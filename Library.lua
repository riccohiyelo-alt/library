local function safeClone(instance)
    if cloneref then
        local ok, result = pcall(cloneref, instance)
        if ok and result then
            return result
        end
    end

    return instance
end

local Players = safeClone(game:GetService("Players"))
local UserInputService = safeClone(game:GetService("UserInputService"))
local TweenService = safeClone(game:GetService("TweenService"))
local HttpService = safeClone(game:GetService("HttpService"))
local GuiService = safeClone(game:GetService("GuiService"))
local Workspace = safeClone(game:GetService("Workspace"))
local CoreGui = safeClone(game:GetService("CoreGui"))

local DEFAULT_THEME = {
    Accent = Color3.fromRGB(74, 168, 255),
    AccentGlow = Color3.fromRGB(120, 205, 255),
    Section = Color3.fromRGB(28, 78, 132),
    SectionHigh = Color3.fromRGB(47, 108, 170),
    SectionLow = Color3.fromRGB(19, 50, 90),
    Outline = Color3.fromRGB(8, 12, 18),
    Inline = Color3.fromRGB(15, 22, 31),
    High = Color3.fromRGB(23, 34, 46),
    Low = Color3.fromRGB(12, 18, 27),
    Text = Color3.fromRGB(232, 239, 246),
    TextDim = Color3.fromRGB(146, 162, 178),
}

local KEY_NAMES = {
    [Enum.KeyCode.LeftShift] = "LSHIFT",
    [Enum.KeyCode.RightShift] = "RSHIFT",
    [Enum.KeyCode.LeftControl] = "LCTRL",
    [Enum.KeyCode.RightControl] = "RCTRL",
    [Enum.KeyCode.LeftAlt] = "LALT",
    [Enum.KeyCode.RightAlt] = "RALT",
    [Enum.KeyCode.Return] = "ENTER",
    [Enum.KeyCode.Backspace] = "BKSP",
    [Enum.KeyCode.Space] = "SPACE",
    [Enum.KeyCode.Insert] = "INS",
    [Enum.KeyCode.Delete] = "DEL",
    [Enum.KeyCode.PageUp] = "PGUP",
    [Enum.KeyCode.PageDown] = "PGDN",
    [Enum.KeyCode.Up] = "UP",
    [Enum.KeyCode.Down] = "DOWN",
    [Enum.KeyCode.Left] = "LEFT",
    [Enum.KeyCode.Right] = "RIGHT",
    [Enum.UserInputType.MouseButton1] = "M1",
    [Enum.UserInputType.MouseButton2] = "M2",
    [Enum.UserInputType.MouseButton3] = "M3",
}

local ICON_NAMES = {
    target = "TG",
    eye = "EY",
    settings = "ST",
    combat = "CB",
    visuals = "VS",
    misc = "MS",
    main = "MN",
}

local function getGuiParent()
    if gethui then
        local ok, result = pcall(gethui)
        if ok and typeof(result) == "Instance" then
            return safeClone(result)
        end
    end

    return CoreGui
end

local function deepCopy(value)
    if type(value) ~= "table" then
        return value
    end

    local clone = {}
    for key, item in pairs(value) do
        clone[key] = deepCopy(item)
    end

    return clone
end

local function merge(into, patch)
    for key, value in pairs(patch) do
        into[key] = value
    end

    return into
end

local function clamp(number, minimum, maximum)
    return math.max(minimum, math.min(maximum, number))
end

local function roundToStep(value, step)
    if not step or step <= 0 then
        return value
    end

    return math.floor(value / step + 0.5) * step
end

local function create(className, properties)
    local instance = Instance.new(className)

    for key, value in pairs(properties or {}) do
        instance[key] = value
    end

    return instance
end

local function addCorner(parent, radius)
    return create("UICorner", {
        Parent = parent,
        CornerRadius = UDim.new(0, radius or 6),
    })
end

local function addStroke(parent, color, thickness, transparency)
    return create("UIStroke", {
        Parent = parent,
        Color = color or Color3.new(0, 0, 0),
        Thickness = thickness or 1,
        Transparency = transparency or 0,
        ApplyStrokeMode = Enum.ApplyStrokeMode.Border,
    })
end

local function addPadding(parent, left, top, right, bottom)
    return create("UIPadding", {
        Parent = parent,
        PaddingLeft = UDim.new(0, left or 0),
        PaddingTop = UDim.new(0, top or 0),
        PaddingRight = UDim.new(0, right or left or 0),
        PaddingBottom = UDim.new(0, bottom or top or 0),
    })
end

local function addListLayout(parent, padding, direction)
    return create("UIListLayout", {
        Parent = parent,
        Padding = UDim.new(0, padding or 0),
        FillDirection = direction or Enum.FillDirection.Vertical,
        SortOrder = Enum.SortOrder.LayoutOrder,
    })
end

local function tween(instance, properties, duration)
    return TweenService:Create(
        instance,
        TweenInfo.new(duration or 0.15, Enum.EasingStyle.Quad, Enum.EasingDirection.Out),
        properties
    )
end

local function safeCall(callback, ...)
    if type(callback) ~= "function" then
        return
    end

    local ok, err = pcall(callback, ...)
    if not ok then
        warn("[CompkillUI] callback error:", err)
    end
end

local function getViewportSize()
    local camera = Workspace.CurrentCamera
    if camera then
        return camera.ViewportSize
    end

    return Vector2.new(1920, 1080)
end

local function normalizeIcon(icon)
    if type(icon) ~= "string" or icon == "" then
        return nil
    end

    local lowered = string.lower(icon)
    if ICON_NAMES[lowered] then
        return ICON_NAMES[lowered]
    end

    if #icon >= 2 then
        return string.upper(string.sub(icon, 1, 2))
    end

    return string.upper(icon)
end

local function formatInput(input)
    if not input then
        return "NONE"
    end

    if KEY_NAMES[input] then
        return KEY_NAMES[input]
    end

    return string.upper(input.Name or tostring(input))
end

local function inputMatches(bound, input)
    if not bound or typeof(bound) ~= "EnumItem" then
        return false
    end

    if bound.EnumType == Enum.KeyCode then
        return input.KeyCode == bound
    end

    if bound.EnumType == Enum.UserInputType then
        return input.UserInputType == bound
    end

    return false
end

local function serializeInput(input)
    if not input or typeof(input) ~= "EnumItem" then
        return nil
    end

    if input.EnumType == Enum.KeyCode then
        return {
            Kind = "KeyCode",
            Name = input.Name,
        }
    end

    if input.EnumType == Enum.UserInputType then
        return {
            Kind = "UserInputType",
            Name = input.Name,
        }
    end

    return nil
end

local function deserializeInput(data)
    if type(data) ~= "table" then
        return nil
    end

    if data.Kind == "KeyCode" then
        return Enum.KeyCode[data.Name]
    end

    if data.Kind == "UserInputType" then
        return Enum.UserInputType[data.Name]
    end

    return nil
end

local function serializeColor(color)
    if typeof(color) ~= "Color3" then
        return nil
    end

    return {
        R = color.R,
        G = color.G,
        B = color.B,
    }
end

local function deserializeColor(data)
    if type(data) ~= "table" then
        return nil
    end

    if type(data.R) ~= "number" or type(data.G) ~= "number" or type(data.B) ~= "number" then
        return nil
    end

    return Color3.new(data.R, data.G, data.B)
end

local function shallowArrayClone(list)
    if type(list) ~= "table" then
        return list
    end

    local clone = {}
    for index, value in ipairs(list) do
        clone[index] = value
    end

    return clone
end

local function isMouseInput(input)
    return input.UserInputType == Enum.UserInputType.MouseButton1
        or input.UserInputType == Enum.UserInputType.MouseButton2
        or input.UserInputType == Enum.UserInputType.MouseButton3
end

local function pointInGui(guiObject, position)
    local absolutePosition = guiObject.AbsolutePosition
    local absoluteSize = guiObject.AbsoluteSize

    return position.X >= absolutePosition.X
        and position.X <= absolutePosition.X + absoluteSize.X
        and position.Y >= absolutePosition.Y
        and position.Y <= absolutePosition.Y + absoluteSize.Y
end

local function encodeValue(value)
    local valueType = typeof(value)

    if valueType == "Color3" then
        return {
            __type = "Color3",
            value = serializeColor(value),
        }
    end

    if valueType == "EnumItem" then
        return {
            __type = "EnumItem",
            value = serializeInput(value),
        }
    end

    if type(value) == "table" then
        local encoded = {}
        for key, item in pairs(value) do
            encoded[key] = encodeValue(item)
        end
        return encoded
    end

    return value
end

local function decodeValue(value)
    if type(value) ~= "table" then
        return value
    end

    if value.__type == "Color3" then
        return deserializeColor(value.value)
    end

    if value.__type == "EnumItem" then
        return deserializeInput(value.value)
    end

    local decoded = {}
    for key, item in pairs(value) do
        decoded[key] = decodeValue(item)
    end

    return decoded
end

local Library = {
    Theme = deepCopy(DEFAULT_THEME),
    Flags = {},
    Options = {},
    Windows = {},
    ThemeBindings = {},
    Connections = {},
    GuiParent = getGuiParent(),
    Font = Enum.Font.Code,
    TextSize = 13,
}

Library.__index = Library

function Library:_connect(signal, callback)
    local connection = signal:Connect(callback)
    table.insert(self.Connections, connection)
    return connection
end

function Library:_bindTheme(instance, property, themeKey, transform)
    local binding = {
        Instance = instance,
        Property = property,
        ThemeKey = themeKey,
        Transform = transform,
    }

    table.insert(self.ThemeBindings, binding)

    pcall(function()
        local value = self.Theme[themeKey]
        if transform then
            value = transform(value, self.Theme, instance)
        end
        instance[property] = value
    end)

    return binding
end

function Library:_refreshThemeBindings()
    local alive = {}

    for _, binding in ipairs(self.ThemeBindings) do
        local ok = pcall(function()
            local value = self.Theme[binding.ThemeKey]
            if binding.Transform then
                value = binding.Transform(value, self.Theme, binding.Instance)
            end

            binding.Instance[binding.Property] = value
        end)

        if ok then
            table.insert(alive, binding)
        end
    end

    self.ThemeBindings = alive
end

function Library:SetTheme(themePatch)
    if type(themePatch) ~= "table" then
        return self
    end

    merge(self.Theme, themePatch)
    self:_refreshThemeBindings()

    for _, window in ipairs(self.Windows) do
        window:_onThemeChanged()
    end

    return self
end

local Window = {}
Window.__index = Window

local Menu = {}
Menu.__index = Menu

local Section = {}
Section.__index = Section

local Group = {}
Group.__index = Group

local BaseControl = {}
BaseControl.__index = BaseControl

local ToggleControl = setmetatable({}, BaseControl)
ToggleControl.__index = ToggleControl

local SliderControl = setmetatable({}, BaseControl)
SliderControl.__index = SliderControl

local DropdownControl = setmetatable({}, BaseControl)
DropdownControl.__index = DropdownControl

local ButtonControl = setmetatable({}, BaseControl)
ButtonControl.__index = ButtonControl

local LabelControl = setmetatable({}, BaseControl)
LabelControl.__index = LabelControl

local DividerControl = setmetatable({}, BaseControl)
DividerControl.__index = DividerControl

local TextboxControl = setmetatable({}, BaseControl)
TextboxControl.__index = TextboxControl

local KeybindControl = setmetatable({}, BaseControl)
KeybindControl.__index = KeybindControl

local ColorPickerControl = setmetatable({}, BaseControl)
ColorPickerControl.__index = ColorPickerControl

function BaseControl:_setFlagValue(value)
    if self.Flag then
        self.Window.Library.Flags[self.Flag] = value
    end
end

function BaseControl:_registerDefault()
    if self.Serialize then
        self.DefaultSerialized = self:Serialize()
    elseif self.Get then
        self.DefaultSerialized = encodeValue(self:Get())
    end
end

function BaseControl:Reset()
    if self.DefaultSerialized ~= nil and self.ApplySerialized then
        self:ApplySerialized(decodeValue(deepCopy(self.DefaultSerialized)))
    end
end

function BaseControl:Get()
    if type(self.Value) == "table" then
        return shallowArrayClone(self.Value)
    end

    return self.Value
end

function BaseControl:Serialize()
    return encodeValue(self:Get())
end

function BaseControl:ApplySerialized(data)
    if self.Set then
        self:Set(decodeValue(data))
    end
end

function Window:_bindTheme(instance, property, themeKey, transform)
    return self.Library:_bindTheme(instance, property, themeKey, transform)
end

function Window:_registerControl(control)
    table.insert(self.Controls, control)
    if control.Flag then
        self.Library.Options[control.Flag] = control
    end

    if control.RefreshTheme then
        table.insert(self.ThemeListeners, control)
    end

    if control.IsBinding then
        table.insert(self.Bindings, control)
        self:_refreshKeybindList()
    end

    if control._registerDefault then
        control:_registerDefault()
    end
end

function Window:_onThemeChanged()
    self:_updateWatermarkText()

    for _, menu in ipairs(self.Menus) do
        menu:RefreshTheme()
    end

    for _, listener in ipairs(self.ThemeListeners) do
        if listener.RefreshTheme then
            listener:RefreshTheme()
        end
    end

    self:_refreshKeybindList()
end

function Window:_beginCapture(control, button, callback)
    if self.CaptureTarget and self.CaptureTarget.Button then
        self.CaptureTarget.Button.Text = self.CaptureTarget.PreviousText
    end

    self.CaptureTarget = {
        Control = control,
        Button = button,
        Callback = callback,
        PreviousText = button.Text,
    }

    button.Text = "[...]"
end

function Window:_finishCapture(bind)
    if not self.CaptureTarget then
        return
    end

    local capture = self.CaptureTarget
    self.CaptureTarget = nil

    safeCall(capture.Callback, bind)
end

function Window:_closePopup()
    if not self.ActivePopup then
        return
    end

    self.ActivePopup.Visible = false
    self.ActivePopup = nil
    self.ActivePopupAnchor = nil
end

function Window:_positionPopup(frame, anchor)
    local viewport = getViewportSize()
    local anchorPosition = anchor.AbsolutePosition
    local anchorSize = anchor.AbsoluteSize
    local popupSize = frame.AbsoluteSize

    local x = anchorPosition.X
    local y = anchorPosition.Y + anchorSize.Y + 6

    if x + popupSize.X > viewport.X - 12 then
        x = viewport.X - popupSize.X - 12
    end

    if y + popupSize.Y > viewport.Y - 12 then
        y = math.max(12, anchorPosition.Y - popupSize.Y - 6)
    end

    frame.Position = UDim2.fromOffset(math.max(12, x), math.max(12, y))
end

function Window:_openPopup(frame, anchor)
    if self.ActivePopup and self.ActivePopup ~= frame then
        self:_closePopup()
    end

    frame.Visible = true
    frame.Parent = self.PopupLayer
    self.ActivePopup = frame
    self.ActivePopupAnchor = anchor

    task.defer(function()
        if frame.Visible and anchor.Parent then
            self:_positionPopup(frame, anchor)
        end
    end)
end

function Window:_togglePopup(frame, anchor)
    if self.ActivePopup == frame and frame.Visible then
        self:_closePopup()
        return
    end

    self:_openPopup(frame, anchor)
end

function Window:_setMenuVisible(state)
    self.Visible = state
    self.Main.Visible = state
    if not state then
        self:_closePopup()
    end
end

function Window:SetMenuBind(bind)
    self.MenuBind = bind
    self:_refreshKeybindList()
    return self
end

function Window:SetVisible(state)
    self:_setMenuVisible(state)
    return self
end

function Window:Toggle()
    self:_setMenuVisible(not self.Visible)
    return self
end

function Window:_setCollapsed(state)
    self.Collapsed = state
    self.Body.Visible = not state
    self.Main.Size = state and self.CollapsedSize or self.ExpandedSize
end

function Window:SetInfo(text)
    self.Info = text or ""
    self.InfoLabel.Text = self.Info
    self:_updateWatermarkText()
    return self
end

function Window:_updateWatermarkText()
    local parts = { self.Name }

    if self.Info and self.Info ~= "" then
        table.insert(parts, self.Info)
    end

    self.WatermarkText.Text = table.concat(parts, " | ")
end

function Window:SetWatermark(state)
    self.WatermarkEnabled = state ~= false
    self.WatermarkFrame.Visible = self.WatermarkEnabled
    return self
end

function Window:SetKeybindList(state)
    self.KeybindListEnabled = state ~= false
    self:_refreshKeybindList()
    return self
end

function Window:_refreshKeybindList()
    if not self.KeybindListContent then
        return
    end

    for _, child in ipairs(self.KeybindListContent:GetChildren()) do
        if not child:IsA("UIListLayout") and not child:IsA("UIPadding") then
            child:Destroy()
        end
    end

    local count = 0

    for _, binding in ipairs(self.Bindings) do
        local bind = binding.GetBind and binding:GetBind() or binding.Bind
        if bind then
            count = count + 1

            local row = create("Frame", {
                Parent = self.KeybindListContent,
                BackgroundTransparency = 1,
                Size = UDim2.new(1, 0, 0, 18),
            })

            local left = create("TextLabel", {
                Parent = row,
                BackgroundTransparency = 1,
                Size = UDim2.new(0.62, 0, 1, 0),
                Font = self.Library.Font,
                Text = binding.GetLabel and binding:GetLabel() or binding.Name or "Bind",
                TextColor3 = self.Library.Theme.Text,
                TextSize = self.Library.TextSize,
                TextXAlignment = Enum.TextXAlignment.Left,
            })
            self:_bindTheme(left, "TextColor3", "Text")

            local right = create("TextLabel", {
                Parent = row,
                BackgroundTransparency = 1,
                Position = UDim2.new(0.62, 0, 0, 0),
                Size = UDim2.new(0.38, 0, 1, 0),
                Font = self.Library.Font,
                Text = string.format("%s %s", formatInput(bind), string.upper(binding.ModeLabel or "")),
                TextColor3 = self.Library.Theme.TextDim,
                TextSize = self.Library.TextSize,
                TextXAlignment = Enum.TextXAlignment.Right,
            })
            self:_bindTheme(right, "TextColor3", "TextDim")
        end
    end

    if count == 0 then
        local empty = create("TextLabel", {
            Parent = self.KeybindListContent,
            BackgroundTransparency = 1,
            Size = UDim2.new(1, 0, 0, 18),
            Font = self.Library.Font,
            Text = "No keybinds",
            TextColor3 = self.Library.Theme.TextDim,
            TextSize = self.Library.TextSize,
            TextXAlignment = Enum.TextXAlignment.Left,
        })
        self:_bindTheme(empty, "TextColor3", "TextDim")
    end

    self.KeybindListFrame.Visible = self.KeybindListEnabled
end

function Window:_setActiveMenu(menu)
    self.ActiveMenu = menu
    self.MenuTitle.Text = menu.Name

    for _, otherMenu in ipairs(self.Menus) do
        otherMenu.Page.Visible = otherMenu == menu
        otherMenu.Active = otherMenu == menu
        otherMenu:RefreshTheme()
    end
end

function Window:AddMenu(options)
    options = options or {}

    local menu = setmetatable({
        Window = self,
        Name = options.Name or "Tab",
        Icon = normalizeIcon(options.Icon),
        Sections = {},
        Active = false,
    }, Menu)

    local button = create("TextButton", {
        Parent = self.TabList,
        AutoButtonColor = false,
        BackgroundColor3 = self.Library.Theme.High,
        BorderSizePixel = 0,
        Size = UDim2.new(1, 0, 0, 36),
        Text = "",
    })
    menu.Button = button
    addCorner(button, 6)
    local buttonStroke = addStroke(button, self.Library.Theme.Outline, 1)
    self:_bindTheme(buttonStroke, "Color", "Outline")

    local accent = create("Frame", {
        Parent = button,
        AnchorPoint = Vector2.new(0, 0.5),
        Position = UDim2.new(0, 0, 0.5, 0),
        Size = UDim2.new(0, 3, 0, 20),
        BorderSizePixel = 0,
        BackgroundColor3 = self.Library.Theme.Accent,
    })
    menu.Accent = accent
    addCorner(accent, 3)
    self:_bindTheme(accent, "BackgroundColor3", "Accent")

    local icon = create("TextLabel", {
        Parent = button,
        BackgroundTransparency = 1,
        Position = UDim2.new(0, 12, 0, 0),
        Size = UDim2.new(0, 20, 1, 0),
        Font = self.Library.Font,
        Text = menu.Icon or "",
        TextColor3 = self.Library.Theme.Accent,
        TextSize = self.Library.TextSize,
        TextXAlignment = Enum.TextXAlignment.Left,
    })
    menu.IconLabel = icon
    self:_bindTheme(icon, "TextColor3", "Accent")

    local title = create("TextLabel", {
        Parent = button,
        BackgroundTransparency = 1,
        Position = UDim2.new(0, menu.Icon and 34 or 12, 0, 0),
        Size = UDim2.new(1, -(menu.Icon and 46 or 24), 1, 0),
        Font = self.Library.Font,
        Text = menu.Name,
        TextColor3 = self.Library.Theme.TextDim,
        TextSize = self.Library.TextSize,
        TextXAlignment = Enum.TextXAlignment.Left,
    })
    menu.TitleLabel = title

    local page = create("Frame", {
        Parent = self.Pages,
        BackgroundTransparency = 1,
        Size = UDim2.new(1, 0, 1, 0),
        Visible = false,
    })
    menu.Page = page

    local columnsHolder = create("Frame", {
        Parent = page,
        BackgroundTransparency = 1,
        Size = UDim2.new(1, 0, 1, 0),
    })
    menu.ColumnsHolder = columnsHolder

    addListLayout(columnsHolder, 8, Enum.FillDirection.Horizontal).HorizontalAlignment = Enum.HorizontalAlignment.Left

    local columns = {}
    for _, name in ipairs({ "left", "center", "right" }) do
        local column = create("ScrollingFrame", {
            Parent = columnsHolder,
            BackgroundTransparency = 1,
            BorderSizePixel = 0,
            CanvasSize = UDim2.new(),
            AutomaticCanvasSize = Enum.AutomaticSize.Y,
            ScrollBarThickness = 4,
            ScrollBarImageColor3 = self.Library.Theme.Accent,
            Size = UDim2.new(1 / 3, -6, 1, 0),
        })
        self:_bindTheme(column, "ScrollBarImageColor3", "Accent")
        addListLayout(column, 10)
        columns[name] = column
    end
    menu.Columns = columns

    button.MouseButton1Click:Connect(function()
        self:_setActiveMenu(menu)
    end)

    function menu:RefreshTheme()
        local theme = self.Window.Library.Theme
        self.Button.BackgroundColor3 = self.Active and theme.SectionLow or theme.High
        self.TitleLabel.TextColor3 = self.Active and theme.Text or theme.TextDim
        self.Accent.BackgroundTransparency = self.Active and 0 or 1
    end

    table.insert(self.Menus, menu)
    menu:RefreshTheme()

    if not self.ActiveMenu then
        self:_setActiveMenu(menu)
    end

    return menu
end

Window.AddTab = Window.AddMenu

local function createContainerMethods(target)
    function target:AddSubsection(name)
        local group = setmetatable({
            Window = self.Window,
            Content = nil,
            Parent = self,
            Name = name or "Subsection",
        }, Group)

        local frame = create("Frame", {
            Parent = self.Content,
            AutomaticSize = Enum.AutomaticSize.Y,
            BackgroundColor3 = self.Window.Library.Theme.Low,
            BorderSizePixel = 0,
            Size = UDim2.new(1, 0, 0, 0),
        })
        group.Frame = frame
        addCorner(frame, 6)
        local stroke = addStroke(frame, self.Window.Library.Theme.Outline, 1)
        self.Window:_bindTheme(stroke, "Color", "Outline")
        self.Window:_bindTheme(frame, "BackgroundColor3", "Low")

        local title = create("TextLabel", {
            Parent = frame,
            BackgroundTransparency = 1,
            Position = UDim2.new(0, 10, 0, 6),
            Size = UDim2.new(1, -20, 0, 18),
            Font = self.Window.Library.Font,
            Text = group.Name,
            TextColor3 = self.Window.Library.Theme.Text,
            TextSize = self.Window.Library.TextSize,
            TextXAlignment = Enum.TextXAlignment.Left,
        })
        self.Window:_bindTheme(title, "TextColor3", "Text")

        local divider = create("Frame", {
            Parent = frame,
            BackgroundColor3 = self.Window.Library.Theme.Outline,
            BorderSizePixel = 0,
            Position = UDim2.new(0, 10, 0, 28),
            Size = UDim2.new(1, -20, 0, 1),
        })
        self.Window:_bindTheme(divider, "BackgroundColor3", "Outline")

        local content = create("Frame", {
            Parent = frame,
            AutomaticSize = Enum.AutomaticSize.Y,
            BackgroundTransparency = 1,
            Position = UDim2.new(0, 10, 0, 36),
            Size = UDim2.new(1, -20, 0, 0),
        })
        group.Content = content
        addPadding(content, 0, 0, 0, 8)
        addListLayout(content, 8)

        return group
    end

    function target:AddLabel(options)
        if type(options) == "string" then
            options = {
                Name = options,
            }
        end

        options = options or {}

        local control = setmetatable({
            Window = self.Window,
            Name = options.Name or options.Text or "Label",
        }, LabelControl)

        local label = create("TextLabel", {
            Parent = self.Content,
            BackgroundTransparency = 1,
            Size = UDim2.new(1, 0, 0, 18),
            Font = self.Window.Library.Font,
            Text = control.Name,
            TextColor3 = self.Window.Library.Theme.TextDim,
            TextSize = self.Window.Library.TextSize,
            TextWrapped = true,
            TextXAlignment = Enum.TextXAlignment.Left,
        })
        control.Frame = label
        self.Window:_bindTheme(label, "TextColor3", "TextDim")

        function control:Set(text)
            self.Name = tostring(text)
            self.Frame.Text = self.Name
        end

        return control
    end

    function target:AddDivider(options)
        options = options or {}

        local control = setmetatable({
            Window = self.Window,
            Name = options.Name or "",
        }, DividerControl)

        local frame = create("Frame", {
            Parent = self.Content,
            BackgroundTransparency = 1,
            Size = UDim2.new(1, 0, 0, 16),
        })
        control.Frame = frame

        local line = create("Frame", {
            Parent = frame,
            AnchorPoint = Vector2.new(0, 0.5),
            Position = UDim2.new(0, 0, 0.5, 0),
            Size = UDim2.new(1, 0, 0, 1),
            BorderSizePixel = 0,
            BackgroundColor3 = self.Window.Library.Theme.Outline,
        })
        self.Window:_bindTheme(line, "BackgroundColor3", "Outline")

        if control.Name ~= "" then
            local labelHolder = create("Frame", {
                Parent = frame,
                AnchorPoint = Vector2.new(0, 0.5),
                Position = UDim2.new(0, 0, 0.5, 0),
                Size = UDim2.new(0, 0, 0, 16),
                AutomaticSize = Enum.AutomaticSize.X,
                BorderSizePixel = 0,
                BackgroundColor3 = self.Window.Library.Theme.Low,
            })
            self.Window:_bindTheme(labelHolder, "BackgroundColor3", "Low")

            local label = create("TextLabel", {
                Parent = labelHolder,
                BackgroundTransparency = 1,
                Size = UDim2.new(0, 0, 1, 0),
                AutomaticSize = Enum.AutomaticSize.X,
                Font = self.Window.Library.Font,
                Text = " " .. control.Name .. " ",
                TextColor3 = self.Window.Library.Theme.TextDim,
                TextSize = self.Window.Library.TextSize,
                TextXAlignment = Enum.TextXAlignment.Left,
            })
            self.Window:_bindTheme(label, "TextColor3", "TextDim")
        end

        return control
    end

    function target:AddButton(options)
        options = options or {}

        local control = setmetatable({
            Window = self.Window,
            Name = options.Name or "Button",
            Callback = options.Callback,
        }, ButtonControl)

        local button = create("TextButton", {
            Parent = self.Content,
            AutoButtonColor = false,
            BackgroundColor3 = self.Window.Library.Theme.High,
            BorderSizePixel = 0,
            Size = UDim2.new(1, 0, 0, 32),
            Text = control.Name,
            Font = self.Window.Library.Font,
            TextColor3 = self.Window.Library.Theme.Text,
            TextSize = self.Window.Library.TextSize,
        })
        control.Frame = button
        addCorner(button, 6)
        local stroke = addStroke(button, self.Window.Library.Theme.Outline, 1)
        self.Window:_bindTheme(stroke, "Color", "Outline")
        self.Window:_bindTheme(button, "TextColor3", "Text")

        function control:RefreshTheme()
            self.Frame.BackgroundColor3 = self.Window.Library.Theme.High
        end

        button.MouseEnter:Connect(function()
            tween(button, {
                BackgroundColor3 = self.Window.Library.Theme.SectionLow,
            }):Play()
        end)

        button.MouseLeave:Connect(function()
            tween(button, {
                BackgroundColor3 = self.Window.Library.Theme.High,
            }):Play()
        end)

        button.MouseButton1Click:Connect(function()
            safeCall(control.Callback)
        end)

        self.Window:_registerControl(control)
        return control
    end

    function target:AddTextbox(options)
        options = options or {}

        local control = setmetatable({
            Window = self.Window,
            Name = options.Name or "Textbox",
            Flag = options.Flag,
            Callback = options.Callback,
            Placeholder = options.Placeholder or "",
            Value = tostring(options.Default or ""),
        }, TextboxControl)

        local frame = create("Frame", {
            Parent = self.Content,
            BackgroundColor3 = self.Window.Library.Theme.High,
            BorderSizePixel = 0,
            Size = UDim2.new(1, 0, 0, 54),
        })
        control.Frame = frame
        addCorner(frame, 6)
        local stroke = addStroke(frame, self.Window.Library.Theme.Outline, 1)
        self.Window:_bindTheme(stroke, "Color", "Outline")
        self.Window:_bindTheme(frame, "BackgroundColor3", "High")

        local label = create("TextLabel", {
            Parent = frame,
            BackgroundTransparency = 1,
            Position = UDim2.new(0, 10, 0, 8),
            Size = UDim2.new(1, -20, 0, 16),
            Font = self.Window.Library.Font,
            Text = control.Name,
            TextColor3 = self.Window.Library.Theme.Text,
            TextSize = self.Window.Library.TextSize,
            TextXAlignment = Enum.TextXAlignment.Left,
        })
        self.Window:_bindTheme(label, "TextColor3", "Text")

        local textbox = create("TextBox", {
            Parent = frame,
            BackgroundColor3 = self.Window.Library.Theme.Low,
            BorderSizePixel = 0,
            ClearTextOnFocus = false,
            Font = self.Window.Library.Font,
            PlaceholderText = control.Placeholder,
            Position = UDim2.new(0, 10, 0, 26),
            Size = UDim2.new(1, -20, 0, 20),
            Text = control.Value,
            TextColor3 = self.Window.Library.Theme.Text,
            PlaceholderColor3 = self.Window.Library.Theme.TextDim,
            TextSize = self.Window.Library.TextSize,
            TextXAlignment = Enum.TextXAlignment.Left,
        })
        control.Textbox = textbox
        addCorner(textbox, 4)
        local textboxStroke = addStroke(textbox, self.Window.Library.Theme.Outline, 1)
        self.Window:_bindTheme(textboxStroke, "Color", "Outline")
        self.Window:_bindTheme(textbox, "BackgroundColor3", "Low")
        self.Window:_bindTheme(textbox, "TextColor3", "Text")
        self.Window:_bindTheme(textbox, "PlaceholderColor3", "TextDim")

        function control:Set(value, silent)
            self.Value = tostring(value or "")
            self.Textbox.Text = self.Value
            self:_setFlagValue(self.Value)
            if not silent then
                safeCall(self.Callback, self.Value)
            end
        end

        textbox.FocusLost:Connect(function()
            control:Set(textbox.Text)
        end)

        control:_setFlagValue(control.Value)
        self.Window:_registerControl(control)
        return control
    end

    function target:AddSlider(options)
        options = options or {}

        local control = setmetatable({
            Window = self.Window,
            Name = options.Name or "Slider",
            Flag = options.Flag,
            Callback = options.Callback,
            Min = tonumber(options.Min or 0) or 0,
            Max = tonumber(options.Max or 100) or 100,
            Round = tonumber(options.Round or 1) or 1,
            Suffix = options.Type or "",
            Value = tonumber(options.Default) or tonumber(options.Min) or 0,
            Dragging = false,
        }, SliderControl)

        local frame = create("Frame", {
            Parent = self.Content,
            BackgroundColor3 = self.Window.Library.Theme.High,
            BorderSizePixel = 0,
            Size = UDim2.new(1, 0, 0, 52),
        })
        control.Frame = frame
        addCorner(frame, 6)
        local stroke = addStroke(frame, self.Window.Library.Theme.Outline, 1)
        self.Window:_bindTheme(stroke, "Color", "Outline")
        self.Window:_bindTheme(frame, "BackgroundColor3", "High")

        local name = create("TextLabel", {
            Parent = frame,
            BackgroundTransparency = 1,
            Position = UDim2.new(0, 10, 0, 8),
            Size = UDim2.new(0.6, -10, 0, 16),
            Font = self.Window.Library.Font,
            Text = control.Name,
            TextColor3 = self.Window.Library.Theme.Text,
            TextSize = self.Window.Library.TextSize,
            TextXAlignment = Enum.TextXAlignment.Left,
        })
        self.Window:_bindTheme(name, "TextColor3", "Text")

        local valueLabel = create("TextLabel", {
            Parent = frame,
            BackgroundTransparency = 1,
            Position = UDim2.new(0.6, 0, 0, 8),
            Size = UDim2.new(0.4, -10, 0, 16),
            Font = self.Window.Library.Font,
            Text = "",
            TextColor3 = self.Window.Library.Theme.TextDim,
            TextSize = self.Window.Library.TextSize,
            TextXAlignment = Enum.TextXAlignment.Right,
        })
        control.ValueLabel = valueLabel
        self.Window:_bindTheme(valueLabel, "TextColor3", "TextDim")

        local bar = create("TextButton", {
            Parent = frame,
            AutoButtonColor = false,
            BackgroundColor3 = self.Window.Library.Theme.Low,
            BorderSizePixel = 0,
            Position = UDim2.new(0, 10, 0, 30),
            Size = UDim2.new(1, -20, 0, 12),
            Text = "",
        })
        control.Bar = bar
        addCorner(bar, 999)
        local barStroke = addStroke(bar, self.Window.Library.Theme.Outline, 1)
        self.Window:_bindTheme(barStroke, "Color", "Outline")
        self.Window:_bindTheme(bar, "BackgroundColor3", "Low")

        local fill = create("Frame", {
            Parent = bar,
            BackgroundColor3 = self.Window.Library.Theme.Accent,
            BorderSizePixel = 0,
            Size = UDim2.new(0, 0, 1, 0),
        })
        control.Fill = fill
        addCorner(fill, 999)
        self.Window:_bindTheme(fill, "BackgroundColor3", "Accent")

        local knob = create("Frame", {
            Parent = bar,
            AnchorPoint = Vector2.new(0.5, 0.5),
            BackgroundColor3 = self.Window.Library.Theme.Text,
            BorderSizePixel = 0,
            Position = UDim2.new(0, 0, 0.5, 0),
            Size = UDim2.fromOffset(8, 8),
        })
        control.Knob = knob
        addCorner(knob, 999)
        self.Window:_bindTheme(knob, "BackgroundColor3", "Text")

        function control:_displayText()
            if math.floor(self.Value) == self.Value then
                return tostring(math.floor(self.Value)) .. self.Suffix
            end

            return tostring(self.Value) .. self.Suffix
        end

        function control:_updateVisual()
            local alpha = 0
            if self.Max ~= self.Min then
                alpha = (self.Value - self.Min) / (self.Max - self.Min)
            end

            self.Fill.Size = UDim2.new(alpha, 0, 1, 0)
            self.Knob.Position = UDim2.new(alpha, 0, 0.5, 0)
            self.ValueLabel.Text = self:_displayText()
        end

        function control:Set(value, silent)
            value = tonumber(value) or self.Min
            value = clamp(value, self.Min, self.Max)
            value = roundToStep(value, self.Round)
            value = clamp(value, self.Min, self.Max)

            self.Value = value
            self:_setFlagValue(self.Value)
            self:_updateVisual()

            if not silent then
                safeCall(self.Callback, self.Value)
            end
        end

        function control:RefreshTheme()
            self.Frame.BackgroundColor3 = self.Window.Library.Theme.High
            self.Bar.BackgroundColor3 = self.Window.Library.Theme.Low
        end

        function control:_setFromInput(positionX)
            local relative = clamp((positionX - self.Bar.AbsolutePosition.X) / math.max(1, self.Bar.AbsoluteSize.X), 0, 1)
            local value = self.Min + (self.Max - self.Min) * relative
            self:Set(value)
        end

        bar.InputBegan:Connect(function(input)
            if input.UserInputType == Enum.UserInputType.MouseButton1 then
                control.Dragging = true
                control:_setFromInput(input.Position.X)
            end
        end)

        self.Window.Library:_connect(UserInputService.InputChanged, function(input)
            if control.Dragging and input.UserInputType == Enum.UserInputType.MouseMovement then
                control:_setFromInput(input.Position.X)
            end
        end)

        self.Window.Library:_connect(UserInputService.InputEnded, function(input)
            if input.UserInputType == Enum.UserInputType.MouseButton1 then
                control.Dragging = false
            end
        end)

        control:Set(control.Value, true)
        self.Window:_registerControl(control)
        return control
    end

    function target:AddColorPicker(options)
        options = options or {}

        local control = setmetatable({
            Window = self.Window,
            Name = options.Name or "Color",
            Flag = options.Flag,
            Callback = options.Callback,
            Value = options.Default or options.Color or self.Window.Library.Theme.Accent,
        }, ColorPickerControl)

        local frame = create("Frame", {
            Parent = self.Content,
            BackgroundColor3 = self.Window.Library.Theme.High,
            BorderSizePixel = 0,
            Size = UDim2.new(1, 0, 0, 32),
        })
        control.Frame = frame
        addCorner(frame, 6)
        local stroke = addStroke(frame, self.Window.Library.Theme.Outline, 1)
        self.Window:_bindTheme(stroke, "Color", "Outline")
        self.Window:_bindTheme(frame, "BackgroundColor3", "High")

        local label = create("TextLabel", {
            Parent = frame,
            BackgroundTransparency = 1,
            Position = UDim2.new(0, 10, 0, 0),
            Size = UDim2.new(1, -54, 1, 0),
            Font = self.Window.Library.Font,
            Text = control.Name,
            TextColor3 = self.Window.Library.Theme.Text,
            TextSize = self.Window.Library.TextSize,
            TextXAlignment = Enum.TextXAlignment.Left,
        })
        self.Window:_bindTheme(label, "TextColor3", "Text")

        local button = create("TextButton", {
            Parent = frame,
            AutoButtonColor = false,
            AnchorPoint = Vector2.new(1, 0.5),
            Position = UDim2.new(1, -10, 0.5, 0),
            Size = UDim2.new(0, 34, 0, 18),
            BorderSizePixel = 0,
            Text = "",
            BackgroundColor3 = control.Value,
        })
        control.Button = button
        addCorner(button, 4)
        local buttonStroke = addStroke(button, self.Window.Library.Theme.Outline, 1)
        self.Window:_bindTheme(buttonStroke, "Color", "Outline")

        local popup = create("Frame", {
            Parent = self.Window.PopupLayer,
            Visible = false,
            BorderSizePixel = 0,
            BackgroundColor3 = self.Window.Library.Theme.Inline,
            Size = UDim2.fromOffset(178, 154),
        })
        control.Popup = popup
        addCorner(popup, 8)
        local popupStroke = addStroke(popup, self.Window.Library.Theme.Outline, 1)
        self.Window:_bindTheme(popupStroke, "Color", "Outline")
        self.Window:_bindTheme(popup, "BackgroundColor3", "Inline")

        local sv = create("Frame", {
            Parent = popup,
            Position = UDim2.fromOffset(10, 10),
            Size = UDim2.fromOffset(120, 120),
            BorderSizePixel = 0,
            BackgroundColor3 = Color3.new(1, 0, 0),
        })
        control.SV = sv
        addCorner(sv, 6)

        local whiteOverlay = create("Frame", {
            Parent = sv,
            Size = UDim2.fromScale(1, 1),
            BorderSizePixel = 0,
            BackgroundColor3 = Color3.new(1, 1, 1),
        })
        addCorner(whiteOverlay, 6)
        create("UIGradient", {
            Parent = whiteOverlay,
            Transparency = NumberSequence.new({
                NumberSequenceKeypoint.new(0, 0),
                NumberSequenceKeypoint.new(1, 1),
            }),
        })

        local blackOverlay = create("Frame", {
            Parent = whiteOverlay,
            Size = UDim2.fromScale(1, 1),
            BorderSizePixel = 0,
            BackgroundColor3 = Color3.new(0, 0, 0),
        })
        addCorner(blackOverlay, 6)
        create("UIGradient", {
            Parent = blackOverlay,
            Rotation = 90,
            Transparency = NumberSequence.new({
                NumberSequenceKeypoint.new(0, 1),
                NumberSequenceKeypoint.new(1, 0),
            }),
        })

        local svCursor = create("Frame", {
            Parent = sv,
            AnchorPoint = Vector2.new(0.5, 0.5),
            BackgroundTransparency = 1,
            BorderSizePixel = 0,
            Size = UDim2.fromOffset(10, 10),
        })
        control.SVCursor = svCursor
        addStroke(svCursor, Color3.new(1, 1, 1), 1)
        addCorner(svCursor, 999)

        local hue = create("Frame", {
            Parent = popup,
            Position = UDim2.fromOffset(138, 10),
            Size = UDim2.fromOffset(18, 120),
            BorderSizePixel = 0,
            BackgroundColor3 = Color3.new(1, 1, 1),
        })
        control.Hue = hue
        addCorner(hue, 6)
        create("UIGradient", {
            Parent = hue,
            Rotation = 90,
            Color = ColorSequence.new({
                ColorSequenceKeypoint.new(0.0, Color3.fromRGB(255, 0, 0)),
                ColorSequenceKeypoint.new(0.17, Color3.fromRGB(255, 255, 0)),
                ColorSequenceKeypoint.new(0.33, Color3.fromRGB(0, 255, 0)),
                ColorSequenceKeypoint.new(0.5, Color3.fromRGB(0, 255, 255)),
                ColorSequenceKeypoint.new(0.67, Color3.fromRGB(0, 0, 255)),
                ColorSequenceKeypoint.new(0.83, Color3.fromRGB(255, 0, 255)),
                ColorSequenceKeypoint.new(1.0, Color3.fromRGB(255, 0, 0)),
            }),
        })

        local hueCursor = create("Frame", {
            Parent = hue,
            AnchorPoint = Vector2.new(0.5, 0.5),
            BackgroundColor3 = self.Window.Library.Theme.Text,
            BorderSizePixel = 0,
            Size = UDim2.fromOffset(22, 3),
        })
        control.HueCursor = hueCursor
        addCorner(hueCursor, 999)
        self.Window:_bindTheme(hueCursor, "BackgroundColor3", "Text")

        local preview = create("TextLabel", {
            Parent = popup,
            BackgroundTransparency = 1,
            Position = UDim2.fromOffset(10, 132),
            Size = UDim2.new(1, -20, 0, 14),
            Font = self.Window.Library.Font,
            Text = "",
            TextColor3 = self.Window.Library.Theme.TextDim,
            TextSize = self.Window.Library.TextSize,
            TextXAlignment = Enum.TextXAlignment.Left,
        })
        control.PreviewLabel = preview
        self.Window:_bindTheme(preview, "TextColor3", "TextDim")

        control.H, control.S, control.V = Color3.toHSV(control.Value)
        control.DragSV = false
        control.DragHue = false

        function control:_updatePopupVisual()
            self.SV.BackgroundColor3 = Color3.fromHSV(self.H, 1, 1)
            self.SVCursor.Position = UDim2.new(self.S, 0, 1 - self.V, 0)
            self.HueCursor.Position = UDim2.new(0.5, 0, self.H, 0)
            self.Button.BackgroundColor3 = self.Value
            self.PreviewLabel.Text = string.format(
                "RGB %d, %d, %d",
                math.floor(self.Value.R * 255 + 0.5),
                math.floor(self.Value.G * 255 + 0.5),
                math.floor(self.Value.B * 255 + 0.5)
            )
        end

        function control:Set(value, silent)
            if typeof(value) ~= "Color3" then
                return
            end

            self.Value = value
            self.H, self.S, self.V = Color3.toHSV(value)
            self:_setFlagValue(self.Value)
            self:_updatePopupVisual()

            if not silent then
                safeCall(self.Callback, self.Value)
            end
        end

        function control:RefreshTheme()
            self.Frame.BackgroundColor3 = self.Window.Library.Theme.High
        end

        function control:_setSVFromPosition(inputPosition)
            local relativeX = clamp((inputPosition.X - self.SV.AbsolutePosition.X) / self.SV.AbsoluteSize.X, 0, 1)
            local relativeY = clamp((inputPosition.Y - self.SV.AbsolutePosition.Y) / self.SV.AbsoluteSize.Y, 0, 1)
            self.S = relativeX
            self.V = 1 - relativeY
            self:Set(Color3.fromHSV(self.H, self.S, self.V))
        end

        function control:_setHueFromPosition(inputPosition)
            local relativeY = clamp((inputPosition.Y - self.Hue.AbsolutePosition.Y) / self.Hue.AbsoluteSize.Y, 0, 1)
            self.H = relativeY
            self:Set(Color3.fromHSV(self.H, self.S, self.V))
        end

        button.MouseButton1Click:Connect(function()
            self.Window:_togglePopup(control.Popup, control.Button)
        end)

        sv.InputBegan:Connect(function(input)
            if input.UserInputType == Enum.UserInputType.MouseButton1 then
                control.DragSV = true
                control:_setSVFromPosition(input.Position)
            end
        end)

        hue.InputBegan:Connect(function(input)
            if input.UserInputType == Enum.UserInputType.MouseButton1 then
                control.DragHue = true
                control:_setHueFromPosition(input.Position)
            end
        end)

        self.Window.Library:_connect(UserInputService.InputChanged, function(input)
            if input.UserInputType == Enum.UserInputType.MouseMovement then
                if control.DragSV then
                    control:_setSVFromPosition(input.Position)
                elseif control.DragHue then
                    control:_setHueFromPosition(input.Position)
                end
            end
        end)

        self.Window.Library:_connect(UserInputService.InputEnded, function(input)
            if input.UserInputType == Enum.UserInputType.MouseButton1 then
                control.DragSV = false
                control.DragHue = false
            end
        end)

        control:Set(control.Value, true)
        self.Window:_registerControl(control)
        return control
    end

    function target:AddKeybind(options)
        options = options or {}

        local control = setmetatable({
            Window = self.Window,
            Name = options.Name or "Keybind",
            Flag = options.Flag,
            Callback = options.Callback,
            Changed = options.Changed,
            Bind = options.Default or options.Key or nil,
            ModeLabel = string.upper(options.Mode or "PRESS"),
            IsBinding = true,
        }, KeybindControl)

        local frame = create("Frame", {
            Parent = self.Content,
            BackgroundColor3 = self.Window.Library.Theme.High,
            BorderSizePixel = 0,
            Size = UDim2.new(1, 0, 0, 32),
        })
        control.Frame = frame
        addCorner(frame, 6)
        local stroke = addStroke(frame, self.Window.Library.Theme.Outline, 1)
        self.Window:_bindTheme(stroke, "Color", "Outline")
        self.Window:_bindTheme(frame, "BackgroundColor3", "High")

        local label = create("TextLabel", {
            Parent = frame,
            BackgroundTransparency = 1,
            Position = UDim2.new(0, 10, 0, 0),
            Size = UDim2.new(1, -90, 1, 0),
            Font = self.Window.Library.Font,
            Text = control.Name,
            TextColor3 = self.Window.Library.Theme.Text,
            TextSize = self.Window.Library.TextSize,
            TextXAlignment = Enum.TextXAlignment.Left,
        })
        self.Window:_bindTheme(label, "TextColor3", "Text")

        local button = create("TextButton", {
            Parent = frame,
            AutoButtonColor = false,
            AnchorPoint = Vector2.new(1, 0.5),
            Position = UDim2.new(1, -10, 0.5, 0),
            Size = UDim2.new(0, 72, 0, 20),
            BackgroundColor3 = self.Window.Library.Theme.Low,
            BorderSizePixel = 0,
            Font = self.Window.Library.Font,
            Text = "",
            TextColor3 = self.Window.Library.Theme.TextDim,
            TextSize = self.Window.Library.TextSize,
        })
        control.Button = button
        addCorner(button, 4)
        local buttonStroke = addStroke(button, self.Window.Library.Theme.Outline, 1)
        self.Window:_bindTheme(buttonStroke, "Color", "Outline")
        self.Window:_bindTheme(button, "BackgroundColor3", "Low")
        self.Window:_bindTheme(button, "TextColor3", "TextDim")

        function control:GetBind()
            return self.Bind
        end

        function control:GetLabel()
            return self.Name
        end

        function control:_updateVisual()
            self.Button.Text = "[" .. formatInput(self.Bind) .. "]"
        end

        function control:Set(bind, silent)
            self.Bind = bind
            self:_setFlagValue(bind)
            self:_updateVisual()

            if not silent then
                safeCall(self.Changed, bind)
                self.Window:_refreshKeybindList()
            end
        end

        function control:Get()
            return self.Bind
        end

        function control:Serialize()
            return encodeValue(self.Bind)
        end

        function control:ApplySerialized(data)
            self:Set(decodeValue(data))
        end

        function control:OnInputBegan()
            safeCall(self.Callback)
        end

        function control:RefreshTheme()
            self.Frame.BackgroundColor3 = self.Window.Library.Theme.High
            self.Button.BackgroundColor3 = self.Window.Library.Theme.Low
        end

        button.MouseButton1Click:Connect(function()
            self.Window:_beginCapture(control, button, function(bind)
                if bind == Enum.KeyCode.Escape then
                    bind = nil
                end

                control:Set(bind)
            end)
        end)

        control:Set(control.Bind, true)
        self.Window:_registerControl(control)
        return control
    end

    function target:AddDropdown(options)
        options = options or {}

        local values = shallowArrayClone(options.Values or {})
        local control = setmetatable({
            Window = self.Window,
            Name = options.Name or "Dropdown",
            Flag = options.Flag,
            Callback = options.Callback,
            Values = values,
            Multi = options.Multi == true,
            Value = nil,
            ModeLabel = "LIST",
        }, DropdownControl)

        local frame = create("Frame", {
            Parent = self.Content,
            BackgroundColor3 = self.Window.Library.Theme.High,
            BorderSizePixel = 0,
            Size = UDim2.new(1, 0, 0, 38),
        })
        control.Frame = frame
        addCorner(frame, 6)
        local stroke = addStroke(frame, self.Window.Library.Theme.Outline, 1)
        self.Window:_bindTheme(stroke, "Color", "Outline")
        self.Window:_bindTheme(frame, "BackgroundColor3", "High")

        local label = create("TextLabel", {
            Parent = frame,
            BackgroundTransparency = 1,
            Position = UDim2.new(0, 10, 0, 0),
            Size = UDim2.new(0.45, -10, 1, 0),
            Font = self.Window.Library.Font,
            Text = control.Name,
            TextColor3 = self.Window.Library.Theme.Text,
            TextSize = self.Window.Library.TextSize,
            TextXAlignment = Enum.TextXAlignment.Left,
        })
        self.Window:_bindTheme(label, "TextColor3", "Text")

        local button = create("TextButton", {
            Parent = frame,
            AutoButtonColor = false,
            AnchorPoint = Vector2.new(1, 0.5),
            Position = UDim2.new(1, -10, 0.5, 0),
            Size = UDim2.new(0.55, -10, 0, 22),
            BackgroundColor3 = self.Window.Library.Theme.Low,
            BorderSizePixel = 0,
            Font = self.Window.Library.Font,
            Text = "",
            TextColor3 = self.Window.Library.Theme.TextDim,
            TextSize = self.Window.Library.TextSize,
            TextTruncate = Enum.TextTruncate.AtEnd,
            TextXAlignment = Enum.TextXAlignment.Left,
        })
        control.Button = button
        addCorner(button, 4)
        addPadding(button, 8, 0, 22, 0)
        local buttonStroke = addStroke(button, self.Window.Library.Theme.Outline, 1)
        self.Window:_bindTheme(buttonStroke, "Color", "Outline")
        self.Window:_bindTheme(button, "BackgroundColor3", "Low")
        self.Window:_bindTheme(button, "TextColor3", "TextDim")

        local arrow = create("TextLabel", {
            Parent = frame,
            BackgroundTransparency = 1,
            AnchorPoint = Vector2.new(1, 0.5),
            Position = UDim2.new(1, -18, 0.5, 0),
            Size = UDim2.fromOffset(12, 12),
            Font = self.Window.Library.Font,
            Text = "v",
            TextColor3 = self.Window.Library.Theme.TextDim,
            TextSize = self.Window.Library.TextSize,
        })
        self.Window:_bindTheme(arrow, "TextColor3", "TextDim")

        local popup = create("Frame", {
            Parent = self.Window.PopupLayer,
            Visible = false,
            BorderSizePixel = 0,
            BackgroundColor3 = self.Window.Library.Theme.Inline,
            Size = UDim2.fromOffset(160, 0),
            AutomaticSize = Enum.AutomaticSize.Y,
        })
        control.Popup = popup
        addCorner(popup, 8)
        local popupStroke = addStroke(popup, self.Window.Library.Theme.Outline, 1)
        self.Window:_bindTheme(popupStroke, "Color", "Outline")
        self.Window:_bindTheme(popup, "BackgroundColor3", "Inline")

        local popupContent = create("ScrollingFrame", {
            Parent = popup,
            BackgroundTransparency = 1,
            BorderSizePixel = 0,
            AutomaticCanvasSize = Enum.AutomaticSize.Y,
            CanvasSize = UDim2.new(),
            ScrollBarThickness = 3,
            ScrollBarImageColor3 = self.Window.Library.Theme.Accent,
            Size = UDim2.new(1, -8, 0, 0),
            AutomaticSize = Enum.AutomaticSize.Y,
            Position = UDim2.fromOffset(4, 4),
        })
        control.PopupContent = popupContent
        self.Window:_bindTheme(popupContent, "ScrollBarImageColor3", "Accent")
        addListLayout(popupContent, 4)

        function control:_displayText()
            if self.Multi then
                if #self.Value == 0 then
                    return "None"
                end

                if #self.Value == 1 then
                    return tostring(self.Value[1])
                end

                return string.format("%d selected", #self.Value)
            end

            return tostring(self.Value or "None")
        end

        function control:_contains(value)
            for _, item in ipairs(self.Value) do
                if item == value then
                    return true
                end
            end

            return false
        end

        function control:_rebuildOptions()
            for _, child in ipairs(self.PopupContent:GetChildren()) do
                if not child:IsA("UIListLayout") then
                    child:Destroy()
                end
            end

            for _, item in ipairs(self.Values) do
                local optionButton = create("TextButton", {
                    Parent = self.PopupContent,
                    AutoButtonColor = false,
                    BackgroundColor3 = self.Window.Library.Theme.High,
                    BorderSizePixel = 0,
                    Size = UDim2.new(1, 0, 0, 24),
                    Font = self.Window.Library.Font,
                    Text = tostring(item),
                    TextColor3 = self.Window.Library.Theme.Text,
                    TextSize = self.Window.Library.TextSize,
                    TextXAlignment = Enum.TextXAlignment.Left,
                })
                addCorner(optionButton, 4)
                local optionStroke = addStroke(optionButton, self.Window.Library.Theme.Outline, 1)
                self.Window:_bindTheme(optionStroke, "Color", "Outline")

                local function refreshOption()
                    local selected = self.Multi and self:_contains(item) or self.Value == item
                    optionButton.BackgroundColor3 = selected and self.Window.Library.Theme.SectionLow or self.Window.Library.Theme.High
                    optionButton.TextColor3 = selected and self.Window.Library.Theme.Text or self.Window.Library.Theme.TextDim
                end

                refreshOption()

                optionButton.MouseButton1Click:Connect(function()
                    if self.Multi then
                        local nextValue = shallowArrayClone(self.Value)
                        local foundIndex = nil

                        for index, existing in ipairs(nextValue) do
                            if existing == item then
                                foundIndex = index
                                break
                            end
                        end

                        if foundIndex then
                            table.remove(nextValue, foundIndex)
                        else
                            table.insert(nextValue, item)
                        end

                        self:Set(nextValue)
                    else
                        self:Set(item)
                        self.Window:_closePopup()
                    end

                    refreshOption()
                end)
            end
        end

        function control:Set(value, silent)
            if self.Multi then
                local nextValue = {}

                if type(value) == "table" then
                    for _, item in ipairs(value) do
                        for _, allowed in ipairs(self.Values) do
                            if allowed == item then
                                table.insert(nextValue, item)
                                break
                            end
                        end
                    end
                end

                self.Value = nextValue
            else
                local nextValue = nil
                for _, allowed in ipairs(self.Values) do
                    if allowed == value then
                        nextValue = allowed
                        break
                    end
                end

                if nextValue == nil and #self.Values > 0 then
                    nextValue = self.Values[1]
                end

                self.Value = nextValue
            end

            self:_setFlagValue(self:Get())
            self.Button.Text = self:_displayText()

            if not silent then
                safeCall(self.Callback, self:Get())
            end

            self:_rebuildOptions()
        end

        function control:Get()
            if self.Multi then
                return shallowArrayClone(self.Value)
            end

            return self.Value
        end

        function control:Serialize()
            return encodeValue(self:Get())
        end

        function control:ApplySerialized(data)
            self:Set(decodeValue(data))
        end

        function control:RefreshOptions(valuesList, defaultValue)
            self.Values = shallowArrayClone(valuesList or {})
            self:_rebuildOptions()
            self:Set(defaultValue ~= nil and defaultValue or (self.Multi and {} or self.Values[1]), true)
        end

        function control:RefreshTheme()
            self.Frame.BackgroundColor3 = self.Window.Library.Theme.High
            self.Button.BackgroundColor3 = self.Window.Library.Theme.Low
        end

        button.MouseButton1Click:Connect(function()
            popup.Size = UDim2.fromOffset(math.max(160, button.AbsoluteSize.X), 0)
            self.Window:_togglePopup(popup, button)
        end)

        control.Value = control.Multi and {} or nil
        control:_rebuildOptions()
        local defaultValue = options.Default
        if defaultValue == nil then
            defaultValue = control.Multi and {} or values[1]
        end
        control:Set(defaultValue, true)
        self.Window:_registerControl(control)
        return control
    end

    function target:AddToggle(options)
        options = options or {}

        local control = setmetatable({
            Window = self.Window,
            Name = options.Name or "Toggle",
            Flag = options.Flag,
            Callback = options.Callback,
            ColorCallback = options.ColorCallback,
            BindChanged = options.Changed,
            Value = options.Default == true,
            Color = options.Color or self.Window.Library.Theme.Accent,
            Bind = options.Bind,
            Mode = string.lower(options.Mode or "toggle"),
            ModeLabel = string.upper(options.Mode or "toggle"),
            HasColorPicker = options.ColorPicker == true,
            IsBinding = options.Bind ~= nil,
        }, ToggleControl)

        local frame = create("Frame", {
            Parent = self.Content,
            BackgroundColor3 = self.Window.Library.Theme.High,
            BorderSizePixel = 0,
            Size = UDim2.new(1, 0, 0, 32),
        })
        control.Frame = frame
        addCorner(frame, 6)
        local stroke = addStroke(frame, self.Window.Library.Theme.Outline, 1)
        self.Window:_bindTheme(stroke, "Color", "Outline")
        self.Window:_bindTheme(frame, "BackgroundColor3", "High")

        local click = create("TextButton", {
            Parent = frame,
            AutoButtonColor = false,
            BackgroundTransparency = 1,
            Size = UDim2.new(1, 0, 1, 0),
            Text = "",
        })

        local label = create("TextLabel", {
            Parent = frame,
            BackgroundTransparency = 1,
            Position = UDim2.new(0, 10, 0, 0),
            Size = UDim2.new(1, -120, 1, 0),
            Font = self.Window.Library.Font,
            Text = control.Name,
            TextColor3 = self.Window.Library.Theme.Text,
            TextSize = self.Window.Library.TextSize,
            TextXAlignment = Enum.TextXAlignment.Left,
        })
        control.Label = label
        self.Window:_bindTheme(label, "TextColor3", "Text")

        local toggleBack = create("Frame", {
            Parent = frame,
            AnchorPoint = Vector2.new(1, 0.5),
            Position = UDim2.new(1, -10, 0.5, 0),
            Size = UDim2.fromOffset(34, 16),
            BorderSizePixel = 0,
            BackgroundColor3 = self.Window.Library.Theme.Low,
        })
        control.ToggleBack = toggleBack
        addCorner(toggleBack, 999)
        local toggleStroke = addStroke(toggleBack, self.Window.Library.Theme.Outline, 1)
        self.Window:_bindTheme(toggleStroke, "Color", "Outline")

        local toggleFill = create("Frame", {
            Parent = toggleBack,
            AnchorPoint = Vector2.new(0, 0.5),
            Position = UDim2.new(0, 2, 0.5, 0),
            Size = UDim2.fromOffset(12, 12),
            BorderSizePixel = 0,
            BackgroundColor3 = control.Color,
        })
        control.ToggleFill = toggleFill
        addCorner(toggleFill, 999)

        local rightOffset = 48

        if control.HasColorPicker then
            local swatch = create("TextButton", {
                Parent = frame,
                AutoButtonColor = false,
                AnchorPoint = Vector2.new(1, 0.5),
                Position = UDim2.new(1, -54, 0.5, 0),
                Size = UDim2.fromOffset(18, 18),
                BackgroundColor3 = control.Color,
                BorderSizePixel = 0,
                Text = "",
            })
            control.ColorButton = swatch
            addCorner(swatch, 4)
            local swatchStroke = addStroke(swatch, self.Window.Library.Theme.Outline, 1)
            self.Window:_bindTheme(swatchStroke, "Color", "Outline")
            rightOffset = rightOffset + 24

            local colorPicker = target:AddColorPicker({
                Name = control.Name .. " Color",
                Default = control.Color,
                Callback = function(color)
                    control:SetColor(color)
                end,
            })
            colorPicker.Frame.Parent = self.Window.HiddenBin
            colorPicker.Frame.Visible = false
            control.ColorPicker = colorPicker

            swatch.MouseButton1Click:Connect(function()
                self.Window:_togglePopup(colorPicker.Popup, swatch)
            end)
        end

        if control.Bind then
            local bindButton = create("TextButton", {
                Parent = frame,
                AutoButtonColor = false,
                AnchorPoint = Vector2.new(1, 0.5),
                Position = UDim2.new(1, -(rightOffset + 10), 0.5, 0),
                Size = UDim2.fromOffset(54, 18),
                BackgroundColor3 = self.Window.Library.Theme.Low,
                BorderSizePixel = 0,
                Font = self.Window.Library.Font,
                Text = "",
                TextColor3 = self.Window.Library.Theme.TextDim,
                TextSize = self.Window.Library.TextSize,
            })
            control.BindButton = bindButton
            addCorner(bindButton, 4)
            local bindStroke = addStroke(bindButton, self.Window.Library.Theme.Outline, 1)
            self.Window:_bindTheme(bindStroke, "Color", "Outline")
            self.Window:_bindTheme(bindButton, "BackgroundColor3", "Low")
            self.Window:_bindTheme(bindButton, "TextColor3", "TextDim")

            bindButton.MouseButton1Click:Connect(function()
                self.Window:_beginCapture(control, bindButton, function(bind)
                    if bind == Enum.KeyCode.Escape then
                        bind = nil
                    end

                    control:SetBind(bind)
                end)
            end)
        end

        function control:GetBind()
            return self.Bind
        end

        function control:GetLabel()
            return self.Name
        end

        function control:SetBind(bind, silent)
            self.Bind = bind
            self.IsBinding = bind ~= nil

            if self.Flag then
                self.Window.Library.Flags[self.Flag .. "_bind"] = bind
            end

            if self.BindButton then
                self.BindButton.Text = "[" .. formatInput(bind) .. "]"
            end

            if not silent then
                safeCall(self.BindChanged, bind)
                self.Window:_refreshKeybindList()
            end
        end

        function control:SetColor(color, silent)
            if typeof(color) ~= "Color3" then
                return
            end

            self.Color = color
            self.ToggleFill.BackgroundColor3 = self.Color

            if self.ColorButton then
                self.ColorButton.BackgroundColor3 = self.Color
            end

            if self.ColorPicker then
                self.ColorPicker:Set(color, true)
            end

            if self.Flag then
                self.Window.Library.Flags[self.Flag .. "_color"] = color
            end

            if not silent then
                safeCall(self.ColorCallback, color)
            end
        end

        function control:GetColor()
            return self.Color
        end

        function control:_updateVisual()
            local theme = self.Window.Library.Theme
            self.Frame.BackgroundColor3 = self.Value and theme.SectionLow or theme.High
            self.ToggleBack.BackgroundColor3 = self.Value and theme.Section or theme.Low
            self.ToggleFill.BackgroundColor3 = self.Value and self.Color or theme.TextDim
            tween(self.ToggleFill, {
                Position = self.Value and UDim2.new(1, -14, 0.5, 0) or UDim2.new(0, 2, 0.5, 0),
            }, 0.12):Play()
        end

        function control:Set(state, silent)
            self.Value = state == true
            self:_setFlagValue(self.Value)
            self:_updateVisual()

            if not silent then
                safeCall(self.Callback, self.Value)
            end
        end

        function control:Serialize()
            return {
                Value = self.Value,
                Color = self.HasColorPicker and encodeValue(self.Color) or nil,
                Bind = self.Bind and encodeValue(self.Bind) or nil,
            }
        end

        function control:ApplySerialized(data)
            if type(data) ~= "table" then
                self:Set(decodeValue(data))
                return
            end

            if data.Color ~= nil then
                local color = decodeValue(data.Color)
                if color then
                    self:SetColor(color)
                end
            end

            if data.Bind ~= nil then
                self:SetBind(decodeValue(data.Bind))
            end

            if data.Value ~= nil then
                self:Set(data.Value)
            end
        end

        function control:RefreshTheme()
            self:_updateVisual()
            if self.BindButton then
                self.BindButton.BackgroundColor3 = self.Window.Library.Theme.Low
            end
        end

        function control:OnInputBegan()
            if self.Mode == "hold" then
                self:Set(true)
                return
            end

            self:Set(not self.Value)
        end

        function control:OnInputEnded()
            if self.Mode == "hold" then
                self:Set(false)
            end
        end

        click.MouseButton1Click:Connect(function()
            control:Set(not control.Value)
        end)

        control:Set(control.Value, true)
        control:SetColor(control.Color, true)
        control:SetBind(control.Bind, true)
        self.Window:_registerControl(control)
        return control
    end
end

createContainerMethods(Menu)
createContainerMethods(Section)
createContainerMethods(Group)

function Menu:AddSection(options)
    options = options or {}

    local position = string.lower(options.Position or "left")
    if position ~= "left" and position ~= "center" and position ~= "right" then
        position = "left"
    end

    local section = setmetatable({
        Window = self.Window,
        Menu = self,
        Name = options.Name or "Section",
    }, Section)

    local frame = create("Frame", {
        Parent = self.Columns[position],
        AutomaticSize = Enum.AutomaticSize.Y,
        BackgroundColor3 = self.Window.Library.Theme.High,
        BorderSizePixel = 0,
        Size = UDim2.new(1, 0, 0, 0),
    })
    section.Frame = frame
    addCorner(frame, 8)
    local stroke = addStroke(frame, self.Window.Library.Theme.Outline, 1)
    self.Window:_bindTheme(stroke, "Color", "Outline")
    self.Window:_bindTheme(frame, "BackgroundColor3", "High")

    local accent = create("Frame", {
        Parent = frame,
        BackgroundColor3 = self.Window.Library.Theme.Accent,
        BorderSizePixel = 0,
        Size = UDim2.new(1, 0, 0, 2),
    })
    addCorner(accent, 8)
    self.Window:_bindTheme(accent, "BackgroundColor3", "Accent")

    local header = create("TextLabel", {
        Parent = frame,
        BackgroundTransparency = 1,
        Position = UDim2.new(0, 12, 0, 10),
        Size = UDim2.new(1, -24, 0, 18),
        Font = self.Window.Library.Font,
        Text = section.Name,
        TextColor3 = self.Window.Library.Theme.Text,
        TextSize = self.Window.Library.TextSize,
        TextXAlignment = Enum.TextXAlignment.Left,
    })
    self.Window:_bindTheme(header, "TextColor3", "Text")

    local content = create("Frame", {
        Parent = frame,
        AutomaticSize = Enum.AutomaticSize.Y,
        BackgroundTransparency = 1,
        Position = UDim2.new(0, 12, 0, 34),
        Size = UDim2.new(1, -24, 0, 0),
    })
    section.Content = content
    addPadding(content, 0, 0, 0, 12)
    addListLayout(content, 8)

    table.insert(self.Sections, section)
    return section
end

local function makeDraggable(window, handle, target)
    local dragging = false
    local dragStart
    local startPosition

    handle.InputBegan:Connect(function(input)
        if input.UserInputType == Enum.UserInputType.MouseButton1 then
            dragging = true
            dragStart = input.Position
            startPosition = target.Position
        end
    end)

    handle.InputEnded:Connect(function(input)
        if input.UserInputType == Enum.UserInputType.MouseButton1 then
            dragging = false
        end
    end)

    window.Library:_connect(UserInputService.InputChanged, function(input)
        if not dragging or input.UserInputType ~= Enum.UserInputType.MouseMovement then
            return
        end

        local viewport = getViewportSize()
        local delta = input.Position - dragStart

        local nextX = clamp(startPosition.X.Offset + delta.X, 0, math.max(0, viewport.X - target.AbsoluteSize.X))
        local nextY = clamp(startPosition.Y.Offset + delta.Y, 0, math.max(0, viewport.Y - target.AbsoluteSize.Y))

        target.Position = UDim2.fromOffset(nextX, nextY)
    end)
end

function Window:_ensureConfigDirectory()
    if not makefolder then
        return false, "makefolder is not available"
    end

    local ok, err = pcall(makefolder, self.ConfigDirectory)
    if not ok and not string.find(string.lower(tostring(err)), "exists", 1, true) then
        return false, err
    end

    return true
end

function Window:ExportConfig()
    local export = {}

    for _, control in ipairs(self.Controls) do
        if control.Flag and control.Serialize then
            export[control.Flag] = control:Serialize()
        end
    end

    local ok, result = pcall(HttpService.JSONEncode, HttpService, export)
    if not ok then
        return nil, result
    end

    return result
end

function Window:SaveConfig(name)
    if not writefile then
        return false, "writefile is not available"
    end

    local ok, err = self:_ensureConfigDirectory()
    if not ok then
        return false, err
    end

    local data, exportErr = self:ExportConfig()
    if not data then
        return false, exportErr
    end

    local path = self.ConfigDirectory .. "/" .. tostring(name) .. ".cfg"
    local writeOk, writeErr = pcall(writefile, path, data)
    if not writeOk then
        return false, writeErr
    end

    return true
end

function Window:LoadConfig(name)
    if not readfile or not isfile then
        return false, "readfile/isfile is not available"
    end

    local path = self.ConfigDirectory .. "/" .. tostring(name) .. ".cfg"
    if not isfile(path) then
        return false, "config not found"
    end

    local ok, data = pcall(readfile, path)
    if not ok then
        return false, data
    end

    local decodeOk, payload = pcall(HttpService.JSONDecode, HttpService, data)
    if not decodeOk then
        return false, payload
    end

    for flag, serialized in pairs(payload) do
        local option = self.Library.Options[flag]
        if option and option.ApplySerialized then
            option:ApplySerialized(serialized)
        end
    end

    return true
end

function Window:DeleteConfig(name)
    if not delfile or not isfile then
        return false, "delfile/isfile is not available"
    end

    local path = self.ConfigDirectory .. "/" .. tostring(name) .. ".cfg"
    if not isfile(path) then
        return false, "config not found"
    end

    local ok, err = pcall(delfile, path)
    if not ok then
        return false, err
    end

    return true
end

function Window:LoadDefaults()
    for _, control in ipairs(self.Controls) do
        if control.Reset then
            control:Reset()
        end
    end

    return self
end

function Window:_handleCapture(input)
    if not self.CaptureTarget then
        return false
    end

    if input.UserInputType == Enum.UserInputType.MouseMovement
        or input.UserInputType == Enum.UserInputType.MouseWheel
        or input.KeyCode == Enum.KeyCode.Unknown
    then
        return true
    end

    local bind = isMouseInput(input) and input.UserInputType or input.KeyCode
    self:_finishCapture(bind)
    return true
end

function Window:_handleInputBegan(input, gameProcessed)
    if self:_handleCapture(input) then
        return
    end

    if input.UserInputType == Enum.UserInputType.MouseButton1 and self.ActivePopup then
        local mousePosition = input.Position
        local insidePopup = pointInGui(self.ActivePopup, mousePosition)
        local insideAnchor = self.ActivePopupAnchor and pointInGui(self.ActivePopupAnchor, mousePosition)
        if not insidePopup and not insideAnchor then
            self:_closePopup()
        end
    end

    if gameProcessed or UserInputService:GetFocusedTextBox() then
        return
    end

    if inputMatches(self.MenuBind, input) then
        self:Toggle()
        return
    end

    for _, binding in ipairs(self.Bindings) do
        local bind = binding.GetBind and binding:GetBind() or binding.Bind
        if bind and inputMatches(bind, input) and binding.OnInputBegan then
            binding:OnInputBegan(input)
        end
    end
end

function Window:_handleInputEnded(input, gameProcessed)
    if gameProcessed or UserInputService:GetFocusedTextBox() then
        return
    end

    for _, binding in ipairs(self.Bindings) do
        local bind = binding.GetBind and binding:GetBind() or binding.Bind
        if bind and inputMatches(bind, input) and binding.OnInputEnded then
            binding:OnInputEnded(input)
        end
    end
end

function Library:CreateWindow(options)
    options = options or {}

    local inset = GuiService:GetGuiInset()
    local windowSize = options.Size or UDim2.fromOffset(940, 620)
    local viewport = getViewportSize()
    local position = options.Position or UDim2.fromOffset(
        math.floor((viewport.X - windowSize.X.Offset) * 0.5),
        math.floor((viewport.Y - windowSize.Y.Offset) * 0.5) - inset.Y
    )

    local window = setmetatable({
        Library = self,
        Name = options.Name or "Compkill UI",
        Info = options.Info or "",
        ConfigDirectory = options.ConfigDirectory or "CompkillUI",
        MenuBind = options.MenuBind or Enum.KeyCode.RightShift,
        Visible = true,
        Collapsed = false,
        WatermarkEnabled = options.Watermark ~= false,
        KeybindListEnabled = options.KeybindList ~= false,
        ExpandedSize = windowSize,
        CollapsedSize = UDim2.fromOffset(windowSize.X.Offset, 56),
        Menus = {},
        Controls = {},
        Bindings = {},
        ThemeListeners = {},
        ActiveMenu = nil,
    }, Window)

    local screenGui = create("ScreenGui", {
        Parent = self.GuiParent,
        Name = "CompkillUI",
        IgnoreGuiInset = true,
        ResetOnSpawn = false,
        DisplayOrder = 100,
        ZIndexBehavior = Enum.ZIndexBehavior.Sibling,
    })
    window.ScreenGui = screenGui

    local hiddenBin = create("Folder", {
        Parent = screenGui,
        Name = "Hidden",
    })
    window.HiddenBin = hiddenBin

    local popupLayer = create("Frame", {
        Parent = screenGui,
        BackgroundTransparency = 1,
        Size = UDim2.fromScale(1, 1),
        ZIndex = 50,
    })
    window.PopupLayer = popupLayer

    local watermarkFrame = create("Frame", {
        Parent = screenGui,
        AutomaticSize = Enum.AutomaticSize.X,
        BackgroundColor3 = self.Theme.Outline,
        BorderSizePixel = 0,
        Position = UDim2.new(1, -16, 0, 16),
        AnchorPoint = Vector2.new(1, 0),
        Size = UDim2.new(0, 0, 0, 24),
    })
    window.WatermarkFrame = watermarkFrame
    addCorner(watermarkFrame, 6)
    self:_bindTheme(watermarkFrame, "BackgroundColor3", "Outline")

    local watermarkInner = create("Frame", {
        Parent = watermarkFrame,
        BackgroundColor3 = self.Theme.Inline,
        BorderSizePixel = 0,
        Position = UDim2.fromOffset(1, 1),
        Size = UDim2.new(1, -2, 1, -2),
    })
    addCorner(watermarkInner, 5)
    self:_bindTheme(watermarkInner, "BackgroundColor3", "Inline")

    local watermarkAccent = create("Frame", {
        Parent = watermarkInner,
        BackgroundColor3 = self.Theme.Accent,
        BorderSizePixel = 0,
        Size = UDim2.new(1, 0, 0, 2),
    })
    self:_bindTheme(watermarkAccent, "BackgroundColor3", "Accent")

    local watermarkText = create("TextLabel", {
        Parent = watermarkInner,
        BackgroundTransparency = 1,
        AutomaticSize = Enum.AutomaticSize.X,
        Position = UDim2.fromOffset(8, 5),
        Size = UDim2.new(0, 0, 0, 14),
        Font = self.Font,
        Text = "",
        TextColor3 = self.Theme.Text,
        TextSize = self.TextSize,
        TextXAlignment = Enum.TextXAlignment.Left,
    })
    self:_bindTheme(watermarkText, "TextColor3", "Text")
    window.WatermarkText = watermarkText

    local keybindFrame = create("Frame", {
        Parent = screenGui,
        BackgroundColor3 = self.Theme.Outline,
        BorderSizePixel = 0,
        Position = UDim2.new(1, -16, 0, 52),
        AnchorPoint = Vector2.new(1, 0),
        Size = UDim2.fromOffset(220, 0),
        AutomaticSize = Enum.AutomaticSize.Y,
    })
    window.KeybindListFrame = keybindFrame
    addCorner(keybindFrame, 6)
    self:_bindTheme(keybindFrame, "BackgroundColor3", "Outline")

    local keybindInner = create("Frame", {
        Parent = keybindFrame,
        BackgroundColor3 = self.Theme.Inline,
        BorderSizePixel = 0,
        Position = UDim2.fromOffset(1, 1),
        Size = UDim2.new(1, -2, 1, -2),
        AutomaticSize = Enum.AutomaticSize.Y,
    })
    addCorner(keybindInner, 5)
    self:_bindTheme(keybindInner, "BackgroundColor3", "Inline")

    local keybindAccent = create("Frame", {
        Parent = keybindInner,
        BackgroundColor3 = self.Theme.Accent,
        BorderSizePixel = 0,
        Size = UDim2.new(1, 0, 0, 2),
    })
    self:_bindTheme(keybindAccent, "BackgroundColor3", "Accent")

    local keybindTitle = create("TextLabel", {
        Parent = keybindInner,
        BackgroundTransparency = 1,
        Position = UDim2.fromOffset(10, 7),
        Size = UDim2.new(1, -20, 0, 14),
        Font = self.Font,
        Text = "Keybinds",
        TextColor3 = self.Theme.Text,
        TextSize = self.TextSize,
        TextXAlignment = Enum.TextXAlignment.Left,
    })
    self:_bindTheme(keybindTitle, "TextColor3", "Text")

    local keybindContent = create("Frame", {
        Parent = keybindInner,
        BackgroundTransparency = 1,
        Position = UDim2.fromOffset(10, 28),
        Size = UDim2.new(1, -20, 0, 0),
        AutomaticSize = Enum.AutomaticSize.Y,
    })
    window.KeybindListContent = keybindContent
    addPadding(keybindContent, 0, 0, 0, 10)
    addListLayout(keybindContent, 4)

    local main = create("Frame", {
        Parent = screenGui,
        BackgroundColor3 = self.Theme.Outline,
        BorderSizePixel = 0,
        Position = position,
        Size = window.ExpandedSize,
    })
    window.Main = main
    addCorner(main, 8)
    self:_bindTheme(main, "BackgroundColor3", "Outline")

    local mainInner = create("Frame", {
        Parent = main,
        BackgroundColor3 = self.Theme.Inline,
        BorderSizePixel = 0,
        Position = UDim2.fromOffset(1, 1),
        Size = UDim2.new(1, -2, 1, -2),
    })
    addCorner(mainInner, 7)
    self:_bindTheme(mainInner, "BackgroundColor3", "Inline")

    local mainBackground = create("Frame", {
        Parent = mainInner,
        BackgroundColor3 = self.Theme.Low,
        BorderSizePixel = 0,
        Position = UDim2.fromOffset(1, 1),
        Size = UDim2.new(1, -2, 1, -2),
    })
    addCorner(mainBackground, 6)
    self:_bindTheme(mainBackground, "BackgroundColor3", "Low")

    local accentBar = create("Frame", {
        Parent = mainBackground,
        BackgroundColor3 = self.Theme.Accent,
        BorderSizePixel = 0,
        Size = UDim2.new(1, 0, 0, 2),
    })
    self:_bindTheme(accentBar, "BackgroundColor3", "Accent")

    local header = create("Frame", {
        Parent = mainBackground,
        BackgroundColor3 = self.Theme.High,
        BorderSizePixel = 0,
        Position = UDim2.fromOffset(0, 0),
        Size = UDim2.new(1, 0, 0, 56),
    })
    window.Header = header
    self:_bindTheme(header, "BackgroundColor3", "High")

    local title = create("TextLabel", {
        Parent = header,
        BackgroundTransparency = 1,
        Position = UDim2.fromOffset(16, 10),
        Size = UDim2.new(1, -160, 0, 16),
        Font = self.Font,
        Text = window.Name,
        TextColor3 = self.Theme.Text,
        TextSize = self.TextSize + 1,
        TextXAlignment = Enum.TextXAlignment.Left,
    })
    self:_bindTheme(title, "TextColor3", "Text")

    local info = create("TextLabel", {
        Parent = header,
        BackgroundTransparency = 1,
        Position = UDim2.fromOffset(16, 28),
        Size = UDim2.new(1, -160, 0, 14),
        Font = self.Font,
        Text = window.Info,
        TextColor3 = self.Theme.TextDim,
        TextSize = self.TextSize,
        TextXAlignment = Enum.TextXAlignment.Left,
    })
    window.InfoLabel = info
    self:_bindTheme(info, "TextColor3", "TextDim")

    local minimize = create("TextButton", {
        Parent = header,
        AnchorPoint = Vector2.new(1, 0.5),
        Position = UDim2.new(1, -52, 0.5, 0),
        Size = UDim2.fromOffset(20, 20),
        AutoButtonColor = false,
        BackgroundColor3 = self.Theme.Low,
        BorderSizePixel = 0,
        Font = self.Font,
        Text = "-",
        TextColor3 = self.Theme.Text,
        TextSize = self.TextSize,
    })
    addCorner(minimize, 5)
    self:_bindTheme(minimize, "BackgroundColor3", "Low")
    self:_bindTheme(minimize, "TextColor3", "Text")
    addStroke(minimize, self.Theme.Outline, 1)

    local hide = create("TextButton", {
        Parent = header,
        AnchorPoint = Vector2.new(1, 0.5),
        Position = UDim2.new(1, -24, 0.5, 0),
        Size = UDim2.fromOffset(20, 20),
        AutoButtonColor = false,
        BackgroundColor3 = self.Theme.Low,
        BorderSizePixel = 0,
        Font = self.Font,
        Text = "x",
        TextColor3 = self.Theme.Text,
        TextSize = self.TextSize,
    })
    addCorner(hide, 5)
    self:_bindTheme(hide, "BackgroundColor3", "Low")
    self:_bindTheme(hide, "TextColor3", "Text")
    addStroke(hide, self.Theme.Outline, 1)

    local body = create("Frame", {
        Parent = mainBackground,
        BackgroundTransparency = 1,
        Position = UDim2.fromOffset(0, 56),
        Size = UDim2.new(1, 0, 1, -56),
    })
    window.Body = body

    local sidebar = create("Frame", {
        Parent = body,
        BackgroundColor3 = self.Theme.High,
        BorderSizePixel = 0,
        Size = UDim2.new(0, 170, 1, 0),
    })
    self:_bindTheme(sidebar, "BackgroundColor3", "High")

    local sidebarLabel = create("TextLabel", {
        Parent = sidebar,
        BackgroundTransparency = 1,
        Position = UDim2.fromOffset(14, 12),
        Size = UDim2.new(1, -28, 0, 14),
        Font = self.Font,
        Text = "CATEGORIES",
        TextColor3 = self.Theme.TextDim,
        TextSize = self.TextSize,
        TextXAlignment = Enum.TextXAlignment.Left,
    })
    self:_bindTheme(sidebarLabel, "TextColor3", "TextDim")

    local tabList = create("ScrollingFrame", {
        Parent = sidebar,
        BackgroundTransparency = 1,
        BorderSizePixel = 0,
        CanvasSize = UDim2.new(),
        AutomaticCanvasSize = Enum.AutomaticSize.Y,
        ScrollBarImageColor3 = self.Theme.Accent,
        ScrollBarThickness = 4,
        Position = UDim2.fromOffset(10, 34),
        Size = UDim2.new(1, -20, 1, -44),
    })
    window.TabList = tabList
    self:_bindTheme(tabList, "ScrollBarImageColor3", "Accent")
    addListLayout(tabList, 8)

    local content = create("Frame", {
        Parent = body,
        BackgroundTransparency = 1,
        Position = UDim2.new(0, 182, 0, 0),
        Size = UDim2.new(1, -194, 1, -12),
    })

    local menuTitle = create("TextLabel", {
        Parent = content,
        BackgroundTransparency = 1,
        Position = UDim2.fromOffset(0, 8),
        Size = UDim2.new(1, 0, 0, 18),
        Font = self.Font,
        Text = "",
        TextColor3 = self.Theme.Text,
        TextSize = self.TextSize + 1,
        TextXAlignment = Enum.TextXAlignment.Left,
    })
    window.MenuTitle = menuTitle
    self:_bindTheme(menuTitle, "TextColor3", "Text")

    local pages = create("Frame", {
        Parent = content,
        BackgroundTransparency = 1,
        Position = UDim2.fromOffset(0, 34),
        Size = UDim2.new(1, 0, 1, -34),
    })
    window.Pages = pages

    minimize.MouseButton1Click:Connect(function()
        window:_setCollapsed(not window.Collapsed)
    end)

    hide.MouseButton1Click:Connect(function()
        window:SetVisible(false)
    end)

    makeDraggable(window, header, main)
    window:SetInfo(window.Info)
    window:SetWatermark(window.WatermarkEnabled)
    window:SetKeybindList(window.KeybindListEnabled)

    self:_connect(UserInputService.InputBegan, function(input, gameProcessed)
        window:_handleInputBegan(input, gameProcessed)
    end)
    self:_connect(UserInputService.InputEnded, function(input, gameProcessed)
        window:_handleInputEnded(input, gameProcessed)
    end)

    table.insert(self.Windows, window)
    return window
end

return Library
