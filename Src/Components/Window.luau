-- a wise man once said: "i will rewrite this someday"

local Root = script.Parent.Parent
local Flipper = require(Root.Packages.Flipper)
local Creator = require(Root.Modules.Creator)
local Acrylic = require(Root.Modules.Acrylic)
local Layout = require(Root.Modules.Layout)
local Signal = require(Root.Packages.Signal)
local Assets = require(script.Parent.Assets)
local Components = script.Parent
local DialogButtonComponent = require(Components.Button)

local Library = require(Root)

local HttpService = game:GetService("HttpService")
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
	local TweenService = game:GetService("TweenService")
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
	local DiscordInviteUrl = "https://discord.gg/vxezehub"
	local ReportWebhookUrl = "https://vxezestudio.online/api/webhooks/proxy_b7e05c77474568813bdd9d8efdcbb930"
	local SuggestWebhookUrl = "https://vxezestudio.online/api/webhooks/proxy_81bc939df362fd6d7f9e38e3c6ded5e6"
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
		New("UIScale", {
			Scale = 1,
		}),
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

	Window.PlayerCardAccent = New("Frame", {
		Size = UDim2.new(1, 0, 0, 2),
		BackgroundTransparency = 0.35,
		Parent = Window.PlayerCard,
		ThemeTag = {
			BackgroundColor3 = "Accent",
		},
	}, {
		New("UICorner", {
			CornerRadius = UDim.new(1, 0),
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

	Window.PlayerDismissButton = New("TextButton", {
		AnchorPoint = Vector2.new(1, 0),
		Position = UDim2.fromOffset(52, 7),
		Size = UDim2.fromOffset(16, 16),
		AutoButtonColor = false,
		BackgroundColor3 = Color3.fromRGB(24, 29, 36),
		BackgroundTransparency = 0.12,
		Text = "",
		ZIndex = 3,
		Parent = Window.PlayerCard,
	}, {
		New("UICorner", {
			CornerRadius = UDim.new(1, 0),
		}),
		New("UIStroke", {
			Transparency = 0.35,
			ThemeTag = {
				Color = "InElementBorder",
			},
		}),
		New("ImageLabel", {
			Name = "Icon",
			AnchorPoint = Vector2.new(0.5, 0.5),
			Position = UDim2.fromScale(0.5, 0.5),
			Size = UDim2.fromOffset(10, 10),
			BackgroundTransparency = 1,
			ZIndex = 4,
			ThemeTag = {
				ImageColor3 = "SubText",
			},
		}),
	})
	Library.Utilities.Icons:SetIcon(Window.PlayerDismissButton.Icon, "x")

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
	Library.Utilities.Icons:SetIcon(Window.PlayerVisibilityToggle.Icon, "eye")

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
		Text = LocalPlayer and (`@{LocalPlayer.Name}`) or "Unavailable",
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

	local PlayerCardDismissed = false
	local PlayerCardTween = TweenInfo.new(0.18, Enum.EasingStyle.Quint, Enum.EasingDirection.Out)
	local PlayerDisplayNameText = LocalPlayer and LocalPlayer.DisplayName or "Player"
	local PlayerMetaText = LocalPlayer and (`@{LocalPlayer.Name}`) or "Unavailable"
	local PlayerDetailMetaText = LocalPlayer and (`@{LocalPlayer.Name}  •  ID {LocalPlayer.UserId}`) or "Unavailable"
	local PlayerCardStroke = Window.PlayerCard.UIStroke
	local PlayerCardScale = Window.PlayerCard.UIScale
	local PlayerCardRole = "Community Profile"

	local function CopyToClipboard(Value)
		local CopyFunction = setclipboard
			or toclipboard
			or set_clipboard
			or copystring
			or (Clipboard and Clipboard.set)
			or (clipboard and clipboard.set)
			or (Clipboard and Clipboard.copy)
			or (clipboard and clipboard.copy)

		if typeof(CopyFunction) == "function" then
			return pcall(CopyFunction, Value)
		end

		return false
	end

	local function TrimText(Value)
		return tostring(Value or ""):match("^%s*(.-)%s*$")
	end

	local function GetRequestFunction()
		return request
			or http_request
			or (syn and syn.request)
			or (http and http.request)
			or (fluxus and fluxus.request)
	end

	local function GetExecutorName()
		if typeof(identifyexecutor) == "function" then
			local Success, ExecutorName = pcall(identifyexecutor)
			if Success and ExecutorName then
				return tostring(ExecutorName)
			end
		end

		return "Unknown"
	end

	local function SendFeedbackWebhook(FeedbackType, WebhookUrl, ScriptName, FeedbackContent)
		local RequestFunction = GetRequestFunction()
		if typeof(RequestFunction) ~= "function" then
			return false, "HTTP requests are not supported by this executor."
		end

		local Payload = {
			embeds = {{
				title = `Script {FeedbackType}: {ScriptName}`,
				color = FeedbackType == "Suggest" and 16766720 or 16740488,
				fields = {
					{
						name = "Name Script",
						value = ScriptName,
						inline = false,
					},
					{
						name = FeedbackType == "Suggest" and "Suggest" or "Report Bug",
						value = FeedbackContent,
						inline = false,
					},
					{
						name = "Executor",
						value = GetExecutorName(),
						inline = false,
					},
				},
				footer = {
					text = "Time: " .. os.date("%c"),
				},
			}},
		}

		local Success, Response = pcall(RequestFunction, {
			Url = WebhookUrl,
			Method = "POST",
			Headers = {
				["Content-Type"] = "application/json",
			},
			Body = HttpService:JSONEncode(Payload),
		})

		if not Success then
			return false, tostring(Response)
		end

		if typeof(Response) == "table" then
			local StatusCode = tonumber(Response.StatusCode or Response.Status)
			if StatusCode and (StatusCode < 200 or StatusCode >= 300) then
				return false, Response.Body or `Request failed ({StatusCode}).`
			end
		end

		return true
	end

	local function UpdatePlayerCardLayout()
		local ReservedHeight = SearchBarHeight + SearchBarPadding
		if not PlayerCardDismissed then
			ReservedHeight += UserCardHeight + UserCardPadding
		end

		Window.PlayerCard.Visible = not PlayerCardDismissed
		Window.TabHolder.Size = UDim2.new(1, 0, 1, -ReservedHeight)
	end

	local function DismissPlayerCard()
		if PlayerCardDismissed then
			return
		end

		PlayerCardDismissed = true
		UpdatePlayerCardLayout()
	end

	local function SetPlayerCardState(State)
		local BackgroundTransparency = 0.22
		local StrokeTransparency = 0.35
		local Scale = 1
		local AccentTransparency = 0.35

		if State == "hover" then
			BackgroundTransparency = 0.14
			StrokeTransparency = 0.18
			Scale = 1.02
			AccentTransparency = 0.05
		elseif State == "pressed" then
			BackgroundTransparency = 0.08
			StrokeTransparency = 0
			Scale = 0.985
			AccentTransparency = 0
		end

		TweenService:Create(Window.PlayerCard, PlayerCardTween, {
			BackgroundTransparency = BackgroundTransparency,
		}):Play()
		TweenService:Create(PlayerCardStroke, PlayerCardTween, {
			Transparency = StrokeTransparency,
		}):Play()
		TweenService:Create(PlayerCardScale, PlayerCardTween, {
			Scale = Scale,
		}):Play()
		TweenService:Create(Window.PlayerCardAccent, PlayerCardTween, {
			BackgroundTransparency = AccentTransparency,
		}):Play()
	end

	UpdatePlayerCardLayout()
	SetPlayerCardState("default")

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
		local MaxDialogWidth = math.min(620, Window.Size.X.Offset - 120)

		local Content = New("TextLabel", {
			FontFace = Font.new("rbxasset://fonts/families/GothamSSm.json"),
			Text = Config.Content,
			TextColor3 = Color3.fromRGB(240, 240, 240),
			TextSize = 14,
			TextXAlignment = Enum.TextXAlignment.Left,
			TextYAlignment = Enum.TextYAlignment.Top,
			AutomaticSize = Enum.AutomaticSize.Y,
			TextWrapped = true,
			Size = UDim2.new(1, -40, 0, 0),
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

		local TargetWidth = math.clamp(Content.TextBounds.X + 40, 300, MaxDialogWidth)
		Dialog.Root.Size = UDim2.fromOffset(TargetWidth, 165)
		task.wait()
		Dialog.Root.Size = UDim2.fromOffset(TargetWidth, math.max(165, Content.TextBounds.Y + 150))

		for _, Button in next, Config.Buttons do
			Dialog:Button(Button.Title, Button.Callback)
		end

		Dialog:Open()

		if Config.Yield then
			Dialog.Closed:Wait()
		end

		return Dialog
	end

	function Window:OpenFeedbackDialog(FeedbackConfig)
		local FeedbackDialog = DialogModule:Create()
		local DialogWidth = math.clamp(Window.Size.X.Offset - 210, 400, 460)
		local DialogHeight = math.clamp(Window.Size.Y.Offset - 165, 300, 340)
		local Sending = false
		local DialogAlive = true

		FeedbackDialog.Title.Text = FeedbackConfig.Title
		FeedbackDialog.Root.Size = UDim2.fromOffset(DialogWidth, DialogHeight)
		FeedbackDialog.Root.BackgroundTransparency = 0.08
		FeedbackDialog.Root.UIStroke.Color = FeedbackConfig.StrokeColor
		FeedbackDialog.Root.UIStroke.Transparency = 0.2
		FeedbackDialog.Root.ClipsDescendants = true
		FeedbackDialog.Title.Position = UDim2.fromOffset(18, 16)
		FeedbackDialog.Title.Size = UDim2.new(1, -36, 0, 24)
		FeedbackDialog.Title.TextSize = 18

		New("UISizeConstraint", {
			MinSize = Vector2.new(400, 300),
			MaxSize = Vector2.new(460, 340),
			Parent = FeedbackDialog.Root,
		})

		New("Frame", {
			Size = UDim2.fromScale(1, 1),
			BackgroundColor3 = Color3.fromRGB(10, 13, 19),
			BackgroundTransparency = 0.06,
			ZIndex = 0,
			Parent = FeedbackDialog.Root,
		}, {
			New("UICorner", {
				CornerRadius = UDim.new(0, 8),
			}),
			New("UIGradient", {
				Color = ColorSequence.new({
					ColorSequenceKeypoint.new(0, Color3.fromRGB(16, 19, 28)),
					ColorSequenceKeypoint.new(1, Color3.fromRGB(24, 17, 23)),
				}),
				Rotation = 18,
			}),
		})

		New("TextLabel", {
			BackgroundTransparency = 1,
			Position = UDim2.fromOffset(18, 48),
			Size = UDim2.new(1, -36, 0, 18),
			FontFace = Font.new("rbxasset://fonts/families/GothamSSm.json", Enum.FontWeight.Medium, Enum.FontStyle.Normal),
			Text = FeedbackConfig.Description,
			TextSize = 12,
			TextWrapped = true,
			TextXAlignment = Enum.TextXAlignment.Left,
			TextColor3 = Color3.fromRGB(209, 213, 222),
			Parent = FeedbackDialog.Root,
		})

		local ScriptNameBox = require(Components.Textbox)(FeedbackDialog.Root, false)
		ScriptNameBox.Frame.Size = UDim2.new(1, -36, 0, 34)
		ScriptNameBox.Frame.Position = UDim2.fromOffset(18, 76)
		ScriptNameBox.Input.PlaceholderText = "Script name"
		ScriptNameBox.Input.ClearTextOnFocus = false
		ScriptNameBox.Input.Text = Config.Title or ""
		ScriptNameBox.Input.Size = UDim2.new(1, -8, 1, 0)
		ScriptNameBox.Input.Position = UDim2.fromOffset(4, 0)

		local ReportBox = New("Frame", {
			Size = UDim2.new(1, -36, 0, 110),
			Position = UDim2.fromOffset(18, 120),
			BackgroundTransparency = 0.08,
			Parent = FeedbackDialog.Root,
			ThemeTag = {
				BackgroundColor3 = "DialogInput",
			},
		}, {
			New("UICorner", {
				CornerRadius = UDim.new(0, 10),
			}),
			New("UIStroke", {
				Transparency = 0.45,
				ThemeTag = {
					Color = "DialogButtonBorder",
				},
			}),
		})

		local ReportInput = New("TextBox", {
			BackgroundTransparency = 1,
			Position = UDim2.fromOffset(12, 10),
			Size = UDim2.new(1, -24, 1, -20),
			FontFace = Font.new("rbxasset://fonts/families/GothamSSm.json"),
			Text = "",
			PlaceholderText = FeedbackConfig.PlaceholderText,
			TextSize = 13,
			ClearTextOnFocus = false,
			MultiLine = true,
			TextWrapped = true,
			TextXAlignment = Enum.TextXAlignment.Left,
			TextYAlignment = Enum.TextYAlignment.Top,
			ThemeTag = {
				TextColor3 = "Text",
				PlaceholderColor3 = "SubText",
			},
			Parent = ReportBox,
		})

		FeedbackDialog.ButtonHolderFrame.BackgroundTransparency = 1
		FeedbackDialog.ButtonHolderFrame.Frame.BackgroundColor3 = FeedbackConfig.StrokeColor
		FeedbackDialog.ButtonHolderFrame.Frame.BackgroundTransparency = 0.9
		FeedbackDialog.ButtonHolderFrame.Size = UDim2.new(1, 0, 0, 58)
		FeedbackDialog.ButtonHolderFrame.Position = UDim2.new(0, 0, 1, -58)
		FeedbackDialog.ButtonHolder.Size = UDim2.new(1, -36, 0, 40)
		FeedbackDialog.ButtonHolder.Position = UDim2.fromScale(0.5, 0.5)

		local SendButton = DialogButtonComponent("", FeedbackDialog.ButtonHolder, true)
		local CancelButton = DialogButtonComponent("", FeedbackDialog.ButtonHolder, true)
		SendButton.Title.Text = "Send"
		CancelButton.Title.Text = "Cancel"

		for _, Button in next, { SendButton, CancelButton } do
			Button.Frame.Size = UDim2.new(0.5, -5, 0, 40)
			Button.Frame.UICorner.CornerRadius = UDim.new(0, 10)
			Button.Frame.UIStroke.Transparency = 0.28
			Button.Title.TextSize = 12
		end

		SendButton.Frame.BackgroundTransparency = 0
		SendButton.Frame.BackgroundColor3 = FeedbackConfig.ButtonColor
		SendButton.Frame.UIStroke.Color = FeedbackConfig.StrokeColor
		SendButton.Title.TextColor3 = FeedbackConfig.ButtonTextColor
		SendButton.HoverFrame.BackgroundTransparency = 1

		CancelButton.Frame.BackgroundColor3 = Color3.fromRGB(38, 44, 56)
		CancelButton.Frame.BackgroundTransparency = 0.14
		CancelButton.Frame.UIStroke.Color = Color3.fromRGB(145, 153, 166)
		CancelButton.Title.TextColor3 = Color3.fromRGB(215, 220, 230)
		CancelButton.HoverFrame.BackgroundTransparency = 1

		local function SetSubmitting(IsSubmitting)
			Sending = IsSubmitting
			SendButton.Title.Text = IsSubmitting and "Sending..." or "Send"
			SendButton.Frame.Active = not IsSubmitting
			CancelButton.Frame.Active = not IsSubmitting
			SendButton.Frame.AutoButtonColor = false
			CancelButton.Frame.AutoButtonColor = false
			SendButton.Frame.BackgroundTransparency = IsSubmitting and 0.12 or 0
			CancelButton.Frame.BackgroundTransparency = IsSubmitting and 0.3 or 0.14
		end

		Creator.AddSignal(SendButton.Frame.MouseButton1Click, function()
			if Sending then
				return
			end

			local ScriptName = TrimText(ScriptNameBox.Input.Text)
			local ReportContent = TrimText(ReportInput.Text)

			if ScriptName == "" or ReportContent == "" then
				Library:Notify({
					Title = FeedbackConfig.TypeName,
					Content = "Please fill in both the script name and content.",
					Duration = 4,
				})
				return
			end

			SetSubmitting(true)

			task.spawn(function()
				local Success, ErrorMessage = SendFeedbackWebhook(
					FeedbackConfig.TypeName,
					FeedbackConfig.WebhookUrl,
					ScriptName,
					ReportContent
				)

				task.defer(function()
					if DialogAlive then
						SetSubmitting(false)
					end

					Library:Notify({
						Title = FeedbackConfig.TypeName,
						Content = Success and `${FeedbackConfig.TypeName} sent successfully.` or (ErrorMessage or `Failed to send ${string.lower(FeedbackConfig.TypeName)}.`),
						Duration = 4,
					})

					if Success and DialogAlive then
						ReportInput.Text = ""
					end
				end)
			end)
		end)

		Creator.AddSignal(CancelButton.Frame.MouseButton1Click, function()
			if Sending then
				return
			end

			DialogAlive = false
			FeedbackDialog:Close()
		end)

		FeedbackDialog:Open()
	end

	Creator.AddSignal(Window.PlayerVisibilityToggle.MouseButton1Click, function()
		DismissPlayerCard()
	end)

	Creator.AddSignal(Window.PlayerDismissButton.MouseButton1Click, function()
		DismissPlayerCard()
	end)

	Creator.AddSignal(Window.PlayerCardButton.MouseEnter, function()
		SetPlayerCardState("hover")
	end)

	Creator.AddSignal(Window.PlayerCardButton.MouseLeave, function()
		SetPlayerCardState("default")
	end)

	Creator.AddSignal(Window.PlayerCardButton.MouseButton1Down, function()
		SetPlayerCardState("pressed")
	end)

	Creator.AddSignal(Window.PlayerCardButton.MouseButton1Up, function()
		SetPlayerCardState("hover")
	end)

	Creator.AddSignal(Window.PlayerCardButton.MouseButton1Click, function()
		local DialogWidth = math.clamp(Window.Size.X.Offset - 250, 420, 500)
		local DialogHeight = math.clamp(Window.Size.Y.Offset - 215, 300, 324)
		local DialogPadding = 16
		local HeaderY = 50
		local HeaderHeight = 78
		local FooterHeight = 56
		local FooterTop = DialogHeight - FooterHeight
		local DiscordY = HeaderY + HeaderHeight + 10
		local DiscordHeight = FooterTop - DiscordY - 10
		local BadgeWidth = math.clamp(math.floor(DialogWidth * 0.26), 124, 136)
		local HeaderTextLeft = 92
		local HeaderTextRight = BadgeWidth + 24
		local ProfileDialog = DialogModule:Create()
		ProfileDialog.Title.Text = "Profile Details"
		ProfileDialog.Root.Size = UDim2.fromOffset(DialogWidth, DialogHeight)
		ProfileDialog.Root.BackgroundTransparency = 0.12
		ProfileDialog.Root.UIStroke.Color = Color3.fromRGB(113, 225, 255)
		ProfileDialog.Root.UIStroke.Transparency = 0.18
		ProfileDialog.Root.ClipsDescendants = true
		ProfileDialog.Title.Position = UDim2.fromOffset(18, 16)
		ProfileDialog.Title.Size = UDim2.new(1, -74, 0, 26)
		ProfileDialog.Title.TextSize = 18
		ProfileDialog.Title.TextColor3 = Color3.fromRGB(244, 248, 255)

		local ReportButton = New("TextButton", {
			AnchorPoint = Vector2.new(1, 0),
			Position = UDim2.new(1, -16, 0, 14),
			Size = UDim2.fromOffset(28, 28),
			BackgroundColor3 = Color3.fromRGB(112, 30, 43),
			BackgroundTransparency = 0.08,
			Parent = ProfileDialog.Root,
			Text = "",
		}, {
			New("UICorner", {
				CornerRadius = UDim.new(0, 8),
			}),
			New("UIStroke", {
				Color = Color3.fromRGB(255, 111, 129),
				Transparency = 0.18,
			}),
			New("ImageLabel", {
				Name = "Icon",
				AnchorPoint = Vector2.new(0.5, 0.5),
				Position = UDim2.fromScale(0.5, 0.5),
				Size = UDim2.fromOffset(14, 14),
				BackgroundTransparency = 1,
				ImageColor3 = Color3.fromRGB(255, 214, 220),
			}),
		})
		Library.Utilities.Icons:SetIcon(ReportButton.Icon, "flag")
		Creator.AddSignal(ReportButton.MouseButton1Click, function()
			Window:OpenFeedbackDialog({
				TypeName = "Report",
				Title = "Report Script",
				Description = "Send the script name and your report directly to the Vxeze bot.",
				PlaceholderText = "Describe the issue or report content",
				WebhookUrl = ReportWebhookUrl,
				StrokeColor = Color3.fromRGB(255, 120, 136),
				ButtonColor = Color3.fromRGB(138, 52, 66),
				ButtonTextColor = Color3.fromRGB(255, 239, 242),
			})
		end)

		local SuggestButton = New("TextButton", {
			AnchorPoint = Vector2.new(1, 0),
			Position = UDim2.new(1, -50, 0, 14),
			Size = UDim2.fromOffset(28, 28),
			BackgroundColor3 = Color3.fromRGB(118, 88, 26),
			BackgroundTransparency = 0.08,
			Parent = ProfileDialog.Root,
			Text = "",
		}, {
			New("UICorner", {
				CornerRadius = UDim.new(0, 8),
			}),
			New("UIStroke", {
				Color = Color3.fromRGB(255, 211, 94),
				Transparency = 0.18,
			}),
			New("ImageLabel", {
				Name = "Icon",
				AnchorPoint = Vector2.new(0.5, 0.5),
				Position = UDim2.fromScale(0.5, 0.5),
				Size = UDim2.fromOffset(14, 14),
				BackgroundTransparency = 1,
				ImageColor3 = Color3.fromRGB(255, 243, 204),
			}),
		})
		Library.Utilities.Icons:SetIcon(SuggestButton.Icon, "message-square-plus")
		Creator.AddSignal(SuggestButton.MouseButton1Click, function()
			Window:OpenFeedbackDialog({
				TypeName = "Suggest",
				Title = "Suggest Script",
				Description = "Send your suggestion for this script directly to the Vxeze bot.",
				PlaceholderText = "Describe your suggestion",
				WebhookUrl = SuggestWebhookUrl,
				StrokeColor = Color3.fromRGB(255, 211, 94),
				ButtonColor = Color3.fromRGB(169, 125, 28),
				ButtonTextColor = Color3.fromRGB(255, 248, 229),
			})
		end)

		New("UISizeConstraint", {
			MinSize = Vector2.new(420, 300),
			MaxSize = Vector2.new(500, 324),
			Parent = ProfileDialog.Root,
		})

		New("Frame", {
			Size = UDim2.fromScale(1, 1),
			BackgroundColor3 = Color3.fromRGB(7, 10, 16),
			BackgroundTransparency = 0.1,
			ZIndex = 0,
			Parent = ProfileDialog.Root,
		}, {
			New("UICorner", {
				CornerRadius = UDim.new(0, 8),
			}),
			New("UIGradient", {
				Color = ColorSequence.new({
					ColorSequenceKeypoint.new(0, Color3.fromRGB(10, 14, 20)),
					ColorSequenceKeypoint.new(0.55, Color3.fromRGB(8, 13, 22)),
					ColorSequenceKeypoint.new(1, Color3.fromRGB(11, 22, 34)),
				}),
				Rotation = 18,
			}),
		})

		New("Frame", {
			AnchorPoint = Vector2.new(0.5, 0.5),
			Position = UDim2.fromScale(0.58, 0.4),
			Size = UDim2.fromOffset(132, 132),
			BackgroundTransparency = 1,
			ZIndex = 0,
			Parent = ProfileDialog.Root,
		}, {
			New("UICorner", {
				CornerRadius = UDim.new(1, 0),
			}),
			New("UIStroke", {
				Color = Color3.fromRGB(108, 229, 255),
				Transparency = 0.9,
				Thickness = 1.5,
			}),
		})

		New("Frame", {
			AnchorPoint = Vector2.new(0.5, 0.5),
			Position = UDim2.fromScale(0.58, 0.4),
			Size = UDim2.fromOffset(184, 184),
			BackgroundTransparency = 1,
			ZIndex = 0,
			Parent = ProfileDialog.Root,
		}, {
			New("UICorner", {
				CornerRadius = UDim.new(1, 0),
			}),
			New("UIStroke", {
				Color = Color3.fromRGB(108, 229, 255),
				Transparency = 0.94,
				Thickness = 1.5,
			}),
		})

		New("ImageLabel", {
			AnchorPoint = Vector2.new(0.5, 0.5),
			Position = UDim2.fromScale(0.6, 0.5),
			Size = UDim2.fromOffset(96, 96),
			Image = Window.PlayerAvatar.Image,
			ImageTransparency = 0.94,
			BackgroundTransparency = 1,
			ZIndex = 0,
			Parent = ProfileDialog.Root,
		})

		local Header = New("Frame", {
			Size = UDim2.new(1, -(DialogPadding * 2), 0, HeaderHeight),
			Position = UDim2.fromOffset(DialogPadding, HeaderY),
			BackgroundColor3 = Color3.fromRGB(20, 29, 41),
			BackgroundTransparency = 0.18,
			Parent = ProfileDialog.Root,
		}, {
			New("UICorner", {
				CornerRadius = UDim.new(0, 14),
			}),
			New("UIStroke", {
				Color = Color3.fromRGB(122, 213, 241),
				Transparency = 0.74,
				Thickness = 1,
			}),
			New("UIGradient", {
				Color = ColorSequence.new({
					ColorSequenceKeypoint.new(0, Color3.fromRGB(16, 24, 35)),
					ColorSequenceKeypoint.new(1, Color3.fromRGB(22, 35, 48)),
				}),
				Rotation = 8,
			}),
		})

		New("Frame", {
			Size = UDim2.new(1, -20, 0, 1),
			Position = UDim2.fromOffset(10, 0),
			BackgroundColor3 = Color3.fromRGB(114, 225, 255),
			BackgroundTransparency = 0.78,
			Parent = Header,
		})

		New("Frame", {
			AnchorPoint = Vector2.new(0.5, 0.5),
			Position = UDim2.fromScale(0.5, 0.5),
			Size = UDim2.fromOffset(94, 94),
			BackgroundTransparency = 1,
			Parent = Header,
		}, {
			New("UICorner", {
				CornerRadius = UDim.new(1, 0),
			}),
			New("UIStroke", {
				Color = Color3.fromRGB(113, 225, 255),
				Transparency = 0.94,
				Thickness = 1,
			}),
		})

		local AvatarRing = New("Frame", {
			Size = UDim2.fromOffset(60, 60),
			Position = UDim2.fromOffset(14, 9),
			BackgroundColor3 = Color3.fromRGB(111, 227, 255),
			BackgroundTransparency = 0.85,
			Parent = Header,
		}, {
			New("UICorner", {
				CornerRadius = UDim.new(1, 0),
			}),
			New("UIStroke", {
				Color = Color3.fromRGB(144, 238, 255),
				Transparency = 0.14,
				Thickness = 2,
			}),
		})

		local HeaderAvatar = New("ImageLabel", {
			Size = UDim2.fromOffset(48, 48),
			Position = UDim2.fromOffset(6, 6),
			BackgroundTransparency = 0.04,
			Image = Window.PlayerAvatar.Image,
			ScaleType = Enum.ScaleType.Crop,
			Parent = AvatarRing,
		}, {
			New("UICorner", {
				CornerRadius = UDim.new(1, 0),
			}),
		})

		New("TextLabel", {
			BackgroundTransparency = 1,
			Position = UDim2.fromOffset(HeaderTextLeft, 18),
			Size = UDim2.new(1, -(HeaderTextLeft + HeaderTextRight), 0, 22),
			FontFace = Font.new("rbxasset://fonts/families/GothamSSm.json", Enum.FontWeight.Bold, Enum.FontStyle.Normal),
			Text = PlayerDisplayNameText,
			TextSize = 15,
			TextXAlignment = Enum.TextXAlignment.Left,
			TextColor3 = Color3.fromRGB(247, 249, 255),
			TextTruncate = Enum.TextTruncate.AtEnd,
			Parent = Header,
		})

		New("TextLabel", {
			BackgroundTransparency = 1,
			Position = UDim2.fromOffset(HeaderTextLeft, 39),
			Size = UDim2.new(1, -(HeaderTextLeft + 22), 0, 16),
			FontFace = Font.new("rbxasset://fonts/families/GothamSSm.json", Enum.FontWeight.Medium, Enum.FontStyle.Normal),
			Text = PlayerDetailMetaText,
			TextSize = 10,
			TextXAlignment = Enum.TextXAlignment.Left,
			TextColor3 = Color3.fromRGB(156, 163, 177),
			TextTruncate = Enum.TextTruncate.AtEnd,
			Parent = Header,
		})

		local ProfileBadge = New("Frame", {
			AnchorPoint = Vector2.new(1, 0),
			Position = UDim2.new(1, -12, 0, 12),
			Size = UDim2.fromOffset(BadgeWidth, 26),
			BackgroundTransparency = 0,
			Parent = Header,
		}, {
			New("UICorner", {
				CornerRadius = UDim.new(1, 0),
			}),
			New("UIGradient", {
				Color = ColorSequence.new({
					ColorSequenceKeypoint.new(0, Color3.fromRGB(149, 239, 255)),
					ColorSequenceKeypoint.new(1, Color3.fromRGB(193, 229, 255)),
				}),
				Rotation = 0,
			}),
		})

		New("TextLabel", {
			BackgroundTransparency = 1,
			Size = UDim2.fromScale(1, 1),
			FontFace = Font.new("rbxasset://fonts/families/GothamSSm.json", Enum.FontWeight.Bold, Enum.FontStyle.Normal),
			Text = PlayerCardRole,
			TextSize = 10,
			TextXAlignment = Enum.TextXAlignment.Center,
			TextColor3 = Color3.fromRGB(29, 52, 63),
			TextTruncate = Enum.TextTruncate.AtEnd,
			Parent = ProfileBadge,
		})

		local DiscordPanel = New("Frame", {
			Size = UDim2.new(1, -(DialogPadding * 2), 0, DiscordHeight),
			Position = UDim2.fromOffset(DialogPadding, DiscordY),
			BackgroundColor3 = Color3.fromRGB(18, 28, 39),
			BackgroundTransparency = 0.18,
			Parent = ProfileDialog.Root,
		}, {
			New("UICorner", {
				CornerRadius = UDim.new(0, 14),
			}),
			New("UIStroke", {
				Color = Color3.fromRGB(122, 213, 241),
				Transparency = 0.76,
				Thickness = 1,
			}),
			New("UIGradient", {
				Color = ColorSequence.new({
					ColorSequenceKeypoint.new(0, Color3.fromRGB(16, 24, 34)),
					ColorSequenceKeypoint.new(1, Color3.fromRGB(22, 31, 44)),
				}),
				Rotation = 8,
			}),
		})

		New("TextLabel", {
			BackgroundTransparency = 1,
			Position = UDim2.fromOffset(14, 10),
			Size = UDim2.new(1, -28, 0, 16),
			FontFace = Font.new("rbxasset://fonts/families/GothamSSm.json", Enum.FontWeight.SemiBold, Enum.FontStyle.Normal),
			Text = "Discord Hub",
			TextSize = 12,
			TextXAlignment = Enum.TextXAlignment.Left,
			TextColor3 = Color3.fromRGB(245, 248, 255),
			Parent = DiscordPanel,
		})

		local function NotifyDiscordCopy()
			local CopyResult = CopyToClipboard(DiscordInviteUrl)
			if not CopyResult then
				CopyResult = CopyToClipboard(DiscordInvite)
			end

			Library:Notify({
				Title = "Discord",
				Content = CopyResult and `Copied: {DiscordInviteUrl}` or "Clipboard is not supported by this executor.",
				Duration = 4,
			})
		end

		local DiscordLink = New("TextButton", {
			BackgroundTransparency = 1,
			Position = UDim2.fromOffset(14, 28),
			Size = UDim2.new(1, -28, 0, 22),
			FontFace = Font.new("rbxasset://fonts/families/GothamSSm.json", Enum.FontWeight.Bold, Enum.FontStyle.Normal),
			Text = DiscordInvite,
			TextSize = 15,
			TextXAlignment = Enum.TextXAlignment.Left,
			TextColor3 = Color3.fromRGB(115, 228, 255),
			TextTruncate = Enum.TextTruncate.AtEnd,
			AutoButtonColor = false,
			Parent = DiscordPanel,
		})
		Creator.AddSignal(DiscordLink.MouseButton1Click, NotifyDiscordCopy)

		New("Frame", {
			Position = UDim2.fromOffset(14, 49),
			Size = UDim2.new(0, 88, 0, 1),
			BackgroundColor3 = Color3.fromRGB(115, 228, 255),
			BackgroundTransparency = 0.55,
			Parent = DiscordPanel,
		})

		local function CreateDiscordInfoColumn(Parent, Position, IconName, Label, Value)
			local Holder = New("Frame", {
				Position = Position,
				Size = UDim2.new(0.5, -18, 0, 28),
				BackgroundColor3 = Color3.fromRGB(14, 20, 30),
				BackgroundTransparency = 0.18,
				Parent = Parent,
			}, {
				New("UICorner", {
					CornerRadius = UDim.new(0, 8),
				}),
				New("UIStroke", {
					Color = Color3.fromRGB(130, 179, 200),
					Transparency = 0.84,
					Thickness = 1,
				}),
			})

			local Icon = New("ImageLabel", {
				AnchorPoint = Vector2.new(0, 0.5),
				Position = UDim2.fromOffset(10, 14),
				Size = UDim2.fromOffset(12, 12),
				BackgroundTransparency = 1,
				ImageColor3 = Color3.fromRGB(194, 201, 214),
				Parent = Holder,
			})
			Library.Utilities.Icons:SetIcon(Icon, IconName)

			New("TextLabel", {
				BackgroundTransparency = 1,
				Position = UDim2.fromOffset(28, 0),
				Size = UDim2.new(1, -36, 1, 0),
				FontFace = Font.new("rbxasset://fonts/families/GothamSSm.json", Enum.FontWeight.Medium, Enum.FontStyle.Normal),
				Text = `{Label}: {Value}`,
				TextSize = 10,
				TextXAlignment = Enum.TextXAlignment.Left,
				TextColor3 = Color3.fromRGB(225, 228, 236),
				TextTruncate = Enum.TextTruncate.AtEnd,
				Parent = Holder,
			})
		end

		CreateDiscordInfoColumn(DiscordPanel, UDim2.fromOffset(14, DiscordHeight - 36), "crown", "Owner", DiscordOwner)
		CreateDiscordInfoColumn(DiscordPanel, UDim2.new(0.5, 4, 0, DiscordHeight - 36), "shield", "Co-Owner", DiscordCoOwner)

		ProfileDialog.ButtonHolderFrame.BackgroundTransparency = 1
		ProfileDialog.ButtonHolderFrame.Frame.BackgroundColor3 = Color3.fromRGB(113, 225, 255)
		ProfileDialog.ButtonHolderFrame.Frame.BackgroundTransparency = 0.88
		ProfileDialog.ButtonHolderFrame.Size = UDim2.new(1, 0, 0, FooterHeight)
		ProfileDialog.ButtonHolderFrame.Position = UDim2.new(0, 0, 1, -FooterHeight)
		ProfileDialog.ButtonHolder.Size = UDim2.new(1, -(DialogPadding * 2), 0, 40)
		ProfileDialog.ButtonHolder.Position = UDim2.fromScale(0.5, 0.5)

		local CopyButton = ProfileDialog:Button("Copy Discord Link", function()
			NotifyDiscordCopy()
		end)
		local CloseButton = ProfileDialog:Button("Đóng", function() end)

		for _, Button in next, { CopyButton, CloseButton } do
			Button.Frame.Size = UDim2.new(0.5, -5, 0, 40)
			Button.Frame.UICorner.CornerRadius = UDim.new(0, 10)
			Button.Frame.UIStroke.Transparency = 0.3
			Button.Title.TextSize = 12
			Button.Title.TextXAlignment = Enum.TextXAlignment.Left
			Button.Title.Size = UDim2.new(1, -46, 1, 0)
			Button.Title.Position = UDim2.fromOffset(34, 0)
		end

		CopyButton.Frame.BackgroundTransparency = 0
		CopyButton.Frame.UIStroke.Transparency = 0.72
		CopyButton.Frame.BackgroundColor3 = Color3.fromRGB(138, 230, 255)
		New("UIGradient", {
			Color = ColorSequence.new({
				ColorSequenceKeypoint.new(0, Color3.fromRGB(141, 231, 255)),
				ColorSequenceKeypoint.new(1, Color3.fromRGB(189, 242, 255)),
			}),
			Rotation = 0,
			Parent = CopyButton.Frame,
		})
		CopyButton.Title.TextColor3 = Color3.fromRGB(18, 30, 38)
		CopyButton.HoverFrame.BackgroundTransparency = 1

		CloseButton.Frame.BackgroundColor3 = Color3.fromRGB(39, 46, 58)
		CloseButton.Frame.BackgroundTransparency = 0.2
		CloseButton.Frame.UIStroke.Color = Color3.fromRGB(151, 163, 176)
		CloseButton.Title.TextColor3 = Color3.fromRGB(200, 232, 242)
		CloseButton.HoverFrame.BackgroundTransparency = 1

		local CopyIcon = New("ImageLabel", {
			AnchorPoint = Vector2.new(0, 0.5),
			Position = UDim2.fromOffset(12, 20),
			Size = UDim2.fromOffset(16, 16),
			BackgroundTransparency = 1,
			ImageColor3 = Color3.fromRGB(18, 30, 38),
			Parent = CopyButton.Frame,
		})
		Library.Utilities.Icons:SetIcon(CopyIcon, "link")

		local CloseIcon = New("ImageLabel", {
			AnchorPoint = Vector2.new(0, 0.5),
			Position = UDim2.fromOffset(12, 20),
			Size = UDim2.fromOffset(16, 16),
			BackgroundTransparency = 1,
			ImageColor3 = Color3.fromRGB(130, 224, 255),
			Parent = CloseButton.Frame,
		})
		Library.Utilities.Icons:SetIcon(CloseIcon, "x")

		ProfileDialog:Open()
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
