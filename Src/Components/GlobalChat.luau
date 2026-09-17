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

local GlobalChat = {}
GlobalChat.__index = GlobalChat

local function safeString(Value, Fallback)
	return typeof(Value) == "string" and Value ~= "" and Value or Fallback
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
		Player = Player,
		PlayerId = tostring(Config.PlayerId or (Player and Player.UserId) or "guest"),
		PlayerName = PlayerName,
		GameName = resolveGameName(Config),
		AvatarUrl = resolveAvatarUrl(Config, Player),
		Endpoint = safeString(Config.Endpoint, ""),
		ApiKey = safeString(Config.ApiKey, ""),
		HttpRequest = resolveHttpRequest(Config),
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
	local HeaderHeight = Compact and 44 or 48
	local ContentTop = HeaderHeight + 4
	local ComposerHeight = Compact and 44 or 34
	local BottomInset = Compact and 8 or 12
	local ComposerGap = Compact and 6 or 8
	local HorizontalInset = Compact and 8 or 10
	local SendWidth = Compact and 72 or 62

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
		Position = UDim2.fromOffset(16, 9),
		Size = UDim2.new(1, -80, 0, 18),
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
		Position = UDim2.fromOffset(16, 27),
		Size = UDim2.new(1, -80, 0, 14),
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

	self.MessageLayout = New("UIListLayout", {
		Padding = UDim.new(0, 5),
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
	table.insert(self.Connections, self.Input.FocusLost:Connect(function(EnterPressed)
		if EnterPressed then
			self:SendMessage()
		end
	end))
	table.insert(self.Connections, self.MessageLayout:GetPropertyChangedSignal("AbsoluteContentSize"):Connect(function()
		self.Messages.CanvasSize = UDim2.fromOffset(0, self.MessageLayout.AbsoluteContentSize.Y + 6)
	end))
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
	self.Status.Text = IsError and ("●  " .. Text) or ("●  " .. Text)
	self.Status.TextColor3 = IsError and Color3.fromRGB(255, 130, 130) or Creator.GetThemeProperty("SubText")
end

function GlobalChat:Request(Method, Payload)
	if self.Endpoint == "" then
		return false, "Set Config.Endpoint to enable online chat"
	end

	local Headers = { ["Content-Type"] = "application/json" }
	if self.ApiKey ~= "" then
		Headers["X-Global-Chat-Key"] = self.ApiKey
	end

	local Request = {
		Url = Method == "GET" and (self.Endpoint .. (self.Endpoint:find("?", 1, true) and "&" or "?") .. "limit=" .. tostring(self.MaxMessages)) or self.Endpoint,
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

function GlobalChat:Render(Messages)
	local PreviousPosition = self.Messages.CanvasPosition.Y
	local PreviousMax = math.max(0, self.Messages.CanvasSize.Y.Offset - self.Messages.AbsoluteWindowSize.Y)
	local FollowLatest = PreviousMax - PreviousPosition <= 24

	for _, Child in next, self.Messages:GetChildren() do
		if Child ~= self.MessageLayout and Child ~= self.EmptyState then
			Child:Destroy()
		end
	end

	self.EmptyState.Visible = #Messages == 0
	for Index, Message in ipairs(Messages) do
		local PlayerName = safeString(Message.playerName, "Guest")
		local DisplayName = maskedPlayerName(PlayerName)
		local Initials = safeString(Message.initials, initials(PlayerName))
		local GameName = safeString(Message.gameName, "Unknown game")
		local AvatarUrl = safeString(Message.avatarUrl, "")
		local Time = formatChatTime(Message.createdAt)

		local Row = rounded(New("Frame", {
			Size = UDim2.new(1, -4, 0, 42),
			BackgroundTransparency = 0.55,
			LayoutOrder = Index,
			ZIndex = 92,
			ThemeTag = { BackgroundColor3 = "DialogHolder" },
			Parent = self.Messages,
		}), 7)

		local Avatar = rounded(New("ImageLabel", {
			Position = UDim2.fromOffset(7, 7),
			Size = UDim2.fromOffset(28, 28),
			Image = AvatarUrl,
			Visible = AvatarUrl ~= "",
			ZIndex = 93,
			Parent = Row,
		}), 14)
		if AvatarUrl ~= "" then
			New("UICorner", { CornerRadius = UDim.new(1, 0), Parent = Avatar })
		end

		local InitialsLabel = rounded(New("TextLabel", {
			Position = UDim2.fromOffset(7, 7),
			Size = UDim2.fromOffset(28, 28),
			Text = Initials,
			TextSize = 10,
			Font = Enum.Font.GothamBold,
			Visible = AvatarUrl == "",
			ZIndex = 93,
			ThemeTag = { TextColor3 = "Text", BackgroundColor3 = "Accent" },
			Parent = Row,
		}), 14)

		local Meta = New("TextLabel", {
			Position = UDim2.fromOffset(44, 5),
			Size = UDim2.new(1, -52, 0, 14),
			Text = `{DisplayName}  •  {GameName}  •  {Time}`,
			TextTruncate = Enum.TextTruncate.AtEnd,
			TextXAlignment = Enum.TextXAlignment.Left,
			Font = Enum.Font.GothamBold,
			TextSize = 10,
			ZIndex = 93,
			ThemeTag = { TextColor3 = "SubText" },
			Parent = Row,
		})

		New("TextLabel", {
			Position = UDim2.fromOffset(44, 19),
			Size = UDim2.new(1, -52, 0, 18),
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
	end

	task.defer(function()
		if not self.Destroyed and self.Messages.Parent then
			local NewMax = math.max(0, self.MessageLayout.AbsoluteContentSize.Y + 6 - self.Messages.AbsoluteWindowSize.Y)
			self.Messages.CanvasPosition = Vector2.new(0, FollowLatest and NewMax or math.min(PreviousPosition, NewMax))
		end
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
		MessageKeys[Index] = tostring(Message.id or Index) .. "\0" .. safeString(Message.content, "")
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
	})
	self.Send.Active = true

	if not Success then
		self:SetStatus(Result, true)
		return
	end

	self.Input.Text = ""
	self:SetStatus("message sent", false)
	task.spawn(function()
		task.wait(0.1)
		self:Refresh()
	end)
end

function GlobalChat:StartPolling()
	if self.Endpoint == "" then
		self:SetStatus("endpoint not configured", true)
		return
	end

	task.spawn(function()
		self:Refresh()
		while not self.Destroyed and not (self.Config.Library and self.Config.Library.Unloaded) do
			task.wait(self.PollInterval)
			if not self.Destroyed then
				self:Refresh()
			end
		end
	end)
end

function GlobalChat:Destroy()
	if self.Destroyed then
		return
	end
	self.Destroyed = true
	for _, Connection in ipairs(self.Connections) do
		Connection:Disconnect()
	end
	if self.ToggleButton then self.ToggleButton:Destroy() end
	if self.Panel then self.Panel:Destroy() end
end

return GlobalChat
