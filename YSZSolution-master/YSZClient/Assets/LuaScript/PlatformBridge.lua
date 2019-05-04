if PlatformBridge == nil then
	PlatformBridge = 
	{
		unityScript = nil,
		currentPlatformID = 0, --此处的值是PLATFORM_TYPE枚举
		currentfunctionEnum = 0,
	}
end

function PlatformBridge:Init()
	self.unityScript = CS.PlatformBridge.Init()
	--print('lua 平台桥接器初始化完成', self.unityScript)
end

function PlatformBridge:CallFunc(platformID, functionEnum, param)
	--print('lua调用平台接口 PlatformBridge.CallFunc', platformID, functionEnum, param)
	self.currentPlatformID = platformID
	self.currentfunctionEnum = functionEnum
	return self.unityScript:UnityCallPlatform(platformID, functionEnum, param)
end

function PlatformBridge.CallBackFunc(paramTable)
	--print('平台代码处理完毕通知回lua PlatformBridge.CallBackFunc paramTable = ', paramTable)
	platformID = paramTable["platformID"];
	functionEnum = paramTable["functionEnum"];
--[[	if platformID ~= PlatformBridge.currentPlatformID then
		print('平台代码处理完毕通知回lua时 platformID ~= PlatformBridge.currentPlatformID')
		return
	end
	
	if functionEnum ~= PlatformBridge.currentfunctionEnum then
		print('平台代码处理完毕通知回lua时 functionEnum ~= PlatformBridge.currentfunctionEnum')
		return
	end--]]
	
	if functionEnum == PLATFORM_FUNCTION_ENUM.PLATFORM_FUNCTION_REG then--注册
		-- 注册接口是同步的返回的，故这里不会进入此分支
	elseif functionEnum == PLATFORM_FUNCTION_ENUM.PLATFORM_FUNCTION_LOGIN then--登陆
		LoginMgr:RecvLoginResult(platformID, paramTable)
		
	elseif functionEnum == PLATFORM_FUNCTION_ENUM.PLATFORM_FUNCTION_SECOND_CHECK then--二次验证
		
	elseif functionEnum == PLATFORM_FUNCTION_ENUM.PLATFORM_FUNCTION_SHARE then--分享
		--提示分享成功
	elseif functionEnum == PLATFORM_FUNCTION_ENUM.PLATFORM_FUNCTION_PAY then--支付
		LoginMgr:RecvPayResult(platformID, paramTable)
		
	elseif functionEnum == PLATFORM_FUNCTION_ENUM.PLATFORM_FUNCTION_BIND_ACCOUNT then--账号绑定
		LoginMgr:RecvSDKBindAccount(platformID, paramTable)
		
	elseif functionEnum == PLATFORM_FUNCTION_ENUM.PLATFORM_FUNCTION_CHANNELCODE then
		-- OpnenInstall 反馈平台ID
		local channelCode = paramTable["channelCode"]
		print('OpenInstall SDK 反馈渠道ID ='..channelCode)
		if GameData.ConfirmChannelCode == false then
			GameData.ChannelCode = tonumber(channelCode)
		end
		CS.BubblePrompt.Show(sting.format("获得渠道ID:%s",GameData.ChannelCode),"UILogin")
	elseif functionEnum == PLATFORM_FUNCTION_ENUM.PLATFORM_FUNCTION_INVITE then
		-- OpnenInstall 反馈邀请房间ID 邀请者推荐ID
		GameData.OpenInstallRoomID = paramTable["roomID"]
		GameData.OpenInstallReferralsID = paramTable["roomID"]
		local InviteReferralsID = paramTable["referralsID"]
		print(string.format( "OpenInstall SDK 反馈回来的房间ID:%s 推荐者ID:%s", InviteRoomID, InviteReferralsID))
	else

	end
end

