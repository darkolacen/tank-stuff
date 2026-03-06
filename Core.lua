-- TankStuff core: saved vars and co-tank defaults
TankStuff = TankStuff or {}

local CO_TANK_DEFAULTS = {
    enabled = false,
    unlock = false,
    font = "GothamNarrowUltra",
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
    if not TankStuffDB then
        TankStuffDB = { coTank = {} }
    end
    if not TankStuffDB.coTank then
        TankStuffDB.coTank = {}
    end
    for k, v in pairs(CO_TANK_DEFAULTS) do
        if TankStuffDB.coTank[k] == nil then
            TankStuffDB.coTank[k] = v
        end
    end
    return TankStuffDB.coTank
end

TankStuff.CO_TANK_DEFAULTS = CO_TANK_DEFAULTS

-- Taunt Aura: square on screen when player uses a taunt
local TAUNT_AURA_DEFAULTS = {
    enabled = true,
    size = 80,
    duration = 1.5,
    point = "CENTER",
    x = 0,
    y = 0,
    relativePoint = "CENTER",
    colorR = 1,
    colorG = 0.4,
    colorB = 0,
    colorA = 0.9,
    nameFontSize = 12,
    raidTauntSync = true,
}

function TankStuff.GetTauntAuraDB()
    if not TankStuffDB then
        TankStuffDB = { coTank = {}, tauntAura = {} }
    end
    if not TankStuffDB.tauntAura then
        TankStuffDB.tauntAura = {}
    end
    for k, v in pairs(TAUNT_AURA_DEFAULTS) do
        if TankStuffDB.tauntAura[k] == nil then
            TankStuffDB.tauntAura[k] = v
        end
    end
    return TankStuffDB.tauntAura
end

TankStuff.TAUNT_AURA_DEFAULTS = TAUNT_AURA_DEFAULTS
