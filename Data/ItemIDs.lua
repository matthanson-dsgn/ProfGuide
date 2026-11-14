-- Starter item ID numbers, so icons and bank counts work straight away.
-- These are hints only. The add-on checks each one against the game,
-- ignores any that don't match, and learns the real ID from your bags
-- or profession window. Missing items here are fine: they get learned.
local _, ns = ...

ns.SeedIDs = {
    -- Leather & hides
    ["Ruined Leather Scraps"] = 2934, ["Light Leather"] = 2318, ["Medium Leather"] = 2319,
    ["Heavy Leather"] = 4234, ["Thick Leather"] = 4304, ["Rugged Leather"] = 8170,
    ["Light Hide"] = 783, ["Medium Hide"] = 4232, ["Heavy Hide"] = 4235, ["Rugged Hide"] = 8171,
    ["Cured Medium Hide"] = 4233, ["Cured Heavy Hide"] = 4236, ["Cured Rugged Hide"] = 15407,
    ["Salt"] = 4289, ["Refined Deeprock Salt"] = 15409, ["Heavy Scorpid Scale"] = 15408,
    ["Fine Leather Belt"] = 4246,

    -- Thread, dye & cloth
    ["Coarse Thread"] = 2320, ["Fine Thread"] = 2321, ["Silken Thread"] = 4291,
    ["Heavy Silken Thread"] = 8343, ["Rune Thread"] = 14341,
    ["Gray Dye"] = 4340, ["Black Dye"] = 2325, ["Blue Dye"] = 6260, ["Orange Dye"] = 6261,
    ["Green Dye"] = 2605, ["Bleach"] = 2324,
    ["Linen Cloth"] = 2589, ["Wool Cloth"] = 2592, ["Silk Cloth"] = 4306,
    ["Mageweave Cloth"] = 4338, ["Runecloth"] = 14047,
    ["Bolt of Linen Cloth"] = 2996, ["Bolt of Woolen Cloth"] = 2997, ["Bolt of Silk Cloth"] = 4305,
    ["Bolt of Mageweave"] = 4339, ["Bolt of Runecloth"] = 14048,
    ["Spider's Silk"] = 3182, ["Ironweb Spider Silk"] = 14227,

    -- Elementals & gems
    ["Elemental Earth"] = 7067, ["Elemental Fire"] = 7068, ["Elemental Air"] = 7069,
    ["Elemental Water"] = 7070, ["Essence of Earth"] = 7076, ["Essence of Air"] = 7082,
    ["Living Essence"] = 12803, ["Iridescent Pearl"] = 5500, ["Black Pearl"] = 7971,
    ["Jade"] = 1529, ["Citrine"] = 3864, ["Moss Agate"] = 1206, ["Shadowgem"] = 1210,
    ["Star Ruby"] = 7910, ["Large Opal"] = 12799,

    -- Stone & metal
    ["Rough Stone"] = 2835, ["Coarse Stone"] = 2836, ["Heavy Stone"] = 2838,
    ["Solid Stone"] = 7912, ["Dense Stone"] = 12365,
    ["Copper Bar"] = 2840, ["Bronze Bar"] = 2841, ["Silver Bar"] = 2842, ["Iron Bar"] = 3575,
    ["Steel Bar"] = 3859, ["Mithril Bar"] = 3860, ["Truesilver Bar"] = 6037,
    ["Thorium Bar"] = 12359, ["Arcanite Bar"] = 12360,
    ["Weak Flux"] = 2880, ["Strong Flux"] = 3466,

    -- Herbs & alchemy
    ["Peacebloom"] = 2447, ["Silverleaf"] = 765, ["Earthroot"] = 2449, ["Mageroyal"] = 785,
    ["Briarthorn"] = 2450, ["Stranglekelp"] = 3820, ["Kingsblood"] = 3356, ["Goldthorn"] = 3821,
    ["Khadgar's Whisker"] = 3358, ["Arthas' Tears"] = 8836, ["Sungrass"] = 8838,
    ["Blindweed"] = 8839, ["Purple Lotus"] = 8831, ["Firebloom"] = 4625, ["Plaguebloom"] = 13466,
    ["Black Vitriol"] = 9262, ["Empty Vial"] = 3371, ["Leaded Vial"] = 3372,
    ["Crystal Vial"] = 8925, ["Murloc Eye"] = 730, ["Elixir of Lesser Defense"] = 3389,

    -- Enchanting
    ["Strange Dust"] = 10940, ["Soul Dust"] = 11083, ["Vision Dust"] = 11137,
    ["Dream Dust"] = 11176, ["Illusion Dust"] = 16204,
    ["Lesser Magic Essence"] = 10938, ["Lesser Astral Essence"] = 10998,
    ["Greater Astral Essence"] = 11082, ["Lesser Mystic Essence"] = 11134,
    ["Greater Mystic Essence"] = 11135, ["Lesser Nether Essence"] = 11174,
    ["Small Brilliant Shard"] = 14343,
    ["Copper Rod"] = 6217, ["Silver Rod"] = 6338, ["Golden Rod"] = 11128, ["Truesilver Rod"] = 11144,

    -- Cooking
    ["Raw Brilliant Smallfish"] = 6291, ["Raw Longjaw Mud Snapper"] = 6289,
    ["Raw Bristle Whisker Catfish"] = 6308, ["Raw Mithril Head Trout"] = 8365,
    ["Raw Spotted Yellowtail"] = 4603, ["Large Raw Mightfish"] = 13893,
    ["Hot Spices"] = 2692, ["Soothing Spices"] = 3713,
}
