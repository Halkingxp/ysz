--Export by excel config file, don't modify this file!
--[[
ID(Column[A] Type[int] Desc[序号]
HE_PROBABILITY(Column[B] Type[int] Desc[和局概率]
MAX_UP_BANKER_GAMES(Column[C] Type[int] Desc[申请上庄后最多当庄局数]
MAX_APPLY_UP_BANKER(Column[D] Type[int] Desc[申请上庄列表人数限制]
SKIP_BANKER_GOLD_MULTIPLE(Column[E] Type[int] Desc[跳庄到第一排名的金币倍数]
SYSTEM_EMAIL_NAME(Column[F] Type[string] Desc[系统邮件名字]
BANKER_NAME(Column[G] Type[string] Desc[系统当庄时, 庄家名字]
BANKER_GOLD(Column[H] Type[int] Desc[系统当庄时, 庄家金币数量]
ROOM_MAX_ROUND(Column[I] Type[int] Desc[房间最大回合数]
DEFAULT_EXTRACT_SCALE(Column[J] Type[int] Desc[竟咪房抽成比例]
MAX_GOLD(Column[K] Type[int] Desc[金币最高上限]
MAX_RMB(Column[L] Type[int] Desc[钻石最高上限]
MAX_ROOMCARD(Column[M] Type[int] Desc[房卡最高上限]
EXCHANGE_GOLD(Column[N] Type[array] Desc[钻石兑换金币配置]
EXCHANGE_ROOMCARD(Column[O] Type[array] Desc[钻石兑换房卡配置]
NOVICE_TIME(Column[P] Type[int] Desc[新手免费试玩时间]
NOVICE_TIME_FREE_COUNT(Column[Q] Type[int] Desc[新手免费试玩时间内, 每天免费次数]
GET_FREE_GOLD(Column[R] Type[int] Desc[领取免费试玩金币数量]
SYSTEM_BANKER_JUMP(Column[S] Type[int] Desc[系统当庄时, 跳过切牌等待播放动画时间]
ROOM_TIME(Column[T] Type[array] Desc[游戏过程中,各阶段等待时间]
BANKER_COMPENSATE_MULTIPLE(Column[U] Type[int] Desc[庄家针对龙虎下注赔付放大倍数]
COMPENSATE_UPPER_LIMIT_JINHUA(Column[V] Type[int] Desc[金花赔付上限计算参数]
COMPENSATE_UPPER_LIMIT_BAOZI(Column[W] Type[int] Desc[豹子赔付上限计算参数]
COMPENSATE(Column[X] Type[array] Desc[赔付比例]
ROOM_CREATE_COST(Column[Y] Type[map] Desc[VIP创建房间的花费]
ROOM_DESTROY_TIME(Column[Z] Type[int] Desc[VIP房间销毁时间]
EMAIL_GIFT_GOLD(Column[AA] Type[array] Desc[邮件赠送金币上下限]
EMALL_SMALL_HORN_COOL_TIME(Column[AB] Type[int] Desc[小喇叭冷却时间 ]
BIND_CODE_GIFT_ROOM_CARD(Column[AC] Type[int] Desc[绑定邀请码赠送房卡数量]
TO_SALESMAN_BETTING(Column[AD] Type[int] Desc[达到推广员要求的下注金额]
ONE_REBATE(Column[AE] Type[int] Desc[一级推广员返利比例, 百分比]
TWO_REBATE(Column[AF] Type[int] Desc[二级推广员返利比例, 百分百]
ADVANCED_REBATE(Column[AG] Type[int] Desc[总代理返利比例, 百分比]
CHAT_PAOPAO_COOL_TIME(Column[AH] Type[int] Desc[发言泡泡冷却时间]
IS_PLAYER_CAN_SEND_REWARD(Column[AJ] Type[int] Desc[是否允许发红包(0不允许, 1允许)]
APP_STORE_INVITATION_CODE(Column[AK] Type[int] Desc[苹果绑定邀请码标志(0关闭, 1开启)]
APP_STORE_PAY(Column[AL] Type[int] Desc[苹果支付标志(0关闭, 1只开启苹果支付)]
OPEN_WHITE_LIST(Column[AM] Type[int] Desc[白名单开启开关(0关闭, 1开启)]
DALIY_FREE_EMAIL_NUM(Column[AN] Type[int] Desc[每日免费邮件发送次数]
CHANGE_NAME_COST(Column[AO] Type[array] Desc[改名收取费用]
BASE_LINE(Column[AQ] Type[array] Desc[基准线和吃大赔小概率(百分比)]
DANGER_LINE(Column[AR] Type[array] Desc[危险线和吃大赔小概率(百分比)]
ROLE_ICON_MAX(Column[AS] Type[int] Desc[玩家Icon最大数量]
SYSTEM_BANKER_HEAD_ID(Column[AT] Type[int] Desc[系统庄家头像ID]
VOICE_INTERVAL(Column[AU] Type[int] Desc[语音冷却间隔时间]
]]--

PublicConfig =
{
    HE_PROBABILITY = 150,
    MAX_UP_BANKER_GAMES = 5,
    MAX_APPLY_UP_BANKER = 5,
    SKIP_BANKER_GOLD_MULTIPLE = 3,
    SYSTEM_EMAIL_NAME = "官方系统",
    BANKER_NAME = "风月小妹",
    BANKER_GOLD = 500000000,
    ROOM_MAX_ROUND = 64,
    DEFAULT_EXTRACT_SCALE = 5,
    MAX_GOLD = 9999999999990000,
    MAX_RMB = 999999999999,
    MAX_ROOMCARD = 9999,
    EXCHANGE_GOLD = { 10, 10000 },
    EXCHANGE_ROOMCARD = { 10, 1 },
    NOVICE_TIME = 259200,
    NOVICE_TIME_FREE_COUNT = 10,
    GET_FREE_GOLD = 5000000,
    SYSTEM_BANKER_JUMP = 1,
    ROOM_TIME = { 0, 1, 3, 6, 3, 24, 7, 17, 2, 17, 2, 8 },
    BANKER_COMPENSATE_MULTIPLE = 2,
    COMPENSATE_UPPER_LIMIT_JINHUA = 2,
    COMPENSATE_UPPER_LIMIT_BAOZI = 1.2,
    COMPENSATE = { 8, 16, 8, 1, 1 },
    ROOM_CREATE_COST = { [1] = 1, [8] = 1, [20] = 2, [64] = 5 },
    ROOM_DESTROY_TIME = 108000,
    EMAIL_GIFT_GOLD = { 1000000, 9999990000 },
    EMALL_SMALL_HORN_COOL_TIME = 10,
    BIND_CODE_GIFT_ROOM_CARD = 20,
    TO_SALESMAN_BETTING = 1000000000,
    ONE_REBATE = 1.5,
    TWO_REBATE = 0.5,
    ADVANCED_REBATE = 0.5,
    CHAT_PAOPAO_COOL_TIME = 3,
    IS_PLAYER_CAN_SEND_REWARD = 1,
    APP_STORE_INVITATION_CODE = 1,
    APP_STORE_PAY = 0,
    OPEN_WHITE_LIST = 0,
    DALIY_FREE_EMAIL_NUM = 10,
    CHANGE_NAME_COST = { 0, 10000, 50000, 100000, 500000, 1000000, 5000000, 10000000, 50000000, 100000000, 500000000, 1000000000, 5000000000, 10000000000 },
    BASE_LINE = { 0, 20 },
    DANGER_LINE = { -100000000, 40 },
    ROLE_ICON_MAX = 16,
    SYSTEM_BANKER_HEAD_ID = 15,
    VOICE_INTERVAL = 10,
}

