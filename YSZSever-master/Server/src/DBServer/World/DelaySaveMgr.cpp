/*****************************************************************************
Copyright (C), 2008-2009, ***. Co., Ltd.
文 件 名:  DelaySaveMgr.cpp
作    者:  
版    本:  1.0
完成日期:  2013-6-22
说明信息:  延迟执行SQL语句的管理器
*****************************************************************************/
#include "DataBase/DataBase.h"
#include "DelaySaveMgr.h"

extern CDataBase	g_cLogDataBase;		// 日志数据库表 

CDelaySaveMgr::CDelaySaveMgr(void) : m_isTopSpeed(false)
{
    m_cLogQueue.reserve(MAX_DELAYSAVE_NUM + 1);
}

CDelaySaveMgr::~CDelaySaveMgr(void)
{
}

CDelaySaveMgr& CDelaySaveMgr::GetInstance(void)
{
    static CDelaySaveMgr object;
    return object;
}

void CDelaySaveMgr::Run(void)
{
	uint32 nCountLog = 0;
	String strSQL;
    
    STRING_VECTOR tempLog;
    tempLog.reserve(MAX_DELAYSAVE_NUM + 1);

	while (IsRun())
	{
        {
			std::lock_guard<std::mutex> g(m_cLock);
            tempLog.swap(m_cLogQueue);
        }

        STRING_VECTOR::iterator it = tempLog.begin();
        STRING_VECTOR::iterator end = tempLog.end();
        while (it != end)
        {
            strSQL = *it;
            it++;
            g_cLogDataBase.NotCommitExecute(strSQL.c_str());
            nCountLog++;
            if (nCountLog >= MAX_DELAYSAVE_NUM)
            {
                g_cLogDataBase.Commit();
                nCountLog = 0;
                if (!m_isTopSpeed)
                {
                    Sleep(5);
                }	
            }
        }
        if (nCountLog > 0)
        {
            g_cLogDataBase.Commit();
            nCountLog = 0;
        }


        if (!m_isTopSpeed)
        {
            Sleep(5);
        }
        tempLog.clear();
	}
}

//********************************************************************
//函数功能: 压入SQL语句
//第一参数: [IN] 指定数据库类型
//第二参数: [IN] SQL语句
//备注说明: 当第一参数是DELAY_FINISH时, 第二参数传回存账号ID的字符串 
//********************************************************************
void CDelaySaveMgr::PushQuery(DelayType eType, const String &strSQL)
{
	std::lock_guard<std::mutex> g(m_cLock);

	switch (eType)
	{
	case DELAY_LOG:
		m_cLogQueue.push_back(strSQL);
		break;
	default:
		return;
	}
}

//********************************************************************
//函数功能: 压入SQL语句
//第一参数: [IN] 指定数据库类型
//第二参数: [IN] SQL语句
//返回说明: true  压入成功
//返回说明: false 压入失败
//备注说明: 当第一参数是DELAY_FINISH时, 第二参数传回存账号ID的字符串 
//********************************************************************
bool CDelaySaveMgr::PushQuery(DelayType eType, const char *szSQL, ...)
{
	static char szQuery[MAX_QUERY_LEN] = {};
	if (NULL == szSQL)
	{
		return false;
	}	

	if (m_cLock.try_lock() == false)
	{
		return false;
	}

	va_list ap;
	va_start(ap, szSQL);
	int res = vsnprintf(szQuery, MAX_QUERY_LEN, szSQL, ap);
	va_end(ap);
	if (res == -1)
	{
		return false;
	}

	switch (eType)
	{
	case DELAY_LOG:
		m_cLogQueue.push_back(szQuery);
		break;
	default:
	    break;
	}
	return true;
}



//********************************************************************
//函数功能: 是否为空队列
//第一参数: 
//返回说明: true  空队列
//返回说明: false 非空队列
//备注说明: 
//********************************************************************
bool CDelaySaveMgr::IsEmpty(void)
{
	return m_cLogQueue.empty();
}

//********************************************************************
//函数功能: 获得队列长度
//第一参数: [IN] 队列类型
//返回说明: 
//备注说明: 
//********************************************************************
uint32 CDelaySaveMgr::GetQuerySize(DelayType eType)
{
    return m_cLogQueue.size();
}