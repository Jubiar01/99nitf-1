local AutoKill = {}

local Players = game:GetService("Players")
local RunService = game:GetService("RunService")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local LocalPlayer = Players.LocalPlayer

AutoKill.enabled = false
AutoKill.killConnection = nil
AutoKill.killDelay = 0.5
AutoKill.lastKillTime = 0
AutoKill.instantKillMode = true
AutoKill.selectedWeapon = "Old Axe"
AutoKill.killRange = 150
AutoKill.targetTypes = {
    ["Bunny"] = true,
    ["Rabbit"] = true,
    ["Hare"] = true
}
AutoKill.killStats = {
    totalKills = 0,
    sessionKills = 0,
    killsPerMinute = 0,
    startTime = tick()
}

function AutoKill.getWeapon()
    local inventory = LocalPlayer:FindFirstChild("Inventory")
    if not inventory then
        inventory = LocalPlayer:WaitForChild("Inventory", 2)
    end
    
    if inventory then
        local weapon = inventory:FindFirstChild(AutoKill.selectedWeapon)
        if weapon then
            return weapon
        end
        
        for _, item in pairs(inventory:GetChildren()) do
            if item.Name:find("Axe") or item.Name:find("Sword") or item.Name:find("Weapon") then
                AutoKill.selectedWeapon = item.Name
                return item
            end
        end
    end
    
    local character = LocalPlayer.Character
    if character then
        for _, item in pairs(character:GetChildren()) do
            if item:IsA("Tool") and (item.Name:find("Axe") or item.Name:find("Sword")) then
                AutoKill.selectedWeapon = item.Name
                return item
            end
        end
    end
    
    return nil
end

function AutoKill.getAllTargets()
    local targets = {}
    local workspace = game:GetService("Workspace")
    
    local charactersFolder = workspace:FindFirstChild("Characters")
    if charactersFolder then
        for _, character in pairs(charactersFolder:GetChildren()) do
            for targetName, _ in pairs(AutoKill.targetTypes) do
                if character.Name == targetName or character.Name:find(targetName) then
                    if character:FindFirstChild("Humanoid") or character:FindFirstChild("Health") or character:FindFirstChildWhichIsA("BasePart") then
                        table.insert(targets, character)
                    end
                end
            end
        end
    end
    
    local npcsFolder = workspace:FindFirstChild("NPCs")
    if npcsFolder then
        for _, npc in pairs(npcsFolder:GetChildren()) do
            for targetName, _ in pairs(AutoKill.targetTypes) do
                if npc.Name == targetName or npc.Name:find(targetName) then
                    if npc:FindFirstChild("Humanoid") or npc:FindFirstChild("Health") or npc:FindFirstChildWhichIsA("BasePart") then
                        table.insert(targets, npc)
                    end
                end
            end
        end
    end
    
    for _, obj in pairs(workspace:GetChildren()) do
        if obj:IsA("Model") then
            for targetName, _ in pairs(AutoKill.targetTypes) do
                if obj.Name == targetName or obj.Name:find(targetName) then
                    if obj:FindFirstChild("Humanoid") or obj:FindFirstChild("Health") or obj:FindFirstChildWhichIsA("BasePart") then
                        local isInList = false
                        for _, existing in pairs(targets) do
                            if existing == obj then
                                isInList = true
                                break
                            end
                        end
                        if not isInList then
                            table.insert(targets, obj)
                        end
                    end
                end
            end
        end
    end
    
    return targets
end

function AutoKill.getTargetPosition(target)
    if target:FindFirstChild("HumanoidRootPart") then
        return target.HumanoidRootPart.Position
    elseif target:FindFirstChild("Torso") then
        return target.Torso.Position
    elseif target:FindFirstChildWhichIsA("BasePart") then
        return target:FindFirstChildWhichIsA("BasePart").Position
    end
    return nil
end

function AutoKill.getDistance(pos1, pos2)
    if pos1 and pos2 then
        return (pos1 - pos2).Magnitude
    end
    return math.huge
end

function AutoKill.generateAttackCFrame(targetPosition)
    local playerPos = LocalPlayer.Character and LocalPlayer.Character:FindFirstChild("HumanoidRootPart")
    if playerPos then
        playerPos = playerPos.Position
    else
        playerPos = Vector3.new(0, 5, 0)
    end
    
    local direction = (targetPosition - playerPos).Unit
    
    return CFrame.lookAt(playerPos, targetPosition) * CFrame.Angles(
        math.rad(math.random(-5, 5)),
        math.rad(math.random(-5, 5)),
        0
    )
end

function AutoKill.attackTarget(target)
    local weapon = AutoKill.getWeapon()
    if not weapon or not target or not target.Parent then
        return false
    end
    
    local targetPos = AutoKill.getTargetPosition(target)
    if not targetPos then
        return false
    end
    
    local playerPos = LocalPlayer.Character and LocalPlayer.Character:FindFirstChild("HumanoidRootPart")
    if playerPos then
        playerPos = playerPos.Position
        local distance = AutoKill.getDistance(playerPos, targetPos)
        if distance > AutoKill.killRange then
            return false
        end
    end
    
    local success = pcall(function()
        local remoteEvents = ReplicatedStorage:FindFirstChild("RemoteEvents")
        if not remoteEvents then
            remoteEvents = ReplicatedStorage:WaitForChild("RemoteEvents", 2)
        end
        
        local damageRemote = remoteEvents and remoteEvents:FindFirstChild("ToolDamageObject")
        if not damageRemote then
            damageRemote = remoteEvents and remoteEvents:FindFirstChild("DamageObject") or
                          remoteEvents and remoteEvents:FindFirstChild("Attack") or
                          remoteEvents and remoteEvents:FindFirstChild("Hit")
        end
        
        if damageRemote then
            local attackId = tostring(math.random(10, 99)) .. "_" .. tostring(tick() * 1000)
            local attackCFrame = AutoKill.generateAttackCFrame(targetPos)
            
            local args = {
                target,
                weapon,
                attackId,
                attackCFrame
            }
            
            if damageRemote:IsA("RemoteFunction") then
                damageRemote:InvokeServer(unpack(args))
            elseif damageRemote:IsA("RemoteEvent") then
                damageRemote:FireServer(unpack(args))
            end
            
            AutoKill.killStats.sessionKills = AutoKill.killStats.sessionKills + 1
            AutoKill.killStats.totalKills = AutoKill.killStats.totalKills + 1
            
            wait(0.02)
            
            if AutoKill.instantKillMode then
                for i = 1, 3 do
                    if target and target.Parent then
                        local newArgs = {
                            target,
                            weapon,
                            tostring(math.random(10, 99)) .. "_" .. tostring(tick() * 1000),
                            AutoKill.generateAttackCFrame(targetPos)
                        }
                        
                        if damageRemote:IsA("RemoteFunction") then
                            damageRemote:InvokeServer(unpack(newArgs))
                        else
                            damageRemote:FireServer(unpack(newArgs))
                        end
                    end
                    wait(0.01)
                end
            end
        end
    end)
    
    return success
end

function AutoKill.killLoop()
    if not AutoKill.enabled then return end
    
    local currentTime = tick()
    if currentTime - AutoKill.lastKillTime < AutoKill.killDelay then
        return
    end
    
    local targets = AutoKill.getAllTargets()
    
    if #targets > 0 then
        if AutoKill.instantKillMode then
            for _, target in pairs(targets) do
                if target and target.Parent then
                    spawn(function()
                        AutoKill.attackTarget(target)
                    end)
                    wait(0.05)
                end
            end
        else
            for i = 1, math.min(#targets, 3) do
                local target = targets[i]
                if target and target.Parent then
                    AutoKill.attackTarget(target)
                    wait(0.1)
                end
            end
        end
        
        AutoKill.lastKillTime = currentTime
    end
    
    local elapsedMinutes = (currentTime - AutoKill.killStats.startTime) / 60
    if elapsedMinutes > 0 then
        AutoKill.killStats.killsPerMinute = math.floor(AutoKill.killStats.sessionKills / elapsedMinutes)
    end
end

function AutoKill.setEnabled(enabled)
    AutoKill.enabled = enabled
    
    if enabled then
        AutoKill.killStats.startTime = tick()
        AutoKill.killStats.sessionKills = 0
        
        if AutoKill.killConnection then
            AutoKill.killConnection:Disconnect()
        end
        AutoKill.killConnection = RunService.Heartbeat:Connect(AutoKill.killLoop)
    else
        if AutoKill.killConnection then
            AutoKill.killConnection:Disconnect()
            AutoKill.killConnection = nil
        end
    end
end

function AutoKill.setKillDelay(delay)
    AutoKill.killDelay = delay
end

function AutoKill.setInstantMode(enabled)
    AutoKill.instantKillMode = enabled
end

function AutoKill.setWeapon(weaponName)
    AutoKill.selectedWeapon = weaponName
end

function AutoKill.setKillRange(range)
    AutoKill.killRange = range
end

function AutoKill.addTargetType(targetName)
    AutoKill.targetTypes[targetName] = true
end

function AutoKill.removeTargetType(targetName)
    AutoKill.targetTypes[targetName] = nil
end

function AutoKill.getStatus()
    if AutoKill.enabled then
        local targets = AutoKill.getAllTargets()
        local weapon = AutoKill.getWeapon()
        local weaponStatus = weapon and weapon.Name or "No weapon"
        
        if #targets > 0 then
            local mode = AutoKill.instantKillMode and "INSTANT" or "Normal"
            return string.format("[%s] Hunting %d targets | Weapon: %s | Kills: %d (%.1f/min)", 
                   mode, #targets, weaponStatus, AutoKill.killStats.sessionKills, AutoKill.killStats.killsPerMinute)
        else
            return string.format("Searching for targets... | Weapon: %s | Session Kills: %d", 
                   weaponStatus, AutoKill.killStats.sessionKills)
        end
    else
        return "Auto Kill disabled | Total Kills: " .. AutoKill.killStats.totalKills
    end
end

function AutoKill.teleportToTarget()
    local targets = AutoKill.getAllTargets()
    if #targets > 0 and LocalPlayer.Character and LocalPlayer.Character:FindFirstChild("HumanoidRootPart") then
        local targetPos = AutoKill.getTargetPosition(targets[1])
        if targetPos then
            LocalPlayer.Character.HumanoidRootPart.CFrame = CFrame.new(targetPos + Vector3.new(5, 5, 5))
        end
    end
end

return AutoKill
