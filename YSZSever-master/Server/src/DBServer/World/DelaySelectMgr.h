/*****************************************************************************
Copyright (C), 2008-2009, ***. Co., Ltd.
文 件 名:  DelaySelectMgr.h
作    者:  
版    本:  1.0
完成日期:  2013-6-22
说明信息:  延迟执行SQL语句的管理器
*****************************************************************************/
#pragma once
#include "Define.h"
#include "Thread/Thread.h"
#include "DataStructure/Queue.h"
#define  MAX_DELAYSELECT_NUM 50

struct SQL_OP
{
    String str_sqlSyntax;       // 语法操作
    String str_Callback;        // 回调函数
    uint32 nCallbackProtocol;   // 回调消息
    uint32 nSocketID;
};

typedef std::vector<SQL_OP>  VEC_SQL;
class CDelaySelectMgr : public CThread
{
private:
	CDelaySelectMgr(void);
	virtual ~CDelaySelectMgr(void);

public:
    static CDelaySelectMgr& GetInstance(void);
    void PushQuery(const String &strSQL, const String &strCallback, uint32 nCBProtocol, uint32 nSocketID);
    //void PushFinish(uint32 nID);
    void SetTopSpeed(bool isTopSpeed)   { m_isTopSpeed = isTopSpeed; }	// 设置全速回存数据标志

protected:
	virtual void Run(void);
public:

private:
	VEC_SQL		                m_cInstQueue;		// 实例队列
    CQueue<uint32>				m_cFinishQueue;		// 通知完成队列
    bool						m_isTopSpeed;		// 是否全速回存, 只允许关闭服务器回存数据时使用
	std::mutex			        m_cLock;
	
};


#define sDelaySelectMgr CDelaySelectMgr::GetInstance()