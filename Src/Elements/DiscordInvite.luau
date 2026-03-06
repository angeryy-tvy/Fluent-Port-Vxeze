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

local function NormalizeInvite(Value)
	local Invite = NormalizeText(Value, "")

	if Invite == "" then
		return ""
	end

	if Invite:find("^https?://") then
		return Invite
	end

	return "https://" .. Invite
end

function Element:New(Idx, Config)
	local Library = self.Library

	if typeof(Idx) == "table" and Config == nil then
		Config = Idx
		Idx = nil
	end

	assert(typeof(Config) == "table", "DiscordInvite - Missing config table")
	assert(Config.Title or Config.ServerName, "DiscordInvite - Missing Title or ServerName")

	local InviteCard = {
		Type = "DiscordInvite",
		Invite = NormalizeText(Config.Invite or Config.InviteUrl, ""),
		Callback = Config.Callback or function() end,
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
		Size = UDim2.new(1, 0, 0, 260),
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
		BackgroundColor3 = Config.BannerColor or Color3.fromRGB(31, 170, 255),
		Parent = CardFrame,
	}, {
		New("UIGradient", {
			Color = ColorSequence.new({
				ColorSequenceKeypoint.new(0, Config.BannerColor or Color3.fromRGB(23, 153, 255)),
				ColorSequenceKeypoint.new(1, Config.BannerColor2 or Color3.fromRGB(112, 237, 244)),
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
		Text = "",
		TextSize = 28,
		TextColor3 = Color3.fromRGB(24, 28, 34),
		Parent = AvatarFrame,
	}) :: TextLabel

	local NameLabel = New("TextLabel", {
		Position = UDim2.fromOffset(16, 122),
		Size = UDim2.new(1, -32, 0, 24),
		BackgroundTransparency = 1,
		Text = "",
		FontFace = Font.new("rbxasset://fonts/families/GothamSSm.json", Enum.FontWeight.Bold, Enum.FontStyle.Normal),
		TextSize = 20,
		TextXAlignment = Enum.TextXAlignment.Left,
		TextYAlignment = Enum.TextYAlignment.Center,
		TextColor3 = Color3.fromRGB(245, 247, 250),
		Parent = CardFrame,
	}) :: TextLabel

	local StatsHolder = New("Frame", {
		Position = UDim2.fromOffset(16, 151),
		Size = UDim2.new(1, -32, 0, 18),
		BackgroundTransparency = 1,
		Parent = CardFrame,
	}, {
		New("UIListLayout", {
			FillDirection = Enum.FillDirection.Horizontal,
			VerticalAlignment = Enum.VerticalAlignment.Center,
			SortOrder = Enum.SortOrder.LayoutOrder,
			Padding = UDim.new(0, 6),
		}),
	}) :: Frame

	local OnlineDot = New("Frame", {
		Size = UDim2.fromOffset(8, 8),
		BackgroundColor3 = Config.OnlineColor or Color3.fromRGB(35, 165, 90),
		Parent = StatsHolder,
	}, {
		New("UICorner", {
			CornerRadius = UDim.new(1, 0),
		}),
	}) :: Frame

	local StatsLabel = New("TextLabel", {
		AutomaticSize = Enum.AutomaticSize.XY,
		Size = UDim2.fromOffset(0, 0),
		BackgroundTransparency = 1,
		Text = "",
		FontFace = Font.new("rbxasset://fonts/families/GothamSSm.json"),
		TextSize = 13,
		TextXAlignment = Enum.TextXAlignment.Left,
		TextYAlignment = Enum.TextYAlignment.Center,
		TextColor3 = Color3.fromRGB(188, 193, 201),
		Parent = StatsHolder,
	}) :: TextLabel

	local CreatedLabel = New("TextLabel", {
		Position = UDim2.fromOffset(16, 172),
		Size = UDim2.new(1, -32, 0, 18),
		BackgroundTransparency = 1,
		Text = "",
		FontFace = Font.new("rbxasset://fonts/families/GothamSSm.json"),
		TextSize = 13,
		TextXAlignment = Enum.TextXAlignment.Left,
		TextYAlignment = Enum.TextYAlignment.Center,
		TextColor3 = Color3.fromRGB(148, 154, 164),
		Parent = CardFrame,
	}) :: TextLabel

	local TagsHolder = New("Frame", {
		Position = UDim2.fromOffset(16, 196),
		Size = UDim2.new(1, -32, 0, 20),
		BackgroundTransparency = 1,
		Parent = CardFrame,
	}, {
		New("UIListLayout", {
			FillDirection = Enum.FillDirection.Horizontal,
			SortOrder = Enum.SortOrder.LayoutOrder,
			Padding = UDim.new(0, 6),
		}),
	}) :: Frame

	local JoinButton = New("TextButton", {
		Position = UDim2.fromOffset(16, 220),
		Size = UDim2.new(1, -32, 0, 28),
		BackgroundColor3 = Config.AccentColor or Color3.fromRGB(35, 165, 90),
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
			Text = "",
			FontFace = Font.new("rbxasset://fonts/families/GothamSSm.json", Enum.FontWeight.Bold, Enum.FontStyle.Normal),
			TextSize = 14,
			TextColor3 = Color3.fromRGB(255, 255, 255),
		}),
	}) :: TextButton

	local JoinLabel = JoinButton.TextLabel

	local function ClearTags()
		for _, Child in next, TagsHolder:GetChildren() do
			if not Child:IsA("UIListLayout") then
				Child:Destroy()
			end
		end
	end

	local function SetTags(Tags)
		ClearTags()

		if typeof(Tags) ~= "table" or #Tags == 0 then
			TagsHolder.Visible = false
			return
		end

		TagsHolder.Visible = true

		for _, Tag in next, Tags do
			local TagText = NormalizeText(Tag, "")
			if TagText ~= "" then
				New("Frame", {
					AutomaticSize = Enum.AutomaticSize.X,
					Size = UDim2.fromOffset(0, 20),
					BackgroundColor3 = Color3.fromRGB(43, 47, 54),
					Parent = TagsHolder,
				}, {
					New("UICorner", {
						CornerRadius = UDim.new(0, 6),
					}),
					New("UIPadding", {
						PaddingLeft = UDim.new(0, 8),
						PaddingRight = UDim.new(0, 8),
					}),
					New("TextLabel", {
						AutomaticSize = Enum.AutomaticSize.XY,
						Size = UDim2.fromOffset(0, 0),
						BackgroundTransparency = 1,
						Text = TagText,
						FontFace = Font.new("rbxasset://fonts/families/GothamSSm.json"),
						TextSize = 11,
						TextColor3 = Color3.fromRGB(220, 223, 228),
						TextXAlignment = Enum.TextXAlignment.Center,
						TextYAlignment = Enum.TextYAlignment.Center,
					}),
				})
			end
		end
	end

	function InviteCard:SetInvite(Value)
		InviteCard.Invite = NormalizeText(Value, "")
		InviteLabel.Text = InviteCard.Invite
		InviteLabel.Visible = InviteCard.Invite ~= ""
	end

	function InviteCard:SetTitle(Value)
		NameLabel.Text = NormalizeText(Value, "Discord Server")
	end

	function InviteCard:SetCreated(Value)
		CreatedLabel.Text = NormalizeText(Value, "")
		CreatedLabel.Visible = CreatedLabel.Text ~= ""
	end

	function InviteCard:SetStats(Online, Members)
		local Parts = {}
		local OnlineText = NormalizeText(Online, "")
		local MemberText = NormalizeText(Members, "")

		if OnlineText ~= "" then
			Parts[#Parts + 1] = OnlineText .. " online"
		end

		if MemberText ~= "" then
			Parts[#Parts + 1] = MemberText .. " members"
		end

		StatsLabel.Text = table.concat(Parts, "  •  ")
		StatsHolder.Visible = StatsLabel.Text ~= ""
	end

	function InviteCard:SetButtonText(Value)
		JoinLabel.Text = NormalizeText(Value, "Join Server")
	end

	function InviteCard:SetBanner(Image)
		local BannerSource = NormalizeImage(Image)
		BannerImage.Visible = BannerSource ~= nil
		BannerImage.Image = BannerSource or ""
	end

	function InviteCard:SetIcon(Image, Initials)
		local IconSource = NormalizeImage(Image)
		AvatarImage.Visible = IconSource ~= nil
		AvatarImage.Image = IconSource or ""
		AvatarInitial.Visible = IconSource == nil
		AvatarInitial.Text = NormalizeText(Initials, NameLabel.Text:sub(1, 1)):upper()
	end

	function InviteCard:SetTags(Tags)
		SetTags(Tags)
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
			Library:SafeCallback(InviteCard.Callback, NormalizeInvite(InviteCard.Invite), InviteCard)
		end
	end)

	InviteCard:SetInvite(InviteCard.Invite)
	InviteCard:SetTitle(Config.Title or Config.ServerName)
	InviteCard:SetStats(Config.Online or Config.OnlineCount, Config.Members or Config.MemberCount)
	InviteCard:SetCreated(Config.Created or Config.Footer or "")
	InviteCard:SetButtonText(Config.ButtonText)
	InviteCard:SetBanner(Config.BannerImage)
	InviteCard:SetIcon(Config.IconImage, Config.Initials or Config.ServerName or Config.Title)
	InviteCard:SetTags(Config.Tags)

	JoinButton.BackgroundTransparency = 0

	if Idx ~= nil then
		Library.Options[Idx] = InviteCard
	end

	InviteCard.Instance = RootFrame

	return InviteCard
end

return Element
