local Rayfield = loadstring(game:HttpGet('https://sirius.menu/rayfield'))()

local Window = Rayfield:CreateWindow({
   Name = "Followers experience",
   LoadingTitle = "Followers experience",
   LoadingSubtitle = "made by carter4321",
   ConfigurationSaving = { Enabled = false },
   Discord = { Enabled = false },
   KeySystem = false,
})

local player = game.Players.LocalPlayer
local RunService = game:GetService("RunService")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local HttpService = game:GetService("HttpService")
local TeleportService = game:GetService("TeleportService")
local Players = game:GetService("Players")
local GroupService = game:GetService("GroupService")
local MarketplaceService = game:GetService("MarketplaceService")
local SoundService = game:GetService("SoundService")
local Lighting = game:GetService("Lighting")
local UserInputService = game:GetService("UserInputService")
local GuiService = game:GetService("GuiService")
local ProximityPromptService = game:GetService("ProximityPromptService")

local scriptRunning = true 
local Connections = {} 

local function PlaySound(soundId)
    local sound = Instance.new("Sound")
    sound.SoundId = "rbxassetid://" .. tostring(soundId)
    sound.Volume = 2
    sound.Parent = SoundService
    sound:Play()
    sound.Ended:Connect(function()
        sound:Destroy()
    end)
end

local selectedTask = "Followers"
local selectedReaction = "none"
local targetInput = ""
local autoGet = false
local getSpeed = 15
local autoDropAll = false
local dropFixedDefault = false
local dropFixedCustom = false
local dropThreshold = 300
local autoDestroyTools = false
local destroyThreshold = 1000
local customX, customY, customZ = 0, 0, 0
local totalGot, totalDropped = 0, 0

local hitboxEnabled = false
local currentHitboxSize = 8
local ToolName = "Sword"

-- Biến cho Player Tab
local wsEnabled = false
local wsValue = 16
local infJumpEnabled = false
local noclipEnabled = false
local disable3DEnabled = false
local hidePlayersEnabled = false
local autoReconnectEnabled = false
local instantPromptEnabled = false

local randomDropPositions = {
    CFrame.new(-54.95, 699.22, 100.73),  
    CFrame.new(-63.65, 699.22, 133.30),  
    CFrame.new(-99.19, 699.22, 99.85),   
    CFrame.new(-105.89, 699.22, 132.59)  
}

local ActivateMainTask 

local MainTab = Window:CreateTab("Main", "home") 
local TrollTab = Window:CreateTab("Troll", "layers")
local PVPTab = Window:CreateTab("PVP", "swords") 
local StatsTab = Window:CreateTab("Info", "bar-chart")
local PlayerTab = Window:CreateTab("Player", "user")
local ConfigTab = Window:CreateTab("Config", "settings") 

-- Hệ thống chạy ngầm: NoGameplayPaused
task.spawn(function()
    while scriptRunning do
        local success, err = pcall(function()
            local pauseGui = game:GetService("CoreGui").RobloxGui:FindFirstChild("CoreScripts/NetworkPause")
            if pauseGui then
                pauseGui:Destroy()
            end
        end)
        task.wait(1)
    end
end)

StatsTab:CreateSection("Executor Information")
local executorName = (identifyexecutor and identifyexecutor() or "Unknown"):lower()
local executorDisplayName = (identifyexecutor and identifyexecutor() or "Unknown")
local LimitedExecutors = {"xeno", "solara"}
local isLimitedExecutor = false

for _, name in ipairs(LimitedExecutors) do
    if string.find(executorName, name) then
        isLimitedExecutor = true
        break
    end
end

local statusText = isLimitedExecutor and "Semi-Working" or "Working"
local extraNote = isLimitedExecutor and "May experiencing bugs for some features!" or "All features should works properly!"

StatsTab:CreateParagraph({
    Title = "System Info",
    Content = "Executor: " .. executorDisplayName .. "\nStatus: " .. statusText .. "\n" .. extraNote
})

StatsTab:CreateSection("Tool Information")
local StatsGotLabel = StatsTab:CreateLabel("Total Tools Gathered: 0")
local StatsDropLabel = StatsTab:CreateLabel("Total Tools Dropped: 0")

local saveFileName = "HangoutFollows_ServerData.json"
local oldJobId = ""
local oldPlaceId = game.PlaceId

if isfile and readfile and isfile(saveFileName) then
    local success, content = pcall(readfile, saveFileName)
    if success and content then
        local decodeSuccess, data = pcall(function() return HttpService:JSONDecode(content) end)
        if decodeSuccess and type(data) == "table" then
            if data.CurrentJobId and data.CurrentJobId ~= game.JobId and data.CurrentJobId ~= "" then
                oldJobId = data.CurrentJobId
                oldPlaceId = data.CurrentPlaceId or game.PlaceId
            else
                oldJobId = data.PreviousJobId or ""
                oldPlaceId = data.PreviousPlaceId or game.PlaceId
            end
        end
    end
end

if writefile and game.JobId ~= "" then
    local dataToSave = {
        PreviousJobId = oldJobId,
        PreviousPlaceId = oldPlaceId,
        CurrentJobId = game.JobId,
        CurrentPlaceId = game.PlaceId
    }
    pcall(function() writefile(saveFileName, HttpService:JSONEncode(dataToSave)) end)
end

table.insert(Connections, TeleportService.TeleportInitFailed:Connect(function(plr, result, errMsg)
    if plr == player then
        PlaySound("108601872025792")
        Rayfield:Notify({ Title = "Rejoin Failed", Content = tostring(errMsg), Duration = 5, Image = "rotate-ccw" })
    end
end))

local function bindBackpack()
    local backpack = player:WaitForChild("Backpack", 5)
    if backpack then
        table.insert(Connections, backpack.ChildAdded:Connect(function(child)
            if child:IsA("Tool") then
                totalGot = totalGot + 1
                StatsGotLabel:Set("Total Tools Gathered: " .. tostring(totalGot))
            end
        end))
    end
end
table.insert(Connections, player.CharacterAdded:Connect(bindBackpack))
bindBackpack()

MainTab:CreateSection("Panel Configuration")

local lastProcessedTask = ""
local lastProcessedInput = ""
local lastFailedTask = ""
local lastFailedInput = ""
local isProcessing = false
local spamWarningCooldown = false
local errorWarningCooldown = false 

local UI_Dropdown_Task = MainTab:CreateDropdown({
    Name = "Select Type",
    Options = {"Followers", "Twith Followers", "Twith Clips", "Group", "Asset Likes", "Look Favs", "Bundle Likes", "Game Favs", "Friend Req", "RoPro", "Group Like"},
    CurrentOption = {"Followers"},
    MultipleOptions = false,
    Flag = "TaskSelector",
    Callback = function(Option) selectedTask = Option[1] end,
})

local UI_Dropdown_Reaction = MainTab:CreateDropdown({
    Name = "Pick A Reaction (Only for Group Like)",
    Options = {"none", "love", "fire", "thumbs-up", "skull", "wow", "sad", "angry", "thinking", "very-positive"},
    CurrentOption = {"none"},
    MultipleOptions = false,
    Flag = "ReactionSelector",
    Callback = function(Option) selectedReaction = Option[1] end,
})

local UI_Input_Target = MainTab:CreateInput({
    Name = "Enter Your (Username/ID/Link)",
    PlaceholderText = "Enter data here...",
    RemoveTextAfterFocusLost = false,
    Callback = function(Text) targetInput = Text end,
})

local function validateUser(input)
    local id = tonumber(input)
    if id then 
        local success, name = pcall(function() return Players:GetNameFromUserIdAsync(id) end)
        return success and name ~= nil, id
    else 
        local success, userId = pcall(function() return Players:GetUserIdFromNameAsync(input) end)
        return success and userId ~= nil, userId
    end
end

local function validateGroup(input)
    local id = tonumber(input)
    if not id then return false, input end
    local success, info = pcall(function() return GroupService:GetGroupInfoAsync(id) end)
    return success and info ~= nil, id
end

local function validateAsset(input, infoType)
    local id = tonumber(input)
    if not id then return false, input end
    local success, info = pcall(function() return MarketplaceService:GetProductInfo(id, infoType) end)
    return success and info ~= nil, id
end

ActivateMainTask = function()
    if isProcessing then return end
    if targetInput == "" then return end 

    if selectedTask ~= "Group Like" and selectedReaction ~= "none" then
        if not errorWarningCooldown then
            errorWarningCooldown = true
            PlaySound("108601872025792")
            Rayfield:Notify({Title = "Error", Content = "You must set Reaction to 'none' when you are not using the 'Group Like'", Duration = 4, Image = 77236530693648})
            task.delay(3, function() errorWarningCooldown = false end)
        end
        return
    end

    if selectedTask == "Group Like" and selectedReaction == "none" then
        if not errorWarningCooldown then
            errorWarningCooldown = true
            PlaySound("108601872025792")
            Rayfield:Notify({Title = "Error", Content = "Please pick a valid reaction (love, fire, etc.) for 'Group Like'", Duration = 4, Image = 77236530693648})
            task.delay(3, function() errorWarningCooldown = false end)
        end
        return
    end

    if selectedTask == lastProcessedTask and targetInput == lastProcessedInput then
        if not spamWarningCooldown then
            spamWarningCooldown = true
            PlaySound("90420386076500") 
            Rayfield:Notify({Title = "Notice", Content = "You're already active", Duration = 3, Image = "info"})
            task.delay(3, function() spamWarningCooldown = false end)
        end
        return
    end

    if selectedTask == lastFailedTask and targetInput == lastFailedInput then return end

    local Event = ReplicatedStorage:FindFirstChild("SetActivityMode")
    if not Event then return end

    isProcessing = true
    local isValid = true
    local finalData = targetInput
    local actionName = ""

    if selectedTask == "Followers" or selectedTask == "Friend Req" or selectedTask == "RoPro" then isValid, finalData = validateUser(targetInput)
    elseif selectedTask == "Group" or selectedTask == "Group Like" then isValid, finalData = validateGroup(targetInput)
    elseif selectedTask == "Asset Likes" or selectedTask == "Game Favs" then isValid, finalData = validateAsset(targetInput, Enum.InfoType.Asset)
    elseif selectedTask == "Bundle Likes" then isValid, finalData = validateAsset(targetInput, Enum.InfoType.Bundle) end

    if not isValid then
        lastFailedTask = selectedTask
        lastFailedInput = targetInput
        
        if not errorWarningCooldown then
            errorWarningCooldown = true
            local errorMsg = "Invalid Data!"
            if selectedTask == "Group" or selectedTask == "Group Like" then errorMsg = "Group ID doesn't exist!"
            elseif selectedTask == "Asset Likes" or selectedTask == "Game Favs" then errorMsg = "Asset/Place ID doesn't exist!"
            elseif selectedTask == "Bundle Likes" then errorMsg = "Bundle ID doesn't exist!"
            else errorMsg = "Username or ID doesn't exist!" end
            
            PlaySound("108601872025792")
            Rayfield:Notify({Title = "Error", Content = errorMsg, Duration = 4, Image = 77236530693648})
            task.delay(3, function() errorWarningCooldown = false end)
        end
        isProcessing = false
        return
    end

    local success = false
    pcall(function()
        if selectedTask == "Followers" then actionName = "user_social"
        elseif selectedTask == "Twith Followers" then actionName = "twith_bot"
        elseif selectedTask == "Twith Clips" then actionName = "twith_clip"
        elseif selectedTask == "Group" then actionName = "project_contribute"
        elseif selectedTask == "Asset Likes" then actionName = "content_asset_support"
        elseif selectedTask == "Look Favs" then actionName = "content_look_support"
        elseif selectedTask == "Bundle Likes" then actionName = "content_bundle_support"
        elseif selectedTask == "Game Favs" then actionName = "game_favorite"
        elseif selectedTask == "Friend Req" then actionName = "friend_request"
        elseif selectedTask == "RoPro" then actionName = "ropro_like" 
        elseif selectedTask == "Group Like" then actionName = "group_like" end
        
        if actionName == "group_like" then Event:FireServer(actionName, finalData, selectedReaction)
        elseif actionName == "project_contribute" or actionName == "content_asset_support" or actionName == "content_bundle_support" or actionName == "game_favorite" then Event:FireServer(actionName, finalData, nil)
        else Event:FireServer(actionName, finalData) end
        success = true
    end)

    if success then
        lastProcessedTask = selectedTask
        lastProcessedInput = targetInput 
        lastFailedTask = "" 
        lastFailedInput = ""
        
        local extraInfo = (actionName == "group_like") and " ["..selectedReaction.."]" or ""
        PlaySound("90420386076500")
        Rayfield:Notify({Title = "Activated", Content = "Running: " .. actionName .. " (" .. tostring(finalData) .. ")" .. extraInfo, Duration = 5, Image = 93912665739148})
    end
    isProcessing = false
end

MainTab:CreateButton({
    Name = "Tap To Save And Auto Activate",
    Callback = function()
        ActivateMainTask()
    end,
})

MainTab:CreateSection("Information")
MainTab:CreateParagraph({
    Title = "How it works",
    Content = "This feature allows you to enter your (Username/ID/Video Link) on an alt account without needing to AFK on your main account (optional), and it will auto-activate for you even if the game constantly auto-rejoins.\n\nTO MAKE IT WORK, you need to create and save your config and enable 'Auto Load Config', it will continuously retain and execute your options."
})

TrollTab:CreateSection("Main Options")
local UI_Toggle_AutoGet = TrollTab:CreateToggle({
   Name = "Auto Get Medkit & FireExtinguisher & IceCream",
   CurrentValue = false,
   Flag = "AutoGet",
   Callback = function(Value) autoGet = Value end,
})

local UI_Slider_Speed = TrollTab:CreateSlider({
   Name = "Tool Grab Speed",
   Range = {5, 100},
   Increment = 1,
   Suffix = "Tools/s",
   CurrentValue = 15,
   Flag = "SpeedSlider",
   Callback = function(Value) getSpeed = Value end,
})

local UI_Toggle_AutoDrop = TrollTab:CreateToggle({
   Name = "Auto Drop All Tools",
   CurrentValue = false,
   Flag = "AutoDropAll",
   Callback = function(Value) autoDropAll = Value end,
})

TrollTab:CreateSection("Drop Position Settings")
local UI_Toggle_DropDefault, UI_Toggle_DropCustom

UI_Toggle_DropDefault = TrollTab:CreateToggle({
   Name = "Drop At Random Positions (Default)",
   CurrentValue = false,
   Flag = "DropFixedDefault",
   Callback = function(Value)
      dropFixedDefault = Value
      if Value and UI_Toggle_DropCustom then UI_Toggle_DropCustom:Set(false) end
   end,
})

local UI_Slider_DropThresh = TrollTab:CreateSlider({
   Name = "Drop When Inventory Is Full",
   Range = {50, 1000},
   Increment = 10,
   Suffix = "Tools",
   CurrentValue = 300,
   Flag = "DropThresholdSlider",
   Callback = function(Value) dropThreshold = Value end,
})

TrollTab:CreateLabel("Note: Only applies when Random or Custom Position drop is enabled.")

UI_Toggle_DropCustom = TrollTab:CreateToggle({
   Name = "Drop At Custom Position",
   CurrentValue = false,
   Flag = "DropFixedCustom",
   Callback = function(Value)
      dropFixedCustom = Value
      if Value and UI_Toggle_DropDefault then UI_Toggle_DropDefault:Set(false) end
   end,
})

local UI_Input_CustomPos = TrollTab:CreateInput({
   Name = "Custom Position (X, Y, Z)",
   PlaceholderText = "e.g. -99.98, 418.82, 104.80",
   RemoveTextAfterFocusLost = false,
   Callback = function(Text)
      local coords = {}
      for num in string.gmatch(Text, "[%d%.%-]+") do table.insert(coords, tonumber(num)) end
      if #coords >= 3 then customX, customY, customZ = coords[1], coords[2], coords[3] end
   end,
})

TrollTab:CreateSection("Optimization")
TrollTab:CreateButton({
   Name = "Destroy Dropped Tools (Fix Lag)",
   Callback = function()
      local deletedCount = 0
      for _, obj in ipairs(workspace:GetChildren()) do
          if obj:IsA("Tool") and (obj.Name == "Medkit" or obj.Name == "FireExtinguisher" or obj.Name == "IceCream" or obj.Name == "IceCreamCone") then
              obj:Destroy()
              deletedCount = deletedCount + 1
          end
      end
      if deletedCount > 0 then
          Rayfield:Notify({Title = "Cleanup Complete", Content = "Destroyed " .. tostring(deletedCount) .. " tools.", Duration = 3})
      end
   end,
})

local UI_Toggle_AutoDestroy = TrollTab:CreateToggle({
   Name = "Auto Destroy All Dropped Tools",
   CurrentValue = false,
   Flag = "AutoDestroyTools",
   Callback = function(Value) autoDestroyTools = Value end,
})

local UI_Slider_DestroyThresh = TrollTab:CreateSlider({
   Name = "Destroy Threshold",
   Range = {100, 5000},
   Increment = 50,
   Suffix = "Tools",
   CurrentValue = 1000,
   Flag = "DestroyThresholdSlider",
   Callback = function(Value) destroyThreshold = Value end,
})

TrollTab:CreateSection("Server Navigation")
local isRejoining = false
TrollTab:CreateButton({
    Name = "Rejoin Previous Server",
    Callback = function()
        if isRejoining then return end
        isRejoining = true
        task.delay(2, function() isRejoining = false end)
        
        if oldJobId and oldJobId ~= "" then
            Rayfield:Notify({ Title = "Rejoining...", Content = "Teleporting...", Duration = 5, Image = "rotate-ccw" })
            local tpSuccess, tpErr = pcall(function() TeleportService:TeleportToPlaceInstance(oldPlaceId, oldJobId, player) end)
            if not tpSuccess then 
                PlaySound("108601872025792")
                Rayfield:Notify({ Title = "Teleport Error", Content = tostring(tpErr), Duration = 4, Image = "rotate-ccw" })
            end
        else
            PlaySound("108601872025792")
            Rayfield:Notify({ Title = "Error", Content = "No previous server found!", Duration = 3, Image = "rotate-ccw" })
        end
    end,
})

local displayJobId = (oldJobId ~= "") and oldJobId or "None"
TrollTab:CreateLabel("Previous Server Job-ID: " .. displayJobId)
TrollTab:CreateLabel("Note: Rejoin the old server to see what you have done or are doing that crashed midway.")

PVPTab:CreateSection("PVP Enhancement")
local UI_Toggle_Hitbox = PVPTab:CreateToggle({
   Name = "Sword Fight Hitbox Expander",
   CurrentValue = false,
   Flag = "SwordHitbox",
   Callback = function(Value) hitboxEnabled = Value end,
})
local UI_Slider_HitboxSize = PVPTab:CreateSlider({
   Name = "Hitbox Size",
   Range = {1, 50},
   Increment = 1,
   Suffix = "Studs",
   CurrentValue = 8,
   Flag = "HitboxSize",
   Callback = function(Value) currentHitboxSize = Value end,
})

PlayerTab:CreateSection("Movement")

local UI_Toggle_WS = PlayerTab:CreateToggle({
    Name = "Enable WalkSpeed",
    CurrentValue = false,
    Flag = "WSToggle",
    Callback = function(Value) 
        wsEnabled = Value 
        if not Value and player.Character then
            local hum = player.Character:FindFirstChildOfClass("Humanoid")
            if hum then hum.WalkSpeed = 16 end
        end
    end,
})

local UI_Slider_WS = PlayerTab:CreateSlider({
    Name = "WalkSpeed Value",
    Range = {16, 250},
    Increment = 1,
    Suffix = "Speed",
    CurrentValue = 16,
    Flag = "WSSlider",
    Callback = function(Value) wsValue = Value end,
})

local UI_Toggle_InfJump = PlayerTab:CreateToggle({
    Name = "Infinite Jump",
    CurrentValue = false,
    Flag = "InfJumpToggle",
    Callback = function(Value) infJumpEnabled = Value end,
})

local UI_Toggle_Noclip = PlayerTab:CreateToggle({
    Name = "Noclip",
    CurrentValue = false,
    Flag = "NoclipToggle",
    Callback = function(Value) 
        noclipEnabled = Value 
        if not Value and player.Character then
            local collidableNames = {HumanoidRootPart = true, Head = true, Torso = true, UpperTorso = true, LowerTorso = true}
            for _, part in pairs(player.Character:GetDescendants()) do
                if part:IsA("BasePart") then
                    if collidableNames[part.Name] then
                        part.CanCollide = true
                    else
                        part.CanCollide = false
                    end
                end
            end
        end
    end,
})

PlayerTab:CreateSection("Game Options")

local UI_Toggle_AutoReconnect = PlayerTab:CreateToggle({
    Name = "Auto Reconnect",
    CurrentValue = false,
    Flag = "AutoReconnectToggle",
    Callback = function(Value) autoReconnectEnabled = Value end,
})

local UI_Toggle_InstantPrompt = PlayerTab:CreateToggle({
    Name = "Instant Prompt",
    CurrentValue = false,
    Flag = "InstantPromptToggle",
    Callback = function(Value) instantPromptEnabled = Value end,
})

PlayerTab:CreateSection("Performance")

local UI_Toggle_Disable3D = PlayerTab:CreateToggle({
    Name = "Disable 3D Rendering",
    CurrentValue = false,
    Flag = "Disable3DToggle",
    Callback = function(Value)
        disable3DEnabled = Value
        pcall(function() RunService:Set3dRenderingEnabled(not Value) end)
    end,
})

local HidePlayerConnections = {}

local function clearHideConnections()
    for _, conn in ipairs(HidePlayerConnections) do
        if conn.Disconnect then conn:Disconnect() end
    end
    table.clear(HidePlayerConnections)
end

local function hideObject(desc)
    if desc:IsA("BasePart") or desc:IsA("Decal") or desc:IsA("Texture") then
        if not desc:GetAttribute("OriginalTransparency") then
            desc:SetAttribute("OriginalTransparency", desc.Transparency)
        end
        desc.Transparency = 1
    elseif desc:IsA("BillboardGui") or desc:IsA("SurfaceGui") or desc:IsA("ParticleEmitter") or desc:IsA("Trail") or desc:IsA("Beam") or desc:IsA("Fire") or desc:IsA("Sparkles") or desc:IsA("Light") or desc:IsA("Highlight") then
        if desc:GetAttribute("OriginalEnabled") == nil then
            desc:SetAttribute("OriginalEnabled", desc.Enabled)
        end
        desc.Enabled = false
    end
end

local function showObject(desc)
    if desc:IsA("BasePart") or desc:IsA("Decal") or desc:IsA("Texture") then
        local orig = desc:GetAttribute("OriginalTransparency")
        if orig then
            desc.Transparency = orig
        end
    elseif desc:IsA("BillboardGui") or desc:IsA("SurfaceGui") or desc:IsA("ParticleEmitter") or desc:IsA("Trail") or desc:IsA("Beam") or desc:IsA("Fire") or desc:IsA("Sparkles") or desc:IsA("Light") or desc:IsA("Highlight") then
        local orig = desc:GetAttribute("OriginalEnabled")
        if orig ~= nil then
            desc.Enabled = orig
        end
    end
end

local function handleCharacterHide(character)
    if not hidePlayersEnabled then return end
    
    for _, desc in pairs(character:GetDescendants()) do
        hideObject(desc)
    end
    
    local conn = character.DescendantAdded:Connect(function(desc)
        if hidePlayersEnabled then
            task.delay(0.05, function() 
                if desc.Parent then hideObject(desc) end
            end)
        end
    end)
    table.insert(HidePlayerConnections, conn)
end

local UI_Toggle_HidePlayers = PlayerTab:CreateToggle({
    Name = "Hide All Players",
    CurrentValue = false,
    Flag = "HidePlayersToggle",
    Callback = function(Value)
        hidePlayersEnabled = Value
        if Value then
            for _, p in pairs(Players:GetPlayers()) do
                if p ~= player and p.Character then
                    handleCharacterHide(p.Character)
                end
            end
            
            local conn1 = Players.PlayerAdded:Connect(function(newPlayer)
                local conn2 = newPlayer.CharacterAdded:Connect(function(char)
                    handleCharacterHide(char)
                end)
                table.insert(HidePlayerConnections, conn2)
            end)
            table.insert(HidePlayerConnections, conn1)
            
            for _, p in pairs(Players:GetPlayers()) do
                if p ~= player then
                    local conn3 = p.CharacterAdded:Connect(function(char)
                        handleCharacterHide(char)
                    end)
                    table.insert(HidePlayerConnections, conn3)
                end
            end
        else
            clearHideConnections()
            for _, p in pairs(Players:GetPlayers()) do
                if p ~= player and p.Character then
                    for _, desc in pairs(p.Character:GetDescendants()) do
                        showObject(desc)
                    end
                end
            end
        end
    end,
})

local fpsBoostCooldown = false
PlayerTab:CreateButton({
    Name = "FPS Boost",
    Callback = function()
        if fpsBoostCooldown then return end
        fpsBoostCooldown = true
        task.delay(3, function() fpsBoostCooldown = false end)
        
        pcall(function()
            Lighting.GlobalShadows = false
            Lighting.FogEnd = 9e9
            Lighting.Brightness = 1
            for _, v in pairs(Lighting:GetChildren()) do
                if v:IsA("PostProcessEffect") or v:IsA("BloomEffect") or v:IsA("BlurEffect") or v:IsA("SunRaysEffect") then
                    v.Enabled = false
                end
            end
            task.spawn(function()
                for i, v in pairs(workspace:GetDescendants()) do
                    if not scriptRunning then break end
                    pcall(function()
                        if v:IsA("BasePart") then
                            v.Material = Enum.Material.SmoothPlastic
                            v.CastShadow = false
                        elseif v:IsA("Decal") or v:IsA("Texture") then
                            v:Destroy()
                        elseif v:IsA("ParticleEmitter") or v:IsA("Trail") or v:IsA("Beam") then
                            v.Enabled = false
                        end
                    end)
                    if i % 500 == 0 then task.wait() end
                end
            end)
        end)
        PlaySound("90420386076500")
        Rayfield:Notify({Title = "FPS Boost", Content = "Game visuals optimized!", Duration = 3, Image = 106868089574304})
    end,
})

table.insert(Connections, RunService.Stepped:Connect(function()
    if not scriptRunning then return end
    
    if wsEnabled and player.Character then
        local hum = player.Character:FindFirstChildOfClass("Humanoid")
        if hum then hum.WalkSpeed = wsValue end
    end

    if noclipEnabled and player.Character then
        for _, part in pairs(player.Character:GetDescendants()) do
            if part:IsA("BasePart") and part.CanCollide then
                part.CanCollide = false
            end
        end
    end
end))

table.insert(Connections, UserInputService.JumpRequest:Connect(function()
    if not scriptRunning then return end
    if infJumpEnabled and player.Character then
        local hum = player.Character:FindFirstChildOfClass("Humanoid")
        if hum then hum:ChangeState(Enum.HumanoidStateType.Jumping) end
    end
end))

table.insert(Connections, GuiService.ErrorMessageChanged:Connect(function()
    if not scriptRunning or not autoReconnectEnabled then return end
    task.wait(3) 
    pcall(function() TeleportService:Teleport(game.PlaceId, player) end)
end))

table.insert(Connections, ProximityPromptService.PromptButtonHoldBegan:Connect(function(prompt)
    if not scriptRunning or not instantPromptEnabled then return end
    prompt.HoldDuration = 0
end))

local ConfigFolder = "FE_Configs"
local AutoloadFile = ConfigFolder .. "/autoload.txt"

if not isfolder(ConfigFolder) then makefolder(ConfigFolder) end

local function GetConfigs()
    local configs = {"None"}
    if isfolder(ConfigFolder) then
        for _, file in ipairs(listfiles(ConfigFolder)) do
            if file:sub(-5) == ".json" then
                local name = file:match("([^/\\]+)%.json$")
                if name then table.insert(configs, name) end
            end
        end
    end
    return configs
end

local ConfigDropdown
local InputConfigName = ""
local SelectedConfig = "None"
local cooldownCreateConfig = false
local cooldownLoadConfig = false
local cooldownAutoload = false
local cooldownRefreshList = false 

ConfigTab:CreateSection("Config List")
ConfigDropdown = ConfigTab:CreateDropdown({
    Name = "Config List",
    Options = GetConfigs(),
    CurrentOption = {"None"},
    MultipleOptions = false,
    Flag = "ConfigSelector",
    Callback = function(Option) SelectedConfig = Option[1] end,
})

ConfigTab:CreateInput({
    Name = "Config Name",
    PlaceholderText = "Enter name...",
    RemoveTextAfterFocusLost = false,
    Callback = function(Text) InputConfigName = Text end,
})

local function RefreshConfigs()
    if ConfigDropdown then ConfigDropdown:Refresh(GetConfigs(), true) end
end

ConfigTab:CreateButton({
    Name = "Create / Overwrite Config",
    Callback = function()
        if cooldownCreateConfig then return end
        cooldownCreateConfig = true
        task.delay(3, function() cooldownCreateConfig = false end)

        local nameToSave = InputConfigName ~= "" and InputConfigName or SelectedConfig
        if nameToSave == "None" or nameToSave == "" then
            PlaySound("108601872025792")
            Rayfield:Notify({Title = "Error", Content = "Please enter a config name!", Duration = 3, Image = "alert-circle"})
            return
        end

        local data = {
            Task = selectedTask, Reaction = selectedReaction, TargetInput = targetInput,
            AutoGet = autoGet, Speed = getSpeed, AutoDropAll = autoDropAll,
            DropFixedDefault = dropFixedDefault, DropFixedCustom = dropFixedCustom, DropThreshold = dropThreshold,
            AutoDestroyTools = autoDestroyTools, DestroyThreshold = destroyThreshold,
            CustomPosX = customX, CustomPosY = customY, CustomPosZ = customZ,
            HitboxEnabled = hitboxEnabled, HitboxSize = currentHitboxSize,
            
            WSEnabled = wsEnabled, WSValue = wsValue, 
            InfJump = infJumpEnabled, Noclip = noclipEnabled,
            Disable3D = disable3DEnabled, HidePlayers = hidePlayersEnabled,
            AutoReconnect = autoReconnectEnabled, InstantPrompt = instantPromptEnabled
        }
        
        local success = pcall(function()
            writefile(ConfigFolder .. "/" .. nameToSave .. ".json", HttpService:JSONEncode(data))
        end)
        
        if success then
            PlaySound("90420386076500")
            Rayfield:Notify({Title = "Success", Content = "Config '" .. nameToSave .. "' saved!", Duration = 3, Image = "save"})
            RefreshConfigs()
        end
    end,
})

ConfigTab:CreateButton({
    Name = "Load Config",
    Callback = function()
        if cooldownLoadConfig then return end
        cooldownLoadConfig = true
        task.delay(3, function() cooldownLoadConfig = false end)

        if SelectedConfig == "None" then 
            PlaySound("108601872025792")
            Rayfield:Notify({Title = "Error", Content = "Select a config to load!", Duration = 3, Image = "alert-circle"})
            return 
        end
        local path = ConfigFolder .. "/" .. SelectedConfig .. ".json"
        
        if isfile(path) then
            local success, content = pcall(readfile, path)
            if success then
                local data = HttpService:JSONDecode(content)
                
                if data.Task then UI_Dropdown_Task:Set({data.Task}) end
                if data.Reaction then UI_Dropdown_Reaction:Set({data.Reaction}) end
                if data.TargetInput then UI_Input_Target:Set(data.TargetInput) end
                if data.AutoGet ~= nil then UI_Toggle_AutoGet:Set(data.AutoGet) end
                if data.Speed then UI_Slider_Speed:Set(data.Speed) end
                if data.AutoDropAll ~= nil then UI_Toggle_AutoDrop:Set(data.AutoDropAll) end
                if data.DropFixedDefault ~= nil then UI_Toggle_DropDefault:Set(data.DropFixedDefault) end
                if data.DropFixedCustom ~= nil then UI_Toggle_DropCustom:Set(data.DropFixedCustom) end
                if data.DropThreshold then UI_Slider_DropThresh:Set(data.DropThreshold) end
                if data.CustomPosX then UI_Input_CustomPos:Set(tostring(data.CustomPosX)..", "..tostring(data.CustomPosY)..", "..tostring(data.CustomPosZ)) end
                if data.AutoDestroyTools ~= nil then UI_Toggle_AutoDestroy:Set(data.AutoDestroyTools) end
                if data.DestroyThreshold then UI_Slider_DestroyThresh:Set(data.DestroyThreshold) end
                if data.HitboxEnabled ~= nil then UI_Toggle_Hitbox:Set(data.HitboxEnabled) end
                if data.HitboxSize then UI_Slider_HitboxSize:Set(data.HitboxSize) end

                if data.WSEnabled ~= nil then UI_Toggle_WS:Set(data.WSEnabled) end
                if data.WSValue then UI_Slider_WS:Set(data.WSValue) end
                if data.InfJump ~= nil then UI_Toggle_InfJump:Set(data.InfJump) end
                if data.Noclip ~= nil then UI_Toggle_Noclip:Set(data.Noclip) end
                if data.Disable3D ~= nil then UI_Toggle_Disable3D:Set(data.Disable3D) end
                if data.HidePlayers ~= nil then UI_Toggle_HidePlayers:Set(data.HidePlayers) end
                if data.AutoReconnect ~= nil then UI_Toggle_AutoReconnect:Set(data.AutoReconnect) end
                if data.InstantPrompt ~= nil then UI_Toggle_InstantPrompt:Set(data.InstantPrompt) end
                
                PlaySound("90420386076500")
                Rayfield:Notify({Title = "Loaded", Content = "Config '" .. SelectedConfig .. "' loaded successfully!", Duration = 3, Image = "download"})
            end
        end
    end,
})

ConfigTab:CreateButton({
    Name = "Delete Config",
    Callback = function()
        if SelectedConfig == "None" then return end
        local path = ConfigFolder .. "/" .. SelectedConfig .. ".json"
        if isfile(path) then
            delfile(path)
            PlaySound("90420386076500")
            Rayfield:Notify({Title = "Deleted", Content = "Config '" .. SelectedConfig .. "' deleted!", Duration = 3, Image = "trash"})
            SelectedConfig = "None"
            RefreshConfigs()
        end
    end,
})

ConfigTab:CreateButton({
    Name = "Refresh List",
    Callback = function() 
        -- Đã fix thêm delay 3s tại đây
        if cooldownRefreshList then return end
        cooldownRefreshList = true
        task.delay(3, function() cooldownRefreshList = false end)

        RefreshConfigs() 
        PlaySound("90420386076500")
        Rayfield:Notify({Title = "Refreshed", Content = "Config list has been updated!", Duration = 3, Image = "refresh-cw"})
    end,
})

ConfigTab:CreateSection("Autoload")
ConfigTab:CreateButton({
    Name = "Set Current as Autoload",
    Callback = function()
        if cooldownAutoload then return end
        cooldownAutoload = true
        task.delay(3, function() cooldownAutoload = false end)

        if SelectedConfig == "None" then
            PlaySound("108601872025792")
            Rayfield:Notify({Title = "Error", Content = "Select a config from the list first!", Duration = 3, Image = "alert-circle"})
            return
        end
        pcall(function() writefile(AutoloadFile, SelectedConfig) end)
        PlaySound("90420386076500")
        Rayfield:Notify({Title = "Autoload Set", Content = "'" .. SelectedConfig .. "' will load on startup.", Duration = 3, Image = "check"})
    end,
})

ConfigTab:CreateButton({
    Name = "Reset Autoload",
    Callback = function()
        if isfile(AutoloadFile) then
            delfile(AutoloadFile)
            PlaySound("90420386076500")
            Rayfield:Notify({Title = "Autoload Disabled", Content = "No config will auto load now.", Duration = 3, Image = "x"})
        end
    end,
})

ConfigTab:CreateSection("System")
ConfigTab:CreateButton({
    Name = "Unload Script",
    Callback = function()
        scriptRunning = false 
        
        for _, connection in pairs(Connections) do 
            if connection.Disconnect then connection:Disconnect() end
        end
        
        pcall(function() RunService:Set3dRenderingEnabled(true) end)
        
        clearHideConnections()
        for _, p in pairs(Players:GetPlayers()) do
            if p ~= player and p.Character then
                for _, desc in pairs(p.Character:GetDescendants()) do
                    showObject(desc)
                end
            end
        end
        
        local char = player.Character
        if char then
            local hum = char:FindFirstChildOfClass("Humanoid")
            if hum then hum.WalkSpeed = 16 end 
            
            local collidableNames = {HumanoidRootPart = true, Head = true, Torso = true, UpperTorso = true, LowerTorso = true}
            for _, part in pairs(char:GetDescendants()) do
                if part:IsA("BasePart") then
                    if collidableNames[part.Name] then
                        part.CanCollide = true
                    else
                        part.CanCollide = false
                    end
                end
            end

            local tool = char:FindFirstChild(ToolName)
            if tool and tool:FindFirstChild("Handle") then
                local hb = tool.Handle:FindFirstChild("HitboxPart")
                if hb then hb:Destroy() end
            end
        end
        
        Rayfield:Destroy() 
    end,
})

local function performDrop(targetCFrame)
    local char = player.Character
    local hrp = char and char:FindFirstChild("HumanoidRootPart")
    if not hrp then return end
    local tools = {}
    
    for _, tool in ipairs(player.Backpack:GetChildren()) do
        if tool:IsA("Tool") then table.insert(tools, tool) end
    end
    for _, tool in ipairs(char:GetChildren()) do
        if tool:IsA("Tool") then table.insert(tools, tool) end
    end

    if #tools > 0 then
        if targetCFrame then
            local cam = workspace.CurrentCamera
            local originalCamCFrame, originalCamType = cam.CFrame, cam.CameraType
            local originalCFrame = hrp.CFrame
            cam.CameraType = Enum.CameraType.Scriptable
            cam.CFrame = originalCamCFrame
            hrp.CFrame = targetCFrame
            task.wait(0.1) 
            for _, tool in ipairs(tools) do tool.Parent = char end
            task.wait(0.05)
            for _, tool in ipairs(tools) do
                tool.Parent = workspace
                totalDropped = totalDropped + 1
            end
            task.wait(0.05)
            hrp.CFrame = originalCFrame
            cam.CameraType = originalCamType
        else
            for _, tool in ipairs(tools) do tool.Parent = char end
            task.wait(0.05)
            for _, tool in ipairs(tools) do
                tool.Parent = workspace
                totalDropped = totalDropped + 1
            end
        end
        StatsDropLabel:Set("Total Tools Dropped: " .. tostring(totalDropped))
    end
end

task.spawn(function()
    while scriptRunning do
        if autoGet then
            local delayTime = 1 / getSpeed
            local school = workspace:FindFirstChild("School")
            if school then
                local safetySupplies = school:FindFirstChild("SafetySupplies")
                if safetySupplies then
                    local firstAid = safetySupplies:FindFirstChild("FirstAidKit")
                    if firstAid then
                        local cd = firstAid:FindFirstChild("Interactive") and firstAid.Interactive:FindFirstChildOfClass("ClickDetector")
                        if cd then fireclickdetector(cd) end
                    end
                    local fireExt = safetySupplies:FindFirstChild("MountedFireExtinguisher")
                    if fireExt then
                        local cd = fireExt:FindFirstChild("Interactive") and fireExt.Interactive:FindFirstChildOfClass("ClickDetector")
                        if cd then fireclickdetector(cd) end
                    end
                end
            end

            local store = workspace:FindFirstChild("Convenience Store")
            if store then
                local freezer = store:FindFirstChild("IceCreamFreezer")
                if freezer then
                    local cd = freezer:FindFirstChild("IceCreamInteractive") and freezer.IceCreamInteractive:FindFirstChildOfClass("ClickDetector")
                    if cd then fireclickdetector(cd) end
                end
            end
            task.wait(delayTime)
        else
            task.wait(0.2)
        end
    end
end)

task.spawn(function()
    while scriptRunning do 
        task.wait(0.5)
        if autoDropAll then
            local backpack = player:FindFirstChild("Backpack")
            local char = player.Character
            if backpack then
                local toolCount = #backpack:GetChildren()
                if char then
                    for _, child in ipairs(char:GetChildren()) do
                        if child:IsA("Tool") then toolCount = toolCount + 1 end
                    end
                end

                if dropFixedDefault or dropFixedCustom then
                    if toolCount >= dropThreshold then
                        local targetPos = dropFixedDefault and randomDropPositions[math.random(1, #randomDropPositions)] or CFrame.new(customX, customY, customZ)
                        performDrop(targetPos)
                    end
                else
                    if toolCount > 0 then performDrop(nil) end
                end
            end
        end
    end
end)

task.spawn(function()
    while scriptRunning do 
        task.wait(2)
        if autoDestroyTools then
            local droppedTools = {}
            for _, obj in ipairs(workspace:GetChildren()) do
                if obj:IsA("Tool") and (obj.Name == "Medkit" or obj.Name == "FireExtinguisher" or obj.Name == "IceCream" or obj.Name == "IceCreamCone") then
                    table.insert(droppedTools, obj)
                end
            end
            if #droppedTools >= destroyThreshold then
                for _, tool in ipairs(droppedTools) do tool:Destroy() end
            end
        end
    end
end)

table.insert(Connections, RunService.RenderStepped:Connect(function()
    if not scriptRunning then return end
    local character = player.Character
    if not character then return end
    local tool = character:FindFirstChild(ToolName)
    
    if not hitboxEnabled or not tool or not tool:IsA("Tool") then
        if tool then
            local handle = tool:FindFirstChild("Handle")
            if handle and handle:FindFirstChild("HitboxPart") then handle.HitboxPart:Destroy() end
        end
        return
    end

    local handle = tool:FindFirstChild("Handle")
    if not handle then return end

    local hitboxPart = handle:FindFirstChild("HitboxPart")
    if not hitboxPart then
        hitboxPart = Instance.new("Part")
        hitboxPart.Name = "HitboxPart"
        hitboxPart.Transparency = 1 
        hitboxPart.CanCollide = false
        hitboxPart.Massless = true
        hitboxPart.Size = Vector3.new(currentHitboxSize, currentHitboxSize, currentHitboxSize)
        hitboxPart.CFrame = handle.CFrame
        hitboxPart.Parent = handle
        
        local weld = Instance.new("WeldConstraint")
        weld.Part0, weld.Part1, weld.Parent = handle, hitboxPart, hitboxPart
        
        local selBox = Instance.new("SelectionBox")
        selBox.Name = "HitboxVisual"
        selBox.Adornee = hitboxPart
        selBox.LineThickness = 0.02 
        selBox.Color3 = Color3.fromRGB(255, 255, 255) 
        selBox.SurfaceColor3 = Color3.fromRGB(255, 100, 100) 
        selBox.SurfaceTransparency = 0.7 
        selBox.Parent = hitboxPart
    else
        hitboxPart.Size = Vector3.new(currentHitboxSize, currentHitboxSize, currentHitboxSize)
    end

    local hrp = character:FindFirstChild("HumanoidRootPart")
    if not hrp then return end

    for _, enemy in ipairs(Players:GetPlayers()) do
        if enemy ~= player and enemy.Character then
            local enemyChar = enemy.Character
            local enemyHrp = enemyChar:FindFirstChild("HumanoidRootPart")
            local enemyHum = enemyChar:FindFirstChildOfClass("Humanoid")
            if enemyHrp and enemyHum and enemyHum.Health > 0 then
                if (hrp.Position - enemyHrp.Position).Magnitude <= currentHitboxSize and firetouchinterest then
                    for _, part in ipairs(enemyChar:GetChildren()) do
                        if part:IsA("BasePart") then
                            firetouchinterest(handle, part, 0)
                            firetouchinterest(handle, part, 1)
                        end
                    end
                end
            end
        end
    end
end))

task.spawn(function()
    task.wait(1.5) 
    if isfile(AutoloadFile) then
        local success, autoloadConfigName = pcall(readfile, AutoloadFile)
        if success and autoloadConfigName ~= "" then
            local path = ConfigFolder .. "/" .. autoloadConfigName .. ".json"
            if isfile(path) then
                SelectedConfig = autoloadConfigName
                ConfigDropdown:Set({autoloadConfigName})
                
                local readSuccess, content = pcall(readfile, path)
                if readSuccess then
                    local data = HttpService:JSONDecode(content)
                    
                    if data.Task then UI_Dropdown_Task:Set({data.Task}) end
                    if data.Reaction then UI_Dropdown_Reaction:Set({data.Reaction}) end
                    if data.TargetInput then UI_Input_Target:Set(data.TargetInput) end
                    if data.AutoGet ~= nil then UI_Toggle_AutoGet:Set(data.AutoGet) end
                    if data.Speed then UI_Slider_Speed:Set(data.Speed) end
                    if data.AutoDropAll ~= nil then UI_Toggle_AutoDrop:Set(data.AutoDropAll) end
                    if data.DropFixedDefault ~= nil then UI_Toggle_DropDefault:Set(data.DropFixedDefault) end
                    if data.DropFixedCustom ~= nil then UI_Toggle_DropCustom:Set(data.DropFixedCustom) end
                    if data.DropThreshold then UI_Slider_DropThresh:Set(data.DropThreshold) end
                    if data.CustomPosX then UI_Input_CustomPos:Set(tostring(data.CustomPosX)..", "..tostring(data.CustomPosY)..", "..tostring(data.CustomPosZ)) end
                    if data.AutoDestroyTools ~= nil then UI_Toggle_AutoDestroy:Set(data.AutoDestroyTools) end
                    if data.DestroyThreshold then UI_Slider_DestroyThresh:Set(data.DestroyThreshold) end
                    if data.HitboxEnabled ~= nil then UI_Toggle_Hitbox:Set(data.HitboxEnabled) end
                    if data.HitboxSize then UI_Slider_HitboxSize:Set(data.HitboxSize) end

                    if data.WSEnabled ~= nil then UI_Toggle_WS:Set(data.WSEnabled) end
                    if data.WSValue then UI_Slider_WS:Set(data.WSValue) end
                    if data.InfJump ~= nil then UI_Toggle_InfJump:Set(data.InfJump) end
                    if data.Noclip ~= nil then UI_Toggle_Noclip:Set(data.Noclip) end
                    if data.Disable3D ~= nil then UI_Toggle_Disable3D:Set(data.Disable3D) end
                    if data.HidePlayers ~= nil then UI_Toggle_HidePlayers:Set(data.HidePlayers) end
                    if data.AutoReconnect ~= nil then UI_Toggle_AutoReconnect:Set(data.AutoReconnect) end
                    if data.InstantPrompt ~= nil then UI_Toggle_InstantPrompt:Set(data.InstantPrompt) end
                    
                    Rayfield:Notify({Title = "Autoloaded", Content = "Config '" .. autoloadConfigName .. "' applied!", Duration = 3, Image = "download"})
                    
                    task.wait(0.5) 
                    if targetInput ~= "" then
                        ActivateMainTask()
                    end
                end
            end
        end
    end
end)
