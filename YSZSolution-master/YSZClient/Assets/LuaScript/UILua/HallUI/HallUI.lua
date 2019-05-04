-- 选择的房间ID
-- 房间类型1(竞咪厅) 偏移量
local RoomType1Offset = 0
-- 房间类型2(试水厅) 偏移量
local RoomType2Offset = 200
-- 聚龙厅房间列表
local mJuLongRooms = { }

local IsUpDate = true

function Awake()
    -- 玩家信息响应
    this.transform:Find('Canvas/RoleInfo/Gold'):GetComponent("Button").onClick:AddListener(AddGoldButtonOnClick)
    this.transform:Find('Canvas/RoleInfo/RoomCard/Icon'):GetComponent("Button").onClick:AddListener(AddRoomCardButtonOnClick)
    this.transform:Find('Canvas/RoleInfo/Diamond/Icon'):GetComponent("Button").onClick:AddListener(AddDiamondButton_OnClick)
    this.transform:Find('Canvas/RoleInfo/RoleIcon'):GetComponent("Button").onClick:AddListener(HallUI_HeadIconOnClick)
    -- 底部区域功能区域按钮
    this.transform:Find('Canvas/Bottom/ButtonStore'):GetComponent("Button").onClick:AddListener(StoreButtonOnClick)
    this.transform:Find('Canvas/Bottom/ButtonMail'):GetComponent("Button").onClick:AddListener(MailButtonOnClick)
    this.transform:Find('Canvas/Bottom/ButtonRank'):GetComponent("Button").onClick:AddListener(RankButtonOnClick)
    this.transform:Find('Canvas/Bottom/ButtonSetting'):GetComponent("Button").onClick:AddListener(SettingButtonOnClick)
    this.transform:Find('Canvas/Bottom/GameStart'):GetComponent("Button").onClick:AddListener(OnGameStartButtonOnClick)

    this.transform:Find('Canvas/Room3/Room2DetailInfo/Content/CreateRoom'):GetComponent("Button").onClick:AddListener(CreateVipRoomButtonOnClick)
    this.transform:Find('Canvas/Room3/Room2DetailInfo/Content/JoinRoom'):GetComponent("Button").onClick:AddListener(JoinVipRoomButtonOnClick)

    this.transform:Find('Canvas/Center/Room1'):GetComponent("Button").onClick:AddListener( function() EnterSelectedRoom(1) end)
    this.transform:Find('Canvas/Center/Room2'):GetComponent("Button").onClick:AddListener( function() EnterSelectedRoom(2) end)
    this.transform:Find('Canvas/Center/Room3'):GetComponent("Button").onClick:AddListener( function() EnterSelectedRoom(3) end)
    this.transform:Find('Canvas/Room1/LeftArrow'):GetComponent("Button").onClick:AddListener( function() EnterSelectedRoom(0) end)
    this.transform:Find('Canvas/Room2/LeftArrow'):GetComponent("Button").onClick:AddListener( function() EnterSelectedRoom(0) end)
    this.transform:Find('Canvas/Room3/LeftArrow'):GetComponent("Button").onClick:AddListener( function() EnterSelectedRoom(0) end)

    -- 其他功能响应
    this.transform:Find('Canvas/Center/BenefitButton'):GetComponent("Button").onClick:AddListener(BenefitButtonOnClick)
    this.transform:Find('Canvas/Center/SevenDayButton'):GetComponent("Button").onClick:AddListener(SevenDayButtonOnClick)

    -- 经典厅 房间响应
    this.transform:Find('Canvas/Room2/RoomInfo1'):GetComponent("Button").onClick:AddListener( function() EnterJingDianRoom(1) end)
    this.transform:Find('Canvas/Room2/RoomInfo2'):GetComponent("Button").onClick:AddListener( function() EnterJingDianRoom(2) end)
    this.transform:Find('Canvas/Room2/RoomInfo3'):GetComponent("Button").onClick:AddListener( function() EnterJingDianRoom(3) end)
    this.transform:Find('Canvas/Room2/RoomInfo4'):GetComponent("Button").onClick:AddListener( function() EnterJingDianRoom(4) end)


    InitHallUIRoomTypeInfo()
end

function RefreshWindowData(windowData)
    -- body
    RefreshHallUIByWindowData(windowData)
end

function WindowOpened()
    CS.EventDispatcher.Instance:AddEventListener(tostring(ProtrocolID.S_Update_Gold), UpdateRoleInfos)
    CS.EventDispatcher.Instance:AddEventListener(tostring(ProtrocolID.S_Update_Diamond), UpdateRoleInfos)
    CS.EventDispatcher.Instance:AddEventListener(tostring(ProtrocolID.S_Update_RoomCard), UpdateRoleInfos)
    CS.EventDispatcher.Instance:AddEventListener(tostring(ProtrocolID.S_Update_Charge), UpdateRoleInfos)
    CS.EventDispatcher.Instance:AddEventListener(tostring(ProtrocolID.CS_Request_Relative_Room), UpdateRelationRoomList)
    CS.EventDispatcher.Instance:AddEventListener(EventDefine.NotifyHeadIconChange, NotifyHeadIconChange)
    CS.EventDispatcher.Instance:AddEventListener(EventDefine.NotifyChangeAccountName, HandleNotifyChangeAccountName)
    CS.EventDispatcher.Instance:AddEventListener(EventDefine.UpdateStatistics, HandleUpdateStatisticsInfo)
    CS.EventDispatcher.Instance:AddEventListener(EventDefine.UpdateUnHandleFlag, HandleUpdateUnHandleFlagEvent)
    HandleRoomTypeChanged(GameData.HallData.SelectType)
end

function WindowClosed()
    CS.EventDispatcher.Instance:RemoveEventListener(tostring(ProtrocolID.S_Update_Gold), UpdateRoleInfos)
    CS.EventDispatcher.Instance:RemoveEventListener(tostring(ProtrocolID.S_Update_Diamond), UpdateRoleInfos)
    CS.EventDispatcher.Instance:RemoveEventListener(tostring(ProtrocolID.S_Update_RoomCard), UpdateRoleInfos)
    CS.EventDispatcher.Instance:RemoveEventListener(tostring(ProtrocolID.S_Update_Charge), UpdateRoleInfos)
    CS.EventDispatcher.Instance:RemoveEventListener(tostring(ProtrocolID.CS_Request_Relative_Room), UpdateRelationRoomList)
    CS.EventDispatcher.Instance:RemoveEventListener(EventDefine.NotifyHeadIconChange, NotifyHeadIconChange)
    CS.EventDispatcher.Instance:RemoveEventListener(EventDefine.NotifyChangeAccountName, HandleNotifyChangeAccountName)
    CS.EventDispatcher.Instance:RemoveEventListener(EventDefine.UpdateStatistics, HandleUpdateStatisticsInfo)
    CS.EventDispatcher.Instance:RemoveEventListener(EventDefine.UpdateUnHandleFlag, HandleUpdateUnHandleFlagEvent)
end

function RefreshHallUIByWindowData(windowData)
    this.transform:Find('Canvas/RoleInfo/RoleName'):GetComponent("Text").text = GameData.RoleInfo.AccountName
    this.transform:Find('Canvas/RoleInfo/Diamond/Number'):GetComponent("Text").text = lua_CommaSeperate(GameData.RoleInfo.DiamondCount)

    this.transform:Find('Canvas/RoleInfo/Gold/Number'):GetComponent("Text").text = lua_CommaSeperate(GameConfig.GetFormatColdNumber(GameData.RoleInfo.GoldCount))
    this.transform:Find('Canvas/RoleInfo/RoomCard/Number'):GetComponent("Text").text = lua_CommaSeperate(GameData.RoleInfo.RoomCardCount)
    this.transform:Find('Canvas/RoleInfo/RoleIcon'):GetComponent("Image"):ResetSpriteByName(GameData.GetRoleIconSpriteName(GameData.RoleInfo.AccountIcon))
    this.transform:Find('Canvas/RoleInfo/RoleIcon/Vip/Value'):GetComponent("Text").text = "VIP" .. GameData.RoleInfo.VipLevel
    -- 刷新未读邮件
    this.transform:Find('Canvas/Bottom/ButtonMail/Flag').gameObject:SetActive(GameData.RoleInfo.UnreadMailCount > 0)
    if (GameData.OpenInstallRoomID == nil or GameData.OpenInstallReferralsID == nil) then
        ReqOpenInstallData();
    end
end

-- 进入选中大厅
function EnterSelectedRoom(roomType)
    GameData.HallData.SelectType = roomType
    HandleRoomTypeChanged(GameData.HallData.SelectType)
end

-- 进入选中房间
function EnterSelectedGameRoom(roomIndexParam)
    local roomConfig = data.RoomConfig[roomIndexParam]
    if nil == roomConfig then
        print('聚龙厅配置错误')
        return
    end
    EnterGameRoomByRoomID(roomConfig.TemplateID)
end

-- 进入房间
function EnterGameRoomByRoomID(roomID)
    if roomID > 0 then
        NetMsgHandler.Send_CS_Enter_Room(roomID)
    end
end

-------------------------------------------------------------------------------
-------------------------------功能响应模块-------------------------------------
-- 响应商场按钮点击事件
function StoreButtonOnClick()
    OpenStoreUI()
end

-- 响应邮件按钮点击事件
function MailButtonOnClick()
    local initParam = CS.WindowNodeInitParam("UIEmail")
    initParam.WindowData = 1
    if EmailMgr:GetMailList() == nil then
        initParam.WindowData = nil
        NetMsgHandler.SendRequestEmails(0)
    end
    CS.WindowManager.Instance:OpenWindow(initParam)
end

-- 邮件数据刷新处理小红点提示
function HandleUpdateUnHandleFlagEvent(eventArg)
    -- body
    if eventArg ~= nil then
        if eventArg.UnHandleType == UNHANDLE_TYPE.EMAIL then
            this.transform:Find('Canvas/Bottom/ButtonMail/Flag').gameObject:SetActive(eventArg.ContainsUnHandle)
        end
    end
end

-- 响应排行榜按钮点击事件
function RankButtonOnClick()
    local initParam = CS.WindowNodeInitParam("UIRank")
    initParam.WindowData = 1
    CS.WindowManager.Instance:OpenWindow(initParam)
    if GameData.RankInfo.RichList == nil then
        NetMsgHandler.SendRequestRanks(1)
    else
        local dayOfyear = lua_GetTimeToYearDay()
        print("点击排行榜按钮时的日期 = " .. dayOfyear)
        if dayOfyear > GameData.RankInfo.DayOfYear then
            print("排行榜已过期，需要请求新的排行榜数据")
            NetMsgHandler.SendRequestRanks(1)
        end
    end
end

-- 响应设置按钮点击事件
function SettingButtonOnClick()
    CS.WindowManager.Instance:OpenWindow("UISetting")
end

-- 快速游戏 call
function OnGameStartButtonOnClick()
    -- TODO 测试
    GameData.InitCurrentRoomInfo(ROOM_TYPE.JH_ZuJu)
    NetMsgHandler.Send_CS_JH_Create_Room(10, 200, 1, 1, 1,321,200)
    --[[
    -- body
    local initParam = CS.WindowNodeInitParam("GameUI1")
    initParam.WindowData = 1
    CS.WindowManager.Instance:OpenWindow(initParam)
    --]]
end

-- 救济金call
function BenefitButtonOnClick()
    print('救济金call')
end

-- 新人大放送
function SevenDayButtonOnClick()
    print('新人大放送call')
end

-- 响应 创建VIP 房间按钮点击事件
function CreateVipRoomButtonOnClick()
    CS.WindowManager.Instance:OpenWindow("UICreateRoom", this.WindowNode)
end

-- 响应 加入VIP 房间按钮点击事件
function JoinVipRoomButtonOnClick()
    CS.WindowManager.Instance:OpenWindow("UIJoinRoom", this.WindowNode)
end

-- 响应 加金币按钮点击事件
function AddGoldButtonOnClick()
    OpenConvertUI(1)
end

-- 响应 加房卡按钮点击事件
function AddRoomCardButtonOnClick()
    OpenConvertUI(2)
end

-- 打开兑换界面
function OpenConvertUI(param)
    local initParam = CS.WindowNodeInitParam("UIConvert")
    initParam.WindowData = param
    CS.WindowManager.Instance:OpenWindow(initParam)
end

-- 响应 加钻石按钮点击事件
function AddDiamondButton_OnClick()
    OpenStoreUI()
end

-------------------------------------------------------------------------------
-------------------------------角色详细信息模块----------------------------------
-- 更新角色信息
function UpdateRoleInfos(param)
    this.transform:Find('Canvas/RoleInfo/RoleName'):GetComponent("Text").text = GameData.RoleInfo.AccountName
    this.transform:Find('Canvas/RoleInfo/Diamond/Number'):GetComponent("Text").text = lua_CommaSeperate(GameData.RoleInfo.DiamondCount)
    this.transform:Find('Canvas/RoleInfo/Gold/Number'):GetComponent("Text").text = lua_CommaSeperate(GameConfig.GetFormatColdNumber(GameData.RoleInfo.GoldCount))
    this.transform:Find('Canvas/RoleInfo/RoomCard/Number'):GetComponent("Text").text = lua_CommaSeperate(GameData.RoleInfo.RoomCardCount)
    this.transform:Find('Canvas/RoleInfo/RoleIcon/Vip/Value'):GetComponent("Text").text = "VIP" .. GameData.RoleInfo.VipLevel
end

-- 玩家头像变化
function NotifyHeadIconChange(icon)
    -- body
    this.transform:Find('Canvas/RoleInfo/RoleIcon'):GetComponent("Image"):ResetSpriteByName(GameData.GetRoleIconSpriteName(GameData.RoleInfo.AccountIcon))
end

-- 刷新主界面上的角色昵称
function HandleNotifyChangeAccountName()
    this.transform:Find('Canvas/RoleInfo/RoleName'):GetComponent("Text").text = GameData.RoleInfo.AccountName
end

-- 响应 头像按钮点击事件
function HallUI_HeadIconOnClick()
    local openParam = CS.WindowNodeInitParam("PlayerInfoUI")
    openParam.WindowData = 0
    CS.WindowManager.Instance:OpenWindow(openParam)
end

-- 开启商城UI
function OpenStoreUI()
    CS.WindowManager.Instance:OpenWindow("UIStore")
end

----------------------------------------------------------------------
------------------------房间类型选择----------------------------------
-- 初始化房间基础信息
function InitHallUIRoomTypeInfo()

    -- 初始化聚龙厅房间
    local roomRoot = this.transform:Find('Canvas/Room1/Room1Content/Viewport/Content')
    for index = 1, 7, 1 do
        local roomInfoItem = roomRoot:Find('Room1Info' .. index)
        mJuLongRooms[index] = roomInfoItem
        local roomConfig = data.RoomConfig[index]
        if roomConfig ~= nil then
            roomInfoItem.gameObject:SetActive(true)
            roomInfoItem:Find('back/RoomID/Value'):GetComponent("Text").text = roomConfig.ShowName
            roomInfoItem:Find('back'):GetComponent("Button").onClick:AddListener( function() EnterSelectedGameRoom(index) end)
            roomInfoItem:Find('back/ChipLimit/Value'):GetComponent("Text").text = string.format("%s-%s", lua_NumberToStyle1String(GameConfig.GetFormatColdNumber(roomConfig.BettingLongHu[1])), lua_NumberToStyle1String(GameConfig.GetFormatColdNumber(roomConfig.BettingLongHu[2])))
            for roomType = 1, 5, 1 do
                roomInfoItem:Find('back/RoomID/RoomType/RoomType' .. roomType).gameObject:SetActive(roomConfig.Type == roomType)
            end
        else
            roomInfoItem.gameObject:SetActive(false)
        end
    end
end

-- 房间类型改变刷新
function HandleRoomTypeChanged(roomType)
    local index = GameData.HallData.Data[roomType]
    this.transform:Find('Canvas/Room1').gameObject:SetActive(roomType == HALL_TYPE.JuLong)
    this.transform:Find('Canvas/Room2').gameObject:SetActive(roomType == HALL_TYPE.JinDian)
    this.transform:Find('Canvas/Room3').gameObject:SetActive(roomType == HALL_TYPE.ZuJu)
    this.transform:Find('Canvas/Center').gameObject:SetActive(roomType == HALL_TYPE.None)
    print('RoomType:' .. roomType)
    -- 刷新细节
    if roomType == HALL_TYPE.JuLong then
        HandleRoomTypeChangedToJuLongting()
    elseif roomType == HALL_TYPE.JinDian then
        HandleRoomTypeChangedToJingDianting()
    elseif roomType == HALL_TYPE.ZuJu then
        HandleRoomTypeChangedToZuJuting()
    end
    -- TryShowGuideOfRoomType(roomType)
end

-- 聚龙厅
function HandleRoomTypeChangedToJuLongting()
    -- NetMsgHandler.Send_CS_Request_Statistics(...)
    NetMsgHandler.Send_CS_Request_Statistics(1, 2, 3, 4, 5, 6, 7)
end

-- 金典厅
function HandleRoomTypeChangedToJingDianting()
    -- 免费试玩房间仅有一个，故不需要选项卡切换来请求数据
end

-- 组局厅
function HandleRoomTypeChangedToZuJuting()
    -- 传入的序号从 0开始的：计算方式（房间ID - 房间类型偏移量 - 1）

end

-- 聚龙厅 刷新详细信息部分的房间人数
function HandleUpdateStatisticsInfo(eventArgs)
    local roomID = eventArgs.RoomID
    local statistics = GameData.RoomInfo.StatisticsInfo[roomID]
    local roleCount = 0
    if statistics ~= nil and mJuLongRooms[roomID] ~= nil then
        -- 刷新房间路单信息
        local trendScrpit = mJuLongRooms[roomID]:Find('back/HallUIStatisticsAreaHandle'):GetComponent("LuaBehaviour").LuaScript
        trendScrpit.ResetRelativeRoomID(roomID)
        roleCount = statistics.Counts.RoleCount
        mJuLongRooms[roomID]:Find('back/RoleCount/Value'):GetComponent('Text').text = tostring(roleCount)
    end
end

-- VIP厅刷新关联的房间列表
function UpdateRelationRoomList(param)
    local vipRelativeRoomItem = this.transform:Find('Canvas/DetailInfo/Panel2/Content/RelativeRooms/Viewport/Content/RoomItem')
    local vipParent = vipRelativeRoomItem.parent
    lua_Transform_ClearChildren(vipParent, true)
    local isShowNoneTips = true

    for roomID, masterName in pairs(GameData.RoomInfo.RelationRooms) do
        local item = CS.UnityEngine.Object.Instantiate(vipRelativeRoomItem).transform
        item:GetComponent("Button").onClick:AddListener( function() EnterGameRoomByRoomID(roomID) end)
        item:Find('RoomID'):GetComponent("Text").text = tostring(roomID)
        item:Find('MasterName'):GetComponent("Text").text = masterName
        item.gameObject:SetActive(true)
        CS.Utility.ReSetTransform(item, vipParent)
        isShowNoneTips = false
    end

    this.transform:Find('Canvas/DetailInfo/Panel2/Content/RelativeRooms/Viewport/NoneTip').gameObject:SetActive(isShowNoneTips)
end

-- =============================经典厅功能=============================================

-- 经典厅 房间进入请求(参数1:房间子类型 0 1 2 3 4)
function EnterJingDianRoom(subTypeParam)
    NetMsgHandler.Send_CS_JH_Enter_Room2(subTypeParam)
end


-- 显示(Guide)引导 UI
function TryShowGuideOfRoomType(roomType)
    local userGuideRoot = this.transform:Find('Canvas/UserGuide')
    if userGuideRoot == nil then
        return
    end

    local childCount = userGuideRoot.childCount
    for index = childCount - 1, 0, -1 do
        userGuideRoot:GetChild(index).gameObject:SetActive(false)
    end

    local guideHallOfRoomType = CS.UnityEngine.PlayerPrefs.GetString("SHOWED_Hall_GUIDE_" .. roomType, "0")

    if guideHallOfRoomType ~= "1" then
        local guidePart = userGuideRoot:Find('Guide' .. roomType)
        if guidePart ~= nil then
            guidePart.gameObject:SetActive(true)
            local iKnowButton = guidePart:Find('KnowButton'):GetComponent("Button")
            iKnowButton.gameObject:SetActive(true)
            iKnowButton.onClick:AddListener(
            function()
                guidePart.gameObject:SetActive(false)
            end
            )
            CS.UnityEngine.PlayerPrefs.SetString("SHOWED_Hall_GUIDE_" .. roomType, "1")
        end
    end
end


-- 请求OpenInstallData
function ReqOpenInstallData()
    PlatformBridge:CallFunc(PLATFORM_TYPE.PLATFORM_TOURISTS, PLATFORM_FUNCTION_ENUM.PLATFORM_FUNCTION_INVITE, '参数:请求OpenInstall数据')
end

function Update()
    if GameData.OpenInstallRoomID ~= nil and GameData.OpenInstallRoomID ~= -1 then
        NetMsgHandler.Send_CS_Enter_Room(tonumber(GameData.OpenInstallRoomID))
        GameData.OpenInstallRoomID = -1
    end
    if GameData.OpenInstallReferralsID ~= nil and tonumber(GameData.OpenInstallReferralsID) ~= -1 then
        if GameData.RoleInfo.InviteCode == 0 and GameData.RoleInfo.PromoterStep < 2 and tonumber(GameData.OpenInstallReferralsID) ~= GameData.RoleInfo.AccountID then
            NetMsgHandler.Send_CS_Invite_Code(tonumber(GameData.OpenInstallReferralsID))
            GameData.OpenInstallReferralsID = -1
        end
    end
end