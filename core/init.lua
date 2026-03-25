local addon = HardcoreChallenges

function addon:Init()
    if self.state.initialized then
        print("HardcoreChallenges: Already initialized")
        return
    end

    print("HardcoreChallenges: Initializing...")
    self.state.initialized = true

    -- Проверяем DB
    if not HardcoreChallengesDB then
        print("Warning: HardcoreChallengesDB is nil!")
    else
        print("HardcoreChallengesDB OK")
    end

    -- Регистрируем событие
    self:RegisterEvent("PLAYER_LOGIN", function()
        addon:OnPlayerLogin()
    end)

    print("HardcoreChallenges: Init done")
end

function addon:OnPlayerLogin()
    print("HardcoreChallenges: PLAYER_LOGIN triggered")
    self.state.playerLoaded = true

    if not HardcoreChallengesDB.characterStarted then
        print("HardcoreChallenges: First launch detected")
        self:ShowFirstLaunchUI()
    else
        print("HardcoreChallenges: Character already started")
    end
end

function addon:ShowFirstLaunchUI()
    if HardcoreChallengesUI then
        print("HardcoreChallenges: Showing main UI")
        HardcoreChallengesUI:Show()
    else
        print("HardcoreChallenges: HardcoreChallengesUI is nil!")
    end
end

addon:Init()