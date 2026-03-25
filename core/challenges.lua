local addon = HardcoreChallenges

addon.Challenges = {
    ["Hardcore"] = {
        name = "Hardcore",
        description = "Death = delete. If the player dies, they must not resurrect.",
        icon = "Interface\\Icons\\ability_creature_cursed_02",
        enabledByDefault = true,
    },
    ["NoBank"] = {
        name = "No Bank",
        description = "The player cannot use the bank.",
        icon = "Interface\\Icons\\INV_Misc_Coin_01",
        enabledByDefault = false,
    },
}

function addon:GetChallengesState()
    local db = self.CharDB
    db.activeChallenges = db.activeChallenges or {}

    local result = {}

    for key, challenge in pairs(self.Challenges) do
        if db.activeChallenges[key] == nil then
            db.activeChallenges[key] = challenge.enabledByDefault
        end

        result[key] = {
            name = challenge.name,
            description = challenge.description,
            icon = challenge.icon,
            enabled = db.activeChallenges[key],
        }
    end

    return result
end