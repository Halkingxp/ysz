/*****************************************************************************
Copyright (C), 2012-2100, ^^^^^^^^. Co., Ltd.
文 件 名:  TimerMgr.h
作    者:  Herry  
版    本:  1.0
完成日期:  2012-9-24
说明信息:  计时管理器, 单线程版本, 限制在Word线程内使用
*****************************************************************************/
#pragma once
#include "Define.h"

struct TimerNode;
typedef std::map<uint32, TimerNode> TIMER_MAP;

// 计时对象
struct TimerNode
{
	uint32			nInterval;
	uint32			nEndTime;
	CPacket        *pPacket;
	int32           iCount;
};


// 计时管理器
class CTimerMgr
{
private:
	CTimerMgr(void);
	~CTimerMgr(void);

public:
	static CTimerMgr& GetInstance(void);

public:
	uint32 SetTimer(uint32 nInterval, CPacket &cPacket, int32 iCount = -1);
	int	   DestroyTimer(uint32 &nTimerID);
	void   Update(void);
	void   Destroy();
protected:
	

private:
	uint32					m_nTimerID;
	TIMER_MAP				m_cTimerMap;
};

#define sTimerMgr CTimerMgr::GetInstance()


















// 简单的计时器, 只计时
class CTimer
{
public:
	CTimer(void) : m_nStartTime(0), m_nCycleTime(0)
	{
	}

	~CTimer(void)
	{
	}

public:
	// 获得开始时间
	inline uint32 GetStartTime(void)
	{ 
		return m_nStartTime; 
	}
	// 获得间隔周期
	inline uint32 GetCycleTime(void)
	{ 
		return m_nCycleTime; 
	}		
	// 设置开始时间
	inline void SetStartTime(void)			  
	{ 
		m_nStartTime = CTimeTools::GetSystemTimeToTick(); 
	} 

	// 设置间隔时间
	inline void SetCycleTime(uint32 nCycleTime) 
	{ 
		m_nCycleTime = nCycleTime;  
	}	

	// 添加间隔周期
	inline void AddCycleTime(uint32 nCycleTime) 
	{ 
		m_nCycleTime += nCycleTime; 
	}	

	// 是否到达时间
	inline bool IsTimeOut(void) const			  
	{ 
		return CTimeTools::GetSystemTimeToTick() - m_nStartTime >= m_nCycleTime;
	} 

	// 获得剩余时间
	inline uint32 GetResidualTime(void)const	    
	{
		int32 iTime = m_nCycleTime - (CTimeTools::GetSystemTimeToTick() - m_nStartTime);
		if (iTime < 0)
		{
			return 0;
		}
		else if ((uint32)iTime > m_nCycleTime)
		{
			return m_nCycleTime;
		}
		return (uint32)iTime;
	} 

	inline void Reset(void)	 				  
	{ 
		m_nStartTime = 0; 
		m_nCycleTime = 0;
	}

protected:
	uint32  m_nStartTime;	// 开始时间 (单位毫秒)
	uint32	m_nCycleTime;	// 间隔时间 (单位毫秒)
};

