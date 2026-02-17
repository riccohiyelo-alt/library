local UserInputService = game:GetService("UserInputService")

local ESPPreviewWidget = {}
ESPPreviewWidget.__index = ESPPreviewWidget

local MOCK_FLAGS = { "HK", "SCOPED", "HIT", "DEFUSING", "FD" }
local TAG_LINE_1 = "Item Icon   Money   Box   Taser   Armor Bar"
local TAG_LINE_2 = "Flashed   Distance   Ammo"

local DEFAULT_ELEMENT = {
	Enabled = true,
	Color = Color3.fromRGB(235, 235, 235),
	Alpha = 1,
	Thickness = 1,
}

local function clampNumber(value, fallback, minValue, maxValue)
	local n = tonumber(value)
	if type(n) ~= "number" or n ~= n or n == math.huge or n == -math.huge then
		n = fallback
	end
	if type(minValue) == "number" then
		n = math.max(minValue, n)
	end
	if type(maxValue) == "number" then
		n = math.min(maxValue, n)
	end
	return n
end

local function sanitizeColor3(value, fallback)
	if typeof(value) == "Color3" then
		return value
	end
	return fallback
end

local function alphaToTransparency(alphaValue)
	local alpha = clampNumber(alphaValue, 1, 0, 1)
	return 1 - alpha
end

local function ensureElementSettings(settingsTable, key, defaults)
	local out = settingsTable[key]
	if type(out) ~= "table" then
		out = {}
		settingsTable[key] = out
	end
	local src = defaults or DEFAULT_ELEMENT
	if out.Enabled == nil then
		out.Enabled = (src.Enabled == true)
	else
		out.Enabled = (out.Enabled == true)
	end
	out.Color = sanitizeColor3(out.Color, src.Color or DEFAULT_ELEMENT.Color)
	out.Alpha = clampNumber(out.Alpha, src.Alpha or DEFAULT_ELEMENT.Alpha, 0, 1)
	out.Thickness = clampNumber(out.Thickness, src.Thickness or DEFAULT_ELEMENT.Thickness, 1, 6)
	return out
end

local function ensureOffset(settingsTable)
	local raw = settingsTable.PreviewOffset
	local x
	local y
	if typeof(raw) == "Vector2" then
		x, y = raw.X, raw.Y
	elseif type(raw) == "table" then
		x = raw.X or raw.x
		y = raw.Y or raw.y
	end
	x = clampNumber(x, 0, -72, 72)
	y = clampNumber(y, 0, -95, 95)
	settingsTable.PreviewOffset = Vector2.new(x, y)
	return settingsTable.PreviewOffset
end

local function ensureVisualSettings(settingsTable)
	settingsTable.PreviewScale = clampNumber(settingsTable.PreviewScale, 1, 0.75, 1.25)
	ensureOffset(settingsTable)
	ensureElementSettings(settingsTable, "Box", {
		Enabled = true,
		Color = Color3.fromRGB(103, 89, 179),
		Alpha = 1,
		Thickness = 1.5,
	})
	ensureElementSettings(settingsTable, "Name", {
		Enabled = true,
		Color = Color3.fromRGB(245, 245, 245),
		Alpha = 1,
	})
	ensureElementSettings(settingsTable, "Health", {
		Enabled = true,
		Color = Color3.fromRGB(64, 214, 117),
		Alpha = 1,
		Thickness = 2,
	})
	ensureElementSettings(settingsTable, "Distance", {
		Enabled = true,
		Color = Color3.fromRGB(198, 198, 198),
		Alpha = 1,
	})
	ensureElementSettings(settingsTable, "Flags", {
		Enabled = true,
		Color = Color3.fromRGB(214, 214, 214),
		Alpha = 1,
	})
	ensureElementSettings(settingsTable, "Weapon", {
		Enabled = true,
		Color = Color3.fromRGB(221, 221, 221),
		Alpha = 1,
	})
	ensureElementSettings(settingsTable, "Money", {
		Enabled = true,
		Color = Color3.fromRGB(98, 225, 104),
		Alpha = 1,
	})
	ensureElementSettings(settingsTable, "ArmorBar", {
		Enabled = true,
		Color = Color3.fromRGB(82, 145, 242),
		Alpha = 1,
		Thickness = 2,
	})
end

function ESPPreviewWidget.new(parent, settings)
	local self = setmetatable({}, ESPPreviewWidget)
	self.Parent = parent
	self.Settings = (type(settings) == "table") and settings or {}
	self._connections = {}
	self._dragging = false
	self._dragInput = nil
	self._dragStart = nil
	self._offsetStart = nil
	self._positionBase = UDim2.new(0.5, 0, 0.5, -6)
	self:Render()
	self:UpdateFromSettings()
	return self
end

function ESPPreviewWidget:_trackConnection(signal, callback)
	local conn = signal:Connect(callback)
	table.insert(self._connections, conn)
	return conn
end

function ESPPreviewWidget:_setOffset(offset)
	local x = clampNumber(offset and offset.X, 0, -72, 72)
	local y = clampNumber(offset and offset.Y, 0, -95, 95)
	local vec = Vector2.new(x, y)
	self.Settings.PreviewOffset = vec
	if self.PreviewLayer then
		self.PreviewLayer.Position = UDim2.new(
			self._positionBase.X.Scale,
			self._positionBase.X.Offset + vec.X,
			self._positionBase.Y.Scale,
			self._positionBase.Y.Offset + vec.Y
		)
	end
end

function ESPPreviewWidget:_beginDrag(inputObject)
	self._dragging = true
	self._dragInput = inputObject
	self._dragStart = inputObject.Position
	self._offsetStart = self.Settings.PreviewOffset
end

function ESPPreviewWidget:_endDrag(inputObject)
	if not self._dragging then
		return
	end
	if self._dragInput and inputObject and inputObject ~= self._dragInput then
		if inputObject.UserInputType ~= self._dragInput.UserInputType then
			return
		end
	end
	self._dragging = false
	self._dragInput = nil
	self._dragStart = nil
	self._offsetStart = nil
end

function ESPPreviewWidget:_updateDrag(inputObject)
	if not self._dragging or not self._dragInput or inputObject ~= self._dragInput then
		return
	end
	if not (self._dragStart and typeof(self._dragStart) == "Vector3") then
		return
	end
	local baseOffset = self._offsetStart
	if typeof(baseOffset) ~= "Vector2" then
		baseOffset = Vector2.new(0, 0)
	end
	local delta = inputObject.Position - self._dragStart
	self:_setOffset(Vector2.new(baseOffset.X + delta.X, baseOffset.Y + delta.Y))
end

function ESPPreviewWidget:Render()
	if self.Root and self.Root.Parent then
		return self.Root
	end

	local root = Instance.new("Frame")
	root.Name = "InteractiveESPPreviewWidget"
	root.Size = UDim2.new(1, 0, 0, 560)
	root.BackgroundTransparency = 1
	root.BorderSizePixel = 0
	root.Parent = self.Parent
	self.Root = root

	local panel = Instance.new("Frame")
	panel.Name = "Panel"
	panel.Size = UDim2.new(1, 0, 1, 0)
	panel.BackgroundColor3 = Color3.fromRGB(8, 10, 16)
	panel.BorderColor3 = Color3.fromRGB(33, 40, 54)
	panel.BorderSizePixel = 1
	panel.Parent = root
	self.Panel = panel

	local corner = Instance.new("UICorner")
	corner.CornerRadius = UDim.new(0, 6)
	corner.Parent = panel

	local topBar = Instance.new("Frame")
	topBar.Name = "TopBar"
	topBar.Size = UDim2.new(1, -18, 0, 24)
	topBar.Position = UDim2.new(0, 9, 0, 9)
	topBar.BackgroundTransparency = 1
	topBar.BorderSizePixel = 0
	topBar.Parent = panel

	local title = Instance.new("TextLabel")
	title.Name = "Title"
	title.BackgroundTransparency = 1
	title.BorderSizePixel = 0
	title.Position = UDim2.new(0, 0, 0, 0)
	title.Size = UDim2.new(1, -30, 1, 0)
	title.Font = Enum.Font.GothamMedium
	title.TextSize = 12
	title.TextXAlignment = Enum.TextXAlignment.Left
	title.TextColor3 = Color3.fromRGB(244, 244, 244)
	title.Text = "Interactive ESP Preview"
	title.Parent = topBar

	local icon = Instance.new("Frame")
	icon.Name = "TopIcon"
	icon.AnchorPoint = Vector2.new(1, 0.5)
	icon.Position = UDim2.new(1, -2, 0.5, 0)
	icon.Size = UDim2.new(0, 12, 0, 12)
	icon.BackgroundColor3 = Color3.fromRGB(26, 34, 49)
	icon.BorderColor3 = Color3.fromRGB(96, 106, 126)
	icon.BorderSizePixel = 1
	icon.Parent = topBar

	local iconCorner = Instance.new("UICorner")
	iconCorner.CornerRadius = UDim.new(1, 0)
	iconCorner.Parent = icon

	local previewArea = Instance.new("Frame")
	previewArea.Name = "PreviewArea"
	previewArea.AnchorPoint = Vector2.new(0.5, 0)
	previewArea.Position = UDim2.new(0.5, 0, 0, 40)
	previewArea.Size = UDim2.new(0, 260, 0, 360)
	previewArea.BackgroundColor3 = Color3.fromRGB(10, 12, 20)
	previewArea.BorderColor3 = Color3.fromRGB(52, 57, 70)
	previewArea.BorderSizePixel = 1
	previewArea.Active = true
	previewArea.ClipsDescendants = true
	previewArea.Parent = panel
	self.PreviewArea = previewArea

	local previewCorner = Instance.new("UICorner")
	previewCorner.CornerRadius = UDim.new(0, 6)
	previewCorner.Parent = previewArea

	local previewLayer = Instance.new("Frame")
	previewLayer.Name = "PreviewLayer"
	previewLayer.AnchorPoint = Vector2.new(0.5, 0.5)
	previewLayer.Position = self._positionBase
	previewLayer.Size = UDim2.new(1, 0, 1, 0)
	previewLayer.BackgroundTransparency = 1
	previewLayer.BorderSizePixel = 0
	previewLayer.Parent = previewArea
	self.PreviewLayer = previewLayer

	local previewScale = Instance.new("UIScale")
	previewScale.Scale = 1
	previewScale.Parent = previewLayer
	self.PreviewScaleObject = previewScale

	local pingLabel = Instance.new("TextLabel")
	pingLabel.Name = "MockPing"
	pingLabel.BackgroundTransparency = 1
	pingLabel.BorderSizePixel = 0
	pingLabel.AnchorPoint = Vector2.new(0.5, 0)
	pingLabel.Position = UDim2.new(0.5, 0, 0, 16)
	pingLabel.Size = UDim2.new(0, 120, 0, 18)
	pingLabel.Font = Enum.Font.Gotham
	pingLabel.TextSize = 10
	pingLabel.TextColor3 = Color3.fromRGB(135, 142, 154)
	pingLabel.Text = "10 ms\nneverlose.cc"
	pingLabel.Parent = previewLayer

	local mannequin = Instance.new("Frame")
	mannequin.Name = "Mannequin"
	mannequin.AnchorPoint = Vector2.new(0.5, 0.5)
	mannequin.Position = UDim2.new(0.5, 0, 0.53, 0)
	mannequin.Size = UDim2.new(0, 76, 0, 170)
	mannequin.BackgroundColor3 = Color3.fromRGB(102, 92, 191)
	mannequin.BackgroundTransparency = 0.45
	mannequin.BorderColor3 = Color3.fromRGB(136, 127, 225)
	mannequin.BorderSizePixel = 1
	mannequin.Parent = previewLayer
	self.Mannequin = mannequin

	local mannequinCorner = Instance.new("UICorner")
	mannequinCorner.CornerRadius = UDim.new(0, 4)
	mannequinCorner.Parent = mannequin

	local head = Instance.new("Frame")
	head.Name = "Head"
	head.AnchorPoint = Vector2.new(0.5, 0)
	head.Position = UDim2.new(0.5, 0, 0, -18)
	head.Size = UDim2.new(0, 34, 0, 34)
	head.BackgroundColor3 = Color3.fromRGB(112, 102, 201)
	head.BackgroundTransparency = 0.35
	head.BorderColor3 = Color3.fromRGB(145, 136, 232)
	head.BorderSizePixel = 1
	head.Parent = mannequin

	local headCorner = Instance.new("UICorner")
	headCorner.CornerRadius = UDim.new(1, 0)
	headCorner.Parent = head

	local weaponBar = Instance.new("Frame")
	weaponBar.Name = "WeaponVisual"
	weaponBar.AnchorPoint = Vector2.new(0.5, 0.5)
	weaponBar.Position = UDim2.new(0.5, 0, 0.45, 0)
	weaponBar.Size = UDim2.new(0, 96, 0, 10)
	weaponBar.Rotation = -18
	weaponBar.BackgroundColor3 = Color3.fromRGB(22, 25, 36)
	weaponBar.BorderColor3 = Color3.fromRGB(138, 141, 152)
	weaponBar.BorderSizePixel = 1
	weaponBar.Parent = mannequin

	local espBox = Instance.new("Frame")
	espBox.Name = "ESPBox"
	espBox.AnchorPoint = Vector2.new(0.5, 0.5)
	espBox.Position = mannequin.Position
	espBox.Size = UDim2.new(0, 96, 0, 208)
	espBox.BackgroundTransparency = 1
	espBox.BorderSizePixel = 0
	espBox.Parent = previewLayer
	self.BoxFrame = espBox

	local boxStroke = Instance.new("UIStroke")
	boxStroke.Thickness = 1.5
	boxStroke.Color = Color3.fromRGB(103, 89, 179)
	boxStroke.Transparency = 0
	boxStroke.Parent = espBox
	self.BoxStroke = boxStroke

	local nameLabel = Instance.new("TextLabel")
	nameLabel.Name = "Name"
	nameLabel.AnchorPoint = Vector2.new(0.5, 1)
	nameLabel.Position = UDim2.new(0.5, 0, 0.53, -112)
	nameLabel.Size = UDim2.new(0, 160, 0, 16)
	nameLabel.BackgroundTransparency = 1
	nameLabel.BorderSizePixel = 0
	nameLabel.Font = Enum.Font.GothamMedium
	nameLabel.TextSize = 12
	nameLabel.TextColor3 = Color3.fromRGB(245, 245, 245)
	nameLabel.Text = "neverpaste.cc"
	nameLabel.Parent = previewLayer
	self.NameLabel = nameLabel

	local distanceLabel = Instance.new("TextLabel")
	distanceLabel.Name = "Distance"
	distanceLabel.AnchorPoint = Vector2.new(0, 0)
	distanceLabel.Position = UDim2.new(0.5, -104, 0.53, -108)
	distanceLabel.Size = UDim2.new(0, 40, 0, 16)
	distanceLabel.BackgroundTransparency = 1
	distanceLabel.BorderSizePixel = 0
	distanceLabel.Font = Enum.Font.Gotham
	distanceLabel.TextSize = 11
	distanceLabel.TextColor3 = Color3.fromRGB(192, 192, 192)
	distanceLabel.TextXAlignment = Enum.TextXAlignment.Left
	distanceLabel.Text = "100"
	distanceLabel.Parent = previewLayer
	self.DistanceLabel = distanceLabel

	local healthBack = Instance.new("Frame")
	healthBack.Name = "HealthBack"
	healthBack.AnchorPoint = Vector2.new(1, 0)
	healthBack.Position = UDim2.new(0.5, -53, 0.53, -104)
	healthBack.Size = UDim2.new(0, 4, 0, 200)
	healthBack.BackgroundColor3 = Color3.fromRGB(26, 26, 26)
	healthBack.BorderSizePixel = 0
	healthBack.Parent = previewLayer
	self.HealthBack = healthBack

	local healthFill = Instance.new("Frame")
	healthFill.Name = "HealthFill"
	healthFill.AnchorPoint = Vector2.new(0, 1)
	healthFill.Position = UDim2.new(0, 0, 1, 0)
	healthFill.Size = UDim2.new(1, 0, 0.78, 0)
	healthFill.BackgroundColor3 = Color3.fromRGB(64, 214, 117)
	healthFill.BorderSizePixel = 0
	healthFill.Parent = healthBack
	self.HealthFill = healthFill

	local armorBack = Instance.new("Frame")
	armorBack.Name = "ArmorBack"
	armorBack.AnchorPoint = Vector2.new(0, 0)
	armorBack.Position = UDim2.new(0.5, 53, 0.53, -104)
	armorBack.Size = UDim2.new(0, 4, 0, 200)
	armorBack.BackgroundColor3 = Color3.fromRGB(26, 26, 26)
	armorBack.BorderSizePixel = 0
	armorBack.Parent = previewLayer
	self.ArmorBack = armorBack

	local armorFill = Instance.new("Frame")
	armorFill.Name = "ArmorFill"
	armorFill.AnchorPoint = Vector2.new(0, 1)
	armorFill.Position = UDim2.new(0, 0, 1, 0)
	armorFill.Size = UDim2.new(1, 0, 0.62, 0)
	armorFill.BackgroundColor3 = Color3.fromRGB(82, 145, 242)
	armorFill.BorderSizePixel = 0
	armorFill.Parent = armorBack
	self.ArmorFill = armorFill

	local flagsHolder = Instance.new("Frame")
	flagsHolder.Name = "FlagsHolder"
	flagsHolder.AnchorPoint = Vector2.new(0, 0)
	flagsHolder.Position = UDim2.new(0.5, 64, 0.53, -72)
	flagsHolder.Size = UDim2.new(0, 88, 0, 106)
	flagsHolder.BackgroundTransparency = 1
	flagsHolder.BorderSizePixel = 0
	flagsHolder.Parent = previewLayer
	self.FlagsHolder = flagsHolder

	local flagsLayout = Instance.new("UIListLayout")
	flagsLayout.Padding = UDim.new(0, 2)
	flagsLayout.FillDirection = Enum.FillDirection.Vertical
	flagsLayout.HorizontalAlignment = Enum.HorizontalAlignment.Left
	flagsLayout.SortOrder = Enum.SortOrder.LayoutOrder
	flagsLayout.Parent = flagsHolder

	self.FlagLabels = {}
	for i = 1, #MOCK_FLAGS do
		local flagLabel = Instance.new("TextLabel")
		flagLabel.Name = "Flag_" .. tostring(i)
		flagLabel.Size = UDim2.new(1, 0, 0, 14)
		flagLabel.BackgroundTransparency = 1
		flagLabel.BorderSizePixel = 0
		flagLabel.Font = Enum.Font.GothamBold
		flagLabel.TextSize = 10
		flagLabel.TextXAlignment = Enum.TextXAlignment.Left
		flagLabel.TextColor3 = Color3.fromRGB(214, 214, 214)
		flagLabel.Text = MOCK_FLAGS[i]
		flagLabel.Parent = flagsHolder
		table.insert(self.FlagLabels, flagLabel)
	end

	local moneyLabel = Instance.new("TextLabel")
	moneyLabel.Name = "Money"
	moneyLabel.AnchorPoint = Vector2.new(0.5, 0)
	moneyLabel.Position = UDim2.new(0.5, 0, 0.53, 109)
	moneyLabel.Size = UDim2.new(0, 120, 0, 14)
	moneyLabel.BackgroundTransparency = 1
	moneyLabel.BorderSizePixel = 0
	moneyLabel.Font = Enum.Font.Gotham
	moneyLabel.TextSize = 11
	moneyLabel.TextColor3 = Color3.fromRGB(98, 225, 104)
	moneyLabel.Text = "$12300"
	moneyLabel.Parent = previewLayer
	self.MoneyLabel = moneyLabel

	local weaponLabel = Instance.new("TextLabel")
	weaponLabel.Name = "Weapon"
	weaponLabel.AnchorPoint = Vector2.new(0.5, 0)
	weaponLabel.Position = UDim2.new(0.5, 0, 0.53, 123)
	weaponLabel.Size = UDim2.new(0, 120, 0, 14)
	weaponLabel.BackgroundTransparency = 1
	weaponLabel.BorderSizePixel = 0
	weaponLabel.Font = Enum.Font.Gotham
	weaponLabel.TextSize = 11
	weaponLabel.TextColor3 = Color3.fromRGB(220, 220, 220)
	weaponLabel.Text = "AK-47"
	weaponLabel.Parent = previewLayer
	self.WeaponLabel = weaponLabel

	local itemIcon = Instance.new("Frame")
	itemIcon.Name = "ItemIcon"
	itemIcon.AnchorPoint = Vector2.new(0.5, 0)
	itemIcon.Position = UDim2.new(0.5, 0, 0.53, 140)
	itemIcon.Size = UDim2.new(0, 22, 0, 22)
	itemIcon.BackgroundColor3 = Color3.fromRGB(36, 40, 53)
	itemIcon.BorderColor3 = Color3.fromRGB(115, 121, 138)
	itemIcon.BorderSizePixel = 1
	itemIcon.Parent = previewLayer
	self.ItemIcon = itemIcon

	local itemIconCorner = Instance.new("UICorner")
	itemIconCorner.CornerRadius = UDim.new(0, 3)
	itemIconCorner.Parent = itemIcon

	local itemIconMark = Instance.new("TextLabel")
	itemIconMark.Name = "Mark"
	itemIconMark.Size = UDim2.new(1, 0, 1, 0)
	itemIconMark.BackgroundTransparency = 1
	itemIconMark.BorderSizePixel = 0
	itemIconMark.Font = Enum.Font.GothamBold
	itemIconMark.TextSize = 10
	itemIconMark.TextColor3 = Color3.fromRGB(210, 214, 228)
	itemIconMark.Text = "I"
	itemIconMark.Parent = itemIcon

	local bottomTitle = Instance.new("TextLabel")
	bottomTitle.Name = "BottomTitle"
	bottomTitle.AnchorPoint = Vector2.new(0, 0)
	bottomTitle.Position = UDim2.new(0, 14, 0, 414)
	bottomTitle.Size = UDim2.new(1, -20, 0, 16)
	bottomTitle.BackgroundTransparency = 1
	bottomTitle.BorderSizePixel = 0
	bottomTitle.Font = Enum.Font.GothamBold
	bottomTitle.TextSize = 12
	bottomTitle.TextXAlignment = Enum.TextXAlignment.Left
	bottomTitle.TextColor3 = Color3.fromRGB(233, 233, 233)
	bottomTitle.Text = "Drag & Drop Elements"
	bottomTitle.Parent = panel

	local tagsLine1 = Instance.new("TextLabel")
	tagsLine1.Name = "TagLine1"
	tagsLine1.AnchorPoint = Vector2.new(0, 0)
	tagsLine1.Position = UDim2.new(0, 14, 0, 436)
	tagsLine1.Size = UDim2.new(1, -20, 0, 16)
	tagsLine1.BackgroundTransparency = 1
	tagsLine1.BorderSizePixel = 0
	tagsLine1.Font = Enum.Font.Gotham
	tagsLine1.TextSize = 11
	tagsLine1.TextXAlignment = Enum.TextXAlignment.Left
	tagsLine1.TextColor3 = Color3.fromRGB(175, 175, 175)
	tagsLine1.Text = TAG_LINE_1
	tagsLine1.Parent = panel

	local tagsLine2 = Instance.new("TextLabel")
	tagsLine2.Name = "TagLine2"
	tagsLine2.AnchorPoint = Vector2.new(0, 0)
	tagsLine2.Position = UDim2.new(0, 14, 0, 455)
	tagsLine2.Size = UDim2.new(1, -20, 0, 16)
	tagsLine2.BackgroundTransparency = 1
	tagsLine2.BorderSizePixel = 0
	tagsLine2.Font = Enum.Font.Gotham
	tagsLine2.TextSize = 11
	tagsLine2.TextXAlignment = Enum.TextXAlignment.Left
	tagsLine2.TextColor3 = Color3.fromRGB(175, 175, 175)
	tagsLine2.Text = TAG_LINE_2
	tagsLine2.Parent = panel

	self:_trackConnection(previewArea.InputBegan, function(inputObject)
		local userInputType = inputObject.UserInputType
		if userInputType == Enum.UserInputType.MouseButton1 or userInputType == Enum.UserInputType.Touch then
			self:_beginDrag(inputObject)
		end
	end)

	self:_trackConnection(previewArea.InputEnded, function(inputObject)
		local userInputType = inputObject.UserInputType
		if userInputType == Enum.UserInputType.MouseButton1 or userInputType == Enum.UserInputType.Touch then
			self:_endDrag(inputObject)
		end
	end)

	self:_trackConnection(UserInputService.InputChanged, function(inputObject)
		if inputObject.UserInputType == Enum.UserInputType.MouseMovement or inputObject.UserInputType == Enum.UserInputType.Touch then
			self:_updateDrag(inputObject)
		end
	end)

	self:_trackConnection(UserInputService.InputEnded, function(inputObject)
		if inputObject.UserInputType == Enum.UserInputType.Touch or inputObject.UserInputType == Enum.UserInputType.MouseButton1 then
			self:_endDrag(inputObject)
		end
	end)

	return root
end

function ESPPreviewWidget:UpdateFromSettings()
	if not self.Root then
		return
	end
	ensureVisualSettings(self.Settings)

	local settings = self.Settings
	local box = settings.Box
	local name = settings.Name
	local health = settings.Health
	local distance = settings.Distance
	local flags = settings.Flags
	local weapon = settings.Weapon
	local money = settings.Money
	local armor = settings.ArmorBar

	if self.PreviewScaleObject then
		self.PreviewScaleObject.Scale = clampNumber(settings.PreviewScale, 1, 0.75, 1.25)
	end
	self:_setOffset(settings.PreviewOffset)

	if self.BoxFrame and self.BoxStroke then
		self.BoxFrame.Visible = (box.Enabled == true)
		self.BoxStroke.Color = sanitizeColor3(box.Color, DEFAULT_ELEMENT.Color)
		self.BoxStroke.Thickness = clampNumber(box.Thickness, 1.5, 1, 6)
		self.BoxStroke.Transparency = alphaToTransparency(box.Alpha)
	end

	if self.NameLabel then
		self.NameLabel.Visible = (name.Enabled == true)
		self.NameLabel.TextColor3 = sanitizeColor3(name.Color, DEFAULT_ELEMENT.Color)
		self.NameLabel.TextTransparency = alphaToTransparency(name.Alpha)
	end

	if self.HealthBack and self.HealthFill then
		local visible = (health.Enabled == true)
		self.HealthBack.Visible = visible
		self.HealthFill.Visible = visible
		self.HealthFill.BackgroundColor3 = sanitizeColor3(health.Color, Color3.fromRGB(64, 214, 117))
		self.HealthFill.BackgroundTransparency = alphaToTransparency(health.Alpha)
		self.HealthBack.Size = UDim2.new(0, clampNumber(health.Thickness, 2, 1, 6), 0, 200)
	end

	if self.DistanceLabel then
		self.DistanceLabel.Visible = (distance.Enabled == true)
		self.DistanceLabel.TextColor3 = sanitizeColor3(distance.Color, DEFAULT_ELEMENT.Color)
		self.DistanceLabel.TextTransparency = alphaToTransparency(distance.Alpha)
	end

	local flagsVisible = (flags.Enabled == true)
	if self.FlagsHolder then
		self.FlagsHolder.Visible = flagsVisible
	end
	for i = 1, #(self.FlagLabels or {}) do
		local flagLabel = self.FlagLabels[i]
		if flagLabel then
			flagLabel.Visible = flagsVisible
			flagLabel.TextColor3 = sanitizeColor3(flags.Color, DEFAULT_ELEMENT.Color)
			flagLabel.TextTransparency = alphaToTransparency(flags.Alpha)
		end
	end

	if self.WeaponLabel then
		self.WeaponLabel.Visible = (weapon.Enabled == true)
		self.WeaponLabel.TextColor3 = sanitizeColor3(weapon.Color, DEFAULT_ELEMENT.Color)
		self.WeaponLabel.TextTransparency = alphaToTransparency(weapon.Alpha)
	end

	if self.MoneyLabel then
		self.MoneyLabel.Visible = (money.Enabled == true)
		self.MoneyLabel.TextColor3 = sanitizeColor3(money.Color, Color3.fromRGB(98, 225, 104))
		self.MoneyLabel.TextTransparency = alphaToTransparency(money.Alpha)
	end

	if self.ItemIcon then
		local iconVisible = (weapon.Enabled == true or money.Enabled == true)
		self.ItemIcon.Visible = iconVisible
		self.ItemIcon.BackgroundTransparency = alphaToTransparency(math.min(weapon.Alpha, money.Alpha))
	end

	if self.ArmorBack and self.ArmorFill then
		local visible = (armor.Enabled == true)
		self.ArmorBack.Visible = visible
		self.ArmorFill.Visible = visible
		self.ArmorFill.BackgroundColor3 = sanitizeColor3(armor.Color, Color3.fromRGB(82, 145, 242))
		self.ArmorFill.BackgroundTransparency = alphaToTransparency(armor.Alpha)
		self.ArmorBack.Size = UDim2.new(0, clampNumber(armor.Thickness, 2, 1, 6), 0, 200)
	end
end

function ESPPreviewWidget:Reset()
	self.Settings.PreviewScale = 1
	self.Settings.PreviewOffset = Vector2.new(0, 0)
	self:UpdateFromSettings()
end

return ESPPreviewWidget
