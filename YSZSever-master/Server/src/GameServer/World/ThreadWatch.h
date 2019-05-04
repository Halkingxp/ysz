/*****************************************************************************
Copyright (C), 2012-2100, ^^^^^^^^. Co., Ltd.
文 件 名:  ThreadWatch.h
作    者:  Herry  
版    本:  1.0
完成日期:  2012-9-25
说明信息:  线程守护者, 监控线程是否死循环
*****************************************************************************/
#pragma once
#include "Define.h"
#include "Thread/Thread.h"


struct ThreadCount
{
	uint32 nLastCount;
	uint32 nCurrCount;
	String strName;
};

typedef std::map<uint16, ThreadCount>    THREAD_COUNT_MAP;
class CThreadWatch : public CThread
{
private:
	CThreadWatch(void);
	~CThreadWatch(void);

protected:
	virtual void Run(void);

public:
	static CThreadWatch& GetInstance(void);

	uint16 Initialize(const String &strInfo);
	void   Updata(uint16 nWatchID);

private:
	void _CheckCount(void);

private:
	uint16				m_nWatchID;
	THREAD_COUNT_MAP	m_cThreadCountMap;
};

#define sThreadWatch CThreadWatch::GetInstance()