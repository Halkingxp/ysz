/*****************************************************************************
Copyright (C), 2012-2100, ^^^^^^^^. Co., Ltd.
文 件 名:  ServerCommend.cpp
作    者:  Herry   
版    本:  1.0
完成日期:  2012-11-12
说明信息:  服务器的控制台命令
*****************************************************************************/
#include "Socket/NetServer.h"
#include "Socket/NetClient.h"
#include "ServerCommend.h"
#include "Statistics/StatisticsMgr.h"
#include "World.h"
#include "ThreadWatch.h"
#include "Xml/Xml.h"
#include "Timer/TimerMgr.h"
#include "Protocol.h"
#include "DataStructure/MsgQueue.h"
#include "Tools/CalculateTools.h"
#include "Algorithm/SHA1.h"
#include "Script/ScriptLua.h"
#include "Packet/Packet.h"
//********************************************************************
//函数功能: 构造函数
//第一参数: 
//返回说明: 
//备注说明: 构造函数添加新指令
//********************************************************************
CServerCommend::CServerCommend(void)
{
	AddOrder("stat",	"显示统计数据",					(CMD_FUN)&CServerCommend::Statistics);
	AddOrder("tw",		"测试world线程是否通畅",		(CMD_FUN)&CServerCommend::TestThread);
	AddOrder("ns",		"通信日志开关",					(CMD_FUN)&CServerCommend::NetSwitch);
	AddOrder("log",		"通用日志开关",					(CMD_FUN)&CServerCommend::LogSwitch);
	AddOrder("lua",		"加载lua文件",					(CMD_FUN)&CServerCommend::Loadlua);
	AddOrder("ms",		"消息队列个数",					(CMD_FUN)&CServerCommend::MsgSize);
	AddOrder("test",	"测试Lua",						(CMD_FUN)&CServerCommend::TestLua);
    AddOrder("id",		"显示服务器ID",					(CMD_FUN)&CServerCommend::ShowServerID);

	AddOrder("toall",	"广播消息到客户端",				(CMD_FUN)&CServerCommend::SendBroadcast);
	AddOrder("tohub",	"发送消息到hb",					(CMD_FUN)&CServerCommend::SendToHubServer);
    AddOrder("todb",	"发送消息到db",					(CMD_FUN)&CServerCommend::SendToDBServer);
}

CServerCommend::~CServerCommend(void)
{
}

//*******************************************************************
//函数功能:  退出
//备注说明:  退出命令处理服务
//*******************************************************************
void CServerCommend::Quit(const STRING_VECTOR &vParam)
{
	// 必须先清空消息队列.
	sMsgQueueVec.ClearAll();

	// 终止控制台线程
	Detach();

	// 终止线程守护者
	sThreadWatch.Detach();
    
	// 终止World线程
	sWorld.Detach();

	sNetServer.Shutdown();
}

//*******************************************************************
//函数功能:  显示统计数据
//备注说明:  
//*******************************************************************
void CServerCommend::Statistics(const STRING_VECTOR &vParam)
{
	sStatisticsMgr.PrintfStatisticsInfo();
}


void CServerCommend::TestThread(const STRING_VECTOR &vParam)
{
	CPacket pack(SS_WORLD_MESSAGE);
	sMsgQueueVec.PushPacket(pack);
}


//********************************************************************
//函数功能: 开关socket消息收发输出
//第一参数: 
//返回说明: 
//备注说明: 
//********************************************************************
void CServerCommend::NetSwitch(const STRING_VECTOR &vParam)
{
	if (vParam.size() < 3)
	{
		printf("第一参数: s服务端 c客户端\r\n");
		printf("第二参数: 0关闭日志，1接收，2发送，3收发, 4异常\r\n");
		return;
	}

    String strType = vParam[1];
	uint8 nPS = atoi(vParam[2].c_str());
	if (strType == "c")
	{
        printf("--成功设置NetClient输出标志\r\n");
	}
    else
    {
        printf("--成功设置NetServer输出标志\r\n");
    }
}

//********************************************************************
//函数功能: 发送广播给客户端, 测试客户端接收消息情况
//第一参数: 
//返回说明: 
//备注说明: 
//********************************************************************
void CServerCommend::SendBroadcast(const STRING_VECTOR &vParam)
{
	if (vParam.size() < 2)
	{
		printf("第一参数: 发送内容\r\n");
		return;
	}

	String strString = vParam[1].c_str();

	CPacket cp(SC_BROADCAST_TEST);
	cp.WriteString(strString);
}

//********************************************************************
//函数功能: 发送消息到HubServer
//第一参数: 
//返回说明: 
//备注说明: 
//********************************************************************
void CServerCommend::SendToHubServer(const STRING_VECTOR &vParam)
{
	CPacket cp(SS_TO_HUBSERVER);
}

//********************************************************************
//函数功能: 发送消息到DBServer
//第一参数: 
//返回说明: 
//备注说明: 
//********************************************************************
void CServerCommend::SendToDBServer(const STRING_VECTOR &vParam)
{
    CPacket cp(SS_TO_DBSERVER);
}

void CServerCommend::Loadlua(const STRING_VECTOR &vParam)
{
	if (vParam.size() < 2)
	{
		printf("第一参数: all加载全部  或者指定脚本名字\r\n");
		return;
	}
    String strLuafile = vParam[1];
    
    CPacket cPacket(SS_RELOAD_LUA);
    cPacket.WriteString(strLuafile);
    sMsgQueueVec.PushPacket(cPacket);
}

void CServerCommend::MsgSize( const STRING_VECTOR &vParam )
{
	printf("MsgQueue Size: %d, MaxCount: %d\r\n", sMsgQueueVec.GetSize(), sMsgQueueVec.GetMaxCount());
}


void CServerCommend::LogSwitch(const STRING_VECTOR &vParam)
{
    if (vParam.size() != 2)
    {
        printf("参数错误\r\n");
        return;
    }

    uint8 nWriteLog = (uint8)CStringTools::StringToInt(vParam[1]);
    CScriptLua::SetWriteLog(nWriteLog);
}

void CServerCommend::TestLua(const STRING_VECTOR &vParam)
{
    if (vParam.size() < 2)
    {
        printf("参数错误, 第一参数HeroID\r\n");
        return;
    }

    uint32 nHeroID = (uint32)CStringTools::StringToInt(vParam[1]);

    CPacket cPacket(SS_TEST_LUA);
    cPacket.WriteUint32(nHeroID);
    sMsgQueueVec.PushPacket(cPacket);
}


void CServerCommend::ShowServerID( const STRING_VECTOR &vParam )
{
    printf("------------------------------------\r\n");
	printf("------------------ HubServer\r\n");
    printf("------------------------------------\r\n");
}