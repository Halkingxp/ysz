print"Room.lua"



if Room == nil then
    Room = {}
end


function Room:New(tConfig)
	local tObj = 
	{
		nStep = 0,
		tConfig = tConfig,
		tPlayer = {},
		tStatistics = 
		{
			tResult = {},
			nLongWin = 0,
			nHuWin = 0,
			nHe = 0,
			nLongJinHua = 0,
			nHuJinHua = 0,
			nBaoZi = 0,
		},
		
		tData = 
		{
			nOpen = 1,
			nRoomOwnerID = 0,
			nRoomID = 0,
			nRoomType = 0,
			tBanker = nil,
			tTopLong = nil,
			tTopHu = nil,
			tLongRank = nil,
			tHuRank = nil,
			tBaoZiRank = nil,
			tJinHuaRank = nil,
			nTimerID = 0,
			nExpireTime = 0,
			nDestroyTime = 0,
			nState = ROOM_STATE.DENGDAI_START,
			tBetting = 
			{
				tPersonal = {}, 
                
				tTotal = 
				{
					[BETTING.LONG] 			= 0,
					[BETTING.HU] 			= 0,
					[BETTING.LONG_JINHUA] 	= 0,
					[BETTING.HU_JINHUA] 	= 0,
					[BETTING.BAOZI] 		= 0,			
				},
                
                tRobot =
                {
					[BETTING.LONG] 			= 0,
					[BETTING.HU] 			= 0,
					[BETTING.LONG_JINHUA] 	= 0,
					[BETTING.HU_JINHUA] 	= 0,
					[BETTING.BAOZI] 		= 0,
                },
                
				tType = 
				{
					[BETTING.LONG] 			= {},
					[BETTING.HU] 			= {},
					[BETTING.LONG_JINHUA] 	= {},
					[BETTING.HU_JINHUA] 	= {},
					[BETTING.BAOZI] 		= {},			
				},
			},
			tCuo = {},
			nCount = 0,
            nRobotCount = 0,
			nGames = 0,
			nMaxGames = 0,
			tUpBanker = { nBankerGames = 0, isSetDownBanker = 0 },
			nCurrentCheck = 0,
			nLastCheck = -1,
		},
		
		tEnterRecord = nil,
		
		tCard =	
		{			
			-- 黑桃
			{CARD_COLOR.HEITAO, 7 },
			{CARD_COLOR.HEITAO, 8 },
			{CARD_COLOR.HEITAO, 9 },
			{CARD_COLOR.HEITAO, 10},
			{CARD_COLOR.HEITAO, 11},
			{CARD_COLOR.HEITAO, 12},
			{CARD_COLOR.HEITAO, 13},
			{CARD_COLOR.HEITAO, 14},
			
			-- 红桃
			{CARD_COLOR.HONGTAO, 7 },
			{CARD_COLOR.HONGTAO, 8 },
			{CARD_COLOR.HONGTAO, 9 },
			{CARD_COLOR.HONGTAO, 10},
			{CARD_COLOR.HONGTAO, 11},
			{CARD_COLOR.HONGTAO, 12},
			{CARD_COLOR.HONGTAO, 13},
			{CARD_COLOR.HONGTAO, 14},
			
			-- 梅花
			{CARD_COLOR.MEIHUA, 7 },
			{CARD_COLOR.MEIHUA, 8 },
			{CARD_COLOR.MEIHUA, 9 },
			{CARD_COLOR.MEIHUA, 10},
			{CARD_COLOR.MEIHUA, 11},
			{CARD_COLOR.MEIHUA, 12},
			{CARD_COLOR.MEIHUA, 13},
			{CARD_COLOR.MEIHUA, 14},
			
			-- 方块
			{CARD_COLOR.FANGKUAI, 7 },
			{CARD_COLOR.FANGKUAI, 8 },
			{CARD_COLOR.FANGKUAI, 9 },
			{CARD_COLOR.FANGKUAI, 10},
			{CARD_COLOR.FANGKUAI, 11},
			{CARD_COLOR.FANGKUAI, 12},
			{CARD_COLOR.FANGKUAI, 13},
			{CARD_COLOR.FANGKUAI, 14},
		},
	}
	
	Extends(tObj, self)	
	return tObj	
end


function Room:CanStopService()
	local tRoomData = self.tData
	if tRoomData.nCount == 0 then
		self:InitRoom(true)
		CancelTimer(tRoomData.nTimerID)
		tRoomData.nTimerID = 0
		return true
	else
		return false
	end
end

-- 初始化房间
function Room:InitRoom(isInitAll)
	local tRoomData = self.tData
	
	if isInitAll == true then	
		self.tPlayer = {}
		tRoomData.nCount = 0
		tRoomData.nExpireTime = 0
		tRoomData.tBanker = nil
		tRoomData.tUpBanker = { nBankerGames = 0, isSetDownBanker = 0 }
		self:SetRoomState(ROOM_STATE.DENGDAI_START)
	end
	
	tRoomData[IDENTITY.LONG] = nil
	tRoomData[IDENTITY.HU] = nil	
	tRoomData.tTopHu = nil
	tRoomData.tTopLong = nil
	tRoomData.tBetting.tPersonal = {}
	tRoomData.tBetting.tTotal = 
	{
		[BETTING.LONG] 			= 0,
		[BETTING.HU] 			= 0,
		[BETTING.LONG_JINHUA] 	= 0,
		[BETTING.HU_JINHUA] 	= 0,
		[BETTING.BAOZI] 		= 0,			
	}
	tRoomData.tBetting.tRobot = 
	{
		[BETTING.LONG] 			= 0,
		[BETTING.HU] 			= 0,
		[BETTING.LONG_JINHUA] 	= 0,
		[BETTING.HU_JINHUA] 	= 0,
		[BETTING.BAOZI] 		= 0,			
	}
	tRoomData.tBetting.tType = 
	{
		[BETTING.LONG] 			= {},
		[BETTING.HU] 			= {},
		[BETTING.LONG_JINHUA] 	= {},
		[BETTING.HU_JINHUA] 	= {},
		[BETTING.BAOZI] 		= {},			
	}
	tRoomData.tCuo = {}
	tRoomData.tLongRank = nil
	tRoomData.tHuRank = nil
	tRoomData.tBaoZiRank = nil
	tRoomData.tJinHuaRank = nil
	tRoomData.nLastCheck = -1
	tRoomData.nCurrentCheck = 0
end

-- 关闭房间
function Room:CloseRoom()
	
	local tRoomData = self.tData
	CancelTimer(tRoomData.nTimerID)
	tRoomData.nTimerID = 0
	
	local tSend = Message:New()
	tSend:Push(UINT8, 0)
	tSend:Push(UINT8, 1)
	self:SendBroadcast(tSend, PROTOCOL.LEAVE_ROOM)
	
	for k,v in pairs(self.tPlayer) do
		v.nRoomID = 0
	end
	
	self:InitRoom(true)
end

-- 房间是否已满
function Room:IsFull()
	
	local nCount = self.tData.nCount
	if nCount == nil then
		return false
	end
	
	if nCount >= self.tConfig.MaxPlayer then
		return true
	end
	return false
end

function Room:PrintRoom()
	local tRoomData = self.tData
	print("--------------- Room Info Start ---------------")
	print("RoomID:", tRoomData.nRoomID, "RoomType:", tRoomData.nRoomType)
	print("State:", tRoomData.nState, "TimerID:", tRoomData.nTimerID, "Open:", tRoomData.nOpen)
	print("CurrentCheck:", tRoomData.nCurrentCheck, "nLastCheck:", tRoomData.nLastCheck, "Step:", self.nStep)
	print("Player:", tRoomData.nCount - tRoomData.nRobotCount, "Robot:", tRoomData.nRobotCount, "Games:", tRoomData.nGames, "MaxGames:", tRoomData.nMaxGames)
--	local n = 0
--	for k,v in pairs(self.tPlayer) do
--		n = n + 1
--		print("Player:", n, k, v.strName, v.isRobot, v.nGold, v.nRMB, v.nRoomCard, v.nRoomID, v.nSocketID)
--	end
	
--	PrintTable(tRoomData.tCuo, "tRoomData.tCuo")
--	PrintTable(tRoomData.tBetting.tPersonal, "tRoomData.tBetting.tPersonal")
--	PrintTable(tRoomData.tBetting.tType, "tRoomData.tBetting.tType")
--	PrintTable(tRoomData.tBetting.tTotal, "tRoomData.tBetting.tTotal")
--	PrintTable(tRoomData.tBetting.tRobot, "tRoomData.tBetting.tRobot")
	print("--------------- Room Info End --------------- ")
end

function Room:SetRoomState(nState, nNextTime)
	
	local nTime = nNextTime or PublicConfig.ROOM_TIME[nState]
	
	--print("=========== SetRoomState:", GetTimeToString(), self.tData.nRoomID, self.tData.nState, nState, nTime)
	
	self.tData.nState = nState	
	self.tData.nExpireTime = GetSystemTimeToMillisecond() + nTime * 1000
	return nTime
end


-- 检查房间流程是否正确执行
function Room:CheckProcessIsCorrect(isCheck)
	local tRoomData = self.tData
	if isCheck == nil then
		tRoomData.nCurrentCheck = tRoomData.nCurrentCheck + 1
	else
		if tRoomData.nLastCheck ~= tRoomData.nCurrentCheck then
			tRoomData.nLastCheck = tRoomData.nCurrentCheck
		else
			local tBetting = {}
			for k,v in pairs(tRoomData.tBetting.tPersonal) do
				if tBetting[k] == nil then
					tBetting[k] = 0
				end		
				if v[BETTING.LONG] ~= nil then
					tBetting[k] = tBetting[k] + v[BETTING.LONG]
				end
				if v[BETTING.HU] ~= nil then
					tBetting[k] = tBetting[k] + v[BETTING.HU]
				end
				if v[BETTING.LONG_JINHUA] ~= nil then
					tBetting[k] = tBetting[k] + v[BETTING.LONG_JINHUA]
				end
				if v[BETTING.HU_JINHUA] ~= nil then
					tBetting[k] = tBetting[k] + v[BETTING.HU_JINHUA]
				end
				if v[BETTING.BAOZI] ~= nil then					
					tBetting[k] = tBetting[k] + v[BETTING.BAOZI]
				end
			end
			
			for k,v in pairs(tBetting) do
				local tAccount = AccountMgr:GetAccountByID(k)
				tAccount:AddGold(v, OPERATE.ERROR_RETURN, tRoomData.nRoomID)
			end
			
			tRoomData.tBanker = nil
			tRoomData.tTopHu = nil
			tRoomData.tTopLong = nil
			local strData = Serialize(tRoomData)
			LogError{"RoomID:%d Process Is Error, Current:%d, RoomData:%s", tRoomData.nRoomID, tRoomData.nCurrentCheck, strData}
			
			CancelTimer(tRoomData.nTimerID)
			tRoomData.nTimerID = 0
			self:InitRoom(true)	
		end
	end
end

-- 添加玩家
function Room:AddPlayer(tAccount)
	
	local nAccountID = tAccount.nAccountID
	local nSocketID = tAccount.nSocketID
	local tRoomData = self.tData
	
	tAccount.nRoomID = tRoomData.nRoomID
	
	self.tPlayer[nAccountID] = tAccount	
	if tRoomData.nCount < 0 then
		tRoomData.nCount = 0
	end
	tRoomData.nCount = tRoomData.nCount + 1	
    
    if tAccount.isRobot == true then
        if tRoomData.nRobotCount < 0 then
            tRoomData.nRobotCount = 0
        end
        tRoomData.nRobotCount = tRoomData.nRobotCount + 1
    end
	
    local tExclude = {nRobot = true}
	local tSend = Message:New()
	tSend:Push(UINT16, tRoomData.nCount)
	self:SendBroadcast(tSend, PROTOCOL.SET_ROOM_PLAYER, tExclude)
end

-- 删除玩家
function Room:RemovePlayer(tAccount)
	
	local nAccountID = tAccount.nAccountID
	local nSocketID = tAccount.nSocketID
	local tRoomData = self.tData
	
	tAccount.nRoomID = 0
	
	self.tPlayer[nAccountID] = nil	
	tRoomData.nCount = tRoomData.nCount - 1	
	if tRoomData.nCount < 0 then
		tRoomData.nCount = 0
	end
	
    if tAccount.isRobot == true then
        tRoomData.nRobotCount = tRoomData.nRobotCount - 1
        if tRoomData.nRobotCount < 0 then
            tRoomData.nRobotCount = 0
        end
    end
    
    local tExclude = {nRobot = true}
	local tSend = Message:New()
	tSend:Push(UINT16, tRoomData.nCount)
	self:SendBroadcast(tSend, PROTOCOL.SET_ROOM_PLAYER, tExclude)
end

-- 获取牌数据和牌型
function Room:CardToString(nIdentity)
	
	local tCard = nil
	local strText = nil
	if type(nIdentity) == "table" then
		strText = "Card: %s%s,%s%s,%s%s"
		tCard = nIdentity
	else
		local tRoomData = self.tData
		tCard = tRoomData[nIdentity]
		if nIdentity == IDENTITY.LONG then
			strText = "龙: %s%s,%s%s,%s%s"
		elseif nIdentity == IDENTITY.HU then
			strText = "虎: %s%s,%s%s,%s%s"
		end		
	end
	strText = string.format(strText, COLOR_STRING[tCard[1][1]],POINT_STRING[tCard[1][2]],COLOR_STRING[tCard[2][1]],POINT_STRING[tCard[2][2]],COLOR_STRING[tCard[3][1]],POINT_STRING[tCard[3][2]])
	return strText
end



local function _CompBetting(tA, tB)
	if tA[2] > tB[2] then
		return true
	elseif tA[2] == tB[2] then
		if tA[3] < tB[3] then
			return true
		else
			return false
		end
	else
		return false
	end
end

local function _CompCard(tA, tB)
	if tA[2] > tB[2] then
		return true
	else
		return false
	end
end


-- 计算牌型和排序
local function _CalcCartTypeAndSort(tCard)
	
	table.sort(tCard, _CompCard)
	
	local tOne = tCard[1]
	local tTwo = tCard[2]
	local tThree = tCard[3]
	
	-- 豹子
	if tOne[2] == tTwo[2] and tTwo[2] == tThree[2] then
		return BRAND_TYPE.BAOZI, tCard
	elseif tOne[1] == tTwo[1] and tTwo[1] == tThree[1] then	
		-- 顺金
		if tOne[2] == (tTwo[2] + 1) and tTwo[2] == (tThree[2] + 1) then
			return BRAND_TYPE.SHUNJIN, tCard
		-- 金花
		else
			return BRAND_TYPE.JINHUA, tCard
		end
	-- 对子
	elseif tOne[2] == tTwo[2] then
		return BRAND_TYPE.DUIZI, tCard
	-- 对子
	elseif tTwo[2] == tThree[2] then
		local tTemp = tCard[1]
		tCard[1] = tCard[3]
		tCard[3] = tTemp
		return BRAND_TYPE.DUIZI, tCard
	-- 对子
	elseif tOne[2] == tThree[2] then
		local tTemp = tCard[2]
		tCard[2] = tCard[3]
		tCard[3] = tTemp
		return BRAND_TYPE.DUIZI, tCard
	else
		-- 顺子
		if tOne[2] == (tTwo[2] + 1) and tTwo[2] == (tThree[2] + 1) then
			return BRAND_TYPE.SHUNZI, tCard
		-- 散牌
		else
			return BRAND_TYPE.SANPAI, tCard
		end
	end
end

-- 龙和虎比较
local function _CompareResults(nOneType, tOneCard, nTwoType, tTwoCard)
	-- 比较方输
	if nOneType > nTwoType then
		return RESULT.FU, nTwoType
	-- 比较方赢
	elseif nOneType < nTwoType then
		return RESULT.SHENG, nTwoType
	-- 牌型一样, 比牌点数
	else
		-- 豹子, 顺金, 顺子都只比第一张牌大小
		if nOneType == BRAND_TYPE.BAOZI or nOneType == BRAND_TYPE.SHUNJIN or nOneType == BRAND_TYPE.SHUNZI then
			-- 比较方输
			if tOneCard[1][2] > tTwoCard[1][2] then
				return RESULT.FU, nTwoType
			-- 比较方赢
			elseif tOneCard[1][2] < tTwoCard[1][2] then
				return RESULT.SHENG, nTwoType
			-- 平局
			else
				return RESULT.HE, nTwoType
			end
		-- 金花, 散牌先比最大的, 再比中间的, 最后比最小的
		elseif nOneType == BRAND_TYPE.JINHUA or nOneType == BRAND_TYPE.SANPAI then
			
			-- 比较方输
			if tOneCard[1][2] > tTwoCard[1][2] then
				return RESULT.FU, nTwoType
			-- 比较方赢
			elseif tOneCard[1][2] < tTwoCard[1][2] then
				return RESULT.SHENG, nTwoType
			-- 相同, 比中间
			else
				-- 比较方输
				if tOneCard[2][2] > tTwoCard[2][2] then
					return RESULT.FU, nTwoType
				-- 比较方赢
				elseif tOneCard[2][2] < tTwoCard[2][2] then
					return RESULT.SHENG, nTwoType
				-- 相同, 比第一张
				else
					
					-- 比较方输
					if tOneCard[3][2] > tTwoCard[3][2] then
						return RESULT.FU, nTwoType
					-- 比较方赢
					elseif tOneCard[3][2] < tTwoCard[3][2] then
						return RESULT.SHENG, nTwoType
					-- 平局
					else
						return RESULT.HE, nTwoType
					end
				end
			end
			
		-- 对子先比对子, 再比最后一张
		elseif nOneType == BRAND_TYPE.DUIZI then
			-- 比较方输
			if tOneCard[1][2] > tTwoCard[1][2] then
				return RESULT.FU, nTwoType
			-- 比较方赢
			elseif tOneCard[1][2] < tTwoCard[1][2] then
				return RESULT.SHENG, nTwoType
			-- 相同, 比最后一张
			else				
				-- 比较方输
				if tOneCard[3][2] > tTwoCard[3][2] then
					return RESULT.FU, nTwoType
				-- 比较方赢
				elseif tOneCard[3][2] < tTwoCard[3][2] then
					return RESULT.SHENG, nTwoType
				-- 平局
				else
					return RESULT.HE, nTwoType
				end
			end
		end	
	end
	return RESULT.FU, nTwoType
end


local function _TwoCardsCompare(tOneCard, tTwoCard)
	local nOneType, tOne = _CalcCartTypeAndSort(tOneCard)
	local nTwoType, tTwo = _CalcCartTypeAndSort(tTwoCard)

	local nResults = _CompareResults(nOneType, tOne, nTwoType, tTwo)
	if nResults == RESULT.SHENG then
		return false, tTwo, tOne
	elseif nResults == RESULT.FU then
		return false, tOne, tTwo
	else
		return true, tOne, tTwo
	end
end


-- 判断龙虎的牌是否有重复的
local function _LongHuCardIsRepeat(tLongCard, tHuCard)
	for k,v in ipairs(tLongCard) do
		for k1,v1 in ipairs(tHuCard) do
			if v[1] == v1[1] and v[2] == v1[2] then
				return true
			end
		end
	end
	return false
end

-- 随机发牌
local function _FiringArray()
	local nIndex = math.random(CardConfig.nMaxLen)
	local tNode = CardConfig[nIndex]
	return tNode.tCard, tNode.nGroup, tNode.nType
end

-- 随机概率发牌
local function _FiringProb(nProb)
	local nL = 1
	local nR = CardConfig.nMaxLen	
	local Config = CardConfig
	local nRandom = math.random(nProb)
	while nL <= nR do
		local nM = math.modf((nL + nR) / 2)
		local tNode = Config[nM]
		if nRandom >= tNode.nStart and  nRandom <= tNode.nEnd then
			return tNode.tCard, tNode.nGroup, tNode.nType
		elseif nRandom < tNode.nStart then
			nR = nM - 1
		else
			nL = nM + 1
		end
	end
	return nil, nil, nil
end


-- 随机和牌, 根据和牌分组
local function _FiringGroup(nGroup)	
	local tGroup = HeCardConfig[nGroup]
	local nLen = #tGroup
	local nIndex = math.random(nLen)
	return tGroup[nIndex]
end

-- 根据配置概率随机
function Room:FiringToConfigProbability()

	local tRoomData = self.tData	
	local nRandom = math.random(10000)
	local tOneCard, nOneGroup, nOneType = nil
	local tTwoCard, nTwoGroup, nTwoType = nil
	local nGroup = nil	
	if nRandom <= PublicConfig.HE_PROBABILITY then
		tOneCard, nGroup = _FiringArray()
		while nGroup <= 0 do
			tOneCard, nGroup = _FiringArray()
		end
		
		tTwoCard = _FiringGroup(nGroup)
		while _LongHuCardIsRepeat(tOneCard, tTwoCard) == true do
			tTwoCard = _FiringGroup(nGroup)
		end		
	else
		tOneCard, nOneGroup, nOneType = _FiringProb(CardConfig.nMaxProb)
		tTwoCard, nTwoGroup, nTwoType = _FiringProb(CardConfig.nMaxProb)
		while _LongHuCardIsRepeat(tOneCard, tTwoCard) == true --[[or ((nOneType == BRAND_TYPE.DUIZI or nOneType == BRAND_TYPE.SHUNJIN) and nOneType == nTwoType)--]] do
			tOneCard, nOneGroup, nOneType = _FiringProb(CardConfig.nMaxProb)
			tTwoCard, nTwoGroup, nTwoType = _FiringProb(CardConfig.nMaxProb)			
		end
	end
	
	table.random(tOneCard)
	table.random(tTwoCard)
	
	if (tRoomData.nGames % 2) == 1 then
		tRoomData[IDENTITY.LONG] = tOneCard
		tRoomData[IDENTITY.HU] = tTwoCard
	else
		tRoomData[IDENTITY.LONG] = tTwoCard
		tRoomData[IDENTITY.HU] = tOneCard
	end
end

-- 存随机发牌
function Room:FiringRandom()
	
	local tCard = self.tCard
	local tRoomData = self.tData
	
	table.random(tCard)
	local tLongCard = {tCard[1], tCard[3], tCard[5]}
	local tHuCard = {tCard[2], tCard[4], tCard[6]}
	tRoomData[IDENTITY.LONG] = tLongCard
	tRoomData[IDENTITY.HU] = tHuCard
end

-- 根据结果发牌 吃大赔小
function Room:FiringToEatBigPaySmall()
	
	local tCard = self.tCard
	table.random(tCard)
	
	local tRoomData = self.tData
	local tTotal = tRoomData.tBetting.tTotal
	if tTotal[BETTING.LONG] == tTotal[BETTING.HU] then
		tRoomData[IDENTITY.LONG] = {tCard[1], tCard[3], tCard[5]}
		tRoomData[IDENTITY.HU] = {tCard[2], tCard[4], tCard[6]}
	else
		local tOneCard = {tCard[1], tCard[3], tCard[5]}
		local tTwoCard = {tCard[2], tCard[4], tCard[6]}
		local isRandom = false
		isRandom, tOneCard, tTwoCard = _TwoCardsCompare(tOneCard, tTwoCard)
		
		if isRandom == true then
			table.random(tCard)
			tRoomData[IDENTITY.LONG] = {tCard[1], tCard[3], tCard[5]}
			tRoomData[IDENTITY.HU] = {tCard[2], tCard[4], tCard[6]}
		else
			if tTotal[BETTING.LONG] > tTotal[BETTING.HU] then
				tRoomData[IDENTITY.LONG] = tTwoCard
				tRoomData[IDENTITY.HU] = tOneCard
			else
				tRoomData[IDENTITY.LONG] = tOneCard
				tRoomData[IDENTITY.HU] = tTwoCard
			end
		end
	end
end

-- 发配置的测试牌型
local nTestIndex = 0
function Room:FiringToTest()
	
	nTestIndex = nTestIndex + 1	
	if TestConfig[nTestIndex] == nil then
		nTestIndex = 1
	end
	
	local tRoomData = self.tData
	tRoomData[IDENTITY.LONG] = TestConfig[nTestIndex].LongCard
	tRoomData[IDENTITY.HU] = TestConfig[nTestIndex].HuCard
end


--更新下注排名
function Room:UpdateBettingRank(isEndBetting, isRank, tSend)
	
	local tRoomData = self.tData
	local tLongRank = {}
	local tHuRank = {}
	
	if isEndBetting == false and isRank == true then		
		local nBettingLong = 0
		local nBettingHu = 0
		for k,v in pairs(tRoomData.tBetting.tPersonal) do			
			
			nBettingLong = v[BETTING.LONG] or 0
			nBettingHu = v[BETTING.HU] or 0
			
			if nBettingLong > 0 then
				table.insert(tLongRank, {k, nBettingLong, v.nLastBettingTime})
			elseif nBettingHu > 0 then
				table.insert(tHuRank, {k, nBettingHu, v.nLastBettingTime})
			end
		end
		
		table.sort(tLongRank, _CompBetting)
		table.sort(tHuRank, _CompBetting)	
		
		tRoomData.tLongRank = tLongRank
		tRoomData.tHuRank = tHuRank
	end

	if isEndBetting == false then
		
		local tPushLong = {}
		for i = 1, 3 do
			if tRoomData.tLongRank[i] ~= nil then
				local nID = tRoomData.tLongRank[i][1]
				local nBetting = tRoomData.tLongRank[i][2]
				local tAccount = AccountMgr:GetAccountByID(nID)
				table.insert(tPushLong, {{UINT32, nID}, {STRING, tAccount.strName}, {INT64, nBetting}, {UINT8, tAccount.nHeadID}})
			end
		end
		local tPushHu = {}
		for i = 1, 3 do
			if tRoomData.tHuRank[i] ~= nil then
				local nID = tRoomData.tHuRank[i][1]
				local nBetting = tRoomData.tHuRank[i][2]
				local tAccount = AccountMgr:GetAccountByID(nID)
				table.insert(tPushHu, {{UINT32, nID}, {STRING, tAccount.strName}, {INT64, nBetting}, {UINT8, tAccount.nHeadID}})
			end
		end
		
		tSend:Push(TABLE, tPushLong)
		tSend:Push(TABLE, tPushHu)
	else
		
		local tBaoZiRank = {}
		local tJinHuaRank = {}
		for k,v in pairs(tRoomData.tBetting.tPersonal) do	
			if v[BETTING.LONG] ~= nil then
				table.insert(tLongRank, {k, v[BETTING.LONG], v.nLastBettingTime})
			end
			
			if v[BETTING.HU] ~= nil then
				table.insert(tHuRank, {k, v[BETTING.HU], v.nLastBettingTime})
			end
			
			if v[BETTING.LONG_JINHUA] ~= nil then
				table.insert(tJinHuaRank, {k, v[BETTING.LONG_JINHUA], v.nLastBettingTime, STATISTICS_RESULT.LONG_JINHUA})
			end
			
			if v[BETTING.HU_JINHUA] ~= nil then
				table.insert(tJinHuaRank, {k, v[BETTING.HU_JINHUA], v.nLastBettingTime, STATISTICS_RESULT.HU_JINHUA})
			end
			
			if v[BETTING.BAOZI] ~= nil then					
				table.insert(tBaoZiRank, {k, v[BETTING.BAOZI], v.nLastBettingTime, STATISTICS_RESULT.BAOZI})
			end
		end
		
		table.sort(tLongRank, _CompBetting)
		table.sort(tHuRank, _CompBetting)	
		table.sort(tBaoZiRank, _CompBetting)	
		table.sort(tJinHuaRank, _CompBetting)	
		
		tRoomData.tLongRank = tLongRank
		tRoomData.tHuRank = tHuRank
		tRoomData.tBaoZiRank = tBaoZiRank
		tRoomData.tJinHuaRank = tJinHuaRank
		
		if tRoomData.tLongRank[1] ~= nil then
			local tAccount = AccountMgr:GetAccountByID(tRoomData.tLongRank[1][1])
			tRoomData.tTopLong = tAccount
		end		
			
		if tRoomData.tHuRank[1] ~= nil then
			local tAccount = AccountMgr:GetAccountByID(tRoomData.tHuRank[1][1])
			tRoomData.tTopHu = tAccount
		end		
		
		if tRoomData.tTopLong ~= nil then		
			tSend:Push(UINT32, tRoomData.tTopLong.nAccountID)
			tSend:Push(STRING, tRoomData.tTopLong.strName)
			tSend:Push(UINT8, tRoomData.tTopLong.nHeadID)
		else			
			tSend:Push(UINT32, 0)
			tSend:Push(STRING, "")
			tSend:Push(UINT8, 0)
		end
		if tRoomData.tTopHu ~= nil then		
			tSend:Push(UINT32, tRoomData.tTopHu.nAccountID)
			tSend:Push(STRING, tRoomData.tTopHu.strName)
			tSend:Push(UINT8, tRoomData.tTopHu.nHeadID)
		else			
			tSend:Push(UINT32, 0)
			tSend:Push(STRING, "")
			tSend:Push(UINT8, 0)
		end
	end
end

-- 计算比牌结果
function Room:CalcResults()
	
	local tRoomData = self.tData
	local nLongType, tLongCard = _CalcCartTypeAndSort(tRoomData[IDENTITY.LONG])
	local nHuType, tHuCard = _CalcCartTypeAndSort(tRoomData[IDENTITY.HU])
	
	local nHuResults = _CompareResults(nLongType, tLongCard, nHuType, tHuCard)
	return nHuResults, nLongType, nHuType
end

-- 检测是否上庄
function Room:CheckUpBanker()
	local isUpBanker = false
	local tRoomData = self.tData
	local nUpLen = #tRoomData.tUpBanker
	local nBaoBanker = 0
	
	local nRoomType = tRoomData.nRoomType
	local nHaveGold = 0
	if tRoomData.tBanker ~= nil then
		if nRoomType == ROOM_TYPE.FREE then
			nHaveGold = tRoomData.tBanker.nFreeGold
		else
			nHaveGold = tRoomData.tBanker.nGold
		end
	end
	
	if tRoomData.tBanker == nil then
		-- 上庄
		if nUpLen > 0 then
			isUpBanker = true
		end
	else		
		-- 庄家已不在房间内
		if self.tPlayer[tRoomData.tBanker.nAccountID] == nil then
			
			isUpBanker = true	
			
		-- 庄家金币数量低于维持最低金币数量, 强制下庄		
		elseif nHaveGold < self.tConfig.DownBankerGold then
			
			isUpBanker = true	
			nBaoBanker = 1	
			
		-- 庄家上庄局数已达上限, 强制下庄
		elseif tRoomData.tUpBanker.nBankerGames >= PublicConfig.MAX_UP_BANKER_GAMES then
			
			isUpBanker = true	
			
		-- 庄家申请下庄, 强制下庄
		elseif tRoomData.tUpBanker.isSetDownBanker == 1 then
			
			isUpBanker = true
			
		end
	end
	
	if isUpBanker == true then
		
		tRoomData.tBanker = nil	
		tRoomData.tUpBanker.nBankerGames = 0	
		tRoomData.tUpBanker.isSetDownBanker = 0
		
		local nRemoveIndex = 1
		for k,v in ipairs(tRoomData.tUpBanker) do	
			local nUperHaveGold = 0			
			if nRoomType == ROOM_TYPE.FREE then
				nUperHaveGold = v.nFreeGold
			else
				nUperHaveGold = v.nGold
			end
			
			if nUperHaveGold < self.tConfig.UpBankerGold then
				nRemoveIndex = k
			else
				tRoomData.tBanker = v
				nRemoveIndex = k
				break
			end
		end
		
		if nUpLen > 0 then
			for i = 1, nRemoveIndex do
				table.remove(tRoomData.tUpBanker, 1)
			end		
		end
		
		-- 广播更新庄家消息
		local tUpdateBanker = Message:New()		
		if tRoomData.tBanker ~= nil then
			tUpdateBanker:Push(UINT32, tRoomData.tBanker.nAccountID)
			tUpdateBanker:Push(STRING, tRoomData.tBanker.strName)
			if nRoomType == ROOM_TYPE.FREE then
				tUpdateBanker:Push(INT64, tRoomData.tBanker.nFreeGold)
			else
				tUpdateBanker:Push(INT64, tRoomData.tBanker.nGold)
			end
			tUpdateBanker:Push(UINT8, PublicConfig.MAX_UP_BANKER_GAMES - tRoomData.tUpBanker.nBankerGames)
			tUpdateBanker:Push(UINT8, tRoomData.tBanker.nHeadID)
			tUpdateBanker:Push(UINT8, nBaoBanker)
		else
			tUpdateBanker:Push(UINT32, 1)
			tUpdateBanker:Push(STRING, PublicConfig.BANKER_NAME)
			tUpdateBanker:Push(INT64, PublicConfig.BANKER_GOLD)
			tUpdateBanker:Push(UINT8, 0)
			tUpdateBanker:Push(UINT8, PublicConfig.SYSTEM_BANKER_HEAD_ID)
			tUpdateBanker:Push(UINT8, nBaoBanker)
		end
		self:SendBroadcast(tUpdateBanker, PROTOCOL.UPDATE_BANKER)
	else		
		self:UpdateRankerGold()	
        
		for i = #tRoomData.tUpBanker, 1, -1  do
            local tAccount = tRoomData.tUpBanker[i]
			if self.tPlayer[tAccount.nAccountID] == nil then
				table.remove(tRoomData.tUpBanker, i)			
			end
		end
	end
end

function Room:UpdateRankerGold()
	local tRoomData = self.tData
	if tRoomData.tBanker ~= nil then
		local tUpdateBanker = Message:New()	
		if tRoomData.nRoomType == ROOM_TYPE.FREE then
			tUpdateBanker:Push(INT64, tRoomData.tBanker.nFreeGold)
		else
			tUpdateBanker:Push(INT64, tRoomData.tBanker.nGold)
		end
		tUpdateBanker:Push(UINT8, PublicConfig.MAX_UP_BANKER_GAMES - tRoomData.tUpBanker.nBankerGames)			
		self:SendBroadcast(tUpdateBanker, PROTOCOL.UPDATE_BANKER_GOLD)
	end	
end

-- 填充统计数据
function Room:FillStatisticsData(isGetAll, tSend)
	
	local tPush = {}
	local tStatistics = self.tStatistics
	if isGetAll == nil then		
		local v = tStatistics.tResult[#tStatistics.tResult]
		tSend:Push(UINT32, self.tData.nRoomID)
		tSend:Push(UINT8, v)		
		tSend:Push(UINT8, tStatistics.nLongWin)
		tSend:Push(UINT8, tStatistics.nHuWin)
		tSend:Push(UINT8, tStatistics.nHe)
		tSend:Push(UINT8, tStatistics.nLongJinHua)
		tSend:Push(UINT8, tStatistics.nHuJinHua)
		tSend:Push(UINT8, tStatistics.nBaoZi)
		tSend:Push(UINT8, self.tData.nGames)
	else
		for k,v in ipairs(tStatistics.tResult) do
			table.insert(tPush, {{UINT8, v}})
		end
		
		tSend:Push(UINT32, self.tData.nRoomID)
		tSend:Push(TABLE, tPush)
		tSend:Push(UINT8, tStatistics.nLongWin)
		tSend:Push(UINT8, tStatistics.nHuWin)
		tSend:Push(UINT8, tStatistics.nHe)
		tSend:Push(UINT8, tStatistics.nLongJinHua)
		tSend:Push(UINT8, tStatistics.nHuJinHua)
		tSend:Push(UINT8, tStatistics.nBaoZi)
		tSend:Push(UINT8, self.tData.nGames)
		tSend:Push(UINT8, self.tData.nMaxGames)
		tSend:Push(UINT16, self.tData.nCount)
	end
	
end


-- 发送游戏数据
function Room:SendGameData(nAccountID, nSocketID)
	
	local tRoomData = self.tData	
	local nRoomState = tRoomData.nState
	local nSurplusTime = tRoomData.nExpireTime - GetSystemTimeToMillisecond()
	
--	-- TODO 测试用
--	if tRoomData.nTimerID == 0 then
--		nSurplusTime = tRoomData.nExpireTime
--	end
	if nSurplusTime < 0 then
		nSurplusTime = 0
	end
	
	local tBettingTotal = {}
	for k,v in pairs(tRoomData.tBetting.tTotal) do
		if v > 0 then
			table.insert(tBettingTotal, {{UINT8, k}, {INT64, v}})
		end
	end

	local tBettingPersonal = {}
	local tBetting = tRoomData.tBetting.tPersonal[nAccountID]
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
	
	local tBettingType = {}
	local tType = tRoomData.tBetting.tType
	for k,v in pairs(tType) do
		for k1,v1 in pairs(v) do
			table.insert(tBettingType, {{UINT8, k}, {UINT32, k1}, {UINT32, v1}})
		end
	end
	
	local tRoomInfo = Message:New()
	tRoomInfo:Push(UINT32, tRoomData.nRoomID)
	tRoomInfo:Push(UINT8, self.tConfig.TemplateID)
	tRoomInfo:Push(UINT32, tRoomData.nRoomOwnerID)
	tRoomInfo:Push(UINT8, tRoomData.nMaxGames)
	tRoomInfo:Push(UINT8, tRoomData.nGames)
	tRoomInfo:Push(UINT8, nRoomState)
	tRoomInfo:Push(UINT32, nSurplusTime)	
	tRoomInfo:Push(TABLE, tBettingPersonal)	
	tRoomInfo:Push(TABLE, tBettingTotal)	
	tRoomInfo:Push(TABLE, tBettingType)	
	
	local tUpdateBanker = Message:New()		
	if tRoomData.tBanker ~= nil then
		tRoomInfo:Push(UINT32, tRoomData.tBanker.nAccountID)
		tRoomInfo:Push(STRING, tRoomData.tBanker.strName)
		tRoomInfo:Push(INT64, tRoomData.tBanker.nGold)
		tRoomInfo:Push(UINT8, PublicConfig.MAX_UP_BANKER_GAMES - tRoomData.tUpBanker.nBankerGames)
		tRoomInfo:Push(UINT8, tRoomData.tBanker.nHeadID) 
		tRoomInfo:Push(UINT8, 0) 
	else
		tRoomInfo:Push(UINT32, 1)
		tRoomInfo:Push(STRING, PublicConfig.BANKER_NAME)
		tRoomInfo:Push(INT64, PublicConfig.BANKER_GOLD)
		tRoomInfo:Push(UINT8, 0)
		tRoomInfo:Push(UINT8, PublicConfig.SYSTEM_BANKER_HEAD_ID)
		tRoomInfo:Push(UINT8, 0)
	end
	
	if nRoomState >= ROOM_STATE.FAPAI then		
		tRoomInfo:Push(UINT16, 6)
		tRoomInfo:Push(UINT8, tRoomData[IDENTITY.LONG][1][1])
		tRoomInfo:Push(UINT8, tRoomData[IDENTITY.LONG][1][2])
		tRoomInfo:Push(UINT8, tRoomData[IDENTITY.LONG][2][1])
		tRoomInfo:Push(UINT8, tRoomData[IDENTITY.LONG][2][2])
		tRoomInfo:Push(UINT8, tRoomData[IDENTITY.LONG][3][1])
		tRoomInfo:Push(UINT8, tRoomData[IDENTITY.LONG][3][2])
		tRoomInfo:Push(UINT8, tRoomData[IDENTITY.HU][1][1])
		tRoomInfo:Push(UINT8, tRoomData[IDENTITY.HU][1][2])
		tRoomInfo:Push(UINT8, tRoomData[IDENTITY.HU][2][1])
		tRoomInfo:Push(UINT8, tRoomData[IDENTITY.HU][2][2])
		tRoomInfo:Push(UINT8, tRoomData[IDENTITY.HU][3][1])
		tRoomInfo:Push(UINT8, tRoomData[IDENTITY.HU][3][2])	
	else		
		tRoomInfo:Push(UINT16, 0)
	end
	
	tRoomInfo:Push(UINT8, tRoomData.tCuo[IDENTITY.LONG] or 0)
	tRoomInfo:Push(UINT8, tRoomData.tCuo[IDENTITY.HU] or 0)
	
	if nRoomState == ROOM_STATE.JIESUAN then	
		local tResult = self.tStatistics.tResult
		local nLen = #tResult
		if nLen > 0 then
			local nResults = tResult[nLen]
			tRoomInfo:Push(UINT8, nResults)
		else
			tRoomInfo:Push(UINT8, 0)
		end
	else
		tRoomInfo:Push(UINT8, 0)
	end
	
	self:UpdateBettingRank(true, false, tRoomInfo)
	net:SendToClient(tRoomInfo, PROTOCOL.GET_GAME_DATA, nSocketID)
	
	
	if nRoomState == ROOM_STATE.XIAZHU then		
		local tRank = Message:New()		
		self:UpdateBettingRank(false, false, tRank)
		net:SendToClient(tRank, PROTOCOL.UPDATE_RANK, nSocketID)
	end
end

-- 广播消息
function Room:SendBroadcast(tSend, nProtocol, tExclude)
	
	if tExclude == nil then
		for k,v in pairs(self.tPlayer) do
			net:SendToClient(tSend, nProtocol, v.nSocketID)
		end
	else
        local nExcludeID = tExclude.nID
        local isExcludeRobot = tExclude.nRobot
        
        if nExcludeID ~= nil and isExcludeRobot ~= nil then
			for k,v in pairs(self.tPlayer) do
				if k ~= nExcludeID and v.isRobot == false then
					net:SendToClient(tSend, nProtocol, v.nSocketID)
				end
			end
        elseif isExcludeRobot ~= nil then
			for k,v in pairs(self.tPlayer) do
				if v.isRobot == false then
					net:SendToClient(tSend, nProtocol, v.nSocketID)
				end
			end
        elseif nExcludeID ~= nil then
			for k,v in pairs(self.tPlayer) do
				if k ~= nExcludeID then
					net:SendToClient(tSend, nProtocol, v.nSocketID)
				end
			end
        else
			for k,v in pairs(self.tPlayer) do
				net:SendToClient(tSend, nProtocol, v.nSocketID)
			end
        end        
	end
end




