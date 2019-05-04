--Export by excel config file, don't modify this file!
--[[
TemplateID(Column[A] Type[int] Desc[房间编号]
Type(Column[D] Type[int] Desc[房间类型]
MaxPlayer(Column[E] Type[int] Desc[人数上限]
UpBankerVIPLv(Column[F] Type[int] Desc[上庄VIP等级]
UpBankerGold(Column[G] Type[int] Desc[上庄金币下限]
DownBankerGold(Column[H] Type[int] Desc[庄家维持最低金币]
BettingLongHu(Column[I] Type[array] Desc[投注龙虎的上下限]
BettingBaoZi(Column[J] Type[array] Desc[投注豹子的上下限]
BettingJinHua(Column[K] Type[array] Desc[投注金花的上下限]
RunHorseCoinLowerLimit(Column[L] Type[int] Desc[播放跑马灯金币条件]
RoomLevel(Column[M] Type[int] Desc[房间等级]
]]--

RoomConfig =
{
    [1] =
    {
        TemplateID = 1,
        Type = 1,
        MaxPlayer = 50,
        UpBankerVIPLv = 0,
        UpBankerGold = 5000000,
        DownBankerGold = 3000000,
        BettingLongHu = { 100000, 15000000 },
        BettingBaoZi = { 10000, 950000 },
        BettingJinHua = { 10000, 1900000 },
        RunHorseCoinLowerLimit = 1000000,
        RoomLevel = 1,
    },
    [2] =
    {
        TemplateID = 2,
        Type = 1,
        MaxPlayer = 50,
        UpBankerVIPLv = 0,
        UpBankerGold = 5000000,
        DownBankerGold = 3000000,
        BettingLongHu = { 100000, 15000000 },
        BettingBaoZi = { 10000, 950000 },
        BettingJinHua = { 10000, 1900000 },
        RunHorseCoinLowerLimit = 1000000,
        RoomLevel = 1,
    },
    [3] =
    {
        TemplateID = 3,
        Type = 1,
        MaxPlayer = 50,
        UpBankerVIPLv = 0,
        UpBankerGold = 5000000,
        DownBankerGold = 3000000,
        BettingLongHu = { 100000, 15000000 },
        BettingBaoZi = { 10000, 950000 },
        BettingJinHua = { 10000, 1900000 },
        RunHorseCoinLowerLimit = 1000000,
        RoomLevel = 1,
    },
    [4] =
    {
        TemplateID = 4,
        Type = 1,
        MaxPlayer = 50,
        UpBankerVIPLv = 0,
        UpBankerGold = 50000000,
        DownBankerGold = 30000000,
        BettingLongHu = { 1000000, 150000000 },
        BettingBaoZi = { 100000, 9500000 },
        BettingJinHua = { 100000, 19000000 },
        RunHorseCoinLowerLimit = 3000000,
        RoomLevel = 2,
    },
    [5] =
    {
        TemplateID = 5,
        Type = 1,
        MaxPlayer = 50,
        UpBankerVIPLv = 0,
        UpBankerGold = 50000000,
        DownBankerGold = 30000000,
        BettingLongHu = { 1000000, 150000000 },
        BettingBaoZi = { 100000, 9500000 },
        BettingJinHua = { 100000, 19000000 },
        RunHorseCoinLowerLimit = 3000000,
        RoomLevel = 2,
    },
    [6] =
    {
        TemplateID = 6,
        Type = 1,
        MaxPlayer = 50,
        UpBankerVIPLv = 0,
        UpBankerGold = 50000000,
        DownBankerGold = 30000000,
        BettingLongHu = { 1000000, 150000000 },
        BettingBaoZi = { 100000, 9500000 },
        BettingJinHua = { 100000, 19000000 },
        RunHorseCoinLowerLimit = 3000000,
        RoomLevel = 2,
    },
    [7] =
    {
        TemplateID = 7,
        Type = 1,
        MaxPlayer = 50,
        UpBankerVIPLv = 0,
        UpBankerGold = 500000000,
        DownBankerGold = 300000000,
        BettingLongHu = { 10000000, 1500000000 },
        BettingBaoZi = { 1000000, 95000000 },
        BettingJinHua = { 1000000, 190000000 },
        RunHorseCoinLowerLimit = 30000000,
        RoomLevel = 3,
    },
    [201] =
    {
        TemplateID = 201,
        Type = 2,
        MaxPlayer = 50,
        UpBankerVIPLv = 0,
        UpBankerGold = 5000000,
        DownBankerGold = 3000000,
        BettingLongHu = { 100000, 15000000 },
        BettingBaoZi = { 10000, 950000 },
        BettingJinHua = { 10000, 1900000 },
        RunHorseCoinLowerLimit = -1,
        RoomLevel = -1,
    },
    [101] =
    {
        TemplateID = 101,
        Type = 3,
        MaxPlayer = 10,
        UpBankerVIPLv = 0,
        UpBankerGold = 5000000,
        DownBankerGold = 3000000,
        BettingLongHu = { 100000, 15000000 },
        BettingBaoZi = { 10000, 950000 },
        BettingJinHua = { 10000, 1900000 },
        RunHorseCoinLowerLimit = -1,
        RoomLevel = -1,
    },
    [102] =
    {
        TemplateID = 102,
        Type = 3,
        MaxPlayer = 10,
        UpBankerVIPLv = 0,
        UpBankerGold = 50000000,
        DownBankerGold = 30000000,
        BettingLongHu = { 1000000, 150000000 },
        BettingBaoZi = { 100000, 9500000 },
        BettingJinHua = { 100000, 19000000 },
        RunHorseCoinLowerLimit = -1,
        RoomLevel = -1,
    },
    [103] =
    {
        TemplateID = 103,
        Type = 3,
        MaxPlayer = 10,
        UpBankerVIPLv = 0,
        UpBankerGold = 500000000,
        DownBankerGold = 300000000,
        BettingLongHu = { 10000000, 1500000000 },
        BettingBaoZi = { 1000000, 95000000 },
        BettingJinHua = { 1000000, 190000000 },
        RunHorseCoinLowerLimit = -1,
        RoomLevel = -1,
    },
}

