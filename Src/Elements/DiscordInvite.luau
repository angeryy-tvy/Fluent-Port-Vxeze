local Root = script.Parent.Parent
local Creator = require(Root.Modules.Creator)

local New = Creator.New

local Element = {}
Element.__index = Element
Element.__type = "DiscordInvite"

local function NormalizeText(Value, Fallback)
	if typeof(Value) == "string" and Value ~= "" then
		return Value
	end

	if Value ~= nil then
		return tostring(Value)
	end

	return Fallback or ""
end

local function NormalizeImage(Value)
	if typeof(Value) == "string" and Value ~= "" then
		return Value
	end

	return nil
end

local function ParseInvite(Value)
	local Invite = NormalizeText(Value, ""):gsub("%s+", "")

	if Invite == "" then
		return "", ""
	end

	local Code = Invite
	local DiscordMatch = Invite:match("discord%.gg/([%w-_]+)")
	local DiscordComMatch = Invite:match("discord%.com/invite/([%w-_]+)")

	if DiscordMatch then
		Code = DiscordMatch
	elseif DiscordComMatch then
		Code = DiscordComMatch
	end

	return "https://discord.gg/" .. Code, Code
end

function Element:New(Idx, Config)
	local Library = self.Library

	if typeof(Idx) == "table" and Config == nil then
		Config = Idx
		Idx = nil
	end

	assert(typeof(Config) == "table", "DiscordInvite - Missing config table")
	assert(Config.Invite or Config.InviteUrl, "DiscordInvite - Missing Invite")

	local InviteUrl, InviteCode = ParseInvite(Config.Invite or Config.InviteUrl)

	local InviteCard = {
		Type = "DiscordInvite",
		Invite = InviteUrl,
		InviteCode = InviteCode,
		Callback = Config.Callback or function() end,
		Resolver = Config.Resolver,
		Data = nil,
	}

	local RootFrame = New("Frame", {
		AutomaticSize = Enum.AutomaticSize.Y,
		Size = UDim2.new(1, 0, 0, 0),
		BackgroundTransparency = 1,
		Parent = self.Container,
		LayoutOrder = 7,
	}, {
		New("UIListLayout", {
			SortOrder = Enum.SortOrder.LayoutOrder,
			Padding = UDim.new(0, 6),
		}),
	})

	local InviteLabel = New("TextLabel", {
		AutomaticSize = Enum.AutomaticSize.Y,
		Size = UDim2.new(1, 0, 0, 0),
		BackgroundTransparency = 1,
		Text = "",
		TextWrapped = true,
		FontFace = Font.new("rbxasset://fonts/families/GothamSSm.json"),
		TextSize = 12,
		TextXAlignment = Enum.TextXAlignment.Left,
		TextYAlignment = Enum.TextYAlignment.Top,
		TextColor3 = Color3.fromRGB(185, 192, 202),
		Parent = RootFrame,
		ThemeTag = {
			TextColor3 = "SubText",
		},
	}) :: TextLabel

	local CardFrame = New("Frame", {
		Size = UDim2.new(1, 0, 0, 244),
		BackgroundColor3 = Color3.fromRGB(27, 30, 35),
		Parent = RootFrame,
		ClipsDescendants = true,
	}, {
		New("UICorner", {
			CornerRadius = UDim.new(0, 12),
		}),
		New("UIStroke", {
			Transparency = 0.75,
			Color = Color3.fromRGB(255, 255, 255),
		}),
	}) :: Frame

	local BannerFrame = New("Frame", {
		Size = UDim2.new(1, 0, 0, 82),
		BackgroundColor3 = Color3.fromRGB(22, 164, 255),
		Parent = CardFrame,
	}, {
		New("UIGradient", {
			Color = ColorSequence.new({
				ColorSequenceKeypoint.new(0, Color3.fromRGB(22, 164, 255)),
				ColorSequenceKeypoint.new(1, Color3.fromRGB(106, 231, 241)),
			}),
			Rotation = 90,
		}),
	}) :: Frame

	local BannerImage = New("ImageLabel", {
		Size = UDim2.fromScale(1, 1),
		BackgroundTransparency = 1,
		Image = "",
		ScaleType = Enum.ScaleType.Crop,
		Visible = false,
		Parent = BannerFrame,
	}) :: ImageLabel

	local AvatarFrame = New("Frame", {
		Size = UDim2.fromOffset(64, 64),
		Position = UDim2.fromOffset(16, 50),
		BackgroundColor3 = Color3.fromRGB(232, 236, 243),
		Parent = CardFrame,
	}, {
		New("UICorner", {
			CornerRadius = UDim.new(0, 18),
		}),
		New("UIStroke", {
			Transparency = 0.2,
			Color = Color3.fromRGB(40, 42, 48),
			Thickness = 3,
		}),
	}) :: Frame

	local AvatarImage = New("ImageLabel", {
		Size = UDim2.new(1, -8, 1, -8),
		Position = UDim2.fromOffset(4, 4),
		BackgroundTransparency = 1,
		Image = "",
		ScaleType = Enum.ScaleType.Crop,
		Visible = false,
		Parent = AvatarFrame,
	}, {
		New("UICorner", {
			CornerRadius = UDim.new(0, 14),
		}),
	}) :: ImageLabel

	local AvatarInitial = New("TextLabel", {
		Size = UDim2.fromScale(1, 1),
		BackgroundTransparency = 1,
		FontFace = Font.new("rbxasset://fonts/families/GothamSSm.json", Enum.FontWeight.Bold, Enum.FontStyle.Normal),
		Text = "D",
		TextSize = 28,
		TextColor3 = Color3.fromRGB(24, 28, 34),
		Parent = AvatarFrame,
	}) :: TextLabel

	local NameLabel = New("TextLabel", {
		Position = UDim2.fromOffset(16, 122),
		Size = UDim2.new(1, -32, 0, 24),
		BackgroundTransparency = 1,
		Text = "Discord Invite",
		FontFace = Font.new("rbxasset://fonts/families/GothamSSm.json", Enum.FontWeight.Bold, Enum.FontStyle.Normal),
		TextSize = 20,
		TextXAlignment = Enum.TextXAlignment.Left,
		TextYAlignment = Enum.TextYAlignment.Center,
		TextColor3 = Color3.fromRGB(245, 247, 250),
		Parent = CardFrame,
	}) :: TextLabel

	local DescriptionLabel = New("TextLabel", {
		Position = UDim2.fromOffset(16, 151),
		Size = UDim2.new(1, -32, 0, 40),
		BackgroundTransparency = 1,
		Text = "",
		TextWrapped = true,
		FontFace = Font.new("rbxasset://fonts/families/GothamSSm.json"),
		TextSize = 13,
		TextXAlignment = Enum.TextXAlignment.Left,
		TextYAlignment = Enum.TextYAlignment.Top,
		TextColor3 = Color3.fromRGB(188, 193, 201),
		Parent = CardFrame,
	}) :: TextLabel

	local StatsLabel = New("TextLabel", {
		Position = UDim2.fromOffset(16, 190),
		Size = UDim2.new(1, -32, 0, 18),
		BackgroundTransparency = 1,
		Text = "",
		FontFace = Font.new("rbxasset://fonts/families/GothamSSm.json"),
		TextSize = 13,
		TextXAlignment = Enum.TextXAlignment.Left,
		TextYAlignment = Enum.TextYAlignment.Center,
		TextColor3 = Color3.fromRGB(148, 154, 164),
		Parent = CardFrame,
		Visible = false,
	}) :: TextLabel

	local JoinButton = New("TextButton", {
		Position = UDim2.fromOffset(16, 210),
		Size = UDim2.new(1, -32, 0, 28),
		BackgroundColor3 = Color3.fromRGB(35, 165, 90),
		Text = "",
		AutoButtonColor = false,
		Parent = CardFrame,
	}, {
		New("UICorner", {
			CornerRadius = UDim.new(0, 8),
		}),
		New("TextLabel", {
			Size = UDim2.fromScale(1, 1),
			BackgroundTransparency = 1,
			Text = NormalizeText(Config.ButtonText, "Copy Invite"),
			FontFace = Font.new("rbxasset://fonts/families/GothamSSm.json", Enum.FontWeight.Bold, Enum.FontStyle.Normal),
			TextSize = 14,
			TextColor3 = Color3.fromRGB(255, 255, 255),
		}),
	}) :: TextButton

	local JoinLabel = JoinButton.TextLabel

	local function SetLoadingState(Text)
		NameLabel.Text = "Discord Invite"
		DescriptionLabel.Text = Text
		StatsLabel.Visible = false
		BannerImage.Visible = false
		BannerImage.Image = ""
		AvatarImage.Visible = false
		AvatarImage.Image = ""
		AvatarInitial.Visible = true
		AvatarInitial.Text = InviteCode ~= "" and InviteCode:sub(1, 1):upper() or "D"
	end

	local function ApplyData(Data)
		if typeof(Data) ~= "table" then
			InviteCard.Data = nil
			SetLoadingState("Preview unavailable. Provide `Data` or `Resolver` to resolve invite metadata.")
			return
		end

		InviteCard.Data = Data

		local Name = NormalizeText(Data.Name or Data.Title, "Discord Invite")
		local Description = NormalizeText(
			Data.Description,
			(Data.Created and ("Created: " .. tostring(Data.Created))) or "Invite metadata resolved from your backend."
		)
		local Online = NormalizeText(Data.Online or Data.PresenceCount, "")
		local Members = NormalizeText(Data.Members or Data.MemberCount, "")
		local Stats = {}

		if Online ~= "" then
			Stats[#Stats + 1] = Online .. " online"
		end

		if Members ~= "" then
			Stats[#Stats + 1] = Members .. " members"
		end

		NameLabel.Text = Name
		DescriptionLabel.Text = Description
		StatsLabel.Text = table.concat(Stats, "  •  ")
		StatsLabel.Visible = StatsLabel.Text ~= ""

		local Banner = NormalizeImage(Data.Banner or Data.BannerImage)
		BannerImage.Visible = Banner ~= nil
		BannerImage.Image = Banner or ""

		local Icon = NormalizeImage(Data.Icon or Data.IconImage)
		AvatarImage.Visible = Icon ~= nil
		AvatarImage.Image = Icon or ""
		AvatarInitial.Visible = Icon == nil
		AvatarInitial.Text = Name:sub(1, 1):upper()

		if typeof(Data.ButtonText) == "string" and Data.ButtonText ~= "" then
			JoinLabel.Text = Data.ButtonText
		end
	end

	function InviteCard:SetInvite(Value)
		InviteCard.Invite, InviteCard.InviteCode = ParseInvite(Value)
		InviteLabel.Text = InviteCard.Invite
		AvatarInitial.Text = InviteCard.InviteCode ~= "" and InviteCard.InviteCode:sub(1, 1):upper() or "D"
	end

	function InviteCard:SetData(Data)
		ApplyData(Data)
	end

	function InviteCard:Resolve()
		if typeof(InviteCard.Resolver) ~= "function" then
			SetLoadingState("Preview unavailable. Add a `Resolver` function that fetches invite metadata from your API.")
			return
		end

		SetLoadingState("Resolving invite preview...")

		task.spawn(function()
			local Success, Result = pcall(InviteCard.Resolver, InviteCard.Invite, InviteCard.InviteCode, InviteCard)

			if not Success then
				SetLoadingState("Resolver failed. Check your API/proxy response and return shape.")
				return
			end

			ApplyData(Result)
		end)
	end

	function InviteCard:Destroy()
		RootFrame:Destroy()
		if Idx ~= nil then
			Library.Options[Idx] = nil
		end
	end

	Creator.AddSignal(JoinButton.MouseEnter, function()
		JoinButton.BackgroundTransparency = 0.08
	end)
	Creator.AddSignal(JoinButton.MouseLeave, function()
		JoinButton.BackgroundTransparency = 0
	end)
	Creator.AddSignal(JoinButton.MouseButton1Down, function()
		JoinButton.BackgroundTransparency = 0.14
	end)
	Creator.AddSignal(JoinButton.MouseButton1Up, function()
		JoinButton.BackgroundTransparency = 0.08
	end)
	Creator.AddSignal(JoinButton.MouseButton1Click, function()
		if typeof(InviteCard.Callback) == "function" then
			Library:SafeCallback(InviteCard.Callback, InviteCard.Invite, InviteCard.Data, InviteCard)
		end
	end)

	InviteCard:SetInvite(Config.Invite or Config.InviteUrl)
	JoinButton.BackgroundTransparency = 0

	if Config.Data ~= nil then
		InviteCard:SetData(Config.Data)
	else
		InviteCard:Resolve()
	end

	if Idx ~= nil then
		Library.Options[Idx] = InviteCard
	end

	InviteCard.Instance = RootFrame

	return InviteCard
end

return Element
