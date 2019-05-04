function Awake()
	local settings = this.transform:Find('Canvas/Window/Content/Settings/Viewport/Content')
	
	settings:Find('AccountSetting/Panel/SwitchAccount'):GetComponent("Button").onClick:AddListener(SwitchAccountButtonOnClick)
	settings:Find('AccountSetting/Panel/BindAccount').gameObject:SetActive(GameConfig.CanVisitorLogin)
	settings:Find('AccountSetting/Panel/BindAccount'):GetComponent("Button").onClick:AddListener(BindAccountButtonOnClick)
	
	settings:Find('OtherSetting/Panel/Help'):GetComponent("Button").onClick:AddListener(HelpButtonOnClick)
	settings:Find('OtherSetting/Panel/Invite'):GetComponent("Button").onClick:AddListener(InviteButtonOnClick) 
	settings:Find('OtherSetting/Panel/GameHistory'):GetComponent("Button").onClick:AddListener(GameHistoryOnClick)	
	
	this.transform:Find('Canvas/Mask'):GetComponent("Button").onClick:AddListener(CloseButtonOnClick)
	this.transform:Find('Canvas/Window/Title/CloseButton'):GetComponent("Button").onClick:AddListener(CloseButtonOnClick)
	
	if GameData.IsShowInviteBtn == 0 and LoginMgr.RunningPlatformID == 3 then
		settings:Find('OtherSetting/Panel/Invite').gameObject:SetActive(false)
	else
		settings:Find('OtherSetting/Panel/Invite').gameObject:SetActive(true)
	end
end

function WindowOpened()
	local settings = this.transform:Find('Canvas/Window/Content/Settings/Viewport/Content')
	settings:Find('SystemSetting/Panel/Switch1'):GetComponent("SwitchControl").IsOn = MusicMgr.isMuteBackMusic
	settings:Find('SystemSetting/Panel/Switch2'):GetComponent("SwitchControl").IsOn = MusicMgr.isMuteSoundEffect
	-- 由于 SwitchControl 状态变化会触发回调 导致开启界面就会播放音效 因此滞后于状态值设置
	settings:Find('SystemSetting/Panel/Switch1'):GetComponent("SwitchControl").onValueChanged:AddListener(BackMusicSwithControlOnValueChanged)
	settings:Find('SystemSetting/Panel/Switch2'):GetComponent("SwitchControl").onValueChanged:AddListener(EffectMusicSwithControlOnValueChanged)
end

function RefreshWindowData(windowData)
	RefreshUIButtonState()
end


-- 刷新窗体按钮状态
function RefreshUIButtonState()
	local settings = this.transform:Find('Canvas/Window/Content/Settings/Viewport/Content')
	settings:Find('AccountSetting/Panel/BindAccount'):GetComponent("Button").interactable = GameData.RoleInfo.IsBindAccount == false
	print(string.format( "promoterStep:%d InviteCode:%d", GameData.RoleInfo.PromoterStep,  GameData.RoleInfo.InviteCode ))
	-- 只有微信登录 邀请码才能可点击
--[[	if (GameData.RoleInfo.PromoterStep == 2  or GameData.RoleInfo.InviteCode == 0)and GameData.LoginInfo.PlatformType == PLATFORM_TYPE.PLATFORM_WEIXIN then
		settings:Find('OtherSetting/Panel/Invite'):GetComponent("Button").interactable = true
	else
		settings:Find('OtherSetting/Panel/Invite'):GetComponent("Button").interactable = false
	end
	]]
end


-- 关闭按钮响应
function CloseButtonOnClick()
	CS.WindowManager.Instance:CloseWindow('UISetting', false)
end

-- 音乐开关
function BackMusicSwithControlOnValueChanged(isOn)
	MusicMgr:MuteBackMusic(isOn)
	MusicMgr:PlaySoundEffect(2)
end

-- 音效开关
function EffectMusicSwithControlOnValueChanged(isOn)
	
	MusicMgr:PlaySoundEffect(2)
	MusicMgr:MuteSoundEffect(isOn)
end

-- 绑定账号按钮
function BindAccountButtonOnClick()
	
	if GameData.RoleInfo.IsBindAccount == true then
		local settings = this.transform:Find('Canvas/Window/Content/Settings/Viewport/Content')
		settings:Find('AccountSetting/Panel/BindAccount'):GetComponent("Button").interactable = false
		return
	end
	
	if LoginMgr.WechatIsInstall == 0 then
		CS.BubblePrompt.Show("无法绑定", "UISetting")
		return
	end
	CS.LoadingDataUI.Show(5)
	--通知sdk绑定账号
	PlatformBridge:CallFunc(PLATFORM_TYPE.PLATFORM_WEIXIN, PLATFORM_FUNCTION_ENUM.PLATFORM_FUNCTION_BIND_ACCOUNT, "通知sdk绑定账号")
end

-- 切换账号按钮
function SwitchAccountButtonOnClick()
	NetMsgHandler.CloseConnect()
	LoginMgr.isChangeAccount = 1
	NetMsgHandler.ReturnLogin()
end

-- 帮助按钮
function HelpButtonOnClick()
	local initParam =CS.WindowNodeInitParam("UIHelp")
	CS.WindowManager.Instance:OpenWindow(initParam)
end

-- 邀请按钮
function InviteButtonOnClick()
	--判断自己是不是推广员，如果是，打开推广员界面，如果不是，打开输入邀请码界面
	if GameData.RoleInfo.PromoterStep == 2 or GameData.RoleInfo.PromoterStep == 3 then
		local initParam =CS.WindowNodeInitParam('UIInvite')
		initParam.ParentNode = this.WindowNode
		CS.WindowManager.Instance:OpenWindow(initParam)
	else
		if GameData.RoleInfo.InviteCode > 0 then
			CS.BubblePrompt.Show(data.GetString("Tip_Bind_Invite_Code_Success"), "UISetting")
		else
			local initParam =CS.WindowNodeInitParam('UIInviteCode')
			initParam.ParentNode = this.WindowNode
			CS.WindowManager.Instance:OpenWindow(initParam)
		end
	end
end

function GameHistoryOnClick()
	local initParam =CS.WindowNodeInitParam("UIGameHistory")
	CS.WindowManager.Instance:OpenWindow(initParam)
end