local detailPartMailInfo = nil

local sendToInfo = nil

local sendMailCastRate = 5

local isUpdateWaitHttpResult = false

local wwwRequest = nil

function Awake()
	AddButtonHandlers()
	local tabControl = this.transform:Find('Canvas/Window/Content'):GetComponent("TabControl")
	tabControl:OnTabChanged('+', HandleTabChanged)
end

function AddButtonHandlers()
	this.transform:Find('Canvas/Mask'):GetComponent("Button").onClick:AddListener(CloseButtonOnClick)
	this.transform:Find('Canvas/Window/Title/CloseButton'):GetComponent("Button").onClick:AddListener(CloseButtonOnClick)
	-- 邮件详情部分的事件
	local emailDetail = this.transform:Find('Canvas/Window/Content/EmailDetail')
	emailDetail:Find('ButtonReturn'):GetComponent("Button").onClick:AddListener(DetailPartReturnButtonOnClick)
	emailDetail:Find('BottomButtons/ButtonDelete'):GetComponent("Button").onClick:AddListener(DetailPartRemoveButtonOnClick)
	emailDetail:Find('BottomButtons/ButtonReceive'):GetComponent("Button").onClick:AddListener(DetailPartReceiveButtonOnClick)
	emailDetail:Find('BottomButtons/ButtonApply'):GetComponent("Button").onClick:AddListener(DetailPartApplyButtonOnClick)
	emailDetail:Find('BottomButtons/ButtonClose'):GetComponent("Button").onClick:AddListener(DetailPartCloseButtonOnClick)
	-- 发邮件部分的事件
	local sendMail = this.transform:Find('Canvas/Window/Content/Panel/SendMail')
	sendMail:Find('Content/SendTo'):GetComponent("InputField").onEndEdit:AddListener(SendPartAccountOnEndEdit)
	sendMail:Find('Content/SendTo/hongbao'):GetComponent("Button").onClick:AddListener(SendPartHongbaoOnClick)
	sendMail:Find('ButtonSend'):GetComponent("Button").onClick:AddListener(SendPartSendButtonOnClick)
	sendMail:Find('Content/MailContent'):GetComponent("InputField").onValueChanged:AddListener(SendPartMailContentOnValueChanged)
	
	-- 红包界面按钮
	this.transform:Find('Canvas/Hongbao/Window/Buttons/CancelButton'):GetComponent("Button").onClick:AddListener(HongBaoPartCancelButtonOnClick)
	this.transform:Find('Canvas/Hongbao/Window/Buttons/ClearButton'):GetComponent("Button").onClick:AddListener(HongBaoPartClearButton_OnClick)
	this.transform:Find('Canvas/Hongbao/Window/Buttons/OKButton'):GetComponent("Button").onClick:AddListener(HongBaoPartOkButton_OnClick)
	this.transform:Find('Canvas/Hongbao/Window/GoldCount'):GetComponent("InputField").onValueChanged:AddListener(HongBaoPartGold_OnValueChanged)
	this.transform:Find('Canvas/Hongbao/Window/GoldCount'):GetComponent("InputField").onEndEdit:AddListener(HongBaoPartGold_OnEditEnd)
	
	-- 申请界面部分
	this.transform:Find('Canvas/ApplyPart/Window/ButtonApply'):GetComponent("Button").onClick:AddListener(ApplyPartSureButton_OnClick)
	this.transform:Find('Canvas/ApplyPart/Window/ButtonClose'):GetComponent("Button").onClick:AddListener(ApplyPartReturnButton_OnClick)
end

function WindowOpened()
	CS.EventDispatcher.Instance:AddEventListener(EventDefine.NotifyEmailRoleInfo, HandleNotifyEmailRoleInfo)
	CS.EventDispatcher.Instance:AddEventListener(EventDefine.UpdateEmailInfo, HandleUpdateEmailInfo)
	CS.EventDispatcher.Instance:AddEventListener(EventDefine.NotifySendMailResult, HandleSendEmailResult)
	CS.EventDispatcher.Instance:AddEventListener(EventDefine.UpdateUnHandleFlag, HandleUpdateUnHandleFlagEvent)
	
	HandleUpdateUnHandleFlagEvent(GameData.CreateUnHandleEventArgsOfEmail(GameData.RoleInfo.UnreadMailCount))
end

function WindowClosed()
	CS.EventDispatcher.Instance:RemoveEventListener(EventDefine.NotifyEmailRoleInfo, HandleNotifyEmailRoleInfo)
	CS.EventDispatcher.Instance:RemoveEventListener(EventDefine.UpdateEmailInfo, HandleUpdateEmailInfo)
	CS.EventDispatcher.Instance:RemoveEventListener(EventDefine.NotifySendMailResult, HandleSendEmailResult)
	CS.EventDispatcher.Instance:RemoveEventListener(EventDefine.UpdateUnHandleFlag, HandleUpdateUnHandleFlagEvent)
	if isUpdateWaitHttpResult then
		CS.LoadingDataUI.Hide()
	end
end

-- Unity MonoBehavior OnDestroy 时调用此方法
function OnDestroy()
	
end

function Update()
	if isUpdateWaitHttpResult then
		UpdateWaitHttpResult()
	end
end

-- 刷新界面数据
function RefreshWindowData(windowData)
	if windowData ~= nil then
		RefreshEmailListPart()
	end
end

-- 关闭按钮响应
function CloseButtonOnClick()
	CS.WindowManager.Instance:CloseWindow('UIEmail', false)
end

-- 刷新邮件列表
function RefreshEmailListPart()
	local mailListParent = this.transform:Find('Canvas/Window/Content/Panel/EmailList/Viewport/Content')
	local mailItem = this.transform:Find('Canvas/Window/Content/Panel/EmailList/Viewport/Content/EmailListItem')
	lua_Transform_ClearChildren(mailListParent, true)
	mailItem.gameObject:SetActive(false)
	-- 刷新邮件数据
	local emailList = EmailMgr:GetMailList()
	
	local sortedMailIDList = EmailMgr:GetMailIDListOfSortBySendData()
	for k,v in pairs(emailList) do
		print("ssssss  "..k)
	end
	print("sortedMailIDList = "..#sortedMailIDList)
	if emailList ~= nil and sortedMailIDList~= nil then
		for	index = 1, #sortedMailIDList, 1 do
			local mailID = sortedMailIDList[index]
			local emailItem = emailList[mailID]
			if emailItem == nil then
				print("根据emailID, 获取不到 对应的邮件内容")
			else
				local newItem = CS.UnityEngine.Object.Instantiate(mailItem)
				CS.Utility.ReSetTransform(newItem, mailListParent)
				newItem.gameObject:SetActive(true)
				ResetMailListItemContent(newItem, emailItem)
			end
		end
	end
	RefreshNoneMailTips()
end

-- 刷新无邮件tips
function RefreshNoneMailTips()
	local noneMailTips = this.transform:Find('Canvas/Window/Content/Panel/EmailList/Viewport/NoneTips')
	local sortedMailIDList = EmailMgr:GetMailIDListOfSortBySendData()
	if sortedMailIDList ~= nil then
		noneMailTips.gameObject:SetActive(#sortedMailIDList == 0)
	else
		noneMailTips.gameObject:SetActive(true)
	end
end

-- 重置邮件Item数据
function ResetMailListItemContent(mailItem, mailInfo)
	mailItem.gameObject.name = tostring(mailInfo.MailID)
	mailItem:GetComponent("Button").onClick:AddListener(function () MailItemOnClick(mailItem, mailInfo) end)
	mailItem:Find('AccountName'):GetComponent("Text").text = mailInfo.sSenderName
	if mailInfo.nSenderID == 0 then
		mailItem:Find('AccountID').gameObject:SetActive(false)
	else
		mailItem:Find('AccountID').gameObject:SetActive(true)
		mailItem:Find('AccountID'):GetComponent("Text").text = tostring(mailInfo.nSenderID)
	end
	mailItem:Find('Date'):GetComponent("Text").text = CS.Utility.UnixTimestampToDateTime(mailInfo.nSendDate):ToString('yyyy-MM-dd HH:mm')
	if mailInfo.nSendType == MAIL_TYPE.INVITE or mailInfo.nSendType == MAIL_TYPE.PROMOTER then
		mailItem:Find('DeleteButton').gameObject:SetActive(false)
	else
		mailItem:Find('DeleteButton').gameObject:SetActive(true)
		mailItem:Find('DeleteButton'):GetComponent("Button").onClick:AddListener( function () DeleteOneEmail(mailInfo) end)
	end
	
	RefreshMailListItemReadFlag(mailItem, mailInfo)
end

-- 邮件Item被点击响应
function MailItemOnClick(mailItem, mailInfo)
	detailPartMailInfo = mailInfo
	EmailListToDetailPart(true)
	RefreshMailListItemReadFlag(mailItem, mailInfo)
end

-- 刷新邮件Item 已读tag
function RefreshMailListItemReadFlag(mailItem, mailInfo)
	if mailInfo.bIsRead  == 0 then
		mailItem:Find('FlagBack/Flag1').gameObject:SetActive(true)
		mailItem:Find('FlagBack/Flag2').gameObject:SetActive(false)
	else
		mailItem:Find('FlagBack/Flag1').gameObject:SetActive(false)
		mailItem:Find('FlagBack/Flag2').gameObject:SetActive(true)
	end
end

-- 读取一封邮件
function ReadOneEmail(mailInfo)
	EmailMgr:ReadMail(mailInfo.MailID)
end

-- 删除一封邮件
function DeleteOneEmail(mailInfo)
	NetMsgHandler.SendDeleteEmail(mailInfo.MailID)
end

-- 
function HandleTabChanged(preKey, curKey)
	if curKey == 2 then
		--ResetSendMailPart()
	end
end

-- 更新未处理邮件信息
function HandleUpdateUnHandleFlagEvent(eventArg)
	if eventArg ~= nil then
		if eventArg.UnHandleType == UNHANDLE_TYPE.EMAIL then
			this.transform:Find('Canvas/Window/Content/TabToggles/ListToggle/Flag').gameObject:SetActive(eventArg.ContainsUnHandle)
		end
	end
end

-- 邮件Item 信息更新
function HandleUpdateEmailInfo(eventArg)
	if eventArg ~= nil then
		local reason = eventArg.Reason
		local mailID = eventArg.MailID
		if eventArg.Reason == 2 then -- 删除邮件
			-- 清理掉对应的邮件
			lua_Transform_RemoveChildByName(this.transform:Find('Canvas/Window/Content/Panel/EmailList/Viewport/Content'),tostring(mailID))
			if detailPartMailInfo ~= nil then
				if detailPartMailInfo.MailID == mailID then
					EmailListToDetailPart(false)-- 返回邮件列表
				end
			end
			
			RefreshNoneMailTips()
		elseif eventArg.Reason == 3 then -- 邮件附件改变
			if detailPartMailInfo.MailID == mailID then
				RefreshDetailPartContent()
			end
		end
	end
end

--=============================邮件详情 模块==============================
-- 邮件详情 返回按钮响应
function DetailPartReturnButtonOnClick()
	EmailListToDetailPart(false)
end

-- 邮件详情--详情信息 转换
function EmailListToDetailPart(isForward)
	if isForward then
		this.transform:Find('Canvas/Window/Content/TabToggles').gameObject:SetActive(false)
		this.transform:Find('Canvas/Window/Content/Panel').gameObject:SetActive(false)
		this.transform:Find('Canvas/Window/Content/EmailDetail').gameObject:SetActive(true)
		ReadOneEmail(detailPartMailInfo)
		RefreshDetailPartContent()
	else
		this.transform:Find('Canvas/Window/Content/TabToggles').gameObject:SetActive(true)
		this.transform:Find('Canvas/Window/Content/Panel').gameObject:SetActive(true)
		this.transform:Find('Canvas/Window/Content/EmailDetail').gameObject:SetActive(false)
		detailPartMailInfo = nil
	end
end

-- 邮件详情 刷新具体显示
function RefreshDetailPartContent()
	if detailPartMailInfo == nil then
		EmailListToDetailPart(false)
	else
		local detailPart = this.transform:Find('Canvas/Window/Content/EmailDetail')
		
		local contentText = detailPart:Find('MailContent/Viewport/Content/Text'):GetComponent("Text")
		contentText.text = EmailMgr:GetMailDisplayContent(detailPartMailInfo)
		
		local contentParentTrans = detailPart:Find('MailContent/Viewport/Content'):GetComponent("RectTransform")
		contentParentTrans.sizeDelta = CS.UnityEngine.Vector2(contentParentTrans.sizeDelta.x, contentText.preferredHeight)
		
		detailPart:Find('BottomContent/Sender/Name'):GetComponent("Text").text = detailPartMailInfo.sSenderName
		detailPart:Find('BottomContent/DateText'):GetComponent("Text").text =CS.Utility.UnixTimestampToDateTime( detailPartMailInfo.nSendDate):ToString('yyyy-MM-dd HH:mm')
		detailPart:Find('BottomContent/Gift/GoldItem').gameObject:SetActive(detailPartMailInfo.nGold > 0)
		detailPart:Find('BottomContent/Gift/GoldItem/Count/Value'):GetComponent("Text").text = lua_CommaSeperate(GameConfig.GetFormatColdNumber(detailPartMailInfo.nGold))
		detailPart:Find('BottomContent/Gift/RoomItem').gameObject:SetActive(detailPartMailInfo.nRoomCard > 0)
		detailPart:Find('BottomContent/Gift/RoomItem/Count/Value'):GetComponent("Text").text = lua_CommaSeperate(detailPartMailInfo.nRoomCard)
		
		detailPart:Find('BottomButtons/ButtonReceive').gameObject:SetActive(false)
		detailPart:Find('BottomButtons/ButtonDelete').gameObject:SetActive(false)
		detailPart:Find('BottomButtons/ButtonApply').gameObject:SetActive(false)
		detailPart:Find('BottomButtons/ButtonClose').gameObject:SetActive(false)
		if detailPartMailInfo.nSendType == MAIL_TYPE.INVITE then
			if GameData.RoleInfo.PromoterStep == 0 then
				detailPart:Find('BottomButtons/ButtonApply').gameObject:SetActive(true)
			end
		elseif detailPartMailInfo.nSendType == MAIL_TYPE.PROMOTER or detailPartMailInfo.nSendType == MAIL_TYPE.PASSWORD then
			detailPart:Find('BottomButtons/ButtonClose').gameObject:SetActive(true)
		else
			if detailPartMailInfo.nGold > 0 or detailPartMailInfo.nRoomCard > 0 then
				detailPart:Find('BottomButtons/ButtonReceive').gameObject:SetActive(true)
			else
				detailPart:Find('BottomButtons/ButtonReceive').gameObject:SetActive(false)
			end
			detailPart:Find('BottomButtons/ButtonDelete').gameObject:SetActive(true)
		end
	end
end

-- 邮件详情 领取按钮响应
function DetailPartReceiveButtonOnClick()
	if detailPartMailInfo ~= nil then
		if detailPartMailInfo.nGold > 0 or detailPartMailInfo.nRoomCard > 0 then
			NetMsgHandler.SendGetEmailReward(detailPartMailInfo.MailID)
		end
	end
end

-- 邮件详情 删除按钮响应
function DetailPartRemoveButtonOnClick()
	if detailPartMailInfo ~= nil then
		NetMsgHandler.SendDeleteEmail(detailPartMailInfo.MailID)
	end
end

-- 邮件详情 代理申请 提交 响应
function DetailPartApplyButtonOnClick()
	if detailPartMailInfo ~= nil then
		if GameData.RoleInfo.PromoterStep == 0 then
			RefreshApplayPart()
			this.transform:Find("Canvas/ApplyPart").gameObject:SetActive(true)
		else
			CS.BubblePrompt.Show("您已成功提交申请，无需重复申请！","UIEmail")
		end
	end
end

-- 邮件详情 代理申请  返回 响应
function DetailPartCloseButtonOnClick()
	if detailPartMailInfo ~= nil then
		EmailListToDetailPart(false)
	end
end


--=============================写邮件 模块==============================
-- 写邮件 收件人ID编辑结束 响应
function SendPartAccountOnEndEdit(value)
	local toSendID = tonumber(value)
	if sendToInfo == nil then
		sendToInfo = {}
		sendToInfo.ToAccountID = toSendID
		sendToInfo.Content = ''
		sendToInfo.GiftGold = 0
		sendToInfo.IsIDValidate = false
	elseif sendToInfo.ToAccountID == toSendID then
		return
	else
		sendToInfo.ToAccountID = toSendID
		sendToInfo.IsIDValidate = false
	end
	
	if #value == 0 then
		local eventArg = { ResultType = 9, VipLevel = 0, CanSendGold = 0}
		HandleNotifyEmailRoleInfo(eventArg)
		return
	end
	
	if toSendID == GameData.RoleInfo.AccountID then
		CS.BubblePrompt.Show(EmailMgr:GetSendMailError(SEND_MAIL_ERROR.SEND_TO_SELF), "UIEmail")
		return
	end
	
	NetMsgHandler.SendCheckAccountID(sendToInfo.ToAccountID)
end

-- 写邮件 刷新 收件人红包发送 发送按钮状态
function HandleNotifyEmailRoleInfo(eventArg)
	local hongbaoButton = this.transform:Find('Canvas/Window/Content/Panel/SendMail/Content/SendTo/hongbao')
	if eventArg ~= nil then
		sendToInfo.IsIDValidate = eventArg.ResultType == 0
		if eventArg.VipLevel > -1 and GameData.RoleInfo.VipLevel > -1 and eventArg.CanSendGold == 1 then
			RefreshSendGoldCastRate(GameData.RoleInfo.VipLevel, eventArg.VipLevel)
			hongbaoButton.gameObject:SetActive(true)
		else
			hongbaoButton.gameObject:SetActive(false)
		end
	else
		hongbaoButton.gameObject:SetActive(true)
	end
	-- 刷新发送按钮是否可用
	RefreshSendPartOfSendButton()
end

-- 写邮件 红包按钮响应
function SendPartHongbaoOnClick()
	this.transform:Find('Canvas/Hongbao').gameObject:SetActive(true)
	RefreshHongBaoWindow()
end

-- 写邮件 发红包 刷新发送金币消耗比例
function RefreshSendGoldCastRate(myVipLevel, toVipLevel)
	local vipLevel = myVipLevel
	if myVipLevel < toVipLevel then
		vipLevel = toVipLevel
	end
	local vipConfig = data.VipConfig[vipLevel]
	sendMailCastRate = vipConfig.HandselExtract
end



-- 写邮件 内容输入刷新
function SendPartMailContentOnValueChanged(mailContent)
	local contentLength = CS.Utility.UTF8Stringlength(mailContent)
	if contentLength > EMAIL_CONFIG.SEND_CONTENT_MAX then
		this.transform:Find('Canvas/Window/Content/Panel/SendMail/Content/MailContent'):GetComponent("InputField").text = CS.Utility.GetSubString(mailContent,0, EMAIL_CONFIG.SEND_CONTENT_MAX)
		return
	end
	sendToInfo.Content = mailContent
	RefreshSendPartOfSendButton()
end

-- 写邮件 刷新发送按钮是否可用
function RefreshSendPartOfSendButton()
	local sendMailButton = this.transform:Find('Canvas/Window/Content/Panel/SendMail/ButtonSend'):GetComponent("Button")
	if sendToInfo == nil then
		sendMailButton.interactable = false
	else
		if sendToInfo.IsIDValidate then
			if sendToInfo.GiftGold > 0 or (sendToInfo.Content ~= nil and CS.Utility.UTF8Stringlength(sendToInfo.Content) >= EMAIL_CONFIG.SEND_CONTENT_MIN)then
				sendMailButton.interactable = true
			else
				sendMailButton.interactable = false
			end
		else
			sendMailButton.interactable = false
		end
	end
end

-- 写邮件 发送按钮响应
function SendPartSendButtonOnClick()
	if sendToInfo == nil then
		return
	end
	
	--金币数范围判断
	if sendToInfo.GiftGold ~= nil and sendToInfo.GiftGold ~= 0 then
		if sendToInfo.GiftGold < data.PublicConfig.EMAIL_GIFT_GOLD[1] or sendToInfo.GiftGold > data.PublicConfig.EMAIL_GIFT_GOLD[2] then
			CS.BubblePrompt.Show(EmailMgr:GetSendMailError(SEND_MAIL_ERROR.GOLD_NUM_ERROR), "UIEmail")
			return
		end
	end
	--自身金币数量是否足够
	if GameData.RoleInfo.GoldCount < sendToInfo.GiftGold * (100 + sendMailCastRate) / 100 then
		CS.BubblePrompt.Show(EmailMgr:GetSendMailError(SEND_MAIL_ERROR.GOLD_NOT_ENOUGH), "UIEmail")
		return
	end
	
	--给服务器发消息
	NetMsgHandler.SendEmail('', sendToInfo.Content, sendToInfo.ToAccountID, sendToInfo.GiftGold)
end

-- 写邮件 发送邮件结果
function HandleSendEmailResult(eventArg)
	if eventArg == 0 then
		ResetSendMailPart()
	end
end

-- 写邮件 重置邮件发送数据
function ResetSendMailPart()
	-- 重置数据
	sendToInfo = {}
	sendToInfo.ToAccountID = ''
	sendToInfo.Content = ''
	sendToInfo.GiftGold = 0
	sendToInfo.IsIDValidate = false
	local sendMail = this.transform:Find('Canvas/Window/Content/Panel/SendMail')
	sendMail:Find('ButtonSend'):GetComponent("Button").interactable = false
	sendMail:Find('Content/SendTo'):GetComponent('InputField').text = sendToInfo.ToAccountID
	sendMail:Find('Content/SendTo/hongbao').gameObject:SetActive(false)
	sendMail:Find('Content/MailContent'):GetComponent('InputField').text = sendToInfo.Content
	RefreshHongbaoFlagOfSendMailPart()
end

-- 写邮件 红包发送信息刷新
function RefreshHongbaoFlagOfSendMailPart()
	if sendToInfo == nil or sendToInfo.GiftGold == 0 then
		this.transform:Find('Canvas/Window/Content/Panel/SendMail/Content/SendTo/hongbao/flag1').gameObject:SetActive(true)
		this.transform:Find('Canvas/Window/Content/Panel/SendMail/Content/SendTo/hongbao/flag2').gameObject:SetActive(false)
	else
		this.transform:Find('Canvas/Window/Content/Panel/SendMail/Content/SendTo/hongbao/flag1').gameObject:SetActive(false)
		this.transform:Find('Canvas/Window/Content/Panel/SendMail/Content/SendTo/hongbao/flag2').gameObject:SetActive(true)
	end
end

--=============================发红包 模块==============================

-- 发红包 返回按钮响应
function CloseHongBaoWindowPart()
	RefreshHongbaoFlagOfSendMailPart()
	RefreshSendPartOfSendButton()
	this.transform:Find('Canvas/Hongbao').gameObject:SetActive(false)
end

-- 发红包 详情UI 刷新显示
function RefreshHongBaoWindow()
	if sendToInfo.GiftGold > 0 then
		this.transform:Find('Canvas/Hongbao/Window/Title/Title1').gameObject:SetActive(false)
		this.transform:Find('Canvas/Hongbao/Window/Title/Title2').gameObject:SetActive(true)
		this.transform:Find('Canvas/Hongbao/Window/Buttons/CancelButton').gameObject:SetActive(false)
		this.transform:Find('Canvas/Hongbao/Window/Buttons/ClearButton').gameObject:SetActive(true)
	else
		this.transform:Find('Canvas/Hongbao/Window/Title/Title1').gameObject:SetActive(true)
		this.transform:Find('Canvas/Hongbao/Window/Title/Title2').gameObject:SetActive(false)
		this.transform:Find('Canvas/Hongbao/Window/Buttons/CancelButton').gameObject:SetActive(true)
		this.transform:Find('Canvas/Hongbao/Window/Buttons/ClearButton').gameObject:SetActive(false)
	end
	
	this.transform:Find('Canvas/Hongbao/Window/GoldCount'):GetComponent("InputField").text =lua_CommaSeperate(GameConfig.GetFormatColdNumber(sendToInfo.GiftGold))
	RefreshHongBaoPartOkButton(sendToInfo.GiftGold)
	local formatStr = data.GetString("Tips_Send_Mail_Rule")
	if formatStr ~= "Tips_Send_Mail_Rule" then
		local minLimitStr = lua_NumberToStyle1String(GameConfig.GetFormatColdNumber(data.PublicConfig.EMAIL_GIFT_GOLD[1]))
		local rateStr = tostring(sendMailCastRate)..'%'
		formatStr = string.format(formatStr, minLimitStr, rateStr)
	end
	this.transform:Find('Canvas/Hongbao/Window/TipText'):GetComponent("Text").text = formatStr
	this.transform:Find('Canvas/Hongbao/Window/TipText').gameObject:SetActive(sendToInfo.GiftGold > 0)
end

-- 发红包 确定按钮响应
function HongBaoPartOkButton_OnClick()
	local goldValueStr = this.transform:Find('Canvas/Hongbao/Window/GoldCount'):GetComponent("InputField").text
	sendToInfo.GiftGold = GameConfig.GetLogicColdNumber(math.abs(tonumber(lua_Remove_CommaSeperate(goldValueStr))))
	CloseHongBaoWindowPart()
end

-- 发红包 清除按钮响应
function HongBaoPartClearButton_OnClick()
	this.transform:Find('Canvas/Hongbao/Window/GoldCount'):GetComponent("InputField").text = tostring(0)
	sendToInfo.GiftGold = 0
	CloseHongBaoWindowPart()
end

-- 发红包 取消按钮响应
function HongBaoPartCancelButtonOnClick()
	CloseHongBaoWindowPart()
end

-- 发红包 红包金额输入变化
function HongBaoPartGold_OnValueChanged(numberStr)
	-- 输入为空时，显示0
	if numberStr == "" then
		this.transform:Find('Canvas/Hongbao/Window/GoldCount'):GetComponent("InputField").text = "0"
		this.transform:Find('Canvas/Hongbao/Window/GoldCount'):GetComponent("InputField"):MoveTextEnd()
		return
	end
	-- 输入超过邮件最大值自动校正为最大值
	if tonumber(lua_Remove_CommaSeperate(numberStr))> GameConfig.GetFormatColdNumber(data.PublicConfig.EMAIL_GIFT_GOLD[2]) then
		this.transform:Find('Canvas/Hongbao/Window/GoldCount'):GetComponent("InputField").text =lua_CommaSeperate(GameConfig.GetFormatColdNumber(data.PublicConfig.EMAIL_GIFT_GOLD[2]))
		this.transform:Find('Canvas/Hongbao/Window/GoldCount'):GetComponent("InputField"):MoveTextEnd()
		return
	end
	
	local newValueStr = lua_CommaSeperate(tonumber(lua_Remove_CommaSeperate(numberStr)))
	if numberStr ~= newValueStr then
		this.transform:Find('Canvas/Hongbao/Window/GoldCount'):GetComponent("InputField").text = newValueStr
		this.transform:Find('Canvas/Hongbao/Window/GoldCount'):GetComponent("InputField"):MoveTextEnd()
	else
		RefreshHongBaoPartOkButton(tonumber(lua_Remove_CommaSeperate(numberStr)))
	end
end

-- 发红包 红包金额输入结束
function HongBaoPartGold_OnEditEnd(value)
	if value == "" or value == "0" then
		this.transform:Find('Canvas/Hongbao/Window/TipText').gameObject:SetActive(false)
		this.transform:Find('Canvas/Hongbao/Window/Buttons/OKButton'):GetComponent("Button").interactable = false
		RefreshHongBaoPartOkButton(0)
	else
		this.transform:Find('Canvas/Hongbao/Window/TipText').gameObject:SetActive(true)
		local inputCount = tonumber(lua_Remove_CommaSeperate(value))
		local havegold = GameConfig.GetFormatColdNumber(GameData.RoleInfo.GoldCount)
		if inputCount > havegold then
			this.transform:Find('Canvas/Hongbao/Window/GoldCount'):GetComponent("InputField").text = "0"
			CS.BubblePrompt.Show(EmailMgr:GetSendMailError(SEND_MAIL_ERROR.GOLD_NOT_ENOUGH), "UIEmail")
			return
		end
		RefreshHongBaoPartOkButton(tonumber(lua_Remove_CommaSeperate(value)))
	end
end

-- 发红包 确认按钮刷新
function RefreshHongBaoPartOkButton(goldCount)
	if goldCount < GameConfig.GetFormatColdNumber(data.PublicConfig.EMAIL_GIFT_GOLD[1]) or goldCount > GameConfig.GetFormatColdNumber(data.PublicConfig.EMAIL_GIFT_GOLD[2]) or goldCount > GameData.RoleInfo.GoldCount then
		this.transform:Find('Canvas/Hongbao/Window/Buttons/OKButton'):GetComponent("Button").interactable = false
	else
		this.transform:Find('Canvas/Hongbao/Window/Buttons/OKButton'):GetComponent("Button").interactable = true
	end
end

-------------------------------Promoter apply part----------------------------------
-- 推广员 数据刷新
function RefreshApplayPart()
	this.transform:Find('Canvas/ApplyPart/Window/weixin/InputValue'):GetComponent("InputField").text = ""
	this.transform:Find('Canvas/ApplyPart/Window/qq/InputValue'):GetComponent("InputField").text = ""
	this.transform:Find('Canvas/ApplyPart/Window/dianhua/InputValue'):GetComponent("InputField").text = ""
	this.transform:Find('Canvas/ApplyPart/Window/password1/InputValue'):GetComponent("InputField").text = ""
	this.transform:Find('Canvas/ApplyPart/Window/password2/InputValue'):GetComponent("InputField").text = ""
end

-- 推广员 返回按钮响应
function ApplyPartReturnButton_OnClick()
	this.transform:Find("Canvas/ApplyPart").gameObject:SetActive(false)
end

-- 推广员 确认按钮响应
function ApplyPartSureButton_OnClick()
	-- 发送消息到HTTP服务器
	-- 发送消息到GameServer服务器
	local weixin = this.transform:Find('Canvas/ApplyPart/Window/weixin/InputValue'):GetComponent("InputField").text
	if weixin == nil or #weixin == 0 then
		CS.BubblePrompt.Show("微信号不能为空", "UIEmail")
		return
	end
	
	local qq = this.transform:Find('Canvas/ApplyPart/Window/qq/InputValue'):GetComponent("InputField").text
	if qq == nil or #qq == 0 then
		CS.BubblePrompt.Show("QQ号不能为空", "UIEmail")
		return
	end
	
	local dianhua =	this.transform:Find('Canvas/ApplyPart/Window/dianhua/InputValue'):GetComponent("InputField").text
	if dianhua == nil or #dianhua == 0 then
		CS.BubblePrompt.Show("电话号码不能为空", "UIEmail")
		return
	end
	
	local psword1 = this.transform:Find('Canvas/ApplyPart/Window/password1/InputValue'):GetComponent("InputField").text
	if psword1 == nil or #psword1 == 0 or #psword1 > 20 or #psword1 < 6 then
		CS.BubblePrompt.Show("密码不能为空，长度6-20", "UIEmail")
		return
	end
	
	local psword2 = this.transform:Find('Canvas/ApplyPart/Window/password2/InputValue'):GetComponent("InputField").text
	if psword1 ~= psword2 then
		CS.BubblePrompt.Show("密码输入不一致", "UIEmail")
		return
	end
	
	CS.LoadingDataUI.Show()
	isUpdateWaitHttpResult = true
	wwwRequest = CS.UnityEngine.WWW(string.format("http://%s/apply.php?id=%d&pwd=%s&qq=%s&wechat=%s&phone=%s&sid=%s",data.PublicConfig.URL_NAME, GameData.RoleInfo.AccountID, psword1, qq, weixin, dianhua, GameData.ServerID))
end

-- 推广员 提交反馈等待
function UpdateWaitHttpResult()
	if wwwRequest ~= nil then
		if wwwRequest.isDone then
			isUpdateWaitHttpResult = false
			if wwwRequest.text ~= nil then
				local errorInfo = wwwRequest.text
				CS.LoadingDataUI.Hide()
				local index1 = string.find(errorInfo, 'paycode=')
				local code = string.sub(errorInfo, index1+8, index1+10)
				if code == "600" then
					GameData.RoleInfo.PromoterStep = 1
					RefreshDetailPartContent()
					ApplyPartReturnButton_OnClick()
					CS.BubblePrompt.Show("提交成功！", "UIEmail")
				else-- “601 fail”
					CS.BubblePrompt.Show("提交失败，请重试！", "UIEmail")
				end
				wwwRequest = nil
			else
				CS.BubblePrompt.Show("提交失败，请重试！", "UIEmail")
			end
			
		end
	end
end
