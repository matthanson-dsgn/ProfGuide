-- Cooking route for WoW Forever (content only, no logic).
-- mats = materials for ONE craft: { "Item name", amount }
local _, ns = ...

ns.RegisterProfession({
    name = "Cooking",
    skillLine = 185,
    icon = "Interface\\Icons\\INV_Misc_Food_15",
    secondary = true,
    rankNotes = {
        [150] = "Expert: buy The Expert Cookbook from Shandrina (Ashenvale) or Wulan (Desolace).",
        [225] = "Artisan: complete the quest Clamlette Surprise (character level 35).",
    },
    steps = {
        { from = 1, to = 50, recipe = "Brilliant Smallfish", crafts = 49, source = "Known",
          note = "These fish come from Fishing or the Auction House. You need a cooking fire.",
          mats = { {"Raw Brilliant Smallfish", 1} } },
        { from = 50, to = 100, recipe = "Longjaw Mud Snapper", crafts = 51, source = "Recipe: Nyalah Brightfire",
          mats = { {"Raw Longjaw Mud Snapper", 1} } },
        { from = 100, to = 175, recipe = "Bristle Whisker Catfish", crafts = 120, source = "Recipe: Kilxx",
          mats = { {"Raw Bristle Whisker Catfish", 1} } },
        { from = 175, to = 225, recipe = "Mithril Headed Trout", crafts = 51, source = "Recipe: Kelsey Yance",
          mats = { {"Raw Mithril Head Trout", 1} } },
        { from = 225, to = 275, recipe = "Spotted Yellowtail", crafts = 51, source = "Recipe: Gikkix",
          mats = { {"Raw Spotted Yellowtail", 1} } },
        { from = 275, to = 300, recipe = "Mightfish Steak", crafts = 25, source = "Recipe: Vivianna / Sheendra Tallgrass",
          mats = { {"Large Raw Mightfish", 1}, {"Hot Spices", 1}, {"Soothing Spices", 1} } },
    },
})
