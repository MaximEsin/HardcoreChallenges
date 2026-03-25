HardcoreChallenges.Challenges = {
    ["Hardcore"] = {
        name = "Hardcore",
        description = "Death = delete. Если персонаж умирает — прогресс будет потерян.",
        icon = "Interface\\Icons\\ability_creature_cursed_02", -- тут можно заменить на иконку
        enabledByDefault = true,
    },
    ["NoBank"] = {
        name = "No Bank",
        description = "Игрок не может использовать банк. Любой предмет оставляем в инвентаре.",
        icon = "Interface\\Icons\\INV_Misc_Coin_01",
        enabledByDefault = false,
    },
}

function HardcoreChallenges:GetChallengesState()
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