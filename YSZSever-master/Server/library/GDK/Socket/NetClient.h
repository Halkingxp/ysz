/*****************************************************************************
Copyright (C), 2015-2050, ***. Co., Ltd.
作    者:  Herry
完成日期:  2016-11-25
说明信息:  网络通讯库, 客户端部分
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
struct ClientNode
{
	String				strCallback;
	SystemAddress		cAddress;
	RakPeerInterface*	pClient;
};

typedef std::map<uint32, ClientNode> MAP_CLIENTS;


class CNetClient
{
private:
	CNetClient(void);
	~CNetClient(void);

public:
	static CNetClient& GetInstance(void);

public:
	uint32	Connect(const String& strIP, uint16 nPort, const String& strPassword, const String& strCallback);
	void    Shutdown(uint32 nSocketID);
	void    Update(void);

	void	SetCallbackProtocol(uint32 nCallbackProtocol);
	uint32  SendToServer(CPacket& cPacket, uint32 nSocketID);
	void    SendBroadcast(CPacket& cPacket);
	void    CloseSocket(uint32 nSocketID);
	String  GetServerAddress(uint32 nSocketID);

	void    LogStatistics(void);

private:
	void	_OnClosedConnection(RakNet::Packet* pPacket);
	void	_OnDispatch(RakNet::Packet* pPacket);

private:
	MAP_CLIENTS			m_cClients;
	CPacket				m_cPacket;
	uint32				m_nCallbackProtocol;
};

#define sNetClient    CNetClient::GetInstance()