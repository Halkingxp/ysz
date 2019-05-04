print "SmallHornMgr.lua"

if SmallHornMgr == nil then
    SmallHornMgr = 
	{
		tLoop = {},		--循环播放小喇叭列表
	}
end

-- 若第一参数传nil, 表示全服广播; 否则只广播房间内玩家
function SmallHornMgr:SendBroadcast(tRoom, nPriority, nRunHorseID, strString, nGold)
	
	local tSend = Message:New()
	tSend:Push(INT8, nPriority)
	tSend:Push(INT8, nRunHorseID)
	tSend:Push(STRING, strString)
	if nGold ~= nil then
		tSend:Push(INT64, nGold)
	end
	
	if tRoom ~= nil then
        local tExclude = {nRobot = true}
		tRoom:SendBroadcast(tSend, PROTOCOL.S_Add_MoveNotice, tExclude)
	else
		AccountMgr:SendBroadcast(tSend, PROTOCOL.S_Add_MoveNotice)
	end	
end

-- 每分钟更新一次
function SmallHornMgr:Update()
	
	local tLoop = SmallHornMgr.tLoop
	local nNowTime = GetSystemTimeToSecond()
	for i = #tLoop, 1, -1 do
		local tNode = tLoop[i]
		if nNowTime >= tNode.nStartTime then
			if tNode.nNextTime == nil then
				tNode.nNextTime = nNowTime + tNode.nIntervalTime
				SmallHornMgr:SendBroadcast(nil, tNode.nPriority, 255, tNode.strContent)
			elseif (nNowTime >= tNode.nNextTime) then
				tNode.nNextTime = nNowTime + tNode.nIntervalTime
				SmallHornMgr:SendBroadcast(nil, tNode.nPriority, 255, tNode.strContent)
			end
		end
		
		if nNowTime >= tNode.nDelTime then
			table.remove(tLoop, i)
		end
	end
end


function HandleSmallHorn(cPacket, nSocketID)
	local tParseData =
    {
		UINT32,		-- 帐号ID
		STRING,     -- 内容
    }
	local tData = c_ParserPacket(tParseData, cPacket)
	local nAccountID = tData[1]
	local strSmallhorn = tData[2]
	
	local tAccount = AccountMgr:GetAccountByID(nAccountID)
	local tSend = Message:New()
	if tAccount == nil then
		tSend:Push(UINT8, 1)
		net:SendToClient(tSend, PROTOCOL.CS_SmallHorn, nSocketID)
		return
	end
	
	--检查vip等级是否符合条件
	local tVIPConfig = VipConfig[tAccount.nVIPLv]
	if	tVIPConfig.Speaker == -1 then
		tSend:Push(UINT8, 3)
		net:SendToClient(tSend, PROTOCOL.CS_SmallHorn, nSocketID)
		return
	end
	
	--检查冷却时间是否足够
	local currentTime = GetSystemTimeToSecond()
	if currentTime - tAccount.nlastSendHornTime < PublicConfig.EMALL_SMALL_HORN_COOL_TIME then
		tSend:Push(UINT8, 4)
		net:SendToClient(tSend, PROTOCOL.CS_SmallHorn, nSocketID)
		return
    end 
	
	--检查金币是否足够
	if tAccount.nGold < tVIPConfig.Speaker then
		tSend:Push(UINT8, 2)
		net:SendToClient(tSend, PROTOCOL.CS_SmallHorn, nSocketID)
		return
	end
	
	tSend:Push(UINT8, 0)
	net:SendToClient(tSend, PROTOCOL.CS_SmallHorn, nSocketID)
	
	--扣钱
	tAccount:AddGold(-tVIPConfig.Speaker, OPERATE.SMALL_HORN)
	tAccount.nlastSendHornTime = currentTime--更新当前玩家的小喇叭发送时间
	
	--广播小喇叭
	SmallHornMgr:SendBroadcast(nil, 1, 255, strSmallhorn)
end