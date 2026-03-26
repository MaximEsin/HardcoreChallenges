-- ui/hub_frame.lua — account-wide challenge completions.

local addon = HardcoreChallenges
local UI = addon.UI

local function SortedHubKeys()
    local hub = addon:HubEnsure()
    local keys = {}
    for k in pairs(hub.completedKeys) do
        if addon.Challenges[k] then
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
    root._layoutHub()
    if root._totalLabel then
        root._totalLabel:SetText("|cFFFFFF00Account points: " .. addon:HubGetTotalPoints() .. "|r")
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
        local keys = SortedHubKeys()

        if #keys == 0 then
            local row = CreateFrame("Frame", nil, contentFrame)
            row:SetWidth(contentFrame:GetWidth() > 0 and contentFrame:GetWidth() or 380)
            local fs = row:CreateFontString(nil, "OVERLAY", "GameFontHighlight")
            fs:SetPoint("TOPLEFT", row, "TOPLEFT", 8, -4)
            fs:SetWidth(row:GetWidth() - 16)
            fs:SetJustifyH("LEFT")
            UI.SafeSetFont(fs, fontPath, 13, "GameFontHighlight")
            fs:SetTextColor(r0, g0, b0)
            fs:SetText("No challenges completed on this account yet.")
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

    root._layoutHub()
    totalLabel:SetText("|cFFFFFF00Account points: " .. addon:HubGetTotalPoints() .. "|r")

    self.hubWindow = root
end
