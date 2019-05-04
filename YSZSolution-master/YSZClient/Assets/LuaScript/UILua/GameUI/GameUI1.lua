local Time = CS.UnityEngine.Time

-- 菜单组件
local mReturnCaiDan = nil

-- PK模块组件
local mVSPK = nil
local mVSPKTable =
{
    PKPlayer1 = nil,
    PKPlayer2 = nil,
    PKVImage = nil,
    PKSImage = nil,
    FailImage1 = nil,
    FailImage2 = nil,
    PKPos =
    {
        [1] = nil,
        [2] = nil,
        [3] = nil,
        [4] = nil,
        [5] = nil,
    },

    PKPosTargets =
    {
        [1] = nil,
        [2] = nil,
    }
}

-- 玩家组件数据
local PlayerItem =
{
    TransformRoot = nil,
    YQButton = nil,
    ZXButton = nil,
    HeadIcon = nil,
    NameText = nil,
    HandleCD = nil,
    GoldInfo = nil,
    GoldText = nil,
    BetingInfo = nil,
    BetingText = nil,
    BankerPos = nil,
    BankerTag = nil,
    PokerParent = nil,
    PokerPoints = { },
    PokerCards = { },
    KPImage = nil,
    QPImage = nil,
    JZImage = nil,
    GZImage = nil,
    ZBImage = nil,
    VSOKButtonGameObject = nil,
}

-- 玩家UI元素集合
local mPlayersUIInfo = { }

-- 玩家下注模块组件
local mMasterXZInfo =
{
    -- 玩家看牌按钮组件
    KPButtonGameObject = nil,
    -- 下注模块组件
    XZButtonGameObject = nil,
    QPButtonGameObject = nil,
    JZButtonGameObject1 = nil,
    GZButtonGameObject = nil,
    BPButtonGameObject = nil,

    -- 加注模块组件
    JZButtonGameObject = nil,
    -- 加注按钮text
    JZButtonTexts =
    {
        [1] = nil,
        [2] = nil,
        [3] = nil,
        [4] = nil,
    },
    -- 玩家自己筹码组件
    CMImageGameObject = nil,
    -- 玩家准备按钮组件
    ZBButtonGameObject = nil
}

local CHIP_JOINTS =
{
    [1] = { JointPoint = nil, RangeX = { Min = - 160, Max = 160 }, RangeY = { Min = - 150, Max = 150 } },
    [2] = { JointPoint = nil, RangeX = { Min = - 160, Max = 160 }, RangeY = { Min = - 150, Max = 150 } },
    [3] = { JointPoint = nil, RangeX = { Min = - 160, Max = 160 }, RangeY = { Min = - 150, Max = 150 } },
    [4] = { JointPoint = nil, RangeX = { Min = - 160, Max = 160 }, RangeY = { Min = - 150, Max = 150 } },
    [5] = { JointPoint = nil, RangeX = { Min = - 160, Max = 160 }, RangeY = { Min = - 150, Max = 150 } },
}

-- 筹码起始点组件
local CHIP_START =
{
    [1] = nil,
    [2] = nil,
    [3] = nil,
    [4] = nil,
    [5] = nil,
}

-- 筹码组件
local CHIP_RES =
{
    [1] = nil,
    [2] = nil,
    [3] = nil,
    [4] = nil,
    [5] = nil,
}

-- 扑克牌发牌时挂接点
local mPokerCardPoints = { }

-- 房间基础信息(ID 下注总额 对战回合 底注下线 底注上线)
local mRoomInfo =
{
    RoomIDText = nil,
    BetAllValueText = nil,
    RoundTimesText = nil,
    BetMinText = nil,
    BetMaxText = nil,
}

-- 当前下注者CD信息
local mCurrentHandleCD = nil
local mISUpdateBetingCD = false

-- 初始化UI元素
function InitUIElement()
    -- body
    mReturnCaiDan = this.transform:Find('Canvas/CaidanButton/ReturnCaiDan').gameObject
    -- PK模块
    mVSPK = this.transform:Find('Canvas/VSPK').gameObject
    mVSPKTable.PKPlayer1 = this.transform:Find('Canvas/VSPK/PKPlayer1')
    mVSPKTable.PKPlayer2 = this.transform:Find('Canvas/VSPK/PKPlayer2')
    mVSPKTable.PKPlayer2 = this.transform:Find('Canvas/VSPK/PKPlayer2')
    mVSPKTable.PKVImage = this.transform:Find('Canvas/VSPK/PKVImage')
    mVSPKTable.PKSImage = this.transform:Find('Canvas/VSPK/PKSImage')
    mVSPKTable.FailImage1 = this.transform:Find('Canvas/VSPK/PKPlayer1/FailImage')
    mVSPKTable.FailImage2 = this.transform:Find('Canvas/VSPK/PKPlayer2/FailImage')
    for index = 1, 5, 1 do
        mVSPKTable.PKPos[index] = this.transform:Find('Canvas/VSPK/PKPos' .. index)
    end
    mVSPKTable.PKPosTargets[1] = this.transform:Find('Canvas/VSPK/PKPosTarget1')
    mVSPKTable.PKPosTargets[2] = this.transform:Find('Canvas/VSPK/PKPosTarget2')

    InitPlayerUIElement()
    -- 玩家下注模块
    this.transform:Find('Canvas/MasterInfo').gameObject:SetActive(true)
    mMasterXZInfo.KPButtonGameObject = this.transform:Find('Canvas/MasterInfo/KPButton').gameObject
    mMasterXZInfo.XZButtonGameObject = this.transform:Find('Canvas/MasterInfo/Buttons/').gameObject
    mMasterXZInfo.QPButtonGameObject = this.transform:Find('Canvas/MasterInfo/Buttons/QPButton').gameObject
    mMasterXZInfo.JZButtonGameObject1 = this.transform:Find('Canvas/MasterInfo/Buttons/JZButton').gameObject
    mMasterXZInfo.GZButtonGameObject = this.transform:Find('Canvas/MasterInfo/Buttons/GZButton').gameObject
    mMasterXZInfo.BPButtonGameObject = this.transform:Find('Canvas/MasterInfo/Buttons/BPButton').gameObject

    mMasterXZInfo.JZButtonGameObject = this.transform:Find('Canvas/MasterInfo/JZInfo').gameObject
    mMasterXZInfo.ZBButtonGameObject = this.transform:Find('Canvas/MasterInfo/ZBButton').gameObject

    for index = 1, 4, 1 do

        mMasterXZInfo.JZButtonTexts[index] = this.transform:Find(string.format('Canvas/MasterInfo/JZInfo/JZButton%d/Text', index)):GetComponent('Text')

    end

    mMasterXZInfo.CMImageGameObject = this.transform:Find('Canvas/Players/Player5/CMImage').gameObject

    -- 筹码挂接组件
    local chipsJointRoot = this.transform:Find('Canvas/AllBetChips/ChipPoints')
    for index = 1, 5, 1 do
        local rectTrans = chipsJointRoot:Find('HandlePoint' .. index):GetComponent("RectTransform")
        CHIP_START[index] = rectTrans
        CHIP_JOINTS[index].JointPoint = this.transform:Find('Canvas/AllBetChips/ChipJoints/HandleJoint_' .. index):GetComponent("RectTransform")
        CHIP_RES[index] = this.transform:Find('Canvas/AllBetChips/ChipRes/ChipItem_' .. index)
    end

    -- 扑克牌挂接点
    for index = 1, 15, 1 do
        mPokerCardPoints[index] = nil
        mPokerCardPoints[index] = this.transform:Find('Canvas/Players/PokerCardPoints/CardPoint_' .. index)
    end

    -- 房间信息
    mRoomInfo.RoomIDText = this.transform:Find('Canvas/RoomInfo/RoomID/Text'):GetComponent('Text')
    mRoomInfo.BetAllValueText = this.transform:Find('Canvas/RoomInfo/BetAllValue/Text'):GetComponent('Text')
    mRoomInfo.RoundTimesText = this.transform:Find('Canvas/RoomInfo/RoundTimes/Text'):GetComponent('Text')
    mRoomInfo.BetMinText = this.transform:Find('Canvas/RoomInfo/BetMin/Text'):GetComponent('Text')
    mRoomInfo.BetMaxText = this.transform:Find('Canvas/RoomInfo/BetMax/Text'):GetComponent('Text')

end

function InitPlayerUIElement()
    -- body
    local playerRoot = this.transform:Find('Canvas/Players')
    for position = 1, 5, 1 do
        local dataItem = lua_NewTable(PlayerItem)
        local childItem = playerRoot:Find('Player' .. position)
        mPlayersUIInfo[position] = dataItem
        dataItem.TransformRoot = childItem.gameObject
        dataItem.YQButton = childItem:Find('Head/YQButton')
        dataItem.ZXButton = childItem:Find('Head/ZXButton')
        dataItem.HeadIcon = childItem:Find('Head/HeadIcon'):GetComponent('Image')
        dataItem.NameText = childItem:Find('Head/HeadIcon/NameText'):GetComponent('Text')
        dataItem.HandleCD = childItem:Find('Head/HeadIcon/HandleCD'):GetComponent('Image')
        dataItem.GoldInfo = childItem:Find('GoldInfo')
        dataItem.GoldText = childItem:Find('GoldInfo/GoldIcon/Text'):GetComponent('Text')
        dataItem.BetingInfo = childItem:Find('BetingInfo')
        dataItem.BetingText = childItem:Find('BetingInfo/Text'):GetComponent('Text')
        dataItem.BankerPos = childItem:Find('BankerPos')
        dataItem.BankerTag = childItem:Find('BankerPos/BankerTag')
        dataItem.PokerParent = childItem:Find('Pokers')
        dataItem.KPImage = childItem:Find('KPImage')
        dataItem.QPImage = childItem:Find('QPImage')
        dataItem.JZImage = childItem:Find('JZImage')
        dataItem.GZImage = childItem:Find('GZImage')
        dataItem.ZBImage = childItem:Find('ZBImage')
        dataItem.VSOKButtonGameObject = childItem:Find('VSOKButton').gameObject
        -- 扑克牌挂接点
        for cardIndex = 1, 3, 1 do
            if dataItem.PokerPoints == nil then
                dataItem.PokerPoints = { }
                dataItem.PokerCards = { }
            end
            dataItem.PokerPoints[cardIndex] = nil
            dataItem.PokerCards[cardIndex] = nil
            dataItem.PokerPoints[cardIndex] = childItem:Find('Pokers/point' .. cardIndex)
            dataItem.PokerCards[cardIndex] = childItem:Find('Pokers/point' .. cardIndex .. '/PokerItem')
        end

    end

end

-- 还原玩家对应位置到初始状态
function ResetPlayerInfo2Defaul(positionParam)
    -- body
    mPlayersUIInfo[positionParam].YQButton.gameObject:SetActive(false)
    mPlayersUIInfo[positionParam].ZXButton.gameObject:SetActive(false)
    mPlayersUIInfo[positionParam].HeadIcon.gameObject:SetActive(false)
    mPlayersUIInfo[positionParam].NameText.text = ''
    mPlayersUIInfo[positionParam].HandleCD.gameObject:SetActive(false)
    mPlayersUIInfo[positionParam].GoldInfo.gameObject:SetActive(false)
    mPlayersUIInfo[positionParam].BetingInfo.gameObject:SetActive(false)
    mPlayersUIInfo[positionParam].KPImage.gameObject:SetActive(false)
    mPlayersUIInfo[positionParam].QPImage.gameObject:SetActive(false)
    mPlayersUIInfo[positionParam].JZImage.gameObject:SetActive(false)
    mPlayersUIInfo[positionParam].GZImage.gameObject:SetActive(false)
    mPlayersUIInfo[positionParam].ZBImage.gameObject:SetActive(false)
    mPlayersUIInfo[positionParam].VSOKButtonGameObject:SetActive(false)
    mPlayersUIInfo[positionParam].BankerTag.gameObject:SetActive(false)
end

-- 设置对应位置坐下状态
function SetPlayerSitdownState(positionParam)
    print('玩家位置:' .. positionParam)
    local PlayerState = GameData.RoomInfo.CurrentRoom.ZUJUPlayers[positionParam].PlayerState
    mPlayersUIInfo[positionParam].YQButton.gameObject:SetActive(PlayerState == Player_State.None)

end

-- 设置对应位置玩家基础信息
function SetPlayerBaseInfo(positionParam)
    local PlayerState = GameData.RoomInfo.CurrentRoom.ZUJUPlayers[positionParam].PlayerState
    local IconID = GameData.RoomInfo.CurrentRoom.ZUJUPlayers[positionParam].IconID
    local PlayerInfo = GameData.RoomInfo.CurrentRoom.ZUJUPlayers[positionParam]
    mPlayersUIInfo[positionParam].HeadIcon.gameObject:SetActive(PlayerState ~= Player_State.None)
    mPlayersUIInfo[positionParam].GoldInfo.gameObject:SetActive(PlayerState ~= Player_State.None)
    if PlayerState ~= Player_State.None then
        SetPlayerHeadIcon(positionParam)
        SetPlayerGoldValue(positionParam)
        SetPlayerNameText(positionParam)
    end
    print(string.format('玩家:%d 状态:%d', positionParam, PlayerState))
end

-- 设置指定玩家金币值
function SetPlayerGoldValue(positionParam)
    local PlayerInfo = GameData.RoomInfo.CurrentRoom.ZUJUPlayers[positionParam]
    mPlayersUIInfo[positionParam].GoldText.text = lua_CommaSeperate(PlayerInfo.GoldValue)
end

-- 设置对应位置玩家Icon
function SetPlayerHeadIcon(positionParam)
    -- body
    if GameData.RoomInfo.CurrentRoom.ZUJUPlayers[positionParam].PlayerState == Player_State.None then
        return
    end
    mPlayersUIInfo[positionParam].HeadIcon:ResetSpriteByName(GameData.GetRoleIconSpriteName(GameData.RoleInfo.AccountIcon), false)
end

-- 设置玩家名字
function SetPlayerNameText(positionParam)
    if GameData.RoomInfo.CurrentRoom.ZUJUPlayers[positionParam].PlayerState == Player_State.None then
        return
    end
    local PlayerInfo = GameData.RoomInfo.CurrentRoom.ZUJUPlayers[positionParam]
    mPlayersUIInfo[positionParam].NameText.text = PlayerInfo.Name
end

-- 还原UI默认基础显示状态
function RestoreUI2Default()
    -- body
    SetCaidanShow(false)
    VSPKShow(false)
    MasterKPButtonShow(false)
    MasterXZButtonShow(false)
    MasterJZInfoShow(false)
    MasterCMImageGameObjectShow(false)
    ResetPokerCardVisible()
    -- 玩家位置信息重置
    for position = 1, 5, 1 do
        ResetPlayerInfo2Defaul(position)
    end
end

-- 重置扑克牌显示
function ResetPokerCardVisible()
    for position = 1, 5, 1 do
        ResetPlayerCardToDefault(position)
    end
end

-- 重置玩家扑克默认状态
function ResetPlayerCardToDefault(positionParam)
    for cardIndex = 1, 3, 1 do
        SetTablePokerCardVisible(mPlayersUIInfo[positionParam].PokerCards[cardIndex], false)
        SetPokerCardShow(positionParam, cardIndex, false)
    end
end


-- 设置扑克牌显示隐藏状态
function SetPokerCardShow(positionParam, cardIndexParam, showParam)
    if mPlayersUIInfo[positionParam].PokerCards[cardIndexParam].gameObject.activeSelf == showParam then
        return
    end
    mPlayersUIInfo[positionParam].PokerCards[cardIndexParam].gameObject:SetActive(showParam)
end

-- 设置玩家扑克牌是否可见
function SetTablePokerCardVisible(pokerCard, isVisible)
    if nil == pokerCard then
        error('玩家扑克牌数据异常')
        return
    end
    if pokerCard:Find('PokerBack').gameObject.activeSelf == lua_NOT_BOLEAN(isVisible) then
        return
    end
    pokerCard:Find('PokerBack').gameObject:SetActive(lua_NOT_BOLEAN(isVisible))
    if isVisible then
        -- 翻牌音效
        -- PlaySoundEffect(4)
    end
end

function Awake()
    InitUIElement()
    AddButtonHandlers()
    RestoreUI2Default()
    -- body
    if GameData.RoomInfo.CurrentRoom.RoomID > 0 then
        ResetGameToRoomState(GameData.RoomInfo.CurrentRoom.RoomState)
    end
    -- TODO 测试模块
    Test1()
end

function Start()

end

-- UI 开启
function WindowOpened()
    CS.EventDispatcher.Instance:AddEventListener(EventDefine.InitRoomState, ResetGameToRoomState)
    CS.EventDispatcher.Instance:AddEventListener(EventDefine.UpdateRoomState, RefreshGameByRoomStateSwitchTo)

    CS.EventDispatcher.Instance:AddEventListener(EventDefine.NotifyZUJUPlayerReadyStateEvent, OnNotifyZUJUPlayerReadyStateEvent)
    CS.EventDispatcher.Instance:AddEventListener(EventDefine.NotifyZUJUAddPlayerEvent, OnNotifyZUJUAddPlayerEvent)
    CS.EventDispatcher.Instance:AddEventListener(EventDefine.NotifyZUJUDeletePlayerEvent, OnNotifyZUJUDeletePlayerEvent)
    CS.EventDispatcher.Instance:AddEventListener(EventDefine.NotifyZUJUBettingEvent, OnNotifyZUJUBettingEvent)
    CS.EventDispatcher.Instance:AddEventListener(EventDefine.NotifyZUJUDropCardEvent, OnNotifyZUJUDropCardEvent)
    CS.EventDispatcher.Instance:AddEventListener(EventDefine.NotifyZUJULookCardEvent, OnNotifyZUJULookCardEvent)


end

-- UI 关闭
function WindowClosed()
    CS.EventDispatcher.Instance:RemoveEventListener(EventDefine.InitRoomState, ResetGameToRoomState)
    CS.EventDispatcher.Instance:RemoveEventListener(EventDefine.UpdateRoomState, RefreshGameByRoomStateSwitchTo)

    CS.EventDispatcher.Instance:RemoveEventListener(EventDefine.NotifyZUJUPlayerReadyStateEvent, OnNotifyZUJUPlayerReadyStateEvent)
    CS.EventDispatcher.Instance:RemoveEventListener(EventDefine.NotifyZUJUAddPlayerEvent, OnNotifyZUJUAddPlayerEvent)
    CS.EventDispatcher.Instance:RemoveEventListener(EventDefine.NotifyZUJUDeletePlayerEvent, OnNotifyZUJUDeletePlayerEvent)
    CS.EventDispatcher.Instance:RemoveEventListener(EventDefine.NotifyZUJUBettingEvent, OnNotifyZUJUBettingEvent)
    CS.EventDispatcher.Instance:RemoveEventListener(EventDefine.NotifyZUJUDropCardEvent, OnNotifyZUJUDropCardEvent)
    CS.EventDispatcher.Instance:RemoveEventListener(EventDefine.NotifyZUJULookCardEvent, OnNotifyZUJULookCardEvent)


end

-- 每一帧更新
function Update()
    GameData.ReduceRoomCountDownValue(Time.deltaTime)
    UpdateCurrentBettingCD()
end

function OnDestroy()
    -- body
end

-- 按钮事件响应绑定
function AddButtonHandlers()
    this.transform:Find('Canvas/CaidanButton'):GetComponent("Button").onClick:AddListener(OnCaidanButtonClick)
    this.transform:Find('Canvas/CaidanButton/ReturnCaiDan/ReturnButton'):GetComponent("Button").onClick:AddListener(OnQuitGameButtonClick)
    this.transform:Find('Canvas/CaidanButton/ReturnCaiDan/SitUpButton'):GetComponent("Button").onClick:AddListener(OnSitUpButtonClick)
    this.transform:Find('Canvas/CaidanButton/ReturnCaiDan/Image'):GetComponent("Button").onClick:AddListener(OnCaidanHideClick)

    this.transform:Find('Canvas/MasterInfo/KPButton'):GetComponent('Button').onClick:AddListener(OnKPButtonClick)
    this.transform:Find('Canvas/MasterInfo/Buttons/QPButton'):GetComponent('Button').onClick:AddListener(OnQPButtonClick)
    this.transform:Find('Canvas/MasterInfo/Buttons/JZButton'):GetComponent('Button').onClick:AddListener(OnJZButtonClick)
    this.transform:Find('Canvas/MasterInfo/Buttons/GZButton'):GetComponent('Button').onClick:AddListener(OnGZButtonClick)
    this.transform:Find('Canvas/MasterInfo/Buttons/BPButton'):GetComponent('Button').onClick:AddListener(OnBPButtonClick)
    this.transform:Find('Canvas/MasterInfo/ZBButton'):GetComponent('Button').onClick:AddListener(OnZBButtonClick)

    this.transform:Find('Canvas/MasterInfo/JZInfo'):GetComponent('Button').onClick:AddListener(OnJZHideClick)
    this.transform:Find('Canvas/MasterInfo/JZInfo/JZButton1'):GetComponent('Button').onClick:AddListener( function() OnJZButtonOKClick(2) end)
    this.transform:Find('Canvas/MasterInfo/JZInfo/JZButton2'):GetComponent('Button').onClick:AddListener( function() OnJZButtonOKClick(3) end)
    this.transform:Find('Canvas/MasterInfo/JZInfo/JZButton3'):GetComponent('Button').onClick:AddListener( function() OnJZButtonOKClick(4) end)
    this.transform:Find('Canvas/MasterInfo/JZInfo/JZButton4'):GetComponent('Button').onClick:AddListener( function() OnJZButtonOKClick(5) end)
    -- 每个位置要求按钮call
    for position = 1, 5, 1 do
        local childItem = this.transform:Find('Canvas/Players/Player' .. position .. '/Head/YQButton'):GetComponent('Button').onClick:AddListener( function() OnYQButtonClick(position) end)
    end

    for posIndex = 1, 4, 1 do
        local childItem = this.transform:Find('Canvas/Players/Player' .. posIndex .. '/VSOKButton'):GetComponent('Button')
        childItem.onClick:AddListener( function() OnVSOKButtonOnclick(posIndex) end)
    end

end

-- =============================房间基础信息设置==========================================
-- 设置房间基础信息
function SetRoomBaseInfo()
    local roomData = GameData.RoomInfo.CurrentRoom
    SetRoomID(roomData.RoomID)
    SetBetAllValueText(roomData.BetAllValue)
    SetRounTimesText(roomData.RoundTimes)
    SetBetMinText(roomData.BetMin)
    SetBetMaxText(roomData.BetMax)
end

function SetRoomID(roomIDParam)
    mRoomInfo.RoomIDText.text = tostring(roomIDParam)
end

function SetBetAllValueText(betParam)
    mRoomInfo.BetAllValueText.text = tostring(betParam)
end

function SetRounTimesText(roundTimesParam)
    mRoomInfo.RoundTimesText.text = string.format('%d/%d', roundTimesParam, 20)
end

function SetBetMinText(betMinParam)
    mRoomInfo.BetMinText.text = tostring(betMinParam)
end

function SetBetMaxText(betMaxParam)
    mRoomInfo.BetMaxText.text = tostring(betMaxParam)
end

---------------------------------------------------------------------------------
-------------------------------按钮响应 call-------------------------------------
-- 菜单按钮 call
function OnCaidanButtonClick()
    -- body
    SetCaidanShow(true)
end

-- 菜单组件隐藏
function OnCaidanHideClick()
    -- body
    SetCaidanShow(false)
end

-- 菜单组件显示设置
function SetCaidanShow(showParam)
    -- body
    if mReturnCaiDan.activeSelf == showParam then
        return
    end
    mReturnCaiDan:SetActive(showParam)
end

-- 推出游戏按钮 call
function OnQuitGameButtonClick()
    -- body
    SetCaidanShow(false)
    NetMsgHandler.Send_CS_JH_Exit_Room(GameData.RoomInfo.CurrentRoom.RoomID)
end

-- 站起按钮 call
function OnSitUpButtonClick()
    -- body
    print("站起按钮点击")
    SetCaidanShow(false)


end

-- 邀请按钮call
function OnYQButtonClick(positionParam)
    if positionParam == 1 then

    elseif positionParam == 2 then

    elseif positionParam == 3 then

    elseif positionParam == 4 then

    else

    end

    print('-----positionParam:' .. positionParam)
    -- TODO 测试 模拟下注
    local ChallengeWinnerPosition = positionParam
    local ChallengerBetValue = 100
    local betChipEventArg = { PositionValue = ChallengeWinnerPosition, BetValue = ChallengerBetValue }
    CS.EventDispatcher.Instance:TriggerEvent(EventDefine.NotifyZUJUBettingEvent, betChipEventArg)

end

-------------------------------按钮 call end--------------------------------------------------

function ResetGameToRoomState(currentState)
    canPlaySoundEffect = false
    -- 停止掉所有的协程
    this:StopAllDelayInvoke()
    InitRoomBaseInfos()
    RefreshGameRoomToEnterGameState(currentState, true)
    canPlaySoundEffect = true
end

-- 游戏状态切换
function RefreshGameByRoomStateSwitchTo(roomState)
    RefreshGameRoomToEnterGameState(roomState, false)
end

-- 刷新游戏房间到游戏状态
function RefreshGameRoomToEnterGameState(roomState, isInit)
    print(string.format('*****当前游戏状态:%d 初始化:%s', roomState, lua_BOLEAN_String(isInit)))

    if isInit or roomState == ZUJURoomState.Wait then
        -- 调用下GC回收
        lua_Call_GC()
    end
    RefreshStartPartOfGameByRoomState(roomState)
    RefreshWaitPartOfGameByRoomState(roomState, isInit)
    RefreshSubduceBetPartOfGameByRoomState(roomState, isInit)
    RefreshDealPartOfGameByRoomState(roomState, isInit)
    RefreshBettingPartOfGameByRoomState(roomState, isInit)
    RefreshCardVSPartOfGameByRoomState(roomState, isInit)
    RefreshSettlementPartOfGameByRoomState(roomState, isInit)
end

-- 初始化房间到初始状态
function InitRoomBaseInfos(roomStateParam)
    -- 座位信息设置
    for position = 1, 5, 1 do
        ResetPlayerInfo2Defaul(position)
        SetPlayerSitdownState(position)
        SetPlayerBaseInfo(position)
    end
    SetRoomBaseInfo()
end

-- 游戏状态变化音效播放接口
function PlaySoundEffect(musicid)
    if true == canPlaySoundEffect then
        MusicMgr:PlaySoundEffect(musicid)
    end
end

-- ===============【等待开局】【1】ZUJURoomState.Start===============--
-- 等待游戏开局
function RefreshStartPartOfGameByRoomState(roomStateParam, initParam)
    -- body
    if roomStateParam == ZUJURoomState.Start then
        -- body
        for position = 1, 5, 1 do
            ResetPlayerInfo2Defaul(position)
            SetPlayerSitdownState(position)
            SetPlayerBaseInfo(position)
        end
    end
end

-- ===============【等待准备】【2】 ZUJURoomState.Wait===============--

function RefreshWaitPartOfGameByRoomState(roomStateParam, initParam)
    -- body
    if roomStateParam == ZUJURoomState.Wait then
        -- body
        for position = 1, 5, 1 do
            local PlayerData = GameData.RoomInfo.CurrentRoom.ZUJUPlayers[position]
            local PlayerState = PlayerData.PlayerState
            if PlayerState == Player_State.JoinOK then
                -- body
                mPlayersUIInfo[position].ZBImage.gameObject:SetActive(PlayerData.ReadyState == 1)
            end
        end
        RefreshZBButtonShow()

        SetRoomBaseInfo()
    else
        -- 准备状态还原
        for position = 1, 5, 1 do
            local PlayerState = GameData.RoomInfo.CurrentRoom.ZUJUPlayers[position].PlayerState
            mPlayersUIInfo[position].ZBImage.gameObject:SetActive(false)
        end
        SetZBButtonShow(false)
    end

end

-- 玩家准备按钮call
function OnZBButtonClick()
    NetMsgHandler.Send_CS_JH_Ready(1)
end

-- 准备按钮显示设置
function SetZBButtonShow(showParam)
    if mMasterXZInfo.ZBButtonGameObject.activeSelf == showParam then
        return
    end
    mMasterXZInfo.ZBButtonGameObject:SetActive(showParam)
end

-- 刷新准备按钮显示
function RefreshZBButtonShow()
    local selfState = GameData.RoomInfo.CurrentRoom.ZUJUPlayers[5].PlayerState
    print('主角玩家状态:' .. selfState)
    if selfState == Player_State.JoinOK then
        SetZBButtonShow(true)
    else
        SetZBButtonShow(false)
    end
end

-- 通知玩家准备状态
function OnNotifyZUJUPlayerReadyStateEvent(positionParam)
    if positionParam == 5 then
        SetZBButtonShow(false)
    end
    local ReadyState = GameData.RoomInfo.CurrentRoom.ZUJUPlayers[positionParam].ReadyState
    print(string.format('玩家：%d 准备状态:%d', positionParam, ReadyState))

    mPlayersUIInfo[positionParam].ZBImage.gameObject:SetActive(ReadyState == 1)
end


-- ===============【收取底注】【3】 ZUJURoomState.SubduceBet===============--

function RefreshSubduceBetPartOfGameByRoomState(roomStateParam, initParam)
    -- body
    if roomStateParam == ZUJURoomState.SubduceBet then

    elseif roomStateParam > ZUJURoomState.SubduceBet and initParam == true then
        -- 收取底注状态之后进入游戏

    else

    end
end

-- 押注筹码到桌子上
function BetChipToDesk(betValueParam, positionParam)
    local startPoint = nil
    startPoint = CHIP_START[positionParam]
    local betType = GameData.GetZUJUBettingLevel(betValueParam)
    CastChipToBetArea(betType, betValueParam, tostring(positionParam), true, startPoint.position)

    -- 押注筹码音效
    PlaySoundEffect(5)
end

-- 向押注区域投掷筹码
function CastChipToBetArea(areaType, chipValue, chipName, isAnimation, fromWorldPoint)
    local model = CHIP_RES[areaType]
    if model ~= nil then
        local betChip = CS.UnityEngine.Object.Instantiate(model)
        betChip.gameObject.name = chipName
        betChip:Find('Text'):GetComponent('Text').text = tostring(chipValue)
        local areaInfo = CHIP_JOINTS[areaType]
        CS.Utility.ReSetTransform(betChip, areaInfo.JointPoint)
        local toLocalPoint = lua_RandomXYOfVector3(areaInfo.RangeX.Min, areaInfo.RangeX.Max, areaInfo.RangeY.Min, areaInfo.RangeY.Max)
        betChip.gameObject:SetActive(true)
        if isAnimation then
            betChip.position = fromWorldPoint
            local script = betChip:GetComponent("TweenPosition")
            script.from = betChip.localPosition
            script.to = toLocalPoint
            script.worldSpace = false
            script:ResetToBeginning()
            script:Play(true)
        else
            betChip.localPosition = toLocalPoint
        end
    end
end

-- 玩家下注通知call
function OnNotifyZUJUBettingEvent(eventArgs)
    print(string.format('****12*****玩家:%d 下注:%f', eventArgs.PositionValue, eventArgs.BetValue))
    BetChipToDesk(eventArgs.BetValue, eventArgs.PositionValue)
    SetBetAllValueText(GameData.RoomInfo.CurrentRoom.BetAllValue)
    SetPlayerBetValueText(eventArgs.PositionValue)
end

-- 设置玩家下注金额
function SetPlayerBetValueText(positionParam)
    if positionParam == 0 then
        return
    end
    if mPlayersUIInfo[positionParam].BetingInfo.gameObject.activeSelf == false then
        mPlayersUIInfo[positionParam].BetingInfo.gameObject:SetActive(true)
    end
    local playerData = GameData.RoomInfo.CurrentRoom.ZUJUPlayers[positionParam]
    mPlayersUIInfo[positionParam].BetingText.text = tostring(playerData.BetChipValue)

end

-- ===============【洗牌发牌】【4】 ZUJURoomState.Deal===============--

function RefreshDealPartOfGameByRoomState(roomStateParam, initParam)
    -- body
    if roomStateParam == ZUJURoomState.Deal then

        PlayDealAnimation()
    else

    end
end

-- 发牌动画
function PlayDealAnimation()
    -- 可以播放发牌动画的玩家
    local ZUJUPlayers = GameData.RoomInfo.CurrentRoom.ZUJUPlayers
    local tResetPosition = { }
    for index = 5, 1, -1 do
        if Player_State.JoinOK == ZUJUPlayers[index].PlayerState then
            table.insert(tResetPosition, index)
        end
    end

    -- 顺序3张牌排列
    local cardIndex = 15
    for pos = 1, 3, 1 do
        for k1, v1 in pairs(tResetPosition) do
            -- 位置重置中心
            CS.Utility.ReSetTransform(mPlayersUIInfo[v1].PokerCards[pos], mPokerCardPoints[cardIndex])
            cardIndex = cardIndex - 1
        end
    end

    -- 发牌顺序位置
    local tcanPlayAnimationPosition = { }
    for index = 1, 5, 1 do
        if Player_State.JoinOK == ZUJUPlayers[index].PlayerState then
            table.insert(tcanPlayAnimationPosition, index)
        end
    end
    -- 按序发牌
    local delayTime = 0
    local cardPointIndex = 15
    for pokerIndex = 1, 3, 1 do

        for k1, v1 in pairs(tcanPlayAnimationPosition) do
            -- print(string.format('发牌序列:%d_%d', v1, pokerIndex))
            SetPokerCardShow(v1, pokerIndex, true)
            SetTablePokerCardVisible(mPlayersUIInfo[v1].PokerCards[pokerIndex], false)

            delayTime = delayTime + 0.1
            this:DelayInvoke(delayTime,
            function()
                local cardItem = mPlayersUIInfo[v1].PokerCards[pokerIndex]
                lua_Clear_AllUITweener(cardItem)

                if cardItem.gameObject.activeSelf == false then
                    cardItem.gameObject:SetActive(true)
                end

                local pokerCard = ZUJUPlayers[v1].PokerList[pokerIndex]
                local script = cardItem.gameObject:AddComponent(typeof(CS.TweenTransform))
                script.from = mPokerCardPoints[cardPointIndex]
                script.to = mPlayersUIInfo[v1].PokerPoints[pokerIndex]
                script.duration = 0.4
                script:OnFinished("+",
                ( function()
                    CS.UnityEngine.Object.Destroy(script)
                    if pokerCard.PokerNumber > 0 then
                        cardItem:GetComponent("Image"):ResetSpriteByName(GameData.GetPokerCardSpriteName(pokerCard))
                    end
                    SetTablePokerCardVisible(cardItem, pokerCard.Visible)
                    CS.Utility.ReSetTransform(cardItem, mPlayersUIInfo[v1].PokerPoints[pokerIndex])
                    -- lua_Paste_Transform_Value(cardItem, script.to)
                end ))
                script:Play(true)
                -- 音效发牌音效
                PlaySoundEffect(20122)
            end )

            cardPointIndex = cardPointIndex - 1

        end

    end
end

-- ===============【下注阶段】【5】 ZUJURoomState.Betting===============--

function RefreshBettingPartOfGameByRoomState(roomStateParam, initParam)
    -- body
    if roomStateParam == ZUJURoomState.Betting then
        SetRounTimesText(GameData.RoomInfo.CurrentRoom.RoundTimes)
        RefreshMasterBetState()
        RefreshCurrentBetingCD()
        SetBetAllValueText(GameData.RoomInfo.CurrentRoom.BetAllValue)
        SetRounTimesText(GameData.RoomInfo.CurrentRoom.RoundTimes)
    else
        mISUpdateBetingCD = false
        ResetCurrentBettingCDShow()
        MasterXZButtonShow(false)
        MasterJZInfoShow(false)
    end
end

-- 刷新玩家下注状态
function RefreshMasterBetState()
    print('*****当前下注玩家:' .. GameData.RoomInfo.CurrentRoom.BettingPosition)

    -- 玩家是否已经弃牌
    if GameData.RoomInfo.CurrentRoom.ZUJUPlayers[5].DropCardState == 1 then
        MasterXZButtonShow(false)
        return
    end

    MasterXZButtonShow(true)
    MasterJZInfoShow(false)

    if GameData.RoomInfo.CurrentRoom.BettingPosition == 5 then
        -- 自己下注处理
        mMasterXZInfo.QPButtonGameObject:SetActive(true)
        mMasterXZInfo.JZButtonGameObject1:SetActive(true)
        mMasterXZInfo.GZButtonGameObject:SetActive(true)
        mMasterXZInfo.BPButtonGameObject:SetActive(true)
    else
        -- 他人下注处理
        mMasterXZInfo.QPButtonGameObject:SetActive(true)
        mMasterXZInfo.JZButtonGameObject1:SetActive(false)
        mMasterXZInfo.GZButtonGameObject:SetActive(false)
        mMasterXZInfo.BPButtonGameObject:SetActive(false)
    end
end



-- 刷新玩家下注倒计时CD
function RefreshCurrentBetingCD()
    local BettingPosition = GameData.RoomInfo.CurrentRoom.BettingPosition
    if BettingPosition > 0 then
        mCurrentHandleCD = mPlayersUIInfo[BettingPosition].HandleCD
        mISUpdateBetingCD = true
        for position = 1, 5, 1 do
            mPlayersUIInfo[position].HandleCD.gameObject:SetActive(position == BettingPosition)
        end
    else
        error('当前下注玩家位置:0有误')
    end
end

function UpdateCurrentBettingCD()
    if false == mISUpdateBetingCD then
        return
    end
    if mCurrentHandleCD == nil then
        return
    end

    if mCurrentHandleCD.gameObject.activeSelf == false then
        mCurrentHandleCD.gameObject:SetActive(true)
    end
    local countDown = GameData.RoomInfo.CurrentRoom.CountDown
    local maxValue = ZUJUROOM_TIME[ZUJURoomState.Betting]
    if countDown < 0 then
        countDown = 0
    end
    local fillAmount = countDown / maxValue
    mCurrentHandleCD.fillAmount = fillAmount

    -- 颜色设置
    --[[
    if fillAmount > 0.63 then
        mCurrentHandleCD.color = m_CheckColorOf1
    elseif fillAmount > 0.38 then
        mCurrentHandleCD.color = m_CheckColorOf2
    else
        mCurrentHandleCD.color = m_CheckColorOf3
    end
    ]]
end

-- CD显示还原
function ResetCurrentBettingCDShow()
    local BettingPosition = GameData.RoomInfo.CurrentRoom.BettingPosition
    if BettingPosition > 0 then
        mPlayersUIInfo[BettingPosition].HandleCD.gameObject:SetActive(false)
    end
end

-- ===============弃牌、加注、跟注、比牌===============--

-- 玩家弃牌按钮call
function OnQPButtonClick()
    -- body
    print('弃牌按钮点击')
    NetMsgHandler.Send_CS_JH_Drop_Card()
end

-- 玩家加注按钮call
function OnJZButtonClick()
    -- body
    print('加注按钮点击')
    MasterJZInfoShow(true)
    local mingBet = 0
    local darkBet = 0

    if GameData.RoomInfo.CurrentRoom.ZUJUPlayers[5].LookState == 0 then

    else

    end

    for index = 1, 4, 1 do
        mingBet, darkBet = GameData.GetZUJUBettingValue(index + 1)
        if GameData.RoomInfo.CurrentRoom.ZUJUPlayers[5].LookState == 0 then
            mMasterXZInfo.JZButtonTexts[index].text = tostring(mingBet)
        else
            mMasterXZInfo.JZButtonTexts[index].text = tostring(darkBet)
        end
    end

end

function SetJZButtonBetValueText(level)

end

-- 玩家跟注按钮call
function OnGZButtonClick()
    -- body
    print('跟注按钮点击')
    local bettingValue = 0
    if GameData.RoomInfo.CurrentRoom.ZUJUPlayers[5].LookState == 0 then
        bettingValue = GameData.RoomInfo.CurrentRoom.DarkCardBetMin
    else
        bettingValue = GameData.RoomInfo.CurrentRoom.MingCardBetMin
    end

    TrySend_CS_JH_Betting(1, bettingValue)
end

-- 玩家比牌按钮call
function OnBPButtonClick()
    -- body
    print("玩家比牌按钮点击")

    local vsCount, playerID = CheckVSCard()

    if vsCount > 1 then
        for index = 1, 4, 1 do
            local playerData = GameData.RoomInfo.CurrentRoom.ZUJUPlayers[index]
            if playerData.PlayerState == Player_State.JoinOK then
                if playerData.CompareResult == 1 or playerData.DropCardState == 1 then
                    -- 玩家已经弃牌
                else
                    mPlayersUIInfo[index].VSOKButtonGameObject:SetActive(true)
                end
            end
        end
    elseif vsCount == 1 then
        NetMsgHandler.Send_CS_JH_VS_Card(playerID, 1)
    else
        -- TODO 此刻应该进入比牌阶段
    end
end

-- 检查可以参与比牌的玩家数量
function CheckVSCard()
    local count = 0
    local playerID = 0
    for index = 1, 4, 1 do
        local playerData = GameData.RoomInfo.CurrentRoom.ZUJUPlayers[index]
        if playerData.PlayerState == Player_State.JoinOK then
            if playerData.CompareResult == 1 or playerData.DropCardState == 1 then
                -- 玩家已经弃牌
                CS.BubblePrompt.Show('玩家已经弃牌，请重新选择.', "GameUI1")
            else
                count = count + 1
                playerID = playerData.AccountID
            end
        end
    end
    return count, playerID
end


-- 选择比牌玩家call
function OnVSOKButtonOnclick(positionParam)
    -- 还原状态
    for index = 1, 4, 1 do
        mPlayersUIInfo[index].VSOKButtonGameObject:SetActive(false)
    end
    local playerData = GameData.RoomInfo.CurrentRoom.ZUJUPlayers[positionParam]
    if playerData.PlayerState == Player_State.JoinOK then
        if playerData.CompareResult == 1 or playerData.DropCardState == 1 then
            -- 玩家已经弃牌
        else
            NetMsgHandler.Send_CS_JH_VS_Card(playerData.AccountID, 1)
        end
    end
end

-- 玩家加注隐藏按钮call
function OnJZHideClick()
    -- body
    print("玩家加注隐藏点击")
    MasterJZInfoShow(false)
end

-- 加注筹码选择call
function OnJZButtonOKClick(jiazhuParam)
    -- body
    print('加注筹码:' .. jiazhuParam)

    local betValue = 10
    local mingBet, darkBet = GameData.GetZUJUBettingValue(jiazhuParam)
    local canJiaZhu = true

    if GameData.RoomInfo.CurrentRoom.ZUJUPlayers[5].LookState == 0 then
        betValue = mingBet
        if darkBet < GameData.RoomInfo.CurrentRoom.DarkCardBetMin then
            canJiaZhu = false
        end
    else
        betValue = darkBet
        -- 所需筹码不是
        if mingBet < GameData.RoomInfo.CurrentRoom.MingCardBetMin then
            canJiaZhu = false
        end
    end

    if canJiaZhu == true then
        TrySend_CS_JH_Betting(2, betValue)
    else
        print('所选筹码非加注筹码')
    end
end

-- 尝试下注请求
function TrySend_CS_JH_Betting(betType, betValue)
    --[[
    if GameData.RoleInfo.GoldCount < betValue then
        -- 金币不足
        CS.BubblePrompt.Show(data.GetString("金币不足,无法下注"), "GameUI1")
        return
    end
    ]]
    NetMsgHandler.Send_CS_JH_Betting(GameData.RoomInfo.CurrentRoom.RoomID, betType, betValue)
end




-- 下注按钮显示设置
function MasterXZButtonShow(showParam)
    -- body
    if mMasterXZInfo.XZButtonGameObject.activeSelf == showParam then
        return
    end
    mMasterXZInfo.XZButtonGameObject:SetActive(showParam)
end

-- 加注模块显示设置
function MasterJZInfoShow(showParam)
    -- body
    if mMasterXZInfo.JZButtonGameObject.activeSelf == showParam then
        return
    end
    -- body
    mMasterXZInfo.JZButtonGameObject:SetActive(showParam)
end

-- 玩家自己筹码组件显示
function MasterCMImageGameObjectShow(showParam)
    if mMasterXZInfo.CMImageGameObject.activeSelf == showParam then
        return
    end
    mMasterXZInfo.CMImageGameObject:SetActive(showParam)
end


-- 玩家弃牌通知
function OnNotifyZUJUDropCardEvent(positionParam)
    print('弃牌玩家:' .. positionParam)
    mPlayersUIInfo[positionParam].QPImage.gameObject:SetActive(true)
    -- 弃牌音效
    PlaySoundEffect(123)
end


-- =============================玩家看牌模块============================================

-- 开牌按钮显示设置
function MasterKPButtonShow(showParam)
    -- body
    if mMasterXZInfo.KPButtonGameObject.activeSelf == showParam then
        return
    end
    mMasterXZInfo.KPButtonGameObject:SetActive(showParam)
end

-- 通知玩家已经看牌
function OnNotifyZUJULookCardEvent(positionParam)

    mPlayersUIInfo[positionParam].KPImage.gameObject:SetActive(true)
    if positionParam == 5 then
        -- 自己看牌 需要显示牌面
    end
end


-- ===============【比牌阶段】【6】 ZUJURoomState.CardVS===============--


function RefreshCardVSPartOfGameByRoomState(roomStateParam, initParam)
    -- body
    if roomStateParam == ZUJURoomState.CardVS then
        VSPKShow(true)
        PlayCardVSAnimation()
    else
        VSPKShow(false)
    end
end

-- 设置VSPK显示
function VSPKShow(showParam)
    -- body
    if mVSPK.activeSelf == showParam then
        return
    end
    mVSPK:SetActive(showParam)
    if showParam == false then
        mVSPKTable.FailImage1.gameObject:SetActive(false)
        mVSPKTable.FailImage2.gameObject:SetActive(false)
    end
end

-- 播放比牌动画
function PlayCardVSAnimation()
    this:DelayInvoke(0, function() PlayCardVSAnimationStep1() end)
    this:DelayInvoke(0.5, function() PlayCardVSAnimationStep2() end)
    this:DelayInvoke(1.0, function() SetCardVSResult() end)
end

-- PK动画第一步
function PlayCardVSAnimationStep1()
    local ChallengerPosition = GameData.RoomInfo.CurrentRoom.ChallengerPosition
    local ActorPosition = GameData.RoomInfo.CurrentRoom.ActorPosition

    mPlayersUIInfo[ChallengerPosition].TransformRoot:SetActive(false)
    mPlayersUIInfo[ActorPosition].TransformRoot:SetActive(false)

    -- 玩家1
    SetChallengerInfo(mVSPKTable.PKPlayer1, ChallengerPosition)
    -- 玩家2
    SetChallengerInfo(mVSPKTable.PKPlayer2, ActorPosition)
    -- 还原默认状态
    mVSPKTable.FailImage1.gameObject:SetActive(false)
    mVSPKTable.FailImage2.gameObject:SetActive(false)

    local tweenScript1 = mVSPKTable.PKPlayer1:GetComponent('TweenTransform')
    tweenScript1:ResetToBeginning()
    tweenScript1.from = mVSPKTable.PKPos[ChallengerPosition]
    tweenScript1.to = mVSPKTable.PKPosTargets[1]
    tweenScript1:Play(true)

    local tweenScript2 = mVSPKTable.PKPlayer2:GetComponent('TweenTransform')
    tweenScript2:ResetToBeginning()
    tweenScript2.from = mVSPKTable.PKPos[ActorPosition]
    tweenScript2.to = mVSPKTable.PKPosTargets[2]
    tweenScript2:Play(true)

    mVSPKTable.PKVImage.gameObject:SetActive(false)
    mVSPKTable.PKSImage.gameObject:SetActive(false)

end

function PlayCardVSAnimationStep2()
    mVSPKTable.PKVImage.gameObject:SetActive(true)
    mVSPKTable.PKSImage.gameObject:SetActive(true)

    local tweenPosition1 = mVSPKTable.PKVImage:GetComponent('TweenPosition')
    tweenPosition1:ResetToBeginning()
    tweenPosition1:Play(true)

    local tweenPosition2 = mVSPKTable.PKSImage:GetComponent('TweenPosition')
    tweenPosition2:ResetToBeginning()
    tweenPosition2:Play(true)

end


-- 设置挑战者基础信息
function SetChallengerInfo(target, positionParam)
    local playerData = GameData.RoomInfo.CurrentRoom.ZUJUPlayers[positionParam]
    local head1 = target:Find('HeadIcon'):GetComponent('Image')
    head1:ResetSpriteByName(GameData.GetRoleIconSpriteName(playerData.IconID), false)
    target:Find('Text'):GetComponent('Text').text = playerData.Name
end


-- 设置比牌结果
function SetCardVSResult()
    local ChallengerPosition = GameData.RoomInfo.CurrentRoom.ChallengerPosition
    local ActorPosition = GameData.RoomInfo.CurrentRoom.ActorPosition
    local ChallengeWinnerPosition = GameData.RoomInfo.CurrentRoom.ChallengeWinnerPosition

    if ChallengerPosition == ChallengeWinnerPosition then
        mVSPKTable.FailImage1.gameObject:SetActive(false)
        mVSPKTable.FailImage2.gameObject:SetActive(true)
    else
        mVSPKTable.FailImage1.gameObject:SetActive(true)
        mVSPKTable.FailImage2.gameObject:SetActive(false)
    end

    -- 玩家信息还原
    local ChallengerPosition = GameData.RoomInfo.CurrentRoom.ChallengerPosition
    local ActorPosition = GameData.RoomInfo.CurrentRoom.ActorPosition
    mPlayersUIInfo[ChallengerPosition].TransformRoot:SetActive(true)
    mPlayersUIInfo[ActorPosition].TransformRoot:SetActive(true)
end

-- ===============【结算阶段】【7】 ZUJURoomState.Settlement===============--

function RefreshSettlementPartOfGameByRoomState(roomStateParam, initParam)
    -- body
    if roomStateParam == ZUJURoomState.Settlement then

    else

    end
end



-- ==============================================================================

-- 添加一个玩家
function OnNotifyZUJUAddPlayerEvent(positionParam)
    ResetPlayerInfo2Defaul(positionParam)
    SetPlayerSitdownState(positionParam)
    SetPlayerBaseInfo(positionParam)
end

-- 删除某个玩家
function OnNotifyZUJUDeletePlayerEvent(positionParam)
    ResetPlayerInfo2Defaul(positionParam)
    ResetPlayerCardToDefault(positionParam)
end


-- ===============================================================================
-- 模拟测试模块

function Test1()
    this.transform:Find('Canvas/TestButtons/Button1'):GetComponent('Button').onClick:AddListener( function() OnTestButtonsClick(1) end)
    this.transform:Find('Canvas/TestButtons/Button2'):GetComponent('Button').onClick:AddListener( function() OnTestButtonsClick(2) end)
    this.transform:Find('Canvas/TestButtons/Button3'):GetComponent('Button').onClick:AddListener( function() OnTestButtonsClick(3) end)
    this.transform:Find('Canvas/TestButtons/Button4'):GetComponent('Button').onClick:AddListener( function() OnTestButtonsClick(4) end)
end

-- 测试按钮响应
function OnTestButtonsClick(indexParam)
    if indexParam == 1 then
        -- TODO 测试 房间状态变化
        local roomState = GameData.RoomInfo.CurrentRoom.RoomState
        roomState = roomState + 1
        if roomState > ZUJURoomState.Settlement then
            roomState = ZUJURoomState.Wait
        end

        if roomState == ZUJURoomState.SubduceBet then
            -- 扣除底注阶段
            for index = 1, 5, 1 do
                local ChallengeWinnerPosition = index
                local ChallengerBetValue = 100
                local betChipEventArg = { PositionValue = ChallengeWinnerPosition, BetValue = ChallengerBetValue }
                CS.EventDispatcher.Instance:TriggerEvent(EventDefine.NotifyZUJUBettingEvent, betChipEventArg)
            end
        elseif roomState == ZUJURoomState.Betting then
            -- 下注阶段
            local RoundTimes = 1
            local BettingPosition = 5
            local MingCardBetMin = 20
            local DarkCardBetMin = 10

            BettingPosition = GameData.PlayerPositionConvert2ShowPosition(BettingPosition)
            MingCardBetMin = GameConfig.GetFormatColdNumber(MingCardBetMin)
            DarkCardBetMin = GameConfig.GetFormatColdNumber(DarkCardBetMin)

            GameData.RoomInfo.CurrentRoom.RoundTimes = RoundTimes
            GameData.RoomInfo.CurrentRoom.BettingPosition = BettingPosition
            GameData.RoomInfo.CurrentRoom.MingCardBetMin = MingCardBetMin
            GameData.RoomInfo.CurrentRoom.DarkCardBetMin = DarkCardBetMin

        elseif roomState == ZUJURoomState.CardVS then

            -- 比牌阶段
            local ChallengerPosition = 1
            local ActorPosition = 5
            local ChallengeWinnerPosition = 5

            GameData.RoomInfo.CurrentRoom.ChallengerPosition = ChallengerPosition
            GameData.RoomInfo.CurrentRoom.ActorPosition = ActorPosition
            GameData.RoomInfo.CurrentRoom.ChallengeWinnerPosition = ChallengeWinnerPosition
            GameData.RoomInfo.CurrentRoom.BetAllValue = BetAllValue

        end

        GameData.SetZUJURoomState(roomState)
    elseif indexParam == 2 then
        local RoundTimes = GameData.RoomInfo.CurrentRoom.RoundTimes + 1
        local BettingPosition = GameData.RoomInfo.CurrentRoom.BettingPosition + 1
        local MingCardBetMin = 20
        local DarkCardBetMin = 10
        if BettingPosition > 5 then
            BettingPosition = 1
        end

        GameData.RoomInfo.CurrentRoom.RoundTimes = RoundTimes
        GameData.RoomInfo.CurrentRoom.BettingPosition = BettingPosition
        GameData.RoomInfo.CurrentRoom.MingCardBetMin = MingCardBetMin
        GameData.RoomInfo.CurrentRoom.DarkCardBetMin = DarkCardBetMin
        print("*****测试下注玩家:" .. GameData.RoomInfo.CurrentRoom.BettingPosition)

        GameData.SetZUJURoomState(ZUJURoomState.Betting)
    elseif indexParam == 3 then
        -- 比牌阶段
        local ChallengerPosition = 1
        local ActorPosition = 3
        local ChallengeWinnerPosition = 3

        GameData.RoomInfo.CurrentRoom.ChallengerPosition = ChallengerPosition
        GameData.RoomInfo.CurrentRoom.ActorPosition = ActorPosition
        GameData.RoomInfo.CurrentRoom.ChallengeWinnerPosition = ChallengeWinnerPosition
        GameData.RoomInfo.CurrentRoom.BetAllValue = BetAllValue
        GameData.SetZUJURoomState(ZUJURoomState.CardVS)
    elseif indexParam == 4 then
        -- 结算阶段
        local winnerCount = 3

        for index = 1, winnerCount, 1 do
            local WinnerPosition = index
            local WinGoldValue = index * 10000
            local GoldValue = index * 20000

            WinnerPosition = GameData.PlayerPositionConvert2ShowPosition(WinnerPosition)
            WinGoldValue = GameConfig.GetFormatColdNumber(WinGoldValue)
            GoldValue = GameConfig.GetFormatColdNumber(GoldValue)

            GameData.RoomInfo.CurrentRoom.ZUJUPlayers[WinnerPosition].GoldValue = GoldValue
            GameData.RoomInfo.CurrentRoom.ZUJUPlayers[WinnerPosition].WinGoldValue = WinGoldValue
            GameData.RoomInfo.CurrentRoom.ZUJUPlayers[WinnerPosition].IsWinner = true
        end
        -- 本局自己客户端需要量牌玩家
        local showCount = 5
        for showIndex = 1, showCount, 1 do
            local position = showIndex
            position = GameData.PlayerPositionConvert2ShowPosition(position)
            GameData.RoomInfo.CurrentRoom.ZUJUPlayers[position].IsShowPokerCard = true
        end
        GameData.SetZUJURoomState(ZUJURoomState.Settlement)
    end

end


