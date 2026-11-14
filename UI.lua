-- ============================================================
-- UI.lua
-- The "component" layer: builds the panel and draws whatever
-- Core.lua works out. Layout uses a 14px outer padding and
-- 24px material rows.
-- ============================================================

local addonName, ns = ...

local UI = {}
ns.UI = UI

-- ---------- Design tokens ----------
local WIDTH   = 300
local PAD     = 14
local ROW_H   = 24
local INNER_W = WIDTH - PAD * 2
local BOX_PAD = 10                     -- padding inside the materials box
local ROW_W   = INNER_W - BOX_PAD * 2  -- row width inside the box

-- Vertical rhythm around the recipe block
local GAP_ABOVE_RECIPE = 12 -- eyebrow -> recipe name
local GAP_IN_RECIPE    = 4  -- recipe name -> "Make about..." (kept tight: one group)
local GAP_BELOW_RECIPE = 18 -- recipe block -> tip / materials box

local COLOR_OK    = { 0.40, 0.85, 0.45 } -- have enough
local COLOR_SHORT = { 1.00, 0.50, 0.45 } -- still need more
local COLOR_MUTED = { 0.62, 0.62, 0.62 }
local COLOR_BAR   = { 0.80, 0.52, 0.22 } -- leather brown-orange

local function Prof() return ns.Professions[ns.activeProfession] end

-- Puts a text element at a vertical position, full width,
-- so long text wraps instead of running off the panel.
local function Place(fs, y)
    fs:ClearAllPoints()
    fs:SetPoint("TOPLEFT", UI.frame, "TOPLEFT", PAD, y)
    fs:SetWidth(INNER_W)
    fs:Show()
end

local function NewText(parent, font, justify)
    local fs = parent:CreateFontString(nil, "OVERLAY", font)
    fs:SetJustifyH(justify or "LEFT")
    fs:SetWordWrap(true)
    return fs
end

-- ---------- Material rows ----------
-- Rows are made once and reused (a "pool"), like recycling
-- list cells in a mobile app.
function UI:GetRow(i)
    if self.rows[i] then return self.rows[i] end

    -- Rows live inside the materials box, so they draw on top of it.
    local r = CreateFrame("Frame", nil, self.box)
    r:SetSize(ROW_W, ROW_H)

    r.icon = r:CreateTexture(nil, "ARTWORK")
    r.icon:SetSize(18, 18)
    r.icon:SetPoint("LEFT")
    r.icon:SetTexCoord(0.08, 0.92, 0.08, 0.92) -- trims the icon's built-in border

    -- Tick icon, so "done" doesn't rely on colour alone.
    r.check = r:CreateTexture(nil, "OVERLAY")
    r.check:SetSize(14, 14)
    r.check:SetPoint("RIGHT")
    r.check:SetTexture("Interface\\RaidFrame\\ReadyCheck-Ready")

    r.count = NewText(r, "GameFontHighlight", "RIGHT")
    r.count:SetPoint("RIGHT", r.check, "LEFT", -6, 0)
    r.count:SetWordWrap(false)

    r.name = NewText(r, "GameFontHighlight", "LEFT")
    r.name:SetPoint("LEFT", r.icon, "RIGHT", 8, 0)
    r.name:SetWordWrap(false) -- width is set per row in FillBox, so the badge can hug the text

    -- "You make this" badge: a tiny leatherworking icon after the name.
    r.badge = r:CreateTexture(nil, "OVERLAY")
    r.badge:SetSize(12, 12)
    r.badge:SetPoint("LEFT", r.name, "RIGHT", 5, 0)
    r.badge:SetTexture("Interface\\Icons\\Trade_LeatherWorking")
    r.badge:SetTexCoord(0.08, 0.92, 0.08, 0.92)

    -- Hover anywhere on the row to see the item tooltip.
    -- (The whole row is the hover target: easier than a 12px icon.)
    r:EnableMouse(true)
    r:SetScript("OnEnter", function(row)
        GameTooltip:SetOwner(row, "ANCHOR_LEFT")
        GameTooltip:SetItemByID(row.itemID)
        if row.crafted then
            GameTooltip:AddLine(" ")
            GameTooltip:AddLine("You craft this in an earlier step.", 1, 0.82, 0)
        end
        GameTooltip:Show()
    end)
    r:SetScript("OnLeave", function() GameTooltip:Hide() end)

    self.rows[i] = r
    return r
end

-- Draws the materials box at position y: a small label, then one
-- row per { id, need, have }. Returns the y position under the box.
function UI:FillBox(label, list, y)
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

        local info = prof.items[m.id]
        local name = info and info.name or ("Item " .. m.id)
        local crafted = (info and info.crafted) or false

        local ok = m.have >= m.need
        r.itemID = m.id
        r.crafted = crafted
        r.icon:SetTexture(ns.ItemIcon(m.id))
        r.count:SetText(m.have .. " / " .. m.need)
        r.count:SetTextColor(unpack(ok and COLOR_OK or COLOR_SHORT))
        r.check:SetShown(ok)
        r.badge:SetShown(crafted)

        -- Size the name to its text, but never wider than the space
        -- left after the icon, count, tick and (if shown) badge.
        r.name:SetText(name)
        local maxW = ROW_W - 18 - 8 - r.count:GetStringWidth() - 8 - 14 - 6
        if crafted then maxW = maxW - 17 end
        local textW = r.name.GetUnboundedStringWidth and r.name:GetUnboundedStringWidth()
            or r.name:GetStringWidth()
        r.name:SetWidth(math.min(textW + 1, maxW))
        r:Show()
    end
    -- Hide leftover rows from a longer list.
    for i = #list + 1, #self.rows do self.rows[i]:Hide() end

    -- Box height = label + rows + padding (rows have built-in air,
    -- so the bottom padding is a little smaller than the top).
    local height = -rowsTop + #list * ROW_H + BOX_PAD - 4
    box:SetHeight(height)
    box:Show()
    return y - height
end

-- ---------- Building the panel (runs once) ----------
function UI:Build()
    if self.frame then return end
    self.rows = {}

    local f = CreateFrame("Frame", "ProfGuideFrame", UIParent, "BackdropTemplate")
    self.frame = f
    f:SetSize(WIDTH, 300)
    f:SetFrameStrata("MEDIUM")
    f:SetClampedToScreen(true)

    -- Flat dark panel with a thin warm border.
    f:SetBackdrop({
        bgFile = "Interface\\Buttons\\WHITE8x8",
        edgeFile = "Interface\\Buttons\\WHITE8x8",
        edgeSize = 1,
    })
    f:SetBackdropColor(0.06, 0.06, 0.07, 0.94)
    f:SetBackdropBorderColor(0.35, 0.27, 0.18, 1)

    -- Drag to move; remember where you left it.
    f:SetMovable(true)
    f:EnableMouse(true)
    f:RegisterForDrag("LeftButton")
    f:SetScript("OnDragStart", f.StartMoving)
    f:SetScript("OnDragStop", function(frame)
        frame:StopMovingOrSizing()
        local point, _, relPoint, x, y = frame:GetPoint()
        ProfGuideDB.pos = { point, relPoint, x, y }
    end)
    local pos = ProfGuideDB.pos
    if pos then
        f:SetPoint(pos[1], UIParent, pos[2], pos[3], pos[4])
    else
        f:SetPoint("RIGHT", UIParent, "RIGHT", -80, 0)
    end

    -- Esc closes the panel, like other game windows.
    tinsert(UISpecialFrames, "ProfGuideFrame")

    -- Header
    self.title = NewText(f, "GameFontNormalLarge")
    self.title:SetPoint("TOPLEFT", PAD, -PAD)

    local close = CreateFrame("Button", nil, f, "UIPanelCloseButton")
    close:SetPoint("TOPRIGHT", 2, 2)
    close:SetScript("OnClick", function() UI:Toggle(false) end)

    self.skillText = NewText(f, "GameFontHighlight", "RIGHT")
    self.skillText:SetPoint("TOPRIGHT", -34, -PAD - 2)

    -- Progress bar towards 300
    local bar = CreateFrame("StatusBar", nil, f)
    bar:SetPoint("TOPLEFT", PAD, -40)
    bar:SetPoint("TOPRIGHT", -PAD, -40)
    bar:SetHeight(6)
    bar:SetStatusBarTexture("Interface\\Buttons\\WHITE8x8")
    bar:SetStatusBarColor(unpack(COLOR_BAR))
    bar:SetMinMaxValues(0, 300)
    local barBg = bar:CreateTexture(nil, "BACKGROUND")
    barBg:SetAllPoints()
    barBg:SetColorTexture(1, 1, 1, 0.08)
    self.bar = bar

    -- Tabs: text with a gold underline on the active one
    local function MakeTab(label, key)
        local b = CreateFrame("Button", nil, f)
        b.text = NewText(b, "GameFontNormal")
        b.text:SetPoint("LEFT")
        b.text:SetText(label)
        b:SetSize(b.text:GetStringWidth() + 2, 20)
        b.line = b:CreateTexture(nil, "ARTWORK")
        b.line:SetColorTexture(1, 0.82, 0, 1)
        b.line:SetHeight(2)
        b.line:SetPoint("TOPLEFT", b.text, "BOTTOMLEFT", 0, -3)
        b.line:SetPoint("TOPRIGHT", b.text, "BOTTOMRIGHT", 0, -3)
        b:SetScript("OnClick", function()
            ns.state.tab = key
            UI:Refresh()
        end)
        return b
    end
    self.tabStep = MakeTab("This step", "step")
    self.tabStep:SetPoint("TOPLEFT", PAD, -56)
    self.tabShop = MakeTab("Shopping list", "shop")
    self.tabShop:SetPoint("LEFT", self.tabStep, "RIGHT", 20, 0)

    -- Content text
    self.eyebrow = NewText(f, "GameFontDisableSmall")
    self.recipe  = NewText(f, "GameFontHighlightLarge")
    self.meta    = NewText(f, "GameFontHighlightSmall")
    self.note    = NewText(f, "GameFontNormalSmall") -- gold, reads as a tip
    -- Materials box: faint fill + 1px border so it reads as its own card.
    local box = CreateFrame("Frame", nil, f, "BackdropTemplate")
    box:SetWidth(INNER_W)
    box:SetBackdrop({
        bgFile = "Interface\\Buttons\\WHITE8x8",
        edgeFile = "Interface\\Buttons\\WHITE8x8",
        edgeSize = 1,
    })
    box:SetBackdropColor(1, 1, 1, 0.04)
    box:SetBackdropBorderColor(1, 1, 1, 0.12)
    self.box = box

    self.boxLabel = NewText(box, "GameFontDisableSmall")
    self.boxLabel:SetPoint("TOPLEFT", BOX_PAD, -BOX_PAD)

    self.summary = NewText(f, "GameFontHighlightSmall")
    self.summary:SetPoint("BOTTOMLEFT", PAD, PAD)

    -- Footer buttons
    local function MakeButton(label, width, onClick)
        local b = CreateFrame("Button", nil, f, "UIPanelButtonTemplate")
        b:SetSize(width, 22)
        b:SetText(label)
        b:SetScript("OnClick", onClick)
        return b
    end
    local function Browse(delta)
        local prof = Prof()
        local skill = ns.GetSkill(prof)
        local index = (ns.state.viewIndex or ns.CurrentStepIndex(prof, skill)) + delta
        ns.state.viewIndex = math.max(1, math.min(#prof.steps, index))
        UI:Refresh()
    end
    self.prevBtn = MakeButton("< Prev", 78, function() Browse(-1) end)
    self.prevBtn:SetPoint("BOTTOMLEFT", PAD, PAD)
    self.nextBtn = MakeButton("Next >", 78, function() Browse(1) end)
    self.nextBtn:SetPoint("BOTTOMRIGHT", -PAD, PAD)
    self.currentBtn = MakeButton("My step", 90, function()
        ns.state.viewIndex = nil
        UI:Refresh()
    end)
    self.currentBtn:SetPoint("BOTTOM", 0, PAD)

    f:SetShown(ProfGuideDB.shown)
    self:Refresh()
end

-- ---------- Drawing (runs whenever something changes) ----------
-- Refresh runs Draw "safely": if anything breaks, the error is
-- printed in your chat window instead of failing silently.
local lastError
function UI:Refresh()
    if not self.frame then return end
    local ok, err = pcall(self.Draw, self)
    if not ok and err ~= lastError then
        lastError = err
        print("|cffff5555ProfGuide error:|r " .. tostring(err))
    end
end

function UI:Draw()
    local prof = Prof()
    local skill, maxSkill = ns.GetSkill(prof)
    local current = ns.CurrentStepIndex(prof, skill)

    -- Header
    self.title:SetText(prof.name)
    if skill then
        self.skillText:SetText(skill .. " / " .. maxSkill)
        self.bar:SetValue(skill)
    else
        self.skillText:SetText("Not learned")
        self.bar:SetValue(0)
    end

    -- Tab styling: active = white + underline, inactive = grey
    local onStep = (ns.state.tab == "step")
    self.tabStep.line:SetShown(onStep)
    self.tabShop.line:SetShown(not onStep)
    self.tabStep.text:SetTextColor(unpack(onStep and { 1, 1, 1 } or COLOR_MUTED))
    self.tabShop.text:SetTextColor(unpack(onStep and COLOR_MUTED or { 1, 1, 1 }))

    local y = -88 -- content starts under the tabs

    if onStep then
        local index = ns.state.viewIndex or current
        local step = prof.steps[index]
        local mats, crafts = ns.StepMaterials(prof, step, skill)

        local label = "STEP " .. index .. " OF " .. #prof.steps
            .. "   SKILL " .. step.from .. "-" .. step.to
        if index ~= current then label = label .. "   (browsing)" end

        Place(self.eyebrow, y); self.eyebrow:SetText(label)
        y = y - self.eyebrow:GetStringHeight() - GAP_ABOVE_RECIPE

        -- Recipe block: name + "Make about..." grouped tightly together
        Place(self.recipe, y); self.recipe:SetText(step.recipe)
        y = y - self.recipe:GetStringHeight() - GAP_IN_RECIPE

        Place(self.meta, y)
        self.meta:SetText("Make about " .. crafts .. ".  Learn from: " .. step.source)
        self.meta:SetTextColor(unpack(COLOR_MUTED))
        y = y - self.meta:GetStringHeight() - GAP_BELOW_RECIPE

        if step.note then
            Place(self.note, y); self.note:SetText("Tip: " .. step.note)
            y = y - self.note:GetStringHeight() - 12
        else
            self.note:Hide()
        end

        y = self:FillBox("MATERIALS", mats, y)

        self.prevBtn:Show(); self.nextBtn:Show(); self.currentBtn:Show()
        self.prevBtn:SetEnabled(index > 1)
        self.nextBtn:SetEnabled(index < #prof.steps)
        self.currentBtn:SetEnabled(index ~= current)
        self.summary:Hide()

        self.frame:SetHeight(-y + 14 + 22 + PAD)
    else
        local list = ns.ShoppingList(prof, skill)

        self.eyebrow:Hide(); self.recipe:Hide(); self.meta:Hide(); self.note:Hide()

        y = self:FillBox("EVERYTHING YOU NEED FROM HERE TO 300", list, y)

        local ready = 0
        for _, m in ipairs(list) do
            if m.have >= m.need then ready = ready + 1 end
        end
        self.summary:SetText(ready .. " of " .. #list .. " materials ready")
        self.summary:SetTextColor(unpack(COLOR_MUTED))
        self.summary:Show()
        self.prevBtn:Hide(); self.nextBtn:Hide(); self.currentBtn:Hide()

        self.frame:SetHeight(-y + 12 + 14 + PAD)
    end
end

-- Show/hide. Pass true/false, or nothing to flip it.
function UI:Toggle(show)
    if not self.frame then self:Build() end
    if show == nil then show = not self.frame:IsShown() end
    self.frame:SetShown(show)
    ProfGuideDB.shown = show
    if show then self:Refresh() end
end
