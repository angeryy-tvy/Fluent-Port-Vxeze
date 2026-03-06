local Root = script.Parent.Parent
local Flipper = require(Root.Packages.Flipper)
local Creator = require(Root.Modules.Creator)
local Layout = require(Root.Modules.Layout)
local TweenService = game:GetService("TweenService")

local New = Creator.New
local Spring = Flipper.Spring.new

local TabModule = {
	Window = nil,
	Tabs = {},
	SelectedTab = 0,
	SelectedItem = nil,
	TabCount = 0,
	SearchQuery = "",
	SearchVisibility = {},
}

local function NormalizeQuery(Query)
	if typeof(Query) ~= "string" then
		return ""
	end

	return (Query:lower():gsub("^%s+", ""):gsub("%s+$", ""))
end

local function IsLayoutObject(Object)
	return Object:IsA("UIListLayout")
		or Object:IsA("UIPadding")
		or Object:IsA("UIGridLayout")
		or Object:IsA("UITableLayout")
		or Object:IsA("UIPageLayout")
		or Object:IsA("UIAspectRatioConstraint")
		or Object:IsA("UISizeConstraint")
end

local function TextMatches(Text, Query)
	return typeof(Text) == "string" and Text ~= "" and string.find(string.lower(Text), Query, 1, true) ~= nil
end

local function ObjectMatchesQuery(Object, Query)
	if Object:IsA("TextLabel") or Object:IsA("TextButton") or Object:IsA("TextBox") then
		if TextMatches(Object.Text, Query) then
			return true
		end
	end

	if Object:IsA("TextBox") and TextMatches(Object.PlaceholderText, Query) then
		return true
	end

	for _, Descendant in next, Object:GetDescendants() do
		if Descendant:IsA("TextLabel") or Descendant:IsA("TextButton") or Descendant:IsA("TextBox") then
			if TextMatches(Descendant.Text, Query) then
				return true
			end
		end

		if Descendant:IsA("TextBox") and TextMatches(Descendant.PlaceholderText, Query) then
			return true
		end
	end

	return false
end

local function CacheVisibility(Cache, Object)
	if Cache[Object] == nil then
		Cache[Object] = Object.Visible
	end
end

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

local function CreatePageContainer(Window)
	return New("ScrollingFrame", {
		Size = UDim2.fromScale(1, 1),
		BackgroundTransparency = 1,
		Parent = Window.ContainerHolder,
		Visible = false,
		BottomImage = "rbxassetid://6889812791",
		MidImage = "rbxassetid://6889812721",
		TopImage = "rbxassetid://6276641225",
		ScrollBarImageColor3 = Color3.fromRGB(255, 255, 255),
		ScrollBarImageTransparency = 0.95,
		ScrollBarThickness = 3,
		BorderSizePixel = 0,
		CanvasSize = UDim2.fromScale(0, 0),
		ScrollingDirection = Enum.ScrollingDirection.Y,
	}, {
		New("UIListLayout", {
			Padding = UDim.new(0, Layout.Page.ItemGap),
			SortOrder = Enum.SortOrder.LayoutOrder,
		}),
		New("UIPadding", {
			PaddingRight = UDim.new(0, Layout.Page.PaddingRight),
			PaddingLeft = UDim.new(0, Layout.Page.PaddingLeft),
			PaddingTop = UDim.new(0, Layout.Page.PaddingTop),
			PaddingBottom = UDim.new(0, Layout.Page.PaddingBottom),
		}),
	})
end

local function BindCanvasSize(ContainerFrame)
	local Layout = ContainerFrame.UIListLayout
	Creator.AddSignal(Layout:GetPropertyChangedSignal("AbsoluteContentSize"), function()
		local TargetCanvas = UDim2.fromOffset(0, Layout.AbsoluteContentSize.Y + 2)
		if ContainerFrame.CanvasSize ~= TargetCanvas then
			ContainerFrame.CanvasSize = TargetCanvas
		end
	end)
end

local function AddSectionAPI(Target, Elements, Library, SectionParent, ScrollFrame)
	function Target:Section(SectionTitle)
		local Section = {
			Type = "Section",
		}

		local SectionFrame = require(Root.Components.Section)(SectionTitle, SectionParent, Library)
		Section.Container = SectionFrame.Container
		Section.ScrollFrame = ScrollFrame
		Section.Toggle = function()
			SectionFrame:Toggle()
		end
		Section.Expand = function()
			SectionFrame:Expand()
		end
		Section.Collapse = function()
			SectionFrame:Collapse()
		end

		Target.Container = SectionFrame.Container

		setmetatable(Section, Elements)
		return Section
	end

	Target.CreateSection = Target.Section
	Target.AddSection = Target.Section
end

local function HideAllContainers()
	for _, Tab in next, TabModule.Tabs do
		Tab.ContainerFrame.Visible = false
		for _, SubTab in next, Tab.SubTabs do
			SubTab.ContainerFrame.Visible = false
		end
	end
end

local function RefreshTabDropdown(Tab)
	local ShowChildren = Tab.SubTabCount > 0 and (Tab.Expanded or Tab.SearchExpanded)
	local TargetHeight = 0

	Tab.Chevron.Visible = Tab.SubTabCount > 0
	Tab.DropdownHitbox.Visible = Tab.SubTabCount > 0
	Tab.Chevron.Rotation = ShowChildren and 0 or -90

	local VisibleCount = 0

	for _, SubTab in next, Tab.SubTabs do
		local SearchAllows = TabModule.SearchQuery == "" or SubTab.SearchVisible ~= false
		SubTab.Frame.Visible = ShowChildren and SearchAllows

		if ShowChildren and SearchAllows then
			VisibleCount += 1
			TargetHeight += SubTab.Frame.Size.Y.Offset
		end
	end

	if VisibleCount > 1 then
		TargetHeight += Tab.SubTabLayout.Padding.Offset * (VisibleCount - 1)
	end

	Tab.SubTabHolder.Visible = ShowChildren
	Tab.SubTabHolder.Size = UDim2.new(1, 0, 0, TargetHeight)
	Tab.Root.Size = UDim2.new(1, 0, 0, 38 + TargetHeight)
end

local function AnimateTabDropdown(Tab)
	local ShowChildren = Tab.SubTabCount > 0 and (Tab.Expanded or Tab.SearchExpanded)
	local TweenInfoData = TweenInfo.new(0.2, Enum.EasingStyle.Quint, Enum.EasingDirection.Out)
	local TargetHeight = 0
	local VisibleCount = 0

	Tab.Chevron.Visible = Tab.SubTabCount > 0
	Tab.DropdownHitbox.Visible = Tab.SubTabCount > 0

	for _, SubTab in next, Tab.SubTabs do
		local SearchAllows = TabModule.SearchQuery == "" or SubTab.SearchVisible ~= false
		SubTab.Frame.Visible = ShowChildren and SearchAllows

		if ShowChildren and SearchAllows then
			VisibleCount += 1
			TargetHeight += SubTab.Frame.Size.Y.Offset
		end
	end

	if VisibleCount > 1 then
		TargetHeight += Tab.SubTabLayout.Padding.Offset * (VisibleCount - 1)
	end

	if ShowChildren then
		Tab.SubTabHolder.Visible = true
	end

	TweenService:Create(Tab.Chevron, TweenInfoData, {
		Rotation = ShowChildren and 0 or -90,
	}):Play()
	TweenService:Create(Tab.SubTabHolder, TweenInfoData, {
		Size = UDim2.new(1, 0, 0, TargetHeight),
	}):Play()
	TweenService:Create(Tab.Root, TweenInfoData, {
		Size = UDim2.new(1, 0, 0, 38 + TargetHeight),
	}):Play()

	if not ShowChildren then
		task.delay(TweenInfoData.Time, function()
			if not Tab.Expanded and not Tab.SearchExpanded then
				Tab.SubTabHolder.Visible = false
			end
		end)
	end
end

local function GetFirstMatchingItem(Tab, Query, HasTabContentMatch)
	if TextMatches(Tab.Name, Query) or HasTabContentMatch then
		return Tab
	end

	for _, SubTab in next, Tab.SubTabs do
		if SubTab.SearchVisible then
			return SubTab
		end
	end

	return nil
end

function TabModule:Init(Window)
	TabModule.Window = Window
	return TabModule
end

function TabModule:GetCurrentTabPos()
	if not TabModule.SelectedItem or not TabModule.SelectedItem.Frame then
		return 0
	end

	local TabHolderPos = TabModule.Window.TabHolder.AbsolutePosition.Y
	local TabPos = TabModule.SelectedItem.Frame.AbsolutePosition.Y

	return TabPos - TabHolderPos
end

function TabModule:RestoreSearch()
	for Object, State in next, TabModule.SearchVisibility do
		if typeof(Object) == "Instance" and Object.Parent and Object:IsA("GuiObject") then
			Object.Visible = State
		end
	end

	for _, Tab in next, TabModule.Tabs do
		Tab.SearchExpanded = false
		Tab.Root.Visible = true
		for _, SubTab in next, Tab.SubTabs do
			SubTab.SearchVisible = nil
		end
		RefreshTabDropdown(Tab)
	end

	table.clear(TabModule.SearchVisibility)
end

function TabModule:SelectItem(TabIndex, Item)
	local Window = TabModule.Window
	local Tab = TabModule.Tabs[TabIndex]

	if not Tab or not Item or not Item.Frame or Item.Frame.Visible == false then
		return
	end

	TabModule.SelectedTab = TabIndex
	TabModule.SelectedItem = Item

	for _, ExistingTab in next, TabModule.Tabs do
		ExistingTab.SetTransparency(0.97)
		ExistingTab.Selected = false
		for _, SubTab in next, ExistingTab.SubTabs do
			SubTab.SetTransparency(0.99)
			SubTab.Selected = false
		end
	end

	if Item.Type == "SubTab" then
		Tab.SetTransparency(0.84)
		Tab.Selected = true
		Item.SetTransparency(0.72)
		Item.Selected = true
		Tab.Expanded = true
		RefreshTabDropdown(Tab)
	else
		Tab.SetTransparency(0.8)
		Tab.Selected = true
	end

	Window.TabDisplay.Text = Item.Name
	Window.SelectorPosMotor:setGoal(Spring(TabModule:GetCurrentTabPos(), { frequency = 6 }))

	task.spawn(function()
		Window.ContainerHolder.Parent = Window.ContainerAnim

		Window.ContainerPosMotor:setGoal(Spring(15, { frequency = 10 }))
		Window.ContainerBackMotor:setGoal(Spring(1, { frequency = 10 }))

		task.wait(0.12)

		HideAllContainers()

		Item.ContainerFrame.Visible = true
		Window.ContainerPosMotor:setGoal(Spring(0, { frequency = 5 }))
		Window.ContainerBackMotor:setGoal(Spring(0, { frequency = 8 }))

		task.wait(0.12)

		Window.ContainerHolder.Parent = Window.ContainerCanvas
	end)
end

function TabModule:SelectTab(TabIndex)
	local Tab = TabModule.Tabs[TabIndex]
	if Tab then
		TabModule:SelectItem(TabIndex, Tab)
	end
end

function TabModule:ApplySearch(Query)
	Query = NormalizeQuery(Query)
	TabModule.SearchQuery = Query

	if Query == "" then
		TabModule:RestoreSearch()

		if TabModule.SelectedItem and TabModule.SelectedItem.Frame and TabModule.SelectedItem.Frame.Visible then
			TabModule.Window.TabDisplay.Text = TabModule.SelectedItem.Name
		elseif TabModule.Tabs[1] then
			TabModule:SelectTab(1)
		end

		return
	end

	local FirstVisibleItem = nil
	local CurrentSelectionVisible = false

	for TabIndex = 1, TabModule.TabCount do
		local Tab = TabModule.Tabs[TabIndex]
		local HasTabContentMatch = false
		local HasSubTabMatch = false

		for _, Child in next, Tab.ContainerFrame:GetChildren() do
			if Child:IsA("GuiObject") and not IsLayoutObject(Child) then
				local Match = ObjectMatchesQuery(Child, Query)
				CacheVisibility(TabModule.SearchVisibility, Child)
				Child.Visible = Match
				HasTabContentMatch = HasTabContentMatch or Match
			end
		end

		for _, SubTab in next, Tab.SubTabs do
			local HasSubTabContentMatch = false

			for _, Child in next, SubTab.ContainerFrame:GetChildren() do
				if Child:IsA("GuiObject") and not IsLayoutObject(Child) then
					local Match = ObjectMatchesQuery(Child, Query)
					CacheVisibility(TabModule.SearchVisibility, Child)
					Child.Visible = Match
					HasSubTabContentMatch = HasSubTabContentMatch or Match
				end
			end

			SubTab.SearchVisible = TextMatches(SubTab.Name, Query) or HasSubTabContentMatch
			HasSubTabMatch = HasSubTabMatch or SubTab.SearchVisible
			CacheVisibility(TabModule.SearchVisibility, SubTab.Frame)
		end

		local TabVisible = TextMatches(Tab.Name, Query) or HasTabContentMatch or HasSubTabMatch
		CacheVisibility(TabModule.SearchVisibility, Tab.Frame)
		Tab.Frame.Visible = TabVisible
		Tab.Root.Visible = TabVisible
		Tab.SearchExpanded = HasSubTabMatch
		RefreshTabDropdown(Tab)

		if not FirstVisibleItem then
			FirstVisibleItem = GetFirstMatchingItem(Tab, Query, HasTabContentMatch)
		end

		if TabModule.SelectedItem == Tab and Tab.Frame.Visible then
			CurrentSelectionVisible = true
		else
			for _, SubTab in next, Tab.SubTabs do
				if TabModule.SelectedItem == SubTab and SubTab.Frame.Visible then
					CurrentSelectionVisible = true
				end
			end
		end
	end

	if not FirstVisibleItem then
		HideAllContainers()
		TabModule.Window.TabDisplay.Text = "No results"
		return
	end

	if not CurrentSelectionVisible then
		for TabIndex, Tab in next, TabModule.Tabs do
			if FirstVisibleItem == Tab then
				TabModule:SelectItem(TabIndex, Tab)
				return
			end

			for _, SubTab in next, Tab.SubTabs do
				if FirstVisibleItem == SubTab then
					TabModule:SelectItem(TabIndex, SubTab)
					return
				end
			end
		end
	end
end

function TabModule:New(Title, Icon, Parent)
	local Library = require(Root)
	local Window = TabModule.Window
	local Elements = Library.Elements
	local TabIcon = NormalizeIcon(Icon, Library)

	TabModule.TabCount = TabModule.TabCount + 1
	local TabIndex = TabModule.TabCount

	local Tab = {
		Selected = false,
		Expanded = false,
		SearchExpanded = false,
		Name = Title,
		Type = "Tab",
		SubTabs = {},
		SubTabCount = 0,
	}

	Tab.Root = New("Frame", {
		Size = UDim2.new(1, 0, 0, 38),
		BackgroundTransparency = 1,
		Parent = Parent,
		LayoutOrder = TabIndex,
		ClipsDescendants = true,
	})

	Tab.Frame = New("TextButton", {
		Size = UDim2.new(1, 0, 0, 38),
		BackgroundTransparency = 0.97,
		Parent = Tab.Root,
		ThemeTag = {
			BackgroundColor3 = "Tab",
		},
	}, {
		New("UICorner", {
			CornerRadius = UDim.new(0, 9),
		}),
		New("UIStroke", {
			Transparency = 0.4,
			ThemeTag = {
				Color = "InElementBorder",
			},
		}),
		New("TextLabel", {
			AnchorPoint = Vector2.new(0, 0.5),
			Position = TabIcon ~= nil and UDim2.new(0, 38, 0.5, 0) or UDim2.new(0, 14, 0.5, 0),
			Text = Title,
			RichText = true,
			TextColor3 = Color3.fromRGB(255, 255, 255),
			TextTransparency = 0,
			FontFace = Font.new(
				"rbxasset://fonts/families/GothamSSm.json",
				Enum.FontWeight.SemiBold,
				Enum.FontStyle.Normal
			),
			TextSize = 13,
			TextXAlignment = Enum.TextXAlignment.Left,
			TextYAlignment = Enum.TextYAlignment.Center,
			Size = UDim2.new(1, -54, 1, 0),
			BackgroundTransparency = 1,
			ThemeTag = {
				TextColor3 = "Text",
			},
		}),
		New("ImageLabel", {
			AnchorPoint = Vector2.new(0, 0.5),
			Size = UDim2.fromOffset(18, 18),
			Position = UDim2.new(0, 12, 0.5, 0),
			BackgroundTransparency = 1,
			ImageRectOffset = TabIcon and TabIcon.ImageRectOffset or Vector2.zero,
			ImageRectSize = TabIcon and TabIcon.ImageRectSize or Vector2.zero,
			Image = TabIcon and TabIcon.Image or nil,
			ThemeTag = {
				ImageColor3 = "Text",
			},
		}),
	})

	Tab.Chevron = New("ImageLabel", {
		AnchorPoint = Vector2.new(1, 0.5),
		Position = UDim2.new(1, -12, 0.5, 0),
		Size = UDim2.fromOffset(14, 14),
		BackgroundTransparency = 1,
		Visible = false,
		Rotation = -90,
		Parent = Tab.Frame,
		ThemeTag = {
			ImageColor3 = "SubText",
		},
	})
	Library.Utilities.Icons:SetIcon(Tab.Chevron, "chevron-down")

	Tab.DropdownHitbox = New("TextButton", {
		AnchorPoint = Vector2.new(1, 0.5),
		Position = UDim2.new(1, 0, 0.5, 0),
		Size = UDim2.fromOffset(32, 32),
		BackgroundTransparency = 1,
		Text = "",
		Visible = false,
		Parent = Tab.Frame,
	})

	Tab.SubTabLayout = New("UIListLayout", {
		Padding = UDim.new(0, 4),
		SortOrder = Enum.SortOrder.LayoutOrder,
	})

	Tab.SubTabHolder = New("Frame", {
		Size = UDim2.new(1, 0, 0, 0),
		Position = UDim2.fromOffset(0, 38),
		BackgroundTransparency = 1,
		Visible = false,
		Parent = Tab.Root,
		ClipsDescendants = true,
	}, {
		New("UIPadding", {
			PaddingLeft = UDim.new(0, 16),
		}),
		Tab.SubTabLayout,
	})

	Creator.AddSignal(Tab.SubTabLayout:GetPropertyChangedSignal("AbsoluteContentSize"), function()
		RefreshTabDropdown(Tab)
	end)

	Tab.ContainerFrame = CreatePageContainer(Window)
	BindCanvasSize(Tab.ContainerFrame)
	Tab.Motor, Tab.SetTransparency = Creator.SpringMotor(0.97, Tab.Frame, "BackgroundTransparency")

	function Tab:ToggleSubTabs()
		if Tab.SubTabCount == 0 then
			return
		end

		if Tab.Expanded and TabModule.SelectedItem and TabModule.SelectedItem.ParentTab == Tab then
			TabModule:SelectItem(TabIndex, Tab)
		end

		Tab.Expanded = not Tab.Expanded
		AnimateTabDropdown(Tab)
	end

	function Tab:ExpandSubTabs()
		if Tab.SubTabCount == 0 or Tab.Expanded then
			return
		end

		Tab.Expanded = true
		AnimateTabDropdown(Tab)
	end

	function Tab:CollapseSubTabs()
		if not Tab.Expanded then
			return
		end

		if TabModule.SelectedItem and TabModule.SelectedItem.ParentTab == Tab then
			TabModule:SelectItem(TabIndex, Tab)
		end

		Tab.Expanded = false
		AnimateTabDropdown(Tab)
	end

	Creator.AddSignal(Tab.Frame.MouseEnter, function()
		Tab.SetTransparency(Tab.Selected and 0.72 or 0.9)
	end)
	Creator.AddSignal(Tab.Frame.MouseLeave, function()
		Tab.SetTransparency(Tab.Selected and 0.8 or 0.97)
	end)
	Creator.AddSignal(Tab.Frame.MouseButton1Down, function()
		Tab.SetTransparency(0.66)
	end)
	Creator.AddSignal(Tab.Frame.MouseButton1Up, function()
		if Tab.Selected and TabModule.SelectedItem ~= Tab then
			Tab.SetTransparency(0.86)
		else
			Tab.SetTransparency(Tab.Selected and 0.72 or 0.9)
		end
	end)
	Creator.AddSignal(Tab.Frame.MouseButton1Click, function()
		TabModule:SelectItem(TabIndex, Tab)
	end)
	Creator.AddSignal(Tab.DropdownHitbox.MouseButton1Click, function()
		Tab:ToggleSubTabs()
	end)

	TabModule.Tabs[TabIndex] = Tab

	Tab.Container = Tab.ContainerFrame
	Tab.ScrollFrame = Tab.ContainerFrame
	AddSectionAPI(Tab, Elements, Library, Tab.ContainerFrame, Tab.ContainerFrame)

	function Tab:SubTab(SubTabConfig)
		assert(typeof(SubTabConfig) == "table", "SubTab - Missing config table")
		assert(SubTabConfig.Title, "SubTab - Missing Title")

		Tab.SubTabCount = Tab.SubTabCount + 1
		local SubTabIndex = Tab.SubTabCount
		local SubIcon = NormalizeIcon(SubTabConfig.Icon, Library)

		local SubTab = {
			Name = SubTabConfig.Title,
			Type = "SubTab",
			ParentTab = Tab,
			SearchVisible = nil,
		}

		SubTab.Frame = New("TextButton", {
			Size = UDim2.new(1, 0, 0, 30),
			BackgroundTransparency = 0.99,
			Parent = Tab.SubTabHolder,
			Visible = false,
			LayoutOrder = SubTabIndex,
			ThemeTag = {
				BackgroundColor3 = "Tab",
			},
			Text = "",
		}, {
			New("UICorner", {
				CornerRadius = UDim.new(0, 8),
			}),
			New("UIStroke", {
				Transparency = 0.55,
				ThemeTag = {
					Color = "InElementBorder",
				},
			}),
			New("TextLabel", {
				AnchorPoint = Vector2.new(0, 0.5),
				Position = SubIcon ~= nil and UDim2.new(0, 34, 0.5, 0) or UDim2.new(0, 14, 0.5, 0),
				Text = SubTabConfig.Title,
				RichText = true,
				TextColor3 = Color3.fromRGB(220, 220, 220),
				TextTransparency = 0,
				FontFace = Font.new(
					"rbxasset://fonts/families/GothamSSm.json",
					Enum.FontWeight.Medium,
					Enum.FontStyle.Normal
				),
				TextSize = 12,
				TextXAlignment = Enum.TextXAlignment.Left,
				TextYAlignment = Enum.TextYAlignment.Center,
				Size = UDim2.new(1, -34, 1, 0),
				BackgroundTransparency = 1,
				ThemeTag = {
					TextColor3 = "SubText",
				},
			}),
			New("ImageLabel", {
				AnchorPoint = Vector2.new(0, 0.5),
				Size = UDim2.fromOffset(14, 14),
				Position = UDim2.new(0, 14, 0.5, 0),
				BackgroundTransparency = 1,
				ImageRectOffset = SubIcon and SubIcon.ImageRectOffset or Vector2.zero,
				ImageRectSize = SubIcon and SubIcon.ImageRectSize or Vector2.zero,
				Image = SubIcon and SubIcon.Image or nil,
				Visible = SubIcon ~= nil,
				ThemeTag = {
					ImageColor3 = "SubText",
				},
			}),
		})

		SubTab.ContainerFrame = CreatePageContainer(Window)
		BindCanvasSize(SubTab.ContainerFrame)
		SubTab.Motor, SubTab.SetTransparency = Creator.SpringMotor(0.99, SubTab.Frame, "BackgroundTransparency")

		Creator.AddSignal(SubTab.Frame.MouseEnter, function()
			SubTab.SetTransparency(SubTab.Selected and 0.72 or 0.9)
		end)
		Creator.AddSignal(SubTab.Frame.MouseLeave, function()
			SubTab.SetTransparency(SubTab.Selected and 0.8 or 0.99)
		end)
		Creator.AddSignal(SubTab.Frame.MouseButton1Down, function()
			SubTab.SetTransparency(0.68)
		end)
		Creator.AddSignal(SubTab.Frame.MouseButton1Up, function()
			SubTab.SetTransparency(SubTab.Selected and 0.72 or 0.9)
		end)
		Creator.AddSignal(SubTab.Frame.MouseButton1Click, function()
			Tab.Expanded = true
			AnimateTabDropdown(Tab)
			TabModule:SelectItem(TabIndex, SubTab)
		end)

		function SubTab:Select()
			Tab.Expanded = true
			AnimateTabDropdown(Tab)
			TabModule:SelectItem(TabIndex, SubTab)
		end

		SubTab.Container = SubTab.ContainerFrame
		SubTab.ScrollFrame = SubTab.ContainerFrame
		AddSectionAPI(SubTab, Elements, Library, SubTab.ContainerFrame, SubTab.ContainerFrame)
		setmetatable(SubTab, Elements)

		Tab.SubTabs[SubTabIndex] = SubTab
		RefreshTabDropdown(Tab)

		if TabModule.SearchQuery ~= "" then
			TabModule:ApplySearch(TabModule.SearchQuery)
		end

		return SubTab
	end

	Tab.CreateSubTab = Tab.SubTab
	Tab.AddSubTab = Tab.SubTab

	setmetatable(Tab, Elements)
	RefreshTabDropdown(Tab)

	if TabModule.SearchQuery ~= "" then
		TabModule:ApplySearch(TabModule.SearchQuery)
	end

	return Tab
end

return TabModule
