local changeNameConsume = 0
local HeadIconItem = nil			-- 头像Item
local HeadIconsParent = nil			-- 头像父节点
local RoleCurrentIcon = 1			-- 角色当前头像ID

function Awake()
	HeadIconsParent = this.transform:Find('Canvas/Window/HeadIcons/Viewport/Content')
	HeadIconItem = this.transform:Find('Canvas/Window/HeadIcons/Viewport/Content/HeadIcon')
	HeadIconItem.gameObject:SetActive(false)
	this.transform:Find('Canvas/Mask'):GetComponent("Button").onClick:AddListener(CloseButton_OnClick)
	this.transform:Find('Canvas/Window/Title/CloseButton'):GetComponent("Button").onClick:AddListener(CloseButton_OnClick)
	this.transform:Find('Canvas/Window/ConfirmButton'):GetComponent("Button").onClick:AddListener(ConfirmButton_OnClick)
	CS.EventDispatcher.Instance:AddEventListener(EventDefine.NotifyHeadIconChange, NotifyHeadIconChange)
end

function Start()
	RoleCurrentIcon = GameData.RoleInfo.AccountIcon
	if RoleCurrentIcon == 0 then
		-- body
		RoleCurrentIcon = 1
	end

	local iconCount = data.PublicConfig.ROLE_ICON_MAX
	for i=1, iconCount, 1 do
		local item = CS.UnityEngine.Object.Instantiate(HeadIconItem)
			CS.Utility.ReSetTransform(item, HeadIconsParent)
			item.gameObject:SetActive(true)
			local itemToggle =	item.transform:Find('Toggle'):GetComponent('Toggle')
			itemToggle.isOn = false
			itemToggle.onValueChanged:AddListener( function (isOn) HeadIcon_OnValueChanged(isOn, i) end)
			local icon = item.transform:Find('Toggle/Background'):GetComponent('Image')
			icon:ResetSpriteByName(GameData.GetRoleIconSpriteName(i))
			if RoleCurrentIcon == i then
				itemToggle.isOn = true
			end
	end
end

function OnDestroy()
	CS.EventDispatcher.Instance:RemoveEventListener(EventDefine.NotifyHeadIconChange, NotifyHeadIconChange)
end

-- 关闭按钮响应
function CloseButton_OnClick()
	CS.WindowManager.Instance:CloseWindow("PlayerIconChangeUI", false)
end

-- 确认按钮响应
function ConfirmButton_OnClick()
	print('=====confirm button click')
	if RoleCurrentIcon ~= GameData.RoleInfo.AccountIcon then
		NetMsgHandler.CS_Player_Icon_Change(RoleCurrentIcon)
	end
end

-- 头像选择变化通知
function HeadIcon_OnValueChanged( isOn, iconid )
	-- body
	if isOn then
		if RoleCurrentIcon ~= iconid then
			RoleCurrentIcon = iconid
		end
	end
end

-- 头像切换成功
function NotifyHeadIconChange()
	-- body
	CS.WindowManager.Instance:CloseWindow("PlayerIconChangeUI", false)
end
