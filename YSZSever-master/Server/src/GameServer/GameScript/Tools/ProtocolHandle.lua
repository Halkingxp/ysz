print "ProtocolHandle.lua"


if MessageMgr == nil then
	MessageMgr = {}
end

function MessageMgr:RegCallbackFun(nOpcode, fCallbackFun)
	--if MessageMgr[nOpcode] == nil then
		MessageMgr[nOpcode] = fCallbackFun
	--end
end

function lua_MsgHandle(nOpcode, cPacket, nSocketID)
	local fCallbackFun = MessageMgr[nOpcode]
	if fCallbackFun == nil then
		return 1
	else
		fCallbackFun(cPacket, nSocketID)
		return 0
	end
end



