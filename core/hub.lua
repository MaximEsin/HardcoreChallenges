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
    print("|cFFFFCC00[HC]|r Account hub cleared.")
end

-- Non-Slayer challenges: active, not failed, character started, level 60 (or debug flag).
function addon:ProcessHubLevel60Completions()
    local db = self.CharDB
    if not db.characterStarted then return end
    if UnitLevel("player") < 60 and not db.debugFakeLevel60 then return end

    local slayerKey = self.SlayerChallengeKey
    for key in pairs(self.Challenges) do
        if key ~= slayerKey then
            if db.activeChallenges[key] and not db.failedChallenges[key] then
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
            if type(newLevel) == "number" and newLevel >= 60 then
                addon:ProcessHubLevel60Completions()
            end
            addon:ProcessHubSlayerFromProgress()
        else
            addon:SyncAccountHubFromCharacter()
        end
    end)
end
