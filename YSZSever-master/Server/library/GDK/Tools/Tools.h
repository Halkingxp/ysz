/*****************************************************************************
Copyright (C), 2012-2100, ^^^^^^^^. Co., Ltd.
文 件 名:  Tools.h
作    者:  Herry  
版    本:  1.0
完成日期:  2012-8-28
说明信息:  
*****************************************************************************/
#pragma once
#include "Define.h"

#if !defined MAKEWORD
#define MAKEWORD(a, b)      ((uint16)(((uint8)(((uint32)(a)) & 0xff)) | ((uint16)((uint8)(((uint32)(b)) & 0xff))) << 8))
#endif

#if !defined MAKELONG
#define MAKELONG(a, b)      ((uint32)(((uint16)(((uint32)(a)) & 0xffff)) | ((uint32)((uint16)(((uint32)(b)) & 0xffff))) << 16))
#endif

#if !defined LOWORD
#define LOWORD(l)           ((uint16)(((uint32)(l)) & 0xffff))
#endif

#if !defined HIWORD
#define HIWORD(l)           ((uint16)((((uint32)(l)) >> 16) & 0xffff))
#endif

#if !defined LOBYTE
#define LOBYTE(w)           ((uint8)(((uint32)(w)) & 0xff))
#endif

#if !defined HIBYTE
#define HIBYTE(w)           ((uint8)((((uint32)(w)) >> 8) & 0xff))
#endif


//********************************************************************
//函数功能: 安全的内存拷贝
//
//第一参数: [IN] 目标指针
//第二参数: [IN] 目标内存长度 (sizeof(pDes) 的长度)
//第三参数: [IN] 源指针
//第四参数: [IN] 源内存长度   (sizeof(pSrc) 的长度)
//
//返回说明: 返回拷贝长度
//返回说明: 异常情况返回值为0, 表示拷贝失败
//
//异常说明: 1. 空指针异常		返回0
//异常说明: 2. 自我拷贝			返回0
//异常说明: 3. 重叠内存拷贝		返回0
//异常说明: 4. 源指针越界访问	    返回0
//
//备注说明: nDesSize < nSrcSize 从源内存块拷贝 nDesSize 字节到目标内存块
//备注说明: nDesSize = nSrcSize 从源内存块拷贝 nDesSize 字节到目标内存块
//备注说明: nDesSize > nSrcSize 从源内存块拷贝 nSrcSize 字节到目标内存块
//备注说明: 如果第四参数无法获取, 请传安全的长度
//********************************************************************
inline uint32 SafeMemcpy(void *pDes, uint32 nDesSize, const void *pSrc, uint32 nSrcSize)
{
	char   *pTo		  = (char *)pDes;
	char   *pFrom	  = (char *)pSrc;
	uint32  nCopySize = nDesSize;

	//避免源指针越界访问
	if (nCopySize > nSrcSize)
	{
		nCopySize = nSrcSize;
	}
	//空指针检查, 自我拷贝检查
	if (pTo == NULL || pFrom == NULL || pTo == pFrom)
	{
		return 0;
	}
	//重叠拷贝检查
	if (pTo < pFrom + nCopySize && pFrom < pTo + nCopySize)
	{
		return 0;
	}
	//内存拷贝
	memcpy(pDes, pSrc, nCopySize);
	return nCopySize;
}

//********************************************************************
//函数功能: 可控制是否打印到控制台的输出函数
//第一参数: [IN] 是否打印到控制台, true为打印
//第二参数: [IN] print输出格式
//第三参数: [IN] 动态参数
//返回说明: 无
//备注说明: 
//********************************************************************
inline void PrintfControl(bool isPrintf, const char* szFormat...)
{
    if (isPrintf == true)
    {
        va_list ap;
        va_start(ap, szFormat);
        vfprintf(stderr, szFormat, ap);
        va_end(ap);
    }
}


//Window平台堆上分配内存的头结构
struct SMemoryHeader
{
#if defined(WIN32) && defined(_DEBUG)
	SMemoryHeader	*pBlockHeaderNext;
	SMemoryHeader	*pBlockHeaderPrev;
	char			*szFileName;
	uint32			 nLine;
	uint32			 nDataSize;
	uint32			 nBlockUse;
	uint32			 lRequest;
	char			 gap[4];
#endif
};


//******************************************************************
//功能说明: 检查内存泄漏
//第一参数:
//返回说明: 
//异常说明:
//备注说明: 程序终止后，在输出窗口查看相关信息
//******************************************************************
inline void CheckMemoryLeakOut(void)
{
#if defined(WIN32) && defined(_DEBUG)
	int tmpDbgFlag;
	tmpDbgFlag = _CrtSetDbgFlag(_CRTDBG_REPORT_FLAG);
	tmpDbgFlag |= _CRTDBG_DELAY_FREE_MEM_DF;
	tmpDbgFlag |= _CRTDBG_LEAK_CHECK_DF;
	tmpDbgFlag |= _CRTDBG_ALLOC_MEM_DF;
	_CrtSetDbgFlag(tmpDbgFlag);
#endif
};

//******************************************************************
//功能说明: 准确定位内存泄漏代码
//第一参数: [IN] 内存分配的ID
//返回说明: 
//异常说明:
//备注说明: 调用CheckMemoryLeakOut函数, 程序终止后，在输出窗口查看内存泄漏的分配ID
//备注说明: 在代码mian函数中加入CrtSetBreakAlloc函数, 参数传内存泄漏的分配ID
//备注说明: 若再次出现内存泄漏, 并且内存泄漏的分配ID一致, 此函数将中断程序.
//******************************************************************
inline void CrtSetBreakAlloc(uint32 nAllocID)
{
#if defined(WIN32) && defined(_DEBUG)
	_CrtSetBreakAlloc(nAllocID);
#endif
}
