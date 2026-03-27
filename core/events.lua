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
local SCARLET_TABARD_KEY = "ScarletTabard"
local SCARLET_TABARD_ITEM_ID = 23192
local NO_MOUNT_KEY = "NoMount"
local NO_HEARTHSTONE_KEY = "NoHearthstone"
local DUNGEON_ONCE_KEY = "DungeonOnce"
-- Classic: Hearthstone (item) cast spell
local HEARTHSTONE_SPELL_ID = 8690
local lastKnownRingCount = 0
local dungeonOnceDebounce
local GetSubZoneTextSafe = _G.GetSubZoneText
local GetRealZoneTextSafe = _G.GetRealZoneText
local GetZoneTextSafe = _G.GetZoneText
local NUM_BAG_SLOTS_SAFE = _G.NUM_BAG_SLOTS or 4
local GetContainerNumSlotsLegacy = _G.GetContainerNumSlots
local GetContainerItemInfoLegacy = _G.GetContainerItemInfo
local GetContainerItemLinkLegacy = _G.GetContainerItemLink
local IsMountedSafe = _G.IsMounted
local IsInInstanceSafe = _G.IsInInstance
local GetInstanceInfoSafe = _G.GetInstanceInfo
local INVSLOT_TABARD_SAFE = _G.INVSLOT_TABARD or 19
local IsQuestFlaggedCompletedSafe = _G.IsQuestFlaggedCompleted
local C_QuestLogSafe = _G.C_QuestLog

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

local function GetContinent()
    return addon:GetPlayerContinentMapId()
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

local function CheckScarletTabardChallenge()
    local db = addon.CharDB
    if not db.characterStarted then return end
    if not db.activeChallenges[SCARLET_TABARD_KEY] or db.failedChallenges[SCARLET_TABARD_KEY] then return end
    local tabardSlot = INVSLOT_TABARD_SAFE
    local link = GetInventoryItemLink("player", tabardSlot)
    local itemID = GetItemIdFromLink(link)
    if itemID ~= SCARLET_TABARD_ITEM_ID then return end
    addon:HubTryAddCompletion(SCARLET_TABARD_KEY)
    if UI and UI.UpdateActive then
        UI:UpdateActive()
    end
    UIErrorsFrame:AddMessage("Scarlet Tabard challenge complete!", 0, 1, 0)
end

local function IsQuestCompletedById(questId)
    if not questId then return false end
    if C_QuestLogSafe and C_QuestLogSafe.IsQuestFlaggedCompleted then
        local ok, done = pcall(C_QuestLogSafe.IsQuestFlaggedCompleted, questId)
        if ok and done then return true end
    end
    if IsQuestFlaggedCompletedSafe then
        local ok, done = pcall(IsQuestFlaggedCompletedSafe, questId)
        if ok and done then return true end
    end
    return false
end

--- Квесты → зачёт в хаб (не на 60): turnedInQuestId = nil при PEW, иначе id квеста из QUEST_TURNED_IN.
local QUEST_HUB_CHALLENGES = {
    { key = "InDreams", questId = 5944, msg = "In Dreams challenge complete!" },
    { key = "OnyxiaAttuneHorde", questId = 6602, msg = "Onyxia Attunement (Horde) complete!" },
    { key = "OnyxiaAttuneAlliance", questId = 6502, msg = "Onyxia Attunement (Alliance) complete!" },
}

local function CheckQuestHubChallenges(turnedInQuestId)
    local db = addon.CharDB
    if not db.characterStarted then return end
    local turned = turnedInQuestId and tonumber(turnedInQuestId) or nil
    for _, row in ipairs(QUEST_HUB_CHALLENGES) do
        if db.activeChallenges[row.key] and not db.failedChallenges[row.key] then
            local done = (turned and turned == row.questId) or (not turned and IsQuestCompletedById(row.questId))
            if done then
                local granted = addon:HubTryAddCompletion(row.key)
                if granted then
                    UIErrorsFrame:AddMessage(row.msg, 0, 1, 0)
                end
            end
        end
    end
end

local function InstanceTypeIsPartyDungeon(instanceType)
    if instanceType == nil then return false end
    if type(instanceType) == "number" then
        return instanceType == 1
    end
    if type(instanceType) == "string" then
        return strlower(instanceType) == "party"
    end
    return false
end

local function ScheduleDungeonOnceCheck()
    local function run()
        local db = addon.CharDB
        if not db.characterStarted then return end
        if not db.activeChallenges[DUNGEON_ONCE_KEY] or db.failedChallenges[DUNGEON_ONCE_KEY] then return end

        local instPack = IsInInstanceSafe and { IsInInstanceSafe() } or {}
        local inInst = instPack[1]
        local instanceType = instPack[2]
        if not inInst or not InstanceTypeIsPartyDungeon(instanceType) then
            db.dungeonOnceInsideMapId = nil
            return
        end

        local instanceMapId = select(8, GetInstanceInfoSafe and GetInstanceInfoSafe())
        local mapID = (instanceMapId and instanceMapId > 0) and instanceMapId
            or (C_Map and C_Map.GetBestMapForUnit and C_Map.GetBestMapForUnit("player"))
        if not mapID then return end

        if db.dungeonOnceInsideMapId == mapID then
            return
        end

        db.dungeonOnceSeenMapIds = db.dungeonOnceSeenMapIds or {}
        if db.dungeonOnceSeenMapIds[mapID] then
            db.failedChallenges[DUNGEON_ONCE_KEY] = true
            UIErrorsFrame:AddMessage("Dungeon Once challenge failed (re-entered a dungeon)!", 1, 0, 0)
            if UI.activeWindow then UI:UpdateActive() end
            return
        end
        db.dungeonOnceSeenMapIds[mapID] = true
        db.dungeonOnceInsideMapId = mapID
    end

    if C_Timer and C_Timer.NewTimer then
        if dungeonOnceDebounce and dungeonOnceDebounce.Cancel then
            dungeonOnceDebounce:Cancel()
        end
        dungeonOnceDebounce = C_Timer.NewTimer(0.45, function()
            dungeonOnceDebounce = nil
            run()
        end)
    else
        run()
    end
end

local function CheckNoMountChallenge()
    local db = addon.CharDB
    if not db.characterStarted then return end
    if not db.activeChallenges[NO_MOUNT_KEY] or db.failedChallenges[NO_MOUNT_KEY] then return end
    if IsMountedSafe and IsMountedSafe() then
        db.failedChallenges[NO_MOUNT_KEY] = true
        UIErrorsFrame:AddMessage("No Mount challenge failed!", 1, 0, 0)
        if UI.activeWindow then UI:UpdateActive() end
    end
end

local noMountPollAccum = 0
if not addon._hcNoMountPollFrame then
    local f = CreateFrame("Frame")
    addon._hcNoMountPollFrame = f
    f:SetScript("OnUpdate", function(_, elapsed)
        local db = addon.CharDB
        if not db.characterStarted or not db.activeChallenges[NO_MOUNT_KEY] or db.failedChallenges[NO_MOUNT_KEY] then
            return
        end
        noMountPollAccum = noMountPollAccum + (elapsed or 0)
        if noMountPollAccum < 0.35 then return end
        noMountPollAccum = 0
        CheckNoMountChallenge()
    end)
end

-- UNIT_SPELLCAST_* через отдельный фрейм: AceEvent допускает один обработчик на событие на аддон
-- (иначе перезапишем UNIT_SPELLCAST_SUCCEEDED из Crafted Lock).
if not addon._hcMiscEventsFrame then
    local mf = CreateFrame("Frame")
    addon._hcMiscEventsFrame = mf
    mf:RegisterEvent("UNIT_SPELLCAST_SUCCEEDED")
    mf:RegisterEvent("PLAYER_MOUNT_DISPLAY_CHANGED")
    mf:SetScript("OnEvent", function(_, event, ...)
        if event == "UNIT_SPELLCAST_SUCCEEDED" then
            local unit, _, spellId = ...
            if unit ~= "player" then return end
            local db = addon.CharDB
            if not db.characterStarted then return end
            if not db.activeChallenges[NO_HEARTHSTONE_KEY] or db.failedChallenges[NO_HEARTHSTONE_KEY] then return end
            if spellId == HEARTHSTONE_SPELL_ID then
                db.failedChallenges[NO_HEARTHSTONE_KEY] = true
                UIErrorsFrame:AddMessage("No Hearthstone challenge failed!", 1, 0, 0)
                if UI.activeWindow then UI:UpdateActive() end
            end
        elseif event == "PLAYER_MOUNT_DISPLAY_CHANGED" then
            CheckNoMountChallenge()
        end
    end)
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

    -- Legacy bug: `parentMapID or mapID` treated 0 as valid continent id (Lua: 0 is truthy).
    if db.startContinent == 0 then
        db.startContinent = current
        return
    end

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
    -- Self Found + Single Continent: never fail on the first PEW tick — auras/map data are often stale until a moment later.
    local function runStableChecks()
        CheckSelfFound()
        CheckSingleContinent()
    end
    local function runImmediate()
        CheckLordOfTheRingsFromBags(true)
        CheckScarletTabardChallenge()
        CheckQuestHubChallenges(nil)
        ScheduleDungeonOnceCheck()
        CheckNoMountChallenge()
    end
    runImmediate()
    if C_Timer and C_Timer.After then
        C_Timer.After(0, runImmediate)
        C_Timer.After(0.75, runStableChecks)
        C_Timer.After(2.5, runStableChecks)
    else
        runStableChecks()
    end
end

addon:RegisterEvent("UNIT_AURA", function(_, unit)
    if unit == "player" then CheckSelfFound() end
end)

addon:RegisterEvent("ZONE_CHANGED_NEW_AREA", function()
    CheckSingleContinent()
    ScheduleDungeonOnceCheck()
end)

addon:RegisterEvent("BAG_UPDATE_DELAYED", function()
    CheckLordOfTheRingsFromBags(false)
end)

addon:RegisterEvent("PLAYER_EQUIPMENT_CHANGED", function()
    CheckScarletTabardChallenge()
end)

addon:RegisterEvent("QUEST_TURNED_IN", function(_, questId)
    CheckQuestHubChallenges(questId)
end)
