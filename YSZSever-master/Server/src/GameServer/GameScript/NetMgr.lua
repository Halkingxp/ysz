print("NetMgr.lua")


-- 所有服务器的IP和Port都定义在此文件里面

DBIP		= "127.0.0.1"
DBPort		= 10000

HubIP		= "127.0.0.1"
HubPort		= 20000

GameIP		= "127.0.0.1"
GamePort	= 30000




if net == nil then
	net = 
	{
		isInit = false,
	}
end

-- 每个进程如果开启了NetServer服务的, 都需要注册以下消息和回调函数
-- MessageMgr:RegCallbackFun(PROTOCOL.SS_CLOSE_CONNECT, HandleCloseConnect)
-- 
-- 有客户端断开连接时的处理
--function HandleCloseConnect(cPacket, nSocketID)
--end

function net:Init(strServerName)
	
	if net.isInit == true then
		return
	end
	
	local nRet = 0
	local nPort = 0
	if strServerName == "GameServer" then
		
		DB_SERVER_ID = c_ClientConnect(DBIP, DBPort, "", "HandleReConnectDB")
		HUB_SERVER_ID = c_ClientConnect(HubIP, HubPort, "", "HandleReConnectHub")
		
		c_Sleep(1000)
		local tSend = Message:New()
		tSend:Push(UINT16, SERVER_ID)
		net:SendToHubServer(tSend, PROTOCOL.SS_MAPING)

		net.isInit = true
		
	else
		LogError{"Error ServerName:%s", strServerName}
	end
end

function net:SendToClient(tSend, nProtocol, nSocketID)
	c_SendMsgToClient(tSend, nProtocol, nSocketID)
end

function net:SendToServer(tSend, nProtocol, nSocketID)
	c_SendMsgToServer(tSend, nProtocol, nSocketID)
end

function net:SendToHubServer(tSend, nProtocol)
	c_SendMsgToServer(tSend, nProtocol, HUB_SERVER_ID)
end

function net:SendToDBServer(tSend, nProtocol)
	c_SendMsgToServer(tSend, nProtocol, DB_SERVER_ID)
end

function lua_GetDBServerSocketID()
	return DB_SERVER_ID
end




-- 重连HubServer
function HandleReConnectHub(cPacket, nSocketID)
	HUB_SERVER_ID = c_ClientConnect(HubIP, HubPort, "", "HandleReConnectHub")

	c_Sleep(1000)
	local tSend = Message:New()
	tSend:Push(UINT16, SERVER_ID)
	net:SendToHubServer(tSend, PROTOCOL.SS_MAPING)
end

-- 重连DBServer
function HandleReConnectDB(cPacket, nSocketID)
	DB_SERVER_ID = c_ClientConnect(DBIP, DBPort, "", "HandleReConnectDB")
end


