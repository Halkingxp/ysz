print("UpdateMgr.lua")



-- 注册下次每日零点更新计时器
function SetNextZeroUpdate()
	local tNextDaily = GetTimeToTable()
	tNextDaily.hour = 23
	tNextDaily.min = 59
	tNextDaily.sec = 59
	
	local nNowTime = GetSystemTimeToSecond()
	local nNextDailyTime = GetTimeToSecond(tNextDaily)
	local iInterval = GetDateInterval(nNowTime, nNextDailyTime)
	if iInterval <= 0 then
		iInterval = iInterval + ONE_DAY_SECOND
	end
	
	-- 注册计时器
	local nTimerID = RegistryTimer(iInterval, 1, PROTOCOL.SS_NEXT_ZERO_UPDATE)
	if nTimerID == 0 then
		-- 第一次注册失败, 再次注册
		iInterval = ONE_DAY_SECOND
		RegistryTimer(iInterval, 1, PROTOCOL.SS_NEXT_ZERO_UPDATE)
	end
	LogInfo{"注册每日零点更新计时器, 间隔%d秒", iInterval}
end

-- 注册下次每日11点更新计时器
function SetNextElevenUpdate()	
	local tNextDaily = GetTimeToTable()
	tNextDaily.hour = DAILY_UPDATE_TIME
	tNextDaily.min = 0
	tNextDaily.sec = 0
	
	local nNowTime = GetSystemTimeToSecond()
	local nNextDailyTime = GetTimeToSecond(tNextDaily)
	local iInterval = GetDateInterval(nNowTime, nNextDailyTime)
	if iInterval <= 0 then
		iInterval = iInterval + ONE_DAY_SECOND
	end
	
	-- 注册计时器
	local nTimerID = RegistryTimer(iInterval, 1, PROTOCOL.SS_NEXT_FIVE_UPDATE)
	if nTimerID == 0 then
		-- 第一次注册失败, 再次注册
		iInterval = ONE_DAY_SECOND
		RegistryTimer(iInterval, 1, PROTOCOL.SS_NEXT_FIVE_UPDATE)
	end
	LogInfo{"注册每日十一点更新计时器, 间隔%d秒", iInterval}
end


-- 零点更新 由于触发此函数，并未到达明天这里提前增加明天的库
function HandleDailyZeroUpdate()
	
	-- 注册下次每日更新
	SetNextZeroUpdate()
	
	local strNowTime = GetTimeToString()
	SQLLog(string.format("UPDATE log_login SET log_LogoutTime='%s' WHERE log_LogoutTime IS NULL", strNowTime))
	
	local ONE_REBATE = PublicConfig.ONE_REBATE
	local TWO_REBATE = PublicConfig.TWO_REBATE
	local ADVANCED_REBATE = PublicConfig.ADVANCED_REBATE
	
	-- 更新免费次数和排行榜
	local nTotalGold = 0
	local nTotalRMB = 0
	local nTotalRoomCard = 0
	local tVIP = {[0]=0,[1]=0,[2]=0,[3]=0,[4]=0,[5]=0,[6]=0,[7]=0,[8]=0,[9]=0}
	local tDailyRebate = AccountMgr.tDailyRebate
	local nAddRebate = 0
	for k,v in pairs(AccountMgr.tAccountByID) do
		
        if v.isRobot == false then        
			tVIP[v.nVIPLv] = tVIP[v.nVIPLv] + 1
			nTotalGold = nTotalGold + v.nGold
			nTotalRMB = nTotalRMB + v.nRMB
			nTotalRoomCard = nTotalRoomCard + v.nRoomCard
			
			-- 记录每日返利金额, 并清零
			nAddRebate = 0
			if v.nSalesman == SALESMAN.ADVANCED then
				
				if tDailyRebate[k] == nil then
					tDailyRebate[k] = {nOne=0, nTwo=0, nTD=0}
				end
				nAddRebate = v.nTDBetting / 100 * ADVANCED_REBATE
				tDailyRebate[k].nTD = nAddRebate			
				LogInfo{"Add TD Rebate, AccountID:%d, AddGold:%d", k, (math.modf(nAddRebate))}
				
			elseif v.nBindCode > 0 then
				
				if tDailyRebate[v.nBindCode] == nil then
					tDailyRebate[v.nBindCode] = {nOne=0, nTwo=0, nTD=0}
				end
				
				nAddRebate = v.nTotalRebate / 100 * ONE_REBATE
				tDailyRebate[v.nBindCode].nOne = tDailyRebate[v.nBindCode].nOne + nAddRebate
				LogInfo{"Add One Rebate, AccountID:%d, OneUperID:%d, AddGold:%d", k, v.nBindCode, (math.modf(nAddRebate))}
				local tOner = AccountMgr:GetAccountByID(v.nBindCode)
				if tOner.nBindCode > 0 then
					
					if tDailyRebate[tOner.nBindCode] == nil then
						tDailyRebate[tOner.nBindCode] = {nOne=0, nTwo=0, nTD=0}
					end
					
					nAddRebate = v.nTotalRebate / 100 * TWO_REBATE
					tDailyRebate[tOner.nBindCode].nTwo = tDailyRebate[tOner.nBindCode].nTwo + nAddRebate
					LogInfo{"Add Two Rebate, AccountID:%d, OneUperID:%d, TwoUperID:%d, AddGold:%d", k, v.nBindCode, tOner.nBindCode, (math.modf(nAddRebate))}
				end
			end		        
            
			v.nTotalRebate = 0
			v.nFree = 0
			v.nFreeEmailNum = 0
			v.isChangeData = true
        end
	end
	
	-- 添加返利日志
	for k,v in pairs(tDailyRebate) do
		local tAccount = AccountMgr:GetAccountByID(k)
		local nTodayRebate = math.modf(v.nOne + v.nTwo + v.nTD)
		v.nTodayRebate = nTodayRebate
		
		local nTodayOneBetting = math.modf(v.nOne * 100 / ONE_REBATE)
		local nTodayTwoBetting = math.modf(v.nTwo * 100 / TWO_REBATE)
		local nTodayTDBetting =  math.modf(v.nTD * 100 / ADVANCED_REBATE)
		SQLLog(string.format("INSERT INTO log_rebate(log_AccountID, log_OneNumber, log_OneBetting, log_TwoNumber, log_TwoBetting, log_TDNumber, log_TDBetting, log_Rebate, log_Time) VALUES(%d,%d,%d,%d,%d,%d,%d,%d,'%s');",
		k, tAccount.nOneNumber, nTodayOneBetting, tAccount.nTwoNumber, nTodayTwoBetting, tAccount.nTDNumber, nTodayTDBetting, nTodayRebate, strNowTime))	
	end
	
	SendMoneyDailyLog("金币", nTotalGold, strNowTime)
	SendMoneyDailyLog("钻石", nTotalRMB, strNowTime)
	SendMoneyDailyLog("房卡", nTotalRoomCard, strNowTime)
	SendMoneyDailyLog("系统抽水", RoomMgr.nCommission, strNowTime)
	SendMoneyDailyLog("钻石充值", RoomMgr.nCharge, strNowTime)
	SendMoneyDailyLog("房卡消耗", RoomMgr.nRoomCard, strNowTime)	
	SendVipDailyLog(tVIP[0], tVIP[1], tVIP[2], tVIP[3], tVIP[4], tVIP[5], tVIP[6], tVIP[7], tVIP[8], tVIP[9], strNowTime)

	RoomMgr.nCommission = 0
	RoomMgr.nCharge = 0
	RoomMgr.nRoomCard = 0
	
	-- 发送房间日报
	RoomMgr:SendRoomDaily(strNowTime);
	
	-- 更新排行榜
	RankMgr:UpdateRank()
	-- 回存邮件数据
	EmailMgr:SaveEmail()
	
	-- 这里加3600是为了让时间到下一天
	--local nNowTime = GetSystemTimeToSecond() + 3600	
	--CreateDailyLog(nNowTime)	
end

-- 11点更新 函数内处理各种需要每日更新的逻辑
function HandleDailyElevenUpdate()
	
	-- 注册下次每日更新
	SetNextElevenUpdate()
	
	local SYSTEM_REBATE = PublicConfig.SYSTEM_REBATE
	for k,v in pairs(AccountMgr.tDailyRebate) do
		
		local tAccount = AccountMgr:GetAccountByID(k)
		tAccount.nGiveGold = tAccount.nGiveGold + v.nTodayRebate			
		tAccount.isChangeData = true	
        tAccount:UpdataDelSettlement()
		
		-- 发送返利邮件
		EmailMgr:AddMail(k, MAIL_TYPE.REBATE, "", tostring(v.nTodayRebate), 0, v.nTodayRebate, 0, true)
		
		LogInfo{"Send Rebate To Email, AccountID:%d, AddGold:%d", k, v.nTodayRebate}
	end
	
	-- 清空每日返利表
	AccountMgr.tDailyRebate = {}
	
--	local tSend = Message:New()
--	local strTime = GetTimeToString()
--	SQLLog(string.format("UPDATE log_login SET log_LogoutTime='%s' WHERE log_LogoutTime IS NULL", strTime))
	
	LogInfo{" GC -> Before Use Memory:%.02fM", collectgarbage("count") / 1024}
	collectgarbage()
	LogInfo{" GC -> After  Use Memory:%.02fM", collectgarbage("count") / 1024}
end

-- 每五分钟更新一次
if nTimeCount == nil then
	nTimeCount = 0
end 
function FiveMinuteUpdate()
	
	RoomMgr:SaveGameData()
	
	local nNowTime = GetSystemTimeToSecond()
	for k,v in pairs(AccountMgr.tAccountByID) do
		v:Save()
	end
	
	-- 每20分钟记录一次日志
	nTimeCount = nTimeCount + 1
	if nTimeCount >= 4 then
		nTimeCount = 0		
		SendOnlineLog(AccountMgr.nMaxOnline, AccountMgr.nOnline, AccountMgr.nNewCount, RoomMgr.iProfitGold)
		AccountMgr.nNewCount = 0
	end
end

-- 每小时更新一次
function OneHourUpdate()
	local nNowTime = GetSystemTimeToSecond()
	local tDelRoom = {}
	for k,v in pairs(RoomMgr.tRoomByID) do
		if v.tData.nRoomType == ROOM_TYPE.VIP and nNowTime >= v.tData.nDestroyTime then
			tDelRoom[k] = true
		end
	end
	
	for k,v in pairs(tDelRoom) do
		
		local tRoom = RoomMgr.tRoomByID[k]
		CancelTimer(tRoom.tData.nTimerID)
		
		local tSend = Message:New()	
		tRoom:SendBroadcast(tSend, PROTOCOL.GAMES_TO_END)
		
		RoomMgr.tRoomByID[k] = nil
	end
end

-- 每分钟更新一次
function OneMinuteUpdate()
	for k,v in pairs(RoomMgr.tRoomByID) do
		if v.tData.nTimerID > 0 then
			v:CheckProcessIsCorrect(true)
		end
	end
	
	SmallHornMgr:Update()
end

--  创建道具日志表
function CreateDailyLog(nNowTime)
--[[	
	local strTime = GetTimeToString()
	local dateDay = GetTimeToYearDay(nNowTime)
	SQLLog(string.format("CREATE TABLE IF NOT EXISTS `log_item_%s` (\
	`log_ID` int(11) unsigned NOT NULL AUTO_INCREMENT COMMENT '序号',\
	`log_HeroID` int(11) unsigned NOT NULL DEFAULT '0' COMMENT 'HeroID',\
	`log_ItemID` int(11) unsigned NOT NULL DEFAULT '0' COMMENT '道具模版ID',\
	`log_ChangeCount` int(11) NOT NULL DEFAULT '0' COMMENT '改变数量',\
	`log_Count` int(11) unsigned NOT NULL DEFAULT '0' COMMENT '改变后剩余数量',\
	`log_Operate` int(11) unsigned NOT NULL DEFAULT '0' COMMENT '改变原因',\
	`log_Time` datetime NOT NULL DEFAULT '%s' COMMENT '改变时间',\
	PRIMARY KEY (`log_ID`)\
	) ENGINE=InnoDB AUTO_INCREMENT=1 DEFAULT CHARSET=utf8mb4 ROW_FORMAT=COMPACT;", dateDay, strTime))
	
	SQLLog(string.format("CREATE TABLE IF NOT EXISTS `log_equip_%s` (\
    `log_ID` int(11) unsigned NOT NULL AUTO_INCREMENT COMMENT '序号',\
    `log_HeroID` int(11) unsigned NOT NULL DEFAULT '0' COMMENT 'HeroID',\
    `log_Equip` text NOT NULL COMMENT '装备数据',\
    `log_Operate` int(11) unsigned NOT NULL DEFAULT '0' COMMENT '操作原因',\
    `log_Time` datetime NOT NULL DEFAULT '2016-01-01 00:00:00' COMMENT '时间',\
    PRIMARY KEY (`log_ID`)\
    ) ENGINE=InnoDB AUTO_INCREMENT=1 DEFAULT CHARSET=utf8mb4 ROW_FORMAT=COMPACT;", dateDay, strTime))
--]]
end