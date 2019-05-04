print "AccountMgr.lua"


function GetVisitorConfig(cPacket, nSocketID)

	-- 客户端游客登录功能配置
	-- 返回1表示开启游客登录
	-- 返回0表示关闭游客登录
	local tSend = Message:New()
	tSend:Push(UINT8, 1)
	net:SendToClient(tSend, PROTOCOL.GET_VISITOR_CONFIG, nSocketID)
end

if AccountMgr == nil then
    AccountMgr = 
	{
		tAccountByAccount = {},
        tServerCount = {},
        nOpenServerID = 10,
	}
end

function OnLoadAccount(cPacket)
    local tParseData = 
	{
		UINT16, 	-- 通用字段，个数		1
		{
			STRING,
			STRING,
			UINT32,		
		},
	}
	
	local tAccountByAccount = AccountMgr.tAccountByAccount
	local tServerCount = AccountMgr.tServerCount
	local tData = c_ParserPacket(tParseData, cPacket)[1]
	for k,v in pairs(tData) do
		local strAccount = v[1]
		local strPwd = v[2]
		local nServerID = v[3]
		
		local tAccount = 
        {
            strPassword = strPwd,
            nServerID = nServerID,
        }
        
        table.add(tServerCount, nServerID, 1)
		
        if AccountMgr.nOpenServerID < nServerID then
            AccountMgr.nOpenServerID = nServerID
        end        
		
		tAccountByAccount[strAccount] = tAccount
	end
    
    AccountMgr:CheckOpenServerID()
end

function AccountMgr:Init()
	SQLQuery("SELECT gd_Account, gd_Password, gd_ServerID FROM hd_account;", "OnLoadAccount")
end

function AccountMgr:GetAccountByAccount(strAccount)
	local tAccount = AccountMgr.tAccountByAccount[strAccount]
	return tAccount
end

function AccountMgr:CheckOpenServerID()

    local nOpenServerID = AccountMgr.nOpenServerID
    for k,v in pairs(AccountMgr.tServerCount) do
        if v < MAX_REGISTER_COUNT and nOpenServerID > k then
            nOpenServerID = k
        end
    end
    AccountMgr.nOpenServerID = nOpenServerID
    
	print("OpenServerID:", AccountMgr.nOpenServerID)
	PrintTable(AccountMgr.tServerCount, "ServerCount")
end


function GetServerHostAndPort(cPacket, nSocketID)
    local tParseData =
    {
        STRING,
        STRING,
    }
    local tData = c_ParserPacket(tParseData, cPacket)
    local strAccount = tData[1]
    local strPassword = tData[2]
    
    local tSend = Message:New()
    local tAccount = AccountMgr:GetAccountByAccount(strAccount)
    if tAccount ~= nil then        
        if tAccount.strPassword ~= strPassword then
			tSend:Push(STRING, "")
			tSend:Push(UINT16, 0)
			tSend:Push(UINT16, 0)
			net:SendToClient(tSend, PROTOCOL.GET_SERVER_HOST_PORT, nSocketID)
        else       
			tSend:Push(STRING, ServerConfig[tAccount.nServerID].Host)
			tSend:Push(UINT16, ServerConfig[tAccount.nServerID].Port)
			tSend:Push(UINT16, tAccount.nServerID)
			net:SendToClient(tSend, PROTOCOL.GET_SERVER_HOST_PORT, nSocketID)
			--print("GetServerHostAndPort", strAccount, tAccount.nServerID, ServerConfig[tAccount.nServerID].Host, ServerConfig[tAccount.nServerID].Port)
        end
    else
        local nServerCount = AccountMgr.tServerCount[AccountMgr.nOpenServerID]
        if nServerCount ~= nil and nServerCount >= MAX_REGISTER_COUNT then
            AccountMgr.nOpenServerID = AccountMgr.nOpenServerID + 1
        end
        
        local nServerID = AccountMgr.nOpenServerID
        if ServerConfig[nServerID] == nil then
            LogError{"ServerConfig Error, can't find ServerID:%d", nServerID}
            return
        end
        
        table.add(AccountMgr.tServerCount, nServerID, 1)
        
		local tNewAccount = 
        {
            strPassword = strPassword,
            nServerID = nServerID,
        }        
        AccountMgr.tAccountByAccount[strAccount] = tNewAccount   
        SQLQuery(string.format("INSERT INTO hd_account(gd_Account, gd_Password, gd_ServerID) VALUES('%s', '%s', %d)", strAccount, strPassword, nServerID), "")     
        
        tSend:Push(STRING, ServerConfig[tNewAccount.nServerID].Host)
        tSend:Push(UINT16, ServerConfig[tNewAccount.nServerID].Port)
        tSend:Push(UINT16, tNewAccount.nServerID)
        net:SendToClient(tSend, PROTOCOL.GET_SERVER_HOST_PORT, nSocketID)
        --print("New Account", strAccount, tNewAccount.nServerID, ServerConfig[tNewAccount.nServerID].Host, ServerConfig[tNewAccount.nServerID].Port)
    end
end


function ForgetPassword(cPacket, nSocketID)
    local tParseData =
    {
        STRING,
        STRING,
    }
    local tData = c_ParserPacket(tParseData, cPacket)
    local strAccount = tData[1]
    local strNewPwd = tData[2]
    
    local tSend = Message:New()
    local tAccount = AccountMgr:GetAccountByAccount(strAccount)
    if tAccount ~= nil then    
        
        tAccount.strPassword = strNewPwd
        SQLQuery(string.format("UPDATE hd_account SET gd_Password='%s' WHERE gd_Account='%s' LIMIT 1;", strNewPwd, strAccount), "")
        
		tSend:Push(UINT8, 0)
		tSend:Push(STRING, strNewPwd)
		net:SendToClient(tSend, PROTOCOL.FORGET_PASSWORD, nSocketID)
    else        
		tSend:Push(UINT8, 1)
		net:SendToClient(tSend, PROTOCOL.FORGET_PASSWORD, nSocketID)
    end
end