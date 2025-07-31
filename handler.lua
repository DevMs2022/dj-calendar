local Settings = require(script.Parent.Parent.Settings)
local Grid = script.Parent.Parent.Panel.SurfaceGui.Main.Grid
local Collum = script.Collum
local LayoutIndexvalue = 0
local Button = script.Button

-- Stop all effects in all engines (for right-click only)
local function StopAllEngines()
    local EffectEnginesFolder = script.Parent:FindFirstChild("EffectEngines")
    if not EffectEnginesFolder then return end
    for _, module in pairs(EffectEnginesFolder:GetChildren()) do
        local success, Engine = pcall(require, module)
        if success and Engine and Engine.System and Engine.System.Stop then
            pcall(Engine.System.Stop)
        end
    end
end

local function HighlightActiveEffects()
    -- Try to find the engine module - check multiple possible locations and names
    local EngineModule = script.Parent.EffectEngines:FindFirstChild("MA_Style_EffectEngine")
    if not EngineModule then
        EngineModule = script.Parent.EffectEngines:FindFirstChild("MA Style Effect Engine")
    end
    if not EngineModule then
        EngineModule = script.Parent:FindFirstChild("MA_Style_EffectEngine")
    end
    if not EngineModule then
        EngineModule = script.Parent:FindFirstChild("MA Style Effect Engine")
    end
    if not EngineModule then
        EngineModule = script.Parent.Parent:FindFirstChild("MA_Style_EffectEngine")
    end
    if not EngineModule then
        EngineModule = script.Parent.Parent:FindFirstChild("MA Style Effect Engine")
    end
    
    if not EngineModule then 
        return 
    end
    
    local Engine = require(EngineModule)
    local active = Engine.System.GetActiveEffects()
    local dimmer = active.DimmerEffect
    local color = active.ColorEffect

    for _, collum in ipairs(Grid:GetChildren()) do
        for _, trigger in ipairs(collum:GetChildren()) do
            if trigger:IsA("Frame") then
                local buttonItem = trigger.Button
                if buttonItem:IsA("TextButton") then
                    local functionName = buttonItem.Parent.Name
                    local categoryName = buttonItem.Parent.Parent.Name
                    
                    -- Check if this button represents an active effect
                    local isActive = false
                    
                    -- Check if it's the active dimmer effect
                    if dimmer and functionName == dimmer then
                        isActive = true
                    end
                    
                    -- Check if it's the active color effect
                    if color and functionName == color then
                        isActive = true
                    end
                    
                    if isActive then
                        trigger.BackgroundColor3 = Color3.fromRGB(255, 200, 40) -- Highlight color
                    else
                        trigger.BackgroundColor3 = Color3.fromRGB(40, 39, 39) -- Default
                    end
                end
            end
        end
    end
end

-- Set up the highlighting function reference in the engine
local function setupHighlighting()
    local EngineModule = script.Parent.EffectEngines:FindFirstChild("MA_Style_EffectEngine")
    if not EngineModule then
        EngineModule = script.Parent.EffectEngines:FindFirstChild("MA Style Effect Engine")
    end
    if EngineModule then
        local Engine = require(EngineModule)
        Engine.System.SetHighlightFunction(HighlightActiveEffects)
    end
end

-- Call setup when the script starts
setupHighlighting()

local Canrun = true
local lastClickTime = 0

-- Function to force reset the handler state (for debugging)
local function forceResetHandler()
    Canrun = true
    StopAllEngines()
end
local function UpdateButtons()
    for _, collum in ipairs(Grid:GetChildren()) do
        spawn(function()
            for _, trigger in ipairs(collum:GetChildren()) do
                spawn(function()
                    if trigger:IsA("Frame") then
                        local buttonItem = trigger.Button
                        if buttonItem:IsA("TextButton") then
                            buttonItem.MouseButton1Click:Connect(function()
                                -- Force reset Canrun if it's been stuck for too long
                                if not Canrun then
                                    Canrun = true
                                end
                                
                                if Canrun then
                                    Canrun = false
                                    
                                    local success, error = pcall(function()
                                        local collumName = buttonItem.Parent.Parent.Name
                                        local functionName = buttonItem.Parent.Name
                                        local EngineLocation = buttonItem.Parent.Parent.Header.Type:getAttribute("Module")
                                        
                                        local Engine = require(script.Parent.EffectEngines:FindFirstChild(EngineLocation))
                                        Engine[collumName][functionName]()
                                        
                                        if collumName ~= "Presets" then
                                            HighlightActiveEffects()
                                        end
                                    end)
                                    
                                    if not success then
                                        warn("Error running effect:", error)
                                    end
                                    
                                    -- Reset Canrun after effect starts
                                    task.wait(0.1)
                                    Canrun = true
                                    
                                    -- Safety: ensure Canrun is reset even if there are issues
                                    spawn(function()
                                        task.wait(0.5)
                                        if not Canrun then
                                            Canrun = true
                                        end
                                    end)
                                end
                            end)
                            buttonItem.MouseButton2Click:Connect(function()
                                StopAllEngines()
                                HighlightActiveEffects()
                            end)
                        end
                    end	
                end)
            end
        end)
    end
end

local function getOrderTable(tbl)
    local orderTable = {}
    for key, _ in pairs(tbl) do
        table.insert(orderTable, key)
    end
    table.sort(orderTable)
    return orderTable
end

for i,module in pairs(script.Parent.EffectEngines:GetChildren())do
    local Engine = require(module)

    -- Get categories using the same approach as buttons
    local functionNamesOrder = getOrderTable(Engine)

    -- Reverse the order (same as buttons)
    for i = 1, math.floor(#functionNamesOrder / 2) do
        local temp = functionNamesOrder[i]
        functionNamesOrder[i] = functionNamesOrder[#functionNamesOrder - i + 1]
        functionNamesOrder[#functionNamesOrder - i + 1] = temp
    end
    
    -- Define the desired order: System, Presets, Zone_Flash, MA_Effects, Color_Effects
    local desiredOrder = {"System", "Presets", "Zone_Flash", "MA_Effects", "Color_Effects"}
    
    -- Create new ordered list
    local orderedCategories = {}
    
    -- Add categories in desired order
    for _, desiredCategory in ipairs(desiredOrder) do
        for i, category in ipairs(functionNamesOrder) do
            if category == desiredCategory then
                table.insert(orderedCategories, category)
                break
            end
        end
    end
    
    -- Add any remaining categories that weren't in the desired order
    for _, category in ipairs(functionNamesOrder) do
        local found = false
        for _, orderedCategory in ipairs(orderedCategories) do
            if category == orderedCategory then
                found = true
                break
            end
        end
        if not found then
            table.insert(orderedCategories, category)
        end
    end
    
    functionNamesOrder = orderedCategories

    for _, functionName in ipairs(functionNamesOrder) do
        task.wait(0.1)

        if functionName ~= "Internal" then
            task.wait()

            local NewCollum = Collum:Clone()
            NewCollum.Header.Title.Text = functionName
            NewCollum.Header.Type.Text =` Module: {Engine["Internal"]["getModuleName"]()}`
            NewCollum.Header.Type:SetAttribute("Module",Engine["Internal"]["getModuleName"]())
            NewCollum.Name = functionName
            LayoutIndexvalue += 1
            NewCollum.LayoutOrder = LayoutIndexvalue

            local success, result = pcall(function()
                NewCollum.Header.BackgroundColor3 = Settings.TabColors[LayoutIndexvalue]
            end)

            if not success then
                warn("Error setting background color:", result)
                NewCollum.Header.BackgroundColor3 = Color3.new(1, 1, 1)
            end

            local functionOrder = getOrderTable(Engine[functionName])
            local LayoutIndexvalue2 = 0

            for func, index in pairs(functionOrder) do
                -- Hide parameter setters and GetAllParameters
                if not (string.sub(index, 1, 3) == "Set" or index == "GetAllParameters") then
                    task.wait()
                    LayoutIndexvalue2 = LayoutIndexvalue2 + 1
                    local NewButton = Button:Clone()
                    NewButton.Button.Text = index
                    NewButton.Parent = NewCollum
                    NewButton.Name = index
                    NewButton.LayoutOrder = #functionOrder - func
                end
            end

            NewCollum.Parent = Grid
            UpdateButtons()
        end
    end
end

-- Make the reset function globally accessible for debugging
_G.ResetEffectHandler = forceResetHandler 