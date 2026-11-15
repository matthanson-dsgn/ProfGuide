-- ============================================================
-- Dock.lua
-- Snaps the guide beside your profession window while it's open,
-- switches to that profession, and puts the guide back where it
-- was when you close the profession window.
-- Turn it on or off with /pg dock.
-- ============================================================

local addonName, ns = ...

local Dock = { active = false, autoOpened = false }
ns.Dock = Dock

-- The open profession window: the modern one, or the Classic one.
local function HostFrame()
    if ProfessionsFrame and ProfessionsFrame:IsShown() then return ProfessionsFrame end
    if TradeSkillFrame and TradeSkillFrame:IsShown() then return TradeSkillFrame end
end

-- Name of the profession that's open right now.
local function OpenProfessionName()
    if C_TradeSkillUI and C_TradeSkillUI.GetBaseProfessionInfo then
        local ok, base = pcall(C_TradeSkillUI.GetBaseProfessionInfo)
        if ok and base and base.professionName then return base.professionName end
    end
    if GetTradeSkillLine then
        local name = GetTradeSkillLine()
        if name and name ~= "UNKNOWN" then return name end
    end
end

function Dock.Undock()
    if not Dock.active then return end
    Dock.active = false
    local f = ns.UI and ns.UI.frame
    if not f then return end
    ns.UI:RestorePosition()
    -- Leave it how it was before the profession window opened.
    f:SetShown(not Dock.autoOpened)
    if f:IsShown() then ns.UI:Refresh() end
    Dock.autoOpened = false
end

function Dock.DockNow()
    if not (ProfGuideForeverDB and ProfGuideForeverDB.dock) then return end
    local host = HostFrame()
    local ui = ns.UI
    if not (host and ui and ui.frame) then return end

    local name = OpenProfessionName()
    if not Dock.active then Dock.autoOpened = not ui.frame:IsShown() end
    Dock.active = true

    -- A profession we don't guide (Fishing, Skinning, Mining...): hide.
    if not (name and ns.Professions[name]) then
        ui.frame:Hide()
        return
    end

    -- Switch to the profession you just opened.
    if ns.state.prof ~= name then
        ns.state.prof = name
        ns.state.viewIndex = nil
        ProfGuideForeverDB.lastProf = name
    end

    ui.frame:ClearAllPoints()
    -- 80px gap: clears the profession window's own tabs down its right
    -- edge, plus our round portrait, which pokes out to the left.
    ui.frame:SetPoint("TOPLEFT", host, "TOPRIGHT", 80, 0)
    ui.frame:Show()
    ui:Refresh()

    -- Put the guide back if the window closes without the usual event.
    if not host.profGuideHooked then
        host:HookScript("OnHide", Dock.Undock)
        host.profGuideHooked = true
    end
end

local events = CreateFrame("Frame")
-- DATA_SOURCE_CHANGED / LIST_UPDATE fire when you switch professions
-- inside the open window (e.g. Leatherworking -> Fishing).
for _, e in ipairs({ "TRADE_SKILL_SHOW", "TRADE_SKILL_CLOSE",
                     "TRADE_SKILL_DATA_SOURCE_CHANGED", "TRADE_SKILL_LIST_UPDATE" }) do
    pcall(events.RegisterEvent, events, e)
end
local pending = false
events:SetScript("OnEvent", function(_, event)
    if event == "TRADE_SKILL_CLOSE" then
        pcall(Dock.Undock)
        return
    end
    -- These fire in bursts: wait a moment, then check once.
    if pending then return end
    pending = true
    C_Timer.After(0.15, function()
        pending = false
        if HostFrame() then pcall(Dock.DockNow) end
    end)
end)

-- /pg dock: turn docking on or off.
function Dock.Toggle()
    ProfGuideForeverDB.dock = not ProfGuideForeverDB.dock
    if not ProfGuideForeverDB.dock then Dock.Undock() end
    print("|cffffd100ProfGuide Forever:|r docking beside the profession window is now "
        .. (ProfGuideForeverDB.dock and "on." or "off."))
end
