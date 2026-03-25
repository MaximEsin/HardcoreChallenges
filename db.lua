-- db.lua
local addonName = HardcoreChallenges
local defaults = {
    profile = {
        characterStarted = false,
        activeChallenges = {},
        failedChallenges = {},
        minimap = { hide = false, angle = 0 },
    }
}

HardcoreChallengesDB = LibStub("AceDB-3.0"):New("HardcoreChallengesDB", defaults, true)
HardcoreChallenges.CharDB = HardcoreChallengesDB.profile

print("HardcoreChallenges: DB loaded via AceDB")