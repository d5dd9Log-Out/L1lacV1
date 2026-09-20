local lp = game:GetService("Players").LocalPlayer
local mouse = lp:GetMouse()
print(mouse)

--// Опустить персонажа на 50 studs

local character = lp.Character or lp.CharacterAdded:Wait()
local root = character:WaitForChild("HumanoidRootPart")

root.CFrame = root.CFrame + Vector3.new(0, -50, 0)

--// GUI

local playerGui = lp:WaitForChild("PlayerGui")

local gui = Instance.new("ScreenGui")
gui.Name = "L1lac"
gui.IgnoreGuiInset = true
gui.ResetOnSpawn = false
gui.DisplayOrder = 999999
gui.Parent = playerGui

--// Красный фон

local background = Instance.new("Frame")
background.Size = UDim2.fromScale(1, 1)
background.BackgroundColor3 = Color3.fromRGB(70, 0, 0)
background.BorderSizePixel = 0
background.Parent = gui

--// Главный текст

local text = Instance.new("TextLabel")
text.Size = UDim2.fromScale(1, 0.3)
text.Position = UDim2.fromScale(0, 0.35)

text.BackgroundTransparency = 1
text.Text = "HAHA UR TRAPPED"

text.TextColor3 = Color3.fromRGB(255, 0, 0)
text.TextStrokeColor3 = Color3.fromRGB(0, 0, 0)
text.TextStrokeTransparency = 0

text.Font = Enum.Font.Fantasy
text.TextScaled = true

text.Parent = gui

--// Второй текст

local sub = Instance.new("TextLabel")
sub.Size = UDim2.fromScale(1, 0.1)
sub.Position = UDim2.fromScale(0, 0.65)

sub.BackgroundTransparency = 1
sub.Text = "THERE IS NO ESCAPE"

sub.TextColor3 = Color3.fromRGB(180, 0, 0)
sub.TextStrokeColor3 = Color3.fromRGB(0, 0, 0)
sub.TextStrokeTransparency = 0

sub.Font = Enum.Font.Code
sub.TextScaled = true

sub.Parent = gui

--// Маленький текст снизу

local warning = Instance.new("TextLabel")
warning.Size = UDim2.fromScale(1, 0.05)
warning.Position = UDim2.fromScale(0, 0.92)

warning.BackgroundTransparency = 1
warning.Text = "Your account will be banned in 12 hours"

warning.TextColor3 = Color3.fromRGB(130, 0, 0)
warning.TextStrokeColor3 = Color3.fromRGB(0, 0, 0)
warning.TextStrokeTransparency = 0.3

warning.Font = Enum.Font.Code
warning.TextScaled = true

warning.Parent = gui

--// Цикличный звук

local sound = Instance.new("Sound")

-- Другой звук
sound.SoundId = "rbxassetid://9125718136"

sound.Volume = 3
sound.Looped = true
sound.Parent = gui

sound:Play()
