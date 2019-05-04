/*****************************************************************************
Copyright (C), 2012-2013, 
文 件 名:  JsonParser.h
作    者:  
版    本:  1.0
完成日期:  2013-3-5
说明信息:  Json读写工具, 使用第三方引擎RapidJson, 仅支持标准JSON格式
*****************************************************************************/
#pragma once

#include <iostream>
#include "document.h"
#include "prettywriter.h"
#include "stringbuffer.h"
#include <set>
#include "Data.h"
#define GETJSON_INT64(var, obj, Index) int64 var = 0;if(obj.HasMember(Index) && obj[Index].IsInt64()){ var = obj[Index].GetInt64();}
#define GETJSON_UINT32(var, obj, Index) uint32 var = 0;if(obj.HasMember(Index) && obj[Index].IsUint()){ var = obj[Index].GetUint();}
#define GETJSON_UINT16(var, obj, Index) uint16 var = 0;if(obj.HasMember(Index) && obj[Index].IsUint()){ var = obj[Index].GetUint();}
#define GETJSON_UINT8(var, obj, Index)  uint8  var = 0;if(obj.HasMember(Index) && obj[Index].IsUint()){ var = obj[Index].GetUint();}
#define GETJSON_INT32(var, obj, Index) int32 var = 0;if(obj.HasMember(Index) && obj[Index].IsInt()){ var = obj[Index].GetInt();}
#define GETJSON_INT16(var, obj, Index) int16 var = 0;if(obj.HasMember(Index) && obj[Index].IsInt()){ var = obj[Index].GetInt();}
#define GETJSON_INT8(var, obj, Index)  int8  var = 0;if(obj.HasMember(Index) && obj[Index].IsInt()){ var = obj[Index].GetInt();}
#define GETJSON_STRING(var, obj, Index)  String  var = "";if(obj.HasMember(Index) && obj[Index].IsString()){ var = obj[Index].GetString();}

using namespace rapidjson;
typedef GenericValue<UTF8<char> > jsonobj;
typedef GenericValue<UTF8<char> > jsonarr;
class CJson
{
public:
	CJson(void);
    CJson(const char *szJsonData);
	~CJson(void);

public:
	std::string GetContent(void);
	bool		SetContent(const char *szJsonData);

public:
	// 通过Key来读取数据
	std::string     ReadString(const char *szKey, char *szValue = "");
	int32			ReadInt(const char *szKey, int32 iDefault = 0);
	bool		    ReadBool(const char *szKey, bool isDefault = false);
	float		    ReadFloat(const char *szKey, float fDefault = 0.0f);
	uint32          ReadUInt32(const char *szKey, int32 iDefault = 0);
    uint64          ReadUInt64(const char *szKey, int64 iDefault = 0);
    const jsonobj&  ReadObject(const char *szKey);
    const Value&    ReadArray(const char *szKey, uint32 nIndex, const char *szArrayKey);

	// 通过Key来写入数据
	void		 WriteString(const char *szKey, const char *szValue);
	void		 WriteInt(const char *szKey, int32 iValue);
	void		 WriteBool(const char *szKey, bool isValue);
	void		 WriteFloat(const char *szKey, float fValue);
	void		 WriteUInt(const char *szKey, uint32 nValue);
    void         WriteObject(const char *szKey, jsonobj& obj);
    jsonobj&     GetAllocator(void) { return m_Doc;}

private:
	std::set<std::string>		m_cStringCache;	// 字符串缓存
	Document					m_Doc;
	StringBuffer				m_StrBuf;
};
