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
