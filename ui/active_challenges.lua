local addon = HardcoreChallenges
local UI = addon.UI
local AceGUI = LibStub("AceGUI-3.0")

function UI:ShowActive()
    if self.activeWindow then
        self:UpdateActive()
        self.activeWindow:Show()
        return
    end

    local window = AceGUI:Create("Window")
    window:SetTitle("Active Challenges")
    window:SetLayout("Flow")
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

    self.activeWindow = window
    self:UpdateActive()
end

function UI:UpdateActive()
    local db = addon.CharDB
    local window = self.activeWindow
    if not window then return end

    window:ReleaseChildren()

    for key, challenge in pairs(addon:GetChallengesState()) do
        if db.activeChallenges[key] then
            local container = AceGUI:Create("SimpleGroup")
            container:SetLayout("Flow")
            container:SetFullWidth(true)
            container:SetHeight(60)

            local icon = AceGUI:Create("Icon")
            icon:SetImage(challenge.icon)
            icon:SetImageSize(36, 36)
            icon:SetWidth(40)

            -- ✅ отключаем любые mouse interaction (убирает странные эффекты)
            icon.image:EnableMouse(false)

            local status = db.failedChallenges[key] and "|cFFFF0000Failed|r" or "|cFF00FF00Active|r"

            local title = "|cFFFF0000" .. challenge.name .. "|r"
            local desc = challenge.description
            local pts = "|cFFFFFF00+" .. challenge.points .. " points|r"

            local text = AceGUI:Create("Label")
            text:SetText(title .. "\n" .. desc .. "\n" .. pts .. " [" .. status .. "]")
            text:SetWidth(320)

            container:AddChild(icon)
            container:AddChild(text)

            window:AddChild(container)
        end
    end

    local spacer = AceGUI:Create("Label")
    spacer:SetText(" ")
    spacer:SetFullWidth(true)
    window:AddChild(spacer)

    local points = addon:GetPoints()

    local pointsLabel = AceGUI:Create("Label")
    pointsLabel:SetText("|cFFFFFF00Total Points: " .. points .. "|r")
    pointsLabel:SetFullWidth(true)
    pointsLabel:SetFontObject(GameFontNormalLarge)

    window:AddChild(pointsLabel)
end