-- core/state.lua

local addon = HardcoreChallenges
addon.UI = addon.UI or {}

--[[ 
    Функция: Получение общего количества очков
    - Суммирует points всех активных челленджей, которые не провалены
    Пример: local total = addon:GetPoints()
]]
function addon:GetPoints()
    local db = self.CharDB
    local total = 0

    for key, enabled in pairs(db.activeChallenges) do
        if enabled and not db.failedChallenges[key] then
            local challenge = self.Challenges[key]
            if challenge and challenge.points then
                if self.SlayerChallengeKey and key == self.SlayerChallengeKey then
                    local n = db.slayer1KillCount or 0
                    if n >= (self.GetSlayerGoal and self:GetSlayerGoal() or 10000) then
                        total = total + challenge.points
                    end
                else
                    total = total + challenge.points
                end
            end
        end
    end

    return total
end

--[[ 
    Функция: Получение имени континента по mapID
    Возвращает "Unknown", если info отсутствует
    Пример: local name = addon:GetContinentName(mapID)
]]
function addon:GetContinentName(mapID)
    if not mapID then return "Unknown" end

    local info = C_Map.GetMapInfo(mapID)
    if not info then return "Unknown" end

    return info.name or "Unknown"
end

--- Walk map parents to a stable root (continent or top-level map). Fixes mismatches when
--- start saved one parent id and login resolves another layer of the same landmass.
function addon:ResolveContinentRootMapId(mapID)
    if not mapID or mapID == 0 then return nil end
    local cur = mapID
    local seen = {}
    while cur and cur ~= 0 and not seen[cur] do
        seen[cur] = true
        local info = C_Map.GetMapInfo(cur)
        if not info then
            return cur
        end
        if Enum.UIMapType and info.mapType == Enum.UIMapType.Continent then
            return cur
        end
        local p = info.parentMapID
        if not p or p == 0 then
            return cur
        end
        cur = p
    end
    return cur
end

--- Open-world continent root for the player (nil in instances / while map not ready).
function addon:GetPlayerContinentMapId()
    local mapID = C_Map.GetBestMapForUnit("player")
    if not mapID then return nil end
    local info = C_Map.GetMapInfo(mapID)
    if not info then return nil end
    if Enum.UIMapType and info.mapType == Enum.UIMapType.Instance then
        return nil
    end
    return self:ResolveContinentRootMapId(mapID)
end