local addon = HardcoreChallenges

function addon:OnInitialize()
    self:InitDB()
end

function addon:OnEnable()
    self:InitMinimap()
    
    print("|cFFFF0000[Hardcore Challenges]|r addon loaded!")
end