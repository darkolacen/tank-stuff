-- TankStuff core: saved vars and co-tank defaults
TankStuff = TankStuff or {}

-- Preview is session-only (not saved)
TankStuff.previewEnabled = false

-- Single-level table so WoW SavedVariables reliably persist (key = TankStuffDB in TOC)
if not _G.TankStuffDB then
    _G.TankStuffDB = {}
end

-- Migrate old nested format to flat (once)
do
    local T = _G.TankStuffDB
    if T.coTank and type(T.coTank) == "table" then
        for k, v in pairs(T.coTank) do
            if T[k] == nil then T[k] = v end
        end
        T.coTank = nil
    end
end

local CO_TANK_DEFAULTS = {
    enabled = false,
    font = "Fonts\\FRIZQT__.TTF",
    point = "CENTER",
    x = 200,
    y = 0,
    relativePoint = "CENTER",
    anchorFrame = "UIParent",
    anchorFrameCustom = "UIParent",
    width = 150,
    height = 20,
    healthColorR = 0,
    healthColorG = 0.8,
    healthColorB = 0.2,
    useClassColor = true,
    bgAlpha = 0.6,
    showName = true,
    nameFormat = "full",
    nameLength = 6,
    nameFontSize = 12,
    nameColorR = 1,
    nameColorG = 1,
    nameColorB = 1,
    nameColorUseClassColor = true,
}

function TankStuff.GetCoTankDB()
    local T = _G.TankStuffDB
    for k, v in pairs(CO_TANK_DEFAULTS) do
        if T[k] == nil then T[k] = v end
    end
    return T
end

TankStuff.CO_TANK_DEFAULTS = CO_TANK_DEFAULTS
