-- ui/active_challenges.lua

local addon = HardcoreChallenges
local UI = addon.UI
local VIEW_SELF = "self"
local VIEW_TARGET = "target"
local UnitIsUnitSafe = _G.UnitIsUnit

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

    local body = root.Body
    local tabBar = CreateFrame("Frame", nil, body)
    tabBar:SetHeight(28)
    tabBar:SetPoint("TOPLEFT", body, "TOPLEFT", 0, 0)
    tabBar:SetPoint("TOPRIGHT", body, "TOPRIGHT", 0, 0)

    local panelHost = CreateFrame("Frame", nil, body)
    panelHost:SetPoint("TOPLEFT", tabBar, "BOTTOMLEFT", 0, -4)
    panelHost:SetPoint("BOTTOMRIGHT", body, "BOTTOMRIGHT", 0, 0)
    root._challengesViewMode = VIEW_SELF
    root._challengesViewName = nil

    local scroll, content = self:CreateBodyScroll(panelHost)
    root._scroll = scroll
    root._content = content

    local titlesScroll, titlesContent = self:CreateBodyScroll(panelHost)
    titlesScroll:Hide()
    root._titlesScroll = titlesScroll
    root._titlesContent = titlesContent

    local btnChallenges = CreateFrame("Button", nil, tabBar, "UIPanelButtonTemplate")
    btnChallenges:SetSize(128, 22)
    btnChallenges:SetPoint("LEFT", tabBar, "LEFT", 4, 0)
    local btnTitles = CreateFrame("Button", nil, tabBar, "UIPanelButtonTemplate")
    btnTitles:SetSize(128, 22)
    btnTitles:SetPoint("LEFT", btnChallenges, "RIGHT", 8, 0)

    root._currentTab = "challenges"

    local function setTabVisual(which)
        if which == "challenges" then
            btnChallenges:SetText("|cFFCCFFCCChallenges|r")
            btnTitles:SetText("Titles")
        else
            btnChallenges:SetText("Challenges")
            btnTitles:SetText("|cFFCCFFCCTitles|r")
        end
    end

    local function showTab(which)
        root._currentTab = which
        if which == "challenges" then
            scroll:Show()
            titlesScroll:Hide()
        else
            scroll:Hide()
            titlesScroll:Show()
            if root._layoutTitles then
                root._layoutTitles()
            end
        end
        setTabVisual(which)
    end

    btnChallenges:SetScript("OnClick", function()
        showTab("challenges")
    end)
    btnTitles:SetScript("OnClick", function()
        showTab("titles")
    end)
    showTab("challenges")

    function root._layoutTitles()
        UI:LayoutTitlesTab(root._titlesContent)
    end

    local foot = root.Footer
    local fontPath = root._pointFontPath
    local r0, g0, b0 = self.GetTitleTextColor()
    local tr, tg, tb = self.GetPlayerClassColor()

    local hubBtn = CreateFrame("Button", nil, foot, "UIPanelButtonTemplate")
    hubBtn:SetSize(72, 22)
    hubBtn:SetPoint("LEFT", foot, "LEFT", 14, -6)
    hubBtn:SetText("Hub")
    hubBtn:SetScript("OnClick", function()
        UI:ShowHub()
    end)

    local pointsLabel = foot:CreateFontString(nil, "OVERLAY", "GameFontHighlightLarge")
    pointsLabel:SetPoint("CENTER", foot, "CENTER", 0, 12)
    UI.SafeSetFont(pointsLabel, fontPath, 18, "GameFontHighlightLarge")
    root._pointsFooter = pointsLabel

    function root._layoutRows()
        local db = addon.CharDB
        local viewMode = root._challengesViewMode or VIEW_SELF
        local profile = viewMode == VIEW_TARGET and addon.GetRemoteProfileByName and addon:GetRemoteProfileByName(root._challengesViewName) or nil
        local activeMap = (profile and profile.activeChallenges) or db.activeChallenges
        local isRemote = profile and true or false
        local contentFrame = root._content
        if not contentFrame then return end

        for _, child in ipairs({ contentFrame:GetChildren() }) do
            child:Hide()
            child:SetParent(nil)
        end

        local y = -6
        local sections = UI.GetChallengeSections()

        for _, sec in ipairs(sections) do
            local anyInSec = false
            for _, k in ipairs(sec.keys) do
                if activeMap[k] then
                    anyInSec = true
                    break
                end
            end
            if not anyInSec then
                -- skip whole category
            else
            local hdr = CreateFrame("Frame", nil, contentFrame)
            hdr:SetWidth(contentFrame:GetWidth() > 0 and contentFrame:GetWidth() or 400)
            hdr._isCategoryHeader = true
            local hdrFs = hdr:CreateFontString(nil, "OVERLAY", "GameFontNormalLarge")
            hdrFs:SetPoint("TOPLEFT", hdr, "TOPLEFT", 6, -4)
            hdrFs:SetWidth(hdr:GetWidth() - 12)
            hdrFs:SetJustifyH("LEFT")
            UI.SafeSetFont(hdrFs, fontPath, 14, "GameFontNormalLarge")
            hdrFs:SetTextColor(0.9, 0.75, 0.3)
            hdrFs:SetText(sec.title)
            local hh = math.max(22, hdrFs:GetStringHeight() + 8)
            hdr:SetHeight(hh)
            hdr:SetPoint("TOPLEFT", contentFrame, "TOPLEFT", 0, y)
            y = y - hh - 2

        for _, key in ipairs(sec.keys) do
            if activeMap[key] then
            local challenge = addon.Challenges[key]
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
            local pts = "|cFFFFFF00+" .. (challenge.points or 0) .. " points|r"
            local extra = ""

            if not isRemote and addon.IsSlayerChallengeKey and addon:IsSlayerChallengeKey(key) then
                local cur, goal = addon:GetSlayerProgressDisplay(key)
                local kcol = cur >= goal and "|cFF00FF00" or "|cFFFFFF00"
                extra = "\n" .. kcol .. "Kills: " .. cur .. "/" .. goal .. "|r"
                if cur >= goal then
                    pts = "|cFFFFFF00+" .. challenge.points .. " points (earned)|r"
                else
                    pts = "|cFFFFFF00+" .. challenge.points .. " points (at " .. goal .. " kills)|r"
                end
            elseif not isRemote and key == "SingleContinent" then
                local currentID = GetCurrentContinent()
                local currentName = currentID and addon:GetContinentName(currentID) or "Unknown"
                local startName = db.startContinent and addon:GetContinentName(db.startContinent) or "Unknown"

                local color = "|cFF00FF00"
                if db.startContinent and currentID and currentID ~= db.startContinent then
                    color = "|cFFFF0000"
                end
                extra = "\n|cFFFFFF00Starting: " .. startName .. "|r" ..
                        "\n" .. color .. "Current: " .. currentName .. "|r"
            elseif not isRemote and key == "CraftedLockedDuo" then
                local pn = db.craftedDuoPartner or ""
                extra = "\n|cFFFFFF00Partner: " .. (pn ~= "" and pn or "(not set)") .. "|r"
            elseif not isRemote and key == "CraftedLockedSolo" then
                extra = "\n|cFFFFFF00Solo: only your own crafts.|r"
            elseif not isRemote and key == "SingleSpec" then
                local st = addon:GetSingleSpecTalentState()
                if st.treeCount == 0 then
                    extra = "\n|cFFFFFF00Talent tree: none yet|r"
                elseif st.treeCount == 1 then
                    extra = "\n|cFF00FF00Talent tree: " .. (st.primaryName or "?") .. "|r"
                else
                    extra = "\n|cFFFF0000Points in " .. st.treeCount .. " trees|r"
                end
            elseif not isRemote and key == "DungeonOnce" then
                local seen = db.dungeonOnceSeenMapIds or {}
                local n = 0
                for _ in pairs(seen) do
                    n = n + 1
                end
                extra = "\n|cFFFFFF00Unique dungeons entered: " .. n .. "|r"
            end

            local status = (not isRemote) and db.failedChallenges[key]
            local hubDone
            if isRemote then
                hubDone = profile and profile.hubCompletedKeys and profile.hubCompletedKeys[key]
            else
                hubDone = addon:HubEnsure().completedKeys[key] and true or false
            end
            local statusStr
            if status then
                statusStr = "|cFFFF4444Failed|r"
            elseif hubDone then
                statusStr = "|cFF66FF66Complete|r"
            elseif not isRemote and addon.IsSlayerChallengeKey and addon:IsSlayerChallengeKey(key) then
                local cur = select(1, addon:GetSlayerProgressDisplay(key))
                local goal = addon.GetSlayerGoal and addon:GetSlayerGoal() or 10000
                statusStr = cur >= goal and "|cFF66FF66Complete|r" or "|cFF66FF66Active|r"
            else
                statusStr = "|cFF66FF66Active|r"
            end
            bodyFs:SetText(desc .. "\n" .. pts .. extra .. "\n" .. statusStr)

            local rowH = math.max(56, titleFs:GetStringHeight() + bodyFs:GetStringHeight() + 16)
            row:SetHeight(rowH)
            row:SetPoint("TOPLEFT", contentFrame, "TOPLEFT", 0, y)
            y = y - rowH - 10

            end
            end
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

    local viewBtn = CreateFrame("Button", nil, foot, "UIPanelButtonTemplate")
    viewBtn:SetSize(96, 22)
    viewBtn:SetPoint("LEFT", hubBtn, "RIGHT", 8, 0)
    root._viewBtn = viewBtn

    local function selectedPointsFromMap(map)
        local total = 0
        for key, enabled in pairs(map or {}) do
            if enabled and addon.Challenges[key] and not addon.Challenges[key].hubOnly then
                total = total + (addon.Challenges[key].points or 0)
            end
        end
        return total
    end

    local function refreshViewModeLabel()
        local profile = root._challengesViewMode == VIEW_TARGET and addon:GetRemoteProfileByName(root._challengesViewName) or nil
        if profile then
            viewBtn:SetText("Self")
            if root._pointsFooter then
                root._pointsFooter:SetText("|cFFFFFF00Selected points (" .. (root._challengesViewName or "?") .. "): "
                    .. selectedPointsFromMap(profile.activeChallenges) .. "|r")
            end
        else
            root._challengesViewMode = VIEW_SELF
            root._challengesViewName = nil
            viewBtn:SetText("Target")
            if root._pointsFooter then
                root._pointsFooter:SetText("|cFFFFFF00Total points: " .. addon:GetPoints() .. "|r")
            end
        end
    end
    root._refreshViewModeLabel = refreshViewModeLabel

    viewBtn:SetScript("OnClick", function()
        if root._challengesViewMode == VIEW_TARGET then
            root._challengesViewMode = VIEW_SELF
            root._challengesViewName = nil
            root._layoutRows()
            refreshViewModeLabel()
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
                root._challengesViewMode = VIEW_TARGET
                root._challengesViewName = profile.name or tname
                root._layoutRows()
                refreshViewModeLabel()
            else
                UIErrorsFrame:AddMessage("No target profile yet. Wait a moment and press again.", 1, 0.4, 0)
            end
        else
            UIErrorsFrame:AddMessage("Target another player first.", 1, 0.4, 0)
        end
    end)
    refreshViewModeLabel()

    self.activeWindow = root
end

function UI:UpdateActive()
    local root = self.activeWindow
    if not root or not root._layoutRows then return end
    root._layoutRows()
    if root._refreshViewModeLabel then
        root._refreshViewModeLabel()
    elseif root._pointsFooter then
        root._pointsFooter:SetText("|cFFFFFF00Total points: " .. addon:GetPoints() .. "|r")
    end
    if root._currentTab == "titles" and root._layoutTitles then
        root._layoutTitles()
    end
end
