-- UI VISUAL TEST ONLY - PC/Mobile GUI
-- Parte 1/3

local Players = game:GetService("Players")
local LocalPlayer = Players.LocalPlayer
local PlayerGui = LocalPlayer:WaitForChild("PlayerGui")
local TweenService = game:GetService("TweenService")
local UserInputService = game:GetService("UserInputService")
local GuiService = game:GetService("GuiService")
local RunService = game:GetService("RunService")

local selectedMode = nil

local DEFAULT_HIDE_GUI_KEY = Enum.KeyCode.RightShift
local DEFAULT_TOGGLE_SCRIPT_KEY = Enum.KeyCode.Q
local DEFAULT_TOGGLE_BEAST_SLOW_KEY = Enum.KeyCode.E

local hideGuiKey = DEFAULT_HIDE_GUI_KEY
local toggleScriptKey = DEFAULT_TOGGLE_SCRIPT_KEY
local toggleBeastSlowKey = DEFAULT_TOGGLE_BEAST_SLOW_KEY

local waitingForHideKey = false
local waitingForToggleKey = false
local waitingForBeastSlowKey = false

local guiVisible = true
local guiMinimized = false
local mobileMenuOpen = false
local mobileWallhopGuiHidden = false

local fakeWallhopEnabled = false
local fakeSlowEnabled = false

local ScreenGui
local MainFrame
local MiniButton
local MobileButton
local MobileMenuButton
local MobilePanel
local MobileBeastSlowRow
local MobileHideGuiRow
local ToggleButton
local HideGuiBindButton
local ToggleBindButton
local BeastSlowBindButton
local Notice
local NoticeStroke
local MoveGuiButton
local ResizeGuiButton

local mobileBeastSlowSwitch
local mobileBeastSlowKnob
local mobileHideGuiSwitch
local mobileHideGuiKnob

local dragConnections = {}
local shadowRegistry = {}

local function destroyOld()
	for _, name in ipairs({
		"AutoWallHopGui",
		"AutoWallHopGuiMobile",
		"WallhopModeSelector"
	}) do
		local old = PlayerGui:FindFirstChild(name)
		if old then
			old:Destroy()
		end
	end
end

destroyOld()

local function noTextStroke(obj)
	obj.TextStrokeTransparency = 1
end

local function registerShadow(host, shadow)
	shadowRegistry[host] = shadowRegistry[host] or {}
	table.insert(shadowRegistry[host], shadow)
end

local function setHostShadowVisible(host, visible)
	local list = shadowRegistry[host]
	if not list then return end

	for _, shadow in ipairs(list) do
		shadow.Visible = visible
		shadow.BackgroundTransparency = visible and shadow:GetAttribute("BaseTransparency") or 1
	end
end

local function addTrueRoundedShadow(parent, cornerRadius, strength, shadowColor)
	strength = strength or 1
	shadowColor = shadowColor or Color3.fromRGB(0, 0, 0)

	local layers = {
		{grow = math.floor(6 * strength), transparency = 0.84, y = 1},
		{grow = math.floor(12 * strength), transparency = 0.90, y = 2},
		{grow = math.floor(18 * strength), transparency = 0.95, y = 3},
	}

	for _, cfg in ipairs(layers) do
		local shadow = Instance.new("Frame")
		shadow.Name = "TrueShadow"
		shadow.AnchorPoint = Vector2.new(0.5, 0.5)
		shadow.Position = UDim2.new(0.5, 0, 0.5, cfg.y)
		shadow.Size = UDim2.new(1, cfg.grow, 1, cfg.grow)
		shadow.BackgroundColor3 = shadowColor
		shadow.BackgroundTransparency = cfg.transparency
		shadow.BorderSizePixel = 0
		shadow.ZIndex = math.max(parent.ZIndex - 1, 0)
		shadow.Parent = parent
		shadow:SetAttribute("BaseTransparency", cfg.transparency)

		Instance.new("UICorner", shadow).CornerRadius =
			UDim.new(0, cornerRadius + math.floor(cfg.grow / 2.2))

		registerShadow(parent, shadow)
	end
end

local function setGroupTransparency(root, bgT, textT)
	for _, obj in ipairs(root:GetDescendants()) do
		if obj:IsA("Frame") or obj:IsA("TextButton") or obj:IsA("TextLabel") then
			pcall(function()
				obj.BackgroundTransparency = bgT
			end)
		end

		if obj:IsA("TextButton") or obj:IsA("TextLabel") then
			pcall(function()
				obj.TextTransparency = textT
			end)
		end

		if obj:IsA("UIStroke") then
			pcall(function()
				obj.Transparency = math.clamp(bgT, 0, 1)
			end)
		end
	end
end

local function elegantShow(root, finalSize, finalPosition, finalBgTransparency)
	if not root then return end

	root.Visible = true

	local targetSize = finalSize or root.Size
	local targetPos = finalPosition or root.Position
	local targetBg = finalBgTransparency
	if targetBg == nil then
		targetBg = root.BackgroundTransparency
	end

	root.Size = UDim2.new(
		targetSize.X.Scale * 0.72, math.floor(targetSize.X.Offset * 0.72),
		targetSize.Y.Scale * 0.72, math.floor(targetSize.Y.Offset * 0.72)
	)
	root.Position = targetPos
	root.BackgroundTransparency = 1
	setGroupTransparency(root, 1, 1)
	setHostShadowVisible(root, false)

	TweenService:Create(root, TweenInfo.new(0.22, Enum.EasingStyle.Quart, Enum.EasingDirection.Out), {
		Size = targetSize,
		Position = targetPos,
		BackgroundTransparency = targetBg
	}):Play()

	task.delay(0.03, function()
		setHostShadowVisible(root, true)

		for _, obj in ipairs(root:GetDescendants()) do
			if obj:IsA("Frame") or obj:IsA("TextButton") or obj:IsA("TextLabel") then
				local goal = {}
				if obj:IsA("Frame") or obj:IsA("TextButton") then
					goal.BackgroundTransparency = 0
				end
				if obj:IsA("TextButton") or obj:IsA("TextLabel") then
					goal.TextTransparency = 0
				end
				TweenService:Create(obj, TweenInfo.new(0.2, Enum.EasingStyle.Quad, Enum.EasingDirection.Out), goal):Play()
			elseif obj:IsA("UIStroke") then
				TweenService:Create(obj, TweenInfo.new(0.2, Enum.EasingStyle.Quad, Enum.EasingDirection.Out), {
					Transparency = 0
				}):Play()
			end
		end
	end)
end

local function elegantHide(root, onDone)
	if not root then
		if onDone then onDone() end
		return
	end

	local currentSize = root.Size
	local shrinkSize = UDim2.new(
		currentSize.X.Scale * 0.76, math.floor(currentSize.X.Offset * 0.76),
		currentSize.Y.Scale * 0.76, math.floor(currentSize.Y.Offset * 0.76)
	)

	for _, obj in ipairs(root:GetDescendants()) do
		if obj:IsA("Frame") or obj:IsA("TextButton") or obj:IsA("TextLabel") then
			local goal = {}
			if obj:IsA("Frame") or obj:IsA("TextButton") then
				goal.BackgroundTransparency = 1
			end
			if obj:IsA("TextButton") or obj:IsA("TextLabel") then
				goal.TextTransparency = 1
			end
			TweenService:Create(obj, TweenInfo.new(0.14, Enum.EasingStyle.Quad, Enum.EasingDirection.In), goal):Play()
		elseif obj:IsA("UIStroke") then
			TweenService:Create(obj, TweenInfo.new(0.14, Enum.EasingStyle.Quad, Enum.EasingDirection.In), {
				Transparency = 1
			}):Play()
		end
	end

	setHostShadowVisible(root, false)

	local tween = TweenService:Create(root, TweenInfo.new(0.18, Enum.EasingStyle.Quart, Enum.EasingDirection.In), {
		Size = shrinkSize,
		BackgroundTransparency = 1
	})
	tween:Play()
	tween.Completed:Connect(function()
		root.Visible = false
		if onDone then onDone() end
	end)
end

local activeNoticeId = 0
local function showNotice(text)
	if selectedMode ~= "PC" or not Notice or not NoticeStroke then
		return
	end

	activeNoticeId += 1
	local noticeId = activeNoticeId

	Notice.Text = text
	Notice.Visible = true
	Notice.AnchorPoint = Vector2.new(1, 0)
	Notice.Position = UDim2.new(1, -14, 0, 14)
	Notice.Size = UDim2.new(0, 200, 0, 26)
	Notice.BackgroundTransparency = 0.08
	Notice.TextTransparency = 0
	NoticeStroke.Transparency = 0.9

	task.spawn(function()
		task.wait(1)
		if noticeId ~= activeNoticeId then
			return
		end

		Notice.Visible = false
	end)
end

local function updateSwitchVisual(switchFrame, knob, enabled)
	if not switchFrame or not knob then return end

	local offPos = UDim2.new(0, 3, 0.5, -13)
	local onPos = UDim2.new(1, -29, 0.5, -13)

	TweenService:Create(switchFrame, TweenInfo.new(0.16, Enum.EasingStyle.Quad, Enum.EasingDirection.Out), {
		BackgroundColor3 = enabled and Color3.fromRGB(190,190,190) or Color3.fromRGB(20,20,24)
	}):Play()

	TweenService:Create(knob, TweenInfo.new(0.16, Enum.EasingStyle.Quad, Enum.EasingDirection.Out), {
		Position = enabled and onPos or offPos,
		BackgroundColor3 = enabled and Color3.fromRGB(255,255,255) or Color3.fromRGB(0,0,0)
	}):Play()
end

local function createSwitchRow(parent, yOffset, labelText)
	local row = Instance.new("TextButton")
	row.Size = UDim2.new(1, -14, 0, 40)
	row.Position = UDim2.new(0, 7, 0, yOffset)
	row.BackgroundColor3 = Color3.fromRGB(0, 0, 0)
	row.AutoButtonColor = false
	row.Text = ""
	row.BorderSizePixel = 0
	row.Parent = parent
	Instance.new("UICorner", row).CornerRadius = UDim.new(0, 12)

	local label = Instance.new("TextLabel")
	label.Name = "Label"
	label.Size = UDim2.new(0, 88, 1, 0)
	label.Position = UDim2.new(0, 12, 0, 0)
	label.BackgroundTransparency = 1
	label.Text = labelText
	label.TextColor3 = Color3.fromRGB(255,255,255)
	label.Font = Enum.Font.GothamBold
	label.TextSize = 13
	label.TextXAlignment = Enum.TextXAlignment.Left
	label.Parent = row
	noTextStroke(label)

	local switch = Instance.new("Frame")
	switch.Size = UDim2.new(0, 54, 0, 28)
	switch.Position = UDim2.new(1, -66, 0.5, -14)
	switch.BackgroundColor3 = Color3.fromRGB(20,20,24)
	switch.BorderSizePixel = 0
	switch.Parent = row
	Instance.new("UICorner", switch).CornerRadius = UDim.new(1, 0)

	local knob = Instance.new("Frame")
	knob.Size = UDim2.new(0, 26, 0, 26)
	knob.Position = UDim2.new(0, 3, 0.5, -13)
	knob.BackgroundColor3 = Color3.fromRGB(0,0,0)
	knob.BorderSizePixel = 0
	knob.Parent = switch
	Instance.new("UICorner", knob).CornerRadius = UDim.new(1, 0)

	return row, switch, knob
end

local function updateToggleButton()
	if selectedMode == "PC" and ToggleButton then
		ToggleButton.Text = fakeWallhopEnabled and "Wall Hop On" or "Wall Hop Off"
	elseif selectedMode == "Mobile" and MobileButton then
		MobileButton.Text = fakeWallhopEnabled and "Wallhop On" or "Wallhop Off"
	end
end

local function setMobileWallhopVisualHidden(hidden)
	if not MobileButton then return end

	MobileButton.BackgroundTransparency = hidden and 1 or 0
	MobileButton.TextTransparency = hidden and 1 or 0
	setHostShadowVisible(MobileButton, not hidden)
end

local function updateMobilePanelButtons()
	if MobileBeastSlowRow and MobileBeastSlowRow:FindFirstChild("Label") then
		MobileBeastSlowRow.Label.Text = "Beast Slow"
	end
	if MobileHideGuiRow and MobileHideGuiRow:FindFirstChild("Label") then
		MobileHideGuiRow.Label.Text = "Hide GUI"
	end

	updateSwitchVisual(mobileBeastSlowSwitch, mobileBeastSlowKnob, fakeSlowEnabled)
	updateSwitchVisual(mobileHideGuiSwitch, mobileHideGuiKnob, mobileWallhopGuiHidden)
	setMobileWallhopVisualHidden(mobileWallhopGuiHidden)
end

local function updateBindButtons()
	if selectedMode ~= "PC" then
		return
	end

	if HideGuiBindButton then
		HideGuiBindButton.Text = waitingForHideKey and "Press any key..." or ("Keybind Hide GUI: " .. hideGuiKey.Name)
	end
	if ToggleBindButton then
		ToggleBindButton.Text = waitingForToggleKey and "Press any key..." or ("Keybind Toggle Wallhop: " .. toggleScriptKey.Name)
	end
	if BeastSlowBindButton then
		BeastSlowBindButton.Text = waitingForBeastSlowKey and "Press any key..." or ("Keybind Toggle Beast Slow: " .. toggleBeastSlowKey.Name)
	end
end

local function applyVisibility()
	if selectedMode == "PC" then
		if MainFrame then
			MainFrame.Visible = guiVisible and not guiMinimized
			setHostShadowVisible(MainFrame, guiVisible and not guiMinimized)
		end
		if MiniButton then
			MiniButton.Visible = guiVisible and guiMinimized
			setHostShadowVisible(MiniButton, guiVisible and guiMinimized)
		end
	elseif selectedMode == "Mobile" then
		if MobileButton then
			MobileButton.Visible = guiVisible
		end
		if MobileMenuButton then
			MobileMenuButton.Visible = true
		end
		if MobilePanel then
			MobilePanel.Visible = mobileMenuOpen
			setHostShadowVisible(MobilePanel, mobileMenuOpen)
		end
		setMobileWallhopVisualHidden(mobileWallhopGuiHidden)
	end
end

local function setGuiVisible(state)
	guiVisible = state
	applyVisibility()
	showNotice(state and "GUI shown" or "GUI hidden")
end
-- Parte 2/3

local function createModeSelector(onPick)
	local selectorGui = Instance.new("ScreenGui")
	selectorGui.Name = "WallhopModeSelector"
	selectorGui.ResetOnSpawn = false
	selectorGui.ZIndexBehavior = Enum.ZIndexBehavior.Sibling
	selectorGui.Parent = PlayerGui

	local frame = Instance.new("Frame")
	frame.Size = UDim2.new(0, 280, 0, 170)
	frame.Position = UDim2.new(0.5, 0, 0.5, 0)
	frame.AnchorPoint = Vector2.new(0.5, 0.5)
	frame.BackgroundColor3 = Color3.fromRGB(0, 0, 0)
	frame.BorderSizePixel = 0
	frame.Parent = selectorGui
	Instance.new("UICorner", frame).CornerRadius = UDim.new(0, 16)
	addTrueRoundedShadow(frame, 16, 1.45, Color3.fromRGB(0, 0, 0))

	local title = Instance.new("TextLabel")
	title.Size = UDim2.new(1, -20, 0, 28)
	title.Position = UDim2.new(0, 10, 0, 10)
	title.BackgroundTransparency = 1
	title.Text = "Choose Version"
	title.TextColor3 = Color3.fromRGB(255,255,255)
	title.Font = Enum.Font.GothamBold
	title.TextSize = 22
	title.Parent = frame
	noTextStroke(title)

	local sub = Instance.new("TextLabel")
	sub.Size = UDim2.new(1, -20, 0, 16)
	sub.Position = UDim2.new(0, 10, 0, 34)
	sub.BackgroundTransparency = 1
	sub.Text = "FtF Wallhop • visual test"
	sub.TextColor3 = Color3.fromRGB(95,95,95)
	sub.Font = Enum.Font.Gotham
	sub.TextSize = 12
	sub.Parent = frame
	noTextStroke(sub)

	local pcButton = Instance.new("TextButton")
	pcButton.Size = UDim2.new(1, -20, 0, 42)
	pcButton.Position = UDim2.new(0, 10, 0, 68)
	pcButton.BackgroundColor3 = Color3.fromRGB(3, 3, 3)
	pcButton.Text = "PC Version"
	pcButton.TextColor3 = Color3.fromRGB(255,255,255)
	pcButton.Font = Enum.Font.GothamBold
	pcButton.TextSize = 17
	pcButton.Parent = frame
	Instance.new("UICorner", pcButton).CornerRadius = UDim.new(0, 12)
	noTextStroke(pcButton)

	local mobileButton = Instance.new("TextButton")
	mobileButton.Size = UDim2.new(1, -20, 0, 42)
	mobileButton.Position = UDim2.new(0, 10, 0, 116)
	mobileButton.BackgroundColor3 = Color3.fromRGB(3, 3, 3)
	mobileButton.Text = "Mobile Version"
	mobileButton.TextColor3 = Color3.fromRGB(255,255,255)
	mobileButton.Font = Enum.Font.GothamBold
	mobileButton.TextSize = 17
	mobileButton.Parent = frame
	Instance.new("UICorner", mobileButton).CornerRadius = UDim.new(0, 12)
	noTextStroke(mobileButton)

	elegantShow(frame, UDim2.new(0, 280, 0, 170), UDim2.new(0.5, 0, 0.5, 0), 0)

	pcButton.MouseButton1Click:Connect(function()
		elegantHide(frame, function()
			selectorGui:Destroy()
			onPick("PC")
		end)
	end)

	mobileButton.MouseButton1Click:Connect(function()
		elegantHide(frame, function()
			selectorGui:Destroy()
			onPick("Mobile")
		end)
	end)
end

local function clearOldDragConnections()
	for _, c in ipairs(dragConnections) do
		if c and c.Disconnect then
			c:Disconnect()
		end
	end
	table.clear(dragConnections)
end

local function bindFreeTouchDrag(dragObject, target, onMove)
	local activeInput = nil
	local dragStart = nil
	local startPos = nil

	table.insert(dragConnections, dragObject.InputBegan:Connect(function(input)
		if input.UserInputType == Enum.UserInputType.Touch or input.UserInputType == Enum.UserInputType.MouseButton1 then
			activeInput = input
			dragStart = input.Position
			startPos = target.Position
		end
	end))

	table.insert(dragConnections, UserInputService.InputChanged:Connect(function(input)
		if input == activeInput and dragStart and startPos then
			local delta = input.Position - dragStart
			target.Position = UDim2.new(
				startPos.X.Scale,
				startPos.X.Offset + delta.X,
				startPos.Y.Scale,
				startPos.Y.Offset + delta.Y
			)

			if onMove then
				onMove()
			end
		end
	end))

	table.insert(dragConnections, UserInputService.InputEnded:Connect(function(input)
		if input == activeInput then
			activeInput = nil
			dragStart = nil
			startPos = nil
		end
	end))
end

local function buildMobileGui()
	clearOldDragConnections()

	ScreenGui = Instance.new("ScreenGui")
	ScreenGui.Name = "AutoWallHopGuiMobile"
	ScreenGui.ResetOnSpawn = false
	ScreenGui.ZIndexBehavior = Enum.ZIndexBehavior.Sibling
	ScreenGui.Parent = PlayerGui

	MobileButton = Instance.new("TextButton")
	MobileButton.Size = UDim2.new(0, 140, 0, 50)
	MobileButton.BackgroundColor3 = Color3.fromRGB(0, 0, 0)
	MobileButton.Text = "Wallhop Off"
	MobileButton.TextColor3 = Color3.fromRGB(255,255,255)
	MobileButton.Font = Enum.Font.GothamBold
	MobileButton.TextScaled = true
	MobileButton.Parent = ScreenGui
	Instance.new("UICorner", MobileButton).CornerRadius = UDim.new(0, 12)
	noTextStroke(MobileButton)
	addTrueRoundedShadow(MobileButton, 14, 1, Color3.fromRGB(0, 0, 0))

	MobileMenuButton = Instance.new("TextButton")
	MobileMenuButton.Size = UDim2.new(0, 54, 0, 54)
	MobileMenuButton.Position = UDim2.new(0, 20, 0, 180)
	MobileMenuButton.BackgroundColor3 = Color3.fromRGB(0, 0, 0)
	MobileMenuButton.Text = "≡"
	MobileMenuButton.TextColor3 = Color3.fromRGB(255,255,255)
	MobileMenuButton.Font = Enum.Font.GothamBold
	MobileMenuButton.TextSize = 22
	MobileMenuButton.Parent = ScreenGui
	Instance.new("UICorner", MobileMenuButton).CornerRadius = UDim.new(1, 0)
	noTextStroke(MobileMenuButton)
	addTrueRoundedShadow(MobileMenuButton, 999, 1, Color3.fromRGB(0, 0, 0))

	MobilePanel = Instance.new("Frame")
	MobilePanel.Size = UDim2.new(0, 170, 0, 94)
	MobilePanel.BackgroundColor3 = Color3.fromRGB(0, 0, 0)
	MobilePanel.BorderSizePixel = 0
	MobilePanel.Visible = false
	MobilePanel.Parent = ScreenGui
	Instance.new("UICorner", MobilePanel).CornerRadius = UDim.new(0, 14)
	addTrueRoundedShadow(MobilePanel, 14, 1, Color3.fromRGB(0, 0, 0))

	MobileBeastSlowRow, mobileBeastSlowSwitch, mobileBeastSlowKnob = createSwitchRow(MobilePanel, 7, "Beast Slow")
	MobileHideGuiRow, mobileHideGuiSwitch, mobileHideGuiKnob = createSwitchRow(MobilePanel, 47, "Hide GUI")

	local function placeMobileButtonDefault()
		local inset = GuiService:GetGuiInset()
		if not MobileButton:GetAttribute("CustomMoved") then
			MobileButton.Position = UDim2.new(0, 150, 0, inset.Y - 58)
		end
	end

	local function placePanelToRightOfWallhop()
		local xOffset = MobileButton.Position.X.Offset + MobileButton.Size.X.Offset + 26
		local yOffset = MobileButton.Position.Y.Offset
		MobilePanel.Position = UDim2.new(0, xOffset, 0, yOffset)
	end

	RunService.RenderStepped:Connect(function()
		if selectedMode ~= "Mobile" then return end
		placeMobileButtonDefault()

		if mobileMenuOpen and not MobilePanel:GetAttribute("CustomMoved") then
			placePanelToRightOfWallhop()
		end
	end)

	placeMobileButtonDefault()
	placePanelToRightOfWallhop()

	bindFreeTouchDrag(MobileButton, MobileButton, function()
		MobileButton:SetAttribute("CustomMoved", true)
		if not MobilePanel:GetAttribute("CustomMoved") then
			placePanelToRightOfWallhop()
		end
	end)

	bindFreeTouchDrag(MobileMenuButton, MobileMenuButton)
	bindFreeTouchDrag(MobilePanel, MobilePanel, function()
		MobilePanel:SetAttribute("CustomMoved", true)
	end)

	MobileButton.MouseButton1Click:Connect(function()
		fakeWallhopEnabled = not fakeWallhopEnabled
		updateToggleButton()
	end)

	MobileMenuButton.MouseButton1Click:Connect(function()
		mobileMenuOpen = not mobileMenuOpen

		if mobileMenuOpen then
			if not MobilePanel:GetAttribute("CustomMoved") then
				placePanelToRightOfWallhop()
			end
			elegantShow(MobilePanel, UDim2.new(0, 170, 0, 94), MobilePanel.Position, 0)
		else
			elegantHide(MobilePanel)
		end
	end)

	MobileBeastSlowRow.MouseButton1Click:Connect(function()
		fakeSlowEnabled = not fakeSlowEnabled
		updateMobilePanelButtons()
	end)

	MobileHideGuiRow.MouseButton1Click:Connect(function()
		mobileWallhopGuiHidden = not mobileWallhopGuiHidden
		updateMobilePanelButtons()
	end)

	updateMobilePanelButtons()
end
-- Parte 3/3

local function setMinimized(state)
	if selectedMode ~= "PC" then
		return
	end

	guiMinimized = state

	if state then
		if MainFrame and MiniButton then
			MiniButton.Position = MainFrame.Position
			elegantHide(MainFrame, function()
				MainFrame.Visible = false
				MiniButton.Visible = true
				setHostShadowVisible(MiniButton, true)

				MiniButton.BackgroundTransparency = 1
				MiniButton.TextTransparency = 1

				TweenService:Create(MiniButton, TweenInfo.new(0.18, Enum.EasingStyle.Quad, Enum.EasingDirection.Out), {
					BackgroundTransparency = 0,
					TextTransparency = 0
				}):Play()
			end)
		end
		showNotice("GUI minimized")
	else
		if MainFrame and MiniButton then
			MainFrame.Position = MiniButton.Position
			MiniButton.Visible = false
			setHostShadowVisible(MiniButton, false)

			MainFrame.Visible = true
			elegantShow(MainFrame, MainFrame.Size, MainFrame.Position, 0)
		end
		showNotice("GUI restored")
	end
end

local function buildPCGui()
	clearOldDragConnections()

	ScreenGui = Instance.new("ScreenGui")
	ScreenGui.Name = "AutoWallHopGui"
	ScreenGui.ResetOnSpawn = false
	ScreenGui.ZIndexBehavior = Enum.ZIndexBehavior.Sibling
	ScreenGui.Parent = PlayerGui

	MainFrame = Instance.new("Frame")
	MainFrame.Size = UDim2.new(0, 265, 0, 196)
	MainFrame.Position = UDim2.new(0.5, -132, 0.5, -98)
	MainFrame.BackgroundColor3 = Color3.fromRGB(0, 0, 0)
	MainFrame.BorderSizePixel = 0
	MainFrame.Parent = ScreenGui
	MainFrame.Visible = true
	Instance.new("UICorner", MainFrame).CornerRadius = UDim.new(0, 16)
	addTrueRoundedShadow(MainFrame, 16, 1.25, Color3.fromRGB(0, 0, 0))

	local TopBar = Instance.new("Frame")
	TopBar.Size = UDim2.new(1, 0, 0, 34)
	TopBar.BackgroundColor3 = Color3.fromRGB(0, 0, 0)
	TopBar.BorderSizePixel = 0
	TopBar.Parent = MainFrame
	Instance.new("UICorner", TopBar).CornerRadius = UDim.new(0, 16)

	local Title = Instance.new("TextLabel")
	Title.Size = UDim2.new(1, -90, 1, 0)
	Title.Position = UDim2.new(0, 12, 0, 0)
	Title.BackgroundTransparency = 1
	Title.Text = "Wallhop PC"
	Title.TextColor3 = Color3.fromRGB(255,255,255)
	Title.Font = Enum.Font.GothamBold
	Title.TextSize = 16
	Title.TextXAlignment = Enum.TextXAlignment.Left
	Title.Parent = TopBar
	noTextStroke(Title)

	local MinimizeButton = Instance.new("TextButton")
	MinimizeButton.Size = UDim2.new(0, 24, 0, 24)
	MinimizeButton.Position = UDim2.new(1, -30, 0.5, -12)
	MinimizeButton.BackgroundColor3 = Color3.fromRGB(8,8,8)
	MinimizeButton.Text = "—"
	MinimizeButton.TextColor3 = Color3.fromRGB(255,255,255)
	MinimizeButton.Font = Enum.Font.GothamBold
	MinimizeButton.TextSize = 18
	MinimizeButton.Parent = TopBar
	Instance.new("UICorner", MinimizeButton).CornerRadius = UDim.new(1, 0)
	noTextStroke(MinimizeButton)

	MoveGuiButton = Instance.new("TextButton")
	MoveGuiButton.Size = UDim2.new(0, 26, 0, 26)
	MoveGuiButton.Position = UDim2.new(1, -60, 0.5, -13)
	MoveGuiButton.BackgroundColor3 = Color3.fromRGB(8,8,8)
	MoveGuiButton.Text = "✥"
	MoveGuiButton.TextColor3 = Color3.fromRGB(180,180,180)
	MoveGuiButton.Font = Enum.Font.GothamBold
	MoveGuiButton.TextSize = 16
	MoveGuiButton.Parent = TopBar
	Instance.new("UICorner", MoveGuiButton).CornerRadius = UDim.new(0, 8)
	noTextStroke(MoveGuiButton)

	ToggleButton = Instance.new("TextButton")
	ToggleButton.Size = UDim2.new(1, -16, 0, 40)
	ToggleButton.Position = UDim2.new(0, 8, 0, 44)
	ToggleButton.BackgroundColor3 = Color3.fromRGB(0, 0, 0)
	ToggleButton.Text = "Wall Hop Off"
	ToggleButton.TextColor3 = Color3.fromRGB(255,255,255)
	ToggleButton.Font = Enum.Font.GothamBold
	ToggleButton.TextSize = 15
	ToggleButton.Parent = MainFrame
	Instance.new("UICorner", ToggleButton).CornerRadius = UDim.new(0, 12)
	noTextStroke(ToggleButton)

	HideGuiBindButton = Instance.new("TextButton")
	HideGuiBindButton.Size = UDim2.new(1, -16, 0, 30)
	HideGuiBindButton.Position = UDim2.new(0, 8, 0, 92)
	HideGuiBindButton.BackgroundColor3 = Color3.fromRGB(0, 0, 0)
	HideGuiBindButton.TextColor3 = Color3.fromRGB(255,255,255)
	HideGuiBindButton.Font = Enum.Font.GothamBold
	HideGuiBindButton.TextSize = 13
	HideGuiBindButton.Parent = MainFrame
	Instance.new("UICorner", HideGuiBindButton).CornerRadius = UDim.new(0, 10)
	noTextStroke(HideGuiBindButton)

	ToggleBindButton = Instance.new("TextButton")
	ToggleBindButton.Size = UDim2.new(1, -16, 0, 30)
	ToggleBindButton.Position = UDim2.new(0, 8, 0, 127)
	ToggleBindButton.BackgroundColor3 = Color3.fromRGB(0, 0, 0)
	ToggleBindButton.TextColor3 = Color3.fromRGB(255,255,255)
	ToggleBindButton.Font = Enum.Font.GothamBold
	ToggleBindButton.TextSize = 13
	ToggleBindButton.Parent = MainFrame
	Instance.new("UICorner", ToggleBindButton).CornerRadius = UDim.new(0, 10)
	noTextStroke(ToggleBindButton)

	BeastSlowBindButton = Instance.new("TextButton")
	BeastSlowBindButton.Size = UDim2.new(1, -16, 0, 30)
	BeastSlowBindButton.Position = UDim2.new(0, 8, 0, 162)
	BeastSlowBindButton.BackgroundColor3 = Color3.fromRGB(0, 0, 0)
	BeastSlowBindButton.TextColor3 = Color3.fromRGB(255,255,255)
	BeastSlowBindButton.Font = Enum.Font.GothamBold
	BeastSlowBindButton.TextSize = 13
	BeastSlowBindButton.Parent = MainFrame
	Instance.new("UICorner", BeastSlowBindButton).CornerRadius = UDim.new(0, 10)
	noTextStroke(BeastSlowBindButton)

	ResizeGuiButton = Instance.new("TextButton")
	ResizeGuiButton.Size = UDim2.new(0, 24, 0, 24)
	ResizeGuiButton.Position = UDim2.new(1, -28, 1, -28)
	ResizeGuiButton.BackgroundColor3 = Color3.fromRGB(8,8,8)
	ResizeGuiButton.Text = "⤡"
	ResizeGuiButton.TextColor3 = Color3.fromRGB(180,180,180)
	ResizeGuiButton.Font = Enum.Font.GothamBold
	ResizeGuiButton.TextSize = 16
	ResizeGuiButton.Parent = MainFrame
	Instance.new("UICorner", ResizeGuiButton).CornerRadius = UDim.new(0, 8)
	noTextStroke(ResizeGuiButton)

	MiniButton = Instance.new("TextButton")
	MiniButton.Size = UDim2.new(0, 58, 0, 34)
	MiniButton.Position = MainFrame.Position
	MiniButton.BackgroundColor3 = Color3.fromRGB(0, 0, 0)
	MiniButton.Text = "GUI"
	MiniButton.TextColor3 = Color3.fromRGB(255,255,255)
	MiniButton.Font = Enum.Font.GothamBold
	MiniButton.TextSize = 14
	MiniButton.Visible = false
	MiniButton.Parent = ScreenGui
	Instance.new("UICorner", MiniButton).CornerRadius = UDim.new(0, 12)
	noTextStroke(MiniButton)
	addTrueRoundedShadow(MiniButton, 12, 1, Color3.fromRGB(0, 0, 0))

	Notice = Instance.new("TextLabel")
	Notice.Size = UDim2.new(0, 200, 0, 26)
	Notice.Position = UDim2.new(1, -14, 0, 14)
	Notice.AnchorPoint = Vector2.new(1, 0)
	Notice.BackgroundColor3 = Color3.fromRGB(0, 0, 0)
	Notice.BackgroundTransparency = 0.08
	Notice.TextColor3 = Color3.fromRGB(255,255,255)
	Notice.TextTransparency = 0
	Notice.Font = Enum.Font.GothamBold
	Notice.TextSize = 13
	Notice.Visible = false
	Notice.Parent = ScreenGui
	Instance.new("UICorner", Notice).CornerRadius = UDim.new(0, 10)
	noTextStroke(Notice)

	NoticeStroke = Instance.new("UIStroke")
	NoticeStroke.Color = Color3.fromRGB(255,255,255)
	NoticeStroke.Thickness = 1
	NoticeStroke.Transparency = 0.9
	NoticeStroke.Parent = Notice

	local moveInput = nil
	local moveStart = nil
	local moveFrameStart = nil

	local resizeInput = nil
	local resizeStart = nil
	local resizeSizeStart = nil

	table.insert(dragConnections, MoveGuiButton.InputBegan:Connect(function(input)
		if input.UserInputType == Enum.UserInputType.Touch or input.UserInputType == Enum.UserInputType.MouseButton1 then
			moveInput = input
			moveStart = input.Position
			moveFrameStart = MainFrame.Position
		end
	end))

	table.insert(dragConnections, ResizeGuiButton.InputBegan:Connect(function(input)
		if input.UserInputType == Enum.UserInputType.Touch or input.UserInputType == Enum.UserInputType.MouseButton1 then
			resizeInput = input
			resizeStart = input.Position
			resizeSizeStart = MainFrame.Size
		end
	end))

	table.insert(dragConnections, UserInputService.InputChanged:Connect(function(input)
		if input == moveInput and moveStart and moveFrameStart then
			local delta = input.Position - moveStart
			MainFrame.Position = UDim2.new(
				moveFrameStart.X.Scale,
				moveFrameStart.X.Offset + delta.X,
				moveFrameStart.Y.Scale,
				moveFrameStart.Y.Offset + delta.Y
			)
		end

		if input == resizeInput and resizeStart and resizeSizeStart then
			local delta = input.Position - resizeStart
			local newW = math.max(235, resizeSizeStart.X.Offset + delta.X)
			local newH = math.max(180, resizeSizeStart.Y.Offset + delta.Y)
			MainFrame.Size = UDim2.new(0, newW, 0, newH)
		end
	end))

	table.insert(dragConnections, UserInputService.InputEnded:Connect(function(input)
		if input == moveInput then
			moveInput = nil
			moveStart = nil
			moveFrameStart = nil
		end

		if input == resizeInput then
			resizeInput = nil
			resizeStart = nil
			resizeSizeStart = nil
		end
	end))

	MinimizeButton.MouseButton1Click:Connect(function()
		setMinimized(true)
	end)

	MiniButton.MouseButton1Click:Connect(function()
		setMinimized(false)
	end)

	HideGuiBindButton.MouseButton1Click:Connect(function()
		waitingForHideKey = true
		waitingForToggleKey = false
		waitingForBeastSlowKey = false
		updateBindButtons()
		showNotice("Press a key...")
	end)

	ToggleBindButton.MouseButton1Click:Connect(function()
		waitingForToggleKey = true
		waitingForHideKey = false
		waitingForBeastSlowKey = false
		updateBindButtons()
		showNotice("Press a key...")
	end)

	BeastSlowBindButton.MouseButton1Click:Connect(function()
		waitingForBeastSlowKey = true
		waitingForHideKey = false
		waitingForToggleKey = false
		updateBindButtons()
		showNotice("Press a key...")
	end)

	ToggleButton.MouseButton1Click:Connect(function()
		fakeWallhopEnabled = not fakeWallhopEnabled
		updateToggleButton()
		showNotice(fakeWallhopEnabled and "Wallhop enabled" or "Wallhop disabled")
	end)

	RunService.RenderStepped:Connect(function()
		if selectedMode ~= "PC" then return end
		local inset = GuiService:GetGuiInset()
		if guiVisible and not guiMinimized and MainFrame.Position == UDim2.new(0.5, -132, 0.5, -98) then
			MainFrame.Position = UDim2.new(0.5, -132, 0.5, -98 + inset.Y / 2)
		end
	end)

	updateBindButtons()
	elegantShow(MainFrame, UDim2.new(0, 265, 0, 196), MainFrame.Position, 0)
	showNotice("PC version loaded")
end

UserInputService.InputBegan:Connect(function(input, gameProcessed)
	if gameProcessed then return end
	if input.UserInputType ~= Enum.UserInputType.Keyboard then return end

	local key = input.KeyCode

	if selectedMode == "PC" then
		if waitingForHideKey then
			if key ~= toggleScriptKey and key ~= toggleBeastSlowKey then
				hideGuiKey = key
				waitingForHideKey = false
				updateBindButtons()
				showNotice("Hide GUI key updated")
			else
				showNotice("Key already in use")
			end
			return
		end

		if waitingForToggleKey then
			if key ~= hideGuiKey and key ~= toggleBeastSlowKey then
				toggleScriptKey = key
				waitingForToggleKey = false
				updateBindButtons()
				showNotice("Wallhop key updated")
			else
				showNotice("Key already in use")
			end
			return
		end

		if waitingForBeastSlowKey then
			if key ~= hideGuiKey and key ~= toggleScriptKey then
				toggleBeastSlowKey = key
				waitingForBeastSlowKey = false
				updateBindButtons()
				showNotice("Beast Slow key updated")
			else
				showNotice("Key already in use")
			end
			return
		end

		if key == hideGuiKey then
			setGuiVisible(not guiVisible)
			return
		end

		if key == toggleScriptKey then
			fakeWallhopEnabled = not fakeWallhopEnabled
			updateToggleButton()
			showNotice(fakeWallhopEnabled and "Wallhop enabled" or "Wallhop disabled")
			return
		end

		if key == toggleBeastSlowKey then
			fakeSlowEnabled = not fakeSlowEnabled
			showNotice(fakeSlowEnabled and "Beast Slow enabled" or "Beast Slow disabled")
			return
		end
	end
end)

createModeSelector(function(mode)
	selectedMode = mode

	if mode == "PC" then
		buildPCGui()
	else
		buildMobileGui()
	end

	updateToggleButton()
	updateMobilePanelButtons()
	applyVisibility()
end)

print("UI visual test loaded successfully")
