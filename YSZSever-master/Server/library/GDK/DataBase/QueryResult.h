/*****************************************************************************
Copyright (C), 2012-2100, ^^^^^^^^. Co., Ltd.
文 件 名:  QueryResult.h
作    者:  Herry  
版    本:  1.0
完成日期:  2012-9-12
说明信息:  SQL执行的结果
*****************************************************************************/
#pragma once

#ifdef WIN32
#include "mysql.h"
#else
#include "mysql.h"
#endif

#include "Field.h"

class CQueryResult
{
public:
    CQueryResult(MYSQL_RES *pResult, MYSQL_FIELD *pFields, uint32 nRowCount, uint32 nFieldCount);
    virtual ~CQueryResult(void);

public:
    bool NextRow(void);
    const CField& operator[](uint32 nIndex) const;

public:
    inline CField* Fetch(void) const		 { return m_pCurrentRow; }
    inline uint32  GetFieldCount(void) const { return m_nFieldCount; }
    inline uint32  GetRowCount(void) const	 { return m_nRowCount;   }
    inline uint32  GetCurrentTotalByte(void)const { return m_nCurrentTotalByte;}

private:
    DataTypes _ConvertNativeType(enum_field_types mysqlType) const;
    void	  _EndQuery(void);

private:
    MYSQL_RES  *m_pResult;
    CField	   *m_pCurrentRow;
    uint32      m_nCurrentTotalByte;
    uint32		m_nFieldCount;
    uint32		m_nRowCount;
};
