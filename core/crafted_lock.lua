-- core/crafted_lock.lua
-- Crafted Locked (Solo / Duo): allow equipping gear whose itemId is on the character allowlist.
-- Crafts add itemId automatically; duo merges allowlists with saved trade partner via addon whisper.

local addon = HardcoreChallenges

local MSG_PREFIX = "HCChallenges"
local ALLOW_LIST_CHUNK = 220

local EQUIP_SLOTS_NAKED_CHECK = {
    1, 2, 3, 5, 6, 7, 8, 9, 10, 11, 12, 13, 14, 15, 16, 17, 18,
}
local BAG_EQUIP_SLOTS = { 20, 21, 22, 23 }

local castBagSnapshot = nil

--- Incoming chunked allowlist from trade partner (C:i/n:payload).
local allowListRecv = {
    total = nil,
    parts = {},
    fromNorm = nil,
}

local ScanEquipment

local function ResetAllowListRecv()
    allowListRecv.total = nil
    wipe(allowListRecv.parts)
    allowListRecv.fromNorm = nil
end

local function Db()
    return addon.CharDB
end

--- One-time: merge old per-instance keys into craftedLockAllowedItemIds.
local function MigrateLegacyCraftedLockOnce(db)
    if db._hcCraftedLockItemIdMigrated then return end
    db._hcCraftedLockItemIdMigrated = true
    db.craftedLockAllowedItemIds = db.craftedLockAllowedItemIds or {}
    local function ingestKeyTable(t)
        if not t then return end
        for k, on in pairs(t) do
            if on then
                local id = select(2, strsplit(":", k))
                id = id and tonumber(id)
                if id then
                    db.craftedLockAllowedItemIds[id] = true
                end
            end
        end
    end
    ingestKeyTable(db.craftedAllowedKeys)
    ingestKeyTable(db.partnerGiftedKeys)
    ingestKeyTable(db.craftedManualAllowKeys)
    if db.craftedManualAllowItemIds then
        for itemId, on in pairs(db.craftedManualAllowItemIds) do
            if on then
                db.craftedLockAllowedItemIds[itemId] = true
            end
        end
    end
end

local function EnsureTables(db)
    db.craftedLockAllowedItemIds = db.craftedLockAllowedItemIds or {}
    MigrateLegacyCraftedLockOnce(db)
end

function addon:CraftedLockActive()
    local db = Db()
    if not db.characterStarted then return false end
    if db.activeChallenges["CraftedLockedSolo"] or db.activeChallenges["CraftedLockedDuo"] then
        if db.failedChallenges["CraftedLockedSolo"] or db.failedChallenges["CraftedLockedDuo"] then
            return false
        end
        return true
    end
    return false
end

function addon:CraftedLockIsDuo()
    local db = Db()
    return db.characterStarted and db.activeChallenges["CraftedLockedDuo"] == true
end

function addon:CraftedLockNeedsRules()
    return self:CraftedLockActive()
end

local function NormPartner(s)
    return (s or ""):gsub("^%s+", ""):gsub("%s+$", ""):lower()
end

function addon:CraftedLockPartnerNorm()
    return NormPartner(Db().craftedDuoPartner or "")
end

local function SenderNorm(who)
    local n, r = strsplit("-", who or "")
    if r then
        return NormPartner(n .. "-" .. r)
    end
    return NormPartner(who)
end

--- Saved partner without realm still matches whisper/trade Name-Realm.
local function PartnerAddonWhisperMatches(sender)
    local myP = addon:CraftedLockPartnerNorm()
    if myP == "" then return false end
    local s1 = SenderNorm(sender)
    local s2 = SenderNorm(Ambiguate(sender, "short"))
    if s1 == myP or s2 == myP then return true end
    if not strfind(myP, "-", 1, true) then
        local only = NormPartner(strsplit("-", Ambiguate(sender, "short")))
        if only == myP then return true end
    end
    return false
end

local function TradePartnerUnitId()
    if UnitExists("npc") then return "npc" end
    return nil
end

local function TradePartnerFullName()
    local u = TradePartnerUnitId()
    if not u then return nil end
    return GetUnitName(u, true) or UnitName(u)
end

local function PartnerNameMatchesTrade()
    local p = NormPartner(Db().craftedDuoPartner or "")
    if p == "" then return false end
    local who = TradePartnerFullName()
    if not who then return false end
    local nw = NormPartner(who)
    local ns = NormPartner(Ambiguate(who, "short"))
    if nw == p or ns == p then return true end
    if not strfind(p, "-", 1, true) then
        if NormPartner(strsplit("-", who)) == p then return true end
        local short = Ambiguate(who, "short")
        if short and short ~= who and NormPartner(strsplit("-", short)) == p then return true end
    end
    return false
end

local function ItemHeaderFromLink(link)
    if not link then return nil end
    return link:match("|H([^|]+)|h")
end

local function ItemInstanceKeyFromLink(link)
    return ItemHeaderFromLink(link)
end

local function ItemIdFromLink(link)
    local h = ItemHeaderFromLink(link)
    if not h then return nil end
    return tonumber((select(2, strsplit(":", h))))
end

local function ItemIdFromInstanceKey(key)
    if not key or key == "" then return nil end
    local id = select(2, strsplit(":", key))
    return id and tonumber(id) or nil
end

local function GetContainerNumSlotsCompat(bag)
    if C_Container and C_Container.GetContainerNumSlots then
        return C_Container.GetContainerNumSlots(bag)
    end
    return GetContainerNumSlots(bag)
end

local function GetContainerItemLinkCompat(bag, slot)
    if C_Container and C_Container.GetContainerItemLink then
        return C_Container.GetContainerItemLink(bag, slot)
    end
    return GetContainerItemLink(bag, slot)
end

local function PickupContainerItemCompat(bag, slot)
    if C_Container and C_Container.PickupContainerItem then
        C_Container.PickupContainerItem(bag, slot)
    elseif PickupContainerItem then
        PickupContainerItem(bag, slot)
    end
end

local function BagSnapshot()
    local snap = {}
    for bag = BACKPACK_CONTAINER, NUM_BAG_FRAMES do
        local n = GetContainerNumSlotsCompat(bag) or 0
        for slot = 1, n do
            local link = GetContainerItemLinkCompat(bag, slot)
            local count = 0
            if link and GetContainerItemInfo then
                _, count = GetContainerItemInfo(bag, slot)
            elseif link then
                count = 1
            end
            snap[bag .. ":" .. slot] = (link or "") .. "#" .. tostring(count or 0)
        end
    end
    return snap
end

local function FixDiffNewItems(oldSnap, newSnap)
    local addedKeys = {}
    for key, newVal in pairs(newSnap) do
        local oldVal = oldSnap[key]
        if newVal ~= oldVal then
            local bag, slot = strmatch(key, "^(%-?%d+):(%d+)$")
            bag, slot = tonumber(bag), tonumber(slot)
            if bag and slot then
                local link = GetContainerItemLinkCompat(bag, slot)
                if link then
                    local h = ItemHeaderFromLink(link)
                    if h then addedKeys[h] = link end
                end
            end
        end
    end
    return addedKeys
end

local function IsRestrictedEquipableCompat(itemId)
    if not itemId or itemId == 0 then return false end
    if not IsEquippableItem(itemId) then return false end
    local _, _, _, _, _, _, _, _, _, srcInvType, _, clsId = GetItemInfo(itemId)
    if clsId == nil then
        return IsEquippableItem(itemId)
    end
    local CONS, TRADE, RECIPE, REAGENT, PROJECTILE = 0, 7, 9, 5, 6
    if clsId == CONS or clsId == TRADE or clsId == RECIPE or clsId == REAGENT or clsId == PROJECTILE then
        return false
    end
    if srcInvType == "INVTYPE_AMMO" then return false end
    return true
end

local function RegisterCraftedLink(link)
    if not addon:CraftedLockActive() then return end
    local db = Db()
    EnsureTables(db)
    local itemId = ItemIdFromLink(link)
    if not itemId or not IsRestrictedEquipableCompat(itemId) then return end
    local isNew = not db.craftedLockAllowedItemIds[itemId]
    db.craftedLockAllowedItemIds[itemId] = true
    if isNew then
        local nm = GetItemInfo(itemId) or ("#" .. tostring(itemId))
        print("|cff00ff00[HC]|r Crafted Lock: item ID " .. tostring(itemId) .. " (" .. nm .. ") added to your allowed list.")
    end
    ScanEquipment()
    if addon.UI and addon.UI.UpdateActive then
        addon.UI:UpdateActive()
    end
end

local function AllowedToWearKey(itemKey)
    if not itemKey then return true end
    local db = Db()
    EnsureTables(db)
    local id = ItemIdFromInstanceKey(itemKey)
    if id and db.craftedLockAllowedItemIds[id] then return true end
    return false
end

local function FindFirstEmptyBagSlot()
    for bag = BACKPACK_CONTAINER, NUM_BAG_FRAMES do
        local n = GetContainerNumSlotsCompat(bag) or 0
        for slot = 1, n do
            if not GetContainerItemLinkCompat(bag, slot) then
                return bag, slot
            end
        end
    end
    return nil, nil
end

local function HasFreeBagSlot()
    return FindFirstEmptyBagSlot() ~= nil
end

local function FailCraftedLockChallenge(reason)
    local db = Db()
    if db.activeChallenges["CraftedLockedDuo"] then
        db.failedChallenges["CraftedLockedDuo"] = true
    end
    if db.activeChallenges["CraftedLockedSolo"] then
        db.failedChallenges["CraftedLockedSolo"] = true
    end
    UIErrorsFrame:AddMessage(reason or "Crafted Lock challenge failed.", 1, 0, 0)
    local UI = addon.UI
    if UI and UI.activeWindow then
        UI:UpdateActive()
    end
end

local function StripEquipSlot(invSlot)
    if InCombatLockdown() then return false end
    if not GetInventoryItemID("player", invSlot) then return false end

    if not HasFreeBagSlot() then
        FailCraftedLockChallenge("Crafted Lock failed: no free space in bags — make room or the challenge is forfeited.")
        return true
    end

    PickupInventoryItem(invSlot)
    if not CursorHasItem() then return false end

    local placed = false
    for _ = 1, 40 do
        local bag, slot = FindFirstEmptyBagSlot()
        if not bag then break end
        PickupContainerItemCompat(bag, slot)
        if not CursorHasItem() then
            placed = true
            break
        end
    end

    if not placed and CursorHasItem() then
        ClearCursor()
        FailCraftedLockChallenge("Crafted Lock failed: could not put forbidden gear into bags (inventory full?).")
        return true
    end

    return false
end

ScanEquipment = function()
    if not addon:CraftedLockNeedsRules() then return end
    for _, invSlot in ipairs(EQUIP_SLOTS_NAKED_CHECK) do
        if not addon:CraftedLockActive() then return end
        local link = GetInventoryItemLink("player", invSlot)
        if link then
            local id = GetInventoryItemID("player", invSlot)
            if IsRestrictedEquipableCompat(id) then
                local key = ItemInstanceKeyFromLink(link)
                if not AllowedToWearKey(key) then
                    UIErrorsFrame:AddMessage(
                        "Crafted Lock: this gear is not on your allowed item list (craft it or trade sync with your duo partner).",
                        1, 0.25, 0.25
                    )
                    if StripEquipSlot(invSlot) then return end
                end
            end
        end
    end
    for _, invSlot in ipairs(BAG_EQUIP_SLOTS) do
        if not addon:CraftedLockActive() then return end
        local link = GetInventoryItemLink("player", invSlot)
        if link then
            local id = GetInventoryItemID("player", invSlot)
            if id and IsEquippableItem(id) then
                local key = ItemInstanceKeyFromLink(link)
                if not AllowedToWearKey(key) then
                    UIErrorsFrame:AddMessage("Crafted Lock: bags — only allowed item IDs.", 1, 0.25, 0.25)
                    if StripEquipSlot(invSlot) then return end
                end
            end
        end
    end
end

function addon:CraftedLockIsNakedForStart()
    for _, invSlot in ipairs(EQUIP_SLOTS_NAKED_CHECK) do
        if GetInventoryItemID("player", invSlot) then
            return false
        end
    end
    for _, invSlot in ipairs(BAG_EQUIP_SLOTS) do
        if GetInventoryItemID("player", invSlot) then
            return false
        end
    end
    return true
end

function addon:CraftedLockOnChallengeStart()
    local db = Db()
    db.craftedLockAllowedItemIds = {}
    db.craftedAllowedKeys = {}
    db.partnerGiftedKeys = {}
    db.craftedManualAllowKeys = {}
    db.craftedManualAllowItemIds = {}
    db._hcCraftedLockItemIdMigrated = true
end

local function OnChatLootCreate(_, msg)
    if not msg or not addon:CraftedLockActive() then return end
    if not strfind(strlower(msg), "create") then return end
    local link = msg:match("|c%x+|Hitem:.-|h%[.-%]|h|r")
    if link then
        RegisterCraftedLink(link)
    end
end

local function SendAddonMessageCompat(prefix, msg, chatType, target)
    if C_ChatInfo and C_ChatInfo.SendAddonMessage then
        C_ChatInfo.SendAddonMessage(prefix, msg, chatType, target)
    elseif SendAddonMessage then
        SendAddonMessage(prefix, msg, chatType, target)
    end
end

local function MergePartnerIdCsvIntoAllowlist(csv)
    local db = Db()
    EnsureTables(db)
    local added = 0
    for piece in string.gmatch(csv or "", "[^,]+") do
        local id = tonumber((piece:gsub("^%s+", ""):gsub("%s+$", "")))
        if id and id > 0 then
            if not db.craftedLockAllowedItemIds[id] then
                added = added + 1
            end
            db.craftedLockAllowedItemIds[id] = true
        end
    end
    return added
end

local function SortedAllowedItemIds(db)
    local t = {}
    for id, on in pairs(db.craftedLockAllowedItemIds) do
        if on then
            t[#t + 1] = id
        end
    end
    table.sort(t)
    return t
end

local function BuildAllowListChunks(ids)
    local chunks = {}
    local cur = nil
    for _, id in ipairs(ids) do
        local p = tostring(id)
        if not cur then
            cur = p
        elseif #cur + 1 + #p <= ALLOW_LIST_CHUNK then
            cur = cur .. "," .. p
        else
            chunks[#chunks + 1] = cur
            cur = p
        end
    end
    if cur then
        chunks[#chunks + 1] = cur
    end
    return chunks
end

local function SendAllowListToTradePartner()
    if not addon:CraftedLockIsDuo() then return end
    if not PartnerNameMatchesTrade() then return end
    local who = TradePartnerFullName()
    if not who then return end
    EnsureTables(Db())
    local ids = SortedAllowedItemIds(Db())
    local chunks = BuildAllowListChunks(ids)
    if #chunks == 0 then
        SendAddonMessageCompat(MSG_PREFIX, "C:1/1:", "WHISPER", who)
        return
    end
    local n = #chunks
    for i, body in ipairs(chunks) do
        SendAddonMessageCompat(MSG_PREFIX, "C:" .. i .. "/" .. n .. ":" .. body, "WHISPER", who)
    end
end

function addon:CraftedLockOnInitialize()
    if C_ChatInfo and C_ChatInfo.RegisterAddonMessagePrefix then
        C_ChatInfo.RegisterAddonMessagePrefix(MSG_PREFIX)
    elseif RegisterAddonMessagePrefix then
        RegisterAddonMessagePrefix(MSG_PREFIX)
    end
end

function addon:CraftedLockChatAddon(_, prefix, msg, _, sender)
    if prefix ~= MSG_PREFIX or not msg or not addon:CraftedLockIsDuo() then return end
    if NormPartner(Db().craftedDuoPartner or "") == "" then return end
    if not PartnerAddonWhisperMatches(sender) then return end
    if strsub(msg, 1, 2) ~= "C:" then return end
    local idx, tot, payload = strmatch(strsub(msg, 3), "^(%d+)/(%d+):(.*)$")
    idx, tot = tonumber(idx), tonumber(tot)
    if not idx or not tot or idx < 1 or tot < 1 or idx > tot then return end
    local sn = SenderNorm(sender)
    if allowListRecv.total ~= tot or allowListRecv.fromNorm ~= sn then
        ResetAllowListRecv()
        allowListRecv.total = tot
        allowListRecv.fromNorm = sn
    end
    allowListRecv.parts[idx] = payload or ""
    for i = 1, tot do
        if allowListRecv.parts[i] == nil then return end
    end
    local full = table.concat(allowListRecv.parts, ",")
    ResetAllowListRecv()
    local added = MergePartnerIdCsvIntoAllowlist(full)
    if added > 0 then
        print("|cff00ff00[HC]|r Crafted Lock: " .. tostring(added) .. " new allowed item ID(s) from your duo partner (merged lists).")
    end
    ScanEquipment()
    if addon.UI and addon.UI.UpdateActive then
        addon.UI:UpdateActive()
    end
end

function addon:CraftedLockCountAllowedItemIds()
    local db = Db()
    EnsureTables(db)
    local n = 0
    for _ in pairs(db.craftedLockAllowedItemIds) do
        n = n + 1
    end
    return n
end

local function MyTradeOfferGuard()
    if not addon:CraftedLockActive() then return end
    EnsureTables(Db())
    local db = Db()
    for i = 1, 8 do
        local link = GetTradePlayerItemLink(i)
        if link then
            local id = ItemIdFromLink(link)
            if id and IsRestrictedEquipableCompat(id) then
                if not db.craftedLockAllowedItemIds[id] then
                    UIErrorsFrame:AddMessage(
                        "Crafted Lock: remove equippable items that are not on your allowed ID list from the trade.",
                        1,
                        0.25,
                        0.25
                    )
                end
            end
        end
    end
end

function addon:CraftedLockOnEnable()
    if self._craftLockEvents then return end
    self._craftLockEvents = true

    self:RegisterEvent("PLAYER_EQUIPMENT_CHANGED", function()
        ScanEquipment()
    end)

    self:RegisterEvent("UNIT_SPELLCAST_START", function(_, unit)
        if unit ~= "player" or not addon:CraftedLockActive() then return end
        castBagSnapshot = BagSnapshot()
    end)

    self:RegisterEvent("UNIT_SPELLCAST_SUCCEEDED", function(_, unit)
        if unit ~= "player" or not addon:CraftedLockActive() or not castBagSnapshot then return end
        local old = castBagSnapshot
        castBagSnapshot = nil
        C_Timer.After(0.05, function()
            if not addon:CraftedLockActive() then return end
            local added = FixDiffNewItems(old, BagSnapshot())
            for _, link in pairs(added) do
                RegisterCraftedLink(link)
            end
        end)
    end)

    self:RegisterEvent("UNIT_SPELLCAST_INTERRUPTED", function(_, unit)
        if unit == "player" then castBagSnapshot = nil end
    end)

    self:RegisterEvent("CHAT_MSG_LOOT", OnChatLootCreate)

    self:RegisterEvent("TRADE_SHOW", function()
        ResetAllowListRecv()
        if addon:CraftedLockActive() and addon:CraftedLockIsDuo() and PartnerNameMatchesTrade() then
            C_Timer.After(0.15, function()
                if addon:CraftedLockActive() and TradePartnerUnitId() and PartnerNameMatchesTrade() then
                    SendAllowListToTradePartner()
                end
            end)
        end
    end)

    self:RegisterEvent("TRADE_CLOSED", function()
        ResetAllowListRecv()
    end)

    self:RegisterEvent("TRADE_PLAYER_ITEM_CHANGED", function()
        MyTradeOfferGuard()
    end)

    self:RegisterEvent("TRADE_ACCEPT_UPDATE", function()
        MyTradeOfferGuard()
    end)

    C_Timer.After(2, function()
        ScanEquipment()
    end)
end
