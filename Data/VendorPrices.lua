-- Vendor (shop-bought) reagents and their starting prices, in copper.
-- (100 copper = 1 silver, 100 silver = 1 gold.)
-- These are Classic-era prices, shown as estimates. When you open a
-- vendor that sells the item, the add-on saves the real price instead.
local _, ns = ...

ns.SeedPrices = {
    ["Coarse Thread"] = 10,
    ["Fine Thread"] = 100,
    ["Silken Thread"] = 300,
    ["Heavy Silken Thread"] = 1600,
    ["Rune Thread"] = 5000,
    ["Gray Dye"] = 35,
    ["Black Dye"] = 2500,
    ["Blue Dye"] = 50,
    ["Red Dye"] = 50,
    ["Green Dye"] = 100,
    ["Orange Dye"] = 2500,
    ["Bleach"] = 25,
    ["Salt"] = 50,
    ["Empty Vial"] = 4,
    ["Leaded Vial"] = 40,
    ["Crystal Vial"] = 200,
    ["Weak Flux"] = 100,
    ["Strong Flux"] = 2000,
    ["Hot Spices"] = 40,
    ["Soothing Spices"] = 40,
    ["Copper Rod"] = 124,
}
