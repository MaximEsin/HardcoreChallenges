local addon = HardcoreChallenges
addon.UI = addon.UI or {}

function addon:GetPoints()
    local db = self.CharDB
    local total = 0

    for key, enabled in pairs(db.activeChallenges) do
        if enabled and not db.failedChallenges[key] then
            local challenge = self.Challenges[key]
            if challenge and challenge.points then
                total = total + challenge.points
            end
        end
    end

    return total
end