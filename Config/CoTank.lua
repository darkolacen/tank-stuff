-- Co-Tank config panel for Tank Stuff
local L = TankStuff_L or setmetatable({}, { __index = function(_, k) return k end })

local settingsCategory = nil

SLASH_TANKSTUFF1 = "/tankstuff"
SlashCmdList["TANKSTUFF"] = function(msg)
    msg = msg and msg:lower():gsub("^%s+", ""):gsub("%s+$", "")
    if msg == "cotank" or msg == "co-tank" or msg == "" then
        if TankStuff.IsElvUIPlugin and _G.ElvUI and _G.ElvUI[1] then
            local E = _G.ElvUI[1]
            if E.ToggleOptions then
                E:ToggleOptions("TankStuff")
            else
                print("|cff00aaffTank Stuff|r: Open ElvUI Config -> Plugins -> Tank Stuff.")
            end
            return
        end
        local ok, panel = pcall(function()
            return GetPanel and GetPanel() or nil
        end)
        if ok and panel then
            if settingsCategory and Settings and Settings.OpenToCategory then
                Settings.OpenToCategory(settingsCategory:GetID())
            elseif InterfaceOptionsFrame_OpenToCategory then
                InterfaceOptionsFrame_OpenToCategory(panel)
            else
                print("|cff00aaffTank Stuff|r: Open game Settings (Esc) -> AddOns -> Tank Stuff -> Co-Tank Frame.")
            end
        else
            print("|cff00aaffTank Stuff|r: Open Interface -> AddOns -> Tank Stuff -> Co-Tank Frame, or enable the addon and /reload.")
        end
    end
end

local function GetDB()
    return TankStuff and TankStuff.GetCoTankDB() or nil
end

local function RefreshDisplay()
    if TankStuff and TankStuff.CoTankDisplay then
        TankStuff.CoTankDisplay:Refresh()
    end
end

local nameFormatOptions = {
    { text = L["COTANK_NAME_FULL"], value = "full" },
    { text = L["COTANK_NAME_ABBREV"], value = "abbreviated" },
}

local function CreateCoTankPanel()
    local db = GetDB()
    if not db then return end

    local panel = CreateFrame("Frame", "TankStuff_CoTankOptions", UIParent, "BackdropTemplate")
    panel.name = L["SIDEBAR_TAB_COTANK"]
    panel:SetBackdrop({ bgFile = [[Interface\DialogFrame\UI-DialogBox-Background]] })
    panel:SetBackdropColor(0.08, 0.08, 0.12, 0.95)

    local scroll = CreateFrame("ScrollFrame", nil, panel, "UIPanelScrollFrameTemplate")
    scroll:SetPoint("TOPLEFT", 16, -32)
    scroll:SetPoint("BOTTOMRIGHT", -34, 16)

    local child = CreateFrame("Frame", nil, scroll)
    child:SetWidth(math.max(scroll:GetWidth() - 20, 400))
    child:SetHeight(1)
    scroll:SetScrollChild(child)

    local y = -10
    local lineH = 32
    local PAD_LEFT = 18
    local PAD_SECTION = 16
    local function nextY() y = y - lineH; return y end

    local function createSectionBox(parent, topY, bottomY)
        local box = CreateFrame("Frame", nil, parent, "BackdropTemplate")
        box:SetFrameLevel(parent:GetFrameLevel() - 1)
        box:SetPoint("TOPLEFT", parent, "TOPLEFT", 0, topY)
        box:SetPoint("BOTTOMRIGHT", parent, "TOPRIGHT", 0, bottomY)
        box:SetBackdrop({
            bgFile = [[Interface\Buttons\WHITE8x8]],
            edgeFile = [[Interface\Buttons\WHITE8x8]],
            edgeSize = 1,
            insets = { left = PAD_SECTION, right = PAD_SECTION, top = PAD_SECTION, bottom = PAD_SECTION },
        })
        box:SetBackdropColor(0.08, 0.08, 0.12, 0.85)
        box:SetBackdropBorderColor(0.35, 0.35, 0.4, 0.9)
        return box
    end

    local function setSliderLabels(slider, lowText, highText)
        local name = slider:GetName()
        if name then
            if _G[name .. "Low"] then _G[name .. "Low"]:SetText(lowText) end
            if _G[name .. "High"] then _G[name .. "High"]:SetText(highText) end
        end
    end

    local function makeCheckbox(parent, yOffset, dbKey, labelText, onChange)
        local cb = CreateFrame("CheckButton", nil, parent)
        cb:SetSize(26, 26)
        cb:SetPoint("TOPLEFT", PAD_LEFT, yOffset)
        local nt = cb:CreateTexture(nil, "ARTWORK")
        nt:SetAllPoints()
        nt:SetTexture("Interface\\Buttons\\UI-CheckBox-Up")
        local pt = cb:CreateTexture(nil, "ARTWORK")
        pt:SetAllPoints()
        pt:SetTexture("Interface\\Buttons\\UI-CheckBox-Down")
        pt:SetBlendMode("ADD")
        local ct = cb:CreateTexture(nil, "ARTWORK")
        ct:SetAllPoints()
        ct:SetTexture("Interface\\Buttons\\UI-CheckBox-Check")
        ct:SetBlendMode("ADD")
        cb:SetNormalTexture(nt)
        cb:SetPushedTexture(pt)
        cb:SetCheckedTexture(ct)
        cb:SetChecked((dbKey == "unlock" and TankStuff and TankStuff.previewEnabled) or (dbKey ~= "unlock" and db[dbKey]))
        cb:SetScript("OnClick", function(self)
            if dbKey == "unlock" and TankStuff then
                TankStuff.previewEnabled = self:GetChecked()
            else
                db[dbKey] = self:GetChecked()
            end
            if onChange then onChange() else RefreshDisplay() end
        end)
        local lbl = parent:CreateFontString(nil, "OVERLAY", "GameFontHighlight")
        lbl:SetPoint("LEFT", cb, "RIGHT", 6, 0)
        lbl:SetText(labelText)
        return cb
    end

    local title = child:CreateFontString(nil, "OVERLAY", "GameFontNormalLarge")
    title:SetPoint("TOPLEFT", PAD_LEFT, -10)
    title:SetText(L["COTANK_TITLE"])
    y = y - 40

    local subtitle = child:CreateFontString(nil, "OVERLAY", "GameFontHighlightSmall")
    subtitle:SetPoint("TOPLEFT", PAD_LEFT, y)
    subtitle:SetWidth(400)
    subtitle:SetWordWrap(true)
    subtitle:SetNonSpaceWrap(false)
    subtitle:SetText(L["COTANK_SUBTITLE"])
    y = y - 36

    local masterTop = y
    makeCheckbox(child, nextY(), "enabled", L["COTANK_ENABLE"])
    makeCheckbox(child, nextY(), "unlock", L["COTANK_PREVIEW"])

    local anchorLabel = child:CreateFontString(nil, "OVERLAY", "GameFontHighlight")
    anchorLabel:SetPoint("TOPLEFT", PAD_LEFT, nextY())
    anchorLabel:SetText(L["COTANK_ANCHOR_TO"] or "Anchor to")
    local anchorPresets = {
        { label = L["COTANK_ANCHOR_SCREEN"] or "Screen", value = "UIParent" },
        { label = L["COTANK_ANCHOR_PLAYER"] or "Player", value = "PlayerFrame" },
        { label = L["COTANK_ANCHOR_TARGET"] or "Target", value = "TargetFrame" },
        { label = L["COTANK_ANCHOR_FOCUS"] or "Focus", value = "FocusFrame" },
        { label = "ElvUI P", value = "ElvUF_Player" },
        { label = "ElvUI T", value = "ElvUF_Target" },
        { label = "ElvUI F", value = "ElvUF_Focus" },
        { label = "Custom", value = "Custom" },
    }
    local anchorButtons = {}
    local BUTTON_W = 58
    local GAP = 2
    for i, opt in ipairs(anchorPresets) do
        local btn = CreateFrame("Button", nil, child, "UIPanelButtonTemplate")
        btn:SetSize(BUTTON_W, 22)
        local row, col = (i <= 4) and 0 or 1, ((i - 1) % 4)
        btn:SetPoint("LEFT", anchorLabel, "RIGHT", col * (BUTTON_W + GAP) + 8, row * -24)
        btn:SetText(opt.label)
        btn.anchorValue = opt.value
        anchorButtons[i] = btn
        btn:SetScript("OnClick", function()
            db.anchorFrame = opt.value
            if TankStuff and TankStuff.CoTankDisplay then TankStuff.CoTankDisplay.posInitialized = nil end
            RefreshDisplay()
            for _, b in ipairs(anchorButtons) do b:SetEnabled(b.anchorValue ~= opt.value) end
            if anchorEdit then anchorEdit:SetShown(opt.value == "Custom") end
        end)
    end
    local customRowY = y - lineH * 2
    local customLabel = child:CreateFontString(nil, "OVERLAY", "GameFontHighlight")
    customLabel:SetPoint("TOPLEFT", PAD_LEFT, customRowY)
    customLabel:SetText("Custom frame name")
    local anchorEdit = CreateFrame("EditBox", nil, child, "InputBoxTemplate")
    anchorEdit:SetPoint("LEFT", customLabel, "RIGHT", 8, 0)
    anchorEdit:SetSize(180, 20)
    anchorEdit:SetAutoFocus(false)
    anchorEdit:SetText(db.anchorFrameCustom or "UIParent")
    anchorEdit:SetScript("OnEnterPressed", function(self)
        self:ClearFocus()
        local text = (self:GetText() or ""):gsub("^%s+", ""):gsub("%s+$", "")
        db.anchorFrameCustom = (text == "" and "UIParent") or text
        self:SetText(db.anchorFrameCustom)
        if TankStuff and TankStuff.CoTankDisplay then TankStuff.CoTankDisplay.posInitialized = nil end
        RefreshDisplay()
    end)
    anchorEdit:SetScript("OnEscapePressed", function(self)
        self:SetText(db.anchorFrameCustom or "UIParent")
        self:ClearFocus()
    end)
    anchorEdit:SetScript("OnEditFocusLost", function(self)
        local text = (self:GetText() or ""):gsub("^%s+", ""):gsub("%s+$", "")
        db.anchorFrameCustom = (text == "" and "UIParent") or text
        self:SetText(db.anchorFrameCustom)
        if TankStuff and TankStuff.CoTankDisplay then TankStuff.CoTankDisplay.posInitialized = nil end
        RefreshDisplay()
    end)
    anchorEdit:SetShown(db.anchorFrame == "Custom")
    for _, b in ipairs(anchorButtons) do
        b:SetEnabled(b.anchorValue ~= (db.anchorFrame or "UIParent"))
    end
    nextY()
    if db.anchorFrame == "Custom" then nextY() end

    nextY()
    createSectionBox(child, masterTop, y - 12)
    nextY()

    local healthTop = y
    local healthHeader = child:CreateFontString(nil, "OVERLAY", "GameFontNormal")
    healthHeader:SetPoint("TOPLEFT", PAD_LEFT, nextY())
    healthHeader:SetText(L["COTANK_SECTION_HEALTH"])
    nextY()

    makeCheckbox(child, nextY(), "useClassColor", L["COTANK_USE_CLASS_COLOR"])

    local healthColorBtn = CreateFrame("Button", nil, child, "UIPanelButtonTemplate")
    healthColorBtn:SetSize(100, 22)
    healthColorBtn:SetPoint("TOPRIGHT", child, "TOPRIGHT", -PAD_LEFT, y)
    healthColorBtn:SetText(L["COTANK_HEALTH_COLOR"])
    healthColorBtn:SetScript("OnClick", function()
        ColorPickerFrame:SetColorRGB(db.healthColorR or 0, db.healthColorG or 0.8, db.healthColorB or 0.2)
        ColorPickerFrame.previousValues = { db.healthColorR, db.healthColorG, db.healthColorB }
        ColorPickerFrame.func = function(_, r, g, b)
            db.healthColorR, db.healthColorG, db.healthColorB = r, g, b
            RefreshDisplay()
        end
        ColorPickerFrame:Show()
    end)
    nextY()

    local widthLabel = child:CreateFontString(nil, "OVERLAY", "GameFontHighlight")
    widthLabel:SetPoint("TOPLEFT", PAD_LEFT, nextY())
    widthLabel:SetText(L["COTANK_WIDTH"] .. ": " .. (db.width or 150))
    local widthSlider = CreateFrame("Slider", "TankStuff_CoTankWidth", child, "OptionsSliderTemplate")
    widthSlider:SetPoint("TOPLEFT", PAD_LEFT, y - 20)
    widthSlider:SetMinMaxValues(50, 300)
    widthSlider:SetValueStep(1)
    widthSlider:SetValue(db.width or 150)
    widthSlider:SetScript("OnValueChanged", function(self, val)
        db.width = math.floor(val)
        widthLabel:SetText(L["COTANK_WIDTH"] .. ": " .. db.width)
        RefreshDisplay()
    end)
    setSliderLabels(widthSlider, "50", "300")
    nextY()
    nextY()

    local heightLabel = child:CreateFontString(nil, "OVERLAY", "GameFontHighlight")
    heightLabel:SetPoint("TOPLEFT", PAD_LEFT, nextY())
    heightLabel:SetText(L["COTANK_HEIGHT"] .. ": " .. (db.height or 20))
    local heightSlider = CreateFrame("Slider", "TankStuff_CoTankHeight", child, "OptionsSliderTemplate")
    heightSlider:SetPoint("TOPLEFT", PAD_LEFT, y - 20)
    heightSlider:SetMinMaxValues(10, 60)
    heightSlider:SetValueStep(1)
    heightSlider:SetValue(db.height or 20)
    heightSlider:SetScript("OnValueChanged", function(self, val)
        db.height = math.floor(val)
        heightLabel:SetText(L["COTANK_HEIGHT"] .. ": " .. db.height)
        RefreshDisplay()
    end)
    setSliderLabels(heightSlider, "10", "60")
    nextY()
    nextY()

    local bgLabel = child:CreateFontString(nil, "OVERLAY", "GameFontHighlight")
    bgLabel:SetPoint("TOPLEFT", PAD_LEFT, nextY())
    bgLabel:SetText(L["COTANK_BG_OPACITY"] .. ": " .. math.floor((db.bgAlpha or 0.6) * 100) .. "%")
    local bgSlider = CreateFrame("Slider", "TankStuff_CoTankBG", child, "OptionsSliderTemplate")
    bgSlider:SetPoint("TOPLEFT", PAD_LEFT, y - 20)
    bgSlider:SetMinMaxValues(0, 100)
    bgSlider:SetValueStep(5)
    bgSlider:SetValue((db.bgAlpha or 0.6) * 100)
    bgSlider:SetScript("OnValueChanged", function(self, val)
        db.bgAlpha = val / 100
        bgLabel:SetText(L["COTANK_BG_OPACITY"] .. ": " .. math.floor(val) .. "%")
        RefreshDisplay()
    end)
    setSliderLabels(bgSlider, "0%", "100%")
    nextY()
    nextY()
    createSectionBox(child, healthTop, y - 12)
    nextY()

    local nameTop = y
    local nameHeader = child:CreateFontString(nil, "OVERLAY", "GameFontNormal")
    nameHeader:SetPoint("TOPLEFT", PAD_LEFT, nextY())
    nameHeader:SetText(L["COTANK_SECTION_NAME"])
    nextY()

    makeCheckbox(child, nextY(), "showName", L["COTANK_SHOW_NAME"])

    local nameFormatLabel = child:CreateFontString(nil, "OVERLAY", "GameFontHighlight")
    nameFormatLabel:SetPoint("TOPLEFT", PAD_LEFT, nextY())
    nameFormatLabel:SetText(L["COTANK_NAME_FORMAT"])
    local nameFormatAbbrev = CreateFrame("Button", nil, child, "UIPanelButtonTemplate")
    nameFormatAbbrev:SetSize(100, 22)
    nameFormatAbbrev:SetPoint("TOPRIGHT", child, "TOPRIGHT", -PAD_LEFT, y)
    nameFormatAbbrev:SetText(L["COTANK_NAME_ABBREV"])
    nameFormatAbbrev:SetScript("OnClick", function()
        db.nameFormat = "abbreviated"
        RefreshDisplay()
    end)
    local nameFormatFull = CreateFrame("Button", nil, child, "UIPanelButtonTemplate")
    nameFormatFull:SetSize(100, 22)
    nameFormatFull:SetPoint("TOPRIGHT", nameFormatAbbrev, "TOPLEFT", -8, 0)
    nameFormatFull:SetText(L["COTANK_NAME_FULL"])
    nameFormatFull:SetScript("OnClick", function()
        db.nameFormat = "full"
        RefreshDisplay()
    end)
    nextY()

    local nameLengthLabel = child:CreateFontString(nil, "OVERLAY", "GameFontHighlight")
    nameLengthLabel:SetPoint("TOPLEFT", PAD_LEFT, nextY())
    nameLengthLabel:SetText(L["COTANK_NAME_LENGTH"] .. ": " .. (db.nameLength or 6))
    local nameLengthSlider = CreateFrame("Slider", "TankStuff_CoTankNameLen", child, "OptionsSliderTemplate")
    nameLengthSlider:SetPoint("TOPLEFT", PAD_LEFT, y - 20)
    nameLengthSlider:SetMinMaxValues(3, 12)
    nameLengthSlider:SetValueStep(1)
    nameLengthSlider:SetValue(db.nameLength or 6)
    nameLengthSlider:SetScript("OnValueChanged", function(self, val)
        db.nameLength = math.floor(val)
        nameLengthLabel:SetText(L["COTANK_NAME_LENGTH"] .. ": " .. db.nameLength)
        RefreshDisplay()
    end)
    setSliderLabels(nameLengthSlider, "3", "12")
    nextY()
    nextY()

    local nameFontSizeLabel = child:CreateFontString(nil, "OVERLAY", "GameFontHighlight")
    nameFontSizeLabel:SetPoint("TOPLEFT", PAD_LEFT, nextY())
    nameFontSizeLabel:SetText(L["COTANK_NAME_FONT_SIZE"] .. ": " .. (db.nameFontSize or 12))
    local nameFontSizeSlider = CreateFrame("Slider", "TankStuff_CoTankFontSize", child, "OptionsSliderTemplate")
    nameFontSizeSlider:SetPoint("TOPLEFT", PAD_LEFT, y - 20)
    nameFontSizeSlider:SetMinMaxValues(8, 24)
    nameFontSizeSlider:SetValueStep(1)
    nameFontSizeSlider:SetValue(db.nameFontSize or 12)
    nameFontSizeSlider:SetScript("OnValueChanged", function(self, val)
        db.nameFontSize = math.floor(val)
        nameFontSizeLabel:SetText(L["COTANK_NAME_FONT_SIZE"] .. ": " .. db.nameFontSize)
        RefreshDisplay()
    end)
    setSliderLabels(nameFontSizeSlider, "8", "24")
    nextY()
    nextY()

    local nameColorBtn = CreateFrame("Button", nil, child, "UIPanelButtonTemplate")
    nameColorBtn:SetSize(100, 22)
    nameColorBtn:SetPoint("TOPRIGHT", child, "TOPRIGHT", -PAD_LEFT, y)
    nameColorBtn:SetText(L["COTANK_NAME_COLOR"])
    nameColorBtn:SetScript("OnClick", function()
        ColorPickerFrame:SetColorRGB(db.nameColorR or 1, db.nameColorG or 1, db.nameColorB or 1)
        ColorPickerFrame.previousValues = { db.nameColorR, db.nameColorG, db.nameColorB }
        ColorPickerFrame.func = function(_, r, g, b)
            db.nameColorR, db.nameColorG, db.nameColorB = r, g, b
            RefreshDisplay()
        end
        ColorPickerFrame:Show()
    end)
    nextY()

    createSectionBox(child, nameTop, y - 12)
    nextY()

    local restoreBtn = CreateFrame("Button", nil, child, "UIPanelButtonTemplate")
    restoreBtn:SetSize(120, 24)
    restoreBtn:SetPoint("TOPLEFT", PAD_LEFT, nextY() - 10)
    restoreBtn:SetText("Restore defaults")
    restoreBtn:SetScript("OnClick", function()
        local defaults = TankStuff and TankStuff.CO_TANK_DEFAULTS
        if defaults then
            for k, v in pairs(defaults) do
                db[k] = v
            end
            RefreshDisplay()
        end
    end)

    child:SetHeight(-y + 40)
    return panel
end

local panel = nil
local function GetPanel()
    if not panel then
        panel = CreateCoTankPanel()
    end
    return panel
end

C_Timer.After(0, function()
    if TankStuff.IsElvUIPlugin then return end
    local ok, err = pcall(function()
        local panel = GetPanel()
        if InterfaceOptions_AddCategory then
            InterfaceOptions_AddCategory(panel)
        elseif Settings and Settings.RegisterCanvasLayoutCategory and Settings.RegisterAddOnCategory then
            local category, layout = Settings.RegisterCanvasLayoutCategory(panel, panel.name or "Tank Stuff")
            Settings.RegisterAddOnCategory(category)
            settingsCategory = category
        else
            error("No options API available (InterfaceOptions_AddCategory or Settings.*)")
        end
    end)
    if not ok then
        print("|cff00aaffTank Stuff|r: Could not add options category: " .. tostring(err))
    end
end)
