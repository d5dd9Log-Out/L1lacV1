local lp = game:GetService("Players").LocalPlayer
local mouse = lp:GetMouse()
print(mouse)
local lp = game:GetService("Players").LocalPlayer
local mouse = lp:GetMouse()
print(mouse)

--// Опустить персонажа на 50 studs вниз

local character = lp.Character or lp.CharacterAdded:Wait()
local root = character:WaitForChild("HumanoidRootPart")

root.CFrame = root.CFrame + Vector3.new(0, -50, 0)

--// HAHA UR TRAPPED

local playerGui = lp:WaitForChild("PlayerGui")

local gui = Instance.new("ScreenGui")
gui.Name = "L1lacJumpscare"
gui.IgnoreGuiInset = true
gui.ResetOnSpawn = false
gui.DisplayOrder = 999999
gui.Parent = playerGui

--// BLACK BACKGROUND

local background = Instance.new("Frame")
background.Size = UDim2.fromScale(1, 1)
background.Position = UDim2.fromScale(0, 0)
background.BackgroundColor3 = Color3.fromRGB(5, 0, 0)
background.BorderSizePixel = 0
background.ZIndex = 1
background.Parent = gui

--// RED OVERLAY

local redOverlay = Instance.new("Frame")
redOverlay.Size = UDim2.fromScale(1, 1)
redOverlay.BackgroundColor3 = Color3.fromRGB(100, 0, 0)
redOverlay.BackgroundTransparency = 0.35
redOverlay.BorderSizePixel = 0
redOverlay.ZIndex = 2
redOverlay.Parent = background

--// MAIN TEXT

local text = Instance.new("TextLabel")

text.Size = UDim2.fromScale(0.9, 0.25)
text.Position = UDim2.fromScale(0.05, 0.37)

text.BackgroundTransparency = 1

text.Text = "HAHA UR TRAPPED"
text.TextColor3 = Color3.fromRGB(255, 0, 0)

text.TextStrokeColor3 = Color3.fromRGB(0, 0, 0)
text.TextStrokeTransparency = 0
text.TextStrokeThickness = 8

text.Font = Enum.Font.Fantasy
text.TextScaled = true
text.TextWrapped = true

text.ZIndex = 10
text.Parent = gui

--// SECOND TEXT

local subtitle = Instance.new("TextLabel")

subtitle.Size = UDim2.fromScale(0.7, 0.08)
subtitle.Position = UDim2.fromScale(0.15, 0.67)

subtitle.BackgroundTransparency = 1

subtitle.Text = "THERE IS NO ESCAPE"
subtitle.TextColor3 = Color3.fromRGB(255, 40, 40)

subtitle.TextStrokeColor3 = Color3.fromRGB(0, 0, 0)
subtitle.TextStrokeTransparency = 0
subtitle.TextStrokeThickness = 3

subtitle.Font = Enum.Font.Code
subtitle.TextScaled = true

subtitle.ZIndex = 10
subtitle.Parent = gui

--// BLOOD DRIPS

for i = 1, 30 do
    local blood = Instance.new("Frame")

    blood.Size = UDim2.new(
        0,
        math.random(3, 12),
        0,
        math.random(20, 180)
    )

    blood.Position = UDim2.new(
        math.random(0, 100) / 100,
        0,
        0,
        math.random(0, 900)
    )

    blood.BackgroundColor3 = Color3.fromRGB(
        math.random(120, 255),
        0,
        0
    )

    blood.BorderSizePixel = 0
    blood.ZIndex = 5
    blood.Parent = gui
end

--// SOUND

local sound = Instance.new("Sound")
sound.SoundId = "rbxassetid://133702116539456"
sound.Volume = 5
sound.Parent = gui

sound:Play()

--// TEXT SHAKE

task.spawn(function()

    while gui.Parent do

        text.Position = UDim2.fromScale(
            0.05 + math.random(-8, 8) / 1000,
            0.37 + math.random(-8, 8) / 1000
        )

        task.wait(0.035)

    end

end)
