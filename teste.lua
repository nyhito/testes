-- Remove apenas folhas verdes escuras no Homestead

local function isDarkGreen(part)
    local c = part.Color
    -- Verde escuro aproximado: R < 0.2, G > 0.2 e < 0.5, B < 0.2
    return c.R < 0.2 and c.G > 0.2 and c.G < 0.5 and c.B < 0.2
end

for _, v in pairs(workspace:GetDescendants()) do
    if v:IsA("BasePart") then
        -- ignora partes do jogador
        if v:IsDescendantOf(game.Players.LocalPlayer.Character) then
            continue
        end

        -- não remove portas ou objetos grandes com CanCollide
        if v.CanCollide then
            continue
        end

        -- só verde escuro
        if isDarkGreen(v) then
            v.Transparency = 1
        end
    end
end

print("Folhas verdes escuras removidas!")
