-- AUTO WALLHOP (ANTI-RECUO REAL + 90° DOMINANTE)

local Players = game:GetService("Players")
local LocalPlayer = Players.LocalPlayer
local RunService = game:GetService("RunService")
local GuiService = game:GetService("GuiService")
local UserInputService = game:GetService("UserInputService")

local PlayerGui = LocalPlayer:WaitForChild("PlayerGui")

-- UI
local ScreenGui = Instance.new("ScreenGui")
ScreenGui.Parent = PlayerGui

local TextButton = Instance.new("TextButton")
TextButton.Size = UDim2.new(0,140,0,50)
TextButton.Text = "Wall Hop Off"
TextButton.Parent = ScreenGui

RunService.RenderStepped:Connect(function()
    local inset = GuiService:GetGuiInset()
    TextButton.Position = UDim2.new(0,150,0,inset.Y-58)
end)

-- STATES
local enabled = false
local isFlicking = false
local Camera = workspace.CurrentCamera

-- FLICK
local function performVideoFlick()
    if isFlicking then return end
    isFlicking = true

    local char = LocalPlayer.Character
    local hum = char and char:FindFirstChild("Humanoid")
    local hrp = char and char:FindFirstChild("HumanoidRootPart")
    if not hum or not hrp then return end

    -- DIREÇÃO DO JOGADOR (ANTES DO FLICK)
    local moveDir = hum.MoveDirection
    local camDir = Vector3.new(Camera.CFrame.LookVector.X,0,Camera.CFrame.LookVector.Z).Unit

    local desiredDir = moveDir.Magnitude > 0 and moveDir.Unit or camDir
    local speed = Vector3.new(hrp.Velocity.X,0,hrp.Velocity.Z).Magnitude

    -- impulso
    hrp.Velocity = desiredDir * speed + Vector3.new(0,44.8,0)

    local oldAuto = hum.AutoRotate
    hum.AutoRotate = false

    -- ESCOLHA (90° MAIS COMUM)
    local roll = math.random()

    local values, timeMin, timeMax

    if roll < 0.7 then
        -- 90°
        if math.random() < 0.5 then
            values = {2500,2550,2600,2650,2700,2750,2800}
            timeMin, timeMax = 0.085, 0.115
        else
            values = {2700,2750,2800,2850,2900,2950,3000,3050,3100}
            timeMin, timeMax = 0.065, 0.085
        end
    else
        -- 80°
        if math.random() < 0.5 then
            values = {1500,1550,1600,1650,1700,1750,1800,1850,1900}
            timeMin, timeMax = 0.06, 0.09
        else
            values = {1800,1850,1900,1950,2000,2050,2100}
            timeMin, timeMax = 0.085, 0.115
        end
    end

    -- RANDOM CENTRALIZADO
    local function pick(vals)
        local mid = math.ceil(#vals/2)
        local total, w = 0, {}
        for i=1,#vals do
            local d = math.abs(i-mid)
            local weight = 1/(1+d^1.3)
            w[i]=weight
            total+=weight
        end
        local r = math.random()*total
        for i,val in ipairs(vals) do
            r-=w[i]
            if r<=0 then return val end
        end
        return vals[#vals]
    end

    local ang = pick(values)
    local flickTime = math.random()*(timeMax-timeMin)+timeMin

    hrp.AssemblyAngularVelocity = Vector3.new(0,math.rad(ang),0)

    -- ANTI-RECUO REAL
    local conn
    conn = RunService.Heartbeat:Connect(function()
        if not hrp then return end

        local y = hrp.Velocity.Y

        -- mantém direção ORIGINAL sempre
        hrp.Velocity = desiredDir * speed + Vector3.new(0,y,0)
    end)

    task.wait(flickTime)

    hrp.AssemblyAngularVelocity = Vector3.zero
    if conn then conn:Disconnect() end

    hum.AutoRotate = oldAuto
    isFlicking = false
end

-- TOGGLE
TextButton.MouseButton1Click:Connect(function()
    enabled = not enabled
    TextButton.Text = enabled and "Wall Hop On" or "Wall Hop Off"
end)

print("Loaded (90° dominante + sem recuo real)")
