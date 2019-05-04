
-- 用于测试服务器逻辑
-- 函数内组装要接收的消息和消息体
-- 在控制台输入 test 命令, 根据需求传参
function lua_TestMsg(nAccountID)
	
	-- 按照服务器解析方式组装要测试的消息体
--	local tSend = Message:New()
--	tSend:Push(UINT32, nAccountID)
--	tSend:Push(UINT8, 1)
	
	-- 注意修改协议编号
	--c_TestMsg(tSend, PROTOCOL.CG_CLAN_BATTLE_SIGN_UP, tHero.nSocketID)
	
	local tRoom = RoomMgr:GetRoom(nAccountID)
	if tRoom ~= nil then
		tRoom:PrintRoom()
	else
		print("Can not find RoomID:", nAccountID)
	end
    
    for k,v in pairs(RoomMgr.tRoomByID) do
        if v.tData.nRobotCount == nil then
            v.tData.nRobotCount = 0
            print(k, "号房间添加tData.nRobotCount字段")
        end
        
        if v.tData.tBetting.tRobot == nil then        
			v.tData.tBetting.tRobot =
			{
				[BETTING.LONG] 			= 0,
				[BETTING.HU] 			= 0,
				[BETTING.LONG_JINHUA] 	= 0,
				[BETTING.HU_JINHUA] 	= 0,
				[BETTING.BAOZI] 		= 0,
			}            
            print(k, "号房间添加tData.tBetting.tRobot字段")
        end
    end
end


-- TODO 测试充值
function TestCharge(cPacket, nSocketID)
    local tParseData =
    {
        UINT32,
		UINT8,
    }
    local tData = c_ParserPacket(tParseData, cPacket)
    local nAccountID = tData[1]
	local nID = tData[2]
	
	local tSend = Message:New()	
	local tAccount = AccountMgr:GetAccountByID(nAccountID)
	if tAccount == nil then
		tSend:Push(UINT8, 1)
		net:SendToClient(tSend, PROTOCOL.TEST_CHARGE, nSocketID)
		return
	end
	
	local tStoreConfig = StoreConfig[nID]
	if tStoreConfig == nil then
		tSend:Push(UINT8, 2)
		net:SendToClient(tSend, PROTOCOL.TEST_CHARGE, nSocketID)
		return
	end
	
	tAccount:AddCharge(tStoreConfig.Price, OPERATE.GM, 0)
	tAccount:AddRMB(tStoreConfig.AddDiamond, OPERATE.GM)
	
	tSend:Push(UINT8, 0)
	net:SendToClient(tSend, PROTOCOL.TEST_CHARGE, nSocketID)
end

--[[
function TestPause(cPacket, nSocketID)
    local tParseData =
    {
        UINT32,
		UINT8,
    }
    local tData = c_ParserPacket(tParseData, cPacket)
    local nAccountID = tData[1]
	local nType = tData[2]
	
	local tSend = Message:New()
	local tAccount = AccountMgr:GetAccountByID(nAccountID)
	if tAccount == nil then
		tSend:Push(UINT8, 1)
		net:SendToClient(tSend, PROTOCOL.TEST_PAUSE, nSocketID)
		return
	end
	
	local tRoom = RoomMgr:GetRoom(tAccount.nRoomID)
	if tRoom == nil then
		tSend:Push(UINT8, 2)
		net:SendToClient(tSend, PROTOCOL.TEST_PAUSE, nSocketID)
		return
	end
	
	local tRoomData = tRoom.tData
	if nType == 1 then
		tRoomData.nExpireTime = tRoomData.nExpireTime - GetSystemTimeToMillisecond()
		CancelTimer(tRoomData.nTimerID)
		tRoomData.nTimerID = 0
	else		
		tRoom:InitRoom(true)
		tRoom:RemovePlayer(tAccount)
		
		tSend:Push(UINT8, 0)
		tSend:Push(UINT8, nType)	-- 退出类型
		net:SendToClient(tSend, PROTOCOL.LEAVE_ROOM, nSocketID)
	end
end
--]]