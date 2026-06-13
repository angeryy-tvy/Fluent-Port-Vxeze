local Acrylic = {
	AcrylicBlur = require(script.AcrylicBlur),
	CreateAcrylic = require(script.CreateAcrylic),
	AcrylicPaint = require(script.AcrylicPaint),
}

function Acrylic.init()
	if getgenv().AcrylicController then
		return
	end

	local baseEffect = Instance.new("DepthOfFieldEffect")
	baseEffect.FarIntensity = 0
	baseEffect.InFocusRadius = 0.1
	baseEffect.NearIntensity = 1

	local depthOfFieldDefaults = {}

	-- Đăng ký bộ điều khiển Acrylic toàn cục
	getgenv().AcrylicController = {
		ActiveModels = {}
	}

	function getgenv().AcrylicController.Enable()
		for _, effect in next, depthOfFieldDefaults do
			effect.Enabled = false
		end
		baseEffect.Parent = game:GetService("Lighting")
	end

	function getgenv().AcrylicController.Disable()
		for _, effect in next, depthOfFieldDefaults do
			effect.Enabled = effect.enabled
		end
		baseEffect.Parent = nil
	end

	function getgenv().AcrylicController.Update()
		local count = 0
		for model, active in next, getgenv().AcrylicController.ActiveModels do
			if active then
				count = count + 1
			end
		end

		if count > 0 then
			getgenv().AcrylicController.Enable()
		else
			getgenv().AcrylicController.Disable()
		end
	end

	local function registerDefaults()
		local function register(object)
			if object:IsA("DepthOfFieldEffect") then
				depthOfFieldDefaults[object] = { enabled = object.Enabled }
			end
		end

		for _, child in next, game:GetService("Lighting"):GetChildren() do
			register(child)
		end

		if game:GetService("Workspace").CurrentCamera then
			for _, child in next, game:GetService("Workspace").CurrentCamera:GetChildren() do
				register(child)
			end
		end
	end

	registerDefaults()
	getgenv().AcrylicController.Enable()

	-- Để tương thích ngược với các thành phần cũ
	Acrylic.Enable = getgenv().AcrylicController.Enable
	Acrylic.Disable = getgenv().AcrylicController.Disable
end

return Acrylic
