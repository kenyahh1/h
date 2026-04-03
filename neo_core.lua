-- neo_core.lua | KenyahSENCE Core v2
local HttpService = game:GetService("HttpService")
local RunService  = game:GetService("RunService")

local Neo = {}

-- ─── Estado de rendimiento ───────────────────────────────────────────────────
Neo.State = { fps = 60, frameMs = 16, cpuMs = 16 }

Neo.Perf = {}
Neo.Perf.start = function()
    RunService.RenderStepped:Connect(function(dt)
        Neo.State.fps     = math.clamp(math.floor(1 / dt), 1, 240)
        Neo.State.frameMs = math.floor(dt * 1000 * 10) / 10
    end)
    RunService.Heartbeat:Connect(function(dt)
        Neo.State.cpuMs = math.floor(dt * 1000 * 10) / 10
    end)
end

-- ─── Logger ──────────────────────────────────────────────────────────────────
Neo.Logger = {}
Neo.Logger.buffer = {}
Neo.Logger.max    = 200000
Neo.Logger.levels = { debug = 1, info = 2, warn = 3, error = 4 }
Neo.Logger.level  = 1   -- captura todo desde debug

Neo.Logger.log = function(level, msg)
    local lv = Neo.Logger.levels[level] or 1
    if lv < Neo.Logger.level then return end
    local t    = (os and os.time and os.time()) or tick()
    local line = "[" .. level .. "] " .. tostring(t) .. " " .. tostring(msg)
    local buf  = Neo.Logger.buffer
    buf[#buf + 1] = line
    if #buf > Neo.Logger.max then table.remove(buf, 1) end
end

Neo.Logger.flush = function(filename)
    if not writefile then return false end
    local s  = table.concat(Neo.Logger.buffer, "\n")
    local ok = pcall(writefile, filename or "NeoLog.txt", s)
    return ok
end

-- ─── Validador permisivo ─────────────────────────────────────────────────────
-- Solo normaliza booleans y garantiza que los enteros sean numéricos.
-- No bloquea ni trunca por valor; usa límites extremadamente amplios.
Neo.Validator = {}

-- Patrones de categoría (para estadísticas, no para bloquear)
Neo.Validator.categories = {
    network   = {"RakNet","Network","Packet","Bandwidth","Ping","Socket","Mtu","Latency"},
    physics   = {"Sim","Physics","Solver","Humanoid","Ragdoll","Aerodynamics","Collision"},
    telemetry = {"Telemetry","Analytics","Crash","PerfData","Lightstep","HttpPoints","Report"},
    rendering = {"Render","Lighting","Shadow","CSG","SSAOMip","Texture","Anisotropic","GlobalIllumination"},
    audio     = {"Audio","VoiceChat","Sound","Emitter","Panner"},
}

Neo.Validator.categorize = function(k)
    for cat, pats in pairs(Neo.Validator.categories) do
        for _, p in ipairs(pats) do
            if tostring(k):find(p) then return cat end
        end
    end
    return nil
end

-- sanitize: solo normaliza, no bloquea ni trunca agresivamente
Neo.Validator.sanitize = function(k, v)
    local s  = tostring(v)
    local lk = tostring(k):lower()

    -- Normalizar booleans
    local sl = s:lower()
    if lk:find("flag") then
        if sl == "true"  or sl == "1" or sl == "yes" or sl == "on"  then return "True"  end
        if sl == "false" or sl == "0" or sl == "no"  or sl == "off" then return "False" end
        return s
    end

    -- Enteros: asegurar que sea un número válido, sin cap de valor
    if lk:find("int") or lk:find("fint") then
        local n = tonumber(s)
        if not n then return "0" end
        -- Solo clampeamos al rango de entero de 64 bits con margen de seguridad
        local MAX = 9007199254740992   -- 2^53
        if n >  MAX then n =  MAX end
        if n < -MAX then n = -MAX end
        return tostring(math.floor(n))
    end

    -- Strings: sin límite de longitud (el executor decidirá)
    return s
end

-- scan: solo cuenta para estadísticas, nunca bloquea
Neo.Validator.scan = function(data)
    local risk, bigInt, longStr, extreme = 0, 0, 0, 0
    for k, v in pairs(data) do
        local s  = tostring(v)
        local lk = tostring(k):lower()
        if lk:find("int") then
            local n = tonumber(s)
            if not n then
                bigInt = bigInt + 1
            else
                if math.abs(n) > 100000  then bigInt  = bigInt  + 1 end
                if math.abs(n) > 1000000 then extreme = extreme + 1 end
            end
        else
            if #s > 512 then longStr = longStr + 1 end
        end
    end
    return { risk = risk, bigInt = bigInt, longStr = longStr, extreme = extreme }
end

-- ─── Perfiles ─────────────────────────────────────────────────────────────────
Neo.Profiles = {}
Neo.Profiles.list = {
    Normal = { maxPerFrame = 6,  fastBoost = 2 },
    Seguro = { maxPerFrame = 2,  fastBoost = 0 },
    Ultra  = { maxPerFrame = 16, fastBoost = 6 },
}
Neo.Profiles.current = "Ultra"

Neo.Profiles.set = function(name)
    if Neo.Profiles.list[name] then
        Neo.Profiles.current = name
        return true
    end
    return false
end

-- ─── RateController ──────────────────────────────────────────────────────────
Neo.RateController = {}
Neo.RateController.rate = function(bytes, count, fps, failureRate, fastMode, _)
    local prof = Neo.Profiles.list[Neo.Profiles.current]
    local base
    if fastMode then
        if bytes >= 30000 or count >= 1200 then base = 6
        elseif bytes >= 20000 or count >= 700 then base = 10
        else base = 16 end
        base = math.min(base + (prof.fastBoost or 0), prof.maxPerFrame or 16)
    else
        if bytes >= 30000 or count >= 1200 then base = 3
        elseif bytes >= 20000 or count >= 700 then base = 5
        else base = 8 end
        base = math.min(base, prof.maxPerFrame or 8)
    end
    if fps < 35 then base = math.max(1, math.floor(base * 0.4))
    elseif fps < 50 then base = math.max(1, math.floor(base * 0.7)) end
    if failureRate and failureRate > 0.3 then base = math.max(1, math.floor(base * 0.6)) end
    return base
end

-- ─── HTTP helper ──────────────────────────────────────────────────────────────
Neo.Url = {}
Neo.Url.get = function(url)
    local ok, body = pcall(function() return HttpService:GetAsync(url) end)
    if ok and type(body) == "string" then return body end
    return nil
end

getgenv().Neo = Neo
return Neo
