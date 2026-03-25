local addon = HardcoreChallenges

function addon:InitMinimap()
    local LDB = LibStub("LibDataBroker-1.1")
    local LDBIcon = LibStub("LibDBIcon-1.0")

    local icon = LDB:NewDataObject("HardcoreChallenges", {
        type = "data source",
        icon = "Interface\\Icons\\ability_creature_cursed_02",
        text = "Hardcore Challenges",

        OnClick = function()
            local db = addon.CharDB

            local anySelected = false
            for _, v in pairs(db.activeChallenges) do
                if v then
                    anySelected = true
                    break
                end
            end

            if not anySelected then
                addon.UI:ShowSelection()
            else
                addon.UI:ShowActive()
            end
        end,

        OnTooltipShow = function(tt)
            tt:AddLine("Hardcore Challenges")
            tt:AddLine("Click to open", 1, 1, 1)
        end,
    })

    LDBIcon:Register("HardcoreChallenges", icon, self.CharDB.minimap)
end