-- ui/active_challenges.lua

local addon = HardcoreChallenges
local UI = addon.UI
local AceGUI = LibStub("AceGUI-3.0")

--[[ 
    Функция: Получение текущего континента игрока
    Используется для проверки челленджа SingleContinent
]]
local function GetCurrentContinent()
    local mapID = C_Map.GetBestMapForUnit("player")
    if not mapID then return nil end

    local info = C_Map.GetMapInfo(mapID)
    if not info then return nil end

    return info.parentMapID or mapID
end

--[[ 
    Функция: Показ активных челленджей
    - Если окно уже существует, обновляет и показывает его
    - Создаёт GUI окно с фоном и списком активных челленджей
]]
function UI:ShowActive()
    if self.activeWindow then
        self:UpdateActive()
        self.activeWindow:Show()
        return
    end

    local frameName = "HardcoreChallenges_ActiveFrame"

    local window = AceGUI:Create("Window")
    window:SetTitle("Active Challenges")
    window:SetLayout("Flow")
    window:SetWidth(420)
    window:SetHeight(450)
    window:EnableResize(false)
    window.frame:SetParent(UIParent)
    window.frame:SetFrameStrata("DIALOG")
    window.frame:SetClampedToScreen(true)

    _G[frameName] = window.frame
    tinsert(UISpecialFrames, frameName)

    -- черный фон
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

--[[ 
    Функция: Обновление списка активных челленджей
    - Вызывается при изменении статуса челленджей
    - Отображает иконку, название, описание, очки и статус (Active/Failed)
]]
function UI:UpdateActive()
    local db = addon.CharDB
    local window = self.activeWindow
    if not window then return end

    -- очищаем старые элементы
    window:ReleaseChildren()

    for key, challenge in pairs(addon:GetChallengesState()) do
        if db.activeChallenges[key] then
            local container = AceGUI:Create("SimpleGroup")
            container:SetLayout("Flow")
            container:SetFullWidth(true)
            container:SetHeight(80)

            local icon = AceGUI:Create("Icon")
            icon:SetImage(challenge.icon)
            icon:SetImageSize(36, 36)
            icon:SetWidth(40)
            icon.frame:Disable() -- отключаем hover

            local title = "|cFFFF0000" .. challenge.name .. "|r"
            local desc = challenge.description
            local pts = "|cFFFFFF00+" .. challenge.points .. " points|r"

            local extra = ""

            -- доп. инфо для SingleContinent
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
            end

            -- статус челленджа
            local status = db.failedChallenges[key] and "|cFFFF0000Failed|r" or "|cFF00FF00Active|r"

            local text = AceGUI:Create("Label")
            text:SetText(title .. "\n" .. desc .. "\n" .. pts .. extra .. "\n[" .. status .. "]")
            text:SetWidth(320)

            container:AddChild(icon)
            container:AddChild(text)

            window:AddChild(container)
        end
    end

    -- отступ
    local spacer = AceGUI:Create("Label")
    spacer:SetText(" ")
    spacer:SetFullWidth(true)
    window:AddChild(spacer)

    -- отображение total points
    local points = addon:GetPoints()
    local pointsLabel = AceGUI:Create("Label")
    pointsLabel:SetText("|cFFFFFF00Total Points: " .. points .. "|r")
    pointsLabel:SetFullWidth(true)
    pointsLabel:SetFontObject(GameFontNormalLarge)

    window:AddChild(pointsLabel)
end