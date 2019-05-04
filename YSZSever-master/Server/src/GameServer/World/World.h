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
	int  Initialize(const String& directory);
	int  Destroy(void);

public:
	inline uint16 GetServerID(void)			{ return m_nServerID; }		// 获得服务器ID	

protected:
	virtual void Run(void);
	void	MsgProc(CPacket &cPacket);

private:
	
	static void _OnReConnect(CPacket &cPacket);							// 有服务端断开连接的回调机制
    static void _OnReloadLua(CPacket &cPacket);							// 加载Lua脚本文件
	static void _OnResponesLua(CPacket &cPacket);						// 调用Lua响应函数
	static void _OnTestLua(CPacket &cPacket);							// 调用Lua测试函数
	static void _OnTestThread(CPacket &cPacket);						// 测试World线程是否通畅
	static void _OnTestNetMsg(CPacket &cPacket);						// 测试网络消息

private:
	uint16		        m_nServerID;			// 服务器组的ID
    MSG_CALLBACK_MAP    m_cCallBackmap;         // 消息回调
};

#define sWorld CWorld::GetInstance()

