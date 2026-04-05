-- core/exalted.lua — Exalted: reach Exalted with your race's home-city faction.

local addon = HardcoreChallenges

local EXALTED_KEY = "Exalted"
local STANDING_EXALTED = 8

--- raceFile from UnitRace (second return), Classic / Wrath client tokens.
local RACE_FILE_TO_FACTION_ID = {
    Human = 72,
    Dwarf = 47,
    NightElf = 69,
    Gnome = 54,
    Orc = 76,
    Scourge = 68,
    Tauren = 81,
    Troll = 530,
    BloodElf = 911,
    Draenei = 930,
}

--- English fallback names if GetFactionInfoByID does not return a name yet.
local FACTION_ID_FALLBACK_NAME = {
    [72] = "Stormwind",
    [47] = "Ironforge",
    [69] = "Darnassus",
    [54] = "Gnomeregan Exiles",
    [76] = "Orgrimmar",
    [68] = "Undercity",
    [81] = "Thunder Bluff",
    [530] = "Darkspear Trolls",
    [911] = "Silvermoon City",
    [930] = "Exodar",
}

function addon:GetRacialCapitalFactionId()
    local _, raceFile = UnitRace("player")
    if not raceFile then return nil end
    return RACE_FILE_TO_FACTION_ID[raceFile]
end

function addon:GetExaltedChallengeFactionDisplayName()
    local id = self:GetRacialCapitalFactionId()
    if not id then return nil end
    if GetFactionInfoByID then
        local ok, name = pcall(function()
            return (select(1, GetFactionInfoByID(id)))
        end)
        if ok and name and name ~= "" and name ~= "Unknown" then
            return name
        end
    end
    return FACTION_ID_FALLBACK_NAME[id]
end

function addon:GetExaltedChallengeDescription()
    local nm = self:GetExaltedChallengeFactionDisplayName()
    if nm then
        return "Reach Exalted with " .. nm .. "."
    end
    return "Reach Exalted with your racial capital faction."
end

--- Any return of GetFactionInfo(i) equal to factionId counts as that row (IDs do not overlap standing 1–8).
local function StandingIdFromOpenFactionList(factionId)
    local n = GetNumFactions and GetNumFactions() or 0
    for i = 1, n do
        local t = { GetFactionInfo(i) }
        if not t[9] and t[11] then
            for idx = 1, #t do
                if t[idx] == factionId then
                    return t[3]
                end
            end
        end
    end
    return nil
end

local function IsFactionExaltedByFactionId(factionId)
    if not factionId then return false end
    if GetFactionInfoByID then
        local ok, standingId = pcall(function()
            return (select(3, GetFactionInfoByID(factionId)))
        end)
        if ok and type(standingId) == "number" and standingId >= STANDING_EXALTED then
            return true
        end
    end
    local standingFromList = StandingIdFromOpenFactionList(factionId)
    return type(standingFromList) == "number" and standingFromList >= STANDING_EXALTED
end

function addon:CheckExaltedChallenge()
    local db = self.CharDB
    if not db.characterStarted then return end
    if not db.activeChallenges[EXALTED_KEY] or db.failedChallenges[EXALTED_KEY] then return end
    local id = self:GetRacialCapitalFactionId()
    if not id then return end
    if not IsFactionExaltedByFactionId(id) then return end
    local granted = self:HubTryAddCompletion(EXALTED_KEY)
    if granted then
        UIErrorsFrame:AddMessage("Exalted challenge complete!", 0, 1, 0)
    end
    local UI = self.UI
    if UI and UI.UpdateActive then
        UI:UpdateActive()
    end
end

if not addon._hcExaltedEventFrame then
    local f = CreateFrame("Frame")
    addon._hcExaltedEventFrame = f
    -- Classic Era: UPDATE_FACTION (retail uses FACTION_UPDATE, which is invalid here).
    f:RegisterEvent("UPDATE_FACTION")
    f:RegisterEvent("CHAT_MSG_COMBAT_FACTION_CHANGE")
    f:SetScript("OnEvent", function()
        addon:CheckExaltedChallenge()
    end)
end
