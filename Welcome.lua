-- ============================================================
-- Welcome.lua
-- The welcome window: shown once, the first time the add-on
-- opens, and again any time from the help button or /pg help.
-- ============================================================

local addonName, ns = ...

local Welcome = {}
ns.Welcome = Welcome

local WIDTH = 380
local TEXT_W = WIDTH - 48

-- The window's text, in order. Kinds: "lead" (intro), "head" (gold
-- heading), "item" (indented point), "note" (grey small print).
local CONTENT = {
    { "lead", "Your profession levelling guide, right inside the game. No more tabbing out to read guides." },
    { "head", "What it does" },
    { "item", "Shows the next recipe to craft from 1 to 300 and follows your skill as you level." },
    { "item", "Counts the reagents in your bags and bank, with a shopping list all the way to 300." },
    { "item", "Snaps beside your profession window when you open it, and shows each recipe's skill-up colour." },
    { "item", "Fast or Budget routes, your nearest trainer, an Open recipe button, and costs: vendor prices, plus Auction House prices if you use TSM or Auctionator." },
    { "head", "Getting accurate data" },
    { "item", "Open each of your profession windows once. This checks every recipe and its reagents against the game (you'll see \"Materials checked in game\")." },
    { "item", "Visit a trade goods vendor. This saves the real prices for thread, dye, salt and vials (the \"est.\" label disappears)." },
    { "item", "Carry or open an item once so its icon and count are recognised." },
    { "note", "Until you've done these, some reagents and prices may be estimates." },
    { "head", "Handy commands" },
    { "item", "/pg or the minimap button: open or close the guide" },
    { "item", "/pg trainers: list your nearest trainers" },
    { "item", "/pg check: check the guide against the game" },
    { "item", "/pg dock: turn snapping beside the profession window on or off" },
    { "note", "Open this window again any time with the help button on the guide, or /pg help." },
}

local FONTS = {
    lead = "GameFontHighlight",
    head = "GameFontNormalLarge",
    item = "GameFontHighlightSmall",
    note = "GameFontDisableSmall",
}

local function Build()
    -- WoW-style window with a portrait; simple dark panel if unavailable.
    local ok, f = pcall(CreateFrame, "Frame", "ProfGuideForeverWelcome", UIParent, "ButtonFrameTemplate")
    if not ok or not f or not f.SetTitle then
        f = CreateFrame("Frame", "ProfGuideForeverWelcome", UIParent, "BackdropTemplate")
        f:SetBackdrop({ bgFile = "Interface\\Buttons\\WHITE8x8", edgeFile = "Interface\\Buttons\\WHITE8x8", edgeSize = 1 })
        f:SetBackdropColor(0.06, 0.06, 0.07, 0.96)
        f:SetBackdropBorderColor(0.35, 0.27, 0.18, 1)
        local title = f:CreateFontString(nil, "OVERLAY", "GameFontNormal")
        title:SetPoint("TOP", 0, -6)
        function f:SetTitle(text) title:SetText(text) end
        local close = CreateFrame("Button", nil, f, "UIPanelCloseButton")
        close:SetPoint("TOPRIGHT", 2, 2)
        f.CloseButton = close
    end
    if type(f.Inset) == "table" then
        f.Inset:ClearAllPoints()
        f.Inset:SetPoint("TOPLEFT", 4, -60)
        f.Inset:SetPoint("BOTTOMRIGHT", -6, 26)
    end

    f:SetWidth(WIDTH)
    f:SetFrameStrata("DIALOG") -- above the guide itself
    f:SetPoint("CENTER")
    f:SetClampedToScreen(true)
    f:SetMovable(true)
    f:EnableMouse(true)
    f:RegisterForDrag("LeftButton")
    f:SetScript("OnDragStart", f.StartMoving)
    f:SetScript("OnDragStop", f.StopMovingOrSizing)
    f:SetTitle("Welcome to ProfGuide Forever")
    if f.SetPortraitToAsset then
        pcall(f.SetPortraitToAsset, f, "Interface\\AddOns\\ProfGuideForever\\Media\\MinimapIcon")
    end
    tinsert(UISpecialFrames, "ProfGuideForeverWelcome") -- Esc closes it

    -- Lay out the text top to bottom, inside the inset.
    local y = -72
    local prevKind
    for _, entry in ipairs(CONTENT) do
        local kind, text = entry[1], entry[2]
        if kind == "head" then y = y - 10 end                       -- space above headings
        if kind == "note" and prevKind == "item" then y = y - 2 end
        local fs = f:CreateFontString(nil, "OVERLAY", FONTS[kind])
        fs:SetJustifyH("LEFT")
        fs:SetWordWrap(true)
        local indent = (kind == "item") and 14 or 0
        fs:SetPoint("TOPLEFT", 24 + indent, y)
        fs:SetWidth(TEXT_W - indent)
        fs:SetText(text)
        if kind == "item" then
            -- Small gold dash as the bullet.
            local dash = f:CreateFontString(nil, "OVERLAY", "GameFontNormalSmall")
            dash:SetPoint("TOPRIGHT", fs, "TOPLEFT", -5, 0)
            dash:SetText("-")
        end
        y = y - fs:GetStringHeight() - ((kind == "head") and 6 or 6)
        prevKind = kind
    end

    -- "Got it" closes the window (and it won't open by itself again).
    local ok2 = CreateFrame("Button", nil, f, "UIPanelButtonTemplate")
    ok2:SetSize(110, 22)
    ok2:SetText("Got it")
    ok2:SetPoint("BOTTOM", 0, 3)
    ok2:SetScript("OnClick", function() f:Hide() end)

    f:SetHeight(-y + 14 + 26)
    f:Hide()
    -- Set after the Hide above, so building the window doesn't count as
    -- "seen". Closing it any way (Got it, X or Esc) does.
    f:SetScript("OnHide", function() ProfGuideForeverDB.welcomeSeen = true end)
    Welcome.frame = f
end

function Welcome.Show()
    if not Welcome.frame then
        local ok, err = pcall(Build)
        if not ok then
            print("|cffff5555ProfGuide Forever error:|r " .. tostring(err))
            return
        end
    end
    Welcome.frame:Show()
    Welcome.frame:Raise()
end

-- First time only: called when the guide opens.
function Welcome.ShowIfFirstTime()
    if not ProfGuideForeverDB.welcomeSeen then Welcome.Show() end
end
