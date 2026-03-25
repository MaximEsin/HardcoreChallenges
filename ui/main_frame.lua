HardcoreChallengesUI = {}

local frame = CreateFrame("Frame", "HardcoreChallengesMainFrame", UIParent, "BackdropTemplate")
frame:SetSize(400, 300)
frame:SetPoint("CENTER")
frame:SetBackdrop({ bgFile = "Interface/Tooltips/UI-Tooltip-Background" })
frame:SetBackdropColor(0, 0, 0, 0.8)
frame:Hide()

local title = frame:CreateFontString(nil, "OVERLAY", "GameFontNormalLarge")
title:SetPoint("TOP", 0, -20)
title:SetText("Challenge Selection")

local startButton = CreateFrame("Button", nil, frame, "UIPanelButtonTemplate")
startButton:SetSize(120, 30)
startButton:SetPoint("BOTTOM", 0, 20)
startButton:SetText("Start")

startButton:SetScript("OnClick", function()
    print("HardcoreChallenges: Start clicked")
    HardcoreChallengesDB.characterStarted = true
    frame:Hide()
end)

function HardcoreChallengesUI:Show()
    print("HardcoreChallengesUI: Show")
    frame:Show()
end

function HardcoreChallengesUI:Hide()
    print("HardcoreChallengesUI: Hide")
    frame:Hide()
end