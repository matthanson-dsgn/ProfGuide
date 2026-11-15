-- ============================================================
-- UI.lua
-- The "component" layer: builds the panel in WoW's own style and
-- draws whatever Core.lua works out.
--
-- Structure (like a WoW window):
--   Frame with portrait (profession icon), title and close button
--   Header row: skill bar + Fast/Budget switch
--   Inset: step details, nearest trainer, tips, reagents box
--   Bottom bar: Prev / My step / Next
--   Tabs under the frame: This step / Shopping list
--   Icon tabs on the right edge: your professions
-- WoW's built-in templates are used where available; if one is
-- missing, a simple fallback is drawn instead so nothing breaks.
-- ============================================================

local addonName, ns = ...

local UI = {}
ns.UI = UI

-- ---------- Design tokens ----------
local WIDTH    = 338
local INSET_L, INSET_R, INSET_TOP, INSET_BOTTOM = 4, 6, 58, 26
local PAD      = INSET_L + 10                  -- content's left edge
local INNER_W  = WIDTH - INSET_L - INSET_R - 20 -- content width
local ROW_H    = 26
local BOX_PAD  = 10
local ROW_W    = INNER_W - BOX_PAD * 2
local OPEN_W   = 92                            -- "Open recipe" button width

local GAP_ABOVE_RECIPE = 10
local GAP_IN_RECIPE    = 4
local GAP_BELOW_RECIPE = 16

local GOLD        = { 1, 0.82, 0 }
local WHITE       = { 1, 1, 1 }
local COLOR_OK    = { 0.40, 0.85, 0.45 }
local COLOR_SHORT = { 1.00, 0.50, 0.45 }
local COLOR_MUTED = { 0.62, 0.62, 0.62 }

local function Prof() return ns.ActiveProf() end

local function NewText(parent, font, justify)
    local fs = parent:CreateFontString(nil, "OVERLAY", font)
    fs:SetJustifyH(justify or "LEFT")
    fs:SetWordWrap(true)
    return fs
end

-- Puts a text element at a vertical position inside the inset.
local function Place(fs, y, width)
    fs:ClearAllPoints()
    fs:SetPoint("TOPLEFT", UI.frame, "TOPLEFT", PAD, y)
    fs:SetWidth(width or INNER_W)
    fs:Show()
end

-- Tries to create a frame from one of WoW's templates; returns nil if
-- that template doesn't exist in this version of the game.
local function TryCreate(kind, name, parent, template)
    local ok, frame = pcall(CreateFrame, kind, name, parent, template)
    if ok then return frame end
end

-- ---------- The window ----------

-- WoW-style window: stone frame, round portrait, title, close button.
local function CreateWindow()
    local f = TryCreate("Frame", "ProfGuideForeverFrame", UIParent, "ButtonFrameTemplate")
    if f and f.SetTitle then
        f.wowStyle = true
        if type(f.Inset) == "table" then
            f.Inset:ClearAllPoints()
            f.Inset:SetPoint("TOPLEFT", INSET_L, -INSET_TOP)
            f.Inset:SetPoint("BOTTOMRIGHT", -INSET_R, INSET_BOTTOM)
        end
        return f
    end

    -- Fallback: the flat panel from earlier versions.
    f = CreateFrame("Frame", "ProfGuideForeverFrame", UIParent, "BackdropTemplate")
    f:SetBackdrop({ bgFile = "Interface\\Buttons\\WHITE8x8", edgeFile = "Interface\\Buttons\\WHITE8x8", edgeSize = 1 })
    f:SetBackdropColor(0.06, 0.06, 0.07, 0.94)
    f:SetBackdropBorderColor(0.35, 0.27, 0.18, 1)
    f.TitleText = NewText(f, "GameFontNormal", "CENTER")
    f.TitleText:SetPoint("TOP", 0, -6)
    function f:SetTitle(text) self.TitleText:SetText(text) end
    local close = CreateFrame("Button", nil, f, "UIPanelCloseButton")
    close:SetPoint("TOPRIGHT", 2, 2)
    f.CloseButton = close
    return f
end

-- ---------- Reagent rows ----------
-- Made once and reused (a "pool"), like recycled list cells.
function UI:GetRow(i)
    if self.rows[i] then return self.rows[i] end

    local r = CreateFrame("Frame", nil, self.box)
    r:SetSize(ROW_W, ROW_H)

    r.icon = r:CreateTexture(nil, "ARTWORK")
    r.icon:SetSize(20, 20)
    r.icon:SetPoint("LEFT", 2, 0)

    -- Slot border, like an item button in your bags.
    r.slot = r:CreateTexture(nil, "OVERLAY")
    r.slot:SetSize(36, 36)
    r.slot:SetPoint("CENTER", r.icon, "CENTER")
    r.slot:SetTexture("Interface\\Buttons\\UI-Quickslot2")

    r.check = r:CreateTexture(nil, "OVERLAY")
    r.check:SetSize(14, 14)
    r.check:SetPoint("RIGHT")
    r.check:SetTexture("Interface\\RaidFrame\\ReadyCheck-Ready")

    r.count = NewText(r, "GameFontHighlight", "RIGHT")
    r.count:SetPoint("RIGHT", r.check, "LEFT", -6, 0)
    r.count:SetWordWrap(false)

    r.name = NewText(r, "GameFontHighlight", "LEFT")
    r.name:SetPoint("LEFT", r.icon, "RIGHT", 10, 0)
    r.name:SetWordWrap(false)

    r.badge = r:CreateTexture(nil, "OVERLAY")
    r.badge:SetSize(12, 12)
    r.badge:SetPoint("LEFT", r.name, "RIGHT", 5, 0)
    r.badge:SetTexCoord(0.08, 0.92, 0.08, 0.92)

    r:EnableMouse(true)
    -- Zone rows open the map when clicked.
    r:SetScript("OnMouseUp", function(row)
        if row.kind == "zone" then ns.Finder.OpenMap({ mapID = row.mapID }) end
    end)
    r:SetScript("OnEnter", function(row)
        GameTooltip:SetOwner(row, "ANCHOR_LEFT")
        if row.kind == "zone" then
            GameTooltip:AddLine(row.label, 1, 0.82, 0)
            GameTooltip:AddLine("Click to open the map.", 1, 1, 1)
            GameTooltip:Show()
            return
        elseif row.kind == "char" then
            GameTooltip:AddLine(row.label, 1, 0.82, 0)
            if row.seen then GameTooltip:AddLine("Last seen: " .. date("%d/%m/%Y", row.seen), 1, 1, 1) end
            GameTooltip:Show()
            return
        elseif row.kind ~= "item" then
            GameTooltip:Hide()
            return
        end
        local id = ns.ItemID(row.itemName)
        if id then
            GameTooltip:SetItemByID(id)
        else
            GameTooltip:SetText(row.itemName)
            GameTooltip:AddLine("Carry one or open your profession window so the add-on can recognise it.", 0.62, 0.62, 0.62, true)
        end
        if row.crafted then
            GameTooltip:AddLine(" ")
            GameTooltip:AddLine(row.craftedText, 1, 0.82, 0, true)
        end
        -- Vendor price: each, and for what you still need.
        local price, real = ns.VendorPrice(row.itemName)
        if price then
            GameTooltip:AddLine(" ")
            GameTooltip:AddDoubleLine("Vendor price (each)", ns.MoneyText(price) .. (real and "" or " (est.)"), 1, 0.82, 0, 1, 1, 1)
            local missing = math.max(0, (row.need or 0) - (row.have or 0))
            if missing > 0 then
                GameTooltip:AddDoubleLine("You need " .. missing .. " more", ns.MoneyText(missing * price), 1, 1, 1, 1, 1, 1)
            end
            if not real then
                GameTooltip:AddLine("Estimate. Open a vendor that sells it to get the real price.", 0.62, 0.62, 0.62, true)
            end
        elseif not row.crafted then
            local ah = ns.AuctionPrice(row.itemName)
            if ah then
                GameTooltip:AddLine(" ")
                GameTooltip:AddDoubleLine("Auction House (each)", ns.MoneyText(ah), 1, 0.82, 0, 1, 1, 1)
                local missing = math.max(0, (row.need or 0) - (row.have or 0))
                if missing > 0 then
                    GameTooltip:AddDoubleLine("You need " .. missing .. " more", ns.MoneyText(missing * ah), 1, 1, 1, 1, 1, 1)
                end
            end
        end
        GameTooltip:Show()
    end)
    r:SetScript("OnLeave", function() GameTooltip:Hide() end)

    self.rows[i] = r
    return r
end

-- Draws the reagents box at y. Returns the y position under it.
function UI:FillBox(label, list, y, craftedText, costList)
    local prof = Prof()
    local box = self.box
    box:ClearAllPoints()
    box:SetPoint("TOPLEFT", self.frame, "TOPLEFT", PAD, y)

    self.boxLabel:SetText(label)
    local rowsTop = -BOX_PAD - self.boxLabel:GetStringHeight() - 6

    for i, m in ipairs(list) do
        local r = self:GetRow(i)
        r:ClearAllPoints()
        r:SetPoint("TOPLEFT", box, "TOPLEFT", BOX_PAD, rowsTop - (i - 1) * ROW_H)

        local ok = m.have >= m.need
        r.kind = "item"
        r.slot:Show()
        r.itemName = m.name
        r.need, r.have = m.need, m.have
        r.crafted = m.crafted
        r.craftedText = craftedText
        r.icon:SetTexture(ns.ItemIcon(m.name))
        r.count:SetText(m.have .. " / " .. m.need)
        r.count:SetTextColor(unpack(ok and COLOR_OK or COLOR_SHORT))
        r.check:SetShown(ok)
        r.badge:SetShown(m.crafted)
        r.badge:SetTexture(prof.icon)

        -- Name sized to its text, never wider than the space left.
        r.name:SetText(m.name)
        local maxW = ROW_W - 22 - 10 - r.count:GetStringWidth() - 8 - 14 - 6
        if m.crafted then maxW = maxW - 17 end
        local textW = r.name.GetUnboundedStringWidth and r.name:GetUnboundedStringWidth() or r.name:GetStringWidth()
        r.name:SetWidth(math.min(textW + 1, maxW))
        r:Show()
    end
    for i = #list + 1, #self.rows do self.rows[i]:Hide() end

    local height = -rowsTop + #list * ROW_H + BOX_PAD - 4

    -- Cost footer: vendor items, Auction House items, and (on the
    -- shopping list) the total. Only lines that apply are shown.
    local lines = {}
    costList = costList or list
    local vendorCost, estimated, vendorItems = ns.VendorCost(costList)
    if vendorItems > 0 then
        if vendorCost > 0 then
            table.insert(lines, "|cffffd100Vendor:|r " .. ns.MoneyText(vendorCost)
                .. (estimated and "  |cff9d9d9d(est.)|r" or ""))
        else
            table.insert(lines, "|cffffd100Vendor:|r |cff66d977all in your bags|r")
        end
    end
    local addon = ns.PriceAddon()
    local ahCost, unpriced = 0, 0
    if addon then
        ahCost, unpriced = ns.AuctionCost(costList)
        if ahCost > 0 or unpriced > 0 then
            local text = "|cffffd100Auction House:|r " .. ns.MoneyText(ahCost) .. "  |cff9d9d9d(" .. addon .. ")|r"
            if unpriced > 0 then text = text .. "  |cff9d9d9d" .. unpriced .. " unpriced|r" end
            table.insert(lines, text)
        end
        if self.showTotal and (vendorCost + ahCost) > 0 then
            table.insert(lines, "|cffffd100Total to 300:|r " .. ns.MoneyText(vendorCost + ahCost))
        end
    elseif self.showTotal then
        table.insert(lines, "|cff9d9d9dInstall Auctionator or TSM to see Auction House prices.|r")
    end

    if #lines > 0 then
        self.boxFooter:SetText(table.concat(lines, "\n"))
        self.boxFooter:ClearAllPoints()
        self.boxFooter:SetPoint("TOPLEFT", box, "TOPLEFT", BOX_PAD, -(height - BOX_PAD + 10))
        self.boxFooter:Show()
        height = height + self.boxFooter:GetStringHeight() + 8
    else
        self.boxFooter:Hide()
    end
    box:SetHeight(height)
    box:Show()
    return y - height
end

-- A plain list in the box (zones, characters). Each entry:
-- { icon, text, right, rightColor, kind, label, mapID, seen, indent }
function UI:FillList(label, entries, y)
    local box = self.box
    box:ClearAllPoints()
    box:SetPoint("TOPLEFT", self.frame, "TOPLEFT", PAD, y)
    self.boxLabel:SetText(label)
    local rowsTop = -BOX_PAD - self.boxLabel:GetStringHeight() - 6

    for i, e in ipairs(entries) do
        local r = self:GetRow(i)
        r:ClearAllPoints()
        r:SetPoint("TOPLEFT", box, "TOPLEFT", BOX_PAD + (e.indent or 0), rowsTop - (i - 1) * ROW_H)
        r.kind, r.label, r.mapID, r.seen = e.kind, e.label or e.text, e.mapID, e.seen
        r.itemName, r.crafted = nil, false
        r.icon:SetTexture(e.icon)
        r.slot:SetShown(e.kind ~= "charprof")
        r.badge:Hide()
        r.check:SetShown(e.check or false)
        r.count:SetText(e.right or "")
        r.count:SetTextColor(unpack(e.rightColor or COLOR_MUTED))
        r.name:SetText(e.text)
        local maxW = ROW_W - 22 - 10 - r.count:GetStringWidth() - 8 - 14 - 6 - (e.indent or 0)
        local textW = r.name.GetUnboundedStringWidth and r.name:GetUnboundedStringWidth() or r.name:GetStringWidth()
        r.name:SetWidth(math.min(textW + 1, maxW))
        r:Show()
    end
    for i = #entries + 1, #self.rows do self.rows[i]:Hide() end

    self.boxFooter:Hide()
    local height = -rowsTop + #entries * ROW_H + BOX_PAD - 4
    box:SetHeight(height)
    box:Show()
    return y - height
end

-- ---------- Building the panel (runs once) ----------
function UI:Build()
    if self.frame then return end
    self.rows = {}

    local f = CreateWindow()
    self.frame = f
    f:SetSize(WIDTH, 400)
    f:SetScale(ProfGuideForeverDB.scale or 1) -- "Panel size" setting
    f:SetFrameStrata("MEDIUM")
    f:SetClampedToScreen(true)
    f:SetToplevel(true)

    -- Drag to move; remember where you left it.
    f:SetMovable(true)
    f:EnableMouse(true)
    f:RegisterForDrag("LeftButton")
    -- While docked beside the profession window, it stays put.
    f:SetScript("OnDragStart", function(frame)
        if ns.Dock and ns.Dock.active then return end
        if ProfGuideForeverDB.locked then return end -- "Lock position" setting
        frame:StartMoving()
    end)
    f:SetScript("OnDragStop", function(frame)
        frame:StopMovingOrSizing()
        if ns.Dock and ns.Dock.active then return end
        local point, _, relPoint, x, y = frame:GetPoint()
        ProfGuideForeverDB.pos = { point, relPoint, x, y }
    end)
    self:RestorePosition()
    tinsert(UISpecialFrames, "ProfGuideForeverFrame") -- Esc closes it

    if type(f.CloseButton) == "table" then
        f.CloseButton:SetScript("OnClick", function() UI:Toggle(false) end)
    end

    -- Help button in the title bar, left of the close button: WoW's
    -- question-mark icon, drawn by us so it works in every version.
    local help = CreateFrame("Button", nil, f)
    help:SetSize(18, 18)
    local helpIcon = help:CreateTexture(nil, "ARTWORK")
    helpIcon:SetAllPoints()
    helpIcon:SetTexture("Interface\\Icons\\INV_Misc_QuestionMark")
    helpIcon:SetTexCoord(0.08, 0.92, 0.08, 0.92)
    local helpBorder = help:CreateTexture(nil, "OVERLAY")
    helpBorder:SetSize(32, 32)
    helpBorder:SetPoint("CENTER")
    helpBorder:SetTexture("Interface\\Buttons\\UI-Quickslot2")
    help:SetHighlightTexture("Interface\\Buttons\\ButtonHilight-Square", "ADD")
    help:SetScript("OnMouseDown", function() helpIcon:SetPoint("TOPLEFT", 1, -1); helpIcon:SetPoint("BOTTOMRIGHT", 1, -1) end)
    help:SetScript("OnMouseUp", function() helpIcon:SetAllPoints() end)
    if type(f.CloseButton) == "table" then
        help:SetPoint("RIGHT", f.CloseButton, "LEFT", -4, 0)
    else
        help:SetPoint("TOPRIGHT", -30, -4)
    end
    -- Same layer as the close button, so the window's border art
    -- (which sits on a high layer) doesn't cover it.
    local level = f:GetFrameLevel() + 10
    if type(f.CloseButton) == "table" then level = math.max(level, f.CloseButton:GetFrameLevel()) end
    if type(f.NineSlice) == "table" and f.NineSlice.GetFrameLevel then level = math.max(level, f.NineSlice:GetFrameLevel() + 1) end
    help:SetFrameLevel(level)
    help:SetScript("OnClick", function() if ns.Welcome then ns.Welcome.Show() end end)
    help:SetScript("OnEnter", function(btn)
        GameTooltip:SetOwner(btn, "ANCHOR_TOP")
        GameTooltip:AddLine("Help", 1, 0.82, 0)
        GameTooltip:AddLine("What ProfGuide Forever does, and how to keep its data accurate.", 1, 1, 1, true)
        GameTooltip:Show()
    end)
    help:SetScript("OnLeave", function() GameTooltip:Hide() end)
    self.helpBtn = help

    -- Settings button (gear icon), left of the help button.
    local gear = CreateFrame("Button", nil, f)
    gear:SetSize(18, 18)
    gear:SetPoint("RIGHT", help, "LEFT", -6, 0)
    gear:SetFrameLevel(level)
    local gearIcon = gear:CreateTexture(nil, "ARTWORK")
    gearIcon:SetAllPoints()
    gearIcon:SetTexture("Interface\\Icons\\INV_Misc_Gear_01")
    gearIcon:SetTexCoord(0.08, 0.92, 0.08, 0.92)
    local gearBorder = gear:CreateTexture(nil, "OVERLAY")
    gearBorder:SetSize(32, 32)
    gearBorder:SetPoint("CENTER")
    gearBorder:SetTexture("Interface\\Buttons\\UI-Quickslot2")
    gear:SetHighlightTexture("Interface\\Buttons\\ButtonHilight-Square", "ADD")
    gear:SetScript("OnClick", function() if ns.Settings then ns.Settings.Open() end end)
    gear:SetScript("OnEnter", function(btn)
        GameTooltip:SetOwner(btn, "ANCHOR_TOP")
        GameTooltip:AddLine("Settings", 1, 0.82, 0)
        GameTooltip:AddLine("Panel size, lock, docking, minimap button and pop-ups.", 1, 1, 1, true)
        GameTooltip:Show()
    end)
    gear:SetScript("OnLeave", function() GameTooltip:Hide() end)
    self.gearBtn = gear

    -- Fallback panels have no portrait, so content starts further left.
    local headerX = f.wowStyle and 62 or PAD

    -- Skill bar, like the rank bar in the profession window.
    local barWrap = CreateFrame("Frame", nil, f, "BackdropTemplate")
    barWrap:SetPoint("TOPLEFT", headerX, -30)
    barWrap:SetSize(WIDTH - headerX - 126, 16)
    barWrap:SetBackdrop({
        bgFile = "Interface\\Buttons\\WHITE8x8",
        edgeFile = "Interface\\Tooltips\\UI-Tooltip-Border", edgeSize = 10,
        insets = { left = 2, right = 2, top = 2, bottom = 2 },
    })
    barWrap:SetBackdropColor(0, 0, 0, 0.6)
    barWrap:SetBackdropBorderColor(0.75, 0.6, 0.35, 1)
    local bar = CreateFrame("StatusBar", nil, barWrap)
    bar:SetPoint("TOPLEFT", 3, -3)
    bar:SetPoint("BOTTOMRIGHT", -3, 3)
    bar:SetStatusBarTexture("Interface\\TargetingFrame\\UI-StatusBar")
    bar:SetStatusBarColor(0.15, 0.55, 0.15) -- WoW's skill-bar green
    bar:SetMinMaxValues(0, 300)
    self.bar = bar
    self.skillText = NewText(bar, "GameFontHighlightSmall", "CENTER")
    self.skillText:SetPoint("CENTER", 0, 0)

    self:BuildRouteToggle()

    -- Content inside the inset
    self.eyebrow = NewText(f, "GameFontDisableSmall")
    self.recipe  = NewText(f, "GameFontNormalLarge") -- gold, like recipe names in game
    self.meta    = NewText(f, "GameFontHighlightSmall")
    self.note    = NewText(f, "GameFontNormalSmall")
    self.empty   = NewText(f, "GameFontHighlight", "CENTER")

    -- "Open recipe": jumps to the recipe in your profession window.
    local open = CreateFrame("Button", nil, f, "UIPanelButtonTemplate")
    open:SetSize(OPEN_W, 20)
    open:SetText("Open recipe")
    open:SetScript("OnClick", function()
        local prof = Prof()
        local index = math.min(ns.state.viewIndex or ns.CurrentStepIndex(prof, (ns.GetSkill(prof))), #prof.steps)
        ns.OpenRecipe(prof, prof.steps[index])
    end)
    open:SetScript("OnEnter", function(btn)
        GameTooltip:SetOwner(btn, "ANCHOR_TOP")
        GameTooltip:AddLine("Open recipe", 1, 0.82, 0)
        if btn.notLearned then
            GameTooltip:AddLine("Learn this recipe first.", 1, 0.5, 0.45, true)
        else
            GameTooltip:AddLine("Opens your profession window on this recipe.", 1, 1, 1, true)
        end
        GameTooltip:Show()
    end)
    open:SetScript("OnLeave", function() GameTooltip:Hide() end)
    if open.SetMotionScriptsWhileDisabled then open:SetMotionScriptsWhileDisabled(true) end -- tooltip even when greyed out
    self.openBtn = open

    -- Red "Not learned yet" badge, shown beside the Open recipe button.
    local badge = CreateFrame("Frame", nil, f, "BackdropTemplate")
    badge:SetBackdrop({ bgFile = "Interface\\Buttons\\WHITE8x8", edgeFile = "Interface\\Buttons\\WHITE8x8", edgeSize = 1 })
    badge:SetBackdropColor(0.45, 0.05, 0.05, 0.9)
    badge:SetBackdropBorderColor(0.9, 0.25, 0.2, 1)
    badge.text = NewText(badge, "GameFontHighlightSmall", "CENTER")
    badge.text:SetPoint("CENTER")
    badge.text:SetText("Not learned yet")
    badge:SetSize(badge.text:GetStringWidth() + 16, 20)
    badge:EnableMouse(true)
    badge:SetScript("OnEnter", function(b)
        GameTooltip:SetOwner(b, "ANCHOR_TOP")
        GameTooltip:AddLine("Not learned yet", 1, 0.82, 0)
        GameTooltip:AddLine("Learn this recipe from: " .. (b.source or "a trainer"), 1, 1, 1, true)
        GameTooltip:Show()
    end)
    badge:SetScript("OnLeave", function() GameTooltip:Hide() end)
    badge:Hide()
    self.learnBadge = badge

    -- Extra line spacing so the details aren't cramped.
    self.meta:SetSpacing(4)
    self.note:SetSpacing(3)

    -- "Nearest trainer" line: click to open the map, hover for more.
    local tb = CreateFrame("Button", nil, f)
    tb:SetSize(INNER_W, 16)
    tb.text = NewText(tb, "GameFontHighlightSmall")
    tb.text:SetPoint("TOPLEFT")
    tb.text:SetWidth(INNER_W)
    tb:SetScript("OnClick", function(btn) ns.Finder.OpenMap(btn.trainers and btn.trainers[1]) end)
    tb:SetScript("OnEnter", function(btn)
        btn.text:SetAlpha(0.75)
        GameTooltip:SetOwner(btn, "ANCHOR_RIGHT")
        GameTooltip:AddLine("Nearest trainers", 1, 0.82, 0)
        for _, e in ipairs(btn.trainers or {}) do
            GameTooltip:AddDoubleLine(e.name, ns.Finder.DistanceText(e), 1, 1, 1, 0.62, 0.62, 0.62)
            GameTooltip:AddLine("   " .. e.zone .. ", " .. e.where, 0.62, 0.62, 0.62)
        end
        GameTooltip:AddLine(" ")
        GameTooltip:AddLine("Click to open the map.", 1, 1, 1)
        GameTooltip:AddLine("City guards will mark any trainer on your map.", 0.62, 0.62, 0.62, true)
        GameTooltip:Show()
    end)
    tb:SetScript("OnLeave", function(btn) btn.text:SetAlpha(1); GameTooltip:Hide() end)
    tb:Hide()
    self.trainerBtn = tb

    -- Reagents box: dark fill with a soft gold edge.
    local box = CreateFrame("Frame", nil, f, "BackdropTemplate")
    box:SetWidth(INNER_W)
    box:SetBackdrop({
        bgFile = "Interface\\Buttons\\WHITE8x8",
        edgeFile = "Interface\\Tooltips\\UI-Tooltip-Border", edgeSize = 12,
        insets = { left = 3, right = 3, top = 3, bottom = 3 },
    })
    box:SetBackdropColor(0, 0, 0, 0.35)
    box:SetBackdropBorderColor(0.6, 0.5, 0.3, 0.9)
    self.box = box
    self.boxLabel = NewText(box, "GameFontNormal") -- gold "Reagents:"
    self.boxLabel:SetPoint("TOPLEFT", BOX_PAD, -BOX_PAD)
    self.boxLabel:SetWidth(ROW_W)
    -- Footer: total cost of shop-bought ingredients you still need.
    self.boxFooter = NewText(box, "GameFontHighlightSmall")
    self.boxFooter:SetWidth(ROW_W)

    self.summary = NewText(f, "GameFontHighlightSmall")
    self.summary:SetPoint("BOTTOMLEFT", 12, 8)

    -- Bottom bar buttons
    local function MakeButton(label, width, onClick)
        local b = CreateFrame("Button", nil, f, "UIPanelButtonTemplate")
        b:SetSize(width, 22)
        b:SetText(label)
        b:SetScript("OnClick", onClick)
        return b
    end
    local function Browse(delta)
        local prof = Prof()
        local index = (ns.state.viewIndex or ns.CurrentStepIndex(prof, (ns.GetSkill(prof)))) + delta
        ns.state.viewIndex = math.max(1, math.min(#prof.steps, index))
        UI:Refresh()
    end
    self.prevBtn = MakeButton("< Prev", 80, function() Browse(-1) end)
    self.prevBtn:SetPoint("BOTTOMLEFT", 6, 3)
    self.nextBtn = MakeButton("Next >", 80, function() Browse(1) end)
    self.nextBtn:SetPoint("BOTTOMRIGHT", -8, 3)
    self.currentBtn = MakeButton("My step", 90, function()
        ns.state.viewIndex = nil
        UI:Refresh()
    end)
    self.currentBtn:SetPoint("BOTTOM", 0, 3)

    self:BuildPanelTabs()

    f:SetShown(ProfGuideForeverDB.shown)
    self:Refresh()
    if f:IsShown() and ns.Welcome then ns.Welcome.ShowIfFirstTime() end
end

-- ---------- Tabs under the window: This step / Shopping list ----------
function UI:BuildPanelTabs()
    local f = self.frame
    local labels = { "This step", "Shopping list", "Characters" }
    local keys = { "step", "shop", "alts" }
    self.panelTabs = {}
    f.Tabs = {}
    for i, label in ipairs(labels) do
        local tab = TryCreate("Button", "ProfGuideForeverFrameTab" .. i, f, "PanelTabButtonTemplate")
            or CreateFrame("Button", "ProfGuideForeverFrameTab" .. i, f, "UIPanelButtonTemplate")
        tab:SetID(i)
        tab:SetText(label)
        if PanelTemplates_TabResize then pcall(PanelTemplates_TabResize, tab, 0) end
        if tab:GetWidth() < 60 then tab:SetSize(100, 24) end
        if i == 1 then
            tab:SetPoint("TOPLEFT", f, "BOTTOMLEFT", 11, 2)
        else
            tab:SetPoint("LEFT", self.panelTabs[i - 1], "RIGHT", 3, 0)
        end
        tab:SetScript("OnClick", function()
            ns.state.tab = keys[i]
            if PlaySound and SOUNDKIT then pcall(PlaySound, SOUNDKIT.IG_CHARACTER_INFO_TAB) end
            UI:Refresh()
        end)
        self.panelTabs[i] = tab
        f.Tabs[i] = tab
    end
    if PanelTemplates_SetNumTabs then pcall(PanelTemplates_SetNumTabs, f, #labels) end
end

-- ---------- Fast / Budget switch ----------
local ROUTE_HELP = {
    fast = "Fewest crafts. Some steps use pricier materials (gems, elixirs, scorpid scales).",
    budget = "Cheaper, common materials. A few more crafts.",
}

function UI:BuildRouteToggle()
    local wrap = CreateFrame("Frame", nil, self.frame, "BackdropTemplate")
    wrap:SetSize(104, 20)
    wrap:SetPoint("TOPRIGHT", -10, -28)
    wrap:SetBackdrop({
        bgFile = "Interface\\Buttons\\WHITE8x8",
        edgeFile = "Interface\\Tooltips\\UI-Tooltip-Border", edgeSize = 10,
        insets = { left = 2, right = 2, top = 2, bottom = 2 },
    })
    wrap:SetBackdropColor(0, 0, 0, 0.6)
    wrap:SetBackdropBorderColor(0.75, 0.6, 0.35, 1)
    self.routeToggle = wrap
    self.routeButtons = {}

    for i, key in ipairs({ "fast", "budget" }) do
        local b = CreateFrame("Button", nil, wrap)
        b:SetSize(48, 14)
        b:SetPoint("LEFT", 4 + (i - 1) * 48, 0)
        b.fill = b:CreateTexture(nil, "BACKGROUND")
        b.fill:SetAllPoints()
        b.fill:SetColorTexture(1, 0.82, 0, 0.25) -- gold tint when selected
        b.text = NewText(b, "GameFontHighlightSmall", "CENTER")
        b.text:SetPoint("CENTER")
        b.text:SetText(key == "fast" and "Fast" or "Budget")
        b:SetScript("OnClick", function()
            local _, def = ns.ActiveProf()
            ns.SetRoute(def.name, key)
            UI:Refresh()
        end)
        b:SetScript("OnEnter", function(btn)
            GameTooltip:SetOwner(btn, "ANCHOR_TOP")
            GameTooltip:AddLine(btn.text:GetText() .. " route", 1, 0.82, 0)
            GameTooltip:AddLine(ROUTE_HELP[key], 1, 1, 1, true)
            GameTooltip:Show()
        end)
        b:SetScript("OnLeave", function() GameTooltip:Hide() end)
        self.routeButtons[key] = b
    end
end

-- ---------- Which profession to show ----------
-- The guide follows the profession window you open (see Dock.lua).
-- On its own it shows the last one you viewed, as long as this
-- character has it; otherwise their first profession.
function UI:EnsureLearnedProfession()
    local learned = ns.LearnedProfessions()
    for _, p in ipairs(learned) do
        if p.name == ns.state.prof then return true end
    end
    if learned[1] then
        ns.state.prof = learned[1].name
        ns.state.viewIndex = nil
        return true
    end
    return false
end

-- ---------- Drawing (runs whenever something changes) ----------
-- Refresh runs Draw "safely": if anything breaks, the error is
-- printed in chat instead of failing silently.
local lastError
function UI:Refresh()
    if not self.frame then return end
    local ok, err = pcall(self.Draw, self)
    if not ok and err ~= lastError then
        lastError = err
        print("|cffff5555ProfGuide Forever error:|r " .. tostring(err))
    end
end

local function HideContent(self)
    self.eyebrow:Hide(); self.recipe:Hide(); self.meta:Hide(); self.note:Hide()
    self.trainerBtn:Hide(); self.openBtn:Hide(); self.learnBadge:Hide(); self.box:Hide(); self.empty:Hide()
    self.prevBtn:Hide(); self.nextBtn:Hide(); self.currentBtn:Hide(); self.summary:Hide()
    for _, r in ipairs(self.rows) do r:Hide() end
end

function UI:Draw()
    local f = self.frame
    local hasAny = self:EnsureLearnedProfession()

    -- Empty state: this character has no professions yet.
    if not hasAny then
        HideContent(self)
        if ns.state.tab == "alts" then -- the Characters tab still works
            f:SetTitle("ProfGuide Forever")
            self.routeToggle:Hide()
            self.skillText:SetText(""); self.bar:SetValue(0)
            if PanelTemplates_SetTab then pcall(PanelTemplates_SetTab, f, 3) end
            f:SetHeight(-self:DrawCharacters(-INSET_TOP - 10) + 12 + INSET_BOTTOM)
            return
        end
        f:SetTitle("ProfGuide Forever")
        if f.SetPortraitToAsset then pcall(f.SetPortraitToAsset, f, "Interface\\AddOns\\ProfGuideForever\\Media\\MinimapIcon") end
        self.skillText:SetText("")
        self.bar:SetValue(0)
        self.routeToggle:Hide()
        Place(self.empty, -INSET_TOP - 30)
        self.empty:SetText("You haven't learned a profession yet.\n\nVisit a profession trainer in any major city, then come back here for your levelling guide.")
        f:SetHeight(INSET_TOP + 30 + self.empty:GetStringHeight() + 30 + INSET_BOTTOM)
        return
    end

    local prof, def = ns.ActiveProf()
    local skill, maxSkill = ns.GetSkill(prof)
    local current = ns.CurrentStepIndex(prof, skill)

    -- Header: title, portrait, skill bar
    f:SetTitle(prof.name)
    if f.SetPortraitToAsset then pcall(f.SetPortraitToAsset, f, prof.icon) end
    if skill then
        self.skillText:SetText(skill .. " / " .. maxSkill)
        self.bar:SetValue(skill)
    else
        self.skillText:SetText("Not learned")
        self.bar:SetValue(0)
    end

    -- Route switch: only for professions with more than one route.
    self.routeToggle:SetShown(def.views.budget ~= nil)
    for key, b in pairs(self.routeButtons) do
        local on = (key == prof.routeKey)
        b.fill:SetShown(on)
        b.text:SetTextColor(unpack(on and WHITE or COLOR_MUTED))
    end

    -- Bottom tabs
    local onStep = (ns.state.tab == "step")
    local tabIndex = ({ step = 1, shop = 2, alts = 3 })[ns.state.tab] or 1
    if PanelTemplates_SetTab then pcall(PanelTemplates_SetTab, f, tabIndex) end

    HideContent(self)
    local y = -INSET_TOP - 10

    if ns.state.tab == "alts" then
        y = self:DrawCharacters(y)
    elseif onStep and prof.gathering then
        y = self:DrawGatheringStep(prof, skill, maxSkill, current, y)
    elseif not onStep and prof.gathering then
        y = self:FillList("Gathering professions don't need materials. Just head to the zones on the This step tab.", {}, y)
    elseif onStep then
        -- Clamp, in case you browsed a longer route or profession.
        local index = math.min(ns.state.viewIndex or current, #prof.steps)
        local step = prof.steps[index]
        local mats, crafts, verified = ns.StepMaterials(prof, step, skill)

        local label = "STEP " .. index .. " OF " .. #prof.steps .. "   SKILL " .. step.from .. "-" .. step.to
        if index ~= current then label = label .. "   (browsing)" end
        Place(self.eyebrow, y); self.eyebrow:SetText(label)
        y = y - self.eyebrow:GetStringHeight() - GAP_ABOVE_RECIPE

        -- Recipe name on its own, full width.
        Place(self.recipe, y); self.recipe:SetText(step.recipe)
        y = y - self.recipe:GetStringHeight() - 8

        -- Button row: Open recipe, plus a red badge if you haven't learned it.
        local known = ns.IsKnown(step.recipe)
        self.openBtn:ClearAllPoints()
        self.openBtn:SetPoint("TOPLEFT", f, "TOPLEFT", PAD - 2, y)
        -- Greyed out for professions or recipes you haven't learned.
        self.openBtn:SetEnabled(skill ~= nil and known ~= false)
        self.openBtn.notLearned = (known == false)
        self.openBtn:Show()
        if known == false then
            self.learnBadge.source = step.source
            self.learnBadge:ClearAllPoints()
            self.learnBadge:SetPoint("LEFT", self.openBtn, "RIGHT", 8, 0)
            self.learnBadge:Show()
        end
        y = y - 22 - 12

        local meta = "Make about " .. crafts .. ".  Learn from: " .. step.source
        local status = {}
        -- Skill-up colour from your last profession-window scan.
        local diffKey, diffSkill = ns.RecipeDifficulty(step.recipe)
        local diff = diffKey and ns.DIFFICULTY[diffKey]
        if diff and known ~= false then
            local text = "|cff" .. diff.hex .. diff.label .. "|r: " .. diff.help
            if diffSkill and skill and diffSkill ~= skill then text = text .. " (at " .. diffSkill .. ")" end
            table.insert(status, text)
        end
        if #status > 0 then meta = meta .. "\n" .. table.concat(status, "\n") end
        Place(self.meta, y); self.meta:SetText(meta)
        self.meta:SetTextColor(unpack(COLOR_MUTED))
        y = y - self.meta:GetStringHeight()

        -- Nearest trainer: profession or recipe not learned, or a rank due.
        local rankTips, capped = ns.RankTips(prof, step, skill, maxSkill)
        local needRank = (index == current) and (capped or #rankTips > 0)
        local needRecipe = (known == false and step.source == "Trainer")
        local trainers = {}
        if (skill == nil or needRank or needRecipe) and ns.Finder then
            local need = ns.Finder.NeedSkill(skill, maxSkill)
            if needRank and maxSkill and maxSkill < 300 then need = maxSkill + 75 end
            trainers = ns.Finder.Nearest(prof.name, need, 3)
        end
        if #trainers > 0 then
            local e = trainers[1]
            local dist = ns.Finder.DistanceText(e)
            self.trainerBtn.trainers = trainers
            self.trainerBtn.text:SetText("|cffffd100Nearest trainer:|r " .. e.name .. ", " .. e.zone
                .. (dist ~= "" and ("  |cff9d9d9d(" .. dist .. ")|r") or ""))
            y = y - 10
            self.trainerBtn:ClearAllPoints()
            self.trainerBtn:SetPoint("TOPLEFT", f, "TOPLEFT", PAD, y)
            self.trainerBtn:SetHeight(self.trainerBtn.text:GetStringHeight())
            self.trainerBtn:Show()
            y = y - self.trainerBtn.text:GetStringHeight()
        end
        y = y - GAP_BELOW_RECIPE

        -- Tips
        local lines = {}
        if step.note then table.insert(lines, "Tip: " .. step.note) end
        for _, t in ipairs(rankTips) do table.insert(lines, t) end
        if capped and index == current then
            table.insert(lines, "|cffff7a6bYou've hit your skill cap. Train the next rank to keep levelling.|r")
        end
        if index == current and known ~= false and (diffKey == "easy" or diffKey == "trivial") and index < #prof.steps then
            table.insert(lines, "Skill-ups are " .. (diffKey == "easy" and "slowing down" or "over") .. " on this recipe. Consider moving to the next step.")
        end
        if #lines > 0 then
            Place(self.note, y); self.note:SetText(table.concat(lines, "\n"))
            y = y - self.note:GetStringHeight() - 12
        end

        self.showTotal = false
        y = self:FillBox("Reagents:", mats, y, "You craft this in an earlier step.")

        self.prevBtn:Show(); self.nextBtn:Show(); self.currentBtn:Show()
        self.prevBtn:SetEnabled(index > 1)
        self.nextBtn:SetEnabled(index < #prof.steps)
        self.currentBtn:SetEnabled(index ~= current)
    else
        local list = ns.ShoppingList(prof, skill)
        local MAX_ROWS = 15
        local shown = list
        if #list > MAX_ROWS then
            shown = {}
            for k = 1, MAX_ROWS do shown[k] = list[k] end
        end
        local label = (#list > 0) and "Everything to gather or buy from here to 300:" or "Nothing left to get. Nice work!"
        -- Costs use the full list, even if only the biggest rows are shown.
        self.showTotal = true
        y = self:FillBox(label, shown, y, nil, list)

        local ready = 0
        for _, m in ipairs(list) do
            if m.have >= m.need then ready = ready + 1 end
        end
        local summary = ready .. " of " .. #list .. " materials ready"
        if #list > #shown then summary = summary .. "  (showing the biggest " .. #shown .. ")" end
        self.summary:SetText(summary)
        self.summary:SetTextColor(unpack(COLOR_MUTED))
        self.summary:Show()
    end

    f:SetHeight(-y + 12 + INSET_BOTTOM)
end

-- Characters tab: every character's professions and skill.
function UI:DrawCharacters(y)
    local roster = ProfGuideForeverDB.roster or {}
    local me = ns.CurrentCharKey()
    local keys = {}
    for key in pairs(roster) do table.insert(keys, key) end
    -- You first, then by name.
    table.sort(keys, function(a, b)
        if a == me then return true elseif b == me then return false end
        return a < b
    end)

    local entries = {}
    for _, key in ipairs(keys) do
        local c = roster[key]
        local colour = (RAID_CLASS_COLORS and c.class and RAID_CLASS_COLORS[c.class]) or { r = 1, g = 1, b = 1 }
        local hex = string.format("|cff%02x%02x%02x", math.floor(colour.r * 255), math.floor(colour.g * 255), math.floor(colour.b * 255))
        table.insert(entries, {
            kind = "char", seen = c.seen,
            icon = c.class and ("Interface\\Icons\\ClassIcon_" .. c.class) or 134400,
            text = hex .. (c.name or key) .. "|r",
            label = (c.name or key) .. " - " .. (c.realm or ""),
            right = c.level and ("Level " .. c.level) or "",
        })
        local names = {}
        for profName in pairs(c.profs or {}) do table.insert(names, profName) end
        table.sort(names)
        if #names == 0 then
            table.insert(entries, { kind = "charprof", indent = 16, icon = nil, text = "|cff9d9d9dNo professions yet|r" })
        end
        for _, profName in ipairs(names) do
            local p = c.profs[profName]
            local def = ns.Professions[profName]
            table.insert(entries, {
                kind = "charprof", indent = 16,
                icon = def and def.icon or 134400,
                text = profName,
                right = p[1] .. " / " .. p[2],
                rightColor = (p[1] >= 300) and COLOR_OK or WHITE,
                check = p[1] >= 300,
            })
        end
    end
    local label = (#keys > 0) and "Your characters:" or "Log in on each character once to see them here."
    y = self:FillList(label, entries, y)
    return y
end

-- Gathering step: what to gather and the best zones for your faction,
-- nearest first. Click a zone to open the map.
function UI:DrawGatheringStep(prof, skill, maxSkill, current, y)
    local f = self.frame
    local index = math.min(ns.state.viewIndex or current, #prof.steps)
    local step = prof.steps[index]

    local label = "STEP " .. index .. " OF " .. #prof.steps .. "   SKILL " .. step.from .. "-" .. step.to
    if index ~= current then label = label .. "   (browsing)" end
    Place(self.eyebrow, y); self.eyebrow:SetText(label)
    y = y - self.eyebrow:GetStringHeight() - GAP_ABOVE_RECIPE

    Place(self.recipe, y); self.recipe:SetText(step.recipe)
    y = y - self.recipe:GetStringHeight() - 8

    Place(self.meta, y)
    self.meta:SetText("Gather until skill " .. step.to .. ".")
    self.meta:SetTextColor(unpack(COLOR_MUTED))
    y = y - self.meta:GetStringHeight() - GAP_BELOW_RECIPE

    local lines = {}
    if step.note then table.insert(lines, "Tip: " .. step.note) end
    local rankTips, capped = ns.RankTips(prof, step, skill, maxSkill)
    for _, t in ipairs(rankTips) do table.insert(lines, t) end
    if capped and index == current then
        table.insert(lines, "|cffff7a6bYou've hit your skill cap. Train the next rank to keep levelling.|r")
    end
    if #lines > 0 then
        Place(self.note, y); self.note:SetText(table.concat(lines, "\n"))
        y = y - self.note:GetStringHeight() - 12
    end

    -- Zones for your faction, nearest first.
    local faction = UnitFactionGroup("player")
    local zones = {}
    for _, key in ipairs({ faction, "Both" }) do
        for _, z in ipairs((step.zones and step.zones[key]) or {}) do table.insert(zones, z) end
    end
    local entries = {}
    for _, z in ipairs(zones) do
        local info = ns.Finder and ns.Finder.ZoneInfo(z) or {}
        local dist = ns.Finder and ns.Finder.DistanceText(info) or ""
        table.insert(entries, {
            kind = "zone", icon = prof.icon, text = z, mapID = info.mapID,
            right = dist, order = info.dist or (info.far and 1e8) or 1e9,
        })
    end
    table.sort(entries, function(a, b) return a.order < b.order end)
    y = self:FillList("Best zones for you:", entries, y)

    self.prevBtn:Show(); self.nextBtn:Show(); self.currentBtn:Show()
    self.prevBtn:SetEnabled(index > 1)
    self.nextBtn:SetEnabled(index < #prof.steps)
    self.currentBtn:SetEnabled(index ~= current)
    return y
end

-- Puts the panel where you last left it (or the default spot).
function UI:RestorePosition()
    local f, pos = self.frame, ProfGuideForeverDB.pos
    f:ClearAllPoints()
    if pos then
        f:SetPoint(pos[1], UIParent, pos[2], pos[3], pos[4])
    else
        f:SetPoint("RIGHT", UIParent, "RIGHT", -120, 0)
    end
end

-- Show/hide. Pass true/false, or nothing to flip it.
function UI:Toggle(show)
    if not self.frame then self:Build() end
    if show == nil then show = not self.frame:IsShown() end
    self.frame:SetShown(show)
    ProfGuideForeverDB.shown = show
    if show then
        self:Refresh()
        if ns.Welcome then ns.Welcome.ShowIfFirstTime() end
    end
end
