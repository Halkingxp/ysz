/*****************************************************************************
Copyright (C), 2012-2100, ^^^^^^^^. Co., Ltd.
文 件 名:  Command.h
作    者:  Herry  
版    本:  1.0
完成日期:  2012-8-30
说明信息:  控制台的指令类
*****************************************************************************/
#pragma once
#include "Define.h"
#include "Thread/Thread.h"

struct Order;
class CCommand;

typedef std::map<std::string, Order> ORDER_MAP;
typedef void (CCommand::* CMD_FUN) (const STRING_VECTOR &vParam);

// 指令对象
struct Order
{
	std::string		strHelp;
	CMD_FUN			pFun;
};

// 指令集对象, 派生后可添加新的指令
class CCommand : public CThread
{
public:
	CCommand(void);
	virtual ~CCommand(void);

public:
	void SetServerName(const String& strServerName) { m_strName = strServerName; }

protected:
	virtual void Run(void);
	virtual void Quit(const STRING_VECTOR &vParam);
	virtual void Help(const STRING_VECTOR &vParam);
	virtual void Cls(const STRING_VECTOR &vParam);

protected:
	int 	AddOrder(const char *szName, const char *szHelp, const CMD_FUN pFun);
	Order*  AnalyzeOrder(char *szData);

private:
	ORDER_MAP		m_mOrderMap;				// 指令集
	STRING_VECTOR   m_vParams;					// 参数集
	String			m_strName;					// 服务器名字
};
