-- core/titles.lua — звания по завершённым челленджам (хаб), синхронизация с другими клиентами через addon messages.

local addon = HardcoreChallenges

local PREFIX = "HCChallenges"
local COLOR_PREFIX = "|cFFFFD100"
local COLOR_SUFFIX = "|r"
local UnitIsUnitSafe = _G.UnitIsUnit
local ChatFrame_AddMessageEventFilterSafe = _G.ChatFrame_AddMessageEventFilter
local IsInGuildSafe = _G.IsInGuild
local IsInRaidSafe = _G.IsInRaid
local IsInGroupSafe = _G.IsInGroup
local CompactUnitFrame_UpdateNameSafe = _G.CompactUnitFrame_UpdateName
local function trim(s)
    return (s or ""):gsub("^%s+", ""):gsub("%s+$", "")
end

local function SendAddonMessageCompat(prefix, msg, chatType, target)
    if C_ChatInfo and C_ChatInfo.SendAddonMessage then
        C_ChatInfo.SendAddonMessage(prefix, msg, chatType, target)
    elseif SendAddonMessage then
        SendAddonMessage(prefix, msg, chatType, target)
    end
end

addon.remoteTitleKeys = {}
addon.remoteChallengeProfiles = {}

local requestThrottle = {}
local THROTTLE_SEC = 40
local chatTitleQThrottle = {}
local CHAT_Q_THROTTLE_SEC = 25
local ticker
local chatTitleFiltersRegistered = false
local RequestTitleWhisper

local CHAT_EVENTS_WITH_TITLE = {
    "CHAT_MSG_WHISPER",
    "CHAT_MSG_PARTY",
    "CHAT_MSG_PARTY_LEADER",
    "CHAT_MSG_RAID",
    "CHAT_MSG_RAID_LEADER",
    "CHAT_MSG_GUILD",
    "CHAT_MSG_OFFICER",
}

local function StoreRemoteTitle(sender, key)
    if not sender or sender == "" then return end
    local val = key or false
    local variants = {
        trim(sender),
        Ambiguate(sender, "none"),
        Ambiguate(sender, "short"),
    }
    for _, v in ipairs(variants) do
        if v and v ~= "" then
            addon.remoteTitleKeys[v] = val
            local hyphen = strfind(v, "-", 1, true)
            if hyphen then
                addon.remoteTitleKeys[strsub(v, 1, hyphen - 1)] = val
            end
        end
    end
end

local function BuildNameVariants(name)
    local out = {}
    local base = trim(name or "")
    if base ~= "" then
        out[#out + 1] = base
        out[#out + 1] = Ambiguate(base, "none")
        out[#out + 1] = Ambiguate(base, "short")
        local hyphen = strfind(base, "-", 1, true)
        if hyphen then
            out[#out + 1] = strsub(base, 1, hyphen - 1)
        end
    end
    local uniq, deduped = {}, {}
    for _, v in ipairs(out) do
        if v and v ~= "" and not uniq[v] then
            uniq[v] = true
            deduped[#deduped + 1] = v
        end
    end
    return deduped
end

local function EnsureRemoteProfile(sender)
    if not sender or sender == "" then return nil end
    local base = trim(sender)
    if base == "" then return nil end
    local p = addon.remoteChallengeProfiles[base]
    if not p then
        p = {
            name = base,
            activeChallenges = {},
            hubCompletedKeys = {},
            updatedAt = 0,
        }
        addon.remoteChallengeProfiles[base] = p
    end
    for _, v in ipairs(BuildNameVariants(base)) do
        addon.remoteChallengeProfiles[v] = p
    end
    return p
end

local function ParseKeyListPayload(payload)
    local out = {}
    payload = payload or ""
    if payload == "" then
        return out
    end
    for token in string.gmatch(payload, "([^,]+)") do
        local key = trim(token or "")
        if key ~= "" and addon.Challenges[key] then
            out[key] = true
        end
    end
    return out
end

local function EncodeActiveChallengePayload()
    local db = addon.CharDB
    local keys = {}
    for key, enabled in pairs(db.activeChallenges or {}) do
        if enabled and addon.Challenges[key] and not addon.Challenges[key].hubOnly then
            keys[#keys + 1] = key
        end
    end
    table.sort(keys)
    return table.concat(keys, ",")
end

local function EncodeHubPayload()
    local hub = addon:HubEnsure()
    local keys = {}
    for key, completed in pairs(hub.completedKeys or {}) do
        if completed and addon.Challenges[key] then
            keys[#keys + 1] = key
        end
    end
    table.sort(keys)
    return table.concat(keys, ",")
end

function addon:GetRemoteProfileByName(name)
    if not name or name == "" then return nil end
    for _, v in ipairs(BuildNameVariants(name)) do
        local p = self.remoteChallengeProfiles[v]
        if p then return p end
    end
    return nil
end

function addon:GetRemoteProfileForUnit(unit)
    if not unit or not UnitExists(unit) or not UnitIsPlayer(unit) then return nil end
    local full = GetUnitName(unit, true)
    local short = UnitName(unit)
    return self:GetRemoteProfileByName(full) or self:GetRemoteProfileByName(short)
end

function addon:RequestRemoteProfileForUnit(unit)
    if RequestTitleWhisper then
        RequestTitleWhisper(unit)
    end
end

local function LookupRemoteTitleKey(unit)
    local full = GetUnitName(unit, true)
    local short = UnitName(unit)
    local ids = {}
    if full then
        ids[#ids + 1] = full
        ids[#ids + 1] = Ambiguate(full, "none")
        ids[#ids + 1] = Ambiguate(full, "short")
    end
    if short then
        ids[#ids + 1] = short
    end
    for _, id in ipairs(ids) do
        if id and id ~= "" then
            local v = addon.remoteTitleKeys[id]
            if v == false then
                return nil
            end
            if type(v) == "string" and v ~= "" then
                return v
            end
        end
    end
    return nil
end

local function ExtractPlainAuthorName(author)
    if not author or author == "" then return nil end
    local body = strmatch(author, "|Hplayer:([^|]+)|")
    if body then
        local pname = strsplit(":", body)
        if pname and pname ~= "" then
            return trim(pname)
        end
    end
    return trim(author)
end

local function IsSamePlayerAsMe(plain)
    if not plain or plain == "" then return false end
    local myFull = GetUnitName("player", true)
    local myShort = UnitName("player")
    if plain == myFull or plain == myShort then return true end
    if myFull and Ambiguate(plain, "none") == Ambiguate(myFull, "none") then return true end
    return false
end

local function TitleKeyForPlainName(plain)
    if not plain then return nil end
    local ids = { plain, Ambiguate(plain, "none"), Ambiguate(plain, "short") }
    local h = strfind(plain, "-", 1, true)
    if h then
        ids[#ids + 1] = strsub(plain, 1, h - 1)
    end
    for _, id in ipairs(ids) do
        if id and id ~= "" then
            local v = addon.remoteTitleKeys[id]
            if v == false then
                return nil
            end
            if type(v) == "string" and v ~= "" then
                return v
            end
        end
    end
    return nil
end

local function TitleKeyForChatAuthor(authorRaw)
    local plain = ExtractPlainAuthorName(authorRaw)
    if not plain then return nil end
    if IsSamePlayerAsMe(plain) then
        addon:ValidateSelectedDisplayTitle()
        local k = addon.CharDB.selectedDisplayTitleKey
        if not k then return nil end
        local hub = addon:HubEnsure()
        if hub.completedKeys[k] and addon.Challenges[k] then return k end
        return nil
    end
    return TitleKeyForPlainName(plain)
end

local function MaybeRequestTitleViaWhisper(authorRaw)
    if not authorRaw or authorRaw == "" then return end
    local plain = ExtractPlainAuthorName(authorRaw)
    if not plain or plain == "" or IsSamePlayerAsMe(plain) then return end
    local target = plain
    if strfind(plain, "-", 1, true) == nil and GetRealmName then
        local r = GetRealmName()
        if r and r ~= "" then
            target = plain .. "-" .. r
        end
    end
    local t = GetTime()
    if (chatTitleQThrottle[target] or 0) + CHAT_Q_THROTTLE_SEC > t then return end
    chatTitleQThrottle[target] = t
    SendAddonMessageCompat(PREFIX, "Q", "WHISPER", target)
end

local function ChatTitleMessageFilter(_chatFrame, event, msg, author, ...)
    if not msg or type(msg) ~= "string" then return false, msg, author, ... end
    if not author then return false, msg, author, ... end
    local key = TitleKeyForChatAuthor(author)
    if not key then
        if event == "CHAT_MSG_WHISPER" then
            if C_Timer and C_Timer.After then
                local auth = author
                C_Timer.After(0, function()
                    MaybeRequestTitleViaWhisper(auth)
                end)
            else
                MaybeRequestTitleViaWhisper(author)
            end
        end
        return false, msg, author, ...
    end
    local title = addon:GetDisplayTitleForKey(key)
    if not title then return false, msg, author, ... end
    local tag = COLOR_PREFIX .. title .. COLOR_SUFFIX .. " "
    if strsub(msg, 1, #tag) == tag then return false, msg, author, ... end
    return false, tag .. msg, author, ...
end

local function RegisterChatTitleFilters()
    if chatTitleFiltersRegistered or not ChatFrame_AddMessageEventFilterSafe then return end
    for _, ev in ipairs(CHAT_EVENTS_WITH_TITLE) do
        pcall(function()
            ChatFrame_AddMessageEventFilterSafe(ev, ChatTitleMessageFilter)
        end)
    end
    chatTitleFiltersRegistered = true
end

function addon:ValidateSelectedDisplayTitle()
    local db = self.CharDB
    local key = db.selectedDisplayTitleKey
    if not key then return end
    local hub = self:HubEnsure()
    if not hub.completedKeys[key] or not self.Challenges[key] then
        db.selectedDisplayTitleKey = nil
    end
end

function addon:GetDisplayTitleForKey(key)
    if not key or key == "" then return nil end
    local def = self.Challenges[key]
    if not def then return nil end
    return def.displayTitle or def.name
end

function addon:GetEffectiveDisplayTitleKeyForUnit(unit)
    if not unit or not UnitExists(unit) then return nil end
    if not UnitIsPlayer(unit) then return nil end
    if UnitIsUnit(unit, "player") then
        self:ValidateSelectedDisplayTitle()
        local db = self.CharDB
        local key = db.selectedDisplayTitleKey
        if not key then return nil end
        local hub = self:HubEnsure()
        if hub.completedKeys[key] and self.Challenges[key] then
            return key
        end
        return nil
    end
    return LookupRemoteTitleKey(unit)
end

function addon:GetBroadcastTitlePayload()
    self:ValidateSelectedDisplayTitle()
    local db = self.CharDB
    local key = db.selectedDisplayTitleKey
    if not key then return "" end
    local hub = self:HubEnsure()
    if not hub.completedKeys[key] or not self.Challenges[key] then
        return ""
    end
    return key
end

function addon:BroadcastDisplayTitle()
    if InCombatLockdown() then return end
    local payload = self:GetBroadcastTitlePayload()
    local msg = "T|" .. payload
    if #msg > 255 then return end
    pcall(function()
        if IsInGuildSafe and IsInGuildSafe() then
            SendAddonMessageCompat(PREFIX, msg, "GUILD")
        end
        if IsInRaidSafe and IsInRaidSafe() then
            SendAddonMessageCompat(PREFIX, msg, "RAID")
        elseif IsInGroupSafe and IsInGroupSafe() then
            SendAddonMessageCompat(PREFIX, msg, "PARTY")
        end
    end)
end

function RequestTitleWhisper(unit)
    if not unit or not UnitExists(unit) or not UnitIsPlayer(unit) then return end
    if UnitIsUnit(unit, "player") then return end
    local target = GetUnitName(unit, true)
    if not target or target == "" then return end
    local t = GetTime()
    if (requestThrottle[target] or 0) + THROTTLE_SEC > t then return end
    requestThrottle[target] = t
    SendAddonMessageCompat(PREFIX, "Q", "WHISPER", target)
end

local function ApplyTitleToNameFontString(unit, fs)
    if not fs or not fs.SetText then return end
    if not unit or not UnitExists(unit) or not UnitIsPlayer(unit) then return end
    local plain = UnitName(unit)
    if not plain then return end
    local key = addon:GetEffectiveDisplayTitleKeyForUnit(unit)
    local title = key and addon:GetDisplayTitleForKey(key)
    if not title then return end
    fs:SetText(COLOR_PREFIX .. title .. COLOR_SUFFIX .. " " .. plain)
end

local function OnCompactNameUpdate(frame)
    if not frame or frame:IsForbidden() then return end
    local unit = frame.unit
    if not unit or not UnitExists(unit) or not UnitIsPlayer(unit) then return end
    local nameFS = frame.name
    if not nameFS then return end
    ApplyTitleToNameFontString(unit, nameFS)
end

local function HookLegacyUnitFrameNames()
    if not hooksecurefunc then return end

    if UnitFrame_Update then
        pcall(function()
            hooksecurefunc("UnitFrame_Update", function(frame)
                if not frame or frame:IsForbidden() then return end
                local unit = frame.unit
                if not unit or not UnitExists(unit) or not UnitIsPlayer(unit) then return end
                if frame.name then
                    ApplyTitleToNameFontString(unit, frame.name)
                end
            end)
        end)
    end

    if TargetFrame_Update then
        pcall(function()
            hooksecurefunc("TargetFrame_Update", function()
                local tf = _G.TargetFrame
                local fs = _G.TargetFrameTextureFrameName or _G.TargetFrameName
                if not fs and tf and tf.name then
                    fs = tf.name
                end
                if fs and UnitExists("target") and UnitIsPlayer("target") then
                    ApplyTitleToNameFontString("target", fs)
                end
            end)
        end)
    end

    if FocusFrame_Update then
        pcall(function()
            hooksecurefunc("FocusFrame_Update", function()
                local fs = _G.FocusFrameTextureFrameName or _G.FocusFrameName
                if fs and UnitExists("focus") and UnitIsPlayer("focus") then
                    ApplyTitleToNameFontString("focus", fs)
                end
            end)
        end)
    end

    if PlayerFrame_Update then
        pcall(function()
            hooksecurefunc("PlayerFrame_Update", function()
                local pf = _G.PlayerFrame
                local fs = _G.PlayerName or _G.PlayerFrameName
                if not fs and pf and pf.name then
                    fs = pf.name
                end
                if fs and UnitExists("player") then
                    ApplyTitleToNameFontString("player", fs)
                end
            end)
        end)
    end
end

--- После прихода addon-сообщения с званием перерисовать стандартные рамки.
function addon:RefreshTitleDependentUnitFrames()
    pcall(function()
        local tf = _G.TargetFrame
        if TargetFrame_Update and tf then
            TargetFrame_Update(tf)
        end
    end)
    pcall(function()
        local ff = _G.FocusFrame
        if FocusFrame_Update and ff then
            FocusFrame_Update(ff)
        end
    end)
    pcall(function()
        local pf = _G.PlayerFrame
        if PlayerFrame_Update and pf then
            PlayerFrame_Update(pf)
        end
    end)
end

function addon:TitlesOnEnable()
    self:ValidateSelectedDisplayTitle()

    self:RegisterEvent("PLAYER_ENTERING_WORLD", function()
        if self.RunEnteringWorldChallengeChecks then
            self:RunEnteringWorldChallengeChecks()
        end
        self:ValidateSelectedDisplayTitle()
        wipe(requestThrottle)
        wipe(chatTitleQThrottle)
        self:BroadcastDisplayTitle()
        if self.EnsureMinimapButton then
            self:EnsureMinimapButton()
        end
    end)

    self:RegisterEvent("GROUP_ROSTER_UPDATE", function()
        self:BroadcastDisplayTitle()
    end)

    -- Один обработчик CHAT_MSG_ADDON на весь аддон: сначала Crafted Lock, потом звания.
    self:RegisterEvent("CHAT_MSG_ADDON", function(event, prefix, message, channel, sender)
        if self.CraftedLockChatAddon then
            self:CraftedLockChatAddon(event, prefix, message, channel, sender)
        end
        if prefix ~= PREFIX then return end
        if message == "Q" and channel == "WHISPER" and sender then
            local payload = self:GetBroadcastTitlePayload()
            SendAddonMessageCompat(PREFIX, "T|" .. payload, "WHISPER", sender)
            SendAddonMessageCompat(PREFIX, "C|" .. EncodeActiveChallengePayload(), "WHISPER", sender)
            SendAddonMessageCompat(PREFIX, "H|" .. EncodeHubPayload(), "WHISPER", sender)
            return
        end
        if strsub(message or "", 1, 2) == "T|" then
            local key = strsub(message, 3)
            if key == "" then
                key = nil
            end
            if key and not self.Challenges[key] then return end
            StoreRemoteTitle(sender, key)
            if self.RefreshTitleDependentUnitFrames then
                self:RefreshTitleDependentUnitFrames()
            end
            return
        end
        if strsub(message or "", 1, 2) == "C|" then
            local profile = EnsureRemoteProfile(sender)
            if not profile then return end
            profile.activeChallenges = ParseKeyListPayload(strsub(message, 3))
            profile.updatedAt = GetTime()
            if self.UI and self.UI.activeWindow and self.UI.UpdateActive then
                self.UI:UpdateActive()
            end
            return
        end
        if strsub(message or "", 1, 2) == "H|" then
            local profile = EnsureRemoteProfile(sender)
            if not profile then return end
            profile.hubCompletedKeys = ParseKeyListPayload(strsub(message, 3))
            profile.updatedAt = GetTime()
            if self.UI and self.UI.hubWindow and self.UI.RefreshHub then
                self.UI:RefreshHub()
            end
        end
    end)

    self:RegisterEvent("UPDATE_MOUSEOVER_UNIT", function()
        if UnitExists("mouseover") and UnitIsPlayer("mouseover")
            and not (UnitIsUnitSafe and UnitIsUnitSafe("mouseover", "player"))
        then
            RequestTitleWhisper("mouseover")
        end
    end)

    self:RegisterEvent("PLAYER_TARGET_CHANGED", function()
        if UnitExists("target") and UnitIsPlayer("target")
            and not (UnitIsUnitSafe and UnitIsUnitSafe("target", "player"))
        then
            RequestTitleWhisper("target")
            if C_Timer and C_Timer.After then
                C_Timer.After(0.35, function()
                    if addon.RefreshTitleDependentUnitFrames then
                        addon:RefreshTitleDependentUnitFrames()
                    end
                end)
                C_Timer.After(1.2, function()
                    if addon.RefreshTitleDependentUnitFrames then
                        addon:RefreshTitleDependentUnitFrames()
                    end
                end)
            end
        end
    end)

    pcall(function()
        self:RegisterEvent("NAME_PLATE_UNIT_ADDED", function(event, unit)
            if unit and UnitIsPlayer(unit) and not (UnitIsUnitSafe and UnitIsUnitSafe(unit, "player")) then
                RequestTitleWhisper(unit)
            end
        end)
    end)

    if ticker and ticker.Cancel then ticker:Cancel() end
    if C_Timer and C_Timer.NewTicker then
        ticker = C_Timer.NewTicker(90, function()
            addon:BroadcastDisplayTitle()
        end)
    end

    if hooksecurefunc and CompactUnitFrame_UpdateNameSafe then
        pcall(function()
            hooksecurefunc(CompactUnitFrame_UpdateNameSafe, OnCompactNameUpdate)
        end)
    end

    HookLegacyUnitFrameNames()

    if GameTooltip and GameTooltip.HookScript then
        GameTooltip:HookScript("OnTooltipSetUnit", function(tip)
            if tip ~= GameTooltip or tip._hcTooltipNamePatched then return end
            local _, unit = tip:GetUnit()
            if not unit or not UnitIsPlayer(unit) then return end
            local key = addon:GetEffectiveDisplayTitleKeyForUnit(unit)
            local title = key and addon:GetDisplayTitleForKey(key)
            if not title then return end
            local left1 = _G.GameTooltipTextLeft1
            if not left1 or not left1.GetText or not left1.SetText then return end
            local cur = left1:GetText()
            if not cur or cur == "" then return end
            if strfind(cur, title, 1, true) then return end
            tip._hcTooltipNamePatched = true
            left1:SetText(COLOR_PREFIX .. title .. COLOR_SUFFIX .. " " .. cur)
            tip:Show()
        end)
        GameTooltip:HookScript("OnTooltipCleared", function(tip)
            tip._hcTooltipNamePatched = nil
        end)
    end

    RegisterChatTitleFilters()

    self:BroadcastDisplayTitle()
end

function addon:SetSelectedDisplayTitleKey(key)
    local db = self.CharDB
    if key and key ~= "" then
        local hub = self:HubEnsure()
        if not hub.completedKeys[key] or not self.Challenges[key] then
            return
        end
    else
        key = nil
    end
    db.selectedDisplayTitleKey = key
    self:BroadcastDisplayTitle()
end

function addon:GetSelectedDisplayTitleKey()
    self:ValidateSelectedDisplayTitle()
    return self.CharDB.selectedDisplayTitleKey
end

function addon:GetUnlockedTitleKeys()
    local hub = self:HubEnsure()
    local keys = {}
    for k in pairs(hub.completedKeys) do
        if self.Challenges[k] and self:GetDisplayTitleForKey(k) then
            keys[#keys + 1] = k
        end
    end
    table.sort(keys, function(a, b)
        local ta = self:GetDisplayTitleForKey(a) or a
        local tb = self:GetDisplayTitleForKey(b) or b
        return ta < tb
    end)
    return keys
end
