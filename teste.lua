-- LocalScript: Wallhop View otimizado para FTF Practice
local Players = game:GetService("Players")
local RunService = game:GetService("RunService")
local Camera = workspace.CurrentCamera
local LocalPlayer = Players.LocalPlayer

-- Configurações
local LineColor = Color3.new(1,1,1) -- branco
local LineThickness = 2

-- Tabela de linhas ativas
local activeLines = {}

-- Função para criar linha 2D
local function CreateLine(startPos, endPos)
    local line = Drawing.new("Line")
    line.From = startPos
    line.To = endPos
    line.Color = LineColor
    line.Thickness = LineThickness
    line.Transparency = 1
    return line
end

-- Lista de partes relevantes (paredes, plataformas, chão)
local function GetRelevantParts()
    local parts = {}
    for _, part in pairs(workspace:GetDescendants()) do
        if part:IsA("BasePart") and part.Anchored and part.CanCollide then
            if part.Size.Magnitude > 2 then -- filtra peças muito pequenas que não importam
                table.insert(parts, part)
            end
        end
    end
    return parts
end

-- Função que cria linhas para as arestas da peça
local function DrawEdges(part)
    local corners = {
        part.Position + Vector3.new(part.Size.X/2, part.Size.Y/2, part.Size.Z/2),
        part.Position + Vector3.new(-part.Size.X/2, part.Size.Y/2, part.Size.Z/2),
        part.Position + Vector3.new(part.Size.X/2, -part.Size.Y/2, part.Size.Z/2),
        part.Position + Vector3.new(-part.Size.X/2, -part.Size.Y/2, part.Size.Z/2),
        part.Position + Vector3.new(part.Size.X/2, part.Size.Y/2, -part.Size.Z/2),
        part.Position + Vector3.new(-part.Size.X/2, part.Size.Y/2, -part.Size.Z/2),
        part.Position + Vector3.new(part.Size.X/2, -part.Size.Y/2, -part.Size.Z/2),
        part.Position + Vector3.new(-part.Size.X/2, -part.Size.Y/2, -part.Size.Z/2),
    }

    local edges = {
        {1,2},{1,3},{1,5},{2,4},{2,6},{3,4},{3,7},{4,8},
        {5,6},{5,7},{6,8},{7,8}
    }

    local lineObjects = {}
    for _, e in pairs(edges) do
        local screenStart, onScreen1 = Camera:WorldToViewportPoint(corners[e[1]])
        local screenEnd, onScreen2 = Camera:WorldToViewportPoint(corners[e[2]])
        if onScreen1 or onScreen2 then -- só desenha se visível
            local line = CreateLine(Vector2.new(screenStart.X, screenStart.Y), Vector2.new(screenEnd.X, screenEnd.Y))
            table.insert(lineObjects, line)
        end
    end
    return lineObjects
end

-- Atualiza linhas a cada frame
RunService.RenderStepped:Connect(function()
    -- Apaga linhas antigas
    for _, line in pairs(activeLines) do
        line:Remove()
    end
    activeLines = {}

    local parts = GetRelevantParts()
    for _, part in pairs(parts) do
        local lines = DrawEdges(part)
        for _, l in pairs(lines) do
            table.insert(activeLines, l)
        end
    end
end)
