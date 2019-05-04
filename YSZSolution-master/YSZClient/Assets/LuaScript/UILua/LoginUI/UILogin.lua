local m_ShowedForceQuitPrompt = false
local mButtonVisitor = nil
local mButtonWeChat = nil
local mWaitDNS = nil

function Awake()
    mButtonWeChat = this.transform:Find('Canvas/Buttons/ButtonWeChat'):GetComponent("Button")
    mButtonVisitor = this.transform:Find('Canvas/Buttons/ButtonVisitor'):GetComponent("Button")
    mWaitDNS = this.transform:Find('Canvas/WaitDNS').gameObject

    mButtonVisitor.onClick:AddListener(OnVisitorButtonClick)
    mButtonWeChat.onClick:AddListener(OnWeChatButtonClick)

    CS.EventDispatcher.Instance:AddEventListener(EventDefine.ConnectGameServerFail, OnConnectGameServerFail)
    CS.EventDispatcher.Instance:AddEventListener(EventDefine.ConnectGameServerTimeOut, OnConnectGameServerTimeOut)

    CS.EventDispatcher.Instance:AddEventListener(EventDefine.NotifyVisitorCheckEvent, OnVisitorCheckEvent)

    this.transform:Find('Canvas/Agreement/AgreementButton'):GetComponent("Button").onClick:AddListener(AgreementButton_OnClick)
    this.transform:Find('Canvas/Agreement'):GetComponent("Toggle").onValueChanged:AddListener(AgreementToggle_OnValueChanged)

    LoginMgr.RunningPlatformID = CS.Utility.GetCurrentPlatform()
    if LoginMgr.RunningPlatformID == 2 or LoginMgr.RunningPlatformID == 3 then
        if LoginMgr.WechatIsRegister == 0 then
            LoginMgr.WechatIsRegister = PlatformBridge:CallFunc(PLATFORM_TYPE.PLATFORM_WEIXIN, PLATFORM_FUNCTION_ENUM.PLATFORM_FUNCTION_REG, "参数：注册sdk")
            -- print("注册sdk结果", LoginMgr.WechatIsRegister)
        end

        if LoginMgr.WechatIsRegister then
            LoginMgr.WechatIsRegister = PlatformBridge:CallFunc(PLATFORM_TYPE.PLATFORM_WEIXIN, PLATFORM_FUNCTION_ENUM.PLATFORM_FUNCTION_INSTALLED, "参数：软件安装状态")
        end
        -- print(string.format("是否安装微信 = %d,  运行平台 = %d",LoginMgr.WechatIsRegister, LoginMgr.RunningPlatformID))
    end

    local versionValue = CS.Utility.GetAppVersion()
    if versionValue ~= nil then
        this.transform:Find('Canvas/VersionText'):GetComponent("Text").text = "V " .. versionValue
    end
end

function Start()
    MusicMgr:PlayBackMusic(1)

    ShowLoginBtns()
    if GameConfig.IsSelectServer == 0 then
        -- 正式版本 不允许选择服务器
        NetMsgHandler.TryConnectHubServer(false)
        mButtonWeChat.gameObject:SetActive(false)
        mButtonVisitor.gameObject:SetActive(false)
        mWaitDNS:SetActive(true)
    end

    ReqChannelCode()
end

function RefreshWindowData(windowData)
    this.transform:Find('Canvas/Agreement'):GetComponent("Toggle").isOn = GameData.IsAgreement == true
end

function Update()
    if GameData.AppVersionCheckResult ~= -2 and not m_ShowedForceQuitPrompt then
        if GameData.AppVersionCheckResult > 0 then
            m_ShowedForceQuitPrompt = true
            ShowForceQuitPrompt()
        end
    end
end

function OnDestroy()
    CS.EventDispatcher.Instance:RemoveEventListener(EventDefine.ConnectGameServerFail, OnConnectGameServerFail)
    CS.EventDispatcher.Instance:RemoveEventListener(EventDefine.ConnectGameServerTimeOut, OnConnectGameServerTimeOut)
    CS.EventDispatcher.Instance:RemoveEventListener(EventDefine.NotifyVisitorCheckEvent, OnVisitorCheckEvent)

end

function OnVisitorButtonClick()
    -- print('点击游客登陆按钮 machinecode =',CS.UnityEngine.SystemInfo.deviceUniqueIdentifier)
    if GameData.IsAgreement ~= true then
        CS.BubblePrompt.Show(data.GetString("Un_Agreement_Tips"), "LoginNewUI")
        return
    end
    LoginMgr.lastLoginType = PLATFORM_TYPE.PLATFORM_TOURISTS

    CS.LoadingDataUI.Show(5)
    GameData.LoginInfo.Account = CS.UnityEngine.SystemInfo.deviceUniqueIdentifier
    GameData.LoginInfo.PlatformType = PLATFORM_TYPE.PLATFORM_TOURISTS
    GameData.LoginInfo.AccountName = ""
    NetMsgHandler.TryConnectHubServer(true)
end

function OnWeChatButtonClick()
    if GameData.IsAgreement ~= true then
        CS.BubblePrompt.Show(data.GetString("Un_Agreement_Tips"), "LoginNewUI")
        return
    end

    if LoginMgr.WechatIsRegister == 0 then
        -- print('提示玩家先安装微信')
        CS.BubblePrompt.Show("请先安装微信！", "LoginUI")
        return
    end
    -- 打开LoadingDataUI
    CS.LoadingDataUI.Show(5)
    PlatformBridge:CallFunc(PLATFORM_TYPE.PLATFORM_WEIXIN, PLATFORM_FUNCTION_ENUM.PLATFORM_FUNCTION_LOGIN, tostring(LoginMgr.isChangeAccount))
end

function OnConnectGameServerFail(param)
    ShowLoginBtns()
end

function OnConnectGameServerTimeOut(param)
    ShowLoginBtns()
end

function OnVisitorCheckEvent(param)
    -- body
    -- 游客登录开关验证结果
    if param == 1 then
        GameConfig.CanVisitorLogin = true
    else
        GameConfig.CanVisitorLogin = false
    end
    print(string.format('游客登录是否开启:%s', GameConfig.CanVisitorLogin))

    -- 刷新UI
    ShowLoginBtns()

end

function ShowLoginBtns()
    if LoginMgr.RunningPlatformID == 1 then
        mButtonVisitor.gameObject:SetActive(true)
        -- 如果是Window 平台则显示游客登陆，便于调试
    else
        mButtonVisitor.gameObject:SetActive(GameConfig.CanVisitorLogin)
    end
    if GameConfig.IsShenHeiVision == true then
        if LoginMgr.WechatIsRegister == 1 then
            mButtonWeChat.gameObject:SetActive(true)
        else
            mButtonWeChat.gameObject:SetActive(false)
        end
    else
        mButtonWeChat.gameObject:SetActive(true)
    end
end

function HideLoginBtns()
    mButtonVisitor.gameObject:SetActive(false)
    mButtonWeChat.gameObject:SetActive(false)
end


function AgreementToggle_OnValueChanged(isOn)
    if GameData.IsAgreement ~= isOn then
        GameData.IsAgreement = isOn
    end
end

function ShowForceQuitPrompt()
    local boxData = CS.MessageBoxData()
    boxData.Title = "提示"
    boxData.Content = "版本已更新，请重新进入"
    boxData.Style = 1
    boxData.OKButtonName = "确定"
    boxData.LuaCallBack = ForceQuitPromptMessageBoxCallBack
    CS.MessageBoxUI.Show(boxData)
end

function ForceQuitPromptMessageBoxCallBack(resultType)
    CS.Utility.LoadScene("Start")
end

function AgreementButton_OnClick()
    CS.WindowManager.Instance:OpenWindow("UIAgreement")
end

-- 请求渠道ID
function ReqChannelCode()
    -- 该阶段请求一下渠道ID
    PlatformBridge:CallFunc(PLATFORM_TYPE.PLATFORM_TOURISTS, PLATFORM_FUNCTION_ENUM.PLATFORM_FUNCTION_CHANNELCODE, '参数:请求渠道ID')
end