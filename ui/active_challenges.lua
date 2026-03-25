-- ui/active_challenges.lua
local addon = HardcoreChallenges
local UI = addon.UI
local AceGUI = LibStub("AceGUI-3.0")

-- Показ окна активных челленджей
function UI:ShowActive()
    -- если уже есть окно — просто обновим
    if self.activeWindow then
        self:UpdateActive()
        self.activeWindow:Show()
        return
    end

    local window = AceGUI:Create("Window")
    window:SetTitle("Active Challenges")
    window:SetLayout("List")
    window:SetWidth(400)
    window:SetHeight(400)
    window:EnableResize(false)

    -- Чёрный фон под контент
    local bg = CreateFrame("Frame", nil, window.frame)
    bg:SetPoint("TOPLEFT", 10, -25)
    bg:SetPoint("BOTTOMRIGHT", -4, 4)
    bg:SetFrameLevel(0)
    bg.texture = bg:CreateTexture(nil, "BACKGROUND")
    bg.texture:SetAllPoints(bg)
    bg.texture:SetColorTexture(0, 0, 0, 1)

    self.activeWindow = window
    self:UpdateActive()
end

-- Обновление списка активных челленджей
function UI:UpdateActive()
    local db = addon.CharDB
    local window = self.activeWindow
    if not window then return end

    window:ReleaseChildren()

    for key, challenge in pairs(addon:GetChallengesState()) do
        if db.activeChallenges[key] then
            local container = AceGUI:Create("SimpleGroup")
            container:SetLayout("Flow")
            container:SetWidth(360)
            container:SetHeight(40)

            local icon = AceGUI:Create("Icon")
            icon:SetImage(challenge.icon)
            icon:SetImageSize(32, 32)
            container:AddChild(icon)

            local status = db.failedChallenges[key] and "|cFFFF0000Failed|r" or "|cFF00FF00Active|r"

            local lbl = AceGUI:Create("Label")
            lbl:SetText(challenge.name .. " - " .. challenge.description .. " [" .. status .. "]")
            lbl:SetWidth(300)

            container:AddChild(lbl)
            window:AddChild(container)
        end
    end
end