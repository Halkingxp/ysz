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
	
	LOGIN_REQUEST									= 200,				-- 登录请求
	DISCONNECT										= 201,				-- 断开连接
	
	SET_RMB											= 203,				-- 设置金币
	SET_GOLD										= 204,				-- 设置金币
	SET_FREEGOLD									= 205,				-- 设置免费金币
	SET_ROOM_CARD									= 206,				-- 设置房卡数量
	SET_CHARGE										= 207,				-- 设置充值RMB数量
	EXCHANGE_GOLD									= 208,				-- 钻石兑换金币
	EXCHANGE_ROOMCARD								= 209,				-- 钻石兑换房卡
	RECOVER_GAME									= 210,				-- 恢复游戏
	REQUEST_ACCOUNT_DATA							= 211,				-- 请求帐号信息
	REQUEST_ROOM_DATA								= 212,				-- 请求房间信息
	BIND_ACCOUNT									= 213,				-- 绑定帐号
	
	START_DENGDAI_STATE								= 332,				-- 开始等待状态
	START_XIPAI_STATE								= 333,				-- 开始洗牌状态
	START_QIEPAI_STATE								= 334,				-- 开始切牌状态
	OVER_QIEPAI_STATE								= 335,				-- 完成切牌状态
	START_BETTING_STATE								= 336,				-- 开始下注状态
	START_FIRING_STATE								= 337,				-- 开始发牌状态
	START_LONG_CUO_STATE							= 338,				-- 开始龙搓牌状态
	START_HU_CUO_STATE								= 339,				-- 开始虎搓牌状态
	START_SETTLEMENT_STATE							= 340,				-- 开始结算状态
	OVER_LONG_CUO_STATE								= 341,				-- 完成龙搓牌状态
	OVER_HU_CUO_STATE								= 342,				-- 完成虎搓牌状态
	
	START_DENGDAI									= 352,				-- 开始等待
	START_XIPAI										= 353,				-- 开始洗牌
	START_QIEPAI									= 354,				-- 开始切牌
	OVER_QIEPAI										= 355,				-- 完成切牌
	START_BETTING									= 356,				-- 开始下注
	START_FIRING									= 357,				-- 开始发牌
	START_LONG_CUO									= 358,				-- 开始龙搓牌
	START_HU_CUO									= 359,				-- 开始虎搓牌
	START_SETTLEMENT								= 360,				-- 通知本局结果
	OVER_LONG_CUO									= 361,				-- 完成龙搓牌
	OVER_HU_CUO										= 362,				-- 完成虎搓牌
	
	ENTER_ROOM										= 400,				-- 进入房间
	LEAVE_ROOM										= 401,				-- 离开房间	
	CREATE_VIP_ROOM									= 402,				-- 创建VIP房间
	BETTING											= 403,				-- 下注
	CUO_SITUATION									= 404,				-- 搓牌状况
	MING_CARD_COUNT									= 405,				-- 明牌数量
	UPDATE_RANK										= 406,				-- 更新下注排行榜
	GET_PARTIAL_STATISTICS							= 407,				-- 更新部分统计数据
	GET_ALL_STATISTICS								= 408,				-- 更新全部统计数据
	ADDITION_STATISTICS								= 409,				-- 追加统计数据
	GET_ENTER_VIP_LIST								= 410,				-- 请求进入过的VIP房间
	TOP_RANK										= 411,				-- 设置龙虎排行榜最高名次
	GET_GAME_DATA									= 412,				-- 设置游戏数据
	START_VIP_ROOM									= 413,				-- 开始VIP房间
	GAMES_TO_END									= 414,				-- 游戏局数已满
	CONTINUE_GAMES									= 415,				-- 续局游戏
	SET_ROOM_PLAYER									= 416,				-- 设置房间内人数
	APPLY_UP_BANKER									= 417,				-- 申请上庄
	GET_UP_BANKER_LIST								= 418,				-- 获得申请上庄列表
	NOTIFY_WIN_GOLD									= 420,				-- 通知本局赢钱数量
	UPDATE_BANKER									= 421,				-- 更新庄家消息
	UPDATE_BANKER_GOLD								= 422,				-- 更新庄家金币消息
	BANKER_QIEPAI									= 423,				-- 庄家切牌
	GET_PLAYER_LIST									= 424,				-- 请求玩家列表
	SHOUT_SLOGANS									= 425,				-- 搓牌喊口号
	CHANGE_HEAD_ID									= 426,				-- 修改头像ID
	VOICE_FORWARDING								= 427,				-- 语音转发
	APPLY_DOWN_BANKER								= 428,				-- 申请下庄
	GET_DOWN_BANKER									= 429,				-- 获取申请下庄状态
	
	
--------------------------------------------------------周边协议------------------------------------------------------------------
	S_Add_MoveNotice                                = 500,				-- 服务器通知添加跑马灯消息
	CS_SmallHorn                                    = 501,              -- 客户端请求发送小喇叭
	CS_SEND_EMAIL									= 502,				-- 客户端请求发送邮件
	CS_CHECK_ACCOUNTID								= 503,				-- 请求检查账号是否有效
	C_CHANGE_EMAIL_TO_READED     					= 505,				-- 请求改变邮件状态为已读
	CS_GET_EMAIL_REWARD								= 506,				-- 请求领取邮件内奖励
	CS_ADD_EMAILS									= 507,				-- 服务器发送邮件给客户端
	CS_DELETE_EMAIL									= 508,				-- 客户端请求删除邮件
	CS_MODIFY_NAME									= 509,				-- 修改昵称
	CS_ALL_RANK										= 510,				-- 发送排行榜数据
	CS_PAOPAO_CHAT							 		= 512, 				-- 房间聊天泡泡交互协议
	SETTLEMENT_LIST							 		= 513, 				-- 结算列表
	
--------------------------------------------------------推广员协议--------------------------------------------------------
	BIND_CODE										= 601,				-- 绑定邀请码
	UPDATE_SALESMAN									= 602,				-- 更新推广员状态

--------------------------------------------------------机器人协议--------------------------------------------------------
	CREATE_ROBOT									= 700,				-- 创建机器人
	GET_ROOM_INFO									= 701,				-- 获取房间信息
    
--------------------------------------------------------测试协议--------------------------------------------------------
--	TEST_CHARGE										= 900,				-- 测试充值
--	TEST_PAUSE										= 901,				-- 测试充值
	
--------------------------------------------------------后台协议--------------------------------------------------------
	SET_SALESMAN									= 1000,				-- 设置为推销员
	BACKSTAGE_EMAIL									= 1001,				-- 后台邮件
	SHOW_PASSWORD									= 1002,				-- 通知显示密码
	UPDATE_APPLY									= 1003,				-- 更新申请推广员状态
	SET_FUNCTION									= 1004,				-- 设置游戏功能
	SET_FROZEN										= 1005,				-- 设置帐号冻结时间
	SET_VIPLV										= 1006,				-- 设置帐号VIP等级
	BACKSTAGE_SPEAKER								= 1007,				-- 后台小喇叭
}

MessageMgr:RegCallbackFun(PROTOCOL.GET_ROOM_INFO, HandleGetRoomInfo)       		    -- 获取房间数据
MessageMgr:RegCallbackFun(PROTOCOL.CREATE_ROBOT, HandleCreateRobot)        		    -- 创建机器人
MessageMgr:RegCallbackFun(PROTOCOL.SETTLEMENT_LIST, HandleSettlementList)		    -- 结算列表
MessageMgr:RegCallbackFun(PROTOCOL.BACKSTAGE_SPEAKER, HandleBackstageSpeaker)		-- 后台小喇叭
MessageMgr:RegCallbackFun(PROTOCOL.SET_VIPLV, HandleBackstageVIPLv)					-- 后台设置帐号VIP等级
MessageMgr:RegCallbackFun(PROTOCOL.SET_FROZEN, HandleBackstageFrozen)				-- 后台设置帐号冻结时间
MessageMgr:RegCallbackFun(PROTOCOL.SET_FUNCTION, HandleBackstageSetFunction)		-- 后台设置游戏功能
MessageMgr:RegCallbackFun(PROTOCOL.SET_SALESMAN, HandleBackstageSetSalesman)		-- 后台设置推销员
MessageMgr:RegCallbackFun(PROTOCOL.BACKSTAGE_EMAIL, HandleBackstageEmail)			-- 后台设置推销员
MessageMgr:RegCallbackFun(PROTOCOL.SHOW_PASSWORD, HandleBackstagePassword)			-- 通知显示密码
MessageMgr:RegCallbackFun(PROTOCOL.UPDATE_APPLY, HandleBackstageApply)				-- 更新申请推广员状态
MessageMgr:RegCallbackFun(PROTOCOL.BIND_CODE, HandleBindCode)						-- 绑定邀请码
MessageMgr:RegCallbackFun(PROTOCOL.BIND_ACCOUNT, HandleBindAccount)					-- 绑定帐号
MessageMgr:RegCallbackFun(PROTOCOL.SHOUT_SLOGANS, HandleShoutSlogans)				-- 搓牌喊口号
MessageMgr:RegCallbackFun(PROTOCOL.CHANGE_HEAD_ID, HandleChangeHeadID)				-- 修改头像ID
MessageMgr:RegCallbackFun(PROTOCOL.VOICE_FORWARDING, HandleVoiceForwarding)			-- 语音转发

--MessageMgr:RegCallbackFun(PROTOCOL.TEST_CHARGE, TestCharge)							-- 测试充值
--MessageMgr:RegCallbackFun(PROTOCOL.TEST_PAUSE, TestPause)							-- 测试暂停和恢复

-- 定义该工程内收到消息时的回调函数
MessageMgr:RegCallbackFun(PROTOCOL.SS_SAVE_ALL, HandleSaveAll)						-- 回存所有数据
MessageMgr:RegCallbackFun(PROTOCOL.SDK_PAY_ORDER_RESULT, HandlePayOrder)			-- 支付成功消息


MessageMgr:RegCallbackFun(PROTOCOL.LOGIN_REQUEST, HandleLogin)						-- 客户端请求登录游戏
MessageMgr:RegCallbackFun(PROTOCOL.SS_CLOSE_CONNECT, HandleCloseConnect)			-- 客户端断开连接 

MessageMgr:RegCallbackFun(PROTOCOL.RECOVER_GAME, HandleRecoverGame)					-- 恢复游戏
MessageMgr:RegCallbackFun(PROTOCOL.REQUEST_ACCOUNT_DATA, HandleRequestAccount)		-- 请求帐号信息
MessageMgr:RegCallbackFun(PROTOCOL.REQUEST_ROOM_DATA, HandleRequestRoom)			-- 请求房间信息


MessageMgr:RegCallbackFun(PROTOCOL.EXCHANGE_GOLD, HandleExchangeGold)				-- 金币兑换金币
MessageMgr:RegCallbackFun(PROTOCOL.EXCHANGE_ROOMCARD, HandleExchangeRoomCard)		-- 金币兑换房卡

MessageMgr:RegCallbackFun(PROTOCOL.START_DENGDAI_STATE, HandleStartDengDai)			-- 开始等待
MessageMgr:RegCallbackFun(PROTOCOL.START_XIPAI_STATE, HandleStartXiPai)				-- 开始洗牌
MessageMgr:RegCallbackFun(PROTOCOL.START_QIEPAI_STATE, HandleStartQiePai)			-- 开始切牌
MessageMgr:RegCallbackFun(PROTOCOL.OVER_QIEPAI_STATE, HandleOverQiePai)				-- 完成切牌
MessageMgr:RegCallbackFun(PROTOCOL.START_BETTING_STATE, HandleStartBetting)			-- 开始下注
MessageMgr:RegCallbackFun(PROTOCOL.START_FIRING_STATE, HandleStartFiring)			-- 开始发牌
MessageMgr:RegCallbackFun(PROTOCOL.START_LONG_CUO_STATE, HandleStartLongCuo)		-- 开始龙搓牌
MessageMgr:RegCallbackFun(PROTOCOL.START_HU_CUO_STATE, HandleStartHuCuo)			-- 开始虎搓牌
MessageMgr:RegCallbackFun(PROTOCOL.START_SETTLEMENT_STATE, HandleStartSettlement)	-- 开始结算
MessageMgr:RegCallbackFun(PROTOCOL.OVER_LONG_CUO_STATE, HandleOverLongCuo)			-- 完成龙搓牌
MessageMgr:RegCallbackFun(PROTOCOL.OVER_HU_CUO_STATE, HandleOverHuCuo)				-- 完成虎搓牌


MessageMgr:RegCallbackFun(PROTOCOL.ENTER_ROOM, HandleEnterRoom)						-- 进入房间
MessageMgr:RegCallbackFun(PROTOCOL.LEAVE_ROOM, HandleLeaveRoom)						-- 离开房间


MessageMgr:RegCallbackFun(PROTOCOL.CREATE_VIP_ROOM, HandleCreateVIPRoom)			-- 创建VIP房间
MessageMgr:RegCallbackFun(PROTOCOL.START_VIP_ROOM, HandleStartVIPRoom)				-- 开始VIP房间
MessageMgr:RegCallbackFun(PROTOCOL.CONTINUE_GAMES, HandleContinueVIPRoom)			-- 续局VIP房间


MessageMgr:RegCallbackFun(PROTOCOL.BETTING, HandleBetting)							-- 下注
MessageMgr:RegCallbackFun(PROTOCOL.CUO_SITUATION, HandleCuoSituation)				-- 搓牌状况
MessageMgr:RegCallbackFun(PROTOCOL.MING_CARD_COUNT, HandleMingCardCount)			-- 明牌数量
MessageMgr:RegCallbackFun(PROTOCOL.GET_PARTIAL_STATISTICS, HandleGetPartialStatData)-- 更新部分统计数据
MessageMgr:RegCallbackFun(PROTOCOL.GET_ENTER_VIP_LIST, HandleGetVIPRoomList)		-- 请求进入过的VIP房间列表
MessageMgr:RegCallbackFun(PROTOCOL.APPLY_UP_BANKER, HandleApplyUpBanker)			-- 申请上庄
MessageMgr:RegCallbackFun(PROTOCOL.APPLY_DOWN_BANKER, HandleApplyDownBanker)		-- 申请下庄
MessageMgr:RegCallbackFun(PROTOCOL.GET_DOWN_BANKER, HandleGetDownBanker)			-- 获取申请下庄状态
MessageMgr:RegCallbackFun(PROTOCOL.GET_UP_BANKER_LIST, HandleGetUpBankerList)		-- 获得申请上庄列表
MessageMgr:RegCallbackFun(PROTOCOL.BANKER_QIEPAI, HandleBankerQiePai)				-- 庄家选择切第几张牌
MessageMgr:RegCallbackFun(PROTOCOL.GET_PLAYER_LIST, HandleGetPlayerList)			-- 请求玩家列表


MessageMgr:RegCallbackFun(PROTOCOL.SS_ONE_MINUTE_UPDATE, OneMinuteUpdate)			-- 每分钟更新一次
MessageMgr:RegCallbackFun(PROTOCOL.SS_ONE_HOUR_UPDATE, OneHourUpdate)				-- 每小时更新一次
MessageMgr:RegCallbackFun(PROTOCOL.SS_FIVE_MINUTE_UPDATE, FiveMinuteUpdate)			-- 每五分钟更新一次
MessageMgr:RegCallbackFun(PROTOCOL.SS_NEXT_ZERO_UPDATE, HandleDailyZeroUpdate)		-- 每日零点触发
MessageMgr:RegCallbackFun(PROTOCOL.SS_NEXT_FIVE_UPDATE, HandleDailyElevenUpdate)		-- 每日五点触发
MessageMgr:RegCallbackFun(PROTOCOL.CS_SmallHorn, HandleSmallHorn)	            	-- 客户端请求发送小喇叭
MessageMgr:RegCallbackFun(PROTOCOL.CS_SEND_EMAIL, HandleSendEmail)	            	-- 客户端请求发送邮件
MessageMgr:RegCallbackFun(PROTOCOL.CS_CHECK_ACCOUNTID, HandleCheckAccountID)	    -- 客户端请求验证游戏账号有效性
MessageMgr:RegCallbackFun(PROTOCOL.C_CHANGE_EMAIL_TO_READED, HandleReadEmail)    	-- 客户端请求阅读邮件
MessageMgr:RegCallbackFun(PROTOCOL.CS_GET_EMAIL_REWARD, HandleGetEmailReward)	    -- 客户端请求领取邮件奖励
MessageMgr:RegCallbackFun(PROTOCOL.CS_DELETE_EMAIL, HandleDeleteEmail)	    		-- 客户端请求删除邮件
MessageMgr:RegCallbackFun(PROTOCOL.CS_MODIFY_NAME, HandleModifyName)				-- 客户端请求修改昵称
MessageMgr:RegCallbackFun(PROTOCOL.CS_ADD_EMAILS, HandleRequestEmails)				-- 客户端请求邮件信息
MessageMgr:RegCallbackFun(PROTOCOL.CS_ALL_RANK, HandleRequestRanks)					-- 客户端请求排行榜数据
MessageMgr:RegCallbackFun(PROTOCOL.CS_PAOPAO_CHAT, HandlePaoPaoChat)				-- 客户端发送泡泡聊天