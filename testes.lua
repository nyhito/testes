-- AUTO WALLHOP + DOUBLE JUMP (REFINADO + FLICK ORIGINAL COMPLETO)

local Players = game:GetService("Players")
local LocalPlayer = Players.LocalPlayer
local RunService = game:GetService("RunService")
local GuiService = game:GetService("GuiService")
local UserInputService = game:GetService("UserInputService")

local PlayerGui = LocalPlayer:WaitForChild("PlayerGui")

-- UI
local ScreenGui = Instance.new("ScreenGui")
ScreenGui.Parent = PlayerGui
ScreenGui.ResetOnSpawn = false

local TextButton = Instance.new("TextButton")
TextButton.Size = UDim2.new(0,140,0,50)
TextButton.BackgroundColor3 = Color3.fromRGB(0,0,0)
TextButton.Text = "Wall Hop Off"
TextButton.TextColor3 = Color3.fromRGB(255,255,255)
TextButton.Font = Enum.Font.GothamBold
TextButton.TextScaled = true
TextButton.Parent = ScreenGui
Instance.new("UICorner", TextButton)

RunService.RenderStepped:Connect(function()
    local inset = GuiService:GetGuiInset()
    TextButton.Position = UDim2.new(0,150,0,inset.Y - 58)
end)

-- STATES
local isWallHopEnabled = false
local lastFlickTime = 0
local lastWallHopTime = 0
local lastNormal = nil
local Camera = workspace.CurrentCamera

local canDoubleJump = false
local lastDoubleJump = 0
local blockDoubleJump = false

-- CHARACTER SETUP
local function setupCharacter(char)
    local hum = char:WaitForChild("Humanoid")
    hum.StateChanged:Connect(function(_, new)
        if new == Enum.HumanoidStateType.Freefall then
            canDoubleJump = true
        elseif new == Enum.HumanoidStateType.Landed then
            canDoubleJump = false
        end
    end)
end

if LocalPlayer.Character then setupCharacter(LocalPlayer.Character) end
LocalPlayer.CharacterAdded:Connect(setupCharacter)

-- DOUBLE JUMP
UserInputService.JumpRequest:Connect(function()
    if not isWallHopEnabled or blockDoubleJump then return end
    local char = LocalPlayer.Character
    local hum = char and char:FindFirstChild("Humanoid")
    local hrp = char and char:FindFirstChild("HumanoidRootPart")
    if not hum or not hrp then return end

    if tick() - lastWallHopTime > 1.5 then return end

    if canDoubleJump and tick() - lastDoubleJump > 3 then
        lastDoubleJump = tick()
        canDoubleJump = false

        hrp.Velocity = Vector3.new(hrp.Velocity.X, 34.5, hrp.Velocity.Z)
        hum:ChangeState(Enum.HumanoidStateType.Jumping)

        task.delay(0.18,function()
            if hum then hum:ChangeState(Enum.HumanoidStateType.Freefall) end
        end)
    end
end)

-- FLICK COMPLETO
local lastFlickAngle = nil
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

local function flick(hrp, hum)
    lastWallHopTime = tick()
    blockDoubleJump = true

    hrp.Velocity = Vector3.new(hrp.Velocity.X, 44.8, hrp.Velocity.Z)
    hum:ChangeState(Enum.HumanoidStateType.Jumping)

    local baseYaw = hrp.Orientation.Y
    local angle = pickNextFlick()
    local steps = math.random(7,9)
    local baseDelay = 0.01

    local overshoot = math.rad(math.random(20,30))
    local useOvershoot = math.random() < 0.9

    for i = 1, steps do
        local alpha = i / steps
        local curve

        if alpha <= 0.6 then
            curve = math.sin((alpha / 0.6) * (math.pi/2))
        else
            curve = math.sin(((1 - alpha) / 0.4) * (math.pi/2))
        end

        local offset = angle * curve
        hrp.CFrame = CFrame.new(hrp.Position) * CFrame.Angles(0, math.rad(baseYaw) + offset, 0)

        RunService.RenderStepped:Wait()
        task.wait(baseDelay)
    end

    if useOvershoot then
        task.delay(0.05, function()
            local smallSteps = 4

            for i = 1, smallSteps do
                local alpha = i / smallSteps
                local offset = -overshoot * alpha
                hrp.CFrame = CFrame.new(hrp.Position) * CFrame.Angles(0, math.rad(baseYaw) + offset, 0)
                RunService.RenderStepped:Wait()
                task.wait(baseDelay)
            end

            for i = 1, smallSteps do
                local alpha = i / smallSteps
                local offset = -overshoot * (1 - alpha)
                hrp.CFrame = CFrame.new(hrp.Position) * CFrame.Angles(0, math.rad(baseYaw) + offset, 0)
                RunService.RenderStepped:Wait()
                task.wait(baseDelay)
            end

            hrp.CFrame = CFrame.new(hrp.Position) * CFrame.Angles(0, math.rad(baseYaw), 0)
        end)
    end

    hrp.CFrame = CFrame.new(hrp.Position) * CFrame.Angles(0, math.rad(baseYaw), 0)

    hum:ChangeState(Enum.HumanoidStateType.Freefall)

    task.delay(0.05, function() blockDoubleJump = false end)
end

-- WALL DETECT REFINADO
RunService.Heartbeat:Connect(function()
    if not isWallHopEnabled then return end

    local char = LocalPlayer.Character
    local hrp = char and char:FindFirstChild("HumanoidRootPart")
    local hum = char and char:FindFirstChild("Humanoid")
    if not hrp or not hum then return end

    local params = RaycastParams.new()
    params.FilterDescendantsInstances = {char}
    params.FilterType = Enum.RaycastFilterType.Exclude

    local look = Camera.CFrame.LookVector
    local horizontal = Vector3.new(look.X,0,look.Z)
    if horizontal.Magnitude > 0 then horizontal = horizontal.Unit end

    local direction = horizontal * 1.55
    local offsets = {
        Vector3.new(0,-2.2,0),
        Vector3.new(0,-1.2,0),
        Vector3.new(0,-0.4,0)
    }

    for _,offset in ipairs(offsets) do
        local ray = workspace:Raycast(hrp.Position + offset, direction, params)
        if ray and ray.Instance and ray.Instance.CanCollide then

            local dot = ray.Normal:Dot(horizontal * -1)

            if dot > 0.7 and math.abs(ray.Normal.Y) < 0.15 then

                if lastNormal and (ray.Normal - lastNormal).Magnitude < 0.1 then
                    return
                end

                if tick() - lastFlickTime < 0.12 then return end

                if hrp.Velocity.Y < -2 then
                    lastFlickTime = tick()
                    lastNormal = ray.Normal
                    flick(hrp, hum)
                end
            end
        end
    end
end)

-- TOGGLE
TextButton.MouseButton1Click:Connect(function()
    isWallHopEnabled = not isWallHopEnabled
    TextButton.Text = isWallHopEnabled and "Wall Hop On" or "Wall Hop Off"
end)

print("WallHop Loaded (refinado + flick completo)")
