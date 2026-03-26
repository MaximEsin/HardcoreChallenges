-- core/crafted_lock.lua
-- Crafted Locked (Solo / Duo): only self-crafted equipable gear (+ partner attestation in duo).

local addon = HardcoreChallenges

local MSG_PREFIX = "HCChallenges"
local EQUIP_SLOTS_NAKED_CHECK = {
    1, 2, 3, 5, 6, 7, 8, 9, 10, 11, 12, 13, 14, 15, 16, 17, 18,
}
local BAG_EQUIP_SLOTS = { 20, 21, 22, 23 }

local castBagSnapshot = nil
local tradeAcceptedFlag = false
local pendingPartnerCerts = {}

local function Db()
    return addon.CharDB
end

local function EnsureTables(db)
    db.craftedAllowedKeys = db.craftedAllowedKeys or {}
    db.partnerGiftedKeys = db.partnerGiftedKeys or {}
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

local function UniqueFromHeader(h)
    if not h then return 0 end
    local parts = { strsplit(":", h) }
    return tonumber(parts[9] or parts[8] or 0) or 0
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
    local key = ItemInstanceKeyFromLink(link)
    if key then
        db.craftedAllowedKeys[key] = true
    end
end

local function AllowedToWearKey(itemKey)
    if not itemKey then return true end
    local db = Db()
    EnsureTables(db)
    if db.craftedAllowedKeys[itemKey] then return true end
    if addon:CraftedLockIsDuo() and db.partnerGiftedKeys[itemKey] then
        return true
    end
    return false
end

--- First empty slot in backpack or any equipped bag (nil if completely full).
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

--- Returns true if the challenge was failed (inventory full or move error).
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

local function ScanEquipment()
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
                        "Crafted Lock: this gear is not allowed (must be your craft" .. (addon:CraftedLockIsDuo() and " or partner trade" or "") .. ").",
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
                    UIErrorsFrame:AddMessage("Crafted Lock: bags must be self-crafted (or partner gift in duo).", 1, 0.25, 0.25)
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
    db.craftedAllowedKeys = {}
    db.partnerGiftedKeys = {}
    wipe(pendingPartnerCerts)
end

local function OnChatLootCreate(_, msg)
    if not msg or not addon:CraftedLockActive() then return end
    if not strfind(strlower(msg), "create") then return end
    local link = msg:match("|c%x+|Hitem:.-|h%[.-%]|h|r")
    if link then
        RegisterCraftedLink(link)
    end
end

local function RegisterAddonPrefixCompat(prefix)
    if C_ChatInfo and C_ChatInfo.RegisterAddonMessagePrefix then
        C_ChatInfo.RegisterAddonMessagePrefix(prefix)
    elseif RegisterAddonMessagePrefix then
        RegisterAddonMessagePrefix(prefix)
    end
end

local function SendAddonMessageCompat(prefix, msg, chatType, target)
    if C_ChatInfo and C_ChatInfo.SendAddonMessage then
        C_ChatInfo.SendAddonMessage(prefix, msg, chatType, target)
    elseif SendAddonMessage then
        SendAddonMessage(prefix, msg, chatType, target)
    end
end

function addon:CraftedLockOnInitialize()
    RegisterAddonPrefixCompat(MSG_PREFIX)
end

local function SenderNorm(who)
    local n, r = strsplit("-", who or "")
    if r then
        return NormPartner(n .. "-" .. r)
    end
    return NormPartner(who)
end

local function OnAddonMsg(prefix, msg, _, sender)
    if prefix ~= MSG_PREFIX or not msg then return end
    if not addon:CraftedLockIsDuo() then return end
    local db = Db()
    if NormPartner(db.craftedDuoPartner or "") == "" then return end
    local myP = addon:CraftedLockPartnerNorm()
    local s1 = SenderNorm(sender)
    local s2 = SenderNorm(Ambiguate(sender, "short"))
    if s1 ~= myP and s2 ~= myP then return end

    if strsub(msg, 1, 2) == "K:" then
        local enc = strsub(msg, 3)
        local dec = enc:gsub("%*", ":")
        if dec and dec ~= "" then
            pendingPartnerCerts[dec] = GetTime()
        end
        return
    end

    local cmd, a, b = strsplit(":", msg, 3)
    if cmd == "P" and a and b then
        local itemId, uq = tonumber(a), tonumber(b)
        if itemId and uq and uq > 0 then
            pendingPartnerCerts[itemId .. ":" .. uq] = GetTime()
        end
    end
end

function addon:CraftedLockChatAddon(event, prefix, message, channel, sender)
    OnAddonMsg(prefix, message, channel, sender)
end

local function MergePartnerCertsAfterTrade()
    local db = Db()
    if not addon:CraftedLockIsDuo() then return end
    EnsureTables(db)
    for bag = BACKPACK_CONTAINER, NUM_BAG_FRAMES do
        local n = GetContainerNumSlotsCompat(bag) or 0
        for slot = 1, n do
            local link = GetContainerItemLinkCompat(bag, slot)
            if link then
                local id = ItemIdFromLink(link)
                local h = ItemHeaderFromLink(link)
                local uq = UniqueFromHeader(h)
                local ok = (h and pendingPartnerCerts[h]) or (id and pendingPartnerCerts[id .. ":" .. uq])
                if ok and IsRestrictedEquipableCompat(id) then
                    local key = ItemInstanceKeyFromLink(link)
                    if key then
                        db.partnerGiftedKeys[key] = true
                    end
                end
            end
        end
    end
    wipe(pendingPartnerCerts)
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
    local np = NormPartner(p)
    return NormPartner(who) == np or NormPartner(Ambiguate(who, "short")) == np
end

local function TradeOfferCertScan()
    if not addon:CraftedLockIsDuo() then return end
    if not PartnerNameMatchesTrade() then return end
    local who = TradePartnerFullName()
    if not who then return end
    EnsureTables(Db())
    for i = 1, 8 do
        local link = GetTradePlayerItemLink(i)
        if link then
            local id = ItemIdFromLink(link)
            if id and IsRestrictedEquipableCompat(id) then
                local key = ItemInstanceKeyFromLink(link)
                if key and Db().craftedAllowedKeys[key] then
                    local raw = ItemHeaderFromLink(link)
                    if raw then
                        local enc = raw:gsub(":", "*")
                        if enc and #enc + 2 <= 250 then
                            SendAddonMessageCompat(MSG_PREFIX, "K:" .. enc, "WHISPER", who)
                        else
                            local uq = UniqueFromHeader(raw)
                            if uq > 0 then
                                SendAddonMessageCompat(MSG_PREFIX, "P:" .. tostring(id) .. ":" .. tostring(uq), "WHISPER", who)
                            end
                        end
                    end
                end
            end
        end
    end
end

local function MyTradeOfferGuard()
    if not addon:CraftedLockActive() then return end
    EnsureTables(Db())
    for i = 1, 8 do
        local link = GetTradePlayerItemLink(i)
        if link then
            local id = ItemIdFromLink(link)
            if id and IsRestrictedEquipableCompat(id) then
                local key = ItemInstanceKeyFromLink(link)
                if key and not Db().craftedAllowedKeys[key] then
                    UIErrorsFrame:AddMessage("Crafted Lock: remove crafted-only equipable items you did not craft from your trade.", 1, 0.25, 0.25)
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

    -- CHAT_MSG_ADDON: один обработчик на аддон в AceEvent — см. core/titles.lua (цепочка в OnTitlesAddonMsg).

    self:RegisterEvent("TRADE_SHOW", function()
        tradeAcceptedFlag = false
        wipe(pendingPartnerCerts)
    end)

    self:RegisterEvent("TRADE_PLAYER_ITEM_CHANGED", function()
        MyTradeOfferGuard()
        TradeOfferCertScan()
    end)

    self:RegisterEvent("TRADE_ACCEPT_UPDATE", function()
        MyTradeOfferGuard()
        TradeOfferCertScan()
    end)

    self:RegisterEvent("TRADE_CLOSED", function()
        if tradeAcceptedFlag then
            MergePartnerCertsAfterTrade()
        else
            wipe(pendingPartnerCerts)
        end
        tradeAcceptedFlag = false
    end)

    if hooksecurefunc then
        hooksecurefunc("AcceptTrade", function()
            tradeAcceptedFlag = true
        end)
    end

    C_Timer.After(2, function()
        ScanEquipment()
    end)
end
