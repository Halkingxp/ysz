/*****************************************************************************
Copyright (C), 2012-2100, ^^^^^^^^. Co., Ltd.
文 件 名:  StatisticsMgr.cpp
作    者:  Herry   
版    本:  1.0
完成日期:  2012-9-27
说明信息:  统计管理器   (统计CPU使用率  统计内存使用率  统计收发消息总字节数等)
*****************************************************************************/
#include "StatisticsMgr.h"
#include "Tools/TimeTools.h"


CStatisticsMgr::CStatisticsMgr(void) : m_nProtocol(0), m_nBeforeProtocol(0)
{
}

CStatisticsMgr::~CStatisticsMgr(void)
{
}

CStatisticsMgr& CStatisticsMgr::GetInstance(void)
{
    static CStatisticsMgr object;
    return object;
}

//********************************************************************
//函数功能: 统计开始
//第一参数: [IN] 协议编号
//第二参数: [IN] 协议包总大小
//返回说明: 
//备注说明: 
//********************************************************************
void CStatisticsMgr::StatisticsStart(uint32 nOpcode, uint16 nPacketSize)
{
	m_nProtocol = nOpcode;

	STATISTICS_MAP::iterator it = m_cStatistics.find(nOpcode);
	if (it != m_cStatistics.end())
	{
		StatisticsInfo &cInfo = it->second;
		cInfo.nPacketCount++;
        cInfo.tStartTime = CTimeTools::GetSystemTimeToTick();
	}
	else
	{
		StatisticsInfo cInfo = {};
		cInfo.nPacketSize = nPacketSize;
		cInfo.nPacketCount = 1;
		cInfo.tStartTime = CTimeTools::GetSystemTimeToTick();
		m_cStatistics.insert(std::make_pair(nOpcode, cInfo));
	}
}

//********************************************************************
//函数功能: 统计结束
//第一参数: [IN] 协议编号
//返回说明: 
//备注说明: 
//********************************************************************
void CStatisticsMgr::StatisticsEnd(uint32 nOpcode)
{
	time_t tEndTime = CTimeTools::GetSystemTimeToTick();
	STATISTICS_MAP::iterator it = m_cStatistics.find(nOpcode);
	if (it != m_cStatistics.end())
	{
		StatisticsInfo &cInfo = it->second;

		// 计数最长处理时间
		uint16 nTime = uint16(tEndTime - cInfo.tStartTime);
		if (cInfo.nProcMaxTime < nTime)
		{
			cInfo.nProcMaxTime = nTime;
		}
		cInfo.nTotalTime += nTime;
		
	}

	m_nBeforeProtocol = m_nProtocol;
}

//********************************************************************
//函数功能: 打印统计信息
//第一参数:
//返回说明: 
//备注说明: 消息编号 消息包计数 消息包大小 消息包总字节 处理超时次数 最长处理时间
//********************************************************************
void CStatisticsMgr::PrintfStatisticsInfo(void)
{
	//LogInfo("--------------------------------------------");
    printf("--------------------------------------------\r\n");
	//LogInfo("[消息编号] [消息包大小] [消息包计数] [消息包总字节] [超时次数] [最长执行时间]");

	char szInfo[1024] = {};
	uint32 nTotalBytes = 0;
	STATISTICS_MAP::iterator it = m_cStatistics.begin();
	while (it != m_cStatistics.end())
	{
		StatisticsInfo &cInfo = it->second;
		sprintf(szInfo, "编号:%d 包大小:%d 总次数:%d 总:%d毫秒 平均:%.2f毫秒 最长:%d毫秒", 
			it->first, cInfo.nPacketSize, cInfo.nPacketCount, cInfo.nTotalTime, (cInfo.nTotalTime/(float)cInfo.nPacketCount), cInfo.nProcMaxTime);
		//LogInfo(szInfo);
        printf("%s\r\n", szInfo);


		// 统计总计量
		nTotalBytes += (cInfo.nPacketCount * cInfo.nPacketSize);

		it++;
	}

	float fMB = (float)nTotalBytes / 1024 / 1024;
	float fGB = fMB / 1024;
	sprintf(szInfo, "网络通信接收数据: [%uKB]  [%.2fMB]  [%.2fGB]", (nTotalBytes / 1024), fMB, fGB);
	//LogInfo(szInfo);
    printf("%s\r\n", szInfo);
	sprintf(szInfo, "最后两条接收的消息编号: [%d] [%d]", m_nBeforeProtocol, m_nProtocol);
    //LogInfo(szInfo);
    printf("%s\r\n", szInfo);
	//LogInfo("--------------------------------------------");
    printf("--------------------------------------------\r\n");
}

//********************************************************************
//函数功能: 获得当前执行协议编号
//第一参数: 
//返回说明: 
//备注说明: 
//********************************************************************
uint32 CStatisticsMgr::GetProtocol(void)
{
	return m_nProtocol;
}
uint32 CStatisticsMgr::GetBeforeProtocol(void)
{
	return m_nBeforeProtocol;
}
