/*****************************************************************************
Copyright (C), 2012. ^^^^^^^^. Co., Ltd.
文 件 名:  Thread.h
作    者:    
版    本:  1.0
完成日期:  2012-8-14
说明信息:  跨平台的线程基类
*****************************************************************************/
#pragma once
#include <thread>


// 线程类
class CThread
{
public:
	CThread(void);
	virtual ~CThread(void);

protected:
	// 线程执行函数, 派生对象重载
	virtual void Run(void) = 0;

public:
	void Start();
	void Detach(void);
	bool Stop(void);
	bool IsRun(void);
	void Sleep(uint32_t nMilliseconds);

private:
	CThread(const CThread &other) = delete;
	CThread& operator = (const CThread &other) = delete;

private:
	static void _ThreadTask(void *pParam);

private:
	bool				m_isRun;		// 执行标志
	std::thread			m_cThread;
};
