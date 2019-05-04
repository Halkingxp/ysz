/*****************************************************************************
Copyright (C), 2012-2100, ^^^^^^^^. Co., Ltd.
文 件 名:  DataBase.cpp
作    者:  Herry   
版    本:  1.0
完成日期:  2012-9-12
说明信息:  mysql的封装类
*****************************************************************************/
#include "DataBase.h"
#include "Tools/StringTools.h"

uint16 CDataBase::s_nInitCount = 0;

CDataBase::CDataBase() : m_pMysql(NULL)
{
	if (0 == s_nInitCount)
	{
		mysql_library_init(-1, NULL, NULL);
		if (!mysql_thread_safe())
		{
			printf("数据库不是线程安全的\r\n");
		}
	}

	s_nInitCount++;
}

CDataBase::~CDataBase()
{
	s_nInitCount--;
	if (0 == s_nInitCount)
	{
		mysql_library_end();
	}
}

//********************************************************************
//函数功能: 初始化函数
//第一参数: [IN] 数据库地址 (可以是数据库IP地址, 也可以是localhost)
//第二参数: [IN] 数据库端口
//第三参数: [IN] 数据库用户名
//第四参数: [IN] 数据库密码
//第五参数: [IN] 数据库表名
//返回说明: 返回-1,  数据库初始化失败
//返回说明: 返回-2,  数据库连接失败
//返回说明: 返回 0,  数据库连接成功
//备注说明: 
//********************************************************************
int CDataBase::ConnectDataBase(const char *host, uint16 port, const char *username, const char *password, const char *database)
{
	MYSQL *pMySqlInit = mysql_init(&m_cSqlInit);
	if (pMySqlInit == NULL)
	{
		return -1;
	}

	my_bool reconnect = 1;
	int connect_timeout = 0;
	mysql_options(pMySqlInit, MYSQL_OPT_RECONNECT, &reconnect);
	mysql_options(pMySqlInit, MYSQL_SET_CHARSET_NAME, "utf8");
	mysql_options(pMySqlInit, MYSQL_OPT_CONNECT_TIMEOUT, &connect_timeout);

    m_pMysql = mysql_real_connect(pMySqlInit, host, username, password, database, port, 0, CLIENT_MULTI_STATEMENTS);
    if (m_pMysql)
    {
        /*----------SET AUTOCOMMIT ON---------*/
        // It seems mysql 5.0.x have enabled this feature
        // by default. In crash case you can lose data!!!
        // So better to turn this off
        if (!mysql_autocommit(m_pMysql, 0))
		{
            //printf("MySQL AUTOCOMMIT SUCCESSFULLY SET TO 1\r\n");
		}
        else
		{
            //printf("MySQL AUTOCOMMIT NOT SET TO 1\r\n");
		}
        // set connection properties to UTF8 to properly handle locales for different
        // server configs - core sends data in UTF8, so MySQL must expect UTF8 too
		Execute("SET NAMES `utf8`;");
		Execute("SET CHARACTER SET `utf8`;");
        return 0;
    }
    else
    {
        mysql_close(&m_cSqlInit);
        return -2;
    }
}

//********************************************************************
//函数功能: 关闭数据库连接
//第一参数: 
//返回说明: 
//备注说明: 1.调用此函数后, 需要调用ConnectDataBase函数.
//备注说明: 2.否则关闭程序会崩溃到析构函数, 原因与mysql_close函数有关.
//********************************************************************
void CDataBase::CloseDataBase(void)
{
	mysql_close(m_pMysql);
	m_pMysql = NULL;
}

//********************************************************************
//函数功能: 启动MySQL线程
//第一参数: 
//返回说明: 
//备注说明: 必须在调用第一个查询前启动线程
//********************************************************************
void CDataBase::ThreadStart()
{
    mysql_thread_init();
}

//********************************************************************
//函数功能: 终止MySQL线程
//第一参数: 
//返回说明: 
//备注说明: 必须在程序终止前终止线程
//********************************************************************
void CDataBase::ThreadEnd()
{
    mysql_thread_end();
}

//********************************************************************
//函数功能: 释放所有结果
//第一参数: 
//返回说明: 
//备注说明: 
//********************************************************************
void CDataBase::FreeMultiQueryResult()
{
	MYSQL_RES *pResult = NULL;
	while(!mysql_next_result(m_pMysql));
	{
		pResult = mysql_store_result(m_pMysql);
		mysql_free_result(pResult);
		pResult = NULL;
	}
}


//********************************************************************
//函数功能: 执行SQL查询

//第一参数: [IN] 组装的SQL格式, 可以直接传SQL语句
//第二参数: [IN] 组装的参数

//返回说明: 返回QueryResult对象  执行查询成功
//返回说明: 返回NULL				执行查询失败

//备注说明: 外部负责释放QueryResult对象的内存空间
//********************************************************************
CQueryResult* CDataBase::Query(const char *format, ...)
{
	static char szQuery[MAX_QUERY_LEN] = {};
	if (m_pMysql == NULL || format == NULL)
	{
		return NULL;
	}

	std::lock_guard<std::mutex> g(m_cLock);

	va_list ap;
	va_start(ap, format);
	int res = vsnprintf(szQuery, MAX_QUERY_LEN, format, ap);
	va_end(ap);

	if (res == -1)
	{
		char szInfo[512] = {};
		sprintf(szInfo, "Query组装SQL语句错误: %s", format);
		REPORT(szInfo);
		return NULL;
	}

    uint32 uQueryLen = (uint32)strlen(szQuery);
	int error = mysql_real_query(m_pMysql, szQuery, uQueryLen);
	if (error != 0)
	{
		char szInfo[8096] = {};
		sprintf(szInfo, "Query执行SQL错误,错误码:=%d 错误原因:=%s \r\nSQLLen:%d SQL:%s", mysql_errno(m_pMysql), mysql_error(m_pMysql), uQueryLen, szQuery);
		REPORT(szInfo);
		return NULL;
	}
    
	mysql_commit(m_pMysql);

	MYSQL_RES *pResult = mysql_store_result(m_pMysql);
	if (pResult == NULL)
	{
		return NULL;
	}
	
	MYSQL_FIELD *pFields = mysql_fetch_fields(pResult);
	uint32 nRowCount = (uint32)mysql_affected_rows(m_pMysql);
	uint32 nFieldCount = (uint32)mysql_field_count(m_pMysql);

	if (pResult == NULL)
	{
		return NULL;
	}
	if (nRowCount == 0 || pFields == NULL)
	{
		mysql_free_result(pResult);
        int s = mysql_next_result(m_pMysql);
		return NULL;
	}

	CQueryResult *pQueryResult = new CQueryResult(pResult, pFields, nRowCount, nFieldCount);
	if (pQueryResult == NULL)
	{
		mysql_free_result(pResult);
        int s = mysql_next_result(m_pMysql);
		return NULL;
	}
    
	pQueryResult->NextRow();

    // 如果语句中需要调用存储过程，必须加上这句，否则下一次执行sql语句会报错
    int s = mysql_next_result(m_pMysql);
    if (s > 0)
    {
        char szInfo[512] = {};
        sprintf(szInfo, "结果集错误:%d", s);
        REPORT(szInfo);
        return NULL;
    }
	return pQueryResult;
}


//********************************************************************
//函数功能: 执行SQL语句
//第一参数: [IN] 组装的SQL格式
//第二参数: [IN] 组装的参数
//返回说明: 返回true  执行成功
//返回说明: 返回false 执行失败
//备注说明:
//********************************************************************
bool CDataBase::Execute(const char *format,...)
{
	static char szQuery[MAX_QUERY_LEN] = {};
	if (format == NULL)
	{
		return false;
	}

	std::lock_guard<std::mutex> g(m_cLock);

	va_list ap;
	va_start(ap, format);
	int res = vsnprintf(szQuery, MAX_QUERY_LEN, format, ap);
	va_end(ap);

	if (res == -1)
	{
		char szInfo[512] = {};
		sprintf(szInfo, "Execute组装SQL语句错误: %s", format);
		REPORT(szInfo);
		return false;
	}

    uint32 uQueryLen = (uint32)strlen(szQuery);
	int error = mysql_real_query(m_pMysql, szQuery, uQueryLen);

	MYSQL_RES *pResult = NULL;
	do
	{
		pResult = mysql_store_result(m_pMysql);
		mysql_free_result(pResult);
		pResult = NULL;
	}
	while (!mysql_next_result(m_pMysql));

	if (error != 0)
	{
        char szInfo[8096] = {};
        sprintf(szInfo, "Execute执行SQL错误,错误码:=%d 错误原因:=%s \r\nSQLLen:%d SQL:%s", mysql_errno(m_pMysql), mysql_error(m_pMysql), uQueryLen, szQuery);
        REPORT(szInfo);
		return false;
	}
	mysql_commit(m_pMysql);
	return true;
}


//********************************************************************
//函数功能: String类型的需要处理某些特殊的字符['"\]
//第一参数: [IN,OUT] 输入的数据,替换后的数据
//返回说明: 
//备注说明:
//********************************************************************
void CDataBase::TransString(String& str)
{
	static String src_1 = "\\";
	static String src_2 = "\'";
	static String src_3 = "\"";

	static String des_1 = "\\\\";
	static String des_2 = "\\'";
	static String des_3 = "\\\"";

	CStringTools::StringReplace(str, src_1, des_1);
	CStringTools::StringReplace(str, src_2, des_2);
	CStringTools::StringReplace(str, src_3, des_3);
}

bool CDataBase::NotCommitExecute(const char *format,...)
{
	static char szQuery[MAX_QUERY_LEN] = {};
	if (format == NULL)
	{
		return false;
	}

	std::lock_guard<std::mutex> g(m_cLock);

	va_list ap;
	va_start(ap, format);
	int res = vsnprintf(szQuery, MAX_QUERY_LEN, format, ap);
	va_end(ap);

	if (res == -1)
	{
		char szInfo[512] = {};
		sprintf(szInfo, "NotCommitExecute组装SQL语句错误: %s", format);
		REPORT(szInfo);
		return false;
	}

    uint32 uQueryLen = (uint32)strlen(szQuery);
	int error = mysql_real_query(m_pMysql, szQuery, uQueryLen);
	if (error != 0)
	{
        char szInfo[8096] = {};
        sprintf(szInfo, "NotCommitExecute执行SQL错误,错误码:=%d 错误原因:=%s \r\nSQLLen:%d SQL:%s", mysql_errno(m_pMysql), mysql_error(m_pMysql), uQueryLen, szQuery);
        REPORT(szInfo);
		return false;
	}
	//mysql_commit(m_pMysql);
	return true;
}
