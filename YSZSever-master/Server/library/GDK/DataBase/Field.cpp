/*****************************************************************************
Copyright (C), 2012-2100, ^^^^^^^^. Co., Ltd.
文 件 名:  Field.cpp
作    者:  Herry   
版    本:  1.0
完成日期:  2012-9-12
说明信息:  SQL执行结果的字段
*****************************************************************************/
#include "Field.h"


CField::CField(void) : m_szValue(NULL), m_eType(DB_TYPE_UNKNOWN),m_columnName("")
{
}

CField::~CField(void)
{
    if (m_szValue != NULL)
    {
        delete [] m_szValue;
    }
}

uint32 CField::SetValue(const char *szValue)
{
    if (m_szValue != NULL)
    {
        delete [] m_szValue;
        m_szValue = NULL;
    }

    if (szValue == NULL)
    {
        m_szValue = NULL;
        return 0;
    }

    size_t nSize = strlen(szValue);
    if (m_szValue = new char[nSize + 1])
    {
        strcpy(m_szValue, szValue);
    }
    else
    {
        REPORT("Memory alloc error");
        m_szValue = NULL;
    }
    // mysql 结果集全部是char，要获得实际存储大小，需要分区一下数据类型
    switch(m_eType)
    {
    case DB_TYPE_STRING:
        break;
    case DB_TYPE_INTEGER:
        return 4;
	case DB_TYPE_BIGINT:
		return 8;
    case DB_TYPE_FLOAT:
        return 4;
    }
    return nSize;
}


const int64 CField::GetInt64(void) const
{
    if (m_szValue != NULL)
    {
        int64 value = 0;
        sscanf(m_szValue, "%llu", &value);
        return value;
    }
    return 0;
}

void CField::SetcoulmName(const char *szName)
{
    m_columnName = szName;
}
