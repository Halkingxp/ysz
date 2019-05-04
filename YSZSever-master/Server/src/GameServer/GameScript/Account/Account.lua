print "Account.lua"


if Account == nil then
    Account = {}
end

function Account:New()
	local tObj = 
    {     
		strAccount = "",
		strBindAccount = "",
		nRegPlatformID = 0,			--注册平台ID, 0表示游客
        nChannelID = 0,
		nAccountID = 0,
		strName = 0,
		nHeadID = 0,
		nCharge = 0,
		nRMB = 0,
		nGold = 0,
		nRoomCard = 0,
		nVIPLv = 0,
		nFree = 0,
		nFreeGold = 0,
		nSocketID = 0,
		nRoomID = 0,
		nState = 0,
		nNextSave = 0,
		nlastSendHornTime = 0,		--上一次发送小喇叭的时刻(单位：秒)不用回存数据库
		nLastVoiceTime = 0,			--上次发送语音时间戳
		nYesterdayGold = 0,			--玩家的昨日财富，新建账号玩家此值为0
		nFreeEmailNum = 0,          --玩家每天可发免费邮件数量
		nActiveTime = 0,			--激活帐号时间
		nOnlineTime = 0,
		nChangeName = 0,			--改名次数
		nFrozenTime = 0,			--帐号冻结时间
		isChangeData = true,		-- 是否有数据改动, 回存数据库	
        isRobot = false,	
		
		nSalesman = 0,				--普通0, 申请中1, 推广员2, 3总代理
		nTotalDealer = 0,			--所属总代理ID
		nDownline = 0,				--所属总代理下的第几层下线
		nTDNumber = 0,				--总代理下线人数
		nTDBetting = 0,				--总代理返利下注金额
		nSendEmail = 0,				--是否已发送邀请推广员邮件 1发送
		nTotalBetting = 0,			--累计下注金额
		nTotalRebate = 0,			--今日累计返利下注金额
		nBindCode = 0,				--绑定邀请码
		nOneNumber = 0,				--一级下线人数
		nOneBetting = 0,			--一级返利下注金额
		nTwoNumber = 0,				--二级下线人数
		nTwoBetting = 0,			--二级返利下注金额
		nGiveGold = 0,				--发放金币数量
		nWin = 0,					--胜次数
		nLose = 0,					--输次数
		nHe	= 0,					--和次数
        nEmailSendGold = 0,         --邮件发送总累积
        nEmailRecvGold = 0,         --邮件接收总累积
        nWeiXinCharge = 0,          --微信充值总累积
        nAlipayCharge = 0,          --支付宝充值总累积
        nOtherCharge = 0,           --其他渠道充值累积
        tSettlement = {},           --结算列表, 数组
    }
	Extends(tObj, self)
	return tObj
end


function Account:AddSettlement(nTime, nRoomID, tLongCard, tHuCard, nResults, tBetting, nPayAll, iChangeGold, nAfterGold)
    
    local tSettlement = self.tSettlement    
    local nLen = #tSettlement
    if nLen >= MAX_SAVE_SETTLEMENT_LEN then
        table.remove(tSettlement)
    end
    
    local tBettingPersonal = {}
	if tBetting ~= nil then
		if tBetting[BETTING.LONG] ~= nil then
			table.insert(tBettingPersonal, {{UINT8, BETTING.LONG}, {INT64, tBetting[BETTING.LONG]}})
		end			
		if tBetting[BETTING.HU] ~= nil then
			table.insert(tBettingPersonal, {{UINT8, BETTING.HU}, {INT64, tBetting[BETTING.HU]}})
		end			
		if tBetting[BETTING.LONG_JINHUA] ~= nil then				
			table.insert(tBettingPersonal, {{UINT8, BETTING.LONG_JINHUA}, {INT64, tBetting[BETTING.LONG_JINHUA]}})
		end			
		if tBetting[BETTING.HU_JINHUA] ~= nil then
			table.insert(tBettingPersonal, {{UINT8, BETTING.HU_JINHUA}, {INT64, tBetting[BETTING.HU_JINHUA]}})
		end			
		if tBetting[BETTING.BAOZI] ~= nil then					
			table.insert(tBettingPersonal, {{UINT8, BETTING.BAOZI}, {INT64, tBetting[BETTING.BAOZI]}})
		end
	end
    
    local tNode =
    {
        nTime = nTime,
        nRoomID = nRoomID,
        tLongCard = tLongCard,
        tHuCard = tHuCard,
        nResults = nResults,
        tBetting = tBettingPersonal,
        nPayAll = nPayAll,
        iChangeGold = iChangeGold,
        nAfterGold = nAfterGold,
        nBeforeGold = nAfterGold - iChangeGold,
    }    
    table.insert(tSettlement, 1, tNode)
end


function Account:UpdataDelSettlement()
    if self.isRobot == true then
        return
    end
    
    local tSettlement = self.tSettlement
    local nLen = #tSettlement 
    local nNowTime = GetSystemTimeToSecond()
    for i = nLen, 1, -1 do
        local tNode = tSettlement[i]
        if nNowTime >= tNode.nTime + MAX_SAVE_SETTLEMENT_TIME then
            table.remove(tSettlement)
        else
            return
        end
    end
end

function Account:SendSettlement(nStartIndex, nCount)
    if self.isRobot == true then
        return
    end
    
    local tSettlement = self.tSettlement
    local nLen = #tSettlement
    if nStartIndex < 0 then
        nStartIndex = 1
    end
    
    if nCount > 7 then
        nCount = 7
    end
    
    local nEndIndex = nStartIndex + nCount - 1
    if nEndIndex > nLen then
        nEndIndex = nLen
    end
    
    local tPush = {}
    for i = nStartIndex, nEndIndex do
        local tNode = tSettlement[i]
        if tNode == nil then
            break
        end
        
        table.insert(tPush, 
        {
            {UINT32, tNode.nTime},
            {UINT32, tNode.nRoomID},
			{UINT8, tNode.tLongCard[1][1]},
			{UINT8, tNode.tLongCard[1][2]},
			{UINT8, tNode.tLongCard[2][1]},
			{UINT8, tNode.tLongCard[2][2]},
			{UINT8, tNode.tLongCard[3][1]},
			{UINT8, tNode.tLongCard[3][2]},
			{UINT8, tNode.tHuCard[1][1]},
			{UINT8, tNode.tHuCard[1][2]},
			{UINT8, tNode.tHuCard[2][1]},
			{UINT8, tNode.tHuCard[2][2]},
			{UINT8, tNode.tHuCard[3][1]},
			{UINT8, tNode.tHuCard[3][2]},
			{UINT32, tNode.nResults},
			{TABLE, tNode.tBetting},
			{INT64, tNode.nBeforeGold},
			{INT64, tNode.iChangeGold},
			{INT64, tNode.nAfterGold},
			{UINT8, tNode.nPayAll},
        })
    end
    
    local tSend = Message:New()
    tSend:Push(UINT16, nLen)
    tSend:Push(TABLE, tPush)
    net:SendToClient(tSend, PROTOCOL.SETTLEMENT_LIST, self.nSocketID)
end


-- 填充帐号信息, 登录发送
function Account:FillAccountInfo(tSend)	
	
	local nAccountID = self.nAccountID
	local yesterdayRank = RankMgr:GetAllGoldRankIndex(nAccountID)
	local yesterdayGoldRankItem = RankMgr:GetAllGoldRankItemByID(nAccountID)
	local yesterdayGoldNum = 0
	if yesterdayGoldRankItem ~= nil then
		yesterdayGoldNum = yesterdayGoldRankItem.nYesterdayAllGold
	end
	
	tSend:Push(UINT8, 0)					-- 成功
	tSend:Push(UINT32, nAccountID)			-- 帐号ID
	tSend:Push(STRING, self.strName)		-- 名字
	tSend:Push(INT64, self.nRMB)			-- 金币
	tSend:Push(INT64, self.nGold)			-- 金币
	tSend:Push(UINT32, self.nRoomCard)		-- 房卡
	tSend:Push(INT8, self:GetFreeCount())	-- 剩余免费次数
	tSend:Push(UINT8, self.nVIPLv)			-- VIP等级
	tSend:Push(UINT32, self.nCharge)		-- 充值金额
	tSend:Push(UINT8, yesterdayRank)
	tSend:Push(INT64, yesterdayGoldNum)
	tSend:Push(UINT32, self.nRoomID)		-- 房间ID
	tSend:Push(UINT16, EmailMgr:GetPlayerUnReadEmailNum(nAccountID))
	tSend:Push(UINT8, self.nSalesman)				-- 是否是推广员
	tSend:Push(UINT8, self:IsBindAccount())			-- 是否绑定帐号
	tSend:Push(UINT32, self.nBindCode)				-- 绑定邀请码
	tSend:Push(UINT8, self.nChangeName)				-- 改变名字次数
	tSend:Push(UINT8, self.nHeadID)					-- 头像ID
	tSend:Push(UINT8, PublicConfig.APP_STORE_PAY)	-- 苹果支付开关, 主要用于苹果审核服务器, 其他服务器都关闭
	tSend:Push(UINT8, PublicConfig.APP_STORE_INVITATION_CODE)	-- 苹果绑定邀请码开关, 主要用于苹果审核服务器, 其他服务器都关闭
    tSend:Push(UINT8, self.nChannelID)
end

-- 获取玩家的限制登录时间
-- 返回说明: 如果玩家未被限制, 返回nil, 否则返回限制登录到期时间
function Account:GetLimitTime()
	local nNowTime = GetSystemTimeToSecond()
	if nNowTime < self.nFrozenTime then
		return self.nFrozenTime
	else
		self.nFrozenTime = 0
		return nil
	end
end

-- 获得免费剩余次数
function Account:GetFreeCount()

	local iCount = 0
	local nNowTime = GetSystemTimeToSecond()
	if nNowTime - self.nActiveTime > PublicConfig.NOVICE_TIME then
		local tVIPConfig = VipConfig[self.nVIPLv]
		if tVIPConfig == nil then
			iCount = 0
		else
			iCount = tVIPConfig.MaxFree - self.nFree
		end	
    else
        iCount = PublicConfig.NOVICE_TIME_FREE_COUNT - self.nFree	
	end
	return iCount
end


function Account:AddTotalBetting(iValue, nRoomType)
    
    if self.isRobot == true then
        return
    end
    
	if nRoomType == ROOM_TYPE.FREE then
		-- 试玩厅不统计下注和返利
		return
	end
	
	self.nTotalBetting = self.nTotalBetting + iValue
	self.isChangeData = true
	
	if self.nBindCode > 0 then
		-- 维护自己的累积下注
		self.nTotalRebate = self.nTotalRebate + iValue		
		
		-- 维护上级或上上级返利总金额
		local tOner = AccountMgr:GetAccountByID(self.nBindCode)
		tOner.nOneBetting = tOner.nOneBetting + iValue
		tOner.isChangeData = true
		
		if tOner.nBindCode > 0 then
			tTwoer = AccountMgr:GetAccountByID(tOner.nBindCode)
			tTwoer.nTwoBetting = tTwoer.nTwoBetting + iValue
			tTwoer.isChangeData = true
		end
	end
	
	if self.nTotalDealer > 0 then
		-- 维护所属总代的累积下注
		local tAdvanced = AccountMgr:GetAccountByID(self.nTotalDealer)
		tAdvanced.nTDBetting = tAdvanced.nTDBetting + iValue
		tAdvanced.isChangeData = true
	end
end


-- 已绑定返回1
function Account:IsBindAccount()
	
	if self.nRegPlatformID > 1 then
		return 1
	elseif self.strBindAccount ~= "" then
		return 1
	else
		return 0
	end
end

function Account:IsOnline()
	if self.nState == STATE.NORMAL then
		return true
	else
		return false
	end
end


function Account:Save(isIgnoreCondition)
    if self.isRobot == true then
        return
    end
    
	if self.isChangeData == false and isIgnoreCondition == nil then
		return
	end
	
	SQLQuery(string.format("UPDATE gd_account SET gd_HeadID=%d, gd_RMB=%d, gd_Gold=%d, gd_RoomCard=%d, gd_Charge=%d, gd_VIPLv=%d, gd_Free=%d, gd_YesterdayGold=%d, gd_DaliyFreeEmailNum=%d WHERE gd_Account='%s'", 
	self.nHeadID, self.nRMB, self.nGold, self.nRoomCard, self.nCharge, self.nVIPLv, self.nFree, self.nYesterdayGold, self.nFreeEmailNum, self.strAccount ), "")
	
	SQLQuery(string.format("UPDATE gd_account2 SET gd_Salesman=%d, gd_SendEmail=%d, gd_TotalBetting=%d, gd_TotalRebate=%d, gd_BindCode=%d, gd_OneNumber=%d, gd_OneBetting=%d, gd_TwoNumber=%d, gd_TwoBetting=%d, gd_GiveGold=%d, gd_ChangeName=%d, gd_Win=%d, gd_Lose=%d, gd_He=%d, gd_TotalDealer=%d,gd_Downline=%d,gd_TDNumber=%d,gd_TDBetting=%d,gd_EmailSendGold=%d,gd_EmailRecvGold=%d,gd_WeiXinCharge=%d,gd_AlipayCharge=%d,gd_OtherCharge=%d WHERE gd_AccountID=%d", 
	self.nSalesman, self.nSendEmail, self.nTotalBetting, self.nTotalRebate, self.nBindCode, self.nOneNumber, self.nOneBetting, self.nTwoNumber, self.nTwoBetting, self.nGiveGold, self.nChangeName, self.nWin, self.nLose, self.nHe, self.nTotalDealer, self.nDownline, self.nTDNumber, self.nTDBetting, self.nEmailSendGold, self.nEmailRecvGold, self.nWeiXinCharge, self.nAlipayCharge, self.nOtherCharge, self.nAccountID ), "")
	self.isChangeData = false
end


function Account:AddRMB(iValue, nOperate, nRoomID)	
	if iValue == 0 then
		return 0
	end
	
	if nRoomID == nil then
		nRoomID = 0
	end
	
	local nMoney = self.nRMB + iValue
	if nMoney < 0 or nMoney > PublicConfig.MAX_RMB then
		LogError{"Must be pre-judged enough consumption, RMB iValue:%d, Operate:%d, RoomID:%d", iValue, nOperate, nRoomID}
		return 0
	end
	
	self.nRMB = nMoney
	self.isChangeData = true
	
    if self.isRobot == false then
		local strTime = GetTimeToString()
		SQLLog(string.format("INSERT INTO log_rmb (log_AccountID, log_ChangeValue, log_Value, log_Operate, log_Time, log_RoomID) \
		VALUES(%d, %d, %d, %d, '%s', %d)", self.nAccountID, iValue, nMoney, nOperate, strTime, nRoomID))
    end
	
	local tSend = Message:New()
	tSend:Push(INT64, nMoney)
	tSend:Push(UINT8, nOperate)
	net:SendToClient(tSend, PROTOCOL.SET_RMB, self.nSocketID)
	return nMoney
end


function Account:AddGold(iValue, nOperate, nRoomID)
	if iValue == 0 then
		return 0
	end
	
	if nRoomID == nil then
		nRoomID = 0
	end
	
	local nMoney = self.nGold + iValue
	if nMoney < 0 or nMoney > PublicConfig.MAX_GOLD then
		LogError{"Must be pre-judged enough consumption, Gold iValue:%d, Operate:%d, RoomID:%d", iValue, nOperate, nRoomID}
		return 0
	end
	
	self.nGold = nMoney
	self.isChangeData = true
	
    if self.isRobot == false then
		local strTime = GetTimeToString()
		SQLLog(string.format("INSERT INTO log_gold (log_AccountID, log_ChangeValue, log_Value, log_Operate, log_Time, log_RoomID) \
		VALUES(%d, %d, %d, %d, '%s', %d)", self.nAccountID, iValue, nMoney, nOperate, strTime, nRoomID))
    end
	
	local tSend = Message:New()
	tSend:Push(INT64, nMoney)
	tSend:Push(UINT8, nOperate)
	net:SendToClient(tSend, PROTOCOL.SET_GOLD, self.nSocketID)
	return nMoney
end


function Account:AddRoomCard(iValue, nOperate, nRoomID)
	if iValue == 0 then
		return 0
	end
	
	if nRoomID == nil then
		nRoomID = 0
	end
	
	local nCard = self.nRoomCard + iValue
	if nCard < 0 or nCard > PublicConfig.MAX_ROOMCARD then
		LogError{"Must be pre-judged enough consumption, RoomCard iValue:%d, Operate:%d, RoomID:%d", iValue, nOperate, nRoomID}
		return 0
	end
	
	if iValue < 0 then
		RoomMgr.nRoomCard = RoomMgr.nRoomCard + (-iValue)
	end
	
	self.nRoomCard = nCard
	self.isChangeData = true
	
    if self.isRobot == false then
		local strTime = GetTimeToString()
		SQLLog(string.format("INSERT INTO log_roomcard (log_AccountID, log_ChangeValue, log_Value, log_Operate, log_Time, log_RoomID) \
		VALUES(%d, %d, %d, %d, '%s', %d)", self.nAccountID, iValue, nCard, nOperate, strTime, nRoomID))
	end
    
	local tSend = Message:New()
	tSend:Push(UINT32, nCard)
	net:SendToClient(tSend, PROTOCOL.SET_ROOM_CARD, self.nSocketID)
	return nCard
end


function Account:AddCharge(iValue, nOperate, nPayCannel)	
	if iValue == 0 then
		return 0
	end
	
	local nMoney = self.nCharge + iValue
	if nMoney < 0 then
		LogError{"Must be pre-judged enough consumption, Charge iValue:%d, Operate:%d, PayCannel:%d", iValue, nOperate, nPayCannel}
		return 0
	end
	
	if iValue > 0 then
		RoomMgr.nCharge = RoomMgr.nCharge + iValue
        
        if nPayCannel == 152 then
            self.nWeiXinCharge = self.nWeiXinCharge + iValue
        elseif nPayCannel == 153 then
            self.nAlipayCharge = self.nAlipayCharge + iValue
        else
            self.nOtherCharge = self.nOtherCharge + iValue
        end
	end
	
	self.nCharge = nMoney
	self.isChangeData = true
	
	if self.nVIPLv < VipConfig.nMaxVIPLv then
		for i = #VipConfig - 1, self.nVIPLv, -1 do
			local tConfig = VipConfig[i]
			if nMoney >= tConfig.ChargeRMB then
				self.nVIPLv = i + 1
				break
			end
		end
	end	
	
	local tSend = Message:New()
	tSend:Push(UINT32, nMoney)
	tSend:Push(UINT8, self.nVIPLv)
	net:SendToClient(tSend, PROTOCOL.SET_CHARGE, self.nSocketID)
	return nMoney
end


function Account:AddFreeGold(iValue, nOperate, nRoomID)
	if iValue == 0 then
		return 0
	end
	
	if nRoomID == nil then
		nRoomID = 0
	end
	
	local nMoney = self.nFreeGold + iValue
	if nMoney < 0 then
		LogError{"Must be pre-judged enough consumption, FreeGold iValue:%d, Operate:%d, RoomID:%d", iValue, nOperate, nRoomID}
		return 0
	end
	
	self.nFreeGold = nMoney
	
--	local strTime = GetTimeToString()
--	SQLLog(string.format("INSERT INTO log_free_gold (log_AccountID, log_ChangeValue, log_Value, log_Operate, log_Time, log_RoomID) \
--	VALUES(%d, %d, %d, %d, '%s', %d)", self.nAccountID, iValue, nMoney, nOperate, strTime, nRoomID))

	local tSend = Message:New()
	tSend:Push(INT64, nMoney)
	tSend:Push(UINT8, nOperate)
	tSend:Push(INT8, self:GetFreeCount())
	net:SendToClient(tSend, PROTOCOL.SET_FREEGOLD, self.nSocketID)
	return nMoney
end