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
    if Dock.autoOpened then f:Hide() end -- we opened it, so we close it
    Dock.autoOpened = false
end

function Dock.DockNow()
    if not (ProfGuideForeverDB and ProfGuideForeverDB.dock) then return end
    local host = HostFrame()
    local ui = ns.UI
    if not (host and ui and ui.frame) then return end

    -- Switch to the profession you just opened (if it's on our list).
    local name = OpenProfessionName()
    if name and ns.Professions[name] and ns.state.prof ~= name then
        ns.state.prof = name
        ns.state.viewIndex = nil
        ProfGuideForeverDB.lastProf = name
    end

    if not Dock.active then Dock.autoOpened = not ui.frame:IsShown() end
    Dock.active = true
    ui.frame:ClearAllPoints()
    ui.frame:SetPoint("TOPLEFT", host, "TOPRIGHT", 6, 0)
    ui.frame:Show()
    ui:Refresh()

    -- Put the guide back if the window closes without the usual event.
    if not host.profGuideHooked then
        host:HookScript("OnHide", Dock.Undock)
        host.profGuideHooked = true
    end
end

local events = CreateFrame("Frame")
for _, e in ipairs({ "TRADE_SKILL_SHOW", "TRADE_SKILL_CLOSE" }) do
    pcall(events.RegisterEvent, events, e)
end
events:SetScript("OnEvent", function(_, event)
    if event == "TRADE_SKILL_SHOW" then
        -- Wait a moment so the profession window has finished opening.
        C_Timer.After(0.1, function() pcall(Dock.DockNow) end)
    else
        pcall(Dock.Undock)
    end
end)

-- /pg dock: turn docking on or off.
function Dock.Toggle()
    ProfGuideForeverDB.dock = not ProfGuideForeverDB.dock
    if not ProfGuideForeverDB.dock then Dock.Undock() end
    print("|cffffd100ProfGuide Forever:|r docking beside the profession window is now "
        .. (ProfGuideForeverDB.dock and "on." or "off."))
end
