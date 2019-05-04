print "CommonFun.lua"


LF  = "\n"		-- 换行符
CR  = "\r"		-- 回车符
NLF = "■BR■"	-- 替换成新的换行符标识


--函数功能：创建一个只读的表(对子表无效，子表如果需要只读，需要单独调用此函数)
----------------------------------------------------------------------------------------------
function ConstTable(tTable)
setmetatable(tTable, { __index = function (t,k)
	LogError{"Can't Visit:["..k.."]"}
	end})
	
	local proxy = {}
	function proxy:Traverse()
		return getmetatable(self).__index
	end
	
	local mt = {
	__index = tTable,
	__newindex = function (t,k,v)
		LogError{"Can't Assignment:["..k.."] = ["..v.."]"}
	end
	}
	setmetatable(proxy, mt)
	return proxy
end

--函数功能：创建不能被外界定义变量的表
----------------------------------------------------------------------------------------------
function ProhibitExternalDef(tTable, vmt)
	local mt = {
	__index = vmt,
	__newindex = function (t,k,v)
		LogError{"Can't Build Varible:["..k.."]"}
	end
	}
	setmetatable(tTable, mt)
	return tTable
end

--函数功能: 让tTable继承vmt函数和变量
function Extends(tTable, vmt)
	local mt = {__index = vmt}
	setmetatable(tTable, mt)
	return tTable
end


-- 函数功能:错误日志
----------------------------------------------------------------------------------------------
function LogError(...)
	local strTrace = debug.traceback()
	local strContent = "◤"..string.format(table.unpack(...)).." ◥".."\n"..strTrace
	c_Errorlog(strContent)
	
	-- 此函数会跳过后面的所有代码, 考虑是否该取消?
	--error(strContent)
end

function LogInfo(...)
	local strContent = "◤"..string.format(table.unpack(...)).." ◥"
	c_Loglog(strContent)
end

function PrintInfo(...)
	print(string.format(table.unpack(...)))
end

function PrintLog(...)
	local nIsWriteLog = c_IsWriteLog()
	if nIsWriteLog > 0 then
		local strContent = string.format(table.unpack(...))
		c_Loglog(strContent)
	end
end

-- 自定义方式组装字符串
function MakeString(...)
	local strContent = string.format(table.unpack(...))
	return strContent
end

-- 字符串替换函数
-- 第一参数: 原始字符串
-- 第二参数: 要替换的字符串或匹配模式
-- 第三参数: 替换成目标字符串
-- 返回说明: 返回替换后的字符串, (注意: 本来返回多个参数, 打括号后只返回字符串)
function StringSub(strString, strPattern, strReplacement)
	local strContent = string.gmatch(strString, strPattern, strReplacement)
	return (strContent)
end

-- 字符串比较函数
-- 第一参数: 原始字符串
-- 第二参数: 要替换的字符串或匹配模式
-- 返回说明: 如果有匹配字符串, 返回其实下标
-- 返回说明: 如果没有匹配字符串, 返回nil
function StringFind(strString, strPattern)
	local nRet = string.find(strString, strPattern)
	return nRet
end


-- 加载配置
----------------------------------------------------------------------------------------------
function Load_Config(strFiledir)
	local cFile = io.open(strFiledir, "r")
	if cFile == nil then
		LogError{"Load_Config Error:%s", strFiledir}
	end
	
	local tTable_Config = {
	tPrd = {},	-- 前缀描述表
	tData = {}	-- 配置数据
	}
	
	local function ParseConfig()
		local strContent = cFile:read()
		if strContent == nil then
			return nil
		end
		
		local t = {}
		--非空格 and 非 " 进行匹配
		
		for v in string.gmatch(strContent, "[^\"]+") do
			if v ~= "	" then -- 非常之奇怪的字符，但是可以肯定不是空格	
			    table.insert(t,v)
			end
		end
		
		return t
	end
	
	tTable_Config.tPrd = {tDes=ParseConfig(), tIndex=ParseConfig(), tType=ParseConfig(), tCS=ParseConfig()}
	local tData = ""
	local nCount = 5
	local nSize = #tTable_Config.tPrd.tIndex
	local tConfData = tTable_Config.tData
	while 1 do
		local tData = ParseConfig()
		if not tData then
			break
		end
		
		local tTemp = {}
		local nDataSize = #tData
		if nDataSize ~= nSize then
			LogError{strFiledir.." Load_Config Error,TotalNum:["..nSize.."] Field Num Of Line:["..nDataSize.."] LineNum:["..nCount.."]"}
		end
		-- 先填充索引
		local tType = tTable_Config.tPrd.tType
		local tCS = tTable_Config.tPrd.tCS
		local tIndex = tTable_Config.tPrd.tIndex
		for i=1,nSize do
			if string.find(tCS[i],"s") ~= nil then
				local nIndex = tonumber(tIndex[i])
				if tType[i] == "string" then
					tTemp[nIndex or tIndex[i]] = tData[i]
				elseif tType[i] == "table" then
				    tTemp[nIndex or tIndex[i]] = Tokenizer(tData[i])
				else
					tTemp[nIndex or tIndex[i]] = tonumber(tData[i])
				end
			end
		end
		tConfData[tTemp.TemplateID] = tTemp
		nCount = nCount + 1
	end
	io.close(cFile)
	return tTable_Config
end

-- 屏蔽字
if SHIELD_WORD == nil then
	SHIELD_WORD =
	{
	  "select",  "insert",  "update",  "delete",  "create",  "drop",  "reload",  "where",  "and",  "or",  "exec",
	  "count",  "mid",  "truncate",  "declare",  "xp_",  "sp_",  "-",  "*",  "\"",  "'",  "+",  ";",
	}
end

-- 判断字符串中包含屏蔽词
function HaveShieldWord(strString)
	local nIndex = nil
	for k,v in ipairs(SHIELD_WORD) do
		nIndex = string.find(strString, v)
		if nIndex ~= nil then
			return true
		end
	end
	return false
end

-- 转换SQL通配符
function ConvertSQLWildcard(strSQL_Syntax)
	local tShield = {["["] = "[[]", ["_"] = "[_]" , ["%"] = "[%]" , ["^"] = "[^]"}
	strSQL_Syntax = string.gmatch(strSQL_Syntax, "%p", tShield)
	return strSQL_Syntax;
end

-- 函数功能: 脚本执行sql，
-- 参数1 语法  
-- 参数2 执行结果回调函数 
-- 函数必须要一个参数
----------------------------------------------------------------------------------------------
function SQLQuery(strSQL_Syntax, strCallback)
	if type(strSQL_Syntax) ~= "string" then
		LogError{"SQL_Syntax Type Error:[%s]", type(strSQL_Syntax)}
		return
	end
	
	if type(strCallback) ~= "string" then
		LogError{"Callback Type Error:[%s]", type(strCallback)}
		return
	end
	
	local tData = 
	{
		{STRING, strSQL_Syntax},      -- 语法
		{UINT8, 0},		  		  	  -- db类型(0 实例数据，1 日志数据)
		{UINT16, PROTOCOL.SS_REQUEST_LUA},
		{STRING, strCallback}
	}
	net:SendToDB(tData, PROTOCOL.SS_REQUEST_LUA)
end
	

-- 函数功能: 脚本执行sql，
-- 参数1 语法  
-- 函数必须要一个参数
----------------------------------------------------------------------------------------------
function SQLLog(strSQL_Syntax)
	if type(strSQL_Syntax) ~= "string" then
		LogError{"SQL_Syntax Type Error:[%s]", type(strSQL_Syntax)}
		return
	end
	
	local tData = 
	{
		{STRING, strSQL_Syntax},      -- 语法
		{UINT8, 1},		  		  	  -- db类型(0 实例数据，1 日志数据)
		{UINT16, 0},				  -- 无返回消息编号
	}
	net:SendToDB(tData, PROTOCOL.SS_REQUEST_LUA)
end

-- 字符串解析
-- 第一参数: 字符串
-- 返回说明: 将字符串中的整型数值解析到一个table中, 并返回
-- 返回说明: 解析格式 "1|3|5|7" 或 "1,2,5,6" 等
-- 备注说明: 字符串中只能是单字节符合, 任意符号均可
function Tokenizer(strString)
	local tTable = {}
	for v in string.gmatch(strString, "[%d-%-]+") do
		table.insert(tTable, tonumber(v))
	end	
	return tTable
end


--------------------------------------------------------------------------------------

-- 获取指定字符串时间格式的秒
-- 第一参数: 字符串时间格式  2016-03-11 12:59:59
-- 返回说明: 起始时间从1970-01-01 08:00:00
-- 返回说明: 返回值为整型 (单位秒)
function StringTimeToSecond(strDate)
	if strDate == nil then
		return 0		
	end
	
	local nTime = c_StringToTime(strDate)
	return nTime
end

-- 获取从进程运行到当前流逝的时间
-- 返回说明: 返回值为整型 (单位毫秒)
-- 使用说明: nStartTime = GetTimeToTick()
-- 使用说明: 执行代码或函数
-- 使用说明: nEndTime = GetTimeToTick();
-- 使用说明: nTick = nEndTime - nStartTime;
function GetSystemTimeToTick()
	local nClock = math.modf(os.clock() * 1000)
	return nClock
end

-- 获取当前系统时间戳
-- 返回说明: 起始时间从1970-01-01 08:00:00
-- 返回说明: 返回值为整型 (单位秒)
function GetSystemTimeToSecond()
	return os.time()
end

-- 获取当前GMT时间戳
-- 返回说明: 起始时间从1970-01-01 00:00:00
-- 返回说明: 返回值为整型 (单位秒)
function GetGMTTimeToSecond()
	return os.time() - 28800
end

-- 获得当前系统时间戳的格式化参数表
-- 第一参数: 若为nil, 返回当前时间戳对应的时间table
-- 第一参数: 若非nil, 返回指定时间戳对应的时间table
-- 返回说明: 返回格式化后的新表, 新表有以下字段
-- : year  : 年    例如2015	
-- : month : 月    取值范围[1~12]
-- : day   : 日    取值范围[1~31]
-- : hour  : 小时  取值范围[0~23]
-- : min   : 分钟  取值范围[0~59]
-- : sec   : 秒数  取值范围[0~59]
function GetTimeToTable(nTimestamp)
	nTimestamp = nTimestamp or os.time()
	local tDate = os.date("*t", nTimestamp)
	local tFormat = {}
	tFormat.year = tDate.year
	tFormat.month = tDate.month
	tFormat.day = tDate.day
	tFormat.hour = tDate.hour
	tFormat.min = tDate.min
	tFormat.sec = tDate.sec
	return tFormat
end

-- 获取系统时间戳的字符串
-- 参数说明: 系统时间戳 
-- 参数说明: 若不传参数或参数小于等于2015-10-1日时间戳, 返回当前系统时间戳的字符串
-- 返回说明: 起始时间从1970-01-01 08:00:00
-- 返回说明: 返回值为字符串, 格式 2015-09-26 23:59:59
function GetTimeToString(nTimestamp)
	if nTimestamp == nil or nTimestamp <= 1443628800 then
		return os.date("%Y-%m-%d %X")
	else
		return os.date("%Y-%m-%d %X", nTimestamp)
	end
end
-- 获取指定系统时间戳
-- 第一参数: 系统时间格式表, 通过GetTimeToTable函数获取
-- 返回说明: 起始时间从1970-01-01 08:00:00
-- 返回说明: 返回值为整型 (单位秒)
function GetTimeToSecond(tDate)
	return os.time(tDate)
end

-- 获得指定时间戳对应字符串日期格式
-- 第一参数: == nil, 返回当前时间戳对应的时间table
-- 第一参数: ~= nil, 返回指定时间戳对应的时间table
-- 返回说明: 格式1970_01_01
function GetTimeToFormateData(nTimestamp)
	nTimestamp = nTimestamp or os.time()
	return os.date("%Y_%m_%d", nTimestamp)
end

-- 获得指定时间戳对应一年中的第几天
-- 第一参数: 系统时间戳
-- 参数说明: 若不传参数或参数小于等于2015-10-1日时间戳, 返回当前系统时间戳对应的天数
-- 返回说明: 起始时间从1970-01-01 08:00:00
-- 返回说明: 返回值为整型 (单位天)
function GetTimeToYearDay(nTimestamp)
	if nTimestamp == nil or nTimestamp <= 1443628800 then
		local strDay = os.date("%j")
		return tonumber(strDay)
	else
		local strDay = os.date("%j", nTimestamp)
		return tonumber(strDay)
	end
end


-- 当前是否在指定时间范围内
-- 第一参数: [1]:小时 [2]分钟
-- 第二参数: [1]:小时 [2]分钟
-- 第一返回: 是否在指定时间范围内
-- 第二返回: 两时间相隔多少秒
function GetTimeInRange(tStartTime, tEndTime)
	local tNowTable = GetTimeToTable()
	local nNowTime = GetSystemTimeToSecond()
	
	-- 计算起始时间
	tNowTable.hour = tStartTime[1]
	tNowTable.min = tStartTime[2]
	tNowTable.sec = 0
	local nStartTime = GetTimeToSecond(tNowTable)
	
	-- 计算截止时间
	tNowTable.hour = tEndTime[1]
	tNowTable.min = tEndTime[2]
	tNowTable.sec = 0
	local nEndTime = GetTimeToSecond(tNowTable)
	if nNowTime >= nStartTime and nNowTime < nEndTime then
		local iInterval = GetDateInterval(nNowTime, nEndTime)
		return true, iInterval
	else
		return false, 0
	end	
end

-- 计算两个日期之间的时间差值
-- 第一参数: 起始日期时间戳
-- 第二参数: 结束日期时间戳
-- 返回说明: 返回相差的秒数
-- 返回说明: 返回值为整型 (单位秒)
-- 备注说明: 如果返回为负数, 表示起始时间在结束时间之后.需做合理处理.
function GetDateInterval(nStartTime, nEndTime)
	local iInterval = os.difftime(nEndTime, nStartTime)
	iInterval = math.modf(iInterval)
	return iInterval
end

-- 注册计时器
-- 第一参数: 注册触发时间, 从调用函数开始间隔多少秒触发
-- 第二参数: 重复次数, -1表示无限次; >0表示重复几次
-- 第三参数: 注册的协议编号
-- 第四参数: 注册的协议数据table, 通过Message:New创建的参数 (可以不传此参数)

-- 返回说明: 注册成功, 返回不可重复的计时器ID, ID>0
-- 返回说明: 注册失败, 返回0
-- 返回说明: 若没有中途停止计时器的需求, 可以不记录返回的计时器ID.
function RegistryTimer(nInterval, iCount, nProtocol, tProtocalData)
	if nInterval == nil then
		nInterval = 99999
	end
	
	if nProtocol == nil then
		LogError{"RegistryTimer, nProtocol:%d Error!", nProtocol}
		return 0
	end
	
	if iCount == nil or iCount == 0 then
		LogError{"RegistryTimer, iCount:%d Error!", iCount}
		return 0
	end
	
	-- 根据C函数的参数顺序传递参数
	local nTimerID = c_RegistryTimer(tProtocalData, nProtocol, iCount, nInterval)
	return nTimerID
end

-- 注销计时器
-- 第一参数: 计时器ID
-- 返回说明: 无返回值
function CancelTimer(nTimerID)
	c_CancelTimer(nTimerID)
end

-- 打印一个table 显示树形结构
function PrintTable(root, msg)
	local cache = {  [root] = "." }
	local function _dump(t,space,name)
		local temp = {}
		for k,v in pairs(t) do
			local key = tostring(k)
			if cache[v] then
				table.insert(temp,"+" .. key .. " {" .. cache[v].."}")
			elseif type(v) == "table" then
				local new_key = name .. "." .. key
				cache[v] = new_key
				table.insert(temp,"+" .. key .. _dump(v,space .. (next(t,k) and "|" or " " ).. string.rep(" ",#key),new_key))
			else
				table.insert(temp,"+" .. key .. " [" .. tostring(v).."]")
			end
		end
		return table.concat(temp,"\n"..space)
	end
	if msg ~= nil then
		print("PrintTable ->", msg)
		print(_dump(root, "",""))
	else
		print(_dump(root, "",""))
	end
end

-- 序列化table里所有数据,不支持table中有 函数，根据table的大小、复杂度以及序列化的使用频率，酌情使用此函数进行序列化
-- 反序列化直接 local t = load(Serialize(t))()
function Serialize(t, strMeta)
	local tMark = {}
	local tAssign = {}
	
	if not t then
		LogError{"Serialize t is nil"}
	end
	local function _ser_table(tbl, parent)
		tMark[tbl] = parent
		local tTemp = {}
		for k,v in pairs(tbl) do
			local key = type(k) == "number" and "["..k.."]" or k
			if type(v) == "table" then
				local dotkey = parent .. (type(k) == "number" and key or "." .. key)
				if tMark[v] then
					table.insert(tAssign,dotkey .. "=" .. tMark[v])
				else
					table.insert(tTemp, key .. "=" .. _ser_table(v, dotkey))
				end
			elseif type(v) == "string" then
				table.insert(tTemp, key .. "=" .. "\"" .. v.. "\"")
			else
				table.insert(tTemp, key .. "=" .. v)
			end
		end
		return "{" .. table.concat(tTemp, ",") .. "}"
	end
 
	
	local strMeta = strMeta and string.format("setmetatable(ret, {__index = %s})", strMeta) or ""
    return "do local ret = " .. _ser_table(t,"ret") .. table.concat(tAssign, " ") .. strMeta .. " return ret end"
end

function Serialize2(t, strMeta)
	local tMark = {}
	local tAssign = {}
	
	if not t then
		LogError{"Serialize t is nil"}
	end
	local function _ser_table(tbl, parent)
		tMark[tbl] = parent
		local tTemp = {}
		for k,v in ipairs(tbl) do
			local key = type(k) == "number" and "["..k.."]" or k
			if type(v) == "table" then
				local dotkey = parent .. (type(k) == "number" and key or "." .. key)
				if tMark[v] then
					table.insert(tAssign,dotkey .. "=" .. tMark[v])
				else
					table.insert(tTemp, key .. "=" .. _ser_table(v, dotkey))
				end
			elseif type(v) == "string" then
				table.insert(tTemp, key .. "=" .. "\"" .. v.. "\"")
			else
				table.insert(tTemp, key .. "=" .. v)
			end
		end
		return "{" .. table.concat(tTemp, ",") .. "}"
	end
	
	local strMeta = strMeta and string.format("setmetatable(ret, {__index = %s})", strMeta) or ""
    return "do local ret = " .. _ser_table(t,"ret") .. table.concat(tAssign, " ") .. strMeta .. " return ret end"
end


-- 根据性别随机名字
-- 需提前加载NameConfig配置
function RandomName(nSex)	
	if nSex == 0 then
		nSex = math.random(1,2)
	end
	local tXing = NameConfig.tXing
	local tBoyMing = NameConfig.tMing[SEX.BOY]
	local tGirlMing = NameConfig.tMing[SEX.GIRL]
	
	local nXing = math.random(1, #tXing)
	if nSex == SEX.BOY then
		local nMing = math.random(1, #tBoyMing)		
		local strName = tXing[nXing] .. tBoyMing[nMing]
		return strName
	else
		local nMing = math.random(1, #tGirlMing)		
		local strName = tXing[nXing] .. tGirlMing[nMing]
		return strName
	end
end

-- 将数组部分打乱顺序
function table.random(tArray)
	local nRandCount = #tArray - 1
	if nRandCount > 1 then
		local nPos = 0
		for i = 1, nRandCount do
			nPos = math.random(1, nRandCount)
			local tTemp = tArray[nRandCount + 1]
			tArray[nRandCount + 1] = tArray[nPos]
			tArray[nPos] = tTemp
			nRandCount = nRandCount - 1
		end
	end
end

-- 获取table中的元素个数, 包含map和array两部分的元素个数
function table.count(tTable)	
	if type(tTable) ~= "table" then
		return 0
	end
	
	local nCount = 0
	for _,v in pairs(tTable) do
		nCount = nCount + 1
	end
	return nCount
end

function table.add(tTable, Key, Value)
	if tTable[Key] == nil then
		tTable[Key] = Value
	else
		tTable[Key] = tTable[Key] + Value
	end
end

-- 判断是否是闰年
function IsLeapYear(year)
	if (year%400==0 or (year%4==0 and year%100 ~= 0)) then
        return true
	end
	return false
end

-- 判断年月的天数是否有效
function DayIsvalid(year, month, day)
	if month < 1 or month > 12 or day < 0 then
		return false
	end
	
	local tab31  = {[1] = 31, [3] = 31, [5] = 31, [7] = 31, [8] = 31, [10] = 31, [12] = 31}	
	local _31 = tab31[month]
	if nil ~= _31 then
		return day <= 31			
	end
	
	local tab30  = {[4] = 30, [6] = 30, [9] = 30, [11] = 30}
	local _30 = tab30[month]
	if nil ~= _30 then
		return day <= 30
	end
	
	if true == IsLeapYear(year) then
		return day <= 29	
	end
	
	return day <= 28
end

