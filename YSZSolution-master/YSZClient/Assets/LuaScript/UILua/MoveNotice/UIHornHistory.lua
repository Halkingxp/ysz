local historyItemParent = nil
local historyItem = nil

function Awake()
	this.transform:Find('Canvas/Window/CloseBtn'):GetComponent("Button").onClick:AddListener(CloseButtonOnClick)
	historyItemParent = this.transform:Find('Canvas/Window/Content/Viewport/Content')
	historyItem = this.transform:Find('Canvas/Window/Content/Viewport/Content/Item')
end

function RefreshWindowData(windowData)
	--获取跑马灯列表
	RefreshHornHistoryItems()
end

function CloseButtonOnClick()
	CS.WindowManager.Instance:CloseWindow("UIHornHistory", false)
end

-- 刷新历史消息记录
function RefreshHornHistoryItems()
	lua_Transform_ClearChildren(historyItemParent, true)
	historyItem.gameObject:SetActive(false)
	local historyList = CS.MoveNotice.NiticedHistory
	local noticeCount = historyList.Count
	for	 index = 0, noticeCount - 1, 1 do
		local noticeContent = historyList[index]
		local instanceItem = CS.UnityEngine.GameObject.Instantiate(historyItem)
		instanceItem.gameObject:SetActive(true)
		CS.Utility.ReSetTransform(instanceItem, historyItemParent)
		local textItem = instanceItem.transform:Find('Text'):GetComponent("Text")
		textItem.text = noticeContent
		local rectTransform = instanceItem:GetComponent('RectTransform')
		CS.Utility.SetRectTransformHeight(rectTransform,math.ceil(textItem.preferredHeight + 40))
	end
end