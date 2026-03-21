-- LocalScript dentro de um ScreenGui
local Players = game:GetService("Players")
local player = Players.LocalPlayer
local playerGui = player:WaitForChild("PlayerGui")

-- Criando o Frame principal se ainda não existir
local screenGui = Instance.new("ScreenGui")
screenGui.Name = "DanceButtonGui"
screenGui.Parent = playerGui

-- Criando o botão circular
local button = Instance.new("TextButton")
button.Size = UDim2.new(0, 50, 0, 50) -- tamanho 50x50 pixels
button.Position = UDim2.new(0.9, 0, 0.8, 0) -- canto inferior direito
button.BackgroundColor3 = Color3.fromRGB(255, 100, 100)
button.Text = "D"
button.TextScaled = true
button.Font = Enum.Font.SourceSansBold
button.BorderSizePixel = 0
button.AutoButtonColor = true
button.AnchorPoint = Vector2.new(0.5, 0.5)
button.BackgroundTransparency = 0
button.TextColor3 = Color3.fromRGB(255,255,255)

-- Fazendo o botão parecer circular
button.ClipsDescendants = true
local uicorner = Instance.new("UICorner")
uicorner.CornerRadius = UDim.new(0.5, 0)
uicorner.Parent = button

button.Parent = screenGui

-- Função para executar o comando de dança
button.MouseButton1Click:Connect(function()
    game:GetService("ReplicatedStorage").DefaultChatSystemChatEvents.SayMessageRequest:FireServer("/e dance2", "All")
end)
