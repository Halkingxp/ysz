/*****************************************************************************
Copyright (C), 2012-2100, ^^^^^^^^. Co., Ltd.
文 件 名:  ThreadWatch.cpp
作    者:  Herry   
版    本:  1.0
完成日期:  2012-9-25
说明信息:  线程守护者, 监控线程是否死循环
*****************************************************************************/
#include "Statistics/StatisticsMgr.h"
#include "DelaySaveMgr.h"
#include "ThreadWatch.h"

CThreadWatch::CThreadWatch(void) : m_nWatchID(0)
{
}

CThreadWatch::~CThreadWatch(void)
{
}

CThreadWatch& CThreadWatch::GetInstance(void)
{
    static CThreadWatch object;
    return object;
}


void CThreadWatch::Run(void)
{
#if defined(WIN32) && defined(_DEBUG)
	// windows平台debug模式下不开启线程狗
	return;
#endif

	#define CHECK_TIME	120	// 检查间隔时间 2分钟

	time_t tCurrtTime = 0;
	time_t tEndTime = CTimeTools::GetSystemTimeToSecond() + CHECK_TIME;
	while (IsRun())
	{
		Sleep(60000);

		tCurrtTime = CTimeTools::GetSystemTimeToSecond();
		if (tCurrtTime >= tEndTime)
		{
			_CheckCount();
			tEndTime = tCurrtTime + CHECK_TIME;
		}
	}
}

//********************************************************************
//函数功能: 初始化线程守护者
//第一参数: [IN] 线程名字
//返回说明: 返回守护ID
//备注说明: 
//********************************************************************
uint16 CThreadWatch::Initialize(const String &strName)
{
	m_nWatchID++;

	ThreadCount info = {};
	info.strName = strName;
	info.nCurrCount = 0;
	info.nLastCount = 0;

	m_cThreadCountMap.insert(std::make_pair(m_nWatchID, info));
	return m_nWatchID;
}


//********************************************************************
//函数功能: 更新指定守护ID
//第一参数: [IN] 守护ID
//返回说明: 
//备注说明: 在检测线程的更新函数内调用此函数
//********************************************************************
void CThreadWatch::Updata(uint16 nWatchID)
{
	THREAD_COUNT_MAP::iterator it = m_cThreadCountMap.find(nWatchID);
	if (it != m_cThreadCountMap.end())
	{
		it->second.nCurrCount++;
	}
}


//********************************************************************
//函数功能: 检查线程计数
//第一参数: 
//返回说明:
//备注说明:
//********************************************************************
void CThreadWatch::_CheckCount(void)
{
	THREAD_COUNT_MAP::iterator it = m_cThreadCountMap.begin();
	while (it != m_cThreadCountMap.end())
	{
		ThreadCount &info = it->second;
		if (info.nLastCount != info.nCurrCount)
		{
			// 线程运行正常, 保存计数
			info.nLastCount = info.nCurrCount;
		}
		else
		{
			// 线程运行异常, 写日志并弹出提示框
			char szInfo[512] = {};
			sprintf(szInfo, "[%s]线程异常, 最后两条消息编号: [%d] [%d], 可能已经出现死循环", info.strName.c_str(), sStatisticsMgr.GetBeforeProtocol(), sStatisticsMgr.GetProtocol());
			REPORT(szInfo);

			// 记录统计信息
			sStatisticsMgr.PrintfStatisticsInfo();
			
			uint32 nInst = 0;
			uint32 nLog = 0;
			while (!sDelaySaveMgr.IsEmpty())
			{
				nInst = sDelaySaveMgr.GetQuerySize(DELAY_INST);
				nLog = sDelaySaveMgr.GetQuerySize(DELAY_LOG);
				printf("-- 服务器正在回存数据, 还有 %d 条数据\r\n", (nInst + nLog));
				Sleep(5000);
			}

			// 模拟空指针操作, 让进程自动重启
			//int *p = NULL;
			//*p = 123;
		}
		it++;
	}
}