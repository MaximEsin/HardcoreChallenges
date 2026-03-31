-- core/hub.lua — account-wide completed challenges (unique keys, points summed once each).

local addon = HardcoreChallenges

function addon:HubEnsure()
    if type(HardcoreChallengesHubDB) ~= "table" then
        HardcoreChallengesHubDB = {}
    end
    if type(HardcoreChallengesHubDB.completedKeys) ~= "table" then
        HardcoreChallengesHubDB.completedKeys = {}
    end
    return HardcoreChallengesHubDB
end

local META_KEY = "MetaAllChallenges"
local EXCLUDE_FROM_AUTO_60 = {
    LordOfTheRings = true,
    ScarletTabard = true,
    InDreams = true,
    OnyxiaAttuneHorde = true,
    OnyxiaAttuneAlliance = true,
}

function addon:HubMetaChallengeKey()
    return META_KEY
end

function addon:HubAllBaseChallengesComplete()
    local hub = self:HubEnsure()
    for key in pairs(self.Challenges) do
        if key ~= META_KEY then
            if not hub.completedKeys[key] then
                return false
            end
        end
    end
    return true
end

--- Grants meta hub completion when every other challenge is in hub; no-op if not ready.
function addon:HubSyncMetaChallenge()
    if not self.Challenges[META_KEY] then return end
    local hub = self:HubEnsure()
    if hub.completedKeys[META_KEY] then return end
    if not self:HubAllBaseChallengesComplete() then return end
    hub.completedKeys[META_KEY] = true
end

function addon:HubTryAddCompletion(key)
    if not key or not self.Challenges[key] then return false end
    if self.Challenges[key].hubOnly then return false end
    local hub = self:HubEnsure()
    if hub.completedKeys[key] then return false end
    hub.completedKeys[key] = true
    self:HubSyncMetaChallenge()
    if self.UI and self.UI.RefreshHub then
        self.UI:RefreshHub()
    end
    if self.UI and self.UI.RefreshTitlesTab then
        self.UI:RefreshTitlesTab()
    end
    if self.UI and self.UI.UpdateActive then
        self.UI:UpdateActive()
    end
    return true
end

function addon:HubGetTotalPoints()
    local hub = self:HubEnsure()
    local total = 0
    for k in pairs(hub.completedKeys) do
        local c = self.Challenges[k]
        if c and c.points then
            total = total + c.points
        end
    end
    return total
end

function addon:HubReset()
    local hub = self:HubEnsure()
    wipe(hub.completedKeys)
    if self.ValidateSelectedDisplayTitle then
        self:ValidateSelectedDisplayTitle()
    end
    if self.BroadcastDisplayTitle then
        self:BroadcastDisplayTitle()
    end
    if self.UI and self.UI.RefreshHub then
        self.UI:RefreshHub()
    end
    if self.UI and self.UI.RefreshTitlesTab then
        self.UI:RefreshTitlesTab()
    end
end

-- Non-Slayer challenges: active, not failed, character started, level 60.
-- opts.newLevelHint: from PLAYER_LEVEL_UP arg; UnitLevel("player") can still be <60 in the same callback.
function addon:ProcessHubLevel60Completions(opts)
    opts = opts or {}
    local db = self.CharDB
    if not db.characterStarted then return end
    db.activeChallenges = db.activeChallenges or {}
    db.failedChallenges = db.failedChallenges or {}
    local hinted60 = type(opts.newLevelHint) == "number" and opts.newLevelHint >= 60
    if UnitLevel("player") < 60 and not hinted60 then
        return
    end

    local slayerKey = self.SlayerChallengeKey
    local faction = UnitFactionGroup("player")
    for key in pairs(self.Challenges) do
        if key ~= slayerKey and not EXCLUDE_FROM_AUTO_60[key] then
            if key == "Level60Horde" then
                if db.activeChallenges[key] and not db.failedChallenges[key] and faction == "Horde" then
                    self:HubTryAddCompletion(key)
                end
            elseif key == "Level60Alliance" then
                if db.activeChallenges[key] and not db.failedChallenges[key] and faction == "Alliance" then
                    self:HubTryAddCompletion(key)
                end
            elseif db.activeChallenges[key] and not db.failedChallenges[key] then
                self:HubTryAddCompletion(key)
            end
        end
    end
end

-- Slayer: grant account completion when kill goal reached (any character).
function addon:ProcessHubSlayerFromProgress()
    local db = self.CharDB
    if not db.characterStarted then return end
    local sk = self.SlayerChallengeKey
    if not sk or not self.Challenges[sk] then return end
    if not db.activeChallenges[sk] or db.failedChallenges[sk] then return end
    local goal = self.GetSlayerGoal and self:GetSlayerGoal() or 10000
    if (db.slayer1KillCount or 0) >= goal then
        self:HubTryAddCompletion(sk)
    end
end

function addon:SyncAccountHubFromCharacter()
    self:ProcessHubLevel60Completions()
    self:ProcessHubSlayerFromProgress()
    self:HubSyncMetaChallenge()
    if self.ValidateSelectedDisplayTitle then
        self:ValidateSelectedDisplayTitle()
    end
    if self.BroadcastDisplayTitle then
        self:BroadcastDisplayTitle()
    end
    if self.UI and self.UI.RefreshTitlesTab then
        self.UI:RefreshTitlesTab()
    end
    if self.UI and self.UI.RefreshHub and self.UI.hubWindow and self.UI.hubWindow:IsShown() then
        self.UI:RefreshHub()
    end
end

function addon:HubOnEnable()
    if self._hubEventFrame then return end
    local f = CreateFrame("Frame")
    self._hubEventFrame = f
    f:RegisterEvent("PLAYER_LEVEL_UP")
    f:RegisterEvent("PLAYER_ENTERING_WORLD")
    f:SetScript("OnEvent", function(_, event, newLevel)
        if event == "PLAYER_LEVEL_UP" then
            addon:ProcessHubLevel60Completions({ newLevelHint = newLevel })
            if C_Timer and C_Timer.After then
                C_Timer.After(0, function()
                    addon:ProcessHubLevel60Completions()
                end)
            end
            addon:ProcessHubSlayerFromProgress()
        else
            addon:SyncAccountHubFromCharacter()
        end
    end)
end
