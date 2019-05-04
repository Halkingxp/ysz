local Time = CS.UnityEngine.Time
local BetCountDownKey = "BetCountdown"
local isUpdateBetCountDown = false
local isUpdateOpenPokerCountDown = false
local m_IsCutPokerCardCountDown = false		-- 切牌倒计时
local m_BetLimitTime = 2			-- 下注倒计时限制时间
local isUpdateCheckCardCountDown = false

-- 离开房间倒计时
local exitRoomCountDown = 99
local isUpdateExitRoomCountDown = false
local canPlayCountDownAudio = false         	--能否开始播放倒计时
local nowPlayingCountDownAudio = true    		--是否处于播放中ing
local canPlaySoundEffect = false 				--能开始播放音效(进入房间时有很多东西需要筹备 筹备完毕才能开始播放)
local PokerTypeClickTime = 0					--扑克花色点击时刻
local PokerTypeClickCDTime = 0.5				--扑克花色点击CD

local m_CutCardAnimationRoot = nil				-- 切牌动画根结点
local m_CutCardAniTipsText = nil				-- 切牌动画提示信息

local m_CanExitRoom = true						-- 能否离开房间

local SystemBankerID = 100000                   -- 系统坐庄ID限制

local m_CheckColorOf1 = CS.UnityEngine.Color(41/255, 243/255, 0)
local m_CheckColorOf2 = CS.UnityEngine.Color(230/255, 251/255, 34/255)
local m_CheckColorOf3 = CS.UnityEngine.Color(227/255, 50/255, 8/255)

-- 发牌每张牌的间隔时间为0.2s
local DEAL_CONFIG =
{
[1] ={DealCard = 1, MoveTime = 0.8, DealStartTime = 0.5, RotateTime = 0.4},
[2] ={DealCard = 4, MoveTime = 0.5, DealStartTime = 1.9, RotateTime = 0.4},
[3] ={DealCard = 2, MoveTime = 0.7, DealStartTime = 2.8, RotateTime = 0},
[4] ={DealCard = 5, MoveTime = 0.4, DealStartTime = 3.4, RotateTime = 0},
[5] ={DealCard = 3, MoveTime = 0.6, DealStartTime = 4.2, RotateTime = 0},
[6] ={DealCard = 6, MoveTime = 0.3, DealStartTime = 5.0, RotateTime = 0},
}

-- 扑克牌的挂节点
local POKER_JOINTS = {}
-- 扑克牌
local POKER_CARDS = {}
-- 扑克牌根节点
local m_PokerCardsRoot = nil

-- 筹码挂节点
local CHIP_JOINTS =
{
[1] = { JointPoint = nil, RangeX = { Min = - 130, Max = 130 }, RangeY = { Min = - 70, Max = 70 } },
[2] = { JointPoint = nil, RangeX = { Min = - 140, Max = 140 }, RangeY = { Min = - 70, Max = 70 } },
[3] = { JointPoint = nil, RangeX = { Min = - 130, Max = 130 }, RangeY = { Min = - 70, Max = 70 } },
[4] = { JointPoint = nil, RangeX = { Min = - 200, Max = 200 }, RangeY = { Min = - 120, Max = 100 } },
[5] = { JointPoint = nil, RangeX = { Min = - 200, Max = 200 }, RangeY = { Min = -120, Max = 100 } },
[11] = { JointPoint = nil },
[12] = { JointPoint = nil },
[13] = { JointPoint = nil },
}

-- 筹码模型
local CHIP_MODEL = { }

local isNeedWait = false -- 是否需要等到赔付结果，如果有赢得区域则需要等待
local isStartCollect = false -- 开始收集筹码
local isReceiveResult = false -- 收到结果
local isDestroy = false
local BankerListShowTime = 5					-- 庄家列表显示时间
local BankerListShowPassTime = 0				-- 庄家列表显示时间流逝

local isInviteLineLight = false --邀请按钮是否闪烁
local inviteLineLightTimeCount = 0 --邀请按钮闪烁计时

function Awake()
	InitGameRoomPokerCardRelative()
	InitGameRoomBetAndChipRelative()
	InitGameRoomAnimationRelative()
	AddButtonHandlers()
	HandleTryShowUserGuide()
end

-- UI 开启
function WindowOpened()
	CS.EventDispatcher.Instance:AddEventListener(EventDefine.InitRoomState, ResetGameRoomToRoomState)
	CS.EventDispatcher.Instance:AddEventListener(EventDefine.UpdateRoomState, RefreshGameRoomByRoomStateSwitchTo)
	CS.EventDispatcher.Instance:AddEventListener(EventDefine.UpdateBankerInfo, RefreshBankerInfo)
	CS.EventDispatcher.Instance:AddEventListener(EventDefine.UpdateRoleCount, RefreshRoomRoleCount)
	CS.EventDispatcher.Instance:AddEventListener(EventDefine.UpdateGold, RefreshMineInfoOfGoldCount)
	CS.EventDispatcher.Instance:AddEventListener(EventDefine.UpdateHandlePoker, RefreshHandlePokerCard)
	CS.EventDispatcher.Instance:AddEventListener(EventDefine.UpdateBankerList, RefreshCandidateBankerList)
	CS.EventDispatcher.Instance:AddEventListener(EventDefine.PokerVisibleChanged,RefreshHandlePokerCardVisibleChanged)
	
	CS.EventDispatcher.Instance:AddEventListener(EventDefine.NotifyBetResult, HandleNotifyBetResult)
	CS.EventDispatcher.Instance:AddEventListener(EventDefine.UpdateBetValue, HandleBetValueChanged)
	CS.EventDispatcher.Instance:AddEventListener(EventDefine.NotifyWinGold, HandleNotifyWinGold)
	
	CS.EventDispatcher.Instance:AddEventListener(EventDefine.NotifyEndGame, RefreshExitRoomTipsPart)
	CS.EventDispatcher.Instance:AddEventListener(CS.Common.Animation.AnimationControl.FrameComplated, HandleAnimationControlFrameComplated)
	
	CS.EventDispatcher.Instance:AddEventListener('CutDeckControl_CutOver', HandleCutAnimationOver)
	CS.EventDispatcher.Instance:AddEventListener('CutDeckControl_ReturnDeskOver', HandleCutAnimationPlayComplated)
	CS.EventDispatcher.Instance:AddEventListener(EventDefine.NotifyCutPokerType, PlayPokerTypeAudio)
	
	CS.EventDispatcher.Instance:AddEventListener(EventDefine.UpdateBetRankList, RefreshBetRankListPartOfRank)
	CS.EventDispatcher.Instance:AddEventListener(EventDefine.NotifyBetEnd, HandleBetEnd)
	
	if GameData.RoomInfo.CurrentRoom.RoomID ~= 0 then
		ResetGameRoomToRoomState(GameData.RoomInfo.CurrentRoom.RoomState)
	end
	-- 设置统计区域脚本关联的房间号
	local topTrendScript = this.transform:Find('Canvas/TopArea'):GetComponent("LuaBehaviour").LuaScript
	topTrendScript.ResetRelativeRoomID(GameData.RoomInfo.CurrentRoom.RoomID)
	
	--音效祝你好运
	MusicMgr:PlaySoundEffect(45)
	
end

-- UI 关闭
function WindowClosed()
	CS.EventDispatcher.Instance:RemoveEventListener(EventDefine.InitRoomState, ResetGameRoomToRoomState)
	CS.EventDispatcher.Instance:RemoveEventListener(EventDefine.UpdateRoomState, RefreshGameRoomByRoomStateSwitchTo)
	CS.EventDispatcher.Instance:RemoveEventListener(EventDefine.UpdateBankerInfo, RefreshBankerInfo)
	CS.EventDispatcher.Instance:RemoveEventListener(EventDefine.UpdateRoleCount, RefreshRoomRoleCount)
	CS.EventDispatcher.Instance:RemoveEventListener(EventDefine.UpdateGold, RefreshMineInfoOfGoldCount)
	CS.EventDispatcher.Instance:RemoveEventListener(EventDefine.UpdateHandlePoker, RefreshHandlePokerCard)
	CS.EventDispatcher.Instance:RemoveEventListener(EventDefine.UpdateBankerList, RefreshCandidateBankerList)
	CS.EventDispatcher.Instance:RemoveEventListener(EventDefine.PokerVisibleChanged,RefreshHandlePokerCardVisibleChanged)
	
	CS.EventDispatcher.Instance:RemoveEventListener(EventDefine.NotifyBetResult, HandleNotifyBetResult)
	CS.EventDispatcher.Instance:RemoveEventListener(EventDefine.UpdateBetValue, HandleBetValueChanged)
	CS.EventDispatcher.Instance:RemoveEventListener(EventDefine.NotifyWinGold, HandleNotifyWinGold)
	
	CS.EventDispatcher.Instance:RemoveEventListener(EventDefine.NotifyEndGame, RefreshExitRoomTipsPart)
	CS.EventDispatcher.Instance:RemoveEventListener(CS.Common.Animation.AnimationControl.FrameComplated, HandleAnimationControlFrameComplated)
	
	CS.EventDispatcher.Instance:RemoveEventListener('CutDeckControl_CutOver', HandleCutAnimationOver)
	CS.EventDispatcher.Instance:RemoveEventListener('CutDeckControl_ReturnDeskOver', HandleCutAnimationPlayComplated)
	CS.EventDispatcher.Instance:RemoveEventListener(EventDefine.NotifyCutPokerType, PlayPokerTypeAudio)
	
	CS.EventDispatcher.Instance:RemoveEventListener(EventDefine.UpdateBetRankList, RefreshBetRankListPartOfRank)
	CS.EventDispatcher.Instance:RemoveEventListener(EventDefine.NotifyBetEnd, HandleBetEnd)
	
	-- UI 关闭时 停掉所有的音效并停止挂起的携程
	MusicMgr:StopAllSoundEffect()
	-- 停止掉所有的协程
	this:StopAllDelayInvoke()
	
	--关闭邀请按钮闪烁
	print("游戏界面关闭，关闭邀请按钮闪烁")
	isInviteLineLight = false
	inviteLineLightTimeCount = 0
	this.transform:Find('Canvas/RoomInfo/ButtonInvite/LineLight').gameObject:SetActive(false)
end

-- 每一帧更新
function Update()
	GameData.ReduceRoomCountDownValue(Time.deltaTime)
	UpdateBetCountDown()
	UpdateOpenPokerCardCountDown()
	UpdateExitRoomCountDown()
	UpdateCutPokerPartOfCountDown()
	AutoRefreshBankerListHide()
	DelayHideInviteLineLight(Time.deltaTime)
	UpdateCheckCardCountDown()
end

-- 重置游戏房间到指定的游戏状态
function ResetGameRoomToRoomState(currentState)
	canPlaySoundEffect = false
	-- 停止掉所有的协程
	this:StopAllDelayInvoke()
	InitRoomBaseInfos()
	RefreshBankerInfo(1)-- 重置庄家信息
	RefreshRoomRoleCount(GameData.RoomInfo.CurrentRoom.RoleCount)
	RefreshExitRoomButtonState(true)
	RefreshGameRoomToEnterGameState(currentState, true)
	canPlaySoundEffect = true
end

-- 刷新游戏房间进入到指定房间状态
function RefreshGameRoomByRoomStateSwitchTo(roomState)
	RefreshGameRoomToEnterGameState(roomState, false)
end

-- 初始化房间基础信息：房间限注金额，桌布的颜色，房间ID信息, 房间的押注赔付比例，邀请按钮的状态，筹码挂接点
function InitRoomBaseInfos()
	InitRoomBaseInfoOfRoomInfo()
	local roomConfig = data.RoomConfig[GameData.RoomInfo.CurrentRoom.TemplateID]
	if roomConfig ~= nil then
		InitRoomBaseInfoOfLimit(roomConfig)
		InitRoomBaseInfoOfTableCloth(roomConfig)
		InitRoomBaseInfoOfChipLocation(roomConfig)
	end
	InitRoomBaseInfoOfBetRate()
	InitRoomBaseInfoOfInviteState()
	InitRoomBaseInfoOfMineInfo()
end

-- 房间限注信息
function InitRoomBaseInfoOfLimit(roomConfig)
	local roomLimit = this.transform:Find('Canvas/RoomInfo/LimitInfo')
	roomLimit:Find('Item1/Value'):GetComponent("Text").text = lua_NumberToStyle1String(GameConfig.GetFormatColdNumber(roomConfig.BettingLongHu[1])).."-"..lua_NumberToStyle1String(GameConfig.GetFormatColdNumber(roomConfig.BettingLongHu[2]))
	roomLimit:Find('Item2/Value'):GetComponent("Text").text = lua_NumberToStyle1String(GameConfig.GetFormatColdNumber(roomConfig.BettingBaoZi[1]))
	roomLimit:Find('Item3/Value'):GetComponent("Text").text = lua_NumberToStyle1String(GameConfig.GetFormatColdNumber(roomConfig.BettingJinHua[2])).."/"..lua_NumberToStyle1String(GameConfig.GetFormatColdNumber(roomConfig.BettingBaoZi[2]))
end

-- 房间桌布颜色信息
function InitRoomBaseInfoOfTableCloth(roomConfig)
	local roomType = 1
	if roomConfig ~= nil then
		roomType = roomConfig.Type
	end
	local tableClothRoot = this.transform:Find('Canvas/Back/DeskBack')
	tableClothRoot:Find('tablecloth1').gameObject:SetActive(roomType == 1)
	tableClothRoot:Find('tablecloth2').gameObject:SetActive(roomType == 2)
	tableClothRoot:Find('tablecloth3').gameObject:SetActive(roomType == 3)
end

-- 设置房间筹码定位点
function InitRoomBaseInfoOfChipLocation(roomConfig)
	this.transform:Find('Canvas/BetChipHandle/Chips'):GetComponent("ScrollRectExtend"):CenterOnChild(roomConfig.CenterOnChild - 1, false)
end

-- 房间信息(房间ID)
function InitRoomBaseInfoOfRoomInfo()
	local roomIDText = this.transform:Find('Canvas/RoomInfo/RoomID/Value'):GetComponent("Text")
	if GameData.RoomInfo.CurrentRoom.IsVipRoom then
		roomIDText.text = tostring(GameData.RoomInfo.CurrentRoom.RoomID)
	else
		roomIDText.text = data.RoomConfig[GameData.RoomInfo.CurrentRoom.TemplateID].ShowName
	end
end

-- 设置赔付比例
function InitRoomBaseInfoOfBetRate()
	local betAreaRoot = this.transform:Find('Canvas/BetChipHandle/BetArea')
	for	index = 1, 5, 1 do
		betAreaRoot:Find('Area'.. index.. '/Rate'):GetComponent("Text").text = "1:".. COMPENSATE[index]
	end
end

-- 设置邀请按钮的状态
function InitRoomBaseInfoOfInviteState()
	--if GameData.RoleInfo.PromoterStep == 2 or GameData.RoleInfo.PromoterStep == 3 or GameData.RoomInfo.CurrentRoom.IsVipRoom then
	this.transform:Find('Canvas/RoomInfo/ButtonInvite'):GetComponent("Button").interactable = true
	this.transform:Find('Canvas/RoomInfo/ButtonInvite/Flag1').gameObject:SetActive(true)
	this.transform:Find('Canvas/RoomInfo/ButtonInvite/Flag2').gameObject:SetActive(false)
	--else
	--	this.transform:Find('Canvas/RoomInfo/ButtonInvite'):GetComponent("Button").interactable = false
	--	this.transform:Find('Canvas/RoomInfo/ButtonInvite/Flag1').gameObject:SetActive(false)
	--	this.transform:Find('Canvas/RoomInfo/ButtonInvite/Flag2').gameObject:SetActive(true)
	--end
end

-- 初始化游戏房间的扑克牌相关
function InitGameRoomPokerCardRelative()
	m_PokerCardsRoot = this.transform:Find('Canvas/DealPokers/Cards')
	for	 cardIndex = 1, 6, 1 do
		POKER_CARDS[cardIndex] = m_PokerCardsRoot:Find('Card'.. cardIndex)
	end
	
	-- 初始化发牌收牌节点(开始节点，中间节点，结束节点,发牌节点)
	local dealPokerJoints = this.transform:Find('Canvas/DealPokers/Points')
	
	POKER_JOINTS[0] = dealPokerJoints:Find('StartPoint')
	POKER_JOINTS[98] = dealPokerJoints:Find('MiddlePoint')
	POKER_JOINTS[99] = dealPokerJoints:Find('EndPoint')
	for	index = 1, 6, 1 do
		POKER_JOINTS[index] = dealPokerJoints:Find('Poker'..index)
	end
	
	-- 操作扑克牌的节点
	local handlePokerJoints = this.transform:Find('Canvas/PokerHandle/Points')
	
	POKER_JOINTS.HANDLER ={}
	POKER_JOINTS.OBSERVER ={}
	POKER_JOINTS.HANDLER[2] = handlePokerJoints:Find('HandlePoint2')
	POKER_JOINTS.HANDLER[3] = handlePokerJoints:Find('HandlePoint3')
	POKER_JOINTS.OBSERVER[2] = handlePokerJoints:Find('Point2')
	POKER_JOINTS.OBSERVER[3] = handlePokerJoints:Find('Point3')
	POKER_JOINTS.OBSERVER[5] = handlePokerJoints:Find('Point5')
	POKER_JOINTS.OBSERVER[6] = handlePokerJoints:Find('Point6')
	
	-- 荷官泡泡
	this.transform:Find('Canvas/DealerPaoPao').gameObject:SetActive(false)
end

-- 初始化房间的押注和筹码相关
function InitGameRoomBetAndChipRelative()
	-- 初始化筹码挂节点
	local chipsJointRoot = this.transform:Find('Canvas/BetChipHandle/ChipJoints')
	for index = 1, 5, 1 do
		local rectTrans = chipsJointRoot:Find('Joint' .. index):GetComponent("RectTransform")
		CHIP_JOINTS[index].JointPoint = rectTrans
		CHIP_JOINTS[index].RangeX.Min = math.floor(- rectTrans.sizeDelta.x *0.5)
		CHIP_JOINTS[index].RangeX.Max = math.floor(rectTrans.sizeDelta.x *0.5)
		CHIP_JOINTS[index].RangeY.Min = math.floor(-rectTrans.sizeDelta.y *0.5)
		CHIP_JOINTS[index].RangeY.Max = math.floor(rectTrans.sizeDelta.y *0.5)
	end
	
	local chipStartJointRoot = this.transform:Find('Canvas/BetChipHandle/StartPoint')
	CHIP_JOINTS[11].JointPoint = chipStartJointRoot:Find('MyPoint')
	CHIP_JOINTS[12].JointPoint = chipStartJointRoot:Find('OtherPoint')
	CHIP_JOINTS[13].JointPoint = chipStartJointRoot:Find('BankerPoint')
	
	-- 筹码模型
	local chipModeRoot = this.transform:Find('Canvas/BetChipHandle/ChipRes')
	for index = 1, 10, 1 do
		CHIP_MODEL[CHIP_VALUE[index]] = chipModeRoot:Find('chip_' .. index)
		CHIP_MODEL[CHIP_VALUE[index]]:Find('Icon').gameObject.name = tostring(CHIP_VALUE[index])
	end
end

-- 初始化切牌动画相关
function InitGameRoomAnimationRelative()
	m_CutCardAnimationRoot = this.transform:Find('Canvas/CutDeckUI')
	m_CutCardAniTipsText = m_CutCardAnimationRoot:Find('Root/Tips'):GetComponent("Text")
end

-- 按钮事件响应绑定
function AddButtonHandlers()
	this.transform:Find('Canvas/TipsPart/StartPart/ButtonStart'):GetComponent("Button").onClick:AddListener(StartGameButtonOnClick)
	this.transform:Find('Canvas/RoomInfo/ButtonExitRoom'):GetComponent("Button").onClick:AddListener(ExitRoomButtonOnClick)
	this.transform:Find('Canvas/RoomInfo/ButtonInvite'):GetComponent("Button").onClick:AddListener(InviteButtonOnClick)
	this.transform:Find('Canvas/RoomInfo/ButtonConvert'):GetComponent("Button").onClick:AddListener(ConvertButtonOnClick)
	this.transform:Find('Canvas/RoomInfo/Banker/BankerList'):GetComponent("Button").onClick:AddListener(BankerListButtonOnClick)
	this.transform:Find('Canvas/RoomInfo/Banker/BankerList/List/back02'):GetComponent("Button").onClick:AddListener(BankerListButtonOnClick)
	this.transform:Find('Canvas/RoomInfo/Banker/ButtonUpBanker'):GetComponent("Button").onClick:AddListener(UpBankerButtonOnClick)
	this.transform:Find('Canvas/RoomInfo/Banker/ButtonDownBanker'):GetComponent("Button").onClick:AddListener(DownBankerButtonOnClick)
	this.transform:Find('Canvas/PokerHandle/ButtonOpen'):GetComponent("Button").onClick:AddListener(OpenCardButtonOnClick)
	this.transform:Find('Canvas/RoomInfo/RoleCount'):GetComponent("Button").onClick:AddListener(RoleCountButtonOnClick)
	this.transform:Find('Canvas/RoomInfo/ButtonHelp'):GetComponent("Button").onClick:AddListener(ButtonHelpOnClick)
	
	this.transform:Find('Canvas/PokerHandle/ShoutHandle/Button1'):GetComponent("Button").onClick:AddListener(function () PokerType_OnClick(Poker_Type.Spade)	 end)
	this.transform:Find('Canvas/PokerHandle/ShoutHandle/Button2'):GetComponent("Button").onClick:AddListener(function () PokerType_OnClick(Poker_Type.Hearts)	 end)
	this.transform:Find('Canvas/PokerHandle/ShoutHandle/Button3'):GetComponent("Button").onClick:AddListener(function () PokerType_OnClick(Poker_Type.Diamond)	 end)
	this.transform:Find('Canvas/PokerHandle/ShoutHandle/Button4'):GetComponent("Button").onClick:AddListener(function () PokerType_OnClick(Poker_Type.Club) end)
	
	AddBetRelativeHandlers()
	
	this.transform:Find('Canvas/BetRank/Area4Rank/RankFirst/Sitdown'):GetComponent("Button").onClick:AddListener(SitDownButtonOnClick)
	this.transform:Find('Canvas/BetRank/Area5Rank/RankFirst/Sitdown'):GetComponent("Button").onClick:AddListener(SitDownButtonOnClick)
	
end

-- 押注区 筹码选择区 事件响应绑定
function AddBetRelativeHandlers()
	-- 押注区域
	for buttonIndex = 1, 5, 1 do
		this.transform:Find('Canvas/BetChipHandle/BetArea/Area' .. buttonIndex):GetComponent("Button").onClick:AddListener( function () BetAreaButtonOnClick(buttonIndex) end)
	end
	
	-- 筹码选择
	for index = 1, 10, 1 do
		this.transform:Find('Canvas/BetChipHandle/Chips/Viewport/Content/Chip' .. index):GetComponent("Toggle").onValueChanged:AddListener( function (isOn) ChipValueOnValueChanged(isOn, CHIP_VALUE[index]) end)
	end
end

--扑克花色点击
function PokerType_OnClick( pokertype )
	-- body
	local passTime = CS.UnityEngine.Time.time - PokerTypeClickTime
	if passTime < PokerTypeClickCDTime then
		return
	end
	PokerTypeClickTime = CS.UnityEngine.Time.time
	
	NetMsgHandler.CS_Player_Cut_Type(pokertype)
	
	PlayPokerTypeAudio(pokertype)
end

--播放扑克花色音效
function PlayPokerTypeAudio(pokertype)
	local musicid = 41
	if pokertype == Poker_Type.Spade then
		musicid = 41
	elseif pokertype == Poker_Type.Hearts then
		musicid = 42
	elseif pokertype == Poker_Type.Club then
		musicid = 43
	else
		musicid = 40
	end
	PlaySoundEffect(musicid)
end

---------------------------------------------------------------------------
-- 响应开始游戏按钮点击
function StartGameButtonOnClick()
	-- 向服务器发送开局消息
	NetMsgHandler.Send_CS_Vip_Start_Game()
end

-- 离开房间按钮
function ExitRoomButtonOnClick()
	-- 如果是庄家不能离开房间
	if not isUpdateExitRoomCountDown then
		if GameData.RoomInfo.CurrentRoom.BankerInfo.ID == GameData.RoleInfo.AccountID then
			return
		else
			-- 非庄家玩家，押注了不能推出
			local isBeted = false
			for	areaType = 1, 5, 1 do
				local betValue = GameData.RoomInfo.CurrentRoom.BetValues[areaType]
				if betValue ~= nil and betValue > 0 then
					isBeted = true
					break
				end
			end
			if isBeted then
				return
			end
		end
	end
	NetMsgHandler.Send_CS_Exit_Room(1)
	
end

-- 刷新推出房间按钮状态
function RefreshExitRoomButtonState(force)
	if isUpdateExitRoomCountDown then -- 如果退出房间阶段
		ResetExitRoomStateValue(true, force)
	elseif GameData.RoomInfo.CurrentRoom.BankerInfo.ID == GameData.RoleInfo.AccountID then -- 如果是庄家不能离开房间
		ResetExitRoomStateValue(false, force)
	else
		-- 非庄家玩家，押注了不能推出
		local isBeted = false
		for	areaType = 1, 5, 1 do
			local betValue = GameData.RoomInfo.CurrentRoom.BetValues[areaType]
			if betValue ~= nil and betValue > 0 then
				isBeted = true
				break
			end
		end
		if isBeted then
			ResetExitRoomStateValue(false, force)
		else
			ResetExitRoomStateValue(true, force)
		end
	end
end

-- 重置退出房间按钮的状态
function ResetExitRoomStateValue(canExitRoom, force)
	if canExitRoom ~= m_CanExitRoom or force then
		local exitRoomButton = this.transform:Find('Canvas/RoomInfo/ButtonExitRoom'):GetComponent("Button")
		if canExitRoom == true then
			exitRoomButton.interactable = true
			exitRoomButton.transform:Find('Flag1').gameObject:SetActive(true)
			exitRoomButton.transform:Find('Flag2').gameObject:SetActive(false)
			m_CanExitRoom = true
		else
			exitRoomButton.interactable = false
			exitRoomButton.transform:Find('Flag1').gameObject:SetActive(false)
			exitRoomButton.transform:Find('Flag2').gameObject:SetActive(true)
			m_CanExitRoom = false
		end
	end
end

-- 直接翻牌按钮响应
function OpenCardButtonOnClick()
	NetMsgHandler.Send_CS_Checked_Card(4)
end

-- 邀请按钮响应
function InviteButtonOnClick()
	--构建信息json
	infoTable = {}
	infoTable["title"] = CS.AppDefineConst.APPName.."[官方]"
	infoTable["content"] = "本游戏是一款竞技+休闲类的三张游戏，模拟真实的搓牌环节，玩家与玩家之间，可发挥更多的心理战术，更能体现出“诈”的乐趣。"
	local InviteID
	if GameData.RoleInfo.PromoterStep > 0 then
		InviteID = GameData.RoleInfo.AccountID
	else
		InviteID = -1
	end
	infoTable["url"] = string.format("%s?channelCode=%s&roomID=%d&referralsID=%d",GameConfig.InviteUrl, GameData.ChannelCode, GameData.RoomInfo.CurrentRoom.RoomID,InviteID)
	print('shareurl='..infoTable["url"])
	infoJSON = CS.LuaAsynFuncMgr.Instance:MakeJson(infoTable)
	print(infoJSON)
	PlatformBridge:CallFunc(PLATFORM_TYPE.PLATFORM_WEIXIN, PLATFORM_FUNCTION_ENUM.PLATFORM_FUNCTION_SHARE, infoJSON)
end

-- 兑换按钮被点击
function ConvertButtonOnClick()
	local initParam = CS.WindowNodeInitParam("UIConvert")
	initParam.WindowData = 1
	CS.WindowManager.Instance:OpenWindow(initParam)
end

-- 房间玩家列表查看响应
function RoleCountButtonOnClick()
	-- body
	local initParam = CS.WindowNodeInitParam("UIRoomPlayers")
	CS.WindowManager.Instance:OpenWindow(initParam)
end


-- 帮助按钮响应
function ButtonHelpOnClick()
	local initParam =CS.WindowNodeInitParam("UIHelp")
	initParam.WindowData = param
	CS.WindowManager.Instance:OpenWindow(initParam)
end

-- 上庄按钮响应
function UpBankerButtonOnClick()
	NetMsgHandler.Send_CS_Up_Banker()
end

-- 下庄按钮响应
function DownBankerButtonOnClick()
	if GameData.RoleInfo.AccountID == GameData.RoomInfo.CurrentRoom.BankerInfo.ID then
		NetMsgHandler.Send_CS_Apply_Banker_State()
	end
end

-- 刷新上庄和下庄按钮状态
function RefreshBankerButtonState()
	if GameData.RoleInfo.AccountID == GameData.RoomInfo.CurrentRoom.BankerInfo.ID then
		this.transform:Find('Canvas/RoomInfo/Banker/ButtonUpBanker').gameObject:SetActive(false)
		this.transform:Find('Canvas/RoomInfo/Banker/ButtonDownBanker').gameObject:SetActive(true)
	else
		this.transform:Find('Canvas/RoomInfo/Banker/ButtonUpBanker').gameObject:SetActive(true)
		this.transform:Find('Canvas/RoomInfo/Banker/ButtonDownBanker').gameObject:SetActive(false)
	end
end

------------------------上庄列表相关功能-----------------------------------
function BankerListButtonOnClick()
	local bankerListRoot = this.transform:Find('Canvas/RoomInfo/Banker/BankerList')
	local listTransform = bankerListRoot:Find('List')
	if listTransform.gameObject.activeSelf then
		listTransform.gameObject:SetActive(false)
		bankerListRoot:Find('UpArrow').gameObject:SetActive(false)
		bankerListRoot:Find('DownArrow').gameObject:SetActive(true)
		BankerListShowPassTime = 0
	else
		listTransform.gameObject:SetActive(true)
		bankerListRoot:Find('UpArrow').gameObject:SetActive(true)
		bankerListRoot:Find('DownArrow').gameObject:SetActive(false)
		NetMsgHandler.Send_CS_Up_Banker_List()
		RefreshCandidateBankerList(nil)
		BankerListShowPassTime = BankerListShowTime
	end
end

-- 刷新候选庄家列表
function RefreshCandidateBankerList(arg)
	local listTransform = this.transform:Find('Canvas/RoomInfo/Banker/BankerList/List')
	for index = 1, 5, 1 do
		local bankerInfo = GameData.RoomInfo.CurrentRoom.BankerList[index]
		if bankerInfo ~= nil then
			listTransform:Find("Item"..index).gameObject:SetActive(true)
			listTransform:Find("Item"..index.."/VipLevel"):GetComponent("Text").text = "V"..tostring(bankerInfo.VipLevel)
			if bankerInfo.ID == GameData.RoleInfo.AccountID then
				listTransform:Find("Item"..index.."/Name"):GetComponent("Text").text =string.format("<color=#F7DE1F>%s</color>", bankerInfo.Name)
				listTransform:Find("Item"..index.."/Gold"):GetComponent("Text").text =string.format("<color=#F7DE1F>%s</color>", lua_NumberToStyle1String(GameConfig.GetFormatColdNumber(bankerInfo.GoldCount)))
			else
				listTransform:Find("Item"..index.."/Name"):GetComponent("Text").text =string.format("<color=#E8D7C6>%s</color>", bankerInfo.Name)
				listTransform:Find("Item"..index.."/Gold"):GetComponent("Text").text =string.format("<color=#E8D7C6>%s</color>", lua_NumberToStyle1String(GameConfig.GetFormatColdNumber(bankerInfo.GoldCount)))
			end
		else
			listTransform:Find("Item"..index).gameObject:SetActive(false)
		end
	end
end

-- 庄家列表自动隐藏
function AutoRefreshBankerListHide()
	-- body
	local  deltaTime = CS.UnityEngine.Time.deltaTime
	if BankerListShowPassTime > 0 then
		BankerListShowPassTime = BankerListShowPassTime - deltaTime
		if BankerListShowPassTime < 0 then
			local listTransform = this.transform:Find('Canvas/RoomInfo/Banker/BankerList/List')
			if true == listTransform.gameObject.activeSelf then
				listTransform.gameObject:SetActive(false)
			end
			BankerListShowPassTime = 0
		end
	end
end

-- 刷新庄家信息
function RefreshBankerInfo(arg)
	if arg == 1 then
		local bankerInfo = GameData.RoomInfo.CurrentRoom.BankerInfo
		local bankerRoot = this.transform:Find('Canvas/RoomInfo/Banker')
		bankerRoot:Find('Name'):GetComponent("Text").text = bankerInfo.Name
		bankerRoot:Find('BankerIcon'):GetComponent("Image"):ResetSpriteByName(GameData.GetRoleIconSpriteName(bankerInfo.HeadIcon))
		bankerRoot:Find('Gold'):GetComponent("Text").text = lua_NumberToStyle1String(GameConfig.GetFormatColdNumber(bankerInfo.Gold))
		bankerRoot:Find('BankerList/List/LeftRound/Number'):GetComponent("Text").text = tostring(bankerInfo.LeftCount)
		-- 刷新下离开房间按钮状态
		RefreshExitRoomButtonState(false)
		RefreshBankerButtonState()
	end
end

-- 刷新房间内人数
function RefreshRoomRoleCount(roleCount)
	this.transform:Find('Canvas/RoomInfo/RoleCount/ValueText'):GetComponent("Text").text = tostring(roleCount)
end

-- 设置角色名称
function InitRoomBaseInfoOfMineInfo()
	this.transform:Find('Canvas/RoleInfo/Name'):GetComponent("Text").text = GameData.RoleInfo.AccountName
	ResetMineInfoOfGoldCount(nil, true)
end

-- 刷新我的金币数量
function RefreshMineInfoOfGoldCount(arg)
	ResetMineInfoOfGoldCount(arg, false)
end

-- 刷新我的金币数量接口
function ResetMineInfoOfGoldCount(arg, isInit)
	local displayCount
	local ceachCount
	if GameData.RoomInfo.CurrentRoom.IsFreeRoom then
		displayCount = GameData.RoleInfo.DisplayFreeGoldCount
		ceachCount = GameData.RoleInfo.Cache.ChangedFreeGoldCount
	else
		displayCount = GameData.RoleInfo.DisplayGoldCount
		ceachCount = GameData.RoleInfo.Cache.ChangedGoldCount
	end
	
	this.transform:Find('Canvas/RoleInfo/GoldCount'):GetComponent("Text").text = lua_CommaSeperate(GameConfig.GetFormatColdNumber(displayCount))
	if ceachCount ~= 0 and isInit == false then
		local ceachString = lua_CommaSeperate(GameConfig.GetFormatColdNumber(ceachCount))
		if ceachCount > 0 then
			ceachString = "+" .. ceachString
			-- 大于0 才播放
			PlaySoundEffect(57)
		end
		local changedGoldItem = this.transform:Find('Canvas/RoleInfo/ChangedGold')
		changedGoldItem:GetComponent('Text').text = ceachString
		local tweenPosition = changedGoldItem:GetComponent('TweenPosition')
		tweenPosition:ResetToBeginning()
		tweenPosition.gameObject:SetActive(true)
		tweenPosition:Play(true)
		this:DelayInvoke(tweenPosition.duration, function ()tweenPosition.gameObject:SetActive(false) end)
	else
		this.transform:Find('Canvas/RoleInfo/ChangedGold').gameObject:SetActive(false)
	end
	
	-- 在押注状态且非重新进入的情况下，刷新下筹码状态
	if GameData.RoomInfo.CurrentRoom.RoomState == ROOM_STATE.BET and isInit == false then
		ResetChipsInteractable(false)
	end
end

-- 初始化房间看牌倒计时
function ResetGameRoomCheckCountDown()
	this.transform:Find('Canvas/BetRank/Area4Rank/RankFirst/CountDown').gameObject:SetActive(false)
	this.transform:Find('Canvas/BetRank/Area5Rank/RankFirst/CountDown').gameObject:SetActive(false)
end

-- 刷新游戏房间到游戏状态
function RefreshGameRoomToEnterGameState(roomState, isInit)
	if isInit or roomState == ROOM_STATE.WAIT then
		ResetGameRoomForReStart()
		lua_Call_GC()-- 调用下GC回收
		-- 荷官泡泡
		this.transform:Find('Canvas/DealerPaoPao').gameObject:SetActive(false)
	end
	RefreshStartPartOfGameRoomByState(roomState)
	RefreshShufflePartOfGameRoomByState(roomState, isInit)
	RefreshCutPokerPartOfGameRoomByState(roomState, isInit)
	RefreshBetAreaPartOfGameRoomByState(roomState, isInit)
	RefreshBetCountDownOfGameRoomByState(roomState)
	RefreshShoutAndBetPartOfGameRoomByState(roomState)
	RefreshPokerCardPartOfGameRoomByState(roomState, isInit)
	RefreshSettlementPartOfGameRoomByState(roomState, isInit)
	RefreshBetRankPartOfGameRoomByState(roomState, isInit)
	
	DealerPlayPaoPaoTips(roomState, isInit)
end

-- 荷官泡泡Tips
function DealerPlayPaoPaoTips( roomState, isInit)
	-- body
	if true == isInit then
		return
	end
	if roomState ~= ROOM_STATE.SHUFFLE then
		-- 非洗牌阶段 推出
		return
	end
	
	if GameData.RoomInfo.CurrentRoom.BankerInfo.ID > SystemBankerID then
		-- 非系统坐庄
		return
	end
	
	local speakRate = CS.UnityEngine.Random.Range(0, 100)
	if speakRate > data.PublicConfig.DEALER_PAOPAO_RATE then
		--print("=====荷官泡泡本次不发言")
		return
	end
	
	
	local DelaySpeakTime = CS.UnityEngine.Random.Range(15, 28.8)
	--print(string.format("============荷官泡泡:[%d] 是否初始化:[%s] Time[%f]", roomState, isInit, DelaySpeakTime))
	this:DelayInvoke(DelaySpeakTime, function () this.transform:Find('Canvas/DealerPaoPao').gameObject:SetActive(true) end)
	this:DelayInvoke(DelaySpeakTime + 3.0, function () this.transform:Find('Canvas/DealerPaoPao').gameObject:SetActive(false) end)
	local paopaoIndex = math.floor(CS.UnityEngine.Random.Range(1,data.PublicConfig.DEALER_PAOPAO_MAX+1))
	local describle = this.transform:Find('Canvas/DealerPaoPao/Text'):GetComponent('Text')
	describle.text = data.GetString("Dealer_PaoPao_"..paopaoIndex)
	local back = this.transform:Find('Canvas/DealerPaoPao/Image')
	CS.Utility.SetRectTransformWidthHight(back, 72, math.ceil(describle.preferredWidth + 32))
end

-- 重置房间信息到可以重新开局，清理掉桌面上的内容(押注区域，发牌区域，操作扑克牌区域，可能的延迟动画等)
function ResetGameRoomForReStart()
	ResetBetChipsAndAreaToRestart()
	ResetPokerCardToRestart()
	ResetSettlementToRestart()
	ResetPokerCardTypeToRestart()
	RefreshOpenPokerCardButtonState(false, false)
	-- 刷新牌桌上龙虎文字
	HideOrShowDeskWord(1, true)
	HideOrShowDeskWord(2, true)
	-- 隐藏看牌倒计时
	ResetGameRoomCheckCountDown()
end

-- 重置押注区域信息
function ResetBetChipsAndAreaToRestart()
	-- 清理掉筹码节点下的所有筹码
	for	areaType = 1, 5, 1 do
		lua_Transform_ClearChildren(CHIP_JOINTS[areaType].JointPoint, false)
	end
	-- 关闭掉区域动画
	HandleBetAreaAnimation(3)
end

-- 设置房间的开始游戏提示内容
function RefreshStartPartOfGameRoomByState(roomState)
	local startPartRoot = this.transform:Find('Canvas/TipsPart/StartPart')
	if roomState == ROOM_STATE.START then
		startPartRoot.gameObject:SetActive(true)
		if GameData.RoomInfo.CurrentRoom.MasterID == GameData.RoleInfo.AccountID then
			startPartRoot:Find('ButtonStart').gameObject:SetActive(true)
			startPartRoot:Find('WaitTips').gameObject:SetActive(false)
			--邀请按钮闪烁
			isInviteLineLight = true
			this.transform:Find('Canvas/RoomInfo/ButtonInvite/LineLight').gameObject:SetActive(true)
		else
			startPartRoot:Find('ButtonStart').gameObject:SetActive(false)
			startPartRoot:Find('WaitTips').gameObject:SetActive(true)
		end
	else
		startPartRoot.gameObject:SetActive(false)
	end
end

-- 刷新离开房间相关提示信息
function RefreshExitRoomTipsPart(isShow)
	if isShow == false then
		this.transform:Find('Canvas/TipsPart/ExitGame').gameObject:SetActive(false)
	else
		this.transform:Find('Canvas/TipsPart/ExitGame').gameObject:SetActive(true)
		if not isUpdateExitRoomCountDown then
			exitRoomCountDown = 10
			isUpdateExitRoomCountDown = true
			RefreshExitRoomButtonState(true)
		end
	end
end

function UpdateExitRoomCountDown()
	if isUpdateExitRoomCountDown then
		exitRoomCountDown = exitRoomCountDown - Time.deltaTime
		local formatStr = data.GetString("Tip_Exit_Room_1")
		this.transform:Find('Canvas/TipsPart/ExitGame/TipsText'):GetComponent("Text").text = string.format(formatStr, tostring(math.ceil(exitRoomCountDown)))
		if exitRoomCountDown <= 0 then
			this.transform:Find('Canvas/TipsPart/ExitGame').gameObject:SetActive(false)
			isUpdateExitRoomCountDown = false
			exitRoomCountDown = 99
			NetMsgHandler.Send_CS_Exit_Room(2)
		end
	end
end

---------------------------------------------------------------------------
------------------------洗牌动画播放中-------------------------------------
function RefreshShufflePartOfGameRoomByState(roomState, isInit)
	if roomState == ROOM_STATE.SHUFFLE then
		this.transform:Find('Canvas/ShuffleAni').gameObject:SetActive(true)
		local passedTime = ROOM_TIME[ROOM_STATE.SHUFFLE] - GameData.RoomInfo.CurrentRoom.CountDown
		CS.Common.Animation.AnimationControl.PlayAnimation("ShuffleAnimation", passedTime, true)
		--音效洗牌音效
		PlaySoundEffect(10)
	else
		this.transform:Find('Canvas/ShuffleAni').gameObject:SetActive(false)
	end
end

---------------------------------------------------------------------------
------------------------庄家切牌过程中-------------------------------------
function RefreshCutPokerPartOfGameRoomByState(roomState, isInit)
	m_IsCutPokerCardCountDown = false
	if roomState == ROOM_STATE.CUT then
		m_CutCardAnimationRoot.gameObject:SetActive(true)
		local m_CutDeckControl = m_CutCardAnimationRoot:GetComponent("CutDeckControl")
		if (GameData.RoomInfo.CurrentRoom.BankerInfo.ID < SystemBankerID) then
			if not isInit then
				m_CutDeckControl.IsDirectFlyToDesk = true
				m_CutCardAniTipsText.gameObject:SetActive(false)
				m_CutDeckControl:ResetToBeginning()
			end
		else
			m_CutDeckControl.IsDirectFlyToDesk = false
			if GameData.RoomInfo.CurrentRoom.BankerInfo.ID == GameData.RoleInfo.AccountID then
				m_CutDeckControl.IsSelfCut = true
				MusicMgr:PlaySoundEffect(46)
			else
				m_CutDeckControl.IsSelfCut = false
				MusicMgr:PlaySoundEffect(47)
			end
			m_CutDeckControl:ResetToBeginning()
			if GameData.RoomInfo.CurrentRoom.CountDown < 1 then
				m_CutCardAniTipsText.gameObject:SetActive(false)
				m_IsCutPokerCardCountDown = false
			else
				m_CutCardAniTipsText.gameObject:SetActive(true)
				m_IsCutPokerCardCountDown = true
				UpdateCutPokerPartOfCountDown()
			end
		end
	elseif roomState == ROOM_STATE.CUTANI and not isInit then
		m_CutCardAnimationRoot.gameObject:SetActive(true)
		m_CutCardAnimationRoot:GetComponent("CutDeckControl"):AutoCutIn(GameData.RoomInfo.CurrentRoom.CutAniIndex)
		m_CutCardAniTipsText.gameObject:SetActive(false)
	elseif roomState == ROOM_STATE.BET then
		if isInit then
			m_CutCardAnimationRoot.gameObject:SetActive(false)
			m_CutCardAniTipsText.gameObject:SetActive(false)
		end
	else
		m_CutCardAnimationRoot.gameObject:SetActive(false)
		m_CutCardAniTipsText.gameObject:SetActive(false)
	end
end

-- 更新切牌倒计时
function UpdateCutPokerPartOfCountDown()
	if m_IsCutPokerCardCountDown == true then
		local countDown = GameData.RoomInfo.CurrentRoom.CountDown - 1
		if GameData.RoomInfo.CurrentRoom.BankerInfo.ID == GameData.RoleInfo.AccountID then
			m_CutCardAniTipsText.text = string.format("请切牌...(%d)", math.ceil(countDown))
		else
			m_CutCardAniTipsText.text = string.format("庄家%s正在切牌中...(%d)", GameData.RoomInfo.CurrentRoom.BankerInfo.Name, math.ceil(countDown))
		end
		if (countDown <= 0) then
			m_IsCutPokerCardCountDown = false
			m_CutCardAnimationRoot:GetComponent("CutDeckControl"):CutTimeOut()
			m_CutCardAniTipsText.gameObject:SetActive(false)
		end
	end
end

function HandleCutAnimationOver(index)
	--如果在收到此事件之前已经收到服务器的自动切牌通知，直接返回
	print('HandleCutAnimationOver---------', index)
	--给服务器发消息
	NetMsgHandler.Send_CS_Cut_Card(index)
end

function HandleCutAnimationPlayComplated(args)
	if m_CutCardAnimationRoot == nil then
		return
	end
	m_CutCardAnimationRoot.gameObject:SetActive(false)
end


-- 重置扑克牌相关信息
function ResetPokerCardToRestart()
	for index = 1, 6, 1 do
		local pokerCardItem = POKER_CARDS[index]
		-- 清理掉所有的UITweener(界面动画脚本)
		lua_Clear_AllUITweener(pokerCardItem)
		lua_Paste_Transform_Value(pokerCardItem, POKER_JOINTS[0])
		pokerCardItem.gameObject:SetActive(false)
		SetTablePokerCardVisible(pokerCardItem, false)
	end
	
	-- 初始化2张操作的扑克牌
	for index = 2, 3, 1 do
		this.transform:Find('Canvas/PokerHandle/HandleCard'..index).gameObject:SetActive(false)
	end
end

-- 重置结算区域相关信息
function ResetSettlementToRestart()
	local settlementRoot = this.transform:Find('Canvas/PokerHandle/Result')
	settlementRoot.gameObject:SetActive(false)
	for	index = 1, 6, 1 do
		settlementRoot:Find('SettlementCards/Card'..index):GetComponent("Image"):ResetSpriteByName(GameData.GetPokerCardBackSpriteName())
		settlementRoot:Find('SettlementCards/Card'..index).gameObject:SetActive(false)
	end
	settlementRoot:Find('Seal').gameObject:SetActive(false)
end

function ResetPokerCardTypeToRestart()
	ResetPokerCardTypeToVisible(1, false)
	ResetPokerCardTypeToVisible(2, false)
end

-- 刷新押注区域相关内容
function RefreshBetCountDownOfGameRoomByState(roomState)
	local countDownRoot = this.transform:Find('Canvas/CountDown')
	if roomState == ROOM_STATE.BET then
		local countDown = GameData.RoomInfo.CurrentRoom.CountDown
		-- 开局2秒内进入房间提示已开局，请下注
		if ROOM_TIME[ROOM_STATE.BET] - countDown < 2 then
			CS.BubblePrompt.Show(data.GetString("Tip_Start_Bet"), "GameUI2")
			--音效:已开局请下注
			PlaySoundEffect(35)
		end
		if countDown > 3 then
			isUpdateBetCountDown = true
			countDownRoot.gameObject:SetActive(true)
		else
			countDownRoot.gameObject:SetActive(false)
		end
	else
		countDownRoot.gameObject:SetActive(false)
	end
end

-- 更新押注倒计时
function UpdateBetCountDown()
	if isUpdateBetCountDown == true then
		local countDown = GameData.RoomInfo.CurrentRoom.CountDown
		if countDown < m_BetLimitTime  then
			this.transform:Find('Canvas/CountDown').gameObject:SetActive(false)
			isUpdateBetCountDown = false
			--print(string.format("=====当前状态:[%d] CD:[%f]", GameData.RoomInfo.CurrentRoom.RoomState, countDown))
			if ROOM_STATE.BET == GameData.RoomInfo.CurrentRoom.RoomState and countDown > m_BetLimitTime - 0.5 then
				-- 停止下注提示
				if countDown > 1 then
					CS.BubblePrompt.Show(data.GetString("Tip_Stop_Bet"), "GameUI2")
				end
				--音效:停止下注
				PlaySoundEffect(36)
				--音效:是否下注提示
				local betValue = GameData.RoomInfo.CurrentRoom.BetValues
				local isPlay = true
				for k,v in pairs(betValue) do
					if nil ~= v and v > 0 then
						isPlay = false
						break
					end
				end
				
				--自己是庄家不需要提示未下注
				if GameData.RoomInfo.CurrentRoom.BankerInfo.ID == GameData.RoleInfo.AccountID then
					isPlay = false
				end
				
				if true == isPlay then
					this:DelayInvoke(2, function () PlaySoundEffect(37) end)
				end
			end
		end
		--显示时间比实际时间少
		this.transform:Find('Canvas/CountDown/ValueText'):GetComponent("Text").text = tostring(math.ceil(countDown - m_BetLimitTime))
		if countDown < m_BetLimitTime + 5 then
			canPlayCountDownAudio = true
		else
			canPlayCountDownAudio = false
			nowPlayingCountDownAudio = false
		end
		
		if canPlayCountDownAudio == true and nowPlayingCountDownAudio == false then
			PlayCountDownAudio()
			nowPlayingCountDownAudio = true
		end
	end
end

--播放倒计时音效
function PlayCountDownAudio()
	--音效倒计时 5 4 3 2 1
	local countDown = GameData.RoomInfo.CurrentRoom.CountDown
	local count = math.ceil(countDown - m_BetLimitTime)
	for i=1,count-1 do
		this:DelayInvoke(i-1, function () PlaySoundEffect(8) end)
	end
	if count > 1 then
		this:DelayInvoke(count-1, function () PlaySoundEffect(9) end)
	end
end

-- 刷新押注区域相关的内容
function RefreshBetAreaPartOfGameRoomByState(roomState, isInit)
	if isInit then
		if roomState >= ROOM_STATE.BET then
			if roomState < ROOM_STATE.SETTLEMENT then
				ResetBetChipsAlreadyOnTable(GameData.RoomInfo.CurrentRoomChips)
			end
			HandleBetValueChanged(3)
		end
		-- 初始状态的时候，筹码都设置成为不可用
		ResetChipsInteractable(true)
	end
	
	if roomState == ROOM_STATE.BET then
		-- 押注开始动画
		ResetChipsInteractable(false)
		if GameData.RoomInfo.CurrentRoom.CountDown > (ROOM_TIME[ROOM_STATE.BET] - 2) then
			HandleBetAreaAnimation(1)
			this:DelayInvoke(1.7,
			function ()
				HandleBetAreaAnimation(3)
			end)
		end
	elseif roomState == ROOM_STATE.DEAL or roomState == ROOM_STATE.WAIT then
		ResetChipsInteractable(true)
	end
end

function RefreshShoutAndBetPartOfGameRoomByState(roomState)
	if roomState > ROOM_STATE.DEAL and roomState < ROOM_STATE.SETTLEMENT then
		this.transform:Find('Canvas/PokerHandle/ShoutHandle').gameObject:SetActive(true)
		this.transform:Find('Canvas/BetChipHandle/Chips').gameObject:SetActive(false)
	else
		this.transform:Find('Canvas/PokerHandle/ShoutHandle').gameObject:SetActive(false)
		if GameData.RoomInfo.CurrentRoom.BankerInfo.ID ~= GameData.RoleInfo.AccountID then
			this.transform:Find('Canvas/BetChipHandle/Chips').gameObject:SetActive(true)
		else
			this.transform:Find('Canvas/BetChipHandle/Chips').gameObject:SetActive(false)
		end
	end
end

-- 扑克牌发牌相关内容
function RefreshPokerCardPartOfGameRoomByState(roomState, isInit)
	-- 扑克牌所在的根节点
	if roomState > ROOM_STATE.DEAL and roomState < ROOM_STATE.SETTLEMENT then
		CS.Utility.ReSetTransform(m_PokerCardsRoot, this.transform:Find('Canvas/PokerHandle/CardsJoint'))
	else
		CS.Utility.ReSetTransform(m_PokerCardsRoot, this.transform:Find('Canvas/DealPokers'))
	end
	
	if isInit then
		isUpdateCheckCardCountDown = false
		if roomState >= ROOM_STATE.DEAL then
			ResetPokerCardToRestart()
			RefreshPokerCardSpriteOfTable()
			HandleDealPokerCardToCardTable(roomState  >  ROOM_STATE.DEAL)
			RefreshCurrentGamePokerCardType()
			ResetPokerCardTypeToVisibleByCardVisible()
			
			if roomState == ROOM_STATE.CHECK1 then
				if GameData.RoomInfo.CurrentRoom.CheckRole1.ID > 0 then
					local isHandler = GameData.RoleInfo.AccountID == GameData.RoomInfo.CurrentRoom.CheckRole1.ID
					StartEnterCheckAnimation(1, isHandler, false)
					RefreshOpenPokerCardButtonState(isHandler, true)
					isUpdateCheckCardCountDown = lua_NOT_BOLEAN(isHandler)
				end
			elseif roomState == ROOM_STATE.CHECK2 then
				if GameData.RoomInfo.CurrentRoom.CheckRole2.ID > 0 then
					local isHandler = GameData.RoleInfo.AccountID == GameData.RoomInfo.CurrentRoom.CheckRole2.ID
					StartEnterCheckAnimation(2, isHandler, false)
					RefreshOpenPokerCardButtonState(isHandler, true)
					isUpdateCheckCardCountDown = lua_NOT_BOLEAN(isHandler)
				end
			end
		end
	else
		if roomState == ROOM_STATE.DEAL then
			ResetPokerCardToRestart()
			RefreshPokerCardSpriteOfTable()
			HandleDealPokerCardToCardTable(false)
			RefreshCurrentGamePokerCardType()
		end
		
		if roomState == ROOM_STATE.CHECK1 then
			if GameData.RoomInfo.CurrentRoom.CheckRole1.ID > 0 then
				local isHandler = GameData.RoleInfo.AccountID == GameData.RoomInfo.CurrentRoom.CheckRole1.ID
				StartEnterCheckAnimation(1,isHandler, true)
				RefreshOpenPokerCardButtonState(isHandler, true)
				--龙搓牌
				PlaySoundEffect(38)
				isUpdateCheckCardCountDown = lua_NOT_BOLEAN(isHandler)
			end
		elseif roomState == ROOM_STATE.CHECK1OVER then
			HandleRoleCheckPokerCordOverAnimation(1, GameData.RoomInfo.CurrentRoom.CheckRole1.ID > 0)
			-- 关闭开牌倒计时
			RefreshOpenPokerCardButtonState(false, false)
			isUpdateCheckCardCountDown = false
			this.transform:Find('Canvas/BetRank/Area4Rank/RankFirst/CountDown').gameObject:SetActive(false)
		elseif roomState == ROOM_STATE.CHECK2 then
			if GameData.RoomInfo.CurrentRoom.CheckRole2.ID > 0 then
				local isHandler = GameData.RoleInfo.AccountID == GameData.RoomInfo.CurrentRoom.CheckRole2.ID
				StartEnterCheckAnimation(2, isHandler, true)
				RefreshOpenPokerCardButtonState(isHandler, true)
				--虎搓牌
				PlaySoundEffect(39)
				isUpdateCheckCardCountDown = lua_NOT_BOLEAN(isHandler)
			end
		elseif roomState == ROOM_STATE.CHECK2OVER then
			HandleRoleCheckPokerCordOverAnimation(2, GameData.RoomInfo.CurrentRoom.CheckRole2.ID > 0)
			-- 关闭开牌倒计时
			RefreshOpenPokerCardButtonState(false, false)
			isUpdateCheckCardCountDown = false
			this.transform:Find('Canvas/BetRank/Area4Rank/RankFirst/CountDown').gameObject:SetActive(false)
		elseif roomState == ROOM_STATE.SETTLEMENT then
			CollectPokerCardsOnTable(isInit)
			-- 双方玩家的倒计时均关闭掉
			ResetGameRoomCheckCountDown()
		end
	end
end

--------------------------------------------------------------------------------------------------------------
------------------------------------------------发牌相关------------------------------------------------------
-- 设置牌桌上的扑克牌点数Sprite
function RefreshPokerCardSpriteOfTable()
	for pokerIndex = 1, 6, 1 do
		local pokerCard = GameData.RoomInfo.CurrentRoom.Pokers[pokerIndex]
		POKER_CARDS[pokerIndex]:GetComponent("Image"):ResetSpriteByName(GameData.GetPokerCardSpriteName(pokerCard))
	end
end

-- 扑克牌发送到牌桌上
function HandleDealPokerCardToCardTable(isNoAnimation)
	local stateTotalLastTime = ROOM_TIME[ROOM_STATE.DEAL]
	local elapseTime =ROOM_TIME[ROOM_STATE.DEAL] - GameData.RoomInfo.CurrentRoom.CountDown
	
	if isNoAnimation then
		elapseTime =  stateTotalLastTime
	end
	m_PokerCardsRoot:GetComponent("AnimationControl"):Play(elapseTime, true)
end

function HandleAnimationControlFrameComplated(args)
	if args ~= nil then
		local params = lua_string_split(args, "##")
		local eventType = params[1]
		if eventType == "DealComplated" then
			local cardIndex = tonumber(params[2])
			local cardItem =  POKER_CARDS[cardIndex]
			local pokerCard = GameData.RoomInfo.CurrentRoom.Pokers[cardIndex]
			if pokerCard ~= nil then
				SetTablePokerCardVisible(cardItem, pokerCard.Visible)
				RefreshSettlementPartOfPokerCard(cardIndex)
			end
		end
		if eventType == "DealStart" then
			local cardIndex = tonumber(params[2])
			PlaySoundEffect(3)
		end
	end
end

-- 设置玩家扑克牌是否可见
function SetTablePokerCardVisible(pokerCard, isVisible)
	pokerCard:Find('back').gameObject:SetActive(lua_NOT_BOLEAN(isVisible))
	if isVisible then
		PlaySoundEffect(4)
	end
end

--------------------------------------------------------------------------------------------------------------
----------------------------------------看牌结束开牌动画------------------------------------------------------
function HandleRoleCheckPokerCordOverAnimation(roleType, isOwnRole)
	if isOwnRole then
		HandleOpenPokerCardAnimationStepOne(roleType)
	else
		HandleNoRolePokerCardAnimation(roleType)
	end
end

function HandleNoRolePokerCardAnimation(roleType)
	local pokerIndex = 2
	if roleType ~= 1 then -- 龙开牌
		pokerIndex = pokerIndex + 3
	end
	
	this:DelayInvoke(0.4, function () AutoOpenPokerCardHandle(pokerIndex) end)
	this:DelayInvoke(1.2,
	function ()
		AutoOpenPokerCardHandle(pokerIndex + 1)
		ResetPokerCardTypeToVisible(roleType, true)
	end)
end

function AutoOpenPokerCardHandle(pokerIndex)
	local pokerCard = GameData.RoomInfo.CurrentRoom.Pokers[pokerIndex]
	if pokerCard ~= nil then
		local cardItem = POKER_CARDS[pokerIndex]
		SetTablePokerCardVisible(cardItem, pokerCard.Visible)
		RefreshSettlementPartOfPokerCard(pokerIndex)
		--翻牌音效
		PlaySoundEffect(4)
	end
end

-- 有玩家的开牌动画1
function HandleOpenPokerCardAnimationStepOne(roleType)
	ResetPokerCardTypeToVisible(roleType, true)
	for	i = 2, 3, 1 do
		local pokerIndex = i + (roleType - 1) * 3
		local pokerCard = GameData.RoomInfo.CurrentRoom.Pokers[pokerIndex]
		local cardItem = POKER_CARDS[pokerIndex]
		SetTablePokerCardVisible(cardItem, true)
		cardItem.gameObject:SetActive(true)
		local pageCurl = this.transform:Find('Canvas/PokerHandle/HandleCard'..i):GetComponent("PageCurl")
		pageCurl.gameObject:SetActive(false)
		lua_Clear_AllUITweener(cardItem)
		if pageCurl.IsSpriteRotated then
			cardItem.eulerAngles = CS.UnityEngine.Vector3(0 , 0, 90)
			local script = cardItem.gameObject:AddComponent(typeof(CS.TweenRotation))
			script.from = CS.UnityEngine.Vector3(0 , 0, 90)
			script.to = CS.UnityEngine.Vector3.zero
			script.duration = 0.2
			script:OnFinished("+", (function () CS.UnityEngine.Object.Destroy(script) end))
			script:Play(true)
		else
			cardItem.eulerAngles = CS.UnityEngine.Vector3(0 , 0, 0)
		end
	end
	this:DelayInvoke(0.5, function () HandleOpenPokerCardAnimationStepTwo(roleType) end)
end

-- 有玩家的开牌动画2
function HandleOpenPokerCardAnimationStepTwo(roleType)
	---- 扑克牌飞回到原始位置
	for	i = 2, 3, 1 do
		local pokerIndex = i + (roleType-1) * 3
		local pokerCard = GameData.RoomInfo.CurrentRoom.Pokers[pokerIndex]
		local cardItem = POKER_CARDS[pokerIndex]
		cardItem.gameObject:SetActive(true)
		local script = cardItem.gameObject:AddComponent(typeof(CS.TweenTransform))
		script.to = POKER_JOINTS[pokerIndex]
		script.duration = 0.5
		script:OnFinished("+",
		(function ()
			CS.UnityEngine.Object.Destroy(script)
			cardItem:GetComponent("Image"):ResetSpriteByName(GameData.GetPokerCardSpriteName(pokerCard))
		end))
		script:Play(true)
	end
end

-- 回收桌面上的扑克牌
function CollectPokerCardsOnTable(isInit)
	if isInit then
		if GameData.RoomInfo.CurrentRoom.CountDown < 3 then
			return
		end
	end
	local delayTime = GameData.RoomInfo.CurrentRoom.CountDown - 2
	this:DelayInvoke(delayTime, CollectPokerCardsAnimationStepOne)
end

-- 收牌动画第一段
function CollectPokerCardsAnimationStepOne()
	ResetPokerCardTypeToVisible(1, false)
	ResetPokerCardTypeToVisible(2, false)
	for index = 1, 6, 1 do
		local pokerCard = POKER_CARDS[index]
		if pokerCard ~= nil then
			local script = pokerCard.gameObject:AddComponent(typeof(CS.TweenTransform))
			script.to = POKER_JOINTS[98]
			script.duration = 0.3
			script:OnFinished("+",
			function ()
				if script ~= nil then
					CS.UnityEngine.Object.Destroy(script)
				end
				CollectPokerCardsAnimationStepTwo(pokerCard, script)
			end)
			script:Play(true)
		end
	end
end

-- 收牌动画第二段
function CollectPokerCardsAnimationStepTwo(pokerCard, script)
	local tweenPosition = pokerCard.gameObject:AddComponent(typeof(CS.TweenTransform))
	tweenPosition.to = POKER_JOINTS[99]
	tweenPosition.duration = 0.4
	tweenPosition:OnFinished("+", function ()
		pokerCard.gameObject:SetActive(false)
		if tweenPosition ~= nil then
			CS.UnityEngine.Object.Destroy(tweenPosition)
		end
	end)
	tweenPosition:Play(true)
end

---------------------------------------------------------------------------
------------------------搓牌相关功能---------------------------------------
function StartEnterCheckAnimation(roleType, isHandler, isAni)
	-- 对应角色的扑克牌
	local pokerIndex2 = roleType * 3 - 1
	local pokerIndex3 = roleType * 3 - 0
	local pokerCard2 = GameData.RoomInfo.CurrentRoom.Pokers[pokerIndex2]
	local pokerCard3 = GameData.RoomInfo.CurrentRoom.Pokers[pokerIndex3]
	-- 设置 可操作的牌
	local handleCard2 = this.transform:Find('Canvas/PokerHandle/HandleCard2'):GetComponent("PageCurl")
	handleCard2:ResetSprites(GameData.GetPokerCardBackSpriteNameOfBig(pokerCard2),GameData.GetPokerCardSpriteNameOfBig(pokerCard2))
	
	local handleCard3 = this.transform:Find('Canvas/PokerHandle/HandleCard3'):GetComponent("PageCurl")
	handleCard3:ResetSprites(GameData.GetPokerCardBackSpriteNameOfBig(pokerCard3),GameData.GetPokerCardSpriteNameOfBig(pokerCard3))
	handleCard2.UserData = pokerIndex2
	handleCard2.gameObject:SetActive(false)
	handleCard3.UserData = pokerIndex3
	handleCard3.gameObject:SetActive(false)
	local pokerCard2Item = POKER_CARDS[pokerIndex2]
	local pokerCard3Item = POKER_CARDS[pokerIndex3]
	if isHandler then
		AddEventOfHandlePokerCard(handleCard2)
		AddEventOfHandlePokerCard(handleCard3)
		pokerCard2Item:GetComponent("Image"):ResetSpriteByName(GameData.GetPokerCardSpriteNameOfBig(pokerCard2))
		pokerCard3Item:GetComponent("Image"):ResetSpriteByName(GameData.GetPokerCardSpriteNameOfBig(pokerCard3))
		CheckStartAnimation(pokerCard2Item, POKER_JOINTS[pokerIndex2], POKER_JOINTS.HANDLER[2], handleCard2, isHandler, isAni)
		CheckStartAnimation(pokerCard3Item, POKER_JOINTS[pokerIndex3], POKER_JOINTS.HANDLER[3], handleCard3, isHandler, isAni)
	else
		CheckStartAnimation(pokerCard2Item, POKER_JOINTS[pokerIndex2], POKER_JOINTS.OBSERVER[pokerIndex2], handleCard2, isHandler, isAni)
		CheckStartAnimation(pokerCard3Item, POKER_JOINTS[pokerIndex3], POKER_JOINTS.OBSERVER[pokerIndex3], handleCard3, isHandler, isAni)
	end
	
	RefreshHandlePokerCardVisibleChanged(pokerIndex2,true)
	RefreshHandlePokerCardVisibleChanged(pokerIndex3,true)
end

function RefreshOpenPokerCardButtonState(isHandler, isActive)
	local openPokerButton = this.transform:Find('Canvas/PokerHandle/ButtonOpen')
	if isHandler then
		isUpdateOpenPokerCountDown = isActive
		openPokerButton.gameObject:SetActive(isActive)
	else
		openPokerButton.gameObject:SetActive(false)
		isUpdateOpenPokerCountDown = false
	end
end

function UpdateOpenPokerCardCountDown()
	if isUpdateOpenPokerCountDown == true then
		local countDown = GameData.RoomInfo.CurrentRoom.CountDown
		if countDown < 0 then
			countDown = 0
		end
		this.transform:Find('Canvas/PokerHandle/ButtonOpen/CountDown'):GetComponent("Text").text = tostring(math.ceil(countDown))
	end
end

function UpdateCheckCardCountDown()
	if isUpdateCheckCardCountDown then
		local countDown = GameData.RoomInfo.CurrentRoom.CountDown
		if countDown < 0 then
			countDown = 0
			isUpdateCheckCardCountDown = false
		end
		
		local checkCountDown = nil
		local maxValue = 15
		if GameData.RoomInfo.CurrentRoom.RoomState == ROOM_STATE.CHECK1 then
			checkCountDown = this.transform:Find('Canvas/BetRank/Area4Rank/RankFirst/CountDown')
			maxValue = ROOM_TIME[ROOM_STATE.CHECK1]
		elseif GameData.RoomInfo.CurrentRoom.RoomState == ROOM_STATE.CHECK2 then
			checkCountDown = this.transform:Find('Canvas/BetRank/Area5Rank/RankFirst/CountDown')
			maxValue = ROOM_TIME[ROOM_STATE.CHECK2]
		end
		
		if checkCountDown ~= nil then
			checkCountDown.gameObject:SetActive(isUpdateCheckCardCountDown)
			local fillAmount = countDown / maxValue
			checkCountDown:Find('ValueText'):GetComponent("Text").text = tostring(math.ceil(countDown))
			local countDownProgress = checkCountDown:Find('CountDown1'):GetComponent("Image")
			countDownProgress.fillAmount = fillAmount
			if fillAmount > 0.63 then
				countDownProgress.color = m_CheckColorOf1
			elseif fillAmount > 0.38 then
				countDownProgress.color = m_CheckColorOf2
			else
				countDownProgress.color = m_CheckColorOf3
			end
		end
	end
end

function CheckStartAnimation(cardItem, from, to, handleCard, isHandler, isAni)
	handleCard.transform.position = to.position
	if isAni then
		local script = cardItem.gameObject:AddComponent(typeof(CS.TweenTransform))
		script.from = from
		script.to = to
		script.duration = 0.4
		script:OnFinished("+", (function () CheckStartAnimationEnd(cardItem, script, handleCard, isHandler) end))
		script:Play(true)
	else
		lua_Paste_Transform_Value(cardItem, to)
		CheckStartAnimationEnd(cardItem, script, handleCard, isHandler)
	end
end

function CheckStartAnimationEnd(cardItem, script, handleCard, isHandler)
	CS.UnityEngine.Object.Destroy(script)
	cardItem.gameObject:SetActive(false)
	handleCard.gameObject:SetActive(true)
	if isHandler then
		handleCard:ResetPageCurl(444, 300, true, true)
	else
		handleCard:ResetPageCurl(177, 120, true, false)
	end
end

function AddEventOfHandlePokerCard(handleCard)
	handleCard:OpenCardCallBack('-', OpenOneCard)
	handleCard:OpenCardCallBack('+', OpenOneCard)
	handleCard:PageChangedEvent('-', HandlePageChangedEvent)
	handleCard:PageChangedEvent('+', HandlePageChangedEvent)
end

function OpenOneCard(userData)
	local pokerIndex = tonumber(userData)
	local index = (pokerIndex % 3)
	local isLastOne = false
	
	if index == 2 then
		local pokerCard = GameData.RoomInfo.CurrentRoom.Pokers[pokerIndex+1]
		if (pokerCard.Visible) then
			isLastOne = true
		end
	else
		index = 3
		local pokerCard = GameData.RoomInfo.CurrentRoom.Pokers[pokerIndex-1]
		if (pokerCard.Visible) then
			isLastOne = true
		end
	end
	
	if isLastOne then
		NetMsgHandler.Send_CS_Checked_Card(4)
	else
		NetMsgHandler.Send_CS_Checked_Card(index)
	end
end

function HandlePageChangedEvent(userData)
	local pokerIndex = tonumber(userData)
	local index = (pokerIndex % 3)
	if index ~= 2 then
		index = 3
	end
	local pageCurl = this.transform:Find('Canvas/PokerHandle/HandleCard'..index):GetComponent("PageCurl")
	local rotated = pageCurl.IsSpriteRotated
	local flipMode = pageCurl.FlipModeValue
	local moveSpace = pageCurl.MoveSpace
	NetMsgHandler.Send_CS_Check_Card_Process(pokerIndex, rotated, flipMode, moveSpace.x, moveSpace.y)
end

function RefreshHandlePokerCard(eventArg)
	if eventArg ~= nil then
		if eventArg.HandlerID == GameData.RoleInfo.AccountID then
			return
		else
			if this.gameObject.activeSelf then
				local index = (eventArg.PokerIndex % 3)
				if index == 0 then
					index = 3
				end
				
				local pageCurl = this.transform:Find('Canvas/PokerHandle/HandleCard'..index):GetComponent("PageCurl")
				if eventArg.IsRotate ~= pageCurl.IsSpriteRotated then
					pageCurl:RotatePage()
				end
				pageCurl:UpdatePage(CS.UnityEngine.Vector3(eventArg.MoveX, eventArg.MoveY, 0) / 2.5, eventArg.FlipMode)
			end
		end
	end
end

-- 操作的牌显示发生改变 (disablePlay：由于策划需求搓牌提示时不需要播放翻牌音效故+此参数)
function RefreshHandlePokerCardVisibleChanged(pokerIndex,disablePlay)
	local pokerCard = GameData.RoomInfo.CurrentRoom.Pokers[pokerIndex]
	if pokerCard.Visible then
		local handleIndex = (pokerIndex - 1) % 3 + 1
		local pageCurl = this.transform:Find('Canvas/PokerHandle/HandleCard'..handleIndex):GetComponent("PageCurl")
		pageCurl:OpenCard()
	end
	RefreshSettlementPartOfPokerCard(pokerIndex)
	--翻牌音效
	if true ~= disablePlay then
		PlaySoundEffect(4)
	end
end

-------------------------------------------------------------------------------------------------
---------------------------------------设置扑克牌的牌型------------------------------------------
function RefreshCurrentGamePokerCardType()
	for roleType = 1, 2 ,1 do
		local pokerType = GameData.GetRolePokerTypeDisplayName(roleType)
		this.transform:Find('Canvas/PokerHandle/Result/SettlementCards/PokerType'..roleType):GetComponent("Text").text = pokerType
		this.transform:Find('Canvas/DealPokers/PokerType'..roleType):GetComponent("Text").text = pokerType
	end
end

-- 刷新统计区域和桌子上的扑克牌型显示
function ResetPokerCardTypeToVisible(roleType, isActive)
	if roleType == 1 or roleType == 2 then
		this.transform:Find('Canvas/PokerHandle/Result/SettlementCards/PokerType'..roleType).gameObject:SetActive(isActive)
		this.transform:Find('Canvas/DealPokers/PokerType'..roleType).gameObject:SetActive(isActive)
	end
end

function ResetPokerCardTypeToVisibleByCardVisible()
	local roleType1IsActive = true
	for	 index = 1 ,3 ,1 do
		if not GameData.RoomInfo.CurrentRoom.Pokers[index].Visible then
			roleType1IsActive = false
			break
		end
	end
	
	local roleType2IsActive = true
	for	 index = 4 ,6 ,1 do
		if not GameData.RoomInfo.CurrentRoom.Pokers[index].Visible then
			roleType2IsActive = false
			break
		end
	end
	ResetPokerCardTypeToVisible(1, roleType1IsActive)
	ResetPokerCardTypeToVisible(2, roleType2IsActive)
end

-------------------------------------------------------------------------------------------------
---------------------------------------设置结算区域内容------------------------------------------
function GetSealIconNameByGameResult(gameResult)
	if CS.Utility.GetLogicAndValue(gameResult, WIN_CODE.LONG) == WIN_CODE.LONG then
		return 'sprite_Seal_1'
	elseif CS.Utility.GetLogicAndValue(gameResult, WIN_CODE.HU) == WIN_CODE.HU then
		return 'sprite_Seal_2'
	elseif CS.Utility.GetLogicAndValue(gameResult, WIN_CODE.HE) == WIN_CODE.HE then
		return 'sprite_Seal_4'
	else
		return 'sprite_Seal_4'
	end
end

-- 刷新统计区域的扑克牌信息
function RefreshSettlementPartOfPokerCard(pokerIndex)
	local pokerCard = GameData.RoomInfo.CurrentRoom.Pokers[pokerIndex]
	local cardItem = this.transform:Find('Canvas/PokerHandle/Result/SettlementCards/Card' .. pokerIndex)
	local cardSpriteName = GameData.GetPokerDisplaySpriteName(pokerCard)
	cardItem:GetComponent("Image"):ResetSpriteByName(cardSpriteName)
	cardItem.gameObject:SetActive(true)
end

function RefreshSettlementPartOfGameRoomByState(roomState, isInit)
	local settlementRoot = this.transform:Find('Canvas/PokerHandle/Result')
	settlementRoot.gameObject:SetActive(roomState > ROOM_STATE.DEAL)
	if roomState == ROOM_STATE.SETTLEMENT then
		settlementRoot:Find('Seal'):GetComponent("Image"):ResetSpriteByName(GetSealIconNameByGameResult(GameData.RoomInfo.CurrentRoom.GameResult))
		SettlementAllAnimations(isInit)
	end
end

function SettlementAllAnimations(isInit)
	local elapseTime = 0
	if isInit then
		elapseTime = ROOM_TIME[ROOM_STATE.SETTLEMENT] - GameData.RoomInfo.CurrentRoom.CountDown
	end
	
	if elapseTime < 0.1 then
		PlayLongBeginAudio() -- 龙
	end
	if elapseTime < 0.5 then
		this:DelayInvoke(0.5 - elapseTime, PlayLongPokerTypeAudio) -- 龙牌型
	end
	if elapseTime < 1.5 then
		this:DelayInvoke(1.5 - elapseTime, PlayHuBeginAudio) -- 虎
	end
	if elapseTime < 2.0 then
		this:DelayInvoke(2.0 - elapseTime, PlayHuPokerTypeAudio) -- 虎牌型
	end
	if elapseTime < 3.3 then
		this:DelayInvoke(3.3 - elapseTime, function() HandleShowGameResult(true) end) -- 显示印章
	else
		HandleShowGameResult(false)
	end
	
	-- 开始收筹码
	if not isInit then
		isStartCollect = false
		RefreshIsAniNeedWaitResult()
		this:DelayInvoke(3.3 - elapseTime, CollectChips)
	end
end

function HandleShowGameResult(isAudio)
	if isAudio then
		PlayGameWinCodeAudio() -- 胜负结果
	end
	ShowGameResultSeal(isAudio)-- 直接显示印章不播放音效
	HandleBetAreaAnimation(2) -- 押注区域开始闪烁
	if GameData.RoomInfo.CurrentRoom.AppendStatisticsEventArgs ~= nil then
		CS.EventDispatcher.Instance:TriggerEvent(EventDefine.UpdateStatistics, GameData.RoomInfo.CurrentRoom.AppendStatisticsEventArgs)
	end
end

function PlayLongBeginAudio()
	PlaySoundEffect(25)
end

function PlayLongPokerTypeAudio()
	PlayBrandTypeAudio(GameData.GetRolePokerType(1))
end

function PlayHuBeginAudio()
	PlaySoundEffect(24)
end

function PlayHuPokerTypeAudio()
	
	PlayBrandTypeAudio(GameData.GetRolePokerType(2))
end

--牌型音效
function PlayBrandTypeAudio(pokerType)
	local musicid = 26
	if pokerType == BRAND_TYPE.DUIZI then
		musicid = 27
	elseif  pokerType == BRAND_TYPE.SHUNZI then
		musicid = 28
	elseif  pokerType == BRAND_TYPE.JINHUA then
		musicid = 29
	elseif  pokerType == BRAND_TYPE.SHUNJIN then
		musicid = 30
	elseif  pokerType == BRAND_TYPE.BAOZI then
		musicid = 31
	else
		musicid = 26
	end
	PlaySoundEffect(musicid)
end

--胜负结果
function PlayGameWinCodeAudio()
	local gameResult = GameData.RoomInfo.CurrentRoom.GameResult
	if CS.Utility.GetLogicAndValue(gameResult, WIN_CODE.LONG) == WIN_CODE.LONG then
		PlaySoundEffect(32)
	elseif CS.Utility.GetLogicAndValue(gameResult, WIN_CODE.HU) == WIN_CODE.HU then
		PlaySoundEffect(33)
	elseif CS.Utility.GetLogicAndValue(gameResult, WIN_CODE.HE) == WIN_CODE.HE then
		PlaySoundEffect(34)
	end
end

--显示本局结果印章
function ShowGameResultSeal(isMusic)
	if isMusic == true then
		PlaySoundEffect(6)
	end
	this.transform:Find('Canvas/PokerHandle/Result/Seal').gameObject:SetActive(true)
end

--游戏状态变化音效播放接口
function PlaySoundEffect(musicid)
	-- body
	--print(string.format( "=====游戏状态:[%d] 冷却CD:[%f]", GameData.RoomInfo.CurrentRoom.RoomState,GameData.RoomInfo.CurrentRoom.CountDown))
	if true == canPlaySoundEffect then
		MusicMgr:PlaySoundEffect(musicid)
	end
end

--------------------------------------------------------------------------------------------
-----------------------------------处理筹码相关---------------------------------------------

function ChipValueOnValueChanged(isOn, chipValue)
	if isOn then
		GameData.RoomInfo.CurrentRoom.SelectBetValue = chipValue
	end
end

---------------------------------------------------------------------------
------------------------------CS_Bet  311----------------------------------
-- 押注区域被点击了
function BetAreaButtonOnClick(areaType)
	-- 发送押注信息, 非押注阶段不可押注, 押注倒计时期间
	if isUpdateBetCountDown then
		if GameData.RoomInfo.CurrentRoom.RoomState == ROOM_STATE.BET then
			-- 如果是庄家，直接返回
			if GameData.RoleInfo.AccountID == GameData.RoomInfo.CurrentRoom.BankerInfo.ID then
				return
			end
			
			if GameData.RoomInfo.CurrentRoom.SelectBetValue > 0 then
				NetMsgHandler.Send_CS_Bet(areaType, GameData.RoomInfo.CurrentRoom.SelectBetValue)
			else
				CS.BubblePrompt.Show("请选择筹码", "GameUI2")
			end
		end
	end
end


-- 押注筹码到桌子上
function BetChipToDesk(areaType, betValue, roleID)
	local startPoint = nil
	if roleID == GameData.RoleInfo.AccountID then
		-- 如果是自己，则从自己点开始， 否则从其他玩家点开始
		startPoint = CHIP_JOINTS[11]
	else
		startPoint = CHIP_JOINTS[12]
	end
	
	CastChipToBetArea(areaType, betValue, tostring(roleID), true, startPoint.JointPoint.position)
	
	--押注筹码音效
	PlaySoundEffect(5)
end

function HandleNotifyBetResult(eventArgs)
	if eventArgs.ResultType == 0 then
		BetChipToDesk(eventArgs.AreaType, eventArgs.BetValue, eventArgs.RoleID)
	else
		local betAreaItem = this.transform:Find('Canvas/BetChipHandle/BetArea/Area'.. eventArgs.AreaType)
		if betAreaItem ~= nil then
			betAreaItem:GetComponent("SwitchAnimation"):Play(1)
		end
		CS.BubblePrompt.Show(data.GetString("Bet_Error_" .. eventArgs.ResultType), "GameUI2")
	end
end

----------------------------------------------------------------------------------------------
-----------------------------------处理筹码赔付相关-------------------------------------------
function ResetChipsInteractable(forceInteractableFalse)
	local roleGold = 0
	if GameData.RoomInfo.CurrentRoom.IsFreeRoom then
		roleGold = GameData.RoleInfo.FreeGoldCount
	else
		roleGold = GameData.RoleInfo.GoldCount
	end
	local selectChipRoot = this.transform:Find('Canvas/BetChipHandle/Chips/Viewport/Content')
	for	index = 1, 10, 1 do
		local chipItem = selectChipRoot:Find('Chip'.. index):GetComponent("Toggle")
		if forceInteractableFalse then
			RefreshChipInteractable(chipItem, false)
		else
			local chipValue = CHIP_VALUE[index]
			if not IsChipCanBeUsedInCurrentRoom(index) or roleGold < chipValue then
				RefreshChipInteractable(chipItem, false)
			else
				RefreshChipInteractable(chipItem, true)
			end
		end
	end
end

function RefreshChipInteractable(chipItem, interactable)
	if not interactable then
		if chipItem.isOn then
			local toggleGroup = chipItem.group
			toggleGroup.allowSwitchOff = true
			
			chipItem.isOn = false
			GameData.RoomInfo.CurrentRoom.SelectBetValue = 0
			
			toggleGroup.allowSwitchOff = false
		end
	end
	chipItem.interactable = interactable
end

function IsChipCanBeUsedInCurrentRoom(chipIndex)
	local roomConfig = data.RoomConfig[GameData.RoomInfo.CurrentRoom.TemplateID]
	if roomConfig ~= nil then
		return lua_TableContainsValue(roomConfig.CanUseChip, chipIndex)
	end
	return false
end

----------------------------------------------------------------------------------------------
-------------------------显示押注区域动画-----------------------------------------------------
function HandleBetAreaAnimation(aniType)
	local betAreaRoot = this.transform:Find('Canvas/BetChipHandle/BetArea')
	if aniType == 1 then
		for index = 1, 5, 1 do
			-- 打开线条灯光
			local areaAni = betAreaRoot:Find('Area' .. index .. '/LineLight')
			areaAni.gameObject:SetActive(true)
			areaAni:GetComponent("TweenAlpha"):ResetToBeginning()
			areaAni:GetComponent("TweenAlpha"):Play(true)
		end
	elseif aniType == 2 then
		local gameResult = GameData.RoomInfo.CurrentRoom.GameResult
		for index = 1, 5, 1 do
			-- 打开区域灯光
			local areaAni = betAreaRoot:Find('Area' .. index .. '/AreaLight')
			if CS.Utility.GetLogicAndValue(gameResult, AREA_WIN_CODE[index]) == AREA_WIN_CODE[index] then
				-- 只有赢得区域闪烁
				areaAni.gameObject:SetActive(true)
				areaAni:GetComponent("TweenAlpha"):ResetToBeginning()
				areaAni:GetComponent("TweenAlpha"):Play(true)
			else
				areaAni.gameObject:SetActive(false)
			end
		end
	else
		for index = 1, 5, 1 do
			-- 关闭区域灯光
			betAreaRoot:Find('Area' .. index .. '/AreaLight').gameObject:SetActive(false)
			-- 关闭线条灯光
			betAreaRoot:Find('Area' .. index .. '/LineLight').gameObject:SetActive(false)
		end
	end
end

-- 设置押注区域值
function HandleBetValueChanged(arg)
	if arg ~= 1 then
		for index = 1, 5, 1 do
			local betValue = GameData.RoomInfo.CurrentRoom.BetValues[index]
			local betValueText = this.transform:Find('Canvas/BetChipHandle/BetValue/Value'.. index):GetComponent("Text")
			if betValue ~= nil and betValue > 0 then
				betValueText.gameObject:SetActive(true)
				betValueText.text = lua_NumberToStyle1String(GameConfig.GetFormatColdNumber(betValue))
				RefreshBetRankListPartOfMine(betValue, index)
			else
				betValueText.gameObject:SetActive(false)
				betValueText.text = "0"
				RefreshBetRankListPartOfMine(0, index)
			end
		end
		-- 刷新下离开房间状态
		RefreshExitRoomButtonState(false)
	end
	for index = 1, 5, 1 do
		local betValue = GameData.RoomInfo.CurrentRoom.TotalBetValues[index]
		local backImage = this.transform:Find('Canvas/BetChipHandle/TotalBetValue/Image'.. index)
		local betValueText = this.transform:Find('Canvas/BetChipHandle/TotalBetValue/Value'.. index):GetComponent("Text")
		if betValue ~= nil and betValue > 0 then
			betValueText.gameObject:SetActive(true)
			betValueText.text = lua_NumberToStyle1String(GameConfig.GetFormatColdNumber(betValue))
			backImage.gameObject:SetActive(true)
		else
			betValueText.gameObject:SetActive(false)
			betValueText.text = "0"
			backImage.gameObject:SetActive(false)
		end
	end
end

function RefreshIsAniNeedWaitResult()
	isNeedWait = false
	local gameResult = GameData.RoomInfo.CurrentRoom.GameResult
	for index = 1, 5, 1 do
		if CS.Utility.GetLogicAndValue(gameResult, AREA_WIN_CODE[index]) == AREA_WIN_CODE[index] then
			local betValue = GameData.RoomInfo.CurrentRoom.BetValues[index]
			if betValue ~= nil and betValue > 0 then
				isNeedWait = true
				return
			end
		end
	end
	isNeedWait = false
end

-------------------------------------------------------------------------
-----------------------处理筹码赔付相关----------------------------------
function CollectChips()
	isStartCollect = true
	StartCollectChipsAni()
end

function HandleNotifyWinGold(arg)
	isReceiveResult = true
	StartCollectChipsAni()
end

function StartCollectChipsAni()
	if isStartCollect then
		if isNeedWait then
			if not isReceiveResult then
				return
			end
		end
	else
		return
	end
	
	-- 开始播放动画
	CollectLoseAreaChips()
	isNeedWait = false
	isReceiveResult = false
end

-- 为筹码增加 0- 0.5s 的延迟，让其错乱飞
function AddRandomDelayForChip(script)
	script.delay = CS.UnityEngine.Random.Range(0, 0.5)
end


-- 为筹码音效增加 0 - 0.3 的延迟,让其感觉音效很多
function DelayPlayAudioForChip(chipAllCount)
	-- body
	--print("=====AllCount:"..chipAllCount)
	if chipAllCount > 0 then
		local limitCount = 4
		for i=1,chipAllCount do
			if i > limitCount then
				break
			end
			local delayTime = CS.UnityEngine.Random.Range(0, 0.3)
			this:DelayInvoke(delayTime, function () PlaySoundEffect(7) end)
		end
	end
end


-- 筹码飞向庄家
function CollectLoseAreaChips()
	if isDestroy then
		return
	end
	local gameResult = GameData.RoomInfo.CurrentRoom.GameResult
	local isDogfall = CS.Utility.GetLogicAndValue(gameResult, WIN_CODE.HE) == WIN_CODE.HE
	local lastTime = 0.5
	local collectMaxArea = 3
	if not isDogfall then
		collectMaxArea = 5
	end
	local endPoint = CHIP_JOINTS[13].JointPoint.position
	if GameData.RoomInfo.CurrentRoom.BankerInfo.ID == GameData.RoleInfo.AccountID then
		endPoint = CHIP_JOINTS[11].JointPoint.position
	end
	
	local gameResult = GameData.RoomInfo.CurrentRoom.GameResult
	local isPlayed = false
	-- 筹码计数
	local chipCount = 0
	for areaIndex = 1, collectMaxArea, 1 do
		if CS.Utility.GetLogicAndValue(gameResult, AREA_WIN_CODE[areaIndex]) ~= AREA_WIN_CODE[areaIndex] then
			-- 筹码飞向庄家
			local chipJoint = CHIP_JOINTS[areaIndex].JointPoint
			local childCount = chipJoint.childCount
			chipCount = chipCount + childCount
			isPlayed = true
			for index = childCount - 1, 0, -1 do
				local chipItem = chipJoint:GetChild(index)
				local script = CS.TweenPosition.Begin(chipItem.gameObject, lastTime, endPoint, true)
				AddRandomDelayForChip(script)
				script:OnFinished('+',( function () HandleAnimationPlayEnd(chipItem) end))
				script:Play(true)
			end
		end
	end
	-- 筹码音效11111
	--print("=====11111111111111111111111")
	DelayPlayAudioForChip(chipCount)
	
	if isPlayed then
		this:DelayInvoke(1.2, BankerThrowChipsToLostArea)
	else
		BankerThrowChipsToLostArea()
	end
end

-- 庄家筹码飞向桌面
function BankerThrowChipsToLostArea()
	if isDestroy then
		return
	end
	
	local lastTime = 0.5
	local roleIDStr = tostring(GameData.RoleInfo.AccountID)
	local startPoint = CHIP_JOINTS[13].JointPoint.position
	if GameData.RoomInfo.CurrentRoom.BankerInfo.ID == GameData.RoleInfo.AccountID then
		startPoint = CHIP_JOINTS[11].JointPoint.position
	end
	
	local gameResult = GameData.RoomInfo.CurrentRoom.GameResult
	local isPlayed = false
	
	-- 筹码计数
	local chipCount = 0
	for areaIndex = 1, 5, 1 do
		if CS.Utility.GetLogicAndValue(gameResult, AREA_WIN_CODE[areaIndex]) == AREA_WIN_CODE[areaIndex] then
			local chipArea = CHIP_JOINTS[areaIndex]
			local chipJoint = chipArea.JointPoint
			local childCount = chipJoint.childCount
			local payCount = COMPENSATE[areaIndex]
			local winGoldInfo = GameData.RoomInfo.CurrentRoom.WinGold[areaIndex]
			local areaWinGold = 0
			if winGoldInfo ~= nil then
				areaWinGold = winGoldInfo.WinGold
			end
			
			if GameData.RoomInfo.CurrentRoom.BetValues[areaIndex] ~= nil then
				GameData.RoomInfo.CurrentRoom.BetValues[areaIndex] = GameData.RoomInfo.CurrentRoom.BetValues[areaIndex] + areaWinGold
			end
			
			chipCount = chipCount + childCount
			isPlayed = true
			for index = childCount - 1, 0, -1 do
				local chipItem = chipJoint:GetChild(index)
				local chipItemName = chipItem.gameObject.name
				local chipItemValue = tonumber(chipItem:GetChild(0).gameObject.name)
				for i = 1, payCount, 1 do
					if chipItemName == roleIDStr then
						if areaWinGold > 0 and chipItemValue <= areaWinGold then
							areaWinGold = areaWinGold - chipItemValue
						else
							break
						end
					end
					
					local newChips = CS.UnityEngine.Object.Instantiate(chipItem)
					CS.Utility.ReSetTransform(newChips, chipJoint)
					newChips.gameObject.name = chipItemName
					newChips.position = startPoint
					local localX = math.random(chipArea.RangeX.Min, chipArea.RangeX.Max)
					local localY = math.random(chipArea.RangeY.Min, chipArea.RangeY.Max)
					local script = CS.TweenPosition.Begin(newChips.gameObject, lastTime, CS.UnityEngine.Vector3(localX, localY, 0), false)
					AddRandomDelayForChip(script)
					script:Play(true)
				end
			end
			
			if areaWinGold > 0 then
				-- 赔付后还有剩余金额不能用筹码赔付
				areaWinGold = areaWinGold + CHIP_VALUE[1] / 2
				-- 加上半个筹码值，便于后续取整
				for index = 10, 1, -1 do
					local count = math.floor(areaWinGold / CHIP_VALUE[index])
					--筹码计数
					chipCount = chipCount + count
					
					for i = 1, count, -1 do
						-- 丢入筹码
						local newChips = CS.UnityEngine.Object.Instantiate(CHIP_MODEL[CHIP_VALUE[index]])
						CS.Utility.ReSetTransform(newChips, chipJoint)
						newChips.gameObject.name = roleIDStr
						newChips.position = startPoint
						local localX = math.random(chipArea.RangeX.Min, chipArea.RangeX.Max)
						local localY = math.random(chipArea.RangeY.Min, chipArea.RangeY.Max)
						local script = CS.TweenPosition.Begin(newChips.gameObject, lastTime, CS.UnityEngine.Vector3(localX, localY, 0), false)
						AddRandomDelayForChip(script)
						script:Play(true)
					end
					areaWinGold = areaWinGold - count * CHIP_VALUE[index]
				end
			end
		end
	end
	-- 筹码音效22222
	--print("=====222222222222222222222")
	DelayPlayAudioForChip(chipCount)
	
	if isPlayed then
		this:DelayInvoke(1.5, HandleRoleCollectOwnChipAreas)
	else
		HandleRoleCollectOwnChipAreas()
	end
end

-- 玩家收筹码表现（赢得筹码和 和的筹码）
function HandleRoleCollectOwnChipAreas()
	if isDestroy then
		return
	end
	HandleBetValueChanged(3)
	HandleSettlementGetGoldShowTip()
	
	local isPlayed = false
	local roleIDStr = tostring(GameData.RoleInfo.AccountID)
	local lastTime = 0.5
	-- 筹码计数
	local chipCount = 0
	for areaIndex = 1, 5, 1 do
		local chipJoint = CHIP_JOINTS[areaIndex].JointPoint
		if chipJoint ~= nil then
			local childCount = chipJoint.childCount
			-- 筹码计数
			chipCount = chipCount + childCount
			for index = childCount - 1, 0, -1 do
				isPlayed = true
				local chipItem = chipJoint:GetChild(index)
				local endPoint = CHIP_JOINTS[12].JointPoint.position
				if chipItem.gameObject.name == roleIDStr then
					endPoint = CHIP_JOINTS[11].JointPoint.position
				end
				local script = CS.TweenPosition.Begin(chipItem.gameObject, lastTime, endPoint, true)
				AddRandomDelayForChip(script)
				script:OnFinished('+',( function () HandleAnimationPlayEnd(chipItem) end))
				script:Play(true)
			end
		end
	end
	-- 筹码音效33333
	--print("=====333333333333333333333")
	DelayPlayAudioForChip(chipCount)
end

function HandleSettlementGetGoldShowTip()
	if GameData.RoomInfo.CurrentRoom.WinGold.NoPayAll == true then
		CS.BubblePrompt.Show(string.format(data.GetString("Not_Pay_All_Tips"), GameData.RoomInfo.CurrentRoom.BankerInfo.Name), "GameUI2")
	end
	GameData.SyncDisplayGoldCount()
end

-- 销毁筹码
function HandleAnimationPlayEnd(chipItem)
	if isDestroy then
		return
	end
	CS.UnityEngine.Object.Destroy(chipItem.gameObject)
end

-----------------------------------------------------------------------------
-------------------重置已经在桌面上的筹码------------------------------------
function ResetBetChipsAlreadyOnTable(currentRoomChips)
	-- 遍历 押注区域
	for	areaType = 1, 5, 1 do
		lua_Transform_ClearChildren(CHIP_JOINTS[areaType].JointPoint, false)
		if currentRoomChips ~= nil and currentRoomChips[areaType]~= nil then -- 有押注值
			local betChips = currentRoomChips[areaType]
			local leftBetValue = GameData.RoomInfo.CurrentRoom.BetValues[areaType]
			if leftBetValue == nil then
				leftBetValue = 0
			end
			for	chipIndex = 10, 1, -1 do
				local chipValue = CHIP_VALUE[chipIndex]
				local chipInfo = betChips[chipValue]
				if chipInfo ~= nil then
					local chipCount = betChips[chipValue].Count
					if chipCount ~= nil then
						-- 创建等值的筹码
						for count = 1, chipCount, 1 do
							local chipName
							chipName, leftBetValue = HandleInitRoomChipsOfChipOwner(chipValue, leftBetValue)
							CastChipToBetArea(areaType, CHIP_VALUE[chipIndex], chipName, false, nil)
						end
					end
				end
			end
		end
	end
end

-- 划归初始化时某个的归属
function HandleInitRoomChipsOfChipOwner(chipValue, leftBetValue)
	if leftBetValue < chipValue then
		return "0", leftBetValue
	else
		leftBetValue = leftBetValue - chipValue
		return tostring(GameData.RoleInfo.AccountID), leftBetValue
	end
end

-- 向押注区域投掷筹码
function CastChipToBetArea(areaType, chipValue, chipName, isAnimation, fromWorldPoint)
	local model = CHIP_MODEL[chipValue]
	if model ~= nil then
		local betChip = CS.UnityEngine.Object.Instantiate(model)
		betChip.gameObject.name = chipName
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

-----------------------------------------------------------------------------
-------------------处理押注排行榜相关内容------------------------------------

-- 刷新押注排行区域信息
function RefreshBetRankPartOfGameRoomByState(roomState, isInit)
	RefreshBetRankFirstInfo()
	if roomState == ROOM_STATE.BET then
		RefreshBetRankListPartOfRank(nil)
	else
		if roomState == ROOM_STATE.DEAL and isInit == false then
			-- 自然进入发牌状态时，不隐藏排行榜,播放动画
		else
			this.transform:Find('Canvas/BetRank/Area4Rank/RankListMask/RankList').gameObject:SetActive(false)
			this.transform:Find('Canvas/BetRank/Area5Rank/RankListMask/RankList').gameObject:SetActive(false)
		end
	end
end

-- 刷新自己押注信息
function RefreshBetRankListPartOfMine(betValue, areaIndex)
	if areaIndex == 4 or areaIndex == 5 then
		local rankListOfMineItem = this.transform:Find('Canvas/BetRank/Area' .. areaIndex .. 'Rank/RankListMask/RankList/Item4')
		rankListOfMineItem:Find('Value'):GetComponent("Text").text = lua_NumberToStyle1String(GameConfig.GetFormatColdNumber(betValue))
	end
end

function HandleBetEnd(arg)
	-- 播放动画
	local rankList4Trans = this.transform:Find('Canvas/BetRank/Area4Rank/RankListMask/RankList')
	local rankList5Trans = this.transform:Find('Canvas/BetRank/Area5Rank/RankListMask/RankList')
	if rankList4Trans.gameObject.activeSelf then
		RankListAnimation(rankList4Trans, CS.UnityEngine.Vector3(-302, 0,0),CS.UnityEngine.Vector3.zero, false)
	end
	if rankList5Trans.gameObject.activeSelf then
		RankListAnimation(rankList5Trans, CS.UnityEngine.Vector3(302, 0,0),CS.UnityEngine.Vector3.zero, false)
	end
	RefreshBetRankFirstInfo()
	HideOrShowDeskWord(1, true)
	HideOrShowDeskWord(2, true)
end

function RefreshBetRankFirstInfo()
	local area4RankFirst = this.transform:Find('Canvas/BetRank/Area4Rank/RankFirst')
	SetRankFirstInfo(area4RankFirst, GameData.RoomInfo.CurrentRoom.CheckRole1)
	
	local area5RankFirst = this.transform:Find('Canvas/BetRank/Area5Rank/RankFirst')
	SetRankFirstInfo(area5RankFirst, GameData.RoomInfo.CurrentRoom.CheckRole2)
end

function SetRankFirstInfo(firstTrans, firstInfo)
	if firstTrans == nil then
		return
	end
	
	firstTrans:Find('Name'):GetComponent("Text").text = firstInfo.Name
	
	if firstInfo.ID == 0 or firstInfo.Icon == "" then
		firstTrans:Find('FirstIcon').gameObject:SetActive(false)
	else
		firstTrans:Find('FirstIcon').gameObject:SetActive(true)
		firstTrans:Find('FirstIcon'):GetComponent("Image"):ResetSpriteByName(GameData.GetRoleIconSpriteName(firstInfo.Icon))
	end
end

-- 刷新排行信息
function RefreshBetRankListPartOfRank(arg)
	local betArea4Rank = GameData.RoomInfo.CurrentRoom.BetRankList[4]
	local betArea5Rank = GameData.RoomInfo.CurrentRoom.BetRankList[5]
	local rankList4 = this.transform:Find('Canvas/BetRank/Area4Rank/RankListMask/RankList')
	local rankList5 = this.transform:Find('Canvas/BetRank/Area5Rank/RankListMask/RankList')
	RefreshRankListPartOfRankInfos(rankList4, betArea4Rank, true)
	RefreshRankListPartOfRankInfos(rankList5, betArea5Rank, false)
end

function RefreshRankListPartOfRankInfos(rankListTrans ,rankData, isLeft)
	if rankData ~= nil and #rankData > 0 then
		if not rankListTrans.gameObject.activeSelf then
			local from = nil
			if isLeft then
				from = CS.UnityEngine.Vector3(-302, 0,0)
			else
				from = CS.UnityEngine.Vector3(302, 0,0)
			end
			RankListAnimation(rankListTrans, from ,CS.UnityEngine.Vector3.zero, true)
			rankListTrans.gameObject:SetActive(true)
			if isLeft then
				HideOrShowDeskWord(1, false)
			else
				HideOrShowDeskWord(2, false)
			end
		end
		for index = 1, 3, 1 do
			local rankInfo = rankData[index]
			local rankItem = rankListTrans:Find('Item' .. index)
			if rankInfo ~= nil then
				local colorValue =  "95BDB0FF" -- 排行榜中别人的颜色值
				if GameData.RoleInfo.AccountID == rankInfo.ID then
					colorValue =  "DBB54EFF" -- 排行榜中自己的颜色值
				end
				rankItem.gameObject:SetActive(true)
				rankItem.transform:Find('Name'):GetComponent("Text").text = string.format("<color=#%s>%s</color>", colorValue, rankInfo.Name)
				rankItem.transform:Find('Value'):GetComponent("Text").text = string.format("<color=#%s>%s</color>", colorValue, lua_NumberToStyle1String(GameConfig.GetFormatColdNumber(rankInfo.Value)))
			else
				rankItem.gameObject:SetActive(false)
			end
		end
	else
		rankListTrans.gameObject:SetActive(false)
	end
end

function RankListAnimation(tweenTrans, from, to, isForward)
	if tweenTrans ~= nil then
		local tweenAni = tweenTrans:GetComponent("TweenPosition")
		if tweenAni == nil then
			tweenAni = tweenTrans.gameObject:AddComponent(typeof(CS.TweenPosition))
		end
		
		tweenAni:ResetToBeginning()
		if isForward == true then
			tweenAni.from = from
			tweenAni.to = to
		else
			tweenAni.from = to
			tweenAni.to = from
		end
		tweenAni.enabled = true
		tweenAni:Play(true)
		tweenTrans.gameObject:SetActive(true)
	end
end

function HideOrShowDeskWord(wordIndex, isActive)
	this.transform:Find('Canvas/Back/Text' .. wordIndex).gameObject:SetActive(isActive)
end

function SitDownButtonOnClick()
	CS.BubblePrompt.Show("押注龙虎冠军可坐下", "GameUI2")
end

function DelayHideInviteLineLight(deltaTime)
	if isInviteLineLight == true then
		inviteLineLightTimeCount = inviteLineLightTimeCount + deltaTime
		if inviteLineLightTimeCount > 10 then
			this.transform:Find('Canvas/RoomInfo/ButtonInvite/LineLight').gameObject:SetActive(false)
			isInviteLineLight = false
			inviteLineLightTimeCount = 0
			print("时间到，关闭闪烁")
		end
	end
end

function HandleTryShowUserGuide()
	local showedGuide = CS.UnityEngine.PlayerPrefs.GetString("SHOWED_GUIDE", "0")
	if showedGuide ~= "1" then
		this.transform:Find("Canvas/UserGuide/GuideDesc").gameObject:SetActive(true)
		local iKnowButton =  this.transform:Find("Canvas/UserGuide/IKnowButton"):GetComponent("Button")
		iKnowButton.gameObject:SetActive(true)
		iKnowButton.onClick:AddListener(function ()
			this.transform:Find("Canvas/UserGuide").gameObject:SetActive(false)
		end)
		
		CS.UnityEngine.PlayerPrefs.SetString("SHOWED_GUIDE", "1")
	else
		this.transform:Find("Canvas/UserGuide").gameObject:SetActive(false)
	end
end