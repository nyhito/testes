-- AUTO WALLHOP (FLICK DINÂMICO + PRIORIDADE DOUBLE JUMP NATIVO)

local Players = game:GetService("Players")
local LocalPlayer = Players.LocalPlayer
local RunService = game:GetService("RunService")
local GuiService = game:GetService("GuiService")

local Camera = workspace.CurrentCamera
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
local isWallHopping = false

-- DETECÇÃO DOUBLE JUMP NATIVO
local lastYVelocity = 0
local lastDoubleJumpTime = 0

local function didUseDoubleJump(currentY)
    -- detecta mudança brusca de queda pra subida
    if lastYVelocity < -2 and currentY > 8 then
        lastDoubleJumpTime = tick()
        return true
    end
    return false
end

local function shouldWaitForDoubleJump(hrp)
    -- se ainda está caindo pouco, pode ser timing do double jump
    return hrp.Velocity.Y > -6
end

-- CROUCH CHECK
local function isCrouching(hum, hrp)
    if not hum or not hrp then return false end
    local horizontalSpeed = Vector3.new(hrp.Velocity.X, 0, hrp.Velocity.Z).Magnitude
    return hum.WalkSpeed <= 9 and horizontalSpeed < 8
end

-- FLICK
local function performVideoFlick(hrp)
    if isFlicking then return end
    isFlicking = true
    isWallHopping = true

    local startCFrame = Camera.CFrame

    -- ajuste dinâmico baseado no ângulo vertical
    local lookY = startCFrame.LookVector.Y
    local verticalInfluence = math.clamp(math.abs(lookY), 0, 1)

    local baseAngle = 45
    local dynamicAngle = baseAngle * (1 - (verticalInfluence * 0.6))

    local flickRotation = CFrame.fromAxisAngle(startCFrame.UpVector, math.rad(dynamicAngle))
    local targetCFrame = flickRotation * startCFrame

    -- impulso SEM forçar estado
    hrp.Velocity = Vector3.new(hrp.Velocity.X, 44.8, hrp.Velocity.Z)

    local fastFlick = math.random() < 0.4

    Camera.CFrame = targetCFrame

    task.wait(fastFlick and 0.013 or 0.019)

    local steps = fastFlick and 4 or 6

    for i = 1, steps do
        local alpha = (i / steps) ^ (fastFlick and 1.8 or 2.2)
        Camera.CFrame = targetCFrame:Lerp(startCFrame, alpha)
        task.wait(fastFlick and 0.0045 or 0.0065)
    end

    task.delay(0.08, function()
        isWallHopping = false
    end)

    isFlicking = false
end

-- WALL DETECT
local lastHitInstance = nil

local function isPlayerCharacter(instance)
    if not instance then return false end
    local model = instance:FindFirstAncestorOfClass("Model")
    return model and model:FindFirstChildOfClass("Humanoid")
end

RunService.Heartbeat:Connect(function()
    if not isWallHopEnabled then return end

    local char = LocalPlayer.Character
    local hrp = char and char:FindFirstChild("HumanoidRootPart")
    local hum = char and char:FindFirstChild("Humanoid")

    if not hrp or not hum then return end
    if isCrouching(hum, hrp) then return end

    -- detectar double jump real
    didUseDoubleJump(hrp.Velocity.Y)

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
            
            -- ⛔ SEGURA SE ESTIVER NO TIMING DO DOUBLE JUMP
            if shouldWaitForDoubleJump(hrp) then
                return
            end

            -- ⚡ SE ACABOU DE USAR DOUBLE JUMP, APROVEITA
            local boostDelay = (tick() - lastDoubleJumpTime) < 0.2

            if hrp.Velocity.Y < -2.2 and tick() - lastFlickTime > (boostDelay and 0.03 or 0.085) then
                lastFlickTime = tick()
                performVideoFlick(hrp)
            end
        end

        lastHitInstance = result.Instance
    else
        lastHitInstance = nil
    end

    lastYVelocity = hrp.Velocity.Y
end)

-- TOGGLE
TextButton.MouseButton1Click:Connect(function()
    isWallHopEnabled = not isWallHopEnabled
    TextButton.Text = isWallHopEnabled and "Wall Hop On" or "Wall Hop Off"
    TextButton.BackgroundColor3 = isWallHopEnabled and Color3.fromRGB(40,40,40) or Color3.fromRGB(0,0,0)
end)

print("WallHop Loaded (Double Jump Integrado)")
