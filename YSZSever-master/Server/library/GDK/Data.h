/*****************************************************************************
Copyright (C), 2012-2100, . Co., Ltd.
文 件 名:  data.h
作    者:  Herry  
版    本:  1.0
完成日期:  2012-8-28
说明信息:  只允许添加标准库还有公共部分的类型定义和宏定义
*****************************************************************************/
#pragma once
#include <string>
#include <stdint.h>


// 通用基础类型定义
typedef std::int64_t			int64;
typedef std::int32_t			int32;
typedef std::int16_t			int16;
typedef std::int8_t				int8;
typedef std::uint64_t			uint64;
typedef std::uint32_t			uint32;
typedef std::uint16_t			uint16;
typedef std::uint8_t			uint8;
typedef std::string				String;


//#ifdef WIN32
//	#ifdef _EXPORT_DLL_
//		#define  DLL_API __declspec(dllexport)
//	#else
//		#define  DLL_API 
//	#endif
//#else
//	#define  DLL_API 
//#endif
