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
		if self.DescLabel then self.DescLabel.Visible = false end
		
		if not self.LockOverlay then
			self.LockOverlay = New("Frame", {
				Size = UDim2.fromScale(1, 1),
				BackgroundColor3 = Color3.new(0, 0, 0),
				BackgroundTransparency = 0.6,
				ZIndex = 10,
				Parent = ButtonFrame.Frame,
			}, {
				New("UICorner", { CornerRadius = UDim.new(0, 8) })
			})
			
			self.LockIcon = New("ImageLabel", {
				Size = UDim2.fromOffset(20, 20),
				Position = UDim2.fromScale(0.5, 0.5),
				AnchorPoint = Vector2.new(0.5, 0.5),
				BackgroundTransparency = 1,
				Parent = self.LockOverlay,
				ZIndex = 11,
				ThemeTag = {
					ImageColor3 = "Text",
				},
			})
			self.Library.Utilities.Icons:SetIcon(self.LockIcon, "lock")
		end
		
		self.LockOverlay.Visible = true
	end

	function ButtonFrame:Unlock()
		if not self.Locked then return end
		self.Locked = false
		
		if self.LockOverlay then
			self.LockOverlay.Visible = false
		end
		
		if Config.Description and self.DescLabel then
			self.DescLabel.Visible = true
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
