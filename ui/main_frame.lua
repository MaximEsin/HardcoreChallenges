-- ui/main_frame.lua

local addon = HardcoreChallenges
local UI = addon.UI
local AceGUI = LibStub("AceGUI-3.0") -- библиотека GUI для аддонов

--[[ 
    Функция: Получение текущего континента игрока
    Используется для челленджа SingleContinent
    Возвращает parentMapID или mapID, если parent отсутствует
]]
local function GetContinent()
    local mapID = C_Map.GetBestMapForUnit("player")
    if not mapID then return nil end

    local info = C_Map.GetMapInfo(mapID)
    if not info then return nil end

    return info.parentMapID or mapID
end

--[[ 
    Функция: Показ окна выбора челленджей
    - Если окно уже существует, просто показывает его
    - Создаёт GUI окно с:
        - фоном
        - списком челленджей (иконка + название + описание + очки)
        - чекбоксом для включения/отключения челленджа
        - кнопкой Start
    Пример: UI:ShowSelection()
]]
function UI:ShowSelection()
    local db = addon.CharDB

    -- окно уже открыто
    if self.selectionWindow then
        self.selectionWindow:Show()
        return
    end

    local frameName = "HardcoreChallenges_SelectionFrame"

    local window = AceGUI:Create("Window")
    window:SetTitle("Select Challenges")
    window:SetLayout("List")
    window:SetWidth(420)
    window:SetHeight(450)
    window:EnableResize(false)
    window.frame:SetParent(UIParent)
    _G[frameName] = window.frame
    tinsert(UISpecialFrames, frameName)

    -- фон окна
    local bg = CreateFrame("Frame", nil, window.frame)
    bg:SetPoint("TOPLEFT", 10, -25)
    bg:SetPoint("BOTTOMRIGHT", -4, 4)
    bg:SetFrameLevel(0)
    bg.texture = bg:CreateTexture(nil, "BACKGROUND")
    bg.texture:SetAllPoints(bg)
    bg.texture:SetColorTexture(0, 0, 0, 1) -- черный фон

    -- метка с очками
    local pointsLabel = AceGUI:Create("Label")
    pointsLabel:SetFullWidth(true)

    local function UpdatePoints()
        pointsLabel:SetText("|cFFFFFF00Total Points: " .. addon:GetPoints() .. "|r")
    end

    -- перебор всех челленджей
    for key, challenge in pairs(addon:GetChallengesState()) do
        local row = AceGUI:Create("SimpleGroup")
        row:SetLayout("Flow")
        row:SetFullWidth(true)
        row:SetHeight(70)

        -- иконка
        local icon = AceGUI:Create("Icon")
        icon:SetImage(challenge.icon)
        icon:SetImageSize(36, 36)
        icon:SetWidth(40)

        -- текст челленджа
        local title = "|cFFFF0000" .. challenge.name .. "|r"
        local desc = challenge.description
        local pts = "|cFFFFFF00+" .. challenge.points .. " points|r"

        local extra = ""

        -- дополнительные данные для SingleContinent
        if key == "SingleContinent" then
            local currentID = GetContinent()
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
        end

        local text = AceGUI:Create("Label")
        text:SetText(title .. "\n" .. desc .. "\n" .. pts .. extra)
        text:SetWidth(260)

        -- чекбокс для выбора челленджа
        local cb = AceGUI:Create("CheckBox")
        cb:SetValue(challenge.enabled)
        cb:SetWidth(40)

        cb:SetCallback("OnValueChanged", function(_, _, val)
            db.activeChallenges[key] = val
            UpdatePoints()
        end)

        -- клик по иконке тоже меняет состояние
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

    -- кнопка "Start"
    local btn = AceGUI:Create("Button")
    btn:SetText("Start")
    btn:SetWidth(120)

    btn:SetCallback("OnClick", function()
        -- проверка SelfFound
        if db.activeChallenges["SelfFound"] then
            local hasBuff = false
            for i = 1, 40 do
                local name = UnitBuff("player", i)
                if not name then break end
                if name == "Self Found" then
                    hasBuff = true
                    break
                end
            end
            if not hasBuff then
                db.failedChallenges["SelfFound"] = true
            end
        end

        -- сохраняем континент для SingleContinent
        if db.activeChallenges["SingleContinent"] then
            db.startContinent = GetContinent()
        end

        db.characterStarted = true
        window:Hide()
        UI:ShowActive()
    end)

    window:AddChild(btn)

    self.selectionWindow = window
end