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
	void RequestExecuteSQL(const String& strSQL, uint32 nProtocol);
	int  Initialize(const String& directory);
	int  Destroy(void);

public:
	inline uint16 GetServerID(void) { return m_nServerID; }		// 获得服务器ID	
	inline bool   IsPrintf() { return m_isPrintf; }
	inline void   SetIsPrintf(bool isPrintf) { m_isPrintf = isPrintf; }
	inline uint32 GetGameSocketID() const { return m_nGameSocketID; }
	inline void   SetGameSocketID(uint32 val) { m_nGameSocketID = val; }

protected:
	virtual void Run(void);
	void	MsgProc(CPacket &cPacket);

private:
	static void _OnGameMapping(CPacket& cPacket);
	static void _OnReConnect(CPacket &cPacket);							// 有服务端断开连接的回调机制
    static void _OnReloadLua(CPacket &cPacket);							// 加载Lua脚本文件
	static void _OnResponesLua(CPacket &cPacket);						// 调用Lua响应函数
	static void _OnTestLua(CPacket &CPacket);							// 调用Lua测试函数
	static void _OnTestThread(CPacket &CPacket);						// 测试World线程是否通畅

private:
	bool				m_isPrintf;             // 是否打印SDK日志输出信息, true开启
	uint16		        m_nServerID;			// 服务器组的ID
	uint32				m_nDBSocketID;			// DBServer的SocketID
	uint32				m_nGameSocketID;		// GameServer的SocketID
	MSG_CALLBACK_MAP    m_cCallBackmap;         // 消息回调
};

#define sWorld CWorld::GetInstance()

