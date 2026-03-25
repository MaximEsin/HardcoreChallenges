-- ui/minimap_button.lua

local addon = HardcoreChallenges
local UI = addon.UI

local LDB = LibStub("LibDataBroker-1.1")
local LDBIcon = LibStub("LibDBIcon-1.0")

print("HardcoreChallenges: Loading minimap button")

local icon = LDB:NewDataObject("HardcoreChallenges", {
    type = "data source",
    icon = "Interface\\Icons\\ability_creature_cursed_02",
    text = "Hardcore Challenges",

    OnClick = function(self, button)
        print("Minimap clicked")

        local db = addon.CharDB

        if not db then
            print("ERROR: CharDB missing")
            return
        end

        -- Проверяем выбран ли хоть один челлендж
        local anySelected = false
        for _, v in pairs(db.activeChallenges) do
            if v then
                anySelected = true
                break
            end
        end

        -- Открываем нужное окно
        if not anySelected then
            print("Opening Selection UI")
            UI:ShowSelection()
        else
            print("Opening Active UI")
            UI:ShowActive()
        end
    end,

    OnTooltipShow = function(tt)
        tt:AddLine("Hardcore Challenges")
        tt:AddLine("Click to open", 1,1,1)
    end,
})

-- Регистрируем кнопку
LDBIcon:Register("HardcoreChallenges", icon, addon.CharDB.minimap)