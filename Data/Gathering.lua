-- Gathering professions: where to go at each skill level (content only).
-- Each step: skill range, what to gather (shown as the title), and the
-- best zones by faction. "Both" zones suit either faction.
-- Zone names must match the game's map names exactly.
-- These are general brackets for the classic world; Forever's own
-- spawns may differ slightly, so treat them as a starting point.
local _, ns = ...

ns.RegisterProfession({
    name = "Mining",
    skillLine = 186,
    icon = "Interface\\Icons\\Trade_Mining",
    gathering = true,
    steps = {
        { from = 1, to = 65, recipe = "Copper Veins", crafts = 0,
          note = "Smelt your ore into bars as you go: it gives extra skill points.",
          zones = { Alliance = { "Elwynn Forest", "Dun Morogh", "Westfall", "Loch Modan", "Darkshore" },
                    Horde = { "Durotar", "Mulgore", "Tirisfal Glades", "The Barrens", "Silverpine Forest" } } },
        { from = 65, to = 125, recipe = "Tin Veins", crafts = 0,
          note = "You'll also find the odd Silver Vein here.",
          zones = { Alliance = { "Redridge Mountains", "Wetlands", "Duskwood" },
                    Horde = { "Stonetalon Mountains", "The Barrens", "Thousand Needles" },
                    Both = { "Hillsbrad Foothills", "Ashenvale" } } },
        { from = 125, to = 175, recipe = "Iron Deposits", crafts = 0,
          note = "Gold Veins appear in the same areas.",
          zones = { Both = { "Arathi Highlands", "Desolace", "Stranglethorn Vale", "Thousand Needles", "Dustwallow Marsh", "Alterac Mountains" } } },
        { from = 175, to = 250, recipe = "Mithril Deposits", crafts = 0,
          note = "Truesilver Deposits appear in the same areas.",
          zones = { Both = { "Badlands", "Searing Gorge", "The Hinterlands", "Tanaris", "Feralas", "Azshara" } } },
        { from = 250, to = 300, recipe = "Thorium Veins", crafts = 0,
          note = "Rich Thorium Veins in Un'Goro Crater and Winterspring give the most ore.",
          zones = { Both = { "Un'Goro Crater", "Winterspring", "Eastern Plaguelands", "Burning Steppes", "Western Plaguelands", "Silithus", "Felwood" } } },
    },
})

ns.RegisterProfession({
    name = "Herbalism",
    skillLine = 182,
    icon = "Interface\\Icons\\Trade_Herbalism",
    gathering = true,
    steps = {
        { from = 1, to = 70, recipe = "Peacebloom, Silverleaf and Earthroot", crafts = 0,
          zones = { Alliance = { "Elwynn Forest", "Dun Morogh", "Teldrassil", "Westfall", "Darkshore" },
                    Horde = { "Durotar", "Mulgore", "Tirisfal Glades", "The Barrens", "Silverpine Forest" } } },
        { from = 70, to = 115, recipe = "Mageroyal, Briarthorn and Bruiseweed", crafts = 0,
          zones = { Alliance = { "Darkshore", "Westfall", "Loch Modan", "Redridge Mountains", "Wetlands" },
                    Horde = { "The Barrens", "Silverpine Forest", "Stonetalon Mountains" },
                    Both = { "Ashenvale" } } },
        { from = 115, to = 160, recipe = "Wild Steelbloom, Kingsblood and Stranglekelp", crafts = 0,
          note = "Stranglekelp grows underwater along coasts.",
          zones = { Alliance = { "Wetlands", "Duskwood" },
                    Horde = { "Stonetalon Mountains", "Thousand Needles" },
                    Both = { "Hillsbrad Foothills", "Ashenvale", "Arathi Highlands" } } },
        { from = 160, to = 205, recipe = "Liferoot, Fadeleaf, Goldthorn and Khadgar's Whisker", crafts = 0,
          zones = { Both = { "Arathi Highlands", "Stranglethorn Vale", "Dustwallow Marsh", "Swamp of Sorrows", "Desolace" } } },
        { from = 205, to = 255, recipe = "Firebloom, Purple Lotus, Sungrass and Arthas' Tears", crafts = 0,
          zones = { Both = { "Tanaris", "Feralas", "The Hinterlands", "Searing Gorge", "Blasted Lands", "Badlands" } } },
        { from = 255, to = 300, recipe = "Gromsblood, Golden Sansam, Dreamfoil and Plaguebloom", crafts = 0,
          zones = { Both = { "Un'Goro Crater", "Felwood", "Eastern Plaguelands", "Winterspring", "Western Plaguelands", "Silithus", "Azshara" } } },
    },
})

ns.RegisterProfession({
    name = "Skinning",
    skillLine = 393,
    icon = "Interface\\Icons\\INV_Misc_Pelt_Wolf_01",
    gathering = true,
    steps = {
        { from = 1, to = 75, recipe = "Beasts level 1 to 15", crafts = 0,
          note = "Rule of thumb: you can skin beasts up to about your skill divided by 5.",
          zones = { Alliance = { "Elwynn Forest", "Dun Morogh", "Teldrassil", "Westfall" },
                    Horde = { "Durotar", "Mulgore", "Tirisfal Glades", "The Barrens" } } },
        { from = 75, to = 150, recipe = "Beasts level 15 to 30", crafts = 0,
          zones = { Alliance = { "Loch Modan", "Darkshore", "Redridge Mountains", "Wetlands" },
                    Horde = { "The Barrens", "Silverpine Forest", "Stonetalon Mountains" },
                    Both = { "Hillsbrad Foothills", "Ashenvale" } } },
        { from = 150, to = 225, recipe = "Beasts level 30 to 45", crafts = 0,
          zones = { Both = { "Arathi Highlands", "Stranglethorn Vale", "Desolace", "Dustwallow Marsh", "Badlands" } } },
        { from = 225, to = 300, recipe = "Beasts level 45 to 60", crafts = 0,
          note = "Devilsaurs in Un'Goro Crater drop valuable leather.",
          zones = { Both = { "Tanaris", "Feralas", "Un'Goro Crater", "Winterspring", "Burning Steppes", "Felwood" } } },
    },
})

ns.RegisterProfession({
    name = "Fishing",
    skillLine = 356,
    icon = "Interface\\Icons\\Trade_Fishing",
    gathering = true,
    secondary = true,
    rankNotes = {
        [150] = "Expert: in Classic, the Expert Fishing book is sold by Old Man Heming in Booty Bay. Check in game.",
        [225] = "Artisan: in Classic, Nat Pagle in Dustwallow Marsh teaches it after his quest. Check in game.",
    },
    steps = {
        { from = 1, to = 75, recipe = "Starting-zone waters", crafts = 0,
          note = "Fish anywhere near water. Lakes and rivers near towns are fine.",
          zones = { Alliance = { "Elwynn Forest", "Dun Morogh", "Teldrassil" },
                    Horde = { "Durotar", "Mulgore", "Tirisfal Glades" } } },
        { from = 75, to = 150, recipe = "Low-level zone waters", crafts = 0,
          zones = { Alliance = { "Westfall", "Loch Modan", "Darkshore", "Redridge Mountains", "Wetlands" },
                    Horde = { "The Barrens", "Silverpine Forest" },
                    Both = { "Ashenvale", "Hillsbrad Foothills" } } },
        { from = 150, to = 225, recipe = "Mid-level zone waters", crafts = 0,
          zones = { Both = { "Stranglethorn Vale", "Desolace", "Arathi Highlands", "Dustwallow Marsh", "Swamp of Sorrows", "Alterac Mountains" } } },
        { from = 225, to = 300, recipe = "High-level zone waters", crafts = 0,
          note = "Coastal waters in Tanaris and Feralas are reliable.",
          zones = { Both = { "Tanaris", "Feralas", "Azshara", "Un'Goro Crater", "The Hinterlands", "Western Plaguelands", "Felwood" } } },
    },
})
