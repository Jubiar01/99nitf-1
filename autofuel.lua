local AutoFuel = {}

local Players = game:GetService("Players")
local RunService = game:GetService("RunService")
local LocalPlayer = Players.LocalPlayer

AutoFuel.autoFuelEnabled = false
AutoFuel.fuelDelay = 1
AutoFuel.fuelConnection = nil
AutoFuel.lastFuelTime = 0
AutoFuel.initAttempts = 0
AutoFuel.maxInitAttempts = 10

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
                if item.Name == "Log" then
                    local hasValidPart = item:FindFirstChild("Handle") or 
                                        item:FindFirstChild("Meshes/log_Cylinder") or
                                        item:FindFirstChildWhichIsA("BasePart")
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
                elseif item.Name == "Fuel Canister" then
                    local hasValidPart = item:FindFirstChild("Handle") or 
                                        item:FindFirstChildWhichIsA("BasePart")
                    if hasValidPart then
                        table.insert(fuelItems, item)
                    end
                end
            end
            
            if item:IsA("Folder") and (item.Name == "Items" or item.Name == "Drops" or item.Name == "DroppedItems") then
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
        
        local function createInitialSpark()
            local sparkPart = Instance.new("Part")
            sparkPart.Name = "InitSpark"
            sparkPart.Size = Vector3.new(0.5, 0.5, 0.5)
            sparkPart.Position = firePosition + Vector3.new(0, 10, 0)
            sparkPart.Transparency = 1
            sparkPart.CanCollide = false
            sparkPart.Parent = workspace
            
            wait(0.1)
            sparkPart.Position = firePosition + Vector3.new(0, 5, 0)
            wait(0.1)
            sparkPart:Destroy()
        end
        
        createInitialSpark()
        
        local fireProximity = mainFire:FindFirstChildWhichIsA("ProximityPrompt")
        if fireProximity then
            fireProximity.MaxActivationDistance = 50
            wait(0.1)
            fireProximity.MaxActivationDistance = 10
        end
    end)
    
    return success
end

function AutoFuel.moveItemToMainFire(fuelItem)
    local mainFire, _ = AutoFuel.getMainFire()
    if not mainFire or not fuelItem or not fuelItem.Parent then
        return false
    end
    
    local success = pcall(function()
        local fuelHandle = nil
        
        if fuelItem.Name == "Log" then
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
            local targetPosition = Vector3.new(0, 4, -3)
            
            fuelHandle.CFrame = CFrame.new(targetPosition + Vector3.new(
                math.random(-2, 2) * 0.1,
                math.random(15, 25),
                math.random(-2, 2) * 0.1
            ))
            
            for _, obj in pairs(fuelHandle:GetChildren()) do
                if obj:IsA("BodyVelocity") or obj:IsA("BodyPosition") or obj:IsA("BodyAngularVelocity") then
                    obj:Destroy()
                end
            end
            
            fuelHandle.Velocity = Vector3.new(0, -10, 0)
            fuelHandle.RotVelocity = Vector3.new(
                math.random(-5, 5),
                math.random(-5, 5),
                math.random(-5, 5)
            )
            
            if fuelHandle:FindFirstChild("AssemblyLinearVelocity") then
                fuelHandle.AssemblyLinearVelocity = Vector3.new(0, -10, 0)
            end
            if fuelHandle:FindFirstChild("AssemblyAngularVelocity") then
                fuelHandle.AssemblyAngularVelocity = Vector3.new(
                    math.random(-5, 5),
                    math.random(-5, 5),
                    math.random(-5, 5)
                )
            end
            
            if fuelItem:IsA("Tool") then
                fuelItem.Parent = workspace
            end
            
            wait(0.05)
            
            fuelHandle.CFrame = CFrame.new(targetPosition + Vector3.new(
                math.random(-1, 1) * 0.1,
                2,
                math.random(-1, 1) * 0.1
            ))
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
        wait(0.5)
        return
    end
    
    local fuelItems = AutoFuel.findLogItems()
    
    if #fuelItems > 0 then
        local itemsToFuel = math.min(#fuelItems, 3)
        for i = 1, itemsToFuel do
            local fuelItem = fuelItems[i]
            if fuelItem and fuelItem.Parent then
                local moved = AutoFuel.moveItemToMainFire(fuelItem)
                if moved then
                    wait(0.15)
                end
            end
        end
        AutoFuel.lastFuelTime = currentTime
    else
        if AutoFuel.initAttempts < AutoFuel.maxInitAttempts then
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
        wait(0.5)
        
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
                if item.Name == "Log" then
                    logCount = logCount + 1
                elseif item.Name == "Coal" then
                    coalCount = coalCount + 1
                elseif item.Name == "Fuel Canister" then
                    canisterCount = canisterCount + 1
                end
            end
            
            return string.format("Status: Active - Logs:%d Coal:%d Cans:%d @ (0,4,-3) - Delay:%.1fs", 
                   logCount, coalCount, canisterCount, AutoFuel.fuelDelay), distance
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
