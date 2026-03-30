local anim = Instance.new("Animation")
anim.AnimationId = "rbxassetid://507776043" -- exemplo

local hum = game.Players.LocalPlayer.Character.Humanoid
local track = hum:LoadAnimation(anim)
track:Play()
