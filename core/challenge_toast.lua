-- core/challenge_toast.lua — achievement-style completion toast (from HardcoreAchievements layout) + queue.

local addon = HardcoreChallenges
local UI = addon.UI

local HOLD_SEC = 3
local FADE_SEC = 0.6
local SOUND_PATH = "Interface\\AddOns\\HardcoreChallenges\\Sounds\\AchievementSound1.ogg"

local toastQueue = {}
local toastActive = false
local hcToastFrame

local function ToastFadeOnUpdate(s, elapsed)
    local t = (s.fadeT or 0) + elapsed
    s.fadeT = t
    local duration = s.fadeDuration or FADE_SEC
    local a = 1 - math.min(t / duration, 1)
    s:SetAlpha(a)
    if t >= duration then
        s:SetScript("OnUpdate", nil)
        s.fadeT = nil
        s.fadeDuration = nil
        s:Hide()
        s:SetAlpha(1)
        local cb = s._onFadeDone
        s._onFadeDone = nil
        if cb then
            cb()
        end
    end
end

local function GetOrCreateChallengeToastFrame()
    if hcToastFrame and hcToastFrame:IsObjectType("Frame") then
        return hcToastFrame
    end

    local f = CreateFrame("Frame", "HardcoreChallenges_Toast", UIParent)
    f:SetSize(320, 92)
    f:SetPoint("CENTER", 0, -280)
    f:Hide()
    f:SetFrameStrata("TOOLTIP")
    f:SetFrameLevel(200)

    local bg = f:CreateTexture(nil, "BACKGROUND")
    bg:SetAllPoints()
    local okAtlas = bg.SetAtlas and bg:SetAtlas("UI-Achievement-Alert-Background", true)
    if not okAtlas then
        bg:SetTexture("Interface\\AchievementFrame\\UI-Achievement-Alert-Background")
        bg:SetTexCoord(0, 0.605, 0, 0.703)
    else
        bg:SetTexCoord(0, 1, 0, 1)
    end

    local iconFrame = CreateFrame("Frame", nil, f)
    iconFrame:SetSize(40, 40)
    iconFrame:SetPoint("LEFT", f, "LEFT", 6, 0)

    local icon = iconFrame:CreateTexture(nil, "ARTWORK")
    icon:SetPoint("CENTER", iconFrame, "CENTER", 0, 0)
    icon:SetSize(40, 43)
    icon:SetTexCoord(0.05, 1, 0.05, 1)
    f.icon = icon

    local iconOverlay = iconFrame:CreateTexture(nil, "OVERLAY")
    iconOverlay:SetTexture("Interface\\AchievementFrame\\UI-Achievement-IconFrame")
    iconOverlay:SetTexCoord(0, 0.5625, 0, 0.5625)
    iconOverlay:SetSize(72, 72)
    iconOverlay:SetPoint("CENTER", iconFrame, "CENTER", -1, 2)

    local name = f:CreateFontString(nil, "OVERLAY", "GameFontHighlight")
    name:SetPoint("CENTER", f, "CENTER", 10, 0)
    name:SetJustifyH("CENTER")
    name:SetWidth(200)
    f.name = name

    local unlocked = f:CreateFontString(nil, "OVERLAY", "GameFontNormalSmall")
    unlocked:SetPoint("TOP", f, "TOP", 7, -26)
    unlocked:SetText("Challenge complete!")
    f.unlocked = unlocked

    local shield = CreateFrame("Frame", nil, f)
    shield:SetSize(64, 64)
    shield:SetPoint("RIGHT", f, "RIGHT", -10, -4)

    local shieldIcon = shield:CreateTexture(nil, "BACKGROUND")
    shieldIcon:SetTexture("Interface\\AchievementFrame\\UI-Achievement-Shields")
    shieldIcon:SetSize(56, 52)
    shieldIcon:SetPoint("TOPRIGHT", 1, 0)
    shieldIcon:SetTexCoord(0, 0.5, 0, 0.45)
    f.shieldIcon = shieldIcon

    local points = shield:CreateFontString(nil, "OVERLAY", "GameFontNormal")
    points:SetPoint("CENTER", 4, 5)
    points:SetText("")
    f.points = points

    function f:PlayFade(duration)
        self.fadeT = 0
        self.fadeDuration = duration
        self:SetScript("OnUpdate", ToastFadeOnUpdate)
    end

    f:EnableMouse(true)
    f:SetScript("OnMouseUp", function(_, button)
        if button == "LeftButton" and UI and UI.ShowHub then
            UI:ShowHub()
        end
    end)

    hcToastFrame = f
    return f
end

local function playToastSound()
    pcall(function()
        PlaySoundFile(SOUND_PATH, "Effects")
    end)
end

local function showToastNow(iconTex, title, pts, onComplete)
    local f = GetOrCreateChallengeToastFrame()
    f:Hide()
    f:SetScript("OnUpdate", nil)
    f:SetAlpha(1)
    f._onFadeDone = nil

    local tex = iconTex
    if type(iconTex) == "table" and iconTex.GetTexture then
        tex = iconTex:GetTexture()
    end
    if not tex then
        tex = 136116
    end

    local finalPts = tonumber(pts) or 0

    f.icon:SetTexture(tex)
    f.name:SetText(title or "")

    if finalPts == 0 then
        f.points:SetText("")
        f.points:Hide()
        if f.shieldIcon then
            f.shieldIcon:SetTexture("Interface\\AchievementFrame\\UI-Achievement-Shields-Nopoints")
            f.shieldIcon:SetTexCoord(0, 0.5, 0, 0.45)
        end
    else
        f.points:SetText(tostring(finalPts))
        f.points:Show()
        if f.shieldIcon then
            f.shieldIcon:SetTexture("Interface\\AchievementFrame\\UI-Achievement-Shields")
            f.shieldIcon:SetTexCoord(0, 0.5, 0, 0.45)
        end
    end

    f._onFadeDone = onComplete
    f:Show()
    playToastSound()

    if C_Timer and C_Timer.After then
        C_Timer.After(HOLD_SEC, function()
            if f:IsShown() then
                f:PlayFade(FADE_SEC)
            elseif onComplete then
                onComplete()
            end
        end)
    else
        f:PlayFade(FADE_SEC)
    end
end

function addon:_ProcessChallengeToastQueue()
    if toastActive then return end
    local item = tremove(toastQueue, 1)
    if not item then return end
    toastActive = true
    if C_Timer and C_Timer.After then
        C_Timer.After(0, function()
            showToastNow(item.icon, item.title, item.points, function()
                toastActive = false
                addon:_ProcessChallengeToastQueue()
            end)
        end)
    else
        showToastNow(item.icon, item.title, item.points, function()
            toastActive = false
            addon:_ProcessChallengeToastQueue()
        end)
    end
end

--- Queue a toast for a challenge key (uses Challenges[key] name, icon, points).
function addon:EnqueueChallengeCompletionToast(key)
    local def = key and self.Challenges and self.Challenges[key]
    if not def then return end
    toastQueue[#toastQueue + 1] = {
        icon = def.icon,
        title = def.name,
        points = def.points or 0,
    }
    self:_ProcessChallengeToastQueue()
end
