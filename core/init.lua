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
        slayer1KillCount = 0,
        debugFakeLevel60 = false,
        selectedDisplayTitleKey = nil,
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
    self.CharDB.slayer1KillCount = self.CharDB.slayer1KillCount or 0
    if self.CharDB.debugFakeLevel60 == nil then
        self.CharDB.debugFakeLevel60 = false
    end
    if C_ChatInfo and C_ChatInfo.RegisterAddonMessagePrefix then
        C_ChatInfo.RegisterAddonMessagePrefix("HCChallenges")
    elseif RegisterAddonMessagePrefix then
        RegisterAddonMessagePrefix("HCChallenges")
    end
    self:RegisterChatCommand("hc", "HandleSlash")
    if self.CraftedLockOnInitialize then
        self:CraftedLockOnInitialize()
    end
end

--[[ 
    Функция: обработка команды /hc
]]
local function strtrim(s)
    return (s or ""):gsub("^%s+", ""):gsub("%s+$", "")
end

function addon:HandleSlash(input)
    local raw = strtrim(input or "")
    if raw == "" then
        print("|cFFFFCC00[HC]|r Commands:")
        print("/hc reset — reset current character data")
        print("/hc hub — open Account Hub")
        print("/hc hubreset — reset account hub (all chars)")
        print("/hc debug60 — treat as level 60 for hub (debug)")
        print("/hc debug60reset — clear debug 60 flag")
        print("/hc debugslayer — set Slayer progress to goal and grant hub completion (debug)")
        print("/hc minimap — show minimap button if it was hidden")
        print("/hc titlesdebug — debug display titles / addon messages")
        return
    end

    local cmd, _ = strsplit(" ", raw, 2)
    cmd = strlower(cmd or "")

    if cmd == "reset" then
        self:ResetCharacter()
    elseif cmd == "hub" then
        self.UI:ShowHub()
    elseif cmd == "hubreset" then
        self:HubReset()
    elseif cmd == "debug60" then
        self.CharDB.debugFakeLevel60 = true
        self:SyncAccountHubFromCharacter()
        print("|cFF00FF00[HC]|r Debug: hub treats this character as level 60.")
    elseif cmd == "debug60reset" then
        self.CharDB.debugFakeLevel60 = false
        print("|cFF00FF00[HC]|r Debug level 60 flag cleared.")
    elseif cmd == "debugslayer" then
        local sk = self.SlayerChallengeKey or "Slayer1"
        local goal = self.GetSlayerGoal and self:GetSlayerGoal() or 10000
        self.CharDB.slayer1KillCount = goal
        if self.HubTryAddCompletion then
            self:HubTryAddCompletion(sk)
        end
        if self.SlayerRefreshUI then
            self:SlayerRefreshUI()
        end
        print("|cFF00FF00[HC]|r Debug: Slayer at " .. goal .. " kills; hub completion applied if not already present.")
    elseif cmd == "minimap" then
        local mm = self.CharDB.minimap
        if type(mm) ~= "table" then
            self.CharDB.minimap = { hide = false, angle = 0 }
        else
            mm.hide = false
        end
        local LDBIcon = LibStub("LibDBIcon-1.0", true)
        if LDBIcon and LDBIcon.Show then
            LDBIcon:Show("HardcoreChallenges")
        end
        print("|cFF00FF00[HC]|r Minimap button should be visible (reload UI if not).")
    elseif cmd == "titlesdebug" then
        print("|cFFFFCC00[HC]|r Titles debug:")
        print("  selected key:", tostring(self.GetSelectedDisplayTitleKey and self:GetSelectedDisplayTitleKey()))
        print("  broadcast payload:", tostring(self.GetBroadcastTitlePayload and self:GetBroadcastTitlePayload()))
        local n = 0
        if self.remoteTitleKeys then
            for _ in pairs(self.remoteTitleKeys) do
                n = n + 1
            end
        end
        print("  remote cache entries:", n)
        if UnitExists("target") and UnitIsPlayer("target") then
            print("  target full:", tostring(GetUnitName("target", true)))
            print("  target short:", tostring(UnitName("target")))
            print("  effective title key:", tostring(self.GetEffectiveDisplayTitleKeyForUnit and self:GetEffectiveDisplayTitleKeyForUnit("target")))
            local t = self.GetDisplayTitleForKey and self:GetDisplayTitleForKey(
                self.GetEffectiveDisplayTitleKeyForUnit and self:GetEffectiveDisplayTitleKeyForUnit("target")
            )
            print("  display text:", tostring(t))
        else
            print("  (no player target — target someone to test lookup)")
        end
        print("  Tip: same guild/party or target + whisper Q must deliver HCChallenges messages.")
    else
        print("|cFFFFCC00[HC]|r Unknown command. Use /hc for help.")
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
    db.slayer1KillCount = 0
    db.debugFakeLevel60 = false
    db.selectedDisplayTitleKey = nil

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

    print("|cFFFF0000[Hardcore Challenges]|r addon loaded!")
end