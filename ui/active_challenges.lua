-- ui/active_challenges.lua

local addon = HardcoreChallenges
local UI = addon.UI
local VIEW_SELF = "self"
local VIEW_TARGET = "target"
local UnitIsUnitSafe = _G.UnitIsUnit

local SORT_STATUS_ORDER = { "default", "failed_first", "complete_first" }
local SORT_POINTS_ORDER = { "none", "high_low", "low_high" }

local SORT_STATUS_BTN = {
    default = "Status: default",
    failed_first = "Status: failed | active | done",
    complete_first = "Status: done | active | failed",
}

local SORT_STATUS_TIP = {
    default = "Category order, then challenge name (default).",
    failed_first = "Failed challenges first, then active, then completed.",
    complete_first = "Completed first, then active, then failed.",
}

local SORT_POINTS_BTN = {
    none = "Points: default",
    high_low = "Points: high to low",
    low_high = "Points: low to high",
}

local SORT_POINTS_TIP = {
    none = "Tiebreaker: challenge name (when status sort is default, keeps category name order).",
    high_low = "More points first (after status order, if any).",
    low_high = "Fewer points first (after status order, if any).",
}

local function CycleSortMode(current, order)
    for i, v in ipairs(order) do
        if v == current then
            return order[(i % #order) + 1]
        end
    end
    return order[1]
end

local function NormalizeStatusSortMode(m)
    if m == "failed_first" or m == "complete_first" then return m end
    return "default"
end

local function NormalizePointsSortMode(m)
    if m == "high_low" or m == "low_high" then return m end
    return "none"
end

local function ChallengeRowComplete(key, db, profile, isRemote)
    if isRemote then
        return profile and profile.hubCompletedKeys and profile.hubCompletedKeys[key] and true or false
    end
    if addon:HubEnsure().completedKeys[key] then return true end
    if addon.IsSlayerChallengeKey and addon:IsSlayerChallengeKey(key) then
        local cur = select(1, addon:GetSlayerProgressDisplay(key))
        local goal = addon.GetSlayerGoal and addon:GetSlayerGoal() or 10000
        return cur >= goal
    end
    return false
end

local function ChallengeRowFailed(key, db, isRemote)
    if isRemote then return false end
    return db.failedChallenges[key] and true or false
end

local function StatusSortRank(key, statusMode, db, profile, isRemote)
    if statusMode == "default" then return 0 end
    local failed = ChallengeRowFailed(key, db, isRemote)
    local complete = ChallengeRowComplete(key, db, profile, isRemote)
    if statusMode == "failed_first" then
        if failed then return 1 end
        if complete then return 3 end
        return 2
    end
    if statusMode == "complete_first" then
        if complete then return 1 end
        if failed then return 3 end
        return 2
    end
    return 0
end

local function ChallengePoints(key)
    return (addon.Challenges[key] and addon.Challenges[key].points) or 0
end

local function ChallengeName(key)
    local c = addon.Challenges[key]
    return (c and c.name) or tostring(key)
end

local function CollectActiveKeysInSection(sec, activeMap)
    local out = {}
    for _, key in ipairs(sec.keys) do
        if activeMap[key] then
            out[#out + 1] = key
        end
    end
    return out
end

local function SortActiveKeysInSection(keys, statusMode, pointsMode, db, profile, isRemote)
    if #keys <= 1 then return end
    if statusMode == "default" and pointsMode == "none" then return end
    table.sort(keys, function(a, b)
        if statusMode ~= "default" then
            local sa = StatusSortRank(a, statusMode, db, profile, isRemote)
            local sb = StatusSortRank(b, statusMode, db, profile, isRemote)
            if sa ~= sb then
                return sa < sb
            end
        end
        if pointsMode == "high_low" then
            local pa, pb = ChallengePoints(a), ChallengePoints(b)
            if pa ~= pb then return pa > pb end
        elseif pointsMode == "low_high" then
            local pa, pb = ChallengePoints(a), ChallengePoints(b)
            if pa ~= pb then return pa < pb end
        end
        return ChallengeName(a) < ChallengeName(b)
    end)
end

local function AttachActiveWindowButtonTooltip(btn, title, bodyText, hintText)
    hintText = hintText or "Click to use."
    btn:SetScript("OnEnter", function(self)
        GameTooltip:SetOwner(self, "ANCHOR_TOPRIGHT")
        GameTooltip:AddLine(title, 1, 1, 1)
        if bodyText and bodyText ~= "" then
            GameTooltip:AddLine(bodyText, 0.85, 0.85, 0.85, true)
        end
        GameTooltip:AddLine(hintText, 0.6, 0.6, 0.6, true)
        GameTooltip:Show()
    end)
    btn:SetScript("OnLeave", function()
        GameTooltip:Hide()
    end)
end

function UI:ShowActive()
    local db = addon.CharDB
    if not db.characterStarted then
        UIErrorsFrame:AddMessage(
            "Hardcore Challenges: no challenge run in progress. Start a run at level 1 (minimap on a level 1 character).",
            1, 1, 0
        )
        return
    end

    if self.activeWindow then
        self:UpdateActive()
        if self.activeWindow._refreshSortButtonLabels then
            self.activeWindow:_refreshSortButtonLabels()
        end
        self.activeWindow:Show()
        self.activeWindow:RefreshTheme()
        return
    end

    local frameName = "HardcoreChallenges_ActiveFrame"
    local root = self:CreateThemedWindow({
        name = frameName,
        title = "Active Challenges",
        width = 468,
        height = 508,
        frameLevel = 5,
    })

    _G[frameName] = root
    tinsert(UISpecialFrames, frameName)

    local body = root.Body
    local tabBar = CreateFrame("Frame", nil, body)
    tabBar:SetHeight(28)
    tabBar:SetPoint("TOPLEFT", body, "TOPLEFT", 0, 0)
    tabBar:SetPoint("TOPRIGHT", body, "TOPRIGHT", 0, 0)

    local filterBar = CreateFrame("Frame", nil, body)
    filterBar:SetHeight(26)
    filterBar:SetPoint("TOPLEFT", tabBar, "BOTTOMLEFT", 0, -2)
    filterBar:SetPoint("TOPRIGHT", tabBar, "BOTTOMRIGHT", 0, -2)

    local panelHost = CreateFrame("Frame", nil, body)
    panelHost:SetPoint("TOPLEFT", filterBar, "BOTTOMLEFT", 0, -4)
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
            filterBar:Show()
        else
            scroll:Hide()
            titlesScroll:Show()
            filterBar:Hide()
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
    AttachActiveWindowButtonTooltip(
        btnChallenges,
        "Challenges",
        "Your active challenges with descriptions, progress, and status (failed, active, or complete)."
    )
    AttachActiveWindowButtonTooltip(
        btnTitles,
        "Titles",
        "Display titles you can show above your character name (account unlocks and selection)."
    )
    showTab("challenges")

    local btnSortStatus = CreateFrame("Button", nil, filterBar, "UIPanelButtonTemplate")
    btnSortStatus:SetHeight(22)
    btnSortStatus:SetPoint("TOPLEFT", filterBar, "TOPLEFT", 2, -2)
    btnSortStatus:SetPoint("TOPRIGHT", filterBar, "TOP", -3, -2)
    local btnSortPoints = CreateFrame("Button", nil, filterBar, "UIPanelButtonTemplate")
    btnSortPoints:SetHeight(22)
    btnSortPoints:SetPoint("TOPLEFT", filterBar, "TOP", 3, -2)
    btnSortPoints:SetPoint("TOPRIGHT", filterBar, "TOPRIGHT", -2, -2)
    root._btnSortStatus = btnSortStatus
    root._btnSortPoints = btnSortPoints

    btnSortStatus:SetScript("OnEnter", function(self)
        local db = addon.CharDB
        local sm = NormalizeStatusSortMode(db and db.activeChallengesSortStatus)
        GameTooltip:SetOwner(self, "ANCHOR_TOPRIGHT")
        GameTooltip:AddLine("Sort by status", 1, 1, 1)
        GameTooltip:AddLine(SORT_STATUS_TIP[sm] or "", 0.85, 0.85, 0.85, true)
        GameTooltip:AddLine("Click to cycle options.", 0.6, 0.6, 0.6, true)
        GameTooltip:Show()
    end)
    btnSortStatus:SetScript("OnLeave", function()
        GameTooltip:Hide()
    end)
    btnSortPoints:SetScript("OnEnter", function(self)
        local db = addon.CharDB
        local pm = NormalizePointsSortMode(db and db.activeChallengesSortPoints)
        GameTooltip:SetOwner(self, "ANCHOR_TOPRIGHT")
        GameTooltip:AddLine("Sort by points", 1, 1, 1)
        GameTooltip:AddLine(SORT_POINTS_TIP[pm] or "", 0.85, 0.85, 0.85, true)
        GameTooltip:AddLine("Click to cycle options.", 0.6, 0.6, 0.6, true)
        GameTooltip:Show()
    end)
    btnSortPoints:SetScript("OnLeave", function()
        GameTooltip:Hide()
    end)

    function root._refreshSortButtonLabels()
        local db = addon.CharDB
        if not db then return end
        local sm = NormalizeStatusSortMode(db.activeChallengesSortStatus)
        local pm = NormalizePointsSortMode(db.activeChallengesSortPoints)
        db.activeChallengesSortStatus = sm
        db.activeChallengesSortPoints = pm
        btnSortStatus:SetText(SORT_STATUS_BTN[sm] or SORT_STATUS_BTN.default)
        btnSortPoints:SetText(SORT_POINTS_BTN[pm] or SORT_POINTS_BTN.none)
    end

    btnSortStatus:SetScript("OnClick", function()
        local db = addon.CharDB
        if not db then return end
        db.activeChallengesSortStatus = CycleSortMode(
            NormalizeStatusSortMode(db.activeChallengesSortStatus),
            SORT_STATUS_ORDER
        )
        root._refreshSortButtonLabels()
        root._layoutRows()
    end)
    btnSortPoints:SetScript("OnClick", function()
        local db = addon.CharDB
        if not db then return end
        db.activeChallengesSortPoints = CycleSortMode(
            NormalizePointsSortMode(db.activeChallengesSortPoints),
            SORT_POINTS_ORDER
        )
        root._refreshSortButtonLabels()
        root._layoutRows()
    end)
    root._refreshSortButtonLabels()

    function root._layoutTitles()
        UI:LayoutTitlesTab(root._titlesContent)
    end

    local foot = root.Footer
    local fontPath = root._pointFontPath
    local r0, g0, b0 = self.GetTitleTextColor()
    local tr, tg, tb = self.GetPlayerClassColor()

    local hubBtn = CreateFrame("Button", nil, foot, "UIPanelButtonTemplate")
    hubBtn:SetSize(64, 22)
    hubBtn:SetPoint("LEFT", foot, "LEFT", 10, -6)
    hubBtn:SetText("Hub")
    hubBtn:SetScript("OnClick", function()
        UI:ShowHub()
    end)
    AttachActiveWindowButtonTooltip(
        hubBtn,
        "Account Hub",
        "Account-wide completed challenges, total points, and meta progress."
    )

    local statsBtn = CreateFrame("Button", nil, foot, "UIPanelButtonTemplate")
    statsBtn:SetSize(64, 22)
    statsBtn:SetPoint("LEFT", hubBtn, "RIGHT", 6, 0)
    statsBtn:SetText("Stats")
    statsBtn:SetScript("OnClick", function()
        UI:ShowRunStats()
    end)
    AttachActiveWindowButtonTooltip(
        statsBtn,
        "Run statistics",
        "This character's run: mobs killed, quests turned in, and gold acquired (tracked by the addon since run start)."
    )
    root._statsBtn = statsBtn

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
        local statusSortMode = NormalizeStatusSortMode(db.activeChallengesSortStatus)
        local pointsSortMode = NormalizePointsSortMode(db.activeChallengesSortPoints)
        db.activeChallengesSortStatus = statusSortMode
        db.activeChallengesSortPoints = pointsSortMode

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

            local rowKeys = CollectActiveKeysInSection(sec, activeMap)
            SortActiveKeysInSection(rowKeys, statusSortMode, pointsSortMode, db, profile, isRemote)
            for _, key in ipairs(rowKeys) do
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
            if key == "Exalted" and addon.GetExaltedChallengeDescription then
                desc = addon:GetExaltedChallengeDescription()
            end
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
                local currentID = addon:GetPlayerContinentMapId()
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
                local nid = addon.CraftedLockCountAllowedItemIds and addon:CraftedLockCountAllowedItemIds() or 0
                extra = "\n|cFFFFFF00Partner: " .. (pn ~= "" and pn or "(not set)") .. "|r"
                    .. "\n|cFFFFFF00Allow list: " .. tostring(nid) .. " items|r"
            elseif not isRemote and key == "CraftedLockedSolo" then
                local nid = addon.CraftedLockCountAllowedItemIds and addon:CraftedLockCountAllowedItemIds() or 0
                extra = "\n|cFFFFFF00Allow list: " .. tostring(nid) .. " items|r"
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
    viewBtn:SetSize(88, 22)
    viewBtn:SetPoint("LEFT", statsBtn, "RIGHT", 6, 0)
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
            if root._statsBtn then
                root._statsBtn:Hide()
            end
            if root._pointsFooter then
                root._pointsFooter:SetText("|cFFFFFF00Selected points (" .. (root._challengesViewName or "?") .. "): "
                    .. selectedPointsFromMap(profile.activeChallenges) .. "|r")
            end
        else
            root._challengesViewMode = VIEW_SELF
            root._challengesViewName = nil
            viewBtn:SetText("Target")
            if root._statsBtn then
                root._statsBtn:Show()
            end
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
    viewBtn:SetScript("OnEnter", function(self)
        GameTooltip:SetOwner(self, "ANCHOR_TOPRIGHT")
        if root._challengesViewMode == VIEW_TARGET then
            GameTooltip:AddLine("Self view", 1, 1, 1)
            GameTooltip:AddLine(
                "Return to your challenges, sort filters, and your account points total in the footer.",
                0.85,
                0.85,
                0.85,
                true
            )
        else
            GameTooltip:AddLine("Target view", 1, 1, 1)
            GameTooltip:AddLine(
                "Target another player who uses this addon, then click to load their shared challenges and hub completions.",
                0.85,
                0.85,
                0.85,
                true
            )
        end
        GameTooltip:AddLine("Click to use.", 0.6, 0.6, 0.6, true)
        GameTooltip:Show()
    end)
    viewBtn:SetScript("OnLeave", function()
        GameTooltip:Hide()
    end)
    refreshViewModeLabel()

    self.activeWindow = root
    root:Show()
end

function UI:UpdateActive()
    local root = self.activeWindow
    if not root or not root._layoutRows then return end
    root._layoutRows()
    if root._refreshSortButtonLabels then
        root:_refreshSortButtonLabels()
    end
    if root._refreshViewModeLabel then
        root._refreshViewModeLabel()
    elseif root._pointsFooter then
        root._pointsFooter:SetText("|cFFFFFF00Total points: " .. addon:GetPoints() .. "|r")
    end
    if root._currentTab == "titles" and root._layoutTitles then
        root._layoutTitles()
    end
    if self.RefreshRunStats then
        self:RefreshRunStats()
    end
end
