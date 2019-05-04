print("UpdateMgr.lua")

local FunFormat = string.format



-- 注册下次每日零点更新计时器
function SetNextZeroUpdate()
	local tNextDaily = GetTimeToTable()
	tNextDaily.hour = 23
	tNextDaily.min = 59
	tNextDaily.sec = 59
	
	local nNowTime = GetSystemTimeToSecond()
	local nNextDailyTime = GetTimeToSecond(tNextDaily)
	local iInterval = GetDateInterval(nNowTime, nNextDailyTime)
	if iInterval <= 0 then
		iInterval = iInterval + ONE_DAY_SECOND
	end
	
	-- 注册计时器
	local nTimerID = RegistryTimer(iInterval, 1, PROTOCOL.SS_NEXT_ZERO_UPDATE)
	if nTimerID == 0 then
		-- 第一次注册失败, 再次注册
		iInterval = ONE_DAY_SECOND
		RegistryTimer(iInterval, 1, PROTOCOL.SS_NEXT_ZERO_UPDATE)
	end
	LogInfo{"注册每日零点更新计时器, 间隔%d秒", iInterval}
end

-- 注册下次每日五点更新计时器
function SetNextFiveUpdate()	
	local tNextDaily = GetTimeToTable()
	tNextDaily.hour = DAILY_UPDATE_TIME
	tNextDaily.min = 0
	tNextDaily.sec = 0
	
	local nNowTime = GetSystemTimeToSecond()
	local nNextDailyTime = GetTimeToSecond(tNextDaily)
	local iInterval = GetDateInterval(nNowTime, nNextDailyTime)
	if iInterval <= 0 then
		iInterval = iInterval + ONE_DAY_SECOND
	end
	
	-- 注册计时器
	local nTimerID = RegistryTimer(iInterval, 1, PROTOCOL.SS_NEXT_FIVE_UPDATE)
	if nTimerID == 0 then
		-- 第一次注册失败, 再次注册
		iInterval = ONE_DAY_SECOND
		RegistryTimer(iInterval, 1, PROTOCOL.SS_NEXT_FIVE_UPDATE)
	end
	LogInfo{"注册每日五点更新计时器, 间隔%d秒", iInterval}
end


-- 零点更新 由于触发此函数，并未到达明天这里提前增加明天的库
function HandleDailyZeroUpdate()
	
	-- 注册下次每日更新
	SetNextZeroUpdate()
	
--	-- 这里加3600是为了让时间到下一天
--	local nNowTime = GetSystemTimeToSecond() + 3600	
--	CreateDailyLog(nNowTime)	
end

-- 五点更新 函数内处理各种需要每日更新的逻辑
function HandleDailyFiveUpdate()
	
	-- 注册下次每日更新
	SetNextFiveUpdate()
	
	
	LogInfo{" GC -> Before Use Memory:%.02fM", collectgarbage("count") / 1024}
	collectgarbage()
	LogInfo{" GC -> After  Use Memory:%.02fM", collectgarbage("count") / 1024}
end

-- 每五分钟更新一次
function FiveMinuteUpdate()
end


--  创建道具日志表
function CreateDailyLog(nNowTime)
--[[	
	local strTime = GetTimeToString()
	local dateDay = GetTimeToYearDay(nNowTime)
	SQLLog(FunFormat("CREATE TABLE IF NOT EXISTS `log_item_%s` (\
	`log_ID` int(11) unsigned NOT NULL AUTO_INCREMENT COMMENT '序号',\
	`log_HeroID` int(11) unsigned NOT NULL DEFAULT '0' COMMENT 'HeroID',\
	`log_ItemID` int(11) unsigned NOT NULL DEFAULT '0' COMMENT '道具模版ID',\
	`log_ChangeCount` int(11) NOT NULL DEFAULT '0' COMMENT '改变数量',\
	`log_Count` int(11) unsigned NOT NULL DEFAULT '0' COMMENT '改变后剩余数量',\
	`log_Operate` int(11) unsigned NOT NULL DEFAULT '0' COMMENT '改变原因',\
	`log_Time` datetime NOT NULL DEFAULT '%s' COMMENT '改变时间',\
	PRIMARY KEY (`log_ID`)\
	) ENGINE=InnoDB AUTO_INCREMENT=1 DEFAULT CHARSET=utf8mb4 ROW_FORMAT=COMPACT;", dateDay, strTime))
	
	SQLLog(FunFormat("CREATE TABLE IF NOT EXISTS `log_equip_%s` (\
    `log_ID` int(11) unsigned NOT NULL AUTO_INCREMENT COMMENT '序号',\
    `log_HeroID` int(11) unsigned NOT NULL DEFAULT '0' COMMENT 'HeroID',\
    `log_Equip` text NOT NULL COMMENT '装备数据',\
    `log_Operate` int(11) unsigned NOT NULL DEFAULT '0' COMMENT '操作原因',\
    `log_Time` datetime NOT NULL DEFAULT '2016-01-01 00:00:00' COMMENT '时间',\
    PRIMARY KEY (`log_ID`)\
    ) ENGINE=InnoDB AUTO_INCREMENT=1 DEFAULT CHARSET=utf8mb4 ROW_FORMAT=COMPACT;", dateDay, strTime))
--]]
end