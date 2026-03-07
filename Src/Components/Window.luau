-- a wise man once said: "i will rewrite this someday"

local Root = script.Parent.Parent
local Flipper = require(Root.Packages.Flipper)
local Creator = require(Root.Modules.Creator)
local Acrylic = require(Root.Modules.Acrylic)
local Layout = require(Root.Modules.Layout)
local Signal = require(Root.Packages.Signal)
local Assets = require(script.Parent.Assets)
local Components = script.Parent

local Library = require(Root)

local UserInputService = Library.Utilities:Clone(game:GetService("UserInputService"))
local Mouse = Library.Utilities:Clone(game:GetService("Players")).LocalPlayer:GetMouse()
local Camera = Library.Utilities:Clone(game:GetService("Workspace")).CurrentCamera

local Spring = Flipper.Spring.new
local Instant = Flipper.Instant.new
local New = Creator.New

return function(Config)
	assert(typeof(Config.Mobile) == "table", "Config key 'Mobile' must be a table!")
	assert(typeof(Config.Mobile.GetIcon) == "function", "Mobile Config key 'GetIcon' must be a function!")
	assert(typeof(Config.Mobile.Size) == "UDim2", "Mobile Config key 'Size' must be a UDim2!")

	local PlayersService = game:GetService("Players")
	local LocalPlayer = PlayersService.LocalPlayer
	
	local Window = {
		Minimized = false,
		OnMinimized = Signal.new(),
		PostMinimized = Signal.new(),
		Maximized = false,
		OnMaximized = Signal.new(),
		PostMaximized = Signal.new(),
		Size = Config.Size,
		MinSize = Config.MinSize,
		CurrentPos = 0,
		TabWidth = 0,
		Position = UDim2.fromOffset(
			Camera.ViewportSize.X / 2 - Config.Size.X.Offset / 2,
			Camera.ViewportSize.Y / 2 - Config.Size.Y.Offset / 2
		),
	}

	local Dragging, DragInput, MousePos, StartPos = false
	local Resizing, ResizePos = false
	local MinimizeNotif = false

	Window.AcrylicPaint = Acrylic.AcrylicPaint()
	Window.TabWidth = Config.TabWidth
	local SearchBarHeight = 36
	local SearchBarPadding = 10
	local UserCardHeight = 58
	local UserCardPadding = 12
	local DiscordInvite = "discord.gg/vxezehub"
	local DiscordOwner = "zthinhtran_dex"
	local DiscordCoOwner = "Angeryy05"
	local SelectorOffsetY = SearchBarHeight + SearchBarPadding + 19

	local Selector = New("Frame", {
		Size = UDim2.fromOffset(3, 0),
		BackgroundColor3 = Color3.fromRGB(76, 194, 255),
		Position = UDim2.fromOffset(6, 19),
		AnchorPoint = Vector2.new(0, 0.5),
		ThemeTag = {
			BackgroundColor3 = "Accent",
		},
	}, {
		New("UICorner", {
			CornerRadius = UDim.new(0, 2),
		}),
	})

	local ResizeStartFrame = New("Frame", {
		Size = UDim2.fromOffset(20, 20),
		BackgroundTransparency = 1,
		Position = UDim2.new(1, -20, 1, -20),
	})

	Window.TabHolder = New("ScrollingFrame", {
		Size = UDim2.new(1, 0, 1, -(SearchBarHeight + SearchBarPadding + UserCardHeight + UserCardPadding)),
		Position = UDim2.fromOffset(0, SearchBarHeight + SearchBarPadding),
		BackgroundTransparency = 1,
		ScrollBarImageTransparency = 0.9,
		ScrollBarThickness = 2,
		BorderSizePixel = 0,
		CanvasSize = UDim2.fromScale(0, 0),
		ScrollingDirection = Enum.ScrollingDirection.Y,
	}, {
		New("UIListLayout", {
			Padding = UDim.new(0, 4),
			SortOrder = Enum.SortOrder.LayoutOrder,
		}),
	})

	local TabFrame = New("Frame", {
		Size = UDim2.new(1, -(Layout.Window.SidebarInset * 2), 1, -(Layout.Window.SidebarInset * 2)),
		Position = UDim2.fromOffset(Layout.Window.SidebarInset, Layout.Window.SidebarInset),
		BackgroundTransparency = 1,
		ClipsDescendants = true,
	}, {
		Window.TabHolder,
		Selector,
	})

	local SidebarShell = New("Frame", {
		Size = UDim2.new(0, Window.TabWidth + 24, 1, -66),
		Position = UDim2.new(0, 12, 0, 54),
		BackgroundTransparency = 0.16,
		ClipsDescendants = true,
		ThemeTag = {
			BackgroundColor3 = "DialogHolder",
		},
	}, {
		New("UICorner", {
			CornerRadius = UDim.new(0, 12),
		}),
		New("UIStroke", {
			Transparency = 0.28,
			ThemeTag = {
				Color = "InElementBorder",
			},
		}),
		TabFrame,
	})

	local SearchBox = require(Components.Textbox)(TabFrame, true)
	SearchBox.Frame.Size = UDim2.new(1, 0, 0, SearchBarHeight)
	SearchBox.Frame.Position = UDim2.fromOffset(0, 0)
	SearchBox.Input.PlaceholderText = "Find a setting"
	SearchBox.Input.Text = ""
	SearchBox.Container.Position = UDim2.fromOffset(22, 0)
	SearchBox.Container.Size = UDim2.new(1, -28, 1, 0)

	local SearchIcon = New("ImageLabel", {
		AnchorPoint = Vector2.new(0, 0.5),
		Position = UDim2.new(0, 7, 0.5, 0),
		Size = UDim2.fromOffset(14, 14),
		BackgroundTransparency = 1,
		ThemeTag = {
			ImageColor3 = "SubText",
		},
	})

	Library.Utilities.Icons:SetIcon(SearchIcon, "search")
	SearchIcon.Parent = SearchBox.Frame
	Window.SearchBox = SearchBox

	Window.PlayerCard = New("Frame", {
		AnchorPoint = Vector2.new(0, 1),
		Position = UDim2.new(0, 0, 1, 0),
		Size = UDim2.new(1, 0, 0, UserCardHeight),
		BackgroundTransparency = 0.22,
		Parent = TabFrame,
		ThemeTag = {
			BackgroundColor3 = "Dialog",
		},
	}, {
		New("UICorner", {
			CornerRadius = UDim.new(0, 12),
		}),
		New("UIStroke", {
			Transparency = 0.35,
			ThemeTag = {
				Color = "InElementBorder",
			},
		}),
	})

	Window.PlayerAvatar = New("ImageLabel", {
		AnchorPoint = Vector2.new(0, 0.5),
		Position = UDim2.new(0, 12, 0.5, 0),
		Size = UDim2.fromOffset(36, 36),
		BackgroundTransparency = 0.08,
		Parent = Window.PlayerCard,
		Image = "",
		ThemeTag = {
			BackgroundColor3 = "Tab",
		},
	}, {
		New("UICorner", {
			CornerRadius = UDim.new(1, 0),
		}),
	})

	Window.PlayerCardButton = New("TextButton", {
		Size = UDim2.new(1, -40, 1, 0),
		BackgroundTransparency = 1,
		Text = "",
		Parent = Window.PlayerCard,
	})

	Window.PlayerVisibilityToggle = New("TextButton", {
		AnchorPoint = Vector2.new(1, 0.5),
		Position = UDim2.new(1, -10, 0.5, 0),
		Size = UDim2.fromOffset(24, 24),
		BackgroundTransparency = 1,
		Text = "",
		Parent = Window.PlayerCard,
	}, {
		New("ImageLabel", {
			Name = "Icon",
			AnchorPoint = Vector2.new(0.5, 0.5),
			Position = UDim2.fromScale(0.5, 0.5),
			Size = UDim2.fromOffset(16, 16),
			BackgroundTransparency = 1,
			ThemeTag = {
				ImageColor3 = "SubText",
			},
		}),
	})

	Window.PlayerDisplayName = New("TextLabel", {
		AnchorPoint = Vector2.new(0, 0),
		Position = UDim2.fromOffset(58, 11),
		Size = UDim2.new(1, -98, 0, 18),
		BackgroundTransparency = 1,
		FontFace = Font.new("rbxasset://fonts/families/GothamSSm.json", Enum.FontWeight.SemiBold, Enum.FontStyle.Normal),
		Text = LocalPlayer and LocalPlayer.DisplayName or "Player",
		TextSize = 13,
		TextXAlignment = Enum.TextXAlignment.Left,
		TextYAlignment = Enum.TextYAlignment.Center,
		ThemeTag = {
			TextColor3 = "Text",
		},
	}, {
		New("UITextSizeConstraint", {
			MaxTextSize = 13,
		}),
	})
	Window.PlayerDisplayName.Parent = Window.PlayerCard

	Window.PlayerMeta = New("TextLabel", {
		AnchorPoint = Vector2.new(0, 0),
		Position = UDim2.fromOffset(58, 29),
		Size = UDim2.new(1, -98, 0, 16),
		BackgroundTransparency = 1,
		FontFace = Font.new("rbxasset://fonts/families/GothamSSm.json", Enum.FontWeight.Medium, Enum.FontStyle.Normal),
		Text = LocalPlayer and (`@{LocalPlayer.Name}  •  ID {LocalPlayer.UserId}`) or "Unavailable",
		TextSize = 11,
		TextXAlignment = Enum.TextXAlignment.Left,
		TextYAlignment = Enum.TextYAlignment.Center,
		ThemeTag = {
			TextColor3 = "SubText",
		},
	}, {
		New("UITextSizeConstraint", {
			MaxTextSize = 11,
		}),
	})
	Window.PlayerMeta.Parent = Window.PlayerCard

	local PlayerCardVisible = true
	local DefaultAvatarTransparency = Window.PlayerAvatar.BackgroundTransparency
	local PlayerDisplayNameText = LocalPlayer and LocalPlayer.DisplayName or "Player"
	local PlayerMetaText = LocalPlayer and (`@{LocalPlayer.Name}  •  ID {LocalPlayer.UserId}`) or "Unavailable"

	local function CopyToClipboard(Value)
		local CopyFunction = setclipboard or toclipboard or set_clipboard or copystring
		if typeof(CopyFunction) == "function" then
			return pcall(CopyFunction, Value)
		end

		return false
	end

	local function UpdatePlayerCardVisibility()
		Window.PlayerDisplayName.Text = PlayerCardVisible and PlayerDisplayNameText or "Profile hidden"
		Window.PlayerMeta.Text = PlayerCardVisible and PlayerMetaText or "Tap eye icon to reveal"
		Window.PlayerAvatar.ImageTransparency = PlayerCardVisible and 0 or 1
		Window.PlayerAvatar.BackgroundTransparency = PlayerCardVisible and DefaultAvatarTransparency or 0.55
		Library.Utilities.Icons:SetIcon(Window.PlayerVisibilityToggle.Icon, PlayerCardVisible and "eye" or "eye-off")
	end

	UpdatePlayerCardVisibility()

	if LocalPlayer then
		task.spawn(function()
			local Success, Content, IsReady = pcall(function()
				return PlayersService:GetUserThumbnailAsync(
					LocalPlayer.UserId,
					Enum.ThumbnailType.HeadShot,
					Enum.ThumbnailSize.Size100x100
				)
			end)

			if Success and Content then
				Window.PlayerAvatar.Image = Content

				if not IsReady then
					task.wait(0.25)

					local RetrySuccess, RetryContent = pcall(function()
						return PlayersService:GetUserThumbnailAsync(
							LocalPlayer.UserId,
							Enum.ThumbnailType.HeadShot,
							Enum.ThumbnailSize.Size100x100
						)
					end)

					if RetrySuccess and RetryContent then
						Window.PlayerAvatar.Image = RetryContent
					end
				end
			end
		end)
	end

	Window.TabDisplay = New("TextLabel", {
		RichText = true,
		Text = "Tab",
		TextTransparency = 0,
		FontFace = Font.new("rbxasset://fonts/families/GothamSSm.json", Enum.FontWeight.Bold, Enum.FontStyle.Normal),
		TextSize = 31,
		TextXAlignment = Enum.TextXAlignment.Left,
		TextYAlignment = Enum.TextYAlignment.Center,
		Size = UDim2.new(1, -44, 0, 34),
		Position = UDim2.fromOffset(22, 24),
		BackgroundTransparency = 1,
		ThemeTag = {
			TextColor3 = "Text",
		},
	})

	Window.TabMeta = New("TextLabel", {
		RichText = true,
		Text = "WORKSPACE",
		TextTransparency = 0.1,
		FontFace = Font.new("rbxasset://fonts/families/GothamSSm.json", Enum.FontWeight.Medium, Enum.FontStyle.Normal),
		TextSize = 11,
		TextXAlignment = Enum.TextXAlignment.Left,
		TextYAlignment = Enum.TextYAlignment.Center,
		Size = UDim2.new(1, -44, 0, 14),
		Position = UDim2.fromOffset(22, 12),
		BackgroundTransparency = 1,
		ThemeTag = {
			TextColor3 = "SubText",
		},
	}, {
		New("UITextSizeConstraint", {
			MaxTextSize = 11,
		}),
	})

	Window.ContainerHolder = New("Frame", {
		Size = UDim2.fromScale(1, 1),
		BackgroundTransparency = 1,
	})

	Window.ContainerAnim = New("CanvasGroup", {
		Size = UDim2.fromScale(1, 1),
		BackgroundTransparency = 1,
	})

	Window.ContainerCanvas = New("Frame", {
		Size = UDim2.new(
			1,
			-(Layout.Window.ContentInsetX * 2),
			1,
			-(Layout.Window.ContentInsetTop + Layout.Window.ContentInsetBottom)
		),
		Position = UDim2.fromOffset(Layout.Window.ContentInsetX, Layout.Window.ContentInsetTop),
		BackgroundTransparency = 1,
	}, {
		Window.ContainerAnim,
		Window.ContainerHolder
	})

	local ContentShell = New("Frame", {
		Size = UDim2.new(1, -Window.TabWidth - 48, 1, -66),
		Position = UDim2.fromOffset(Window.TabWidth + 36, 54),
		BackgroundTransparency = 0.08,
		ClipsDescendants = true,
		ThemeTag = {
			BackgroundColor3 = "Dialog",
		},
	}, {
		New("UICorner", {
			CornerRadius = UDim.new(0, 14),
		}),
		New("UIStroke", {
			Transparency = 0.26,
			ThemeTag = {
				Color = "DialogBorder",
			},
		}),
		Window.TabMeta,
		Window.TabDisplay,
		Window.ContainerCanvas,
	})

	Window.Root = New("Frame", {
		BackgroundTransparency = 1,
		Size = Window.Size,
		Position = Window.Position,
		Parent = Config.Parent,
	}, {
		Window.AcrylicPaint.Frame,
		SidebarShell,
		ContentShell,
		ResizeStartFrame,
	})

	-- CustomButton Toggle - appears as a draggable circular button to toggle UI
	local TweenService = game:GetService("TweenService")
	local ContentProvider = game:GetService("ContentProvider")
	local playerGui = LocalPlayer:WaitForChild("PlayerGui")

	local existingGui = playerGui:FindFirstChild("FluentToggleGui")
	if existingGui then existingGui:Destroy() end

	Window.ToggleScreenGui = Instance.new("ScreenGui")
	Window.ToggleScreenGui.Name = "FluentToggleGui"
	Window.ToggleScreenGui.ResetOnSpawn = false
	Window.ToggleScreenGui.Parent = playerGui

	local BorderFrame = Instance.new("Frame")
	BorderFrame.Name = "BorderFrame"
	BorderFrame.Parent = Window.ToggleScreenGui
	BorderFrame.Size = UDim2.new(0, 52, 0, 52)
	BorderFrame.Position = UDim2.new(0, 50, 0, 50)
	BorderFrame.BackgroundColor3 = Color3.new(1, 1, 1)
	BorderFrame.BackgroundTransparency = 0
	BorderFrame.BorderSizePixel = 2
	BorderFrame.BorderColor3 = Color3.fromRGB(0, 255, 255)

	local BorderUICorner = Instance.new("UICorner")
	BorderUICorner.CornerRadius = UDim.new(1, 0)
	BorderUICorner.Parent = BorderFrame

	local ToggleButton = Instance.new("ImageButton")
	ToggleButton.Name = "CustomButton"
	ToggleButton.Parent = BorderFrame
	ToggleButton.Size = UDim2.new(1, -4, 1, -4)
	ToggleButton.Position = UDim2.new(0.5, 0, 0.5, 0)
	ToggleButton.AnchorPoint = Vector2.new(0.5, 0.5)
	ToggleButton.BackgroundTransparency = 1
	ToggleButton.Image = "rbxassetid://87167480222237"

	local ToggleUICorner = Instance.new("UICorner")
	ToggleUICorner.CornerRadius = UDim.new(1, 0)
	ToggleUICorner.Parent = ToggleButton

	local ToggleGlow = Instance.new("UIStroke")
	ToggleGlow.Thickness = 2
	ToggleGlow.Color = Color3.fromRGB(0, 255, 255)
	ToggleGlow.Parent = BorderFrame
	ToggleGlow.Enabled = false

	local toggleImageLoaded = false
	ContentProvider:PreloadAsync({ ToggleButton.Image }, function()
		toggleImageLoaded = true
	end)

	local toggleDragging = false
	local toggleDragStart = nil
	local toggleStartPos = nil
	local toggleOriginalSize = ToggleButton.Size
	local toggleGlowEnabled = false

	ToggleButton.InputBegan:Connect(function(input)
		if input.UserInputType == Enum.UserInputType.MouseButton1 or input.UserInputType == Enum.UserInputType.Touch then
			toggleDragging = true
			toggleDragStart = input.Position
			toggleStartPos = BorderFrame.Position
			TweenService:Create(ToggleButton, TweenInfo.new(0.1, Enum.EasingStyle.Quad, Enum.EasingDirection.Out), {
				Size = UDim2.new(toggleOriginalSize.X.Scale, toggleOriginalSize.X.Offset * 0.9, toggleOriginalSize.Y.Scale, toggleOriginalSize.Y.Offset * 0.9)
			}):Play()
			input.Changed:Connect(function()
				if input.UserInputState == Enum.UserInputState.End then
					toggleDragging = false
					TweenService:Create(ToggleButton, TweenInfo.new(0.1, Enum.EasingStyle.Quad, Enum.EasingDirection.Out), { Size = toggleOriginalSize }):Play()
				end
			end)
		end
	end)

	ToggleButton.InputChanged:Connect(function(input)
		if input.UserInputType == Enum.UserInputType.MouseMovement or input.UserInputType == Enum.UserInputType.Touch then
			if toggleDragging then
				local delta = input.Position - toggleDragStart
				local targetPos = UDim2.new(toggleStartPos.X.Scale, toggleStartPos.X.Offset + delta.X, toggleStartPos.Y.Scale, toggleStartPos.Y.Offset + delta.Y)
				TweenService:Create(BorderFrame, TweenInfo.new(0.08, Enum.EasingStyle.Sine, Enum.EasingDirection.Out), {
					Position = targetPos
				}):Play()
			end
		end
	end)

	ToggleButton.MouseEnter:Connect(function()
		TweenService:Create(ToggleButton, TweenInfo.new(0.2, Enum.EasingStyle.Quad, Enum.EasingDirection.Out), {
			Size = UDim2.new(toggleOriginalSize.X.Scale, toggleOriginalSize.X.Offset * 1.1, toggleOriginalSize.Y.Scale, toggleOriginalSize.Y.Offset * 1.1)
		}):Play()
	end)

	ToggleButton.MouseLeave:Connect(function()
		TweenService:Create(ToggleButton, TweenInfo.new(0.2, Enum.EasingStyle.Quad, Enum.EasingDirection.Out), { Size = toggleOriginalSize }):Play()
	end)

	Window.ToggleButton = ToggleButton
	Window.ToggleGlow = ToggleGlow
	Window.ToggleBorderFrame = BorderFrame

	Window.TitleBar = require(script.Parent.TitleBar)({
		Title = Config.Title,
		SubTitle = Config.SubTitle,
		Parent = Window.Root,
		Window = Window,
	})

	if Library.UseAcrylic then
		Window.AcrylicPaint.AddParent(Window.Root)
	end

	local SizeMotor = Flipper.GroupMotor.new({
		X = Window.Size.X.Offset,
		Y = Window.Size.Y.Offset,
	})

	local PosMotor = Flipper.GroupMotor.new({
		X = Window.Position.X.Offset,
		Y = Window.Position.Y.Offset,
	})

	Window.SelectorPosMotor = Flipper.SingleMotor.new(0)
	Window.SelectorSizeMotor = Flipper.SingleMotor.new(0)
	Window.ContainerBackMotor = Flipper.SingleMotor.new(0)
	Window.ContainerPosMotor = Flipper.SingleMotor.new(94)

	SizeMotor:onStep(function(values)
		Window.Root.Size = UDim2.new(0, values.X, 0, values.Y)
	end)

	PosMotor:onStep(function(values)
		Window.Root.Position = UDim2.new(0, values.X, 0, values.Y)
	end)

	local LastValue = 0
	local LastTime = 0
	Window.SelectorPosMotor:onStep(function(Value)
		Selector.Position = UDim2.new(0, 6, 0, Value + SelectorOffsetY)
		local Now = tick()
		local DeltaTime = Now - LastTime

		if LastValue ~= nil then
			Window.SelectorSizeMotor:setGoal(Spring((math.abs(Value - LastValue) / (DeltaTime * 60)) + 18))
			LastValue = Value
		end
		LastTime = Now
	end)

	Window.SelectorSizeMotor:onStep(function(Value)
		Selector.Size = UDim2.new(0, 3, 0, Value)
	end)

	Window.ContainerBackMotor:onStep(function(Value)
		Window.ContainerAnim.GroupTransparency = Value
	end)

	Window.ContainerPosMotor:onStep(function(Value)
		Window.ContainerAnim.Position = UDim2.fromOffset(0, Value)
	end)


	local OldSizeX
	local OldSizeY
	Window.Maximize = function(Value, NoPos, Instant)
		Window.OnMaximized:Fire(tick())

		Window.Maximized = Value
		Window.TitleBar.MaxButton.Frame.Icon.Image = Value and Assets.Restore or Assets.Max

		if Value then
			OldSizeX = Window.Size.X.Offset
			OldSizeY = Window.Size.Y.Offset
		end
		local SizeX = Value and Camera.ViewportSize.X or OldSizeX
		local SizeY = Value and Camera.ViewportSize.Y or OldSizeY
		SizeMotor:setGoal({
			X = Flipper[Instant and "Instant" or "Spring"].new(SizeX, { frequency = 6 }),
			Y = Flipper[Instant and "Instant" or "Spring"].new(SizeY, { frequency = 6 }),
		})
		Window.Size = UDim2.fromOffset(SizeX, SizeY)

		if not NoPos then
			PosMotor:setGoal({
				X = Spring(Value and 0 or Window.Position.X.Offset, { frequency = 6 }),
				Y = Spring(Value and 0 or Window.Position.Y.Offset, { frequency = 6 }),
			})
		end

		Window.PostMaximized:Fire(tick())
	end

	Creator.AddSignal(Window.TitleBar.Frame.InputBegan, function(Input)
		if
			Input.UserInputType == Enum.UserInputType.MouseButton1
			or Input.UserInputType == Enum.UserInputType.Touch
		then
			Dragging = true
			MousePos = Input.Position
			StartPos = Window.Root.Position

			if Window.Maximized then
				StartPos = UDim2.fromOffset(
					Mouse.X - (Mouse.X * ((OldSizeX - 100) / Window.Root.AbsoluteSize.X)),
					Mouse.Y - (Mouse.Y * (OldSizeY / Window.Root.AbsoluteSize.Y))
				)
			end

			Input.Changed:Connect(function()
				if Input.UserInputState == Enum.UserInputState.End then
					Dragging = false
				end
			end)
		end
	end)

	Creator.AddSignal(Window.TitleBar.Frame.InputChanged, function(Input)
		if
			Input.UserInputType == Enum.UserInputType.MouseMovement
			or Input.UserInputType == Enum.UserInputType.Touch
		then
			DragInput = Input
		end
	end)

	Creator.AddSignal(ResizeStartFrame.InputBegan, function(Input)
		if
			Input.UserInputType == Enum.UserInputType.MouseButton1
			or Input.UserInputType == Enum.UserInputType.Touch
		then
			Resizing = true
			ResizePos = Input.Position
		end
	end)

	Creator.AddSignal(UserInputService.InputChanged, function(Input)
		if Input == DragInput and Dragging then
			local Delta = Input.Position - MousePos
			Window.Position = UDim2.fromOffset(StartPos.X.Offset + Delta.X, StartPos.Y.Offset + Delta.Y)
			PosMotor:setGoal({
				X = Instant(Window.Position.X.Offset),
				Y = Instant(Window.Position.Y.Offset),
			})

			if Window.Maximized then
				Window.Maximize(false, true, true)
			end
		end

		if
			(Input.UserInputType == Enum.UserInputType.MouseMovement or Input.UserInputType == Enum.UserInputType.Touch)
			and Resizing
		then
			local Delta = Input.Position - ResizePos
			local StartSize = Window.Size

			local TargetSize = Vector3.new(StartSize.X.Offset, StartSize.Y.Offset, 0) + Vector3.new(1, 1, 0) * Delta
			local TargetSizeClamped =
				Vector2.new(math.clamp(TargetSize.X, Window.MinSize.X, 2048), math.clamp(TargetSize.Y, Window.MinSize.Y, 2048))

			SizeMotor:setGoal({
				X = Flipper.Instant.new(TargetSizeClamped.X),
				Y = Flipper.Instant.new(TargetSizeClamped.Y),
			})
		end
	end)

	Creator.AddSignal(UserInputService.InputEnded, function(Input)
		if Resizing == true or Input.UserInputType == Enum.UserInputType.Touch then
			Resizing = false
			Window.Size = UDim2.fromOffset(SizeMotor:getValue().X, SizeMotor:getValue().Y)
		end
	end)

	Creator.AddSignal(Window.TabHolder.UIListLayout:GetPropertyChangedSignal("AbsoluteContentSize"), function()
		if Window.TabHolder.CanvasSize ~= UDim2.fromOffset(0, Window.TabHolder.UIListLayout.AbsoluteContentSize.Y) then
			Window.TabHolder.CanvasSize = UDim2.fromOffset(0, Window.TabHolder.UIListLayout.AbsoluteContentSize.Y)
		end
	end)

	function Window:Minimize()
		Window.Minimized = not Window.Minimized
		Window.Root.Visible = not Window.Minimized

		-- Toggle CustomButton glow to indicate state
		toggleGlowEnabled = Window.Minimized
		Window.ToggleGlow.Enabled = toggleGlowEnabled

		Window.OnMinimized:Fire(tick(), Window.Root.Visible)

		if not MinimizeNotif then
			local Key = Library.MinimizeKeybind and Library.MinimizeKeybind.Value or typeof(Library.MinimizeKey) == "string" and Library.MinimizeKey or Library.MinimizeKey.Name

			MinimizeNotif = true
			
			Library:Notify({
				Title = "Interface",
				Content = `Press {Library.Utilities:Prettify(Key)} to toggle the interface.`,
				Duration = 6
			})
		end
		Window.PostMinimized:Fire(tick(), Window.Root.Visible)
	end

	Creator.AddSignal(UserInputService.InputBegan, function(Input)
		if
			type(Library.MinimizeKeybind) == "table"
			and Library.MinimizeKeybind.Type == "Keybind"
			and not UserInputService:GetFocusedTextBox()
		then
			if Input.KeyCode.Name == Library.MinimizeKeybind.Value or Input.KeyCode.Name == Library.MinimizeKeybind.Value.Name then
				Window:Minimize()
			end
		elseif (Input.KeyCode == Library.MinimizeKey or Input.KeyCode.Name == Library.MinimizeKey) and not UserInputService:GetFocusedTextBox() then
			Window:Minimize()
		end
	end)

	-- CustomButton click handler to toggle UI
	do
		local LastClick = 0
		ToggleButton.MouseButton1Click:Connect(function()
			if tick() - LastClick > 0.3 then
				LastClick = tick()
				if not toggleImageLoaded then return end
				Window:Minimize()
			end
		end)
	end

	function Window:Destroy()
		if Library.UseAcrylic then
			Window.AcrylicPaint.Model:Destroy()
		end
		if Window.ToggleScreenGui then
			Window.ToggleScreenGui:Destroy()
		end
		Window.Root:Destroy()
	end

	local DialogModule = require(Components.Dialog):Init(Window)
	function Window:Dialog(Config)
		local Dialog = DialogModule:Create()
		Dialog.Title.Text = Config.Title

		local Content = New("TextLabel", {
			FontFace = Font.new("rbxasset://fonts/families/GothamSSm.json"),
			Text = Config.Content,
			TextColor3 = Color3.fromRGB(240, 240, 240),
			TextSize = 14,
			TextXAlignment = Enum.TextXAlignment.Left,
			TextYAlignment = Enum.TextYAlignment.Top,
			Size = UDim2.new(1, -40, 1, 0),
			Position = UDim2.fromOffset(20, 60),
			BackgroundTransparency = 1,
			Parent = Dialog.Root,
			ClipsDescendants = false,
			ThemeTag = {
				TextColor3 = "Text",
			},
		})

		New("UISizeConstraint", {
			MinSize = Vector2.new(300, 165),
			MaxSize = Vector2.new(620, math.huge),
			Parent = Dialog.Root,
		})

		Dialog.Root.Size = UDim2.fromOffset(Content.TextBounds.X + 40, 165)
		if Content.TextBounds.X + 40 > Window.Size.X.Offset - 120 then
			Dialog.Root.Size = UDim2.fromOffset(Window.Size.X.Offset - 120, 165)
			Content.TextWrapped = true
			Dialog.Root.Size = UDim2.fromOffset(Window.Size.X.Offset - 120, Content.TextBounds.Y + 150)
		end

		for _, Button in next, Config.Buttons do
			Dialog:Button(Button.Title, Button.Callback)
		end

		Dialog:Open()

		if Config.Yield then
			Dialog.Closed:Wait()
		end

		return Dialog
	end

	Creator.AddSignal(Window.PlayerVisibilityToggle.MouseButton1Click, function()
		PlayerCardVisible = not PlayerCardVisible
		UpdatePlayerCardVisibility()
	end)

	Creator.AddSignal(Window.PlayerCardButton.MouseButton1Click, function()
		local CopyResult = false
		Window:Dialog({
			Title = "Profile Details",
			Content = table.concat({
				`Display Name: {PlayerDisplayNameText}`,
				`Username: @{LocalPlayer and LocalPlayer.Name or "unknown"}`,
				`User ID: {LocalPlayer and LocalPlayer.UserId or 0}`,
				"",
				`Discord: {DiscordInvite}`,
				`Owner: {DiscordOwner}`,
				`Co.Owner: {DiscordCoOwner}`,
			}, "\n"),
			Buttons = {
				{
					Title = "Copy Discord Link",
					Callback = function()
						CopyResult = CopyToClipboard(DiscordInvite)
						Library:Notify({
							Title = "Discord",
							Content = CopyResult and "Discord link copied." or "Clipboard is not supported by this executor.",
							Duration = 4,
						})
					end,
				},
				{
					Title = "Close",
					Callback = function() end,
				},
			},
		})
	end)

	local TabModule = require(Components.Tab):Init(Window)

	Creator.AddSignal(Window.SearchBox.Input:GetPropertyChangedSignal("Text"), function()
		TabModule:ApplySearch(Window.SearchBox.Input.Text)
	end)

	function Window:Tab(TabConfig)
		return TabModule:New(TabConfig.Title, TabConfig.Icon, Window.TabHolder)
	end

	function Window:AddTab(TabConfig)
		return Window:Tab(TabConfig)
	end

	function Window:CreateTab(TabConfig)
		return Window:Tab(TabConfig)
	end

	function Window:SelectTab(Tab)
		TabModule:SelectTab(Tab)
	end

	Creator.AddSignal(Window.TabHolder:GetPropertyChangedSignal("CanvasPosition"), function()
		LastValue = TabModule:GetCurrentTabPos() + 19
		LastTime = 0
		Window.SelectorPosMotor:setGoal(Instant(TabModule:GetCurrentTabPos()))
	end)

	return Window
end
