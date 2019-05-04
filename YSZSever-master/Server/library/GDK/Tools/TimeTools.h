/*****************************************************************************
Copyright (C), 2012-2100, ^^^^^^^^. Co., Ltd.
文 件 名:  TimeTools.h
作    者:  Herry  
版    本:  1.0
完成日期:  2012-8-28
说明信息:  
*****************************************************************************/
#pragma once
#include "Define.h"
#include "StringTools.h"

#ifndef WIN32
#include <sys/time.h>
#include <unistd.h>
#endif



class CTimeTools
{
public:
	//********************************************************************
	//函数功能: 从第一次调用此函数到现在所经过（elapsed）的毫秒数 (时间戳)
	//第一参数: 
	//返回说明: 单位: 毫秒

	//使用说明: time_t start = GetSystemTimeToTick();
	//使用说明: Function();
	//使用说明: time_t end = GetSystemTimeToTick();
	//使用说明: time_t tick = end - start;

	//备注说明: GetSystemTimeToTick()函数只能计算连续48天内的时间
	//备注说明: 如有需要, 可将返回值改为64位. 那么48天限制将被扩大
	//********************************************************************
	static uint32 GetSystemTimeToTick(void)
	{
		static uint32 nStartTime = (uint32)clock();
		uint32 nNowTime = (uint32)clock() - nStartTime;
		return nNowTime;
	}

	//********************************************************************
	//函数功能: 将时间戳(秒)转换成时间字符串, 从1970-01-01 08:00:00开始
	//第一参数: 时间戳(秒)
	//返回说明: 单位: 秒
	//********************************************************************
	static const char* GetTimeToString(uint32 nTime)
	{
		static char szBuffer[BUFFER_LEN] = {};

		time_t t = nTime;
		tm* p = localtime(&t);
		if (p == NULL)
		{
			szBuffer[0] = '\0';
			return szBuffer;
		}

		CStringTools::SafeSprintf(szBuffer, BUFFER_LEN, "%04d-%02d-%02d %02d:%02d:%02d", 
			(p->tm_year+1900), (p->tm_mon+1), p->tm_mday, p->tm_hour, p->tm_min, p->tm_sec);
		return szBuffer;
	}

	//********************************************************************
	//函数功能: 从1970-01-01 08:00:00到现在所经过（elapsed）的秒数
	//第一参数: 
	//返回说明: 单位: 秒
	//备注说明: 
	//********************************************************************
	static uint32 GetSystemTimeToSecond(void)
	{
		return uint32(time(NULL));
	};


	//********************************************************************
	//函数功能: 获取系统当前日期的字符串, 从1970-01-01 08:00:00开始
	//第一参数: 
	//返回说明: 参数true,  返回格式 2012-08-28 23:58:59
    //返回说明: 参数false, 返回格式 20120828235859
	//备注说明: 
	//********************************************************************
	static const char* GetSystemTimeToString(bool isFormat = true)
	{
		static char szBuffer[BUFFER_LEN] = {};

		time_t t = time(NULL);
		tm* p = localtime(&t);
		if (p == NULL)
		{
			szBuffer[0] = '\0';
			return szBuffer;
		}

        if (isFormat == true)
        {
			// 返回格式 2012-08-28 23:58:59
			CStringTools::SafeSprintf(szBuffer, BUFFER_LEN, "%04d-%02d-%02d %02d:%02d:%02d",
				(p->tm_year + 1900), (p->tm_mon + 1), p->tm_mday, (p->tm_hour), p->tm_min, p->tm_sec);
        } 
        else
        {
            // 返回格式 20120828235859
			CStringTools::SafeSprintf(szBuffer, BUFFER_LEN, "%04d%02d%02d%02d%02d%02d",
				(p->tm_year + 1900), (p->tm_mon + 1), p->tm_mday, (p->tm_hour), p->tm_min, p->tm_sec);
        }
		return szBuffer;
	};


	//********************************************************************
	//函数功能: 获得当前系统时间的tm结构
	//第一参数: 无
	//返回说明: tm结构
	//********************************************************************
	static std::tm GetSystemTimeToTM(void)
	{
		static tm cStm = {};
		time_t nTime = time(NULL);
		tm* pTm = localtime(&nTime);
		if (pTm != nullptr)
		{
			pTm->tm_year += 1900;
			pTm->tm_mon += 1;
			return *pTm;
		}
		else
		{
			return cStm;
		}
	};

	//********************************************************************
	//函数功能: 获得系统时间属于一年中的哪一天
	//第一参数: [IN] 指定时间戳
	//返回说明: 天数 (第0-365天)
	//备注说明: 
	//********************************************************************
	static uint32 GetSystemTimeToYearDay(time_t nTime)
	{
		tm* p = localtime(&nTime);
		if (p == NULL)
		{
			return 0;
		}
		return p->tm_yday;
	};

	//********************************************************************
	//函数功能: 获取标准格林威治时间戳对应秒数的字符串, 从1970-01-01 00:00:00开始
	//第一参数: 
	//返回说明: 格式: 1464002169
	//备注说明: 
	//********************************************************************
	static char* GetGMTimeToString(void)
	{
		static char szBuffer[32] = {};
		sprintf(szBuffer, "%d", ((uint32)time(NULL) - 28800));
		return szBuffer;
	};

	//********************************************************************
	//函数功能: 获取标准格林威治时间戳对应秒数, 从1970-01-01 00:00:00开始
	//第一参数: 
	//返回说明: 格式: 1464002169
	//备注说明: 
	//********************************************************************
	static uint32 GetGMTimeToSecond(void)
	{
		uint32 nTime = (uint32)time(NULL) - 28800;
		return nTime;
	};

	//********************************************************************
	//函数功能: 获取标准格林威治时间戳对应毫秒数, 从1970-01-01 08:00:00开始
	//第一参数: 
	//返回说明: 格式: 1464002169
	//备注说明: 
	//********************************************************************
	static uint64 GetSystemTimeToMillisecond(void)
	{
#ifdef WIN32
		SYSTEMTIME wtm = {};
		GetLocalTime(&wtm);

		time_t sec = time(NULL);
		uint64 nTime = sec * 1000 + wtm.wMilliseconds;
		return nTime;
#else
		struct timeval tv = {};
		gettimeofday(&tv, NULL);
		uint64 nTime = tv.tv_sec * 1000 + tv.tv_usec / 1000;
		return nTime;
#endif
	};

	//********************************************************************
	//函数功能: 获取当前时间的微妙数
	//第一参数: 
	//返回说明: 格式: 642169
	//备注说明: 
	//********************************************************************
	static uint32 GetNowTimeToMillisecond(void)
	{
#ifdef WIN32
		SYSTEMTIME wtm = {};
		GetLocalTime(&wtm);
		return wtm.wMilliseconds;
#else
		struct timeval tv = {};
		gettimeofday(&tv, NULL);
		uint32 nTime = tv.tv_usec / 1000;
		return nTime;
#endif
	};
	//********************************************************************
	//函数功能: 字符串类型的时间, 转换成对应的系统时间(单位秒)
	//第一参数: [IN] 字符串时间
	//返回说明: 0,  转换失败, 参数为空指针
	//返回说明: >0, 转换成功, 返回从1970-01-01 08:00:00到现在所经过（elapsed）的秒数
	//备注说明: 字符串格式为 (%Y-%m-%d %H:%M:%S)  (年-月-日 小时:分:秒)
	//备注说明: 例如 2013-04-30 23:59:59  或者 2013-05-22 12:00:00
	//********************************************************************
	static uint32 GetStringToTime(const char *szData)
	{
		if (NULL == szData)
		{
			return 0;
		}

		tm cStm = {};
#if defined(WIN32)
		int year = 0, month = 0, day = 0, hour = 0, minute = 0, second = 0;
		sscanf(szData, "%d-%d-%d %d:%d:%d", &year, &month, &day, &hour, &minute, &second);
		cStm.tm_year = year - 1900;
		cStm.tm_mon = month - 1;
		cStm.tm_mday = day;
		cStm.tm_hour = hour;
		cStm.tm_min = minute;
		cStm.tm_sec = second;
		cStm.tm_isdst = -1;
#else
		strptime(szData, "%Y-%m-%d %H:%M:%S", &cStm);
#endif
		uint32 nTime = (uint32)mktime(&cStm);
		return nTime;
	};



	//********************************************************************
	//函数功能: 计算两个日期之间的时间差值 (单位: 秒)
	//第一参数: [IN] 起始日期
	//第二参数: [IN] 结束日期
	//返回说明: 返回相差的秒数
	//备注说明: 如果返回为负数, 表示起始时间在结束时间之后.需做合理处理.
	//********************************************************************
	static int32 GetDateInterval(std::tm& start, std::tm& end)
	{
		time_t st = mktime(&start);
		time_t et = mktime(&end);
		return int32(et - st);
	};

};
