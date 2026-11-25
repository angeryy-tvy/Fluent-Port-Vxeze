-- Example: VxezePortV2 with a Home dashboard, tabs, sections, a Global Chat tab (Fluent relay) and a
-- Cloud tab where players share settings presets through vxezestudio.online.
--
-- VxezePortV2 uses positional arguments, not NullUI's option tables:
--   Library:Window({ Title, Game, Version, Id, Key })
--   Window:Tab(name, icon)             Tab:Section(name, icon)
--   Section:Toggle(name, default, callback, description)
--   Section:Slider(name, min, max, default, callback, mode, step, description)
--   Section:Dropdown(name, options, default, callback, multi, description)
--   Section:Input(name, placeholder, callback, description)
--   Section:Button(name, buttonText, callback, color, description)
--   Section:Cards(visibleRows, emptyText, { Columns, Apply, ApplyText, Like })
--   Library:Notify(title, text, "ok" | "info" | "warn" | "err", seconds)
-- Icons are names from the library's built-in set (home, user, zap, settings, server, star, ...).

local Players = game:GetService("Players")
local HttpService = game:GetService("HttpService")
local LocalPlayer = Players.LocalPlayer

-- Same values as Example.luau. Any key shipped in a client script is public.
local GLOBAL_CHAT_ENDPOINT = "https://vxezestudio.online/api/global-chat"
local GLOBAL_CHAT_API_KEY = "olwenth05dzkhoaito"

-- Shared config library (Cloud tab). Uses the same key as the chat; the script id
-- picks which library and tags the server allows ("nullui-example" is demo-only,
-- a real hub uses its own id, e.g. "steal-an-egg").
local CLOUD_CONFIG_ENDPOINT = "https://vxezestudio.online/api/configs"
local CLOUD_CONFIG_SCRIPT = "nullui-example"

local LIBRARY_URL = "https://raw.githubusercontent.com/angeryy-tvy/Fluent-Port-Vxeze/refs/heads/main/VxezePortV2.lua"
-- Optional: set to a workspace file name to test a local build instead of the URL.
local LIBRARY_LOCAL_FILE = nil

local function loadLibrary()
	if LIBRARY_LOCAL_FILE and typeof(isfile) == "function" and isfile(LIBRARY_LOCAL_FILE) then
		return loadstring(readfile(LIBRARY_LOCAL_FILE))()
	end
	return loadstring(game:HttpGetAsync(LIBRARY_URL))()
end

local Library = loadLibrary()

--------------------------------------------------------------------------------
-- Settings that cloud presets save and restore
--------------------------------------------------------------------------------

-- Only controls registered here go into a preset, so UI settings (scale, blur, ...)
-- and the publish form are never shared.
local Flags = {}

local function flag(name, control)
	Flags[name] = control
	return control
end

local function getConfig()
	local out = {}
	for name, control in pairs(Flags) do
		local value = control.Value
		out[name] = typeof(value) == "table" and table.clone(value) or value
	end
	return out
end

local function applyConfig(data)
	local applied = 0
	for name, value in pairs(typeof(data) == "table" and data or {}) do
		local control = Flags[name]
		if control and pcall(control.Set, control, value) then
			applied += 1
		end
	end
	return applied
end

--------------------------------------------------------------------------------
-- Cloud config adapter
--------------------------------------------------------------------------------

local function resolveRequest()
	if typeof(request) == "function" then
		return request
	end
	if typeof(http_request) == "function" then
		return http_request
	end
	if typeof(syn) == "table" and typeof(syn.request) == "function" then
		return syn.request
	end
	return function(req)
		return HttpService:RequestAsync(req)
	end
end

local function CreateCloudConfigService(config)
	local endpoint = config.Endpoint:gsub("/+$", "")
	local httpRequest = resolveRequest()
	local scriptQuery = "script=" .. HttpService:UrlEncode(config.Script)

	local function call(method, path, query, body)
		local ok, res = pcall(httpRequest, {
			Url = endpoint .. path .. "?" .. scriptQuery .. (query or ""),
			Method = method,
			Headers = {
				["Content-Type"] = "application/json",
				["X-Global-Chat-Key"] = config.ApiKey,
				-- Ownership (publish, delete, likes) is tied to the Roblox UserId.
				["X-Player-Id"] = tostring(LocalPlayer.UserId),
			},
			Body = body and HttpService:JSONEncode(body) or nil,
		})
		if not ok or typeof(res) ~= "table" then
			return nil, tostring(res)
		end
		local decoded, data = pcall(HttpService.JSONDecode, HttpService, res.Body or "")
		if not res.Success then
			local msg = decoded and typeof(data) == "table" and data.error
			return nil, msg or res.StatusMessage or "Request failed"
		end
		if not decoded or typeof(data) ~= "table" then
			return nil, "Invalid config response"
		end
		return data
	end

	-- Field names Section:Cards reads.
	local function toCard(item)
		return {
			id = tostring(item.id),
			title = item.name,
			description = item.description,
			tags = typeof(item.tags) == "table" and item.tags or {},
			author = item.ownerName,
			likes = tonumber(item.likes) or 0,
			uses = tonumber(item.downloads) or 0,
			liked = item.liked == true,
		}
	end

	local function toCards(items)
		local out = {}
		for _, item in ipairs(typeof(items) == "table" and items or {}) do
			table.insert(out, toCard(item))
		end
		return out
	end

	local service = {}

	function service:List(sort, q)
		local query = "&sort=" .. HttpService:UrlEncode(sort or "top") .. "&limit=30"
		if q and q ~= "" then
			query ..= "&q=" .. HttpService:UrlEncode(q)
		end
		local data, err = call("GET", "", query)
		if not data then
			return nil, err
		end
		return toCards(data.items)
	end

	function service:ListMine()
		local data, err = call("GET", "/mine")
		if not data then
			return nil, err
		end
		return toCards(data.items)
	end

	function service:Publish(meta)
		local data, err = call("POST", "", nil, {
			script = config.Script,
			name = meta.Name,
			description = meta.Description or "",
			tags = meta.Tags or {},
			data = getConfig(),
		})
		if not data then
			return nil, err
		end
		return toCard(data.item or {})
	end

	function service:Delete(id)
		local data, err = call("DELETE", "/" .. HttpService:UrlEncode(tostring(id)))
		return data ~= nil, err
	end

	-- Toggles: a second press removes the player's like.
	function service:Like(id)
		local data, err = call("POST", "/" .. HttpService:UrlEncode(tostring(id)) .. "/like")
		return data ~= nil, err
	end

	function service:Download(id)
		local data, err = call("POST", "/" .. HttpService:UrlEncode(tostring(id)) .. "/install")
		if not data then
			return nil, err
		end
		return data.data
	end

	return service
end

local CloudService = CreateCloudConfigService({
	Endpoint = CLOUD_CONFIG_ENDPOINT,
	Script = CLOUD_CONFIG_SCRIPT,
	ApiKey = GLOBAL_CHAT_API_KEY,
})

--------------------------------------------------------------------------------
-- Window, tabs and sections
--------------------------------------------------------------------------------

local Window = Library:Window({
	Id = "VxezePortV2 Example",
	Title = "Vxeze Example",
	Game = "Global chat via Fluent relay",
	Version = "v2",
	Key = Enum.KeyCode.RightControl,
})

-- Home dashboard (created first, so it opens by default): header chips, notice card,
-- quick actions (Rejoin / Server hop / Copy Job ID / Unload), changelog and live stats.
local Home = Window:Home({
	Name = "Home",
	Title = "Dashboard",
	Game = game.Name,
	-- Shown on the white card; without it the card offers the Discord invite instead.
	Notice = { "Global chat is live", "Open the Chat tab to talk" },
	-- Discord = "https://discord.gg/your-invite",
	Unload = function()
		Window:Destroy()
	end,
	-- { tag, text, author?, unix time? }; NEW / FIX / IMP / UPD get their own colours.
	News = {
		{ "NEW", "Cloud tab: share and apply settings presets", "Vxeze", os.time() - 3600 },
		{ "IMP", "Global chat: replies, pinned message and mailbox", "Vxeze", os.time() - 86400 },
		{ "FIX", "Library loads again on executors with a 200-local limit", "Vxeze", os.time() - 2 * 86400 },
	},
})

-- { name, icon, onClick? }. Stats returns an object whose Set(name, text) updates a tile.
local Stats = Home:Stats("This session", {
	{ "Players", "user" },
	{ "Ping", "wind" },
	{ "Uptime", "clock" },
})

local startedAt = os.clock()
task.spawn(function()
	local Stats_ = game:GetService("Stats")
	while Window.Gui and Window.Gui.Parent do
		Stats:Set("Players", tostring(#Players:GetPlayers()))
		local ok, ping = pcall(function()
			return Stats_.Network.ServerStatsItem["Data Ping"]:GetValue()
		end)
		Stats:Set("Ping", ok and `{math.floor(ping)} ms` or "--")
		local s = math.floor(os.clock() - startedAt)
		Stats:Set("Uptime", string.format("%02d:%02d", s // 60, s % 60))
		task.wait(1)
	end
end)

local Main = Window:Tab("Main", "zap")

local Player = Main:Section("Player", "user")
Player:Text(`Signed in as {LocalPlayer.DisplayName}. Open the Chat tab to talk with everyone using the script.`)

flag("AutoFarm", Player:Toggle("Auto farm", false, function(value)
	print("Auto farm:", value)
end, "Example toggle"))

flag("WalkSpeed", Player:Slider("Walk speed", 16, 100, 16, function(value)
	local humanoid = LocalPlayer.Character and LocalPlayer.Character:FindFirstChildOfClass("Humanoid")
	if humanoid then
		humanoid.WalkSpeed = value
	end
end))

local Actions = Main:Section("Actions", "sparkles")
Actions:Button("Say hello", "Run", function()
	Library:Notify("Hello", "VxezePortV2 is running.", "ok", 3)
end, nil, "Shows a notification")

-- Global chat tab. The library has its own Fluent relay client, so Endpoint + ApiKey is enough.
Window:GlobalChat({
	Name = "Chat",
	Title = "Global Chat",
	Endpoint = GLOBAL_CHAT_ENDPOINT,
	ApiKey = GLOBAL_CHAT_API_KEY,
	MaxMessages = 50,
	HistoryLimit = 50,
	PollInterval = 2,
	Placeholder = "Message everyone using this script...",
	-- Display-only badges; the relay's senderTag is trusted when present.
	RoleTags = {
		["11464210153"] = { Label = "ADMIN", Color = "#EF4444" },
		["10611068537"] = { Label = "SUPPORT", Color = "#3B82F6" },
		["8274772008"] = { Label = "SUPPORT", Color = "#3B82F6" },
	},
})

--------------------------------------------------------------------------------
-- Cloud tab: browse / like / apply public presets, publish and delete your own
--------------------------------------------------------------------------------

local Cloud = Window:Tab("Cloud", "server")

local publicSort, publicQuery = "top", ""
local PublicCards, MineCards

local function refreshPublic()
	PublicCards:Set({}, "Loading...")
	task.spawn(function()
		local items, err = CloudService:List(publicSort, publicQuery)
		PublicCards:Set(items or {}, items and "No configs yet" or ("Error: " .. tostring(err)))
	end)
end

local function refreshMine()
	MineCards:Set({}, "Loading...")
	task.spawn(function()
		local items, err = CloudService:ListMine()
		MineCards:Set(items or {}, items and "You haven't published anything" or ("Error: " .. tostring(err)))
	end)
end

local Browse = Cloud:Section("Public configs", "star")
Browse:Dropdown("Sort", { "top", "new" }, "top", function(value)
	publicSort = value
	refreshPublic()
end).Skip = true
Browse:Input("Search", "Config name...", function(text)
	publicQuery = text
	refreshPublic()
end).Skip = true

PublicCards = Browse:Cards(3, "Loading...", {
	Columns = 2,
	ApplyText = "Apply",
	Apply = function(it)
		local data, err = CloudService:Download(it.id)
		if not data then
			return Library:Notify("Apply failed", tostring(err), "err")
		end
		Library:Notify("Config applied", `{it.title}: {applyConfig(data)} settings`, "ok")
	end,
	-- Returning false makes the card undo its optimistic like.
	Like = function(it)
		local ok, err = CloudService:Like(it.id)
		if not ok then
			Library:Notify("Like failed", tostring(err), "err")
		end
		return ok
	end,
})
Browse:Button("Refresh", "Refresh", refreshPublic)

local Mine = Cloud:Section("My configs", "folder")
MineCards = Mine:Cards(2, "Loading...", {
	ApplyText = "Delete",
	Apply = function(it)
		local ok, err = CloudService:Delete(it.id)
		Library:Notify(ok and "Deleted" or "Delete failed", ok and it.title or tostring(err), ok and "ok" or "err")
		refreshMine()
	end,
})

local Publish = Cloud:Section("Publish current settings", "save")
local nameInput = Publish:Input("Name", "My farm setup")
local descInput = Publish:Input("Description", "What it does")
local tagsInput = Publish:Input("Tags", "Farming, Event, AFK")
nameInput.Skip, descInput.Skip, tagsInput.Skip = true, true, true

Publish:Button("Publish", "Publish", function()
	local name = nameInput.Value
	if name == "" then
		return Library:Notify("Name required", "Give the config a name first", "warn")
	end
	local tags = {}
	for tag in tagsInput.Value:gmatch("[^,]+") do
		tag = tag:match("^%s*(.-)%s*$")
		if tag ~= "" then
			table.insert(tags, tag)
		end
	end
	local card, err = CloudService:Publish({ Name = name, Description = descInput.Value, Tags = tags })
	if not card then
		return Library:Notify("Publish failed", tostring(err), "err")
	end
	Library:Notify("Published", card.title or name, "ok")
	refreshMine()
	refreshPublic()
end, "mint", "Max 10 configs per player")

-- Built-in tabs: UI look and theme, then local configs saved on this device.
Window:Settings()
Window:Config()

refreshPublic()
refreshMine()

return { Library = Library, Window = Window }
