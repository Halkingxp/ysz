local playerItemParent = nil
local playerItem = nil

function Awake()
	this.transform:Find('Canvas/Window/CloseBtn'):GetComponent("Button").onClick:AddListener(CloseButtonOnClick)
	playerItemParent = this.transform:Find('Canvas/Window/Content/Viewport/Content')
	playerItem = this.transform:Find('Canvas/Window/Content/Viewport/Content/Item')
end

function Start()
	-- body
	NetMsgHandler.Send_CS_Request_Role_List()
end

function RefreshWindowData(windowData)
	--获取玩家列表
	if nil ~= windowData then
		RefreshPlayerListItems(windowData)
	end
end

-- 关闭按钮响应
function CloseButtonOnClick()
	CS.WindowManager.Instance:CloseWindow("UIRoomPlayers", false)
end

-- 刷新玩家列表信息
function RefreshPlayerListItems(plarDatas)
	lua_Transform_ClearChildren(playerItemParent, true)
	playerItem.gameObject:SetActive(false)
	for key,playerInfo in ipairs(plarDatas) do
		local instanceItem = CS.UnityEngine.GameObject.Instantiate(playerItem)
		if nil ~= instanceItem then
			instanceItem.gameObject:SetActive(true)
			CS.Utility.ReSetTransform(instanceItem, playerItemParent)
			instanceItem:Find('NameText'):GetComponent("Text").text = tostring(playerInfo.AccountName)
			instanceItem:Find('GoldText'):GetComponent("Text").text = lua_CommaSeperate(GameConfig.GetFormatColdNumber(playerInfo.GoldCount))
			instanceItem:Find('IconImage'):GetComponent("Image"):ResetSpriteByName(GameData.GetRoleIconSpriteName(playerInfo.HeadIcon))
		end
	end
end