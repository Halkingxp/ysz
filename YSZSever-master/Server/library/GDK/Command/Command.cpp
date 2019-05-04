/*****************************************************************************
Copyright (C), 2012-2100, ^^^^^^^^. Co., Ltd.
文 件 名:  Command.cpp
作    者:  Herry   
版    本:  1.0
完成日期:  2012-8-30
说明信息:  控制台指令
*****************************************************************************/
#include "Command.h"
#include "Tools/StringTools.h"

using namespace std;

//********************************************************************
//函数功能: 构造函数
//第一参数: 
//返回说明: 
//备注说明: 可直接在派生类的构造函数添加新指令
//********************************************************************
CCommand::CCommand(void)
{
	AddOrder("help", "帮助信息", (CMD_FUN)&CCommand::Help);

#if defined(WIN32)
	//AddOrder("quit", "退出程序", (CMD_FUN)&CCommand::Quit);
	AddOrder("cls", "清屏命令", (CMD_FUN)&CCommand::Cls);
#endif
}

CCommand::~CCommand(void)
{
	m_mOrderMap.clear();
	m_vParams.clear();
}

//*******************************************************************
//函数功能:  添加一个指令
//
//第一参数:  指令名称
//第二参数:  指令帮助信息
//第三参数:  回调函数
//
//返回说明:  -1 参数有空指针
//返回说明:  -2 指令重复
//返回说明:   0 添加成功
//
//备注说明:  添加失败是因为参数中有空指针
//*******************************************************************
int CCommand::AddOrder(const char *szName, const char *szHelp, const CMD_FUN pFun)
{
	if (szName == NULL || szHelp == NULL || pFun == NULL)
	{
		return false;
	}

	ORDER_MAP::iterator it = m_mOrderMap.find(szName);
	if (it != m_mOrderMap.end())
	{
		return false;
	}

	Order cOrder = {};
	cOrder.strHelp = szHelp;
	cOrder.pFun = pFun;

	m_mOrderMap.insert(std::make_pair(szName, cOrder));
	return true;
}

//*******************************************************************
//函数功能:  分析命令
//
//第一参数:  控制台输入的数据
//
//返回说明:  输入的指令存在, 返回指令对象
//返回说明:  输入的指令不存在, 返回NULL
//*******************************************************************
Order* CCommand::AnalyzeOrder(char *szData)
{
	// 清空参数集
	m_vParams.clear();
	m_vParams = CStringTools::Tokenizer(szData, ' ');

	if (m_vParams.size() > 0)
	{
		const char *szOrderName = m_vParams[0].c_str();
		ORDER_MAP::iterator it = m_mOrderMap.find(szOrderName);
		if (it != m_mOrderMap.end())
		{
			return &it->second;
		}
	}
	return NULL;
}

//********************************************************************
//函数功能: 线程执行函数
//第一参数: 
//返回说明: 
//备注说明: 控制台输入quit指令可结束此线程
//********************************************************************
void CCommand::Run(void)
{
	printf("输入 help 查询所有的指令\r\n");

	char szBuffer[BUFFER_LEN] = {};
	while (IsRun())
	{
		memset(szBuffer, 0, BUFFER_LEN);
		fgets(szBuffer, BUFFER_LEN, stdin);

		// 去掉回车符
		szBuffer[strlen(szBuffer) - 1] = '\0';

		Order *pOrder = AnalyzeOrder(szBuffer);
		if (pOrder)						
		{
			(this->*(pOrder->pFun))(m_vParams);
		}
		else
		{
			printf("不能识别的指令, 请检查输入的指令! (注意指令有大小写区分!!)\r\n");
		}
	}	
}
//*******************************************************************
//函数功能:  帮助
//
//备注说明:  显示所有命令的帮助信息
//*******************************************************************
void CCommand::Help(const STRING_VECTOR &vParam)
{
	printf("-------------------------------------------------------\r\n");
	printf("--------------------- %s ------------------------\r\n", m_strName.c_str());
	printf("-------------------------------------------------------\r\n");
	ORDER_MAP::iterator it = m_mOrderMap.begin();
	while (it != m_mOrderMap.end())
	{
		printf("%-15s%s\n", it->first.c_str(), it->second.strHelp.c_str());
		it++;
	}
	printf("-------------------------------------------------------\r\n");
}

//********************************************************************
//函数功能: 清屏命令
//第一参数:
//返回说明: 
//异常说明:
//备注说明: 
//********************************************************************
void CCommand::Cls(const STRING_VECTOR &vParam)
{
	system("cls");
	printf("输入 help 查询所有的指令\r\n");
}

//*******************************************************************
//函数功能:  退出
//
//备注说明:  退出命令处理服务
//*******************************************************************
void CCommand::Quit(const STRING_VECTOR &vParam)
{
	Detach();
}


















