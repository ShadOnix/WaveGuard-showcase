-- ClientGuiWatch.lua
-- watches PlayerGui / CoreGui / client remotes and reports to the server

local Players           = game:GetService("Players")
local CoreGui           = game:GetService("CoreGui")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local RunService        = game:GetService("RunService")

local player    = Players.LocalPlayer
local playerGui = player:WaitForChild("PlayerGui")

local ALERT_REMOTE = ReplicatedStorage
	:WaitForChild("AntiCheat")
	:WaitForChild("RemoteAction")

-- Local config

local OFFICIAL_CORE_ROOTS = {
	["PlayerList"]    = true,
	["Chat"]          = true,
	["BubbleChat"]    = true,
	["Backpack"]      = true,
	["Health"]        = true,
	["TopBar"]        = true,
	["TopBarPlus"]    = true,
	["RobloxGui"]     = true,
	["DevConsole"]    = true,
	["RobloxCoreGui"] = true,
	["TouchGui"]      = true,
}

-- the game's own GUIs (HUD, menus...)
-- an official GUI also needs WG_Trusted = true
local SAFE_GUI_ROOTS = {
	["WaveGuardExecutor"] = true,
	["MainHUD"]           = true,
	["SettingsUI"]        = true,
	["Freecam"]           = true,
	["TouchGui"]          = true,
}

-- GUIs that should only exist once
local OFFICIAL_SINGLE_INSTANCES = {
	["WaveGuardExecutor"] = true,
	["MainHUD"]           = true,
	["SettingsUI"]        = true,
	["Freecam"]           = true,
	["TouchGui"]          = true,
}

-- Studio rebuilds PlayerGui sometimes
if RunService:IsStudio() then
	OFFICIAL_SINGLE_INSTANCES["WaveGuardExecutor"] = false
end

-- Utils

local function isTrusted(inst)
	local ok, val = pcall(function()
		return inst:GetAttribute("WG_Trusted")
	end)
	return ok and val == true
end

local function isUnderPlayerGui(inst)
	local cur = inst
	while cur do
		if cur == playerGui then
			return true
		end
		cur = cur.Parent
	end
	return false
end

local function findRootInPlayerGui(obj)
	local cur = obj
	while cur and cur.Parent and cur.Parent ~= playerGui do
		cur = cur.Parent
	end
	if cur and cur.Parent == playerGui and cur:IsA("ScreenGui") then
		return cur
	end
	return nil
end

-- dedup: same alert is ignored for a short time
local LAST_ALERT_AT = {}
local function alertKey(alertType, data)
	local root = (data and (data.rootName or data.fullName)) or "?"
	return alertType .. "|" .. tostring(root)
end

-- global rate limit
local windowStart = os.clock()
local sentInWindow = 0
local MAX_ALERTS_PER_SEC = 10

-- per-root cooldown so descendants don't spam
local lastHandledByRoot = setmetatable({}, { __mode = "k" })
local function shouldHandleRoot(root, cooldown)
	local now = os.clock()
	local last = lastHandledByRoot[root] or 0
	if (now - last) < cooldown then return false end
	lastHandledByRoot[root] = now
	return true
end

local function sendAlert(alertType, data)
	data = data or {}

	local now = os.clock()

	-- short dedup
	local k = alertKey(alertType, data)
	local last = LAST_ALERT_AT[k] or 0
	if (now - last) < 1.5 then
		return
	end
	LAST_ALERT_AT[k] = now

	-- global rate limit
	if (now - windowStart) > 1.0 then
		windowStart = now
		sentInWindow = 0
	end
	sentInWindow += 1
	if sentInWindow > MAX_ALERTS_PER_SEC then
		return
	end

	pcall(function()
		ALERT_REMOTE:FireServer(alertType, data)
	end)
end

-- a GUI moved out of PlayerGui usually means injection / hijack
local TrackedGuiRoots = setmetatable({}, { __mode = "k" })
local function watchRootMovement(root)
	if not root or not root:IsA("ScreenGui") then return end
	if TrackedGuiRoots[root] then return end
	TrackedGuiRoots[root] = true

	root.AncestryChanged:Connect(function()
		if not root.Parent then
			-- destroyed, that's fine
			return
		end

		if not isUnderPlayerGui(root) then
			sendAlert("GUI_MOVED_OUT_OF_PLAYERGUI", {
				rootName = root.Name,
				class    = root.ClassName,
				fullName = root:GetFullName(),
			})
		end
	end)
end

local function isOfficialCore(root)
	return OFFICIAL_CORE_ROOTS[root.Name] == true
end

-- PlayerGui

-- cleared on destroy/reparent, avoids false TRUSTED_GUI_CLONED
local OfficialRootByName = {}

local function trackOfficialLifecycle(root)
	if not root or not root:IsA("ScreenGui") then return end

	root.AncestryChanged:Connect(function()
		if not root.Parent or not isUnderPlayerGui(root) then
			if OfficialRootByName[root.Name] == root then
				OfficialRootByName[root.Name] = nil
			end
		end
	end)
end

local function handleGuiRoot(root, desc)
	if not root or not root.Parent then return end
	if not root:IsA("ScreenGui") then return end

	-- root cooldown, avoids spam while descendants are being created
	if not shouldHandleRoot(root, 0.8) then
		return
	end

	watchRootMovement(root)

	local full = (desc or root):GetFullName()
	local className = desc and desc.ClassName or root.ClassName
	local name = root.Name
	local trusted = isTrusted(root)

	-- 1) official GUI (allowlist)
	if SAFE_GUI_ROOTS[name] then
		-- a) same name as an official GUI but not signed
		if not trusted then
			sendAlert("FAKE_GUI_IMPERSONATION", {
				rootName = name,
				class    = className,
				fullName = full,
			})
			return
		end

		trackOfficialLifecycle(root)

		-- b) signed + single instance
		if OFFICIAL_SINGLE_INSTANCES[name] then
			local existing = OfficialRootByName[name]

			-- old one is dead or out of PlayerGui, just replace it
			if existing and (not existing.Parent or not isUnderPlayerGui(existing)) then
				OfficialRootByName[name] = nil
				existing = nil
			end

			if existing and existing ~= root then
				sendAlert("TRUSTED_GUI_CLONED", {
					rootName = name,
					class    = className,
					fullName = root:GetFullName(),
				})
				return
			end

			OfficialRootByName[name] = root
		end

		-- c) signed official GUI, nothing to do
		return
	end

	-- 2) unknown GUI
	if trusted then
		sendAlert("TRUSTED_FLAG_ANOMALY", {
			rootName = name,
			class    = className,
			fullName = full,
		})
	end

	sendAlert("UNSIGNED_GUI", {
		rootName = name,
		class    = className,
		fullName = full,
	})
end

-- DescendantAdded fires a lot, so descendants of official GUIs are skipped
local function onDescendantInGui(desc)
	if not desc or not desc.Parent then return end

	if not (desc:IsA("GuiObject")
		or desc:IsA("LocalScript")
		or desc:IsA("ModuleScript")
		or desc:IsA("Script")) then
		return
	end

	local root = findRootInPlayerGui(desc)
	if not root then return end

	if SAFE_GUI_ROOTS[root.Name] then
		return
	end

	handleGuiRoot(root, desc)
end

local function scanPlayerGuiInitial()
	for _, root in ipairs(playerGui:GetChildren()) do
		if root:IsA("ScreenGui") then
			handleGuiRoot(root, root)
		end
	end

	-- only scan descendants of non official GUIs
	for _, root in ipairs(playerGui:GetChildren()) do
		if root:IsA("ScreenGui") and not SAFE_GUI_ROOTS[root.Name] then
			for _, d in ipairs(root:GetDescendants()) do
				onDescendantInGui(d)
			end
		end
	end
end

local function bindPlayerGui()
	playerGui.ChildAdded:Connect(function(gui)
		task.defer(function()
			if gui:IsA("ScreenGui") then
				handleGuiRoot(gui, gui)

				if not SAFE_GUI_ROOTS[gui.Name] then
					for _, d in ipairs(gui:GetDescendants()) do
						onDescendantInGui(d)
					end
				end
			end
		end)
	end)

	playerGui.DescendantAdded:Connect(function(desc)
		onDescendantInGui(desc)
	end)
end

-- CoreGui

local function handleCoreGuiObject(obj)
	if not obj or not obj.Parent then return end

	local root = obj
	while root.Parent and root.Parent ~= CoreGui do
		root = root.Parent
	end
	if not root then return end
	if isOfficialCore(root) then return end

	sendAlert("COREGUI_INJECT", {
		rootName = root.Name,
		class    = obj.ClassName,
		fullName = obj:GetFullName(),
	})
end

local function bindCoreGui()
	local ok, core = pcall(function()
		return game:GetService("CoreGui")
	end)
	if not ok or not core then return end

	for _, obj in ipairs(core:GetChildren()) do
		handleCoreGuiObject(obj)
	end

	core.ChildAdded:Connect(function(obj)
		task.defer(function()
			handleCoreGuiObject(obj)
		end)
	end)
end

-- Remotes created on the client

local function snapshotRemotes()
	local t = {}
	for _, inst in ipairs(ReplicatedStorage:GetChildren()) do
		if inst:IsA("RemoteEvent") or inst:IsA("RemoteFunction") then
			t[inst.Name] = true
		end
	end
	return t
end

local initialRemotes = snapshotRemotes()

-- known false positives (Studio plugins etc.)
local ALLOWED_LOCAL_REMOTES = {
	["IS"] = true, -- created by a Studio pentest plugin I use
}

local function onLocalRemote(obj)
	if not (obj:IsA("RemoteEvent") or obj:IsA("RemoteFunction")) then return end
	if initialRemotes[obj.Name] then return end
	if ALLOWED_LOCAL_REMOTES[obj.Name] then return end

	sendAlert("UNAUTHORIZED_REMOTE_LOCAL", {
		rootName = obj.Name,
		class    = obj.ClassName,
		fullName = obj:GetFullName(),
		parent   = obj.Parent and obj.Parent.Name or "unknown",
	})
end

local function bindLocalRemotes()
	ReplicatedStorage.ChildAdded:Connect(function(obj)
		task.defer(function()
			onLocalRemote(obj)
		end)
	end)
end

-- Init

task.defer(function()
	scanPlayerGuiInitial()
	bindPlayerGui()
	bindCoreGui()
	bindLocalRemotes()
end)
