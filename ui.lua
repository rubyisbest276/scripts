local UserInputService = game:GetService("UserInputService")
local TweenService = game:GetService("TweenService")
local RunService = game:GetService("RunService")
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
    AccentSecondary = Color3.fromRGB(255, 115, 140),
    AccentDeep = Color3.fromRGB(185, 18, 65),
    GlassBg = Color3.fromRGB(14, 15, 22),
    GlassSidebar = Color3.fromRGB(10, 11, 17),
    SidebarItemBg = Color3.fromRGB(28, 31, 46),
    SidebarTextColor = Color3.fromRGB(185, 190, 215),
    GlassSection = Color3.fromRGB(20, 22, 32),
    GlassElement = Color3.fromRGB(28, 31, 45),
    GlassElementHover = Color3.fromRGB(36, 40, 58),
    SolidPopup = Color3.fromRGB(18, 20, 30),
    GlassBorder = Color3.fromRGB(75, 82, 110),
    GlassBorderSoft = Color3.fromRGB(45, 50, 70),
    GlassHighlight = Color3.fromRGB(255, 255, 255),
    TextColor = Color3.fromRGB(245, 247, 255),
    SubTextColor = Color3.fromRGB(145, 152, 178),
    Font = Enum.Font.GothamMedium,
    FontBold = Enum.Font.GothamBold,
    BackgroundImage = "",
    BackgroundTransparency = 0.14,
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
    ActivePopupCloseCallback = nil,
    TextObjects = {},
    InstanceColors = {},
    AccentGradients = {},
    ActiveTweens = setmetatable({}, { __mode = "k" }),
    TweenInfoCache = {}
}

local function DeriveAccentShades(baseColor)
    local h, s, v = baseColor:ToHSV()
    local secondary = Color3.fromHSV((h + 0.03) % 1, math.clamp(s * 0.75, 0, 1), math.clamp(v * 1.08, 0, 1))
    local deep = Color3.fromHSV((h - 0.02) % 1, math.clamp(s * 1.05, 0, 1), math.clamp(v * 0.72, 0, 1))
    return secondary, deep
end

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

                for _, catList in pairs(res) do
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
        ["Cyber Cyan"] = Color3.fromRGB(0, 225, 255),
        ["Emerald Glow"] = Color3.fromRGB(46, 213, 115),
        ["Solar Amber"] = Color3.fromRGB(255, 165, 2),
        ["Sakura Pink"] = Color3.fromRGB(255, 105, 180),
        ["Crimson Blood"] = Color3.fromRGB(220, 20, 60),
        ["Minimalist Snow"] = Color3.fromRGB(235, 240, 255),
    }
}

-- Optimized Tween with TweenInfo caching
function Library:Tween(object, time, properties, style, direction)
    if not object then return nil end
    time = time or 0.2
    style = style or Enum.EasingStyle.Quart
    direction = direction or Enum.EasingDirection.Out

    local cacheKey = tostring(time) .. "_" .. tostring(style.Value) .. "_" .. tostring(direction.Value)
    local info = self.TweenInfoCache[cacheKey]
    if not info then
        info = TweenInfo.new(time, style, direction)
        self.TweenInfoCache[cacheKey] = info
    end

    local anim = TweenService:Create(object, info, properties)
    self.ActiveTweens[object] = anim
    anim:Play()
    return anim
end

-- Interactive Ripple Effect on Click
function Library:CreateRipple(parent, mousePos, color)
    if not parent then return end
    task.spawn(function()
        local rippleHolder = parent:FindFirstChild("_RippleHolder")
        if not rippleHolder then
            rippleHolder = Instance.new("Frame")
            rippleHolder.Name = "_RippleHolder"
            rippleHolder.Size = UDim2.new(1, 0, 1, 0)
            rippleHolder.BackgroundTransparency = 1
            rippleHolder.ClipsDescendants = true
            rippleHolder.ZIndex = parent.ZIndex + 1
            rippleHolder.Parent = parent

            local parentCorner = parent:FindFirstChildOfClass("UICorner")
            if parentCorner then
                local rc = Instance.new("UICorner")
                rc.CornerRadius = parentCorner.CornerRadius
                rc.Parent = rippleHolder
            end
        end

        local absPos = parent.AbsolutePosition
        local absSize = parent.AbsoluteSize
        local relX = mousePos and (mousePos.X - absPos.X) or (absSize.X * 0.5)
        local relY = mousePos and (mousePos.Y - absPos.Y) or (absSize.Y * 0.5)

        local maxDiameter = math.max(absSize.X, absSize.Y) * 2.4

        local ripple = Instance.new("Frame")
        ripple.Name = "Ripple"
        ripple.AnchorPoint = Vector2.new(0.5, 0.5)
        ripple.Position = UDim2.new(0, relX, 0, relY)
        ripple.Size = UDim2.new(0, 0, 0, 0)
        ripple.BackgroundColor3 = color or Library.TextColor
        ripple.BackgroundTransparency = 0.72
        ripple.BorderSizePixel = 0
        ripple.ZIndex = rippleHolder.ZIndex + 1
        ripple.Parent = rippleHolder

        local corner = Instance.new("UICorner")
        corner.CornerRadius = UDim.new(1, 0)
        corner.Parent = ripple

        Library:Tween(ripple, 0.45, {
            Size = UDim2.new(0, maxDiameter, 0, maxDiameter),
            BackgroundTransparency = 1
        }, Enum.EasingStyle.Quart, Enum.EasingDirection.Out)

        task.wait(0.46)
        if ripple and ripple.Parent then
            ripple:Destroy()
        end
    end)
end

function Library:Animate(object, animType, baseSize)
    if not object then return end
    if animType == "Pop" then
        local targetSize = baseSize or object.Size
        object.Size = targetSize - UDim2.new(0, 4, 0, 2)
        Library:Tween(object, 0.22, { Size = targetSize }, Enum.EasingStyle.Back, Enum.EasingDirection.Out)
    elseif animType == "Pulse" then
        local originalColor = object.BackgroundColor3
        Library:Tween(object, 0.12, { BackgroundColor3 = Library.Accent })
        task.delay(0.14, function()
            if object and object.Parent then
                Library:Tween(object, 0.25, { BackgroundColor3 = originalColor })
            end
        end)
    end
end

-- Adds a soft 9-slice drop shadow behind any GuiObject with safe ZIndex handling
function Library:AddShadow(parent, cfg)
    cfg = cfg or {}
    local shadow = Instance.new("ImageLabel")
    shadow.Name = "Shadow"
    shadow.BackgroundTransparency = 1
    shadow.Image = "rbxassetid://5028857084"
    shadow.ImageColor3 = cfg.Color or Color3.fromRGB(0, 0, 0)
    shadow.ImageTransparency = cfg.Transparency or 0.48
    shadow.ScaleType = Enum.ScaleType.Slice
    shadow.SliceCenter = Rect.new(24, 24, 276, 276)
    shadow.Size = UDim2.new(1, cfg.Spread or 34, 1, cfg.Spread or 34)
    shadow.Position = UDim2.new(0.5, 0, 0.5, (cfg.YOffset or 4))
    shadow.AnchorPoint = Vector2.new(0.5, 0.5)
    shadow.ZIndex = math.max(0, (cfg.ZIndex or (parent.ZIndex - 1)))
    shadow.Parent = parent
    return shadow
end

-- Adds realistic Frosted Glass specular shine & top reflection line
function Library:AddGlassSurface(parent, cfg)
    cfg = cfg or {}
    local holder = Instance.new("Frame")
    holder.Name = "GlassSurface"
    holder.Size = UDim2.new(1, 0, 1, 0)
    holder.BackgroundColor3 = Color3.fromRGB(255, 255, 255)
    holder.BackgroundTransparency = cfg.ShineTransparency or 0.94
    holder.BorderSizePixel = 0
    holder.ZIndex = parent.ZIndex
    holder.Active = false
    holder.Parent = parent

    local pCorner = parent:FindFirstChildOfClass("UICorner")
    if pCorner then
        local c = Instance.new("UICorner")
        c.CornerRadius = pCorner.CornerRadius
        c.Parent = holder
    end

    local grad = Instance.new("UIGradient")
    grad.Rotation = cfg.Rotation or 135
    grad.Color = ColorSequence.new({
        ColorSequenceKeypoint.new(0, Color3.fromRGB(255, 255, 255)),
        ColorSequenceKeypoint.new(0.45, Color3.fromRGB(200, 210, 255)),
        ColorSequenceKeypoint.new(1, Color3.fromRGB(120, 130, 170))
    })
    grad.Transparency = NumberSequence.new({
        NumberSequenceKeypoint.new(0, 0.15),
        NumberSequenceKeypoint.new(0.4, 0.75),
        NumberSequenceKeypoint.new(1, 1)
    })
    grad.Parent = holder

    if cfg.TopEdge ~= false then
        local topReflection = Instance.new("Frame")
        topReflection.Name = "TopEdgeHighlight"
        topReflection.Size = UDim2.new(1, -16, 0, 1)
        topReflection.Position = UDim2.new(0, 8, 0, 0)
        topReflection.BackgroundColor3 = Color3.fromRGB(255, 255, 255)
        topReflection.BackgroundTransparency = cfg.EdgeTransparency or 0.72
        topReflection.BorderSizePixel = 0
        topReflection.ZIndex = parent.ZIndex + 1
        topReflection.Active = false
        topReflection.Parent = holder

        local edgeGrad = Instance.new("UIGradient")
        edgeGrad.Transparency = NumberSequence.new({
            NumberSequenceKeypoint.new(0, 1),
            NumberSequenceKeypoint.new(0.2, 0),
            NumberSequenceKeypoint.new(0.8, 0),
            NumberSequenceKeypoint.new(1, 1)
        })
        edgeGrad.Parent = topReflection
    end

    return holder
end

function Library:ApplyGradient(instance, colors, rotation, isAccentBound)
    local seq = {}
    local count = #colors
    for i, c in ipairs(colors) do
        local t = (count == 1) and 0 or (i - 1) / (count - 1)
        table.insert(seq, ColorSequenceKeypoint.new(t, c))
    end
    local grad = Instance.new("UIGradient")
    grad.Color = ColorSequence.new(seq)
    grad.Rotation = rotation or 90
    grad.Parent = instance

    if isAccentBound then
        table.insert(self.AccentGradients, { Gradient = grad, Count = count })
    end
    return grad
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

function Library:CleanRegistries()
    for i = #self.TextObjects, 1, -1 do
        local item = self.TextObjects[i]
        if not item.Label or not item.Label.Parent then
            table.remove(self.TextObjects, i)
        end
    end
    for i = #self.InstanceColors, 1, -1 do
        local item = self.InstanceColors[i]
        if not item.Instance or not item.Instance.Parent then
            table.remove(self.InstanceColors, i)
        end
    end
    for i = #self.AccentGradients, 1, -1 do
        local item = self.AccentGradients[i]
        if not item.Gradient or not item.Gradient.Parent then
            table.remove(self.AccentGradients, i)
        end
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
    self:CleanRegistries()
    for _, item in ipairs(self.TextObjects) do
        if item.Label and item.Label.Parent then
            item.Label.Font = newFont
        end
    end
end

function Library:UpdateThemeColor(colorType, newColor)
    self[colorType] = newColor
    if colorType == "Accent" then
        local sec, deep = DeriveAccentShades(newColor)
        self.AccentSecondary = sec
        self.AccentDeep = deep

        for _, gItem in ipairs(self.AccentGradients) do
            if gItem.Gradient and gItem.Gradient.Parent then
                if gItem.Count == 2 then
                    gItem.Gradient.Color = ColorSequence.new({
                        ColorSequenceKeypoint.new(0, self.AccentDeep),
                        ColorSequenceKeypoint.new(1, self.Accent)
                    })
                else
                    gItem.Gradient.Color = ColorSequence.new({
                        ColorSequenceKeypoint.new(0, self.AccentDeep),
                        ColorSequenceKeypoint.new(0.5, self.Accent),
                        ColorSequenceKeypoint.new(1, self.AccentSecondary)
                    })
                end
            end
        end
    end

    self:CleanRegistries()
    for _, item in ipairs(self.InstanceColors) do
        if item.Instance and item.Instance.Parent and item.Type == colorType then
            Library:Tween(item.Instance, 0.2, { [item.Property] = newColor })
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
        local popup = self.ActivePopup
        local closeCb = self.ActivePopupCloseCallback
        self.ActivePopup = nil
        self.ActivePopupCloseCallback = nil

        if closeCb then
            pcall(closeCb)
        else
            popup.Visible = false
        end
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
                local opener = Library.ActivePopup.OpenerBtn
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
    slotFrame.Size = UDim2.new(1, 0, 0, 58)
    slotFrame.BackgroundTransparency = 1
    slotFrame.ClipsDescendants = false
    slotFrame.Parent = Library.NotificationContainer

    local notifWrapper = Instance.new("Frame")
    notifWrapper.Name = "ToastWrapper"
    notifWrapper.Size = UDim2.new(1, 0, 1, 0)
    notifWrapper.Position = UDim2.new(1, 50, 0, 0)
    notifWrapper.BackgroundTransparency = 1
    notifWrapper.ZIndex = 10
    notifWrapper.Parent = slotFrame

    Library:AddShadow(notifWrapper, { Transparency = 0.42, Spread = 28, YOffset = 4, ZIndex = 9 })

    local notifFrame = Instance.new("Frame")
    notifFrame.Name = "Toast"
    notifFrame.Size = UDim2.new(1, 0, 1, 0)
    notifFrame.BackgroundColor3 = Library.SolidPopup
    notifFrame.BackgroundTransparency = 0.08
    notifFrame.BorderSizePixel = 0
    notifFrame.ClipsDescendants = true
    notifFrame.ZIndex = 10
    notifFrame.Parent = notifWrapper

    local corner = Instance.new("UICorner")
    corner.CornerRadius = UDim.new(0, 10)
    corner.Parent = notifFrame

    local stroke = Instance.new("UIStroke")
    stroke.Color = Library.GlassBorder
    stroke.Thickness = 1.2
    stroke.Transparency = 0.25
    stroke.Parent = notifFrame

    Library:AddGlassSurface(notifFrame, { ShineTransparency = 0.93, EdgeTransparency = 0.65 })

    local accentBar = Instance.new("Frame")
    accentBar.Size = UDim2.new(0, 4, 1, 0)
    accentBar.Position = UDim2.new(0, 0, 0, 0)
    accentBar.BackgroundColor3 = Library.Accent
    accentBar.BorderSizePixel = 0
    accentBar.ZIndex = 12
    accentBar.Parent = notifFrame

    Library:ApplyGradient(accentBar, { Library.AccentDeep, Library.Accent, Library.AccentSecondary }, 90, true)

    local iconBg = Instance.new("Frame")
    iconBg.Size = UDim2.new(0, 30, 0, 30)
    iconBg.Position = UDim2.new(0, 13, 0.5, -15)
    iconBg.BackgroundColor3 = Library.Accent
    iconBg.BackgroundTransparency = 0.86
    iconBg.BorderSizePixel = 0
    iconBg.ZIndex = 11
    iconBg.Parent = notifFrame

    local ibCorner = Instance.new("UICorner")
    ibCorner.CornerRadius = UDim.new(0, 8)
    ibCorner.Parent = iconBg

    local iconLabel = Instance.new("ImageLabel")
    iconLabel.Size = UDim2.new(0, 18, 0, 18)
    iconLabel.Position = UDim2.new(0.5, -9, 0.5, -9)
    iconLabel.BackgroundTransparency = 1
    iconLabel.ImageColor3 = Library.Accent
    iconLabel.ZIndex = 12
    iconLabel.Parent = iconBg

    local hasIcon = Library:ApplyIcon(iconLabel, icon)
    iconBg.Visible = hasIcon

    local textOffsetX = hasIcon and 52 or 16

    local titleLabel = Instance.new("TextLabel")
    titleLabel.Size = UDim2.new(1, -(textOffsetX + 12), 0, 18)
    titleLabel.Position = UDim2.new(0, textOffsetX, 0, 9)
    titleLabel.BackgroundTransparency = 1
    titleLabel.Font = Library.FontBold
    titleLabel.Text = title
    titleLabel.TextColor3 = Library.TextColor
    titleLabel.TextSize = 13
    titleLabel.TextXAlignment = Enum.TextXAlignment.Left
    titleLabel.TextTruncate = Enum.TextTruncate.AtEnd
    titleLabel.ZIndex = 12
    titleLabel.Parent = notifFrame

    local textLabel = Instance.new("TextLabel")
    textLabel.Size = UDim2.new(1, -(textOffsetX + 12), 0, 18)
    textLabel.Position = UDim2.new(0, textOffsetX, 0, 28)
    textLabel.BackgroundTransparency = 1
    textLabel.Font = Library.Font
    textLabel.Text = message
    textLabel.TextColor3 = Library.SubTextColor
    textLabel.TextSize = 11
    textLabel.TextXAlignment = Enum.TextXAlignment.Left
    textLabel.TextTruncate = Enum.TextTruncate.AtEnd
    textLabel.ZIndex = 12
    textLabel.Parent = notifFrame

    local progressBar = Instance.new("Frame")
    progressBar.Size = UDim2.new(1, 0, 0, 2)
    progressBar.Position = UDim2.new(0, 0, 1, -2)
    progressBar.BackgroundColor3 = Library.Accent
    progressBar.BorderSizePixel = 0
    progressBar.ZIndex = 13
    progressBar.Parent = notifFrame

    Library:Tween(notifWrapper, 0.4, { Position = UDim2.new(0, 0, 0, 0) }, Enum.EasingStyle.Back, Enum.EasingDirection.Out)
    Library:Tween(progressBar, notifDuration, { Size = UDim2.new(0, 0, 0, 2) }, Enum.EasingStyle.Linear)

    task.delay(notifDuration, function()
        if not slotFrame.Parent then return end
        Library:Tween(notifWrapper, 0.28, { Position = UDim2.new(1, 60, 0, 0) }, Enum.EasingStyle.Back, Enum.EasingDirection.In)
        task.wait(0.28)
        if not slotFrame.Parent then return end
        Library:Tween(slotFrame, 0.18, { Size = UDim2.new(1, 0, 0, 0) }, Enum.EasingStyle.Quart, Enum.EasingDirection.Out)
        task.wait(0.18)
        if slotFrame and slotFrame.Parent then
            slotFrame:Destroy()
        end
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

    local KeyWrapper = Instance.new("Frame")
    KeyWrapper.Name = "KeyModalWrapper"
    KeyWrapper.Size = UDim2.new(0, 360, 0, 220)
    KeyWrapper.Position = UDim2.new(0.5, 0, 0.5, 0)
    KeyWrapper.AnchorPoint = Vector2.new(0.5, 0.5)
    KeyWrapper.BackgroundTransparency = 1
    KeyWrapper.ZIndex = 10
    KeyWrapper.Parent = ScreenGui

    local keyScale = Instance.new("UIScale")
    keyScale.Scale = 0.85
    keyScale.Parent = KeyWrapper
    Library:Tween(keyScale, 0.35, { Scale = 1 }, Enum.EasingStyle.Back, Enum.EasingDirection.Out)

    Library:AddShadow(KeyWrapper, { Transparency = 0.35, Spread = 60, YOffset = 10, ZIndex = 9 })

    local KeyFrame = Instance.new("Frame")
    KeyFrame.Name = "KeyModal"
    KeyFrame.Size = UDim2.new(1, 0, 1, 0)
    KeyFrame.BackgroundColor3 = self.SolidPopup
    KeyFrame.BackgroundTransparency = 0.08
    KeyFrame.BorderSizePixel = 0
    KeyFrame.ClipsDescendants = true
    KeyFrame.ZIndex = 10
    KeyFrame.Parent = KeyWrapper

    local corner = Instance.new("UICorner")
    corner.CornerRadius = UDim.new(0, 14)
    corner.Parent = KeyFrame

    local stroke = Instance.new("UIStroke")
    stroke.Color = self.GlassBorder
    stroke.Thickness = 1.2
    stroke.Transparency = 0.2
    stroke.Parent = KeyFrame

    Library:AddGlassSurface(KeyFrame, { ShineTransparency = 0.92, EdgeTransparency = 0.6 })

    local isDrag, dragStart, startPos
    KeyFrame.InputBegan:Connect(function(input)
        if input.UserInputType == Enum.UserInputType.MouseButton1 then
            isDrag = true
            dragStart = input.Position
            startPos = KeyWrapper.Position
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
            KeyWrapper.Position = UDim2.new(startPos.X.Scale, startPos.X.Offset + delta.X, startPos.Y.Scale, startPos.Y.Offset + delta.Y)
        end
    end)
    table.insert(self.Connections, dragMv)

    local topGlow = Instance.new("Frame")
    topGlow.Size = UDim2.new(1, 0, 0, 3)
    topGlow.BackgroundColor3 = self.Accent
    topGlow.BorderSizePixel = 0
    topGlow.ZIndex = 12
    topGlow.Parent = KeyFrame

    Library:ApplyGradient(topGlow, { self.AccentDeep, self.Accent, self.AccentSecondary }, 0, true)

    local kTitle = Instance.new("TextLabel")
    kTitle.Size = UDim2.new(1, -24, 0, 30)
    kTitle.Position = UDim2.new(0, 16, 0, 14)
    kTitle.BackgroundTransparency = 1
    kTitle.Font = self.FontBold
    kTitle.Text = Title
    kTitle.TextColor3 = self.TextColor
    kTitle.TextSize = 15
    kTitle.TextXAlignment = Enum.TextXAlignment.Left
    kTitle.ZIndex = 12
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
    kSub.ZIndex = 12
    kSub.Parent = KeyFrame

    local inputField = Instance.new("TextBox")
    inputField.Size = UDim2.new(1, -32, 0, 36)
    inputField.Position = UDim2.new(0, 16, 0, 76)
    inputField.BackgroundColor3 = self.GlassElement
    inputField.BackgroundTransparency = 0.25
    inputField.BorderSizePixel = 0
    inputField.Font = self.Font
    inputField.PlaceholderText = "Paste License Key..."
    inputField.PlaceholderColor3 = self.SubTextColor
    inputField.Text = ""
    inputField.TextColor3 = self.TextColor
    inputField.TextSize = 12
    inputField.ClearTextOnFocus = false
    inputField.ZIndex = 12
    inputField.Parent = KeyFrame

    local inputCorner = Instance.new("UICorner")
    inputCorner.CornerRadius = UDim.new(0, 8)
    inputCorner.Parent = inputField

    local inputStroke = Instance.new("UIStroke")
    inputStroke.Color = self.GlassBorderSoft
    inputStroke.Transparency = 0.25
    inputStroke.Parent = inputField

    inputField.Focused:Connect(function()
        Library:Tween(inputStroke, 0.2, { Color = Library.Accent, Transparency = 0 })
        Library:Tween(inputField, 0.2, { BackgroundTransparency = 0.1 })
    end)
    inputField.FocusLost:Connect(function()
        Library:Tween(inputStroke, 0.2, { Color = Library.GlassBorderSoft, Transparency = 0.25 })
        Library:Tween(inputField, 0.2, { BackgroundTransparency = 0.25 })
    end)

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
    verifyBtn.ZIndex = 12
    verifyBtn.Parent = KeyFrame

    local vCorner = Instance.new("UICorner")
    vCorner.CornerRadius = UDim.new(0, 8)
    vCorner.Parent = verifyBtn

    Library:ApplyGradient(verifyBtn, { self.AccentDeep, self.Accent, self.AccentSecondary }, 0, true)

    local discordBtn = Instance.new("TextButton")
    discordBtn.Size = UDim2.new(1, -32, 0, 24)
    discordBtn.Position = UDim2.new(0, 16, 0, 164)
    discordBtn.BackgroundTransparency = 1
    discordBtn.Font = self.Font
    discordBtn.Text = "Get key via Discord link (Click to copy)"
    discordBtn.TextColor3 = self.SubTextColor
    discordBtn.TextSize = 11
    discordBtn.ZIndex = 12
    discordBtn.Parent = KeyFrame

    discordBtn.MouseEnter:Connect(function()
        Library:Tween(discordBtn, 0.15, { TextColor3 = Library.TextColor })
    end)
    discordBtn.MouseLeave:Connect(function()
        Library:Tween(discordBtn, 0.15, { TextColor3 = Library.SubTextColor })
    end)

    discordBtn.MouseButton1Click:Connect(function()
        if setclipboard then
            setclipboard(DiscordUrl)
            Library:Notify({ Title = "Clipboard", Message = "Discord link copied to clipboard!", Duration = 2.5, Icon = "check-circle" })
        end
    end)

    verifyBtn.MouseButton1Click:Connect(function()
        Library:CreateRipple(verifyBtn, UserInputService:GetMouseLocation())
        if inputField.Text == TargetKey then
            verifyBtn.Text = "ACCESS GRANTED"
            Library:Tween(verifyBtn, 0.2, { BackgroundColor3 = Color3.fromRGB(46, 213, 115) })
            task.wait(0.45)
            Library:Tween(keyScale, 0.25, { Scale = 0.85 }, Enum.EasingStyle.Back, Enum.EasingDirection.In)
            Library:Tween(KeyFrame, 0.25, { BackgroundTransparency = 1 })
            task.wait(0.26)
            KeyWrapper:Destroy()
            OnSuccess()
        else
            verifyBtn.Text = "INVALID KEY"
            Library:Tween(verifyBtn, 0.15, { BackgroundColor3 = Color3.fromRGB(220, 45, 55) })
            local origPos = KeyWrapper.Position
            for i = 1, 4 do
                KeyWrapper.Position = origPos + UDim2.new(0, (i % 2 == 0 and 6 or -6), 0, 0)
                task.wait(0.04)
            end
            KeyWrapper.Position = origPos
            task.delay(1, function()
                if verifyBtn and verifyBtn.Parent then
                    verifyBtn.Text = "AUTHENTICATE"
                    Library:Tween(verifyBtn, 0.2, { BackgroundColor3 = Library.Accent })
                end
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

    -- Outer wrapper holds drop shadow so MainWindow can clip descendants cleanly
    local WindowHolder = Instance.new("Frame")
    WindowHolder.Name = "RubyWindowHolder"
    WindowHolder.Size = UDim2.new(0, 720, 0, 490)
    WindowHolder.AnchorPoint = Vector2.new(0.5, 0.5)
    if Center then
        WindowHolder.Position = UDim2.new(0.5, 0, 0.5, 0)
    else
        WindowHolder.Position = UDim2.new(0, 460, 0, 345)
    end
    WindowHolder.BackgroundTransparency = 1
    WindowHolder.Visible = AutoShow
    WindowHolder.ZIndex = 2
    WindowHolder.Parent = ScreenGui

    local windowScale = Instance.new("UIScale")
    windowScale.Scale = AutoShow and 0.92 or 0.88
    windowScale.Parent = WindowHolder
    if AutoShow then
        Library:Tween(windowScale, 0.35, { Scale = 1 }, Enum.EasingStyle.Back, Enum.EasingDirection.Out)
    end

    Library:AddShadow(WindowHolder, { Transparency = 0.38, Spread = 64, YOffset = 12, ZIndex = 1 })

    local MainWindow = Instance.new("Frame")
    MainWindow.Name = "RubyMainWindow"
    MainWindow.Size = UDim2.new(1, 0, 1, 0)
    MainWindow.BackgroundColor3 = self.GlassBg
    MainWindow.BackgroundTransparency = self.BackgroundTransparency
    MainWindow.BorderSizePixel = 0
    MainWindow.ClipsDescendants = true
    MainWindow.ZIndex = 2
    MainWindow.Parent = WindowHolder
    self.MainWindow = MainWindow

    Library:RegisterColor(MainWindow, "BackgroundColor3", "GlassBg")

    local mainCorner = Instance.new("UICorner")
    mainCorner.CornerRadius = UDim.new(0, 14)
    mainCorner.Parent = MainWindow

    local mainStroke = Instance.new("UIStroke")
    mainStroke.Color = self.GlassBorder
    mainStroke.Thickness = 1.3
    mainStroke.Transparency = 0.2
    mainStroke.Parent = MainWindow
    Library:RegisterColor(mainStroke, "Color", "GlassBorder")

    local strokeGrad = Instance.new("UIGradient")
    strokeGrad.Rotation = 135
    strokeGrad.Color = ColorSequence.new({
        ColorSequenceKeypoint.new(0, Color3.fromRGB(255, 255, 255)),
        ColorSequenceKeypoint.new(0.5, Color3.fromRGB(185, 195, 230)),
        ColorSequenceKeypoint.new(1, Color3.fromRGB(110, 120, 160))
    })
    strokeGrad.Transparency = NumberSequence.new({
        NumberSequenceKeypoint.new(0, 0.05),
        NumberSequenceKeypoint.new(0.5, 0.35),
        NumberSequenceKeypoint.new(1, 0.15)
    })
    strokeGrad.Parent = mainStroke

    -- Frosted Glass Diagonal Specular Reflection Overlay
    Library:AddGlassSurface(MainWindow, { ShineTransparency = 0.93, EdgeTransparency = 0.62, Rotation = 130 })

    local bgImageLabel = Instance.new("ImageLabel")
    bgImageLabel.Name = "CustomBackground"
    bgImageLabel.Size = UDim2.new(1, 0, 1, 0)
    bgImageLabel.Position = UDim2.new(0, 0, 0, 0)
    bgImageLabel.BackgroundTransparency = 1
    bgImageLabel.Image = bgUrl
    bgImageLabel.ImageTransparency = bgTransp
    bgImageLabel.ScaleType = Enum.ScaleType.Crop
    bgImageLabel.Visible = bgUrl ~= ""
    bgImageLabel.ZIndex = 2
    bgImageLabel.Parent = MainWindow
    self.BgImageLabel = bgImageLabel

    local bgCorner = Instance.new("UICorner")
    bgCorner.CornerRadius = UDim.new(0, 14)
    bgCorner.Parent = bgImageLabel

    -- Smooth Lerp Dragging System
    local dragging = false
    local dragStart = Vector2.zero
    local startPos = WindowHolder.Position
    local targetWindowPos = WindowHolder.Position

    local titleBar = Instance.new("Frame")
    titleBar.Name = "Header"
    titleBar.Size = UDim2.new(1, 0, 0, 44)
    titleBar.BackgroundTransparency = 1
    titleBar.ZIndex = 5
    titleBar.Parent = MainWindow

    titleBar.InputBegan:Connect(function(input)
        if input.UserInputType == Enum.UserInputType.MouseButton1 then
            dragging = true
            dragStart = Vector2.new(input.Position.X, input.Position.Y)
            startPos = WindowHolder.Position
            targetWindowPos = WindowHolder.Position
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
            local delta = Vector2.new(input.Position.X, input.Position.Y) - dragStart
            targetWindowPos = UDim2.new(
                startPos.X.Scale,
                startPos.X.Offset + delta.X,
                startPos.Y.Scale,
                startPos.Y.Offset + delta.Y
            )
            Library:CloseActivePopup()
        end
    end)
    table.insert(self.Connections, dragMoveConn)

    local smoothDragConn = RunService.RenderStepped:Connect(function(dt)
        if WindowHolder and WindowHolder.Parent and WindowHolder.Visible then
            local cur = WindowHolder.Position
            if math.abs(cur.X.Offset - targetWindowPos.X.Offset) > 0.2 or math.abs(cur.Y.Offset - targetWindowPos.Y.Offset) > 0.2 then
                local alpha = math.clamp(dt * 22, 0, 1)
                WindowHolder.Position = cur:Lerp(targetWindowPos, alpha)
            elseif dragging then
                WindowHolder.Position = targetWindowPos
            end
        end
    end)
    table.insert(self.Connections, smoothDragConn)

    local topAccent = Instance.new("Frame")
    topAccent.Size = UDim2.new(1, 0, 0, 3)
    topAccent.BackgroundColor3 = self.Accent
    topAccent.BorderSizePixel = 0
    topAccent.ZIndex = 6
    topAccent.Parent = MainWindow

    Library:ApplyGradient(topAccent, { self.AccentDeep, self.Accent, self.AccentSecondary }, 0, true)
    Library:RegisterColor(topAccent, "BackgroundColor3", "Accent")

    local topAccentGlow = Instance.new("Frame")
    topAccentGlow.Size = UDim2.new(1, 0, 0, 20)
    topAccentGlow.BackgroundColor3 = self.Accent
    topAccentGlow.BackgroundTransparency = 0.2
    topAccentGlow.BorderSizePixel = 0
    topAccentGlow.ZIndex = 4
    topAccentGlow.Parent = MainWindow

    local glowGrad = Instance.new("UIGradient")
    glowGrad.Rotation = 90
    glowGrad.Transparency = NumberSequence.new({
        NumberSequenceKeypoint.new(0, 0.68),
        NumberSequenceKeypoint.new(1, 1)
    })
    glowGrad.Parent = topAccentGlow
    Library:RegisterColor(topAccentGlow, "BackgroundColor3", "Accent")

    local titleDot = Instance.new("Frame")
    titleDot.Size = UDim2.new(0, 8, 0, 8)
    titleDot.Position = UDim2.new(0, 16, 0.5, -4)
    titleDot.BackgroundColor3 = self.Accent
    titleDot.BorderSizePixel = 0
    titleDot.ZIndex = 6
    titleDot.Parent = titleBar
    Library:RegisterColor(titleDot, "BackgroundColor3", "Accent")

    local tdCorner = Instance.new("UICorner")
    tdCorner.CornerRadius = UDim.new(1, 0)
    tdCorner.Parent = titleDot

    local titleLabel = Instance.new("TextLabel")
    titleLabel.Name = "TitleText"
    titleLabel.Size = UDim2.new(0, 200, 1, 0)
    titleLabel.Position = UDim2.new(0, 32, 0, 0)
    titleLabel.BackgroundTransparency = 1
    titleLabel.Font = self.FontBold
    titleLabel.Text = TitleText
    titleLabel.TextColor3 = self.TextColor
    titleLabel.TextSize = 14
    titleLabel.TextXAlignment = Enum.TextXAlignment.Left
    titleLabel.ZIndex = 6
    titleLabel.Parent = titleBar

    local subTitleBadge = Instance.new("Frame")
    subTitleBadge.Size = UDim2.new(0, 0, 0, 18)
    subTitleBadge.AutomaticSize = Enum.AutomaticSize.X
    subTitleBadge.Position = UDim2.new(0, 32 + titleLabel.TextBounds.X + 10, 0.5, -9)
    subTitleBadge.BackgroundColor3 = self.Accent
    subTitleBadge.BackgroundTransparency = 0.85
    subTitleBadge.BorderSizePixel = 0
    subTitleBadge.ZIndex = 6
    subTitleBadge.Parent = titleBar
    Library:RegisterColor(subTitleBadge, "BackgroundColor3", "Accent")

    local stbCorner = Instance.new("UICorner")
    stbCorner.CornerRadius = UDim.new(0, 5)
    stbCorner.Parent = subTitleBadge

    local stbStroke = Instance.new("UIStroke")
    stbStroke.Color = self.Accent
    stbStroke.Transparency = 0.55
    stbStroke.Thickness = 1
    stbStroke.Parent = subTitleBadge
    Library:RegisterColor(stbStroke, "Color", "Accent")

    local stbPad = Instance.new("UIPadding")
    stbPad.PaddingLeft = UDim.new(0, 7)
    stbPad.PaddingRight = UDim.new(0, 7)
    stbPad.Parent = subTitleBadge

    local subTitleLabel = Instance.new("TextLabel")
    subTitleLabel.Name = "SubTitleText"
    subTitleLabel.Size = UDim2.new(0, 0, 1, 0)
    subTitleLabel.AutomaticSize = Enum.AutomaticSize.X
    subTitleLabel.BackgroundTransparency = 1
    subTitleLabel.Font = self.FontBold
    subTitleLabel.Text = SubTitleText
    subTitleLabel.TextColor3 = self.Accent
    subTitleLabel.TextSize = 10
    subTitleLabel.ZIndex = 7
    subTitleLabel.Parent = subTitleBadge

    Library:RegisterText(titleLabel, true)
    Library:RegisterText(subTitleLabel, true)
    Library:RegisterColor(titleLabel, "TextColor3", "TextColor")
    Library:RegisterColor(subTitleLabel, "TextColor3", "Accent")

    titleLabel:GetPropertyChangedSignal("TextBounds"):Connect(function()
        subTitleBadge.Position = UDim2.new(0, 32 + titleLabel.TextBounds.X + 10, 0.5, -9)
    end)

    local headerLine = Instance.new("Frame")
    headerLine.Size = UDim2.new(1, 0, 0, 1)
    headerLine.Position = UDim2.new(0, 0, 0, 44)
    headerLine.BackgroundColor3 = self.GlassBorderSoft
    headerLine.BackgroundTransparency = 0.25
    headerLine.BorderSizePixel = 0
    headerLine.ZIndex = 5
    headerLine.Parent = MainWindow

    Library:RegisterColor(headerLine, "BackgroundColor3", "GlassBorderSoft")

    local sidebar = Instance.new("Frame")
    sidebar.Name = "Sidebar"
    sidebar.Size = UDim2.new(0, 155, 1, -72)
    sidebar.Position = UDim2.new(0, 0, 0, 45)
    sidebar.BackgroundColor3 = self.GlassSidebar
    sidebar.BackgroundTransparency = 0.22
    sidebar.BorderSizePixel = 0
    sidebar.ClipsDescendants = true
    sidebar.ZIndex = 3
    sidebar.Parent = MainWindow

    Library:RegisterColor(sidebar, "BackgroundColor3", "GlassSidebar")

    local sidebarScroll = Instance.new("ScrollingFrame")
    sidebarScroll.Name = "SidebarScroll"
    sidebarScroll.Size = UDim2.new(1, 0, 1, 0)
    sidebarScroll.BackgroundTransparency = 1
    sidebarScroll.BorderSizePixel = 0
    sidebarScroll.ScrollBarThickness = 0
    sidebarScroll.CanvasSize = UDim2.new(0, 0, 0, 0)
    sidebarScroll.ZIndex = 4
    sidebarScroll.Parent = sidebar

    local sidebarLayout = Instance.new("UIListLayout")
    sidebarLayout.SortOrder = Enum.SortOrder.LayoutOrder
    sidebarLayout.Padding = UDim.new(0, 5)
    sidebarLayout.Parent = sidebarScroll

    local sidebarPad = Instance.new("UIPadding")
    sidebarPad.PaddingTop = UDim.new(0, 10)
    sidebarPad.PaddingBottom = UDim.new(0, 10)
    sidebarPad.PaddingLeft = UDim.new(0, 8)
    sidebarPad.PaddingRight = UDim.new(0, 8)
    sidebarPad.Parent = sidebarScroll

    sidebarLayout:GetPropertyChangedSignal("AbsoluteContentSize"):Connect(function()
        sidebarScroll.CanvasSize = UDim2.new(0, 0, 0, sidebarLayout.AbsoluteContentSize.Y + 20)
    end)

    local sidebarDivider = Instance.new("Frame")
    sidebarDivider.Size = UDim2.new(0, 1, 1, -72)
    sidebarDivider.Position = UDim2.new(0, 155, 0, 45)
    sidebarDivider.BackgroundColor3 = self.GlassBorder
    sidebarDivider.BackgroundTransparency = 0.4
    sidebarDivider.BorderSizePixel = 0
    sidebarDivider.ZIndex = 5
    sidebarDivider.Parent = MainWindow

    Library:RegisterColor(sidebarDivider, "BackgroundColor3", "GlassBorder")

    local tabContainer = Instance.new("Frame")
    tabContainer.Name = "TabViews"
    tabContainer.Size = UDim2.new(1, -156, 1, -72)
    tabContainer.Position = UDim2.new(0, 156, 0, 45)
    tabContainer.BackgroundTransparency = 1
    tabContainer.ClipsDescendants = true
    tabContainer.ZIndex = 3
    tabContainer.Parent = MainWindow

    local footerLine = Instance.new("Frame")
    footerLine.Size = UDim2.new(1, 0, 0, 1)
    footerLine.Position = UDim2.new(0, 0, 1, -27)
    footerLine.BackgroundColor3 = self.GlassBorderSoft
    footerLine.BackgroundTransparency = 0.25
    footerLine.BorderSizePixel = 0
    footerLine.ZIndex = 5
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
    footerLabel.ZIndex = 5
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
            WindowHolder.Visible = true
            windowScale.Scale = 0.9
            Library:Tween(windowScale, 0.3, { Scale = 1 }, Enum.EasingStyle.Back, Enum.EasingDirection.Out)
            Library:Tween(MainWindow, 0.25, { BackgroundTransparency = self.BackgroundTransparency }, Enum.EasingStyle.Quart, Enum.EasingDirection.Out)
        else
            Library:CloseActivePopup()
            Library:Tween(windowScale, 0.2, { Scale = 0.92 }, Enum.EasingStyle.Quart, Enum.EasingDirection.In)
            Library:Tween(MainWindow, 0.2, { BackgroundTransparency = 0.6 }, Enum.EasingStyle.Quart, Enum.EasingDirection.In)
            task.delay(0.2, function()
                if not self.Open then
                    WindowHolder.Visible = false
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
        tabButton.Size = UDim2.new(1, 0, 0, 34)
        tabButton.BackgroundColor3 = Library.SidebarItemBg
        tabButton.BackgroundTransparency = 0.85
        tabButton.AutoButtonColor = false
        tabButton.Text = ""
        tabButton.ZIndex = 5
        tabButton.Parent = sidebarScroll

        Library:RegisterColor(tabButton, "BackgroundColor3", "SidebarItemBg")

        local btnCorner = Instance.new("UICorner")
        btnCorner.CornerRadius = UDim.new(0, 8)
        btnCorner.Parent = tabButton

        local tabStroke = Instance.new("UIStroke")
        tabStroke.Color = Library.Accent
        tabStroke.Thickness = 1
        tabStroke.Transparency = 1
        tabStroke.Parent = tabButton

        Library:RegisterColor(tabStroke, "Color", "Accent")

        local iconImg = Instance.new("ImageLabel")
        iconImg.Size = UDim2.new(0, 17, 0, 17)
        iconImg.Position = UDim2.new(0, 10, 0.5, -8)
        iconImg.BackgroundTransparency = 1
        iconImg.ImageColor3 = Library.SidebarTextColor
        iconImg.ZIndex = 6
        iconImg.Parent = tabButton

        local hasIcon = Library:ApplyIcon(iconImg, iconInput)
        iconImg.Visible = hasIcon

        local baseTextX = hasIcon and 34 or 14

        local tabTitle = Instance.new("TextLabel")
        tabTitle.Size = UDim2.new(1, -(baseTextX + 6), 1, 0)
        tabTitle.Position = UDim2.new(0, baseTextX, 0, 0)
        tabTitle.BackgroundTransparency = 1
        tabTitle.Font = Library.Font
        tabTitle.Text = tabName
        tabTitle.TextColor3 = Library.SidebarTextColor
        tabTitle.TextSize = 12.5
        tabTitle.TextXAlignment = Enum.TextXAlignment.Left
        tabTitle.ZIndex = 6
        tabTitle.Parent = tabButton

        Library:RegisterText(tabTitle, false)

        local activeBar = Instance.new("Frame")
        activeBar.Size = UDim2.new(0, 3, 0, 6)
        activeBar.Position = UDim2.new(0, 1, 0.5, 0)
        activeBar.AnchorPoint = Vector2.new(0, 0.5)
        activeBar.BackgroundColor3 = Library.Accent
        activeBar.BorderSizePixel = 0
        activeBar.BackgroundTransparency = 1
        activeBar.ZIndex = 7
        activeBar.Parent = tabButton

        Library:ApplyGradient(activeBar, { Library.AccentDeep, Library.Accent, Library.AccentSecondary }, 90, true)
        Library:RegisterColor(activeBar, "BackgroundColor3", "Accent")

        local abCorner = Instance.new("UICorner")
        abCorner.CornerRadius = UDim.new(1, 0)
        abCorner.Parent = activeBar

        local tabScroll = Instance.new("ScrollingFrame")
        tabScroll.Name = "Scroll_" .. tabName
        tabScroll.Size = UDim2.new(1, 0, 1, 0)
        tabScroll.Position = UDim2.new(0, 0, 0, 14)
        tabScroll.BackgroundTransparency = 1
        tabScroll.BorderSizePixel = 0
        tabScroll.ScrollBarThickness = 3
        tabScroll.ScrollBarImageColor3 = Library.Accent
        tabScroll.ScrollBarImageTransparency = 0.35
        tabScroll.Visible = false
        tabScroll.CanvasSize = UDim2.new(0, 0, 0, 0)
        tabScroll.ZIndex = 4
        tabScroll.Parent = tabContainer

        Library:RegisterColor(tabScroll, "ScrollBarImageColor3", "Accent")

        tabScroll:GetPropertyChangedSignal("CanvasPosition"):Connect(function()
            Library:CloseActivePopup()
        end)

        local pad = Instance.new("UIPadding")
        pad.PaddingTop = UDim.new(0, 10)
        pad.PaddingBottom = UDim.new(0, 14)
        pad.PaddingLeft = UDim.new(0, 12)
        pad.PaddingRight = UDim.new(0, 12)
        pad.Parent = tabScroll

        local leftCol = Instance.new("Frame")
        leftCol.Name = "LeftColumn"
        leftCol.Size = UDim2.new(0.5, -6, 0, 0)
        leftCol.Position = UDim2.new(0, 0, 0, 0)
        leftCol.BackgroundTransparency = 1
        leftCol.ZIndex = 4
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
        rightCol.ZIndex = 4
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
            rightCol.Size = UDim2.new(0.5, -6, 0, rightH)
        end

        leftLayout:GetPropertyChangedSignal("AbsoluteContentSize"):Connect(UpdateCanvas)
        rightLayout:GetPropertyChangedSignal("AbsoluteContentSize"):Connect(UpdateCanvas)

        local function ShowTab()
            if WindowObj.CurrentTab == Tab then return end
            Library:CloseActivePopup()

            for _, t in ipairs(WindowObj.Tabs) do
                if t ~= Tab then
                    if t.View.Visible then
                        local oldView = t.View
                        Library:Tween(oldView, 0.16, { Position = UDim2.new(0, 0, 0, -10) }, Enum.EasingStyle.Quart, Enum.EasingDirection.Out)
                        task.delay(0.15, function()
                            if WindowObj.CurrentTab ~= t then
                                oldView.Visible = false
                            end
                        end)
                    end
                    Library:Tween(t.Button, 0.2, { BackgroundTransparency = 0.85 })
                    Library:Tween(t.Stroke, 0.2, { Transparency = 1 })
                    Library:Tween(t.Label, 0.2, {
                        TextColor3 = Library.SidebarTextColor,
                        Position = UDim2.new(0, t.BaseTextX, 0, 0)
                    })
                    Library:Tween(t.ActiveBar, 0.2, { BackgroundTransparency = 1, Size = UDim2.new(0, 3, 0, 6) })
                    if t.Icon and t.Icon.Visible then
                        Library:Tween(t.Icon, 0.2, { ImageColor3 = Library.SidebarTextColor })
                    end
                end
            end

            WindowObj.CurrentTab = Tab
            tabScroll.Position = UDim2.new(0, 0, 0, 14)
            tabScroll.Visible = true
            Library:Tween(tabScroll, 0.28, { Position = UDim2.new(0, 0, 0, 0) }, Enum.EasingStyle.Quart, Enum.EasingDirection.Out)

            -- Staggered Groupbox Entrance Animation
            local allGbs = {}
            for _, g in ipairs(Tab.LeftGroupboxes) do table.insert(allGbs, g) end
            for _, g in ipairs(Tab.RightGroupboxes) do table.insert(allGbs, g) end
            for idx, g in ipairs(allGbs) do
                if g.Scale then
                    g.Scale.Scale = 0.96
                    task.delay((idx - 1) * 0.03, function()
                        if g.Scale and g.Scale.Parent then
                            Library:Tween(g.Scale, 0.28, { Scale = 1 }, Enum.EasingStyle.Back, Enum.EasingDirection.Out)
                        end
                    end)
                end
            end

            Library:Tween(tabButton, 0.2, { BackgroundTransparency = 0.12 })
            Library:Tween(tabStroke, 0.2, { Transparency = 0.45 })
            Library:Tween(tabTitle, 0.2, {
                TextColor3 = Library.TextColor,
                Position = UDim2.new(0, baseTextX + 3, 0, 0)
            })
            Library:Tween(activeBar, 0.25, { BackgroundTransparency = 0, Size = UDim2.new(0, 3, 0, 18) }, Enum.EasingStyle.Back, Enum.EasingDirection.Out)
            if iconImg.Visible then
                Library:Tween(iconImg, 0.2, { ImageColor3 = Library.Accent })
            end
            UpdateCanvas()
        end

        tabButton.MouseButton1Click:Connect(function()
            Library:CreateRipple(tabButton, UserInputService:GetMouseLocation(), Library.Accent)
            ShowTab()
        end)

        tabButton.MouseEnter:Connect(function()
            if WindowObj.CurrentTab ~= Tab then
                Library:Tween(tabButton, 0.15, { BackgroundTransparency = 0.5 })
                Library:Tween(tabTitle, 0.15, {
                    TextColor3 = Library.TextColor,
                    Position = UDim2.new(0, baseTextX + 2, 0, 0)
                })
                if iconImg.Visible then
                    Library:Tween(iconImg, 0.15, { ImageColor3 = Library.TextColor })
                end
            end
        end)
        tabButton.MouseLeave:Connect(function()
            if WindowObj.CurrentTab ~= Tab then
                Library:Tween(tabButton, 0.15, { BackgroundTransparency = 0.85 })
                Library:Tween(tabTitle, 0.15, {
                    TextColor3 = Library.SidebarTextColor,
                    Position = UDim2.new(0, baseTextX, 0, 0)
                })
                if iconImg.Visible then
                    Library:Tween(iconImg, 0.15, { ImageColor3 = Library.SidebarTextColor })
                end
            end
        end)

        Tab.View = tabScroll
        Tab.Button = tabButton
        Tab.Stroke = tabStroke
        Tab.Label = tabTitle
        Tab.Icon = iconImg
        Tab.ActiveBar = activeBar
        Tab.BaseTextX = baseTextX
        table.insert(WindowObj.Tabs, Tab)

        if #WindowObj.Tabs == 1 then
            ShowTab()
        end

        local function CreateGroupbox(parentContainer, groupTitle)
            local gb = Instance.new("Frame")
            gb.Name = "Groupbox_" .. groupTitle
            gb.Size = UDim2.new(1, 0, 0, 0)
            gb.BackgroundColor3 = Library.GlassSection
            gb.BackgroundTransparency = 0.26
            gb.BorderSizePixel = 0
            gb.ZIndex = 4
            gb.Parent = parentContainer

            local gbScale = Instance.new("UIScale")
            gbScale.Scale = 1
            gbScale.Parent = gb

            Library:RegisterColor(gb, "BackgroundColor3", "GlassSection")

            local gbCorner = Instance.new("UICorner")
            gbCorner.CornerRadius = UDim.new(0, 10)
            gbCorner.Parent = gb

            local gbStroke = Instance.new("UIStroke")
            gbStroke.Color = Library.GlassBorder
            gbStroke.Thickness = 1
            gbStroke.Transparency = 0.35
            gbStroke.Parent = gb
            Library:RegisterColor(gbStroke, "Color", "GlassBorder")

            Library:AddGlassSurface(gb, { ShineTransparency = 0.94, EdgeTransparency = 0.72, Rotation = 125 })

            gb.MouseEnter:Connect(function()
                Library:Tween(gbStroke, 0.2, { Transparency = 0.12 })
            end)
            gb.MouseLeave:Connect(function()
                Library:Tween(gbStroke, 0.2, { Transparency = 0.35 })
            end)

            local gbDot = Instance.new("Frame")
            gbDot.Size = UDim2.new(0, 5, 0, 5)
            gbDot.Position = UDim2.new(0, 11, 0, 14)
            gbDot.AnchorPoint = Vector2.new(0, 0.5)
            gbDot.BackgroundColor3 = Library.Accent
            gbDot.BorderSizePixel = 0
            gbDot.ZIndex = 5
            gbDot.Parent = gb

            local gbDotCorner = Instance.new("UICorner")
            gbDotCorner.CornerRadius = UDim.new(1, 0)
            gbDotCorner.Parent = gbDot

            Library:RegisterColor(gbDot, "BackgroundColor3", "Accent")

            local header = Instance.new("Frame")
            header.Name = "Header"
            header.Size = UDim2.new(1, 0, 0, 28)
            header.BackgroundTransparency = 1
            header.ZIndex = 5
            header.Parent = gb

            local gbTitleLabel = Instance.new("TextLabel")
            gbTitleLabel.Size = UDim2.new(1, -28, 1, 0)
            gbTitleLabel.Position = UDim2.new(0, 21, 0, 0)
            gbTitleLabel.BackgroundTransparency = 1
            gbTitleLabel.Font = Library.FontBold
            gbTitleLabel.Text = groupTitle
            gbTitleLabel.TextColor3 = Library.TextColor
            gbTitleLabel.TextSize = 11.5
            gbTitleLabel.TextXAlignment = Enum.TextXAlignment.Left
            gbTitleLabel.ZIndex = 5
            gbTitleLabel.Parent = header

            Library:RegisterText(gbTitleLabel, true)
            Library:RegisterColor(gbTitleLabel, "TextColor3", "TextColor")

            local line = Instance.new("Frame")
            line.Size = UDim2.new(1, 0, 0, 1)
            line.Position = UDim2.new(0, 0, 0, 28)
            line.BackgroundColor3 = Library.GlassBorderSoft
            line.BackgroundTransparency = 0.3
            line.BorderSizePixel = 0
            line.ZIndex = 5
            line.Parent = gb

            Library:RegisterColor(line, "BackgroundColor3", "GlassBorderSoft")

            local container = Instance.new("Frame")
            container.Name = "Container"
            container.Size = UDim2.new(1, 0, 0, 0)
            container.Position = UDim2.new(0, 0, 0, 29)
            container.BackgroundTransparency = 1
            container.ZIndex = 5
            container.Parent = gb

            local listLayout = Instance.new("UIListLayout")
            listLayout.SortOrder = Enum.SortOrder.LayoutOrder
            listLayout.Padding = UDim.new(0, 7)
            listLayout.Parent = container

            local listPad = Instance.new("UIPadding")
            listPad.PaddingTop = UDim.new(0, 8)
            listPad.PaddingBottom = UDim.new(0, 10)
            listPad.PaddingLeft = UDim.new(0, 10)
            listPad.PaddingRight = UDim.new(0, 10)
            listPad.Parent = container

            local function UpdateGbHeight()
                local innerH = listLayout.AbsoluteContentSize.Y + 18
                container.Size = UDim2.new(1, 0, 0, innerH)
                gb.Size = UDim2.new(1, 0, 0, innerH + 29)
                UpdateCanvas()
            end

            listLayout:GetPropertyChangedSignal("AbsoluteContentSize"):Connect(UpdateGbHeight)

            local Groupbox = {
                Frame = gb,
                Container = container,
                Scale = gbScale
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
                row.ZIndex = 5
                row.Parent = container

                local checkBox = Instance.new("TextButton")
                checkBox.Name = "Pill"
                checkBox.Size = UDim2.new(0, 32, 0, 17)
                checkBox.Position = UDim2.new(0, 0, 0.5, -8)
                checkBox.BackgroundColor3 = state and Library.Accent or Library.GlassElement
                checkBox.BackgroundTransparency = state and 0.05 or 0.25
                checkBox.BorderSizePixel = 0
                checkBox.Text = ""
                checkBox.AutoButtonColor = false
                checkBox.ClipsDescendants = false
                checkBox.ZIndex = 6
                checkBox.Parent = row

                local cbCorner = Instance.new("UICorner")
                cbCorner.CornerRadius = UDim.new(1, 0)
                cbCorner.Parent = checkBox

                local cbStroke = Instance.new("UIStroke")
                cbStroke.Color = state and Library.Accent or Library.GlassBorderSoft
                cbStroke.Transparency = state and 0.2 or 0.35
                cbStroke.Parent = checkBox

                local knob = Instance.new("Frame")
                knob.Name = "Knob"
                knob.Size = UDim2.new(0, 13, 0, 13)
                knob.AnchorPoint = Vector2.new(0, 0.5)
                knob.Position = state and UDim2.new(1, -15, 0.5, 0) or UDim2.new(0, 2, 0.5, 0)
                knob.BackgroundColor3 = Color3.fromRGB(255, 255, 255)
                knob.BorderSizePixel = 0
                knob.ZIndex = 7
                knob.Parent = checkBox

                local knobCorner = Instance.new("UICorner")
                knobCorner.CornerRadius = UDim.new(1, 0)
                knobCorner.Parent = knob

                local titleBtn = Instance.new("TextButton")
                titleBtn.Size = UDim2.new(1, -42, 1, 0)
                titleBtn.Position = UDim2.new(0, 40, 0, 0)
                titleBtn.BackgroundTransparency = 1
                titleBtn.Font = Library.Font
                titleBtn.Text = text
                titleBtn.TextColor3 = state and Library.TextColor or Library.SubTextColor
                titleBtn.TextSize = 12
                titleBtn.TextXAlignment = Enum.TextXAlignment.Left
                titleBtn.AutoButtonColor = false
                titleBtn.ZIndex = 6
                titleBtn.Parent = row

                Library:RegisterText(titleBtn, false)

                row.MouseEnter:Connect(function()
                    if not ToggleObj.Value then
                        Library:Tween(titleBtn, 0.15, { TextColor3 = Library.TextColor })
                        Library:Tween(cbStroke, 0.15, { Color = Library.GlassBorder })
                    end
                end)
                row.MouseLeave:Connect(function()
                    if not ToggleObj.Value then
                        Library:Tween(titleBtn, 0.15, { TextColor3 = Library.SubTextColor })
                        Library:Tween(cbStroke, 0.15, { Color = Library.GlassBorderSoft })
                    end
                end)

                local addonsContainer = Instance.new("Frame")
                addonsContainer.Name = "Addons"
                addonsContainer.Size = UDim2.new(0, 0, 1, 0)
                addonsContainer.Position = UDim2.new(1, 0, 0, 0)
                addonsContainer.AnchorPoint = Vector2.new(1, 0)
                addonsContainer.BackgroundTransparency = 1
                addonsContainer.AutomaticSize = Enum.AutomaticSize.X
                addonsContainer.ZIndex = 6
                addonsContainer.Parent = row

                local addonsLayout = Instance.new("UIListLayout")
                addonsLayout.FillDirection = Enum.FillDirection.Horizontal
                addonsLayout.HorizontalAlignment = Enum.HorizontalAlignment.Right
                addonsLayout.VerticalAlignment = Enum.VerticalAlignment.Center
                addonsLayout.SortOrder = Enum.SortOrder.LayoutOrder
                addonsLayout.Padding = UDim.new(0, 5)
                addonsLayout.Parent = addonsContainer

                ToggleObj = {
                    Value = state,
                    Type = "Toggle",
                    SetValue = function(selfTog, val)
                        selfTog.Value = val == true
                        Library:Tween(checkBox, 0.2, {
                            BackgroundColor3 = selfTog.Value and Library.Accent or Library.GlassElement,
                            BackgroundTransparency = selfTog.Value and 0.05 or 0.25
                        })
                        Library:Tween(cbStroke, 0.2, {
                            Color = selfTog.Value and Library.Accent or Library.GlassBorderSoft,
                            Transparency = selfTog.Value and 0.2 or 0.35
                        })

                        -- Elastic knob stretch effect
                        Library:Tween(knob, 0.08, { Size = UDim2.new(0, 16, 0, 13) })
                        task.delay(0.06, function()
                            if knob and knob.Parent then
                                Library:Tween(knob, 0.22, {
                                    Size = UDim2.new(0, 13, 0, 13),
                                    Position = selfTog.Value and UDim2.new(1, -15, 0.5, 0) or UDim2.new(0, 2, 0.5, 0)
                                }, Enum.EasingStyle.Back, Enum.EasingDirection.Out)
                            end
                        end)

                        Library:Tween(titleBtn, 0.18, {
                            TextColor3 = selfTog.Value and Library.TextColor or Library.SubTextColor
                        })
                        task.spawn(callback, selfTog.Value)
                    end
                }

                local function OnClick()
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
                    cpBtn.Size = UDim2.new(0, 24, 0, 14)
                    cpBtn.BackgroundColor3 = cpDef
                    cpBtn.BorderSizePixel = 0
                    cpBtn.Text = ""
                    cpBtn.AutoButtonColor = false
                    cpBtn.ZIndex = 7
                    cpBtn.Parent = addonsContainer

                    local cCorner = Instance.new("UICorner")
                    cCorner.CornerRadius = UDim.new(0, 4)
                    cCorner.Parent = cpBtn

                    local cStroke = Instance.new("UIStroke")
                    cStroke.Color = Library.GlassBorder
                    cStroke.Transparency = 0.2
                    cStroke.Parent = cpBtn

                    Library:RegisterColor(cStroke, "Color", "GlassBorder")

                    local cpPopup = Instance.new("Frame")
                    cpPopup.Name = "ColorPopup_" .. tostring(cpId)
                    cpPopup.Size = UDim2.new(0, 180, 0, 165)
                    cpPopup.BackgroundColor3 = Library.SolidPopup
                    cpPopup.BackgroundTransparency = 0.05
                    cpPopup.BorderSizePixel = 0
                    cpPopup.Visible = false
                    cpPopup.ZIndex = 50
                    cpPopup.Parent = Library.PopupGui
                    cpPopup.OpenerBtn = cpBtn

                    local cpScale = Instance.new("UIScale")
                    cpScale.Scale = 0.9
                    cpScale.Parent = cpPopup

                    Library:RegisterColor(cpPopup, "BackgroundColor3", "SolidPopup")

                    local pCorner = Instance.new("UICorner")
                    pCorner.CornerRadius = UDim.new(0, 10)
                    pCorner.Parent = cpPopup

                    local pStroke = Instance.new("UIStroke")
                    pStroke.Color = Library.GlassBorder
                    pStroke.Transparency = 0.2
                    pStroke.Parent = cpPopup

                    Library:AddShadow(cpPopup, { Transparency = 0.4, Spread = 30, YOffset = 6, ZIndex = 49 })
                    Library:AddGlassSurface(cpPopup, { ShineTransparency = 0.93, EdgeTransparency = 0.65 })
                    Library:RegisterColor(pStroke, "Color", "GlassBorder")

                    local pTitle = Instance.new("TextLabel")
                    pTitle.Size = UDim2.new(1, -16, 0, 22)
                    pTitle.Position = UDim2.new(0, 10, 0, 4)
                    pTitle.BackgroundTransparency = 1
                    pTitle.Font = Library.FontBold
                    pTitle.Text = cpTitle
                    pTitle.TextColor3 = Library.TextColor
                    pTitle.TextSize = 11
                    pTitle.TextXAlignment = Enum.TextXAlignment.Left
                    pTitle.ZIndex = 52
                    pTitle.Parent = cpPopup

                    Library:RegisterText(pTitle, true)
                    Library:RegisterColor(pTitle, "TextColor3", "TextColor")

                    local svBox = Instance.new("ImageButton")
                    svBox.Size = UDim2.new(1, -20, 0, 100)
                    svBox.Position = UDim2.new(0, 10, 0, 28)
                    svBox.Image = "rbxassetid://4155801252"
                    svBox.BorderSizePixel = 0
                    svBox.AutoButtonColor = false
                    svBox.ZIndex = 52
                    svBox.Parent = cpPopup

                    local svCorner = Instance.new("UICorner")
                    svCorner.CornerRadius = UDim.new(0, 6)
                    svCorner.Parent = svBox

                    local svCursor = Instance.new("Frame")
                    svCursor.Size = UDim2.new(0, 10, 0, 10)
                    svCursor.AnchorPoint = Vector2.new(0.5, 0.5)
                    svCursor.BackgroundColor3 = Color3.fromRGB(255, 255, 255)
                    svCursor.BorderSizePixel = 0
                    svCursor.ZIndex = 54
                    svCursor.Parent = svBox

                    local svcCorner = Instance.new("UICorner")
                    svcCorner.CornerRadius = UDim.new(1, 0)
                    svcCorner.Parent = svCursor

                    local svcStroke = Instance.new("UIStroke")
                    svcStroke.Color = Color3.fromRGB(0, 0, 0)
                    svcStroke.Thickness = 1.5
                    svcStroke.Parent = svCursor

                    local hueBar = Instance.new("ImageButton")
                    hueBar.Size = UDim2.new(1, -20, 0, 14)
                    hueBar.Position = UDim2.new(0, 10, 0, 138)
                    hueBar.Image = "rbxassetid://3641079629"
                    hueBar.BorderSizePixel = 0
                    hueBar.AutoButtonColor = false
                    hueBar.ZIndex = 52
                    hueBar.Parent = cpPopup

                    local hbCorner = Instance.new("UICorner")
                    hbCorner.CornerRadius = UDim.new(1, 0)
                    hbCorner.Parent = hueBar

                    local hueCursor = Instance.new("Frame")
                    hueCursor.Size = UDim2.new(0, 6, 1, 4)
                    hueCursor.AnchorPoint = Vector2.new(0.5, 0.5)
                    hueCursor.Position = UDim2.new(0, 0, 0.5, 0)
                    hueCursor.BackgroundColor3 = Color3.fromRGB(255, 255, 255)
                    hueCursor.BorderSizePixel = 0
                    hueCursor.ZIndex = 54
                    hueCursor.Parent = hueBar

                    local hcCorner = Instance.new("UICorner")
                    hcCorner.CornerRadius = UDim.new(1, 0)
                    hcCorner.Parent = hueCursor

                    local curHue, curSat, curVal = cpDef:ToHSV()
                    svBox.BackgroundColor3 = Color3.fromHSV(curHue, 1, 1)
                    svCursor.Position = UDim2.new(curSat, 0, 1 - curVal, 0)
                    hueCursor.Position = UDim2.new(curHue, 0, 0.5, 0)

                    local ColorPickerObj = {
                        Value = cpDef,
                        Type = "ColorPicker",
                        SetValue = function(selfCp, color)
                            selfCp.Value = color
                            cpBtn.BackgroundColor3 = color
                            local h, s, v = color:ToHSV()
                            curHue, curSat, curVal = h, s, v
                            svBox.BackgroundColor3 = Color3.fromHSV(curHue, 1, 1)
                            svCursor.Position = UDim2.new(curSat, 0, 1 - curVal, 0)
                            hueCursor.Position = UDim2.new(curHue, 0, 0.5, 0)
                            task.spawn(cpCb, color)
                        end
                    }

                    local dragSV, dragHue = false, false
                    local function UpdateSV(input)
                        local rx = math.clamp((input.Position.X - svBox.AbsolutePosition.X) / svBox.AbsoluteSize.X, 0, 1)
                        local ry = math.clamp((input.Position.Y - svBox.AbsolutePosition.Y) / svBox.AbsoluteSize.Y, 0, 1)
                        curSat = rx
                        curVal = 1 - ry
                        ColorPickerObj:SetValue(Color3.fromHSV(curHue, curSat, curVal))
                    end
                    local function UpdateHue(input)
                        local rx = math.clamp((input.Position.X - hueBar.AbsolutePosition.X) / hueBar.AbsoluteSize.X, 0, 1)
                        curHue = rx
                        ColorPickerObj:SetValue(Color3.fromHSV(curHue, curSat, curVal))
                    end

                    svBox.InputBegan:Connect(function(input)
                        if input.UserInputType == Enum.UserInputType.MouseButton1 then
                            dragSV = true
                            UpdateSV(input)
                        end
                    end)
                    hueBar.InputBegan:Connect(function(input)
                        if input.UserInputType == Enum.UserInputType.MouseButton1 then
                            dragHue = true
                            UpdateHue(input)
                        end
                    end)

                    local moveConn = UserInputService.InputChanged:Connect(function(input)
                        if input.UserInputType == Enum.UserInputType.MouseMovement then
                            if dragSV then
                                UpdateSV(input)
                            elseif dragHue then
                                UpdateHue(input)
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
                            cpScale.Scale = 0.88
                            cpPopup.Visible = true
                            Library:Tween(cpScale, 0.22, { Scale = 1 }, Enum.EasingStyle.Back, Enum.EasingDirection.Out)
                            Library.ActivePopup = cpPopup
                            Library.ActivePopupCloseCallback = function()
                                Library:Tween(cpScale, 0.15, { Scale = 0.88 }, Enum.EasingStyle.Quart, Enum.EasingDirection.In)
                                task.delay(0.15, function()
                                    if Library.ActivePopup ~= cpPopup then
                                        cpPopup.Visible = false
                                    end
                                end)
                            end
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
                        kpBtn.ZIndex = 7
                        kpBtn.Parent = addonsContainer

                        local kpCorner = Instance.new("UICorner")
                        kpCorner.CornerRadius = UDim.new(0, 4)
                        kpCorner.Parent = kpBtn

                        local kpStroke = Instance.new("UIStroke")
                        kpStroke.Color = Library.GlassBorderSoft
                        kpStroke.Transparency = 0.4
                        kpStroke.Parent = kpBtn

                        Library:RegisterText(kpBtn, false)
                        Library:RegisterColor(kpBtn, "BackgroundColor3", "GlassElement")

                        local listening = false
                        kpBtn.MouseButton1Click:Connect(function()
                            if listening then return end
                            listening = true
                            kpBtn.Text = "[...]"
                            Library:Tween(kpBtn, 0.15, { TextColor3 = Library.Accent })
                            Library:Tween(kpStroke, 0.15, { Color = Library.Accent, Transparency = 0 })

                            local tempConn
                            tempConn = UserInputService.InputBegan:Connect(function(input)
                                local k = ParseKeyInput(input)
                                if k then
                                    if k == Enum.KeyCode.Escape then k = "None" end
                                    KeyPickerObj.Value = k
                                    kpBtn.Text = "[" .. ConvertKeyCodeToString(k) .. "]"
                                    Library:Tween(kpBtn, 0.15, { TextColor3 = Library.SubTextColor })
                                    Library:Tween(kpStroke, 0.15, { Color = Library.GlassBorderSoft, Transparency = 0.4 })
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
                row.ZIndex = 5
                row.Parent = container

                local titleLabel = Instance.new("TextLabel")
                titleLabel.Size = UDim2.new(0.7, 0, 0, 16)
                titleLabel.BackgroundTransparency = 1
                titleLabel.Font = Library.Font
                titleLabel.Text = text
                titleLabel.TextColor3 = Library.TextColor
                titleLabel.TextSize = 12
                titleLabel.TextXAlignment = Enum.TextXAlignment.Left
                titleLabel.ZIndex = 6
                titleLabel.Parent = row

                local valLabel = Instance.new("TextLabel")
                valLabel.Size = UDim2.new(0.3, 0, 0, 16)
                valLabel.Position = UDim2.new(0.7, 0, 0, 0)
                valLabel.BackgroundTransparency = 1
                valLabel.Font = Library.FontBold
                valLabel.Text = tostring(def) .. suffix
                valLabel.TextColor3 = Library.SubTextColor
                valLabel.TextSize = 11
                valLabel.TextXAlignment = Enum.TextXAlignment.Right
                valLabel.ZIndex = 6
                valLabel.Parent = row

                Library:RegisterText(titleLabel, false)
                Library:RegisterText(valLabel, true)
                Library:RegisterColor(titleLabel, "TextColor3", "TextColor")
                Library:RegisterColor(valLabel, "TextColor3", "SubTextColor")

                local track = Instance.new("TextButton")
                track.Size = UDim2.new(1, 0, 0, 6)
                track.Position = UDim2.new(0, 0, 0, 24)
                track.BackgroundColor3 = Library.GlassElement
                track.BackgroundTransparency = 0.15
                track.BorderSizePixel = 0
                track.Text = ""
                track.AutoButtonColor = false
                track.ClipsDescendants = false
                track.ZIndex = 6
                track.Parent = row

                Library:RegisterColor(track, "BackgroundColor3", "GlassElement")

                local tCorner = Instance.new("UICorner")
                tCorner.CornerRadius = UDim.new(1, 0)
                tCorner.Parent = track

                local tStroke = Instance.new("UIStroke")
                tStroke.Color = Library.GlassBorderSoft
                tStroke.Transparency = 0.4
                tStroke.Parent = track

                Library:RegisterColor(tStroke, "Color", "GlassBorderSoft")

                local initialRatio = math.clamp((def - min) / (max - min), 0, 1)

                local fill = Instance.new("Frame")
                fill.Size = UDim2.new(initialRatio, 0, 1, 0)
                fill.BackgroundColor3 = Library.Accent
                fill.BorderSizePixel = 0
                fill.ZIndex = 7
                fill.Parent = track

                Library:RegisterColor(fill, "BackgroundColor3", "Accent")
                Library:ApplyGradient(fill, { Library.AccentDeep, Library.Accent, Library.AccentSecondary }, 0, true)

                local fCorner = Instance.new("UICorner")
                fCorner.CornerRadius = UDim.new(1, 0)
                fCorner.Parent = fill

                local knob = Instance.new("Frame")
                knob.Name = "Knob"
                knob.Size = UDim2.new(0, 13, 0, 13)
                knob.AnchorPoint = Vector2.new(0.5, 0.5)
                knob.Position = UDim2.new(initialRatio, 0, 0.5, 0)
                knob.BackgroundColor3 = Color3.fromRGB(255, 255, 255)
                knob.BorderSizePixel = 0
                knob.ZIndex = 8
                knob.Parent = track

                local knobCorner = Instance.new("UICorner")
                knobCorner.CornerRadius = UDim.new(1, 0)
                knobCorner.Parent = knob

                local knobRing = Instance.new("UIStroke")
                knobRing.Color = Library.Accent
                knobRing.Thickness = 2
                knobRing.Parent = knob

                Library:RegisterColor(knobRing, "Color", "Accent")

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
                        Library:Tween(knob, 0.08, { Position = UDim2.new(ratio, 0, 0.5, 0) })
                        task.spawn(callback, val)
                    end
                }

                local isDragging = false
                track.InputBegan:Connect(function(input)
                    if input.UserInputType == Enum.UserInputType.MouseButton1 then
                        isDragging = true
                        Library:Tween(knob, 0.15, { Size = UDim2.new(0, 17, 0, 17) }, Enum.EasingStyle.Back, Enum.EasingDirection.Out)
                        Library:Tween(valLabel, 0.15, { TextColor3 = Library.Accent })
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
                    if input.UserInputType == Enum.UserInputType.MouseButton1 and isDragging then
                        isDragging = false
                        Library:Tween(knob, 0.2, { Size = UDim2.new(0, 13, 0, 13) }, Enum.EasingStyle.Back, Enum.EasingDirection.Out)
                        Library:Tween(valLabel, 0.2, { TextColor3 = Library.SubTextColor })
                    end
                end)
                table.insert(Library.Connections, releaseConn)

                if id then
                    Options[id] = SliderObj
                end

                return SliderObj
            end

            -- COMPLETELY FIXED & ANIMATED DROPDOWN
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
                row.ZIndex = 5
                row.Parent = container

                local titleLabel = Instance.new("TextLabel")
                titleLabel.Size = UDim2.new(1, 0, 0, 16)
                titleLabel.BackgroundTransparency = 1
                titleLabel.Font = Library.Font
                titleLabel.Text = text
                titleLabel.TextColor3 = Library.TextColor
                titleLabel.TextSize = 12
                titleLabel.TextXAlignment = Enum.TextXAlignment.Left
                titleLabel.ZIndex = 6
                titleLabel.Parent = row

                Library:RegisterText(titleLabel, false)
                Library:RegisterColor(titleLabel, "TextColor3", "TextColor")

                local mainBtn = Instance.new("TextButton")
                mainBtn.Size = UDim2.new(1, 0, 0, 26)
                mainBtn.Position = UDim2.new(0, 0, 0, 20)
                mainBtn.BackgroundColor3 = Library.GlassElement
                mainBtn.BackgroundTransparency = 0.22
                mainBtn.BorderSizePixel = 0
                mainBtn.Font = Library.Font
                mainBtn.Text = "   " .. tostring(def)
                mainBtn.TextColor3 = Library.TextColor
                mainBtn.TextSize = 11.5
                mainBtn.TextXAlignment = Enum.TextXAlignment.Left
                mainBtn.AutoButtonColor = false
                mainBtn.ZIndex = 6
                mainBtn.Parent = row

                Library:RegisterText(mainBtn, false)
                Library:RegisterColor(mainBtn, "BackgroundColor3", "GlassElement")
                Library:RegisterColor(mainBtn, "TextColor3", "TextColor")

                local bCorner = Instance.new("UICorner")
                bCorner.CornerRadius = UDim.new(0, 7)
                bCorner.Parent = mainBtn

                local bStroke = Instance.new("UIStroke")
                bStroke.Color = Library.GlassBorderSoft
                bStroke.Transparency = 0.25
                bStroke.Parent = mainBtn

                Library:RegisterColor(bStroke, "Color", "GlassBorderSoft")
                Library:AddGlassSurface(mainBtn, { ShineTransparency = 0.95, TopEdge = false })

                local arrow = Instance.new("TextLabel")
                arrow.Size = UDim2.new(0, 24, 1, 0)
                arrow.Position = UDim2.new(1, -24, 0, 0)
                arrow.BackgroundTransparency = 1
                arrow.Font = Library.FontBold
                arrow.Text = "v"
                arrow.TextColor3 = Library.SubTextColor
                arrow.TextSize = 10
                arrow.Rotation = 0
                arrow.ZIndex = 7
                arrow.Parent = mainBtn

                Library:RegisterText(arrow, true)
                Library:RegisterColor(arrow, "TextColor3", "SubTextColor")

                mainBtn.MouseEnter:Connect(function()
                    if Library.ActivePopup ~= listOuter then
                        Library:Tween(mainBtn, 0.15, { BackgroundTransparency = 0.1 })
                        Library:Tween(bStroke, 0.15, { Color = Library.GlassBorder })
                    end
                end)
                mainBtn.MouseLeave:Connect(function()
                    if Library.ActivePopup ~= listOuter then
                        Library:Tween(mainBtn, 0.15, { BackgroundTransparency = 0.22 })
                        Library:Tween(bStroke, 0.15, { Color = Library.GlassBorderSoft })
                    end
                end)

                -- Outer container (ClipsDescendants = false so Shadow renders outside cleanly)
                listOuter = Instance.new("Frame")
                listOuter.Name = "DropdownOverlay_" .. tostring(id)
                listOuter.Size = UDim2.new(0, 160, 0, 0)
                listOuter.BackgroundColor3 = Library.SolidPopup
                listOuter.BackgroundTransparency = 0.05
                listOuter.BorderSizePixel = 0
                listOuter.Visible = false
                listOuter.ClipsDescendants = false
                listOuter.ZIndex = 50
                listOuter.Parent = Library.PopupGui
                listOuter.OpenerBtn = mainBtn

                Library:RegisterColor(listOuter, "BackgroundColor3", "SolidPopup")

                local lCorner = Instance.new("UICorner")
                lCorner.CornerRadius = UDim.new(0, 8)
                lCorner.Parent = listOuter

                local lStroke = Instance.new("UIStroke")
                lStroke.Color = Library.GlassBorder
                lStroke.Thickness = 1.2
                lStroke.Transparency = 0.15
                lStroke.Parent = listOuter

                Library:RegisterColor(lStroke, "Color", "GlassBorder")
                Library:AddShadow(listOuter, { Transparency = 0.38, Spread = 28, YOffset = 6, ZIndex = 48 })
                Library:AddGlassSurface(listOuter, { ShineTransparency = 0.92, EdgeTransparency = 0.65 })

                -- Inner ScrollingFrame (ClipsDescendants = true and explicit high ZIndex so items are always visible!)
                local listScroll = Instance.new("ScrollingFrame")
                listScroll.Name = "ListScroll"
                listScroll.Size = UDim2.new(1, 0, 1, 0)
                listScroll.BackgroundTransparency = 1
                listScroll.BorderSizePixel = 0
                listScroll.ClipsDescendants = true
                listScroll.ScrollBarThickness = 3
                listScroll.ScrollBarImageColor3 = Library.Accent
                listScroll.ScrollBarImageTransparency = 0.25
                listScroll.CanvasSize = UDim2.new(0, 0, 0, 0)
                listScroll.ZIndex = 55
                listScroll.Parent = listOuter

                Library:RegisterColor(listScroll, "ScrollBarImageColor3", "Accent")

                local lPad = Instance.new("UIPadding")
                lPad.PaddingTop = UDim.new(0, 5)
                lPad.PaddingBottom = UDim.new(0, 5)
                lPad.PaddingLeft = UDim.new(0, 5)
                lPad.PaddingRight = UDim.new(0, 5)
                lPad.Parent = listScroll

                local lLayout = Instance.new("UIListLayout")
                lLayout.SortOrder = Enum.SortOrder.LayoutOrder
                lLayout.Padding = UDim.new(0, 3)
                lLayout.Parent = listScroll

                local optionButtons = {}

                local function RefreshOptionStyles(selectedValue)
                    for _, item in ipairs(optionButtons) do
                        local isSelected = (item.Value == selectedValue)
                        Library:Tween(item.Button, 0.15, {
                            BackgroundColor3 = isSelected and Library.Accent or Library.GlassElement,
                            BackgroundTransparency = isSelected and 0.82 or 1
                        })
                        Library:Tween(item.Label, 0.15, {
                            TextColor3 = isSelected and Library.Accent or Library.TextColor,
                            Position = isSelected and UDim2.new(0, 14, 0, 0) or UDim2.new(0, 9, 0, 0)
                        })
                        Library:Tween(item.Bar, 0.2, {
                            BackgroundTransparency = isSelected and 0 or 1,
                            Size = isSelected and UDim2.new(0, 3, 0, 12) or UDim2.new(0, 3, 0, 4)
                        }, Enum.EasingStyle.Back, Enum.EasingDirection.Out)
                    end
                end

                local DropdownObj = {
                    Value = def,
                    Values = values,
                    Type = "Dropdown",
                    SetValue = function(selfDd, val)
                        selfDd.Value = val
                        mainBtn.Text = "   " .. tostring(val)
                        RefreshOptionStyles(val)
                        task.spawn(callback, val)
                    end,
                    SetValues = function(selfDd, newVals)
                        selfDd.Values = newVals or {}
                        optionButtons = {}
                        for _, child in ipairs(listScroll:GetChildren()) do
                            if child:IsA("TextButton") then
                                child:Destroy()
                            end
                        end

                        for idx, opt in ipairs(selfDd.Values) do
                            local isSelected = (opt == selfDd.Value)

                            local optBtn = Instance.new("TextButton")
                            optBtn.Name = "Option_" .. tostring(opt)
                            optBtn.LayoutOrder = idx
                            optBtn.Size = UDim2.new(1, 0, 0, 24)
                            optBtn.BackgroundColor3 = isSelected and Library.Accent or Library.GlassElement
                            optBtn.BackgroundTransparency = isSelected and 0.82 or 1
                            optBtn.BorderSizePixel = 0
                            optBtn.Text = ""
                            optBtn.AutoButtonColor = false
                            optBtn.ZIndex = 56
                            optBtn.Parent = listScroll

                            local oCorner = Instance.new("UICorner")
                            oCorner.CornerRadius = UDim.new(0, 6)
                            oCorner.Parent = optBtn

                            local optBar = Instance.new("Frame")
                            optBar.Size = isSelected and UDim2.new(0, 3, 0, 12) or UDim2.new(0, 3, 0, 4)
                            optBar.Position = UDim2.new(0, 4, 0.5, 0)
                            optBar.AnchorPoint = Vector2.new(0, 0.5)
                            optBar.BackgroundColor3 = Library.Accent
                            optBar.BackgroundTransparency = isSelected and 0 or 1
                            optBar.BorderSizePixel = 0
                            optBar.ZIndex = 57
                            optBar.Parent = optBtn

                            local obCorner = Instance.new("UICorner")
                            obCorner.CornerRadius = UDim.new(1, 0)
                            obCorner.Parent = optBar

                            local optLabel = Instance.new("TextLabel")
                            optLabel.Size = UDim2.new(1, -18, 1, 0)
                            optLabel.Position = isSelected and UDim2.new(0, 14, 0, 0) or UDim2.new(0, 9, 0, 0)
                            optLabel.BackgroundTransparency = 1
                            optLabel.Font = Library.Font
                            optLabel.Text = tostring(opt)
                            optLabel.TextColor3 = isSelected and Library.Accent or Library.TextColor
                            optLabel.TextSize = 11.5
                            optLabel.TextXAlignment = Enum.TextXAlignment.Left
                            optLabel.TextTruncate = Enum.TextTruncate.AtEnd
                            optLabel.ZIndex = 57
                            optLabel.Parent = optBtn

                            table.insert(optionButtons, {
                                Value = opt,
                                Button = optBtn,
                                Label = optLabel,
                                Bar = optBar
                            })

                            optBtn.MouseEnter:Connect(function()
                                if selfDd.Value ~= opt then
                                    Library:Tween(optBtn, 0.14, {
                                        BackgroundColor3 = Library.GlassElementHover,
                                        BackgroundTransparency = 0.35
                                    })
                                    Library:Tween(optLabel, 0.14, {
                                        Position = UDim2.new(0, 12, 0, 0),
                                        TextColor3 = Library.TextColor
                                    })
                                end
                            end)

                            optBtn.MouseLeave:Connect(function()
                                if selfDd.Value ~= opt then
                                    Library:Tween(optBtn, 0.14, {
                                        BackgroundTransparency = 1
                                    })
                                    Library:Tween(optLabel, 0.14, {
                                        Position = UDim2.new(0, 9, 0, 0)
                                    })
                                end
                            end)

                            optBtn.MouseButton1Click:Connect(function()
                                Library:CreateRipple(optBtn, UserInputService:GetMouseLocation(), Library.Accent)
                                selfDd:SetValue(opt)
                                Library:CloseActivePopup()
                            end)
                        end

                        local totalContentH = (#selfDd.Values * 27) + 8
                        listScroll.CanvasSize = UDim2.new(0, 0, 0, totalContentH)
                    end
                }

                DropdownObj:SetValues(values)

                local function CloseDropdownAnimated()
                    Library:Tween(arrow, 0.2, { Rotation = 0, TextColor3 = Library.SubTextColor })
                    Library:Tween(bStroke, 0.2, { Color = Library.GlassBorderSoft, Transparency = 0.25 })
                    Library:Tween(listOuter, 0.18, {
                        Size = UDim2.new(0, mainBtn.AbsoluteSize.X, 0, 0),
                        BackgroundTransparency = 0.4
                    }, Enum.EasingStyle.Quart, Enum.EasingDirection.In)
                    task.delay(0.18, function()
                        if Library.ActivePopup ~= listOuter then
                            listOuter.Visible = false
                        end
                    end)
                end

                mainBtn.MouseButton1Click:Connect(function()
                    Library:CreateRipple(mainBtn, UserInputService:GetMouseLocation(), Library.Accent)
                    if listOuter.Visible and Library.ActivePopup == listOuter then
                        Library:CloseActivePopup()
                    else
                        Library:CloseActivePopup()
                        local absPos = mainBtn.AbsolutePosition
                        local btnWidth = mainBtn.AbsoluteSize.X
                        local itemCount = #DropdownObj.Values
                        local targetHeight = math.clamp((itemCount * 27) + 8, 34, 175)

                        listOuter.Position = UDim2.new(0, absPos.X, 0, absPos.Y + mainBtn.AbsoluteSize.Y + 5)
                        listOuter.Size = UDim2.new(0, btnWidth, 0, 0)
                        listOuter.BackgroundTransparency = 0.35
                        listOuter.Visible = true

                        RefreshOptionStyles(DropdownObj.Value)

                        -- Cascade Slide-in Animation for Dropdown Items
                        for idx, item in ipairs(optionButtons) do
                            item.Label.TextTransparency = 1
                            Library:Tween(item.Label, 0.18 + (idx * 0.02), { TextTransparency = 0 })
                        end

                        Library:Tween(arrow, 0.22, { Rotation = 180, TextColor3 = Library.Accent })
                        Library:Tween(bStroke, 0.22, { Color = Library.Accent, Transparency = 0.1 })
                        Library:Tween(listOuter, 0.24, {
                            Size = UDim2.new(0, btnWidth, 0, targetHeight),
                            BackgroundTransparency = 0.04
                        }, Enum.EasingStyle.Quart, Enum.EasingDirection.Out)

                        Library.ActivePopup = listOuter
                        Library.ActivePopupCloseCallback = CloseDropdownAnimated
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
                row.ZIndex = 5
                row.Parent = container

                local titleLabel = Instance.new("TextLabel")
                titleLabel.Size = UDim2.new(1, 0, 0, 16)
                titleLabel.BackgroundTransparency = 1
                titleLabel.Font = Library.Font
                titleLabel.Text = text
                titleLabel.TextColor3 = Library.TextColor
                titleLabel.TextSize = 12
                titleLabel.TextXAlignment = Enum.TextXAlignment.Left
                titleLabel.ZIndex = 6
                titleLabel.Parent = row

                Library:RegisterText(titleLabel, false)
                Library:RegisterColor(titleLabel, "TextColor3", "TextColor")

                local textBox = Instance.new("TextBox")
                textBox.Size = UDim2.new(1, 0, 0, 26)
                textBox.Position = UDim2.new(0, 0, 0, 20)
                textBox.BackgroundColor3 = Library.GlassElement
                textBox.BackgroundTransparency = 0.22
                textBox.BorderSizePixel = 0
                textBox.Font = Library.Font
                textBox.Text = def
                textBox.PlaceholderText = placeholder
                textBox.PlaceholderColor3 = Library.SubTextColor
                textBox.TextColor3 = Library.TextColor
                textBox.TextSize = 11.5
                textBox.ClearTextOnFocus = false
                textBox.ZIndex = 6
                textBox.Parent = row

                Library:RegisterText(textBox, false)
                Library:RegisterColor(textBox, "BackgroundColor3", "GlassElement")
                Library:RegisterColor(textBox, "TextColor3", "TextColor")
                Library:RegisterColor(textBox, "PlaceholderColor3", "SubTextColor")

                local tbCorner = Instance.new("UICorner")
                tbCorner.CornerRadius = UDim.new(0, 7)
                tbCorner.Parent = textBox

                local tbStroke = Instance.new("UIStroke")
                tbStroke.Color = Library.GlassBorderSoft
                tbStroke.Transparency = 0.25
                tbStroke.Parent = textBox

                Library:RegisterColor(tbStroke, "Color", "GlassBorderSoft")

                textBox.Focused:Connect(function()
                    Library:Tween(tbStroke, 0.2, { Color = Library.Accent, Transparency = 0, Thickness = 1.3 })
                    Library:Tween(textBox, 0.2, { BackgroundTransparency = 0.08 })
                end)
                textBox.FocusLost:Connect(function()
                    Library:Tween(tbStroke, 0.2, { Color = Library.GlassBorderSoft, Transparency = 0.25, Thickness = 1 })
                    Library:Tween(textBox, 0.2, { BackgroundTransparency = 0.22 })
                end)

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
                btn.Size = UDim2.new(1, 0, 0, 28)
                btn.BackgroundColor3 = Library.GlassElement
                btn.BackgroundTransparency = 0.22
                btn.BorderSizePixel = 0
                btn.Font = Library.Font
                btn.Text = text
                btn.TextColor3 = Library.TextColor
                btn.TextSize = 12
                btn.AutoButtonColor = false
                btn.ZIndex = 6
                btn.Parent = container

                Library:RegisterText(btn, false)
                Library:RegisterColor(btn, "BackgroundColor3", "GlassElement")
                Library:RegisterColor(btn, "TextColor3", "TextColor")

                local bCorner = Instance.new("UICorner")
                bCorner.CornerRadius = UDim.new(0, 7)
                bCorner.Parent = btn

                local bStroke = Instance.new("UIStroke")
                bStroke.Color = Library.GlassBorderSoft
                bStroke.Transparency = 0.25
                bStroke.Parent = btn

                Library:RegisterColor(bStroke, "Color", "GlassBorderSoft")
                Library:AddGlassSurface(btn, { ShineTransparency = 0.95, TopEdge = false })

                btn.MouseEnter:Connect(function()
                    Library:Tween(btn, 0.16, { BackgroundColor3 = Library.Accent, BackgroundTransparency = 0.1 })
                    Library:Tween(bStroke, 0.16, { Color = Library.Accent, Transparency = 0 })
                end)
                btn.MouseLeave:Connect(function()
                    Library:Tween(btn, 0.16, { BackgroundColor3 = Library.GlassElement, BackgroundTransparency = 0.22 })
                    Library:Tween(bStroke, 0.16, { Color = Library.GlassBorderSoft, Transparency = 0.25 })
                end)
                btn.MouseButton1Click:Connect(function()
                    Library:CreateRipple(btn, UserInputService:GetMouseLocation())
                    Library:Animate(btn, "Pop", UDim2.new(1, 0, 0, 28))
                    task.spawn(callback)
                end)

                return btn
            end

            function Groupbox:AddLabel(labelText)
                local row = Instance.new("Frame")
                row.Name = "LabelRow"
                row.Size = UDim2.new(1, 0, 0, 20)
                row.BackgroundTransparency = 1
                row.ZIndex = 5
                row.Parent = container

                local lbl = Instance.new("TextLabel")
                lbl.Size = UDim2.new(1, -50, 1, 0)
                lbl.BackgroundTransparency = 1
                lbl.Font = Library.Font
                lbl.Text = labelText
                lbl.TextColor3 = Library.SubTextColor
                lbl.TextSize = 12
                lbl.TextXAlignment = Enum.TextXAlignment.Left
                lbl.ZIndex = 6
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
                addonsContainer.ZIndex = 6
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
                        kpBtn.ZIndex = 7
                        kpBtn.Parent = addonsContainer

                        local kpCorner = Instance.new("UICorner")
                        kpCorner.CornerRadius = UDim.new(0, 4)
                        kpCorner.Parent = kpBtn

                        local kpStroke = Instance.new("UIStroke")
                        kpStroke.Color = Library.GlassBorderSoft
                        kpStroke.Transparency = 0.4
                        kpStroke.Parent = kpBtn

                        Library:RegisterText(kpBtn, false)
                        Library:RegisterColor(kpBtn, "BackgroundColor3", "GlassElement")

                        local listening = false
                        kpBtn.MouseButton1Click:Connect(function()
                            if listening then return end
                            listening = true
                            kpBtn.Text = "[...]"
                            Library:Tween(kpBtn, 0.15, { TextColor3 = Library.Accent })
                            Library:Tween(kpStroke, 0.15, { Color = Library.Accent, Transparency = 0 })

                            local tempConn
                            tempConn = UserInputService.InputBegan:Connect(function(input)
                                local k = ParseKeyInput(input)
                                if k then
                                    if k == Enum.KeyCode.Escape then k = "None" end
                                    KeyPickerObj.Value = k
                                    kpBtn.Text = "[" .. ConvertKeyCodeToString(k) .. "]"
                                    Library:Tween(kpBtn, 0.15, { TextColor3 = Library.SubTextColor })
                                    Library:Tween(kpStroke, 0.15, { Color = Library.GlassBorderSoft, Transparency = 0.4 })
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
    table.sort(themeNames)

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
