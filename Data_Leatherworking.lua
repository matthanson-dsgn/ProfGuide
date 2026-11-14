-- ============================================================
-- Data_Leatherworking.lua
-- The "content" layer: the levelling route, with no logic.
-- To change the route, edit this file only.
-- ============================================================

-- Every file in an add-on gets the add-on's name and a shared
-- table ("ns" = namespace). We use ns to pass data between files.
local addonName, ns = ...

ns.Professions = ns.Professions or {}

ns.Professions.Leatherworking = {
    name = "Leatherworking",
    skillLine = 165, -- the game's internal ID for Leatherworking

    -- Every material used below. The number is the game's item ID,
    -- which lets the add-on count how many you're carrying.
    -- crafted = true means you make it yourself in an earlier step.
    items = {
        [2318]  = { name = "Light Leather" },
        [2319]  = { name = "Medium Leather" },
        [4234]  = { name = "Heavy Leather" },
        [4304]  = { name = "Thick Leather" },
        [8170]  = { name = "Rugged Leather" },
        [783]   = { name = "Light Hide" },
        [4232]  = { name = "Medium Hide" },
        [4235]  = { name = "Heavy Hide" },
        [8171]  = { name = "Rugged Hide" },
        [4289]  = { name = "Salt" },
        [15409] = { name = "Refined Deeprock Salt" },
        [2320]  = { name = "Coarse Thread" },
        [2321]  = { name = "Fine Thread" },
        [4291]  = { name = "Silken Thread" },
        [14341] = { name = "Rune Thread" },
        [4340]  = { name = "Gray Dye" },
        [2325]  = { name = "Black Dye" },
        [14047] = { name = "Runecloth" },
        [15408] = { name = "Heavy Scorpid Scale" },
        -- Things you craft and keep for later steps:
        [4246]  = { name = "Fine Leather Belt",  crafted = true },
        [4233]  = { name = "Cured Medium Hide",  crafted = true },
        [4236]  = { name = "Cured Heavy Hide",   crafted = true },
        [15407] = { name = "Cured Rugged Hide",  crafted = true },
    },

    -- The route. Each step: skill range, recipe, rough number of
    -- crafts, where to learn it, an optional tip, and the
    -- materials for ONE craft (the add-on multiplies them up).
    steps = {
        { from = 1, to = 30, recipe = "Light Armor Kit", crafts = 32, source = "Trainer",
          mats = { {2318, 1} } },

        { from = 30, to = 45, recipe = "Handstitched Leather Boots", crafts = 20, source = "Trainer",
          mats = { {2318, 2}, {2320, 1} } },

        { from = 45, to = 55, recipe = "Cured Light Hide", crafts = 12, source = "Trainer",
          note = "Train Journeyman (level 10) before you reach 75.",
          mats = { {783, 1}, {4289, 1} } },

        { from = 55, to = 85, recipe = "Embossed Leather Gloves", crafts = 35, source = "Trainer",
          mats = { {2318, 3}, {2320, 2} } },

        { from = 85, to = 90, recipe = "Cured Medium Hide", crafts = 10, source = "Trainer",
          note = "Keep all 10. Dark Leather Belt uses them at 115.",
          mats = { {4232, 1}, {4289, 1} } },

        { from = 90, to = 100, recipe = "Fine Leather Belt", crafts = 20, source = "Trainer",
          note = "Keep 10 belts. Dark Leather Belt uses them at 115.",
          mats = { {2318, 6}, {2320, 2} } },

        { from = 100, to = 115, recipe = "Dark Leather Pants", crafts = 15, source = "Trainer",
          mats = { {2319, 12}, {4340, 1}, {2321, 1} } },

        { from = 115, to = 125, recipe = "Dark Leather Belt", crafts = 10, source = "Trainer",
          note = "Train Expert (level 20) before you reach 150.",
          mats = { {4246, 1}, {4233, 1}, {2321, 2}, {4340, 1} } },

        { from = 125, to = 130, recipe = "Heavy Leather", crafts = 7, source = "Trainer",
          mats = { {2319, 5} } },

        { from = 130, to = 140, recipe = "Cured Heavy Hide", crafts = 35, source = "Trainer",
          note = "Keep them all. The next two steps use about 33.",
          mats = { {4235, 1}, {4289, 3} } },

        { from = 140, to = 150, recipe = "Heavy Armor Kit", crafts = 12, source = "Trainer",
          mats = { {4234, 5}, {2321, 1} } },

        { from = 150, to = 165, recipe = "Barbaric Shoulders", crafts = 15, source = "Trainer",
          mats = { {4234, 8}, {4236, 1}, {2321, 2} } },

        { from = 165, to = 180, recipe = "Guardian Gloves", crafts = 18, source = "Trainer",
          mats = { {4234, 4}, {4236, 1}, {4291, 1} } },

        { from = 180, to = 195, recipe = "Thick Armor Kit", crafts = 20, source = "Trainer",
          mats = { {4304, 5}, {4291, 1} } },

        { from = 195, to = 210, recipe = "Nightscape Headband", crafts = 20, source = "Trainer",
          note = "Train Artisan (level 35) before you reach 225.",
          mats = { {4304, 5}, {4291, 2} } },

        { from = 210, to = 225, recipe = "Nightscape Pants", crafts = 15, source = "Trainer",
          mats = { {4304, 14}, {4291, 4} } },

        { from = 225, to = 235, recipe = "Cured Rugged Hide", crafts = 15, source = "Trainer",
          note = "Keep them all. Heavy Scorpid Helm uses them at 285.",
          mats = { {8171, 1}, {15409, 1} } },

        { from = 235, to = 265, recipe = "Wicked Leather Gauntlets", crafts = 37, source = "Pattern (vendor / AH)",
          mats = { {8170, 8}, {2325, 1}, {14341, 1} } },

        { from = 265, to = 285, recipe = "Runic Leather Headband", crafts = 21, source = "Pattern (vendor / AH)",
          mats = { {8170, 14}, {14047, 10}, {14341, 1} } },

        { from = 285, to = 300, recipe = "Heavy Scorpid Helm", crafts = 15, source = "Pattern (vendor)",
          mats = { {8170, 8}, {15408, 12}, {15407, 1}, {14341, 1} } },
    },
}
