/*****************************************************************************
Copyright (C), 2008-2009, ***. Co., Ltd.
文 件 名:  DelaySaveMgr.h
作    者:    
版    本:  1.0
完成日期:  2013-6-22
说明信息:  延迟执行SQL语句的管理器
*****************************************************************************/
#pragma once
#include "Define.h"
#include "Thread/Thread.h"
#include <mutex>

#define  MAX_DELAYSAVE_NUM 50

enum DelayType
{
	DELAY_INST,		// 实例类型
	DELAY_LOG,		// 日志类型
};

class CDelaySaveMgr : public CThread
{
private:
	CDelaySaveMgr(void);
	virtual ~CDelaySaveMgr(void);

public:
    static CDelaySaveMgr& GetInstance(void);

protected:
	virtual void Run(void);

public:
	void PushQuery(DelayType eType, const String &strSQL);
	bool PushQuery(DelayType eType, const char *szSQL, ...);
	

	bool	IsEmpty(void);
	uint32	GetQuerySize(DelayType eType);
	void	SetTopSpeed(bool isTopSpeed)   { m_isTopSpeed = isTopSpeed; }	// 设置全速回存数据标志


private:
	STRING_VECTOR		        m_cLogQueue;		// 日志队列
	bool						m_isTopSpeed;		// 是否全速回存, 只允许关闭服务器回存数据时使用
	std::mutex					m_cLock;
	
};


#define sDelaySaveMgr CDelaySaveMgr::GetInstance()