-- core/events.lua

local addon = HardcoreChallenges
local UI = addon.UI

-- =========================
-- 🔍 HELPERS
-- =========================

--[[ 
    Проверка баффа Self Found
    Возвращает true, если есть бафф
]]
local function HasSelfFoundBuff()
    for i = 1, 40 do
        local name = UnitBuff("player", i)
        if not name then break end
        if name == "Self Found" then
            return true
        end
    end
    return false
end

--[[ 
    Получение текущего континента игрока (игнорируем инстансы)
]]
local function GetContinent()
    local mapID = C_Map.GetBestMapForUnit("player")
    if not mapID then return nil end

    local info = C_Map.GetMapInfo(mapID)
    if not info then return nil end

    if info.mapType == Enum.UIMapType.Instance then return nil end

    return info.parentMapID or mapID
end

-- =========================
-- 💀 HARDCORE (смерть = провал)
-- =========================
addon:RegisterEvent("PLAYER_DEAD", function()
    local db = addon.CharDB

    if db.activeChallenges["Hardcore"] then
        db.failedChallenges["Hardcore"] = true
        if UI.activeWindow then UI:UpdateActive() end
    end
end)

-- =========================
-- 🏦 NO BANK (закрываем банк)
-- =========================
addon:RegisterEvent("BANKFRAME_OPENED", function()
    local db = addon.CharDB
    if db.activeChallenges["NoBank"] then
        CloseBankFrame()
        UIErrorsFrame:AddMessage("No Bank challenge active!", 1, 0, 0)
    end
end)

-- =========================
-- ✉️ NO MAIL
-- =========================
addon:RegisterEvent("MAIL_SHOW", function()
    local db = addon.CharDB
    if db.activeChallenges["NoMail"] then
        CloseMail()
        UIErrorsFrame:AddMessage("No Mail challenge active!", 1, 0, 0)
    end
end)

-- =========================
-- 🏷️ NO AUCTION HOUSE
-- =========================
--[[
    AUCTION_HOUSE_SHOW часто приходит до того, как окно реально показано
    (или до появления AuctionFrame при ленивой загрузке UI), поэтому один
    вызов CloseAuctionHouse() не закрывает при первом открытии — закрываем
    на следующих тиках и дублируем через HideUIPanel, если кадр всё ещё виден.
]]
local function CloseAuctionHouseForChallenge()
    local db = addon.CharDB
    if not db.activeChallenges["NoAuctionHouse"] then return end
    CloseAuctionHouse()
    local af = _G.AuctionFrame
    if af and af:IsShown() and HideUIPanel then
        HideUIPanel(af)
    end
end

addon:RegisterEvent("AUCTION_HOUSE_SHOW", function()
    local db = addon.CharDB
    if not db.activeChallenges["NoAuctionHouse"] then return end
    UIErrorsFrame:AddMessage("No Auction House challenge active!", 1, 0, 0)
    CloseAuctionHouseForChallenge()
    if C_Timer and C_Timer.After then
        C_Timer.After(0, CloseAuctionHouseForChallenge)
        C_Timer.After(0.05, CloseAuctionHouseForChallenge)
    end
end)

-- =========================
-- 🔥 SELF FOUND
-- =========================
local function CheckSelfFound()
    local db = addon.CharDB
    if not db.activeChallenges["SelfFound"] then return end
    if db.failedChallenges["SelfFound"] then return end

    if not HasSelfFoundBuff() then
        db.failedChallenges["SelfFound"] = true
        UIErrorsFrame:AddMessage("Self Found challenge failed!", 1, 0, 0)
        if UI.activeWindow then UI:UpdateActive() end
    end
end

-- =========================
-- 🌍 SINGLE CONTINENT
-- =========================
local function CheckSingleContinent()
    local db = addon.CharDB
    if not db.activeChallenges["SingleContinent"] then return end
    if db.failedChallenges["SingleContinent"] then return end
    if not db.startContinent then return end

    local current = GetContinent()
    if not current then return end

    if current ~= db.startContinent then
        db.failedChallenges["SingleContinent"] = true
        UIErrorsFrame:AddMessage("Single Continent challenge failed!", 1, 0, 0)
        if UI.activeWindow then UI:UpdateActive() end
    end
end

-- =========================
-- 📡 EVENTS
-- =========================
addon:RegisterEvent("PLAYER_ENTERING_WORLD", function()
    CheckSelfFound()
    CheckSingleContinent()
end)

addon:RegisterEvent("UNIT_AURA", function(_, unit)
    if unit == "player" then CheckSelfFound() end
end)

addon:RegisterEvent("ZONE_CHANGED_NEW_AREA", function()
    CheckSingleContinent()
end)