print('RankMgr.lua')
if RankMgr == nil then
	RankMgr =
	{
		bIsInit = false,
		tAllGoldRankData = {},			-- 排行榜数据集 nAccountID nYesterdayAllGold	
		tAllGoldRankKeyIsAccountID = {},		--排行榜数据集，accountID作为key，value是排名
	}
end

function RankMgr:GetAllGoldRankIndex(accountID)

	local index = RankMgr.tAllGoldRankKeyIsAccountID[accountID]
	if index == nil then
		--LogError{"can not find item by idaccountID = %d at tAllGoldRankKeyIsAccountID", accountID}
		return 0
	end
	
	if RankMgr.tAllGoldRankData[index] == nil then
		LogInfo{"can not find item by idaccountID = %d at tAllGoldRankData", accountID}
		return 0
	end
	return index
end

function RankMgr:GetAllGoldRankItemByID(accountID)

	local index = RankMgr.tAllGoldRankKeyIsAccountID[accountID]
	if index == nil then
		--LogError{'can not find item by idaccountID = %d at tAllGoldRankKeyIsAccountID', accountID}
		return nil
	end
	
	if RankMgr.tAllGoldRankData[index] == nil then
		LogInfo{'can not find item by idaccountID = %d at tAllGoldRankData', accountID}
		return nil
	end
	return RankMgr.tAllGoldRankData[index]
end

function RankMgr:InitRank()
	--print('RankMgr:InitRank is run')

	RankMgr.tAllGoldRankData = {}
	RankMgr.tAllGoldRankKeyIsAccountID = {}
	--更新排行榜数据集
	for k,v in pairs(AccountMgr.tAccountByID) do
		local tempItem = {}
		tempItem.nAccountID = v.nAccountID
		tempItem.nYesterdayAllGold = v.nYesterdayGold
		table.insert(RankMgr.tAllGoldRankData, tempItem)
	end
	table.sort(RankMgr.tAllGoldRankData, RankMgr._CompYesterdayAllGold)
	
	for k,v in ipairs(RankMgr.tAllGoldRankData) do
		RankMgr.tAllGoldRankKeyIsAccountID[v.nAccountID] = k
	end
	
	RankMgr.bIsInit = true;
end

function RankMgr:UpdateRank()
	local tAccountByID = AccountMgr.tAccountByID
	RankMgr.tAllGoldRankData = {}
	RankMgr.tAllGoldRankKeyIsAccountID = {}
	--更新排行榜数据集
	for k,v in pairs(tAccountByID) do
		local tempItem = {}
		tempItem.nAccountID = v.nAccountID
		tempItem.nYesterdayAllGold = v.nGold
		v.nYesterdayGold = v.nGold
		table.insert(RankMgr.tAllGoldRankData, tempItem)
	end
	table.sort(RankMgr.tAllGoldRankData, RankMgr._CompYesterdayAllGold)
	
	for k,v in ipairs(RankMgr.tAllGoldRankData) do
		RankMgr.tAllGoldRankKeyIsAccountID[v.nAccountID] = k
	end
	
end

function RankMgr:SendRankToClient(nAccountID, nSocketID, rankType)
	if RankMgr.bIsInit == false then
		LogError{"RangMgr is not Init"}
		return
	end
	
	local nPushCount = 0
	local tPush = {}
	for k,v in ipairs(RankMgr.tAllGoldRankData) do
		if nPushCount >= 20 then
			break
		end
		
		local tAccount = AccountMgr:GetAccountByID(v.nAccountID)
		if tAccount ~= nil and v.nYesterdayAllGold > 0 then
			table.insert(tPush, {{UINT8, tAccount.nHeadID}, {STRING, tAccount.strName}, {INT64, v.nYesterdayAllGold}, {UINT32, tAccount.nAccountID}, {UINT8, tAccount.nVIPLv}})
			nPushCount = nPushCount + 1
			--print(nPushCount, tAccount.nHeadID, tAccount.strName, v.nYesterdayAllGold/10000, tAccount.nAccountID, tAccount.nVIPLv)
		end
	end
	
	local tSend = Message:New()
	tSend:Push(UINT8, 1)
	tSend:Push(TABLE, tPush)
	net:SendToClient(tSend, PROTOCOL.CS_ALL_RANK, nSocketID)
end

function RankMgr._CompYesterdayAllGold(tA, tB)
	if tA.nYesterdayAllGold > tB.nYesterdayAllGold then
		return true
	else
		return false
	end
end


function HandleRequestRanks(cPacket, nSocketID)
	--print('request ranks')
	local tParseData =
    {
		UINT32,		-- 自己的帐号ID
		UINT8,      -- 排行榜类型	1为资产排行榜 2为昨日赢取排行榜
    }
	local tData = c_ParserPacket(tParseData, cPacket)
	local nAccountID = tData[1]
	local nType		 = tData[2]	
	RankMgr:SendRankToClient(nAccountID, nSocketID, nType)
end