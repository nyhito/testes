local Workspace = game:GetService("Workspace")

-- Função para checar se a cor é verde aproximada
local function isGreen(part)
    local color = part.Color
    return color.G > color.R and color.G > color.B -- Verde dominante
end

-- Função para checar se é um tronco marrom
local function isBrownTrunk(part)
    local color = part.Color
    return color.R > 0.3 and color.G > 0.15 and color.B < 0.1 -- aproximação marrom
        and part.Size.Y > 2 -- vertical alto
end

-- Loop por todas as partes do mapa
for _, part in pairs(Workspace:GetDescendants()) do
    if part:IsA("BasePart") then
        -- Sem colisão
        if not part.CanCollide then
            -- Verde direto
            if isGreen(part) then
                part:Destroy()
            else
                -- Quadrado sobre tronco
                local aboveTrunk = false
                for _, checkPart in pairs(Workspace:GetDescendants()) do
                    if checkPart:IsA("BasePart") and isBrownTrunk(checkPart) then
                        -- checa se part está em cima do tronco (aproximação)
                        local dx = math.abs(part.Position.X - checkPart.Position.X)
                        local dz = math.abs(part.Position.Z - checkPart.Position.Z)
                        local dy = part.Position.Y - (checkPart.Position.Y + checkPart.Size.Y/2)
                        if dx < checkPart.Size.X/2 and dz < checkPart.Size.Z/2 and dy > 0 and dy < 10 then
                            aboveTrunk = true
                            break
                        end
                    end
                end
                if aboveTrunk then
                    part:Destroy()
                end
            end
        end
    end
end
