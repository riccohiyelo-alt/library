-- Bootstrap
local cloneref = cloneref or function(instance)
    return instance
end

local gethui = gethui or function()
    return cloneref(game:GetService("CoreGui"))
end

local executorName = "unknown"
pcall(function()
    executorName = string.lower(identifyexecutor())
end)

-- Dependencies
local Services = {
    Players = cloneref(game:GetService("Players")),
    TweenService = cloneref(game:GetService("TweenService")),
    UserInputService = cloneref(game:GetService("UserInputService")),
    RunService = cloneref(game:GetService("RunService")),
    Lighting = cloneref(game:GetService("Lighting")),
    Stats = cloneref(game:GetService("Stats")),
    TextService = cloneref(game:GetService("TextService")),
    HttpService = cloneref(game:GetService("HttpService")),
    MarketplaceService = cloneref(game:GetService("MarketplaceService")),
    Workspace = cloneref(game:GetService("Workspace")),
}

local FileApi = {
    makefolder = type(makefolder) == "function" and makefolder or nil,
    isfolder = type(isfolder) == "function" and isfolder or nil,
    writefile = type(writefile) == "function" and writefile or nil,
    readfile = type(readfile) == "function" and readfile or nil,
    isfile = type(isfile) == "function" and isfile or nil,
    listfiles = type(listfiles) == "function" and listfiles or nil,
    delfile = type(delfile) == "function" and delfile or nil,
}

-- Core helpers
local function getGlobalScope()
    if type(getgenv) == "function" then
        local ok, env = pcall(getgenv)
        if ok and type(env) == "table" then
            return env
        end
    end

    if type(_G) == "table" then
        return _G
    end

    return nil
end

local function cloneInstance(instance)
    if typeof(instance) == "Instance" then
        return cloneref(instance)
    end

    return instance
end

local function getCurrentCamera()
    return cloneInstance(Services.Workspace.CurrentCamera)
end

local function tryGetEnumItem(enumObject, itemName)
    local ok, item = pcall(function()
        return enumObject[itemName]
    end)

    if ok then
        return item
    end

    return nil
end

local function getViewportSize()
    local camera = getCurrentCamera()
    if camera then
        return camera.ViewportSize
    end

    return Vector2.new(1920, 1080)
end

local function disconnectConnection(connection)
    if typeof(connection) == "RBXScriptConnection" then
        pcall(function()
            connection:Disconnect()
        end)
    end
end

local function destroyInstance(instance)
    if typeof(instance) == "Instance" and instance.Parent then
        pcall(function()
            instance:Destroy()
        end)
    end
end

local function generateRuntimeName(prefix)
    local guid

    pcall(function()
        guid = Services.HttpService:GenerateGUID(false)
    end)

    if type(guid) == "string" and guid ~= "" then
        return string.format("%s_%s", prefix, guid:gsub("%-", ""))
    end

    return string.format("%s_%d", prefix, math.random(100000, 999999))
end

local LocalPlayer = cloneInstance(Services.Players.LocalPlayer)
local GlobalScope = getGlobalScope()
local RuntimeSingletonKey = "__NEVERPASTE_RUNTIME__"
local RuntimeHandle = {
    connections = {},
    viewportConnection = nil,
    gui = nil,
    blur = nil,
}

local function cleanupRuntimeHandle(handle)
    if type(handle) ~= "table" then
        return
    end

    if type(handle.connections) == "table" then
        for _, connection in ipairs(handle.connections) do
            disconnectConnection(connection)
        end
        table.clear(handle.connections)
    end

    disconnectConnection(handle.viewportConnection)
    handle.viewportConnection = nil

    destroyInstance(handle.gui)
    destroyInstance(handle.blur)
    handle.gui = nil
    handle.blur = nil
end

if GlobalScope and GlobalScope[RuntimeSingletonKey] then
    cleanupRuntimeHandle(GlobalScope[RuntimeSingletonKey])
end

if GlobalScope then
    GlobalScope[RuntimeSingletonKey] = RuntimeHandle
end

--if string.find(executorName, "solara") or string.find(executorName, "xeno") then
--    LocalPlayer:Kick("XENO AND SOLARA IS UNSUPPORTED BROTHER!!!")
--    return
--end

-- Theme and assets
local Theme = {
    outline = Color3.fromRGB(8, 15, 22),
    inline = Color3.fromRGB(20, 34, 46),
    high = Color3.fromRGB(35, 67, 84),
    low = Color3.fromRGB(20, 43, 58),
    section = Color3.fromRGB(37, 96, 152),
    sectionHigh = Color3.fromRGB(63, 132, 194),
    sectionLow = Color3.fromRGB(25, 68, 115),
    accent = Color3.fromRGB(72, 166, 214),
    text = Color3.fromRGB(225, 236, 242),
    textDim = Color3.fromRGB(152, 176, 188),
    accentGlow = Color3.fromRGB(108, 203, 255),
}

local IconAssets = {
    search = "rbxassetid://10734943674",
    settings = "rbxassetid://10734950309",
    target = "rbxassetid://10734977012",
    eye = "rbxassetid://10723346959",
    info = "rbxassetid://10723415903",
    code = "rbxassetid://10709810463",
}
IconAssets.file = IconAssets.code

local TabIcons = {
    main = IconAssets.target,
    visuals = IconAssets.eye,
    ui = IconAssets.code,
}

local RootGui = cloneInstance(gethui())
local OldGui = cloneInstance(RootGui:FindFirstChild("NeverPasteUI"))
if OldGui then
    OldGui:Destroy()
end

local OldBlur = cloneInstance(Services.Lighting:FindFirstChild("NeverPasteBlur"))
if OldBlur then
    OldBlur:Destroy()
end

local ThemeRegistry = {
    outline = {},
    inline = {},
    section = {},
    accent = {},
    text = {},
    textDim = {},
    contrast = {},
    sectionContrast = {},
}

local function trackRuntimeConnection(connection)
    if typeof(connection) == "RBXScriptConnection" then
        RuntimeHandle.connections[#RuntimeHandle.connections + 1] = connection
    end

    return connection
end

-- UI primitives
local function create(className, properties)
    local instance = Instance.new(className)

    for property, value in pairs(properties or {}) do
        if property ~= "Parent" then
            instance[property] = value
        end
    end

    if properties and properties.Parent then
        instance.Parent = properties.Parent
    end

    return instance
end

local function tween(instance, duration, properties, style, direction)
    local animation = Services.TweenService:Create(
        instance,
        TweenInfo.new(duration, style or Enum.EasingStyle.Quart, direction or Enum.EasingDirection.Out),
        properties
    )

    animation:Play()
    return animation
end

local function applyCorner(instance, radius)
    create("UICorner", {
        Parent = instance,
        CornerRadius = UDim.new(0, radius),
    })
end

local function applyStroke(instance, color, thickness, transparency)
    return create("UIStroke", {
        Parent = instance,
        Color = color,
        Thickness = thickness or 1,
        Transparency = transparency or 0,
    })
end

local function applyGradient(instance, colorA, colorB, rotation)
    return create("UIGradient", {
        Parent = instance,
        Rotation = rotation or 0,
        Color = ColorSequence.new({
            ColorSequenceKeypoint.new(0, colorA),
            ColorSequenceKeypoint.new(1, colorB),
        }),
    })
end

local function registerTheme(kind, instance, property)
    table.insert(ThemeRegistry[kind], {
        instance = instance,
        property = property,
    })
end

local function createThemedText(parent, props, dimmed)
    local label = create("TextLabel", props)
    label.TextColor3 = dimmed and Theme.textDim or Theme.text
    registerTheme(dimmed and "textDim" or "text", label, "TextColor3")
    create("UIStroke", {
        Parent = label,
        Transparency = 0.75,
        Thickness = 1,
        LineJoinMode = Enum.LineJoinMode.Miter,
    })
    return label
end

local function refreshTheme()
    for _, entry in ipairs(ThemeRegistry.outline) do
        if entry.instance.Parent then
            entry.instance[entry.property] = Theme.outline
        end
    end

    for _, entry in ipairs(ThemeRegistry.inline) do
        if entry.instance.Parent then
            entry.instance[entry.property] = Theme.inline
        end
    end

    for _, entry in ipairs(ThemeRegistry.section) do
        if entry.instance.Parent then
            entry.instance[entry.property] = Theme.section
        end
    end

    for _, entry in ipairs(ThemeRegistry.accent) do
        if entry.instance.Parent then
            entry.instance[entry.property] = Theme.accent
        end
    end

    for _, entry in ipairs(ThemeRegistry.text) do
        if entry.instance.Parent then
            entry.instance[entry.property] = Theme.text
        end
    end

    for _, entry in ipairs(ThemeRegistry.textDim) do
        if entry.instance.Parent then
            entry.instance[entry.property] = Theme.textDim
        end
    end

    local sequence = ColorSequence.new({
        ColorSequenceKeypoint.new(0, Theme.high),
        ColorSequenceKeypoint.new(1, Theme.low),
    })

    for _, entry in ipairs(ThemeRegistry.contrast) do
        if entry.instance.Parent then
            entry.instance[entry.property] = sequence
        end
    end

    local sectionSequence = ColorSequence.new({
        ColorSequenceKeypoint.new(0, Theme.sectionHigh),
        ColorSequenceKeypoint.new(1, Theme.sectionLow),
    })

    for _, entry in ipairs(ThemeRegistry.sectionContrast) do
        if entry.instance.Parent then
            entry.instance[entry.property] = sectionSequence
        end
    end
end

local function addShell(parent, size, position, accentTop, radius, zindex)
    local outline = create("Frame", {
        Parent = parent,
        BorderSizePixel = 0,
        BackgroundColor3 = Theme.outline,
        Size = size,
        Position = position or UDim2.fromOffset(0, 0),
        ZIndex = zindex or 1,
    })
    registerTheme("outline", outline, "BackgroundColor3")

    local inline = create("Frame", {
        Parent = outline,
        BorderSizePixel = 0,
        BackgroundColor3 = Theme.inline,
        Position = UDim2.fromOffset(1, 1),
        Size = UDim2.new(1, -2, 1, -2),
        ZIndex = (zindex or 1) + 1,
    })
    registerTheme("inline", inline, "BackgroundColor3")

    local background = create("Frame", {
        Parent = inline,
        BorderSizePixel = 0,
        BackgroundColor3 = Theme.low,
        Position = UDim2.fromOffset(1, 1),
        Size = UDim2.new(1, -2, 1, -2),
        ZIndex = (zindex or 1) + 2,
    })

    local contrast = applyGradient(background, Theme.high, Theme.low, 90)
    registerTheme("contrast", contrast, "Color")

    if radius and radius > 0 then
        applyCorner(outline, radius)
        applyCorner(inline, radius)
        applyCorner(background, radius)
    end

    local accent
    local accentHighlight

    if accentTop then
        accent = create("Frame", {
            Parent = outline,
            BorderSizePixel = 0,
            BackgroundColor3 = Theme.accent,
            Position = UDim2.fromOffset(2, 2),
            Size = UDim2.new(1, -4, 0, 2),
            ZIndex = (zindex or 1) + 3,
        })
        registerTheme("accent", accent, "BackgroundColor3")
        accentHighlight = applyGradient(accent, Color3.fromRGB(255, 255, 255), Color3.fromRGB(170, 170, 170), 90)
    end

    return {
        outline = outline,
        inline = inline,
        background = background,
        accent = accent,
        accentHighlight = accentHighlight,
    }
end

local MouseButtons = {
    left = tryGetEnumItem(Enum.UserInputType, "MouseButton1"),
    right = tryGetEnumItem(Enum.UserInputType, "MouseButton2"),
    middle = tryGetEnumItem(Enum.UserInputType, "MouseButton3"),
}

local function bindToText(bind)
    if typeof(bind) ~= "EnumItem" then
        return "NONE"
    end

    local map = {
        [Enum.KeyCode.Insert] = "INS",
        [Enum.KeyCode.RightShift] = "RSHIFT",
        [Enum.KeyCode.LeftShift] = "LSHIFT",
        [Enum.KeyCode.Backspace] = "BSP",
        [Enum.KeyCode.Space] = "SPACE",
        [Enum.KeyCode.Escape] = "ESC",
    }

    if MouseButtons.left then
        map[MouseButtons.left] = "M1"
    end

    if MouseButtons.right then
        map[MouseButtons.right] = "M2"
    end

    if MouseButtons.middle then
        map[MouseButtons.middle] = "M3"
    end

    return map[bind] or string.upper(bind.Name)
end

local function formatToggleBindText(entry)
    if not entry or entry.kind ~= "toggle" then
        return "NONE"
    end

    if entry.mode == "always" then
        return "ALWAYS"
    end

    return bindToText(entry.bind)
end

local function inputMatchesBind(bind, input)
    if typeof(bind) ~= "EnumItem" then
        return false
    end

    if bind.EnumType == Enum.KeyCode then
        return input.KeyCode == bind
    end

    return input.UserInputType == bind
end

local function getBindableMouseInput(input)
    local inputType = input and input.UserInputType
    if inputType == MouseButtons.left
        or inputType == MouseButtons.right
        or inputType == MouseButtons.middle then
        return inputType
    end

    return nil
end

local function isInsideGui(guiObject, position)
    if not guiObject or not guiObject.Parent then
        return false
    end

    local guiPosition = guiObject.AbsolutePosition
    local guiSize = guiObject.AbsoluteSize

    return position.X >= guiPosition.X
        and position.X <= guiPosition.X + guiSize.X
        and position.Y >= guiPosition.Y
        and position.Y <= guiPosition.Y + guiSize.Y
end

local function getPing()
    local network = cloneInstance(Services.Stats:FindFirstChild("Network"))
    local serverStats = network and cloneInstance(network:FindFirstChild("ServerStatsItem"))
    local candidates = {}

    if serverStats then
        table.insert(candidates, cloneInstance(serverStats:FindFirstChild("Data Ping")))
        table.insert(candidates, cloneInstance(serverStats:FindFirstChild("Ping")))
    end

    if network then
        for _, item in ipairs(network:GetDescendants()) do
            if item.Name and string.find(string.lower(item.Name), "ping", 1, true) then
                table.insert(candidates, cloneInstance(item))
            end
        end
    end

    for _, pingItem in ipairs(candidates) do
        if pingItem and pingItem.GetValueString then
            local ok, value = pcall(function()
                return pingItem:GetValueString()
            end)

            if ok and value then
                local number = tonumber((value:gsub("[^%d%.]", "")))
                if number then
                    return math.floor(number)
                end
            end
        end
    end

    return 0
end

-- Root bootstrap
local placeName = game.Name
task.spawn(function()
    pcall(function()
        local info = Services.MarketplaceService:GetProductInfo(game.PlaceId)
        if info and info.Name then
            placeName = info.Name
        end
    end)
end)

local ScreenGui = create("ScreenGui", {
    Parent = RootGui,
    Name = generateRuntimeName("NeverPasteUI"),
    ResetOnSpawn = false,
    ZIndexBehavior = Enum.ZIndexBehavior.Sibling,
    IgnoreGuiInset = true,
    DisplayOrder = 999999,
})
RuntimeHandle.gui = ScreenGui

local CachedViewportSize = Vector2.new(1920, 1080)
local CameraViewportConnection

local function refreshViewportSize()
    local camera = getCurrentCamera()
    if camera then
        CachedViewportSize = camera.ViewportSize
    end
end

local function attachViewportListener()
    if CameraViewportConnection then
        disconnectConnection(CameraViewportConnection)
        CameraViewportConnection = nil
        RuntimeHandle.viewportConnection = nil
    end

    local camera = getCurrentCamera()
    if camera then
        CachedViewportSize = camera.ViewportSize
        CameraViewportConnection = camera:GetPropertyChangedSignal("ViewportSize"):Connect(refreshViewportSize)
        RuntimeHandle.viewportConnection = CameraViewportConnection
    end
end

trackRuntimeConnection(Services.Workspace:GetPropertyChangedSignal("CurrentCamera"):Connect(attachViewportListener))
attachViewportListener()

local Blur
local Intro
local IntroStart
local IntroStartScale
local IntroGlyphs = {}

local function measureText(text, font, textSize, maxWidth)
    return Services.TextService:GetTextSize(text, textSize, font, Vector2.new(maxWidth or 1000, 1000))
end

do
    local function measureIntroText(text, font, textSize)
        return measureText(text, font, textSize)
    end

    Blur = create("BlurEffect", {
        Parent = Services.Lighting,
        Name = generateRuntimeName("NeverPasteBlur"),
        Size = 0,
    })
    RuntimeHandle.blur = Blur

    Intro = create("Frame", {
        Parent = ScreenGui,
        Size = UDim2.fromScale(1, 1),
        BackgroundColor3 = Color3.fromRGB(0, 0, 0),
        BackgroundTransparency = 1,
        ZIndex = 100,
    })

    applyGradient(Intro, Color3.fromRGB(8, 10, 20), Color3.fromRGB(17, 12, 31), 135)

    local introLetters = create("Frame", {
        Parent = Intro,
        BackgroundTransparency = 1,
        AnchorPoint = Vector2.new(0.5, 0.5),
        Position = UDim2.fromScale(0.5, 0.5),
        Size = UDim2.new(1, -80, 0, 100),
        ZIndex = 101,
    })

    create("UIListLayout", {
        Parent = introLetters,
        FillDirection = Enum.FillDirection.Horizontal,
        HorizontalAlignment = Enum.HorizontalAlignment.Center,
        VerticalAlignment = Enum.VerticalAlignment.Center,
        SortOrder = Enum.SortOrder.LayoutOrder,
        Padding = UDim.new(0, 2),
    })

    local introStartBounds = measureIntroText("N", Enum.Font.GothamBold, 72)
    IntroStart = create("TextLabel", {
        Parent = Intro,
        BackgroundTransparency = 1,
        AnchorPoint = Vector2.new(0.5, 0.5),
        Position = UDim2.fromScale(0.5, 0.5),
        Size = UDim2.fromOffset(introStartBounds.X + 100, 74),
        Font = Enum.Font.GothamBold,
        Text = "N",
        TextColor3 = Theme.text,
        TextSize = 72,
        TextWrapped = true,
        TextTransparency = 1,
        TextXAlignment = Enum.TextXAlignment.Center,
        ZIndex = 102,
    })

    applyGradient(IntroStart, Color3.fromRGB(112, 148, 255), Color3.fromRGB(170, 102, 255), 90)
    IntroStartScale = create("UIScale", {
        Parent = IntroStart,
        Scale = 4.25,
    })

    local introWidthAdjust = {}
    local introLetterPadding = 8

    for index = 1, #"NeverPaste" do
        local character = string.sub("NeverPaste", index, index)
        local glyphBounds = measureIntroText(character, Enum.Font.GothamBold, 72)
        local holder = create("Frame", {
            Parent = introLetters,
            BackgroundTransparency = 1,
            Size = UDim2.fromOffset(glyphBounds.X + introLetterPadding + (introWidthAdjust[character] or 0), 100),
            LayoutOrder = index,
            ZIndex = 101,
        })

        local glyph = create("TextLabel", {
            Parent = holder,
            BackgroundTransparency = 1,
            AnchorPoint = Vector2.new(0.5, 0.5),
            Position = index == 1 and UDim2.new(0.5, 0, 0.5, 0) or UDim2.new(0.5, 0, 0.5, 200),
            Size = UDim2.fromOffset(glyphBounds.X + 100, 74),
            Font = Enum.Font.GothamBold,
            Text = character,
            TextColor3 = Theme.text,
            TextSize = 72,
            TextWrapped = true,
            TextTransparency = 1,
            TextXAlignment = Enum.TextXAlignment.Center,
            ZIndex = 101,
        })

        applyGradient(
            glyph,
            index <= 5 and Color3.fromRGB(118, 154, 255) or Color3.fromRGB(220, 226, 255),
            index <= 5 and Color3.fromRGB(162, 108, 255) or Color3.fromRGB(160, 118, 255),
            90
        )

        IntroGlyphs[index] = {
            holder = holder,
            glyph = glyph,
        }
    end
end

-- Runtime state
local MenuState = {
    toggleBind = Enum.KeyCode.Insert,
    visible = true,
    introDone = false,
    searchOpen = false,
    infoOpen = false,
    settingsOpen = false,
    listeningKeybindEntry = nil,
    bindPopupEntry = nil,
    bindPopupCurrent = nil,
    bindPopupListening = false,
}

local PickerRuntime = {
    openEntry = nil,
    isOpen = false,
    mode = nil,
}

local StatsState = {
    currentFps = 0,
    currentPing = getPing(),
    fpsFrames = 0,
    fpsElapsed = 0,
    lastWatermarkTextUpdate = 0,
    watermarkWidth = 140,
}

local MenuMotion = {
    tweens = {},
    connections = {},
    holdEntries = {},
}

local WindowMinSize = Vector2.new(600, 430)
local DefaultWindowPosition = UDim2.new(0.5, -96, 0.5, -16)
local MenuHiddenOffset = Vector2.new(0, 14)
local MenuShowStartScale = 0.945
local MenuHideEndScale = 0.965

local Runtime = {
    initialized = false,
    title = "NeverPaste",
    info = "Right click toggles to assign binds.\nUse search to jump between controls quickly.",
    showWatermark = true,
    showKeybindList = true,
}

local supportsConfigFiles

local ConfigSystem = {
    enabled = true,
    supported = FileApi.makefolder ~= nil
        and FileApi.writefile ~= nil
        and FileApi.readfile ~= nil
        and FileApi.listfiles ~= nil
        and FileApi.delfile ~= nil,
    directory = "NeverPaste",
    folder = "NeverPaste/configs",
    menuBuilt = false,
    buildToken = 0,
    windowObject = nil,
    selectedName = nil,
    syncing = false,
    buttonsBound = false,
    rows = {},
    button = nil,
    shell = nil,
    results = nil,
    inputBox = nil,
    emptyLabel = nil,
    deleteButton = nil,
    deleteLabel = nil,
    deleteConfirmName = nil,
}

local refreshRows
local updateWatermark

local DropdownPanel = {
    entry = nil,
    rows = {},
}

local SettingsPanel = {
    bindListening = false,
}

local PickerState = {
    target = nil,
    h = 0,
    s = 1,
    v = 1,
}

local Tabs = {}
local Sections = {}
local TabDefinitions = {}
local Entries = {}
local EntryMap = {}
local CreatedSubsectionHeaders = {}
local ModeButtons = {}

-- Public API tables
local Atlanta = {}
Atlanta.__index = Atlanta

local WindowMethods = {}
WindowMethods.__index = WindowMethods

local MenuMethods = {}
MenuMethods.__index = MenuMethods

local SectionMethods = {}
SectionMethods.__index = SectionMethods

local ControlMethods = {}
ControlMethods.__index = ControlMethods

-- Forward declarations
local DefaultTabId
local CurrentTab
local Panels = {}
local Layout = {}
local Render = {}
local Motion = {}
local WindowLifecycle = {}
local ConfigOps = {}

-- Shell and overlay assembly
local WindowShell = addShell(ScreenGui, UDim2.fromOffset(658, 476), UDim2.fromOffset(0, 0), true, 0, 10)
local Window = WindowShell.outline
Window.AnchorPoint = Vector2.new(0.5, 0.5)
Window.Position = DefaultWindowPosition
Window.Visible = false
Window.BackgroundTransparency = 1

local WindowScale = create("UIScale", {
    Parent = Window,
    Scale = 1,
})

local WindowRestPosition = DefaultWindowPosition

WindowShell.resizeHandle = create("TextButton", {
    Parent = Window,
    AnchorPoint = Vector2.new(1, 1),
    Position = UDim2.new(1, 6, 1, 4),
    Size = UDim2.fromOffset(14, 14),
    BackgroundTransparency = 1,
    BorderSizePixel = 0,
    Text = "",
    AutoButtonColor = false,
    ZIndex = 18,
})

do
    local resizeLineA = create("Frame", {
        Parent = WindowShell.resizeHandle,
        AnchorPoint = Vector2.new(1, 1),
        Position = UDim2.new(1, 0, 1, 0),
        Size = UDim2.fromOffset(10, 2),
        BackgroundColor3 = Theme.textDim,
        BorderSizePixel = 0,
        Rotation = -45,
        ZIndex = 19,
    })
    registerTheme("textDim", resizeLineA, "BackgroundColor3")

    local resizeLineB = create("Frame", {
        Parent = WindowShell.resizeHandle,
        AnchorPoint = Vector2.new(1, 1),
        Position = UDim2.new(1, -3, 1, 0),
        Size = UDim2.fromOffset(6, 2),
        BackgroundColor3 = Theme.textDim,
        BorderSizePixel = 0,
        Rotation = -45,
        ZIndex = 19,
    })
    registerTheme("textDim", resizeLineB, "BackgroundColor3")
end

WindowShell.header = create("Frame", {
    Parent = WindowShell.background,
    BackgroundTransparency = 1,
    Size = UDim2.new(1, -12, 0, 20),
    Position = UDim2.fromOffset(6, 4),
    ZIndex = 14,
})

WindowShell.titleLabel = createThemedText(WindowShell.header, {
    Parent = WindowShell.header,
    BackgroundTransparency = 1,
    Position = UDim2.fromOffset(2, 0),
    Size = UDim2.new(0, 220, 1, 0),
    Font = Enum.Font.GothamBold,
    Text = "NeverPaste",
    TextSize = 12,
    TextXAlignment = Enum.TextXAlignment.Left,
    TextYAlignment = Enum.TextYAlignment.Center,
    ZIndex = 14,
}, false)

WindowShell.titleRightLabel = createThemedText(WindowShell.header, {
    Parent = WindowShell.header,
    BackgroundTransparency = 1,
    AnchorPoint = Vector2.new(1, 0),
    Position = UDim2.new(1, -24, 0, 0),
    Size = UDim2.new(0, 216, 1, 0),
    Font = Enum.Font.GothamMedium,
    Text = "menu bind: " .. bindToText(MenuState.toggleBind),
    TextSize = 12,
    TextXAlignment = Enum.TextXAlignment.Right,
    ZIndex = 14,
}, true)

WindowShell.settingsButton = create("ImageButton", {
    Parent = WindowShell.header,
    AnchorPoint = Vector2.new(1, 0.5),
    Position = UDim2.new(1, 0, 0.5, 0),
    Size = UDim2.fromOffset(16, 16),
    BackgroundTransparency = 1,
    BorderSizePixel = 0,
    Image = IconAssets.settings,
    ImageColor3 = Theme.textDim,
    AutoButtonColor = false,
    ZIndex = 15,
})
registerTheme("textDim", WindowShell.settingsButton, "ImageColor3")

local TabHolder = create("Frame", {
    Parent = WindowShell.background,
    BackgroundTransparency = 1,
    Position = UDim2.fromOffset(6, 22),
    Size = UDim2.new(1, -12, 0, 22),
    ZIndex = 14,
})

create("UIListLayout", {
    Parent = TabHolder,
    FillDirection = Enum.FillDirection.Horizontal,
    Padding = UDim.new(0, 2),
    SortOrder = Enum.SortOrder.LayoutOrder,
})

local ContentShell = addShell(WindowShell.background, UDim2.new(1, -12, 1, -72), UDim2.fromOffset(6, 44), false, 0, 12)

create("UIPadding", {
    Parent = ContentShell.background,
    PaddingTop = UDim.new(0, 4),
    PaddingBottom = UDim.new(0, 4),
    PaddingLeft = UDim.new(0, 4),
    PaddingRight = UDim.new(0, 4),
})
ContentShell.background.ClipsDescendants = true

local ConfigButton
local SearchButton
local InfoButton
do
    local bottomBar = create("Frame", {
        Parent = WindowShell.background,
        BackgroundTransparency = 1,
        Position = UDim2.new(0, 6, 1, -22),
        Size = UDim2.new(1, -12, 0, 16),
        ZIndex = 14,
    })

    ConfigButton = create("ImageButton", {
        Parent = bottomBar,
        BackgroundTransparency = 1,
        BorderSizePixel = 0,
        Position = UDim2.fromOffset(0, 0),
        Size = UDim2.fromOffset(16, 16),
        Image = IconAssets.file,
        ImageColor3 = Theme.textDim,
        AutoButtonColor = false,
        ZIndex = 15,
    })
    registerTheme("textDim", ConfigButton, "ImageColor3")

    SearchButton = create("ImageButton", {
        Parent = bottomBar,
        BackgroundTransparency = 1,
        BorderSizePixel = 0,
        Position = UDim2.fromOffset(22, 0),
        Size = UDim2.fromOffset(16, 16),
        Image = IconAssets.search,
        ImageColor3 = Theme.textDim,
        AutoButtonColor = false,
        ZIndex = 15,
    })
    registerTheme("textDim", SearchButton, "ImageColor3")

    InfoButton = create("ImageButton", {
        Parent = bottomBar,
        AnchorPoint = Vector2.new(1, 0),
        BackgroundTransparency = 1,
        BorderSizePixel = 0,
        Position = UDim2.new(1, 0, 0, 0),
        Size = UDim2.fromOffset(16, 16),
        Image = IconAssets.info,
        ImageColor3 = Theme.textDim,
        AutoButtonColor = false,
        ZIndex = 15,
    })
    registerTheme("textDim", InfoButton, "ImageColor3")
end

local SearchShell = addShell(WindowShell.background, UDim2.fromOffset(300, 290), UDim2.new(0, 8, 1, -320), false, 0, 40)
SearchShell.outline.Visible = false

do
    local searchBoxShell = addShell(SearchShell.background, UDim2.new(1, -18, 0, 22), UDim2.fromOffset(9, 9), false, 0, 42)
    SearchShell.input = create("TextBox", {
        Parent = searchBoxShell.background,
        BackgroundTransparency = 1,
        Position = UDim2.fromOffset(6, 0),
        Size = UDim2.new(1, -12, 1, 0),
        ClearTextOnFocus = false,
        Font = Enum.Font.GothamMedium,
        PlaceholderText = "Search name, path or tag",
        PlaceholderColor3 = Theme.textDim,
        Text = "",
        TextColor3 = Theme.text,
        TextSize = 12,
        TextXAlignment = Enum.TextXAlignment.Left,
        ZIndex = 44,
    })
end
registerTheme("text", SearchShell.input, "TextColor3")
registerTheme("textDim", SearchShell.input, "PlaceholderColor3")

SearchShell.results = create("ScrollingFrame", {
    Parent = SearchShell.background,
    BackgroundTransparency = 1,
    BorderSizePixel = 0,
    Position = UDim2.fromOffset(9, 38),
    Size = UDim2.new(1, -18, 1, -47),
    CanvasSize = UDim2.fromOffset(0, 0),
    ScrollBarImageColor3 = Theme.accent,
    ScrollBarThickness = 4,
    TopImage = "",
    BottomImage = "",
    MidImage = "",
    ZIndex = 43,
})
registerTheme("accent", SearchShell.results, "ScrollBarImageColor3")

do
    local searchResultsLayout = create("UIListLayout", {
        Parent = SearchShell.results,
        FillDirection = Enum.FillDirection.Vertical,
        Padding = UDim.new(0, 4),
        SortOrder = Enum.SortOrder.LayoutOrder,
    })

    searchResultsLayout:GetPropertyChangedSignal("AbsoluteContentSize"):Connect(function()
        SearchShell.results.CanvasSize = UDim2.fromOffset(0, searchResultsLayout.AbsoluteContentSize.Y)
    end)
end

SearchShell.emptyLabel = createThemedText(SearchShell.background, {
    Parent = SearchShell.background,
    BackgroundTransparency = 1,
    Position = UDim2.fromOffset(16, 46),
    Size = UDim2.new(1, -32, 0, 16),
    Font = Enum.Font.GothamMedium,
    Text = "No results found",
    TextSize = 12,
    TextXAlignment = Enum.TextXAlignment.Left,
    Visible = false,
    ZIndex = 44,
}, true)

do
    local shell = addShell(ScreenGui, UDim2.fromOffset(172, 24), UDim2.fromOffset(0, 0), false, 0, 48)
    shell.outline.Visible = false
    shell.outline.ClipsDescendants = true

    local list = create("ScrollingFrame", {
        Parent = shell.background,
        BackgroundTransparency = 1,
        BorderSizePixel = 0,
        Position = UDim2.fromOffset(4, 4),
        Size = UDim2.new(1, -8, 1, -8),
        CanvasSize = UDim2.fromOffset(0, 0),
        ScrollBarImageColor3 = Theme.accent,
        ScrollBarThickness = 4,
        TopImage = "",
        BottomImage = "",
        MidImage = "",
        ZIndex = 49,
    })
    registerTheme("accent", list, "ScrollBarImageColor3")

    create("UIListLayout", {
        Parent = list,
        FillDirection = Enum.FillDirection.Vertical,
        Padding = UDim.new(0, 2),
        SortOrder = Enum.SortOrder.LayoutOrder,
    })

    DropdownPanel.shell = shell
    DropdownPanel.list = list
end

local SettingsShell = addShell(WindowShell.background, UDim2.fromOffset(168, 114), UDim2.new(1, -174, 0, 26), false, 0, 40)
SettingsShell.outline.Visible = false

createThemedText(SettingsShell.background, {
    Parent = SettingsShell.background,
    BackgroundTransparency = 1,
    Position = UDim2.fromOffset(8, 6),
    Size = UDim2.new(1, -16, 0, 14),
    Font = Enum.Font.GothamMedium,
    Text = "Quick Settings",
    TextSize = 12,
    TextXAlignment = Enum.TextXAlignment.Left,
    ZIndex = 44,
}, false)

do
    local settingsHolder = create("Frame", {
        Parent = SettingsShell.background,
        BackgroundTransparency = 1,
        Position = UDim2.fromOffset(8, 26),
        Size = UDim2.new(1, -16, 1, -34),
        ZIndex = 43,
    })

    create("UIListLayout", {
        Parent = settingsHolder,
        FillDirection = Enum.FillDirection.Vertical,
        Padding = UDim.new(0, 4),
        SortOrder = Enum.SortOrder.LayoutOrder,
    })

    local function createMiniToggleRow(labelText, getter, setter)
        local row = create("TextButton", {
            Parent = settingsHolder,
            BackgroundTransparency = 1,
            BorderSizePixel = 0,
            Size = UDim2.new(1, 0, 0, 18),
            Text = "",
            AutoButtonColor = false,
            ZIndex = 44,
        })

        local label = createThemedText(row, {
            Parent = row,
            BackgroundTransparency = 1,
            Position = UDim2.fromOffset(0, 0),
            Size = UDim2.new(1, -22, 1, 0),
            Font = Enum.Font.GothamMedium,
            Text = labelText,
            TextSize = 12,
            TextXAlignment = Enum.TextXAlignment.Left,
            ZIndex = 45,
        }, false)

        local toggleShell = addShell(row, UDim2.fromOffset(14, 14), UDim2.new(1, -14, 0.5, -7), false, 0, 45)
        local fill = create("Frame", {
            Parent = toggleShell.background,
            BorderSizePixel = 0,
            BackgroundColor3 = Theme.accent,
            Position = UDim2.fromOffset(1, 1),
            Size = UDim2.new(1, -2, 1, -2),
            BackgroundTransparency = 1,
            ZIndex = 47,
        })
        registerTheme("accent", fill, "BackgroundColor3")

        row.MouseButton1Click:Connect(function()
            setter(not getter())
        end)

        return {
            kind = "toggle",
            row = row,
            label = label,
            fill = fill,
            get = getter,
        }
    end

    local bindRow = create("TextButton", {
        Parent = settingsHolder,
        BackgroundTransparency = 1,
        BorderSizePixel = 0,
        Size = UDim2.new(1, 0, 0, 18),
        Text = "",
        AutoButtonColor = false,
        ZIndex = 44,
    })

    local bindLabel = createThemedText(bindRow, {
        Parent = bindRow,
        BackgroundTransparency = 1,
        Position = UDim2.fromOffset(0, 0),
        Size = UDim2.new(1, -56, 1, 0),
        Font = Enum.Font.GothamMedium,
        Text = "Menu Bind",
        TextSize = 12,
        TextXAlignment = Enum.TextXAlignment.Left,
        ZIndex = 45,
    }, false)

    local bindValue = createThemedText(bindRow, {
        Parent = bindRow,
        BackgroundTransparency = 1,
        AnchorPoint = Vector2.new(1, 0),
        Position = UDim2.new(1, 0, 0, 0),
        Size = UDim2.fromOffset(54, 18),
        Font = Enum.Font.Code,
        Text = "NONE",
        TextSize = 11,
        TextXAlignment = Enum.TextXAlignment.Right,
        ZIndex = 45,
    }, true)

    bindRow.MouseButton1Click:Connect(function()
        MenuState.listeningKeybindEntry = nil
        MenuState.bindPopupListening = false
        SettingsPanel.bindListening = true
        if SettingsPanel.refresh then
            SettingsPanel.refresh()
        end
    end)

    SettingsPanel.watermark = createMiniToggleRow("Watermark", function()
        return Runtime.showWatermark
    end, function(state)
        Runtime.showWatermark = state
        updateWatermark()
        if SettingsPanel.refresh then
            SettingsPanel.refresh()
        end
    end)
    SettingsPanel.watermark.row.LayoutOrder = 1

    SettingsPanel.keybinds = createMiniToggleRow("Keybind List", function()
        return Runtime.showKeybindList
    end, function(state)
        Runtime.showKeybindList = state
        refreshRows()
        if SettingsPanel.refresh then
            SettingsPanel.refresh()
        end
    end)
    SettingsPanel.keybinds.row.LayoutOrder = 2

    SettingsPanel.bind = {
        kind = "bind",
        row = bindRow,
        label = bindLabel,
        value = bindValue,
    }
    SettingsPanel.bind.row.LayoutOrder = 3

    SettingsPanel.refresh = function()
        for _, control in pairs(SettingsPanel) do
            if type(control) == "table" and control.kind == "toggle" then
                local enabled = control.get()
                control.fill.BackgroundTransparency = enabled and 0 or 1
                control.label.TextColor3 = enabled and Theme.text or Theme.textDim
            end
        end

        if SettingsPanel.bind and SettingsPanel.bind.value then
            SettingsPanel.bind.value.Text = SettingsPanel.bindListening and "..." or bindToText(MenuState.toggleBind)
            SettingsPanel.bind.value.TextColor3 = SettingsPanel.bindListening and Theme.accent or Theme.textDim
        end
    end
end

local InfoShell = addShell(WindowShell.background, UDim2.fromOffset(198, 108), UDim2.new(1, -206, 1, -138), false, 0, 40)
InfoShell.outline.Visible = false

InfoShell.titleLabel = createThemedText(InfoShell.background, {
    Parent = InfoShell.background,
    BackgroundTransparency = 1,
    Position = UDim2.fromOffset(8, 6),
    Size = UDim2.new(1, -16, 0, 14),
    Font = Enum.Font.GothamMedium,
    Text = "NeverPaste Info",
    TextSize = 12,
    TextXAlignment = Enum.TextXAlignment.Left,
    ZIndex = 44,
}, false)

InfoShell.bodyText = createThemedText(InfoShell.background, {
    Parent = InfoShell.background,
    BackgroundTransparency = 1,
    Position = UDim2.fromOffset(8, 26),
    Size = UDim2.new(1, -16, 1, -34),
    Font = Enum.Font.GothamMedium,
    Text = "Discord: discord.gg/neverpaste\nChannel: @neverpaste\nBuild: private preview\nSupport: use RMB for binds",
    TextSize = 12,
    TextWrapped = true,
    TextYAlignment = Enum.TextYAlignment.Top,
    TextXAlignment = Enum.TextXAlignment.Left,
    ZIndex = 44,
}, true)

local WatermarkShell = addShell(ScreenGui, UDim2.fromOffset(0, 24), UDim2.new(1, -18, 0, 18), true, 0, 30)
WatermarkShell.outline.AnchorPoint = Vector2.new(1, 0)
WatermarkShell.outline.Visible = true

local WatermarkText = createThemedText(WatermarkShell.background, {
    Parent = WatermarkShell.background,
    BackgroundTransparency = 1,
    Position = UDim2.fromOffset(0, 1),
    Size = UDim2.fromOffset(0, 18),
    AutomaticSize = Enum.AutomaticSize.X,
    Font = Enum.Font.Code,
    Text = "",
    TextSize = 12,
    TextXAlignment = Enum.TextXAlignment.Left,
    ZIndex = 33,
}, false)

create("UIPadding", {
    Parent = WatermarkShell.background,
    PaddingLeft = UDim.new(0, 9),
    PaddingRight = UDim.new(0, 9),
})

local KeybindMetrics = {
    headerHeight = 20,
    rowHeight = 14,
    minWidth = 140,
    maxWidth = 220,
    bindPadding = 6,
    nameGap = 8,
}

local KeybindShell = addShell(ScreenGui, UDim2.fromOffset(KeybindMetrics.minWidth, KeybindMetrics.headerHeight), UDim2.fromOffset(52, 210), true, 0, 25)
KeybindShell.outline.Visible = true

createThemedText(KeybindShell.background, {
    Parent = KeybindShell.background,
    BackgroundTransparency = 1,
    Size = UDim2.new(1, 0, 1, 0),
    Font = Enum.Font.GothamMedium,
    Text = "Keybinds",
    TextSize = 10,
    ZIndex = 28,
}, false)

local KeybindListShell = addShell(KeybindShell.outline, UDim2.new(1, 0, 0, 0), UDim2.new(0, 0, 1, 0), false, 0, 25)

local KeybindList = create("Frame", {
    Parent = KeybindListShell.background,
    BackgroundTransparency = 1,
    AutomaticSize = Enum.AutomaticSize.Y,
    Size = UDim2.new(1, 0, 0, 0),
    ZIndex = 28,
})

create("UIListLayout", {
    Parent = KeybindList,
    FillDirection = Enum.FillDirection.Vertical,
    Padding = UDim.new(0, 1),
    SortOrder = Enum.SortOrder.LayoutOrder,
})

create("UIPadding", {
    Parent = KeybindList,
    PaddingTop = UDim.new(0, 1),
    PaddingLeft = UDim.new(0, 6),
    PaddingRight = UDim.new(0, 6),
    PaddingBottom = UDim.new(0, 2),
})

local PickerShell = addShell(ScreenGui, UDim2.fromOffset(176, 196), UDim2.fromOffset(0, 0), true, 0, 60)
PickerShell.outline.Visible = false
PickerShell.outline.ClipsDescendants = true

local PickerOverlay = create("TextButton", {
    Parent = ScreenGui,
    BackgroundTransparency = 1,
    Size = UDim2.fromScale(1, 1),
    Visible = false,
    Text = "",
    AutoButtonColor = false,
    ZIndex = 59,
})

local PickerTitle = createThemedText(PickerShell.background, {
    Parent = PickerShell.background,
    BackgroundTransparency = 1,
    Position = UDim2.fromOffset(8, 4),
    Size = UDim2.new(1, -16, 0, 16),
    Font = Enum.Font.GothamMedium,
    Text = "Color Picker",
    TextSize = 12,
    TextXAlignment = Enum.TextXAlignment.Left,
    ZIndex = 64,
}, false)

local SatVal = create("Frame", {
    Parent = PickerShell.background,
    BorderSizePixel = 0,
    BackgroundColor3 = Theme.accent,
    Position = UDim2.fromOffset(7, 24),
    Size = UDim2.fromOffset(135, 135),
    ZIndex = 64,
})

applyStroke(SatVal, Theme.outline, 1, 0)

do
    local satValWhite = create("Frame", {
        Parent = SatVal,
        BorderSizePixel = 0,
        BackgroundColor3 = Color3.new(1, 1, 1),
        Size = UDim2.fromScale(1, 1),
        ZIndex = 65,
    })

    create("UIGradient", {
        Parent = satValWhite,
        Color = ColorSequence.new(Color3.new(1, 1, 1), Color3.new(1, 1, 1)),
        Transparency = NumberSequence.new({
            NumberSequenceKeypoint.new(0, 0),
            NumberSequenceKeypoint.new(1, 1),
        }),
    })
end

local SatValShade = create("Frame", {
    Parent = SatVal,
    BorderSizePixel = 0,
    BackgroundColor3 = Color3.new(0, 0, 0),
    Size = UDim2.fromScale(1, 1),
    ZIndex = 66,
})

create("UIGradient", {
    Parent = SatValShade,
    Rotation = 90,
    Color = ColorSequence.new(Color3.new(0, 0, 0), Color3.new(0, 0, 0)),
    Transparency = NumberSequence.new({
        NumberSequenceKeypoint.new(0, 1),
        NumberSequenceKeypoint.new(1, 0),
    }),
})

local SatValCursor = create("Frame", {
    Parent = SatVal,
    AnchorPoint = Vector2.new(0.5, 0.5),
    BackgroundColor3 = Color3.new(1, 1, 1),
    BorderSizePixel = 0,
    Size = UDim2.fromOffset(10, 10),
    ZIndex = 67,
})

applyStroke(SatValCursor, Theme.outline, 1, 0)
applyCorner(SatValCursor, 2)

local HueBar = create("Frame", {
    Parent = PickerShell.background,
    BorderSizePixel = 0,
    BackgroundColor3 = Color3.new(1, 1, 1),
    Position = UDim2.fromOffset(148, 24),
    Size = UDim2.fromOffset(20, 135),
    ZIndex = 64,
})

applyStroke(HueBar, Theme.outline, 1, 0)

create("UIGradient", {
    Parent = HueBar,
    Rotation = 90,
    Color = ColorSequence.new({
        ColorSequenceKeypoint.new(0, Color3.fromRGB(255, 0, 0)),
        ColorSequenceKeypoint.new(0.16, Color3.fromRGB(255, 255, 0)),
        ColorSequenceKeypoint.new(0.33, Color3.fromRGB(0, 255, 0)),
        ColorSequenceKeypoint.new(0.5, Color3.fromRGB(0, 255, 255)),
        ColorSequenceKeypoint.new(0.67, Color3.fromRGB(0, 0, 255)),
        ColorSequenceKeypoint.new(0.84, Color3.fromRGB(255, 0, 255)),
        ColorSequenceKeypoint.new(1, Color3.fromRGB(255, 0, 0)),
    }),
})

local HueCursor = create("Frame", {
    Parent = HueBar,
    AnchorPoint = Vector2.new(0.5, 0.5),
    BackgroundColor3 = Color3.new(1, 1, 1),
    BorderSizePixel = 0,
    Size = UDim2.new(1, 4, 0, 3),
    ZIndex = 66,
})

applyStroke(HueCursor, Theme.outline, 1, 0)

local PickerPreview
do
    local pickerPreviewShell = addShell(PickerShell.background, UDim2.fromOffset(60, 18), UDim2.fromOffset(7, 168), false, 0, 64)
    PickerPreview = create("Frame", {
        Parent = pickerPreviewShell.background,
        BorderSizePixel = 0,
        BackgroundColor3 = Theme.accent,
        Size = UDim2.new(1, 0, 1, 0),
        ZIndex = 67,
    })
end

local PickerValue = createThemedText(PickerShell.background, {
    Parent = PickerShell.background,
    BackgroundTransparency = 1,
    Position = UDim2.fromOffset(75, 169),
    Size = UDim2.new(1, -82, 0, 16),
    Font = Enum.Font.Code,
    Text = "#FFFFFF",
    TextSize = 12,
    TextXAlignment = Enum.TextXAlignment.Left,
    ZIndex = 64,
}, true)

local BindPopupShell = addShell(ScreenGui, UDim2.fromOffset(166, 88), UDim2.fromOffset(0, 0), true, 0, 55)
BindPopupShell.outline.Visible = false

local BindOverlay = create("TextButton", {
    Parent = ScreenGui,
    BackgroundTransparency = 1,
    Size = UDim2.fromScale(1, 1),
    Visible = false,
    Text = "",
    AutoButtonColor = false,
    ZIndex = 54,
})

local BindPopupTitle = createThemedText(BindPopupShell.background, {
    Parent = BindPopupShell.background,
    BackgroundTransparency = 1,
    Position = UDim2.fromOffset(8, 4),
    Size = UDim2.new(1, -16, 0, 16),
    Font = Enum.Font.GothamMedium,
    Text = "Bind Setup",
    TextSize = 12,
    TextXAlignment = Enum.TextXAlignment.Left,
    ZIndex = 59,
}, false)

local BindFieldText
local BindFieldButton
do
    local bindFieldShell = addShell(BindPopupShell.background, UDim2.new(1, -16, 0, 18), UDim2.fromOffset(8, 22), false, 0, 57)
    BindFieldText = createThemedText(bindFieldShell.background, {
        Parent = bindFieldShell.background,
        BackgroundTransparency = 1,
        Size = UDim2.new(1, 0, 1, 0),
        Font = Enum.Font.Code,
        Text = "click to bind",
        TextSize = 11,
        ZIndex = 60,
    }, false)

    BindFieldButton = create("TextButton", {
        Parent = bindFieldShell.outline,
        BackgroundTransparency = 1,
        Size = UDim2.new(1, 0, 1, 0),
        Text = "",
        AutoButtonColor = false,
        ZIndex = 61,
    })
end

-- Shared utilities
-- Collection and callback helpers
local function appendUniqueStrings(target, values)
    if type(values) ~= "table" then
        return
    end

    for _, value in ipairs(values) do
        local normalized = string.lower(tostring(value))
        if not table.find(target, normalized) then
            target[#target + 1] = normalized
        end
    end
end

local function mergeTags(...)
    local tags = {}
    for index = 1, select("#", ...) do
        appendUniqueStrings(tags, select(index, ...))
    end
    return tags
end

local function safeCallback(callback, ...)
    if type(callback) ~= "function" then
        return
    end

    local ok, err = pcall(callback, ...)
    if not ok then
        return err
    end
end

local function slugify(text)
    local value = string.lower(tostring(text or "item"))
    value = value:gsub("%s+", "_")
    value = value:gsub("[^%w_]", "")
    value = value:gsub("_+", "_")
    value = value:gsub("^_", "")
    value = value:gsub("_$", "")
    return value ~= "" and value or "item"
end

local function copyArray(values)
    local copied = {}
    if type(values) ~= "table" then
        return copied
    end

    for index, value in ipairs(values) do
        copied[index] = value
    end

    return copied
end

local function copyMap(values)
    local copied = {}
    if type(values) ~= "table" then
        return copied
    end

    for key, value in pairs(values) do
        copied[key] = value
    end

    return copied
end

local function trimString(text)
    return tostring(text or ""):gsub("^%s+", ""):gsub("%s+$", "")
end

-- Filesystem and serialization helpers
supportsConfigFiles = function()
    return FileApi.makefolder ~= nil
        and FileApi.writefile ~= nil
        and FileApi.readfile ~= nil
        and FileApi.listfiles ~= nil
        and FileApi.delfile ~= nil
end

local function ensureFolder(path)
    if type(path) ~= "string" or path == "" or not FileApi.makefolder then
        return false
    end

    if FileApi.isfolder then
        local ok, exists = pcall(FileApi.isfolder, path)
        if ok and exists then
            return true
        end
    end

    local created = pcall(FileApi.makefolder, path)
    if created then
        return true
    end

    if FileApi.isfolder then
        local ok, exists = pcall(FileApi.isfolder, path)
        return ok and exists
    end

    return false
end

local function serializeEnumItem(enumItem)
    if typeof(enumItem) == "EnumItem" then
        return tostring(enumItem)
    end
    return nil
end

local function deserializeEnumItem(value)
    if typeof(value) == "EnumItem" then
        return value
    end

    if type(value) ~= "string" or not string.match(value, "^Enum%.") then
        return nil
    end

    local current = Enum
    local first = true

    for segment in string.gmatch(value, "[^%.]+") do
        if first then
            first = false
        else
            local nextValue = current[segment]
            if nextValue == nil then
                return nil
            end
            current = nextValue
        end
    end

    return typeof(current) == "EnumItem" and current or nil
end

local function serializeColor3(color)
    if typeof(color) == "Color3" then
        return color:ToHex()
    end
    return nil
end

local function deserializeColor3(value)
    if typeof(value) == "Color3" then
        return value
    end

    if type(value) ~= "string" then
        return nil
    end

    local normalized = trimString(value):gsub("#", "")
    if normalized == "" then
        return nil
    end

    local ok, color = pcall(Color3.fromHex, "#" .. normalized)
    if ok then
        return color
    end

    return nil
end

local function makeEntryId(preferred)
    local base = slugify(preferred)
    local candidate = base
    local suffix = 2

    while EntryMap[candidate] do
        candidate = string.format("%s_%d", base, suffix)
        suffix = suffix + 1
    end

    return candidate
end

local function makeTabId(preferred)
    local base = slugify(preferred)
    local candidate = base
    local suffix = 2

    while Tabs[candidate] do
        candidate = string.format("%s_%d", base, suffix)
        suffix = suffix + 1
    end

    return candidate
end

-- Entry identity and layout helpers
local function resolveColumn(position)
    local normalized = string.lower(tostring(position or "left"))
    if normalized == "center" or normalized == "middle" then
        return 2
    elseif normalized == "right" then
        return 3
    end
    return 1
end

local function resolveIcon(icon)
    if type(icon) ~= "string" or icon == "" then
        return TabIcons.main
    end

    local lookup = {
        target = IconAssets.target,
        eye = IconAssets.eye,
        code = IconAssets.code,
        settings = IconAssets.settings,
        info = IconAssets.info,
        search = IconAssets.search,
        main = TabIcons.main,
        visuals = TabIcons.visuals,
        ui = TabIcons.ui,
    }

    local normalized = string.lower(icon)
    return lookup[normalized] or icon
end

local function roundValue(value, step)
    if not step or step == 0 then
        return value
    end

    local multiplier = 1 / step
    return math.floor(value * multiplier + 0.5) / multiplier
end

local function getSliderPrecision(entry)
    if not entry or not entry.round or entry.round >= 1 then
        return 0
    end

    local decimals = tostring(entry.round):match("%.(%d+)")
    return decimals and #decimals or 2
end

-- Control value helpers
local function normalizeSliderValue(entry, value)
    local numericValue = tonumber(value)
    if numericValue == nil or numericValue ~= numericValue or numericValue == math.huge or numericValue == -math.huge then
        local fallbackValue = tonumber(entry.value)
        if fallbackValue == nil or fallbackValue ~= fallbackValue or fallbackValue == math.huge or fallbackValue == -math.huge then
            fallbackValue = entry.min
        end

        return math.clamp(roundValue(fallbackValue, entry.round), entry.min, entry.max)
    end

    return math.clamp(roundValue(numericValue, entry.round), entry.min, entry.max)
end

local function formatSliderInputValue(entry, value)
    local number = normalizeSliderValue(entry, value)
    local precision = getSliderPrecision(entry)

    if precision > 0 then
        return string.format("%." .. precision .. "f", number)
    end

    if math.floor(number) == number then
        number = math.floor(number)
    end

    return tostring(number)
end

local function sanitizeSliderInputText(entry, text, finalize)
    local cleaned = tostring(text or ""):gsub(",", "."):gsub("[^%d%-%.]", "")
    local hasNegativePrefix = entry.min < 0 and cleaned:sub(1, 1) == "-"

    cleaned = cleaned:gsub("%-", "")
    if hasNegativePrefix then
        cleaned = "-" .. cleaned
    end

    local dotIndex = cleaned:find("%.", 1, true)
    if dotIndex then
        cleaned = cleaned:sub(1, dotIndex) .. cleaned:sub(dotIndex + 1):gsub("%.", "")
    end

    if cleaned == "" or cleaned == "-" or cleaned == "." or cleaned == "-." then
        return cleaned
    end

    local numericValue = tonumber(cleaned)
    if numericValue == nil then
        return formatSliderInputValue(entry, entry.value)
    end

    if numericValue > entry.max or (finalize and numericValue < entry.min) then
        return formatSliderInputValue(entry, numericValue)
    end

    return cleaned
end

local function applySliderValue(entry, value, fireCallback)
    local nextValue = normalizeSliderValue(entry, value)
    local changed = entry.value ~= nextValue

    entry.value = nextValue

    if fireCallback and changed then
        safeCallback(entry.callback, entry.value)
    end

    return entry.value, changed
end

local function getSliderGlowColor(entry)
    local baseColor = entry.color or Theme.accent
    return baseColor:Lerp(Color3.new(1, 1, 1), 0.28)
end

local function formatSliderValue(entry)
    local suffix = entry.type or ""
    local precision = getSliderPrecision(entry)
    if precision > 0 then
        return string.format("%." .. precision .. "f%s", entry.value, suffix)
    end

    local number = entry.round and roundValue(entry.value, entry.round) or entry.value
    if math.floor(number) == number then
        number = math.floor(number)
    end
    return tostring(number) .. suffix
end

local function formatDropdownValue(entry)
    if entry.multi then
        local selected = {}
        for _, option in ipairs(entry.values or {}) do
            if entry.value[option] then
                selected[#selected + 1] = tostring(option)
            end
        end
        return #selected > 0 and table.concat(selected, ", ") or "None"
    end

    return tostring(entry.value or "None")
end

local function normalizeDropdownValue(entry, incoming)
    if entry.multi then
        local map = {}
        if type(incoming) == "table" then
            for key, value in pairs(incoming) do
                if type(key) == "number" then
                    map[value] = true
                elseif value then
                    map[key] = true
                end
            end
        end
        return map
    end

    if incoming ~= nil then
        return incoming
    end

    return entry.values and entry.values[1] or nil
end

local function normalizeConfigName(name)
    local cleaned = trimString(name)
    cleaned = cleaned:gsub("[\\/:*?\"<>|]", "")
    cleaned = cleaned:gsub("%s+", " ")
    return cleaned
end

local function getConfigPath(name)
    return string.format("%s/%s.cfg", ConfigSystem.folder, normalizeConfigName(name))
end

local function isConfigEntry(entry)
    return entry and entry.flag and entry.skipConfig ~= true
end

local function getDropdownSelectionList(valueMap, values)
    local selected = {}
    for _, option in ipairs(values or {}) do
        if valueMap[option] then
            selected[#selected + 1] = option
        end
    end
    return selected
end

-- Config payload helpers
local function getEntryConfigValue(entry, useDefaults)
    if not entry then
        return nil
    end

    if entry.kind == "toggle" then
        return {
            state = useDefaults and entry.defaultState or entry.state,
            mode = useDefaults and entry.defaultMode or entry.mode,
            bind = serializeEnumItem(useDefaults and entry.defaultBind or entry.bind),
            color = serializeColor3(useDefaults and entry.defaultColor or entry.color),
        }
    elseif entry.kind == "slider" then
        return useDefaults and entry.defaultValue or entry.value
    elseif entry.kind == "dropdown" then
        local value = useDefaults and entry.defaultValue or entry.value
        if entry.multi then
            return getDropdownSelectionList(value or {}, entry.values)
        end
        return value
    elseif entry.kind == "color" then
        return serializeColor3(useDefaults and entry.defaultValue or entry.color)
    elseif entry.kind == "keybind" then
        return serializeEnumItem(useDefaults and entry.defaultValue or entry.bind)
    elseif entry.kind == "textbox" then
        return useDefaults and entry.defaultValue or entry.value
    end

    return nil
end

local function setEntryValue(entry, value, fireCallback)
    if not entry then
        return
    end

    if entry.kind == "toggle" then
        local nextState = value
        local nextMode
        local nextBind
        local nextColor

        if type(value) == "table" then
            nextState = value.state
            if nextState == nil then
                nextState = value.active
            end

            nextMode = value.mode or value.Mode
            nextBind = deserializeEnumItem(value.bind or value.key or value.Bind)
            nextColor = deserializeColor3(value.color or value.Color)
        end

        if type(nextMode) == "string" then
            local normalizedMode = string.lower(nextMode)
            if normalizedMode == "toggle" or normalizedMode == "hold" or normalizedMode == "always" then
                entry.mode = normalizedMode
            end
        end

        if type(value) == "table" then
            entry.bind = nextBind
            if nextColor then
                entry.color = nextColor
            end
        end

        entry.state = entry.mode == "always" and true or nextState == true

        if fireCallback then
            safeCallback(entry.callback, entry.state)
            if nextColor and entry.colorChanged then
                safeCallback(entry.colorChanged, entry.color)
            end
        end
    elseif entry.kind == "color" then
        local nextColor = deserializeColor3(value)
        if nextColor then
            entry.color = nextColor
            if fireCallback then
                safeCallback(entry.callback, entry.color)
            end
        end
    elseif entry.kind == "slider" then
        applySliderValue(entry, value, fireCallback)
    elseif entry.kind == "dropdown" then
        entry.value = normalizeDropdownValue(entry, value)
        if fireCallback then
            safeCallback(entry.callback, entry.multi and copyMap(entry.value) or entry.value)
        end
    elseif entry.kind == "keybind" then
        entry.bind = deserializeEnumItem(value)
        if fireCallback then
            safeCallback(entry.changed, entry.bind)
        end
    elseif entry.kind == "textbox" then
        entry.value = tostring(value or "")
        if fireCallback then
            safeCallback(entry.callback, entry.value)
        end
    end
end

local function setDropdownValues(entry, values, preferredValue)
    if not entry or entry.kind ~= "dropdown" then
        return
    end

    entry.values = copyArray(values or {})

    local nextValue = preferredValue
    if nextValue ~= nil and not entry.multi and not table.find(entry.values, nextValue) then
        nextValue = nil
    end

    if entry.multi then
        entry.value = normalizeDropdownValue(entry, nextValue or {})
    else
        entry.value = nextValue ~= nil and nextValue or (entry.values[1] or nil)
    end
end

do
    ConfigOps.exportData = function(useDefaults)
        local payload = {
            meta = {
                title = Runtime.title,
                version = 2,
                directory = ConfigSystem.directory,
            },
            settings = {},
        }

        for _, entry in ipairs(Entries) do
            if isConfigEntry(entry) then
                payload.settings[entry.flag] = getEntryConfigValue(entry, useDefaults)
            end
        end

        return payload
    end

    ConfigOps.applyData = function(payload)
        if type(payload) ~= "table" then
            return false, "invalid config payload"
        end

        local settings = payload
        if type(payload.settings) == "table" then
            settings = payload.settings
        elseif type(payload.flags) == "table" then
            settings = payload.flags
        end

        if type(settings) ~= "table" then
            return false, "config has no settings"
        end

        for flag, value in pairs(settings) do
            local entry = EntryMap[flag]
            if isConfigEntry(entry) then
                setEntryValue(entry, value, true)
            end
        end

        refreshRows()
        updateWatermark()
        ConfigOps.resetDeleteState()
        if ConfigOps.refreshControls and ConfigSystem.menuBuilt then
            ConfigOps.refreshControls(ConfigSystem.selectedName, false)
        end
        return true
    end

    ConfigOps.getList = function()
        if not ConfigSystem.supported then
            return {}
        end

        ensureFolder(ConfigSystem.directory)
        ensureFolder(ConfigSystem.folder)

        local ok, files = pcall(FileApi.listfiles, ConfigSystem.folder)
        if not ok or type(files) ~= "table" then
            return {}
        end

        local names = {}
        for _, filePath in ipairs(files) do
            local normalized = tostring(filePath):gsub("\\", "/")
            local name = normalized:match("([^/]+)%.cfg$")
            if name then
                names[#names + 1] = name
            end
        end

        table.sort(names, function(left, right)
            return string.lower(left) < string.lower(right)
        end)

        return names
    end

    ConfigOps.setInputText = function(value)
        if not ConfigSystem.inputBox then
            return
        end

        ConfigSystem.syncing = true
        ConfigSystem.inputBox.Text = normalizeConfigName(value or "")
        ConfigSystem.syncing = false
    end

    ConfigOps.resetDeleteState = function()
        ConfigSystem.deleteConfirmName = nil
        if ConfigSystem.deleteLabel then
            ConfigSystem.deleteLabel.Text = "Delete"
        end
    end

    ConfigOps.clearRows = function()
        for _, row in ipairs(ConfigSystem.rows) do
            if row.button and row.button.Parent then
                row.button:Destroy()
            end
        end

        table.clear(ConfigSystem.rows)
    end
end

do
    local function buildFilteredConfigNames(filterText)
        local names = ConfigOps.getList()
        if filterText == "" then
            return names
        end

        local filtered = {}
        local normalizedFilter = string.lower(filterText)

        for _, name in ipairs(names) do
            if string.find(string.lower(name), normalizedFilter, 1, true) then
                filtered[#filtered + 1] = name
            end
        end

        return filtered
    end

    local function createConfigRow(name)
        local row = create("TextButton", {
            Parent = ConfigSystem.results,
            BackgroundColor3 = Theme.accent,
            BackgroundTransparency = 1,
            BorderSizePixel = 0,
            Size = UDim2.new(1, -2, 0, 18),
            Text = "",
            AutoButtonColor = false,
            ZIndex = 44,
        })

        applyGradient(row, Color3.fromRGB(255, 255, 255), Color3.fromRGB(167, 167, 167), 90)

        local label = createThemedText(row, {
            Parent = row,
            BackgroundTransparency = 1,
            Position = UDim2.fromOffset(4, 0),
            Size = UDim2.new(1, -8, 1, 0),
            Font = Enum.Font.Code,
            Text = name,
            TextSize = 11,
            TextXAlignment = Enum.TextXAlignment.Left,
            ZIndex = 45,
        }, false)

        row.MouseEnter:Connect(function()
            row.BackgroundTransparency = 0.95
        end)

        row.MouseLeave:Connect(function()
            row.BackgroundTransparency = 1
        end)

        row.MouseButton1Click:Connect(function()
            ConfigSystem.selectedName = name
            ConfigOps.setInputText(name)
            ConfigOps.resetDeleteState()
            ConfigOps.refreshControls(name, true)
        end)

        ConfigSystem.rows[#ConfigSystem.rows + 1] = {
            button = row,
            label = label,
            name = name,
        }
    end

    ConfigOps.refreshControls = function(preferredName, syncNameBox)
        if not ConfigSystem.menuBuilt then
            return {}
        end

        local typed = normalizeConfigName(ConfigSystem.inputBox and ConfigSystem.inputBox.Text or "")
        local names = ConfigOps.getList()
        local selected = preferredName

        if selected == nil or selected == "" or not table.find(names, selected) then
            selected = ConfigSystem.selectedName
        end

        if selected == nil or selected == "" or not table.find(names, selected) then
            selected = names[1]
        end

        if selected ~= nil and selected ~= "" and not table.find(names, selected) then
            selected = nil
        end

        ConfigSystem.selectedName = selected

        if syncNameBox and selected then
            ConfigOps.setInputText(selected)
            typed = selected
        end

        ConfigOps.clearRows()

        local visibleNames = buildFilteredConfigNames(typed)
        for _, name in ipairs(visibleNames) do
            createConfigRow(name)
        end

        for _, row in ipairs(ConfigSystem.rows) do
            local isSelected = row.name == selected
            row.label.TextColor3 = isSelected and Theme.accent or Theme.text
        end

        if ConfigSystem.emptyLabel then
            if not ConfigSystem.supported then
                ConfigSystem.emptyLabel.Text = "filesystem unavailable"
                ConfigSystem.emptyLabel.Visible = true
            elseif #visibleNames == 0 then
                ConfigSystem.emptyLabel.Text = typed ~= "" and "not found" or "no configs"
                ConfigSystem.emptyLabel.Visible = true
            else
                ConfigSystem.emptyLabel.Visible = false
            end
        end

        refreshRows()
        return visibleNames
    end

    ConfigOps.getRequestedName = function(preferSelected)
        local selected = normalizeConfigName(ConfigSystem.selectedName)
        local typed = normalizeConfigName(ConfigSystem.inputBox and ConfigSystem.inputBox.Text or "")

        if preferSelected and selected ~= "" then
            return selected
        end

        if typed ~= "" then
            return typed
        end

        if selected ~= "" then
            return selected
        end

        return nil
    end
end

do
    local function createConfigPopupButton(parent, text, position, size)
        local shell = addShell(parent, size, position, false, 0, 42)
        local label = createThemedText(shell.background, {
            Parent = shell.background,
            BackgroundTransparency = 1,
            Size = UDim2.new(1, 0, 1, 0),
            Font = Enum.Font.GothamMedium,
            Text = text,
            TextSize = 11,
            ZIndex = 45,
        }, false)

        local button = create("TextButton", {
            Parent = shell.outline,
            BackgroundTransparency = 1,
            Size = UDim2.new(1, 0, 1, 0),
            Text = "",
            AutoButtonColor = false,
            ZIndex = 46,
        })

        button.MouseEnter:Connect(function()
            shell.background.BackgroundColor3 = Theme.high
        end)

        button.MouseLeave:Connect(function()
            shell.background.BackgroundColor3 = Theme.low
        end)

        return {
            shell = shell,
            label = label,
            button = button,
        }
    end

    local function initializeConfigPanel()
        local configShell = addShell(WindowShell.background, UDim2.fromOffset(248, 224), UDim2.new(0, 8, 1, -252), false, 0, 40)
        configShell.outline.Visible = false
        configShell.outline.ClipsDescendants = true

        local titleLabel = createThemedText(configShell.background, {
            Parent = configShell.background,
            BackgroundTransparency = 1,
            Position = UDim2.fromOffset(9, 7),
            Size = UDim2.new(1, -18, 0, 14),
            Font = Enum.Font.GothamMedium,
            Text = "Configs",
            TextSize = 12,
            TextXAlignment = Enum.TextXAlignment.Left,
            ZIndex = 44,
        }, false)

        local listFrame = create("ScrollingFrame", {
            Parent = configShell.background,
            BackgroundTransparency = 1,
            BorderSizePixel = 0,
            Position = UDim2.fromOffset(9, 26),
            Size = UDim2.new(1, -18, 0, 110),
            CanvasSize = UDim2.fromOffset(0, 0),
            ScrollBarImageColor3 = Theme.accent,
            ScrollBarThickness = 4,
            TopImage = "",
            BottomImage = "",
            MidImage = "",
            ZIndex = 43,
        })
        registerTheme("accent", listFrame, "ScrollBarImageColor3")

        local listLayout = create("UIListLayout", {
            Parent = listFrame,
            FillDirection = Enum.FillDirection.Vertical,
            Padding = UDim.new(0, 3),
            SortOrder = Enum.SortOrder.LayoutOrder,
        })

        listLayout:GetPropertyChangedSignal("AbsoluteContentSize"):Connect(function()
            listFrame.CanvasSize = UDim2.fromOffset(0, listLayout.AbsoluteContentSize.Y)
        end)

        local emptyLabel = createThemedText(configShell.background, {
            Parent = configShell.background,
            BackgroundTransparency = 1,
            Position = UDim2.fromOffset(12, 70),
            Size = UDim2.new(1, -24, 0, 14),
            Font = Enum.Font.GothamMedium,
            Text = "not found",
            TextSize = 12,
            TextXAlignment = Enum.TextXAlignment.Left,
            Visible = false,
            ZIndex = 44,
        }, true)

        local inputShell = addShell(configShell.background, UDim2.new(1, -18, 0, 22), UDim2.fromOffset(9, 144), false, 0, 42)
        local inputBox = create("TextBox", {
            Parent = inputShell.background,
            BackgroundTransparency = 1,
            Position = UDim2.fromOffset(6, 0),
            Size = UDim2.new(1, -12, 1, 0),
            ClearTextOnFocus = false,
            Font = Enum.Font.GothamMedium,
            PlaceholderText = "search or create config",
            PlaceholderColor3 = Theme.textDim,
            Text = "",
            TextColor3 = Theme.text,
            TextSize = 12,
            TextXAlignment = Enum.TextXAlignment.Left,
            ZIndex = 44,
        })
        registerTheme("text", inputBox, "TextColor3")
        registerTheme("textDim", inputBox, "PlaceholderColor3")

        local loadButton = createConfigPopupButton(configShell.background, "Load", UDim2.fromOffset(9, 174), UDim2.fromOffset(70, 18))
        local saveButton = createConfigPopupButton(configShell.background, "Save", UDim2.fromOffset(86, 174), UDim2.fromOffset(70, 18))
        local createButton = createConfigPopupButton(configShell.background, "Create", UDim2.fromOffset(163, 174), UDim2.fromOffset(76, 18))
        local deleteButton = createConfigPopupButton(configShell.background, "Delete", UDim2.fromOffset(9, 198), UDim2.fromOffset(112, 18))
        local refreshButton = createConfigPopupButton(configShell.background, "Refresh", UDim2.fromOffset(128, 198), UDim2.fromOffset(111, 18))

        ConfigSystem.shell = configShell
        ConfigSystem.results = listFrame
        ConfigSystem.inputBox = inputBox
        ConfigSystem.emptyLabel = emptyLabel
        ConfigSystem.deleteButton = deleteButton.button
        ConfigSystem.deleteLabel = deleteButton.label
        ConfigSystem.loadButton = loadButton.button
        ConfigSystem.saveButton = saveButton.button
        ConfigSystem.createButton = createButton.button
        ConfigSystem.refreshButton = refreshButton.button
        ConfigSystem.titleLabel = titleLabel
        ConfigSystem.button = ConfigButton
    end

    initializeConfigPanel()
end

-- Panel visibility and quick actions
do

do
Panels.closeSearch = function()
    MenuState.searchOpen = false
    SearchShell.outline.Visible = false
    SearchShell.input:ReleaseFocus()
end

Panels.closeInfo = function()
    MenuState.infoOpen = false
    InfoShell.outline.Visible = false
end

Panels.closeSettings = function()
    MenuState.settingsOpen = false
    SettingsShell.outline.Visible = false
    SettingsPanel.bindListening = false
    if SettingsPanel.refresh then
        SettingsPanel.refresh()
    end
end

Panels.closeConfigMenu = function()
    if ConfigSystem.shell then
        ConfigSystem.shell.outline.Visible = false
    end

    ConfigOps.resetDeleteState()
end

Panels.closeMiniPanels = function()
    Panels.closeSearch()
    Panels.closeInfo()
    Panels.closeSettings()
    Panels.closeConfigMenu()
end

Panels.closeDropdown = function()
    if DropdownPanel.entry then
        DropdownPanel.entry.open = false
    end

    DropdownPanel.entry = nil

    if DropdownPanel.list then
        for _, child in ipairs(DropdownPanel.list:GetChildren()) do
            if child:IsA("TextButton") then
                child:Destroy()
            end
        end
    end

    table.clear(DropdownPanel.rows)

    if DropdownPanel.shell then
        DropdownPanel.shell.outline.Visible = false
    end
end

Panels.refreshDropdownOverlay = function()
    if not DropdownPanel.shell or not DropdownPanel.list then
        return
    end

    local openEntry
    for _, entry in ipairs(Entries) do
        if entry.kind == "dropdown" and entry.open then
            openEntry = entry
            break
        end
    end

    if not openEntry or not openEntry.ui or not openEntry.ui.button or not openEntry.ui.button.Parent then
        Panels.closeDropdown()
        return
    end

    if DropdownPanel.entry ~= openEntry then
        for _, child in ipairs(DropdownPanel.list:GetChildren()) do
            if child:IsA("TextButton") then
                child:Destroy()
            end
        end

        table.clear(DropdownPanel.rows)

        for _, option in ipairs(openEntry.values or {}) do
            local row = create("TextButton", {
                Parent = DropdownPanel.list,
                BackgroundColor3 = Theme.accent,
                BackgroundTransparency = 1,
                BorderSizePixel = 0,
                Size = UDim2.new(1, 0, 0, 16),
                Text = "",
                AutoButtonColor = false,
                ZIndex = 50,
            })

            applyGradient(row, Color3.fromRGB(255, 255, 255), Color3.fromRGB(167, 167, 167), 90)

            local label = createThemedText(row, {
                Parent = row,
                BackgroundTransparency = 1,
                Position = UDim2.fromOffset(4, 0),
                Size = UDim2.new(1, -8, 1, 0),
                Font = Enum.Font.GothamMedium,
                Text = tostring(option),
                TextSize = 11,
                TextXAlignment = Enum.TextXAlignment.Left,
                ZIndex = 51,
            }, true)

            row.MouseButton1Click:Connect(function()
                if openEntry.multi then
                    openEntry.value[option] = not openEntry.value[option]
                    safeCallback(openEntry.callback, copyMap(openEntry.value))
                else
                    openEntry.value = option
                    safeCallback(openEntry.callback, openEntry.value)
                    Panels.closeDropdown()
                end

                refreshRows()
            end)

            DropdownPanel.rows[option] = {
                row = row,
                label = label,
            }
        end

        DropdownPanel.entry = openEntry
    end

    local optionCount = #(openEntry.values or {})
    local contentHeight = optionCount > 0 and ((optionCount * 16) + ((optionCount - 1) * 2)) or 0
    local width = math.max(openEntry.ui.button.AbsoluteSize.X, 132)
    local shellWidth = width + 10
    local height = math.min(contentHeight + 8, 132)
    local viewport = getViewportSize()
    local buttonPosition = openEntry.ui.button.AbsolutePosition
    local buttonSize = openEntry.ui.button.AbsoluteSize
    local x = math.clamp(buttonPosition.X, 10, viewport.X - shellWidth - 10)
    local y = math.clamp(buttonPosition.Y + buttonSize.Y + 4, 10, viewport.Y - height - 10)

    DropdownPanel.shell.outline.Size = UDim2.fromOffset(shellWidth, height)
    DropdownPanel.shell.outline.Position = UDim2.fromOffset(x, y)
    DropdownPanel.shell.outline.Visible = optionCount > 0
    DropdownPanel.list.CanvasSize = UDim2.fromOffset(0, contentHeight)

    for option, data in pairs(DropdownPanel.rows) do
        local selected = openEntry.multi and openEntry.value[option] or openEntry.value == option
        data.label.TextColor3 = selected and Theme.accent or Theme.textDim
    end
end

end

do

Panels.toggleSearch = function()
    MenuState.searchOpen = not MenuState.searchOpen
    SearchShell.outline.Visible = MenuState.searchOpen
    if MenuState.searchOpen then
        Panels.closeInfo()
        Panels.closeSettings()
        SearchShell.input:CaptureFocus()
    else
        SearchShell.input:ReleaseFocus()
    end
end

Panels.toggleInfo = function()
    MenuState.infoOpen = not MenuState.infoOpen
    InfoShell.outline.Visible = MenuState.infoOpen
    if MenuState.infoOpen then
        Panels.closeSearch()
        Panels.closeSettings()
    end
end

Panels.toggleSettings = function()
    MenuState.settingsOpen = not MenuState.settingsOpen
    SettingsShell.outline.Visible = MenuState.settingsOpen
    if MenuState.settingsOpen then
        Panels.closeSearch()
        Panels.closeInfo()
        Panels.closeConfigMenu()
    end
    SettingsPanel.bindListening = false
    if SettingsPanel.refresh then
        SettingsPanel.refresh()
    end
end

end

do

Panels.toggleConfigMenu = function()
    if not ConfigSystem.shell then
        return
    end

    local nextVisible = not ConfigSystem.shell.outline.Visible
    Panels.closeSearch()
    Panels.closeInfo()
    Panels.closeSettings()
    ConfigOps.resetDeleteState()

    ConfigSystem.shell.outline.Visible = nextVisible
    if nextVisible then
        ConfigOps.refreshControls(nil, false)
        if ConfigSystem.inputBox then
            ConfigSystem.inputBox:CaptureFocus()
        end
    elseif ConfigSystem.inputBox then
        ConfigSystem.inputBox:ReleaseFocus()
    end
end

end

do

Panels.rebuildSearchResults = function(query)
    local filter = string.lower(query or "")

    for _, child in ipairs(SearchShell.results:GetChildren()) do
        if child:IsA("TextButton") or child:IsA("Frame") then
            child:Destroy()
        end
    end

    local resultCount = 0

    for _, entry in ipairs(Entries) do
        local title = string.lower(entry.name)
        local pathDisplay = string.format("%s > %s", string.upper(entry.tabName or entry.tab), entry.section)
        if entry.subsection and entry.subsection ~= "" then
            pathDisplay = string.format("%s > %s", pathDisplay, entry.subsection)
        end

        local path = string.lower(pathDisplay)
        local tagText = string.lower(table.concat(entry.tags or {}, " "))

        if filter == "" or string.find(title, filter, 1, true) or string.find(path, filter, 1, true) or string.find(tagText, filter, 1, true) then
            resultCount = resultCount + 1

            local result = create("TextButton", {
                Parent = SearchShell.results,
                BackgroundTransparency = 1,
                BorderSizePixel = 0,
                Size = UDim2.new(1, -4, 0, 30),
                Text = "",
                AutoButtonColor = false,
                ZIndex = 44,
            })

            local titleLabel = createThemedText(result, {
                Parent = result,
                BackgroundTransparency = 1,
                Position = UDim2.fromOffset(0, 0),
                Size = UDim2.new(1, 0, 0, 14),
                Font = Enum.Font.GothamMedium,
                Text = entry.name,
                TextSize = 12,
                TextXAlignment = Enum.TextXAlignment.Left,
                ZIndex = 45,
            }, false)

            local pathLabel = createThemedText(result, {
                Parent = result,
                BackgroundTransparency = 1,
                Position = UDim2.fromOffset(0, 14),
                Size = UDim2.new(1, 0, 0, 12),
                Font = Enum.Font.GothamMedium,
                Text = pathDisplay,
                TextSize = 11,
                TextXAlignment = Enum.TextXAlignment.Left,
                ZIndex = 45,
            }, true)

            result.MouseEnter:Connect(function()
                titleLabel.TextColor3 = Theme.accent
            end)

            result.MouseLeave:Connect(function()
                titleLabel.TextColor3 = Theme.text
            end)

            result.MouseButton1Click:Connect(function()
                Layout.selectTab(entry.tab)
                Panels.closeSearch()
            end)
        end
    end

    SearchShell.emptyLabel.Visible = resultCount == 0
    SearchShell.results.CanvasSize = UDim2.fromOffset(0, resultCount > 0 and (resultCount * 30) + ((resultCount - 1) * 4) or 0)
end

SearchShell.input:GetPropertyChangedSignal("Text"):Connect(function()
    Panels.rebuildSearchResults(SearchShell.input.Text)
end)

if ConfigSystem.inputBox then
    ConfigSystem.inputBox:GetPropertyChangedSignal("Text"):Connect(function()
        if ConfigSystem.syncing then
            return
        end

        local normalized = normalizeConfigName(ConfigSystem.inputBox.Text)
        if normalized ~= ConfigSystem.inputBox.Text then
            ConfigOps.setInputText(normalized)
            return
        end

        if normalized == "" or normalized ~= normalizeConfigName(ConfigSystem.selectedName) then
            ConfigSystem.selectedName = nil
        end

        ConfigOps.resetDeleteState()
        ConfigOps.refreshControls(nil, false)
    end)
end

ConfigButton.MouseButton1Click:Connect(Panels.toggleConfigMenu)
SearchButton.MouseButton1Click:Connect(Panels.toggleSearch)
InfoButton.MouseButton1Click:Connect(Panels.toggleInfo)
WindowShell.settingsButton.MouseButton1Click:Connect(Panels.toggleSettings)

ConfigButton.MouseEnter:Connect(function()
    ConfigButton.ImageColor3 = Theme.text
end)
ConfigButton.MouseLeave:Connect(function()
    ConfigButton.ImageColor3 = Theme.textDim
end)

SearchButton.MouseEnter:Connect(function()
    SearchButton.ImageColor3 = Theme.text
end)
SearchButton.MouseLeave:Connect(function()
    SearchButton.ImageColor3 = Theme.textDim
end)

InfoButton.MouseEnter:Connect(function()
    InfoButton.ImageColor3 = Theme.text
end)
InfoButton.MouseLeave:Connect(function()
    InfoButton.ImageColor3 = Theme.textDim
end)

WindowShell.settingsButton.MouseEnter:Connect(function()
    WindowShell.settingsButton.ImageColor3 = Theme.text
end)
WindowShell.settingsButton.MouseLeave:Connect(function()
    WindowShell.settingsButton.ImageColor3 = Theme.textDim
end)

end

do
    local modeHolder = create("Frame", {
        Parent = BindPopupShell.background,
        BackgroundTransparency = 1,
        Position = UDim2.fromOffset(8, 48),
        Size = UDim2.new(1, -16, 0, 22),
        ZIndex = 58,
    })

    create("UIListLayout", {
        Parent = modeHolder,
        FillDirection = Enum.FillDirection.Horizontal,
        Padding = UDim.new(0, 4),
        SortOrder = Enum.SortOrder.LayoutOrder,
    })

    local function createModeButton(modeId, title)
        local shell = addShell(modeHolder, UDim2.new(1 / 3, -3, 1, 0), UDim2.fromOffset(0, 0), false, 0, 58)
        local fill = create("Frame", {
            Parent = shell.background,
            BorderSizePixel = 0,
            BackgroundColor3 = Theme.accent,
            Size = UDim2.new(1, 0, 1, 0),
            BackgroundTransparency = 1,
            ZIndex = 60,
        })
        registerTheme("accent", fill, "BackgroundColor3")

        local text = createThemedText(shell.background, {
            Parent = shell.background,
            BackgroundTransparency = 1,
            Size = UDim2.new(1, 0, 1, 0),
            Font = Enum.Font.GothamMedium,
            Text = title,
            TextSize = 11,
            ZIndex = 61,
        }, false)

        local button = create("TextButton", {
            Parent = shell.outline,
            BackgroundTransparency = 1,
            Size = UDim2.new(1, 0, 1, 0),
            Text = "",
            AutoButtonColor = false,
            ZIndex = 62,
        })

        ModeButtons[modeId] = {
            fill = fill,
            text = text,
            button = button,
        }
    end

    createModeButton("always", "Always")
    createModeButton("toggle", "Toggle")
    createModeButton("hold", "Hold")
end

end

-- Layout, composition and control rendering
do

do

local function getSectionContentHeight(section)
    return section and section.layout and section.layout.AbsoluteContentSize.Y or 0
end

local function getSectionFillHeight(section)
    if not section or not section.column or not section.outline or not section.outline.Parent then
        return nil
    end

    local columnHeight = section.column.AbsoluteSize.Y
    if columnHeight <= 0 then
        return nil
    end

    local relativeTop = section.outline.AbsolutePosition.Y - section.column.AbsolutePosition.Y
    local availableHeight = columnHeight - relativeTop - 29
    return math.max(0, availableHeight)
end

Layout.updateShellSize = function(section, fillToBottom)
    if not section or not section.layout then
        return
    end

    local contentHeight = getSectionContentHeight(section)
    local visibleHeight

    if fillToBottom and not section.fixedHeight then
        visibleHeight = getSectionFillHeight(section)
    end

    if visibleHeight == nil then
        visibleHeight = math.min(contentHeight, section.maxContentHeight or 156)
    end

    local needsScroll = contentHeight > visibleHeight

    section.holder.Size = UDim2.new(1, needsScroll and -4 or -8, 0, visibleHeight)
    section.holder.CanvasSize = UDim2.fromOffset(0, contentHeight > 0 and (contentHeight + 2) or 0)
    section.holder.ScrollBarThickness = needsScroll and 4 or 0
    section.outline.Size = UDim2.new(1, 0, 0, visibleHeight + 29)
end

Layout.relayoutSectionColumn = function(tabId, columnIndex)
    local sortedSections = {}

    for _, section in pairs(Sections) do
        if section.tabId == tabId and section.columnIndex == columnIndex then
            sortedSections[#sortedSections + 1] = section
        end
    end

    table.sort(sortedSections, function(left, right)
        return (left.layoutOrder or 0) < (right.layoutOrder or 0)
    end)

    for index, section in ipairs(sortedSections) do
        Layout.updateShellSize(section, index == #sortedSections)
    end
end

Layout.relayoutAllSectionColumns = function()
    for _, definition in ipairs(TabDefinitions) do
        for columnIndex = 1, 3 do
            Layout.relayoutSectionColumn(definition.id, columnIndex)
        end
    end
end

end

do

local function getAnchoredGuiPosition(guiObject)
    local guiSize = guiObject.AbsoluteSize
    local anchorOffset = Vector2.new(guiSize.X * guiObject.AnchorPoint.X, guiSize.Y * guiObject.AnchorPoint.Y)

    return Vector2.new(
        guiObject.AbsolutePosition.X + anchorOffset.X,
        guiObject.AbsolutePosition.Y + anchorOffset.Y
    )
end

local function clampGuiPositionToViewport(guiObject, anchoredPosition)
    local guiSize = guiObject.AbsoluteSize
    local anchorOffset = Vector2.new(guiSize.X * guiObject.AnchorPoint.X, guiSize.Y * guiObject.AnchorPoint.Y)
    local minPosition = anchorOffset
    local maxPosition = Vector2.new(
        math.max(anchorOffset.X, CachedViewportSize.X - guiSize.X + anchorOffset.X),
        math.max(anchorOffset.Y, CachedViewportSize.Y - guiSize.Y + anchorOffset.Y)
    )

    return Vector2.new(
        math.clamp(anchoredPosition.X, minPosition.X, maxPosition.X),
        math.clamp(anchoredPosition.Y, minPosition.Y, maxPosition.Y)
    )
end

Layout.updateWindowRestPosition = function(position)
    WindowRestPosition = position or Window.Position
end

Layout.getMenuHiddenPosition = function()
    local rest = WindowRestPosition or Window.Position
    return UDim2.new(
        rest.X.Scale,
        rest.X.Offset + MenuHiddenOffset.X,
        rest.Y.Scale,
        rest.Y.Offset + MenuHiddenOffset.Y
    )
end

local function makeDraggable(handle, target)
    local dragging = false
    local dragInput
    local dragStart
    local dragStartPosition
    local dragStartAnchored

    handle.InputBegan:Connect(function(input)
        if input.UserInputType ~= Enum.UserInputType.MouseButton1 then
            return
        end

        if target == Window then
            Motion.stopMenuTween()
        end

        dragging = true
        dragStart = input.Position
        dragStartPosition = target.Position
        dragStartAnchored = getAnchoredGuiPosition(target)

        local releaseConnection
        releaseConnection = input.Changed:Connect(function()
            if input.UserInputState == Enum.UserInputState.End then
                dragging = false
                dragInput = nil
                if releaseConnection then
                    releaseConnection:Disconnect()
                end
            end
        end)
    end)

    handle.InputChanged:Connect(function(input)
        if input.UserInputType == Enum.UserInputType.MouseMovement then
            dragInput = input
        end
    end)

    trackRuntimeConnection(Services.UserInputService.InputChanged:Connect(function(input)
        if not dragging or not dragStart or not dragStartPosition or input ~= dragInput then
            return
        end

        local delta = input.Position - dragStart
        local clampedAnchored = clampGuiPositionToViewport(target, dragStartAnchored + Vector2.new(delta.X, delta.Y))
        local clampedDelta = clampedAnchored - dragStartAnchored

        target.Position = UDim2.new(
            dragStartPosition.X.Scale,
            dragStartPosition.X.Offset + clampedDelta.X,
            dragStartPosition.Y.Scale,
            dragStartPosition.Y.Offset + clampedDelta.Y
        )

        if target == Window then
            Layout.updateWindowRestPosition(target.Position)
            Layout.relayoutAllSectionColumns()
        end
    end))
end

local function makeResizable(handle, target, minimumSize)
    local resizing = false
    local resizeInput
    local resizeStartMouse
    local resizeStartSize
    local resizeStartPosition
    local resizeTopLeft

    handle.InputBegan:Connect(function(input)
        if input.UserInputType ~= Enum.UserInputType.MouseButton1 then
            return
        end

        if target == Window then
            Motion.stopMenuTween()
        end

        resizing = true
        resizeStartMouse = input.Position
        resizeStartSize = target.AbsoluteSize
        resizeStartPosition = target.Position
        resizeTopLeft = target.AbsolutePosition

        local releaseConnection
        releaseConnection = input.Changed:Connect(function()
            if input.UserInputState == Enum.UserInputState.End then
                resizing = false
                resizeInput = nil
                if releaseConnection then
                    releaseConnection:Disconnect()
                end
            end
        end)
    end)

    handle.InputChanged:Connect(function(input)
        if input.UserInputType == Enum.UserInputType.MouseMovement then
            resizeInput = input
        end
    end)

    trackRuntimeConnection(Services.UserInputService.InputChanged:Connect(function(input)
        if not resizing or not resizeStartMouse or not resizeStartPosition or input ~= resizeInput then
            return
        end

        local currentMouse = input.Position
        local delta = currentMouse - resizeStartMouse
        local minWidth = minimumSize.X
        local minHeight = minimumSize.Y
        local maxWidth = math.max(minWidth, CachedViewportSize.X - resizeTopLeft.X)
        local maxHeight = math.max(minHeight, CachedViewportSize.Y - resizeTopLeft.Y)

        local nextWidth = math.clamp(resizeStartSize.X + delta.X, minWidth, maxWidth)
        local nextHeight = math.clamp(resizeStartSize.Y + delta.Y, minHeight, maxHeight)
        target.Size = UDim2.fromOffset(nextWidth, nextHeight)
        target.Position = UDim2.new(
            resizeStartPosition.X.Scale,
            resizeStartPosition.X.Offset + ((nextWidth - resizeStartSize.X) * target.AnchorPoint.X),
            resizeStartPosition.Y.Scale,
            resizeStartPosition.Y.Offset + ((nextHeight - resizeStartSize.Y) * target.AnchorPoint.Y)
        )

        if target == Window then
            Layout.updateWindowRestPosition(target.Position)
            Layout.relayoutAllSectionColumns()
        end
    end))
end

makeDraggable(WindowShell.header, Window)
makeDraggable(WatermarkShell.outline, WatermarkShell.outline)
makeDraggable(KeybindShell.outline, KeybindShell.outline)
makeResizable(WindowShell.resizeHandle, Window, WindowMinSize)

end

do

Layout.getSection = function(tabId, columnIndex, name)
    local key = tabId .. "_" .. columnIndex .. "_" .. name
    if Sections[key] then
        return Sections[key]
    end

    local tabFrame = Tabs[tabId]
    local column = tabFrame.columns[columnIndex]
    local layoutOrder = 1

    for _, existingSection in pairs(Sections) do
        if existingSection.tabId == tabId and existingSection.columnIndex == columnIndex then
            layoutOrder = math.max(layoutOrder, (existingSection.layoutOrder or 0) + 1)
        end
    end

    local shell = addShell(column, UDim2.new(1, 0, 0, 28), UDim2.fromOffset(0, 0), false, 0, 16)
    shell.outline.AutomaticSize = Enum.AutomaticSize.None
    shell.outline.LayoutOrder = layoutOrder

    local sectionTint = create("Frame", {
        Parent = shell.background,
        BorderSizePixel = 0,
        BackgroundColor3 = Theme.section,
        Position = UDim2.fromOffset(1, 1),
        Size = UDim2.new(1, -2, 1, -2),
        BackgroundTransparency = 0.93,
        ZIndex = 18,
    })
    registerTheme("section", sectionTint, "BackgroundColor3")

    local sectionTintGradient = applyGradient(sectionTint, Theme.sectionHigh, Theme.sectionLow, 90)
    registerTheme("sectionContrast", sectionTintGradient, "Color")

    local title = createThemedText(shell.background, {
        Parent = shell.background,
        BackgroundTransparency = 1,
        Position = UDim2.fromOffset(8, 2),
        Size = UDim2.new(1, -16, 0, 14),
        Font = Enum.Font.GothamMedium,
        Text = name,
        TextSize = 12,
        TextXAlignment = Enum.TextXAlignment.Left,
        ZIndex = 21,
    }, false)

    local holder = create("ScrollingFrame", {
        Parent = shell.background,
        BackgroundColor3 = Theme.section,
        BackgroundTransparency = 0.08,
        BorderSizePixel = 0,
        Position = UDim2.fromOffset(4, 18),
        Size = UDim2.new(1, -8, 0, 0),
        CanvasSize = UDim2.fromOffset(0, 0),
        ScrollBarImageColor3 = Theme.accent,
        ScrollBarThickness = 0,
        ScrollingDirection = Enum.ScrollingDirection.Y,
        TopImage = "",
        BottomImage = "",
        MidImage = "",
        ZIndex = 20,
    })
    registerTheme("section", holder, "BackgroundColor3")
    registerTheme("accent", holder, "ScrollBarImageColor3")

    local holderGradient = applyGradient(holder, Theme.sectionHigh, Theme.sectionLow, 90)
    registerTheme("sectionContrast", holderGradient, "Color")

    local layout = create("UIListLayout", {
        Parent = holder,
        FillDirection = Enum.FillDirection.Vertical,
        Padding = UDim.new(0, 5),
        SortOrder = Enum.SortOrder.LayoutOrder,
    })

    layout:GetPropertyChangedSignal("AbsoluteContentSize"):Connect(function()
        Layout.relayoutSectionColumn(tabId, columnIndex)
    end)

    local section = {
        tabId = tabId,
        columnIndex = columnIndex,
        column = column,
        layoutOrder = layoutOrder,
        outline = shell.outline,
        background = shell.background,
        holder = holder,
        layout = layout,
        title = title,
        maxContentHeight = 156,
        fixedHeight = false,
    }

    Sections[key] = section
    Layout.relayoutSectionColumn(tabId, columnIndex)
    task.defer(function()
        Layout.relayoutSectionColumn(tabId, columnIndex)
    end)
    return section
end

Layout.reflowTabButtons = function()
    local count = math.max(#TabDefinitions, 1)
    for _, definition in ipairs(TabDefinitions) do
        local tab = Tabs[definition.id]
        if tab and tab.button and tab.button.outline then
            tab.button.outline.Size = UDim2.new(1 / count, -2, 1, 0)
        end
    end
end

Layout.createTab = function(id, name, iconAsset, order)
    local columnGap = 6
    local columnCount = 3
    local columnWidthOffset = -math.floor((columnGap * (columnCount - 1)) / columnCount + 0.5)
    local tabWidth = math.max(#TabDefinitions, 1) > 0 and (1 / math.max(#TabDefinitions, 1)) or 1
    local buttonShell = addShell(TabHolder, UDim2.new(tabWidth, -2, 1, 0), UDim2.fromOffset(0, 0), false, 0, 16)
    buttonShell.outline.LayoutOrder = order

    local fill = create("Frame", {
        Parent = buttonShell.background,
        AnchorPoint = Vector2.new(0.5, 0.5),
        BorderSizePixel = 0,
        BackgroundColor3 = Theme.accent,
        Position = UDim2.new(0.5, 0, 0.5, 0),
        Size = UDim2.new(0, 0, 1, 0),
        BackgroundTransparency = 1,
        ZIndex = 19,
    })
    registerTheme("accent", fill, "BackgroundColor3")

    local icon = create("ImageLabel", {
        Parent = buttonShell.background,
        BackgroundTransparency = 1,
        AnchorPoint = Vector2.new(0, 0.5),
        Position = UDim2.new(0, 8, 0.5, 0),
        Size = UDim2.fromOffset(14, 14),
        Image = iconAsset,
        ImageColor3 = Theme.textDim,
        ZIndex = 20,
    })
    registerTheme("textDim", icon, "ImageColor3")

    local label = createThemedText(buttonShell.background, {
        Parent = buttonShell.background,
        BackgroundTransparency = 1,
        Position = UDim2.fromOffset(0, 0),
        Size = UDim2.new(1, 0, 1, 0),
        Font = Enum.Font.GothamMedium,
        Text = name,
        TextSize = 12,
        TextXAlignment = Enum.TextXAlignment.Center,
        ZIndex = 20,
    }, false)

    local hitbox = create("TextButton", {
        Parent = buttonShell.outline,
        BackgroundTransparency = 1,
        Size = UDim2.new(1, 0, 1, 0),
        Text = "",
        AutoButtonColor = false,
        ZIndex = 21,
    })

    local page = create("Frame", {
        Parent = ContentShell.background,
        BackgroundTransparency = 1,
        Size = UDim2.new(1, 0, 1, 0),
        Visible = false,
        ZIndex = 16,
    })

    local columns = {}
    for index = 1, columnCount do
        local columnIndex = index
        local columnOffset = math.floor((((index - 1) * columnGap) / columnCount) + 0.5)
        local column = create("Frame", {
            Parent = page,
            BackgroundTransparency = 1,
            Position = UDim2.new((columnIndex - 1) / columnCount, columnOffset, 0, 0),
            Size = UDim2.new(1 / columnCount, columnWidthOffset, 1, 0),
            AutomaticSize = Enum.AutomaticSize.None,
            ZIndex = 16,
        })

        local columnLayout = create("UIListLayout", {
            Parent = column,
            FillDirection = Enum.FillDirection.Vertical,
            Padding = UDim.new(0, 4),
            SortOrder = Enum.SortOrder.LayoutOrder,
        })

        column:GetPropertyChangedSignal("AbsoluteSize"):Connect(function()
            Layout.relayoutSectionColumn(id, columnIndex)
        end)

        columns[columnIndex] = column
    end

    Tabs[id] = {
        button = buttonShell,
        icon = icon,
        label = label,
        fill = fill,
        hitbox = hitbox,
        page = page,
        columns = columns,
        order = order,
    }

    hitbox.MouseButton1Click:Connect(function()
        Layout.selectTab(id)
    end)
    Layout.reflowTabButtons()
end

Render.colorToHex = function(color)
    return string.format("#%02X%02X%02X", math.floor(color.R * 255), math.floor(color.G * 255), math.floor(color.B * 255))
end

Render.getInlineBindText = function(entry)
    return formatToggleBindText(entry)
end

end

do

local function createKeybindEntry(entry)
    local row = create("Frame", {
        Parent = KeybindList,
        BackgroundTransparency = 1,
        Size = UDim2.new(1, 0, 0, KeybindMetrics.rowHeight),
        Visible = false,
        ZIndex = 28,
    })

    local label = createThemedText(row, {
        Parent = row,
        BackgroundTransparency = 1,
        Position = UDim2.fromOffset(0, 0),
        Size = UDim2.new(1, -34, 1, 0),
        Font = Enum.Font.GothamMedium,
        Text = "",
        TextSize = 10,
        TextXAlignment = Enum.TextXAlignment.Left,
        TextYAlignment = Enum.TextYAlignment.Center,
        TextTruncate = Enum.TextTruncate.AtEnd,
        ZIndex = 29,
    }, false)

    local bindText = create("TextLabel", {
        Parent = row,
        BackgroundTransparency = 1,
        AnchorPoint = Vector2.new(1, 0),
        Position = UDim2.new(1, 0, 0, 0),
        Size = UDim2.fromOffset(28, KeybindMetrics.rowHeight),
        Font = Enum.Font.Code,
        Text = "",
        TextSize = 10,
        TextXAlignment = Enum.TextXAlignment.Center,
        TextYAlignment = Enum.TextYAlignment.Center,
        TextColor3 = Theme.text,
        ZIndex = 32,
    })
    registerTheme("text", bindText, "TextColor3")

    entry.keybindDisplay = {
        row = row,
        label = label,
        bindText = bindText,
    }
end

local function createSubsectionHeader(entry)
    if not entry.subsection or entry.subsection == "" then
        return
    end

    local key = table.concat({
        entry.tab,
        tostring(entry.column),
        entry.section,
        entry.subsection,
    }, "::")

    if CreatedSubsectionHeaders[key] then
        return
    end
    CreatedSubsectionHeaders[key] = true

    local section = Layout.getSection(entry.tab, entry.column, entry.section)

    local row = create("Frame", {
        Parent = section.holder,
        BackgroundTransparency = 1,
        BorderSizePixel = 0,
        Size = UDim2.new(1, -2, 0, 12),
        ZIndex = 20,
    })

    local marker = create("Frame", {
        Parent = row,
        BorderSizePixel = 0,
        BackgroundColor3 = Theme.accent,
        Position = UDim2.fromOffset(0, 4),
        Size = UDim2.fromOffset(5, 5),
        ZIndex = 21,
    })
    registerTheme("accent", marker, "BackgroundColor3")

    local label = createThemedText(row, {
        Parent = row,
        BackgroundTransparency = 1,
        Position = UDim2.fromOffset(10, -1),
        Size = UDim2.new(1, -10, 1, 0),
        Font = Enum.Font.GothamMedium,
        Text = string.upper(entry.subsection),
        TextSize = 10,
        TextXAlignment = Enum.TextXAlignment.Left,
        ZIndex = 21,
    }, true)

    label.TextTransparency = 0.1
end

Render.createToggleRow = function(entry)
    createSubsectionHeader(entry)
    local section = Layout.getSection(entry.tab, entry.column, entry.section)
    local hasPicker = entry.picker == true

    local row = create("TextButton", {
        Parent = section.holder,
        BackgroundColor3 = Theme.accent,
        BackgroundTransparency = 1,
        BorderSizePixel = 0,
        Size = UDim2.new(1, -2, 0, 16),
        AutoButtonColor = false,
        Text = "",
        ZIndex = 20,
    })

    local rowShade = applyGradient(row, Color3.fromRGB(255, 255, 255), Color3.fromRGB(167, 167, 167), 90)

    local leftHolder = create("Frame", {
        Parent = row,
        BackgroundTransparency = 1,
        Size = hasPicker and UDim2.new(1, -86, 1, 0) or UDim2.new(1, -58, 1, 0),
        ZIndex = 20,
    })

    create("UIListLayout", {
        Parent = leftHolder,
        FillDirection = Enum.FillDirection.Horizontal,
        Padding = UDim.new(0, 5),
        VerticalAlignment = Enum.VerticalAlignment.Center,
        SortOrder = Enum.SortOrder.LayoutOrder,
    })

    local toggleShell = addShell(leftHolder, UDim2.fromOffset(14, 14), UDim2.fromOffset(0, 0), false, 0, 21)
    toggleShell.outline.LayoutOrder = 1

    local toggleFill = create("Frame", {
        Parent = toggleShell.background,
        BorderSizePixel = 0,
        BackgroundColor3 = entry.color,
        Position = UDim2.fromOffset(1, 1),
        Size = UDim2.new(1, -2, 1, -2),
        BackgroundTransparency = 1,
        ZIndex = 24,
    })

    local toggleFillGradient = applyGradient(toggleFill, Color3.fromRGB(255, 255, 255), Color3.fromRGB(167, 167, 167), 90)

    local label = createThemedText(leftHolder, {
        Parent = leftHolder,
        BackgroundTransparency = 1,
        AutomaticSize = Enum.AutomaticSize.X,
        Size = UDim2.new(0, 0, 1, 0),
        Font = Enum.Font.GothamMedium,
        Text = entry.name,
        TextSize = 12,
        TextXAlignment = Enum.TextXAlignment.Left,
        ZIndex = 21,
    }, false)
    label.LayoutOrder = 2

    local rightHolder = create("Frame", {
        Parent = row,
        BackgroundTransparency = 1,
        AnchorPoint = Vector2.new(1, 0),
        Position = UDim2.new(1, 0, 0, 0),
        Size = hasPicker and UDim2.new(0, 84, 1, 0) or UDim2.fromOffset(56, 16),
        ZIndex = 20,
    })

    local rightLayout = create("UIListLayout", {
        Parent = rightHolder,
        FillDirection = Enum.FillDirection.Horizontal,
        HorizontalAlignment = Enum.HorizontalAlignment.Right,
        VerticalAlignment = Enum.VerticalAlignment.Center,
        Padding = UDim.new(0, 4),
        SortOrder = Enum.SortOrder.LayoutOrder,
    })

    local bindText = createThemedText(rightHolder, {
        Parent = rightHolder,
        BackgroundTransparency = 1,
        Size = UDim2.fromOffset(56, 16),
        AutomaticSize = Enum.AutomaticSize.X,
        Font = Enum.Font.Code,
        Text = formatToggleBindText(entry),
        TextSize = 11,
        ZIndex = 23,
    }, false)

    local colorShell
    local colorDisplay
    local colorButton

    if hasPicker then
        colorShell = addShell(rightHolder, UDim2.fromOffset(24, 14), UDim2.fromOffset(0, 0), false, 0, 21)
        colorDisplay = create("Frame", {
            Parent = colorShell.background,
            BorderSizePixel = 0,
            BackgroundColor3 = entry.color,
            Position = UDim2.fromOffset(1, 1),
            Size = UDim2.new(1, -2, 1, -2),
            ZIndex = 23,
        })

        colorButton = create("TextButton", {
            Parent = colorShell.outline,
            BackgroundTransparency = 1,
            Size = UDim2.new(1, 0, 1, 0),
            Text = "",
            AutoButtonColor = false,
            ZIndex = 24,
        })
    end

    entry.ui = {
        row = row,
        rowShade = rowShade,
        fill = toggleFill,
        fillGradient = toggleFillGradient,
        label = label,
        bindText = bindText,
        colorDisplay = colorDisplay,
        colorButton = colorButton,
    }

    if colorButton then
        colorButton.MouseButton1Click:Connect(function()
            PickerRuntime.openEntry = entry
            PickerRuntime.isOpen = true
        end)
    end

    row.MouseButton1Click:Connect(function()
        entry.state = entry.mode == "always" and true or not entry.state
        safeCallback(entry.callback, entry.state)
        refreshRows()
        updateWatermark()
    end)

    row.MouseButton2Click:Connect(function()
        if MenuState.bindPopupCurrent == entry then
            MenuState.bindPopupEntry = nil
        else
            MenuState.bindPopupEntry = entry
        end
        MenuState.bindPopupListening = false
    end)

    row.MouseEnter:Connect(function()
        tween(row, 0.14, {
            BackgroundTransparency = entry.state and 0.9 or 0.955,
        }, Enum.EasingStyle.Quad)
    end)

    row.MouseLeave:Connect(function()
        tween(row, 0.14, {
            BackgroundTransparency = 1,
        }, Enum.EasingStyle.Quad)
    end)

    createKeybindEntry(entry)
end

Render.createButtonRow = function(entry)
    createSubsectionHeader(entry)
    local section = Layout.getSection(entry.tab, entry.column, entry.section)

    local row = create("TextButton", {
        Parent = section.holder,
        BackgroundColor3 = Theme.accent,
        BackgroundTransparency = 1,
        BorderSizePixel = 0,
        Size = UDim2.new(1, -2, 0, 16),
        AutoButtonColor = false,
        Text = "",
        ZIndex = 20,
    })

    applyGradient(row, Color3.fromRGB(255, 255, 255), Color3.fromRGB(167, 167, 167), 90)

    local label = createThemedText(row, {
        Parent = row,
        BackgroundTransparency = 1,
        Size = UDim2.new(1, 0, 1, 0),
        Font = Enum.Font.GothamMedium,
        Text = entry.name,
        TextSize = 12,
        TextXAlignment = Enum.TextXAlignment.Left,
        ZIndex = 21,
    }, false)

    entry.ui = {
        row = row,
        label = label,
    }

    row.MouseEnter:Connect(function()
        tween(row, 0.14, {
            BackgroundTransparency = 0.93,
        }, Enum.EasingStyle.Quad)
    end)

    row.MouseLeave:Connect(function()
        tween(row, 0.14, {
            BackgroundTransparency = 1,
        }, Enum.EasingStyle.Quad)
    end)

    row.MouseButton1Click:Connect(function()
        safeCallback(entry.callback)
    end)
end

Render.createSliderRow = function(entry)
    createSubsectionHeader(entry)
    local section = Layout.getSection(entry.tab, entry.column, entry.section)

    local row = create("Frame", {
        Parent = section.holder,
        BackgroundTransparency = 1,
        BorderSizePixel = 0,
        Size = UDim2.new(1, -2, 0, 30),
        ZIndex = 20,
    })

    local label = createThemedText(row, {
        Parent = row,
        BackgroundTransparency = 1,
        Position = UDim2.fromOffset(0, 0),
        Size = UDim2.new(1, -72, 0, 14),
        Font = Enum.Font.GothamMedium,
        Text = entry.name,
        TextSize = 12,
        TextXAlignment = Enum.TextXAlignment.Left,
        ZIndex = 21,
    }, false)

    local valueLabel = create("TextBox", {
        Parent = row,
        BackgroundTransparency = 1,
        AnchorPoint = Vector2.new(1, 0),
        Position = UDim2.new(1, 0, 0, 0),
        Size = UDim2.fromOffset(68, 14),
        Font = Enum.Font.Code,
        Text = "",
        ClearTextOnFocus = false,
        TextSize = 11,
        TextXAlignment = Enum.TextXAlignment.Right,
        TextColor3 = Theme.textDim,
        ZIndex = 21,
    })
    registerTheme("textDim", valueLabel, "TextColor3")

    create("UIStroke", {
        Parent = valueLabel,
        Transparency = 0.75,
        Thickness = 1,
        LineJoinMode = Enum.LineJoinMode.Miter,
    })

    local barShell = addShell(row, UDim2.new(1, 0, 0, 10), UDim2.fromOffset(0, 18), false, 0, 21)
    barShell.background.ClipsDescendants = false
    local glow = create("Frame", {
        Parent = barShell.background,
        AnchorPoint = Vector2.new(0, 0.5),
        BorderSizePixel = 0,
        BackgroundColor3 = getSliderGlowColor(entry),
        Position = UDim2.new(0, 0, 0.5, 0),
        Size = UDim2.new(0, 0, 1, 4),
        BackgroundTransparency = 0.74,
        ZIndex = 22,
    })
    applyCorner(glow, 4)

    local fill = create("Frame", {
        Parent = barShell.background,
        BorderSizePixel = 0,
        BackgroundColor3 = entry.color or Theme.accent,
        Size = UDim2.new(0, 0, 1, 0),
        ZIndex = 23,
    })
    registerTheme("accent", fill, "BackgroundColor3")
    applyCorner(fill, 3)

    local barButton = create("TextButton", {
        Parent = barShell.outline,
        BackgroundTransparency = 1,
        Size = UDim2.new(1, 0, 1, 0),
        Text = "",
        AutoButtonColor = false,
        ZIndex = 24,
    })

    local dragging = false
    local internalTextChange = false

    local function setFromX(positionX)
        local width = math.max(barShell.outline.AbsoluteSize.X, 1)
        local relative = math.clamp(positionX - barShell.outline.AbsolutePosition.X, 0, width)
        local alpha = relative / width
        local range = entry.max - entry.min
        applySliderValue(entry, entry.min + (range * alpha), true)
        refreshRows()
    end

    valueLabel:GetPropertyChangedSignal("Text"):Connect(function()
        if not entry.editingValue or internalTextChange then
            return
        end

        local sanitized = sanitizeSliderInputText(entry, valueLabel.Text, false)
        if sanitized ~= valueLabel.Text then
            internalTextChange = true
            valueLabel.Text = sanitized
            internalTextChange = false
        end
    end)

    valueLabel.Focused:Connect(function()
        entry.editingValue = true
        internalTextChange = true
        valueLabel.Text = formatSliderInputValue(entry, entry.value)
        internalTextChange = false
        valueLabel.TextColor3 = Theme.text
    end)

    valueLabel.FocusLost:Connect(function()
        local sanitized = sanitizeSliderInputText(entry, valueLabel.Text, true)
        local rawNumber = tonumber(sanitized)

        entry.editingValue = false
        valueLabel.TextColor3 = Theme.textDim

        if rawNumber ~= nil then
            applySliderValue(entry, rawNumber, true)
        else
            internalTextChange = true
            valueLabel.Text = formatSliderInputValue(entry, entry.value)
            internalTextChange = false
        end

        refreshRows()
    end)

    barButton.InputBegan:Connect(function(input)
        if input.UserInputType ~= Enum.UserInputType.MouseButton1 then
            return
        end

        dragging = true
        setFromX(input.Position.X)
    end)

    trackRuntimeConnection(Services.UserInputService.InputChanged:Connect(function(input)
        if dragging and input.UserInputType == Enum.UserInputType.MouseMovement then
            setFromX(input.Position.X)
        end
    end))

    trackRuntimeConnection(Services.UserInputService.InputEnded:Connect(function(input)
        if input.UserInputType == Enum.UserInputType.MouseButton1 then
            dragging = false
        end
    end))

    entry.ui = {
        row = row,
        label = label,
        valueLabel = valueLabel,
        glow = glow,
        fill = fill,
    }
end

Render.createTextboxRow = function(entry)
    createSubsectionHeader(entry)
    local section = Layout.getSection(entry.tab, entry.column, entry.section)

    local row = create("Frame", {
        Parent = section.holder,
        BackgroundTransparency = 1,
        BorderSizePixel = 0,
        Size = UDim2.new(1, -2, 0, 30),
        ZIndex = 20,
    })

    local label = createThemedText(row, {
        Parent = row,
        BackgroundTransparency = 1,
        Position = UDim2.fromOffset(0, 0),
        Size = UDim2.new(1, 0, 0, 14),
        Font = Enum.Font.GothamMedium,
        Text = entry.name,
        TextSize = 12,
        TextXAlignment = Enum.TextXAlignment.Left,
        ZIndex = 21,
    }, false)

    local inputShell = addShell(row, UDim2.new(1, 0, 0, 12), UDim2.fromOffset(0, 18), false, 0, 21)

    local input = create("TextBox", {
        Parent = inputShell.background,
        BackgroundTransparency = 1,
        Position = UDim2.fromOffset(4, -1),
        Size = UDim2.new(1, -8, 1, 2),
        Font = Enum.Font.Code,
        Text = tostring(entry.value or ""),
        PlaceholderText = tostring(entry.placeholder or ""),
        PlaceholderColor3 = Theme.textDim,
        ClearTextOnFocus = false,
        TextSize = 11,
        TextXAlignment = Enum.TextXAlignment.Left,
        TextColor3 = Theme.textDim,
        ZIndex = 23,
    })
    registerTheme("textDim", input, "TextColor3")

    create("UIStroke", {
        Parent = input,
        Transparency = 0.75,
        Thickness = 1,
        LineJoinMode = Enum.LineJoinMode.Miter,
    })

    input:GetPropertyChangedSignal("Text"):Connect(function()
        entry.value = input.Text
    end)

    input.Focused:Connect(function()
        entry.editingText = true
        input.TextColor3 = Theme.text
    end)

    input.FocusLost:Connect(function(enterPressed)
        entry.editingText = false
        entry.value = input.Text
        input.TextColor3 = Theme.textDim
        safeCallback(entry.callback, entry.value, enterPressed)
        refreshRows()
    end)

    entry.ui = {
        row = row,
        label = label,
        input = input,
    }
end

Render.createDropdownRow = function(entry)
    createSubsectionHeader(entry)
    local section = Layout.getSection(entry.tab, entry.column, entry.section)

    local row = create("Frame", {
        Parent = section.holder,
        BackgroundTransparency = 1,
        BorderSizePixel = 0,
        Size = UDim2.new(1, -2, 0, 16),
        ZIndex = 20,
    })

    local button = create("TextButton", {
        Parent = row,
        BackgroundColor3 = Theme.accent,
        BackgroundTransparency = 1,
        BorderSizePixel = 0,
        Size = UDim2.new(1, 0, 0, 16),
        AutoButtonColor = false,
        Text = "",
        ZIndex = 20,
    })

    applyGradient(button, Color3.fromRGB(255, 255, 255), Color3.fromRGB(167, 167, 167), 90)

    local label = createThemedText(button, {
        Parent = button,
        BackgroundTransparency = 1,
        Size = UDim2.new(1, -90, 1, 0),
        Font = Enum.Font.GothamMedium,
        Text = entry.name,
        TextSize = 12,
        TextXAlignment = Enum.TextXAlignment.Left,
        ZIndex = 21,
    }, false)

    local valueLabel = createThemedText(button, {
        Parent = button,
        BackgroundTransparency = 1,
        AnchorPoint = Vector2.new(1, 0),
        Position = UDim2.new(1, 0, 0, 0),
        Size = UDim2.fromOffset(86, 16),
        Font = Enum.Font.Code,
        Text = "",
        TextSize = 11,
        TextTruncate = Enum.TextTruncate.AtEnd,
        TextXAlignment = Enum.TextXAlignment.Right,
        ZIndex = 21,
    }, true)

    button.MouseEnter:Connect(function()
        tween(button, 0.14, {
            BackgroundTransparency = 0.94,
        }, Enum.EasingStyle.Quad)
    end)

    button.MouseLeave:Connect(function()
        tween(button, 0.14, {
            BackgroundTransparency = 1,
        }, Enum.EasingStyle.Quad)
    end)

    button.MouseButton1Click:Connect(function()
        for _, other in ipairs(Entries) do
            if other.kind == "dropdown" and other ~= entry then
                other.open = false
            end
        end

        entry.open = not entry.open
        if not entry.open then
            Panels.closeDropdown()
        end
        refreshRows()
    end)

    entry.ui = {
        row = row,
        button = button,
        label = label,
        valueLabel = valueLabel,
    }
end

Render.createKeybindRow = function(entry)
    createSubsectionHeader(entry)
    local section = Layout.getSection(entry.tab, entry.column, entry.section)

    local row = create("TextButton", {
        Parent = section.holder,
        BackgroundColor3 = Theme.accent,
        BackgroundTransparency = 1,
        BorderSizePixel = 0,
        Size = UDim2.new(1, -2, 0, 16),
        AutoButtonColor = false,
        Text = "",
        ZIndex = 20,
    })

    applyGradient(row, Color3.fromRGB(255, 255, 255), Color3.fromRGB(167, 167, 167), 90)

    local label = createThemedText(row, {
        Parent = row,
        BackgroundTransparency = 1,
        Size = UDim2.new(1, -72, 1, 0),
        Font = Enum.Font.GothamMedium,
        Text = entry.name,
        TextSize = 12,
        TextXAlignment = Enum.TextXAlignment.Left,
        ZIndex = 21,
    }, false)

    local bindText = createThemedText(row, {
        Parent = row,
        BackgroundTransparency = 1,
        AnchorPoint = Vector2.new(1, 0),
        Position = UDim2.new(1, 0, 0, 0),
        Size = UDim2.fromOffset(68, 16),
        Font = Enum.Font.Code,
        Text = "",
        TextSize = 11,
        TextXAlignment = Enum.TextXAlignment.Right,
        ZIndex = 21,
    }, true)

    entry.ui = {
        row = row,
        label = label,
        bindText = bindText,
    }

    row.MouseEnter:Connect(function()
        tween(row, 0.14, {
            BackgroundTransparency = 0.94,
        }, Enum.EasingStyle.Quad)
    end)

    row.MouseLeave:Connect(function()
        tween(row, 0.14, {
            BackgroundTransparency = 1,
        }, Enum.EasingStyle.Quad)
    end)

    row.MouseButton1Click:Connect(function()
        MenuState.listeningKeybindEntry = entry
        refreshRows()
    end)

    row.MouseButton2Click:Connect(function()
        entry.bind = nil
        MenuState.listeningKeybindEntry = nil
        safeCallback(entry.changed, entry.bind)
        refreshRows()
    end)
end

Render.createColorRow = function(entry)
    createSubsectionHeader(entry)
    local section = Layout.getSection(entry.tab, entry.column, entry.section)

    local row = create("Frame", {
        Parent = section.holder,
        BackgroundTransparency = 1,
        BorderSizePixel = 0,
        Size = UDim2.new(1, -2, 0, 16),
        ZIndex = 20,
    })

    local label = createThemedText(row, {
        Parent = row,
        BackgroundTransparency = 1,
        Size = UDim2.new(1, -30, 1, 0),
        Font = Enum.Font.GothamMedium,
        Text = entry.name,
        TextSize = 12,
        TextXAlignment = Enum.TextXAlignment.Left,
        ZIndex = 21,
    }, false)

    local colorShell = addShell(row, UDim2.fromOffset(24, 14), UDim2.new(1, 0, 0.5, -7), false, 0, 21)
    colorShell.outline.AnchorPoint = Vector2.new(1, 0)
    local colorDisplay = create("Frame", {
        Parent = colorShell.background,
        BorderSizePixel = 0,
        BackgroundColor3 = entry.color,
        Position = UDim2.fromOffset(1, 1),
        Size = UDim2.new(1, -2, 1, -2),
        ZIndex = 23,
    })

    local colorButton = create("TextButton", {
        Parent = colorShell.outline,
        BackgroundTransparency = 1,
        Size = UDim2.new(1, 0, 1, 0),
        Text = "",
        AutoButtonColor = false,
        ZIndex = 24,
    })

    entry.ui = {
        row = row,
        label = label,
        colorDisplay = colorDisplay,
        colorButton = colorButton,
    }

    colorButton.MouseButton1Click:Connect(function()
        PickerRuntime.openEntry = entry
        PickerRuntime.isOpen = true
    end)
end

end

local function getFlagState(flagName)
    local entry = EntryMap[flagName]
    return (entry and entry.state) == true or (entry and entry.mode == "always")
end

local function getFlagColor(flagName)
    local entry = EntryMap[flagName]
    return entry and entry.color or Color3.new(1, 1, 1)
end

local function getFlagValue(flagName)
    local entry = EntryMap[flagName]
    return entry and entry.value or ""
end

Render.createESPPreviewRow = function(entry)
    local previewSize = Vector2.new(300, 325)
    local previewGui = create("ScreenGui", {
        Parent = RootGui,
        Name = "NeverPastePreview_" .. math.random(10000, 99999),
        ResetOnSpawn = false,
        IgnoreGuiInset = true,
        ZIndexBehavior = Enum.ZIndexBehavior.Sibling,
        DisplayOrder = ScreenGui.DisplayOrder,
    })

    local function getPreviewPosition()
        local viewportSize = getViewportSize()
        local x = 20
        local y = 110

        if Window and Window.Parent then
            x = Window.AbsolutePosition.X
            y = Window.AbsolutePosition.Y + Window.AbsoluteSize.Y + 2
        end

        return UDim2.fromOffset(
            math.clamp(x, 10, math.max(10, viewportSize.X - previewSize.X - 10)),
            math.clamp(y, 10, math.max(10, viewportSize.Y - previewSize.Y - 10))
        )
    end

    local shell = addShell(previewGui, UDim2.fromOffset(previewSize.X, previewSize.Y), getPreviewPosition(), true, 0, 32)
    shell.outline.Visible = MenuState.introDone and MenuState.visible
    shell.outline.ClipsDescendants = true

    local header = create("Frame", {
        Parent = shell.background,
        BackgroundTransparency = 1,
        Position = UDim2.fromOffset(6, 4),
        Size = UDim2.new(1, -12, 0, 18),
        Active = true,
        ZIndex = 34,
    })

    createThemedText(header, {
        Parent = header,
        BackgroundTransparency = 1,
        Position = UDim2.fromOffset(2, 0),
        Size = UDim2.new(1, -4, 1, 0),
        Font = Enum.Font.GothamMedium,
        Text = entry.name ~= "" and entry.name or "ESP Preview",
        TextSize = 12,
        TextXAlignment = Enum.TextXAlignment.Left,
        ZIndex = 35,
    }, false)

    local dragHandle = create("TextButton", {
        Parent = header,
        BackgroundTransparency = 1,
        Size = UDim2.new(1, 0, 1, 0),
        Text = "",
        AutoButtonColor = false,
        ZIndex = 36,
    })

    local previewArea = create("Frame", {
        Parent = shell.background,
        BackgroundTransparency = 1,
        Position = UDim2.fromOffset(6, 24),
        Size = UDim2.new(1, -12, 1, -30),
        ZIndex = 33,
    })

    local viewportShell = addShell(previewArea, UDim2.new(1, 0, 1, 0), UDim2.fromOffset(0, 0), false, 0, 33)
    local viewport = create("ViewportFrame", {
        Parent = viewportShell.background,
        BackgroundColor3 = Color3.fromRGB(6, 10, 16),
        BorderSizePixel = 0,
        Size = UDim2.new(1, 0, 1, 0),
        ZIndex = 34,
    })

    local overlay = create("Frame", {
        Parent = viewportShell.background,
        BackgroundTransparency = 1,
        Size = UDim2.new(1, 0, 1, 0),
        ZIndex = 35,
    })

    local camera = create("Camera", {
        Parent = Services.Workspace,
        FieldOfView = 70.00022888183594,
        CameraType = Enum.CameraType.Track,
        Focus = CFrame.new(0, 0, 0, 1, 0, 0, 0, 1, 0, 0, 0, 1),
        CFrame = CFrame.new(0, 0, 0, 1, 0, 0, 0, 1, 0, 0, 0, 1),
        Name = "NeverPastePreviewCamera_" .. math.random(10000, 99999),
    })

    viewport.CurrentCamera = camera

    LocalPlayer.Character.Archivable = true
    local character = LocalPlayer.Character:Clone()
    if character:FindFirstChild("Animate") then
        character.Animate:Destroy()
    end
    character.Parent = viewport
    
    camera.CameraSubject = character

    local holder = create("Frame", {
        Parent = overlay,
        BackgroundTransparency = 1,
        Position = UDim2.new(0.5, 0, 0.5, 10),
        Size = UDim2.fromOffset(135, 190),
        AnchorPoint = Vector2.new(0.5, 0.5),
        ZIndex = 36,
    })

    local cacheInfoFrame = create("Frame", {
        Parent = shell.background,
        BackgroundTransparency = 1,
        Position = UDim2.fromOffset(-1000, -1000),
        Size = UDim2.fromOffset(0, 0),
        Visible = false,
    })

    local objects = { holder = holder, cache = cacheInfoFrame }

    objects.name = create("TextLabel", {
        Parent = cacheInfoFrame,
        BackgroundTransparency = 1,
        Text = string.format("%s (@%s)", LocalPlayer.DisplayName, LocalPlayer.Name),
        AnchorPoint = Vector2.new(0, 1),
        Position = UDim2.new(0, 0, 0, -5),
        Size = UDim2.new(1, 0, 0, 0),
        AutomaticSize = Enum.AutomaticSize.Y,
        Font = Enum.Font.GothamMedium,
        TextSize = 12,
        ZIndex = 37,
    })
    create("UIStroke", {
        Parent = objects.name,
        Transparency = 0.5,
        Thickness = 1,
        LineJoinMode = Enum.LineJoinMode.Miter,
    })

    objects.boxHandler = create("Frame", {
        Parent = cacheInfoFrame,
        BackgroundTransparency = 1,
        Position = UDim2.new(0, 1, 0, 1),
        Size = UDim2.new(1, -2, 1, -2),
        ZIndex = 36,
    })
    objects.boxColor = create("UIStroke", {
        Parent = objects.boxHandler,
        LineJoinMode = Enum.LineJoinMode.Miter,
        Color = Color3.new(1, 1, 1),
    })
    objects.outline = create("Frame", {
        Parent = objects.boxHandler,
        BackgroundTransparency = 1,
        Position = UDim2.new(0, 1, 0, 1),
        Size = UDim2.new(1, -2, 1, -2),
        ZIndex = 36,
    })
    create("UIStroke", {
        Parent = objects.outline,
        LineJoinMode = Enum.LineJoinMode.Miter,
    })

    objects.corners = create("Frame", {
        Parent = cacheInfoFrame,
        BackgroundTransparency = 1,
        Position = UDim2.new(0, -1, 0, 2),
        Size = UDim2.new(1, 0, 1, 0),
        ZIndex = 36,
    })

    local function makeCorner(parent, position, size, anchor, rotation)
        local frame = create("Frame", {
            Parent = parent,
            BackgroundColor3 = Color3.new(0, 0, 0),
            BorderSizePixel = 0,
            Position = position,
            Size = size,
            AnchorPoint = anchor or Vector2.new(0, 0),
            Rotation = rotation or 0,
            ZIndex = 36,
        })
        local inner = create("Frame", {
            Parent = frame,
            BorderSizePixel = 0,
            Position = UDim2.new(0, 1, 0, 1),
            Size = UDim2.new(1, -2, 1, -2),
            ZIndex = 37,
            BackgroundColor3 = Color3.new(1, 1, 1),
        })
        return { outline = frame, inner = inner }
    end

    objects.corner1 = makeCorner(objects.corners, UDim2.new(0, 0, 0, -2), UDim2.new(0.4, 0, 0, 3))
    objects.corner2 = makeCorner(objects.corners, UDim2.new(0, 0, 0, 1), UDim2.new(0, 3, 0.25, 0))
    objects.corner3 = makeCorner(objects.corners, UDim2.new(1, 0, 0, -2), UDim2.new(0.4, 0, 0, 3), Vector2.new(1, 0))
    objects.corner4 = makeCorner(objects.corners, UDim2.new(1, 0, 0, 1), UDim2.new(0, 3, 0.25, 0), Vector2.new(1, 0))
    objects.corner5 = makeCorner(objects.corners, UDim2.new(0, -1, 1, -2), UDim2.new(0.4, 0, 0, 3), Vector2.new(0, 1))
    objects.corner6 = makeCorner(objects.corners, UDim2.new(0, 0, 1, -4), UDim2.new(0, 3, 0.25, 1), Vector2.new(0, 1), 180)
    objects.corner7 = makeCorner(objects.corners, UDim2.new(1, -1, 1, -2), UDim2.new(0.4, 0, 0, 3), Vector2.new(1, 1))
    objects.corner8 = makeCorner(objects.corners, UDim2.new(1, 0, 1, -4), UDim2.new(0, 3, 0.25, 1), Vector2.new(1, 1), 180)

    objects.corner2.inner.Position = UDim2.new(0, 1, 0, -2)
    objects.corner2.inner.Size = UDim2.new(1, -2, 1, 1)
    objects.corner4.inner.Position = UDim2.new(0, 1, 0, -2)
    objects.corner4.inner.Size = UDim2.new(1, -2, 1, 1)
    objects.corner6.inner.Position = UDim2.new(0, 1, 0, -2)
    objects.corner6.inner.Size = UDim2.new(1, -2, 1, 1)
    objects.corner8.inner.Position = UDim2.new(0, 1, 0, -2)
    objects.corner8.inner.Size = UDim2.new(1, -2, 1, 1)

    objects.healthbarHolder = create("Frame", {
        Parent = cacheInfoFrame,
        BackgroundColor3 = Color3.new(0, 0, 0),
        BorderSizePixel = 0,
        Position = UDim2.new(0, -5, 0, 0),
        Size = UDim2.new(0, 4, 1, 0),
        AnchorPoint = Vector2.new(1, 0),
        ZIndex = 36,
    })

    objects.healthbar = create("Frame", {
        Parent = objects.healthbarHolder,
        BackgroundColor3 = Color3.new(1, 1, 1),
        BorderSizePixel = 0,
        Position = UDim2.new(0, 1, 0, 1),
        Size = UDim2.new(1, -2, 1, -2),
        ZIndex = 37,
    })

    objects.distance = create("TextLabel", {
        Parent = cacheInfoFrame,
        BackgroundTransparency = 1,
        Text = "127 studs",
        Position = UDim2.new(0, 0, 1, 5),
        Size = UDim2.new(1, 0, 0, 0),
        AutomaticSize = Enum.AutomaticSize.Y,
        Font = Enum.Font.GothamMedium,
        TextSize = 12,
        ZIndex = 37,
    })
    create("UIStroke", {
        Parent = objects.distance,
        Transparency = 0.5,
        Thickness = 1,
        LineJoinMode = Enum.LineJoinMode.Miter,
    })

    objects.weapon = create("TextLabel", {
        Parent = cacheInfoFrame,
        BackgroundTransparency = 1,
        Text = "[ Weapon ]",
        Position = UDim2.new(0, 0, 1, 19),
        Size = UDim2.new(1, 0, 0, 0),
        AutomaticSize = Enum.AutomaticSize.Y,
        Font = Enum.Font.GothamMedium,
        TextSize = 12,
        ZIndex = 37,
    })
    create("UIStroke", {
        Parent = objects.weapon,
        Transparency = 0.5,
        Thickness = 1,
        LineJoinMode = Enum.LineJoinMode.Miter,
    })

    local dockedToWindow = true
    local previewDragging = false
    local previewDragInput
    local previewDragStart
    local previewDragStartPosition

    local function clampPreviewPosition(position)
        local viewportSize = getViewportSize()
        return Vector2.new(
            math.clamp(position.X, 10, math.max(10, viewportSize.X - previewSize.X - 10)),
            math.clamp(position.Y, 10, math.max(10, viewportSize.Y - previewSize.Y - 10))
        )
    end

    dragHandle.InputBegan:Connect(function(input)
        if input.UserInputType ~= Enum.UserInputType.MouseButton1 then
            return
        end

        dockedToWindow = false
        previewDragging = true
        previewDragStart = input.Position
        previewDragStartPosition = shell.outline.Position

        local releaseConnection
        releaseConnection = input.Changed:Connect(function()
            if input.UserInputState == Enum.UserInputState.End then
                previewDragging = false
                previewDragInput = nil
                if releaseConnection then
                    releaseConnection:Disconnect()
                end
            end
        end)
    end)

    dragHandle.InputChanged:Connect(function(input)
        if input.UserInputType == Enum.UserInputType.MouseMovement then
            previewDragInput = input
        end
    end)

    trackRuntimeConnection(Services.UserInputService.InputChanged:Connect(function(input)
        if not previewDragging or input ~= previewDragInput or not previewDragStartPosition then
            return
        end

        local delta = input.Position - previewDragStart
        local clampedPosition = clampPreviewPosition(Vector2.new(
            previewDragStartPosition.X.Offset + delta.X,
            previewDragStartPosition.Y.Offset + delta.Y
        ))

        shell.outline.Position = UDim2.fromOffset(clampedPosition.X, clampedPosition.Y)
    end))

    local function updatePreviewVisibility()
        local isVisible = (entry.visible ~= false) and MenuState.introDone and MenuState.visible
        previewGui.Enabled = isVisible
        shell.outline.Visible = isVisible
    end

    local function updatePreviewPosition()
        if not dockedToWindow or not shell.outline.Parent then
            return
        end

        shell.outline.Position = getPreviewPosition()
    end

    local function updateHealthBar()
        if objects.healthbarHolder.Parent ~= holder then
            return
        end

        local alpha = math.abs(math.sin(tick() * 2))
        local lowColor = getFlagColor("Health_Low")
        local highColor = getFlagColor("Health_High")
        objects.healthbar.Size = UDim2.new(1, -2, alpha, -2)
        objects.healthbar.Position = UDim2.new(0, 1, 1 - alpha, 1)
        objects.healthbar.BackgroundColor3 = lowColor:Lerp(highColor, alpha)
    end

    local function refreshPreview()
        updatePreviewVisibility()

        local enabled = getFlagState("Enabled")
        holder.Visible = enabled

        objects.name.TextColor3 = getFlagColor("Name_Color")
        objects.name.Parent = enabled and getFlagState("Names") and holder or cacheInfoFrame

        objects.distance.TextColor3 = getFlagColor("Distance_Color")
        objects.distance.Parent = enabled and getFlagState("Distance") and holder or cacheInfoFrame

        objects.weapon.TextColor3 = getFlagColor("Weapon_Color")
        objects.weapon.Parent = enabled and getFlagState("Weapon") and holder or cacheInfoFrame

        objects.healthbarHolder.Parent = enabled and getFlagState("Healthbar") and holder or cacheInfoFrame

        local boxColor = getFlagColor("Box_Color")
        objects.boxColor.Color = boxColor
        for index = 1, 8 do
            objects["corner" .. index].inner.BackgroundColor3 = boxColor
        end

        if enabled and getFlagState("Boxes") then
            if getFlagValue("Box_Type") == "Full" then
                objects.boxHandler.Parent = holder
                objects.corners.Parent = cacheInfoFrame
            else
                objects.corners.Parent = holder
                objects.boxHandler.Parent = cacheInfoFrame
            end
        else
            objects.corners.Parent = cacheInfoFrame
            objects.boxHandler.Parent = cacheInfoFrame
        end
    end

    trackRuntimeConnection(Services.RunService.RenderStepped:Connect(function()
        if not shell.outline.Parent then
            return
        end

        if character.PrimaryPart then
            character:SetPrimaryPartCFrame(CFrame.new(Vector3.new(0, -1, -6)))
        end

        updatePreviewPosition()
        updateHealthBar()
        refreshPreview()
    end))

    entry.ui = {
        row = shell.outline,
        shell = shell,
        gui = previewGui,
        character = character,
        camera = camera,
        cache = cacheInfoFrame,
    }
end

for _, entry in ipairs(Entries) do
    if entry.kind == "toggle" then
        Render.createToggleRow(entry)
    elseif entry.kind == "esppreview" then
        Render.createESPPreviewRow(entry)
    elseif entry.kind == "button" then
        Render.createButtonRow(entry)
    elseif entry.kind == "slider" then
        Render.createSliderRow(entry)
    elseif entry.kind == "textbox" then
        Render.createTextboxRow(entry)
    elseif entry.kind == "dropdown" then
        Render.createDropdownRow(entry)
    elseif entry.kind == "keybind" then
        Render.createKeybindRow(entry)
    elseif entry.kind == "color" then
        Render.createColorRow(entry)
    end
end

Layout.selectTab = function(id)
    CurrentTab = id

    for tabId, tab in pairs(Tabs) do
        local selected = tabId == id
        tab.fill.BackgroundTransparency = selected and 0 or 1
        tab.fill.Size = selected and UDim2.new(1, 0, 1, 0) or UDim2.new(0, 0, 1, 0)
        tab.icon.ImageColor3 = selected and Theme.text or Theme.textDim
        tab.label.TextColor3 = selected and Theme.text or Theme.text
        tab.page.Visible = selected
        tab.page.Position = UDim2.fromOffset(0, 0)
    end

    task.defer(function()
        for columnIndex = 1, 3 do
            Layout.relayoutSectionColumn(id, columnIndex)
        end
    end)
end

end

-- Menu motion, overlays and refresh
do

local function getBindDisplayText(entry)
    return formatToggleBindText(entry)
end

local function updateBindPopup()
    if not MenuState.bindPopupCurrent then
        return
    end

    BindPopupTitle.Text = MenuState.bindPopupCurrent.name .. " Bind"
    BindFieldText.Text = MenuState.bindPopupListening and "press any key..." or getBindDisplayText(MenuState.bindPopupCurrent)

    for modeId, data in pairs(ModeButtons) do
        local selected = MenuState.bindPopupCurrent.mode == modeId
        data.fill.BackgroundTransparency = selected and 0 or 1
        data.text.TextColor3 = selected and Theme.text or Theme.text
    end
end

Motion.openBindPopup = function(entry)
    if not entry or not entry.ui or not entry.ui.row then
        BindPopupShell.outline.Visible = false
        BindOverlay.Visible = false
        MenuState.bindPopupCurrent = nil
        MenuState.bindPopupListening = false
        return
    end

    MenuState.bindPopupCurrent = entry
    MenuState.bindPopupListening = false

    local rowPosition = entry.ui.row.AbsolutePosition
    local viewport = getViewportSize()
    local x = math.clamp(rowPosition.X + 140, 10, viewport.X - 176)
    local y = math.clamp(rowPosition.Y + 18, 10, viewport.Y - 110)

    BindPopupShell.outline.Position = UDim2.fromOffset(x, y)
    BindPopupShell.outline.Visible = true
    BindOverlay.Visible = true
    updateBindPopup()
end

Motion.closeBindPopup = function()
    BindPopupShell.outline.Visible = false
    BindOverlay.Visible = false
    MenuState.bindPopupCurrent = nil
    MenuState.bindPopupListening = false
    MenuState.bindPopupEntry = nil
end

Motion.closePicker = function()
    PickerShell.outline.Visible = false
    PickerOverlay.Visible = false
    PickerState.target = nil
    PickerRuntime.openEntry = nil
    PickerRuntime.isOpen = false
    PickerRuntime.mode = nil
end

local function trackMenuTween(tweenObject)
    if tweenObject then
        MenuMotion.tweens[#MenuMotion.tweens + 1] = tweenObject
    end

    return tweenObject
end

local function trackMenuConnection(connection)
    if connection then
        MenuMotion.connections[#MenuMotion.connections + 1] = connection
    end

    return connection
end

local function clearMenuTweenState()
    for _, connection in ipairs(MenuMotion.connections) do
        connection:Disconnect()
    end

    table.clear(MenuMotion.tweens)
    table.clear(MenuMotion.connections)
end

Motion.stopMenuTween = function()
    for _, tweenObject in ipairs(MenuMotion.tweens) do
        tweenObject:Cancel()
    end

    clearMenuTweenState()
end

Motion.animateMenuVisibility = function(visible)
    local restPosition = WindowRestPosition or Window.Position
    local hiddenPosition = Layout.getMenuHiddenPosition()
    local wasVisible = Window.Visible

    if visible then
        Motion.stopMenuTween()
        Window.Visible = true
        if not wasVisible then
            Window.Position = hiddenPosition
            WindowScale.Scale = MenuShowStartScale
        end

        trackMenuTween(tween(Window, 0.24, {
            Position = restPosition,
        }, Enum.EasingStyle.Quint))
        local scaleTween = trackMenuTween(tween(WindowScale, 0.24, {
            Scale = 1,
        }, Enum.EasingStyle.Back))

        trackMenuConnection(scaleTween.Completed:Connect(function()
            clearMenuTweenState()
            Window.Position = restPosition
            WindowScale.Scale = 1
        end))
    else
        if not wasVisible then
            Window.Position = restPosition
            WindowScale.Scale = 1
            return
        end

        Motion.stopMenuTween()

        local positionTween = trackMenuTween(tween(Window, 0.18, {
            Position = hiddenPosition,
        }, Enum.EasingStyle.Quart))
        trackMenuTween(tween(WindowScale, 0.18, {
            Scale = MenuHideEndScale,
        }, Enum.EasingStyle.Quint))

        trackMenuConnection(positionTween.Completed:Connect(function()
            clearMenuTweenState()
            Window.Visible = false
            Window.Position = restPosition
            WindowScale.Scale = 1
        end))
    end
end

BindOverlay.MouseButton1Click:Connect(Motion.closeBindPopup)
BindOverlay.InputBegan:Connect(function(input)
    if input.UserInputType == Enum.UserInputType.MouseButton2
        or input.UserInputType == Enum.UserInputType.Touch then
        Motion.closeBindPopup()
    end
end)

BindFieldButton.MouseButton1Click:Connect(function()
    if not MenuState.bindPopupCurrent then
        return
    end

    MenuState.bindPopupListening = true
    updateBindPopup()
end)

for modeId, data in pairs(ModeButtons) do
    data.button.MouseButton1Click:Connect(function()
        if not MenuState.bindPopupCurrent then
            return
        end

        MenuState.bindPopupCurrent.mode = modeId
        updateBindPopup()
        refreshRows()
        updateWatermark()
    end)
end

Motion.refreshKeybindList = function()
    local visible = MenuState.introDone and Runtime.showKeybindList
    KeybindShell.outline.Visible = visible
    local visibleEntries = {}
    local maxNameWidth = measureText("Keybinds", Enum.Font.GothamMedium, 11).X
    local maxBindWidth = 0

    for _, entry in ipairs(Entries) do
        if entry.kind == "toggle" and entry.keybindDisplay then
            entry.keybindDisplay.row.Visible = false

            if entry.bind and entry.state and entry.id ~= "keybinds" and entry.mode ~= "always" then
                local bindText = getBindDisplayText(entry)
                maxNameWidth = math.max(maxNameWidth, measureText(entry.name, Enum.Font.GothamMedium, 12).X)
                maxBindWidth = math.max(maxBindWidth, measureText(bindText, Enum.Font.Code, 11).X)
                table.insert(visibleEntries, {
                    entry = entry,
                    bindText = bindText,
                })
            end
        end
    end

    local bindBadgeWidth = maxBindWidth > 0 and (maxBindWidth + KeybindMetrics.bindPadding) or 0
    local shellWidth = math.clamp(
        math.ceil(maxNameWidth + bindBadgeWidth + KeybindMetrics.nameGap + 10),
        KeybindMetrics.minWidth,
        KeybindMetrics.maxWidth
    )

    KeybindShell.outline.Size = UDim2.fromOffset(shellWidth, KeybindMetrics.headerHeight)
    KeybindListShell.outline.Visible = #visibleEntries > 0
    KeybindListShell.outline.Size = UDim2.new(1, 0, 0, #visibleEntries > 0 and (#visibleEntries * KeybindMetrics.rowHeight + (#visibleEntries - 1) + 5) or 0)

    for index, item in ipairs(visibleEntries) do
        local display = item.entry.keybindDisplay
        local currentBindWidth = math.max(14, math.ceil(measureText(item.bindText, Enum.Font.Code, 11).X + KeybindMetrics.bindPadding))

        display.row.Visible = true
        display.row.LayoutOrder = index
        display.label.Text = item.entry.name
        display.label.Size = UDim2.new(1, -(currentBindWidth + KeybindMetrics.nameGap), 1, 0)
        display.bindText.Size = UDim2.fromOffset(currentBindWidth, KeybindMetrics.rowHeight)
        display.bindText.Position = UDim2.new(1, 0, 0, 0)
        display.bindText.Text = item.bindText
    end
end

refreshRows = function()
    for _, entry in ipairs(Entries) do
        if entry.kind == "toggle" and entry.ui then
            if entry.mode == "always" then
                entry.state = true
            end
            entry.ui.fill.BackgroundColor3 = entry.color
            entry.ui.fill.BackgroundTransparency = entry.state and 0 or 1
            if entry.ui.bindText then
                entry.ui.bindText.Text = formatToggleBindText(entry)
                entry.ui.bindText.TextColor3 = MenuState.bindPopupCurrent == entry and entry.color or (entry.mode == "always" and entry.color or Theme.textDim)
            end
            if entry.ui.colorDisplay then
                entry.ui.colorDisplay.BackgroundColor3 = entry.color
            end
            entry.ui.label.TextColor3 = entry.state and Theme.text or Theme.textDim
        elseif entry.kind == "color" and entry.ui then
            entry.ui.colorDisplay.BackgroundColor3 = entry.color
            entry.ui.label.TextColor3 = Theme.text
        elseif entry.kind == "slider" and entry.ui then
            local denominator = math.max(entry.max - entry.min, 0.0001)
            local alpha = math.clamp((entry.value - entry.min) / denominator, 0, 1)
            entry.ui.fill.Size = UDim2.new(alpha, 0, 1, 0)
            if entry.ui.glow then
                entry.ui.glow.Size = UDim2.new(alpha, 0, 1, 4)
                entry.ui.glow.BackgroundColor3 = getSliderGlowColor(entry)
            end
            if entry.ui.valueLabel and not entry.editingValue then
                entry.ui.valueLabel.Text = formatSliderValue(entry)
            end
            entry.ui.label.TextColor3 = Theme.text
        elseif entry.kind == "textbox" and entry.ui then
            entry.ui.label.TextColor3 = Theme.text
            if entry.ui.input and not entry.editingText and entry.ui.input.Text ~= entry.value then
                entry.ui.input.Text = entry.value
            end
        elseif entry.kind == "dropdown" and entry.ui then
            entry.ui.valueLabel.Text = formatDropdownValue(entry)
            entry.ui.row.Size = UDim2.new(1, -2, 0, 16)
        elseif entry.kind == "keybind" and entry.ui then
            entry.ui.label.TextColor3 = Theme.text
            entry.ui.bindText.Text = MenuState.listeningKeybindEntry == entry and "..." or bindToText(entry.bind)
            entry.ui.bindText.TextColor3 = MenuState.listeningKeybindEntry == entry and Theme.accent or Theme.textDim
        elseif entry.kind == "button" and entry.ui then
            entry.ui.label.TextColor3 = Theme.text
        end
    end

    if MenuState.bindPopupCurrent then
        updateBindPopup()
    end

    if SettingsPanel.refresh then
        SettingsPanel.refresh()
    end

    Panels.refreshDropdownOverlay()
    Motion.refreshKeybindList()
end

updateWatermark = function()
    local visible = MenuState.introDone and Runtime.showWatermark
    local watermarkColor = Theme.accent
    local now = time()

    WatermarkShell.outline.Visible = visible
    WatermarkShell.accent.BackgroundColor3 = watermarkColor

    if visible and (now - StatsState.lastWatermarkTextUpdate >= 1 or WatermarkText.Text == "") then
        WatermarkText.Text = string.format(
            "  %s | %s : %s : %s : %d FPS : %d MS  ",
            Runtime.title,
            LocalPlayer.Name,
            placeName,
            os.date("%H:%M:%S"),
            StatsState.currentFps,
            StatsState.currentPing
        )
        StatsState.watermarkWidth = math.max(StatsState.watermarkWidth, WatermarkText.TextBounds.X + 16)
        WatermarkShell.outline.Size = UDim2.fromOffset(StatsState.watermarkWidth, 24)
        StatsState.lastWatermarkTextUpdate = now
    end
end

end

-- Input lifecycle and intro orchestration
do
do

local function openPickerFor(entry)
    if not entry or not entry.ui or not entry.ui.colorButton then
        Motion.closePicker()
        return
    end

    PickerState.target = entry
    PickerState.h, PickerState.s, PickerState.v = entry.color:ToHSV()
    PickerTitle.Text = entry.name .. " Color"

    local previewButton = entry.ui.colorButton
    local previewPosition = previewButton.AbsolutePosition
    local previewSize = previewButton.AbsoluteSize
    local viewport = getViewportSize()

    local x = math.clamp(previewPosition.X + 1, 10, viewport.X - 186)
    local y = math.clamp(previewPosition.Y + previewSize.Y + 6, 10, viewport.Y - 206)

    PickerShell.outline.Position = UDim2.fromOffset(x, y)
    PickerShell.outline.Visible = true
    PickerOverlay.Visible = true
end

local function updatePickerVisual()
    if not PickerState.target then
        return
    end

    local color = Color3.fromHSV(PickerState.h, PickerState.s, PickerState.v)
    PickerState.target.color = color
    SatVal.BackgroundColor3 = Color3.fromHSV(PickerState.h, 1, 1)
    SatValCursor.Position = UDim2.new(PickerState.s, 0, 1 - PickerState.v, 0)
    HueCursor.Position = UDim2.new(0.5, 0, PickerState.h, 0)
    PickerPreview.BackgroundColor3 = color
    PickerValue.Text = Render.colorToHex(color)

    local pickerCallback = PickerState.target.kind == "color" and PickerState.target.callback or PickerState.target.colorChanged
    if type(pickerCallback) == "function" then
        pickerCallback(color)
    end

    refreshRows()
    updateWatermark()
end

local function setPickerFromInput(input, mode)
    if not PickerState.target then
        return
    end

    local inputPosition = Vector2.new(input.Position.X, input.Position.Y)

    if mode == "sv" then
        local relative = inputPosition - SatVal.AbsolutePosition
        PickerState.s = math.clamp(relative.X / SatVal.AbsoluteSize.X, 0, 1)
        PickerState.v = 1 - math.clamp(relative.Y / SatVal.AbsoluteSize.Y, 0, 1)
    elseif mode == "hue" then
        local relative = inputPosition - HueBar.AbsolutePosition
        PickerState.h = math.clamp(relative.Y / HueBar.AbsoluteSize.Y, 0, 1)
    end

    updatePickerVisual()
end

local function beginPickerDrag(frame, mode)
    frame.InputBegan:Connect(function(input)
        if input.UserInputType ~= Enum.UserInputType.MouseButton1 then
            return
        end

        PickerRuntime.mode = mode
        setPickerFromInput(input, mode)
    end)
end

beginPickerDrag(SatVal, "sv")
beginPickerDrag(SatValShade, "sv")
beginPickerDrag(HueBar, "hue")

trackRuntimeConnection(Services.UserInputService.InputChanged:Connect(function(input)
    if input.UserInputType ~= Enum.UserInputType.MouseMovement then
        return
    end

    if PickerRuntime.mode == "sv" then
        setPickerFromInput(input, "sv")
    elseif PickerRuntime.mode == "hue" then
        setPickerFromInput(input, "hue")
    end
end))

trackRuntimeConnection(Services.UserInputService.InputEnded:Connect(function(input)
    if input.UserInputType == Enum.UserInputType.MouseButton1 then
        PickerRuntime.mode = nil
    end

    local changedHold = false
    for entry in pairs(MenuMotion.holdEntries) do
        if inputMatchesBind(entry.bind, input) then
            entry.state = false
            MenuMotion.holdEntries[entry] = nil
            safeCallback(entry.callback, entry.state)
            changedHold = true
        end
    end

    if changedHold then
        refreshRows()
        updateWatermark()
    end
end))

trackRuntimeConnection(Services.UserInputService.InputBegan:Connect(function(input, gameProcessed)
    local bindableMouseInput = getBindableMouseInput(input)

    if SettingsPanel.bindListening then
        if input.KeyCode == Enum.KeyCode.Escape then
            SettingsPanel.bindListening = false
        elseif input.UserInputType == Enum.UserInputType.Keyboard and input.KeyCode ~= Enum.KeyCode.Unknown then
            MenuState.toggleBind = input.KeyCode
            SettingsPanel.bindListening = false
        elseif bindableMouseInput then
            MenuState.toggleBind = bindableMouseInput
            SettingsPanel.bindListening = false
        else
            return
        end

        WindowShell.titleRightLabel.Text = "menu bind: " .. bindToText(MenuState.toggleBind)
        if SettingsPanel.refresh then
            SettingsPanel.refresh()
        end
        return
    end

    if MenuState.listeningKeybindEntry then
        if input.KeyCode == Enum.KeyCode.Escape then
            MenuState.listeningKeybindEntry.bind = nil
        elseif input.UserInputType == Enum.UserInputType.Keyboard and input.KeyCode ~= Enum.KeyCode.Unknown then
            MenuState.listeningKeybindEntry.bind = input.KeyCode
        elseif bindableMouseInput then
            MenuState.listeningKeybindEntry.bind = bindableMouseInput
        else
            return
        end

        safeCallback(MenuState.listeningKeybindEntry.changed, MenuState.listeningKeybindEntry.bind)
        MenuState.listeningKeybindEntry = nil
        refreshRows()
        return
    end

    if MenuState.bindPopupCurrent and MenuState.bindPopupListening then
        if input.KeyCode == Enum.KeyCode.Escape then
            MenuState.bindPopupCurrent.bind = nil
            Motion.closeBindPopup()
        elseif input.UserInputType == Enum.UserInputType.Keyboard and input.KeyCode ~= Enum.KeyCode.Unknown then
            MenuState.bindPopupCurrent.bind = input.KeyCode
            MenuState.bindPopupListening = false
        elseif bindableMouseInput then
            MenuState.bindPopupCurrent.bind = bindableMouseInput
            MenuState.bindPopupListening = false
        end

        refreshRows()
        Motion.refreshKeybindList()
        return
    end

    if BindPopupShell.outline.Visible and (
        input.UserInputType == Enum.UserInputType.MouseButton1
        or input.UserInputType == Enum.UserInputType.MouseButton2
        or input.UserInputType == Enum.UserInputType.Touch
    ) then
        local inputPosition = Vector2.new(input.Position.X, input.Position.Y)

        if not isInsideGui(BindPopupShell.outline, inputPosition) then
            Motion.closeBindPopup()
        end
    end

    if PickerShell.outline.Visible and (
        input.UserInputType == Enum.UserInputType.MouseButton1
        or input.UserInputType == Enum.UserInputType.MouseButton2
        or input.UserInputType == Enum.UserInputType.Touch
    ) then
        local inputPosition = Vector2.new(input.Position.X, input.Position.Y)

        if not isInsideGui(PickerShell.outline, inputPosition) then
            Motion.closePicker()
        end
    end

    if DropdownPanel.shell and DropdownPanel.shell.outline.Visible and (
        input.UserInputType == Enum.UserInputType.MouseButton1
        or input.UserInputType == Enum.UserInputType.MouseButton2
        or input.UserInputType == Enum.UserInputType.Touch
    ) then
        local inputPosition = Vector2.new(input.Position.X, input.Position.Y)
        local dropdownButton = DropdownPanel.entry and DropdownPanel.entry.ui and DropdownPanel.entry.ui.button

        if not isInsideGui(DropdownPanel.shell.outline, inputPosition)
            and not isInsideGui(dropdownButton, inputPosition) then
            Panels.closeDropdown()
        end
    end

    if input.UserInputType == Enum.UserInputType.MouseButton1
        or input.UserInputType == Enum.UserInputType.MouseButton2
        or input.UserInputType == Enum.UserInputType.Touch then
        local inputPosition = Vector2.new(input.Position.X, input.Position.Y)

        if MenuState.searchOpen
            and not isInsideGui(SearchShell.outline, inputPosition)
            and not isInsideGui(SearchButton, inputPosition) then
            Panels.closeSearch()
        end

        if MenuState.infoOpen
            and not isInsideGui(InfoShell.outline, inputPosition)
            and not isInsideGui(InfoButton, inputPosition) then
            Panels.closeInfo()
        end

        if MenuState.settingsOpen
            and not isInsideGui(SettingsShell.outline, inputPosition)
            and not isInsideGui(WindowShell.settingsButton, inputPosition) then
            Panels.closeSettings()
        end

        if ConfigSystem.shell
            and ConfigSystem.shell.outline.Visible
            and not isInsideGui(ConfigSystem.shell.outline, inputPosition)
            and not isInsideGui(ConfigButton, inputPosition) then
            Panels.closeConfigMenu()
        end
    end

    if gameProcessed and not (bindableMouseInput and not MenuState.visible) then
        return
    end

    if inputMatchesBind(MenuState.toggleBind, input) then
        MenuState.visible = not MenuState.visible

        if MenuState.visible then
            Motion.animateMenuVisibility(true)
        else
            Motion.closePicker()
            Panels.closeDropdown()
            Motion.closeBindPopup()
            Panels.closeMiniPanels()
            table.clear(MenuMotion.holdEntries)
            Motion.animateMenuVisibility(false)
        end

        return
    end

    if input.KeyCode == Enum.KeyCode.Escape and PickerShell.outline.Visible then
        Motion.closePicker()
        return
    end

    if input.KeyCode == Enum.KeyCode.Escape and DropdownPanel.entry then
        Panels.closeDropdown()
        return
    end

    if input.KeyCode == Enum.KeyCode.Escape and BindPopupShell.outline.Visible then
        Motion.closeBindPopup()
        return
    end

    if input.KeyCode == Enum.KeyCode.Escape and (MenuState.searchOpen or MenuState.infoOpen or MenuState.settingsOpen) then
        Panels.closeMiniPanels()
        return
    end

    if input.KeyCode == Enum.KeyCode.Escape and ConfigSystem.shell and ConfigSystem.shell.outline.Visible then
        Panels.closeConfigMenu()
        return
    end

    for _, entry in ipairs(Entries) do
        if entry.kind == "toggle" and entry.mode ~= "always" and inputMatchesBind(entry.bind, input) then
            if entry.mode == "hold" then
                entry.state = true
                MenuMotion.holdEntries[entry] = true
            else
                entry.state = not entry.state
            end
            safeCallback(entry.callback, entry.state)
        elseif entry.kind == "keybind" and inputMatchesBind(entry.bind, input) then
            safeCallback(entry.callback, bindToText(entry.bind), entry.bind)
        end
    end

    refreshRows()
    updateWatermark()
end))

trackRuntimeConnection(Services.RunService.RenderStepped:Connect(function(deltaTime)
    StatsState.fpsFrames = StatsState.fpsFrames + 1
    StatsState.fpsElapsed = StatsState.fpsElapsed + deltaTime

    if StatsState.fpsElapsed >= 2 then
        StatsState.currentFps = math.floor(StatsState.fpsFrames / StatsState.fpsElapsed + 0.5)
        StatsState.currentPing = getPing()
        StatsState.fpsFrames = 0
        StatsState.fpsElapsed = 0
    end

    if PickerRuntime.isOpen then
        if PickerRuntime.openEntry ~= PickerState.target then
            openPickerFor(PickerRuntime.openEntry)
            updatePickerVisual()
        end
    elseif PickerState.target then
        Motion.closePicker()
    end

    if MenuState.bindPopupEntry ~= MenuState.bindPopupCurrent then
        if MenuState.bindPopupEntry then
            Motion.openBindPopup(MenuState.bindPopupEntry)
        else
            Motion.closeBindPopup()
        end
    end

    Panels.refreshDropdownOverlay()
    updateWatermark()
end))

Motion.revealWindowImmediate = function()
    MenuState.introDone = true
    Layout.updateWindowRestPosition(WindowRestPosition or Window.Position)
    Window.Visible = true
    Window.BackgroundTransparency = 0
    Window.Position = WindowRestPosition
    WindowScale.Scale = 1
end

Motion.playIntro = function()
    tween(Blur, 0.9, { Size = 52 }, Enum.EasingStyle.Quart)
    local fadeIn = tween(Intro, 0.45, { BackgroundTransparency = 0.28 }, Enum.EasingStyle.Quad)
    fadeIn.Completed:Wait()

    task.wait(0.5)

    local firstGlyph = IntroGlyphs[1]
    local firstCenter = Vector2.new(
        firstGlyph.holder.AbsolutePosition.X + (firstGlyph.holder.AbsoluteSize.X / 2),
        firstGlyph.holder.AbsolutePosition.Y + (firstGlyph.holder.AbsoluteSize.Y / 2) + math.abs(Intro.AbsolutePosition.Y)
    )

    tween(IntroStart, 0.42, {
        TextTransparency = 0,
    }, Enum.EasingStyle.Quad)
    tween(IntroStartScale, 0.52, {
        Scale = 1,
    }, Enum.EasingStyle.Quart)

    task.wait(0.45)

    tween(IntroStart, 0.35, {
        Position = UDim2.fromOffset(firstCenter.X, firstCenter.Y),
    }, Enum.EasingStyle.Quart)

    task.wait(0.5)

    for index, glyphData in ipairs(IntroGlyphs) do
        if index > 1 then
            tween(glyphData.glyph, 0.65, {
                Position = UDim2.new(0.5, 0, 0.5, 0),
                TextTransparency = 0,
            }, Enum.EasingStyle.Quart)
        end
    end

    task.wait(3.1)

    tween(IntroStart, 1.5, {
        TextTransparency = 1,
    }, Enum.EasingStyle.Quad)

    for _, glyphData in ipairs(IntroGlyphs) do
        tween(glyphData.glyph, 1.5, {
            TextTransparency = 1,
        }, Enum.EasingStyle.Quad)
    end

    tween(Blur, 1.5, { Size = 0 }, Enum.EasingStyle.Quad)

    local fade = tween(Intro, 1.5, { BackgroundTransparency = 1 }, Enum.EasingStyle.Quad)
    fade.Completed:Wait()

    Intro:Destroy()
    Blur:Destroy()
    Intro = nil
    Blur = nil

    Motion.revealWindowImmediate()
    Window.Position = Layout.getMenuHiddenPosition()
    WindowScale.Scale = 0.965
    Motion.animateMenuVisibility(true)
end

end

-- Entry registration and builder API
do

local function renderEntry(entry)
    if entry.kind == "toggle" then
        Render.createToggleRow(entry)
    elseif entry.kind == "esppreview" then
        Render.createESPPreviewRow(entry)
    elseif entry.kind == "button" then
        Render.createButtonRow(entry)
    elseif entry.kind == "slider" then
        Render.createSliderRow(entry)
    elseif entry.kind == "textbox" then
        Render.createTextboxRow(entry)
    elseif entry.kind == "dropdown" then
        Render.createDropdownRow(entry)
    elseif entry.kind == "keybind" then
        Render.createKeybindRow(entry)
    elseif entry.kind == "color" then
        Render.createColorRow(entry)
    end
end

local function clearSearchResults()
    for _, child in ipairs(SearchShell.results:GetChildren()) do
        if child:IsA("TextButton") or child:IsA("Frame") then
            child:Destroy()
        end
    end
end

WindowLifecycle.clearState = function()
    Panels.closeDropdown()
    Motion.closePicker()
    Motion.closeBindPopup()
    Panels.closeMiniPanels()

    MenuState.listeningKeybindEntry = nil
    SettingsPanel.bindListening = false
    table.clear(MenuMotion.holdEntries)

    for _, entry in ipairs(Entries) do
        if entry.keybindDisplay and entry.keybindDisplay.row and entry.keybindDisplay.row.Parent then
            entry.keybindDisplay.row:Destroy()
        end
        if entry.kind == "esppreview" and entry.ui then
            destroyInstance(entry.ui.character)
            destroyInstance(entry.ui.camera)
            destroyInstance(entry.ui.cache)
            destroyInstance(entry.ui.gui)
            if entry.ui.shell and entry.ui.shell.outline and entry.ui.shell.outline.Parent then
                entry.ui.shell.outline:Destroy()
            end
        end
    end

    for _, tab in pairs(Tabs) do
        if tab.button and tab.button.outline and tab.button.outline.Parent then
            tab.button.outline:Destroy()
        end
        if tab.page and tab.page.Parent then
            tab.page:Destroy()
        end
    end

    table.clear(Tabs)
    table.clear(Sections)
    table.clear(TabDefinitions)
    table.clear(Entries)
    table.clear(EntryMap)
    table.clear(CreatedSubsectionHeaders)

    DefaultTabId = nil
    CurrentTab = nil
    StatsState.watermarkWidth = 140
    StatsState.lastWatermarkTextUpdate = 0

    clearSearchResults()
    SearchShell.input.Text = ""
    SearchShell.emptyLabel.Visible = false
    WatermarkText.Text = ""
    KeybindShell.outline.Visible = false
    WatermarkShell.outline.Visible = false
    ConfigSystem.menuBuilt = false
    ConfigSystem.windowObject = nil
    ConfigSystem.selectedName = nil
    ConfigSystem.syncing = false
    ConfigSystem.deleteConfirmName = nil
    ConfigSystem.buildToken = ConfigSystem.buildToken + 1
    ConfigOps.clearRows()

    if ConfigSystem.inputBox then
        ConfigSystem.inputBox.Text = ""
    end

    if ConfigSystem.emptyLabel then
        ConfigSystem.emptyLabel.Visible = false
    end

    if ConfigSystem.shell then
        ConfigSystem.shell.outline.Visible = false
    end

    ConfigOps.resetDeleteState()

    if SettingsPanel.refresh then
        SettingsPanel.refresh()
    end
end

local function registerEntry(entry)
    if entry.kind == "toggle" then
        entry.mode = entry.mode or "toggle"
        entry.state = entry.mode == "always" and true or entry.state == true
        entry.color = entry.color or Theme.accent
    elseif entry.kind == "color" then
        entry.color = entry.color or Theme.accent
    elseif entry.kind == "slider" then
        entry.min = tonumber(entry.min) or 0
        entry.max = tonumber(entry.max) or 100
        if entry.max < entry.min then
            entry.min, entry.max = entry.max, entry.min
        end
        entry.round = entry.round or 1
        entry.value = normalizeSliderValue(entry, entry.value ~= nil and entry.value or entry.min)
        entry.color = entry.color or Theme.accent
    elseif entry.kind == "dropdown" then
        entry.values = copyArray(entry.values or {})
        entry.value = normalizeDropdownValue(entry, entry.value)
        entry.open = false
    elseif entry.kind == "keybind" then
        entry.bind = entry.bind
    elseif entry.kind == "textbox" then
        entry.value = tostring(entry.value or "")
        entry.placeholder = tostring(entry.placeholder or "")
    end
    if entry.kind == "esppreview" then
        entry.name = entry.name or "ESP Preview"
    end

    entry.id = makeEntryId(entry.id or entry.flag or string.format("%s_%s_%s", entry.tab, entry.section, entry.name))
    entry.tags = mergeTags(entry.tags, { entry.kind }, { entry.section }, entry.subsection and { entry.subsection } or nil)

    if entry.kind == "toggle" then
        entry.defaultState = entry.state
        entry.defaultColor = entry.color
        entry.defaultBind = entry.bind
        entry.defaultMode = entry.mode
    elseif entry.kind == "color" then
        entry.defaultValue = entry.color
    elseif entry.kind == "slider" then
        entry.defaultValue = entry.value
    elseif entry.kind == "dropdown" then
        entry.defaultValue = entry.multi and copyMap(entry.value) or entry.value
    elseif entry.kind == "keybind" then
        entry.defaultValue = entry.bind
    elseif entry.kind == "textbox" then
        entry.defaultValue = entry.value
    end

    EntryMap[entry.id] = entry
    Entries[#Entries + 1] = entry

    renderEntry(entry)
    Panels.rebuildSearchResults(SearchShell.input.Text)
    refreshRows()
    updateWatermark()

    return setmetatable({
        entry = entry,
    }, ControlMethods)
end

function ControlMethods:Get()
    local entry = self.entry
    if not entry then
        return nil
    end

    if entry.kind == "toggle" then
        return entry.state
    elseif entry.kind == "color" then
        return entry.color
    elseif entry.kind == "slider" then
        return entry.value
    elseif entry.kind == "textbox" then
        return entry.value
    elseif entry.kind == "dropdown" then
        return entry.multi and copyMap(entry.value) or entry.value
    elseif entry.kind == "keybind" then
        return entry.bind
    end

    return nil
end

function ControlMethods:Set(value)
    local entry = self.entry
    if not entry then
        return self
    end

    setEntryValue(entry, value, true)

    refreshRows()
    updateWatermark()
    return self
end

function ControlMethods:SetVisible(state)
    if self.entry then
        self.entry.visible = state ~= false
    end
    if self.entry and self.entry.ui and self.entry.ui.row then
        self.entry.ui.row.Visible = state ~= false
    end
    return self
end

function ControlMethods:SetColor(color)
    if self.entry and (self.entry.kind == "toggle" or self.entry.kind == "color") and typeof(color) == "Color3" then
        self.entry.color = color
        refreshRows()
        updateWatermark()
    end
    return self
end

function ControlMethods:RefreshOptions(values, preferredValue)
    if self.entry and self.entry.kind == "dropdown" then
        setDropdownValues(self.entry, values, preferredValue)
        refreshRows()
    end
    return self
end

local function buildSectionEntry(section, kind, config)
    config = config or {}

    return {
        id = config.Flag or config.Id,
        flag = config.Flag,
        kind = kind,
        name = config.Name or kind,
        tab = section.tabId,
        tabName = section.tabName,
        column = section.column,
        section = section.sectionName,
        subsection = section.subsectionName,
        tags = mergeTags(section.tags, config.Tags),
        callback = config.Callback,
        skipConfig = config.SkipConfig == true,
    }
end

function SectionMethods:AddSubsection(config)
    local name = type(config) == "table" and config.Name or config

    return setmetatable({
        tabId = self.tabId,
        tabName = self.tabName,
        sectionName = self.sectionName,
        column = self.column,
        subsectionName = tostring(name or "General"),
        tags = mergeTags(self.tags, type(config) == "table" and config.Tags or nil),
    }, SectionMethods)
end

function SectionMethods:AddToggle(config)
    local entry = buildSectionEntry(self, "toggle", config)
    entry.state = config and config.Default == true
    entry.color = config and config.Color or Theme.accent
    entry.bind = config and (config.Bind or config.Keybind) or nil
    entry.mode = config and config.Mode or "toggle"
    entry.picker = config and config.ColorPicker == true or false
    entry.colorChanged = config and config.ColorChanged or nil
    return registerEntry(entry)
end

function SectionMethods:AddButton(config)
    local entry = buildSectionEntry(self, "button", config)
    return registerEntry(entry)
end

function SectionMethods:AddSlider(config)
    local entry = buildSectionEntry(self, "slider", config)
    entry.min = config and config.Min or 0
    entry.max = config and config.Max or 100
    entry.value = config and (config.Default ~= nil and config.Default or config.Min) or 0
    entry.round = config and config.Round or 1
    entry.type = config and config.Type or ""
    entry.color = config and config.Color or Theme.accent
    return registerEntry(entry)
end

function SectionMethods:AddDropdown(config)
    local entry = buildSectionEntry(self, "dropdown", config)
    entry.values = config and config.Values or {}
    entry.multi = config and config.Multi == true or false
    entry.value = config and config.Default or nil
    return registerEntry(entry)
end

function SectionMethods:AddTextbox(config)
    local entry = buildSectionEntry(self, "textbox", config)
    entry.value = config and config.Default or ""
    entry.placeholder = config and (config.Placeholder or config.Hint) or ""
    return registerEntry(entry)
end

SectionMethods.AddInput = SectionMethods.AddTextbox

function SectionMethods:AddColorPicker(config)
    local entry = buildSectionEntry(self, "color", config)
    entry.color = config and config.Default or Theme.accent
    return registerEntry(entry)
end

function SectionMethods:AddKeybind(config)
    local entry = buildSectionEntry(self, "keybind", config)
    entry.bind = config and config.Default or nil
    entry.callback = config and config.Callback or nil
    entry.changed = config and config.Changed or nil
    return registerEntry(entry)
end
function SectionMethods:AddESPPreview(config)
    local entry = buildSectionEntry(self, "esppreview", config)
    return registerEntry(entry)
end

function MenuMethods:AddSection(config)
    config = config or {}

    local section = setmetatable({
        tabId = self.id,
        tabName = self.name,
        sectionName = config.Name or "Section",
        subsectionName = nil,
        column = resolveColumn(config.Position),
        tags = config.Tags,
    }, SectionMethods)

    local uiSection = Layout.getSection(section.tabId, section.column, section.sectionName)
    if config.Height then
        uiSection.maxContentHeight = config.Height
        uiSection.fixedHeight = true
        Layout.updateShellSize(uiSection, false)
    else
        uiSection.fixedHeight = false
        Layout.relayoutSectionColumn(section.tabId, section.column)
    end

    return section
end

function WindowMethods:AddMenu(config)
    config = config or {}

    local name = config.Name or string.format("Menu %d", #TabDefinitions + 1)
    local id = makeTabId(config.Id or name)

    TabDefinitions[#TabDefinitions + 1] = {
        id = id,
        name = name,
        icon = resolveIcon(config.Icon),
        order = #TabDefinitions + 1,
    }

    Layout.createTab(id, name, resolveIcon(config.Icon), #TabDefinitions)

    if not DefaultTabId then
        DefaultTabId = id
    end

    if not CurrentTab then
        Layout.selectTab(id)
    else
        Layout.reflowTabButtons()
    end

    return setmetatable({
        id = id,
        name = name,
    }, MenuMethods)
end

end

-- Window configuration API
do

function WindowMethods:ExportConfig(useDefaults)
    local ok, encoded = pcall(function()
        return Services.HttpService:JSONEncode(ConfigOps.exportData(useDefaults == true))
    end)

    if not ok then
        return nil, "failed to encode config"
    end

    return encoded
end

function WindowMethods:ImportConfig(configText)
    if type(configText) ~= "string" or configText == "" then
        return false, "config text is empty"
    end

    local ok, payload = pcall(function()
        return Services.HttpService:JSONDecode(configText)
    end)

    if not ok then
        return false, "failed to decode config"
    end

    return ConfigOps.applyData(payload)
end

function WindowMethods:GetConfigs()
    return ConfigOps.getList()
end

function WindowMethods:RefreshConfigs()
    return ConfigOps.refreshControls()
end

function WindowMethods:SaveConfig(name)
    if not ConfigSystem.supported then
        return false, "filesystem api is unavailable"
    end

    local configName = normalizeConfigName(name or ConfigOps.getRequestedName(false))
    if configName == "" then
        return false, "config name is empty"
    end

    ensureFolder(ConfigSystem.directory)
    ensureFolder(ConfigSystem.folder)

    local encoded, encodeError = self:ExportConfig(false)
    if not encoded then
        return false, encodeError
    end

    local ok, err = pcall(FileApi.writefile, getConfigPath(configName), encoded)
    if not ok then
        return false, err or "failed to write config"
    end

    ConfigSystem.selectedName = configName
    ConfigOps.refreshControls(configName, true)
    return true
end

function WindowMethods:LoadConfig(name)
    if not ConfigSystem.supported then
        return false, "filesystem api is unavailable"
    end

    local configName = normalizeConfigName(name or ConfigOps.getRequestedName(true))
    if configName == "" then
        return false, "config name is empty"
    end

    local path = getConfigPath(configName)
    if FileApi.isfile then
        local ok, exists = pcall(FileApi.isfile, path)
        if ok and not exists then
            return false, "config does not exist"
        end
    end

    local ok, content = pcall(FileApi.readfile, path)
    if not ok or type(content) ~= "string" then
        return false, "failed to read config"
    end

    local loaded, message = self:ImportConfig(content)
    if not loaded then
        return false, message
    end

    ConfigSystem.selectedName = configName
    ConfigOps.refreshControls(configName, true)
    return true
end

function WindowMethods:DeleteConfig(name)
    if not ConfigSystem.supported then
        return false, "filesystem api is unavailable"
    end

    local configName = normalizeConfigName(name or ConfigOps.getRequestedName(true))
    if configName == "" then
        return false, "config name is empty"
    end

    local path = getConfigPath(configName)
    if FileApi.isfile then
        local ok, exists = pcall(FileApi.isfile, path)
        if ok and not exists then
            return false, "config does not exist"
        end
    end

    local ok, err = pcall(FileApi.delfile, path)
    if not ok then
        return false, err or "failed to delete config"
    end

    if ConfigSystem.selectedName == configName then
        ConfigSystem.selectedName = nil
    end

    ConfigOps.refreshControls(nil, false)
    return true
end

function WindowMethods:LoadDefaults()
    return ConfigOps.applyData(ConfigOps.exportData(true))
end

local function warnConfigFailure(actionName, message)
    warn("[NeverPaste Config] " .. tostring(actionName) .. " failed: " .. tostring(message))
end

do
    function ConfigOps.buildMenu(windowObject)
        if not windowObject or ConfigSystem.menuBuilt or not ConfigSystem.enabled then
            return
        end

        ConfigSystem.menuBuilt = true
        ConfigSystem.windowObject = windowObject

        if not ConfigSystem.buttonsBound then
            local function doConfigAction(actionName, callback)
                local activeWindow = ConfigSystem.windowObject
                if not activeWindow then
                    return
                end

                local ok, message = callback(activeWindow)
                if not ok then
                    warnConfigFailure(actionName, message)
                    return
                end

                ConfigOps.resetDeleteState()
            end

            if ConfigSystem.createButton then
                ConfigSystem.createButton.MouseButton1Click:Connect(function()
                    doConfigAction("Create", function(activeWindow)
                        return activeWindow:SaveConfig(ConfigOps.getRequestedName(false))
                    end)
                end)
            end

            if ConfigSystem.saveButton then
                ConfigSystem.saveButton.MouseButton1Click:Connect(function()
                    doConfigAction("Save", function(activeWindow)
                        return activeWindow:SaveConfig(ConfigOps.getRequestedName(true))
                    end)
                end)
            end

            if ConfigSystem.loadButton then
                ConfigSystem.loadButton.MouseButton1Click:Connect(function()
                    doConfigAction("Load", function(activeWindow)
                        return activeWindow:LoadConfig(ConfigOps.getRequestedName(true))
                    end)
                end)
            end

            if ConfigSystem.deleteButton then
                ConfigSystem.deleteButton.MouseButton1Click:Connect(function()
                    local configName = ConfigOps.getRequestedName(true)
                    if not configName then
                        warnConfigFailure("Delete", "config name is empty")
                        return
                    end

                    if ConfigSystem.deleteConfirmName ~= configName then
                        ConfigSystem.deleteConfirmName = configName
                        if ConfigSystem.deleteLabel then
                            ConfigSystem.deleteLabel.Text = "Are you sure?"
                        end
                        return
                    end

                    doConfigAction("Delete", function(activeWindow)
                        return activeWindow:DeleteConfig(configName)
                    end)
                end)
            end

            if ConfigSystem.refreshButton then
                ConfigSystem.refreshButton.MouseButton1Click:Connect(function()
                    ConfigOps.resetDeleteState()
                    ConfigOps.refreshControls(nil, false)
                end)
            end

            ConfigSystem.buttonsBound = true
        end

        if not ConfigSystem.supported and ConfigSystem.titleLabel then
            ConfigSystem.titleLabel.Text = "Configs (filesystem unavailable)"
        elseif ConfigSystem.titleLabel then
            ConfigSystem.titleLabel.Text = "Configs"
        end

        ConfigOps.resetDeleteState()
        ConfigOps.refreshControls(nil, false)
    end
end

function WindowMethods:SetMenuBind(bind)
    if typeof(bind) == "EnumItem" then
        MenuState.toggleBind = bind
        WindowShell.titleRightLabel.Text = "menu bind: " .. bindToText(MenuState.toggleBind)
        if SettingsPanel.refresh then
            SettingsPanel.refresh()
        end
    end
    return self
end

function WindowMethods:SetInfo(text)
    Runtime.info = tostring(text or "")
    InfoShell.bodyText.Text = Runtime.info
    return self
end

function WindowMethods:SetWatermark(state)
    Runtime.showWatermark = state ~= false
    updateWatermark()
    if SettingsPanel.refresh then
        SettingsPanel.refresh()
    end
    return self
end

function WindowMethods:SetKeybindList(state)
    Runtime.showKeybindList = state ~= false
    refreshRows()
    if SettingsPanel.refresh then
        SettingsPanel.refresh()
    end
    return self
end

function WindowMethods:GetFlag(flag)
    local entry = EntryMap[flag]
    if not entry then
        return nil
    end

    return ControlMethods.Get({
        entry = entry,
    })
end

end
end

-- Menu creation
local function createWindow(config)
    config = config or {}

    WindowLifecycle.clearState()

    Runtime.title = config.Name or "NeverPaste"
    Runtime.info = config.Info or "Right click toggles to assign binds.\nUse search to jump between controls quickly."
    Runtime.showWatermark = config.Watermark ~= false
    Runtime.showKeybindList = config.KeybindList ~= false
    Runtime.initialized = true

    ConfigSystem.enabled = config.ConfigMenu ~= false
    ConfigSystem.supported = supportsConfigFiles()
    ConfigSystem.directory = normalizeConfigName(config.ConfigDirectory or "NeverPaste")
    if ConfigSystem.directory == "" then
        ConfigSystem.directory = "NeverPaste"
    end
    ConfigSystem.folder = ConfigSystem.directory .. "/configs"
    ConfigSystem.selectedName = nil

    if ConfigButton then
        ConfigButton.Visible = ConfigSystem.enabled
    end

    if ConfigSystem.shell then
        ConfigSystem.shell.outline.Visible = false
    end

    WindowShell.titleLabel.Text = Runtime.title
    InfoShell.titleLabel.Text = Runtime.title .. " Info"
    InfoShell.bodyText.Text = Runtime.info

    MenuState.toggleBind = config.MenuBind or config.Keybind or Enum.KeyCode.Insert
    WindowShell.titleRightLabel.Text = "menu bind: " .. bindToText(MenuState.toggleBind)

    MenuState.introDone = false
    MenuState.visible = true
    Motion.stopMenuTween()
    Layout.updateWindowRestPosition(DefaultWindowPosition)
    Window.Visible = false
    Window.BackgroundTransparency = 1
    Window.Position = DefaultWindowPosition
    WindowScale.Scale = 1

    refreshTheme()
    Panels.rebuildSearchResults("")
    refreshRows()
    updateWatermark()

    if config.Intro == false or not (Intro and Intro.Parent and Blur and Blur.Parent) then
        Motion.revealWindowImmediate()
    else
        task.spawn(function()
            local ok, err = pcall(Motion.playIntro)
            if ok then
                return
            end

            warn("[NeverPaste Intro] " .. tostring(err))
            destroyInstance(Intro)
            destroyInstance(Blur)
            Intro = nil
            Blur = nil
            Motion.revealWindowImmediate()
        end)
    end

    local windowObject = setmetatable({}, WindowMethods)
    local buildToken = ConfigSystem.buildToken

    task.defer(function()
        if ConfigSystem.buildToken ~= buildToken then
            return
        end

        ConfigOps.buildMenu(windowObject)
    end)

    return windowObject
end

local function destroyLibrary()
    Motion.stopMenuTween()
    WindowLifecycle.clearState()
    cleanupRuntimeHandle(RuntimeHandle)

    MenuState.visible = false
    MenuState.introDone = false

    if GlobalScope and GlobalScope[RuntimeSingletonKey] == RuntimeHandle then
        GlobalScope[RuntimeSingletonKey] = nil
    end
end

function Atlanta:CreateWindow(config)
    return createWindow(config)
end

function Atlanta:CreateMenu(config)
    return createWindow(config)
end

function Atlanta.new(config)
    return createWindow(config)
end

function Atlanta:SetTheme(config)
    config = config or {}

    if typeof(config.Accent) == "Color3" then
        Theme.accent = config.Accent
    end
    if typeof(config.Text) == "Color3" then
        Theme.text = config.Text
    end
    if typeof(config.TextDim) == "Color3" then
        Theme.textDim = config.TextDim
    end
    if typeof(config.Outline) == "Color3" then
        Theme.outline = config.Outline
    end
    if typeof(config.Inline) == "Color3" then
        Theme.inline = config.Inline
    end
    if typeof(config.High) == "Color3" then
        Theme.high = config.High
    end
    if typeof(config.Low) == "Color3" then
        Theme.low = config.Low
    end
    if typeof(config.Section) == "Color3" then
        Theme.section = config.Section
    end
    if typeof(config.SectionHigh) == "Color3" then
        Theme.sectionHigh = config.SectionHigh
    end
    if typeof(config.SectionLow) == "Color3" then
        Theme.sectionLow = config.SectionLow
    end
    if typeof(config.AccentGlow) == "Color3" then
        Theme.accentGlow = config.AccentGlow
    end

    refreshTheme()
    refreshRows()
    updateWatermark()
    return Atlanta
end

function Atlanta:GetFlag(flag)
    local entry = EntryMap[flag]
    if not entry then
        return nil
    end

    return ControlMethods.Get({
        entry = entry,
    })
end

function Atlanta:Destroy()
    destroyLibrary()
end

--[[
Usage:

local UI = loadstring(game:HttpGet("your raw github link"))()
local Window = UI.new({
    Name = "NeverPaste",
    MenuBind = Enum.KeyCode.Insert,
    -- Intro = false,
})

local Combat = Window:AddMenu({ Name = "Combat", Icon = "target" })
local Aim = Combat:AddSection({ Name = "Aim", Position = "left" })
local Targeting = Aim:AddSubsection("Targeting")

Targeting:AddToggle({ Name = "Aimbot", Default = false, Bind = Enum.KeyCode.Q, Callback = function(state) end })
Targeting:AddSlider({ Name = "FOV", Min = 0, Max = 30, Default = 5, Round = 0.1, Type = " deg" })
Targeting:AddDropdown({ Name = "Hitbox", Values = { "Head", "Chest", "Stomach" }, Default = "Head" })
]]

-- Module exports
-- Services
Atlanta.Services = Services

-- Utilities
Atlanta.Utilities = {
    create = create,
    tween = tween,
    bindToText = bindToText,
    inputMatchesBind = inputMatchesBind,
    isInsideGui = isInsideGui,
    measureText = measureText,
}

-- Components
Atlanta.Components = {
    Window = WindowMethods,
    Menu = MenuMethods,
    Section = SectionMethods,
    Control = ControlMethods,
}

Atlanta.Theme = Theme
Atlanta.Runtime = Runtime
Atlanta.State = {
    menu = MenuState,
    picker = PickerRuntime,
    stats = StatsState,
    motion = MenuMotion,
    config = ConfigSystem,
}

Atlanta.flags = EntryMap
Atlanta.entries = Entries

refreshTheme()
Motion.stopMenuTween()
WindowRestPosition = DefaultWindowPosition
Window.Visible = false
Window.Position = DefaultWindowPosition
WindowScale.Scale = 1
Window.BackgroundTransparency = 1
WatermarkShell.outline.Visible = false
KeybindShell.outline.Visible = false
MenuState.introDone = false
MenuState.visible = false

return Atlanta
