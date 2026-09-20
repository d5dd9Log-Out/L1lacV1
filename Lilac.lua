
--==================================================================
--   "FINAL HOURS"  --  anti-cheat punishment screen
--   SINGLE-FILE EXECUTOR SCRIPT  (no server script required)
--
--   Executors run with elevated thread identity, so the local
--   player can be kicked directly from this script.
--==================================================================

--=========================== SERVICES =============================

local Players         = game:GetService("Players")
local TweenService    = game:GetService("TweenService")
local ContentProvider = game:GetService("ContentProvider")
local SoundService    = game:GetService("SoundService")
local RunService      = game:GetService("RunService")

local LocalPlayer = Players.LocalPlayer
local playerGui   = LocalPlayer:WaitForChild("PlayerGui", 20)
if not playerGui then
	playerGui = game:GetService("CoreGui") -- fallback, keeps it on screen regardless
end

local rng = Random.new()

--============================ CONFIG ==============================

local IMAGE_IDS = {
	129479498204701, -- 1
	132136401230988, -- 2
	103887570225764, -- 3
	75210308468406,  -- 4
	88243109225877,  -- 5
	84609606642935,  -- 6
	105055458373791, -- 7
	120146372014827, -- 8
}

local AUDIO_ID     = 132884111463673
local AUDIO_VOLUME = 3

local KICK_MESSAGE = "you have 12 hours before you are banned… enjoy your final hours."

-- Background / jitter
local BG_SCALE         = 2.5     -- 2 = exactly double screen
local JITTER_SCALE     = 0.26    -- normal shake
local HARD_JOLT_SCALE  = 0.50    -- violent shake (must stay under (BG_SCALE-1)/2 = 0.75)
local JITTER_RATE      = 0.045
local IMAGE_INTERVAL   = 0.15
local IMAGE_SCALE_TYPE = Enum.ScaleType.Crop

-- Timing
local FADE_IN         = 1.0
local HOLD            = 1.0
local FADE_OUT        = 0.5
local GLITCH_DELAY    = 0.5   -- after fully faded in, before colour cycling
local GLITCH_INTERVAL = 0.2
local START_DELAY     = 1.0
local KICK_DELAY      = 0.6

-- Glitch intensity: baseline during the whole run, maxed during glitch
local BASE_GLITCH = 0.25
local glitchPower = BASE_GLITCH

-- Colour cycling order
local GLITCH_COLORS = {
	Color3.fromRGB(0, 140, 255),  -- bright blue
	Color3.fromRGB(0, 255, 40),   -- bright green
	Color3.fromRGB(255, 0, 230),  -- bright pink
	Color3.fromRGB(255, 150, 0),  -- bright orange
	Color3.fromRGB(140, 0, 0),    -- darkish red
	Color3.fromRGB(70, 0, 130),   -- darkish purple
}

-- Colours used by the screen-tear bars
local TEAR_COLORS = {
	Color3.fromRGB(255, 255, 255),
	Color3.fromRGB(0, 0, 0),
	Color3.fromRGB(0, 255, 60),
	Color3.fromRGB(255, 0, 200),
	Color3.fromRGB(120, 200, 255),
	Color3.fromRGB(160, 0, 0),
}

local GLYPHS = {
	"#","@","%","&","$","?","!","*","/","\\","|","~","^","<",">",
	"[","]","{","}","(",")","=","+","-","_","0","1","2","3","4","5",
	"6","7","8","9",
}

local TEXTS = {
	"if you are seeing this you might be wondering..",
	"why have i been brought here?",
	"you tried to cheat.. in a roblox game.",
	"so now, i have put a line of code that will get you anticheat banned!",
}

--=========================== BUILD GUI ============================

local old = playerGui:FindFirstChild("FinalHoursOverlay")
if old then old:Destroy() end

local gui = Instance.new("ScreenGui")
gui.Name           = "FinalHoursOverlay"
gui.ResetOnSpawn   = false
gui.IgnoreGuiInset = true
gui.DisplayOrder   = 999999999
gui.ZIndexBehavior = Enum.ZIndexBehavior.Sibling
gui.Parent         = playerGui

-------------------------------------------------------------------
-- Oversized background container
-------------------------------------------------------------------
local bgFrame = Instance.new("Frame")
bgFrame.Name             = "GlitchBackground"
bgFrame.AnchorPoint      = Vector2.new(0.5, 0.5)
bgFrame.Position         = UDim2.fromScale(0.5, 0.5)
bgFrame.Size             = UDim2.fromScale(BG_SCALE, BG_SCALE)
bgFrame.BackgroundColor3 = Color3.fromRGB(0, 0, 0)
bgFrame.BorderSizePixel  = 0
bgFrame.ZIndex           = 1
bgFrame.Parent           = gui

local function assetID(id) return "rbxassetid://" .. tostring(id) end
local function thumbID(id) return "rbxthumb://type=Asset&id=" .. tostring(id) .. "&w=1024&h=1024" end

local imageLabels = {}
for i, id in ipairs(IMAGE_IDS) do
	local lbl = Instance.new("ImageLabel")
	lbl.Name                   = "Slide" .. i
	lbl.Position               = UDim2.fromScale(0, 0)
	lbl.Size                   = UDim2.fromScale(1, 1)
	lbl.BackgroundTransparency = 1
	lbl.BorderSizePixel        = 0
	lbl.Image                  = assetID(id)
	lbl.ScaleType              = IMAGE_SCALE_TYPE
	lbl.Visible                = (i == 1)
	lbl.ZIndex                 = 1
	lbl.Parent                 = bgFrame
	imageLabels[i] = lbl
end

-------------------------------------------------------------------
-- Text layer
-------------------------------------------------------------------
local textFrame = Instance.new("Frame")
textFrame.Name                   = "TextLayer"
textFrame.AnchorPoint            = Vector2.new(0.5, 0.5)
textFrame.Position               = UDim2.fromScale(0.5, 0.5)
textFrame.Size                   = UDim2.fromScale(1, 1)
textFrame.BackgroundTransparency = 1
textFrame.ZIndex                 = 10
textFrame.Parent                 = gui

local function makeTextLabel(name, zindex)
	local lbl = Instance.new("TextLabel")
	lbl.Name                   = name
	lbl.AnchorPoint            = Vector2.new(0.5, 0.5)
	lbl.Position               = UDim2.fromScale(0.5, 0.5)
	lbl.Size                   = UDim2.new(0.72, 0, 0.22, 0)
	lbl.BackgroundTransparency = 1
	lbl.Font                   = Enum.Font.Code
	lbl.TextScaled             = true
	lbl.TextWrapped            = true
	lbl.TextXAlignment         = Enum.TextXAlignment.Center
	lbl.TextYAlignment         = Enum.TextYAlignment.Center
	lbl.TextColor3             = Color3.fromRGB(255, 255, 255)
	lbl.TextStrokeColor3       = Color3.fromRGB(0, 0, 0)
	lbl.TextStrokeTransparency = 1
	lbl.TextTransparency       = 1
	lbl.Text                   = ""
	lbl.ZIndex                 = zindex
	lbl.Parent                 = textFrame

	local limit = Instance.new("UITextSizeConstraint")
	limit.MaxTextSize = 26
	limit.MinTextSize = 8
	limit.Parent = lbl

	return lbl
end

local textLabel = makeTextLabel("GlitchText", 11)
local ghostR    = makeTextLabel("GhostRed",   10)
local ghostB    = makeTextLabel("GhostBlue",   9)
ghostR.TextColor3 = Color3.fromRGB(255, 0, 60)   -- red fringe
ghostB.TextColor3 = Color3.fromRGB(0, 220, 255)  -- cyan fringe

--=========================== FX LAYERS ============================

-- Screen-tear bars
local tearBars = {}
for i = 1, 8 do
	local bar = Instance.new("Frame")
	bar.Name                   = "Tear" .. i
	bar.BackgroundColor3       = Color3.new(1, 1, 1)
	bar.BackgroundTransparency = 1
	bar.BorderSizePixel        = 0
	bar.Size                   = UDim2.new(1, 0, 0, 4)
	bar.Position               = UDim2.new(0, 0, 0, 0)
	bar.ZIndex                 = 45
	bar.Parent                 = gui
	tearBars[i] = bar
end

-- Full-screen strobe
local flash = Instance.new("Frame")
flash.Name                   = "Strobe"
flash.Size                   = UDim2.fromScale(1, 1)
flash.BackgroundColor3       = Color3.new(1, 1, 1)
flash.BackgroundTransparency = 1
flash.BorderSizePixel        = 0
flash.ZIndex                 = 50
flash.Parent                 = gui

--============================ AUDIO ===============================

local sound = Instance.new("Sound")
sound.Name    = "StaticLoop"
sound.SoundId = assetID(AUDIO_ID)
sound.Volume  = AUDIO_VOLUME
sound.Looped  = true
sound.Parent  = SoundService

--================= BACKGROUND LOADING (non-blocking) ==============

task.spawn(function()
	local pass1 = {}
	for _, lbl in ipairs(imageLabels) do table.insert(pass1, lbl) end
	pcall(function() ContentProvider:PreloadAsync(pass1) end)

	local retry = {}
	for i, lbl in ipairs(imageLabels) do
		if not lbl.IsLoaded then
			lbl.Image = thumbID(IMAGE_IDS[i])
			table.insert(retry, lbl)
		end
	end
	if #retry > 0 then
		pcall(function() ContentProvider:PreloadAsync(retry) end)
		for i, lbl in ipairs(imageLabels) do
			if not lbl.IsLoaded then
				warn(("[FinalHours] Image %d (%d) failed to load - asset may be private."):format(i, IMAGE_IDS[i]))
			end
		end
	end
end)

--============================ SYSTEMS =============================

-- Image cycling (0.15s, loops 8 -> 1, random jumps while glitching)
task.spawn(function()
	task.wait(START_DELAY)
	local current = 1
	while gui.Parent do
		local show
		if glitchPower > 0.6 and rng:NextNumber() < 0.25 then
			show = rng:NextInteger(1, #imageLabels) -- random frame jump
		else
			show = current
			current = current % #imageLabels + 1
		end

		imageLabels[show].Visible = true
		for i, lbl in ipairs(imageLabels) do
			if i ~= show then lbl.Visible = false end
		end

		task.wait(IMAGE_INTERVAL)
	end
end)

-- Background jitter / hard jolts
task.spawn(function()
	while gui.Parent do
		local amp = math.min(JITTER_SCALE * (0.5 + glitchPower), HARD_JOLT_SCALE)
		if rng:NextNumber() < 0.05 * glitchPower then
			amp = HARD_JOLT_SCALE -- violent jolt
		end

		local dx = (rng:NextNumber() * 2 - 1) * amp
		local dy = (rng:NextNumber() * 2 - 1) * amp
		bgFrame.Position = UDim2.new(0.5 + dx, 0, 0.5 + dy, 0)

		task.wait(glitchPower > 0.6 and 0.025 or JITTER_RATE)
	end
end)

-- Text jitter + chromatic offset
local textBase    = Vector2.new(0, 0)
local ghostSpread = 0

local function applyTextPositions()
	textLabel.Position = UDim2.new(0.5, textBase.X, 0.5, textBase.Y)
	ghostR.Position    = UDim2.new(0.5, textBase.X + ghostSpread, 0.5, textBase.Y)
	ghostB.Position    = UDim2.new(0.5, textBase.X - ghostSpread, 0.5, textBase.Y)
end

-- Main glitch FX loop (tears, strobe, audio mangling)
task.spawn(function()
	while gui.Parent do
		local power = glitchPower

		-- text shake
		local amp = 1 + math.floor(power * 9)
		textBase = Vector2.new(rng:NextInteger(-amp, amp), rng:NextInteger(-amp, amp))

		-- chromatic split
		if rng:NextNumber() < 0.25 * power + 0.05 then
			ghostSpread = rng:NextInteger(1, 2 + math.floor(power * 6))
		else
			ghostSpread = math.floor(power * 2)
		end
		applyTextPositions()

		-- screen tears
		local cam = workspace.CurrentCamera
		local vh  = cam and cam.ViewportSize.Y or 1080
		for _, bar in ipairs(tearBars) do
			if power > 0.3 and rng:NextNumber() < 0.3 * power then
				bar.Size                   = UDim2.new(1, 0, 0, rng:NextInteger(2, 18))
				bar.Position               = UDim2.new(0, 0, 0, rng:NextInteger(0, math.max(0, vh - 20)))
				bar.BackgroundColor3       = TEAR_COLORS[rng:NextInteger(1, #TEAR_COLORS)]
				bar.BackgroundTransparency = rng:NextNumber() * 0.45 + 0.15
			else
				bar.BackgroundTransparency = 1
			end
		end

		-- strobe flash
		if power > 0.45 and rng:NextNumber() < 0.07 * power then
			if rng:NextNumber() < 0.55 then
				flash.BackgroundColor3 = Color3.new(1, 1, 1)
			else
				flash.BackgroundColor3 = Color3.new(0, 0, 0)
			end
			flash.BackgroundTransparency = rng:NextNumber() * 0.25
		else
			flash.BackgroundTransparency = 1
		end

		-- audio corruption
		if sound.IsPlaying and rng:NextNumber() < 0.15 * power then
			sound.PlaybackSpeed = 0.85 + rng:NextNumber() * 0.6
		end

		task.wait(0.035)
	end
end)

--============================= TEXT ===============================

local GLYPH_MIN = 1 -- ghost visibility floor: 1 = hidden, 0.4 = visible

local function corrupt(str, amount)
	local out = {}
	for i = 1, #str do
		local c = str:sub(i, i)
		if c == " " or rng:NextNumber() >= amount then
			out[i] = c
		else
			out[i] = GLYPHS[rng:NextInteger(1, #GLYPHS)]
		end
	end
	return table.concat(out)
end

local glitchToken = 0

local function showText(str)
	glitchToken += 1
	local token = glitchToken

	textLabel.Text                   = str
	textLabel.TextColor3             = Color3.fromRGB(255, 255, 255)
	textLabel.TextTransparency       = 1
	textLabel.TextStrokeTransparency = 1
	ghostR.Text                      = str
	ghostB.Text                      = str
	ghostR.TextTransparency          = GLYPH_MIN
	ghostB.TextTransparency          = GLYPH_MIN
	textBase    = Vector2.new(0, 0)
	ghostSpread = 0

	-- 1) FADE IN (1 second) into white code text
	TweenService:Create(
		textLabel,
		TweenInfo.new(FADE_IN, Enum.EasingStyle.Linear),
		{ TextTransparency = 0, TextStrokeTransparency = 0 }
	):Play()
	task.wait(FADE_IN)

	-- 2) 0.5s after fully faded in -> full glitch mode
	task.spawn(function()
		task.wait(GLITCH_DELAY)
		if token ~= glitchToken then return end

		glitchPower = 1
		GLYPH_MIN   = 0.4
		ghostR.TextTransparency = 0.4
		ghostB.TextTransparency = 0.4

		local ci = 1
		while token == glitchToken do
			textLabel.TextColor3 = GLITCH_COLORS[ci]
			ci = ci % #GLITCH_COLORS + 1

			local shown = str
			if rng:NextNumber() < 0.8 then
				shown = corrupt(str, 0.18) -- live character corruption
			end
			textLabel.Text = shown
			ghostR.Text    = shown
			ghostB.Text    = shown

			task.wait(GLITCH_INTERVAL)
		end
	end)

	-- 3) HOLD (1 second)
	task.wait(HOLD)

	-- 4) FADE OUT (0.5 second)
	local tw = TweenInfo.new(FADE_OUT, Enum.EasingStyle.Linear)
	TweenService:Create(textLabel, tw, { TextTransparency = 1, TextStrokeTransparency = 1 }):Play()
	TweenService:Create(ghostR,    tw, { TextTransparency = 1 }):Play()
	TweenService:Create(ghostB,    tw, { TextTransparency = 1 }):Play()
	task.wait(FADE_OUT)

	glitchToken += 1
	glitchPower = BASE_GLITCH
	GLYPH_MIN   = 1
	textLabel.Text                   = str
	ghostR.Text                      = str
	ghostB.Text                      = str
	textLabel.TextTransparency       = 1
	textLabel.TextStrokeTransparency = 1
	ghostR.TextTransparency          = 1
	ghostB.TextTransparency          = 1
end

--============================= KICK ===============================

local kicked = false

local function deliverKick(attempt)
	if kicked then return end
	attempt = attempt or 1

	-- Primary: direct local-player kick (works in most executors)
	local ok = pcall(function()
		LocalPlayer:Kick(KICK_MESSAGE)
	end)

	if not ok then
		-- Fallback: some executors lock the instance method table
		ok = pcall(function()
			Players.LocalPlayer:Kick(KICK_MESSAGE)
		end)
	end

	if not ok then
		-- Fallback: raw service call
		ok = pcall(function()
			game:GetService("Players").LocalPlayer:Kick(KICK_MESSAGE)
		end)
	end

	if ok then
		kicked = true
		return
	end

	if attempt < 6 then
		task.delay(0.75, function() deliverKick(attempt + 1) end)
	else
		warn("[FinalHours] Kick call was blocked - leaving the overlay + audio running as a fallback lock.")
	end
end

--============================= RUN ================================

local SEQUENCE_TIME = START_DELAY + (#TEXTS * (FADE_IN + HOLD + FADE_OUT)) + KICK_DELAY

task.spawn(function()
	sound:Play()

	task.wait(START_DELAY)
	for _, line in ipairs(TEXTS) do
		showText(line)
	end

	task.wait(KICK_DELAY)
	deliverKick()
end)

-- Watchdog: fire the kick on schedule even if the sequence thread dies
task.spawn(function()
	task.wait(SEQUENCE_TIME + 1.5)
	deliverKick()
end)

print(("[FinalHours] Armed. Kicking in ~%.1fs."):format(SEQUENCE_TIME))
