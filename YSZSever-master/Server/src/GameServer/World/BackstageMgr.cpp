/*****************************************************************************
Copyright (C), 2008-2009, ***. Co., Ltd.
文 件 名:  BackstageMgr.cpp
说明信息:  
*****************************************************************************/
#include "BackstageMgr.h"
#include "Packet/Packet.h"
#include "log4z/log4z.h"
#include "DataStructure/MsgQueue.h"

#if defined WIN32
	#include <winsock.h>
#else
	#include <stdlib.h>  
	#include <errno.h>  
	#include <unistd.h>  
	#include <sys/socket.h>  
	#include <netinet/in.h>  
	#include <arpa/inet.h>  
#endif


CBackstageMgr::CBackstageMgr(void)
{
}

CBackstageMgr::~CBackstageMgr(void)
{
}

void CBackstageMgr::Run(void)
{

	int iRet = 0;
#if defined WIN32
	WSADATA wsa = {};
	iRet = WSAStartup(MAKEWORD(2, 2), &wsa);
	if (iRet != 0) 
	{
		LOGFMTF("初始化Socket失败: %d", iRet);
	}
#endif

#if defined WIN32
	SOCKET hServerSocket = socket(AF_INET, SOCK_STREAM, IPPROTO_TCP);
	if (hServerSocket == INVALID_SOCKET)
	{
		LOGFMTF("创建Socket失败");
	}
#else
	int hServerSocket = socket(AF_INET, SOCK_STREAM, 0);
	if (hServerSocket == -1)
	{
		LOGFMTF("创建Socket失败");
	}
#endif

	struct sockaddr_in cServerAddress;
	memset(&cServerAddress, 0, sizeof(sockaddr_in));
	cServerAddress.sin_family = AF_INET;
	cServerAddress.sin_port = htons(30000);
#if defined WIN32
	cServerAddress.sin_addr.S_un.S_addr = htonl(INADDR_ANY);
#else
	cServerAddress.sin_addr.s_addr = htonl(INADDR_ANY);
#endif 

	iRet = ::bind(hServerSocket, (sockaddr*)&cServerAddress, sizeof(cServerAddress));
	if (iRet == -1) 
	{
		LOGFMTF("套接字绑定到端口失败！端口: %d", 30000);
	}

	iRet = listen(hServerSocket, 10);
	if (iRet == -1)
	{
		LOGFMTF("侦听失败！iRet:%d", iRet);
	}

#if defined WIN32
	SOCKET hClientSocket = 0;
	int nClientAddrLen = 0;
#else
	int hClientSocket = 0;
	socklen_t nClientAddrLen = 0;
#endif 

	struct sockaddr_in cClientAddress;
	char szBuffer[65535] = {};
	CPacket cp;

	while (IsRun())
	{
		szBuffer[0] = '0';
		nClientAddrLen = sizeof(cClientAddress);
		memset(&cClientAddress, 0, sizeof(cClientAddress));
		if ((hClientSocket = accept(hServerSocket, (sockaddr*)&cClientAddress, &nClientAddrLen)) == -1)
		{
			continue;
		}

		//接收数据
		int iRecvBytes = recv(hClientSocket, szBuffer, sizeof(szBuffer), 0);
		if (iRecvBytes == -1) 
		{
			Sleep(500);
#if defined WIN32
			closesocket(hClientSocket);
			hClientSocket = 0;
#else
			close(hClientSocket);
			hClientSocket = 0;
#endif 	
			continue;
		}
				
		cp.Reset(szBuffer, iRecvBytes);
		sMsgQueueVec.PushPacket(cp);

		Sleep(500);

#if defined WIN32
		closesocket(hClientSocket);
		hClientSocket = 0;
#else
		close(hClientSocket);
		hClientSocket = 0;
#endif 		
	}
}
