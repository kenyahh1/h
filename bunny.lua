do
    local ok, src = pcall(function() return readfile and readfile("neo_core.lua") end)
    if ok and type(src) == "string" and #src > 0 and type(loadstring) == "function" then
        pcall(function() loadstring(src)() end)
    end
end

local Players          = game:GetService("Players")
local TweenService     = game:GetService("TweenService")
local UserInputService = game:GetService("UserInputService")
local RunService       = game:GetService("RunService")
local HttpService      = game:GetService("HttpService")

local player    = Players.LocalPlayer
local playerGui = player:WaitForChild("PlayerGui")

do
    local prev = playerGui:FindFirstChild("KyroDev") or playerGui:FindFirstChild("KyroDevNeo")
    if prev then prev:Destroy() end
end

local C_HOT    = Color3.fromRGB(255,  50,  50)
local C_DARK   = Color3.fromRGB(100,   0,   0)
local C_GLOW   = Color3.fromRGB(255, 120, 120)
local C_DIM    = Color3.fromRGB( 60,   6,   6)
local C_BG     = Color3.fromRGB(  9,   3,   3)
local C_PANEL  = Color3.fromRGB( 16,   5,   5)
local C_CARD   = Color3.fromRGB( 22,   7,   7)
local C_WHITE  = Color3.new(1, 1, 1)
local C_TEXT   = Color3.fromRGB(255, 170, 170)

local fps     = 60
local frameMs = 16
local cpuMs   = 16

local function new(class, props)
    local obj = Instance.new(class)
    for k, v in pairs(props or {}) do
        if k == "Parent" then obj.Parent = v else obj[k] = v end
    end
    return obj
end

local function corner(obj, r)
    new("UICorner", { Parent = obj, CornerRadius = UDim.new(0, r) })
end

local function redgrad(parent, rot)
    new("UIGradient", {
        Parent   = parent,
        Rotation = rot or 90,
        Color    = ColorSequence.new({
            ColorSequenceKeypoint.new(0,   Color3.fromRGB(130,  0,  0)),
            ColorSequenceKeypoint.new(0.5, Color3.fromRGB(200, 20, 20)),
            ColorSequenceKeypoint.new(1,   Color3.fromRGB(255, 55, 55)),
        }),
    })
end

local function hover(btn)
    btn.AutoButtonColor = false
    local orig = btn.BackgroundColor3
    btn.MouseEnter:Connect(function()
        TweenService:Create(btn, TweenInfo.new(0.12), { BackgroundColor3 = C_GLOW }):Play()
    end)
    btn.MouseLeave:Connect(function()
        TweenService:Create(btn, TweenInfo.new(0.18), { BackgroundColor3 = orig }):Play()
    end)
end

local function makeDraggable(frame)
    local dragging, dragInput, startPos, startMouse = false, nil, nil, nil
    frame.InputBegan:Connect(function(i)
        if i.UserInputType == Enum.UserInputType.MouseButton1
        or i.UserInputType == Enum.UserInputType.Touch then
            dragging   = true
            startPos   = frame.Position
            startMouse = i.Position
            dragInput  = i
        end
    end)
    frame.InputChanged:Connect(function(i)
        if i.UserInputType == Enum.UserInputType.MouseMovement
        or i.UserInputType == Enum.UserInputType.Touch then
            dragInput = i
        end
    end)
    frame.InputEnded:Connect(function(i)
        if i == dragInput then dragging = false end
    end)
    UserInputService.InputChanged:Connect(function(i)
        if dragging and i == dragInput then
            local d = i.Position - startMouse
            frame.Position = UDim2.new(
                startPos.X.Scale, startPos.X.Offset + d.X,
                startPos.Y.Scale, startPos.Y.Offset + d.Y
            )
        end
    end)
end

local function notify(text)
    local n = new("Frame", {
        Parent              = playerGui,
        Size                = UDim2.fromOffset(320, 42),
        Position            = UDim2.new(0.5, -160, 1, -90),
        BackgroundColor3    = C_PANEL,
        ZIndex              = 30,
    })
    corner(n, 9)
    redgrad(n, 0)
    new("UIStroke", { Parent = n, Color = C_HOT, Thickness = 1.2, Transparency = 0.15 })
    local lbl = new("TextLabel", {
        Parent              = n,
        Size                = UDim2.fromScale(1, 1),
        BackgroundTransparency = 1,
        Text                = text,
        Font                = Enum.Font.GothamBold,
        TextSize            = 13,
        TextColor3          = C_WHITE,
        ZIndex              = 31,
    })
    TweenService:Create(n, TweenInfo.new(0.2), { Position = UDim2.new(0.5, -160, 1, -112) }):Play()
    task.delay(2.8, function()
        TweenService:Create(n,   TweenInfo.new(0.18), { BackgroundTransparency = 1 }):Play()
        TweenService:Create(lbl, TweenInfo.new(0.18), { TextTransparency = 1 }):Play()
        task.delay(0.2, function() n:Destroy() end)
    end)
end

local gui = new("ScreenGui", {
    Parent         = playerGui,
    Name           = "KyroDev",
    IgnoreGuiInset = true,
    ResetOnSpawn   = false,
})

local overlay = new("Frame", {
    Parent              = gui,
    Size                = UDim2.fromScale(1, 1),
    BackgroundColor3    = Color3.new(0, 0, 0),
    BackgroundTransparency = 1,
    Visible             = false,
})

local dockIcon = new("Frame", {
    Parent           = gui,
    Size             = UDim2.fromOffset(42, 42),
    Position         = UDim2.new(1, -54, 0, 80),
    BackgroundColor3 = C_CARD,
    Visible          = true,
})
dockIcon.Active = true
corner(dockIcon, 21)
redgrad(dockIcon)
new("UIStroke", { Parent = dockIcon, Color = C_HOT, Thickness = 1.2, Transparency = 0.15 })
local dockBtn = new("TextButton", {
    Parent              = dockIcon,
    Size                = UDim2.fromScale(1, 1),
    BackgroundTransparency = 1,
    Text                = "K",
    Font                = Enum.Font.GothamBold,
    TextSize            = 17,
    TextColor3          = C_WHITE,
})
makeDraggable(dockIcon)

local container = new("Frame", {
    Parent           = gui,
    Size             = UDim2.fromOffset(330, 370),
    Position         = UDim2.new(0.5, -165, 0.5, -185),
    BackgroundColor3 = C_BG,
    Visible          = false,
})
corner(container, 14)
new("UIGradient", {
    Parent   = container,
    Rotation = 130,
    Color    = ColorSequence.new({
        ColorSequenceKeypoint.new(0,   Color3.fromRGB(11,  3,  3)),
        ColorSequenceKeypoint.new(0.6, Color3.fromRGB(17,  5,  5)),
        ColorSequenceKeypoint.new(1,   Color3.fromRGB(24,  9,  9)),
    }),
})
local mainStroke = new("UIStroke", { Parent = container, Color = C_HOT, Thickness = 1.8, Transparency = 0.1 })
container.Active    = true
container.Selectable = true
makeDraggable(container)

task.spawn(function()
    local h = 0
    while container.Parent do
        h = (h + 0.4) % 360
        local s = math.abs(math.sin(math.rad(h)))
        mainStroke.Color = Color3.fromRGB(255, math.floor(30 + s * 40), math.floor(30 + s * 40))
        task.wait(0.05)
    end
end)

local header = new("Frame", {
    Parent           = container,
    Size             = UDim2.new(1, 0, 0, 38),
    BackgroundColor3 = C_DARK,
})
corner(header, 14)
redgrad(header, 0)
new("UIStroke", { Parent = header, Color = C_HOT, Thickness = 1, Transparency = 0.3 })

local title = new("TextLabel", {
    Parent              = header,
    Size                = UDim2.fromScale(1, 1),
    BackgroundTransparency = 1,
    Text                = "KenyahSENCE  |  FFlag Injector",
    Font                = Enum.Font.GothamBold,
    TextSize            = 13,
    TextColor3          = C_WHITE,
})

local closeBtn = new("TextButton", {
    Parent           = header,
    Size             = UDim2.fromOffset(20, 20),
    Position         = UDim2.new(1, -26, 0, 9),
    BackgroundColor3 = C_DIM,
    Text             = "X",
    Font             = Enum.Font.GothamBold,
    TextSize         = 11,
    TextColor3       = C_WHITE,
})
corner(closeBtn, 5)
hover(closeBtn)

local minBtn = new("TextButton", {
    Parent           = header,
    Size             = UDim2.fromOffset(20, 20),
    Position         = UDim2.new(1, -50, 0, 9),
    BackgroundColor3 = C_DIM,
    Text             = "-",
    Font             = Enum.Font.GothamBold,
    TextSize         = 11,
    TextColor3       = C_WHITE,
})
corner(minBtn, 5)
hover(minBtn)

local body    = new("Frame", { Parent = container, Position = UDim2.new(0, 0, 0, 38), Size = UDim2.new(1, 0, 1, -38), BackgroundTransparency = 1 })
local sidebar = new("Frame", { Parent = body, Size = UDim2.new(0, 66, 1, 0), BackgroundColor3 = C_PANEL })
corner(sidebar, 10)
new("UIGradient", {
    Parent   = sidebar,
    Rotation = 90,
    Color    = ColorSequence.new({
        ColorSequenceKeypoint.new(0, Color3.fromRGB(20, 5, 5)),
        ColorSequenceKeypoint.new(1, Color3.fromRGB(13, 3, 3)),
    }),
})

local content = new("Frame", { Parent = body, Position = UDim2.new(0, 72, 0, 0), Size = UDim2.new(1, -78, 1, 0), BackgroundTransparency = 1 })

local function makeTab(label, y)
    local b = new("TextButton", {
        Parent           = sidebar,
        Size             = UDim2.new(1, -8, 0, 26),
        Position         = UDim2.new(0, 4, 0, y),
        BackgroundColor3 = C_DIM,
        Text             = label,
        Font             = Enum.Font.GothamBold,
        TextSize         = 11,
        TextColor3       = C_WHITE,
    })
    corner(b, 7)
    hover(b)
    return b
end

local tabFF   = makeTab("Flags",  6)
local tabCfg  = makeTab("Config", 36)
local tabInfo = makeTab("Info",   66)

local pageFF  = new("Frame", { Parent = content, Size = UDim2.fromScale(1, 1), BackgroundTransparency = 1 })
local pageCfg = new("Frame", { Parent = content, Size = UDim2.fromScale(1, 1), BackgroundTransparency = 1, Visible = false })
local pageInf = new("Frame", { Parent = content, Size = UDim2.fromScale(1, 1), BackgroundTransparency = 1, Visible = false })

local function showPage(ff, cf, inf)
    pageFF.Visible  = ff
    pageCfg.Visible = cf
    pageInf.Visible = inf
end
tabFF.MouseButton1Click:Connect(function()   showPage(true,  false, false) end)
tabCfg.MouseButton1Click:Connect(function()  showPage(false, true,  false) end)
tabInfo.MouseButton1Click:Connect(function() showPage(false, false, true)  end)

local ffBox = new("TextBox", {
    Parent              = pageFF,
    Position            = UDim2.new(0, 3, 0, 4),
    Size                = UDim2.new(1, -6, 1, -116),
    MultiLine           = true,
    ClearTextOnFocus    = false,
    TextWrapped         = true,
    Font                = Enum.Font.Gotham,
    TextSize            = 11,
    BackgroundColor3    = C_CARD,
    TextColor3          = C_WHITE,
    PlaceholderText     = "Pega tu JSON aqui...",
    TextXAlignment      = Enum.TextXAlignment.Left,
    TextYAlignment      = Enum.TextYAlignment.Top,
})
corner(ffBox, 7)
new("UIStroke", { Parent = ffBox, Color = C_DARK, Thickness = 1, Transparency = 0.2 })

local sizeLabel = new("TextLabel", {
    Parent              = pageFF,
    Position            = UDim2.new(0, 3, 1, -110),
    Size                = UDim2.new(1, -6, 0, 13),
    BackgroundTransparency = 1,
    Font                = Enum.Font.GothamBold,
    TextSize            = 9,
    TextColor3          = C_TEXT,
    Text                = "0 KB",
    TextXAlignment      = Enum.TextXAlignment.Left,
})
ffBox:GetPropertyChangedSignal("Text"):Connect(function()
    local t = ffBox.Text or ""
    sizeLabel.Text = ("%.2f KB  /  %d chars"):format(#t / 1024, #t)
end)

local progBg = new("Frame", {
    Parent           = pageFF,
    Size             = UDim2.new(1, -6, 0, 8),
    Position         = UDim2.new(0, 3, 1, -92),
    BackgroundColor3 = Color3.fromRGB(28, 6, 6),
})
corner(progBg, 4)
local progFill = new("Frame", { Parent = progBg, Size = UDim2.new(0, 0, 1, 0), BackgroundColor3 = C_HOT })
corner(progFill, 4)
redgrad(progFill, 0)

local progText = new("TextLabel", {
    Parent              = pageFF,
    Position            = UDim2.new(0, 3, 1, -82),
    Size                = UDim2.new(1, -6, 0, 13),
    BackgroundTransparency = 1,
    Font                = Enum.Font.GothamBold,
    TextSize            = 9,
    TextColor3          = C_TEXT,
    Text                = "Listo",
    TextXAlignment      = Enum.TextXAlignment.Left,
})

local function makeBtn2(label, xs, xo, yo, accent)
    local b = new("TextButton", {
        Parent           = pageFF,
        Size             = UDim2.new(0.5, -4, 0, 23),
        Position         = UDim2.new(xs, xo, 1, yo),
        BackgroundColor3 = accent and C_HOT or C_DIM,
        Text             = label,
        Font             = Enum.Font.GothamBold,
        TextSize         = 11,
        TextColor3       = accent and Color3.new(0,0,0) or C_WHITE,
    })
    corner(b, 6)
    if accent then redgrad(b, 0) end
    hover(b)
    return b
end

local pauseBtn  = makeBtn2("Pausa",    0,   3, -64, false)
local cancelBtn = makeBtn2("Cancelar", 0.5, 1, -64, false)
local saveBtn   = makeBtn2("Sanitize", 0,   3, -37, false)
local injectBtn = makeBtn2("INJECT",   0.5, 1, -37, true)

local perfOverlay = new("Frame", {
    Parent           = gui,
    Size             = UDim2.fromOffset(160, 54),
    Position         = UDim2.new(1, -176, 0, 18),
    BackgroundColor3 = C_PANEL,
    Visible          = false,
})
corner(perfOverlay, 8)
redgrad(perfOverlay)
new("UIStroke", { Parent = perfOverlay, Color = C_HOT, Thickness = 1, Transparency = 0.2 })
local perfText = new("TextLabel", {
    Parent              = perfOverlay,
    Size                = UDim2.fromScale(1, 1),
    BackgroundTransparency = 1,
    Font                = Enum.Font.GothamBold,
    TextSize            = 12,
    TextColor3          = C_WHITE,
    Text                = "FPS --\nCPU -- ms",
})
local perfClose = new("TextButton", {
    Parent           = perfOverlay,
    Size             = UDim2.fromOffset(18, 18),
    Position         = UDim2.new(1, -22, 0, 3),
    BackgroundColor3 = C_DIM,
    Text             = "X",
    Font             = Enum.Font.GothamBold,
    TextSize         = 10,
    TextColor3       = C_WHITE,
})
corner(perfClose, 4)
perfOverlay.Active = true
makeDraggable(perfOverlay)
local SHOW_OVERLAY = false
perfClose.MouseButton1Click:Connect(function()
    SHOW_OVERLAY        = false
    perfOverlay.Visible = false
end)

local function addSetting(y, label, ctrl)
    new("TextLabel", {
        Parent              = pageCfg,
        Position            = UDim2.new(0, 5, 0, y),
        Size                = UDim2.new(1, -92, 0, 22),
        BackgroundTransparency = 1,
        Text                = label,
        Font                = Enum.Font.GothamBold,
        TextSize            = 11,
        TextColor3          = C_WHITE,
        TextXAlignment      = Enum.TextXAlignment.Left,
    })
    ctrl.Parent   = pageCfg
    ctrl.Position = UDim2.new(1, -85, 0, y)
end

local function toggle()
    local on = false
    local b = new("TextButton", {
        Size             = UDim2.fromOffset(72, 22),
        BackgroundColor3 = C_DIM,
        Text             = "OFF",
        Font             = Enum.Font.GothamBold,
        TextSize         = 11,
        TextColor3       = C_WHITE,
    })
    corner(b, 5)
    hover(b)
    b.MouseButton1Click:Connect(function()
        on = not on
        b.Text             = on and "ON" or "OFF"
        b.BackgroundColor3 = on and C_HOT or C_DIM
        b.TextColor3       = on and Color3.new(0,0,0) or C_WHITE
    end)
    return b, function() return on end
end

local overlayTgl,  getOverlay  = toggle()
local fastModeTgl, getFastMode = toggle()
local cpuTgl,      getCpuBoost = toggle()

addSetting(6,  "Mostrar FPS:", overlayTgl)
addSetting(34, "Fast Mode:",   fastModeTgl)
addSetting(62, "CPU Boost:",   cpuTgl)

overlayTgl.MouseButton1Click:Connect(function()
    SHOW_OVERLAY        = getOverlay()
    perfOverlay.Visible = SHOW_OVERLAY
end)

local cpuEm, cpuTr = {}, {}
local function setCpuBoost(on)
    task.spawn(function()
        if on then
            cpuEm, cpuTr = {}, {}
            for _, o in ipairs(workspace:GetDescendants()) do
                if o:IsA("BasePart") then o.Material = Enum.Material.Plastic; o.Reflectance = 0 end
                if o:IsA("ParticleEmitter") and o.Enabled then table.insert(cpuEm, o); o.Enabled = false end
                if o:IsA("Trail") and o.Enabled then table.insert(cpuTr, o); o.Enabled = false end
            end
            notify("CPU Boost ON")
        else
            for _, e in ipairs(cpuEm) do if e and e.Parent then e.Enabled = true end end
            for _, t in ipairs(cpuTr) do if t and t.Parent then t.Enabled = true end end
            cpuEm, cpuTr = {}, {}
            notify("CPU Boost OFF")
        end
    end)
end
cpuTgl.MouseButton1Click:Connect(function() setCpuBoost(getCpuBoost()) end)

new("TextLabel", {
    Parent              = pageInf,
    Position            = UDim2.new(0, 8, 0, 10),
    Size                = UDim2.new(1, -16, 0, 160),
    BackgroundTransparency = 1,
    Text                = "KenyahSENCE\n\nOwner: @0_kenyah\nDev:   @0_kenyah\n\nFFlag Injector v3\nRed Theme",
    Font                = Enum.Font.GothamBold,
    TextSize            = 13,
    TextColor3          = C_TEXT,
    TextXAlignment      = Enum.TextXAlignment.Left,
})

local function openUI()
    container.Visible = true
    overlay.Visible   = true
    overlay.BackgroundTransparency = 1
    TweenService:Create(overlay, TweenInfo.new(0.18), { BackgroundTransparency = 0.5 }):Play()
    container.BackgroundTransparency = 1
    local sz = UserInputService.TouchEnabled and UDim2.fromOffset(330, 370) or UDim2.fromOffset(330, 370)
    TweenService:Create(container, TweenInfo.new(0.28, Enum.EasingStyle.Back, Enum.EasingDirection.Out), {
        Size = sz, BackgroundTransparency = 0
    }):Play()
    dockIcon.Visible = false
end

local function closeUI()
    TweenService:Create(container, TweenInfo.new(0.18, Enum.EasingStyle.Sine, Enum.EasingDirection.In), { BackgroundTransparency = 1 }):Play()
    TweenService:Create(overlay,   TweenInfo.new(0.16), { BackgroundTransparency = 1 }):Play()
    task.delay(0.2, function()
        container.Visible = false
        overlay.Visible   = false
    end)
    dockIcon.Visible = true
end

closeBtn.MouseButton1Click:Connect(closeUI)
minBtn.MouseButton1Click:Connect(closeUI)
dockBtn.MouseButton1Click:Connect(openUI)
openUI()

local injState = { running = false, paused = false, cancel = false }

local hasSetfflag   = type(setfflag)   == "function"
local hasSetfint    = type(setfint)    == "function"
local hasSetfstring = type(setfstring) == "function"

local PREFIXES = { "DFFlag","FFlag","SFFlag","DFInt","FInt","DFString","FString","FLog" }

local function stripPfx(k)
    for _, p in ipairs(PREFIXES) do
        if k:sub(1, #p) == p then return k:sub(#p + 1) end
    end
    return k
end

local function flagType(k)
    for _, p in ipairs(PREFIXES) do
        if k:sub(1, #p) == p then
            local lp = p:lower()
            if lp:find("flag") then return "bool"
            elseif lp:find("int") then return "int"
            else return "str" end
        end
    end
    return "str"
end

local function injectOne(key, val)
    local vstr = tostring(val)
    local name = stripPfx(key)
    local kind = flagType(key)

    local bval
    do
        local l = vstr:lower()
        if l == "true"  or l == "1" or l == "yes" or l == "on"  then bval = "True"  end
        if l == "false" or l == "0" or l == "no"  or l == "off" then bval = "False" end
    end

    if hasSetfflag then
        if pcall(setfflag, key,  (kind == "bool" and bval) and bval or vstr) then return true end
        if pcall(setfflag, name, (kind == "bool" and bval) and bval or vstr) then return true end
    end

    if kind == "int" or tonumber(vstr) then
        local n = tonumber(vstr)
        if n then
            if hasSetfint then
                if pcall(setfint, key,  math.floor(n)) then return true end
                if pcall(setfint, name, math.floor(n)) then return true end
            end
            if hasSetfflag then
                if pcall(setfflag, key,  tostring(math.floor(n))) then return true end
                if pcall(setfflag, name, tostring(math.floor(n))) then return true end
            end
        end
    end

    if hasSetfstring then
        if pcall(setfstring, key,  vstr) then return true end
        if pcall(setfstring, name, vstr) then return true end
    end

    if bval and hasSetfflag then
        if pcall(setfflag, key,  bval) then return true end
        if pcall(setfflag, name, bval) then return true end
    end

    if hasSetfflag then
        if pcall(setfflag, key,  vstr) then return true end
        if pcall(setfflag, name, vstr) then return true end
    end

    return false
end

local function resolveInput(text)
    local t = (text or ""):match("^%s*(.-)%s*$"):gsub("#L%d+%-?%d*$", "")
    if t:lower():sub(-5) == ".json" then
        local ok, s = pcall(function() return readfile and readfile(t) end)
        if ok and type(s) == "string" and #s > 0 then return s end
    end
    return text
end

local function parseFallback(text)
    local tbl   = {}
    local clean = text:gsub("//[^\n]*", ""):gsub("/%*.-%*/", "")
    for line in clean:gmatch("[^\r\n]+") do
        local l   = line:gsub("[,%s]*$", "")
        local k, v
        k, v = l:match('"(.-)"%s*:%s*"(.-)"')
        if not k then k, v = l:match('"(.-)"%s*:%s*([^,}%s]+)') end
        if not k then k, v = l:match("^%s*([%w_%-]+)%s*=%s*(.+)%s*$") end
        if k and v then
            v      = v:match('^"(.*)"$') or v:match("^'(.*)'$") or v:gsub("%s+$", "")
            tbl[k] = v
        end
    end
    local n = 0
    for _ in pairs(tbl) do n = n + 1 end
    return n > 0 and tbl or nil
end

local LATE = {
    datasender = true, raknetuseslidingwindow = true, httpbatch = true,
    taskschedulertargetfps = true, assetpreloading = true,
    numassetsmaxtopreload = true, bandwidth = true,
    clientpacket = true, teleportclientassetpreloading = true,
}

local function buildList(data)
    local seen  = {}
    local early = {}
    local late  = {}
    for k, v in pairs(data) do
        local name = stripPfx(k)
        if not seen[name] then
            seen[name] = true
            local lk   = name:lower()
            local isL  = false
            for pat in pairs(LATE) do
                if lk:find(pat) then isL = true; break end
            end
            table.insert(isL and late or early, { k, tostring(v) })
        end
    end
    local res = {}
    for _, p in ipairs(early) do res[#res + 1] = p end
    for _, p in ipairs(late)  do res[#res + 1] = p end
    return res
end

local function injectFastFlags(text)
    local src  = resolveInput(text)
    local data

    local ok, tmp = pcall(function() return HttpService:JSONDecode(src) end)
    if ok and type(tmp) == "table" then
        data = tmp
    else
        data = parseFallback(src)
        if not data then
            notify("JSON invalido o formato no reconocido")
            injectBtn.Text   = "INJECT"
            injectBtn.Active = true
            return
        end
    end

    local flags = buildList(data)
    local total = #flags

    if total == 0 then
        notify("Sin flags encontradas")
        injectBtn.Text   = "INJECT"
        injectBtn.Active = true
        return
    end

    local FAST = getFastMode()

    task.spawn(function()
        injState.running = true
        injState.cancel  = false
        injState.paused  = false

        local done, good, bad = 0, 0, 0

        progText.Text = ("Inyectando %d flags..."):format(total)

        local BATCH  = FAST and 60 or 30
        local YIELD  = FAST and 0  or 0

        for i, pair in ipairs(flags) do
            while injState.paused do
                progText.Text = "Pausado..."
                RunService.Heartbeat:Wait()
            end
            if injState.cancel then
                progText.Text = ("Cancelado en %d/%d"):format(done, total)
                break
            end

            local k, v = pair[1], pair[2]

            pcall(function()
                if injectOne(k, v) then good = good + 1 else bad = bad + 1 end
            end)

            done = done + 1

            if done % BATCH == 0 or done == total then
                local pct = done / total
                TweenService:Create(progFill, TweenInfo.new(0.08), { Size = UDim2.new(pct, 0, 1, 0) }):Play()
                progText.Text = ("%d%%  %d/%d  ok:%d  fail:%d"):format(math.floor(pct * 100), done, total, good, bad)
                if YIELD > 0 then task.wait(YIELD) else RunService.Heartbeat:Wait() end
            end
        end

        progFill.Size  = UDim2.new(1, 0, 1, 0)
        local msg = ("Listo: ok %d  |  fail %d  |  total %d"):format(good, bad, total)
        progText.Text  = msg
        notify(msg)

        injState.running = false
        injectBtn.Text   = "INJECT"
        injectBtn.Active = true

        pcall(function()
            if getgenv().Neo and getgenv().Neo.Logger then
                getgenv().Neo.Logger.log("info", msg)
                getgenv().Neo.Logger.flush("NeoLog.txt")
            end
        end)
    end)
end

injectBtn.MouseButton1Click:Connect(function()
    if injState.running then return end
    injectBtn.Text         = "Inyectando..."
    injectBtn.Active       = false
    progFill.Size          = UDim2.new(0, 0, 1, 0)
    progText.Text          = "0%"
    injState.cancel        = false
    injState.paused        = false
    local ok, err = pcall(function() injectFastFlags(ffBox.Text) end)
    if not ok then
        notify("Error: " .. tostring(err))
        injectBtn.Text   = "INJECT"
        injectBtn.Active = true
    end
end)

pauseBtn.MouseButton1Click:Connect(function()
    if not injState.running then return end
    injState.paused = not injState.paused
    pauseBtn.Text   = injState.paused and "Reanudar" or "Pausa"
end)

cancelBtn.MouseButton1Click:Connect(function()
    if injState.running then injState.cancel = true end
end)

saveBtn.MouseButton1Click:Connect(function()
    local src = resolveInput(ffBox.Text)
    local ok, data = pcall(function() return HttpService:JSONDecode(src) end)
    if not ok or type(data) ~= "table" then notify("JSON invalido"); return end
    local out = {}
    for k, v in pairs(data) do
        local s  = tostring(v)
        local sl = s:lower()
        local tp = flagType(k)
        if tp == "bool" then
            if sl == "true"  or sl == "1" or sl == "yes" then s = "True"
            elseif sl == "false" or sl == "0" or sl == "no" then s = "False" end
        elseif tp == "int" then
            local n = tonumber(s); s = n and tostring(math.floor(n)) or "0"
        end
        out[k] = s
    end
    local enc  = HttpService:JSONEncode(out)
    local saved = pcall(function() if writefile then writefile("KyroDev-sanitized.json", enc) end end)
    if saved then notify("Guardado: KyroDev-sanitized.json") else ffBox.Text = enc; notify("Pegado en caja") end
end)

RunService.RenderStepped:Connect(function(dt)
    fps     = math.clamp(math.floor(1 / dt), 1, 240)
    frameMs = math.floor(dt * 1000 * 10) / 10
end)
RunService.Heartbeat:Connect(function(dt)
    cpuMs = math.floor(dt * 1000 * 10) / 10
end)

task.spawn(function()
    while perfOverlay.Parent do
        local sf = (getgenv().Neo and getgenv().Neo.State.fps)     or fps
        local sc = (getgenv().Neo and getgenv().Neo.State.cpuMs)   or cpuMs
        local sg = (getgenv().Neo and getgenv().Neo.State.frameMs) or frameMs
        perfText.Text = ("FPS %d\nCPU %.1f ms  GPU %.1f ms"):format(sf, sc, sg)
        task.wait(0.3)
    end
end)
