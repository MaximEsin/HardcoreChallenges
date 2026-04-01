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
        - category: строковый id секции UI (см. ui/chrome.lua CHALLENGE_CATEGORY_ORDER); без поля = Progression (Alliance / Horde — фракционные секции)
]]
addon.Challenges = {
    ["Hardcore"] = {
        name = "Hardcore",
        displayTitle = "Hardcore",
        description = "Death = delete. If the player dies, they must not resurrect and delete the character.",
        icon = "Interface\\Icons\\ability_creature_cursed_02",
        enabledByDefault = true,
        points = 10,
        category = "Restrictions",
    },
    ["NoBank"] = {
        name = "No Bank",
        displayTitle = "Bankless",
        description = "The player cannot use the bank. Any item remains in the inventory.",
        icon = "Interface\\Icons\\INV_Misc_Coin_01",
        enabledByDefault = false,
        points = 10,
        category = "Restrictions",
    },
    ["NoMail"] = {
        name = "No Mail",
        displayTitle = "Unposted",
        description = "The player cannot use mailboxes or the mail interface.",
        icon = "Interface\\Icons\\INV_Letter_15",
        enabledByDefault = false,
        points = 10,
        category = "Restrictions",
    },
    ["NoAuctionHouse"] = {
        name = "No Auction House",
        displayTitle = "Off-Market",
        description = "The player cannot use the auction house.",
        icon = "Interface\\Icons\\INV_Misc_Coin_02",
        enabledByDefault = false,
        points = 10,
        category = "Restrictions",
    },
    ["NoMount"] = {
        name = "No Mount",
        displayTitle = "Unmounted",
        description = "You must not use mounts. Mounting fails the challenge.",
        icon = "Interface\\Icons\\ability_mount_ridinghorse",
        enabledByDefault = false,
        points = 20,
        category = "Restrictions",
    },
    ["NoHearthstone"] = {
        name = "No Hearthstone",
        displayTitle = "Wayfarer",
        description = "Do not use your Hearthstone. Using it fails the challenge.",
        icon = "Interface\\Icons\\INV_Misc_Rune_01",
        enabledByDefault = false,
        points = 20,
        category = "Restrictions",
    },
    ["NoWorldBuffs"] = {
        name = "No World Buffs",
        displayTitle = "Worldbuffless",
        description = "You must not keep Rallying Cry of the Dragonslayer, Warchief's Blessing, or Spirit of Zandalar (Zul'Gurub) on your character.",
        icon = "Interface\\Icons\\spell_holy_arcaneintellect",
        enabledByDefault = false,
        points = 10,
        category = "Restrictions",
    },
    ["DungeonOnce"] = {
        name = "Dungeon Once",
        displayTitle = "One Run",
        description = "Each five-player dungeon only once. Entering the same dungeon again fails the challenge.",
        icon = "Interface\\Icons\\ability_warrior_shieldmastery",
        enabledByDefault = false,
        points = 10,
        category = "Progression",
    },
    ["SelfFound"] = {
        name = "Self Found",
        displayTitle = "Self-Found",
        description = "Keep the Self-Found adventurer buff until level 60. Losing it fails the challenge.",
        icon = "Interface\\Icons\\ui_selffound",
        enabledByDefault = false,
        points = 30,
        category = "Restrictions",
    },
    ["SingleContinent"] = {
        name = "Single Continent",
        displayTitle = "Continental",
        description = "You may not leave the continent you have spawned on",
        icon = "Interface\\Icons\\spell_arcane_portalundercity",
        enabledByDefault = false,
        points = 50,
        category = "Restrictions",
    },
    ["CraftedLockedSolo"] = {
        name = "Crafted Locked (Solo)",
        displayTitle = "Solo Crafter",
        description = "Start with no gear. You may only wear items on your allow list; eligible new crafts add themselves. Rings, neck, and trinkets are exempt—any of those may be worn.",
        icon = "Interface\\Icons\\Trade_Engineering",
        enabledByDefault = false,
        points = 50,
        category = "Progression",
    },
    ["CraftedLockedDuo"] = {
        name = "Crafted Locked (Duo)",
        displayTitle = "Duo Crafter",
        description = "Same gear rules as solo (rings, neck, and trinkets exempt). Trade once with your saved partner to merge both allow lists.",
        icon = "Interface\\Icons\\inv_gizmo_02",
        enabledByDefault = false,
        points = 35,
        category = "Progression",
    },
    ["SingleSpec"] = {
        name = "Single Spec",
        displayTitle = "Focused",
        description = "Spend talent points in only one talent tree. Any points in a second tree fails the challenge.",
        icon = "Interface\\Icons\\Ability_Marksmanship",
        enabledByDefault = false,
        points = 30,
        category = "Progression",
    },
    ["Exalted"] = {
        name = "Exalted",
        displayTitle = "Exalted",
        description = "Reach Exalted with your racial capital faction.",
        icon = "Interface\\Icons\\spell_holy_sealofwisdom",
        enabledByDefault = false,
        points = 50,
        category = "Progression",
    },
    ["LordOfTheRings"] = {
        name = "Lord of the Rings",
        displayTitle = "Ringbreaker",
        description = "Destroy The 1 ring while standing in Blackrock Mountain.",
        icon = "Interface\\Icons\\INV_Jewelry_Ring_03",
        enabledByDefault = false,
        points = 5,
        category = "Lore",
    },
    ["ScarletTabard"] = {
        name = "Scarlet Tabard",
        displayTitle = "Crusader",
        description = "Equip the Tabard of the Scarlet Crusade.",
        icon = "Interface\\Icons\\INV_Shirt_GuildTabard_01",
        enabledByDefault = false,
        points = 5,
        category = "Lore",
    },
    ["InDreams"] = {
        name = "In Dreams",
        displayTitle = "Dreamwalker",
        description = "Complete the quest «In Dreams».",
        icon = "Interface\\Icons\\classicon_paladin",
        enabledByDefault = false,
        points = 5,
        category = "Lore",
    },
    ["CorruptionEarthAndSeed"] = {
        name = "Corruption of Earth and Seed",
        displayTitle = "Earthseed",
        description = "Complete the quest «Corruption of Earth and Seed».",
        icon = "Interface\\Icons\\spell_nature_abolishmagic",
        enabledByDefault = false,
        points = 5,
        category = "Lore",
    },
    ["ScarletMonastery"] = {
        name = "Scarlet Monastery",
        displayTitle = "Scarlet",
        description = "Complete «Into The Scarlet Monastery» (Horde) or «In the Name of the Light» (Alliance).",
        icon = "Interface\\Icons\\spell_holy_sealofprotection",
        enabledByDefault = false,
        points = 5,
        category = "Lore",
    },
    ["Scholomance"] = {
        name = "Scholomance",
        displayTitle = "Darrow",
        description = "Complete the quest «The Lich, Ras Frostwhisper».",
        icon = "Interface\\Icons\\spell_shadow_raisedead",
        enabledByDefault = false,
        points = 5,
        category = "Lore",
    },
    ["Uldaman"] = {
        name = "Uldaman",
        displayTitle = "Discwarden",
        description = "Complete the quest «Seeing What Happens».",
        icon = "Interface\\Icons\\inv_misc_stonetablet_01",
        enabledByDefault = false,
        points = 5,
        category = "Lore",
    },
    ["ItsDangerousToGoAlone"] = {
        name = "It's Dangerous to Go Alone",
        displayTitle = "Linken",
        description = "Complete the quest «It's Dangerous to Go Alone».",
        icon = "Interface\\Icons\\spell_fire_firearmor",
        enabledByDefault = false,
        points = 5,
        category = "Lore",
    },
    ["Level60Horde"] = {
        name = "Horde Champion",
        displayTitle = "Horde Champion",
        description = "Reach level 60 on a Horde character.",
        icon = "Interface\\Icons\\INV_BannerPVP_01",
        enabledByDefault = false,
        points = 10,
        category = "Horde",
    },
    ["OnyxiaAttuneHorde"] = {
        name = "Onyxia Attunement (Horde)",
        displayTitle = "Black Dragon Champion",
        description = "Complete the Horde Onyxia attunement—turn in «Blood of the Black Dragon Champion».",
        icon = "Interface\\Icons\\Achievement_Boss_Onyxia",
        enabledByDefault = false,
        points = 10,
        category = "Horde",
    },
    ["Level60Alliance"] = {
        name = "Alliance Champion",
        displayTitle = "Alliance Champion",
        description = "Reach level 60 on an Alliance character.",
        icon = "Interface\\Icons\\INV_BannerPVP_02",
        enabledByDefault = false,
        points = 10,
        category = "Alliance",
    },
    ["OnyxiaAttuneAlliance"] = {
        name = "Onyxia Attunement (Alliance)",
        displayTitle = "Drakefire",
        description = "Complete the Alliance Onyxia attunement—obtain the «Drakefire Amulet».",
        icon = "Interface\\Icons\\Achievement_Boss_Onyxia",
        enabledByDefault = false,
        points = 10,
        category = "Alliance",
    },
    ["Slayer1"] = {
        name = "Slayer",
        displayTitle = "Slayer",
        description = "Kill 10000 enemies with your character or pet (killing blow). Any creature type counts.",
        icon = "Interface\\Icons\\Ability_Warrior_IntensifyRage",
        enabledByDefault = false,
        points = 30,
        category = "Combat",
    },
    ["MetaAllChallenges"] = {
        name = "All Challenges",
        displayTitle = "Paragon",
        description = "Complete every other challenge. Unlocks when you are eligible.",
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

            local desc = challenge.description
            if key == "Exalted" and self.GetExaltedChallengeDescription then
                desc = self:GetExaltedChallengeDescription()
            end

            result[key] = {
                name = challenge.name,
                description = desc,
                icon = challenge.icon,
                enabled = db.activeChallenges[key],
                points = challenge.points or 0,
                category = challenge.category or "Progression",
            }
        end
    end

    return result
end
