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
        - hubOnly: если true — только хаб (не в окне выбора / активных)
        - displayTitle: короткое звание для неймплейтов / тултипов (видно игрокам с аддоном)
]]
addon.Challenges = {
    ["Hardcore"] = {
        name = "Hardcore",
        displayTitle = "Hardcore",
        description = "Death = delete. If the player dies, they must not resurrect and delete the character.",
        icon = "Interface\\Icons\\ability_creature_cursed_02",
        enabledByDefault = true,
        points = 10,
    },
    ["NoBank"] = {
        name = "No Bank",
        displayTitle = "Bankless",
        description = "The player cannot use the bank. Any item remains in the inventory.",
        icon = "Interface\\Icons\\INV_Misc_Coin_01",
        enabledByDefault = false,
        points = 10,
    },
    ["NoMail"] = {
        name = "No Mail",
        displayTitle = "Unposted",
        description = "The player cannot use mailboxes or the mail interface.",
        icon = "Interface\\Icons\\INV_Letter_15",
        enabledByDefault = false,
        points = 10,
    },
    ["NoAuctionHouse"] = {
        name = "No Auction House",
        displayTitle = "Off-Market",
        description = "The player cannot use the auction house.",
        icon = "Interface\\Icons\\INV_Misc_Coin_02",
        enabledByDefault = false,
        points = 10,
    },
    ["SelfFound"] = {
        name = "Self Found",
        displayTitle = "Self-Found",
        description = "Have self found buff active until lvl 60",
        icon = "Interface\\Icons\\ui_selffound",
        enabledByDefault = false,
        points = 10,
    },
    ["SingleContinent"] = {
        name = "Single Continent",
        displayTitle = "Continental",
        description = "You may not leave the continent you have spawned on",
        icon = "Interface\\Icons\\spell_arcane_portalundercity",
        enabledByDefault = false,
        points = 30,
    },
    ["CraftedLockedSolo"] = {
        name = "Crafted Locked (Solo)",
        displayTitle = "Solo Crafter",
        description = "Start naked. You may only equip armor, weapons, and bags that you crafted yourself. Other items cannot be worn.",
        icon = "Interface\\Icons\\Trade_Engineering",
        enabledByDefault = false,
        points = 25,
    },
    ["CraftedLockedDuo"] = {
        name = "Crafted Locked (Duo)",
        displayTitle = "Duo Crafter",
        description = "Same as solo, but you may also equip gear your linked partner traded to you (both must run the addon and set each other as partners). Other looted or bought gear is never allowed.",
        icon = "Interface\\Icons\\inv_gizmo_02",
        enabledByDefault = false,
        points = 25,
    },
    ["SingleSpec"] = {
        name = "Single Spec",
        displayTitle = "Focused",
        description = "Spend talent points in only one talent tree. Any points in a second tree fails the challenge (talents unlock at level 10).",
        icon = "Interface\\Icons\\Ability_Marksmanship",
        enabledByDefault = false,
        points = 20,
    },
    ["Slayer1"] = {
        name = "Slayer",
        displayTitle = "Slayer",
        description = "Kill 10000 enemies with your character or pet (killing blow). Any creature type counts. Points apply when the goal is reached.",
        icon = "Interface\\Icons\\Ability_Warrior_IntensifyRage",
        enabledByDefault = false,
        points = 30,
    },
    ["MetaAllChallenges"] = {
        name = "All Challenges",
        displayTitle = "Paragon",
        description = "Account meta: complete every other challenge in the hub. Unlocks automatically.",
        icon = "Interface\\Icons\\Achievement_Character_Human_Male",
        enabledByDefault = false,
        points = 100,
        hubOnly = true,
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
        if challenge.hubOnly then
            -- Hub-only challenges never appear in selection / active lists.
        else
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
    end

    return result
end