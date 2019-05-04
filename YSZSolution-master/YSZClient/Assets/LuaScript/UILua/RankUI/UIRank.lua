function Awake()
	this.transform:Find('Canvas/Window/Title/ReturnButton'):GetComponent("Button").onClick:AddListener(CloseButtonOnClick)
	this.transform:Find('Canvas/Mask'):GetComponent("Button").onClick:AddListener(CloseButtonOnClick)
end

-- 数据刷新
function RefreshWindowData(windowData)
	local rankItemParent = this.transform:Find('Canvas/Window/Content/RankList/Viewport/Content')
	lua_Transform_ClearChildren(rankItemParent, true)
	local rankItem = this.transform:Find('Canvas/Window/Content/RankList/Viewport/Content/RankItem')
	rankItem.gameObject:SetActive(false)
	if windowData ~= nil and windowData == 1 then
		local richList = GameData.RankInfo.RichList
		if richList ~= nil then
			local newRankItem = nil
			for key, rankInfo in ipairs(richList) do
				newRankItem = CS.UnityEngine.Object.Instantiate(rankItem)
				CS.Utility.ReSetTransform(newRankItem, rankItemParent)
				newRankItem.gameObject:SetActive(true)
				ResetRankRichListItem(newRankItem, rankInfo)
			end
		end
	end
end

-- 关闭按钮响应
function CloseButtonOnClick()
	CS.WindowManager.Instance:CloseWindow('UIRank', false)
end

-- 刷新排行榜数据
function ResetRankRichListItem(rankItem, rankInfo)
	if rankInfo.RankID > 3 then
		rankItem:Find('RankID'):GetComponent("Text").text = tostring(rankInfo.RankID)
		rankItem:Find('RankID').gameObject:SetActive(true)
		rankItem:Find('RankFlag').gameObject:SetActive(false)
	else
		rankItem:Find('RankFlag'):GetComponent("Image"):ResetSpriteByName("sprite_Rank_Flag_".. rankInfo.RankID)		
		rankItem:Find('RankID').gameObject:SetActive(false)
		rankItem:Find('RankFlag').gameObject:SetActive(true)
	end
	rankItem:Find('AccountID'):GetComponent("Text").text = "ID:" .. tostring(rankInfo.AccountID)
	rankItem:Find('ItemBack').gameObject:SetActive(lua_Math_Mod(rankInfo.RankID, 2) == 1)
	rankItem:Find('AccountName'):GetComponent("Text").text = rankInfo.AccountName
	rankItem:Find('RichValue'):GetComponent("Text").text = lua_CommaSeperate(GameConfig.GetFormatColdNumber(rankInfo.RichValue))
	rankItem:Find('HeadIcon/VipLevel/Value'):GetComponent("Text").text = "V" .. rankInfo.VipLevel
	rankItem:Find('HeadIcon'):GetComponent("Image"):ResetSpriteByName(GameData.GetRoleIconSpriteName(rankInfo.HeadIcon))
end