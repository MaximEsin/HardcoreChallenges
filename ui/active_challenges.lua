-- ui/active_challenges.lua

local addon = HardcoreChallenges
local UI = addon.UI

local function GetCurrentContinent()
    local mapID = C_Map.GetBestMapForUnit("player")
    if not mapID then return nil end

    local info = C_Map.GetMapInfo(mapID)
    if not info then return nil end

    return info.parentMapID or mapID
end

function UI:ShowActive()
    if self.activeWindow then
        self:UpdateActive()
        self.activeWindow:Show()
        self.activeWindow:RefreshTheme()
        return
    end

    local frameName = "HardcoreChallenges_ActiveFrame"
    local root = self:CreateThemedWindow({
        name = frameName,
        title = "Active Challenges",
        width = 468,
        height = 480,
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

    local pointsLabel = foot:CreateFontString(nil, "OVERLAY", "GameFontHighlightLarge")
    pointsLabel:SetPoint("CENTER", foot, "CENTER", 0, 6)
    UI.SafeSetFont(pointsLabel, fontPath, 18, "GameFontHighlightLarge")
    root._pointsFooter = pointsLabel

    function root._layoutRows()
        local db = addon.CharDB
        local contentFrame = root._content
        if not contentFrame then return end

        for _, child in ipairs({ contentFrame:GetChildren() }) do
            child:Hide()
            child:SetParent(nil)
        end

        local y = -6
        local order = UI.SortedChallengeKeys()

        for _, key in ipairs(order) do
            if db.activeChallenges[key] then
            local challenge = addon:GetChallengesState()[key]
            if challenge then

            local row = CreateFrame("Frame", nil, contentFrame)
            row:SetWidth(contentFrame:GetWidth() > 0 and contentFrame:GetWidth() or 400)

            local icon = row:CreateTexture(nil, "ARTWORK")
            icon:SetSize(44, 44)
            icon:SetPoint("TOPLEFT", row, "TOPLEFT", 6, -6)
            icon:SetTexture(challenge.icon)
            icon:SetTexCoord(0.08, 0.92, 0.08, 0.92)

            local titleFs = row:CreateFontString(nil, "OVERLAY", "GameFontNormalLarge")
            titleFs:SetPoint("TOPLEFT", icon, "TOPRIGHT", 12, -2)
            titleFs:SetWidth(row:GetWidth() - 36)
            titleFs:SetJustifyH("LEFT")
            UI.SafeSetFont(titleFs, fontPath, 15, "GameFontNormalLarge")
            titleFs:SetTextColor(tr, tg, tb)
            titleFs:SetText(challenge.name)

            local bodyFs = row:CreateFontString(nil, "OVERLAY", "GameFontHighlightSmall")
            bodyFs:SetPoint("TOPLEFT", titleFs, "BOTTOMLEFT", 0, -4)
            bodyFs:SetWidth(row:GetWidth() - 36)
            bodyFs:SetJustifyH("LEFT")
            UI.SafeSetFont(bodyFs, fontPath, 12, "GameFontHighlightSmall")
            bodyFs:SetTextColor(r0, g0, b0)

            local desc = challenge.description
            local pts = "|cFFFFFF00+" .. challenge.points .. " points|r"
            local extra = ""

            if key == "SingleContinent" then
                local currentID = GetCurrentContinent()
                local currentName = currentID and addon:GetContinentName(currentID) or "Unknown"
                local startName = db.startContinent and addon:GetContinentName(db.startContinent) or "Unknown"

                local color = "|cFF00FF00"
                if db.startContinent and currentID and currentID ~= db.startContinent then
                    color = "|cFFFF0000"
                end
                extra = "\n|cFFFFFF00Starting: " .. startName .. "|r" ..
                        "\n" .. color .. "Current: " .. currentName .. "|r"
            elseif key == "CraftedLockedDuo" then
                local pn = db.craftedDuoPartner or ""
                extra = "\n|cFFFFFF00Partner: " .. (pn ~= "" and pn or "(not set)") .. "|r"
            elseif key == "CraftedLockedSolo" then
                extra = "\n|cFFFFFF00Solo: only your own crafts.|r"
            end

            local status = db.failedChallenges[key]
            local statusStr = status and "|cFFFF4444Failed|r" or "|cFF66FF66Active|r"
            bodyFs:SetText(desc .. "\n" .. pts .. extra .. "\n" .. statusStr)

            local rowH = math.max(56, titleFs:GetStringHeight() + bodyFs:GetStringHeight() + 16)
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

    root._layoutRows()
    if root._pointsFooter then
        root._pointsFooter:SetText("|cFFFFFF00Total points: " .. addon:GetPoints() .. "|r")
    end

    self.activeWindow = root
end

function UI:UpdateActive()
    local root = self.activeWindow
    if not root or not root._layoutRows then return end
    root._layoutRows()
    if root._pointsFooter then
        root._pointsFooter:SetText("|cFFFFFF00Total points: " .. addon:GetPoints() .. "|r")
    end
end
