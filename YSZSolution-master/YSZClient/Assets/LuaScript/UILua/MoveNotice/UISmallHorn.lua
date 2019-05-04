local m_oldContent = ""
local m_hornContent = nil

function Awake()
	this.transform:Find('Canvas/Window/CloseBtn'):GetComponent("Button").onClick:AddListener(CloseButton_OnClick)
	this.transform:Find('Canvas/Window/SendBtn'):GetComponent("Button").onClick:AddListener(SendMsgButton_OnClick)
	m_hornContent = this.transform:Find('Canvas/Window/InputField'):GetComponent("InputField")
	m_hornContent.onValueChanged:AddListener(MsgContent_OnValueChanged)
end

function CloseButton_OnClick()
	CS.WindowManager.Instance:CloseWindow("UISmallHorn", false)
end

function SendMsgButton_OnClick()
		--print('发送按钮被点击')
	--冷却时间判断
	local currentTime = os.time()
	--print(currentTime)
	if currentTime - GameData.LastSmallHornTime >= MOVE_NOTICE_CONFIG.SMALL_HORN_COOL_TIME then
		GameData.LastSmallHornTime = currentTime
	else
		CS.BubblePrompt.Show(data.GetString("SmallHorn_Error_4"), "Notice")
		return
	end
	
	--金币是否足够
	local tVipConfig = data.VipConfig[GameData.RoleInfo.VipLevel]
	if GameData.RoleInfo.GoldCount < tVipConfig.Speaker then
		CS.BubblePrompt.Show(data.GetString("SmallHorn_Error_2"), "Notice")
		return
	end
	
	local content = m_hornContent.text
	--文字内容是否为空
	if content == '' then
		CS.BubblePrompt.Show(data.GetString("SmallHorn_Error_5"), "Notice")
		return
	end
	--print(content)
	
	--屏蔽字替换
	--string.gsub(content, "(%W)+", data.MaskConfig)
	local indexs
	local charNum
	local strReplace = ''
	for k, v in pairs(data.MaskConfig) do
		indexs = string.find(content, v.Value)
		if indexs ~= nil then
			--charNum = #(v.Value)
			charNum = CS.Utility.UTF8Stringlength(v.Value)
			--print('查询到的敏感字 = ', v.Value)
			for i = 1, charNum, 1  do
				strReplace = string.format("*%s",strReplace)
			end
			--print(string.format('index = %d, charNum = %d',indexs, charNum))
			content = string.gsub(content, v.Value, strReplace)
		end
	end
	--print(string.format('转换花费时间 = %d, 转换后的内容 = %s', os.time() - currentTime, content))
	
	--发送小喇叭协议给服务器
	content = string.format("<i><color=#f1dc29>V%d</color></i><color=#ffd06f>[%s]:</color>%s",GameData.RoleInfo.VipLevel, GameData.RoleInfo.AccountName, content)
	NetMsgHandler.SendSmallHorn(content)
	CloseButton_OnClick()
end

function MsgContent_OnValueChanged(newValue)	
	local content = newValue
	local csharpcharNum = CS.Utility.UTF8Stringlength(content)
	local luacharNum = string.len(content)
	local zwNum = (luacharNum - csharpcharNum) / 2
	local finalNum = zwNum + csharpcharNum
	if finalNum <= 100 then
		m_oldContent = content
	else
		m_hornContent.text = m_oldContent
	end
end

