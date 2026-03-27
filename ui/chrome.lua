-- ui/chrome.lua
-- Themed window chrome (assets under this addon's Media/).

local addon = HardcoreChallenges
local UI = addon.UI

local HCA = "Interface\\AddOns\\HardcoreChallenges\\Media\\"
local POINTS_FONT_PATH = HCA .. "Fonts\\friz-quadrata-regular.ttf"
local HEADER_TEX = HCA .. "Images\\header.png"
local DIVIDER_TEX = HCA .. "Images\\divider.png"
local CLOSE_TEX = HCA .. "Images\\header-x.png"
local CHECKBOX_NORMAL = HCA .. "Images\\box.png"
local CHECKBOX_ACTIVE = HCA .. "Images\\box_active.png"

local TITLE_TEXT_COLOR = { 0.922, 0.871, 0.761 }

local function SafeSetFont(fs, path, size, fallbackFontObject)
    if fs.SetFont and path and path ~= "" then
        local ok = pcall(function()
            fs:SetFont(path, size)
        end)
        if ok then return end
    end
    if fallbackFontObject then
        fs:SetFontObject(fallbackFontObject)
    end
end
local CLASS_BACKGROUND_MAP = {
    WARRIOR = HCA .. "Images\\bg_warrior.png",
    PALADIN = HCA .. "Images\\bg_pally.png",
    HUNTER = HCA .. "Images\\bg_hunter.png",
    ROGUE = HCA .. "Images\\bg_rogue.png",
    PRIEST = HCA .. "Images\\bg_priest.png",
    SHAMAN = HCA .. "Images\\bg_shaman.png",
    MAGE = HCA .. "Images\\bg_mage.png",
    WARLOCK = HCA .. "Images\\bg_warlock.png",
    DRUID = HCA .. "Images\\bg_druid.png",
}
local CLASS_BG_ASPECT = 1200 / 700

local function GetPlayerClassColor()
    local _, class = UnitClass("player")
    if class and RAID_CLASS_COLORS and RAID_CLASS_COLORS[class] then
        local c = RAID_CLASS_COLORS[class]
        return c.r, c.g, c.b
    end
    return 1, 1, 1
end

local function GetClassBackgroundTexture()
    local _, token = UnitClass("player")
    if token and CLASS_BACKGROUND_MAP[token] then
        return CLASS_BACKGROUND_MAP[token]
    end
    return "Interface\\DialogFrame\\UI-DialogBox-Background"
end

local function UpdateClassBackgroundTexture(texture, hostFrame)
    if not texture or not hostFrame then return end
    texture:SetTexture(GetClassBackgroundTexture())
    texture:SetTexCoord(0, 1, 0, 1)
    local h = hostFrame:GetHeight()
    texture:ClearAllPoints()
    texture:SetPoint("CENTER", hostFrame, "CENTER", 0, 0)
    texture:SetSize(h * CLASS_BG_ASPECT, h)
end

-- Thin class-colored scrollbar thumb (Dashboard-style).
local function StyleScrollBar(scrollFrame, xInset)
    if not scrollFrame or not scrollFrame.ScrollBar then return end
    local scrollBar = scrollFrame.ScrollBar
    local r, g, b = GetPlayerClassColor()
    xInset = tonumber(xInset) or 2
    local yInset = 16
    scrollBar:ClearAllPoints()
    scrollBar:SetPoint("TOPLEFT", scrollFrame, "TOPRIGHT", -xInset, -yInset)
    scrollBar:SetPoint("BOTTOMLEFT", scrollFrame, "BOTTOMRIGHT", -xInset, yInset)

    local sbName = scrollBar.GetName and scrollBar:GetName()
    local up = scrollBar.ScrollUpButton or scrollBar.UpButton or (sbName and _G[sbName .. "ScrollUpButton"])
    local down = scrollBar.ScrollDownButton or scrollBar.DownButton or (sbName and _G[sbName .. "ScrollDownButton"])
    local function hideBtn(btn)
        if not btn then return end
        btn:Hide()
        btn:SetAlpha(0)
        btn:EnableMouse(false)
        btn:SetScript("OnShow", btn.Hide)
    end
    hideBtn(up)
    hideBtn(down)

    scrollBar:SetWidth(6)
    scrollBar:SetAlpha(0.9)

    for _, region in ipairs({ scrollBar:GetRegions() }) do
        if region and region:IsObjectType("Texture") then
            region:SetTexture(nil)
            region:SetAlpha(0)
        end
    end

    local thumb = scrollBar.GetThumbTexture and scrollBar:GetThumbTexture()
    if thumb then
        thumb:SetTexture("Interface\\Buttons\\WHITE8x8")
        thumb:SetTexCoord(0, 1, 0, 1)
        thumb:SetVertexColor(r, g, b)
        thumb:SetAlpha(0.95)
        thumb:SetWidth(2)
    end
end

function UI.ApplyThemedCheckbox(cb)
    if not cb then return end
    cb:SetNormalTexture(CHECKBOX_NORMAL)
    cb:SetPushedTexture(CHECKBOX_NORMAL)
    cb:SetHighlightTexture(CHECKBOX_NORMAL, "ADD")
    cb:SetCheckedTexture(CHECKBOX_ACTIVE)
    cb:SetDisabledCheckedTexture(CHECKBOX_ACTIVE)
    local r, g, b = GetPlayerClassColor()
    local checked = cb:GetCheckedTexture()
    if checked then checked:SetVertexColor(r, g, b) end
    local dc = cb:GetDisabledCheckedTexture()
    if dc then dc:SetVertexColor(r, g, b) end
    local label = cb.text or cb.Text
    if label then
        label:SetTextColor(TITLE_TEXT_COLOR[1], TITLE_TEXT_COLOR[2], TITLE_TEXT_COLOR[3])
    end
end

function UI.GetTitleTextColor()
    return TITLE_TEXT_COLOR[1], TITLE_TEXT_COLOR[2], TITLE_TEXT_COLOR[3]
end

function UI.GetPlayerClassColor()
    return GetPlayerClassColor()
end

--[[
    Returns root frame and a content region (below divider) for scroll / rows.
    root.footer is anchored bottom for extra controls.
]]
function UI:CreateThemedWindow(opts)
    opts = opts or {}
    local name = opts.name or "HardcoreChallenges_ThemedFrame"
    local title = opts.title or "Hardcore Challenges"
    local width = opts.width or 440
    local height = opts.height or 480
    local logoTexture = opts.logoTexture or "Interface\\Icons\\ability_creature_cursed_02"

    local backdropTemplate = BackdropTemplateMixin and "BackdropTemplate" or nil
    local root = CreateFrame("Frame", name, UIParent, backdropTemplate)
    root:SetSize(width, height)
    root:SetPoint("CENTER", UIParent, "CENTER", 0, 0)
    root:SetFrameStrata("DIALOG")
    root:SetFrameLevel(20)
    root:SetClampedToScreen(true)
    root:SetMovable(true)
    root:EnableMouse(true)
    root:RegisterForDrag("LeftButton")
    root:SetScript("OnDragStart", root.StartMoving)
    root:SetScript("OnDragStop", root.StopMovingOrSizing)
    root:SetClipsChildren(true)
    root:Hide()

    root.ClassBackground = root:CreateTexture(nil, "BACKGROUND")
    UpdateClassBackgroundTexture(root.ClassBackground, root)
    root:SetScript("OnSizeChanged", function(self)
        UpdateClassBackgroundTexture(self.ClassBackground, self)
    end)

    if root.SetBackdrop then
        root:SetBackdrop({
            edgeFile = "Interface\\Buttons\\WHITE8x8",
            tile = false,
            edgeSize = 2,
            insets = { left = 0, right = 0, top = 0, bottom = 0 },
        })
        root:SetBackdropBorderColor(0, 0, 0, 1)
        root:SetBackdropColor(0, 0, 0, 0)
    end

    root.TitleBar = CreateFrame("Frame", nil, root, backdropTemplate)
    local titleBar = root.TitleBar
    titleBar:SetHeight(40)
    titleBar:SetPoint("TOPLEFT", root, "TOPLEFT", 0, 0)
    titleBar:SetPoint("TOPRIGHT", root, "TOPRIGHT", 0, 0)
    titleBar:SetFrameLevel(root:GetFrameLevel() + 5)
    if titleBar.SetBackdrop then
        titleBar:SetBackdrop({
            edgeFile = "Interface\\Buttons\\WHITE8x8",
            tile = false,
            edgeSize = 2,
            insets = { left = 0, right = 0, top = 0, bottom = 0 },
        })
        titleBar:SetBackdropBorderColor(0, 0, 0, 1)
        titleBar:SetBackdropColor(0, 0, 0, 0.95)
    end

    local titleBarBg = titleBar:CreateTexture(nil, "BACKGROUND")
    titleBarBg:SetAllPoints()
    titleBarBg:SetTexture(HEADER_TEX)
    titleBarBg:SetTexCoord(0, 1, 0, 1)

    local logoSize = 28
    local titleBarLogo = titleBar:CreateTexture(nil, "OVERLAY")
    titleBarLogo:SetSize(logoSize, logoSize)
    titleBarLogo:SetPoint("LEFT", titleBar, "LEFT", 6, 0)
    titleBarLogo:SetTexture(logoTexture)
    titleBarLogo:SetTexCoord(0, 1, 0, 1)

    local titleText = titleBar:CreateFontString(nil, "OVERLAY", "GameFontHighlight")
    titleText:SetPoint("CENTER", titleBar, "CENTER", 0, 0)
    SafeSetFont(titleText, POINTS_FONT_PATH, 18, "GameFontHighlightHuge")
    local tr, tg, tb = GetPlayerClassColor()
    titleText:SetTextColor(tr, tg, tb)
    titleText:SetText(title)

    local closeBtn = CreateFrame("Button", nil, titleBar, "UIPanelCloseButton")
    closeBtn:SetPoint("RIGHT", titleBar, "RIGHT", -12, 0)
    closeBtn:SetSize(16, 16)
    closeBtn:SetNormalTexture(CLOSE_TEX)
    closeBtn:SetPushedTexture(CLOSE_TEX)
    closeBtn:SetHighlightTexture("Interface\\Buttons\\UI-Panel-MinimizeButton-Highlight", "ADD")
    for _, tex in ipairs({ closeBtn:GetNormalTexture(), closeBtn:GetPushedTexture() }) do
        if tex then tex:SetTexCoord(0, 1, 0, 1) end
    end
    closeBtn:SetScript("OnClick", function()
        root:Hide()
    end)

    local divider = CreateFrame("Frame", nil, root)
    divider:SetHeight(20)
    divider:SetPoint("TOPLEFT", titleBar, "BOTTOMLEFT", -4, 4)
    divider:SetPoint("TOPRIGHT", titleBar, "BOTTOMRIGHT", 4, 4)
    divider:SetFrameLevel(titleBar:GetFrameLevel())
    local dividerTex = divider:CreateTexture(nil, "ARTWORK")
    dividerTex:SetAllPoints()
    dividerTex:SetTexture(DIVIDER_TEX)
    dividerTex:SetTexCoord(0, 1, 0, 1)

    root.Footer = CreateFrame("Frame", nil, root)
    root.Footer:SetHeight(68)
    root.Footer:SetPoint("BOTTOMLEFT", root, "BOTTOMLEFT", 0, 0)
    root.Footer:SetPoint("BOTTOMRIGHT", root, "BOTTOMRIGHT", 0, 0)
    root.Footer:SetFrameLevel(root:GetFrameLevel() + 2)
    local footBg = root.Footer:CreateTexture(nil, "BACKGROUND")
    footBg:SetAllPoints()
    footBg:SetColorTexture(0, 0, 0, 0.75)

    root.Body = CreateFrame("Frame", nil, root)
    root.Body:SetPoint("TOPLEFT", divider, "BOTTOMLEFT", 12, -8)
    root.Body:SetPoint("BOTTOMRIGHT", root.Footer, "TOPRIGHT", -12, 6)

    root._logoTexture = logoTexture
    root._titleFontString = titleText
    root._pointFontPath = POINTS_FONT_PATH
    root._checkboxNormal = CHECKBOX_NORMAL
    root._checkboxActive = CHECKBOX_ACTIVE

    function root:RefreshTheme()
        UpdateClassBackgroundTexture(self.ClassBackground, self)
        local r, g, b = GetPlayerClassColor()
        if self._titleFontString then
            self._titleFontString:SetTextColor(r, g, b)
        end
    end

    return root
end

function UI:CreateBodyScroll(host)
    local backdropTemplate = BackdropTemplateMixin and "BackdropTemplate" or nil

    local bg = CreateFrame("Frame", nil, host, backdropTemplate)
    bg:SetAllPoints(host)
    bg:EnableMouse(false)
    bg:SetFrameLevel((host:GetFrameLevel() or 0))
    if bg.SetBackdrop then
        bg:SetBackdrop({
            bgFile = "Interface\\Buttons\\WHITE8x8",
            edgeFile = "Interface\\Buttons\\WHITE8x8",
            edgeSize = 1,
        })
        bg:SetBackdropColor(0, 0, 0, 0.4)
        bg:SetBackdropBorderColor(0.282, 0.275, 0.259)
    else
        local t = bg:CreateTexture(nil, "BACKGROUND")
        t:SetAllPoints()
        t:SetColorTexture(0, 0, 0, 0.4)
    end

    local scroll = CreateFrame("ScrollFrame", nil, host, "UIPanelScrollFrameTemplate")
    scroll:SetAllPoints(host)
    scroll:SetFrameLevel(bg:GetFrameLevel() + 2)

    local child = CreateFrame("Frame", nil, scroll)
    local function syncChildWidth()
        local w = scroll:GetWidth()
        if w and w > 40 then
            child:SetWidth(w - 20)
        end
    end
    syncChildWidth()
    scroll:SetScript("OnSizeChanged", function()
        syncChildWidth()
    end)
    child:SetHeight(1)
    scroll:SetScrollChild(child)
    scroll:EnableMouseWheel(true)
    scroll:SetScript("OnMouseWheel", function(self, delta)
        local step = 40
        local cur = self:GetVerticalScroll() or 0
        local maxV = self:GetVerticalScrollRange() or 0
        local newV = math.min(maxV, math.max(0, cur - delta * step))
        self:SetVerticalScroll(newV)
        local sb = self.ScrollBar
        if sb and sb.SetValue then sb:SetValue(newV) end
    end)
    StyleScrollBar(scroll, 4)

    return scroll, child
end

--- Порядок секций в UI выбора / активных челленджей (id должен совпадать с challenge.category).
UI.CHALLENGE_CATEGORY_ORDER = {
    "Lore",
    "Restrictions",
    "Progression",
    "Combat",
}

UI.ChallengeCategoryLabel = {
    Lore = "Lore",
    Restrictions = "Restrictions",
    Progression = "Progression",
    Combat = "Combat",
}

local DEFAULT_CHALLENGE_CATEGORY = "Progression"

--- Секции с отсортированными ключами челленджей (hubOnly не включаются).
function UI.GetChallengeSections()
    local order = UI.CHALLENGE_CATEGORY_ORDER
    local byCat = {}
    for i = 1, #order do
        byCat[order[i]] = {}
    end
    for k, def in pairs(addon.Challenges or {}) do
        if not def.hubOnly then
            local cat = def.category
            if not cat or not byCat[cat] then
                cat = DEFAULT_CHALLENGE_CATEGORY
                if not byCat[cat] then
                    byCat[cat] = {}
                end
            end
            byCat[cat][#byCat[cat] + 1] = k
        end
    end
    local sections = {}
    for i = 1, #order do
        local cat = order[i]
        local keys = byCat[cat]
        if keys and #keys > 0 then
            table.sort(keys, function(a, b)
                local na = addon.Challenges[a] and addon.Challenges[a].name or a
                local nb = addon.Challenges[b] and addon.Challenges[b].name or b
                return na < nb
            end)
            sections[#sections + 1] = {
                id = cat,
                title = UI.ChallengeCategoryLabel[cat] or cat,
                keys = keys,
            }
        end
    end
    return sections
end

--- Плоский порядок ключей (категории по CHALLENGE_CATEGORY_ORDER, внутри — по имени).
function UI.SortedChallengeKeys()
    local keys = {}
    for _, sec in ipairs(UI.GetChallengeSections()) do
        for _, k in ipairs(sec.keys) do
            keys[#keys + 1] = k
        end
    end
    return keys
end

UI.SafeSetFont = SafeSetFont
