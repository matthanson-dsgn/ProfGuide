-- ============================================================
-- Settings.lua
-- The settings page in WoW's Options -> AddOns. Open it from the
-- gear icon on the guide, by right-clicking the minimap button,
-- or with /pg settings.
-- ============================================================

local addonName, ns = ...

local S = {}
ns.Settings = S

local controls = {} -- refreshed whenever the page opens

-- A tick box with a label and a grey help line underneath.
-- get() returns true/false; set(value) saves it.
local function CheckBox(panel, y, label, help, get, set)
    local cb = CreateFrame("CheckButton", nil, panel, "UICheckButtonTemplate")
    cb:SetSize(26, 26)
    cb:SetPoint("TOPLEFT", 16, y)
    local text = cb:CreateFontString(nil, "OVERLAY", "GameFontHighlight")
    text:SetPoint("LEFT", cb, "RIGHT", 6, 1)
    text:SetText(label)
    local sub = cb:CreateFontString(nil, "OVERLAY", "GameFontDisableSmall")
    sub:SetPoint("TOPLEFT", text, "BOTTOMLEFT", 0, -3)
    sub:SetText(help)
    cb:SetScript("OnClick", function(self)
        set(self:GetChecked() and true or false)
        if PlaySound and SOUNDKIT then
            pcall(PlaySound, self:GetChecked() and SOUNDKIT.IG_MAINMENU_OPTION_CHECKBOX_ON or SOUNDKIT.IG_MAINMENU_OPTION_CHECKBOX_OFF)
        end
    end)
    table.insert(controls, function() cb:SetChecked(get()) end)
    return cb
end

-- Panel size slider (80% to 130%), drawn with WoW's classic slider art.
local function SizeSlider(panel, y)
    local label = panel:CreateFontString(nil, "OVERLAY", "GameFontHighlight")
    label:SetPoint("TOPLEFT", 20, y)

    local sl = CreateFrame("Slider", nil, panel, "BackdropTemplate")
    sl:SetOrientation("HORIZONTAL")
    sl:SetSize(240, 17)
    sl:SetPoint("TOPLEFT", label, "BOTTOMLEFT", 0, -8)
    sl:SetBackdrop({
        bgFile = "Interface\\Buttons\\UI-SliderBar-Background",
        edgeFile = "Interface\\Buttons\\UI-SliderBar-Border",
        tile = true, tileSize = 8, edgeSize = 8,
        insets = { left = 3, right = 3, top = 6, bottom = 6 },
    })
    sl:SetThumbTexture("Interface\\Buttons\\UI-SliderBar-Button-Horizontal")
    sl:SetMinMaxValues(80, 130)
    sl:SetValueStep(5)
    if sl.SetObeyStepOnDrag then sl:SetObeyStepOnDrag(true) end

    local low = sl:CreateFontString(nil, "OVERLAY", "GameFontDisableSmall")
    low:SetPoint("TOPLEFT", sl, "BOTTOMLEFT", 2, -2)
    low:SetText("80%")
    local high = sl:CreateFontString(nil, "OVERLAY", "GameFontDisableSmall")
    high:SetPoint("TOPRIGHT", sl, "BOTTOMRIGHT", -2, -2)
    high:SetText("130%")

    sl:SetScript("OnValueChanged", function(_, value)
        value = math.floor(value / 5 + 0.5) * 5
        label:SetText("Panel size: " .. value .. "%")
        ProfGuideForeverDB.scale = value / 100
        if ns.UI and ns.UI.frame then ns.UI.frame:SetScale(ProfGuideForeverDB.scale) end
    end)
    table.insert(controls, function() sl:SetValue((ProfGuideForeverDB.scale or 1) * 100) end)
end

local function Button(panel, x, y, label, onClick)
    local b = CreateFrame("Button", nil, panel, "UIPanelButtonTemplate")
    b:SetSize(170, 24)
    b:SetPoint("TOPLEFT", x, y)
    b:SetText(label)
    b:SetScript("OnClick", onClick)
    return b
end

function S.Build()
    if S.panel then return end
    local panel = CreateFrame("Frame")
    panel.name = "ProfGuide Forever"
    S.panel = panel

    local title = panel:CreateFontString(nil, "OVERLAY", "GameFontNormalLarge")
    title:SetPoint("TOPLEFT", 16, -16)
    title:SetText("ProfGuide Forever")
    local version = (C_AddOns and C_AddOns.GetAddOnMetadata or GetAddOnMetadata)
    local v = version and version(addonName, "Version") or ""
    local sub = panel:CreateFontString(nil, "OVERLAY", "GameFontHighlightSmall")
    sub:SetPoint("TOPLEFT", title, "BOTTOMLEFT", 0, -6)
    sub:SetText("Version " .. tostring(v) .. "  -  in-game profession levelling guide")

    local db = function() return ProfGuideForeverDB end

    SizeSlider(panel, -70)

    CheckBox(panel, -130, "Lock position",
        "Stops the guide being dragged when it's not beside a profession window.",
        function() return db().locked end, function(v) db().locked = v end)

    CheckBox(panel, -175, "Open beside profession windows",
        "Opens the guide next to your profession window and switches to that profession.",
        function() return db().dock end,
        function(v) db().dock = v; if not v and ns.Dock then ns.Dock.Undock() end end)

    CheckBox(panel, -220, "Show minimap button",
        "The round ProfGuide button on the edge of your minimap.",
        function() return not (db().minimap and db().minimap.hide) end,
        function(v) if ns.Minimap then ns.Minimap:SetShown(v) end end)

    CheckBox(panel, -265, "Step complete pop-up",
        "Shows \"Step complete! Next: ...\" when you finish a step.",
        function() return db().toast end, function(v) db().toast = v end)

    CheckBox(panel, -310, "Play a sound with the pop-up",
        "The quest-complete sound.",
        function() return db().toastSound end, function(v) db().toastSound = v end)

    Button(panel, 20, -365, "Show welcome window", function() if ns.Welcome then ns.Welcome.Show() end end)
    Button(panel, 200, -365, "Reset position", function()
        if ns.Dock then ns.Dock.Undock() end
        ProfGuideForeverDB.pos = nil
        if ns.UI and ns.UI.frame then ns.UI:RestorePosition() end
    end)

    panel:SetScript("OnShow", function()
        for _, refresh in ipairs(controls) do refresh() end
    end)

    -- Add the page to WoW's options (newer clients first, then older).
    if Settings and Settings.RegisterCanvasLayoutCategory and Settings.RegisterAddOnCategory then
        local category = Settings.RegisterCanvasLayoutCategory(panel, panel.name)
        Settings.RegisterAddOnCategory(category)
        S.category = category
    elseif InterfaceOptions_AddCategory then
        InterfaceOptions_AddCategory(panel)
    end
end

-- Opens WoW's options on our page.
function S.Open()
    if not S.panel then S.Build() end
    if InCombatLockdown and InCombatLockdown() then
        print("|cffffd100ProfGuide Forever:|r settings can't be opened during combat.")
        return
    end
    if S.category and Settings and Settings.OpenToCategory then
        local id = S.category.GetID and S.category:GetID() or S.category.ID
        if pcall(Settings.OpenToCategory, id) then return end
    end
    if InterfaceOptionsFrame_OpenToCategory then
        InterfaceOptionsFrame_OpenToCategory(S.panel)
        InterfaceOptionsFrame_OpenToCategory(S.panel) -- twice: an old WoW quirk
    end
end
