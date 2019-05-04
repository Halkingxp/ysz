/*****************************************************************************
Copyright (C), 2015-2050, ***. Co., Ltd.  
完成日期:  2016-11-25
说明信息:  消息包的内存池
*****************************************************************************/
#include "PacketPool.h"

CPacketPool::CPacketPool(void) : m_nExpansion(1000)
{
}

CPacketPool::~CPacketPool(void)
{
	std::list<CPacket*>::iterator it = m_cFreeList.begin();
	while (it != m_cFreeList.end())
	{
		CPacket* pPacket = *it;
		delete pPacket;
		it++;
	}

	m_cFreeList.clear();
}

CPacketPool& CPacketPool::GetInstance(void)
{
    static CPacketPool object;
    return object;
}

//********************************************************************
//函数功能: 初始化消息包
//第一参数: 初始化消息包指针个数
//第二参数: 消息包指针不够时, 动态扩展个数
//返回说明: 
//备注说明: 
//********************************************************************
void CPacketPool::Init(uint16 nInitSize, uint16 nExpansionSize)
{
	this->m_nExpansion = nExpansionSize;
	for (uint16 i = 0; i < nInitSize; i++)
	{
		CPacket* pPacket = new CPacket;
		if (pPacket != nullptr)
		{
			m_cFreeList.push_back(pPacket);
		}
	}
}
//********************************************************************
//函数功能: 分配消息包指针
//第一参数: 
//返回说明: 
//备注说明: 
//********************************************************************
CPacket* CPacketPool::Pop(void)
{
	std::lock_guard<std::mutex> g(m_cLock);
	if (m_cFreeList.empty())
	{
		CPacket* pPacket = new CPacket;
		if (pPacket != nullptr)
		{
			m_cFreeList.push_back(pPacket);
		}
	}

	CPacket* pPacket = m_cFreeList.front();
	m_cFreeList.pop_front();
	return pPacket;
}

//********************************************************************
//函数功能: 回收消息包指针
//第一参数: 
//返回说明: 
//备注说明: 
//********************************************************************
void CPacketPool::Push(CPacket *pPacket)
{
	std::lock_guard<std::mutex> g(m_cLock);
	m_cFreeList.push_back(pPacket);
}





