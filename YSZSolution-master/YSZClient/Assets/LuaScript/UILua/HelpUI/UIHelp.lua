local GameRuleUI = nil				-- 游戏规则UI
local GameShowUI = nil				-- 咪牌演示UI
local GameExplainUI = nil			-- 路单说明UI


function Awake()
	GameRuleUI = this.transform:Find('Canvas/Window/GameRule')
	GameShowUI = this.transform:Find('Canvas/Window/GameShow')
	GameExplainUI = this.transform:Find('Canvas/Window/GameExplain')
	
	this.transform:Find('Canvas/Window/ToggleGroup/GameRuleToggle'):GetComponent("Toggle").onValueChanged:AddListener( function (isOn) OnToggle_OnValue_Changed(isOn, 1) end)
	this.transform:Find('Canvas/Window/ToggleGroup/GameShowToggle'):GetComponent("Toggle").onValueChanged:AddListener( function (isOn) OnToggle_OnValue_Changed(isOn, 2) end)
	this.transform:Find('Canvas/Window/ToggleGroup/GameExplainToggle'):GetComponent("Toggle").onValueChanged:AddListener( function (isOn) OnToggle_OnValue_Changed(isOn, 3) end)
	this.transform:Find('Canvas/Window/Title/ReturnButton'):GetComponent("Button").onClick:AddListener(ReturnButtonButtonOnClick)
	GameRuleUI.gameObject:SetActive(true)
	GameShowUI.gameObject:SetActive(false)
	GameExplainUI.gameObject:SetActive(false)
end

-- 返回按钮回调
function ReturnButtonButtonOnClick()
	CS.WindowManager.Instance:CloseWindow('UIHelp', false)
end

-- UI显示切换
function OnToggle_OnValue_Changed(isOn, page)
	if isOn then
		GameRuleUI.gameObject:SetActive(false)
		GameShowUI.gameObject:SetActive(false)
		GameExplainUI.gameObject:SetActive(false)

		if page == 1 then
			GameRuleUI.gameObject:SetActive(true)
		elseif page == 2 then
			GameShowUI.gameObject:SetActive(true)
		else
			GameExplainUI.gameObject:SetActive(true)
		end
	end
end
