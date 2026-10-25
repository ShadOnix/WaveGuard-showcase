-- ClientHeartbeat.lua
local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local RunService = game:GetService("RunService")

local player = Players.LocalPlayer
local antiFolder = ReplicatedStorage:WaitForChild("AntiCheat")
local RemoteHeartbeat = antiFolder:WaitForChild("RemoteHeartbeat")

local lastSend = 0
local HEART_INTERVAL = 1

RunService.Heartbeat:Connect(function(dt)
	lastSend += dt
	if lastSend >= HEART_INTERVAL then
		lastSend = 0

		pcall(function()
			local char = player.Character or player.CharacterAdded:Wait()
			local hrp = char:FindFirstChild("HumanoidRootPart")
			if hrp then
				local pos = hrp.Position
				local token = _G.AntiCheat_Token
				if token then
					RemoteHeartbeat:FireServer(pos, os.time(), token)
				end
			end
		end)
	end
end)
