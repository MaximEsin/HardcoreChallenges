-- core/init.lua

-- Инициализация аддона через AceAddon
HardcoreChallenges = LibStub("AceAddon-3.0"):NewAddon(
    "HardcoreChallenges",
    "AceEvent-3.0"
)

local addon = HardcoreChallenges
addon.UI = {}

--- Challenge pick / active UI is allowed only at character level 1.
function addon:IsChallengeConfigureLevel()
    return UnitLevel("player") == 1
end

--[[ 
    Инициализация базы данных персонажа
    - Использует AceDB-3.0
    - Хранит данные по персонажу: активные челленджи, провалы, стартовый континент, миникарта
]]
function addon:InitDB()
    local function GetCharKey()
        return UnitName("player").." - "..GetRealmName()
    end

    local charKey = GetCharKey()

    local defaults = {
        characterStarted = false,
        activeChallenges = {},
        failedChallenges = {},
        minimap = { hide = false, angle = 0 },
        startContinent = nil,
        craftedDuoPartner = "",
        craftedLockAllowedItemIds = {},
        craftedAllowedKeys = {},
        partnerGiftedKeys = {},
        slayer1KillCount = 0,
        selectedDisplayTitleKey = nil,
        dungeonOnceSeenMapIds = {},
        dungeonOnceInsideMapId = nil,
    }

    self.DB = LibStub("AceDB-3.0"):New("HardcoreChallengesDB", { profile = defaults }, false)
    self.DB:SetProfile(charKey)
    self.CharDB = self.DB.profile
end

function addon:OnInitialize()
    self:InitDB()
    self.CharDB.dungeonOnceSeenMapIds = self.CharDB.dungeonOnceSeenMapIds or {}
    self.CharDB.slayer1KillCount = self.CharDB.slayer1KillCount or 0
    if C_ChatInfo and C_ChatInfo.RegisterAddonMessagePrefix then
        C_ChatInfo.RegisterAddonMessagePrefix("HCChallenges")
    elseif RegisterAddonMessagePrefix then
        RegisterAddonMessagePrefix("HCChallenges")
    end
    if self.CraftedLockOnInitialize then
        self:CraftedLockOnInitialize()
    end
    local ver = (GetAddOnMetadata and GetAddOnMetadata("HardcoreChallenges", "Version")) or "?"
    print("|cff33ff99[Hardcore Challenges]|r v" .. tostring(ver) .. " loaded.")
end

--[[ 
    Функция: сброс данных персонажа
]]
function addon:ResetCharacter()
    local db = self.CharDB
    db.characterStarted = false
    db.activeChallenges = {}
    db.failedChallenges = {}
    db.craftedDuoPartner = ""
    db.craftedLockAllowedItemIds = {}
    db.craftedAllowedKeys = {}
    db.partnerGiftedKeys = {}
    db.craftedManualAllowKeys = {}
    db.craftedManualAllowItemIds = {}
    db._hcCraftedLockItemIdMigrated = nil
    db.slayer1KillCount = 0
    db.selectedDisplayTitleKey = nil
    db.dungeonOnceSeenMapIds = {}
    db.dungeonOnceInsideMapId = nil
    db.startContinent = nil
    db._scPewMismatchN = nil

    if self.UI.selectionWindow then
        self.UI.selectionWindow:Hide()
        self.UI.selectionWindow:SetParent(nil)
        self.UI.selectionWindow = nil
    end

    if self.UI.activeWindow then
        self.UI.activeWindow:Hide()
        self.UI.activeWindow:SetParent(nil)
        self.UI.activeWindow = nil
    end

    if self.UI.hubWindow then
        self.UI.hubWindow:Hide()
    end
end

--[[ 
    Функция: при включении аддона
    - показывает окно активных челленджей, если персонаж уже стартовал
]]
function addon:OnEnable()
    if self.CraftedLockOnEnable then
        self:CraftedLockOnEnable()
    end
    if self.SingleSpecOnEnable then
        self:SingleSpecOnEnable()
    end
    if self.SlayerOnEnable then
        self:SlayerOnEnable()
    end
    if self.HubOnEnable then
        self:HubOnEnable()
    end
    if self.TitlesOnEnable then
        self:TitlesOnEnable()
    end
    if self.RunEnteringWorldChallengeChecks then
        self:RunEnteringWorldChallengeChecks()
    end
    if self.EnsureMinimapButton then
        self:EnsureMinimapButton()
    end

    if self.CharDB.characterStarted then
        self.UI:ShowActive()
    end
end