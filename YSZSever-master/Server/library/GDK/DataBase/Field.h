/*****************************************************************************
Copyright (C), 2012-2100, ^^^^^^^^. Co., Ltd.
文 件 名:  Field.h
作    者:  Herry  
版    本:  1.0
完成日期:  2012-9-12
说明信息:  SQL执行结果的字段
*****************************************************************************/
#pragma once
#include "Define.h"

enum DataTypes
{
    DB_TYPE_UNKNOWN = 0x00,
    DB_TYPE_STRING  = 0x01,
    DB_TYPE_INTEGER = 0x02,
    DB_TYPE_FLOAT   = 0x03,
    DB_TYPE_BOOL    = 0x04,
	DB_TYPE_BIGINT  = 0x05,
};

class CField
{
public:
    CField(void);
    //CField(const char *szValue, enum DataTypes eType);

    ~CField(void);

public:
    uint32 SetValue(const char *szValue);
    void SetcoulmName(const char *szName);
    void SetType(DataTypes eType)		{ m_eType = eType;			}
    DataTypes GetType(void) const		{ return m_eType;			}
    bool IsNull(void) const				{ return m_szValue == NULL; }

    String       GetName(void)   const { return m_columnName; }
    const char*  GetValue(void)	 const { return m_szValue; }
    const String GetString(void) const { return m_szValue ? m_szValue : ""; }
    const float  GetFloat(void)	 const { return m_szValue ? static_cast<float>(atof(m_szValue)) : 0.0f; }
    const bool   GetBool(void)	 const { return m_szValue ? atoi(m_szValue) > 0 : false; }
    const int8	 GetInt8(void)	 const { return m_szValue ? static_cast<int8>(atol(m_szValue)) : int8(0); }
    const int16	 GetInt16(void)	 const { return m_szValue ? static_cast<int16>(atol(m_szValue)) : int16(0); }
    const int32	 GetInt32(void)	 const { return m_szValue ? static_cast<int32>(atol(m_szValue)) : int32(0); }
    const uint8  GetUInt8(void)	 const { return m_szValue ? static_cast<uint8>(atol(m_szValue)) : uint8(0); }
    const uint16 GetUInt16(void) const { return m_szValue ? static_cast<uint16>(atol(m_szValue)) : uint16(0); }
    const uint32 GetUInt32(void) const { return m_szValue ? static_cast<uint32>(atol(m_szValue)) : uint32(0); }
    const int64 GetInt64(void) const;

private:
    CField(CField &other);
    CField& operator = (const CField &other);

private:
    char		   *m_szValue;
    DataTypes		m_eType;
    String          m_columnName;
};

