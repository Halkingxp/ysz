/*****************************************************************************
Copyright (C), 2012-2100, 网盟科技. Co., Ltd.
文 件 名:  Define.h
作    者:  Herry  
版    本:  1.0
完成日期:  2012-8-28
说明信息:  只允许添加标准库还有公共部分的类型定义和宏定义
*****************************************************************************/
#pragma once

// 标准库相关
#include <chrono>
#include <time.h>
#include <set>
#include <map>
#include <list>
#include <vector>
#include <cstdarg>
#include "Data.h"
#include "log4z/log4z.h"

#define BUFFER_LEN						 4096		// 缓冲区长度

// 通用字符串, 主要用于组装错误日志
static char g_szInfo[BUFFER_LEN] = {};
#include "Assert/Assert.h"
typedef	std::vector<String> STRING_VECTOR;	// 字符串vector
//////////////////////////////////////////////////////////////////////////

// 通用库
#include "Tools/Tools.h"
#include "Tools/CalculateTools.h"
#include "Tools/StringTools.h"
#include "Tools/TimeTools.h"
#include "Packet/Packet.h"


// 以下宏均为从packet消息包中读取对应类型的字段
#define get_uint8(field, packet)   uint8  field = packet.ReadUint8();
#define get_uint16(field, packet)  uint16 field = packet.ReadUint16();
#define get_uint32(field, packet)  uint32 field = packet.ReadUint32();
#define get_uint64(field, packet)  uint64 field = packet.ReadUint64();
#define get_int8(field, packet)    int8   field = packet.ReadInt8();
#define get_int16(field, packet)   int16  field = packet.ReadInt16();
#define get_int32(field, packet)   int32  field = packet.ReadInt32();
#define get_int64(field, packet)   int64  field = packet.ReadInt64();
#define get_float(field, packet)   float  field = packet.ReadFloat(); 
#define get_bool(field, packet)    bool   field = packet.ReadBool();
#define get_string(field, packet)  String field = packet.ReadString();