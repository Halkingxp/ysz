print "EmailMgr.lua"


if EmailMgr == nil then
	EmailMgr =
	{
		nEmailID = 0,           -- 当前可分配邮件id(从1开始分配，每次分配后自增，二次起服时，根据加载的邮件决定最新的可分配id号)
		tPersonal = {},			-- 个人邮件
	}
end

--邮件结构体
local MailStruct = 
{
	nSendType = 0, --1为系统邮件2为玩家邮件
	sTitle = '',
	sContent = '',
	nSenderID = 0,
	nSendDate = 0,
	nGold = 0,
	nRoomCard = 0,
	bIsRead = 0,  --0为未读，1为已读
}

function MailStruct:New()
	local tObj = {}
	Extends(tObj, self)
	return tObj
end

function OnRecvEmailData(cPacket, nSocketID)
	local tParseData = 
	{
		UINT16,	-- 数据库返回通用字段   1
		{
			UINT32,		--HeroID	1
			STRING,		--邮件内容	2
		},
	}
	local tData = c_ParserPacket(tParseData, cPacket)[1]
	for k,v in pairs(tData) do
		local nAccountID = v[1]
		local strEmail = v[2]
		
		local tEmail = load(strEmail)()
		EmailMgr.tPersonal[nAccountID] = tEmail
		
		for i,j in pairs(tEmail) do
			if i > EmailMgr.nEmailID then
				EmailMgr.nEmailID = i
			end
		end
	end
end

function EmailMgr:Init()
	SQLQuery(string.format("SELECT gd_AccountID, gd_Email FROM gd_email"), "OnRecvEmailData")
end

-- 回存所有邮件, 每日凌晨5点更新回存一次或关服回存一次
function EmailMgr:SaveEmail()
	-- 回存所有玩家的有附件邮件数据	
	for k,v in pairs(EmailMgr.tPersonal) do
		local rewardEmails = {}
		for i,j in pairs(v) do
			if j.nGold ~= 0 or j.nRoomCard ~= 0 then
				rewardEmails[i] = j
			end
		end
		SQLQuery(string.format("REPLACE INTO gd_email (gd_AccountID, gd_Email) VALUES(%d, '%s')", k, Serialize(rewardEmails)), "")
	end
	
	---- 回存全服邮件数据
	--SQLQuery(string.format("REPLACE INTO gd_email (gd_AccountID, gd_Email) VALUES(%d, '%s')", 1, Serialize(EmailMgr.tWhole)), "")
end

function EmailMgr:GetEmails(nAccountID)
	return EmailMgr.tPersonal[nAccountID]
end

--添加邮件
function EmailMgr:AddMail(nRecvHeroID, nSendType, sTitle, sContent, nSenderID, nGold, nRoomCard, isSend)
	local account = AccountMgr:GetAccountByID(nRecvHeroID)
	if account == nil then
		LogError{"Can not find player by AccountID = %d, SendType:%d, Title:%s, Content:%s, SenderID:%d, Gold:%d, RoomCard:%d",
		nRecvHeroID, nSendType, sTitle, sContent, nSenderID, nGold, nRoomCard}
		return -1
	elseif nReceiverID == nSenderID then
		LogError{"Do not Send Self AccountID = %d, SendType:%d, Title:%s, Content:%s, SenderID:%d, Gold:%d, RoomCard:%d",
		nRecvHeroID, nSendType, sTitle, sContent, nSenderID, nGold, nRoomCard}
		return -1
	end
	
	if sContent ~= "" then
		sContent = c_Base64Encode(sContent)
	end
	
	local mail = MailStruct:New()
	mail.nSendType = nSendType
	mail.sTitle = sTitle or ""
	mail.sContent = sContent or ""
	mail.nSenderID = nSenderID or 0
	mail.nGold = nGold or 0
	mail.nRoomCard = nRoomCard or 0
	mail.nSendDate = GetSystemTimeToSecond()
	mail.bIsRead = 0
	if EmailMgr.tPersonal[nRecvHeroID] == nil then
		EmailMgr.tPersonal[nRecvHeroID] = {}
	end
	
	EmailMgr.nEmailID = EmailMgr.nEmailID + 1
	local mailID = EmailMgr.nEmailID 
	EmailMgr.tPersonal[nRecvHeroID][mailID] = mail
	
	if isSend == true and account:IsOnline() then
		EmailMgr:SendEmailToClient(nRecvHeroID, account.nSocketID, mailID)
	end
	return mailID
end

--删除邮件
function EmailMgr:RemoveMail(nAccountID, mailID)
	local account = AccountMgr:GetAccountByID(nAccountID)
	if account == nil then
		print('can not find player by idaccountID = ', nAccountID)
		return 1
	end
	
	if EmailMgr.tPersonal[nAccountID] == nil then
		print('mail list is empty accountID = ', nAccountID)
		return 2
	end
	if EmailMgr.tPersonal[nAccountID][mailID] == nil then
		print('mail is nil id = ', mailID)
		return 2
	end
	
	-- 将邮件里的金币和房卡加到邮件所属玩家身上
	if EmailMgr.tPersonal[nAccountID][mailID].nGold ~= 0 then
		account:AddGold(EmailMgr.tPersonal[nAccountID][mailID].nGold, OPERATE.EMAILL)
	end
	
	if EmailMgr.tPersonal[nAccountID][mailID].nRoomCard ~= 0 then
		account:AddRoomCard(EmailMgr.tPersonal[nAccountID][mailID].nRoomCard, OPERATE.EMAILL)
	end
	
	EmailMgr.tPersonal[nAccountID][mailID] = nil
	return 0
end

function EmailMgr:GetPlayerUnReadEmailNum(nAccountID)
	local count = 0
	local account = AccountMgr:GetAccountByID(nAccountID)
	if account == nil then
		return 0
	end
	
	if EmailMgr.tPersonal[nAccountID] == nil then
		return 0
	end
	
	for k,v in pairs(EmailMgr.tPersonal[nAccountID]) do
		if v.bIsRead == 0 then
			count = count + 1
		end
	end
	
	return count
end

--阅读邮件
function EmailMgr:ReadMail(nAccountID, mailID)
	local account = AccountMgr:GetAccountByID(nAccountID)
	if account == nil then
		print('can not find player by idaccountID = ', nAccountID)
		return
	end
	
	if EmailMgr.tPersonal[nAccountID] == nil then
		print('mail list is empty accountID = ', nAccountID)
		return
	end
	if EmailMgr.tPersonal[nAccountID][mailID] == nil then
		print('mail is nil id = ', mailID)
		return
	end
	
	EmailMgr.tPersonal[nAccountID][mailID].bIsRead = 1
end

--领取邮件内容
function EmailMgr:GetMailReward(nAccountID, mailID)
	local account = AccountMgr:GetAccountByID(nAccountID)
	if account == nil then
		print('can not find player by idaccountID = ', nAccountID)
		return 1
	end	
	if EmailMgr.tPersonal[nAccountID] == nil then
		print('mail list is empty accountID = ', nAccountID)
		return 2
	end
	if EmailMgr.tPersonal[nAccountID][mailID] == nil then
		print('mail is nil id = ', mailID)
		return 2
	end
	
	if EmailMgr.tPersonal[nAccountID][mailID].nGold == 0 then
		print('mail reward is geted')
		return 3
	end
	
	EmailMgr.tPersonal[nAccountID][mailID].bIsRead = 1
	
	-- 将邮件里的金币和房卡加到邮件所属玩家身上
	if EmailMgr.tPersonal[nAccountID][mailID].nGold ~= 0 then
		account:AddGold(EmailMgr.tPersonal[nAccountID][mailID].nGold, OPERATE.EMAILL)
		EmailMgr.tPersonal[nAccountID][mailID].nGold = 0
	end
	
	if EmailMgr.tPersonal[nAccountID][mailID].nRoomCard ~= 0 then
		account:AddRoomCard(EmailMgr.tPersonal[nAccountID][mailID].nRoomCard, OPERATE.EMAILL)
		EmailMgr.tPersonal[nAccountID][mailID].nRoomCard = 0
	end
	
	return 0
end

function EmailMgr:SendEmailToClient(nAccountID, nSocketID, nMailID)
	--print('1111111111111111111111111111111111111111111111111111111111')
	local tSend = Message:New()
	local sContent = nil
	if EmailMgr.tPersonal[nAccountID] == nil then
		tSend:Push(UINT16, 0)
		net:SendToClient(tSend, PROTOCOL.CS_ADD_EMAILS, nSocketID)
		return
	end
	
	if nMailID == nil then
		local count = table.count(EmailMgr.tPersonal[nAccountID])
		tSend:Push(UINT16, count)
		if count ~= 0 then
			for k,v in pairs(EmailMgr.tPersonal[nAccountID]) do
				if v ~= nil then
					
					local strName = nil
					if v.nSenderID > 0 then
						local account = AccountMgr:GetAccountByID(v.nSenderID)
						if account ~= nil then
							strName = account.strName
						else
							LogInfo('can not find player id = %d', v.nSenderID)
							strName = ""
						end						
					else
						strName = PublicConfig.SYSTEM_EMAIL_NAME
					end					
					
					sContent = v.sContent
					if sContent ~= "" then
						sContent = c_Base64Decode(sContent)
					end
					
					tSend:Push(UINT32, k)
					tSend:Push(UINT8, v.nSendType)
					tSend:Push(STRING, v.sTitle)
					tSend:Push(STRING, sContent)
					tSend:Push(UINT32, v.nSenderID)
					tSend:Push(STRING, strName)
					tSend:Push(UINT32, v.nSendDate)
					tSend:Push(INT64, v.nGold)
					tSend:Push(UINT32, v.nRoomCard)
					tSend:Push(UINT8, v.bIsRead)
				end
			end
		end
		net:SendToClient(tSend, PROTOCOL.CS_ADD_EMAILS, nSocketID)
	else
		if EmailMgr.tPersonal[nAccountID][nMailID] == nil then
			return
		end
		local tSend = Message:New()
		local tMail = EmailMgr.tPersonal[nAccountID][nMailID]
		
		local strName = nil
		if tMail.nSenderID > 0 then
			local account = AccountMgr:GetAccountByID(tMail.nSenderID)
			if account ~= nil then
				strName = account.strName
			else
				LogInfo('can not find player id = %d', tMail.nSenderID)
				strName = ""
			end						
		else
			strName = PublicConfig.SYSTEM_EMAIL_NAME
		end
		
		sContent = tMail.sContent
		if sContent ~= "" then
			sContent = c_Base64Decode(sContent)
		end
		
		tSend:Push(UINT16, 1)
		tSend:Push(UINT32, nMailID)
		tSend:Push(UINT8, tMail.nSendType)
		tSend:Push(STRING, tMail.sTitle)
		tSend:Push(STRING, sContent)
		tSend:Push(UINT32, tMail.nSenderID)
		tSend:Push(STRING, strName)
		tSend:Push(UINT32, tMail.nSendDate)
		tSend:Push(INT64, tMail.nGold)
		tSend:Push(UINT32, tMail.nRoomCard)
		tSend:Push(UINT8, tMail.bIsRead)
		net:SendToClient(tSend, PROTOCOL.CS_ADD_EMAILS, nSocketID)
	end
end

--客户端请求发送邮件
function HandleSendEmail(cPacket, nSocketID)
	--print('recive client send mail')
	local tParseData =
    {
		UINT32,		-- 自己的帐号ID
		UINT8,      -- 发送类型
		STRING,     -- 标题
		STRING,		-- 内容
		UINT32,		-- 接收方id
		INT64,		-- 金币数量
		UINT32,		-- 房卡数量
    }
	local tData = c_ParserPacket(tParseData, cPacket)
	local nAccountID = tData[1]
	local nSendType  = tData[2]
	local strTitle = tData[3]
	local strContent = tData[4]
	local nReceiverID = tData[5]
	local nGold = tData[6]
	local nRoomCard = tData[7]
	local tSend = Message:New()
	local nFee = 0
	
	--获取发送者account
	local tAccount = AccountMgr:GetAccountByID(nAccountID)
	if tAccount == nil then
		tSend:Push(UINT8, 1)
		net:SendToClient(tSend, PROTOCOL.CS_SEND_EMAIL, nSocketID)
		return
	end
	--获取接收者account
	local tReceiver = AccountMgr:GetAccountByID(nReceiverID)
	if tReceiver == nil then
		tSend:Push(UINT8, 3)
		net:SendToClient(tSend, PROTOCOL.CS_SEND_EMAIL, nSocketID)
		return
	end
	
	if nAccountID == nReceiverID then
		tSend:Push(UINT8, 6)
		net:SendToClient(tSend, PROTOCOL.CS_SEND_EMAIL, nSocketID)
		return
	end
	
	nGold = math.abs(nGold)
	
	if nGold == 0 then
		if tAccount.nFreeEmailNum >= PublicConfig.DALIY_FREE_EMAIL_NUM then--如果是发送的免费邮件，且该玩家的免费邮件发送次数已经用完，则返回5
			tSend:Push(UINT8, 5)
			net:SendToClient(tSend, PROTOCOL.CS_SEND_EMAIL, nSocketID)
			return
		else
			tAccount.nFreeEmailNum = tAccount.nFreeEmailNum + 1
			tAccount.isChangeData = true
		end
	else
		--判断金币数量范围是否合乎规则
		if nGold < PublicConfig.EMAIL_GIFT_GOLD[1] or nGold > PublicConfig.EMAIL_GIFT_GOLD[2] then
			tSend:Push(UINT8, 4)
			net:SendToClient(tSend, PROTOCOL.CS_SEND_EMAIL, nSocketID)
			return
		end
		
		--判断发送者金币是否足够
		local maxVip = tReceiver.nVIPLv > tAccount.nVIPLv and tReceiver.nVIPLv or tAccount.nVIPLv
		local needGold = nGold * (1 + 0.01 * VipConfig[maxVip].HandselExtract)
		needGold = math.modf(needGold)
		if tAccount.nGold < needGold then
			tSend:Push(UINT8, 2)
			net:SendToClient(tSend, PROTOCOL.CS_SEND_EMAIL, nSocketID)
			return
		end
		
		--扣钱
		tAccount:AddGold(-needGold, OPERATE.EMAILL, OPERATE.EMAILL)
		
		-- 发送邮件日志
		local nCommission = needGold - nGold
		nFee = nCommission
		SendEmailLog(nAccountID, nReceiverID, nGold, nCommission)
		RoomMgr.nCommission = RoomMgr.nCommission + nCommission
        
        tReceiver.nEmailRecvGold = tReceiver.nEmailRecvGold + nGold
        tReceiver.isChangeData = true
        
        tAccount.nEmailSendGold = tAccount.nEmailSendGold + nGold
        tAccount.isChangeData = true
	end
	
	--通知客户端发送成功
	tSend:Push(UINT8, 0)
	tSend:Push(UINT32, nReceiverID)
	tSend:Push(INT64, nGold)
	tSend:Push(INT64, nFee)
	net:SendToClient(tSend, PROTOCOL.CS_SEND_EMAIL, nSocketID)
	
	--添加邮件到管理器
	local mailID = EmailMgr:AddMail(nReceiverID, nSendType, strTitle, strContent, nAccountID, nGold, 0)
	if mailID == -1 then
		return
	end
	
	--如果对方在线，把邮件发给对方
	if tReceiver:IsOnline() then
		EmailMgr:SendEmailToClient(tReceiver.nAccountID, tReceiver.nSocketID, mailID)
	end
end

--客户端请求阅读邮件
function HandleReadEmail(cPacket, nSocketID)
	local tParseData =
    {
		UINT32,		-- 自己的帐号ID
		UINT32,     -- 邮件id
    }
	local tData = c_ParserPacket(tParseData, cPacket)
	local nAccountID = tData[1]
	local nRmailID = tData[2]
	EmailMgr:ReadMail(nAccountID, nRmailID)
end

--客户端请求获取邮件奖励
function HandleGetEmailReward(cPacket, nSocketID)
	local tParseData =
    {
		UINT32,		-- 自己的帐号ID
		UINT32,     -- 邮件id
    }
	local tData = c_ParserPacket(tParseData, cPacket)
	local nAccountID = tData[1]
	local nEmailID = tData[2]
	local result = EmailMgr:RemoveMail(nAccountID, nEmailID)
	local tSend = Message:New()
	tSend:Push(UINT8, result)
	tSend:Push(UINT32, nEmailID)
	net:SendToClient(tSend, PROTOCOL.CS_GET_EMAIL_REWARD, nSocketID)
end

function HandleDeleteEmail(cPacket, nSocketID)
	--print('request delete email')
	local tParseData =
    {
		UINT32,		-- 自己的帐号ID
		UINT32,     -- 邮件id
    }
	local tData = c_ParserPacket(tParseData, cPacket)
	local nAccountID = tData[1]
	local nEmailID = tData[2]
	local result = EmailMgr:RemoveMail(nAccountID, nEmailID)
	local tSend = Message:New()
	tSend:Push(UINT8, result)
	tSend:Push(UINT32, nEmailID)
	net:SendToClient(tSend, PROTOCOL.CS_DELETE_EMAIL, nSocketID)
end

function HandleRequestEmails(cPacket, nSocketID)
	--print('request emails')
	local tParseData =
    {
		UINT32,		-- 自己的帐号ID
		UINT32,     -- 邮件id
    }
	local tData = c_ParserPacket(tParseData, cPacket)
	local nAccountID = tData[1]
	local nEmailID = tData[2]
	
	EmailMgr:SendEmailToClient(nAccountID, nSocketID)
end