print "Protocol.lua"

-- 定义该工程内收发的消息编号
-- 注:1 所有动态类型的size只能用2字节存储
PROTOCOL = 
{
    SS_CLOSE_CONNECT                   				= 99,             	-- 服务端与客户端断开连接通知	该协议编号在C++中也有定义
    SS_REQUEST_LUA                    				= 100,             	-- 调用Lua响应函数 				该协议编号在C++中也有定义
	SS_MAPING										= 108,              -- 关联SocketID					该协议编号在C++中也有定义
	SDK_PAY_ORDER_RESULT							= 113,			 	-- SDK订单处理结果				该协议编号在C++中也有定义
	SS_SAVE_ALL										= 120,			 	-- 关服回存所有数据				该协议编号在C++中也有定义
	
    SS_NEXT_ZERO_UPDATE                    			= 151,             	-- 下次零点更新
    SS_NEXT_FIVE_UPDATE                    			= 152,             	-- 下次五点更新
    SS_FIVE_MINUTE_UPDATE                    		= 153,             	-- 五分钟更新	
    SS_ONE_HOUR_UPDATE                    			= 154,             	-- 一小时更新	
    SS_ONE_MINUTE_UPDATE                    		= 155,             	-- 一分钟更新	
	
    FORGET_PASSWORD                                 = 160,              -- 忘记密码
    
    GET_VISITOR_CONFIG                              = 198,              -- 请求游客配置开关
    GET_SERVER_HOST_PORT                            = 199,              -- 请求服务器域名和Port
}

MessageMgr:RegCallbackFun(PROTOCOL.FORGET_PASSWORD, ForgetPassword)  			    -- 忘记密码
MessageMgr:RegCallbackFun(PROTOCOL.GET_VISITOR_CONFIG, GetVisitorConfig)  			-- 请求游客配置开关
MessageMgr:RegCallbackFun(PROTOCOL.GET_SERVER_HOST_PORT, GetServerHostAndPort)  	-- 请求服务器域名和Port
MessageMgr:RegCallbackFun(PROTOCOL.SS_MAPING, HandleGameMap)            			-- 与GameServer建立映射
MessageMgr:RegCallbackFun(PROTOCOL.SS_CLOSE_CONNECT, HandleCloseConnect)			-- 客户端断开连接 
MessageMgr:RegCallbackFun(PROTOCOL.SS_FIVE_MINUTE_UPDATE, FiveMinuteUpdate)			-- 每五分钟更新一次
MessageMgr:RegCallbackFun(PROTOCOL.SS_NEXT_ZERO_UPDATE, HandleDailyZeroUpdate)		-- 每日零点触发
MessageMgr:RegCallbackFun(PROTOCOL.SS_NEXT_FIVE_UPDATE, HandleDailyFiveUpdate)		-- 每日五点触发