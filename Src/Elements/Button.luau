local Root = script.Parent.Parent
local Creator = require(Root.Modules.Creator)
 
local New = Creator.New
local Components = Root.Components

local Element = {}
Element.__index = Element
Element.__type = "Button"

function Element:New(Config)
	assert(Config.Title, "Button - Missing Title")
	Config.Callback = Config.Callback or function() end

	local ButtonFrame = require(Components.Element)(Config.Title, Config.Description, self.Container, true)

	local ButtonIco = New("ImageLabel", {
		Size = UDim2.fromOffset(16, 16),
		AnchorPoint = Vector2.new(1, 0.5),
		Position = UDim2.new(1, -10, 0.5, 0),
		BackgroundTransparency = 1,
		Parent = ButtonFrame.Frame,
		ThemeTag = {
			ImageColor3 = "Text",
		}
	}) :: ImageLabel

	self.Library.Utilities.Icons:SetIcon(ButtonIco, "chevron-right")

	-- Lock Functionality
	function ButtonFrame:Lock(Reason)
		if self.Locked then return end
		self.Locked = true
		self.DescLabel.Visible = false
		
		if not self.LockIcon then
			self.LockIcon = New("ImageLabel", {
				Size = UDim2.fromOffset(16, 16),
				AnchorPoint = Vector2.new(1, 0.5),
				Position = UDim2.new(1, -30, 0.5, 0), -- Position to the left of chevron
				BackgroundTransparency = 1,
				Parent = ButtonFrame.Frame,
				Image = "rbxassetid://3926305904", -- Lock icon
				ImageColor3 = Color3.fromRGB(255, 255, 255),
				ImageTransparency = 0,
				ThemeTag = {
					ImageColor3 = "Text",
				}
			})
		end
		self.LockIcon.Visible = true
		
		ButtonFrame.Frame.BackgroundTransparency = 0.5 -- Dim the button
		ButtonFrame.TitleLabel.TextTransparency = 0.5
	end

	function ButtonFrame:Unlock()
		if not self.Locked then return end
		self.Locked = false
		
		if self.LockIcon then
			self.LockIcon.Visible = false
		end
		
		ButtonFrame.Frame.BackgroundTransparency = 0 -- Restore visuals
		ButtonFrame.TitleLabel.TextTransparency = 0
		if Config.Description then
			ButtonFrame.DescLabel.Visible = true
		end
	end

	Creator.AddSignal(ButtonFrame.Frame.MouseButton1Click, function()
		if ButtonFrame.Locked then return end
		if typeof(Config.Callback) == "function" then
			self.Library:SafeCallback(Config.Callback, Config.Value)
		end
	end)

	ButtonFrame.Instance = ButtonFrame

	return ButtonFrame
end

return Element
