-- ============================================================
-- Minimap.lua
-- The round button on the minimap edge. Click to show/hide the
-- panel; drag to slide it around the minimap. Uses the same
-- sizes as other add-ons' minimap buttons so it sits in line.
-- ============================================================

local addonName, ns = ...

local Btn = {}
ns.Minimap = Btn

local ICON = "Interface\\AddOns\\ProfGuide\\Media\\MinimapIcon"

-- Places the button on the minimap's edge at the saved angle
-- (0 = right, 90 = top, 180 = left, 270 = bottom).
local function UpdatePosition(button)
    local angle = math.rad(ProfGuideDB.minimap.angle)
    local radius = (Minimap:GetWidth() / 2) + 5
    button:ClearAllPoints()
    button:SetPoint("CENTER", Minimap, "CENTER", math.cos(angle) * radius, math.sin(angle) * radius)
end

function Btn:Build()
    if self.button or not Minimap then return end
    ProfGuideDB.minimap = ProfGuideDB.minimap or { angle = 225, hide = false } -- 225 = bottom-left

    local b = CreateFrame("Button", "ProfGuideMinimapButton", Minimap)
    b:SetSize(31, 31)
    b:SetFrameStrata("MEDIUM")
    b:SetFrameLevel(8)
    b:RegisterForClicks("AnyUp")
    b:RegisterForDrag("LeftButton")
    b:SetHighlightTexture("Interface\\Minimap\\UI-Minimap-ZoomButton-Highlight")

    -- Layers, bottom to top: dark disc, your artwork, gold ring.
    local bg = b:CreateTexture(nil, "BACKGROUND")
    bg:SetSize(20, 20)
    bg:SetPoint("TOPLEFT", 7, -5)
    bg:SetTexture("Interface\\Minimap\\UI-Minimap-Background")

    local icon = b:CreateTexture(nil, "ARTWORK")
    icon:SetSize(18, 18)
    icon:SetPoint("TOPLEFT", 7, -6)
    icon:SetTexture(ICON)
    b.icon = icon

    local border = b:CreateTexture(nil, "OVERLAY")
    border:SetSize(53, 53)
    border:SetPoint("TOPLEFT")
    border:SetTexture("Interface\\Minimap\\MiniMap-TrackingBorder")

    -- Pressed state: nudge the icon 1px, like a real button.
    b:SetScript("OnMouseDown", function() icon:SetPoint("TOPLEFT", 8, -7) end)
    b:SetScript("OnMouseUp", function() icon:SetPoint("TOPLEFT", 7, -6) end)

    b:SetScript("OnClick", function()
        if ns.UI then ns.UI:Toggle() end
    end)

    b:SetScript("OnEnter", function(self)
        GameTooltip:SetOwner(self, "ANCHOR_LEFT")
        GameTooltip:AddLine("ProfGuide", 1, 0.82, 0)
        GameTooltip:AddLine("Click to show or hide the guide.", 1, 1, 1)
        GameTooltip:AddLine("Drag to move this button.", 0.62, 0.62, 0.62)
        GameTooltip:Show()
    end)
    b:SetScript("OnLeave", function() GameTooltip:Hide() end)

    -- Dragging: while held, follow the cursor's angle around the minimap.
    b:SetScript("OnDragStart", function(self)
        GameTooltip:Hide()
        self:SetScript("OnUpdate", function(button)
            local mx, my = Minimap:GetCenter()
            local cx, cy = GetCursorPosition()
            local scale = Minimap:GetEffectiveScale()
            cx, cy = cx / scale, cy / scale
            ProfGuideDB.minimap.angle = math.deg(math.atan2(cy - my, cx - mx))
            UpdatePosition(button)
        end)
    end)
    b:SetScript("OnDragStop", function(self) self:SetScript("OnUpdate", nil) end)

    self.button = b
    UpdatePosition(b)
    b:SetShown(not ProfGuideDB.minimap.hide)
end

-- /pg minimap: hide or show the button.
function Btn:Toggle()
    if not self.button then return end
    ProfGuideDB.minimap.hide = not ProfGuideDB.minimap.hide
    self.button:SetShown(not ProfGuideDB.minimap.hide)
    print("|cffffd100ProfGuide:|r minimap button " .. (ProfGuideDB.minimap.hide and "hidden. Type /pg minimap to bring it back." or "shown."))
end

-- Clicking ProfGuide in the minimap's add-on menu (newer clients
-- have one; the .toc file points here). Global so the game can find it.
function ProfGuide_OnAddonCompartmentClick()
    if ns.UI then ns.UI:Toggle() end
end
