/*****************************************************************************
Copyright (C), 2012-2100, ^^^^^^^^. Co., Ltd.
文 件 名:  MsgQueue.cpp
作    者:  Herry   
版    本:  1.0
完成日期:  2012-11-13
说明信息:  消息队列, 多线程安全
*****************************************************************************/
#include "MsgQueue.h"



///////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////

CMsgQueueVec::CMsgQueueVec(void) : m_nMaxCount(0)
{
    m_vecMsg.reserve(MAX_MSG_QUEUE_LEN);
}

CMsgQueueVec::~CMsgQueueVec(void)
{

}

bool CMsgQueueVec::PushPacket(CPacket &cPacket)
{

	std::lock_guard<std::mutex> g(m_cLock);
    if (m_vecMsg.size() > m_nMaxCount)
    {
        m_nMaxCount = m_vecMsg.size();
    }

	CPacket *pNode = new CPacket;
	if (pNode == NULL)
	{
		return false;
	}

	pNode->SetSocketID(cPacket.GetSocketID());
	pNode->Reset(cPacket.GetData(), cPacket.GetSize());
    m_vecMsg.push_back(pNode);
    return true;
}

void CMsgQueueVec::Get(PACK_VEC& vec)
{
    if (!vec.empty())
    {
        REPORT("异常情况 vec不为空");
        return;
    }

	std::lock_guard<std::mutex> g(m_cLock);
    vec.swap(m_vecMsg);
}

void CMsgQueueVec::ClearAll(void)
{
	std::lock_guard<std::mutex> g(m_cLock);
	PACK_VEC::iterator it = m_vecMsg.begin();
	PACK_VEC::iterator end = m_vecMsg.end();
	while (it != end)
	{
		CPacket* pPacket = *it;
		it++;

		delete pPacket;
	}
    m_vecMsg.clear();
}

