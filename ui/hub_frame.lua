-- ui/hub_frame.lua — account-wide challenge completions.

local addon = HardcoreChallenges
local UI = addon.UI

local META_KEY = "MetaAllChallenges"
local VIEW_SELF = "self"
local VIEW_TARGET = "target"
local UnitIsUnitSafe = _G.UnitIsUnit

local function SortedHubKeysExcludingMeta(hubKeys)
    local keys = {}
    for k in pairs(hubKeys or {}) do
        if addon.Challenges[k] and k ~= META_KEY then
            keys[#keys + 1] = k
        end
    end
    table.sort(keys, function(a, b)
        local na = addon.Challenges[a].name
        local nb = addon.Challenges[b].name
        return na < nb
    end)
    return keys
end

function UI:RefreshHub()
    local root = self.hubWindow
    if not root or not root._layoutHub then return end
    if (root._hubViewMode or VIEW_SELF) == VIEW_SELF then
        addon:HubSyncMetaChallenge()
    end
    root._layoutHub()
    if root._refreshHubViewLabel then
        root._refreshHubViewLabel()
    elseif root._totalLabel then
        root._totalLabel:SetText("|cFFFFFF00Account points: " .. addon:HubGetTotalPoints() .. "|r")
    end
    if self.RefreshTitlesTab then
        self:RefreshTitlesTab()
    end
end

function UI:ShowHub()
    if self.hubWindow then
        self:RefreshHub()
        self.hubWindow:Show()
        self.hubWindow:RefreshTheme()
        return
    end

    local frameName = "HardcoreChallenges_HubFrame"
    local root = self:CreateThemedWindow({
        name = frameName,
        title = "Account Hub",
        width = 440,
        height = 420,
        logoTexture = "Interface\\Icons\\INV_Misc_Coin_01",
    })

    _G[frameName] = root
    tinsert(UISpecialFrames, frameName)
    root._hubViewMode = VIEW_SELF
    root._hubViewName = nil

    local scroll, content = self:CreateBodyScroll(root.Body)
    root._scroll = scroll
    root._content = content

    local foot = root.Footer
    local fontPath = root._pointFontPath
    local r0, g0, b0 = self.GetTitleTextColor()
    local tr, tg, tb = self.GetPlayerClassColor()

    local totalLabel = foot:CreateFontString(nil, "OVERLAY", "GameFontHighlightLarge")
    totalLabel:SetPoint("CENTER", foot, "CENTER", 0, 6)
    UI.SafeSetFont(totalLabel, fontPath, 18, "GameFontHighlightLarge")
    root._totalLabel = totalLabel

    function root._layoutHub()
        local contentFrame = root._content
        if not contentFrame then return end

        for _, child in ipairs({ contentFrame:GetChildren() }) do
            child:Hide()
            child:SetParent(nil)
        end

        local y = -8
        local profile = root._hubViewMode == VIEW_TARGET and addon:GetRemoteProfileByName(root._hubViewName) or nil
        local hubKeys = profile and profile.hubCompletedKeys or addon:HubEnsure().completedKeys
        local metaDef = addon.Challenges[META_KEY]

        if metaDef then
            local metaComplete = hubKeys[META_KEY] and true or false
            local row = CreateFrame("Frame", nil, contentFrame)
            row:SetWidth(contentFrame:GetWidth() > 0 and contentFrame:GetWidth() or 380)

            local icon = row:CreateTexture(nil, "ARTWORK")
            icon:SetSize(40, 40)
            icon:SetPoint("TOPLEFT", row, "TOPLEFT", 4, -4)
            icon:SetTexture(metaDef.icon)
            icon:SetTexCoord(0.08, 0.92, 0.08, 0.92)
            if not metaComplete then
                icon:SetDesaturated(true)
                icon:SetAlpha(0.65)
            end

            local titleFs = row:CreateFontString(nil, "OVERLAY", "GameFontNormalLarge")
            titleFs:SetPoint("TOPLEFT", icon, "TOPRIGHT", 10, -2)
            titleFs:SetWidth(row:GetWidth() - 58)
            titleFs:SetJustifyH("LEFT")
            UI.SafeSetFont(titleFs, fontPath, 15, "GameFontNormalLarge")
            titleFs:SetTextColor(tr, tg, tb)
            titleFs:SetText(metaDef.name)

            local statusFs = row:CreateFontString(nil, "OVERLAY", "GameFontHighlightSmall")
            statusFs:SetPoint("TOPLEFT", titleFs, "BOTTOMLEFT", 0, -4)
            statusFs:SetWidth(row:GetWidth() - 58)
            statusFs:SetJustifyH("LEFT")
            UI.SafeSetFont(statusFs, fontPath, 12, "GameFontHighlightSmall")
            if metaComplete then
                statusFs:SetText("|cFF66FF66Complete|r  |cFFFFFF00+" .. (metaDef.points or 0) .. " account pts|r")
            else
                statusFs:SetText("|cFFFFAA66Incomplete|r — complete every other challenge below")
            end

            local descFs = row:CreateFontString(nil, "OVERLAY", "GameFontHighlightSmall")
            descFs:SetPoint("TOPLEFT", statusFs, "BOTTOMLEFT", 0, -3)
            descFs:SetWidth(row:GetWidth() - 58)
            descFs:SetJustifyH("LEFT")
            UI.SafeSetFont(descFs, fontPath, 11, "GameFontHighlightSmall")
            descFs:SetTextColor(r0 * 0.9, g0 * 0.9, b0 * 0.9)
            descFs:SetText(metaDef.description)

            local rowH = math.max(52, titleFs:GetStringHeight() + statusFs:GetStringHeight()
                + descFs:GetStringHeight() + 28)
            row:SetHeight(rowH)
            row:SetPoint("TOPLEFT", contentFrame, "TOPLEFT", 0, y)
            y = y - rowH - 14
        end

        local keys = SortedHubKeysExcludingMeta(hubKeys)

        if #keys == 0 then
            local row = CreateFrame("Frame", nil, contentFrame)
            row:SetWidth(contentFrame:GetWidth() > 0 and contentFrame:GetWidth() or 380)
            local fs = row:CreateFontString(nil, "OVERLAY", "GameFontHighlight")
            fs:SetPoint("TOPLEFT", row, "TOPLEFT", 8, -4)
            fs:SetWidth(row:GetWidth() - 16)
            fs:SetJustifyH("LEFT")
            UI.SafeSetFont(fs, fontPath, 13, "GameFontHighlight")
            fs:SetTextColor(r0, g0, b0)
            fs:SetText("No other hub completions yet.")
            row:SetHeight(fs:GetStringHeight() + 12)
            row:SetPoint("TOPLEFT", contentFrame, "TOPLEFT", 0, y)
            y = y - row:GetHeight() - 8
        else
            for _, key in ipairs(keys) do
                local ch = addon.Challenges[key]
                if ch then
                    local row = CreateFrame("Frame", nil, contentFrame)
                    row:SetWidth(contentFrame:GetWidth() > 0 and contentFrame:GetWidth() or 380)

                    local icon = row:CreateTexture(nil, "ARTWORK")
                    icon:SetSize(36, 36)
                    icon:SetPoint("TOPLEFT", row, "TOPLEFT", 4, -4)
                    icon:SetTexture(ch.icon)
                    icon:SetTexCoord(0.08, 0.92, 0.08, 0.92)

                    local titleFs = row:CreateFontString(nil, "OVERLAY", "GameFontNormalLarge")
                    titleFs:SetPoint("TOPLEFT", icon, "TOPRIGHT", 10, -2)
                    titleFs:SetWidth(row:GetWidth() - 54)
                    titleFs:SetJustifyH("LEFT")
                    UI.SafeSetFont(titleFs, fontPath, 14, "GameFontNormalLarge")
                    titleFs:SetTextColor(tr, tg, tb)
                    titleFs:SetText(ch.name)

                    local ptsFs = row:CreateFontString(nil, "OVERLAY", "GameFontHighlightSmall")
                    ptsFs:SetPoint("TOPLEFT", titleFs, "BOTTOMLEFT", 0, -2)
                    ptsFs:SetWidth(row:GetWidth() - 54)
                    ptsFs:SetJustifyH("LEFT")
                    UI.SafeSetFont(ptsFs, fontPath, 12, "GameFontHighlightSmall")
                    ptsFs:SetTextColor(r0, g0, b0)
                    ptsFs:SetText("|cFFFFFF00+" .. (ch.points or 0) .. " account pts|r")

                    local rowH = math.max(44, titleFs:GetStringHeight() + ptsFs:GetStringHeight() + 20)
                    row:SetHeight(rowH)
                    row:SetPoint("TOPLEFT", contentFrame, "TOPLEFT", 0, y)
                    y = y - rowH - 10
                end
            end
        end

        contentFrame:SetHeight(math.max(1, -y))
        if root._scroll then
            root._scroll:SetVerticalScroll(0)
        end
    end

    addon:HubSyncMetaChallenge()
    root._layoutHub()
    totalLabel:SetText("|cFFFFFF00Account points: " .. addon:HubGetTotalPoints() .. "|r")

    local viewBtn = CreateFrame("Button", nil, foot, "UIPanelButtonTemplate")
    viewBtn:SetSize(96, 22)
    viewBtn:SetPoint("RIGHT", foot, "RIGHT", -14, 6)
    root._hubViewBtn = viewBtn

    local function accountPointsFromHubMap(hubMap)
        local total = 0
        for key, completed in pairs(hubMap or {}) do
            if completed and addon.Challenges[key] then
                total = total + (addon.Challenges[key].points or 0)
            end
        end
        return total
    end

    local function refreshHubViewLabel()
        local profile = root._hubViewMode == VIEW_TARGET and addon:GetRemoteProfileByName(root._hubViewName) or nil
        if profile then
            viewBtn:SetText("Self")
            if root._totalLabel then
                root._totalLabel:SetText("|cFFFFFF00Account points (" .. (root._hubViewName or "?") .. "): "
                    .. accountPointsFromHubMap(profile.hubCompletedKeys) .. "|r")
            end
        else
            root._hubViewMode = VIEW_SELF
            root._hubViewName = nil
            viewBtn:SetText("Target")
            if root._totalLabel then
                root._totalLabel:SetText("|cFFFFFF00Account points: " .. addon:HubGetTotalPoints() .. "|r")
            end
        end
    end
    root._refreshHubViewLabel = refreshHubViewLabel

    viewBtn:SetScript("OnClick", function()
        if root._hubViewMode == VIEW_TARGET then
            root._hubViewMode = VIEW_SELF
            root._hubViewName = nil
            root._layoutHub()
            refreshHubViewLabel()
            return
        end
        if UnitExists("target") and UnitIsPlayer("target")
            and not (UnitIsUnitSafe and UnitIsUnitSafe("target", "player"))
        then
            local tname = GetUnitName("target", true) or UnitName("target")
            if addon.RequestRemoteProfileForUnit then
                addon:RequestRemoteProfileForUnit("target")
            end
            local profile = addon:GetRemoteProfileByName(tname)
            if profile then
                root._hubViewMode = VIEW_TARGET
                root._hubViewName = profile.name or tname
                root._layoutHub()
                refreshHubViewLabel()
            else
                UIErrorsFrame:AddMessage("No target profile yet. Wait a moment and press again.", 1, 0.4, 0)
            end
        else
            UIErrorsFrame:AddMessage("Target another player first.", 1, 0.4, 0)
        end
    end)
    refreshHubViewLabel()

    self.hubWindow = root
end
