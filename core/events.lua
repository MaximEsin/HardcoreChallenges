-- core/events.lua
local addon = HardcoreChallenges
local UI = addon.UI

addon:RegisterEvent("PLAYER_DEAD", function()
    local db = addon.CharDB
    if db.activeChallenges["Hardcore"] then
        db.failedChallenges["Hardcore"] = true
        if UI.activeWindow then
            UI:UpdateActive()
            UI.activeWindow:Show()
        end
    end
end)

addon:RegisterEvent("BANKFRAME_OPENED", function()
    local db = addon.CharDB
    if db.activeChallenges["NoBank"] then
        CloseBankFrame()
        UIErrorsFrame:AddMessage("No Bank challenge active!", 1, 0, 0)
    end
end)