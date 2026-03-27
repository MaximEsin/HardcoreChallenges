-- core/events.lua

local addon = HardcoreChallenges
local UI = addon.UI

-- =========================
-- 🔍 HELPERS
-- =========================

--[[
    Официальный баф Self-Found в клиенте — «Self-Found Adventurer» (не «Self Found»).
    Проверяем по spellId, чтобы не зависеть от локали и точной строки имени.
]]
local SELF_FOUND_SPELL_ID = 431567
local LOTR_KEY = "LordOfTheRings"
local LOTR_RING_ITEM_ID = 8350
local lastKnownRingCount = 0
local GetSubZoneTextSafe = _G.GetSubZoneText
local GetRealZoneTextSafe = _G.GetRealZoneText
local GetZoneTextSafe = _G.GetZoneText
local NUM_BAG_SLOTS_SAFE = _G.NUM_BAG_SLOTS or 4
local GetContainerNumSlotsLegacy = _G.GetContainerNumSlots
local GetContainerItemInfoLegacy = _G.GetContainerItemInfo
local GetContainerItemLinkLegacy = _G.GetContainerItemLink

function addon:HasSelfFoundBuff()
    if C_UnitAuras and C_UnitAuras.GetPlayerAuraBySpellID then
        local d = C_UnitAuras.GetPlayerAuraBySpellID(SELF_FOUND_SPELL_ID)
        if d then return true end
    end
    for i = 1, 40 do
        local name, _, _, _, _, _, _, _, _, _, spellId = UnitBuff("player", i)
        if not name then break end
        if spellId == SELF_FOUND_SPELL_ID then
            return true
        end
        if name == "Self Found" or name == "Self-Found Adventurer" then
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

local function IsBlackrockMountain()
    local function hasName(s)
        if not s or s == "" then return false end
        local low = strlower(s)
        if strfind(low, "blackrock mountain", 1, true) then return true end
        if strfind(low, "blackrock", 1, true) then return true end
        return false
    end

    if hasName(GetSubZoneTextSafe and GetSubZoneTextSafe()) or hasName(GetRealZoneTextSafe and GetRealZoneTextSafe())
        or hasName(GetZoneTextSafe and GetZoneTextSafe())
    then
        return true
    end

    local mapID = C_Map.GetBestMapForUnit("player")
    while mapID do
        local info = C_Map.GetMapInfo(mapID)
        if not info then break end
        if hasName(info.name) then
            return true
        end
        if not info.parentMapID or info.parentMapID == 0 then break end
        mapID = info.parentMapID
    end
    return false
end

local function GetItemIdFromLink(link)
    if not link or link == "" then return nil end
    local itemString = strmatch(link, "item[%-:](%d+)")
    local id = itemString and tonumber(itemString)
    if id and id > 0 then
        return id
    end
    return nil
end

local function GetRingCountInBags()
    local total = 0
    local maxBag = NUM_BAG_SLOTS_SAFE
    for bag = 0, maxBag do
        local slots
        if C_Container and C_Container.GetContainerNumSlots then
            slots = C_Container.GetContainerNumSlots(bag)
        elseif GetContainerNumSlotsLegacy then
            slots = GetContainerNumSlotsLegacy(bag)
        else
            slots = 0
        end
        for slot = 1, (slots or 0) do
            local itemInfo = C_Container and C_Container.GetContainerItemInfo and C_Container.GetContainerItemInfo(bag, slot)
            if itemInfo then
                local link = C_Container.GetContainerItemLink and C_Container.GetContainerItemLink(bag, slot)
                local itemID = (itemInfo.itemID and tonumber(itemInfo.itemID)) or GetItemIdFromLink(link)
                if itemID == LOTR_RING_ITEM_ID then
                    total = total + (itemInfo.stackCount or 1)
                end
            else
                local texture, count
                if GetContainerItemInfoLegacy then
                    texture, count = GetContainerItemInfoLegacy(bag, slot)
                end
                if texture then
                    local link
                    if GetContainerItemLinkLegacy then
                        link = GetContainerItemLinkLegacy(bag, slot)
                    end
                    local itemID = GetItemIdFromLink(link)
                    if itemID == LOTR_RING_ITEM_ID then
                        total = total + (count or 1)
                    end
                end
            end
        end
    end
    return total
end

local function CheckLordOfTheRingsFromBags(isInit)
    local db = addon.CharDB
    if not db.characterStarted then
        lastKnownRingCount = GetRingCountInBags()
        return
    end
    if not db.activeChallenges[LOTR_KEY] or db.failedChallenges[LOTR_KEY] then
        lastKnownRingCount = GetRingCountInBags()
        return
    end

    local cur = GetRingCountInBags()
    local prev = lastKnownRingCount or cur
    lastKnownRingCount = cur
    if isInit then return end

    if prev > cur and cur == 0 and IsBlackrockMountain() then
        addon:HubTryAddCompletion(LOTR_KEY)
        if UI and UI.UpdateActive then
            UI:UpdateActive()
        end
        UIErrorsFrame:AddMessage("Lord of the Rings challenge complete!", 0, 1, 0)
    end
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

    if not addon:HasSelfFoundBuff() then
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
-- PEW регистрируется в core/titles.lua (AceEvent: один обработчик PLAYER_ENTERING_WORLD на аддон).
function addon:RunEnteringWorldChallengeChecks()
    local function run()
        CheckSelfFound()
        CheckSingleContinent()
        CheckLordOfTheRingsFromBags(true)
    end
    run()
    if C_Timer and C_Timer.After then
        C_Timer.After(0, run)
    end
end

addon:RegisterEvent("UNIT_AURA", function(_, unit)
    if unit == "player" then CheckSelfFound() end
end)

addon:RegisterEvent("ZONE_CHANGED_NEW_AREA", function()
    CheckSingleContinent()
end)

addon:RegisterEvent("BAG_UPDATE_DELAYED", function()
    CheckLordOfTheRingsFromBags(false)
end)