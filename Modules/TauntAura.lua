-- Taunt Aura: show a square on screen when you use a taunt ability.
-- Workaround for raid/party: addon messages – when a group member with TankStuff taunts, they broadcast; we show the aura.
local TAUNT_SPELL_IDS = {
    [355]     = true, -- Warrior: Taunt
    [115546]  = true, -- Monk: Provoke
    [116189]  = true, -- Warrior: Challenging Shout
    [185245]  = true, -- DH: Torment
    [49560]   = true, -- DK: Death Grip (taunt)
    [56222]   = true, -- DK: Dark Command
    [62124]   = true, -- Paladin: Hand of Reckoning
    [6795]    = true, -- Druid: Growl
    [5209]    = true, -- Druid: Challenging Roar
    [20736]   = true, -- Druid: Taunt (Legacy)
}

local function GetDB()
    return TankStuff and TankStuff.GetTauntAuraDB() or nil
end

local frame = CreateFrame("Frame", nil, UIParent, "BackdropTemplate")
frame:SetFrameStrata("FULLSCREEN_DIALOG")
frame:SetFrameLevel(100)
frame:SetSize(80, 80)
frame:SetPoint("CENTER", UIParent, "CENTER", 0, 0)
frame:SetBackdrop({
    edgeFile = [[Interface\Buttons\WHITE8x8]],
    edgeSize = 2,
})
frame:SetBackdropBorderColor(1, 0.6, 0, 1)
frame:Show()
frame:SetAlpha(0)  -- "hidden" until taunt; use alpha so we can show in combat (Show/Hide are protected)

-- Spell icon texture (shows the taunt ability used)
local icon = frame:CreateTexture(nil, "ARTWORK")
icon:SetPoint("CENTER")
icon:SetSize(76, 76)  -- slightly inset from edge
icon:SetTexCoord(0.08, 0.92, 0.08, 0.92)

-- Target name (right of icon – who the taunt was used on)
local targetLabel = frame:CreateFontString(nil, "OVERLAY", "GameFontHighlightSmall")
targetLabel:SetPoint("TOPLEFT", frame, "TOPRIGHT", 1, -8)
targetLabel:SetJustifyH("LEFT")
targetLabel:SetJustifyV("TOP")
targetLabel:SetWordWrap(false)

-- Player name (bottom-right of icon – who used the taunt)
local nameLabel = frame:CreateFontString(nil, "OVERLAY", "GameFontHighlightSmall")
nameLabel:SetPoint("BOTTOMLEFT", frame, "BOTTOMRIGHT", 1, 8)
nameLabel:SetJustifyH("LEFT")
nameLabel:SetJustifyV("BOTTOM")
nameLabel:SetWordWrap(false)

local hideTimer = nil

local function ShowTauntSquare(spellId, casterName, destGUID, playerTargetName)
    local db = GetDB()
    if not db or not db.enabled then return end

    local inCombat = InCombatLockdown()
    if not inCombat then
        frame:SetSize(db.size or 80, db.size or 80)
        icon:SetSize(math.max(4, (db.size or 80) - 4), math.max(4, (db.size or 80) - 4))
    end
    -- Set icon to the taunt ability that was just used
    local getTex = GetSpellTexture or (C_Spell and C_Spell.GetSpellTexture)
    local tex = (spellId and getTex and getTex(spellId)) or nil
    if tex then
        icon:SetTexture(tex)
    else
        icon:SetTexture([[Interface\Icons\Ability_Physical_Taunt]])
    end
    -- Target name above the icon: resolve from destGUID (untainted) or use playerTargetName (player cast path)
    local targetToShow = ""
    if destGUID and destGUID ~= "" then
        local name = GetPlayerInfoByGUID and GetPlayerInfoByGUID(destGUID)
        if name and name ~= "" then targetToShow = name end
    elseif playerTargetName and playerTargetName ~= "" then
        targetToShow = playerTargetName
    end
    targetLabel:SetText(targetToShow)
    local fontSize = db.nameFontSize or 12
    targetLabel:SetFont(targetLabel:GetFont(), fontSize, "OUTLINE")
    targetLabel:SetTextColor(1, 0.9, 0.6, 1)
    -- Player name just below the icon (who used the taunt)
    local nameToShow = (type(casterName) == "string" and #casterName > 0) and casterName or (UnitName("player") or "")
    nameLabel:SetText(nameToShow)
    nameLabel:SetFont(nameLabel:GetFont(), fontSize, "OUTLINE")
    nameLabel:SetTextColor(1, 1, 1, 1)
    frame:SetBackdropBorderColor(
        math.min(1, (db.colorR or 1) * 1.2),
        math.min(1, (db.colorG or 0.4) * 1.2),
        math.min(1, (db.colorB or 0) * 1.2),
        1
    )
    if not inCombat and not frame.mover then
        frame:ClearAllPoints()
        frame:SetPoint(db.point or "CENTER", UIParent, db.relativePoint or "CENTER", db.x or 0, db.y or 0)
    end
    frame:SetAlpha(1)

    if hideTimer then
        hideTimer:Cancel()
    end
    hideTimer = C_Timer.NewTimer(db.duration or 1.5, function()
        hideTimer = nil
        frame:SetAlpha(0)
    end)
end

local function ApplyPosition()
    local db = GetDB()
    if not db or InCombatLockdown() then return end
    frame:ClearAllPoints()
    local size = db.size or 80
    if frame.mover then
        frame.mover:ClearAllPoints()
        frame.mover:SetPoint(db.point or "CENTER", UIParent, db.relativePoint or "CENTER", db.x or 0, db.y or 0)
        frame.mover:SetSize(size, size)
        frame:SetPoint("CENTER", frame.mover, "CENTER", 0, 0)
    else
        frame:SetPoint(db.point or "CENTER", UIParent, db.relativePoint or "CENTER", db.x or 0, db.y or 0)
    end
    frame:SetSize(size, size)
    icon:SetSize(math.max(4, size - 4), math.max(4, size - 4))
end

local function onTauntSpellCast(unit, castGUID, spellId)
    if unit == "player" and spellId and TAUNT_SPELL_IDS[spellId] then
        local playerTargetName = UnitName("target") or ""
        ShowTauntSquare(spellId, UnitName("player"), nil, playerTargetName)
        -- Broadcast to raid/party so others with TankStuff can show our taunt (workaround for no CLEU)
        local db = GetDB()
        if db and db.raidTauntSync ~= false and (IsInGroup() or IsInRaid()) then
            local payload = tostring(spellId) .. ":" .. (playerTargetName or "")
            local channel = IsInRaid() and "RAID" or "PARTY"
            if C_ChatInfo and C_ChatInfo.SendAddonMessage then
                C_ChatInfo.SendAddonMessage("TankStuffTaunt", payload, channel)
            end
        end
    end
end

-- Receive taunt broadcasts from raid/party (only from players in our group)
local ADDON_MSG_PREFIX = "TankStuffTaunt"

local function normalizePlayerName(name)
    if not name or name == "" then return "" end
    return (name:match("^([^%-]+)") or name):gsub("%s+", "")
end

local function isSenderInGroup(sender)
    if not sender or sender == "" then return false end
    local s = normalizePlayerName(sender)
    if normalizePlayerName(UnitName("player")) == s then return true end
    if IsInRaid() then
        for i = 1, GetNumGroupMembers() do
            if normalizePlayerName(UnitName("raid" .. i)) == s then return true end
        end
    elseif IsInGroup() then
        for i = 1, 4 do
            if normalizePlayerName(UnitName("party" .. i)) == s then return true end
        end
    end
    return false
end

-- Player taunts: UNIT_SPELLCAST_SUCCEEDED. Raid/party: addon messages (requires others to have TankStuff).
local eventFrame = CreateFrame("Frame", nil, UIParent)
eventFrame:SetScript("OnEvent", function(_, event, ...)
    if event == "UNIT_SPELLCAST_SUCCEEDED" then
        local unit, castGUID, spellId = ...
        onTauntSpellCast(unit, castGUID, spellId)
    elseif event == "CHAT_MSG_ADDON" then
        local prefix, msg, channel, sender = ...
        if prefix ~= ADDON_MSG_PREFIX or not msg or msg == "" then return end
        local db = GetDB()
        if not db or not db.enabled or db.raidTauntSync == false then return end
        if not isSenderInGroup(sender) then return end
        local spellIdStr, targetName = msg:match("^(%d+):(.*)$")
        if not spellIdStr then return end
        local spellId = tonumber(spellIdStr)
        if not spellId or not TAUNT_SPELL_IDS[spellId] then return end
        ShowTauntSquare(spellId, sender, nil, (targetName and targetName ~= "") and targetName or nil)
    elseif event == "PLAYER_LOGIN" then
        if C_ChatInfo and C_ChatInfo.RegisterAddonMessagePrefix then
            C_ChatInfo.RegisterAddonMessagePrefix(ADDON_MSG_PREFIX)
        end
    end
end)
do
    local ok = pcall(function()
        eventFrame:RegisterUnitEvent("UNIT_SPELLCAST_SUCCEEDED", "player")
    end)
    if not ok then eventFrame:SetScript("OnEvent", nil) end
end
-- Register prefix at load; also on PLAYER_LOGIN in case load is too early
if C_ChatInfo and C_ChatInfo.RegisterAddonMessagePrefix then
    C_ChatInfo.RegisterAddonMessagePrefix(ADDON_MSG_PREFIX)
    eventFrame:RegisterEvent("PLAYER_LOGIN")
end
eventFrame:RegisterEvent("CHAT_MSG_ADDON")

-- Apply position when options refresh (no PLAYER_LOGIN needed)
C_Timer.After(2, ApplyPosition)

function frame:Refresh()
    ApplyPosition()
    if hideTimer and GetDB() and not GetDB().enabled then
        frame:SetAlpha(0)
        if hideTimer then hideTimer:Cancel() hideTimer = nil end
    end
    -- Show or hide Taunt Aura in ElvUI movers when enabled changes
    local E = _G.ElvUI and unpack(_G.ElvUI)
    if E and E.EnableMover and E.DisableMover then
        local name = "TankStuffTauntAuraMover"
        local enabled = GetDB() and GetDB().enabled
        if E.DisabledMovers[name] and enabled then
            E:EnableMover(name)
        elseif E.CreatedMovers[name] and not enabled then
            E:DisableMover(name)
        end
    end
end

TankStuff.TauntAuraFrame = frame