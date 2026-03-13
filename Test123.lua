local rawCloneref = type(cloneref) == "function" and cloneref or function(instance)
    return instance
end

local function cloneRef(value)
    if typeof(value) == "Instance" then
        return rawCloneref(value)
    end
    return value
end

local function getSafeHui()
    if type(gethui) == "function" then
        local ok, container = pcall(gethui)
        if ok and typeof(container) == "Instance" then
            return cloneRef(container)
        end
    end
    return cloneRef(game:GetService("CoreGui"))
end

local Services = {
    Players = cloneRef(game:GetService("Players")),
    Lighting = cloneRef(game:GetService("Lighting")),
    TweenService = cloneRef(game:GetService("TweenService")),
    UserInputService = cloneRef(game:GetService("UserInputService")),
    HttpService = cloneRef(game:GetService("HttpService")),
    TextService = cloneRef(game:GetService("TextService")),
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

local GlobalScope = getGlobalScope()
local RootParent = getSafeHui()
local ActiveWindowKey = "__ATLANTA_MENU_ACTIVE__"

local ThemeTemplate = {
    Outline = Color3.fromRGB(8, 15, 22),
    Inline = Color3.fromRGB(20, 34, 46),
    High = Color3.fromRGB(35, 67, 84),
    Low = Color3.fromRGB(20, 43, 58),
    Section = Color3.fromRGB(37, 96, 152),
    Accent = Color3.fromRGB(72, 166, 214),
    AccentGlow = Color3.fromRGB(108, 203, 255),
    Text = Color3.fromRGB(225, 236, 242),
    TextDim = Color3.fromRGB(152, 176, 188),
}

local TabIcons = {
    target = "rbxassetid://10734977012",
    eye = "rbxassetid://10723346959",
    settings = "rbxassetid://10734950309",
    code = "rbxassetid://10709810463",
    search = "rbxassetid://10734943674",
    info = "rbxassetid://10723415903",
}

local BindTextAliases = {
    [Enum.KeyCode.LeftShift] = "LS",
    [Enum.KeyCode.RightShift] = "RS",
    [Enum.KeyCode.LeftControl] = "LC",
    [Enum.KeyCode.RightControl] = "RC",
    [Enum.KeyCode.LeftAlt] = "LA",
    [Enum.KeyCode.RightAlt] = "RA",
    [Enum.KeyCode.CapsLock] = "CAPS",
    [Enum.KeyCode.Return] = "ENT",
    [Enum.KeyCode.Backspace] = "BS",
    [Enum.KeyCode.Insert] = "INS",
    [Enum.KeyCode.Space] = "SPC",
    [Enum.UserInputType.MouseButton1] = "MB1",
    [Enum.UserInputType.MouseButton2] = "MB2",
    [Enum.UserInputType.MouseButton3] = "MB3",
}

local function warnLibrary(message)
    warn("[Atlanta] " .. tostring(message))
end

local function copyTable(source)
    local output = {}
    for key, value in pairs(source) do
        if type(value) == "table" then
            output[key] = copyTable(value)
        else
            output[key] = value
        end
    end
    return output
end

local function copyMap(source)
    local output = {}
    for key, value in pairs(source) do
        output[key] = value
    end
    return output
end

local function copyArray(source)
    local output = {}
    for index, value in ipairs(source) do
        output[index] = value
    end
    return output
end

local function isArray(source)
    if type(source) ~= "table" then
        return false
    end
    local index = 1
    for key in pairs(source) do
        if key ~= index then
            return false
        end
        index = index + 1
    end
    return true
end

local function tableCount(source)
    local count = 0
    for _ in pairs(source) do
        count = count + 1
    end
    return count
end

local function clampNumber(value, minimum, maximum)
    if value < minimum then
        return minimum
    end
    if value > maximum then
        return maximum
    end
    return value
end

local function roundToStep(value, step)
    if step <= 0 then
        return value
    end
    return math.floor((value / step) + 0.5) * step
end

local function generateName(prefix)
    local ok, guid = pcall(function()
        return Services.HttpService:GenerateGUID(false)
    end)
    if ok and type(guid) == "string" then
        return prefix .. "_" .. guid:gsub("%-", "")
    end
    return string.format("%s_%d", prefix, math.random(100000, 999999))
end

local function sanitizeConfigName(name)
    return tostring(name or ""):gsub("[<>:\"/\\|%?%*]", ""):gsub("^%s+", ""):gsub("%s+$", "")
end

local function supportsFilesystem()
    return FileApi.makefolder and FileApi.writefile and FileApi.readfile
end

local function ensureFolder(path)
    if not FileApi.makefolder then
        return
    end
    if FileApi.isfolder then
        local ok, exists = pcall(FileApi.isfolder, path)
        if ok and exists then
            return
        end
    end
    pcall(FileApi.makefolder, path)
end

local function normalizeKeybind(bind)
    if typeof(bind) ~= "EnumItem" then
        return nil
    end
    if bind.EnumType == Enum.KeyCode or bind.EnumType == Enum.UserInputType then
        return bind
    end
    return nil
end

local function getInputBind(input)
    if input.UserInputType == Enum.UserInputType.Keyboard then
        if input.KeyCode ~= Enum.KeyCode.Unknown then
            return input.KeyCode
        end
        return nil
    end
    if input.UserInputType == Enum.UserInputType.MouseButton1 or input.UserInputType == Enum.UserInputType.MouseButton2 or input.UserInputType == Enum.UserInputType.MouseButton3 then
        return input.UserInputType
    end
    return nil
end

local function bindToText(bind)
    bind = normalizeKeybind(bind)
    if not bind then
        return "None"
    end
    return BindTextAliases[bind] or bind.Name
end

local function inputMatchesBind(input, bind)
    local inputBind = getInputBind(input)
    bind = normalizeKeybind(bind)
    return inputBind ~= nil and bind ~= nil and inputBind == bind
end

local function safeCallback(callback, ...)
    if type(callback) ~= "function" then
        return
    end
    local arguments = table.pack(...)
    task.spawn(function()
        local ok, message = pcall(function()
            callback(table.unpack(arguments, 1, arguments.n))
        end)
        if not ok then
            warnLibrary(message)
        end
    end)
end

local function newJanitor()
    local janitor = { entries = {} }
    function janitor:Add(target, method)
        if target ~= nil then
            table.insert(self.entries, { target = target, method = method })
        end
        return target
    end
    function janitor:Cleanup()
        for index = #self.entries, 1, -1 do
            local entry = self.entries[index]
            local target = entry.target
            if target ~= nil then
                local targetType = typeof(target)
                if targetType == "RBXScriptConnection" then
                    pcall(function() target:Disconnect() end)
                elseif targetType == "Instance" then
                    pcall(function() target:Destroy() end)
                elseif type(target) == "function" then
                    pcall(target)
                elseif type(target) == "table" then
                    local methodName = entry.method or "Destroy"
                    if type(target[methodName]) == "function" then
                        pcall(target[methodName], target)
                    end
                end
            end
            self.entries[index] = nil
        end
    end
    return janitor
end

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

local function tween(instance, duration, properties)
    local animation = Services.TweenService:Create(instance, TweenInfo.new(duration, Enum.EasingStyle.Quart, Enum.EasingDirection.Out), properties)
    animation:Play()
    return animation
end

local function applyCorner(parent, radius)
    create("UICorner", {
        Parent = parent,
        CornerRadius = UDim.new(0, radius),
    })
end

local function applyPadding(parent, top, right, bottom, left)
    create("UIPadding", {
        Parent = parent,
        PaddingTop = UDim.new(0, top),
        PaddingRight = UDim.new(0, right),
        PaddingBottom = UDim.new(0, bottom),
        PaddingLeft = UDim.new(0, left),
    })
end

local function serializeValue(value)
    if typeof(value) == "Color3" then
        return { __type = "Color3", r = value.R, g = value.G, b = value.B }
    end
    if typeof(value) == "EnumItem" then
        return { __type = "EnumItem", enum = value.EnumType.Name, name = value.Name }
    end
    if type(value) == "table" then
        local output = {}
        for key, nested in pairs(value) do
            output[key] = serializeValue(nested)
        end
        return output
    end
    return value
end

local function deserializeValue(value)
    if type(value) ~= "table" then
        return value
    end
    if value.__type == "Color3" then
        return Color3.new(value.r or 0, value.g or 0, value.b or 0)
    end
    if value.__type == "EnumItem" then
        local enumObject = Enum[value.enum]
        return enumObject and enumObject[value.name] or nil
    end
    local output = {}
    for key, nested in pairs(value) do
        output[key] = deserializeValue(nested)
    end
    return output
end

local function colorToHex(color)
    local r = math.clamp(math.floor(color.R * 255 + 0.5), 0, 255)
    local g = math.clamp(math.floor(color.G * 255 + 0.5), 0, 255)
    local b = math.clamp(math.floor(color.B * 255 + 0.5), 0, 255)
    return string.format("#%02X%02X%02X", r, g, b)
end

local function hexToColor(text)
    local normalized = tostring(text or ""):gsub("#", "")
    if #normalized ~= 6 then
        return nil
    end
    local ok, color = pcall(function()
        return Color3.fromHex("#" .. normalized)
    end)
    return ok and color or nil
end

local function registerThemeTarget(state, instance, property, key)
    table.insert(state.themeTargets, {
        instance = instance,
        property = property,
        key = key,
    })
end

local function applyTheme(state)
    for _, target in ipairs(state.themeTargets) do
        if target.instance and target.instance.Parent then
            target.instance[target.property] = state.theme[target.key]
        end
    end
    for _, entry in ipairs(state.entries) do
        if type(entry.sync) == "function" then
            entry.sync()
        end
        if type(entry.syncTheme) == "function" then
            entry.syncTheme()
        end
    end
    for _, tab in ipairs(state.tabOrder or {}) do
        local selected = state.currentTab == tab.id
        tab.button.BackgroundColor3 = selected and state.theme.Section or state.theme.High
        local stroke = tab.button:FindFirstChildOfClass("UIStroke")
        if stroke then
            stroke.Color = selected and state.theme.AccentGlow or state.theme.Outline
        end
    end
end

local function themedFrame(state, parent, key, props)
    local frame = create("Frame", props or {})
    frame.Parent = parent
    frame.BackgroundColor3 = state.theme[key]
    registerThemeTarget(state, frame, "BackgroundColor3", key)
    return frame
end

local function themedButton(state, parent, key, props)
    local button = create("TextButton", props or {})
    button.Parent = parent
    button.AutoButtonColor = false
    button.BackgroundColor3 = state.theme[key]
    registerThemeTarget(state, button, "BackgroundColor3", key)
    return button
end

local function themedStroke(state, parent, key, thickness, transparency)
    local stroke = create("UIStroke", {
        Parent = parent,
        ApplyStrokeMode = Enum.ApplyStrokeMode.Border,
        Thickness = thickness or 1,
        Transparency = transparency or 0,
        Color = state.theme[key],
    })
    registerThemeTarget(state, stroke, "Color", key)
    return stroke
end

local function newLabel(state, parent, text, size, dimmed, bold)
    local label = create("TextLabel", {
        Parent = parent,
        BackgroundTransparency = 1,
        BorderSizePixel = 0,
        FontFace = Font.new(
            bold and "rbxasset://fonts/families/GothamSSm.json" or "rbxasset://fonts/families/SourceSansPro.json",
            bold and Enum.FontWeight.Bold or Enum.FontWeight.Medium,
            Enum.FontStyle.Normal
        ),
        Text = text,
        TextColor3 = dimmed and state.theme.TextDim or state.theme.Text,
        TextSize = size,
        TextXAlignment = Enum.TextXAlignment.Left,
        TextYAlignment = Enum.TextYAlignment.Center,
    })
    registerThemeTarget(state, label, "TextColor3", dimmed and "TextDim" or "Text")
    return label
end

local function refreshWatermark(state)
    if not state.watermarkFrame or not state.watermarkLabel then
        return
    end
    state.watermarkFrame.Visible = state.showWatermark
    state.watermarkLabel.Text = string.format("%s | %s", state.title, state.visible and "visible" or "hidden")
end

local function refreshKeybindList(state)
    if not state.keybindPanel or not state.keybindListBody then
        return
    end
    for _, child in ipairs(state.keybindListBody:GetChildren()) do
        if not child:IsA("UIListLayout") then
            child:Destroy()
        end
    end
    if not state.showKeybindList then
        state.keybindPanel.Visible = false
        return
    end
    local rows = 0
    for _, entry in ipairs(state.bindEntries) do
        if entry.bind then
            rows = rows + 1
            local row = create("Frame", {
                Parent = state.keybindListBody,
                BackgroundTransparency = 1,
                Size = UDim2.new(1, 0, 0, 20),
            })
            local label = newLabel(state, row, entry.name, 14, false, false)
            label.Size = UDim2.new(1, -60, 1, 0)
            local bindLabel = newLabel(state, row, bindToText(entry.bind), 14, true, false)
            bindLabel.Size = UDim2.new(0, 60, 1, 0)
            bindLabel.Position = UDim2.new(1, -60, 0, 0)
            bindLabel.TextXAlignment = Enum.TextXAlignment.Right
        end
    end
    state.keybindPanel.Visible = rows > 0
end

local function setWindowVisible(state, visible)
    state.visible = visible
    if state.windowFrame then
        state.windowFrame.Visible = visible
    end
    if state.blur then
        state.blur.Enabled = visible
    end
    refreshWatermark(state)
end

local function getConfigPath(state, name)
    return string.format("%s/%s.json", state.configFolder, name)
end

local function getDropdownText(entry)
    if not entry.multi then
        return tostring(entry.value or "None")
    end
    local count = tableCount(entry.value)
    if count == 0 then
        return "None"
    end
    local selected = {}
    for _, option in ipairs(entry.values) do
        if entry.value[option] then
            table.insert(selected, option)
        end
    end
    if #selected <= 2 then
        return table.concat(selected, ", ")
    end
    return tostring(#selected) .. " selected"
end

local function normalizeToggleMode(mode)
    local normalized = string.lower(tostring(mode or "toggle"))
    if normalized == "toggle" or normalized == "hold" or normalized == "always" then
        return normalized
    end
    return "toggle"
end

local function normalizeSliderValue(entry, value)
    local numeric = tonumber(value) or entry.min
    numeric = clampNumber(numeric, entry.min, entry.max)
    numeric = roundToStep(numeric, entry.round)
    return clampNumber(numeric, entry.min, entry.max)
end

local function normalizeDropdownValue(entry, value)
    if entry.multi then
        local result = {}
        if type(value) == "table" then
            if isArray(value) then
                for _, option in ipairs(value) do
                    if table.find(entry.values, option) then
                        result[option] = true
                    end
                end
            else
                for option, enabled in pairs(value) do
                    if enabled and table.find(entry.values, option) then
                        result[option] = true
                    end
                end
            end
        elseif type(value) == "string" and table.find(entry.values, value) then
            result[value] = true
        end
        return result
    end
    if type(value) == "string" and table.find(entry.values, value) then
        return value
    end
    return entry.values[1]
end

local function getEntryStoredValue(entry, useDefaults)
    if entry.kind == "toggle" then
        local value = {
            state = useDefaults and entry.defaultState or entry.state,
            bind = useDefaults and entry.defaultBind or entry.bind,
            mode = useDefaults and entry.defaultMode or entry.mode,
        }
        if entry.hasColorPicker then
            value.color = useDefaults and entry.defaultColor or entry.color
        end
        return value
    end
    if entry.kind == "slider" or entry.kind == "textbox" or entry.kind == "label" or entry.kind == "paragraph" then
        return useDefaults and entry.defaultValue or entry.value
    end
    if entry.kind == "dropdown" then
        local stored = useDefaults and entry.defaultValue or entry.value
        return entry.multi and copyMap(stored) or stored
    end
    if entry.kind == "color" then
        return useDefaults and entry.defaultValue or entry.color
    end
    if entry.kind == "keybind" then
        return useDefaults and entry.defaultValue or entry.bind
    end
    return nil
end

local function exportConfigData(state, useDefaults)
    local payload = {
        meta = { title = state.title, version = 2 },
        values = {},
    }
    for _, entry in ipairs(state.entries) do
        if entry.flag and not entry.skipConfig then
            payload.values[entry.flag] = serializeValue(getEntryStoredValue(entry, useDefaults))
        end
    end
    return payload
end

local function refreshEntry(entry)
    if type(entry.sync) == "function" then
        entry.sync()
    end
    if type(entry.syncTheme) == "function" then
        entry.syncTheme()
    end
end

local function fireEntryCallback(entry)
    if entry.kind == "toggle" then
        safeCallback(entry.callback, entry.state)
    elseif entry.kind == "slider" then
        safeCallback(entry.callback, entry.value)
    elseif entry.kind == "dropdown" then
        safeCallback(entry.callback, entry.multi and copyMap(entry.value) or entry.value)
    elseif entry.kind == "textbox" then
        safeCallback(entry.callback, entry.value)
    elseif entry.kind == "color" then
        safeCallback(entry.callback, entry.color)
    elseif entry.kind == "button" then
        safeCallback(entry.callback)
    elseif entry.kind == "label" or entry.kind == "paragraph" then
        safeCallback(entry.callback, entry.value)
    end
end

local function setEntryValue(entry, value, fireCallbacks)
    if entry.kind == "toggle" then
        local stateValue = value
        local bindValue = nil
        local modeValue = nil
        local colorValue = nil
        if type(value) == "table" then
            stateValue = value.state
            bindValue = value.bind
            modeValue = value.mode
            colorValue = value.color
        end
        if stateValue ~= nil then
            entry.state = stateValue == true
        end
        if bindValue ~= nil then
            entry.bind = normalizeKeybind(bindValue)
        end
        if modeValue ~= nil then
            entry.mode = normalizeToggleMode(modeValue)
            if entry.mode == "always" then
                entry.state = true
            end
        end
        if colorValue ~= nil and typeof(colorValue) == "Color3" then
            entry.color = colorValue
            safeCallback(entry.colorChanged, entry.color)
        end
    elseif entry.kind == "slider" then
        entry.value = normalizeSliderValue(entry, value)
    elseif entry.kind == "dropdown" then
        entry.value = normalizeDropdownValue(entry, value)
    elseif entry.kind == "textbox" or entry.kind == "label" or entry.kind == "paragraph" then
        entry.value = tostring(value or "")
    elseif entry.kind == "color" then
        if typeof(value) == "Color3" then
            entry.color = value
        end
    elseif entry.kind == "keybind" then
        entry.bind = normalizeKeybind(value)
        if fireCallbacks then
            safeCallback(entry.changed, entry.bind)
        end
    end
    refreshEntry(entry)
    if fireCallbacks and entry.kind ~= "keybind" then
        fireEntryCallback(entry)
    end
end

local function newControlButton(state, parent, width)
    local button = themedButton(state, parent, "High", {
        Parent = parent,
        BorderSizePixel = 0,
        Size = UDim2.new(0, width, 0, 24),
        FontFace = Font.new("rbxasset://fonts/families/GothamSSm.json", Enum.FontWeight.Medium, Enum.FontStyle.Normal),
        Text = "",
        TextColor3 = state.theme.Text,
        TextSize = 13,
    })
    applyCorner(button, 7)
    themedStroke(state, button, "Outline", 1, 0)
    registerThemeTarget(state, button, "TextColor3", "Text")
    return button
end

local function createRowShell(state, parent)
    local row = themedFrame(state, parent, "Inline", {
        Parent = parent,
        BorderSizePixel = 0,
        AutomaticSize = Enum.AutomaticSize.Y,
        Size = UDim2.new(1, 0, 0, 0),
    })
    applyCorner(row, 10)
    applyPadding(row, 10, 12, 10, 12)
    themedStroke(state, row, "Outline", 1, 0)
    create("UIListLayout", {
        Parent = row,
        FillDirection = Enum.FillDirection.Vertical,
        Padding = UDim.new(0, 8),
        SortOrder = Enum.SortOrder.LayoutOrder,
    })
    return row
end

local function createBarInput(state, parent, onChanged)
    local holder = create("Frame", {
        Parent = parent,
        BackgroundTransparency = 1,
        Size = UDim2.new(1, 0, 0, 16),
    })
    local bar = themedFrame(state, holder, "Low", {
        Parent = holder,
        BorderSizePixel = 0,
        Position = UDim2.new(0, 0, 0.5, -3),
        Size = UDim2.new(1, 0, 0, 6),
    })
    local fill = themedFrame(state, bar, "Accent", {
        Parent = bar,
        BorderSizePixel = 0,
        Size = UDim2.new(0, 0, 1, 0),
    })
    local knob = themedFrame(state, bar, "Accent", {
        Parent = bar,
        AnchorPoint = Vector2.new(0.5, 0.5),
        BorderSizePixel = 0,
        Position = UDim2.new(0, 0, 0.5, 0),
        Size = UDim2.new(0, 12, 0, 12),
    })
    applyCorner(bar, 6)
    applyCorner(fill, 6)
    applyCorner(knob, 12)
    themedStroke(state, knob, "Outline", 1, 0)

    local dragging = false
    local function setRatio(ratio)
        ratio = clampNumber(ratio, 0, 1)
        fill.Size = UDim2.new(ratio, 0, 1, 0)
        knob.Position = UDim2.new(ratio, 0, 0.5, 0)
    end
    local function updateFromX(x)
        local baseX = bar.AbsolutePosition.X
        local width = math.max(bar.AbsoluteSize.X, 1)
        local ratio = clampNumber((x - baseX) / width, 0, 1)
        setRatio(ratio)
        onChanged(ratio)
    end

    state.janitor:Add(bar.InputBegan:Connect(function(input)
        if input.UserInputType == Enum.UserInputType.MouseButton1 then
            dragging = true
            updateFromX(input.Position.X)
        end
    end))
    state.janitor:Add(Services.UserInputService.InputChanged:Connect(function(input)
        if dragging and input.UserInputType == Enum.UserInputType.MouseMovement then
            updateFromX(input.Position.X)
        end
    end))
    state.janitor:Add(Services.UserInputService.InputEnded:Connect(function(input)
        if input.UserInputType == Enum.UserInputType.MouseButton1 then
            dragging = false
        end
    end))

    return {
        holder = holder,
        setRatio = setRatio,
    }
end

local function createColorEditor(state, parent, initialColor, onChanged)
    local editor = themedFrame(state, parent, "Low", {
        Parent = parent,
        BorderSizePixel = 0,
        AutomaticSize = Enum.AutomaticSize.Y,
        Size = UDim2.new(1, 0, 0, 0),
        Visible = false,
    })
    applyCorner(editor, 8)
    applyPadding(editor, 10, 10, 10, 10)
    themedStroke(state, editor, "Outline", 1, 0)
    create("UIListLayout", {
        Parent = editor,
        FillDirection = Enum.FillDirection.Vertical,
        Padding = UDim.new(0, 8),
        SortOrder = Enum.SortOrder.LayoutOrder,
    })

    local preview = themedFrame(state, editor, "Inline", {
        Parent = editor,
        BorderSizePixel = 0,
        Size = UDim2.new(1, 0, 0, 24),
    })
    applyCorner(preview, 6)
    themedStroke(state, preview, "Outline", 1, 0)

    local hexBox = create("TextBox", {
        Parent = editor,
        BackgroundColor3 = state.theme.Inline,
        BorderSizePixel = 0,
        ClearTextOnFocus = false,
        Size = UDim2.new(1, 0, 0, 26),
        FontFace = Font.new("rbxasset://fonts/families/SourceSansPro.json", Enum.FontWeight.Semibold, Enum.FontStyle.Normal),
        PlaceholderText = "#RRGGBB",
        Text = "",
        TextColor3 = state.theme.Text,
        TextSize = 15,
    })
    applyCorner(hexBox, 6)
    themedStroke(state, hexBox, "Outline", 1, 0)
    registerThemeTarget(state, hexBox, "BackgroundColor3", "Inline")
    registerThemeTarget(state, hexBox, "TextColor3", "Text")

    local current = initialColor
    local syncing = false
    local channelBars = {}
    local channelLabels = {}

    local function commit(color)
        current = color
        preview.BackgroundColor3 = color
        hexBox.Text = colorToHex(color)
        onChanged(color)
    end

    local function buildChannel(title, getter, setter)
        local shell = create("Frame", {
            Parent = editor,
            BackgroundTransparency = 1,
            Size = UDim2.new(1, 0, 0, 34),
        })
        local titleLabel = newLabel(state, shell, title, 14, true, false)
        titleLabel.Size = UDim2.new(0, 16, 1, 0)
        local valueLabel = newLabel(state, shell, "0", 14, false, false)
        valueLabel.Size = UDim2.new(0, 32, 1, 0)
        valueLabel.Position = UDim2.new(1, -32, 0, 0)
        valueLabel.TextXAlignment = Enum.TextXAlignment.Right
        local barFrame = create("Frame", {
            Parent = shell,
            BackgroundTransparency = 1,
            Position = UDim2.new(0, 24, 0, 9),
            Size = UDim2.new(1, -64, 0, 16),
        })
        local bar = createBarInput(state, barFrame, function(ratio)
            if syncing then
                return
            end
            local raw = math.floor(ratio * 255 + 0.5)
            commit(setter(current, raw))
        end)
        channelBars[title] = { setRatio = bar.setRatio, getter = getter }
        channelLabels[title] = valueLabel
    end

    buildChannel("R", function(color) return color.R end, function(color, value)
        return Color3.fromRGB(value, math.floor(color.G * 255 + 0.5), math.floor(color.B * 255 + 0.5))
    end)
    buildChannel("G", function(color) return color.G end, function(color, value)
        return Color3.fromRGB(math.floor(color.R * 255 + 0.5), value, math.floor(color.B * 255 + 0.5))
    end)
    buildChannel("B", function(color) return color.B end, function(color, value)
        return Color3.fromRGB(math.floor(color.R * 255 + 0.5), math.floor(color.G * 255 + 0.5), value)
    end)

    local function sync(color)
        syncing = true
        current = color
        preview.BackgroundColor3 = color
        hexBox.Text = colorToHex(color)
        for key, barData in pairs(channelBars) do
            local channelValue = barData.getter(color)
            barData.setRatio(channelValue)
            channelLabels[key].Text = tostring(math.floor(channelValue * 255 + 0.5))
        end
        syncing = false
    end

    state.janitor:Add(hexBox.FocusLost:Connect(function(enterPressed)
        if not enterPressed then
            hexBox.Text = colorToHex(current)
            return
        end
        local parsed = hexToColor(hexBox.Text)
        if parsed then
            commit(parsed)
            sync(parsed)
        else
            hexBox.Text = colorToHex(current)
        end
    end))

    sync(initialColor)

    return {
        frame = editor,
        setOpen = function(open)
            editor.Visible = open
        end,
        sync = sync,
    }
end

local function beginBindCapture(state, entry, button)
    state.pendingBindCapture = { entry = entry, button = button }
    button.Text = "..."
end

local function clearBindCapture(state)
    if state.pendingBindCapture then
        local capture = state.pendingBindCapture
        state.pendingBindCapture = nil
        if capture.entry and capture.entry.bindButton then
            capture.entry.bindButton.Text = bindToText(capture.entry.bind)
        end
    end
end

local function createButtonEntry(state, parent, entry)
    local row = createRowShell(state, parent)
    entry.row = row
    local button = themedButton(state, row, "High", {
        Parent = row,
        BorderSizePixel = 0,
        Size = UDim2.new(1, 0, 0, 32),
        FontFace = Font.new("rbxasset://fonts/families/GothamSSm.json", Enum.FontWeight.Semibold, Enum.FontStyle.Normal),
        Text = entry.name,
        TextColor3 = state.theme.Text,
        TextSize = 14,
    })
    applyCorner(button, 8)
    themedStroke(state, button, "Outline", 1, 0)
    registerThemeTarget(state, button, "TextColor3", "Text")
    state.janitor:Add(button.MouseButton1Click:Connect(function()
        fireEntryCallback(entry)
    end))
    entry.sync = function()
        button.Text = entry.name
    end
    entry.syncTheme = function()
        button.TextColor3 = state.theme.Text
    end
end

local function createLabelEntry(state, parent, entry, paragraph)
    local row = createRowShell(state, parent)
    entry.row = row
    local title = newLabel(state, row, entry.name, 14, true, true)
    title.Size = UDim2.new(1, 0, 0, 18)
    local body = create("TextLabel", {
        Parent = row,
        BackgroundTransparency = 1,
        BorderSizePixel = 0,
        AutomaticSize = Enum.AutomaticSize.Y,
        Size = UDim2.new(1, 0, 0, 0),
        FontFace = Font.new("rbxasset://fonts/families/SourceSansPro.json", Enum.FontWeight.Regular, Enum.FontStyle.Normal),
        Text = entry.value,
        TextColor3 = state.theme.Text,
        TextSize = paragraph and 15 or 14,
        TextWrapped = true,
        TextXAlignment = Enum.TextXAlignment.Left,
        TextYAlignment = Enum.TextYAlignment.Top,
    })
    registerThemeTarget(state, body, "TextColor3", "Text")
    entry.sync = function()
        title.Text = entry.name
        body.Text = entry.value
    end
    entry.syncTheme = function()
        title.TextColor3 = state.theme.TextDim
        body.TextColor3 = state.theme.Text
    end
end

local function createTextboxEntry(state, parent, entry)
    local row = createRowShell(state, parent)
    entry.row = row
    local title = newLabel(state, row, entry.name, 14, true, false)
    title.Size = UDim2.new(1, 0, 0, 18)
    local box = create("TextBox", {
        Parent = row,
        BackgroundColor3 = state.theme.High,
        BorderSizePixel = 0,
        ClearTextOnFocus = false,
        Size = UDim2.new(1, 0, 0, 30),
        FontFace = Font.new("rbxasset://fonts/families/SourceSansPro.json", Enum.FontWeight.Semibold, Enum.FontStyle.Normal),
        PlaceholderText = entry.placeholder,
        Text = entry.value,
        TextColor3 = state.theme.Text,
        TextSize = 15,
        TextXAlignment = Enum.TextXAlignment.Left,
    })
    applyCorner(box, 8)
    applyPadding(box, 0, 10, 0, 10)
    themedStroke(state, box, "Outline", 1, 0)
    registerThemeTarget(state, box, "BackgroundColor3", "High")
    registerThemeTarget(state, box, "TextColor3", "Text")
    state.janitor:Add(box.FocusLost:Connect(function()
        setEntryValue(entry, box.Text, true)
    end))
    entry.sync = function()
        title.Text = entry.name
        box.Text = entry.value
        box.PlaceholderText = entry.placeholder
    end
    entry.syncTheme = function()
        title.TextColor3 = state.theme.TextDim
        box.BackgroundColor3 = state.theme.High
        box.TextColor3 = state.theme.Text
    end
end

local function createSliderEntry(state, parent, entry)
    local row = createRowShell(state, parent)
    entry.row = row
    local header = create("Frame", {
        Parent = row,
        BackgroundTransparency = 1,
        Size = UDim2.new(1, 0, 0, 20),
    })
    local title = newLabel(state, header, entry.name, 14, true, false)
    title.Size = UDim2.new(1, -90, 1, 0)
    local valueLabel = newLabel(state, header, "", 14, false, false)
    valueLabel.Size = UDim2.new(0, 90, 1, 0)
    valueLabel.Position = UDim2.new(1, -90, 0, 0)
    valueLabel.TextXAlignment = Enum.TextXAlignment.Right
    local bar = createBarInput(state, row, function(ratio)
        local raw = entry.min + ((entry.max - entry.min) * ratio)
        setEntryValue(entry, raw, true)
    end)
    entry.sync = function()
        local ratio = 0
        if entry.max > entry.min then
            ratio = (entry.value - entry.min) / (entry.max - entry.min)
        end
        bar.setRatio(ratio)
        title.Text = entry.name
        valueLabel.Text = tostring(entry.value) .. entry.suffix
    end
    entry.syncTheme = function()
        title.TextColor3 = state.theme.TextDim
        valueLabel.TextColor3 = state.theme.Text
    end
    entry.sync()
end

local function createKeybindEntry(state, parent, entry)
    local row = createRowShell(state, parent)
    entry.row = row
    local header = create("Frame", {
        Parent = row,
        BackgroundTransparency = 1,
        Size = UDim2.new(1, 0, 0, 24),
    })
    local label = newLabel(state, header, entry.name, 14, false, false)
    label.Size = UDim2.new(1, -88, 0, 24)
    local bindButton = newControlButton(state, header, 80)
    bindButton.Position = UDim2.new(1, -80, 0, 0)
    bindButton.Text = bindToText(entry.bind)
    entry.bindButton = bindButton
    state.janitor:Add(bindButton.MouseButton1Click:Connect(function()
        beginBindCapture(state, entry, bindButton)
    end))
    entry.sync = function()
        label.Text = entry.name
        bindButton.Text = bindToText(entry.bind)
    end
    entry.syncTheme = function()
        label.TextColor3 = state.theme.Text
        bindButton.TextColor3 = state.theme.Text
    end
end

local function createColorEntry(state, parent, entry)
    local row = createRowShell(state, parent)
    entry.row = row
    local header = create("Frame", {
        Parent = row,
        BackgroundTransparency = 1,
        Size = UDim2.new(1, 0, 0, 26),
    })
    local label = newLabel(state, header, entry.name, 14, false, false)
    label.Size = UDim2.new(1, -76, 1, 0)
    local previewButton = newControlButton(state, header, 68)
    previewButton.Position = UDim2.new(1, -68, 0, 0)
    local swatch = themedFrame(state, previewButton, "Accent", {
        Parent = previewButton,
        BorderSizePixel = 0,
        Position = UDim2.new(0, 6, 0.5, -6),
        Size = UDim2.new(0, 12, 0, 12),
    })
    applyCorner(swatch, 12)
    local editorOpen = false
    local editor = createColorEditor(state, row, entry.color, function(color)
        entry.color = color
        refreshEntry(entry)
        fireEntryCallback(entry)
    end)
    state.janitor:Add(previewButton.MouseButton1Click:Connect(function()
        editorOpen = not editorOpen
        editor.setOpen(editorOpen)
    end))
    entry.sync = function()
        label.Text = entry.name
        swatch.BackgroundColor3 = entry.color
        previewButton.Text = colorToHex(entry.color)
        editor.sync(entry.color)
    end
    entry.syncTheme = function()
        label.TextColor3 = state.theme.Text
        previewButton.TextColor3 = state.theme.Text
    end
    entry.sync()
end

local function createDropdownEntry(state, parent, entry)
    local row = createRowShell(state, parent)
    entry.row = row

    local trigger = themedButton(state, row, "High", {
        Parent = row,
        BorderSizePixel = 0,
        Size = UDim2.new(1, 0, 0, 32),
        FontFace = Font.new("rbxasset://fonts/families/GothamSSm.json", Enum.FontWeight.Semibold, Enum.FontStyle.Normal),
        Text = "",
        TextColor3 = state.theme.Text,
        TextSize = 14,
    })
    applyCorner(trigger, 8)
    themedStroke(state, trigger, "Outline", 1, 0)
    registerThemeTarget(state, trigger, "TextColor3", "Text")

    local optionsHolder = themedFrame(state, row, "Low", {
        Parent = row,
        BorderSizePixel = 0,
        AutomaticSize = Enum.AutomaticSize.Y,
        Size = UDim2.new(1, 0, 0, 0),
        Visible = false,
    })
    applyCorner(optionsHolder, 8)
    applyPadding(optionsHolder, 8, 8, 8, 8)
    themedStroke(state, optionsHolder, "Outline", 1, 0)
    create("UIListLayout", {
        Parent = optionsHolder,
        FillDirection = Enum.FillDirection.Vertical,
        Padding = UDim.new(0, 6),
        SortOrder = Enum.SortOrder.LayoutOrder,
    })

    local function rebuildOptions()
        for _, child in ipairs(optionsHolder:GetChildren()) do
            if not child:IsA("UIListLayout") then
                child:Destroy()
            end
        end
        for _, option in ipairs(entry.values) do
            local selected = entry.multi and entry.value[option] or entry.value == option
            local optionButton = themedButton(state, optionsHolder, selected and "Accent" or "High", {
                Parent = optionsHolder,
                BorderSizePixel = 0,
                Size = UDim2.new(1, 0, 0, 26),
                FontFace = Font.new("rbxasset://fonts/families/SourceSansPro.json", Enum.FontWeight.Semibold, Enum.FontStyle.Normal),
                Text = option,
                TextColor3 = state.theme.Text,
                TextSize = 14,
            })
            applyCorner(optionButton, 6)
            themedStroke(state, optionButton, selected and "AccentGlow" or "Outline", 1, 0)
            registerThemeTarget(state, optionButton, "TextColor3", "Text")
            state.janitor:Add(optionButton.MouseButton1Click:Connect(function()
                if entry.multi then
                    local nextValue = copyMap(entry.value)
                    nextValue[option] = not nextValue[option]
                    if not nextValue[option] then
                        nextValue[option] = nil
                    end
                    setEntryValue(entry, nextValue, true)
                else
                    setEntryValue(entry, option, true)
                    entry.open = false
                    optionsHolder.Visible = false
                end
            end))
        end
    end

    state.janitor:Add(trigger.MouseButton1Click:Connect(function()
        entry.open = not entry.open
        optionsHolder.Visible = entry.open
    end))

    entry.rebuildOptions = rebuildOptions
    entry.sync = function()
        trigger.Text = string.format("%s  [%s]", entry.name, getDropdownText(entry))
        rebuildOptions()
        optionsHolder.Visible = entry.open == true
    end
    entry.syncTheme = function()
        trigger.TextColor3 = state.theme.Text
    end
    entry.sync()
end

local function createToggleEntry(state, parent, entry)
    local row = createRowShell(state, parent)
    entry.row = row

    local header = create("Frame", {
        Parent = row,
        BackgroundTransparency = 1,
        Size = UDim2.new(1, 0, 0, 28),
    })
    local label = newLabel(state, header, entry.name, 14, false, false)
    label.Size = UDim2.new(1, -180, 1, 0)

    local right = create("Frame", {
        Parent = header,
        AnchorPoint = Vector2.new(1, 0),
        BackgroundTransparency = 1,
        Position = UDim2.new(1, 0, 0, 0),
        Size = UDim2.new(0, entry.hasColorPicker and 172 or 140, 0, 24),
    })
    create("UIListLayout", {
        Parent = right,
        FillDirection = Enum.FillDirection.Horizontal,
        HorizontalAlignment = Enum.HorizontalAlignment.Right,
        VerticalAlignment = Enum.VerticalAlignment.Center,
        Padding = UDim.new(0, 6),
        SortOrder = Enum.SortOrder.LayoutOrder,
    })

    local bindButton = newControlButton(state, right, 54)
    local modeButton = newControlButton(state, right, 28)
    local toggleButton = newControlButton(state, right, 44)
    local colorButton
    local colorEditor
    local colorOpen = false

    if entry.hasColorPicker then
        colorButton = newControlButton(state, right, 24)
        colorButton.Text = ""
        entry.colorSwatch = themedFrame(state, colorButton, "Accent", {
            Parent = colorButton,
            BorderSizePixel = 0,
            AnchorPoint = Vector2.new(0.5, 0.5),
            Position = UDim2.new(0.5, 0, 0.5, 0),
            Size = UDim2.new(0, 12, 0, 12),
        })
        applyCorner(entry.colorSwatch, 12)
        colorEditor = createColorEditor(state, row, entry.color, function(color)
            entry.color = color
            refreshEntry(entry)
            safeCallback(entry.colorChanged, color)
        end)
        state.janitor:Add(colorButton.MouseButton1Click:Connect(function()
            colorOpen = not colorOpen
            colorEditor.setOpen(colorOpen)
        end))
    end

    state.janitor:Add(toggleButton.MouseButton1Click:Connect(function()
        setEntryValue(entry, not entry.state, true)
    end))
    state.janitor:Add(bindButton.MouseButton1Click:Connect(function()
        beginBindCapture(state, entry, bindButton)
    end))
    state.janitor:Add(modeButton.MouseButton1Click:Connect(function()
        local nextMode = "toggle"
        if entry.mode == "toggle" then
            nextMode = "hold"
        elseif entry.mode == "hold" then
            nextMode = "always"
        end
        setEntryValue(entry, { mode = nextMode }, false)
        if nextMode == "always" then
            setEntryValue(entry, { state = true }, true)
        else
            refreshEntry(entry)
        end
    end))

    entry.bindButton = bindButton
    entry.sync = function()
        label.Text = entry.name
        bindButton.Text = bindToText(entry.bind)
        modeButton.Text = string.upper(string.sub(entry.mode, 1, 1))
        toggleButton.Text = entry.state and "ON" or "OFF"
        toggleButton.BackgroundColor3 = entry.state and entry.color or state.theme.High
        if entry.colorSwatch then
            entry.colorSwatch.BackgroundColor3 = entry.color
        end
        if colorEditor then
            colorEditor.sync(entry.color)
        end
    end
    entry.syncTheme = function()
        label.TextColor3 = state.theme.Text
        bindButton.TextColor3 = state.theme.Text
        modeButton.TextColor3 = state.theme.Text
        toggleButton.TextColor3 = state.theme.Text
        if not entry.state then
            toggleButton.BackgroundColor3 = state.theme.High
        end
    end
    entry.sync()
end

local EntryBuilders = {
    button = createButtonEntry,
    slider = createSliderEntry,
    dropdown = createDropdownEntry,
    textbox = createTextboxEntry,
    color = createColorEntry,
    keybind = createKeybindEntry,
    toggle = createToggleEntry,
    label = function(state, parent, entry) createLabelEntry(state, parent, entry, false) end,
    paragraph = function(state, parent, entry) createLabelEntry(state, parent, entry, true) end,
}

local ControlMethods = {}
ControlMethods.__index = ControlMethods

function ControlMethods:Get()
    local entry = self.entry
    if not entry then
        return nil
    end
    if entry.kind == "toggle" then
        return entry.state
    end
    if entry.kind == "slider" or entry.kind == "textbox" or entry.kind == "label" or entry.kind == "paragraph" then
        return entry.value
    end
    if entry.kind == "dropdown" then
        return entry.multi and copyMap(entry.value) or entry.value
    end
    if entry.kind == "color" then
        return entry.color
    end
    if entry.kind == "keybind" then
        return entry.bind
    end
    return nil
end

function ControlMethods:Set(value)
    if self.entry then
        setEntryValue(self.entry, value, true)
        refreshKeybindList(self._state)
        refreshWatermark(self._state)
    end
    return self
end

function ControlMethods:SetVisible(state)
    if self.entry and self.entry.row then
        self.entry.row.Visible = state ~= false
    end
    return self
end

function ControlMethods:SetColor(color)
    if self.entry and typeof(color) == "Color3" then
        if self.entry.kind == "toggle" then
            setEntryValue(self.entry, { color = color }, false)
        elseif self.entry.kind == "color" then
            setEntryValue(self.entry, color, false)
        end
    end
    return self
end

function ControlMethods:RefreshOptions(values, preferredValue)
    if self.entry and self.entry.kind == "dropdown" then
        self.entry.values = copyArray(values or {})
        self.entry.value = normalizeDropdownValue(self.entry, preferredValue ~= nil and preferredValue or self.entry.value)
        refreshEntry(self.entry)
    end
    return self
end

function ControlMethods:Press()
    if self.entry and self.entry.kind == "button" then
        fireEntryCallback(self.entry)
    end
    return self
end

local function registerEntry(state, parent, entry)
    if entry.flag then
        if state.entryMap[entry.flag] then
            error(string.format("duplicate flag '%s'", entry.flag))
        end
        state.entryMap[entry.flag] = entry
    end
    table.insert(state.entries, entry)
    if entry.kind == "toggle" or entry.kind == "keybind" then
        table.insert(state.bindEntries, entry)
    end
    local builder = EntryBuilders[entry.kind]
    builder(state, parent, entry)
    refreshKeybindList(state)
    refreshWatermark(state)
    return setmetatable({ entry = entry, _state = state }, ControlMethods)
end

local function createBaseEntry(section, kind, config)
    config = config or {}
    local entry = {
        kind = kind,
        name = tostring(config.Name or kind),
        flag = config.Flag,
        callback = config.Callback,
        skipConfig = config.SkipConfig == true or kind == "button",
    }
    if kind == "toggle" then
        entry.state = config.Default == true
        entry.color = typeof(config.Color) == "Color3" and config.Color or section._state.theme.Accent
        entry.bind = normalizeKeybind(config.Bind or config.Keybind)
        entry.mode = normalizeToggleMode(config.Mode)
        entry.hasColorPicker = config.ColorPicker == true
        entry.colorChanged = config.ColorChanged
        entry.defaultState = entry.state
        entry.defaultBind = entry.bind
        entry.defaultMode = entry.mode
        entry.defaultColor = entry.color
    elseif kind == "slider" then
        entry.min = tonumber(config.Min) or 0
        entry.max = tonumber(config.Max) or 100
        if entry.max < entry.min then
            entry.min, entry.max = entry.max, entry.min
        end
        entry.round = tonumber(config.Round) or 1
        entry.suffix = tostring(config.Type or "")
        entry.value = normalizeSliderValue(entry, config.Default ~= nil and config.Default or entry.min)
        entry.defaultValue = entry.value
    elseif kind == "dropdown" then
        entry.values = copyArray(config.Values or {})
        entry.multi = config.Multi == true
        entry.value = normalizeDropdownValue(entry, config.Default)
        entry.defaultValue = entry.multi and copyMap(entry.value) or entry.value
        entry.open = false
    elseif kind == "textbox" then
        entry.value = tostring(config.Default or "")
        entry.placeholder = tostring(config.Placeholder or config.Hint or "")
        entry.defaultValue = entry.value
    elseif kind == "color" then
        entry.color = typeof(config.Default) == "Color3" and config.Default or section._state.theme.Accent
        entry.defaultValue = entry.color
    elseif kind == "keybind" then
        entry.bind = normalizeKeybind(config.Default)
        entry.changed = config.Changed
        entry.defaultValue = entry.bind
    elseif kind == "label" or kind == "paragraph" then
        entry.value = tostring(config.Text or config.Content or config.Value or config.Name or "")
        entry.defaultValue = entry.value
    end
    return entry
end

local SectionMethods = {}
SectionMethods.__index = SectionMethods

function SectionMethods:AddSubsection(config)
    local name = type(config) == "table" and tostring(config.Name or "Subsection") or tostring(config or "Subsection")
    local shell = themedFrame(self._state, self._container, "Low", {
        Parent = self._container,
        BorderSizePixel = 0,
        AutomaticSize = Enum.AutomaticSize.Y,
        Size = UDim2.new(1, 0, 0, 0),
    })
    applyCorner(shell, 8)
    applyPadding(shell, 10, 10, 10, 10)
    themedStroke(self._state, shell, "Outline", 1, 0)
    local title = newLabel(self._state, shell, name, 13, true, true)
    title.Size = UDim2.new(1, 0, 0, 18)
    local body = create("Frame", {
        Parent = shell,
        BackgroundTransparency = 1,
        AutomaticSize = Enum.AutomaticSize.Y,
        Size = UDim2.new(1, 0, 0, 0),
    })
    create("UIListLayout", {
        Parent = shell,
        FillDirection = Enum.FillDirection.Vertical,
        Padding = UDim.new(0, 8),
        SortOrder = Enum.SortOrder.LayoutOrder,
    })
    create("UIListLayout", {
        Parent = body,
        FillDirection = Enum.FillDirection.Vertical,
        Padding = UDim.new(0, 8),
        SortOrder = Enum.SortOrder.LayoutOrder,
    })
    return setmetatable({
        _state = self._state,
        _container = body,
        _name = name,
    }, SectionMethods)
end

function SectionMethods:AddToggle(config) return registerEntry(self._state, self._container, createBaseEntry(self, "toggle", config)) end
function SectionMethods:AddButton(config) return registerEntry(self._state, self._container, createBaseEntry(self, "button", config)) end
function SectionMethods:AddSlider(config) return registerEntry(self._state, self._container, createBaseEntry(self, "slider", config)) end
function SectionMethods:AddDropdown(config) return registerEntry(self._state, self._container, createBaseEntry(self, "dropdown", config)) end
function SectionMethods:AddTextbox(config) return registerEntry(self._state, self._container, createBaseEntry(self, "textbox", config)) end
function SectionMethods:AddColorPicker(config) return registerEntry(self._state, self._container, createBaseEntry(self, "color", config)) end
function SectionMethods:AddKeybind(config) return registerEntry(self._state, self._container, createBaseEntry(self, "keybind", config)) end
function SectionMethods:AddLabel(config)
    if type(config) == "string" then
        config = { Name = "Label", Text = config }
    end
    return registerEntry(self._state, self._container, createBaseEntry(self, "label", config))
end
function SectionMethods:AddParagraph(config)
    if type(config) == "string" then
        config = { Name = "Paragraph", Text = config }
    end
    return registerEntry(self._state, self._container, createBaseEntry(self, "paragraph", config))
end
SectionMethods.AddInput = SectionMethods.AddTextbox
SectionMethods.AddGroupbox = SectionMethods.AddSubsection

local MenuMethods = {}
MenuMethods.__index = MenuMethods

function MenuMethods:AddSection(config)
    config = config or {}
    local useRight = string.lower(tostring(config.Position or "left")) == "right"
    local parent = useRight and self._tab.rightColumn or self._tab.leftColumn
    local shell = themedFrame(self._state, parent, "High", {
        Parent = parent,
        BorderSizePixel = 0,
        AutomaticSize = Enum.AutomaticSize.Y,
        Size = UDim2.new(1, 0, 0, 0),
    })
    applyCorner(shell, 10)
    applyPadding(shell, 12, 12, 12, 12)
    themedStroke(self._state, shell, "Outline", 1, 0)
    local title = newLabel(self._state, shell, tostring(config.Name or "Section"), 15, false, true)
    title.Size = UDim2.new(1, 0, 0, 20)
    local body = create("Frame", {
        Parent = shell,
        BackgroundTransparency = 1,
        AutomaticSize = Enum.AutomaticSize.Y,
        Size = UDim2.new(1, 0, 0, 0),
    })
    create("UIListLayout", {
        Parent = shell,
        FillDirection = Enum.FillDirection.Vertical,
        Padding = UDim.new(0, 10),
        SortOrder = Enum.SortOrder.LayoutOrder,
    })
    create("UIListLayout", {
        Parent = body,
        FillDirection = Enum.FillDirection.Vertical,
        Padding = UDim.new(0, 8),
        SortOrder = Enum.SortOrder.LayoutOrder,
    })
    return setmetatable({
        _state = self._state,
        _container = body,
        _name = tostring(config.Name or "Section"),
    }, SectionMethods)
end

MenuMethods.AddGroupbox = MenuMethods.AddSection

local WindowMethods = {}
WindowMethods.__index = WindowMethods

function WindowMethods:AddMenu(config)
    config = config or {}
    local state = self._state
    local tabId = generateName("tab")
    local tabName = tostring(config.Name or ("Tab " .. tostring(#state.tabOrder + 1)))
    local button = themedButton(state, state.tabList, "High", {
        Parent = state.tabList,
        BorderSizePixel = 0,
        Size = UDim2.new(1, 0, 0, 36),
        FontFace = Font.new("rbxasset://fonts/families/GothamSSm.json", Enum.FontWeight.Semibold, Enum.FontStyle.Normal),
        Text = "  " .. tabName,
        TextColor3 = state.theme.Text,
        TextSize = 14,
        TextXAlignment = Enum.TextXAlignment.Left,
    })
    applyCorner(button, 8)
    themedStroke(state, button, "Outline", 1, 0)
    registerThemeTarget(state, button, "TextColor3", "Text")
    local icon = create("ImageLabel", {
        Parent = button,
        BackgroundTransparency = 1,
        BorderSizePixel = 0,
        Position = UDim2.new(0, 10, 0.5, -8),
        Size = UDim2.new(0, 16, 0, 16),
        Image = TabIcons[tostring(config.Icon or "")] or "",
        ImageColor3 = state.theme.TextDim,
    })
    registerThemeTarget(state, icon, "ImageColor3", "TextDim")

    local page = create("Frame", {
        Parent = state.pages,
        BackgroundTransparency = 1,
        BorderSizePixel = 0,
        Size = UDim2.new(1, 0, 1, 0),
        Visible = false,
    })
    local leftColumn = create("ScrollingFrame", {
        Parent = page,
        Active = true,
        AutomaticCanvasSize = Enum.AutomaticSize.Y,
        BackgroundTransparency = 1,
        BorderSizePixel = 0,
        CanvasSize = UDim2.new(),
        ScrollBarImageColor3 = state.theme.Accent,
        ScrollBarThickness = 3,
        Size = UDim2.new(0.5, -8, 1, 0),
    })
    local rightColumn = create("ScrollingFrame", {
        Parent = page,
        Active = true,
        AutomaticCanvasSize = Enum.AutomaticSize.Y,
        BackgroundTransparency = 1,
        BorderSizePixel = 0,
        CanvasSize = UDim2.new(),
        Position = UDim2.new(0.5, 8, 0, 0),
        ScrollBarImageColor3 = state.theme.Accent,
        ScrollBarThickness = 3,
        Size = UDim2.new(0.5, -8, 1, 0),
    })
    registerThemeTarget(state, leftColumn, "ScrollBarImageColor3", "Accent")
    registerThemeTarget(state, rightColumn, "ScrollBarImageColor3", "Accent")
    create("UIListLayout", {
        Parent = leftColumn,
        FillDirection = Enum.FillDirection.Vertical,
        Padding = UDim.new(0, 10),
        SortOrder = Enum.SortOrder.LayoutOrder,
    })
    create("UIListLayout", {
        Parent = rightColumn,
        FillDirection = Enum.FillDirection.Vertical,
        Padding = UDim.new(0, 10),
        SortOrder = Enum.SortOrder.LayoutOrder,
    })

    local tab = {
        id = tabId,
        button = button,
        page = page,
        leftColumn = leftColumn,
        rightColumn = rightColumn,
    }

    local function selectTab()
        for _, item in ipairs(state.tabOrder) do
            local selected = item.id == tabId
            item.page.Visible = selected
            item.button.BackgroundColor3 = selected and state.theme.Section or state.theme.High
            local stroke = item.button:FindFirstChildOfClass("UIStroke")
            if stroke then
                stroke.Color = selected and state.theme.AccentGlow or state.theme.Outline
            end
        end
        state.currentTab = tabId
    end

    state.janitor:Add(button.MouseButton1Click:Connect(selectTab))
    table.insert(state.tabOrder, tab)
    if not state.currentTab then
        selectTab()
    end

    return setmetatable({ _state = state, _tab = tab }, MenuMethods)
end

function WindowMethods:ExportConfig(useDefaults)
    local ok, encoded = pcall(function()
        return Services.HttpService:JSONEncode(exportConfigData(self._state, useDefaults == true))
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
    if not ok or type(payload) ~= "table" or type(payload.values) ~= "table" then
        return false, "failed to decode config"
    end
    for flag, encodedValue in pairs(payload.values) do
        local entry = self._state.entryMap[flag]
        if entry then
            setEntryValue(entry, deserializeValue(encodedValue), true)
        end
    end
    refreshKeybindList(self._state)
    refreshWatermark(self._state)
    return true
end

function WindowMethods:GetConfigs()
    if not supportsFilesystem() or not FileApi.listfiles then
        return {}
    end
    ensureFolder(self._state.configDirectory)
    ensureFolder(self._state.configFolder)
    local ok, files = pcall(FileApi.listfiles, self._state.configFolder)
    if not ok or type(files) ~= "table" then
        return {}
    end
    local output = {}
    for _, path in ipairs(files) do
        local name = tostring(path):match("([^/\\]+)%.json$")
        if name then
            table.insert(output, name)
        end
    end
    table.sort(output)
    return output
end

function WindowMethods:RefreshConfigs()
    return self:GetConfigs()
end

function WindowMethods:SaveConfig(name)
    if not supportsFilesystem() then
        return false, "filesystem api is unavailable"
    end
    local configName = sanitizeConfigName(name)
    if configName == "" then
        return false, "config name is empty"
    end
    ensureFolder(self._state.configDirectory)
    ensureFolder(self._state.configFolder)
    local encoded, message = self:ExportConfig(false)
    if not encoded then
        return false, message
    end
    local ok, writeMessage = pcall(FileApi.writefile, getConfigPath(self._state, configName), encoded)
    if not ok then
        return false, writeMessage or "failed to write config"
    end
    return true
end

function WindowMethods:LoadConfig(name)
    if not supportsFilesystem() then
        return false, "filesystem api is unavailable"
    end
    local configName = sanitizeConfigName(name)
    if configName == "" then
        return false, "config name is empty"
    end
    local path = getConfigPath(self._state, configName)
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
    return self:ImportConfig(content)
end

function WindowMethods:DeleteConfig(name)
    if not FileApi.delfile then
        return false, "filesystem delete api is unavailable"
    end
    local configName = sanitizeConfigName(name)
    if configName == "" then
        return false, "config name is empty"
    end
    local path = getConfigPath(self._state, configName)
    local ok, message = pcall(FileApi.delfile, path)
    if not ok then
        return false, message or "failed to delete config"
    end
    return true
end

function WindowMethods:LoadDefaults()
    local payload = exportConfigData(self._state, true)
    for flag, encodedValue in pairs(payload.values) do
        local entry = self._state.entryMap[flag]
        if entry then
            setEntryValue(entry, deserializeValue(encodedValue), true)
        end
    end
    refreshKeybindList(self._state)
    refreshWatermark(self._state)
    return true
end

function WindowMethods:SetMenuBind(bind)
    local normalized = normalizeKeybind(bind)
    if normalized then
        self._state.menuBind = normalized
        if self._state.menuBindLabel then
            self._state.menuBindLabel.Text = "menu bind: " .. bindToText(normalized)
        end
    end
    return self
end

function WindowMethods:SetInfo(text)
    self._state.info = tostring(text or "")
    if self._state.infoLabel then
        self._state.infoLabel.Text = self._state.info
    end
    return self
end

function WindowMethods:SetWatermark(state)
    self._state.showWatermark = state ~= false
    refreshWatermark(self._state)
    return self
end

function WindowMethods:SetKeybindList(state)
    self._state.showKeybindList = state ~= false
    refreshKeybindList(self._state)
    return self
end

function WindowMethods:GetFlag(flag)
    local entry = self._state.entryMap[flag]
    if not entry then
        return nil
    end
    return setmetatable({ entry = entry, _state = self._state }, ControlMethods):Get()
end

function WindowMethods:Destroy()
    local state = self._state
    if state.destroyed then
        return
    end
    state.destroyed = true
    clearBindCapture(state)
    state.janitor:Cleanup()
    if GlobalScope and GlobalScope[ActiveWindowKey] == state then
        GlobalScope[ActiveWindowKey] = nil
    end
end

local function buildWindowShell(state)
    local gui = create("ScreenGui", {
        Parent = RootParent,
        Name = state.guiName,
        DisplayOrder = 32000,
        IgnoreGuiInset = true,
        ResetOnSpawn = false,
        ZIndexBehavior = Enum.ZIndexBehavior.Sibling,
    })
    state.janitor:Add(gui)
    state.gui = gui

    local blur = create("BlurEffect", {
        Parent = Services.Lighting,
        Name = state.blurName,
        Enabled = true,
        Size = 10,
    })
    state.janitor:Add(blur)
    state.blur = blur

    local root = create("Frame", {
        Parent = gui,
        BackgroundTransparency = 1,
        BorderSizePixel = 0,
        Size = UDim2.fromScale(1, 1),
    })

    local watermarkFrame = themedFrame(state, root, "Outline", {
        Parent = root,
        AnchorPoint = Vector2.new(1, 0),
        BorderSizePixel = 0,
        Position = UDim2.new(1, -16, 0, 16),
        Size = UDim2.new(0, 220, 0, 28),
    })
    applyCorner(watermarkFrame, 8)
    applyPadding(watermarkFrame, 0, 10, 0, 10)
    themedStroke(state, watermarkFrame, "AccentGlow", 1, 0.2)
    state.watermarkFrame = watermarkFrame
    state.watermarkLabel = newLabel(state, watermarkFrame, "", 13, false, false)
    state.watermarkLabel.Size = UDim2.new(1, 0, 1, 0)
    state.watermarkLabel.TextXAlignment = Enum.TextXAlignment.Center

    local keybindPanel = themedFrame(state, root, "Outline", {
        Parent = root,
        AnchorPoint = Vector2.new(1, 0.5),
        BorderSizePixel = 0,
        Position = UDim2.new(1, -16, 0.5, 0),
        AutomaticSize = Enum.AutomaticSize.Y,
        Size = UDim2.new(0, 220, 0, 0),
        Visible = false,
    })
    applyCorner(keybindPanel, 10)
    applyPadding(keybindPanel, 10, 10, 10, 10)
    themedStroke(state, keybindPanel, "AccentGlow", 1, 0.2)
    state.keybindPanel = keybindPanel
    local bindTitle = newLabel(state, keybindPanel, "Active binds", 14, false, true)
    bindTitle.Size = UDim2.new(1, 0, 0, 18)
    state.keybindListBody = create("Frame", {
        Parent = keybindPanel,
        BackgroundTransparency = 1,
        AutomaticSize = Enum.AutomaticSize.Y,
        Size = UDim2.new(1, 0, 0, 0),
    })
    create("UIListLayout", {
        Parent = keybindPanel,
        FillDirection = Enum.FillDirection.Vertical,
        Padding = UDim.new(0, 8),
        SortOrder = Enum.SortOrder.LayoutOrder,
    })
    create("UIListLayout", {
        Parent = state.keybindListBody,
        FillDirection = Enum.FillDirection.Vertical,
        Padding = UDim.new(0, 6),
        SortOrder = Enum.SortOrder.LayoutOrder,
    })

    local window = themedFrame(state, root, "Outline", {
        Parent = root,
        AnchorPoint = Vector2.new(0.5, 0.5),
        BorderSizePixel = 0,
        Position = UDim2.fromScale(0.5, 0.5),
        Size = UDim2.fromOffset(760, 520),
    })
    applyCorner(window, 14)
    themedStroke(state, window, "AccentGlow", 1, 0.15)
    state.windowFrame = window

    local topbar = themedFrame(state, window, "Section", {
        Parent = window,
        BorderSizePixel = 0,
        Size = UDim2.new(1, 0, 0, 56),
    })
    applyCorner(topbar, 14)
    themedFrame(state, topbar, "Section", {
        Parent = topbar,
        BorderSizePixel = 0,
        Position = UDim2.new(0, 0, 1, -14),
        Size = UDim2.new(1, 0, 0, 14),
    })
    local titleLabel = newLabel(state, topbar, state.title, 18, false, true)
    titleLabel.Position = UDim2.new(0, 16, 0, 7)
    titleLabel.Size = UDim2.new(1, -160, 0, 20)
    local infoLabel = newLabel(state, topbar, state.info, 14, true, false)
    infoLabel.Position = UDim2.new(0, 16, 0, 28)
    infoLabel.Size = UDim2.new(1, -160, 0, 18)
    local bindLabel = newLabel(state, topbar, "menu bind: " .. bindToText(state.menuBind), 14, false, false)
    bindLabel.Position = UDim2.new(1, -150, 0, 0)
    bindLabel.Size = UDim2.new(0, 136, 1, 0)
    bindLabel.TextXAlignment = Enum.TextXAlignment.Right
    state.infoLabel = infoLabel
    state.menuBindLabel = bindLabel

    local sidebar = themedFrame(state, window, "Inline", {
        Parent = window,
        BorderSizePixel = 0,
        Position = UDim2.new(0, 12, 0, 68),
        Size = UDim2.new(0, 168, 1, -80),
    })
    applyCorner(sidebar, 12)
    applyPadding(sidebar, 12, 12, 12, 12)
    themedStroke(state, sidebar, "Outline", 1, 0)
    state.tabList = create("Frame", {
        Parent = sidebar,
        BackgroundTransparency = 1,
        AutomaticSize = Enum.AutomaticSize.Y,
        Size = UDim2.new(1, 0, 0, 0),
    })
    create("UIListLayout", {
        Parent = sidebar,
        FillDirection = Enum.FillDirection.Vertical,
        Padding = UDim.new(0, 8),
        SortOrder = Enum.SortOrder.LayoutOrder,
    })
    create("UIListLayout", {
        Parent = state.tabList,
        FillDirection = Enum.FillDirection.Vertical,
        Padding = UDim.new(0, 8),
        SortOrder = Enum.SortOrder.LayoutOrder,
    })

    state.pages = themedFrame(state, window, "Inline", {
        Parent = window,
        BorderSizePixel = 0,
        Position = UDim2.new(0, 192, 0, 68),
        Size = UDim2.new(1, -204, 1, -80),
    })
    applyCorner(state.pages, 12)
    applyPadding(state.pages, 12, 12, 12, 12)
    themedStroke(state, state.pages, "Outline", 1, 0)

    local dragging = false
    local dragOrigin = Vector2.zero
    local frameOrigin = Vector2.zero
    state.janitor:Add(topbar.InputBegan:Connect(function(input)
        if input.UserInputType == Enum.UserInputType.MouseButton1 then
            dragging = true
            dragOrigin = input.Position
            frameOrigin = window.AbsolutePosition
        end
    end))
    state.janitor:Add(Services.UserInputService.InputEnded:Connect(function(input)
        if input.UserInputType == Enum.UserInputType.MouseButton1 then
            dragging = false
        end
    end))
    state.janitor:Add(Services.UserInputService.InputChanged:Connect(function(input)
        if dragging and input.UserInputType == Enum.UserInputType.MouseMovement then
            local delta = input.Position - dragOrigin
            window.Position = UDim2.fromOffset(frameOrigin.X + delta.X + (window.AbsoluteSize.X * 0.5), frameOrigin.Y + delta.Y + (window.AbsoluteSize.Y * 0.5))
        end
    end))
end

local function hookInput(state)
    state.janitor:Add(Services.UserInputService.InputBegan:Connect(function(input, gameProcessed)
        if state.destroyed then
            return
        end

        if state.pendingBindCapture then
            if input.KeyCode == Enum.KeyCode.Escape then
                clearBindCapture(state)
                return
            end
            local bind = getInputBind(input)
            if bind then
                local capture = state.pendingBindCapture
                clearBindCapture(state)
                setEntryValue(capture.entry, bind, true)
                refreshKeybindList(state)
            end
            return
        end

        if gameProcessed or Services.UserInputService:GetFocusedTextBox() then
            return
        end

        if inputMatchesBind(input, state.menuBind) then
            setWindowVisible(state, not state.visible)
            return
        end

        for _, entry in ipairs(state.bindEntries) do
            if entry.bind and inputMatchesBind(input, entry.bind) then
                if entry.kind == "toggle" then
                    if entry.mode == "hold" or entry.mode == "always" then
                        setEntryValue(entry, true, true)
                    else
                        setEntryValue(entry, not entry.state, true)
                    end
                elseif entry.kind == "keybind" then
                    safeCallback(entry.callback, bindToText(entry.bind), entry.bind)
                end
            end
        end
    end))

    state.janitor:Add(Services.UserInputService.InputEnded:Connect(function(input)
        if state.destroyed then
            return
        end
        for _, entry in ipairs(state.bindEntries) do
            if entry.kind == "toggle" and entry.mode == "hold" and entry.bind and inputMatchesBind(input, entry.bind) then
                setEntryValue(entry, false, true)
            end
        end
    end))
end

local function newWindowState(config)
    local configDirectory = sanitizeConfigName(config.ConfigDirectory or config.Name or "Atlanta")
    if configDirectory == "" then
        configDirectory = "Atlanta"
    end
    return {
        theme = copyTable(ThemeTemplate),
        themeTargets = {},
        janitor = newJanitor(),
        entries = {},
        entryMap = {},
        bindEntries = {},
        tabOrder = {},
        currentTab = nil,
        title = tostring(config.Name or "Atlanta"),
        info = tostring(config.Info or "Safe Luau menu library"),
        visible = true,
        showWatermark = config.Watermark ~= false,
        showKeybindList = config.KeybindList ~= false,
        menuBind = normalizeKeybind(config.MenuBind or config.Keybind) or Enum.KeyCode.Insert,
        guiName = generateName("AtlantaUI"),
        blurName = generateName("AtlantaBlur"),
        destroyed = false,
        configDirectory = configDirectory,
        configFolder = configDirectory .. "/configs",
    }
end

local Atlanta = {
    Services = Services,
    Utilities = {
        create = create,
        tween = tween,
        bindToText = bindToText,
        inputMatchesBind = inputMatchesBind,
    },
    Components = {
        Window = WindowMethods,
        Menu = MenuMethods,
        Section = SectionMethods,
        Control = ControlMethods,
    },
    Theme = ThemeTemplate,
}

function Atlanta:SetTheme(config)
    config = config or {}
    for key, value in pairs(config) do
        if ThemeTemplate[key] ~= nil and typeof(value) == "Color3" then
            ThemeTemplate[key] = value
        end
    end
    if GlobalScope and GlobalScope[ActiveWindowKey] then
        local state = GlobalScope[ActiveWindowKey]
        for key, value in pairs(ThemeTemplate) do
            state.theme[key] = value
        end
        applyTheme(state)
    end
    return self
end

local function destroyActiveWindow()
    if GlobalScope and GlobalScope[ActiveWindowKey] then
        local state = GlobalScope[ActiveWindowKey]
        if state.windowObject then
            pcall(function()
                state.windowObject:Destroy()
            end)
        elseif state.janitor then
            pcall(function()
                state.janitor:Cleanup()
            end)
        end
        GlobalScope[ActiveWindowKey] = nil
    end
end

local function createWindow(config)
    config = config or {}
    destroyActiveWindow()

    local state = newWindowState(config)
    for key, value in pairs(ThemeTemplate) do
        state.theme[key] = value
    end

    buildWindowShell(state)
    hookInput(state)
    applyTheme(state)
    refreshKeybindList(state)
    refreshWatermark(state)
    setWindowVisible(state, true)

    local windowObject = setmetatable({ _state = state }, WindowMethods)
    state.windowObject = windowObject

    if GlobalScope then
        GlobalScope[ActiveWindowKey] = state
        GlobalScope.Atlanta = Atlanta
        GlobalScope.NeverPaste = Atlanta
    end

    Atlanta.flags = state.entryMap
    Atlanta.entries = state.entries
    Atlanta.State = state

    if config.Intro ~= false then
        tween(state.windowFrame, 0.18, { Size = UDim2.fromOffset(760, 520) })
    end

    return windowObject
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

function Atlanta:GetFlag(flag)
    if not GlobalScope or not GlobalScope[ActiveWindowKey] then
        return nil
    end
    local entry = GlobalScope[ActiveWindowKey].entryMap[flag]
    if not entry then
        return nil
    end
    return setmetatable({ entry = entry, _state = GlobalScope[ActiveWindowKey] }, ControlMethods):Get()
end

return Atlanta
