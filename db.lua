local addon = HardcoreChallenges

local defaults = {
    profile = {
        characterStarted = false,
        activeChallenges = {},
        failedChallenges = {},
        minimap = {
            hide = false,
            angle = 0,
        },
    }
}

function addon:InitDB()
    self.DB = LibStub("AceDB-3.0"):New("HardcoreChallengesDB", defaults, true)
    self.CharDB = self.DB.profile
end