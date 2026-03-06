local TweenService = game:GetService("TweenService")
local Root = script.Parent.Parent
local Creator = require(Root.Modules.Creator)

local New = Creator.New

local function NormalizeIcon(Icon, Library)
	if typeof(Icon) ~= "string" or Icon == "" then
		return nil
	end

	return Icon:find("^rbxasset[://|id://]") == nil and Library.Utilities:GetIcon(Icon) or {
		Image = Icon,
		ImageRectOffset = Vector2.zero,
		ImageRectSize = Vector2.zero,
	}
end

return function(Config, Parent, Library)
	local SubTab = {
		Collapsed = false,
		TargetHeight = 0,
	}

	local Icon = NormalizeIcon(Config.Icon, Library)

	SubTab.Layout = New("UIListLayout", {
		Padding = UDim.new(0, 5),
	})

	SubTab.Container = New("Frame", {
		Size = UDim2.new(1, 0, 0, 0),
		Position = UDim2.fromOffset(0, 34),
		BackgroundTransparency = 1,
		ClipsDescendants = true,
	}, {
		SubTab.Layout,
	})

	local ChevronIcon = New("ImageLabel", {
		Size = UDim2.fromOffset(18, 18),
		Position = UDim2.new(1, -8, 0.5, 0),
		AnchorPoint = Vector2.new(1, 0.5),
		BackgroundTransparency = 1,
		Rotation = 0,
		ThemeTag = {
			ImageColor3 = "Text",
		},
	})

	if Library and Library.Utilities and Library.Utilities.Icons then
		Library.Utilities.Icons:SetIcon(ChevronIcon, "chevron-down")
	else
		ChevronIcon.Image = "rbxassetid://10709790948"
	end

	local HeaderButton = New("TextButton", {
		Size = UDim2.new(1, 0, 0, 30),
		BackgroundTransparency = 0.08,
		Text = "",
		ThemeTag = {
			BackgroundColor3 = "Tab",
			BackgroundTransparency = "ElementTransparency",
		},
	}, {
		New("UICorner", {
			CornerRadius = UDim.new(0, 6),
		}),
		New("ImageLabel", {
			AnchorPoint = Vector2.new(0, 0.5),
			Position = UDim2.new(0, 10, 0.5, 0),
			Size = UDim2.fromOffset(16, 16),
			BackgroundTransparency = 1,
			ImageRectOffset = Icon and Icon.ImageRectOffset or Vector2.zero,
			ImageRectSize = Icon and Icon.ImageRectSize or Vector2.zero,
			Image = Icon and Icon.Image or nil,
			Visible = Icon ~= nil,
			ThemeTag = {
				ImageColor3 = "Text",
			},
		}),
		New("TextLabel", {
			RichText = true,
			Text = Config.Title,
			TextTransparency = 0,
			FontFace = Font.new("rbxassetid://12187365364", Enum.FontWeight.SemiBold, Enum.FontStyle.Normal),
			TextSize = 15,
			TextXAlignment = Enum.TextXAlignment.Left,
			TextYAlignment = Enum.TextYAlignment.Center,
			Size = UDim2.new(1, -44, 1, 0),
			Position = Icon and UDim2.fromOffset(32, 0) or UDim2.fromOffset(10, 0),
			BackgroundTransparency = 1,
			ThemeTag = {
				TextColor3 = "Text",
			},
		}),
		ChevronIcon,
	})

	SubTab.Root = New("Frame", {
		BackgroundTransparency = 1,
		Size = UDim2.new(1, 0, 0, 34),
		LayoutOrder = 7,
		Parent = Parent,
		ClipsDescendants = true,
	}, {
		HeaderButton,
		SubTab.Container,
	})

	local function UpdateSize()
		SubTab.TargetHeight = SubTab.Layout.AbsoluteContentSize.Y
		if not SubTab.Collapsed then
			SubTab.Container.Size = UDim2.new(1, 0, 0, SubTab.TargetHeight)
			SubTab.Root.Size = UDim2.new(1, 0, 0, SubTab.TargetHeight + 34)
		end
	end

	Creator.AddSignal(SubTab.Layout:GetPropertyChangedSignal("AbsoluteContentSize"), UpdateSize)

	function SubTab:Toggle()
		SubTab.Collapsed = not SubTab.Collapsed

		local Tween = TweenInfo.new(0.25, Enum.EasingStyle.Quint, Enum.EasingDirection.Out)

		if SubTab.Collapsed then
			TweenService:Create(ChevronIcon, Tween, { Rotation = -90 }):Play()
			TweenService:Create(SubTab.Container, Tween, { Size = UDim2.new(1, 0, 0, 0) }):Play()
			TweenService:Create(SubTab.Root, Tween, { Size = UDim2.new(1, 0, 0, 34) }):Play()
		else
			TweenService:Create(ChevronIcon, Tween, { Rotation = 0 }):Play()
			TweenService:Create(SubTab.Container, Tween, { Size = UDim2.new(1, 0, 0, SubTab.TargetHeight) }):Play()
			TweenService:Create(SubTab.Root, Tween, { Size = UDim2.new(1, 0, 0, SubTab.TargetHeight + 34) }):Play()
		end
	end

	function SubTab:Expand()
		if SubTab.Collapsed then
			SubTab:Toggle()
		end
	end

	function SubTab:Collapse()
		if not SubTab.Collapsed then
			SubTab:Toggle()
		end
	end

	Creator.AddSignal(HeaderButton.MouseButton1Click, function()
		SubTab:Toggle()
	end)

	return SubTab
end
