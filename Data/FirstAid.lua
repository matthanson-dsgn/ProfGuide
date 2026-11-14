-- First Aid route for WoW Forever (content only, no logic).
-- mats = materials for ONE craft: { "Item name", amount }
local _, ns = ...

ns.RegisterProfession({
    name = "First Aid",
    skillLine = 129,
    icon = "Interface\\Icons\\Spell_Holy_SealOfSacrifice",
    secondary = true,
    rankNotes = {
        [150] = "Expert: read Expert First Aid - Under Wraps (Deneb Walker / Balai Lok'Wein).",
        [225] = "Artisan: complete the quest Triage (character level 35).",
    },
    steps = {
        { from = 1, to = 40, recipe = "Linen Bandage", crafts = 41, source = "Known",
          mats = { {"Linen Cloth", 1} } },
        { from = 40, to = 80, recipe = "Heavy Linen Bandage", crafts = 55, source = "Trainer",
          mats = { {"Linen Cloth", 2} } },
        { from = 80, to = 115, recipe = "Wool Bandage", crafts = 48, source = "Trainer",
          mats = { {"Wool Cloth", 1} } },
        { from = 115, to = 150, recipe = "Heavy Wool Bandage", crafts = 48, source = "Trainer",
          mats = { {"Wool Cloth", 2} } },
        { from = 150, to = 180, recipe = "Silk Bandage", crafts = 41, source = "Trainer",
          mats = { {"Silk Cloth", 1} } },
        { from = 180, to = 210, recipe = "Heavy Silk Bandage", crafts = 41, source = "Manual: Deneb Walker / Balai Lok'Wein",
          mats = { {"Silk Cloth", 2} } },
        { from = 210, to = 240, recipe = "Mageweave Bandage", crafts = 41, source = "Manual: Deneb Walker / Balai Lok'Wein",
          mats = { {"Mageweave Cloth", 1} } },
        { from = 240, to = 260, recipe = "Heavy Mageweave Bandage", crafts = 24,
          source = "Doctor Gustaf VanHowzen / Doctor Gregory Victor",
          mats = { {"Mageweave Cloth", 2} } },
        { from = 260, to = 290, recipe = "Runecloth Bandage", crafts = 40,
          source = "Doctor Gustaf VanHowzen / Doctor Gregory Victor",
          mats = { {"Runecloth", 1} } },
        { from = 290, to = 300, recipe = "Heavy Runecloth Bandage", crafts = 11,
          source = "Doctor Gustaf VanHowzen / Doctor Gregory Victor",
          mats = { {"Runecloth", 2} } },
    },
})
