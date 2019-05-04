function Awake()
	this.transform:Find('Canvas/Window/Title/CloseButton'):GetComponent("Button").onClick:AddListener(CloseButton_OnClick)
	--this.transform:Find('Canvas/Mask'):GetComponent("Button").onClick:AddListener(CloseButton_OnClick)
	
	this.transform:Find('Canvas/Window/Content/Panel/Bottom/ButtonInputCode'):GetComponent("Button").onClick:AddListener(InputCodeButton_OnClick)
	this.transform:Find('Canvas/Window/Content/Panel/Bottom/ButtonShare'):GetComponent("Button").onClick:AddListener(ShareButton_OnClick)
	
	this.transform:Find('Canvas/ShareWay/Content/ButtonClose'):GetComponent("Button").onClick:AddListener(ShareWayButton_OnClick)
	this.transform:Find('Canvas/ShareWay/Content/QQ'):GetComponent("Button").onClick:AddListener(ShareWayOfQQButton_OnClick)
	this.transform:Find('Canvas/ShareWay/Content/Weixin'):GetComponent("Button").onClick:AddListener(ShareWayOfWeixinButton_OnClick)
	this.transform:Find('Canvas/ShareWay').gameObject:SetActive(false)
end

function WindowOpened()
	this.transform:Find('Canvas/Window/Content/Panel/Bottom/InviteCode'):GetComponent("Text").text = tostring(GameData.RoleInfo.AccountID)
	this.transform:Find('Canvas/Window/Content/Panel/Bottom/ButtonInputCode'):GetComponent("Button").interactable = (GameData.RoleInfo.InviteCode == 0 and GameData.RoleInfo.PromoterStep ~= 3)
end

function CloseButton_OnClick()
	CS.WindowManager.Instance:CloseWindow('UIInvite', false)
end

-- 邀请码按钮
function InputCodeButton_OnClick()
	if GameData.RoleInfo.InviteCode == 0 and GameData.RoleInfo.PromoterStep ~= 3 then
		local initParam =CS.WindowNodeInitParam('UIInviteCode')
		initParam.ParentNode = this.WindowNode
		CS.WindowManager.Instance:OpenWindow(initParam)
	end
end

-- 分享按钮按钮
function ShareButton_OnClick()
	--this.transform:Find('Canvas/ShareWay').gameObject:SetActive(true)
	infoTable = {}
	infoTable["title"] = "万人金花之搓牌高手[官方]"
	infoTable["content"] = "本游戏是一款竞技+休闲类的三张游戏，模拟真实的搓牌环节，玩家与玩家之间，可发挥更多的心理战术，更能体现出“诈”的乐趣。"
	infoTable["url"] = "sdk.cool"
	infoJSON = CS.LuaAsynFuncMgr.Instance:MakeJson(infoTable)
	PlatformBridge:CallFunc(PLATFORM_TYPE.PLATFORM_WEIXIN, PLATFORM_FUNCTION_ENUM.PLATFORM_FUNCTION_SHARE, infoJSON)
end

function ShareWayButton_OnClick()
	this.transform:Find('Canvas/ShareWay').gameObject:SetActive(false)
end

function ShareWayOfQQButton_OnClick()
	CS.BubblePrompt.Show("Todo QQ", CS.UnityEngine.Vector3(0,0,0))
end

function ShareWayOfWeixinButton_OnClick()
	CS.BubblePrompt.Show("Todo 微信", CS.UnityEngine.Vector3(0,0,0))
end