-- 3v3 Arena Ultimate VIP Stealth Hub (Single-Instance & iPad Fixed)
local Players = game:GetService("Players")
local RunService = game:GetService("RunService")
local CoreGui = game:GetService("CoreGui")
local UserInputService = game:GetService("UserInputService")
local Camera = workspace.CurrentCamera
local LocalPlayer = Players.LocalPlayer

----------------------------------------------------
-- 1. CLEANUP PREVIOUS INSTANCES (PREVENT OVERLAP)
----------------------------------------------------
if _G.Arena3v3Connections then
    for _, conn in pairs(_G.Arena3v3Connections) do
        if conn and typeof(conn) == "RBXScriptConnection" then
            conn:Disconnect()
        end
    end
end
_G.Arena3v3Connections = {}

if CoreGui:FindFirstChild("Arena3v3VIPHub") then
    CoreGui.Arena3v3VIPHub:Destroy()
end

for _, v in pairs(workspace:GetDescendants()) do
    if v:IsA("Highlight") and v.Name == "VIP_ESP_Highlight" then
        v:Destroy()
    end
end

----------------------------------------------------
-- 2. CREATE UI ELEMENTS
----------------------------------------------------
local ScreenGui = Instance.new("ScreenGui")
ScreenGui.Name = "Arena3v3VIPHub"
ScreenGui.Parent = CoreGui
ScreenGui.ResetOnSpawn = false

-- Floating VIP Button
local ToggleButton = Instance.new("TextButton")
ToggleButton.Name = "ToggleButton"
ToggleButton.Parent = ScreenGui
ToggleButton.BackgroundColor3 = Color3.fromRGB(25, 25, 35)
ToggleButton.Position = UDim2.new(0.03, 0, 0.2, 0)
ToggleButton.Size = UDim2.new(0, 55, 0, 55)
ToggleButton.Font = Enum.Font.FredokaOne
ToggleButton.Text = "👑 VIP"
ToggleButton.TextColor3 = Color3.fromRGB(255, 215, 0)
ToggleButton.TextSize = 16
ToggleButton.Active = true

local ToggleCorner = Instance.new("UICorner")
ToggleCorner.CornerRadius = UDim.new(1, 0)
ToggleCorner.Parent = ToggleButton

-- Main VIP Window Frame
local MainFrame = Instance.new("Frame")
MainFrame.Name = "MainFrame"
MainFrame.Parent = ScreenGui
MainFrame.BackgroundColor3 = Color3.fromRGB(15, 15, 22)
MainFrame.Position = UDim2.new(0.15, 0, 0.15, 0)
MainFrame.Size = UDim2.new(0, 420, 0, 320)
MainFrame.Visible = true
MainFrame.Active = true

local MainCorner = Instance.new("UICorner")
MainCorner.CornerRadius = UDim.new(0, 12)
MainCorner.Parent = MainFrame

-- Draggable Header
local TitleLabel = Instance.new("TextLabel")
TitleLabel.Name = "TitleLabel"
TitleLabel.Parent = MainFrame
TitleLabel.BackgroundColor3 = Color3.fromRGB(30, 30, 45)
TitleLabel.Size = UDim2.new(1, 0, 0, 45)
TitleLabel.Font = Enum.Font.FredokaOne
TitleLabel.Text = "  👑 3v3 Arena VIP Hub [Clean & Fixed]"
TitleLabel.TextColor3 = Color3.fromRGB(255, 215, 0)
TitleLabel.TextSize = 15
TitleLabel.TextXAlignment = Enum.TextXAlignment.Left

local TitleCorner = Instance.new("UICorner")
TitleCorner.CornerRadius = UDim.new(0, 12)
TitleCorner.Parent = TitleLabel

----------------------------------------------------
-- 3. TOUCH & DRAG MECHANICS (iPad Safe)
----------------------------------------------------
local function MakeDraggable(guiObject)
    local dragging, dragInput, dragStart, startPos

    local function update(input)
        local delta = input.Position - dragStart
        guiObject.Position = UDim2.new(startPos.X.Scale, startPos.X.Offset + delta.X, startPos.Y.Scale, startPos.Y.Offset + delta.Y)
    end

    guiObject.InputBegan:Connect(function(input)
        if input.UserInputType == Enum.UserInputType.MouseButton1 or input.UserInputType == Enum.UserInputType.Touch then
            dragging = true
            dragStart = input.Position
            startPos = guiObject.Position
            input.Changed:Connect(function()
                if input.UserInputState == Enum.UserInputState.End then
                    dragging = false
                end
            end)
        end
    end)

    guiObject.InputChanged:Connect(function(input)
        if input.UserInputType == Enum.UserInputType.MouseMovement or input.UserInputType == Enum.UserInputType.Touch then
            dragInput = input
        end
    end)

    UserInputService.InputChanged:Connect(function(input)
        if input == dragInput and dragging then
            update(input)
        end
    end)
end

MakeDraggable(MainFrame)
MakeDraggable(ToggleButton)

-- Reliable Single-Tap Toggle Button
local lastToggleTime = 0
ToggleButton.MouseButton1Click:Connect(function()
    if os.clock() - lastToggleTime > 0.2 then
        lastToggleTime = os.clock()
        MainFrame.Visible = not MainFrame.Visible
    end
end)

----------------------------------------------------
-- 4. SETTINGS & AIMBOT FOV
----------------------------------------------------
local Settings = {
    Aimbot = false,
    FOV = 120,
    ESP = false
}

local FOVCircle = Drawing.new("Circle")
FOVCircle.Visible = false
FOVCircle.Radius = Settings.FOV
FOVCircle.Color = Color3.fromRGB(255, 215, 0)
FOVCircle.Thickness = 2
FOVCircle.Filled = false
FOVCircle.Transparency = 0.8
FOVCircle.Position = Vector2.new(Camera.ViewportSize.X / 2, Camera.ViewportSize.Y / 2)

----------------------------------------------------
-- 5. UI CONTROLS BUILDER
----------------------------------------------------
local function CreateButton(name, posY, callback)
    local btn = Instance.new("TextButton")
    btn.Parent = MainFrame
    btn.BackgroundColor3 = Color3.fromRGB(35, 35, 50)
    btn.Position = UDim2.new(0.05, 0, 0, posY)
    btn.Size = UDim2.new(0.9, 0, 0, 42)
    btn.Font = Enum.Font.SourceSansBold
    btn.Text = name .. ": [OFF]"
    btn.TextColor3 = Color3.fromRGB(255, 255, 255)
    btn.TextSize = 16

    local corner = Instance.new("UICorner")
    corner.CornerRadius = UDim.new(0, 8)
    corner.Parent = btn

    local state = false
    btn.MouseButton1Click:Connect(function()
        state = not state
        btn.BackgroundColor3 = state and Color3.fromRGB(0, 180, 100) or Color3.fromRGB(35, 35, 50)
        btn.Text = name .. (state and ": [ON]" or ": [OFF]")
        callback(state)
    end)
    return btn
end

----------------------------------------------------
-- 6. CORE FEATURES (ESP & AIMBOT)
----------------------------------------------------
local espHighlights = {}

local espConn = RunService.RenderStepped:Connect(function()
    pcall(function()
        if Settings.ESP then
            for _, player in pairs(Players:GetPlayers()) do
                -- Only highlight real ENEMIES (different team or not self)
                if player ~= LocalPlayer and player.Character and (not player.Team or player.Team ~= LocalPlayer.Team) then
                    local char = player.Character
                    if not espHighlights[player] or espHighlights[player].Parent ~= char then
                        if espHighlights[player] then espHighlights[player]:Destroy() end
                        
                        local hl = Instance.new("Highlight")
                        hl.Name = "VIP_ESP_Highlight"
                        hl.Parent = char
                        hl.Adornee = char
                        hl.DepthMode = Enum.HighlightDepthMode.AlwaysOnTop
                        hl.FillColor = Color3.fromRGB(255, 50, 50) -- Red for Enemies Only
                        hl.OutlineColor = Color3.fromRGB(255, 255, 255)
                        espHighlights[player] = hl
                    end
                elseif espHighlights[player] then
                    espHighlights[player]:Destroy()
                    espHighlights[player] = nil
                end
            end
        else
            for _, hl in pairs(espHighlights) do
                if hl then hl:Destroy() end
            end
            espHighlights = {}
        end
    end)
end)
table.insert(_G.Arena3v3Connections, espConn)

local function GetClosestEnemy()
    local target, shortest = nil, Settings.FOV
    for _, p in pairs(Players:GetPlayers()) do
        if p ~= LocalPlayer and p.Character and p.Character:FindFirstChild("Head") and (not p.Team or p.Team ~= LocalPlayer.Team) then
            local char = p.Character
            local hum = char:FindFirstChildOfClass("Humanoid")
            if hum and hum.Health > 0 then
                local head = char.Head
                local pos, onScreen = Camera:WorldToViewportPoint(head.Position)
                if onScreen then
                    local dist = (Vector2.new(pos.X, pos.Y) - Vector2.new(Camera.ViewportSize.X / 2, Camera.ViewportSize.Y / 2)).Magnitude
                    if dist < shortest then
                        shortest = dist
                        target = head
                    end
                end
            end
        end
    end
    return target
end

local aimConn = RunService.RenderStepped:Connect(function()
    pcall(function()
        FOVCircle.Position = Vector2.new(Camera.ViewportSize.X / 2, Camera.ViewportSize.Y / 2)
        if Settings.Aimbot then
            local t = GetClosestEnemy()
            if t then
                Camera.CFrame = CFrame.new(Camera.CFrame.Position, t.Position)
            end
        end
    end)
end)
table.insert(_G.Arena3v3Connections, aimConn)

----------------------------------------------------
-- 7. MOUNT UI CONTROLS
----------------------------------------------------
CreateButton("ESP Wallhack (Enemies Red)", 65, function(v) Settings.ESP = v end)
CreateButton("Aimbot (Head Lock + FOV)", 125, function(v) Settings.Aimbot = v FOVCircle.Visible = v end)

print("3v3 Arena VIP Hub Clean Instance Loaded!")
