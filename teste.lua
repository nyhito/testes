-- CCF Parts (remove objetos visuais sem colisão)

for _, v in pairs(workspace:GetDescendants()) do
    if v:IsA("BasePart") then
        
        -- remove partes sem colisão (folhas, efeitos, etc)
        if v.CanCollide == false then
            v.Transparency = 1
        end
        
        -- remove também texturas dentro delas
        for _, child in pairs(v:GetChildren()) do
            if child:IsA("Decal") or child:IsA("Texture") then
                child.Transparency = 1
            end
        end
    end
end

print("CCF Parts aplicado")
