local TweenService = game:GetService("TweenService")
local Root = script.Parent.Parent
local Creator = require(Root.Modules.Creator)

local New = Creator.New

return function(Title, Parent, Library)
	local Section = {
		Collapsed = false,
		TargetHeight = 0
	}

	Section.Layout = New("UIListLayout", {
		Padding = UDim.new(0, 5),
	})

	Section.Container = New("Frame", {
		Size = UDim2.new(1, 0, 0, 0),
		Position = UDim2.fromOffset(0, 28),
		BackgroundTransparency = 1,
		ClipsDescendants = true,
	}, {
		Section.Layout,
	})

	local ChevronIcon = New("ImageLabel", {
		Size = UDim2.fromOffset(14, 14),
		Position = UDim2.new(1, -5, 0.5, 0),
		AnchorPoint = Vector2.new(1, 0.5),
		BackgroundTransparency = 1,
		Rotation = 0,
		ThemeTag = {
			ImageColor3 = "SubText",
		},
	})

	if Library and Library.Utilities and Library.Utilities.Icons then
		Library.Utilities.Icons:SetIcon(ChevronIcon, "chevron-down")
	else
		ChevronIcon.Image = "rbxassetid://10709790948"
	end

	local HeaderButton = New("TextButton", {
		Size = UDim2.new(1, 0, 0, 24),
		BackgroundTransparency = 1,
		Text = "",
	}, {
		New("TextLabel", {
			RichText = true,
			Text = Title,
			TextTransparency = 0,
			FontFace = Font.new("rbxassetid://12187365364", Enum.FontWeight.SemiBold, Enum.FontStyle.Normal),
			TextSize = 18,
			TextXAlignment = "Left",
			TextYAlignment = "Center",
			Size = UDim2.new(1, -24, 1, 0),
			Position = UDim2.fromOffset(0, 0),
			BackgroundTransparency = 1,
			ThemeTag = {
				TextColor3 = "Text",
			},
		}),
		ChevronIcon,
	})

	Section.Root = New("Frame", {
		BackgroundTransparency = 1,
		Size = UDim2.new(1, 0, 0, 28),
		LayoutOrder = 7,
		Parent = Parent,
		ClipsDescendants = true,
	}, {
		HeaderButton,
		Section.Container,
	})

	local function UpdateSize()
		Section.TargetHeight = Section.Layout.AbsoluteContentSize.Y
		if not Section.Collapsed then
			Section.Container.Size = UDim2.new(1, 0, 0, Section.TargetHeight)
			Section.Root.Size = UDim2.new(1, 0, 0, Section.TargetHeight + 28)
		end
	end

	Creator.AddSignal(Section.Layout:GetPropertyChangedSignal("AbsoluteContentSize"), UpdateSize)

	function Section:Toggle()
		Section.Collapsed = not Section.Collapsed
		
		local tweenInfo = TweenInfo.new(0.25, Enum.EasingStyle.Quint, Enum.EasingDirection.Out)
		
		if Section.Collapsed then
			TweenService:Create(ChevronIcon, tweenInfo, {Rotation = -90}):Play()
			TweenService:Create(Section.Container, tweenInfo, {Size = UDim2.new(1, 0, 0, 0)}):Play()
			TweenService:Create(Section.Root, tweenInfo, {Size = UDim2.new(1, 0, 0, 28)}):Play()
		else
			TweenService:Create(ChevronIcon, tweenInfo, {Rotation = 0}):Play()
			TweenService:Create(Section.Container, tweenInfo, {Size = UDim2.new(1, 0, 0, Section.TargetHeight)}):Play()
			TweenService:Create(Section.Root, tweenInfo, {Size = UDim2.new(1, 0, 0, Section.TargetHeight + 28)}):Play()
		end
	end

	function Section:Expand()
		if Section.Collapsed then
			Section:Toggle()
		end
	end

	function Section:Collapse()
		if not Section.Collapsed then
			Section:Toggle()
		end
	end

	Creator.AddSignal(HeaderButton.MouseButton1Click, function()
		Section:Toggle()
	end)

	return Section
end

