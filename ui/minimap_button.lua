-- ui/minimap_button.lua

print("HardcoreChallenges: Loading Minimap Button...")

-- Гарантируем, что DB есть
if not HardcoreChallengesDB then
    print("HardcoreChallenges: HardcoreChallengesDB is nil! Creating default table...")
    HardcoreChallengesDB = {}
end
HardcoreChallengesDB.minimap = HardcoreChallengesDB.minimap or {}

-- LibDBIcon
local LDB = LibStub("LibDBIcon-1.0")
local LDBDataObject = LibStub("LibDataBroker-1.1"):NewDataObject("HardcoreChallenges", {
    type = "data source",
    icon = "Interface\\Icons\\ability_creature_cursed_02",
    text = "Hardcore Challenges",
    OnClick = function(self, button)
        print("HardcoreChallenges: Minimap button clicked")
        if HardcoreChallengesUI then
            HardcoreChallengesUI:Show()
        end
    end,
    OnTooltipShow = function(tt)
        tt:AddLine("Hardcore Challenges")
        tt:AddLine("Click to open Challenge Selection", 1,1,1)
    end,
})

LDB:Register("HardcoreChallenges", LDBDataObject, HardcoreChallengesDB.minimap)

print("HardcoreChallenges: Minimap Button loaded")