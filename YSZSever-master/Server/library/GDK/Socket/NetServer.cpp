/*****************************************************************************
Copyright (C), 2015-2050, ***. Co., Ltd.
作       者:  Herry   
完成日期:  2016-11-24
说明信息:  网络通讯库, 服务端部分
*****************************************************************************/
#include "NetServer.h"
#include "log4z/log4z.h"
#include "DataStructure/MsgQueue.h"
#include "MessageIdentifiers.h"


CNetServer& CNetServer::GetInstance(void)
{
    static CNetServer object;
    return object;
}

CNetServer::CNetServer(void) : m_pServer(NULL), m_nNotifyCloseProtocol(0)
{
}

CNetServer::~CNetServer(void)
{
}

//********************************************************************
//函数功能: 加载服务器通信模块
//第一参数: 最大连接数
//第二参数: 监听端口
//第三参数: 连接密码
//第四参数: 有客户端断开连接时, 通知消息编号
//返回说明: 返回1, 重复初始化
//返回说明: 返回2, 初始化通信模块实例失败
//返回说明: 返回3, 绑定监听端口失败
//返回说明: 返回0, 成功
//备注说明: 
//********************************************************************
uint8 CNetServer::Startup(uint32 nMaxConnecttion, uint16 nPort, const String& strPassword)
{
	if (m_pServer)
	{
		REPORT("Server Repeat to Create communication module!");
		return 1;
	}

	m_pServer = RakPeerInterface::GetInstance();
	if (!m_pServer)
	{
		REPORT("Server Communication module is creation failed");
		return 2;
	}

	if (strPassword.length() > 0)
	{
		m_pServer->SetIncomingPassword(strPassword.c_str(), strPassword.length());
	}
	m_pServer->SetTimeoutTime(10000, UNASSIGNED_SYSTEM_ADDRESS);
	m_pServer->SetLimitIPConnectionFrequency(true);

	SocketDescriptor cSocketDescriptors[2];
	cSocketDescriptors[0].port = nPort;
	cSocketDescriptors[0].socketFamily = AF_INET; // Test out IPV4

#if defined WIN32
	cSocketDescriptors[1].port = nPort;
	cSocketDescriptors[1].socketFamily = AF_INET6; // Test out IPV6
	StartupResult nResult = m_pServer->Startup(nMaxConnecttion, cSocketDescriptors, 1);
#else
	cSocketDescriptors[1].port = nPort;
	cSocketDescriptors[1].socketFamily = AF_INET6; // Test out IPV6
	StartupResult nResult = m_pServer->Startup(nMaxConnecttion, cSocketDescriptors, 1);
#endif

	if (nResult != RakNet::RAKNET_STARTED)
	{
		sprintf(g_szInfo, "Server failed to Listen on Port:%d, Result:%d", nPort, nResult);
		REPORT(g_szInfo);
		return 3;
	}

	m_pServer->SetMaximumIncomingConnections(nMaxConnecttion);
	m_pServer->SetUnreliableTimeout(1000);

	for (uint32 i = 0; i < m_pServer->GetNumberOfAddresses(); i++)
	{
		SystemAddress sa = m_pServer->GetInternalID(UNASSIGNED_SYSTEM_ADDRESS, i);
		LOGFMTI("Server Listening Port: %s ", sa.ToString());
	}
	return 0;
}



//********************************************************************
//函数功能: 关闭服务端网络模块
//第一参数: 
//返回说明: 
//备注说明: 调用此函数后, 若需再次使用通信模块, 需先调用Startup函数
//********************************************************************
void CNetServer::Shutdown(void)
{
	if (m_pServer)
	{
		m_pServer->Shutdown(300);
		RakPeerInterface::DestroyInstance(m_pServer);
		m_pServer = NULL;
		LOGI("Server Communication Module Shutdown");
	} 
	else
	{
		REPORT("Shutdown UDP Service failed! because it is't Initialized!");
	}
}

//********************************************************************
//函数功能: 更新通信模块
//第一参数: 
//返回说明: 
//备注说明: 
//********************************************************************
void CNetServer::Update(void)
{
	if (m_pServer == nullptr)
	{
		return;
	}

	for (RakNet::Packet* pPacket = m_pServer->Receive(); pPacket != NULL; m_pServer->DeallocatePacket(pPacket), pPacket = m_pServer->Receive())
	{
		if (pPacket == nullptr)
		{
			break;
		}

		uint8 nRakNetID = (uint8)(pPacket->data[0]);
		switch (nRakNetID)
		{
		case ID_USER_PACKET_ENUM:
			_OnDispatch(pPacket);
			break;
		case ID_NEW_INCOMING_CONNECTION:
		case ID_CONNECTION_REQUEST_ACCEPTED:
			_OnNewConnection(pPacket);
			break;
		case ID_DISCONNECTION_NOTIFICATION:
		case ID_CONNECTION_LOST:
			_OnClosedConnection(pPacket);
			break;			
		case ID_CONNECTED_PING:
		case ID_UNCONNECTED_PING:			
			LOGFMTI("-----------> Ping From %s:", pPacket->systemAddress.ToString());
			break;
		}
	}
}

//********************************************************************
//函数功能: 新连接触发
//第一参数: 
//返回说明: 
//备注说明: 
//********************************************************************
void CNetServer::_OnNewConnection(RakNet::Packet* pPacket)
{
	const SystemAddress& cClientAddress = pPacket->systemAddress;
	uint32 nSocketID = SystemAddress::ToInteger(cClientAddress);

	MAP_ADDRESS::iterator it = m_cAddress.find(nSocketID);
	if (it == m_cAddress.end())
	{
		m_cAddress.insert(std::make_pair(nSocketID, cClientAddress));
		printf("Accept New Connections, Remote Address:%s, SocketID:%u\r\n", cClientAddress.ToString(), nSocketID);
	}
	else
	{
		sprintf(g_szInfo, "NewConnection SocketID Repeat, Remote Address:%s, SocketID:%u", cClientAddress.ToString(), nSocketID);
		REPORT(g_szInfo);
	}
}

//********************************************************************
//函数功能: 断开连接触发
//第一参数: 
//返回说明: 
//备注说明: 
//********************************************************************
void CNetServer::_OnClosedConnection(RakNet::Packet* pPacket)
{
	const SystemAddress& cClientAddress = pPacket->systemAddress;
	uint32 nSocketID = SystemAddress::ToInteger(cClientAddress);

	MAP_ADDRESS::iterator it = m_cAddress.find(nSocketID);
	if (it != m_cAddress.end())
	{
		String strClientIP = it->second.ToString(false);
		m_cAddress.erase(nSocketID);

		if (m_nNotifyCloseProtocol > 0)
		{
			CPacket cRet;
			cRet.SetSocketID(nSocketID);
			cRet.Reset(m_nNotifyCloseProtocol);
			cRet.WriteString(strClientIP);
			sMsgQueueVec.PushPacket(cRet);
		}

		printf("From Client Connection Closed, Remote Address:%s, SocketID:%u\r\n", cClientAddress.ToString(), nSocketID);
	}
}

//********************************************************************
//函数功能: 消息中转
//第一参数: 
//返回说明: 
//备注说明: 
//********************************************************************
void CNetServer::_OnDispatch(RakNet::Packet* pPacket)
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
uint32 CNetServer::SendToClient(CPacket& cPacket, uint32 nSocketID)
{
	MAP_ADDRESS::iterator it = m_cAddress.find(nSocketID);
	if (it != m_cAddress.end())
	{
		m_pServer->Send(cPacket.GetData(), cPacket.GetSize(), HIGH_PRIORITY, RELIABLE_ORDERED, 0, it->second, false);
	}
	return 0;
}

//********************************************************************
//函数功能: 发送消息到所有客户端
//第一参数: 消息包
//返回说明: 
//备注说明: 
//********************************************************************
void CNetServer::SendBroadcast(CPacket& cPacket)
{
	MAP_ADDRESS::iterator it = m_cAddress.begin();
	MAP_ADDRESS::iterator node = it;
	while (it != m_cAddress.end())
	{
		node = it;
		it++;

		m_pServer->Send(cPacket.GetData(), cPacket.GetSize(), HIGH_PRIORITY, RELIABLE_ORDERED, 0, node->second, false);
	}
}

//********************************************************************
//函数功能: 关闭指定SocketID的连接
//第一参数: 客户端SocketID
//返回说明: 
//备注说明: 
//********************************************************************
void CNetServer::CloseSocket(uint32 nSocketID)
{
	MAP_ADDRESS::iterator it = m_cAddress.find(nSocketID);
	if (it != m_cAddress.end())
	{
		ConnectionState nState = m_pServer->GetConnectionState(it->second);
		LOGFMTI("Will Close A Connection State:%d, SocketID:%u, Remote Address:%s", nState, nSocketID, it->second.ToString());

		m_pServer->CloseConnection(AddressOrGUID(it->second), true);
	}
}



//********************************************************************
//函数功能: 开启服务, 允许连接
//第一参数: 
//返回说明: 
//备注说明: 
//********************************************************************
void CNetServer::StartService(void)
{
	m_pServer->ClearBanList();
}

//********************************************************************
//函数功能: 关闭服务, 禁止所有连接
//第一参数: 
//返回说明: 
//备注说明: 
//********************************************************************
void CNetServer::StopService(void)
{
	m_pServer->AddToBanList("*.*.*.*");
}

//********************************************************************
//函数功能: 关闭所有SocketID的连接
//第一参数: 
//返回说明: 
//备注说明: 
//********************************************************************
void CNetServer::CloseAll(void)
{
	MAP_ADDRESS::iterator it = m_cAddress.begin();
	MAP_ADDRESS::iterator node = it;
	uint32 nSocketID = 0;
	while (it != m_cAddress.end())
	{
		node = it;
		it++;

		nSocketID = SystemAddress::ToInteger(node->second);
		ConnectionState nState = m_pServer->GetConnectionState(node->second);
		LOGFMTI("CloseAll -> Will Close A Connection State:%d, SocketID:%u, Remote Address:%s", nState, nSocketID, node->second.ToString());

		m_pServer->CloseConnection(AddressOrGUID(node->second), true);
	}
}

//********************************************************************
//函数功能: 获得指定SocketID的IP地址
//第一参数: 客户端SocketID
//返回说明: 
//备注说明: 
//********************************************************************
String CNetServer::GetClientAddress(uint32 nSocketID)
{
	MAP_ADDRESS::iterator it = m_cAddress.find(nSocketID);
	if (it != m_cAddress.end())
	{
		return it->second.ToString(false);
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
void CNetServer::LogStatistics(void)
{
	RakNetStatistics* pRss = m_pServer->GetStatistics(m_pServer->GetSystemAddressFromIndex(0));
	if (pRss == NULL)
	{
		return;
	}

	StatisticsToString(pRss, g_szInfo, 1);
	g_szInfo[sizeof(g_szInfo) - 1] = '\0';

	LOGFMTI("Server RakNet Stat:\r\n%s", g_szInfo);
}

//********************************************************************
//函数功能: 设置当客户端断开连接时的通知消息编号
//第一参数: 
//返回说明: 
//备注说明: 
//********************************************************************
void CNetServer::SetNotifyCloseProtocol(uint32 nNotifyCloseProtocol)
{
	m_nNotifyCloseProtocol = nNotifyCloseProtocol;
}