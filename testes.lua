-- (Wallhop Humanoid Type - Made by NT)

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
local WALLHOP_COOLDOWN = 0.18

-- DOUBLE JUMP
local canDoubleJump = false
local lastDoubleJump = 0
local DOUBLE_JUMP_COOLDOWN = 3
local blockDoubleJump = false

-- TRACKER
local scriptDoubleJumpUses = 0
local rechargeNotifyId = 0

local function isCrouching(hum, hrp)
    if not hum or not hrp then return false end
    local horizontalSpeed = Vector3.new(hrp.Velocity.X, 0, hrp.Velocity.Z).Magnitude
    return hum.WalkSpeed <= 9 and horizontalSpeed < 8
end

-- ANIMAÇÃO LEVE
local function playGemRechargeAnimation()
    local char = LocalPlayer.Character
    local hum = char and char:FindFirstChild("Humanoid")
    if not hum then return end

    local originalOffset = hum.CameraOffset

    for i = 1, 4 do
        local a = i / 4
        hum.CameraOffset = originalOffset + Vector3.new(0.02 * a, 0.01 * a, 0)
        RunService.RenderStepped:Wait()
    end

    for i = 1, 6 do
        local a = i / 6
        hum.CameraOffset = originalOffset + Vector3.new(0.02 * (1 - a), 0.01 * (1 - a), 0)
        RunService.RenderStepped:Wait()
    end

    hum.CameraOffset = originalOffset
end

-- EFEITO AZUL NOVO
local function playGemReadyEffect()
    local char = LocalPlayer.Character
    if not char then return end

    local hrp = char:FindFirstChild("HumanoidRootPart")
    if not hrp then return end

    local old = char:FindFirstChild("GemReadyEffectTemp")
    if old then old:Destroy() end

    local oldLight = hrp:FindFirstChild("GemReadyBlueLight")
    if oldLight then oldLight:Destroy() end

    local holder = Instance.new("BillboardGui")
    holder.Name = "GemReadyEffectTemp"
    holder.Size = UDim2.new(0, 110, 0, 110)
    holder.StudsOffset = Vector3.new(1.45, 0.25, 0)
    holder.AlwaysOnTop = true
    holder.LightInfluence = 0
    holder.Adornee = hrp
    holder.Parent = char

    local ring = Instance.new("Frame")
    ring.AnchorPoint = Vector2.new(0.5, 0.5)
    ring.Position = UDim2.new(0.5, 0, 0.5, 0)
    ring.Size = UDim2.new(0, 18, 0, 18)
    ring.BackgroundTransparency = 1
    ring.Parent = holder

    local corner = Instance.new("UICorner")
    corner.CornerRadius = UDim.new(1, 0)
    corner.Parent = ring

    local stroke = Instance.new("UIStroke")
    stroke.Thickness = 3
    stroke.Transparency = 1
    stroke.Color = Color3.fromRGB(0, 170, 255)
    stroke.Parent = ring

    local fill = Instance.new("Frame")
    fill.AnchorPoint = Vector2.new(0.5, 0.5)
    fill.Position = UDim2.new(0.5, 0, 0.5, 0)
    fill.Size = UDim2.new(0, 10, 0, 10)
    fill.BackgroundColor3 = Color3.fromRGB(80, 200, 255)
    fill.BackgroundTransparency = 1
    fill.BorderSizePixel = 0
    fill.Parent = holder

    local fillCorner = Instance.new("UICorner")
    fillCorner.CornerRadius = UDim.new(1, 0)
    fillCorner.Parent = fill

    local light = Instance.new("PointLight")
    light.Name = "GemReadyBlueLight"
    light.Color = Color3.fromRGB(0, 170, 255)
    light.Range = 0
    light.Brightness = 0
    light.Parent = hrp

    for i = 1, 8 do
        local a = i / 8

        ring.Size = UDim2.new(0, 18 + 42 * a, 0, 18 + 42 * a)
        stroke.Transparency = 1 - (0.8 * a)

        fill.Size = UDim2.new(0, 10 + 18 * a, 0, 10 + 18 * a)
        fill.BackgroundTransparency = 1 - (0.7 * a)

        light.Range = 2 + 8 * a
        light.Brightness = 0.4 + 1.8 * a

        RunService.RenderStepped:Wait()
    end

    task.wait(0.05)

    for i = 1, 10 do
        local a = i / 10

        ring.Size = UDim2.new(0, 60 + 34 * a, 0, 60 + 34 * a)
        stroke.Transparency = 0.2 + (0.8 * a)

        fill.Size = UDim2.new(0, 28 + 18 * a, 0, 28 + 18 * a)
        fill.BackgroundTransparency = 0.3 + (0.7 * a)

        light.Range = 10 - 6 * a
        light.Brightness = 2.2 - 2 * a

        RunService.RenderStepped:Wait()
    end

    if holder then holder:Destroy() end
    if light then light:Destroy() end
end

local function scheduleScriptRechargeNotice()
    rechargeNotifyId += 1
    local myId = rechargeNotifyId

    task.delay(DOUBLE_JUMP_COOLDOWN, function()
        if myId ~= rechargeNotifyId then return end
        if not isWallHopEnabled then return end

        task.spawn(playGemReadyEffect)
        task.spawn(playGemRechargeAnimation)
    end)
end

local function setupCharacter(char)
    local hum = char:WaitForChild("Humanoid")

    canDoubleJump = false
    blockDoubleJump = false
    scriptDoubleJumpUses = 0
    rechargeNotifyId = 0

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
    if not isWallHopEnabled or blockDoubleJump then return end

    local char = LocalPlayer.Character
    local hum = char and char:FindFirstChild("Humanoid")
    local hrp = char and char:FindFirstChild("HumanoidRootPart")
    if not hum or not hrp then return end

    local stillValid = isWallHopping or (tick() - lastWallHopTime <= WALLHOP_GRACE_TIME)
    if not stillValid then return end

    if canDoubleJump and tick() - lastDoubleJump > DOUBLE_JUMP_COOLDOWN then
        lastDoubleJump = tick()
        canDoubleJump = false
        scriptDoubleJumpUses += 1

        -- AGORA FUNCIONA DESDE O PRIMEIRO
        if scriptDoubleJumpUses >= 1 then
            scheduleScriptRechargeNotice()
        end

        hrp.Velocity = Vector3.new(hrp.Velocity.X, 30, hrp.Velocity.Z)
        hum:ChangeState(Enum.HumanoidStateType.Jumping)

        task.delay(0.18, function()
            if hum and hum.Parent then
                hum:ChangeState(Enum.HumanoidStateType.Freefall)
            end
        end)
    end
end)

-- resto do script (wallhop, flick, etc) permanece IGUAL
print("Humanoid Wallhop - Loaded Successfully ✅")
