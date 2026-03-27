-- ui/titles_panel.lua — вкладка выбора звания (завершённые в Account Hub челленджи).

local addon = HardcoreChallenges
local UI = addon.UI

function UI:LayoutTitlesTab(contentFrame)
    if not contentFrame then return end

    for _, child in ipairs({ contentFrame:GetChildren() }) do
        child:Hide()
        child:SetParent(nil)
    end

    local fontPath = self.activeWindow and self.activeWindow._pointFontPath
    local r0, g0, b0 = self.GetTitleTextColor()
    local tr, tg, tb = self.GetPlayerClassColor()

    local keys = addon:GetUnlockedTitleKeys()
    local y = -8
    local sel = addon:GetSelectedDisplayTitleKey()

    local function makeRow(label, key, iconTex)
        local row = CreateFrame("Frame", nil, contentFrame)
        row:SetWidth(contentFrame:GetWidth() > 0 and contentFrame:GetWidth() or 400)

        local cb = CreateFrame("CheckButton", nil, row, "UICheckButtonTemplate")
        cb:SetSize(20, 20)
        cb:SetPoint("TOPLEFT", row, "TOPLEFT", 6, -4)
        cb:SetHitRectInsets(-4, -4, -4, -4)
        local lbl = cb.text or cb.Text
        if lbl then
            lbl:SetText("")
            lbl:Hide()
        end
        self.ApplyThemedCheckbox(cb)

        local icon = row:CreateTexture(nil, "ARTWORK")
        icon:SetSize(36, 36)
        icon:SetPoint("TOPLEFT", cb, "TOPRIGHT", 8, 2)
        if iconTex then
            icon:SetTexture(iconTex)
            icon:SetTexCoord(0.08, 0.92, 0.08, 0.92)
        else
            icon:SetTexture("Interface\\Icons\\INV_Misc_QuestionMark")
        end

        local titleFs = row:CreateFontString(nil, "OVERLAY", "GameFontNormalLarge")
        titleFs:SetPoint("TOPLEFT", icon, "TOPRIGHT", 10, -2)
        titleFs:SetWidth(row:GetWidth() - 80)
        titleFs:SetJustifyH("LEFT")
        self.SafeSetFont(titleFs, fontPath, 15, "GameFontNormalLarge")
        titleFs:SetTextColor(tr, tg, tb)
        titleFs:SetText(label)

        local subFs = row:CreateFontString(nil, "OVERLAY", "GameFontHighlightSmall")
        subFs:SetPoint("TOPLEFT", titleFs, "BOTTOMLEFT", 0, -3)
        subFs:SetWidth(row:GetWidth() - 80)
        subFs:SetJustifyH("LEFT")
        self.SafeSetFont(subFs, fontPath, 11, "GameFontHighlightSmall")
        subFs:SetTextColor(r0 * 0.85, g0 * 0.85, b0 * 0.85)
        if key then
            subFs:SetText("Shown to other players with this addon (guild / party / whisper).")
        else
            subFs:SetText("No prefix on nameplates or tooltip.")
        end

        cb._titleKey = key
        cb:SetChecked(sel == key)

        cb:SetScript("OnClick", function(self)
            addon:SetSelectedDisplayTitleKey(self._titleKey)
            sel = addon:GetSelectedDisplayTitleKey()
            for _, ch in ipairs({ contentFrame:GetChildren() }) do
                local c = ch._radio
                if c then
                    local k = c._titleKey
                    local on = (k == nil and sel == nil) or (k ~= nil and sel == k)
                    c:SetChecked(on)
                end
            end
        end)

        row._radio = cb
        row:SetHeight(52)
        row:SetPoint("TOPLEFT", contentFrame, "TOPLEFT", 0, y)
        y = y - 56
        return row
    end

    makeRow("None (hide title)", nil, nil)

    if #keys == 0 then
        local hint = contentFrame:CreateFontString(nil, "OVERLAY", "GameFontHighlightSmall")
        hint:SetPoint("TOPLEFT", contentFrame, "TOPLEFT", 8, y + 8)
        hint:SetWidth(contentFrame:GetWidth() > 0 and contentFrame:GetWidth() - 16 or 380)
        hint:SetJustifyH("LEFT")
        self.SafeSetFont(hint, fontPath, 12, "GameFontHighlightSmall")
        hint:SetTextColor(r0, g0, b0)
        hint:SetText("No titles unlocked yet. Complete challenges on this account (Account Hub) to choose a title.")
        y = y - 40
    end

    for _, key in ipairs(keys) do
        local def = addon.Challenges[key]
        local disp = addon:GetDisplayTitleForKey(key) or key
        local label = "|cFFFFD100" .. disp .. "|r  (" .. (def and def.name or key) .. ")"
        makeRow(label, key, def and def.icon)
    end

    contentFrame:SetHeight(math.max(1, -y + 8))
    if self.activeWindow and self.activeWindow._titlesScroll then
        self.activeWindow._titlesScroll:SetVerticalScroll(0)
    end
end

function UI:RefreshTitlesTab()
    local root = self.activeWindow
    if not root or not root._layoutTitles then return end
    root._layoutTitles()
end
