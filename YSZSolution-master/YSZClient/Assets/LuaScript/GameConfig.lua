data = { };


GameConfig =
{
    -- 开发测试阶段可开启 正式版本一定要记住关闭该功能
    IsDebug = true,
    -- 是否启用选择服务器0表示不启用1表示启用，当ipv6的网络环境下此标志位无效
    IsSelectServer = 0,
    -- 能否游客登陆(该标记位将从hub服务器下发)
    CanVisitorLogin = true,
    -- 是否是审核版本
    IsShenHeiVision = false,
    -- 邀请好友一起玩游戏url
    InviteUrl = "http://jhysz.api.changlaith.com/downpage/main.php",

    -- 连接的HubServerURL 域名(正式服务器:clysz.hub.changlaith.com 苹果审核域名:jhysz.v10101hub.changlaith.com 本地服务器:10.8.3.123)
    -- 外网测试服:118.190.159.166)
    HubServerURL = "10.8.3.234",
    GameServerURL = "jhysz.s10.changlaith.com",
    -- 链接服务器地址 由服务器下发
    HubServerPort = 20000,
    GameServerIP = "",
    GameServerPort = 30000,
}

-- 性别
SEX =
{
    BOY = 1,
    -- 男
    GIRL = 2,-- 女
}

-- 扑克牌花色定义
Poker_Type =
{
    Spade = 1,
    -- 黑桃
    Hearts = 2,
    -- 红桃
    Club = 3,
    -- 梅花
    Diamond = 4,-- 方块
}

-- 扑克牌花色Icon抬头定义
Poker_Type_Define =
{
    [Poker_Type.Spade] = "Spade",
    -- 黑桃
    [Poker_Type.Hearts] = "Hearts",
    -- 红桃
    [Poker_Type.Club] = "Club",
    -- 梅花
    [Poker_Type.Diamond] = "Diamond",-- 方块
}

-- 大厅类型
HALL_TYPE =
{
    -- 大厅中心
    None = 0,
    -- 聚龙厅    百人房
    JuLong = 1,
    -- 经典厅    五人房
    JinDian = 2,
    -- 组局厅    五人房
    ZuJu = 3,
}

-- 房间类型
ROOM_TYPE =
{
    -- 金花 聚龙厅 百人房
    JH_JuLong = 1,
    -- 金花 组局房 5人对战
    JH_ZuJu = 2,
    -- 金花 闷鸡房间 5人对战
    JH_MenJi = 3,
}


-- 获取字符串，如果没找到则返回Key
function data.GetString(strKey)
    local result = data.StringConfig[strKey]
    if result ~= nil then
        return result.Value_CN
    end
    return strKey
end

EventDefine =
{
    -- 更新角色金币
    UpdateGold = "UpdateGold",
    -- 更新房间状态
    UpdateRoomState = "UpdateRoomState",
    -- 初始化房间状态
    InitRoomState = "InitRoomState",
    -- 扑克牌可见改变
    PokerVisibleChanged = "PokerVisibleChanged",
    -- 更新游戏结果
    UpdateGameResult = "UpdateGameResult",
    -- 某张牌发牌结束
    DealOnePokerEnd = "DealOnePokerEnd",
    -- 更新统计信息
    UpdateStatistics = "UpdateStatistics",
    -- 更新押注金额
    UpdateBetValue = "UpdateBetValue",
    -- 更新房间人数
    UpdateRoleCount = "UpdateRoleCount",
    -- 更新庄家信息
    UpdateBankerInfo = "UpdateBankerInfo",
    -- 更新押注排行榜
    UpdateBetRankList = "UpdateBetRankList",
    -- 通知赢取的金币结果
    NotifyWinGold = "NotifyWinGold",
    -- 通知停止押注
    NotifyBetEnd = "NotifyBetEnd",
    -- 刷新当前可视的大UI（主界面级别的UI）的内容
    UpdateCurrentBigUIInfo = "UpdateCurrentBigUIInfo",
    -- 更新庄家列表
    UpdateBankerList = "UpdateBankerList",
    -- 通知游戏结束
    NotifyEndGame = "NotifyEndGame",
    -- 通知添加筹码事件	
    NotifyBetResult = "NotifyBetResult",
    -- 更新邮件信息
    UpdateEmailInfo = "UpdateEmailInfo",
    -- 通知角色账号信息
    NotifyEmailRoleInfo = "NotifyEmailRoleInfo",
    -- 通知邮件发送结果
    NotifySendMailResult = "NotifySendMailResult",
    -- 更新未处理的标志
    UpdateUnHandleFlag = "UpdateUnHandleFlag",
    -- 连接游戏服务器失败
    ConnectGameServerFail = "ConnectGameServerFail",
    -- 连接游戏服务器超时
    ConnectGameServerTimeOut = "ConnectGameServerTimeOut",
    -- 更新扑克牌
    UpdateHandlePoker = "UpdateHandlePoker",
    -- 通知有玩家搓牌尖叫
    NotifyCutPokerType = "NotifyCutPokerType",
    -- VIP玩家聊天泡泡
    NotifyChatPaoPao = "NotifyChatPaoPao",
    -- 玩家头像ID变化
    NotifyHeadIconChange = "NotifyHeadIconChange",
    -- 玩家昵称变化
    NotifyChangeAccountName = "NotifyChangeAccountName",
    -- 玩家语音聊天
    NotifyPlayerYuYinChat = "NotifyPlayerYuYinChat",
    -- 游客登录开关检测通知
    NotifyVisitorCheckEvent = "NotifyVisitorCheckEvent",

    -- 组局厅玩家准备状态通知
    NotifyZUJUPlayerReadyStateEvent = "NotifyZUJUPlayerReadyStateEvent",
    -- 组局厅添加玩家通知
    NotifyZUJUAddPlayerEvent = "NotifyZUJUAddPlayerEvent",
    -- 组局厅删除玩家通知
    NotifyZUJUDeletePlayerEvent = "NotifyZUJUDeletePlayerEvent",
    -- 组局厅玩家下注通知
    NotifyZUJUBettingEvent = "NotifyZUJUBettingEvent",
    -- 组局厅玩家弃牌通知
    NotifyZUJUDropCardEvent = "NotifyZUJUDropCardEvent",
    -- 组局厅玩家看牌通知
    NotifyZUJULookCardEvent = "NotifyZUJULookCardEvent",


}

UNHANDLE_TYPE =
{
    EMAIL = 1,-- 邮件
}

UuHandleFlagEventArgs =
{
    UnHandleType = 0,
    -- 未处理的类型
    ContainsUnHandle = false,
    -- 是否包含未处理
    UnHandleCount = 0,-- 未处理的数量
}

HandlePokerEventArgs =
{
    HandlerID = 0,
    PokerIndex = 0,
    IsRotate = false,
    FlipMode = 0,
    MoveX = 0.0,
    MoveY = 0.0,
}

GAME_STATE =
{
    UPDATE = 1,
    -- 更新
    LOADING = 2,
    -- 加载
    LOGIN = 3,
    -- 登陆
    HALL = 4,
    -- 大厅
    ROOM = 5,-- 房间
}

-- 百人厅 房间状态
ROOM_STATE =
{
    -- 开始
    START = 1,
    -- 等待
    WAIT = 2,
    -- 洗牌
    SHUFFLE = 3,
    -- 切牌
    CUT = 4,
    -- 切牌动画
    CUTANI = 5,
    -- 押注
    BET = 6,
    -- 发牌
    DEAL = 7,
    -- 龙看牌
    CHECK1 = 8,
    -- 龙看牌结束
    CHECK1OVER = 9,
    -- 虎看牌
    CHECK2 = 10,
    -- 虎看牌结束
    CHECK2OVER = 11,
    -- 结算
    SETTLEMENT = 12,
}

-- 百人厅 各房间状态CD时间
ROOM_TIME =
{
    [ROOM_STATE.START] = 9,
    [ROOM_STATE.WAIT] = 1,
    [ROOM_STATE.SHUFFLE] = 3,
    [ROOM_STATE.CUT] = 6,
    [ROOM_STATE.CUTANI] = 3,
    [ROOM_STATE.BET] = 24,
    [ROOM_STATE.DEAL] = 7,
    [ROOM_STATE.CHECK1] = 15,
    [ROOM_STATE.CHECK1OVER] = 2,
    [ROOM_STATE.CHECK2] = 15,
    [ROOM_STATE.CHECK2OVER] = 2,
    [ROOM_STATE.SETTLEMENT] = 8,
}

MOVE_NOTICE_CONFIG =
{
    MOVE_SPEED = 100,
    LIST_LENGTH = 10,
    -- 小喇叭冷却时间
    SMALL_HORN_COOL_TIME = 1,
}

EMAIL_CONFIG =
{
    -- GIFT_GOLD_LOW = 500,
    -- GIFT_GOLD_HIGH = 999999,
    SEND_CONTENT_MAX = 50,
    SEND_CONTENT_MIN = 1,
    GIFT_SEND_RULE = '1. 赠送金币最低额度<color=#D8AD15>500</color>。\n\n2. 系统将从赠送金币中，抽取<color=#D8AD15>5%</color>手续费。\n\n3. VIP9级玩家赠送金币，抽取<color=#D8AD15>1%</color>手续费。\n\n4. 给VIP9玩家赠送金币，抽取<color=#D8AD15>1%</color>手续费。',
}

CHIP_VALUE = {
    [1] = 10000,
    [2] = 50000,
    [3] = 100000,
    [4] = 500000,
    [5] = 1000000,
    [6] = 5000000,
    [7] = 10000000,
    [8] = 50000000,
    [9] = 100000000,
    [10] = 500000000,
}

-- 胜负编号
WIN_CODE =
{
    LONG = 1,
    HU = 2,
    HE = 4,
    LONGJINHUA = 8,
    LONGHUBAOZI = 16,
    HUJINHUA = 32,
}

-- 区域胜负结果码
AREA_WIN_CODE =
{
    [1] = WIN_CODE.LONGJINHUA,
    [2] = WIN_CODE.LONGHUBAOZI,
    [3] = WIN_CODE.HUJINHUA,
    [4] = WIN_CODE.LONG,
    [5] = WIN_CODE.HU,
}

-- 胜负结果转区域码
WIN_AREA_CODE =
{
    [WIN_CODE.LONGJINHUA] = 1,
    [WIN_CODE.LONGHUBAOZI] = 2,
    [WIN_CODE.HUJINHUA] = 3,
    [WIN_CODE.LONG] = 4,
    [WIN_CODE.HU] = 5,
    [WIN_CODE.HE] = 0,-- 无此条
}

-- 押注区域
BETTING =
{
    LONG_JINHUA = 1,
    -- 龙金花
    LONGHU_BAOZI = 2,
    -- 龙虎豹子
    HU_JINHUA = 3,
    -- 虎金花
    LONG = 4,
    -- 龙
    HU = 5,-- 虎
}

COMPENSATE =
{
    [BETTING.LONG_JINHUA] = 8,
    -- 龙金花赔付比例
    [BETTING.LONGHU_BAOZI] = 16,
    -- 虎豹子赔付比例
    [BETTING.HU_JINHUA] = 8,
    -- 虎金花赔付比例
    [BETTING.LONG] = 1,
    -- 龙赔付比例
    [BETTING.HU] = 1,-- 虎赔付比例
}

CREATE_ROOM_CONSUME =
{
    [1] = { Round = 8, Consume = 1 },
    -- 房间局数 8 消耗房卡数量
    [2] = { Round = 20, Consume = 2 },
    -- 房间局数20 消耗房卡数量
    [3] = { Round = 64, Consume = 5 },-- 房间局数64 消耗房卡数量
}

BRAND_TYPE =
{
    -- 散牌
    SANPAI = 1,
    -- 对子
    DUIZI = 2,
    -- 顺子
    SHUNZI = 3,
    -- 金花
    JINHUA = 4,
    -- 顺金
    SHUNJIN = 5,
    -- 豹子
    BAOZI = 6,
}

-- 邮件类型
MAIL_TYPE =
{
    SYSTEM = 1,
    PLAYER = 2,
    INVITE = 3,
    PROMOTER = 4,
    PASSWORD = 5,
    REBATE = 6,
}

-- 平台类型
PLATFORM_TYPE =
{
    -- 游客
    PLATFORM_TOURISTS = 1,
    -- APP_STORE
    PLATFORM_APP_STORE = 150,
    -- QQ
    PLATFORM_QQ = 151,
    -- 微信
    PLATFORM_WEIXIN = 152,
    -- Alipay
    PLATFORM_ALIPAY = 153,
    -- 胜付通
    PLATFORM_SDO = 154,
}

PLATFORM_FUNCTION_ENUM =
{
    -- 注册
    PLATFORM_FUNCTION_REG = 1,
    -- 登陆
    PLATFORM_FUNCTION_LOGIN = 2,
    -- 二次校验
    PLATFORM_FUNCTION_SECOND_CHECK = 3,
    -- 分享
    PLATFORM_FUNCTION_SHARE = 4,
    -- 支付
    PLATFORM_FUNCTION_PAY = 5,
    -- 是否安装相关软件
    PLATFORM_FUNCTION_INSTALLED = 6,
    -- 绑定账号
    PLATFORM_FUNCTION_BIND_ACCOUNT = 7,
    -- 登录成功通知到PlatformBridge
    PLATFORM_FUNCTION_LOGIN_SUCCESS = 8,
    -- OpenInstall 反馈回来的渠道ID
    PLATFORM_FUNCTION_CHANNELCODE = 9,
    -- OpenInstall 反馈回来的邀请信息	
    PLATFORM_FUNCTION_INVITE = 10,
}

function GameConfig.Init()
    require 'Config/RoomConfig'
    require 'Config/VipConfig'
    require 'Config/StringConfig'
    require 'Config/RunHorseConfig'
    require 'Config/MaskConfig'
    require 'Config/StoreConfig'
    require 'Config/PublicConfig'
    require 'Config/MusicConfig'
    require 'Config/MailContentConfig'
    require 'Config/MusicGroupConfig'
    GameConfig.InitChipValueByConfig()
    print('Inited game configs')
end

function GameConfig.InitChipValueByConfig()
    if data.PublicConfig ~= nil and data.PublicConfig.CHIP_VALUE ~= nil then
        CHIP_VALUE = { }
        for k, value in ipairs(data.PublicConfig.CHIP_VALUE) do
            CHIP_VALUE[k] = value
        end
    end
end

-- 格式化金币的显示
function GameConfig.GetFormatColdNumber(logicGold)
    -- data.PublicConfig.GOLD_TO_RMB_RATE
    -- data.PublicConfig.VALID_DECIMAL
    formatGold = logicGold / data.PublicConfig.GOLD_TO_RMB_RATE
    return formatGold
end

function GameConfig.GetLogicColdNumber(formatGold)
    logicGold = formatGold * data.PublicConfig.GOLD_TO_RMB_RATE
    return logicGold
end

-- 玩家游戏状态
Player_State = 
{
    -- 位置空闲
    None = 0,
    -- 坐下未参与游戏
    JoinNO = 1,
    -- 参与游戏
    JoinOK = 2,
}

-- 组局厅 房间状态
ZUJURoomState =
{
    -- 开始(等待服务器自动开始)
    Start = 1,
    -- 等待准备
    Wait = 2,
    -- 收取底注
    SubduceBet = 3,
    -- 发牌
    Deal = 4,
    -- 下注阶段
    Betting = 5,
    -- 比牌阶段
    CardVS = 6,
    -- 结算阶段
    Settlement = 7,
}

-- 百人厅 各房间状态CD时间
ZUJUROOM_TIME =
{
    [ZUJURoomState.Start] = 99,
    [ZUJURoomState.Wait] = 5,
    [ZUJURoomState.SubduceBet] = 2,
    [ZUJURoomState.Deal] = 2,
    [ZUJURoomState.Betting] = 15,
    [ZUJURoomState.CardVS] = 3,
    [ZUJURoomState.Settlement] = 4,
}

-- 明牌(看牌)下注倍率
BettingMingCardValue = 
{
    [1] = 2,
    [2] = 5,
    [3] = 10,
    [4] = 20,
    [5] = 40,
}

-- 暗牌(焖鸡)下注倍率
BettingDarkCardValue = 
{
    [1] = 1,
    [2] = 2,
    [3] = 5,
    [4] = 10,
    [5] = 20,
}

