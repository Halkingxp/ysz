
if HubServerClient == nil then
	HubServerClient = 
	{
		netClientAgent = nil,	--网络代理
		buffMsg = nil,			--缓存的待发消息
		buffprotrocolID = 0,	--缓存的待发消息的id
		platformID = 1,			--当前操作对应的平台id
		isConnecting = false,	--当前是否正在连接网关中
	}
end

function HubServerClient:Init()
	self.netClientAgent = CS.Net.ConnectManager:Instance():FindNetworkClient("HubServer")
	if self.netClientAgent == nil then
		--self.netClientAgent = CS.Net.ConnectManager:Instance():CreateNetworkClient("HubServer");
		--self:RegProtocals()
	end
end

function HubServerClient:RegProtocals()
	if self.netClientAgent == nil then
		print('netClientAgent 为空 at HubServerClient:RegProtocals()')
		return
	end
	self.netClientAgent:RegisterParser(ProtrocolID.CS_SEND_CODE_TO_HUB, HubServerClient.HandleReceivedToken)
	self.netClientAgent:RegisterParser(ProtrocolID.CS_SEND_CREATE_ORDER_TO_HUB, HubServerClient.HandleCreateOrderResult)
end

function HubServerClient:SendMessageToHub(protrocolID, message, isShowLoadingUI)
	if self.netClientAgent == nil then
		print('HubServerClient was nil when you want send message['..protrocolID..'] to server, please check and fix this!')
		return
	end
	
	if self.isConnecting == true then
		print('Connnecting HubServer ...')
		return
	end
	
	if self.netClientAgent.IsConnectSuccess == true then
		self.netClientAgent:SendMessage(protrocolID, message.Message)
		if isShowLoadingUI then
			CS.LoadingDataUI.Show()
		end
	else
		--缓存下message
		self.bufferMsg = message
		self.buffprotrocolID = protrocolID
		--连接HUB服务器
		self:ConnectHub()
		self.isConnecting = true
	end
end

function HubServerClient:SendCheckCode(platformID, code)
	self.platformID = platformID--记录下当前操作对应的平台id
	local message = CS.Net.PushMessage()
	message:PushUInt16(platformID)
	message:PushString(code)
	self:SendMessageToHub(ProtrocolID.CS_SEND_CODE_TO_HUB, message, true);
end

function HubServerClient:SendCreateOrder(platformID, info)
	self.platformID = platformID--记录下当前操作对应的平台id
	local message = CS.Net.PushMessage()
	message:PushUInt16(platformID)
	message:PushString(info)
	self:SendMessageToHub(ProtrocolID.CS_SEND_CREATE_ORDER_TO_HUB, message, true);
end

function HubServerClient.HandleReceivedToken()
	
end

function HubServerClient.HandleCreateOrderResult()
	--如果成功，断开hub连接，
	local result = message:PopUInt32()
	if result == 0 then
		local info = message:PopString()
		print('hub返回的订单信息',info)
		HubServerClient:DisconnectHub()
		--拿着订单信息，去调用sdk的支付接口
		PlatformBridge:CallFunc(HubServerClient.platformID, PLATFORM_FUNCTION_ENUM.PLATFORM_FUNCTION_PAY, info)
	end
end

function HubServerClient:ConnectHub()
	print('开始链接hub')
	self.netClientAgent:Connect(GameConfig.HubServerIP,GameConfig.HubServerPort, HubServerClient.ConnectHubCallBack)
end

function HubServerClient:DisconnectHub()
	print('主动断开hub')
	self.netClientAgent:DisConnect()
end

function HubServerClient.ConnectHubCallBack(success)
	print('连接回调返回值为'..tostring(success))
	print(HubServerClient.netClientAgent.IsConnectSuccess)
	if success then
		-- 发送缓存的message
		if HubServerClient.buffprotrocolID ~= 0 then
			HubServerClient:SendMessageToHub(HubServerClient.buffprotrocolID, HubServerClient.buffMsg,false)
		end
	else
		-- 连接失败
		CS.LoadingDataUI.Hide();
		HubServerClient.buffprotrocolID = 0
		HubServerClient.buffMsg = nil
	end
	HubServerClient.isConnecting = false
end