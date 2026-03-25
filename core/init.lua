-- core/init.lua
HardcoreChallenges = LibStub("AceAddon-3.0"):NewAddon(
    "HardcoreChallenges",
    "AceEvent-3.0",
    "AceConsole-3.0"
)

local addon = HardcoreChallenges
addon.UI = {}

-- Инициализация базы данных для текущего персонажа
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
    }

    -- Создаём AceDB без shared профиля
    self.DB = LibStub("AceDB-3.0"):New("HardcoreChallengesDB", { profile = defaults }, false)
    self.DB:SetProfile(charKey)
    self.CharDB = self.DB.profile
end

function addon:OnInitialize()
    self:InitDB()
end

function addon:OnEnable()
    -- Подключаем миникарту
    if self.CharDB.characterStarted then
        self.UI:ShowActive()
    end

    print("|cFFFF0000[Hardcore Challenges]|r addon loaded!")
end