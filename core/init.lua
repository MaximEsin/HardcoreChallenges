-- db.lua

print("HardcoreChallenges: Loading DB...")

-- Глобальная база
HardcoreChallengesDB = HardcoreChallengesDB or {}

-- Получение уникального идентификатора персонажа
local function GetCharKey()
    return UnitName("player").." - "..GetRealmName()
end

-- Инициализация данных для персонажа
local charKey = GetCharKey()
HardcoreChallengesDB[charKey] = HardcoreChallengesDB[charKey] or {}

local charDB = HardcoreChallengesDB[charKey]

-- Дефолты для персонажа
local defaults = {
    characterStarted = false,
    activeChallenges = {},
    failedChallenges = {},
    minimap = { angle = 0 },
}

-- Функция применения дефолтов
local function ApplyDefaults(db, defaultsTable)
    for key, value in pairs(defaultsTable) do
        if db[key] == nil then
            db[key] = value
        end
    end
end

ApplyDefaults(charDB, defaults)

-- Возвращаем для удобства
HardcoreChallenges.CharDB = charDB

print("HardcoreChallenges: DB loaded for", charKey)