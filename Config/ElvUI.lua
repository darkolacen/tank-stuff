-- ElvUI plugin: register Tank Stuff and embed full Co-Tank + Taunt Aura options.
local ElvUI = _G.ElvUI
local LibStub = _G.LibStub
if not ElvUI or not LibStub then return end

local EP = LibStub("LibElvUIPlugin-1.0", true)
if not EP then return end

local E = unpack(ElvUI)
if not E or not E.Libs or not E.Libs.ACH then return end

local ACH = E.Libs.ACH
local L = _G.TankStuff_L or setmetatable({}, { __index = function(_, k) return k end })

local function coTankRefresh()
    if TankStuff and TankStuff.CoTankDisplay then
        TankStuff.CoTankDisplay.posInitialized = nil
        TankStuff.CoTankDisplay:Refresh()
    end
end

local function tauntAuraRefresh()
    if TankStuff and TankStuff.TauntAuraFrame then
        TankStuff.TauntAuraFrame:Refresh()
    end
end

-- Match anchor presets: Screen, Player, Target, Focus, ElvUI P, ElvUI T, ElvUI F, Custom
local anchorValues = {
    UIParent = L["COTANK_ANCHOR_SCREEN"],
    PlayerFrame = L["COTANK_ANCHOR_PLAYER"],
    TargetFrame = L["COTANK_ANCHOR_TARGET"],
    FocusFrame = L["COTANK_ANCHOR_FOCUS"],
    ElvUF_Player = "ElvUI P",
    ElvUF_Target = "ElvUI T",
    ElvUF_Focus = "ElvUI F",
    Custom = "Custom",
}

local nameFormatValues = { full = L["COTANK_NAME_FULL"], abbreviated = L["COTANK_NAME_ABBREV"] }

local function insertOptions()
    -- Co-Tank tab
    local coTank = ACH:Group(L["SIDEBAR_TAB_COTANK"], nil, 1)
    coTank.args.enabled = ACH:Toggle(L["COTANK_ENABLE"], L["COTANK_ENABLE_DESC"], 1, nil, nil, nil,
        function() return TankStuff.GetCoTankDB().enabled end,
        function(_, v) TankStuff.GetCoTankDB().enabled = v; coTankRefresh() end)
    coTank.args.unlock = ACH:Toggle(L["COTANK_PREVIEW"], L["COTANK_PREVIEW_DESC"], 2, nil, nil, nil,
        function() return TankStuff.GetCoTankDB().unlock end,
        function(_, v) TankStuff.GetCoTankDB().unlock = v; coTankRefresh() end)
    coTank.args.anchorHeader = ACH:Header(L["COTANK_ANCHOR_TO"], 3)
    coTank.args.anchorFrame = ACH:Select(L["COTANK_ANCHOR_TO"], nil, 4, anchorValues, nil, nil,
        function() return TankStuff.GetCoTankDB().anchorFrame or "UIParent" end,
        function(_, v) TankStuff.GetCoTankDB().anchorFrame = v; coTankRefresh() end)
    coTank.args.anchorFrameCustom = ACH:Input("Custom frame name", "When Anchor is Custom.", 5, false, "full",
        function() return TankStuff.GetCoTankDB().anchorFrameCustom or "UIParent" end,
        function(_, v) TankStuff.GetCoTankDB().anchorFrameCustom = (v and v:match("%S") and v) or "UIParent"; coTankRefresh() end,
        nil, function() return (TankStuff.GetCoTankDB().anchorFrame or "UIParent") ~= "Custom" end)
    coTank.args.x = ACH:Range(L["COTANK_OFFSET_X"], nil, 6, { min = -400, max = 400, step = 1 }, nil,
        function() return TankStuff.GetCoTankDB().x or 200 end,
        function(_, v) TankStuff.GetCoTankDB().x = v; coTankRefresh() end)
    coTank.args.y = ACH:Range(L["COTANK_OFFSET_Y"], nil, 7, { min = -400, max = 400, step = 1 }, nil,
        function() return TankStuff.GetCoTankDB().y or 0 end,
        function(_, v) TankStuff.GetCoTankDB().y = v; coTankRefresh() end)
    coTank.args.healthHeader = ACH:Header(L["COTANK_SECTION_HEALTH"], 8)
    coTank.args.useClassColor = ACH:Toggle(L["COTANK_USE_CLASS_COLOR"], nil, 9, nil, nil, nil,
        function() return TankStuff.GetCoTankDB().useClassColor end,
        function(_, v) TankStuff.GetCoTankDB().useClassColor = v; coTankRefresh() end)
    coTank.args.healthColor = ACH:Color(L["COTANK_HEALTH_COLOR"], nil, 10, false, nil,
        function() local d = TankStuff.GetCoTankDB(); return d.healthColorR, d.healthColorG, d.healthColorB end,
        function(_, r, g, b) local d = TankStuff.GetCoTankDB(); d.healthColorR, d.healthColorG, d.healthColorB = r, g, b; coTankRefresh() end,
        function() return TankStuff.GetCoTankDB().useClassColor end)
    coTank.args.width = ACH:Range(L["COTANK_WIDTH"], nil, 11, { min = 50, max = 300, step = 1 }, nil,
        function() return TankStuff.GetCoTankDB().width or 150 end,
        function(_, v) TankStuff.GetCoTankDB().width = v; coTankRefresh() end)
    coTank.args.height = ACH:Range(L["COTANK_HEIGHT"], nil, 12, { min = 10, max = 60, step = 1 }, nil,
        function() return TankStuff.GetCoTankDB().height or 20 end,
        function(_, v) TankStuff.GetCoTankDB().height = v; coTankRefresh() end)
    coTank.args.bgAlpha = ACH:Range(L["COTANK_BG_OPACITY"], nil, 13, { min = 0, max = 1, step = 0.05, isPercent = true }, nil,
        function() return TankStuff.GetCoTankDB().bgAlpha or 0.6 end,
        function(_, v) TankStuff.GetCoTankDB().bgAlpha = v; coTankRefresh() end)
    coTank.args.nameHeader = ACH:Header(L["COTANK_SECTION_NAME"], 14)
    coTank.args.showName = ACH:Toggle(L["COTANK_SHOW_NAME"], nil, 15, nil, nil, nil,
        function() return TankStuff.GetCoTankDB().showName end,
        function(_, v) TankStuff.GetCoTankDB().showName = v; coTankRefresh() end)
    coTank.args.nameFormat = ACH:Select(L["COTANK_NAME_FORMAT"], nil, 16, nameFormatValues, nil, nil,
        function() return TankStuff.GetCoTankDB().nameFormat or "full" end,
        function(_, v) TankStuff.GetCoTankDB().nameFormat = v; coTankRefresh() end)
    coTank.args.nameLength = ACH:Range(L["COTANK_NAME_LENGTH"], nil, 17, { min = 3, max = 12, step = 1 }, nil,
        function() return TankStuff.GetCoTankDB().nameLength or 6 end,
        function(_, v) TankStuff.GetCoTankDB().nameLength = v; coTankRefresh() end)
    coTank.args.nameFontSize = ACH:Range(L["COTANK_NAME_FONT_SIZE"], nil, 18, { min = 8, max = 24, step = 1 }, nil,
        function() return TankStuff.GetCoTankDB().nameFontSize or 12 end,
        function(_, v) TankStuff.GetCoTankDB().nameFontSize = v; coTankRefresh() end)
    coTank.args.nameColorUseClassColor = ACH:Toggle(L["COTANK_NAME_USE_CLASS_COLOR"], nil, 19, nil, nil, nil,
        function() return TankStuff.GetCoTankDB().nameColorUseClassColor end,
        function(_, v) TankStuff.GetCoTankDB().nameColorUseClassColor = v; coTankRefresh() end)
    coTank.args.nameColor = ACH:Color(L["COTANK_NAME_COLOR"], nil, 20, false, nil,
        function() local d = TankStuff.GetCoTankDB(); return d.nameColorR, d.nameColorG, d.nameColorB end,
        function(_, r, g, b) local d = TankStuff.GetCoTankDB(); d.nameColorR, d.nameColorG, d.nameColorB = r, g, b; coTankRefresh() end,
        function() return TankStuff.GetCoTankDB().nameColorUseClassColor end)
    coTank.args.restoreCo = ACH:Execute("Restore defaults", nil, 21, function()
        local def = TankStuff.CO_TANK_DEFAULTS
        if def then for k, v in pairs(def) do TankStuff.GetCoTankDB()[k] = v end end
        coTankRefresh()
    end)

    -- Taunt Aura tab
    local tauntAura = ACH:Group(L["TAUNT_AURA_TAB"], nil, 2)
    tauntAura.args.ownOnlyNote = ACH:Description("Shows when you use a taunt. With 'Raid taunt sync' on, also shows when other raid/party members taunt — they must have TankStuff and sync enabled.", 0)
    tauntAura.args.enabled = ACH:Toggle(L["TAUNT_AURA_ENABLE"], nil, 1, nil, nil, nil,
        function() return TankStuff.GetTauntAuraDB().enabled end,
        function(_, v) TankStuff.GetTauntAuraDB().enabled = v; tauntAuraRefresh() end)
    tauntAura.args.size = ACH:Range(L["TAUNT_AURA_SIZE"], nil, 2, { min = 40, max = 200, step = 5 }, nil,
        function() return TankStuff.GetTauntAuraDB().size or 80 end,
        function(_, v) TankStuff.GetTauntAuraDB().size = v; tauntAuraRefresh() end)
    tauntAura.args.duration = ACH:Range(L["TAUNT_AURA_DURATION"], nil, 3, { min = 0.5, max = 5, step = 0.25 }, nil,
        function() return TankStuff.GetTauntAuraDB().duration or 1.5 end,
        function(_, v) TankStuff.GetTauntAuraDB().duration = v; tauntAuraRefresh() end)
    tauntAura.args.nameFontSize = ACH:Range("Player name font size", "Font size for the name shown on the aura.", 4, { min = 8, max = 24, step = 1 }, nil,
        function() return TankStuff.GetTauntAuraDB().nameFontSize or 12 end,
        function(_, v) TankStuff.GetTauntAuraDB().nameFontSize = v; tauntAuraRefresh() end)
    tauntAura.args.raidTauntSync = ACH:Toggle("Raid taunt sync", "Broadcast your taunts to the group and show taunts from others who have TankStuff with this option enabled. Only works when other tanks use the addon.", 4.5, nil, nil, nil,
        function() return TankStuff.GetTauntAuraDB().raidTauntSync ~= false end,
        function(_, v) TankStuff.GetTauntAuraDB().raidTauntSync = v; tauntAuraRefresh() end)
    tauntAura.args.restoreTaunt = ACH:Execute("Restore defaults", nil, 5, function()
        local def = TankStuff.TAUNT_AURA_DEFAULTS
        if def then for k, v in pairs(def) do TankStuff.GetTauntAuraDB()[k] = v end end
        tauntAuraRefresh()
    end)

    local main = ACH:Group("Tank Stuff", nil, 5)
    main.childGroups = "tab"
    main.args.coTank = coTank
    main.args.tauntAura = tauntAura
    E.Options.args.TankStuff = main
end

EP:RegisterPlugin("TankStuff", insertOptions)

-- Register Taunt Aura frame with ElvUI movers when enabled (after ElvUI has initialized)
local TANKSTUFF_TAUNT_MOVER = "TankStuffTauntAuraMover"
local function createTauntAuraMover()
    if not TankStuff or not TankStuff.TauntAuraFrame then return end
    local E = unpack(ElvUI)
    if E.CreatedMovers[TANKSTUFF_TAUNT_MOVER] or E.DisabledMovers[TANKSTUFF_TAUNT_MOVER] then return end
    local frame = TankStuff.TauntAuraFrame
    local db = TankStuff.GetTauntAuraDB and TankStuff.GetTauntAuraDB()
    if not db then return end
    local shouldDisable = not db.enabled
    E:CreateMover(frame, TANKSTUFF_TAUNT_MOVER, L["TAUNT_AURA_TAB"], nil, nil, function(mover)
        if not mover or not mover.GetPoint then return end
        local point, relativeTo, relativePoint, x, y = mover:GetPoint()
        if point and (relativeTo == UIParent or (relativeTo and relativeTo.GetName and relativeTo:GetName() == "UIParent")) then
            local d = TankStuff.GetTauntAuraDB()
            if d then
                d.point = point
                d.relativePoint = relativePoint or point
                d.x = math.floor(x or 0)
                d.y = math.floor(y or 0)
            end
        end
    end, nil, shouldDisable, nil, true)
    if db.enabled then
        E:EnableMover(TANKSTUFF_TAUNT_MOVER)
    end
    if frame.Refresh then frame:Refresh() end
end
EP:HookInitialize(TankStuff or {}, createTauntAuraMover)
-- If ElvUI already initialized before we loaded, create mover on next tick
C_Timer.After(0, createTauntAuraMover)
