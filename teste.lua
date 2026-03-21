local Players = game:GetService("Players")
local TextChatService = game:GetService("TextChatService")
local player = Players.LocalPlayer

-- Criar ScreenGui
local screenGui = Instance.new("ScreenGui")
screenGui.Name = "Dance2ButtonGui"
screenGui.Parent = player:WaitForChild("PlayerGui")

-- Botão circular moderno
local button = Instance.new("TextButton")
button.Size = UDim2.new(0, 70, 0, 70)
button.Position = UDim2.new(0.9, 0, 0.85, 0)
button.AnchorPoint = Vector2.new(0.5, 0.5)
button.BackgroundColor3 = Color3.fromRGB(0, 0, 0)
button.BorderColor3 = Color3.fromRGB(255, 255, 255)
button.BorderSizePixel = 2
button.Text = "D"
button.TextColor3 = Color3.fromRGB(255, 255, 255)
button.TextScaled = true
button.Font = Enum.Font.GothamBold

local corner = Instance.new("UICorner")
corner.CornerRadius = UDim.new(0.5, 0)
corner.Parent = button

button.Parent = screenGui

-- Função para enviar /e dance2 via TextChatService
local function sendDance2()
    local defaultChannel = TextChatService:FindFirstChild("General") or TextChatService:FindFirstChildOfClass("TextChatChannel")
    if defaultChannel then
        defaultChannel:SendAsync("/e dance2")
    else
        warn("Não foi possível enviar comando: canal de chat não encontrado")
    end
end

button.MouseButton1Click:Connect(sendDance2)
