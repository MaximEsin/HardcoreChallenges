HardcoreChallenges:RegisterEvent("PLAYER_DEAD", function()
    local db = HardcoreChallenges.CharDB
    if db.activeChallenges["Hardcore"] then
        print("HardcoreChallenges: Hardcore failed!")
        db.failedChallenges["Hardcore"] = true
        if HardcoreChallengesActiveUI then
            HardcoreChallengesActiveUI:Update()
            HardcoreChallengesActiveUI:Show()
        end
    end
end)

HardcoreChallenges:RegisterEvent("BANKFRAME_OPENED", function()
    local db = HardcoreChallenges.CharDB
    if db.activeChallenges["NoBank"] then
        print("HardcoreChallenges: No Bank active — closing bank!")
        CloseBankFrame()
        UIErrorsFrame:AddMessage("No Bank challenge active!", 1, 0, 0)
    end
end)