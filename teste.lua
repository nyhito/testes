-- AUTO WALLHOP + DOUBLE JUMP (REFINADO FINAL + PULSO VISUAL)

local Players = game:GetService("Players")
local LocalPlayer = Players.LocalPlayer
local RunService = game:GetService("RunService")
local GuiService = game:GetService("GuiService")
local UserInputService = game:GetService("UserInputService")
local TweenService = game:GetService("TweenService")

local PlayerGui = LocalPlayer:WaitForChild("PlayerGui")

-- UI
local ScreenGui = Instance.new("ScreenGui")
ScreenGui.Name = "AutoWallHopGui"
ScreenGui.ResetOnSpawn = false
ScreenGui.Parent = PlayerGui

local TextButton = Instance.new("TextButton")
TextButton.Size = UDim2.new(0, 140, 0, 50)
TextButton.BackgroundColor3 = Color3.fromRGB(0, 0, 0)
TextButton.Text = "Wall Hop Off"
TextButton.TextColor3 = Color3.fromRGB(255,255,255)
TextButton.Font = Enum.Font.GothamBold
TextButton.TextScaled = true
TextButton.Parent = ScreenGui

Instance.new("UICorner", TextButton).CornerRadius = UDim.new(0, 12)

RunService.RenderStepped:Connect(function()
    local inset = GuiService:GetGuiInset()
    TextButton.Position = UDim2.new(0, 150, 0, inset.Y - 58)
end)

-- STATES
local isWallHopEnabled = false
local isFlicking = false
local lastFlickTime = 0
local Camera = workspace.CurrentCamera

local isWallHopping = false

-- DOUBLE JUMP SISTEMA
local lastDoubleJump = 0
local DOUBLE_JUMP_COOLDOWN = 3
local BUFFER_TIME = 1.5

local bufferActive = false
local bufferStart = 0
local touchedGround = false

-- INDICADOR
local cooldownReadyShown = false

-- CHARACTER
local function setupCharacter(char)
    local hum = char:WaitForChild("Humanoid")

    hum.StateChanged:Connect(function(_, new)
        if new == Enum.HumanoidStateType.Landed then
            touchedGround = true
            bufferActive = false
        end

        if new == Enum.HumanoidStateType.Freefall then
            touchedGround = false
        end
    end)
end

if LocalPlayer.Character then
    setupCharacter(LocalPlayer.Character)
end
LocalPlayer.CharacterAdded:Connect(setupCharacter)

-- INDICADOR VISUAL (PULSO SUAVE)
RunService.Heartbeat:Connect(function()
    if not isWallHopEnabled then return end

    local now = tick()

    if now - lastDoubleJump >= DOUBLE_JUMP_COOLDOWN then
        if not cooldownReadyShown then
            cooldownReadyShown = true

            local originalColor = Color3.fromRGB(40,40,40)
            local greenColor = Color3.fromRGB(0,170,0)

            TextButton.BackgroundColor3 = greenColor

            local tween = TweenService:Create(
                TextButton,
                TweenInfo.new(0.5, Enum.EasingStyle.Quad, Enum.EasingDirection.Out),
                {BackgroundColor3 = originalColor}
            )

            tween:Play()
        end
    end
end)

-- DOUBLE JUMP INPUT
UserInputService.JumpRequest:Connect(function()
    if not isWallHopEnabled then return end

    local char = LocalPlayer.Character
    local hum = char and char:FindFirstChild("Humanoid")
    local hrp = char and char:FindFirstChild("HumanoidRootPart")
    if not hum or not hrp then return end

    local now = tick()

    if now - lastDoubleJump >= DOUBLE_JUMP_COOLDOWN then
        bufferActive = true
        bufferStart = now
    end

    local canUse = false

    if isWallHopping then
        canUse = true
    else
        if bufferActive and (now - bufferStart <= BUFFER_TIME) then
            if hrp.Velocity.Y < -1 and not touchedGround then
                canUse = true
            end
        end
    end

    if canUse then
        lastDoubleJump = now
        bufferActive = false
        cooldownReadyShown = false

        hrp.Velocity = Vector3.new(hrp.Velocity.X, 34.5, hrp.Velocity.Z)
        hum:ChangeState(Enum.HumanoidStateType.Jumping)

        task.delay(0.18, function()
            if hum then
                hum:ChangeState(Enum.HumanoidStateType.Freefall)
            end
        end)
    end
end)

-- FLICK
local function performVideoFlick()
    if isFlicking then return end
    isFlicking = true

    isWallHopping = true

    local char = LocalPlayer.Character
    local hum = char and char:FindFirstChild("Humanoid")
    local hrp = char and char:FindFirstChild("HumanoidRootPart")
    if not hum or not hrp then
        isFlicking = false
        return
    end

    hum:ChangeState(Enum.HumanoidStateType.Jumping)
    hrp.Velocity = Vector3.new(hrp.Velocity.X, 44.8, hrp.Velocity.Z)

    local startCFrame = Camera.CFrame
    local targetCFrame = startCFrame * CFrame.Angles(0, math.rad(45), 0)

    Camera.CFrame = targetCFrame
    task.wait(0.015)

    for i = 1, 5 do
        Camera.CFrame = targetCFrame:Lerp(startCFrame, i/5)
        task.wait(0.005)
    end

    task.delay(0.25, function()
        isWallHopping = false
    end)

    isFlicking = false
end

-- IGNORAR PLAYERS
local function isPlayerCharacter(instance)
    local model = instance:FindFirstAncestorOfClass("Model")
    return model and model:FindFirstChildOfClass("Humanoid")
end

-- WALL DETECT
local lastHitInstance = nil

RunService.Heartbeat:Connect(function()
    if not isWallHopEnabled then return end

    local char = LocalPlayer.Character
    local hrp = char and char:FindFirstChild("HumanoidRootPart")
    if not hrp then return end

    local params = RaycastParams.new()
    params.FilterDescendantsInstances = {char}
    params.FilterType = Enum.RaycastFilterType.Exclude

    local look = Camera.CFrame.LookVector
    local horizontal = Vector3.new(look.X, 0, look.Z).Unit
    local direction = horizontal * 3

    local offsets = {
        Vector3.new(0, -2.2, 0),
        Vector3.new(0, -1.2, 0),
        Vector3.new(0, -0.4, 0)
    }

    local result = nil

    for _, offset in ipairs(offsets) do
        local ray = workspace:Raycast(hrp.Position + offset, direction, params)
        if ray and ray.Instance and ray.Instance.CanCollide then
            if not isPlayerCharacter(ray.Instance) then
                result = ray
                break
            end
        end
    end

    if result then
        if lastHitInstance and lastHitInstance ~= result.Instance then
            if hrp.Velocity.Y < -1 and tick() - lastFlickTime > 0.07 then
                lastFlickTime = tick()
                performVideoFlick()
            end
        end
        lastHitInstance = result.Instance
    else
        lastHitInstance = nil
    end
end)

-- TOGGLE
TextButton.MouseButton1Click:Connect(function()
    isWallHopEnabled = not isWallHopEnabled
    TextButton.Text = isWallHopEnabled and "Wall Hop On" or "Wall Hop Off"
    TextButton.BackgroundColor3 = isWallHopEnabled and Color3.fromRGB(40,40,40) or Color3.fromRGB(0,0,0)
end)

print("WallHop Loaded (Pulso suave integrado)")
