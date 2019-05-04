print "Message.lua"

if Message == nil then
    Message = {}
end

-----------------------------------------------------------------------------------------------------------
function Message:New()
    local tMsg = {}
    setmetatable(tMsg, {__index = self})
	return tMsg
end

-----------------------------------------------------------------------------------------------------------
function Message:Push(nType, Value)

	if nType == nil then
		LogError{"Make Message nType Error, Value:%s", Value}
		return
	elseif Value == nil then
		LogError{"Make Message Value Error, nType:%s", nType}
		return
	end
    table.insert(self, {nType, Value})
end
