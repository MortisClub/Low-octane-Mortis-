-- runtime.lua — оригинальный монолит Mortis HACK v10.1

local Players = game:GetService("Players")
local Workspace = game:GetService("Workspace")
local RunService = game:GetService("RunService")
local UserInputService = game:GetService("UserInputService")
local Lighting = game:GetService("Lighting")
local LocalPlayer = Players.LocalPlayer
local Camera = workspace.CurrentCamera
local Mouse = LocalPlayer:GetMouse()

-- ============================================
-- НАЙТИ СЕБЯ
-- ============================================

local MyModel = nil

local function findMyModel()
    local chars = Workspace:FindFirstChild("Characters")
    if not chars then return nil end
    local closest, closestDist = nil, math.huge
    for _, m in pairs(chars:GetChildren()) do
        local charC = m:FindFirstChild("Character_C")
        if charC then
            local human = charC:FindFirstChild("Human")
            if human then
                local head = human:FindFirstChild("Head")
                if head and head:IsA("BasePart") then
                    local d = (head.Position - Camera.CFrame.Position).Magnitude
                    if d < closestDist then closestDist = d closest = m end
                end
            end
        end
    end
    MyModel = closest
    return closest
end

local function getHumanoid()
    local char = LocalPlayer.Character
    if char then
        for _, d in pairs(char:GetDescendants()) do
            if d:IsA("Humanoid") then return d end
        end
    end
    if MyModel then
        for _, d in pairs(MyModel:GetDescendants()) do
            if d:IsA("Humanoid") then return d end
        end
    end
    return nil
end

local function getHRP()
    local char = LocalPlayer.Character
    if char then
        local hrp = char:FindFirstChild("HumanoidRootPart")
        if hrp then return hrp end
    end
    if MyModel then
        local charC = MyModel:FindFirstChild("Character_C")
        if charC then
            local human = charC:FindFirstChild("Human")
            if human then
                local head = human:FindFirstChild("Head")
                if head and head:IsA("BasePart") then return head end
            end
        end
    end
    return nil
end

-- ============================================
-- SETTINGS
-- ============================================

local Settings = {
    ESP_Enabled = true, ESP_Color = Color3.fromRGB(255, 50, 50), ESP_Transparency = 0.6,

    Aimbot_Enabled = false,
    Aimbot_Smoothing = 4,
    Aimbot_FOV = 120,
    Aimbot_DeadZone = 1,
    Aimbot_Prediction = 0.08,
    Aimbot_ResponseCurve = 1.2,
    Aimbot_MaxSpeed = 40,
    Aimbot_MinSpeed = 0.5,
    Aimbot_NearSlowdown = 15,
    Aimbot_StickyTarget = true,
    Aimbot_TargetPart = "Head",
    Aimbot_VisCheck = false,
    Aimbot_KeyMode = "RMB",
    Aimbot_AlwaysOn = false,

    MagicBullet_Enabled = false, MagicBullet_FOVCheck = true, MagicBullet_TargetPart = "Head",
    AntiRecoil_Enabled = false, AntiRecoil_Strength = 100,
    NoHandShake_Enabled = false, NoHandShake_Strength = 100,
    Fullbright_Enabled = false, AlwaysDay_Enabled = false, RemoveFog_Enabled = false, OriginalLightingSettings = nil,
    Fly_Enabled = false, Fly_Speed = 50, Noclip_Enabled = false,
    Speed_Enabled = false, Speed_Value = 50,
    JumpPower_Enabled = false, JumpPower_Value = 100,
    InfiniteJump_Enabled = false, Invisibility_Enabled = false, GodMode_Enabled = false,
    FreeCam_Enabled = false, FreeCam_Speed = 1,
    ClickTP_Enabled = false, Spin_Enabled = false, Spin_Speed = 10,
    BigHead_Enabled = false, HitboxSize = 10,
    FOVCircle = nil, OriginalTransparency = {}, Flying = false, FlyBV = nil, FlyBG = nil,
    WatchedModels = {}, OriginalHeadSizes = {},
    CurrentTarget = nil, AimbotActive = false,
}

-- ============================================
-- AIM KEY
-- ============================================

local function isAimKeyPressed()
    if Settings.Aimbot_AlwaysOn then return true end
    local m = Settings.Aimbot_KeyMode
    if m == "RMB" then return UserInputService:IsMouseButtonPressed(Enum.UserInputType.MouseButton2)
    elseif m == "LMB" then return UserInputService:IsMouseButtonPressed(Enum.UserInputType.MouseButton1)
    elseif m == "Shift" then return UserInputService:IsKeyDown(Enum.KeyCode.LeftShift)
    elseif m == "Alt" then return UserInputService:IsKeyDown(Enum.KeyCode.LeftAlt)
    elseif m == "Ctrl" then return UserInputService:IsKeyDown(Enum.KeyCode.LeftControl)
    elseif m == "Q" then return UserInputService:IsKeyDown(Enum.KeyCode.Q)
    elseif m == "X" then return UserInputService:IsKeyDown(Enum.KeyCode.X)
    elseif m == "C" then return UserInputService:IsKeyDown(Enum.KeyCode.C)
    elseif m == "CapsLock" then return UserInputService:IsKeyDown(Enum.KeyCode.CapsLock)
    elseif m == "Always On" then return true end
    return UserInputService:IsMouseButtonPressed(Enum.UserInputType.MouseButton2)
end

-- ============================================
-- ПОИСК ГОЛОВЫ
-- ============================================

local function findCorrectHead(model)
    local charC = model:FindFirstChild("Character_C")
    if charC then
        local human = charC:FindFirstChild("Human")
        if human then
            local head = human:FindFirstChild("Head")
            if head and head:IsA("BasePart") then return head end
        end
    end
    return nil
end

local function findBestTargetPart(model, pref)
    if not model then return nil end
    pref = pref or "Head"
    local correctHead = findCorrectHead(model)

    if pref == "Head" or pref == "Auto" then
        if correctHead then return correctHead end
    end

    if pref == "Torso" then
        local charC = model:FindFirstChild("Character_C")
        if charC then
            local human = charC:FindFirstChild("Human")
            if human then
                local ub = human:FindFirstChild("UpperBody")
                if ub then
                    for _, p in pairs(ub:GetChildren()) do
                        if p:IsA("BasePart") then return p end
                    end
                end
            end
        end
    end

    if correctHead then return correctHead end

    local highest, highY = nil, -math.huge
    for _, d in pairs(model:GetDescendants()) do
        if d:IsA("BasePart") and d.Size.Magnitude > 0.3 and d.Position.Y > highY then
            if d.Parent.Name ~= "RagdollCollision" and d.Parent.Name ~= "Accessories" then
                highY = d.Position.Y
                highest = d
            end
        end
    end
    return highest
end

local aliveCache = {}

local function isModelAlive(model)
    if not model or not model.Parent then return false end
    local cached = aliveCache[model]
    if cached and cached.Parent then return cached.Health > 0 end
    for _, d in pairs(model:GetDescendants()) do
        if d:IsA("Humanoid") then aliveCache[model] = d return d.Health > 0 end
    end
    for _, d in pairs(model:GetDescendants()) do
        if d:IsA("BasePart") then return true end
    end
    return false
end

-- ============================================
-- TEAM COLORS
-- ============================================

local teamCache = {}
local teamCacheTick = {}

local function getTeamType(model)
    if not model then return "neutral" end
    local now = tick()
    if teamCacheTick[model] and (now - teamCacheTick[model]) < 2 then
        return teamCache[model] or "neutral"
    end
    local result = "neutral"
    for _, d in pairs(model:GetDescendants()) do
        local n = d.Name:lower()
        if n == "headcloth" then result = "headcloth" break
        elseif n == "band" then result = "band" end
    end
    teamCache[model] = result
    teamCacheTick[model] = now
    return result
end

-- ============================================
-- LIGHTING
-- ============================================

local OriginalLighting = nil

local function saveOriginalLighting()
    OriginalLighting = {
        Ambient = Lighting.Ambient,
        Brightness = Lighting.Brightness,
        ClockTime = Lighting.ClockTime,
        FogEnd = Lighting.FogEnd,
        FogStart = Lighting.FogStart,
        OutdoorAmbient = Lighting.OutdoorAmbient,
        TimeOfDay = Lighting.TimeOfDay,
        ExposureCompensation = Lighting.ExposureCompensation,
    }
end
saveOriginalLighting()

local function forceFullbright()
    Lighting.Ambient = Color3.fromRGB(255, 255, 255)
    Lighting.Brightness = 2
    Lighting.OutdoorAmbient = Color3.fromRGB(255, 255, 255)
    Lighting.ExposureCompensation = 0.5
end

local function restoreFullbright()
    if not OriginalLighting then return end
    Lighting.Ambient = OriginalLighting.Ambient
    Lighting.Brightness = OriginalLighting.Brightness
    Lighting.OutdoorAmbient = OriginalLighting.OutdoorAmbient
    Lighting.ExposureCompensation = OriginalLighting.ExposureCompensation
end

local function forceDay()
    Lighting.ClockTime = 14
    Lighting.TimeOfDay = "14:00:00"
end

local function restoreDay()
    if not OriginalLighting then return end
    Lighting.ClockTime = OriginalLighting.ClockTime
    Lighting.TimeOfDay = OriginalLighting.TimeOfDay
end

local function forceFog()
    Lighting.FogEnd = 100000
    Lighting.FogStart = 100000
end

local function restoreFog()
    if not OriginalLighting then return end
    Lighting.FogEnd = OriginalLighting.FogEnd
    Lighting.FogStart = OriginalLighting.FogStart
end

local function applyFullbright()
    if Settings.Fullbright_Enabled then forceFullbright() else restoreFullbright() end
end

local function applyAlwaysDay()
    if Settings.AlwaysDay_Enabled then forceDay() else restoreDay() end
end

local function applyRemoveFog()
    if Settings.RemoveFog_Enabled then forceFog() else restoreFog() end
end

local function maintainLighting()
    if Settings.Fullbright_Enabled then forceFullbright() end
    if Settings.AlwaysDay_Enabled then forceDay() end
    if Settings.RemoveFog_Enabled then forceFog() end
end

-- ============================================
-- FLY
-- ============================================

local function cleanupFly()
    Settings.Flying = false
    if Settings.FlyBV then pcall(function() Settings.FlyBV:Destroy() end) Settings.FlyBV = nil end
    if Settings.FlyBG then pcall(function() Settings.FlyBG:Destroy() end) Settings.FlyBG = nil end
end

local function startFly()
    local hrp = getHRP() if not hrp then return end cleanupFly() Settings.Flying = true
    local bv = Instance.new("BodyVelocity") bv.MaxForce = Vector3.new(9e9,9e9,9e9) bv.Velocity = Vector3.zero bv.Parent = hrp Settings.FlyBV = bv
    local bg = Instance.new("BodyGyro") bg.MaxTorque = Vector3.new(9e9,9e9,9e9) bg.P = 9e4 bg.CFrame = hrp.CFrame bg.Parent = hrp Settings.FlyBG = bg
end

local function stopFly() cleanupFly() end

local function updateFly()
    if not Settings.Fly_Enabled or not Settings.Flying then return end
    local hrp = getHRP() if not hrp then return end
    if not Settings.FlyBV or not Settings.FlyBV.Parent then startFly() return end
    local dir, cf = Vector3.zero, Camera.CFrame
    if UserInputService:IsKeyDown(Enum.KeyCode.W) then dir = dir + cf.LookVector end
    if UserInputService:IsKeyDown(Enum.KeyCode.S) then dir = dir - cf.LookVector end
    if UserInputService:IsKeyDown(Enum.KeyCode.A) then dir = dir - cf.RightVector end
    if UserInputService:IsKeyDown(Enum.KeyCode.D) then dir = dir + cf.RightVector end
    if UserInputService:IsKeyDown(Enum.KeyCode.Space) then dir = dir + Vector3.new(0,1,0) end
    if UserInputService:IsKeyDown(Enum.KeyCode.LeftControl) or UserInputService:IsKeyDown(Enum.KeyCode.LeftShift) then dir = dir - Vector3.new(0,1,0) end
    Settings.FlyBV.Velocity = dir.Magnitude > 0 and dir.Unit * Settings.Fly_Speed or Vector3.zero
    Settings.FlyBG.CFrame = CFrame.new(hrp.Position, hrp.Position + cf.LookVector)
end

-- ============================================
-- MOVEMENT / PLAYER
-- ============================================

local function applyNoclip()
    if not Settings.Noclip_Enabled then return end
    if MyModel then for _,p in pairs(MyModel:GetDescendants()) do if p:IsA("BasePart") then p.CanCollide = false end end end
    local c = LocalPlayer.Character if c then for _,p in pairs(c:GetDescendants()) do if p:IsA("BasePart") then p.CanCollide = false end end end
end

local function applySpeed() if Settings.Speed_Enabled then local h = getHumanoid() if h then h.WalkSpeed = Settings.Speed_Value end end end
local function resetSpeed() local h = getHumanoid() if h then h.WalkSpeed = 16 end end
local function applyJumpPower() if Settings.JumpPower_Enabled then local h = getHumanoid() if h then h.JumpPower = Settings.JumpPower_Value h.JumpHeight = Settings.JumpPower_Value/2 end end end
local function resetJumpPower() local h = getHumanoid() if h then h.JumpPower = 50 h.JumpHeight = 7.2 end end
local function applySpin() if Settings.Spin_Enabled then local h = getHRP() if h then h.CFrame = h.CFrame * CFrame.Angles(0,math.rad(Settings.Spin_Speed),0) end end end
local function applyGodMode() if Settings.GodMode_Enabled then local h = getHumanoid() if h then h.Health = h.MaxHealth end end end
local function teleportToMouse() local h = getHRP() if h and Mouse.Hit then h.CFrame = CFrame.new(Mouse.Hit.Position + Vector3.new(0,3,0)) end end

local function teleportToPlayer(name)
    local h = getHRP() if not h then return nil end
    for _,p in pairs(Players:GetPlayers()) do
        if p ~= LocalPlayer and p.Name:lower():find(name:lower()) then
            local tc = p.Character if tc then
                local tp for _,d in pairs(tc:GetDescendants()) do if d:IsA("BasePart") and d.Name == "Head" then tp = d break end end
                if tp then h.CFrame = tp.CFrame * CFrame.new(0,0,3) return p.Name end
            end
        end
    end
    return nil
end

local function applyInvisibility()
    local target = MyModel or LocalPlayer.Character if not target then return end
    if Settings.Invisibility_Enabled then
        for _,p in pairs(target:GetDescendants()) do if (p:IsA("BasePart") or p:IsA("Decal") or p:IsA("Texture")) and not Settings.OriginalTransparency[p] then Settings.OriginalTransparency[p] = p.Transparency p.Transparency = 1 end end
    else for p,t in pairs(Settings.OriginalTransparency) do pcall(function() if p and p.Parent then p.Transparency = t end end) end Settings.OriginalTransparency = {} end
end

local lastBigHeadUpdate = 0
local function applyBigHead()
    local now = tick()
    if now - lastBigHeadUpdate < 0.5 then return end
    lastBigHeadUpdate = now
    local chars = Workspace:FindFirstChild("Characters") if not chars then return end
    for _,m in pairs(chars:GetChildren()) do
        if m ~= MyModel then
            local head = findCorrectHead(m)
            if head then
                if Settings.BigHead_Enabled then
                    if not Settings.OriginalHeadSizes[head] then Settings.OriginalHeadSizes[head] = head.Size end
                    head.Size = Vector3.new(Settings.HitboxSize,Settings.HitboxSize,Settings.HitboxSize) head.Transparency = 0.5 head.CanCollide = false
                else local o = Settings.OriginalHeadSizes[head] if o then head.Size = o Settings.OriginalHeadSizes[head] = nil end head.Transparency = 0 end
            end
        end
    end
end

local function startFreeCam() Camera.CameraType = Enum.CameraType.Scriptable end
local function stopFreeCam() Camera.CameraType = Enum.CameraType.Custom local h = getHumanoid() if h then Camera.CameraSubject = h end end

local function updateFreeCam()
    if not Settings.FreeCam_Enabled then return end
    local dir = Vector3.zero
    if UserInputService:IsKeyDown(Enum.KeyCode.W) then dir = dir + Camera.CFrame.LookVector end
    if UserInputService:IsKeyDown(Enum.KeyCode.S) then dir = dir - Camera.CFrame.LookVector end
    if UserInputService:IsKeyDown(Enum.KeyCode.A) then dir = dir - Camera.CFrame.RightVector end
    if UserInputService:IsKeyDown(Enum.KeyCode.D) then dir = dir + Camera.CFrame.RightVector end
    if UserInputService:IsKeyDown(Enum.KeyCode.Space) then dir = dir + Vector3.new(0,1,0) end
    if UserInputService:IsKeyDown(Enum.KeyCode.LeftControl) then dir = dir - Vector3.new(0,1,0) end
    if dir.Magnitude > 0 then Camera.CFrame = Camera.CFrame + dir.Unit * Settings.FreeCam_Speed end
end

pcall(function() local vu = game:GetService("VirtualUser") LocalPlayer.Idled:Connect(function() vu:CaptureController() vu:ClickButton2(Vector2.new()) end) end)

-- ============================================
-- NO HAND SHAKE
-- ============================================

local ShakeData = {baselineCFrame = nil}

local function applyNoHandShake()
    if not Settings.NoHandShake_Enabled then ShakeData.baselineCFrame = nil return end
    if Settings.AimbotActive then return end
    local str = Settings.NoHandShake_Strength / 100
    local md = Vector2.zero pcall(function() md = UserInputService:GetMouseDelta() end)
    if not ShakeData.baselineCFrame then ShakeData.baselineCFrame = Camera.CFrame return end
    if md.Magnitude > 0.5 then ShakeData.baselineCFrame = Camera.CFrame
    else
        local cY,cX,cZ = Camera.CFrame:ToEulerAnglesYXZ()
        local bY,bX,bZ = ShakeData.baselineCFrame:ToEulerAnglesYXZ()
        local total = math.abs(cY-bY)+math.abs(cX-bX)+math.abs(cZ-bZ)
        if total > 0.001 and total < 0.1 then
            Camera.CFrame = CFrame.new(Camera.CFrame.Position) * CFrame.fromEulerAnglesYXZ(bY+(cY-bY)*(1-str),bX+(cX-bX)*(1-str),bZ+(cZ-bZ)*(1-str))
        else ShakeData.baselineCFrame = Camera.CFrame end
    end
end

local function setupNoHandShakeHook()
    if not Settings.NoHandShake_Enabled then return end
    pcall(function()
        local target = MyModel or LocalPlayer.Character if not target then return end
        for _,d in pairs(target:GetDescendants()) do local n = d.Name:lower()
            if d:IsA("NumberValue") and (n:find("shake") or n:find("sway") or n:find("bob")) then d.Value = 0
            elseif d:IsA("Vector3Value") and (n:find("shake") or n:find("sway") or n:find("bob")) then d.Value = Vector3.zero end
        end
    end)
end

-- ============================================
-- ESP
-- ============================================

local function getOrCreateHighlight(model)
    local h = model:FindFirstChild("Chms") if h then return h end
    h = Instance.new("Highlight") h.Name = "Chms" h.FillTransparency = Settings.ESP_Transparency h.OutlineTransparency = 0
    h.DepthMode = Enum.HighlightDepthMode.AlwaysOnTop h.Enabled = true h.Parent = model
    return h
end

local function refreshHighlight(model)
    if not model or not model.Parent then return end
    if model == MyModel then local h = model:FindFirstChild("Chms") if h then h.Enabled = false end return end
    if not Settings.ESP_Enabled then local h = model:FindFirstChild("Chms") if h then h.Enabled = false end return end
    local h = getOrCreateHighlight(model)
    teamCacheTick[model] = 0
    local team = getTeamType(model)
    if team == "headcloth" then
        h.FillColor = Color3.fromRGB(255, 0, 0) h.OutlineColor = Color3.fromRGB(255, 0, 0)
    elseif team == "band" then
        h.FillColor = Color3.fromRGB(0, 255, 0) h.OutlineColor = Color3.fromRGB(0, 255, 0)
    else
        h.FillColor = Settings.ESP_Color h.OutlineColor = Settings.ESP_Color
    end
    h.FillTransparency = Settings.ESP_Transparency
    h.Enabled = true
end

local function watchModel(model)
    if not model then return end
    if Settings.WatchedModels[model] then refreshHighlight(model) return end
    Settings.WatchedModels[model] = true refreshHighlight(model)
    local c1 = model.DescendantAdded:Connect(function(d)
        local n = d.Name:lower()
        if n == "headcloth" or n == "band" then teamCacheTick[model] = 0 task.defer(function() task.wait(0.1) refreshHighlight(model) end) end
    end)
    local c2 = model.DescendantRemoving:Connect(function(d)
        local n = d.Name:lower()
        if n == "headcloth" or n == "band" then teamCacheTick[model] = 0 task.defer(function() task.wait(0.1) refreshHighlight(model) end) end
    end)
    local c3 c3 = model.AncestryChanged:Connect(function(_,p)
        if not p then Settings.WatchedModels[model]=nil teamCache[model]=nil teamCacheTick[model]=nil aliveCache[model]=nil
            pcall(function() c1:Disconnect() end) pcall(function() c2:Disconnect() end) pcall(function() c3:Disconnect() end) end
    end)
end

local function updateESP()
    local chars = Workspace:FindFirstChild("Characters") if not chars then return 0 end
    local count = 0
    for _,m in pairs(chars:GetChildren()) do if m ~= MyModel then watchModel(m) count = count + 1 end end
    return count
end

-- ============================================
-- AIMBOT
-- ============================================

local stickyTargetModel = nil

local function createFOVCircle()
    pcall(function()
        if Settings.FOVCircle then pcall(function() Settings.FOVCircle:Remove() end) end
        local c = Drawing.new("Circle") c.Thickness = 2 c.NumSides = 64 c.Radius = Settings.Aimbot_FOV
        c.Color = Color3.fromRGB(255,255,255) c.Transparency = 0.7 c.Visible = Settings.Aimbot_Enabled c.Filled = false Settings.FOVCircle = c
    end)
end

local function isInFOV(pos)
    local sp, onScreen = Camera:WorldToViewportPoint(pos) if not onScreen then return false, math.huge end
    local center = Vector2.new(Camera.ViewportSize.X/2, Camera.ViewportSize.Y/2)
    local dist = (Vector2.new(sp.X,sp.Y) - center).Magnitude
    return dist <= Settings.Aimbot_FOV, dist
end

local function getBestTarget()
    local bestPart, bestDist, bestModel = nil, math.huge, nil
    local chars = Workspace:FindFirstChild("Characters") if not chars then return nil end

    if Settings.Aimbot_StickyTarget and stickyTargetModel
       and stickyTargetModel.Parent and stickyTargetModel ~= MyModel
       and isModelAlive(stickyTargetModel) then
        local part = findBestTargetPart(stickyTargetModel, Settings.Aimbot_TargetPart)
        if part then
            local inFov = isInFOV(part.Position)
            if inFov then return part end
        end
    end

    for _,model in pairs(chars:GetChildren()) do
        if model ~= MyModel and isModelAlive(model) then
            local part = findBestTargetPart(model, Settings.Aimbot_TargetPart)
            if part then
                local inFov, dist = isInFOV(part.Position)
                if inFov and dist < bestDist then
                    bestDist = dist bestPart = part bestModel = model
                end
            end
        end
    end
    if bestModel then stickyTargetModel = bestModel end
    return bestPart
end

local function aimAt(targetPart)
    if not targetPart or not targetPart.Parent then return end
    local vel = Vector3.zero
    pcall(function() vel = targetPart.AssemblyLinearVelocity or Vector3.zero end)
    local predicted = targetPart.Position + vel * Settings.Aimbot_Prediction
    if predicted ~= predicted then predicted = targetPart.Position end

    local sp, onScreen = Camera:WorldToViewportPoint(predicted)
    if not onScreen then return end

    local center = Vector2.new(Camera.ViewportSize.X/2, Camera.ViewportSize.Y/2)
    local offX = sp.X - center.X
    local offY = sp.Y - center.Y
    local dist = math.sqrt(offX * offX + offY * offY)

    if dist < Settings.Aimbot_DeadZone then return end

    local dirX = offX / dist
    local dirY = offY / dist

    local baseFactor = math.clamp(1 / Settings.Aimbot_Smoothing, 0.05, 1.0)
    local normalizedDist = math.clamp(dist / Settings.Aimbot_FOV, 0.001, 1)
    local curvedFactor = math.pow(normalizedDist, Settings.Aimbot_ResponseCurve)

    local nearFactor = 1
    if dist < Settings.Aimbot_NearSlowdown then
        nearFactor = math.clamp(dist / Settings.Aimbot_NearSlowdown, 0.08, 1)
    end

    local speed = Settings.Aimbot_MaxSpeed * baseFactor * curvedFactor * nearFactor
    speed = math.clamp(speed, Settings.Aimbot_MinSpeed, Settings.Aimbot_MaxSpeed)
    speed = math.min(speed, dist * 0.9)

    if speed < Settings.Aimbot_MinSpeed and dist > Settings.Aimbot_DeadZone then
        speed = Settings.Aimbot_MinSpeed
    end

    mousemoverel(dirX * speed, dirY * speed)
end

-- ============================================
-- MAGIC BULLET / ANTI-RECOIL
-- ============================================

local function getMagicBulletTarget()
    if not Settings.MagicBullet_Enabled then return nil end
    local best, bestDist = nil, math.huge
    local chars = Workspace:FindFirstChild("Characters") if not chars then return nil end
    for _,m in pairs(chars:GetChildren()) do
        if m ~= MyModel and isModelAlive(m) then
            local p = findBestTargetPart(m, Settings.MagicBullet_TargetPart)
            if p then
                if Settings.MagicBullet_FOVCheck then
                    local inF,d = isInFOV(p.Position) if inF and d < bestDist then bestDist = d best = p end
                else
                    local myH = getHRP() if myH then local d = (p.Position-myH.Position).Magnitude if d < bestDist then bestDist = d best = p end end
                end
            end
        end
    end
    return best
end

local lastCamLook = nil
local function applyAntiRecoil()
    if not Settings.AntiRecoil_Enabled or Settings.AimbotActive then lastCamLook = Camera.CFrame.LookVector return end
    local shooting = UserInputService:IsMouseButtonPressed(Enum.UserInputType.MouseButton1)
    if not shooting then lastCamLook = Camera.CFrame.LookVector return end
    if not lastCamLook then lastCamLook = Camera.CFrame.LookVector return end
    local vertDiff = Camera.CFrame.LookVector.Y - lastCamLook.Y
    if vertDiff > 0.001 then mousemoverel(0, vertDiff * (Settings.AntiRecoil_Strength/100) * 50) end
    lastCamLook = Camera.CFrame.LookVector
end

-- ============================================
-- GUI — FLUENT UI LIBRARY
-- ============================================

local Fluent = loadstring(game:HttpGet("https://github.com/dawid-scripts/Fluent/releases/latest/download/main.lua"))()
local SaveManager = loadstring(game:HttpGet("https://raw.githubusercontent.com/dawid-scripts/Fluent/master/Addons/SaveManager.lua"))()
local InterfaceManager = loadstring(game:HttpGet("https://raw.githubusercontent.com/dawid-scripts/Fluent/master/Addons/InterfaceManager.lua"))()

local Window = Fluent:CreateWindow({
    Title = "Mortis HACK v10.1",
    SubTitle = "by Mortis",
    TabWidth = 160,
    Size = UDim2.fromOffset(620, 500),
    Acrylic = true,
    Theme = "Amethyst",
    MinimizeKey = Enum.KeyCode.RightControl
})

-- ===================== ESP TAB =====================
local ESPTab = Window:AddTab({ Title = "ESP", Icon = "eye" })

ESPTab:AddParagraph({ Title = "👁️ ESP Settings", Content = "Подсветка игроков сквозь стены" })

ESPTab:AddToggle("ESPEnabled", {
    Title = "Включить ESP",
    Description = "Подсветка всех игроков",
    Default = Settings.ESP_Enabled,
    Callback = function(v) Settings.ESP_Enabled = v; updateESP() end
})

ESPTab:AddColorpicker("ESPColor", {
    Title = "Нейтральный цвет",
    Default = Settings.ESP_Color,
    Callback = function(v) Settings.ESP_Color = v; updateESP() end
})

ESPTab:AddSlider("ESPTransparency", {
    Title = "Прозрачность заливки",
    Description = "0 = непрозрачный, 1 = полностью прозрачный",
    Min = 0,
    Max = 1,
    Default = Settings.ESP_Transparency,
    Rounding = 1,
    Callback = function(v) Settings.ESP_Transparency = v; updateESP() end
})

ESPTab:AddButton({
    Title = "🔄 Пересканировать",
    Description = "Обновить список игроков",
    Callback = function()
        Settings.WatchedModels = {}
        teamCache = {}
        teamCacheTick = {}
        aliveCache = {}
        findMyModel()
        local c = updateESP()
        Fluent:Notify({ Title = "ESP", Content = c .. " игроков найдено", Duration = 3 })
    end
})

ESPTab:AddParagraph({ Title = "🎨 Цветовая схема", Content = "🔴 Красный = Headcloth\n🟢 Зелёный = Band\n⚪ Нейтральный = Свой цвет" })

-- ===================== AIMBOT TAB =====================
local AimbotTab = Window:AddTab({ Title = "Aimbot", Icon = "crosshair" })

AimbotTab:AddParagraph({ Title = "⚡ Активация", Content = "Основные настройки наведения" })

AimbotTab:AddToggle("AimbotEnabled", {
    Title = "Включить аимбот",
    Description = "Автоматическое наведение на цель",
    Default = Settings.Aimbot_Enabled,
    Callback = function(v)
        Settings.Aimbot_Enabled = v
        pcall(function() if Settings.FOVCircle then Settings.FOVCircle.Visible = v end end)
    end
})

AimbotTab:AddDropdown("AimKey", {
    Title = "Кнопка наведения",
    Description = "Выберите кнопку активации",
    Values = {"RMB", "LMB", "Shift", "Alt", "Ctrl", "Q", "X", "C", "CapsLock", "Always On"},
    Default = "RMB",
    Callback = function(v)
        Settings.Aimbot_KeyMode = v
        Settings.Aimbot_AlwaysOn = (v == "Always On")
    end
})

AimbotTab:AddDropdown("AimTarget", {
    Title = "Цель",
    Description = "Часть тела для наведения",
    Values = {"Head", "Auto", "Torso"},
    Default = "Head",
    Callback = function(v) Settings.Aimbot_TargetPart = v end
})

AimbotTab:AddToggle("VisCheck", {
    Title = "Проверка видимости",
    Default = Settings.Aimbot_VisCheck,
    Callback = function(v) Settings.Aimbot_VisCheck = v end
})

AimbotTab:AddToggle("StickyTarget", {
    Title = "Sticky Target",
    Description = "Держать цель пока она в FOV",
    Default = Settings.Aimbot_StickyTarget,
    Callback = function(v) Settings.Aimbot_StickyTarget = v end
})

AimbotTab:AddParagraph({ Title = "🎯 Основные параметры", Content = "Настройки точности и скорости" })

AimbotTab:AddSlider("Smoothing", {
    Title = "Плавность",
    Description = "1 = мгновенно, 15 = очень плавно",
    Min = 1,
    Max = 15,
    Default = Settings.Aimbot_Smoothing,
    Rounding = 1,
    Callback = function(v) Settings.Aimbot_Smoothing = v end
})

AimbotTab:AddSlider("AimbotFOV", {
    Title = "FOV (радиус захвата)",
    Description = "Радиус зоны захвата в пикселях",
    Min = 30,
    Max = 500,
    Default = Settings.Aimbot_FOV,
    Rounding = 0,
    Callback = function(v)
        Settings.Aimbot_FOV = v
        pcall(function() if Settings.FOVCircle then Settings.FOVCircle.Radius = v end end)
    end
})

AimbotTab:AddSlider("DeadZone", {
    Title = "Мёртвая зона",
    Description = "Минимальное расстояние для активации",
    Min = 0.5,
    Max = 15,
    Default = Settings.Aimbot_DeadZone,
    Rounding = 1,
    Callback = function(v) Settings.Aimbot_DeadZone = v end
})

AimbotTab:AddSlider("Prediction", {
    Title = "Предсказание движения (%)",
    Description = "Компенсация лага и движения цели",
    Min = 0,
    Max = 50,
    Default = Settings.Aimbot_Prediction * 100,
    Rounding = 0,
    Callback = function(v) Settings.Aimbot_Prediction = v / 100 end
})

AimbotTab:AddParagraph({ Title = "🔧 Тонкая настройка", Content = "Продвинутые параметры для точной калибровки" })

AimbotTab:AddSlider("ResponseCurve", {
    Title = "Кривая отклика",
    Description = "<1 = агрессивно, >1 = плавно",
    Min = 0.3,
    Max = 3,
    Default = Settings.Aimbot_ResponseCurve,
    Rounding = 1,
    Callback = function(v) Settings.Aimbot_ResponseCurve = v end
})

AimbotTab:AddSlider("MaxSpeed", {
    Title = "Макс. скорость (px/кадр)",
    Min = 5,
    Max = 100,
    Default = Settings.Aimbot_MaxSpeed,
    Rounding = 0,
    Callback = function(v) Settings.Aimbot_MaxSpeed = v end
})

AimbotTab:AddSlider("MinSpeed", {
    Title = "Мин. скорость (гарантия доводки)",
    Min = 0.1,
    Max = 3,
    Default = Settings.Aimbot_MinSpeed,
    Rounding = 1,
    Callback = function(v) Settings.Aimbot_MinSpeed = v end
})

AimbotTab:AddSlider("NearSlowdown", {
    Title = "Зона торможения",
    Description = "Замедление при приближении к цели",
    Min = 5,
    Max = 80,
    Default = Settings.Aimbot_NearSlowdown,
    Rounding = 0,
    Callback = function(v) Settings.Aimbot_NearSlowdown = v end
})

AimbotTab:AddParagraph({ Title = "📋 Пресеты", Content = "Быстрое переключение настроек" })

AimbotTab:AddButton({
    Title = "🎯 Идеальный",
    Description = "Сбалансированные настройки",
    Callback = function()
        Settings.Aimbot_Smoothing=4 Settings.Aimbot_FOV=120 Settings.Aimbot_DeadZone=1 Settings.Aimbot_Prediction=0.08
        Settings.Aimbot_ResponseCurve=1.2 Settings.Aimbot_MaxSpeed=40 Settings.Aimbot_MinSpeed=0.5 Settings.Aimbot_NearSlowdown=15
        Settings.Aimbot_StickyTarget=true
        pcall(function() if Settings.FOVCircle then Settings.FOVCircle.Radius=120 end end)
        Fluent:Notify({Title="Пресет",Content="Идеальные настройки применены",Duration=3})
    end
})

AimbotTab:AddButton({
    Title = "⚡ Агрессивный",
    Description = "Быстрый захват, меньше плавности",
    Callback = function()
        Settings.Aimbot_Smoothing=2 Settings.Aimbot_FOV=150 Settings.Aimbot_DeadZone=0.5 Settings.Aimbot_Prediction=0.05
        Settings.Aimbot_ResponseCurve=0.7 Settings.Aimbot_MaxSpeed=70 Settings.Aimbot_MinSpeed=1 Settings.Aimbot_NearSlowdown=8
        Settings.Aimbot_StickyTarget=true
        pcall(function() if Settings.FOVCircle then Settings.FOVCircle.Radius=150 end end)
        Fluent:Notify({Title="Пресет",Content="Агрессивные настройки применены",Duration=3})
    end
})

AimbotTab:AddButton({
    Title = "🫥 Легит",
    Description = "Незаметные плавные движения",
    Callback = function()
        Settings.Aimbot_Smoothing=8 Settings.Aimbot_FOV=80 Settings.Aimbot_DeadZone=2 Settings.Aimbot_Prediction=0.1
        Settings.Aimbot_ResponseCurve=1.8 Settings.Aimbot_MaxSpeed=25 Settings.Aimbot_MinSpeed=0.3 Settings.Aimbot_NearSlowdown=30
        Settings.Aimbot_StickyTarget=true
        pcall(function() if Settings.FOVCircle then Settings.FOVCircle.Radius=80 end end)
        Fluent:Notify({Title="Пресет",Content="Легит настройки применены",Duration=3})
    end
})

AimbotTab:AddButton({
    Title = "🔒 Лок-он",
    Description = "Мгновенная фиксация на цели",
    Callback = function()
        Settings.Aimbot_Smoothing=1 Settings.Aimbot_FOV=200 Settings.Aimbot_DeadZone=0.5 Settings.Aimbot_Prediction=0.12
        Settings.Aimbot_ResponseCurve=0.5 Settings.Aimbot_MaxSpeed=100 Settings.Aimbot_MinSpeed=2 Settings.Aimbot_NearSlowdown=5
        Settings.Aimbot_StickyTarget=true
        pcall(function() if Settings.FOVCircle then Settings.FOVCircle.Radius=200 end end)
        Fluent:Notify({Title="Пресет",Content="Лок-он настройки применены",Duration=3})
    end
})

AimbotTab:AddParagraph({ Title = "🧪 Тестирование", Content = "" })

AimbotTab:AddButton({
    Title = "🧪 Тест аима (3 сек)",
    Description = "Проверить наведение на ближайшую цель",
    Callback = function()
        findMyModel()
        local part = getBestTarget()
        if part then
            Fluent:Notify({Title="Тест",Content="Наведение на "..part.Name.." ("..part.Parent.Name..")",Duration=2})
            local st = tick()
            local cn
            cn = RunService.RenderStepped:Connect(function()
                if tick()-st > 3 then cn:Disconnect() return end
                if part and part.Parent then aimAt(part) end
            end)
        else
            Fluent:Notify({Title="Тест",Content="Цель не найдена в FOV!",Duration=2})
        end
    end
})

-- ============================================
-- HOOKS (FIXED FOR NEW XENO)
-- ============================================

local _hookInstalled = false
local _oldNamecall = nil

local function installMagicBulletHook()
    if _hookInstalled then return end
    _hookInstalled = true

    pcall(function()
        _oldNamecall = hookmetamethod(game, "__namecall", function(self, ...)
            -- Если Magic Bullet выключен — ничего не трогаем
            if not Settings.MagicBullet_Enabled then
                return _oldNamecall(self, ...)
            end

            local method = getnamecallmethod()

            -- Только FireServer / InvokeServer
            if method ~= "FireServer" and method ~= "InvokeServer" then
                return _oldNamecall(self, ...)
            end

            local ok, remoteName = pcall(function() return self.Name:lower() end)
            if not ok or not remoteName then
                return _oldNamecall(self, ...)
            end

            -- Только ремоуты, связанные со стрельбой
            local isShootRemote = remoteName:find("shoot")
                or remoteName:find("fire")
                or remoteName:find("gun")
                or remoteName:find("damage")
                or remoteName:find("hit")
                or remoteName:find("bullet")

            if not isShootRemote then
                return _oldNamecall(self, ...)
            end

            -- Только здесь трогаем аргументы
            local args = {...}
            local target = getMagicBulletTarget()
            if target then
                for i = 1, #args do
                    if typeof(args[i]) == "Vector3" then
                        args[i] = target.Position
                    elseif typeof(args[i]) == "CFrame" then
                        args[i] = CFrame.new(target.Position)
                    end
                end
                return _oldNamecall(self, unpack(args))
            end

            return _oldNamecall(self, ...)
        end)
    end)
end

-- ===================== COMBAT TAB =====================
local CombatTab = Window:AddTab({ Title = "Combat", Icon = "swords" })

CombatTab:AddParagraph({ Title = "🔫 Magic Bullet", Content = "Автоматическое попадание пуль" })

CombatTab:AddToggle("MagicBullet", {
    Title = "Magic Bullet",
    Description = "Перенаправляет пули в цель",
    Default = false,
    Callback = function(v)
        Settings.MagicBullet_Enabled = v
        if v and not _hookInstalled then
            installMagicBulletHook()
        end
    end
})

CombatTab:AddToggle("MBFOVCheck", {
    Title = "FOV Check (Magic Bullet)",
    Default = Settings.MagicBullet_FOVCheck,
    Callback = function(v) Settings.MagicBullet_FOVCheck = v end
})

CombatTab:AddParagraph({ Title = "📉 Anti-Recoil", Content = "Компенсация отдачи оружия" })

CombatTab:AddToggle("AntiRecoil", {
    Title = "Anti-Recoil",
    Description = "Автоматическая компенсация отдачи",
    Default = Settings.AntiRecoil_Enabled,
    Callback = function(v) Settings.AntiRecoil_Enabled = v end
})

CombatTab:AddSlider("AntiRecoilStr", {
    Title = "Сила компенсации",
    Min = 0,
    Max = 100,
    Default = Settings.AntiRecoil_Strength,
    Rounding = 0,
    Callback = function(v) Settings.AntiRecoil_Strength = v end
})

CombatTab:AddParagraph({ Title = "🤚 No Hand Shake", Content = "Убрать тряску рук / оружия" })

CombatTab:AddToggle("NoShake", {
    Title = "No Hand Shake",
    Description = "Стабилизация камеры",
    Default = Settings.NoHandShake_Enabled,
    Callback = function(v)
        Settings.NoHandShake_Enabled = v
        if v then ShakeData.baselineCFrame = Camera.CFrame; setupNoHandShakeHook() end
    end
})

CombatTab:AddSlider("NoShakeStr", {
    Title = "Сила стабилизации",
    Min = 0,
    Max = 100,
    Default = Settings.NoHandShake_Strength,
    Rounding = 0,
    Callback = function(v) Settings.NoHandShake_Strength = v end
})

CombatTab:AddParagraph({ Title = "💀 Hitbox Expander", Content = "Увеличение хитбоксов врагов" })

CombatTab:AddToggle("BigHead", {
    Title = "Big Head",
    Description = "Увеличить головы врагов",
    Default = Settings.BigHead_Enabled,
    Callback = function(v) Settings.BigHead_Enabled = v; lastBigHeadUpdate = 0; applyBigHead() end
})

CombatTab:AddSlider("HitboxSizeSlider", {
    Title = "Размер хитбокса",
    Min = 1,
    Max = 30,
    Default = Settings.HitboxSize,
    Rounding = 0,
    Callback = function(v)
        Settings.HitboxSize = v
        if Settings.BigHead_Enabled then lastBigHeadUpdate = 0; applyBigHead() end
    end
})

-- ===================== MOVEMENT TAB =====================
local MoveTab = Window:AddTab({ Title = "Movement", Icon = "move" })

MoveTab:AddParagraph({ Title = "✈️ Полёт", Content = "Свободный полёт по карте" })

MoveTab:AddToggle("FlyEnabled", {
    Title = "Fly",
    Description = "WASD + Space/Ctrl для полёта",
    Default = Settings.Fly_Enabled,
    Callback = function(v)
        Settings.Fly_Enabled = v
        if v then startFly() else stopFly() end
    end
})

MoveTab:AddSlider("FlySpeed", {
    Title = "Скорость полёта",
    Min = 10,
    Max = 300,
    Default = Settings.Fly_Speed,
    Rounding = 0,
    Callback = function(v) Settings.Fly_Speed = v end
})

MoveTab:AddParagraph({ Title = "🏃 Движение", Content = "Настройки скорости и прыжков" })

MoveTab:AddToggle("NoclipEnabled", {
    Title = "Noclip",
    Description = "Проходить сквозь стены",
    Default = Settings.Noclip_Enabled,
    Callback = function(v) Settings.Noclip_Enabled = v end
})

MoveTab:AddToggle("SpeedEnabled", {
    Title = "Speed Hack",
    Default = Settings.Speed_Enabled,
    Callback = function(v) Settings.Speed_Enabled = v; if not v then resetSpeed() end end
})

MoveTab:AddSlider("SpeedValue", {
    Title = "Скорость",
    Min = 16,
    Max = 300,
    Default = Settings.Speed_Value,
    Rounding = 0,
    Callback = function(v) Settings.Speed_Value = v end
})

MoveTab:AddToggle("JumpEnabled", {
    Title = "Jump Power",
    Default = Settings.JumpPower_Enabled,
    Callback = function(v) Settings.JumpPower_Enabled = v; if not v then resetJumpPower() end end
})

MoveTab:AddSlider("JumpValue", {
    Title = "Сила прыжка",
    Min = 50,
    Max = 500,
    Default = Settings.JumpPower_Value,
    Rounding = 0,
    Callback = function(v) Settings.JumpPower_Value = v end
})

MoveTab:AddToggle("InfJump", {
    Title = "Бесконечный прыжок",
    Description = "Прыгать в воздухе",
    Default = Settings.InfiniteJump_Enabled,
    Callback = function(v) Settings.InfiniteJump_Enabled = v end
})

MoveTab:AddToggle("SpinEnabled", {
    Title = "Spin",
    Description = "Вращение персонажа",
    Default = Settings.Spin_Enabled,
    Callback = function(v) Settings.Spin_Enabled = v end
})

MoveTab:AddSlider("SpinSpeed", {
    Title = "Скорость вращения",
    Min = 1,
    Max = 50,
    Default = Settings.Spin_Speed,
    Rounding = 0,
    Callback = function(v) Settings.Spin_Speed = v end
})

-- ===================== PLAYER TAB =====================
local PlayerTab = Window:AddTab({ Title = "Player", Icon = "user" })

PlayerTab:AddParagraph({ Title = "👤 Персонаж", Content = "Настройки персонажа" })

PlayerTab:AddToggle("InvisEnabled", {
    Title = "Невидимость",
    Description = "Стать невидимым для других",
    Default = Settings.Invisibility_Enabled,
    Callback = function(v) Settings.Invisibility_Enabled = v; applyInvisibility() end
})

PlayerTab:AddToggle("GodEnabled", {
    Title = "God Mode",
    Description = "Бесконечное здоровье",
    Default = Settings.GodMode_Enabled,
    Callback = function(v) Settings.GodMode_Enabled = v end
})

PlayerTab:AddParagraph({ Title = "📍 Телепортация", Content = "Перемещение по карте" })

PlayerTab:AddToggle("ClickTPEnabled", {
    Title = "Click TP (клавиша E)",
    Description = "Телепорт по клику мыши",
    Default = Settings.ClickTP_Enabled,
    Callback = function(v) Settings.ClickTP_Enabled = v end
})

PlayerTab:AddButton({
    Title = "📍 Телепорт к курсору",
    Description = "Переместиться к позиции мыши",
    Callback = function() teleportToMouse() end
})

local tpInput = ""
PlayerTab:AddInput("TPInput", {
    Title = "Имя игрока",
    Default = "",
    Placeholder = "Введите имя...",
    Callback = function(v) tpInput = v end
})

PlayerTab:AddButton({
    Title = "🚀 Телепорт к игроку",
    Description = "Переместиться к указанному игроку",
    Callback = function()
        local r = teleportToPlayer(tpInput)
        Fluent:Notify({Title = "Телепорт", Content = r or "Игрок не найден", Duration = 2})
    end
})

PlayerTab:AddParagraph({ Title = "📷 Камера", Content = "Свободная камера" })

PlayerTab:AddToggle("FreeCamEnabled", {
    Title = "FreeCam",
    Description = "Свободное управление камерой",
    Default = Settings.FreeCam_Enabled,
    Callback = function(v)
        Settings.FreeCam_Enabled = v
        if v then startFreeCam() else stopFreeCam() end
    end
})

PlayerTab:AddSlider("FreeCamSpeed", {
    Title = "Скорость камеры",
    Min = 0.5,
    Max = 10,
    Default = Settings.FreeCam_Speed,
    Rounding = 1,
    Callback = function(v) Settings.FreeCam_Speed = v end
})

-- ===================== VISUALS TAB =====================
local VisTab = Window:AddTab({ Title = "Visuals", Icon = "sun" })

VisTab:AddParagraph({ Title = "💡 Освещение", Content = "Настройки видимости на карте" })

VisTab:AddToggle("Fullbright", {
    Title = "Fullbright",
    Description = "Максимальная яркость",
    Default = Settings.Fullbright_Enabled,
    Callback = function(v) Settings.Fullbright_Enabled = v; applyFullbright() end
})

VisTab:AddToggle("AlwaysDay", {
    Title = "Всегда день",
    Description = "Фиксированное дневное время",
    Default = Settings.AlwaysDay_Enabled,
    Callback = function(v) Settings.AlwaysDay_Enabled = v; applyAlwaysDay() end
})

VisTab:AddToggle("NoFog", {
    Title = "Убрать туман",
    Description = "Максимальная дальность видимости",
    Default = Settings.RemoveFog_Enabled,
    Callback = function(v) Settings.RemoveFog_Enabled = v; applyRemoveFog() end
})

-- ===================== SETTINGS TAB =====================
local SettingsTab = Window:AddTab({ Title = "Settings", Icon = "settings" })

SaveManager:SetLibrary(Fluent)
InterfaceManager:SetLibrary(Fluent)
SaveManager:IgnoreThemeSettings()
SaveManager:SetFolder("MortisHack")
InterfaceManager:SetFolder("MortisHack")
InterfaceManager:BuildInterfaceSection(SettingsTab)
SaveManager:BuildConfigSection(SettingsTab)

-- ============================================
-- HOOKS (Magic Bullet устанавливается выше через installMagicBulletHook)
-- ============================================

-- ============================================
-- INPUT
-- ============================================

UserInputService.JumpRequest:Connect(function()
    if Settings.InfiniteJump_Enabled then
        local h = getHumanoid()
        if h then h:ChangeState(Enum.HumanoidStateType.Jumping) end
    end
end)

UserInputService.InputBegan:Connect(function(input, gpe)
    if gpe then return end
    if input.KeyCode == Enum.KeyCode.E and Settings.ClickTP_Enabled then teleportToMouse() end
end)

-- ============================================
-- MAIN LOOP
-- ============================================

RunService.Stepped:Connect(function()
    if Settings.Noclip_Enabled then applyNoclip() end
end)

local lastMyModelUpdate = 0
local lastSpeedUpdate = 0

RunService.RenderStepped:Connect(function()
    local now = tick()

    if now - lastMyModelUpdate > 2 then lastMyModelUpdate = now findMyModel() end

    maintainLighting()

    if Settings.Fly_Enabled then updateFly() end
    if Settings.FreeCam_Enabled then updateFreeCam() end
    if Settings.Spin_Enabled then applySpin() end

    if now - lastSpeedUpdate > 0.2 then
        lastSpeedUpdate = now
        if Settings.Speed_Enabled then applySpeed() end
        if Settings.JumpPower_Enabled then applyJumpPower() end
        if Settings.GodMode_Enabled then applyGodMode() end
    end

    pcall(function()
        if Settings.FOVCircle then
            local s = Camera.ViewportSize
            Settings.FOVCircle.Position = Vector2.new(s.X/2, s.Y/2)
            Settings.FOVCircle.Visible = Settings.Aimbot_Enabled or Settings.MagicBullet_Enabled
        end
    end)

    Settings.AimbotActive = Settings.Aimbot_Enabled and isAimKeyPressed()

    if Settings.AimbotActive then
        local part = getBestTarget()
        if part then aimAt(part) Settings.CurrentTarget = part
        else Settings.CurrentTarget = nil end
    else
        Settings.CurrentTarget = nil
        stickyTargetModel = nil
    end

    if not Settings.AimbotActive then applyAntiRecoil() end
    if not Settings.AimbotActive then applyNoHandShake() end
end)

local lastSH = 0
RunService.Heartbeat:Connect(function()
    if Settings.BigHead_Enabled then applyBigHead() end
    if Settings.NoHandShake_Enabled and tick()-lastSH >= 5 then lastSH = tick() task.defer(setupNoHandShakeHook) end
end)

-- ============================================
-- LIGHTING PROPERTY GUARDS
-- ============================================

Lighting:GetPropertyChangedSignal("Ambient"):Connect(function()
    if Settings.Fullbright_Enabled then Lighting.Ambient = Color3.fromRGB(255,255,255) end
end)
Lighting:GetPropertyChangedSignal("OutdoorAmbient"):Connect(function()
    if Settings.Fullbright_Enabled then Lighting.OutdoorAmbient = Color3.fromRGB(255,255,255) end
end)
Lighting:GetPropertyChangedSignal("Brightness"):Connect(function()
    if Settings.Fullbright_Enabled then Lighting.Brightness = 2 end
end)
Lighting:GetPropertyChangedSignal("ExposureCompensation"):Connect(function()
    if Settings.Fullbright_Enabled then Lighting.ExposureCompensation = 0.5 end
end)
Lighting:GetPropertyChangedSignal("ClockTime"):Connect(function()
    if Settings.AlwaysDay_Enabled then Lighting.ClockTime = 14 end
end)
Lighting:GetPropertyChangedSignal("TimeOfDay"):Connect(function()
    if Settings.AlwaysDay_Enabled then Lighting.TimeOfDay = "14:00:00" end
end)
Lighting:GetPropertyChangedSignal("FogEnd"):Connect(function()
    if Settings.RemoveFog_Enabled then Lighting.FogEnd = 100000 end
end)
Lighting:GetPropertyChangedSignal("FogStart"):Connect(function()
    if Settings.RemoveFog_Enabled then Lighting.FogStart = 100000 end
end)

-- ============================================
-- INIT
-- ============================================

task.defer(function()
    local chars = Workspace:WaitForChild("Characters", 30)
    if not chars then warn("[Mortis] No Characters!") return end

    chars.ChildAdded:Connect(function(m)
        task.defer(function()
            task.wait(0.2)
            findMyModel()
            watchModel(m)
        end)
    end)

    chars.ChildRemoved:Connect(function(m)
        Settings.WatchedModels[m] = nil
        teamCache[m] = nil
        teamCacheTick[m] = nil
        aliveCache[m] = nil
        if m == MyModel then findMyModel() end
        if m == stickyTargetModel then stickyTargetModel = nil end
    end)

    createFOVCircle()
    task.wait(1)
    findMyModel()
    local count = updateESP()

    Fluent:Notify({
        Title = "Mortis HACK v10.1",
        Content = "✅ Загружено! " .. count .. " игроков\n🔴 Red = Headcloth | 🟢 Green = Band",
        Duration = 7
    })

    print("[Mortis v10.1] " .. count .. " players | MyModel: " .. (MyModel and MyModel.Name or "nil"))
end)

