-- remover folhas "ccf" (100% seguro)

for _, v in pairs(workspace:GetDescendants()) do
    if v:IsA("BasePart") then
        if string.find(string.lower(v.Name), "ccf") then
            v.Transparency = 1
            v.CanCollide = false
        end
    end
end
