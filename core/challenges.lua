-- core/challenges.lua

local addon = HardcoreChallenges

--[[ 
    Таблица: Все доступные челленджи
    Ключ = идентификатор челленджа
    Значения:
        - name: название
        - description: описание
        - icon: путь к иконке
        - enabledByDefault: включен ли по умолчанию
        - points: очки
]]
addon.Challenges = {
    ["Hardcore"] = {
        name = "Hardcore",
        description = "Death = delete. If the player dies, they must not resurrect and delete the character.",
        icon = "Interface\\Icons\\ability_creature_cursed_02",
        enabledByDefault = true,
        points = 10,
    },
    ["NoBank"] = {
        name = "No Bank",
        description = "The player cannot use the bank. Any item remains in the inventory.",
        icon = "Interface\\Icons\\INV_Misc_Coin_01",
        enabledByDefault = false,
        points = 10,
    },
    ["NoMail"] = {
        name = "No Mail",
        description = "The player cannot use mailboxes or the mail interface.",
        icon = "Interface\\Icons\\INV_Letter_15",
        enabledByDefault = false,
        points = 10,
    },
    ["NoAuctionHouse"] = {
        name = "No Auction House",
        description = "The player cannot use the auction house.",
        icon = "Interface\\Icons\\INV_Misc_Coin_02",
        enabledByDefault = false,
        points = 10,
    },
    ["SelfFound"] = {
        name = "Self Found",
        description = "Have self found buff active until lvl 60",
        icon = "Interface\\Icons\\ui_selffound",
        enabledByDefault = false,
        points = 10,
    },
    ["SingleContinent"] = {
        name = "Single Continent",
        description = "You may not leave the continent you have spawned on",
        icon = "Interface\\Icons\\spell_arcane_portalundercity",
        enabledByDefault = false,
        points = 30,
    },
}

--[[ 
    Функция: Получение состояния всех челленджей
    - Проверяет базу данных
    - Если челлендж не задан, берёт enabledByDefault
    - Возвращает таблицу со всеми данными (icon, name, description, enabled, points)
    Пример: local state = addon:GetChallengesState()
]]
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
            points = challenge.points or 0,
        }
    end

    return result
end