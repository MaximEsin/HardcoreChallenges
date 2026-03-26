-- core/single_spec.lua — Single Spec: at most one talent tree may have points spent.

local addon = HardcoreChallenges
local UI = addon.UI

-- Classic API variants:
-- Legacy: name, texture, pointsSpent, fileName = GetTalentTabInfo(i)
-- Modern (e.g. recent Classic): id, name, description, icon, pointsSpent, ... = GetTalentTabInfo(i)
local function GetTalentTabPointsAndName(tabIndex)
    local r1, r2, r3, r4, r5 = GetTalentTabInfo(tabIndex)
    if type(r1) == "number" then
        return r2, r5
    end
    return r1, r3
end

--[[
  Returns:
    treeCount — number of tabs with pointsSpent > 0
    treeNames — ordered names of those tabs
    primaryName — name if exactly one tab has points, else nil
    violated — true if two or more tabs have points
]]
function addon:GetSingleSpecTalentState()
    local n = GetNumTalentTabs and GetNumTalentTabs(false) or 0
    if n < 1 then
        return { treeCount = 0, treeNames = {}, primaryName = nil, violated = false }
    end

    local treeNames = {}
    for i = 1, n do
        local tabName, pointsSpent = GetTalentTabPointsAndName(i)
        local spent = tonumber(pointsSpent) or 0
        if spent > 0 then
            treeNames[#treeNames + 1] = tabName or ("Tree " .. i)
        end
    end

    local treeCount = #treeNames
    return {
        treeCount = treeCount,
        treeNames = treeNames,
        primaryName = treeCount == 1 and treeNames[1] or nil,
        violated = treeCount >= 2,
    }
end

function addon:SingleSpecCheckAndFail()
    local db = self.CharDB
    if not db.activeChallenges["SingleSpec"] then return end
    if db.failedChallenges["SingleSpec"] then return end
    if not db.characterStarted then return end

    local st = self:GetSingleSpecTalentState()
    if st.violated then
        db.failedChallenges["SingleSpec"] = true
        UIErrorsFrame:AddMessage("Single Spec challenge failed: points spent in more than one talent tree.", 1, 0, 0)
        if UI.UpdateActive then UI:UpdateActive() end
    end
end

function addon:SingleSpecOnChallengeStart()
    local db = self.CharDB
    if not db.activeChallenges["SingleSpec"] then return end
    local st = self:GetSingleSpecTalentState()
    if st.violated then
        db.failedChallenges["SingleSpec"] = true
        UIErrorsFrame:AddMessage("Single Spec: points in multiple trees — challenge failed at start.", 1, 0, 0)
    end
end

function addon:SingleSpecOnEnable()
    if self._singleSpecListener then return end

    local f = CreateFrame("Frame")
    self._singleSpecListener = f
    f:RegisterEvent("PLAYER_ENTERING_WORLD")
    f:RegisterEvent("PLAYER_LEVEL_UP")
    f:RegisterEvent("CHARACTER_POINTS_CHANGED")
    f:RegisterEvent("PLAYER_TALENT_UPDATE")
    f:SetScript("OnEvent", function()
        addon:SingleSpecCheckAndFail()
    end)

    self:SingleSpecCheckAndFail()
end
