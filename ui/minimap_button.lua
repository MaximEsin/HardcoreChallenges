-- ui/minimap_button.lua
local addon = HardcoreChallenges
local UI = addon.UI
local LDB = LibStub("LibDataBroker-1.1")
local LDBIcon = LibStub("LibDBIcon-1.0")

local function CreateMinimapButton()
    if not addon.CharDB then return end -- безопасно, если CharDB ещё не готов

    local icon = LDB:NewDataObject("HardcoreChallenges", {
        type = "data source",
        icon = "Interface\\Icons\\ability_creature_cursed_02",
        text = "Hardcore Challenges",

        OnClick = function()
            local db = addon.CharDB
            local anySelected = false
            for _, v in pairs(db.activeChallenges) do
                if v then anySelected = true break end
            end

            if not anySelected or not db.characterStarted then
                UI:ShowSelection()
            else
                UI:ShowActive()
            end
        end,

        OnTooltipShow = function(tt)
            tt:AddLine("Hardcore Challenges")
            tt:AddLine("Click to open", 1,1,1)
        end,
    })

    LDBIcon:Register("HardcoreChallenges", icon, addon.CharDB.minimap)
end

-- Регистрируем миникнопку только после OnEnable
addon:RegisterEvent("PLAYER_ENTERING_WORLD", function()
    CreateMinimapButton()
end)