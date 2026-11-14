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

local function Prof() return ns.ActiveProf() end

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

    -- "You make this" badge: a tiny profession icon after the name.
    r.badge = r:CreateTexture(nil, "OVERLAY")
    r.badge:SetSize(12, 12)
    r.badge:SetPoint("LEFT", r.name, "RIGHT", 5, 0)
    r.badge:SetTexCoord(0.08, 0.92, 0.08, 0.92)

    -- Hover anywhere on the row to see the item tooltip.
    -- (The whole row is the hover target: easier than a 12px icon.)
    r:EnableMouse(true)
    r:SetScript("OnEnter", function(row)
        GameTooltip:SetOwner(row, "ANCHOR_LEFT")
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
        GameTooltip:Show()
    end)
    r:SetScript("OnLeave", function() GameTooltip:Hide() end)

    self.rows[i] = r
    return r
end

-- Draws the materials box at position y: a small label, then one
-- row per { name, need, have, crafted }. Returns the y under the box.
-- craftedText = tooltip line for things you make yourself.
function UI:FillBox(label, list, y, craftedText)
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

        local name, crafted = m.name, m.crafted

        local ok = m.have >= m.need
        r.itemName = name
        r.crafted = crafted
        r.craftedText = craftedText
        r.icon:SetTexture(ns.ItemIcon(name))
        r.badge:SetTexture(prof.icon)
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

    local f = CreateFrame("Frame", "ProfGuideForeverFrame", UIParent, "BackdropTemplate")
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
        ProfGuideForeverDB.pos = { point, relPoint, x, y }
    end)
    local pos = ProfGuideForeverDB.pos
    if pos then
        f:SetPoint(pos[1], UIParent, pos[2], pos[3], pos[4])
    else
        f:SetPoint("RIGHT", UIParent, "RIGHT", -80, 0)
    end

    -- Esc closes the panel, like other game windows.
    tinsert(UISpecialFrames, "ProfGuideForeverFrame")

    -- Header: profession picker. Icon + name + down arrow, as one button.
    local picker = CreateFrame("Button", nil, f)
    picker:SetPoint("TOPLEFT", PAD, -PAD + 3)
    picker:SetHeight(22)
    self.picker = picker

    self.profIcon = picker:CreateTexture(nil, "ARTWORK")
    self.profIcon:SetSize(18, 18)
    self.profIcon:SetPoint("LEFT")
    self.profIcon:SetTexCoord(0.08, 0.92, 0.08, 0.92)

    self.title = NewText(picker, "GameFontNormalLarge")
    self.title:SetPoint("LEFT", self.profIcon, "RIGHT", 6, 0)
    self.title:SetWordWrap(false)

    self.arrow = picker:CreateTexture(nil, "ARTWORK")
    self.arrow:SetSize(12, 12)
    self.arrow:SetPoint("LEFT", self.title, "RIGHT", 6, -1)
    self.arrow:SetTexture("Interface\\ChatFrame\\ChatFrameExpandArrow")
    self.arrow:SetRotation(-math.pi / 2) -- point it downwards

    -- Hover: name turns white, so it reads as clickable.
    picker:SetScript("OnEnter", function() self.title:SetTextColor(1, 1, 1) end)
    picker:SetScript("OnLeave", function() self.title:SetTextColor(1, 0.82, 0) end)
    picker:SetScript("OnClick", function() UI:ToggleMenu() end)

    self:BuildMenu()

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
            UI.menu:Hide()
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
    self.boxLabel:SetWidth(ROW_W) -- long labels wrap inside the box

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

    f:HookScript("OnHide", function() UI.menu:Hide() end)
    f:SetShown(ProfGuideForeverDB.shown)
    self:Refresh()
end

-- ---------- Profession menu ----------
-- A small dropdown: your professions first (with skill), then the rest.

local MENU_W, ITEM_H = 236, 22

function UI:BuildMenu()
    local m = CreateFrame("Frame", nil, self.frame, "BackdropTemplate")
    m:SetFrameStrata("DIALOG") -- draws above everything else
    m:SetWidth(MENU_W)
    m:SetPoint("TOPLEFT", self.picker, "BOTTOMLEFT", -6, -6)
    m:SetBackdrop({
        bgFile = "Interface\\Buttons\\WHITE8x8",
        edgeFile = "Interface\\Buttons\\WHITE8x8",
        edgeSize = 1,
    })
    m:SetBackdropColor(0.09, 0.09, 0.10, 0.98)
    m:SetBackdropBorderColor(0.35, 0.27, 0.18, 1)
    m:EnableMouse(true) -- clicks on the menu don't fall through to the panel
    m:Hide()
    self.menu = m
    self.menuItems, self.menuHeaders = {}, {}
end

local function MenuItem(self, i)
    if self.menuItems[i] then return self.menuItems[i] end
    local b = CreateFrame("Button", nil, self.menu)
    b:SetSize(MENU_W - 12, ITEM_H)
    b:SetHighlightTexture("Interface\\Buttons\\WHITE8x8")
    b:GetHighlightTexture():SetVertexColor(1, 1, 1, 0.08)
    b.icon = b:CreateTexture(nil, "ARTWORK")
    b.icon:SetSize(16, 16)
    b.icon:SetPoint("LEFT", 6, 0)
    b.icon:SetTexCoord(0.08, 0.92, 0.08, 0.92)
    b.label = NewText(b, "GameFontHighlight")
    b.label:SetPoint("LEFT", b.icon, "RIGHT", 8, 0)
    b.skill = NewText(b, "GameFontHighlightSmall", "RIGHT")
    b.skill:SetPoint("RIGHT", -6, 0)
    b.skill:SetTextColor(unpack(COLOR_MUTED))
    b:SetScript("OnClick", function(btn)
        ns.state.prof = btn.profName
        ns.state.viewIndex = nil
        ProfGuideForeverDB.lastProf = btn.profName
        UI.menu:Hide()
        UI:Refresh()
    end)
    self.menuItems[i] = b
    return b
end

local function MenuHeader(self, i)
    if self.menuHeaders[i] then return self.menuHeaders[i] end
    local fs = NewText(self.menu, "GameFontDisableSmall")
    self.menuHeaders[i] = fs
    return fs
end

function UI:ToggleMenu()
    if self.menu:IsShown() then self.menu:Hide(); return end

    -- Split into "yours" and "everything else".
    local learned = ns.LearnedProfessions()
    local isLearned = {}
    for _, p in ipairs(learned) do isLearned[p.name] = p end
    local others = {}
    for _, name in ipairs(ns.ProfessionOrder) do
        if not isLearned[name] then table.insert(others, { name = name }) end
    end

    local sections = {}
    if #learned > 0 then table.insert(sections, { "YOUR PROFESSIONS", learned }) end
    if #others > 0 then table.insert(sections, { #learned > 0 and "OTHER PROFESSIONS" or "PROFESSIONS", others }) end

    local y, itemCount = -8, 0
    for h, section in ipairs(sections) do
        local header = MenuHeader(self, h)
        header:ClearAllPoints()
        header:SetPoint("TOPLEFT", 12, y)
        header:SetText(section[1])
        header:Show()
        y = y - header:GetStringHeight() - 4

        for _, p in ipairs(section[2]) do
            itemCount = itemCount + 1
            local b = MenuItem(self, itemCount)
            b:ClearAllPoints()
            b:SetPoint("TOPLEFT", 6, y)
            b.profName = p.name
            b.icon:SetTexture(ns.Professions[p.name].icon)
            b.label:SetText(p.name)
            -- Current profession in gold, others white.
            if p.name == Prof().name then b.label:SetTextColor(1, 0.82, 0) else b.label:SetTextColor(1, 1, 1) end
            b.skill:SetText(p.rank and (p.rank .. " / " .. p.max) or "")
            b:Show()
            y = y - ITEM_H
        end
        y = y - 8 -- gap between sections
    end
    for i = itemCount + 1, #self.menuItems do self.menuItems[i]:Hide() end
    for i = #sections + 1, #self.menuHeaders do self.menuHeaders[i]:Hide() end

    self.menu:SetHeight(-y)
    self.menu:Show()
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
        print("|cffff5555ProfGuide Forever error:|r " .. tostring(err))
    end
end

function UI:Draw()
    local prof = Prof()
    local skill, maxSkill = ns.GetSkill(prof)
    local current = ns.CurrentStepIndex(prof, skill)

    -- Header: icon + name; size the picker to fit so the arrow hugs the text
    self.profIcon:SetTexture(prof.icon)
    self.title:SetText(prof.name)
    self.picker:SetWidth(18 + 6 + self.title:GetStringWidth() + 6 + 12)
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
        local mats, crafts, verified = ns.StepMaterials(prof, step, skill)

        local label = "STEP " .. index .. " OF " .. #prof.steps
            .. "   SKILL " .. step.from .. "-" .. step.to
        if index ~= current then label = label .. "   (browsing)" end

        Place(self.eyebrow, y); self.eyebrow:SetText(label)
        y = y - self.eyebrow:GetStringHeight() - GAP_ABOVE_RECIPE

        -- Recipe block: name + "Make about..." grouped tightly together
        Place(self.recipe, y); self.recipe:SetText(step.recipe)
        y = y - self.recipe:GetStringHeight() - GAP_IN_RECIPE

        Place(self.meta, y)
        local meta = "Make about " .. crafts .. ".  Learn from: " .. step.source
        if verified then meta = meta .. "\n|cff66d977Materials checked in game|r" end
        self.meta:SetText(meta)
        self.meta:SetTextColor(unpack(COLOR_MUTED))
        y = y - self.meta:GetStringHeight() - GAP_BELOW_RECIPE

        -- Tips: the step's own note, rank training reminders, and a
        -- warning if you've hit your skill cap.
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
        else
            self.note:Hide()
        end

        y = self:FillBox("MATERIALS", mats, y, "You craft this in an earlier step.")

        self.prevBtn:Show(); self.nextBtn:Show(); self.currentBtn:Show()
        self.prevBtn:SetEnabled(index > 1)
        self.nextBtn:SetEnabled(index < #prof.steps)
        self.currentBtn:SetEnabled(index ~= current)
        self.summary:Hide()

        self.frame:SetHeight(-y + 14 + 22 + PAD)
    else
        local list = ns.ShoppingList(prof, skill)

        self.eyebrow:Hide(); self.recipe:Hide(); self.meta:Hide(); self.note:Hide()

        local label = (#list > 0) and "EVERYTHING TO GATHER OR BUY FROM HERE TO 300" or "NOTHING LEFT TO GET. NICE WORK!"
        -- Long lists get cut to the biggest items so the panel stays a sensible height.
        local MAX_ROWS = 15
        local shown = list
        if #list > MAX_ROWS then
            shown = {}
            for k = 1, MAX_ROWS do shown[k] = list[k] end
        end
        y = self:FillBox(label, shown, y)

        local ready = 0
        for _, m in ipairs(list) do
            if m.have >= m.need then ready = ready + 1 end
        end
        local summary = ready .. " of " .. #list .. " materials ready"
        if #list > #shown then summary = summary .. "  (showing the biggest " .. #shown .. ")" end
        self.summary:SetText(summary)
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
    ProfGuideForeverDB.shown = show
    if show then self:Refresh() end
end
