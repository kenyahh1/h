local HttpService = game:GetService("HttpService")
local RunService  = game:GetService("RunService")

local Neo = {}

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

Neo.Logger = {}
Neo.Logger.buffer = {}
Neo.Logger.max    = 200000

Neo.Logger.log = function(level, msg)
    local buf  = Neo.Logger.buffer
    local line = "[" .. tostring(level) .. "] " .. tostring(tick()) .. " " .. tostring(msg)
    buf[#buf + 1] = line
    if #buf > Neo.Logger.max then table.remove(buf, 1) end
end

Neo.Logger.flush = function(filename)
    if not writefile then return false end
    return pcall(writefile, filename or "NeoLog.txt", table.concat(Neo.Logger.buffer, "\n"))
end

Neo.Validator = {}
Neo.Validator.sanitize = function(k, v)
    local s  = tostring(v)
    local lk = tostring(k):lower()
    local sl = s:lower()
    if lk:find("flag") then
        if sl == "true"  or sl == "1" or sl == "yes" or sl == "on"  then return "True"  end
        if sl == "false" or sl == "0" or sl == "no"  or sl == "off" then return "False" end
        return s
    end
    if lk:find("int") then
        local n = tonumber(s)
        if not n then return "0" end
        local M = 9007199254740992
        if n >  M then n =  M end
        if n < -M then n = -M end
        return tostring(math.floor(n))
    end
    return s
end

Neo.Validator.scan = function(data)
    local bigInt, longStr, extreme = 0, 0, 0
    for k, v in pairs(data) do
        local s  = tostring(v)
        local lk = tostring(k):lower()
        if lk:find("int") then
            local n = tonumber(s)
            if not n then bigInt = bigInt + 1
            else
                if math.abs(n) > 100000  then bigInt  = bigInt  + 1 end
                if math.abs(n) > 1000000 then extreme = extreme + 1 end
            end
        else
            if #s > 512 then longStr = longStr + 1 end
        end
    end
    return { risk = 0, bigInt = bigInt, longStr = longStr, extreme = extreme }
end

Neo.Profiles = {}
Neo.Profiles.list = {
    Normal = { maxPerFrame = 6,  fastBoost = 2  },
    Seguro = { maxPerFrame = 2,  fastBoost = 0  },
    Ultra  = { maxPerFrame = 20, fastBoost = 10 },
}
Neo.Profiles.current = "Ultra"
Neo.Profiles.set = function(name)
    if Neo.Profiles.list[name] then Neo.Profiles.current = name; return true end
    return false
end

Neo.Url = {}
Neo.Url.get = function(url)
    local ok, body = pcall(function() return HttpService:GetAsync(url) end)
    return (ok and type(body) == "string") and body or nil
end

getgenv().Neo = Neo
return Neo
