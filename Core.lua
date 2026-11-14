-- ============================================================
-- Core.lua
-- The "logic" layer: reads your skill and bags, works out which
-- step you're on and what you still need. No visuals here.
-- ============================================================

local addonName, ns = ...

-- Which profession the panel shows. Only one for now.
ns.activeProfession = "Leatherworking"

-- Panel state. viewIndex = nil means "follow my current skill";
-- a number means you've browsed to that step with prev/next.
ns.state = { viewIndex = nil, tab = "step" }

-- ---------- Reading the game ----------

-- Returns your current and max skill for a profession,
-- or nil if this character hasn't learned it.
function ns.GetSkill(prof)
    if not GetProfessions then return nil end
    -- GetProfessions gives up to 5 slots; empty slots are nil.
    local slots = { GetProfessions() }
    for i = 1, 5 do
        local index = slots[i]
        if index then
            local name, _, rank, maxRank, _, _, skillLine = GetProfessionInfo(index)
            if skillLine == prof.skillLine or name == prof.name then
                return rank, maxRank
            end
        end
    end
    return nil
end

-- How many of an item you own (bags + bank).
-- Newer clients keep this under C_Item; older ones have a plain function.
function ns.CountItem(itemID)
    if C_Item and C_Item.GetItemCount then
        return C_Item.GetItemCount(itemID, true) or 0
    elseif GetItemCount then
        return GetItemCount(itemID, true) or 0
    end
    return 0
end

-- Item icon, so materials look like they do in your bags.
function ns.ItemIcon(itemID)
    if C_Item and C_Item.GetItemIconByID then
        return C_Item.GetItemIconByID(itemID)
    elseif GetItemIcon then
        return GetItemIcon(itemID)
    end
    return 134400 -- the generic "?" icon
end

-- ---------- Working out the route ----------

-- The step your skill currently falls in.
function ns.CurrentStepIndex(prof, skill)
    skill = skill or 1
    for i, step in ipairs(prof.steps) do
        if skill < step.to then return i end
    end
    return #prof.steps -- maxed out: show the last step
end

-- Crafts still needed for a step. If you're halfway through
-- a step, it scales down (e.g. 20 crafts, half done = 10 left).
function ns.CraftsLeft(step, skill)
    skill = skill or 1
    if skill <= step.from then return step.crafts end
    if skill >= step.to then return 0 end
    local fraction = (step.to - skill) / (step.to - step.from)
    return math.ceil(step.crafts * fraction)
end

-- Materials for one step: a list of { id, need, have }.
function ns.StepMaterials(prof, step, skill)
    local crafts = ns.CraftsLeft(step, skill)
    -- When browsing a step you've finished, show the full amounts
    -- rather than zeros, so it's still useful as a reference.
    if crafts == 0 then crafts = step.crafts end

    local list = {}
    for _, mat in ipairs(step.mats) do
        local id, perCraft = mat[1], mat[2]
        table.insert(list, {
            id = id,
            need = perCraft * crafts,
            have = ns.CountItem(id),
        })
    end
    return list, crafts
end

-- Total shopping list from your current step to the end.
-- Skips things you craft yourself (their raw materials are
-- already counted in the step that makes them).
function ns.ShoppingList(prof, skill)
    local totals = {}
    local first = ns.CurrentStepIndex(prof, skill)
    for i = first, #prof.steps do
        local step = prof.steps[i]
        local crafts = ns.CraftsLeft(step, skill)
        for _, mat in ipairs(step.mats) do
            local id, perCraft = mat[1], mat[2]
            local info = prof.items[id]
            if crafts > 0 and not (info and info.crafted) then
                totals[id] = (totals[id] or 0) + perCraft * crafts
            end
        end
    end

    -- Turn into a list, biggest amounts first.
    local list = {}
    for id, need in pairs(totals) do
        table.insert(list, { id = id, need = need, have = ns.CountItem(id) })
    end
    table.sort(list, function(a, b) return a.need > b.need end)
    return list
end

-- ---------- Events ----------
-- The game "announces" things (bags changed, skill went up).
-- We listen with an invisible frame and refresh the panel.

local events = CreateFrame("Frame")
events:RegisterEvent("ADDON_LOADED")
events:RegisterEvent("PLAYER_LOGIN")
events:RegisterEvent("SKILL_LINES_CHANGED")   -- skill went up / learned
events:RegisterEvent("CHAT_MSG_SKILL")        -- "Your skill has increased"
events:RegisterEvent("BAG_UPDATE_DELAYED")    -- bags changed (fires once per batch)
events:RegisterEvent("TRADE_SKILL_LIST_UPDATE")

events:SetScript("OnEvent", function(self, event, arg1)
    if event == "ADDON_LOADED" then
        if arg1 ~= addonName then return end
        -- Saved settings (remembered between sessions).
        ProfGuideDB = ProfGuideDB or {}
        ProfGuideDB.shown = (ProfGuideDB.shown ~= false) -- shown by default
        return
    end

    if event == "PLAYER_LOGIN" then
        if ns.UI then ns.UI:Build() end
    end

    if event == "SKILL_LINES_CHANGED" or event == "CHAT_MSG_SKILL" then
        ns.state.viewIndex = nil -- skill moved: jump back to current step
    end

    if ns.UI and ns.UI.Refresh then ns.UI:Refresh() end
end)

-- ---------- Slash command ----------
-- Type /profguide or /pg in chat to show or hide the panel.
SLASH_PROFGUIDE1 = "/profguide"
SLASH_PROFGUIDE2 = "/pg"
SlashCmdList.PROFGUIDE = function()
    if ns.UI then ns.UI:Toggle() end
end
