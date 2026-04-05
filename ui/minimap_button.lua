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

--- Сколько из явно выбранных (activeChallenges) челленджей уже засчитаны в хабе; логика как в active_challenges.
local function GetSelectedChallengesCompletionCounts()
    local db = addon.CharDB
    if not db or not addon.Challenges then return 0, 0 end
    db.activeChallenges = db.activeChallenges or {}
    db.failedChallenges = db.failedChallenges or {}
    local hub = addon:HubEnsure()
    local total, done = 0, 0
    for key, challenge in pairs(addon.Challenges) do
        if not challenge.hubOnly and db.activeChallenges[key] then
            total = total + 1
            if db.failedChallenges[key] then
                -- failed: not complete
            elseif hub.completedKeys[key] then
                done = done + 1
            elseif addon.IsSlayerChallengeKey and addon:IsSlayerChallengeKey(key) then
                local cur = select(1, addon:GetSlayerProgressDisplay(key))
                local goal = addon.GetSlayerGoal and addon:GetSlayerGoal() or 10000
                if cur >= goal then
                    done = done + 1
                end
            end
        end
    end
    return done, total
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
                if addon:IsChallengeConfigureLevel() then
                    local anySelected = false
                    for _, v in pairs(db.activeChallenges) do
                        if v then anySelected = true break end
                    end
                    if not anySelected or not db.characterStarted then
                        UI:ShowSelection()
                    else
                        UI:ShowActive()
                    end
                    return
                end
                if db.characterStarted then
                    UI:ShowActive()
                else
                    UI:ShowHub()
                end
            end,
            OnTooltipShow = function(tt)
                tt:AddLine("Hardcore Challenges")
                local done, total = GetSelectedChallengesCompletionCounts()
                if total > 0 then
                    tt:AddLine(string.format("%d/%d completed", done, total), 0.75, 0.9, 0.75)
                end
                if addon:IsChallengeConfigureLevel() then
                    tt:AddLine("Click to choose challenges (level 1) or view your run", 1, 1, 1)
                elseif addon.CharDB and addon.CharDB.characterStarted then
                    tt:AddLine("Click to view active challenges and titles", 1, 1, 1)
                else
                    tt:AddLine("Click for Account Hub (new runs only at level 1)", 1, 1, 1)
                end
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
