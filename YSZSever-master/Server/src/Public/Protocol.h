/*****************************************************************************
Copyright (C), 2013-2015, ***. Co., Ltd.
文 件 名:  Protocol.h
作    者:    
版    本:  1.0
完成日期:  2013-6-24
说明信息:  
*****************************************************************************/
#pragma once


enum Protocol
{
	SS_RECONNECT			= 98,			 // 有服务端断开连接时的通知协议
	SS_CLOSE_CONNECT		= 99,			 // 有客户端断开连接时的通知协议	该协议编号在Lua中也有定义
	SS_REQUEST_LUA			= 100,		     // 调用Lua响应函数					该协议编号在Lua中也有定义
	SS_RELOAD_LUA			= 101,			 // 加载Lua脚本文件
	SS_TEST_LUA				= 102,			 // 调用Lua测试函数
	SS_WORLD_MESSAGE		= 103,           // 测试WORLD线程是否卡死
	SC_BROADCAST_TEST		= 104,			 // 发送消息到所有Client
	SS_TO_HUBSERVER			= 105,           // 发送消息到HubServer
	SS_TO_GAMESERVER		= 106,			 // 发送消息到GameServer
	SS_TO_DBSERVER			= 107,           // 发送消息到DBServer

	SS_MAPING				= 108,           // 关联SocketID					该协议编号在Lua中也有定义
	SS_INIT_PAY_ORDER		= 109,			 // 初始化订单数据

	SDK_LOGIN				= 110,			 // SDK登录验证
	SDK_CREATE_PAY_ORDER	= 111,			 // SDK创建订单
	SDK_VERIFY_PAY_ORDER	= 112,			 // SDK验证订单
	SDK_PAY_ORDER_RESULT	= 113,			 // SDK订单处理结果					该协议编号在Lua中也有定义		
	SS_SAVE_ALL				= 120,			 // 关服回存所有数据				该协议编号在Lua中也有定义
};