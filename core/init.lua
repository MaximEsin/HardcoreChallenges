-- core/init.lua

-- Инициализация аддона через AceAddon
HardcoreChallenges = LibStub("AceAddon-3.0"):NewAddon(
    "HardcoreChallenges",
    "AceEvent-3.0",
    "AceConsole-3.0"
)

local addon = HardcoreChallenges
addon.UI = {}

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
        craftedAllowedKeys = {},
        partnerGiftedKeys = {},
    }

    self.DB = LibStub("AceDB-3.0"):New("HardcoreChallengesDB", { profile = defaults }, false)
    self.DB:SetProfile(charKey)
    self.CharDB = self.DB.profile
end

--[[ 
    Функция: инициализация аддона
    - вызывается при загрузке
    - регистрирует slash-команду /hc
]]
function addon:OnInitialize()
    self:InitDB()
    self:RegisterChatCommand("hc", "HandleSlash")
    if self.CraftedLockOnInitialize then
        self:CraftedLockOnInitialize()
    end
end

--[[ 
    Функция: обработка команды /hc
]]
function addon:HandleSlash(input)
    if input == "reset" then
        self:ResetCharacter()
    else
        print("|cFFFF0000[HC]|r Commands:")
        print("/hc reset - reset current character data")
    end
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
    db.craftedAllowedKeys = {}
    db.partnerGiftedKeys = {}

    print("|cFFFF0000[Hardcore Challenges]|r Character data reset!")

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

    if self.CharDB.characterStarted then
        self.UI:ShowActive()
    end

    print("|cFFFF0000[Hardcore Challenges]|r addon loaded!")
end