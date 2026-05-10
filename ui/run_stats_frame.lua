-- ui/run_stats_frame.lua — Run statistics window (self only).

local addon = HardcoreChallenges
local UI = addon.UI

local function FormatMoneyCopper(copper)
    copper = copper or 0
    local g = math.floor(copper / 10000)
    local s = math.floor((copper % 10000) / 100)
    local c = copper % 100
    return string.format("%dg %ds %dc", g, s, c)
end

function UI:RefreshRunStats()
    local root = self.runStatsWindow
    if not root or not root._applyStats then return end
    if root:IsVisible() then
        root._applyStats()
    end
end

function UI:ShowRunStats()
    local db = addon.CharDB
    if not db or not db.characterStarted then
        UIErrorsFrame:AddMessage("Hardcore Challenges: no run in progress.", 1, 1, 0)
        return
    end

    if self.runStatsWindow then
        self.runStatsWindow._applyStats()
        self.runStatsWindow:Show()
        self.runStatsWindow:Raise()
        self.runStatsWindow:RefreshTheme()
        return
    end

    local frameName = "HardcoreChallenges_RunStatsFrame"
    local root = self:CreateThemedWindow({
        name = frameName,
        title = "Run statistics",
        width = 360,
        height = 300,
    })
    _G[frameName] = root
    tinsert(UISpecialFrames, frameName)

    local body = root.Body
    local fontPath = root._pointFontPath
    local r0, g0, b0 = self.GetTitleTextColor()
    local tr, tg, tb = self.GetPlayerClassColor()

    local intro = body:CreateFontString(nil, "OVERLAY", "GameFontHighlight")
    intro:SetPoint("TOPLEFT", body, "TOPLEFT", 8, -8)
    intro:SetPoint("TOPRIGHT", body, "TOPRIGHT", -8, -8)
    intro:SetJustifyH("LEFT")
    self.SafeSetFont(intro, fontPath, 13, "GameFontHighlight")
    intro:SetTextColor(0.85, 0.85, 0.85)
    intro:SetText("Totals for this character since starting the run (addon-tracked).")

    local y = -52
    local function addRow(labelKey, valueFs)
        local lab = body:CreateFontString(nil, "OVERLAY", "GameFontNormalLarge")
        lab:SetPoint("TOPLEFT", body, "TOPLEFT", 12, y)
        lab:SetWidth(200)
        lab:SetJustifyH("LEFT")
        self.SafeSetFont(lab, fontPath, 15, "GameFontNormalLarge")
        lab:SetTextColor(tr, tg, tb)
        lab:SetText(labelKey)

        valueFs:SetPoint("TOPLEFT", lab, "TOPRIGHT", 8, 0)
        valueFs:SetPoint("TOPRIGHT", body, "TOPRIGHT", -16, y)
        valueFs:SetJustifyH("RIGHT")
        self.SafeSetFont(valueFs, fontPath, 15, "GameFontNormalLarge")
        valueFs:SetTextColor(r0, g0, b0)

        y = y - 36
    end

    local fsKills = body:CreateFontString(nil, "OVERLAY", "GameFontNormalLarge")
    local fsQuests = body:CreateFontString(nil, "OVERLAY", "GameFontNormalLarge")
    local fsGold = body:CreateFontString(nil, "OVERLAY", "GameFontNormalLarge")
    addRow("Mobs killed", fsKills)
    addRow("Quests completed", fsQuests)
    addRow("Gold earned", fsGold)

    function root._applyStats()
        local d = addon.CharDB
        if not d then return end
        fsKills:SetText(tostring(d.statMobsKilled or 0))
        fsQuests:SetText(tostring(d.statQuestsCompleted or 0))
        fsGold:SetText(FormatMoneyCopper(d.statGoldEarnedCopper or 0))
    end

    root._applyStats()
    self.runStatsWindow = root
    root:Show()
    root:Raise()
end
