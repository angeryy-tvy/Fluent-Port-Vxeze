local Root = script.Parent.Parent
local Flipper = require(Root.Packages.Flipper)
local Creator = require(Root.Modules.Creator)

local New = Creator.New
local Spring = Flipper.Spring.new
local Instant = Flipper.Instant.new
local Components = Root.Components

local TabModule = {
	Window = nil,
	Tabs = {},
	Containers = {},
	SelectedTab = 0,
	TabCount = 0,
	SearchQuery = "",
	SearchVisibility = {},
}

local SubTabSidebarWidth = 150

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
		ImageRectSize = Vector2.zero
	}
end

local function AddSectionAPI(Target, Elements, Library, SectionParent, ScrollFrame)
	function Target:Section(SectionTitle)
		local Section = {
			Type = "Section"
		}

		local SectionFrame = require(Components.Section)(SectionTitle, SectionParent, Library)
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

local function UpdateSubTabHostSize(SubTabHost)
	local SelectedSubTab = SubTabHost.SubTabs[SubTabHost.SelectedSubTab]
	local ContentHeight = SelectedSubTab and SelectedSubTab.PageLayout.AbsoluteContentSize.Y or 0
	local SidebarHeight = SubTabHost.SidebarLayout.AbsoluteContentSize.Y
	local TargetHeight = math.max(ContentHeight, SidebarHeight, 32)

	SubTabHost.ContentFrame.Size = UDim2.new(1, -(SubTabSidebarWidth + 14), 0, TargetHeight)
	SubTabHost.Root.Size = UDim2.new(1, 0, 0, TargetHeight)
end

local function EnsureSubTabHost(Tab, Library, Elements)
	if Tab.SubTabHost then
		return Tab.SubTabHost
	end

	local Host = {
		SubTabs = {},
		SelectedSubTab = 0,
		Count = 0,
	}

	Host.SidebarLayout = New("UIListLayout", {
		Padding = UDim.new(0, 4),
		SortOrder = Enum.SortOrder.LayoutOrder,
	})

	Host.SidebarFrame = New("Frame", {
		Size = UDim2.new(0, SubTabSidebarWidth, 1, 0),
		BackgroundTransparency = 0.08,
		ThemeTag = {
			BackgroundColor3 = "Tab",
			BackgroundTransparency = "ElementTransparency",
		},
	}, {
		New("UICorner", {
			CornerRadius = UDim.new(0, 8),
		}),
		New("UIPadding", {
			PaddingTop = UDim.new(0, 8),
			PaddingBottom = UDim.new(0, 8),
			PaddingLeft = UDim.new(0, 6),
			PaddingRight = UDim.new(0, 6),
		}),
		Host.SidebarLayout,
	})

	Host.ContentFrame = New("Frame", {
		Size = UDim2.new(1, -(SubTabSidebarWidth + 14), 0, 32),
		Position = UDim2.new(0, SubTabSidebarWidth + 14, 0, 0),
		BackgroundTransparency = 1,
	})

	Host.Root = New("Frame", {
		Size = UDim2.new(1, 0, 0, 32),
		BackgroundTransparency = 1,
		Parent = Tab.ContainerFrame,
	}, {
		Host.SidebarFrame,
		Host.ContentFrame,
	})

	function Host:Select(SubTabIndex)
		local Selected = Host.SubTabs[SubTabIndex]
		if not Selected then
			return
		end

		Host.SelectedSubTab = SubTabIndex

		for _, ExistingSubTab in next, Host.SubTabs do
			ExistingSubTab.Selected = false
			ExistingSubTab.Page.Visible = false
			ExistingSubTab.SetTransparency(1)
		end

		Selected.Selected = true
		Selected.Page.Visible = true
		Selected.SetTransparency(0.89)
		UpdateSubTabHostSize(Host)
	end

	Tab.SubTabHost = Host

	Creator.AddSignal(Host.SidebarLayout:GetPropertyChangedSignal("AbsoluteContentSize"), function()
		UpdateSubTabHostSize(Host)
	end)

	if TabModule.SearchQuery ~= "" then
		TabModule:ApplySearch(TabModule.SearchQuery)
	end

	return Host
end

function TabModule:Init(Window)
	TabModule.Window = Window
	return TabModule
end

function TabModule:GetCurrentTabPos()
	if not TabModule.Tabs[TabModule.SelectedTab] then
		return 0
	end

	local TabHolderPos = TabModule.Window.TabHolder.AbsolutePosition.Y
	local TabPos = TabModule.Tabs[TabModule.SelectedTab].Frame.AbsolutePosition.Y

	return TabPos - TabHolderPos
end

function TabModule:RestoreSearch()
	for Object, State in next, TabModule.SearchVisibility do
		if typeof(Object) == "Instance" and Object.Parent and Object:IsA("GuiObject") then
			Object.Visible = State
		end
	end

	table.clear(TabModule.SearchVisibility)
end

function TabModule:New(Title, Icon, Parent)
	local Library = require(Root)
	local Window = TabModule.Window
	local Elements = Library.Elements

	TabModule.TabCount = TabModule.TabCount + 1
	local TabIndex = TabModule.TabCount

	local Tab = {
		Selected = false,
		Name = Title,
		Type = "Tab",
	}

	Icon = NormalizeIcon(Icon, Library)

	Tab.Frame = New("TextButton", {
		Size = UDim2.new(1, 0, 0, 34),
		BackgroundTransparency = 1,
		Parent = Parent,
		ThemeTag = {
			BackgroundColor3 = "Tab",
		},
	}, {
		New("UICorner", {
			CornerRadius = UDim.new(0, 6),
		}),
		New("TextLabel", {
			AnchorPoint = Vector2.new(0, 0.5),
			Position = Icon ~= nil and UDim2.new(0, 30, 0.5, 0) or UDim2.new(0, 12, 0.5, 0),
			Text = Title,
			RichText = true,
			TextColor3 = Color3.fromRGB(255, 255, 255),
			TextTransparency = 0,
			FontFace = Font.new(
				"rbxasset://fonts/families/GothamSSm.json",
				Enum.FontWeight.Regular,
				Enum.FontStyle.Normal
			),
			TextSize = 12,
			TextXAlignment = "Left",
			TextYAlignment = "Center",
			Size = UDim2.new(1, -12, 1, 0),
			BackgroundTransparency = 1,
			ThemeTag = {
				TextColor3 = "Text",
			},
		}),
		New("ImageLabel", {
			AnchorPoint = Vector2.new(0, 0.5),
			Size = UDim2.fromOffset(16, 16),
			Position = UDim2.new(0, 8, 0.5, 0),
			BackgroundTransparency = 1,
			ImageRectOffset = Icon and Icon.ImageRectOffset or Vector2.zero,
			ImageRectSize = Icon and Icon.ImageRectSize or Vector2.zero,
			Image = Icon and Icon.Image or nil,
			ThemeTag = {
				ImageColor3 = "Text",
			},
		}),
	})

	local ContainerLayout = New("UIListLayout", {
		Padding = UDim.new(0, 5),
		SortOrder = Enum.SortOrder.LayoutOrder,
	})

	Tab.ContainerFrame = New("ScrollingFrame", {
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
		ContainerLayout,
		New("UIPadding", {
			PaddingRight = UDim.new(0, 10),
			PaddingLeft = UDim.new(0, 1),
			PaddingTop = UDim.new(0, 1),
			PaddingBottom = UDim.new(0, 1),
		}),
	})

	Creator.AddSignal(ContainerLayout:GetPropertyChangedSignal("AbsoluteContentSize"), function()
		if Tab.ContainerFrame.CanvasSize ~= UDim2.fromOffset(0, ContainerLayout.AbsoluteContentSize.Y + 2) then
			Tab.ContainerFrame.CanvasSize = UDim2.fromOffset(0, ContainerLayout.AbsoluteContentSize.Y + 2)
		end
	end)

	Tab.Motor, Tab.SetTransparency = Creator.SpringMotor(1, Tab.Frame, "BackgroundTransparency")

	Creator.AddSignal(Tab.Frame.MouseEnter, function()
		Tab.SetTransparency(Tab.Selected and 0.85 or 0.89)
	end)
	Creator.AddSignal(Tab.Frame.MouseLeave, function()
		Tab.SetTransparency(Tab.Selected and 0.89 or 1)
	end)
	Creator.AddSignal(Tab.Frame.MouseButton1Down, function()
		Tab.SetTransparency(0.92)
	end)
	Creator.AddSignal(Tab.Frame.MouseButton1Up, function()
		Tab.SetTransparency(Tab.Selected and 0.85 or 0.89)
	end)
	Creator.AddSignal(Tab.Frame.MouseButton1Click, function()
		TabModule:SelectTab(TabIndex)
	end)

	TabModule.Containers[TabIndex] = Tab.ContainerFrame
	TabModule.Tabs[TabIndex] = Tab

	Tab.Container = Tab.ContainerFrame
	Tab.ScrollFrame = Tab.Container
	AddSectionAPI(Tab, Elements, Library, Tab.ContainerFrame, Tab.ContainerFrame)

	function Tab:SubTab(SubTabConfig)
		assert(typeof(SubTabConfig) == "table", "SubTab - Missing config table")
		assert(SubTabConfig.Title, "SubTab - Missing Title")

		local Host = EnsureSubTabHost(Tab, Library, Elements)
		Host.Count = Host.Count + 1
		local SubTabIndex = Host.Count
		local SubTabIcon = NormalizeIcon(SubTabConfig.Icon, Library)

		local SubTab = {
			Name = SubTabConfig.Title,
			Type = "SubTab",
			Selected = false,
		}

		SubTab.PageLayout = New("UIListLayout", {
			Padding = UDim.new(0, 5),
			SortOrder = Enum.SortOrder.LayoutOrder,
		})

		SubTab.Page = New("Frame", {
			Size = UDim2.new(1, 0, 0, 0),
			AutomaticSize = Enum.AutomaticSize.Y,
			BackgroundTransparency = 1,
			Visible = false,
			Parent = Host.ContentFrame,
		}, {
			SubTab.PageLayout,
			New("UIPadding", {
				PaddingRight = UDim.new(0, 2),
				PaddingLeft = UDim.new(0, 2),
				PaddingBottom = UDim.new(0, 2),
			}),
		})

		SubTab.Button = New("TextButton", {
			Size = UDim2.new(1, 0, 0, 30),
			BackgroundTransparency = 1,
			Parent = Host.SidebarFrame,
			ThemeTag = {
				BackgroundColor3 = "Tab",
			},
			Text = "",
		}, {
			New("UICorner", {
				CornerRadius = UDim.new(0, 6),
			}),
			New("TextLabel", {
				AnchorPoint = Vector2.new(0, 0.5),
				Position = SubTabIcon and UDim2.new(0, 30, 0.5, 0) or UDim2.new(0, 12, 0.5, 0),
				Text = SubTabConfig.Title,
				RichText = true,
				TextColor3 = Color3.fromRGB(255, 255, 255),
				TextTransparency = 0,
				FontFace = Font.new(
					"rbxasset://fonts/families/GothamSSm.json",
					Enum.FontWeight.Regular,
					Enum.FontStyle.Normal
				),
				TextSize = 12,
				TextXAlignment = Enum.TextXAlignment.Left,
				TextYAlignment = Enum.TextYAlignment.Center,
				Size = UDim2.new(1, -12, 1, 0),
				BackgroundTransparency = 1,
				ThemeTag = {
					TextColor3 = "Text",
				},
			}),
			New("ImageLabel", {
				AnchorPoint = Vector2.new(0, 0.5),
				Size = UDim2.fromOffset(16, 16),
				Position = UDim2.new(0, 8, 0.5, 0),
				BackgroundTransparency = 1,
				ImageRectOffset = SubTabIcon and SubTabIcon.ImageRectOffset or Vector2.zero,
				ImageRectSize = SubTabIcon and SubTabIcon.ImageRectSize or Vector2.zero,
				Image = SubTabIcon and SubTabIcon.Image or nil,
				ThemeTag = {
					ImageColor3 = "Text",
				},
			}),
		})

		SubTab.Motor, SubTab.SetTransparency = Creator.SpringMotor(1, SubTab.Button, "BackgroundTransparency")

		Creator.AddSignal(SubTab.Button.MouseEnter, function()
			SubTab.SetTransparency(SubTab.Selected and 0.85 or 0.89)
		end)
		Creator.AddSignal(SubTab.Button.MouseLeave, function()
			SubTab.SetTransparency(SubTab.Selected and 0.89 or 1)
		end)
		Creator.AddSignal(SubTab.Button.MouseButton1Down, function()
			SubTab.SetTransparency(0.92)
		end)
		Creator.AddSignal(SubTab.Button.MouseButton1Up, function()
			SubTab.SetTransparency(SubTab.Selected and 0.85 or 0.89)
		end)
		Creator.AddSignal(SubTab.Button.MouseButton1Click, function()
			Host:Select(SubTabIndex)
		end)
		Creator.AddSignal(SubTab.PageLayout:GetPropertyChangedSignal("AbsoluteContentSize"), function()
			if Host.SelectedSubTab == SubTabIndex then
				UpdateSubTabHostSize(Host)
			end
		end)

		SubTab.Container = SubTab.Page
		SubTab.ScrollFrame = Tab.ContainerFrame

		AddSectionAPI(SubTab, Elements, Library, SubTab.Page, Tab.ContainerFrame)
		setmetatable(SubTab, Elements)

		Host.SubTabs[SubTabIndex] = SubTab

		if Host.SelectedSubTab == 0 then
			Host:Select(SubTabIndex)
		else
			UpdateSubTabHostSize(Host)
		end

		if TabModule.SearchQuery ~= "" then
			TabModule:ApplySearch(TabModule.SearchQuery)
		end

		return SubTab
	end

	Tab.CreateSubTab = Tab.SubTab
	Tab.AddSubTab = Tab.SubTab

	setmetatable(Tab, Elements)

	if TabModule.SearchQuery ~= "" then
		TabModule:ApplySearch(TabModule.SearchQuery)
	end

	return Tab
end

function TabModule:SelectTab(Tab)
	local Window = TabModule.Window
	local Selected = TabModule.Tabs[Tab]

	if not Selected or (Selected.Frame and Selected.Frame.Visible == false) then
		return
	end

	TabModule.SelectedTab = Tab

	for _, TabObject in next, TabModule.Tabs do
		TabObject.SetTransparency(1)
		TabObject.Selected = false
	end

	TabModule.Tabs[Tab].SetTransparency(0.89)
	TabModule.Tabs[Tab].Selected = true

	Window.TabDisplay.Text = TabModule.Tabs[Tab].Name
	Window.SelectorPosMotor:setGoal(Spring(TabModule:GetCurrentTabPos(), { frequency = 6 }))

	task.spawn(function()
		Window.ContainerHolder.Parent = Window.ContainerAnim
		
		Window.ContainerPosMotor:setGoal(Spring(15, { frequency = 10 }))
		Window.ContainerBackMotor:setGoal(Spring(1, { frequency = 10 }))

		task.wait(0.12)

		for _, Container in next, TabModule.Containers do
			Container.Visible = false
		end
	
		TabModule.Containers[Tab].Visible = true
		Window.ContainerPosMotor:setGoal(Spring(0, { frequency = 5 }))
		Window.ContainerBackMotor:setGoal(Spring(0, { frequency = 8 }))

		task.wait(0.12)

		Window.ContainerHolder.Parent = Window.ContainerCanvas
	end)
end

function TabModule:ApplySearch(Query)
	Query = NormalizeQuery(Query)
	TabModule.SearchQuery = Query

	if Query == "" then
		TabModule:RestoreSearch()

		if TabModule.SelectedTab > 0 and TabModule.Tabs[TabModule.SelectedTab] then
			TabModule.Window.TabDisplay.Text = TabModule.Tabs[TabModule.SelectedTab].Name
		elseif TabModule.Tabs[1] then
			TabModule:SelectTab(1)
		end

		return
	end

	local FirstVisibleTab = nil
	local CurrentTabVisible = false

	for TabIndex = 1, TabModule.TabCount do
		local Tab = TabModule.Tabs[TabIndex]
		local Container = TabModule.Containers[TabIndex]

		if Tab and Container then
			local HasElementMatch = false

			for _, Child in next, Container:GetChildren() do
				if Child:IsA("GuiObject") and not IsLayoutObject(Child) then
					local Match = ObjectMatchesQuery(Child, Query)
					CacheVisibility(TabModule.SearchVisibility, Child)
					Child.Visible = Match
					HasElementMatch = HasElementMatch or Match
				end
			end

			local TabMatch = TextMatches(Tab.Name, Query)
			local TabVisible = TabMatch or HasElementMatch
			CacheVisibility(TabModule.SearchVisibility, Tab.Frame)
			Tab.Frame.Visible = TabVisible

			if TabVisible and not FirstVisibleTab then
				FirstVisibleTab = TabIndex
			end

			if TabModule.SelectedTab == TabIndex then
				CurrentTabVisible = TabVisible
			end
		end
	end

	if not FirstVisibleTab then
		for _, Container in next, TabModule.Containers do
			Container.Visible = false
		end

		TabModule.Window.TabDisplay.Text = "No results"
		return
	end

	if TabModule.SelectedTab == 0 or not CurrentTabVisible then
		TabModule:SelectTab(FirstVisibleTab)
	end
end

return TabModule
