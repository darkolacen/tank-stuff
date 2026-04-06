-- Co-Tank display for TankStuff
local L = TankStuff_L or setmetatable({}, { __index = function(_, k) return k end })

local FRAME_BACKDROP = {
    bgFile = "Interface\\Tooltips\\UI-Tooltip-Background",
    edgeFile = "Interface\\Tooltips\\UI-Tooltip-Border",
    tile = true, tileSize = 16, edgeSize = 16,
    insets = { left = 4, right = 4, top = 4, bottom = 4 },
}

local function GetDB()
    return TankStuff and TankStuff.GetCoTankDB() or nil
end

local function GetE()
    if _G.ElvUI and type(_G.ElvUI) == "table" then
        return _G.ElvUI[1] or select(1, unpack(_G.ElvUI))
    end
    return nil
end

local healthBar, healthBg

local function GetUF()
    local E = GetE()
    if E and E.GetModule then
        return E:GetModule("UnitFrames", true)
    end
    return nil
end

local function ColorToRGB(color)
    if not color then return nil end
    if type(color.GetRGB) == "function" then
        return color:GetRGB()
    end
    if color.r and color.g and color.b then
        return color.r, color.g, color.b
    end
    return nil
end

local function GetFallbackHealthColor(unit, db)
    if db.useClassColor then
        local _, class = UnitClass(unit)
        if class then
            local color = RAID_CLASS_COLORS[class]
            if color then
                return color.r, color.g, color.b
            end
        end
    end

    return db.healthColorR or 0, db.healthColorG or 0.8, db.healthColorB or 0.2
end

local function GetElvUIHealthColor(unit)
    local E = GetE()
    local colors = E and E.db and E.db.unitframe and E.db.unitframe.colors
    local ElvUF = _G.ElvUF
    if not colors then return nil end

    local isPlayer = UnitIsPlayer(unit) or (UnitInPartyIsAI and UnitInPartyIsAI(unit))

    if colors.healthselection and type(UnitSelectionType) == "function" and ElvUF and ElvUF.colors and ElvUF.colors.selection then
        local selectionType = UnitSelectionType(unit, false)
        local r, g, b = ColorToRGB(ElvUF.colors.selection[selectionType])
        if r then
            return r, g, b
        end
    end

    if colors.healthclass then
        if isPlayer and not colors.forcehealthreaction then
            local _, class = UnitClass(unit)
            local classColor = class and RAID_CLASS_COLORS[class]
            if classColor then
                return classColor.r, classColor.g, classColor.b
            end
        end

        local reaction = UnitReaction(unit, "player")
        local reactionColor = reaction and ElvUF and ElvUF.colors and ElvUF.colors.reaction and ElvUF.colors.reaction[reaction]
        local r, g, b = ColorToRGB(reactionColor or (reaction and FACTION_BAR_COLORS and FACTION_BAR_COLORS[reaction]))
        if r then
            return r, g, b
        end
    end

    return ColorToRGB(colors.health)
end

local function GetHealthBarColor(unit, db)
    local r, g, b = GetElvUIHealthColor(unit)
    if r then
        return r, g, b
    end
    return GetFallbackHealthColor(unit, db)
end

local function GetElvUIBackdropMultiplier()
    local E = GetE()
    local unitframeDB = E and E.db and E.db.unitframe
    local colors = unitframeDB and unitframeDB.colors
    if not colors then return nil end

    return (colors.healthMultiplier and colors.healthMultiplier > 0 and colors.healthMultiplier)
        or unitframeDB.multiplier
        or 0.35
end

local function GetElvUIHealthBackdropColor(unit, healthR, healthG, healthB)
    local E = GetE()
    local unitframeDB = E and E.db and E.db.unitframe
    local colors = unitframeDB and unitframeDB.colors
    local ElvUF = _G.ElvUF
    if not colors then return nil end

    if colors.useDeadBackdrop and UnitIsDeadOrGhost(unit) then
        return ColorToRGB(colors.health_backdrop_dead)
    end

    if colors.customhealthbackdrop then
        return ColorToRGB(colors.health_backdrop)
    end

    if colors.classbackdrop then
        if UnitIsPlayer(unit) or (E.Retail and UnitInPartyIsAI and UnitInPartyIsAI(unit)) then
            local _, class = UnitClass(unit)
            local classColor = class and ((ElvUF and ElvUF.colors and ElvUF.colors.class and ElvUF.colors.class[class]) or RAID_CLASS_COLORS[class])
            local r, g, b = ColorToRGB(classColor)
            if r then
                return r, g, b
            end
        end

        local reaction = UnitReaction(unit, "player")
        local reactionColor = reaction and ElvUF and ElvUF.colors and ElvUF.colors.reaction and ElvUF.colors.reaction[reaction]
        local r, g, b = ColorToRGB(reactionColor or (reaction and FACTION_BAR_COLORS and FACTION_BAR_COLORS[reaction]))
        if r then
            return r, g, b
        end
    end

    local mult = GetElvUIBackdropMultiplier()
    if mult then
        return (healthR or 0) * mult, (healthG or 0) * mult, (healthB or 0) * mult
    end

    return nil
end

local function GetHealthBackdropColor(unit, db, healthR, healthG, healthB)
    local r, g, b = GetElvUIHealthBackdropColor(unit, healthR, healthG, healthB)
    if r then
        return r, g, b
    end

    local mult = 0.35
    return (healthR or 0) * mult, (healthG or 0.8) * mult, (healthB or 0.2) * mult
end

local function ApplyBarColors(healthR, healthG, healthB, bgR, bgG, bgB, db)
    local E = GetE()
    local colors = E and E.db and E.db.unitframe and E.db.unitframe.colors
    local UF = GetUF()

    if colors and UF and UF.SetStatusBarColor and healthBar and healthBar.bg then
        if healthBar.CreateBackdrop and not healthBar.backdrop then
            healthBar:CreateBackdrop(nil, nil, nil, nil, true)
        end
        if UF.ToggleTransparentStatusBar and healthBar._tankStuffTransparent ~= colors.transparentHealth then
            UF:ToggleTransparentStatusBar(colors.transparentHealth, healthBar, healthBar.bg, true, colors.invertHealth, false)
            healthBar._tankStuffTransparent = colors.transparentHealth
        end
        healthBar.isTransparent = colors.transparentHealth
        UF:SetStatusBarColor(healthBar, healthR, healthG, healthB, {
            r = bgR,
            g = bgG,
            b = bgB,
            a = 1,
        }, false)
    else
        healthBar:SetStatusBarColor(healthR, healthG, healthB)
        healthBar:GetStatusBarTexture():SetVertexColor(healthR, healthG, healthB, 1)
        healthBg:SetVertexColor(bgR, bgG, bgB, 1)
    end
end

local function GetNameColor(unit, db)
    if db.nameColorUseClassColor ~= false then
        local _, class = UnitClass(unit)
        local classColor = class and RAID_CLASS_COLORS[class]
        if classColor then
            return classColor.r, classColor.g, classColor.b
        end
    end

    return db.nameColorR or 1, db.nameColorG or 1, db.nameColorB or 1
end

local function IsPreviewEnabled()
    return TankStuff and TankStuff.previewEnabled
end

local DEFAULT_FONT = "Fonts\\FRIZQT__.TTF"

local function ResolveFont(nameOrPath)
    if not nameOrPath or nameOrPath == "" then
        if _G.ElvUI and type(_G.ElvUI) == "table" then
            local E = _G.ElvUI[1] or select(1, unpack(_G.ElvUI))
            if E and E.media and E.media.normFont then
                return E.media.normFont
            end
        end
        return DEFAULT_FONT
    end
    if nameOrPath:find("\\") or nameOrPath:find("/") then
        return nameOrPath
    end
    if _G.ElvUI and type(_G.ElvUI) == "table" then
        local E = _G.ElvUI[1] or select(1, unpack(_G.ElvUI))
        if E and E.media and E.media.normFont then
            return E.media.normFont
        end
    end
    return DEFAULT_FONT
end

local function SetFrameUnlocked(frame, unlocked, label, isPreviewOnly)
    if unlocked then
        -- Preview mode: show frame exactly as it will look in raid (no overlay, no label)
        if isPreviewOnly then
            if frame.unlockLabel then
                frame.unlockLabel:Hide()
            end
            frame:SetBackdrop(nil)
        else
            frame:SetBackdrop(FRAME_BACKDROP)
            frame:SetBackdropColor(0, 0, 0, 0.5)
            frame:SetBackdropBorderColor(1, 0.66, 0, 0.8)
            if label and not frame.unlockLabel then
                frame.unlockLabel = frame:CreateFontString(nil, "OVERLAY")
                frame.unlockLabel:SetFont(ResolveFont(nil), 10, "OUTLINE")
                frame.unlockLabel:SetPoint("CENTER")
                frame.unlockLabel:SetTextColor(1, 0.66, 0)
            end
            if frame.unlockLabel then
                frame.unlockLabel:SetText(label or L["COMMON_DRAG_TO_MOVE"])
                frame.unlockLabel:Show()
            end
        end
        -- Keep preview frame on top so it's visible
        if not InCombatLockdown() then
            frame:SetFrameStrata("DIALOG")
            frame:SetFrameLevel(500)
        end
    else
        frame:SetBackdrop(nil)
        if frame.unlockLabel then
            frame.unlockLabel:Hide()
        end
        if not InCombatLockdown() then
            frame:SetFrameStrata("MEDIUM")
            frame:SetFrameLevel(1)
        end
    end
end

local function MakeDraggable(frame, db)
    frame:SetMovable(true)
    frame:EnableMouse(true)
    frame:RegisterForDrag("LeftButton")
    frame:SetClampedToScreen(true)
    frame:SetUserPlaced(true)
    frame:SetScript("OnDragStart", function(self)
        if IsPreviewEnabled() then
            self.isDragging = true
            self:StartMoving()
        end
    end)
    frame:SetScript("OnDragStop", function(self)
        self.isDragging = nil
        self:StopMovingOrSizing()
        local point, _, relativePoint, x, y = self:GetPoint()
        if point and x and y then
            db.point = point
            db.relativePoint = relativePoint or point
            db.x = math.floor(x)
            db.y = math.floor(y)
        end
    end)
end

local currentOtherTank = nil
local isPlayerTank = false

local frame = CreateFrame("Button", "TankStuff_CoTankFrame", UIParent, "BackdropTemplate")
frame:SetSize(150, 20)
frame:SetPoint("CENTER", UIParent, "CENTER", 200, 0)
frame:RegisterForClicks("AnyUp")
frame:Hide()

local borderFrame = CreateFrame("Frame", nil, frame, "BackdropTemplate")
borderFrame:SetPoint("TOPLEFT", -1, 1)
borderFrame:SetPoint("BOTTOMRIGHT", 1, -1)
borderFrame:SetBackdrop({
    edgeFile = [[Interface\Buttons\WHITE8X8]],
    edgeSize = 1,
})
borderFrame:SetBackdropBorderColor(0, 0, 0, 1)

healthBar = CreateFrame("StatusBar", nil, frame)
healthBar:SetAllPoints()
healthBar:SetStatusBarTexture("Interface\\Buttons\\WHITE8X8")
healthBar:SetStatusBarColor(0, 0.8, 0.2)
healthBar:SetMinMaxValues(0, 100)
healthBar:SetValue(100)

healthBg = healthBar:CreateTexture(nil, "BORDER")
healthBg:SetAllPoints()
healthBg:SetTexture("Interface\\Buttons\\WHITE8X8")
healthBg:SetVertexColor(0.1, 0.1, 0.1, 0.8)
healthBar.bg = healthBg

local nameText = healthBar:CreateFontString(nil, "OVERLAY")
nameText:SetFont(ResolveFont(nil), 12, "OUTLINE")
nameText:SetPoint("CENTER", healthBar, "CENTER", 0, 0)

local function ApplyPosition()
    local db = GetDB()
    if not db or InCombatLockdown() then return end
    local E = GetE()
    local anchorName = (db.anchorFrame == "Custom" and (db.anchorFrameCustom or "UIParent")) or (db.anchorFrame or "UIParent")
    local anchorFrame = _G[anchorName]
    local useAnchor = anchorName ~= "UIParent" and anchorFrame

    -- User chose a specific anchor (e.g. ElvUI Player): position relative to it; never let mover control the frame
    if anchorName ~= "UIParent" then
        -- Hide ElvUI mover so only our frame is visible (mover would otherwise show at its saved position, e.g. bottom-left)
        if E and E.CreatedMovers and E.CreatedMovers["TankStuff_CoTankMover"] then
            local mover = E.CreatedMovers["TankStuff_CoTankMover"].mover
            if mover and mover:IsShown() then mover:Hide() end
        end
        if useAnchor then
            frame:ClearAllPoints()
            local relPoint = db.relativePoint or db.point or "CENTER"
            frame:SetPoint(db.point or "CENTER", anchorFrame, relPoint, db.x or 200, db.y or 0)
            -- Re-apply once next frame to win over any ElvUI layout that ran same frame
            if not frame._anchorReapplyScheduled then
                frame._anchorReapplyScheduled = true
                C_Timer.After(0, function()
                    frame._anchorReapplyScheduled = nil
                    ApplyPosition()
                end)
            end
        else
            -- Anchor frame not created yet (e.g. ElvUF_Player): do NOT attach to mover; use UIParent with saved position until anchor exists
            frame:ClearAllPoints()
            local relPoint = db.relativePoint or db.point or "CENTER"
            frame:SetPoint(db.point or "CENTER", UIParent, relPoint, db.x or 200, db.y or 0)
        end
        return
    end
    -- No custom anchor: use ElvUI mover if present
    if E and E.CreatedMovers and E.CreatedMovers["TankStuff_CoTankMover"] then
        E:SetMoverPoints("TankStuff_CoTankMover", frame)
        return
    end
    frame:ClearAllPoints()
    local relPoint = db.relativePoint or db.point or "CENTER"
    frame:SetPoint(db.point or "CENTER", anchorFrame or UIParent, relPoint, db.x or 200, db.y or 0)
end

local function FindOtherTank()
    if not IsInRaid() then return nil end
    local numMembers = GetNumGroupMembers()
    for i = 1, numMembers do
        local unit = "raid" .. i
        if UnitExists(unit) and not UnitIsUnit(unit, "player") then
            local role = UnitGroupRolesAssigned(unit)
            if role == "TANK" then
                return unit
            end
        end
    end
    return nil
end

local function IsPlayerTankSpec()
    if PlayerUtil and PlayerUtil.IsPlayerEffectivelyTank then
        return PlayerUtil.IsPlayerEffectivelyTank()
    end
    return UnitGroupRolesAssigned("player") == "TANK"
end

local function ShouldBeVisible()
    local db = GetDB()
    if not db or not db.enabled then return false end
    if IsPreviewEnabled() then return true end
    if not IsInRaid() then return false end
    if not IsPlayerTankSpec() then return false end
    return FindOtherTank() ~= nil
end

local function UpdateHealth()
    if not currentOtherTank or not UnitExists(currentOtherTank) then
        healthBar:SetValue(0)
        nameText:Hide()
        return
    end

    local db = GetDB()
    healthBar:SetMinMaxValues(0, UnitHealthMax(currentOtherTank))
    healthBar:SetValue(UnitHealth(currentOtherTank))
    local healthR, healthG, healthB = GetHealthBarColor(currentOtherTank, db)
    local bgR, bgG, bgB = GetHealthBackdropColor(currentOtherTank, db, healthR, healthG, healthB)
    ApplyBarColors(healthR, healthG, healthB, bgR, bgG, bgB, db)

    if db.showName then
        local name = UnitName(currentOtherTank)
        if name then
            if db.nameFormat == "abbreviated" and db.nameLength then
                name = string.sub(name, 1, db.nameLength)
            end
            nameText:SetText(name)
            nameText:SetFont(ResolveFont(db.font), db.nameFontSize or 12, "OUTLINE")
            nameText:SetTextColor(GetNameColor(currentOtherTank, db))
            nameText:Show()
        else
            nameText:Hide()
        end
    else
        nameText:Hide()
    end
end

local function UpdateDisplay()
    local db = GetDB()
    if not db then
        if not InCombatLockdown() then frame:Hide() end
        return
    end

    if not InCombatLockdown() then
        frame:EnableMouse(true)
    end
    SetFrameUnlocked(frame, IsPreviewEnabled(), L["SIDEBAR_TAB_COTANK"], IsPreviewEnabled())

    -- Always apply size from db so preview matches real frame (allow in combat when preview so it looks right)
    if not InCombatLockdown() or IsPreviewEnabled() then
        frame:SetSize(db.width or 150, db.height or 20)
    end

    ApplyPosition()

    healthBg:SetAlpha(1)

    if ShouldBeVisible() then
        currentOtherTank = FindOtherTank()

        frame:SetScript("OnClick", function(_, button)
            if button == "LeftButton" and currentOtherTank and UnitExists(currentOtherTank) and not InCombatLockdown() then
                TargetUnit(currentOtherTank)
            end
        end)

        if IsPreviewEnabled() and not currentOtherTank then
            -- Preview: apply same visuals as real frame so it looks identical
            healthBar:SetFrameLevel(frame:GetFrameLevel() + 2)
            healthBar:SetMinMaxValues(0, 100)
            healthBar:SetValue(75)
            local healthR, healthG, healthB = GetHealthBarColor("player", db)
            local bgR, bgG, bgB = GetHealthBackdropColor("player", db, healthR, healthG, healthB)
            ApplyBarColors(healthR, healthG, healthB, bgR, bgG, bgB, db)
            if db.showName then
                local previewName = L["COTANK_PREVIEW_NAME"] or "TankName"
                if db.nameFormat == "abbreviated" and db.nameLength then
                    previewName = string.sub(previewName, 1, db.nameLength)
                end
                nameText:SetText(previewName)
                nameText:SetFont(ResolveFont(db.font), db.nameFontSize or 12, "OUTLINE")
                nameText:SetTextColor(GetNameColor("player", db))
                nameText:Show()
            else
                nameText:Hide()
            end
            healthBar:Show()
        else
            UpdateHealth()
        end

        frame:Show()

        -- Force a second refresh next frame so status bar and text get a proper layout/paint (fixes black rectangle on first preview)
        if IsPreviewEnabled() and not currentOtherTank then
            C_Timer.After(0, function()
                local d = GetDB()
                if d and d.enabled and IsPreviewEnabled() and ShouldBeVisible() then
                    UpdateDisplay()
                end
            end)
        end
    else
        currentOtherTank = nil
        frame:SetScript("OnClick", nil)
        frame:Hide()
    end

    -- When ElvUI is loaded: hide mover from Movers list when frame is disabled, show when enabled
    local E = GetE()
    if E then
        local inCreated = E.CreatedMovers and E.CreatedMovers["TankStuff_CoTankMover"]
        local inDisabled = E.DisabledMovers and E.DisabledMovers["TankStuff_CoTankMover"]
        if inCreated or inDisabled then
            if db.enabled and inDisabled then
                pcall(function() E:EnableMover("TankStuff_CoTankMover") end)
            elseif not db.enabled and inCreated then
                pcall(function() E:DisableMover("TankStuff_CoTankMover") end)
            end
        end
    end
end

function frame:Refresh()
    UpdateDisplay()
end

TankStuff.CoTankDisplay = frame

local eventFrame = CreateFrame("Frame")
eventFrame:RegisterEvent("PLAYER_LOGIN")
eventFrame:RegisterEvent("ADDON_LOADED")
eventFrame:RegisterEvent("GROUP_ROSTER_UPDATE")
eventFrame:RegisterEvent("PLAYER_ROLES_ASSIGNED")
eventFrame:RegisterEvent("ROLE_CHANGED_INFORM")
eventFrame:RegisterEvent("PLAYER_SPECIALIZATION_CHANGED")
eventFrame:RegisterEvent("PLAYER_ENTERING_WORLD")
eventFrame:RegisterEvent("PLAYER_REGEN_ENABLED")

eventFrame:SetScript("OnEvent", function(self, event, addonName)
    if event == "ADDON_LOADED" then
        if addonName ~= "TankStuff" then return end
        -- Run display update after a short delay so saved vars and other addons are ready
        C_Timer.After(0.5, function()
            UpdateDisplay()
        end)
        return
    end

    if event == "PLAYER_LOGIN" then
        local db = GetDB()
        if not db then return end

        -- Only use custom drag when ElvUI is not present; with ElvUI we use movers
        if not GetE() then
            MakeDraggable(frame, db)
        end
        isPlayerTank = IsPlayerTankSpec()
        ApplyPosition()
        -- Register with ElvUI movers so user can position via ElvUI Config → Movers
        local E = GetE()
        if E and E.CreateMover and not (E.CreatedMovers and E.CreatedMovers["TankStuff_CoTankMover"]) then
            E:CreateMover(frame, "TankStuff_CoTankMover", "Co-Tank Frame", nil, nil, nil, nil, nil, "TankStuff", nil)
        end
        -- When user has "Anchor to" set to a frame (e.g. ElvUI Player), re-apply our position after ElvUI's SetMoversPositions so we stay on the anchor
        if E and E.SetMoversPositions and not frame._hookSetMoversPositions then
            frame._hookSetMoversPositions = true
            hooksecurefunc(E, "SetMoversPositions", function()
                local d = GetDB()
                if not d or InCombatLockdown() then return end
                local an = (d.anchorFrame == "Custom" and (d.anchorFrameCustom or "UIParent")) or (d.anchorFrame or "UIParent")
                if an ~= "UIParent" and _G[an] then
                    C_Timer.After(0, ApplyPosition)
                end
            end)
        end
        UpdateDisplay()
        return
    end

    if event == "GROUP_ROSTER_UPDATE" or event == "PLAYER_ROLES_ASSIGNED"
        or event == "ROLE_CHANGED_INFORM" or event == "PLAYER_ENTERING_WORLD" then
        isPlayerTank = IsPlayerTankSpec()
        currentOtherTank = FindOtherTank()
        UpdateDisplay()
        return
    end

    if event == "PLAYER_SPECIALIZATION_CHANGED" then
        isPlayerTank = IsPlayerTankSpec()
        UpdateDisplay()
        return
    end

    if event == "PLAYER_REGEN_ENABLED" then
        currentOtherTank = FindOtherTank()
        UpdateDisplay()
        return
    end
end)

local updateElapsed = 0
local UPDATE_INTERVAL = 0.1
local anchorElapsed = 0
local ANCHOR_UPDATE_INTERVAL = 0.05

frame:SetScript("OnUpdate", function(self, elapsed)
    updateElapsed = updateElapsed + elapsed
    if updateElapsed >= UPDATE_INTERVAL then
        updateElapsed = 0
        -- Skip UpdateHealth in preview mode so we don't keep hiding the name every 0.1s (causes flickering)
        local db = GetDB()
        if not (db and db.enabled and IsPreviewEnabled() and not FindOtherTank()) then
            UpdateHealth()
        end
    end
    if not self.isDragging then
        anchorElapsed = anchorElapsed + elapsed
        if anchorElapsed >= ANCHOR_UPDATE_INTERVAL then
            anchorElapsed = 0
            ApplyPosition()
        end
    end
end)
