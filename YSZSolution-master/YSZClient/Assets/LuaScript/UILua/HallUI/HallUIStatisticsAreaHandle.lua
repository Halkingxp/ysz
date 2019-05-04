-- 是否初始化
local isInited = false
-- 关联的房间ID和统计信息
local m_RelativeRoomID = 0

-- 右侧统计数据
local m_Right_LastPos = 0
local m_Right_LastUpdateValue = 0
local m_Right_OffsetY = 6
local m_Right_OffsetX = 64
local m_Right_DisplayColumnCount = 19
local m_Right_TrendTable = { }
local m_Right_IsDeflected = false
-- 左侧统计数据
local m_Left_OffsetY = 5
local m_Left_OffsetX = 13
local m_Left_DisplayColumnCount = 9

local m_Right_ItemCount = 0
local m_Left_ItemCount = 0

local m_Left_StatisticsRoot = nil
local m_Right_StatisticsRoot = nil
-- 上次处理到的回合数
local m_LastHandleRound = 0
-- 统计大小
local m_Left_ItemSize = 0
local m_Right_ItemSize = 0

local m_Right_CurrentMaxDisplayPos = 19

function Awake()
    m_Left_ItemCount = m_Left_OffsetX * m_Left_OffsetY
    m_Right_ItemCount = m_Right_OffsetX * m_Right_OffsetY

    m_Left_StatisticsRoot = this.transform:Find('StatisticsLeft/Viewport/Content')
    m_Right_StatisticsRoot = this.transform:Find('StatisticsRight/Viewport/Content')
    local leftGridLayoutGroup = m_Left_StatisticsRoot:GetComponent("GridLayoutGroup")
    m_Left_ItemSize = leftGridLayoutGroup.cellSize.x + leftGridLayoutGroup.spacing.x
    local rightGridLayoutGroup = m_Right_StatisticsRoot:GetComponent("GridLayoutGroup")
    m_Right_ItemSize = rightGridLayoutGroup.cellSize.x + rightGridLayoutGroup.spacing.x

    CreateStatisticsTrendItems(m_Left_StatisticsRoot, m_Left_ItemCount, m_Left_OffsetY * m_Left_DisplayColumnCount)
    CreateStatisticsTrendItems(m_Right_StatisticsRoot, m_Right_ItemCount, m_Right_OffsetY * m_Right_DisplayColumnCount)
    isInited = true
    CS.EventDispatcher.Instance:AddEventListener(EventDefine.UpdateStatistics, HandleUpdateStatisticsInfo)
    ResetRelativeRoomID(m_RelativeRoomID)
end

function OnDestroy()
    CS.EventDispatcher.Instance:RemoveEventListener(EventDefine.UpdateStatistics, HandleUpdateStatisticsInfo)
end

-- 重置关联的房间ID
function ResetRelativeRoomID(roomID)
    m_RelativeRoomID = roomID

    if not isInited then
        return
    end

    local statistics = GameData.RoomInfo.StatisticsInfo[roomID]
    if statistics ~= nil then
        ResetStatisticsInfo(statistics)
    end
end

-- 处理更新统计信息
function HandleUpdateStatisticsInfo(eventArgs)
    local updateRoomID = eventArgs.RoomID
    -- 不是关联的房间ID
    if updateRoomID ~= m_RelativeRoomID then
        return
    end
    local operationType = eventArgs.OperationType
    local statistics = GameData.RoomInfo.StatisticsInfo[updateRoomID]
    if operationType == 1 then
        AppendStatisticsInfo(statistics)
    else
        ResetStatisticsInfo(statistics)
    end
end

-- 创建统计趋势的元素
function CreateStatisticsTrendItems(trendParent, childCount, displayCount)
    local roundItem = trendParent:GetChild(0)
    roundItem.gameObject:SetActive(false)
    lua_Transform_ClearChildren(trendParent, true)
    for index = 1, childCount, 1 do
        local instanceItem = CS.UnityEngine.Object.Instantiate(roundItem)
        instanceItem.gameObject.name = 'Item' .. tostring(index)
        CS.Utility.ReSetTransform(instanceItem, trendParent)
        if index > displayCount then
            instanceItem.gameObject:SetActive(false)
        else
            instanceItem.gameObject:SetActive(true)
        end
    end
end

-- 重置统计信息
function ResetStatisticsInfo(statistics)
    m_RelativeRoomID = statistics.RoomID
    m_LastHandleRound = statistics.Round.CurrentRound
    if isInited == true then
        RefreshStatisticsTrendByStatistics(statistics)
    end
end

-- 追加统计信息
function AppendStatisticsInfo(statistics)
    if statistics.RoomID ~= m_RelativeRoomID then
        ResetStatisticsInfo(statistics)
    else
        if m_LastHandleRound < statistics.Round.CurrentRound then
            -- 刷新左侧的统计图
            for roundIndex = m_LastHandleRound + 1, math.ceil(statistics.Round.CurrentRound / m_Left_OffsetY) * m_Left_OffsetY, 1 do
                local roundItem = m_Left_StatisticsRoot:Find('Item' .. roundIndex)
                SetTrendItemResult(roundItem, statistics.Trend[roundIndex])
            end
            -- 刷新右侧的统计图
            for roundIndex = m_LastHandleRound + 1, statistics.Round.CurrentRound, 1 do
                AppendRightStatisticsTrendValue(statistics.Trend[roundIndex])
            end
            ResetStatisticsRootToRightVisible(statistics.Round.CurrentRound)
            RefreshStatisticsCountsByStatistics(statistics)
            m_LastHandleRound = statistics.Round.CurrentRound
        else
            ResetStatisticsInfo(statistics)
        end
    end
end

-- 刷新统计趋势图，数量
function RefreshStatisticsTrendByStatistics(statistics)
    RefreshLeftStatisticsTrendByStatistics(statistics)
    RefreshRightStatisticsTrendByStatistics(statistics)
    RefreshStatisticsCountsByStatistics(statistics)
    ResetStatisticsRootToRightVisible(statistics.Round.CurrentRound)
end

-- 刷新左侧统计趋势图
function RefreshLeftStatisticsTrendByStatistics(statistics)
    local roundCount = statistics.Round.CurrentRound
    local displayCount = math.ceil(roundCount / m_Left_OffsetY) * m_Left_OffsetY
    if displayCount < m_Left_DisplayColumnCount * m_Left_OffsetY then
        displayCount = m_Left_DisplayColumnCount * m_Left_OffsetY
    end
    for roundIndex = 1, m_Left_ItemCount, 1 do
        local roundItem = m_Left_StatisticsRoot:Find('Item' .. roundIndex)
        if roundIndex > displayCount then
            roundItem.gameObject:SetActive(false)
        else
            local roundResult = statistics.Trend[roundIndex]
            SetTrendItemResult(roundItem, roundResult)
        end
    end
end

function SetTrendItemResult(roundItem, roundResult)
    roundItem.gameObject:SetActive(true)
    local valueIcon = roundItem.transform:Find('ValueIcon'):GetComponent("Image")
    if roundResult ~= nil then
        valueIcon.gameObject:SetActive(true)
        local spriteName = GetTrendResultSpriteOfTrendItem(roundResult)
        valueIcon:ResetSpriteByName(spriteName)
        roundItem:Find("BaoZi").gameObject:SetActive(CS.Utility.GetLogicAndValue(roundResult, WIN_CODE.LONGHUBAOZI) == WIN_CODE.LONGHUBAOZI)
        roundItem:Find("LongJinHua").gameObject:SetActive(CS.Utility.GetLogicAndValue(roundResult, WIN_CODE.LONGJINHUA) == WIN_CODE.LONGJINHUA)
        roundItem:Find("HuJinHua").gameObject:SetActive(CS.Utility.GetLogicAndValue(roundResult, WIN_CODE.HUJINHUA) == WIN_CODE.HUJINHUA)
    else
        valueIcon.gameObject:SetActive(false)
        roundItem:Find("BaoZi").gameObject:SetActive(false)
        roundItem:Find("LongJinHua").gameObject:SetActive(false)
        roundItem:Find("HuJinHua").gameObject:SetActive(false)
    end
end

-- 刷新右侧统计趋势图
function RefreshRightStatisticsTrendByStatistics(statistics)
    m_Right_TrendTable = { }
    m_Right_LastPos = 0
    m_Right_LastUpdateValue = 0
    m_Right_IsDeflected = false
    local initDisplayCount = m_Right_DisplayColumnCount * m_Right_OffsetY
    m_Right_CurrentMaxDisplayPos = initDisplayCount
    for index = 1, m_Right_ItemCount, 1 do
        local trendItem = m_Right_StatisticsRoot:Find('Item' .. index)
        if index > initDisplayCount then
            trendItem.gameObject:SetActive(false)
        end
        trendItem:Find("ValueIcon").gameObject:SetActive(false)
        trendItem:Find("BaoZi").gameObject:SetActive(false)
        trendItem:Find("LongJinHua").gameObject:SetActive(false)
        trendItem:Find("HuJinHua").gameObject:SetActive(false)
    end

    for roundIndex = 1, statistics.Round.CurrentRound, 1 do
        AppendRightStatisticsTrendValue(statistics.Trend[roundIndex])
    end
end

function ResetStatisticsRootToRightVisible(roundCount)
    local leftDisplayCount = math.max(math.ceil(roundCount / m_Left_OffsetY), m_Left_DisplayColumnCount)
    local leftPosX = m_Left_StatisticsRoot.parent.rect.size.x - leftDisplayCount * m_Left_ItemSize
    local leftLocalPos = m_Left_StatisticsRoot.localPosition
    leftLocalPos.x = leftPosX
    m_Left_StatisticsRoot.localPosition = leftLocalPos

    local rightDisplayCount = math.max(math.ceil(m_Right_CurrentMaxDisplayPos / m_Right_OffsetY))
    local rightPosX =(m_Right_StatisticsRoot.parent.rect.size.x - rightDisplayCount * m_Right_ItemSize)
    local rightLocalPos = m_Right_StatisticsRoot.localPosition
    rightLocalPos.x = rightPosX
    m_Right_StatisticsRoot.localPosition = rightLocalPos
end

-- 追加统计值
function AppendRightStatisticsTrendValue(newValue)
    if m_Right_LastPos == 0 then
        m_Right_LastPos = 1
        m_Right_TrendTable[m_Right_LastPos] = newValue
        m_Right_LastUpdateValue = GetTrend2UpdateValue(newValue)
    else
        -- 下一个坐标点的valueIcon 是否显示，显示则转向
        if CS.Utility.GetLogicAndValue(newValue, m_Right_LastUpdateValue) == m_Right_LastUpdateValue then
            if isDeflected or m_Right_LastPos % m_Right_OffsetY == 0 then
                isDeflected = true
                m_Right_LastPos = m_Right_LastPos + m_Right_OffsetY
                m_Right_TrendTable[m_Right_LastPos] = newValue
            else
                if m_Right_TrendTable[m_Right_LastPos + 1] == nil then
                    m_Right_LastPos = m_Right_LastPos + 1
                    m_Right_TrendTable[m_Right_LastPos] = newValue
                else
                    m_Right_LastPos = m_Right_LastPos + m_Right_OffsetY
                    m_Right_TrendTable[m_Right_LastPos] = newValue
                    isDeflected = true
                end
            end
        else
            isDeflected = false
            -- 开辟新行
            local columnIndex = math.ceil(m_Right_LastPos / m_Right_OffsetY) + 1
            for i = columnIndex, 1, -1 do
                if m_Right_TrendTable[i * m_Right_OffsetY + 1] ~= nil then
                    break
                end
                columnIndex = i
            end
            m_Right_LastPos = columnIndex * m_Right_OffsetY + 1
            m_Right_TrendTable[m_Right_LastPos] = newValue
            m_Right_LastUpdateValue = GetTrend2UpdateValue(newValue)
        end
    end

    if m_Right_LastPos > m_Right_DisplayColumnCount * m_Left_OffsetY then
        local columnMax = math.ceil(m_Right_LastPos / m_Right_OffsetY) * m_Right_OffsetY
        for index = columnMax - m_Right_OffsetY, columnMax, 1 do
            m_Right_StatisticsRoot:Find('Item' .. index).gameObject:SetActive(true)
        end
    end
    -- 刷新当前最大的显示位置
    m_Right_CurrentMaxDisplayPos = math.max(m_Right_CurrentMaxDisplayPos, m_Right_LastPos)

    local trendItem = m_Right_StatisticsRoot:Find('Item' .. m_Right_LastPos)
    trendItem:Find('ValueIcon'):GetComponent("Image"):ResetSpriteByName(GetTrend2IconNameByValue(newValue))
    trendItem:Find("ValueIcon").gameObject:SetActive(true)
    trendItem:Find("BaoZi").gameObject:SetActive(CS.Utility.GetLogicAndValue(newValue, WIN_CODE.LONGHUBAOZI) == WIN_CODE.LONGHUBAOZI)
    trendItem:Find("LongJinHua").gameObject:SetActive(CS.Utility.GetLogicAndValue(newValue, WIN_CODE.LONGJINHUA) == WIN_CODE.LONGJINHUA)
    trendItem:Find("HuJinHua").gameObject:SetActive(CS.Utility.GetLogicAndValue(newValue, WIN_CODE.HUJINHUA) == WIN_CODE.HUJINHUA)
end

-- 刷新统计数量相关内容
function RefreshStatisticsCountsByStatistics(statistics)
    local rightBottom = this.transform:Find('RightBottom')
    rightBottom:Find('Row1/Item1/Value'):GetComponent("Text").text = tostring(statistics.Counts.LongWin)
    rightBottom:Find('Row1/Item2/Value'):GetComponent("Text").text = tostring(statistics.Counts.HuWin)
    rightBottom:Find('Row1/Item3/Value'):GetComponent("Text").text = tostring(statistics.Counts.HeJu)
    rightBottom:Find('Row1/Item4/Value'):GetComponent("Text").text = string.format("%d/%d", statistics.Round.CurrentRound, statistics.Round.MaxRound)
    rightBottom:Find('Row2/Item1/Value'):GetComponent("Text").text = tostring(statistics.Counts.LongJinHua)
    rightBottom:Find('Row2/Item2/Value'):GetComponent("Text").text = tostring(statistics.Counts.HuJinHua)
    rightBottom:Find('Row2/Item3/Value'):GetComponent("Text").text = tostring(statistics.Counts.LongHuBaoZi)
end

function GetTrendResultSpriteOfTrendItem(roundResult)
    if CS.Utility.GetLogicAndValue(roundResult, WIN_CODE.LONG) == WIN_CODE.LONG then
        return 'sprite_Trend_Icon_1'
    elseif CS.Utility.GetLogicAndValue(roundResult, WIN_CODE.HU) == WIN_CODE.HU then
        return 'sprite_Trend_Icon_2'
    elseif CS.Utility.GetLogicAndValue(roundResult, WIN_CODE.HE) == WIN_CODE.HE then
        return 'sprite_Trend_Icon_4'
    else
        return 'sprite_Trend_Icon_1'
    end
end

function GetTrend2IconNameByValue(value)
    if CS.Utility.GetLogicAndValue(value, WIN_CODE.LONG) == WIN_CODE.LONG then
        return 'sprite_hong'
    elseif CS.Utility.GetLogicAndValue(value, WIN_CODE.HU) == WIN_CODE.HU then
        return 'sprite_lan'
    elseif CS.Utility.GetLogicAndValue(value, WIN_CODE.HE) == WIN_CODE.HE then
        return 'sprite_lv'
    else
        return 'sprite_lv'
    end
end

-- 获取更新的值
function GetTrend2UpdateValue(value)
    if CS.Utility.GetLogicAndValue(value, WIN_CODE.LONG) == WIN_CODE.LONG then
        return WIN_CODE.LONG
    elseif CS.Utility.GetLogicAndValue(value, WIN_CODE.HU) == WIN_CODE.HU then
        return WIN_CODE.HU
    else
        return WIN_CODE.HE
    end
end