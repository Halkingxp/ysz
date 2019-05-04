--Export by excel config file, don't modify this file!
--[[
TemplateID(Column[A] Type[int] Desc[房间编号]
ShowName(Column[B] Type[string] Desc[显示房间名]
Type(Column[D] Type[int] Desc[房间类型]
MaxPlayer(Column[E] Type[int] Desc[人数上限]
UpBankerVIPLv(Column[F] Type[int] Desc[上庄VIP等级]
UpBankerGold(Column[G] Type[int] Desc[上庄金币下限]
DownBankerGold(Column[H] Type[int] Desc[庄家维持最低金币]
BettingLongHu(Column[I] Type[array] Desc[投注龙虎的上下限]
BettingBaoZi(Column[J] Type[array] Desc[投注豹子的上下限]
BettingJinHua(Column[K] Type[array] Desc[投注金花的上下限]
CanUseChip(Column[N] Type[array] Desc[可用筹码]
AutoSelectChip(Column[O] Type[int] Desc[自动选择筹码]
CenterOnChild(Column[P] Type[int] Desc[进入时居中的筹码索引]
]]--

data.RoomConfig =
{
    [1] =
    {
        TemplateID = 1,
        ShowName = "001",
        Type = 1,
        MaxPlayer = 50,
        UpBankerVIPLv = 0,
        UpBankerGold = 5000000,
        DownBankerGold = 3000000,
        BettingLongHu = { 100000, 15000000 },
        BettingBaoZi = { 10000, 950000 },
        BettingJinHua = { 10000, 1900000 },
        CanUseChip = { 1, 2, 3, 4, 5, 6, 7 },
        AutoSelectChip = 2,
        CenterOnChild = 3,
    },
    [2] =
    {
        TemplateID = 2,
        ShowName = "002",
        Type = 1,
        MaxPlayer = 50,
        UpBankerVIPLv = 0,
        UpBankerGold = 5000000,
        DownBankerGold = 3000000,
        BettingLongHu = { 100000, 15000000 },
        BettingBaoZi = { 10000, 950000 },
        BettingJinHua = { 10000, 1900000 },
        CanUseChip = { 1, 2, 3, 4, 5, 6, 7 },
        AutoSelectChip = 2,
        CenterOnChild = 3,
    },
    [3] =
    {
        TemplateID = 3,
        ShowName = "003",
        Type = 1,
        MaxPlayer = 50,
        UpBankerVIPLv = 0,
        UpBankerGold = 5000000,
        DownBankerGold = 3000000,
        BettingLongHu = { 100000, 15000000 },
        BettingBaoZi = { 10000, 950000 },
        BettingJinHua = { 10000, 1900000 },
        CanUseChip = { 1, 2, 3, 4, 5, 6, 7 },
        AutoSelectChip = 2,
        CenterOnChild = 3,
    },
    [4] =
    {
        TemplateID = 4,
        ShowName = "004",
        Type = 1,
        MaxPlayer = 50,
        UpBankerVIPLv = 0,
        UpBankerGold = 50000000,
        DownBankerGold = 30000000,
        BettingLongHu = { 1000000, 150000000 },
        BettingBaoZi = { 100000, 9500000 },
        BettingJinHua = { 100000, 19000000 },
        CanUseChip = { 3, 4, 5, 6, 7, 8, 9 },
        AutoSelectChip = 2,
        CenterOnChild = 5,
    },
    [5] =
    {
        TemplateID = 5,
        ShowName = "005",
        Type = 1,
        MaxPlayer = 50,
        UpBankerVIPLv = 0,
        UpBankerGold = 50000000,
        DownBankerGold = 30000000,
        BettingLongHu = { 1000000, 150000000 },
        BettingBaoZi = { 100000, 9500000 },
        BettingJinHua = { 100000, 19000000 },
        CanUseChip = { 3, 4, 5, 6, 7, 8, 9 },
        AutoSelectChip = 2,
        CenterOnChild = 5,
    },
    [6] =
    {
        TemplateID = 6,
        ShowName = "006",
        Type = 1,
        MaxPlayer = 50,
        UpBankerVIPLv = 0,
        UpBankerGold = 50000000,
        DownBankerGold = 30000000,
        BettingLongHu = { 1000000, 150000000 },
        BettingBaoZi = { 100000, 9500000 },
        BettingJinHua = { 100000, 19000000 },
        CanUseChip = { 3, 4, 5, 6, 7, 8, 9 },
        AutoSelectChip = 2,
        CenterOnChild = 5,
    },
    [7] =
    {
        TemplateID = 7,
        ShowName = "007",
        Type = 1,
        MaxPlayer = 50,
        UpBankerVIPLv = 0,
        UpBankerGold = 500000000,
        DownBankerGold = 300000000,
        BettingLongHu = { 10000000, 1500000000 },
        BettingBaoZi = { 1000000, 95000000 },
        BettingJinHua = { 1000000, 190000000 },
        CanUseChip = { 5, 6, 7, 8, 9, 10 },
        AutoSelectChip = 2,
        CenterOnChild = 7,
    },
    [201] =
    {
        TemplateID = 201,
        ShowName = "",
        Type = 2,
        MaxPlayer = 50,
        UpBankerVIPLv = 0,
        UpBankerGold = 5000000,
        DownBankerGold = 3000000,
        BettingLongHu = { 100000, 15000000 },
        BettingBaoZi = { 10000, 950000 },
        BettingJinHua = { 10000, 1900000 },
        CanUseChip = { 1, 2, 3, 4, 5, 6, 7 },
        AutoSelectChip = 2,
        CenterOnChild = 3,
    },
    [101] =
    {
        TemplateID = 101,
        ShowName = "0",
        Type = 3,
        MaxPlayer = 10,
        UpBankerVIPLv = 0,
        UpBankerGold = 5000000,
        DownBankerGold = 3000000,
        BettingLongHu = { 100000, 15000000 },
        BettingBaoZi = { 10000, 950000 },
        BettingJinHua = { 10000, 1900000 },
        CanUseChip = { 1, 2, 3, 4, 5, 6, 7 },
        AutoSelectChip = 2,
        CenterOnChild = 3,
    },
    [102] =
    {
        TemplateID = 102,
        ShowName = "0",
        Type = 3,
        MaxPlayer = 10,
        UpBankerVIPLv = 0,
        UpBankerGold = 50000000,
        DownBankerGold = 30000000,
        BettingLongHu = { 1000000, 150000000 },
        BettingBaoZi = { 100000, 9500000 },
        BettingJinHua = { 100000, 19000000 },
        CanUseChip = { 3, 4, 5, 6, 7, 8, 9 },
        AutoSelectChip = 2,
        CenterOnChild = 5,
    },
    [103] =
    {
        TemplateID = 103,
        ShowName = "0",
        Type = 3,
        MaxPlayer = 10,
        UpBankerVIPLv = 0,
        UpBankerGold = 500000000,
        DownBankerGold = 300000000,
        BettingLongHu = { 10000000, 1500000000 },
        BettingBaoZi = { 1000000, 95000000 },
        BettingJinHua = { 1000000, 190000000 },
        CanUseChip = { 5, 6, 7, 8, 9, 10 },
        AutoSelectChip = 2,
        CenterOnChild = 7,
    },
}

