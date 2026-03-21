local Players = game:GetService("Players")
local RunService = game:GetService("RunService")
local LocalPlayer = Players.LocalPlayer
local Camera = workspace.CurrentCamera

local LineColor = Color3.fromRGB(255,255,255)
local LineThickness = 0.07
local RayDistance = 4 -- distância da parede (igual alcance de wallhop)

-- pool
local line = Instance.new("Part")
line.Anchored = true
line.CanCollide = false
line.Material = Enum.Material.Neon
line.Color = LineColor
line.Name = "WallhopLine"
line.Parent = workspace

local function update()
    local char = LocalPlayer.Character
    if not char or not char:FindFirstChild("HumanoidRootPart") then
        line.Transparency = 1
        return
    end

    local root = char.HumanoidRootPart

    -- direção baseada na câmera (igual player real)
    local direction = Camera.CFrame.LookVector * RayDistance

    local params = RaycastParams.new()
    params.FilterDescendantsInstances = {char}
    params.FilterType = Enum.RaycastFilterType.Blacklist

    local result = workspace:Raycast(root.Position, direction, params)

    if result and result.Instance then
        local hitPart = result.Instance

        -- ponto real de contato
        local hitPos = result.Position

        -- checa altura de wallhop
        local topY = hitPart.Position.Y + hitPart.Size.Y/2
        if topY > root.Position.Y + 5 then
            line.Transparency = 1
            return
        end

        -- largura da linha baseada na parede
        local size = hitPart.Size

        -- direção lateral da parede
        local right = Vector3.new(direction.Z, 0, -direction.X).Unit

        local p1 = hitPos + right * (size.X/2)
        local p2 = hitPos - right * (size.X/2)

        local dist = (p1 - p2).Magnitude

        line.Size = Vector3.new(dist, LineThickness, LineThickness)
        line.CFrame = CFrame.new((p1 + p2)/2, p2)
        line.Transparency = 0
    else
        line.Transparency = 1
    end
end

RunService.RenderStepped:Connect(update)
