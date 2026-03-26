local addon = HardcoreChallenges
local UI = addon.UI
local LDB = LibStub("LibDataBroker-1.1", true) -- библиотека для создания "DataObject"
local LDBIcon = LibStub("LibDBIcon-1.0", true) -- библиотека для отображения кнопки на миникарте

local iconObject -- переменная для хранения объекта кнопки, чтобы не создавать несколько раз

--[[ 
    Функция: Создание кнопки на миникарте
    Описание: 
        - Проверяет, готова ли база данных персонажа
        - Создаёт объект LDB с иконкой, текстом, обработчиками клика и тултипа
        - Регистрирует кнопку через LibDBIcon
    Расширения:
        - Можно добавить контекстное меню по правому клику
        - Изменить иконку или текст динамически
]]
local function CreateMinimapButton()
    if not addon.CharDB then return end -- база данных не готова
    if not LDB or not LDBIcon then return end -- библиотеки отсутствуют
    if iconObject then return end -- кнопка уже создана

    iconObject = LDB:NewDataObject("HardcoreChallenges", {
        type = "data source",
        icon = "Interface\\Icons\\ability_creature_cursed_02", -- иконка кнопки
        text = "Hardcore Challenges", -- текст при наведении

        -- обработчик клика на кнопку
        OnClick = function()
            local db = addon.CharDB
            local anySelected = false

            -- проверка: есть ли активные челленджи
            for _, v in pairs(db.activeChallenges) do
                if v then anySelected = true break end
            end

            -- открываем окно выбора или активных челленджей
            if not anySelected or not db.characterStarted then
                UI:ShowSelection()
            else
                UI:ShowActive()
            end
        end,

        -- подсказка при наведении
        OnTooltipShow = function(tt)
            tt:AddLine("Hardcore Challenges") -- заголовок
            tt:AddLine("Click to open", 1,1,1) -- белый текст
        end,
    })

    if iconObject then
        -- регистрация кнопки на миникарте с сохранением настроек
        LDBIcon:Register("HardcoreChallenges", iconObject, addon.CharDB.minimap)
    end
end

-- событие: создаём кнопку при входе в мир
addon:RegisterEvent("PLAYER_ENTERING_WORLD", function()
    CreateMinimapButton()
end)