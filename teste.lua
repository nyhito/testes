-- LocalScript dentro de um ScreenGui
local Players = game:GetService("Players")
local player = Players.LocalPlayer
local playerGui = player:WaitForChild("PlayerGui")
local UserInputService = game:GetService("UserInputService")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

-- Criando ScreenGui
local screenGui = Instance.new("ScreenGui")
screenGui.Name = "FTFDanceButtonGui"
screenGui.Parent = playerGui

-- Criando botão moderno
local button = Instance.new("TextButton")
button.Size = UDim2.new(0,60,0,60)
button.Position = UDim2.new(0.9,0,0.85,0)
button.AnchorPoint = Vector2.new(0.5,0.5)
button.BackgroundColor3 = Color3.fromRGB(0,0,0)
button.Text = "💃"
button.TextScaled = true
button.Font = Enum.Font.GothamBold
button.TextColor3 = Color3.fromRGB(255,255,255)
button.BorderSizePixel = 0

local uicorner = Instance.new("UICorner")
uicorner.CornerRadius = UDim.new(0.5,0)
uicorner.Parent = button

local uistroke = Instance.new("UIStroke")
uistroke.Color = Color3.fromRGB(255,255,255)
uistroke.Thickness = 2
uistroke.Transparency = 0.7
uistroke.Parent = button

button.Parent = screenGui

-- Variáveis para arrastar
local dragging = false
local dragStartPos
local buttonStartPos
local holdTime = 1

button.InputBegan:Connect(function(input)
    if input.UserInputType == Enum.UserInputType.Touch then
        dragStartPos = input.Position
        buttonStartPos = Vector2.new(button.Position.X.Offset, button.Position.Y.Offset)
        local held = true
        
        task.spawn(function()
            task.wait(holdTime)
            if held then
                dragging = true
            end
        end)
        
        input.Changed:Connect(function()
            if input.UserInputState == Enum.UserInputState.End then
                if dragging then
                    dragging = false
                else
                    -- clique curto: envia o comando de dança
                    pcall(function()
                        ReplicatedStorage.DefaultChatSystemChatEvents.SayMessageRequest:FireServer("/e dance","All")
                    end)
                end
                held = false
            end
        end)
    end
end)

button.InputChanged:Connect(function(input)
    if input.UserInputType == Enum.UserInputType.Touch then
        input.Changed:Connect(function()
            if dragging and input.UserInputState == Enum.UserInputState.Change then
                local delta = input.Position - dragStartPos
                button.Position = UDim2.new(
                    0,
                    math.clamp(buttonStartPos.X + delta.X, 0, workspace.CurrentCamera.ViewportSize.X - button.AbsoluteSize.X),
                    0,
                    math.clamp(buttonStartPos.Y + delta.Y, 0, workspace.CurrentCamera.ViewportSize.Y - button.AbsoluteSize.Y)
                )
            end
        end)
    end
end)
