GameData =
{
    LoginInfo =
    {
        -- 登陆的账号信息
        Account = "",
        -- 登陆的平台
        PlatformType = PLATFORM_TYPE.PLATFORM_TOURISTS,
        -- 登陆账号名称
        AccountName = "",
    },
    -- 角色的相关信息
    RoleInfo =
    {
        -- 账号
        Account = "",
        -- 账号ID
        AccountID = 0,
        -- 账号名称
        AccountName = "",
        -- 角色头像信息
        AccountIcon = 0,
        -- 砖石数量
        DiamondCount = 0,
        -- 金币数量
        GoldCount = 0,
        -- 显示金币数量
        DisplayGoldCount = 0,
        -- 房卡数量
        RoomCardCount = 0,
        -- 免费试玩次数
        FreePlayTime = 0,
        -- 免费金币数
        FreeGoldCount = 0,
        -- 显示的免费金币数量
        DisplayFreeGoldCount = 0,
        -- Vip 等级
        VipLevel = 0,
        -- 充值数量
        ChargeCount = 0,

        -- 昨日排名
        YesterdayRank = 0,
        -- 昨日赢取金币数
        YesterdayGoldNum = 0,

        Cache =
        {
            ChangedGoldCount = 0,
            ChangedFreeGoldCount = 0
        },
        -- 是否是推广员
        PromoterStep = 0,
        -- 是否已经填写过邀请码
        InviteCode = 0,
        -- 是否已绑定账号
        IsBindAccount = false,
        -- 未读邮件数量
        UnreadMailCount = 0,
        -- 修改名称次数
        ModifyNameCount = 0,
    },
    -- 组局玩家信息
    ZuJuPlayer =
    {
        -- 玩家ID
        AccountID = 0,
        -- 名称
        Name = '同花顺',
        -- 头像ID
        IconID = 0,
        -- 玩家头像url
        IconUrl = '',
        -- 当前拥有金币数量
        GoldValue = 0,
        -- 本局下注金额
        BetChipValue = 0,
        -- 玩家位置
        Position = 0,
        -- 玩家参与游戏状态(0 空位 1 旁观 2参与)
        PlayerState = 0,
        -- 玩家准备状态(0准备状态默认值 1 准备 2未准备)
        ReadyState = 0,
        -- 看牌标记(0未看牌 1看牌)
        LookState = 0,
        -- 弃牌状态(0 未弃牌 1弃牌)
        DropCardState = 0,
        -- 比牌状态(0 未比牌 1比牌)
        CompareState = 0,
        -- 比牌结果(0 默认状态 1比牌输 2 比牌赢)
        CompareResult = 0,
        -- 免费PK状态 0 不允许 1 允许
        FreePK = 1,
        -- 扑克列表
        PokerList = { },

        -- 是否是本局赢家
        IsWinner = false,
        -- 赢取的金币值
        WinGoldValue = 0,
        -- 是否亮牌(结算时刻)
        IsShowPokerCard = false,
    },

    -- 房间的相关信息
    RoomInfo =
    {
        -- 当前房间信息
        CurrentRoom = { },
        -- [1] = {[10000] ={ Count = 5, [1] = {X = 1, Y = 1, Owner = 10001, }
        RelationRooms = { },
        -- 统计信息
        CurrentRoomChips = { },
        -- 房间路单信息
        StatisticsInfo = { },
    },

    -- 排行榜数据
    RankInfo =
    {
        -- [1] = { RankID = 1, AccountName = "", AccountID = 0, VipLevel = 0, HeadIcon = "", RichValue = 0}
        RichList = nil,
        -- 总资产财富榜
        DayOfYear = 0,-- 获取排行榜数据时的日期（一年中的第几天）
    },
    -- 邮件信息
    EmailInfo =
    {
    },

    -- 游戏APP的状态
    GameState = 0,
    -- 大厅操作数据便于返回大厅时
    HallData = { },

    -- 上一次发送小喇叭的时间
    LastSmallHornTime = 0,
    -- 服务器ID
    ServerID = 0,
    -- 是否开启苹果支付,此值在登陆的时候由服务器初始化
    IsOpenApplePay = 1,
    -- 是否输入了邀请提示
    IsPromptedInviteTips = true,
    -- 是否显示邀请码按钮
    IsShowInviteBtn = 1,
    -- App版本检查结果
    AppVersionCheckResult = - 2,
    -- 是否同意协议
    IsAgreement = true,
    -- 游戏历史数据
    GameHistory = { MaxCount = 0, RequestedPage = 0, Datas = { } },
    -- 玩家注册渠道ID
    ChannelCode = 1,
    -- 是否已经确认平台ID
    ConfirmChannelCode = false,
    -- OpenInstall推荐人ID
    OpenInstallReferralsID,
    -- OpenInstall房间ID
    OpenInstallRoomID,
};

function GameData.InitHallData()
    GameData.HallData = { }
    -- 默认选择 竞咪厅
    GameData.HallData.SelectType = 1

    GameData.HallData.SelectType = CS.AppDefineConst.DefaultSelectType

    GameData.HallData.Data = { }
    -- 竞咪厅默认选择 4
    GameData.HallData.Data[1] = 1
    -- 试水厅默认选择 201
    GameData.HallData.Data[2] = 201
    -- Vip 厅默认选择 1
    GameData.HallData.Data[3] = 1
end

function GameData.InitCurrentRoomInfo(roomTypeParam)
    if roomTypeParam == ROOM_TYPE.JH_JuLong then
        GameData.InitBaiRenRoomInfo()
    else
        GameData.InitZuJuRoomInfo()
    end
end

-- (百人房间)数据初始化
function GameData.InitBaiRenRoomInfo()
    GameData.RoomInfo.CurrentRoom =
    {
        -- 房间ID
        RoomID = 0,
        -- 房主ID
        MasterID = 0,
        -- 房间当前阶段
        RoomState = 1,
        -- 倒计时
        CountDown = 20,
        -- 房间模板ID
        TemplateID = 0,
        -- 是否是试水厅
        IsFreeRoom = false,
        -- 是否是VIP厅
        IsVipRoom = false,
        -- 房间人数
        RoleCount = 0,
        -- 存储当前收到的扑克牌信息 格式为：[1] = {PokerType = 1, PokerNumber = 14, Visible = true,}
        Pokers = { },
        -- 最大局数
        MaxRound = 0,
        -- 当前局数
        CurrentRound = 0,
        -- 庄家信息
        BankerInfo = { ID = 0, Name = "", Gold = 0, LeftCount = 0, HeadIcon = 0 },
        -- 龙信息
        CheckRole1 = { ID = 0, Name = "", Icon = 1, },
        -- 虎信息
        CheckRole2 = { ID = 0, Name = "", Icon = 1, },
        -- 本局结果信息 位运算：1 龙赢，2 虎赢，4 和，8 龙金花 16 龙豹子 32 龙金花
        GameResult = 0,
        -- 赢取的金币
        WinGold = { },
        -- 当前选择下注的金额
        SelectBetValue = 0,

        -- [4(区域编号)] = {[0(自己)]={Value(值) = 0, Rank(排行) = 0 },[1(排行榜1)] = {Name(名称) ="", Value(值) = 0}},
        BetRankList = { },
        -- 自己的押注信息
        BetValues = { },
        -- {[1] = 0, [2] = 0, [3] = 0, [4] = 0, [5] = 0},
        -- 总计押注金额
        TotalBetValues = { },

        BankerList = { },
        -- 切牌动画中，切的是第几张扑克牌
        CutAniIndex = 0,
        -- 本局追加统计信息事件参数
        AppendStatisticsEventArgs = nil,
    }

end

-- ==============================--
-- desc: 组局房间初始化
-- time:2017-10-23 07:10:56
-- @return
-- ==============================--
function GameData.InitZuJuRoomInfo()
    -- body
    GameData.RoomInfo.CurrentRoom =
    {
        -- 房间ID
        RoomID = 123,
        -- 房主ID
        MasterID = 1,
        -- 房间类型
        RoomType = ROOM_TYPE.JH_MenJi,
        -- 房间大类型
        BigType = 20,
        -- 房间值类型
        SmallType = 0,
        -- 房间模式(经典 激情)
        GameMode = 0,
        -- 比闷模式(必闷1圈 必闷3圈)
        GameRule = 0,
        -- 房间底注
        BetMin = 10,
        -- 下注上限
        BetMax = 400,
        -- 房间状态
        RoomState = ZUJURoomState.Wait,
        -- 当前状态CD
        CountDown = 0,
        -- 玩家自己位置
        SelfPosition = 0,
        -- 庄家位置
        BankerPosition = 1,
        -- 当前下注总额
        BetAllValue = 0,
        -- 当前对战回合
        RoundTimes = 0,
        -- 当前下注位置
        BettingPosition = 0,
        -- 当前名牌下注
        MingCardBetMin = 0,
        -- 当前暗牌下注最小值
        DarkCardBetMin = 0,

        -- 房间对应位置玩家详细数据
        ZUJUPlayers = { },
        -- 当前房间所有下注情况
        AllBetInfo = { },
        -- =========挑战数据========
        -- 挑战者: 位置
        ChallengerPosition = 0,
        -- 应邀参与者位置
        ActorPosition = 0,
        -- 挑战赢家位置
        ChallengeWinnerPosition = 0,
        -- 名牌下注档次
        MingCardBettingValue =
        {
            [1] = 2,
            [2] = 5,
            [3] = 10,
            [4] = 20,
            [5] = 40,
        },

        -- 暗牌下注档次
        DarkCardBettingValue =
        {
            [1] = 2,
            [2] = 5,
            [3] = 10,
            [4] = 20,
            [5] = 40,
        }

    }
    -- 房间列表信息
    for i = 1, 5, 1 do
        -- 初始化玩家基础信息
        local playerInfo = lua_NewTable(GameData.ZuJuPlayer)
        playerInfo.AccountID = 0
        playerInfo.IconID = i
        playerInfo.IconUrl = ''
        playerInfo.Position = i
        playerInfo.Name = '帝濠' .. i
        playerInfo.PlayerState = Player_State.None
        if i == 5 or i == 1 then
            -- playerInfo.PlayerState = Player_State.JoinOK
        end
        playerInfo.LookState = 0
        playerInfo.DropCardState = 0
        playerInfo.CompareState = 0
        playerInfo.CompareResult = 0
        playerInfo.BetChipValue = 0
        playerInfo.PokerList = { }

        -- 初始化玩家扑克牌
        for card = 1, 3, 1 do
            playerInfo.PokerList[card] = { }
            local pokerData = { PokerType = 1, PokerNumber = card + 1, Visible = false, }
            playerInfo.PokerList[card] = pokerData
        end
        GameData.RoomInfo.CurrentRoom.ZUJUPlayers[i] = playerInfo
    end

end

-- 初始化对战房间当前下注倍率(名牌 暗牌)
function GameData.InitZUJURoomBettingValue(betMinParam)
    for index = 1, 5, 1 do
        GameData.RoomInfo.CurrentRoom.MingCardBettingValue[index] = betMinParam * BettingMingCardValue[index]
        GameData.RoomInfo.CurrentRoom.DarkCardBettingValue[index] = betMinParam * BettingDarkCardValue[index]
    end
end

-- 获取当前组局厅对应等级下注值
function GameData.GetZUJUBettingValue(betLevel)
    return GameData.RoomInfo.CurrentRoom.MingCardBettingValue[betLevel], GameData.RoomInfo.CurrentRoom.DarkCardBettingValue[betLevel]
end

-- 更新组局厅下注总额
function GameData.UpdateZUJUBetAllValue(betValue)
    GameData.RoomInfo.CurrentRoom.BetAllValue = GameData.RoomInfo.CurrentRoom.BetAllValue + betValue
end

-- 获取筹码所属等级
function GameData.GetZUJUBettingLevel(betValue)
    local level = 1
    local compareValue1 = 1
    local compareValue2 = 2
    for index = 1, 5, 1 do
        compareValue1 = GameData.RoomInfo.CurrentRoom.MingCardBettingValue[index]
        compareValue1 = GameConfig.GetFormatColdNumber(compareValue1)
        compareValue2 = GameData.RoomInfo.CurrentRoom.DarkCardBettingValue[index]
        compareValue2 = GameConfig.GetFormatColdNumber(compareValue2)
        if compareValue2 <= betValue and betValue <= compareValue1 then
            level = index
            break
        end
    end
    return level
end


-- 组局厅玩家显示位置转换
function GameData.PlayerPositionConvert2ShowPosition(tagPositionParam)
    local position = 0
    if tagPositionParam > 0 then
        position =(5 - GameData.RoomInfo.CurrentRoom.SelfPosition + tagPositionParam - 1) % 5 + 1
    else
        print("服务器传入位置有误:" .. tagPositionParam)
    end
    print(string.format('位置转换[%d]==>[%d]', tagPositionParam, position))
    return position
end

function GameData.ClearCurrentRoundData()
    GameData.RoomInfo.CurrentRoom.BetRankList = { }
    GameData.RoomInfo.CurrentRoom.BetValues = { }
    GameData.RoomInfo.CurrentRoom.TotalBetValues = { }
    GameData.RoomInfo.CurrentRoom.WinGold = { }
    GameData.RoomInfo.CurrentRoom.Pokers = { }
    GameData.RoomInfo.CurrentRoom.GameResult = 0
    GameData.RoomInfo.CurrentRoom.CheckRole1 = { ID = 0, Name = "", Icon = "", }
    -- 龙信息
    GameData.RoomInfo.CurrentRoom.CheckRole2 = { ID = 0, Name = "", Icon = "", }
    -- 虎信息
    GameData.RoomInfo.CurrentRoom.CutAniIndex = 0
    CS.EventDispatcher.Instance:TriggerEvent(EventDefine.UpdateBetValue, nil)
end

function GameData.SubFloatZeroPart(valueStr)
    local index = string.find(valueStr, ".")
    if index ~= nil then
        local strLength = #valueStr
        for i = strLength, 1, -1 do
            local endChar = string.sub(valueStr, -1)
            if endChar == "0" then
                valueStr = string.sub(valueStr, 1, #valueStr - 1)
            elseif endChar == "." then
                valueStr = string.sub(valueStr, 1, #valueStr - 1)
                break
            else
                break
            end
        end
    end

    return valueStr
end

function GameData.Init()
    GameData.InitCurrentRoomInfo(ROOM_TYPE.JH_ZuJu)
    GameData.InitHallData()
end

-- 获取扑克牌的贴图资源名称
function GameData.GetPokerCardSpriteName(pokerCard)
    local cardSpriteName = "sprite_" .. Poker_Type_Define[pokerCard.PokerType] .. "_" .. pokerCard.PokerNumber;
    return cardSpriteName;
end

function GameData.GetPokerCardSpriteNameOfBig(pokerCard)
    local cardSpriteName = "sprite_" .. Poker_Type_Define[pokerCard.PokerType] .. "_b_" .. pokerCard.PokerNumber
    return cardSpriteName
end

function GameData.GetPokerCardBackSpriteNameOfBig(pokerCard)
    return "sprite_Poker_Back_b_01";
end

function GameData.GetPokerDisplaySpriteName(pokerCard)
    if pokerCard ~= nil and pokerCard.Visible then
        return GameData.GetPokerCardSpriteName(pokerCard);
    else
        return GameData.GetPokerCardBackSpriteName(pokerCard);
    end
end

function GameData.GetRolePokerTypeDisplayName(roleType)
    return data.GetString("BRAND_TYPE_" .. GameData.GetRolePokerType(roleType))
end

function GameData.GetRolePokerType(roleType)
    local pokerCards = GameData.RoomInfo.CurrentRoom.Pokers
    if roleType == 1 then
        local pokerCard1 = pokerCards[1]
        local pokerCard2 = pokerCards[2]
        local pokerCard3 = pokerCards[3]
        return GameData.GetPokerType(pokerCard1, pokerCard2, pokerCard3)
    elseif roleType == 2 then
        local pokerCard1 = pokerCards[4]
        local pokerCard2 = pokerCards[5]
        local pokerCard3 = pokerCards[6]
        return GameData.GetPokerType(pokerCard1, pokerCard2, pokerCard3)
    else
        return "角色不正确"
    end
end

function GameData.GetPokerType(pokerCard1, pokerCard2, pokerCard3)
    if pokerCard1 == nil or pokerCard2 == nil or pokerCard3 == nil then
        return BRAND_TYPE.SANPAI
    end

    if pokerCard1.PokerNumber == pokerCard2.PokerNumber
        or pokerCard1.PokerNumber == pokerCard3.PokerNumber
        or pokerCard2.PokerNumber == pokerCard3.PokerNumber then
        if pokerCard1.PokerNumber == pokerCard2.PokerNumber and pokerCard2.PokerNumber == pokerCard3.PokerNumber then
            return BRAND_TYPE.BAOZI
        else
            return BRAND_TYPE.DUIZI
        end
    else
        -- 检验是否是金花
        local isJinHua = false
        if pokerCard1.PokerType == pokerCard2.PokerType then
            if pokerCard1.PokerType == pokerCard3.PokerType then
                isJinHua = true
            end
        end

        local isSunZi = false
        local sortedNumbers = lua_number_sort(pokerCard1.PokerNumber, pokerCard2.PokerNumber, pokerCard3.PokerNumber)
        -- 检验是否是顺子
        if (sortedNumbers[1] + 1) == sortedNumbers[2] then
            if (sortedNumbers[2] + 1) == sortedNumbers[3] then
                isSunZi = true
            end
        end

        if isJinHua and isSunZi then
            return BRAND_TYPE.SHUNJIN
        elseif isJinHua then
            return BRAND_TYPE.JINHUA
        elseif isSunZi then
            return BRAND_TYPE.SHUNZI
        else
            return BRAND_TYPE.SANPAI
        end
    end
end

function GameData.GetPokerCardBackSpriteName(pokerCard)
    return "sprite_Poker_Back_01";
end

-- 设置百人厅房间状态
function GameData.SetRoomState(roomState)
    GameData.RoomInfo.CurrentRoom.RoomState = roomState
    GameData.RoomInfo.CurrentRoom.CountDown = ROOM_TIME[roomState]
    CS.EventDispatcher.Instance:TriggerEvent(EventDefine.UpdateRoomState, roomState)
end

-- 设置组局房间状态
function GameData.SetZUJURoomState(roomState)
    GameData.RoomInfo.CurrentRoom.RoomState = roomState
    GameData.RoomInfo.CurrentRoom.CountDown = ZUJUROOM_TIME[roomState]
    if GameData.RoomInfo.CurrentRoom.CountDown == nil then
        print('*****组局厅房间状态:' .. roomState .. '有误')
    end
    CS.EventDispatcher.Instance:TriggerEvent(EventDefine.UpdateRoomState, roomState)
end

function GameData.ReduceRoomCountDownValue(deltaValue)
    GameData.RoomInfo.CurrentRoom.CountDown = GameData.RoomInfo.CurrentRoom.CountDown - deltaValue
end

function GameData.UpdateGoldCount(count, reason)
    if reason == 13 or reason == 12 then
        GameData.RoleInfo.Cache.ChangedGoldCount = count - GameData.RoleInfo.GoldCount
        print(string.format("New Gold:%d Old Gold:%d Change Gold:%d", count, GameData.RoleInfo.GoldCount, GameData.RoleInfo.Cache.ChangedGoldCount))
        GameData.RoleInfo.GoldCount = count
    else
        GameData.RoleInfo.GoldCount = count
        GameData.SyncDisplayGoldCount()
    end
end

function GameData.UpdateFreeGoldCount(count, reason)
    if reason == 13 or reason == 12 then
        GameData.RoleInfo.Cache.ChangedFreeGoldCount = count - GameData.RoleInfo.FreeGoldCount
        GameData.RoleInfo.FreeGoldCount = count
    else
        GameData.RoleInfo.FreeGoldCount = count
        GameData.SyncDisplayGoldCount()
    end
end

function GameData.SyncDisplayGoldCount()
    if GameData.RoleInfo.DisplayGoldCount ~= GameData.RoleInfo.GoldCount then
        GameData.RoleInfo.DisplayGoldCount = GameData.RoleInfo.GoldCount
        CS.EventDispatcher.Instance:TriggerEvent(EventDefine.UpdateGold, 1)
        GameData.RoleInfo.Cache.ChangedGoldCount = 0
    elseif GameData.RoleInfo.DisplayFreeGoldCount ~= GameData.RoleInfo.FreeGoldCount then
        GameData.RoleInfo.DisplayFreeGoldCount = GameData.RoleInfo.FreeGoldCount
        CS.EventDispatcher.Instance:TriggerEvent(EventDefine.UpdateGold, 2)
        GameData.RoleInfo.Cache.ChangedFreeGoldCount = 0
    else
        CS.EventDispatcher.Instance:TriggerEvent(EventDefine.UpdateGold, 0)
        GameData.RoleInfo.Cache.ChangedGoldCount = 0
        GameData.RoleInfo.Cache.ChangedFreeGoldCount = 0
    end
end

-- 设置未读邮件数量
function GameData.ResetUnreadMailCount(count)
    GameData.RoleInfo.UnreadMailCount = count
    local eventArg = GameData.CreateUnHandleEventArgsOfEmail(count)
    CS.EventDispatcher.Instance:TriggerEvent(EventDefine.UpdateUnHandleFlag, eventArg)
end

function GameData.CreateUnHandleEventArgsOfEmail(count)
    if count == nil then
        count = 0
    end
    local eventArg = lua_NewTable(UuHandleFlagEventArgs)
    eventArg.UnHandleType = UNHANDLE_TYPE.EMAIL
    eventArg.ContainsUnHandle = count > 0
    eventArg.UnHandleCount = count
    return eventArg
end


function GameData.GetTrendResultSpriteOfTrendItem(roundResult)
    if CS.Utility.GetLogicAndValue(roundResult, WIN_CODE.LONG) == WIN_CODE.LONG then
        return 'sprite_Trend_Icon_1'
    elseif CS.Utility.GetLogicAndValue(roundResult, WIN_CODE.HU) == WIN_CODE.HU then
        return 'sprite_Trend_Icon_2'
    elseif CS.Utility.GetLogicAndValue(roundResult, WIN_CODE.HE) == WIN_CODE.HE then
        return 'sprite_Trend_Icon_4'
    else
        return 'sprite_Trend_Icon_1'
    end
end

-- 获取玩家头像的的贴图资源名称
function GameData.GetRoleIconSpriteName(iconid)
    -- 由于老账号记录为0
    if iconid == 0 then
        iconid = 1
    end
    local iconSpriteName = "sprite_RoleIcon_" .. iconid;
    return iconSpriteName
end