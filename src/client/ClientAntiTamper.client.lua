-- ClientAntiTamper.lua
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Players = game:GetService("Players")

local antiFolder = ReplicatedStorage:WaitForChild("AntiCheat")
local RemoteAction = antiFolder:WaitForChild("RemoteAction")

-- global so ClientHeartbeat can read it
_G.AntiCheat_Token = nil

RemoteAction.OnClientEvent:Connect(function(cmd, payload)
	if cmd == "AssignToken" and type(payload) == "table" and payload.token then
		_G.AntiCheat_Token = tostring(payload.token)
	end
end)

-- no token after 5s -> report it
task.delay(5, function()
	if not _G.AntiCheat_Token then
		warn("[AntiTamper] token not received, reporting to server")
		pcall(function()
			RemoteAction:FireServer("ClientTamper", {reason = "token not received"})
		end)
	end
end)
