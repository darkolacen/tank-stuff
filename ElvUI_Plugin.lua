--[[
  ElvUI companion: register as an ElvUI plugin so Tank Stuff appears in the Plugins tab
  (like ElvUI Anchor) and add options from the plugin callback.
]]

local addonName = "TankStuff"

local function GetDB()
    return TankStuff and TankStuff.GetCoTankDB() or nil
end

local function RefreshDisplay()
    if TankStuff and TankStuff.CoTankDisplay then
        TankStuff.CoTankDisplay:Refresh()
    end
end

local function BuildOptionsArgs()
    local L = TankStuff_L or setmetatable({}, { __index = function(_, k) return k end })
    if not GetDB() then return nil end

    return {
        coTank = {
            order = 1,
            type = "group",
            name = L["SIDEBAR_TAB_COTANK"] or "Co-Tank Frame",
            args = {
                enabled = {
                    order = 1,
                    type = "toggle",
                    name = L["COTANK_ENABLE"] or "Enable Co-Tank Frame",
                    get = function() return GetDB() and GetDB().enabled end,
                    set = function(_, v) local d = GetDB(); if d then d.enabled = v; RefreshDisplay() end end,
                },
                unlock = {
                    order = 2,
                    type = "toggle",
                    name = L["COTANK_PREVIEW"] or "Preview",
                    desc = L["COTANK_PREVIEW_DESC"] or "Show the frame with sample content so you can see how it looks.",
                    get = function() return TankStuff and TankStuff.previewEnabled end,
                    set = function(_, v) if TankStuff then TankStuff.previewEnabled = v; RefreshDisplay() end end,
                },
                spacer1 = { order = 3, type = "description", name = " ", fontSize = "small" },
                anchorFrame = {
                    order = 4,
                    type = "select",
                    name = L["COTANK_ANCHOR_TO"] or "Anchor to",
                    values = {
                        UIParent = L["COTANK_ANCHOR_SCREEN"] or "Screen",
                        PlayerFrame = L["COTANK_ANCHOR_PLAYER"] or "Player",
                        TargetFrame = L["COTANK_ANCHOR_TARGET"] or "Target",
                        FocusFrame = L["COTANK_ANCHOR_FOCUS"] or "Focus",
                        ElvUF_Player = "ElvUI Player",
                        ElvUF_Target = "ElvUI Target",
                        ElvUF_Focus = "ElvUI Focus",
                        Custom = "Custom",
                    },
                    get = function() return (GetDB() or {}).anchorFrame or "UIParent" end,
                    set = function(_, v) local d = GetDB(); if d then d.anchorFrame = v; RefreshDisplay() end end,
                },
                anchorFrameCustom = {
                    order = 5,
                    type = "input",
                    name = "Custom frame name",
                    get = function() return (GetDB() or {}).anchorFrameCustom or "UIParent" end,
                    set = function(_, v)
                        local d = GetDB()
                        if d then d.anchorFrameCustom = (v and v:trim() ~= "" and v:trim()) or "UIParent"; RefreshDisplay() end
                    end,
                    disabled = function() return (GetDB() or {}).anchorFrame ~= "Custom" end,
                },
                spacerAnchor = { order = 6, type = "description", name = " ", fontSize = "small" },
                anchorX = {
                    order = 7,
                    type = "range",
                    name = L["COTANK_OFFSET_X"] or "Offset X",
                    desc = L["COTANK_OFFSET_DESC"] or "Horizontal offset from the anchor.",
                    min = -500, max = 500, step = 1,
                    get = function() return (GetDB() or {}).x or 200 end,
                    set = function(_, v) local d = GetDB(); if d then d.x = v; RefreshDisplay() end end,
                    disabled = function() return (GetDB() or {}).anchorFrame == "UIParent" end,
                },
                anchorY = {
                    order = 8,
                    type = "range",
                    name = L["COTANK_OFFSET_Y"] or "Offset Y",
                    desc = L["COTANK_OFFSET_DESC"] or "Vertical offset from the anchor.",
                    min = -500, max = 500, step = 1,
                    get = function() return (GetDB() or {}).y or 0 end,
                    set = function(_, v) local d = GetDB(); if d then d.y = v; RefreshDisplay() end end,
                    disabled = function() return (GetDB() or {}).anchorFrame == "UIParent" end,
                },
                useClassColor = {
                    order = 10,
                    type = "toggle",
                    name = L["COTANK_USE_CLASS_COLOR"] or "Use Class Color",
                    desc = L["COTANK_USE_CLASS_COLOR_DESC"] or "Use class color for health bar and name.",
                    get = function() return (GetDB() or {}).useClassColor end,
                    set = function(_, v) local d = GetDB(); if d then d.useClassColor = v; RefreshDisplay() end end,
                },
                healthColor = {
                    order = 11,
                    type = "color",
                    name = L["COTANK_HEALTH_COLOR"] or "Health Color",
                    hasAlpha = false,
                    get = function() local d = GetDB(); return d and (d.healthColorR or 0) or 0, d and (d.healthColorG or 0.8) or 0.8, d and (d.healthColorB or 0.2) or 0.2 end,
                    set = function(_, r, g, b) local d = GetDB(); if d then d.healthColorR, d.healthColorG, d.healthColorB = r, g, b; RefreshDisplay() end end,
                    disabled = function() return (GetDB() or {}).useClassColor end,
                },
                width = {
                    order = 12,
                    type = "range",
                    name = L["COTANK_WIDTH"] or "Width",
                    min = 50, max = 300, step = 1,
                    get = function() return (GetDB() or {}).width or 150 end,
                    set = function(_, v) local d = GetDB(); if d then d.width = v; RefreshDisplay() end end,
                },
                height = {
                    order = 13,
                    type = "range",
                    name = L["COTANK_HEIGHT"] or "Height",
                    min = 10, max = 60, step = 1,
                    get = function() return (GetDB() or {}).height or 20 end,
                    set = function(_, v) local d = GetDB(); if d then d.height = v; RefreshDisplay() end end,
                },
                bgAlpha = {
                    order = 14,
                    type = "range",
                    name = L["COTANK_BG_OPACITY"] or "Background Opacity",
                    min = 0, max = 1, step = 0.05,
                    isPercent = true,
                    get = function() return (GetDB() or {}).bgAlpha or 0.6 end,
                    set = function(_, v) local d = GetDB(); if d then d.bgAlpha = v; RefreshDisplay() end end,
                },
                spacer3 = { order = 15, type = "description", name = " ", fontSize = "small" },
                showName = {
                    order = 20,
                    type = "toggle",
                    name = L["COTANK_SHOW_NAME"] or "Show Name",
                    get = function() return (GetDB() or {}).showName end,
                    set = function(_, v) local d = GetDB(); if d then d.showName = v; RefreshDisplay() end end,
                },
                nameFormat = {
                    order = 21,
                    type = "select",
                    name = L["COTANK_NAME_FORMAT"] or "Name Format",
                    values = {
                        full = L["COTANK_NAME_FULL"] or "Full",
                        abbreviated = L["COTANK_NAME_ABBREV"] or "Abbreviated",
                    },
                    get = function() return (GetDB() or {}).nameFormat or "full" end,
                    set = function(_, v) local d = GetDB(); if d then d.nameFormat = v; RefreshDisplay() end end,
                },
                nameLength = {
                    order = 22,
                    type = "range",
                    name = L["COTANK_NAME_LENGTH"] or "Name Length",
                    min = 3, max = 12, step = 1,
                    get = function() return (GetDB() or {}).nameLength or 6 end,
                    set = function(_, v) local d = GetDB(); if d then d.nameLength = v; RefreshDisplay() end end,
                    disabled = function() return (GetDB() or {}).nameFormat ~= "abbreviated" end,
                },
                nameFontSize = {
                    order = 23,
                    type = "range",
                    name = L["COTANK_NAME_FONT_SIZE"] or "Font Size",
                    min = 8, max = 24, step = 1,
                    get = function() return (GetDB() or {}).nameFontSize or 12 end,
                    set = function(_, v) local d = GetDB(); if d then d.nameFontSize = v; RefreshDisplay() end end,
                },
                nameColor = {
                    order = 25,
                    type = "color",
                    name = L["COTANK_NAME_COLOR"] or "Name Color",
                    hasAlpha = false,
                    get = function() local d = GetDB(); return d and (d.nameColorR or 1) or 1, d and (d.nameColorG or 1) or 1, d and (d.nameColorB or 1) or 1 end,
                    set = function(_, r, g, b) local d = GetDB(); if d then d.nameColorR, d.nameColorG, d.nameColorB = r, g, b; RefreshDisplay() end end,
                },
                restoreDefaults = {
                    order = 30,
                    type = "execute",
                    name = "Restore defaults",
                    func = function()
                        local d = GetDB()
                        local defaults = TankStuff and TankStuff.CO_TANK_DEFAULTS
                        if d and defaults then
                            for k, v in pairs(defaults) do d[k] = v end
                            RefreshDisplay()
                        end
                    end,
                },
            },
        },
    }
end

local function InsertOptions()
    local E = _G.ElvUI and type(_G.ElvUI) == "table" and (_G.ElvUI[1] or select(1, unpack(_G.ElvUI)))
    if not E or not E.Options or not E.Options.args then return end
    local ACH = E.Libs and E.Libs.ACH
    if not ACH or not ACH.Group then return end

    local args = BuildOptionsArgs()
    if not args then return end

    E.Options.args.TankStuff = ACH:Group("Tank Stuff", nil, 99, "tab")
    E.Options.args.TankStuff.args = args
end

local function TryRegister()
    if TankStuff.IsElvUIPlugin then return true end
    if not _G.ElvUI or type(_G.ElvUI) ~= "table" then return false end

    local E = _G.ElvUI[1] or select(1, unpack(_G.ElvUI))
    if not E or not E.Options or not E.Options.args then return false end
    local ACH = E.Libs and E.Libs.ACH
    if not ACH or not ACH.Group then return false end

    -- Register with LibElvUIPlugin so Tank Stuff appears in the Plugins tab list (like ElvUI Anchor)
    local EP = LibStub and LibStub("LibElvUIPlugin-1.0", true)
    if EP then
        EP:RegisterPlugin(addonName, InsertOptions)
    else
        -- Fallback if lib not available: add options directly
        InsertOptions()
    end

    TankStuff.IsElvUIPlugin = true
    if E.ToggleOptions then
        _G.TankStuff_OnAddonCompartmentClick = function()
            E:ToggleOptions("TankStuff")
        end
    end
    return true
end

-- Run immediately (ElvUI loads first via OptionalDeps)
TryRegister()

local frame = CreateFrame("Frame")
frame:RegisterEvent("ADDON_LOADED")
frame:SetScript("OnEvent", function(_, event, name)
    if event == "ADDON_LOADED" and (name == "ElvUI" or name == "ElvUI_Options" or name == addonName) then
        if TryRegister() and name == addonName then
            frame:UnregisterAllEvents()
        end
    end
end)

C_Timer.After(0, function()
    if TryRegister() then
        frame:UnregisterAllEvents()
    end
end)
