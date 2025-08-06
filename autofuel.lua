local AutoFuel = {}

local Players = game:GetService("Players")
local RunService = game:GetService("RunService")
local LocalPlayer = Players.LocalPlayer

AutoFuel.autoFuelEnabled = false
AutoFuel.fuelDelay = 0.5
AutoFuel.fuelConnection = nil
AutoFuel.lastFuelTime = 0
AutoFuel.initAttempts = 0
AutoFuel.maxInitAttempts = 10
AutoFuel.instantDrop = true

function AutoFuel.getPlayerPosition()
    if LocalPlayer.Character and LocalPlayer.Character:FindFirstChild("HumanoidRootPart") then
        return LocalPlayer.Character.HumanoidRootPart.Position
    end
    return nil
end

function AutoFuel.getDistance(pos1, pos2)
    return (pos1 - pos2).Magnitude
end

function AutoFuel.getMainFire()
    local workspace = game:GetService("Workspace")
    local map = workspace:FindFirstChild("Map")
    if not map then
        map = workspace:WaitForChild("Map", 5)
    end
    if not map then return nil, nil end
    
    local campground = map:FindFirstChild("Campground")
    if not campground then
        campground = map:WaitForChild("Campground", 5)
    end
    if not campground then return nil, nil end
    
    local mainFire = campground:FindFirstChild("MainFire")
    if not mainFire then
        mainFire = campground:WaitForChild("MainFire", 5)
    end
    
    return mainFire, mainFire
end

function AutoFuel.findLogItems()
    local workspace = game:GetService("Workspace")
    local fuelItems = {}
    
    local function searchInObject(parent)
        if not parent then return end
        
        for _, item in pairs(parent:GetChildren()) do
            if item:IsA("Model") or item:IsA("Tool") then
                if item.Name == "Log" or item.Name == "Wood" or string.find(item.Name:lower(), "log") then
                    local hasValidPart = item:FindFirstChild("Handle") or 
                                        item:FindFirstChild("Meshes/log_Cylinder") or
                                        item:FindFirstChildWhichIsA("BasePart") or
                                        item:FindFirstChildWhichIsA("MeshPart")
                    if hasValidPart then
                        table.insert(fuelItems, item)
                    end
                elseif item.Name == "Coal" then
                    local hasValidPart = item:FindFirstChild("Coal") or 
                                        item:FindFirstChild("Handle") or
                                        item:FindFirstChildWhichIsA("BasePart")
                    if hasValidPart then
                        table.insert(fuelItems, item)
                    end
                elseif item.Name == "Fuel Canister" or item.Name == "FuelCanister" then
                    local hasValidPart = item:FindFirstChild("Handle") or 
                                        item:FindFirstChildWhichIsA("BasePart")
                    if hasValidPart then
                        table.insert(fuelItems, item)
                    end
                end
            end
            
            if item:IsA("Folder") and (item.Name == "Items" or item.Name == "Drops" or item.Name == "DroppedItems" or item.Name == "Storage") then
                searchInObject(item)
            end
        end
    end
    
    searchInObject(workspace)
    
    local itemsFolder = workspace:FindFirstChild("Items")
    if itemsFolder then
        searchInObject(itemsFolder)
    end
    
    local dropsFolder = workspace:FindFirstChild("Drops")
    if dropsFolder then
        searchInObject(dropsFolder)
    end
    
    for _, player in pairs(Players:GetPlayers()) do
        if player.Character then
            local backpack = player:FindFirstChild("Backpack")
            if backpack then
                searchInObject(backpack)
            end
            searchInObject(player.Character)
        end
    end
    
    return fuelItems
end

function AutoFuel.initializeFire()
    local mainFire = AutoFuel.getMainFire()
    if not mainFire then
        return false
    end
    
    local success = pcall(function()
        local firePosition = mainFire:GetBoundingBox().Position
        
        local fireProximity = mainFire:FindFirstChildWhichIsA("ProximityPrompt")
        if fireProximity then
            local oldDist = fireProximity.MaxActivationDistance
            fireProximity.MaxActivationDistance = 100
            wait(0.05)
            fireProximity.MaxActivationDistance = oldDist or 10
        end
        
        local fireClickDetector = mainFire:FindFirstChildWhichIsA("ClickDetector")
        if fireClickDetector then
            local oldDist = fireClickDetector.MaxActivationDistance
            fireClickDetector.MaxActivationDistance = 100
            wait(0.05)
            fireClickDetector.MaxActivationDistance = oldDist or 32
        end
    end)
    
    return success
end

function AutoFuel.instantDropToFire(fuelItem)
    local mainFire = AutoFuel.getMainFire()
    if not mainFire or not fuelItem or not fuelItem.Parent then
        return false
    end
    
    local success = pcall(function()
        local fuelHandle = nil
        
        if fuelItem.Name == "Log" or string.find(fuelItem.Name:lower(), "log") or fuelItem.Name == "Wood" then
            fuelHandle = fuelItem:FindFirstChild("Handle") or 
                        fuelItem:FindFirstChild("Meshes/log_Cylinder") or
                        fuelItem:FindFirstChildWhichIsA("MeshPart") or
                        fuelItem:FindFirstChildWhichIsA("BasePart")
        elseif fuelItem.Name == "Coal" then
            fuelHandle = fuelItem:FindFirstChild("Coal") or 
                        fuelItem:FindFirstChild("Handle") or
                        fuelItem:FindFirstChildWhichIsA("BasePart")
        else
            fuelHandle = fuelItem:FindFirstChild("Handle") or 
                        fuelItem:FindFirstChildWhichIsA("BasePart") or
                        fuelItem:FindFirstChildWhichIsA("MeshPart")
        end
        
        if fuelHandle then
            local fireBox = mainFire:GetBoundingBox()
            local firePosition = fireBox.Position
            
            for _, obj in pairs(fuelHandle:GetDescendants()) do
                if obj:IsA("BodyVelocity") or obj:IsA("BodyPosition") or 
                   obj:IsA("BodyAngularVelocity") or obj:IsA("BodyGyro") then
                    obj:Destroy()
                end
            end
            
            if fuelHandle:IsA("BasePart") then
                fuelHandle.CanCollide = false
                fuelHandle.Anchored = false
            end
            
            fuelHandle.CFrame = CFrame.new(
                firePosition.X + math.random(-10, 10) * 0.05,
                firePosition.Y + 3,
                firePosition.Z + math.random(-10, 10) * 0.05
            )
            
            fuelHandle.Velocity = Vector3.new(0, -20, 0)
            fuelHandle.RotVelocity = Vector3.new(0, 0, 0)
            
            wait(0.05)
            
            fuelHandle.CFrame = CFrame.new(
                firePosition.X,
                firePosition.Y + 0.5,
                firePosition.Z
            )
            
            fuelHandle.Velocity = Vector3.new(0, -5, 0)
            
            if fuelItem:IsA("Tool") then
                fuelItem.Parent = workspace
            end
            
            wait(0.02)
            
            if fuelHandle and fuelHandle.Parent then
                fuelHandle.CFrame = CFrame.new(firePosition)
                fuelHandle.Velocity = Vector3.new(0, 0, 0)
                fuelHandle.RotVelocity = Vector3.new(0, 0, 0)
            end
        end
    end)
    
    return success
end

function AutoFuel.moveItemToMainFire(fuelItem)
    if AutoFuel.instantDrop then
        return AutoFuel.instantDropToFire(fuelItem)
    end
    
    local mainFire, _ = AutoFuel.getMainFire()
    if not mainFire or not fuelItem or not fuelItem.Parent then
        return false
    end
    
    local success = pcall(function()
        local fuelHandle = nil
        
        if fuelItem.Name == "Log" or string.find(fuelItem.Name:lower(), "log") then
            fuelHandle = fuelItem:FindFirstChild("Handle") or 
                        fuelItem:FindFirstChild("Meshes/log_Cylinder") or
                        fuelItem:FindFirstChildWhichIsA("BasePart")
        elseif fuelItem.Name == "Coal" then
            fuelHandle = fuelItem:FindFirstChild("Coal") or 
                        fuelItem:FindFirstChild("Handle") or
                        fuelItem:FindFirstChildWhichIsA("BasePart")
        elseif fuelItem.Name == "Fuel Canister" then
            fuelHandle = fuelItem:FindFirstChild("Handle") or 
                        fuelItem:FindFirstChildWhichIsA("BasePart")
        end
        
        if not fuelHandle then
            fuelHandle = fuelItem:FindFirstChildWhichIsA("BasePart") or 
                        fuelItem:FindFirstChildWhichIsA("MeshPart")
        end
        
        if fuelHandle then
            local fireBox = mainFire:GetBoundingBox()
            local targetPosition = fireBox.Position
            
            fuelHandle.CFrame = CFrame.new(targetPosition + Vector3.new(
                math.random(-2, 2) * 0.1,
                math.random(8, 12),
                math.random(-2, 2) * 0.1
            ))
            
            for _, obj in pairs(fuelHandle:GetChildren()) do
                if obj:IsA("BodyVelocity") or obj:IsA("BodyPosition") or obj:IsA("BodyAngularVelocity") then
                    obj:Destroy()
                end
            end
            
            fuelHandle.Velocity = Vector3.new(0, -15, 0)
            fuelHandle.RotVelocity = Vector3.new(
                math.random(-3, 3),
                math.random(-3, 3),
                math.random(-3, 3)
            )
            
            if fuelItem:IsA("Tool") then
                fuelItem.Parent = workspace
            end
        end
    end)
    
    return success
end

function AutoFuel.autoFuelLoop()
    if not AutoFuel.autoFuelEnabled then return end
    
    local currentTime = tick()
    if currentTime - AutoFuel.lastFuelTime < AutoFuel.fuelDelay then
        return
    end
    
    local mainFire = AutoFuel.getMainFire()
    if not mainFire and AutoFuel.initAttempts < AutoFuel.maxInitAttempts then
        AutoFuel.initializeFire()
        AutoFuel.initAttempts = AutoFuel.initAttempts + 1
        wait(0.2)
        return
    end
    
    local fuelItems = AutoFuel.findLogItems()
    
    if #fuelItems > 0 then
        local itemsToFuel = math.min(#fuelItems, 5)
        for i = 1, itemsToFuel do
            local fuelItem = fuelItems[i]
            if fuelItem and fuelItem.Parent then
                local moved = AutoFuel.moveItemToMainFire(fuelItem)
                if moved then
                    wait(0.08)
                end
            end
        end
        AutoFuel.lastFuelTime = currentTime
    else
        if AutoFuel.initAttempts < AutoFuel.maxInitAttempts and AutoFuel.initAttempts % 3 == 0 then
            AutoFuel.initializeFire()
            AutoFuel.initAttempts = AutoFuel.initAttempts + 1
        end
    end
end

function AutoFuel.setEnabled(enabled)
    AutoFuel.autoFuelEnabled = enabled
    AutoFuel.initAttempts = 0
    
    if enabled then
        AutoFuel.initializeFire()
        wait(0.2)
        
        if AutoFuel.fuelConnection then
            AutoFuel.fuelConnection:Disconnect()
        end
        AutoFuel.fuelConnection = RunService.Heartbeat:Connect(AutoFuel.autoFuelLoop)
    else
        if AutoFuel.fuelConnection then
            AutoFuel.fuelConnection:Disconnect()
            AutoFuel.fuelConnection = nil
        end
    end
end

function AutoFuel.setFuelDelay(delay)
    AutoFuel.fuelDelay = delay
end

function AutoFuel.setInstantDrop(enabled)
    AutoFuel.instantDrop = enabled
end

function AutoFuel.getStatus()
    if AutoFuel.autoFuelEnabled then
        local fuelItems = AutoFuel.findLogItems()
        local mainFire, _ = AutoFuel.getMainFire()
        
        if not mainFire then
            return "Status: Initializing MainFire... (" .. AutoFuel.initAttempts .. "/" .. AutoFuel.maxInitAttempts .. ")", 0
        elseif #fuelItems > 0 then
            local playerPos = AutoFuel.getPlayerPosition()
            local mainFireCFrame = mainFire:GetBoundingBox()
            local mainFirePos = mainFireCFrame.Position
            local distance = playerPos and AutoFuel.getDistance(playerPos, mainFirePos) or 0
            
            local logCount = 0
            local coalCount = 0
            local canisterCount = 0
            
            for _, item in pairs(fuelItems) do
                if item.Name == "Log" or string.find(item.Name:lower(), "log") or item.Name == "Wood" then
                    logCount = logCount + 1
                elseif item.Name == "Coal" then
                    coalCount = coalCount + 1
                elseif item.Name == "Fuel Canister" then
                    canisterCount = canisterCount + 1
                end
            end
            
            local dropMode = AutoFuel.instantDrop and "INSTANT" or "Normal"
            return string.format("Status: [%s] Logs:%d Coal:%d Cans:%d - Delay:%.1fs", 
                   dropMode, logCount, coalCount, canisterCount, AutoFuel.fuelDelay), distance
        else
            return "Status: Searching for fuel items...", 0
        end
    else
        return "Status: Auto fuel disabled", 0
    end
end

function AutoFuel.forceRefresh()
    if AutoFuel.autoFuelEnabled then
        AutoFuel.initAttempts = 0
        AutoFuel.initializeFire()
    end
end

return AutoFuel
