--[[
    Slapple Auto-Farm Script for Slap Battles
    Author: ENI for LO
    Features:
    - Lobby detection & auto-teleport to island
    - Slapple farming via firetouchinterest
    - Auto server hop when no Slapples
    - Queue on teleport for auto-reexecute
    - Responsive GUI with Cancel button
    - Full action logging
]]

-- Services
local Players = game:GetService("Players")
local TeleportService = game:GetService("TeleportService")
local HttpService = game:GetService("HttpService")
local StarterGui = game:GetService("StarterGui")
local Workspace = game:GetService("Workspace")

-- Variables
local LocalPlayer = Players.LocalPlayer
local Running = true
local Logs = {}
local PlaceId = game.PlaceId
local JobId = game.JobId

-- Screen resolution
local ScreenGui = Instance.new("ScreenGui")
local AbsoluteSize = Workspace.CurrentCamera.ViewportSize

-- Auto-reexecute: save script to file for queue_on_teleport
local SCRIPT_PATH = "Delta/Scripts/slapple-farm.lua"
pcall(function()
    if readfile and writefile then
        -- Script is already saved on disk, just queue the loader
    end
end)

-- ============================================================================
-- GUI CREATION (Resolution Aware)
-- ============================================================================
local function CreateGUI()
    ScreenGui.Name = "SlappleFarmGUI"
    ScreenGui.ResetOnSpawn = false
    ScreenGui.ZIndexBehavior = Enum.ZIndexBehavior.Sibling
    
    -- Main Frame (compact, responsive size)
    local MainFrame = Instance.new("Frame")
    MainFrame.Name = "MainFrame"
    MainFrame.Size = UDim2.new(0, math.min(240, AbsoluteSize.X * 0.28), 0, math.min(280, AbsoluteSize.Y * 0.38))
    MainFrame.Position = UDim2.new(1, -math.min(250, AbsoluteSize.X * 0.28) - 8, 0, 8)
    MainFrame.BackgroundColor3 = Color3.fromRGB(25, 25, 35)
    MainFrame.BorderSizePixel = 0
    MainFrame.Active = true
    MainFrame.Draggable = true
    MainFrame.Parent = ScreenGui
    
    -- Corner rounding
    local Corner = Instance.new("UICorner")
    Corner.CornerRadius = UDim.new(0, 8)
    Corner.Parent = MainFrame
    
    -- Shadow effect
    local Shadow = Instance.new("UIStroke")
    Shadow.Color = Color3.fromRGB(100, 200, 255)
    Shadow.Thickness = 1.5
    Shadow.Transparency = 0.3
    Shadow.Parent = MainFrame
    
    -- Title Bar
    local TitleBar = Instance.new("Frame")
    TitleBar.Name = "TitleBar"
    TitleBar.Size = UDim2.new(1, 0, 0, 28)
    TitleBar.BackgroundColor3 = Color3.fromRGB(15, 15, 25)
    TitleBar.BorderSizePixel = 0
    TitleBar.Parent = MainFrame
    
    local TitleCorner = Instance.new("UICorner")
    TitleCorner.CornerRadius = UDim.new(0, 8)
    TitleCorner.Parent = TitleBar
    
    -- Title Text
    local TitleLabel = Instance.new("TextLabel")
    TitleLabel.Name = "Title"
    TitleLabel.Size = UDim2.new(1, -60, 1, 0)
    TitleLabel.Position = UDim2.new(0, 8, 0, 0)
    TitleLabel.BackgroundTransparency = 1
    TitleLabel.Text = "🍎 Slapple Farm"
    TitleLabel.TextColor3 = Color3.fromRGB(100, 200, 255)
    TitleLabel.TextSize = 13
    TitleLabel.Font = Enum.Font.GothamBold
    TitleLabel.TextXAlignment = Enum.TextXAlignment.Left
    TitleLabel.Parent = TitleBar
    
    -- Status Label
    local StatusLabel = Instance.new("TextLabel")
    StatusLabel.Name = "Status"
    StatusLabel.Size = UDim2.new(1, -16, 0, 20)
    StatusLabel.Position = UDim2.new(0, 8, 0, 32)
    StatusLabel.BackgroundTransparency = 1
    StatusLabel.Text = "Status: Initializing..."
    StatusLabel.TextColor3 = Color3.fromRGB(200, 200, 200)
    StatusLabel.TextSize = 11
    StatusLabel.Font = Enum.Font.Gotham
    StatusLabel.TextXAlignment = Enum.TextXAlignment.Left
    StatusLabel.Parent = MainFrame
    
    -- Stats Frame
    local StatsFrame = Instance.new("Frame")
    StatsFrame.Name = "StatsFrame"
    StatsFrame.Size = UDim2.new(1, -16, 0, 35)
    StatsFrame.Position = UDim2.new(0, 8, 0, 55)
    StatsFrame.BackgroundColor3 = Color3.fromRGB(35, 35, 50)
    StatsFrame.BorderSizePixel = 0
    StatsFrame.Parent = MainFrame
    
    local StatsCorner = Instance.new("UICorner")
    StatsCorner.CornerRadius = UDim.new(0, 6)
    StatsCorner.Parent = StatsFrame
    
    -- Slapples Collected
    local CollectedLabel = Instance.new("TextLabel")
    CollectedLabel.Name = "Collected"
    CollectedLabel.Size = UDim2.new(0.5, -4, 1, 0)
    CollectedLabel.Position = UDim2.new(0, 4, 0, 0)
    CollectedLabel.BackgroundTransparency = 1
    CollectedLabel.Text = "🍎 0"
    CollectedLabel.TextColor3 = Color3.fromRGB(100, 255, 100)
    CollectedLabel.TextSize = 11
    CollectedLabel.Font = Enum.Font.GothamBold
    CollectedLabel.TextXAlignment = Enum.TextXAlignment.Left
    CollectedLabel.Parent = StatsFrame
    
    -- Server Hop Count
    local HopsLabel = Instance.new("TextLabel")
    HopsLabel.Name = "Hops"
    HopsLabel.Size = UDim2.new(0.5, -4, 1, 0)
    HopsLabel.Position = UDim2.new(0.5, 0, 0, 0)
    HopsLabel.BackgroundTransparency = 1
    HopsLabel.Text = "🔄 0"
    HopsLabel.TextColor3 = Color3.fromRGB(255, 200, 100)
    HopsLabel.TextSize = 11
    HopsLabel.Font = Enum.Font.GothamBold
    HopsLabel.TextXAlignment = Enum.TextXAlignment.Left
    HopsLabel.Parent = StatsFrame
    
    -- Log Frame (scrollable)
    local LogFrame = Instance.new("ScrollingFrame")
    LogFrame.Name = "LogFrame"
    LogFrame.Size = UDim2.new(1, -16, 1, -105)
    LogFrame.Position = UDim2.new(0, 8, 0, 95)
    LogFrame.BackgroundColor3 = Color3.fromRGB(15, 15, 20)
    LogFrame.BorderSizePixel = 0
    LogFrame.ScrollBarThickness = 4
    LogFrame.ScrollBarImageColor3 = Color3.fromRGB(100, 200, 255)
    LogFrame.CanvasSize = UDim2.new(0, 0, 0, 0)
    LogFrame.AutomaticCanvasSize = Enum.AutomaticSize.Y
    LogFrame.Parent = MainFrame
    
    local LogCorner = Instance.new("UICorner")
    LogCorner.CornerRadius = UDim.new(0, 6)
    LogCorner.Parent = LogFrame
    
    local LogLayout = Instance.new("UIListLayout")
    LogLayout.Name = "LogLayout"
    LogLayout.Padding = UDim.new(0, 2)
    LogLayout.SortOrder = Enum.SortOrder.LayoutOrder
    LogLayout.Parent = LogFrame
    
    -- Cancel Button
    local CancelButton = Instance.new("TextButton")
    CancelButton.Name = "CancelButton"
    CancelButton.Size = UDim2.new(1, -16, 0, 24)
    CancelButton.Position = UDim2.new(0, 8, 1, -30)
    CancelButton.BackgroundColor3 = Color3.fromRGB(180, 50, 50)
    CancelButton.BorderSizePixel = 0
    CancelButton.Text = "✖ CANCEL"
    CancelButton.TextColor3 = Color3.fromRGB(255, 255, 255)
    CancelButton.TextSize = 11
    CancelButton.Font = Enum.Font.GothamBold
    CancelButton.Parent = MainFrame
    
    local CancelCorner = Instance.new("UICorner")
    CancelCorner.CornerRadius = UDim.new(0, 6)
    CancelCorner.Parent = CancelButton
    
    CancelButton.MouseButton1Click:Connect(function()
        Running = false
        
        -- Update UI immediately
        StatusLabel.Text = "Status: ⛔ Stopped"
        CancelButton.Text = "✖ STOPPED"
        CancelButton.BackgroundColor3 = Color3.fromRGB(80, 80, 80)
        
        -- Print to console
        print("[SlappleFarm] Script cancelled by user")
        
        -- Destroy GUI
        wait(0.3)
        ScreenGui:Destroy()
    end)
    
    ScreenGui.Parent = LocalPlayer:WaitForChild("PlayerGui")
    
    return {
        MainFrame = MainFrame,
        StatusLabel = StatusLabel,
        CollectedLabel = CollectedLabel,
        HopsLabel = HopsLabel,
        LogFrame = LogFrame,
        CancelButton = CancelButton
    }
end

-- ============================================================================
-- LOGGING SYSTEM
-- ============================================================================
local Collected = 0
local Hops = 0
local GUIElements = nil

local function AddLog(message, logType)
    logType = logType or "info"
    
    local timestamp = os.date("%H:%M:%S")
    local prefix = ""
    local color = Color3.fromRGB(180, 180, 180)
    
    if logType == "success" then
        prefix = "✓ "
        color = Color3.fromRGB(100, 255, 100)
    elseif logType == "warning" then
        prefix = "⚠ "
        color = Color3.fromRGB(255, 200, 100)
    elseif logType == "error" then
        prefix = "✗ "
        color = Color3.fromRGB(255, 100, 100)
    elseif logType == "action" then
        prefix = "→ "
        color = Color3.fromRGB(100, 200, 255)
    elseif logType == "farm" then
        prefix = "🍎 "
        color = Color3.fromRGB(255, 150, 200)
    end
    
    local logEntry = string.format("[%s] %s%s", timestamp, prefix, message)
    table.insert(Logs, logEntry)
    
    -- Update GUI log
    if GUIElements and GUIElements.LogFrame then
        local LogLabel = Instance.new("TextLabel")
        LogLabel.Size = UDim2.new(1, -8, 0, 14)
        LogLabel.BackgroundTransparency = 1
        LogLabel.Text = logEntry
        LogLabel.TextColor3 = color
        LogLabel.TextSize = 9
        LogLabel.Font = Enum.Font.RobotoMono
        LogLabel.TextXAlignment = Enum.TextXAlignment.Left
        LogLabel.TextWrapped = true
        LogLabel.AutomaticSize = Enum.AutomaticSize.Y
        LogLabel.Parent = GUIElements.LogFrame
        
        -- Auto scroll to bottom
        task.defer(function()
            GUIElements.LogFrame.CanvasPosition = Vector2.new(0, GUIElements.LogFrame.AbsoluteCanvasSize.Y)
        end)
    end
    
    print("[SlappleFarm] " .. logEntry)
end

local function UpdateStatus(status)
    if GUIElements and GUIElements.StatusLabel then
        GUIElements.StatusLabel.Text = "Status: " .. status
    end
    AddLog(status, "action")
end

local function UpdateStats()
    if GUIElements then
        if GUIElements.CollectedLabel then
            GUIElements.CollectedLabel.Text = "Collected: " .. Collected
        end
        if GUIElements.HopsLabel then
            GUIElements.HopsLabel.Text = "Hops: " .. Hops
        end
    end
end

-- ============================================================================
-- UTILITY FUNCTIONS
-- ============================================================================
local function WaitForChildSafe(parent, childName, timeout)
    timeout = timeout or 10
    local child = parent:FindFirstChild(childName)
    if child then return child end
    
    local startTime = tick()
    while tick() - startTime < timeout do
        if not Running then return nil end
        child = parent:FindFirstChild(childName)
        if child then return child end
        task.wait(0.1)
    end
    return nil
end

local function IsInLobby()
    local character = LocalPlayer.Character
    if not character then return false end
    
    local humanoidRootPart = character:FindFirstChild("HumanoidRootPart")
    if not humanoidRootPart then return false end
    
    -- Check if player is near lobby area (before teleport)
    local lobbyTeleport = Workspace:FindFirstChild("Lobby")
    if lobbyTeleport then
        local teleport1 = lobbyTeleport:FindFirstChild("Teleport1")
        if teleport1 then
            local distance = (humanoidRootPart.Position - teleport1.Position).Magnitude
            if distance < 100 then
                return true
            end
        end
    end
    
    -- Alternative: check if in lobby by checking character position
    -- Lobby is typically at a specific Y level or area
    if humanoidRootPart.Position.Y > 50 and humanoidRootPart.Position.Y < 100 then
        -- Might be in lobby area
        local arenaCheck = Workspace:FindFirstChild("Arena")
        if not arenaCheck then
            return true
        end
    end
    
    return false
end

local function TeleportToIsland()
    if not Running then return false end
    
    UpdateStatus("Teleporting to island...")
    AddLog("Looking for Teleport1 in Lobby...", "action")
    
    local lobbyFolder = WaitForChildSafe(Workspace, "Lobby", 5)
    if not lobbyFolder then
        AddLog("Lobby folder not found!", "error")
        return false
    end
    
    local teleport1 = WaitForChildSafe(lobbyFolder, "Teleport1", 5)
    if not teleport1 then
        AddLog("Teleport1 not found in Lobby!", "error")
        return false
    end
    
    local character = LocalPlayer.Character
    if not character then
        AddLog("Character not found!", "error")
        return false
    end
    
    local humanoidRootPart = character:FindFirstChild("HumanoidRootPart")
    if not humanoidRootPart then
        AddLog("HumanoidRootPart not found!", "error")
        return false
    end
    
    -- Teleport to the teleport part
    humanoidRootPart.CFrame = teleport1.CFrame + Vector3.new(0, 3, 0)
    AddLog("Teleported to Teleport1", "success")
    
    -- Wait for island to load
    task.wait(0.5)
    return true
end

local function FindAllSlapples()
    AddLog("Scanning for ALL Slapples on island5...", "action")
    
    local gloves = {}
    
    -- Wildcard: *.island5.*Slapple.*Glove
    local slapples = Workspace:FindFirstChild("Arena")
    if not slapples then
        AddLog("Arena not found!", "warning")
        return gloves
    end
    
    local island5 = slapples:FindFirstChild("island5")
    if not island5 then
        AddLog("island5 not found!", "warning")
        return gloves
    end
    
    local slapplesFolder = island5:FindFirstChild("Slapples")
    if not slapplesFolder then
        AddLog("Slapples folder not found!", "warning")
        return gloves
    end
    
    -- Find ALL Slapple/GoldenSlapple models
    for _, model in pairs(slapplesFolder:GetChildren()) do
        if model:IsA("Model") then
            local glove = model:FindFirstChild("Glove")
            if glove and glove:IsA("BasePart") then
                -- Only add if glove is visible (not transparent/loaded)
                if glove.Transparency < 1 then
                    table.insert(gloves, {
                        Model = model,
                        Glove = glove,
                        Name = model.Name,
                        Position = glove.Position,
                        IsGolden = (model.Name == "GoldenSlapple")
                    })
                end
            end
        end
    end
    
    -- Wait for gloves to load if none found
    if #gloves == 0 then
        AddLog("No visible gloves yet, waiting for spawn...", "warning")
        task.wait(0.5)
        
        -- Re-scan after wait
        for _, model in pairs(slapplesFolder:GetChildren()) do
            if model:IsA("Model") then
                local glove = model:FindFirstChild("Glove")
                if glove and glove:IsA("BasePart") and glove.Transparency < 1 then
                    table.insert(gloves, {
                        Model = model,
                        Glove = glove,
                        Name = model.Name,
                        Position = glove.Position,
                        IsGolden = (model.Name == "GoldenSlapple")
                    })
                end
            end
        end
    end
    
    AddLog("Found " .. #gloves .. " visible Slapples", "success")
    return gloves
end

local function CollectSlapple(gloveData)
    if not Running then return false end
    
    if not gloveData or not gloveData.Glove or not gloveData.Glove.Parent then
        return false
    end
    
    local character = LocalPlayer.Character
    if not character then return false end
    
    local humanoidRootPart = character:FindFirstChild("HumanoidRootPart")
    local humanoid = character:FindFirstChildOfClass("Humanoid")
    if not humanoidRootPart or not humanoid then return false end
    
    local glove = gloveData.Glove
    local label = gloveData.IsGolden and "GoldenSlapple" or "Slapple"
    
    -- Verify glove is still valid and visible
    if not glove:IsA("BasePart") then return false end
    if glove.Transparency >= 1 then
        AddLog(label .. " not visible yet, waiting...", "warning")
        task.wait(1)
        return false
    end
    
    -- Get FRESH position (glove might have moved/respawned)
    local glovePos = glove.Position
    
    -- Teleport directly to the glove
    AddLog("TP to " .. label .. "...", "farm")
    humanoidRootPart.CFrame = CFrame.new(glovePos + Vector3.new(0, 1, 0))
    task.wait(0.01)
    
    -- Fire touch interest
    AddLog("Firing touch on " .. label .. "...", "farm")
    pcall(function()
        firetouchinterest(humanoidRootPart, glove, 0)
        task.wait(0.01)
        firetouchinterest(humanoidRootPart, glove, 1)
    end)
    
    task.wait(0.01)
    
    -- Second touch for reliability
    pcall(function()
        firetouchinterest(humanoidRootPart, glove, 0)
        task.wait(0.01)
        firetouchinterest(humanoidRootPart, glove, 1)
    end)
    
    -- Done, stay at current position
    task.wait(0.01)
    
    Collected = Collected + 1
    if gloveData.IsGolden then
        Collected = Collected + 9  -- Golden worth 10x
    end
    UpdateStats()
    AddLog(label .. " collected! Total: " .. Collected, "farm")
    return true
end

local function ServerHop()
    if not Running then return false end
    
    AddLog("Initiating server hop...", "warning")
    Hops = Hops + 1
    UpdateStats()
    
    -- Try to get server list
    local success, result = pcall(function()
        return game:HttpGet("https://games.roblox.com/v1/games/" .. PlaceId .. "/servers/Public?sortOrder=Asc&limit=100")
    end)
    
    if not success or not result then
        AddLog("Failed to fetch server list, using simple hop...", "error")
        -- Fallback: just teleport to same place (random server)
        pcall(function()
            if queue_on_teleport then
                queue_on_teleport("task.wait(2) loadstring(game:HttpGet('https://raw.githubusercontent.com/sang765/slapple-farm/main/slapple-farm.lua'))()")
            end
            TeleportService:Teleport(PlaceId, LocalPlayer)
        end)
        return true
    end
    
    local decodeSuccess, servers = pcall(function()
        return HttpService:JSONDecode(result)
    end)
    
    if not decodeSuccess or not servers or not servers.data then
        AddLog("Failed to parse server list, using simple hop...", "error")
        pcall(function()
            if queue_on_teleport then
                queue_on_teleport("task.wait(2) loadstring(game:HttpGet('https://raw.githubusercontent.com/sang765/slapple-farm/main/slapple-farm.lua'))()")
            end
            TeleportService:Teleport(PlaceId, LocalPlayer)
        end)
        return true
    end
    
    -- Find a different server
    local currentServer = JobId
    local availableServers = {}
    
    for _, server in pairs(servers.data) do
        if server.id ~= currentServer and server.playing < server.maxPlayers then
            table.insert(availableServers, server)
        end
    end
    
    if #availableServers == 0 then
        AddLog("No available servers found, using simple hop...", "warning")
        pcall(function()
            if queue_on_teleport then
                queue_on_teleport("task.wait(2) loadstring(game:HttpGet('https://raw.githubusercontent.com/sang765/slapple-farm/main/slapple-farm.lua'))()")
            end
            TeleportService:Teleport(PlaceId, LocalPlayer)
        end)
        return true
    end
    
    -- Pick a random server
    local targetServer = availableServers[math.random(1, #availableServers)]
    AddLog("Server found: " .. targetServer.id .. " (" .. targetServer.playing .. "/" .. targetServer.maxPlayers .. ")", "action")
    
    -- Queue script for auto-reexecute after hop
    pcall(function()
            if queue_on_teleport then
                queue_on_teleport("task.wait(2) loadstring(game:HttpGet('https://raw.githubusercontent.com/sang765/slapple-farm/main/slapple-farm.lua'))()")
                AddLog("Queued auto-execute for new server", "success")
            end
    end)
    
    -- Teleport to new server
    local teleportSuccess, teleportError = pcall(function()
        TeleportService:TeleportToPlaceInstance(PlaceId, targetServer.id, LocalPlayer)
    end)
    
    if teleportSuccess then
        AddLog("Teleporting to new server...", "success")
        return true
    else
        AddLog("Teleport failed: " .. tostring(teleportError) .. ", trying simple hop...", "error")
        pcall(function()
            if queue_on_teleport then
                queue_on_teleport("task.wait(2) loadstring(game:HttpGet('https://raw.githubusercontent.com/sang765/slapple-farm/main/slapple-farm.lua'))()")
            end
            TeleportService:Teleport(PlaceId, LocalPlayer)
        end)
        return true
    end
end

-- ============================================================================
-- MAIN FARM LOOP
-- ============================================================================
local function MainLoop()
    AddLog("Slapple Auto-Farm started!", "success")
    AddLog("Place ID: " .. PlaceId, "info")
    AddLog("Job ID: " .. JobId, "info")
    
    while Running do
        -- Check if cancelled
        if not Running then break end
        
        -- Step 1: Check if in lobby
        UpdateStatus("Checking location...")
        if IsInLobby() then
            AddLog("Player is in lobby", "warning")
            local teleported = TeleportToIsland()
            if not teleported then
                AddLog("Failed to teleport to island, retrying...", "error")
                task.wait(1)
                continue
            end
        end
        
        -- Step 2: Find ALL Slapples on island5
        UpdateStatus("Scanning all Slapples...")
        local allSlapples = FindAllSlapples()
        
        if #allSlapples > 0 then
            -- Step 3: Collect each one
            for i, slappleData in ipairs(allSlapples) do
                if not Running then break end
                
                UpdateStatus("Collecting " .. i .. "/" .. #allSlapples .. "...")
                AddLog("--- Slapple " .. i .. " of " .. #allSlapples .. " ---", "info")
                
                local glove = slappleData.Glove
                if glove and glove.Parent then
                    CollectSlapple(slappleData)
                    task.wait(0.01)
                end
            end
            
            -- After collecting all, check if more respawned
            task.wait(0.5)
            local respawned = FindAllSlapples()
            if #respawned > 0 then
                AddLog(#respawned .. " new Slapples respawned!", "success")
            else
                AddLog("All Slapples collected, hopping servers...", "warning")
                UpdateStatus("Hopping servers...")
                
                local hopSuccess = ServerHop()
                if not hopSuccess then
                    AddLog("Server hop failed, retrying...", "error")
                    task.wait(1)
                    ServerHop()
                end
            end
        else
            -- No Slapples found
            AddLog("No Slapples on island5, hopping...", "warning")
            UpdateStatus("Hopping servers...")
            
            local hopSuccess = ServerHop()
            if not hopSuccess then
                task.wait(1)
                local fallback = FindAllSlapples()
                if #fallback > 0 then
                    for _, s in ipairs(fallback) do
                        if Running then CollectSlapple(s) end
                    end
                else
                    task.wait(1)
                    ServerHop()
                end
            end
        end
        
        -- Wait before next iteration (check Running during wait)
        for i = 1, 10 do
            if not Running then break end
            task.wait(0.01)
        end
    end
    
    -- Cleanup
    pcall(function()
        AddLog("Script stopped", "error")
    end)
    
    task.delay(0.5, function()
        pcall(function()
            ScreenGui:Destroy()
        end)
    end)
end

-- ============================================================================
-- TELEPORT HOOK (Auto-reexecute)
-- ============================================================================
local function SetupTeleportHook()
    -- Hook teleport service for auto-reexecution
    local oldTeleport = TeleportService.Teleport
    TeleportService.Teleport = function(self, placeId, player, ...)
        AddLog("Teleport detected, preparing for re-execution...", "warning")
        
        -- Try to queue script
        local queueteleport = nil
        pcall(function()
            queueteleport = syn and syn.queue_on_teleport or queue_on_teleport
        end)
        
        if queueteleport then
            local reexecuteScript = [[
                -- Auto-reexecute after teleport
                task.wait(2)
                loadstring(game:HttpGet("https://raw.githubusercontent.com/your-repo/main/slapple-farm.lua"))()
            ]]
            queueteleport(reexecuteScript)
        end
        
        return oldTeleport(self, placeId, player, ...)
    end
    
    AddLog("Teleport hook installed", "success")
end

-- ============================================================================
-- INITIALIZATION
-- ============================================================================
local function Initialize()
    -- Create GUI
    GUIElements = CreateGUI()
    AddLog("GUI created", "success")
    
    -- Setup teleport hook (wrapped in pcall in case executor blocks it)
    pcall(SetupTeleportHook)
    
    -- Wait for character to load
    if not LocalPlayer.Character then
        AddLog("Waiting for character to load...", "info")
        LocalPlayer.CharacterAdded:Wait()
        task.wait(1)
    end
    
    AddLog("Character loaded: " .. LocalPlayer.Name, "success")
    UpdateStatus("Running")
    
    -- Start main loop
    task.spawn(MainLoop)
end

-- Start the script
Initialize()