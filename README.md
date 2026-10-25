# WaveGuard

Server-side anti-cheat for Roblox, written in Lua. I built it like a small IDS/IPS: it watches what players do, gives them suspicion points when something looks off, logs it, and only kicks once the score is high enough.

This repo is a showcase. WaveGuard runs on a live game, so the detection modules and the real thresholds stay private. What's here is the architecture, the scoring/logging side and the client scripts. The rest can be shown on request.

## Detection

Movement, checked server-side:
- speed, teleports and small teleports adding up over time
- high jump, infinite jump
- fly, hovering, staying still in the air
- noclip
- invisibility
- gravity changes that didn't come from the server

Integrity:
- tools and GUIs are only accepted if they're on an allowlist and signed by the server (the signatures never leave the server)
- known exploit UIs (Dex, Infinite Yield, executor menus...)
- injection traces like `loadstring`, `require`, `HttpGet`
- client heartbeat with a per-player token

## How it reacts

Each detection adds points to the player's suspicion score (`SuspicionManager`). One weird event just gets logged. If it keeps happening, the player hits a warning threshold, then a kick threshold. That's what keeps false positives down when someone lags or uses a jump pad.

The kick is disguised as a normal Roblox connection error, so a cheater doesn't learn which check caught him. The real reason only shows up in the server logs.

## Structure

```
src/
  server/
    SuspicionManager.lua
    Logger.lua
    Config.example.lua
  client/
    ClientHeartbeat.client.lua
    ClientAntiTamper.client.lua
    ClientGuiWatch.client.lua
```

Client scripts only report to the server. Anything on the client can be read by an exploiter anyway, so they're fine to publish.

## Testing

I tested it by attacking it myself. I made a fake executor UI (Synapse X style) to trigger the GUI and injection checks, then tried fly, teleport and noclip by hand to tune the thresholds and cut false positives.
