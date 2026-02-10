-- lighting.lua — управление освещением и защита свойств Lighting

-- Берём уже созданный в core.lua/global Mortis, без Roblox require
local Mortis = getgenv().Mortis or {}
getgenv().Mortis = Mortis

local Lighting = Mortis.Lighting
local Settings = Mortis.Settings

local OriginalLighting = nil

local M = {}

function M.saveOriginalLighting()
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

function M.applyFullbright()
    if Settings.Fullbright_Enabled then
        forceFullbright()
    else
        restoreFullbright()
    end
end

function M.applyAlwaysDay()
    if Settings.AlwaysDay_Enabled then
        forceDay()
    else
        restoreDay()
    end
end

function M.applyRemoveFog()
    if Settings.RemoveFog_Enabled then
        forceFog()
    else
        restoreFog()
    end
end

function M.maintainLighting()
    if Settings.Fullbright_Enabled then forceFullbright() end
    if Settings.AlwaysDay_Enabled then forceDay() end
    if Settings.RemoveFog_Enabled then forceFog() end
end

function M.bindGuards()
    Lighting:GetPropertyChangedSignal("Ambient"):Connect(function()
        if Settings.Fullbright_Enabled then
            Lighting.Ambient = Color3.fromRGB(255,255,255)
        end
    end)

    Lighting:GetPropertyChangedSignal("OutdoorAmbient"):Connect(function()
        if Settings.Fullbright_Enabled then
            Lighting.OutdoorAmbient = Color3.fromRGB(255,255,255)
        end
    end)

    Lighting:GetPropertyChangedSignal("Brightness"):Connect(function()
        if Settings.Fullbright_Enabled then
            Lighting.Brightness = 2
        end
    end)

    Lighting:GetPropertyChangedSignal("ExposureCompensation"):Connect(function()
        if Settings.Fullbright_Enabled then
            Lighting.ExposureCompensation = 0.5
        end
    end)

    Lighting:GetPropertyChangedSignal("ClockTime"):Connect(function()
        if Settings.AlwaysDay_Enabled then
            Lighting.ClockTime = 14
        end
    end)

    Lighting:GetPropertyChangedSignal("TimeOfDay"):Connect(function()
        if Settings.AlwaysDay_Enabled then
            Lighting.TimeOfDay = "14:00:00"
        end
    end)

    Lighting:GetPropertyChangedSignal("FogEnd"):Connect(function()
        if Settings.RemoveFog_Enabled then
            Lighting.FogEnd = 100000
        end
    end)

    Lighting:GetPropertyChangedSignal("FogStart"):Connect(function()
        if Settings.RemoveFog_Enabled then
            Lighting.FogStart = 100000
        end
    end)
end

Mortis.LightingModule = M

return M

