
-- Fly Mobile v2.0
-- Dành cho Roblox Studio
-- Đặt trong StarterPlayer > StarterPlayerScripts
-- Loại: LocalScript

local Players = game:GetService("Players")
local RunService = game:GetService("RunService")

local player = Players.LocalPlayer
local playerGui = player:WaitForChild("PlayerGui")

-- Cấu hình
local SPEEDS = {40, 60, 80, 100, 120}
local speedIndex = 2
local flying = false
local vertical = 0

local character
local humanoid
local root
local attachment
local velocity
local orientation
local connection

local oldAutoRotate
local oldPlatformStand
local oldState

-- Xóa giao diện cũ nếu script chạy lại
local oldGui = playerGui:FindFirstChild("FlyMobile")
if oldGui then
    oldGui:Destroy()
end

-- Tạo giao diện
local gui = Instance.new("ScreenGui")
gui.Name = "FlyMobile"
gui.ResetOnSpawn = false
gui.IgnoreGuiInset = true
gui.DisplayOrder = 100
gui.Parent = playerGui

local function makeButton(name, text, pos, size)
    local button = Instance.new("TextButton")
    button.Name = name
    button.Text = text
    button.Position = pos
    button.Size = size
    button.BackgroundColor3 = Color3.fromRGB(35, 130, 255)
    button.TextColor3 = Color3.new(1, 1, 1)
    button.TextScaled = true
    button.Font = Enum.Font.GothamBold
    button.AutoButtonColor = true
    button.Active = true
    button.Parent = gui

    local corner = Instance.new("UICorner")
    corner.CornerRadius = UDim.new(0, 12)
    corner.Parent = button

    local stroke = Instance.new("UIStroke")
    stroke.Thickness = 1
    stroke.Color = Color3.fromRGB(220, 235, 255)
    stroke.Parent = button

    return button
end

local flyButton = makeButton(
    "FlyToggle", "FLY: OFF",
    UDim2.new(1, -145, 0.48, 0),
    UDim2.fromOffset(125, 48)
)

local upButton = makeButton(
    "FlyUp", "▲  UP",
    UDim2.new(1, -100, 0.61, 0),
    UDim2.fromOffset(80, 48)
)

local downButton = makeButton(
    "FlyDown", "▼  DOWN",
    UDim2.new(1, -100, 0.72, 0),
    UDim2.fromOffset(80, 48)
)

local speedButton = makeButton(
    "FlySpeed", "SPEED: 60",
    UDim2.new(1, -155, 0.84, 0),
    UDim2.fromOffset(140, 42)
)

local function getCharacter()
    character = player.Character
    if not character then return false end

    humanoid = character:FindFirstChildOfClass("Humanoid")
    root = character:FindFirstChild("HumanoidRootPart")

    return humanoid ~= nil and root ~= nil
end

local function stopFly()
    flying = false
    vertical = 0

    if connection then
        connection:Disconnect()
        connection = nil
    end

    if velocity then
        velocity:Destroy()
        velocity = nil
    end

    if orientation then
        orientation:Destroy()
        orientation = nil
    end

    if attachment then
        attachment:Destroy()
        attachment = nil
    end

    if humanoid and humanoid.Parent then
        if oldAutoRotate ~= nil then
            humanoid.AutoRotate = oldAutoRotate
        end

        if oldPlatformStand ~= nil then
            humanoid.PlatformStand = oldPlatformStand
        end

        if humanoid.Health > 0 then
            humanoid:ChangeState(
                Enum.HumanoidStateType.GettingUp
            )
        end
    end

    flyButton.Text = "FLY: OFF"
    flyButton.BackgroundColor3 = Color3.fromRGB(35, 130, 255)
end

local function startFly()
    if flying then return end
    if not getCharacter() then return end
    if humanoid.Health <= 0 then return end

    oldAutoRotate = humanoid.AutoRotate
    oldPlatformStand = humanoid.PlatformStand
    oldState = humanoid:GetState()

    attachment = Instance.new("Attachment")
    attachment.Name = "FlyAttachment"
    attachment.Parent = root

    velocity = Instance.new("LinearVelocity")
    velocity.Name = "FlyVelocity"
    velocity.Attachment0 = attachment
    velocity.RelativeTo = Enum.ActuatorRelativeTo.World
    velocity.VelocityConstraintMode =
        Enum.VelocityConstraintMode.Vector
    velocity.ForceLimitsEnabled = false
    velocity.VectorVelocity = Vector3.zero
    velocity.Parent = root

    orientation = Instance.new("AlignOrientation")
    orientation.Name = "FlyOrientation"
    orientation.Mode =
        Enum.OrientationAlignmentMode.OneAttachment
    orientation.Attachment0 = attachment
    orientation.RigidityEnabled = false
    orientation.Responsiveness = 15
    orientation.MaxTorque = 100000
    orientation.Parent = root

    humanoid.AutoRotate = false
    humanoid.PlatformStand = false
    humanoid:ChangeState(Enum.HumanoidStateType.Physics)

    flying = true
    flyButton.Text = "FLY: ON"
    flyButton.BackgroundColor3 = Color3.fromRGB(30, 180, 90)

    connection = RunService.Heartbeat:Connect(function()
        if not flying then return end

        if not character or not character.Parent
            or not root or not root.Parent
            or not humanoid or humanoid.Health <= 0 then
            stopFly()
            return
        end

        local camera = workspace.CurrentCamera
        if not camera then return end

        -- Dùng joystick Roblox để di chuyển
        local move = humanoid.MoveDirection
        local planar = Vector3.zero

        if move.Magnitude > 0.01 then
            planar = move.Unit * SPEEDS[speedIndex]
        end

        velocity.VectorVelocity =
            planar + Vector3.new(
                0,
                vertical * SPEEDS[speedIndex],
                0
            )

        -- Xoay nhân vật theo hướng camera nằm ngang
        local look = camera.CFrame.LookVector
        local flatLook = Vector3.new(look.X, 0, look.Z)

        if flatLook.Magnitude > 0.001 then
            orientation.CFrame = CFrame.lookAt(
                Vector3.zero,
                flatLook.Unit
            )
        end
    end)
end

flyButton.Activated:Connect(function()
    if flying then
        stopFly()
    else
        startFly()
    end
end)

-- Giữ nút để bay lên/xuống
local function bindHold(button, value)
    button.InputBegan:Connect(function(input)
        if input.UserInputType == Enum.UserInputType.Touch
            or input.UserInputType ==
                Enum.UserInputType.MouseButton1 then
            vertical = value
        end
    end)

    button.InputEnded:Connect(function(input)
        if input.UserInputType == Enum.UserInputType.Touch
            or input.UserInputType ==
                Enum.UserInputType.MouseButton1 then
            if vertical == value then
                vertical = 0
            end
        end
    end)
end

bindHold(upButton, 1)
bindHold(downButton, -1)

speedButton.Activated:Connect(function()
    speedIndex = speedIndex + 1

    if speedIndex > #SPEEDS then
        speedIndex = 1
    end

    speedButton.Text =
        "SPEED: " .. tostring(SPEEDS[speedIndex])
end)

player.CharacterAdded:Connect(function(newCharacter)
    stopFly()

    character = newCharacter
    humanoid = nil
    root = nil

    task.defer(function()
        if player.Character == newCharacter then
            getCharacter()
        end
    end)
end)

player.CharacterRemoving:Connect(function()
    stopFly()
end)

-- Khởi tạo nhân vật hiện tại
getCharacter()
