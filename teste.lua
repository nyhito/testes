-- FLICK VISUAL (SEM MEXER NA CÂMERA)
local function performVideoFlick()
    if isFlicking then return end
    isFlicking = true

    isWallHopping = true
    lastWallHopTime = tick()

    local char = LocalPlayer.Character
    local hum = char and char:FindFirstChild("Humanoid")
    local hrp = char and char:FindFirstChild("HumanoidRootPart")
    if not hum or not hrp then
        isFlicking = false
        return
    end

    -- impulso original (INALTERADO)
    hum:ChangeState(Enum.HumanoidStateType.Jumping)
    hrp.Velocity = Vector3.new(hrp.Velocity.X, 44.8, hrp.Velocity.Z)

    -- ===== FLICK VISUAL =====
    local originalCFrame = hrp.CFrame

    -- gira 45° para a direita
    local flickCFrame = originalCFrame * CFrame.Angles(0, math.rad(45), 0)
    hrp.CFrame = flickCFrame

    -- volta suavemente (igual sensação do flick antigo)
    task.wait(0.015)

    local steps = 5
    for i = 1, steps do
        local alpha = (i / steps) ^ 2
        hrp.CFrame = flickCFrame:Lerp(originalCFrame, alpha)
        task.wait(0.005)
    end
    -- ========================

    task.delay(0.1, function()
        if hum and hum:GetState() == Enum.HumanoidStateType.Jumping then
            hum:ChangeState(Enum.HumanoidStateType.Freefall)
        end
    end)

    task.delay(0.25, function()
        isWallHopping = false
    end)

    isFlicking = false
end
