--2023-MA Style EffectEngine by Markus aka Ms.Videoproductions_Ltd#5345-MS.StageAudioSystems-GmbH
-- Enhanced with MA Lighting-style features

local Stop = false
local ts = game:GetService("TweenService")
local ColorSequence1 = ColorSequence.new(Color3.new(1, 0, 0), Color3.new(0, 0, 1))

-- Layering system variables
local activeDimmerEffect = nil
local activeColorEffect = nil
local layeringEnabled = true -- Enabled by default

-- Helper function to get the Bands folder
local function getWristbandsContainer()
    return script.Parent.Parent.Parent:FindFirstChild("Bands")
end

-- Helper to get parameter from Bands folder attribute with defaults
local function GetParameter(param)
    local bandsFolder = getWristbandsContainer()
    if bandsFolder and bandsFolder:GetAttribute(param) ~= nil then
        return bandsFolder:GetAttribute(param)
    end
    
    -- Return defaults if attribute is missing
    local defaults = {
        DimmerSpeed = 1,
        ColorSpeed = 1,
        Phase = 0,
        Amplitude = 1,
        Offset = 0,
        Invert = false,
        Wings = 1,
        Direction = 1,
        Intensity = 1,
        FadeTime = 0.5,
        Primary = Color3.fromRGB(255,255,255),
        Secondary = Color3.fromRGB(0,128,255)
    }
    
    return defaults[param]
end

-- Helper functions for getting dimmer and color speeds
local function GetDimmerSpeed()
    return GetParameter("DimmerSpeed")
end

local function GetColorSpeed()
    return GetParameter("ColorSpeed")
end

-- Listen for attribute changes on Bands folder
local function ListenToBandAttributes()
    local bandsFolder = getWristbandsContainer()
    if not bandsFolder then return end
    bandsFolder.AttributeChanged:Connect(function(attr)
        -- Optionally: print("Attribute changed:", attr, bandsFolder:GetAttribute(attr))
        -- Effects will auto-update since GetParameter always reads live
    end)
end

ListenToBandAttributes()

function applyColorTween(led, spot, color)
    ts:Create(led, TweenInfo.new(0.5), { Color = color }):Play()
    ts:Create(spot, TweenInfo.new(0.5), { Color = color }):Play()
end

-- Helper function to get all bands in a specific zone
local function getBandsInZone(Wristbands, zoneID)
    local zoneBands = {}
    if not Wristbands then return zoneBands end
    for _, band in pairs(Wristbands:GetChildren()) do
        if band:GetAttribute("ZoneID") == zoneID and band:FindFirstChild("Led") and band.Led:FindFirstChild("PointLight") then
            table.insert(zoneBands, band)
        end
    end
    return zoneBands
end

-- Helper function to get all bands (including static pixels) - dynamic detection
local function getAllBands(Wristbands)
    local bands = {}
    if not Wristbands then return bands end
    for _, band in pairs(Wristbands:GetChildren()) do
        if band:FindFirstChild("Led") and band.Led:FindFirstChild("PointLight") then
            table.insert(bands, band)
        end
    end
    return bands
end

-- Updated applyToBand to accept setColor parameter
local function applyToBand(band, color, transparency, brightness, setColor)
    if band and band:FindFirstChild("Led") and band.Led:FindFirstChild("PointLight") then
        if setColor and color then
            band.Led.Color = color
            band.Led.PointLight.Color = color
        end
        if transparency ~= nil then
            band.Led.Transparency = transparency
        end
        if brightness ~= nil then
            band.Led.PointLight.Brightness = brightness
        end
    end
end

-- Update applyToZone to accept setColor and propagate to applyToBand
local function applyToZone(Wristbands, zoneID, color, transparency, brightness, setColor)
    local zoneBands = getBandsInZone(Wristbands, zoneID)
    for _, band in pairs(zoneBands) do
        applyToBand(band, color, transparency, brightness, setColor)
    end
end

-- Helper to get a safe color attribute or fallback
local function getSafeColorAttribute(attrName, defaultColor)
    local bandsFolder = getWristbandsContainer()
    local color = defaultColor
    if bandsFolder then
        local attr = bandsFolder:GetAttribute(attrName)
        if attr and typeof(attr) == "Color3" then
            -- Check for black or zero
            if attr.R == 0 and attr.G == 0 and attr.B == 0 then
                color = defaultColor
            else
                color = attr
            end
        end
    end
    return color
end

-- On server start, set defaults if needed
local function setDefaultParametersIfNeeded()
    local bandsFolder = getWristbandsContainer()
    if not bandsFolder then return end
    
    -- Define all parameter defaults
    local defaults = {
        DimmerSpeed = 1,
        ColorSpeed = 1,
        Phase = 0,
        Amplitude = 1,
        Offset = 0,
        Invert = false,
        Wings = 1,
        Direction = 1,
        Intensity = 1,
        FadeTime = 0.5,
        Primary = Color3.fromRGB(255,255,255),
        Secondary = Color3.fromRGB(0,128,255)
    }
    
    -- Set each parameter if missing
    for paramName, defaultValue in pairs(defaults) do
        local currentValue = bandsFolder:GetAttribute(paramName)
        if currentValue == nil then
            bandsFolder:SetAttribute(paramName, defaultValue)
        elseif typeof(currentValue) == "Color3" and currentValue.R == 0 and currentValue.G == 0 and currentValue.B == 0 then
            -- Special case for black colors
            bandsFolder:SetAttribute(paramName, defaultValue)
        end
    end
end

setDefaultParametersIfNeeded()

-- Layering system functions
local function isDimmerEffect(effectName)
    local dimmerEffects = {
        -- MA_Effects category (brightness/transparency only)
        "Cue1", "Dim", "Pulse", "Wave", "Chase", "Breath", "Bounce", "Strobe", "Ripple", "Twinkle", "Sparkle",
        -- System category (brightness/transparency only)
        "On", "Off",
        -- Zone_Flash category (brightness/transparency only)
        "OddFlash", "EvenFlash", "HalfFlashZone1to5", "HalfFlashZone6to10",
        "Zone1to3Flash", "Zone4to6Flash", "Zone7to9Flash", "Zone10Flash",
        "ZoneChase", "ZoneReverseChase", "ZonePingPong"
    }
    
    for _, effect in ipairs(dimmerEffects) do
        if effectName == effect then
            return true
        end
    end
    return false
end

local function isColorEffect(effectName)
    local colorEffects = {
        -- Color_Effects category (colors only)
        "OddEvenColor", "LeftToRight", "MA_Rainbow", "MA_Fire", "MA_Water", 
        "RainbowGradient", "PrimarySecondaryGradient", "AnimatedGradient", "MultiColorGradient", 
        "RadialGradient", "PulseGradient", "SpiralGradient", "Alternate", "Fade", "Random", "Scan", 
        "ColorWave", "Rainbow"
    }
    
    for _, effect in ipairs(colorEffects) do
        if effectName == effect then
            return true
        end
    end
    return false
end

local function isStandaloneEffect(effectName)
    -- No standalone effects anymore - all effects are now properly categorized
    return false
end

local function canStartEffect(effectName)
    if not layeringEnabled then
        return true
    end
    
    -- Standalone effects stop everything and run alone
    if isStandaloneEffect(effectName) then
        return true
    end
    
    -- Both dimmer and color effects can run simultaneously
    -- Only prevent multiple effects of the same type
    if isDimmerEffect(effectName) then
        if activeDimmerEffect and activeDimmerEffect ~= effectName then
            return false, "Another dimmer effect is already running: " .. activeDimmerEffect
        end
    elseif isColorEffect(effectName) then
        if activeColorEffect and activeColorEffect ~= effectName then
            return false, "Another color effect is already running: " .. activeColorEffect
        end
    end
    
    return true
end

local function registerEffect(effectName)
    if not layeringEnabled then
        return
    end
    
    -- Standalone effects clear everything and register as standalone
    if isStandaloneEffect(effectName) then
        activeDimmerEffect = nil
        activeColorEffect = nil
        -- Note: We don't register standalone effects in the layering system
        return
    end
    
    if isDimmerEffect(effectName) then
        activeDimmerEffect = effectName
    elseif isColorEffect(effectName) then
        activeColorEffect = effectName
    end
end

local function unregisterEffect(effectName)
    if not layeringEnabled then
        return
    end
    
    if isDimmerEffect(effectName) then
        if activeDimmerEffect == effectName then
            activeDimmerEffect = nil
        end
    elseif isColorEffect(effectName) then
        if activeColorEffect == effectName then
            activeColorEffect = nil
        end
    end
end

-- Global reference to the highlighting function
local highlightFunction = nil

-- Function to set the highlighting function reference
local function setHighlightFunction(func)
    highlightFunction = func
end

-- Function to call highlighting periodically with throttling
local lastHighlightTime = 0
local highlightThrottle = 0.1 -- Update highlighting every 0.1 seconds for better responsiveness

local function updateHighlighting()
    local currentTime = tick()
    if highlightFunction and (currentTime - lastHighlightTime) >= highlightThrottle then
        highlightFunction()
        lastHighlightTime = currentTime
    end
end

-- Function to force immediate highlighting update
local function forceUpdateHighlighting()
    if highlightFunction then
        highlightFunction()
        lastHighlightTime = tick()
    end
end

-- Enhanced Stop function that clears all active effects
local function stopAllEffects()
    Stop = true
    activeDimmerEffect = nil
    activeColorEffect = nil
    
    -- Turn all bands black when stopping any cue
    local Wristbands = getWristbandsContainer()
    if Wristbands then
        for zoneID = 1, 10 do
            applyToZone(Wristbands, zoneID, nil, 1, 0, false)
        end
    end
    
    -- Force update highlighting to clear any active highlights
    forceUpdateHighlighting()
end

-- Function to stop only effects of a specific type (for layering)
local function stopEffectsOfType(effectType)
    if effectType == "dimmer" then
        if activeDimmerEffect then
            Stop = true
            wait(0.1) -- Give time for the dimmer effect to stop
            activeDimmerEffect = nil
        end
    elseif effectType == "color" then
        if activeColorEffect then
            Stop = true
            wait(0.1) -- Give time for the color effect to stop
            activeColorEffect = nil
        end
    end
end

-- Wrapper function to handle layering for effects
-- Note: Dimmer and color effects can now run simultaneously
-- Only effects of the same type (dimmer vs dimmer, color vs color) will stop each other
local function runEffectWithLayering(effectName, effectFunction)
    -- Stop all effects if this is a standalone effect
    if isStandaloneEffect(effectName) then
        Stop = true
        wait(0.2) -- Give more time for all effects to stop
        stopAllEffects()
        wait(0.1) -- Additional wait to ensure effects are stopped
    else
        -- Only stop effects of the same type - allow dimmer and color to run together
        if isDimmerEffect(effectName) and activeDimmerEffect and activeDimmerEffect ~= effectName then
            stopEffectsOfType("dimmer")
            wait(0.1) -- Give time for the dimmer effect to stop
        elseif isColorEffect(effectName) and activeColorEffect and activeColorEffect ~= effectName then
            stopEffectsOfType("color")
            wait(0.1) -- Give time for the color effect to stop
        end
        -- Note: We don't stop effects of different types - they can run simultaneously
    end
    
    -- Register this effect
    registerEffect(effectName)
    
    -- Force immediate highlighting update to show the new active effect
    forceUpdateHighlighting()
    
    -- Reset Stop flag and run the effect
    Stop = false
    
    -- Run the effect function with proper error handling
    local success, error = pcall(function()
        effectFunction()
    end)
    
    -- Only unregister if the effect failed to start or encountered an error
    -- For successful effects, they will unregister themselves when they stop
    if not success then
        unregisterEffect(effectName)
        warn("Effect '" .. effectName .. "' encountered an error: " .. tostring(error))
    end
end

-- Add this helper function near the top of the file, after the layering system variables:
local function isAnyDimmerActive()
    return activeDimmerEffect ~= nil
end

-- Helper function to get appropriate brightness for color effects
local function getColorEffectBrightness(defaultBrightness)
    defaultBrightness = defaultBrightness or 1
    if isAnyDimmerActive() then
        return nil -- Don't set brightness if dimmer effect is active - let dimmer control it
    else
        return defaultBrightness -- Set default brightness if no dimmer effect is running
    end
end

-- Helper function to unregister effect when loop breaks
local function unregisterOnStop(effectName)
    if Stop then
        unregisterEffect(effectName)
    end
end

-- In all color cue effect functions (ColorCues, Global, Professional color effects),
-- when calling applyToZone or applyToBand, check if a dimmer effect is active.
-- If not, set brightness to 1 (or a default value) when applying color.

-- Example for a color cue:
-- Instead of:
-- applyToZone(Wristbands, zoneID, color, nil, nil, true)
-- Use:
-- local brightness = isAnyDimmerActive() and nil or 1
-- applyToZone(Wristbands, zoneID, color, nil, brightness, true)

-- Apply this pattern to all color cue effect functions.

-- In all Global color cues, use getSafeColorAttribute and setColor=true
-- Example for a color cue in Global:
-- local primary = getSafeColorAttribute("Primary", Color3.fromRGB(255,255,255))
-- applyToZone(Wristbands, zoneID, primary, 0, intensity, true)

local Effects = {
    ["Internal"] = {
        getModuleName = function()
            return script.Name
        end,
    },
    
    ["System"] = {
        -- Function to get currently active effects
        GetActiveEffects = function()
            return {
                DimmerEffect = activeDimmerEffect,
                ColorEffect = activeColorEffect
            }
        end,
        
        -- Function to set the highlighting function reference
        SetHighlightFunction = function(func)
            highlightFunction = func
        end,
        
        -- Function to stop all effects
        Stop = function()
            stopAllEffects()
        end,
        
        -- Function to get all active effects (for compatibility)
        GetAllActiveEffects = function()
            local effects = {}
            if activeDimmerEffect then
                table.insert(effects, activeDimmerEffect)
            end
            if activeColorEffect then
                table.insert(effects, activeColorEffect)
            end
            return effects
        end,
        
        -- Function to check if any effects are running
        IsAnyEffectRunning = function()
            return activeDimmerEffect ~= nil or activeColorEffect ~= nil
        end,
        
        -- Function to get layering status
        GetLayeringStatus = function()
            return {
                Enabled = layeringEnabled,
                ActiveDimmer = activeDimmerEffect,
                ActiveColor = activeColorEffect
            }
        end,
        
        -- Function to enable/disable layering
        SetLayeringEnabled = function(enabled)
            layeringEnabled = enabled
        end,
        
        -- Function to force update highlighting
        ForceUpdateHighlighting = function()
            forceUpdateHighlighting()
        end,
        
        -- Function to force reset engine state (for debugging/fixing stuck states)
        ForceResetState = function()
            Stop = false
            activeDimmerEffect = nil
            activeColorEffect = nil
        end,
        
        -- Function to get engine status
        GetEngineStatus = function()
            return {
                Stop = Stop,
                LayeringEnabled = layeringEnabled,
                ActiveDimmerEffect = activeDimmerEffect,
                ActiveColorEffect = activeColorEffect,
                HighlightFunctionSet = highlightFunction ~= nil
            }
        end,
        
        -- Basic system controls
        On = function()
            runEffectWithLayering("On", function()
                local Style = Enum.EasingStyle.Sine
                while true do
                    if Stop then break end
                    local Wristbands = getWristbandsContainer()
                    for zoneID = 1, 10 do
                        if Stop then break end
                        applyToZone(Wristbands, zoneID, nil, 0, 2 * (GetParameter("Intensity") or 1), false)
                    end
                    updateHighlighting() -- Update highlighting periodically
                    wait(0.1)
                end
                -- Unregister when loop ends
                if Stop then
                    unregisterEffect("On")
                end
            end)
        end,

        Off = function()
            runEffectWithLayering("Off", function()
                local Style = Enum.EasingStyle.Sine
                local Wristbands = getWristbandsContainer()
                for zoneID = 1, 10 do
                    if Stop then break end
                    applyToZone(Wristbands, zoneID, nil, 1, 0, false)
                end
                -- Unregister when effect ends
                if Stop then
                    unregisterEffect("Off")
                end
            end)
        end,
        
        -- Parameter controls
        SetSpeed = function(speed)
            local bandsFolder = getWristbandsContainer()
            if bandsFolder then
                bandsFolder:SetAttribute("Speed", speed)
            end
        end,
        SetPhase = function(phase)
            local bandsFolder = getWristbandsContainer()
            if bandsFolder then
                bandsFolder:SetAttribute("Phase", phase)
            end
        end,
        SetAmplitude = function(amplitude)
            local bandsFolder = getWristbandsContainer()
            if bandsFolder then
                bandsFolder:SetAttribute("Amplitude", amplitude)
            end
        end,
        SetOffset = function(offset)
            local bandsFolder = getWristbandsContainer()
            if bandsFolder then
                bandsFolder:SetAttribute("Offset", offset)
            end
        end,
        SetIntensity = function(intensity)
            local bandsFolder = getWristbandsContainer()
            if bandsFolder then
                bandsFolder:SetAttribute("Intensity", intensity)
            end
        end,
        SetDirection = function(direction)
            local bandsFolder = getWristbandsContainer()
            if bandsFolder then
                bandsFolder:SetAttribute("Direction", direction)
            end
        end,
        SetInvert = function(invert)
            local bandsFolder = getWristbandsContainer()
            if bandsFolder then
                bandsFolder:SetAttribute("Invert", invert)
            end
        end,
        SetPrimary = function(color)
            local bandsFolder = getWristbandsContainer()
            if bandsFolder then
                bandsFolder:SetAttribute("Primary", color)
            end
        end,
        SetSecondary = function(color)
            local bandsFolder = getWristbandsContainer()
            if bandsFolder then
                bandsFolder:SetAttribute("Secondary", color)
            end
        end,
        GetAllParameters = function()
            local bandsFolder = getWristbandsContainer()
            if bandsFolder then
                return {
                    Speed = bandsFolder:GetAttribute("Speed"),
                    Phase = bandsFolder:GetAttribute("Phase"),
                    Amplitude = bandsFolder:GetAttribute("Amplitude"),
                    Offset = bandsFolder:GetAttribute("Offset"),
                    Invert = bandsFolder:GetAttribute("Invert"),
                    Wings = bandsFolder:GetAttribute("Wings"),
                    Direction = bandsFolder:GetAttribute("Direction"),
                    Intensity = bandsFolder:GetAttribute("Intensity"),
                    FadeTime = bandsFolder:GetAttribute("FadeTime"),
                    Primary = bandsFolder:GetAttribute("Primary"),
                    Secondary = bandsFolder:GetAttribute("Secondary")
                }
            end
            return {}
        end,
        
        -- Layering system controls
        EnableLayering = function()
            layeringEnabled = true
        end,
        
        DisableLayering = function()
            layeringEnabled = false
        end,
        
        StopAllEffects = function()
            stopAllEffects()
        end
    },

    ["Presets"] = {
        -- ===== SPEED PRESETS =====
        -- Control how fast effects animate (sets both dimmer and color speeds)
        ["Speed_VerySlow"] = function()
            local bandsFolder = getWristbandsContainer()
            if bandsFolder then
                bandsFolder:SetAttribute("DimmerSpeed", 0.1)
                bandsFolder:SetAttribute("ColorSpeed", 0.1)
            end
        end,
        ["Speed_Slow"] = function()
            local bandsFolder = getWristbandsContainer()
            if bandsFolder then
                bandsFolder:SetAttribute("DimmerSpeed", 0.3)
                bandsFolder:SetAttribute("ColorSpeed", 0.3)
            end
        end,
        ["Speed_Medium"] = function()
            local bandsFolder = getWristbandsContainer()
            if bandsFolder then
                bandsFolder:SetAttribute("DimmerSpeed", 0.7)
                bandsFolder:SetAttribute("ColorSpeed", 0.7)
            end
        end,
        ["Speed_Normal"] = function()
            local bandsFolder = getWristbandsContainer()
            if bandsFolder then
                bandsFolder:SetAttribute("DimmerSpeed", 1)
                bandsFolder:SetAttribute("ColorSpeed", 1)
            end
        end,
        ["Speed_Fast"] = function()
            local bandsFolder = getWristbandsContainer()
            if bandsFolder then
                bandsFolder:SetAttribute("DimmerSpeed", 1.5)
                bandsFolder:SetAttribute("ColorSpeed", 1.5)
            end
        end,
        ["Speed_VeryFast"] = function()
            local bandsFolder = getWristbandsContainer()
            if bandsFolder then
                bandsFolder:SetAttribute("DimmerSpeed", 2.5)
                bandsFolder:SetAttribute("ColorSpeed", 2.5)
            end
        end,
        ["Speed_Extreme"] = function()
            local bandsFolder = getWristbandsContainer()
            if bandsFolder then
                bandsFolder:SetAttribute("DimmerSpeed", 4)
                bandsFolder:SetAttribute("ColorSpeed", 4)
            end
        end,

        -- ===== DIMMER SPEED PRESETS =====
        -- Control dimmer effect speed only
        ["DimmerSpeed_Slow"] = function()
            local bandsFolder = getWristbandsContainer()
            if bandsFolder then
                bandsFolder:SetAttribute("DimmerSpeed", 0.3)
            end
        end,
        ["DimmerSpeed_Normal"] = function()
            local bandsFolder = getWristbandsContainer()
            if bandsFolder then
                bandsFolder:SetAttribute("DimmerSpeed", 1)
            end
        end,
        ["DimmerSpeed_Fast"] = function()
            local bandsFolder = getWristbandsContainer()
            if bandsFolder then
                bandsFolder:SetAttribute("DimmerSpeed", 2)
            end
        end,

        -- ===== COLOR SPEED PRESETS =====
        -- Control color effect speed only
        ["ColorSpeed_Slow"] = function()
            local bandsFolder = getWristbandsContainer()
            if bandsFolder then
                bandsFolder:SetAttribute("ColorSpeed", 0.3)
            end
        end,
        ["ColorSpeed_Normal"] = function()
            local bandsFolder = getWristbandsContainer()
            if bandsFolder then
                bandsFolder:SetAttribute("ColorSpeed", 1)
            end
        end,
        ["ColorSpeed_Fast"] = function()
            local bandsFolder = getWristbandsContainer()
            if bandsFolder then
                bandsFolder:SetAttribute("ColorSpeed", 2)
            end
        end,

        -- ===== BRIGHTNESS PRESETS =====
        -- Control overall brightness/intensity
        ["Brightness_Low"] = function()
            local bandsFolder = getWristbandsContainer()
            if bandsFolder then
                bandsFolder:SetAttribute("Intensity", 0.3)
            end
        end,
        ["Brightness_Full"] = function()
            local bandsFolder = getWristbandsContainer()
            if bandsFolder then
                bandsFolder:SetAttribute("Intensity", 2)
            end
        end,

        -- ===== SYSTEM PRESETS =====
        -- Reset and default settings
        ["Reset_All"] = function()
            local bandsFolder = getWristbandsContainer()
            if bandsFolder then
                bandsFolder:SetAttribute("DimmerSpeed", 1)
                bandsFolder:SetAttribute("ColorSpeed", 1)
                bandsFolder:SetAttribute("Phase", 0)
                bandsFolder:SetAttribute("Amplitude", 1)
                bandsFolder:SetAttribute("Intensity", 1)
                bandsFolder:SetAttribute("Direction", 1)
            end
        end
    },
    
    ["Zone_Flash"] = {
        -- Zone-specific flash effects
        OddFlash = function()
            runEffectWithLayering("OddFlash", function()
                local Wristbands = getWristbandsContainer()
                if Wristbands then
                    for zoneID = 1, 10 do
                        if zoneID % 2 == 1 then -- Odd zones
                            applyToZone(Wristbands, zoneID, nil, 0, GetParameter("Intensity") or 1, false)
                            task.wait(0.1)
                            applyToZone(Wristbands, zoneID, nil, 1, 0, false)
                        end
                    end
                end
                task.wait(0.5)
                -- Unregister when effect ends
                if Stop then
                    unregisterEffect("OddFlash")
                end
            end)
        end,
        
        EvenFlash = function()
            runEffectWithLayering("EvenFlash", function()
                local Wristbands = getWristbandsContainer()
                if Wristbands then
                    for zoneID = 1, 10 do
                        if zoneID % 2 == 0 then -- Even zones
                            applyToZone(Wristbands, zoneID, nil, 0, GetParameter("Intensity") or 1, false)
                            task.wait(0.1)
                            applyToZone(Wristbands, zoneID, nil, 1, 0, false)
                        end
                    end
                end
                task.wait(0.5)
                -- Unregister when effect ends
                if Stop then
                    unregisterEffect("EvenFlash")
                end
            end)
        end,
        
        HalfFlashZone1to5 = function()
            runEffectWithLayering("HalfFlashZone1to5", function()
                local Wristbands = getWristbandsContainer()
                if Wristbands then
                    for zoneID = 1, 5 do
                        applyToZone(Wristbands, zoneID, nil, 0, GetParameter("Intensity") or 1, false)
                        task.wait(0.1)
                        applyToZone(Wristbands, zoneID, nil, 1, 0, false)
                    end
                end
                task.wait(0.5)
                -- Unregister when effect ends
                if Stop then
                    unregisterEffect("HalfFlashZone1to5")
                end
            end)
        end,
        
        HalfFlashZone6to10 = function()
            runEffectWithLayering("HalfFlashZone6to10", function()
                local Wristbands = getWristbandsContainer()
                if Wristbands then
                    for zoneID = 6, 10 do
                        applyToZone(Wristbands, zoneID, nil, 0, GetParameter("Intensity") or 1, false)
                        task.wait(0.1)
                        applyToZone(Wristbands, zoneID, nil, 1, 0, false)
                    end
                end
                task.wait(0.5)
                -- Unregister when effect ends
                if Stop then
                    unregisterEffect("HalfFlashZone6to10")
                end
            end)
        end,

        Zone1to3Flash = function()
            runEffectWithLayering("Zone1to3Flash", function()
                local Wristbands = getWristbandsContainer()
                if Wristbands then
                    for zoneID = 1, 3 do
                        applyToZone(Wristbands, zoneID, nil, 0, GetParameter("Intensity") or 1, false)
                        task.wait(0.1)
                        applyToZone(Wristbands, zoneID, nil, 1, 0, false)
                    end
                end
                task.wait(0.5)
                -- Unregister when effect ends
                if Stop then
                    unregisterEffect("Zone1to3Flash")
                end
            end)
        end,

        Zone4to6Flash = function()
            runEffectWithLayering("Zone4to6Flash", function()
                local Wristbands = getWristbandsContainer()
                if Wristbands then
                    for zoneID = 4, 6 do
                        applyToZone(Wristbands, zoneID, nil, 0, GetParameter("Intensity") or 1, false)
                        task.wait(0.1)
                        applyToZone(Wristbands, zoneID, nil, 1, 0, false)
                    end
                end
                task.wait(0.5)
                -- Unregister when effect ends
                if Stop then
                    unregisterEffect("Zone4to6Flash")
                end
            end)
        end,

        Zone7to9Flash = function()
            runEffectWithLayering("Zone7to9Flash", function()
                local Wristbands = getWristbandsContainer()
                if Wristbands then
                    for zoneID = 7, 9 do
                        applyToZone(Wristbands, zoneID, nil, 0, GetParameter("Intensity") or 1, false)
                        task.wait(0.1)
                        applyToZone(Wristbands, zoneID, nil, 1, 0, false)
                    end
                end
                task.wait(0.5)
                -- Unregister when effect ends
                if Stop then
                    unregisterEffect("Zone7to9Flash")
                end
            end)
        end,

        Zone10Flash = function()
            runEffectWithLayering("Zone10Flash", function()
                local Style = Enum.EasingStyle.Sine
                local Wristbands = getWristbandsContainer()
                applyToZone(Wristbands, 10, nil, 0, GetParameter("Intensity") or 1, false)
                task.wait(0.1)
                for _, band in pairs(getBandsInZone(Wristbands, 10)) do
                    ts:Create(band.Led, TweenInfo.new(0.2, Style), { Transparency = 1 }):Play()
                    ts:Create(band.Led.PointLight, TweenInfo.new(0.2, Style), { Brightness = 0 }):Play()
                end
                task.wait(0.5)
                -- Unregister when effect ends
                if Stop then
                    unregisterEffect("Zone10Flash")
                end
            end)
        end,

        ZoneChase = function()
            runEffectWithLayering("ZoneChase", function()
                local Style = Enum.EasingStyle.Sine
                while true do
                    if Stop then break end
                    local Wristbands = getWristbandsContainer()
                    
                    for zoneID = 1, 10 do
                        if Stop then break end
                        -- Turn off all zones
                        for z = 1, 10 do
                            applyToZone(Wristbands, z, nil, 1, 0, false)
                        end
                        -- Turn on current zone
                        applyToZone(Wristbands, zoneID, nil, 0, GetParameter("Intensity") or 1, false)
                        task.wait(GetDimmerSpeed() or 0.2)
                    end
                    updateHighlighting() -- Update highlighting periodically
                end
                -- Unregister when loop ends
                if Stop then
                    unregisterEffect("ZoneChase")
                end
            end)
        end,

        -- Zone Reverse Chase (10 to 1)
        ZoneReverseChase = function()
            runEffectWithLayering("ZoneReverseChase", function()
                local Style = Enum.EasingStyle.Sine
                while true do
                    if Stop then break end
                    local Wristbands = getWristbandsContainer()
                    
                    for zoneID = 10, 1, -1 do
                        if Stop then break end
                        -- Turn off all zones
                        for z = 1, 10 do
                            applyToZone(Wristbands, z, nil, 1, 0, false)
                        end
                        -- Turn on current zone
                        applyToZone(Wristbands, zoneID, nil, 0, GetParameter("Intensity") or 1, false)
                        task.wait(GetDimmerSpeed() or 0.2)
                    end
                    updateHighlighting() -- Update highlighting periodically
                end
                -- Unregister when loop ends
                if Stop then
                    unregisterEffect("ZoneReverseChase")
                end
            end)
        end,

        -- Zone Ping Pong
        ZonePingPong = function()
            runEffectWithLayering("ZonePingPong", function()
                local Style = Enum.EasingStyle.Sine
                local direction = 1
                local currentZone = 1
                
                while true do
                    if Stop then break end
                    local Wristbands = getWristbandsContainer()
                    
                    -- Turn off all zones
                    for z = 1, 10 do
                        applyToZone(Wristbands, z, nil, 1, 0, false)
                    end
                    -- Turn on current zone
                    applyToZone(Wristbands, currentZone, nil, 0, GetParameter("Intensity") or 1, false)
                    
                    currentZone = currentZone + direction
                    if currentZone >= 10 then
                        direction = -1
                    elseif currentZone <= 1 then
                        direction = 1
                    end
                    
                    task.wait(GetDimmerSpeed() or 0.2)
                    updateHighlighting() -- Update highlighting periodically
                end
                -- Unregister when loop ends
                if Stop then
                    unregisterEffect("ZonePingPong")
                end
            end)
        end,
    },
    
    ["MA_Effects"] = {
        -- MA Lighting-style effects with parameter control
        Cue1 = function(Speed, distanceBetweenZones, transparencyMultiplier, brightnessMultiplier, reverse)
            runEffectWithLayering("Cue1", function()
                Speed = Speed or GetDimmerSpeed()
                distanceBetweenZones = distanceBetweenZones or GetParameter("Phase")
                transparencyMultiplier = transparencyMultiplier or GetParameter("Amplitude")
                brightnessMultiplier = brightnessMultiplier or GetParameter("Amplitude")
                reverse = reverse or GetParameter("Invert")

                while true do
                    if Stop then break end
                    local Wristbands = getWristbandsContainer()
                    Speed = Speed + 20 / 100

                    for Index, LightBand in pairs(Wristbands:GetChildren()) do
                        if Stop then break end
                        spawn(function()
                            for zoneID = 1, 10 do
                                if Stop then break end
                                local centerZone = (10 + 1) / 2
                                local distanceFromCenter = distanceBetweenZones * math.abs(LightBand:GetAttribute("ZoneID") - centerZone)

                                if reverse then
                                    distanceFromCenter = -distanceFromCenter
                                end

                                if LightBand:GetAttribute("ZoneID") == zoneID then
                                    local sineValue = math.sin(Speed + distanceFromCenter * transparencyMultiplier) + 1
                                    local brightnessValue = 2 * math.cos(Speed + distanceFromCenter * brightnessMultiplier) + 1
                                    
                                    applyToBand(LightBand, nil, sineValue, brightnessValue * (GetParameter("Intensity") or 1), false)
                                end
                            end
                        end)
                    end
                    updateHighlighting() -- Update highlighting periodically
                    wait()
                end
                -- Unregister when loop ends
                if Stop then
                    unregisterEffect("Cue1")
                end
            end)
        end,
        
        -- MA Style Dim Effect
        Dim = function()
            runEffectWithLayering("Dim", function()
                local u3 = {}
                
                -- Initialize u3 for each zone
                for zoneID = 1, 10 do
                    u3[zoneID] = 0
                end
                
                while true do
                    if Stop then break end
                    local Wristbands = getWristbandsContainer()
                    
                    for zoneID = 1, 10 do
                        if Stop then break end
                        u3[zoneID] = u3[zoneID] + GetDimmerSpeed()
                        
                        local phaseDelay = (zoneID - 1) * GetParameter("Phase")
                        task.wait(phaseDelay)
                        
                        local sineValue
                        if GetParameter("Invert") then
                            sineValue = math.sin(-u3[zoneID]) * GetParameter("Amplitude") + GetParameter("Offset")
                        else
                            sineValue = math.sin(u3[zoneID]) * GetParameter("Amplitude") + GetParameter("Offset")
                        end
                        
                        sineValue = math.clamp(sineValue, 0, 1)
                        applyToZone(Wristbands, zoneID, nil, sineValue, (1 - sineValue) * (GetParameter("Intensity") or 1), false)
                    end
                    wait()
                end
                -- Unregister when loop ends
                if Stop then
                    unregisterEffect("Dim")
                end
            end)
        end,
        
        -- MA Style Pulse Effect
        Pulse = function()
            runEffectWithLayering("Pulse", function()
                local u3 = 0
                
                while true do
                    if Stop then break end
                    local Wristbands = getWristbandsContainer()
                    
                    u3 = u3 + GetDimmerSpeed()
                    local sineValue = math.sin(u3) * GetParameter("Amplitude") + GetParameter("Offset")
                    sineValue = math.clamp(sineValue, 0, 1)
                    
                    if Wristbands then
                        for zoneID = 1, 10 do
                            if Stop then break end
                            applyToZone(Wristbands, zoneID, nil, sineValue, (1 - sineValue) * (GetParameter("Intensity") or 1), false)
                        end
                    end
                    updateHighlighting() -- Update highlighting periodically
                    wait()
                end
                -- Unregister when loop ends
                if Stop then
                    unregisterEffect("Pulse")
                end
            end)
        end,
        
        -- MA Style Wave Effect
        Wave = function()
            runEffectWithLayering("Wave", function()
                local u3 = {}
                
                for zoneID = 1, 10 do
                    u3[zoneID] = 0
                end
                
                while true do
                    if Stop then break end
                    local Wristbands = getWristbandsContainer()
                    
                    if Wristbands then
                        for zoneID = 1, 10 do
                            if Stop then break end
                            u3[zoneID] = u3[zoneID] + GetDimmerSpeed()
                            
                            local waveValue = math.sin(u3[zoneID] + (zoneID * GetParameter("Phase"))) * GetParameter("Amplitude") + GetParameter("Offset")
                            waveValue = math.clamp(waveValue, 0, 1)
                            
                            applyToZone(Wristbands, zoneID, nil, waveValue, (1 - waveValue) * (GetParameter("Intensity") or 1), false)
                        end
                    end
                    
                    updateHighlighting() -- Update highlighting periodically
                    wait()
                end
                -- Unregister when loop ends
                if Stop then
                    unregisterEffect("Wave")
                end
            end)
        end,
        
        -- MA Style Chase Effect
        Chase = function()
            runEffectWithLayering("Chase", function()
                local currentZone = 1
                local direction = GetParameter("Direction")
                
                while true do
                    if Stop then break end
                    local Wristbands = getWristbandsContainer()
                    
                    if Wristbands then
                        -- Turn off all zones
                        for zoneID = 1, 10 do
                            if Stop then break end
                            applyToZone(Wristbands, zoneID, nil, 1, 0, false)
                        end
                        
                        -- Turn on current zone
                        applyToZone(Wristbands, currentZone, nil, 0, (GetParameter("Intensity") or 1), false)
                    end
                    
                    -- Move to next zone
                    currentZone = currentZone + direction
                    if currentZone > 10 then
                        currentZone = 1
                    elseif currentZone < 1 then
                        currentZone = 10
                    end
                    
                    task.wait(1 / GetDimmerSpeed())
                    updateHighlighting() -- Update highlighting periodically
                end
                -- Unregister when loop ends
                if Stop then
                    unregisterEffect("Chase")
                end
            end)
        end,
        
        -- Breath Effect (proper dimmer effect - brightness/transparency only)
        Breath = function(speed)
            runEffectWithLayering("Breath", function()
                speed = speed or 0.02
                local time = 0
                while true do
                    if Stop then break end
                    time = time + speed
                    local intensity = (math.sin(time) + 1) / 2
                    local Wristbands = getWristbandsContainer()
                    
                    if Wristbands then
                        for zone = 1, 10 do
                            if Stop then break end
                            -- Apply dimmer effect (no color, only brightness/transparency)
                            applyToZone(Wristbands, zone, nil, 1 - intensity, intensity * (GetParameter("Intensity") or 1), false)
                        end
                    end
                    wait(0.016)
                    updateHighlighting() -- Update highlighting periodically
                end
                -- Unregister when loop ends
                if Stop then
                    unregisterEffect("Breath")
                end
            end)
        end,

        -- Bounce Effect (proper dimmer effect - brightness/transparency only)
        Bounce = function(speed)
            runEffectWithLayering("Bounce", function()
                speed = speed or 0.1
                local position = 1
                local direction = 1
                while true do
                    if Stop then break end
                    local Wristbands = getWristbandsContainer()
                    
                    if Wristbands then
                        -- Turn off all zones
                        for zone = 1, 10 do
                            if Stop then break end
                            applyToZone(Wristbands, zone, nil, 1, 0, false)
                        end
                        
                        -- Turn on current zone
                        local currentZone = math.floor(position)
                        if currentZone >= 1 and currentZone <= 10 then
                            applyToZone(Wristbands, currentZone, nil, 0, (GetParameter("Intensity") or 1), false)
                        end
                    end
                    
                    position = position + direction * speed
                    if position >= 10 then
                        direction = -1
                    elseif position <= 1 then
                        direction = 1
                    end
                    wait(0.1)
                    updateHighlighting() -- Update highlighting periodically
                end
                -- Unregister when loop ends
                if Stop then
                    unregisterEffect("Bounce")
                end
            end)
        end,



        -- Strobe Effect (moved from Color_Effects to MA_Effects - dimmer only)
        Strobe = function(speed)
            runEffectWithLayering("Strobe", function()
                speed = speed or 0.1
                while true do
                    if Stop then break end
                    local Wristbands = getWristbandsContainer()
                    if Wristbands then
                        for zone = 1, 10 do
                            if Stop then break end
                            applyToZone(Wristbands, zone, nil, 0, GetParameter("Intensity") or 1, false)
                        end
                    end
                    wait(speed)
                    if Stop then break end
                    if Wristbands then
                        for zone = 1, 10 do
                            if Stop then break end
                            applyToZone(Wristbands, zone, nil, 1, 0, false)
                        end
                    end
                    wait(speed)
                    updateHighlighting() -- Update highlighting periodically
                end
                -- Unregister when loop ends
                if Stop then
                    unregisterEffect("Strobe")
                end
            end)
        end,

        -- Ripple Effect (moved from Color_Effects to MA_Effects - dimmer only)
        Ripple = function(speed)
            runEffectWithLayering("Ripple", function()
                speed = speed or 0.1
                local time = 0
                while true do
                    if Stop then break end
                    time = time + speed
                    local Wristbands = getWristbandsContainer()
                    if Wristbands then
                        for zone = 1, 10 do
                            if Stop then break end
                            local distance = math.abs(zone - 5.5)
                            local ripple = math.sin(time - distance) * 0.5 + 0.5
                            applyToZone(Wristbands, zone, nil, 1 - ripple, ripple * (GetParameter("Intensity") or 1), false)
                        end
                    end
                    wait(0.016)
                    updateHighlighting() -- Update highlighting periodically
                end
                -- Unregister when loop ends
                if Stop then
                    unregisterEffect("Ripple")
                end
            end)
        end,

        -- Twinkle Effect (moved from Color_Effects to MA_Effects - dimmer only)
        Twinkle = function(speed)
            runEffectWithLayering("Twinkle", function()
                speed = speed or 0.05
                local twinkleStates = {}
                for i = 1, 10 do
                    twinkleStates[i] = math.random()
                end
                while true do
                    if Stop then break end
                    local Wristbands = getWristbandsContainer()
                    if Wristbands then
                        for zone = 1, 10 do
                            if Stop then break end
                            twinkleStates[zone] = twinkleStates[zone] + speed
                            if twinkleStates[zone] > 1 then
                                twinkleStates[zone] = 0
                            end
                            local twinkle = math.sin(twinkleStates[zone] * math.pi * 2) * 0.5 + 0.5
                            applyToZone(Wristbands, zone, nil, 1 - twinkle, twinkle * (GetParameter("Intensity") or 1), false)
                        end
                    end
                    wait(0.016)
                    updateHighlighting() -- Update highlighting periodically
                end
                -- Unregister when loop ends
                if Stop then
                    unregisterEffect("Twinkle")
                end
            end)
        end,

        -- Sparkle Effect (moved from Color_Effects to MA_Effects - dimmer only)
        Sparkle = function(speed)
            runEffectWithLayering("Sparkle", function()
                speed = speed or 0.05
                while true do
                    if Stop then break end
                    local Wristbands = getWristbandsContainer()
                    if Wristbands then
                        for zone = 1, 10 do
                            if Stop then break end
                            applyToZone(Wristbands, zone, nil, 1, 0, false)
                        end
                        updateHighlighting() -- Update highlighting periodically
                        for i = 1, math.random(1, 4) do
                            if Stop then break end
                            local zone = math.random(1, 10)
                            applyToZone(Wristbands, zone, nil, 0, (GetParameter("Intensity") or 1), false)
                        end
                    end
                    wait(speed)
                end
                -- Unregister when loop ends
                if Stop then
                    unregisterEffect("Sparkle")
                end
            end)
        end,

    },

    ["Color_Effects"] = {
        
        
        
        OddEvenColor = function()
            runEffectWithLayering("OddEvenColor", function()
                local Primary = GetParameter("Primary")
                local Secondary = GetParameter("Secondary")
                while true do
                    if Stop then break end
                    local Wristbands = getWristbandsContainer()
                    local brightness = getColorEffectBrightness()
                    if Wristbands then
                        for zoneID = 1, 10 do
                            if Stop then break end
                            if zoneID % 2 == 1 then
                                applyToZone(Wristbands, zoneID, Primary, nil, brightness, true)
                            else
                                applyToZone(Wristbands, zoneID, Secondary, nil, brightness, true)
                            end
                        end
                    end
                    updateHighlighting() -- Update highlighting periodically
                    wait(GetColorSpeed() or 1)
                    if Stop then break end
                    if Wristbands then
                        for zoneID = 1, 10 do
                            if Stop then break end
                            if zoneID % 2 == 1 then
                                applyToZone(Wristbands, zoneID, Secondary, nil, brightness, true)
                            else
                                applyToZone(Wristbands, zoneID, Primary, nil, brightness, true)
                            end
                        end
                    end
                    updateHighlighting() -- Update highlighting periodically
                    wait(GetColorSpeed() or 1)
                end
                -- Unregister when loop ends
                if Stop then
                    unregisterEffect("OddEvenColor")
                end
            end)
        end,
        
        LeftToRight = function()
            runEffectWithLayering("LeftToRight", function()
                local Primary = GetParameter("Primary")
                local Secondary = GetParameter("Secondary")
                while true do
                    if Stop then break end
                    local Wristbands = getWristbandsContainer()
                    local brightness = getColorEffectBrightness()
                    if Wristbands then
                        for zoneID = 1, 10 do
                            if Stop then break end
                            applyToZone(Wristbands, zoneID, Primary, nil, brightness, true)
                            wait(0.2)
                        end
                        if Stop then break end
                        for zoneID = 10, 1, -1 do
                            if Stop then break end
                            applyToZone(Wristbands, zoneID, Secondary, nil, brightness, true)
                            wait(0.2)
                        end
                    end
                    updateHighlighting() -- Update highlighting periodically
                end
                -- Unregister when loop ends
                if Stop then
                    unregisterEffect("LeftToRight")
                end
            end)
        end,
        
        -- MA Style Rainbow Effect
        MA_Rainbow = function()
            runEffectWithLayering("MA_Rainbow", function()
                local u3 = {}
                for zoneID = 1, 10 do u3[zoneID] = 0 end
                while true do
                    if Stop then break end
                    local Wristbands = getWristbandsContainer()
                    for zoneID = 1, 10 do
                        if Stop then break end
                        u3[zoneID] = u3[zoneID] + GetColorSpeed()
                        local hue = (u3[zoneID] + (zoneID * GetParameter("Phase"))) % 360
                        local color = Color3.fromHSV(hue / 360, 1, 1)
                        applyToZone(Wristbands, zoneID, color, 0, (GetParameter("Intensity") or 1), true)
                    end
                    updateHighlighting() -- Update highlighting periodically
                    wait()
                end
                -- Unregister when loop ends
                if Stop then
                    unregisterEffect("MA_Rainbow")
                end
            end)
        end,
        
        -- MA Style Fire Effect
        MA_Fire = function()
            runEffectWithLayering("MA_Fire", function()
                local u3 = {}
                for zoneID = 1, 10 do u3[zoneID] = math.random() * 100 end
                while true do
                    if Stop then break end
                    local Wristbands = getWristbandsContainer()
                    for zoneID = 1, 10 do
                        if Stop then break end
                        u3[zoneID] = u3[zoneID] + GetColorSpeed()
                        local fireValue = math.sin(u3[zoneID]) * 0.5 + 0.5
                        fireValue = math.clamp(fireValue, 0, 1)
                        local color = Color3.fromRGB(255, fireValue * 100, 0)
                        applyToZone(Wristbands, zoneID, color, 1 - fireValue, fireValue * (GetParameter("Intensity") or 1), true)
                    end
                    updateHighlighting() -- Update highlighting periodically
                    wait()
                end
                -- Unregister when loop ends
                if Stop then
                    unregisterEffect("MA_Fire")
                end
            end)
        end,
        
        -- MA Style Water Effect
        MA_Water = function()
            runEffectWithLayering("MA_Water", function()
                local u3 = {}
                for zoneID = 1, 10 do u3[zoneID] = math.random() * 100 end
                while true do
                    if Stop then break end
                    local Wristbands = getWristbandsContainer()
                    for zoneID = 1, 10 do
                        if Stop then break end
                        u3[zoneID] = u3[zoneID] + GetColorSpeed()
                        local waterValue = math.sin(u3[zoneID]) * 0.3 + 0.7
                        waterValue = math.clamp(waterValue, 0, 1)
                        local color = Color3.fromRGB(0, waterValue * 0.5, 1)
                        applyToZone(Wristbands, zoneID, color, 1 - waterValue, waterValue * (GetParameter("Intensity") or 1), true)
                    end
                    updateHighlighting() -- Update highlighting periodically
                    wait()
                end
                -- Unregister when loop ends
                if Stop then
                    unregisterEffect("MA_Water")
                end
            end)
        end,
        
        -- Rainbow Gradient Effect
        RainbowGradient = function()
            runEffectWithLayering("RainbowGradient", function()
                local time = 0
                while true do
                    if Stop then break end
                    local Wristbands = getWristbandsContainer()
                    time = time + GetColorSpeed()
                    for zoneID = 1, 10 do
                        if Stop then break end
                        local hue = ((zoneID - 1) / 9 + (time * 0.1)) % 1
                        local color = Color3.fromHSV(hue, 1, 1)
                        applyToZone(Wristbands, zoneID, color, 0, (GetParameter("Intensity") or 1), true)
                    end
                    updateHighlighting() -- Update highlighting periodically
                    wait()
                end
                -- Unregister when loop ends
                if Stop then
                    unregisterEffect("RainbowGradient")
                end
            end)
        end,
        
        -- Primary to Secondary Gradient Effect (Animated)
        PrimarySecondaryGradient = function()
            runEffectWithLayering("PrimarySecondaryGradient", function()
                local time = 0
                while true do
                    if Stop then break end
                    local Wristbands = getWristbandsContainer()
                    time = time + GetColorSpeed()
                    for zoneID = 1, 10 do
                        if Stop then break end
                        local gradientPosition = ((zoneID - 1) / 9 + (time * 0.1)) % 1
                        local color = GetParameter("Primary"):Lerp(GetParameter("Secondary"), gradientPosition)
                        applyToZone(Wristbands, zoneID, color, 0, (GetParameter("Intensity") or 1), true)
                    end
                    updateHighlighting() -- Update highlighting periodically
                    wait()
                end
                -- Unregister when loop ends
                if Stop then
                    unregisterEffect("PrimarySecondaryGradient")
                end
            end)
        end,
        
        -- Animated Primary to Secondary Gradient Effect
        AnimatedGradient = function()
            runEffectWithLayering("AnimatedGradient", function()
                local time = 0
                while true do
                    if Stop then break end
                    local Wristbands = getWristbandsContainer()
                    time = time + GetColorSpeed()
                    for zoneID = 1, 10 do
                        if Stop then break end
                        local gradientPosition = ((zoneID - 1) / 9 + (time * 0.1)) % 1
                        local color = GetParameter("Primary"):Lerp(GetParameter("Secondary"), gradientPosition)
                        applyToZone(Wristbands, zoneID, color, 0, (GetParameter("Intensity") or 1), true)
                    end
                    updateHighlighting() -- Update highlighting periodically
                    wait()
                end
                -- Unregister when loop ends
                if Stop then
                    unregisterEffect("AnimatedGradient")
                end
            end)
        end,

        -- Multi-Color Gradient Effect
        MultiColorGradient = function()
            runEffectWithLayering("MultiColorGradient", function()
                local time = 0
                local colors = {
                    GetParameter("Primary"),
                    GetParameter("Secondary"),
                    Color3.fromRGB(255, 0, 255), -- Magenta
                    Color3.fromRGB(0, 255, 255), -- Cyan
                    Color3.fromRGB(255, 255, 0)  -- Yellow
                }
                while true do
                    if Stop then break end
                    local Wristbands = getWristbandsContainer()
                    time = time + GetColorSpeed()
                    for zoneID = 1, 10 do
                        if Stop then break end
                        local gradientPosition = ((zoneID - 1) / 9 + (time * 0.05)) % 1
                        local colorIndex = math.floor(gradientPosition * (#colors - 1)) + 1
                        local subPosition = (gradientPosition * (#colors - 1)) % 1
                        local color1 = colors[colorIndex]
                        local color2 = colors[colorIndex + 1] or colors[1]
                        local color = color1:Lerp(color2, subPosition)
                        applyToZone(Wristbands, zoneID, color, 0, (GetParameter("Intensity") or 1), true)
                    end
                    updateHighlighting() -- Update highlighting periodically
                    wait()
                end
                -- Unregister when loop ends
                if Stop then
                    unregisterEffect("MultiColorGradient")
                end
            end)
        end,

        -- Radial Gradient Effect
        RadialGradient = function()
            runEffectWithLayering("RadialGradient", function()
                local time = 0
                while true do
                    if Stop then break end
                    local Wristbands = getWristbandsContainer()
                    time = time + GetColorSpeed()
                    for zoneID = 1, 10 do
                        if Stop then break end
                        local centerZone = 5.5
                        local distance = math.abs(zoneID - centerZone) / 4.5
                        local radialPosition = (distance + time * 0.1) % 1
                        local color = GetParameter("Primary"):Lerp(GetParameter("Secondary"), radialPosition)
                        applyToZone(Wristbands, zoneID, color, 0, (GetParameter("Intensity") or 1), true)
                    end
                    updateHighlighting() -- Update highlighting periodically
                    wait()
                end
                -- Unregister when loop ends
                if Stop then
                    unregisterEffect("RadialGradient")
                end
            end)
        end,

        -- Pulse Gradient Effect
        PulseGradient = function()
            runEffectWithLayering("PulseGradient", function()
                local time = 0
                while true do
                    if Stop then break end
                    local Wristbands = getWristbandsContainer()
                    time = time + GetColorSpeed()
                    for zoneID = 1, 10 do
                        if Stop then break end
                        local pulse = math.sin(time + zoneID * 0.5) * 0.5 + 0.5
                        local gradientPosition = (zoneID - 1) / 9
                        local color = GetParameter("Primary"):Lerp(GetParameter("Secondary"), gradientPosition)
                        applyToZone(Wristbands, zoneID, color, 1 - pulse, pulse * (GetParameter("Intensity") or 1), true)
                    end
                    updateHighlighting() -- Update highlighting periodically
                    wait()
                end
                -- Unregister when loop ends
                if Stop then
                    unregisterEffect("PulseGradient")
                end
            end)
        end,

        -- Spiral Gradient Effect
        SpiralGradient = function()
            runEffectWithLayering("SpiralGradient", function()
                local time = 0
                while true do
                    if Stop then break end
                    local Wristbands = getWristbandsContainer()
                    time = time + GetColorSpeed()
                    for zoneID = 1, 10 do
                        if Stop then break end
                        local spiralPosition = ((zoneID - 1) / 9 + time * 0.2 + math.sin(time * 0.5) * 0.1) % 1
                        local color = GetParameter("Primary"):Lerp(GetParameter("Secondary"), spiralPosition)
                        applyToZone(Wristbands, zoneID, color, 0, (GetParameter("Intensity") or 1), true)
                    end
                    updateHighlighting() -- Update highlighting periodically
                    wait()
                end
                -- Unregister when loop ends
                if Stop then
                    unregisterEffect("SpiralGradient")
                end
            end)
        end,
        
        -- Alternate Effect (moved from Professional)
        Alternate = function(color1, color2, speed)
            runEffectWithLayering("Alternate", function()
                color1 = color1 or Color3.fromRGB(255,255,255)
                color2 = color2 or Color3.fromRGB(0,0,255)
                speed = speed or 0.5
                while true do
                    if Stop then break end
                    local Wristbands = getWristbandsContainer()
                    local brightness = getColorEffectBrightness()
                    for zone = 1, 10 do
                        if Stop then break end
                        if zone % 2 == 1 then
                            applyToZone(Wristbands, zone, color1, nil, brightness, true)
                        else
                            applyToZone(Wristbands, zone, color2, nil, brightness, true)
                        end
                    end
                    updateHighlighting() -- Update highlighting periodically
                    wait(speed)
                    if Stop then break end
                    local Wristbands = getWristbandsContainer()
                    for zone = 1, 10 do
                        if Stop then break end
                        if zone % 2 == 0 then
                            applyToZone(Wristbands, zone, color1, nil, brightness, true)
                        else
                            applyToZone(Wristbands, zone, color2, nil, brightness, true)
                        end
                    end
                    updateHighlighting() -- Update highlighting periodically
                    wait(speed)
                end
                -- Unregister when loop ends
                if Stop then
                    unregisterEffect("Alternate")
                end
            end)
        end,

        -- Fade Effect (moved from Professional)
        Fade = function(colors, speed)
            runEffectWithLayering("Fade", function()
                colors = colors or {Color3.fromRGB(255,0,0), Color3.fromRGB(0,255,0), Color3.fromRGB(0,0,255)}
                speed = speed or 0.1
                local currentColor = 1
                local fadeTime = 0
                while true do
                    if Stop then break end
                    fadeTime = fadeTime + speed
                    if fadeTime >= 1 then
                        fadeTime = 0
                        currentColor = currentColor % #colors + 1
                    end
                    local nextColor = currentColor % #colors + 1
                    local color1 = colors[currentColor]
                    local color2 = colors[nextColor]
                    local blendedColor = color1:Lerp(color2, fadeTime)
                    local Wristbands = getWristbandsContainer()
                    local brightness = getColorEffectBrightness()
                    for zone = 1, 10 do
                        if Stop then break end
                        applyToZone(Wristbands, zone, blendedColor, nil, brightness, true)
                    end
                    updateHighlighting() -- Update highlighting periodically
                    wait(0.016)
                end
                -- Unregister when loop ends
                if Stop then
                    unregisterEffect("Fade")
                end
            end)
        end,

        -- Random Effect (moved from Professional)
        Random = function(colors, speed)
            runEffectWithLayering("Random", function()
                colors = colors or {Color3.fromRGB(255,0,0), Color3.fromRGB(0,255,0), Color3.fromRGB(0,0,255), Color3.fromRGB(255,255,0), Color3.fromRGB(255,0,255), Color3.fromRGB(0,255,255)}
                speed = speed or 0.2
                while true do
                    if Stop then break end
                    local Wristbands = getWristbandsContainer()
                    local brightness = getColorEffectBrightness()
                    for zone = 1, 10 do
                        if Stop then break end
                        local randomColor = colors[math.random(1, #colors)]
                        applyToZone(Wristbands, zone, randomColor, nil, brightness, true)
                    end
                    updateHighlighting() -- Update highlighting periodically
                    wait(speed)
                end
                -- Unregister when loop ends
                if Stop then
                    unregisterEffect("Random")
                end
            end)
        end,
        






        -- Scan Effect (moved from MA_Effects to Color_Effects)
        Scan = function(color, speed)
            runEffectWithLayering("Scan", function()
                color = color or Color3.new(1,1,1)
                speed = speed or 0.1
                local position = 1
                while true do
                    if Stop then break end
                    local Wristbands = getWristbandsContainer()
                    local brightness = getColorEffectBrightness()
                    for zone = 1, 10 do
                        if Stop then break end
                        local distance = math.abs(zone - position)
                        local intensity = math.max(0, 1 - distance * 0.3)
                        applyToZone(Wristbands, zone, color, 1 - intensity, brightness, true)
                    end
                    position = position + speed
                    if position > 10 then
                        position = 1
                    end
                    wait(0.05)
                    updateHighlighting() -- Update highlighting periodically
                end
                -- Unregister when loop ends
                if Stop then
                    unregisterEffect("Scan")
                end
            end)
        end,


        

        
        -- ColorWave Effect (moved from Global)
        ColorWave = function(colors, speed)
            runEffectWithLayering("ColorWave", function()
                speed = speed or 0.1
                colors = colors or {Color3.fromRGB(255,0,0), Color3.fromRGB(0,255,0), Color3.fromRGB(0,0,255)}
                while true do
                    if Stop then break end
                    for offset = 1, #colors do
                        if Stop then break end
                        local Wristbands = getWristbandsContainer()
                        local brightness = getColorEffectBrightness()
                        for zone = 1, 10 do
                            if Stop then break end
                            local colorIndex = ((zone + offset - 2) % #colors) + 1
                            applyToZone(Wristbands, zone, colors[colorIndex], nil, brightness, true)
                        end
                        updateHighlighting() -- Update highlighting periodically
                        wait(speed)
                    end
                end
                -- Unregister when loop ends
                if Stop then
                    unregisterEffect("ColorWave")
                end
            end)
        end,

        -- Rainbow Effect (moved from Global)
        Rainbow = function(speed)
            runEffectWithLayering("Rainbow", function()
                speed = speed or 0.1
                while true do
                    if Stop then break end
                    for t = 0, 1, 0.1 do
                        if Stop then break end
                        local Wristbands = getWristbandsContainer()
                        local brightness = getColorEffectBrightness()
                        for zone = 1, 10 do
                            if Stop then break end
                            local hue = ((zone-1)/10 + t) % 1
                            local color = Color3.fromHSV(hue, 1, 1)
                            applyToZone(Wristbands, zone, color, nil, brightness, true)
                        end
                        updateHighlighting() -- Update highlighting periodically
                        wait(speed)
                    end
                end
                -- Unregister when loop ends
                if Stop then
                    unregisterEffect("Rainbow")
                end
            end)
        end,


    },

    -- ===== CUSTOM DIMMER EFFECTS =====
    -- Uncomment this section and add your custom dimmer effects here
    -- Custom dimmer effects should only control brightness/transparency, not colors
    -- Use applyToZone(Wristbands, zoneID, nil, transparency, brightness, false) for dimmer effects
    -- Example: applyToZone(Wristbands, zoneID, nil, 0.5, 1.5, false)
    -- 
    -- ["Custom_Dimmer"] = {
    --     -- Example Custom Dimmer Effect
    --     ["MyCustomDim"] = function()
    --         runEffectWithLayering("MyCustomDim", function()
    --             local time = 0
    --             while true do
    --                 if Stop then break end
    --                 time = time + 0.1
    --                 local Wristbands = getWristbandsContainer()
    --                 
    --                 for zoneID = 1, 10 do
    --                     if Stop then break end
    --                     -- Create a custom dimming pattern
    --                     local dimValue = math.sin(time + zoneID * 0.5) * 0.5 + 0.5
    --                     local brightness = dimValue * (GetParameter("Intensity") or 1)
    --                     
    --                     -- Apply dimmer effect (no color, only brightness/transparency)
    --                     applyToZone(Wristbands, zoneID, nil, 1 - dimValue, brightness, false)
    --                 end
    --                 
    --                 updateHighlighting() -- Update highlighting periodically
    --                 wait(0.016)
    --             end
    --             -- Unregister when loop ends
    --             if Stop then
    --                 unregisterEffect("MyCustomDim")
    --             end
    --         end)
    --     end,
    --     
    --     -- Add more custom dimmer effects here...
    --     -- ["AnotherCustomDim"] = function()
    --     --     -- Your custom dimmer effect code here
    --     -- end,
    -- },

    -- ===== CUSTOM COLOR EFFECTS =====
    -- Uncomment this section and add your custom color effects here
    -- Custom color effects should only control colors, brightness is handled by dimmer effects
    -- Use applyToZone(Wristbands, zoneID, color, nil, brightness, true) for color effects
    -- Use getColorEffectBrightness() to get appropriate brightness (respects active dimmer effects)
    -- Example: applyToZone(Wristbands, zoneID, Color3.fromRGB(255,0,0), nil, getColorEffectBrightness(), true)
    -- 
    -- ["Custom_ColorFX"] = {
    --     -- Example Custom Color Effect
    --     ["MyCustomColor"] = function()
    --         runEffectWithLayering("MyCustomColor", function()
    --             local time = 0
    --             while true do
    --                 if Stop then break end
    --                 time = time + 0.1
    --                 local Wristbands = getWristbandsContainer()
    --                 local brightness = getColorEffectBrightness() -- Respects active dimmer effects
    --                 
    --                 for zoneID = 1, 10 do
    --                     if Stop then break end
    --                     -- Create a custom color pattern
    --                     local hue = (time + zoneID * 0.1) % 1
    --                     local color = Color3.fromHSV(hue, 1, 1)
    --                     
    --                     -- Apply color effect (color + brightness, no transparency control)
    --                     applyToZone(Wristbands, zoneID, color, nil, brightness, true)
    --                 end
    --                 
    --                 updateHighlighting() -- Update highlighting periodically
    --                 wait(0.016)
    --             end
    --             -- Unregister when loop ends
    --             if Stop then
    --                 unregisterEffect("MyCustomColor")
    --             end
    --         end)
    --     end,
    --     
    --     -- Add more custom color effects here...
    --     -- ["AnotherCustomColor"] = function()
    --     --     -- Your custom color effect code here
    --     -- end,
    -- },

}

return Effects