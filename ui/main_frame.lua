-- ui/main_frame.lua

local addon = HardcoreChallenges
local UI = addon.UI

local function strtrim(s)
    return (s or ""):gsub("^%s+", ""):gsub("%s+$", "")
end

function UI:ShowSelection()
    if not addon:IsChallengeConfigureLevel() then
        UIErrorsFrame:AddMessage(
            "Hardcore Challenges: you can only choose challenges at level 1. Open the Account Hub from the minimap.",
            1, 1, 0
        )
        return
    end

    local db = addon.CharDB

    if self.selectionWindow then
        self.selectionWindow:Show()
        self.selectionWindow:RefreshTheme()
        local content = self.selectionWindow._content
        if content then
            for _, child in ipairs({ content:GetChildren() }) do
                if child._challengeKey and child._checkbox then
                    child._checkbox:SetChecked(db.activeChallenges[child._challengeKey] and true or false)
                end
                if child._buildBodyText then
                    child._buildBodyText()
                end
            end
        end
        if self.selectionWindow._updatePoints then
            self.selectionWindow._updatePoints()
        end
        if self.selectionWindow._refreshCraftedMutex then
            self.selectionWindow._refreshCraftedMutex()
        end
        if self.selectionWindow._syncPartnerRow then
            self.selectionWindow._syncPartnerRow()
        end
        return
    end

    local frameName = "HardcoreChallenges_SelectionFrame"
    local root = self:CreateThemedWindow({
        name = frameName,
        title = "Select Challenges",
        width = 468,
        height = 520,
    })

    _G[frameName] = root
    tinsert(UISpecialFrames, frameName)
    root.Footer:SetHeight(100)

    local scroll, content = self:CreateBodyScroll(root.Body)
    root._scroll = scroll
    root._content = content

    local r0, g0, b0 = self.GetTitleTextColor()
    local fontPath = root._pointFontPath
    local tr, tg, tb = self.GetPlayerClassColor()

    local y = -6
    local sections = self.GetChallengeSections()

    for _, sec in ipairs(sections) do
        local hdr = CreateFrame("Frame", nil, content)
        hdr:SetWidth(content:GetWidth() > 0 and content:GetWidth() or 400)
        hdr._isCategoryHeader = true
        local hdrFs = hdr:CreateFontString(nil, "OVERLAY", "GameFontNormalLarge")
        hdrFs:SetPoint("TOPLEFT", hdr, "TOPLEFT", 4, -2)
        hdrFs:SetWidth(hdr:GetWidth() - 16)
        hdrFs:SetJustifyH("LEFT")
        self.SafeSetFont(hdrFs, fontPath, 14, "GameFontNormalLarge")
        hdrFs:SetTextColor(0.9, 0.75, 0.3)
        hdrFs:SetText(sec.title)
        local hh = math.max(22, hdrFs:GetStringHeight() + 8)
        hdr:SetHeight(hh)
        hdr:SetPoint("TOPLEFT", content, "TOPLEFT", 0, y)
        y = y - hh - 2

        for _, key in ipairs(sec.keys) do
        local challenge = addon:GetChallengesState()[key]
        if challenge then
        local row = CreateFrame("Frame", nil, content)
        row:SetWidth(content:GetWidth() > 0 and content:GetWidth() or 400)

        local iconBtn = CreateFrame("Button", nil, row)
        iconBtn:SetSize(44, 44)
        iconBtn:SetPoint("TOPLEFT", row, "TOPLEFT", 4, -4)
        iconBtn:SetNormalTexture(challenge.icon)
        iconBtn:SetHighlightTexture("Interface\\Buttons\\ButtonHilight-Square", "ADD")

        local titleFs = row:CreateFontString(nil, "OVERLAY", "GameFontNormalLarge")
        titleFs:SetPoint("TOPLEFT", iconBtn, "TOPRIGHT", 12, -2)
        titleFs:SetWidth(row:GetWidth() - 130)
        titleFs:SetJustifyH("LEFT")
        self.SafeSetFont(titleFs, fontPath, 15, "GameFontNormalLarge")
        titleFs:SetTextColor(tr, tg, tb)
        titleFs:SetText(challenge.name)

        local bodyFs = row:CreateFontString(nil, "OVERLAY", "GameFontHighlightSmall")
        bodyFs:SetPoint("TOPLEFT", titleFs, "BOTTOMLEFT", 0, -4)
        bodyFs:SetWidth(row:GetWidth() - 130)
        bodyFs:SetJustifyH("LEFT")
        bodyFs:SetWordWrap(true)
        self.SafeSetFont(bodyFs, fontPath, 12, "GameFontHighlightSmall")
        bodyFs:SetTextColor(r0, g0, b0)

        local function buildBodyText()
            local desc = challenge.description
            if key == "Exalted" and addon.GetExaltedChallengeDescription then
                desc = addon:GetExaltedChallengeDescription()
            end
            local pts = "|cFFFFFF00+" .. challenge.points .. " points|r"
            local extra = ""
            if addon.IsSlayerChallengeKey and addon:IsSlayerChallengeKey(key) then
                local cur, goal = addon:GetSlayerProgressDisplay(key)
                local kcol = cur >= goal and "|cFF00FF00" or "|cFFFFFF00"
                extra = "\n" .. kcol .. "Kills: " .. cur .. "/" .. goal .. "|r"
                if cur >= goal then
                    pts = "|cFFFFFF00+" .. challenge.points .. " points (earned)|r"
                else
                    pts = "|cFFFFFF00+" .. challenge.points .. " points (at " .. goal .. " kills)|r"
                end
            elseif key == "SingleContinent" then
                local currentID = addon:GetPlayerContinentMapId()
                local currentName = currentID and addon:GetContinentName(currentID) or "Unknown"

                if db.startContinent then
                    local startName = addon:GetContinentName(db.startContinent)
                    local color = "|cFF00FF00"
                    if currentID and currentID ~= db.startContinent then
                        color = "|cFFFF0000"
                    end
                    extra = "\n|cFFFFFF00Starting: " .. startName .. "|r" ..
                            "\n" .. color .. "Current: " .. currentName .. "|r"
                else
                    extra = "\n|cFFFFFF00Starting: will be set on start|r" ..
                            "\n|cFF00FF00Current: " .. currentName .. "|r"
                end
            elseif key == "SingleSpec" then
                local st = addon:GetSingleSpecTalentState()
                if st.treeCount == 0 then
                    extra = "\n|cFFFFFF00Talent tree: none yet (no points spent)|r"
                elseif st.treeCount == 1 then
                    extra = "\n|cFF00FF00Talent tree: " .. (st.primaryName or "?") .. "|r"
                else
                    extra = "\n|cFFFF0000Talent points in " .. st.treeCount ..
                        " trees — violates Single Spec (fail on start / while active).|r"
                end
            end
            bodyFs:SetText(desc .. "\n" .. pts .. extra)
        end
        buildBodyText()

        local cb = CreateFrame("CheckButton", nil, row, "UICheckButtonTemplate")
        cb:SetSize(20, 20)
        cb:SetPoint("TOPRIGHT", row, "TOPRIGHT", -10, -12)
        cb:SetHitRectInsets(-4, -4, -4, -4)
        local label = cb.text or cb.Text
        if label then
            label:SetText("")
            label:Hide()
        end
        self.ApplyThemedCheckbox(cb)
        cb:SetChecked(challenge.enabled)

        cb:SetScript("OnClick", function()
            db.activeChallenges[key] = cb:GetChecked() and true or false
            if key == "CraftedLockedSolo" and db.activeChallenges[key] then
                db.activeChallenges["CraftedLockedDuo"] = false
            elseif key == "CraftedLockedDuo" and db.activeChallenges[key] then
                db.activeChallenges["CraftedLockedSolo"] = false
            end
            if root._refreshCraftedMutex then root._refreshCraftedMutex() end
            if root._syncPartnerRow then root._syncPartnerRow() end
            if root._updatePoints then root._updatePoints() end
        end)

        iconBtn:SetScript("OnClick", function()
            cb:Click()
        end)

        row._challengeKey = key
        row._checkbox = cb
        row._buildBodyText = buildBodyText

        local rowH = math.max(56, titleFs:GetStringHeight() + bodyFs:GetStringHeight() + 28)
        row:SetHeight(rowH)
        row:SetPoint("TOPLEFT", content, "TOPLEFT", 0, y)
        y = y - rowH - 10
        end
        end
    end

    content:SetHeight(math.max(1, -y))

    local foot = root.Footer

    local partnerBlock = CreateFrame("Frame", nil, foot)
    partnerBlock:SetHeight(24)
    partnerBlock:SetPoint("TOPLEFT", foot, "TOPLEFT", 12, -4)
    partnerBlock:SetPoint("TOPRIGHT", foot, "TOPRIGHT", -12, -4)

    local partnerLabel = partnerBlock:CreateFontString(nil, "OVERLAY", "GameFontHighlightSmall")
    partnerLabel:SetPoint("LEFT", partnerBlock, "LEFT", 0, 0)
    self.SafeSetFont(partnerLabel, fontPath, 12, "GameFontHighlightSmall")
    partnerLabel:SetTextColor(r0, g0, b0)
    partnerLabel:SetText("Duo partner")

    local partnerEdit = CreateFrame("EditBox", nil, partnerBlock, "InputBoxTemplate")
    partnerEdit:SetSize(220, 18)
    partnerEdit:SetPoint("LEFT", partnerLabel, "RIGHT", 8, 0)
    partnerEdit:SetAutoFocus(false)
    partnerEdit:SetMaxLetters(50)
    partnerEdit:SetText(db.craftedDuoPartner or "")
    partnerEdit:SetScript("OnEditFocusLost", function(self)
        db.craftedDuoPartner = strtrim(self:GetText() or "")
    end)

    function root._syncPartnerRow()
        local show = db.activeChallenges["CraftedLockedDuo"] and true or false
        partnerBlock:SetShown(show)
        if show then
            partnerEdit:SetText(db.craftedDuoPartner or "")
        end
    end

    function root._refreshCraftedMutex()
        for _, child in ipairs({ content:GetChildren() }) do
            local k = child._challengeKey
            local cbx = child._checkbox
            if cbx and (k == "CraftedLockedSolo" or k == "CraftedLockedDuo") then
                cbx:SetChecked(db.activeChallenges[k] and true or false)
            end
        end
    end

    root._syncPartnerRow()

    local pointsLabel = foot:CreateFontString(nil, "OVERLAY", "GameFontHighlightLarge")
    pointsLabel:SetPoint("LEFT", foot, "LEFT", 20, 10)
    self.SafeSetFont(pointsLabel, fontPath, 16, "GameFontHighlightLarge")

    function root._updatePoints()
        pointsLabel:SetText("|cFFFFFF00Total: " .. addon:GetPoints() .. " pts|r")
    end
    root._updatePoints()

    local hubBtn = CreateFrame("Button", nil, foot, "UIPanelButtonTemplate")
    hubBtn:SetSize(96, 28)
    hubBtn:SetPoint("RIGHT", foot, "RIGHT", -158, 10)
    hubBtn:SetText("Hub")
    hubBtn:SetScript("OnClick", function()
        UI:ShowHub()
    end)

    local startBtn = CreateFrame("Button", nil, foot, "UIPanelButtonTemplate")
    startBtn:SetSize(132, 28)
    startBtn:SetPoint("RIGHT", foot, "RIGHT", -18, 10)
    startBtn:SetText("Start")
    startBtn:SetScript("OnClick", function()
        if not addon:IsChallengeConfigureLevel() then
            UIErrorsFrame:AddMessage("Hardcore Challenges: starting a run is only allowed at level 1.", 1, 0, 0)
            return
        end
        local crafted = db.activeChallenges["CraftedLockedSolo"] or db.activeChallenges["CraftedLockedDuo"]
        if crafted then
            if not addon:CraftedLockIsNakedForStart() then
                UIErrorsFrame:AddMessage("Crafted Lock: remove all armor, weapons, and equipped bags. Shirt and tabard may stay empty or any; bags in bag slots must be unequipped.", 1, 0, 0)
                return
            end
            if db.activeChallenges["CraftedLockedDuo"] then
                local pn = strtrim(partnerEdit:GetText() or "")
                if pn == "" then
                    UIErrorsFrame:AddMessage("Crafted Lock (Duo): enter your partner's character as Name or Name-Realm.", 1, 0, 0)
                    return
                end
                db.craftedDuoPartner = pn
            else
                db.craftedDuoPartner = ""
            end
            addon:CraftedLockOnChallengeStart()
        end

        if db.activeChallenges["SelfFound"] then
            if not addon:HasSelfFoundBuff() then
                db.failedChallenges["SelfFound"] = true
            end
        end

        if db.activeChallenges["SingleContinent"] then
            db.startContinent = addon:GetPlayerContinentMapId()
        end

        if addon.SingleSpecOnChallengeStart then
            addon:SingleSpecOnChallengeStart()
        end

        db.characterStarted = true
        root:Hide()
        UI:ShowActive()
    end)

    self.selectionWindow = root
end
