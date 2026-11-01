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

local Options = {}
local Toggles = {}

_G.Options = Options
_G.Toggles = Toggles
if getgenv then
    getgenv().Options = Options
    getgenv().Toggles = Toggles
end

local Fonts = {
    ["Gotham"] = Enum.Font.GothamMedium,
    ["GothamBold"] = Enum.Font.GothamBold,
    ["Fredoka"] = Enum.Font.FredokaOne,
    ["Nunito"] = Enum.Font.Nunito,
    ["Ubuntu"] = Enum.Font.Ubuntu,
    ["SourceSans"] = Enum.Font.SourceSansSemibold,
    ["Roboto"] = Enum.Font.Roboto,
    ["Montserrat"] = Enum.Font.Montserrat,
    ["JosefinSans"] = Enum.Font.JosefinSans,
    ["Sarpanch"] = Enum.Font.Sarpanch
}

local FontKeys = {
    "Gotham",
    "GothamBold",
    "Fredoka",
    "Nunito",
    "Ubuntu",
    "SourceSans",
    "Roboto",
    "Montserrat",
    "JosefinSans",
    "Sarpanch"
}

local Library = {
    Name = "RubyUI",
    Open = true,
    Accent = Color3.fromRGB(250, 44, 83),
    GlassBg = Color3.fromRGB(15, 16, 22),
    GlassSidebar = Color3.fromRGB(11, 12, 17),
    GlassSection = Color3.fromRGB(20, 22, 30),
    GlassElement = Color3.fromRGB(26, 28, 38),
    SolidPopup = Color3.fromRGB(18, 20, 27),
    GlassBorder = Color3.fromRGB(60, 65, 85),
    GlassBorderSoft = Color3.fromRGB(36, 40, 52),
    TextColor = Color3.fromRGB(245, 245, 250),
    SubTextColor = Color3.fromRGB(140, 144, 165),
    Font = Enum.Font.GothamMedium,
    FontBold = Enum.Font.GothamBold,
    BackgroundImage = "",
    BackgroundTransparency = 0.15,
    ImageTransparency = 0.85,
    UnloadCallbacks = {},
    Connections = {},
    Keybinds = {},
    ScreenGui = nil,
    PopupGui = nil,
    MainWindow = nil,
    NotificationContainer = nil,
    BgImageLabel = nil,
    LucideIcons = {},
    ActivePopup = nil,
    TextObjects = {},
    InstanceColors = {}
}

local function InitLucideAPI()
    local endpoints = {
        "https://raw.githubusercontent.com/latte-soft/lucide-roblox/refs/heads/master/lib/Icons.luau",
        "https://raw.githubusercontent.com/SiriusSoftwareLtd/Rayfield/a2c3063cc1e54db522dac4ab837b0a35a0da5ed0/icons.lua"
    }

    for _, url in ipairs(endpoints) do
        local ok, src = pcall(function()
            if game.HttpGet then
                return game:HttpGet(url, true)
            end
            return nil
        end)

        if ok and type(src) == "string" and #src > 100 then
            local execOk, res = pcall(function()
                return loadstring(src)()
            end)

            if execOk and typeof(res) == "table" then
                local preferred = res["48px"] or res["36px"] or res["24px"] or res
                for name, data in pairs(preferred) do
                    if typeof(data) == "table" and (data[1] or data.id) then
                        local clean = tostring(name):lower():gsub("^lucide%-", ""):gsub("_", "-"):gsub("%s+", "-")
                        Library.LucideIcons[clean] = data
                    end
                end

                for resKey, catList in pairs(res) do
                    if typeof(catList) == "table" then
                        for name, data in pairs(catList) do
                            if typeof(data) == "table" and (data[1] or data.id) then
                                local clean = tostring(name):lower():gsub("^lucide%-", ""):gsub("_", "-"):gsub("%s+", "-")
                                if not Library.LucideIcons[clean] then
                                    Library.LucideIcons[clean] = data
                                end
                            end
                        end
                    end
                end
                break
            end
        end
    end
end

task.spawn(InitLucideAPI)

function Library:ApplyIcon(imageLabel, iconInput)
    if not imageLabel or not iconInput or iconInput == "" then
        if imageLabel then
            imageLabel.Image = ""
            imageLabel.ImageRectSize = Vector2.zero
            imageLabel.ImageRectOffset = Vector2.zero
        end
        return false
    end

    iconInput = tostring(iconInput)

    if iconInput:find("rbxassetid://") or iconInput:find("http://") or iconInput:find("https://") then
        imageLabel.Image = iconInput
        imageLabel.ImageRectSize = Vector2.zero
        imageLabel.ImageRectOffset = Vector2.zero
        return true
    end

    if tonumber(iconInput) then
        imageLabel.Image = "rbxassetid://" .. iconInput
        imageLabel.ImageRectSize = Vector2.zero
        imageLabel.ImageRectOffset = Vector2.zero
        return true
    end

    local cleanName = iconInput:lower():gsub("^lucide%-", ""):gsub("_", "-"):gsub("%s+", "-")
    local iconData = self.LucideIcons[cleanName]

    if iconData and typeof(iconData) == "table" then
        if iconData[1] then
            local assetId = tostring(iconData[1])
            if not assetId:find("rbxassetid://") then
                assetId = "rbxassetid://" .. assetId
            end
            imageLabel.Image = assetId

            local sz = iconData[2]
            local off = iconData[3]

            if typeof(sz) == "table" then
                imageLabel.ImageRectSize = Vector2.new(sz[1], sz[2])
            elseif typeof(sz) == "Vector2" then
                imageLabel.ImageRectSize = sz
            else
                imageLabel.ImageRectSize = Vector2.new(48, 48)
            end

            if typeof(off) == "table" then
                imageLabel.ImageRectOffset = Vector2.new(off[1], off[2])
            elseif typeof(off) == "Vector2" then
                imageLabel.ImageRectOffset = off
            else
                imageLabel.ImageRectOffset = Vector2.zero
            end
            return true
        elseif iconData.id then
            local assetId = tostring(iconData.id)
            if not assetId:find("rbxassetid://") then
                assetId = "rbxassetid://" .. assetId
            end
            imageLabel.Image = assetId
            imageLabel.ImageRectSize = iconData.imageRectSize or Vector2.zero
            imageLabel.ImageRectOffset = iconData.imageRectOffset or Vector2.zero
            return true
        end
    end

    imageLabel.Image = "rbxassetid://10709759764"
    imageLabel.ImageRectSize = Vector2.zero
    imageLabel.ImageRectOffset = Vector2.zero
    return false
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

function Library:RegisterText(label, isBold)
    table.insert(self.TextObjects, { Label = label, IsBold = isBold })
    label.Font = isBold and self.FontBold or self.Font
end

function Library:RegisterColor(instance, property, colorType)
    table.insert(self.InstanceColors, { Instance = instance, Property = property, Type = colorType })
end

function Library:SetFont(newFont)
    self.Font = newFont
    self.FontBold = newFont
    for _, item in ipairs(self.TextObjects) do
        if item.Label and item.Label.Parent then
            item.Label.Font = newFont
        end
    end
end

function Library:UpdateThemeColor(colorType, newColor)
    self[colorType] = newColor
    for _, item in ipairs(self.InstanceColors) do
        if item.Instance and item.Instance.Parent and item.Type == colorType then
            item.Instance[item.Property] = newColor
        end
    end
end

function Library:SetBackgroundImage(url, transparency)
    self.BackgroundImage = url or ""
    self.ImageTransparency = transparency or self.ImageTransparency
    if self.BgImageLabel then
        self.BgImageLabel.Image = self.BackgroundImage
        self.BgImageLabel.ImageTransparency = self.ImageTransparency
        self.BgImageLabel.Visible = self.BackgroundImage ~= ""
    end
end

function Library:CloseActivePopup()
    if self.ActivePopup then
        self.ActivePopup.Visible = false
        self.ActivePopup = nil
    end
end

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
    if input.UserInputType == Enum.UserInputType.MouseButton1 then
        if Library.ActivePopup and Library.ActivePopup.Visible then
            local pos = input.Position
            local pPos = Library.ActivePopup.AbsolutePosition
            local pSize = Library.ActivePopup.AbsoluteSize
            if pos.X < pPos.X or pos.X > pPos.X + pSize.X or pos.Y < pPos.Y or pos.Y > pPos.Y + pSize.Y then
                local opener = Library.ActivePopup:GetAttribute("OpenerBtn")
                local isOverOpener = false
                if opener and typeof(opener) == "Instance" and opener.Parent then
                    local oPos = opener.AbsolutePosition
                    local oSize = opener.AbsoluteSize
                    if pos.X >= oPos.X and pos.X <= oPos.X + oSize.X and pos.Y >= oPos.Y and pos.Y <= oPos.Y + oSize.Y then
                        isOverOpener = true
                    end
                end
                if not isOverOpener then
                    Library:CloseActivePopup()
                end
            end
        end
    end

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

    if self.PopupGui then
        self.PopupGui:Destroy()
        self.PopupGui = nil
    end

    _G.Options = nil
    _G.Toggles = nil
    if getgenv then
        getgenv().Options = nil
        getgenv().Toggles = nil
    end
end

-- Completely fixed notification receiver: handles both Library:Notify({...}) and Library.Notify({...})
function Library.Notify(...)
    local args = table.pack(...)
    local first = args[1]
    local second = args[2]
    local third = args[3]

    local cfg, duration
    if typeof(first) == "table" and first ~= Library and (first.Title or first.Message or first.Content or first.Text or first.Description) then
        cfg = first
        duration = second
    elseif first == Library then
        cfg = second
        duration = third
    else
        cfg = first
        duration = second
    end

    local title = "Notification"
    local message = ""
    local icon = "bell"
    local notifDuration = 3

    if typeof(cfg) == "table" then
        title = cfg.Title or cfg.Header or cfg.Name or "Notification"
        local rawMsg = cfg.Message or cfg.Text or cfg.Content or cfg.Description or cfg.Desc or cfg.Body or cfg[1]
        if typeof(rawMsg) == "table" then
            message = rawMsg.Message or rawMsg.Text or rawMsg.Content or rawMsg[1] or ""
        else
            message = tostring(rawMsg or "")
        end
        notifDuration = cfg.Duration or cfg.Time or duration or notifDuration
        icon = cfg.Icon or cfg.Image or icon
    elseif typeof(cfg) == "string" then
        if typeof(duration) == "string" then
            title = cfg
            message = duration
            notifDuration = third or notifDuration
        else
            message = cfg
            notifDuration = duration or notifDuration
        end
    else
        message = tostring(cfg or "")
        notifDuration = duration or notifDuration
    end

    message = tostring(message)
    title = tostring(title)

    if not Library.NotificationContainer then return end

    local slotFrame = Instance.new("Frame")
    slotFrame.Name = "ToastSlot"
    slotFrame.Size = UDim2.new(1, 0, 0, 56)
    slotFrame.BackgroundTransparency = 1
    slotFrame.ClipsDescendants = false
    slotFrame.Parent = Library.NotificationContainer

    local notifFrame = Instance.new("Frame")
    notifFrame.Name = "Toast"
    notifFrame.Size = UDim2.new(1, 0, 1, 0)
    notifFrame.Position = UDim2.new(1, 40, 0, 0)
    notifFrame.BackgroundColor3 = Library.SolidPopup
    notifFrame.BackgroundTransparency = 0
    notifFrame.BorderSizePixel = 0
    notifFrame.ClipsDescendants = true
    notifFrame.Parent = slotFrame

    local corner = Instance.new("UICorner")
    corner.CornerRadius = UDim.new(0, 8)
    corner.Parent = notifFrame

    local stroke = Instance.new("UIStroke")
    stroke.Color = Library.GlassBorder
    stroke.Thickness = 1.2
    stroke.Transparency = 0.2
    stroke.Parent = notifFrame

    local accentBar = Instance.new("Frame")
    accentBar.Size = UDim2.new(0, 4, 1, 0)
    accentBar.Position = UDim2.new(0, 0, 0, 0)
    accentBar.BackgroundColor3 = Library.Accent
    accentBar.BorderSizePixel = 0
    accentBar.Parent = notifFrame

    local iconLabel = Instance.new("ImageLabel")
    iconLabel.Size = UDim2.new(0, 22, 0, 22)
    iconLabel.Position = UDim2.new(0, 14, 0.5, -11)
    iconLabel.BackgroundTransparency = 1
    iconLabel.ImageColor3 = Library.Accent
    iconLabel.Parent = notifFrame

    local hasIcon = Library:ApplyIcon(iconLabel, icon)
    iconLabel.Visible = hasIcon

    local textOffsetX = hasIcon and 44 or 16

    local titleLabel = Instance.new("TextLabel")
    titleLabel.Size = UDim2.new(1, -(textOffsetX + 12), 0, 18)
    titleLabel.Position = UDim2.new(0, textOffsetX, 0, 8)
    titleLabel.BackgroundTransparency = 1
    titleLabel.Font = Library.FontBold
    titleLabel.Text = title
    titleLabel.TextColor3 = Library.TextColor
    titleLabel.TextSize = 13
    titleLabel.TextXAlignment = Enum.TextXAlignment.Left
    titleLabel.TextTruncate = Enum.TextTruncate.AtEnd
    titleLabel.Parent = notifFrame

    local textLabel = Instance.new("TextLabel")
    textLabel.Size = UDim2.new(1, -(textOffsetX + 12), 0, 18)
    textLabel.Position = UDim2.new(0, textOffsetX, 0, 27)
    textLabel.BackgroundTransparency = 1
    textLabel.Font = Library.Font
    textLabel.Text = message
    textLabel.TextColor3 = Library.SubTextColor
    textLabel.TextSize = 11
    textLabel.TextXAlignment = Enum.TextXAlignment.Left
    textLabel.TextTruncate = Enum.TextTruncate.AtEnd
    textLabel.Parent = notifFrame

    local progressBar = Instance.new("Frame")
    progressBar.Size = UDim2.new(1, 0, 0, 2)
    progressBar.Position = UDim2.new(0, 0, 1, -2)
    progressBar.BackgroundColor3 = Library.Accent
    progressBar.BorderSizePixel = 0
    progressBar.Parent = notifFrame

    Library:RegisterText(titleLabel, true)
    Library:RegisterText(textLabel, false)
    Library:RegisterColor(notifFrame, "BackgroundColor3", "SolidPopup")
    Library:RegisterColor(stroke, "Color", "GlassBorder")
    Library:RegisterColor(accentBar, "BackgroundColor3", "Accent")
    Library:RegisterColor(iconLabel, "ImageColor3", "Accent")
    Library:RegisterColor(titleLabel, "TextColor3", "TextColor")
    Library:RegisterColor(textLabel, "TextColor3", "SubTextColor")
    Library:RegisterColor(progressBar, "BackgroundColor3", "Accent")

    Library:Tween(notifFrame, 0.35, { Position = UDim2.new(0, 0, 0, 0) }, Enum.EasingStyle.Back, Enum.EasingDirection.Out)
    Library:Tween(progressBar, notifDuration, { Size = UDim2.new(0, 0, 0, 2) }, Enum.EasingStyle.Linear)

    task.delay(notifDuration, function()
        if not slotFrame.Parent then return end
        Library:Tween(notifFrame, 0.25, { Position = UDim2.new(1, 40, 0, 0) }, Enum.EasingStyle.Quad, Enum.EasingDirection.In)
        task.wait(0.26)
        if not slotFrame.Parent then return end
        Library:Tween(slotFrame, 0.15, { Size = UDim2.new(1, 0, 0, 0) }, Enum.EasingStyle.Quad, Enum.EasingDirection.Out)
        task.wait(0.16)
        slotFrame:Destroy()
    end)
end

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
    KeyFrame.BackgroundColor3 = self.SolidPopup
    KeyFrame.BackgroundTransparency = 0
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

    Library:RegisterText(kTitle, true)
    Library:RegisterText(kSub, false)
    Library:RegisterText(inputField, false)
    Library:RegisterText(verifyBtn, true)
    Library:RegisterText(discordBtn, false)

    discordBtn.MouseButton1Click:Connect(function()
        if setclipboard then
            setclipboard(DiscordUrl)
            Library:Notify({ Title = "Clipboard", Message = "Discord link copied to clipboard!", Duration = 2.5, Icon = "check-circle" })
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

function Library:CreateWindow(config)
    config = config or {}
    local TitleText = config.Title or "EXTERNAL V2"
    local SubTitleText = config.SubTitle or "UNIVERSAL"
    local FooterText = config.Footer or "Build 2026.11"
    local Center = config.Center ~= false
    local AutoShow = config.AutoShow ~= false
    local bgUrl = config.BackgroundImage or config.Background or ""
    local bgTransp = config.ImageTransparency or self.ImageTransparency

    local ScreenGui = Instance.new("ScreenGui")
    ScreenGui.Name = "RubyWindowGui"
    ScreenGui.ResetOnSpawn = false
    ScreenGui.ZIndexBehavior = Enum.ZIndexBehavior.Sibling
    ScreenGui.DisplayOrder = 1000
    ScreenGui.Parent = GetSafeGuiParent()
    self.ScreenGui = ScreenGui

    local PopupGui = Instance.new("ScreenGui")
    PopupGui.Name = "RubyPopupOverlayGui"
    PopupGui.ResetOnSpawn = false
    PopupGui.ZIndexBehavior = Enum.ZIndexBehavior.Sibling
    PopupGui.DisplayOrder = 2000
    PopupGui.Parent = GetSafeGuiParent()
    self.PopupGui = PopupGui

    local notifContainer = Instance.new("Frame")
    notifContainer.Name = "NotificationStack"
    notifContainer.Size = UDim2.new(0, 310, 1, -40)
    notifContainer.Position = UDim2.new(1, -326, 0, 20)
    notifContainer.BackgroundTransparency = 1
    notifContainer.Parent = ScreenGui

    local notifLayout = Instance.new("UIListLayout")
    notifLayout.SortOrder = Enum.SortOrder.LayoutOrder
    notifLayout.VerticalAlignment = Enum.VerticalAlignment.Bottom
    notifLayout.Padding = UDim.new(0, 8)
    notifLayout.Parent = notifContainer
    self.NotificationContainer = notifContainer

    local MainWindow = Instance.new("Frame")
    MainWindow.Name = "RubyMainWindow"
    MainWindow.Size = UDim2.new(0, 720, 0, 490)
    if Center then
        MainWindow.Position = UDim2.new(0.5, -360, 0.5, -245)
    else
        MainWindow.Position = UDim2.new(0, 100, 0, 100)
    end
    MainWindow.BackgroundColor3 = self.GlassBg
    MainWindow.BackgroundTransparency = self.BackgroundTransparency
    MainWindow.BorderSizePixel = 0
    MainWindow.Visible = AutoShow
    MainWindow.ClipsDescendants = true
    MainWindow.Parent = ScreenGui
    self.MainWindow = MainWindow

    Library:RegisterColor(MainWindow, "BackgroundColor3", "GlassBg")

    local bgImageLabel = Instance.new("ImageLabel")
    bgImageLabel.Name = "CustomBackground"
    bgImageLabel.Size = UDim2.new(1, 0, 1, 0)
    bgImageLabel.Position = UDim2.new(0, 0, 0, 0)
    bgImageLabel.BackgroundTransparency = 1
    bgImageLabel.Image = bgUrl
    bgImageLabel.ImageTransparency = bgTransp
    bgImageLabel.ScaleType = Enum.ScaleType.Crop
    bgImageLabel.Visible = bgUrl ~= ""
    bgImageLabel.ZIndex = 0
    bgImageLabel.Parent = MainWindow
    self.BgImageLabel = bgImageLabel

    local mainCorner = Instance.new("UICorner")
    mainCorner.CornerRadius = UDim.new(0, 8)
    mainCorner.Parent = MainWindow

    local mainStroke = Instance.new("UIStroke")
    mainStroke.Color = self.GlassBorder
    mainStroke.Thickness = 1.2
    mainStroke.Transparency = 0.25
    mainStroke.Parent = MainWindow

    Library:RegisterColor(mainStroke, "Color", "GlassBorder")

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
            Library:CloseActivePopup()
        end
    end)
    table.insert(self.Connections, dragMoveConn)

    local topAccent = Instance.new("Frame")
    topAccent.Size = UDim2.new(1, 0, 0, 2)
    topAccent.BackgroundColor3 = self.Accent
    topAccent.BorderSizePixel = 0
    topAccent.Parent = MainWindow

    Library:RegisterColor(topAccent, "BackgroundColor3", "Accent")

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

    Library:RegisterText(titleLabel, true)
    Library:RegisterText(subTitleLabel, false)
    Library:RegisterColor(titleLabel, "TextColor3", "TextColor")
    Library:RegisterColor(subTitleLabel, "TextColor3", "SubTextColor")

    titleLabel:GetPropertyChangedSignal("TextBounds"):Connect(function()
        subTitleLabel.Position = UDim2.new(0, 16 + titleLabel.TextBounds.X + 8, 0, 0)
    end)

    local headerLine = Instance.new("Frame")
    headerLine.Size = UDim2.new(1, 0, 0, 1)
    headerLine.Position = UDim2.new(0, 0, 0, 44)
    headerLine.BackgroundColor3 = self.GlassBorderSoft
    headerLine.BorderSizePixel = 0
    headerLine.Parent = MainWindow

    Library:RegisterColor(headerLine, "BackgroundColor3", "GlassBorderSoft")

    local sidebar = Instance.new("Frame")
    sidebar.Name = "Sidebar"
    sidebar.Size = UDim2.new(0, 150, 1, -72)
    sidebar.Position = UDim2.new(0, 0, 0, 45)
    sidebar.BackgroundColor3 = self.GlassSidebar
    sidebar.BackgroundTransparency = 0.25
    sidebar.BorderSizePixel = 0
    sidebar.ClipsDescendants = true
    sidebar.Parent = MainWindow

    Library:RegisterColor(sidebar, "BackgroundColor3", "GlassSidebar")

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

    Library:RegisterColor(sidebarDivider, "BackgroundColor3", "GlassBorderSoft")

    local tabContainer = Instance.new("Frame")
    tabContainer.Name = "TabViews"
    tabContainer.Size = UDim2.new(1, -151, 1, -72)
    tabContainer.Position = UDim2.new(0, 151, 0, 45)
    tabContainer.BackgroundTransparency = 1
    tabContainer.ClipsDescendants = true
    tabContainer.Parent = MainWindow

    local footerLine = Instance.new("Frame")
    footerLine.Size = UDim2.new(1, 0, 0, 1)
    footerLine.Position = UDim2.new(0, 0, 1, -27)
    footerLine.BackgroundColor3 = self.GlassBorderSoft
    footerLine.BorderSizePixel = 0
    footerLine.Parent = MainWindow

    Library:RegisterColor(footerLine, "BackgroundColor3", "GlassBorderSoft")

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

    Library:RegisterText(footerLabel, false)
    Library:RegisterColor(footerLabel, "TextColor3", "SubTextColor")

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
            Library:Tween(MainWindow, 0.25, { Size = UDim2.new(0, 720, 0, 490) }, Enum.EasingStyle.Back, Enum.EasingDirection.Out)
        else
            Library:CloseActivePopup()
            Library:Tween(MainWindow, 0.2, { Size = UDim2.new(0, 680, 0, 460) }, Enum.EasingStyle.Quad, Enum.EasingDirection.In)
            task.delay(0.2, function()
                if not self.Open then
                    MainWindow.Visible = false
                end
            end)
        end
    end

    function WindowObj:AddTab(tabName, iconInput)
        local Tab = {
            Name = tabName,
            LeftGroupboxes = {},
            RightGroupboxes = {},
        }

        local tabButton = Instance.new("TextButton")
        tabButton.Name = "TabBtn_" .. tabName
        tabButton.Size = UDim2.new(1, 0, 0, 32)
        tabButton.BackgroundColor3 = Library.GlassSection
        tabButton.BackgroundTransparency = 1
        tabButton.AutoButtonColor = false
        tabButton.Text = ""
        tabButton.Parent = sidebarScroll

        Library:RegisterColor(tabButton, "BackgroundColor3", "GlassSection")

        local btnCorner = Instance.new("UICorner")
        btnCorner.CornerRadius = UDim.new(0, 6)
        btnCorner.Parent = tabButton

        local iconImg = Instance.new("ImageLabel")
        iconImg.Size = UDim2.new(0, 16, 0, 16)
        iconImg.Position = UDim2.new(0, 8, 0.5, -8)
        iconImg.BackgroundTransparency = 1
        iconImg.ImageColor3 = Library.SubTextColor
        iconImg.Parent = tabButton

        local hasIcon = Library:ApplyIcon(iconImg, iconInput)
        iconImg.Visible = hasIcon

        local tabTitle = Instance.new("TextLabel")
        tabTitle.Size = UDim2.new(1, hasIcon and -34 or -16, 1, 0)
        tabTitle.Position = UDim2.new(0, hasIcon and 32 or 12, 0, 0)
        tabTitle.BackgroundTransparency = 1
        tabTitle.Font = Library.Font
        tabTitle.Text = tabName
        tabTitle.TextColor3 = Library.SubTextColor
        tabTitle.TextSize = 12
        tabTitle.TextXAlignment = Enum.TextXAlignment.Left
        tabTitle.Parent = tabButton

        Library:RegisterText(tabTitle, false)

        local activeBar = Instance.new("Frame")
        activeBar.Size = UDim2.new(0, 3, 0, 16)
        activeBar.Position = UDim2.new(0, 1, 0.5, -8)
        activeBar.BackgroundColor3 = Library.Accent
        activeBar.BorderSizePixel = 0
        activeBar.BackgroundTransparency = 1
        activeBar.Parent = tabButton

        Library:RegisterColor(activeBar, "BackgroundColor3", "Accent")

        local abCorner = Instance.new("UICorner")
        abCorner.CornerRadius = UDim.new(0, 2)
        abCorner.Parent = activeBar

        local tabScroll = Instance.new("ScrollingFrame")
        tabScroll.Name = "Scroll_" .. tabName
        tabScroll.Size = UDim2.new(1, 0, 1, 0)
        tabScroll.Position = UDim2.new(0, 16, 0, 0)
        tabScroll.BackgroundTransparency = 1
        tabScroll.BorderSizePixel = 0
        tabScroll.ScrollBarThickness = 3
        tabScroll.ScrollBarImageColor3 = Library.GlassBorder
        tabScroll.Visible = false
        tabScroll.CanvasSize = UDim2.new(0, 0, 0, 0)
        tabScroll.Parent = tabContainer

        Library:RegisterColor(tabScroll, "ScrollBarImageColor3", "GlassBorder")

        tabScroll:GetPropertyChangedSignal("CanvasPosition"):Connect(function()
            Library:CloseActivePopup()
        end)

        local pad = Instance.new("UIPadding")
        pad.PaddingTop = UDim.new(0, 10)
        pad.PaddingBottom = UDim.new(0, 12)
        pad.PaddingLeft = UDim.new(0, 12)
        pad.PaddingRight = UDim.new(0, 12)
        pad.Parent = tabScroll

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
            Library:CloseActivePopup()
            for _, t in ipairs(WindowObj.Tabs) do
                if t ~= Tab and t.View.Visible then
                    local oldView = t.View
                    Library:Tween(oldView, 0.15, { Position = UDim2.new(0, -16, 0, 0) }, Enum.EasingStyle.Quad, Enum.EasingDirection.Out)
                    task.delay(0.15, function()
                        oldView.Visible = false
                        oldView.Position = UDim2.new(0, 16, 0, 0)
                    end)
                end
                Library:Tween(t.Button, 0.15, { BackgroundTransparency = 1 })
                Library:Tween(t.Label, 0.15, { TextColor3 = Library.SubTextColor })
                Library:Tween(t.ActiveBar, 0.15, { BackgroundTransparency = 1 })
                if t.Icon and t.Icon.Visible then
                    Library:Tween(t.Icon, 0.15, { ImageColor3 = Library.SubTextColor })
                end
            end

            tabScroll.Position = UDim2.new(0, 16, 0, 0)
            tabScroll.Visible = true
            Library:Tween(tabScroll, 0.25, { Position = UDim2.new(0, 0, 0, 0) }, Enum.EasingStyle.Quad, Enum.EasingDirection.Out)

            Library:Tween(tabButton, 0.15, { BackgroundTransparency = 0.25 })
            Library:Tween(tabTitle, 0.15, { TextColor3 = Library.TextColor })
            Library:Tween(activeBar, 0.15, { BackgroundTransparency = 0 })
            if iconImg.Visible then
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

        local function CreateGroupbox(parentContainer, groupTitle)
            local gb = Instance.new("Frame")
            gb.Name = "Groupbox_" .. groupTitle
            gb.Size = UDim2.new(1, 0, 0, 0)
            gb.BackgroundColor3 = Library.GlassSection
            gb.BackgroundTransparency = 0.35
            gb.BorderSizePixel = 0
            gb.Parent = parentContainer

            Library:RegisterColor(gb, "BackgroundColor3", "GlassSection")

            local gbCorner = Instance.new("UICorner")
            gbCorner.CornerRadius = UDim.new(0, 6)
            gbCorner.Parent = gb

            local gbStroke = Instance.new("UIStroke")
            gbStroke.Color = Library.GlassBorder
            gbStroke.Thickness = 1
            gbStroke.Transparency = 0.35
            gbStroke.Parent = gb

            Library:RegisterColor(gbStroke, "Color", "GlassBorder")

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

            Library:RegisterText(gbTitleLabel, true)
            Library:RegisterColor(gbTitleLabel, "TextColor3", "TextColor")

            local line = Instance.new("Frame")
            line.Size = UDim2.new(1, 0, 0, 1)
            line.Position = UDim2.new(0, 0, 0, 26)
            line.BackgroundColor3 = Library.GlassBorderSoft
            line.BorderSizePixel = 0
            line.Parent = gb

            Library:RegisterColor(line, "BackgroundColor3", "GlassBorderSoft")

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

                Library:RegisterColor(cbStroke, "Color", "GlassBorderSoft")

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

                Library:RegisterText(titleBtn, false)

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

                    Library:RegisterColor(cStroke, "Color", "GlassBorder")

                    local cpPopup = Instance.new("Frame")
                    cpPopup.Name = "ColorPopup_" .. tostring(cpId)
                    cpPopup.Size = UDim2.new(0, 170, 0, 155)
                    cpPopup.BackgroundColor3 = Library.SolidPopup
                    cpPopup.BackgroundTransparency = 0
                    cpPopup.BorderSizePixel = 0
                    cpPopup.Visible = false
                    cpPopup.Parent = Library.PopupGui

                    cpPopup:SetAttribute("OpenerBtn", cpBtn)
                    Library:RegisterColor(cpPopup, "BackgroundColor3", "SolidPopup")

                    local pCorner = Instance.new("UICorner")
                    pCorner.CornerRadius = UDim.new(0, 6)
                    pCorner.Parent = cpPopup

                    local pStroke = Instance.new("UIStroke")
                    pStroke.Color = Library.GlassBorder
                    pStroke.Parent = cpPopup

                    Library:RegisterColor(pStroke, "Color", "GlassBorder")

                    local pTitle = Instance.new("TextLabel")
                    pTitle.Size = UDim2.new(1, -12, 0, 20)
                    pTitle.Position = UDim2.new(0, 8, 0, 4)
                    pTitle.BackgroundTransparency = 1
                    pTitle.Font = Library.FontBold
                    pTitle.Text = cpTitle
                    pTitle.TextColor3 = Library.TextColor
                    pTitle.TextSize = 11
                    pTitle.TextXAlignment = Enum.TextXAlignment.Left
                    pTitle.Parent = cpPopup

                    Library:RegisterText(pTitle, true)
                    Library:RegisterColor(pTitle, "TextColor3", "TextColor")

                    local svBox = Instance.new("ImageButton")
                    svBox.Size = UDim2.new(1, -16, 0, 95)
                    svBox.Position = UDim2.new(0, 8, 0, 26)
                    svBox.Image = "rbxassetid://4155801252"
                    svBox.BorderSizePixel = 0
                    svBox.AutoButtonColor = false
                    svBox.Parent = cpPopup

                    local hueBar = Instance.new("ImageButton")
                    hueBar.Size = UDim2.new(1, -16, 0, 12)
                    hueBar.Position = UDim2.new(0, 8, 0, 130)
                    hueBar.Image = "rbxassetid://3641079629"
                    hueBar.BorderSizePixel = 0
                    hueBar.AutoButtonColor = false
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
                        if cpPopup.Visible then
                            Library:CloseActivePopup()
                        else
                            Library:CloseActivePopup()
                            local absPos = cpBtn.AbsolutePosition
                            cpPopup.Position = UDim2.new(0, absPos.X + cpBtn.AbsoluteSize.X + 8, 0, absPos.Y)
                            cpPopup.Visible = true
                            Library.ActivePopup = cpPopup
                        end
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
                            if selfKp.Button then
                                selfKp.Button.Text = "[" .. ConvertKeyCodeToString(key) .. "]"
                            end
                        end
                    }

                    if not noUi then
                        local kpBtn = Instance.new("TextButton")
                        kpBtn.Name = "KeyBtn_" .. tostring(kpId)
                        kpBtn.Size = UDim2.new(0, 48, 0, 16)
                        kpBtn.BackgroundColor3 = Library.GlassElement
                        kpBtn.BackgroundTransparency = 0.2
                        kpBtn.BorderSizePixel = 0
                        kpBtn.Font = Library.Font
                        kpBtn.Text = "[" .. ConvertKeyCodeToString(kpDef) .. "]"
                        kpBtn.TextColor3 = Library.SubTextColor
                        kpBtn.TextSize = 10
                        kpBtn.TextTruncate = Enum.TextTruncate.AtEnd
                        kpBtn.ClipsDescendants = true
                        kpBtn.AutoButtonColor = false
                        kpBtn.Parent = addonsContainer

                        local kpCorner = Instance.new("UICorner")
                        kpCorner.CornerRadius = UDim.new(0, 3)
                        kpCorner.Parent = kpBtn

                        Library:RegisterText(kpBtn, false)
                        Library:RegisterColor(kpBtn, "BackgroundColor3", "GlassElement")

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

                Library:RegisterText(titleLabel, false)
                Library:RegisterText(valLabel, false)
                Library:RegisterColor(titleLabel, "TextColor3", "TextColor")
                Library:RegisterColor(valLabel, "TextColor3", "SubTextColor")

                local track = Instance.new("TextButton")
                track.Size = UDim2.new(1, 0, 0, 8)
                track.Position = UDim2.new(0, 0, 0, 22)
                track.BackgroundColor3 = Library.GlassElement
                track.BackgroundTransparency = 0.2
                track.BorderSizePixel = 0
                track.Text = ""
                track.AutoButtonColor = false
                track.Parent = row

                Library:RegisterColor(track, "BackgroundColor3", "GlassElement")

                local tCorner = Instance.new("UICorner")
                tCorner.CornerRadius = UDim.new(0, 4)
                tCorner.Parent = track

                local fill = Instance.new("Frame")
                fill.Size = UDim2.new(math.clamp((def - min) / (max - min), 0, 1), 0, 1, 0)
                fill.BackgroundColor3 = Library.Accent
                fill.BorderSizePixel = 0
                fill.Parent = track

                Library:RegisterColor(fill, "BackgroundColor3", "Accent")

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

                Library:RegisterText(titleLabel, false)
                Library:RegisterColor(titleLabel, "TextColor3", "TextColor")

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

                Library:RegisterText(mainBtn, false)
                Library:RegisterColor(mainBtn, "BackgroundColor3", "GlassElement")
                Library:RegisterColor(mainBtn, "TextColor3", "TextColor")

                local bCorner = Instance.new("UICorner")
                bCorner.CornerRadius = UDim.new(0, 4)
                bCorner.Parent = mainBtn

                local bStroke = Instance.new("UIStroke")
                bStroke.Color = Library.GlassBorderSoft
                bStroke.Parent = mainBtn

                Library:RegisterColor(bStroke, "Color", "GlassBorderSoft")

                local arrow = Instance.new("TextLabel")
                arrow.Size = UDim2.new(0, 20, 1, 0)
                arrow.Position = UDim2.new(1, -20, 0, 0)
                arrow.BackgroundTransparency = 1
                arrow.Font = Library.Font
                arrow.Text = "v"
                arrow.TextColor3 = Library.SubTextColor
                arrow.TextSize = 9
                arrow.Parent = mainBtn

                Library:RegisterText(arrow, false)
                Library:RegisterColor(arrow, "TextColor3", "SubTextColor")

                local listFrame = Instance.new("Frame")
                listFrame.Name = "DropdownOverlayList_" .. tostring(id)
                listFrame.Size = UDim2.new(0, 100, 0, 0)
                listFrame.BackgroundColor3 = Library.SolidPopup
                listFrame.BackgroundTransparency = 0
                listFrame.BorderSizePixel = 0
                listFrame.Visible = false
                listFrame.ClipsDescendants = true
                listFrame.Parent = Library.PopupGui

                listFrame:SetAttribute("OpenerBtn", mainBtn)
                Library:RegisterColor(listFrame, "BackgroundColor3", "SolidPopup")

                local lCorner = Instance.new("UICorner")
                lCorner.CornerRadius = UDim.new(0, 4)
                lCorner.Parent = listFrame

                local lStroke = Instance.new("UIStroke")
                lStroke.Color = Library.GlassBorder
                lStroke.Parent = listFrame

                Library:RegisterColor(lStroke, "Color", "GlassBorder")

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
                        listFrame.Size = UDim2.new(0, mainBtn.AbsoluteSize.X, 0, #newVals * 22)
                        for _, opt in ipairs(newVals) do
                            local optBtn = Instance.new("TextButton")
                            optBtn.Size = UDim2.new(1, 0, 0, 22)
                            optBtn.BackgroundColor3 = Library.SolidPopup
                            optBtn.BackgroundTransparency = 0
                            optBtn.BorderSizePixel = 0
                            optBtn.Font = Library.Font
                            optBtn.Text = "  " .. tostring(opt)
                            optBtn.TextColor3 = (opt == selfDd.Value) and Library.Accent or Library.TextColor
                            optBtn.TextSize = 11
                            optBtn.TextXAlignment = Enum.TextXAlignment.Left
                            optBtn.AutoButtonColor = false
                            optBtn.Parent = listFrame

                            Library:RegisterText(optBtn, false)
                            Library:RegisterColor(optBtn, "BackgroundColor3", "SolidPopup")

                            optBtn.MouseEnter:Connect(function()
                                optBtn.BackgroundColor3 = Library.GlassElement
                            end)
                            optBtn.MouseLeave:Connect(function()
                                optBtn.BackgroundColor3 = Library.SolidPopup
                            end)

                            optBtn.MouseButton1Click:Connect(function()
                                selfDd:SetValue(opt)
                                Library:CloseActivePopup()
                                arrow.Text = "v"
                            end)
                        end
                    end
                }

                DropdownObj:SetValues(values)

                mainBtn.MouseButton1Click:Connect(function()
                    if listFrame.Visible then
                        Library:CloseActivePopup()
                        arrow.Text = "v"
                    else
                        Library:CloseActivePopup()
                        local absPos = mainBtn.AbsolutePosition
                        listFrame.Position = UDim2.new(0, absPos.X, 0, absPos.Y + mainBtn.AbsoluteSize.Y + 4)
                        listFrame.Size = UDim2.new(0, mainBtn.AbsoluteSize.X, 0, #DropdownObj.Values * 22)
                        listFrame.Visible = true
                        Library.ActivePopup = listFrame
                        arrow.Text = "^"
                    end
                end)

                if id then
                    Options[id] = DropdownObj
                end

                return DropdownObj
            end

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

                Library:RegisterText(titleLabel, false)
                Library:RegisterColor(titleLabel, "TextColor3", "TextColor")

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

                Library:RegisterText(textBox, false)
                Library:RegisterColor(textBox, "BackgroundColor3", "GlassElement")
                Library:RegisterColor(textBox, "TextColor3", "TextColor")
                Library:RegisterColor(textBox, "PlaceholderColor3", "SubTextColor")

                local tbCorner = Instance.new("UICorner")
                tbCorner.CornerRadius = UDim.new(0, 4)
                tbCorner.Parent = textBox

                local tbStroke = Instance.new("UIStroke")
                tbStroke.Color = Library.GlassBorderSoft
                tbStroke.Parent = textBox

                Library:RegisterColor(tbStroke, "Color", "GlassBorderSoft")

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

                Library:RegisterText(btn, false)
                Library:RegisterColor(btn, "BackgroundColor3", "GlassElement")
                Library:RegisterColor(btn, "TextColor3", "TextColor")

                local bCorner = Instance.new("UICorner")
                bCorner.CornerRadius = UDim.new(0, 4)
                bCorner.Parent = btn

                local bStroke = Instance.new("UIStroke")
                bStroke.Color = Library.GlassBorderSoft
                bStroke.Parent = btn

                Library:RegisterColor(bStroke, "Color", "GlassBorderSoft")

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

                Library:RegisterText(lbl, false)
                Library:RegisterColor(lbl, "TextColor3", "SubTextColor")

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
                            if selfKp.Button then
                                selfKp.Button.Text = "[" .. ConvertKeyCodeToString(key) .. "]"
                            end
                        end
                    }

                    if not noUi then
                        local kpBtn = Instance.new("TextButton")
                        kpBtn.Name = "KeyBtn_" .. tostring(kpId)
                        kpBtn.Size = UDim2.new(0, 48, 0, 16)
                        kpBtn.BackgroundColor3 = Library.GlassElement
                        kpBtn.BackgroundTransparency = 0.2
                        kpBtn.BorderSizePixel = 0
                        kpBtn.Font = Library.Font
                        kpBtn.Text = "[" .. ConvertKeyCodeToString(kpDef) .. "]"
                        kpBtn.TextColor3 = Library.SubTextColor
                        kpBtn.TextSize = 10
                        kpBtn.TextTruncate = Enum.TextTruncate.AtEnd
                        kpBtn.ClipsDescendants = true
                        kpBtn.AutoButtonColor = false
                        kpBtn.Parent = addonsContainer

                        local kpCorner = Instance.new("UICorner")
                        kpCorner.CornerRadius = UDim.new(0, 3)
                        kpCorner.Parent = kpBtn

                        Library:RegisterText(kpBtn, false)
                        Library:RegisterColor(kpBtn, "BackgroundColor3", "GlassElement")

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
    self.Library:Notify({ Title = "Configuration", Message = "Config saved: " .. name, Duration = 3, Icon = "save" })
end

function SaveManager:Load(name)
    if not (readfile and isfile) then return end
    local path = self.Folder .. "/" .. name .. ".json"
    if not isfile(path) then
        self.Library:Notify({ Title = "Configuration", Message = "Config not found: " .. name, Duration = 3, Icon = "alert-triangle" })
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

    self.Library:Notify({ Title = "Configuration", Message = "Config loaded: " .. name, Duration = 3, Icon = "folder" })
end

function SaveManager:Delete(name)
    if not (delfile and isfile) then return end
    local path = self.Folder .. "/" .. name .. ".json"
    if isfile(path) then
        delfile(path)
        self.Library:Notify({ Title = "Configuration", Message = "Config deleted: " .. name, Duration = 3, Icon = "trash" })
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
                self.Library:Notify({ Title = "Configuration", Message = "Autoload set to: " .. selectedConfig, Duration = 3, Icon = "save" })
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
                self.Library:UpdateThemeColor("Accent", col)
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
            self.Library:UpdateThemeColor("Accent", color)
        end
    })

    local bgToggle = gb:AddToggle("ThemeManager_BgColorToggle", {
        Text = "Custom Background Color",
        Default = false
    })

    bgToggle:AddColorPicker("ThemeManager_CustomBg", {
        Default = self.Library.GlassBg,
        Title = "Background Color",
        Callback = function(color)
            self.Library:UpdateThemeColor("GlassBg", color)
        end
    })

    local borderToggle = gb:AddToggle("ThemeManager_BorderColorToggle", {
        Text = "Custom Border Color",
        Default = false
    })

    borderToggle:AddColorPicker("ThemeManager_CustomBorder", {
        Default = self.Library.GlassBorder,
        Title = "Border Color",
        Callback = function(color)
            self.Library:UpdateThemeColor("GlassBorder", color)
        end
    })

    local textToggle = gb:AddToggle("ThemeManager_TextColorToggle", {
        Text = "Custom Text Color",
        Default = false
    })

    textToggle:AddColorPicker("ThemeManager_CustomText", {
        Default = self.Library.TextColor,
        Title = "Text Color",
        Callback = function(color)
            self.Library:UpdateThemeColor("TextColor", color)
        end
    })

    gb:AddInput("ThemeManager_CustomBgImage", {
        Text = "Background Image URL / Asset",
        Default = self.Library.BackgroundImage,
        Placeholder = "rbxassetid:// or url...",
        Finished = true,
        Callback = function(url)
            self.Library:SetBackgroundImage(url, self.Library.ImageTransparency)
        end
    })

    gb:AddSlider("ThemeManager_BgImageTransparency", {
        Text = "Background Image Transparency",
        Default = math.floor(self.Library.ImageTransparency * 100),
        Min = 0,
        Max = 100,
        Rounding = 0,
        Suffix = "%",
        Callback = function(val)
            self.Library:SetBackgroundImage(self.Library.BackgroundImage, val / 100)
        end
    })

    gb:AddDropdown("ThemeManager_FontSelector", {
        Text = "Interface Typography Font",
        Values = FontKeys,
        Default = "Gotham",
        Callback = function(fontName)
            local targetFont = Fonts[fontName]
            if targetFont then
                self.Library:SetFont(targetFont)
            end
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
