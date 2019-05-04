print "-----------load lua!-----------"

--[[
C++中定义的变量类型
enum LuaField
{
    INT8        = 1,
    INT16       = 2,
    INT32       = 3,
    UINT8       = 4,
    UINT16      = 5,
    UINT32      = 6,
    STRING      = 7,
    FLOAT       = 8,
    TABLE       = 9,
    DOUBLE      = 10,
	INT64		= 11,
};
]]--



-- C捕捉到异常后的回调函数
function Error(errmsg)
	c_Errorlog(errmsg)
end

function File_Load(strPatch)	
	g_strPatch = strPatch
	print("Config Path:" .. strPatch)
	
	-- 加载基础模块
	dofile(strPatch.."Tools/CommonFun.lua")
	dofile(strPatch.."Tools/Message.lua")
	dofile(strPatch.."Tools/ProtocolHandle.lua")		
	dofile(strPatch.."ServerConfig.lua")
	dofile(strPatch.."ConfigMgr.lua")
	dofile(strPatch.."WhiteList.lua")
	dofile(strPatch.."BlackList.lua")
	
	-- 所有功能文件加载，都在此下	
	dofile(strPatch.."UpdateMgr.lua")
	dofile(strPatch.."TestMsg.lua")
	dofile(strPatch.."Account/Account.lua")
	dofile(strPatch.."Account/AccountMgr.lua")
	dofile(strPatch.."Room/Room.lua")
	dofile(strPatch.."Room/RoomMgr.lua")
	dofile(strPatch.."SmallHorn/SmallHornMgr.lua")
	dofile(strPatch.."Email/EmailMgr.lua")
	dofile(strPatch.."Rank/RankMgr.lua")
	dofile(strPatch.."Backstage/Backstage.lua")

	-- 此文件加载必须在最后	
	dofile(strPatch.."Protocol.lua")
	dofile(strPatch.."NetMgr.lua")
	
	-- 所有需要初始化的实例数据，都放在此处，不受热更新影响
	if not DontReload then
		
		net:Init("GameServer", SERVER_ID)
		AccountMgr:Init()
		RoomMgr:Init()	
		EmailMgr:Init()
		--RoomMgr:Test()
		
		-- 注册下次每日更新
		SetNextElevenUpdate()
		SetNextZeroUpdate()
		
		-- 创建以天分表的日志表
		--CreateDailyLog()
		
		-- 完成加载
		SQLQuery("SELECT 1", "OnStartService")
		
		-- 注册回调计时器
		RegistryTimer(60, -1, PROTOCOL.SS_ONE_MINUTE_UPDATE)
		RegistryTimer(300, -1, PROTOCOL.SS_FIVE_MINUTE_UPDATE)
		RegistryTimer(3600, -1, PROTOCOL.SS_ONE_HOUR_UPDATE)
		DontReload = true		
	end
	
	-- 随机种子
	local t = tonumber(tostring(os.time()):reverse())
	math.randomseed(t)
	
	LogInfo{" GC -> Before Use Memory:%.02fM", collectgarbage("count") / 1024}
	collectgarbage()
	LogInfo{" GC -> After  Use Memory:%.02fM", collectgarbage("count") / 1024}
	if PublicConfig.OPEN_WHITE_LIST == 1 then
		print("=========== 白名单功能状态:已开启")
		print("=========== 白名单功能状态:已开启")
		print("=========== 白名单功能状态:已开启")
	else
		print("=========== 白名单功能状态:已关闭")
		print("=========== 白名单功能状态:已关闭")
		print("=========== 白名单功能状态:已关闭")
	end	
end


-- 开启服务
function OnStartService(cPacket, nSocketID)

	RankMgr:InitRank()
	
	local nRet = c_ServerStartup(7000, GamePort, "")
	if nRet ~= 0 then
		LogError{"Startup GameServer Error:%d, Port:%d", nRet, GamePort}
	else
		print("Start Service!")	
	end
end





print "-----------load lua!-----------END"
