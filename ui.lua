-- [[ Ruby UI Library - Complete Glassmorphic Engine with Lucide Icon Support ]]
-- Architecture: Window -> Tab -> Groupbox (Left/Right) -> Controls
-- Supported Icons: Lucide Icon Names ("swords", "flame", "eye", etc.) OR Roblox Asset ID ("rbxassetid://...")

local UserInputService = game:GetService("UserInputService")
local TweenService = game:GetService("TweenService")
local CoreGui = game:GetService("CoreGui")
local Players = game:GetService("Players")
local HttpService = game:GetService("HttpService")

local LocalPlayer = Players.LocalPlayer

local function GetSafeGuiParent()
    local success, parent = pcall(function()
        if gethui then return gethui() end
        return CoreGui
    end)
    if success and parent then return parent end
    return LocalPlayer:WaitForChild("PlayerGui")
end

-- =========================================================================
-- GLOBAL STATE & REGISTRY
-- =========================================================================
local Options = {}
local Toggles = {}

_G.Options = Options
_G.Toggles = Toggles
if getgenv then
    getgenv().Options = Options
    getgenv().Toggles = Toggles
end

local Library = {
    Name = "RubyUI",
    Open = true,
    Accent = Color3.fromRGB(250, 44, 83),          -- Vivid Ruby Rose
    GlassBg = Color3.fromRGB(15, 16, 22),         -- Deep Frosted Base
    GlassSidebar = Color3.fromRGB(11, 12, 17),    -- Dark Sidebar Tint
    GlassSection = Color3.fromRGB(20, 22, 30),    -- Translucent Element Card
    GlassElement = Color3.fromRGB(26, 28, 38),    -- Input & Slider Base
    GlassBorder = Color3.fromRGB(60, 65, 85),     -- Glass Edge Highlight
    GlassBorderSoft = Color3.fromRGB(36, 40, 52), -- Muted Sub-border
    TextColor = Color3.fromRGB(245, 245, 250),
    SubTextColor = Color3.fromRGB(140, 144, 165),
    Font = Enum.Font.GothamMedium,
    FontBold = Enum.Font.GothamBold,
    UnloadCallbacks = {},
    Connections = {},
    Keybinds = {},
    ScreenGui = nil,
    MainWindow = nil,
    NotificationContainer = nil,
    LucideCache = {},
}

-- Built-in Lucide Fallback Table
local BuiltInLucide = {
    ["swords"] = "rbxassetid://10709791437",
    ["sword"] = "rbxassetid://10709791281",
    ["crosshair"] = "rbxassetid://10709769841",
    ["shield"] = "rbxassetid://10723346959",
    ["flame"] = "rbxassetid://10709775963",
    ["eye"] = "rbxassetid://10723345518",
    ["activity"] = "rbxassetid://10709752035",
    ["globe"] = "rbxassetid://10723343321",
    ["settings"] = "rbxassetid://10734950309",
    ["box"] = "rbxassetid://10709759764",
    ["user"] = "rbxassetid://10747373176",
    ["users"] = "rbxassetid://10747373426",
    ["zap"] = "rbxassetid://10734996996",
    ["terminal"] = "rbxassetid://10747372431",
    ["code"] = "rbxassetid://10709768704",
    ["compass"] = "rbxassetid://10709769317",
    ["search"] = "rbxassetid://10734883986",
    ["file-text"] = "rbxassetid://10723346158",
    ["folder"] = "rbxassetid://10723346376",
    ["bell"] = "rbxassetid://10709756155",
    ["lock"] = "rbxassetid://10723346593",
    ["key"] = "rbxassetid://10723346487",
    ["trash"] = "rbxassetid://10747373059",
    ["save"] = "rbxassetid://10734883598",
    ["sliders"] = "rbxassetid://10734950857",
    ["mouse-pointer"] = "rbxassetid://10734884248",
    ["cross"] = "rbxassetid://10709769993"
}

-- Lucide / Asset Resolver
local function ResolveIcon(iconInput)
    if not iconInput or iconInput == "" then return "" end
    iconInput = tostring(iconInput)

    -- Case 1: Direct Asset ID or URL
    if iconInput:find("rbxassetid://") or iconInput:find("http://") or iconInput:find("https://") then
        return iconInput
    end
    if tonumber(iconInput) then
        return "rbxassetid://" .. iconInput
    end

    -- Case 2: Clean Lucide Name Resolver
    local cleanName = iconInput:lower():gsub("^lucide%-", ""):gsub("_", "-")

    -- Check Memory Cache
    if Library.LucideCache[cleanName] then
        return Library.LucideCache[cleanName]
    end

    -- Check Built-in Fallbacks
    if BuiltInLucide[cleanName] then
        Library.LucideCache[cleanName] = BuiltInLucide[cleanName]
        return BuiltInLucide[cleanName]
    end

    -- Fetch from external Lucide index if available
    local success, assetId = pcall(function()
        if game.HttpGet then
            local json = game:HttpGet("https://raw.githubusercontent.com/Footagesus/lucide-roblox/main/icons.json")
            local parsed = HttpService:JSONDecode(json)
            if parsed and parsed[cleanName] then
                return "rbxassetid://" .. tostring(parsed[cleanName])
            end
        end
        return nil
    end)

    if success and assetId then
        Library.LucideCache[cleanName] = assetId
        return assetId
    end

    return "rbxassetid://10709759764" -- Safe fallback (Box icon)
end

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
        ["Ruby Rose"] = Color3.fromRGB(250, 44, 83),
        ["Amethyst Violet"] = Color3.fromRGB(155, 89, 255),
        ["Cyber Cyan"] = Color3.fromRGB(0, 230, 255),
        ["Emerald Glow"] = Color3.fromRGB(46, 213, 115),
        ["Solar Amber"] = Color3.fromRGB(255, 165, 2),
        ["Minimalist Snow"] = Color3.fromRGB(240, 240, 245),
    }
}

-- =========================================================================
-- ANIMATION / TWEEN ENGINE
-- =========================================================================
function Library:Tween(object, time, properties, style, direction)
    local info = TweenInfo.new(time or 0.2, style or Enum.EasingStyle.Quad, direction or Enum.EasingDirection.Out)
    local anim = TweenService:Create(object, info, properties)
    anim:Play()
    return anim
end

function Library:Animate(object, animType)
    if animType == "Pop" then
        object.Size = object.Size - UDim2.new(0, 4, 0, 4)
        Library:Tween(object, 0.15, { Size = object.Size + UDim2.new(0, 4, 0, 4) }, Enum.EasingStyle.Back, Enum.EasingDirection.Out)
    elseif animType == "Pulse" then
        local originalColor = object.BackgroundColor3
        Library:Tween(object, 0.1, { BackgroundColor3 = Library.Accent })
        task.delay(0.12, function()
            Library:Tween(object, 0.2, { BackgroundColor3 = originalColor })
        end)
    end
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
    if name == "RightShift" then return "RShift" end
    if name == "LeftShift" then return "LShift" end
    if name == "RightControl" then return "RCtrl" end
    if name == "LeftControl" then return "LCtrl" end
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

local inputBeganConn = UserInputService.InputBegan:Connect(function(input, gameProcessed)
    if not gameProcessed and Options.MenuKeybind then
        local menuKey = Options.MenuKeybind.Value
        if KeyMatches(menuKey, input.KeyCode) or KeyMatches(menuKey, input.UserInputType) then
            Library:Toggle()
            return
        end
    end

    if gameProcessed then return end

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
-- NOTIFICATION SYSTEM
-- =========================================================================
function Library:Notify(message, duration)
    duration = duration or 3
    if not self.NotificationContainer then return end

    local notifFrame = Instance.new("Frame")
    notifFrame.Name = "Toast"
    notifFrame.Size = UDim2.new(1, 0, 0, 38)
    notifFrame.BackgroundColor3 = self.GlassSection
    notifFrame.BackgroundTransparency = 1
    notifFrame.BorderSizePixel = 0
    notifFrame.Parent = self.NotificationContainer

    local corner = Instance.new("UICorner")
    corner.CornerRadius = UDim.new(0, 6)
    corner.Parent = notifFrame

    local stroke = Instance.new("UIStroke")
    stroke.Color = self.GlassBorder
    stroke.Transparency = 1
    stroke.Parent = notifFrame

    local accentBar = Instance.new("Frame")
    accentBar.Size = UDim2.new(0, 3, 1, -12)
    accentBar.Position = UDim2.new(0, 8, 0.5, -13)
    accentBar.BackgroundColor3 = self.Accent
    accentBar.BorderSizePixel = 0
    accentBar.BackgroundTransparency = 1
    accentBar.Parent = notifFrame

    local barCorner = Instance.new("UICorner")
    barCorner.CornerRadius = UDim.new(0, 3)
    barCorner.Parent = accentBar

    local textLabel = Instance.new("TextLabel")
    textLabel.Size = UDim2.new(1, -28, 1, 0)
    textLabel.Position = UDim2.new(0, 18, 0, 0)
    textLabel.BackgroundTransparency = 1
    textLabel.Font = self.Font
    textLabel.Text = tostring(message)
    textLabel.TextColor3 = self.TextColor
    textLabel.TextSize = 12
    textLabel.TextXAlignment = Enum.TextXAlignment.Left
    textLabel.TextTransparency = 1
    textLabel.Parent = notifFrame

    Library:Tween(notifFrame, 0.25, { BackgroundTransparency = 0.15 })
    Library:Tween(stroke, 0.25, { Transparency = 0.3 })
    Library:Tween(accentBar, 0.25, { BackgroundTransparency = 0 })
    Library:Tween(textLabel, 0.25, { TextTransparency = 0 })

    task.delay(duration, function()
        if not notifFrame.Parent then return end
        Library:Tween(notifFrame, 0.2, { BackgroundTransparency = 1 })
        Library:Tween(stroke, 0.2, { Transparency = 1 })
        Library:Tween(accentBar, 0.2, { BackgroundTransparency = 1 })
        Library:Tween(textLabel, 0.2, { TextTransparency = 1 })
        task.wait(0.22)
        notifFrame:Destroy()
    end)
end

-- =========================================================================
-- OPTIONAL KEY SYSTEM
-- =========================================================================
function Library:InitKeySystem(config)
    config = config or {}
    local Title = config.Title or "Key Verification"
    local TargetKey = config.Key or "RUBY-2026-KEY"
    local DiscordUrl = config.Discord or "https://discord.gg/"
    local OnSuccess = config.OnSuccess or function() end

    local ScreenGui = self.ScreenGui or Instance.new("ScreenGui")
    ScreenGui.Name = "RubyKeySystemGui"
    ScreenGui.ResetOnSpawn = false
    ScreenGui.ZIndexBehavior = Enum.ZIndexBehavior.Sibling
    ScreenGui.DisplayOrder = 1100
    ScreenGui.Parent = GetSafeGuiParent()
    self.ScreenGui = ScreenGui

    local KeyFrame = Instance.new("Frame")
    KeyFrame.Name = "KeyModal"
    KeyFrame.Size = UDim2.new(0, 360, 0, 220)
    KeyFrame.Position = UDim2.new(0.5, -180, 0.5, -110)
    KeyFrame.BackgroundColor3 = self.GlassBg
    KeyFrame.BackgroundTransparency = 0.1
    KeyFrame.BorderSizePixel = 0
    KeyFrame.ClipsDescendants = true
    KeyFrame.Parent = ScreenGui

    local corner = Instance.new("UICorner")
    corner.CornerRadius = UDim.new(0, 10)
    corner.Parent = KeyFrame

    local stroke = Instance.new("UIStroke")
    stroke.Color = self.GlassBorder
    stroke.Thickness = 1.2
    stroke.Parent = KeyFrame

    local isDrag, dragStart, startPos
    KeyFrame.InputBegan:Connect(function(input)
        if input.UserInputType == Enum.UserInputType.MouseButton1 then
            isDrag = true
            dragStart = input.Position
            startPos = KeyFrame.Position
        end
    end)
    local dragEnd = UserInputService.InputEnded:Connect(function(input)
        if input.UserInputType == Enum.UserInputType.MouseButton1 then
            isDrag = false
        end
    end)
    table.insert(self.Connections, dragEnd)

    local dragMv = UserInputService.InputChanged:Connect(function(input)
        if isDrag and input.UserInputType == Enum.UserInputType.MouseMovement then
            local delta = input.Position - dragStart
            KeyFrame.Position = UDim2.new(startPos.X.Scale, startPos.X.Offset + delta.X, startPos.Y.Scale, startPos.Y.Offset + delta.Y)
        end
    end)
    table.insert(self.Connections, dragMv)

    local topGlow = Instance.new("Frame")
    topGlow.Size = UDim2.new(1, 0, 0, 2)
    topGlow.BackgroundColor3 = self.Accent
    topGlow.BorderSizePixel = 0
    topGlow.Parent = KeyFrame

    local kTitle = Instance.new("TextLabel")
    kTitle.Size = UDim2.new(1, -24, 0, 30)
    kTitle.Position = UDim2.new(0, 16, 0, 14)
    kTitle.BackgroundTransparency = 1
    kTitle.Font = self.FontBold
    kTitle.Text = Title
    kTitle.TextColor3 = self.TextColor
    kTitle.TextSize = 15
    kTitle.TextXAlignment = Enum.TextXAlignment.Left
    kTitle.Parent = KeyFrame

    local kSub = Instance.new("TextLabel")
    kSub.Size = UDim2.new(1, -24, 0, 16)
    kSub.Position = UDim2.new(0, 16, 0, 42)
    kSub.BackgroundTransparency = 1
    kSub.Font = self.Font
    kSub.Text = "Please enter your access license key to continue"
    kSub.TextColor3 = self.SubTextColor
    kSub.TextSize = 11
    kSub.TextXAlignment = Enum.TextXAlignment.Left
    kSub.Parent = KeyFrame

    local inputField = Instance.new("TextBox")
    inputField.Size = UDim2.new(1, -32, 0, 36)
    inputField.Position = UDim2.new(0, 16, 0, 76)
    inputField.BackgroundColor3 = self.GlassElement
    inputField.BackgroundTransparency = 0.2
    inputField.BorderSizePixel = 0
    inputField.Font = self.Font
    inputField.PlaceholderText = "Paste License Key..."
    inputField.PlaceholderColor3 = self.SubTextColor
    inputField.Text = ""
    inputField.TextColor3 = self.TextColor
    inputField.TextSize = 12
    inputField.ClearTextOnFocus = false
    inputField.Parent = KeyFrame

    local inputCorner = Instance.new("UICorner")
    inputCorner.CornerRadius = UDim.new(0, 6)
    inputCorner.Parent = inputField

    local inputStroke = Instance.new("UIStroke")
    inputStroke.Color = self.GlassBorderSoft
    inputStroke.Parent = inputField

    local verifyBtn = Instance.new("TextButton")
    verifyBtn.Size = UDim2.new(1, -32, 0, 34)
    verifyBtn.Position = UDim2.new(0, 16, 0, 122)
    verifyBtn.BackgroundColor3 = self.Accent
    verifyBtn.BorderSizePixel = 0
    verifyBtn.Font = self.FontBold
    verifyBtn.Text = "AUTHENTICATE"
    verifyBtn.TextColor3 = Color3.fromRGB(255, 255, 255)
    verifyBtn.TextSize = 12
    verifyBtn.AutoButtonColor = false
    verifyBtn.Parent = KeyFrame

    local vCorner = Instance.new("UICorner")
    vCorner.CornerRadius = UDim.new(0, 6)
    vCorner.Parent = verifyBtn

    local discordBtn = Instance.new("TextButton")
    discordBtn.Size = UDim2.new(1, -32, 0, 24)
    discordBtn.Position = UDim2.new(0, 16, 0, 164)
    discordBtn.BackgroundTransparency = 1
    discordBtn.Font = self.Font
    discordBtn.Text = "Get key via Discord link (Click to copy)"
    discordBtn.TextColor3 = self.SubTextColor
    discordBtn.TextSize = 11
    discordBtn.Parent = KeyFrame

    discordBtn.MouseButton1Click:Connect(function()
        if setclipboard then
            setclipboard(DiscordUrl)
            Library:Notify("Discord link copied to clipboard!", 2.5)
        end
    end)

    verifyBtn.MouseButton1Click:Connect(function()
        if inputField.Text == TargetKey then
            verifyBtn.Text = "ACCESS GRANTED"
            Library:Tween(verifyBtn, 0.2, { BackgroundColor3 = Color3.fromRGB(46, 213, 115) })
            task.wait(0.5)
            Library:Tween(KeyFrame, 0.25, { Size = UDim2.new(0, 360, 0, 0), Position = KeyFrame.Position + UDim2.new(0, 0, 0, 110) })
            task.wait(0.28)
            KeyFrame:Destroy()
            OnSuccess()
        else
            verifyBtn.Text = "INVALID KEY"
            Library:Tween(verifyBtn, 0.15, { BackgroundColor3 = Color3.fromRGB(200, 40, 40) })
            task.delay(1, function()
                verifyBtn.Text = "AUTHENTICATE"
                Library:Tween(verifyBtn, 0.2, { BackgroundColor3 = Library.Accent })
            end)
        end
    end)
end

-- =========================================================================
-- MAIN WINDOW CREATION
-- =========================================================================
function Library:CreateWindow(config)
    config = config or {}
    local TitleText = config.Title or "EXTERNAL V2"
    local SubTitleText = config.SubTitle or "UNIVERSAL"
    local FooterText = config.Footer or "Build 2026.11 | Daegu"
    local Center = config.Center ~= false
    local AutoShow = config.AutoShow ~= false

    local ScreenGui = self.ScreenGui or Instance.new("ScreenGui")
    ScreenGui.Name = "RubyWindowGui"
    ScreenGui.ResetOnSpawn = false
    ScreenGui.ZIndexBehavior = Enum.ZIndexBehavior.Sibling
    ScreenGui.DisplayOrder = 1000
    ScreenGui.Parent = GetSafeGuiParent()
    self.ScreenGui = ScreenGui

    -- Toast Stack
    local notifContainer = Instance.new("Frame")
    notifContainer.Name = "NotificationStack"
    notifContainer.Size = UDim2.new(0, 270, 1, -40)
    notifContainer.Position = UDim2.new(1, -286, 0, 20)
    notifContainer.BackgroundTransparency = 1
    notifContainer.Parent = ScreenGui

    local notifLayout = Instance.new("UIListLayout")
    notifLayout.SortOrder = Enum.SortOrder.LayoutOrder
    notifLayout.VerticalAlignment = Enum.VerticalAlignment.Bottom
    notifLayout.Padding = UDim.new(0, 8)
    notifLayout.Parent = notifContainer
    self.NotificationContainer = notifContainer

    -- Outer Glass Window
    local MainWindow = Instance.new("Frame")
    MainWindow.Name = "RubyMainWindow"
    MainWindow.Size = UDim2.new(0, 720, 0, 490)
    if Center then
        MainWindow.Position = UDim2.new(0.5, -360, 0.5, -245)
    else
        MainWindow.Position = UDim2.new(0, 100, 0, 100)
    end
    MainWindow.BackgroundColor3 = self.GlassBg
    MainWindow.BackgroundTransparency = 0.15 -- True Frosted Glass Look
    MainWindow.BorderSizePixel = 0
    MainWindow.Visible = AutoShow
    MainWindow.ClipsDescendants = true -- Prevents content leaking outside
    MainWindow.Parent = ScreenGui
    self.MainWindow = MainWindow

    local mainCorner = Instance.new("UICorner")
    mainCorner.CornerRadius = UDim.new(0, 8)
    mainCorner.Parent = MainWindow

    local mainStroke = Instance.new("UIStroke")
    mainStroke.Color = self.GlassBorder
    mainStroke.Thickness = 1.2
    mainStroke.Transparency = 0.25
    mainStroke.Parent = MainWindow

    -- Dragging Logic
    local dragging, dragStart, startPos
    local titleBar = Instance.new("Frame")
    titleBar.Name = "Header"
    titleBar.Size = UDim2.new(1, 0, 0, 44)
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

    -- Accent Top Strip
    local topAccent = Instance.new("Frame")
    topAccent.Size = UDim2.new(1, 0, 0, 2)
    topAccent.BackgroundColor3 = self.Accent
    topAccent.BorderSizePixel = 0
    topAccent.Parent = MainWindow

    -- Title Labels
    local titleLabel = Instance.new("TextLabel")
    titleLabel.Name = "TitleText"
    titleLabel.Size = UDim2.new(0, 200, 1, 0)
    titleLabel.Position = UDim2.new(0, 16, 0, 0)
    titleLabel.BackgroundTransparency = 1
    titleLabel.Font = self.FontBold
    titleLabel.Text = TitleText
    titleLabel.TextColor3 = self.TextColor
    titleLabel.TextSize = 14
    titleLabel.TextXAlignment = Enum.TextXAlignment.Left
    titleLabel.Parent = titleBar

    local subTitleLabel = Instance.new("TextLabel")
    subTitleLabel.Name = "SubTitleText"
    subTitleLabel.Size = UDim2.new(0, 200, 1, 0)
    subTitleLabel.Position = UDim2.new(0, 16 + titleLabel.TextBounds.X + 8, 0, 0)
    subTitleLabel.BackgroundTransparency = 1
    subTitleLabel.Font = self.Font
    subTitleLabel.Text = SubTitleText
    subTitleLabel.TextColor3 = self.SubTextColor
    subTitleLabel.TextSize = 12
    subTitleLabel.TextXAlignment = Enum.TextXAlignment.Left
    subTitleLabel.Parent = titleBar

    titleLabel:GetPropertyChangedSignal("TextBounds"):Connect(function()
        subTitleLabel.Position = UDim2.new(0, 16 + titleLabel.TextBounds.X + 8, 0, 0)
    end)

    local headerLine = Instance.new("Frame")
    headerLine.Size = UDim2.new(1, 0, 0, 1)
    headerLine.Position = UDim2.new(0, 0, 0, 44)
    headerLine.BackgroundColor3 = self.GlassBorderSoft
    headerLine.BorderSizePixel = 0
    headerLine.Parent = MainWindow

    -- =========================================================================
    -- FIXED SIDEBAR (CONFINED & SCROLLABLE CONTAINER)
    -- =========================================================================
    local sidebar = Instance.new("Frame")
    sidebar.Name = "Sidebar"
    sidebar.Size = UDim2.new(0, 150, 1, -72)
    sidebar.Position = UDim2.new(0, 0, 0, 45)
    sidebar.BackgroundColor3 = self.GlassSidebar
    sidebar.BackgroundTransparency = 0.25
    sidebar.BorderSizePixel = 0
    sidebar.ClipsDescendants = true
    sidebar.Parent = MainWindow

    local sidebarScroll = Instance.new("ScrollingFrame")
    sidebarScroll.Name = "SidebarScroll"
    sidebarScroll.Size = UDim2.new(1, 0, 1, 0)
    sidebarScroll.BackgroundTransparency = 1
    sidebarScroll.BorderSizePixel = 0
    sidebarScroll.ScrollBarThickness = 0
    sidebarScroll.CanvasSize = UDim2.new(0, 0, 0, 0)
    sidebarScroll.Parent = sidebar

    local sidebarLayout = Instance.new("UIListLayout")
    sidebarLayout.SortOrder = Enum.SortOrder.LayoutOrder
    sidebarLayout.Padding = UDim.new(0, 4)
    sidebarLayout.Parent = sidebarScroll

    local sidebarPad = Instance.new("UIPadding")
    sidebarPad.PaddingTop = UDim.new(0, 8)
    sidebarPad.PaddingBottom = UDim.new(0, 8)
    sidebarPad.PaddingLeft = UDim.new(0, 8)
    sidebarPad.PaddingRight = UDim.new(0, 8)
    sidebarPad.Parent = sidebarScroll

    sidebarLayout:GetPropertyChangedSignal("AbsoluteContentSize"):Connect(function()
        sidebarScroll.CanvasSize = UDim2.new(0, 0, 0, sidebarLayout.AbsoluteContentSize.Y + 16)
    end)

    local sidebarDivider = Instance.new("Frame")
    sidebarDivider.Size = UDim2.new(0, 1, 1, -72)
    sidebarDivider.Position = UDim2.new(0, 150, 0, 45)
    sidebarDivider.BackgroundColor3 = self.GlassBorderSoft
    sidebarDivider.BorderSizePixel = 0
    sidebarDivider.Parent = MainWindow

    -- Viewport Container
    local tabContainer = Instance.new("Frame")
    tabContainer.Name = "TabViews"
    tabContainer.Size = UDim2.new(1, -151, 1, -72)
    tabContainer.Position = UDim2.new(0, 151, 0, 45)
    tabContainer.BackgroundTransparency = 1
    tabContainer.ClipsDescendants = true
    tabContainer.Parent = MainWindow

    -- Footer
    local footerLine = Instance.new("Frame")
    footerLine.Size = UDim2.new(1, 0, 0, 1)
    footerLine.Position = UDim2.new(0, 0, 1, -27)
    footerLine.BackgroundColor3 = self.GlassBorderSoft
    footerLine.BorderSizePixel = 0
    footerLine.Parent = MainWindow

    local footerLabel = Instance.new("TextLabel")
    footerLabel.Name = "FooterText"
    footerLabel.Size = UDim2.new(1, -24, 0, 26)
    footerLabel.Position = UDim2.new(0, 14, 1, -26)
    footerLabel.BackgroundTransparency = 1
    footerLabel.Font = self.Font
    footerLabel.Text = FooterText
    footerLabel.TextColor3 = self.SubTextColor
    footerLabel.TextSize = 11
    footerLabel.TextXAlignment = Enum.TextXAlignment.Left
    footerLabel.Parent = MainWindow

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
        CurrentTab = nil
    }

    function Library:Toggle()
        self.Open = not self.Open
        if self.Open then
            MainWindow.Visible = true
            Library:Tween(MainWindow, 0.2, { Size = UDim2.new(0, 720, 0, 490) }, Enum.EasingStyle.Back, Enum.EasingDirection.Out)
        else
            Library:Tween(MainWindow, 0.15, { Size = UDim2.new(0, 700, 0, 470) })
            task.delay(0.15, function()
                if not self.Open then
                    MainWindow.Visible = false
                end
            end)
        end
    end

    -- =========================================================================
    -- TAB IMPLEMENTATION (WITH RESOLVED ICON)
    -- =========================================================================
    function WindowObj:AddTab(tabName, iconInput)
        local Tab = {
            Name = tabName,
            LeftGroupboxes = {},
            RightGroupboxes = {},
        }

        local finalIcon = ResolveIcon(iconInput)

        local tabButton = Instance.new("TextButton")
        tabButton.Name = "TabBtn_" .. tabName
        tabButton.Size = UDim2.new(1, 0, 0, 32)
        tabButton.BackgroundColor3 = Library.GlassSection
        tabButton.BackgroundTransparency = 1
        tabButton.AutoButtonColor = false
        tabButton.Text = ""
        tabButton.Parent = sidebarScroll

        local btnCorner = Instance.new("UICorner")
        btnCorner.CornerRadius = UDim.new(0, 6)
        btnCorner.Parent = tabButton

        local iconImg = nil
        if finalIcon and finalIcon ~= "" then
            iconImg = Instance.new("ImageLabel")
            iconImg.Size = UDim2.new(0, 15, 0, 15)
            iconImg.Position = UDim2.new(0, 8, 0.5, -8)
            iconImg.BackgroundTransparency = 1
            iconImg.Image = finalIcon
            iconImg.ImageColor3 = Library.SubTextColor
            iconImg.Parent = tabButton
        end

        local tabTitle = Instance.new("TextLabel")
        tabTitle.Size = UDim2.new(1, iconImg and -34 or -16, 1, 0)
        tabTitle.Position = UDim2.new(0, iconImg and 32 or 12, 0, 0)
        tabTitle.BackgroundTransparency = 1
        tabTitle.Font = Library.Font
        tabTitle.Text = tabName
        tabTitle.TextColor3 = Library.SubTextColor
        tabTitle.TextSize = 12
        tabTitle.TextXAlignment = Enum.TextXAlignment.Left
        tabTitle.Parent = tabButton

        local activeBar = Instance.new("Frame")
        activeBar.Size = UDim2.new(0, 3, 0, 16)
        activeBar.Position = UDim2.new(0, 1, 0.5, -8)
        activeBar.BackgroundColor3 = Library.Accent
        activeBar.BorderSizePixel = 0
        activeBar.BackgroundTransparency = 1
        activeBar.Parent = tabButton

        local abCorner = Instance.new("UICorner")
        abCorner.CornerRadius = UDim.new(0, 2)
        abCorner.Parent = activeBar

        -- Scrollable Tab View Frame
        local tabScroll = Instance.new("ScrollingFrame")
        tabScroll.Name = "Scroll_" .. tabName
        tabScroll.Size = UDim2.new(1, 0, 1, 0)
        tabScroll.BackgroundTransparency = 1
        tabScroll.BorderSizePixel = 0
        tabScroll.ScrollBarThickness = 3
        tabScroll.ScrollBarImageColor3 = Library.GlassBorder
        tabScroll.Visible = false
        tabScroll.CanvasSize = UDim2.new(0, 0, 0, 0)
        tabScroll.Parent = tabContainer

        local pad = Instance.new("UIPadding")
        pad.PaddingTop = UDim.new(0, 10)
        pad.PaddingBottom = UDim.new(0, 12)
        pad.PaddingLeft = UDim.new(0, 12)
        pad.PaddingRight = UDim.new(0, 12)
        pad.Parent = tabScroll

        -- Left Column
        local leftCol = Instance.new("Frame")
        leftCol.Name = "LeftColumn"
        leftCol.Size = UDim2.new(0.5, -6, 0, 0)
        leftCol.Position = UDim2.new(0, 0, 0, 0)
        leftCol.BackgroundTransparency = 1
        leftCol.Parent = tabScroll

        local leftLayout = Instance.new("UIListLayout")
        leftLayout.SortOrder = Enum.SortOrder.LayoutOrder
        leftLayout.Padding = UDim.new(0, 10)
        leftLayout.Parent = leftCol

        -- Right Column
        local rightCol = Instance.new("Frame")
        rightCol.Name = "RightColumn"
        rightCol.Size = UDim2.new(0.5, -6, 0, 0)
        rightCol.Position = UDim2.new(0.5, 6, 0, 0)
        rightCol.BackgroundTransparency = 1
        rightCol.Parent = tabScroll

        local rightLayout = Instance.new("UIListLayout")
        rightLayout.SortOrder = Enum.SortOrder.LayoutOrder
        rightLayout.Padding = UDim.new(0, 10)
        rightLayout.Parent = rightCol

        local function UpdateCanvas()
            local leftH = leftLayout.AbsoluteContentSize.Y
            local rightH = rightLayout.AbsoluteContentSize.Y
            local maxH = math.max(leftH, rightH) + 30
            tabScroll.CanvasSize = UDim2.new(0, 0, 0, maxH)
            leftCol.Size = UDim2.new(0.5, -6, 0, leftH)
            rightCol.Size = UDim2.new(0.5, 6, 0, rightH)
        end

        leftLayout:GetPropertyChangedSignal("AbsoluteContentSize"):Connect(UpdateCanvas)
        rightLayout:GetPropertyChangedSignal("AbsoluteContentSize"):Connect(UpdateCanvas)

        local function ShowTab()
            for _, t in ipairs(WindowObj.Tabs) do
                t.View.Visible = false
                Library:Tween(t.Button, 0.15, { BackgroundTransparency = 1 })
                Library:Tween(t.Label, 0.15, { TextColor3 = Library.SubTextColor })
                Library:Tween(t.ActiveBar, 0.15, { BackgroundTransparency = 1 })
                if t.Icon then
                    Library:Tween(t.Icon, 0.15, { ImageColor3 = Library.SubTextColor })
                end
            end
            tabScroll.Visible = true
            Library:Tween(tabButton, 0.15, { BackgroundTransparency = 0.25 })
            Library:Tween(tabTitle, 0.15, { TextColor3 = Library.TextColor })
            Library:Tween(activeBar, 0.15, { BackgroundTransparency = 0 })
            if iconImg then
                Library:Tween(iconImg, 0.15, { ImageColor3 = Library.Accent })
            end
            WindowObj.CurrentTab = Tab
            UpdateCanvas()
        end

        tabButton.MouseButton1Click:Connect(ShowTab)

        Tab.View = tabScroll
        Tab.Button = tabButton
        Tab.Label = tabTitle
        Tab.Icon = iconImg
        Tab.ActiveBar = activeBar
        table.insert(WindowObj.Tabs, Tab)

        if #WindowObj.Tabs == 1 then
            ShowTab()
        end

        -- =================================================================
        -- GROUPBOX CONSTRUCTOR (GLASS CARDS)
        -- =================================================================
        local function CreateGroupbox(parentContainer, groupTitle)
            local gb = Instance.new("Frame")
            gb.Name = "Groupbox_" .. groupTitle
            gb.Size = UDim2.new(1, 0, 0, 0)
            gb.BackgroundColor3 = Library.GlassSection
            gb.BackgroundTransparency = 0.35
            gb.BorderSizePixel = 0
            gb.Parent = parentContainer

            local gbCorner = Instance.new("UICorner")
            gbCorner.CornerRadius = UDim.new(0, 6)
            gbCorner.Parent = gb

            local gbStroke = Instance.new("UIStroke")
            gbStroke.Color = Library.GlassBorder
            gbStroke.Thickness = 1
            gbStroke.Transparency = 0.35
            gbStroke.Parent = gb

            local header = Instance.new("Frame")
            header.Name = "Header"
            header.Size = UDim2.new(1, 0, 0, 26)
            header.BackgroundTransparency = 1
            header.Parent = gb

            local gbTitleLabel = Instance.new("TextLabel")
            gbTitleLabel.Size = UDim2.new(1, -20, 1, 0)
            gbTitleLabel.Position = UDim2.new(0, 10, 0, 0)
            gbTitleLabel.BackgroundTransparency = 1
            gbTitleLabel.Font = Library.FontBold
            gbTitleLabel.Text = groupTitle
            gbTitleLabel.TextColor3 = Library.TextColor
            gbTitleLabel.TextSize = 11
            gbTitleLabel.TextXAlignment = Enum.TextXAlignment.Left
            gbTitleLabel.Parent = header

            local line = Instance.new("Frame")
            line.Size = UDim2.new(1, 0, 0, 1)
            line.Position = UDim2.new(0, 0, 0, 26)
            line.BackgroundColor3 = Library.GlassBorderSoft
            line.BorderSizePixel = 0
            line.Parent = gb

            local container = Instance.new("Frame")
            container.Name = "Container"
            container.Size = UDim2.new(1, 0, 0, 0)
            container.Position = UDim2.new(0, 0, 0, 27)
            container.BackgroundTransparency = 1
            container.Parent = gb

            local listLayout = Instance.new("UIListLayout")
            listLayout.SortOrder = Enum.SortOrder.LayoutOrder
            listLayout.Padding = UDim.new(0, 6)
            listLayout.Parent = container

            local listPad = Instance.new("UIPadding")
            listPad.PaddingTop = UDim.new(0, 8)
            listPad.PaddingBottom = UDim.new(0, 8)
            listPad.PaddingLeft = UDim.new(0, 10)
            listPad.PaddingRight = UDim.new(0, 10)
            listPad.Parent = container

            local function UpdateGbHeight()
                local innerH = listLayout.AbsoluteContentSize.Y + 16
                container.Size = UDim2.new(1, 0, 0, innerH)
                gb.Size = UDim2.new(1, 0, 0, innerH + 28)
                UpdateCanvas()
            end

            listLayout:GetPropertyChangedSignal("AbsoluteContentSize"):Connect(UpdateGbHeight)

            local Groupbox = {
                Frame = gb,
                Container = container
            }

            -- =============================================================
            -- 1. TOGGLE (CHAINING: ColorPicker, KeyPicker)
            -- =============================================================
            function Groupbox:AddToggle(id, cfg)
                cfg = cfg or {}
                local text = cfg.Text or id or "Toggle"
                local state = cfg.Default == true
                local callback = cfg.Callback or function() end

                local row = Instance.new("Frame")
                row.Name = "Toggle_" .. tostring(id)
                row.Size = UDim2.new(1, 0, 0, 22)
                row.BackgroundTransparency = 1
                row.Parent = container

                local checkBox = Instance.new("TextButton")
                checkBox.Size = UDim2.new(0, 16, 0, 16)
                checkBox.Position = UDim2.new(0, 0, 0.5, -8)
                checkBox.BackgroundColor3 = state and Library.Accent or Library.GlassElement
                checkBox.BackgroundTransparency = state and 0 or 0.2
                checkBox.BorderSizePixel = 0
                checkBox.Text = ""
                checkBox.AutoButtonColor = false
                checkBox.Parent = row

                local cbCorner = Instance.new("UICorner")
                cbCorner.CornerRadius = UDim.new(0, 4)
                cbCorner.Parent = checkBox

                local cbStroke = Instance.new("UIStroke")
                cbStroke.Color = Library.GlassBorderSoft
                cbStroke.Parent = checkBox

                local titleBtn = Instance.new("TextButton")
                titleBtn.Size = UDim2.new(1, -26, 1, 0)
                titleBtn.Position = UDim2.new(0, 24, 0, 0)
                titleBtn.BackgroundTransparency = 1
                titleBtn.Font = Library.Font
                titleBtn.Text = text
                titleBtn.TextColor3 = state and Library.TextColor or Library.SubTextColor
                titleBtn.TextSize = 12
                titleBtn.TextXAlignment = Enum.TextXAlignment.Left
                titleBtn.AutoButtonColor = false
                titleBtn.Parent = row

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
                    SetValue = function(selfTog, val)
                        selfTog.Value = val == true
                        Library:Tween(checkBox, 0.15, {
                            BackgroundColor3 = selfTog.Value and Library.Accent or Library.GlassElement,
                            BackgroundTransparency = selfTog.Value and 0 or 0.2
                        })
                        Library:Tween(titleBtn, 0.15, {
                            TextColor3 = selfTog.Value and Library.TextColor or Library.SubTextColor
                        })
                        task.spawn(callback, selfTog.Value)
                    end
                }

                local function OnClick()
                    Library:Animate(checkBox, "Pop")
                    ToggleObj:SetValue(not ToggleObj.Value)
                end

                checkBox.MouseButton1Click:Connect(OnClick)
                titleBtn.MouseButton1Click:Connect(OnClick)

                if id then
                    Toggles[id] = ToggleObj
                    Options[id] = ToggleObj
                end

                local ChainWrapper = { Toggle = ToggleObj }

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
                    cStroke.Color = Library.GlassBorder
                    cStroke.Parent = cpBtn

                    local cpPopup = Instance.new("Frame")
                    cpPopup.Name = "Popup"
                    cpPopup.Size = UDim2.new(0, 170, 0, 155)
                    cpPopup.Position = UDim2.new(1, 10, 0, 0)
                    cpPopup.BackgroundColor3 = Library.GlassSection
                    cpPopup.BackgroundTransparency = 0.05
                    cpPopup.BorderSizePixel = 0
                    cpPopup.Visible = false
                    cpPopup.ZIndex = 60
                    cpPopup.Parent = cpBtn

                    local pCorner = Instance.new("UICorner")
                    pCorner.CornerRadius = UDim.new(0, 6)
                    pCorner.Parent = cpPopup

                    local pStroke = Instance.new("UIStroke")
                    pStroke.Color = Library.GlassBorder
                    pStroke.Parent = cpPopup

                    local pTitle = Instance.new("TextLabel")
                    pTitle.Size = UDim2.new(1, -12, 0, 20)
                    pTitle.Position = UDim2.new(0, 8, 0, 4)
                    pTitle.BackgroundTransparency = 1
                    pTitle.Font = Library.FontBold
                    pTitle.Text = cpTitle
                    pTitle.TextColor3 = Library.TextColor
                    pTitle.TextSize = 11
                    pTitle.TextXAlignment = Enum.TextXAlignment.Left
                    pTitle.ZIndex = 61
                    pTitle.Parent = cpPopup

                    local svBox = Instance.new("ImageButton")
                    svBox.Size = UDim2.new(1, -16, 0, 95)
                    svBox.Position = UDim2.new(0, 8, 0, 26)
                    svBox.Image = "rbxassetid://4155801252"
                    svBox.BorderSizePixel = 0
                    svBox.AutoButtonColor = false
                    svBox.ZIndex = 61
                    svBox.Parent = cpPopup

                    local hueBar = Instance.new("ImageButton")
                    hueBar.Size = UDim2.new(1, -16, 0, 12)
                    hueBar.Position = UDim2.new(0, 8, 0, 130)
                    hueBar.Image = "rbxassetid://3641079629"
                    hueBar.BorderSizePixel = 0
                    hueBar.AutoButtonColor = false
                    hueBar.ZIndex = 61
                    hueBar.Parent = cpPopup

                    local curHue, curSat, curVal = cpDef:ToHSV()
                    svBox.BackgroundColor3 = Color3.fromHSV(curHue, 1, 1)

                    local ColorPickerObj = {
                        Value = cpDef,
                        Type = "ColorPicker",
                        SetValue = function(selfCp, color)
                            selfCp.Value = color
                            cpBtn.BackgroundColor3 = color
                            local h, s, v = color:ToHSV()
                            curHue, curSat, curVal = h, s, v
                            svBox.BackgroundColor3 = Color3.fromHSV(curHue, 1, 1)
                            task.spawn(cpCb, color)
                        end
                    }

                    local dragSV, dragHue = false, false
                    svBox.InputBegan:Connect(function(input)
                        if input.UserInputType == Enum.UserInputType.MouseButton1 then dragSV = true end
                    end)
                    hueBar.InputBegan:Connect(function(input)
                        if input.UserInputType == Enum.UserInputType.MouseButton1 then dragHue = true end
                    end)

                    local moveConn = UserInputService.InputChanged:Connect(function(input)
                        if input.UserInputType == Enum.UserInputType.MouseMovement then
                            if dragSV then
                                local rx = math.clamp((input.Position.X - svBox.AbsolutePosition.X) / svBox.AbsoluteSize.X, 0, 1)
                                local ry = math.clamp((input.Position.Y - svBox.AbsolutePosition.Y) / svBox.AbsoluteSize.Y, 0, 1)
                                curSat = rx
                                curVal = 1 - ry
                                ColorPickerObj:SetValue(Color3.fromHSV(curHue, curSat, curVal))
                            elseif dragHue then
                                local rx = math.clamp((input.Position.X - hueBar.AbsolutePosition.X) / hueBar.AbsoluteSize.X, 0, 1)
                                curHue = rx
                                ColorPickerObj:SetValue(Color3.fromHSV(curHue, curSat, curVal))
                            end
                        end
                    end)
                    table.insert(Library.Connections, moveConn)

                    local endConn = UserInputService.InputEnded:Connect(function(input)
                        if input.UserInputType == Enum.UserInputType.MouseButton1 then
                            dragSV = false
                            dragHue = false
                        end
                    end)
                    table.insert(Library.Connections, endConn)

                    cpBtn.MouseButton1Click:Connect(function()
                        cpPopup.Visible = not cpPopup.Visible
                    end)

                    if cpId then
                        Options[cpId] = ColorPickerObj
                    end

                    return ChainWrapper
                end

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
                        kpBtn.Size = UDim2.new(0, 44, 0, 16)
                        kpBtn.BackgroundColor3 = Library.GlassElement
                        kpBtn.BackgroundTransparency = 0.2
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
                                local k = ParseKeyInput(input)
                                if k then
                                    if k == Enum.KeyCode.Escape then k = "None" end
                                    KeyPickerObj.Value = k
                                    kpBtn.Text = "[" .. ConvertKeyCodeToString(k) .. "]"
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

            -- =============================================================
            -- 2. SLIDER
            -- =============================================================
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
                row.Size = UDim2.new(1, 0, 0, 38)
                row.BackgroundTransparency = 1
                row.Parent = container

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
                track.BackgroundColor3 = Library.GlassElement
                track.BackgroundTransparency = 0.2
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
                    SetValue = function(selfSld, val)
                        val = math.clamp(val, min, max)
                        val = Round(val, rounding)
                        selfSld.Value = val
                        valLabel.Text = tostring(val) .. suffix
                        local ratio = math.clamp((val - min) / (max - min), 0, 1)
                        Library:Tween(fill, 0.08, { Size = UDim2.new(ratio, 0, 1, 0) })
                        task.spawn(callback, val)
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

            -- =============================================================
            -- 3. DROPDOWN
            -- =============================================================
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
                row.Parent = container

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
                mainBtn.BackgroundColor3 = Library.GlassElement
                mainBtn.BackgroundTransparency = 0.2
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
                bStroke.Color = Library.GlassBorderSoft
                bStroke.Parent = mainBtn

                local arrow = Instance.new("TextLabel")
                arrow.Size = UDim2.new(0, 20, 1, 0)
                arrow.Position = UDim2.new(1, -20, 0, 0)
                arrow.BackgroundTransparency = 1
                arrow.Font = Library.Font
                arrow.Text = "v"
                arrow.TextColor3 = Library.SubTextColor
                arrow.TextSize = 9
                arrow.Parent = mainBtn

                local listFrame = Instance.new("Frame")
                listFrame.Name = "DropList"
                listFrame.Size = UDim2.new(1, 0, 0, 0)
                listFrame.Position = UDim2.new(0, 0, 1, 4)
                listFrame.BackgroundColor3 = Library.GlassSection
                listFrame.BackgroundTransparency = 0.05
                listFrame.BorderSizePixel = 0
                listFrame.Visible = false
                listFrame.ZIndex = 50
                listFrame.ClipsDescendants = true
                listFrame.Parent = mainBtn

                local lCorner = Instance.new("UICorner")
                lCorner.CornerRadius = UDim.new(0, 4)
                lCorner.Parent = listFrame

                local lStroke = Instance.new("UIStroke")
                lStroke.Color = Library.GlassBorder
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
                            optBtn.BackgroundColor3 = Library.GlassSection
                            optBtn.BackgroundTransparency = 0.2
                            optBtn.BorderSizePixel = 0
                            optBtn.Font = Library.Font
                            optBtn.Text = "  " .. tostring(opt)
                            optBtn.TextColor3 = (opt == selfDd.Value) and Library.Accent or Library.TextColor
                            optBtn.TextSize = 11
                            optBtn.TextXAlignment = Enum.TextXAlignment.Left
                            optBtn.ZIndex = 51
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

            -- =============================================================
            -- 4. INPUT (TextBox)
            -- =============================================================
            function Groupbox:AddInput(id, cfg)
                cfg = cfg or {}
                local text = cfg.Text or id or "Input"
                local def = cfg.Default or ""
                local placeholder = cfg.Placeholder or "Enter value..."
                local finishedOnly = cfg.Finished ~= false
                local callback = cfg.Callback or function() end

                local row = Instance.new("Frame")
                row.Name = "Input_" .. tostring(id)
                row.Size = UDim2.new(1, 0, 0, 48)
                row.BackgroundTransparency = 1
                row.Parent = container

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
                textBox.BackgroundColor3 = Library.GlassElement
                textBox.BackgroundTransparency = 0.2
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
                tbStroke.Color = Library.GlassBorderSoft
                tbStroke.Parent = textBox

                local InputObj = {
                    Value = def,
                    Type = "Input",
                    SetValue = function(selfInp, val)
                        selfInp.Value = tostring(val)
                        textBox.Text = selfInp.Value
                        task.spawn(callback, selfInp.Value)
                    end
                }

                if finishedOnly then
                    textBox.FocusLost:Connect(function()
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

            -- =============================================================
            -- 5. BUTTON
            -- =============================================================
            function Groupbox:AddButton(cfg)
                local text = (typeof(cfg) == "table" and cfg.Text) or tostring(cfg) or "Button"
                local callback = (typeof(cfg) == "table" and cfg.Callback) or function() end

                local btn = Instance.new("TextButton")
                btn.Name = "Btn_" .. text
                btn.Size = UDim2.new(1, 0, 0, 26)
                btn.BackgroundColor3 = Library.GlassElement
                btn.BackgroundTransparency = 0.2
                btn.BorderSizePixel = 0
                btn.Font = Library.Font
                btn.Text = text
                btn.TextColor3 = Library.TextColor
                btn.TextSize = 12
                btn.AutoButtonColor = false
                btn.Parent = container

                local bCorner = Instance.new("UICorner")
                bCorner.CornerRadius = UDim.new(0, 4)
                bCorner.Parent = btn

                local bStroke = Instance.new("UIStroke")
                bStroke.Color = Library.GlassBorderSoft
                bStroke.Parent = btn

                btn.MouseEnter:Connect(function()
                    Library:Tween(btn, 0.12, { BackgroundColor3 = Library.GlassBorder, BackgroundTransparency = 0.1 })
                end)
                btn.MouseLeave:Connect(function()
                    Library:Tween(btn, 0.12, { BackgroundColor3 = Library.GlassElement, BackgroundTransparency = 0.2 })
                end)
                btn.MouseButton1Click:Connect(function()
                    Library:Animate(btn, "Pop")
                    task.spawn(callback)
                end)

                return btn
            end

            -- =============================================================
            -- 6. LABEL (CHAINING: KeyPicker)
            -- =============================================================
            function Groupbox:AddLabel(labelText)
                local row = Instance.new("Frame")
                row.Name = "LabelRow"
                row.Size = UDim2.new(1, 0, 0, 20)
                row.BackgroundTransparency = 1
                row.Parent = container

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

                local LabelChain = { Label = lbl }

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
                        kpBtn.Size = UDim2.new(0, 44, 0, 16)
                        kpBtn.BackgroundColor3 = Library.GlassElement
                        kpBtn.BackgroundTransparency = 0.2
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
                                local k = ParseKeyInput(input)
                                if k then
                                    if k == Enum.KeyCode.Escape then k = "None" end
                                    KeyPickerObj.Value = k
                                    kpBtn.Text = "[" .. ConvertKeyCodeToString(k) .. "]"
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
            local gb = CreateGroupbox(leftCol, title)
            table.insert(Tab.LeftGroupboxes, gb)
            return gb
        end

        function Tab:AddRightGroupbox(title)
            local gb = CreateGroupbox(rightCol, title)
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
    writefile(path, HttpService:JSONEncode(data))
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
        Text = "Config Presets",
        Values = configList,
        Default = selectedConfig,
        Callback = function(val)
            selectedConfig = val
        end
    })

    local configNameInput = gb:AddInput("SaveManager_ConfigName", {
        Text = "Create New Config",
        Default = "",
        Placeholder = "config_name",
        Finished = true
    })

    gb:AddButton({
        Text = "Save Config",
        Callback = function()
            local name = configNameInput.Value
            if name == "" then name = "default" end
            self:Save(name)
            configDropdown:SetValues(self:RefreshConfigs())
        end
    })

    gb:AddButton({
        Text = "Load Config",
        Callback = function()
            if selectedConfig ~= "" then
                self:Load(selectedConfig)
            end
        end
    })

    gb:AddButton({
        Text = "Overwrite Current",
        Callback = function()
            if selectedConfig ~= "" then
                self:Save(selectedConfig)
            end
        end
    })

    gb:AddButton({
        Text = "Delete Config",
        Callback = function()
            if selectedConfig ~= "" then
                self:Delete(selectedConfig)
                configDropdown:SetValues(self:RefreshConfigs())
            end
        end
    })

    gb:AddButton({
        Text = "Set As Auto-Load",
        Callback = function()
            if selectedConfig ~= "" and writefile then
                SafeMakeFolder(self.Folder)
                writefile(self.Folder .. "/" .. self.AutoloadFile, selectedConfig)
                self.Library:Notify("Autoload set to: " .. selectedConfig, 3)
            end
        end
    })

    gb:AddButton({
        Text = "Refresh Presets",
        Callback = function()
            configDropdown:SetValues(self:RefreshConfigs())
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
    local gb = tab:AddLeftGroupbox("Theme & Styling")

    local themeNames = {}
    for name, _ in pairs(self.BuiltInThemes) do
        table.insert(themeNames, name)
    end

    gb:AddDropdown("ThemeManager_Presets", {
        Text = "Color Accent Presets",
        Values = themeNames,
        Default = "Ruby Rose",
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
        Text = "Enable Custom Accent",
        Default = false
    })

    accentToggle:AddColorPicker("ThemeManager_CustomAccent", {
        Default = self.Library.Accent,
        Title = "Accent Tint",
        Callback = function(color)
            self.Library.Accent = color
        end
    })

    gb:AddLabel("Unload Library Hook"):AddKeyPicker("UnloadMenuKey", {
        Default = "End",
        Mode = "Toggle",
        Text = "Unload UI",
        Callback = function()
            self.Library:Unload()
        end
    })
end

Library.SaveManager = SaveManager
Library.ThemeManager = ThemeManager

return Library
