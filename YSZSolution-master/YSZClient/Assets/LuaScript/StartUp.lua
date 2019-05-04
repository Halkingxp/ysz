StartUp = {}

require 'DataManagers/MoveNotice/CustomList'
require 'LuaUtility'
require 'GameConfig'
require 'GameData'
require 'Net/NetMsgHandler'
require 'DataManagers/Email/EmailMgr'
require 'DataManagers/MusicMgr/MusicMgr'
require 'PlatformBridge'
require 'LoginMgr'
require 'Net/HubServerClient'

--VSCode lua 调试代码
if GameConfig.IsDebug == true then
	-- body
	local breakSocketHandle, debugXpCall = require("LuaDebugjit")("localhost", 7003)
end


--主入口函数。从这里开始lua逻辑
function StartUp.Main()
	-- 初始化游戏配置脚本
	GameConfig.Init()
	-- 初始化游戏数据
	GameData.Init()
	-- 初始化网络处理
	NetMsgHandler.Init()
	-- 初始化音乐管理器
	MusicMgr:Init()
	-- 初始化平台连接桥
	PlatformBridge:Init()
	-- 初始化登录管理器
	LoginMgr:Init()
	
	-- 打开登陆界面
	local openparam = CS.WindowNodeInitParam("UILogin")
	openparam.NodeType = 0
	openparam.LoadComplatedCallBack =
	function(windowNode)
		CS.UILoading.Hide()
	end
	CS.WindowManager.Instance:OpenWindow(openparam)
	
	-- 切换状态为登陆
	GameData.GameState = GAME_STATE.LOGIN
	
end

function StartUp.Shutdown()
	MusicMgr:Destory()
end 