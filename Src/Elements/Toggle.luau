local TweenService, UserInputService = game:GetService("TweenService"), game:GetService("UserInputService")
local Root = script.Parent.Parent
local Creator = require(Root.Modules.Creator)
 
local New = Creator.New
local Components = Root.Components

local Element = {}
Element.__index = Element
Element.__type = "Toggle"

function Element:New(Idx, Config)
	local Library = self.Library
	assert(Config.Title, "Toggle - Missing Title")

	local Toggle = {
		Value = Config.Default or Config.Value or false,
		Callback = Config.Callback or function(Value) end,
		Type = "Toggle",
		ParticleToken = 0,
	}

	local ToggleFrame = require(Components.Element)(Config.Title, Config.Description, self.Container, true)
	ToggleFrame.DescLabel.Size = UDim2.new(1, -54, 0, 14)

	Toggle.SetTitle = ToggleFrame.SetTitle
	Toggle.SetDesc = ToggleFrame.SetDesc

	local ToggleCircle = New("ImageLabel", {
		AnchorPoint = Vector2.new(0, 0.5),
		Size = UDim2.fromOffset(14, 14),
		Position = UDim2.new(0, 2, 0.5, 0),
		Image = "http://www.roblox.com/asset/?id=12266946128",
		ImageTransparency = 0.5,
		ThemeTag = {
			ImageColor3 = "ToggleSlider",
		},
	}) :: ImageLabel

	local ToggleBorder = New("UIStroke", {
		Transparency = 0.5,
		ThemeTag = {
			Color = "ToggleSlider",
		},
	})

	local ParticleHolder = New("Frame", {
		Size = UDim2.new(1, -4, 1, -4),
		Position = UDim2.fromOffset(2, 2),
		BackgroundTransparency = 1,
		ClipsDescendants = true,
	}, {
		New("UICorner", {
			CornerRadius = UDim.new(0, 7),
		}),
	}) :: Frame

	local ToggleSlider = New("Frame", {
		Size = UDim2.fromOffset(36, 18),
		AnchorPoint = Vector2.new(1, 0.5),
		Position = UDim2.new(1, -10, 0.5, 0),
		Parent = ToggleFrame.Frame,
		BackgroundTransparency = 1,
		ThemeTag = {
			BackgroundColor3 = "Accent",
		},
	}, {
		New("UICorner", {
			CornerRadius = UDim.new(0, 9),
		}),
		ToggleBorder,
		ParticleHolder,
		ToggleCircle,
	}) :: Frame

	local Particles = {}

	local function FadeParticles(Transparency, Duration)
		for _, Particle in next, Particles do
			TweenService:Create(
				Particle,
				TweenInfo.new(Duration, Enum.EasingStyle.Quad, Enum.EasingDirection.Out),
				{ BackgroundTransparency = Transparency }
			):Play()
		end
	end

	local function RunParticle(Particle, Token)
		task.spawn(function()
			while Toggle.ParticleToken == Token and Toggle.Value and Particle.Parent do
				local StartX = math.random(-4, 10)
				local EndX = StartX + math.random(10, 18)
				local StartY = math.random(2, 10)
				local EndY = math.clamp(StartY + math.random(-2, 2), 2, 10)
				local PeakTransparency = math.random(45, 68) / 100
				local TravelTime = math.random(14, 24) / 10

				Particle.Visible = true
				Particle.Position = UDim2.fromOffset(StartX, StartY)
				Particle.BackgroundTransparency = 1

				TweenService:Create(
					Particle,
					TweenInfo.new(TravelTime, Enum.EasingStyle.Linear, Enum.EasingDirection.Out),
					{
						Position = UDim2.fromOffset(EndX, EndY),
						BackgroundTransparency = PeakTransparency,
					}
				):Play()

				task.wait(TravelTime * 0.6)

				if Toggle.ParticleToken ~= Token or not Toggle.Value or not Particle.Parent then
					break
				end

				TweenService:Create(
					Particle,
					TweenInfo.new(TravelTime * 0.4, Enum.EasingStyle.Quad, Enum.EasingDirection.Out),
					{ BackgroundTransparency = 1 }
				):Play()

				task.wait(math.random(10, 24) / 100)
			end

			if Particle.Parent then
				Particle.BackgroundTransparency = 1
			end
		end)
	end

	for ParticleIndex = 1, 6 do
		local Size = math.random(1, 2) + (ParticleIndex % 3 == 0 and 1 or 0)
		local Particle = New("Frame", {
			Size = UDim2.fromOffset(Size, Size),
			Position = UDim2.fromOffset(math.random(0, 24), math.random(2, 10)),
			BackgroundColor3 = Color3.fromRGB(234, 247, 255),
			BackgroundTransparency = 1,
			Visible = true,
			Parent = ParticleHolder,
		}, {
			New("UICorner", {
				CornerRadius = UDim.new(1, 0),
			}),
		}) :: Frame

		Particles[#Particles + 1] = Particle
	end

	local function UpdateParticles(IsEnabled)
		Toggle.ParticleToken += 1
		local Token = Toggle.ParticleToken

		if not IsEnabled then
			FadeParticles(1, 0.15)
			return
		end

		for _, Particle in next, Particles do
			RunParticle(Particle, Token)
		end
	end

	function Toggle:OnChanged(Func)
		Toggle.Changed = Func
		Library:SafeCallback(Func, Toggle.Value, Toggle.Value)
	end

	function Toggle:SetValue(Value)
		Value = not not Value

		rawset(Toggle, "Value", Value)

		Creator.OverrideTag(ToggleBorder, { Color = Toggle.Value and "Accent" or "ToggleSlider" })
		Creator.OverrideTag(ToggleCircle, { ImageColor3 = Toggle.Value and "ToggleToggled" or "ToggleSlider" })

		ToggleCircle:TweenPosition(
			UDim2.new(0, Toggle.Value and 19 or 2, 0.5, 0),
			Enum.EasingDirection.Out,
			Enum.EasingStyle.Quint,
			.25,
			true
		)

		TweenService:Create(
			ToggleSlider,
			TweenInfo.new(0.25, Enum.EasingStyle.Quint, Enum.EasingDirection.Out),
			{ BackgroundTransparency = Toggle.Value and 0.08 or 1 }
		):Play()

		ToggleCircle.ImageTransparency = Toggle.Value and 0 or 0.5
		UpdateParticles(Toggle.Value)

		if typeof(Toggle.Callback) == "function" then
			Library:SafeCallback(Toggle.Callback, Toggle.Value)
		end
		if typeof(Toggle.Changed) == "function" then
			Library:SafeCallback(Toggle.Changed, Toggle.Value)
		end
	end

	function Toggle:Destroy()
		Toggle.ParticleToken += 1
		ToggleFrame:Destroy()
		Library.Options[Idx] = nil
	end

	-- Lock Functionality
	function Toggle:Lock(Reason)
		if Toggle.Locked then return end
		Toggle.Locked = true
		
		if not Toggle.LockOverlay then
			Toggle.LockOverlay = New("Frame", {
				Size = UDim2.fromScale(1, 1),
				BackgroundColor3 = Color3.new(0, 0, 0),
				BackgroundTransparency = 0.6,
				ZIndex = 10,
				Parent = ToggleFrame.Frame,
			}, {
				New("UICorner", { CornerRadius = UDim.new(0, 8) })
			})
			
			Toggle.LockIcon = New("ImageLabel", {
				Size = UDim2.fromOffset(20, 20),
				Position = UDim2.fromScale(0.5, 0.5),
				AnchorPoint = Vector2.new(0.5, 0.5),
				BackgroundTransparency = 1,
				Parent = Toggle.LockOverlay,
				ZIndex = 11,
				ThemeTag = {
					ImageColor3 = "Text",
				},
			})
			Library.Utilities.Icons:SetIcon(Toggle.LockIcon, "lock")
		end
		
		Toggle.LockOverlay.Visible = true
	end

	function Toggle:Unlock()
		if not Toggle.Locked then return end
		Toggle.Locked = false
		
		if Toggle.LockOverlay then
			Toggle.LockOverlay.Visible = false
		end
	end

	Creator.AddSignal(ToggleFrame.Frame.MouseButton1Click, function()
		if Toggle.Locked then return end
		Toggle:SetValue(not Toggle.Value)
	end)

	Toggle.Keybind = setmetatable({}, { -- TODO: Rewrite this piece of shit
		__call = function(_, self, Idx, Config)
			local Keybind = {
				Value = Config.Default or Config.Value or Enum.KeyCode.Unknown,
				Toggled = false,
				Mode = Config.Mode or "Toggle",
				Type = "Keybind",
				Callback = Config.Callback or function(Value) end,
				ChangedCallback = Config.ChangedCallback or function(New) end,
				Instance = nil
			}

			local Picking = false

			local KeybindDisplayLabel = New("TextLabel", {
				FontFace = Font.new("rbxasset://fonts/families/GothamSSm.json", Enum.FontWeight.Regular, Enum.FontStyle.Normal),
				Text = Library.Utilities:Prettify(Keybind.Value),
				TextColor3 = Color3.fromRGB(240, 240, 240),
				TextSize = 13,
				TextXAlignment = Enum.TextXAlignment.Center,
				Size = UDim2.new(0, 0, 0, 14),
				Position = UDim2.new(0, 0, 0.5, 0),
				AnchorPoint = Vector2.new(0, 0.5),
				BackgroundColor3 = Color3.fromRGB(255, 255, 255),
				AutomaticSize = Enum.AutomaticSize.X,
				BackgroundTransparency = 1,
				ThemeTag = {
					TextColor3 = "Text",
				},
			})
		
			local KeybindDisplayFrame: TextButton = New("TextButton", {
				Size = UDim2.fromOffset(0, 30),
				Position = UDim2.new(1, -10, 0.5, 0),
				AnchorPoint = Vector2.new(1, 0.5),
				BackgroundTransparency = 0.9,
				Parent = ToggleFrame.Frame,
				AutomaticSize = Enum.AutomaticSize.X,
				ThemeTag = {
					BackgroundColor3 = "Keybind",
				},
			}, {
				New("UICorner", {
					CornerRadius = UDim.new(0, 5),
				}),
				New("UIPadding", {
					PaddingLeft = UDim.new(0, 8),
					PaddingRight = UDim.new(0, 8),
				}),
				New("UIStroke", {
					Transparency = 0.5,
					ApplyStrokeMode = Enum.ApplyStrokeMode.Border,
					ThemeTag = {
						Color = "InElementBorder",
					},
				}),
				KeybindDisplayLabel
			})

			Keybind.Instance = setmetatable({
				CreatedAt = tick()
			}, {
				__index = function(self, idx)
					if rawget(self, idx) then
						return rawget(self, idx)
					else
						return KeybindDisplayFrame[idx]
					end
				end
			})
	
			local function UpdateTogglePosition()
				ToggleSlider.Position = UDim2.new(1, KeybindDisplayFrame.Position.X.Offset - KeybindDisplayFrame.AbsoluteSize.X - 10, 0.5, 0)
			end
	
			function Keybind:GetState()
				if UserInputService:GetFocusedTextBox() and self.Mode ~= "Always" then
					return false
				end
		
				if self.Mode == "Always" then
					return true
				elseif self.Mode == "Hold" then
					if self.Value == "None" then
						return false
					end
		
					local Key = self.Value
		
					if Key == "LeftMousebutton" or Key == "RightMousebutton" then
						return Key == "LeftMousebutton" and UserInputService:IsMouseButtonPressed(Enum.UserInputType.MouseButton1)
							or Key == "RightMousebutton"
								and UserInputService:IsMouseButtonPressed(Enum.UserInputType.MouseButton2)
					else
						return UserInputService:IsKeyDown(Enum.KeyCode[self.Value])
					end
				else
					return self.Toggled
				end
			end
		
			function Keybind:SetValue(Key, Mode)
				Key = Key or self.Value
				Mode = Mode or self.Mode
		
				self.Value = Key
				self.Mode = Mode
		
				KeybindDisplayLabel.Text = Library.Utilities:Prettify(self.Value)
			end
		
			function Keybind:OnClick(Callback)
				self.Clicked = Callback
			end
		
			function Keybind:OnChanged(Callback)
				self.Changed = Callback
				Library:SafeCallback(Callback, self.Value, self.Value)
			end
		
			function Keybind:DoClick()
				Toggle:SetValue(not Toggle.Value)
				
				if typeof(self.Callback) == "function" then
					Library:SafeCallback(self.Callback, self.Value)
				end
				if typeof(self.Clicked) == "function" then
					Library:SafeCallback(self.Clicked, self.Value)
				end
			end
		
			function Keybind:Destroy()
				KeybindDisplayFrame.Size = UDim2.new()
				KeybindDisplayFrame.Position = UDim2.new()
				KeybindDisplayFrame:Destroy()
				Library.Options[Idx] = nil
			end
		
			Creator.AddSignal(KeybindDisplayFrame.InputBegan, function(Input)
				if
					Input.UserInputType == Enum.UserInputType.MouseButton1
					or Input.UserInputType == Enum.UserInputType.Touch
				then
					Picking = true
					KeybindDisplayLabel.Text = "..."
		
					wait(0.2)
		
					UserInputService.InputBegan:Once(function(Input)
						local Key
		
						if Input.UserInputType == Enum.UserInputType.Keyboard then
							Key = Input.KeyCode.Name
						elseif Input.UserInputType == Enum.UserInputType.MouseButton1 then
							Key = "LeftMousebutton"
						elseif Input.UserInputType == Enum.UserInputType.MouseButton2 then
							Key = "RightMousebutton"
						end
		
						UserInputService.InputEnded:Once(function(Input)
							if (Input.KeyCode.Name == Key
								or Key == "LeftMousebutton" and Input.UserInputType == Enum.UserInputType.MouseButton1
								or Key == "RightMousebutton" and Input.UserInputType == Enum.UserInputType.MouseButton2)
								and not Library.Unloaded
							then
								Picking = false
		
								Keybind:SetValue(Key)
		
								Library:SafeCallback(self.ChangedCallback, Input.KeyCode or Input.UserInputType)
								Library:SafeCallback(self.Changed, Input.KeyCode or Input.UserInputType)
							end
						end)
					end)
				end
			end)
		
			Creator.AddSignal(UserInputService.InputBegan, function(Input)
				if not Picking and not UserInputService:GetFocusedTextBox() then
					if Keybind.Mode == "Toggle" then
						local Key = Keybind.Value

						if Key == "LeftMousebutton" or Key == "RightMousebutton" then
							if
								Key == "LeftMousebutton" and Input.UserInputType == Enum.UserInputType.MouseButton1
								or Key == "RightMousebutton" and Input.UserInputType == Enum.UserInputType.MouseButton2
							then
								Keybind.Toggled = not Keybind.Toggled
								Keybind:DoClick()
							end
						elseif Input.UserInputType == Enum.UserInputType.Keyboard then
							if Input.KeyCode.Name == Key or Input.KeyCode == Key then
								Keybind.Toggled = not Keybind.Toggled
								Keybind:DoClick()
							end
						end
					end
				end
			end)
	
			Creator.AddSignal(KeybindDisplayFrame:GetPropertyChangedSignal("AbsoluteSize"), UpdateTogglePosition)

			Library.Options[Idx] = Keybind

			Toggle.Keybind = Keybind
	
			return setmetatable(Toggle.Keybind, {
				__newindex =  function(self, index, newvalue)
					if index == "Value" then
						task.spawn(Keybind.SetValue, Keybind, newvalue)
					end
					rawset(self, index, newvalue)
				end
			})
		end
	})

	Toggle:SetValue(Toggle.Value)

	Library.Options[Idx] = Toggle

	Toggle.Instance = ToggleFrame

	return setmetatable(Toggle, {
		__newindex =  function(self, index, newvalue)
			if index == "Value" then
				task.spawn(Toggle.SetValue, Toggle, newvalue)
			end
			rawset(self, index, newvalue)
		end
	})
end

return Element
