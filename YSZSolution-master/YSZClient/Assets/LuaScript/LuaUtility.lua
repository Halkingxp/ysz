-- 参数:待分割的字符串,分割字符
-- 返回:子串表.(含有空串)
function lua_string_split(str, split_char)
    local sub_str_tab = { }
    while (true) do
        local pos = string.find(str, split_char)
        if (not pos) then
            sub_str_tab[#sub_str_tab + 1] = str
            break
        end
        local sub_str = string.sub(str, 1, pos - 1)
        sub_str_tab[#sub_str_tab + 1] = sub_str
        str = string.sub(str, pos + #split_char, #str)
    end
    return sub_str_tab
end

-- 参数:数字
-- 返回:table 按照数字的大小排序
function lua_number_sort(...)
    local arg = { ...}
    table.sort(arg)
    return arg
end

-- 扩展传入table，让他具有vmt的功能
-- 暂时放這里等有了合适的地方再挪过去 by hc 2017-3-5
function Extends(tTable, vmt)
    local mt = { __index = vmt }
    setmetatable(tTable, mt)
    return tTable
end

-- 创建扩展表结果
function lua_NewTable(SourceTable)
    local tTable = { }
    local mt = { __index = SourceTable }
    setmetatable(tTable, SourceTable)
    return tTable
end

function lua_Transform_ClearChildren(transform, keepFirst)
    if transform ~= nil then
        local childCount = transform.childCount
        if childCount ~= 0 then
            local endFlag = 0
            if keepFirst then
                endFlag = 1
            end
            for index = childCount - 1, endFlag, -1 do
                CS.UnityEngine.Object.Destroy(transform:GetChild(index).gameObject)
            end
        end
    end
end

-- 删除指定名称的子Transform
function lua_Transform_RemoveChildByName(transform, removeWithName)
    if transform ~= nil and removeWithName ~= nil then
        local childCount = transform.childCount
        if childCount ~= 0 then
            for index = childCount - 1, 0, -1 do
                if transform:GetChild(index).gameObject.name == removeWithName then
                    CS.UnityEngine.Object.Destroy(transform:GetChild(index).gameObject)
                end
            end
        end
    end
end

-- 粘贴Transform 的值(本地位置，缩放，朝向)
function lua_Paste_Transform_Value(transA, transB)
    if transA ~= nil and transB ~= nil then
        transA.localPosition = transB.localPosition
        transA.localRotation = transB.localRotation
        transA.localScale = transB.localScale
    end
end

function lua_RandomXYOfVector3(minX, maxX, minY, maxY)
    local localX = math.random(minX, maxX)
    local localY = math.random(minY, maxY)
    return CS.UnityEngine.Vector3(localX, localY, 0)
end

function lua_TableContainsValue(sourceTable, value)
    if sourceTable ~= nil then
        for k, v in pairs(sourceTable) do
            if v == value then
                return true
            end
        end
    end
    return false
end

-- 删除数字字符串的 逗号分隔符
function lua_Remove_CommaSeperate(numberStr)
    return(string.gsub(numberStr, ",", ""))
end

-- 给数字添加上万分号(1,2345,6789)
function lua_CommaSeperate(number)
    return lua_AddSplitCharToNumber(number, ",", 4)
end

-- 添加分割字符的标号
function lua_AddSplitCharToNumber(number, splitChar, interval)
    if number == nil then
        number = 0
    end

    if splitChar == nil then
        splitChar = ","
    end

    local sign = ""
    if math.abs(number) ~= number then
        sign = "-"
        number = math.abs(number)
    end

    t1, t2 = math.modf(number)
    -- print("整数 = "..t1.."小数 = "..t2)

    number = t1

    if interval == nil then
        interval = 1
    else
        interval = math.floor(interval)
        if interval < 1 then
            interval = 1
        end
    end

    local valueStr = tostring(number)
    local resultStr = ""
    while true do
        local strLength = #valueStr
        if strLength > interval then
            resultStr = splitChar .. string.sub(valueStr, strLength - interval + 1, strLength) .. resultStr
            valueStr = string.sub(valueStr, 1, strLength - interval)
        else
            resultStr = valueStr .. resultStr
            break
        end
    end

    if t2 < 0.01 then
        return sign .. resultStr
    else
        t3 = GameData.SubFloatZeroPart(string.format("%.2f", t2))
        t3 = string.sub(t3, 2)
        -- print("t3 = "..t3)
        -- t2 = string.format(".%d", math.floor(math.abs(t2) * 100))
        return sign .. resultStr .. t3
    end

end

-- Bool 变量取反
function lua_NOT_BOLEAN(value)
    if value then
        return false
    else
        return true
    end
end

-- Bool 字符串输出
function lua_BOLEAN_String(value)
    if value then
        return 'true'
    else
        return 'false'
    end
end

-- 数字转换为显示的字符串(如：2.00亿， 1.95万 )
function lua_NumberToStyle1String(number)
    if number == nil then
        return "0"
    end

    if number >= 100000000 then
        return GameData.SubFloatZeroPart(string.format("%.2f", number / 100000000)) .. "亿"
    elseif number >= 10000 then
        return GameData.SubFloatZeroPart(string.format("%.2f", number / 10000)) .. "万"
    else
        return GameData.SubFloatZeroPart(string.format("%.2f", number))
    end
end

function lua_Clear_AllUITweener(transform)
    CS.Utility.ClearAllUITweener(transform)
end

function lua_Call_GC()
    CS.Utility.CallGC()
end

function lua_Math_Mod(v1, v2)
    return CS.Utility.GetLuaMod(v1, v2)
end

-- 获得指定时间戳对应一年中的第几天
-- 第一参数: 系统时间戳
-- 参数说明: 若不传参数或参数小于等于2015-10-1日时间戳, 返回当前系统时间戳对应的天数
-- 返回说明: 起始时间从1970-01-01 08:00:00
-- 返回说明: 返回值为整型 (单位天)
function lua_GetTimeToYearDay(nTimestamp)
    if nTimestamp == nil or nTimestamp <= 1443628800 then
        local strDay = os.date("%j")
        return tonumber(strDay)
    else
        local strDay = os.date("%j", nTimestamp)
        return tonumber(strDay)
    end
end
