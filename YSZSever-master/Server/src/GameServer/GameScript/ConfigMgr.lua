print "ConfigMgr.lua"



dofile(g_strPatch.."Config/room.lua")
dofile(g_strPatch.."Config/vip.lua")
dofile(g_strPatch.."Config/test.lua")
dofile(g_strPatch.."Config/card.lua")
dofile(g_strPatch.."Config/store.lua")
dofile(g_strPatch.."Config/public.lua")
HeCardConfig = {}



-- 检查配置表数据有效性
local function _CheckData()
	local nErrorCount = 0
	
	if RoomMgr ~= nil then
		for k,v in pairs(RoomMgr.tRoomByID) do
			local tConfig = RoomConfig[v.tConfig.TemplateID]
			v.tConfig = tConfig
		end
	end
	
--	table.random(CardConfig)
--	table.random(CardConfig)
	
	local tNewCard = {}
	local nStart = 0
	local nEnd = 0
	for k,v in ipairs(CardConfig) do
		nStart = nEnd + 1
		nEnd = nEnd + v.Prob
		
		table.insert(tNewCard, {nStart = nStart, nEnd = nEnd, tCard = v.Card, nGroup = v.Group, nType = v.Type})
		
		if v.Group > 0 then
			if HeCardConfig[v.Group] == nil then
				HeCardConfig[v.Group] = {}
			end
			
			table.insert(HeCardConfig[v.Group], v.Card)
		end
	end
	
	CardConfig = tNewCard
	CardConfig.nMaxProb = nEnd
	CardConfig.nMaxLen = #tNewCard
	
	local nMaxVIPLv = 0
	for k,v in pairs(VipConfig) do
		if nMaxVIPLv < k then
			nMaxVIPLv = k
		end
	end
	VipConfig.nMaxVIPLv = nMaxVIPLv
end

_CheckData()


	
