local changeNameConsume = 0

function Awake()
	this.transform:Find('Canvas/Mask'):GetComponent("Button").onClick:AddListener(CloseButton_OnClick)
	this.transform:Find('Canvas/Window/Title/CloseButton'):GetComponent("Button").onClick:AddListener(CloseButton_OnClick)
	
	this.transform:Find('Canvas/Window/Content/Panel/AccountName/Modify'):GetComponent("Button").onClick:AddListener(EditAccountNameButton_OnClick)
	this.transform:Find('Canvas/Window/Content/Panel/AccountName/Value'):GetComponent("InputField").onEndEdit:AddListener(AccountName_OnEndEdit)
	this.transform:Find('Canvas/Window/Content/Panel/VipLevel/UpVipLevel'):GetComponent("Button").onClick:AddListener(VipLevelUpButton_OnClick)
	this.transform:Find('Canvas/Window/Content/Panel/ItemIcon/Icon'):GetComponent("Button").onClick:AddListener(HeadIcon_OnClick)

	CS.EventDispatcher.Instance:AddEventListener(EventDefine.NotifyHeadIconChange, NotifyHeadIconChange)
end

function RefreshWindowData(windowData)
	this.transform:Find('Canvas/Window/Content/Panel/Account/Value'):GetComponent("Text").text = tostring(GameData.RoleInfo.AccountID)
	this.transform:Find('Canvas/Window/Content/Panel/AccountName/Value'):GetComponent("InputField").text = GameData.RoleInfo.AccountName
	this.transform:Find('Canvas/Window/Content/Panel/VipLevel/Value'):GetComponent("Text").text = tostring(GameData.RoleInfo.VipLevel)
	this.transform:Find('Canvas/Window/Content/Panel/ItemIcon/Icon'):GetComponent("Image"):ResetSpriteByName(GameData.GetRoleIconSpriteName(GameData.RoleInfo.AccountIcon))
	if changeNameConsume > GameData.RoleInfo.GoldCount then
		this.transform:Find('Canvas/Window/Content/Panel/AccountName/Modify'):GetComponent("Button").interactable = false
	else
		this.transform:Find('Canvas/Window/Content/Panel/AccountName/Modify'):GetComponent("Button").interactable = true
	end
	
	RefreshCheckNameTime()
end

function OnDestroy()
	-- body
	CS.EventDispatcher.Instance:RemoveEventListener(EventDefine.NotifyHeadIconChange, NotifyHeadIconChange)
end

-- 头像按钮响应
function HeadIcon_OnClick()
	-- 打开头像编辑UI
	openparam = CS.WindowNodeInitParam("PlayerIconChangeUI")
	CS.WindowManager.Instance:OpenWindow(openparam)
end
-- 头像变化更新
function NotifyHeadIconChange( icon )
	-- body
	print("=====icon:"..GameData.RoleInfo.AccountIcon)
	this.transform:Find('Canvas/Window/Content/Panel/ItemIcon/Icon'):GetComponent("Image"):ResetSpriteByName(GameData.GetRoleIconSpriteName(GameData.RoleInfo.AccountIcon))
end

-- 响应关闭按钮
function CloseButton_OnClick()
	CS.WindowManager.Instance:CloseWindow("PlayerInfoUI", false)
end

-- 响应昵称修改按钮
function EditAccountNameButton_OnClick()
	this.transform:Find('Canvas/Window/Content/Panel/AccountName/Modify'):GetComponent("Button").interactable = false
	this.transform:Find('Canvas/Window/Content/Panel/AccountName/Mask').gameObject:SetActive(false)
	this.transform:Find('Canvas/Window/Content/Panel/AccountName/Value'):GetComponent("InputField"):Select()
	this.transform:Find('Canvas/Window/Content/Panel/AccountName/Value'):GetComponent("InputField"):MoveTextEnd()
end

-- 昵称输入结束
function AccountName_OnEndEdit(accountName)
	this.transform:Find('Canvas/Window/Content/Panel/AccountName/Modify'):GetComponent("Button").interactable = true
	this.transform:Find('Canvas/Window/Content/Panel/AccountName/Mask').gameObject:SetActive(true)
	CheckInputedAccountName()
end

-- 修改昵称提示tips
function RefreshCheckNameTime()
	local tipsContent = "修改昵称"
	changeNameConsume = data.PublicConfig.CHANGE_NAME_COST[GameData.RoleInfo.ModifyNameCount + 1]
	if changeNameConsume > 0 then
		tipsContent = tipsContent.."将消耗"..lua_NumberToStyle1String(GameConfig.GetFormatColdNumber(changeNameConsume)).."金币"
	else
		tipsContent = tipsContent.. "免费"
	end
	this.transform:Find('Canvas/Window/Content/Panel/AccountName/Tips'):GetComponent("Text").text =  tipsContent
end

-- 校验账号名称
function CheckInputedAccountName()
	--屏蔽字检查，如果有屏蔽字，弹出提示框提醒玩家
	local accountNameInputField = this.transform:Find('Canvas/Window/Content/Panel/AccountName/Value'):GetComponent("InputField")
	local indexs
	local charNum
	local strReplace = ''
	local newAccountName = accountNameInputField.text
	if newAccountName == GameData.RoleInfo.AccountName then
		return
	end
	
	if newAccountName == '' then
		CS.BubblePrompt.Show(data.GetString("Change_Name_Error_5"), "PlayerInfoUI")
		accountNameInputField.text = GameData.RoleInfo.AccountName
		return
	end
	
	local csharpcharNum = CS.Utility.UTF8Stringlength(newAccountName)
	local luacharNum = string.len(newAccountName)
	local zwNum = (luacharNum - csharpcharNum) / 2
	local finalNum = zwNum + csharpcharNum
	print('csharp length = ', csharpcharNum, ' luacharNum = ', luacharNum, ' zwNum = ', zwNum)
	if finalNum > 12 then
		CS.BubblePrompt.Show(data.GetString("Change_Name_Error_6"), "PlayerInfoUI")
		accountNameInputField.text = GameData.RoleInfo.AccountName
		return
	end
	
	for k, v in pairs(data.MaskConfig) do
		indexs = string.find(newAccountName, v.Value)
		if indexs ~= nil then
			CS.BubblePrompt.Show(data.GetString("Change_Name_Error_4"), "PlayerInfoUI")
			accountNameInputField.text = GameData.RoleInfo.AccountName
			return
		end
	end
	
	NetMsgHandler.SendModifyName(newAccountName)
end

-- VIP提示按钮响应
function VipLevelUpButton_OnClick()
	-- 打开商城界面，关闭当前界面
	openparam = CS.WindowNodeInitParam("UIStore")
	CS.WindowManager.Instance:OpenWindow(openparam)
end



