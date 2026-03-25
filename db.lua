-- db.lua

print("HardcoreChallenges: Loading DB...")

-- Создаем базу если ее нет
HardcoreChallengesDB = HardcoreChallengesDB or {}

-- Значения по умолчанию
local defaults = {
    characterStarted = false, -- выбрал ли игрок челленджи
    activeChallenges = {},    -- активные челленджи
    failedChallenges = {},    -- проваленные челленджи
    minimap = { angle = 0 },  -- угол кнопки миникарты
}

-- Применяем дефолты
local function ApplyDefaults(db, defaultsTable)
    for key, value in pairs(defaultsTable) do
        if db[key] == nil then
            db[key] = value
        end
    end
end

ApplyDefaults(HardcoreChallengesDB, defaults)

print("HardcoreChallenges: DB loaded")
print("Current DB:", HardcoreChallengesDB)

-- 🔄 Ресет аддона (для дебага)
SLASH_HCRESET1 = "/hcr"
SlashCmdList["HCRESET"] = function()
    print("HardcoreChallenges: Resetting DB...")
    HardcoreChallengesDB = {}
    ApplyDefaults(HardcoreChallengesDB, defaults)
    print("HardcoreChallenges: DB reset")
    -- Перезагрузка UI для теста
    ReloadUI()
end