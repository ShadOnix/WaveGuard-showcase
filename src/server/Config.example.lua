-- ServerScriptService/AntiCheat/Config.lua (values removed)
local Config = {}

-- ===== Heartbeat =====
Config.HEARTBEAT_INTERVAL  = 0
Config.HEARTBEAT_TOLERANCE = 0

-- ===== Rate limits / sanctions / suspicion =====
Config.MAX_ACTIONS_PER_SECOND        = 0
Config.WARNINGS_BEFORE_KICK          = 0
Config.KICK_ON_SPEEDCHEAT            = true

Config.SUSPICION_WARN                = 0
Config.SUSPICION_KICK                = 0
Config.SUSPICION_INCREMENT_SPAM      = 0
Config.SUSPICION_INCREMENT_PAYLOAD   = 0
Config.SUSPICION_INCREMENT_TOOL      = 0
Config.SUSPICION_INCREMENT_CLIENTTAMPER = 0

-- ===== Movement / speed (server) =====
-- on the ground: WalkSpeed + margin, in the air: horizontal cap
Config.GROUND_SPEED_MARGIN       = 0
Config.MAX_AIR_HORIZONTAL_SPEED  = 0
Config.SMOOTH_ALPHA              = 0    -- EMA smoothing on speed

-- ===== Weird jumps =====
Config.MAX_JUMP_HEIGHT       = 0
Config.MAX_UPWARD_VELOCITY   = 0
Config.HIGHJUMP_FORGIVENESS  = 0
Config.HIGHJUMP_TAG          = "AllowHighJump"

-- Infinite jump
Config.INFJUMP_GROUND_GRACE    = 0      -- how long after leaving the ground it still counts as grounded
Config.INFJUMP_MAX_AIR_JUMPS   = 0
Config.INFJUMP_SUS_INCREMENT   = 0
Config.INFJUMP_DEBUG           = true

-- ===== Teleports =====
Config.TELEPORT_DISTANCE   = 0          -- one big jump in a single step
Config.MICROTP_WINDOW      = 0          -- time window for small TPs adding up
Config.MICROTP_THRESHOLD   = 0          -- total distance allowed in that window
Config.TELEPORT_GRACE      = 0          -- grace time after a server TP
Config.TELEPORTER_TAG      = "Teleporter"  -- tag for teleporter parts

-- ===== Void / respawn =====
Config.GRACE_AFTER_RESPAWN  = 0
Config.FALLEN_HEIGHT_MARGIN = 0

-- ===== Noclip (raycast) =====
Config.NOCLIP_RAYCAST = true
Config.NOCLIP_MIN_MOVE = 0              -- min distance moved before checking
Config.NOCLIP_VERTICAL_TOLERANCE = 0
Config.NOCLIP_SUS_INCREMENT = 0
Config.NOCLIP_WHITELIST_TAG = "Partnoclip"

-- ===== Gravity check =====
Config.GRAVITY_CHECK_ENABLED = true
Config.GRAVITY_MIN = 0
Config.GRAVITY_MAX = 0
Config.GRAVITY_COOLDOWN = 0

-- ===== Invisibility (server) =====
Config.ANTI_INVIS_INTERVAL      = 0     -- time between two checks
Config.ANTI_INVIS_THRESHOLD     = 0     -- ratio of invisible parts (0.0 to 1.0)
Config.ANTI_INVIS_PERSISTENCE   = 0     -- how long it has to last before kick
Config.ANTI_INVIS_SUS_INCREMENT = 0     -- suspicion added on first detection

-- ===== Misc =====
Config.CHECKPOINT_TOLERANCE = 0
Config.ENABLE_LOGS = true
Config.ANTI_TAMPER_REQUIRE_TOKEN = false

-- ==== Tools ====
Config.TOOLWATCH_DEBUG = true

-- ==== GUI ====
Config.GUIWATCH_DEBUG = true
Config.GUI_UNAUTHORIZED_SUS_INCREMENT = 0

-- ==== Injection ====
Config.INJECTION_SCAN_INTERVAL = 0
Config.INJECTION_SUSPICION = 0
Config.INJECTION_PERSIST_COUNT = 0
Config.INJECTION_KICK_ENABLED = true

-- ===== Fly =====
-- max time in the air before it gets suspicious (jump pads excluded)
Config.FLY_MAX_AIR_TIME       = 0

-- below this vertical speed the player is "hovering"
Config.FLY_HOVER_VY_THRESHOLD = 0

-- min height above the ground to count as floating
Config.FLY_MIN_HEIGHT         = 0

-- hover ticks before suspicion
Config.FLY_HOVER_TICKS        = 0

-- ticks in a row going up before suspicion
Config.FLY_VERTICAL_TICKS     = 0

-- vertical speed that counts as going up
Config.FLY_VERTICAL_VY        = 0

-- BodyMovers / constraints scan
Config.FLY_SCAN_INTERVAL      = 0
Config.FLY_BODY_SPEED_MIN     = 0       -- min magnitude to count as active
Config.FLY_BODY_TICKS         = 0       -- scans in a row before suspicion

-- suspicion added per pattern
Config.FLY_SUS_HOVER          = 0
Config.FLY_SUS_VERTICAL       = 0
Config.FLY_SUS_BODY           = 0

Config.FLY_DEBUG              = false

-- ===== Air camping (staying still in the air) =====
Config.AIRCAMP_MIN_AIR_TIME    = 0
Config.AIRCAMP_MIN_HEIGHT      = 0
Config.AIRCAMP_VY_THRESHOLD    = 0
Config.AIRCAMP_HSPEED_MAX      = 0
Config.AIRCAMP_TICKS           = 0
Config.AIRCAMP_SUS_INCREMENT   = 0

return Config
