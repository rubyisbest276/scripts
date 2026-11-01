-- [[ Ruby UI Library - Full Complete Framework ]]
-- Architecture: Window -> Tab -> Groupbox (Left/Right) -> Controls
-- Supported: Toggle, Slider, Dropdown, Input, Button, Label, ColorPicker, KeyPicker
-- Chaining: Toggle:AddColorPicker():AddKeyPicker(), Label:AddKeyPicker()
-- Systems: Keybind Manager, SaveManager (Config), ThemeManager, Toast Notifications, Unload Hooks

local UserInputService = game:GetService("UserInputService")
local TweenService = game:GetService("TweenService")
local CoreGui = game:GetService("CoreGui")
local Players = game:GetService("Players")
local HttpService = game:GetService("HttpService")

local LocalPlayer = Players.LocalPlayer
local Mouse = LocalPlayer and LocalPlayer:GetMouse()

-- Safe parent container resolver
local function GetSafeGuiParent()
    local success, parent = pcall(function()
        if gethui then return gethui() end
        return CoreGui
    end)
    if success and parent then return parent end
    return LocalPlayer:WaitForChild("PlayerGui")
end

-- =========================================================================
-- GLOBAL STATE & TABLES
-- =========================================================================
local Options = {}
local Toggles = {}

-- 전역 노출 (스크립트 내부 rawget(_G, "Options") 호환)
_G.Options = Options
_G.Toggles = Toggles
if getgenv then
    getgenv().Options = Options
    getgenv().Toggles = Toggles
end

local Library = {
    Name = "RubyUI",
    Open = true,
    Accent = Color3.fromRGB(235, 60, 80),
    Background = Color3.fromRGB(20, 20, 24),
    Sidebar = Color3.fromRGB(24, 24, 28),
    SectionBg = Color3.fromRGB(28, 28, 34),
    Border = Color3.fromRGB(45, 45, 55),
    TextColor = Color3.fromRGB(240, 240, 240),
    SubTextColor = Color3.fromRGB(150, 150, 160),
    Font = Enum.Font.GothamMedium,
    FontBold = Enum.Font.GothamBold,
    UnloadCallbacks = {},
    Connections = {},
    Keybinds = {},
    ScreenGui = nil,
    MainWindow = nil,
    NotificationContainer = nil,
    KeybindMenu = nil,
}

local SaveManager = {
    Folder = "RubyLibraryConfigs",
    IgnoreIndexes = { "MenuKeybind" },
    Library = Library,
    AutoloadFile = "autoload.txt"
}

local ThemeManager = {
    Folder = "RubyLibraryThemes",
    Library = Library,
    BuiltInThemes = {
        ["Crimson Red"] = Color3.fromRGB(235, 60, 80),
        ["Amethyst Violet"] = Color3.fromRGB(140, 75, 255),
        ["Electric Blue"] = Color3.fromRGB(45, 125, 255),
        ["Emerald Green"] = Color3.fromRGB(45, 200, 115),
        ["Cyber Gold"] = Color3.fromRGB(255, 185, 45),
        ["Pure White"] = Color3.fromRGB(230, 230, 230),
    }
}

-- =========================================================================
-- UTILITY FUNCTIONS
-- =========================================================================
local function FastTween(object, style, time, properties)
    local tweenInfo = TweenInfo.new(time or 0.15, style or Enum.EasingStyle.Quad, Enum.EasingDirection.Out)
    local tween = TweenService:Create(object, tweenInfo, properties)
    tween:Play()
    return tween
end

local function Round(num, decimals)
    if not decimals or decimals <= 0 then
        return math.floor(num + 0.5)
    end
    local mult = 10 ^ decimals
    return math.floor(num * mult + 0.5) / mult
end

local function SafeMakeFolder(folder)
    if makefolder and not (isfolder and isfolder(folder)) then
        pcall(makefolder, folder)
    end
end

-- =========================================================================
-- KEYBIND SYSTEM
-- =========================================================================
local function ConvertKeyCodeToString(keyCode)
    if not keyCode then return "None" end
    if typeof(keyCode) == "string" then return keyCode end
    local name = keyCode.Name
    if name:find("Keypad") then
        return name
    elseif name == "RightShift" then
        return "RShift"
    elseif name == "LeftShift" then
        return "LShift"
    elseif name == "RightControl" then
        return "RCtrl"
    elseif name == "LeftControl" then
        return "LCtrl"
    end
    return name
end

local function ParseKeyInput(input)
    if input.UserInputType == Enum.UserInputType.Keyboard then
        return input.KeyCode
    elseif input.UserInputType == Enum.UserInputType.MouseButton1 then
        return Enum.UserInputType.MouseButton1
    elseif input.UserInputType == Enum.UserInputType.MouseButton2 then
        return Enum.UserInputType.MouseButton2
    elseif input.UserInputType == Enum.UserInputType.MouseButton3 then
        return Enum.UserInputType.MouseButton3
    end
    return nil
end

local function KeyMatches(keyA, keyB)
    if not keyA or not keyB then return false end
    if typeof(keyA) == "string" then
        if keyA == "MB1" and keyB == Enum.UserInputType.MouseButton1 then return true end
        if keyA == "MB2" and keyB == Enum.UserInputType.MouseButton2 then return true end
        if keyA == "MB3" and keyB == Enum.UserInputType.MouseButton3 then return true end
        return keyA:lower() == (typeof(keyB) == "EnumItem" and keyB.Name:lower() or tostring(keyB):lower())
    end
    if typeof(keyA) == "EnumItem" and typeof(keyB) == "EnumItem" then
        return keyA == keyB
    end
    return false
end

-- Global Input Listeners (NO RenderStepped / Heartbeat used)
local inputBeganConn = UserInputService.InputBegan:Connect(function(input, gameProcessed)
    -- Global Menu Keybind Check
    if not gameProcessed and Options.MenuKeybind then
        local menuKey = Options.MenuKeybind.Value
        if KeyMatches(menuKey, input.KeyCode) or KeyMatches(menuKey, input.UserInputType) then
            Library:Toggle()
            return
        end
    end

    if gameProcessed then return end

    -- Check Registered KeyPickers
    for _, kp in ipairs(Library.Keybinds) do
        local targetKey = kp.Value
        if KeyMatches(targetKey, input.KeyCode) or KeyMatches(targetKey, input.UserInputType) then
            if kp.Mode == "Toggle" then
                kp.Active = not kp.Active
                if kp.SyncToggleState and kp.ParentToggle then
                    kp.ParentToggle:SetValue(kp.Active)
                end
                if kp.Callback then
                    task.spawn(kp.Callback, kp.Active)
                end
            elseif kp.Mode == "Hold" then
                kp.Active = true
                if kp.SyncToggleState and kp.ParentToggle then
                    kp.ParentToggle:SetValue(true)
                end
                if kp.Callback then
                    task.spawn(kp.Callback, true)
                end
            end
        end
    end
end)
table.insert(Library.Connections, inputBeganConn)

local inputEndedConn = UserInputService.InputEnded:Connect(function(input, _)
    for _, kp in ipairs(Library.Keybinds) do
        local targetKey = kp.Value
        if KeyMatches(targetKey, input.KeyCode) or KeyMatches(targetKey, input.UserInputType) then
            if kp.Mode == "Hold" and kp.Active then
                kp.Active = false
                if kp.SyncToggleState and kp.ParentToggle then
                    kp.ParentToggle:SetValue(false)
                end
                if kp.Callback then
                    task.spawn(kp.Callback, false)
                end
            end
        end
    end
end)
table.insert(Library.Connections, inputEndedConn)

-- =========================================================================
-- UNLOAD SYSTEM
-- =========================================================================
function Library:OnUnload(fn)
    table.insert(self.UnloadCallbacks, fn)
end

function Library:Unload()
    for _, conn in ipairs(self.Connections) do
        pcall(function() conn:Disconnect() end)
    end
    self.Connections = {}

    for _, cb in ipairs(self.UnloadCallbacks) do
        task.spawn(pcall, cb)
    end
    self.UnloadCallbacks = {}

    if self.ScreenGui then
        self.ScreenGui:Destroy()
        self.ScreenGui = nil
    end

    _G.Options = nil
    _G.Toggles = nil
    if getgenv then
        getgenv().Options = nil
        getgenv().Toggles = nil
    end
end

-- =========================================================================
-- NOTIFICATION (TOAST) SYSTEM
-- =========================================================================
function Library:Notify(message, duration, position)
    duration = duration or 3
    position = position or "Right"

    if not self.NotificationContainer then return end

    local notifFrame = Instance.new("Frame")
    notifFrame.Name = "Toast"
    notifFrame.Size = UDim2.new(1, 0, 0, 36)
    notifFrame.BackgroundColor3 = self.SectionBg
    notifFrame.BorderSizePixel = 0
    notifFrame.BackgroundTransparency = 1
    notifFrame.Parent = self.NotificationContainer

    local corner = Instance.new("UICorner")
    corner.CornerRadius = UDim.new(0, 6)
    corner.Parent = notifFrame

    local stroke = Instance.new("UIStroke")
    stroke.Color = self.Border
    stroke.Transparency = 1
    stroke.Parent = notifFrame

    local accentBar = Instance.new("Frame")
    accentBar.Size = UDim2.new(0, 3, 1, 0)
    accentBar.BackgroundColor3 = self.Accent
    accentBar.BorderSizePixel = 0
    accentBar.BackgroundTransparency = 1
    accentBar.Parent = notifFrame

    local barCorner = Instance.new("UICorner")
    barCorner.CornerRadius = UDim.new(0, 3)
    barCorner.Parent = accentBar

    local textLabel = Instance.new("TextLabel")
    textLabel.Size = UDim2.new(1, -20, 1, 0)
    textLabel.Position = UDim2.new(0, 12, 0, 0)
    textLabel.BackgroundTransparency = 1
    textLabel.Font = self.Font
    textLabel.Text = tostring(message)
    textLabel.TextColor3 = self.TextColor
    textLabel.TextSize = 13
    textLabel.TextXAlignment = Enum.TextXAlignment.Left
    textLabel.TextTransparency = 1
    textLabel.Parent = notifFrame

    -- Fade in
    FastTween(notifFrame, Enum.EasingStyle.Quad, 0.25, { BackgroundTransparency = 0 })
    FastTween(stroke, Enum.EasingStyle.Quad, 0.25, { Transparency = 0 })
    FastTween(accentBar, Enum.EasingStyle.Quad, 0.25, { BackgroundTransparency = 0 })
    FastTween(textLabel, Enum.EasingStyle.Quad, 0.25, { TextTransparency = 0 })

    task.delay(duration, function()
        if not notifFrame.Parent then return end
        FastTween(notifFrame, Enum.EasingStyle.Quad, 0.25, { BackgroundTransparency = 1 })
        FastTween(stroke, Enum.EasingStyle.Quad, 0.25, { Transparency = 1 })
        FastTween(accentBar, Enum.EasingStyle.Quad, 0.25, { BackgroundTransparency = 1 })
        FastTween(textLabel, Enum.EasingStyle.Quad, 0.25, { TextTransparency = 1 })
        task.wait(0.26)
        notifFrame:Destroy()
    end)
end

-- =========================================================================
-- WINDOW CREATION
-- =========================================================================
function Library:CreateWindow(config)
    config = config or {}
    local TitleText = config.Title or "Ruby Framework"
    local SubTitleText = config.SubTitle or "External Hybrid"
    local FooterText = config.Footer or "v1.0.0 | Private Build"
    local Center = config.Center ~= false
    local AutoShow = config.AutoShow ~= false

    local ScreenGui = Instance.new("ScreenGui")
    ScreenGui.Name = "RubyUILibrary"
    ScreenGui.ResetOnSpawn = false
    ScreenGui.ZIndexBehavior = Enum.ZIndexBehavior.Sibling
    ScreenGui.DisplayOrder = 1000
    ScreenGui.Parent = GetSafeGuiParent()
    self.ScreenGui = ScreenGui

    -- Toast Container
    local notifContainer = Instance.new("Frame")
    notifContainer.Name = "Notifications"
    notifContainer.Size = UDim2.new(0, 260, 1, -40)
    notifContainer.Position = UDim2.new(1, -280, 0, 20)
    notifContainer.BackgroundTransparency = 1
    notifContainer.Parent = ScreenGui

    local notifLayout = Instance.new("UIListLayout")
    notifLayout.SortOrder = Enum.SortOrder.LayoutOrder
    notifLayout.VerticalAlignment = Enum.VerticalAlignment.Bottom
    notifLayout.Padding = UDim.new(0, 8)
    notifLayout.Parent = notifContainer
    self.NotificationContainer = notifContainer

    -- Main Container Window
    local MainWindow = Instance.new("Frame")
    MainWindow.Name = "MainWindow"
    MainWindow.Size = UDim2.new(0, 680, 0, 480)
    if Center then
        MainWindow.Position = UDim2.new(0.5, -340, 0.5, -240)
    else
        MainWindow.Position = UDim2.new(0, 100, 0, 100)
    end
    MainWindow.BackgroundColor3 = self.Background
    MainWindow.BorderSizePixel = 0
    MainWindow.Visible = AutoShow
    MainWindow.ClipsDescendants = false
    MainWindow.Parent = ScreenGui
    self.MainWindow = MainWindow

    local mainCorner = Instance.new("UICorner")
    mainCorner.CornerRadius = UDim.new(0, 8)
    mainCorner.Parent = MainWindow

    local mainStroke = Instance.new("UIStroke")
    mainStroke.Color = self.Border
    mainStroke.Thickness = 1.2
    mainStroke.Parent = MainWindow

    -- Dragging Mechanics
    local dragging, dragStart, startPos
    local titleBar = Instance.new("Frame")
    titleBar.Name = "TitleBar"
    titleBar.Size = UDim2.new(1, 0, 0, 42)
    titleBar.BackgroundTransparency = 1
    titleBar.Parent = MainWindow

    titleBar.InputBegan:Connect(function(input)
        if input.UserInputType == Enum.UserInputType.MouseButton1 then
            dragging = true
            dragStart = input.Position
            startPos = MainWindow.Position
        end
    end)

    local dragEndConn = UserInputService.InputEnded:Connect(function(input)
        if input.UserInputType == Enum.UserInputType.MouseButton1 then
            dragging = false
        end
    end)
    table.insert(self.Connections, dragEndConn)

    local dragMoveConn = UserInputService.InputChanged:Connect(function(input)
        if dragging and input.UserInputType == Enum.UserInputType.MouseMovement then
            local delta = input.Position - dragStart
            MainWindow.Position = UDim2.new(
                startPos.X.Scale,
                startPos.X.Offset + delta.X,
                startPos.Y.Scale,
                startPos.Y.Offset + delta.Y
            )
        end
    end)
    table.insert(self.Connections, dragMoveConn)

    -- Window Header Elements
    local titleLabel = Instance.new("TextLabel")
    titleLabel.Name = "Title"
    titleLabel.Size = UDim2.new(0, 200, 1, 0)
    titleLabel.Position = UDim2.new(0, 16, 0, 0)
    titleLabel.BackgroundTransparency = 1
    titleLabel.Font = self.FontBold
    titleLabel.Text = TitleText
    titleLabel.TextColor3 = self.TextColor
    titleLabel.TextSize = 15
    titleLabel.TextXAlignment = Enum.TextXAlignment.Left
    titleLabel.Parent = titleBar

    local subTitleLabel = Instance.new("TextLabel")
    subTitleLabel.Name = "SubTitle"
    subTitleLabel.Size = UDim2.new(0, 200, 1, 0)
    subTitleLabel.Position = UDim2.new(0, 16 + titleLabel.TextBounds.X + 8, 0, 0)
    subTitleLabel.BackgroundTransparency = 1
    subTitleLabel.Font = self.Font
    subTitleLabel.Text = SubTitleText
    subTitleLabel.TextColor3 = self.SubTextColor
    subTitleLabel.TextSize = 13
    subTitleLabel.TextXAlignment = Enum.TextXAlignment.Left
    subTitleLabel.Parent = titleBar

    titleLabel:GetPropertyChangedSignal("TextBounds"):Connect(function()
        subTitleLabel.Position = UDim2.new(0, 16 + titleLabel.TextBounds.X + 8, 0, 0)
    end)

    -- Divider below TitleBar
    local titleDivider = Instance.new("Frame")
    titleDivider.Size = UDim2.new(1, 0, 0, 1)
    titleDivider.Position = UDim2.new(0, 0, 0, 42)
    titleDivider.BackgroundColor3 = self.Border
    titleDivider.BorderSizePixel = 0
    titleDivider.Parent = MainWindow

    -- Sidebar Container (Tab Buttons)
    local sidebar = Instance.new("Frame")
    sidebar.Name = "Sidebar"
    sidebar.Size = UDim2.new(0, 140, 1, -66)
    sidebar.Position = UDim2.new(0, 0, 0, 43)
    sidebar.BackgroundColor3 = self.Sidebar
    sidebar.BorderSizePixel = 0
    sidebar.Parent = MainWindow

    local sideCorner = Instance.new("UICorner")
    sideCorner.CornerRadius = UDim.new(0, 8)
    sideCorner.Parent = sidebar

    -- Straighten right side corners of the sidebar
    local sideFiller = Instance.new("Frame")
    sideFiller.Size = UDim2.new(0, 8, 1, 0)
    sideFiller.Position = UDim2.new(1, -8, 0, 0)
    sideFiller.BackgroundColor3 = self.Sidebar
    sideFiller.BorderSizePixel = 0
    sideFiller.Parent = sidebar

    local sidebarLayout = Instance.new("UIListLayout")
    sidebarLayout.SortOrder = Enum.SortOrder.LayoutOrder
    sidebarLayout.Padding = UDim.new(0, 4)
    sidebarLayout.Parent = sidebar

    local sidebarPadding = Instance.new("UIPadding")
    sidebarPadding.PaddingTop = UDim.new(0, 8)
    sidebarPadding.PaddingLeft = UDim.new(0, 6)
    sidebarPadding.PaddingRight = UDim.new(0, 6)
    sidebarPadding.Parent = sidebar

    -- Sidebar Divider
    local sidebarDivider = Instance.new("Frame")
    sidebarDivider.Size = UDim2.new(0, 1, 1, -66)
    sidebarDivider.Position = UDim2.new(0, 140, 0, 43)
    sidebarDivider.BackgroundColor3 = self.Border
    sidebarDivider.BorderSizePixel = 0
    sidebarDivider.Parent = MainWindow

    -- Tab Content Container
    local tabContainer = Instance.new("Frame")
    tabContainer.Name = "TabContainer"
    tabContainer.Size = UDim2.new(1, -141, 1, -66)
    tabContainer.Position = UDim2.new(0, 141, 0, 43)
    tabContainer.BackgroundTransparency = 1
    tabContainer.ClipsDescendants = true
    tabContainer.Parent = MainWindow

    -- Footer
    local footerDivider = Instance.new("Frame")
    footerDivider.Size = UDim2.new(1, 0, 0, 1)
    footerDivider.Position = UDim2.new(0, 0, 1, -24)
    footerDivider.BackgroundColor3 = self.Border
    footerDivider.BorderSizePixel = 0
    footerDivider.Parent = MainWindow

    local footerLabel = Instance.new("TextLabel")
    footerLabel.Name = "Footer"
    footerLabel.Size = UDim2.new(1, -24, 0, 23)
    footerLabel.Position = UDim2.new(0, 12, 1, -23)
    footerLabel.BackgroundTransparency = 1
    footerLabel.Font = self.Font
    footerLabel.Text = FooterText
    footerLabel.TextColor3 = self.SubTextColor
    footerLabel.TextSize = 11
    footerLabel.TextXAlignment = Enum.TextXAlignment.Left
    footerLabel.Parent = MainWindow

    -- Register MenuKeybind into Options
    Options.MenuKeybind = {
        Value = Enum.KeyCode.RightShift,
        Type = "KeyPicker",
        Mode = "Toggle",
        SetValue = function(selfOpt, val)
            selfOpt.Value = val
        end
    }

    local WindowObj = {
        Tabs = {},
        CurrentTab = nil,
    }

    function Library:Toggle()
        self.Open = not self.Open
        MainWindow.Visible = self.Open
    end

    -- =====================================================================
    -- TAB BUILDER
    -- =====================================================================
    function WindowObj:AddTab(tabName, iconId)
        local Tab = {
            Name = tabName,
            LeftGroupboxes = {},
            RightGroupboxes = {},
        }

        local tabButton = Instance.new("TextButton")
        tabButton.Name = "TabBtn_" .. tabName
        tabButton.Size = UDim2.new(1, 0, 0, 32)
        tabButton.BackgroundColor3 = Library.SectionBg
        tabButton.BackgroundTransparency = 1
        tabButton.AutoButtonColor = false
        tabButton.Text = ""
        tabButton.Parent = sidebar

        local btnCorner = Instance.new("UICorner")
        btnCorner.CornerRadius = UDim.new(0, 6)
        btnCorner.Parent = tabButton

        local iconImg = nil
        if iconId and iconId ~= "" then
            iconImg = Instance.new("ImageLabel")
            iconImg.Size = UDim2.new(0, 16, 0, 16)
            iconImg.Position = UDim2.new(0, 8, 0.5, -8)
            iconImg.BackgroundTransparency = 1
            iconImg.Image = tostring(iconId)
            iconImg.ImageColor3 = Library.SubTextColor
            iconImg.Parent = tabButton
        end

        local tabTextLabel = Instance.new("TextLabel")
        tabTextLabel.Size = UDim2.new(1, iconImg and -32 or -16, 1, 0)
        tabTextLabel.Position = UDim2.new(0, iconImg and 30 or 10, 0, 0)
        tabTextLabel.BackgroundTransparency = 1
        tabTextLabel.Font = Library.Font
        tabTextLabel.Text = tabName
        tabTextLabel.TextColor3 = Library.SubTextColor
        tabTextLabel.TextSize = 13
        tabTextLabel.TextXAlignment = Enum.TextXAlignment.Left
        tabTextLabel.Parent = tabButton

        -- Tab View Frame (Scrollable 2-Column Container)
        local tabScroll = Instance.new("ScrollingFrame")
        tabScroll.Name = "TabView_" .. tabName
        tabScroll.Size = UDim2.new(1, 0, 1, 0)
        tabScroll.BackgroundTransparency = 1
        tabScroll.BorderSizePixel = 0
        tabScroll.ScrollBarThickness = 3
        tabScroll.ScrollBarImageColor3 = Library.Border
        tabScroll.Visible = false
        tabScroll.CanvasSize = UDim2.new(0, 0, 0, 0)
        tabScroll.AutomaticCanvasSize = Enum.AutomaticSize.Y
        tabScroll.Parent = tabContainer

        local pad = Instance.new("UIPadding")
        pad.PaddingTop = UDim.new(0, 10)
        pad.PaddingBottom = UDim.new(0, 10)
        pad.PaddingLeft = UDim.new(0, 10)
        pad.PaddingRight = UDim.new(0, 10)
        pad.Parent = tabScroll

        -- Left Column
        local leftColumn = Instance.new("Frame")
        leftColumn.Name = "LeftColumn"
        leftColumn.Size = UDim2.new(0.5, -6, 0, 0)
        leftColumn.Position = UDim2.new(0, 0, 0, 0)
        leftColumn.BackgroundTransparency = 1
        leftColumn.AutomaticSize = Enum.AutomaticSize.Y
        leftColumn.Parent = tabScroll

        local leftLayout = Instance.new("UIListLayout")
        leftLayout.SortOrder = Enum.SortOrder.LayoutOrder
        leftLayout.Padding = UDim.new(0, 10)
        leftLayout.Parent = leftColumn

        -- Right Column
        local rightColumn = Instance.new("Frame")
        rightColumn.Name = "RightColumn"
        rightColumn.Size = UDim2.new(0.5, -6, 0, 0)
        rightColumn.Position = UDim2.new(0.5, 6, 0, 0)
        rightColumn.BackgroundTransparency = 1
        rightColumn.AutomaticSize = Enum.AutomaticSize.Y
        rightColumn.Parent = tabScroll

        local rightLayout = Instance.new("UIListLayout")
        rightLayout.SortOrder = Enum.SortOrder.LayoutOrder
        rightLayout.Padding = UDim.new(0, 10)
        rightLayout.Parent = rightColumn

        local function ShowTab()
            for _, t in ipairs(WindowObj.Tabs) do
                t.View.Visible = false
                FastTween(t.Button, Enum.EasingStyle.Quad, 0.15, { BackgroundTransparency = 1 })
                FastTween(t.Label, Enum.EasingStyle.Quad, 0.15, { TextColor3 = Library.SubTextColor })
                if t.Icon then
                    FastTween(t.Icon, Enum.EasingStyle.Quad, 0.15, { ImageColor3 = Library.SubTextColor })
                end
            end
            tabScroll.Visible = true
            FastTween(tabButton, Enum.EasingStyle.Quad, 0.15, { BackgroundTransparency = 0 })
            FastTween(tabTextLabel, Enum.EasingStyle.Quad, 0.15, { TextColor3 = Library.TextColor })
            if iconImg then
                FastTween(iconImg, Enum.EasingStyle.Quad, 0.15, { ImageColor3 = Library.Accent })
            end
            WindowObj.CurrentTab = Tab
        end

        tabButton.MouseButton1Click:Connect(ShowTab)

        Tab.View = tabScroll
        Tab.Button = tabButton
        Tab.Label = tabTextLabel
        Tab.Icon = iconImg
        table.insert(WindowObj.Tabs, Tab)

        -- First tab auto-select
        if #WindowObj.Tabs == 1 then
            ShowTab()
        end

        -- =================================================================
        -- GROUPBOX BUILDER
        -- =================================================================
        local function CreateGroupbox(parentCol, groupTitle)
            local gbFrame = Instance.new("Frame")
            gbFrame.Name = "Groupbox_" .. groupTitle
            gbFrame.Size = UDim2.new(1, 0, 0, 0)
            gbFrame.BackgroundColor3 = Library.SectionBg
            gbFrame.BorderSizePixel = 0
            gbFrame.AutomaticSize = Enum.AutomaticSize.Y
            gbFrame.Parent = parentCol

            local gbCorner = Instance.new("UICorner")
            gbCorner.CornerRadius = UDim.new(0, 6)
            gbCorner.Parent = gbFrame

            local gbStroke = Instance.new("UIStroke")
            gbStroke.Color = Library.Border
            gbStroke.Thickness = 1
            gbStroke.Parent = gbFrame

            local gbHeader = Instance.new("Frame")
            gbHeader.Size = UDim2.new(1, 0, 0, 26)
            gbHeader.BackgroundTransparency = 1
            gbHeader.Parent = gbFrame

            local gbTitleLabel = Instance.new("TextLabel")
            gbTitleLabel.Size = UDim2.new(1, -20, 1, 0)
            gbTitleLabel.Position = UDim2.new(0, 10, 0, 0)
            gbTitleLabel.BackgroundTransparency = 1
            gbTitleLabel.Font = Library.FontBold
            gbTitleLabel.Text = groupTitle
            gbTitleLabel.TextColor3 = Library.TextColor
            gbTitleLabel.TextSize = 12
            gbTitleLabel.TextXAlignment = Enum.TextXAlignment.Left
            gbTitleLabel.Parent = gbHeader

            local gbDivider = Instance.new("Frame")
            gbDivider.Size = UDim2.new(1, 0, 0, 1)
            gbDivider.Position = UDim2.new(0, 0, 0, 26)
            gbDivider.BackgroundColor3 = Library.Border
            gbDivider.BorderSizePixel = 0
            gbDivider.Parent = gbFrame

            local gbContent = Instance.new("Frame")
            gbContent.Name = "Content"
            gbContent.Size = UDim2.new(1, 0, 0, 0)
            gbContent.Position = UDim2.new(0, 0, 0, 27)
            gbContent.BackgroundTransparency = 1
            gbContent.AutomaticSize = Enum.AutomaticSize.Y
            gbContent.Parent = gbFrame

            local contentLayout = Instance.new("UIListLayout")
            contentLayout.SortOrder = Enum.SortOrder.LayoutOrder
            contentLayout.Padding = UDim.new(0, 6)
            contentLayout.Parent = gbContent

            local contentPad = Instance.new("UIPadding")
            contentPad.PaddingTop = UDim.new(0, 8)
            contentPad.PaddingBottom = UDim.new(0, 8)
            contentPad.PaddingLeft = UDim.new(0, 10)
            contentPad.PaddingRight = UDim.new(0, 10)
            contentPad.Parent = gbContent

            local Groupbox = {
                Frame = gbFrame,
                Content = gbContent
            }

            -- =============================================================
            -- CONTROLS IMPLEMENTATION
            -- =============================================================

            -- 1. TOGGLE (with Chaining: AddColorPicker, AddKeyPicker)
            function Groupbox:AddToggle(id, cfg)
                cfg = cfg or {}
                local text = cfg.Text or id or "Toggle"
                local state = cfg.Default == true
                local callback = cfg.Callback or function() end

                local row = Instance.new("Frame")
                row.Name = "Toggle_" .. tostring(id)
                row.Size = UDim2.new(1, 0, 0, 22)
                row.BackgroundTransparency = 1
                row.Parent = gbContent

                local checkBox = Instance.new("TextButton")
                checkBox.Size = UDim2.new(0, 16, 0, 16)
                checkBox.Position = UDim2.new(0, 0, 0.5, -8)
                checkBox.BackgroundColor3 = state and Library.Accent or Library.Background
                checkBox.BorderSizePixel = 0
                checkBox.Text = ""
                checkBox.AutoButtonColor = false
                checkBox.Parent = row

                local cbCorner = Instance.new("UICorner")
                cbCorner.CornerRadius = UDim.new(0, 4)
                cbCorner.Parent = checkBox

                local cbStroke = Instance.new("UIStroke")
                cbStroke.Color = Library.Border
                cbStroke.Parent = checkBox

                local titleBtn = Instance.new("TextButton")
                titleBtn.Size = UDim2.new(1, -24, 1, 0)
                titleBtn.Position = UDim2.new(0, 24, 0, 0)
                titleBtn.BackgroundTransparency = 1
                titleBtn.Font = Library.Font
                titleBtn.Text = text
                titleBtn.TextColor3 = state and Library.TextColor or Library.SubTextColor
                titleBtn.TextSize = 12
                titleBtn.TextXAlignment = Enum.TextXAlignment.Left
                titleBtn.Parent = row

                -- Container on the right for chained items (ColorPickers / KeyPickers)
                local addonsContainer = Instance.new("Frame")
                addonsContainer.Name = "Addons"
                addonsContainer.Size = UDim2.new(0, 0, 1, 0)
                addonsContainer.Position = UDim2.new(1, 0, 0, 0)
                addonsContainer.AnchorPoint = Vector2.new(1, 0)
                addonsContainer.BackgroundTransparency = 1
                addonsContainer.AutomaticSize = Enum.AutomaticSize.X
                addonsContainer.Parent = row

                local addonsLayout = Instance.new("UIListLayout")
                addonsLayout.FillDirection = Enum.FillDirection.Horizontal
                addonsLayout.HorizontalAlignment = Enum.HorizontalAlignment.Right
                addonsLayout.VerticalAlignment = Enum.VerticalAlignment.Center
                addonsLayout.SortOrder = Enum.SortOrder.LayoutOrder
                addonsLayout.Padding = UDim.new(0, 4)
                addonsLayout.Parent = addonsContainer

                local ToggleObj = {
                    Value = state,
                    Type = "Toggle",
                    RawCallback = callback,
                    SubComponents = {}
                }

                function ToggleObj:SetValue(newVal)
                    self.Value = newVal == true
                    FastTween(checkBox, Enum.EasingStyle.Quad, 0.12, {
                        BackgroundColor3 = self.Value and Library.Accent or Library.Background
                    })
                    FastTween(titleBtn, Enum.EasingStyle.Quad, 0.12, {
                        TextColor3 = self.Value and Library.TextColor or Library.SubTextColor
                    })
                    task.spawn(callback, self.Value)
                end

                local function ToggleClicked()
                    ToggleObj:SetValue(not ToggleObj.Value)
                end

                checkBox.MouseButton1Click:Connect(ToggleClicked)
                titleBtn.MouseButton1Click:Connect(ToggleClicked)

                if id then
                    Toggles[id] = ToggleObj
                    Options[id] = ToggleObj
                end

                -- Chaining Wrapper
                local ChainWrapper = {
                    Toggle = ToggleObj
                }

                -- Chained ColorPicker
                function ChainWrapper:AddColorPicker(cpId, cpCfg)
                    cpCfg = cpCfg or {}
                    local cpDef = cpCfg.Default or Color3.fromRGB(255, 255, 255)
                    local cpTitle = cpCfg.Title or "Color"
                    local cpCb = cpCfg.Callback or function() end

                    local cpBtn = Instance.new("TextButton")
                    cpBtn.Name = "ColorBtn_" .. tostring(cpId)
                    cpBtn.Size = UDim2.new(0, 22, 0, 14)
                    cpBtn.BackgroundColor3 = cpDef
                    cpBtn.BorderSizePixel = 0
                    cpBtn.Text = ""
                    cpBtn.AutoButtonColor = false
                    cpBtn.Parent = addonsContainer

                    local cCorner = Instance.new("UICorner")
                    cCorner.CornerRadius = UDim.new(0, 3)
                    cCorner.Parent = cpBtn

                    local cStroke = Instance.new("UIStroke")
                    cStroke.Color = Library.Border
                    cStroke.Parent = cpBtn

                    -- Popup Window for HSV selection
                    local cpPickerFrame = Instance.new("Frame")
                    cpPickerFrame.Name = "ColorPickerPopup"
                    cpPickerFrame.Size = UDim2.new(0, 180, 0, 160)
                    cpPickerFrame.Position = UDim2.new(1, 10, 0, 0)
                    cpPickerFrame.BackgroundColor3 = Library.SectionBg
                    cpPickerFrame.BorderSizePixel = 0
                    cpPickerFrame.Visible = false
                    cpPickerFrame.ZIndex = 50
                    cpPickerFrame.Parent = cpBtn

                    local pCorner = Instance.new("UICorner")
                    pCorner.CornerRadius = UDim.new(0, 6)
                    pCorner.Parent = cpPickerFrame

                    local pStroke = Instance.new("UIStroke")
                    pStroke.Color = Library.Border
                    pStroke.Parent = cpPickerFrame

                    local pTitle = Instance.new("TextLabel")
                    pTitle.Size = UDim2.new(1, -12, 0, 20)
                    pTitle.Position = UDim2.new(0, 8, 0, 4)
                    pTitle.BackgroundTransparency = 1
                    pTitle.Font = Library.FontBold
                    pTitle.Text = cpTitle
                    pTitle.TextColor3 = Library.TextColor
                    pTitle.TextSize = 11
                    pTitle.TextXAlignment = Enum.TextXAlignment.Left
                    pTitle.ZIndex = 51
                    pTitle.Parent = cpPickerFrame

                    -- Saturation/Value Box
                    local svBox = Instance.new("ImageButton")
                    svBox.Size = UDim2.new(1, -16, 0, 100)
                    svBox.Position = UDim2.new(0, 8, 0, 26)
                    svBox.Image = "rbxassetid://4155801252"
                    svBox.BorderSizePixel = 0
                    svBox.AutoButtonColor = false
                    svBox.ZIndex = 51
                    svBox.Parent = cpPickerFrame

                    -- Hue Slider Bar
                    local hueBar = Instance.new("ImageButton")
                    hueBar.Size = UDim2.new(1, -16, 0, 12)
                    hueBar.Position = UDim2.new(0, 8, 0, 134)
                    hueBar.Image = "rbxassetid://3641079629"
                    hueBar.BorderSizePixel = 0
                    hueBar.AutoButtonColor = false
                    hueBar.ZIndex = 51
                    hueBar.Parent = cpPickerFrame

                    local currentHue, currentSat, currentVal = cpDef:ToHSV()

                    local ColorPickerObj = {
                        Value = cpDef,
                        Type = "ColorPicker",
                        SetValue = function(selfColor, color)
                            selfColor.Value = color
                            cpBtn.BackgroundColor3 = color
                            local h, s, v = color:ToHSV()
                            currentHue, currentSat, currentVal = h, s, v
                            svBox.BackgroundColor3 = Color3.fromHSV(currentHue, 1, 1)
                            task.spawn(cpCb, color)
                        end
                    }

                    svBox.BackgroundColor3 = Color3.fromHSV(currentHue, 1, 1)

                    local isDraggingSV = false
                    local isDraggingHue = false

                    svBox.InputBegan:Connect(function(input)
                        if input.UserInputType == Enum.UserInputType.MouseButton1 then
                            isDraggingSV = true
                        end
                    end)

                    hueBar.InputBegan:Connect(function(input)
                        if input.UserInputType == Enum.UserInputType.MouseButton1 then
                            isDraggingHue = true
                        end
                    end)

                    local moveConn = UserInputService.InputChanged:Connect(function(input)
                        if input.UserInputType == Enum.UserInputType.MouseMovement then
                            if isDraggingSV then
                                local rX = math.clamp((input.Position.X - svBox.AbsolutePosition.X) / svBox.AbsoluteSize.X, 0, 1)
                                local rY = math.clamp((input.Position.Y - svBox.AbsolutePosition.Y) / svBox.AbsoluteSize.Y, 0, 1)
                                currentSat = rX
                                currentVal = 1 - rY
                                ColorPickerObj:SetValue(Color3.fromHSV(currentHue, currentSat, currentVal))
                            elseif isDraggingHue then
                                local rX = math.clamp((input.Position.X - hueBar.AbsolutePosition.X) / hueBar.AbsoluteSize.X, 0, 1)
                                currentHue = rX
                                ColorPickerObj:SetValue(Color3.fromHSV(currentHue, currentSat, currentVal))
                            end
                        end
                    end)
                    table.insert(Library.Connections, moveConn)

                    local stopConn = UserInputService.InputEnded:Connect(function(input)
                        if input.UserInputType == Enum.UserInputType.MouseButton1 then
                            isDraggingSV = false
                            isDraggingHue = false
                        end
                    end)
                    table.insert(Library.Connections, stopConn)

                    cpBtn.MouseButton1Click:Connect(function()
                        cpPickerFrame.Visible = not cpPickerFrame.Visible
                    end)

                    if cpId then
                        Options[cpId] = ColorPickerObj
                    end

                    return ChainWrapper
                end

                -- Chained KeyPicker
                function ChainWrapper:AddKeyPicker(kpId, kpCfg)
                    kpCfg = kpCfg or {}
                    local kpDef = kpCfg.Default or "None"
                    local kpMode = kpCfg.Mode or "Toggle"
                    local kpText = kpCfg.Text or text
                    local sync = kpCfg.SyncToggleState == true
                    local noUi = kpCfg.NoUI == true
                    local kpCb = kpCfg.Callback or function() end

                    local KeyPickerObj = {
                        Value = kpDef,
                        Mode = kpMode,
                        Text = kpText,
                        SyncToggleState = sync,
                        ParentToggle = ToggleObj,
                        Active = false,
                        Type = "KeyPicker",
                        Callback = kpCb,
                        SetValue = function(selfKp, key)
                            selfKp.Value = key
                        end
                    }

                    if not noUi then
                        local kpBtn = Instance.new("TextButton")
                        kpBtn.Name = "KeyBtn_" .. tostring(kpId)
                        kpBtn.Size = UDim2.new(0, 42, 0, 16)
                        kpBtn.BackgroundColor3 = Library.Background
                        kpBtn.BorderSizePixel = 0
                        kpBtn.Font = Library.Font
                        kpBtn.Text = "[" .. ConvertKeyCodeToString(kpDef) .. "]"
                        kpBtn.TextColor3 = Library.SubTextColor
                        kpBtn.TextSize = 10
                        kpBtn.AutoButtonColor = false
                        kpBtn.Parent = addonsContainer

                        local kpCorner = Instance.new("UICorner")
                        kpCorner.CornerRadius = UDim.new(0, 3)
                        kpCorner.Parent = kpBtn

                        local listening = false
                        kpBtn.MouseButton1Click:Connect(function()
                            if listening then return end
                            listening = true
                            kpBtn.Text = "[...]"
                            kpBtn.TextColor3 = Library.Accent

                            local tempConn
                            tempConn = UserInputService.InputBegan:Connect(function(input)
                                if input.UserInputType == Enum.UserInputType.Keyboard or
                                   input.UserInputType == Enum.UserInputType.MouseButton1 or
                                   input.UserInputType == Enum.UserInputType.MouseButton2 or
                                   input.UserInputType == Enum.UserInputType.MouseButton3 then
                                    
                                    local keyVal = ParseKeyInput(input)
                                    if keyVal == Enum.KeyCode.Escape then
                                        keyVal = "None"
                                    end
                                    KeyPickerObj.Value = keyVal
                                    kpBtn.Text = "[" .. ConvertKeyCodeToString(keyVal) .. "]"
                                    kpBtn.TextColor3 = Library.SubTextColor
                                    listening = false
                                    tempConn:Disconnect()
                                end
                            end)
                        end)

                        KeyPickerObj.Button = kpBtn
                    end

                    table.insert(Library.Keybinds, KeyPickerObj)
                    if kpId then
                        Options[kpId] = KeyPickerObj
                    end

                    return ChainWrapper
                end

                return ChainWrapper
            end

            -- 2. SLIDER
            function Groupbox:AddSlider(id, cfg)
                cfg = cfg or {}
                local text = cfg.Text or id or "Slider"
                local min = cfg.Min or 0
                local max = cfg.Max or 100
                local def = cfg.Default or min
                local rounding = cfg.Rounding or 0
                local suffix = cfg.Suffix or ""
                local callback = cfg.Callback or function() end

                local row = Instance.new("Frame")
                row.Name = "Slider_" .. tostring(id)
                row.Size = UDim2.new(1, 0, 0, 36)
                row.BackgroundTransparency = 1
                row.Parent = gbContent

                local titleLabel = Instance.new("TextLabel")
                titleLabel.Size = UDim2.new(0.7, 0, 0, 16)
                titleLabel.BackgroundTransparency = 1
                titleLabel.Font = Library.Font
                titleLabel.Text = text
                titleLabel.TextColor3 = Library.TextColor
                titleLabel.TextSize = 12
                titleLabel.TextXAlignment = Enum.TextXAlignment.Left
                titleLabel.Parent = row

                local valLabel = Instance.new("TextLabel")
                valLabel.Size = UDim2.new(0.3, 0, 0, 16)
                valLabel.Position = UDim2.new(0.7, 0, 0, 0)
                valLabel.BackgroundTransparency = 1
                valLabel.Font = Library.Font
                valLabel.Text = tostring(def) .. suffix
                valLabel.TextColor3 = Library.SubTextColor
                valLabel.TextSize = 11
                valLabel.TextXAlignment = Enum.TextXAlignment.Right
                valLabel.Parent = row

                local track = Instance.new("TextButton")
                track.Size = UDim2.new(1, 0, 0, 8)
                track.Position = UDim2.new(0, 0, 0, 22)
                track.BackgroundColor3 = Library.Background
                track.BorderSizePixel = 0
                track.Text = ""
                track.AutoButtonColor = false
                track.Parent = row

                local tCorner = Instance.new("UICorner")
                tCorner.CornerRadius = UDim.new(0, 4)
                tCorner.Parent = track

                local fill = Instance.new("Frame")
                fill.Size = UDim2.new(math.clamp((def - min) / (max - min), 0, 1), 0, 1, 0)
                fill.BackgroundColor3 = Library.Accent
                fill.BorderSizePixel = 0
                fill.Parent = track

                local fCorner = Instance.new("UICorner")
                fCorner.CornerRadius = UDim.new(0, 4)
                fCorner.Parent = fill

                local SliderObj = {
                    Value = def,
                    Type = "Slider",
                    SetValue = function(selfSlider, newVal)
                        newVal = math.clamp(newVal, min, max)
                        newVal = Round(newVal, rounding)
                        selfSlider.Value = newVal
                        valLabel.Text = tostring(newVal) .. suffix
                        local ratio = math.clamp((newVal - min) / (max - min), 0, 1)
                        fill.Size = UDim2.new(ratio, 0, 1, 0)
                        task.spawn(callback, newVal)
                    end
                }

                local isDragging = false
                track.InputBegan:Connect(function(input)
                    if input.UserInputType == Enum.UserInputType.MouseButton1 then
                        isDragging = true
                        local ratio = math.clamp((input.Position.X - track.AbsolutePosition.X) / track.AbsoluteSize.X, 0, 1)
                        SliderObj:SetValue(min + ((max - min) * ratio))
                    end
                end)

                local dragConn = UserInputService.InputChanged:Connect(function(input)
                    if isDragging and input.UserInputType == Enum.UserInputType.MouseMovement then
                        local ratio = math.clamp((input.Position.X - track.AbsolutePosition.X) / track.AbsoluteSize.X, 0, 1)
                        SliderObj:SetValue(min + ((max - min) * ratio))
                    end
                end)
                table.insert(Library.Connections, dragConn)

                local releaseConn = UserInputService.InputEnded:Connect(function(input)
                    if input.UserInputType == Enum.UserInputType.MouseButton1 then
                        isDragging = false
                    end
                end)
                table.insert(Library.Connections, releaseConn)

                if id then
                    Options[id] = SliderObj
                end

                return SliderObj
            end

            -- 3. DROPDOWN (Single Select)
            function Groupbox:AddDropdown(id, cfg)
                cfg = cfg or {}
                local text = cfg.Text or id or "Dropdown"
                local values = cfg.Values or {}
                local def = cfg.Default or values[1] or ""
                local callback = cfg.Callback or function() end

                local row = Instance.new("Frame")
                row.Name = "Dropdown_" .. tostring(id)
                row.Size = UDim2.new(1, 0, 0, 48)
                row.BackgroundTransparency = 1
                row.Parent = gbContent

                local titleLabel = Instance.new("TextLabel")
                titleLabel.Size = UDim2.new(1, 0, 0, 16)
                titleLabel.BackgroundTransparency = 1
                titleLabel.Font = Library.Font
                titleLabel.Text = text
                titleLabel.TextColor3 = Library.TextColor
                titleLabel.TextSize = 12
                titleLabel.TextXAlignment = Enum.TextXAlignment.Left
                titleLabel.Parent = row

                local mainBtn = Instance.new("TextButton")
                mainBtn.Size = UDim2.new(1, 0, 0, 24)
                mainBtn.Position = UDim2.new(0, 0, 0, 20)
                mainBtn.BackgroundColor3 = Library.Background
                mainBtn.BorderSizePixel = 0
                mainBtn.Font = Library.Font
                mainBtn.Text = "  " .. tostring(def)
                mainBtn.TextColor3 = Library.TextColor
                mainBtn.TextSize = 11
                mainBtn.TextXAlignment = Enum.TextXAlignment.Left
                mainBtn.AutoButtonColor = false
                mainBtn.Parent = row

                local bCorner = Instance.new("UICorner")
                bCorner.CornerRadius = UDim.new(0, 4)
                bCorner.Parent = mainBtn

                local bStroke = Instance.new("UIStroke")
                bStroke.Color = Library.Border
                bStroke.Parent = mainBtn

                local arrow = Instance.new("TextLabel")
                arrow.Size = UDim2.new(0, 20, 1, 0)
                arrow.Position = UDim2.new(1, -20, 0, 0)
                arrow.BackgroundTransparency = 1
                arrow.Font = Library.Font
                arrow.Text = "v"
                arrow.TextColor3 = Library.SubTextColor
                arrow.TextSize = 10
                arrow.Parent = mainBtn

                -- Dropdown List popup
                local listFrame = Instance.new("Frame")
                listFrame.Name = "DropdownList"
                listFrame.Size = UDim2.new(1, 0, 0, 0)
                listFrame.Position = UDim2.new(0, 0, 1, 4)
                listFrame.BackgroundColor3 = Library.SectionBg
                listFrame.BorderSizePixel = 0
                listFrame.Visible = false
                listFrame.ZIndex = 40
                listFrame.ClipsDescendants = true
                listFrame.Parent = mainBtn

                local lCorner = Instance.new("UICorner")
                lCorner.CornerRadius = UDim.new(0, 4)
                lCorner.Parent = listFrame

                local lStroke = Instance.new("UIStroke")
                lStroke.Color = Library.Border
                lStroke.Parent = listFrame

                local lLayout = Instance.new("UIListLayout")
                lLayout.SortOrder = Enum.SortOrder.LayoutOrder
                lLayout.Parent = listFrame

                local DropdownObj = {
                    Value = def,
                    Values = values,
                    Type = "Dropdown",
                    SetValue = function(selfDd, val)
                        selfDd.Value = val
                        mainBtn.Text = "  " .. tostring(val)
                        task.spawn(callback, val)
                    end,
                    SetValues = function(selfDd, newVals)
                        selfDd.Values = newVals
                        for _, child in ipairs(listFrame:GetChildren()) do
                            if child:IsA("TextButton") then child:Destroy() end
                        end
                        listFrame.Size = UDim2.new(1, 0, 0, #newVals * 22)
                        for _, opt in ipairs(newVals) do
                            local optBtn = Instance.new("TextButton")
                            optBtn.Size = UDim2.new(1, 0, 0, 22)
                            optBtn.BackgroundColor3 = Library.SectionBg
                            optBtn.BorderSizePixel = 0
                            optBtn.Font = Library.Font
                            optBtn.Text = "  " .. tostring(opt)
                            optBtn.TextColor3 = (opt == selfDd.Value) and Library.Accent or Library.TextColor
                            optBtn.TextSize = 11
                            optBtn.TextXAlignment = Enum.TextXAlignment.Left
                            optBtn.ZIndex = 41
                            optBtn.Parent = listFrame

                            optBtn.MouseButton1Click:Connect(function()
                                selfDd:SetValue(opt)
                                listFrame.Visible = false
                                arrow.Text = "v"
                            end)
                        end
                    end
                }

                DropdownObj:SetValues(values)

                mainBtn.MouseButton1Click:Connect(function()
                    listFrame.Visible = not listFrame.Visible
                    arrow.Text = listFrame.Visible and "^" or "v"
                end)

                if id then
                    Options[id] = DropdownObj
                end

                return DropdownObj
            end

            -- 4. INPUT (TextBox)
            function Groupbox:AddInput(id, cfg)
                cfg = cfg or {}
                local text = cfg.Text or id or "Input"
                local def = cfg.Default or ""
                local placeholder = cfg.Placeholder or "Type here..."
                local finishedOnly = cfg.Finished ~= false
                local callback = cfg.Callback or function() end

                local row = Instance.new("Frame")
                row.Name = "Input_" .. tostring(id)
                row.Size = UDim2.new(1, 0, 0, 48)
                row.BackgroundTransparency = 1
                row.Parent = gbContent

                local titleLabel = Instance.new("TextLabel")
                titleLabel.Size = UDim2.new(1, 0, 0, 16)
                titleLabel.BackgroundTransparency = 1
                titleLabel.Font = Library.Font
                titleLabel.Text = text
                titleLabel.TextColor3 = Library.TextColor
                titleLabel.TextSize = 12
                titleLabel.TextXAlignment = Enum.TextXAlignment.Left
                titleLabel.Parent = row

                local textBox = Instance.new("TextBox")
                textBox.Size = UDim2.new(1, 0, 0, 24)
                textBox.Position = UDim2.new(0, 0, 0, 20)
                textBox.BackgroundColor3 = Library.Background
                textBox.BorderSizePixel = 0
                textBox.Font = Library.Font
                textBox.Text = def
                textBox.PlaceholderText = placeholder
                textBox.PlaceholderColor3 = Library.SubTextColor
                textBox.TextColor3 = Library.TextColor
                textBox.TextSize = 11
                textBox.ClearTextOnFocus = false
                textBox.Parent = row

                local tbCorner = Instance.new("UICorner")
                tbCorner.CornerRadius = UDim.new(0, 4)
                tbCorner.Parent = textBox

                local tbStroke = Instance.new("UIStroke")
                tbStroke.Color = Library.Border
                tbStroke.Parent = textBox

                local InputObj = {
                    Value = def,
                    Type = "Input",
                    SetValue = function(selfIn, val)
                        selfIn.Value = tostring(val)
                        textBox.Text = selfIn.Value
                        task.spawn(callback, selfIn.Value)
                    end
                }

                if finishedOnly then
                    textBox.FocusLost:Connect(function(enterPressed)
                        InputObj.Value = textBox.Text
                        task.spawn(callback, textBox.Text)
                    end)
                else
                    textBox:GetPropertyChangedSignal("Text"):Connect(function()
                        InputObj.Value = textBox.Text
                        task.spawn(callback, textBox.Text)
                    end)
                end

                if id then
                    Options[id] = InputObj
                end

                return InputObj
            end

            -- 5. BUTTON
            function Groupbox:AddButton(cfg)
                local text = (typeof(cfg) == "table" and cfg.Text) or tostring(cfg) or "Button"
                local callback = (typeof(cfg) == "table" and cfg.Callback) or function() end

                local btn = Instance.new("TextButton")
                btn.Name = "Button_" .. text
                btn.Size = UDim2.new(1, 0, 0, 26)
                btn.BackgroundColor3 = Library.Background
                btn.BorderSizePixel = 0
                btn.Font = Library.Font
                btn.Text = text
                btn.TextColor3 = Library.TextColor
                btn.TextSize = 12
                btn.AutoButtonColor = false
                btn.Parent = gbContent

                local bCorner = Instance.new("UICorner")
                bCorner.CornerRadius = UDim.new(0, 4)
                bCorner.Parent = btn

                local bStroke = Instance.new("UIStroke")
                bStroke.Color = Library.Border
                bStroke.Parent = btn

                btn.MouseEnter:Connect(function()
                    FastTween(btn, Enum.EasingStyle.Quad, 0.1, { BackgroundColor3 = Library.Border })
                end)
                btn.MouseLeave:Connect(function()
                    FastTween(btn, Enum.EasingStyle.Quad, 0.1, { BackgroundColor3 = Library.Background })
                end)
                btn.MouseButton1Click:Connect(function()
                    task.spawn(callback)
                end)

                return btn
            end

            -- 6. LABEL (with AddKeyPicker Chaining)
            function Groupbox:AddLabel(labelText)
                local row = Instance.new("Frame")
                row.Name = "LabelRow"
                row.Size = UDim2.new(1, 0, 0, 20)
                row.BackgroundTransparency = 1
                row.Parent = gbContent

                local lbl = Instance.new("TextLabel")
                lbl.Size = UDim2.new(1, -50, 1, 0)
                lbl.BackgroundTransparency = 1
                lbl.Font = Library.Font
                lbl.Text = labelText
                lbl.TextColor3 = Library.SubTextColor
                lbl.TextSize = 12
                lbl.TextXAlignment = Enum.TextXAlignment.Left
                lbl.Parent = row

                local addonsContainer = Instance.new("Frame")
                addonsContainer.Name = "Addons"
                addonsContainer.Size = UDim2.new(0, 0, 1, 0)
                addonsContainer.Position = UDim2.new(1, 0, 0, 0)
                addonsContainer.AnchorPoint = Vector2.new(1, 0)
                addonsContainer.BackgroundTransparency = 1
                addonsContainer.AutomaticSize = Enum.AutomaticSize.X
                addonsContainer.Parent = row

                local LabelChain = {
                    Label = lbl
                }

                function LabelChain:AddKeyPicker(kpId, kpCfg)
                    kpCfg = kpCfg or {}
                    local kpDef = kpCfg.Default or "None"
                    local kpMode = kpCfg.Mode or "Toggle"
                    local kpText = kpCfg.Text or labelText
                    local sync = kpCfg.SyncToggleState == true
                    local noUi = kpCfg.NoUI == true
                    local kpCb = kpCfg.Callback or function() end

                    local KeyPickerObj = {
                        Value = kpDef,
                        Mode = kpMode,
                        Text = kpText,
                        SyncToggleState = sync,
                        Active = false,
                        Type = "KeyPicker",
                        Callback = kpCb,
                        SetValue = function(selfKp, key)
                            selfKp.Value = key
                        end
                    }

                    if not noUi then
                        local kpBtn = Instance.new("TextButton")
                        kpBtn.Name = "KeyBtn_" .. tostring(kpId)
                        kpBtn.Size = UDim2.new(0, 42, 0, 16)
                        kpBtn.BackgroundColor3 = Library.Background
                        kpBtn.BorderSizePixel = 0
                        kpBtn.Font = Library.Font
                        kpBtn.Text = "[" .. ConvertKeyCodeToString(kpDef) .. "]"
                        kpBtn.TextColor3 = Library.SubTextColor
                        kpBtn.TextSize = 10
                        kpBtn.AutoButtonColor = false
                        kpBtn.Parent = addonsContainer

                        local kpCorner = Instance.new("UICorner")
                        kpCorner.CornerRadius = UDim.new(0, 3)
                        kpCorner.Parent = kpBtn

                        local listening = false
                        kpBtn.MouseButton1Click:Connect(function()
                            if listening then return end
                            listening = true
                            kpBtn.Text = "[...]"
                            kpBtn.TextColor3 = Library.Accent

                            local tempConn
                            tempConn = UserInputService.InputBegan:Connect(function(input)
                                if input.UserInputType == Enum.UserInputType.Keyboard or
                                   input.UserInputType == Enum.UserInputType.MouseButton1 or
                                   input.UserInputType == Enum.UserInputType.MouseButton2 or
                                   input.UserInputType == Enum.UserInputType.MouseButton3 then
                                    
                                    local keyVal = ParseKeyInput(input)
                                    if keyVal == Enum.KeyCode.Escape then
                                        keyVal = "None"
                                    end
                                    KeyPickerObj.Value = keyVal
                                    kpBtn.Text = "[" .. ConvertKeyCodeToString(keyVal) .. "]"
                                    kpBtn.TextColor3 = Library.SubTextColor
                                    listening = false
                                    tempConn:Disconnect()
                                end
                            end)
                        end)
                        KeyPickerObj.Button = kpBtn
                    end

                    table.insert(Library.Keybinds, KeyPickerObj)
                    if kpId then
                        Options[kpId] = KeyPickerObj
                    end

                    return LabelChain
                end

                return LabelChain
            end

            return Groupbox
        end

        function Tab:AddLeftGroupbox(title)
            local gb = CreateGroupbox(leftColumn, title)
            table.insert(Tab.LeftGroupboxes, gb)
            return gb
        end

        function Tab:AddRightGroupbox(title)
            local gb = CreateGroupbox(rightColumn, title)
            table.insert(Tab.RightGroupboxes, gb)
            return gb
        end

        return Tab
    end

    return WindowObj
end

-- =========================================================================
-- SAVE MANAGER (CONFIG SAVE / LOAD)
-- =========================================================================
function SaveManager:SetLibrary(lib)
    self.Library = lib
end

function SaveManager:SetFolder(folder)
    self.Folder = folder
    SafeMakeFolder(self.Folder)
end

function SaveManager:SetIgnoreIndexes(list)
    self.IgnoreIndexes = list
end

function SaveManager:IsIgnored(id)
    for _, ignored in ipairs(self.IgnoreIndexes) do
        if ignored == id then return true end
    end
    return false
end

function SaveManager:Save(name)
    if not writefile then return end
    SafeMakeFolder(self.Folder)

    local data = {}
    for id, opt in pairs(Options) do
        if not self:IsIgnored(id) and opt.Value ~= nil then
            if opt.Type == "ColorPicker" and typeof(opt.Value) == "Color3" then
                data[id] = { Type = "ColorPicker", Value = { opt.Value.R, opt.Value.G, opt.Value.B } }
            elseif opt.Type == "KeyPicker" then
                local k = opt.Value
                local serializedKey = (typeof(k) == "EnumItem" and k.Name) or tostring(k)
                data[id] = { Type = "KeyPicker", Value = serializedKey }
            else
                data[id] = { Type = opt.Type, Value = opt.Value }
            end
        end
    end

    local path = self.Folder .. "/" .. name .. ".json"
    local encoded = HttpService:JSONEncode(data)
    writefile(path, encoded)
    self.Library:Notify("Config saved: " .. name, 3)
end

function SaveManager:Load(name)
    if not (readfile and isfile) then return end
    local path = self.Folder .. "/" .. name .. ".json"
    if not isfile(path) then
        self.Library:Notify("Config not found: " .. name, 3)
        return
    end

    local content = readfile(path)
    local decoded = HttpService:JSONDecode(content)

    for id, item in pairs(decoded) do
        if not self:IsIgnored(id) and Options[id] then
            local opt = Options[id]
            if item.Type == "ColorPicker" and typeof(item.Value) == "table" then
                opt:SetValue(Color3.new(item.Value[1], item.Value[2], item.Value[3]))
            elseif item.Type == "KeyPicker" then
                local keyStr = item.Value
                if Enum.KeyCode[keyStr] then
                    opt:SetValue(Enum.KeyCode[keyStr])
                else
                    opt:SetValue(keyStr)
                end
            elseif opt.SetValue then
                opt:SetValue(item.Value)
            end
        end
    end

    self.Library:Notify("Config loaded: " .. name, 3)
end

function SaveManager:Delete(name)
    if not (delfile and isfile) then return end
    local path = self.Folder .. "/" .. name .. ".json"
    if isfile(path) then
        delfile(path)
        self.Library:Notify("Config deleted: " .. name, 3)
    end
end

function SaveManager:RefreshConfigs()
    local list = {}
    if listfiles and isfolder and isfolder(self.Folder) then
        for _, file in ipairs(listfiles(self.Folder)) do
            if file:sub(-5) == ".json" then
                local cleanName = file:match("([^/\\]+)%.json$")
                if cleanName then
                    table.insert(list, cleanName)
                end
            end
        end
    end
    return list
end

function SaveManager:LoadAutoloadConfig()
    if not (readfile and isfile) then return end
    SafeMakeFolder(self.Folder)
    local autoPath = self.Folder .. "/" .. self.AutoloadFile
    if isfile(autoPath) then
        local target = readfile(autoPath)
        if target and target ~= "" then
            self:Load(target)
        end
    end
end

function SaveManager:BuildConfigSection(tab)
    SafeMakeFolder(self.Folder)
    local gb = tab:AddRightGroupbox("Configuration")

    local configList = self:RefreshConfigs()
    local selectedConfig = configList[1] or ""

    local configDropdown = gb:AddDropdown("SaveManager_ConfigList", {
        Text = "Config List",
        Values = configList,
        Default = selectedConfig,
        Callback = function(val)
            selectedConfig = val
        end
    })

    local configNameInput = gb:AddInput("SaveManager_ConfigName", {
        Text = "New Config Name",
        Default = "",
        Placeholder = "default",
        Finished = true
    })

    gb:AddButton({
        Text = "Create / Save Config",
        Callback = function()
            local name = configNameInput.Value
            if name == "" then name = "default" end
            self:Save(name)
            local updated = self:RefreshConfigs()
            configDropdown:SetValues(updated)
        end
    })

    gb:AddButton({
        Text = "Load Selected Config",
        Callback = function()
            if selectedConfig ~= "" then
                self:Load(selectedConfig)
            end
        end
    })

    gb:AddButton({
        Text = "Overwrite Selected",
        Callback = function()
            if selectedConfig ~= "" then
                self:Save(selectedConfig)
            end
        end
    })

    gb:AddButton({
        Text = "Delete Selected",
        Callback = function()
            if selectedConfig ~= "" then
                self:Delete(selectedConfig)
                local updated = self:RefreshConfigs()
                configDropdown:SetValues(updated)
            end
        end
    })

    gb:AddButton({
        Text = "Set As Autoload",
        Callback = function()
            if selectedConfig ~= "" and writefile then
                SafeMakeFolder(self.Folder)
                writefile(self.Folder .. "/" .. self.AutoloadFile, selectedConfig)
                self.Library:Notify("Autoload set to: " .. selectedConfig, 3)
            end
        end
    })

    gb:AddButton({
        Text = "Refresh List",
        Callback = function()
            local updated = self:RefreshConfigs()
            configDropdown:SetValues(updated)
        end
    })
end

-- =========================================================================
-- THEME MANAGER
-- =========================================================================
function ThemeManager:SetLibrary(lib)
    self.Library = lib
end

function ThemeManager:SetFolder(folder)
    self.Folder = folder
    SafeMakeFolder(self.Folder)
end

function ThemeManager:ApplyToTab(tab)
    local gb = tab:AddLeftGroupbox("Theme Settings")

    local themeNames = {}
    for name, _ in pairs(self.BuiltInThemes) do
        table.insert(themeNames, name)
    end

    gb:AddDropdown("ThemeManager_Presets", {
        Text = "Accent Theme Presets",
        Values = themeNames,
        Default = "Crimson Red",
        Callback = function(themeName)
            local col = self.BuiltInThemes[themeName]
            if col then
                self.Library.Accent = col
                if Options["ThemeManager_CustomAccent"] then
                    Options["ThemeManager_CustomAccent"]:SetValue(col)
                end
            end
        end
    })

    local accentToggle = gb:AddToggle("ThemeManager_CustomAccentToggle", {
        Text = "Custom Accent Color",
        Default = false
    })

    accentToggle:AddColorPicker("ThemeManager_CustomAccent", {
        Default = self.Library.Accent,
        Title = "Accent Color",
        Callback = function(color)
            self.Library.Accent = color
        end
    })

    gb:AddLabel("Unload Library"):AddKeyPicker("UnloadMenuKey", {
        Default = "End",
        Mode = "Toggle",
        Text = "Unload UI",
        Callback = function()
            self.Library:Unload()
        end
    })
end

-- Expose Sub-Managers
Library.SaveManager = SaveManager
Library.ThemeManager = ThemeManager

return Library
