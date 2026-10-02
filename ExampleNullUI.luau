-- Example: NullUI with tabs, sections and a Global Chat tab that talks to the
-- same relay (endpoint + protocol) as Fluent's GlobalChat component.
--
-- NullUI's chat panel expects a "service" object (SendChatMessage / PollChatMessages / ...).
-- Fluent's relay speaks a different JSON shape (camelCase, string ids, ISO timestamps,
-- X-Global-Chat-Key header), so this file contains a small adapter between the two.

local Players = game:GetService("Players")
local HttpService = game:GetService("HttpService")
local MarketplaceService = game:GetService("MarketplaceService")
local LocalPlayer = Players.LocalPlayer

-- Same values as Example.luau. Any key shipped in a client script is public.
local GLOBAL_CHAT_ENDPOINT = "https://vxezestudio.online/api/global-chat"
local GLOBAL_CHAT_API_KEY = "olwenth05dzkhoaito"

-- NullUI build that includes the Fluent-style global chat (role tags, pinned, reply, join, ...).
local NULLUI_URL = "https://raw.githubusercontent.com/angeryy-tvy/Fluent-Port-Vxeze/refs/heads/main/null-custom.lua"
-- Optional: set to a workspace file name to test a local build instead of the URL.
local NULLUI_LOCAL_FILE = nil

-- NullUI auto-translates its labels when the Roblox locale isn't English. Disable it here.
-- Must be set before the library loads.
getgenv().NullUI_NoTranslate = true

local function loadNullUI()
	if NULLUI_LOCAL_FILE and typeof(isfile) == "function" and isfile(NULLUI_LOCAL_FILE) then
		return loadstring(readfile(NULLUI_LOCAL_FILE))()
	end
	return loadstring(game:HttpGetAsync(NULLUI_URL))()
end

local NullUI = loadNullUI()

--------------------------------------------------------------------------------
-- Fluent relay adapter
--------------------------------------------------------------------------------

local function maskedName(name)
	name = tostring(name or "Guest")
	local ok, off = pcall(utf8.offset, name, 4)
	local prefix = ok and (off and name:sub(1, off - 1) or name) or name:sub(1, 3)
	return prefix .. "*****"
end

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

local function CreateFluentChatService(config)
	local endpoint = config.Endpoint:gsub("/+$", "")
	local httpRequest = resolveRequest()
	local playerId = tostring(LocalPlayer.UserId)
	local playerName = maskedName(LocalPlayer.DisplayName or LocalPlayer.Name)
	local gameName = config.GameName
	if not gameName then
		local ok, info = pcall(MarketplaceService.GetProductInfo, MarketplaceService, game.PlaceId)
		gameName = ok and info.Name or "Unknown game"
	end
	local avatarUrl =
		`https://www.roblox.com/headshot-thumbnail/image?userId={playerId}&width=150&height=150&format=png`

	-- Relay ids are increasing integers sent as strings; NullUI compares them
	-- numerically and passes the last one back as `after`.
	local function idFor(id)
		return tonumber(id) or 0
	end

	local service = { ChatMeta = { OnlineCount = 0 } }

	local function call(method, path, body, query)
		local headers = { ["Content-Type"] = "application/json", ["X-Global-Chat-Key"] = config.ApiKey }
		local url = endpoint .. (path or "") .. (query or "")
		local ok, res = pcall(httpRequest, {
			Url = url,
			Method = method,
			Headers = headers,
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
			return nil, "Invalid chat response"
		end
		return data
	end

	local function toMs(iso)
		local ok, dt = pcall(DateTime.fromIsoDate, iso)
		return ok and dt and dt.UnixTimestampMillis or os.time() * 1000
	end

	local function convert(m)
		local join = typeof(m.joinServer) == "table" and m.joinServer or nil
		local reply = typeof(m.reply) == "table" and m.reply or nil
		return {
			Id = idFor(m.id),
			UserId = tonumber(m.playerId) or 0,
			PlayerName = m.playerName,
			GameName = m.gameName,
			SenderTag = m.senderTag,
			Text = m.content,
			CreatedAt = toMs(m.createdAt),
			Reply = reply and { PlayerName = reply.playerName, Content = reply.content } or nil,
			JoinServer = join and { PlaceId = join.placeId, JobId = join.jobId } or nil,
		}
	end

	-- With `after` the relay returns only messages newer than that id, so a
	-- quiet chat costs a few hundred bytes per poll instead of the whole history.
	local function fetch(sinceId)
		local query = "?limit=" .. tostring(config.MaxMessages or 50)
		if sinceId and sinceId > 0 then
			query ..= "&after=" .. tostring(sinceId)
		end
		local data, err = call("GET", nil, nil, query)
		if not data then
			return nil, err
		end
		local pinned = typeof(data.pinnedMessage) == "table" and data.pinnedMessage or nil
		-- Ids an admin deleted recently; NullUI removes those rows if rendered.
		local deletedIds = {}
		for _, id in ipairs(typeof(data.deletedIds) == "table" and data.deletedIds or {}) do
			table.insert(deletedIds, idFor(id))
		end
		service.ChatMeta = {
			Pinned = pinned and { Content = pinned.content, UpdatedByName = pinned.updatedByName } or nil,
			OnlineCount = tonumber(data.onlineCount) or 0,
			DeletedIds = deletedIds,
		}
		return typeof(data.messages) == "table" and data.messages or {}
	end

	function service:PollChatMessages(sinceId)
		local raw, err = fetch(sinceId)
		if not raw then
			return nil, err
		end
		local out = {}
		for _, m in ipairs(raw) do
			local converted = convert(m)
			if converted.Id > (sinceId or 0) then
				table.insert(out, converted)
			end
		end
		return out
	end

	function service:SendChatMessage(_, text, extra)
		extra = extra or {}
		local replyId = extra.ReplyToId and tostring(extra.ReplyToId) or nil
		local data, err = call("POST", nil, {
			playerId = playerId,
			playerName = extra.PlayerName or playerName,
			gameName = extra.GameName or gameName,
			avatarUrl = avatarUrl,
			content = text,
			replyToId = replyId,
		})
		if not data then
			return nil, err
		end

		-- The relay answers 201 with the stored message, so the next poll won't
		-- render our own bubble a second time.
		local posted = typeof(data.message) == "table" and data.message or data
		-- The relay may rewrite the content (e.g. blocked script links); show its copy.
		return { Id = idFor(posted.id), Text = typeof(posted.content) == "string" and posted.content or nil }
	end

	function service:ReportChatMessage(messageId, reason)
		if not messageId or messageId <= 0 then
			return false, "Unknown message"
		end
		local id = tostring(messageId)
		local data, err = call("POST", "/report", {
			reporterPlayerId = playerId,
			reporterPlayerName = playerName,
			messageId = id,
			reason = reason,
		})
		return data ~= nil, err
	end

	function service:PublishChatPresence(_, allowJoin, placeId, jobId)
		local data, err = call("POST", "/presence", {
			playerId = playerId,
			allowJoin = allowJoin,
			placeId = allowJoin and placeId or nil,
			jobId = allowJoin and jobId or nil,
		})
		return data ~= nil, err
	end

	function service:GetChatJoinTarget(userId)
		local data, err = call("GET", "/presence/" .. tostring(userId))
		if not data then
			return nil, err
		end
		local join = data.joinServer
		return typeof(join) == "table" and { PlaceId = join.placeId, JobId = join.jobId } or nil
	end

	return service
end

local ChatService = CreateFluentChatService({
	Endpoint = GLOBAL_CHAT_ENDPOINT,
	ApiKey = GLOBAL_CHAT_API_KEY,
	MaxMessages = 50,
})

--------------------------------------------------------------------------------
-- Window, tabs and sections
--------------------------------------------------------------------------------

local Window = NullUI:CreateWindow({
	Title = "NullUI Example",
	Subtitle = "Global chat via Fluent relay",
	Size = UDim2.fromOffset(720, 460),
})

local Main = Window:AddTab({ Name = "Main", Icon = "users" })

Main:AddSection({ Text = "Player", Icon = "user" })
Main:AddParagraph({
	Title = "Welcome",
	Text = `Signed in as {LocalPlayer.DisplayName}. Open the Chat tab to talk with everyone using the script.`,
})
Main:AddToggle({
	Text = "Auto farm",
	Description = "Example toggle",
	Default = false,
	Callback = function(value)
		print("Auto farm:", value)
	end,
})
Main:AddSlider({
	Text = "Walk speed",
	Min = 16,
	Max = 100,
	Default = 16,
	Increment = 1,
	Callback = function(value)
		local humanoid = LocalPlayer.Character and LocalPlayer.Character:FindFirstChildOfClass("Humanoid")
		if humanoid then
			humanoid.WalkSpeed = value
		end
	end,
})

Main:AddSection({ Text = "Actions", Icon = "zap" })
Main:AddButton({
	Text = "Say hello",
	Description = "Shows a notification",
	Callback = function()
		NullUI:Notify({ Title = "Hello", Text = "NullUI is running.", Type = "success", Duration = 3 })
	end,
})

local Settings = Window:AddTab({ Name = "Settings", Icon = "settings" })
Settings:AddSection({ Text = "Interface", Icon = "palette" })
Settings:AddDropdown({
	Text = "Theme",
	Options = NullUI:GetThemeNames(),
	Callback = function(theme)
		NullUI:SetTheme(theme)
	end,
})

-- Global chat tab. Hidden = false puts it in the tab bar like any other tab.
local Chat = Window:AddGlobalChatPanel({
	Name = "Chat",
	Title = "Global Chat",
	Icon = "messages-square",
	Hidden = false,
	Service = ChatService,
	AnonymousByDefault = false, -- Fluent always sends the real player id (name masked)
	PollInterval = 2,
	HistoryLimit = 50,
	Placeholder = "Message everyone using this script...",
	-- Display-only badges; the relay's senderTag is trusted when present.
	RoleTags = {
		["11464210153"] = { Label = "ADMIN", Color = "#EF4444" },
		["10611068537"] = { Label = "SUPPORT", Color = "#3B82F6" },
		["8274772008"] = { Label = "SUPPORT", Color = "#3B82F6" },
	},
})

return { Window = Window, Chat = Chat }
