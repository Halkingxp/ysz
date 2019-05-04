/*****************************************************************************
Copyright (C), 2012-2100, ^^^^^^^^. Co., Ltd.
文 件 名:  World.h
作    者:  Herry  
版    本:  1.0
完成日期:  2012-11-12
说明信息:  
*****************************************************************************/
#pragma once
#include "Thread/Thread.h"
#include "Packet/Packet.h"

#define RegMsgCallbackFun(OP, CallbackFun) sWorld.RegMsgCallBackFun(OP, CallbackFun);

typedef void (*CallBackFun)(CPacket&);
typedef std::map<uint32, CallBackFun> MSG_CALLBACK_MAP;

class CWorld : public CThread
{
private:
    CWorld(void);
    virtual ~CWorld(void);

public:
	static CWorld& GetInstance(void);
    bool RegMsgCallBackFun(uint32 nOpcode, CallBackFun pFun);
	int  Initialize(void);
	int  Destroy(void);

public:
	void   Run(void);
	void   MsgProc(CPacket &cPacket);

private:
	static void _OnTestThread(CPacket &CPacket);							// 测试World线程是否通畅
    static void _OnRequestData(CPacket &cPacket);							// 响应数据请求消息
	static void _OnTestNetMsg(CPacket &cPacket);								// 响应网络测试消息

private:
    MSG_CALLBACK_MAP m_cCallBackmap;  // 消息回调
};

#define sWorld CWorld::GetInstance()
