-- (Wallhop Humanoid Type - Made by nyhito)
-- All Credits: nyhito (tester, config and uploader)
-- The Best Wallhop Script

local Players = game:GetService("Players")
local LocalPlayer = Players.LocalPlayer
local RunService = game:GetService("RunService")
local GuiService = game:GetService("GuiService")
local UserInputService = game:GetService("UserInputService")
local TweenService = game:GetService("TweenService")
local HttpService = game:GetService("HttpService")

local PlayerGui = LocalPlayer:WaitForChild("PlayerGui")
local Camera = workspace.CurrentCamera

-- CONFIG
local DEFAULT_HIDE_GUI_KEY = Enum.KeyCode.RightShift
local DEFAULT_TOGGLE_SCRIPT_KEY = Enum.KeyCode.Q
local DEFAULT_TOGGLE_BEAST_SLOW_KEY = Enum.KeyCode.E
local SETTINGS_FILE = "nyhito_wallhop_pc_settings.json"

-- STATES
local selectedMode = nil

local isWallHopEnabled = false
local isSlowEnabled = false
local isFlicking = false
local lastFlickTime = 0

local isWallHopping = false
local lastWallHopTime = 0
local WALLHOP_GRACE_TIME = 1.5
local WALLHOP_COOLDOWN = 0.18

local canDoubleJump = false
local lastDoubleJump = 0
local DOUBLE_JUMP_COOLDOWN = 3
local blockDoubleJump = false

local hideGuiKey = DEFAULT_HIDE_GUI_KEY
local toggleScriptKey = DEFAULT_TOGGLE_SCRIPT_KEY
local toggleBeastSlowKey = DEFAULT_TOGGLE_BEAST_SLOW_KEY

local guiVisible = true
local guiMinimized = false
local mobileWallhopGuiHidden = false
local mobileMenuOpen = false

local waitingForHideKey = false
local waitingForToggleKey = false
local waitingForBeastSlowKey = false

local lastHitPosition = nil
local MIN_HIT_DISTANCE = 0.2
local lastFlickAngle = nil

local airborneSource = nil
local airborneStartY = nil
local airborneStartTime = 0
local jumpedRecently = false

local LEDGE_BLOCK_DISTANCE = 6.0
local LEDGE_BLOCK_TIME = 0.20

local SLOW_DURATION = 0.8
local SLOW_WALKSPEED = 9
local DEFAULT_WALKSPEED = 16
local slowToken = 0
local scriptSlowActive = false

-- GUI REFS
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

local mobileBeastSlowSwitch = nil
local mobileBeastSlowKnob = nil
local mobileHideGuiSwitch = nil
local mobileHideGuiKnob = nil

local function safeKeyCodeFromName(name, fallback)
	if typeof(name) ~= "string" then
		return fallback
	end

	local ok, result = pcall(function()
		return Enum.KeyCode[name]
	end)

	if ok and result then
		return result
	end

	return fallback
end

local function saveSettings()
	if not writefile or not isfile then
		return
	end

	local data = {
		hideGuiKey = hideGuiKey.Name,
		toggleScriptKey = toggleScriptKey.Name,
		toggleBeastSlowKey = toggleBeastSlowKey.Name,
	}

	pcall(function()
		writefile(SETTINGS_FILE, HttpService:JSONEncode(data))
	end)
end

local function loadSettings()
	if not readfile or not isfile then
		return
	end

	if not isfile(SETTINGS_FILE) then
		return
	end

	local ok, decoded = pcall(function()
		return HttpService:JSONDecode(readfile(SETTINGS_FILE))
	end)

	if ok and decoded then
		hideGuiKey = safeKeyCodeFromName(decoded.hideGuiKey, DEFAULT_HIDE_GUI_KEY)
		toggleScriptKey = safeKeyCodeFromName(decoded.toggleScriptKey, DEFAULT_TOGGLE_SCRIPT_KEY)
		toggleBeastSlowKey = safeKeyCodeFromName(decoded.toggleBeastSlowKey, DEFAULT_TOGGLE_BEAST_SLOW_KEY)
	end
end

loadSettings()

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
		shadow.ZIndex = 0
		shadow.Parent = parent
		Instance.new("UICorner", shadow).CornerRadius = UDim.new(0, cornerRadius + math.floor(cfg.grow / 2.2))
	end
end

local function noTextStroke(obj)
	obj.TextStrokeTransparency = 1
end

local activeNoticeId = 0
local function showNotice(text)
	if selectedMode ~= "PC" or not Notice or not NoticeStroke then
		return
	end

	activeNoticeId += 1
	local noticeId = activeNoticeId

	Notice.Text = text
	Notice.Position = UDim2.new(1, 240, 0, 0)
	Notice.TextTransparency = 1
	Notice.BackgroundTransparency = 0.08
	NoticeStroke.Transparency = 1

	TweenService:Create(Notice, TweenInfo.new(0.18, Enum.EasingStyle.Quad, Enum.EasingDirection.Out), {
		Position = UDim2.new(1, 0, 0, 0),
		TextTransparency = 0
	}):Play()

	TweenService:Create(NoticeStroke, TweenInfo.new(0.14), {
		Transparency = 0.9
	}):Play()

	task.spawn(function()
		task.wait(1)
		if noticeId ~= activeNoticeId then
			return
		end

		TweenService:Create(Notice, TweenInfo.new(0.24, Enum.EasingStyle.Quad, Enum.EasingDirection.In), {
			Position = UDim2.new(1, 250, 0, 0),
			TextTransparency = 1,
			BackgroundTransparency = 1
		}):Play()

		TweenService:Create(NoticeStroke, TweenInfo.new(0.2), {
			Transparency = 1
		}):Play()
	end)
end

local function fadeGuiObjectIn(obj, extra)
	if not obj then return end
	obj.Visible = true
	local goal = extra or {}
	if obj:IsA("Frame") or obj:IsA("TextButton") or obj:IsA("TextLabel") then
		obj.BackgroundTransparency = 1
		if obj:IsA("TextButton") or obj:IsA("TextLabel") then
			obj.TextTransparency = 1
			goal.TextTransparency = 0
		end
		goal.BackgroundTransparency = goal.BackgroundTransparency or 0
	end
	TweenService:Create(obj, TweenInfo.new(0.18, Enum.EasingStyle.Quad, Enum.EasingDirection.Out), goal):Play()
end

local function fadeGuiObjectOut(obj, onDone)
	if not obj then
		if onDone then onDone() end
		return
	end

	local tweenProps = {}
	if obj:IsA("Frame") or obj:IsA("TextButton") or obj:IsA("TextLabel") then
		tweenProps.BackgroundTransparency = 1
		if obj:IsA("TextButton") or obj:IsA("TextLabel") then
			tweenProps.TextTransparency = 1
		end
	end

	local tween = TweenService:Create(obj, TweenInfo.new(0.16, Enum.EasingStyle.Quad, Enum.EasingDirection.In), tweenProps)
	tween:Play()
	tween.Completed:Connect(function()
		if onDone then onDone() end
	end)
end

local function clearScriptSlowInstant()
	slowToken += 1
	scriptSlowActive = false

	local char = LocalPlayer.Character
	local hum = char and char:FindFirstChild("Humanoid")
	if hum and hum.Parent and hum.WalkSpeed == SLOW_WALKSPEED then
		hum.WalkSpeed = DEFAULT_WALKSPEED
	end
end

local function applyWallhopSlow(hum)
	if not hum or not hum.Parent or not isSlowEnabled then
		return
	end

	slowToken += 1
	local myToken = slowToken

	scriptSlowActive = true
	hum.WalkSpeed = SLOW_WALKSPEED

	task.delay(SLOW_DURATION, function()
		if not hum or not hum.Parent then
			scriptSlowActive = false
			return
		end

		if myToken ~= slowToken then
			return
		end

		scriptSlowActive = false

		if not isSlowEnabled then
			return
		end

		if hum.WalkSpeed == SLOW_WALKSPEED then
			hum.WalkSpeed = DEFAULT_WALKSPEED
		end
	end)
end

local function updateToggleButton()
	if selectedMode == "PC" and ToggleButton then
		ToggleButton.Text = isWallHopEnabled and "Wall Hop On" or "Wall Hop Off"
	elseif selectedMode == "Mobile" and MobileButton then
		MobileButton.Text = isWallHopEnabled and "Wallhop On" or "Wallhop Off"
	end
end

local function setMobileWallhopVisualHidden(hidden)
	if not MobileButton then return end

	if hidden then
		MobileButton.BackgroundTransparency = 1
		MobileButton.TextTransparency = 1
	else
		MobileButton.BackgroundTransparency = 0
		MobileButton.TextTransparency = 0
	end
end

local function updateSwitchVisual(switchFrame, knob, enabled)
	if not switchFrame or not knob then return end

	local knobPosOff = UDim2.new(0, 4, 0.5, -16)
	local knobPosOn = UDim2.new(1, -36, 0.5, -16)

	switchFrame.BackgroundTransparency = 0
	switchFrame.BackgroundColor3 = Color3.fromRGB(18, 18, 18)
	knob.BackgroundColor3 = enabled and Color3.fromRGB(255,255,255) or Color3.fromRGB(0,0,0)

	TweenService:Create(knob, TweenInfo.new(0.16, Enum.EasingStyle.Quad, Enum.EasingDirection.Out), {
		Position = enabled and knobPosOn or knobPosOff
	}):Play()
end

local function updateMobilePanelButtons()
	if MobileBeastSlowRow and MobileBeastSlowRow:FindFirstChild("Label") then
		MobileBeastSlowRow.Label.Text = "Beast Slow"
	end
	if MobileHideGuiRow and MobileHideGuiRow:FindFirstChild("Label") then
		MobileHideGuiRow.Label.Text = "Hide GUI"
	end

	updateSwitchVisual(mobileBeastSlowSwitch, mobileBeastSlowKnob, isSlowEnabled)
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
		end
		if MiniButton then
			MiniButton.Visible = guiVisible and guiMinimized
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
		end
		setMobileWallhopVisualHidden(mobileWallhopGuiHidden)
	end
end

local function setGuiVisible(state)
	guiVisible = state
	applyVisibility()
	showNotice(state and "GUI shown" or "GUI hidden")
end

local function setMinimized(state)
	if selectedMode ~= "PC" then
		return
	end

	guiMinimized = state

	if state then
		if MainFrame and MiniButton then
			MiniButton.Position = MainFrame.Position
			fadeGuiObjectOut(MainFrame, function()
				MainFrame.Visible = false
				MiniButton.BackgroundTransparency = 1
				MiniButton.TextTransparency = 1
				MiniButton.Visible = true
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
			fadeGuiObjectOut(MiniButton, function()
				MiniButton.Visible = false
				MainFrame.BackgroundTransparency = 1
				MainFrame.Visible = true
				TweenService:Create(MainFrame, TweenInfo.new(0.18, Enum.EasingStyle.Quad, Enum.EasingDirection.Out), {
					BackgroundTransparency = 0
				}):Play()
			end)
		end
		showNotice("GUI restored")
	end
end

local function isCrouching(hum, hrp)
	if not hum or not hrp then
		return false
	end

	local horizontalSpeed = Vector3.new(hrp.Velocity.X, 0, hrp.Velocity.Z).Magnitude
	return hum.WalkSpeed <= 9 and horizontalSpeed < 8
end

local function setupCharacter(char)
	local hum = char:WaitForChild("Humanoid")
	local hrp = char:WaitForChild("HumanoidRootPart")

	slowToken = 0
	scriptSlowActive = false

	hum.StateChanged:Connect(function(_, new)
		if new == Enum.HumanoidStateType.Jumping then
			jumpedRecently = true
			airborneSource = "jump"
			airborneStartY = hrp.Position.Y
			airborneStartTime = tick()
		end

		if new == Enum.HumanoidStateType.Freefall then
			canDoubleJump = true

			if airborneSource == nil then
				if jumpedRecently then
					airborneSource = "jump"
				else
					airborneSource = "ledge"
				end

				airborneStartY = hrp.Position.Y
				airborneStartTime = tick()
			end
		end

		if new == Enum.HumanoidStateType.Landed then
			canDoubleJump = false
			lastHitPosition = nil
			airborneSource = nil
			airborneStartY = nil
			airborneStartTime = 0
			jumpedRecently = false
		end
	end)
end

if LocalPlayer.Character then
	setupCharacter(LocalPlayer.Character)
end
LocalPlayer.CharacterAdded:Connect(setupCharacter)

UserInputService.JumpRequest:Connect(function()
	if not isWallHopEnabled or blockDoubleJump then
		return
	end

	local char = LocalPlayer.Character
	local hum = char and char:FindFirstChild("Humanoid")
	local hrp = char and char:FindFirstChild("HumanoidRootPart")
	if not hum or not hrp then
		return
	end

	local stillValid = isWallHopping or (tick() - lastWallHopTime <= WALLHOP_GRACE_TIME)
	if not stillValid then
		return
	end

	if canDoubleJump and tick() - lastDoubleJump > DOUBLE_JUMP_COOLDOWN then
		lastDoubleJump = tick()
		canDoubleJump = false

		hrp.Velocity = Vector3.new(hrp.Velocity.X, 30, hrp.Velocity.Z)
		hum:ChangeState(Enum.HumanoidStateType.Jumping)

		task.delay(0.18, function()
			if hum then
				hum:ChangeState(Enum.HumanoidStateType.Freefall)
			end
		end)
	end
end)

local function pickNextFlick()
	local minAngle, maxAngle = 50, 80
	local attempt = 0
	local angle

	repeat
		angle = math.random(minAngle, maxAngle)
		attempt += 1
	until not lastFlickAngle or math.abs(angle - lastFlickAngle) >= 10 or attempt > 20

	lastFlickAngle = angle
	return math.rad(angle)
end

local function getFlickProfile()
	local flickRoll = math.random()

	if flickRoll < 0.10 then
		return {
			steps = math.random(4, 5),
			delayMin = 0.0048,
			delayMax = 0.0062,
			overshootMin = 18,
			overshootMax = 24,
			baseDelay = 0.0105
		}
	elseif flickRoll < 0.40 then
		return {
			steps = math.random(5, 6),
			delayMin = 0.0055,
			delayMax = 0.0078,
			overshootMin = 18,
			overshootMax = 27,
			baseDelay = 0.0105
		}
	else
		return {
			steps = math.random(7, 10),
			delayMin = 0.008,
			delayMax = 0.0125,
			overshootMin = 20,
			overshootMax = 32,
			baseDelay = 0.01
		}
	end
end

local function performVideoFlick()
	if isFlicking then
		return
	end

	isFlicking = true
	isWallHopping = true
	lastWallHopTime = tick()
	blockDoubleJump = true

	local char = LocalPlayer.Character
	local hum = char and char:FindFirstChild("Humanoid")
	local hrp = char and char:FindFirstChild("HumanoidRootPart")
	if not hum or not hrp then
		isFlicking = false
		return
	end

	hum:ChangeState(Enum.HumanoidStateType.Jumping)

	local baseYaw = hrp.Orientation.Y
	local angle = -pickNextFlick()

	local profile = getFlickProfile()
	local steps = profile.steps
	local delayMin = profile.delayMin
	local delayMax = profile.delayMax
	local baseDelay = profile.baseDelay
	local overshoot = math.rad(math.random(profile.overshootMin, profile.overshootMax))
	local useOvershoot = math.random() < 0.9
	for i = 1, steps do
		local alpha = i / steps
		local curve

		if alpha <= 0.6 then
			curve = math.sin((alpha / 0.6) * (math.pi / 2))
		else
			curve = math.sin(((1 - alpha) / 0.4) * (math.pi / 2))
		end

		local offset = angle * curve
		hrp.CFrame = CFrame.new(hrp.Position) * CFrame.Angles(0, math.rad(baseYaw) + offset, 0)

		RunService.RenderStepped:Wait()
		task.wait(delayMin + math.random() * (delayMax - delayMin))
	end

	if useOvershoot then
		task.delay(0.05, function()
			if not hrp or not hrp.Parent then
				return
			end

			local smallSteps = 4

			for i = 1, smallSteps do
				local alpha = i / smallSteps
				local offset = overshoot * alpha
				hrp.CFrame = CFrame.new(hrp.Position) * CFrame.Angles(0, math.rad(baseYaw) + offset, 0)
				RunService.RenderStepped:Wait()
				task.wait(baseDelay)
			end

			for i = 1, smallSteps do
				local alpha = i / smallSteps
				local offset = overshoot * (1 - alpha)
				hrp.CFrame = CFrame.new(hrp.Position) * CFrame.Angles(0, math.rad(baseYaw) + offset, 0)
				RunService.RenderStepped:Wait()
				task.wait(baseDelay)
			end

			hrp.CFrame = CFrame.new(hrp.Position) * CFrame.Angles(0, math.rad(baseYaw), 0)
		end)
	end

	hrp.CFrame = CFrame.new(hrp.Position) * CFrame.Angles(0, math.rad(baseYaw), 0)

	if isSlowEnabled then
		applyWallhopSlow(hum)
	end

	task.delay(0.05, function()
		blockDoubleJump = false
	end)

	task.delay(0.15, function()
		isWallHopping = false
	end)

	isFlicking = false
end

local function isPlayerCharacter(instance)
	if not instance then
		return false
	end

	local model = instance:FindFirstAncestorOfClass("Model")
	return model and model:FindFirstChild("Humanoid")
end

local function isWallLikeSurface(normal)
	return math.abs(normal.Y) < 0.35
end

local function hasValidHorizontalEdge(rayResult, params)
	if not rayResult or not rayResult.Instance then
		return false
	end

	local hitPos = rayResult.Position
	local normal = rayResult.Normal.Unit

	local right = normal:Cross(Vector3.new(0, 1, 0))
	if right.Magnitude < 0.01 then
		return false
	end
	right = right.Unit

	local surfaceOffset = normal * 0.08

	local verticalChecks = {
		Vector3.new(0, 0.9, 0),
		Vector3.new(0, -0.9, 0),
		Vector3.new(0, 1.25, 0),
		Vector3.new(0, -1.25, 0),
	}

	local foundHorizontalEdge = false
	for _, vOffset in ipairs(verticalChecks) do
		local origin = hitPos + vOffset + surfaceOffset
		local probe = workspace:Raycast(origin, -normal * 0.22, params)

		if not probe or not probe.Instance or probe.Instance ~= rayResult.Instance then
			foundHorizontalEdge = true
			break
		end
	end

	if not foundHorizontalEdge then
		return false
	end

	return true
end

local function findValidWall(hrp, params, directions)
	local offsets = {
		Vector3.new(0, -2.3, 0),
		Vector3.new(0, -2.2, 0),
		Vector3.new(0, -1.2, 0)
	}

	for _, dir in ipairs(directions) do
		for _, offset in ipairs(offsets) do
			local origin = hrp.Position + offset
			local ray = workspace:Raycast(origin, dir, params)

			if ray and ray.Instance and ray.Instance.CanCollide and not isPlayerCharacter(ray.Instance) then
				if isWallLikeSurface(ray.Normal) and hasValidHorizontalEdge(ray, params) then
					return ray
				end
			end
		end
	end

	return nil
end

local function isWithinWallhopAngle(cameraLook, wallNormal, maxAngleDeg)
	local look = Vector3.new(cameraLook.X, 0, cameraLook.Z)
	local normal = Vector3.new(wallNormal.X, 0, wallNormal.Z)

	if look.Magnitude <= 0 or normal.Magnitude <= 0 then
		return false
	end

	look = look.Unit
	normal = normal.Unit

	local dotFront = math.clamp(look:Dot(-normal), -1, 1)
	local dotBack = math.clamp(look:Dot(normal), -1, 1)

	local frontAngle = math.deg(math.acos(dotFront))
	local backAngle = math.deg(math.acos(dotBack))

	return frontAngle <= maxAngleDeg or backAngle <= maxAngleDeg
end

local function createModeSelector(onPick)
	local selectorGui = Instance.new("ScreenGui")
	selectorGui.Name = "WallhopModeSelector"
	selectorGui.ResetOnSpawn = false
	selectorGui.ZIndexBehavior = Enum.ZIndexBehavior.Sibling
	selectorGui.Parent = PlayerGui

	local frame = Instance.new("Frame")
	frame.Size = UDim2.new(0, 280, 0, 170)
	frame.Position = UDim2.new(0.5, -140, 0.5, -85)
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
	sub.Text = "FtF Wallhop • made by nyhito"
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

	pcButton.MouseButton1Click:Connect(function()
		selectorGui:Destroy()
		onPick("PC")
	end)

	mobileButton.MouseButton1Click:Connect(function()
		selectorGui:Destroy()
		onPick("Mobile")
	end)
end

local function buildPCGui()
	ScreenGui = Instance.new("ScreenGui")
	ScreenGui.Name = "FtFWallhopGuiPC"
	ScreenGui.ResetOnSpawn = false
	ScreenGui.ZIndexBehavior = Enum.ZIndexBehavior.Sibling
	ScreenGui.Parent = PlayerGui

	MainFrame = Instance.new("Frame")
	MainFrame.Name = "MainFrame"
	MainFrame.Size = UDim2.new(0, 265, 0, 196)
	MainFrame.Position = UDim2.new(0.5, -132, 0.5, -98)
	MainFrame.BackgroundColor3 = Color3.fromRGB(0, 0, 0)
	MainFrame.BorderSizePixel = 0
	MainFrame.Parent = ScreenGui
	Instance.new("UICorner", MainFrame).CornerRadius = UDim.new(0, 16)

	addTrueRoundedShadow(MainFrame, 16, 1, Color3.fromRGB(0, 0, 0))

	local TopBar = Instance.new("Frame")
	TopBar.Name = "TopBar"
	TopBar.Size = UDim2.new(1, 0, 0, 40)
	TopBar.BackgroundTransparency = 1
	TopBar.Parent = MainFrame

	local Title = Instance.new("TextLabel")
	Title.Size = UDim2.new(1, -44, 0, 22)
	Title.Position = UDim2.new(0, 12, 0, 7)
	Title.BackgroundTransparency = 1
	Title.Text = "FtF Wallhop"
	Title.TextColor3 = Color3.fromRGB(255, 255, 255)
	Title.Font = Enum.Font.GothamBold
	Title.TextSize = 19
	Title.TextXAlignment = Enum.TextXAlignment.Left
	Title.Parent = TopBar
	noTextStroke(Title)

	local SubTitle = Instance.new("TextLabel")
	SubTitle.Size = UDim2.new(1, -44, 0, 12)
	SubTitle.Position = UDim2.new(0, 12, 0, 25)
	SubTitle.BackgroundTransparency = 1
	SubTitle.Text = "PC Version"
	SubTitle.TextColor3 = Color3.fromRGB(110, 110, 110)
	SubTitle.Font = Enum.Font.Gotham
	SubTitle.TextSize = 10
	SubTitle.TextXAlignment = Enum.TextXAlignment.Left
	SubTitle.Parent = TopBar
	noTextStroke(SubTitle)

	local MinimizeButton = Instance.new("TextButton")
	MinimizeButton.Size = UDim2.new(0, 22, 0, 22)
	MinimizeButton.Position = UDim2.new(1, -29, 0, 8)
	MinimizeButton.BackgroundColor3 = Color3.fromRGB(0, 0, 0)
	MinimizeButton.Text = "≡"
	MinimizeButton.TextColor3 = Color3.fromRGB(225, 225, 225)
	MinimizeButton.Font = Enum.Font.GothamBold
	MinimizeButton.TextSize = 14
	MinimizeButton.Parent = TopBar
	Instance.new("UICorner", MinimizeButton).CornerRadius = UDim.new(1, 0)
	noTextStroke(MinimizeButton)

	local ContentFrame = Instance.new("Frame")
	ContentFrame.Name = "ContentFrame"
	ContentFrame.Size = UDim2.new(1, -18, 1, -46)
	ContentFrame.Position = UDim2.new(0, 9, 0, 38)
	ContentFrame.BackgroundTransparency = 1
	ContentFrame.Parent = MainFrame
	ToggleButton = Instance.new("TextButton")
	ToggleButton.Size = UDim2.new(1, 0, 0, 34)
	ToggleButton.Position = UDim2.new(0, 0, 0, 0)
	ToggleButton.BackgroundColor3 = Color3.fromRGB(0, 0, 0)
	ToggleButton.Text = "Wall Hop Off"
	ToggleButton.TextColor3 = Color3.fromRGB(255,255,255)
	ToggleButton.Font = Enum.Font.GothamBold
	ToggleButton.TextSize = 17
	ToggleButton.TextXAlignment = Enum.TextXAlignment.Left
	ToggleButton.Parent = ContentFrame
	Instance.new("UICorner", ToggleButton).CornerRadius = UDim.new(0, 12)
	noTextStroke(ToggleButton)

	local TogglePadding = Instance.new("UIPadding")
	TogglePadding.PaddingLeft = UDim.new(0, 14)
	TogglePadding.Parent = ToggleButton

	HideGuiBindButton = Instance.new("TextButton")
	HideGuiBindButton.Size = UDim2.new(1, 0, 0, 28)
	HideGuiBindButton.Position = UDim2.new(0, 0, 0, 40)
	HideGuiBindButton.BackgroundColor3 = Color3.fromRGB(0, 0, 0)
	HideGuiBindButton.Text = "Keybind Hide GUI: RightShift"
	HideGuiBindButton.TextColor3 = Color3.fromRGB(225,225,225)
	HideGuiBindButton.Font = Enum.Font.Gotham
	HideGuiBindButton.TextSize = 12
	HideGuiBindButton.TextXAlignment = Enum.TextXAlignment.Left
	HideGuiBindButton.Parent = ContentFrame
	Instance.new("UICorner", HideGuiBindButton).CornerRadius = UDim.new(0, 11)
	noTextStroke(HideGuiBindButton)

	local HidePadding = Instance.new("UIPadding")
	HidePadding.PaddingLeft = UDim.new(0, 14)
	HidePadding.Parent = HideGuiBindButton

	ToggleBindButton = Instance.new("TextButton")
	ToggleBindButton.Size = UDim2.new(1, 0, 0, 28)
	ToggleBindButton.Position = UDim2.new(0, 0, 0, 72)
	ToggleBindButton.BackgroundColor3 = Color3.fromRGB(0, 0, 0)
	ToggleBindButton.Text = "Keybind Toggle Wallhop: Q"
	ToggleBindButton.TextColor3 = Color3.fromRGB(225,225,225)
	ToggleBindButton.Font = Enum.Font.Gotham
	ToggleBindButton.TextSize = 12
	ToggleBindButton.TextXAlignment = Enum.TextXAlignment.Left
	ToggleBindButton.Parent = ContentFrame
	Instance.new("UICorner", ToggleBindButton).CornerRadius = UDim.new(0, 11)
	noTextStroke(ToggleBindButton)

	local ToggleBindPadding = Instance.new("UIPadding")
	ToggleBindPadding.PaddingLeft = UDim.new(0, 14)
	ToggleBindPadding.Parent = ToggleBindButton

	BeastSlowBindButton = Instance.new("TextButton")
	BeastSlowBindButton.Size = UDim2.new(1, 0, 0, 28)
	BeastSlowBindButton.Position = UDim2.new(0, 0, 0, 104)
	BeastSlowBindButton.BackgroundColor3 = Color3.fromRGB(0, 0, 0)
	BeastSlowBindButton.Text = "Keybind Toggle Beast Slow: E"
	BeastSlowBindButton.TextColor3 = Color3.fromRGB(225,225,225)
	BeastSlowBindButton.Font = Enum.Font.Gotham
	BeastSlowBindButton.TextSize = 12
	BeastSlowBindButton.TextXAlignment = Enum.TextXAlignment.Left
	BeastSlowBindButton.Parent = ContentFrame
	Instance.new("UICorner", BeastSlowBindButton).CornerRadius = UDim.new(0, 11)
	noTextStroke(BeastSlowBindButton)

	local BeastSlowBindPadding = Instance.new("UIPadding")
	BeastSlowBindPadding.PaddingLeft = UDim.new(0, 14)
	BeastSlowBindPadding.Parent = BeastSlowBindButton

	local BottomLabel = Instance.new("TextLabel")
	BottomLabel.Size = UDim2.new(1, -2, 0, 12)
	BottomLabel.Position = UDim2.new(0, 2, 1, -14)
	BottomLabel.BackgroundTransparency = 1
	BottomLabel.Text = "the best ftf wallhop ever - nyhito panel"
	BottomLabel.TextColor3 = Color3.fromRGB(85, 85, 85)
	BottomLabel.Font = Enum.Font.Gotham
	BottomLabel.TextSize = 8
	BottomLabel.TextXAlignment = Enum.TextXAlignment.Left
	BottomLabel.Parent = ContentFrame
	noTextStroke(BottomLabel)

	MiniButton = Instance.new("TextButton")
	MiniButton.Name = "MiniButton"
	MiniButton.Size = UDim2.new(0, 140, 0, 36)
	MiniButton.Position = UDim2.new(0.5, -70, 0.5, -18)
	MiniButton.BackgroundColor3 = Color3.fromRGB(0, 0, 0)
	MiniButton.Visible = false
	MiniButton.Text = "FtF Wallhop"
	MiniButton.TextColor3 = Color3.fromRGB(255,255,255)
	MiniButton.Font = Enum.Font.GothamBold
	MiniButton.TextSize = 14
	MiniButton.Parent = ScreenGui
	Instance.new("UICorner", MiniButton).CornerRadius = UDim.new(1, 0)
	noTextStroke(MiniButton)

	addTrueRoundedShadow(MiniButton, 999, 0.8, Color3.fromRGB(0, 0, 0))

	local NoticeHolder = Instance.new("Frame")
	NoticeHolder.Name = "NoticeHolder"
	NoticeHolder.AnchorPoint = Vector2.new(1, 0)
	NoticeHolder.Position = UDim2.new(1, -10, 0, 8)
	NoticeHolder.Size = UDim2.new(0, 210, 0, 28)
	NoticeHolder.BackgroundTransparency = 1
	NoticeHolder.Parent = ScreenGui

	Notice = Instance.new("TextLabel")
	Notice.AnchorPoint = Vector2.new(1, 0)
	Notice.Position = UDim2.new(1, 240, 0, 0)
	Notice.Size = UDim2.new(0, 200, 0, 26)
	Notice.BackgroundColor3 = Color3.fromRGB(0, 0, 0)
	Notice.BackgroundTransparency = 0.08
	Notice.TextTransparency = 1
	Notice.Text = ""
	Notice.TextColor3 = Color3.fromRGB(255,255,255)
	Notice.Font = Enum.Font.GothamBold
	Notice.TextSize = 11
	Notice.TextXAlignment = Enum.TextXAlignment.Center
	Notice.Parent = NoticeHolder
	Instance.new("UICorner", Notice).CornerRadius = UDim.new(1, 0)
	noTextStroke(Notice)

	NoticeStroke = Instance.new("UIStroke")
	NoticeStroke.Color = Color3.fromRGB(0,0,0)
	NoticeStroke.Transparency = 1
	NoticeStroke.Thickness = 1
	NoticeStroke.Parent = Notice

	local dragging = false
	local dragStart
	local startPos
	local dragTarget = MainFrame

	local function beginDrag(input, target)
		dragging = true
		dragTarget = target
		dragStart = input.Position
		startPos = target.Position
	end

	local function updateDrag(input)
		if not dragging or not dragTarget then
			return
		end

		local delta = input.Position - dragStart
		dragTarget.Position = UDim2.new(
			startPos.X.Scale,
			startPos.X.Offset + delta.X,
			startPos.Y.Scale,
			startPos.Y.Offset + delta.Y
		)
	end

	local function bindDrag(handle, target)
		handle.InputBegan:Connect(function(input)
			if input.UserInputType == Enum.UserInputType.MouseButton1 then
				beginDrag(input, target)
				input.Changed:Connect(function()
					if input.UserInputState == Enum.UserInputState.End then
						dragging = false
					end
				end)
			end
		end)
	end

	bindDrag(TopBar, MainFrame)
	bindDrag(MiniButton, MiniButton)

	UserInputService.InputChanged:Connect(function(input)
		if selectedMode == "PC" and input.UserInputType == Enum.UserInputType.MouseMovement then
			updateDrag(input)
		end
	end)

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
		isWallHopEnabled = not isWallHopEnabled
		updateToggleButton()
		showNotice(isWallHopEnabled and "Wallhop enabled" or "Wallhop disabled")
	end)

	RunService.RenderStepped:Connect(function()
		if selectedMode ~= "PC" then return end
		local inset = GuiService:GetGuiInset()
		if guiVisible and not dragging then
			if not guiMinimized and MainFrame.Position == UDim2.new(0.5, -132, 0.5, -98) then
				MainFrame.Position = UDim2.new(0.5, -132, 0.5, -98 + inset.Y / 2)
			end
		end
	end)

	showNotice("PC version loaded")
end

local function createSwitchRow(parent, yOffset, labelText)
	local row = Instance.new("Frame")
	row.Size = UDim2.new(1, -16, 0, 48)
	row.Position = UDim2.new(0, 8, 0, yOffset)
	row.BackgroundColor3 = Color3.fromRGB(0, 0, 0)
	row.BorderSizePixel = 0
	row.Parent = parent
	Instance.new("UICorner", row).CornerRadius = UDim.new(0, 12)

	local label = Instance.new("TextLabel")
	label.Name = "Label"
	label.Size = UDim2.new(1, -86, 1, 0)
	label.Position = UDim2.new(0, 12, 0, 0)
	label.BackgroundTransparency = 1
	label.Text = labelText
	label.TextColor3 = Color3.fromRGB(255,255,255)
	label.Font = Enum.Font.GothamBold
	label.TextSize = 15
	label.TextXAlignment = Enum.TextXAlignment.Left
	label.Parent = row
	noTextStroke(label)

	local switch = Instance.new("Frame")
	switch.Size = UDim2.new(0, 72, 0, 36)
	switch.Position = UDim2.new(1, -80, 0.5, -18)
	switch.BackgroundColor3 = Color3.fromRGB(18,18,18)
	switch.BorderSizePixel = 0
	switch.Parent = row
	Instance.new("UICorner", switch).CornerRadius = UDim.new(1, 0)

	local knob = Instance.new("Frame")
	knob.Size = UDim2.new(0, 32, 0, 32)
	knob.Position = UDim2.new(0, 4, 0.5, -16)
	knob.BackgroundColor3 = Color3.fromRGB(0,0,0)
	knob.BorderSizePixel = 0
	knob.Parent = switch
	Instance.new("UICorner", knob).CornerRadius = UDim.new(1, 0)

	return row, switch, knob
end

local function buildMobileGui()
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
	MobilePanel.Size = UDim2.new(0, 210, 0, 118)
	MobilePanel.Position = UDim2.new(0, 20, 0, 240)
	MobilePanel.BackgroundColor3 = Color3.fromRGB(0, 0, 0)
	MobilePanel.BorderSizePixel = 0
	MobilePanel.Visible = false
	MobilePanel.Parent = ScreenGui
	Instance.new("UICorner", MobilePanel).CornerRadius = UDim.new(0, 14)

	addTrueRoundedShadow(MobilePanel, 14, 1, Color3.fromRGB(0, 0, 0))

	MobileBeastSlowRow, mobileBeastSlowSwitch, mobileBeastSlowKnob = createSwitchRow(MobilePanel, 8, "Beast Slow")
	MobileHideGuiRow, mobileHideGuiSwitch, mobileHideGuiKnob = createSwitchRow(MobilePanel, 60, "Hide GUI")

	RunService.RenderStepped:Connect(function()
		if selectedMode ~= "Mobile" then return end
		local inset = GuiService:GetGuiInset()
		if not MobileButton:GetAttribute("CustomMoved") then
			MobileButton.Position = UDim2.new(0, 150, 0, inset.Y - 58)
		end
	end)

	local mobileDragData = {
		button = {dragging = false, input = nil, startPos = nil, startInput = nil},
		menu = {dragging = false, input = nil, startPos = nil, startInput = nil}
	}

	MobileButton.InputBegan:Connect(function(input)
		if input.UserInputType == Enum.UserInputType.Touch then
			mobileDragData.button.dragging = true
			mobileDragData.button.input = input
			mobileDragData.button.startPos = MobileButton.Position
			mobileDragData.button.startInput = input.Position
		end
	end)

	MobileButton.InputChanged:Connect(function(input)
		if input.UserInputType == Enum.UserInputType.Touch and mobileDragData.button.dragging and mobileDragData.button.input == input then
			local delta = input.Position - mobileDragData.button.startInput
			if delta.Magnitude > 65 then
				mobileDragData.button.dragging = false
				return
			end
			MobileButton.Position = UDim2.new(
				mobileDragData.button.startPos.X.Scale,
				mobileDragData.button.startPos.X.Offset + delta.X,
				mobileDragData.button.startPos.Y.Scale,
				mobileDragData.button.startPos.Y.Offset + delta.Y
			)
			MobileButton:SetAttribute("CustomMoved", true)
		end
	end)

	MobileButton.InputEnded:Connect(function(input)
		if input.UserInputType == Enum.UserInputType.Touch and mobileDragData.button.input == input then
			mobileDragData.button.dragging = false
			mobileDragData.button.input = nil
		end
	end)

	MobileMenuButton.InputBegan:Connect(function(input)
		if input.UserInputType == Enum.UserInputType.Touch then
			mobileDragData.menu.dragging = true
			mobileDragData.menu.input = input
			mobileDragData.menu.startPos = MobileMenuButton.Position
			mobileDragData.menu.startInput = input.Position
		end
	end)

	MobileMenuButton.InputChanged:Connect(function(input)
		if input.UserInputType == Enum.UserInputType.Touch and mobileDragData.menu.dragging and mobileDragData.menu.input == input then
			local delta = input.Position - mobileDragData.menu.startInput
			MobileMenuButton.Position = UDim2.new(
				mobileDragData.menu.startPos.X.Scale,
				mobileDragData.menu.startPos.X.Offset + delta.X,
				mobileDragData.menu.startPos.Y.Scale,
				mobileDragData.menu.startPos.Y.Offset + delta.Y
			)

			if MobilePanel then
				MobilePanel.Position = UDim2.new(
					MobileMenuButton.Position.X.Scale,
					MobileMenuButton.Position.X.Offset,
					MobileMenuButton.Position.Y.Scale,
					MobileMenuButton.Position.Y.Offset + 60
				)
			end
		end
	end)

	MobileMenuButton.InputEnded:Connect(function(input)
		if input.UserInputType == Enum.UserInputType.Touch and mobileDragData.menu.input == input then
			mobileDragData.menu.dragging = false
			mobileDragData.menu.input = nil
		end
	end)

	MobileButton.MouseButton1Click:Connect(function()
		isWallHopEnabled = not isWallHopEnabled
		updateToggleButton()
	end)

	MobileMenuButton.MouseButton1Click:Connect(function()
		mobileMenuOpen = not mobileMenuOpen

		if mobileMenuOpen then
			MobilePanel.BackgroundTransparency = 1
			for _, child in ipairs(MobilePanel:GetChildren()) do
				if child:IsA("TextButton") or child:IsA("TextLabel") or child:IsA("Frame") then
					child.BackgroundTransparency = 1
					if child:IsA("TextButton") or child:IsA("TextLabel") then
						child.TextTransparency = 1
					end
				end
			end
			MobilePanel.Visible = true
			TweenService:Create(MobilePanel, TweenInfo.new(0.18, Enum.EasingStyle.Quad, Enum.EasingDirection.Out), {
				BackgroundTransparency = 0
			}):Play()
			for _, child in ipairs(MobilePanel:GetChildren()) do
				if child:IsA("Frame") then
					TweenService:Create(child, TweenInfo.new(0.18, Enum.EasingStyle.Quad, Enum.EasingDirection.Out), {
						BackgroundTransparency = 0
					}):Play()
					for _, sub in ipairs(child:GetChildren()) do
						if sub:IsA("TextLabel") then
							TweenService:Create(sub, TweenInfo.new(0.18, Enum.EasingStyle.Quad, Enum.EasingDirection.Out), {
								TextTransparency = 0
							}):Play()
						elseif sub:IsA("Frame") then
							TweenService:Create(sub, TweenInfo.new(0.18, Enum.EasingStyle.Quad, Enum.EasingDirection.Out), {
								BackgroundTransparency = 0
							}):Play()
						end
					end
				end
			end
		else
			fadeGuiObjectOut(MobilePanel, function()
				MobilePanel.Visible = false
				MobilePanel.BackgroundTransparency = 0
				updateMobilePanelButtons()
			end)
		end
	end)

	MobileBeastSlowRow.MouseButton1Click:Connect(function()
		isSlowEnabled = not isSlowEnabled
		if not isSlowEnabled then
			clearScriptSlowInstant()
		end
		updateMobilePanelButtons()
	end)

	MobileHideGuiRow.MouseButton1Click:Connect(function()
		mobileWallhopGuiHidden = not mobileWallhopGuiHidden
		updateMobilePanelButtons()
	end)

	updateMobilePanelButtons()
end

RunService.Heartbeat:Connect(function()
	if not isWallHopEnabled then
		return
	end

	local char = LocalPlayer.Character
	local hrp = char and char:FindFirstChild("HumanoidRootPart")
	local hum = char and char:FindFirstChild("Humanoid")

	if not hrp or not hum then
		return
	end

	if isCrouching(hum, hrp) then
		return
	end

	local state = hum:GetState()
	local airborne = state == Enum.HumanoidStateType.Freefall or state == Enum.HumanoidStateType.Jumping

	if not airborne then
		lastHitPosition = nil
		return
	end

	local allowWallhop = true

	if airborneSource == "ledge" and airborneStartY then
		local fallDistance = airborneStartY - hrp.Position.Y
		local airTime = tick() - airborneStartTime

		if fallDistance < LEDGE_BLOCK_DISTANCE and airTime < LEDGE_BLOCK_TIME then
			allowWallhop = false
		end
	end

	if not allowWallhop then
		lastHitPosition = nil
		return
	end

	local params = RaycastParams.new()
	params.FilterDescendantsInstances = {char}
	params.FilterType = Enum.RaycastFilterType.Exclude

	local look = Camera.CFrame.LookVector
	local horizontal = Vector3.new(look.X, 0, look.Z)

	if horizontal.Magnitude <= 0 then
		lastHitPosition = nil
		return
	end

	horizontal = horizontal.Unit

	local forwardDirection = horizontal * 1.55
	local backwardDirection = -horizontal * 1.55

	local result = findValidWall(hrp, params, {
		forwardDirection,
		backwardDirection
	})

	if result and result.Instance then
		local validAngle = isWithinWallhopAngle(Camera.CFrame.LookVector, result.Normal, 25)

		if validAngle then
			local farEnough = true
			if lastHitPosition then
				farEnough = (result.Position - lastHitPosition).Magnitude >= MIN_HIT_DISTANCE
			end

			if hrp.Velocity.Y < -0.8 and tick() - lastFlickTime > WALLHOP_COOLDOWN and farEnough then
				lastFlickTime = tick()
				lastHitPosition = result.Position
				performVideoFlick()
			else
				lastHitPosition = result.Position
			end
		else
			lastHitPosition = nil
		end
	else
		lastHitPosition = nil
	end
end)

UserInputService.InputBegan:Connect(function(input, gameProcessed)
	if selectedMode ~= "PC" then return end
	if gameProcessed then return end
	if input.UserInputType ~= Enum.UserInputType.Keyboard then return end

	local key = input.KeyCode
	if key == Enum.KeyCode.Unknown then return end

	if waitingForHideKey then
		if key ~= toggleScriptKey and key ~= toggleBeastSlowKey then
			hideGuiKey = key
			waitingForHideKey = false
			updateBindButtons()
			saveSettings()
			showNotice("Hide GUI updated")
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
			saveSettings()
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
			saveSettings()
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
		isWallHopEnabled = not isWallHopEnabled
		updateToggleButton()
		showNotice(isWallHopEnabled and "Wallhop enabled" or "Wallhop disabled")
		return
	end

	if key == toggleBeastSlowKey then
		isSlowEnabled = not isSlowEnabled
		if not isSlowEnabled then
			clearScriptSlowInstant()
		end
		showNotice(isSlowEnabled and "Beast Slow enabled" or "Beast Slow disabled")
		return
	end
end)

createModeSelector(function(mode)
	selectedMode = mode

	if mode == "PC" then
		buildPCGui()
		updateBindButtons()
	else
		buildMobileGui()
	end

	updateToggleButton()
	updateMobilePanelButtons()
	applyVisibility()
end)

print("Made by nyhito | Best Flee The Facility Wallhop Script - Loaded Successfully ✅")
