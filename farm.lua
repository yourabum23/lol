workspace.FallenPartsDestroyHeight = 0/0

local player = game.Players.LocalPlayer
local OG_Kills = tonumber(player.leaderstats.Kills.Value)
local currentkills = OG_Kills

local SafeSpot = Instance.new("Part")
SafeSpot.Name = "safety"
SafeSpot.Position = Vector3.new(0, -1000, 0)
SafeSpot.Size = Vector3.new(500, 1, 500)
SafeSpot.Anchored = true
SafeSpot.Parent = workspace

player.Character:MoveTo(SafeSpot.Position)

local ScreenGui = Instance.new("ScreenGui")
ScreenGui.Name = "AutoKillerGUI"
ScreenGui.ResetOnSpawn = false
ScreenGui.Parent = player:WaitForChild("PlayerGui")

local MainFrame = Instance.new("Frame")
MainFrame.Name = "MainFrame"
MainFrame.Size = UDim2.new(0, 280, 0, 160)
MainFrame.Position = UDim2.new(0, 20, 0, 20)
MainFrame.BackgroundColor3 = Color3.fromRGB(20, 20, 20)
MainFrame.BorderSizePixel = 0
MainFrame.Parent = ScreenGui

local Stroke = Instance.new("UIStroke")
Stroke.Color = Color3.fromRGB(255, 0, 0)
Stroke.Thickness = 2
Stroke.Parent = MainFrame

local Corner = Instance.new("UICorner")
Corner.CornerRadius = UDim.new(0, 12)
Corner.Parent = MainFrame

local Title = Instance.new("TextLabel")
Title.Size = UDim2.new(1, 0, 0, 40)
Title.BackgroundTransparency = 1
Title.Text = "Auto Killer"
Title.TextColor3 = Color3.fromRGB(255, 50, 50)
Title.TextScaled = true
Title.Font = Enum.Font.GothamBold
Title.Parent = MainFrame

local TitleCorner = Instance.new("UICorner")
TitleCorner.CornerRadius = UDim.new(0, 12)
TitleCorner.Parent = Title

local KillsLabel = Instance.new("TextLabel")
KillsLabel.Size = UDim2.new(1, -20, 0, 35)
KillsLabel.Position = UDim2.new(0, 10, 0, 50)
KillsLabel.BackgroundTransparency = 1
KillsLabel.Text = "Kills: 0 (+0)"
KillsLabel.TextColor3 = Color3.fromRGB(255, 255, 255)
KillsLabel.TextScaled = true
KillsLabel.Font = Enum.Font.GothamSemibold
KillsLabel.Parent = MainFrame

local TimerLabel = Instance.new("TextLabel")
TimerLabel.Size = UDim2.new(1, -20, 0, 35)
TimerLabel.Position = UDim2.new(0, 10, 0, 95)
TimerLabel.BackgroundTransparency = 1
TimerLabel.Text = "Next Hop: 120s"
TimerLabel.TextColor3 = Color3.fromRGB(255, 100, 100)
TimerLabel.TextScaled = true
TimerLabel.Font = Enum.Font.GothamSemibold
TimerLabel.Parent = MainFrame

local dragging, dragInput, dragStart, startPos
MainFrame.InputBegan:Connect(function(input)
    if input.UserInputType == Enum.UserInputType.MouseButton1 then
        dragging = true
        dragStart = input.Position
        startPos = MainFrame.Position
    end
end)

MainFrame.InputEnded:Connect(function(input)
    if input.UserInputType == Enum.UserInputType.MouseButton1 then
        dragging = false
    end
end)

game:GetService("UserInputService").InputChanged:Connect(function(input)
    if dragging and input.UserInputType == Enum.UserInputType.MouseMovement then
        local delta = input.Position - dragStart
        MainFrame.Position = UDim2.new(startPos.X.Scale, startPos.X.Offset + delta.X, startPos.Y.Scale, startPos.Y.Offset + delta.Y)
    end
end)

local function GETOUT()
    local Services = setmetatable({}, { __index = function(self, name)
        local success, cache = pcall(function() return cloneref(game:GetService(name)) end)
        if success then
            rawset(self, name, cache)
            return cache
        end
    end})

    local PlaceId, JobId = game.PlaceId, game.JobId
    local servers = {}
    local req = game:HttpGet("https://games.roblox.com/v1/games/" .. PlaceId .. "/servers/Public?sortOrder=Desc&limit=100&excludeFullGames=true")
    local body = Services.HttpService:JSONDecode(req)

    if body and body.data then
        for _, v in ipairs(body.data) do
            if v.playing and v.maxPlayers and v.playing < v.maxPlayers and v.id ~= JobId then
                table.insert(servers, v.id)
            end
        end
    end

    if #servers >= 1 then
        Services.TeleportService:TeleportToPlaceInstance(PlaceId, servers[math.random(1, #servers)], player)
    end
end

local serverTime = 120
spawn(function()
    while true do
        task.wait(1)
        serverTime -= 1
        if serverTime <= 0 then serverTime = 120 end
        TimerLabel.Text = "Next Hop: " .. serverTime .. "s"
    end
end)

while true do
    task.wait(0.09)
    pcall(function()
        currentkills = tonumber(player.leaderstats.Kills.Value)
        
        local gained = currentkills - OG_Kills
        KillsLabel.Text = "Kills: " .. currentkills .. " (+" .. gained .. ")"

        local punch = player.Backpack:FindFirstChild("Punch") or (player.Character and player.Character:FindFirstChild("Punch"))
        if punch and punch.Parent == player.Backpack then
            punch.Parent = player.Character
        end

        for _, target in ipairs(game.Players:GetPlayers()) do
            if target ~= player and target.Character and target:FindFirstChild("Durability") and target:FindFirstChild("leaderstats") then
                if target.Durability.Value <= player.leaderstats.Strength.Value * 2 and target.leaderstats.Rebirths.Value <= 200000 then
                    local root = target.Character:FindFirstChild("HumanoidRootPart")
                    local rHand = player.Character and player.Character:FindFirstChild("RightHand")
                    local lHand = player.Character and player.Character:FindFirstChild("LeftHand")

                    if root and rHand and lHand then
                        game.Players.LocalPlayer.muscleEvent:FireServer("punch", "rightHand")
                        firetouchinterest(rHand, root, 1)
                        firetouchinterest(lHand, root, 1)
                        firetouchinterest(rHand, root, 0)
                        firetouchinterest(lHand, root, 0)
                    end
                end
            end
        end

        local humanoid = player.Character and player.Character:FindFirstChild("Humanoid")
        if (humanoid and humanoid.Health <= humanoid.MaxHealth / 10) or 
           (game.Workspace.DistributedGameTime >= 120) or 
           (#game.Players:GetPlayers() <= 9) then
            GETOUT()
        end
    end)
end
