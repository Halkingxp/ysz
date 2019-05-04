
-- 用于测试服务器逻辑
-- 函数内组装要接收的消息和消息体
-- 在控制台输入 test 命令, 根据需求传参
function lua_TestMsg(nHeroID)
	
	-- 按照服务器解析方式组装要测试的消息体
--	local tSend = Message:New()
--	tSend:Push(UINT32, nHeroID)
--	tSend:Push(UINT8, 1)
	
	-- 注意修改协议编号
	--c_TestMsg(tSend, PROTOCOL.CG_CLAN_BATTLE_SIGN_UP, tHero.nSocketID)
    AccountMgr:CheckOpenServerID()
	
end

