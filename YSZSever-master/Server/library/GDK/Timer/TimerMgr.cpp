/*****************************************************************************
Copyright (C), 2012-2100, ^^^^^^^^. Co., Ltd.
文 件 名:  TimerMgr.cpp
作    者:  Herry   
版    本:  1.0
完成日期:  2012-9-24
说明信息:  计时管理器, 单线程版本, 限制在Word线程内使用
*****************************************************************************/
#include "TimerMgr.h"
#include "Tools/TimeTools.h"
#include "DataStructure/MsgQueue.h"

CTimerMgr::CTimerMgr(void) : m_nTimerID(0)
{
}

CTimerMgr::~CTimerMgr(void)
{
	
}

void CTimerMgr::Destroy()
{
	for (TIMER_MAP::iterator it = m_cTimerMap.begin(); m_cTimerMap.end() != it; ++it)
	{
		if (it->second.pPacket != NULL)
		{
			delete it->second.pPacket;
			it->second.pPacket = NULL;
		}
	}

	m_cTimerMap.clear();
}

CTimerMgr& CTimerMgr::GetInstance(void)
{
    static CTimerMgr object;
    return object;
}

//********************************************************************
//函数功能: 线程执行函数
//第一参数: 
//返回说明: 
//备注说明: 单线程版本, 限制在Word线程内使用
//********************************************************************
void CTimerMgr::Update(void)
{
	uint32 nCurrentTime = CTimeTools::GetSystemTimeToSecond();
	TIMER_MAP::iterator it = m_cTimerMap.begin();
	TIMER_MAP::iterator t;
	while (it != m_cTimerMap.end())
	{
		t = it;
		it++;

		TimerNode &timer = t->second;
		if (0 == timer.iCount)
		{
			// 次数为0, 销毁计时器
			if (timer.pPacket != NULL)
			{
				delete timer.pPacket;
			}
			m_cTimerMap.erase(t);
			continue;
		}

		if (nCurrentTime >= timer.nEndTime)
		{
			if (timer.iCount > 0)
			{
				--timer.iCount;
			}
			timer.nEndTime += timer.nInterval;
			if (timer.pPacket != NULL)
			{
				sMsgQueueVec.PushPacket(*timer.pPacket);
			}
		}
	}

	//Sleep(10);
}


//********************************************************************
//函数功能: 注册计时器

//第一参数: [IN] 间隔时间 (单位: 秒)
//第二参数: [IN] 包
//第三参数: [IN] 次数，默认永久


//返回说明: 返回  0, 注册计时器失败, 参数异常
//返回说明: 返回 >0, 注册计时器成功, 返回值为计时器ID.

//备注说明: 如果注册的计时器是无限次数的, 计时器ID无需保存, 系统会自动回收
//备注说明: 如果注册的计时器是>1次的, 计时器ID可以不保存, 次数为0时系统会自动回收.
//备注说明: 如果注册的计时器是>1次的, 且需要在计时到达前销毁计时器的, 由外部保存计时器ID, 根据逻辑销毁计时器.
//备注说明: 单线程版本, 限制在Word线程内使用
//********************************************************************
uint32 CTimerMgr::SetTimer(uint32 nInterval, CPacket &cPacket, int32 iCount/* = -1*/)
{
	if (cPacket.GetOpcode() == 0)
	{
		char szInfo[128] = {};
		sprintf(szInfo, "注册计时器异常, 间隔时间:%d秒  消息编号:%d", nInterval, cPacket.GetOpcode());
		REPORT(szInfo);
		return 0;
	}
	
	TimerNode timer;
	timer.pPacket = new CPacket;
	if (timer.pPacket == NULL)
	{
		REPORT("空指证异常");
		return 0;
	}

	timer.pPacket->Reset(cPacket.GetData(), cPacket.GetSize());
	timer.pPacket->SetSocketID(cPacket.GetSocketID());
	timer.nInterval = nInterval;
	timer.nEndTime = CTimeTools::GetSystemTimeToSecond() + timer.nInterval;
	timer.iCount = iCount;

	m_nTimerID++;
	m_cTimerMap.insert(std::make_pair(m_nTimerID, timer));
	return m_nTimerID;
}

//********************************************************************
//函数功能: 销毁计时器
//第一参数: [IN] 计时器ID
//返回说明: 返回 -1, 销毁计时器失败, 计时器ID无效.
//返回说明: 返回  0, 销毁计时器成功, 计时器ID被设置为0.
//备注说明: 单线程版本, 限制在Word线程内使用
//********************************************************************
int CTimerMgr::DestroyTimer(uint32 &nTimerID)
{
	TIMER_MAP::iterator it = m_cTimerMap.find(nTimerID);
	if (it == m_cTimerMap.end())
	{
		//REPORT("找不到指定的计时器对象");
		return -1;
	}

	if (it->second.pPacket != NULL)
	{
		delete it->second.pPacket;
	}
	m_cTimerMap.erase(it);
	nTimerID = 0;
	return 0;
}