-- ServerScriptService/AntiCheat/SuspicionManager.lua
local Suspicion = {}
Suspicion.__index = Suspicion

local Players = game:GetService("Players")
local Logger = require(script.Parent:WaitForChild("Logger"))
local Config = require(script.Parent:WaitForChild("Config"))

local stateRef = {} -- local storage, MainServer owns the real state table

function Suspicion:initStateTable(externalState)
	-- MainServer passes its own state table here
	self.state = externalState or {}
end

function Suspicion:incr(userId, amount, reason)
	if not self.state then return end
	local s = self.state[userId]
	if not s then return end
	s.suspicion = (s.suspicion or 0) + (amount or 1)
	if Config.ENABLE_LOGS then
		Logger:Warn(("%s suspicion +%d (%d) : %s"):format(tostring(userId), amount, s.suspicion, reason or "no reason"))
	end
	return s.suspicion
end

function Suspicion:get(userId)
	if not self.state then return 0 end
	local s = self.state[userId]
	return (s and s.suspicion) or 0
end

function Suspicion:shouldKick(userId)
	return self:get(userId) >= Config.SUSPICION_KICK
end

function Suspicion:shouldWarn(userId)
	return self:get(userId) >= Config.SUSPICION_WARN
end

return Suspicion
