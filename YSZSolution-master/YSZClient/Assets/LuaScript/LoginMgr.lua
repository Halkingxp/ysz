print('load LoginMgr.lua')

if LoginMgr == nil then
	LoginMgr = 
	{
		isChangeAccount = 0,			--是否切换账号标志，只有当玩家点击了切换账号按钮后，此值才为1，其他情况下都为0
		lastLoginType = 1,				--1游客登陆 152微信登陆
		wwwRequest = nil,				--http请求对象
		bindName = nil,					--绑定微信账号时，缓存的微信名称
		WechatIsRegister = 0,			-- 0 未注册 1 已注册
		WechatIsInstall = 0,			-- 0 未安装 1 已安装
		RunningPlatformID = 1, 		-- 1 windows 2 android 3 ios 4 macos
	}
end

function LoginMgr:Init()
	--读取本地数据
	self:LoadFromLocal()
	
end

function LoginMgr:IsAutoLogin()
	--[[if self.lastLoginType == PLATFORM_TYPE.PLATFORM_QQ or self.lastLoginType == PLATFORM_TYPE.PLATFORM_WEIXIN then
		if self.isChangeAccount == 0 then
			return true
		end
	end--]]
	return false
end

function LoginMgr:LoadFromLocal()
	local isChangeStr = CS.UnityEngine.PlayerPrefs.GetString("Game_Login_isChangeAccount","0")
	self.isChangeAccount =  tonumber(isChangeStr)
	
	local loginType = CS.UnityEngine.PlayerPrefs.GetString("Game_Login_lastLoginType","1")
	self.lastLoginType = tonumber(loginType)
	
	--print(string.format('isChangeAccount = %d, loginType = %d', self.isChangeAccount, self.lastLoginType))
end

function LoginMgr:SaveToLocal()
	CS.UnityEngine.PlayerPrefs.SetString("Game_Login_isChangeAccount", tostring(self.isChangeAccount))
	CS.UnityEngine.PlayerPrefs.SetString("Game_Login_lastLoginType", tostring(self.lastLoginType))
end

function LoginMgr:RecvLoginResult(platformID, paramTable)
	CS.LoadingDataUI.Hide()
	if platformID == PLATFORM_TYPE.PLATFORM_WEIXIN then
		errcode = paramTable['errcode']
		--print('lua 获取到的errcode = '..errcode)
		if errcode ~= 0 then
			print('微信授权登陆失败 errcode = ', errcode)
			CS.BubblePrompt.Show("授权登陆失败", "LoginMgr")
		else
			print("微信授权成功，即将向服务器发送登录信息")
			GameData.LoginInfo.Account = paramTable['openid']
			GameData.LoginInfo.PlatformType = PLATFORM_TYPE.PLATFORM_WEIXIN
			GameData.LoginInfo.AccountName = paramTable['nickname']
			--保存本次登录方式
			self.lastLoginType = PLATFORM_TYPE.PLATFORM_WEIXIN
			NetMsgHandler.TryConnectHubServer(true)
		end
	end
end

function LoginMgr:RecvSDKBindAccount(platformID, paramTable)
	if platformID == PLATFORM_TYPE.PLATFORM_WEIXIN then
		errcode = paramTable['errcode']
		--print('lua 获取到的errcode = '..errcode)
		
		if errcode == 0 then
			print("微信授权绑定账号成功，即将向服务器发送绑定信息")
			openid = paramTable['openid']
			name = paramTable['nickname']
			--print('lua 获取到的openid = '..openid)
			--print('lua 获取到的name = '..name)
			self.lastLoginType = PLATFORM_TYPE.PLATFORM_WEIXIN
			self.bindName = name;
			if NetMsgHandler.CanSendMessage() == true then
				NetMsgHandler.SendBindAccount(openid, name)
			else
				--保存消息到本地，等联通了服务器在发送
				NetMsgHandler.SaveBindAccountMsg(openid, name)
			end
			
		elseif errcode == 1 then
			print('该微信已绑定其他账号 errcode = ', errcode)
			CS.BubblePrompt.Show("该微信已绑定其他账号", "LoginMgr")
			CS.LoadingDataUI.Hide()
		else
			print('微信授权绑定账号失败 errcode = ', errcode)
			CS.BubblePrompt.Show("授权绑定失败", "LoginMgr")
			CS.LoadingDataUI.Hide()
		end
	end
end

function LoginMgr:RecvPayResult(platformID, paramTable)
	CS.LoadingDataUI.Hide()
	if platformID == PLATFORM_TYPE.PLATFORM_APP_STORE then
		errcode = paramTable['errcode']
		if errcode ~= 0 then
			CS.BubblePrompt.Show("支付失败", "LoginMgr")
		else
			--CS.BubblePrompt.Show("支付成功", "LoginMgr")
		end
	end
end

