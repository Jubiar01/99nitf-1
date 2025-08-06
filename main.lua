local TreeChopper = loadstring(game:HttpGet('https://raw.githubusercontent.com/Levitzy/99nitf/refs/heads/main/tree.lua'))()
local AutoFuel = loadstring(game:HttpGet('https://raw.githubusercontent.com/Levitzy/99nitf/refs/heads/main/autofuel.lua'))()
local Fly = loadstring(game:HttpGet('https://raw.githubusercontent.com/Levitzy/99nitf/refs/heads/main/fly.lua'))()
local AutoKill = loadstring(game:HttpGet('https://raw.githubusercontent.com/Levitzy/99nitf/refs/heads/main/autokill.lua'))()

local Rayfield = loadstring(game:HttpGet('https://sirius.menu/rayfield'))()

local Window = Rayfield:CreateWindow({
    Name = "Multi-Tool Bot Suite",
    LoadingTitle = "Ultimate Game Assistant",
    LoadingSubtitle = "by TreeChopper",
    ConfigurationSaving = {
        Enabled = true,
        FolderName = "MultiToolConfig",
        FileName = "Config"
    },
    Discord = {
        Enabled = false,
        Invite = "noinvitelink",
        RememberJoins = true
    },
    KeySystem = false
})

local FlyTab = Window:CreateTab("Fly", 4483362458)
local TreeTab = Window:CreateTab("Tree Chopper", 4483362458)
local FuelTab = Window:CreateTab("Auto Fuel", 4335489011)
local KillTab = Window:CreateTab("Auto Kill", 4483345998)
local UtilityTab = Window:CreateTab("Utilities", 4370317008)

local RunService = game:GetService("RunService")

local FlyToggle = FlyTab:CreateToggle({
    Name = "Enable Fly",
    CurrentValue = false,
    Flag = "FlyToggle",
    Callback = function(Value)
        local success = Fly.setEnabled(Value)
        
        if Value and success then
            Rayfield:Notify({
                Title = "Fly Enabled",
                Content = "PC: WASD + Space/Shift | Mobile: Touch & drag to fly!",
                Duration = 4,
                Image = 4483362458
            })
        elseif Value and not success then
            Rayfield:Notify({
                Title = "Fly Failed",
                Content = "Could not enable fly - character not found!",
                Duration = 3,
                Image = 4483362458
            })
        else
            Rayfield:Notify({
                Title = "Fly Disabled",
                Content = "Flight mode deactivated.",
                Duration = 2,
                Image = 4483362458
            })
        end
    end,
})

local FlySpeedSlider = FlyTab:CreateSlider({
    Name = "Fly Speed",
    Range = {1, 200},
    Increment = 5,
    Suffix = " Speed",
    CurrentValue = 50,
    Flag = "FlySpeed",
    Callback = function(Value)
        Fly.setSpeed(Value)
    end,
})

local TreeToggle = TreeTab:CreateToggle({
    Name = "Auto Chop All Small Trees",
    CurrentValue = false,
    Flag = "AutoChopToggle",
    Callback = function(Value)
        TreeChopper.setEnabled(Value)
        
        if Value then
            Rayfield:Notify({
                Title = "Auto Chop Enabled",
                Content = "Started chopping ALL small trees in map!",
                Duration = 3,
                Image = 4483362458
            })
        else
            Rayfield:Notify({
                Title = "Auto Chop Disabled",
                Content = "Stopped chopping trees.",
                Duration = 3,
                Image = 4483362458
            })
        end
    end,
})

local ChopDelayDropdown = TreeTab:CreateDropdown({
    Name = "Chop Delay",
    Options = {"0.1s", "0.5s", "1s", "2s", "3s", "5s"},
    CurrentOption = "1s",
    Flag = "ChopDelay",
    Callback = function(Option)
        local delayMap = {
            ["0.1s"] = 0.1,
            ["0.5s"] = 0.5,
            ["1s"] = 1,
            ["2s"] = 2,
            ["3s"] = 3,
            ["5s"] = 5
        }
        local delay = delayMap[Option] or 1
        TreeChopper.setChopDelay(delay)
    end,
})

local TreeStatusLabel = TreeTab:CreateLabel("Status: Ready")

local FuelToggle = FuelTab:CreateToggle({
    Name = "Auto Fuel MainFire [INSTANT]",
    CurrentValue = false,
    Flag = "AutoFuelToggle",
    Callback = function(Value)
        AutoFuel.setEnabled(Value)
        
        if Value then
            Rayfield:Notify({
                Title = "Auto Fuel Enabled",
                Content = "INSTANT dropping to MainFire campfire!",
                Duration = 3,
                Image = 4335489011
            })
        else
            Rayfield:Notify({
                Title = "Auto Fuel Disabled",
                Content = "Stopped moving fuel items.",
                Duration = 3,
                Image = 4335489011
            })
        end
    end,
})

local FuelStatusLabel = FuelTab:CreateLabel("Status: Ready")

local KillToggle = KillTab:CreateToggle({
    Name = "Auto Kill Bunnies [INSTANT]",
    CurrentValue = false,
    Flag = "AutoKillToggle",
    Callback = function(Value)
        AutoKill.setEnabled(Value)
        
        if Value then
            Rayfield:Notify({
                Title = "Auto Kill Enabled",
                Content = "Hunting all Bunnies instantly! 0.5s delay",
                Duration = 3,
                Image = 4483345998
            })
        else
            Rayfield:Notify({
                Title = "Auto Kill Disabled",
                Content = "Stopped hunting. Kills: " .. AutoKill.killStats.sessionKills,
                Duration = 3,
                Image = 4483345998
            })
        end
    end,
})

local InstantKillToggle = KillTab:CreateToggle({
    Name = "Instant Kill Mode (3x Damage)",
    CurrentValue = true,
    Flag = "InstantKillMode",
    Callback = function(Value)
        AutoKill.setInstantMode(Value)
        
        if Value then
            Rayfield:Notify({
                Title = "Instant Kill ON",
                Content = "Triple damage for instant kills!",
                Duration = 2,
                Image = 4483345998
            })
        else
            Rayfield:Notify({
                Title = "Instant Kill OFF",
                Content = "Normal damage mode",
                Duration = 2,
                Image = 4483345998
            })
        end
    end,
})

local KillDelaySlider = KillTab:CreateSlider({
    Name = "Kill Delay",
    Range = {0.1, 5},
    Increment = 0.1,
    Suffix = "s",
    CurrentValue = 0.5,
    Flag = "KillDelay",
    Callback = function(Value)
        AutoKill.setKillDelay(Value)
    end,
})

local KillRangeSlider = KillTab:CreateSlider({
    Name = "Kill Range",
    Range = {10, 500},
    Increment = 10,
    Suffix = " studs",
    CurrentValue = 150,
    Flag = "KillRange",
    Callback = function(Value)
        AutoKill.setKillRange(Value)
    end,
})

local WeaponDropdown = KillTab:CreateDropdown({
    Name = "Select Weapon",
    Options = {"Old Axe", "Stone Axe", "Iron Axe", "Any Axe", "Any Weapon"},
    CurrentOption = "Old Axe",
    Flag = "WeaponSelect",
    Callback = function(Option)
        if Option == "Any Axe" then
            AutoKill.setWeapon("Axe")
        elseif Option == "Any Weapon" then
            AutoKill.setWeapon("")
        else
            AutoKill.setWeapon(Option)
        end
    end,
})

local AddTargetInput = KillTab:CreateInput({
    Name = "Add Target Type",
    PlaceholderText = "Enter target name...",
    RemoveTextAfterFocusLost = true,
    Callback = function(Text)
        if Text and Text ~= "" then
            AutoKill.addTargetType(Text)
            Rayfield:Notify({
                Title = "Target Added",
                Content = "Now hunting: " .. Text,
                Duration = 2,
                Image = 4483345998
            })
        end
    end,
})

local TeleportButton = KillTab:CreateButton({
    Name = "Teleport to Nearest Target",
    Callback = function()
        AutoKill.teleportToTarget()
        Rayfield:Notify({
            Title = "Teleported",
            Content = "Moved to nearest target!",
            Duration = 2,
            Image = 4483345998
        })
    end,
})

local KillStatusLabel = KillTab:CreateLabel("Status: Ready")
local KillStatsLabel = KillTab:CreateLabel("Session Kills: 0 | KPM: 0")

local ComboToggle = UtilityTab:CreateToggle({
    Name = "Tree + Fuel Combo",
    CurrentValue = false,
    Flag = "ComboBotToggle",
    Callback = function(Value)
        TreeChopper.setEnabled(Value)
        AutoFuel.setEnabled(Value)
        
        if Value then
            Rayfield:Notify({
                Title = "Combo Bot Enabled",
                Content = "Tree Chopper and Auto Fuel active!",
                Duration = 4,
                Image = 4370317008
            })
        else
            Rayfield:Notify({
                Title = "Combo Bot Disabled",
                Content = "Both bots have been stopped.",
                Duration = 3,
                Image = 4370317008
            })
        end
    end,
})

local UltimateToggle = UtilityTab:CreateToggle({
    Name = "ULTIMATE MODE (All Bots)",
    CurrentValue = false,
    Flag = "UltimateModeToggle",
    Callback = function(Value)
        TreeChopper.setEnabled(Value)
        AutoFuel.setEnabled(Value)
        AutoKill.setEnabled(Value)
        
        if Value then
            Rayfield:Notify({
                Title = "ULTIMATE MODE ACTIVATED",
                Content = "All bots running! Chop, Fuel, Kill!",
                Duration = 5,
                Image = 4370317008
            })
        else
            Rayfield:Notify({
                Title = "Ultimate Mode Disabled",
                Content = "All bots stopped.",
                Duration = 3,
                Image = 4370317008
            })
        end
    end,
})

local ComboStatusLabel = UtilityTab:CreateLabel("Combo Status: All bots disabled")

RunService.Heartbeat:Connect(function()
    local treeStatus, treeCount, closestDistance = TreeChopper.getStatus()
    TreeStatusLabel:Set(treeStatus)
    
    local fuelStatus, distance = AutoFuel.getStatus()
    FuelStatusLabel:Set(fuelStatus)
    
    local killStatus = AutoKill.getStatus()
    KillStatusLabel:Set(killStatus)
    KillStatsLabel:Set(string.format("Session: %d kills | %.1f KPM | Total: %d", 
        AutoKill.killStats.sessionKills, 
        AutoKill.killStats.killsPerMinute,
        AutoKill.killStats.totalKills))
    
    local chopEnabled = TreeChopper.autoChopEnabled
    local fuelEnabled = AutoFuel.autoFuelEnabled
    local killEnabled = AutoKill.enabled
    
    local activeCount = 0
    local statusParts = {}
    
    if chopEnabled then 
        activeCount = activeCount + 1
        table.insert(statusParts, "Chop")
    end
    if fuelEnabled then 
        activeCount = activeCount + 1
        table.insert(statusParts, "Fuel")
    end
    if killEnabled then 
        activeCount = activeCount + 1
        table.insert(statusParts, "Kill")
    end
    
    if activeCount == 3 then
        ComboStatusLabel:Set("ULTIMATE MODE: All 3 bots active!")
    elseif activeCount > 0 then
        ComboStatusLabel:Set("Active: " .. table.concat(statusParts, " + "))
    else
        ComboStatusLabel:Set("Combo Status: All bots disabled")
    end
end)

Rayfield:Notify({
    Title = "Multi-Tool Bot Suite Loaded",
    Content = "Auto Kill added! Hunt Bunnies instantly with 0.5s delay!",
    Duration = 6,
    Image = 4483345998
})
