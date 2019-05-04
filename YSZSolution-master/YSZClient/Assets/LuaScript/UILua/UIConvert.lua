local toGoldConsumeCountFiled = nil			-- 金币兑换输入框
local convertRoomCardCountField = nil		-- 房卡兑换输入框
local ConvertGoldClickRate = 10				-- 单击递增率
local ConvertGoldPressRate = 1				-- 长按递指数
local exchangeGoldConsume = 10				-- 兑换金币消耗钻石
local exchangeGold = 10						-- 兑换金币数量

local exchangeRoomCardConsume = 1			-- 兑换的房卡消耗钻石
local exchangeRoomCard = 1					-- 兑换的房卡数量

-- Unity MonoBehavior Awake 时调用此方法
function Awake()
	-- 注册房间按钮	
	this.transform:Find('Canvas/Window/ToggleGroup/TabGoldToggle'):GetComponent("Toggle").onValueChanged:AddListener(GoldTabOnClick);
	this.transform:Find('Canvas/Window/ToggleGroup/TabRoomCardToggle'):GetComponent("Toggle").onValueChanged:AddListener(RoomCardTabOnClick);	
	-- 增加关闭按钮
	this.transform:Find('Canvas/Window/Title/ButtonClose'):GetComponent("Button").onClick:AddListener(CloseConvertButton_OnClick);
	-- 金币
	this.transform:Find('Canvas/Window/Content/Gold/ConvertGoldTips'):GetComponent("Text").text = data.GetString("Convert_Gold_Tips")
	this.transform:Find('Canvas/Window/Content/Gold/ButtonAdd'):GetComponent("Button").onClick:AddListener(ConvertGoldAddButtonOnClick);
	this.transform:Find('Canvas/Window/Content/Gold/ButtonAdd'):GetComponent("OnButtonPressed").onPressed:AddListener(ConvertGoldAddButtonOnPressed);
	this.transform:Find('Canvas/Window/Content/Gold/ButtonAdd'):GetComponent("OnButtonPressed").onLongPressed:AddListener(ConvertGoldAddButtonOnLongPressed);
	this.transform:Find('Canvas/Window/Content/Gold/ButtonReduce'):GetComponent("Button").onClick:AddListener(ConvertGoldReduceButtonOnClick);
    toGoldConsumeCountFiled = this.transform:Find('Canvas/Window/Content/Gold/ConsumeCount'):GetComponent("InputField");
    toGoldConsumeCountFiled.onValueChanged:AddListener(ConvertGoldInputFieldValueChanged);
    this.transform:Find('Canvas/Window/Content/Gold/ButtonConvert'):GetComponent("Button").onClick:AddListener(ConvertGoldButtonOnClick)
    this.transform:Find('Canvas/Window/Content/Gold/ButtonConvertAll'):GetComponent("Button").onClick:AddListener(ConvertGoldAllButtonOnClick)
    -- 房卡
	this.transform:Find('Canvas/Window/Content/RoomCard/ConvertRoomCardTips'):GetComponent("Text").text = data.GetString("Convert_FangKa_Tips")
	this.transform:Find('Canvas/Window/Content/RoomCard/ButtonAdd'):GetComponent("Button").onClick:AddListener(ConvertRoomCardAddButtonOnClick);
	this.transform:Find('Canvas/Window/Content/RoomCard/ButtonReduce'):GetComponent("Button").onClick:AddListener(ConvertRoomCardReduceButtonOnClick);	
    convertRoomCardCountField = this.transform:Find('Canvas/Window/Content/RoomCard/ConvertCount'):GetComponent("InputField");
	convertRoomCardCountField.onValueChanged:AddListener(ConvertRoomCardCountValueChanged);	
	this.transform:Find('Canvas/Window/Content/RoomCard/ButtonConvert'):GetComponent("Button").onClick:AddListener(ConvertRoomCardButtonOnClick)

	CS.EventDispatcher.Instance:AddEventListener(tostring(ProtrocolID.S_Update_Diamond), UpdateDiamond)
end	

-- Unity MonoBehavior OnDestroy 时调用此方法
function OnDestroy()
	CS.EventDispatcher.Instance:RemoveEventListener(tostring(ProtrocolID.S_Update_Diamond), UpdateDiamond)
end

-- UI数据刷新
function RefreshWindowData(windowData)
	if windowData ~= nil then
		InitUI(windowData);
	end
end

-- 初始化UI信息
function InitUI(tabIndex)
	this.transform:Find('Canvas/Window/Content/Gold').gameObject:SetActive(tabIndex == 1);
	this.transform:Find('Canvas/Window/Content/RoomCard').gameObject:SetActive(tabIndex == 2);
	this.transform:Find('Canvas/Window/Content/Gold/Owned/DiamondCount'):GetComponent("Text").text = lua_CommaSeperate(GameData.RoleInfo.DiamondCount)
	exchangeGoldConsume = data.PublicConfig.EXCHANGE_GOLD[1]
	exchangeGold = data.PublicConfig.EXCHANGE_GOLD[2]
	toGoldConsumeCountFiled.text = lua_CommaSeperate(exchangeGoldConsume);
	this.transform:Find('Canvas/Window/Content/Gold/ConvertCount'):GetComponent("Text").text = lua_CommaSeperate(GameConfig.GetFormatColdNumber(exchangeGold))
	this.transform:Find('Canvas/Window/Content/Gold/consume/DiamondCount'):GetComponent("Text").text = lua_CommaSeperate(exchangeGoldConsume);

	exchangeRoomCardConsume = data.PublicConfig.EXCHANGE_ROOMCARD[1]
	exchangeRoomCard = data.PublicConfig.EXCHANGE_ROOMCARD[2]

	convertRoomCardCountField.text = lua_CommaSeperate(exchangeRoomCardConsume)
	this.transform:Find('Canvas/Window/Content/RoomCard/ConsumeText'):GetComponent("Text").text = lua_CommaSeperate(exchangeRoomCard)
	this.transform:Find('Canvas/Window/Content/RoomCard/Consume/Count'):GetComponent("Text").text = lua_CommaSeperate(exchangeRoomCardConsume)
	this.transform:Find('Canvas/Window/Content/RoomCard/Owned/DiamondCount'):GetComponent("Text").text = lua_CommaSeperate(GameData.RoleInfo.DiamondCount)
	

	if tabIndex == 2 then
		if not this.transform:Find('Canvas/Window/ToggleGroup/TabRoomCardToggle'):GetComponent("Toggle").isOn then
			this.transform:Find('Canvas/Window/ToggleGroup/TabRoomCardToggle'):GetComponent("Toggle").isOn = true
		end
	end
end

-- 关闭商城界面
function CloseConvertButton_OnClick()
	CS.WindowManager.Instance:CloseWindow('UIConvert', false)
end

-- 响应金币tab
function GoldTabOnClick(value)
	if value then
		InitUI(1);
	end
end

-- 响应房卡tab
function RoomCardTabOnClick(value)
	if value then
		InitUI(2);
	end
end

-- 钻石更新
function UpdateDiamond()
	-- body
	this.transform:Find('Canvas/Window/Content/Gold/Owned/DiamondCount'):GetComponent("Text").text = lua_CommaSeperate(GameData.RoleInfo.DiamondCount)
	this.transform:Find('Canvas/Window/Content/RoomCard/Owned/DiamondCount'):GetComponent("Text").text = lua_CommaSeperate(GameData.RoleInfo.DiamondCount)
end

--=============================金币兑换模块 Start======================================

-- 金币+按钮按下退出
function ConvertGoldAddButtonOnPressed( value )
	-- body
	if true == value then
		ConvertGoldPressRate = 1
	else
		ConvertGoldPressRate = 0
	end
end

-- 长按金币+按钮
function ConvertGoldAddButtonOnLongPressed()
	if exchangeGoldConsume >= GameData.RoleInfo.DiamondCount then
		return
	end
	-- 指数级别递增
	ConvertGoldPressRate = ConvertGoldPressRate + 1
	
	local addValue = 1
	for i=1,ConvertGoldPressRate do
		addValue = addValue * 2
	end

	exchangeGoldConsume = exchangeGoldConsume + addValue
	toGoldConsumeCountFiled.text = lua_CommaSeperate(exchangeGoldConsume)
end

-- 金币+按钮点击
function ConvertGoldAddButtonOnClick()
	exchangeGoldConsume = exchangeGoldConsume + data.PublicConfig.EXCHANGE_GOLD[1]
	if exchangeGoldConsume > GameData.RoleInfo.DiamondCount then
		exchangeGoldConsume = math.floor(GameData.RoleInfo.DiamondCount / data.PublicConfig.EXCHANGE_GOLD[1]) * data.PublicConfig.EXCHANGE_GOLD[1]
	end
	toGoldConsumeCountFiled.text = lua_CommaSeperate(exchangeGoldConsume)
end

-- 金币按钮-点击
function ConvertGoldReduceButtonOnClick()
	exchangeGoldConsume = exchangeGoldConsume - data.PublicConfig.EXCHANGE_GOLD[1]
	if exchangeGoldConsume < 0 then
		exchangeGoldConsume = 0
	end
	toGoldConsumeCountFiled.text = lua_CommaSeperate(exchangeGoldConsume)
end

-- 金币兑换输入变化
function ConvertGoldInputFieldValueChanged(valueStr)
	if valueStr == nil or valueStr == "" then
		toGoldConsumeCountFiled.text = "0"
		toGoldConsumeCountFiled:MoveTextEnd()
		return
	end

	local newValueStr = lua_CommaSeperate(tonumber(lua_Remove_CommaSeperate(valueStr)))
	if valueStr ~= newValueStr then
		toGoldConsumeCountFiled.text = newValueStr
		toGoldConsumeCountFiled:MoveTextEnd()
		return
	end

	exchangeGoldConsume = tonumber(lua_Remove_CommaSeperate(valueStr))
	exchangeGold = math.floor( exchangeGoldConsume / data.PublicConfig.EXCHANGE_GOLD[1]) * data.PublicConfig.EXCHANGE_GOLD[2]


	if exchangeGoldConsume < 0 then
		exchangeGoldConsume = 0;
		toGoldConsumeCountFiled.text = lua_CommaSeperate(exchangeGoldConsume);	
	elseif exchangeGoldConsume> GameData.RoleInfo.DiamondCount then
		exchangeGoldConsume = GameData.RoleInfo.DiamondCount;
		toGoldConsumeCountFiled.text = lua_CommaSeperate(exchangeGoldConsume)
	end
	
	this.transform:Find('Canvas/Window/Content/Gold/ConvertCount'):GetComponent("Text").text = lua_CommaSeperate(GameConfig.GetFormatColdNumber(exchangeGold))
	this.transform:Find('Canvas/Window/Content/Gold/consume/DiamondCount'):GetComponent("Text").text = lua_CommaSeperate(exchangeGoldConsume);
end

-- 兑换金币 全部兑
function ConvertGoldAllButtonOnClick()
	exchangeGoldConsume = math.floor(GameData.RoleInfo.DiamondCount / data.PublicConfig.EXCHANGE_GOLD[1]) * data.PublicConfig.EXCHANGE_GOLD[1]
	toGoldConsumeCountFiled.text = lua_CommaSeperate(exchangeGoldConsume)
end

-- 响应 兑换金币按钮 点击事件
function ConvertGoldButtonOnClick()
	if  exchangeGold == 0 then
		CS.BubblePrompt.Show(string.format( "最少兑换%s个金币", lua_CommaSeperate(GameConfig.GetFormatColdNumber(data.PublicConfig.EXCHANGE_GOLD[2]))), "UIConvert")
	elseif exchangeGoldConsume > GameData.RoleInfo.DiamondCount then
		CS.BubblePrompt.Show("钻石数量不足", "UIConvert")
	else
	    NetMsgHandler.SendConvertGoldMessage(exchangeGold)
	end
end
--=============================金币兑换模块 End======================================


--===============================================================================
--=============================房卡兑换模块 Start=================================


-- 房卡按钮+点击
function ConvertRoomCardAddButtonOnClick()
	exchangeRoomCard = exchangeRoomCard + data.PublicConfig.EXCHANGE_ROOMCARD[2]
	convertRoomCardCountField.text = lua_CommaSeperate(math.floor(exchangeRoomCard / data.PublicConfig.EXCHANGE_ROOMCARD[2])  * data.PublicConfig.EXCHANGE_ROOMCARD[1])
end

-- 房卡按钮—点击
function ConvertRoomCardReduceButtonOnClick()	
	exchangeRoomCard = exchangeRoomCard - data.PublicConfig.EXCHANGE_ROOMCARD[2]
	if exchangeRoomCard < 0 then
		exchangeRoomCard = 0
	end
	convertRoomCardCountField.text = lua_CommaSeperate(math.floor(exchangeRoomCard / data.PublicConfig.EXCHANGE_ROOMCARD[2])  * data.PublicConfig.EXCHANGE_ROOMCARD[1])
end

-- 房卡兑换 输入值变化
function ConvertRoomCardCountValueChanged(valueStr)
	if valueStr == nil or valueStr == "" then
		exchangeRoomCard = 0
		convertRoomCardCountField.text = "0"
		convertRoomCardCountField:MoveTextEnd()
		return
	end

	local newValueStr = lua_CommaSeperate(tonumber(lua_Remove_CommaSeperate(valueStr)))
	if valueStr ~= newValueStr then
		convertRoomCardCountField.text = newValueStr
		convertRoomCardCountField:MoveTextEnd()
		return
	end

	exchangeRoomCardConsume = tonumber(lua_Remove_CommaSeperate(valueStr))
	-- 超额限制
	if exchangeRoomCardConsume > GameData.RoleInfo.DiamondCount then
		convertRoomCardCountField.text = lua_CommaSeperate(GameData.RoleInfo.DiamondCount)
		convertRoomCardCountField:MoveTextEnd()
		return
	end
	exchangeRoomCard =  math.floor(exchangeRoomCardConsume / data.PublicConfig.EXCHANGE_ROOMCARD[1]) * data.PublicConfig.EXCHANGE_ROOMCARD[2]
	
	this.transform:Find('Canvas/Window/Content/RoomCard/Consume/Count'):GetComponent("Text").text = lua_CommaSeperate(exchangeRoomCardConsume);
	this.transform:Find('Canvas/Window/Content/RoomCard/ConsumeText'):GetComponent("Text").text = lua_CommaSeperate(exchangeRoomCard);
end

-- 响应 兑换房卡按钮 点击事件
function ConvertRoomCardButtonOnClick()
	if  exchangeRoomCard == 0 then
		CS.BubblePrompt.Show(string.format( "最少兑换%d张房卡", data.PublicConfig.EXCHANGE_ROOMCARD[2]), "UIConvert")
	elseif exchangeRoomCardConsume  > GameData.RoleInfo.DiamondCount then
		CS.BubblePrompt.Show("钻石数量不足", "UIConvert")
	else
	    NetMsgHandler.SendConvertRoomCardMessage(exchangeRoomCard);
	end
end

--=============================房卡兑换模块 Start=================================
--===============================================================================

