-- core/run_stats.lua — per-character run stats (mobs killed, quests turned in, gold acquired).

local addon = HardcoreChallenges
local UI = addon.UI

local runStatsKillGUIDs = {}
local lastMoneySnapshot

local function SyncMoneySnapshot()
    lastMoneySnapshot = GetMoney()
end

--- One NPC kill credit per destGUID per session (same dedupe window as Slayer combat log).
function addon:RunStatsTryRegisterKill(destGUID)
    local db = self.CharDB
    if not db or not db.characterStarted or not destGUID or destGUID == "" then return end
    if runStatsKillGUIDs[destGUID] then return end
    runStatsKillGUIDs[destGUID] = true
    db.statMobsKilled = (db.statMobsKilled or 0) + 1
    if UI.RefreshRunStats then
        UI:RefreshRunStats()
    end
end

function addon:RunStatsOnChallengeStart()
    local db = self.CharDB
    if not db then return end
    db.statMobsKilled = 0
    db.statQuestsCompleted = 0
    db.statGoldEarnedCopper = 0
    wipe(runStatsKillGUIDs)
    SyncMoneySnapshot()
end

function addon:RunStatsOnPlayerEnteringWorld()
    wipe(runStatsKillGUIDs)
    SyncMoneySnapshot()
end

--- Only positive deltas (loot, vendoring, quest cash); repairs/trades that reduce gold are ignored for the total.
function addon:RunStatsOnMoneyChanged()
    local db = self.CharDB
    if not db then return end
    if not db.characterStarted then
        SyncMoneySnapshot()
        return
    end
    local m = GetMoney()
    local prev = lastMoneySnapshot
    if prev == nil then
        prev = m
    end
    local delta = m - prev
    if delta > 0 then
        db.statGoldEarnedCopper = (db.statGoldEarnedCopper or 0) + delta
    end
    lastMoneySnapshot = m
    if UI.RefreshRunStats then
        UI:RefreshRunStats()
    end
end

function addon:RunStatsOnQuestTurnedIn()
    local db = self.CharDB
    if not db or not db.characterStarted then return end
    db.statQuestsCompleted = (db.statQuestsCompleted or 0) + 1
    if UI.RefreshRunStats then
        UI:RefreshRunStats()
    end
end

function addon:RunStatsOnEnable()
    SyncMoneySnapshot()
    self:RegisterEvent("PLAYER_ENTERING_WORLD", function()
        self:RunStatsOnPlayerEnteringWorld()
    end)
    local mf = CreateFrame("Frame")
    mf:SetScript("OnEvent", function()
        addon:RunStatsOnMoneyChanged()
    end)
    local ok = pcall(function()
        mf:RegisterEvent("PLAYER_MONEY_CHANGED")
    end)
    if not ok then
        pcall(function()
            mf:RegisterEvent("PLAYER_MONEY")
        end)
    end
end
