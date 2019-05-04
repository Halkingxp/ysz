function Awake()
	this.transform:Find('Canvas/Window/Title/ReturnButton'):GetComponent("Button").onClick:AddListener(CloseButton_OnClick)
	this.transform:Find('Canvas/Window/Content/OKButton'):GetComponent("Button").onClick:AddListener(OKButton_OnClick)
end

function CloseButton_OnClick()
	CS.WindowManager.Instance:CloseWindow("UIAgreement", false)
end

function OKButton_OnClick()
	CS.WindowManager.Instance:CloseWindow("UIAgreement", false)
	GameData.IsAgreement = true
	-- 刷新下界面	
	local loginUI = CS.WindowManager.Instance:FindWindowNodeByName("UILogin")
	if loginUI ~= nil then
		loginUI.WindowData = 1
	end
end