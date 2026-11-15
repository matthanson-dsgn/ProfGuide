-- ============================================================
-- Toast.lua
-- "Step complete!" pop-up: slides in near the top of the screen
-- with a sound when your skill finishes a step, then fades out.
-- Click it to open the guide.
-- ============================================================

local addonName, ns = ...

local Toast = {}
ns.Toast = Toast

local SHOW_FOR = 4 -- seconds before it fades
local lastStep = {} -- profession -> step index we last saw (this session)

local function Build()
    local t = CreateFrame("Button", "ProfGuideForeverToast", UIParent, "BackdropTemplate")
    t:SetSize(300, 58)
    t:SetPoint("TOP", 0, -140)
    t:SetFrameStrata("DIALOG")
    t:SetBackdrop({
        bgFile = "Interface\\Tooltips\\UI-Tooltip-Background",
        edgeFile = "Interface\\Tooltips\\UI-Tooltip-Border", edgeSize = 16,
        insets = { left = 4, right = 4, top = 4, bottom = 4 },
    })
    t:SetBackdropColor(0.05, 0.05, 0.05, 0.92)
    t:SetBackdropBorderColor(1, 0.82, 0, 1) -- gold edge

    t.icon = t:CreateTexture(nil, "ARTWORK")
    t.icon:SetSize(36, 36)
    t.icon:SetPoint("LEFT", 12, 0)
    t.icon:SetTexCoord(0.08, 0.92, 0.08, 0.92)
    t.slot = t:CreateTexture(nil, "OVERLAY")
    t.slot:SetSize(62, 62)
    t.slot:SetPoint("CENTER", t.icon, "CENTER")
    t.slot:SetTexture("Interface\\Buttons\\UI-Quickslot2")

    t.title = t:CreateFontString(nil, "OVERLAY", "GameFontNormal")
    t.title:SetPoint("TOPLEFT", t.icon, "TOPRIGHT", 12, -1)
    t.title:SetPoint("RIGHT", -12, 0)
    t.title:SetJustifyH("LEFT")

    t.text = t:CreateFontString(nil, "OVERLAY", "GameFontHighlight")
    t.text:SetPoint("BOTTOMLEFT", t.icon, "BOTTOMRIGHT", 12, 2)
    t.text:SetPoint("RIGHT", -12, 0)
    t.text:SetJustifyH("LEFT")
    t.text:SetWordWrap(false)

    -- Fade in, wait, fade out.
    local anim = t:CreateAnimationGroup()
    local fadeIn = anim:CreateAnimation("Alpha")
    fadeIn:SetFromAlpha(0); fadeIn:SetToAlpha(1); fadeIn:SetDuration(0.3); fadeIn:SetOrder(1)
    local fadeOut = anim:CreateAnimation("Alpha")
    fadeOut:SetFromAlpha(1); fadeOut:SetToAlpha(0); fadeOut:SetDuration(0.8)
    fadeOut:SetStartDelay(SHOW_FOR); fadeOut:SetOrder(2)
    anim:SetScript("OnFinished", function() t:Hide() end)
    t.anim = anim

    t:SetScript("OnClick", function()
        t:Hide()
        if ns.UI then ns.UI:Toggle(true) end
    end)
    t:SetScript("OnEnter", function() anim:Pause() end)   -- stays while you read it
    t:SetScript("OnLeave", function() anim:Play() end)
    t:Hide()
    Toast.frame = t
end

-- Shows the pop-up. title in gold, text below it.
function Toast.Show(icon, title, text)
    if not ProfGuideForeverDB.toast then return end
    if not Toast.frame then Build() end
    local t = Toast.frame
    t.icon:SetTexture(icon)
    t.title:SetText(title)
    t.text:SetText(text)
    t:SetAlpha(0)
    t:Show()
    t.anim:Stop()
    t.anim:Play()
    if ProfGuideForeverDB.toastSound and PlaySound and SOUNDKIT then
        pcall(PlaySound, SOUNDKIT.IG_QUEST_LIST_COMPLETE or SOUNDKIT.READY_CHECK)
    end
end

-- Called when your skill may have changed: compares each profession's
-- current step with the one we saw last, and celebrates moving on.
function Toast.CheckProgress()
    for _, p in ipairs(ns.LearnedProfessions()) do
        local def = ns.Professions[p.name]
        local view = def.views[ns.RouteKey(def)]
        local index = ns.CurrentStepIndex(view, p.rank)
        local maxed = p.rank >= 300
        local before = lastStep[p.name]
        if before and (index > before or (maxed and not lastStep[p.name .. ":maxed"])) then
            if maxed then
                Toast.Show(def.icon, p.name .. " complete!", "You've reached 300. Nice work!")
            else
                Toast.Show(def.icon, "Step complete!", "Next: " .. view.steps[index].recipe)
            end
        end
        lastStep[p.name] = index
        if maxed then lastStep[p.name .. ":maxed"] = true end
    end
end
