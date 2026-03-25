local addon = HardcoreChallenges
local UI = addon.UI

-- 🔍 Проверка баффа Self Found
local function HasSelfFoundBuff()
    for i = 1, 40 do
        local name = UnitBuff("player", i)
        if not name then break end

        if name == "Self-Found Adventurer" then
            return true
        end
    end
    return false
end

-- 💀 Hardcore смерть
addon:RegisterEvent("PLAYER_DEAD", function()
    local db = addon.CharDB
    if db.activeChallenges["Hardcore"] then
        db.failedChallenges["Hardcore"] = true
        if UI.activeWindow then
            UI:UpdateActive()
        end
    end
end)

-- 🏦 Банк
addon:RegisterEvent("BANKFRAME_OPENED", function()
    local db = addon.CharDB
    if db.activeChallenges["NoBank"] then
        CloseBankFrame()
        UIErrorsFrame:AddMessage("No Bank challenge active!", 1, 0, 0)
    end
end)

-- 🔥 Self Found проверка (главное)
local function CheckSelfFound()
    local db = addon.CharDB

    if not db.activeChallenges["SelfFound"] then return end
    if db.failedChallenges["SelfFound"] then return end

    if not HasSelfFoundBuff() then
        db.failedChallenges["SelfFound"] = true

        UIErrorsFrame:AddMessage("Self Found challenge failed!", 1, 0, 0)

        if UI.activeWindow then
            UI:UpdateActive()
        end
    end
end

-- 📡 События
addon:RegisterEvent("PLAYER_ENTERING_WORLD", CheckSelfFound)
addon:RegisterEvent("UNIT_AURA", function(_, unit)
    if unit == "player" then
        CheckSelfFound()
    end
end)