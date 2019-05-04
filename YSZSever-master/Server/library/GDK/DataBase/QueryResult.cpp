/*****************************************************************************
Copyright (C), 2012-2100, ^^^^^^^^. Co., Ltd.
文 件 名:  QueryResult.cpp
作    者:  Herry   
版    本:  1.0
完成日期:  2012-9-12
说明信息:  SQL执行的结果
*****************************************************************************/
#include "QueryResult.h"


CQueryResult::CQueryResult(MYSQL_RES *pResult, MYSQL_FIELD *pFields, uint32 nRowCount, uint32 nFieldCount)
    : m_nRowCount(nRowCount), m_nFieldCount(nFieldCount), m_pResult(pResult),m_nCurrentTotalByte(1)
{

    m_pCurrentRow = new CField[m_nFieldCount];
    for (uint32 i = 0; i < m_nFieldCount; i++)
    {
        m_pCurrentRow[i].SetType(_ConvertNativeType(pFields[i].type));
        m_pCurrentRow[i].SetcoulmName(pFields[i].name);
    }
}

CQueryResult::~CQueryResult()
{
    _EndQuery();
}


const CField& CQueryResult::operator[](uint32 nIndex) const
{
    if (nIndex >= m_nFieldCount)
    {
        static CField field;
        return field;
    }
    return m_pCurrentRow[nIndex];
}

bool CQueryResult::NextRow()
{
    if (!m_pResult)
    {
        return false;
    }

    MYSQL_ROW row = mysql_fetch_row(m_pResult);
    if (!row)
    {
        _EndQuery();
        return false;
    }
    m_nCurrentTotalByte = 1;
    for (uint32 i = 0; i < m_nFieldCount; i++)
    {
        m_nCurrentTotalByte += m_pCurrentRow[i].SetValue(row[i]);
    }

    return true;
}

void CQueryResult::_EndQuery()
{
    if (m_pCurrentRow)
    {
        delete [] m_pCurrentRow;
        m_pCurrentRow = 0;
    }

    if (m_pResult)
    {
        mysql_free_result(m_pResult);
        m_pResult = 0;
    }
}

DataTypes CQueryResult::_ConvertNativeType(enum_field_types mysqlType) const
{
    switch (mysqlType)
    {
    case FIELD_TYPE_TIMESTAMP:
    case FIELD_TYPE_DATE:
    case FIELD_TYPE_TIME:
    case FIELD_TYPE_DATETIME:
    case FIELD_TYPE_YEAR:
    case FIELD_TYPE_STRING:
    case FIELD_TYPE_VAR_STRING:
    case FIELD_TYPE_BLOB:
    case FIELD_TYPE_SET:
    case FIELD_TYPE_NULL:
        return DB_TYPE_STRING;
    case FIELD_TYPE_TINY:
    case FIELD_TYPE_SHORT:
    case FIELD_TYPE_LONG:
    case FIELD_TYPE_INT24:
    case FIELD_TYPE_ENUM:
        return DB_TYPE_INTEGER;
	case FIELD_TYPE_LONGLONG:
		return DB_TYPE_BIGINT;
    case FIELD_TYPE_DECIMAL:
    case FIELD_TYPE_FLOAT:
    case FIELD_TYPE_DOUBLE:
        return DB_TYPE_FLOAT;
    default:
        return DB_TYPE_UNKNOWN;
    }
}
