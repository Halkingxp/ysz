/*****************************************************************************
Copyright (C), 2012-2100, ^^^^^^^^. Co., Ltd.
文 件 名:  StatisticsMgr.h
作    者:  Herry  
版    本:  1.0
完成日期:  2012-9-27
说明信息:  统计管理器   (统计CPU使用率  统计内存使用率  统计收发消息总字节数等)
*****************************************************************************/
#pragma once
#include "Define.h"

#define _STATISTICS			 // 统计宏的开关

// 统计信息
struct StatisticsInfo
{
	uint16		nPacketSize;		// 消息包大小
	uint16		nProcMaxTime;		// 消息处理最长时间
	uint32      nTotalTime;			// 平均执行时间
	uint32		nPacketCount;		// 消息包计数
	time_t		tStartTime;			// 统计开始时间
};

typedef std::map<uint32, StatisticsInfo>    STATISTICS_MAP;
class CStatisticsMgr
{
private:
	CStatisticsMgr(void);
	~CStatisticsMgr(void);

public:
	static CStatisticsMgr& GetInstance(void);

public:
	void StatisticsStart(uint32 nOpcode, uint16 nPacketSize);
	void StatisticsEnd(uint32 nOpcode);
	void PrintfStatisticsInfo(void);

	uint32 GetProtocol(void);
	uint32 GetBeforeProtocol(void);
	
private:
	STATISTICS_MAP		m_cStatistics;
	uint32				m_nProtocol;
	uint32				m_nBeforeProtocol;
};

#define sStatisticsMgr CStatisticsMgr::GetInstance()
