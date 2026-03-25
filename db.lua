-- core/db.lua
local addon = HardcoreChallenges

-- Для совместимости, оставляем функции доступа
function addon:GetCharDB()
    return self.CharDB
end