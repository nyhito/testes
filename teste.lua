-- AUTO WALLHOP + DOUBLE JUMP (FLICK HARD LOCK + RANDOM AVANÇADO)

local Players = game:GetService("Players")
local LocalPlayer = Players.LocalPlayer
local RunService = game:GetService("RunService")
local GuiService = game:GetService("GuiService")
local UserInputService = game:GetService("UserInputService")

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

local lastWallHopTime = 0
local WALLHOP_GRACE_TIME = 1.5

-- DOUBLE JUMP
local canDoubleJump = false
local lastDoubleJump = 0
local DOUBLE_JUMP_COOLDOWN = 3

local function isCrouching(hum, hrp)
    if not hum or not hrp then return false end
    local horizontalSpeed = Vector3.new(hrp.Velocity.X, 0, hrp.Velocity.Z).Magnitude
    return hum.WalkSpeed <= 9 and horizontalSpeed < 8
end

local function setupCharacter(char)
    local hum = char:WaitForChild("Humanoid")

    hum.StateChanged:Connect(function(_, new)
        if new == Enum.HumanoidStateType.Freefall then
            canDoubleJump = true
        end
        if new == Enum.HumanoidStateType.Landed then
            canDoubleJump = false
        end
    end)
end

if LocalPlayer.Character then
    setupCharacter(LocalPlayer.Character)
end
LocalPlayer.CharacterAdded:Connect(setupCharacter)

-- DOUBLE JUMP
UserInputService.JumpRequest:Connect(function()
    if not isWallHopEnabled then return end

    local char = LocalPlayer.Character
    local hum = char and char:FindFirstChild("Humanoid")
    local hrp = char and char:FindFirstChild("HumanoidRootPart")
    if not hum or not hrp then return end

    local stillValid = isWallHopping or (tick() - lastWallHopTime <= WALLHOP_GRACE_TIME)
    if not stillValid then return end

    if canDoubleJump and tick() - lastDoubleJump > DOUBLE_JUMP_COOLDOWN then
        lastDoubleJump = tick()
        canDoubleJump = false

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
    lastWallHopTime = tick()

    local char = LocalPlayer.Character
    local hum = char and char:FindFirstChild("Humanoid")
    local hrp = char and char:FindFirstChild("HumanoidRootPart")
    if not hum or not hrp then
        isFlicking = false
        return
    end

    -- direção original
    local originalVel = hrp.Velocity
    local horizontal = Vector3.new(originalVel.X, 0, originalVel.Z)
    local speed = horizontal.Magnitude
    local direction = speed > 0 and horizontal.Unit or Vector3.zero

    -- impulso
    hum:ChangeState(Enum.HumanoidStateType.Jumping)
    hrp.Velocity = Vector3.new(originalVel.X, 44.8, originalVel.Z)

    local oldAutoRotate = hum.AutoRotate
    hum.AutoRotate = false

    -- RANDOM VELOCITY (1500–2000, sino)
    local possibleValues = {1500,1550,1600,1650,1700,1750,1800,1850,1900,1950,2000}

    local function getRandomAngularVelocity()
        local weights = {}
        local totalWeight = 0
        local mid = math.ceil(#possibleValues/2)

        for i = 1, #possibleValues do
            local d = math.abs(i - mid)
            local w = 1 / (1 + d^1.3)
            weights[i] = w
            totalWeight += w
        end

        local r = math.random() * totalWeight
        for i, w in ipairs(weights) do
            r -= w
            if r <= 0 then
                return possibleValues[i]
            end
        end

        return possibleValues[#possibleValues]
    end

    -- RANDOM TIME (0.015–0.08, sino)
    local possibleTimes = {0.015,0.02,0.025,0.03,0.035,0.04,0.045,0.05,0.06,0.07,0.08}

    local function getRandomTime()
        local weights = {}
        local totalWeight = 0
        local mid = math.ceil(#possibleTimes/2)

        for i = 1, #possibleTimes do
            local d = math.abs(i - mid)
            local w = 1 / (1 + d^1.4)
            weights[i] = w
            totalWeight += w
        end

        local r = math.random() * totalWeight
        for i, w in ipairs(weights) do
            r -= w
            if r <= 0 then
                return possibleTimes[i]
            end
        end

        return possibleTimes[#possibleTimes]
    end

    -- normal da parede
    local wallNormal = nil
    do
        local params = RaycastParams.new()
        params.FilterDescendantsInstances = {char}
        params.FilterType = Enum.RaycastFilterType.Exclude

        local look = Camera.CFrame.LookVector
        local horizontalLook = Vector3.new(look.X, 0, look.Z).Unit

        local ray = workspace:Raycast(hrp.Position, horizontalLook * 2, params)
        if ray then
            wallNormal = ray.Normal
        end
    end

    hrp.AssemblyAngularVelocity = Vector3.new(0, math.rad(getRandomAngularVelocity()), 0)

    -- HARD LOCK
    local connection
    connection = RunService.Heartbeat:Connect(function()
        if not hrp or not hrp.Parent then
            if connection then connection:Disconnect() end
            return
        end

        local currentY = hrp.Velocity.Y
        local finalDir = direction

        if wallNormal then
            finalDir = (direction - wallNormal * 0.25).Unit
        end

        hrp.Velocity = finalDir * speed + Vector3.new(0, currentY, 0)
    end)

    local flickTime = getRandomTime()
    task.wait(flickTime)

    hrp.AssemblyAngularVelocity = Vector3.zero

    if connection then
        connection:Disconnect()
    end

    local currentY = hrp.Velocity.Y
    hrp.Velocity = direction * speed + Vector3.new(0, currentY, 0)

    hum.AutoRotate = oldAutoRotate

    task.delay(0.1, function()
        if hum and hum:GetState() == Enum.HumanoidStateType.Jumping then
            hum:ChangeState(Enum.HumanoidStateType.Freefall)
        end
    end)

    task.delay(0.25, function()
        isWallHopping = false
    end)

    isFlicking = false
end

-- WALL DETECT
local lastHitInstance = nil

local function isPlayerCharacter(instance)
    if not instance then return false end
    local model = instance:FindFirstAncestorOfClass("Model")
    if model and model:FindFirstChildOfClass("Humanoid") then
        return true
    end
    return false
end

RunService.Heartbeat:Connect(function()
    if not isWallHopEnabled then return end

    local char = LocalPlayer.Character
    local hrp = char and char:FindFirstChild("HumanoidRootPart")
    local hum = char and char:FindFirstChild("Humanoid")
    if not hrp or not hum then return end

    if isCrouching(hum, hrp) then return end

    local params = RaycastParams.new()
    params.FilterDescendantsInstances = {char}
    params.FilterType = Enum.RaycastFilterType.Exclude

    local look = Camera.CFrame.LookVector
    local horizontal = Vector3.new(look.X, 0, look.Z)

    if horizontal.Magnitude > 0 then
        horizontal = horizontal.Unit
    end

    local direction = horizontal * 1.55
    local result = nil

    local offsets = {
        Vector3.new(0, -2.2, 0),
        Vector3.new(0, -1.2, 0),
        Vector3.new(0, -0.4, 0)
    }

    for _, offset in ipairs(offsets) do
        local origin = hrp.Position + offset
        local ray = workspace:Raycast(origin, direction, params)

        if ray and ray.Instance and ray.Instance.CanCollide then
            if not isPlayerCharacter(ray.Instance) then
                result = ray
                break
            end
        end
    end

    if result and result.Instance then
        if lastHitInstance and lastHitInstance ~= result.Instance then
            if hrp.Velocity.Y < -2.2 and tick() - lastFlickTime > 0.085 then
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

print("WallHop Loaded (zero recuo + random avançado)")
