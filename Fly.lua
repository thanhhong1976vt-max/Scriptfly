
-- Fly Mobile for Roblox Studio
-- FLY: bật/tắt bay
-- Joystick: di chuyển
-- UP / DOWN: bay lên / xuống
-- SPEED: tốc độ bay

local Players = game:GetService("Players")
local RunService = game:GetService("RunService")

local player = Players.LocalPlayer
local flying = false
local speed = 60
local connection, attachment, velocity
local gui = Instance.new("ScreenGui")
gui.Name = "FlyMobile"
gui.ResetOnSpawn = false
gui.Parent = player:WaitForChild("PlayerGui")

local function makeButton(name, text, pos, size)
    local b = Instance.new("TextButton")
    b.Name = name
    b.Text = text
    b.Position = pos
    b.Size = size
    b.BackgroundColor3 = Color3.fromRGB(35, 130, 255)
    b.TextColor3 = Color3.new(1, 1, 1)
    b.TextScaled = true
    b.Parent = gui
    Instance.new("UICorner", b).CornerRadius =
        UDim.new(0, 12)
    return b
end

local flyButton = makeButton(
    "FlyToggle", "FLY: OFF",
    UDim2.new(1, -145, 0.55, 0),
    UDim2.fromOffset(125, 50)
)

local upButton = makeButton(
    "FlyUp", "▲",
    UDim2.new(1, -100, 0.68, 0),
    UDim2.fromOffset(55, 50)
)

local downButton = makeButton(
    "FlyDown", "▼",
    UDim2.new(1, -100, 0.78, 0),
    UDim2.fromOffset(55, 50)
)

local speedButton = makeButton(
    "FlySpeed", "SPEED: 60",
    UDim2.new(1, -160, 0.88, 0),
    UDim2.fromOffset(140, 40)
)

local vertical = 0

local function stopFly()
    flying = false
    vertical = 0

    if connection then connection:Disconnect() end
    connection = nil

    if velocity then velocity:Destroy() end
    if attachment then attachment:Destroy() end

    velocity = nil
    attachment = nil
    flyButton.Text = "FLY: OFF"
end

local function startFly()
    local character = player.Character
    local humanoid = character
        and character:FindFirstChildOfClass("Humanoid")
    local root = character
        and character:FindFirstChild("HumanoidRootPart")

    if not humanoid or not root then return end

    stopFly()
    flying = true

    attachment = Instance.new("Attachment")
    attachment.Parent = root

    velocity = Instance.new("LinearVelocity")
    velocity.Attachment0 = attachment
    velocity.RelativeTo = Enum.ActuatorRelativeTo.World
    velocity.MaxForce = 100000
    velocity.VectorVelocity = Vector3.zero
    velocity.Parent = root

    humanoid:ChangeState(Enum.HumanoidStateType.Physics)
    flyButton.Text = "FLY: ON"

    connection = RunService.RenderStepped:Connect(function()
        if not root.Parent then
            stopFly()
            return
        end

        local humanoidNow = character:FindFirstChildOfClass("Humanoid")
        local camera = workspace.CurrentCamera
        if not humanoidNow or not camera then return end

        local move = humanoidNow.MoveDirection
        velocity.VectorVelocity =
            move * speed + Vector3.new(0, vertical * speed, 0)
    end)
end

flyButton.Activated:Connect(function()
    if flying then stopFly() else startFly() end
end)

upButton.InputBegan:Connect(function(input)
    if input.UserInputType == Enum.UserInputType.Touch
        or input.UserInputType == Enum.UserInputType.MouseButton1 then
        vertical = 1
    end
end)

upButton.InputEnded:Connect(function()
    vertical = 0
end)

downButton.InputBegan:Connect(function(input)
    if input.UserInputType == Enum.UserInputType.Touch
        or input.UserInputType == Enum.UserInputType.MouseButton1 then
        vertical = -1
    end
end)

downButton.InputEnded:Connect(function()
    vertical = 0
end)

speedButton.Activated:Connect(function()
    speed = speed + 20
    if speed > 120 then speed = 40 end
    speedButton.Text = "SPEED: " .. speed
end)

player.CharacterAdded:Connect(function()
    stopFly()
end)
