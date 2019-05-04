print "load EmailMgr.lua"

SEND_MAIL_ERROR ={
	SUCCESS = 0,				-- 发送成功
	ACCOUNT_ERROR = 1,			-- 账号错误
	GOLD_NOT_ENOUGH = 2,		-- 金币不足
	NO_ACCOUNT = 3,				-- 对方账号不存在
	GOLD_NUM_ERROR = 4,			-- 金币数量错误
	TIME_MAX = 5,				-- 次数达到上限
	SEND_TO_SELF = 6,			-- 发邮件给自己
}

if EmailMgr == nil then
	EmailMgr =
	{
		mails = nil,
		SortedMailIDList = nil,
	}
end

--邮件结构体
local MailStruct = 
{
	MailID = 0,					--邮件ID
	nSendType = 0, 				--1为系统邮件2为玩家邮件
	sTitle = '',				--邮件的标题
	sContent = '',				--邮件的文字内容
	nSenderID = 0,				--发送者id，如果是系统发的则为1
	sSenderName = "",			--发送者名称
	nSendDate = '',				--发送日期，东八区时间戳
	nGold = 0,					--邮件附带的金币数
	nRoomCard = 0,				--邮件附带的房卡数
	bIsRead = 0,				--0表示未读 1表示已读	
}

function EmailMgr:GetSendMailError(errorType)
	return data.GetString("Send_Mail_".. errorType)
end

local UpdateMailEventArgs = 
{	
	Reason = 0,			-- 更新的原因(1， 增加，2 删除， 3，内容更新)
	MailID = 0,			-- 更新的邮件ID	
}

function MailStruct:New()
	local tObj = {}
	Extends(tObj, MailStruct)
	return tObj
end

function EmailMgr:InitList()
	self.mails = {}
	self.SortedMailIDList = {}
end

function EmailMgr:ClearAll()
	self.mails = nil
	self.SortedMailIDList = nil
end

function EmailMgr:AddMail(nMailID, nSendType, sTitle, sContent, nSenderID,sSenderName, nSendDate, nGold, nRoomCard, bIsRead)
	if self.mails[nMailID] ~= nil then
		return
	end
	local mail = MailStruct:New()
	mail.MailID = nMailID
	mail.nSendType = nSendType
	mail.sTitle = sTitle
	mail.sContent = sContent
	mail.nSenderID = nSenderID
	mail.sSenderName = sSenderName
	mail.nGold = nGold
	mail.nRoomCard = nRoomCard
	mail.nSendDate = nSendDate
	mail.bIsRead = bIsRead
	self.mails[nMailID] = mail
end

function EmailMgr:DelMail(nMailID)
	if self.mails[nMailID] == nil then
		print('删除邮件时，找不到邮件 id = '..nMailID)
		return
	else
		local mailInfo = self.mails[nMailID]
		if mailInfo.bIsRead == 0 then
			GameData.ResetUnreadMailCount(GameData.RoleInfo.UnreadMailCount - 1)	
		end
		self.mails[nMailID] = nil
	end
	EmailMgr:RefreshSortMailIDList()
	-- 事件通知
	local eventArg = lua_NewTable(UpdateMailEventArgs)
	eventArg.Reason = 2
	eventArg.MailID = nMailID
 	CS.EventDispatcher.Instance:TriggerEvent(EventDefine.UpdateEmailInfo, eventArg)
end	

function EmailMgr:ReadMail(nMailID)
	if self.mails[nMailID] == nil then
		print('阅读邮件时，找不到邮件 id = '..nMailID)
		return
	end
	if self.mails[nMailID].bIsRead ~= 1 then
		self.mails[nMailID].bIsRead = 1
		GameData.ResetUnreadMailCount(GameData.RoleInfo.UnreadMailCount - 1)
		NetMsgHandler.SendReadEmail(nMailID)
	end
end

function EmailMgr:IsReadEmail(nMailID)
	if self.mails[nMailID] == nil then
		print('检查邮件阅读状态时，找不到邮件 id = '..nMailID)
		return
	end
	
	return self.mails[nMailID].bIsRead == 1
end

function EmailMgr:GetMailReward(nMailID)
	if self.mails[nMailID] == nil then
		print('获取邮件奖励时，找不到邮件 id = '..nMailID)
		return
	end
	self.mails[nMailID].bIsRead = 1
	self.mails[nMailID].nGold = 0
	self.mails[nMailID].nRoomCard = 0
	-- 事件通知
	local eventArg = lua_NewTable(UpdateMailEventArgs)
	eventArg.Reason = 3
	eventArg.MailID = nMailID
 	CS.EventDispatcher.Instance:TriggerEvent(EventDefine.UpdateEmailInfo, eventArg)
end

function EmailMgr:GetMailList()
	return self.mails
end

function EmailMgr:RefreshSortMailIDList()
	print("刷新邮件排序列表")
	local forSortItem = {}
	for	key, value in pairs(self.mails) do
		local item = {}
		item.Date = value.nSendDate
		item.MailID = value.MailID
		table.insert(forSortItem, item)
	end
	table.sort(forSortItem, function(a,b) return a.Date > b.Date end)
	local resultTable = {}
	for k, v in pairs(forSortItem) do
		resultTable[k] = v.MailID
	end
	self.SortedMailIDList = resultTable
end

function EmailMgr:GetMailIDListOfSortBySendData()
	return self.SortedMailIDList
end

function EmailMgr:RefreshUnreadMailCount()
	local unreadCount = 0
	for key,mailInfo in pairs(self.mails) do
		if mailInfo.bIsRead == 0 then
			unreadCount = unreadCount + 1
		end		
	end
	GameData.ResetUnreadMailCount(unreadCount)
end

-- 获取邮件显示内容
function EmailMgr:GetMailDisplayContent(mailInfo)
	local sendType = mailInfo.nSendType
	if sendType == MAIL_TYPE.INVITE then
		return data.MailContentConfig[sendType].Value
	elseif sendType == MAIL_TYPE.PROMOTER then
		local formatStr = data.MailContentConfig[sendType].Value
		return string.format(formatStr, mailInfo.sContent, tostring(GameData.RoleInfo.AccountID))
	elseif sendType == MAIL_TYPE.PASSWORD then
		local formatStr = data.MailContentConfig[sendType].Value
		return string.format(formatStr, mailInfo.sContent)
	elseif sendType == MAIL_TYPE.REBATE then
		local formatStr = data.MailContentConfig[sendType].Value
		return string.format(formatStr, lua_CommaSeperate(GameConfig.GetFormatColdNumber(mailInfo.sContent)))
	else	
		return mailInfo.sContent
	end
end