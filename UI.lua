local addonName, ns = ...
local AceGUI = LibStub("AceGUI-3.0")

-- Load or initialize SavedVariables
oUF_FailConfig = oUF_FailConfig or {}
local cfg = oUF_FailConfig

-- Default settings
local defaults = {
    units = {
        showtot = true,
        showpet = true,
        showpartypet = false,
        showfocus = true,
        showfocustarget = true,
        ShowPlayerName = true,
        ShowExtraUnitArrows = true,
        showBossFrames = true,
        showMTFrames = false,
    },
    frames = {
        player = {
            enable = true,
            width = 200,
            height = 50,
        },
    },
}

-- Merge defaults with SavedVariables
local function MergeDefaults(defaults, target)
    for k, v in pairs(defaults) do
        if type(v) == "table" then
            target[k] = target[k] or {}
            MergeDefaults(v, target[k])
        else
            if target[k] == nil then
                target[k] = v
            end
        end
    end
end
MergeDefaults(defaults, cfg)

-- Create a styled panel
local function CreateStyledPanel(name, parent, width, height, point, relativeTo, relativePoint, x, y)
    local panel = CreateFrame("Frame", name, parent, "BackdropTemplate")
    panel:SetSize(width, height)
    panel:SetPoint(point, relativeTo, relativePoint, x, y)
    panel:SetBackdrop({
        bgFile = "Interface\\Buttons\\WHITE8X8",
        edgeFile = "Interface\\Buttons\\WHITE8X8",
        edgeSize = 1,
    })
    panel:SetBackdropColor(0.1, 0.1, 0.1, 0.8)
    panel:SetBackdropBorderColor(0, 0, 0, 1)
    return panel
end

-- Create the main configuration window
local function CreateConfigWindow()
    if ns.configFrame then
        return
    end

    -- Create the main frame
    local frame = CreateStyledPanel("oUF_Fail_ConfigFrame", UIParent, 850, 600, "CENTER", UIParent, "CENTER", 0, 0)
    frame:SetMovable(true)
    frame:EnableMouse(true)
    frame:RegisterForDrag("LeftButton")
    frame:SetScript("OnDragStart", frame.StartMoving)
    frame:SetScript("OnDragStop", frame.StopMovingOrSizing)

    -- Title
    local title = frame:CreateFontString(nil, "OVERLAY", "GameFontNormalLarge")
    title:SetPoint("TOP", frame, "TOP", 0, -10)
    title:SetText("|cff1784d1oUF_Fail|r Configuration")

    -- Close button
    local closeButton = CreateFrame("Button", nil, frame, "UIPanelCloseButton")
    closeButton:SetPoint("TOPRIGHT", frame, "TOPRIGHT", -5, -5)
    closeButton:SetScript("OnClick", function()
        frame:Hide()
    end)

    -- Left menu panel
    local leftPanel = CreateStyledPanel("oUF_Fail_LeftPanel", frame, 200, 580, "TOPLEFT", frame, "TOPLEFT", 10, -30)

    -- Right content panel
    local rightPanel = CreateStyledPanel("oUF_Fail_RightPanel", frame, 620, 580, "TOPRIGHT", frame, "TOPRIGHT", -10, -30)

    -- Menu buttons
    local menuButtons = {}
    local selectedButton

    local function CreateMenuButton(parent, text, value)
        -- Create a container frame for the button
        local button = CreateFrame("Button", nil, parent, "BackdropTemplate")
        button:SetSize(180, 30)
        button:SetText(text)
        button:SetNormalFontObject("GameFontNormal")
        button:SetHighlightFontObject("GameFontHighlight")

        -- Add backdrop styling
        button:SetBackdrop({
            bgFile = "Interface\\Buttons\\WHITE8X8",
            edgeFile = "Interface\\Buttons\\WHITE8X8",
            edgeSize = 1,
        })
        button:SetBackdropColor(0.1, 0.1, 0.1, 0.8)
        button:SetBackdropBorderColor(0, 0, 0, 1)

        -- Add text to the button
        local buttonText = button:CreateFontString(nil, "OVERLAY", "GameFontNormal")
        buttonText:SetPoint("CENTER", button, "CENTER")
        buttonText:SetText(text)

        -- Handle button clicks
        button:SetScript("OnClick", function()
            if selectedButton then
                selectedButton:SetBackdropColor(0.1, 0.1, 0.1, 0.8)
            end
            selectedButton = button
            button:SetBackdropColor(0.2, 0.2, 0.2, 1)

            -- Clear right panel
            for _, child in ipairs({rightPanel:GetChildren()}) do
                child:Hide()
            end

            -- Populate right panel based on the selected menu
            if value == "general" then
                local generalGroup = AceGUI:Create("SimpleGroup")
                generalGroup:SetFullWidth(true)
                generalGroup:SetLayout("Flow")

                -- Add units section
                local unitsGroup = AceGUI:Create("InlineGroup")
                unitsGroup:SetTitle("Units")
                unitsGroup:SetFullWidth(true)
                unitsGroup:SetLayout("Flow")

                -- Define the settings for the units section
                local unitSettings = {
                    { key = "showtot", label = "Show Target of Target Frame", description = "Enable or disable the target of target frame." },
                    { key = "showpet", label = "Show Pet Frame", description = "Enable or disable the pet frame." },
                    { key = "showpartypet", label = "Show Party Pet Frame", description = "Enable or disable the party pet frame." },
                    { key = "showfocus", label = "Show Focus Frame", description = "Enable or disable the focus frame." },
                    { key = "showfocustarget", label = "Show Focus Target Frame", description = "Enable or disable the focus target frame." },
                    { key = "ShowPlayerName", label = "Show Player's Name and Level", description = "Enable or disable the display of the player's name and level." },
                    { key = "ShowExtraUnitArrows", label = "Show Extra Unit Arrows", description = "Enable or disable power arrows on additional frames (target, focus, focus target)." },
                    { key = "showBossFrames", label = "Show Boss Frame", description = "Enable or disable the boss frame." },
                    { key = "showMTFrames", label = "Show Main Tank Frame", description = "Enable or disable the main tank frame (not yet working)." },
                }

                -- Create checkboxes for each setting
                for _, setting in ipairs(unitSettings) do
                    local checkBox = AceGUI:Create("CheckBox")
                    checkBox:SetLabel(setting.label)
                    checkBox:SetDescription(setting.description)
                    checkBox:SetValue(cfg.units[setting.key])
                    checkBox:SetCallback("OnValueChanged", function(_, _, value)
                        cfg.units[setting.key] = value -- Update SavedVariables
                        print(setting.label .. (value and " enabled." or " disabled."))
                    end)
                    unitsGroup:AddChild(checkBox)
                end

                generalGroup:AddChild(unitsGroup)
                generalGroup.frame:SetParent(rightPanel)
                generalGroup.frame:SetPoint("TOPLEFT", rightPanel, "TOPLEFT", 10, -10)
                generalGroup.frame:SetPoint("BOTTOMRIGHT", rightPanel, "BOTTOMRIGHT", -10, 10)
                generalGroup.frame:Show()
            elseif value == "guide" then
                local guideGroup = AceGUI:Create("SimpleGroup")
                guideGroup:SetFullWidth(true)
                guideGroup:SetLayout("Flow")

                -- Add movable button
                local movableButton = AceGUI:Create("Button")
                movableButton:SetFullWidth(true)
                movableButton:SetHeight(30)
                
                -- Local function to update button text
                local function updateButtonText()
                    if _LOCK then
                        movableButton:SetText("Disable Frame Movement")
                    else
                        movableButton:SetText("Enable Frame Movement")
                    end
                end
                
                -- Set initial text
                updateButtonText()
                
                movableButton:SetCallback("OnClick", function()
                    -- Use the same function as the old /omf command
                    local success = ns.ToggleMovable()
                    
                    -- Update button text
                    updateButtonText()
                    
                    -- Print status message
                    if success ~= nil then
                        print("Frame Movement: " .. (_LOCK and "Enabled" or "Disabled"))
                    end
                end)

                guideGroup:AddChild(movableButton)
                guideGroup.frame:SetParent(rightPanel)
                guideGroup.frame:SetPoint("TOPLEFT", rightPanel, "TOPLEFT", 10, -10)
                guideGroup.frame:SetPoint("BOTTOMRIGHT", rightPanel, "BOTTOMRIGHT", -10, 10)
                guideGroup.frame:Show()
            end
        end)

        return button
    end

    -- Add menu buttons
    local generalButton = CreateMenuButton(leftPanel, "General", "general")
    generalButton:SetPoint("TOP", leftPanel, "TOP", 0, -10)

    local guideButton = CreateMenuButton(leftPanel, "Guide Frame", "guide")
    guideButton:SetPoint("TOP", generalButton, "BOTTOM", 0, -10)

    -- Store the frame reference
    ns.configFrame = frame

    -- Hide the frame by default
    frame:Hide()
end

-- Initialize settings
local function InitializeSettings()
    -- Create slash command
    SLASH_OUFFAIL1 = "/of"
    SlashCmdList["OUFFAIL"] = function()
        if not ns.configFrame then
            CreateConfigWindow()
        end

        if ns.configFrame:IsShown() then
            ns.configFrame:Hide()
        else
            ns.configFrame:Show()
        end
    end
end

-- Event handling
local eventFrame = CreateFrame("Frame")
eventFrame:RegisterEvent("PLAYER_LOGIN")
eventFrame:SetScript("OnEvent", InitializeSettings)