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

local function ResolveFont(nameOrPath)
    if not nameOrPath then nameOrPath = "GothamNarrowUltra" end
    local LSM = LibStub and LibStub("LibSharedMedia-3.0", true)
    if LSM and not nameOrPath:find("\\") and not nameOrPath:find("/") then
        local path = LSM:Fetch("font", nameOrPath)
        if path then return path end
    end
    return nameOrPath
end

local function SetFrameUnlocked(frame, unlocked, label)
    if unlocked then
        frame:SetBackdrop(FRAME_BACKDROP)
        frame:SetBackdropColor(0, 0, 0, 0.5)
        frame:SetBackdropBorderColor(1, 0.66, 0, 0.8)
        if label and not frame.unlockLabel then
            frame.unlockLabel = frame:CreateFontString(nil, "OVERLAY")
            frame.unlockLabel:SetFont(ResolveFont("GothamNarrowUltra"), 10, "OUTLINE")
            frame.unlockLabel:SetPoint("CENTER")
            frame.unlockLabel:SetTextColor(1, 0.66, 0)
        end
        if frame.unlockLabel then
            frame.unlockLabel:SetText(label or L["COMMON_DRAG_TO_MOVE"])
            frame.unlockLabel:Show()
        end
    else
        frame:SetBackdrop(nil)
        if frame.unlockLabel then
            frame.unlockLabel:Hide()
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
        if db.unlock then
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

local frame = CreateFrame("Button", "TankStuff_CoTankFrame", UIParent, "SecureUnitButtonTemplate, BackdropTemplate")
frame:SetSize(150, 20)
frame:SetPoint("CENTER", UIParent, "CENTER", 200, 0)
frame:RegisterForClicks("AnyUp")
frame:SetAttribute("type1", "target")
frame:Hide()

local borderFrame = CreateFrame("Frame", nil, frame, "BackdropTemplate")
borderFrame:SetPoint("TOPLEFT", -1, 1)
borderFrame:SetPoint("BOTTOMRIGHT", 1, -1)
borderFrame:SetBackdrop({
    edgeFile = [[Interface\Buttons\WHITE8X8]],
    edgeSize = 1,
})
borderFrame:SetBackdropBorderColor(0, 0, 0, 1)

local healthBg = frame:CreateTexture(nil, "BACKGROUND")
healthBg:SetAllPoints()
healthBg:SetColorTexture(0.1, 0.1, 0.1, 0.8)

local healthBar = CreateFrame("StatusBar", nil, frame)
healthBar:SetAllPoints()
healthBar:SetStatusBarTexture("Interface\\Buttons\\WHITE8X8")
healthBar:SetStatusBarColor(0, 0.8, 0.2)
healthBar:SetMinMaxValues(0, 100)
healthBar:SetValue(100)

local nameText = healthBar:CreateFontString(nil, "OVERLAY")
nameText:SetFont(ResolveFont("GothamNarrowUltra"), 12, "OUTLINE")
nameText:SetPoint("CENTER", healthBar, "CENTER", 0, 0)

local function ApplyPosition()
    local db = GetDB()
    if not db or InCombatLockdown() then return end
    frame:ClearAllPoints()
    local anchorName = (db.anchorFrame == "Custom" and (db.anchorFrameCustom or "UIParent")) or (db.anchorFrame or "UIParent")
    local anchorFrame = _G[anchorName] or UIParent
    local relPoint = db.relativePoint or db.point or "CENTER"
    frame:SetPoint(db.point or "CENTER", anchorFrame, relPoint, db.x or 200, db.y or 0)
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
    if db.unlock then return true end
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

    if db.useClassColor then
        local _, class = UnitClass(currentOtherTank)
        if class then
            local color = RAID_CLASS_COLORS[class]
            if color then
                healthBar:SetStatusBarColor(color.r, color.g, color.b)
            end
        end
    else
        healthBar:SetStatusBarColor(db.healthColorR or 0, db.healthColorG or 0.8, db.healthColorB or 0.2)
    end

    if db.showName then
        local name = UnitName(currentOtherTank)
        if name then
            if db.nameFormat == "abbreviated" and db.nameLength then
                name = string.sub(name, 1, db.nameLength)
            end
            nameText:SetText(name)
            nameText:SetFont(ResolveFont(db.font), db.nameFontSize or 12, "OUTLINE")
            if db.nameColorUseClassColor then
                local _, class = UnitClass(currentOtherTank)
                if class then
                    local color = RAID_CLASS_COLORS[class]
                    if color then
                        nameText:SetTextColor(color.r, color.g, color.b)
                    end
                end
            else
                nameText:SetTextColor(db.nameColorR or 1, db.nameColorG or 1, db.nameColorB or 1)
            end
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
    SetFrameUnlocked(frame, db.unlock, L["SIDEBAR_TAB_COTANK"])

    if not InCombatLockdown() then
        frame:SetSize(db.width or 150, db.height or 20)
    end

    ApplyPosition()

    healthBg:SetAlpha(db.bgAlpha or 0.6)

    if ShouldBeVisible() then
        currentOtherTank = FindOtherTank()

        if not InCombatLockdown() then
            frame:SetAttribute("unit", currentOtherTank)
        end

        if db.unlock and not currentOtherTank then
            healthBar:SetValue(75)
            healthBar:SetMinMaxValues(0, 100)
            healthBar:SetStatusBarColor(0, 0.8, 0.2)
            if db.showName then
                local previewName = L["COTANK_PREVIEW_NAME"] or "TankName"
                if db.nameFormat == "abbreviated" and db.nameLength then
                    previewName = string.sub(previewName, 1, db.nameLength)
                end
                nameText:SetText(previewName)
                nameText:SetFont(ResolveFont(db.font), db.nameFontSize or 12, "OUTLINE")
                nameText:SetTextColor(db.nameColorR or 1, db.nameColorG or 1, db.nameColorB or 1)
                nameText:Show()
            else
                nameText:Hide()
            end
        else
            UpdateHealth()
        end

        if not InCombatLockdown() then frame:Show() end
    else
        if not InCombatLockdown() then
            frame:SetAttribute("unit", nil)
        end
        if not InCombatLockdown() then frame:Hide() end
    end
end

function frame:Refresh()
    UpdateDisplay()
end

TankStuff.CoTankDisplay = frame

local eventFrame = CreateFrame("Frame")
eventFrame:RegisterEvent("PLAYER_LOGIN")
eventFrame:RegisterEvent("GROUP_ROSTER_UPDATE")
eventFrame:RegisterEvent("PLAYER_ROLES_ASSIGNED")
eventFrame:RegisterEvent("ROLE_CHANGED_INFORM")
eventFrame:RegisterEvent("PLAYER_SPECIALIZATION_CHANGED")
eventFrame:RegisterEvent("PLAYER_ENTERING_WORLD")
eventFrame:RegisterEvent("PLAYER_REGEN_ENABLED")

eventFrame:SetScript("OnEvent", function(self, event)
    if event == "PLAYER_LOGIN" then
        local db = GetDB()
        if not db then return end

        MakeDraggable(frame, db)
        isPlayerTank = IsPlayerTankSpec()
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
        frame:SetAttribute("unit", currentOtherTank)
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
        UpdateHealth()
    end
    if not self.isDragging then
        anchorElapsed = anchorElapsed + elapsed
        if anchorElapsed >= ANCHOR_UPDATE_INTERVAL then
            anchorElapsed = 0
            ApplyPosition()
        end
    end
end)
