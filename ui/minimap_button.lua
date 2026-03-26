local addon = HardcoreChallenges
local UI = addon.UI
local LDB = LibStub("LibDataBroker-1.1", true)
local LDBIcon = LibStub("LibDBIcon-1.0", true)

local BROKER_NAME = "HardcoreChallenges"
local iconObject

local function EnsureMinimapDb()
    local db = addon.CharDB
    if not db then return nil end
    if type(db.minimap) ~= "table" then
        db.minimap = { hide = false, angle = 0 }
    else
        if db.minimap.hide == nil then db.minimap.hide = false end
        if db.minimap.angle == nil then db.minimap.angle = 0 end
    end
    return db.minimap
end

--- Вызывать из PLAYER_ENTERING_WORLD (см. core/titles.lua + init OnEnable).
--- Нельзя отдельно RegisterEvent("PLAYER_ENTERING_WORLD") здесь: в AceEvent один обработчик на событие на аддон.
function addon:EnsureMinimapButton()
    if not self.CharDB then return end
    if not LDB or not LDBIcon then return end

    local mm = EnsureMinimapDb()
    if not mm then return end

    if not iconObject then
        iconObject = LDB:NewDataObject(BROKER_NAME, {
            type = "data source",
            icon = "Interface\\Icons\\ability_creature_cursed_02",
            text = "Hardcore Challenges",
            OnClick = function()
                local db = addon.CharDB
                if not db then return end
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
                tt:AddLine("Click to open", 1, 1, 1)
            end,
        })
        if not iconObject and LDB.GetDataObjectByName then
            iconObject = LDB:GetDataObjectByName(BROKER_NAME)
        end
    end

    if not iconObject then return end

    pcall(function()
        LDBIcon:Register(BROKER_NAME, iconObject, mm)
    end)
end
