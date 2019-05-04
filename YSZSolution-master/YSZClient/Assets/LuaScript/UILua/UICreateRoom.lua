local betLevel = 101
local roomCount = 8
local betLevelSlider = nil
local betMinValueText = nil
local betMaxValueText = nil
local consumeText = nil
local roomType = 101
local consumeCount = 1

-- Unity MonoBehavior Awake 时调用此方法
function Awake()
	-- 返回按钮
    this.transform:Find('Canvas/Window/Title/ButtonBack'):GetComponent("Button").onClick:AddListener(ReturnButtonOnClick)
    this.transform:Find('Canvas/Window/ButtonCreate'):GetComponent("Button").onClick:AddListener(CreateRoomButton_OnClick)	
	betLevelSlider = this.transform:Find('Canvas/Window/Content/BetSetting/Slider'):GetComponent("Slider")
	betLevelSlider.onValueChanged:AddListener(BetLevelSlider_Value_Changed)
	betMinValueText = this.transform:Find('Canvas/Window/Content/BetSetting/MinValue'):GetComponent("Text")
	betMaxValueText = this.transform:Find('Canvas/Window/Content/BetSetting/MaxValue'):GetComponent("Text")
	    
	consumeText = this.transform:Find('Canvas/Window/Content/Consume/Count'):GetComponent("Text")
	for	index = 1, 3, 1 do
		local toggle = this.transform:Find('Canvas/Window/Content/CountSetting/Count'..index):GetComponent("Toggle")
		toggle.onValueChanged:AddListener(function(isOn) OnHandleRoundCount_Setting_Changed(index, isOn) end)
	end
	this.transform:Find('Canvas/Window/Content/CountSetting/Count1'):GetComponent("Toggle").isOn = true
	OnHandleRoundCount_Setting_Changed(1, true)
end

-- Unity MonoBehavior Start 时调用此方法
function Start()
	betLevel = betLevelSlider.value
	RefreshBetLevel()
end

-- 刷新显示
function RefreshBetLevel()
	local index = math.modf(betLevel) -- 浮点数取整
	local config = data.RoomConfig[index]
	roomType = index -- 房间类型 = 模板ID
	betMinValueText.text = lua_CommaSeperate(GameConfig.GetFormatColdNumber(config.BettingLongHu[1]))
	betMaxValueText.text = lua_CommaSeperate(GameConfig.GetFormatColdNumber(config.BettingLongHu[2]))
end

-- 局数选择变化响应
function OnHandleRoundCount_Setting_Changed(index, isOn)
	if isOn then
		local config = CREATE_ROOM_CONSUME[index]
		consumeCount = config.Consume
		consumeText.text = tostring(consumeCount)
		roomCount = config.Round		
	end
end

-- 响应 返回按钮 点击事件
function ReturnButtonOnClick()
	CS.WindowManager.Instance:CloseWindow('UICreateRoom', false)
end

-- 响应 押注等级 改变事件
function BetLevelSlider_Value_Changed(newValue)
	betLevel = newValue
	RefreshBetLevel()
end

-- 创建房间按钮响应
function CreateRoomButton_OnClick()
	if consumeCount <= GameData.RoleInfo.RoomCardCount then
	   NetMsgHandler.Send_CS_Create_Room(roomType, roomCount)
	else
		CS.BubblePrompt.Show(data.GetString("Create_Room_Error_4"), "UICreateRoom")
	end
	NetMsgHandler.Send_CS_JH_Create_Room(10,200,1,1,1,300,200)
end