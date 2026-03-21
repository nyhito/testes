-- LocalScript dentro de um ScreenGui
local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local UserInputService = game:GetService("UserInputService")
local player = Players.LocalPlayer

-- Criar ScreenGui
local screenGui = Instance.new("ScreenGui")
screenGui.Name = "Dance2GUI"
screenGui.Parent = player:WaitForChild("PlayerGui")

-- Criar botão moderno
local button = Instance.new("TextButton")
button.Size = UDim2.new(0, 60, 0, 60)
button.Position = UDim2.new(0.9, 0, 0.85, 0)
button.AnchorPoint = Vector2.new(0.5, 0.5)
button.Text = "💃"
button.TextScaled = true
button.Font = Enum.Font.GothamBold
button.TextColor3 = Color3.fromRGB(255, 255, 255)
button.BackgroundColor3 = Color3.fromRGB(0, 0, 0)
button.BorderSizePixel = 0
button.AutoButtonColor = false
button.ClipsDescendants = true

-- Sombra elegante
local shadow = Instance.new("UIStroke")
shadow.Color = Color3.fromRGB(255, 255, 255)
shadow.Thickness = 2
shadow.Transparency = 0.7
shadow.Parent = button

-- Borda arredondada
local corner = Instance.new("UICorner")
corner.CornerRadius = UDim.new(0.5, 0)
corner.Parent = button

button.Parent = screenGui

-- Variáveis de arraste
local dragging = false
local dragStartPos
local startPos
local holdTime = 1

button.InputBegan:Connect(function(input)
    if input.UserInputType == Enum.UserInputType.Touch or input.UserInputType == Enum.UserInputType.MouseButton1 then
        dragStartPos = input.Position
        startPos = button.Position
        local held = true

        -- Segurar 1s para arrastar
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
                    -- Clique curto: envia /e dance2 via chat
                    pcall(function()
                        ReplicatedStorage.DefaultChatSystemChatEvents.SayMessageRequest:FireServer("/e dance2", "All")
                    end)
                end
                held = false
            end
        end)
    end
end)

-- Movimentação do botão
button.InputChanged:Connect(function(input)
    if input.UserInputType == Enum.UserInputType.Touch or input.UserInputType == Enum.UserInputType.MouseMovement then
        input.Changed:Connect(function()
            if dragging and input.UserInputState == Enum.UserInputState.Change then
                local delta = input.Position - dragStartPos
                button.Position = UDim2.new(
                    0,
                    math.clamp(startPos.X.Offset + delta.X, 0, workspace.CurrentCamera.ViewportSize.X - button.AbsoluteSize.X),
                    0,
                    math.clamp(startPos.Y.Offset + delta.Y, 0, workspace.CurrentCamera.ViewportSize.Y - button.AbsoluteSize.Y)
                )
            end
        end)
    end
end)
