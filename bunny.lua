-- bunny.lua | KenyahSENCE Injector v2  (tema rojo degradado)
-- Carga neo_core si está disponible
do
    local ok, src = pcall(function() return readfile and readfile("neo_core.lua") end)
    if ok and type(src) == "string" and #src > 0 and type(loadstring) == "function" then
        pcall(function() loadstring(src)() end)
    end
end

-- ── Servicios ─────────────────────────────────────────────────────────────────
local Players          = game:GetService("Players")
local TweenService     = game:GetService("TweenService")
local UserInputService = game:GetService("UserInputService")
local RunService       = game:GetService("RunService")
local HttpService      = game:GetService("HttpService")

local player    = Players.LocalPlayer
local playerGui = player:WaitForChild("PlayerGui")

-- limpia GUI anterior
local prev = playerGui:FindFirstChild("KyroDev") or playerGui:FindFirstChild("KyroDevNeo")
if prev then prev:Destroy() end

-- ── Paleta roja ───────────────────────────────────────────────────────────────
local RED_HOT    = Color3.fromRGB(255, 45,  45)
local RED_DARK   = Color3.fromRGB(140,  0,   0)
local RED_GLOW   = Color3.fromRGB(255, 100, 100)
local RED_DIM    = Color3.fromRGB( 80,   8,   8)
local BG_BASE    = Color3.fromRGB(  8,   4,   4)
local BG_PANEL   = Color3.fromRGB( 14,   6,   6)
local BG_CARD    = Color3.fromRGB( 20,   8,   8)
local TEXT_WHITE = Color3.new(1, 1, 1)
local TEXT_RED   = Color3.fromRGB(255, 160, 160)

-- ── Estado de rendimiento ─────────────────────────────────────────────────────
local fps     = 60
local frameMs = 16
local cpuMs   = 16

-- ── Helpers UI ───────────────────────────────────────────────────────────────
local function new(class, props)
    local obj = Instance.new(class)
    for k, v in pairs(props or {}) do
        if k == "Parent" then obj.Parent = v else obj[k] = v end
    end
    return obj
end

local function round(obj, r)
    new("UICorner", { Parent = obj, CornerRadius = UDim.new(0, r) })
end

local function redGradient(parent, rot)
    rot = rot or 90
    new("UIGradient", {
        Parent   = parent,
        Rotation = rot,
        Color    = ColorSequence.new({
            ColorSequenceKeypoint.new(0,   Color3.fromRGB(160,  0,  0)),
            ColorSequenceKeypoint.new(0.5, Color3.fromRGB(220, 20, 20)),
            ColorSequenceKeypoint.new(1,   Color3.fromRGB(255, 60, 60)),
        })
    })
end

local function hoverEffect(btn)
    btn.AutoButtonColor = false
    local orig = btn.BackgroundColor3
    btn.MouseEnter:Connect(function()
        TweenService:Create(btn, TweenInfo.new(0.15), {
            BackgroundColor3    = RED_GLOW,
            BackgroundTransparency = 0.15,
        }):Play()
    end)
    btn.MouseLeave:Connect(function()
        TweenService:Create(btn, TweenInfo.new(0.2), {
            BackgroundColor3    = orig,
            BackgroundTransparency = 0,
        }):Play()
    end)
end

local function makeDraggable(frame, handle)
    local dragging, dragInput, startPos, startInput = false, nil, nil, nil
    handle.InputBegan:Connect(function(i)
        if i.UserInputType == Enum.UserInputType.MouseButton1
        or i.UserInputType == Enum.UserInputType.Touch then
            dragging   = true
            startPos   = frame.Position
            startInput = i.Position
            dragInput  = i
        end
    end)
    handle.InputChanged:Connect(function(i)
        if i.UserInputType == Enum.UserInputType.MouseMovement
        or i.UserInputType == Enum.UserInputType.Touch then
            dragInput = i
        end
    end)
    handle.InputEnded:Connect(function(i)
        if i == dragInput then dragging = false end
    end)
    UserInputService.InputChanged:Connect(function(i)
        if dragging and i == dragInput then
            local d = i.Position - startInput
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
        Size                = UDim2.fromOffset(340, 46),
        Position            = UDim2.new(0.5, -170, 1, -100),
        BackgroundColor3    = BG_PANEL,
        ZIndex              = 20,
    })
    round(n, 10)
    local stroke = new("UIStroke", { Parent = n, Color = RED_HOT, Thickness = 1.4, Transparency = 0.2 })
    redGradient(n, 0)
    local lbl = new("TextLabel", {
        Parent              = n,
        Size                = UDim2.fromScale(1, 1),
        BackgroundTransparency = 1,
        Text                = text,
        Font                = Enum.Font.GothamBold,
        TextSize            = 14,
        TextColor3          = TEXT_WHITE,
        ZIndex              = 21,
    })
    TweenService:Create(n, TweenInfo.new(0.22), { Position = UDim2.new(0.5, -170, 1, -124) }):Play()
    task.delay(2.6, function()
        TweenService:Create(n,   TweenInfo.new(0.2), { BackgroundTransparency = 1 }):Play()
        TweenService:Create(lbl, TweenInfo.new(0.2), { TextTransparency = 1 }):Play()
        task.delay(0.22, function() n:Destroy() end)
    end)
end

-- ── GUI principal ─────────────────────────────────────────────────────────────
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

-- Dock icon
local dockIcon = new("Frame", {
    Parent           = gui,
    Size             = UDim2.fromOffset(46, 46),
    Position         = UDim2.new(1, -58, 0, 86),
    BackgroundColor3 = BG_CARD,
    Visible          = true,
})
dockIcon.Active = true
round(dockIcon, 23)
redGradient(dockIcon)
new("UIStroke", { Parent = dockIcon, Color = RED_HOT, Thickness = 1.4, Transparency = 0.2 })
local dockBtn = new("TextButton", {
    Parent              = dockIcon,
    Size                = UDim2.fromScale(1, 1),
    BackgroundTransparency = 1,
    Text                = "◎",
    Font                = Enum.Font.GothamBold,
    TextSize            = 18,
    TextColor3          = RED_HOT,
})
makeDraggable(dockIcon, dockIcon)

-- Ventana principal
local container = new("Frame", {
    Parent           = gui,
    Size             = UDim2.fromOffset(380, 440),
    Position         = UDim2.new(0.5, -190, 0.5, -220),
    BackgroundColor3 = BG_BASE,
    Visible          = false,
})
round(container, 16)
new("UIGradient", {
    Parent   = container,
    Rotation = 135,
    Color    = ColorSequence.new({
        ColorSequenceKeypoint.new(0,   Color3.fromRGB(12,  3,  3)),
        ColorSequenceKeypoint.new(0.6, Color3.fromRGB(18,  5,  5)),
        ColorSequenceKeypoint.new(1,   Color3.fromRGB(26, 10, 10)),
    })
})
local mainStroke = new("UIStroke", { Parent = container, Thickness = 2, Transparency = 0.1 })
redGradient(mainStroke, 45)

-- Animar borde
task.spawn(function()
    local r = 0
    while container.Parent do
        r = (r + 1.5) % 360
        mainStroke.Color = Color3.fromHSV(0, 0.85, 1 - math.abs(math.sin(math.rad(r))) * 0.3)
        task.wait(0.04)
    end
end)

-- Header
local header = new("Frame", {
    Parent           = container,
    Size             = UDim2.new(1, 0, 0, 42),
    BackgroundColor3 = RED_DARK,
})
round(header, 16)
redGradient(header, 0)
new("UIStroke", { Parent = header, Color = RED_HOT, Thickness = 1, Transparency = 0.3 })

local title = new("TextLabel", {
    Parent              = header,
    Size                = UDim2.fromScale(1, 1),
    BackgroundTransparency = 1,
    Text                = "⚡ KenyahSENCE  ·  FFlag Injector",
    Font                = Enum.Font.GothamBold,
    TextSize            = 14,
    TextColor3          = TEXT_WHITE,
})

local closeBtn = new("TextButton", {
    Parent           = header,
    Size             = UDim2.fromOffset(22, 22),
    Position         = UDim2.new(1, -28, 0, 9),
    BackgroundColor3 = RED_DIM,
    Text             = "✕",
    Font             = Enum.Font.GothamBold,
    TextSize         = 12,
    TextColor3       = TEXT_WHITE,
})
round(closeBtn, 6)
hoverEffect(closeBtn)

local minimizeBtn = new("TextButton", {
    Parent           = header,
    Size             = UDim2.fromOffset(22, 22),
    Position         = UDim2.new(1, -54, 0, 9),
    BackgroundColor3 = RED_DIM,
    Text             = "—",
    Font             = Enum.Font.GothamBold,
    TextSize         = 12,
    TextColor3       = TEXT_WHITE,
})
round(minimizeBtn, 6)
hoverEffect(minimizeBtn)

-- Body
local body    = new("Frame", { Parent = container, Position = UDim2.new(0, 0, 0, 42), Size = UDim2.new(1, 0, 1, -42), BackgroundTransparency = 1 })
local sidebar = new("Frame", { Parent = body, Size = UDim2.new(0, 74, 1, 0), BackgroundColor3 = BG_PANEL })
round(sidebar, 12)
new("UIGradient", {
    Parent   = sidebar,
    Rotation = 90,
    Color    = ColorSequence.new({
        ColorSequenceKeypoint.new(0, Color3.fromRGB(22, 6, 6)),
        ColorSequenceKeypoint.new(1, Color3.fromRGB(14, 4, 4)),
    })
})

local content = new("Frame", { Parent = body, Position = UDim2.new(0, 80, 0, 0), Size = UDim2.new(1, -86, 1, 0), BackgroundTransparency = 1 })

local function makeTab(text, yPos)
    local btn = new("TextButton", {
        Parent           = sidebar,
        Size             = UDim2.new(1, -10, 0, 28),
        Position         = UDim2.new(0, 5, 0, yPos),
        BackgroundColor3 = RED_DIM,
        Text             = text,
        Font             = Enum.Font.GothamBold,
        TextSize         = 11,
        TextColor3       = TEXT_WHITE,
    })
    round(btn, 8)
    hoverEffect(btn)
    return btn
end

local tabFF       = makeTab("Flags",  8)
local tabSettings = makeTab("Config", 40)
local tabCredits  = makeTab("Info",   72)

-- Páginas
local pageFF       = new("Frame", { Parent = content, Size = UDim2.fromScale(1, 1), BackgroundTransparency = 1 })
local pageSettings = new("Frame", { Parent = content, Size = UDim2.fromScale(1, 1), BackgroundTransparency = 1, Visible = false })
local pageCredits  = new("Frame", { Parent = content, Size = UDim2.fromScale(1, 1), BackgroundTransparency = 1, Visible = false })

local function showPage(ff, st, cr)
    pageFF.Visible       = ff
    pageSettings.Visible = st
    pageCredits.Visible  = cr
end
tabFF.MouseButton1Click:Connect(function()       showPage(true,  false, false) end)
tabSettings.MouseButton1Click:Connect(function() showPage(false, true,  false) end)
tabCredits.MouseButton1Click:Connect(function()  showPage(false, false, true)  end)

-- ── Página Flags ──────────────────────────────────────────────────────────────
local ffBox = new("TextBox", {
    Parent              = pageFF,
    Position            = UDim2.new(0, 4, 0, 6),
    Size                = UDim2.new(1, -8, 1, -128),
    MultiLine           = true,
    ClearTextOnFocus    = false,
    TextWrapped         = true,
    Font                = Enum.Font.Gotham,
    TextSize            = 11,
    BackgroundColor3    = BG_CARD,
    TextColor3          = TEXT_WHITE,
    PlaceholderText     = "Pega tu JSON de FFlags aquí…",
    TextXAlignment      = Enum.TextXAlignment.Left,
    TextYAlignment      = Enum.TextYAlignment.Top,
})
round(ffBox, 8)
new("UIStroke", { Parent = ffBox, Color = RED_DARK, Thickness = 1, Transparency = 0.3 })

local bufferInfo = new("TextLabel", {
    Parent              = pageFF,
    Position            = UDim2.new(0, 4, 1, -120),
    Size                = UDim2.new(1, -8, 0, 14),
    BackgroundTransparency = 1,
    Font                = Enum.Font.GothamBold,
    TextSize            = 10,
    TextColor3          = TEXT_RED,
    Text                = "0 KB",
    TextXAlignment      = Enum.TextXAlignment.Left,
})
ffBox:GetPropertyChangedSignal("Text"):Connect(function()
    bufferInfo.Text = ("%.2f KB  ·  %d chars"):format(#(ffBox.Text or "") / 1024, #(ffBox.Text or ""))
end)

-- Barra de progreso roja
local progressBg = new("Frame", {
    Parent           = pageFF,
    Size             = UDim2.new(1, -8, 0, 9),
    Position         = UDim2.new(0, 4, 1, -100),
    BackgroundColor3 = Color3.fromRGB(30, 8, 8),
})
round(progressBg, 5)
local progressFill = new("Frame", {
    Parent           = progressBg,
    Size             = UDim2.new(0, 0, 1, 0),
    BackgroundColor3 = RED_HOT,
})
round(progressFill, 5)
redGradient(progressFill, 0)

local progressText = new("TextLabel", {
    Parent              = pageFF,
    Position            = UDim2.new(0, 4, 1, -89),
    Size                = UDim2.new(1, -8, 0, 14),
    BackgroundTransparency = 1,
    Font                = Enum.Font.GothamBold,
    TextSize            = 10,
    TextColor3          = TEXT_RED,
    Text                = "Listo",
    TextXAlignment      = Enum.TextXAlignment.Left,
})

-- Botones de control
local function makeBtn(text, xScale, xOff, yOff, w, accent)
    local bg = accent and RED_HOT or RED_DIM
    local tc = accent and Color3.new(0, 0, 0) or TEXT_WHITE
    local btn = new("TextButton", {
        Parent           = pageFF,
        Size             = UDim2.new(w, -4, 0, 26),
        Position         = UDim2.new(xScale, xOff, 1, yOff),
        BackgroundColor3 = bg,
        Text             = text,
        Font             = Enum.Font.GothamBold,
        TextSize         = 12,
        TextColor3       = tc,
    })
    round(btn, 7)
    if accent then redGradient(btn, 0) end
    hoverEffect(btn)
    return btn
end

local pauseBtn    = makeBtn("⏸ Pausa",   0,    4, -74, 0.5, false)
local cancelBtn   = makeBtn("✕ Cancelar",0.5,  2, -74, 0.5, false)
local sanitizeBtn = makeBtn("🛡 Sanitize",0,   4, -44, 0.5, false)
local injectBtn   = makeBtn("⚡ INJECT",  0.5,  2, -44, 0.5, true)

-- ── Overlay FPS ──────────────────────────────────────────────────────────────
local perfOverlay = new("Frame", {
    Parent           = gui,
    Size             = UDim2.fromOffset(170, 62),
    Position         = UDim2.new(1, -185, 0, 22),
    BackgroundColor3 = BG_PANEL,
    Visible          = false,
})
round(perfOverlay, 10)
redGradient(perfOverlay)
new("UIStroke", { Parent = perfOverlay, Color = RED_HOT, Thickness = 1.2, Transparency = 0.2 })
local perfText = new("TextLabel", {
    Parent              = perfOverlay,
    Size                = UDim2.fromScale(1, 1),
    BackgroundTransparency = 1,
    Font                = Enum.Font.GothamBold,
    TextSize            = 13,
    TextColor3          = TEXT_WHITE,
    Text                = "FPS --\nCPU -- ms",
})
local perfClose = new("TextButton", {
    Parent           = perfOverlay,
    Size             = UDim2.fromOffset(22, 22),
    Position         = UDim2.new(1, -26, 0, 4),
    BackgroundColor3 = RED_DIM,
    Text             = "✕",
    Font             = Enum.Font.GothamBold,
    TextSize         = 12,
    TextColor3       = TEXT_WHITE,
})
round(perfClose, 5)
perfOverlay.Active = true
makeDraggable(perfOverlay, perfOverlay)
local SHOW_OVERLAY = false
perfClose.MouseButton1Click:Connect(function()
    SHOW_OVERLAY = false
    perfOverlay.Visible = false
end)

-- ── Página Config ─────────────────────────────────────────────────────────────
local function addSetting(y, label, control)
    new("TextLabel", {
        Parent              = pageSettings,
        Position            = UDim2.new(0, 6, 0, y),
        Size                = UDim2.new(1, -96, 0, 24),
        BackgroundTransparency = 1,
        Text                = label,
        Font                = Enum.Font.GothamBold,
        TextSize            = 12,
        TextColor3          = TEXT_WHITE,
        TextXAlignment      = Enum.TextXAlignment.Left,
    })
    control.Parent   = pageSettings
    control.Position = UDim2.new(1, -88, 0, y)
end

local function makeToggle()
    local t = new("TextButton", {
        Size             = UDim2.fromOffset(80, 24),
        BackgroundColor3 = RED_DIM,
        Text             = "OFF",
        Font             = Enum.Font.GothamBold,
        TextSize         = 12,
        TextColor3       = TEXT_WHITE,
    })
    round(t, 6)
    hoverEffect(t)
    t.MouseButton1Click:Connect(function()
        local on = t.Text == "OFF"
        t.Text             = on and "ON" or "OFF"
        t.BackgroundColor3 = on and RED_HOT or RED_DIM
        t.TextColor3       = on and Color3.new(0, 0, 0) or TEXT_WHITE
    end)
    return t
end

local overlayToggle  = makeToggle()
local fastModeToggle = makeToggle()
local cpuBoostToggle = makeToggle()

addSetting(8,  "Mostrar FPS:",  overlayToggle)
addSetting(38, "Fast Mode:",    fastModeToggle)
addSetting(68, "CPU Boost:",    cpuBoostToggle)

overlayToggle.MouseButton1Click:Connect(function()
    SHOW_OVERLAY        = overlayToggle.Text == "ON"
    perfOverlay.Visible = SHOW_OVERLAY
end)

local cpuBoostEmitters, cpuBoostTrails = {}, {}
local function setCpuBoost(on)
    task.spawn(function()
        if on then
            cpuBoostEmitters, cpuBoostTrails = {}, {}
            for _, o in ipairs(workspace:GetDescendants()) do
                if o:IsA("BasePart") then
                    o.Material   = Enum.Material.Plastic
                    o.Reflectance = 0
                end
                if o:IsA("ParticleEmitter") and o.Enabled then
                    table.insert(cpuBoostEmitters, o); o.Enabled = false
                end
                if o:IsA("Trail") and o.Enabled then
                    table.insert(cpuBoostTrails, o); o.Enabled = false
                end
            end
            notify("CPU Boost ON")
        else
            for _, e in ipairs(cpuBoostEmitters) do if e and e.Parent then e.Enabled = true end end
            for _, t in ipairs(cpuBoostTrails)   do if t and t.Parent then t.Enabled = true end end
            cpuBoostEmitters, cpuBoostTrails = {}, {}
            notify("CPU Boost OFF")
        end
    end)
end
cpuBoostToggle.MouseButton1Click:Connect(function()
    setCpuBoost(cpuBoostToggle.Text == "ON")
end)

-- ── Página Info ───────────────────────────────────────────────────────────────
new("TextLabel", {
    Parent              = pageCredits,
    Position            = UDim2.new(0, 10, 0, 14),
    Size                = UDim2.new(1, -20, 0, 140),
    BackgroundTransparency = 1,
    Text                = "KenyahSENCE\n\nOwner:    @0_kenyah\nLead Dev: @0_kenyah\n\nFFlag Injector v2\nTema rojo · Zero-crash pcall",
    Font                = Enum.Font.GothamBold,
    TextSize            = 14,
    TextColor3          = TEXT_RED,
    TextXAlignment      = Enum.TextXAlignment.Left,
})

-- ── Abrir / Cerrar UI ─────────────────────────────────────────────────────────
local ANIM = true

local function openUI()
    container.Visible = true
    overlay.Visible   = true
    if ANIM then
        overlay.BackgroundTransparency = 1
        TweenService:Create(overlay, TweenInfo.new(0.2), { BackgroundTransparency = 0.5 }):Play()
        container.BackgroundTransparency = 1
        local sz = UserInputService.TouchEnabled and UDim2.fromOffset(370, 420) or UDim2.fromOffset(400, 450)
        TweenService:Create(container, TweenInfo.new(0.3, Enum.EasingStyle.Back, Enum.EasingDirection.Out), {
            Size = sz, BackgroundTransparency = 0
        }):Play()
    end
    dockIcon.Visible = false
end

local function closeUI()
    if ANIM then
        TweenService:Create(container, TweenInfo.new(0.2, Enum.EasingStyle.Sine, Enum.EasingDirection.In), {
            BackgroundTransparency = 1
        }):Play()
        TweenService:Create(overlay, TweenInfo.new(0.18), { BackgroundTransparency = 1 }):Play()
        task.delay(0.22, function()
            container.Visible = false
            overlay.Visible   = false
        end)
    else
        container.Visible = false
        overlay.Visible   = false
    end
    dockIcon.Visible = true
end

closeBtn.MouseButton1Click:Connect(closeUI)
minimizeBtn.MouseButton1Click:Connect(closeUI)
dockBtn.MouseButton1Click:Connect(openUI)
container.Active    = true
container.Selectable = true
makeDraggable(container, header)
openUI()

-- ══════════════════════════════════════════════════════════════════════════════
--  MOTOR DE INYECCIÓN
-- ══════════════════════════════════════════════════════════════════════════════

local injectionState = { running = false, paused = false, cancel = false }
local FAST_MODE      = false

-- Soporte del executor
local Support = {
    setfflag   = type(setfflag)   == "function",
    setfint    = type(setfint)    == "function",
    setfstring = type(setfstring) == "function",
}

-- Prefijos reconocidos
local PREFIXES = { "DFFlag","FFlag","SFFlag","DFInt","FInt","DFString","FString","FLog" }

local function stripPrefix(flag)
    for _, p in ipairs(PREFIXES) do
        if flag:sub(1, #p) == p then return flag:sub(#p + 1) end
    end
    return flag
end

-- Detectar tipo de flag
local function flagKind(key)
    for _, p in ipairs(PREFIXES) do
        if key:sub(1, #p) == p then
            local lp = p:lower()
            if lp:find("flag") then return "flag"
            elseif lp:find("int") then return "int"
            else return "string" end
        end
    end
    -- fallback por valor
    return nil
end

-- ── Setter de bandera — sin validación de valor, pcall en cada intento ────────
local function injectOne(key, value)
    local vstr = tostring(value)
    local name = stripPrefix(key)
    local kind = flagKind(key)

    -- Normalizar booleans para flags
    local boolVal
    do
        local l = vstr:lower()
        if l == "true" or l == "1" or l == "yes" or l == "on" then
            boolVal = "True"
        elseif l == "false" or l == "0" or l == "no" or l == "off" then
            boolVal = "False"
        end
    end

    -- Intentos en orden de prioridad; cada uno protegido con pcall
    -- 1) setfflag con key completa
    if Support.setfflag then
        local val = (kind == "flag" and boolVal) and boolVal or vstr
        if pcall(setfflag, key, val) then return true end
    end
    -- 2) setfflag con nombre sin prefijo
    if Support.setfflag then
        local val = (kind == "flag" and boolVal) and boolVal or vstr
        if pcall(setfflag, name, val) then return true end
    end
    -- 3) setfint (si es entero)
    if kind == "int" or tonumber(vstr) then
        local n = tonumber(vstr)
        if n then
            if Support.setfint then
                if pcall(setfint, key,  math.floor(n)) then return true end
                if pcall(setfint, name, math.floor(n)) then return true end
            end
            -- fallback string del número
            if Support.setfflag then
                if pcall(setfflag, key,  tostring(math.floor(n))) then return true end
                if pcall(setfflag, name, tostring(math.floor(n))) then return true end
            end
        end
    end
    -- 4) setfstring
    if Support.setfstring then
        if pcall(setfstring, key,  vstr) then return true end
        if pcall(setfstring, name, vstr) then return true end
    end
    -- 5) Último recurso: boolean normalizado vía setfflag
    if boolVal and Support.setfflag then
        if pcall(setfflag, key,  boolVal) then return true end
        if pcall(setfflag, name, boolVal) then return true end
    end

    return false
end

-- ── Parser de entrada ─────────────────────────────────────────────────────────
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
        if not k then k, v = l:match('"(.-)"%s*:%s*([^,}]+)') end
        if not k then k, v = l:match("^%s*([%w_%-]+)%s*=%s*(.+)%s*$") end
        if k and v then
            v = v:match('^"(.*)"$') or v:match("^'(.*)'$") or v:gsub("%s+$", "")
            tbl[k] = v
        end
    end
    local n = 0
    for _ in pairs(tbl) do n = n + 1 end
    return n > 0 and tbl or nil
end

-- ── Agrupar y ordenar flags ───────────────────────────────────────────────────
local LATE_KEYS = { "datasender","raknetuseslidingwindow","httpbatch","taskschedulertargetfps","assetpreloading","numassetsmaxtopreload","bandwidth","clientpacket","teleportclientassetpreloading" }

local function buildFlagList(data)
    local seen   = {}
    local early  = {}
    local late   = {}
    for k, v in pairs(data) do
        local name = stripPrefix(k)
        if not seen[name] then
            seen[name]  = true
            local lk   = name:lower()
            local isLate = false
            for _, pat in ipairs(LATE_KEYS) do
                if lk:find(pat) then isLate = true; break end
            end
            local target = isLate and late or early
            table.insert(target, { k, tostring(v) })
        end
    end
    -- Ints primero dentro de cada grupo
    local function sortGroup(g)
        table.sort(g, function(a, b)
            local ai = flagKind(a[1]) == "int"
            local bi = flagKind(b[1]) == "int"
            if ai ~= bi then return ai end
            return a[1] < b[1]
        end)
    end
    sortGroup(early); sortGroup(late)
    local res = {}
    for _, p in ipairs(early) do res[#res + 1] = p end
    for _, p in ipairs(late)  do res[#res + 1] = p end
    return res
end

-- ── Loop de inyección ─────────────────────────────────────────────────────────
local function injectFastFlags(text)
    local src       = resolveInput(text)
    local sizeBytes = #src

    -- Parseo JSON con fallback
    local data
    local ok, tmp = pcall(function() return HttpService:JSONDecode(src) end)
    if ok and type(tmp) == "table" then
        data = tmp
    else
        data = parseFallback(src)
        if not data then
            notify("❌ JSON inválido o formato no reconocido")
            injectBtn.Text   = "⚡ INJECT"
            injectBtn.Active = true
            return
        end
    end

    local flags = buildFlagList(data)
    local total = #flags

    if total == 0 then
        notify("No se encontraron flags")
        injectBtn.Text   = "⚡ INJECT"
        injectBtn.Active = true
        return
    end

    FAST_MODE = fastModeToggle and fastModeToggle.Text == "ON" or false

    task.spawn(function()
        injectionState.running = true
        injectionState.cancel  = false
        injectionState.paused  = false

        local done    = 0
        local ok_     = 0
        local failed  = 0
        local skipped = 0

        -- Tiempo de frame máximo (mayor = más rápido)
        local FRAME_MS = FAST_MODE and 0.020 or 0.010

        progressText.Text = ("Inyectando %d flags…"):format(total)

        for i, pair in ipairs(flags) do
            -- Pausa
            while injectionState.paused do
                progressText.Text = "⏸ Pausado…"
                RunService.Heartbeat:Wait()
            end
            -- Cancelar
            if injectionState.cancel then
                progressText.Text = "✕ Cancelado en " .. done .. "/" .. total
                break
            end

            local k, v = pair[1], pair[2]

            -- ── Intento de inyección, totalmente protegido ──
            local success = pcall(function()
                local r = injectOne(k, v)
                if r then ok_ = ok_ + 1 else failed = failed + 1 end
            end)
            if not success then
                skipped = skipped + 1
            end

            done = done + 1

            -- Actualizar barra cada 20 flags
            if done % 20 == 0 or done == total then
                local pct = done / total
                TweenService:Create(progressFill, TweenInfo.new(0.1), { Size = UDim2.new(pct, 0, 1, 0) }):Play()
                progressText.Text = ("%d%% — %d/%d  ✔%d ✘%d"):format(math.floor(pct * 100), done, total, ok_, failed)
            end

            -- Yield mínimo para no congelar
            if done % 80 == 0 then
                RunService.Heartbeat:Wait()
            end
        end

        -- Resultado final
        progressFill.Size = UDim2.new(1, 0, 1, 0)
        local msg = ("✔ %d/%d  |  ✘ %d  |  skip %d"):format(ok_, total, failed, skipped)
        progressText.Text = msg
        notify(msg)

        injectionState.running = false
        injectBtn.Text         = "⚡ INJECT"
        injectBtn.Active       = true

        if getgenv().Neo and getgenv().Neo.Logger then
            getgenv().Neo.Logger.log("info", "Inyección completa: " .. msg)
            getgenv().Neo.Logger.flush("NeoLog.txt")
        end
    end)
end

-- ── Botones de acción ─────────────────────────────────────────────────────────
injectBtn.MouseButton1Click:Connect(function()
    if injectionState.running then return end
    injectBtn.Text             = "Inyectando…"
    injectBtn.Active           = false
    progressFill.Size          = UDim2.new(0, 0, 1, 0)
    progressText.Text          = "0%"
    injectionState.cancel      = false
    injectionState.paused      = false
    local ok, err = pcall(function() injectFastFlags(ffBox.Text) end)
    if not ok then
        notify("Error: " .. tostring(err))
        injectBtn.Text   = "⚡ INJECT"
        injectBtn.Active = true
    end
end)

pauseBtn.MouseButton1Click:Connect(function()
    if not injectionState.running then return end
    injectionState.paused = not injectionState.paused
    pauseBtn.Text = injectionState.paused and "▶ Reanudar" or "⏸ Pausa"
end)

cancelBtn.MouseButton1Click:Connect(function()
    if injectionState.running then
        injectionState.cancel = true
    end
end)

sanitizeBtn.MouseButton1Click:Connect(function()
    -- Solo normaliza booleans/enteros sin bloquear valores
    local src = resolveInput(ffBox.Text)
    local ok, data = pcall(function() return HttpService:JSONDecode(src) end)
    if not ok or type(data) ~= "table" then
        notify("JSON inválido para sanitize")
        return
    end
    local out = {}
    for k, v in pairs(data) do
        local kk = flagKind(k)
        local s  = tostring(v)
        local sl = s:lower()
        if kk == "flag" then
            if sl == "true"  or sl == "1" or sl == "yes" then s = "True"
            elseif sl == "false" or sl == "0" or sl == "no" then s = "False" end
        elseif kk == "int" then
            local n = tonumber(s)
            s = n and tostring(math.floor(n)) or "0"
        end
        out[k] = s
    end
    local encoded = HttpService:JSONEncode(out)
    local saved = pcall(function()
        if writefile then writefile("KyroDev-sanitized.json", encoded) end
    end)
    if saved then
        notify("Guardado: KyroDev-sanitized.json")
    else
        ffBox.Text = encoded
        notify("Pegado en caja (no hay writefile)")
    end
end)

-- ── Medición de FPS ──────────────────────────────────────────────────────────
RunService.RenderStepped:Connect(function(dt)
    fps     = math.clamp(math.floor(1 / dt), 1, 240)
    frameMs = math.floor(dt * 1000 * 10) / 10
end)
RunService.Heartbeat:Connect(function(dt)
    cpuMs = math.floor(dt * 1000 * 10) / 10
end)

task.spawn(function()
    while perfOverlay.Parent do
        local sf = (getgenv().Neo and getgenv().Neo.State.fps)    or fps
        local sc = (getgenv().Neo and getgenv().Neo.State.cpuMs)  or cpuMs
        local sg = (getgenv().Neo and getgenv().Neo.State.frameMs) or frameMs
        perfText.Text = ("FPS %d\nCPU %.1f ms  GPU %.1f ms"):format(sf, sc, sg)
        task.wait(0.3)
    end
end)
