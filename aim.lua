-- aim.lua — аимбот, FOV‑круг, Magic Bullet, Anti-Recoil, No Hand Shake

-- Работает с глобальным Mortis, созданным в core.lua
local Mortis = getgenv().Mortis or {}
getgenv().Mortis = Mortis

local Workspace = Mortis.Workspace
local Camera = Mortis.Camera
local Settings = Mortis.Settings
local UserInputService = Mortis.UserInputService

local M = {}

local stickyTargetModel = nil
local ShakeData = { baselineCFrame = nil }
local lastCamLook = nil

-- ============================================
-- НАЖАТИЕ КЛАВИШИ АИМА
-- ============================================

function M.isAimKeyPressed()
    if Settings.Aimbot_AlwaysOn then return true end
    local m = Settings.Aimbot_KeyMode
    if m == "RMB" then
        return UserInputService:IsMouseButtonPressed(Enum.UserInputType.MouseButton2)
    elseif m == "LMB" then
        return UserInputService:IsMouseButtonPressed(Enum.UserInputType.MouseButton1)
    elseif m == "Shift" then
        return UserInputService:IsKeyDown(Enum.KeyCode.LeftShift)
    elseif m == "Alt" then
        return UserInputService:IsKeyDown(Enum.KeyCode.LeftAlt)
    elseif m == "Ctrl" then
        return UserInputService:IsKeyDown(Enum.KeyCode.LeftControl)
    elseif m == "Q" then
        return UserInputService:IsKeyDown(Enum.KeyCode.Q)
    elseif m == "X" then
        return UserInputService:IsKeyDown(Enum.KeyCode.X)
    elseif m == "C" then
        return UserInputService:IsKeyDown(Enum.KeyCode.C)
    elseif m == "CapsLock" then
        return UserInputService:IsKeyDown(Enum.KeyCode.CapsLock)
    elseif m == "Always On" then
        return true
    end
    return UserInputService:IsMouseButtonPressed(Enum.UserInputType.MouseButton2)
end

-- ============================================
-- FOV‑КРУГ
-- ============================================

function M.createFOVCircle()
    pcall(function()
        if Settings.FOVCircle then
            pcall(function() Settings.FOVCircle:Remove() end)
        end
        local c = Drawing.new("Circle")
        c.Thickness = 2
        c.NumSides = 64
        c.Radius = Settings.Aimbot_FOV
        c.Color = Color3.fromRGB(255,255,255)
        c.Transparency = 0.7
        c.Visible = Settings.Aimbot_Enabled
        c.Filled = false
        Settings.FOVCircle = c
    end)
end

local function isInFOV(pos)
    local sp, onScreen = Camera:WorldToViewportPoint(pos)
    if not onScreen then return false, math.huge end
    local center = Vector2.new(Camera.ViewportSize.X/2, Camera.ViewportSize.Y/2)
    local dist = (Vector2.new(sp.X,sp.Y) - center).Magnitude
    return dist <= Settings.Aimbot_FOV, dist
end

-- ============================================
-- ВЫБОР ЛУЧШЕЙ ЦЕЛИ
-- ============================================

function M.getBestTarget()
    local bestPart, bestDist, bestModel = nil, math.huge, nil
    local chars = Workspace:FindFirstChild("Characters")
    if not chars then return nil end

    if Settings.Aimbot_StickyTarget and stickyTargetModel
       and stickyTargetModel.Parent and stickyTargetModel ~= Mortis.getMyModel()
       and Mortis.isModelAlive(stickyTargetModel) then
        local part = Mortis.findBestTargetPart(stickyTargetModel, Settings.Aimbot_TargetPart)
        if part then
            local inFov = isInFOV(part.Position)
            if inFov then
                return part
            end
        end
    end

    for _, model in pairs(chars:GetChildren()) do
        if model ~= Mortis.getMyModel() and Mortis.isModelAlive(model) then
            local part = Mortis.findBestTargetPart(model, Settings.Aimbot_TargetPart)
            if part then
                local inFov, dist = isInFOV(part.Position)
                if inFov and dist < bestDist then
                    bestDist = dist
                    bestPart = part
                    bestModel = model
                end
            end
        end
    end

    if bestModel then
        stickyTargetModel = bestModel
    end
    return bestPart
end

-- ============================================
-- НАВЕДЕНИЕ
-- ============================================

function M.aimAt(targetPart)
    if not targetPart or not targetPart.Parent then return end

    local vel = Vector3.zero
    pcall(function()
        vel = targetPart.AssemblyLinearVelocity or Vector3.zero
    end)

    local predicted = targetPart.Position + vel * Settings.Aimbot_Prediction
    if predicted ~= predicted then
        predicted = targetPart.Position
    end

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
-- MAGIC BULLET
-- ============================================

function M.getMagicBulletTarget()
    if not Settings.MagicBullet_Enabled then return nil end
    local best, bestDist = nil, math.huge
    local chars = Workspace:FindFirstChild("Characters")
    if not chars then return nil end

    for _, m in pairs(chars:GetChildren()) do
        if m ~= Mortis.getMyModel() and Mortis.isModelAlive(m) then
            local p = Mortis.findBestTargetPart(m, Settings.MagicBullet_TargetPart)
            if p then
                if Settings.MagicBullet_FOVCheck then
                    local inF, d = isInFOV(p.Position)
                    if inF and d < bestDist then
                        bestDist = d
                        best = p
                    end
                else
                    local myH = Mortis.getHRP()
                    if myH then
                        local d = (p.Position - myH.Position).Magnitude
                        if d < bestDist then
                            bestDist = d
                            best = p
                        end
                    end
                end
            end
        end
    end
    return best
end

-- ============================================
-- ANTI-RECOIL
-- ============================================

function M.applyAntiRecoil()
    if not Settings.AntiRecoil_Enabled or Settings.AimbotActive then
        lastCamLook = Camera.CFrame.LookVector
        return
    end

    local shooting = UserInputService:IsMouseButtonPressed(Enum.UserInputType.MouseButton1)
    if not shooting then
        lastCamLook = Camera.CFrame.LookVector
        return
    end
    if not lastCamLook then
        lastCamLook = Camera.CFrame.LookVector
        return
    end

    local vertDiff = Camera.CFrame.LookVector.Y - lastCamLook.Y
    if vertDiff > 0.001 then
        mousemoverel(0, vertDiff * (Settings.AntiRecoil_Strength/100) * 50)
    end
    lastCamLook = Camera.CFrame.LookVector
end

-- ============================================
-- NO HAND SHAKE
-- ============================================

function M.applyNoHandShake()
    if not Settings.NoHandShake_Enabled then
        ShakeData.baselineCFrame = nil
        return
    end
    if Settings.AimbotActive then return end

    local str = Settings.NoHandShake_Strength / 100
    local md = Vector2.zero
    pcall(function()
        md = UserInputService:GetMouseDelta()
    end)

    if not ShakeData.baselineCFrame then
        ShakeData.baselineCFrame = Camera.CFrame
        return
    end

    if md.Magnitude > 0.5 then
        ShakeData.baselineCFrame = Camera.CFrame
    else
        local cY,cX,cZ = Camera.CFrame:ToEulerAnglesYXZ()
        local bY,bX,bZ = ShakeData.baselineCFrame:ToEulerAnglesYXZ()
        local total = math.abs(cY-bY)+math.abs(cX-bX)+math.abs(cZ-bZ)
        if total > 0.001 and total < 0.1 then
            Camera.CFrame = CFrame.new(Camera.CFrame.Position)
                * CFrame.fromEulerAnglesYXZ(
                    bY+(cY-bY)*(1-str),
                    bX+(cX-bX)*(1-str),
                    bZ+(cZ-bZ)*(1-str)
                )
        else
            ShakeData.baselineCFrame = Camera.CFrame
        end
    end
end

function M.setupNoHandShakeHook()
    if not Settings.NoHandShake_Enabled then return end
    pcall(function()
        local target = Mortis.getMyModel() or Mortis.LocalPlayer.Character
        if not target then return end
        for _, d in pairs(target:GetDescendants()) do
            local n = d.Name:lower()
            if d:IsA("NumberValue") and (n:find("shake") or n:find("sway") or n:find("bob")) then
                d.Value = 0
            elseif d:IsA("Vector3Value") and (n:find("shake") or n:find("sway") or n:find("bob")) then
                d.Value = Vector3.zero
            end
        end
    end)
end

Mortis.Aim = M
Mortis.isAimKeyPressed = M.isAimKeyPressed
Mortis.createFOVCircle = M.createFOVCircle
Mortis.getBestTarget = M.getBestTarget
Mortis.aimAt = M.aimAt
Mortis.getMagicBulletTarget = M.getMagicBulletTarget
Mortis.applyAntiRecoil = M.applyAntiRecoil
Mortis.applyNoHandShake = M.applyNoHandShake
Mortis.setupNoHandShakeHook = M.setupNoHandShakeHook

return M

