function Awake()
	this.transform:Find('Canvas/Window/Bottom/ButtonClose'):GetComponent("Button").onClick:AddListener(CloseButtonOnClick)
	this.transform:Find('Canvas/Window/Bottom/ButtonOK'):GetComponent("Button").onClick:AddListener(OKButtonOnClick)
end

function WindowOpened()
	this.transform:Find('Canvas/Window/Content/CodeInput'):GetComponent("InputField").text = ''
end

-- 关闭按钮响应
function CloseButtonOnClick()
	CS.WindowManager.Instance:CloseWindow('UIInviteCode', false)
end

-- 确定按钮按钮
function OKButtonOnClick()
	local inviteCode = this.transform:Find('Canvas/Window/Content/CodeInput'):GetComponent("InputField").text
	if #inviteCode > 0 then
		if tonumber(inviteCode) == GameData.RoleInfo.AccountID then
			-- 不能绑定自身
			CS.BubblePrompt.Show(data.GetString("Invite_Code_Error_".. 5), "UISetting")
			return
		end
		
		NetMsgHandler.Send_CS_Invite_Code(tonumber(inviteCode))
	end
end