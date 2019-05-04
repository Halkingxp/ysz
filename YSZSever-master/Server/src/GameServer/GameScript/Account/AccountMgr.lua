print "AccountMgr.lua"


if AccountMgr == nil then
    AccountMgr = 
	{
		tAccountByAccount = {},
		tAccountByID = {},
		tAccountBySocketID = {},
		nNextAccountID = 0,
		nOnline = 0,
		nMaxOnline = 0,
		nNewCount = 0,
		tPayOrder = {},
		tDailyRebate = {},
	}
end


function OnLoadAccountID(cPacket, nSocketID)
    local tParseData = 
	{
		UINT16, 	-- 通用字段，个数		1
		{
			UINT32,		
		},
	}
    local tData = c_ParserPacket(tParseData, cPacket)[1]
    local nMaxAccountID = tData[1][1]
	
	if nMaxAccountID <= 0 then
		nMaxAccountID = MERGE_INTERVAL * SERVER_ID
	end
	AccountMgr.nNextAccountID = nMaxAccountID
end


function OnLoadAccount(cPacket)
    local tParseData = 
	{
		UINT16, 	-- 通用字段，个数		1
		{
			STRING,
			STRING,
			UINT32,		
			STRING,
			UINT32,	
			INT64,
			INT64,	
			UINT32,	
			UINT32,	
			UINT32,	
			UINT32,	
			STRING,	
			UINT32,	
			INT64,	
			UINT32,
			UINT32,
			UINT32,
		},
	}
	
	local tAccountByAccount = AccountMgr.tAccountByAccount
	local tAccountByID = AccountMgr.tAccountByID
	local tData = c_ParserPacket(tParseData, cPacket)[1]
	for k,v in pairs(tData) do
		local strAccount = v[1]
		local strBindAccount = v[2]
		local nAccountID = v[3]
		
		local tAccount = Account:New()		
		tAccount.nAccountID = nAccountID
		tAccount.strAccount = strAccount
		tAccount.strBindAccount = strBindAccount
		tAccount.strName = v[4]
		tAccount.nHeadID = v[5]
		tAccount.nRMB = v[6]
		tAccount.nGold = v[7]
		tAccount.nRoomCard = v[8]
		tAccount.nCharge = v[9]
		tAccount.nVIPLv = v[10]		
		tAccount.nFree = v[11]
		tAccount.nSocketID = 0
		tAccount.nRoomID = 0
		tAccount.nState = STATE.OFFLINE
		tAccount.nActiveTime = StringTimeToSecond(v[12])	--玩家创建帐号时间
		tAccount.nRegPlatformID = v[13]						--注册平台ID
		tAccount.nYesterdayGold = v[14]						--玩家的昨日财富，新建账号玩家此值为0
		tAccount.nFreeEmailNum = v[15]                      --玩家免费邮件发送次数（已用数）
		tAccount.nFrozenTime = v[16]						--帐号冻结到期时间
        tAccount.nChannelID = v[17]                         --渠道ID
        
        if string.find(strAccount, "Robot") ~= nil then
            tAccount.isRobot = true
        else
            tAccount.isRobot = false
        end
		
		--=================================== TODO 测试用代码
--		if tAccount.nRMB < 1000 then			
--			tAccount:AddRMB(1000, OPERATE.GM)
--		end
--		if tAccount.nGold < 10000000 then
--			tAccount:AddGold(10000000, OPERATE.GM)
--		end
		--=================================== TODO 测试用代码
		
		if strBindAccount ~= "" then
			tAccountByAccount[strBindAccount] = tAccount
		end
		
		tAccountByAccount[strAccount] = tAccount
		tAccountByID[nAccountID] = tAccount
	end
end

function OnLoadAccount2(cPacket)
    local tParseData = 
	{
		UINT16, 	-- 通用字段，个数		1
		{
			UINT32,
			UINT32,
			UINT32,
			INT64,
			INT64,
			UINT32,
			UINT32,
			INT64,
			UINT32,
			INT64,
			INT64,
			UINT32,
			UINT32,
			UINT32,
			UINT32,
			UINT32,
			UINT32,
			UINT32,
			INT64,
			INT64,
			INT64,
			INT64,
			INT64,
			INT64,
		},
	}

	local tData = c_ParserPacket(tParseData, cPacket)[1]
	for k,v in pairs(tData) do
		local nAccountID = v[1]		
		local tAccount = AccountMgr:GetAccountByID(nAccountID)	
		tAccount.nSalesman = v[2]
		tAccount.nSendEmail = v[3]	
		tAccount.nTotalBetting = v[4]
		tAccount.nTotalRebate = v[5]
		tAccount.nBindCode = v[6]	
		tAccount.nOneNumber = v[7]	
		tAccount.nOneBetting = v[8]	
		tAccount.nTwoNumber = v[9]		
		tAccount.nTwoBetting = v[10]	
		tAccount.nGiveGold = v[11]	
		tAccount.nChangeName = v[12]
		tAccount.nWin = v[13]
		tAccount.nLose = v[14]
		tAccount.nHe = v[15]		
		tAccount.nTotalDealer = v[16]
		tAccount.nDownline = v[17]
		tAccount.nTDNumber = v[18]
		tAccount.nTDBetting = v[19]
        tAccount.nEmailSendGold = v[20]
        tAccount.nEmailRecvGold = v[21]
        tAccount.nWeiXinCharge = v[22]
        tAccount.nAlipayCharge = v[23]
        tAccount.nOtherCharge = v[24]
	end
end

function OnLoadPayOrder(cPacket)
    local tParseData = 
	{
		UINT16, 	-- 通用字段，个数		1
		{
			STRING,		-- 订单号
			UINT32,		-- 帐号ID
			UINT32,		-- 商品ID
			UINT32,		-- 金额RMB
			STRING,		-- 支付时间
			UINT32,		-- 支付渠道
			STRING,		-- 支付IP
		},
	}

	tPayOrder = AccountMgr.tPayOrder
	local tData = c_ParserPacket(tParseData, cPacket)[1]
	for k,v in pairs(tData) do
		local tNode = 
		{
			nAccountID = v[2],
			nCommodityID = v[3],
			nAmount = v[4],
			strPayTime = v[5],
			nPayCannel = v[6],
			strPayIP = v[7],
		}
		
		local strOrder = v[1]
		if tPayOrder[strOrder] ~= nil then
			LogError{"Order:%s is repeat", strOrder}
		else
			tPayOrder[strOrder] = tNode
		end
	end
end

function AccountMgr:Init()
	SQLQuery("SELECT MAX(gd_AccountID) FROM gd_account;", "OnLoadAccountID")
	SQLQuery("SELECT gd_Account, gd_BindAccount, gd_AccountID, gd_Name, gd_HeadID, gd_RMB, gd_Gold, gd_RoomCard, gd_Charge, gd_VIPLv, gd_Free, gd_ActiveTime, gd_PlatformID, gd_YesterdayGold, gd_DaliyFreeEmailNum,gd_FrozenTime,gd_ChannelID FROM gd_account;", "OnLoadAccount")
	SQLQuery("SELECT gd_AccountID, gd_Salesman, gd_SendEmail, gd_TotalBetting, gd_TotalRebate, gd_BindCode, gd_OneNumber, gd_OneBetting, gd_TwoNumber, gd_TwoBetting, gd_GiveGold, gd_ChangeName, gd_Win, gd_Lose, gd_He, gd_TotalDealer,gd_Downline,gd_TDNumber,gd_TDBetting,gd_EmailSendGold,gd_EmailRecvGold,gd_WeiXinCharge,gd_AlipayCharge,gd_OtherCharge FROM gd_account2;", "OnLoadAccount2")
	SQLQuery("SELECT gd_Order, gd_AccountID, gd_CommodityID, gd_Amount, gd_PayTime, gd_PayCannel, gd_PayIP FROM gd_payorder;", "OnLoadPayOrder")	
end

function AccountMgr:GetAccountByID(nAccountID)
	local tAccount = AccountMgr.tAccountByID[nAccountID]
	return tAccount
end

function AccountMgr:GetAccountBySocketID(nSocketID)
	local tAccount = AccountMgr.tAccountBySocketID[nSocketID]
	return tAccount
end

function AccountMgr:GetAccountByAccount(strAccount)
	local tAccount = AccountMgr.tAccountByAccount[strAccount]
	return tAccount
end


 -- 广播消息, 给所有在线玩家
function AccountMgr:SendBroadcast(tSend, nProtocol)
	for k,v in pairs(self.tAccountByID) do
		if v:IsOnline() and v.isRobot == false then		
			net:SendToClient(tSend, nProtocol, v.nSocketID)
		end
	end
end

-- 创建帐号
function AccountMgr:CreateAccount(strAccount, strName, nPlatformID, nChannelID, strIP, nSocketID, isRobot)
	local nNowTime = GetSystemTimeToSecond()
	local tAccountByAccount = AccountMgr.tAccountByAccount
	local tAccountByID = AccountMgr.tAccountByID
	local tAccountBySocketID = AccountMgr.tAccountBySocketID
	
	AccountMgr.nNextAccountID = AccountMgr.nNextAccountID + 1
	local nNewAccountID = AccountMgr.nNextAccountID		
	
	
    if isRobot == false then
        
	    AccountMgr.nNewCount = AccountMgr.nNewCount + 1
        
		local isHave = HaveShieldWord(strName)
		local strNameLen = string.len(strName)
		if strNameLen <= 0 or strNameLen > 15 or isHave == true then
			strName = "赌圣" .. math.random(100000, 999999)
		end
    else
        -- 机器人帐号由服务器生成
        strAccount = "Robot" .. nNewAccountID;
    end
	
	local nHeadID = math.random(PublicConfig.ROLE_ICON_MAX)		
	local tNewAccount = Account:New()		
	tNewAccount.nAccountID = nNewAccountID
	tNewAccount.strAccount = strAccount
	tNewAccount.strName = strName
	tNewAccount.nRMB = 0
	tNewAccount.nGold = 0
	tNewAccount.nRoomCard = 0
	tNewAccount.nCharge = 0
	tNewAccount.nVIPLv = 0
	tNewAccount.nFree = 0
	tNewAccount.nFreeGold = 0
	tNewAccount.nSocketID = nSocketID
	tNewAccount.nRoomID = 0
	tNewAccount.nState = STATE.NORMAL
	tNewAccount.nActiveTime = nNowTime
	tNewAccount.nOnlineTime = nNowTime
	tNewAccount.nFreeEmailNum = 0
	tNewAccount.nHeadID = nHeadID
	tNewAccount.nRegPlatformID = nPlatformID
	tNewAccount.nChannelID = nChannelID
    tNewAccount.isRobot = isRobot
	
	-- 创建新帐号
	tAccountByAccount[strAccount] = tNewAccount
	tAccountByID[nNewAccountID] = tNewAccount
	tAccountBySocketID[nSocketID] = tNewAccount
	
    if isRobot == false then
        local strTime = GetTimeToString()
		SQLQuery(string.format("INSERT INTO gd_account (gd_Account, gd_BindAccount, gd_AccountID, gd_Name, gd_HeadID, gd_RMB, gd_Gold, gd_RoomCard, gd_Charge, gd_VIPLv, gd_Free, gd_ActiveTime, gd_ActiveIP, gd_PlatformID, gd_ChannelID) VALUES('%s', '%s', %d, '%s', %d, %d, %d, %d, %d, %d, %d, '%s', '%s', %d, %d)",
		strAccount, "", nNewAccountID, strName, nHeadID, 0, 0, 0, 0, 0, 0, strTime, strIP, nPlatformID, nChannelID), "")
		
		SQLQuery(string.format("INSERT INTO gd_account2 (gd_AccountID, gd_Salesman, gd_SendEmail, gd_TotalBetting, gd_TotalRebate, gd_BindCode, gd_OneNumber, gd_OneBetting, gd_TwoNumber, gd_TwoBetting, gd_GiveGold, gd_ChangeName, gd_Win, gd_Lose, gd_He, gd_SaleAccount, gd_TotalDealer,gd_Downline,gd_TDNumber,gd_TDBetting,gd_SalesTime,gd_EmailSendGold,gd_EmailRecvGold,gd_WeiXinCharge,gd_AlipayCharge,gd_OtherCharge) VALUES (%d, %d, %d, %d, %d, %d, %d, %d, %d, %d, %d, %d, %d, %d, %d, '%s', %d, %d, %d, %d, '%s', %d, %d, %d, %d, %d)", 
		nNewAccountID, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, "", 0, 0, 0, 0, "", 0, 0, 0, 0, 0), "")
	
        AccountMgr.nOnline = AccountMgr.nOnline + 1
		if AccountMgr.nOnline > AccountMgr.nMaxOnline then
			AccountMgr.nMaxOnline = AccountMgr.nOnline
		end
        
	    SendLoginLog(nNewAccountID)
        
	    -- TODO 活动给新用户发1500金币和5张张房卡
	    EmailMgr:AddMail(nNewAccountID, MAIL_TYPE.SYSTEM, "", "　　欢迎来到【金花赢三张】，为了感谢您的参与，特意赠送新人奖励。点击领取将获得邮件附件中的金币和房卡。\n　　祝您游戏愉快！", 0, 150000, 5, true)
        
        -- 申请成为推广员(自动审核通过)
		local strURL = string.format(APPLY_SALEMANS_STRING, nNewAccountID, SERVER_ID)
		c_SendHttpRequest(strURL, "")
    end
  
	-- 登录成功
    local tSend = Message:New()
	tNewAccount:FillAccountInfo(tSend)			
	net:SendToClient(tSend, PROTOCOL.LOGIN_REQUEST, nSocketID)	
    
    if isRobot == false then        
	    print("Registry Player:", GetTimeToString(), strAccount, nNewAccountID, tNewAccount.strName, strIP, nSocketID)
    else
	    print("Registry Robot:", GetTimeToString(), strAccount, nNewAccountID, tNewAccount.strName, strIP, nSocketID)
    end
    
    return tNewAccount
end

-- 帐号登录
function AccountMgr:LoginAccount(tAccount, strIP, nSocketID, isRobot)
    
	local nNowTime = GetSystemTimeToSecond()
	local tAccountByAccount = AccountMgr.tAccountByAccount
	local tAccountByID = AccountMgr.tAccountByID
	local tAccountBySocketID = AccountMgr.tAccountBySocketID
    
	-- 顶号处理
	if tAccount.nSocketID > 0 and tAccount.nSocketID ~= nSocketID then
		local tDisSend = Message:New()
		tDisSend:Push(UINT8, 1)
		c_SendMsgToClient(tDisSend, PROTOCOL.DISCONNECT, tAccount.nSocketID)
		
		-- 取消被顶号的Socket关联
		tAccountBySocketID[tAccount.nSocketID] = nil
        
		if tAccount.isRobot == false then
		    AccountMgr.nOnline = AccountMgr.nOnline - 1
		    SendExitLog(tAccount.nAccountID)
        end
	end
	
	-- 如果还在房间内, 则先退出房间
	for k,v in pairs(RoomMgr.tRoomByID) do
		if v.tPlayer[tAccount.nAccountID] ~= nil then
			v:RemovePlayer(tAccount)
			break
		end
	end
	
	-- 更新SocketID和状态
	tAccount.nSocketID = nSocketID
	tAccount.nState = STATE.NORMAL
	tAccount.nOnlineTime = nNowTime
	tAccountBySocketID[nSocketID] = tAccount
	
    if tAccount.isRobot == false then
        
		AccountMgr.nOnline = AccountMgr.nOnline + 1
		if AccountMgr.nOnline > AccountMgr.nMaxOnline then
			AccountMgr.nMaxOnline = AccountMgr.nOnline
		end
        
	    SendLoginLog(tAccount.nAccountID)
    end
	
	
	-- 登录成功
    local tSend = Message:New()
	tAccount:FillAccountInfo(tSend)		
	net:SendToClient(tSend, PROTOCOL.LOGIN_REQUEST, nSocketID)
    
    if isRobot == false then
	    print("Login Player:", GetTimeToString(), tAccount.strAccount, tAccount.nAccountID, tAccount.strName, strIP, nSocketID)
    else
	    print("Login Robot:", GetTimeToString(), tAccount.strAccount, tAccount.nAccountID, tAccount.strName, strIP, nSocketID)
    end
end

-- 创建机器人
function HandleCreateRobot(cPacket, nSocketID)
    local tParseData =
    {
        STRING,
        STRING,
        STRING,
        INT64,
        UINT16,
        STRING,
    }
    local tData = c_ParserPacket(tParseData, cPacket)
    local strBKAccount = tData[1]
    local strRobotAccount = tData[2]
    local strRobotName = tData[3]
    local nInitGold = tData[4]
    local nLifeCycle = tData[5]
    local strSign = tData[6]
 
    local tSend = Message:New()   
    local nRet = string.find(strRobotAccount, "Robot")
    if nRet == nil then
        tSend:Push(UINT8, 3)
        net:SendToClient(tSend, PROTOCOL.CREATE_ROBOT, nSocketID)
        return
    end
    
    if nInitGold > 10000000000 then
        tSend:Push(UINT8, 4)
        net:SendToClient(tSend, PROTOCOL.CREATE_ROBOT, nSocketID)
        return
    end
    
--    if nLifeCycle > 60 then
--        tSend:Push(UINT8, 5)
--        net:SendToClient(tSend, PROTOCOL.CREATE_ROBOT, nSocketID)
--        return
--    end
    
--    if strSign ~= strCheckSign then
--        tSend:Push(UINT8, 2)
--        net:SendToClient(tSend, PROTOCOL.CREATE_ROBOT, nSocketID)
--        return
--    end
    
    local strIP = c_GetClientIP(nSocketID)
    local tAccount = AccountMgr:GetAccountByAccount(strRobotAccount)	
	if tAccount == nil then
        -- 创建机器人 初始金币
		local tRobot = AccountMgr:CreateAccount(strRobotAccount, strRobotName, 0, 0, strIP, nSocketID, true)
		tRobot:AddGold(nInitGold, OPERATE.ROBOT_CREATE)
	else		
        -- 机器人登录
        AccountMgr:LoginAccount(tAccount, strIP, nSocketID, true)
	end	     
end

-- LoginServer请求登录
---------------------------------------------------------------------------------------------------------------------------------
function HandleLogin(cPacket, nSocketID)
    local tParseData =
    {
        STRING,			--Account
        UINT16,			--PlatformID
		STRING,			--Name
		UINT16,			--ChannelID
		STRING,			--ChannelID
    }
    local tData = c_ParserPacket(tParseData, cPacket)
    local strAccount 	 = tData[1]
	local nPlatformID	 = tData[2]
	local strName		 = tData[3]
	local nChannelID	 = tData[4]
	
	local strIP = c_GetClientIP(nSocketID)
	local tSend = Message:New()
	
	if PublicConfig.OPEN_WHITE_LIST == 1 then	
		local nWhite = IsWhiteLogin(strIP)
		if 0 == nWhite then
			-- 不用返回消息
			local strInfo = string.format("Account:%s, PlatformID:%d, Name:%s, ChannelID:%d, IP:%s 禁止登录.", strAccount, nPlatformID, strName, nChannelID, strIP)
			print(strInfo)
			return
		end
	end
	
	-- 在线人数是否超出上限
	if AccountMgr.nOnline >= ONLINE_MAX then
		tSend:Push(UINT8, 1)
		c_SendMsgToClient(tSend, PROTOCOL.LOGIN_REQUEST, nSocketID)
		return
	end
	
	if strAccount == "" then
		tSend:Push(UINT8, 3)
		c_SendMsgToClient(tSend, PROTOCOL.LOGIN_REQUEST, nSocketID)
		return
	end
	
	local tAccount = AccountMgr:GetAccountByAccount(strAccount)
	if tAccount == nil then
        -- 创建新新帐号
		AccountMgr:CreateAccount(strAccount, strName, nPlatformID, nChannelID, strIP, nSocketID, false)
	else
		-- 检测帐号是否被冻结	
		local nFrozenTime = tAccount:GetLimitTime()
		if nFrozenTime ~= nil then
			local strFrozenTime = GetTimeToString(nFrozenTime)
			tSend:Push(UINT8, 2)
			tSend:Push(STRING, strFrozenTime)			
			c_SendMsgToClient(tSend, PROTOCOL.LOGIN_REQUEST, nSocketID)
			return
		end
		
        -- 帐号登录
        AccountMgr:LoginAccount(tAccount, strIP, nSocketID, false)
	end	
end


-- 有客户端断开连接时的处理
function HandleCloseConnect(cPacket, nSocketID)
    local tParseData =
    {
        STRING,			--ClientIP
    }
    local tData = c_ParserPacket(tParseData, cPacket)
    local strClientIP = tData[1]
	
	local tAccount = AccountMgr.tAccountBySocketID[nSocketID]
	if tAccount == nil then
		return
	end
	
	if tAccount.nSocketID ~= nSocketID or tAccount.nState == STATE.OFFLINE then
		-- 已重新登录 或者 已处于离线状态, 故不处理后面逻辑
		AccountMgr.tAccountBySocketID[nSocketID] = nil
		LogError{"tAccount.nSocketID:%d, nSocketID:d, tAccount.nState:%d", tAccount.nSocketID, nSocketID, tAccount.nState}
		return
	end
	
	if tAccount.nRoomID > 0 then
		local tRoom = RoomMgr:GetRoom(tAccount.nRoomID)
		if tRoom ~= nil then
			tRoom:RemovePlayer(tAccount)
		end
	end
    
    if tAccount.isRobot == false then    
	    AccountMgr.nOnline = AccountMgr.nOnline - 1
    end
	
	AccountMgr.tAccountBySocketID[nSocketID] = nil
	tAccount.nState = STATE.OFFLINE
	tAccount.nSocketID = 0
	
	SendExitLog(tAccount.nAccountID)
	print("Logout:", GetTimeToString(), tAccount.strAccount, tAccount.nAccountID, tAccount.strName, strClientIP, nSocketID)
end


-- 回存完成提示
function HandleFinishSaveAll()
	print "实例数据回存完毕!!! 按下 'ctrl + c' 关闭程序"
end

-- 回存所有数据
function HandleSaveAll()
	c_Sleep(1000)
	
	local strNowTime = GetTimeToString()
	SendMoneyDailyLog("系统抽水", RoomMgr.nCommission, strNowTime)
	SendMoneyDailyLog("钻石充值", RoomMgr.nCharge, strNowTime)
	SendMoneyDailyLog("房卡消耗", RoomMgr.nRoomCard, strNowTime)
	RoomMgr.nCommission = 0
	RoomMgr.nCharge = 0
	RoomMgr.nRoomCard = 0
	
	-- 回存游戏全局数据
	RoomMgr:SaveGameData()
	
	-- 发送房间日报
	RoomMgr:SendRoomDaily(strNowTime)
	
	-- 回存邮件数据
	EmailMgr:SaveEmail()
	
	for k,v in pairs(AccountMgr.tAccountByID) do
		v:Save(true)
		c_Sleep(5)
	end

	SQLQuery("SELECT 1", "HandleFinishSaveAll")	
	print "实例数据回存中~~!!, 请等待完成提示!!!"
	
end

--客户端请求验证账号id有效性
function HandleCheckAccountID(cPacket, nSocketID)
	local tParseData =
    {
		UINT32,		-- 自己的帐号ID
		UINT32,     -- 待验证的账号
    }
	local tData = c_ParserPacket(tParseData, cPacket)
	local nAccountID = tData[1]
	local nCheckAccountID = tData[2]
	local tSend = Message:New()
	local tAccount = AccountMgr:GetAccountByID(nCheckAccountID)
	if tAccount == nil then
		--print(string.format('can not get tAccount id = %d', nAccountID))	
		tSend:Push(UINT8, 1)
	else
		tSend:Push(UINT8, 0)
		tSend:Push(UINT8, tAccount.nVIPLv)
        
        if IsInEmailBlackList(nAccountID) == 1 then
            -- 如果发送方在黑名单内, 不允许红包交易
            tSend:Push(UINT8, 0)
        else
            -- 如果发送方不在黑名单内, 根据配置返回
		    tSend:Push(UINT8, PublicConfig.IS_PLAYER_CAN_SEND_REWARD)
        end
	end
	net:SendToClient(tSend, PROTOCOL.CS_CHECK_ACCOUNTID, nSocketID)
end


function HandleModifyName(cPacket, nSocketID)
	local tParseData =
    {
		UINT32,		-- 帐号ID
		STRING,     -- 新的昵称
    }
	local tData = c_ParserPacket(tParseData, cPacket)
	local nAccountID = tData[1]
	local newName = tData[2]
	
	local tSend = Message:New()
	local tAccount = AccountMgr:GetAccountByID(nAccountID)
	if tAccount == nil then
		tSend:Push(UINT8, 1)
		net:SendToClient(tSend, PROTOCOL.CS_MODIFY_NAME, nSocketID)
		return
	end
	
	local nNameLen = string.len(newName)
	if nNameLen > 15 then
		tSend:Push(UINT8, 6)
		net:SendToClient(tSend, PROTOCOL.CS_MODIFY_NAME, nSocketID)
		return
	elseif nNameLen <= 0 then
		tSend:Push(UINT8, 5)
		net:SendToClient(tSend, PROTOCOL.CS_MODIFY_NAME, nSocketID)
		return
	end
	
	-- 下标从1开始
	local CHANGE_NAME_COST = PublicConfig.CHANGE_NAME_COST
	local nNeedCost = CHANGE_NAME_COST[tAccount.nChangeName + 1] or CHANGE_NAME_COST[#CHANGE_NAME_COST]
	if nNeedCost == nil then
		tSend:Push(UINT8, 2)
		net:SendToClient(tSend, PROTOCOL.CS_MODIFY_NAME, nSocketID)
		return
	end
	
	if tAccount.nGold < nNeedCost then
		tSend:Push(UINT8, 3)
		net:SendToClient(tSend, PROTOCOL.CS_MODIFY_NAME, nSocketID)
		return
	end
	
	local isHave = HaveShieldWord(newName)
	if isHave == true then
		tSend:Push(UINT8, 4)
		net:SendToClient(tSend, PROTOCOL.CS_MODIFY_NAME, nSocketID)
		return
	end
	
	
	tAccount:AddGold(-nNeedCost, OPERATE.CHANGE_NAME)
	tAccount.nChangeName = tAccount.nChangeName + 1
	tAccount.isChangeData = true
	tAccount.strName = newName
	
	--回存新名称
	SQLQuery(string.format("UPDATE gd_account SET gd_Name='%s' WHERE gd_Account='%s'", newName, tAccount.strAccount),"")
	
	tSend:Push(UINT8, 0)
	tSend:Push(UINT8, tAccount.nChangeName)
	tSend:Push(STRING, newName)
	net:SendToClient(tSend, PROTOCOL.CS_MODIFY_NAME, nSocketID)
end


-- 恢复游戏
function HandleRecoverGame(cPacket, nSocketID)
    local tParseData =
    {
        UINT32,	
    }
    local tData = c_ParserPacket(tParseData, cPacket)
    local nAccountID = tData[1]
		
	local tSend = Message:New()
	local tAccount = AccountMgr:GetAccountByID(nAccountID)
	if tAccount == nil then
		tSend:Push(UINT8, 1)
		net:SendToClient(tSend, PROTOCOL.RECOVER_GAME, nSocketID)
		return
	end	
	
	if tAccount.nState == STATE.OFFLINE or tAccount.nSocketID == 0 then
		tSend:Push(UINT8, 2)
		net:SendToClient(tSend, PROTOCOL.RECOVER_GAME, nSocketID)
		return
	end
	
	tSend:Push(UINT8, 0)
	net:SendToClient(tSend, PROTOCOL.RECOVER_GAME, nSocketID)
	
	EmailMgr:SendEmailToClient(nAccountID, nSocketID)
end

-- 请求帐号信息
function HandleRequestAccount(cPacket, nSocketID)
    local tParseData =
    {
        UINT32,	
    }
    local tData = c_ParserPacket(tParseData, cPacket)
    local nAccountID = tData[1]
		
	local tSend = Message:New()
	local tAccount = AccountMgr:GetAccountByID(nAccountID)
	if tAccount == nil then
		tSend:Push(UINT8, 1)
		net:SendToClient(tSend, PROTOCOL.REQUEST_ACCOUNT_DATA, nSocketID)
		return
	end
	
	tAccount:FillAccountInfo(tSend)		
	net:SendToClient(tSend, PROTOCOL.REQUEST_ACCOUNT_DATA, nSocketID)
end

-- 请求房间信息
function HandleRequestRoom(cPacket, nSocketID)
    local tParseData =
    {
        UINT32,	
    }
    local tData = c_ParserPacket(tParseData, cPacket)
    local nAccountID = tData[1]
		
	local tSend = Message:New()
	local tAccount = AccountMgr:GetAccountByID(nAccountID)
	if tAccount == nil then
		tSend:Push(UINT8, 1)
		net:SendToClient(tSend, PROTOCOL.REQUEST_ROOM_DATA, nSocketID)
		return
	end
	
	local tRoom = RoomMgr:GetRoom(tAccount.nRoomID)
	if tRoom == nil then
		tSend:Push(UINT8, 2)
		net:SendToClient(tSend, PROTOCOL.REQUEST_ROOM_DATA, nSocketID)
		return
	end
	
	local tRoomData = tRoom.tData
	if tRoomData.nRoomType == ROOM_TYPE.VIP and (tRoom.tEnterRecord == nil or tRoom.tEnterRecord[nAccountID] == nil) then
		tSend:Push(UINT8, 3)
		net:SendToClient(tSend, PROTOCOL.REQUEST_ROOM_DATA, nSocketID)
		return
	end
	
	if tRoomData.nRoomType == ROOM_TYPE.VIP and tRoomData.nGames >= tRoomData.nMaxGames then
		tSend:Push(UINT8, 4)
		net:SendToClient(tSend, PROTOCOL.REQUEST_ROOM_DATA, nSocketID)
		return
	end	
	
	tSend:Push(UINT8, 0)
	net:SendToClient(tSend, PROTOCOL.REQUEST_ROOM_DATA, nSocketID)
	
	local tRoomData = tRoom.tData	
	local tNumber = Message:New()
	tNumber:Push(UINT16, tRoomData.nCount)
	net:SendToClient(tNumber, PROTOCOL.SET_ROOM_PLAYER, nSocketID)
	
	tRoom:SendGameData(nAccountID, nSocketID)
	
	local tStat = Message:New()
	tRoom:FillStatisticsData(true, tStat)
	net:SendToClient(tStat, PROTOCOL.GET_ALL_STATISTICS, nSocketID)	
end


-- 绑定邀请码
function HandleBindCode(cPacket, nSocketID)
    local tParseData =
    {
        UINT32,
		UINT32,
    }
	
    local tData = c_ParserPacket(tParseData, cPacket)
    local nAccountID = tData[1]
    local nBindCode = tData[2]
	
	local tSend = Message:New()
	local tAccount = AccountMgr:GetAccountByID(nAccountID)
	if tAccount == nil then
		tSend:Push(UINT8, 1)
		net:SendToClient(tSend, PROTOCOL.BIND_CODE, nSocketID)
		return
	end
	
	local tOther = AccountMgr:GetAccountByID(nBindCode)
	if tOther == nil then
		tSend:Push(UINT8, 2)
		net:SendToClient(tSend, PROTOCOL.BIND_CODE, nSocketID)
		return
	end
	
	if tAccount.nSalesman == SALESMAN.ADVANCED then
		tSend:Push(UINT8, 7)
		net:SendToClient(tSend, PROTOCOL.BIND_CODE, nSocketID)
		return
	end
	
	if tOther.nSalesman < SALESMAN.COMMON then
		tSend:Push(UINT8, 3)
		net:SendToClient(tSend, PROTOCOL.BIND_CODE, nSocketID)
		return
	end
	
	
	if tAccount.nBindCode > 0 then
		tSend:Push(UINT8, 4)
		net:SendToClient(tSend, PROTOCOL.BIND_CODE, nSocketID)
		return
	end	
	
	if nBindCode == nAccountID then
		tSend:Push(UINT8, 5)
		net:SendToClient(tSend, PROTOCOL.BIND_CODE, nSocketID)
		return
	end
	
	if tOther.nAccountID == nAccountID then
		tSend:Push(UINT8, 6)
		net:SendToClient(tSend, PROTOCOL.BIND_CODE, nSocketID)
		return
	end
	
	local tHigher = nil
	if tOther.nBindCode > 0 then
		tHigher = AccountMgr:GetAccountByID(tOther.nBindCode)
		if tHigher.nAccountID == nAccountID then
			tSend:Push(UINT8, 6)
			net:SendToClient(tSend, PROTOCOL.BIND_CODE, nSocketID)
			return
		end
	end	
	
	tAccount.isChangeData = true
	tAccount.nBindCode = nBindCode
	tAccount:AddRoomCard(PublicConfig.BIND_CODE_GIFT_ROOM_CARD, OPERATE.BIND_CODE)
	
	tOther.isChangeData = true
	tOther.nOneNumber = tOther.nOneNumber + 1
	if tHigher ~= nil then
		tHigher.nTwoNumber = tHigher.nTwoNumber + 1
		tHigher.isChangeData = true
	end
	
	if tOther.nSalesman == SALESMAN.ADVANCED then
		tOther.nTDNumber = tOther.nTDNumber + 1
		tAccount.nDownline = 1
		tAccount.nTotalDealer = tOther.nAccountID
	elseif tOther.nTotalDealer > 0 then
		tAccount.nDownline = tOther.nDownline + 1
		tAccount.nTotalDealer = tOther.nTotalDealer
		local tAdvanced = AccountMgr:GetAccountByID(tOther.nTotalDealer)
		tAdvanced.nTDNumber = tAdvanced.nTDNumber + 1
	end
	
	tSend:Push(UINT8, 0)
	tSend:Push(UINT32, nBindCode)
	net:SendToClient(tSend, PROTOCOL.BIND_CODE, nSocketID)
end

-- 绑定帐号
function HandleBindAccount(cPacket, nSocketID)
    local tParseData =
    {
        UINT32,
		STRING,
		STRING,
    }
	
    local tData = c_ParserPacket(tParseData, cPacket)
    local nAccountID = tData[1]
    local strBindAccount = tData[2]
    local strName = tData[3]
	
	local tSend = Message:New()
	local tAccount = AccountMgr:GetAccountByID(nAccountID)
	if tAccount == nil then
		tSend:Push(UINT8, 1)
		net:SendToClient(tSend, PROTOCOL.BIND_ACCOUNT, nSocketID)
		return
	end
	
	if tAccount:IsBindAccount() > 0 then
		tSend:Push(UINT8, 2)
		net:SendToClient(tSend, PROTOCOL.BIND_ACCOUNT, nSocketID)
		return
	end
	
	local tAccountByAccount = AccountMgr.tAccountByAccount
	if tAccountByAccount[strBindAccount] ~= nil then
		tSend:Push(UINT8, 3)
		net:SendToClient(tSend, PROTOCOL.BIND_ACCOUNT, nSocketID)
		return
	end
	
	local isHave = HaveShieldWord(strName)
	if isHave == true then
		tSend:Push(UINT8, 4)
		net:SendToClient(tSend, PROTOCOL.BIND_ACCOUNT, nSocketID)
		return
	end

	tAccountByAccount[strBindAccount] = tAccount
	tAccount.strBindAccount = strBindAccount	
	tAccount.strName = strName
	SQLQuery(string.format("UPDATE gd_account SET gd_BindAccount='%s',gd_Name='%s' WHERE gd_Account='%s'", strBindAccount, strName, tAccount.strAccount), "")
	
	tSend:Push(UINT8, 0)
	tSend:Push(STRING, strBindAccount)
	net:SendToClient(tSend, PROTOCOL.BIND_ACCOUNT, nSocketID)
end


-- 修改头像ID
function HandleChangeHeadID(cPacket, nSocketID)
    local tParseData =
    {
        UINT32,
		UINT8,
    }
	
    local tData = c_ParserPacket(tParseData, cPacket)
    local nAccountID = tData[1]
    local nHeadID = tData[2]
	
	local tSend = Message:New()
	local tAccount = AccountMgr:GetAccountByID(nAccountID)
	if tAccount == nil then
		tSend:Push(UINT8, 1)
		net:SendToClient(tSend, PROTOCOL.CHANGE_HEAD_ID, nSocketID)
		return
	end
	
	if nHeadID <= 0 or nHeadID > PublicConfig.ROLE_ICON_MAX then
		tSend:Push(UINT8, 2)
		net:SendToClient(tSend, PROTOCOL.CHANGE_HEAD_ID, nSocketID)
		return
	end
	
	tAccount.nHeadID = nHeadID
	tAccount.isChangeData = true
	tSend:Push(UINT8, 0)
	tSend:Push(UINT8, nHeadID)
	net:SendToClient(tSend, PROTOCOL.CHANGE_HEAD_ID, nSocketID)
end

function HandleSettlementList(cPacket, nSocketID)
    local tParseData =
    {
        UINT32,
        UINT16,
        UINT16,        
    }
    local tData = c_ParserPacket(tParseData, cPacket)
    local nAccountID = tData[1]
    local nStartIndex = tData[2]
    local nCount = tData[3]
	
	local tAccount = AccountMgr:GetAccountByID(nAccountID)
	if tAccount == nil then
        local tSend = Message:New()
        tSend:Push(UINT16, 0)
        net:SendToClient(tSend, PROTOCOL.SETTLEMENT_LIST, nSocketID)
		return
	end
	
    tAccount:SendSettlement(nStartIndex, nCount)
end


function HandleGetRoomInfo(cPacket, nSocketID)
    local tParseData =
    {
        UINT32,
    }
    local tData = c_ParserPacket(tParseData, cPacket)
    local nRoomID = tData[1]
	local tRoom = RoomMgr:GetRoom(nRoomID)
	if tRoom == nil then
		return
	end
    
    local tRoomData = tRoom.tData
    local tSend = Message:New()
    tSend:Push(UINT32, nRoomID)
    tSend:Push(UINT8, tRoomData.nCount)
    tSend:Push(UINT8, tRoomData.nRobotCount)
    net:SendToClient(tSend, PROTOCOL.GET_ROOM_INFO, nSocketID)
end