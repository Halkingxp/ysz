/*****************************************************************************
Copyright (C), 2012-2100, ^^^^^^^^. Co., Ltd.
文 件 名:  DataBase.h
作    者:  Herry  
版    本:  1.0
完成日期:  2012-9-12
说明信息:  mysql的封装类
说明信息:  目前已知一个崩溃问题, 如果程序调用ConnectDataBase函数后, 
		   调用CloseDataBase, 再关闭程序, 程序会崩溃到析构函数.
		   此问题是由mysql_close函数导致的.
*****************************************************************************/
#pragma once
#define MAX_QUERY_LEN 1048576

#ifdef WIN32
#include "mysql.h"
#else
#include "mysql.h"
#endif

#include "Define.h"
#include "Field.h"
#include "QueryResult.h"
#include <mutex>


class CDataBase
{
public:
	CDataBase(void);
	~CDataBase(void);

public:
	int  ConnectDataBase(const char *host, uint16 port, const char *username, const char *password, const char *database);
	void CloseDataBase(void);
	void ThreadStart(void);
	void ThreadEnd(void);

	CQueryResult* Query(const char *format, ...);
	bool Execute(const char *format, ...);
	void FreeMultiQueryResult(void);
	static void TransString(String& str);

public:
	bool NotCommitExecute(const char *format,...);
	void Commit() {if(m_pMysql)mysql_commit(m_pMysql);}
private:
	std::mutex			        m_cLock;
	MYSQL						m_cSqlInit;
	MYSQL					   *m_pMysql;

	static uint16		 s_nInitCount;
};


