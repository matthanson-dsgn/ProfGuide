-- ============================================================
-- Core.lua
-- The "logic" layer: knows the professions, reads your skill and
-- bags, learns item IDs, and works out what you still need.
-- No visuals here. Loads first so the Data files can register.
-- ============================================================

local addonName, ns = ...

ns.Professions = {}     -- name -> profession definition
ns.ProfessionOrder = {} -- names in display order
ns.bagCounts = {}       -- item name -> how many are in your bags right now

-- Panel state. viewIndex = nil means "follow my current skill".
ns.state = { prof = nil, viewIndex = nil, tab = "step" }

-- Skill caps and the rank you train to pass each one.
-- Professions can override the text with rankNotes.
local RANKS = {
    { cap = 75,  text = "Journeyman: visit a trainer (character level 10)." },
    { cap = 150, text = "Expert: visit a trainer (character level 20)." },
    { cap = 225, text = "Artisan: visit a trainer (character level 35)." },
}

-- ---------- Registering professions (called by Data files) ----------

-- Builds a "view" of a profession for one route: its steps plus
-- quick lookups. The rest of the add-on only ever sees views.
local function MakeView(def, key, label, steps)
    local view = {
        name = def.name, skillLine = def.skillLine, icon = def.icon,
        rankNotes = def.rankNotes, routeKey = key, routeLabel = label,
        steps = steps, recipeSet = {}, allRecipes = {},
    }
    -- recipeSet: things you make yourself on this route. Steps marked
    -- gathered = true (e.g. Light Leather) don't count: you'd normally
    -- skin or buy those. allRecipes: every recipe, for reading the
    -- profession window.
    for _, step in ipairs(steps) do
        view.allRecipes[step.recipe] = true
        if not step.gathered then view.recipeSet[step.recipe] = true end
    end
    return view
end

function ns.RegisterProfession(def)
    def.views = { fast = MakeView(def, "fast", "Fast", def.steps) }
    if def.budgetSteps then
        def.views.budget = MakeView(def, "budget", "Budget", def.budgetSteps)
    end
    -- Every recipe across all routes, for reading the profession window.
    def.allRecipes = {}
    for _, view in pairs(def.views) do
        for name in pairs(view.allRecipes) do def.allRecipes[name] = true end
    end
    ns.Professions[def.name] = def
    table.insert(ns.ProfessionOrder, def.name)
end

-- Which route a profession is using ("fast" unless you picked another).
function ns.RouteKey(def)
    local saved = ProfGuideForeverDB and ProfGuideForeverDB.routes and ProfGuideForeverDB.routes[def.name]
    if saved and def.views[saved] then return saved end
    return "fast"
end

function ns.SetRoute(name, key)
    ProfGuideForeverDB.routes[name] = key
    ns.state.viewIndex = nil
end

-- The profession on screen, as a view of its chosen route.
function ns.ActiveProf()
    local def = ns.Professions[ns.state.prof] or ns.Professions[ns.ProfessionOrder[1]]
    return def.views[ns.RouteKey(def)], def
end

-- ---------- Saved data ----------

local function CharKey()
    return (UnitName("player") or "?") .. "-" .. (GetRealmName() or "?")
end

local function InitDB()
    ProfGuideForeverDB = ProfGuideForeverDB or {}
    local db = ProfGuideForeverDB
    if db.shown == nil then db.shown = true end
    db.itemIDs = db.itemIDs or {}   -- item name -> ID, learned in game
    db.recipes = db.recipes or {}   -- recipe name -> materials, read from profession windows
    -- Skill numbers saved before 0.5.1 could belong to another character,
    -- so clear them once. They refill on login or when you open a profession.
    if db.skillsVersion ~= 2 then
        db.skills = {}
        db.skillsVersion = 2
    end
    db.skills  = db.skills or {}    -- character -> profession -> { skill, max }
    db.routes  = db.routes or {}    -- profession -> "fast" or "budget"
    db.known   = db.known or {}     -- character -> recipe name -> learned? (true/false)
    db.recipeIDs = db.recipeIDs or {} -- recipe name -> the game's recipe ID (for "Open recipe")
end

-- This character's part of a saved table (e.g. "skills"), created on demand.
-- Returns nil until the character's name is known, so nothing is ever
-- saved under a shared "unknown" character.
local function CharTable(field)
    local name = UnitName("player")
    if not (ProfGuideForeverDB and name and name ~= UNKNOWNOBJECT) then return nil end
    local key = CharKey()
    ProfGuideForeverDB[field][key] = ProfGuideForeverDB[field][key] or {}
    return ProfGuideForeverDB[field][key]
end

local function RememberSkill(name, rank, maxRank)
    local skills = CharTable("skills")
    if skills and name and rank and maxRank and maxRank > 0 then
        skills[name] = { rank, maxRank }
    end
end

-- Has this character learned a recipe? true / false, or nil if we
-- haven't seen it in a profession window yet.
function ns.IsKnown(recipe)
    local known = CharTable("known")
    if known then return known[recipe] end
end

-- ---------- Reading your skill ----------
-- Tries two ways: your professions list, then this character's own
-- profession window from last time.

function ns.GetSkill(prof)
    -- 1. The standard professions list (works for most professions).
    if GetProfessions and GetProfessionInfo then
        local slots = { GetProfessions() }
        for i = 1, 10 do
            local index = slots[i]
            if index then
                local name, _, rank, maxRank, _, _, skillLine = GetProfessionInfo(index)
                if skillLine == prof.skillLine or name == prof.name then
                    RememberSkill(prof.name, rank, maxRank)
                    return rank, maxRank
                end
            end
        end
    end

    -- 2. What this character's own profession window told us last time
    --    (covers professions the list above leaves out, like First Aid).
    -- Note: we don't ask the game by skill line ID any more. After a
    -- character switch it could still answer with the previous
    -- character's skill.
    local skills = CharTable("skills")
    local saved = skills and skills[prof.name]
    if saved then return saved[1], saved[2] end
    return nil
end

-- Professions this character has, in display order.
function ns.LearnedProfessions()
    local list = {}
    for _, name in ipairs(ns.ProfessionOrder) do
        local rank, maxRank = ns.GetSkill(ns.Professions[name])
        if rank then table.insert(list, { name = name, rank = rank, max = maxRank }) end
    end
    return list
end

-- ---------- Items: names -> IDs -> counts ----------

-- Finds an item's ID: one learned in game first, then the starter
-- list (only if the game agrees that ID has this name).
function ns.ItemID(name)
    local learned = ProfGuideForeverDB and ProfGuideForeverDB.itemIDs[name]
    if learned then return learned end
    local seed = ns.SeedIDs and ns.SeedIDs[name]
    if seed and C_Item and C_Item.GetItemNameByID then
        local real = C_Item.GetItemNameByID(seed)
        if real and real ~= name then return nil end -- wrong guess: ignore it
    end
    return seed
end

-- How many you own. With an ID we can include your bank;
-- without one we count by name from your bags.
function ns.CountItem(name)
    local inBags = ns.bagCounts[name] or 0
    local id = ns.ItemID(name)
    if not id then return inBags end
    local total = 0
    if C_Item and C_Item.GetItemCount then
        total = C_Item.GetItemCount(id, true) or 0
    elseif GetItemCount then
        total = GetItemCount(id, true) or 0
    end
    return math.max(total, inBags)
end

function ns.ItemIcon(name)
    local id = ns.ItemID(name)
    if id and C_Item and C_Item.GetItemIconByID then
        return C_Item.GetItemIconByID(id) or 134400
    end
    return 134400 -- the generic "?" icon until we learn the item
end

-- Looks through your bags: counts items by name and learns their IDs.
local function ScanBags()
    if not (C_Container and C_Container.GetContainerNumSlots) then return end
    wipe(ns.bagCounts)
    local lastBag = NUM_TOTAL_EQUIPPED_BAG_SLOTS or NUM_BAG_SLOTS or 4
    for bag = 0, lastBag do
        for slot = 1, (C_Container.GetContainerNumSlots(bag) or 0) do
            local info = C_Container.GetContainerItemInfo(bag, slot)
            if info and info.itemID then
                local name = (C_Item and C_Item.GetItemNameByID and C_Item.GetItemNameByID(info.itemID))
                    or (info.hyperlink and info.hyperlink:match("%[(.-)%]"))
                if name then
                    ProfGuideForeverDB.itemIDs[name] = info.itemID
                    ns.bagCounts[name] = (ns.bagCounts[name] or 0) + (info.stackCount or 1)
                end
            end
        end
    end
end

-- ---------- Reading recipes from the profession window ----------
-- When you open a profession, the game lists every recipe's real
-- materials. We save the ones on our routes, so the guide corrects
-- itself if our data is wrong or Blizzard changes a recipe.

local function RouteRecipeNames()
    local set = {}
    for _, prof in pairs(ns.Professions) do
        for name in pairs(prof.allRecipes) do set[name] = true end
    end
    return set
end

-- Notes from the last scan, shown by /pg check to help fix problems.
local function NewScanReport(api)
    local report = { api = api, recipes = 0, matched = 0, saved = 0, examples = {}, time = time() }
    ProfGuideForeverDB.lastScan = report
    ns.scannedNames = {} -- every recipe name seen (this session only, not saved)
    return report
end

-- Modern (retail-style) profession window.
local function ScanModern()
    local T = C_TradeSkillUI
    if not (T and T.GetAllRecipeIDs and T.GetRecipeInfo and T.GetRecipeSchematic) then return false end
    local ids = T.GetAllRecipeIDs() or {}
    if #ids == 0 then return false end -- no window open, or not this kind of window
    local report = NewScanReport("modern")

    -- Your skill in the open profession.
    if T.GetBaseProfessionInfo then
        local base = T.GetBaseProfessionInfo()
        if base and base.professionName then
            RememberSkill(base.professionName, base.skillLevel, base.maxSkillLevel)
        end
    end

    local wanted = RouteRecipeNames()
    local basicType = Enum and Enum.CraftingReagentType and Enum.CraftingReagentType.Basic
    for _, recipeID in ipairs(ids) do
        local info = T.GetRecipeInfo(recipeID)
        report.recipes = report.recipes + 1
        if info and info.name then table.insert(ns.scannedNames, info.name) end
        if info and info.name and #report.examples < 3 then table.insert(report.examples, info.name) end
        if info and info.name and wanted[info.name] then
            report.matched = report.matched + 1
            local known = CharTable("known")
            if known then known[info.name] = info.learned and true or false end
            ProfGuideForeverDB.recipeIDs[info.name] = recipeID
            local schematic = T.GetRecipeSchematic(recipeID, false)
            local mats, complete = {}, true
            for _, slot in ipairs(schematic and schematic.reagentSlotSchematics or {}) do
                local reagent = slot.reagents and slot.reagents[1]
                local isBasic = (slot.reagentType == nil) or (basicType == nil) or (slot.reagentType == basicType)
                if isBasic and reagent and reagent.itemID then
                    local name = C_Item.GetItemNameByID(reagent.itemID)
                    if name then
                        ProfGuideForeverDB.itemIDs[name] = reagent.itemID
                        table.insert(mats, { name, slot.quantityRequired or 1 })
                    else
                        complete = false -- item not loaded yet; we'll catch it next scan
                        if C_Item.RequestLoadItemDataByID then C_Item.RequestLoadItemDataByID(reagent.itemID) end
                    end
                end
            end
            if complete and #mats > 0 then
                ProfGuideForeverDB.recipes[info.name] = mats
                report.saved = report.saved + 1
            end
        end
    end
    return true
end

-- Older (Classic-style) profession window, in case Forever uses it.
local function ScanClassic()
    if not (GetNumTradeSkills and GetTradeSkillInfo and GetTradeSkillNumReagents and GetTradeSkillReagentInfo) then
        return false
    end
    local count = GetNumTradeSkills() or 0
    if count == 0 then return false end
    local report = NewScanReport("classic")

    if GetTradeSkillLine then
        local name, rank, maxRank = GetTradeSkillLine()
        RememberSkill(name, rank, maxRank)
    end

    local wanted = RouteRecipeNames()
    for i = 1, count do
        local name, kind = GetTradeSkillInfo(i)
        if name and kind ~= "header" and kind ~= "subheader" then
            report.recipes = report.recipes + 1
            table.insert(ns.scannedNames, name)
            if #report.examples < 3 then table.insert(report.examples, name) end
            if wanted[name] then
                report.matched = report.matched + 1
                local known = CharTable("known")
                if known then known[name] = true end -- this window only lists learned recipes
                local mats, complete = {}, true
                for j = 1, (GetTradeSkillNumReagents(i) or 0) do
                    local reagentName, _, amount = GetTradeSkillReagentInfo(i, j)
                    if reagentName then
                        table.insert(mats, { reagentName, amount or 1 })
                        -- Learn the item ID from its link, e.g. "|Hitem:2318:..."
                        local link = GetTradeSkillReagentItemLink and GetTradeSkillReagentItemLink(i, j)
                        local id = link and tonumber(link:match("item:(%d+)"))
                        if id then ProfGuideForeverDB.itemIDs[reagentName] = id end
                    else
                        complete = false -- not loaded yet; next scan will get it
                    end
                end
                if complete and #mats > 0 then
                    ProfGuideForeverDB.recipes[name] = mats
                    report.saved = report.saved + 1
                end
            end
        end
    end
    return true
end

local function ScanTradeSkill()
    if not ScanModern() then
        if not ScanClassic() then
            ProfGuideForeverDB.lastScan = { api = "none" }
        end
    end
end

-- ---------- Working out the route ----------

function ns.CurrentStepIndex(prof, skill)
    skill = skill or 1
    for i, step in ipairs(prof.steps) do
        if skill < step.to then return i end
    end
    return #prof.steps
end

-- Crafts still needed for a step, scaled down if you're part-way through.
function ns.CraftsLeft(step, skill)
    skill = skill or 1
    if skill <= step.from then return step.crafts end
    if skill >= step.to then return 0 end
    return math.ceil(step.crafts * (step.to - skill) / (step.to - step.from))
end

-- A step's materials: from your profession window if we've seen it,
-- otherwise from our data. Returns the list and whether it's verified.
function ns.RecipeMats(step)
    local scanned = ProfGuideForeverDB and ProfGuideForeverDB.recipes[step.recipe]
    if scanned then return scanned, true end
    return step.mats, false
end

-- Materials for one step: list of { name, need, have, crafted }.
function ns.StepMaterials(prof, step, skill)
    local crafts = ns.CraftsLeft(step, skill)
    if crafts == 0 then crafts = step.crafts end -- browsing a finished step: show full amounts
    local mats, verified = ns.RecipeMats(step)
    local list = {}
    for _, mat in ipairs(mats) do
        local name, perCraft = mat[1], mat[2]
        table.insert(list, {
            name = name,
            need = perCraft * crafts,
            have = ns.CountItem(name),
            crafted = prof.recipeSet[name] or false,
        })
    end
    return list, crafts, verified
end

-- Everything you need to gather or buy from your current skill to 300.
-- Things you craft yourself (bolts of cloth, cured hides, parts) are
-- turned back into their raw materials, so the list is all shopping.
function ns.ShoppingList(prof, skill)
    local need, produced = {}, {}
    for i = ns.CurrentStepIndex(prof, skill), #prof.steps do
        local step = prof.steps[i]
        local crafts = ns.CraftsLeft(step, skill)
        if crafts > 0 then
            produced[step.recipe] = (produced[step.recipe] or 0) + crafts
            for _, mat in ipairs((ns.RecipeMats(step))) do
                need[mat[1]] = (need[mat[1]] or 0) + mat[2] * crafts
            end
        end
    end

    -- Find the step that makes a crafted item (its first appearance).
    local function StepFor(name)
        for _, step in ipairs(prof.steps) do
            if step.recipe == name then return step end
        end
    end

    -- Adds the raw materials for `qty` more of a crafted item.
    -- depth stops runaway loops if a route ever contains a cycle.
    local function Expand(name, qty, depth)
        local step = StepFor(name)
        if not step or depth > 3 then return end
        for _, mat in ipairs((ns.RecipeMats(step))) do
            local amount = mat[2] * qty
            if prof.recipeSet[mat[1]] then
                Expand(mat[1], amount, depth + 1)
            else
                need[mat[1]] = (need[mat[1]] or 0) + amount
            end
        end
    end

    -- For each crafted item: how many more than the route makes and
    -- you already own? Turn that shortfall into raw materials.
    local craftedNeeds = {}
    for name, amount in pairs(need) do
        if prof.recipeSet[name] then craftedNeeds[name] = amount end
    end
    for name, amount in pairs(craftedNeeds) do
        local shortfall = amount - (produced[name] or 0) - ns.CountItem(name)
        if shortfall > 0 then Expand(name, shortfall, 1) end
    end

    local list = {}
    for name, amount in pairs(need) do
        if not prof.recipeSet[name] then
            table.insert(list, { name = name, need = amount, have = ns.CountItem(name), crafted = false })
        end
    end
    table.sort(list, function(a, b) return a.need > b.need end)
    return list
end

-- Tips about training the next rank, for the step you're looking at.
function ns.RankTips(prof, step, skill, maxSkill)
    local tips = {}
    for _, r in ipairs(RANKS) do
        -- Skip ranks you've already trained (your max skill is past the cap).
        local alreadyTrained = maxSkill and maxSkill > r.cap
        if step.from < r.cap and step.to >= r.cap and not alreadyTrained then
            local text = (prof.rankNotes and prof.rankNotes[r.cap]) or r.text
            table.insert(tips, "Skill stops at " .. r.cap .. ". " .. text)
        end
    end
    local capped = skill and maxSkill and maxSkill < 300 and skill >= maxSkill
    return tips, capped
end

-- ---------- Opening a recipe in the profession window ----------

-- Opens your profession window on a step's recipe. Uses the recipe's
-- ID if we've seen it; otherwise opens the profession and types the
-- recipe name into its search box.
function ns.OpenRecipe(prof, step)
    local T = C_TradeSkillUI
    if InCombatLockdown and InCombatLockdown() then
        print("|cffffd100ProfGuide Forever:|r can't open the profession window during combat.")
        return
    end
    local id = ProfGuideForeverDB.recipeIDs[step.recipe]
    if id and T and T.OpenRecipe then
        if pcall(T.OpenRecipe, id) then return end
    end
    -- Fallback: open the profession, then search for the recipe by name.
    if T and T.OpenTradeSkill then
        pcall(T.OpenTradeSkill, prof.skillLine)
    elseif CastSpellByName then
        pcall(CastSpellByName, prof.name)
    end
    C_Timer.After(0.4, function()
        pcall(function()
            local box = ProfessionsFrame.CraftingPage.RecipeList.SearchBox
            box:SetText(step.recipe)
        end)
    end)
end

-- ---------- /pg check ----------
-- Lists which materials the add-on recognises, and anything that
-- doesn't match the game, so problems are easy to report.

local function Check()
    local prof = ns.ActiveProf()
    local seen, known, unknown, wrong = {}, 0, {}, {}
    for _, step in ipairs(prof.steps) do
        for _, mat in ipairs((ns.RecipeMats(step))) do
            local name = mat[1]
            if not seen[name] then
                seen[name] = true
                local seed = ns.SeedIDs[name]
                local real = seed and C_Item.GetItemNameByID(seed)
                if real and real ~= name then
                    table.insert(wrong, name .. " (ID " .. seed .. " is " .. real .. ")")
                end
                if ns.ItemID(name) then known = known + 1 else table.insert(unknown, name) end
            end
        end
    end
    -- Which steps the game has confirmed, which it hasn't, and which
    -- recipes have different materials in game than in our data.
    local verified, missing, differs, listed = 0, {}, {}, {}
    for _, step in ipairs(prof.steps) do
        local scanned = ProfGuideForeverDB.recipes[step.recipe]
        if scanned then
            verified = verified + 1
            local same = (#scanned == #step.mats)
            if same then
                local ours = {}
                for _, m in ipairs(step.mats) do ours[m[1]] = m[2] end
                for _, m in ipairs(scanned) do
                    if ours[m[1]] ~= m[2] then same = false end
                end
            end
            if not same and not listed[step.recipe] then
                listed[step.recipe] = true
                local parts = {}
                for _, m in ipairs(scanned) do table.insert(parts, m[2] .. " " .. m[1]) end
                table.insert(differs, step.recipe .. " = " .. table.concat(parts, ", "))
            end
        elseif not listed[step.recipe] then
            listed[step.recipe] = true
            table.insert(missing, step.recipe)
        end
    end

    local gold, grey, red = "|cffffd100", "|cff9d9d9d", "|cffff5555"
    print(gold .. "ProfGuide Forever check: " .. prof.name .. "|r")
    print("  Recipes confirmed from your profession window: " .. verified .. " of " .. #prof.steps)
    if #missing > 0 then
        print(grey .. "  Not confirmed (name may differ in game): " .. table.concat(missing, ", ") .. "|r")
        -- Show game recipe names that contain the same words, to spot spelling differences.
        if ns.scannedNames then
            for _, recipe in ipairs(missing) do
                local needle, hits = recipe:lower(), {}
                for _, n in ipairs(ns.scannedNames) do
                    if n:lower():find(needle, 1, true) and #hits < 5 then
                        table.insert(hits, "\"" .. n .. "\"")
                    end
                end
                print(grey .. "    In game for \"" .. recipe .. "\": " .. (#hits > 0 and table.concat(hits, ", ") or "no similar names") .. "|r")
            end
        end
    end
    if #differs > 0 then
        print(grey .. "  Different in game (the game's version is being used):|r")
        for _, line in ipairs(differs) do print(grey .. "    " .. line .. "|r") end
    end
    print("  Materials recognised: " .. known .. " of " .. (known + #unknown))
    if #unknown > 0 then
        print(grey .. "  Not seen yet (carry one or open the profession window): " .. table.concat(unknown, ", ") .. "|r")
    end
    if #wrong > 0 then
        print(red .. "  Wrong starter IDs (ignored, please report): " .. table.concat(wrong, "; ") .. "|r")
    end

    -- What happened the last time a profession window was opened.
    local scan = ProfGuideForeverDB.lastScan
    if not scan then
        print(grey .. "  Profession window: not opened since the add-on was updated. Open it, then run /pg check again.|r")
    elseif scan.api == "none" then
        print(red .. "  Profession window: opened, but the add-on couldn't read it (please report).|r")
    else
        local age = scan.time and math.floor((time() - scan.time) / 60) or nil
        print(grey .. "  Last window scan (" .. scan.api .. (age and (", " .. age .. " min ago") or "") .. "): " .. scan.recipes .. " recipes seen, "
            .. scan.matched .. " on a route, " .. scan.saved .. " saved.|r")
        if #scan.examples > 0 then
            print(grey .. "  e.g. " .. table.concat(scan.examples, ", ") .. "|r")
        end
    end
end

-- ---------- Events ----------
-- The game announces things (bags changed, skill went up); we listen
-- with an invisible frame and refresh the panel.

local events = CreateFrame("Frame")
for _, e in ipairs({ "ADDON_LOADED", "PLAYER_LOGIN", "SKILL_LINES_CHANGED", "CHAT_MSG_SKILL",
                     "BAG_UPDATE_DELAYED", "BANKFRAME_OPENED", "TRADE_SKILL_SHOW",
                     "TRADE_SKILL_LIST_UPDATE", "TRADE_SKILL_DATA_SOURCE_CHANGED",
                     "TRADE_SKILL_UPDATE" }) do
    -- Some events only exist in some versions of WoW. Registering an
    -- unknown one is an error, so we try each safely and skip misses.
    pcall(events.RegisterEvent, events, e)
end

local scanQueued = false
local function QueueTradeSkillScan()
    -- These events fire in bursts; wait half a second and scan once.
    if scanQueued then return end
    scanQueued = true
    C_Timer.After(0.5, function()
        scanQueued = false
        local ok, err = pcall(ScanTradeSkill)
        if not ok then print("|cffff5555ProfGuide Forever scan error:|r " .. tostring(err)) end
        if ns.UI then ns.UI:Refresh() end
    end)
end

events:SetScript("OnEvent", function(self, event, arg1)
    if event == "ADDON_LOADED" then
        if arg1 == addonName then InitDB() end
        return
    end

    if event == "PLAYER_LOGIN" then
        pcall(ScanBags)
        -- Open on the profession you last viewed, or your first one.
        ns.state.prof = ProfGuideForeverDB.lastProf -- the UI swaps it if this character doesn't have it
        if ns.UI then ns.UI:Build() end
        if ns.Minimap then ns.Minimap:Build() end
        return
    end

    if event == "BAG_UPDATE_DELAYED" or event == "BANKFRAME_OPENED" then
        pcall(ScanBags)
    elseif event == "SKILL_LINES_CHANGED" or event == "CHAT_MSG_SKILL" then
        ns.state.viewIndex = nil -- skill moved: jump back to your current step
    elseif event:find("TRADE_SKILL") then
        QueueTradeSkillScan()
        return
    end

    if ns.UI then ns.UI:Refresh() end
end)

-- ---------- Slash commands ----------
-- /pg or /pgf  show or hide the panel (/pgf works even if another add-on uses /pg)
-- /pg check    check the current profession's data against the game
-- /pg reset    move the panel back to the middle-right of the screen
-- /pg minimap  hide or show the minimap button
-- /pg trainers list the nearest trainers for the current profession
SLASH_PROFGUIDEFOREVER1 = "/pgf"
SLASH_PROFGUIDEFOREVER2 = "/pg"
SLASH_PROFGUIDEFOREVER3 = "/profguide"
SlashCmdList.PROFGUIDEFOREVER = function(msg)
    msg = (msg or ""):lower():match("^%s*(.-)%s*$")
    if msg == "check" then
        Check()
    elseif msg == "trainers" or msg == "trainer" then
        if ns.Finder then ns.Finder.PrintNearest() end
    elseif msg == "minimap" then
        if ns.Minimap then ns.Minimap:Toggle() end
    elseif msg == "reset" then
        ProfGuideForeverDB.pos = nil
        if ns.UI and ns.UI.frame then
            ns.UI.frame:ClearAllPoints()
            ns.UI.frame:SetPoint("RIGHT", UIParent, "RIGHT", -80, 0)
        end
    elseif ns.UI then
        ns.UI:Toggle()
    end
end
