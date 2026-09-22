-- Compact online global chat component for Fluent Renewed.
-- The component deliberately talks to a small JSON REST relay instead of
-- coupling the UI library to a specific auth/database implementation.

local Root = script.Parent.Parent
local Creator = require(Root.Modules.Creator)
local New = Creator.New

local HttpService = game:GetService("HttpService")
local Players = game:GetService("Players")
local MarketplaceService = game:GetService("MarketplaceService")
local UserInputService = game:GetService("UserInputService")
local TeleportService = game:GetService("TeleportService")
local RunService = game:GetService("RunService")

local GlobalChat = {}
GlobalChat.__index = GlobalChat

-- Display-only roles. The relay currently accepts client-supplied player IDs,
-- so these badges must not be used as proof of identity or for permissions.
local RoleTags = {
	["11464210153"] = { Label = "ADMIN", Color = "#EF4444" }, -- OlwenThNek
	["10611068537"] = { Label = "SUPPORT", Color = "#3B82F6" }, -- jwenvie04
}

local function safeString(Value, Fallback)
	return typeof(Value) == "string" and Value ~= "" and Value or Fallback
end

local function escapeRichText(Value)
	return Value:gsub("&", "&amp;"):gsub("<", "&lt;"):gsub(">", "&gt;")
end

local function initials(Name)
	local First, Last = Name:match("^(%S)%S*%s+(%S)")
	if First and Last then
		return (First .. Last):upper()
	end
	return Name:sub(1, 2):upper()
end

local function maskedPlayerName(Name)
	local Success, FourthByte = pcall(utf8.offset, Name, 4)
	local Prefix = Success and (FourthByte and Name:sub(1, FourthByte - 1) or Name)
		or Name:sub(1, 3)
	return Prefix .. "*****"
end

local function formatChatTime(IsoTimestamp)
	if typeof(IsoTimestamp) ~= "string" then
		return ""
	end
	local Hour, Minute = IsoTimestamp:match("T(%d%d):(%d%d)")
	if not Hour then
		return ""
	end
	-- The chat API returns UTC ISO timestamps; display them in Vietnam time (UTC+7).
	if IsoTimestamp:sub(-1) == "Z" then
		Hour = string.format("%02d", (tonumber(Hour) + 7) % 24)
	end
	return Hour .. ":" .. Minute
end

local function rounded(Object, Radius)
	New("UICorner", {
		CornerRadius = UDim.new(0, Radius),
		Parent = Object,
	})
	return Object
end

local function themed(Object, ThemeTag)
	Object.ThemeTag = ThemeTag
	Creator.AddThemeObject(Object, ThemeTag)
	return Object
end

local function resolveGameName(Config)
	if typeof(Config.GameName) == "string" and Config.GameName ~= "" then
		return Config.GameName
	end

	local Success, Info = pcall(MarketplaceService.GetProductInfo, MarketplaceService, game.PlaceId)
	return Success and Info.Name or "Unknown game"
end

local function resolveAvatarUrl(Config, Player)
	if typeof(Config.AvatarUrl) == "string" and Config.AvatarUrl ~= "" then
		return Config.AvatarUrl
	end

	if not Player then
		return ""
	end

	return `https://www.roblox.com/headshot-thumbnail/image?userId={Player.UserId}&width=150&height=150&format=png`
end

local function resolveHttpRequest(Config)
	if typeof(Config.Request) == "function" then
		return Config.Request
	end
	if typeof(request) == "function" then
		return request
	end
	if typeof(http_request) == "function" then
		return http_request
	end
	if typeof(http) == "table" and typeof(http.request) == "function" then
		return http.request
	end
	if typeof(syn) == "table" and typeof(syn.request) == "function" then
		return syn.request
	end
	return nil
end

local function resolveClipboard(Config)
	if typeof(Config.SetClipboard) == "function" then return Config.SetClipboard end
	if typeof(setclipboard) == "function" then return setclipboard end
	if typeof(toclipboard) == "function" then return toclipboard end
	if typeof(Clipboard) == "table" and typeof(Clipboard.set) == "function" then
		return function(Text) Clipboard.set(Text) end
	end
	return nil
end

function GlobalChat.new(Config)
	Config = Config or {}
	assert(Config.Parent, "GlobalChat requires a Parent GuiObject or ScreenGui")
	local Player = Players.LocalPlayer
	local PlayerName = safeString(Config.PlayerName, Player and (Player.DisplayName or Player.Name) or "Guest")

	local self = setmetatable({
		Config = Config,
		Destroyed = false,
		Open = Config.Inline == true or Config.Open ~= false,
		Connections = {},
		LastRenderedSignature = nil,
		RenderGeneration = 0,
		AllowJoin = false,
		PresenceBusy = false,
		ReplyingTo = nil,
		OpenMenu = nil,
		ChatJoinPending = false,
		ChatJoinAttempt = 0,
		RefreshInProgress = false,
		StatusToken = 0,
		Player = Player,
		PlayerId = tostring(Config.PlayerId or (Player and Player.UserId) or "guest"),
		PlayerName = PlayerName,
		GameName = resolveGameName(Config),
		AvatarUrl = resolveAvatarUrl(Config, Player),
		Endpoint = safeString(Config.Endpoint, ""),
		ApiKey = safeString(Config.ApiKey, ""),
		HttpRequest = resolveHttpRequest(Config),
		SetClipboard = resolveClipboard(Config),
		PollInterval = math.max(tonumber(Config.PollInterval) or 3, 2),
		MaxMessages = math.clamp(tonumber(Config.MaxMessages) or 50, 10, 100),
	}, GlobalChat)

	self:Build(Config.Parent)
	self:SetOpen(self.Open)
	self:StartPolling()
	return self
end

function GlobalChat:Build(Parent)
	local Accent = Color3.fromRGB(82, 201, 255)
	local Inline = self.Config.Inline == true
	local Compact = UserInputService.TouchEnabled and not UserInputService.KeyboardEnabled
	local HeaderHeight = Compact and 32 or 48
	local ContentTop = HeaderHeight + (Compact and 2 or 4)
	local ComposerHeight = Compact and 36 or 34
	local BottomInset = Compact and 4 or 12
	local ComposerGap = Compact and 3 or 8
	local HorizontalInset = Compact and 5 or 10
	local SendWidth = Compact and 64 or 62
	local ReplyBarHeight = 24
	local JoinToggleWidth = Compact and 76 or 110
	local JoinToggleRight = Inline and 8 or 42

	if not Inline then
		self.ToggleButton = rounded(New("TextButton", {
			Name = "GlobalChatToggle",
			AnchorPoint = Vector2.new(1, 1),
			Position = UDim2.new(1, -24, 1, -24),
			Size = UDim2.fromOffset(42, 42),
			Text = "",
			ZIndex = 100,
			Parent = Parent,
			ThemeTag = { BackgroundColor3 = "DialogHolder" },
		}, {
			New("UICorner", { CornerRadius = UDim.new(1, 0) }),
			New("UIStroke", { Transparency = 0.35, ThemeTag = { Color = "DialogBorder" } }),
			New("TextLabel", {
				Text = "●",
				TextColor3 = Accent,
				TextSize = 22,
				Font = Enum.Font.GothamBold,
				Size = UDim2.fromScale(1, 1),
				BackgroundTransparency = 1,
				ThemeTag = { TextColor3 = "Accent" },
			}),
		}), 21)
	end

	self.Panel = rounded(New("Frame", {
		Name = "GlobalChat",
		AnchorPoint = Inline and Vector2.zero or Vector2.new(1, 1),
		Position = Inline and UDim2.fromOffset(0, 0) or UDim2.new(1, -24, 1, -76),
		-- Inline chat fills the visible tab instead of using a fixed pixel height.
		-- This keeps the composer inside short mobile viewports and above the
		-- on-screen keyboard area handled by the window.
		Size = Inline and UDim2.new(1, 0, 1, -4)
			or UDim2.fromOffset(self.Config.Width or 360, self.Config.Height or 330),
		ClipsDescendants = true,
		ZIndex = 90,
		Parent = Parent,
		ThemeTag = { BackgroundColor3 = "Dialog" },
	}, {
		New("UIStroke", { Transparency = 0.25, ThemeTag = { Color = "DialogBorder" } }),
	}), 10)

	self.Header = New("Frame", {
		Size = UDim2.new(1, 0, 0, HeaderHeight),
		BackgroundTransparency = 1,
		ZIndex = 91,
		Parent = self.Panel,
	})

	New("TextLabel", {
		Text = safeString(self.Config.Title, "Global Chat"),
		Position = UDim2.fromOffset(Compact and 10 or 16, Compact and 2 or 9),
		Size = UDim2.new(1, -(JoinToggleWidth + JoinToggleRight + 20), 0, Compact and 16 or 18),
		TextXAlignment = Enum.TextXAlignment.Left,
		Font = Enum.Font.GothamBold,
		TextSize = 14,
		BackgroundTransparency = 1,
		ZIndex = 92,
		ThemeTag = { TextColor3 = "Text" },
		Parent = self.Header,
	})

	self.Status = New("TextLabel", {
		Text = "●  connecting…",
		Position = UDim2.fromOffset(Compact and 10 or 16, Compact and 18 or 27),
		Size = UDim2.new(1, -(JoinToggleWidth + JoinToggleRight + 20), 0, 14),
		TextXAlignment = Enum.TextXAlignment.Left,
		Font = Enum.Font.Gotham,
		TextSize = 10,
		BackgroundTransparency = 1,
		ZIndex = 92,
		ThemeTag = { TextColor3 = "SubText" },
		Parent = self.Header,
	})

	self.CloseButton = New("TextButton", {
		Text = "×",
		Visible = not Inline,
		Position = UDim2.new(1, -38, 0, 9),
		Size = UDim2.fromOffset(28, 28),
		Font = Enum.Font.Gotham,
		TextSize = 20,
		ZIndex = 93,
		ThemeTag = { TextColor3 = "SubText", BackgroundColor3 = "DialogButton" },
		Parent = self.Header,
	}, {
		New("UICorner", { CornerRadius = UDim.new(0, 7) }),
	})

	self.JoinToggle = rounded(New("TextButton", {
		Name = "AllowJoinSetting",
		Text = Compact and "Join: OFF" or "Allow Join: OFF",
		Position = UDim2.new(1, -(JoinToggleWidth + JoinToggleRight), 0, Compact and 4 or 10),
		Size = UDim2.fromOffset(JoinToggleWidth, Compact and 24 or 26),
		Font = Enum.Font.GothamBold,
		TextSize = Compact and 9 or 10,
		TextColor3 = Color3.fromRGB(170, 177, 190),
		ZIndex = 93,
		ThemeTag = { BackgroundColor3 = "DialogButton" },
		Parent = self.Header,
	}), 7)

	self.Messages = New("ScrollingFrame", {
		Position = UDim2.fromOffset(HorizontalInset, ContentTop),
		Size = UDim2.new(
			1,
			-HorizontalInset * 2,
			1,
			-(ContentTop + ComposerHeight + BottomInset + ComposerGap)
		),
		BackgroundTransparency = 1,
		BorderSizePixel = 0,
		ClipsDescendants = true,
		ScrollBarThickness = 3,
		ScrollBarImageTransparency = 0.5,
		CanvasSize = UDim2.fromOffset(0, 0),
		ZIndex = 91,
		Parent = self.Panel,
	})
	self.MessagesBaseSize = self.Messages.Size

	self.MessageLayout = New("UIListLayout", {
		Padding = UDim.new(0, Compact and 3 or 5),
		SortOrder = Enum.SortOrder.LayoutOrder,
		Parent = self.Messages,
	})

	self.EmptyState = New("TextLabel", {
		Text = "No messages yet — say hello!",
		Size = UDim2.new(1, 0, 0, 24),
		Position = UDim2.fromOffset(0, 50),
		TextXAlignment = Enum.TextXAlignment.Center,
		Font = Enum.Font.Gotham,
		TextSize = 11,
		BackgroundTransparency = 1,
		ZIndex = 92,
		ThemeTag = { TextColor3 = "SubText" },
		Parent = self.Messages,
	})

	self.InputFrame = rounded(New("Frame", {
		AnchorPoint = Vector2.new(0, 1),
		Position = UDim2.new(0, HorizontalInset, 1, -BottomInset),
		Size = UDim2.new(1, -HorizontalInset * 2, 0, ComposerHeight),
		BackgroundTransparency = 0.08,
		ZIndex = 96,
		ThemeTag = { BackgroundColor3 = "DialogInput" },
		Parent = self.Panel,
	}), 7)

	self.ReplyBar = rounded(New("Frame", {
		AnchorPoint = Vector2.new(0, 1),
		Position = UDim2.new(0, HorizontalInset, 1, -(BottomInset + ComposerHeight + 4)),
		Size = UDim2.new(1, -HorizontalInset * 2, 0, ReplyBarHeight),
		Visible = false,
		ZIndex = 96,
		ThemeTag = { BackgroundColor3 = "DialogHolder" },
		Parent = self.Panel,
	}), 6)

	self.ReplyLabel = New("TextLabel", {
		Position = UDim2.fromOffset(8, 0),
		Size = UDim2.new(1, -38, 1, 0),
		Text = "",
		TextTruncate = Enum.TextTruncate.AtEnd,
		TextXAlignment = Enum.TextXAlignment.Left,
		Font = Enum.Font.Gotham,
		TextSize = 10,
		BackgroundTransparency = 1,
		ZIndex = 97,
		ThemeTag = { TextColor3 = "SubText" },
		Parent = self.ReplyBar,
	})

	self.CancelReply = New("TextButton", {
		Text = "×",
		Position = UDim2.new(1, -28, 0, 0),
		Size = UDim2.fromOffset(28, ReplyBarHeight),
		Font = Enum.Font.GothamBold,
		TextSize = 16,
		BackgroundTransparency = 1,
		ZIndex = 98,
		ThemeTag = { TextColor3 = "SubText" },
		Parent = self.ReplyBar,
	})

	self.Input = New("TextBox", {
		Position = UDim2.fromOffset(10, 0),
		Size = UDim2.new(1, -(SendWidth + 22), 1, 0),
		ClearTextOnFocus = false,
		PlaceholderText = "Type a message…",
		Text = "",
		TextXAlignment = Enum.TextXAlignment.Left,
		TextYAlignment = Enum.TextYAlignment.Center,
		Font = Enum.Font.Gotham,
		TextSize = 12,
		BackgroundTransparency = 1,
		ZIndex = 97,
		ThemeTag = { TextColor3 = "Text", PlaceholderColor3 = "SubText" },
		Parent = self.InputFrame,
	})

	self.Send = rounded(New("TextButton", {
		Text = "Send",
		Position = UDim2.new(1, -(SendWidth + 4), 0, 4),
		Size = UDim2.new(0, SendWidth, 1, -8),
		Font = Enum.Font.GothamBold,
		TextSize = 11,
		ZIndex = 98,
		ThemeTag = { TextColor3 = "Text", BackgroundColor3 = "Accent" },
		Parent = self.InputFrame,
	}), 6)

	if not Inline then
		table.insert(self.Connections, self.ToggleButton.MouseButton1Click:Connect(function()
			self:Toggle()
		end))
		table.insert(self.Connections, self.CloseButton.MouseButton1Click:Connect(function()
			self:SetOpen(false)
		end))
	end
	table.insert(self.Connections, self.Send.MouseButton1Click:Connect(function()
		self:SendMessage()
	end))
	table.insert(self.Connections, self.JoinToggle.MouseButton1Click:Connect(function()
		self:SetAllowJoin(not self.AllowJoin)
	end))
	table.insert(self.Connections, self.CancelReply.MouseButton1Click:Connect(function()
		self:ClearReply()
	end))
	table.insert(self.Connections, self.Input.FocusLost:Connect(function(EnterPressed)
		if EnterPressed then
			self:SendMessage()
		end
	end))
	table.insert(self.Connections, self.MessageLayout:GetPropertyChangedSignal("AbsoluteContentSize"):Connect(function()
		self.Messages.CanvasSize = UDim2.fromOffset(0, self.MessageLayout.AbsoluteContentSize.Y + 6)
	end))
	table.insert(self.Connections, TeleportService.TeleportInitFailed:Connect(function(Player, _, ErrorMessage)
		if Player == self.Player and self.ChatJoinPending and not self.Destroyed then
			self.ChatJoinPending = false
			self.ChatJoinAttempt += 1
			self:SetTransientStatus("Join failed: " .. tostring(ErrorMessage), true, 3)
		end
	end))
	if self.Config.Library and self.Config.Library.OnUnload then
		table.insert(self.Connections, self.Config.Library.OnUnload:Connect(function()
			self:Destroy()
		end))
	end
end

function GlobalChat:SetOpen(IsOpen)
	self.Open = self.Config.Inline == true or IsOpen == true
	self.Panel.Visible = self.Open
	if self.ToggleButton then
		self.ToggleButton.Visible = not self.Open
	end
end

function GlobalChat:Toggle()
	self:SetOpen(not self.Open)
end

function GlobalChat:SetStatus(Text, IsError)
	self.StatusToken += 1
	self.Status.Text = IsError and ("●  " .. Text) or ("●  " .. Text)
	self.Status.TextColor3 = IsError and Color3.fromRGB(255, 130, 130) or Creator.GetThemeProperty("SubText")
end

function GlobalChat:SetTransientStatus(Text, IsError, Duration)
	self:SetStatus(Text, IsError)
	local Token = self.StatusToken
	task.delay(Duration or 3, function()
		if not self.Destroyed and self.StatusToken == Token then
			self:SafeRefresh()
		end
	end)
end

function GlobalChat:SafeRefresh()
	if self.Destroyed or self.RefreshInProgress then return end
	self.RefreshInProgress = true
	local Success, Error = pcall(self.Refresh, self)
	self.RefreshInProgress = false
	if not Success and not self.Destroyed then
		self:SetStatus("Chat refresh failed; retrying…", true)
		warn("[GlobalChat] Refresh failed: " .. tostring(Error))
	end
end

function GlobalChat:Request(Method, Payload, Path)
	if self.Endpoint == "" then
		return false, "Set Config.Endpoint to enable online chat"
	end

	local Headers = { ["Content-Type"] = "application/json" }
	if self.ApiKey ~= "" then
		Headers["X-Global-Chat-Key"] = self.ApiKey
	end

	local Url = Path and (self.Endpoint:gsub("/+$", "") .. Path) or self.Endpoint
	if Method == "GET" and not Path then
		Url = Url .. (Url:find("?", 1, true) and "&" or "?") .. "limit=" .. tostring(self.MaxMessages)
	end
	local Request = {
		Url = Url,
		Method = Method,
		Headers = Headers,
	}
	if Payload then
		Request.Body = HttpService:JSONEncode(Payload)
	end

	local Success, Response
	if self.HttpRequest then
		Success, Response = pcall(self.HttpRequest, Request)
	else
		Success, Response = pcall(HttpService.RequestAsync, HttpService, Request)
	end
	if not Success or typeof(Response) ~= "table" or not Response.Success then
		return false, (Success and typeof(Response) == "table" and (Response.StatusMessage or "Request failed") or tostring(Response))
	end

	local DecodeSuccess, Data = pcall(HttpService.JSONDecode, HttpService, Response.Body)
	if not DecodeSuccess or typeof(Data) ~= "table" then
		return false, "Invalid chat response"
	end
	return true, Data
end

function GlobalChat:ClearReply()
	self.ReplyingTo = nil
	if self.ReplyBar then self.ReplyBar.Visible = false end
	if self.Messages and self.MessagesBaseSize then self.Messages.Size = self.MessagesBaseSize end
end

function GlobalChat:SetReply(Message)
	local Id = tostring(Message.id or "")
	if Id == "" then return end
	local PlayerName = safeString(Message.playerName, "Guest")
	local Content = safeString(Message.content, "")
	self.ReplyingTo = { id = Id, playerName = PlayerName, content = Content }
	self.ReplyLabel.Text = `Replying to {maskedPlayerName(PlayerName)}: {Content}`
	self.ReplyBar.Visible = true
	local Base = self.MessagesBaseSize
	self.Messages.Size = UDim2.new(Base.X.Scale, Base.X.Offset, Base.Y.Scale, Base.Y.Offset - self.ReplyBar.Size.Y.Offset - 4)
	pcall(function() self.Input:CaptureFocus() end)
end

function GlobalChat:CopyMessage(Content)
	if not self.SetClipboard then
		self:SetStatus("Clipboard is unavailable in this executor", true)
		return
	end
	local Success, Error = pcall(self.SetClipboard, Content)
	self:SetStatus(Success and "message copied" or ("Copy failed: " .. tostring(Error)), not Success)
end

function GlobalChat:UpdateJoinToggle()
	if not self.JoinToggle then return end
	local Compact = UserInputService.TouchEnabled and not UserInputService.KeyboardEnabled
	self.JoinToggle.Text = Compact and (self.AllowJoin and "Join: ON" or "Join: OFF")
		or (self.AllowJoin and "Allow Join: ON" or "Allow Join: OFF")
	self.JoinToggle.TextColor3 = self.AllowJoin and Color3.fromRGB(105, 224, 163)
		or Color3.fromRGB(170, 177, 190)
end

function GlobalChat:PublishPresence()
	return self:Request("POST", {
		playerId = self.PlayerId,
		allowJoin = self.AllowJoin,
		placeId = self.AllowJoin and game.PlaceId or nil,
		jobId = self.AllowJoin and game.JobId or nil,
	}, "/presence")
end

function GlobalChat:SetAllowJoin(Allow)
	if self.Destroyed or self.PresenceBusy or Allow == self.AllowJoin then return end
	if Allow and (game.JobId == "" or game.PrivateServerId ~= "" or game.PlaceId <= 0) then
		self:SetStatus("Join sharing needs a public game server", true)
		return
	end

	self.PresenceBusy = true
	self.JoinToggle.Active = false
	self.AllowJoin = Allow
	self:UpdateJoinToggle()
	local Success, Result = self:PublishPresence()
	if not Success then
		self.AllowJoin = not Allow
		self:UpdateJoinToggle()
		self:SetStatus(Result, true)
	end
	self.JoinToggle.Active = true
	self.PresenceBusy = false
end

function GlobalChat:JoinServer(PlayerId)
	local Success, Result = self:Request("GET", nil, "/presence/" .. PlayerId)
	if not Success then
		self:SetStatus(Result, true)
		return
	end

	local Target = Result.joinServer
	local PlaceId = typeof(Target) == "table" and tonumber(Target.placeId) or nil
	local JobId = typeof(Target) == "table" and Target.jobId or nil
	if not PlaceId or typeof(JobId) ~= "string" or JobId == "" then
		self:SetStatus("This player is no longer sharing a server", true)
		return
	end
	if not self.Player then
		self:SetStatus("Local player is unavailable", true)
		return
	end
	if PlaceId == game.PlaceId and JobId == game.JobId then
		self:SetStatus("You are already in this server", false)
		return
	end

	self:SetStatus("Joining server…", false)
	-- Client-side executor scripts cannot call server-only TeleportAsync.
	self.ChatJoinAttempt += 1
	local Attempt = self.ChatJoinAttempt
	self.ChatJoinPending = true
	local Teleported, Error = pcall(TeleportService.TeleportToPlaceInstance, TeleportService, PlaceId, JobId, self.Player)
	if not Teleported then
		self.ChatJoinPending = false
		self:SetTransientStatus("Join failed: " .. tostring(Error), true, 3)
	else
		task.delay(15, function()
			if not self.Destroyed and self.ChatJoinAttempt == Attempt then
				self.ChatJoinPending = false
			end
		end)
	end
end

function GlobalChat:ConfirmJoin(PlayerId, PlayerName, GameName)
	local Window = self.Config.Library and self.Config.Library.CreatedWindow
	if not Window or typeof(Window.Dialog) ~= "function" then
		self:SetStatus("Join confirmation is unavailable", true)
		return
	end

	Window:Dialog({
		Title = "Join Server?",
		Content = `Join {maskedPlayerName(PlayerName)} in {GameName}? You will leave your current server.`,
		Buttons = {
			{ Title = "No", Callback = function() end },
			{ Title = "Yes", Callback = function()
				task.spawn(function() self:JoinServer(PlayerId) end)
			end },
		},
	})
end

function GlobalChat:Render(Messages)
	local PreviousPosition = self.Messages.CanvasPosition.Y
	local PreviousMax = math.max(0, self.Messages.CanvasSize.Y.Offset - self.Messages.AbsoluteWindowSize.Y)
	local FollowLatest = PreviousMax - PreviousPosition <= 24
	self.RenderGeneration += 1
	local Generation = self.RenderGeneration
	self.OpenMenu = nil

	for _, Child in next, self.Messages:GetChildren() do
		if Child ~= self.MessageLayout and Child ~= self.EmptyState then
			Child:Destroy()
		end
	end

	self.EmptyState.Visible = #Messages == 0
	for Index, Message in ipairs(Messages) do
		local PlayerName = safeString(Message.playerName, "Guest")
		local TrustedSenderTag = safeString(Message.senderTag, "")
		local IsOwner = TrustedSenderTag == "OWNER"
		local DisplayName = IsOwner and PlayerName or maskedPlayerName(PlayerName)
		local Initials = safeString(Message.initials, initials(PlayerName))
		local GameName = safeString(Message.gameName, "Unknown game")
		local AvatarUrl = safeString(Message.avatarUrl, "")
		local Time = formatChatTime(Message.createdAt)
		local Role = IsOwner and { Label = "OWNER", Color = "#EF4444" }
			or RoleTags[tostring(Message.playerId or "")]
		local Tag = Role and `  <font color="{Role.Color}">[{Role.Label}]</font>` or ""
		local JoinData = typeof(Message.joinServer) == "table" and Message.joinServer or nil
		local CanJoin = JoinData and tostring(Message.playerId or "") ~= self.PlayerId
			and tonumber(JoinData.placeId) and typeof(JoinData.jobId) == "string" and JoinData.jobId ~= ""
		local Compact = UserInputService.TouchEnabled and not UserInputService.KeyboardEnabled
		local Reply = typeof(Message.reply) == "table" and Message.reply or nil
		local HasReply = Reply and safeString(Reply.content, "") ~= ""
		local BaseRowHeight = 42
		local ReplyHeight = HasReply and (Compact and 14 or 16) or 0
		local RowHeight = BaseRowHeight + ReplyHeight
		local MetaY = Compact and 4 or 5
		local BodyY = (Compact and 20 or 19) + ReplyHeight
		local RightInset = CanJoin and 164 or 76
		local AvatarSize = Compact and 24 or 28
		local AvatarX = Compact and 5 or 7
		local TextX = Compact and 36 or 44

		local Row = rounded(New("Frame", {
			Size = UDim2.new(1, -4, 0, RowHeight),
			BackgroundTransparency = 0.55,
			LayoutOrder = Index,
			ZIndex = 92,
			ThemeTag = { BackgroundColor3 = "DialogHolder" },
			Parent = self.Messages,
		}), 7)

		local Avatar = rounded(New("ImageLabel", {
			Position = UDim2.fromOffset(AvatarX, math.floor((RowHeight - AvatarSize) / 2)),
			Size = UDim2.fromOffset(AvatarSize, AvatarSize),
			Image = AvatarUrl,
			Visible = AvatarUrl ~= "",
			ZIndex = 93,
			Parent = Row,
		}), 14)
		if AvatarUrl ~= "" then
			New("UICorner", { CornerRadius = UDim.new(1, 0), Parent = Avatar })
		end

		local InitialsLabel = rounded(New("TextLabel", {
			Position = UDim2.fromOffset(AvatarX, math.floor((RowHeight - AvatarSize) / 2)),
			Size = UDim2.fromOffset(AvatarSize, AvatarSize),
			Text = Initials,
			TextSize = 10,
			Font = Enum.Font.GothamBold,
			Visible = AvatarUrl == "",
			ZIndex = 93,
			ThemeTag = { TextColor3 = "Text", BackgroundColor3 = "Accent" },
			Parent = Row,
		}), 14)

		local Meta = New("TextLabel", {
			Position = UDim2.fromOffset(TextX, MetaY),
			Size = UDim2.new(1, -RightInset, 0, 14),
			Text = `{escapeRichText(DisplayName)}{Tag}  •  {escapeRichText(GameName)}  •  {Time}`,
			RichText = true,
			TextTruncate = Enum.TextTruncate.AtEnd,
			TextXAlignment = Enum.TextXAlignment.Left,
			Font = Enum.Font.GothamBold,
			TextSize = 10,
			ZIndex = 93,
			ThemeTag = { TextColor3 = "SubText" },
			Parent = Row,
		})

		if HasReply then
			New("TextLabel", {
				Position = UDim2.fromOffset(TextX, Compact and 20 or 19),
				Size = UDim2.new(1, -RightInset, 0, 14),
				Text = `↪ {maskedPlayerName(safeString(Reply.playerName, "Guest"))}: {safeString(Reply.content, "")}`,
				TextTruncate = Enum.TextTruncate.AtEnd,
				TextXAlignment = Enum.TextXAlignment.Left,
				Font = Enum.Font.Gotham,
				TextSize = 9,
				BackgroundTransparency = 1,
				ZIndex = 93,
				ThemeTag = { TextColor3 = "SubText" },
				Parent = Row,
			})
		end

		New("TextLabel", {
			Position = UDim2.fromOffset(TextX, BodyY),
			Size = UDim2.new(1, -RightInset, 0, 18),
			Text = safeString(Message.content, ""),
			TextWrapped = true,
			TextXAlignment = Enum.TextXAlignment.Left,
			TextYAlignment = Enum.TextYAlignment.Center,
			Font = Enum.Font.Gotham,
			TextSize = 11,
			ZIndex = 93,
			ThemeTag = { TextColor3 = "Text" },
			Parent = Row,
		})

		if CanJoin then
			local JoinButton = rounded(New("TextButton", {
				Name = "JoinServer",
				Text = "Join Server",
				Position = UDim2.new(1, -112, 0, Compact and 6 or 4),
				Size = UDim2.fromOffset(76, Compact and 28 or 17),
				Font = Enum.Font.GothamBold,
				TextSize = 9,
				TextColor3 = Color3.fromRGB(105, 182, 255),
				ZIndex = 94,
				ThemeTag = { BackgroundColor3 = "DialogButton" },
				Parent = Row,
			}), 5)
			JoinButton.MouseButton1Click:Connect(function()
				self:ConfirmJoin(tostring(Message.playerId), PlayerName, GameName)
			end)
		end

		local Menu = rounded(New("Frame", {
			Name = "MessageActions",
			Position = UDim2.new(1, -118, 0, Compact and 6 or 4),
			Size = UDim2.fromOffset(112, Compact and 28 or 22),
			Visible = false,
			ZIndex = 98,
			ThemeTag = { BackgroundColor3 = "DialogButton" },
			Parent = Row,
		}), 5)
		local Copy = New("TextButton", {
			Text = "Copy",
			Size = UDim2.new(0.5, 0, 1, 0),
			Font = Enum.Font.GothamBold,
			TextSize = 9,
			BackgroundTransparency = 1,
			ZIndex = 99,
			ThemeTag = { TextColor3 = "Text" },
			Parent = Menu,
		})
		local ReplyButton = New("TextButton", {
			Text = "Reply",
			Position = UDim2.fromScale(0.5, 0),
			Size = UDim2.new(0.5, 0, 1, 0),
			Font = Enum.Font.GothamBold,
			TextSize = 9,
			BackgroundTransparency = 1,
			ZIndex = 99,
			ThemeTag = { TextColor3 = "Text" },
			Parent = Menu,
		})
		local More = New("TextButton", {
			Name = "MoreActions",
			Text = "•••",
			Position = UDim2.new(1, -30, 0, Compact and 6 or 4),
			Size = UDim2.fromOffset(24, Compact and 28 or 17),
			Font = Enum.Font.GothamBold,
			TextSize = 10,
			BackgroundTransparency = 1,
			ZIndex = 95,
			ThemeTag = { TextColor3 = "SubText" },
			Parent = Row,
		})
		More.MouseButton1Click:Connect(function()
			if self.OpenMenu and self.OpenMenu ~= Menu then self.OpenMenu.Visible = false end
			Menu.Visible = not Menu.Visible
			self.OpenMenu = Menu.Visible and Menu or nil
		end)
		Copy.MouseButton1Click:Connect(function()
			Menu.Visible = false
			self.OpenMenu = nil
			self:CopyMessage(safeString(Message.content, ""))
		end)
		ReplyButton.MouseButton1Click:Connect(function()
			Menu.Visible = false
			self.OpenMenu = nil
			self:SetReply(Message)
		end)
	end

	task.spawn(function()
		-- UIListLayout can still report zero during the first defer. Wait until its
		-- height is stable so the initial render reliably opens at the latest chat.
		local LastHeight = -1
		for _ = 1, 5 do
			RunService.Heartbeat:Wait()
			if self.Destroyed or Generation ~= self.RenderGeneration or not self.Messages.Parent then return end
			local Height = self.MessageLayout.AbsoluteContentSize.Y
			if Height == LastHeight then break end
			LastHeight = Height
		end
		local NewMax = math.max(0, self.MessageLayout.AbsoluteContentSize.Y + 6 - self.Messages.AbsoluteWindowSize.Y)
		self.Messages.CanvasPosition = Vector2.new(0, FollowLatest and NewMax or math.min(PreviousPosition, NewMax))
	end)
end

function GlobalChat:Refresh()
	local Success, Result = self:Request("GET")
	if not Success then
		self:SetStatus(Result, true)
		return
	end

	local Messages = typeof(Result.messages) == "table" and Result.messages or {}
	local MessageKeys = table.create(#Messages)
	for Index, Message in ipairs(Messages) do
		local JoinData = typeof(Message.joinServer) == "table" and Message.joinServer or nil
		MessageKeys[Index] = tostring(Message.id or Index) .. "\0" .. safeString(Message.content, "")
			.. "\0" .. tostring(JoinData and JoinData.placeId or "")
			.. "\0" .. tostring(JoinData and JoinData.jobId or "")
	end
	local Signature = table.concat(MessageKeys, "\1")
	if Signature ~= self.LastRenderedSignature then
		self:Render(Messages)
		self.LastRenderedSignature = Signature
	end
	local OnlineCount = tonumber(Result.onlineCount) or 0
	self:SetStatus(`{OnlineCount} online`, false)
end

function GlobalChat:SendMessage()
	local Content = self.Input.Text:gsub("^%s+", ""):gsub("%s+$", "")
	if Content == "" or self.Destroyed then
		return
	end

	self.Send.Active = false
	local Success, Result = self:Request("POST", {
		playerId = self.PlayerId,
		playerName = maskedPlayerName(self.PlayerName),
		gameName = self.GameName,
		avatarUrl = self.AvatarUrl,
		content = Content,
		replyToId = self.ReplyingTo and self.ReplyingTo.id or nil,
	})
	self.Send.Active = true

	if not Success then
		self:SetStatus(Result, true)
		return
	end

	self.Input.Text = ""
	self:ClearReply()
	self:SetStatus("message sent", false)
	task.spawn(function()
		task.wait(0.1)
		self:SafeRefresh()
	end)
end

function GlobalChat:StartPolling()
	if self.Endpoint == "" then
		self:SetStatus("endpoint not configured", true)
		return
	end

	task.spawn(function()
		self:SafeRefresh()
		while not self.Destroyed and not (self.Config.Library and self.Config.Library.Unloaded) do
			task.wait(self.PollInterval)
			if not self.Destroyed then
				self:SafeRefresh()
			end
		end
	end)
	task.spawn(function()
		-- Clear any stale sharing left by an earlier script instance.
		self.PresenceBusy = true
		self:PublishPresence()
		self.PresenceBusy = false
		while not self.Destroyed and not (self.Config.Library and self.Config.Library.Unloaded) do
			task.wait(20)
			if self.AllowJoin and not self.PresenceBusy and not self.Destroyed then
				self.PresenceBusy = true
				local Success, Result = self:PublishPresence()
				self.PresenceBusy = false
				if not Success and not self.Destroyed then self:SetStatus(Result, true) end
			end
		end
		if self.AllowJoin then
			self.AllowJoin = false
			self:PublishPresence()
		end
	end)
end

function GlobalChat:Destroy()
	if self.Destroyed then
		return
	end
	self.Destroyed = true
	if self.AllowJoin then
		self.AllowJoin = false
		task.spawn(function()
			while self.PresenceBusy do task.wait() end
			self:PublishPresence()
		end)
	end
	for _, Connection in ipairs(self.Connections) do
		Connection:Disconnect()
	end
	if self.ToggleButton then self.ToggleButton:Destroy() end
	if self.Panel then self.Panel:Destroy() end
end

return GlobalChat
