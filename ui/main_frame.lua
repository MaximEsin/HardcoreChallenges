local addon = HardcoreChallenges
local UI = addon.UI
local AceGUI = LibStub("AceGUI-3.0")

function UI:ShowSelection()
    local db = addon.CharDB

    if self.selectionWindow then
        self.selectionWindow:Show()
        return
    end

    local window = AceGUI:Create("Window")
    window:SetTitle("Select Challenges")
    window:SetLayout("List") -- ✅ ВАЖНО: не Flow!
    window:SetWidth(420)
    window:SetHeight(450)
    window:EnableResize(false)

    local bg = CreateFrame("Frame", nil, window.frame)
    bg:SetPoint("TOPLEFT", 10, -25)
    bg:SetPoint("BOTTOMRIGHT", -4, 4)
    bg:SetFrameLevel(0)
    bg.texture = bg:CreateTexture(nil, "BACKGROUND")
    bg.texture:SetAllPoints(bg)
    bg.texture:SetColorTexture(0, 0, 0, 1)

    local pointsLabel = AceGUI:Create("Label")
    pointsLabel:SetFullWidth(true)

    local function UpdatePoints()
        pointsLabel:SetText("|cFFFFFF00Total Points: " .. addon:GetPoints() .. "|r")
    end

    for key, challenge in pairs(addon:GetChallengesState()) do
        local row = AceGUI:Create("SimpleGroup")
        row:SetLayout("Flow")
        row:SetFullWidth(true)
        row:SetHeight(60)

        -- ИКОНКА
        local icon = AceGUI:Create("Icon")
        icon:SetImage(challenge.icon)
        icon:SetImageSize(36, 36)
        icon:SetWidth(40)

        -- ТЕКСТ (точно как в active)
        local title = "|cFFFF0000" .. challenge.name .. "|r"
        local desc = challenge.description
        local pts = "|cFFFFFF00+" .. challenge.points .. " points|r"

        local text = AceGUI:Create("Label")
        text:SetText(title .. "\n" .. desc .. "\n" .. pts)
        text:SetWidth(260)

        -- ЧЕКБОКС (фикс справа)
        local cb = AceGUI:Create("CheckBox")
        cb:SetValue(challenge.enabled)
        cb:SetWidth(40)

        cb:SetCallback("OnValueChanged", function(_, _, val)
            db.activeChallenges[key] = val
            UpdatePoints()
        end)

        -- КЛИК ПО ИКОНКЕ
        icon.frame:SetScript("OnMouseDown", function()
            local newVal = not cb:GetValue()
            cb:SetValue(newVal)
            db.activeChallenges[key] = newVal
            UpdatePoints()
        end)

        row:AddChild(icon)
        row:AddChild(text)
        row:AddChild(cb)

        window:AddChild(row)
    end

    UpdatePoints()
    window:AddChild(pointsLabel)

    local btn = AceGUI:Create("Button")
    btn:SetText("Start")
    btn:SetWidth(120)
    btn:SetCallback("OnClick", function()
    -- ✅ Проверка Self Found при старте
    if db.activeChallenges["SelfFound"] then
        local hasBuff = false

        for i = 1, 40 do
            local name = UnitBuff("player", i)
            if not name then break end

            if name == "Self-Found Adventurer" then
                hasBuff = true
                break
            end
        end

        if not hasBuff then
            db.failedChallenges["SelfFound"] = true
        end
    end

    db.characterStarted = true
    window:Hide()
    UI:ShowActive()
end)

    window:AddChild(btn)

    self.selectionWindow = window
end