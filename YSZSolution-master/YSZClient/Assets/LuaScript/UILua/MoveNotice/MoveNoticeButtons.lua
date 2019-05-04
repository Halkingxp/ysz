function Awake()
	this.transform:Find('laba'):GetComponent("Button").onClick:AddListener(HornButton_OnClick)
	this.transform:Find('jilu'):GetComponent("Button").onClick:AddListener(HistoryButton_OnClick)
end

function HornButton_OnClick()
	--print('小喇叭按钮被点击')
	--print(string.format('viplevel = %d',GameData.RoleInfo.VipLevel))
	--玩家vip等级判断
	local tVipConfig = data.VipConfig[GameData.RoleInfo.VipLevel]
	if tVipConfig.Speaker == -1 then
		--print('需要vip等级6才能发送小喇叭')
		CS.BubblePrompt.Show("VIP6以上才可发送", "Notice")
	else
		local initParam = CS.WindowNodeInitParam("UISmallHorn")
		CS.WindowManager.Instance:OpenWindow(initParam)
	end
end

function HistoryButton_OnClick()
	local initParam = CS.WindowNodeInitParam("UIHornHistory")
	CS.WindowManager.Instance:OpenWindow(initParam)
end