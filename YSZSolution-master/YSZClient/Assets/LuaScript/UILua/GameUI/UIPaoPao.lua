if PaoPaoUIClass == nil then
    PaoPaoUIClass = {}
end
function PaoPaoUIClass:New()
	local tObj = {}
	Extends(tObj, PaoPaoUIInstance)
	return tObj
end

if PaoPaoUIInstance == nil then
	PaoPaoUIInstance =
	{
		mainUITransform = nil,
		ownerChat = {},
		longChat = {},
		huChat = {},
		chatBtn = nil,					-- 文字聊天
		chatBtnTweenAlpha = nil,		-- 文字聊天动画
		chatBtnPassTime = 0,
		closeChatSelectBtn = nil,
		chatContent = nil, 				--transform
		tempItem = nil,
		passTimeOwner = 0,
		passTimeLong = 0,
		passTimeHu = 0,
		coolTime = 0,
		isInitSelectItems = false,
	}
end

local YuYinChatBtn = nil				-- 语音聊天按钮
local YuYinChatTips = nil				-- 语音聊天倒计时
local YuYinChatTipsText = nil			-- 语音聊天倒计时text
local YuYinChatTipsSlider = nil			-- 语音聊天倒计时音量
local YuYinChatItem = nil				-- 语音聊天Item
local YuYinChatItemParent = nil			-- 语音聊天Item挂靠点
local CanRecordYuYin = true				-- 能否开始录音
local RecordYuYinCountDown = 5			-- 语音录音倒计时


function PaoPaoUIInstance:Init(gameObject)
	self.mainUITransform = gameObject.transform
	self.ownerChat.UI = self.mainUITransform:Find('Owner').gameObject
	self.ownerChat.Text = self.mainUITransform:Find('Owner/Text'):GetComponent('Text')
	self.ownerChat.BackRect = self.mainUITransform:Find('Owner/Image'):GetComponent('RectTransform')
	self.ownerChat.TextRect = self.mainUITransform:Find('Owner/Text'):GetComponent('RectTransform')

	self.longChat.UI = self.mainUITransform:Find('Long').gameObject
	self.longChat.Text = self.mainUITransform:Find('Long/Text'):GetComponent('Text')
	self.longChat.BackRect = self.mainUITransform:Find('Long/Image'):GetComponent('RectTransform')
	self.longChat.TextRect = self.mainUITransform:Find('Long/Text'):GetComponent('RectTransform')

	self.huChat.UI = self.mainUITransform:Find('Hu').gameObject
	self.huChat.Text = self.mainUITransform:Find('Hu/Text'):GetComponent('Text')
	self.huChat.BackRect = self.mainUITransform:Find('Hu/Image'):GetComponent('RectTransform')
	self.huChat.TextRect = self.mainUITransform:Find('Hu/Text'):GetComponent('RectTransform')

	self.chatBtn = self.mainUITransform:Find('ChatBtn'):GetComponent('Button')
	self.chatBtnTweenAlpha = self.mainUITransform:Find('ChatBtn'):GetComponent('TweenAlpha')
	self.closeChatSelectBtn = self.mainUITransform:Find('SelectUI'):GetComponent('Button')
	self.chatContent = self.mainUITransform:Find('SelectUI/ScrollRect/Viewport/Content')
	self.tempItem = self.mainUITransform:Find('SelectUI/ScrollRect/Viewport/Content/Item')
	-- 默认状态设置
	self.tempItem.gameObject:SetActive(false)
	self.chatBtn.gameObject:SetActive(false)

	self.chatBtn.onClick:AddListener(PaoPaoUIClass.OnClickChatBtn)
	self.closeChatSelectBtn.onClick:AddListener(PaoPaoUIClass.OnCloseSelectChat)
end

function PaoPaoUIInstance:Update()
	-- body
	local  deltaTime = CS.UnityEngine.Time.deltaTime
	if self.passTimeOwner > 0 then
		self.passTimeOwner = self.passTimeOwner - deltaTime
		if self.passTimeOwner < 0 then
			self.ownerChat.UI:SetActive(false)
			self.passTimeOwner = 0
		end
	end

	if self.passTimeLong > 0 then
		self.passTimeLong = self.passTimeLong - deltaTime
		if self.passTimeLong < 0 then
			self.longChat.UI:SetActive(false)
			self.passTimeLong = 0
		end
	end

	if self.passTimeHu > 0 then
		self.passTimeHu = self.passTimeHu - deltaTime
		if self.passTimeHu < 0 then
			self.huChat.UI:SetActive(false)
			self.passTimeHu = 0
		end
	end

	if self.chatBtnPassTime > 0 then
		self.chatBtnPassTime = self.chatBtnPassTime - deltaTime
		if self.chatBtnPassTime < 0 then
			self.chatBtnTweenAlpha.enabled = false
			self.chatBtnPassTime = 0
		end
	end
	 
end

function PaoPaoUIInstance:SetChatBtnActive()
	if GameData.RoomInfo.CurrentRoom.BankerInfo.ID == GameData.RoleInfo.AccountID then--自己是庄家
		--显示发言按钮
		--print('=====发言泡泡:222222222222222222222')
		self:ShowChatBtn()
	else
		--游戏状态判断
		local roomState = GameData.RoomInfo.CurrentRoom.RoomState
		--print('33333333333333333333333',roomState)
		if roomState >= ROOM_STATE.DEAL then
			--只有龙虎押注第一人才显示按钮
			if GameData.RoomInfo.CurrentRoom.CheckRole1.ID == GameData.RoleInfo.AccountID or GameData.RoomInfo.CurrentRoom.CheckRole2.ID == GameData.RoleInfo.AccountID then
				--显示发言按钮
				--print('=====发言泡泡:111111111111111111111')
				self:ShowChatBtn()
			else
				self:HideChatBtn()
			end
		else
			self:HideChatBtn()
		end
	end
	-- VIP按钮
	--YuYinChatBtn.gameObject:SetActive(GameData.RoomInfo.CurrentRoom.IsVipRoom)
end

function PaoPaoUIInstance.HandleShowChat(eventArg)
	local roleType, chatIndex = eventArg.roleType, eventArg.chatIndex
	--print('=====roleType:' .. roleType .. " chatIndex: "..chatIndex)

	local finalWidth = 0
	if roleType == 1 then --庄家发言
		PaoPaoUIInstance.ownerChat.UI:SetActive(true)
		PaoPaoUIInstance.ownerChat.Text.text = data.GetString("Chat_PaoPao_".. chatIndex)
		finalWidth = PaoPaoUIInstance.ownerChat.Text.preferredWidth
		CS.Utility.SetRectTransformWidthHight(PaoPaoUIInstance.ownerChat.BackRect, 66, math.ceil(finalWidth + 32))
		PaoPaoUIInstance.passTimeOwner = data.PublicConfig.CHAT_PAOPAO_SHOW_TIME
	elseif roleType == 2 then --龙发言
		PaoPaoUIInstance.longChat.UI:SetActive(true)
		PaoPaoUIInstance.longChat.Text.text = data.GetString("Chat_PaoPao_".. chatIndex)
		finalWidth = PaoPaoUIInstance.longChat.Text.preferredWidth
		
		CS.Utility.SetRectTransformWidthHight(PaoPaoUIInstance.longChat.BackRect, 66, math.ceil(finalWidth + 32))
		PaoPaoUIInstance.passTimeLong = data.PublicConfig.CHAT_PAOPAO_SHOW_TIME
	else --虎发言
		PaoPaoUIInstance.huChat.UI:SetActive(true)
		PaoPaoUIInstance.huChat.Text.text = data.GetString("Chat_PaoPao_".. chatIndex)
		finalWidth = PaoPaoUIInstance.huChat.Text.preferredWidth
		
		CS.Utility.SetRectTransformWidthHight(PaoPaoUIInstance.huChat.BackRect, 66, math.ceil(finalWidth + 32))
		PaoPaoUIInstance.passTimeHu = data.PublicConfig.CHAT_PAOPAO_SHOW_TIME
	end
end

--Chat_PaoPao_
function PaoPaoUIInstance:ShowSelectChat()
	self.closeChatSelectBtn.gameObject:SetActive(true)
	--如果没有初始化选择项，初始化
	if self.isInitSelectItems == false then
		for index = 1, 6, 1 do
			local item = CS.UnityEngine.Object.Instantiate(self.tempItem)
			CS.Utility.ReSetTransform(item, self.chatContent)
			item.gameObject:SetActive(true)
			item.transform:Find('Text'):GetComponent('Text').text =  string.format("%d , %s", index , data.GetString("Chat_PaoPao_".. index))

			local button = item.transform:GetComponent('Button')
			button.onClick:AddListener(function() self.OnSelectItem(index) end)
		end
		self.isInitSelectItems = true
	end
end

function PaoPaoUIInstance:HideSelectChat()
	self.closeChatSelectBtn.gameObject:SetActive(false)
end

function PaoPaoUIInstance:ShowChatBtn()
	if false == self.chatBtn.gameObject.activeSelf then
		self.chatBtnTweenAlpha.enabled = true
		self.chatBtnPassTime = 3
	end
	self.chatBtn.gameObject:SetActive(true)
	
end

function PaoPaoUIInstance:HideChatBtn()
	self.chatBtn.gameObject:SetActive(false)
	PaoPaoUIInstance:HideSelectChat()
end

function PaoPaoUIInstance.OnSelectItem(index)
	--print('选择的聊天id是'..index)
	--关闭选择聊天界面
	PaoPaoUIInstance:HideSelectChat()

	--游戏状态判断，不符合条件直接返回
	if GameData.RoomInfo.CurrentRoom.BankerInfo.ID == GameData.RoleInfo.AccountID then--自己是庄家
		--给服务器发消息
		NetMsgHandler.SendChatPaoPao(1, index)
	else
		--游戏状态判断
		local roomState = GameData.RoomInfo.CurrentRoom.RoomState
		if roomState >= ROOM_STATE.DEAL then

			--只有龙虎押注第一人才能发消息
			if GameData.RoomInfo.CurrentRoom.CheckRole1.ID == GameData.RoleInfo.AccountID then
				--给服务器发消息
				NetMsgHandler.SendChatPaoPao(2, index)
			elseif GameData.RoomInfo.CurrentRoom.CheckRole2.ID == GameData.RoleInfo.AccountID then
				--给服务器发消息
				NetMsgHandler.SendChatPaoPao(3, index)
			else
				print('发言者，既不是龙第一人，也不是虎第一人')
			end
		end
	end

	PaoPaoUIInstance.coolTime = os.time()
end

function PaoPaoUIClass.OnClickChatBtn()
	if PaoPaoUIInstance.coolTime == 0 then
		PaoPaoUIInstance.coolTime = os.time()
		--显示聊天选择界面
		if PaoPaoUIInstance.closeChatSelectBtn.gameObject.activeSelf then
			PaoPaoUIInstance:HideSelectChat()
		else
			PaoPaoUIInstance:ShowSelectChat()
		end
	else
		local nowTime = os.time()
		if nowTime - PaoPaoUIInstance.coolTime < data.PublicConfig.CHAT_PAOPAO_COOL_TIME then
			--提示，冷却时间未到
			CS.BubblePrompt.Show("发言频率太高", "GameUI2");
		else
			--显示聊天选择界面
			if PaoPaoUIInstance.closeChatSelectBtn.gameObject.activeSelf then
			PaoPaoUIInstance:HideSelectChat()
			else
				PaoPaoUIInstance:ShowSelectChat()
			end
		end
	end
end



function PaoPaoUIClass.OnCloseSelectChat()
	--关闭选择聊天界面
	paopaoUIInstance:HideSelectChat()
end

function PaoPaoUIClass.OnRoomStateChange(state)
	PaoPaoUIInstance:SetChatBtnActive()
end

----------------------------------------------------------------------
-- UI 元素解析
function UIParse()
	-- body
	YuYinChatBtn = this.transform:Find('YuYinChat'):GetComponent('Button')
	YuYinChatTips = this.transform:Find('YuYinChatTips').gameObject
	YuYinChatTipsText = this.transform:Find('YuYinChatTips/Text'):GetComponent('Text')
	YuYinChatTipsSlider = this.transform:Find('YuYinChatTips/Slider'):GetComponent('Slider')
	YuYinChatItem = this.transform:Find('YuYinChatShow/ScrollRect/Viewport/Content/Item')
	YuYinChatItemParent = this.transform:Find('YuYinChatShow/ScrollRect/Viewport/Content')

	YuYinChatBtn.gameObject:SetActive(false)
	YuYinChatBtn.onClick:AddListener(PaoPaoUIClass.OnClickYuYinChatBtn)
end

function NotifyPlayerYuYinChat( chatdata )
	-- body
end


function NotifyRecordOverEvent(result)
	-- body
	print('=====NotifyRecordOverEvent'..result)
	NetMsgHandler.CS_Player_YuYinChat(result)
end

function NotifyRecordCountDownEvent( countDown )
	-- body
	RecordYuYinCountDown = countDown
	ShowYuYinChatTipsText(RecordYuYinCountDown)

	if RecordYuYinCountDown == 0 then
		ShowYuYinChatTips(false)
	end
end

-- 语音录制按钮点击回调
function PaoPaoUIClass.OnClickYuYinChatBtn()
	-- body
	CS.BubblePrompt.Show("语音聊天暂未开放,敬请期待...", "GameUI2");
end

function ShowYuYinChatTipsText( countDown )
	-- body
	YuYinChatTipsText.text = string.format("你正在说话[%d]",countDown)
end

function ShowYuYinChatTips( isShow )
	-- body
	YuYinChatTips:SetActive(isShow)
end

-----------------------------------------------------------------------
----------------------------MonoBehaviour call function----------------
function Awake()
	-- body
	UIParse()
	PaoPaoUIInstance:Init(this.gameObject)
	
	CS.EventDispatcher.Instance:AddEventListener(EventDefine.UpdateRoomState, PaoPaoUIClass.OnRoomStateChange)
	CS.EventDispatcher.Instance:AddEventListener(EventDefine.NotifyChatPaoPao, PaoPaoUIInstance.HandleShowChat)
	CS.EventDispatcher.Instance:AddEventListener(EventDefine.NotifyPlayerYuYinChat, NotifyPlayerYuYinChat)
end

function Start()
	PaoPaoUIInstance.ownerChat.UI:SetActive(false)
	PaoPaoUIInstance.longChat.UI:SetActive(false)
	PaoPaoUIInstance.huChat.UI:SetActive(false)
	PaoPaoUIInstance:HideSelectChat()
	PaoPaoUIInstance:SetChatBtnActive()
end

function Update()
	PaoPaoUIInstance:Update()
end

function OnDestroy()
	CS.EventDispatcher.Instance:RemoveEventListener(EventDefine.UpdateRoomState, PaoPaoUIClass.OnRoomStateChange)
	CS.EventDispatcher.Instance:RemoveEventListener(EventDefine.NotifyChatPaoPao, PaoPaoUIInstance.HandleShowChat)
	CS.EventDispatcher.Instance:RemoveEventListener(EventDefine.NotifyPlayerYuYinChat, NotifyPlayerYuYinChat)
end

