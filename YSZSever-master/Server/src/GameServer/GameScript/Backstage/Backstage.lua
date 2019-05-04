print "Backstage.lua"


function HandlePayOrder(cPacket, nSocketID)
    local tParseData =
    {
		STRING,		-- 后台服务器IP
		STRING,		-- 订单
        UINT8,		-- 充值渠道ID
		UINT32,		-- 帐号ID
		UINT8,		-- 商品ID
		UINT32,		-- 充值RMB
		STRING,		-- 充值IP
		STRING,		-- 充值时间
    }
    local tData = c_ParserPacket(tParseData, cPacket)
	local strServerIP = tData[1]
	local strOrder = tData[2]
	local nPlatformID = tData[3]
    local nAccountID = tData[4]
	local nCommodityID = tData[5]
	local nAmount = tData[6]
	local strIP = tData[7]
	local strPayTime = tData[8]
	
	print("PayOrder:", strServerIP, strOrder, nPlatformID, nAccountID, nCommodityID, nAmount, strIP, strPayTime)
	local nWhite = IsWhiteBackstage(strServerIP)
	if 0 == nWhite then
		LogError{"Backstage IP:%s, is not in whitelist", strServerIP}
		return
	end
	
	local tAccount = AccountMgr:GetAccountByID(nAccountID)
	if tAccount == nil then
		LogError{"Can't find Account, Order:%s, PlatformID:%d, AccountID:%d, CommodityID:%d, Amount:%d, IP:%s", strOrder, nPlatformID, nAccountID, nCommodityID, nAmount, strIP}
		return
	end
	
	local tConfig = StoreConfig[nCommodityID]
	if tConfig == nil then
		LogError{"Can't find StoreConfig, Order:%s, PlatformID:%d, AccountID:%d, CommodityID:%d, Amount:%d, IP:%s", strOrder, nPlatformID, nAccountID, nCommodityID, nAmount, strIP}
		return
	end
	
	local nInteger, nDecimal = math.modf(nAmount)
	if nDecimal ~= 0 then
		nAmount = nInteger
		if nAmount <= 0 then
			nAmount = 1
		end
	elseif nInteger <= 0 then
		nAmount = 1
	else
		if tConfig.Price ~= nAmount then
			LogError{"Price does not match, ConfigPrice:%d, Order:%s, PlatformID:%d, AccountID:%d, CommodityID:%d, Amount:%d, IP:%s", tConfig.Price, strOrder, nPlatformID, nAccountID, nCommodityID, nAmount, strIP}
			return
		end
	end	
	
	if AccountMgr.tPayOrder[strOrder] ~= nil then
		-- 非异常
		return
	end
	
	local tNode = 
	{
		nAccountID = nAccountID,
		nAmount = nAmount,
		strPayTime = strPayTime,
		nCommodityID = nCommodityID,
		nPayCannel = nPlatformID,
		strPayIP = strIP,
	}
	AccountMgr.tPayOrder[strOrder] = tNode	
	
	tAccount:AddRMB(tConfig.AddDiamond, OPERATE.CHARGE)
	tAccount:AddCharge(nAmount, OPERATE.CHARGE, tNode.nPayCannel)
	
	SQLQuery(string.format("INSERT INTO gd_payorder(gd_Order, gd_AccountID, gd_CommodityID, gd_Amount, gd_PayTime, gd_PayCannel, gd_PayIP) VALUE('%s', %d, %d, %d, '%s', %d, '%s');",
	strOrder, nAccountID, nCommodityID, nAmount, strPayTime, nPlatformID, strIP), "")

	local strURL = string.format(ORDER_RESULTS_STRING, strOrder)
	c_SendHttpRequest(strURL, "")
	
	if tAccount:IsOnline() then		
		local tSend = Message:New()
		net:SendToClient(tSend, PROTOCOL.SDK_PAY_ORDER_RESULT, tAccount.nSocketID)
	end
end


-- 后台设置功能
function HandleBackstageSetFunction(cPacket, nSocketID)
	local tParseData =
    {
		STRING,
		UINT8,
		UINT8,
		UINT8,
		UINT16,
		{
			UINT8,
		},
    }
    local tData = c_ParserPacket(tParseData, cPacket)
	local strServerIP = tData[1]
	local nOperate = tData[2]
	local nSetCPT = tData[3]
	local nSetVIP = tData[4]
	local tRoomList = tData[5]
	
	local nWhite = IsWhiteBackstage(strServerIP)
	if 0 == nWhite then
		LogError{"Backstage IP:%s, is not in whitelist", strServerIP}
		return
	end
	
	if nSetVIP > 0 then
		RoomMgr.nOpenVIP = nOperate		
		if nOperate == 0 then
			for k,v in pairs(RoomMgr.tRoomByID) do
				if v.tData.nRoomType == ROOM_TYPE.VIP then
					v:CloseRoom()
				end
			end
		end
	end
	
	if nSetCPT then	
		for k,v in pairs(RoomMgr.tRoomByID) do
			local tRoomData = v.tData
			if tRoomData.nRoomType == ROOM_TYPE.COMMON then
				tRoomData.nOpen = nOperate
				if nOperate == 0 then
					v:CloseRoom()
				end
			end
		end
	end
	
	for k,v in pairs(tRoomList) do
		local nRoomID = v[1]
		local tRoom = RoomMgr:GetRoom(nRoomID)
		if tRoom ~= nil then
			tRoom.tData.nOpen = nOperate
			if nOperate == 0 then
				tRoom:CloseRoom()
			end
		end
	end
end

-- 后台邮件
function HandleBackstageEmail(cPacket, nSocketID)
	local tParseData =
    {
		STRING,
		STRING,
		UINT16,
		{
			UINT8,
		},
		STRING,
		UINT32,
		UINT32,
    }
    local tData = c_ParserPacket(tParseData, cPacket)
	local strServerIP = tData[1]
	local tAccountList = Tokenizer(tData[2])
	local tVIPList = tData[3]
	local strContent = tData[4]
	local nAddGold = tData[5]
	local nAddRoomCard = tData[6]
	
	local nWhite = IsWhiteBackstage(strServerIP)
	if 0 == nWhite then
		LogError{"Backstage IP:%s, is not in whitelist", strServerIP}
		return
	end
	
	local nAccountLen = #tAccountList
	if nAccountLen == 1 and tAccountList[1] == 0 then
		-- 全服接收
		for k,v in pairs(AccountMgr.tAccountByID) do
			EmailMgr:AddMail(k, MAIL_TYPE.SYSTEM, "", strContent, 0, nAddGold, nAddRoomCard, true)
		end
		
	elseif nAccountLen >= 1 then
		-- 指定ID接收
		for k,v in ipairs(tAccountList) do
			EmailMgr:AddMail(v, MAIL_TYPE.SYSTEM, "", strContent, 0, nAddGold, nAddRoomCard, true)
		end
		
	else
		-- 指定VIP等级接收
		local tVIPMath = {}
		for k,v in ipairs(tVIPList) do
			tVIPMath[v] = true
		end
		
		for k,v in pairs(AccountMgr.tAccountByID) do
			if tVIPMath[v.nVIPLv] ~= nil then
				EmailMgr:AddMail(k, MAIL_TYPE.SYSTEM, "", strContent, 0, nAddGold, nAddRoomCard, true)
			end
		end
	end
end

-- 后台小喇叭
function HandleBackstageSpeaker(cPacket, nSocketID)
	local tParseData =
    {
		STRING,	
		UINT32,
		UINT32,
		UINT32,
		UINT8,
		STRING,
    }
    local tData = c_ParserPacket(tParseData, cPacket)
	local strServerIP = tData[1]
	local nStartTime = tData[2]
	local nDelTime = tData[3]
	local nIntervalTime = tData[4]
	local nPriority = tData[5]
	local strContent = tData[6]
	
	local nWhite = IsWhiteBackstage(strServerIP)
	if 0 == nWhite then
		LogError{"Backstage IP:%s, is not in whitelist", strServerIP}
		return
	end
	
	-- 立即播放
	if nStartTime <= 0 or nDelTime <= 0 or nIntervalTime <= 0 then
		SmallHornMgr:SendBroadcast(nil, nPriority, 255, strContent)
		return
	end
	
	-- 轮询播放判断
	local nNowTime = GetSystemTimeToSecond()
	if nStartTime < nNowTime then
		nStartTime = nNowTime
	end
	
	if nIntervalTime > 0 and nDelTime <= 0 then
		LogError{"后台小喇叭参数错误, 删除时间未设置; nStartTime:%d, nDelTime:%d, nIntervalTime:%d, nPriority:%d, strContent:'%s'",
		nStartTime, nDelTime, nIntervalTime, nPriority, strContent}
		return
	end
	
	if nDelTime < nStartTime then
		LogError{"后台小喇叭参数错误, 删除时间小于开始时间; nStartTime:%d, nDelTime:%d, nIntervalTime:%d, nPriority:%d, strContent:'%s'",
		nStartTime, nDelTime, nIntervalTime, nPriority, strContent}
		return
	end
	
	if (nDelTime - nStartTime) < nIntervalTime then	
		LogError{"后台小喇叭参数错误, 间隔时间太长; nStartTime:%d, nDelTime:%d, nIntervalTime:%d, nPriority:%d, strContent:'%s'",
		nStartTime, nDelTime, nIntervalTime, nPriority, strContent}
		return
	end
	
	local tNode =
	{
		nStartTime = nStartTime,
		nDelTime = nDelTime,
		nIntervalTime = nIntervalTime,
		nPriority = nPriority,
		strContent = strContent,
	}
	table.insert(SmallHornMgr.tLoop, tNode)	
	print("添加后台小喇叭", nStartTime, nDelTime, nIntervalTime, nPriority, strContent)
end

-- 设置已申请推广员状态
function HandleBackstageApply(cPacket, nSocketID)

	local tParseData =
    {
		STRING,		-- 后台IP
		UINT32,		-- 游戏帐号ID
    }
	
    local tData = c_ParserPacket(tParseData, cPacket)
    local strServerIP = tData[1]
    local nAccountID = tData[2]
	
	local nWhite = IsWhiteBackstage(strServerIP)
	if 0 == nWhite then
		LogError{"Backstage IP:%s, is not in whitelist", strServerIP}
		return
	end
	
	local tAccount = AccountMgr:GetAccountByID(nAccountID)
	if tAccount == nil then
		LogError{"Backstage Set Apply AccountID:%d, is not find", nAccountID}
		return
	end
	
	if tAccount.nSendEmail ~= 1 then
		LogError{"Backstage Set Apply Not AccountID:%d, SendEmail :%d", nAccountID, tAccount.nSendEmail}
		return
	end
	
	if tAccount.nSalesman ~= SALESMAN.NULL then
		LogError{"Backstage Set Apply AccountID:%d, Salesman:%d", nAccountID, tAccount.nSalesman}
		return
	end
	
	if tAccount.nTotalBetting < PublicConfig.TO_SALESMAN_BETTING then
		LogError{"Backstage Set Apply:%d, nSalesman:%d TotalBetting:%d, Condition is not satisfied", nAccountID, tAccount.nSalesman, tAccount.nTotalBetting}
		return
	end
	
	tAccount.nSalesman = SALESMAN.APPLY		
	tAccount.isChangeData = true
	if tAccount:IsOnline() then
		local tSend = Message:New()
		tSend:Push(UINT8, tAccount.nSalesman)
		net:SendToClient(tSend, PROTOCOL.UPDATE_SALESMAN, tAccount.nSocketID)
	end	
end


-- 设置为推广员
function HandleBackstageSetSalesman(cPacket, nSocketID)
	local tParseData =
    {
        STRING,		-- 后台IP
        UINT32,		-- 帐号ID
		STRING, 	-- 网站帐号
		UINT8,		-- 推广员类型
    }
    local tData = c_ParserPacket(tParseData, cPacket)
    local strServerIP = tData[1]
    local nAccountID = tData[2]
	local nWebAccount = tData[3]	
	local nSetSalesman = tData[4]	
	
	local nWhite = IsWhiteBackstage(strServerIP)
	if 0 == nWhite then
		LogError{"Backstage IP:%s, is not in whitelist; AccountID:%d, WebAcc:%d, SetSalesman:%d", strServerIP,nAccountID,nWebAccount,nSetSalesman}
		return
	end
	
	if nSetSalesman < SALESMAN.COMMON then
		LogError{"Backstage SetSalesman Illegal parameters; AccountID:%d, WebAcc:%d, SetSalesman:%d", nAccountID,nWebAccount,nSetSalesman}
		return
	end
	
	local tAccount = AccountMgr:GetAccountByID(nAccountID)
	if tAccount == nil then
		LogError{"Backstage Set AccountID:%d, is not find;  WebAcc:%d, SetSalesman:%d", nAccountID, nWebAccount, nSetSalesman}
		return
	end
	
	if nSetSalesman == SALESMAN.ADVANCED and tAccount.nBindCode > 0 then
		LogError{"Backstage Set AccountID:%d, SetSalesman:%d, BindCode:%d, Has Binded", nAccountID, nSetSalesman, tAccount.nBindCode}
		return
	end
	
	tAccount.nSalesman = nSetSalesman
	tAccount.isChangeData = true
	-- 发送通知成为推广员的邮件
	EmailMgr:AddMail(nAccountID, MAIL_TYPE.SALESMAN, "", nWebAccount, 0, 0, 0, true)	
	SQLQuery(string.format("UPDATE gd_account2 SET gd_SaleAccount='%s', gd_Salesman=%d, gd_SalesTime='%s' WHERE gd_AccountID=%d", nWebAccount, nSetSalesman, GetTimeToString(), nAccountID), "")
	
	if tAccount:IsOnline() then
		local tSend = Message:New()
		tSend:Push(UINT8, tAccount.nSalesman)
		net:SendToClient(tSend, PROTOCOL.UPDATE_SALESMAN, tAccount.nSocketID)
	end
end






-- 后台显示密码
function HandleBackstagePassword(cPacket, nSocketID)
	local tParseData =
    {
		STRING,		-- 后台IP
		UINT32,		-- 游戏帐号ID
		STRING,		-- 密码
    }
	
    local tData = c_ParserPacket(tParseData, cPacket)
    local strServerIP = tData[1]
    local nAccountID = tData[2]
	local strPassword = tData[3]
	
	local nWhite = IsWhiteBackstage(strServerIP)
	if 0 == nWhite then
		LogError{"Backstage IP:%s, is not in whitelist", strServerIP}
		return
	end
	
	local tAccount = AccountMgr:GetAccountByID(nAccountID)
	if tAccount == nil then
		LogError{"Backstage Set AccountID:%d, is not find", nAccountID}
		return
	end
	
	-- 发送邮件告知客户端显示密码
	EmailMgr:AddMail(nAccountID, MAIL_TYPE.PASSWORD, "", strPassword, 0, 0, 0, true)	
end


-- 后台冻结帐号
function HandleBackstageFrozen(cPacket, nSocketID)
	local tParseData =
    {
		STRING,		-- 后台IP
		UINT32,		-- 游戏帐号ID
		UINT32,		-- 冻结到期时间戳
    }
	
    local tData = c_ParserPacket(tParseData, cPacket)
    local strServerIP = tData[1]
    local nAccountID = tData[2]
	local nFrozentime = tData[3]
	
	local nWhite = IsWhiteBackstage(strServerIP)
	if 0 == nWhite then
		LogError{"Backstage IP:%s, is not in whitelist", strServerIP}
		return
	end
	
	local tAccount = AccountMgr:GetAccountByID(nAccountID)
	if tAccount == nil then
		LogError{"Backstage Set AccountID:%d, is not find", nAccountID}
		return
	end
	
	if nFrozentime > 0 and tAccount.nSocketID > 0 then
		c_ServerCloseSocket(tAccount.nSocketID)
	end
	
	tAccount.nFrozenTime = nFrozentime
	SQLQuery(string.format("UPDATE gd_account SET gd_FrozenTime=%d WHERE gd_AccountID=%d", nFrozentime, nAccountID), "")
end


-- 后台设置VIP等级
function HandleBackstageVIPLv(cPacket, nSocketID)
	local tParseData =
    {
		STRING,		-- 后台IP
		UINT32,		-- 游戏帐号ID
		UINT8,		-- VIP等级
    }
	
    local tData = c_ParserPacket(tParseData, cPacket)
    local strServerIP = tData[1]
    local nAccountID = tData[2]
	local nVIPLv = tData[3]
	
	local nWhite = IsWhiteBackstage(strServerIP)
	if 0 == nWhite then
		LogError{"Backstage IP:%s, is not in whitelist", strServerIP}
		return
	end
	
	local tAccount = AccountMgr:GetAccountByID(nAccountID)
	if tAccount == nil then
		LogError{"Backstage Set AccountID:%d, is not find", nAccountID}
		return
	end
	
	if nVIPLv < tAccount.nVIPLv then
		-- 非异常
		return
	end
	
	tAccount.nVIPLv = nVIPLv
	tAccount.isChangeData = true	
	if tAccount:IsOnline() then
		local tSend = Message:New()
		tSend:Push(UINT32, tAccount.nCharge)
		tSend:Push(UINT8, tAccount.nVIPLv)
		net:SendToClient(tSend, PROTOCOL.SET_CHARGE, tAccount.nSocketID)
	end
end