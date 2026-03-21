-- LocalScript dentro de um ScreenGui

local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local player = Players.LocalPlayer

-- Criar GUI
local screenGui = Instance.new("ScreenGui")
screenGui.Name = "Dance2Button"
screenGui.Parent = player:WaitForChild("PlayerGui")

-- Botão circular moderno
local button = Instance.new("TextButton")
button.Size = UDim2.new(0, 60, 0, 60)
button.Position = UDim2.new(0.9, 0, 0.85, 0)
button.AnchorPoint = Vector2.new(0.5, 0.5)
button.BackgroundColor3 = Color3.fromRGB(0,0,0)
button.BorderColor3 = Color3.fromRGB(255,255,255)
button.BorderSizePixel = 2
button.Text = "D"
button.TextColor3 = Color3.fromRGB(255,255,255)
button.TextScaled = true
button.Font = Enum.Font.GothamBold

local corner = Instance.new("UICorner")
corner.CornerRadius = UDim.new(0.5,0)
corner.Parent = button

button.Parent = screenGui

-- Função para localizar evento de chat
local function findChatEvent(parent)
    for _, obj in ipairs(parent:GetChildren()) do
        if obj:IsA("RemoteEvent") and obj.Name:lower():find("say") then
            return obj
        elseif #obj:GetChildren() > 0 then
            local found = findChatEvent(obj)
            if found then return found end
        end
    end
    return nil
end

-- Detectar evento de chat no ReplicatedStorage
local chatEvent = findChatEvent(ReplicatedStorage)

if not chatEvent then
    warn("Não foi possível localizar o evento de chat para enviar /e dance2")
end

-- Função que envia /e dance2
local function sendDance2()
    if chatEvent then
        chatEvent:FireServer("/e dance2","All")
    else
        warn("Evento de chat não encontrado, /e dance2 não enviado")
    end
end

-- Conectar clique do botão
button.MouseButton1Click:Connect(sendDance2)
