-- Necrotic Plague Tracker (8-Group Roster Grid Edition) for WotLK 3.3.5a
-- Author: Copper
local ADDON_NAME = ...

local TILE_SIZE = 30
local GROUPS_COUNT = 8
local SLOTS_PER_GROUP = 5

local ICON_PATH = "Interface\\Icons\\Ability_Creature_Disease_02"
local ALERT_SOUND_PATH = "Sound\\Spells\\PVPFlagTaken.wav"

local PLAGUE_SPELL_IDS = {
    [70337] = true, [70338] = true, [73780] = true, [73912] = true,
}

-- Standard Blizzard RAID_CLASS_COLORS fallback table (Exact WotLK RGB)
local CLASS_COLORS = {
    ["DEATHKNIGHT"] = { r = 0.77, g = 0.12, b = 0.23 },
    ["DRUID"]       = { r = 1.00, g = 0.49, b = 0.04 },
    ["HUNTER"]      = { r = 0.67, g = 0.83, b = 0.45 },
    ["MAGE"]        = { r = 0.41, g = 0.80, b = 0.94 },
    ["PALADIN"]     = { r = 0.96, g = 0.55, b = 0.73 },
    ["PRIEST"]      = { r = 1.00, g = 1.00, b = 1.00 },
    ["ROGUE"]       = { r = 1.00, g = 0.96, b = 0.41 },
    ["SHAMAN"]      = { r = 0.00, g = 0.44, b = 0.87 },
    ["WARLOCK"]     = { r = 0.58, g = 0.51, b = 0.79 },
    ["WARRIOR"]     = { r = 0.78, g = 0.61, b = 0.43 },
}

local InitFrame = CreateFrame("Frame")
InitFrame:RegisterEvent("ADDON_LOADED")
InitFrame:RegisterEvent("PLAYER_ENTERING_WORLD")

----------------------------------------------------
-- HELPER FUNCTIONS
----------------------------------------------------
local function GetClassColor(unit)
    if unit and UnitExists(unit) then
        local _, classFileName = UnitClass(unit)
        if classFileName then
            if RAID_CLASS_COLORS and RAID_CLASS_COLORS[classFileName] then
                local c = RAID_CLASS_COLORS[classFileName]
                return c.r, c.g, c.b
            elseif CLASS_COLORS[classFileName] then
                local c = CLASS_COLORS[classFileName]
                return c.r, c.g, c.b
            end
        end
    end
    return 0.2, 0.2, 0.2
end

----------------------------------------------------
-- 1. WELCOME & HELP DIALOG
----------------------------------------------------
local WelcomeDialog = CreateFrame("Frame", "NPT_WelcomeDialog", UIParent)
WelcomeDialog:SetSize(360, 200)
WelcomeDialog:SetPoint("CENTER", UIParent, "CENTER", 0, 0)
WelcomeDialog:SetMovable(true)
WelcomeDialog:EnableMouse(true)
WelcomeDialog:SetClampedToScreen(true)
WelcomeDialog:RegisterForDrag("LeftButton")
WelcomeDialog:SetScript("OnDragStart", function(self) self:StartMoving() end)
WelcomeDialog:SetScript("OnDragStop", function(self) self:StopMovingOrSizing() end)
WelcomeDialog:SetFrameStrata("DIALOG")

tinsert(UISpecialFrames, "NPT_WelcomeDialog")

local WelcomeTitle = WelcomeDialog:CreateFontString(nil, "OVERLAY", "GameFontNormal")
WelcomeTitle:SetPoint("TOP", WelcomeDialog, "TOP", 0, -16)
WelcomeTitle:SetText("Necrotic Plague Tracker")

local WelcomeText = WelcomeDialog:CreateFontString(nil, "OVERLAY", "GameFontHighlight")
WelcomeText:SetPoint("TOPLEFT", WelcomeDialog, "TOPLEFT", 22, -42)
WelcomeText:SetPoint("BOTTOMRIGHT", WelcomeDialog, "BOTTOMRIGHT", -22, 50)
WelcomeText:SetJustifyH("LEFT")
WelcomeText:SetJustifyV("TOP")
WelcomeText:SetText("Welcome to the Necrotic Plague Tracker addon by Copper. Click the minimap button or the title bar config button to open settings and position the frame.")

local function MarkWelcomeAsSeen()
    NPT_Position = NPT_Position or {}
    NPT_Position.hasSeenWelcome = true
    WelcomeDialog:Hide()
end

WelcomeDialog:SetScript("OnHide", function()
    if NPT_Position then
        NPT_Position.hasSeenWelcome = true
    end
end)

local WelcomeOKButton = CreateFrame("Button", nil, WelcomeDialog, "UIPanelButtonTemplate")
WelcomeOKButton:SetSize(90, 22)
WelcomeOKButton:SetPoint("BOTTOM", WelcomeDialog, "BOTTOM", 0, 16)
WelcomeOKButton:SetText("OK")
WelcomeOKButton:SetScript("OnClick", MarkWelcomeAsSeen)

WelcomeDialog:Hide()

----------------------------------------------------
-- 2. TITLE HEADER ANCHOR & DUMMY GRID
----------------------------------------------------
local GRID_WIDTH = (TILE_SIZE * GROUPS_COUNT) + ((GROUPS_COUNT - 1) * 2)

local AnchorFrame = CreateFrame("Frame", "NPT_AnchorFrame", UIParent)
AnchorFrame:SetSize(GRID_WIDTH, 18)
AnchorFrame:SetMovable(true)
AnchorFrame:EnableMouse(true)
AnchorFrame:SetClampedToScreen(true)

local AnchorBg = AnchorFrame:CreateTexture(nil, "BACKGROUND")
AnchorBg:SetAllPoints(AnchorFrame)

local AnchorBorder = AnchorFrame:CreateTexture(nil, "BORDER")
AnchorBorder:SetAllPoints(AnchorFrame)

local AnchorText = AnchorFrame:CreateFontString(nil, "OVERLAY", "GameFontHighlightSmall")
AnchorText:SetPoint("LEFT", AnchorFrame, "LEFT", 5, 0)
AnchorText:SetText("Necrotic Plague Tracker")

-- Title Bar Config Gear/Button
local AnchorConfigBtn = CreateFrame("Button", nil, AnchorFrame)
AnchorConfigBtn:SetSize(14, 14)
AnchorConfigBtn:SetPoint("RIGHT", AnchorFrame, "RIGHT", -3, 0)

local AnchorConfigIcon = AnchorConfigBtn:CreateTexture(nil, "ARTWORK")
AnchorConfigIcon:SetAllPoints(AnchorConfigBtn)
AnchorConfigIcon:SetTexture("Interface\\WorldMap\\Gear_64")

AnchorConfigBtn:SetScript("OnClick", function()
    ToggleConfigPanel()
end)

AnchorConfigBtn:SetScript("OnEnter", function(self)
    GameTooltip:SetOwner(self, "ANCHOR_RIGHT")
    GameTooltip:AddLine("Open NPT Config", 1, 1, 1)
    GameTooltip:Show()
end)

AnchorConfigBtn:SetScript("OnLeave", function(self)
    GameTooltip:Hide()
end)

local function UpdateAnchorVisuals()
    if NPT_Locked then
        AnchorBg:SetTexture(0.05, 0.05, 0.05, 0.85)
        AnchorBorder:SetTexture(0.2, 0.2, 0.2, 0.6)
    else
        AnchorBg:SetTexture(0.0, 0.45, 0.75, 0.85)
        AnchorBorder:SetTexture(0.2, 0.8, 1.0, 0.9)
    end
end

AnchorFrame:RegisterForDrag("LeftButton")
AnchorFrame:SetScript("OnDragStart", function(self)
    if not NPT_Locked and not InCombatLockdown() then
        self:StartMoving()
        self.isMoving = true
    end
end)

AnchorFrame:SetScript("OnDragStop", function(self)
    if self.isMoving then
        self:StopMovingOrSizing()
        self.isMoving = false
        local point, _, relativePoint, x, y = self:GetPoint()
        NPT_Position = NPT_Position or {}
        NPT_Position.point = point
        NPT_Position.relativePoint = relativePoint
        NPT_Position.x = x
        NPT_Position.y = y
    end
end)

-- Background Dummy Grid (40 slots across 8 columns)
local DummyGrid = {}
for col = 0, GROUPS_COUNT - 1 do
    DummyGrid[col] = {}
    for row = 0, SLOTS_PER_GROUP - 1 do
        local dummy = CreateFrame("Frame", nil, UIParent)
        dummy:SetSize(TILE_SIZE, TILE_SIZE)
        dummy:SetPoint("TOPLEFT", AnchorFrame, "BOTTOMLEFT", col * (TILE_SIZE + 2), -row * (TILE_SIZE + 2) - 3)
        dummy:SetFrameLevel(1)

        local border = dummy:CreateTexture(nil, "BACKGROUND")
        border:SetAllPoints(dummy)
        border:SetTexture(1, 1, 1, 0.1)

        local bg = dummy:CreateTexture(nil, "BORDER")
        bg:SetPoint("TOPLEFT", dummy, "TOPLEFT", 1, -1)
        bg:SetPoint("BOTTOMRIGHT", dummy, "BOTTOMRIGHT", -1, 1)
        bg:SetTexture(0.05, 0.05, 0.05, 0.3)

        dummy:Hide()
        DummyGrid[col][row] = dummy
    end
end

-- Secure Button Factory
local function CreateTileButton(name, unitID)
    local btn = CreateFrame("Button", name, UIParent, "SecureActionButtonTemplate")
    btn:SetSize(TILE_SIZE, TILE_SIZE)
    btn:SetFrameLevel(5)

    btn:RegisterForClicks("LeftButtonUp", "RightButtonUp")
    btn:SetAttribute("type1", "target")
    btn:SetAttribute("unit", unitID)

    local border = btn:CreateTexture(nil, "BACKGROUND")
    border:SetAllPoints(btn)
    border:SetTexture(0.15, 0.15, 0.15, 0.3)
    btn.border = border

    local bg = btn:CreateTexture(nil, "BORDER")
    bg:SetPoint("TOPLEFT", btn, "TOPLEFT", 1, -1)
    bg:SetPoint("BOTTOMRIGHT", btn, "BOTTOMRIGHT", -1, 1)
    bg:SetTexture(0.08, 0.08, 0.08, 0.6)
    btn.bg = bg

    -- 1px Outer Hover Frame Overlay
    local hoverFrame = CreateFrame("Frame", nil, btn)
    hoverFrame:SetPoint("TOPLEFT", btn, "TOPLEFT", -1, 1)
    hoverFrame:SetPoint("BOTTOMRIGHT", btn, "BOTTOMRIGHT", 1, -1)
    hoverFrame:SetFrameLevel(btn:GetFrameLevel() + 5)
    hoverFrame:Hide()

    local top = hoverFrame:CreateTexture(nil, "OVERLAY")
    top:SetPoint("TOPLEFT", hoverFrame, "TOPLEFT")
    top:SetPoint("TOPRIGHT", hoverFrame, "TOPRIGHT")
    top:SetHeight(1)
    top:SetTexture(1, 1, 1, 0.9)

    local bottom = hoverFrame:CreateTexture(nil, "OVERLAY")
    bottom:SetPoint("BOTTOMLEFT", hoverFrame, "BOTTOMLEFT")
    bottom:SetPoint("BOTTOMRIGHT", hoverFrame, "BOTTOMRIGHT")
    bottom:SetHeight(1)
    bottom:SetTexture(1, 1, 1, 0.9)

    local left = hoverFrame:CreateTexture(nil, "OVERLAY")
    left:SetPoint("TOPLEFT", hoverFrame, "TOPLEFT")
    left:SetPoint("BOTTOMLEFT", hoverFrame, "BOTTOMLEFT")
    left:SetWidth(1)
    left:SetTexture(1, 1, 1, 0.9)

    local right = hoverFrame:CreateTexture(nil, "OVERLAY")
    right:SetPoint("TOPRIGHT", hoverFrame, "TOPRIGHT")
    right:SetPoint("BOTTOMRIGHT", hoverFrame, "BOTTOMRIGHT")
    right:SetWidth(1)
    right:SetTexture(1, 1, 1, 0.9)

    btn.hoverFrame = hoverFrame

    btn:SetScript("OnEnter", function(self)
        self.hoverFrame:Show()
    end)
    btn:SetScript("OnLeave", function(self)
        self.hoverFrame:Hide()
    end)

    local nameText = btn:CreateFontString(nil, "OVERLAY", "GameFontNormalSmall")
    nameText:SetPoint("TOP", btn, "TOP", 0, -2)
    nameText:SetTextColor(0.6, 0.6, 0.6)
    nameText:SetShadowColor(0, 0, 0, 1)
    nameText:SetShadowOffset(1, -1)
    btn.nameText = nameText

    local timerText = btn:CreateFontString(nil, "OVERLAY", "GameFontHighlightSmall")
    timerText:SetPoint("BOTTOM", btn, "BOTTOM", 0, 2)
    timerText:SetShadowColor(0, 0, 0, 1)
    timerText:SetShadowOffset(1, -1)
    btn.timerText = timerText

    btn:Hide()
    return btn
end

-- Party & Raid Tiles
local PartyTiles = {}
local PartyUnits = { "player", "party1", "party2", "party3", "party4" }
for idx, unitID in ipairs(PartyUnits) do
    local btn = CreateTileButton("NPT_PartyTile_" .. unitID, unitID)
    btn:SetPoint("TOPLEFT", AnchorFrame, "BOTTOMLEFT", 0, -(idx - 1) * (TILE_SIZE + 2) - 3)
    PartyTiles[unitID] = btn
end

local RaidTiles = {}
for idx = 1, 40 do
    local unitID = "raid" .. idx
    RaidTiles[unitID] = CreateTileButton("NPT_RaidTile_" .. unitID, unitID)
end

----------------------------------------------------
-- 3. CONFIGURATION PANEL
----------------------------------------------------
local ConfigPanel = CreateFrame("Frame", "NPT_ConfigPanel", UIParent)
ConfigPanel:SetSize(260, 260)
ConfigPanel:SetPoint("CENTER", UIParent, "CENTER", 0, 0)
ConfigPanel:SetMovable(true)
ConfigPanel:EnableMouse(true)
ConfigPanel:SetClampedToScreen(true)
ConfigPanel:RegisterForDrag("LeftButton")
ConfigPanel:SetScript("OnDragStart", ConfigPanel.StartMoving)
ConfigPanel:SetScript("OnDragStop", ConfigPanel.StopMovingOrSizing)
ConfigPanel:SetFrameStrata("DIALOG")
ConfigPanel:Hide()

ConfigPanel:SetBackdrop({
    bgFile = "Interface\\DialogFrame\\UI-DialogBox-Background",
    edgeFile = "Interface\\DialogFrame\\UI-DialogBox-Border",
    tile = true, tileSize = 32, edgeSize = 32,
    insets = { left = 11, right = 12, top = 12, bottom = 11 }
})

tinsert(UISpecialFrames, "NPT_ConfigPanel")

local ConfigTitle = ConfigPanel:CreateFontString(nil, "OVERLAY", "GameFontNormal")
ConfigTitle:SetPoint("TOP", ConfigPanel, "TOP", 0, -16)
ConfigTitle:SetText("Necrotic Plague Tracker")

local CloseButton = CreateFrame("Button", nil, ConfigPanel, "UIPanelCloseButton")
CloseButton:SetPoint("TOPRIGHT", ConfigPanel, "TOPRIGHT", -5, -5)

local EnableCheckbox = CreateFrame("CheckButton", "NPT_EnableCheckbox", ConfigPanel, "InterfaceOptionsCheckButtonTemplate")
EnableCheckbox:SetPoint("TOPLEFT", ConfigPanel, "TOPLEFT", 25, -45)
_G[EnableCheckbox:GetName() .. "Text"]:SetText(" Enable Necrotic Plague Tracker")
EnableCheckbox:SetScript("OnClick", function(self)
    NPT_Enabled = self:GetChecked()
    NPT_UpdateDisplay()
end)

local LockCheckbox = CreateFrame("CheckButton", "NPT_LockCheckbox", ConfigPanel, "InterfaceOptionsCheckButtonTemplate")
LockCheckbox:SetPoint("TOPLEFT", EnableCheckbox, "BOTTOMLEFT", 0, -4)
_G[LockCheckbox:GetName() .. "Text"]:SetText(" Lock Frame Anchor")
LockCheckbox:SetScript("OnClick", function(self)
    NPT_Locked = self:GetChecked()
    UpdateAnchorVisuals()
end)

local TestCheckbox = CreateFrame("CheckButton", "NPT_TestCheckbox", ConfigPanel, "InterfaceOptionsCheckButtonTemplate")
TestCheckbox:SetPoint("TOPLEFT", LockCheckbox, "BOTTOMLEFT", 0, -4)
_G[TestCheckbox:GetName() .. "Text"]:SetText(" Enable Test Mode")
TestCheckbox:SetScript("OnClick", function(self)
    NPT_TestMode = self:GetChecked()
    TestMode_NextSwapTime = nil
    TestMode_CurrentUnit = nil
    NPT_UpdateDisplay()
end)

local SoundCheckbox = CreateFrame("CheckButton", "NPT_SoundCheckbox", ConfigPanel, "InterfaceOptionsCheckButtonTemplate")
SoundCheckbox:SetPoint("TOPLEFT", TestCheckbox, "BOTTOMLEFT", 0, -4)
_G[SoundCheckbox:GetName() .. "Text"]:SetText(" Play Audio Warning (3s)")
SoundCheckbox:SetScript("OnClick", function(self)
    NPT_Position = NPT_Position or {}
    NPT_Position.audioAlert = self:GetChecked()
end)

local ResetButton = CreateFrame("Button", nil, ConfigPanel, "UIPanelButtonTemplate")
ResetButton:SetSize(105, 22)
ResetButton:SetPoint("TOPRIGHT", ConfigPanel, "TOP", -5, -170)
ResetButton:SetText("Reset Pos")
ResetButton:SetScript("OnClick", function()
    AnchorFrame:ClearAllPoints()
    AnchorFrame:SetPoint("CENTER", UIParent, "CENTER", 0, 100)
    NPT_Position = NPT_Position or {}
    NPT_Position.point = "CENTER"
    NPT_Position.relativePoint = "CENTER"
    NPT_Position.x = 0
    NPT_Position.y = 100

    ConfigPanel:ClearAllPoints()
    ConfigPanel:SetPoint("CENTER", UIParent, "CENTER", 0, 0)

    WelcomeDialog:ClearAllPoints()
    WelcomeDialog:SetPoint("CENTER", UIParent, "CENTER", 0, 0)
end)

local HelpButton = CreateFrame("Button", nil, ConfigPanel, "UIPanelButtonTemplate")
HelpButton:SetSize(105, 22)
HelpButton:SetPoint("TOPLEFT", ConfigPanel, "TOP", 5, -170)
HelpButton:SetText("Help")
HelpButton:SetScript("OnClick", function()
    WelcomeDialog:Show()
end)

local DoneButton = CreateFrame("Button", nil, ConfigPanel, "UIPanelButtonTemplate")
DoneButton:SetSize(90, 22)
DoneButton:SetPoint("BOTTOM", ConfigPanel, "BOTTOM", 0, 18)
DoneButton:SetText("Done")
DoneButton:SetScript("OnClick", function() ConfigPanel:Hide() end)

function ToggleConfigPanel()
    if ConfigPanel:IsShown() then
        ConfigPanel:Hide()
    else
        EnableCheckbox:SetChecked(NPT_Enabled)
        LockCheckbox:SetChecked(NPT_Locked)
        TestCheckbox:SetChecked(NPT_TestMode)
        SoundCheckbox:SetChecked(NPT_Position and NPT_Position.audioAlert ~= false)
        ConfigPanel:Show()
    end
end

----------------------------------------------------
-- 4. MINIMAP BUTTON
----------------------------------------------------
local MinimapBtn = CreateFrame("Button", "NPT_MinimapButton", Minimap)
MinimapBtn:SetSize(31, 31)
MinimapBtn:SetFrameStrata("LOW")
MinimapBtn:SetFrameLevel(9)
MinimapBtn:SetHighlightTexture("Interface\\Minimap\\UI-Minimap-ZoomButton-Highlight")

local MinimapIcon = MinimapBtn:CreateTexture("NPT_MinimapIconTexture", "ARTWORK")
MinimapIcon:SetSize(20, 20)
MinimapIcon:SetPoint("CENTER", MinimapBtn, "CENTER", 0, 0)
MinimapIcon:SetTexture(ICON_PATH)
MinimapIcon:SetTexCoord(0.07, 0.93, 0.07, 0.93)

local MinimapBorder = MinimapBtn:CreateTexture(nil, "OVERLAY")
MinimapBorder:SetTexture("Interface\\Minimap\\MiniMap-TrackingBorder")
MinimapBorder:SetSize(53, 53)
MinimapBorder:SetPoint("TOPLEFT", MinimapBtn, "TOPLEFT", 0, 0)

local function UpdateMinimapButtonPosition()
    local angle = math.rad(NPT_MinimapPos or 45)
    MinimapBtn:SetPoint("CENTER", Minimap, "CENTER", math.cos(angle) * 80, math.sin(angle) * 80)
end

MinimapBtn:EnableMouse(true)
MinimapBtn:RegisterForDrag("LeftButton")
MinimapBtn:SetScript("OnDragStart", function(self) self.isDragging = true end)
MinimapBtn:SetScript("OnDragStop", function(self) self.isDragging = false end)
MinimapBtn:SetScript("OnUpdate", function(self)
    if self.isDragging then
        local mx, my = Minimap:GetCenter()
        local px, py = GetCursorPosition()
        local scale = Minimap:GetEffectiveScale()
        local angle = math.deg(math.atan2((py/scale) - my, (px/scale) - mx))
        if angle < 0 then angle = angle + 360 end
        NPT_MinimapPos = angle
        UpdateMinimapButtonPosition()
    end
end)
MinimapBtn:SetScript("OnClick", ToggleConfigPanel)

MinimapBtn:SetScript("OnEnter", function(self)
    GameTooltip:SetOwner(self, "ANCHOR_LEFT")
    GameTooltip:AddLine("Necrotic Plague Tracker", 1, 1, 1)
    GameTooltip:AddLine("Left-Click: Open Config Panel", 0.2, 0.8, 1)
    GameTooltip:Show()
end)

MinimapBtn:SetScript("OnLeave", function(self)
    GameTooltip:Hide()
end)

----------------------------------------------------
-- 5. CORE ENGINE & LOGIC
----------------------------------------------------
local function IsInFrozenThrone()
    local subZone = string.lower(GetSubZoneText() or "")
    local miniZone = string.lower(GetMinimapZoneText() or "")
    return (string.find(subZone, "frozen throne") or string.find(miniZone, "frozen throne")) ~= nil
end

local function UpdateRaidPositions()
    if InCombatLockdown() then return end

    local groupCounts = {0, 0, 0, 0, 0, 0, 0, 0}
    local raidCount = GetNumRaidMembers()

    if raidCount > 0 then
        for i = 1, raidCount do
            local unitID = "raid" .. i
            local _, _, subgroup = GetRaidRosterInfo(i)
            subgroup = subgroup or 1

            if subgroup >= 1 and subgroup <= 8 then
                local row = groupCounts[subgroup]
                if row < SLOTS_PER_GROUP then
                    groupCounts[subgroup] = groupCounts[subgroup] + 1
                    local col = subgroup - 1

                    local btn = RaidTiles[unitID]
                    if btn then
                        btn:ClearAllPoints()
                        btn:SetPoint("TOPLEFT", AnchorFrame, "BOTTOMLEFT", col * (TILE_SIZE + 2), -row * (TILE_SIZE + 2) - 3)
                    end
                end
            end
        end
    else
        for i = 1, 40 do
            local unitID = "raid" .. i
            local col = math.floor((i - 1) / SLOTS_PER_GROUP)
            local row = (i - 1) % SLOTS_PER_GROUP
            local btn = RaidTiles[unitID]
            if btn then
                btn:ClearAllPoints()
                btn:SetPoint("TOPLEFT", AnchorFrame, "BOTTOMLEFT", col * (TILE_SIZE + 2), -row * (TILE_SIZE + 2) - 3)
            end
        end
    end
end

-- Strictly scans for Disease + Necrotic Plague and selects candidate with highest remaining duration
local function ScanForPlague()
    local bestCarrier = nil
    local highestRemaining = -1
    local currentTime = GetTime()

    local function CheckUnit(u)
        if not UnitExists(u) then return end
        for j = 1, 40 do
            local dName, _, _, _, dType, _, expTime, _, _, _, spellID = UnitDebuff(u, j)
            if not dName then break end

            if dType == "Disease" and (dName == "Necrotic Plague" or PLAGUE_SPELL_IDS[spellID]) then
                local expiration = expTime or (currentTime + 15)
                local remaining = expiration - currentTime

                if remaining > highestRemaining then
                    highestRemaining = remaining
                    bestCarrier = {
                        name = UnitName(u) or u,
                        unit = u,
                        expiration = expiration
                    }
                end
            end
        end
    end

    local raidCount = GetNumRaidMembers()
    local partyCount = GetNumPartyMembers()

    if raidCount > 0 then
        for i = 1, raidCount do CheckUnit("raid" .. i) end
    elseif partyCount > 0 then
        CheckUnit("player")
        for i = 1, partyCount do CheckUnit("party" .. i) end
    else
        CheckUnit("player")
    end

    return bestCarrier
end

local TestMode_NextSwapTime = nil
local TestMode_CurrentUnit = nil
local ActiveCarrier = nil
local PlayedAudioForExpTime = nil

function NPT_UpdateDisplay()
    local currentTime = GetTime()
    local inThrone = IsInFrozenThrone()
    local showAddon = NPT_Enabled and (NPT_TestMode or inThrone)

    local previousCarrierUnit = ActiveCarrier and ActiveCarrier.unit or nil
    ActiveCarrier = nil
    UpdateRaidPositions()

    if not showAddon then
        AnchorFrame:Hide()
        for col = 0, GROUPS_COUNT - 1 do
            for row = 0, SLOTS_PER_GROUP - 1 do
                DummyGrid[col][row]:Hide()
            end
        end
        if not InCombatLockdown() then
            for _, btn in pairs(PartyTiles) do btn:Hide() end
            for _, btn in pairs(RaidTiles) do btn:Hide() end
        end
        return
    else
        AnchorFrame:Show()
        for col = 0, GROUPS_COUNT - 1 do
            for row = 0, SLOTS_PER_GROUP - 1 do
                DummyGrid[col][row]:Show()
            end
        end
    end

    local raidCount = GetNumRaidMembers()
    local partyCount = GetNumPartyMembers()
    local inRaid = raidCount > 0

    if NPT_TestMode then
        local onlineUnits = {}
        if inRaid then
            for i = 1, raidCount do
                local u = "raid" .. i
                if UnitExists(u) and UnitIsConnected(u) then
                    table.insert(onlineUnits, u)
                end
            end
        elseif partyCount > 0 then
            if UnitIsConnected("player") then table.insert(onlineUnits, "player") end
            for i = 1, partyCount do
                local u = "party" .. i
                if UnitExists(u) and UnitIsConnected(u) then
                    table.insert(onlineUnits, u)
                end
            end
        else
            table.insert(onlineUnits, "player")
        end

        if #onlineUnits > 0 then
            if not TestMode_NextSwapTime or currentTime >= TestMode_NextSwapTime or not TestMode_CurrentUnit or not UnitExists(TestMode_CurrentUnit) or not UnitIsConnected(TestMode_CurrentUnit) then
                local randomIndex = math.random(1, #onlineUnits)
                TestMode_CurrentUnit = onlineUnits[randomIndex]
                TestMode_NextSwapTime = currentTime + 30
            end
            local u = TestMode_CurrentUnit
            ActiveCarrier = {
                name = UnitName(u) or u,
                unit = u,
                expiration = TestMode_NextSwapTime
            }
        end
    else
        ActiveCarrier = ScanForPlague()
    end

    -- Reset audio lockout state if active carrier changed or dropped
    if not ActiveCarrier or (ActiveCarrier and ActiveCarrier.unit ~= previousCarrierUnit) then
        PlayedAudioForExpTime = nil
    end

    -- Render Raid Grid
    if inRaid or (NPT_TestMode and raidCount > 0) then
        if not InCombatLockdown() then
            for _, btn in pairs(PartyTiles) do btn:Hide() end
        end

        for idx = 1, 40 do
            local unitID = "raid" .. idx
            local btn = RaidTiles[unitID]
            local exists = UnitExists(unitID)

            if exists then
                if not btn:IsShown() and not InCombatLockdown() then btn:Show() end

                local isCarrier = ActiveCarrier and (ActiveCarrier.unit == unitID)
                local name = UnitName(unitID) or ""
                local shortName = string.sub(name, 1, 3)

                if isCarrier then
                    local r, g, b = GetClassColor(unitID)
                    btn.nameText:SetText(shortName)
                    btn.nameText:SetTextColor(1, 1, 1)

                    local remaining = math.max(0, ActiveCarrier.expiration - currentTime)
                    btn.timerText:SetText(string.format("%.0fs", remaining))
                    btn.timerText:SetTextColor(1, 1, 1)

                    btn.bg:SetTexture(r, g, b, 1.0)
                    btn.border:SetTexture(0, 0, 0, 0)
                else
                    btn.nameText:SetText(shortName)
                    btn.nameText:SetTextColor(0.6, 0.6, 0.6)
                    btn.timerText:SetText("")

                    btn.bg:SetTexture(0.08, 0.08, 0.08, 0.6)
                    btn.border:SetTexture(0.15, 0.15, 0.15, 0.3)
                end
            else
                if btn:IsShown() and not InCombatLockdown() then btn:Hide() end
            end
        end
    else
        if not InCombatLockdown() then
            for _, btn in pairs(RaidTiles) do btn:Hide() end
        end

        for _, unitID in ipairs(PartyUnits) do
            local btn = PartyTiles[unitID]
            local exists = UnitExists(unitID)

            if exists then
                if not btn:IsShown() and not InCombatLockdown() then btn:Show() end

                local isCarrier = ActiveCarrier and (ActiveCarrier.unit == unitID)
                local name = UnitName(unitID) or ""
                local shortName = string.sub(name, 1, 3)

                if isCarrier then
                    local r, g, b = GetClassColor(unitID)
                    btn.nameText:SetText(shortName)
                    btn.nameText:SetTextColor(1, 1, 1)

                    local remaining = math.max(0, ActiveCarrier.expiration - currentTime)
                    btn.timerText:SetText(string.format("%.0fs", remaining))
                    btn.timerText:SetTextColor(1, 1, 1)

                    btn.bg:SetTexture(r, g, b, 1.0)
                    btn.border:SetTexture(0, 0, 0, 0)
                else
                    btn.nameText:SetText(shortName)
                    btn.nameText:SetTextColor(0.6, 0.6, 0.6)
                    btn.timerText:SetText("")

                    btn.bg:SetTexture(0.08, 0.08, 0.08, 0.6)
                    btn.border:SetTexture(0.15, 0.15, 0.15, 0.3)
                end
            else
                if btn:IsShown() and not InCombatLockdown() then btn:Hide() end
            end
        end
    end
end

----------------------------------------------------
-- 6. EVENT HANDLERS & TIMERS
----------------------------------------------------
InitFrame:SetScript("OnEvent", function(self, event, arg1)
    if event == "ADDON_LOADED" and arg1 == ADDON_NAME then
        NPT_Position = NPT_Position or { point = "CENTER", relativePoint = "CENTER", x = 0, y = 100, audioAlert = true }
        NPT_Enabled = (NPT_Enabled == nil) and true or NPT_Enabled
        NPT_Locked = (NPT_Locked == nil) and false or NPT_Locked
        NPT_MinimapPos = NPT_MinimapPos or 45
        
        AnchorFrame:SetPoint(NPT_Position.point or "CENTER", UIParent, NPT_Position.relativePoint or "CENTER", NPT_Position.x or 0, NPT_Position.y or 100)
        UpdateAnchorVisuals()
        UpdateMinimapButtonPosition()
        
        InitFrame:UnregisterEvent("ADDON_LOADED")
    elseif event == "PLAYER_ENTERING_WORLD" then
        if not NPT_Position.hasSeenWelcome then
            WelcomeDialog:Show()
        end
        InitFrame:UnregisterEvent("PLAYER_ENTERING_WORLD")
    end
end)

local EventFrame = CreateFrame("Frame")
EventFrame:RegisterEvent("UNIT_AURA")
EventFrame:RegisterEvent("ZONE_CHANGED_NEW_AREA")
EventFrame:RegisterEvent("PLAYER_REGEN_ENABLED")
EventFrame:RegisterEvent("RAID_ROSTER_UPDATE")
EventFrame:RegisterEvent("PARTY_MEMBERS_CHANGED")

EventFrame:SetScript("OnEvent", function(self, event, unit)
    NPT_UpdateDisplay()
end)

local TimerFrame = CreateFrame("Frame")
local elapsedTimer = 0
local scanHeartbeatTimer = 0

TimerFrame:SetScript("OnUpdate", function(self, elapsed)
    elapsedTimer = elapsedTimer + elapsed
    scanHeartbeatTimer = scanHeartbeatTimer + elapsed

    -- Heartbeat re-scan every 0.25 seconds to catch new aura applications immediately
    if scanHeartbeatTimer >= 0.25 then
        NPT_UpdateDisplay()
        scanHeartbeatTimer = 0
    end

    if elapsedTimer >= 0.03 then
        local currentTime = GetTime()

        if NPT_TestMode and TestMode_NextSwapTime and currentTime >= TestMode_NextSwapTime then
            NPT_UpdateDisplay()
        elseif ActiveCarrier then
            local remaining = math.max(0, ActiveCarrier.expiration - currentTime)
            local pulseAlpha = 0.2 + (0.8 * ((math.sin(currentTime * 12) + 1) / 2))
            local btn = (GetNumRaidMembers() > 0) and RaidTiles[ActiveCarrier.unit] or PartyTiles[ActiveCarrier.unit]

            if btn and btn:IsShown() then
                btn.timerText:SetText(string.format("%.0fs", remaining))
                btn.border:SetTexture(1, 0, 0, pulseAlpha)
            end

            -- Trigger Audio Warning once at <= 3 seconds
            if remaining <= 3.0 and remaining > 0 then
                if PlayedAudioForExpTime ~= ActiveCarrier.expiration then
                    PlayedAudioForExpTime = ActiveCarrier.expiration
                    if NPT_Position and NPT_Position.audioAlert ~= false then
                        PlaySoundFile(ALERT_SOUND_PATH)
                    end
                end
            end
        end

        elapsedTimer = 0
    end
end)

SLASH_NPT1 = "/npt"
SlashCmdList["NPT"] = ToggleConfigPanel
