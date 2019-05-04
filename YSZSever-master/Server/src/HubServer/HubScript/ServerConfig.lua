print "ServerConfig.lua"
-- 此文件只包含Server所有公式和配置


MERGE_INTERVAL	    		= 500000	-- 合服算法的区间值和GameServer同时修改
ONLINE_MAX					= 5000		-- 允许同时在线最高人数限制
SAVE_INTERVAL_TIME			= 300		-- 回存间隔时间5分钟
ONE_DAY_SECOND				= 86400		-- 一天的秒数
PROBABILITY         		= 10000     -- 游戏通用概率万份比
DAILY_UPDATE_TIME 			= 5			-- 每日更新定于每天凌晨5点, 如要调整此值, 需修改C++逻辑


MAX_REGISTER_COUNT          = 10000      -- 一个服务器最大注册人数, 超过即分配新服务器登录



--状态枚举
STATE = 
{
	NORMAL			= 1,		-- 正常
	OFFLINE			= 2,		-- 离线
}


