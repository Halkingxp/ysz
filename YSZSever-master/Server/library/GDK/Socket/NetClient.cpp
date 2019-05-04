/*****************************************************************************
Copyright (C), 2015-2050, ***. Co., Ltd.
作       者:  Herry
完成日期:  2016-11-25
说明信息:  网络通讯库, 客户端部分
*****************************************************************************/
#include "NetClient.h"
#include "log4z/log4z.h"
#include "DataStructure/MsgQueue.h"
#include "MessageIdentifiers.h"


CNetClient& CNetClient::GetInstance(void)
{
	static CNetClient object;
	return object;
}

CNetClient::CNetClient(void) : m_nCallbackProtocol(0)
{
}

CNetClient::~CNetClient(void)
{
}

//********************************************************************
//函数功能: 连接服务器通信模块
//第一参数: 服务器IP
//第二参数: 服务器端口
//第三参数: 连接密码
//第四参数: 有服务端断开连接的回调函数, 只会回调一次
//返回说明: 返回1, 重复初始化
//返回说明: 返回2, 初始化通信模块实例失败
//返回说明: 返回3, 绑定监听端口失败
//返回说明: 返回4, 连接服务器失败
//返回说明: 返回>4, 成功
//备注说明: 成功返回的是SocketID
//********************************************************************
uint32 CNetClient::Connect(const String& strIP, uint16 nPort, const String& strPassword, const String& strCallback)
{
	ClientNode cNode;
	cNode.strCallback = strCallback;
	cNode.cAddress = SystemAddress(strIP.c_str(), nPort);
	uint32 nSocketID = SystemAddress::ToInteger(cNode.cAddress);
	MAP_CLIENTS::iterator it = m_cClients.find(nSocketID);

	// 断线重连处理
	ConnectionAttemptResult nRet = CONNECTION_ATTEMPT_STARTED;
	if (it != m_cClients.end())
	{
		nRet = it->second.pClient->Connect(strIP.c_str(), nPort, strPassword.c_str(), strPassword.length());
		if (CONNECTION_ATTEMPT_STARTED != nRet)
		{
			sprintf(g_szInfo, "Client ReConnect Failed, Remote Addres:%s, Result:%d", cNode.cAddress.ToString(), nRet);
			REPORT(g_szInfo);
			return 5;
		}

		LOGFMTI("Client ReConnect Server: SocketID:%u, Remote Address: %s", nSocketID, cNode.cAddress.ToString());

		// 等待1秒, 等待收到连接成功消息
#if defined WIN32
		std::this_thread::sleep_for(std::chrono::milliseconds(1000));
#else
		usleep(1000 * 1000);
#endif
		return nSocketID;
	}

	cNode.pClient = RakPeerInterface::GetInstance();
	if (!cNode.pClient)
	{
		REPORT("Client Communication module is creation failed");
		return 2;
	}

	if (strPassword.length() > 0)
	{
		cNode.pClient->SetIncomingPassword(strPassword.c_str(), strPassword.length());
	}
	cNode.pClient->SetTimeoutTime(10000, UNASSIGNED_SYSTEM_ADDRESS);
	cNode.pClient->SetLimitIPConnectionFrequency(true);

	SocketDescriptor cSocketDescriptors;
	cSocketDescriptors.port = 0;
	cSocketDescriptors.socketFamily = AF_INET; // Test out IPV4
	StartupResult nResult = cNode.pClient->Startup(1, &cSocketDescriptors, 1);
	if (nResult != RakNet::RAKNET_STARTED)
	{
		sprintf(g_szInfo, "Client failed to Startup, Result:%d", nResult);
		REPORT(g_szInfo);
		return 3;
	}

	cNode.pClient->SetMaximumIncomingConnections(1);
	cNode.pClient->SetUnreliableTimeout(1000);
	nRet = cNode.pClient->Connect(strIP.c_str(), nPort, strPassword.c_str(), strPassword.length());
	if (CONNECTION_ATTEMPT_STARTED != nRet)
	{
		sprintf(g_szInfo, "Client Connect Failed, Remote Addres:%s, Result:%d", cNode.cAddress.ToString(), nRet);
		REPORT(g_szInfo);
		return 4;
	}

	LOGFMTI("Client Connect Server: SocketID:%u, Remote Address: %s", nSocketID, cNode.cAddress.ToString());

	m_cClients.insert(std::make_pair(nSocketID, cNode));

	// 等待1秒, 等待收到连接成功消息
#if defined WIN32
	std::this_thread::sleep_for(std::chrono::milliseconds(1000));
#else
	usleep(1000 * 1000);
#endif
	return nSocketID;
}



//********************************************************************
//函数功能: 关闭服务端网络模块
//第一参数: 
//返回说明: 
//备注说明: 
//********************************************************************
void CNetClient::Shutdown(uint32 nSocketID)
{
	MAP_CLIENTS::iterator it = m_cClients.find(nSocketID);
	if (it != m_cClients.end())
	{
		it->second.pClient->Shutdown(300);
		RakPeerInterface::DestroyInstance(it->second.pClient);
		it->second.pClient = NULL;

		m_cClients.erase(nSocketID);

		LOGFMTI("Client Connection Module Shutdown,SocketID:%u, Remote Addres:%s", nSocketID, it->second.cAddress.ToString());
	}
}

//********************************************************************
//函数功能: 更新通信模块
//第一参数: 
//返回说明: 
//备注说明: 
//********************************************************************
void CNetClient::Update(void)
{
	MAP_CLIENTS::iterator it = m_cClients.begin();
	MAP_CLIENTS::iterator end = m_cClients.end();
	while (it != end)
	{		
		RakPeerInterface* pClient = it->second.pClient; 
		it++;
		if (pClient == NULL)
		{
			continue;
		}

		for (RakNet::Packet* pPacket = pClient->Receive(); pPacket != NULL; pClient->DeallocatePacket(pPacket), pPacket = pClient->Receive())
		{
			if (pPacket == NULL)
			{
				break;
			}

			uint8 nRakNetID = (uint8)(pPacket->data[0]);
			switch (nRakNetID)
			{
			case ID_USER_PACKET_ENUM:
				_OnDispatch(pPacket);
				break;
			case ID_DISCONNECTION_NOTIFICATION:
			case ID_CONNECTION_LOST:
				_OnClosedConnection(pPacket);
				break;
			//case ID_NEW_INCOMING_CONNECTION:
			//case ID_CONNECTION_REQUEST_ACCEPTED:
				//LOGFMTI("-----------> New Connection: %s", pPacket->systemAddress.ToString());
				//break;
			case ID_CONNECTION_ATTEMPT_FAILED:
				LOGFMTI("-----------> Connection Server Failed: %s", pPacket->systemAddress.ToString());
				break;
			case ID_INVALID_PASSWORD:
				LOGFMTI("-----------> Need a Password to Connect: %s", pPacket->systemAddress.ToString());
				break;
			case ID_CONNECTED_PING:
			case ID_UNCONNECTED_PING:
				LOGFMTI("-----------> Ping From %s:", pPacket->systemAddress.ToString());
				break;
			}
		}
	}
}

//********************************************************************
//函数功能: 断开连接触发
//第一参数: 
//返回说明: 
//备注说明: 
//********************************************************************
void CNetClient::_OnClosedConnection(RakNet::Packet* pPacket)
{
	uint32 nSocketID = SystemAddress::ToInteger(pPacket->systemAddress);
	MAP_CLIENTS::iterator it = m_cClients.find(nSocketID);
	if (it != m_cClients.end())
	{
		String strCallback = it->second.strCallback;
		if (strCallback.length() > 0 && m_nCallbackProtocol > 0)
		{
			CPacket cRet;
			cRet.SetSocketID(nSocketID);
			cRet.Reset(m_nCallbackProtocol);
			cRet.WriteString(strCallback);
			sMsgQueueVec.PushPacket(cRet);
		}
		else
		{
			m_cClients.erase(nSocketID);
		}

		LOGFMTI("From Server Connection Closed, Remote Address:%s, SocketID:%u", pPacket->systemAddress.ToString(), nSocketID);
	}
}

//********************************************************************
//函数功能: 消息中转
//第一参数: 
//返回说明: 
//备注说明: 
//********************************************************************
void CNetClient::_OnDispatch(RakNet::Packet* pPacket)
{
	uint32 nSocketID = SystemAddress::ToInteger(pPacket->systemAddress);

	m_cPacket.SetSocketID(nSocketID);
	m_cPacket.Reset((char*)pPacket->data, pPacket->length);
	sMsgQueueVec.PushPacket(m_cPacket);
}

//********************************************************************
//函数功能: 发送消息到客户端
//第一参数: 消息包
//第二参数: 客户端SocketID
//返回说明: 
//备注说明: 
//********************************************************************
uint32 CNetClient::SendToServer(CPacket& cPacket, uint32 nSocketID)
{
	MAP_CLIENTS::iterator it = m_cClients.find(nSocketID);
	if (it != m_cClients.end())
	{
		it->second.pClient->Send(cPacket.GetData(), cPacket.GetSize(), HIGH_PRIORITY, RELIABLE_ORDERED, 0, it->second.cAddress, false);
	}
	return 0;
}

//********************************************************************
//函数功能: 广播消息到所有客户端
//第一参数: 消息包
//返回说明: 
//备注说明: 
//********************************************************************
void CNetClient::SendBroadcast(CPacket& cPacket)
{
	MAP_CLIENTS::iterator it = m_cClients.begin();
	MAP_CLIENTS::iterator node = it;
	while (it != m_cClients.end())
	{
		node = it;
		it++;

		node->second.pClient->Send(cPacket.GetData(), cPacket.GetSize(), HIGH_PRIORITY, RELIABLE_ORDERED, 0, node->second.cAddress, true);
	}
}

//********************************************************************
//函数功能: 关闭指定SocketID的连接
//第一参数: 客户端SocketID
//返回说明: 
//备注说明: 
//********************************************************************
void CNetClient::CloseSocket(uint32 nSocketID)
{
	MAP_CLIENTS::iterator it = m_cClients.find(nSocketID);
	if (it != m_cClients.end())
	{
		RakPeerInterface* pClient = it->second.pClient;

		ConnectionState nState = pClient->GetConnectionState(it->second.cAddress);
		LOGFMTI("Client Will Close A Connection State:%d, SocketID:%u, Remote Address:%s", nState, nSocketID, it->second.cAddress.ToString());

		pClient->CloseConnection(AddressOrGUID(it->second.cAddress), true);
	}
}

//********************************************************************
//函数功能: 获得指定SocketID的IP地址
//第一参数: 客户端SocketID
//返回说明: 
//备注说明: 
//********************************************************************
String CNetClient::GetServerAddress(uint32 nSocketID)
{
	MAP_CLIENTS::iterator it = m_cClients.find(nSocketID);
	if (it != m_cClients.end())
	{
		return it->second.cAddress.ToString(false);
	}

	static String strIP = "";
	return strIP;
}


//********************************************************************
//函数功能: 将网络数据记录日志
//第一参数: 
//返回说明: 
//备注说明: 
//********************************************************************
void CNetClient::LogStatistics(void)
{
	MAP_CLIENTS::iterator it = m_cClients.begin();
	while (it != m_cClients.end())
	{
		RakPeerInterface* pClient = it->second.pClient;
		RakNetStatistics* pRss = pClient->GetStatistics(pClient->GetSystemAddressFromIndex(0));
		if (pRss == NULL)
		{
			continue;
		}

		StatisticsToString(pRss, g_szInfo, 1);
		g_szInfo[sizeof(g_szInfo) - 1] = '\0';

		LOGFMTI("Client RakNet IP:%s Stat:\r\n%s", it->second.cAddress.ToString(), g_szInfo);
	}

}

//********************************************************************
//函数功能: 当有服务端断开连接时的回调消息编号
//第一参数: 
//返回说明: 
//备注说明: 
//********************************************************************
void CNetClient::SetCallbackProtocol(uint32 nCallbackProtocol)
{
	m_nCallbackProtocol = nCallbackProtocol;
}