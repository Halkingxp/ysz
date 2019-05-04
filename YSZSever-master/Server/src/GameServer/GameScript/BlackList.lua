print("BlackList.lua")

-- 邮件交易黑名单列表, key帐号ID
-- 格式 [10000001]  = true,	
-- [禁止交易帐号ID] = true,
local EMAIL_BLACK_TABLE =
{
}


function IsInEmailBlackList(nAccountID)
	local isRet = EMAIL_BLACK_TABLE[nAccountID]
	if isRet == nil then
		return 0
	else
		return 1
	end
end

