/*****************************************************************************
Copyright (C), 2015-2050, ***. Co., Ltd.
作    者:  Herry  
完成日期:  2016-11-24
说明信息:  网络通讯库, 服务端部分
*****************************************************************************/
#pragma once
#include "GetTime.h"
#include "MessageIdentifiers.h"
#include "RakPeerInterface.h"
#include "RakNetStatistics.h"
#include "RakNetTypes.h"
#include "RakSleep.h"
#include "PacketLogger.h"
#include "RakNetSocket2.h"
#include "Data.h"
#include "Packet/Packet.h"


using namespace RakNet;
typedef std::map<uint32, SystemAddress> MAP_ADDRESS;

class CNetServer
{
private:
	CNetServer(void);
	~CNetServer(void);

public:
	static CNetServer& GetInstance(void);

public:
	uint8	Startup(uint32 nMaxConnecttion, uint16 nPort, const String& strPassword);
	void    Shutdown(void);
	void    Update(void);

	void	SetNotifyCloseProtocol(uint32 nNotifyCloseProtocol);
	uint32  SendToClient(CPacket& cPacket, uint32 nSocketID);
	void    SendBroadcast(CPacket& cPacket);
	String  GetClientAddress(uint32 nSocketID);
	void    CloseSocket(uint32 nSocketID);
	void	StartService(void);
	void	StopService(void);
	void    CloseAll(void);
	void    LogStatistics(void);

private:
	void	_OnNewConnection(RakNet::Packet* pPacket);
	void	_OnClosedConnection(RakNet::Packet* pPacket);
	void	_OnDispatch(RakNet::Packet* pPacket);

private:
	RakPeerInterface*	m_pServer;
	MAP_ADDRESS			m_cAddress;
	CPacket				m_cPacket;
	uint32				m_nNotifyCloseProtocol;
};

#define sNetServer    CNetServer::GetInstance()