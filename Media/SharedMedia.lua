-- Register fonts and statusbar texture with LibSharedMedia (TankStuff).
local function RegisterMedia()
    if not LibStub then return false end
    local LSM = LibStub("LibSharedMedia-3.0", true)
    if not LSM then return false end

    local koKR = LSM.LOCALE_BIT_koKR
    local ruRU = LSM.LOCALE_BIT_ruRU
    local zhCN = LSM.LOCALE_BIT_zhCN
    local zhTW = LSM.LOCALE_BIT_zhTW
    local western = LSM.LOCALE_BIT_western

    local FONT = LSM.MediaType.FONT
    local STATUSBAR = LSM.MediaType.STATUSBAR

    -- Fonts (locale-aware)
    LSM:Register(FONT, "GothamNarrowUltra", [[Interface\Addons\TankStuff\Media\Fonts\GothamNarrowUltra.ttf]], ruRU + western)
    LSM:Register(FONT, "GothamNarrowUltra", [[Interface\Addons\TankStuff\Media\Fonts\GothamNarrowUltraAsia.ttf]], koKR + zhCN + zhTW)

    -- Statusbar texture
    LSM:Register(STATUSBAR, "Melli", [[Interface\Addons\TankStuff\Media\Textures\Melli]])

    return true
end

if RegisterMedia() then return end

-- LibSharedMedia is often embedded in other addons, so ADDON_LOADED may fire with their name.
-- Retry on every addon load until we succeed.
local frame = CreateFrame("Frame")
frame:RegisterEvent("ADDON_LOADED")
frame:SetScript("OnEvent", function()
    if RegisterMedia() then
        frame:UnregisterAllEvents()
    end
end)
