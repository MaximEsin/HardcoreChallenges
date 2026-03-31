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
        description = "Do not use your Hearthstone (casting its spell fails the challenge).",
        icon = "Interface\\Icons\\INV_Misc_Rune_01",
        enabledByDefault = false,
        points = 20,
        category = "Restrictions",
    },
    ["DungeonOnce"] = {
        name = "Dungeon Once",
        displayTitle = "One Run",
        description = "Each 5-man dungeon only once. Entering the same dungeon again fails. Hub credit at level 60.",
        icon = "Interface\\Icons\\ability_warrior_shieldmastery",
        enabledByDefault = false,
        points = 10,
        category = "Progression",
    },
    ["SelfFound"] = {
        name = "Self Found",
        displayTitle = "Self-Found",
        description = "Have self found buff active until lvl 60",
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
        description = "Start naked. You may only wear gear whose item ID is on your allow list (new crafts add the ID). Any copy of that item type is allowed—the list is per item ID, not per unique item.",
        icon = "Interface\\Icons\\Trade_Engineering",
        enabledByDefault = false,
        points = 50,
        category = "Progression",
    },
    ["CraftedLockedDuo"] = {
        name = "Crafted Locked (Duo)",
        displayTitle = "Duo Crafter",
        description = "Same ID allowlist as solo. Crafts add IDs automatically. With the addon, opening trade with your saved partner merges both allowlists (union).",
        icon = "Interface\\Icons\\inv_gizmo_02",
        enabledByDefault = false,
        points = 35,
        category = "Progression",
    },
    ["SingleSpec"] = {
        name = "Single Spec",
        displayTitle = "Focused",
        description = "Spend talent points in only one talent tree. Any points in a second tree fails the challenge (talents unlock at level 10).",
        icon = "Interface\\Icons\\Ability_Marksmanship",
        enabledByDefault = false,
        points = 30,
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
        description = "Equip Tabard of the Scarlet Crusade (item 23192).",
        icon = "Interface\\Icons\\INV_Shirt_GuildTabard_01",
        enabledByDefault = false,
        points = 5,
        category = "Lore",
    },
    ["InDreams"] = {
        name = "In Dreams",
        displayTitle = "Dreamwalker",
        description = "Complete quest 'In Dreams' (quest ID 5944).",
        icon = "Interface\\Icons\\classicon_paladin",
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
        description = "Complete the Horde Onyxia chain — turn in «Blood of the Black Dragon Champion» (quest ID 6602).",
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
        description = "Complete the Alliance Onyxia chain — obtain «Drakefire Amulet» (quest ID 6502).",
        icon = "Interface\\Icons\\Achievement_Boss_Onyxia",
        enabledByDefault = false,
        points = 10,
        category = "Alliance",
    },
    ["Slayer1"] = {
        name = "Slayer",
        displayTitle = "Slayer",
        description = "Kill 10000 enemies with your character or pet (killing blow). Any creature type counts. Points apply when the goal is reached.",
        icon = "Interface\\Icons\\Ability_Warrior_IntensifyRage",
        enabledByDefault = false,
        points = 30,
        category = "Combat",
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
                category = challenge.category or "Progression",
            }
        end
    end

    return result
end
