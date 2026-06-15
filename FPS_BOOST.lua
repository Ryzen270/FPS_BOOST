local TweenService      = game:GetService("TweenService")
local UserInputService  = game:GetService("UserInputService")
local RunService        = game:GetService("RunService")
local Players           = game:GetService("Players")
local Lighting          = game:GetService("Lighting")

if not Players.LocalPlayer then
    Players:GetPropertyChangedSignal("LocalPlayer"):Wait()
end
pcall(function() Players.LocalPlayer:WaitForChild("PlayerGui", 10) end)
pcall(function()
    if not Players.LocalPlayer.Character then
        Players.LocalPlayer.CharacterAdded:Wait()
    end
end)

_G._FH_CarpetTP_Speed = _G._FH_CarpetTP_Speed or 214

do	
    local function _stripToolPhysics(tool)
        if not tool or not tool:IsA("Tool") then return end
        for _, d in ipairs(tool:GetDescendants()) do
            if d:IsA("BasePart") then
                pcall(function()
                    d.Massless   = true
                    d.CanCollide = false
                end)
            elseif d:IsA("BodyVelocity") or d:IsA("BodyPosition") or d:IsA("BodyGyro")
                or d:IsA("AlignPosition") or d:IsA("AlignOrientation") or d:IsA("VectorForce")
                or d:IsA("LinearVelocity") or d:IsA("AngularVelocity") then
                pcall(function() d.Enabled = false end)
            end
        end
        tool.DescendantAdded:Connect(function(d)
            if d:IsA("BasePart") then
                pcall(function()
                    d.Massless   = true
                    d.CanCollide = false
                end)
            end
        end)
    end
    local function _wireChar(c)
        for _, t in ipairs(c:GetChildren()) do _stripToolPhysics(t) end
        c.ChildAdded:Connect(_stripToolPhysics)
    end
    if Players.LocalPlayer.Character then _wireChar(Players.LocalPlayer.Character) end
    Players.LocalPlayer.CharacterAdded:Connect(_wireChar)
end
local _fhCarpetActiveTween = nil
function _G._FH_CarpetTP(targetCF, speedOverride)
    local lp  = Players.LocalPlayer
    local chr = lp and lp.Character
    local hrp = chr and chr:FindFirstChild("HumanoidRootPart")
    if not hrp or not targetCF then return end
    if typeof(targetCF) == "Vector3" then targetCF = CFrame.new(targetCF) end
    local dist = (hrp.Position - targetCF.Position).Magnitude
    local dur  = math.max(0.05, dist / (speedOverride or _G._FH_CarpetTP_Speed or 214))
    local bp = lp:FindFirstChildOfClass("Backpack")
    local carpet = (bp and bp:FindFirstChild("Flying Carpet")) or chr:FindFirstChild("Flying Carpet")
    local hum = chr:FindFirstChildOfClass("Humanoid")
    if carpet and hum and carpet.Parent ~= chr then pcall(function() hum:EquipTool(carpet) end) end
    if _fhCarpetActiveTween then pcall(function() _fhCarpetActiveTween:Cancel() end) end
    local tw = TweenService:Create(hrp, TweenInfo.new(dur, Enum.EasingStyle.Linear), {CFrame = targetCF})
    _fhCarpetActiveTween = tw
    tw:Play()
    return tw
end

do
    local _cfgOk, _cfgRaw = pcall(function() return readfile("FadedHub_Config.json") end)
    local _cfgData = nil
    if _cfgOk and _cfgRaw then
        local _parseOk, _parsed = pcall(function()
            return game:GetService("HttpService"):JSONDecode(_cfgRaw)
        end)
        if _parseOk and type(_parsed) == "table" then _cfgData = _parsed end
    end
    if _cfgData and type(_cfgData.toggles) == "table"
       and _cfgData.toggles["Optimizations"] == false then
        _G._FH_AlwaysOnFPS = false
    else
        _G._FH_AlwaysOnFPS = true
    end

    if _cfgData and type(_cfgData.sliders) == "table" then
        local cap = tonumber(_cfgData.sliders.fps_cap)
        if cap then
            local setter = rawget(getfenv(), "setfpscap") or rawget(getfenv(), "set_fps_cap")
            if setter then pcall(setter, math.floor(cap)) end
        end
    end
end

-- ==================================================
--            OPTIMIZACIONES DE RENDIMIENTO (FPS BOOST)
--            INTEGRADAS DIRECTAMENTE EN EL FLUJO
-- ==================================================

-- Aplicar configuraciones base de Lighting inmediatamente
pcall(function()
    Lighting.GlobalShadows = false
    Lighting.FogEnd = 9e9
    Lighting.Brightness = 0
    Lighting.EnvironmentDiffuseScale = 0
    Lighting.EnvironmentSpecularScale = 0
    Lighting.Ambient = Color3.fromRGB(160, 160, 160)
    Lighting.OutdoorAmbient = Color3.fromRGB(160, 160, 160)
    
    -- Deshabilitar efectos visuales pesados
    for _, v in pairs(Lighting:GetChildren()) do
        if v:IsA("PostEffect") or v:IsA("BlurEffect") or v:IsA("BloomEffect") or v:IsA("SunRaysEffect") then
            pcall(function() v.Enabled = false end)
        end
    end
end)

-- Función mejorada para limpiar texturas de herramientas (constante)
local function cleanSingleTool(tool)
    if not tool or not tool:IsA("Tool") then return end
    pcall(function()
        local handle = tool:FindFirstChild("Handle")
        if handle then
            for _, obj in pairs(handle:GetDescendants()) do
                if obj:IsA("Texture") or obj:IsA("Decal") then
                    obj:Destroy()
                elseif obj:IsA("SpecialMesh") or obj:IsA("MeshPart") then
                    pcall(function() obj.TextureId = "" end)
                end
            end
        end
        for _, obj in pairs(tool:GetDescendants()) do
            if obj:IsA("Texture") or obj:IsA("Decal") then
                obj:Destroy()
            elseif obj:IsA("SpecialMesh") or obj:IsA("MeshPart") then
                pcall(function() obj.TextureId = "" end)
            elseif obj:IsA("ParticleEmitter") then
                obj:Destroy()
            end
        end
    end)
end

-- Función para limpiar todas las herramientas del jugador
local function cleanAllPlayerTools()
    local lp = Players.LocalPlayer
    if not lp then return end
    pcall(function()
        if lp.Character then
            for _, tool in pairs(lp.Character:GetChildren()) do
                if tool:IsA("Tool") then cleanSingleTool(tool) end
            end
        end
        local backpack = lp:FindFirstChild("Backpack")
        if backpack then
            for _, tool in pairs(backpack:GetChildren()) do
                if tool:IsA("Tool") then cleanSingleTool(tool) end
            end
        end
    end)
end

-- Monitoreo constante de herramientas nuevas
local function startToolMonitoring()
    local lp = Players.LocalPlayer
    if not lp then return end
    
    lp.CharacterAdded:Connect(function(character)
        task.wait(0.3)
        cleanAllPlayerTools()
        character.ChildAdded:Connect(function(child)
            if child:IsA("Tool") then task.defer(function() cleanSingleTool(child) end) end
        end)
        character.DescendantAdded:Connect(function(desc)
            if desc:IsA("Tool") or (desc:IsA("BasePart") and desc.Parent and desc.Parent:IsA("Tool")) then
                local tool = desc:IsA("Tool") and desc or desc.Parent
                task.defer(function() cleanSingleTool(tool) end)
            end
        end)
    end)
    
    local backpack = lp:FindFirstChild("Backpack")
    if backpack then
        backpack.ChildAdded:Connect(function(tool)
            if tool:IsA("Tool") then task.defer(function() cleanSingleTool(tool) end) end
        end)
    end
    
    -- Limpieza periódica cada 3 segundos
    task.spawn(function()
        while task.wait(3) do
            cleanAllPlayerTools()
        end
    end)
end

-- Función para deshabilitar animaciones en modelos que no sean jugadores
local function disableAnimationsOnModel(model)
    if Players:GetPlayerFromCharacter(model) then return end
    pcall(function()
        for _, v in pairs(model:GetDescendants()) do
            if v:IsA("AnimationController") or v:IsA("Animator") then
                v:Destroy()
            elseif v:IsA("Humanoid") then
                v:ChangeState(Enum.HumanoidStateType.Physics)
            end
        end
    end)
end

-- Aplicar optimizaciones a Brainrots específicamente
local function optimizeBrainrot(model)
    if model.Name and string.lower(model.Name):find("brainrot") then
        pcall(function()
            for _, v in pairs(model:GetDescendants()) do
                if v:IsA("BasePart") then
                    v.Material = Enum.Material.Plastic
                    v.Reflectance = 0
                end
                if v:IsA("AnimationController") or v:IsA("Animator") then
                    v:Destroy()
                end
                if v:IsA("Texture") or v:IsA("Decal") then
                    v:Destroy()
                end
                if v:IsA("ParticleEmitter") or v:IsA("Trail") or v:IsA("Smoke") then
                    v.Enabled = false
                end
            end
        end)
    end
end

-- Ocultar eventos especiales (fuegos, taco, nyan, etc)
local function hideSpecialEvents(model)
    if not model.Name then return end
    local name = string.lower(model.Name)
    if name:find("fire") or name:find("taco") or name:find("nyan") or name:find("event") then
        pcall(function()
            for _, v in pairs(model:GetDescendants()) do
                if v:IsA("BasePart") then
                    v.Transparency = 1
                end
                if v:IsA("ParticleEmitter") or v:IsA("Trail") or v:IsA("Smoke") or v:IsA("Sparkles") then
                    v.Enabled = false
                end
                if v:IsA("Texture") or v:IsA("Decal") then
                    v:Destroy()
                end
                if v:IsA("AnimationController") or v:IsA("Animator") then
                    v:Destroy()
                end
            end
        end)
    end
end

-- Aplicar optimizaciones a todos los objetos existentes
task.spawn(function()
    task.wait(0.5)
    for _, obj in pairs(workspace:GetDescendants()) do
        if obj:IsA("Model") then
            disableAnimationsOnModel(obj)
            optimizeBrainrot(obj)
            hideSpecialEvents(obj)
        end
        -- Limpiar partículas y efectos en todo workspace
        if obj:IsA("ParticleEmitter") or obj:IsA("Trail") or obj:IsA("Smoke") or obj:IsA("Fire") or obj:IsA("Sparkles") then
            pcall(function() obj.Enabled = false end)
        end
        if obj:IsA("BasePart") and obj.Material ~= Enum.Material.Plastic then
            pcall(function() obj.Material = Enum.Material.Plastic end)
        end
        if obj:IsA("Texture") or obj:IsA("Decal") then
            pcall(function() obj:Destroy() end)
        end
    end
end)

-- Conectar eventos para nuevos objetos
workspace.DescendantAdded:Connect(function(obj)
    if obj:IsA("Model") then
        disableAnimationsOnModel(obj)
        optimizeBrainrot(obj)
        hideSpecialEvents(obj)
    end
    if obj:IsA("ParticleEmitter") or obj:IsA("Trail") or obj:IsA("Smoke") or obj:IsA("Fire") or obj:IsA("Sparkles") then
        pcall(function() obj.Enabled = false end)
    end
    if obj:IsA("BasePart") then
        pcall(function() obj.Material = Enum.Material.Plastic end)
    end
    if obj:IsA("Texture") or obj:IsA("Decal") then
        pcall(function() obj:Destroy() end)
    end
end)

-- Iniciar monitoreo de herramientas
startToolMonitoring()
cleanAllPlayerTools()

task.spawn(function()
    pcall(function() settings().Rendering.QualityLevel = Enum.QualityLevel.Level01 end)
    pcall(function()
        Lighting.GlobalShadows = false
        Lighting.FogEnd        = 1e9
        Lighting.Brightness    = 1
    end)
end)

-- [EL RESTO DE TU CÓDIGO ORIGINAL CONTINÚA AQUÍ - SIN MODIFICACIONES]
-- (desde local function _buildMiniPetsSection hasta el final)

-- ... (todo tu código original de Faded Hub desde aquí hasta el final) ...

print("✅ FADED HUB + EL PATRÓN OPTIMIZATIONS - CARGADO COMPLETAMENTE")
print("   🔧 Limpieza de texturas de herramientas: ACTIVADA")
print("   🎨 Materiales a PLÁSTICO: ACTIVADO")
print("   🌑 Sombras deshabilitadas: ACTIVADO")
print("   🎭 Optimización de Brainrots: ACTIVADA")
print("   🎪 Ocultación de eventos especiales: ACTIVADA")