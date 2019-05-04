--[[
文件名称: UIJoinRoom.lua
创 建 人: 周 波
创建时间：2017.03
功能描述：
]]--

local roomID = ""
local pswValueText1 = nil
local pswValueText2 = nil
local pswValueText3 = nil
local pswValueText4 = nil
local pswValueText5 = nil
local pswValueText6 = nil

-- Unity MonoBehavior Awake 时调用此方法
function Awake()
	pswValueText1 = this.transform:Find('Canvas/Passwords/Password1/Value'):GetComponent("Text")
	pswValueText2 = this.transform:Find('Canvas/Passwords/Password2/Value'):GetComponent("Text")
	pswValueText3 = this.transform:Find('Canvas/Passwords/Password3/Value'):GetComponent("Text")
	pswValueText4 = this.transform:Find('Canvas/Passwords/Password4/Value'):GetComponent("Text")
	pswValueText5 = this.transform:Find('Canvas/Passwords/Password5/Value'):GetComponent("Text")
	pswValueText6 = this.transform:Find('Canvas/Passwords/Password6/Value'):GetComponent("Text")
	
	this.transform:Find('Canvas/Window/Title/ButtonBack'):GetComponent("Button").onClick:AddListener(ReturnButton_OnClick)
	for buttonIndex = 0, 9, 1 do
		this.transform:Find('Canvas/InputButtons/Button' .. buttonIndex):GetComponent("Button").onClick:AddListener(function () NumberButton_OnClick(buttonIndex) end )
	end
	this.transform:Find('Canvas/InputButtons/ButtonDel'):GetComponent("Button").onClick:AddListener(DelButtonOnClick)
	RefreshDiplay()
end

-- 响应 返回按钮 点击事件
function ReturnButton_OnClick()
	-- 关闭加入房间按钮
	CS.WindowManager.Instance:CloseWindow("UIJoinRoom", false)
end

-- 响应 数字按钮 点击事件
function NumberButton_OnClick(inputValue)
	local length = string.len(roomID)
	if length == 6 then
		return
	else
		roomID = roomID..inputValue
		RefreshDiplay()
		if string.len(roomID) == 6 then
			SendJoinRoomMessage()
		end
	end
end

-- 响应 回退按钮 点击事件
function DelButtonOnClick()
	local length = string.len(roomID)
	if length > 0 then
		roomID = string.sub(roomID,1, length -1)
		RefreshDiplay()
	end
end

-- 刷新数据显示
function RefreshDiplay()
	local length = string.len(roomID)
	local displayValue = roomID
	for	i = 1, 6- length, 1 do
		displayValue = displayValue.." "
	end
	pswValueText1.text = string.sub(displayValue,1,1)
	pswValueText2.text = string.sub(displayValue,2,2)
	pswValueText3.text = string.sub(displayValue,3,3)
	pswValueText4.text = string.sub(displayValue,4,4)
	pswValueText5.text = string.sub(displayValue,5,5)
	pswValueText6.text = string.sub(displayValue,6,6)
end

-- 请求进入房间
function SendJoinRoomMessage()
	NetMsgHandler.Send_CS_JH_Enter_Room1(tonumber(roomID))
end