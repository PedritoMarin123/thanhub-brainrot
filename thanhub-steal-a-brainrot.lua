local TweenService = game:GetService("TweenService")
local UIS = game:GetService("UserInputService")
local RunService = game:GetService("RunService")
local Lighting = game:GetService("Lighting")
local Players = game:GetService("Players")
local Player = Players.LocalPlayer

local scriptToLoad = [[
local Players = game:GetService("Players")
local RunService = game:GetService("RunService")
local TweenService = game:GetService("TweenService")
local UserInputService = game:GetService("UserInputService")
local Lighting = game:GetService("Lighting")
local player = Players.LocalPlayer
local random = Random.new()

--// Configuration
local DEBUG = false
local tpAmt
local void = CFrame.new(0, -3.4028234663852886e+38, 0)
local teleporting

local function DebugInfo(mode, content, value)
    if not DEBUG then return end
    if mode == "warn" then
        warn("[ThanHub-tp DEBUG]:", content, value or "")
    elseif mode == "print" then
        print("[ThanHub-tp DEBUG]:", content, value or "")
    else
        warn("[ThanHub-tp DEBUG]: Invalid debug type.")
    end
end

--// Player & Character setup
local backpack = player:WaitForChild("Backpack")
local char, humanoid, hrp

local function GetCharacter()
    return player.Character or player.CharacterAdded:Wait()
end

local function SetupCharacter()
    char = GetCharacter()
    humanoid = char:WaitForChild("Humanoid")
    hrp = char:WaitForChild("HumanoidRootPart")
    backpack = player:WaitForChild("Backpack")
    DebugInfo("print", "Character setup completed for", player.Name)
end

SetupCharacter()

player.CharacterAdded:Connect(function()
    SetupCharacter()
end)

--// Calculate tpAmt from Latency
task.spawn(function()
    while true do
        local ping = player:GetNetworkPing() * 1000
        tpAmt = math.clamp(math.floor(ping * 0.8), 10, 150)
        if DEBUG then
            DebugInfo("print", "Ping: " .. math.floor(ping) .. "ms | tpAmt:", tpAmt)
        end
        RunService.Heartbeat:Wait()
    end
end)

local function TP(position)
    if not teleporting then
        teleporting = true
        if typeof(position) == "CFrame" then
            hrp.CFrame = position + Vector3.new(
                random:NextNumber(-0.0001, 0.0001),
                random:NextNumber(-0.0001, 0.0001),
                random:NextNumber(-0.0001, 0.0001)
            )
            RunService.Heartbeat:Wait()
            teleporting = false
        end
    else
        DebugInfo("warn", "You are already teleporting", "teleporting")
    end
end

local function FindDelivery()
    local plots = workspace:FindFirstChild("Plots")
    if not plots then
        DebugInfo("warn", "Plots folder not found in workspace", nil)
        return
    end
    for _, plot in pairs(plots:GetChildren()) do
        local sign = plot:FindFirstChild("PlotSign")
        if sign then
            local yourBase = sign:FindFirstChild("YourBase")
            if yourBase and yourBase.Enabled then
                local hitbox = plot:FindFirstChild("DeliveryHitbox")
                if hitbox then return hitbox end
            end
        end
    end
    DebugInfo("warn", "No valid DeliveryHitbox found", nil)
end

local function DeliverBrainrot(statusLabel)
    local hitbox = FindDelivery()
    if not hitbox then
        statusLabel.Text = "Error: DeliveryHitbox not found"
        statusLabel.TextColor3 = Color3.fromRGB(255, 80, 80)
        TweenService:Create(statusLabel, TweenInfo.new(0.3), {TextTransparency = 0}):Play()
        task.wait(2)
        TweenService:Create(statusLabel, TweenInfo.new(0.3), {TextTransparency = 1}):Play()
        return
    end

    DebugInfo("print", "DeliveryHitbox successfully found", hitbox)

    local target = hitbox.CFrame * CFrame.new(0, -3, 0)
    
    local i = 0
    while i < (tpAmt or 70) do
        TP(target)
        i += 1
    end
    
    for _ = 1, 2 do
        TP(void)
    end
    
    i = 0
    while i < (tpAmt / 16) do
        TP(target)
        i += 1
    end
    
    task.wait(1)  

    local distance = (hrp.Position - target.Position).Magnitude
    if distance <= 30 then
        DebugInfo("print", "Teleport succeeded", distance)
        statusLabel.Text = "Teleport Succeeded!"
        statusLabel.TextColor3 = Color3.fromRGB(0, 255, 100)
    else
        DebugInfo("warn", "Teleport failed", distance)
        statusLabel.Text = "Teleport Failed: Too far (" .. math.floor(distance) .. ")"
        statusLabel.TextColor3 = Color3.fromRGB(255, 80, 80)
    end
    TweenService:Create(statusLabel, TweenInfo.new(0.3), {TextTransparency = 0}):Play()
    task.wait(2)
    TweenService:Create(statusLabel, TweenInfo.new(0.3), {TextTransparency = 1}):Play()
end

local function TPNearestBase(statusLabel)
    local plotsFolder = workspace:FindFirstChild("Plots")
    if not plotsFolder then
        DebugInfo("warn", "Missing folder", "Plots")
        statusLabel.Text = "Error: Plots folder not found"
        statusLabel.TextColor3 = Color3.fromRGB(255, 80, 80)
        TweenService:Create(statusLabel, TweenInfo.new(0.3), {TextTransparency = 0}):Play()
        task.wait(2)
        TweenService:Create(statusLabel, TweenInfo.new(0.3), {TextTransparency = 1}):Play()
        return
    end

    local closestBrainrot = nil
    local shortestDistance = math.huge

    for _, plot in pairs(plotsFolder:GetChildren()) do
        local plotSign = plot:FindFirstChild("PlotSign")
        if plotSign then
            local plotSignText = plotSign:FindFirstChild("SurfaceGui"):FindFirstChild("Frame"):FindFirstChild("TextLabel")
            if plotSignText and plotSignText.ContentText ~= "Empty Base" then
                local yourBase = plotSign:FindFirstChild("YourBase")
                if yourBase and not yourBase.Enabled then
                    local podiums = plot:FindFirstChild("AnimalPodiums")
                    if podiums then
                        for _, brainrot in pairs(podiums:GetChildren()) do
                            if brainrot:IsA("Model") and brainrot:FindFirstChild("Base"):FindFirstChild("Spawn") then
                                local brainrotSpawn = brainrot.Base.Spawn
                                local distance = (brainrotSpawn.Position - hrp.Position).Magnitude
                                if distance < shortestDistance then
                                    shortestDistance = distance
                                    closestBrainrot = brainrotSpawn
                                end
                            end
                        end
                    end
                end
            end
        end
    end

    if not closestBrainrot then
        DebugInfo("warn", "No valid podium found", nil)
        statusLabel.Text = "Error: No valid podium found"
        statusLabel.TextColor3 = Color3.fromRGB(255, 80, 80)
        TweenService:Create(statusLabel, TweenInfo.new(0.3), {TextTransparency = 0}):Play()
        task.wait(2)
        TweenService:Create(statusLabel, TweenInfo.new(0.3), {TextTransparency = 1}):Play()
        return
    end

    DebugInfo("print", "Nearest podium found", closestBrainrot)

    local target = closestBrainrot.CFrame * CFrame.new(0, 2, 0)
    
    local i = 0
    while i < (tpAmt or 70) do
        TP(target)
        i += 1
    end
    
    for _ = 1, 2 do
        TP(void)
    end
    
    i = 0
    while i < (tpAmt / 16) do
        TP(target)
        i += 1
    end
    
    task.wait(1)

    local distance = (hrp.Position - target.Position).Magnitude
    if distance <= 30 then
        DebugInfo("print", "Teleport succeeded", distance)
        statusLabel.Text = "Teleport Succeeded!"
        statusLabel.TextColor3 = Color3.fromRGB(0, 255, 100)
    else
        DebugInfo("warn", "Teleport failed", distance)
        statusLabel.Text = "Teleport Failed: Too far (" .. math.floor(distance) .. ")"
        statusLabel.TextColor3 = Color3.fromRGB(255, 80, 80)
    end
    TweenService:Create(statusLabel, TweenInfo.new(0.3), {TextTransparency = 0}):Play()
    task.wait(2)
    TweenService:Create(statusLabel, TweenInfo.new(0.3), {TextTransparency = 1}):Play()
end

local function TweenSteal(statusLabel)
    local TELEPORT_ITERATIONS = 85
    local VOID_CFRAME = CFrame.new(0, -3e40, 0)
    local MIN_RANDOM_OFFSET = -0.0008
    local MAX_RANDOM_OFFSET = 0.0008
    local JITTER_RANGE = 0.0002

    local function executeStealthMovement(targetCF, steps)
        if not hrp or typeof(targetCF) ~= "CFrame" then
            DebugInfo("warn", "Invalid HRP or target CFrame", nil)
            return false
        end
        
        local currentPos = hrp.Position
        local targetPos = targetCF.Position
        local startTime = tick()

        for i = 1, steps do
            local progress = (tick() - startTime) / (steps * 0.02)
            progress = math.min(progress, 1)
            
            local curvedProgress = progress * progress * (3 - 2 * progress)
            
            local newPos = currentPos:Lerp(targetPos, curvedProgress)
            newPos += Vector3.new(
                random:NextNumber(-JITTER_RANGE, JITTER_RANGE),
                random:NextNumber(-JITTER_RANGE, JITTER_RANGE),
                random:NextNumber(-JITTER_RANGE, JITTER_RANGE)
            )

            hrp.CFrame = CFrame.new(newPos) * (hrp.CFrame - hrp.Position)
            
            local waitTime = random:NextNumber(0.005, 0.015)
            task.wait(waitTime)
        end
        return true
    end

    local function findDeliverySpot()
        for _, v in ipairs(workspace.Plots:GetDescendants()) do
            if v.Name == "DeliveryHitbox" and v.Parent:FindFirstChild("PlotSign") then
                if v.Parent.PlotSign:FindFirstChild("YourBase") and v.Parent.PlotSign.YourBase.Enabled then
                    return v
                end
            end
        end
        DebugInfo("warn", "No valid DeliveryHitbox found for TweenSteal", nil)
        return nil
    end

    local delivery = findDeliverySpot()
    if not delivery then
        statusLabel.Text = "Error: DeliveryHitbox not found"
        statusLabel.TextColor3 = Color3.fromRGB(255, 80, 80)
        TweenService:Create(statusLabel, TweenInfo.new(0.3), {TextTransparency = 0}):Play()
        task.wait(2)
        TweenService:Create(statusLabel, TweenInfo.new(0.3), {TextTransparency = 1}):Play()
        return
    end

    DebugInfo("print", "DeliveryHitbox found for TweenSteal", delivery)

    local targetPos = delivery.CFrame * CFrame.new(0, random:NextInteger(-3, -1), 0)
    
    for _ = 1, 3 do
        task.spawn(function()
            local success = executeStealthMovement(targetPos, TELEPORT_ITERATIONS)
            if success then
                for _ = 1, 3 do
                    hrp.CFrame = VOID_CFRAME
                    task.wait(random:NextNumber(0.05, 0.1))
                    hrp.CFrame = targetPos
                    task.wait(random:NextNumber(0.05, 0.1))
                end
            end
            task.wait(random:NextNumber(0.1, 0.3))
        end)
    end

    task.wait(1)
    local distance = (hrp.Position - targetPos.Position).Magnitude
    if distance <= 30 then
        DebugInfo("print", "TweenSteal succeeded", distance)
        statusLabel.Text = "TweenSteal Succeeded!"
        statusLabel.TextColor3 = Color3.fromRGB(0, 255, 100)
    else
        DebugInfo("warn", "TweenSteal failed", distance)
        statusLabel.Text = "TweenSteal Failed: Too far (" .. math.floor(distance) .. ")"
        statusLabel.TextColor3 = Color3.fromRGB(255, 80, 80)
    end
    TweenService:Create(statusLabel, TweenInfo.new(0.3), {TextTransparency = 0}):Play()
    task.wait(2)
    TweenService:Create(statusLabel, TweenInfo.new(0.3), {TextTransparency = 1}):Play()
end

local ScreenGui = Instance.new("ScreenGui")
ScreenGui.Name = "ThanHub-Tp-Gui"
ScreenGui.ZIndexBehavior = Enum.ZIndexBehavior.Sibling
ScreenGui.IgnoreGuiInset = true
ScreenGui.DisplayOrder = 999
ScreenGui.Parent = game.Players.LocalPlayer:WaitForChild("PlayerGui")
DebugInfo("print", "created", ScreenGui.Name)

local Blur = Instance.new("BlurEffect")
Blur.Name = "ThanHubTPBlur"
Blur.Size = 0
Blur.Parent = workspace
DebugInfo("print", "ThanHubTPBlur created", Blur.Name)

local Frame = Instance.new("Frame")
Frame.Parent = ScreenGui
Frame.BackgroundColor3 = Color3.fromRGB(10, 10, 15)
Frame.BorderSizePixel = 0
Frame.AnchorPoint = Vector2.new(0.5, 0.5)
Frame.Position = UDim2.new(0.5, 0, 0.5, 0)
Frame.Size = UDim2.new(0, 0, 0, 0)
Frame.ClipsDescendants = true
Frame.BackgroundTransparency = 1

local Gradient = Instance.new("UIGradient")
Gradient.Color = ColorSequence.new({
    ColorSequenceKeypoint.new(0, Color3.fromRGB(20, 20, 30)),
    ColorSequenceKeypoint.new(1, Color3.fromRGB(10, 10, 20))
})
Gradient.Rotation = 45
Gradient.Parent = Frame

local UICorner = Instance.new("UICorner")
UICorner.CornerRadius = UDim.new(0, 16)
UICorner.Parent = Frame

local DropShadow = Instance.new("ImageLabel")
DropShadow.Name = "DropShadow"
DropShadow.Parent = Frame
DropShadow.AnchorPoint = Vector2.new(0.5, 0.5)
DropShadow.BackgroundTransparency = 1
DropShadow.Position = UDim2.new(0.5, 0, 0.5, 8)
DropShadow.Size = UDim2.new(1, 24, 1, 24)
DropShadow.Image = "rbxassetid://6014261993"
DropShadow.ImageColor3 = Color3.fromRGB(0, 0, 0)
DropShadow.ImageTransparency = 0.6
DropShadow.ScaleType = Enum.ScaleType.Slice
DropShadow.SliceCenter = Rect.new(10, 10, 118, 118)
DropShadow.ZIndex = -1
DropShadow.Visible = false

local TitleBar = Instance.new("Frame")
TitleBar.Name = "TitleBar"
TitleBar.Parent = Frame
TitleBar.BackgroundColor3 = Color3.fromRGB(15, 15, 20)
TitleBar.BorderSizePixel = 0
TitleBar.Size = UDim2.new(1, 0, 0, 40)
TitleBar.ZIndex = 2

local TitleBarGradient = Instance.new("UIGradient")
TitleBarGradient.Color = ColorSequence.new({
    ColorSequenceKeypoint.new(0, Color3.fromRGB(25, 25, 35)),
    ColorSequenceKeypoint.new(1, Color3.fromRGB(15, 15, 25))
})
TitleBarGradient.Parent = TitleBar

local TitleBarCorner = Instance.new("UICorner")
TitleBarCorner.CornerRadius = UDim.new(0, 16)
TitleBarCorner.Parent = TitleBar

local TitleLabel = Instance.new("TextLabel")
TitleLabel.Name = "Title"
TitleLabel.Parent = TitleBar
TitleLabel.BackgroundTransparency = 1
TitleLabel.Size = UDim2.new(1, -80, 1, 0)
TitleLabel.Position = UDim2.new(0, 15, 0, 0)
TitleLabel.Font = Enum.Font.GothamBlack
TitleLabel.Text = "THANHUB TP"
TitleLabel.TextColor3 = Color3.fromRGB(255, 255, 255)
TitleLabel.TextSize = 20
TitleLabel.TextXAlignment = Enum.TextXAlignment.Left
TitleLabel.TextTransparency = 1

local ButtonFrame = Instance.new("Frame")
ButtonFrame.Parent = TitleBar
ButtonFrame.BackgroundTransparency = 1
ButtonFrame.Size = UDim2.new(0, 80, 1, 0)
ButtonFrame.Position = UDim2.new(1, -80, 0, 0)

local MinimizeButton = Instance.new("TextButton")
MinimizeButton.Name = "MinimizeButton"
MinimizeButton.Parent = ButtonFrame
MinimizeButton.AnchorPoint = Vector2.new(0.5, 0.5)
MinimizeButton.BackgroundTransparency = 1
MinimizeButton.Position = UDim2.new(0.65, 0, 0.5, 0)
MinimizeButton.Size = UDim2.new(0, 24, 0, 24)
MinimizeButton.Font = Enum.Font.GothamBold
MinimizeButton.Text = "—"
MinimizeButton.TextColor3 = Color3.fromRGB(255, 204, 0)
MinimizeButton.TextSize = 16
MinimizeButton.TextTransparency = 1

local CloseButton = Instance.new("TextButton")
CloseButton.Name = "CloseButton"
CloseButton.Parent = ButtonFrame
CloseButton.AnchorPoint = Vector2.new(0.5, 0.5)
CloseButton.BackgroundTransparency = 1
CloseButton.Position = UDim2.new(0.85, 0, 0.5, 0)
CloseButton.Size = UDim2.new(0, 24, 0, 24)
CloseButton.Font = Enum.Font.GothamBold
CloseButton.Text = "X"
CloseButton.TextColor3 = Color3.fromRGB(255, 80, 80)
CloseButton.TextSize = 16
CloseButton.TextTransparency = 1

local Content = Instance.new("Frame")
Content.Name = "Content"
Content.Parent = Frame
Content.BackgroundTransparency = 1
Content.Position = UDim2.new(0, 0, 0, 40)
Content.Size = UDim2.new(1, 0, 1, -40)

local DeliveryButton = Instance.new("TextButton")
DeliveryButton.Name = "DeliveryButton"
DeliveryButton.Parent = Content
DeliveryButton.BackgroundColor3 = Color3.fromRGB(0, 120, 255)
DeliveryButton.TextColor3 = Color3.fromRGB(255, 255, 255)
DeliveryButton.Position = UDim2.new(0.1, 0, 0.15, 0)
DeliveryButton.Size = UDim2.new(0.8, 0, 0, 50)
DeliveryButton.Font = Enum.Font.GothamSemibold
DeliveryButton.Text = "TP TO DELIVERY BOX"
DeliveryButton.TextSize = 18
DeliveryButton.TextWrapped = true
DeliveryButton.TextTransparency = 1
DeliveryButton.AutoButtonColor = false

local UICorner_Delivery = Instance.new("UICorner")
UICorner_Delivery.CornerRadius = UDim.new(0, 12)
UICorner_Delivery.Parent = DeliveryButton

local DeliveryStroke = Instance.new("UIStroke")
DeliveryStroke.Parent = DeliveryButton
DeliveryStroke.Color = Color3.fromRGB(0, 80, 200)
DeliveryStroke.Thickness = 2
DeliveryStroke.Transparency = 0.5

local BaseButton = Instance.new("TextButton")
BaseButton.Name = "BaseButton"
BaseButton.Parent = Content
BaseButton.BackgroundColor3 = Color3.fromRGB(0, 120, 255)
BaseButton.TextColor3 = Color3.fromRGB(255, 255, 255)
BaseButton.Position = UDim2.new(0.1, 0, 0.35, 0)
BaseButton.Size = UDim2.new(0.8, 0, 0, 50)
BaseButton.Font = Enum.Font.GothamSemibold
BaseButton.Text = "TP INSIDE NEAREST BASE"
BaseButton.TextSize = 18
BaseButton.TextWrapped = true
BaseButton.TextTransparency = 1
BaseButton.AutoButtonColor = false

local UICorner_Base = Instance.new("UICorner")
UICorner_Base.CornerRadius = UDim.new(0, 12)
UICorner_Base.Parent = BaseButton

local BaseStroke = Instance.new("UIStroke")
BaseStroke.Parent = BaseButton
BaseStroke.Color = Color3.fromRGB(0, 80, 200)
BaseStroke.Thickness = 2
BaseStroke.Transparency = 0.5

local TweenStealButton = Instance.new("TextButton")
TweenStealButton.Name = "TweenStealButton"
TweenStealButton.Parent = Content
TweenStealButton.BackgroundColor3 = Color3.fromRGB(0, 120, 255)
TweenStealButton.TextColor3 = Color3.fromRGB(255, 255, 255)
TweenStealButton.Position = UDim2.new(0.1, 0, 0.55, 0)
TweenStealButton.Size = UDim2.new(0.8, 0, 0, 50)
TweenStealButton.Font = Enum.Font.GothamSemibold
TweenStealButton.Text = "TWEEN STEAL"
TweenStealButton.TextSize = 18
TweenStealButton.TextWrapped = true
TweenStealButton.TextTransparency = 1
TweenStealButton.AutoButtonColor = false

local UICorner_TweenSteal = Instance.new("UICorner")
UICorner_TweenSteal.CornerRadius = UDim.new(0, 12)
UICorner_TweenSteal.Parent = TweenStealButton

local TweenStealStroke = Instance.new("UIStroke")
TweenStealStroke.Parent = TweenStealButton
TweenStealStroke.Color = Color3.fromRGB(0, 80, 200)
TweenStealStroke.Thickness = 2
TweenStealStroke.Transparency = 0.5

local StatusLabel = Instance.new("TextLabel")
StatusLabel.Name = "StatusLabel"
StatusLabel.Parent = Content
StatusLabel.BackgroundTransparency = 1
StatusLabel.Size = UDim2.new(0.8, 0, 0, 30)
StatusLabel.Position = UDim2.new(0.1, 0, 0.75, 0)
StatusLabel.Font = Enum.Font.Gotham
StatusLabel.TextColor3 = Color3.fromRGB(255, 255, 255)
StatusLabel.TextSize = 14
StatusLabel.TextTransparency = 1
StatusLabel.Text = ""
StatusLabel.TextWrapped = true

local function createHoverEffect(button, stroke)
    button.MouseEnter:Connect(function()
        TweenService:Create(button, TweenInfo.new(0.2, Enum.EasingStyle.Exponential), {
            BackgroundColor3 = Color3.fromRGB(0, 140, 255),
            TextColor3 = Color3.fromRGB(255, 255, 255)
        }):Play()
        TweenService:Create(stroke, TweenInfo.new(0.2, Enum.EasingStyle.Exponential), {
            Color = Color3.fromRGB(0, 100, 220),
            Thickness = 3,
            Transparency = 0.2
        }):Play()
    end)
    button.MouseLeave:Connect(function()
        TweenService:Create(button, TweenInfo.new(0.2, Enum.EasingStyle.Exponential), {
            BackgroundColor3 = Color3.fromRGB(0, 120, 255),
            TextColor3 = Color3.fromRGB(255, 255, 255)
        }):Play()
        TweenService:Create(stroke, TweenInfo.new(0.2, Enum.EasingStyle.Exponential), {
            Color = Color3.fromRGB(0, 80, 200),
            Thickness = 2,
            Transparency = 0.5
        }):Play()
    end)
end

createHoverEffect(DeliveryButton, DeliveryStroke)
createHoverEffect(BaseButton, BaseStroke)
createHoverEffect(TweenStealButton, TweenStealStroke)

-- Initial animation
task.wait(0.1)
TweenService:Create(Blur, TweenInfo.new(0.6, Enum.EasingStyle.Exponential), {Size = 15}):Play()
TweenService:Create(Frame, TweenInfo.new(0.6, Enum.EasingStyle.Back, Enum.EasingDirection.Out), {
    Size = UDim2.new(0, 450, 0, 360),
    BackgroundTransparency = 0,
    BackgroundColor3 = Color3.fromRGB(10, 10, 15)
}):Play()
DropShadow.Visible = true
TweenService:Create(DropShadow, TweenInfo.new(0.6), {ImageTransparency = 0.6}):Play()

task.wait(0.3)
TweenService:Create(TitleLabel, TweenInfo.new(0.4), {TextTransparency = 0}):Play()
TweenService:Create(CloseButton, TweenInfo.new(0.4), {TextTransparency = 0}):Play()
TweenService:Create(MinimizeButton, TweenInfo.new(0.4), {TextTransparency = 0}):Play()

task.wait(0.2)
TweenService:Create(DeliveryButton, TweenInfo.new(0.4, Enum.EasingStyle.Exponential), {
    TextTransparency = 0,
    BackgroundTransparency = 0
}):Play()
TweenService:Create(DeliveryStroke, TweenInfo.new(0.4, Enum.EasingStyle.Exponential), {Transparency = 0}):Play()
TweenService:Create(BaseButton, TweenInfo.new(0.4, Enum.EasingStyle.Exponential), {
    TextTransparency = 0,
    BackgroundTransparency = 0
}):Play()
TweenService:Create(BaseStroke, TweenInfo.new(0.4, Enum.EasingStyle.Exponential), {Transparency = 0}):Play()
TweenService:Create(TweenStealButton, TweenInfo.new(0.4, Enum.EasingStyle.Exponential), {
    TextTransparency = 0,
    BackgroundTransparency = 0
}):Play()
TweenService:Create(TweenStealStroke, TweenInfo.new(0.4, Enum.EasingStyle.Exponential), {Transparency = 0}):Play()

DeliveryButton.MouseButton1Click:Connect(function()
    DebugInfo("print", "Delivery button clicked", "")
    DeliverBrainrot(StatusLabel)
end)

BaseButton.MouseButton1Click:Connect(function()
    DebugInfo("print", "Base button clicked", "")
    TPNearestBase(StatusLabel)
end)

TweenStealButton.MouseButton1Click:Connect(function()
    DebugInfo("print", "TweenSteal button clicked", "")
    TweenSteal(StatusLabel)
end)

local isMinimized = false
local originalSize = UDim2.new(0, 450, 0, 360)
local minimizedSize = UDim2.new(0, 200, 0, 40)

MinimizeButton.MouseButton1Click:Connect(function()
    isMinimized = not isMinimized
    local targetSize = isMinimized and minimizedSize or originalSize
    local contentTransparency = isMinimized and 1 or 0
    
    TweenService:Create(Frame, TweenInfo.new(0.4, Enum.EasingStyle.Exponential), {
        Size = targetSize,
        BackgroundColor3 = Color3.fromRGB(10, 10, 15)
    }):Play()
    
    TweenService:Create(Content, TweenInfo.new(0.4, Enum.EasingStyle.Exponential), {
        Visible = not isMinimized
    }):Play()
    
    TweenService:Create(DropShadow, TweenInfo.new(0.4), {
        ImageTransparency = 0.6,
        Visible = true
    }):Play()
    
    TweenService:Create(DeliveryButton, TweenInfo.new(0.4, Enum.EasingStyle.Exponential), {
        TextTransparency = contentTransparency,
        BackgroundTransparency = contentTransparency
    }):Play()
    
    TweenService:Create(DeliveryStroke, TweenInfo.new(0.4, Enum.EasingStyle.Exponential), {
        Transparency = contentTransparency
    }):Play()
    
    TweenService:Create(BaseButton, TweenInfo.new(0.4, Enum.EasingStyle.Exponential), {
        TextTransparency = contentTransparency,
        BackgroundTransparency = contentTransparency
    }):Play()
    
    TweenService:Create(BaseStroke, TweenInfo.new(0.4, Enum.EasingStyle.Exponential), {
        Transparency = contentTransparency
    }):Play()
    
    TweenService:Create(TweenStealButton, TweenInfo.new(0.4, Enum.EasingStyle.Exponential), {
        TextTransparency = contentTransparency,
        BackgroundTransparency = contentTransparency
    }):Play()
    
    TweenService:Create(TweenStealStroke, TweenInfo.new(0.4, Enum.EasingStyle.Exponential), {
        Transparency = contentTransparency
    }):Play()
    
    TweenService:Create(StatusLabel, TweenInfo.new(0.4, Enum.EasingStyle.Exponential), {
        TextTransparency = contentTransparency
    }):Play()
    
    MinimizeButton.Text = isMinimized and "□" or "—"
    DebugInfo("print", "Minimize toggled", isMinimized and "Minimized" or "Restored")
end)

CloseButton.MouseButton1Click:Connect(function()
    TweenService:Create(Frame, TweenInfo.new(0.4, Enum.EasingStyle.Exponential), {
        Size = UDim2.new(0, 0, 0, 0),
        BackgroundTransparency = 1
    }):Play()
    TweenService:Create(Blur, TweenInfo.new(0.4), {Size = 0}):Play()
    task.wait(0.4)
    ScreenGui:Destroy()
    Blur:Destroy()
    DebugInfo("print", "Gui closed", "")
end)

local isGuiVisible = true
UserInputService.InputBegan:Connect(function(input, gameProcessedEvent)
    if gameProcessedEvent then return end
    if input.KeyCode == Enum.KeyCode.RightShift then
        isGuiVisible = not isGuiVisible
        if isGuiVisible then
            TweenService:Create(Frame, TweenInfo.new(0.4, Enum.EasingStyle.Back, Enum.EasingDirection.Out), {
                Size = isMinimized and minimizedSize or originalSize,
                BackgroundColor3 = Color3.fromRGB(10, 10, 15),
                BackgroundTransparency = 0
            }):Play()
            TweenService:Create(Blur, TweenInfo.new(0.4), {Size = 15}):Play()
            TweenService:Create(DropShadow, TweenInfo.new(0.4), {
                ImageTransparency = 0.6,
                Visible = true
            }):Play()
            TweenService:Create(Content, TweenInfo.new(0.4), {
                Visible = not isMinimized
            }):Play()
            if not isMinimized then
                TweenService:Create(DeliveryButton, TweenInfo.new(0.4, Enum.EasingStyle.Exponential), {
                    TextTransparency = 0,
                    BackgroundTransparency = 0
                }):Play()
                TweenService:Create(DeliveryStroke, TweenInfo.new(0.4, Enum.EasingStyle.Exponential), {Transparency = 0}):Play()
                TweenService:Create(BaseButton, TweenInfo.new(0.4, Enum.EasingStyle.Exponential), {
                    TextTransparency = 0,
                    BackgroundTransparency = 0
                }):Play()
                TweenService:Create(BaseStroke, TweenInfo.new(0.4, Enum.EasingStyle.Exponential), {Transparency = 0}):Play()
                TweenService:Create(TweenStealButton, TweenInfo.new(0.4, Enum.EasingStyle.Exponential), {
                    TextTransparency = 0,
                    BackgroundTransparency = 0
                }):Play()
                TweenService:Create(TweenStealStroke, TweenInfo.new(0.4, Enum.EasingStyle.Exponential), {Transparency = 0}):Play()
                TweenService:Create(StatusLabel, TweenInfo.new(0.4, Enum.EasingStyle.Exponential), {TextTransparency = 1}):Play()
            end
            DebugInfo("print", "shown", "")
        else
            TweenService:Create(Frame, TweenInfo.new(0.4, Enum.EasingStyle.Exponential), {
                Size = UDim2.new(0, 0, 0, 0),
                BackgroundTransparency = 1
            }):Play()
            TweenService:Create(Blur, TweenInfo.new(0.4), {Size = 0}):Play()
            TweenService:Create(DropShadow, TweenInfo.new(0.4), {ImageTransparency = 1}):Play()
            DebugInfo("print", "ThanHubGui hidden", "")
        end
    end
end)

local dragging = false
local dragInput, dragStart, startPos

TitleBar.InputBegan:Connect(function(input)
    if input.UserInputType == Enum.UserInputType.MouseButton1 then
        dragging = true
        dragStart = input.Position
        startPos = Frame.Position
        input.Changed:Connect(function()
            if input.UserInputState == Enum.UserInputState.End then
                dragging = false
            end
        end)
    end
end)

TitleBar.InputChanged:Connect(function(input)
    if input.UserInputType == Enum.UserInputType.MouseMovement then
        dragInput = input
    end
end)

UserInputService.InputChanged:Connect(function(input)
    if input == dragInput and dragging then
        local delta = input.Position - dragStart
        local goal = UDim2.new(
            startPos.X.Scale,
            startPos.X.Offset + delta.X,
            startPos.Y.Scale,
            startPos.Y.Offset + delta.Y
        )
        Frame:TweenPosition(goal, Enum.EasingDirection.Out, Enum.EasingStyle.Sine, 0.05, true)
    end
end)

DebugInfo("print", "initialization completed", "")
]]

local ScreenGui = Instance.new("ScreenGui")
ScreenGui.Name = "ThanHub"
ScreenGui.ZIndexBehavior = Enum.ZIndexBehavior.Sibling
ScreenGui.IgnoreGuiInset = true
ScreenGui.DisplayOrder = 999
ScreenGui.Parent = Player:WaitForChild("PlayerGui")

local Blur = Instance.new("BlurEffect")
Blur.Name = "ThanHubBlur"
Blur.Size = 0
Blur.Parent = Lighting

local Frame = Instance.new("Frame")
Frame.Parent = ScreenGui
Frame.BackgroundColor3 = Color3.fromRGB(10, 10, 15)
Frame.BorderSizePixel = 0
Frame.AnchorPoint = Vector2.new(0.5, 0.5)
Frame.Position = UDim2.new(0.5, 0, 0.5, 0)
Frame.Size = UDim2.new(0, 0, 0, 0)
Frame.ClipsDescendants = true
Frame.BackgroundTransparency = 1

local Gradient = Instance.new("UIGradient")
Gradient.Color = ColorSequence.new({
    ColorSequenceKeypoint.new(0, Color3.fromRGB(20, 20, 30)),
    ColorSequenceKeypoint.new(1, Color3.fromRGB(10, 10, 20))
})
Gradient.Rotation = 45
Gradient.Parent = Frame

local UICorner = Instance.new("UICorner")
UICorner.CornerRadius = UDim.new(0, 16)
UICorner.Parent = Frame

local DropShadow = Instance.new("ImageLabel")
DropShadow.Name = "DropShadow"
DropShadow.Parent = Frame
DropShadow.AnchorPoint = Vector2.new(0.5, 0.5)
DropShadow.BackgroundTransparency = 1
DropShadow.Position = UDim2.new(0.5, 0, 0.5, 8)
DropShadow.Size = UDim2.new(1, 24, 1, 24)
DropShadow.Image = "rbxassetid://6014261993"
DropShadow.ImageColor3 = Color3.fromRGB(0, 0, 0)
DropShadow.ImageTransparency = 0.6
DropShadow.ScaleType = Enum.ScaleType.Slice
DropShadow.SliceCenter = Rect.new(10, 10, 118, 118)
DropShadow.ZIndex = -1
DropShadow.Visible = false

local TitleBar = Instance.new("Frame")
TitleBar.Name = "TitleBar"
TitleBar.Parent = Frame
TitleBar.BackgroundColor3 = Color3.fromRGB(15, 15, 20)
TitleBar.BorderSizePixel = 0
TitleBar.Size = UDim2.new(1, 0, 0, 40)
TitleBar.ZIndex = 2

local TitleBarGradient = Instance.new("UIGradient")
TitleBarGradient.Color = ColorSequence.new({
    ColorSequenceKeypoint.new(0, Color3.fromRGB(25, 25, 35)),
    ColorSequenceKeypoint.new(1, Color3.fromRGB(15, 15, 25))
})
TitleBarGradient.Parent = TitleBar

local TitleBarCorner = Instance.new("UICorner")
TitleBarCorner.CornerRadius = UDim.new(0, 16)
TitleBarCorner.Parent = TitleBar

local TitleLabel = Instance.new("TextLabel")
TitleLabel.Name = "Title"
TitleLabel.Parent = TitleBar
TitleLabel.BackgroundTransparency = 1
TitleLabel.Size = UDim2.new(1, -80, 1, 0)
TitleLabel.Position = UDim2.new(0, 15, 0, 0)
TitleLabel.Font = Enum.Font.GothamBlack
TitleLabel.Text = "THANHUB"
TitleLabel.TextColor3 = Color3.fromRGB(255, 255, 255)
TitleLabel.TextSize = 20
TitleLabel.TextXAlignment = Enum.TextXAlignment.Left
TitleLabel.TextTransparency = 1

local ButtonFrame = Instance.new("Frame")
ButtonFrame.Parent = TitleBar
ButtonFrame.BackgroundTransparency = 1
ButtonFrame.Size = UDim2.new(0, 80, 1, 0)
ButtonFrame.Position = UDim2.new(1, -80, 0, 0)

local MinimizeButton = Instance.new("TextButton")
MinimizeButton.Name = "MinimizeButton"
MinimizeButton.Parent = ButtonFrame
MinimizeButton.AnchorPoint = Vector2.new(0.5, 0.5)
MinimizeButton.BackgroundTransparency = 1
MinimizeButton.Position = UDim2.new(0.65, 0, 0.5, 0)
MinimizeButton.Size = UDim2.new(0, 24, 0, 24)
MinimizeButton.Font = Enum.Font.GothamBold
MinimizeButton.Text = "—"
MinimizeButton.TextColor3 = Color3.fromRGB(255, 204, 0)
MinimizeButton.TextSize = 16
MinimizeButton.TextTransparency = 1

local CloseButton = Instance.new("TextButton")
CloseButton.Name = "CloseButton"
CloseButton.Parent = ButtonFrame
CloseButton.AnchorPoint = Vector2.new(0.5, 0.5)
CloseButton.BackgroundTransparency = 1
CloseButton.Position = UDim2.new(0.85, 0, 0.5, 0)
CloseButton.Size = UDim2.new(0, 24, 0, 24)
CloseButton.Font = Enum.Font.GothamBold
CloseButton.Text = "X"
CloseButton.TextColor3 = Color3.fromRGB(255, 80, 80)
CloseButton.TextSize = 16
CloseButton.TextTransparency = 1

local Content = Instance.new("Frame")
Content.Name = "Content"
Content.Parent = Frame
Content.BackgroundTransparency = 1
Content.Position = UDim2.new(0, 0, 0, 40)
Content.Size = UDim2.new(1, 0, 1, -40)

local LoadingCircle = Instance.new("Frame")
LoadingCircle.Name = "LoadingCircle"
LoadingCircle.Parent = Content
LoadingCircle.AnchorPoint = Vector2.new(0.5, 0.5)
LoadingCircle.BackgroundTransparency = 1
LoadingCircle.Position = UDim2.new(0.5, 0, 0.5, 0)
LoadingCircle.Size = UDim2.new(0, 40, 0, 40)
LoadingCircle.Visible = true

local Circle1 = Instance.new("Frame")
Circle1.Name = "Circle1"
Circle1.Parent = LoadingCircle
Circle1.AnchorPoint = Vector2.new(0.5, 0.5)
Circle1.BackgroundColor3 = Color3.fromRGB(0, 120, 255)
Circle1.Size = UDim2.new(0, 10, 0, 10)
Circle1.Position = UDim2.new(0.5, 0, 0, 0)
Circle1.BorderSizePixel = 0

local UICorner_Circle1 = Instance.new("UICorner")
UICorner_Circle1.CornerRadius = UDim.new(1, 0)
UICorner_Circle1.Parent = Circle1

local Circle2 = Instance.new("Frame")
Circle2.Name = "Circle2"
Circle2.Parent = LoadingCircle
Circle2.AnchorPoint = Vector2.new(0.5, 0.5)
Circle2.BackgroundColor3 = Color3.fromRGB(0, 120, 255)
Circle2.Size = UDim2.new(0, 10, 0, 10)
Circle2.Position = UDim2.new(0.5, 0, 0, 0)
Circle2.BorderSizePixel = 0

local UICorner_Circle2 = Instance.new("UICorner")
UICorner_Circle2.CornerRadius = UDim.new(1, 0)
UICorner_Circle2.Parent = Circle2

-- Initial animation
task.wait(0.1)
TweenService:Create(Blur, TweenInfo.new(0.6, Enum.EasingStyle.Exponential), {Size = 15}):Play()
TweenService:Create(Frame, TweenInfo.new(0.6, Enum.EasingStyle.Back, Enum.EasingDirection.Out), {
    Size = UDim2.new(0, 450, 0, 320),
    BackgroundTransparency = 0
}):Play()
DropShadow.Visible = true
TweenService:Create(DropShadow, TweenInfo.new(0.6), {ImageTransparency = 0.6}):Play()

task.wait(0.3)
TweenService:Create(TitleLabel, TweenInfo.new(0.4), {TextTransparency = 0}):Play()
TweenService:Create(CloseButton, TweenInfo.new(0.4), {TextTransparency = 0}):Play()
TweenService:Create(MinimizeButton, TweenInfo.new(0.4), {TextTransparency = 0}):Play()

-- Start loading animation
local angle = 0
local connection
connection = RunService.Heartbeat:Connect(function(delta)
    angle = (angle + delta * 10) % (2 * math.pi)
    Circle1.Position = UDim2.new(0.5 + math.cos(angle) * 0.4, 0, 0.5 + math.sin(angle) * 0.4, 0)
    Circle2.Position = UDim2.new(0.5 + math.cos(angle + math.pi) * 0.4, 0, 0.5 + math.sin(angle + math.pi) * 0.4, 0)
end)

task.wait(1.2)
connection:Disconnect()
LoadingCircle:Destroy()

-- Load the main script
TweenService:Create(Frame, TweenInfo.new(0.4, Enum.EasingStyle.Exponential), {
    Size = UDim2.new(0, 0, 0, 0),
    BackgroundTransparency = 1
}):Play()

TweenService:Create(Blur, TweenInfo.new(0.4), {Size = 0}):Play()

task.wait(0.4)
ScreenGui:Destroy()
Blur:Destroy()

local success, errorMsg = pcall(function()
    local func = loadstring(scriptToLoad)
    if not func then
        error("Failed to compile scriptToLoad")
    end
    func()
end)

if not success then
    warn("ERROR: Failed to execute scriptToLoad: " .. tostring(errorMsg))
else
    print("Successfully executed script Load")
end

local isGuiVisible = true
UIS.InputBegan:Connect(function(input, gameProcessedEvent)
    if gameProcessedEvent then return end
    if input.KeyCode == Enum.KeyCode.RightShift then
        isGuiVisible = not isGuiVisible
        if isGuiVisible then
            TweenService:Create(Frame, TweenInfo.new(0.4, Enum.EasingStyle.Back, Enum.EasingDirection.Out), {
                Size = UDim2.new(0, 450, 0, 320),
                BackgroundColor3 = Color3.fromRGB(10, 10, 15),
                BackgroundTransparency = 0
            }):Play()
            TweenService:Create(Blur, TweenInfo.new(0.4), {Size = 15}):Play()
            TweenService:Create(DropShadow, TweenInfo.new(0.4), {
                ImageTransparency = 0.6,
                Visible = true
            }):Play()
        else
            TweenService:Create(Frame, TweenInfo.new(0.4, Enum.EasingStyle.Exponential), {
                Size = UDim2.new(0, 0, 0, 0),
                BackgroundTransparency = 1
            }):Play()
            TweenService:Create(Blur, TweenInfo.new(0.4), {Size = 0}):Play()
            TweenService:Create(DropShadow, TweenInfo.new(0.4), {ImageTransparency = 1}):Play()
        end
    end
end)

local dragging = false
local dragInput, dragStart, startPos

TitleBar.InputBegan:Connect(function(input)
    if input.UserInputType == Enum.UserInputType.MouseButton1 then
        dragging = true
        dragStart = input.Position
        startPos = Frame.Position
        input.Changed:Connect(function()
            if input.UserInputState == Enum.UserInputState.End then
                dragging = false
            end
        end)
    end
end)

TitleBar.InputChanged:Connect(function(input)
    if input.UserInputType == Enum.UserInputType.MouseMovement then
        dragInput = input
    end
end)

UIS.InputChanged:Connect(function(input)
    if input == dragInput and dragging then
        local delta = input.Position - dragStart
        local goal = UDim2.new(
            startPos.X.Scale,
            startPos.X.Offset + delta.X,
            startPos.Y.Scale,
            startPos.Y.Offset + delta.Y
        )
        Frame:TweenPosition(goal, Enum.EasingDirection.Out, Enum.EasingStyle.Sine, 0.05, true)
    end
end)