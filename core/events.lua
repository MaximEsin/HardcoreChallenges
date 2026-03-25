local addon = HardcoreChallenges

function addon:OnEnable()
    self:RegisterEvent("PLAYER_DEAD")
    self:RegisterEvent("BANKFRAME_OPENED")
end

function addon:PLAYER_DEAD()
    local db = self.CharDB

    if db.activeChallenges["Hardcore"] then
        db.failedChallenges["Hardcore"] = true

        if self.UI and self.UI.activeWindow then
            self.UI:UpdateActive()
            self.UI.activeWindow:Show()
        end
    end
end

function addon:BANKFRAME_OPENED()
    local db = self.CharDB

    if db.activeChallenges["NoBank"] then
        CloseBankFrame()
        UIErrorsFrame:AddMessage("No Bank challenge active!", 1, 0, 0)
    end
end