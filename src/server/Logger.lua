-- ServerScriptService/AntiCheat/Logger.lua
local Logger = {}

-- Config
local MERGE_WINDOW = 1.5      -- seconds, identical logs inside this window get merged
local MERGE_LIMIT = 50        -- caps the counter, no (x9999)
local CLEANUP_INTERVAL = 0.5

local recentLogs = {}

local function flushLog(key)
	local data = recentLogs[key]
	if not data then return end

	local suffix = (data.count > 1) and (" (x" .. data.count .. ")") or ""

	local prefix = "[AntiCheat] "
	if data.level == "error" then
		prefix = "[AntiCheat] [ERROR] "
	elseif data.level == "warn" then
		prefix = "[AntiCheat] [WARN] "
	else
		prefix = "[AntiCheat] [INFO] "
	end

	-- server console only
	if data.level == "warn" or data.level == "error" then
		warn(prefix .. data.text .. suffix)
	else
		print(prefix .. data.text .. suffix)
	end

	recentLogs[key] = nil
end

-- flushes logs once their merge window is over
task.spawn(function()
	while true do
		task.wait(CLEANUP_INTERVAL)
		local now = os.clock()
		for key, data in pairs(recentLogs) do
			if now - data.last > MERGE_WINDOW then
				flushLog(key)
			end
		end
	end
end)

-- turns whatever we get into (text, level)
local function normalizeMessage(msg, defaultLevel)
	local level = defaultLevel or "info"
	local text

	if typeof(msg) == "table" then
		if msg.level then
			level = msg.level
		end

		if msg.message then
			text = tostring(msg.message)
		else
			-- fallback: k=v | k2=v2 ...
			local parts = {}
			for k, v in pairs(msg) do
				if k ~= "level" then
					table.insert(parts, tostring(k) .. "=" .. tostring(v))
				end
			end
			text = table.concat(parts, " | ")
		end
	else
		text = tostring(msg)
	end

	return text, level
end

local function push(defaultLevel, msg)
	local text, level = normalizeMessage(msg, defaultLevel)
	if not text or text == "" then return end

	local key = level .. "|" .. text
	local now = os.clock()

	local data = recentLogs[key]
	if data then
		data.count = math.min(data.count + 1, MERGE_LIMIT)
		data.last = now
	else
		recentLogs[key] = {
			text = text,
			level = level,
			count = 1,
			last = now,
		}
	end
end

-- Public API

function Logger:Log(msg)
	push("info", msg)
end

function Logger:Info(msg)
	push("info", msg)
end

function Logger:Warn(msg)
	push("warn", msg)
end

function Logger:Error(msg)
	push("error", msg)
end

return Logger
