local m_PageIndex = 1			-- 当前页签
local m_EveryPageCount = 7		-- 每页内容数量
local HistoryItems = {}			-- 游戏记录数据展示项

function Awake()
	this.transform:Find('Canvas/Window/Title/CloseButton'):GetComponent("Button").onClick:AddListener(CloseButtonOnClick)
	this.transform:Find('Canvas/Window/Content/Viewport/HandleArea/LeftArrow'):GetComponent("Button").onClick:AddListener(LeftArrowButtonOnClick)
	this.transform:Find('Canvas/Window/Content/Viewport/HandleArea/RightArrow'):GetComponent("Button").onClick:AddListener(RightArrowButtonOnClick)
	local historyRoot = this.transform:Find('Canvas/Window/Content/Viewport/Content')
	CreateHistoryItems(historyRoot, 7)
end

-- 打开窗体
function WindowOpened()
	PageIndexChangedTo(1)
end

-- 关闭窗体
function WindowClosed()
	GameData.GameHistory.MaxCount = 0
	GameData.GameHistory.RequestedPage = 0
	GameData.GameHistory.Datas = {}
end

-- 刷新界面数据
function RefreshWindowData(windowData)
	RefreshGameHistoryUI()
end

-- 创建统计趋势的元素
function CreateHistoryItems(historyRoot, childCount)
	local childModel = historyRoot:GetChild(0)
	childModel.gameObject:SetActive(false)
	lua_Transform_ClearChildren(historyRoot, true)
	for	index = 1, childCount, 1 do
		local instanceItem = CS.UnityEngine.Object.Instantiate(childModel)
		instanceItem.gameObject.name = 'Item' .. tostring(index)
		CS.Utility.ReSetTransform(instanceItem, historyRoot)
		instanceItem.gameObject:SetActive(false)
		HistoryItems[index] = instanceItem
	end
end

-- 刷新历史记录
function RefreshGameHistoryUI()
	if GameData.GameHistory.MaxCount > 0 then
		this.transform:Find('Canvas/Window/Content/NonHistory').gameObject:SetActive(false)
		this.transform:Find('Canvas/Window/Content/Viewport').gameObject:SetActive(true)
		RefreshGameHistoryItems()
	else
		this.transform:Find('Canvas/Window/Content/NonHistory').gameObject:SetActive(true)
		this.transform:Find('Canvas/Window/Content/Viewport').gameObject:SetActive(false)
	end
end

-- 刷新历史记录所有Item
function RefreshGameHistoryItems()
	for	index = 1, m_EveryPageCount, 1 do
		local historyData = GameData.GameHistory.Datas[index + (m_PageIndex - 1) * m_EveryPageCount]
		local historyItem = HistoryItems[index]
		if historyData ~= nil then
			historyItem.gameObject:SetActive(true)
			RefreshGameHistoryItem(historyItem, historyData)
		else
			historyItem.gameObject:SetActive(false)
		end
	end
	ResetPageIndexRelativeInfo()
end

-- 设置页面相关的信息
function ResetPageIndexRelativeInfo()
	local handleAreaRoot = this.transform:Find('Canvas/Window/Content/Viewport/HandleArea')
	local maxPage = math.ceil(GameData.GameHistory.MaxCount / m_EveryPageCount)
	handleAreaRoot:Find('PageIndex'):GetComponent("Text").text = string.format("%d/%d",m_PageIndex, maxPage)
end

-- 刷新历史记录Item
function RefreshGameHistoryItem(historyItem, historyData)
	historyItem:Find('Time'):GetComponent("Text").text = CS.Utility.UnixTimestampToDateTime(historyData.Time):ToString('MM-dd HH:mm')
	historyItem:Find('Room'):GetComponent("Text").text = GetRoomDisplayName(historyData.RoomID)
	historyItem:Find('CardInfos/Long/CardType'):GetComponent("Text").text = data.GetString("BRAND_TYPE_".. GameData.GetPokerType(historyData.Pokers[1], historyData.Pokers[2], historyData.Pokers[3]))
	historyItem:Find('CardInfos/Long/PokerCards'):GetComponent("Text").text = GetPokerCardsDisplayString(historyData.Pokers[1], historyData.Pokers[2], historyData.Pokers[3])
	historyItem:Find('CardInfos/Result'):GetComponent("Text").text = GetGameResultDisplayString(historyData.GameResult)
	historyItem:Find('CardInfos/Hu/CardType'):GetComponent("Text").text = data.GetString("BRAND_TYPE_".. GameData.GetPokerType(historyData.Pokers[4], historyData.Pokers[5], historyData.Pokers[6]))
	historyItem:Find('CardInfos/Hu/PokerCards'):GetComponent("Text").text = GetPokerCardsDisplayString(historyData.Pokers[4], historyData.Pokers[5], historyData.Pokers[6])
	-- 设置下注金额
	for	index = 1, 5, 1 do
		local betAreaItem = historyItem:Find('BetInfos/Area' .. index)
		if historyData.BetValues[index] ~= nil then
			betAreaItem.gameObject:SetActive(true)
			betAreaItem:Find('Value'):GetComponent("Text").text = lua_CommaSeperate(GameConfig.GetFormatColdNumber(historyData.BetValues[index]))
		else
			betAreaItem.gameObject:SetActive(false)
		end
	end
	-- 设置金币信息
	historyItem:Find('GoldInfos/BeforeGold/Value'):GetComponent("Text").text = lua_CommaSeperate(GameConfig.GetFormatColdNumber(historyData.BeforeGoldCount))
	historyItem:Find('GoldInfos/ChangeGold/Value'):GetComponent("Text").text = GetChangeGoldDisplay(historyData)
	historyItem:Find('GoldInfos/LaterGold/Value'):GetComponent("Text").text = lua_CommaSeperate(GameConfig.GetFormatColdNumber(historyData.LaterGoldCount))
end

-- 获取牌型描述
function GetPokerCardsDisplayString(poker1, poker2, poker3)
	return string.format("%s %s %s", GetPokerCardDisplayString(poker1), GetPokerCardDisplayString(poker2), GetPokerCardDisplayString(poker3))
end

-- 获取牌型Name
function GetPokerCardDisplayString(poker)
	local resultName = ""
	if poker.PokerType == Poker_Type.Spade then
		resultName = "黑"
	elseif poker.PokerType == Poker_Type.Hearts then
		resultName = "红"
	elseif poker.PokerType == Poker_Type.Club then
		resultName = "方"
	elseif poker.PokerType == Poker_Type.Diamond then
		resultName = "梅"
	end
	
	if poker.PokerNumber == 14 then
		resultName = resultName .. "A"
	elseif poker.PokerNumber == 13 then
		resultName = resultName .. "K"
	elseif poker.PokerNumber == 12 then
		resultName = resultName .. "Q"
	elseif poker.PokerNumber == 11 then
		resultName = resultName .. "J"
	else
		resultName = resultName .. poker.PokerNumber
	end
	return resultName
end

-- 设置金币信息
function GetChangeGoldDisplay(historyData)
	local result = ""
	if historyData.ChangeGoldCount >= 0 then
		result = "+"
	end
	result = result ..  lua_CommaSeperate(GameConfig.GetFormatColdNumber(historyData.ChangeGoldCount))
	
	if historyData.PayAll == 1 then
		result = result .. "(爆庄)"
	end
	return result
end

function GetGameResultDisplayString(gameResult)
	local resultStr = ""
	if CS.Utility.GetLogicAndValue(gameResult, WIN_CODE.LONG) == WIN_CODE.LONG then
		resultStr = "龍赢"
	elseif CS.Utility.GetLogicAndValue(gameResult, WIN_CODE.HU) == WIN_CODE.HU then
		resultStr = "虎赢"
	elseif CS.Utility.GetLogicAndValue(gameResult, WIN_CODE.HE) == WIN_CODE.HE then
		resultStr = "和局"
	else
		resultStr = ""
	end
	
	if CS.Utility.GetLogicAndValue(gameResult, WIN_CODE.LONGJINHUA) == WIN_CODE.LONGJINHUA then
		resultStr = resultStr .. ",龍金花"
	end
	if CS.Utility.GetLogicAndValue(gameResult, WIN_CODE.HUJINHUA) == WIN_CODE.HUJINHUA then
		resultStr = resultStr .. ",虎金花"
	end
	if CS.Utility.GetLogicAndValue(gameResult, WIN_CODE.LONGHUBAOZI) == WIN_CODE.LONGHUBAOZI then
		resultStr = resultStr .. ",龍虎豹子"
	end
	return resultStr
end


function GetRoomDisplayName(roomID)
	local roomConfig = data.RoomConfig[roomID]
	if roomConfig ~= nil then
		if roomConfig.Type == 2 then
			return "试水厅"
		elseif roomConfig.Type == 1 then
			return "搓牌厅" .. roomConfig.ShowName
		end
	else
		-- VIP 厅
		return "VIP".. roomID
	end
end

-- 关闭按钮
function CloseButtonOnClick()
	CS.WindowManager.Instance:CloseWindow("UIGameHistory", false)
end

-- 左箭头被点击
function LeftArrowButtonOnClick()
	PageIndexChangedTo(m_PageIndex - 1)
end

-- 右箭头被点击
function RightArrowButtonOnClick()
	PageIndexChangedTo(m_PageIndex + 1)
end

function PageIndexChangedTo(pageIndex)
	if GameData.GameHistory.MaxCount > 0 then
		if pageIndex > math.ceil(GameData.GameHistory.MaxCount / m_EveryPageCount) or pageIndex < 1 then
			return
		end
	end
	m_PageIndex = pageIndex
	-- 数据已经存在，直接刷新界面, 否则等待数据回来的时候，再刷新下界面
	if GameData.GameHistory.RequestedPage < pageIndex then
		for	index = 1, pageIndex - GameData.GameHistory.RequestedPage, 1 do
			local startNum = (GameData.GameHistory.RequestedPage + index - 1) * m_EveryPageCount + 1
			print (startNum)
			NetMsgHandler.Send_CS_Request_Game_History(startNum, m_EveryPageCount)
		end
		GameData.GameHistory.RequestedPage = pageIndex
	else
		RefreshGameHistoryUI()
	end
end