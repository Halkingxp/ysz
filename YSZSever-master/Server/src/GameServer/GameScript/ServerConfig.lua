print "ServerConfig.lua"
-- 此文件只包含Server所有公式和配置


--====================================================================================
--以下内容不允许改动
--====================================================================================
MERGE_INTERVAL	    		= 1000000		-- 合服算法的区间值和GameServer同时修改
ONLINE_MAX					= 5000			-- 允许同时在线最高人数限制
ONE_DAY_SECOND				= 86400			-- 一天的秒数
PROBABILITY         		= 10000     	-- 游戏通用概率万份比
DAILY_UPDATE_TIME 			= 11			-- 每日更新定于每天凌晨11点
ROOM_DESTROY_TIME		    = 10800			-- VIP房间销毁时间 (单位:秒)

MAX_SAVE_SETTLEMENT_TIME    = 604800        -- 超过7天的记录删除 (单位:秒)
MAX_SAVE_SETTLEMENT_LEN     = 100           -- 最大保存100条


-- 订单成功通知
ORDER_RESULTS_STRING = "http://jhysz.api.changlaith.com/Pay/PayResults.php?order=%s&results=success"

-- 申请成为推广员(自动通过审核)
APPLY_SALEMANS_STRING = "http://jhysz.api.changlaith.com/apply.php?id=%d&pwd=123456&qq=1&wechat=1&phone=1&sid=%d"


-- 登录日志
function SendLoginLog(nAccountID)
	
	local nIsWriteLog = c_IsWriteLog()
	if nIsWriteLog > 0 then
		SQLLog(string.format("INSERT INTO log_login(log_AccountID,log_LoginTime) VALUES (%d, '%s')", nAccountID, GetTimeToString()), "")
	end
	
end

-- 登出日志
function SendExitLog(nAccountID)
	
	local nIsWriteLog = c_IsWriteLog()
	if nIsWriteLog > 0 then
		SQLLog(string.format("UPDATE log_login SET log_LogoutTime='%s' WHERE log_AccountID=%d ORDER BY log_ID DESC LIMIT 1", GetTimeToString(), nAccountID))
	end
	
end

-- 在线人数日志
function SendOnlineLog(nMaxOnline, nOnline, nNewCount, iProfitGold)
	
	local nIsWriteLog = c_IsWriteLog()
	if nIsWriteLog > 0 then
		SQLLog(string.format("INSERT INTO log_online(log_MaxOnline, log_Online,log_NewCount,log_ProfitGold,log_Time) VALUES (%d, %d, %d, %d, '%s')", nMaxOnline, nOnline, nNewCount, iProfitGold, GetTimeToString()), "")
	end
	
end


-- 每日代币日志
function SendMoneyDailyLog(strMoneyName, nMoney, strNowTime)
	
	local nIsWriteLog = c_IsWriteLog()
	if nIsWriteLog > 0 then
		SQLLog(string.format("INSERT INTO log_money_daily(log_MoneyName,log_Money,log_Time) VALUES ('%s', %d, '%s')", strMoneyName, nMoney, strNowTime), "")
	end
	
end


-- 邮件日志
function SendEmailLog(nSenderID, nReceiverID, nGold, nCost)
	
	local nIsWriteLog = c_IsWriteLog()
	if nIsWriteLog > 0 then
		SQLLog(string.format("INSERT INTO log_email(log_SenderID, log_ReceiveID, log_Gold, log_Cost, log_Time) VALUES (%d, %d, %d, %d, '%s')",
		nSenderID, nReceiverID, nGold, nCost, GetTimeToString()), "")
	end
	
end

-- 每日VIP等级分布
function SendVipDailyLog(nVIP0, nVIP1, nVIP2, nVIP3, nVIP4, nVIP5, nVIP6, nVIP7, nVIP8, nVIP9, strNowTime)
	
	local nIsWriteLog = c_IsWriteLog()
	if nIsWriteLog > 0 then
		SQLLog(string.format("INSERT INTO log_vip(log_Vip0, log_Vip1, log_Vip2, log_Vip3, log_Vip4, log_Vip5, log_Vip6, log_Vip7, log_Vip8, log_Vip9, log_Time) VALUES (%d, %d, %d, %d, %d, %d, %d, %d, %d, %d, '%s')",
		nVIP0, nVIP1, nVIP2, nVIP3, nVIP4, nVIP5, nVIP6, nVIP7, nVIP8, nVIP9, strNowTime), "")
	end
	
end

-- 玩家每局结算日志
function SendSettlementLog(nAccountID, nRoomID, isBanker, nLong, nHu, nLongJinHua, nBaoZi, nHuJinHua, strResult, strLongType, strHuType, iChangeGold, strPayAll, strNowTime)
	
	local nIsWriteLog = c_IsWriteLog()
	if nIsWriteLog > 0 then
		nLong = nLong or 0
		nHu = nHu or 0
		nLongJinHua = nLongJinHua or 0
		nBaoZi = nBaoZi or 0
		nHuJinHua = nHuJinHua or 0
		SQLLog(string.format("INSERT INTO log_settlement(log_AccountID,log_RoomID,log_Banker,log_YaLong,log_YaHu,log_YaLongJinHua,log_YaBaozi,log_YaHuJinHua,log_Result,log_LongType,log_HuType,log_ChangeGold,log_PayAll,log_Time) VALUES (%d,%d,%d,%d,%d,%d,%d,%d,'%s','%s','%s',%d,'%s','%s')",
		nAccountID, nRoomID, isBanker, nLong, nHu, nLongJinHua, nBaoZi, nHuJinHua, strResult, strLongType, strHuType, iChangeGold, strPayAll, strNowTime), "")
	end
	
end

-- 房间日报日志
function SendRoomDailyLog(nRoomID, nBoard, nLongWin, nHuWin, nHe, nLongJinHua, nBaoZi, nHuJinHua, nYaLong, nYaHu, nYaLongJinHua, nYaBaoZi, nYaHuJinHua, nSystemBanker, iSystemProfitGold, nSystemCommission, nPlayerBanker, iPlayerProfitGold, nPlayerCommission, strNowTime)
	
	local nIsWriteLog = c_IsWriteLog()
	if nIsWriteLog > 0 then
		SQLLog(string.format("INSERT INTO log_room_daily(log_RoomID,log_Board,log_LongWin,log_HuWin,log_He,log_LongJinHua,log_Baozi,log_HuJinHua,log_YaLong,log_YaHu,log_YaLongJinHua,log_YaBaozi,log_YaHuJinHua,log_SystemBanker,log_SystemProfitGold,log_SystemCommission,log_PlayerBanker,log_PlayerProfitGold,log_PlayerCommission,log_Time) VALUES (%d,%d,%d,%d,%d,%d,%d,%d,%d,%d,%d,%d,%d,%d,%d,%d,%d,%d,%d,'%s')",
		nRoomID, nBoard, nLongWin, nHuWin, nHe, nLongJinHua, nBaoZi, nHuJinHua, nYaLong, nYaHu, nYaLongJinHua, nYaBaoZi, nYaHuJinHua, nSystemBanker, iSystemProfitGold, nSystemCommission, nPlayerBanker, iPlayerProfitGold, nPlayerCommission, strNowTime), "")
	end
	
end


-- 原因类型, 同时填写OPERATE_STRING对应的内容
OPERATE = 
{
	GM							= 1,		-- GM功能
	INIT						= 2,		-- 初始化
	CHARGE						= 3,		-- 充值RMB
	GET_FREE_GOLD				= 4,		-- 领取免费金币
	CHANGE_NAME					= 5,		-- 改名
    ROBOT_CREATE                = 6,        -- 创造机器人
	
	BETTING						= 11,		-- 下注
	SETTLEMENT					= 12,		-- 结算
	BANKER_SETTLEMENT			= 13,		-- 庄家结算
	ERROR_RETURN				= 14,		-- 异常返还	
	
	CREATE_VIP_ROOM				= 18,		-- 创建VIP房间
	EXCHANGE_GOLD				= 19,		-- 金币兑换金币
	EXCHANGE_ROOMCARD			= 20,		-- 金币兑换房卡	
	
	BIND_CODE					= 40,		-- 绑定邀请码
	DAILY_REBATE				= 41,		-- 每日返利
	
	SMALL_HORN					= 50,		-- 小喇叭
	EMAILL						= 51,		-- EMail赠送

}

OPERATE_STRING = 
{
	[OPERATE.GM]							= "GM",						-- GM功能
	[OPERATE.INIT]							= "INIT",					-- 初始化
	[OPERATE.CHARGE]						= "CHARGE",					-- 充值RMB
	[OPERATE.GET_FREE_GOLD]					= "GET_FREE_GOLD",			-- 领取免费金币
	[OPERATE.CHANGE_NAME]					= "CHANGE_NAME",			-- 改名
	
	[OPERATE.BETTING]						= "BETTING",				-- 下注
	[OPERATE.SETTLEMENT]					= "SETTLEMENT",				-- 结算
	[OPERATE.BANKER_SETTLEMENT]				= "BANKER_SETTLEMENT",		-- 庄家结算
	[OPERATE.ERROR_RETURN]					= "ERROR_RETURN",			-- 异常返还
	
	[OPERATE.CREATE_VIP_ROOM]				= "CREATE_VIP_ROOM",		-- 创建VIP房间
	[OPERATE.EXCHANGE_GOLD]					= "EXCHANGE_GOLD",			-- 金币兑换金币
	[OPERATE.EXCHANGE_ROOMCARD]				= "EXCHANGE_ROOMCARD",		-- 金币兑换房卡	
	
	[OPERATE.BIND_CODE]						= "BIND_CODE",				-- 绑定邀请码
	[OPERATE.DAILY_REBATE]					= "DAILY_REBATE",			-- 每日返利
	
	[OPERATE.SMALL_HORN]					= "SMALL_HORN",				-- 小喇叭	
	[OPERATE.EMAILL]						= "EMAILL",					-- EMail赠送
}

    
PAY_STRING =
{
	[1] = "爆庄",
	[2] = "全赔",
}

-- 性别       
SEX =          
{
	BOY  			= 1,    	-- 男
    GIRL 			= 2,    	-- 女
}


ROOM_STATE = 
{
	DENGDAI_START	= 1,		-- VIP房等待开始
	DENGDAI			= 2,		-- 等待
	XIPAI			= 3,		-- 洗牌
	QIEPAI			= 4,		-- 切牌
	OVER_QIEPAI		= 5,		-- 切牌完成
	XIAZHU			= 6,		-- 下注
	FAPAI			= 7,		-- 发牌
	LONG_CUO		= 8,		-- 龙搓牌
	OVER_LONG_CUO	= 9,		-- 完成龙搓牌
	HU_CUO			= 10,		-- 虎搓牌
	OVER_HU_CUO		= 11,		-- 完成虎搓牌
	JIESUAN			= 12,		-- 结算	
}

SALESMAN = 
{
	NULL			= 0,		-- 非推广员
	APPLY			= 1,		-- 申请中
	COMMON			= 2,		-- 普通推广员
	ADVANCED		= 3,		-- 高级推广员(总代理)
}

ROOM_TYPE =
{
	COMMON			= 1,		-- 搓牌房
	FREE			= 2,		-- 试玩房
	VIP				= 3,		-- VIP房
}

BRAND_TYPE = 
{
	SANPAI			= 1,		-- 散牌
	DUIZI			= 2,		-- 对子
	SHUNZI			= 3,		-- 顺子
	JINHUA			= 4,		-- 金花
	SHUNJIN			= 5,		-- 顺金
	BAOZI			= 6,		-- 豹子
}

CARD_COLOR = 
{
	HEITAO			= 1,		-- 黑桃
	HONGTAO			= 2,		-- 红桃
	MEIHUA			= 3,		-- 梅花
	FANGKUAI		= 4,		-- 方块
}



IDENTITY = 
{
	LONG			= 1,		-- 龙
	HU				= 2,		-- 虎
	BANKER			= 3,		-- 庄家
}

STATISTICS_RESULT = 
{
	LONG_WIN		= 1,		-- 龙胜
	HU_WIN			= 2,		-- 虎胜
	HE				= 4,		-- 和局
	LONG_JINHUA		= 8,		-- 龙金花
	BAOZI			= 16,		-- 龙虎豹子
	HU_JINHUA		= 32,		-- 虎金花
}

RESULT =
{
	SHENG			= 1,		-- 胜
	FU				= 2,		-- 负
	HE				= 3,		-- 和
}

BETTING =
{
	LONG_JINHUA		= 1,			-- 龙金花
	BAOZI			= 2,			-- 龙虎豹子
	HU_JINHUA		= 3,			-- 虎金花
	LONG			= 4,			-- 龙
	HU				= 5,			-- 虎	
}

--状态枚举
STATE = 
{
	NORMAL			= 1,		-- 正常
	OFFLINE			= 2,		-- 离线
}

BRAND_STRING = 
{
	[BRAND_TYPE.SANPAI]			= "散牌",		-- 散牌
	[BRAND_TYPE.DUIZI]			= "对子",		-- 对子
	[BRAND_TYPE.SHUNZI]			= "顺子",		-- 顺子
	[BRAND_TYPE.JINHUA]			= "金花",		-- 金花
	[BRAND_TYPE.SHUNJIN]		= "顺金",		-- 顺金
	[BRAND_TYPE.BAOZI]			= "豹子",		-- 豹子
}

COLOR_STRING = 
{	
	[CARD_COLOR.HEITAO]			= "♠",--"?",		-- 黑桃
	[CARD_COLOR.HONGTAO]		= "♥",--"?",		-- 红桃
	[CARD_COLOR.MEIHUA]			= "♣",--"?",		-- 梅花
	[CARD_COLOR.FANGKUAI]		= "♦",--"?",		-- 方块
}

POINT_STRING = 
{
	[7]							= "7",		
	[8]							= "8",		
	[9]							= "9",		
	[10]						= "10",		
	[11]						= "J",		
	[12]						= "Q",		
	[13]						= "K",		
	[14]						= "A",		
}

PLATFORM_STRING =
{
	[150] = "AppStore",
	[151] = "QQPay",
	[152] = "WeiXin",
	[153] = "Alipay",
	[154] = "ShengPay",
}

RESULT_STRING =
{
	[RESULT.SHENG]			= "虎胜",		-- 虎胜
	[RESULT.FU]				= "龙胜",		-- 龙胜
	[RESULT.HE]				= "和局",		-- 和
}


STATISTICS_STRING =
{
	[STATISTICS_RESULT.LONG_WIN]		= "龙胜",		-- 龙胜
	[STATISTICS_RESULT.HU_WIN]			= "虎胜",		-- 虎胜
	[STATISTICS_RESULT.HE]				= "和局",		-- 和局
	[STATISTICS_RESULT.LONG_JINHUA]		= "龙金花",		-- 龙金花
	[STATISTICS_RESULT.BAOZI]			= "龙虎豹子",	-- 龙虎豹子
	[STATISTICS_RESULT.HU_JINHUA]		= "虎金花",		-- 虎金花
}

--邮件类型
MAIL_TYPE = 
{
	SYSTEM          = 1,		-- 系统发的
	PLAYER			= 2,		-- 玩家发的
	INVITE			= 3,		-- 邀请成为推广员邮件
	SALESMAN		= 4,		-- 成为推广员通知
	PASSWORD		= 5,		-- 通知网站密码
	REBATE			= 6,		-- 每日返利
}

--====================================================================================
--以上内容不允许改动
--====================================================================================





