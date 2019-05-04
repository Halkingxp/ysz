print "RoomMgr.lua"


if RoomMgr == nil then
	RoomMgr = 
	{
		tRoomByID = {},
		tDailyStat = {},
		nOpenVIP = 1,			-- 是否开启VIP房功能, 1开启, 0关闭
		iProfitGold = 0,		-- 系统当庄下盈利金币数(可以为负数)
		nCommission = 0,		-- 每日抽水总数(邮件+结算)
		nCharge = 0,			-- 每日钻石充值总数
		nRoomCard = 0,			-- 每日房卡消耗总数
	}
end

function OnLoadGameData(cPacket)
    local tParseData = 
	{
		UINT16, 	-- 通用字段，个数		1
		{
			INT64,	
			STRING,
		},
	}
    local tData = c_ParserPacket(tParseData, cPacket)[1]
    local iProfitGold = 0
	local strDailyRebate = ""
	if tData[1] ~= nil then
		iProfitGold = tData[1][1]
		strDailyRebate = tData[1][2]
	end
	RoomMgr.iProfitGold = iProfitGold
	if strDailyRebate ~= "" then
		AccountMgr.tDailyRebate = load(strDailyRebate)()
	end
end

function RoomMgr:Init()
	
	local tDailyStat = RoomMgr.tDailyStat
	for k,v in pairs(RoomConfig) do
		if v.Type < ROOM_TYPE.VIP then
			local tRoom = Room:New(v)			
			tRoom.tData.nRoomID = v.TemplateID
			tRoom.tData.nRoomType = v.Type
			tRoom.tData.nMaxGames = PublicConfig.ROOM_MAX_ROUND
			RoomMgr.tRoomByID[v.TemplateID] = tRoom
		end
		
		tDailyStat[k] =
		{
			nBoard = 0,
			nLongWin = 0,
			nHuWin = 0,
			nHe = 0,
			nLongJinHua = 0,
			nHuJinHua = 0,
			nBaoZi = 0,
			nSystemBanker = 0,
			iSystemProfitGold = 0,
			nSystemCommission = 0,
			nPlayerBanker = 0,
			iPlayerProfitGold = 0,
			nPlayerCommission = 0,
			[BETTING.LONG] 			= 0,
			[BETTING.HU] 			= 0,
			[BETTING.LONG_JINHUA] 	= 0,
			[BETTING.HU_JINHUA] 	= 0,
			[BETTING.BAOZI] 		= 0,
		}
	end
	
	SQLQuery("SELECT gd_ProfitGold, gd_DailyRebate FROM gd_game;", "OnLoadGameData")
end

function RoomMgr:SendRoomDaily(strNowTime)
	
	local tDailyStat = RoomMgr.tDailyStat
	for k,v in pairs(RoomMgr.tDailyStat) do
		SendRoomDailyLog(k, v.nBoard, v.nLongWin, v.nHuWin, v.nHe, v.nLongJinHua, v.nBaoZi, v.nHuJinHua, v[BETTING.LONG], v[BETTING.HU], v[BETTING.LONG_JINHUA], v[BETTING.BAOZI], v[BETTING.HU_JINHUA], v.nSystemBanker, v.iSystemProfitGold, v.nSystemCommission, v.nPlayerBanker, v.iPlayerProfitGold, v.nPlayerCommission, strNowTime)
		
		tDailyStat[k] =
		{
			nBoard = 0,
			nLongWin = 0,
			nHuWin = 0,
			nHe = 0,
			nLongJinHua = 0,
			nHuJinHua = 0,
			nBaoZi = 0,
			nSystemBanker = 0,
			iSystemProfitGold = 0,
			nSystemCommission = 0,
			nPlayerBanker = 0,
			iPlayerProfitGold = 0,
			nPlayerCommission = 0,
			[BETTING.LONG] 			= 0,
			[BETTING.HU] 			= 0,
			[BETTING.LONG_JINHUA] 	= 0,
			[BETTING.HU_JINHUA] 	= 0,
			[BETTING.BAOZI] 		= 0,
		}
	end
end


function RoomMgr:Test()
	
	local nGames = 64
	local tRoom = RoomMgr:GetRoom(1)
	local tRoomData = tRoom.tData
	local tResult = 
	{
		[STATISTICS_RESULT.HE]=0,
		[STATISTICS_RESULT.HU_WIN]=0,
		[STATISTICS_RESULT.LONG_WIN]=0,
	}
	local nLianWin = 0
	local nMaxLianWin = 0
	local nLastResult = 99
	local tType = 
	{
		tLong =
		{		
			[BRAND_TYPE.SANPAI]			= 0,		-- 散牌
			[BRAND_TYPE.DUIZI]			= 0,		-- 对子
			[BRAND_TYPE.SHUNZI]			= 0,		-- 顺子
			[BRAND_TYPE.JINHUA]			= 0,		-- 金花
			[BRAND_TYPE.SHUNJIN]		= 0,		-- 顺金
			[BRAND_TYPE.BAOZI]			= 0,		-- 豹子
		},
		tHu =
		{		
			[BRAND_TYPE.SANPAI]			= 0,		-- 散牌
			[BRAND_TYPE.DUIZI]			= 0,		-- 对子
			[BRAND_TYPE.SHUNZI]			= 0,		-- 顺子
			[BRAND_TYPE.JINHUA]			= 0,		-- 金花
			[BRAND_TYPE.SHUNJIN]		= 0,		-- 顺金
			[BRAND_TYPE.BAOZI]			= 0,		-- 豹子
		},
	}
	
	local tBetting = tRoomData.tBetting
	local tPersonal = tBetting.tPersonal
	local tTotal = tBetting.tTotal
	tPersonal[100001] = {}
	tPersonal[100001][4] = 100
	tPersonal[100001].nLastBettingTime = GetSystemTimeToSecond()
	tPersonal[100002] = {}
	tPersonal[100002][5] = 100
	tPersonal[100002].nLastBettingTime = GetSystemTimeToSecond()
	tTotal[4] = 100
	tTotal[5] = 100
	
--	local tLong = AccountMgr:GetAccountByID(100001)
--	local tHu = AccountMgr:GetAccountByID(100002)
--	tRoom.tPlayer[100001] = tLong
--	tRoom.tPlayer[100002] = tHu	
	
--	tRoomData.tLongRank = {{100001, 100}}
--	tRoomData.tHuRank = {{100002, 100}}
--	tRoomData.tBaoZiRank = {}
--	tRoomData.tJinHuaRank = {}
	
	local nHuResult, nLongType, nHuType = 0,0,0
	local nCurrResult = 0
	for i = 1, nGames do
		
--		tLong.nGold = tLong.nGold - 100
--		tHu.nGold = tHu.nGold - 100
		tRoom:FiringToConfigProbability()
		tRoomData.nGames = tRoomData.nGames + 1
--		tRoom:FiringRandom()
		nHuResult, nLongType, nHuType = tRoom:CalcResults()
--		print(i, "-------------------------------------------")
--		print("Long", BRAND_STRING[nLongType], tRoom:CardToString(tRoomData[IDENTITY.LONG]))
--		print("Hu", BRAND_STRING[nHuType], tRoom:CardToString(tRoomData[IDENTITY.HU]))

		nCurrResult = 0
		if nHuResult == RESULT.HE then
			tResult[STATISTICS_RESULT.HE] = tResult[STATISTICS_RESULT.HE] + 1
		elseif nHuResult == RESULT.SHENG then
			tResult[STATISTICS_RESULT.HU_WIN] = tResult[STATISTICS_RESULT.HU_WIN] + 1
			nCurrResult = STATISTICS_RESULT.HU_WIN
		elseif nHuResult == RESULT.FU then
			tResult[STATISTICS_RESULT.LONG_WIN] = tResult[STATISTICS_RESULT.LONG_WIN] + 1
			nCurrResult = STATISTICS_RESULT.LONG_WIN
		end		
		
		tType.tLong[nLongType] = tType.tLong[nLongType] + 1
		tType.tHu[nHuType] = tType.tHu[nHuType] + 1
		
		if nCurrResult == nLastResult and (STATISTICS_RESULT.LONG_WIN == nCurrResult or STATISTICS_RESULT.HU_WIN == nCurrResult) then
			nLianWin = nLianWin + 1
			
			if nLianWin > nMaxLianWin then
				nMaxLianWin = nLianWin
			end
		else
			nLianWin = 0
		end
		
		nLastResult = nCurrResult
	end
	
--	LogInfo{" Result ----------------"}
--	print("---------------- Result ----------------")
--	print("Long Gold:", tLong.nGold)
--	print("Hu Gold:", tHu.nGold)
	print("---------------- Result ----------------")
	for k,v in pairs(tResult) do
--		LogInfo{"%s := %d", STATISTICS_STRING[k], v}
		print(STATISTICS_STRING[k], v)
	end
	
--	LogInfo{"Long Card Type ----------------"}
	print("---------------- Long Card Type ----------------")
	for k,v in pairs(tType.tLong) do
--		LogInfo{"%s := %d", BRAND_STRING[k], v}
		print(BRAND_STRING[k], v)
	end
--	LogInfo{"Hu Card Type ----------------"}
	print("---------------- Hu Card Type ----------------")
	for k,v in pairs(tType.tHu) do
--		LogInfo{"%s := %d", BRAND_STRING[k], v}
		print(BRAND_STRING[k], v)
	end
	
--	LogInfo{" Max Lian Win ----------------"}
	print("---------------- Max Lian Win ----------------")
--	LogInfo{nMaxLianWin}
	print(nMaxLianWin)
end

function RoomMgr:GetRoom(nRoomID)
	local tRoom = RoomMgr.tRoomByID[nRoomID]
	return tRoom
end


function RoomMgr:SaveGameData()
	SQLQuery(string.format("REPLACE INTO gd_game(gd_ID, gd_ProfitGold, gd_DailyRebate) VALUES(1, %d, '%s')", 
	RoomMgr.iProfitGold, Serialize(AccountMgr.tDailyRebate)), "")
end

-- 比较赢钱玩家所赢金币数量
local function _CompReturnNode(tA, tB)
	if tA[2] > tB[2] then
		return true
	else
		return false
	end
end

-- 开始等待
local function _ProcessStartDengDai(tRoom, nSocketID)

	if tRoom == nil then
		LogError{"Room is nil RoomID:%d"}
		return
	end
	
	local tRoomData = tRoom.tData
	if tRoomData.nGames >= tRoomData.nMaxGames then
		
		-- VIP房间局数已用完, 发消息告知客户端退出
		if tRoomData.nRoomType == ROOM_TYPE.VIP then
			
			tRoom:SetRoomState(ROOM_STATE.DENGDAI_START)			
			CancelTimer(tRoomData.nTimerID)
			tRoomData.nTimerID = 0
			tRoomData.tBanker = nil
			tRoomData.tUpBanker = { nBankerGames = 0, isSetDownBanker = 0 }
			
			local tGamesToEnd = Message:New()
			tRoom:SendBroadcast(tGamesToEnd, PROTOCOL.GAMES_TO_END)
			return
			
		-- 重置统计数据
		else						
			local tRoomStatistics = tRoom.tStatistics
			tRoomStatistics.tResult = {}
			tRoomStatistics.nLongWin = 0
			tRoomStatistics.nHuWin = 0
			tRoomStatistics.nHe = 0
			tRoomStatistics.nLongJinHua = 0
			tRoomStatistics.nHuJinHua = 0
			tRoomStatistics.nBaoZi = 0
			tRoomData.nGames = 0
		end
	end
	
	local nNextTime = tRoom:SetRoomState(ROOM_STATE.DENGDAI)
	
	local tSend = Message:New()
	tRoom:SendBroadcast(tSend, PROTOCOL.START_DENGDAI)
	
	local tNextXiPai = Message:New()
	tNextXiPai:Push(UINT32, tRoomData.nRoomID)
	tRoomData.nTimerID = RegistryTimer(nNextTime, 1, PROTOCOL.START_XIPAI_STATE, tNextXiPai)
	
	tRoom:CheckUpBanker()
	tRoom:InitRoom(false)
	tRoom:CheckProcessIsCorrect()
end

-- 完成切牌
local function _ProcessOverQiePai(tRoom, nNumber, nSocketID)
	
	local tRoomData = tRoom.tData
	if tRoomData.nState ~= ROOM_STATE.QIEPAI then		
		LogError{"RoomID:%d, Error State:%d", tRoomData.nRoomID, tRoomData.nState}
		return
	end
	
	local tSend = Message:New()
	tSend:Push(UINT8, nNumber)
	tRoom:SendBroadcast(tSend, PROTOCOL.OVER_QIEPAI)
	
	local nNextTime = tRoom:SetRoomState(ROOM_STATE.OVER_QIEPAI)
	
	local tNextBetting = Message:New()
	tNextBetting:Push(UINT32, tRoomData.nRoomID)
	tRoomData.nTimerID = RegistryTimer(nNextTime, 1, PROTOCOL.START_BETTING_STATE, tNextBetting)
	tRoom:CheckProcessIsCorrect()
end


local function _ProcessStartBetting(tRoom, nSocketID)
	
	local tRoomData = tRoom.tData
	if tRoomData.nState ~= ROOM_STATE.OVER_QIEPAI and tRoomData.nState ~= ROOM_STATE.QIEPAI then
		LogError{"RoomID:%d, Error State:%d", tRoomData.nRoomID, tRoomData.nState}
		return
	end
	
	local nNextTime = tRoom:SetRoomState(ROOM_STATE.XIAZHU)

	local tSend = Message:New()
	tRoom:SendBroadcast(tSend, PROTOCOL.START_BETTING)

	local tNextFiring = Message:New()
	tNextFiring:Push(UINT32, tRoomData.nRoomID)
	tRoomData.nTimerID = RegistryTimer(nNextTime, 1, PROTOCOL.START_FIRING_STATE, tNextFiring)
	tRoom:CheckProcessIsCorrect()
end



local function _ProcessStartSettlement(tRoom, nSocketID)
	
	tRoom.nStep = 0
	local tRoomData = tRoom.tData	
	if tRoomData.nState ~= ROOM_STATE.OVER_LONG_CUO and tRoomData.nState ~= ROOM_STATE.OVER_HU_CUO then
		LogError{"RoomID:%d, Error State:%d", tRoomData.nRoomID, tRoomData.nState}
		return
	end
	
	local isJingMiRoom = tRoomData.nRoomType == ROOM_TYPE.COMMON
	local isFreeRoom = tRoomData.nRoomType == ROOM_TYPE.FREE
	local isPlayerBanker = tRoomData.tBanker ~= nil
	local nHuResult, nLongType, nHuType = tRoom:CalcResults()
	
	print("-------------------   RoomID", tRoomData.nRoomID, "Games", tRoomData.nGames, "---------------------")
	print(RESULT_STRING[nHuResult], tRoom:CardToString(IDENTITY.LONG), BRAND_STRING[nLongType], tRoom:CardToString(IDENTITY.HU), BRAND_STRING[nHuType])
	
	local fRoomExtractScale = 1
	if tRoomData.nRoomType == ROOM_TYPE.COMMON then
		fRoomExtractScale = (100 - PublicConfig.DEFAULT_EXTRACT_SCALE) / 100
	elseif tRoomData.nRoomType == ROOM_TYPE.VIP then
		local tOwner = AccountMgr:GetAccountByID(tRoomData.nRoomOwnerID)
		if tOwner == nil then
			fRoomExtractScale = (100 - PublicConfig.DEFAULT_EXTRACT_SCALE) / 100
		else
			local tVIPConfig = VipConfig[tOwner.nVIPLv]
			fRoomExtractScale = (100 - tVIPConfig.OpenExtract) / 100
		end
	end
	
	local MAX_BANKER_GOLD = 500000000000
	local nBankerGold = MAX_BANKER_GOLD
	if isPlayerBanker == true then
		if isFreeRoom == true then
			nBankerGold = tRoomData.tBanker.nFreeGold
		else
			nBankerGold = tRoomData.tBanker.nGold
		end
	end	
	
	local tProfitGold = {}
	local tTotal = tRoomData.tBetting.tTotal
    local tRobotBetting = tRoomData.tBetting.tRobot
	local tStatistics = tRoom.tStatistics
	local tDailyStat = RoomMgr.tDailyStat[tRoom.tConfig.TemplateID]
	local nStatisticsResults = 0	
	local nCommission = 0
    local nCorrectionRobot = 0
	tDailyStat.nBoard = tDailyStat.nBoard + 1
	if nHuResult == RESULT.HE then
		nStatisticsResults = nStatisticsResults | STATISTICS_RESULT.HE
		tStatistics.nHe = tStatistics.nHe + 1
		tDailyStat.nHe = tDailyStat.nHe + 1
	elseif nHuResult == RESULT.SHENG then
		nStatisticsResults = nStatisticsResults | STATISTICS_RESULT.HU_WIN		
		tStatistics.nHuWin = tStatistics.nHuWin + 1
		tDailyStat.nHuWin = tDailyStat.nHuWin + 1
		
        nCorrectionRobot = nCorrectionRobot - math.modf(tRobotBetting[BETTING.LONG] * fRoomExtractScale)
		local nBankerWin = math.modf(tTotal[BETTING.LONG] * fRoomExtractScale)
		nBankerGold = nBankerGold + nBankerWin
		nCommission = nCommission + math.modf((tTotal[BETTING.LONG] - tRobotBetting[BETTING.LONG]) * fRoomExtractScale)
	else
		nStatisticsResults = nStatisticsResults | STATISTICS_RESULT.LONG_WIN
		tStatistics.nLongWin = tStatistics.nLongWin + 1
		tDailyStat.nLongWin = tDailyStat.nLongWin + 1
		
        nCorrectionRobot = nCorrectionRobot - math.modf(tRobotBetting[BETTING.HU] * fRoomExtractScale)
		local nBankerWin = math.modf(tTotal[BETTING.HU] * fRoomExtractScale)
		nBankerGold = nBankerGold + nBankerWin
		nCommission = nCommission + math.modf((tTotal[BETTING.HU] - tRobotBetting[BETTING.HU]) * fRoomExtractScale)
	end
	
	if nLongType == BRAND_TYPE.BAOZI or nHuType == BRAND_TYPE.BAOZI then
		nStatisticsResults = nStatisticsResults | STATISTICS_RESULT.BAOZI
		tStatistics.nBaoZi = tStatistics.nBaoZi + 1
		tDailyStat.nBaoZi = tDailyStat.nBaoZi + 1        
	else        
        nCorrectionRobot = nCorrectionRobot - math.modf(tRobotBetting[BETTING.BAOZI] * fRoomExtractScale)
		local nBankerWin = math.modf(tTotal[BETTING.BAOZI] * fRoomExtractScale)
		nBankerGold = nBankerGold + nBankerWin
		nCommission = nCommission + math.modf((tTotal[BETTING.BAOZI] - tRobotBetting[BETTING.BAOZI]) * fRoomExtractScale)
	end
	if nLongType == BRAND_TYPE.JINHUA or nLongType == BRAND_TYPE.SHUNJIN then
		nStatisticsResults = nStatisticsResults | STATISTICS_RESULT.LONG_JINHUA
		tStatistics.nLongJinHua = tStatistics.nLongJinHua + 1
		tDailyStat.nLongJinHua = tDailyStat.nLongJinHua + 1
	else			
        nCorrectionRobot = nCorrectionRobot - math.modf(tRobotBetting[BETTING.LONG_JINHUA] * fRoomExtractScale)
		local nBankerWin = math.modf(tTotal[BETTING.LONG_JINHUA] * fRoomExtractScale)
		nBankerGold = nBankerGold + nBankerWin
		nCommission = nCommission + math.modf((tTotal[BETTING.LONG_JINHUA] - tRobotBetting[BETTING.LONG_JINHUA]) * fRoomExtractScale)
	end
	if nHuType == BRAND_TYPE.JINHUA or nHuType == BRAND_TYPE.SHUNJIN then
		nStatisticsResults = nStatisticsResults | STATISTICS_RESULT.HU_JINHUA
		tStatistics.nHuJinHua = tStatistics.nHuJinHua + 1
		tDailyStat.nHuJinHua = tDailyStat.nHuJinHua + 1
	else		
        nCorrectionRobot = nCorrectionRobot - math.modf(tRobotBetting[BETTING.HU_JINHUA] * fRoomExtractScale)
		local nBankerWin = math.modf(tTotal[BETTING.HU_JINHUA] * fRoomExtractScale)
		nBankerGold = nBankerGold + nBankerWin
		nCommission = nCommission + math.modf((tTotal[BETTING.HU_JINHUA] - tRobotBetting[BETTING.HU_JINHUA]) * fRoomExtractScale)
	end
	table.insert(tStatistics.tResult, nStatisticsResults)
	tRoom.nStep = 1
	
	-- 局数增加
	tRoomData.nGames = tRoomData.nGames + 1
	if isPlayerBanker == true then
		tRoomData.tUpBanker.nBankerGames = tRoomData.tUpBanker.nBankerGames + 1
	end
	
	local tWiner = {}
	local COMPENSATE = 0
	if nStatisticsResults & STATISTICS_RESULT.HE > 0 then
		for k,v in ipairs(tRoomData.tLongRank) do
			local nAccountID = v[1]
			local nBettingGold = v[2]
			local tAccount = AccountMgr:GetAccountByID(nAccountID)
			tAccount.nHe = tAccount.nHe + 1
			tAccount:AddTotalBetting(-nBettingGold, tRoomData.nRoomType)
			
			if tWiner[nAccountID] == nil then
				tWiner[nAccountID] = {}
			end
			if tWiner[nAccountID][STATISTICS_RESULT.LONG_WIN] == nil then
				tWiner[nAccountID][STATISTICS_RESULT.LONG_WIN] = {nBettingGold, 0, 0, 2}
			end
			
			tProfitGold[nAccountID] = {iProfitGold=0, nPayAll=2}
		end		
		for k,v in ipairs(tRoomData.tHuRank) do
			local nAccountID = v[1]
			local nBettingGold = v[2]			
			local tAccount = AccountMgr:GetAccountByID(nAccountID)
			tAccount.nHe = tAccount.nHe + 1
			tAccount:AddTotalBetting(-nBettingGold, tRoomData.nRoomType)
			
			if tWiner[nAccountID] == nil then
				tWiner[nAccountID] = {}
			end
			if tWiner[nAccountID][STATISTICS_RESULT.HU_WIN] == nil then
				tWiner[nAccountID][STATISTICS_RESULT.HU_WIN] = {nBettingGold, 0, 0, 2}
			end
			
			tProfitGold[nAccountID] = {iProfitGold=0, nPayAll=2}
		end
		tRoom.nStep = 2
	elseif nStatisticsResults & STATISTICS_RESULT.HU_WIN > 0 then		
		COMPENSATE = PublicConfig.COMPENSATE[BETTING.HU]
		for k,v in ipairs(tRoomData.tHuRank) do			
			local nAccountID = v[1]
			local nBettingGold = v[2]
			local nWinGold = nBettingGold * COMPENSATE
			local nPayAll = 2
			
			local tAccount = AccountMgr:GetAccountByID(nAccountID)
			tAccount.nWin = tAccount.nWin + 1
			
			if nBankerGold >= nWinGold then
				nBankerGold = nBankerGold - nWinGold
			else
				nWinGold = nBankerGold
				nBankerGold = 0
				nPayAll = 1
			end	
			
			local nAfterTax = math.modf(nWinGold * fRoomExtractScale)
			if tWiner[nAccountID] == nil then
				tWiner[nAccountID] = {}
			end
			if tWiner[nAccountID][STATISTICS_RESULT.HU_WIN] == nil then
				tWiner[nAccountID][STATISTICS_RESULT.HU_WIN] = {nBettingGold, nWinGold, nAfterTax, nPayAll}
			end
            
            if tAccount.isRobot == true then
                nCorrectionRobot = nCorrectionRobot + nWinGold
            else                
			    nCommission = nCommission + (nWinGold - nAfterTax)
            end
			
			tProfitGold[nAccountID] =  {iProfitGold=nAfterTax, nPayAll=nPayAll}
		end
		
		for k,v in ipairs(tRoomData.tLongRank) do	
			local nAccountID = v[1]		
			local nBettingGold = v[2]	
			local tAccount = AccountMgr:GetAccountByID(nAccountID)
			tAccount.nLose = tAccount.nLose + 1
			
			tProfitGold[nAccountID] = {iProfitGold=-nBettingGold, nPayAll=2}
		end
		tRoom.nStep = 3
	elseif nStatisticsResults & STATISTICS_RESULT.LONG_WIN > 0 then	
		COMPENSATE = PublicConfig.COMPENSATE[BETTING.LONG]	
		for k,v in ipairs(tRoomData.tLongRank) do			
			local nAccountID = v[1]
			local nBettingGold = v[2]
			local nWinGold = nBettingGold * COMPENSATE
			local nPayAll = 2
			
			local tAccount = AccountMgr:GetAccountByID(nAccountID)
			tAccount.nWin = tAccount.nWin + 1
			
			if nBankerGold >= nWinGold then
				nBankerGold = nBankerGold - nWinGold
			else
				nWinGold = nBankerGold
				nBankerGold = 0
				nPayAll = 1
			end
			
			local nAfterTax = math.modf(nWinGold * fRoomExtractScale)
			if tWiner[nAccountID] == nil then
				tWiner[nAccountID] = {}
			end
			if tWiner[nAccountID][STATISTICS_RESULT.LONG_WIN] == nil then
				tWiner[nAccountID][STATISTICS_RESULT.LONG_WIN] = {nBettingGold, nWinGold, nAfterTax, nPayAll}
			end
			
            if tAccount.isRobot == true then
                nCorrectionRobot = nCorrectionRobot + nWinGold
            else                
			    nCommission = nCommission + (nWinGold - nAfterTax)
            end
            
			tProfitGold[nAccountID] = {iProfitGold=nAfterTax, nPayAll=nPayAll}
		end
		
		for k,v in ipairs(tRoomData.tHuRank) do	
			local nAccountID = v[1]		
			local nBettingGold = v[2]		
			local tAccount = AccountMgr:GetAccountByID(nAccountID)
			tAccount.nLose = tAccount.nLose + 1
			
			tProfitGold[nAccountID] = {iProfitGold=-nBettingGold, nPayAll=2}
		end
		tRoom.nStep = 4
	end
	
	if nStatisticsResults & STATISTICS_RESULT.BAOZI > 0 then
		COMPENSATE = PublicConfig.COMPENSATE[BETTING.BAOZI]
		for k,v in ipairs(tRoomData.tBaoZiRank) do			
			local nAccountID = v[1]
			local nBettingGold = v[2]
			local nWinGold = nBettingGold * COMPENSATE
			local nPayAll = 2
			
			local tAccount = AccountMgr:GetAccountByID(nAccountID)
			if nBankerGold >= nWinGold then
				nBankerGold = nBankerGold - nWinGold
			else
				nWinGold = nBankerGold
				nBankerGold = 0
				nPayAll = 1
			end
			
			local nAfterTax = math.modf(nWinGold * fRoomExtractScale)
			if tWiner[nAccountID] == nil then
				tWiner[nAccountID] = {}
			end
			if tWiner[nAccountID][STATISTICS_RESULT.BAOZI] == nil then
				tWiner[nAccountID][STATISTICS_RESULT.BAOZI] = {nBettingGold, nWinGold, nAfterTax, nPayAll}
			end
			
			if tProfitGold[nAccountID] == nil then
				tProfitGold[nAccountID] = {iProfitGold=0, nPayAll=2}
			end
			tProfitGold[nAccountID].iProfitGold = tProfitGold[nAccountID].iProfitGold + nAfterTax
			if nPayAll == 1 then
				tProfitGold[nAccountID].nPayAll = nPayAll
			end
            
            if tAccount.isRobot == true then
                nCorrectionRobot = nCorrectionRobot + nWinGold
            else                
			    nCommission = nCommission + (nWinGold - nAfterTax)
            end
		end
	else
		for k,v in ipairs(tRoomData.tBaoZiRank) do			
			local nAccountID = v[1]
			local nBettingGold = v[2]
			
			if tProfitGold[nAccountID] == nil then
				tProfitGold[nAccountID] = {iProfitGold=0, nPayAll=2}
			end		
			tProfitGold[nAccountID].iProfitGold = tProfitGold[nAccountID].iProfitGold - nBettingGold
		end
	end
	tRoom.nStep = 5
	
--	if (nStatisticsResults & STATISTICS_RESULT.LONG_JINHUA > 0) or (nStatisticsResults & STATISTICS_RESULT.HU_JINHUA > 0) then	
		COMPENSATE = PublicConfig.COMPENSATE[BETTING.LONG_JINHUA]
		for k,v in ipairs(tRoomData.tJinHuaRank) do		
			
			local nAccountID = v[1]
			local nBettingGold = v[2]
			if tProfitGold[nAccountID] == nil then
				tProfitGold[nAccountID] = {iProfitGold=0, nPayAll=2}
			end
			
			local nResult = v[4]
			if nStatisticsResults & nResult > 0 then		
				local nWinGold = nBettingGold * COMPENSATE
				local nPayAll = 2				
				if nBankerGold >= nWinGold then
					nBankerGold = nBankerGold - nWinGold
				else
					nWinGold = nBankerGold
					nBankerGold = 0
					nPayAll = 1
				end					
                
			    local tAccount = AccountMgr:GetAccountByID(nAccountID)
				local nAfterTax = math.modf(nWinGold * fRoomExtractScale)
				if tWiner[nAccountID] == nil then
					tWiner[nAccountID] = {}
				end
				if tWiner[nAccountID][nResult] == nil then
					tWiner[nAccountID][nResult] = {nBettingGold, nWinGold, nAfterTax, nPayAll}
				end
				
				tProfitGold[nAccountID].iProfitGold = tProfitGold[nAccountID].iProfitGold + nAfterTax
				if nPayAll == 1 then
					tProfitGold[nAccountID].nPayAll = nPayAll
				end
                
				if tAccount.isRobot == true then
					nCorrectionRobot = nCorrectionRobot + nWinGold
                else                
			        nCommission = nCommission + (nWinGold - nAfterTax)
				end
			else				
				tProfitGold[nAccountID].iProfitGold = tProfitGold[nAccountID].iProfitGold - nBettingGold
			end			
		end
--	end
	tRoom.nStep = 6
	
	local tNotify = Message:New()
	tNotify:Push(UINT8, nStatisticsResults)
	tRoom:SendBroadcast(tNotify, PROTOCOL.START_SETTLEMENT)
	tRoom.nStep = 7
	
	local strNowTime = GetTimeToString()
    local nNowTime = GetSystemTimeToSecond()
	if isPlayerBanker == true then
		local iBankerReturn = 0		
        local tPlayerBanker = tRoomData.tBanker
		if isFreeRoom == true then
			iBankerReturn = nBankerGold - tPlayerBanker.nFreeGold
		else
			iBankerReturn = nBankerGold - tPlayerBanker.nGold
		end
        
        local nHaveGold = 0
		if isFreeRoom == true then
			tPlayerBanker:AddFreeGold(iBankerReturn, OPERATE.BANKER_SETTLEMENT, tRoomData.nRoomID)
            nHaveGold = tPlayerBanker.nFreeGold
		else
			tPlayerBanker:AddGold(iBankerReturn, OPERATE.BANKER_SETTLEMENT, tRoomData.nRoomID)
            nHaveGold = tPlayerBanker.nGold
		end
		
		tDailyStat.nPlayerBanker = tDailyStat.nPlayerBanker + 1
		tDailyStat.iPlayerProfitGold = tDailyStat.iPlayerProfitGold + iBankerReturn + nCorrectionRobot
		tDailyStat.nPlayerCommission = tDailyStat.nPlayerCommission + nCommission
		
	    local nBankerPayAll = 2
		if nHaveGold <= 0 then
			nBankerPayAll = 1
		end
        
        if tPlayerBanker.isRobot == false then
			SendSettlementLog(tPlayerBanker.nAccountID, tRoomData.nRoomID, 1, 0, 0, 0, 0, 0, RESULT_STRING[nHuResult], BRAND_STRING[nLongType], BRAND_STRING[nHuType], iBankerReturn, PAY_STRING[nBankerPayAll], strNowTime)
			
			if isFreeRoom == false then
				tPlayerBanker:AddSettlement(nNowTime, tRoomData.nRoomID, tRoomData[IDENTITY.LONG], tRoomData[IDENTITY.HU], nStatisticsResults, {}, nBankerPayAll, iBankerReturn, tPlayerBanker.nGold)
			end        
        end
	else
		
		local iBankerReturn = nBankerGold - MAX_BANKER_GOLD
		
		-- 计算并更新全局盈利金币数值
		if isFreeRoom == false then	
			RoomMgr.iProfitGold = RoomMgr.iProfitGold + iBankerReturn + nCorrectionRobot
			print("-------------------", "RoomID", tRoomData.nRoomID, iBankerReturn / 10000, RoomMgr.iProfitGold / 10000, "Settlement")
            
			RoomMgr.nCommission = RoomMgr.nCommission + nCommission
		end
		
		tDailyStat.nSystemBanker = tDailyStat.nSystemBanker + 1
		tDailyStat.iSystemProfitGold = tDailyStat.iSystemProfitGold + iBankerReturn	+ nCorrectionRobot	
		tDailyStat.nSystemCommission = tDailyStat.nSystemCommission + nCommission
	end
	tRoom.nStep = 8
	
	for k,v in pairs(tWiner) do
		local tAccount = AccountMgr:GetAccountByID(k)
		local nTotal = 0
		local nTipsGold = 0
		local tPush = {}
		for k1,v1 in pairs(v) do
			nTotal = nTotal + v1[1] + v1[3]
			nTipsGold = nTipsGold + v1[2]
			table.insert(tPush, {{UINT8, k1}, {INT64, v1[1]}, {INT64, v1[2]}, {UINT8, v1[4]}}) 
		end
		
		if isFreeRoom == true then
			tAccount:AddFreeGold(nTotal, OPERATE.SETTLEMENT, tRoomData.nRoomID)
		else			
			tAccount:AddGold(nTotal, OPERATE.SETTLEMENT, tRoomData.nRoomID)
		end		
		
		local tSend = Message:New()
		tSend:Push(TABLE, tPush)
		tSend:Push(INT64, tAccount.nGold)
		net:SendToClient(tSend, PROTOCOL.NOTIFY_WIN_GOLD, tAccount.nSocketID)
	end
	tRoom.nStep = 9
	
    local tExclude = {nRobot = true}
	local tStat = Message:New()
	tRoom:FillStatisticsData(nil, tStat)
	tRoom:SendBroadcast(tStat, PROTOCOL.ADDITION_STATISTICS, tExclude)
	tRoom.nStep = 10
	
	local tReturnList = {}
	for k,v in pairs(tProfitGold) do		
		if isJingMiRoom == true then
			table.insert(tReturnList, {k, v.iProfitGold})
		end
		
		local tAccount = AccountMgr:GetAccountByID(k)
        if tAccount.isRobot == false then
			local tPersonal = tRoomData.tBetting.tPersonal[k]
			SendSettlementLog(k, tRoomData.nRoomID, 0, tPersonal[BETTING.LONG], tPersonal[BETTING.HU], tPersonal[BETTING.LONG_JINHUA], tPersonal[BETTING.BAOZI], tPersonal[BETTING.HU_JINHUA], RESULT_STRING[nHuResult], BRAND_STRING[nLongType], BRAND_STRING[nHuType], v.iProfitGold, PAY_STRING[v.nPayAll], strNowTime)
            
			if isFreeRoom == false then
				tAccount:AddSettlement(nNowTime, tRoomData.nRoomID, tRoomData[IDENTITY.LONG], tRoomData[IDENTITY.HU], nStatisticsResults, tPersonal, v.nPayAll, v.iProfitGold, tAccount.nGold)
			end        
        end
	end
	tRoom.nStep = 11
	
	-- 判断是否播放跑马灯
	if isJingMiRoom == true then	
		-- 排序赢钱最高的玩家
		if #tReturnList > 0 then
			table.sort(tReturnList, _CompReturnNode)				
			local coinLevel = tRoom.tConfig.RunHorseCoinLowerLimit
			if tReturnList[1][2] >= coinLevel then				
				local tAccount = AccountMgr:GetAccountByID(tReturnList[1][1])
				if tAccount ~= nil then
					SmallHornMgr:SendBroadcast(nil, 1, tRoom.tConfig.RoomLevel, tAccount.strName, tReturnList[1][2])
				end
			end
		end
	end
	tRoom.nStep = 12
	
	if tRoom:CanStopService() == true then
		
		tRoom.nStep = 13
		-- 注意: 此处已return
		return
	end
	
	
	local nNextTime = tRoom:SetRoomState(ROOM_STATE.JIESUAN)

	local tNextDengDai = Message:New()
	tNextDengDai:Push(UINT32, tRoomData.nRoomID)
	tRoomData.nTimerID = RegistryTimer(nNextTime, 1, PROTOCOL.START_DENGDAI_STATE, tNextDengDai)
	
	tRoom.nStep = 14
	tRoom:CheckProcessIsCorrect()	
end



local function _ProcessStartLongCuo(tRoom, nSocketID)
	local tRoomData = tRoom.tData		
	if tRoomData.nState ~= ROOM_STATE.OVER_HU_CUO and tRoomData.nState ~= ROOM_STATE.FAPAI then
		LogError{"RoomID:%d, Error State:%d", tRoomData.nRoomID, tRoomData.nState}
		return
	end
	
	local nNextTime = tRoom:SetRoomState(ROOM_STATE.LONG_CUO)
	
	local tSend = Message:New()	
	tRoom:SendBroadcast(tSend, PROTOCOL.START_LONG_CUO)
	
	local tNextState = Message:New()
	tNextState:Push(UINT32, tRoomData.nRoomID)
	tRoomData.nTimerID = RegistryTimer(nNextTime, 1, PROTOCOL.OVER_LONG_CUO_STATE, tNextState)
	tRoom:CheckProcessIsCorrect()
end

local function _ProcessOverLongCuo(tRoom, nSocketID)
	local tRoomData = tRoom.tData	
	if tRoomData.nState ~= ROOM_STATE.FAPAI and tRoomData.nState ~= ROOM_STATE.OVER_HU_CUO and tRoomData.nState ~= ROOM_STATE.LONG_CUO then
		LogError{"RoomID:%d, Error State:%d", tRoomData.nRoomID, tRoomData.nState}
		return
	end
	
	local nNextTime = tRoom:SetRoomState(ROOM_STATE.OVER_LONG_CUO)
	
	local tSend = Message:New()	
	tRoom:SendBroadcast(tSend, PROTOCOL.OVER_LONG_CUO)	
	
	local nNextProtocol = 0
	local tTotal = tRoomData.tBetting.tTotal
	if tTotal[BETTING.LONG] <= tTotal[BETTING.HU] then		
		tRoomData.tCuo[IDENTITY.LONG] = 4
		if tRoomData.tTopHu == nil then
			nNextProtocol = PROTOCOL.OVER_HU_CUO_STATE
		else
			nNextProtocol = PROTOCOL.START_HU_CUO_STATE
		end
	else
		nNextProtocol = PROTOCOL.START_SETTLEMENT_STATE
		tRoomData.tCuo[IDENTITY.LONG] = 4
		tRoomData.tCuo[IDENTITY.HU] = 4
	end		
	
	local tNextState = Message:New()
	tNextState:Push(UINT32, tRoomData.nRoomID)
	tRoomData.nTimerID = RegistryTimer(nNextTime, 1, nNextProtocol, tNextState)
	tRoom:CheckProcessIsCorrect()
end

local function _ProcessStartHuCuo(tRoom, nSocketID)		
	local tRoomData = tRoom.tData	
	if tRoomData.nState ~= ROOM_STATE.FAPAI and tRoomData.nState ~= ROOM_STATE.OVER_LONG_CUO then
		LogError{"RoomID:%d, Error State:%d", tRoomData.nRoomID, tRoomData.nState}
		return
	end
	
	local nNextTime = tRoom:SetRoomState(ROOM_STATE.HU_CUO)
		
	local tSend = Message:New()	
	tRoom:SendBroadcast(tSend, PROTOCOL.START_HU_CUO)
	
	local tNextState = Message:New()
	tNextState:Push(UINT32, tRoomData.nRoomID)
	tRoomData.nTimerID = RegistryTimer(nNextTime, 1, PROTOCOL.OVER_HU_CUO_STATE, tNextState)
	tRoom:CheckProcessIsCorrect()
end

local function _ProcessOverHuCuo(tRoom, nSocketID)		
	local tRoomData = tRoom.tData	
	if tRoomData.nState ~= ROOM_STATE.FAPAI and tRoomData.nState ~= ROOM_STATE.OVER_LONG_CUO and tRoomData.nState ~= ROOM_STATE.HU_CUO then
		LogError{"RoomID:%d, Error State:%d", tRoomData.nRoomID, tRoomData.nState}
		return
	end
	
	local tSend = Message:New()	
	tRoom:SendBroadcast(tSend, PROTOCOL.OVER_HU_CUO)
	
	local nNextProtocol = 0
	local tTotal = tRoomData.tBetting.tTotal
	if tTotal[BETTING.LONG] <= tTotal[BETTING.HU] then
		nNextProtocol = PROTOCOL.START_SETTLEMENT_STATE
		tRoomData.tCuo[IDENTITY.LONG] = 4
		tRoomData.tCuo[IDENTITY.HU] = 4
	else
		tRoomData.tCuo[IDENTITY.HU] = 4
		if tRoomData.tTopLong == nil then
			nNextProtocol = PROTOCOL.OVER_LONG_CUO_STATE
		else
			nNextProtocol = PROTOCOL.START_LONG_CUO_STATE
		end
	end	
	
	local nNextTime = tRoom:SetRoomState(ROOM_STATE.OVER_HU_CUO)
	local tNextState = Message:New()
	tNextState:Push(UINT32, tRoomData.nRoomID)
	tRoomData.nTimerID = RegistryTimer(nNextTime, 1, nNextProtocol, tNextState)
	tRoom:CheckProcessIsCorrect()
end

--　请求部分统计数据
function HandleGetPartialStatData(cPacket, nSocketID)
    local tParseData =
    {
        UINT16,
		{
			UINT32,
		}
    }
    local tData = c_ParserPacket(tParseData, cPacket)
    local tRoomID = tData[1]
	
	local tSend = Message:New()
	tSend:Push(UINT16, #tRoomID)
	for k,v in ipairs(tRoomID) do
		local tRoom = RoomMgr:GetRoom(v[1])
		if tRoom ~= nil then
			tRoom:FillStatisticsData(true, tSend)
		end
	end
	net:SendToClient(tSend, PROTOCOL.GET_PARTIAL_STATISTICS, nSocketID)
end

-- 进入房间
function HandleEnterRoom(cPacket, nSocketID)
    local tParseData =
    {
		UINT32,		-- 帐号ID
        UINT32,		-- 房间ID
    }
	
    local tData = c_ParserPacket(tParseData, cPacket)
    local nAccountID = tData[1]
	local nRoomID = tData[2]
	
	local tSend = Message:New()	
	local tAccount = AccountMgr:GetAccountByID(nAccountID)
	if tAccount == nil then
		tSend:Push(UINT8, 1)
		net:SendToClient(tSend, PROTOCOL.ENTER_ROOM, nSocketID)
		return
	end
	
	if tAccount:IsOnline() == false then
		tSend:Push(UINT8, 7)
		net:SendToClient(tSend, PROTOCOL.ENTER_ROOM, nSocketID)
		return
	end
	
	local tRoom = RoomMgr:GetRoom(nRoomID)
	if tRoom == nil then
		tSend:Push(UINT8, 2)
		net:SendToClient(tSend, PROTOCOL.ENTER_ROOM, nSocketID)
		return
	end
	
	if tRoom:IsFull() then
		tSend:Push(UINT8, 3)
		net:SendToClient(tSend, PROTOCOL.ENTER_ROOM, nSocketID)
		return
	end
	
	-- 已经在房间内
	for k,v in pairs(RoomMgr.tRoomByID) do
		if v.tPlayer[nAccountID] ~= nil then
			tSend:Push(UINT8, 5)
			net:SendToClient(tSend, PROTOCOL.ENTER_ROOM, nSocketID)
			return
		end
	end
	
	local tRoomData = tRoom.tData
	if tRoom.tConfig.Type == ROOM_TYPE.FREE then
		
		local iFreeCount = tAccount:GetFreeCount()
        if iFreeCount > 0 then
			tAccount.nFree = tAccount.nFree + 1			
			tAccount.isChangeData = true
		else			
			tSend:Push(UINT8, 4)
			net:SendToClient(tSend, PROTOCOL.ENTER_ROOM, nSocketID)
			return
		end		
		
		tAccount.nFreeGold = 0
		tAccount:AddFreeGold(PublicConfig.GET_FREE_GOLD, OPERATE.GET_FREE_GOLD, tRoomData.nRoomID)	
	end
	
	
	if tRoomData.nRoomType == ROOM_TYPE.VIP then
		if RoomMgr.nOpenVIP == 0 then
			tSend:Push(UINT8, 8)
			net:SendToClient(tSend, PROTOCOL.ENTER_ROOM, nSocketID)
			return
		end
		
		if tRoomData.nGames >= tRoomData.nMaxGames then
			tSend:Push(UINT8, 6)
			net:SendToClient(tSend, PROTOCOL.ENTER_ROOM, nSocketID)
			return
		end
	else	
		if tRoomData.nOpen == 0 then
			tSend:Push(UINT8, 8)
			net:SendToClient(tSend, PROTOCOL.ENTER_ROOM, nSocketID)
			return
		end
		
		if tRoomData.nCount <= 0 and tRoomData.nTimerID == 0 then
			_ProcessStartDengDai(tRoom, nSocketID)
		end
	end

	if tRoom.tEnterRecord ~= nil then
		tRoom.tEnterRecord[nAccountID] = true
	end
	
	--=================================== TODO 测试用代码
--		if tAccount.nRMB < 1000 then			
--			tAccount:AddRMB(1000, OPERATE.GM)
--		end
		if tAccount.nGold < 10000000 then
			tAccount:AddGold(10000000, OPERATE.GM)
		end
	--=================================== TODO 测试用代码
	
	tSend:Push(UINT8, 0)
	tSend:Push(UINT32, nRoomID)
	tSend:Push(UINT8, tRoom.tConfig.TemplateID)
	net:SendToClient(tSend, PROTOCOL.ENTER_ROOM, nSocketID)
	
	tRoom:SendGameData(nAccountID, nSocketID)
	tRoom:AddPlayer(tAccount)	
	
	local tStat = Message:New()
	tRoom:FillStatisticsData(true, tStat)
	net:SendToClient(tStat, PROTOCOL.GET_ALL_STATISTICS, nSocketID)
end

-- 离开房间
function HandleLeaveRoom(cPacket, nSocketID)
    local tParseData =
    {
        UINT32,		--AccountID
		UINT8,		--Type
    }
	
    local tData = c_ParserPacket(tParseData, cPacket)
    local nAccountID = tData[1]
	local nType = tData[2]
	
	local tSend = Message:New()	
	local tAccount = AccountMgr:GetAccountByID(nAccountID)
	if tAccount == nil then
		tSend:Push(UINT8, 1)
		net:SendToClient(tSend, PROTOCOL.LEAVE_ROOM, nSocketID)
		return
	end
	
	local nRoomID = tAccount.nRoomID
	local tRoom = RoomMgr:GetRoom(nRoomID)
	if tRoom == nil then
--		根据策划要求, 不提示此错误, 例如反复点击退出房间等情况
--		tSend:Push(UINT8, 2)
--		net:SendToClient(tSend, PROTOCOL.LEAVE_ROOM, nSocketID)
		return
	end
	
	-- 不在房间内
	if tRoom.tPlayer[nAccountID] == nil then
		tSend:Push(UINT8, 3)
		net:SendToClient(tSend, PROTOCOL.LEAVE_ROOM, nSocketID)
		return
	end
	
	tRoom:RemovePlayer(tAccount)
    
    local tRoomData = tRoom.tData
    for i = 1, #tRoomData.tUpBanker do
		if tRoomData.tUpBanker[i] == tAccount then
			table.remove(tRoomData.tUpBanker, i)			
			break
		end
	end
	
	tSend:Push(UINT8, 0)
	tSend:Push(UINT8, nType)	-- 退出类型
	net:SendToClient(tSend, PROTOCOL.LEAVE_ROOM, nSocketID)
end


-- 开始等待, 下一阶段下注
function HandleStartDengDai(cPacket, nSocketID)
    local tParseData =
    {
        UINT32,		-- RoomID
    }
    local tData = c_ParserPacket(tParseData, cPacket)
    local nRoomID = tData[1]
	local tRoom = RoomMgr:GetRoom(nRoomID)
	_ProcessStartDengDai(tRoom, nSocketID)
end

-- 开始洗牌状态
function HandleStartXiPai(cPacket, nSocketID)
    local tParseData =
    {
        UINT32,		-- RoomID
    }
    local tData = c_ParserPacket(tParseData, cPacket)
    local nRoomID = tData[1]
	local tRoom = RoomMgr:GetRoom(nRoomID)
	if tRoom == nil then
		LogError{"Room is nil RoomID:%d", nRoomID}
		return
	end
	
	local tRoomData = tRoom.tData
	if tRoomData.nState ~= ROOM_STATE.DENGDAI then
		LogError{"RoomID:%d, Error State:%d", nRoomID, tRoomData.nState}
		return
	end
	
	local tSend = Message:New()
	tRoom:SendBroadcast(tSend, PROTOCOL.START_XIPAI)
	
	local nNextTime = tRoom:SetRoomState(ROOM_STATE.XIPAI)

	local tNextState = Message:New()
	tNextState:Push(UINT32, nRoomID)
	tRoomData.nTimerID = RegistryTimer(nNextTime, 1, PROTOCOL.START_QIEPAI_STATE, tNextState)
	tRoom:CheckProcessIsCorrect()
end


-- 开始切牌状态
function HandleStartQiePai(cPacket, nSocketID)
    local tParseData =
    {
        UINT32,		-- RoomID
    }
    local tData = c_ParserPacket(tParseData, cPacket)
    local nRoomID = tData[1]
	local tRoom = RoomMgr:GetRoom(nRoomID)
	if tRoom == nil then
		LogError{"Room is nil RoomID:%d", nRoomID}
		return
	end
	
	local tRoomData = tRoom.tData
	if tRoomData.nState ~= ROOM_STATE.XIPAI then
		LogError{"RoomID:%d, Error State:%d", nRoomID, tRoomData.nState}
		return
	end
	
	local tSend = Message:New()
	tRoom:SendBroadcast(tSend, PROTOCOL.START_QIEPAI)
	
	local nNextTime = 0	
	local nNextProtocol = 0
	if tRoomData.tBanker == nil then
		nNextTime = PublicConfig.SYSTEM_BANKER_JUMP
		nNextProtocol = PROTOCOL.START_BETTING_STATE
	else
		nNextTime = PublicConfig.ROOM_TIME[ROOM_STATE.QIEPAI]
		nNextProtocol = PROTOCOL.OVER_QIEPAI_STATE
	end
	
	tRoom:SetRoomState(ROOM_STATE.QIEPAI, nNextTime)
	
	local tNextOver = Message:New()
	tNextOver:Push(UINT32, nRoomID)
	tRoomData.nTimerID = RegistryTimer(nNextTime, 1, nNextProtocol, tNextOver)
	tRoom:CheckProcessIsCorrect()
end


-- 完成切牌
function HandleOverQiePai(cPacket, nSocketID)
    local tParseData =
    {
        UINT32,		-- RoomID
    }
    local tData = c_ParserPacket(tParseData, cPacket)
    local nRoomID = tData[1]
	local tRoom = RoomMgr:GetRoom(nRoomID)
	if tRoom == nil then
		LogError{"Room is nil RoomID:%d", nRoomID}
		return
	end

	local nNumber = math.random(1, 8)
	_ProcessOverQiePai(tRoom, nNumber, nSocketID)
end


-- 庄家切牌
function HandleBankerQiePai(cPacket, nSocketID)
    local tParseData =
    {
        UINT32,
		UINT8,
    }
    local tData = c_ParserPacket(tParseData, cPacket)
    local nAccountID = tData[1]
    local nNumber = tData[2]
	
	local tSend = Message:New()
	local tAccount = AccountMgr:GetAccountByID(nAccountID)
	if tAccount == nil then
		tSend:Push(UINT8, 1)
		net:SendToClient(tSend, PROTOCOL.BANKER_QIEPAI, nSocketID)
		return
	end
	
	local tRoom = RoomMgr:GetRoom(tAccount.nRoomID)
	if tRoom == nil then
		tSend:Push(UINT8, 2)
		net:SendToClient(tSend, PROTOCOL.BANKER_QIEPAI, nSocketID)
		return
	end
	
	local tRoomData = tRoom.tData
	if tRoomData.nState ~= ROOM_STATE.QIEPAI then
		tSend:Push(UINT8, 3)
		net:SendToClient(tSend, PROTOCOL.BANKER_QIEPAI, nSocketID)
		return
	end
	
	if tRoomData.tBanker ~= tAccount then
		tSend:Push(UINT8, 4)
		net:SendToClient(tSend, PROTOCOL.BANKER_QIEPAI, nSocketID)
		return
	end
	
	CancelTimer(tRoomData.nTimerID)
	tRoomData.nTimerID = 0
	_ProcessOverQiePai(tRoom, nNumber, nSocketID)
end




-- 开始下注, 下一阶段发牌
function HandleStartBetting(cPacket, nSocketID)
    local tParseData =
    {
        UINT32,		-- RoomID
    }
    local tData = c_ParserPacket(tParseData, cPacket)
    local nRoomID = tData[1]
	local tRoom = RoomMgr:GetRoom(nRoomID)
	if tRoom == nil then
		LogError{"Room is nil RoomID:%d", nRoomID}
		return
	end
	_ProcessStartBetting(tRoom, nSocketID)
end

-- 开始发牌, 下一阶段搓牌
function HandleStartFiring(cPacket, nSocketID)
    local tParseData =
    {
        UINT32,		-- RoomID
    }
    local tData = c_ParserPacket(tParseData, cPacket)
    local nRoomID = tData[1]
	local tRoom = RoomMgr:GetRoom(nRoomID)
	if tRoom == nil then
		LogError{"Room is nil RoomID:%d", nRoomID}
		return
	end
	
	local tRoomData = tRoom.tData
	if tRoomData.nState ~= ROOM_STATE.XIAZHU then
		LogError{"RoomID:%d, Error State:%d", tRoomData.nRoomID, tRoomData.nState}
		return
	end
	
	local tTotal = tRoomData.tBetting.tTotal
	local nTotalBetting = 0
	for k,v in pairs(tTotal) do
		nTotalBetting = nTotalBetting + v
	end
	
	if nTotalBetting <= 0 then		
		-- 无人下注, 如果房间没有玩家, 则停止服务, 初始化房间
		if tRoom:CanStopService() == false then
			-- 无人下注, 如果房间有玩家, 则继续走等待状态
			_ProcessStartDengDai(tRoom, nSocketID)			
		end		
		return
	end
	
	local tUpdateRank = Message:New()
	tRoom:UpdateBettingRank(true, true, tUpdateRank)
	tRoom:SendBroadcast(tUpdateRank, PROTOCOL.TOP_RANK)
	
	if RoomMgr.iProfitGold >= PublicConfig.BASE_LINE[1] then
		-- 按照配置概率随机
		tRoom:FiringToConfigProbability()
	elseif RoomMgr.iProfitGold <= PublicConfig.DANGER_LINE[1] then
		local nRandom = math.random(100)
		if nRandom < PublicConfig.DANGER_LINE[2] then
			-- 吃大赔小
			tRoom:FiringToEatBigPaySmall()
			print("Danger Line EatBigPaySmall", RoomMgr.iProfitGold / 10000, "W")
		else
			-- 按照配置概率随机
			tRoom:FiringToConfigProbability()
		end
	else
		local nRandom = math.random(100)
		if nRandom < PublicConfig.BASE_LINE[2] then
			-- 吃大赔小
			tRoom:FiringToEatBigPaySmall()
			print("Base Line EatBigPaySmall", RoomMgr.iProfitGold / 10000, "W")
		else
			-- 按照配置概率随机
			tRoom:FiringToConfigProbability()
		end
	end
	
	local tSend = Message:New()
	tSend:Push(UINT8, tRoomData[IDENTITY.LONG][1][1])
	tSend:Push(UINT8, tRoomData[IDENTITY.LONG][1][2])
	tSend:Push(UINT8, tRoomData[IDENTITY.LONG][2][1])
	tSend:Push(UINT8, tRoomData[IDENTITY.LONG][2][2])
	tSend:Push(UINT8, tRoomData[IDENTITY.LONG][3][1])
	tSend:Push(UINT8, tRoomData[IDENTITY.LONG][3][2])
	tSend:Push(UINT8, tRoomData[IDENTITY.HU][1][1])
	tSend:Push(UINT8, tRoomData[IDENTITY.HU][1][2])
	tSend:Push(UINT8, tRoomData[IDENTITY.HU][2][1])
	tSend:Push(UINT8, tRoomData[IDENTITY.HU][2][2])
	tSend:Push(UINT8, tRoomData[IDENTITY.HU][3][1])
	tSend:Push(UINT8, tRoomData[IDENTITY.HU][3][2])	
	tRoom:SendBroadcast(tSend, PROTOCOL.START_FIRING)
	
	local nNextTime = tRoom:SetRoomState(ROOM_STATE.FAPAI)

	local nNextProtocol = 0
	if tTotal[BETTING.LONG] <= tTotal[BETTING.HU] then
		if tRoomData.tTopLong == nil then
			nNextProtocol = PROTOCOL.OVER_LONG_CUO_STATE
		else
			nNextProtocol = PROTOCOL.START_LONG_CUO_STATE
		end
	else
		if tRoomData.tTopHu == nil then
			nNextProtocol = PROTOCOL.OVER_HU_CUO_STATE
		else
			nNextProtocol = PROTOCOL.START_HU_CUO_STATE
		end
	end	
	
	local tNextState = Message:New()
	tNextState:Push(UINT32, nRoomID)
	tRoom.tData.nTimerID = RegistryTimer(nNextTime, 1, nNextProtocol, tNextState)
	tRoom:CheckProcessIsCorrect()
end



-- 开始结算, 下一阶段等待
function HandleStartSettlement(cPacket, nSocketID)
    local tParseData =
    {
        UINT32,		-- RoomID
    }
    local tData = c_ParserPacket(tParseData, cPacket)
    local nRoomID = tData[1]
	local tRoom = RoomMgr:GetRoom(nRoomID)
	if tRoom == nil then
		LogError{"Room is nil RoomID:%d", nRoomID}
		return
	end
	_ProcessStartSettlement(tRoom, nSocketID)
end



-- 龙开始搓牌, 下一阶段虎搓牌
function HandleStartLongCuo(cPacket, nSocketID)	
    local tParseData =
    {
        UINT32,		-- RoomID
    }

    local tData = c_ParserPacket(tParseData, cPacket)
	local nRoomID = tData[1]
	local tRoom = RoomMgr:GetRoom(nRoomID)
	if tRoom == nil then
		LogError{"Room is nil RoomID:%d", nRoomID}
		return
	end
	_ProcessStartLongCuo(tRoom, nSocketID)
end

function HandleOverLongCuo(cPacket, nSocketID)
    local tParseData =
    {
        UINT32,		-- RoomID
    }

    local tData = c_ParserPacket(tParseData, cPacket)
	local nRoomID = tData[1]
	local tRoom = RoomMgr:GetRoom(nRoomID)
	if tRoom == nil then
		LogError{"Room is nil RoomID:%d", nRoomID}
		return
	end
	_ProcessOverLongCuo(tRoom, nSocketID)
end

-- 虎开始搓牌, 下一阶段结算
function HandleStartHuCuo(cPacket, nSocketID)	
    local tParseData =
    {
        UINT32,		-- RoomID
    }

    local tData = c_ParserPacket(tParseData, cPacket)
    local nRoomID = tData[1]
	local tRoom = RoomMgr:GetRoom(nRoomID)
	if tRoom == nil then
		LogError{"Room is nil RoomID:%d", nRoomID}
		return
	end
	_ProcessStartHuCuo(tRoom, nSocketID)
end


function HandleOverHuCuo(cPacket, nSocketID)
    local tParseData =
    {
        UINT32,		-- RoomID
    }

    local tData = c_ParserPacket(tParseData, cPacket)
	local nRoomID = tData[1]
	local tRoom = RoomMgr:GetRoom(nRoomID)
	if tRoom == nil then
		LogError{"Room is nil RoomID:%d", nRoomID}
		return
	end
	_ProcessOverHuCuo(tRoom, nSocketID)
end





-- 续局VIP房间
function HandleContinueVIPRoom(cPacket, nSocketID)
    local tParseData =
    {
        UINT32,			-- 帐号ID
		UINT8,			-- 续局局数
    }	
	
    local tData = c_ParserPacket(tParseData, cPacket)
    local nAccountID = tData[1]
    local nGames = tData[2]
	
	local tSend = Message:New()
	local tAccount = AccountMgr:GetAccountByID(nAccountID)
	if tAccount == nil then
		tSend:Push(UINT8, 1)
		net:SendToClient(tSend, PROTOCOL.CONTINUE_GAMES, nSocketID)
		return
	end
	
	local tRoom = RoomMgr:GetRoom(tAccount.nRoomID)
	if tRoom == nil then
		tSend:Push(UINT8, 2)
		net:SendToClient(tSend, PROTOCOL.CONTINUE_GAMES, nSocketID)
		return
	end
	
	local tRoomData = tRoom.tData
	if tRoomData.nRoomOwnerID ~= nAccountID then
		tSend:Push(UINT8, 3)
		net:SendToClient(tSend, PROTOCOL.CONTINUE_GAMES, nSocketID)
		return
	end
	
	if tRoomData.nGames < tRoomData.nMaxGames then
		tSend:Push(UINT8, 4)
		net:SendToClient(tSend, PROTOCOL.CONTINUE_GAMES, nSocketID)
		return
	end
		
	local tVIPConfig = VipConfig[tAccount.nVIPLv]
	local nNeedRoomCard = 0
	if tVIPConfig.RoomCard == 0 then
		nNeedRoomCard = PublicConfig.ROOM_CREATE_COST[nGames]
	end
	if nNeedRoomCard == nil then
		tSend:Push(UINT8, 5)
		net:SendToClient(tSend, PROTOCOL.CONTINUE_GAMES, nSocketID)
		return
	end
	
	if tAccount.nRoomCard < nNeedRoomCard then
		tSend:Push(UINT8, 6)
		net:SendToClient(tSend, PROTOCOL.CONTINUE_GAMES, nSocketID)
		return
	end
	
	if tRoomData.nState ~= ROOM_STATE.DENGDAI then
		tSend:Push(UINT8, 7)
		net:SendToClient(tSend, PROTOCOL.CONTINUE_GAMES, nSocketID)
		return
	end
	
	tAccount:AddRoomCard(-nNeedRoomCard, OPERATE.CONTINUE_GAMES, tAccount.nRoomID)
	_ProcessStartDengDai(tRoom, nSocketID)
end


-- 下注
function HandleBetting(cPacket, nSocketID)
    local tParseData =
    {
		UINT32,		-- 帐号ID
		UINT8,		-- 下注类型
		UINT32,		-- 下注金币数量
    }
    local tData = c_ParserPacket(tParseData, cPacket)
    local nAccountID = tData[1]
	local nBettingType = tData[2]
	local nBettingGold = tData[3]
	
	local tSend = Message:New()
	if nBettingGold <= 0 then
		tSend:Push(UINT8, 12)
		tSend:Push(UINT32, nAccountID)
		tSend:Push(UINT8, nBettingType)
		tSend:Push(UINT32, nBettingGold)
		net:SendToClient(tSend, PROTOCOL.BETTING, nSocketID)
		return
	end
	
	local tAccount = AccountMgr:GetAccountByID(nAccountID)
	if tAccount == nil then
		tSend:Push(UINT8, 1)
		tSend:Push(UINT32, nAccountID)
		tSend:Push(UINT8, nBettingType)
		tSend:Push(UINT32, nBettingGold)
		net:SendToClient(tSend, PROTOCOL.BETTING, nSocketID)
		return
	end
	
	local tRoom = RoomMgr:GetRoom(tAccount.nRoomID)
	if tRoom == nil then
		tSend:Push(UINT8, 2)
		tSend:Push(UINT32, nAccountID)
		tSend:Push(UINT8, nBettingType)
		tSend:Push(UINT32, nBettingGold)
		net:SendToClient(tSend, PROTOCOL.BETTING, nSocketID)
		return
	end
	
	local tRoomData = tRoom.tData
	if tRoomData.nState ~= ROOM_STATE.XIAZHU then
		tSend:Push(UINT8, 3)
		tSend:Push(UINT32, nAccountID)
		tSend:Push(UINT8, nBettingType)
		tSend:Push(UINT32, nBettingGold)
		net:SendToClient(tSend, PROTOCOL.BETTING, nSocketID)
		return
	end
	
	if tRoomData.tBanker ~= nil then
		if tRoomData.tBanker.nAccountID == nAccountID then
			tSend:Push(UINT8, 12)
			tSend:Push(UINT32, nAccountID)
			tSend:Push(UINT8, nBettingType)
			tSend:Push(UINT32, nBettingGold)
			net:SendToClient(tSend, PROTOCOL.BETTING, nSocketID)
			return
		end
	end
	
	local COMPENSATE = PublicConfig.COMPENSATE[nBettingType]
	if COMPENSATE == nil then
		tSend:Push(UINT8, 4)
		tSend:Push(UINT32, nAccountID)
		tSend:Push(UINT8, nBettingType)
		tSend:Push(UINT32, nBettingGold)
		net:SendToClient(tSend, PROTOCOL.BETTING, nSocketID)
		return
	end
	
	local nHaveValue = 0
	local isFreeRoom = tRoomData.nRoomType == ROOM_TYPE.FREE
	if isFreeRoom == true then
		nHaveValue = tAccount.nFreeGold
	else
		nHaveValue = tAccount.nGold
	end
	
	if nHaveValue < nBettingGold then
		tSend:Push(UINT8, 5)
		tSend:Push(UINT32, nAccountID)
		tSend:Push(UINT8, nBettingType)
		tSend:Push(UINT32, nBettingGold)
		net:SendToClient(tSend, PROTOCOL.BETTING, nSocketID)
		return
	end
	
	local tBetting = tRoomData.tBetting
	local tPersonal = tBetting.tPersonal
	local tTotal = tBetting.tTotal
	local tRobot = tBetting.tRobot
	local tType = tBetting.tType
	local tAccountBetting = tPersonal[nAccountID]
	
	if tAccountBetting ~= nil then
		if nBettingType == BETTING.LONG then
			local nTemp = tAccountBetting[BETTING.HU] or 0
			if nTemp > 0 then
				tSend:Push(UINT8, 6)
				tSend:Push(UINT32, nAccountID)
				tSend:Push(UINT8, nBettingType)
				tSend:Push(UINT32, nBettingGold)
				net:SendToClient(tSend, PROTOCOL.BETTING, nSocketID)
				return
			end
		elseif nBettingType == BETTING.HU then
			local nTemp = tAccountBetting[BETTING.LONG] or 0
			if nTemp > 0 then
				tSend:Push(UINT8, 6)
				tSend:Push(UINT32, nAccountID)
				tSend:Push(UINT8, nBettingType)
				tSend:Push(UINT32, nBettingGold)
				net:SendToClient(tSend, PROTOCOL.BETTING, nSocketID)
				return
			end
		end
	end
	
	local nLowerLimit = 0
	local nUpperLimit = 0	
	if nBettingType == BETTING.LONG or nBettingType == BETTING.HU then
		nLowerLimit = tRoom.tConfig.BettingLongHu[1]
		nUpperLimit = tRoom.tConfig.BettingLongHu[2]	
	elseif nBettingType == BETTING.BAOZI then
		nLowerLimit = tRoom.tConfig.BettingBaoZi[1]
		nUpperLimit = tRoom.tConfig.BettingBaoZi[2]	
	else		
		nLowerLimit = tRoom.tConfig.BettingJinHua[1]
		nUpperLimit = tRoom.tConfig.BettingJinHua[2]	
	end
	
	local nTotalPersonal = 0
	if tAccountBetting ~= nil and tAccountBetting[nBettingType] ~= nil then
		nTotalPersonal = tAccountBetting[nBettingType] + nBettingGold
	else
		nTotalPersonal = nBettingGold
	end
	if nBettingGold < nLowerLimit then
		tSend:Push(UINT8, 100 + nBettingType)
		tSend:Push(UINT32, nAccountID)
		tSend:Push(UINT8, nBettingType)
		tSend:Push(UINT32, nBettingGold)
		net:SendToClient(tSend, PROTOCOL.BETTING, nSocketID)
		return
	elseif nTotalPersonal > nUpperLimit then
		tSend:Push(UINT8, 8)
		tSend:Push(UINT32, nAccountID)
		tSend:Push(UINT8, nBettingType)
		tSend:Push(UINT32, nBettingGold)
		net:SendToClient(tSend, PROTOCOL.BETTING, nSocketID)
		return
	end
	
	if tRoomData.tBanker ~= nil then
		local nBankerValue = 0
		if isFreeRoom == true then
			nBankerValue = tRoomData.tBanker.nFreeGold
		else
			nBankerValue = tRoomData.tBanker.nGold
		end
		if nBettingType == BETTING.LONG then
			local nBankerUpperLimit = nBankerValue * PublicConfig.BANKER_COMPENSATE_MULTIPLE
			local nValue = math.abs((tTotal[BETTING.LONG] + nBettingGold) - tTotal[BETTING.HU])
			if nValue > nBankerUpperLimit then
				tSend:Push(UINT8, 9)
				tSend:Push(UINT32, nAccountID)
				tSend:Push(UINT8, nBettingType)
				tSend:Push(UINT32, nBettingGold)
				net:SendToClient(tSend, PROTOCOL.BETTING, nSocketID)
				return
			end
		elseif nBettingType == BETTING.HU then
			local nBankerUpperLimit = nBankerValue * PublicConfig.BANKER_COMPENSATE_MULTIPLE
			local nValue = math.abs(tTotal[BETTING.LONG] - (tTotal[BETTING.HU] + nBettingGold))
			if nValue > nBankerUpperLimit then
				tSend:Push(UINT8, 9)
				tSend:Push(UINT32, nAccountID)
				tSend:Push(UINT8, nBettingType)
				tSend:Push(UINT32, nBettingGold)
				net:SendToClient(tSend, PROTOCOL.BETTING, nSocketID)
				return
			end
		elseif nBettingType == BETTING.BAOZI then
			local nBankerUpperLimit = math.modf(nBankerValue * PublicConfig.COMPENSATE_UPPER_LIMIT_BAOZI / PublicConfig.COMPENSATE[BETTING.BAOZI])
			local nValue = tTotal[BETTING.BAOZI]
			if nValue > nBankerUpperLimit then
				tSend:Push(UINT8, 10)
				tSend:Push(UINT32, nAccountID)
				tSend:Push(UINT8, nBettingType)
				tSend:Push(UINT32, nBettingGold)
				net:SendToClient(tSend, PROTOCOL.BETTING, nSocketID)
				return
			end
		else
			local nBankerUpperLimit = math.modf(nBankerValue / PublicConfig.COMPENSATE_UPPER_LIMIT_JINHUA / PublicConfig.COMPENSATE[BETTING.LONG_JINHUA])
			local nValue = tTotal[nBettingType]
			if nValue > nBankerUpperLimit then
				tSend:Push(UINT8, 11)
				tSend:Push(UINT32, nAccountID)
				tSend:Push(UINT8, nBettingType)
				tSend:Push(UINT32, nBettingGold)
				net:SendToClient(tSend, PROTOCOL.BETTING, nSocketID)
				return
			end
		end	
	end
	
	if isFreeRoom == true then
		tAccount:AddFreeGold(-nBettingGold, OPERATE.BETTING, tAccount.nRoomID)
	else
		tAccount:AddGold(-nBettingGold, OPERATE.BETTING, tAccount.nRoomID)
	end
	
	if tPersonal[nAccountID] == nil then
		tPersonal[nAccountID] = {}
	end
	if tPersonal[nAccountID][nBettingType] == nil then
		tPersonal[nAccountID][nBettingType] = 0
	end
	
	tPersonal[nAccountID].nLastBettingTime = GetSystemTimeToSecond()
	tPersonal[nAccountID][nBettingType] = nTotalPersonal
	
	local tDailyStat = RoomMgr.tDailyStat[tRoom.tConfig.TemplateID]
	tDailyStat[nBettingType] = tDailyStat[nBettingType] + nBettingGold
    
	tTotal[nBettingType] = tTotal[nBettingType] + nBettingGold	
    if tAccount.isRobot == true then
        tRobot[nBettingType] = tRobot[nBettingType] + nBettingGold
    end
    
	local tTypeNode = tType[nBettingType]
	if tTypeNode[nBettingGold] == nil then
		tTypeNode[nBettingGold] = 0
	end    
	tTypeNode[nBettingGold] = tTypeNode[nBettingGold] + 1
	tAccount:AddTotalBetting(nBettingGold, tRoomData.nRoomType)
	
--  TODO 策划要求屏蔽此功能, 以后可能会再开启
--	-- 满足条件则发送要求成为推广员的邮件
--	if tAccount.nSendEmail == 0 and tAccount.nTotalBetting >= PublicConfig.TO_SALESMAN_BETTING then
--		tAccount.nSendEmail = 1
--		tAccount.isChangeData = true
--		
--		-- 发送邀请成为推广员邮件
--		EmailMgr:AddMail(nAccountID, MAIL_TYPE.INVITE, "", "", 0, 0, 0, true)		
--	end
	
    local tExclude = {nRobot = true}
	tSend:Push(UINT8, 0)
	tSend:Push(UINT32, nAccountID)
	tSend:Push(UINT8, nBettingType)
	tSend:Push(UINT32, nBettingGold)
	tRoom:SendBroadcast(tSend, PROTOCOL.BETTING, tExclude)	
	
	if nBettingType == BETTING.HU or nBettingType == BETTING.LONG then       
		local tUpdateRank = Message:New()
		tRoom:UpdateBettingRank(false, true, tUpdateRank)
		tRoom:SendBroadcast(tUpdateRank, PROTOCOL.UPDATE_RANK, tExclude)
	end
end


-- 同步搓牌状况
function HandleCuoSituation(cPacket, nSocketID)
    local tParseData =
    {
        UINT32,
		UINT8,
		UINT8,
		UINT8,
		FLOAT,
		FLOAT,
    }
    local tData = c_ParserPacket(tParseData, cPacket)
    local nAccountID = tData[1]
    local nNumber = tData[2]
	local nRotate = tData[3]
	local nMode = tData[4]
	local fX = tData[5]
	local fY = tData[6]
	
	local tAccount = AccountMgr:GetAccountByID(nAccountID)
	if tAccount == nil then
		return
	end
	
	local tRoom = RoomMgr:GetRoom(tAccount.nRoomID)
	if tRoom == nil then
		return
	end
	
    
	local tExclude = {nRobot = true}
	local tSend = Message:New()
	tSend:Push(UINT32, nAccountID)
	tSend:Push(UINT8, nNumber)
	tSend:Push(UINT8, nRotate)
	tSend:Push(UINT8, nMode)
	tSend:Push(FLOAT, fX)
	tSend:Push(FLOAT, fY)
	tRoom:SendBroadcast(tSend, PROTOCOL.CUO_SITUATION, tExclude)
end

-- 同步明牌数量
function HandleMingCardCount(cPacket, nSocketID)
    local tParseData =
    {
        UINT32,		-- 帐号ID
		UINT8,		-- 第几张是明牌 (2,3,4全部明牌)
    }
    local tData = c_ParserPacket(tParseData, cPacket)
    local nAccountID = tData[1]
	local nNumber = tData[2]
	
	local tSend = Message:New()
	local tAccount = AccountMgr:GetAccountByID(nAccountID)
	if tAccount == nil then
		tSend:Push(UINT8, 1)
		net:SendToClient(tSend, PROTOCOL.MING_CARD_COUNT, nSocketID)
		return
	end
	
	local tRoom = RoomMgr:GetRoom(tAccount.nRoomID)
	if tRoom == nil then
		tSend:Push(UINT8, 2)
		net:SendToClient(tSend, PROTOCOL.MING_CARD_COUNT, nSocketID)
		return
	end
	
	if nNumber < 2 or nNumber > 4 then
		tSend:Push(UINT8, 3)
		net:SendToClient(tSend, PROTOCOL.MING_CARD_COUNT, nSocketID)
		return
	end
	
	local tRoomData = tRoom.tData	
	local nIdentity = 0
	if tRoomData.nState == ROOM_STATE.LONG_CUO and tAccount == tRoomData.tTopLong then
		tRoomData.tCuo[IDENTITY.LONG] = nNumber
		nIdentity = IDENTITY.LONG
	elseif tRoomData.nState == ROOM_STATE.HU_CUO and tAccount == tRoomData.tTopHu then
		tRoomData.tCuo[IDENTITY.HU] = nNumber
		nIdentity = IDENTITY.HU
	else
		-- 非异常, 例如最后一秒同时点开牌, 就有可能出现连发2次此消息
		-- 或者网络延迟, 连发2次此消息
		return
	end
	
	if nNumber == 4 then
		
		if nIdentity == IDENTITY.LONG then
			
			-- 提前明牌, 进入下一阶段, 注销之前的计时器
			CancelTimer(tRoomData.nTimerID)
			tRoomData.nTimerID = 0
			_ProcessOverLongCuo(tRoom, nSocketID)
		elseif nIdentity == IDENTITY.HU then	
			
			-- 提前明牌, 进入下一阶段, 注销之前的计时器
			CancelTimer(tRoomData.nTimerID)
			tRoomData.nTimerID = 0		
			_ProcessOverHuCuo(tRoom, nSocketID)
		end
	else		
	
	    local tExclude = {nRobot = true}
		tSend:Push(UINT8, 0)
		tSend:Push(UINT8, nIdentity)
		tSend:Push(UINT8, nNumber)
		tRoom:SendBroadcast(tSend, PROTOCOL.MING_CARD_COUNT, tExclude)
	end
end

-- 请求进入过的VIP房列表
function HandleGetVIPRoomList(cPacket, nSocketID)
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
		net:SendToClient(tSend, PROTOCOL.GET_ENTER_VIP_LIST)
		return
	end
	
	local tPush = {}
	for k,v in pairs(RoomMgr.tRoomByID) do
		if v.tEnterRecord ~= nil then
			if v.tEnterRecord[nAccountID] ~= nil then
				local tRoomOwner = AccountMgr:GetAccountByID(v.tData.nRoomOwnerID)
				if tRoomOwner ~= nil and v.tData.nGames < v.tData.nMaxGames then
					table.insert(tPush, {{UINT32, k}, {STRING, tRoomOwner.strName}})
				end
			end
		end
	end

	tSend:Push(UINT8, 0)
	tSend:Push(TABLE, tPush)
	net:SendToClient(tSend, PROTOCOL.GET_ENTER_VIP_LIST, nSocketID)
end

-- 创建VIP房间
function HandleCreateVIPRoom(cPacket, nSocketID)
    local tParseData =
    {
        UINT32,		-- 帐号ID
		UINT8,		-- VIP房档次
		UINT8,		-- 开局局数
    }
    local tData = c_ParserPacket(tParseData, cPacket)
    local nAccountID = tData[1]
	local nVIPRoomType = tData[2]
	local nGames = tData[3]
	
	local tSend = Message:New()
	local tAccount = AccountMgr:GetAccountByID(nAccountID)
	if tAccount == nil then
		tSend:Push(UINT8, 1)
		net:SendToClient(tSend, PROTOCOL.CREATE_VIP_ROOM, nSocketID)
		return
	end
	
	if RoomMgr.nOpenVIP == 0 then
		tSend:Push(UINT8, 6)
		net:SendToClient(tSend, PROTOCOL.CREATE_VIP_ROOM, nSocketID)
		return
	end
	
	local tConfig = RoomConfig[nVIPRoomType]
	if tConfig == nil then
		tSend:Push(UINT8, 2)
		net:SendToClient(tSend, PROTOCOL.CREATE_VIP_ROOM, nSocketID)
		return
	end
	
	local tVIPConfig = VipConfig[tAccount.nVIPLv]
	local nNeedRoomCard = 0
	if tVIPConfig.RoomCard == 0 then
		nNeedRoomCard = PublicConfig.ROOM_CREATE_COST[nGames]
	end
	if nNeedRoomCard == nil then
		tSend:Push(UINT8, 3)
		net:SendToClient(tSend, PROTOCOL.CREATE_VIP_ROOM, nSocketID)
		return
	end
	
	if tAccount.nRoomCard < nNeedRoomCard then
		tSend:Push(UINT8, 4)
		net:SendToClient(tSend, PROTOCOL.CREATE_VIP_ROOM, nSocketID)
		return
	end
	
	-- 只能创建一个VIP房间
	--for k,v in pairs(RoomMgr.tRoomByID) do
	--	if v.tData.nGames < v.tData.nMaxGames and v.tData.nRoomOwnerID == nAccountID then
	--		tSend:Push(UINT8, 5)
	--		net:SendToClient(tSend, PROTOCOL.CREATE_VIP_ROOM, nSocketID)
	--		return
	--	end
	--end
	
	local nNewRoomID = math.random(100000, 999999)
	local tRoom = RoomMgr:GetRoom(nNewRoomID)
	while tRoom ~= nil do
		nNewRoomID = math.random(100000, 999999)
		tRoom = RoomMgr:GetRoom(nNewRoomID)
	end
	
	local tNewRoom = Room:New(tConfig)	
	tNewRoom.tData.nRoomID = nNewRoomID
	tNewRoom.tData.nRoomType = ROOM_TYPE.VIP
	tNewRoom.tData.nRoomOwnerID = nAccountID
	tNewRoom.tData.nMaxGames = nGames
	tNewRoom.tData.nDestroyTime = GetSystemTimeToSecond() + ROOM_DESTROY_TIME
	tNewRoom:SetRoomState(ROOM_STATE.DENGDAI_START)
	tNewRoom.tEnterRecord = {}
	RoomMgr.tRoomByID[nNewRoomID] = tNewRoom	
	
	tAccount:AddRoomCard(-nNeedRoomCard, OPERATE.CREATE_VIP_ROOM, nNewRoomID)
	
	tSend:Push(UINT8, 0)
	tSend:Push(UINT32, nNewRoomID)
	net:SendToClient(tSend, PROTOCOL.CREATE_VIP_ROOM, nSocketID)
end

-- 开始VIP房间
function HandleStartVIPRoom(cPacket, nSocketID)

    local tParseData =
    {
        UINT32,		-- 帐号ID
    }
    local tData = c_ParserPacket(tParseData, cPacket)
    local nAccountID = tData[1]
	
	local tSend = Message:New()
	local tAccount = AccountMgr:GetAccountByID(nAccountID)
	if tAccount == nil then
		tSend:Push(UINT8, 1)
		net:SendToClient(tSend, PROTOCOL.START_VIP_ROOM, nSocketID)
		return
	end
	
	local tRoom = RoomMgr:GetRoom(tAccount.nRoomID)
	if tRoom == nil then
		tSend:Push(UINT8, 2)
		net:SendToClient(tSend, PROTOCOL.START_VIP_ROOM, nSocketID)
		return
	end
	
	local tRoomData = tRoom.tData	
	if tRoomData.nRoomOwnerID ~= nAccountID then
		tSend:Push(UINT8, 3)
		net:SendToClient(tSend, PROTOCOL.START_VIP_ROOM, nSocketID)
		return
	end	
	
	if tRoomData.nState ~= ROOM_STATE.DENGDAI_START then
		tSend:Push(UINT8, 4)
		net:SendToClient(tSend, PROTOCOL.START_VIP_ROOM, nSocketID)
		return
	end
	
	_ProcessStartDengDai(tRoom, nSocketID)
end


-- 钻石兑换金币
function HandleExchangeGold(cPacket, nSocketID)
    local tParseData =
    {
        UINT32,	
		INT64,		--金币
    }
    local tData = c_ParserPacket(tParseData, cPacket)
    local nAccountID = tData[1]
	local nGold = tData[2]
	
	local tSend = Message:New()
	local tAccount = AccountMgr:GetAccountByID(nAccountID)
	if tAccount == nil then
		tSend:Push(UINT8, 1)
		net:SendToClient(tSend, PROTOCOL.EXCHANGE_GOLD, nSocketID)
		return
	end
	
	local nCount, nDecimal = math.modf(nGold / PublicConfig.EXCHANGE_GOLD[2])
	if nDecimal ~= 0 or nCount <= 0 then
		tSend:Push(UINT8, 2)
		net:SendToClient(tSend, PROTOCOL.EXCHANGE_GOLD, nSocketID)
		return
	end
	
	local nNeedRMB = nCount * PublicConfig.EXCHANGE_GOLD[1]
	if tAccount.nRMB < nNeedRMB then
		tSend:Push(UINT8, 3)
		net:SendToClient(tSend, PROTOCOL.EXCHANGE_GOLD, nSocketID)
		return
	end
	
	if tAccount.nGold + nGold > PublicConfig.MAX_GOLD then
		tSend:Push(UINT8, 4)
		net:SendToClient(tSend, PROTOCOL.EXCHANGE_GOLD, nSocketID)
		return
	end
	
	tAccount:AddRMB(-nNeedRMB, OPERATE.EXCHANGE_GOLD)
	tAccount:AddGold(nGold, OPERATE.EXCHANGE_GOLD)
	
	if tAccount.nRoomID > 0 then
		local tRoom = RoomMgr:GetRoom(tAccount.nRoomID)
		if tRoom ~= nil and tAccount == tRoom.tData.tBanker then
			tRoom:UpdateRankerGold()
		end
	end
	
	tSend:Push(UINT8, 0)
	tSend:Push(INT64, nGold)
	net:SendToClient(tSend, PROTOCOL.EXCHANGE_GOLD, nSocketID)
end


-- 钻石兑换房卡
function HandleExchangeRoomCard(cPacket, nSocketID)
    local tParseData =
    {
        UINT32,	
		UINT32,			--房卡
    }
    local tData = c_ParserPacket(tParseData, cPacket)
    local nAccountID = tData[1]
	local nRoomCard = tData[2]
	
	local tSend = Message:New()
	local tAccount = AccountMgr:GetAccountByID(nAccountID)
	if tAccount == nil then
		tSend:Push(UINT8, 1)
		net:SendToClient(tSend, PROTOCOL.EXCHANGE_ROOMCARD, nSocketID)
		return
	end
	
	local nCount, nDecimal = math.modf(nRoomCard / PublicConfig.EXCHANGE_ROOMCARD[2])
	if nDecimal ~= 0 or nCount <= 0  then
		tSend:Push(UINT8, 2)
		net:SendToClient(tSend, PROTOCOL.EXCHANGE_ROOMCARD, nSocketID)
		return
	end
	
	local nNeedRMB = nCount * PublicConfig.EXCHANGE_ROOMCARD[1]
	if tAccount.nRMB < nNeedRMB then
		tSend:Push(UINT8, 3)
		net:SendToClient(tSend, PROTOCOL.EXCHANGE_ROOMCARD, nSocketID)
		return
	end
	
	tAccount:AddRMB(-nNeedRMB, OPERATE.EXCHANGE_ROOMCARD)
	tAccount:AddRoomCard(nRoomCard, OPERATE.EXCHANGE_ROOMCARD)
	
	tSend:Push(UINT8, 0)
	tSend:Push(UINT32, nRoomCard)
	net:SendToClient(tSend, PROTOCOL.EXCHANGE_ROOMCARD, nSocketID)
end



-- 申请上庄
function HandleApplyUpBanker(cPacket, nSocketID)
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
		net:SendToClient(tSend, PROTOCOL.APPLY_UP_BANKER, nSocketID)
		return
	end
	
	local tRoom = RoomMgr:GetRoom(tAccount.nRoomID)
	if tRoom == nil then
		tSend:Push(UINT8, 2)
		net:SendToClient(tSend, PROTOCOL.APPLY_UP_BANKER, nSocketID)
		return
	end
	
	local tRoomData = tRoom.tData
	if tAccount.nVIPLv < tRoom.tConfig.UpBankerVIPLv then
		tSend:Push(UINT8, 3)
		net:SendToClient(tSend, PROTOCOL.APPLY_UP_BANKER, nSocketID)
		return
	end
	
	local nHaveGold = 0
	if tRoomData.nRoomType == ROOM_TYPE.FREE then
		nHaveGold = tAccount.nFreeGold
	else
		nHaveGold = tAccount.nGold
	end
	
	if nHaveGold < tRoom.tConfig.UpBankerGold then
		tSend:Push(UINT8, 4)
		net:SendToClient(tSend, PROTOCOL.APPLY_UP_BANKER, nSocketID)
		return
	end
	
	for k,v in pairs(RoomMgr.tRoomByID) do
		if v.tData.tBanker == tAccount then
			tSend:Push(UINT8, 7)
			net:SendToClient(tSend, PROTOCOL.APPLY_UP_BANKER, nSocketID)
			return
		end
	end
	
	for k,v in ipairs(tRoomData.tUpBanker) do
		if v.nAccountID == nAccountID then
			tSend:Push(UINT8, 6)
			net:SendToClient(tSend, PROTOCOL.APPLY_UP_BANKER, nSocketID)
			return
		end
	end
	
	local nUpLen = #tRoomData.tUpBanker
	if nUpLen >= PublicConfig.MAX_APPLY_UP_BANKER then
		tSend:Push(UINT8, 5)
		net:SendToClient(tSend, PROTOCOL.APPLY_UP_BANKER, nSocketID)
		return
	end
	
	local nTopUperGold = 0
	local tTopUper = tRoomData.tUpBanker[1]	
	if tTopUper ~= nil then
		if tRoomData.nRoomType == ROOM_TYPE.FREE then
			nTopUperGold = tTopUper.nFreeGold
		else
			nTopUperGold = tTopUper.nGold
		end		
	end
	
	if tTopUper ~= nil and nHaveGold >= (nTopUperGold * PublicConfig.SKIP_BANKER_GOLD_MULTIPLE) then
		table.insert(tRoomData.tUpBanker, 1, tAccount)
	else
		table.insert(tRoomData.tUpBanker, tAccount)
	end
	
	tSend:Push(UINT8, 0)
	net:SendToClient(tSend, PROTOCOL.APPLY_UP_BANKER, nSocketID)	
end

-- 获取申请下庄状态
function HandleGetDownBanker(cPacket, nSocketID)
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
		net:SendToClient(tSend, PROTOCOL.GET_DOWN_BANKER, nSocketID)
		return
	end
	
	local tRoom = RoomMgr:GetRoom(tAccount.nRoomID)
	if tRoom == nil then
		tSend:Push(UINT8, 2)
		net:SendToClient(tSend, PROTOCOL.GET_DOWN_BANKER, nSocketID)
		return
	end
	
	local tRoomData = tRoom.tData	
	if tRoomData.tBanker ~= tAccount then
		tSend:Push(UINT8, 3)
		net:SendToClient(tSend, PROTOCOL.GET_DOWN_BANKER, nSocketID)
		return
	end

	tSend:Push(UINT8, 0)
	tSend:Push(UINT8, tRoomData.tUpBanker.isSetDownBanker)
	net:SendToClient(tSend, PROTOCOL.GET_DOWN_BANKER, nSocketID)	
end


-- 申请下庄
function HandleApplyDownBanker(cPacket, nSocketID)
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
		net:SendToClient(tSend, PROTOCOL.APPLY_DOWN_BANKER, nSocketID)
		return
	end
	
	local tRoom = RoomMgr:GetRoom(tAccount.nRoomID)
	if tRoom == nil then
		tSend:Push(UINT8, 2)
		net:SendToClient(tSend, PROTOCOL.APPLY_DOWN_BANKER, nSocketID)
		return
	end
	
	local tRoomData = tRoom.tData	
	if tRoomData.tBanker ~= tAccount then
		tSend:Push(UINT8, 3)
		net:SendToClient(tSend, PROTOCOL.APPLY_DOWN_BANKER, nSocketID)
		return
	end
	
	if tRoomData.tUpBanker.isSetDownBanker == 1 then
		tSend:Push(UINT8, 4)
		net:SendToClient(tSend, PROTOCOL.APPLY_DOWN_BANKER, nSocketID)
		return
	end
	
	tRoomData.tUpBanker.isSetDownBanker = 1
	
	tSend:Push(UINT8, 0)
	net:SendToClient(tSend, PROTOCOL.APPLY_DOWN_BANKER, nSocketID)	
end


-- 获得申请上庄列表
function HandleGetUpBankerList(cPacket, nSocketID)
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
		net:SendToClient(tSend, PROTOCOL.GET_UP_BANKER_LIST, nSocketID)
		return
	end
	
	local tRoom = RoomMgr:GetRoom(tAccount.nRoomID)
	if tRoom == nil then
		tSend:Push(UINT8, 2)
		net:SendToClient(tSend, PROTOCOL.GET_UP_BANKER_LIST, nSocketID)
		return
	end
	
	local tRoomData = tRoom.tData
	local tPush = {}
	for k,v in ipairs(tRoomData.tUpBanker) do
		if tRoomData.nRoomType == ROOM_TYPE.FREE then
			table.insert(tPush, {{UINT32, v.nAccountID},{STRING, v.strName}, {INT64, v.nFreeGold}, {UINT8, v.nVIPLv}})
		else
			table.insert(tPush, {{UINT32, v.nAccountID},{STRING, v.strName}, {INT64, v.nGold}, {UINT8, v.nVIPLv}})
		end
	end

	tSend:Push(UINT8, 0)
	tSend:Push(TABLE, tPush)
	net:SendToClient(tSend, PROTOCOL.GET_UP_BANKER_LIST, nSocketID)	
end

-- 请求玩家列表
function HandleGetPlayerList(cPacket, nSocketID)
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
		net:SendToClient(tSend, PROTOCOL.GET_PLAYER_LIST, nSocketID)
		return
	end
	
	local tRoom = RoomMgr:GetRoom(tAccount.nRoomID)
	if tRoom == nil then
		tSend:Push(UINT8, 2)
		net:SendToClient(tSend, PROTOCOL.GET_PLAYER_LIST, nSocketID)
		return
	end
	
	local nRoomType = tRoom.tData.nRoomType
	local tPush = {}
	for k,v in pairs(tRoom.tPlayer) do
		if nRoomType == ROOM_TYPE.FREE then		
			table.insert(tPush, {{UINT32, v.nAccountID},{STRING, v.strName}, {INT64, v.nFreeGold}, {UINT8, v.nHeadID}})
		else
			table.insert(tPush, {{UINT32, v.nAccountID},{STRING, v.strName}, {INT64, v.nGold}, {UINT8, v.nHeadID}})
		end
	end

	tSend:Push(UINT8, 0)
	tSend:Push(TABLE, tPush)
	net:SendToClient(tSend, PROTOCOL.GET_PLAYER_LIST, nSocketID)	
end


function HandlePaoPaoChat(cPacket, nSocketID)
	local tParseData =
	{
		UINT32,
		UINT8,
		UINT8,
	}
	local tData = c_ParserPacket(tParseData, cPacket)
	local nAccountID = tData[1]
	local nSenderEnum = tData[2]
	local nChatInEnum = tData[3]
	
	local tAccount = AccountMgr:GetAccountByID(nAccountID)
	if tAccount == nil then
		return
	end
	
	local tRoom = RoomMgr:GetRoom(tAccount.nRoomID)
	if tRoom == nil then
		return
	end
    
	local tExclude = {nRobot = true}
	local tSend = Message:New()
	tSend:Push(UINT8, nSenderEnum)
	tSend:Push(UINT8, nChatInEnum)
	tRoom:SendBroadcast(tSend, PROTOCOL.CS_PAOPAO_CHAT, tExclude)
end


-- 搓牌时喊口号
function HandleShoutSlogans(cPacket, nSocketID)
    local tParseData =
    {
        UINT32,	
		UINT8,
    }
    local tData = c_ParserPacket(tParseData, cPacket)
    local nAccountID = tData[1]
    local nCartType = tData[2]
		
	local tSend = Message:New()
	local tAccount = AccountMgr:GetAccountByID(nAccountID)
	if tAccount == nil then
		tSend:Push(UINT8, 1)
		net:SendToClient(tSend, PROTOCOL.SHOUT_SLOGANS, nSocketID)
		return
	end
	
	local tRoom = RoomMgr:GetRoom(tAccount.nRoomID)
	if tRoom == nil then
		tSend:Push(UINT8, 2)
		net:SendToClient(tSend, PROTOCOL.SHOUT_SLOGANS, nSocketID)
		return
	end
	
	local nRoomState = tRoom.tData.nState
	if nRoomState < ROOM_STATE.LONG_CUO or nRoomState > ROOM_STATE.OVER_HU_CUO then
		tSend:Push(UINT8, 3)
		net:SendToClient(tSend, PROTOCOL.SHOUT_SLOGANS, nSocketID)
		return
	end
	
    local tExclude = {nID = nAccountID, nRobot = true}
	tSend:Push(UINT8, 0)
	tSend:Push(UINT8, nCartType)
	tRoom:SendBroadcast(tSend, PROTOCOL.SHOUT_SLOGANS, tExclude)
end



-- 语音转发
function HandleVoiceForwarding(cPacket, nSocketID)
    local tParseData =
    {
        UINT32,	
		STRING,
    }
    local tData = c_ParserPacket(tParseData, cPacket)
    local nAccountID = tData[1]
    local strVoice = tData[2]
	
	local tSend = Message:New()
	local tAccount = AccountMgr:GetAccountByID(nAccountID)
	if tAccount == nil then
		tSend:Push(UINT8, 1)
		net:SendToClient(tSend, PROTOCOL.VOICE_FORWARDING, nSocketID)
		return
	end
	
	local tRoom = RoomMgr:GetRoom(tAccount.nRoomID)
	if tRoom == nil then
		tSend:Push(UINT8, 2)
		net:SendToClient(tSend, PROTOCOL.VOICE_FORWARDING, nSocketID)
		return
	end
	
	if tRoom.tData.nRoomType ~= ROOM_TYPE.VIP then
		tSend:Push(UINT8, 3)
		net:SendToClient(tSend, PROTOCOL.VOICE_FORWARDING, nSocketID)
		return
	end
	
	local nNowTime = GetSystemTimeToSecond()
	if tAccount.nLastVoiceTime > 0 and tAccount.nLastVoiceTime + PublicConfig.VOICE_INTERVAL < nNowTime  then
		tSend:Push(UINT8, 4)
		net:SendToClient(tSend, PROTOCOL.VOICE_FORWARDING, nSocketID)
		return
	end
	
	tAccount.nLastVoiceTime = nNowTime
	tSend:Push(UINT8, 0)
	tSend:Push(STRING, tAccount.strName)
	tSend:Push(UINT8, tAccount.nHeadID)
	tSend:Push(STRING, strVoice)
	tRoom:SendBroadcast(tSend, PROTOCOL.VOICE_FORWARDING)
end