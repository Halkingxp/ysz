ProtrocolID =
{    --Hub服务器协议
    CS_SEND_CODE_TO_HUB                      = 110,-- 给服务器发送验证code
    CS_SEND_CREATE_ORDER_TO_HUB              = 111,-- 给服务器发送创建订单协议
    
    
    S_SFT_PAY_RESULT                         = 113,-- 服务器通知盛付通支付结果
    CS_Visitor_Check                         = 198,-- 游客登录开关验证
    CS_Request_Game_Server                   = 199,-- 请求登陆服务器
    --gameserver服务器协议
    CS_Login                                 = 200,-- 登陆    
    S_Disconnect                             = 201,-- 断开连接    
    S_Update_Diamond                         = 203,-- 更新钻石数量    
    S_Update_Gold                            = 204,-- 更新金币数量    
    S_Update_FreeGold                        = 205,-- 更新免费金币    
    S_Update_RoomCard                        = 206,-- 更新房卡数量    
    S_Update_Charge                          = 207,-- 更新充值人名币    
    CS_Convert_Gold                          = 208,-- 兑换金币    
    CS_Convert_RoomCard                      = 209,-- 兑换房卡
    CS_RECOVER_GAME                          = 210,-- 恢复游戏
    CS_REQUEST_ACCOUNT_DATA                  = 211,-- 请求帐号信息
    CS_REQUEST_ROOM_DATA                     = 212,-- 请求房间信息
    CS_BIND_ACCOUNT                          = 213,-- 绑定账号交互
    
    S_Notify_Wait_State                      = 352, -- 进入等待状态
    S_Notify_Shuffle_State                   = 353, -- 进入洗牌状态
    S_Notify_Cut_State                       = 354, -- 进入切牌状态
    S_Notify_Play_Cut_State                  = 355, -- 进入切牌动画
    S_Notify_Bet_State                       = 356, -- 进入押注状态
    S_Notify_Deal_State                      = 357, -- 进入发牌状态
    S_Notify_Long_Check_State                = 358, -- 进入龙看牌
    S_Notify_Hu_Check_State                  = 359, -- 进入虎看牌
    S_Notify_Settlement_State                = 360, -- 进入结算状态    
    S_Notify_Check1_Over                     = 361, -- 龙看牌结束
    S_Notify_Check2_Over                     = 362, -- 虎看牌结束
    
    CS_Enter_Room                            = 400, -- 进入房间    
    CS_Exit_Room                             = 401, -- 请求离开房间
    CS_Create_Room                           = 402, -- 创建Vip房间
    CS_Bet                                   = 403, -- 下注    
    CS_Check_Card_Process                    = 404, -- 客户端看牌过程
    CS_Checked_Card                          = 405, -- 客户端明牌数量
    S_Bet_Rank_List                          = 406, -- 押注排行榜    
    CS_Request_Statistics                    = 407, -- 请求房间统计信息
    S_Room_Statistics                        = 408, -- 房间统计信息    
    S_Room_Append_Statistics                 = 409, -- 追加房间统计信息
        
    CS_Request_Relative_Room                 = 410, -- 请求关联的房间列表
    S_Set_Bet_First                          = 411, -- 设置龙虎排行榜第一名
    S_Set_Game_Data                          = 412,    -- 服务器设置游戏数据        
    CS_Vip_Start_Game                        = 413, -- 请求开始VIP房间游戏
    S_Notify_Game_End                        = 414, -- 通知房间局数已结束    
    CS_Request_Continue_Game                 = 415,    -- 请求续局    
    S_Notify_Game_Player_Count               = 416,    -- 服务器设置房间内人数
    CS_Up_Banker                             = 417, -- 申请上庄    
    CS_Up_Banker_List                        = 418, -- 请求上庄列表
    
    S_Notify_Win_Gold                        = 420, -- 通知赢钱数量
    S_Update_Banker                          = 421, -- 更新庄家信息
    S_Update_Banker_Gold                     = 422, -- 通知更新庄家金币
    CS_Cut_Card                              = 423, -- 庄家切牌
    CS_Request_Role_List                     = 424, -- 请求玩家列表
    CS_Player_Cut_Type                       = 425, -- 玩家搓牌扑克花色尖叫
    CS_Player_Icon_Change                    = 426, -- 玩家头像Icon切换
    CS_Player_YuYinChat                      = 427, -- 玩家语音聊天    
    CS_Apply_Down_Banker                     = 428, -- 庄家申请下庄
    CS_Apply_Banker_State                    = 429, -- 庄家请求当前的状态
    

    ------------------------------------------------------游戏周边协议从这里开始定义--------------------------------------------

    S_Add_MoveNotice                         = 500,    -- 服务器通知添加跑马灯消息
    CS_SmallHorn                             = 501,    -- 请求发送小喇叭
    CS_SEND_EMAIL                            = 502,    -- 客户端请求发送邮件
    CS_CHECK_ACCOUNTID                       = 503,    -- 请求检查账号是否有效
    CS_OTHER_PLAYER_INFO                     = 504,    -- 请求其他玩家信息
    C_CHANGE_EMAIL_TO_READED                 = 505,    -- 请求改变邮件状态为已读
    CS_GET_EMAIL_REWARD                      = 506,    -- 请求领取邮件内奖励
    CS_ADD_EMAILS                            = 507,    -- 服务器发送邮件给客户端
    CS_DELETE_EMAIL                          = 508,    -- 客户端请求删除邮件
    CS_MODIFY_NAME                           = 509,    -- 客户端请求修改昵称
    CS_ALL_RANK                              = 510,    -- 请求产排行榜数据
    C_RETURN_GAME                            = 511, -- 客户端从切出状态返回游戏
    CS_PAOPAO_CHAT                           = 512, -- 房间聊天泡泡交互协议
    CS_Request_Game_History                  = 513, -- 请求游戏历史记录
    --------------------------------------------------------------------------------------------

    CS_Invite_Code                           = 601, -- 邀请码        
    S_Update_Promoter                        = 602, -- 更新推广员信息

    --=========================组局厅相关协议=====================================
    CS_JH_Create_Room                        = 801,  -- 组局厅请求创建房间
    CS_JH_Enter_Room1                        = 802,  -- 组局厅请求进入组局房间
    CS_JH_Enter_Room2                        = 803,  -- 组局厅请求进入闷鸡房间
    S_JH_Set_Game_Data                       = 804,  -- 组局厅反馈房间详细信息
    S_JH_Next_State                          = 805,  -- 组局厅通知房间下一阶段
    S_JH_Add_Player                          = 806,  -- 组局厅通知新增一个玩家
    S_JH_Delete_Player                       = 807,  -- 组局厅通知删除一个玩家
    CS_JH_Exit_Room                          = 808,  -- 组局厅请求离开房间(以及反馈)
    CS_JH_Ready                              = 809,  -- 组局厅玩家准备(以及反馈)
    CS_JH_Betting                            = 810,  -- 组局厅玩家下注(加注,跟注)
    CS_JH_VS_Card                            = 811,  -- 组局厅玩家请求比牌(反馈)
    CS_JH_Drop_Card                          = 812,  -- 组局厅玩家请求弃牌(反馈广播)
    CS_JH_Look_Card                          = 813,  -- 组局厅玩家请求看牌(反馈广播)
    S_JH_Notify_Look_Card                    = 814,  -- 服务器广播**看牌
    


    --------------------------------------------------------------------------------------------
    CS_Buy_Goods                             = 900, -- 购买商品
}