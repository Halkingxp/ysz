--Export by excel config file, don't modify this file!
--[[
TemplateID(Column[A] Type[int] Desc[测试编号]
LongCard(Column[C] Type[group] Desc[龙牌型]
HuCard(Column[D] Type[group] Desc[虎牌型]
]]--

TestConfig =
{
    [1] =
    {
        TemplateID = 1,
        LongCard = { { 1, 13 }, { 2, 13 }, { 2, 13 } },
        HuCard = { { 4, 12 }, { 2, 12 }, { 3, 12 } },
    },
    [2] =
    {
        TemplateID = 2,
        LongCard = { { 2, 13 }, { 3, 12 }, { 1, 12 } },
        HuCard = { { 4, 13 }, { 4, 12 }, { 4, 11 } },
    },
}

