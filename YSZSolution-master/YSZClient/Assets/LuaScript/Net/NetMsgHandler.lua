require 'GameConfig'
require 'GameData'
require 'Net/Protrocol'

NetMsgHandler = { };

-- 游戏服务器
local loginNetClient = nil;
-- 登陆Hub服务器
local hubNetClient = nil;

local CutOutTime = 0 -- 用于记录切出时间，以及再次切入时，记录切入切出的间隔时间
local IsAutoConnect = false-- 用于自动重连的判定
local AutoConnectCount = 0-- 用于自动重连次数的统计
local IsProactiveDisconnect = false -- 如果是主动断开链接则为true，在此状态值下，不走断线重连流程
local SaveMsgList = CustomList:new()

local isConnectingHub = true

-- 初始化，注册消息解析函数
function NetMsgHandler.Init()
    CS.EventDispatcher.Instance:AddEventListener("Application_CutOut", NetMsgHandler.OnCutOut)
    CS.EventDispatcher.Instance:AddEventListener("Application_ClearMessage_OK", NetMsgHandler.OnClearMessageOK)
    CS.EventDispatcher.Instance:AddEventListener("Application_ConnectionLost", NetMsgHandler.OnConnectionLost)
end

function NetMsgHandler.InitHubNetClient()
    hubNetClient:RegisterParser(ProtrocolID.CS_Request_Game_Server, NetMsgHandler.Received_CS_Request_Game_Server)
    hubNetClient:RegisterParser(ProtrocolID.CS_Visitor_Check, NetMsgHandler.Received_CS_Visitor_Check)
end

-- 尝试连接hub服务器(islogin: true 走登录流程 false 走游客开关验证流程)
function NetMsgHandler.TryConnectHubServer(islogin)
    isConnectingHub = true
    CS.LoadingDataUI.Show(5)
    if hubNetClient == nil then
        hubNetClient = CS.Net.ConnectManager:Instance():FindNetworkClient("HubServer")
        if hubNetClient == nil then
            hubNetClient = CS.Net.ConnectManager:Instance():CreateNetworkClient("HubServer")
            if hubNetClient == nil then
                CS.BubblePrompt.Show("连接失败,请检查网络", "UILogin")
                return
            end
            NetMsgHandler.InitHubNetClient()
        end
    end
    print("connect hub sever： " .. GameConfig.HubServerURL)

    if hubNetClient.IsConnectedServer then
        if islogin then
            -- 登录流程
            local message = CS.Net.PushMessage()
            message:PushString(GameData.LoginInfo.Account)

            CS.LoadingDataUI.Show(5, function()
                CS.BubblePrompt.Show("网络连接失败，请检查！", "UILogin")
                hubNetClient:DisConnect()
            end )

            hubNetClient:SendMessage(ProtrocolID.CS_Request_Game_Server, message.Message)
        else
            -- 游客登录验证流程
            print('游客登录验证请求')
            local message = CS.Net.PushMessage()

            hubNetClient:SendMessage(ProtrocolID.CS_Visitor_Check, message.Message)
        end
    else
        local hubServerIP = CS.Utility.GetGameServerIP(GameConfig.HubServerURL)
        hubNetClient:DisConnect()
        hubNetClient:StartUpRaknet(string.find(hubServerIP, ":") ~= nil)
        hubNetClient:Connect(hubServerIP, GameConfig.HubServerPort, function(success)
            CS.LoadingDataUI.Hide()
            if success then
                if islogin then
                    -- 登录流程
                    local message = CS.Net.PushMessage()
                    message:PushString(GameData.LoginInfo.Account)

                    CS.LoadingDataUI.Show(5, function()
                        CS.BubblePrompt.Show("网络连接失败，请检查！", "UILogin")
                        hubNetClient:DisConnect()
                    end )

                    hubNetClient:SendMessage(ProtrocolID.CS_Request_Game_Server, message.Message)
                else
                    -- 游客登录验证流程
                    print('游客登录验证请求')
                    local message = CS.Net.PushMessage()

                    hubNetClient:SendMessage(ProtrocolID.CS_Visitor_Check, message.Message)
                end

            else
                -- 连接失败，显示日志信息
                CS.LoadingDataUI.Hide()
                CS.BubblePrompt.Show("网络连接失败，请检查！", "UILogin")
                hubNetClient:DisConnect()
                if false == islogin then
                    -- 游客登录验证失败 游客不能登录
                    CS.EventDispatcher.Instance:TriggerEvent(EventDefine.NotifyVisitorCheckEvent, 0)
                end
            end
        end )
    end

end

-------------------------------------------------------------------
----------------------NetMsgHandler.Received_CS_Visitor_Check 198
-- 游客登录开关
function NetMsgHandler.Received_CS_Visitor_Check(message)
    CS.LoadingDataUI.Hide()
    -- 0 游客不能登录 1游客可以登录
    local resultType = message:PopByte()
    print('服务器反馈 游客是否登录:' .. resultType)
    CS.EventDispatcher.Instance:TriggerEvent(EventDefine.NotifyVisitorCheckEvent, resultType)
end

---------------------------------------------------------------------------
----------------------CS_Request_Game_Server  199--------------------------
function NetMsgHandler.Received_CS_Request_Game_Server(message)
    isConnectingHub = false
    CS.LoadingDataUI.Hide()

    GameConfig.GameServerURL = message:PopString()
    GameConfig.GameServerPort = message:PopUInt16()
    GameData.ServerID = message:PopUInt16()
    print("game server url: " .. GameConfig.GameServerURL)
    GameConfig.GameServerIP = CS.Utility.GetGameServerIP(GameConfig.GameServerURL)
    NetMsgHandler.ConnectAndSendLogin()
    -- 关闭掉 HubServer
    CS.Net.ConnectManager:Instance():CloseNetworkClient("HubServer")
    hubNetClient = nil
end

-- 初始化登陆服务器连接
function NetMsgHandler.InitLoginNetClient()
    -- 200-209
    print("注册网络消息处理11111111111111111111")
    loginNetClient:RegisterParser(ProtrocolID.S_SFT_PAY_RESULT, NetMsgHandler.HandleSFTPayResult)
    loginNetClient:RegisterParser(ProtrocolID.CS_Login, NetMsgHandler.HandleReceivedLogin)
    loginNetClient:RegisterParser(ProtrocolID.S_Disconnect, NetMsgHandler.HandleReceivedDisconnect)
    loginNetClient:RegisterParser(ProtrocolID.S_Update_Diamond, NetMsgHandler.HandleReceivedUpdateDiamond)
    loginNetClient:RegisterParser(ProtrocolID.S_Update_Gold, NetMsgHandler.HandleReceivedUpdateGold)
    loginNetClient:RegisterParser(ProtrocolID.S_Update_FreeGold, NetMsgHandler.HandleReceivedUpdateFreeGold)
    loginNetClient:RegisterParser(ProtrocolID.S_Update_RoomCard, NetMsgHandler.HandleReceivedUpdateRoomCard)
    loginNetClient:RegisterParser(ProtrocolID.S_Update_Charge, NetMsgHandler.HandleReceivedUpdateCharge)
    loginNetClient:RegisterParser(ProtrocolID.CS_Convert_Gold, NetMsgHandler.HandleReceivedConvertGoldResult)
    loginNetClient:RegisterParser(ProtrocolID.CS_Convert_RoomCard, NetMsgHandler.HandleReceivedConvertRoomCardResult)
    loginNetClient:RegisterParser(ProtrocolID.CS_RECOVER_GAME, NetMsgHandler.HandleCutOutReturn)
    loginNetClient:RegisterParser(ProtrocolID.CS_REQUEST_ACCOUNT_DATA, NetMsgHandler.HandleAccountInfo)
    loginNetClient:RegisterParser(ProtrocolID.CS_REQUEST_ROOM_DATA, NetMsgHandler.HandleRoomInfo)
    loginNetClient:RegisterParser(ProtrocolID.CS_BIND_ACCOUNT, NetMsgHandler.OnServerBindAccountResult)

    -- 352~360
    loginNetClient:RegisterParser(ProtrocolID.S_Notify_Wait_State, NetMsgHandler.Received_S_Notify_Wait_State)
    loginNetClient:RegisterParser(ProtrocolID.S_Notify_Shuffle_State, NetMsgHandler.Received_S_Notify_Shuffle_State)
    loginNetClient:RegisterParser(ProtrocolID.S_Notify_Cut_State, NetMsgHandler.Received_S_Notify_Cut_State)
    loginNetClient:RegisterParser(ProtrocolID.S_Notify_Play_Cut_State, NetMsgHandler.Received_S_Notify_Play_Cut_State)
    loginNetClient:RegisterParser(ProtrocolID.S_Notify_Bet_State, NetMsgHandler.Received_S_Notify_Bet_State)
    loginNetClient:RegisterParser(ProtrocolID.S_Notify_Deal_State, NetMsgHandler.Received_S_Notify_Deal_State)
    loginNetClient:RegisterParser(ProtrocolID.S_Notify_Long_Check_State, NetMsgHandler.Received_S_Notify_Long_Check_State)
    loginNetClient:RegisterParser(ProtrocolID.S_Notify_Hu_Check_State, NetMsgHandler.Received_S_Notify_Hu_Check_State)
    loginNetClient:RegisterParser(ProtrocolID.S_Notify_Settlement_State, NetMsgHandler.Received_S_Notify_Settlement_State)
    loginNetClient:RegisterParser(ProtrocolID.S_Notify_Check1_Over, NetMsgHandler.Received_S_Notify_Check1_Over)
    loginNetClient:RegisterParser(ProtrocolID.S_Notify_Check2_Over, NetMsgHandler.Received_S_Notify_Check2_Over)

    -- 400~404
    loginNetClient:RegisterParser(ProtrocolID.CS_Enter_Room, NetMsgHandler.Received_CS_Enter_Room)
    loginNetClient:RegisterParser(ProtrocolID.CS_Exit_Room, NetMsgHandler.Received_CS_Exit_Room)
    loginNetClient:RegisterParser(ProtrocolID.CS_Create_Room, NetMsgHandler.Received_CS_Create_Room)
    loginNetClient:RegisterParser(ProtrocolID.CS_Bet, NetMsgHandler.Received_CS_Bet)
    loginNetClient:RegisterParser(ProtrocolID.CS_Check_Card_Process, NetMsgHandler.Received_CS_Check_Card_Process)

    -- 405~409
    loginNetClient:RegisterParser(ProtrocolID.CS_Checked_Card, NetMsgHandler.Received_CS_Checked_Card)
    loginNetClient:RegisterParser(ProtrocolID.S_Bet_Rank_List, NetMsgHandler.Received_S_Bet_Rank_List)
    loginNetClient:RegisterParser(ProtrocolID.CS_Request_Statistics, NetMsgHandler.Received_CS_Request_Statistics)
    loginNetClient:RegisterParser(ProtrocolID.S_Room_Statistics, NetMsgHandler.Received_S_Room_Statistics)
    loginNetClient:RegisterParser(ProtrocolID.S_Room_Append_Statistics, NetMsgHandler.Received_S_Room_Append_Statistics)

    -- 410~418
    loginNetClient:RegisterParser(ProtrocolID.CS_Request_Relative_Room, NetMsgHandler.Received_CS_Request_Relative_Room)
    loginNetClient:RegisterParser(ProtrocolID.S_Set_Bet_First, NetMsgHandler.Received_S_Set_Bet_First)
    loginNetClient:RegisterParser(ProtrocolID.S_Set_Game_Data, NetMsgHandler.Received_S_Set_Game_Data)
    loginNetClient:RegisterParser(ProtrocolID.CS_Vip_Start_Game, NetMsgHandler.Received_CS_Vip_Start_Game)
    loginNetClient:RegisterParser(ProtrocolID.S_Notify_Game_End, NetMsgHandler.Received_S_Notify_Game_End)
    loginNetClient:RegisterParser(ProtrocolID.CS_Request_Continue_Game, NetMsgHandler.Received_CS_Request_Continue_Game)
    loginNetClient:RegisterParser(ProtrocolID.S_Notify_Game_Player_Count, NetMsgHandler.Received_S_Notify_Game_Player_Count)
    loginNetClient:RegisterParser(ProtrocolID.CS_Up_Banker, NetMsgHandler.Received_CS_Up_Banker)
    loginNetClient:RegisterParser(ProtrocolID.CS_Up_Banker_List, NetMsgHandler.Received_CS_Up_Banker_List)

    -- 420~428
    loginNetClient:RegisterParser(ProtrocolID.S_Notify_Win_Gold, NetMsgHandler.Received_S_Notify_Win_Gold)
    loginNetClient:RegisterParser(ProtrocolID.S_Update_Banker, NetMsgHandler.Received_S_Update_Banker)
    loginNetClient:RegisterParser(ProtrocolID.S_Update_Banker_Gold, NetMsgHandler.Received_S_Update_Banker_Gold)
    loginNetClient:RegisterParser(ProtrocolID.CS_Cut_Card, NetMsgHandler.Received_CS_Cut_Card)
    loginNetClient:RegisterParser(ProtrocolID.CS_Request_Role_List, NetMsgHandler.Received_CS_Request_Role_List)
    loginNetClient:RegisterParser(ProtrocolID.CS_Player_Cut_Type, NetMsgHandler.Received_CS_Player_Cut_Type)
    loginNetClient:RegisterParser(ProtrocolID.CS_Player_Icon_Change, NetMsgHandler.Received_CS_Player_Icon_Change)
    loginNetClient:RegisterParser(ProtrocolID.CS_Player_YuYinChat, NetMsgHandler.Received_CS_Player_YuYinChat)
    loginNetClient:RegisterParser(ProtrocolID.CS_Apply_Down_Banker, NetMsgHandler.Received_CS_Apply_Down_Banker)
    loginNetClient:RegisterParser(ProtrocolID.CS_Apply_Banker_State, NetMsgHandler.Received_CS_Apply_Banker_State)
    -- 500
    loginNetClient:RegisterParser(ProtrocolID.S_Add_MoveNotice, NetMsgHandler.HandleAddMoveNotice);
    -- 501
    loginNetClient:RegisterParser(ProtrocolID.CS_SmallHorn, NetMsgHandler.HandleSmallHorn);
    -- 502
    loginNetClient:RegisterParser(ProtrocolID.CS_SEND_EMAIL, NetMsgHandler.HandleSendEmailResult);
    -- 503
    loginNetClient:RegisterParser(ProtrocolID.CS_CHECK_ACCOUNTID, NetMsgHandler.HandleCheckAccountIDResult);
    -- 504
    loginNetClient:RegisterParser(ProtrocolID.CS_OTHER_PLAYER_INFO, NetMsgHandler.HandleOtherPlayerInfoResult);
    -- 506
    loginNetClient:RegisterParser(ProtrocolID.CS_GET_EMAIL_REWARD, NetMsgHandler.HandleGetEmailRewardResult);
    -- 507
    loginNetClient:RegisterParser(ProtrocolID.CS_ADD_EMAILS, NetMsgHandler.HandleReceiveEmail);
    -- 508
    loginNetClient:RegisterParser(ProtrocolID.CS_DELETE_EMAIL, NetMsgHandler.HandleDeleteEmail);
    -- 509
    loginNetClient:RegisterParser(ProtrocolID.CS_MODIFY_NAME, NetMsgHandler.HandleModifyName);
    -- 510
    loginNetClient:RegisterParser(ProtrocolID.CS_ALL_RANK, NetMsgHandler.HandleAllRankInfo)
    -- 512 - 513
    loginNetClient:RegisterParser(ProtrocolID.CS_PAOPAO_CHAT, NetMsgHandler.HandleChatPaoPao)
    loginNetClient:RegisterParser(ProtrocolID.CS_Request_Game_History, NetMsgHandler.Received_CS_Request_Game_History)
    -- 601 - 602
    loginNetClient:RegisterParser(ProtrocolID.CS_Invite_Code, NetMsgHandler.Received_CS_Invite_Code)
    loginNetClient:RegisterParser(ProtrocolID.S_Update_Promoter, NetMsgHandler.Received_S_Update_Pomoter)

    -- 801--809
    loginNetClient:RegisterParser(ProtrocolID.CS_JH_Create_Room, NetMsgHandler.Received_CS_JH_Create_Room)
    loginNetClient:RegisterParser(ProtrocolID.CS_JH_Enter_Room1, NetMsgHandler.Received_CS_JH_Enter_Room1)
    loginNetClient:RegisterParser(ProtrocolID.CS_JH_Enter_Room2, NetMsgHandler.Received_CS_JH_Enter_Room2)
    loginNetClient:RegisterParser(ProtrocolID.S_JH_Set_Game_Data, NetMsgHandler.Received_S_JH_Set_Game_Data)
    loginNetClient:RegisterParser(ProtrocolID.S_JH_Next_State, NetMsgHandler.Received_S_JH_Next_State)
    loginNetClient:RegisterParser(ProtrocolID.S_JH_Add_Player, NetMsgHandler.Received_S_JH_Add_Player)
    loginNetClient:RegisterParser(ProtrocolID.S_JH_Delete_Player, NetMsgHandler.Received_S_JH_Delete_Player)
    loginNetClient:RegisterParser(ProtrocolID.CS_JH_Exit_Room, NetMsgHandler.Received_CS_JH_Exit_Room)
    loginNetClient:RegisterParser(ProtrocolID.CS_JH_Ready, NetMsgHandler.Received_CS_JH_Ready)
    loginNetClient:RegisterParser(ProtrocolID.CS_JH_Betting, NetMsgHandler.Received_CS_JH_Betting)
    loginNetClient:RegisterParser(ProtrocolID.CS_JH_VS_Card, NetMsgHandler.Received_CS_JH_VS_Card)
    loginNetClient:RegisterParser(ProtrocolID.CS_JH_Drop_Card, NetMsgHandler.Received_CS_JH_Drop_Card)
    loginNetClient:RegisterParser(ProtrocolID.CS_JH_Look_Card, NetMsgHandler.Received_CS_JH_Look_Card)


end

function NetMsgHandler.RegisterGameParser(protrocolID, handler)
    loginNetClient:RegisterParser(protrocolID, handler)
end

function NetMsgHandler.RemoveGameParser(protrocolID, handler)
    if loginNetClient ~= nil then
        loginNetClient:RemoveParser(protrocolID, handler)
    end
end

function NetMsgHandler.CloseConnect()
    if loginNetClient ~= nil then
        -- print("调用raknet的disconnect接口")
        loginNetClient:DisConnect()
    end
end

-- 向GameServer 发送消息
-- protrocolID : ushort 消息编号
-- message ：CS.Net.PushMessage 类型消息
-- openLoadingDataUI: bool 是否开启数据加载界面
function NetMsgHandler.SendMessageToGame(protrocolID, message, openLoadingDataUI)

    if loginNetClient ~= nil then
        if openLoadingDataUI then
            CS.LoadingDataUI.Show()
        end

        loginNetClient:SendMessage(protrocolID, message.Message)
    else
        print('LoginNetClient was null when you want send message[' .. protrocolID .. '] to server, please check and fix this!')
    end
end

function NetMsgHandler.OnCutOut(isCutOut)
    if isConnectingHub then

        return
    end

    if GameData.GameState <= GAME_STATE.LOGIN then
        -- print("切入切出时，处于登陆状态，不做其他处理")
        return
    end

    print("切出游戏")
    -- ***** 开发测试可开启 正式版本一定要记住关闭该功能****
    if true == GameConfig.IsDebug then
        return
    end


    if isCutOut == true then
        -- 切出
        print("切出游戏")
        CutOutTime = os.time()
        -- 记录下切出时刻
        loginNetClient:ShutDown()
        -- 关闭raknet
        GameData.OpenInstallRoomID = nil
        GameData.OpenInstallReferralsID = nil
    else
        -- 切回
        print("切回游戏")
        GameData.OpenInstallRoomID = nil
        GameData.OpenInstallReferralsID = nil
        CutOutTime = os.time() - CutOutTime
        -- 计算出切出的总时长
        print("切出总时长" .. CutOutTime)
        -- 如果切出超过10分钟，直接返回登陆界面
        if CutOutTime > data.PublicConfig.CUT_OUT_RETURN_LOGIN_TIME then
            print("切出超过5分钟，直接返回登陆界面")
            NetMsgHandler.ReturnLogin()
            return
        end

        CS.LoadingDataUI.Show(5)
        print("创建新的连接，悄悄地走一遍登陆流程 lastLoginType = " .. LoginMgr.lastLoginType)
        IsAutoConnect = true
        NetMsgHandler.ConnectAndSendLogin()
    end
end

function NetMsgHandler.OnClearMessageOK(param)
    -- print('清除缓存消息完毕，给服务器发送切回通知')
    CS.LoadingDataUI.Show(5);
end

function NetMsgHandler.OnConnectionLost(param)
    if isConnectingHub then
        CS.EventDispatcher.Instance:TriggerEvent(EventDefine.NotifyVisitorCheckEvent, 0)
        return
    end

    print('底层发现连接中断 id = ' .. param)
    if IsProactiveDisconnect then
        print("主动断开连接，不走自动重连流程")
        return
    end

    local isReturnLoginUI = false
    if param == 21 then
        -- 服务器关闭
        -- 尝试自动重连
        AutoConnectCount = AutoConnectCount + 1
    elseif param == 32 then
        -- 服务器强踢客户端
        -- 切回登陆界面
        CS.BubblePrompt.Show("连接超时！", "NB")
        isReturnLoginUI = true
    elseif param == 17 then
        -- 连接请求无法完成时收到此消息
        -- 切回登陆界面
        CS.BubblePrompt.Show("连接超时！", "NB")
        isReturnLoginUI = true
    elseif param == 22 then
        -- 数据包不能发送到指定系统，与该系统的连接已经关闭
        -- 尝试自动重连
        AutoConnectCount = AutoConnectCount + 1
    end

    if AutoConnectCount >= 3 then
        NetMsgHandler.ReturnLogin()
    end

    if isReturnLoginUI == true then
        NetMsgHandler.ReturnLogin()
    else
        -- 创建新的连接，悄悄地走一遍登陆流程
        CS.LoadingDataUI.Show(5)
        -- print("创建新的连接，悄悄地走一遍登陆流程")
        IsAutoConnect = true
        NetMsgHandler.ConnectAndSendLogin()
    end
end

function NetMsgHandler.ConnectAndSendLogin()
    CS.LoadingDataUI.Show(5)
    if loginNetClient == nil then
        loginNetClient = CS.Net.ConnectManager:Instance():FindNetworkClient("LoginServer")
        if loginNetClient == nil then
            loginNetClient = CS.Net.ConnectManager:Instance():CreateNetworkClient("LoginServer")
            if loginNetClient == nil then
                CS.BubblePrompt.Show("连接失败,请检查网络", "UILogin")
                return
            end
            NetMsgHandler.InitLoginNetClient()
        end
    end

    local realConnectIP
    if string.find(GameConfig.GameServerIP, ":") ~= nil then
        -- 当前网络环境为ipv6
        realConnectIP = GameConfig.GameServerIP
        loginNetClient:StartUpRaknet(true)
        print("当前处于ipv6网络")
    else
        realConnectIP = GameConfig.GameServerIP
        loginNetClient:StartUpRaknet(false)
        print("当前处于ipv4网络")
    end

    if GameConfig.GameServerIP == "" then
        print("GameServerIP = 为空")
        -- 尝试获取一次ip地址，如果还是获取不到，则提示玩家，链接服务器失败
        GameConfig.GameServerIP = CS.Utility.GetGameServerIP(GameConfig.GameServerURL)
        if GameConfig.GameServerIP == "" then
            CS.BubblePrompt.Show("连接失败,请检查网络", "UILogin")
            return
        end
    end

    print("即将连接的 GameServerIP = " .. realConnectIP .. "  platformType = " .. GameData.LoginInfo.PlatformType)
    loginNetClient:Connect(realConnectIP, GameConfig.GameServerPort, function(success)
        -- print('连接回调返回值为'..tostring(success))
        if success then
            IsProactiveDisconnect = false
            LoginMgr.isChangeAccount = 0
            NetMsgHandler.Send_CS_Login()
        else
            -- 连接失败，显示日志信息
            -- print('连接服务器失败')
            CS.LoadingDataUI.Hide();
            -- CS.EventDispatcher.Instance:TriggerEvent(EventDefine.ConnectGameServerFail, 1)
            if GameData.GameState ~= GAME_STATE.LOGIN then
                NetMsgHandler.ReturnLogin()
            end
        end
    end );
end

function NetMsgHandler.ReturnLogin()
    IsProactiveDisconnect = true
    IsAutoConnect = false
    AutoConnectCount = 0

    if GameData.GameState == GAME_STATE.LOGIN then
        -- LoginUIData:ShowLoginBtns()
        return
    end
    loginNetClient:ShutDown()
    CS.WindowManager.Instance:CloseAllWindows()
    -- 打开登陆界面
    local openparam = CS.WindowNodeInitParam("UILogin")
    openparam.NodeType = 0
    openparam.LoadComplatedCallBack =
    function(windowNode)
        -- 重回登录界面，重新校验版本信息
        CS.Utility.RecheckAppVersion(NetMsgHandler.CheckAppVersionCallBack)
    end
    CS.WindowManager.Instance:OpenWindow(openparam)

    EmailMgr:ClearAll()
    GameData.RoleInfo.UnreadMailCount = 0
    CS.MoveNotice.ClearAll()
    GameData.GameState = GAME_STATE.LOGIN
end

function NetMsgHandler.CheckAppVersionCallBack(result)
    GameData.AppVersionCheckResult = result
end

function NetMsgHandler.CanSendMessage()
    if loginNetClient == nil then
        return false
    else
        return loginNetClient:CanSendMessage()
    end
end

---------------------------------------------------------------------------
----------------------------S_SFT_PAY_RESULT  113--------------------------
function NetMsgHandler.HandleSFTPayResult(message)
    -- print('服务器通知 盛付通 支付成功！')
    CS.LoadingDataUI.Hide()
end

---------------------------------------------------------------------------
-------------------------------CS_Login  200-------------------------------

-- 链接超时
function ConnectTimeOut()
    -- print('Connect server time out');
    CS.EventDispatcher.Instance:TriggerEvent(EventDefine.ConnectGameServerTimeOut, 1)
end

-- 请求登录游戏服务器
function NetMsgHandler.Send_CS_Login()
    local message = CS.Net.PushMessage()
    message:PushString(GameData.LoginInfo.Account)
    -- message:PushString('AccountA')
    message:PushUInt16(GameData.LoginInfo.PlatformType)
    message:PushString(GameData.LoginInfo.AccountName)
    message:PushUInt16(GameData.ChannelCode)
    NetMsgHandler.SendMessageToGame(ProtrocolID.CS_Login, message, true);
    print('链接服务器 渠道ID:' .. GameData.ChannelCode)
end

-- 处理收到服务器 登陆结果 消息
function NetMsgHandler.HandleReceivedLogin(message)
    CS.LoadingDataUI.Hide()
    local resultType = message:PopByte()
    if resultType == 0 then
        -- 登陆成功,设置角色基本信息
        GameData.RoleInfo.AccountID = message:PopUInt32()
        GameData.RoleInfo.AccountName = message:PopString()
        GameData.RoleInfo.DiamondCount = message:PopInt64()
        local goldCount = message:PopInt64()
        GameData.UpdateGoldCount(goldCount, 0)
        GameData.RoleInfo.RoomCardCount = message:PopUInt32()
        GameData.RoleInfo.FreePlayTimes = message:PopSByte()
        GameData.RoleInfo.VipLevel = message:PopByte()
        GameData.RoleInfo.ChargeCount = message:PopUInt32()

        GameData.RoleInfo.YesterdayRank = message:PopByte()
        -- GameData.RoleInfo.YesterdayWinRank = message:PopByte()
        GameData.RoleInfo.YesterdayGoldNum = message:PopInt64()
        -- GameData.RoleInfo.YesterdayWinNum = message:PopInt64()
        local roomID = message:PopUInt32()
        -- 房间ID; 若ID为0表示在大厅
        -- 设置未读邮件数
        local unreademailNum = message:PopUInt16()
        print("服务器发来的未读邮件数" .. unreademailNum)
        GameData.ResetUnreadMailCount(unreademailNum)

        GameData.RoleInfo.PromoterStep = message:PopByte()
        GameData.RoleInfo.IsBindAccount =(message:PopByte() == 1)
        GameData.RoleInfo.InviteCode = message:PopUInt32()
        GameData.RoleInfo.ModifyNameCount = message:PopByte()
        -- 改名次数
        GameData.RoleInfo.AccountIcon = message:PopByte()
        -- 头像ID
        -- GameData.ServerID = message:PopUInt16()  -- 服务器ID
        GameData.IsOpenApplePay = message:PopByte()
        -- 是否开启苹果支付
        GameData.IsShowInviteBtn = message:PopByte()
        -- 是否显示邀请码按钮
        GameData.ChannelCode = message:PopByte()
        -- 注册初始渠道反馈
        GameData.ConfirmChannelCode = true

        print("服务器发的是否绑定账号 = " .. tostring(GameData.RoleInfo.IsBindAccount))
        print("服务器发的是否开启苹果支付 = " .. tostring(GameData.IsOpenApplePay))
        print("服务器发的是否显示邀请码按钮 = " .. tostring(GameData.IsShowInviteBtn))
        print("服务器发的注册渠道ID = " .. tostring(GameData.ChannelCode))
        if IsAutoConnect then
            -- 如果房间号不为0，并且切出时间符合要求，发送请求进入房间协议
            -- print("悄悄登陆")
            print("roomid = " .. GameData.RoomInfo.CurrentRoom.RoomID .. "cut out time" .. CutOutTime)
            if GameData.RoomInfo.CurrentRoom.RoomID ~= 0 and CutOutTime <= data.PublicConfig.CUT_OUT_CAN_ENTER_ROOM_TIME then
                print("cut in 自动进入房间")
                NetMsgHandler.Send_CS_Enter_Room(GameData.RoomInfo.CurrentRoom.RoomID)
            else
                NetMsgHandler.ExitRoomToHall(3)
                IsAutoConnect = false
            end
            -- 若是在大厅UI则刷新UI
            local hallUI = CS.WindowManager.Instance:FindWindowNodeByName("HallUI")
            if hallUI ~= nil then
                hallUI.WindowData = 1
            end
            -- 断线重连之后 发现有未读邮件 主动请求一次邮件数据
            if unreademailNum > 0 then
                NetMsgHandler.SendRequestEmails(0)
                EmailMgr:ClearAll()
            end

        else
            -- 打开HallUI，关闭登陆界面
            -- print("正常登陆")
            openparam = CS.WindowNodeInitParam('HallUI')
            openparam.NodeType = 0
            openparam.LoadComplatedCallBack =
            function(windowNode)
                CS.WindowManager.Instance:CloseWindow('UILogin', false)
            end
            CS.WindowManager.Instance:OpenWindow(openparam)

            -- 初次登陆进入
            MusicMgr:PlaySoundEffect(44)
            -- 切换状态为大厅
            GameData.GameState = GAME_STATE.HALL

        end

        -- 处理本地缓存的待发送消息
        print("处理本地缓存的待发送消息 个数为 = " .. SaveMsgList:length())
        while (SaveMsgList:length() > 0) do
            local msgStruct = SaveMsgList:pop()
            NetMsgHandler.SendMessageToGame(msgStruct.pretocalID, msgStruct.message, msgStruct.pretocalID)
        end

    elseif resultType == 1 then
        -- 在线人数达到上限
        CS.BubblePrompt.Show("服务器已满!", "UILogin")
        loginNetClient:ShutDown()
        NetMsgHandler.ReturnLogin()

    elseif resultType == 2 then
        -- 账号被冻结
        local suspendedTime = message:PopString()
        CS.BubblePrompt.Show("你的账号被冻结，无法登陆!", "UILogin")
        loginNetClient:ShutDown()
        NetMsgHandler.ReturnLogin()
    else
        -- 未处理的失败原因
        print('UnHandle fail reason: ' .. resultType)
        loginNetClient:ShutDown()
        NetMsgHandler.ReturnLogin()
    end

    if LoginMgr.lastLoginType == PLATFORM_TYPE.PLATFORM_WEIXIN then
        -- 微信登录
        PlatformBridge:CallFunc(PLATFORM_TYPE.PLATFORM_WEIXIN, PLATFORM_FUNCTION_ENUM.PLATFORM_FUNCTION_LOGIN_SUCCESS, GameData.LoginInfo.Account)
    else
        -- 游客登录
        PlatformBridge:CallFunc(PLATFORM_TYPE.PLATFORM_TOURISTS, PLATFORM_FUNCTION_ENUM.PLATFORM_FUNCTION_LOGIN_SUCCESS, GameData.LoginInfo.Account)
    end

end



---------------------------------------------------------------------------
------------------------------S_Disconnect  201----------------------------

-- 处理收到服务器 断开连接 消息
function NetMsgHandler.HandleReceivedDisconnect(message)
    local reason = message:PopByte()
    NetMsgHandler.CloseConnect()
    NetMsgHandler.ReturnLogin()
    LoginMgr.isChangeAccount = 1
    CS.BubblePrompt.Show(data.GetString("DISCONNECT_ERROR_" .. reason), "UILogin")
end

---------------------------------------------------------------------------
----------------------------S_Update_Diamond  203--------------------------
-- 处理收到服务器 更新钻石 消息
function NetMsgHandler.HandleReceivedUpdateDiamond(message)
    local diamondCount = message:PopInt64()
    local reason = message:PopByte()
    local changedValue = diamondCount - GameData.RoleInfo.DiamondCount
    if changedValue > 0 then
        if reason == 3 then
            -- 充值成功获得钻石
            CS.BubblePrompt.Show(string.format(data.GetString("Rechare_Diamond_Tips"), changedValue), "UIStore")
        else
            -- 其他原因获得钻石
            CS.BubblePrompt.Show(string.format(data.GetString("Get_Diamond_Tips"), changedValue), "UIStore")
        end
    end
    GameData.RoleInfo.DiamondCount = diamondCount
end

---------------------------------------------------------------------------
------------------------------S_Update_Gold  204---------------------------
-- 处理收到服务器 更新金币 消息
function NetMsgHandler.HandleReceivedUpdateGold(message)
    local goldCount = message:PopInt64()
    local reason = message:PopByte()
    GameData.UpdateGoldCount(goldCount, reason)
end

---------------------------------------------------------------------------
----------------------------S_Update_FreeGold  205-------------------------
-- 处理收到服务器 更新免费金币 消息
function NetMsgHandler.HandleReceivedUpdateFreeGold(message)
    local freeGoldCount = message:PopInt64()
    local reason = message:PopByte()
    GameData.RoleInfo.FreePlayTimes = message:PopSByte()
    GameData.UpdateFreeGoldCount(freeGoldCount, reason)
end

---------------------------------------------------------------------------
----------------------------S_Update_RoomCard  206-------------------------
-- 处理收到服务器 更新房卡 消息
function NetMsgHandler.HandleReceivedUpdateRoomCard(message)
    local roomCardCount = message:PopUInt32()
    GameData.RoleInfo.RoomCardCount = roomCardCount
end

---------------------------------------------------------------------------
-----------------------------S_Update_Charge  207--------------------------
-- 处理收到服务器 更新充值人民币 消息
function NetMsgHandler.HandleReceivedUpdateCharge(message)
    GameData.RoleInfo.ChargeCount = message:PopUInt32()
    GameData.RoleInfo.VipLevel = message:PopByte()

    local masterInfoUI = CS.WindowManager.Instance:FindWindowNodeByName("PlayerInfoUI")
    if masterInfoUI ~= nil then
        masterInfoUI.WindowData = 2
    end
end

---------------------------------------------------------------------------
---------------------------CS_Convert_Gold  208----------------------------
-- 发送兑换金币消息
function NetMsgHandler.SendConvertGoldMessage(diamondNumber)
    local message = CS.Net.PushMessage()
    message:PushUInt32(GameData.RoleInfo.AccountID)
    message:PushUInt64(diamondNumber)
    print('Convert gold:' .. GameData.RoleInfo.AccountID .. '   ' .. diamondNumber)
    NetMsgHandler.SendMessageToGame(ProtrocolID.CS_Convert_Gold, message, true)
end

-- 处理收到服务器 兑换金币 消息
function NetMsgHandler.HandleReceivedConvertGoldResult(message)
    local resultType = message:PopByte()
    print("兑换金币返回值" .. resultType)
    if resultType == 0 then
        local gold = message:PopUInt64()
        print("=====Gold:" .. gold)
        CS.BubblePrompt.Show(string.format(data.GetString("Convert_Gold_Success"), lua_CommaSeperate(GameConfig.GetFormatColdNumber(gold))), "UIConvert")
    end
    CS.LoadingDataUI.Hide()
end

---------------------------------------------------------------------------
-------------------------CS_Convert_RoomCard  209--------------------------
-- 发送兑换房卡消息
function NetMsgHandler.SendConvertRoomCardMessage(roomCardNumber)
    local message = CS.Net.PushMessage();
    message:PushUInt32(GameData.RoleInfo.AccountID);
    message:PushUInt32(roomCardNumber);
    NetMsgHandler.SendMessageToGame(ProtrocolID.CS_Convert_RoomCard, message, true);
end

-- 处理收到服务器 兑换房卡 消息
function NetMsgHandler.HandleReceivedConvertRoomCardResult(message)
    local resultType = message:PopByte();
    if resultType == 0 then
        local fangka = message:PopUInt32()
        CS.BubblePrompt.Show(string.format(data.GetString("Convert_FangKa_Success"), fangka), "UIConvert")
    end
    CS.LoadingDataUI.Hide();
end


function NetMsgHandler.SendBindAccount(openid, name)
    local message = CS.Net.PushMessage()
    message:PushUInt32(GameData.RoleInfo.AccountID)
    -- 玩家账号
    message:PushString(openid)
    message:PushString(name)
    NetMsgHandler.SendMessageToGame(ProtrocolID.CS_BIND_ACCOUNT, message, false)
end

function NetMsgHandler.SaveBindAccountMsg(openid, name)
    local saveMsgStruct = { }
    local message = CS.Net.PushMessage()
    message:PushUInt32(GameData.RoleInfo.AccountID)
    -- 玩家账号
    message:PushString(openid)
    message:PushString(name)
    saveMsgStruct.message = message
    saveMsgStruct.pretocalID = ProtrocolID.CS_BIND_ACCOUNT
    saveMsgStruct.isShowLoadingUI = false
    SaveMsgList:push(saveMsgStruct)
end

function NetMsgHandler.OnServerBindAccountResult(message)
    CS.LoadingDataUI.Hide()
    local nType = message:PopByte()
    print('绑定结果 nType = ' .. nType)
    if nType == 0 then
        CS.BubblePrompt.Show("绑定成功", "UISetting")
        GameData.RoleInfo.IsBindAccount = true
        GameData.RoleInfo.AccountName = LoginMgr.bindName
        CS.EventDispatcher.Instance:TriggerEvent(EventDefine.NotifyChangeAccountName, nil)
    elseif nType == 3 or nType == 2 then
        CS.BubblePrompt.Show("此微信账号已被绑定", "UISetting")
    else
        CS.BubblePrompt.Show("绑定失败", "UISetting")
    end
end
---------------------------------------------------------------------------
-----------------S_Notify_Wait_State  352----------------------------------
function NetMsgHandler.Received_S_Notify_Wait_State(message)
    GameData.ClearCurrentRoundData()
    GameData.SetRoomState(ROOM_STATE.WAIT)
end


---------------------------------------------------------------------------
-----------------S_Notify_Shuffle_State  353-------------------------------
function NetMsgHandler.Received_S_Notify_Shuffle_State(message)
    GameData.SetRoomState(ROOM_STATE.SHUFFLE)
end

---------------------------------------------------------------------------
-----------------S_Notify_Cut_State  354-----------------------------------
function NetMsgHandler.Received_S_Notify_Cut_State(message)
    -- print('354')
    GameData.SetRoomState(ROOM_STATE.CUT)
end

---------------------------------------------------------------------------
-----------------S_Notify_Wait_State  355----------------------------------
function NetMsgHandler.Received_S_Notify_Play_Cut_State(message)
    -- print('355')
    local cutResult = message:PopByte()
    -- print('服务器通知切牌结果', cutResult)
    if cutResult > 32 then
        cutResult = 32
    end

    GameData.RoomInfo.CurrentRoom.CutAniIndex = cutResult

    GameData.SetRoomState(ROOM_STATE.CUTANI)
end

---------------------------------------------------------------------------
-----------------S_Notify_Bet_State  356-----------------------------------
function NetMsgHandler.Received_S_Notify_Bet_State(message)
    GameData.SetRoomState(ROOM_STATE.BET)
end

---------------------------------------------------------------------------
-----------------S_Notify_Deal_State  357----------------------------------
function NetMsgHandler.Received_S_Notify_Deal_State(message)
    NetMsgHandler.ParseAndSetPokerCards(message, 6)

    GameData.SetRoomState(ROOM_STATE.DEAL)
end

---------------------------------------------------------------------------
-----------------S_Notify_Long_Check_State  358----------------------------
function NetMsgHandler.Received_S_Notify_Long_Check_State(message)
    GameData.SetRoomState(ROOM_STATE.CHECK1)
end

---------------------------------------------------------------------------
-----------------S_Notify_Hu_Check_State  359------------------------------
function NetMsgHandler.Received_S_Notify_Hu_Check_State(message)
    GameData.SetRoomState(ROOM_STATE.CHECK2)
end

---------------------------------------------------------------------------
-----------------S_Notify_Settlement_State  360----------------------------
function NetMsgHandler.Received_S_Notify_Settlement_State(message)
    GameData.RoomInfo.CurrentRoom.GameResult = message:PopByte()
    GameData.SetRoomState(ROOM_STATE.SETTLEMENT)
end

---------------------------------------------------------------------------
-----------------S_Notify_Check1_Over  361---------------------------------
function NetMsgHandler.Received_S_Notify_Check1_Over(message)
    NetMsgHandler.SetRoleCardCurrentState(1, 4, GameData.RoomInfo.CurrentRoom.CheckRole1.ID > 0)
    GameData.SetRoomState(ROOM_STATE.CHECK1OVER)
end

---------------------------------------------------------------------------
-----------------S_Notify_Check2_Over  362---------------------------------
function NetMsgHandler.Received_S_Notify_Check2_Over(message)
    NetMsgHandler.SetRoleCardCurrentState(2, 4, GameData.RoomInfo.CurrentRoom.CheckRole2.ID > 0)
    GameData.SetRoomState(ROOM_STATE.CHECK2OVER)
end

---------------------------------------------------------------------------
-----------------CS_Enter_Room  400----------------------------------------
function NetMsgHandler.Send_CS_Enter_Room(roomID)
    local message = CS.Net.PushMessage()
    message:PushUInt32(GameData.RoleInfo.AccountID)
    message:PushUInt32(roomID)
    NetMsgHandler.SendMessageToGame(ProtrocolID.CS_Enter_Room, message, true)
end

function NetMsgHandler.Received_CS_Enter_Room(message)
    CS.LoadingDataUI.Hide()
    local resultType = message:PopByte()
    if resultType == 0 then
        -- 成功需要在发送消息结束后关闭数据加载框

        if IsAutoConnect then
            -- 断线自动登录流程
            -- print("悄悄进房间")
            local roomID = message:PopUInt32()
            if roomID ~= GameData.RoomInfo.CurrentRoom.RoomID then
                return
            end
            IsAutoConnect = false
        else
            -- 正常流程
            -- print("正常进房间")
            GameData.InitCurrentRoomInfo(ROOM_TYPE.JH_JuLong)
            GameData.RoomInfo.CurrentRoom.RoomID = message:PopUInt32()
            GameData.RoomInfo.CurrentRoom.TemplateID = message:PopByte()

            local openparam = CS.WindowNodeInitParam("GameUI2")
            openparam.NodeType = 0
            openparam.LoadComplatedCallBack = function(windowNode)
                CS.WindowManager.Instance:CloseWindow("HallUI", false)
                NetMsgHandler.ShowFreeRoomEnterMessageBox()
            end

            CS.WindowManager.Instance:OpenWindow(openparam)

            -- 切换状态为房间
            GameData.GameState = GAME_STATE.ROOM

        end

    else
        CS.BubblePrompt.Show(data.GetString("Enter_Room_Error_" .. resultType), "HallUI")
    end
end

function NetMsgHandler.ShowFreeRoomEnterMessageBox()
    local roomConfig = data.RoomConfig[GameData.RoomInfo.CurrentRoom.TemplateID]
    if roomConfig ~= nil then
        if roomConfig.Type == 2 then
            local boxData = CS.MessageBoxData()
            boxData.Title = "提示"
            boxData.Content = data.GetString("Tip_Enter_Free_Room")
            boxData.Style = 1
            -- boxData.LastTime = 3
            local parentWindow = CS.WindowManager.Instance:FindWindowNodeByName("GameUI2")
            CS.MessageBoxUI.Show(boxData, parentWindow)
        end
    end
end

---------------------------------------------------------------------------
-----------------CS_Exit_Room  401-----------------------------------------
function NetMsgHandler.Send_CS_Exit_Room(handleType)
    local message = CS.Net.PushMessage()
    message:PushUInt32(GameData.RoleInfo.AccountID)
    message:PushByte(handleType)
    NetMsgHandler.SendMessageToGame(ProtrocolID.CS_Exit_Room, message, false)
end

function NetMsgHandler.Received_CS_Exit_Room(message)
    local resultType = message:PopByte()
    local handleType = message:PopByte()
    if resultType == 0 then
        NetMsgHandler.ExitRoomToHall(handleType)
    else
        -- CS.BubblePrompt.Show(data.GetString("Exit_Room_Error_".. resultType), "GameUI2")
    end
end

function NetMsgHandler.ExitRoomToHall(handleType)
    if GameData.GameState == GAME_STATE.HALL then
        -- 如果当前已经是房间状态，直接返回
        return
    end

    -- 打开大厅界面，关闭游戏界面
    local openparam = CS.WindowNodeInitParam("HallUI")
    openparam.NodeType = 0
    openparam.LoadComplatedCallBack =
    function(windowNode)
        -- 清理掉房间的数据
        GameData.InitCurrentRoomInfo(ROOM_TYPE.JH_JuLong)
        -- 清理掉GameUI 里的提示信息
        CS.BubblePrompt.ClearPrompt("GameUI2")
        CS.WindowManager.Instance:CloseWindow("GameUI2", false)
        CS.WindowManager.Instance:CloseWindow("GameUI1", false)
        if handleType == 2 then
            CS.BubblePrompt.Show(data.GetString("Tip_Exit_Room_2"), "HallUI")
        end
    end
    CS.WindowManager.Instance:OpenWindow(openparam)

    -- 切换状态为大厅
    GameData.GameState = GAME_STATE.HALL
end
---------------------------------------------------------------------------
-----------------CS_Create_Room  402---------------------------------------
function NetMsgHandler.Send_CS_Create_Room(roomType, roomCount)
    local message = CS.Net.PushMessage();
    message:PushUInt32(GameData.RoleInfo.AccountID);
    message:PushByte(roomType);
    message:PushByte(roomCount);
    print('send create room :' .. roomType .. '  ' .. roomCount);
    NetMsgHandler.SendMessageToGame(ProtrocolID.CS_Create_Room, message, true);
end

function NetMsgHandler.Received_CS_Create_Room(message)
    local resultType = message:PopByte();
    if resultType == 0 then
        local roomID = message:PopUInt32();
        -- 关闭创建房间界面，发送进入房间消息
        CS.WindowManager.Instance:CloseWindow("UICreateRoom", false)
        NetMsgHandler.Send_CS_Enter_Room(roomID);
    else
        CS.LoadingDataUI.Hide();
        CS.BubblePrompt.Show(data.GetString("Create_Room_Error_" .. resultType), "UICreateRoom")
    end
end

---------------------------------------------------------------------------
------------------------------CS_Bet  403----------------------------------
-- 押注区域被点击了
function NetMsgHandler.Send_CS_Bet(areaType, betValue)
    local message = CS.Net.PushMessage()
    message:PushUInt32(GameData.RoleInfo.AccountID)
    message:PushByte(areaType)
    message:PushUInt32(betValue)
    NetMsgHandler.SendMessageToGame(ProtrocolID.CS_Bet, message, false)
end

-- 处理收到服务器 押注结果 消息
function NetMsgHandler.Received_CS_Bet(message)
    local resultType = message:PopByte()
    local roleID = message:PopUInt32()
    local areaType = message:PopByte()
    local betValue = message:PopUInt32()
    if resultType == 0 then
        local eventArg = 1
        if (roleID == GameData.RoleInfo.AccountID) then
            if GameData.RoomInfo.CurrentRoom.BetValues[areaType] == nil then
                GameData.RoomInfo.CurrentRoom.BetValues[areaType] = 0
            end
            GameData.RoomInfo.CurrentRoom.BetValues[areaType] = GameData.RoomInfo.CurrentRoom.BetValues[areaType] + betValue
            eventArg = 2
        end

        if GameData.RoomInfo.CurrentRoom.TotalBetValues[areaType] == nil then
            GameData.RoomInfo.CurrentRoom.TotalBetValues[areaType] = 0
        end

        GameData.RoomInfo.CurrentRoom.TotalBetValues[areaType] = GameData.RoomInfo.CurrentRoom.TotalBetValues[areaType] + betValue
        CS.EventDispatcher.Instance:TriggerEvent(EventDefine.UpdateBetValue, eventArg)
    end

    local betChipEventArg = { RoleID = roleID, AreaType = areaType, BetValue = betValue, ResultType = resultType }
    -- 调用下注结果
    CS.EventDispatcher.Instance:TriggerEvent(EventDefine.NotifyBetResult, betChipEventArg)

end

---------------------------------------------------------------------------
-----------------CS_Check_Card_Process  404--------------------------------
function NetMsgHandler.Send_CS_Check_Card_Process(pokerIndex, isRotate, flipMode, moveX, moveY)
    local message = CS.Net.PushMessage()
    message:PushUInt32(GameData.RoleInfo.AccountID)
    message:PushByte(pokerIndex)
    if isRotate then
        message:PushByte(1)
    else
        message:PushByte(0)
    end
    message:PushByte(flipMode)
    message:PushFloat(moveX)
    message:PushFloat(moveY)
    NetMsgHandler.SendMessageToGame(ProtrocolID.CS_Check_Card_Process, message, false)
end

function NetMsgHandler.Received_CS_Check_Card_Process(message)
    local eventArg = lua_NewTable(HandlePokerEventArgs)

    eventArg.HandlerID = message:PopUInt32()
    eventArg.PokerIndex = message:PopByte()
    eventArg.IsRotate = message:PopByte() == 1
    eventArg.FlipMode = message:PopByte()
    eventArg.MoveX = message:PopFloat()
    eventArg.MoveY = message:PopFloat()
    print('MoveX: ' .. eventArg.MoveX .. 'MoveY: ' .. eventArg.MoveY)
    CS.EventDispatcher.Instance:TriggerEvent(EventDefine.UpdateHandlePoker, eventArg)
end

---------------------------------------------------------------------------
-----------------CS_Checked_Card  405--------------------------------------
-- cardIndex : 2,3 表示第几张牌，如果 4，表示
function NetMsgHandler.Send_CS_Checked_Card(cardIndex)
    local message = CS.Net.PushMessage()
    message:PushUInt32(GameData.RoleInfo.AccountID)
    message:PushByte(cardIndex)
    NetMsgHandler.SendMessageToGame(ProtrocolID.CS_Checked_Card, message, false)
end

function NetMsgHandler.Received_CS_Checked_Card(message)
    local resultType = message:PopByte()
    if resultType == 0 then
        local roleType = message:PopByte()
        local cardIndex = message:PopByte()
        NetMsgHandler.SetRoleCardCurrentState(roleType, cardIndex, true)
    else
        CS.BubblePrompt.Show(data.GetString("Checked_Card_Error_" .. resultType), "GameUI2")
    end

end

---------------------------------------------------------------------------
-----------------S_Bet_Rank_List  406--------------------------------------
-- 处理收到服务器 押注 排行榜
function NetMsgHandler.Received_S_Bet_Rank_List(message)
    local area4 = { }
    -- 押龙排行榜
    local area5 = { }
    -- 押虎排行榜
    local area4RankCount = message:PopUInt16()
    for i = 1, area4RankCount, 1 do
        area4[i] = { }
        area4[i].ID = message:PopUInt32()
        area4[i].Name = message:PopString()
        area4[i].Value = message:PopInt64()
        area4[i].HeadIcon = message:PopByte()
    end

    local area5RankCount = message:PopUInt16()
    for i = 1, area5RankCount, 1 do
        area5[i] = { }
        area5[i].ID = message:PopUInt32()
        area5[i].Name = message:PopString()
        area5[i].Value = message:PopInt64()
        area5[i].HeadIcon = message:PopByte()
    end

    GameData.RoomInfo.CurrentRoom.BetRankList[4] = area4
    GameData.RoomInfo.CurrentRoom.BetRankList[5] = area5

    CS.EventDispatcher.Instance:TriggerEvent(EventDefine.UpdateBetRankList, nil)
end

---------------------------------------------------------------------------
-----------------CS_Request_Statistics  407--------------------------------
function NetMsgHandler.Send_CS_Request_Statistics(...)
    local length = select('#', ...)
    if length > 0 then
        local message = CS.Net.PushMessage()
        message:PushUInt16(length)
        -- 写入长度
        for i = 1, length do
            local roomID = select(i, ...)
            message:PushUInt32(roomID)
        end
        NetMsgHandler.SendMessageToGame(ProtrocolID.CS_Request_Statistics, message, false)
    end
end


function NetMsgHandler.Received_CS_Request_Statistics(message)
    local count = message:PopUInt16()
    local currentTime = CS.UnityEngine.Time.realtimeSinceStartup
    for i = 1, count, 1 do
        -- 解析统计信息
        local statistics = NetMsgHandler.ParseOneRoomStatisticsInfo(message)
        -- 设置其他信息 房间最大局数，房间内的人数，数据请求的时间
        statistics.Round.MaxRound = message:PopByte()
        statistics.Counts.RoleCount = message:PopUInt16()
        statistics.Time = currentTime

        GameData.RoomInfo.StatisticsInfo[statistics.RoomID] = statistics

        local eventArgs = { RoomID = statistics.RoomID, OperationType = 0 }
        CS.EventDispatcher.Instance:TriggerEvent(EventDefine.UpdateStatistics, eventArgs)
    end
end

function NetMsgHandler.ParseOneRoomStatisticsInfo(message)

    local statistics = NetMsgHandler.NewStatisticsInfo()
    statistics.RoomID = message:PopUInt32()
    local roundCount = message:PopUInt16()
    for round = 1, roundCount, 1 do
        table.insert(statistics.Trend, message:PopByte())
    end

    NetMsgHandler.ParseOneRoomStatisticsCounts(message, statistics.Counts)
    statistics.Round.CurrentRound = message:PopByte()
    return statistics
end

-- 返回一个房间的牌型数量统计
function NetMsgHandler.ParseOneRoomStatisticsCounts(message, counts)
    counts.LongWin = message:PopByte()
    counts.HuWin = message:PopByte()
    counts.HeJu = message:PopByte()

    counts.LongJinHua = message:PopByte()
    counts.HuJinHua = message:PopByte()
    counts.LongHuBaoZi = message:PopByte()
end

---------------------------------------------------------------------------
-----------------S_Room_Statistics  408------------------------------------
-- 返回全部统计信息
function NetMsgHandler.Received_S_Room_Statistics(message)
    local statistics = NetMsgHandler.ParseOneRoomStatisticsInfo(message)
    statistics.Round.MaxRound = GameData.RoomInfo.CurrentRoom.MaxRound
    if statistics.Round.CurrentRound == statistics.Round.MaxRound then
        statistics.ClearFlag = true
    end
    statistics.Time = CS.UnityEngine.Time.realtimeSinceStartup
    GameData.RoomInfo.StatisticsInfo[statistics.RoomID] = statistics
    local eventArgs = { RoomID = statistics.RoomID, OperationType = 0 }
    CS.EventDispatcher.Instance:TriggerEvent(EventDefine.UpdateStatistics, eventArgs)
end

---------------------------------------------------------------------------
-----------------S_Room_Append_Statistics  409-----------------------------
function NetMsgHandler.Received_S_Room_Append_Statistics(message)
    local roomID = message:PopUInt32()
    local currentRoomID = GameData.RoomInfo.CurrentRoom.RoomID
    if roomID ~= currentRoomID then
        return
    end

    local statistics = GameData.RoomInfo.StatisticsInfo[currentRoomID]
    local eventArgs = { RoomID = roomID, OperationType = 1 }
    if statistics.ClearFlag == true then
        statistics = NetMsgHandler.NewStatisticsInfo()
        statistics.RoomID = currentRoomID
        GameData.RoomInfo.StatisticsInfo[currentRoomID] = statistics
        eventArgs.OperationType = 0
    end

    statistics.Time = CS.UnityEngine.Time.realtimeSinceStartup

    table.insert(statistics.Trend, message:PopByte())
    NetMsgHandler.ParseOneRoomStatisticsCounts(message, statistics.Counts)
    statistics.Round.CurrentRound = message:PopByte()

    if statistics.Round.CurrentRound == statistics.Round.MaxRound then
        statistics.ClearFlag = true
    end

    GameData.RoomInfo.CurrentRoom.AppendStatisticsEventArgs = eventArgs
end

function NetMsgHandler.NewStatisticsInfo()
    local statistics = { }
    statistics.RoomID = 0
    statistics.Trend = { }
    statistics.Counts = { LongWin = 0, HuWin = 0, HeJu = 0, LongJinHua = 0, HuJinHua = 0, LongHuBaoZi = 0, RoleCount = 0 }
    statistics.Round = { CurrentRound = 0, MaxRound = 0 }
    statistics.ClearFlag = false
    return statistics
end

---------------------------------------------------------------------------
-----------------CS_Request_Relative_Room  410-----------------------------
function NetMsgHandler.Send_CS_Request_Relative_Room()
    local message = CS.Net.PushMessage()
    message:PushUInt32(GameData.RoleInfo.AccountID)
    NetMsgHandler.SendMessageToGame(ProtrocolID.CS_Request_Relative_Room, message, true)
end

function NetMsgHandler.Received_CS_Request_Relative_Room(message)
    CS.LoadingDataUI.Hide()
    local resultType = message:PopByte()
    if resultType == 0 then
        -- 成功
        local count = message:PopUInt16()
        GameData.RoomInfo.RelationRooms = { }
        for i = 1, count, 1 do
            local roomID = message:PopUInt32()
            local masterName = message:PopString()
            GameData.RoomInfo.RelationRooms[roomID] = masterName
        end
    else
        print('--账号不存在--')
    end
end

---------------------------------------------------------------------------
-----------------S_Set_Bet_First  411--------------------------------------
function NetMsgHandler.Received_S_Set_Bet_First(message)
    NetMsgHandler.ParseAndSetBetRankFirst(message)
    CS.EventDispatcher.Instance:TriggerEvent(EventDefine.NotifyBetEnd, nil)
end

---------------------------------------------------------------------------
-----------------S_Set_Game_Data  412--------------------------------------
function NetMsgHandler.Received_S_Set_Game_Data(message)
    -- Home 出去 再切换回来时也会调用此接口，重新初始化房间信息
    GameData.InitCurrentRoomInfo(ROOM_TYPE.JH_JuLong)
    -- 解析房间的基本信息
    GameData.RoomInfo.CurrentRoom.RoomID = message:PopUInt32()
    GameData.RoomInfo.CurrentRoom.TemplateID = message:PopByte()
    GameData.RoomInfo.CurrentRoom.MasterID = message:PopUInt32()
    GameData.RoomInfo.CurrentRoom.MaxRound = message:PopByte()
    GameData.RoomInfo.CurrentRoom.CurrentRound = message:PopByte()
    GameData.RoomInfo.CurrentRoom.RoomState = message:PopByte()
    GameData.RoomInfo.CurrentRoom.CountDown = message:PopUInt32() / 1000.0
    local roomConfig = data.RoomConfig[GameData.RoomInfo.CurrentRoom.TemplateID]
    if roomConfig ~= nil then
        GameData.RoomInfo.CurrentRoom.IsFreeRoom = roomConfig.Type == 2
        GameData.RoomInfo.CurrentRoom.IsVipRoom = roomConfig.Type == 3
    end

    -- 解压个人押注信息
    NetMsgHandler.ParseAndSetBetValue(message)
    -- 解压总押注信息
    NetMsgHandler.ParseAndSetTotalBetValue(message)

    CS.EventDispatcher.Instance:TriggerEvent(EventDefine.UpdateBetValue, 3)

    -- 解析已押注到押注区域的筹码信息
    NetMsgHandler.ParseAndSetChipsOnBetAreas(message)

    -- 解析庄家信息
    NetMsgHandler.ParseAndSetBankerInfo(message)

    -- 解析扑克牌
    local cardCount = message:PopUInt16()
    NetMsgHandler.ParseAndSetPokerCards(message, cardCount)
    -- 解析扑克牌状态
    NetMsgHandler.SetRoleCardCurrentState(1, message:PopByte(), false)
    NetMsgHandler.SetRoleCardCurrentState(2, message:PopByte(), false)
    -- 解析游戏结果
    GameData.RoomInfo.CurrentRoom.GameResult = message:PopByte()
    -- 押注排行榜第一名信息
    NetMsgHandler.ParseAndSetBetRankFirst(message)

    CS.EventDispatcher.Instance:TriggerEvent(EventDefine.InitRoomState, GameData.RoomInfo.CurrentRoom.RoomState)
end

-- 解析自身押注信息
function NetMsgHandler.ParseAndSetBetValue(message)
    local betCount = message:PopUInt16()
    if betCount > 0 then
        for index = 1, betCount, 1 do
            local betArea = message:PopByte()
            local betValue = message:PopInt64()
            GameData.RoomInfo.CurrentRoom.BetValues[betArea] = betValue
        end
    end
end

-- 解析总押注信息
function NetMsgHandler.ParseAndSetTotalBetValue(message)
    local totalBetCount = message:PopUInt16()
    if totalBetCount > 0 then
        for index = 1, totalBetCount, 1 do
            local totalBetArea = message:PopByte()
            local totalBetValue = message:PopInt64()
            GameData.RoomInfo.CurrentRoom.TotalBetValues[totalBetArea] = totalBetValue
        end
    end
end

-- 解析押注区域已经存在的筹码信息
function NetMsgHandler.ParseAndSetChipsOnBetAreas(message)
    -- 解析桌面上已有的筹码面值和数量
    local count = message:PopUInt16()
    local currentRoomChips = { }
    for index = 1, count, 1 do
        local betArea = message:PopByte()
        local chipValue = message:PopUInt32()
        local chipCount = message:PopUInt32()
        local betAreaInfo = currentRoomChips[betArea]
        if betAreaInfo == nil then
            betAreaInfo = { }
            currentRoomChips[betArea] = betAreaInfo
        end

        local chipInfo = betAreaInfo[chipValue]
        if chipInfo == nil then
            chipInfo = { }
            betAreaInfo[chipValue] = chipInfo
        end
        chipInfo.Count = chipCount
    end
    GameData.RoomInfo.CurrentRoomChips = currentRoomChips
end

-- 解析设置庄家信息
function NetMsgHandler.ParseAndSetBankerInfo(message)
    if GameData.RoomInfo.CurrentRoom.BankerInfo == nil then
        GameData.RoomInfo.CurrentRoom.BankerInfo = { }
    end
    GameData.RoomInfo.CurrentRoom.BankerInfo.ID = message:PopUInt32()
    GameData.RoomInfo.CurrentRoom.BankerInfo.Name = message:PopString()
    GameData.RoomInfo.CurrentRoom.BankerInfo.Gold = message:PopInt64()
    GameData.RoomInfo.CurrentRoom.BankerInfo.LeftCount = message:PopByte()
    -- 庄家剩余局数
    GameData.RoomInfo.CurrentRoom.BankerInfo.HeadIcon = message:PopByte()
    -- 头像ID
    GameData.RoomInfo.CurrentRoom.BankerInfo.IsLastForceDownBanker = message:PopByte() == 1
    -- 上一个庄家是否被强制下庄
end

-- 解析收到的扑克牌
function NetMsgHandler.ParseAndSetPokerCards(message, count)
    for index = 1, count, 1 do
        GameData.RoomInfo.CurrentRoom.Pokers[index] = { }
        local pokerType = message:PopByte()
        local pokerNumber = message:PopByte()
        GameData.RoomInfo.CurrentRoom.Pokers[index].PokerType = pokerType
        GameData.RoomInfo.CurrentRoom.Pokers[index].PokerNumber = pokerNumber
        GameData.RoomInfo.CurrentRoom.Pokers[index].Visible =(index % 3 == 1)
        -- 第一张可见其它不可见
    end
end

-- 设置角色扑克牌的当前状态标志
function NetMsgHandler.SetRoleCardCurrentState(roleType, cardState, isNotify)
    local cardIndex1 = 1
    local cardIndex2 = 2
    local cardIndex3 = 3
    if roleType == 2 then
        cardIndex1 = 4
        cardIndex2 = 5
        cardIndex3 = 6
    end
    if GameData.RoomInfo.CurrentRoom.Pokers ~= nil and #GameData.RoomInfo.CurrentRoom.Pokers > 0 then
        NetMsgHandler.ResetPokerCardVisible(cardIndex1, true, isNotify)
        NetMsgHandler.ResetPokerCardVisible(cardIndex2,(cardState == 2 or cardState == 4), isNotify)
        NetMsgHandler.ResetPokerCardVisible(cardIndex3,(cardState == 3 or cardState == 4), isNotify)
    end
end

function NetMsgHandler.ResetPokerCardVisible(cardIndex, visible, isNotify)
    if GameData.RoomInfo.CurrentRoom.Pokers[cardIndex].Visible ~= visible then
        GameData.RoomInfo.CurrentRoom.Pokers[cardIndex].Visible = visible
        if isNotify then
            CS.EventDispatcher.Instance:TriggerEvent(EventDefine.PokerVisibleChanged, cardIndex)
        end
    end
end

-- 解析设置押注排行第一信息
function NetMsgHandler.ParseAndSetBetRankFirst(message)
    GameData.RoomInfo.CurrentRoom.CheckRole1.ID = message:PopUInt32()
    GameData.RoomInfo.CurrentRoom.CheckRole1.Name = message:PopString()
    local longIcon = message:PopByte()
    -- 龙头像
    GameData.RoomInfo.CurrentRoom.CheckRole1.Icon = longIcon
    GameData.RoomInfo.CurrentRoom.CheckRole2.ID = message:PopUInt32()
    GameData.RoomInfo.CurrentRoom.CheckRole2.Name = message:PopString()
    local huIcon = message:PopByte()
    -- 虎头像
    GameData.RoomInfo.CurrentRoom.CheckRole2.Icon = huIcon
end

---------------------------------------------------------------------------
-----------------CS_Vip_Start_Game  413------------------------------------
function NetMsgHandler.Send_CS_Vip_Start_Game()
    local message = CS.Net.PushMessage();
    message:PushUInt32(GameData.RoleInfo.AccountID);
    NetMsgHandler.SendMessageToGame(ProtrocolID.CS_Vip_Start_Game, message, false);
end

function NetMsgHandler.Received_CS_Vip_Start_Game(message)
    local resultType = message:PopByte()
    -- 策划新需求 #58 【提示优化】
    if resultType ~= 3 and resultType ~= 4 then
        CS.BubblePrompt.Show(data.GetString("Start_Game_Error_" .. resultType), "GameUI2");
    end
end

---------------------------------------------------------------------------
-----------------S_Notify_Game_End  414------------------------------------
function NetMsgHandler.Received_S_Notify_Game_End(message)
    GameData.SetRoomState(ROOM_STATE.WAIT)
    CS.EventDispatcher.Instance:TriggerEvent(EventDefine.NotifyEndGame, true)
end

---------------------------------------------------------------------------
-----------------CS_Request_Continue_Game  415-----------------------------
function NetMsgHandler.Send_CS_Request_Continue_Game(message)
    print("CS_Request_Continue_Game");
end

function NetMsgHandler.Received_CS_Request_Continue_Game(message)
    print("CS_Request_Continue_Game");
end

---------------------------------------------------------------------------
-----------------S_Notify_Game_Player_Count  416---------------------------
function NetMsgHandler.Received_S_Notify_Game_Player_Count(message)
    GameData.RoomInfo.CurrentRoom.RoleCount = message:PopUInt16()
    CS.EventDispatcher.Instance:TriggerEvent(EventDefine.UpdateRoleCount, GameData.RoomInfo.CurrentRoom.RoleCount)
end

---------------------------------------------------------------------------
-----------------CS_Up_Banker  417-----------------------------------------
function NetMsgHandler.Send_CS_Up_Banker()
    local message = CS.Net.PushMessage()
    message:PushUInt32(GameData.RoleInfo.AccountID)
    NetMsgHandler.SendMessageToGame(ProtrocolID.CS_Up_Banker, message, false)
end

function NetMsgHandler.Received_CS_Up_Banker(message)
    local resultType = message:PopByte();
    local showMsg = data.GetString("Up_Bank_Error_" .. resultType)
    if resultType == 4 then
        local roomConfig = data.RoomConfig[GameData.RoomInfo.CurrentRoom.TemplateID]
        if roomConfig ~= nil then
            showMsg = string.format(showMsg, lua_NumberToStyle1String(GameConfig.GetFormatColdNumber(roomConfig.UpBankerGold)))
        end
    end
    CS.BubblePrompt.Show(showMsg, "GameUI2");
end

---------------------------------------------------------------------------
-----------------CS_Up_Banker_List  418------------------------------------
function NetMsgHandler.Send_CS_Up_Banker_List()
    local message = CS.Net.PushMessage()
    message:PushUInt32(GameData.RoleInfo.AccountID)
    NetMsgHandler.SendMessageToGame(ProtrocolID.CS_Up_Banker_List, message, false)
end

function NetMsgHandler.Received_CS_Up_Banker_List(message)
    local resultType = message:PopByte()
    local count = message:PopUInt16()
    GameData.RoomInfo.CurrentRoom.BankerList = { }
    for index = 1, count, 1 do
        local bankerInfo = { }
        bankerInfo.ID = message:PopUInt32()
        bankerInfo.Name = message:PopString()
        bankerInfo.GoldCount = message:PopInt64()
        bankerInfo.VipLevel = message:PopByte()
        GameData.RoomInfo.CurrentRoom.BankerList[index] = bankerInfo
    end
    CS.EventDispatcher.Instance:TriggerEvent(EventDefine.UpdateBankerList, nil)
end

---------------------------------------------------------------------------
-----------------S_Notify_Win_Gold  420------------------------------------
function NetMsgHandler.Received_S_Notify_Win_Gold(message)
    local count = message:PopUInt16()
    GameData.RoomInfo.CurrentRoom.WinGold.NoPayAll = false
    for index = 1, count, 1 do
        local winCode = message:PopByte()
        local betValue = message:PopInt64()
        local winValue = message:PopInt64()
        local isPayOff = message:PopByte()
        GameData.RoomInfo.CurrentRoom.WinGold[WIN_AREA_CODE[winCode]] = { BetValue = betValue, WinGold = winValue, IsPayOff = isPayOff }
        if isPayOff == 1 then
            -- 有未赔付的情况
            GameData.RoomInfo.CurrentRoom.WinGold.NoPayAll = true
        end
    end

    CS.EventDispatcher.Instance:TriggerEvent(EventDefine.NotifyWinGold, nil)
end

---------------------------------------------------------------------------
-----------------S_Update_Banker  421--------------------------------------
function NetMsgHandler.Received_S_Update_Banker(message)
    local lastBankerName = GameData.RoomInfo.CurrentRoom.BankerInfo.Name
    NetMsgHandler.ParseAndSetBankerInfo(message)

    if GameData.RoomInfo.CurrentRoom.BankerInfo.IsLastForceDownBanker then
        CS.BubblePrompt.Show(string.format(data.GetString("Down_Banker_Tips_Force"), lastBankerName), "GameUI2")
    end

    CS.BubblePrompt.Show(string.format(data.GetString("Update_Banker_Tips"), GameData.RoomInfo.CurrentRoom.BankerInfo.Name), "GameUI2")

    CS.EventDispatcher.Instance:TriggerEvent(EventDefine.UpdateBankerInfo, 1)
end

---------------------------------------------------------------------------
-----------------S_Update_Banker_Gold  422---------------------------------
function NetMsgHandler.Received_S_Update_Banker_Gold(message)
    GameData.RoomInfo.CurrentRoom.BankerInfo.Gold = message:PopInt64()
    GameData.RoomInfo.CurrentRoom.BankerInfo.LeftCount = message:PopByte()
    CS.EventDispatcher.Instance:TriggerEvent(EventDefine.UpdateBankerInfo, 1)
end

---------------------------------------------------------------------------
-----------------CS_Cut_Card  423------------------------------------------
function NetMsgHandler.Send_CS_Cut_Card(index)
    print('给服务器发切的第几张牌', index)
    local message = CS.Net.PushMessage()
    message:PushUInt32(GameData.RoleInfo.AccountID)
    message:PushByte(index)
    NetMsgHandler.SendMessageToGame(ProtrocolID.CS_Cut_Card, message, false)
end

function NetMsgHandler.Received_CS_Cut_Card(message)
    local resultType = message:PopByte()
    print('服务器返回切牌结果', resultType)
    if resultType ~= 0 then
    end
end

---------------------------------------------------------------------------
-----------------CS_Request_Role_List  424---------------------------------
function NetMsgHandler.Send_CS_Request_Role_List()
    local message = CS.Net.PushMessage()
    message:PushUInt32(GameData.RoleInfo.AccountID)
    NetMsgHandler.SendMessageToGame(ProtrocolID.CS_Request_Role_List, message, true)
end

function NetMsgHandler.Received_CS_Request_Role_List(message)
    CS.LoadingDataUI.Hide()
    local resultType = message:PopByte()
    if resultType == 0 then
        local count = message:PopUInt16()
        local playerList = { }
        for index = 1, count, 1 do
            local player = { }
            player.AccountID = message:PopUInt32()
            player.AccountName = message:PopString()
            player.GoldCount = message:PopInt64()
            player.HeadIcon = message:PopByte()
            playerList[index] = player
        end
        print('=====服务器返回玩家列表结果:', count)
        local playersUI = CS.WindowManager.Instance:FindWindowNodeByName("UIRoomPlayers");
        if playersUI ~= nil then
            playersUI.WindowData = playerList
        end
    else
        CS.BubblePrompt.Show(data.GetString("Role_List_Error" .. resultType), "GameUI2")
    end
end

---------------------------------------------------------------------------
------------------------CS_Player_Cut_Type  425----------------------------
function NetMsgHandler.CS_Player_Cut_Type(pokerType)
    -- body
    local message = CS.Net.PushMessage()
    message:PushUInt32(GameData.RoleInfo.AccountID)
    message:PushByte(pokerType)
    NetMsgHandler.SendMessageToGame(ProtrocolID.CS_Player_Cut_Type, message, false)
end

function NetMsgHandler.Received_CS_Player_Cut_Type(message)
    -- body
    local result = message:PopByte()
    if result == 0 then
        local pokerType = message:PopByte()
        CS.EventDispatcher.Instance:TriggerEvent(EventDefine.NotifyCutPokerType, pokerType)
    else
        -- 有误1账号不存在 2房间不存在 3不是搓牌状态
    end

end

--------------------------------------------------------------------------
------------------------CS_Player_Icon_Change  426------------------------

-- 请求切换玩家头像icon
function NetMsgHandler.CS_Player_Icon_Change(iconid)
    -- body
    local message = CS.Net.PushMessage()
    message:PushUInt32(GameData.RoleInfo.AccountID)
    message:PushByte(iconid)
    NetMsgHandler.SendMessageToGame(ProtrocolID.CS_Player_Icon_Change, message, false)
end

-- Sever反馈头像修改结果
function NetMsgHandler.Received_CS_Player_Icon_Change(message)
    -- body
    local result = message:PopByte()
    if result == 0 then
        local headIcon = message:PopByte()
        GameData.RoleInfo.AccountIcon = headIcon
        CS.EventDispatcher.Instance:TriggerEvent(EventDefine.NotifyHeadIconChange, headIcon)
    else
        -- 有误1账号不存在 2头像ID不存在
    end
end

--------------------------------------------------------------------------
------------------------------CS_Player_YuYinChat 427---------------------

function NetMsgHandler.CS_Player_YuYinChat(chatResult)
    -- body
    local message = CS.Net.PushMessage()
    message:PushUInt32(GameData.RoleInfo.AccountID)
    message:PushString(chatResult)
    NetMsgHandler.SendMessageToGame(ProtrocolID.CS_Player_YuYinChat, message, false)
end

-- 服务器反馈语音聊天发送结果
function NetMsgHandler.Received_CS_Player_YuYinChat(message)
    -- body
    local result = message:PopByte()
    if result == 0 then
        local chatData = { }
        chatData.name = message:PopString()
        chatData.headIcon = message:PopByte()
        chatData.chatResult = message:PopString()
        print(string.format("=====[%s] send chat icon[%d]", chatData.name, chatData.headIcon))
        CS.EventDispatcher.Instance:TriggerEvent(EventDefine.NotifyPlayerYuYinChat, chatData)
    else
        -- 有误1账号不存在 2房间不存在 3 房间不是VIP房 4 冷却中...
        error("player YuYin chat error" .. result)
    end
end

---------------------------------------------------------------------------
-----------------CS_Apply_Down_Banker  428---------------------------------
function NetMsgHandler.Send_CS_Apply_Down_Banker()
    local message = CS.Net.PushMessage()
    message:PushUInt32(GameData.RoleInfo.AccountID)
    NetMsgHandler.SendMessageToGame(ProtrocolID.CS_Apply_Down_Banker, message, false)
end

function NetMsgHandler.Received_CS_Apply_Down_Banker(message)
    local resultType = message:PopByte()
    CS.BubblePrompt.Show(data.GetString("Down_Banker_Error_" .. resultType), "GameUI2")
end

---------------------------------------------------------------------------
-----------------CS_Apply_Banker_State  429--------------------------------
function NetMsgHandler.Send_CS_Apply_Banker_State()
    local message = CS.Net.PushMessage()
    message:PushUInt32(GameData.RoleInfo.AccountID)
    NetMsgHandler.SendMessageToGame(ProtrocolID.CS_Apply_Banker_State, message, false)
end

function NetMsgHandler.Received_CS_Apply_Banker_State(message)
    local resultType = message:PopByte()
    if resultType == 0 then
        local state = message:PopByte()
        if state == 0 then
            if GameData.RoleInfo.AccountID == GameData.RoomInfo.CurrentRoom.BankerInfo.ID then
                local boxData = CS.MessageBoxData()
                boxData.Title = "提示"
                boxData.Content = data.GetString("Down_Banker_Tips")
                boxData.Style = 2
                boxData.OKButtonName = "放弃"
                boxData.CancelButtonName = "确定"
                boxData.LuaCallBack = DownBankerButtonMessageBoxCallBack
                local parentWindow = CS.WindowManager.Instance:FindWindowNodeByName("GameUI2")
                CS.MessageBoxUI.Show(boxData, parentWindow)
            end
        elseif state == 1 then
            CS.BubblePrompt.Show(data.GetString("Down_Banker_Error_4"), "GameUI2")
        end
    end
end

function DownBankerButtonMessageBoxCallBack(result)
    if result == 2 then
        -- 取消和确定位置反向了的
        if GameData.RoleInfo.AccountID == GameData.RoomInfo.CurrentRoom.BankerInfo.ID then
            NetMsgHandler.Send_CS_Apply_Down_Banker()
        end
    end
end

---------------------------------------------------------------------------
-----------------S_Add_MoveNotice  500-------------------------------------
-- 处理收到服务器播放跑马灯消息
function NetMsgHandler.HandleAddMoveNotice(message)
    local level = message:PopByte()
    local enumType = message:PopByte()
    local name = message:PopString()
    -- 跑马灯管理器添加数据
    if enumType == 255 then
        CS.MoveNotice.Notice(name, level)
    else
        local goldCoins = message:PopUInt64()
        local value = data.RunHorseConfig[enumType].Value_CN
        if enumType <= 3 then
            local goldDesc = lua_CommaSeperate(GameConfig.GetFormatColdNumber(goldCoins))
            value = string.format(value, name, goldDesc)
        else
            value = string.format(value, name)
        end
        CS.MoveNotice.Notice(value, level)
    end
end

---------------------------------------------------------------------------
-----------------CS_SmallHorn  501-----------------------------------------
-- 发送 小喇叭 协议
function NetMsgHandler.SendSmallHorn(contentString)
    local message = CS.Net.PushMessage()
    message:PushUInt32(GameData.RoleInfo.AccountID)
    -- 玩家账号
    message:PushString(contentString)
    -- 小喇叭字符串信息压入消息结构体
    NetMsgHandler.SendMessageToGame(ProtrocolID.CS_SmallHorn, message, true);
end

function NetMsgHandler.HandleSmallHorn(message)
    -- print('收到小喇叭返回协议')
    CS.LoadingDataUI.Hide();
    local result = message:PopByte()
    if result == 0 then
        -- 通知界面发送小喇叭消息成功
        return
    else
        CS.BubblePrompt.Show(data.GetString("SmallHorn_Error_" .. result), "Notice")
        return
    end
end

---------------------------------------------------------------------------
-----------------CS_SEND_EMAIL  502----------------------------------------
-- 发送邮件
function NetMsgHandler.SendEmail(title, content, receiverID, gold)
    local message = CS.Net.PushMessage()
    message:PushUInt32(GameData.RoleInfo.AccountID)
    -- 玩家账号
    message:PushByte(2)
    -- 邮件发送者类型
    message:PushString(title)
    -- 邮件标题
    message:PushString(content)
    -- 邮件内容
    message:PushUInt32(receiverID)
    -- 接收者id
    message:PushUInt64(gold)
    -- 邮件附带金币数
    message:PushUInt32(0)
    -- 邮件附带房卡数
    NetMsgHandler.SendMessageToGame(ProtrocolID.CS_SEND_EMAIL, message, true);
end

-- 服务器回复发送结果
function NetMsgHandler.HandleSendEmailResult(message)
    -- print('收到邮件发送结果')
    CS.LoadingDataUI.Hide()
    local result = message:PopByte()
    if result == 0 then
        local sendTo = message:PopUInt32()
        local goldCount = message:PopInt64()
        local feeCount = message:PopInt64()
        if goldCount > 0 then
            -- 金币邮件，提示
            local boxData = CS.MessageBoxData()
            boxData.Title = "提示"
            local formatStr = data.GetString("Tips_Send_Mail_Success")
            boxData.Content = string.format(formatStr, lua_CommaSeperate(GameConfig.GetFormatColdNumber(goldCount)), tostring(sendTo), lua_CommaSeperate(GameConfig.GetFormatColdNumber(feeCount)))
            boxData.Style = 1
            CS.MessageBoxUI.Show(boxData)
        else
            CS.BubblePrompt.Show(EmailMgr:GetSendMailError(result), "UIEmail")
        end
    else
        CS.BubblePrompt.Show(EmailMgr:GetSendMailError(result), "UIEmail")
    end

    CS.EventDispatcher.Instance:TriggerEvent(EventDefine.NotifySendMailResult, result)
end

---------------------------------------------------------------------------
-----------------CS_CHECK_ACCOUNTID  503-----------------------------------
-- 检查账号有效性
function NetMsgHandler.SendCheckAccountID(accountID)
    local message = CS.Net.PushMessage()
    message:PushUInt32(GameData.RoleInfo.AccountID)
    -- 玩家账号
    message:PushUInt32(accountID)
    -- 待检测账号
    NetMsgHandler.SendMessageToGame(ProtrocolID.CS_CHECK_ACCOUNTID, message, true)
end

-- 账号检测结果
function NetMsgHandler.HandleCheckAccountIDResult(message)
    CS.LoadingDataUI.Hide();
    local result = message:PopByte()
    local vipLevel = 0
    local canSendGold = 0
    if result == 0 then
        vipLevel = message:PopByte()
        canSendGold = message:PopByte()
    elseif result == 1 then
        CS.BubblePrompt.Show("账号无效", "UIEmail")
    end
    print('发红包标记:' .. canSendGold)
    local eventArg = { ResultType = result, VipLevel = vipLevel, CanSendGold = canSendGold }
    CS.EventDispatcher.Instance:TriggerEvent(EventDefine.NotifyEmailRoleInfo, eventArg)
end

---------------------------------------------------------------------------
-----------------CS_OTHER_PLAYER_INFO  504---------------------------------
-- 请求邮件发送者信息
function NetMsgHandler.SendOtherPlayerInfoRequest(accountID)
    local message = CS.Net.PushMessage()
    message:PushUInt32(GameData.RoleInfo.AccountID)
    -- 玩家账号
    message:PushUInt32(accountID)
    -- 对方账号
    NetMsgHandler.SendMessageToGame(ProtrocolID.CS_OTHER_PLAYER_INFO, message, true);
end

-- 返回邮件发送者信息
function NetMsgHandler.HandleOtherPlayerInfoResult(message)
    -- print('收到服务器发来的其他玩家信息')
    CS.LoadingDataUI.Hide();
    local result = message:PopByte()
    if result == 0 then
        print('服务器说账号有效')
        local name = message:PopString()
        local nGold = message:PopUInt64()
        local nRoomCard = message:PopUInt32()
        local nRank = message:PopByte()
        local headIconUrl = message:PopString()
        return
    elseif result == 1 then
        print('服务器说账号无效')
        CS.BubblePrompt.Show("账号无效", "UIEmail");
        return
    end
end

---------------------------------------------------------------------------
-----------------C_CHANGE_EMAIL_TO_READED  505-----------------------------
-- 标记邮件为已读，此协议无需服务器返回结果
function NetMsgHandler.SendReadEmail(emailID)
    local message = CS.Net.PushMessage()
    message:PushUInt32(GameData.RoleInfo.AccountID)
    -- 玩家账号
    message:PushUInt32(emailID)
    -- 邮件id
    NetMsgHandler.SendMessageToGame(ProtrocolID.C_CHANGE_EMAIL_TO_READED, message, false);
end

---------------------------------------------------------------------------
-----------------CS_GET_EMAIL_REWARD  506----------------------------------
-- 请求获取邮件内奖励
function NetMsgHandler.SendGetEmailReward(emailID)
    local message = CS.Net.PushMessage()
    message:PushUInt32(GameData.RoleInfo.AccountID)
    -- 玩家账号
    message:PushUInt32(emailID)
    -- 邮件id
    NetMsgHandler.SendMessageToGame(ProtrocolID.CS_GET_EMAIL_REWARD, message, true);
end

-- 返回获取邮件奖励结果
function NetMsgHandler.HandleGetEmailRewardResult(message)
    -- print('收到服务器发来的领取邮件奖励结果')
    CS.LoadingDataUI.Hide();
    local result = message:PopByte()
    if result == 0 then
        -- 领取成功
        CS.BubblePrompt.Show("领取成功", "UIEmail");
        local mailID = message:PopUInt32()
        EmailMgr:GetMailReward(mailID)
        return
    elseif result == 1 then
        print('服务器说邮件无效')
        CS.BubblePrompt.Show("邮件无效", "UIEmail");
        return
    elseif result == 2 then
        -- print('服务器说已领取了该邮件')
        CS.BubblePrompt.Show("已领取了该邮件", "UIEmail");
        return
    end
end


---------------------------------------------------------------------------
-----------------CS_ADD_EMAILS  507----------------------------------------
-- 向服务器请求邮件列表
function NetMsgHandler.SendRequestEmails(mailID)
    local message = CS.Net.PushMessage()
    message:PushUInt32(GameData.RoleInfo.AccountID)
    -- 玩家账号
    message:PushUInt32(mailID)
    -- 客户端最大的邮件id
    NetMsgHandler.SendMessageToGame(ProtrocolID.CS_ADD_EMAILS, message, true);
end

function NetMsgHandler.HandleReceiveEmail(message)

    CS.LoadingDataUI.Hide()
    local number = message:PopUInt16()
    if EmailMgr:GetMailList() == nil then
        -- 如果邮件管理器的邮件table为nil，初始化为{}
        EmailMgr:InitList()
    end
    print("服务器通知添加邮件 number = " .. number)
    if number == 0 then
        return
    end

    for index = 1, number, 1 do
        local emailID = message:PopUInt32()
        local emailType = message:PopByte()
        local title = message:PopString()
        local content = message:PopString()
        local senderID = message:PopUInt32()
        local senderName = message:PopString()
        local date = message:PopUInt32()
        local nGold = message:PopUInt64()
        local nRoomCard = message:PopUInt32()
        local bIsRead = message:PopByte()
        -- 添加到邮件管理器 nMailID, nSendType, sTitle, sContent, nSenderID, sSenderName, sSendDate, nGold, nRoomCard, bIsRead
        print(string.format("emailID = %d, emailType = %d, bIsRead = %d", emailID, emailType, bIsRead))
        EmailMgr:AddMail(emailID, emailType, title, content, senderID, senderName, date, nGold, nRoomCard, bIsRead)
    end

    -- 刷新一下邮件ID排列
    EmailMgr:RefreshSortMailIDList()
    -- 刷新一下未读邮件数
    EmailMgr:RefreshUnreadMailCount()

    -- 如果当前正在显示邮件界面，刷新邮件列表
    local emailUI = CS.WindowManager.Instance:FindWindowNodeByName("UIEmail")
    if emailUI ~= nil then
        emailUI.WindowData = 1
    end
end

---------------------------------------------------------------------------
-----------------CS_DELETE_EMAIL  508--------------------------------------
function NetMsgHandler.SendDeleteEmail(emailID)
    -- print('请求删除邮件')
    local message = CS.Net.PushMessage()
    message:PushUInt32(GameData.RoleInfo.AccountID)
    -- 玩家账号
    message:PushUInt32(emailID)
    -- 邮件id
    NetMsgHandler.SendMessageToGame(ProtrocolID.CS_DELETE_EMAIL, message, true);
end

function NetMsgHandler.HandleDeleteEmail(message)
    -- print('服务器返回删除邮件结果')
    CS.LoadingDataUI.Hide()
    local result = message:PopByte()
    if result == 0 or 2 then
        CS.BubblePrompt.Show("删除成功", "UIEmail")
        -- 邮件管理器删除邮件
        local mailID = message:PopUInt32()
        EmailMgr:DelMail(mailID)

    elseif result == 1 then
        CS.BubblePrompt.Show("删除失败,账号不存在", "UIEmail")
    end
end

---------------------------------------------------------------------------
-----------------CS_MODIFY_NAME  509---------------------------------------
function NetMsgHandler.SendModifyName(newName)
    print('请求修改昵称')
    local message = CS.Net.PushMessage()
    message:PushUInt32(GameData.RoleInfo.AccountID)
    -- 玩家账号
    message:PushString(newName)
    -- 新昵称
    NetMsgHandler.SendMessageToGame(ProtrocolID.CS_MODIFY_NAME, message, true);
end

function NetMsgHandler.HandleModifyName(message)
    print('修改昵称结果')
    CS.LoadingDataUI.Hide();
    local resultType = message:PopByte()
    if resultType == 0 then
        GameData.RoleInfo.ModifyNameCount = message:PopByte()
        GameData.RoleInfo.AccountName = message:PopString()
    end

    CS.BubblePrompt.Show(data.GetString('Change_Name_Error_' .. resultType), "PlayerInfoUI")

    local masterInfoUI = CS.WindowManager.Instance:FindWindowNodeByName("PlayerInfoUI")
    if masterInfoUI ~= nil then
        masterInfoUI.WindowData = 1
    end

    CS.EventDispatcher.Instance:TriggerEvent(EventDefine.NotifyChangeAccountName, nil)
end

---------------------------------------------------------------------------
-----------------CS_ALL_RANK  510------------------------------------------
function NetMsgHandler.SendRequestRanks(nType)
    print("请求排行榜数据")
    local message = CS.Net.PushMessage()
    message:PushUInt32(GameData.RoleInfo.AccountID)
    -- 玩家账号
    message:PushByte(nType)
    -- 排行榜类型
    NetMsgHandler.SendMessageToGame(ProtrocolID.CS_ALL_RANK, message, true);
end

function NetMsgHandler.HandleAllRankInfo(message)
    CS.LoadingDataUI.Hide();
    local nType = message:PopByte()
    if nType == 1 then
        local count = message:PopUInt16()
        local richList = { }
        for index = 1, count, 1 do
            local rankItem = { }
            rankItem.RankID = index
            rankItem.HeadIcon = message:PopByte()
            rankItem.AccountName = message:PopString()
            rankItem.RichValue = message:PopInt64()
            rankItem.AccountID = message:PopUInt32()
            rankItem.VipLevel = message:PopByte()
            richList[index] = rankItem
        end
        GameData.RankInfo.RichList = richList
        GameData.RankInfo.DayOfYear = lua_GetTimeToYearDay()
        print("获取排行榜的日期 = " .. GameData.RankInfo.DayOfYear)
        -- 如果排行榜界面还是打开的，刷新界面
        local rankUI = CS.WindowManager.Instance:FindWindowNodeByName("UIRank")
        if rankUI ~= nil then
            rankUI.WindowData = nType
        end
    end
end

---------------------------------------------------------------------------
-----------------CS_PAOPAO_CHAT  512---------------------------------------
function NetMsgHandler.SendChatPaoPao(senderEnum, chatEnum)
    -- print('发送聊天泡泡senderEnum = '..senderEnum..' chatEnum = '..chatEnum)
    local message = CS.Net.PushMessage()
    message:PushUInt32(GameData.RoleInfo.AccountID)
    -- 玩家账号
    message:PushByte(senderEnum)
    message:PushByte(chatEnum)
    NetMsgHandler.SendMessageToGame(ProtrocolID.CS_PAOPAO_CHAT, message, false)
end

function NetMsgHandler.HandleChatPaoPao(message)
    local senderEnum = message:PopByte()
    local chatEnum = message:PopByte()
    -- print('收到聊天泡泡 sender='..senderEnum..' chatEnum ='..chatEnum)
    local eventArg = { roleType = senderEnum, chatIndex = chatEnum, }
    -- 通知界面显示
    CS.EventDispatcher.Instance:TriggerEvent(EventDefine.NotifyChatPaoPao, eventArg)
end

---------------------------------------------------------------------------
-----------------CS_Request_Game_History  513------------------------------
function NetMsgHandler.Send_CS_Request_Game_History(startNum, requestCount)
    local message = CS.Net.PushMessage()
    message:PushUInt32(GameData.RoleInfo.AccountID)
    -- 玩家账号
    message:PushUInt16(startNum)
    message:PushUInt16(requestCount)
    NetMsgHandler.SendMessageToGame(ProtrocolID.CS_Request_Game_History, message, true)
end

function NetMsgHandler.Received_CS_Request_Game_History(message)
    CS.LoadingDataUI.Hide()
    -- 如果历史记录界面已关闭，则不需要再解析数据
    local gameHistoryUI = CS.WindowManager.Instance:FindWindowNodeByName("UIGameHistory")
    if gameHistoryUI ~= nil then
        local maxCount = message:PopUInt16()
        if maxCount > 0 then
            local count = message:PopUInt16()
            for index = 1, count, 1 do
                local historyData = { }
                historyData.Time = message:PopUInt32()
                historyData.RoomID = message:PopUInt32()
                historyData.Pokers = { }
                -- 解析扑克牌
                for i = 1, 6, 1 do
                    historyData.Pokers[i] = { }
                    historyData.Pokers[i].PokerType = message:PopByte()
                    historyData.Pokers[i].PokerNumber = message:PopByte()
                end
                -- 游戏结果
                historyData.GameResult = message:PopUInt32()
                -- 解析押注信息
                historyData.BetValues = { }
                local betAreaCount = message:PopUInt16()
                for j = 1, betAreaCount, 1 do
                    local betArea = message:PopByte()
                    local betValue = message:PopUInt64()
                    historyData.BetValues[betArea] = betValue
                end
                -- 解析金币相关内容
                historyData.BeforeGoldCount = message:PopInt64()
                historyData.ChangeGoldCount = message:PopInt64()
                historyData.LaterGoldCount = message:PopInt64()
                historyData.PayAll = message:PopByte()
                table.insert(GameData.GameHistory.Datas, historyData)
            end
        end
        GameData.GameHistory.MaxCount = maxCount
        gameHistoryUI.WindowData = nil
    end
end

---------------------------------------------------------------------------
-----------------C_RETURN_GAME  511----------------------------------------


-- 收到切回确认通知 此消息已作废
function NetMsgHandler.HandleCutOutReturn(message)
    print('收到切回确认通知 此消息已作废')

end

-- 请求玩家基本信息 此消息已作废
function NetMsgHandler.SendRequestAccountInfo()
    print('请求玩家基本信息 此消息已作废')

end

-- 收到玩家基本信息 此消息已作废
function NetMsgHandler.HandleAccountInfo(message)
    print('收到玩家基本信息 此消息已作废')
end

-- 请求房间信息 此消息已作废
function NetMsgHandler.SendRequestRoomInfo(roomID)
    print('请求房间信息 此消息已作废')

end

-- 收到请求房间数据确认 此消息已作废
function NetMsgHandler.HandleRoomInfo(message)
    print('收到请求房间数据确认 此消息已作废')

end

---------------------------------------------------------------------------
-----------------CS_Invite_Code  601---------------------------------------
function NetMsgHandler.Send_CS_Invite_Code(inviteCode)
    local message = CS.Net.PushMessage()
    message:PushUInt32(GameData.RoleInfo.AccountID)
    message:PushUInt32(inviteCode)
    NetMsgHandler.SendMessageToGame(ProtrocolID.CS_Invite_Code, message, true)
end

function NetMsgHandler.Received_CS_Invite_Code(message)
    CS.LoadingDataUI.Hide()
    local resultType = message:PopByte()
    if resultType == 0 then
        GameData.RoleInfo.InviteCode = message:PopUInt32()
        CS.WindowManager.Instance:CloseWindow('UIInviteCode', false)
        -- 刷新下设置界面
        local settingUI = CS.WindowManager.Instance:FindWindowNodeByName("UISetting")
        if settingUI ~= nil then
            settingUI.WindowData = 1
        end
    end

    CS.BubblePrompt.Show(data.GetString("Invite_Code_Error_" .. resultType), "UISetting")
end

---------------------------------------------------------------------------
-----------------S_Update_Promoter  602------------------------------------
function NetMsgHandler.Received_S_Update_Pomoter(message)
    GameData.RoleInfo.PromoterStep = message:PopByte()
    -- 刷新下设置界面按钮状态界面
    local settingUI = CS.WindowManager.Instance:FindWindowNodeByName("UISetting")
    if settingUI ~= nil then
        settingUI.WindowData = 1
    end
end

-- ===========================================================================--
-- =============================CS_JH_Create_Room 801=========================--

-- 组局厅请求创建房间(底注 下注上限 陌生人加入 游戏模式(经典 激情):1 2 必闷N圈:1 3 入场金币:100 离场金币:20)
function NetMsgHandler.Send_CS_JH_Create_Room(betMinParam, betMaxParam, isLockParam, roomTypeParam, menTimesParam, enterBetParam, quitBetParam)
    -- body
    local message = CS.Net.PushMessage()
    message:PushUInt32(GameData.RoleInfo.AccountID)
    message:PushUInt32(betMinParam)
    message:PushUInt32(betMaxParam)
    message:PushByte(isLockParam)
    message:PushByte(roomTypeParam)
    message:PushByte(menTimesParam)
    message:PushUInt32(enterBetParam)
    message:PushUInt32(quitBetParam)

    NetMsgHandler.SendMessageToGame(ProtrocolID.CS_JH_Create_Room, message, true)
    print(string.format("-----Account:%d Min:%d Max:%d Lock:%d RoomType:%d MenJi:%d EnterBet:%d QuitBet:%d", GameData.RoleInfo.AccountID, betMinParam, betMaxParam, isLockParam, roomTypeParam, menTimesParam, enterBetParam, quitBetParam))
end

-- 组局厅请求创建房间反馈
function NetMsgHandler.Received_CS_JH_Create_Room(message)
    -- body
    CS.LoadingDataUI.Hide()
    local resultType = message:PopByte()
    if resultType == 0 then

        local ZJRoomID = message:PopUInt32()
        GameData.RoomInfo.CurrentRoom.RoomID = ZJRoomID
        -- 组局厅房间创建成功 马上进入房间
        NetMsgHandler.Send_CS_JH_Enter_Room1(ZJRoomID)
    else
        CS.BubblePrompt.Show(data.GetString("JH_Create_Room_Error_" .. resultType), "HallUI")
    end
    print("=====CS_JH_Create_Room Result:" .. resultType)
end

-- ===========================================================================--
-- =============================CS_JH_Enter_Room1 802=========================--

-- 组局厅请求进入房间1
function NetMsgHandler.Send_CS_JH_Enter_Room1(roomIDParam)
    -- body
    local message = CS.Net.PushMessage()
    message:PushUInt32(GameData.RoleInfo.AccountID)
    message:PushUInt32(roomIDParam)
    NetMsgHandler.SendMessageToGame(ProtrocolID.CS_JH_Enter_Room1, message, true)
    print("-----CS_JH_Enter_Room1 ID:" .. roomIDParam)
end

-- 组局厅请求进入组局房间
function NetMsgHandler.Received_CS_JH_Enter_Room1(message)
    CS.LoadingDataUI.Hide()
    -- body
    local resultType = message:PopByte()
    if resultType == 0 then
        -- 进入游戏房间
        GameData.InitCurrentRoomInfo(ROOM_TYPE.JH_ZuJu)
        NetMsgHandler.OpenZUJUGameUI()
    else
        CS.BubblePrompt.Show(data.GetString("JH_Enter_Room1_Error_" .. resultType), "HallUI")
    end
    print("=====802 Result:" .. resultType)
end

-- ===========================================================================--
-- =============================CS_JH_Enter_Room2 803=========================--

-- 组局厅请求进入房间1
function NetMsgHandler.Send_CS_JH_Enter_Room2(roomTypeParam)
    -- body
    local message = CS.Net.PushMessage()
    message:PushUInt32(GameData.RoleInfo.AccountID)
    message:PushByte(roomTypeParam)
    NetMsgHandler.SendMessageToGame(ProtrocolID.CS_JH_Enter_Room2, message, true)
    print("-----CS_JH_Enter_Room2 ID:" .. roomTypeParam)

end

-- 组局厅请求进入闷鸡房间2
function NetMsgHandler.Received_CS_JH_Enter_Room2(message)
    CS.LoadingDataUI.Hide()
    -- body
    local resultType = message:PopByte()
    if resultType == 0 then
        GameData.InitCurrentRoomInfo(ROOM_TYPE.JH_MenJi)
        NetMsgHandler.OpenZUJUGameUI()
    else
        CS.BubblePrompt.Show(data.GetString("JH_Enter_Room2_Error_" .. resultType), "HallUI")
    end
    print("-----803 ID:" .. resultType)
end

-- 进入对战游戏房间
function NetMsgHandler.OpenZUJUGameUI()
    local gameui1Node = CS.WindowManager.Instance:FindWindowNodeByName('GameUI1')
    if gameui1Node == nil then
        local openparam = CS.WindowNodeInitParam("GameUI1")
        openparam.NodeType = 0
        openparam.LoadComplatedCallBack = function(windowNode)
            CS.WindowManager.Instance:CloseWindow("HallUI", false)
        end
        CS.WindowManager.Instance:OpenWindow(openparam)
    else
        -- TODO  已经处于对战房间
    end
end

-- ============================================================================--
-- =============================S_JH_Set_Game_Data 804=========================--

-- 组局厅反馈房间详细信息
function NetMsgHandler.Received_S_JH_Set_Game_Data(message)
    -- body
    NetMsgHandler.ParseJHRoomBaseInfo(message)
    NetMsgHandler.ParseJHRoomPlayersInfo(message)
    NetMsgHandler.ParseAllBetInfo(message)
    NetMsgHandler.ParseZUJURoomStateSwitchToSettlement(message)
    CS.EventDispatcher.Instance:TriggerEvent(EventDefine.InitRoomState, GameData.RoomInfo.CurrentRoom.RoomState)
    -- 切换状态为房间
    GameData.GameState = GAME_STATE.ROOM
end

-- 解析房间基础信息
function NetMsgHandler.ParseJHRoomBaseInfo(message)
    -- body
    GameData.RoomInfo.CurrentRoom.RoomID = message:PopUInt32()
    GameData.RoomInfo.CurrentRoom.MasterID = message:PopUInt32()
    GameData.RoomInfo.CurrentRoom.BigType = message:PopByte()
    GameData.RoomInfo.CurrentRoom.SmallType = message:PopByte()
    GameData.RoomInfo.CurrentRoom.GameMode = message:PopByte()
    GameData.RoomInfo.CurrentRoom.GameRule = message:PopByte()
    GameData.RoomInfo.CurrentRoom.BetMin = message:PopUInt32()
    GameData.RoomInfo.CurrentRoom.BetMax = message:PopUInt32()
    GameData.RoomInfo.CurrentRoom.RoomState = message:PopByte()
    GameData.RoomInfo.CurrentRoom.CountDown = message:PopUInt32() / 1000.0
    GameData.RoomInfo.CurrentRoom.SelfPosition = message:PopByte()
    local BankerPosition = message:PopByte()
    GameData.RoomInfo.CurrentRoom.BetAllValue = message:PopInt64()
    GameData.RoomInfo.CurrentRoom.RoundTimes = message:PopByte()
    local BettingPosition = message:PopByte()
    print('玩家真实位置:' .. GameData.RoomInfo.CurrentRoom.SelfPosition)
    print(string.format('底注min:%d 底注max:%d', GameData.RoomInfo.CurrentRoom.BetMin, GameData.RoomInfo.CurrentRoom.BetMax))
    -- 位置转换
    GameData.InitZUJURoomBettingValue(GameData.RoomInfo.CurrentRoom.BetMin)
    GameData.RoomInfo.CurrentRoom.BankerPosition = GameData.PlayerPositionConvert2ShowPosition(BankerPosition)
    GameData.RoomInfo.CurrentRoom.BettingPosition = GameData.PlayerPositionConvert2ShowPosition(BettingPosition)
end

-- 解析房间玩家列表
function NetMsgHandler.ParseJHRoomPlayersInfo(message)
    -- body
    local playerCount = message:PopUInt16()
    print('===804=当前房间玩家数量:' .. playerCount)
    for index = 1, playerCount, 1 do
        local playerID = message:PopUInt32()
        local Name = message:PopString()
        local HeadIcon = message:PopByte()
        local HeadUrl = message:PopString()
        local GoldValue = message:PopInt64()
        local severposition = message:PopByte()
        local PlayerState = message:PopByte()
        local LookState = message:PopByte()
        local DropCardState = message:PopByte()
        local CompareState = message:PopByte()
        local CompareResult = message:PopByte()
        local ReadyState = message:PopByte()

        print(string.format('玩家基础信息ID:%d Name:%s Head:%d Url:%s Gold:%d Pos:%d 状态:%d', playerID, Name, HeadIcon, HeadUrl, GoldValue, severposition, PlayerState))
        print('玩家服务器位置:' .. severposition)
        if severposition == 0 then
            error('服务器上传玩家位置:0 有误!!!')
        end

        local position = GameData.PlayerPositionConvert2ShowPosition(severposition)
        GoldValue = GameConfig.GetFormatColdNumber(GoldValue)

        GameData.RoomInfo.CurrentRoom.ZUJUPlayers[position].AccountID = playerID
        GameData.RoomInfo.CurrentRoom.ZUJUPlayers[position].Name = Name
        GameData.RoomInfo.CurrentRoom.ZUJUPlayers[position].HeadIcon = HeadIcon
        GameData.RoomInfo.CurrentRoom.ZUJUPlayers[position].HeadUrl = HeadUrl
        GameData.RoomInfo.CurrentRoom.ZUJUPlayers[position].GoldValue = GoldValue
        GameData.RoomInfo.CurrentRoom.ZUJUPlayers[position].Position = severposition
        GameData.RoomInfo.CurrentRoom.ZUJUPlayers[position].PlayerState = PlayerState
        GameData.RoomInfo.CurrentRoom.ZUJUPlayers[position].LookState = LookState
        GameData.RoomInfo.CurrentRoom.ZUJUPlayers[position].CompareState = CompareState
        GameData.RoomInfo.CurrentRoom.ZUJUPlayers[position].CompareResult = CompareResult
        GameData.RoomInfo.CurrentRoom.ZUJUPlayers[position].ReadyState = ReadyState
    end

    -- 玩家自己的 扑克牌解析
    local cardCount = message:PopUInt16()
    print('当前扑克数量:' .. cardCount)
    for cardIndex = 1, cardCount, 1 do
        PokerType = message:PopByte()
        PokerNumber = message:PopByte()
        GameData.RoomInfo.CurrentRoom.ZUJUPlayers[5].PokerList[cardIndex].PokerType = PokerType
        GameData.RoomInfo.CurrentRoom.ZUJUPlayers[5].PokerList[cardIndex].PokerNumber = PokerNumber
    end

end

-- 解析当前所有下注情况
function NetMsgHandler.ParseAllBetInfo(message)
    -- body
    local betCount = message:PopUInt16()
    print('本局当前下注次数:' .. betCount)
    for index = 1, betCount, 1 do
        local position = message:PopByte()
        local betValue = message:PopInt64()
        local BetInfo = { Position = position, BetValue = betValue }
        GameData.RoomInfo.CurrentRoom.AllBetInfo[index] = BetInfo
    end
end

-- ============================================================================--
-- =============================S_JH_Next_State 805=========================--

-- 组局厅通知房间下一阶段
function NetMsgHandler.Received_S_JH_Next_State(message)
    -- body
    local RoomState = message:PopByte()
    if RoomState == ZUJURoomState.Start then
        -- 等待开始
        NetMsgHandler.ParseZUJURoomStateSwitchToStart(message)
    elseif RoomState == ZUJURoomState.Wait then
        -- 准备阶段
        NetMsgHandler.ParseZUJURoomStateSwitchToWait(message)
    elseif RoomState == ZUJURoomState.SubduceBet then
        -- 扣除底注
        NetMsgHandler.ParseZUJURoomStateSwitchToSubduceBet(message)
    elseif RoomState == ZUJURoomState.Deal then
        -- 发牌
        NetMsgHandler.ParseZUJURoomStateSwitchToDeal(message)
    elseif RoomState == ZUJURoomState.Betting then
        -- 下注
        NetMsgHandler.ParseZUJURoomStateSwitchToBetting(message)
    elseif RoomState == ZUJURoomState.CardVS then
        -- 比牌
        NetMsgHandler.ParseZUJURoomStateSwitchToCardVS(message)
    else
        -- Settlement 结算
        NetMsgHandler.ParseZUJURoomStateSwitchToSettlement(message)
    end

    GameData.SetZUJURoomState(RoomState)
end

-- 等待开始阶段解析
function NetMsgHandler.ParseZUJURoomStateSwitchToStart(message)

    print(string.format('===1==等待开始阶段解析'))
end

-- 准备阶段解析
function NetMsgHandler.ParseZUJURoomStateSwitchToWait(message)

    print(string.format('===2==准备阶段解析'))
end

-- 扣除底注阶段解析
function NetMsgHandler.ParseZUJURoomStateSwitchToSubduceBet(message)

    local playerCount = message:PopUInt16()
    for index = 1, playerCount, 1 do
        local severPosition = message:PopByte()
        local position = GameData.PlayerPositionConvert2ShowPosition(severPosition)
        local betValue = message:PopInt64()
        local GoldValue = message:PopInt64()
        betValue = GameConfig.GetFormatColdNumber(betValue)
        GoldValue = GameConfig.GetFormatColdNumber(GoldValue)
        GameData.RoomInfo.CurrentRoom.ZUJUPlayers[position].GoldValue = GoldValue
        GameData.RoomInfo.CurrentRoom.ZUJUPlayers[position].BetChipValue = GameData.RoomInfo.CurrentRoom.ZUJUPlayers[position].BetChipValue + betValue
        GameData.RoomInfo.CurrentRoom.ZUJUPlayers[position].PlayerState = Player_State.JoinOK
        print('betValue：' .. betValue .. 'GoldValue:' .. GoldValue)
        GameData.UpdateZUJUBetAllValue(betValue)
        -- 通知玩家下注了
        NetMsgHandler.NotifyPlayerBetting(position, betValue, 0)
    end
    print(string.format('===3==扣除底注阶段 玩家数量:%d', playerCount))
end

-- 发牌阶段解析
function NetMsgHandler.ParseZUJURoomStateSwitchToDeal(message)
    local playerCount = message:PopUInt16()
    for index = 1, playerCount, 1 do
        local position = message:PopByte()
        position = GameData.PlayerPositionConvert2ShowPosition(position)
        local cardCount = message:PopUInt16()
        for cardIndex = 1, cardCount, 1 do
            GameData.RoomInfo.CurrentRoom.ZUJUPlayers[position].PokerList[cardIndex].PokerType = message:PopByte()
            GameData.RoomInfo.CurrentRoom.ZUJUPlayers[position].PokerList[cardIndex].PokerNumber = message:PopByte()
            GameData.RoomInfo.CurrentRoom.ZUJUPlayers[position].PokerList[cardIndex].Visible = false
        end
    end
    print(string.format('===4==发牌阶段 玩家数量:%d', playerCount))
end

-- 下注阶段解析
function NetMsgHandler.ParseZUJURoomStateSwitchToBetting(message)
    local RoundTimes = message:PopByte()
    local BettingPosition = message:PopByte()
    local MingCardBetMin = message:PopUInt32()
    local DarkCardBetMin = message:PopUInt32()
    local freePK = message:PopByte()


    BettingPosition = GameData.PlayerPositionConvert2ShowPosition(BettingPosition)
    MingCardBetMin = GameConfig.GetFormatColdNumber(MingCardBetMin)
    DarkCardBetMin = GameConfig.GetFormatColdNumber(DarkCardBetMin)

    GameData.RoomInfo.CurrentRoom.RoundTimes = RoundTimes
    GameData.RoomInfo.CurrentRoom.BettingPosition = BettingPosition
    GameData.RoomInfo.CurrentRoom.MingCardBetMin = MingCardBetMin
    GameData.RoomInfo.CurrentRoom.DarkCardBetMin = DarkCardBetMin

    print(string.format('===5==下注阶段 当前轮次:%d 下注玩家:%d 名牌底注:%f 暗牌底注:%f', RoundTimes, BettingPosition, MingCardBetMin, DarkCardBetMin))

end

-- 比牌阶段解析
function NetMsgHandler.ParseZUJURoomStateSwitchToCardVS(message)
    -- 挑战者: 位置 下注筹码 剩余筹码
    local ChallengerPosition = message:PopByte()
    local ChallengerBetValue = message:PopInt64()
    local ChallengerGoldValue = message:PopInt64()
    -- 总下注筹码
    local BetAllValue = message:PopInt64()

    -- 应邀参与者位置
    local ActorPosition = message:PopByte()
    -- 挑战赢家位置
    local ChallengeWinnerPosition = message:PopByte()

    ChallengerPosition = GameData.PlayerPositionConvert2ShowPosition(ChallengerPosition)
    ActorPosition = GameData.PlayerPositionConvert2ShowPosition(ActorPosition)
    ChallengeWinnerPosition = GameData.PlayerPositionConvert2ShowPosition(ChallengeWinnerPosition)

    ChallengerBetValue = GameConfig.GetFormatColdNumber(ChallengerBetValue)
    ChallengerGoldValue = GameConfig.GetFormatColdNumber(ChallengerGoldValue)
    BetAllValue = GameConfig.GetFormatColdNumber(BetAllValue)


    GameData.RoomInfo.CurrentRoom.ChallengerPosition = ChallengerPosition
    GameData.RoomInfo.CurrentRoom.ActorPosition = ActorPosition
    GameData.RoomInfo.CurrentRoom.ChallengeWinnerPosition = ChallengeWinnerPosition
    GameData.RoomInfo.CurrentRoom.BetAllValue = BetAllValue

    GameData.RoomInfo.CurrentRoom.ZUJUPlayers[ChallengerPosition].GoldValue = ChallengerGoldValue
    GameData.RoomInfo.CurrentRoom.ZUJUPlayers[ChallengerPosition].BetChipValue = GameData.RoomInfo.CurrentRoom.ZUJUPlayers[ChallengerPosition].BetChipValue + ChallengerBetValue

    -- 判断玩家比牌状态
    if ChallengeWinnerPosition == ChallengerPosition then
        GameData.RoomInfo.CurrentRoom.ZUJUPlayers[ActorPosition].CompareState = 1
        GameData.RoomInfo.CurrentRoom.ZUJUPlayers[ActorPosition].CompareResult = 1
    else
        GameData.RoomInfo.CurrentRoom.ZUJUPlayers[ChallengeWinnerPosition].CompareState = 1
        GameData.RoomInfo.CurrentRoom.ZUJUPlayers[ChallengeWinnerPosition].CompareResult = 1
    end

    -- 判断本次挑战 是否有自己参加

    -- 通知挑战者下注
    NetMsgHandler.NotifyPlayerBetting(ChallengeWinnerPosition, ChallengerBetValue, 0)

end

-- 结算状态解析
function NetMsgHandler.ParseZUJURoomStateSwitchToSettlement(message)

    -- 赢家数量
    local winnerCount = message:PopUInt16()

    for index = 1, winnerCount, 1 do
        local WinnerPosition = message:PopByte()
        local WinGoldValue = message:PopInt64()
        local GoldValue = message:PopInt64()

        WinnerPosition = GameData.PlayerPositionConvert2ShowPosition(WinnerPosition)
        WinGoldValue = GameConfig.GetFormatColdNumber(WinGoldValue)
        GoldValue = GameConfig.GetFormatColdNumber(GoldValue)

        GameData.RoomInfo.CurrentRoom.ZUJUPlayers[WinnerPosition].GoldValue = GoldValue
        GameData.RoomInfo.CurrentRoom.ZUJUPlayers[WinnerPosition].WinGoldValue = WinGoldValue
        GameData.RoomInfo.CurrentRoom.ZUJUPlayers[WinnerPosition].IsWinner = true
    end
    -- 本局自己客户端需要量牌玩家
    local showCount = message:PopUInt16()
    for showIndex = 1, showCount, 1 do
        local position = message:PopByte()
        position = GameData.PlayerPositionConvert2ShowPosition(position)
        GameData.RoomInfo.CurrentRoom.ZUJUPlayers[position].IsShowPokerCard = true
    end
end

-- ============================================================================--
-- =============================S_JH_Next_State 806=========================--

-- 组局厅通知新增一个玩家
function NetMsgHandler.Received_S_JH_Add_Player(message)
    -- body
    local position = message:PopByte()
    position = GameData.PlayerPositionConvert2ShowPosition(position)

    local playerID = message:PopUInt32()
    local Name = message:PopString()
    local HeadIcon = message:PopByte()
    local HeadUrl = message:PopString()
    local GoldValue = message:PopInt64()
    local PlayerState = message:PopByte()

    GoldValue = GameConfig.GetFormatColdNumber(GoldValue)
    GameData.RoomInfo.CurrentRoom.ZUJUPlayers[position].AccountID = playerID
    GameData.RoomInfo.CurrentRoom.ZUJUPlayers[position].Name = Name
    GameData.RoomInfo.CurrentRoom.ZUJUPlayers[position].HeadIcon = HeadIcon
    GameData.RoomInfo.CurrentRoom.ZUJUPlayers[position].HeadUrl = HeadUrl
    GameData.RoomInfo.CurrentRoom.ZUJUPlayers[position].GoldValue = GoldValue
    GameData.RoomInfo.CurrentRoom.ZUJUPlayers[position].Position = position
    GameData.RoomInfo.CurrentRoom.ZUJUPlayers[position].PlayerState = PlayerState

    CS.EventDispatcher.Instance:TriggerEvent(EventDefine.NotifyZUJUAddPlayerEvent, position)
end

-- ============================================================================--
-- =============================S_JH_Delete_Player 807=========================--

-- 组局厅通知删除一个玩家
function NetMsgHandler.Received_S_JH_Delete_Player(message)
    -- body
    local position = message:PopByte()
    position = GameData.PlayerPositionConvert2ShowPosition(position)
    GameData.RoomInfo.CurrentRoom.ZUJUPlayers[position].PlayerState = Player_State.None
    GameData.RoomInfo.CurrentRoom.ZUJUPlayers[position].AccountID = 0
    GameData.RoomInfo.CurrentRoom.ZUJUPlayers[position].Name = ''
    GameData.RoomInfo.CurrentRoom.ZUJUPlayers[position].HeadIcon = 0
    GameData.RoomInfo.CurrentRoom.ZUJUPlayers[position].HeadUrl = ''
    GameData.RoomInfo.CurrentRoom.ZUJUPlayers[position].GoldValue = 0
    GameData.RoomInfo.CurrentRoom.ZUJUPlayers[position].Position = 0
    GameData.RoomInfo.CurrentRoom.ZUJUPlayers[position].BetChipValue = 0
    GameData.RoomInfo.CurrentRoom.ZUJUPlayers[position].ReadyState = 0
    GameData.RoomInfo.CurrentRoom.ZUJUPlayers[position].LookState = 0
    GameData.RoomInfo.CurrentRoom.ZUJUPlayers[position].DropCardState = 0
    GameData.RoomInfo.CurrentRoom.ZUJUPlayers[position].CompareState = 0
    GameData.RoomInfo.CurrentRoom.ZUJUPlayers[position].CompareResult = 0
    GameData.RoomInfo.CurrentRoom.ZUJUPlayers[position].IsWinner = false
    GameData.RoomInfo.CurrentRoom.ZUJUPlayers[position].WinGoldValue = 0
    GameData.RoomInfo.CurrentRoom.ZUJUPlayers[position].IsShowPokerCard = false


    CS.EventDispatcher.Instance:TriggerEvent(EventDefine.NotifyZUJUDeletePlayerEvent, position)
end

-- ============================================================================--
-- =============================CS_JH_Exit_Room 808=========================--

-- 组局厅请求离开房间
function NetMsgHandler.Send_CS_JH_Exit_Room(rooIDParam)
    local message = CS.Net.PushMessage()
    message:PushUInt32(GameData.RoleInfo.AccountID)
    message:PushUInt32(rooIDParam)
    NetMsgHandler.SendMessageToGame(ProtrocolID.CS_JH_Exit_Room, message, true)
    print("-----808 ID:" .. rooIDParam)
end

-- 组局厅请求离开房间反馈
function NetMsgHandler.Received_CS_JH_Exit_Room(message)
    CS.LoadingDataUI.Hide()
    local resultType = message:PopByte()
    if resultType == 0 then
        NetMsgHandler.ExitRoomToHall(0)
    else
        CS.BubblePrompt.Show(data.GetString("CS_JH_Exit_Room_Error_" .. resultType), "GameUI1")
    end
    CS.LoadingDataUI.Hide()
    print("=====808 ID:" .. resultType)
end

-- ============================================================================--
-- =============================CS_JH_Ready 809=========================--

-- 组局厅玩家开始准备
function NetMsgHandler.Send_CS_JH_Ready(readyParam)
    local message = CS.Net.PushMessage()
    message:PushUInt32(GameData.RoleInfo.AccountID)
    message:PushByte(readyParam)
    NetMsgHandler.SendMessageToGame(ProtrocolID.CS_JH_Ready, message)
    print("-----CS_JH_Ready ID:" .. readyParam)
end

-- 组局厅玩家准备反馈
function NetMsgHandler.Received_CS_JH_Ready(message)
    local resultType = message:PopByte()
    if resultType == 0 then
        local position = message:PopByte()
        local readyState = message:PopByte()
        position = GameData.PlayerPositionConvert2ShowPosition(position)
        GameData.RoomInfo.CurrentRoom.ZUJUPlayers[position].ReadyState = readyState
        CS.EventDispatcher.Instance:TriggerEvent(EventDefine.NotifyZUJUPlayerReadyStateEvent, position)
    else
        CS.BubblePrompt.Show(data.GetString("CS_JH_Ready_Error_" .. resultType), "GameUI1")
    end
    print("=====CS_JH_Ready ID:" .. resultType)
end

-- ============================================================================--
-- =============================CS_JH_Betting 810=========================--

-- 玩家请求下注(加注,跟注)
function NetMsgHandler.Send_CS_JH_Betting(roomidParam, betTypeParam, betValueParam)
    local message = CS.Net.PushMessage()
    message:PushUInt32(GameData.RoleInfo.AccountID)
    message:PushUInt32(roomidParam)
    message:PushByte(betTypeParam)
    message:PushInt64(betValueParam)
    NetMsgHandler.SendMessageToGame(ProtrocolID.CS_JH_Betting, message)
    print("---810--CS_JH_Betting ID:" .. roomidParam)
end

-- 组局厅 下注反馈
function NetMsgHandler.Received_CS_JH_Betting(message)
    local resultType = message:PopByte()
    if resultType == 0 then
        local position = message:PopByte()
        local betType = message:PopByte()
        local betValue = message:PopInt64()
        local GoldValue = message:PopInt64()

        position = GameData.PlayerPositionConvert2ShowPosition(position)
        betValue = GameConfig.GetFormatColdNumber(betValue)
        GoldValue = GameConfig.GetFormatColdNumber(GoldValue)

        GameData.RoomInfo.CurrentRoom.ZUJUPlayers[position].GoldValue = GoldValue
        GameData.RoomInfo.CurrentRoom.ZUJUPlayers[position].BetChipValue = GameData.RoomInfo.CurrentRoom.ZUJUPlayers[position].BetChipValue + betValue
        GameData.UpdateZUJUBetAllValue(betValue)
        -- 通知玩家下注了
        NetMsgHandler.NotifyPlayerBetting(position, betValue, betType)
    else
        CS.BubblePrompt.Show(data.GetString("JH_Betting_Error_" .. resultType), "GameUI1")
    end
    print("=====CS_JH_Betting Result:" .. resultType)
end

-- 广播玩家玩家下注
function NetMsgHandler.NotifyPlayerBetting(positionParam, betValueParam, betTypeParam)
    -- 通知玩家下注了
    local betChipEventArg = { PositionValue = positionParam, BetValue = betValueParam, BetType = betTypeParam }
    CS.EventDispatcher.Instance:TriggerEvent(EventDefine.NotifyZUJUBettingEvent, betChipEventArg)
end

-- ============================================================================--
-- =============================CS_JH_VS_Card 811=========================--

-- 玩家请求比牌(被挑战者，发起类型)
function NetMsgHandler.Send_CS_JH_VS_Card(defenseID, PKType)

    local message = CS.Net.PushMessage()
    message:PushUInt32(GameData.RoleInfo.AccountID)
    message:PushUInt32(defenseID)
    message:PushByte(PKType)
    NetMsgHandler.SendMessageToGame(ProtrocolID.CS_JH_VS_Card, message)
    print("---810--CS_JH_VS_Card ID:" .. defenseID)
end


-- 服务器反馈比牌
function NetMsgHandler.Received_CS_JH_VS_Card(message)
    local resultType = message:PopByte()
    if resultType == 0 then

        -- 通知玩家下注了
    else
        CS.BubblePrompt.Show(data.GetString("VS_Card_Error_" .. resultType), "GameUI1")
    end
    print("=====811 Result:" .. resultType)
end


-- ============================================================================--
-- =============================CS_JH_Drop_Card 812=========================--

function NetMsgHandler.Send_CS_JH_Drop_Card()
    local message = CS.Net.PushMessage()
    message:PushUInt32(GameData.RoleInfo.AccountID)
    NetMsgHandler.SendMessageToGame(ProtrocolID.CS_JH_Drop_Card, message)
    print("---812--CS_JH_Drop_Card ID:" .. GameData.RoleInfo.AccountID)
end

-- 服务器反馈玩家弃牌
function NetMsgHandler.Received_CS_JH_Drop_Card(message)
    local resultType = message:PopByte()
    if resultType == 0 then
        local position = message:PopByte()
        position = GameData.PlayerPositionConvert2ShowPosition(position)
        GameData.RoomInfo.CurrentRoom.ZUJUPlayers[position].DropCardState = 1
        CS.EventDispatcher.Instance:TriggerEvent(EventDefine.NotifyZUJUDropCardEvent, position)
    else
        CS.BubblePrompt.Show(data.GetString("Drop_Card_Error_" .. resultType), "GameUI1")
    end
end

-- ============================================================================--
-- =============================CS_JH_Look_Card 813=========================--

function NetMsgHandler.Send_CS_JH_Look_Card()
    local message = CS.Net.PushMessage()
    message:PushUInt32(GameData.RoleInfo.AccountID)
    NetMsgHandler.SendMessageToGame(ProtrocolID.CS_JH_Look_Card, message)
    print("---813--CS_JH_Drop_Card ID:" .. GameData.RoleInfo.AccountID)
end

-- 服务器反馈 看牌
function NetMsgHandler.Received_CS_JH_Look_Card(message)
    local resultType = message:PopByte()
    if resultType == 0 then
        local position = message:PopByte()
        position = GameData.PlayerPositionConvert2ShowPosition(position)
        local cardCount = message:PopUInt16()
        for cardIndex = 1, cardCount, 1 do
            local PokerType = message:PopByte()
            local PokerNumber = message:PopByte()

            GameData.RoomInfo.CurrentRoom.ZUJUPlayers[position].PokerList[cardIndex].PokerType = PokerType
            GameData.RoomInfo.CurrentRoom.ZUJUPlayers[position].PokerList[cardIndex].PokerNumber = PokerNumber
            GameData.RoomInfo.CurrentRoom.ZUJUPlayers[position].PokerList[cardIndex].Visible = true
        end

        GameData.RoomInfo.CurrentRoom.ZUJUPlayers[position].LookState = 1
        CS.EventDispatcher.Instance:TriggerEvent(EventDefine.NotifyZUJULookCardEvent, position)
    else
        CS.BubblePrompt.Show(data.GetString("Drop_Card_Error_" .. resultType), "GameUI1")
    end
end


-- 服务器广播玩家看牌消息
function NetMsgHandler.Received_S_JH_Notify_Look_Card(message)

end

