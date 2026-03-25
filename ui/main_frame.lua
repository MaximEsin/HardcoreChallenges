-- ui/main_frame.lua
local addon = HardcoreChallenges
local UI = addon.UI
local AceGUI = LibStub("AceGUI-3.0")

-- Окно выбора челленджей
function UI:ShowSelection()
    local db = addon.CharDB

    -- если окно уже есть — просто показать
    if self.selectionWindow then
        self.selectionWindow:Show()
        return
    end

    local window = AceGUI:Create("Window")
    window:SetTitle("Select Challenges")
    window:SetLayout("Flow")
    window:SetWidth(400)
    window:SetHeight(400)
    window:EnableResize(false)

    -- Чёрный фон под контент, аккуратно по рамке
    local bg = CreateFrame("Frame", nil, window.frame)
    bg:SetPoint("TOPLEFT", 10, -25)
    bg:SetPoint("BOTTOMRIGHT", -4, 4)
    bg:SetFrameLevel(0)
    bg.texture = bg:CreateTexture(nil, "BACKGROUND")
    bg.texture:SetAllPoints(bg)
    bg.texture:SetColorTexture(0, 0, 0, 1)  -- полностью черный

    -- создаем чекбоксы для челленджей
    for key, challenge in pairs(addon:GetChallengesState()) do
        local container = AceGUI:Create("SimpleGroup")
        container:SetLayout("Flow")
        container:SetWidth(360)
        container:SetHeight(40)

        local icon = AceGUI:Create("Icon")
        icon:SetImage(challenge.icon)
        icon:SetImageSize(32, 32)
        container:AddChild(icon)

        local cb = AceGUI:Create("CheckBox")
        cb:SetLabel(challenge.name .. " - " .. challenge.description)
        cb:SetValue(challenge.enabled)
        cb:SetWidth(300)

        cb:SetCallback("OnValueChanged", function(_, _, val)
            db.activeChallenges[key] = val
        end)

        container:AddChild(cb)
        window:AddChild(container)
    end

    local btn = AceGUI:Create("Button")
    btn:SetText("Start")
    btn:SetWidth(120)
    btn:SetCallback("OnClick", function()
        db.characterStarted = true
        window:Hide()
        UI:ShowActive()
    end)
    window:AddChild(btn)

    self.selectionWindow = window
end