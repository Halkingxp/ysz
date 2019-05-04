--Export by excel config file, don't modify this file!
--[[
ID(Column[A] Type[int] Desc[序号]
EXCHANGE_GOLD(Column[N] Type[array] Desc[钻石兑换金币配置]
EXCHANGE_ROOMCARD(Column[O] Type[array] Desc[钻石兑换房卡配置]
EMAIL_GIFT_GOLD(Column[AA] Type[array] Desc[邮件赠送金币上下限]
BIND_CODE_GIFT_ROOM_CARD(Column[AC] Type[int] Desc[绑定邀请码赠送房卡数量]
TO_SALESMAN_BETTING(Column[AD] Type[int] Desc[达到推广员要求的下注金额]
ONE_REBATE(Column[AE] Type[int] Desc[一级推广员返利比例, 百分比]
TWO_REBATE(Column[AF] Type[int] Desc[二级推广员返利比例, 百分百]
ADVANCED_REBATE(Column[AG] Type[int] Desc[总代理返利比例, 百分比]
CHAT_PAOPAO_COOL_TIME(Column[AH] Type[int] Desc[发言泡泡冷却时间]
CHAT_PAOPAO_SHOW_TIME(Column[AI] Type[int] Desc[发言泡泡显示时间]
CHANGE_NAME_COST(Column[AO] Type[array] Desc[改名收取费用]
URL_NAME(Column[AP] Type[string] Desc[后台网站域名地址]
ROLE_ICON_MAX(Column[AS] Type[int] Desc[玩家Icon最大数量]
VOICE_INTERVAL(Column[AU] Type[int] Desc[语音冷却间隔时间]
DEALER_PAOPAO_MAX(Column[AV] Type[int] Desc[荷官泡泡语言计数]
CHIP_VALUE(Column[AW] Type[map] Desc[筹码对应的值]
DEALER_PAOPAO_RATE(Column[AX] Type[int] Desc[荷官泡泡发言概率(0~100)%]
CUT_OUT_RETURN_LOGIN_TIME(Column[AY] Type[int] Desc[切出时长退回登陆(秒)]
GOLD_TO_RMB_RATE(Column[AZ] Type[int] Desc[金币和人民币兑换比]
VALID_DECIMAL(Column[BA] Type[int] Desc[有效小数]
CUT_OUT_CAN_ENTER_ROOM_TIME(Column[BB] Type[int] Desc[切回游戏能进入房间的时限]
]]--

data.PublicConfig =
{
    EXCHANGE_GOLD = { 10, 10000 },
    EXCHANGE_ROOMCARD = { 10, 1 },
    EMAIL_GIFT_GOLD = { 1000000, 9999990000 },
    BIND_CODE_GIFT_ROOM_CARD = 20,
    TO_SALESMAN_BETTING = 1000000000,
    ONE_REBATE = 1.5,
    TWO_REBATE = 0.5,
    ADVANCED_REBATE = 0.5,
    CHAT_PAOPAO_COOL_TIME = 3,
    CHAT_PAOPAO_SHOW_TIME = 3,
    CHANGE_NAME_COST = { 0, 10000, 50000, 100000, 500000, 1000000, 5000000, 10000000, 50000000, 100000000, 500000000, 1000000000, 5000000000, 10000000000 },
    URL_NAME = "jhysz.bk.changlaith.com/login.php",
    ROLE_ICON_MAX = 16,
    VOICE_INTERVAL = 10,
    DEALER_PAOPAO_MAX = 4,
    CHIP_VALUE = { [1] = 10000, [2] = 50000, [3] = 100000, [4] = 500000, [5] = 1000000, [6] = 5000000, [7] = 10000000, [8] = 50000000, [9] = 100000000, [10] = 500000000, [11] = 1000000000, [12] = 5000000000 },
    DEALER_PAOPAO_RATE = 20,
    CUT_OUT_RETURN_LOGIN_TIME = 300,
    GOLD_TO_RMB_RATE = 10000,
    VALID_DECIMAL = 2,
    CUT_OUT_CAN_ENTER_ROOM_TIME = 60,
}

