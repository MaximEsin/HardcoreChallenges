-- core/slayer.lua — Slayer: 10000 NPC kills (any creature type), your killing blow.

local addon = HardcoreChallenges
local UI = addon.UI

local GOAL = 10000
local KEY = "Slayer1"

addon.SlayerChallengeKey = KEY

function addon:IsSlayerChallengeKey(k)
    return k == KEY
end

function addon:GetSlayerGoal()
    return GOAL
end

function addon:GetSlayerProgressDisplay(key)
    if key ~= KEY then return 0, GOAL end
    local db = addon.CharDB
    local n = db.slayer1KillCount or 0
    return math.min(GOAL, n), GOAL
end

local slayerDeathCredited = {}
local lastPlayerDamageToGUID = {}
local DAMAGE_ATTRIB_WINDOW = 28

local damageSubevents = {
    SWING_DAMAGE = true,
    RANGE_DAMAGE = true,
    SPELL_DAMAGE = true,
    SPELL_PERIODIC_DAMAGE = true,
    DAMAGE_SHIELD = true,
    SPELL_BUILDING_DAMAGE = true,
    DAMAGE_SPLIT = true,
}

local function IsDamageSubevent(subevent)
    if not subevent then return false end
    subevent = string.upper(subevent)
    if damageSubevents[subevent] then return true end
    if strfind(subevent, "_MISSED") or strfind(subevent, "MISSED_") then return false end
    if strfind(subevent, "DAMAGE") then return true end
    return false
end

local function AffiliationMine(flags)
    return bit.band(flags or 0, COMBATLOG_OBJECT_AFFILIATION_MINE) ~= 0
end

local function SourceIsPlayerKillCredit(sourceGUID, sourceFlags)
    if not sourceGUID or sourceGUID == "" then return false end
    if sourceGUID == UnitGUID("player") then return true end
    if UnitExists("pet") and sourceGUID == UnitGUID("pet") then return true end
    local sf = sourceFlags or 0
    if AffiliationMine(sf) and bit.band(sf, COMBATLOG_OBJECT_CONTROL_PLAYER) ~= 0 then
        if bit.band(sf, COMBATLOG_OBJECT_TYPE_PLAYER) ~= 0 then return true end
        if bit.band(sf, COMBATLOG_OBJECT_TYPE_PET) ~= 0 then return true end
        if bit.band(sf, COMBATLOG_OBJECT_TYPE_GUARDIAN) ~= 0 then return true end
    end
    return false
end

local function RecentlyDamagedByPlayer(destGUID)
    if not destGUID then return false end
    local t = lastPlayerDamageToGUID[destGUID]
    if not t then return false end
    return (GetTime() - t) <= DAMAGE_ATTRIB_WINDOW
end

local function KillCreditToPlayer(sourceGUID, sourceFlags, destGUID)
    if SourceIsPlayerKillCredit(sourceGUID, sourceFlags) then return true end
    return RecentlyDamagedByPlayer(destGUID)
end

local function CoarsePlayerDamageToCreature(subevent, sourceGUID, sourceFlags, destGUID)
    if not destGUID or destGUID == "" then return false end
    if not SourceIsPlayerKillCredit(sourceGUID, sourceFlags) then return false end
    if not strfind(destGUID, "^Creature%-") and not strfind(destGUID, "^Vehicle%-") then return false end
    local s = string.upper(subevent or "")
    if strfind(s, "HEAL") or strfind(s, "MISSED") or strfind(s, "_AURA") or strfind(s, "_CAST")
        or strfind(s, "_INTERRUPT") or strfind(s, "_DISPEL") or strfind(s, "_SUMMON")
        or strfind(s, "_CREATE") or strfind(s, "_ENERGIZE") or strfind(s, "_AURADELAY")
    then
        return false
    end
    if strfind(s, "SPELL_") or strfind(s, "RANGE_") or strfind(s, "SWING_") or strfind(s, "DAMAGE") then
        return true
    end
    return false
end

local function IsGuidString(s)
    return type(s) == "string" and s ~= ""
        and (strfind(s, "^Player%-")
            or strfind(s, "^Creature%-")
            or strfind(s, "^Pet%-")
            or strfind(s, "^Vehicle%-")
            or strfind(s, "^Unit%-"))
end

local function ParseCombatLogBase()
    local t = { CombatLogGetCurrentEventInfo() }
    local timestamp = t[1]
    local subevent = t[2]
    local third = t[3]
    local sourceGUID, sourceName, sourceFlags, sourceRaidFlags
    local destGUID, destName, destFlags, destRaidFlags

    local useHideCasterSlot = type(third) == "boolean"
        or (type(third) == "number" and (third == 0 or third == 1))

    if not useHideCasterSlot and IsGuidString(third) then
        sourceGUID = t[3]
        sourceName = t[4]
        sourceFlags = t[5]
        sourceRaidFlags = t[6]
        destGUID = t[7]
        destName = t[8]
        destFlags = t[9]
        destRaidFlags = t[10]
    else
        sourceGUID = t[4]
        sourceName = t[5]
        sourceFlags = t[6]
        sourceRaidFlags = t[7]
        destGUID = t[8]
        destName = t[9]
        destFlags = t[10]
        destRaidFlags = t[11]
    end

    return timestamp, subevent, sourceGUID, sourceName, sourceFlags, sourceRaidFlags,
        destGUID, destName, destFlags, destRaidFlags
end

local function NotePlayerDamage(destGUID)
    if not destGUID or destGUID == "" then return end
    if not strfind(destGUID, "^Creature%-") and not strfind(destGUID, "^Vehicle%-") then return end
    lastPlayerDamageToGUID[destGUID] = GetTime()
end

local function TryIncrementSlayer()
    local db = addon.CharDB
    if not db.characterStarted then return false end
    if not db.activeChallenges[KEY] or db.failedChallenges[KEY] then return false end

    local c = db.slayer1KillCount or 0
    if c >= GOAL then return false end

    db.slayer1KillCount = c + 1
    addon:SlayerRefreshUI()
    local goal = GOAL
    if (db.slayer1KillCount or 0) >= goal and addon.HubTryAddCompletion then
        addon:HubTryAddCompletion(KEY)
    end
    return true
end

local function QueueKillProcessing(destGUID, sourceGUID, sourceFlags, destFlags)
    if not KillCreditToPlayer(sourceGUID, sourceFlags, destGUID) then return end
    if not destGUID or destGUID == "" or destGUID == UnitGUID("player") then return end
    if bit.band(destFlags or 0, COMBATLOG_OBJECT_TYPE_PLAYER) ~= 0 then return end
    if not strfind(destGUID, "^Creature%-") and not strfind(destGUID, "^Vehicle%-") then return end

    local dguid = destGUID

    local function attempt()
        if slayerDeathCredited[dguid] then return end
        slayerDeathCredited[dguid] = true
        if not TryIncrementSlayer() then
            slayerDeathCredited[dguid] = nil
            return
        end
        if C_Timer and C_Timer.After then
            C_Timer.After(2, function()
                slayerDeathCredited[dguid] = nil
            end)
        end
    end

    attempt()
    if C_Timer and C_Timer.After then
        for _, d in ipairs({ 0.04, 0.1, 0.18, 0.3 }) do
            C_Timer.After(d, attempt)
        end
    end
end

function addon:SlayerRefreshUI()
    if UI.selectionWindow and UI.selectionWindow._content then
        for _, child in ipairs({ UI.selectionWindow._content:GetChildren() }) do
            if child._challengeKey == KEY and child._buildBodyText then
                child._buildBodyText()
            end
        end
    end
    if UI.selectionWindow and UI.selectionWindow._updatePoints then
        UI.selectionWindow._updatePoints()
    end
    if UI.UpdateActive then
        UI:UpdateActive()
    end
end

function addon:SlayerOnEnable()
    if self._slayerLogFrame then return end

    local f = CreateFrame("Frame")
    self._slayerLogFrame = f
    f:RegisterEvent("COMBAT_LOG_EVENT_UNFILTERED")
    f:RegisterEvent("PLAYER_ENTERING_WORLD")
    f:SetScript("OnEvent", function(_, event)
        if event == "PLAYER_ENTERING_WORLD" then
            wipe(slayerDeathCredited)
            wipe(lastPlayerDamageToGUID)
            return
        end

        local _, subevent, sourceGUID, _, sourceFlags, _, destGUID, _, destFlags =
            ParseCombatLogBase()

        subevent = string.upper(subevent or "")

        if IsDamageSubevent(subevent) then
            if SourceIsPlayerKillCredit(sourceGUID, sourceFlags) and destGUID and destGUID ~= "" then
                NotePlayerDamage(destGUID)
            end
            return
        end

        if CoarsePlayerDamageToCreature(subevent, sourceGUID, sourceFlags, destGUID) then
            NotePlayerDamage(destGUID)
            return
        end

        if subevent == "UNIT_DIED" or subevent == "PARTY_KILL" then
            QueueKillProcessing(destGUID, sourceGUID, sourceFlags, destFlags)
            return
        end
    end)
end
