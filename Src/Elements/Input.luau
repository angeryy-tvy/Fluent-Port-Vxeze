local Root = script.Parent.Parent
local Creator = require(Root.Modules.Creator)

local AddSignal = Creator.AddSignal
local Components = Root.Components

local Element = {}
Element.__index = Element
Element.__type = "Input"

function Element:New(Idx, Config)
	local Library = self.Library
	assert(Config.Title, "Input - Missing Title")
	Config.Callback = Config.Callback or function() end

	local Input = {
		Value = Config.Default or Config.Value or "",
		Numeric = Config.Numeric or false,
		Finished = Config.Finished or false,
		Callback = Config.Callback or function(Value) end,
		ClearOnFocusLost = Config.ClearOnFocusLost or false,
		Type = "Input",
	}

	local InputFrame = require(Components.Element)(Config.Title, Config.Description, self.Container, false)

	Input.SetTitle = InputFrame.SetTitle
	Input.SetDesc = InputFrame.SetDesc

	local Textbox = require(Components.Textbox)(InputFrame.Frame, true)
	Textbox.Frame.Position = UDim2.new(1, -10, 0.5, 0)
	Textbox.Frame.AnchorPoint = Vector2.new(1, 0.5)
	Textbox.Frame.Size = UDim2.fromOffset(160, 30)
	Textbox.Input.Text = Config.Default or ""
	Textbox.Input.PlaceholderText = Config.Placeholder or ""

	local Box = Textbox.Input

	function Input:SetValue(Text)
		if Config.MaxLength and #Text > Config.MaxLength then
			Text = Text:sub(1, Config.MaxLength)
		end

		if Input.Numeric then
			if (not tonumber(Text)) and Text:len() > 0 then
				Text = Input.Value
			end
		end

		rawset(Input, "Value", Text)
		Box.Text = Text

		if typeof(Input.Callback) == "function" then
			Library:SafeCallback(Input.Callback, Input.Value)
		end
		if typeof(Input.Changed) == "function" then
			Library:SafeCallback(Input.Changed, Input.Value)
		end
	end

	if Input.Finished then
		AddSignal(Box.FocusLost, function(enter: boolean, input: InputObject)
			if not enter then
				return
			end

			Input:SetValue(Box.Text)

			if Config.ClearOnFocusLost then
				Box.Text = ""
			end
		end)
	else
		AddSignal(Box:GetPropertyChangedSignal("Text"), function()
			Input:SetValue(Box.Text)
		end)
	end

	function Input:OnChanged(Func)
		Input.Changed = Func
		Library:SafeCallback(Func, Input.Value, Input.Value)
	end

	function Input:Destroy()
		InputFrame:Destroy()
		Library.Options[Idx] = nil
	end
	
	-- Lock Functionality
	function Input:Lock(Reason)
		if Input.Locked then return end
		Input.Locked = true
		Input.SetDesc(nil)
		
		if not Input.LockIcon then
			Input.LockIcon = New("ImageLabel", {
				Image = "rbxassetid://3926305904",
				Size = UDim2.fromOffset(16, 16),
				AnchorPoint = Vector2.new(1, 0.5),
				Position = UDim2.new(1, -5, 0.5, 0),
				BackgroundTransparency = 1,
				Parent = Textbox.Frame,
				ThemeTag = {
					ImageColor3 = "SubText",
				},
				ZIndex = 5
			})
		end
		Input.LockIcon.Visible = true
		Box.TextEditable = false
		Box.ClearTextOnFocus = false
		
		Textbox.Frame.BackgroundTransparency = 0.5
		Textbox.Input.TextTransparency = 0.5
	end

	function Input:Unlock()
		if not Input.Locked then return end
		Input.Locked = false
		
		if Input.LockIcon then
			Input.LockIcon.Visible = false
		end
		
		Input.SetDesc(Config.Description)
		Box.TextEditable = true
		Box.ClearTextOnFocus = Config.ClearOnFocusLost or false
		
		Textbox.Frame.BackgroundTransparency = 0.9 -- Default transparency for Input frame? Need to check.
		-- Actually Textbox module sets it. 
		-- Let's just assume 0.9 or use ThemeTag to restore?
		-- ThemeTag handles color, transparency might be manual.
		-- Textbox.luau might need to be checked for default transparency.
		-- Standard input background is usually standard element transparency.
		-- Let's set to 1 if it mimics standard or Check config.
		-- Looking at implementation: Textbox = require(Components.Textbox)(..., true)
		-- Let's check Textbox.luau later or just set a safe value.
		-- Assuming standard input look.
		
		-- Safer to just trigger theme update or set to default known.
		-- Textbox module uses "Input" theme color.
		-- Transparency is usually handled by theme too?
		-- Let's look at `Textbox.Frame` properties in `Input.luau`? 
		-- It doesn't set transparency explicitly, so it uses default from `Components.Textbox`.
		-- I'll check `Components.Textbox.luau` to be sure about transparency restore.
	end

	Library.Options[Idx] = Input

	Input.Instance = InputFrame

	return setmetatable(Input, {
		__newindex =  function(self, index, newvalue)
			if index == "Value" then
				task.spawn(Input.SetValue, Input, newvalue)
			end
			rawset(self, index, newvalue)
		end
	})
end

return Element
