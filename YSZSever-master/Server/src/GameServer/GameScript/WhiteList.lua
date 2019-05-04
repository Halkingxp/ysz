print("WhiteList.lua")

-- 后台白名单列表
local BACKSTAGE_WHITE_TABLE_IP =
{
	["192.168.2.83"] = true,	
	["120.77.35.48"] = true,		--01内网测试服务器
	["172.18.75.100"] = true,		--01内网测试服务器	
	["119.23.204.11"] = true,		--02外网测试服务器
	["172.18.75.101"] = true,		--02外网测试服务器	
	["103.211.167.25"] = true,		--01服-超级赢三张
	["10.16.0.158"] = true,			--01服-超级赢三张
}

-- 登录白名单列表
local LOGIN_WHITE_TABLE_IP =
{
	["192.168.2.83"] = true,	
	["171.221.254.163"] = true,             --帝濠金花01服 wifi
	["118.116.106.137"] = true,             --帝濠金花01服 有线

}

function IsWhiteBackstage(IP)
	local ret = BACKSTAGE_WHITE_TABLE_IP[IP]
	if not ret then
		return 0
	else
		return 1
	end
end


function IsWhiteLogin(IP)
	local ret = LOGIN_WHITE_TABLE_IP[IP]
	if not ret then
		return 0
	else
		return 1
	end
end