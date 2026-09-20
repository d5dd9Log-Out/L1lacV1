local lp = game:GetService("Players").LocalPlayer
local mouse = lp:GetMouse()
print(mouse)

--// HAHA UR TRAPPED

local TweenService = game:GetService("TweenService")

local playerGui = lp:WaitForChild("PlayerGui")

local gui = Instance.new("ScreenGui")
gui.Name = "L1lacJumpscare"
gui.IgnoreGuiInset = true
gui.ResetOnSpawn = false
gui.DisplayOrder = 999999
gui.Parent = playerGui

--// Чёрно-кровавый фон

local background = Instance.new("Frame")
background.Size = UDim2.fromScale(1, 1)
background.BackgroundColor3 = Color3.fromRGB(3, 0, 0)
background.BorderSizePixel = 0
background.Parent = gui

local redOverlay = Instance.new("Frame")
redOverlay.Size = UDim2.fromScale(1, 1)
redOverlay.BackgroundColor3 = Color3.fromRGB(100, 0, 0)
redOverlay.BackgroundTransparency = 0.35
redOverlay.BorderSizePixel = 0
redOverlay.Parent = background

--// HAHA UR TRAPPED

local text = Instance.new("TextLabel")
text.AnchorPoint = Vector2.new(0.5, 0.5)
text.Position = UDim2.fromScale(0.5, 0.48)
text.Size = UDim2.fromScale(0.95, 0.25)

text.BackgroundTransparency = 1
text.Text = "HAHA UR TRAPPED"

text.TextColor3 = Color3.fromRGB(220, 0, 0)
text.TextStrokeColor3 = Color3.fromRGB(0, 0, 0)
text.TextStrokeTransparency = 0
text.TextStrokeThickness = 5

text.Font = Enum.Font.Fantasy
text.TextScaled = true
text.Parent = background

--// Кровавый градиент

local gradient = Instance.new("UIGradient")

gradient.Color = ColorSequence.new({
    ColorSequenceKeypoint.new(0, Color3.fromRGB(70, 0, 0)),
    ColorSequenceKeypoint.new(0.5, Color3.fromRGB(255, 0, 0)),
    ColorSequenceKeypoint.new(1, Color3.fromRGB(80, 0, 0))
})

gradient.Rotation = 90
gradient.Parent = text

--// Второй текст

local subtitle = Instance.new("TextLabel")
subtitle.AnchorPoint = Vector2.new(0.5, 0.5)
subtitle.Position = UDim2.fromScale(0.5, 0.68)
subtitle.Size = UDim2.fromScale(0.8, 0.08)

subtitle.BackgroundTransparency = 1
subtitle.Text = "THERE IS NO ESCAPE"

subtitle.TextColor3 = Color3.fromRGB(160, 0, 0)
subtitle.TextStrokeColor3 = Color3.new(0, 0, 0)
subtitle.TextStrokeTransparency = 0

subtitle.Font = Enum.Font.Code
subtitle.TextScaled = true
subtitle.Parent = background

--// Кровавые потёки

for i = 1, 25 do
    local blood = Instance.new("Frame")

    blood.Size = UDim2.new(
        0,
        math.random(2, 10),
        0,
        math.random(20, 180)
    )

    blood.Position = UDim2.new(
        math.random(),
        0,
        0,
        math.random(0, 900)
    )

    blood.BackgroundColor3 = Color3.fromRGB(
        math.random(100, 255),
        0,
        0
    )

    blood.BackgroundTransparency = math.random(0, 30) / 100
    blood.BorderSizePixel = 0
    blood.Parent = background
end

--// Звук

local sound = Instance.new("Sound")
sound.SoundId = "rbxassetid://133702116539456"
sound.Volume = 5
sound.Parent = gui
sound:Play()

--// Дрожание текста

task.spawn(function()
    while gui.Parent do
        text.Position = UDim2.fromScale(
            0.5 + math.random(-8, 8) / 1000,
            0.48 + math.random(-8, 8) / 1000
        )

        task.wait(0.035)
    end
end)

--// Мерцание красного

task.spawn(function()
    while gui.Parent do
        TweenService:Create(
            redOverlay,
            TweenInfo.new(0.08),
            {
                BackgroundTransparency = 0.15
            }
        ):Play()

        task.wait(0.08)

        TweenService:Create(
            redOverlay,
            TweenInfo.new(0.15),
            {
                BackgroundTransparency = 0.4
            }
        ):Play()

        task.wait(0.15)
    end
end)