if not LPH_OBFUSCATED then
	local function Pass(...)
		return ...
	end
	local function Nothing() end
	LPH_ENCSTR = Pass
	LPH_STRENC = Pass
	LPH_ENCNUM = Pass
	LPH_NUMENC = Pass
	LPH_CRASH = Nothing
	LPH_PRECHECK = function(check)
		check()
	end
	LPH_REWRITE = Pass
	LPH_ATTRIBUTES = Nothing
	ENCRYPT = Nothing
	VM = Nothing
	PRESET = Nothing
	OPTIMIZE = Nothing
	NO_UPVALUES = Nothing
	ERROR_HANDLING = Nothing
	UNROLL = Nothing
	INLINE = Nothing
	TRANSFORM = Nothing
	NONE = Nothing
	OPAL = Nothing
	ONYX = Nothing
	FAST = Nothing
	BALANCED = Nothing
	SECURE = Nothing
	EXTRACT = Nothing
	CONTROL_FLOW = Nothing
	REWRITE_NAMECALLS = Nothing
	GLOBALS = Nothing
	CONSTANTS = Nothing
end

local TweenService = game:GetService("TweenService")
local Players = game:GetService("Players")
local UserInputService = game:GetService("UserInputService")
local RunService = game:GetService("RunService")
local TextService = game:GetService("TextService")
local Lighting = game:GetService("Lighting")
local HttpService = game:GetService("HttpService")
local GuiService = game:GetService("GuiService")

local LocalPlayer = Players.LocalPlayer
local PlayerGui = LocalPlayer:WaitForChild("PlayerGui")

local IsMobileDevice = UserInputService.TouchEnabled and not UserInputService.MouseEnabled

local NullUI = {}
NullUI.__index = NullUI
NullUI.Version = "4.0.0"
NullUI.Flags = {}
NullUI._Windows = {}

local function GetGlobalTable()
	local ok, g = pcall(function()
		if getgenv then
			return getgenv()
		end
		return _G
	end)
	return (ok and g) or _G
end

do
	local globalTable = GetGlobalTable()
	local previousUnload = globalTable.__NullUI_Unload
	globalTable.__NullUI_Unload = nil
	if type(previousUnload) == "function" then
		pcall(previousUnload)
	end
end

local Janitor = {}
Janitor.__index = Janitor

function Janitor.new()
	return setmetatable({ _items = {}, _dead = false }, Janitor)
end

function Janitor:Add(item)
	if self._dead then
		if typeof(item) == "RBXScriptConnection" then
			item:Disconnect()
		elseif typeof(item) == "Instance" then
			item:Destroy()
		end
		return item
	end
	table.insert(self._items, item)
	return item
end

function Janitor:Destroy()
	if self._dead then
		return
	end
	self._dead = true
	for i = #self._items, 1, -1 do
		local item = self._items[i]
		self._items[i] = nil
		local t = typeof(item)
		if t == "RBXScriptConnection" then
			pcall(function()
				item:Disconnect()
			end)
		elseif t == "Instance" then
			pcall(function()
				item:Destroy()
			end)
		elseif t == "function" then
			pcall(item)
		elseif t == "table" and type(item.Destroy) == "function" then
			pcall(function()
				item:Destroy()
			end)
		elseif t == "table" and type(item.Disconnect) == "function" then
			pcall(function()
				item:Disconnect()
			end)
		end
	end
end

local IdentitySetter = (function()
	local ok, fn = pcall(function()
		local env = (getgenv and getgenv()) or _G or {}
		return env.setthreadidentity or env.set_thread_identity or env.setidentity
	end)
	if ok and type(fn) == "function" then
		return fn
	end
	return nil
end)()

local function RestoreIdentity()
	if IdentitySetter then
		pcall(IdentitySetter, 8)
	end
end

local function SafeSpawn(fn, ...)
	return task.spawn(function(...)
		RestoreIdentity()
		return fn(...)
	end, ...)
end

local function SafeDefer(fn, ...)
	return task.defer(function(...)
		RestoreIdentity()
		return fn(...)
	end, ...)
end

local function SafeDelay(seconds, fn, ...)
	return task.delay(seconds, function(...)
		RestoreIdentity()
		return fn(...)
	end, ...)
end

local LibJanitor = Janitor.new()

local function MakeSignal()
	local listeners = {}
	return {
		Fire = function(...)
			for _, fn in ipairs(table.clone(listeners)) do
				SafeSpawn(fn, ...)
			end
		end,
		Connect = function(fn)
			table.insert(listeners, fn)
			return {
				Disconnect = function()
					local i = table.find(listeners, fn)
					if i then
						table.remove(listeners, i)
					end
				end,
			}
		end,
		Clear = function()
			table.clear(listeners)
		end,
	}
end

local function SafeClamp(value, lo, hi)
	LPH_ATTRIBUTES(VM(NONE))
	if hi < lo then
		return lo
	end
	return math.clamp(value, lo, hi)
end

local function SafeAlpha(value, min, max)
	LPH_ATTRIBUTES(VM(NONE))
	local range = max - min
	if range == 0 then
		return 0
	end
	return math.clamp((value - min) / range, 0, 1)
end

local function SnapToIncrement(raw, min, max, increment)
	LPH_ATTRIBUTES(VM(NONE))
	if increment <= 0 then
		increment = 1
	end
	local snapped = math.floor((raw - min) / increment + 0.5) * increment + min
	snapped = math.clamp(snapped, min, max)
	local decimals = 0
	local probe = increment
	while decimals < 6 and math.abs(probe - math.floor(probe + 0.5)) > 1e-9 do
		probe = probe * 10
		decimals = decimals + 1
	end
	local factor = 10 ^ decimals
	return math.floor(snapped * factor + (snapped >= 0 and 0.5 or -0.5)) / factor
end

local function FormatNumber(v)
	LPH_ATTRIBUTES(VM(NONE))
	if math.abs(v - math.floor(v + 0.5)) < 1e-9 then
		return tostring(math.floor(v + 0.5))
	end
	return string.format("%.4g", v)
end

local ACRYLIC_DOF_NAME = "NullUI_AcrylicDOF"
local ACRYLIC_DISTANCE = 0.001
local ACRYLIC_TRANSPARENCY = 0.98
local AcrylicDOF = nil
local AcrylicControllers = {}
local CameraConnections = {}
local AcrylicShuttingDown = false

NullUI.Config = { Blur = true, MaxNotifications = 5, LiquidGlass = false }

local function DisconnectCameraSignals()
	for i = #CameraConnections, 1, -1 do
		CameraConnections[i]:Disconnect()
		CameraConnections[i] = nil
	end
end

local function EnsureAcrylicDOF()
	if AcrylicDOF and AcrylicDOF.Parent then
		return AcrylicDOF
	end
	local stale = Lighting:FindFirstChild(ACRYLIC_DOF_NAME)
	if stale then
		stale:Destroy()
	end

	local dof = Instance.new("DepthOfFieldEffect")
	dof.Name = ACRYLIC_DOF_NAME
	dof.FarIntensity = 0
	dof.FocusDistance = 0.05
	dof.InFocusRadius = 0.1
	dof.NearIntensity = 1
	dof.Enabled = false
	dof.Parent = Lighting
	AcrylicDOF = dof
	LibJanitor:Add(dof)
	return dof
end

local function RefreshAcrylicEffect()
	if AcrylicShuttingDown then
		return
	end
	local dof = EnsureAcrylicDOF()
	local active = false
	if NullUI.Config.Blur ~= false then
		for index = 1, #AcrylicControllers do
			if AcrylicControllers[index]._vis then
				active = true
				break
			end
		end
	end
	if dof.Enabled ~= active then
		dof.Enabled = active
	end
end

local function HasVisibleAcrylic()
	for index = 1, #AcrylicControllers do
		if AcrylicControllers[index]._vis then
			return true
		end
	end
	return false
end

local function UpdateAllAcrylic()
	for index = #AcrylicControllers, 1, -1 do
		local controller = AcrylicControllers[index]
		if controller.Destroyed then
			table.remove(AcrylicControllers, index)
		else
			controller:Update()
		end
	end
end

local ACRYLIC_RENDER_KEY = "NullUI_AcrylicFollow"
local AcrylicBound = false

local function UnbindAcrylicRender()
	if not AcrylicBound then
		return
	end
	AcrylicBound = false
	pcall(function()
		RunService:UnbindFromRenderStep(ACRYLIC_RENDER_KEY)
	end)
end

local function BindAcrylicRender()
	if AcrylicBound or AcrylicShuttingDown then
		return
	end
	AcrylicBound = true
	-- Runs right after the camera is updated so the glass panel lands on the same
	-- frame as the window instead of trailing one frame behind it.
	RunService:BindToRenderStep(ACRYLIC_RENDER_KEY, Enum.RenderPriority.Camera.Value + 1, function()
		if NullUI.Config.Blur == false or not HasVisibleAcrylic() then
			return
		end
		UpdateAllAcrylic()
	end)
end

local function BindAcrylicCamera(camera)
	DisconnectCameraSignals()
	if not camera then
		UnbindAcrylicRender()
		return
	end

	table.insert(CameraConnections, camera:GetPropertyChangedSignal("ViewportSize"):Connect(UpdateAllAcrylic))
	BindAcrylicRender()
	UpdateAllAcrylic()
end

local function CreateWindowAcrylic(guiObject)
	local folder = Instance.new("Folder")
	folder.Name = "NullUI_AcrylicWindow"

	local part = Instance.new("Part")
	part.Name = "Glass"
	part.Anchored = true
	part.CanCollide = false
	part.CanQuery = false
	part.CanTouch = false
	part.CastShadow = false
	part.Locked = true
	part.Material = Enum.Material.Glass
	part.Color = Color3.new(0, 0, 0)
	part.Reflectance = 0
	part.Size = Vector3.new(1, 1, 0.001)
	part.Transparency = 1
	part.Parent = folder

	local mesh = Instance.new("SpecialMesh")
	mesh.Name = "AcrylicMesh"
	mesh.MeshType = Enum.MeshType.Brick
	mesh.Offset = Vector3.new(0, 0, -0.000001)
	mesh.Scale = Vector3.new(1, 1, 0.001)
	mesh.Parent = part

	local controller = {
		Gui = guiObject,
		Folder = folder,
		Part = part,
		Mesh = mesh,
		Connections = {},
		Destroyed = false,
	}

	function controller:Update()
		if self.Destroyed then
			return
		end
		local camera = workspace.CurrentCamera
		local gui = self.Gui
		if not camera or not gui or not gui.Parent then
			if self._vis ~= false then
				self._vis = false
				self.Part.Transparency = 1
				RefreshAcrylicEffect()
			end
			return
		end

		if self.Folder.Parent ~= camera then
			self.Folder.Parent = camera
		end

		local size = gui.AbsoluteSize
		local visible = NullUI.Config.Blur ~= false and gui.Visible and size.X > 2 and size.Y > 2
		visible = visible and true or false
		if self._vis ~= visible then
			self._vis = visible
			self.Part.Transparency = visible and ACRYLIC_TRANSPARENCY or 1
			RefreshAcrylicEffect()
		end
		if not visible then
			return
		end

		-- Nothing moved since the last frame: skip the projection maths entirely.
		local camCF = camera:GetRenderCFrame()
		local pos = gui.AbsolutePosition
		local fov = camera.FieldOfView
		if self._cCF == camCF and self._cFov == fov and self._cPos == pos and self._cSize == size then
			return
		end
		self._cCF, self._cFov, self._cPos, self._cSize = camCF, fov, pos, size

		local edgeInset = math.clamp(camera.ViewportSize.Y * 0.012, 8, 18)
		local position = gui.AbsolutePosition + Vector2.new(edgeInset, edgeInset)
		local panelSize = Vector2.new(math.max(1, size.X - edgeInset * 2), math.max(1, size.Y - edgeInset * 2))

		local function ScreenToWorld(point)
			local ray = camera:ScreenPointToRay(point.X, point.Y)
			return ray.Origin + ray.Direction * ACRYLIC_DISTANCE
		end

		local topLeft3D = ScreenToWorld(position)
		local topRight3D = ScreenToWorld(position + Vector2.new(panelSize.X, 0))
		local bottomRight3D = ScreenToWorld(position + panelSize)
		local width = (topRight3D - topLeft3D).Magnitude
		local height = (bottomRight3D - topRight3D).Magnitude
		local renderCFrame = camCF

		self.Part.CFrame = CFrame.fromMatrix(
			(topLeft3D + bottomRight3D) / 2,
			renderCFrame.XVector,
			renderCFrame.YVector,
			renderCFrame.ZVector
		)
		self.Mesh.Scale = Vector3.new(width, height, 0.001)
	end

	function controller:Destroy()
		if self.Destroyed then
			return
		end
		self.Destroyed = true
		for _, connection in ipairs(self.Connections) do
			connection:Disconnect()
		end
		table.clear(self.Connections)
		local index = table.find(AcrylicControllers, self)
		if index then
			table.remove(AcrylicControllers, index)
		end
		if self.Folder then
			self.Folder:Destroy()
		end
		RefreshAcrylicEffect()
	end

	for _, property in ipairs({ "AbsolutePosition", "AbsoluteSize", "Visible" }) do
		table.insert(
			controller.Connections,
			guiObject:GetPropertyChangedSignal(property):Connect(function()
				controller:Update()
			end)
		)
	end
	table.insert(
		controller.Connections,
		guiObject.AncestryChanged:Connect(function()
			if not guiObject.Parent then
				controller:Destroy()
			end
		end)
	)

	table.insert(AcrylicControllers, controller)
	RefreshAcrylicEffect()
	controller:Update()
	return controller
end

BindAcrylicCamera(workspace.CurrentCamera)
LibJanitor:Add(workspace:GetPropertyChangedSignal("CurrentCamera"):Connect(function()
	BindAcrylicCamera(workspace.CurrentCamera)
end))
LibJanitor:Add(function()
	DisconnectCameraSignals()
end)

function NullUI:SetBlurEnabled(enabled)
	NullUI.Config.Blur = enabled and true or false
	RefreshAcrylicEffect()
	UpdateAllAcrylic()
end

local function StopAcrylicRender()
	UnbindAcrylicRender()
	DisconnectCameraSignals()
end

local function DestroyAllAcrylicControllers()
	StopAcrylicRender()
	for index = #AcrylicControllers, 1, -1 do
		AcrylicControllers[index]:Destroy()
	end
	table.clear(AcrylicControllers)
end

local ASSETS_FOLDER = "NullUI/Assets"

local function hasFn(name)
	local ok, fn = pcall(function()
		if getgenv then
			local v = getgenv()[name]
			if type(v) == "function" then
				return v
			end
		end
		if getfenv then
			local v = getfenv(1)[name]
			if type(v) == "function" then
				return v
			end
		end
		return _G[name]
	end)
	if ok and type(fn) == "function" then
		return fn
	end
	return nil
end

local fn_isfolder = hasFn("isfolder")
local fn_makefolder = hasFn("makefolder")
local fn_isfile = hasFn("isfile")
local fn_writefile = hasFn("writefile")
local fn_readfile = hasFn("readfile")
local fn_delfile = hasFn("delfile")
local fn_listfiles = hasFn("listfiles")
local fn_customasset = hasFn("getcustomasset") or hasFn("getsynasset")

local function EnsureAssetsFolder()
	if not (fn_isfolder and fn_makefolder) then
		return false
	end
	local ok = pcall(function()
		if not fn_isfolder("NullUI") then
			fn_makefolder("NullUI")
		end
		if not fn_isfolder(ASSETS_FOLDER) then
			fn_makefolder(ASSETS_FOLDER)
		end
	end)
	return ok
end

local RunCountPath = "NullUI/RunCount.txt"

local function BumpRunCount()
	local count = 1
	if fn_isfile and fn_readfile and fn_isfile(RunCountPath) then
		local ok, data = pcall(fn_readfile, RunCountPath)
		local n = ok and tonumber(data)
		if n then
			count = math.floor(n) + 1
		end
	end
	if fn_writefile then
		EnsureAssetsFolder()
		pcall(fn_writefile, RunCountPath, tostring(count))
	end
	return count
end

local function GetExecutorName()
	local ok, name, version = pcall(function()
		if identifyexecutor then
			return identifyexecutor()
		end
		if getexecutorname then
			return getexecutorname()
		end
		if syn and syn.get_executor_name then
			return syn.get_executor_name()
		end
		return nil
	end)
	if ok and name and name ~= "" then
		return version and version ~= "" and (tostring(name) .. " " .. tostring(version)) or tostring(name)
	end
	return "Unknown"
end

local function FormatClock(minutesAfterMidnight)
	minutesAfterMidnight = minutesAfterMidnight or 0
	local h = math.floor(minutesAfterMidnight / 60) % 24
	local m = math.floor(minutesAfterMidnight % 60)
	local suffix = h >= 12 and "PM" or "AM"
	local h12 = h % 12
	if h12 == 0 then
		h12 = 12
	end
	return string.format("%02d:%02d %s", h12, m, suffix)
end

local function LooksLikeFontFile(data)
	if type(data) ~= "string" or #data < 4096 then
		return false
	end
	local sig = data:sub(1, 4)
	return sig == "\0\1\0\0" or sig == "OTTO" or sig == "true" or sig == "ttcf" or sig == "wOFF" or sig == "wOF2"
end

local function DownloadFontFile(path, url)
	if not (fn_isfile and fn_writefile) then
		return false
	end

	local cached = nil
	if fn_isfile(path) and fn_readfile then
		local ok, data = pcall(fn_readfile, path)
		if ok and LooksLikeFontFile(data) then
			return true
		end
		cached = ok and data or nil
	end

	if cached ~= nil and fn_delfile then
		pcall(fn_delfile, path)
	end

	local ok, body = pcall(function()
		return game:HttpGet(url)
	end)
	if not ok or not LooksLikeFontFile(body) then
		return false
	end

	local wrote = pcall(fn_writefile, path, body)
	return wrote
end

local function LoadCustomFigtree()
	if not (fn_customasset and fn_writefile) then
		return nil
	end

	local okFolder = EnsureAssetsFolder()
	if not okFolder then
		return nil
	end

	local base = LPH_ENCSTR("https://raw.githubusercontent.com/Skinny-yz/NullUI-Assets/main/fonts/")
	local semiPath = ASSETS_FOLDER .. "/Figtree-SemiBold.ttf"
	local regPath = ASSETS_FOLDER .. "/Figtree-Medium.ttf"

	if not DownloadFontFile(semiPath, base .. "Figtree-SemiBold.ttf") then
		return nil
	end
	local hasRegular = DownloadFontFile(regPath, base .. "Figtree-Medium.ttf")
	if not hasRegular then
		regPath = semiPath
	end

	local result = nil
	pcall(function()
		local family = {
			name = "Figtree",
			faces = {
				{ name = "Regular", weight = 400, style = "normal", assetId = fn_customasset(regPath) },
				{ name = "SemiBold", weight = 600, style = "normal", assetId = fn_customasset(semiPath) },
			},
		}
		local familyPath = ASSETS_FOLDER .. "/Figtree.font"
		fn_writefile(familyPath, HttpService:JSONEncode(family))

		local asset = fn_customasset(familyPath)
		result = {
			Regular = Font.new(asset, Enum.FontWeight.Regular, Enum.FontStyle.Normal),
			SemiBold = Font.new(asset, Enum.FontWeight.SemiBold, Enum.FontStyle.Normal),
		}
	end)

	return result
end

local function LoadFonts()

	local custom = LoadCustomFigtree()
	if custom and custom.Regular and custom.SemiBold then
		return custom
	end

	local ok, native = pcall(function()
		return {
			Regular = Font.new(
				"rbxasset://fonts/families/Figtree.json",
				Enum.FontWeight.Regular,
				Enum.FontStyle.Normal
			),
			SemiBold = Font.new(
				"rbxasset://fonts/families/Figtree.json",
				Enum.FontWeight.SemiBold,
				Enum.FontStyle.Normal
			),
		}
	end)
	if ok and native then
		return native
	end

	return {
		Regular = Font.fromEnum(Enum.Font.Gotham),
		SemiBold = Font.fromEnum(Enum.Font.GothamSemibold),
	}
end

local Fonts = LoadFonts()

NullUI.Theme = {
	Background = Color3.fromRGB(16, 16, 16),
	Surface = Color3.fromRGB(24, 24, 24),
	Text = Color3.fromRGB(240, 240, 240),
	TextDim = Color3.fromRGB(150, 150, 155),
	Accent = Color3.fromRGB(255, 255, 255),
	Danger = Color3.fromRGB(205, 205, 210),

	Font = Fonts.SemiBold,
	FontRegular = Fonts.Regular,

	MeasureFont = Enum.Font.GothamSemibold,

	CornerRadius = 16,
	CornerRadiusSm = 8,
	Margin = 14,
	AnimFast = 0.15,
	AnimSlow = 0.32,
}

-- Base surfaces stay neutral; only the accent carries the colour, the way Fluent
-- ships one dark shell with a long list of accent choices.
local THEME_BASES = {
	Dark = {
		Background = Color3.fromRGB(16, 16, 16),
		Surface = Color3.fromRGB(24, 24, 24),
		Text = Color3.fromRGB(240, 240, 240),
		TextDim = Color3.fromRGB(150, 150, 155),
	},
	Darker = {
		Background = Color3.fromRGB(8, 8, 9),
		Surface = Color3.fromRGB(15, 15, 17),
		Text = Color3.fromRGB(236, 236, 240),
		TextDim = Color3.fromRGB(132, 132, 140),
	},
	Slate = {
		Background = Color3.fromRGB(18, 20, 25),
		Surface = Color3.fromRGB(26, 29, 36),
		Text = Color3.fromRGB(232, 236, 244),
		TextDim = Color3.fromRGB(140, 148, 162),
	},
}

local THEME_ACCENTS = {
	{ "Aqua", "Darker", Color3.fromRGB(0, 255, 255) },
	{ "Sky", "Darker", Color3.fromRGB(88, 166, 255) },
	{ "Ocean", "Slate", Color3.fromRGB(64, 200, 224) },
	{ "Midnight", "Slate", Color3.fromRGB(96, 150, 255) },
	{ "Indigo", "Darker", Color3.fromRGB(120, 130, 255) },
	{ "Amethyst", "Darker", Color3.fromRGB(176, 128, 255) },
	{ "Orchid", "Dark", Color3.fromRGB(214, 130, 255) },
	{ "Rose", "Darker", Color3.fromRGB(255, 118, 160) },
	{ "Sakura", "Dark", Color3.fromRGB(255, 160, 190) },
	{ "Crimson", "Darker", Color3.fromRGB(255, 92, 92) },
	{ "Ember", "Dark", Color3.fromRGB(255, 122, 66) },
	{ "Amber", "Darker", Color3.fromRGB(255, 176, 66) },
	{ "Gold", "Dark", Color3.fromRGB(240, 205, 96) },
	{ "Lime", "Darker", Color3.fromRGB(164, 230, 84) },
	{ "Emerald", "Darker", Color3.fromRGB(72, 217, 150) },
	{ "Mint", "Slate", Color3.fromRGB(128, 240, 200) },
	{ "Teal", "Slate", Color3.fromRGB(64, 210, 196) },
	{ "Coral", "Dark", Color3.fromRGB(255, 127, 110) },
	{ "Peach", "Dark", Color3.fromRGB(255, 184, 140) },
	{ "Tangerine", "Darker", Color3.fromRGB(255, 149, 0) },
	{ "Lemon", "Dark", Color3.fromRGB(248, 236, 96) },
	{ "Forest", "Slate", Color3.fromRGB(96, 200, 110) },
	{ "Jade", "Darker", Color3.fromRGB(0, 200, 140) },
	{ "Azure", "Slate", Color3.fromRGB(0, 160, 255) },
	{ "Cobalt", "Slate", Color3.fromRGB(70, 110, 255) },
	{ "Violet", "Darker", Color3.fromRGB(150, 90, 255) },
	{ "Magenta", "Darker", Color3.fromRGB(255, 70, 200) },
	{ "Ruby", "Darker", Color3.fromRGB(230, 40, 80) },
	{ "Ice", "Slate", Color3.fromRGB(190, 235, 255) },
	{ "Mono", "Dark", Color3.fromRGB(255, 255, 255) },
	{ "Graphite", "Darker", Color3.fromRGB(190, 195, 205) },
}

NullUI.Themes = {}

for _, entry in ipairs(THEME_ACCENTS) do
	local name, baseName, accent = entry[1], entry[2], entry[3]
	local base = THEME_BASES[baseName]
	-- Glass is the accent washed almost all the way to white so panels pick up a
	-- hint of the accent without turning the whole window into one colour.
	local glass = Color3.new(accent.R * 0.16 + 0.84, accent.G * 0.16 + 0.84, accent.B * 0.16 + 0.84)
	NullUI.Themes[name] = {
		Background = base.Background,
		Surface = base.Surface,
		Text = base.Text,
		TextDim = base.TextDim,
		Accent = accent,
		Glass = glass,
		Danger = Color3.fromRGB(235, 120, 120),
	}
end

for key, value in pairs(NullUI.Themes.Aqua) do
	NullUI.Theme[key] = value
end
NullUI.ThemeName = "Aqua"

local Z = {
	Glass = 0,
	Window = 1,
	Content = 2,
	Backdrop = 390,
	Popup = 400,
	PopupTop = 410,
	Toast = 600,
	Modal = 800,
	ModalTop = 810,
}

-- Motion tokens. Windows 11 uses short, decelerating moves for small elements and
-- slightly longer ones for surfaces; macOS adds a soft overshoot on entrances.
-- Every animation in the library pulls its timing from here so nothing feels
-- out of step with the rest of the interface.
local MOTION = {
	Instant = 0.08,
	Fast = 0.12,
	Normal = 0.18,
	Slow = 0.26,
	Surface = 0.32,
	Style = Enum.EasingStyle.Quint,
	Direction = Enum.EasingDirection.Out,
	EnterStyle = Enum.EasingStyle.Back,
	ExitStyle = Enum.EasingStyle.Quad,
}

-- Only one tween may own a property at a time. Without this, fast input stacks
-- competing tweens on the same instance and the motion visibly stutters.
local ActiveTweens = setmetatable({}, { __mode = "k" })

local function Tween(instance, props, duration, style, direction)
	LPH_ATTRIBUTES(VM(NONE))
	local owned = ActiveTweens[instance]
	if not owned then
		owned = {}
		ActiveTweens[instance] = owned
	end

	for property in pairs(props) do
		local previous = owned[property]
		if previous then
			if previous.PlaybackState == Enum.PlaybackState.Playing then
				pcall(previous.Cancel, previous)
			end
			owned[property] = nil
		end
	end

	local t = TweenService:Create(
		instance,
		TweenInfo.new(
			math.max(duration or 0.25, 0),
			style or Enum.EasingStyle.Quint,
			direction or Enum.EasingDirection.Out
		),
		props
	)

	for property in pairs(props) do
		owned[property] = t
	end

	t.Completed:Once(function()
		for property, tween in pairs(owned) do
			if tween == t then
				owned[property] = nil
			end
		end
	end)

	t:Play()
	return t
end

local THEME_KEYS = { "Background", "Surface", "Text", "TextDim", "Accent", "Glass", "Danger" }
local THEME_PROPS = {
	BackgroundColor3 = true,
	TextColor3 = true,
	PlaceholderColor3 = true,
	ImageColor3 = true,
	Color = true,
	TextStrokeColor3 = true,
}

-- Elements tagged with a role are repainted directly from the palette, so a theme
-- change never depends on guessing which colour an instance happened to hold.
local ROLE_ATTR = "NullUIRole"

local ApplyLiquidGlassRef
-- Registry of themed instances so a palette change touches only what it must
-- instead of walking the whole GUI tree twice.
local RoleRegistry = setmetatable({}, { __mode = "k" })
-- Exact property -> palette key, filled in by the first sweep so later theme
-- changes can repaint from the table instead of walking the tree again.
local PropRegistry = setmetatable({}, { __mode = "k" })
local TreeDirty = true

local function Role(instance, role)
	if instance then
		instance:SetAttribute(ROLE_ATTR, role)
		RoleRegistry[instance] = role
		-- Surfaces created while the effect is on pick it up immediately.
		if role == "Glass" and NullUI.Config.LiquidGlass and ApplyLiquidGlassRef then
			pcall(ApplyLiquidGlassRef, instance, true)
		end
	end
	return instance
end

local function PaintRole(instance, role)
	local color = NullUI.Theme[role]
	if not color then
		return
	end
	if instance:IsA("UIStroke") then
		instance.Color = color
	elseif instance:IsA("TextLabel") or instance:IsA("TextButton") or instance:IsA("TextBox") then
		instance.TextColor3 = color
	elseif instance:IsA("ImageLabel") or instance:IsA("ImageButton") then
		instance.ImageColor3 = color
	elseif instance:IsA("GuiObject") then
		instance.BackgroundColor3 = color
	end
end

local function SameColor(a, b)
	if typeof(a) ~= "Color3" or typeof(b) ~= "Color3" then
		return false
	end
	return math.abs(a.R - b.R) < 0.004 and math.abs(a.G - b.G) < 0.004 and math.abs(a.B - b.B) < 0.004
end

NullUI.ThemeChanged = MakeSignal()
NullUI.Unloaded = MakeSignal()

function NullUI:GetThemeNames()
	local names = {}
	for name in pairs(NullUI.Themes) do
		table.insert(names, name)
	end
	table.sort(names)
	return names
end

function NullUI:ApplyPalette(palette, instant)
	if type(palette) ~= "table" then
		return false, "palette must be a table"
	end

	local old = {}
	for _, key in ipairs(THEME_KEYS) do
		old[key] = NullUI.Theme[key]
	end

	local changed = {}
	for _, key in ipairs(THEME_KEYS) do
		local newColor = palette[key]
		if typeof(newColor) == "Color3" and not SameColor(newColor, old[key]) then
			table.insert(changed, { key = key, from = old[key], to = newColor })
			NullUI.Theme[key] = newColor
		end
	end

	if #changed == 0 then
		return true
	end

	local root = NullUI._Root
	if root then
		local duration = instant and 0 or 0.22
		local IMAGE_SAFE_KEYS = { Text = true, TextDim = true, Accent = true, Danger = true }

		-- Hash lookup instead of comparing against every changed key: a palette
		-- switch touches thousands of properties, so the inner loop has to be O(1).
		local changeMap = {}
		local function ColorKey(c)
			return math.round(c.R * 255) * 65536 + math.round(c.G * 255) * 256 + math.round(c.B * 255)
		end
		for _, entry in ipairs(changed) do
			changeMap[ColorKey(entry.from)] = entry
		end

		local IMAGE_SAFE_KEYS = { Text = true, TextDim = true, Accent = true, Danger = true }

		local function remap(inst, prop)
			local current = inst[prop]
			if typeof(current) ~= "Color3" then
				return
			end
			local entry = changeMap[ColorKey(current)]
			if not entry then
				return
			end
			if inst:GetAttribute("NullUINoTheme") then
				return
			end
			-- A tagged instance already knows its role. Guessing one from the
			-- colour would pick the wrong key whenever two palette entries share
			-- a colour, and that wrong guess would stick in PropRegistry.
			if RoleRegistry[inst] then
				return
			end

			local accentTagged = inst:GetAttribute("NullUIAccent") == true
				or (inst.Parent and inst.Parent:GetAttribute("NullUIAccent") == true)
			if entry.key == "Accent" and not accentTagged and prop ~= "ImageColor3" then
				return
			end
			if entry.key == "Glass" and accentTagged then
				return
			end
			if prop == "ImageColor3" then
				if not IMAGE_SAFE_KEYS[entry.key] then
					return
				end
				local image = tostring(inst.Image or "")
				if image == "" or string.find(image, "rbxthumb", 1, true) or string.find(image, "http", 1, true) then
					return
				end
			end

			-- Remember what this property maps to, so the next palette change can
			-- repaint straight from the table instead of walking the tree again.
			local props = PropRegistry[inst]
			if not props then
				props = {}
				PropRegistry[inst] = props
			end
			props[prop] = entry.key
			if duration <= 0 then
				inst[prop] = entry.to
			else
				Tween(inst, { [prop] = entry.to }, duration)
			end
		end
		-- Fast path: everything the library tagged, plus every property the first
		-- sweep already resolved, repaints straight from the palette.
		for inst, role in pairs(RoleRegistry) do
			if inst.Parent then
				PaintRole(inst, role)
			else
				RoleRegistry[inst] = nil
			end
		end

		for inst, props in pairs(PropRegistry) do
			if inst.Parent then
				for prop, key in pairs(props) do
					local color = NullUI.Theme[key]
					if color then
						if duration <= 0 then
							inst[prop] = color
						else
							Tween(inst, { [prop] = color }, duration)
						end
					end
				end
			else
				PropRegistry[inst] = nil
			end
		end

		-- Slow path runs only when the tree actually changed since the last pass.
		if TreeDirty then
			TreeDirty = false
			for _, inst in ipairs(root:GetDescendants()) do
				if not RoleRegistry[inst] and not PropRegistry[inst] then
					local role = inst:GetAttribute(ROLE_ATTR)
					if role then
						PaintRole(inst, role)
					elseif inst:IsA("TextLabel") or inst:IsA("TextButton") then
						remap(inst, "BackgroundColor3")
						remap(inst, "TextColor3")
					elseif inst:IsA("TextBox") then
						remap(inst, "BackgroundColor3")
						remap(inst, "TextColor3")
						remap(inst, "PlaceholderColor3")
					elseif inst:IsA("ImageLabel") or inst:IsA("ImageButton") then
						remap(inst, "BackgroundColor3")
						remap(inst, "ImageColor3")
					elseif inst:IsA("UIStroke") then
						remap(inst, "Color")
					elseif inst:IsA("GuiObject") then
						remap(inst, "BackgroundColor3")
					end
				end
			end
		end
	end

	NullUI.ThemeChanged.Fire(NullUI.Theme)
	return true
end

-- One source of truth for colour: the theme owns the base palette, and an
-- optional accent override survives theme switches until it is cleared.
NullUI.AccentOverride = nil

function NullUI:SetTheme(nameOrPalette, instant, keepAccent)
	local palette = nameOrPalette
	if type(nameOrPalette) == "string" then
		palette = NullUI.Themes[nameOrPalette]
		if not palette then
			return false, 'unknown theme "' .. nameOrPalette .. '"'
		end
		NullUI.ThemeName = nameOrPalette
	else
		NullUI.ThemeName = "Custom"
	end

	if keepAccent == false then
		NullUI.AccentOverride = nil
	end

	local ok, err = NullUI:ApplyPalette(palette, instant)
	if ok and NullUI.AccentOverride then
		NullUI:ApplyPalette({ Accent = NullUI.AccentOverride }, instant)
	end
	return ok, err
end

-- Drop the override and fall back to the accent that ships with the theme.
function NullUI:ResetAccent(instant)
	NullUI.AccentOverride = nil
	local palette = NullUI.Themes[NullUI.ThemeName]
	if not palette then
		return false, "current theme has no palette"
	end
	return NullUI:ApplyPalette({ Accent = palette.Accent }, instant)
end

function NullUI:GetThemeAccent(name)
	local palette = NullUI.Themes[name or NullUI.ThemeName]
	return palette and palette.Accent or NullUI.Theme.Accent
end

NullUI._Locks = {}

function NullUI:CreateLock(opts)
	opts = opts or {}
	local lock = {
		Name = opts.Name or "Lock",
		Reason = opts.Reason or "This feature is locked.",
		UnlockedReason = opts.UnlockedReason,
		_unlocked = opts.Unlocked == true,
		_listeners = {},
		_alive = true,
	}

	function lock:IsUnlocked()
		return self._unlocked
	end

	function lock:GetReason()
		return self._unlocked and (self.UnlockedReason or self.Name) or self.Reason
	end

	function lock:Subscribe(fn)
		if type(fn) ~= "function" then
			return { Disconnect = function() end }
		end
		table.insert(self._listeners, fn)
		local connection = {
			Disconnect = function()
				for index, listener in ipairs(lock._listeners) do
					if listener == fn then
						table.remove(lock._listeners, index)
						break
					end
				end
			end,
		}
		return connection
	end

	function lock:Set(unlocked, reason)
		unlocked = unlocked and true or false
		if reason then
			self.Reason = reason
		end
		if self._unlocked == unlocked then
			return self
		end
		self._unlocked = unlocked
		for _, fn in ipairs(table.clone(self._listeners)) do
			SafeSpawn(fn, unlocked, self:GetReason())
		end
		if opts.Notify ~= false then
			NullUI:Notify({
				Title = self.Name,
				Text = unlocked and (self.UnlockedReason or "Unlocked.") or self.Reason,
				Type = unlocked and "success" or "warning",
				Icon = unlocked and "lock-open" or "lock",
				Duration = 3,
			})
		end
		return self
	end

	function lock:Unlock(reason)
		return self:Set(true, reason)
	end

	function lock:Lock(reason)
		return self:Set(false, reason)
	end

	function lock:Try(input)
		if type(opts.Unlocker) == "function" then
			local ok, reason = opts.Unlocker(input)
			if ok then
				self:Unlock()
				return true
			end
			return false, reason or self.Reason
		end
		if opts.Key ~= nil then
			if tostring(input) == tostring(opts.Key) then
				self:Unlock()
				return true
			end
			return false, opts.WrongKeyReason or "Wrong key."
		end
		return false, self.Reason
	end

	function lock:Destroy()
		self._alive = false
		table.clear(self._listeners)
	end

	if type(opts.Check) == "function" then
		local interval = math.max(tonumber(opts.Interval) or 2, 0.25)
		SafeSpawn(function()
			while lock._alive do
				local ok, unlocked, reason = pcall(opts.Check)
				if ok then
					lock:Set(unlocked and true or false, type(reason) == "string" and reason or nil)
				end
				task.wait(interval)
			end
		end)
	end

	NullUI._Locks[lock.Name] = lock
	return lock
end

function NullUI:GetLock(name)
	return NullUI._Locks[name]
end

function NullUI:SetAccent(color, instant)
	if typeof(color) ~= "Color3" then
		return false, "accent must be a Color3"
	end
	NullUI.AccentOverride = color
	return NullUI:ApplyPalette({ Accent = color }, instant)
end

local function Corner(parent, radius)
	LPH_ATTRIBUTES(VM(NONE))
	local c = Instance.new("UICorner")
	c.CornerRadius = UDim.new(0, radius or NullUI.Theme.CornerRadius)
	c.Parent = parent
	return c
end

local function Stroke(parent, color, thickness, transparency)
	local s = Instance.new("UIStroke")
	s.Color = color or Color3.new(1, 1, 1)
	s.Thickness = thickness or 1
	s.Transparency = transparency or 0.9
	s.ApplyStrokeMode = Enum.ApplyStrokeMode.Border
	s.Parent = parent
	return s
end

local LiquidGlassLayers = setmetatable({}, { __mode = "k" })

-- Windows 11 Mica / macOS material: a barely-there lift in translucency plus a
-- single soft highlight along the top edge. No colour wash, no specular streaks
-- on every card -- those read as dirt at small sizes.
local function ApplyLiquidGlass(surface, enabled)
	local sheen = surface:FindFirstChild("LiquidSheen")
	local rim = surface:FindFirstChild("LiquidRim")
	local streak = surface:FindFirstChild("LiquidStreak")

	local base = surface:GetAttribute("BaseTransparency")
	if base == nil then
		base = surface.BackgroundTransparency
		surface:SetAttribute("BaseTransparency", base)
	end

	if not enabled then
		if sheen then
			sheen.Enabled = false
		end
		if rim then
			rim.Enabled = false
		end
		if streak then
			streak.Visible = false
		end
		surface.BackgroundColor3 = Color3.new(1, 1, 1)
		surface.BackgroundTransparency = base
		return
	end

	-- Large surfaces (window, flyouts, panels) can carry a touch more material;
	-- small rows only get a whisper so text stays crisp.
	local height = surface.AbsoluteSize.Y
	local isLarge = height >= 90 or base <= 0.9

	surface.BackgroundColor3 = Color3.new(1, 1, 1)
	surface.BackgroundTransparency = math.clamp(base - (isLarge and 0.05 or 0.015), 0.78, 0.995)

	if not sheen then
		sheen = Instance.new("UIGradient")
		sheen.Name = "LiquidSheen"
		sheen.Rotation = 90
		sheen.Parent = surface
	end
	sheen.Color = ColorSequence.new(Color3.new(1, 1, 1))
	sheen.Transparency = NumberSequence.new({
		NumberSequenceKeypoint.new(0, isLarge and 0.35 or 0.55),
		NumberSequenceKeypoint.new(0.45, 0.88),
		NumberSequenceKeypoint.new(1, 1),
	})
	sheen.Enabled = true

	if isLarge then
		if not streak then
			streak = Instance.new("Frame")
			streak.Name = "LiquidStreak"
			streak.BackgroundColor3 = Color3.fromRGB(255, 255, 255)
			streak.BorderSizePixel = 0
			streak.AnchorPoint = Vector2.new(0.5, 0)
			streak.Position = UDim2.new(0.5, 0, 0, 0)
			streak.Size = UDim2.new(1, -24, 0, 1)
			streak.ZIndex = surface.ZIndex + 1
			streak.Parent = surface

			local streakGradient = Instance.new("UIGradient")
			streakGradient.Transparency = NumberSequence.new({
				NumberSequenceKeypoint.new(0, 1),
				NumberSequenceKeypoint.new(0.5, 0.45),
				NumberSequenceKeypoint.new(1, 1),
			})
			streakGradient.Parent = streak
		end
		streak.BackgroundTransparency = 0.72
		streak.Visible = true
	elseif streak then
		streak.Visible = false
	end

	if rim then
		rim.Enabled = false
	end
end
local function GlassLayer(parent, radius, transparency)
	local glass = Instance.new("Frame")
	glass.Name = "Glass"
	glass.Size = UDim2.fromScale(1, 1)
	glass.BackgroundColor3 = Color3.new(1, 1, 1)
	glass.BackgroundTransparency = transparency or 0.985
	glass.BorderSizePixel = 0
	glass.ZIndex = Z.Glass
	glass.Parent = parent
	Role(glass, "Glass")
	Corner(glass, radius)
	LiquidGlassLayers[glass] = true
	if NullUI.Config.LiquidGlass then
		ApplyLiquidGlass(glass, true)
	end
	return glass
end

-- Every surface that carries the Glass role takes the treatment, not just the
-- handful of dedicated GlassLayer frames: cards, panels, popups and the window.
ApplyLiquidGlassRef = ApplyLiquidGlass

function NullUI:SetLiquidGlass(enabled)
	enabled = enabled and true or false
	NullUI.Config.LiquidGlass = enabled

	local seen = {}
	for glass in pairs(LiquidGlassLayers) do
		if glass.Parent then
			seen[glass] = true
			pcall(ApplyLiquidGlass, glass, enabled)
		else
			LiquidGlassLayers[glass] = nil
		end
	end

	local root = NullUI._Root
	if root then
		for _, inst in ipairs(root:GetDescendants()) do
			if not seen[inst] and inst:IsA("GuiObject") and inst:GetAttribute(ROLE_ATTR) == "Glass" then
				pcall(ApplyLiquidGlass, inst, enabled)
			end
		end
	end
	return true
end

local function AddScrollbar(scroll)
	scroll.ScrollBarThickness = 0
	scroll.ScrollBarImageTransparency = 1
	scroll.VerticalScrollBarInset = Enum.ScrollBarInset.None
	scroll.HorizontalScrollBarInset = Enum.ScrollBarInset.None
end

local function AddContentScrollThumb(scroll, listLayout, thumbParent, janitor)
	local thumb = Instance.new("Frame")
	thumb.Name = "ContentScrollThumb"
	thumb.BackgroundColor3 = NullUI.Theme.TextDim
	-- Invisible while idle, like macOS / Win11: it only materialises while the
	-- content is actually moving and melts away again a moment later.
	thumb.BackgroundTransparency = 1
	thumb.BorderSizePixel = 0
	thumb.AnchorPoint = Vector2.new(1, 0)
	thumb.Size = UDim2.new(0, 3, 0, 40)
	thumb.Visible = false
	thumb.ZIndex = (scroll.ZIndex or 0) + 6
	thumb.Parent = thumbParent
	Corner(thumb, 2)
	Role(thumb, "TextDim")

	-- Scrollbars stay completely invisible: the content scrolls, nothing draws on
	-- top of it. The thumb instance is kept only so layout maths stay identical.
	local function flashThumb() end

	local MARGIN = 4

	local function refreshThumb()
		LPH_ATTRIBUTES(VM(NONE))
		if not thumbParent.Visible then
			thumb.Visible = false
			return
		end
		local windowH = scroll.AbsoluteWindowSize.Y
		local canvasH = scroll.AbsoluteCanvasSize.Y
		local overflow = canvasH - windowH
		if overflow <= 8 or windowH <= 0 then
			thumb.Visible = false
			return
		end
		local trackH = windowH - MARGIN * 2
		if trackH <= 0 then
			thumb.Visible = false
			return
		end
		local parentPos, parentSize = thumbParent.AbsolutePosition, thumbParent.AbsoluteSize
		if parentSize.X <= 0 or parentSize.Y <= 0 then
			thumb.Visible = false
			return
		end
		local thumbH = math.min(trackH, math.max(30, trackH * (windowH / canvasH)))
		local maxThumbY = trackH - thumbH
		local ratio = math.clamp(scroll.CanvasPosition.Y / overflow, 0, 1)
		local topY = (scroll.AbsolutePosition.Y - parentPos.Y) + MARGIN + maxThumbY * ratio
		local rightX = (scroll.AbsolutePosition.X + scroll.AbsoluteSize.X) - parentPos.X - MARGIN
		thumb.Visible = false
		thumb.Size = UDim2.new(0, 3, thumbH / parentSize.Y, 0)
		thumb.Position = UDim2.new(rightX / parentSize.X, 0, topY / parentSize.Y, 0)
	end

	local queued = false
	local function queueRefresh()
		if queued then
			return
		end
		queued = true
		SafeDefer(function()
			queued = false
			if thumb.Parent then
				refreshThumb()
			end
		end)
	end

	janitor:Add(scroll:GetPropertyChangedSignal("CanvasPosition"):Connect(function()
		queueRefresh()
		flashThumb()
	end))
	janitor:Add(scroll:GetPropertyChangedSignal("AbsoluteCanvasSize"):Connect(queueRefresh))
	janitor:Add(scroll:GetPropertyChangedSignal("AbsoluteWindowSize"):Connect(queueRefresh))
	janitor:Add(scroll:GetPropertyChangedSignal("AbsolutePosition"):Connect(queueRefresh))
	janitor:Add(thumbParent:GetPropertyChangedSignal("AbsoluteSize"):Connect(queueRefresh))
	janitor:Add(thumbParent:GetPropertyChangedSignal("Visible"):Connect(queueRefresh))
	queueRefresh()

	return thumb
end

local MEASURE_FUDGE = 1.06
local MeasureCache = {}

local function MeasureText(text, size, maxWidth)
	LPH_ATTRIBUTES(VM(NONE))
	text = tostring(text or "")
	maxWidth = maxWidth or 10000
	local key = text .. "\1" .. size .. "\1" .. math.floor(maxWidth)
	local cached = MeasureCache[key]
	if cached then
		return cached.X, cached.Y
	end

	local ok, bounds = pcall(function()
		return TextService:GetTextSize(text, size, NullUI.Theme.MeasureFont, Vector2.new(maxWidth, 100000))
	end)
	local w, h
	if ok and bounds then
		w = math.ceil(bounds.X * MEASURE_FUDGE)
		h = math.ceil(bounds.Y)
	else
		w = math.ceil(#text * size * 0.55)
		h = size + 2
	end
	MeasureCache[key] = Vector2.new(w, h)
	return w, h
end

local IconSources = {
	Material = LPH_ENCSTR("https://raw.githubusercontent.com/Skinny-yz/NullUI-Assets/main/icons/MaterialIcons.luau"),
	Lucide = LPH_ENCSTR("https://raw.githubusercontent.com/Skinny-yz/NullUI-Assets/main/icons/LucideIcons.luau"),
	Phosphor = LPH_ENCSTR("https://raw.githubusercontent.com/Skinny-yz/NullUI-Assets/main/icons/Phosphor.luau"),
	["Phosphor-Filled"] = LPH_ENCSTR(
		"https://raw.githubusercontent.com/Skinny-yz/NullUI-Assets/main/icons/Phosphor%20Filled.luau"
	),
	SF = LPH_ENCSTR("https://raw.githubusercontent.com/Skinny-yz/NullUI-Assets/main/icons/SFSymbols.luau"),
}

local IconCache = {}
local IconLoading = {}

local function LoadIconSource(source)
	if IconCache[source] ~= nil then
		return IconCache[source] or nil
	end

	if IconLoading[source] then
		local t0 = os.clock()
		while IconLoading[source] and os.clock() - t0 < 10 do
			task.wait()
		end
		return IconCache[source] or nil
	end

	local url = IconSources[source]
	if not url then
		IconCache[source] = false
		return nil
	end

	IconLoading[source] = true
	local ok, data = pcall(function()
		return loadstring(game:HttpGet(url))()
	end)
	IconLoading[source] = nil

	if ok and type(data) == "table" then
		IconCache[source] = data
		return data
	end

	IconCache[source] = false
	return nil
end

function NullUI:GetIcon(name, source)
	source = source or "Lucide"
	local set = LoadIconSource(source)
	local iconId = set and set[name]
	if not iconId then
		return ""
	end
	return "rbxassetid://" .. tostring(iconId)
end

local function ResolveIcon(icon)
	if icon == nil or icon == "" then
		return ""
	end
	if type(icon) ~= "string" then
		return icon
	end
	if icon:match("^%a[%w%+%-%.]*://") then
		return icon
	end
	if icon:match("^%d+$") then
		return "rbxassetid://" .. icon
	end
	local source, name = icon:match("^(%a[%w%-]*):(.+)$")
	if source and name then
		return NullUI:GetIcon(name, source)
	end
	return NullUI:GetIcon(icon, "Lucide")
end

function NullUI:PreloadIcons(sources)
	for _, src in ipairs(sources or { "Lucide" }) do
		SafeSpawn(LoadIconSource, src)
	end
end

NullUI.RestoreIdentity = RestoreIdentity

local function GetRoot()
	RestoreIdentity()

	local parent = PlayerGui
	if NullUI.UseHiddenGui then
		local hidden = hasFn("gethui")
		if hidden then
			local ok, container = pcall(hidden)
			if ok and container then
				parent = container
			end
		end
	end

	local stale = parent:FindFirstChild("NullUI")
	if stale then
		pcall(function()
			stale:Destroy()
		end)
	end

	local screenGui = Instance.new("ScreenGui")
	screenGui.Name = "NullUI"
	screenGui.ResetOnSpawn = false
	screenGui.IgnoreGuiInset = false
	screenGui.DisplayOrder = 9999
	screenGui.ZIndexBehavior = Enum.ZIndexBehavior.Sibling

	local ok = pcall(function()
		screenGui.Parent = parent
	end)
	if not ok or not screenGui.Parent then
		screenGui.Parent = PlayerGui
	end

	local protect = hasFn("protect_gui") or hasFn("protectgui")
	if protect and screenGui.Parent ~= PlayerGui then
		pcall(protect, screenGui)
	end

	return screenGui
end

NullUI._Root = GetRoot()

local function ViewportSize()
	LPH_ATTRIBUTES(VM(NONE))
	local root = NullUI._Root
	if root and root.AbsoluteSize.X > 0 then
		return root.AbsoluteSize
	end
	local cam = workspace.CurrentCamera
	return cam and cam.ViewportSize or Vector2.new(1280, 720)
end

-- Desktop sits a touch above Fluent's 1:1: the element metrics match it, and the
-- extra tenth keeps the small text readable without the whole window ballooning
-- the way a 1.35 cap did. Phones still scale up, they need the reach.
local UI_SCALE_BASELINE = IsMobileDevice and 380 or 880
local UI_SCALE_MIN = IsMobileDevice and 1.0 or 0.85
local UI_SCALE_MAX = IsMobileDevice and 1.5 or 1.25

-- Auto mode measures the screen itself: a small game window shrinks the whole UI and a
-- maximised or 4K one grows it, instead of staying stuck at the size it opened with.
local AutoScale = false
local AUTO_SCALE_MIN = IsMobileDevice and 0.9 or 0.65
local AUTO_SCALE_MAX = IsMobileDevice and 1.5 or 1.6

local function ComputeUIScale()
	if AutoScale then
		local base = ViewportSize().Y / UI_SCALE_BASELINE
		-- A full-screen window has room to spare, so the controls grow with it instead of
		-- floating tiny in the middle of a huge panel.
		if not IsMobileDevice then
			for _, window in ipairs(NullUI._Windows or {}) do
				if window._fullscreen and window._state ~= "closed" then
					-- zoom with the window: the full-tab panel is 0.94 x 0.9 of the screen, so the
					-- scale follows how much bigger it is than the 640 x 430 reference panel
					local view = ViewportSize()
					local fit = math.min(view.X * 0.94 / 640, view.Y * 0.9 / 430)
					base = math.max(base, math.min(fit, 1.7))
					break
				end
			end
		end
		return SafeClamp(base, AUTO_SCALE_MIN, AUTO_SCALE_MAX)
	end
	return SafeClamp(ViewportSize().Y / UI_SCALE_BASELINE, UI_SCALE_MIN, UI_SCALE_MAX)
end

local GlobalScale = Instance.new("UIScale")
GlobalScale.Name = "GlobalScale"
GlobalScale.Scale = ComputeUIScale()
GlobalScale.Parent = NullUI._Root

-- Any new UI means the untagged sweep has to run once more.
NullUI._Root.DescendantAdded:Connect(function()
	TreeDirty = true
end)

local function GetUIScale()
	LPH_ATTRIBUTES(VM(NONE))
	return GlobalScale.Scale
end

local UserScaleMultiplier = 1
local ScaleTween

local RefitAllWindows = function() end

local function RefreshUIScale(instant)
	local target = SafeClamp(ComputeUIScale() * (AutoScale and 1 or UserScaleMultiplier), 0.4, 3)
	if math.abs(GlobalScale.Scale - target) < 0.001 then
		return
	end
	if ScaleTween then
		pcall(function()
			ScaleTween:Cancel()
		end)
		ScaleTween = nil
	end
	if instant then
		GlobalScale.Scale = target
		return
	end
	-- Tweening keeps the relayout spread over a short window instead of snapping
	-- the whole tree on every slider tick.
	ScaleTween = TweenService:Create(
		GlobalScale,
		TweenInfo.new(0.12, Enum.EasingStyle.Sine, Enum.EasingDirection.Out),
		{ Scale = target }
	)
	ScaleTween:Play()
end

-- Resizing the game window fires ViewportSize for every pixel; wait for it to settle so
-- the tree is only rescaled and the windows refitted once.
local ViewportToken = 0
local function OnViewportChanged()
	ViewportToken += 1
	local token = ViewportToken
	SafeDelay(0.25, function()
		if token ~= ViewportToken then
			return
		end
		RefreshUIScale()
		SafeDelay(0.16, RefitAllWindows)
	end)
end

local function WatchCamera(cam)
	if not cam then
		return
	end
	LibJanitor:Add(cam:GetPropertyChangedSignal("ViewportSize"):Connect(OnViewportChanged))
end

WatchCamera(workspace.CurrentCamera)
LibJanitor:Add(workspace:GetPropertyChangedSignal("CurrentCamera"):Connect(function()
	WatchCamera(workspace.CurrentCamera)
	OnViewportChanged()
end))
if NullUI._Root then
	LibJanitor:Add(NullUI._Root:GetPropertyChangedSignal("AbsoluteSize"):Connect(OnViewportChanged))
end

function NullUI:SetScaleRange(minScale, maxScale)
	UI_SCALE_MIN = minScale or UI_SCALE_MIN
	UI_SCALE_MAX = maxScale or UI_SCALE_MAX
	RefreshUIScale()
end

function NullUI:SetUIScale(multiplier, instant)
	local value = tonumber(multiplier)
	if not value then
		return false, "scale must be a number"
	end
	UserScaleMultiplier = SafeClamp(value, 0.5, 2)
	RefreshUIScale(instant)
	return true
end

function NullUI:GetUIScaleMultiplier()
	return UserScaleMultiplier
end

function NullUI:SetAutoScale(enabled)
	AutoScale = enabled ~= false
	RefreshUIScale()
	SafeDelay(0.16, RefitAllWindows)
	return AutoScale
end

function NullUI:GetAutoScale()
	return AutoScale
end

local ActivePopupClose = nil

local function RegisterPopupOpen(closeFn)
	if ActivePopupClose and ActivePopupClose ~= closeFn then
		local previous = ActivePopupClose
		ActivePopupClose = nil
		previous()
	end
	ActivePopupClose = closeFn
end

local function RegisterPopupClose(closeFn)
	if ActivePopupClose == closeFn then
		ActivePopupClose = nil
	end
end

local function CloseAnyOpenPopup()
	if ActivePopupClose then
		local fn = ActivePopupClose
		ActivePopupClose = nil
		fn()
	end
end

local function MakePopupBackdrop(onClose)
	local backdrop = Instance.new("TextButton")
	backdrop.Name = "PopupBackdrop"
	backdrop.Text = ""
	backdrop.AutoButtonColor = false
	backdrop.BackgroundTransparency = 1
	backdrop.BorderSizePixel = 0
	backdrop.Size = UDim2.fromScale(1, 1)
	backdrop.ZIndex = Z.Backdrop
	backdrop.Parent = NullUI._Root
	backdrop.InputBegan:Connect(function(input)
		if
			input.UserInputType == Enum.UserInputType.MouseButton1
			or input.UserInputType == Enum.UserInputType.Touch
		then
			onClose()
		end
	end)
	return backdrop
end

LibJanitor:Add(UserInputService.InputBegan:Connect(function(input, gameProcessed)
	if gameProcessed then
		return
	end
	if input.KeyCode == Enum.KeyCode.Escape and ActivePopupClose then
		CloseAnyOpenPopup()
	end
end))

local KeybindCapturing = false

local NotificationQueue = {}

local function GetNotifyHolder()
	local root = NullUI._Root
	local holder = root:FindFirstChild("NotificationHolder")
	if holder then
		return holder
	end

	holder = Instance.new("Frame")
	holder.Name = "NotificationHolder"
	holder.AnchorPoint = Vector2.new(1, 1)
	holder.Position = UDim2.new(1, -20, 1, -20)
	holder.Size = UDim2.new(0, 280, 1, -40)
	holder.BackgroundTransparency = 1
	holder.ZIndex = Z.Toast
	holder.Parent = root

	local layout = Instance.new("UIListLayout")
	layout.SortOrder = Enum.SortOrder.LayoutOrder
	layout.VerticalAlignment = Enum.VerticalAlignment.Bottom
	layout.HorizontalAlignment = Enum.HorizontalAlignment.Right
	layout.Padding = UDim.new(0, 10)
	layout.Parent = holder
	holder.ClipsDescendants = true

	local function pumpToasts()
		LPH_ATTRIBUTES(VM(NONE))
		if not holder.Parent then
			return
		end
		local s = GetUIScale()
		local view = ViewportSize()
		holder.Size = UDim2.fromOffset(math.max(1, math.min(280, view.X / s - 40)), math.max(1, view.Y / s - 40))
		local used, count = 0, 0
		local function fullHeight(card)
			local anim = card:FindFirstChildOfClass("UIScale")
			return card.AbsoluteSize.Y / (anim and math.max(anim.Scale, 0.01) or 1)
		end
		for _, child in ipairs(holder:GetChildren()) do
			if child:IsA("GuiObject") and child.Visible then
				used += fullHeight(child) + (count > 0 and 10 * s or 0)
				count += 1
			end
		end
		while #NotificationQueue > 0 do
			local entry = NotificationQueue[1]
			if not entry.Card.Parent then
				table.remove(NotificationQueue, 1)
			else
				local h = fullHeight(entry.Card)
				if h <= 0 then
					break
				end
				local needed = h + (count > 0 and 10 * s or 0)
				if used + needed > holder.AbsoluteSize.Y then
					break
				end
				table.remove(NotificationQueue, 1)
				entry.Start()
				used += needed
				count += 1
			end
		end
	end

	local toastAlive = true
	LibJanitor:Add(function()
		toastAlive = false
	end)
	SafeSpawn(function()
		while toastAlive do
			pumpToasts()
			task.wait(#NotificationQueue > 0 and 0.05 or 0.25)
		end
	end)
	LibJanitor:Add(workspace.CurrentCamera:GetPropertyChangedSignal("ViewportSize"):Connect(pumpToasts))

	return holder
end

NullUI._NotifyCounter = 0

local NotifyIcons = {
	info = "info",
	success = "check",
	warning = "triangle-alert",
	error = "circle-x",
}

local NotifyColors = {
	info = Color3.fromRGB(120, 170, 255),
	success = Color3.fromRGB(110, 220, 140),
	warning = Color3.fromRGB(255, 190, 90),
	error = Color3.fromRGB(255, 105, 105),
}

function NullUI:Notify(opts)
	opts = opts or {}
	local title = opts.Title or "Notification"
	local text = opts.Text or ""
	local duration = opts.Duration or 4
	local notifyType = opts.Type or "info"
	local color = opts.Color or NotifyColors[notifyType] or NullUI.Theme.Accent
	local iconName = opts.Icon or NotifyIcons[notifyType] or NotifyIcons.info

	local holder = GetNotifyHolder()
	NullUI._NotifyCounter = NullUI._NotifyCounter + 1

	local dismiss

	local card = Instance.new("Frame")
	card.Name = "Notification"
	card.BackgroundColor3 = NullUI.Theme.Surface
	card.BackgroundTransparency = 1
	card.BorderSizePixel = 0
	card.ClipsDescendants = true
	card.AutomaticSize = Enum.AutomaticSize.Y
	card.Size = UDim2.new(1, 0, 0, 0)
	card.LayoutOrder = NullUI._NotifyCounter
	card.ZIndex = Z.Toast
	card.Visible = false
	card.Parent = holder
	Corner(card, 12)
	local stroke = Stroke(card, Color3.new(1, 1, 1), 1, 1)
	local notificationAcrylic = nil
	local scale = Instance.new("UIScale")
	scale.Scale = 0.88
	scale.Parent = card

	local padding = Instance.new("UIPadding")
	padding.PaddingTop = UDim.new(0, 10)
	padding.PaddingBottom = UDim.new(0, 10)
	padding.PaddingLeft = UDim.new(0, 10)
	padding.PaddingRight = UDim.new(0, 10)
	padding.Parent = card

	local layout = Instance.new("UIListLayout")
	layout.Padding = UDim.new(0, 6)
	layout.SortOrder = Enum.SortOrder.LayoutOrder
	layout.Parent = card

	local headerRow = Instance.new("Frame")
	headerRow.BackgroundTransparency = 1
	headerRow.AutomaticSize = Enum.AutomaticSize.XY
	headerRow.Size = UDim2.new(0, 0, 0, 0)
	headerRow.LayoutOrder = 1
	headerRow.ZIndex = Z.Toast + 1
	headerRow.Parent = card

	local headerLayout = Instance.new("UIListLayout")
	headerLayout.FillDirection = Enum.FillDirection.Horizontal
	headerLayout.VerticalAlignment = Enum.VerticalAlignment.Center
	headerLayout.Padding = UDim.new(0, 7)
	headerLayout.SortOrder = Enum.SortOrder.LayoutOrder
	headerLayout.Parent = headerRow

	local icon = Instance.new("ImageLabel")
	icon.BackgroundTransparency = 1
	icon.Image = ResolveIcon(iconName)
	icon.ImageColor3 = color
	icon.ImageTransparency = 1
	icon.Size = UDim2.fromOffset(14, 14)
	icon.LayoutOrder = 1
	icon.ZIndex = Z.Toast + 1
	icon.Parent = headerRow

	local titleLabel = Instance.new("TextLabel")
	titleLabel.BackgroundTransparency = 1
	titleLabel.FontFace = NullUI.Theme.Font
	titleLabel.Text = title
	titleLabel.TextColor3 = NullUI.Theme.Text
	Role(titleLabel, "Text")
	titleLabel.TextTransparency = 1
	titleLabel.TextSize = 14
	titleLabel.TextXAlignment = Enum.TextXAlignment.Left
	titleLabel.AutomaticSize = Enum.AutomaticSize.XY
	titleLabel.Size = UDim2.fromOffset(0, 14)
	titleLabel.LayoutOrder = 2
	titleLabel.ZIndex = Z.Toast + 1
	titleLabel.Parent = headerRow

	local textLabel
	if text ~= "" then
		textLabel = Instance.new("TextLabel")
		textLabel.BackgroundTransparency = 1
		textLabel.FontFace = NullUI.Theme.FontRegular
		textLabel.Text = text
		textLabel.TextColor3 = NullUI.Theme.TextDim
		Role(textLabel, "TextDim")
		textLabel.TextTransparency = 1
		textLabel.TextSize = 12
		textLabel.TextWrapped = true
		textLabel.TextXAlignment = Enum.TextXAlignment.Left
		textLabel.AutomaticSize = Enum.AutomaticSize.Y
		textLabel.LayoutOrder = 2
		textLabel.Size = UDim2.new(1, 0, 0, 14)
		textLabel.ZIndex = Z.Toast + 1
		textLabel.Parent = card
	end

	local actionButtons = {}
	if type(opts.Actions) == "table" and #opts.Actions > 0 then
		local actionsRow = Instance.new("Frame")
		actionsRow.Name = "Actions"
		actionsRow.BackgroundTransparency = 1
		actionsRow.AutomaticSize = Enum.AutomaticSize.Y
		actionsRow.Size = UDim2.new(1, 0, 0, 0)
		actionsRow.LayoutOrder = 3
		actionsRow.ZIndex = Z.Toast + 1
		actionsRow.Parent = card

		local actionsLayout = Instance.new("UIListLayout")
		actionsLayout.FillDirection = Enum.FillDirection.Horizontal
		actionsLayout.Padding = UDim.new(0, 6)
		actionsLayout.SortOrder = Enum.SortOrder.LayoutOrder
		actionsLayout.Parent = actionsRow

		for i, action in ipairs(opts.Actions) do
			local btn = Instance.new("TextButton")
			btn.AutoButtonColor = false
			btn.BackgroundColor3 = color
			btn.BackgroundTransparency = 1
			btn.BorderSizePixel = 0
			btn.Text = ""
			btn.AutomaticSize = Enum.AutomaticSize.X
			btn.Size = UDim2.fromOffset(0, 22)
			btn.LayoutOrder = i
			btn.ZIndex = Z.Toast + 1
			btn.Parent = actionsRow
			Corner(btn, 6)
			local btnStroke = Stroke(btn, color, 1, 1)

			local btnPad = Instance.new("UIPadding")
			btnPad.PaddingLeft = UDim.new(0, 8)
			btnPad.PaddingRight = UDim.new(0, 8)
			btnPad.Parent = btn

			local lbl = Instance.new("TextLabel")
			lbl.BackgroundTransparency = 1
			lbl.FontFace = NullUI.Theme.Font
			lbl.Text = action.Text or "Action"
			lbl.TextColor3 = color
			lbl.TextTransparency = 1
			lbl.TextSize = 12
			lbl.AutomaticSize = Enum.AutomaticSize.X
			lbl.Size = UDim2.fromOffset(0, 22)
			lbl.ZIndex = Z.Toast + 2
			lbl.Parent = btn

			Tween(btn, { BackgroundTransparency = 0.85 }, 0.26)
			Tween(btnStroke, { Transparency = 0.6 }, 0.26)
			Tween(lbl, { TextTransparency = 0 }, 0.26)

			btn.MouseEnter:Connect(function()
				Tween(btn, { BackgroundTransparency = 0.7 }, 0.12)
			end)
			btn.MouseLeave:Connect(function()
				Tween(btn, { BackgroundTransparency = 0.85 }, 0.12)
			end)
			btn.MouseButton1Click:Connect(function()
				if action.Callback then
					SafeSpawn(action.Callback)
				end
				if action.DismissOnClick ~= false then
					dismiss()
				end
			end)

			table.insert(actionButtons, { Button = btn, Stroke = btnStroke, Label = lbl })
		end
	end

	local barHolder = Instance.new("Frame")
	barHolder.BackgroundColor3 = Color3.new(1, 1, 1)
	barHolder.BackgroundTransparency = 1
	barHolder.BorderSizePixel = 0
	barHolder.Size = UDim2.new(1, 0, 0, 3)
	barHolder.LayoutOrder = 4
	barHolder.ZIndex = Z.Toast + 1
	barHolder.Parent = card
	Corner(barHolder, 2)

	local bar = Instance.new("Frame")
	bar.BackgroundColor3 = color
	bar.BackgroundTransparency = 1
	bar.BorderSizePixel = 0
	bar.AnchorPoint = Vector2.new(0, 0.5)
	bar.Position = UDim2.new(0, 0, 0.5, 0)
	bar.Size = UDim2.fromScale(1, 1)
	bar.ZIndex = Z.Toast + 2
	bar.Parent = barHolder
	Corner(bar, 2)

	local barGradient = Instance.new("UIGradient")
	barGradient.Color = ColorSequence.new({
		ColorSequenceKeypoint.new(0, color:Lerp(Color3.new(1, 1, 1), 0.4)),
		ColorSequenceKeypoint.new(1, color),
	})
	barGradient.Parent = bar

	local dismissed = false
	function dismiss()
		if dismissed or not card.Parent then
			return
		end
		dismissed = true
		if not card.Visible then
			card:Destroy()
			return
		end

		local currentHeight = card.AbsoluteSize.Y / GetUIScale()
		card.AutomaticSize = Enum.AutomaticSize.None
		card.Size = UDim2.new(1, 0, 0, currentHeight)

		Tween(card, { BackgroundTransparency = 1 }, 0.18)
		Tween(stroke, { Transparency = 1 }, 0.18)
		Tween(scale, { Scale = 0.9 }, 0.18, Enum.EasingStyle.Quint, Enum.EasingDirection.In)
		Tween(icon, { ImageTransparency = 1 }, 0.18)
		Tween(titleLabel, { TextTransparency = 1 }, 0.18)
		if textLabel then
			Tween(textLabel, { TextTransparency = 1 }, 0.18)
		end

		SafeDelay(0.1, function()
			if card and card.Parent then
				Tween(card, { Size = UDim2.new(1, 0, 0, 0) }, 0.26, Enum.EasingStyle.Quint, Enum.EasingDirection.In)
			end
		end)

		SafeDelay(0.34, function()
			if notificationAcrylic then
				notificationAcrylic:Destroy()
				notificationAcrylic = nil
			end
			if card then
				card:Destroy()
			end
		end)
	end

	local function startNotification()
		if dismissed or not card.Parent then
			return
		end
		card.Visible = true
		notificationAcrylic = CreateWindowAcrylic(card)
		Tween(card, { BackgroundTransparency = 0.25 }, 0.26)
		Tween(stroke, { Transparency = 0.82 }, 0.26)
		Tween(scale, { Scale = 1 }, 0.32, Enum.EasingStyle.Quint, Enum.EasingDirection.Out)
		Tween(icon, { ImageTransparency = 0 }, 0.26)
		Tween(titleLabel, { TextTransparency = 0 }, 0.26)
		Tween(barHolder, { BackgroundTransparency = 0.88 }, 0.26)
		Tween(bar, { BackgroundTransparency = 0 }, 0.26)
		if textLabel then
			Tween(textLabel, { TextTransparency = 0 }, 0.26)
		end

		SafeDelay(0.05, function()
			if bar and bar.Parent then
				Tween(
					bar,
					{ Size = UDim2.new(0, 0, 1, 0) },
					duration - 0.05,
					Enum.EasingStyle.Linear,
					Enum.EasingDirection.Out
				)
			end
		end)

		SafeDelay(duration, dismiss)
	end
	table.insert(NotificationQueue, { Card = card, Start = startNotification })

	return {
		Instance = card,
		Dismiss = dismiss,
	}
end

-- Global announcement toast: one at a time, centered near the top of the
-- screen and outside every window. Width adapts to phone / PC viewports.
function NullUI:Announce(opts)
	opts = opts or {}
	local text = tostring(opts.Text or "")
	if text == "" then
		return
	end
	local title = opts.Title or "Announcement"
	local duration = math.max(tonumber(opts.Duration) or 6, 1)
	local color = opts.Color or NullUI.Theme.Accent
	local mobile = IsMobileDevice

	if NullUI._ActiveAnnouncement then
		NullUI._ActiveAnnouncement.Dismiss()
	end

	local function metrics()
		local s = GetUIScale()
		local view = ViewportSize()
		local availW, availH = view.X / s, view.Y / s
		local width = math.min(mobile and 320 or 400, math.max(availW - 32, 160))
		local top = math.clamp(availH * 0.05, 14, 44)
		return width, top
	end

	local width, top = metrics()
	local card = Instance.new("Frame")
	card.Name = "NullUIAnnouncement"
	card.AnchorPoint = Vector2.new(0.5, 0)
	card.Position = UDim2.new(0.5, 0, 0, top - 12)
	card.Size = UDim2.fromOffset(width, 0)
	card.AutomaticSize = Enum.AutomaticSize.Y
	card.BackgroundColor3 = NullUI.Theme.Surface
	card.BackgroundTransparency = 1
	card.BorderSizePixel = 0
	card.ZIndex = Z.Toast + 20
	card.Active = true
	card.Parent = NullUI._Root
	Corner(card, mobile and 12 or 14)
	local stroke = Stroke(card, color, 1, 1)

	local pad = Instance.new("UIPadding")
	pad.PaddingTop = UDim.new(0, mobile and 8 or 10)
	pad.PaddingBottom = UDim.new(0, mobile and 8 or 10)
	pad.PaddingLeft = UDim.new(0, mobile and 10 or 12)
	pad.PaddingRight = UDim.new(0, mobile and 10 or 12)
	pad.Parent = card

	local layout = Instance.new("UIListLayout")
	layout.Padding = UDim.new(0, mobile and 4 or 5)
	layout.SortOrder = Enum.SortOrder.LayoutOrder
	layout.Parent = card

	local header = Instance.new("Frame")
	header.BackgroundTransparency = 1
	header.AutomaticSize = Enum.AutomaticSize.XY
	header.Size = UDim2.new(0, 0, 0, 0)
	header.LayoutOrder = 1
	header.ZIndex = card.ZIndex + 1
	header.Parent = card

	local headerLayout = Instance.new("UIListLayout")
	headerLayout.FillDirection = Enum.FillDirection.Horizontal
	headerLayout.VerticalAlignment = Enum.VerticalAlignment.Center
	headerLayout.Padding = UDim.new(0, 6)
	headerLayout.SortOrder = Enum.SortOrder.LayoutOrder
	headerLayout.Parent = header

	local icon = Instance.new("ImageLabel")
	icon.BackgroundTransparency = 1
	icon.Image = ResolveIcon(opts.Icon or "megaphone")
	icon.ImageColor3 = color
	icon.ImageTransparency = 1
	icon.Size = UDim2.fromOffset(mobile and 13 or 15, mobile and 13 or 15)
	icon.LayoutOrder = 1
	icon.ZIndex = card.ZIndex + 1
	icon.Parent = header

	local titleLabel = Instance.new("TextLabel")
	titleLabel.BackgroundTransparency = 1
	titleLabel.FontFace = NullUI.Theme.Font
	titleLabel.Text = title
	titleLabel.TextColor3 = color
	titleLabel.TextTransparency = 1
	titleLabel.TextSize = mobile and 12 or 13
	titleLabel.AutomaticSize = Enum.AutomaticSize.XY
	titleLabel.Size = UDim2.fromOffset(0, mobile and 12 or 13)
	titleLabel.LayoutOrder = 2
	titleLabel.ZIndex = card.ZIndex + 1
	titleLabel.Parent = header

	local body = Instance.new("TextLabel")
	body.BackgroundTransparency = 1
	body.FontFace = NullUI.Theme.FontRegular
	body.Text = text
	body.TextColor3 = NullUI.Theme.Text
	Role(body, "Text")
	body.TextTransparency = 1
	body.TextSize = mobile and 12 or 14
	body.TextWrapped = true
	body.TextXAlignment = Enum.TextXAlignment.Left
	body.AutomaticSize = Enum.AutomaticSize.Y
	body.Size = UDim2.new(1, 0, 0, 0)
	body.LayoutOrder = 2
	body.ZIndex = card.ZIndex + 1
	body.Parent = card

	local barHolder = Instance.new("Frame")
	barHolder.BackgroundColor3 = color
	barHolder.BackgroundTransparency = 1
	barHolder.BorderSizePixel = 0
	barHolder.Size = UDim2.new(1, 0, 0, 2)
	barHolder.LayoutOrder = 3
	barHolder.ZIndex = card.ZIndex + 1
	barHolder.Parent = card
	Corner(barHolder, 1)

	local bar = Instance.new("Frame")
	bar.BackgroundColor3 = color
	bar.BackgroundTransparency = 1
	bar.BorderSizePixel = 0
	bar.Size = UDim2.fromScale(1, 1)
	bar.ZIndex = card.ZIndex + 2
	bar.Parent = barHolder
	Corner(bar, 1)

	local viewportConn
	local cam = workspace.CurrentCamera
	if cam then
		viewportConn = cam:GetPropertyChangedSignal("ViewportSize"):Connect(function()
			if card.Parent then
				local w, t = metrics()
				card.Size = UDim2.fromOffset(w, 0)
				card.Position = UDim2.new(0.5, 0, 0, t)
			end
		end)
	end

	local dismissed = false
	local handle = {}
	function handle.Dismiss()
		if dismissed then
			return
		end
		dismissed = true
		if NullUI._ActiveAnnouncement == handle then
			NullUI._ActiveAnnouncement = nil
		end
		if viewportConn then
			viewportConn:Disconnect()
		end
		if not card.Parent then
			return
		end
		local _, t = metrics()
		Tween(card, { BackgroundTransparency = 1, Position = UDim2.new(0.5, 0, 0, t - 12) }, 0.22)
		Tween(stroke, { Transparency = 1 }, 0.22)
		Tween(icon, { ImageTransparency = 1 }, 0.22)
		Tween(titleLabel, { TextTransparency = 1 }, 0.22)
		Tween(body, { TextTransparency = 1 }, 0.22)
		Tween(barHolder, { BackgroundTransparency = 1 }, 0.22)
		Tween(bar, { BackgroundTransparency = 1 }, 0.22)
		SafeDelay(0.25, function()
			if card then
				card:Destroy()
			end
		end)
	end
	handle.Instance = card
	NullUI._ActiveAnnouncement = handle

	-- Tap / click to dismiss early.
	card.InputBegan:Connect(function(input)
		local kind = input.UserInputType
		if kind == Enum.UserInputType.MouseButton1 or kind == Enum.UserInputType.Touch then
			handle.Dismiss()
		end
	end)

	Tween(card, { BackgroundTransparency = 0.06, Position = UDim2.new(0.5, 0, 0, top) }, 0.3, Enum.EasingStyle.Quint, Enum.EasingDirection.Out)
	Tween(stroke, { Transparency = 0.55 }, 0.3)
	Tween(icon, { ImageTransparency = 0 }, 0.3)
	Tween(titleLabel, { TextTransparency = 0 }, 0.3)
	Tween(body, { TextTransparency = 0 }, 0.3)
	Tween(barHolder, { BackgroundTransparency = 0.85 }, 0.3)
	Tween(bar, { BackgroundTransparency = 0 }, 0.3)
	SafeDelay(0.05, function()
		if bar.Parent and not dismissed then
			Tween(bar, { Size = UDim2.fromScale(0, 1) }, duration, Enum.EasingStyle.Linear, Enum.EasingDirection.Out)
		end
	end)
	SafeDelay(duration, handle.Dismiss)

	return handle
end

local function ComputeDialogCenter(anchorFrame)
	local view = ViewportSize()
	if not anchorFrame or anchorFrame.AbsoluteSize.X <= 0 then
		return view.X / 2, view.Y / 2
	end
	local pos, size = anchorFrame.AbsolutePosition, anchorFrame.AbsoluteSize
	local cx = SafeClamp(pos.X + size.X / 2, 190, math.max(190, view.X - 190))
	local cy = SafeClamp(pos.Y + size.Y / 2, 110, math.max(110, view.Y - 110))
	return cx, cy
end

function NullUI:Confirm(opts)
	opts = opts or {}
	local title = opts.Title or "Confirm"
	local text = opts.Text or ""
	local confirmText = opts.ConfirmText or "Confirm"
	local cancelText = opts.CancelText or "Cancel"
	local danger = opts.Danger == true
	local anchorFrame = opts.Window
	if type(anchorFrame) == "table" then
		anchorFrame = anchorFrame._gui
	end

	local root = NullUI._Root
	local jan = Janitor.new()

	local backdrop = Instance.new("TextButton")
	backdrop.Name = "ConfirmBackdrop"
	backdrop.Text = ""
	backdrop.AutoButtonColor = false
	backdrop.BackgroundColor3 = Color3.new(0, 0, 0)
	backdrop.BackgroundTransparency = 1
	backdrop.BorderSizePixel = 0
	backdrop.Size = UDim2.fromScale(1, 1)
	backdrop.ZIndex = Z.Modal
	backdrop.Parent = root

	local dialog = Instance.new("Frame")
	dialog.Name = "ConfirmDialog"
	dialog.AnchorPoint = Vector2.new(0.5, 0.5)
	do
		local cx, cy = ComputeDialogCenter(anchorFrame)
		local s = GetUIScale()
		dialog.Position = UDim2.fromOffset(math.round(cx / s), math.round(cy / s))
	end
	dialog.BackgroundColor3 = NullUI.Theme.Surface
	dialog.BackgroundTransparency = 1
	dialog.BorderSizePixel = 0
	dialog.Active = true
	dialog.ClipsDescendants = true
	dialog.AutomaticSize = Enum.AutomaticSize.Y
	dialog.Size = UDim2.new(0, 340, 0, 0)
	dialog.ZIndex = Z.ModalTop
	dialog.Parent = backdrop
	Corner(dialog, 16)
	local dialogStroke = Stroke(dialog, Color3.new(1, 1, 1), 1, 1)

	local scale = Instance.new("UIScale")
	scale.Scale = 0.9
	scale.Parent = dialog

	local padding = Instance.new("UIPadding")
	padding.PaddingTop = UDim.new(0, 20)
	padding.PaddingBottom = UDim.new(0, 18)
	padding.PaddingLeft = UDim.new(0, 20)
	padding.PaddingRight = UDim.new(0, 20)
	padding.Parent = dialog

	local layout = Instance.new("UIListLayout")
	layout.Padding = UDim.new(0, 10)
	layout.SortOrder = Enum.SortOrder.LayoutOrder
	layout.Parent = dialog

	local titleLabel = Instance.new("TextLabel")
	titleLabel.BackgroundTransparency = 1
	titleLabel.FontFace = NullUI.Theme.Font
	titleLabel.Text = title
	titleLabel.TextColor3 = danger and NullUI.Theme.Danger or NullUI.Theme.Text
	titleLabel.TextTransparency = 1
	titleLabel.TextSize = 18
	titleLabel.TextXAlignment = Enum.TextXAlignment.Left
	titleLabel.TextWrapped = true
	titleLabel.AutomaticSize = Enum.AutomaticSize.Y
	titleLabel.Size = UDim2.new(1, 0, 0, 20)
	titleLabel.LayoutOrder = 1
	titleLabel.ZIndex = Z.ModalTop + 1
	titleLabel.Parent = dialog

	local textLabel
	if text ~= "" then
		textLabel = Instance.new("TextLabel")
		textLabel.BackgroundTransparency = 1
		textLabel.FontFace = NullUI.Theme.FontRegular
		textLabel.Text = text
		textLabel.TextColor3 = NullUI.Theme.TextDim
		Role(textLabel, "TextDim")
		textLabel.TextTransparency = 1
		textLabel.TextSize = 14
		textLabel.TextWrapped = true
		textLabel.TextXAlignment = Enum.TextXAlignment.Left
		textLabel.LineHeight = 1.25
		textLabel.AutomaticSize = Enum.AutomaticSize.Y
		textLabel.Size = UDim2.new(1, 0, 0, 14)
		textLabel.LayoutOrder = 2
		textLabel.ZIndex = Z.ModalTop + 1
		textLabel.Parent = dialog
	end

	local buttonsRow = Instance.new("Frame")
	buttonsRow.BackgroundTransparency = 1
	buttonsRow.Size = UDim2.new(1, 0, 0, 38)
	buttonsRow.LayoutOrder = 3
	buttonsRow.ZIndex = Z.ModalTop + 1
	buttonsRow.Parent = dialog

	local rowPad = Instance.new("UIPadding")
	rowPad.PaddingTop = UDim.new(0, 6)
	rowPad.Parent = buttonsRow

	local rowLayout = Instance.new("UIListLayout")
	rowLayout.FillDirection = Enum.FillDirection.Horizontal
	rowLayout.Padding = UDim.new(0, 8)
	rowLayout.SortOrder = Enum.SortOrder.LayoutOrder
	rowLayout.Parent = buttonsRow

	local function makeButton(text_, order, filled)
		local tint = (filled and danger) and NullUI.Theme.Danger or Color3.new(1, 1, 1)

		local btn = Instance.new("TextButton")
		btn.Text = ""
		btn.AutoButtonColor = false
		btn.BackgroundColor3 = tint
		btn.BackgroundTransparency = filled and (danger and 0.55 or 0.82) or 1
		btn.BorderSizePixel = 0
		btn.Size = UDim2.new(0.5, -4, 1, 0)
		btn.LayoutOrder = order
		btn.ZIndex = Z.ModalTop + 1
		btn.Parent = buttonsRow
		Corner(btn, 10)
		local btnStroke = Stroke(btn, tint, 1, filled and 0.7 or 0.85)

		local lbl = Instance.new("TextLabel")
		lbl.BackgroundTransparency = 1
		lbl.FontFace = NullUI.Theme.Font
		lbl.Text = text_
		lbl.TextColor3 = (filled and danger) and NullUI.Theme.Danger or NullUI.Theme.Text
		lbl.TextSize = 14
		lbl.Size = UDim2.fromScale(1, 1)
		lbl.ZIndex = Z.ModalTop + 2
		lbl.Parent = btn

		local baseBg = btn.BackgroundTransparency
		local baseStroke = btnStroke.Transparency

		jan:Add(btn.MouseEnter:Connect(function()
			Tween(btn, { BackgroundTransparency = math.max(baseBg - 0.1, 0) }, 0.12)
			Tween(btnStroke, { Transparency = math.max(baseStroke - 0.15, 0) }, 0.12)
		end))
		jan:Add(btn.MouseLeave:Connect(function()
			Tween(btn, { BackgroundTransparency = baseBg }, 0.12)
			Tween(btnStroke, { Transparency = baseStroke }, 0.12)
		end))

		return btn
	end

	local cancelBtn = makeButton(cancelText, 1, false)
	local confirmBtn = makeButton(confirmText, 2, true)

	local closed = false
	local function close(confirmed)
		if closed then
			return
		end
		closed = true

		Tween(scale, { Scale = 0.94 }, 0.18, Enum.EasingStyle.Quint, Enum.EasingDirection.In)
		Tween(dialog, { BackgroundTransparency = 1 }, 0.18)
		Tween(dialogStroke, { Transparency = 1 }, 0.18)
		Tween(backdrop, { BackgroundTransparency = 1 }, 0.18)
		Tween(titleLabel, { TextTransparency = 1 }, 0.12)
		if textLabel then
			Tween(textLabel, { TextTransparency = 1 }, 0.12)
		end

		SafeDelay(0.18, function()
			jan:Destroy()
			if backdrop then
				backdrop:Destroy()
			end
		end)

		if opts.Callback then
			SafeSpawn(opts.Callback, confirmed)
		end
	end

	jan:Add(backdrop.MouseButton1Click:Connect(function()
		close(false)
	end))
	jan:Add(cancelBtn.MouseButton1Click:Connect(function()
		close(false)
	end))
	jan:Add(confirmBtn.MouseButton1Click:Connect(function()
		close(true)
	end))

	jan:Add(UserInputService.InputBegan:Connect(function(input, gameProcessed)
		if gameProcessed or closed then
			return
		end
		if input.KeyCode == Enum.KeyCode.Return or input.KeyCode == Enum.KeyCode.KeypadEnter then
			close(true)
		elseif input.KeyCode == Enum.KeyCode.Escape then
			close(false)
		end
	end))

	Tween(backdrop, { BackgroundTransparency = 0.5 }, 0.18)
	Tween(dialog, { BackgroundTransparency = 0 }, 0.18)
	Tween(dialogStroke, { Transparency = 0.8 }, 0.18)
	Tween(titleLabel, { TextTransparency = 0 }, 0.18)
	if textLabel then
		Tween(textLabel, { TextTransparency = 0 }, 0.18)
	end
	Tween(scale, { Scale = 1 }, 0.26, Enum.EasingStyle.Quint, Enum.EasingDirection.Out)

	return { Close = close }
end

function NullUI:Modal(opts)
	opts = opts or {}
	local title = opts.Title or "Modal"
	local text = opts.Text or ""
	local confirmText = opts.ConfirmText or "Confirm"
	local cancelText = opts.CancelText or "Cancel"
	local danger = opts.Danger == true
	local fields = opts.Fields or {}
	local anchorFrame = opts.Window
	if type(anchorFrame) == "table" then
		anchorFrame = anchorFrame._gui
	end

	local root = NullUI._Root
	local jan = Janitor.new()

	local backdrop = Instance.new("TextButton")
	backdrop.Name = "ModalBackdrop"
	backdrop.Text = ""
	backdrop.AutoButtonColor = false
	backdrop.BackgroundColor3 = Color3.new(0, 0, 0)
	backdrop.BackgroundTransparency = 1
	backdrop.BorderSizePixel = 0
	backdrop.Size = UDim2.fromScale(1, 1)
	backdrop.ZIndex = Z.Modal
	backdrop.Parent = root

	local dialog = Instance.new("Frame")
	dialog.Name = "ModalDialog"
	dialog.AnchorPoint = Vector2.new(0.5, 0.5)
	do
		local cx, cy = ComputeDialogCenter(anchorFrame)
		local s = GetUIScale()
		dialog.Position = UDim2.fromOffset(math.round(cx / s), math.round(cy / s))
	end
	dialog.BackgroundColor3 = NullUI.Theme.Surface
	dialog.BackgroundTransparency = 1
	dialog.BorderSizePixel = 0
	dialog.Active = true
	dialog.ClipsDescendants = true
	dialog.AutomaticSize = Enum.AutomaticSize.Y
	dialog.Size = UDim2.new(0, 360, 0, 0)
	dialog.ZIndex = Z.ModalTop
	dialog.Parent = backdrop
	Corner(dialog, 16)
	local dialogStroke = Stroke(dialog, Color3.new(1, 1, 1), 1, 1)

	local scale = Instance.new("UIScale")
	scale.Scale = 0.9
	scale.Parent = dialog

	local padding = Instance.new("UIPadding")
	padding.PaddingTop = UDim.new(0, 20)
	padding.PaddingBottom = UDim.new(0, 18)
	padding.PaddingLeft = UDim.new(0, 20)
	padding.PaddingRight = UDim.new(0, 20)
	padding.Parent = dialog

	local layout = Instance.new("UIListLayout")
	layout.Padding = UDim.new(0, 14)
	layout.SortOrder = Enum.SortOrder.LayoutOrder
	layout.Parent = dialog

	local titleLabel = Instance.new("TextLabel")
	titleLabel.BackgroundTransparency = 1
	titleLabel.FontFace = NullUI.Theme.Font
	titleLabel.Text = title
	titleLabel.TextColor3 = danger and NullUI.Theme.Danger or NullUI.Theme.Text
	titleLabel.TextTransparency = 1
	titleLabel.TextSize = 18
	titleLabel.TextXAlignment = Enum.TextXAlignment.Left
	titleLabel.TextWrapped = true
	titleLabel.AutomaticSize = Enum.AutomaticSize.Y
	titleLabel.Size = UDim2.new(1, 0, 0, 20)
	titleLabel.LayoutOrder = 1
	titleLabel.ZIndex = Z.ModalTop + 1
	titleLabel.Parent = dialog

	local textLabel
	if text ~= "" then
		textLabel = Instance.new("TextLabel")
		textLabel.BackgroundTransparency = 1
		textLabel.FontFace = NullUI.Theme.FontRegular
		textLabel.Text = text
		textLabel.TextColor3 = NullUI.Theme.TextDim
		Role(textLabel, "TextDim")
		textLabel.TextTransparency = 1
		textLabel.TextSize = 13
		textLabel.TextWrapped = true
		textLabel.TextXAlignment = Enum.TextXAlignment.Left
		textLabel.LineHeight = 1.25
		textLabel.AutomaticSize = Enum.AutomaticSize.Y
		textLabel.Size = UDim2.new(1, 0, 0, 14)
		textLabel.LayoutOrder = 2
		textLabel.ZIndex = Z.ModalTop + 1
		textLabel.Parent = dialog
	end

	local fieldsHolder = Instance.new("Frame")
	fieldsHolder.BackgroundTransparency = 1
	fieldsHolder.AutomaticSize = Enum.AutomaticSize.Y
	fieldsHolder.Size = UDim2.new(1, 0, 0, 0)
	fieldsHolder.LayoutOrder = 3
	fieldsHolder.ZIndex = Z.ModalTop + 1
	fieldsHolder.Parent = dialog

	local fieldsLayout = Instance.new("UIListLayout")
	fieldsLayout.Padding = UDim.new(0, 10)
	fieldsLayout.SortOrder = Enum.SortOrder.LayoutOrder
	fieldsLayout.Parent = fieldsHolder

	local fieldBoxes = {}
	local fieldOrder = {}

	for i, field in ipairs(fields) do
		local isTextarea = field.Type == "textarea"
		local labelH = field.Label and field.Label ~= "" and 16 or 0
		local boxH = isTextarea and 60 or 34

		local holder = Instance.new("Frame")
		holder.BackgroundTransparency = 1
		holder.AutomaticSize = Enum.AutomaticSize.Y
		holder.Size = UDim2.new(1, 0, 0, 0)
		holder.LayoutOrder = i
		holder.ZIndex = Z.ModalTop + 1
		holder.Parent = fieldsHolder

		local holderLayout = Instance.new("UIListLayout")
		holderLayout.Padding = UDim.new(0, 4)
		holderLayout.SortOrder = Enum.SortOrder.LayoutOrder
		holderLayout.Parent = holder

		if labelH > 0 then
			local lbl = Instance.new("TextLabel")
			lbl.BackgroundTransparency = 1
			lbl.FontFace = NullUI.Theme.FontRegular
			lbl.Text = string.upper(field.Label)
			lbl.TextColor3 = danger and NullUI.Theme.Danger or NullUI.Theme.TextDim
			lbl.TextSize = 11
			lbl.TextXAlignment = Enum.TextXAlignment.Left
			lbl.Size = UDim2.new(1, 0, 0, labelH)
			lbl.LayoutOrder = 1
			lbl.ZIndex = Z.ModalTop + 2
			lbl.Parent = holder
		end

		local fieldFrame = Instance.new("Frame")
		fieldFrame.BackgroundColor3 = Color3.new(1, 1, 1)
		fieldFrame.BackgroundTransparency = 0.93
		fieldFrame.BorderSizePixel = 0
		fieldFrame.Size = UDim2.new(1, 0, 0, boxH)
		fieldFrame.LayoutOrder = 2
		fieldFrame.ZIndex = Z.ModalTop + 2
		fieldFrame.Parent = holder
		Corner(fieldFrame, 9)
		local fieldStroke = Stroke(fieldFrame, Color3.new(1, 1, 1), 1, 0.88)

		local fieldPad = Instance.new("UIPadding")
		fieldPad.PaddingLeft = UDim.new(0, 10)
		fieldPad.PaddingRight = UDim.new(0, 10)
		fieldPad.PaddingTop = UDim.new(0, isTextarea and 8 or 0)
		fieldPad.Parent = fieldFrame

		local box = Instance.new("TextBox")
		box.ClearTextOnFocus = false
		box.MultiLine = isTextarea
		box.FontFace = NullUI.Theme.FontRegular
		box.PlaceholderText = field.Placeholder or ""
		box.PlaceholderColor3 = Color3.fromRGB(120, 120, 122)
		box.Text = tostring(field.Default or "")
		box.TextColor3 = NullUI.Theme.Text
		Role(box, "Text")
		box.TextSize = 13
		box.TextXAlignment = Enum.TextXAlignment.Left
		box.TextYAlignment = isTextarea and Enum.TextYAlignment.Top or Enum.TextYAlignment.Center
		box.TextWrapped = isTextarea
		box.ClipsDescendants = true
		box.BackgroundTransparency = 1
		box.Size = UDim2.fromScale(1, 1)
		box.ZIndex = Z.ModalTop + 3
		box.Parent = fieldFrame

		if field.MaxLength then
			jan:Add(box:GetPropertyChangedSignal("Text"):Connect(function()
				if utf8.len(box.Text) and utf8.len(box.Text) > field.MaxLength then
					box.Text = string.sub(box.Text, 1, field.MaxLength)
				end
			end))
		end

		jan:Add(box.Focused:Connect(function()
			Tween(fieldStroke, { Color = NullUI.Theme.Accent, Transparency = 0.3 }, 0.18)
			Tween(fieldFrame, { BackgroundTransparency = 0.85 }, 0.18)
		end))
		jan:Add(box.FocusLost:Connect(function()
			Tween(fieldStroke, { Color = Color3.new(1, 1, 1), Transparency = 0.88 }, 0.18)
			Tween(fieldFrame, { BackgroundTransparency = 0.93 }, 0.18)
		end))

		local entry = { Type = field.Type, Box = box, Multiline = isTextarea }
		fieldBoxes[field.Key or i] = entry
		table.insert(fieldOrder, entry)
	end

	local buttonsRow = Instance.new("Frame")
	buttonsRow.BackgroundTransparency = 1
	buttonsRow.Size = UDim2.new(1, 0, 0, 38)
	buttonsRow.LayoutOrder = 4
	buttonsRow.ZIndex = Z.ModalTop + 1
	buttonsRow.Parent = dialog

	local rowPad = Instance.new("UIPadding")
	rowPad.PaddingTop = UDim.new(0, 4)
	rowPad.Parent = buttonsRow

	local rowLayout = Instance.new("UIListLayout")
	rowLayout.FillDirection = Enum.FillDirection.Horizontal
	rowLayout.Padding = UDim.new(0, 8)
	rowLayout.SortOrder = Enum.SortOrder.LayoutOrder
	rowLayout.Parent = buttonsRow

	local function makeButton(text_, order, filled)
		local tint = (filled and danger) and NullUI.Theme.Danger or Color3.new(1, 1, 1)

		local btn = Instance.new("TextButton")
		btn.Text = ""
		btn.AutoButtonColor = false
		btn.BackgroundColor3 = tint
		btn.BackgroundTransparency = filled and (danger and 0.55 or 0.82) or 1
		btn.BorderSizePixel = 0
		btn.Size = UDim2.new(0.5, -4, 1, 0)
		btn.LayoutOrder = order
		btn.ZIndex = Z.ModalTop + 1
		btn.Parent = buttonsRow
		Corner(btn, 10)
		local btnStroke = Stroke(btn, tint, 1, filled and 0.7 or 0.85)

		local lbl = Instance.new("TextLabel")
		lbl.BackgroundTransparency = 1
		lbl.FontFace = NullUI.Theme.Font
		lbl.Text = text_
		lbl.TextColor3 = (filled and danger) and NullUI.Theme.Danger or NullUI.Theme.Text
		lbl.TextSize = 14
		lbl.Size = UDim2.fromScale(1, 1)
		lbl.ZIndex = Z.ModalTop + 2
		lbl.Parent = btn

		local baseBg = btn.BackgroundTransparency
		local baseStroke = btnStroke.Transparency

		jan:Add(btn.MouseEnter:Connect(function()
			Tween(btn, { BackgroundTransparency = math.max(baseBg - 0.1, 0) }, 0.12)
			Tween(btnStroke, { Transparency = math.max(baseStroke - 0.15, 0) }, 0.12)
		end))
		jan:Add(btn.MouseLeave:Connect(function()
			Tween(btn, { BackgroundTransparency = baseBg }, 0.12)
			Tween(btnStroke, { Transparency = baseStroke }, 0.12)
		end))

		return btn
	end

	local cancelBtn = makeButton(cancelText, 1, false)
	local confirmBtn = makeButton(confirmText, 2, true)

	local function collectValues()
		local values = {}
		for key, entry in pairs(fieldBoxes) do
			if entry.Type == "tags" then
				local list = {}
				for piece in string.gmatch(entry.Box.Text, "[^,]+") do
					local trimmed = piece:gsub("^%s+", ""):gsub("%s+$", "")
					if trimmed ~= "" then
						table.insert(list, trimmed)
					end
				end
				values[key] = list
			else
				values[key] = entry.Box.Text
			end
		end
		return values
	end

	local closed = false
	local function close(confirmed)
		if closed then
			return
		end
		closed = true

		Tween(scale, { Scale = 0.94 }, 0.18, Enum.EasingStyle.Quint, Enum.EasingDirection.In)
		Tween(dialog, { BackgroundTransparency = 1 }, 0.18)
		Tween(dialogStroke, { Transparency = 1 }, 0.18)
		Tween(backdrop, { BackgroundTransparency = 1 }, 0.18)
		Tween(titleLabel, { TextTransparency = 1 }, 0.12)
		if textLabel then
			Tween(textLabel, { TextTransparency = 1 }, 0.12)
		end

		SafeDelay(0.18, function()
			jan:Destroy()
			if backdrop then
				backdrop:Destroy()
			end
		end)

		if opts.Callback then
			SafeSpawn(opts.Callback, confirmed, confirmed and collectValues() or nil)
		end
	end

	jan:Add(backdrop.MouseButton1Click:Connect(function()
		close(false)
	end))
	jan:Add(cancelBtn.MouseButton1Click:Connect(function()
		close(false)
	end))
	jan:Add(confirmBtn.MouseButton1Click:Connect(function()
		close(true)
	end))

	jan:Add(UserInputService.InputBegan:Connect(function(input, gameProcessed)
		if gameProcessed or closed then
			return
		end
		if input.KeyCode == Enum.KeyCode.Escape then
			close(false)
		end
	end))

	Tween(backdrop, { BackgroundTransparency = 0.5 }, 0.18)
	Tween(dialog, { BackgroundTransparency = 0 }, 0.18)
	Tween(dialogStroke, { Transparency = 0.8 }, 0.18)
	Tween(titleLabel, { TextTransparency = 0 }, 0.18)
	if textLabel then
		Tween(textLabel, { TextTransparency = 0 }, 0.18)
	end
	Tween(scale, { Scale = 1 }, 0.26, Enum.EasingStyle.Quint, Enum.EasingDirection.Out)

	if fieldOrder[1] and opts.AutoFocus ~= false then
		SafeDefer(function()
			if not closed and fieldOrder[1].Box and fieldOrder[1].Box.Parent then
				fieldOrder[1].Box:CaptureFocus()
			end
		end)
	end

	for index, entry in ipairs(fieldOrder) do
		if entry.Box and not entry.Multiline then
			jan:Add(entry.Box.FocusLost:Connect(function(enterPressed)
				if not enterPressed or closed then
					return
				end
				local nextEntry = fieldOrder[index + 1]
				if nextEntry and nextEntry.Box and nextEntry.Box.Parent then
					nextEntry.Box:CaptureFocus()
				else
					close(true)
				end
			end))
		end
	end

	return { Close = close }
end

local DRAG_SMOOTH_SPEED = 22

local function SetupSmoothDrag(frame, handle, janitor, extraHandles)
	handle = handle or frame

	local detector = handle:FindFirstChildWhichIsA("UIDragDetector")
	if detector then
		detector.Enabled = false
	end

	local dragging = false
	local settling = false
	local mouseOffset = Vector2.zero
	local activeInput = nil

	local function frameOffset()
		local pos = frame.Position
		local parentSize = ViewportSize()
		if frame.Parent and frame.Parent:IsA("GuiObject") and frame.Parent.AbsoluteSize.X > 0 then
			parentSize = frame.Parent.AbsoluteSize
		end
		local s = GetUIScale()
		return Vector2.new(pos.X.Scale * parentSize.X + pos.X.Offset * s, pos.Y.Scale * parentSize.Y + pos.Y.Offset * s)
	end

	local currentPosition = frameOffset()
	local targetPosition = currentPosition

	local function clampToScreen(pos)
		local view = ViewportSize()
		local size = frame.AbsoluteSize
		local anchor = frame.AnchorPoint
		local minVisible = 60
		local left = pos.X - size.X * anchor.X
		local top = pos.Y - size.Y * anchor.Y
		left = SafeClamp(left, -size.X + minVisible, view.X - minVisible)
		-- A ScreenGui vive abaixo do inset do topo, entao travar em 0 era o teto invisivel
		-- que impedia arrastar a janela pra cima. -inset.Y libera ate a borda real da tela.
		top = SafeClamp(top, -GuiService:GetGuiInset().Y, view.Y - minVisible)
		return Vector2.new(left + size.X * anchor.X, top + size.Y * anchor.Y)
	end

	local api = {}

	function api.Sync()
		currentPosition = frameOffset()
		targetPosition = currentPosition
		settling = false
	end

	local function beginDrag(input)
		if
			input.UserInputType ~= Enum.UserInputType.MouseButton1
			and input.UserInputType ~= Enum.UserInputType.Touch
		then
			return
		end
		if dragging then
			return
		end
		dragging = true
		settling = true
		activeInput = input
		currentPosition = frameOffset()
		targetPosition = currentPosition
		mouseOffset = Vector2.new(input.Position.X, input.Position.Y) - currentPosition
	end

	janitor:Add(handle.InputBegan:Connect(beginDrag))
	for _, extra in ipairs(extraHandles or {}) do
		janitor:Add(extra.InputBegan:Connect(beginDrag))
	end

	janitor:Add(UserInputService.InputChanged:Connect(function(input)
		LPH_ATTRIBUTES(VM(NONE))
		if not dragging then
			return
		end
		if
			input.UserInputType ~= Enum.UserInputType.MouseMovement
			and input.UserInputType ~= Enum.UserInputType.Touch
		then
			return
		end
		if input.UserInputType == Enum.UserInputType.Touch and activeInput and input ~= activeInput then
			return
		end
		targetPosition = clampToScreen(Vector2.new(input.Position.X, input.Position.Y) - mouseOffset)
	end))

	janitor:Add(UserInputService.InputEnded:Connect(function(input)
		if
			input == activeInput
			or (
				activeInput
				and activeInput.UserInputType == Enum.UserInputType.MouseButton1
				and input.UserInputType == Enum.UserInputType.MouseButton1
			)
		then
			dragging = false
			activeInput = nil
		end
	end))

	janitor:Add(RunService.RenderStepped:Connect(function(dt)
		LPH_ATTRIBUTES(VM(NONE))
		if not dragging and not settling then
			return
		end
		if not frame.Parent then
			return
		end

		local alpha = 1 - math.exp(-DRAG_SMOOTH_SPEED * dt)
		currentPosition = currentPosition:Lerp(targetPosition, alpha)

		if not dragging and (currentPosition - targetPosition).Magnitude < 0.5 then
			currentPosition = targetPosition
			settling = false
		end

		local s = GetUIScale()
		frame.Position = UDim2.fromOffset(math.round(currentPosition.X / s), math.round(currentPosition.Y / s))
	end))

	return api
end

local function SetupResize(frame, handle, janitor, opts)
	opts = opts or {}
	local minSize = opts.MinSize or Vector2.new(420, 300)
	local onResize = opts.OnResize

	local resizing = false
	local startSize, startTopLeft, startInput, activeInput

	janitor:Add(handle.InputBegan:Connect(function(input)
		if
			input.UserInputType ~= Enum.UserInputType.MouseButton1
			and input.UserInputType ~= Enum.UserInputType.Touch
		then
			return
		end
		if resizing then
			return
		end
		resizing = true
		activeInput = input
		startSize = frame.AbsoluteSize
		startTopLeft = frame.AbsolutePosition
		startInput = Vector2.new(input.Position.X, input.Position.Y)
	end))

	janitor:Add(UserInputService.InputChanged:Connect(function(input)
		LPH_ATTRIBUTES(VM(NONE))
		if not resizing then
			return
		end
		if
			input.UserInputType ~= Enum.UserInputType.MouseMovement
			and input.UserInputType ~= Enum.UserInputType.Touch
		then
			return
		end
		if input.UserInputType == Enum.UserInputType.Touch and activeInput and input ~= activeInput then
			return
		end

		local view = ViewportSize()
		local delta = Vector2.new(input.Position.X, input.Position.Y) - startInput
		local maxW = math.max(view.X - startTopLeft.X - 8, 100)
		local maxH = math.max(view.Y - startTopLeft.Y - 8, 100)
		local newW = SafeClamp(startSize.X + delta.X, math.min(minSize.X, maxW), maxW)
		local newH = SafeClamp(startSize.Y + delta.Y, math.min(minSize.Y, maxH), maxH)

		local s = GetUIScale()
		frame.Size = UDim2.fromOffset(math.round(newW / s), math.round(newH / s))

		local centerX = startTopLeft.X + newW / 2
		local centerY = startTopLeft.Y + newH / 2
		frame.Position = UDim2.fromOffset(math.round(centerX / s), math.round(centerY / s))

		if onResize then
			onResize(frame.Size, false)
		end
	end))

	janitor:Add(UserInputService.InputEnded:Connect(function(input)
		if not resizing then
			return
		end
		if
			input == activeInput
			or (
				activeInput
				and activeInput.UserInputType == Enum.UserInputType.MouseButton1
				and input.UserInputType == Enum.UserInputType.MouseButton1
			)
		then
			resizing = false
			activeInput = nil
			if onResize then
				onResize(frame.Size, true)
			end
		end
	end))
end

local DRAG_THRESHOLD = 6

local function BaseCard(parent, height)
	local card = Instance.new("Frame")
	card.BackgroundColor3 = Color3.new(1, 1, 1)
	card.BackgroundTransparency = 0.96
	card.BorderSizePixel = 0
	card.Size = UDim2.new(1, 0, 0, height or 44)
	card.ZIndex = Z.Content
	card.Parent = parent
	Role(card, "Glass")
	Corner(card, NullUI.Theme.CornerRadiusSm)
	local cardStroke = Stroke(card, Color3.new(1, 1, 1), 1, 0.95)

	local sheen = Instance.new("UIGradient")
	sheen.Rotation = 90
	sheen.Transparency = NumberSequence.new({
		NumberSequenceKeypoint.new(0, 0),
		NumberSequenceKeypoint.new(1, 0.5),
	})
	sheen.Parent = card

	card.MouseEnter:Connect(function()
		Tween(card, { BackgroundTransparency = 0.93 }, 0.12)
		Tween(cardStroke, { Transparency = 0.88 }, 0.12)
	end)
	card.MouseLeave:Connect(function()
		Tween(card, { BackgroundTransparency = 0.96 }, 0.18)
		Tween(cardStroke, { Transparency = 0.95 }, 0.18)
	end)

	return card
end

local function AddLeadingIcon(card, icon, height)
	local asset = icon and ResolveIcon(icon) or ""
	if asset == "" then
		return 14, nil
	end

	local img = Instance.new("ImageLabel")
	img.Name = "LeadingIcon"
	img.BackgroundTransparency = 1
	img.Image = asset
	img.ImageColor3 = NullUI.Theme.TextDim
	Role(img, "TextDim")
	img.Size = UDim2.fromOffset(16, 16)
	img.AnchorPoint = Vector2.new(0, 0.5)
	img.Position = UDim2.new(0, 14, 0.5, 0)
	img.ZIndex = Z.Content + 1
	img.Parent = card
	Role(img, "TextDim")
	return 14 + 16 + 10, img
end

local function AddTitleDesc(card, x, rightReserve, title, description, baseHeight, extraBottom)
	extraBottom = extraBottom or 0
	local hasDesc = description ~= nil and description ~= ""
	local titleH, descH, gap = 15, 14, 2

	local titleLabel = Instance.new("TextLabel")
	titleLabel.Name = "Title"
	titleLabel.BackgroundTransparency = 1
	titleLabel.FontFace = NullUI.Theme.Font
	titleLabel.Text = title
	titleLabel.TextColor3 = NullUI.Theme.Text
	Role(titleLabel, "Text")
	titleLabel.TextSize = 13
	titleLabel.TextXAlignment = Enum.TextXAlignment.Left
	titleLabel.TextYAlignment = Enum.TextYAlignment.Center
	titleLabel.TextTruncate = Enum.TextTruncate.AtEnd
	titleLabel.Size =
		UDim2.new(1, -(x + (type(rightReserve) == "function" and rightReserve() or rightReserve)), 0, titleH)
	titleLabel.Position = UDim2.fromOffset(x, 0)
	titleLabel.ZIndex = Z.Content + 1
	titleLabel.Parent = card

	local descLabel
	if hasDesc then
		descLabel = Instance.new("TextLabel")
		descLabel.Name = "Description"
		descLabel.BackgroundTransparency = 1
		descLabel.FontFace = NullUI.Theme.FontRegular
		descLabel.Text = description
		descLabel.TextColor3 = NullUI.Theme.TextDim
		Role(descLabel, "TextDim")
		descLabel.TextSize = 12
		descLabel.TextWrapped = true
		descLabel.TextXAlignment = Enum.TextXAlignment.Left
		descLabel.TextYAlignment = Enum.TextYAlignment.Top
		descLabel.Size =
			UDim2.new(1, -(x + (type(rightReserve) == "function" and rightReserve() or rightReserve)), 0, descH)
		descLabel.Position = UDim2.fromOffset(x, titleH + gap)
		descLabel.ZIndex = Z.Content + 1
		descLabel.Parent = card
	end

	local lastWidth = -1
	local lastReserve = -1

	local function relayout()
		local cardW = card.AbsoluteSize.X / GetUIScale()
		if cardW <= 0 then
			return
		end
		local reserve = type(rightReserve) == "function" and rightReserve() or rightReserve
		if math.abs(cardW - lastWidth) < 1 and reserve == lastReserve then
			return
		end
		lastReserve = reserve
		titleLabel.Size = UDim2.new(1, -(x + reserve), 0, titleH)
		lastWidth = cardW

		local avail = math.max(cardW - x - reserve, 1)
		local realDescH = descH
		if hasDesc then
			local _, h = MeasureText(description, 12, avail)
			realDescH = math.max(descH, h)
			descLabel.Size =
				UDim2.new(1, -(x + (type(rightReserve) == "function" and rightReserve() or rightReserve)), 0, realDescH)
		end

		local blockH = hasDesc and (titleH + gap + realDescH) or titleH
		local topPortion = math.max(baseHeight, blockH + 16)
		card.Size = UDim2.new(1, 0, 0, topPortion + extraBottom)

		local top = math.floor((topPortion - blockH) / 2)
		titleLabel.Position = UDim2.fromOffset(x, top)
		if hasDesc then
			descLabel.Position = UDim2.fromOffset(x, top + titleH + gap)
		end
	end

	card:GetPropertyChangedSignal("AbsoluteSize"):Connect(relayout)
	SafeDefer(relayout)

	return titleLabel, descLabel, relayout
end

local function AddEmptyState(scroll, overlayParent, janitor)
	local emptyState = Instance.new("Frame")
	emptyState.Name = "EmptyState"
	emptyState.BackgroundTransparency = 1
	emptyState.Size = UDim2.fromScale(1, 1)
	emptyState.ZIndex = (scroll.ZIndex or 0) + 5
	emptyState.Parent = overlayParent

	local layout = Instance.new("UIListLayout")
	layout.FillDirection = Enum.FillDirection.Vertical
	layout.HorizontalAlignment = Enum.HorizontalAlignment.Center
	layout.VerticalAlignment = Enum.VerticalAlignment.Center
	layout.Padding = UDim.new(0, 6)
	layout.Parent = emptyState

	local icon = Instance.new("ImageLabel")
	icon.BackgroundTransparency = 1
	icon.Image = ResolveIcon("frown")
	icon.ImageColor3 = NullUI.Theme.TextDim
	Role(icon, "TextDim")
	icon.Size = UDim2.fromOffset(26, 26)
	icon.LayoutOrder = 1
	icon.ZIndex = emptyState.ZIndex + 1
	icon.Parent = emptyState

	local label = Instance.new("TextLabel")
	label.BackgroundTransparency = 1
	label.FontFace = NullUI.Theme.FontRegular
	label.Text = "There's nothing here yet"
	label.TextColor3 = NullUI.Theme.TextDim
	Role(label, "TextDim")
	label.TextSize = 13
	label.AutomaticSize = Enum.AutomaticSize.XY
	label.Size = UDim2.fromOffset(0, 16)
	label.LayoutOrder = 2
	label.ZIndex = emptyState.ZIndex + 1
	label.Parent = emptyState

	local function update()
		local hasContent = false
		for _, child in ipairs(scroll:GetChildren()) do
			local cn = child.ClassName
			if cn ~= "UIListLayout" and cn ~= "UIPadding" then
				hasContent = true
				break
			end
		end
		emptyState.Visible = not hasContent
	end

	janitor:Add(scroll.ChildAdded:Connect(update))
	janitor:Add(scroll.ChildRemoved:Connect(update))
	update()

	return emptyState
end

local Window = {}
Window.__index = Window

local Tab = {}
Tab.__index = Tab

-- Fit a window to the screen it is on: phones get almost the full viewport, desktops keep
-- the requested size but never overflow. Sizes are in scaled (offset) units.
local function FitWindowSize(reqW, reqH)
	local vp = ViewportSize()
	local s = GetUIScale()
	local availW, availH = vp.X / s, vp.Y / s
	local w, h = reqW, reqH

	if IsMobileDevice then
		w = math.floor(availW * (availW < availH and 0.94 or 0.7))
		h = math.floor(availH * (availW < availH and 0.72 or 0.94))
	end

	w = math.floor(math.clamp(w, math.min(320, availW - 16), math.max(280, availW - 16)))
	h = math.floor(math.clamp(h, math.min(240, availH - 16), math.max(220, availH - 16)))
	return w, h
end

function NullUI:CreateWindow(opts)
	opts = opts or {}
	local size = opts.Size or UDim2.fromOffset(605, 405)
	local requestedW, requestedH = size.X.Offset, size.Y.Offset

	do
		local w, h = FitWindowSize(requestedW, requestedH)
		size = UDim2.fromOffset(w, h)
	end
	local margin = NullUI.Theme.Margin

	local root = NullUI._Root
	local jan = Janitor.new()

	local main = Instance.new("Frame")
	main.Name = "Window"
	main.AnchorPoint = Vector2.new(0.5, 0.5)
	main.Position = UDim2.fromScale(0.5, IsMobileDevice and 0.5 or 0.55)
	main.Size = size
	main.BackgroundColor3 = NullUI.Theme.Background
	main.BackgroundTransparency = 1
	main.BorderSizePixel = 0
	main.ClipsDescendants = true
	main.ZIndex = Z.Window
	main.Parent = root
	Corner(main, NullUI.Theme.CornerRadius)
	Stroke(main, Color3.new(1, 1, 1), 1, 0.92)
	GlassLayer(main, NullUI.Theme.CornerRadius, 0.985)

	local topbar = Instance.new("Frame")
	topbar.Name = "TopBar"
	topbar.BackgroundTransparency = 1
	topbar.Size = UDim2.new(1, 0, 0, 52)
	topbar.ZIndex = Z.Content
	topbar.Parent = main

	local accentLine = Instance.new("Frame")
	accentLine.Name = "AccentLine"
	accentLine.BackgroundColor3 = NullUI.Theme.Accent
	accentLine.BackgroundTransparency = 0.25
	accentLine.BorderSizePixel = 0
	accentLine.AnchorPoint = Vector2.new(0, 1)
	accentLine.Position = UDim2.new(0, 0, 1, 0)
	accentLine.Size = UDim2.new(1, 0, 0, 1)
	accentLine.ZIndex = Z.Content
	accentLine.Parent = topbar
	accentLine:SetAttribute("NullUIAccent", true)
	Role(accentLine, "Accent")

	local accentLineGradient = Instance.new("UIGradient")
	accentLineGradient.Transparency = NumberSequence.new({
		NumberSequenceKeypoint.new(0, 1),
		NumberSequenceKeypoint.new(0.18, 0.25),
		NumberSequenceKeypoint.new(0.55, 0.6),
		NumberSequenceKeypoint.new(1, 1),
	})
	accentLineGradient.Parent = accentLine

	local controlsHolder = Instance.new("Frame")
	controlsHolder.Name = "WindowControls"
	controlsHolder.AnchorPoint = Vector2.new(1, 0.5)
	controlsHolder.Position = UDim2.new(1, -margin, 0.5, 0)
	controlsHolder.Size = UDim2.fromOffset(120, 26)
	controlsHolder.BackgroundTransparency = 1
	controlsHolder.ZIndex = Z.Content + 1
	controlsHolder.Parent = topbar

	local controlsLayout = Instance.new("UIListLayout")
	controlsLayout.FillDirection = Enum.FillDirection.Horizontal
	controlsLayout.VerticalAlignment = Enum.VerticalAlignment.Center
	controlsLayout.HorizontalAlignment = Enum.HorizontalAlignment.Right
	controlsLayout.Padding = UDim.new(0, 4)
	controlsLayout.SortOrder = Enum.SortOrder.LayoutOrder
	controlsLayout.Parent = controlsHolder

	local function addControl(icon, name, order, hoverColor)
		local btn = Instance.new("TextButton")
		btn.Name = name
		btn.Text = ""
		btn.AutoButtonColor = false
		btn.BackgroundColor3 = Color3.new(1, 1, 1)
		btn.BackgroundTransparency = 1
		btn.BorderSizePixel = 0
		btn.Size = UDim2.fromOffset(26, 26)
		btn.LayoutOrder = order
		btn.ZIndex = Z.Content + 1
		btn.Parent = controlsHolder
		Corner(btn, 8)

		local ic = Instance.new("ImageLabel")
		ic.BackgroundTransparency = 1
		ic.Image = ResolveIcon(icon)
		ic.ImageColor3 = NullUI.Theme.TextDim
		Role(ic, "TextDim")
		ic.Size = UDim2.fromOffset(14, 14)
		ic.AnchorPoint = Vector2.new(0.5, 0.5)
		ic.Position = UDim2.fromScale(0.5, 0.5)
		ic.ZIndex = Z.Content + 2
		ic.Parent = btn

		jan:Add(btn.MouseEnter:Connect(function()
			Tween(btn, { BackgroundTransparency = 0.9 }, 0.12)
			Tween(ic, { ImageColor3 = hoverColor or NullUI.Theme.Text }, 0.12)
		end))
		jan:Add(btn.MouseLeave:Connect(function()
			Tween(btn, { BackgroundTransparency = 1 }, 0.12)
			Tween(ic, { ImageColor3 = NullUI.Theme.TextDim }, 0.12)
		end))
		return btn
	end

	local searchBtn = addControl("search", "SearchButton", 1)
	local minBtn = addControl("minus", "MinimizeButton", 2)
	local fullBtn = addControl("maximize", "FullscreenButton", 3)
	local closeBtn = addControl("x", "CloseButton", 4)

	local titleStartX = margin + 5
	local titleTextPad = 146

	local hasIcon = opts.Icon and opts.Icon ~= ""
	if hasIcon then
		local windowIcon = Instance.new("ImageLabel")
		windowIcon.Name = "WindowIcon"
		windowIcon.BackgroundTransparency = 1
		windowIcon.Image = ResolveIcon(opts.Icon)
		windowIcon.ImageColor3 = NullUI.Theme.Text
		Role(windowIcon, "Text")
		windowIcon.Size = UDim2.fromOffset(20, 20)
		windowIcon.AnchorPoint = Vector2.new(0, 0.5)
		windowIcon.Position = UDim2.new(0, titleStartX, 0.5, 0)
		windowIcon.ZIndex = Z.Content
		windowIcon.Parent = topbar
		titleStartX += 20 + 8
	end

	local titleLabel = Instance.new("TextLabel")
	titleLabel.Name = "Title"
	titleLabel.BackgroundTransparency = 1
	titleLabel.FontFace = NullUI.Theme.Font
	titleLabel.Text = opts.Title or "Window"
	titleLabel.TextColor3 = NullUI.Theme.Text
	Role(titleLabel, "Text")
	titleLabel.TextSize = 16
	titleLabel.TextXAlignment = Enum.TextXAlignment.Left
	titleLabel.TextYAlignment = Enum.TextYAlignment.Center
	titleLabel.TextTruncate = Enum.TextTruncate.AtEnd
	titleLabel.Position = UDim2.fromOffset(titleStartX, opts.Subtitle and 8 or 0)
	titleLabel.Size = UDim2.new(1, -titleStartX - titleTextPad, 0, 20)
	titleLabel.ZIndex = Z.Content
	titleLabel.Parent = topbar

	local subLabel
	if opts.Subtitle then
		subLabel = Instance.new("TextLabel")
		subLabel.Name = "Subtitle"
		subLabel.BackgroundTransparency = 1
		subLabel.FontFace = NullUI.Theme.FontRegular
		subLabel.Text = opts.Subtitle
		subLabel.TextColor3 = NullUI.Theme.TextDim
		Role(subLabel, "TextDim")
		subLabel.TextSize = 13
		subLabel.TextXAlignment = Enum.TextXAlignment.Left
		subLabel.TextYAlignment = Enum.TextYAlignment.Center
		subLabel.TextTruncate = Enum.TextTruncate.AtEnd
		subLabel.Position = UDim2.fromOffset(titleStartX, 28)
		subLabel.Size = UDim2.new(1, -titleStartX - titleTextPad, 0, 14)
		subLabel.ZIndex = Z.Content
		subLabel.Parent = topbar
	end

	-- Scripts with long tab names can widen the rail; everything that sizes
	-- against it reads self._tabWidth.
	local tabWidth = math.clamp(tonumber(opts.TabWidth) or 130, 90, 260)

	local tabBar = Instance.new("ScrollingFrame")
	tabBar.Name = "TabBar"
	tabBar.BackgroundTransparency = 1
	tabBar.BorderSizePixel = 0
	tabBar.Position = UDim2.fromOffset(margin, 58)
	tabBar.Size = UDim2.new(0, tabWidth, 1, -(58 + margin))
	tabBar.ScrollBarThickness = 0
	tabBar.ScrollingDirection = Enum.ScrollingDirection.Y
	tabBar.AutomaticCanvasSize = Enum.AutomaticSize.Y
	tabBar.CanvasSize = UDim2.new(0, 0, 0, 0)
	tabBar.ZIndex = Z.Content
	tabBar.Parent = main

	local tabBarLayout = Instance.new("UIListLayout")
	tabBarLayout.Padding = UDim.new(0, 4)
	tabBarLayout.SortOrder = Enum.SortOrder.LayoutOrder
	tabBarLayout.Parent = tabBar

	AddScrollbar(tabBar)
	-- Many tabs (or a short window) must stay reachable: the rail scrolls and shows
	-- a slim thumb only while there is something to scroll to.
	tabBar.ScrollingEnabled = true
	tabBar.ElasticBehavior = Enum.ElasticBehavior.WhenScrollable
	AddContentScrollThumb(tabBar, tabBarLayout, main, jan)

	local tabIndicatorLayer = Instance.new("Frame")
	tabIndicatorLayer.Name = "TabIndicatorLayer"
	tabIndicatorLayer.BackgroundTransparency = 1
	tabIndicatorLayer.ClipsDescendants = true
	tabIndicatorLayer.ZIndex = Z.Window
	tabIndicatorLayer.Position = tabBar.Position
	tabIndicatorLayer.Size = tabBar.Size
	tabIndicatorLayer.Parent = main

	local tabIndicator = Instance.new("Frame")
	tabIndicator.Name = "Indicator"
	tabIndicator.BackgroundColor3 = Color3.new(1, 1, 1)
	tabIndicator.BackgroundTransparency = 1
	tabIndicator.BorderSizePixel = 0
	tabIndicator.ZIndex = Z.Window
	tabIndicator.Size = UDim2.new(1, 0, 0, 34)
	tabIndicator.Position = UDim2.new(0, 0, 0, 0)
	tabIndicator.Parent = tabIndicatorLayer
	Corner(tabIndicator, 10)

	local indicatorGradient = Instance.new("UIGradient")
	indicatorGradient.Transparency = NumberSequence.new({
		NumberSequenceKeypoint.new(0, 0),
		NumberSequenceKeypoint.new(1, 0.65),
	})
	indicatorGradient.Parent = tabIndicator

	local indicatorBar = Instance.new("Frame")
	indicatorBar.Name = "AccentBar"
	indicatorBar.BackgroundColor3 = NullUI.Theme.Accent
	indicatorBar.BackgroundTransparency = 0.15
	indicatorBar.BorderSizePixel = 0
	indicatorBar.AnchorPoint = Vector2.new(0, 0.5)
	indicatorBar.Position = UDim2.new(0, 0, 0.5, 0)
	indicatorBar.Size = UDim2.new(0, 3, 0, 18)
	indicatorBar.ZIndex = tabIndicator.ZIndex + 1
	indicatorBar.Parent = tabIndicator
	indicatorBar:SetAttribute("NullUIAccent", true)
	Role(indicatorBar, "Accent")
	Corner(indicatorBar, 2)

	local divider = Instance.new("Frame")
	divider.Name = "Divider"
	divider.BackgroundColor3 = Color3.new(1, 1, 1)
	divider.BackgroundTransparency = 0.94
	divider.BorderSizePixel = 0
	divider.Position = UDim2.new(0, margin + tabWidth + 14, 0, 58)
	divider.Size = UDim2.new(0, 1, 1, -(58 + margin))
	divider.ZIndex = Z.Content
	divider.Parent = main

	local contentX = margin + tabWidth + 30
	local content = Instance.new("Frame")
	content.Name = "Content"
	content.BackgroundTransparency = 1
	content.Position = UDim2.new(0, contentX, 0, 58)
	content.Size = UDim2.new(1, -contentX - margin, 1, -(58 + margin))
	content.ZIndex = Z.Content
	content.Parent = main

	-- The grips live outside the window (main clips its children) on a frame that
	-- mirrors the window, and stay invisible until the pointer or a touch needs them.
	local edge = Instance.new("Frame")
	edge.Name = "WindowEdge"
	edge.BackgroundTransparency = 1
	edge.AnchorPoint = main.AnchorPoint
	edge.Position = main.Position
	edge.Size = main.Size
	edge.Visible = false
	edge.ZIndex = Z.Content + 4
	edge.Parent = root
	jan:Add(edge)
	local function syncEdge()
		edge.Position = main.Position
		edge.Size = main.Size
	end
	jan:Add(main:GetPropertyChangedSignal("Position"):Connect(syncEdge))
	jan:Add(main:GetPropertyChangedSignal("Size"):Connect(syncEdge))
	jan:Add(main:GetPropertyChangedSignal("Visible"):Connect(function()
		edge.Visible = main.Visible
	end))

	local gripAlpha = IsMobileDevice and 0.2 or 0.35
	local resizeHandle = Instance.new("ImageButton")
	resizeHandle.Name = "ResizeHandle"
	resizeHandle.BackgroundTransparency = 1
	resizeHandle.AutoButtonColor = false
	resizeHandle.Image = ""
	resizeHandle.AnchorPoint = Vector2.new(0, 0)
	resizeHandle.Position = UDim2.new(1, IsMobileDevice and -26 or -20, 1, IsMobileDevice and -26 or -20)
	resizeHandle.Size = IsMobileDevice and UDim2.fromOffset(52, 52) or UDim2.fromOffset(40, 40)
	resizeHandle.ZIndex = Z.Content + 4
	resizeHandle.Parent = edge

	local arcClip = Instance.new("Frame")
	arcClip.Name = "ArcClip"
	arcClip.BackgroundTransparency = 1
	arcClip.ClipsDescendants = true
	arcClip.Position = UDim2.fromOffset(IsMobileDevice and 10 or 4, IsMobileDevice and 10 or 4)
	arcClip.Size = UDim2.fromOffset(22, 22)
	arcClip.ZIndex = Z.Content + 4
	arcClip.Parent = resizeHandle

	local arc = Instance.new("Frame")
	arc.Name = "Arc"
	arc.BackgroundTransparency = 1
	arc.Position = UDim2.fromOffset(-18, -18)
	arc.Size = UDim2.fromOffset(36, 36)
	arc.ZIndex = Z.Content + 4
	arc.Parent = arcClip
	Corner(arc, 18)
	local arcStroke = Stroke(arc, NullUI.Theme.TextDim, 2.5, 1)
	Role(arcStroke, "TextDim")

	local gripHit = Instance.new("Frame")
	gripHit.Name = "GripHandle"
	gripHit.BackgroundTransparency = 1
	gripHit.Active = true
	gripHit.AnchorPoint = Vector2.new(0.5, 0)
	gripHit.Position = UDim2.new(0.5, 0, 1, 0)
	gripHit.Size = IsMobileDevice and UDim2.fromOffset(160, 30) or UDim2.fromOffset(130, 22)
	gripHit.ZIndex = Z.Content + 4
	gripHit.Parent = edge

	local gripPill = Instance.new("Frame")
	gripPill.Name = "Pill"
	gripPill.BackgroundColor3 = NullUI.Theme.TextDim
	gripPill.BackgroundTransparency = 1
	gripPill.BorderSizePixel = 0
	gripPill.AnchorPoint = Vector2.new(0.5, 0)
	gripPill.Position = UDim2.new(0.5, 0, 0, IsMobileDevice and 6 or 4)
	gripPill.Size = UDim2.fromOffset(IsMobileDevice and 120 or 100, IsMobileDevice and 5 or 4)
	gripPill.ZIndex = Z.Content + 4
	gripPill.Parent = gripHit
	Corner(gripPill, 3)
	Role(gripPill, "TextDim")

	local gripShown = false
	local gripToken = 0
	local gripHeld = 0
	local function paintGrip(alpha)
		Tween(arcStroke, { Transparency = alpha }, 0.18)
		Tween(gripPill, { BackgroundTransparency = alpha }, 0.18)
	end
	local function showGrip(strong)
		gripToken += 1
		gripShown = true
		paintGrip(strong and 0 or gripAlpha)
	end
	local function hideGripLater(delay)
		gripToken += 1
		local token = gripToken
		SafeDelay(delay or 1.2, function()
			if token == gripToken and gripHeld <= 0 then
				gripShown = false
				paintGrip(1)
			end
		end)
	end

	for _, handle in ipairs({ resizeHandle, gripHit }) do
		jan:Add(handle.MouseEnter:Connect(function()
			showGrip(true)
		end))
		jan:Add(handle.MouseLeave:Connect(function()
			showGrip(false)
			hideGripLater(1)
		end))
		jan:Add(handle.InputBegan:Connect(function(input)
			if input.UserInputType == Enum.UserInputType.MouseButton1 or input.UserInputType == Enum.UserInputType.Touch then
				gripHeld += 1
				showGrip(true)
				local ended
				ended = input.Changed:Connect(function()
					if input.UserInputState == Enum.UserInputState.End then
						ended:Disconnect()
						gripHeld = math.max(gripHeld - 1, 0)
						hideGripLater(IsMobileDevice and 2 or 1)
					end
				end)
			end
		end))
	end
	jan:Add(main.MouseEnter:Connect(function()
		if not IsMobileDevice then
			showGrip(false)
		end
	end))
	jan:Add(main.MouseLeave:Connect(function()
		hideGripLater(0.8)
	end))
	jan:Add(main.InputBegan:Connect(function(input)
		if input.UserInputType == Enum.UserInputType.Touch then
			showGrip(false)
			hideGripLater(2.5)
		end
	end))
	edge.Visible = true
	Tween(main, { BackgroundTransparency = 0.15 }, 0.6, Enum.EasingStyle.Exponential)

	local self = setmetatable({
		_gui = main,
		_content = content,
		_tabBar = tabBar,
		_tabWidth = tabWidth,
		_tabIndicatorLayer = tabIndicatorLayer,
		_tabIndicator = tabIndicator,
		_divider = divider,
		_resizeHandle = resizeHandle,
		_gripHandle = gripHit,
		_titleLabel = titleLabel,
		_subLabel = subLabel,
		_tabs = {},
		_currentTab = nil,
		_normalSize = size,
		_requestedSize = Vector2.new(requestedW, requestedH),
		_userSized = false,
		_fullscreen = false,
		_janitor = jan,
		_state = "open",
		_busy = false,
		_destroyed = false,
		_onClose = opts.OnClose,
		_autoUnload = opts.AutoUnload,
		Closed = MakeSignal(),
		_searchIndex = {},
		_useBlur = opts.UseBlur ~= false,
		_defaultTabName = opts.DefaultTab,
		_tabChangeListeners = {},
	}, Window)

	table.insert(NullUI._Windows, self)

	if opts.Draggable ~= false then
		self._drag = SetupSmoothDrag(main, topbar, jan, { gripHit })
	end

	if opts.Resizable ~= false then
		SetupResize(main, resizeHandle, jan, {
			-- No mobile o minimo nao pode ser maior que a janela ja clampada, senao um
			-- resize devolve a janela pro tamanho cortado.
			MinSize = Vector2.new(
				math.min((opts.MinSize or Vector2.new(420, 300)).X, size.X.Offset),
				math.min((opts.MinSize or Vector2.new(420, 300)).Y, size.Y.Offset)
			),
			OnResize = function(newSize, finished)
				if self._fullscreen then
					return
				end
				if finished then
					self._normalSize = newSize
					self._sizeBeforeMinimize = newSize
					self._userSized = true
				end
			end,
		})
	else
		resizeHandle.Visible = false
	end

	if self._useBlur then
		self._acrylic = CreateWindowAcrylic(main)
		jan:Add(self._acrylic)
	end

	jan:Add(closeBtn.MouseButton1Click:Connect(function()
		NullUI:Confirm({
			Title = "Close Window",
			Text = "This unloads the interface completely: every panel, button and background task is removed "
				.. "and you will have to run the script again. To just hide it, use the minimize button.",
			ConfirmText = "Close & Unload",
			CancelText = "Cancel",
			Danger = true,
			Window = self,
			Callback = function(confirmed)
				if confirmed then
					self:Destroy()
				end
			end,
		})
	end))

	jan:Add(minBtn.MouseButton1Click:Connect(function()
		if self._state == "collapsed" then
			self:Expand()
		else
			self:Collapse()
		end
	end))
	jan:Add(fullBtn.MouseButton1Click:Connect(function()
		self:ToggleFullscreen()
	end))
	jan:Add(searchBtn.MouseButton1Click:Connect(function()
		self:_OpenSearch()
	end))

	jan:Add(UserInputService.InputBegan:Connect(function(input, gameProcessed)
		if gameProcessed or KeybindCapturing then
			return
		end
		if self._state ~= "open" then
			return
		end
		local ctrlDown = UserInputService:IsKeyDown(Enum.KeyCode.LeftControl)
			or UserInputService:IsKeyDown(Enum.KeyCode.RightControl)
			or UserInputService:IsKeyDown(Enum.KeyCode.LeftMeta)
			or UserInputService:IsKeyDown(Enum.KeyCode.RightMeta)
		if ctrlDown and input.KeyCode == Enum.KeyCode.K then
			self:_OpenSearch()
		end
	end))

	local toggleKey = opts.ToggleKeybind
	if toggleKey == nil then
		toggleKey = Enum.KeyCode.RightShift
	end
	self._toggleKey = toggleKey

	-- gameProcessed is not checked here on purpose: games bind keys like LeftControl
	-- themselves, and the toggle still has to work while they do.
	jan:Add(UserInputService.InputBegan:Connect(function(input)
		if KeybindCapturing or not self._toggleKey then
			return
		end
		if UserInputService:GetFocusedTextBox() then
			return
		end
		if input.UserInputType == Enum.UserInputType.Keyboard and input.KeyCode == self._toggleKey then
			self:ToggleVisibility()
		end
	end))

	-- Floating launcher (same idea as FluentCustom's round button): a draggable ring that
	-- shows/hides the window on every platform. Pass LauncherButton = false to disable it,
	-- LauncherImage for a custom picture and TogglePosition to place it.
	local showLauncher = opts.LauncherButton
	if showLauncher == nil then
		showLauncher = true
	end
	if showLauncher then
		local mobileToggle = Instance.new("Frame")
		mobileToggle.Name = "LauncherButton"
		mobileToggle.Active = true
		mobileToggle.BackgroundColor3 = Color3.new(1, 1, 1)
		mobileToggle.BackgroundTransparency = 0
		mobileToggle.BorderSizePixel = 0
		local toggleSize = 52
		-- The root is scaled by GlobalScale, so divide by it: the button is then 52px at
		-- (50, 50) on screen on every device, exactly like FluentCustom's.
		local launcherMoved = false
		local function launcherPx(n)
			return n / GetUIScale()
		end

		mobileToggle.AnchorPoint = Vector2.new(0, 0)
		mobileToggle.Position = opts.TogglePosition or UDim2.fromOffset(launcherPx(50), launcherPx(50))
		mobileToggle.Size = UDim2.fromOffset(launcherPx(toggleSize), launcherPx(toggleSize))
		mobileToggle.ZIndex = Z.Toast
		mobileToggle.Parent = root

		local mobileToggleCorner = Instance.new("UICorner")
		mobileToggleCorner.CornerRadius = UDim.new(1, 0)
		mobileToggleCorner.Parent = mobileToggle

		local ringStroke = Instance.new("UIStroke")
		ringStroke.Color = Color3.fromRGB(0, 255, 255)
		ringStroke.Thickness = 2
		ringStroke.Parent = mobileToggle

		-- Glows while the window is hidden, like Fluent's button.
		local glowStroke = Instance.new("UIStroke")
		glowStroke.Color = Color3.fromRGB(0, 255, 255)
		glowStroke.Thickness = 4
		glowStroke.Transparency = 0.55
		glowStroke.Enabled = false
		glowStroke.Parent = mobileToggle

		local launcherImage = Instance.new("ImageLabel")
		launcherImage.Name = "Picture"
		launcherImage.BackgroundTransparency = 1
		launcherImage.AnchorPoint = Vector2.new(0.5, 0.5)
		launcherImage.Position = UDim2.fromScale(0.5, 0.5)
		launcherImage.Size = UDim2.new(1, -4, 1, -4)
		launcherImage.Image = opts.LauncherImage or "rbxassetid://87167480222237"
		launcherImage.ZIndex = Z.Toast + 1
		launcherImage.Parent = mobileToggle
		local launcherImageCorner = Instance.new("UICorner")
		launcherImageCorner.CornerRadius = UDim.new(1, 0)
		launcherImageCorner.Parent = launcherImage

		-- Auto-scale can change after load; keep the size and, until it is dragged, the spot.
		jan:Add(GlobalScale:GetPropertyChangedSignal("Scale"):Connect(function()
			mobileToggle.Size = UDim2.fromOffset(launcherPx(toggleSize), launcherPx(toggleSize))
			if not launcherMoved and not opts.TogglePosition then
				mobileToggle.Position = UDim2.fromOffset(launcherPx(50), launcherPx(50))
			end
		end))

		jan:Add(mobileToggle.MouseEnter:Connect(function()
			Tween(launcherImage, { Size = UDim2.new(1, 2, 1, 2) }, 0.2)
		end))
		jan:Add(mobileToggle.MouseLeave:Connect(function()
			Tween(launcherImage, { Size = UDim2.new(1, -4, 1, -4) }, 0.2)
		end))

		SafeSpawn(function()
			while not self._destroyed and mobileToggle.Parent do
				glowStroke.Enabled = self._state ~= "open"
				task.wait(0.15)
			end
		end)

		-- Draggable is deprecated and swallows touch input (Activated never fires),
		-- so drive the drag by hand and treat a touch that barely moved as a tap.
		local DRAG_SLOP = 8
		local dragInput, dragStart, startPos, dragged

		jan:Add(mobileToggle.InputBegan:Connect(function(input)
			if
				input.UserInputType ~= Enum.UserInputType.Touch
				and input.UserInputType ~= Enum.UserInputType.MouseButton1
			then
				return
			end
			if dragInput then
				return
			end
			dragInput = input
			dragStart = input.Position
			startPos = mobileToggle.Position
			dragged = false
		end))

		jan:Add(UserInputService.InputChanged:Connect(function(input)
			LPH_ATTRIBUTES(VM(NONE))
			if not dragInput or not dragStart then
				return
			end
			-- A touch keeps one InputObject for the whole gesture, but a held mouse button
			-- does not: its movement arrives as separate MouseMovement objects.
			local isMouseDrag = dragInput.UserInputType == Enum.UserInputType.MouseButton1
				and input.UserInputType == Enum.UserInputType.MouseMovement
			if input ~= dragInput and not isMouseDrag then
				return
			end
			local delta = input.Position - dragStart
			if not dragged and delta.Magnitude > DRAG_SLOP then
				dragged = true
				launcherMoved = true
			end
			if not dragged then
				return
			end
			local s = GetUIScale()
			mobileToggle.Position = UDim2.new(
				startPos.X.Scale,
				startPos.X.Offset + delta.X / s,
				startPos.Y.Scale,
				startPos.Y.Offset + delta.Y / s
			)
		end))

		jan:Add(UserInputService.InputEnded:Connect(function(input)
			if not dragInput then
				return
			end
			-- Release of the same touch/button that started the drag.
			if input ~= dragInput and input.UserInputType ~= dragInput.UserInputType then
				return
			end
			dragInput, dragStart = nil, nil
			if not dragged then
				self:ToggleVisibility()
			end
		end))

		jan:Add(mobileToggle)
	end

	if not IsMobileDevice and toggleKey then
		NullUI:Notify({
			Title = "Minimize Keybind",
			Text = "Press " .. toggleKey.Name .. " to minimize or open this panel.",
			Type = "info",
			Duration = 15,
		})
	end

	return self
end

function Window:SetTitle(title, subtitle)
	if self._titleLabel then
		self._titleLabel.Text = title or self._titleLabel.Text
	end
	if subtitle and self._subLabel then
		self._subLabel.Text = subtitle
	end
end

function Window:IsOpen()
	return self._state == "open"
end

function Window:Destroy()
	if self._destroyed then
		return
	end
	self._destroyed = true

	local idx = table.find(NullUI._Windows, self)
	if idx then
		table.remove(NullUI._Windows, idx)
	end

	CloseAnyOpenPopup()

	local gui = self._gui

	Tween(gui, {
		Size = UDim2.new(gui.Size.X.Scale, gui.Size.X.Offset, 0, 0),
	}, 0.32, Enum.EasingStyle.Quint, Enum.EasingDirection.In)
	Tween(gui, { BackgroundTransparency = 1 }, 0.32, Enum.EasingStyle.Quint, Enum.EasingDirection.In)

	SafeDelay(0.34, function()
		self._janitor:Destroy()
		if gui then
			gui:Destroy()
		end

		if self.Closed then
			self.Closed.Fire(self)
		end
		if type(self._onClose) == "function" then
			SafeSpawn(self._onClose, self)
		end

		if #NullUI._Windows == 0 and self._autoUnload ~= false then
			SafeDefer(function()
				if #NullUI._Windows == 0 then
					NullUI:Unload()
				end
			end)
		end
	end)
end

local COLLAPSED_HEIGHT = 52

-- The minimise button walks three states: open -> title bar only -> hidden.
function Window:Toggle()
	if self._destroyed or self._busy then
		return
	end
	if self._state == "open" then
		self:Collapse()
	elseif self._state == "collapsed" then
		self:Close()
	else
		self:Open()
	end
end

-- Plain show/hide used by the launcher button and the keybind: no title-bar
-- stop in between, it either shows the whole window or nothing.
-- The key that shows and hides the window, changeable while the script runs.
function Window:SetToggleKey(key)
	if typeof(key) == "EnumItem" and key.EnumType == Enum.KeyCode then
		self._toggleKey = key
	elseif key == nil or key == false then
		self._toggleKey = nil
	end
	return self._toggleKey
end

function Window:GetToggleKey()
	return self._toggleKey
end

function Window:ToggleVisibility()
	if self._destroyed or self._busy then
		return
	end
	if self._state == "closed" then
		self:Open()
	else
		self:Close()
	end
end

-- Lazily created UIScale used for the open/close motion so the window can zoom
-- without fighting the responsive size that lives on Size itself.
function Window:GetWindowScale()
	local existing = self._gui:FindFirstChild("WindowFxScale")
	if existing then
		return existing
	end
	local fx = Instance.new("UIScale")
	fx.Name = "WindowFxScale"
	fx.Scale = 1
	fx.Parent = self._gui
	return fx
end

function Window:SetChromeVisible(visible)
	for _, key in ipairs({ "_tabBar", "_tabIndicatorLayer", "_divider", "_dock", "_resizeHandle", "_gripHandle" }) do
		local obj = self[key]
		if obj then
			obj.Visible = visible
		end
	end
end

function Window:Collapse()
	if self._destroyed or self._busy or self._state ~= "open" then
		return
	end
	self._busy = true
	self._state = "collapsed"

	CloseAnyOpenPopup()

	local gui = self._gui
	self._sizeBeforeMinimize = self._fullscreen and UDim2.new(0.94, 0, 0.9, 0) or (self._normalSize or gui.Size)

	self:SetChromeVisible(false)
	if self._content then
		self._content.Visible = false
	end

	Tween(gui, {
		Size = UDim2.new(gui.Size.X.Scale, gui.Size.X.Offset, 0, COLLAPSED_HEIGHT),
	}, MOTION.Slow, MOTION.Style, MOTION.Direction)

	SafeDelay(MOTION.Slow + 0.02, function()
		self._busy = false
	end)
end

function Window:Expand()
	if self._destroyed or self._busy or self._state ~= "collapsed" then
		return
	end
	self._busy = true
	self._state = "open"

	local gui = self._gui
	Tween(gui, {
		Size = self._sizeBeforeMinimize or self._normalSize,
	}, MOTION.Surface, MOTION.Style, MOTION.Direction)

	SafeDelay(MOTION.Fast, function()
		if self._destroyed or self._state ~= "open" then
			return
		end
		self:SetChromeVisible(true)
		if self._content then
			self._content.Visible = true
		end
	end)

	SafeDelay(MOTION.Surface + 0.02, function()
		self._busy = false
		if self._drag then
			self._drag.Sync()
		end
	end)
end

function Window:Close()
	if self._destroyed or self._busy or (self._state ~= "open" and self._state ~= "collapsed") then
		return
	end
	local wasCollapsed = self._state == "collapsed"
	self._busy = true
	self._state = "closed"

	CloseAnyOpenPopup()

	local gui = self._gui
	if not wasCollapsed then
		self._sizeBeforeMinimize = self._fullscreen and UDim2.new(0.94, 0, 0.9, 0) or (self._normalSize or gui.Size)
	end

	-- Recede towards the centre with a fade instead of squashing the height to
	-- zero: reads as the window stepping back, and never leaves a 1px sliver.
	local fx = self:GetWindowScale()
	Tween(fx, { Scale = 0.92 }, MOTION.Slow, Enum.EasingStyle.Quad, Enum.EasingDirection.In)
	Tween(gui, { BackgroundTransparency = 1 }, MOTION.Slow, Enum.EasingStyle.Quad, Enum.EasingDirection.In)
	SafeDelay(MOTION.Slow + 0.02, function()
		if self._destroyed then
			return
		end
		if self._state == "closed" and gui and gui.Parent then
			gui.Visible = false
			gui.Size = self._sizeBeforeMinimize or gui.Size
		end
		self._busy = false
	end)
end

function Window:Open()
	if self._destroyed or self._busy or self._state ~= "closed" then
		return
	end
	self._busy = true
	self._state = "open"

	local gui = self._gui
	gui.Visible = true
	self:SetChromeVisible(true)
	if self._content then
		self._content.Visible = true
	end

	local targetSize = self._sizeBeforeMinimize or self._normalSize
	gui.Size = targetSize

	local fx = self:GetWindowScale()
	fx.Scale = 0.92
	Tween(fx, { Scale = 1 }, MOTION.Surface, Enum.EasingStyle.Quint, Enum.EasingDirection.Out)
	Tween(gui, { BackgroundTransparency = 0.15 }, MOTION.Normal, MOTION.Style, MOTION.Direction)

	SafeDelay(MOTION.Surface + 0.02, function()
		self._busy = false
		if self._drag then
			self._drag.Sync()
		end
	end)
end

function Window:ToggleFullscreen()
	if self._destroyed or self._state ~= "open" then
		return
	end
	local gui = self._gui
	self._fullscreen = not self._fullscreen

	CloseAnyOpenPopup()
	RefreshUIScale()

	if self._fullscreen then
		self._preFullscreenPosition = gui.Position
		Tween(gui, {
			Size = UDim2.new(0.94, 0, 0.9, 0),
			Position = UDim2.fromScale(0.5, 0.5),
		}, 0.32, Enum.EasingStyle.Quint)
	else
		Tween(gui, {
			Size = self._normalSize,
			Position = self._preFullscreenPosition or UDim2.fromScale(0.5, 0.55),
		}, 0.32, Enum.EasingStyle.Quint)
	end

	SafeDelay(0.36, function()
		if self._drag then
			self._drag.Sync()
		end
	end)
end

-- Called after the game window (and so the UI scale) changed: a window nobody resized by
-- hand follows the new screen size, a hand-sized one only shrinks when it would overflow.
function Window:Refit()
	if self._destroyed or not self._gui or not self._gui.Parent then
		return
	end
	local vp = ViewportSize()
	local s = GetUIScale()
	local availW, availH = vp.X / s, vp.Y / s
	local cur = self._normalSize
	local w, h
	if self._userSized then
		w = math.min(cur.X.Offset, availW - 16)
		h = math.min(cur.Y.Offset, availH - 16)
		w = math.max(w, math.min(320, availW - 16))
		h = math.max(h, math.min(240, availH - 16))
	else
		w, h = FitWindowSize(self._requestedSize.X, self._requestedSize.Y)
	end
	local new = UDim2.fromOffset(math.floor(w), math.floor(h))
	if new == cur then
		return
	end
	self._normalSize = new
	if self._fullscreen then
		self._sizeBeforeMinimize = UDim2.new(0.94, 0, 0.9, 0)
		return
	end
	self._sizeBeforeMinimize = new
	if self._state == "open" then
		Tween(self._gui, { Size = new }, MOTION.Surface, MOTION.Style, MOTION.Direction)
	elseif self._state == "collapsed" then
		self._gui.Size = UDim2.new(0, new.X.Offset, 0, COLLAPSED_HEIGHT)
	else
		self._gui.Size = new
	end
	SafeDelay(MOTION.Surface + 0.05, function()
		if not self._destroyed and self._drag then
			self._drag.Sync()
		end
	end)
end

RefitAllWindows = function()
	for _, window in ipairs(NullUI._Windows) do
		pcall(window.Refit, window)
	end
end

function Window:AddTabLine()
	local holder = Instance.new("Frame")
	holder.Name = "TabLine"
	holder.BackgroundTransparency = 1
	holder.Size = UDim2.new(1, 0, 0, 9)
	holder.ZIndex = Z.Content
	holder.Parent = self._tabBar

	local line = Instance.new("Frame")
	line.AnchorPoint = Vector2.new(0, 0.5)
	line.Position = UDim2.new(0, 4, 0.5, 0)
	line.Size = UDim2.new(1, -8, 0, 1)
	line.BackgroundColor3 = Color3.new(1, 1, 1)
	line.BackgroundTransparency = 0.92
	line.BorderSizePixel = 0
	line.ZIndex = Z.Content
	line.Parent = holder

	return holder
end

local DOCK_ICON_SIZE = 28
local DOCK_HEIGHT = 34

function Window:AddDockButton(opts)
	opts = opts or {}
	local jan = self._janitor
	local margin = NullUI.Theme.Margin

	if not self._dock then
		local shrunkSize = UDim2.new(0, self._tabWidth or 130, 1, -(58 + margin + DOCK_HEIGHT + 10))
		self._tabBar.Size = shrunkSize
		self._tabIndicatorLayer.Size = shrunkSize

		local dock = Instance.new("Frame")
		dock.Name = "Dock"
		dock.BackgroundTransparency = 1
		dock.AnchorPoint = Vector2.new(0, 1)
		dock.Position = UDim2.new(0, margin, 1, -margin)
		dock.Size = UDim2.new(0, self._tabWidth or 130, 0, DOCK_HEIGHT)
		dock.ZIndex = Z.Content
		dock.Parent = self._gui

		local dockLayout = Instance.new("UIListLayout")
		dockLayout.FillDirection = Enum.FillDirection.Horizontal
		dockLayout.Padding = UDim.new(0, 6)
		dockLayout.SortOrder = Enum.SortOrder.LayoutOrder
		dockLayout.Parent = dock

		self._dock = dock
	end

	local btn = Instance.new("TextButton")
	btn.Name = opts.Name or "DockButton"
	btn.Text = ""
	btn.AutoButtonColor = false
	btn.BackgroundColor3 = Color3.new(1, 1, 1)
	btn.BackgroundTransparency = 0.95
	btn.BorderSizePixel = 0
	btn.Size = UDim2.fromOffset(DOCK_ICON_SIZE, DOCK_ICON_SIZE)
	btn.LayoutOrder = #self._dock:GetChildren()
	btn.ZIndex = Z.Content + 1
	btn.Parent = self._dock
	Corner(btn, 8)

	local icon = Instance.new("ImageLabel")
	icon.BackgroundTransparency = 1
	icon.Image = opts.Icon and ResolveIcon(opts.Icon) or ""
	icon.ImageColor3 = NullUI.Theme.TextDim
	Role(icon, "TextDim")
	icon.Size = UDim2.fromOffset(15, 15)
	icon.AnchorPoint = Vector2.new(0.5, 0.5)
	icon.Position = UDim2.fromScale(0.5, 0.5)
	icon.ZIndex = Z.Content + 2
	icon.Parent = btn

	local active = false

	jan:Add(btn.MouseEnter:Connect(function()
		if active then
			return
		end
		Tween(btn, { BackgroundTransparency = 0.85 }, 0.12)
		Tween(icon, { ImageColor3 = NullUI.Theme.Text }, 0.12)
	end))
	jan:Add(btn.MouseLeave:Connect(function()
		if active then
			return
		end
		Tween(btn, { BackgroundTransparency = 0.95 }, 0.12)
		Tween(icon, { ImageColor3 = NullUI.Theme.TextDim }, 0.12)
	end))
	jan:Add(btn.MouseButton1Click:Connect(function()
		if opts.Callback then
			SafeSpawn(opts.Callback)
		end
	end))

	return {
		Instance = btn,
		Icon = icon,
		SetActive = function(_, isActive)
			active = isActive and true or false
			Tween(btn, { BackgroundTransparency = active and 0.8 or 0.95 }, 0.12)
			Tween(icon, { ImageColor3 = active and NullUI.Theme.Text or NullUI.Theme.TextDim }, 0.12)
		end,
	}
end

local CHAT_CODE_FONT = "rbxasset://fonts/families/RobotoMono.json"

local function EscapeRichText(text)
	text = text:gsub("&", "&amp;")
	text = text:gsub("<", "&lt;")
	text = text:gsub(">", "&gt;")
	return text
end

local function MarkdownToRichText(text)
	text = EscapeRichText(text)

	text = text:gsub("`([^`\n]+)`", '<font family="' .. CHAT_CODE_FONT .. '">%1</font>')

	text = text:gsub("%*%*(.-)%*%*", "<b>%1</b>")
	text = text:gsub("__(.-)__", "<b>%1</b>")

	text = text:gsub("%*([^%s*][^*]-)%*", "<i>%1</i>")
	text = text:gsub("_([^%s_][^_]-)_", "<i>%1</i>")

	return text
end

local function SplitMessageSegments(text)
	local segments = {}
	local pos = 1
	while true do
		local s, e, lang, code = text:find("```(%w*)\n?(.-)```", pos)
		if not s then
			local rest = text:sub(pos)
			if rest ~= "" then
				table.insert(segments, { kind = "text", content = rest })
			end
			break
		end
		if s > pos then
			local before = text:sub(pos, s - 1)
			if before:match("%S") then
				table.insert(segments, { kind = "text", content = before })
			end
		end
		code = code:gsub("^%s+", ""):gsub("%s+$", "")
		table.insert(segments, { kind = "code", lang = lang ~= "" and lang or "lua", content = code })
		pos = e + 1
	end
	if #segments == 0 then
		table.insert(segments, { kind = "text", content = text })
	end
	return segments
end

local LUA_KEYWORDS = {
	["and"] = true,
	["break"] = true,
	["do"] = true,
	["else"] = true,
	["elseif"] = true,
	["end"] = true,
	["false"] = true,
	["for"] = true,
	["function"] = true,
	["if"] = true,
	["in"] = true,
	["local"] = true,
	["nil"] = true,
	["not"] = true,
	["or"] = true,
	["repeat"] = true,
	["return"] = true,
	["then"] = true,
	["true"] = true,
	["until"] = true,
	["while"] = true,
	["continue"] = true,
}

local function HighlightLua(code)
	local out = {}
	local n = #code
	local i = 1

	while i <= n do
		local c = code:sub(i, i)

		if code:sub(i, i + 3) == "--[[" then
			local closeEnd = select(2, code:find("%]%]", i + 4))
			local stop = closeEnd or n
			out[#out + 1] = '<font color="#6A9955">' .. code:sub(i, stop) .. "</font>"
			i = stop + 1
		elseif code:sub(i, i + 1) == "--" then
			local nl = code:find("\n", i, true)
			local stop = (nl or (n + 1)) - 1
			out[#out + 1] = '<font color="#6A9955">' .. code:sub(i, stop) .. "</font>"
			i = stop + 1
		elseif c == '"' or c == "'" then
			local quote = c
			local j = i + 1
			while j <= n do
				local jc = code:sub(j, j)
				if jc == "\\" then
					j = j + 2
				elseif jc == quote or jc == "\n" then
					break
				else
					j = j + 1
				end
			end
			j = math.min(j, n)
			out[#out + 1] = '<font color="#CE9178">' .. code:sub(i, j) .. "</font>"
			i = j + 1
		elseif c:match("%a") or c == "_" then
			local j = i
			while j <= n and code:sub(j, j):match("[%w_]") do
				j = j + 1
			end
			local word = code:sub(i, j - 1)
			out[#out + 1] = LUA_KEYWORDS[word] and ('<font color="#C586C0">' .. word .. "</font>") or word
			i = j
		elseif c:match("%d") then
			local j = i
			while j <= n and code:sub(j, j):match("[%d%.]") do
				j = j + 1
			end
			out[#out + 1] = '<font color="#B5CEA8">' .. code:sub(i, j - 1) .. "</font>"
			i = j
		else
			out[#out + 1] = c
			i = i + 1
		end
	end

	return table.concat(out)
end

function Window:AddPanelTab(opts)
	opts = opts or {}
	local self_ = self
	local tabObj = self:AddTab({
		Name = opts.Name,
		Icon = opts.Icon,
		Hidden = opts.Hidden ~= false,
	})
	-- Panels normally draw straight into the group, so the scrolling page is left
	-- out of the way. UseElements keeps it so Tab:AddButton and friends still work.
	tabObj._page.Visible = opts.UseElements == true
	local staleEmptyState = tabObj._group:FindFirstChild("EmptyState")
	if staleEmptyState then
		staleEmptyState.Visible = false
	end

	if opts.OnToggle then
		table.insert(self._tabChangeListeners, function(selected)
			SafeSpawn(opts.OnToggle, selected == tabObj)
		end)
	end

	local lastRealTab = nil
	local function openPanel()
		if self_._currentTab == tabObj then
			return
		end
		if self_._currentTab and not self_._currentTab.Hidden then
			lastRealTab = self_._currentTab
		end
		tabObj._select()
	end
	local function closePanel()
		if self_._currentTab ~= tabObj then
			return
		end
		if lastRealTab and not lastRealTab.Hidden then
			lastRealTab._select()
		elseif self_._tabs[1] and self_._tabs[1] ~= tabObj then
			self_._tabs[1]._select()
		end
	end

	return {
		Instance = tabObj._group,
		Tab = tabObj,
		Open = openPanel,
		Close = closePanel,
		Toggle = function()
			if self_._currentTab == tabObj then
				closePanel()
			else
				openPanel()
			end
		end,
		IsOpen = function()
			return self_._currentTab == tabObj
		end,
	}
end

local DEFAULT_CREDIT_IMAGE = "rbxassetid://87167480222237"
local AVATAR_SIZE = 36

-- opts.Credits is a list of { Name, Text, Image }. Image is any asset id or url,
-- shown inside the ring the way the launcher button holds its picture. Leave the
-- list out and the panel shows the library's own line.
function Window:AddDefaultCreditsPanel(opts)
	opts = opts or {}
	local jan = self._janitor
	local dockBtn
	local panelTitle = opts.Title or "Credits"
	local panel = self:AddPanelTab({
		Name = opts.Name or panelTitle,
		Icon = opts.Icon or "Lucide:heart-handshake",
		OnToggle = function(isOpen)
			if dockBtn then
				dockBtn:SetActive(isOpen)
			end
		end,
	})

	local CREDITS = opts.Credits
	if type(CREDITS) ~= "table" or #CREDITS == 0 then
		CREDITS = {
			{
				Name = "_nguoitinhcuae",
				Text = "Rewrite Full GUI",
			},
		}
	end

	local HEADER_H = 38

	local header = Instance.new("Frame")
	header.BackgroundTransparency = 1
	header.Size = UDim2.new(1, 0, 0, HEADER_H)
	header.ZIndex = Z.Content + 1
	header.Parent = panel.Instance

	local headerPad = Instance.new("UIPadding")
	headerPad.PaddingLeft = UDim.new(0, 14)
	headerPad.PaddingRight = UDim.new(0, 8)
	headerPad.Parent = header

	local titleRow = Instance.new("Frame")
	titleRow.BackgroundTransparency = 1
	titleRow.Size = UDim2.new(1, -40, 1, 0)
	titleRow.ZIndex = Z.Content + 2
	titleRow.Parent = header

	local titleLayout = Instance.new("UIListLayout")
	titleLayout.FillDirection = Enum.FillDirection.Horizontal
	titleLayout.VerticalAlignment = Enum.VerticalAlignment.Center
	titleLayout.Padding = UDim.new(0, 7)
	titleLayout.Parent = titleRow

	local titleIcon = Instance.new("ImageLabel")
	titleIcon.BackgroundTransparency = 1
	titleIcon.Image = ResolveIcon(opts.Icon or "heart-handshake")
	titleIcon.ImageColor3 = NullUI.Theme.Text
	Role(titleIcon, "Text")
	titleIcon.Size = UDim2.fromOffset(14, 14)
	titleIcon.LayoutOrder = 1
	titleIcon.ZIndex = Z.Content + 3
	titleIcon.Parent = titleRow

	local titleLabel = Instance.new("TextLabel")
	titleLabel.BackgroundTransparency = 1
	titleLabel.FontFace = NullUI.Theme.Font
	titleLabel.Text = panelTitle
	titleLabel.TextColor3 = NullUI.Theme.Text
	Role(titleLabel, "Text")
	titleLabel.TextSize = 14
	titleLabel.TextXAlignment = Enum.TextXAlignment.Left
	titleLabel.AutomaticSize = Enum.AutomaticSize.X
	titleLabel.Size = UDim2.fromOffset(0, 14)
	titleLabel.LayoutOrder = 2
	titleLabel.ZIndex = Z.Content + 3
	titleLabel.Parent = titleRow

	local closeBtn = Instance.new("TextButton")
	closeBtn.Text = ""
	closeBtn.AutoButtonColor = false
	closeBtn.BackgroundColor3 = Color3.new(1, 1, 1)
	closeBtn.BackgroundTransparency = 1
	closeBtn.BorderSizePixel = 0
	closeBtn.AnchorPoint = Vector2.new(1, 0.5)
	closeBtn.Position = UDim2.new(1, 0, 0.5, 0)
	closeBtn.Size = UDim2.fromOffset(26, 26)
	closeBtn.ZIndex = Z.Content + 2
	closeBtn.Parent = header

	local closeIcon = Instance.new("ImageLabel")
	closeIcon.BackgroundTransparency = 1
	closeIcon.Image = ResolveIcon("x")
	closeIcon.ImageColor3 = NullUI.Theme.TextDim
	Role(closeIcon, "TextDim")
	closeIcon.Size = UDim2.fromOffset(13, 13)
	closeIcon.AnchorPoint = Vector2.new(0.5, 0.5)
	closeIcon.Position = UDim2.fromScale(0.5, 0.5)
	closeIcon.ZIndex = Z.Content + 3
	closeIcon.Parent = closeBtn

	closeBtn.MouseEnter:Connect(function()
		closeIcon.ImageColor3 = NullUI.Theme.Text
		Role(closeIcon, "Text")
	end)
	closeBtn.MouseLeave:Connect(function()
		closeIcon.ImageColor3 = NullUI.Theme.TextDim
		Role(closeIcon, "TextDim")
	end)
	closeBtn.MouseButton1Click:Connect(function()
		panel.Close()
	end)

	local divider = Instance.new("Frame")
	divider.BackgroundColor3 = Color3.new(1, 1, 1)
	divider.BackgroundTransparency = 0.94
	divider.BorderSizePixel = 0
	divider.Position = UDim2.fromOffset(0, HEADER_H)
	divider.Size = UDim2.new(1, 0, 0, 1)
	divider.ZIndex = Z.Content + 1
	divider.Parent = panel.Instance

	local scroll = Instance.new("ScrollingFrame")
	scroll.BackgroundTransparency = 1
	scroll.BorderSizePixel = 0
	scroll.Position = UDim2.fromOffset(0, HEADER_H + 1)
	scroll.Size = UDim2.new(1, 0, 1, -(HEADER_H + 1))
	scroll.ScrollingDirection = Enum.ScrollingDirection.Y
	scroll.ScrollBarThickness = 0
	scroll.AutomaticCanvasSize = Enum.AutomaticSize.Y
	scroll.CanvasSize = UDim2.new(0, 0, 0, 0)
	scroll.ZIndex = Z.Content + 1
	scroll.Parent = panel.Instance

	local scrollPad = Instance.new("UIPadding")
	scrollPad.PaddingTop = UDim.new(0, 12)
	scrollPad.PaddingBottom = UDim.new(0, 12)
	scrollPad.PaddingLeft = UDim.new(0, 14)
	scrollPad.PaddingRight = UDim.new(0, 14)
	scrollPad.Parent = scroll

	local listLayout = Instance.new("UIListLayout")
	listLayout.Padding = UDim.new(0, 8)
	listLayout.SortOrder = Enum.SortOrder.LayoutOrder
	listLayout.Parent = scroll

	AddScrollbar(scroll)
	AddContentScrollThumb(scroll, listLayout, panel.Instance, jan)

	for i, credit in ipairs(CREDITS) do
		local row = Instance.new("Frame")
		row.Name = credit.Name or ("Credit" .. i)
		row.BackgroundColor3 = Color3.new(1, 1, 1)
		row.BackgroundTransparency = 0.96
		row.BorderSizePixel = 0
		row.LayoutOrder = i
		row.Size = UDim2.new(1, 0, 0, 56)
		row.ZIndex = Z.Content + 2
		row.Parent = scroll

		local rowCorner = Instance.new("UICorner")
		rowCorner.CornerRadius = UDim.new(0, 10)
		rowCorner.Parent = row

		local rowStroke = Instance.new("UIStroke")
		rowStroke.Color = Color3.new(1, 1, 1)
		rowStroke.Transparency = 0.94
		rowStroke.Thickness = 1
		rowStroke.Parent = row

		row.MouseEnter:Connect(function()
			row.BackgroundTransparency = 0.92
		end)
		row.MouseLeave:Connect(function()
			row.BackgroundTransparency = 0.96
		end)

		-- Ring, then the image inside it, the same shape as the launcher button.
		-- Both ring parts follow the accent, so a theme change repaints them.
		-- ClipsDescendants ignores UICorner, so the picture carries its own
		-- corner instead of relying on a round parent to cut it.
		local avatar = Instance.new("Frame")
		avatar.Name = "Avatar"
		avatar.AnchorPoint = Vector2.new(0, 0.5)
		avatar.Position = UDim2.new(0, 14, 0.5, 0)
		avatar.Size = UDim2.fromOffset(AVATAR_SIZE, AVATAR_SIZE)
		avatar.BackgroundColor3 = NullUI.Theme.Accent
		avatar:SetAttribute("NullUIAccent", true)
		Role(avatar, "Accent")
		avatar.BackgroundTransparency = 0.82
		avatar.BorderSizePixel = 0
		avatar.ZIndex = Z.Content + 2
		avatar.Parent = row

		local avCorner = Instance.new("UICorner")
		avCorner.CornerRadius = UDim.new(1, 0)
		avCorner.Parent = avatar

		local avStroke = Instance.new("UIStroke")
		avStroke.Color = NullUI.Theme.Accent
		avStroke:SetAttribute("NullUIAccent", true)
		Role(avStroke, "Accent")
		avStroke.Transparency = 0.55
		avStroke.Thickness = 1
		avStroke.Parent = avatar

		jan:Add(NullUI.ThemeChanged.Connect(function(theme)
			avatar.BackgroundColor3 = theme.Accent
			avStroke.Color = theme.Accent
		end))

		local avImage = Instance.new("ImageLabel")
		avImage.Name = "Image"
		avImage.BackgroundTransparency = 1
		avImage.Image = ResolveIcon(credit.Image or DEFAULT_CREDIT_IMAGE)
		avImage:SetAttribute("NullUINoTheme", true)
		-- The image fills the circle and carries its own corner, so the ring's
		-- stroke lands right on its edge instead of leaving a gap.
		avImage.ScaleType = Enum.ScaleType.Crop
		avImage.Size = UDim2.fromScale(1, 1)
		avImage.AnchorPoint = Vector2.new(0.5, 0.5)
		avImage.Position = UDim2.fromScale(0.5, 0.5)
		avImage.ZIndex = Z.Content + 3
		avImage.Parent = avatar

		local imgCorner = Instance.new("UICorner")
		imgCorner.CornerRadius = UDim.new(1, 0)
		imgCorner.Parent = avImage

		local textX = 14 + AVATAR_SIZE + 12
		local nameLabel = Instance.new("TextLabel")
		nameLabel.Name = "Name"
		nameLabel.BackgroundTransparency = 1
		nameLabel.FontFace = NullUI.Theme.Font
		nameLabel.Text = credit.Name or ""
		nameLabel.TextColor3 = NullUI.Theme.Text
		Role(nameLabel, "Text")
		nameLabel.TextSize = 13.5
		nameLabel.TextXAlignment = Enum.TextXAlignment.Left
		nameLabel.TextYAlignment = Enum.TextYAlignment.Bottom
		nameLabel.AnchorPoint = Vector2.new(0, 1)
		nameLabel.Position = UDim2.new(0, textX, 0.5, -4)
		nameLabel.Size = UDim2.new(1, -(textX + 14), 0, 17)
		nameLabel.ZIndex = Z.Content + 2
		nameLabel.Parent = row

		local textLabel = Instance.new("TextLabel")
		textLabel.Name = "Text"
		textLabel.BackgroundTransparency = 1
		textLabel.FontFace = NullUI.Theme.FontRegular
		textLabel.Text = credit.Text or ""
		textLabel.TextColor3 = NullUI.Theme.TextDim
		Role(textLabel, "TextDim")
		textLabel.TextSize = 11.5
		textLabel.TextTruncate = Enum.TextTruncate.AtEnd
		textLabel.TextXAlignment = Enum.TextXAlignment.Left
		textLabel.TextYAlignment = Enum.TextYAlignment.Top
		textLabel.Position = UDim2.new(0, textX, 0.5, 4)
		textLabel.Size = UDim2.new(1, -(textX + 14), 0, 16)
		textLabel.ZIndex = Z.Content + 2
		textLabel.Parent = row
	end

	dockBtn = self:AddDockButton({
		Icon = "Lucide:heart-handshake",
		Callback = function()
			panel.Toggle()
		end,
	})

	return panel
end

function Window:AddSpotifyPanel(opts)
	opts = opts or {}
	local jan = self._janitor
	local dockBtn
	local connectBridge
	local hasOpenedSpotify = false
	local panel
	panel = self:AddPanelTab({
		Name = opts.Name or "Spotify",
		Icon = opts.Icon or "Lucide:music-2",
		OnToggle = function(isOpen)
			if dockBtn then
				dockBtn:SetActive(isOpen)
			end
			if isOpen and not hasOpenedSpotify then
				hasOpenedSpotify = true
				if opts.AutoConnect == true and opts.BridgeUrl ~= "" then
					SafeDefer(function()
						if connectBridge then
							connectBridge()
						end
					end)
				end
			end
			if opts.OnToggle then
				SafeSpawn(opts.OnToggle, isOpen)
			end
		end,
	})

	local function websocketConnect()
		local candidates = {}
		pcall(function()
			if WebSocket and type(WebSocket.connect) == "function" then
				table.insert(candidates, WebSocket.connect)
			end
		end)
		pcall(function()
			if websocket and type(websocket.connect) == "function" then
				table.insert(candidates, websocket.connect)
			end
		end)
		pcall(function()
			if syn and syn.websocket and type(syn.websocket.connect) == "function" then
				table.insert(candidates, syn.websocket.connect)
			end
		end)
		return candidates[1]
	end

	local HEADER_H = 0
	local header = Instance.new("Frame")
	header.BackgroundTransparency = 1
	header.Size = UDim2.new(1, 0, 0, HEADER_H)
	header.ZIndex = Z.Content + 1
	header.Parent = panel.Instance
	header.Visible = false

	local headerPad = Instance.new("UIPadding")
	headerPad.PaddingLeft = UDim.new(0, 14)
	headerPad.PaddingRight = UDim.new(0, 8)
	headerPad.Parent = header

	local titleIcon = Instance.new("ImageLabel")
	titleIcon.BackgroundTransparency = 1
	titleIcon.Image = ResolveIcon(opts.Icon or "Lucide:music-2")
	titleIcon.ImageColor3 = Color3.fromRGB(30, 215, 96)
	titleIcon.AnchorPoint = Vector2.new(0, 0.5)
	titleIcon.Position = UDim2.new(0, 0, 0.5, 0)
	titleIcon.Size = UDim2.fromOffset(15, 15)
	titleIcon.ZIndex = Z.Content + 2
	titleIcon.Parent = header

	local titleLabel = Instance.new("TextLabel")
	titleLabel.BackgroundTransparency = 1
	titleLabel.FontFace = NullUI.Theme.Font
	titleLabel.Text = opts.Title or "Spotify Player"
	titleLabel.TextColor3 = NullUI.Theme.Text
	Role(titleLabel, "Text")
	titleLabel.TextSize = 14
	titleLabel.TextXAlignment = Enum.TextXAlignment.Left
	titleLabel.AnchorPoint = Vector2.new(0, 0.5)
	titleLabel.Position = UDim2.new(0, 22, 0.5, 0)
	titleLabel.Size = UDim2.new(1, -62, 0, 18)
	titleLabel.ZIndex = Z.Content + 2
	titleLabel.Parent = header

	local closeBtn = Instance.new("TextButton")
	closeBtn.Text = ""
	closeBtn.AutoButtonColor = false
	closeBtn.BackgroundTransparency = 1
	closeBtn.AnchorPoint = Vector2.new(1, 0.5)
	closeBtn.Position = UDim2.new(1, 0, 0.5, 0)
	closeBtn.Size = UDim2.fromOffset(26, 26)
	closeBtn.ZIndex = Z.Content + 2
	closeBtn.Parent = header

	local closeIcon = Instance.new("ImageLabel")
	closeIcon.BackgroundTransparency = 1
	closeIcon.Image = ResolveIcon("x")
	closeIcon.ImageColor3 = NullUI.Theme.TextDim
	Role(closeIcon, "TextDim")
	closeIcon.AnchorPoint = Vector2.new(0.5, 0.5)
	closeIcon.Position = UDim2.fromScale(0.5, 0.5)
	closeIcon.Size = UDim2.fromOffset(13, 13)
	closeIcon.ZIndex = Z.Content + 3
	closeIcon.Parent = closeBtn
	jan:Add(closeBtn.MouseButton1Click:Connect(function()
		panel.Close()
	end))

	local divider = Instance.new("Frame")
	divider.BackgroundColor3 = Color3.new(1, 1, 1)
	divider.BackgroundTransparency = 0.94
	divider.BorderSizePixel = 0
	divider.Position = UDim2.fromOffset(0, HEADER_H)
	divider.Size = UDim2.new(1, 0, 0, 1)
	divider.ZIndex = Z.Content + 1
	divider.Parent = panel.Instance
	divider.Visible = false

	local subTabHost = Instance.new("ScrollingFrame")
	subTabHost.Name = "SpotifySubTabs"
	subTabHost.BackgroundTransparency = 1
	subTabHost.BorderSizePixel = 0
	subTabHost.Position = UDim2.fromOffset(0, HEADER_H)
	subTabHost.Size = UDim2.new(1, 0, 1, -HEADER_H)
	subTabHost.ScrollBarThickness = 0
	subTabHost.ZIndex = Z.Content + 1
	subTabHost.Parent = panel.Instance

	local subTabRoot = setmetatable({
		Name = "Spotify Player",
		_page = subTabHost,
		_window = self,
		_janitor = jan,
		_group = panel.Instance,
	}, Tab)
	local playerSubTab = subTabRoot:AddSubTab({ Name = "Spotify Player", Icon = "Lucide:music-2" })
	local favoritesSubTab = subTabRoot:AddSubTab({ Name = "Favorites", Icon = "Lucide:heart" })
	local scroll = playerSubTab._page
	local list = scroll:FindFirstChild("PageLayout")
	local scrollPad = scroll:FindFirstChild("PagePadding")
	if scrollPad then
		scrollPad.PaddingTop = UDim.new(0, 0)
		scrollPad.PaddingLeft = UDim.new(0, 0)
		scrollPad.PaddingRight = UDim.new(0, 12)
		scrollPad.PaddingBottom = UDim.new(0, 6)
	end
	local favoritesPad = favoritesSubTab._page:FindFirstChild("PagePadding")
	if favoritesPad then
		favoritesPad.PaddingTop = UDim.new(0, 0)
		favoritesPad.PaddingLeft = UDim.new(0, 0)
		favoritesPad.PaddingRight = UDim.new(0, 12)
		favoritesPad.PaddingBottom = UDim.new(0, 6)
	end

	local function makeCard(height, order, parent)
		local card = Instance.new("Frame")
		card.BackgroundColor3 = Color3.new(1, 1, 1)
		card.BackgroundTransparency = 0.96
		card.BorderSizePixel = 0
		card.Size = UDim2.new(1, 0, 0, height)
		card.LayoutOrder = order
		card.ZIndex = Z.Content + 2
		card.Parent = parent or scroll
		Corner(card, 10)
		Stroke(card, Color3.new(1, 1, 1), 1, 0.94)
		return card
	end

	local guideParagraph = playerSubTab:AddParagraph({
		Title = "Quick setup",
		Icon = "Lucide:link-2",
		Text = "Copy the player link, keep it open in your browser, load a playlist and press Play once.",
	})
	guideParagraph.Instance.LayoutOrder = 1

	local statusCard = makeCard(30, 6)
	local statusDot = Instance.new("Frame")
	statusDot.BackgroundColor3 = Color3.fromRGB(125, 130, 128)
	statusDot.BorderSizePixel = 0
	statusDot.AnchorPoint = Vector2.new(0, 0.5)
	statusDot.Position = UDim2.new(0, 11, 0.5, 0)
	statusDot.Size = UDim2.fromOffset(7, 7)
	statusDot.ZIndex = Z.Content + 3
	statusDot.Parent = statusCard
	Corner(statusDot, 4)

	local statusLabel = Instance.new("TextLabel")
	statusLabel.BackgroundTransparency = 1
	statusLabel.FontFace = NullUI.Theme.FontRegular
	statusLabel.Text = "Bridge disconnected"
	statusLabel.TextColor3 = NullUI.Theme.TextDim
	Role(statusLabel, "TextDim")
	statusLabel.TextSize = 12
	statusLabel.TextXAlignment = Enum.TextXAlignment.Left
	statusLabel.Position = UDim2.fromOffset(27, 0)
	statusLabel.Size = UDim2.new(1, -38, 1, 0)
	statusLabel.ZIndex = Z.Content + 3
	statusLabel.Parent = statusCard

	local nowCard = makeCard(164, 7)
	nowCard.ClipsDescendants = true
	local art = Instance.new("ImageLabel")
	art.BackgroundColor3 = Color3.fromRGB(30, 215, 96)
	art.BackgroundTransparency = 0.84
	art.BorderSizePixel = 0
	art.Image = ""
	art.ImageColor3 = Color3.new(1, 1, 1)
	art.ScaleType = Enum.ScaleType.Crop
	art.AnchorPoint = Vector2.new(0, 0)
	art.Position = UDim2.fromOffset(0, 12)
	art.Size = UDim2.fromOffset(88, 88)
	art.ZIndex = Z.Content + 3
	art.Parent = nowCard
	Corner(art, 12)
	Stroke(art, Color3.new(1, 1, 1), 1, 0.9)

	local artIcon = Instance.new("ImageLabel")
	artIcon.BackgroundTransparency = 1
	artIcon.Image = ResolveIcon("music-2")
	artIcon.ImageColor3 = Color3.fromRGB(30, 215, 96)
	artIcon.AnchorPoint = Vector2.new(0.5, 0.5)
	artIcon.Position = UDim2.fromScale(0.5, 0.5)
	artIcon.Size = UDim2.fromOffset(28, 28)
	artIcon.ZIndex = Z.Content + 4
	artIcon.Parent = art

	local coverToken = 0
	local coverCache = {}
	local function showCover(url)
		coverToken += 1
		local token = coverToken
		url = type(url) == "string" and url or ""
		if url == "" then
			art.BackgroundTransparency = 0.84
			art.Image = ""
			artIcon.Visible = true
			artIcon.Image = ResolveIcon("music-2")
			artIcon.ImageColor3 = Color3.fromRGB(30, 215, 96)
			artIcon.BackgroundTransparency = 1
			artIcon.AnchorPoint = Vector2.new(0.5, 0.5)
			artIcon.Size = UDim2.fromOffset(28, 28)
			artIcon.Position = UDim2.fromScale(0.5, 0.5)
			return
		end
		SafeSpawn(function()
			local asset = coverCache[url]
			if not asset and fn_customasset and fn_writefile and EnsureAssetsFolder() then
				local hash = 7
				for index = 1, #url do
					hash = (hash * 31 + url:byte(index)) % 2147483647
				end
				local path = ASSETS_FOLDER .. "/spotify-cover-" .. tostring(hash) .. ".jpg"
				if not (fn_isfile and fn_isfile(path)) then
					local ok, body = pcall(function()
						return game:HttpGet(url)
					end)
					if ok and type(body) == "string" and #body > 256 then
						pcall(fn_writefile, path, body)
					end
				end
				if not fn_isfile or fn_isfile(path) then
					local ok, result = pcall(fn_customasset, path)
					if ok then
						asset = result
						coverCache[url] = result
					end
				end
			end
			if token ~= coverToken or not asset then
				return
			end
			art.BackgroundTransparency = 1
			art.Image = asset
			artIcon.Visible = false
		end)
	end

	local nowPlayingTag = Instance.new("TextLabel")
	nowPlayingTag.BackgroundTransparency = 1
	nowPlayingTag.FontFace = NullUI.Theme.Font
	nowPlayingTag.Text = "NOW PLAYING"
	nowPlayingTag.TextColor3 = Color3.fromRGB(30, 215, 96)
	nowPlayingTag.TextSize = 9
	nowPlayingTag.TextXAlignment = Enum.TextXAlignment.Left
	nowPlayingTag.Position = UDim2.fromOffset(100, 9)
	nowPlayingTag.Size = UDim2.new(1, -100, 0, 12)
	nowPlayingTag.ZIndex = Z.Content + 3
	nowPlayingTag.Parent = nowCard

	local trackLabel = Instance.new("TextLabel")
	trackLabel.BackgroundTransparency = 1
	trackLabel.FontFace = NullUI.Theme.Font
	trackLabel.Text = "Nothing playing"
	trackLabel.TextColor3 = NullUI.Theme.Text
	Role(trackLabel, "Text")
	trackLabel.TextSize = 15
	trackLabel.TextXAlignment = Enum.TextXAlignment.Left
	trackLabel.TextTruncate = Enum.TextTruncate.AtEnd
	trackLabel.Position = UDim2.fromOffset(100, 25)
	trackLabel.Size = UDim2.new(1, -100, 0, 20)
	trackLabel.ZIndex = Z.Content + 3
	trackLabel.Parent = nowCard

	local artistLabel = Instance.new("TextLabel")
	artistLabel.BackgroundTransparency = 1
	artistLabel.FontFace = NullUI.Theme.FontRegular
	artistLabel.Text = "Connect your Spotify bridge"
	artistLabel.TextColor3 = NullUI.Theme.TextDim
	Role(artistLabel, "TextDim")
	artistLabel.TextSize = 12
	artistLabel.TextXAlignment = Enum.TextXAlignment.Left
	artistLabel.TextTruncate = Enum.TextTruncate.AtEnd
	artistLabel.Position = UDim2.fromOffset(100, 47)
	artistLabel.Size = UDim2.new(1, -100, 0, 16)
	artistLabel.ZIndex = Z.Content + 3
	artistLabel.Parent = nowCard

	local progressTrack = Instance.new("Frame")
	progressTrack.BackgroundColor3 = Color3.fromRGB(95, 100, 98)
	progressTrack.BackgroundTransparency = 0.45
	progressTrack.BorderSizePixel = 0
	progressTrack.Position = UDim2.fromOffset(100, 76)
	progressTrack.Size = UDim2.new(1, -100, 0, 5)
	progressTrack.ZIndex = Z.Content + 3
	progressTrack.Parent = nowCard
	Corner(progressTrack, 2)

	local progressFill = Instance.new("Frame")
	progressFill.BackgroundColor3 = Color3.fromRGB(30, 215, 96)
	progressFill.BorderSizePixel = 0
	progressFill.Size = UDim2.new(0, 0, 1, 0)
	progressFill.ZIndex = Z.Content + 4
	progressFill.Parent = progressTrack
	Corner(progressFill, 2)

	local progressKnob = Instance.new("Frame")
	progressKnob.BackgroundColor3 = Color3.fromRGB(235, 239, 237)
	progressKnob.BorderSizePixel = 0
	progressKnob.AnchorPoint = Vector2.new(0.5, 0.5)
	progressKnob.Position = UDim2.new(0, 0, 0.5, 0)
	progressKnob.Size = UDim2.fromOffset(9, 9)
	progressKnob.ZIndex = Z.Content + 6
	progressKnob.Parent = progressTrack
	Corner(progressKnob, 5)

	local seekBubble = Instance.new("Frame")
	seekBubble.BackgroundColor3 = Color3.fromRGB(21, 26, 24)
	seekBubble.BackgroundTransparency = 0.04
	seekBubble.BorderSizePixel = 0
	seekBubble.AnchorPoint = Vector2.new(0.5, 1)
	seekBubble.Position = UDim2.new(0, 0, 0, -8)
	seekBubble.Size = UDim2.fromOffset(48, 25)
	seekBubble.Visible = false
	seekBubble.ZIndex = Z.Content + 8
	seekBubble.Parent = progressTrack
	Corner(seekBubble, 7)
	Stroke(seekBubble, Color3.new(1, 1, 1), 1, 0.9)
	local seekBubbleLabel = Instance.new("TextLabel")
	seekBubbleLabel.BackgroundTransparency = 1
	seekBubbleLabel.FontFace = NullUI.Theme.Font
	seekBubbleLabel.Text = "0:00"
	seekBubbleLabel.TextColor3 = NullUI.Theme.Text
	Role(seekBubbleLabel, "Text")
	seekBubbleLabel.TextSize = 10
	seekBubbleLabel.Size = UDim2.fromScale(1, 1)
	seekBubbleLabel.ZIndex = Z.Content + 9
	seekBubbleLabel.Parent = seekBubble

	local progressHitbox = Instance.new("TextButton")
	progressHitbox.Text = ""
	progressHitbox.AutoButtonColor = false
	progressHitbox.BackgroundTransparency = 1
	progressHitbox.BorderSizePixel = 0
	progressHitbox.Position = UDim2.fromOffset(100, 68)
	progressHitbox.Size = UDim2.new(1, -100, 0, 21)
	progressHitbox.ZIndex = Z.Content + 7
	progressHitbox.Parent = nowCard

	local timeLabel = Instance.new("TextLabel")
	timeLabel.BackgroundTransparency = 1
	timeLabel.FontFace = NullUI.Theme.FontRegular
	timeLabel.Text = "0:00"
	timeLabel.TextColor3 = NullUI.Theme.TextDim
	Role(timeLabel, "TextDim")
	timeLabel.TextSize = 10
	timeLabel.TextXAlignment = Enum.TextXAlignment.Left
	timeLabel.Position = UDim2.fromOffset(100, 87)
	timeLabel.Size = UDim2.new(0.5, -50, 0, 14)
	timeLabel.ZIndex = Z.Content + 3
	timeLabel.Parent = nowCard

	local durationLabel = Instance.new("TextLabel")
	durationLabel.BackgroundTransparency = 1
	durationLabel.FontFace = NullUI.Theme.FontRegular
	durationLabel.Text = "0:00"
	durationLabel.TextColor3 = NullUI.Theme.TextDim
	Role(durationLabel, "TextDim")
	durationLabel.TextSize = 10
	durationLabel.TextXAlignment = Enum.TextXAlignment.Right
	durationLabel.Position = UDim2.new(0.5, 50, 0, 87)
	durationLabel.Size = UDim2.new(0.5, -50, 0, 14)
	durationLabel.ZIndex = Z.Content + 3
	durationLabel.Parent = nowCard

	local controlsDivider = Instance.new("Frame")
	controlsDivider.BackgroundColor3 = Color3.new(1, 1, 1)
	controlsDivider.BackgroundTransparency = 0.93
	controlsDivider.BorderSizePixel = 0
	controlsDivider.Position = UDim2.fromOffset(0, 111)
	controlsDivider.Size = UDim2.new(1, 0, 0, 1)
	controlsDivider.ZIndex = Z.Content + 3
	controlsDivider.Parent = nowCard

	local controls = Instance.new("Frame")
	controls.BackgroundTransparency = 1
	controls.BorderSizePixel = 0
	controls.Position = UDim2.fromOffset(0, 114)
	controls.Size = UDim2.new(1, 0, 0, 44)
	controls.ZIndex = Z.Content + 3
	controls.Parent = nowCard
	local controlsLayout = Instance.new("UIListLayout")
	controlsLayout.FillDirection = Enum.FillDirection.Horizontal
	controlsLayout.HorizontalAlignment = Enum.HorizontalAlignment.Center
	controlsLayout.VerticalAlignment = Enum.VerticalAlignment.Center
	controlsLayout.Padding = UDim.new(0, 12)
	controlsLayout.SortOrder = Enum.SortOrder.LayoutOrder
	controlsLayout.Parent = controls

	local controlRefs = {}
	local function makeControl(name, icon, order, primary)
		local button = Instance.new("TextButton")
		button.Name = name
		button.Text = ""
		button.AutoButtonColor = false
		button.BackgroundColor3 = primary and Color3.fromRGB(30, 215, 96) or Color3.new(1, 1, 1)
		button.BackgroundTransparency = primary and 0.05 or 0.94
		button.BorderSizePixel = 0
		button.Size = UDim2.fromOffset(primary and 36 or 32, primary and 36 or 32)
		button.LayoutOrder = order
		button.ZIndex = Z.Content + 3
		button.Parent = controls
		Corner(button, primary and 18 or 10)

		local image = Instance.new("ImageLabel")
		image.BackgroundTransparency = 1
		image.Image = ResolveIcon(icon)
		image.ImageColor3 = primary and Color3.fromRGB(12, 28, 18) or NullUI.Theme.TextDim
		image.AnchorPoint = Vector2.new(0.5, 0.5)
		image.Position = UDim2.fromScale(0.5, 0.5)
		image.Size = UDim2.fromOffset(primary and 17 or 15, primary and 17 or 15)
		image.ZIndex = Z.Content + 4
		image.Parent = button
		controlRefs[name] = { Button = button, Icon = image }
		return button
	end

	local shuffleBtn = makeControl("Shuffle", "shuffle", 1, false)
	local previousBtn = makeControl("Previous", "skip-back", 2, false)
	local playBtn = makeControl("PlayPause", "play", 3, true)
	local nextBtn = makeControl("Next", "skip-forward", 4, false)
	local repeatBtn = makeControl("Repeat", "repeat", 5, false)

	local function makeInputCard(order, title, placeholder, buttonIcon)
		local card = makeCard(66, order)
		local label = Instance.new("TextLabel")
		label.BackgroundTransparency = 1
		label.FontFace = NullUI.Theme.Font
		label.Text = title
		label.TextColor3 = NullUI.Theme.Text
		Role(label, "Text")
		label.TextSize = 12
		label.TextXAlignment = Enum.TextXAlignment.Left
		label.Position = UDim2.fromOffset(11, 6)
		label.Size = UDim2.new(1, -22, 0, 16)
		label.ZIndex = Z.Content + 3
		label.Parent = card

		local pill = Instance.new("Frame")
		pill.BackgroundColor3 = Color3.new(1, 1, 1)
		pill.BackgroundTransparency = 0.94
		pill.BorderSizePixel = 0
		pill.Position = UDim2.fromOffset(10, 27)
		pill.Size = UDim2.new(1, -20, 0, 30)
		pill.ZIndex = Z.Content + 3
		pill.Parent = card
		Corner(pill, 8)

		local button = Instance.new("TextButton")
		button.Text = ""
		button.AutoButtonColor = false
		button.BackgroundColor3 = Color3.new(1, 1, 1)
		button.BackgroundTransparency = 0.91
		button.BorderSizePixel = 0
		button.AnchorPoint = Vector2.new(1, 0)
		button.Position = UDim2.new(1, -3, 0, 3)
		button.Size = UDim2.fromOffset(34, 24)
		button.ZIndex = Z.Content + 5
		button.Parent = pill
		Corner(button, 7)
		Stroke(button, Color3.new(1, 1, 1), 1, 0.94)
		local buttonImage = Instance.new("ImageLabel")
		buttonImage.BackgroundTransparency = 1
		buttonImage.Image = ResolveIcon(buttonIcon)
		buttonImage.ImageColor3 = NullUI.Theme.Text
		Role(buttonImage, "Text")
		buttonImage.AnchorPoint = Vector2.new(0.5, 0.5)
		buttonImage.Position = UDim2.fromScale(0.5, 0.5)
		buttonImage.Size = UDim2.fromOffset(14, 14)
		buttonImage.ZIndex = Z.Content + 6
		buttonImage.Parent = button

		local box = Instance.new("TextBox")
		box.ClearTextOnFocus = false
		box.FontFace = NullUI.Theme.FontRegular
		box.PlaceholderText = placeholder
		box.PlaceholderColor3 = Color3.fromRGB(115, 120, 118)
		box.Text = ""
		box.TextColor3 = NullUI.Theme.Text
		Role(box, "Text")
		box.TextSize = 11
		box.TextXAlignment = Enum.TextXAlignment.Left
		box.BackgroundTransparency = 1
		box.Position = UDim2.fromOffset(9, 0)
		box.Size = UDim2.new(1, -52, 1, 0)
		box.ZIndex = Z.Content + 4
		box.Parent = pill
		return box, button, card, label, pill
	end

	local searchBox, searchBtn, searchCard, searchTitle, searchPill =
		makeInputCard(3, "", "Search this playlist...", "search")
	local pairBox, connectBtn, pairCard = makeInputCard(3, "Spotify Connect", "Pairing code", "link-2")
	local connectBtnIcon = connectBtn:FindFirstChildOfClass("ImageLabel")
	pairBox.TextEditable = false
	pairBox.Text = HttpService:GenerateGUID(false):gsub("%-", ""):sub(1, 8):upper()
	local playlistBox, loadBtn, playlistCard, playlistTitle, playlistPill =
		makeInputCard(4, "", "Paste a Spotify playlist link...", "play")

	local connectSection = playerSubTab:AddLineText("Spotify Connect")
	connectSection.Instance.LayoutOrder = 2
	local playerSection = playerSubTab:AddLineText("Player")
	playerSection.Instance.LayoutOrder = 4
	local playerShell = makeCard(286, 5)
	local function flattenIntoPlayer(card, y, height)
		card.Parent = playerShell
		card.BackgroundTransparency = 1
		card.Position = UDim2.fromOffset(12, y)
		card.Size = UDim2.new(1, -24, 0, height)
		for _, child in ipairs(card:GetChildren()) do
			if child:IsA("UIStroke") then
				child.Transparency = 1
			end
		end
	end
	flattenIntoPlayer(searchCard, 12, 40)
	searchTitle.Visible = false
	searchPill.Position = UDim2.fromOffset(0, 0)
	searchPill.Size = UDim2.fromScale(1, 1)
	searchPill.BackgroundTransparency = 0.92
	searchBtn.AnchorPoint = Vector2.zero
	searchBtn.Position = UDim2.fromOffset(4, 4)
	searchBtn.Size = UDim2.fromOffset(32, 32)
	searchBtn.BackgroundTransparency = 1
	for _, child in ipairs(searchBtn:GetChildren()) do
		if child:IsA("UIStroke") then
			child.Transparency = 1
		end
	end
	searchBox.Position = UDim2.fromOffset(38, 0)
	searchBox.Size = UDim2.new(1, -46, 1, 0)
	searchBox.TextSize = 13

	flattenIntoPlayer(playlistCard, 60, 40)
	playlistTitle.Visible = false
	playlistPill.Position = UDim2.fromOffset(0, 0)
	playlistPill.Size = UDim2.fromScale(1, 1)
	playlistPill.BackgroundTransparency = 0.92
	loadBtn.Position = UDim2.new(1, -4, 0, 4)
	loadBtn.Size = UDim2.fromOffset(32, 32)
	playlistBox.Position = UDim2.fromOffset(12, 0)
	playlistBox.Size = UDim2.new(1, -56, 1, 0)

	statusCard.Parent = playerShell
	statusCard.Position = UDim2.fromOffset(12, 108)
	statusCard.Size = UDim2.new(1, -24, 0, 30)
	statusCard.Visible = false
	nowCard.Parent = playerShell
	nowCard.Position = UDim2.fromOffset(12, 108)
	nowCard.Size = UDim2.new(1, -24, 0, 164)
	nowCard.BackgroundTransparency = 1
	for _, child in ipairs(nowCard:GetChildren()) do
		if child:IsA("UIStroke") then
			child.Transparency = 1
		end
	end

	local favoritesSection = favoritesSubTab:AddLineText("Saved Playlists")
	favoritesSection.Instance.LayoutOrder = 1
	local favoritesHeader = makeCard(137, 2, favoritesSubTab._page)
	local favoritesTitle = Instance.new("TextLabel")
	favoritesTitle.BackgroundTransparency = 1
	favoritesTitle.FontFace = NullUI.Theme.Font
	favoritesTitle.Text = "Favorite playlists"
	favoritesTitle.TextColor3 = NullUI.Theme.Text
	Role(favoritesTitle, "Text")
	favoritesTitle.TextSize = 14
	favoritesTitle.TextXAlignment = Enum.TextXAlignment.Left
	favoritesTitle.Position = UDim2.fromOffset(12, 8)
	favoritesTitle.Size = UDim2.new(1, -112, 0, 20)
	favoritesTitle.ZIndex = Z.Content + 3
	favoritesTitle.Parent = favoritesHeader
	favoritesTitle.Visible = false
	local favoritesHint = Instance.new("TextLabel")
	favoritesHint.BackgroundTransparency = 1
	favoritesHint.FontFace = NullUI.Theme.FontRegular
	favoritesHint.Text = "Save and load your playlists with one tap"
	favoritesHint.TextColor3 = NullUI.Theme.TextDim
	Role(favoritesHint, "TextDim")
	favoritesHint.TextSize = 10
	favoritesHint.TextXAlignment = Enum.TextXAlignment.Left
	favoritesHint.Position = UDim2.fromOffset(12, 29)
	favoritesHint.Size = UDim2.new(1, -112, 0, 16)
	favoritesHint.ZIndex = Z.Content + 3
	favoritesHint.Parent = favoritesHeader
	favoritesHint.Visible = false
	local favoritesSearchPill = Instance.new("Frame")
	favoritesSearchPill.BackgroundColor3 = Color3.new(1, 1, 1)
	favoritesSearchPill.BackgroundTransparency = 0.94
	favoritesSearchPill.BorderSizePixel = 0
	favoritesSearchPill.Position = UDim2.fromOffset(8, 7)
	favoritesSearchPill.Size = UDim2.new(1, -16, 0, 36)
	favoritesSearchPill.ZIndex = Z.Content + 3
	favoritesSearchPill.Parent = favoritesHeader
	Corner(favoritesSearchPill, 9)
	local favoritesSearchIcon = Instance.new("ImageLabel")
	favoritesSearchIcon.BackgroundTransparency = 1
	favoritesSearchIcon.Image = ResolveIcon("search")
	favoritesSearchIcon.ImageColor3 = NullUI.Theme.TextDim
	Role(favoritesSearchIcon, "TextDim")
	favoritesSearchIcon.AnchorPoint = Vector2.new(0, 0.5)
	favoritesSearchIcon.Position = UDim2.new(0, 11, 0.5, 0)
	favoritesSearchIcon.Size = UDim2.fromOffset(15, 15)
	favoritesSearchIcon.ZIndex = Z.Content + 4
	favoritesSearchIcon.Parent = favoritesSearchPill
	local favoritesSearchBox = Instance.new("TextBox")
	favoritesSearchBox.BackgroundTransparency = 1
	favoritesSearchBox.ClearTextOnFocus = false
	favoritesSearchBox.FontFace = NullUI.Theme.FontRegular
	favoritesSearchBox.PlaceholderText = "Search favorite playlists..."
	favoritesSearchBox.PlaceholderColor3 = Color3.fromRGB(115, 120, 118)
	favoritesSearchBox.Text = ""
	favoritesSearchBox.TextColor3 = NullUI.Theme.Text
	Role(favoritesSearchBox, "Text")
	favoritesSearchBox.TextSize = 11
	favoritesSearchBox.TextXAlignment = Enum.TextXAlignment.Left
	favoritesSearchBox.Position = UDim2.fromOffset(36, 0)
	favoritesSearchBox.Size = UDim2.new(1, -44, 1, 0)
	favoritesSearchBox.ZIndex = Z.Content + 4
	favoritesSearchBox.Parent = favoritesSearchPill
	local addFavoriteBtn = Instance.new("TextButton")
	addFavoriteBtn.Text = ""
	addFavoriteBtn.AutoButtonColor = false
	addFavoriteBtn.BackgroundColor3 = Color3.new(1, 1, 1)
	addFavoriteBtn.BackgroundTransparency = 0.96
	addFavoriteBtn.BorderSizePixel = 0
	addFavoriteBtn.Position = UDim2.fromOffset(8, 113)
	addFavoriteBtn.Size = UDim2.new(1, -16, 0, 56)
	addFavoriteBtn.ZIndex = Z.Content + 4
	addFavoriteBtn.Parent = favoritesHeader
	Corner(addFavoriteBtn, 10)
	Stroke(addFavoriteBtn, Color3.new(1, 1, 1), 1, 0.94)
	local addFavoriteIcon = Instance.new("ImageLabel")
	addFavoriteIcon.BackgroundTransparency = 1
	addFavoriteIcon.Image = ResolveIcon("heart-plus")
	addFavoriteIcon.ImageColor3 = NullUI.Theme.Text
	Role(addFavoriteIcon, "Text")
	addFavoriteIcon.AnchorPoint = Vector2.new(0, 0.5)
	addFavoriteIcon.Position = UDim2.new(0, 16, 0.5, 0)
	addFavoriteIcon.Size = UDim2.fromOffset(17, 17)
	addFavoriteIcon.ZIndex = Z.Content + 5
	addFavoriteIcon.Parent = addFavoriteBtn
	local saveFavoriteTitle = Instance.new("TextLabel")
	saveFavoriteTitle.BackgroundTransparency = 1
	saveFavoriteTitle.FontFace = NullUI.Theme.Font
	saveFavoriteTitle.Text = "Save current playlist"
	saveFavoriteTitle.TextColor3 = NullUI.Theme.Text
	Role(saveFavoriteTitle, "Text")
	saveFavoriteTitle.TextSize = 12
	saveFavoriteTitle.TextXAlignment = Enum.TextXAlignment.Left
	saveFavoriteTitle.Position = UDim2.fromOffset(44, 7)
	saveFavoriteTitle.Size = UDim2.new(1, -84, 0, 20)
	saveFavoriteTitle.ZIndex = Z.Content + 5
	saveFavoriteTitle.Parent = addFavoriteBtn
	local saveFavoriteHint = Instance.new("TextLabel")
	saveFavoriteHint.BackgroundTransparency = 1
	saveFavoriteHint.FontFace = NullUI.Theme.FontRegular
	saveFavoriteHint.Text = "Add the playlist loaded in the player to Favorites"
	saveFavoriteHint.TextColor3 = NullUI.Theme.TextDim
	Role(saveFavoriteHint, "TextDim")
	saveFavoriteHint.TextSize = 9
	saveFavoriteHint.TextXAlignment = Enum.TextXAlignment.Left
	saveFavoriteHint.Position = UDim2.fromOffset(44, 27)
	saveFavoriteHint.Size = UDim2.new(1, -84, 0, 17)
	saveFavoriteHint.ZIndex = Z.Content + 5
	saveFavoriteHint.Parent = addFavoriteBtn
	local saveFavoriteChevron = Instance.new("ImageLabel")
	saveFavoriteChevron.BackgroundTransparency = 1
	saveFavoriteChevron.Image = ResolveIcon("chevron-right")
	saveFavoriteChevron.ImageColor3 = NullUI.Theme.TextDim
	Role(saveFavoriteChevron, "TextDim")
	saveFavoriteChevron.AnchorPoint = Vector2.new(1, 0.5)
	saveFavoriteChevron.Position = UDim2.new(1, -16, 0.5, 0)
	saveFavoriteChevron.Size = UDim2.fromOffset(14, 14)
	saveFavoriteChevron.ZIndex = Z.Content + 5
	saveFavoriteChevron.Parent = addFavoriteBtn
	local saveFavoriteDivider = Instance.new("Frame")
	saveFavoriteDivider.BackgroundColor3 = Color3.new(1, 1, 1)
	saveFavoriteDivider.BackgroundTransparency = 0.92
	saveFavoriteDivider.BorderSizePixel = 0
	saveFavoriteDivider.Position = UDim2.fromOffset(8, 103)
	saveFavoriteDivider.Size = UDim2.new(1, -16, 0, 1)
	saveFavoriteDivider.ZIndex = Z.Content + 3
	saveFavoriteDivider.Parent = favoritesHeader

	local favoritesList = Instance.new("Frame")
	favoritesList.BackgroundTransparency = 1
	favoritesList.BorderSizePixel = 0
	favoritesList.Position = UDim2.fromOffset(8, 51)
	favoritesList.Size = UDim2.new(1, -16, 0, 78)
	favoritesList.ZIndex = Z.Content + 2
	favoritesList.Parent = favoritesHeader
	local favoriteRows = {}
	local favorites = {}
	local currentPlaylistName = "Spotify playlist"
	local favoritesPath = ASSETS_FOLDER .. "/spotify-favorites.json"
	if fn_readfile and fn_isfile and fn_isfile(favoritesPath) then
		pcall(function()
			local decoded = HttpService:JSONDecode(fn_readfile(favoritesPath))
			if type(decoded) == "table" then
				favorites = decoded
			end
		end)
	end
	local function saveFavorites()
		if not (fn_writefile and EnsureAssetsFolder()) then
			return
		end
		pcall(fn_writefile, favoritesPath, HttpService:JSONEncode(favorites))
	end

	local socket
	local socketConnections = {}
	local isConnected = false
	local isPlaying = false
	local shuffle = false
	local repeatMode = "off"
	local durationMs = 0
	local progressMs = 0
	local lastStateClock = os.clock()
	local seekDragging = false
	local seekPreviewMs = 0

	local function setStatus(text, color)
		statusLabel.Text = tostring(text or "")
		statusDot.BackgroundColor3 = color or Color3.fromRGB(125, 130, 128)
	end

	local notifyTimes = {}
	local function spotifyNotify(key, title, text, notifyType, icon, duration, actions)
		if not panel.IsOpen() then
			return
		end
		local now = os.clock()
		if notifyTimes[key] and now - notifyTimes[key] < 2.5 then
			return
		end
		notifyTimes[key] = now
		NullUI:Notify({
			Title = title,
			Text = text,
			Type = notifyType or "info",
			Icon = icon,
			Duration = duration or 5,
			Actions = actions,
		})
	end

	local function formatTime(ms)
		local seconds = math.max(0, math.floor((tonumber(ms) or 0) / 1000))
		return string.format("%d:%02d", math.floor(seconds / 60), seconds % 60)
	end

	local function renderProgress()
		LPH_ATTRIBUTES(VM(NONE))
		local shownProgress = progressMs
		if isPlaying and durationMs > 0 then
			shownProgress = math.min(durationMs, progressMs + (os.clock() - lastStateClock) * 1000)
		end
		local alpha = durationMs > 0 and math.clamp(shownProgress / durationMs, 0, 1) or 0
		if not seekDragging then
			progressFill.Size = UDim2.new(alpha, 0, 1, 0)
			progressKnob.Position = UDim2.new(alpha, 0, 0.5, 0)
			timeLabel.Text = formatTime(shownProgress)
		end
		durationLabel.Text = formatTime(durationMs)
	end
	jan:Add(RunService.Heartbeat:Connect(renderProgress))

	local function send(action, extra)
		if not (isConnected and socket) then
			setStatus("Connect the bridge first", Color3.fromRGB(255, 190, 90))
			return false
		end
		local payload = extra or {}
		payload.type = "command"
		payload.action = action
		local ok, err = pcall(function()
			socket:Send(HttpService:JSONEncode(payload))
		end)
		if not ok then
			setStatus("Could not send command: " .. tostring(err), Color3.fromRGB(255, 105, 105))
		end
		return ok
	end

	local function setView(name)
		subTabRoot:SelectSubTabByName(name)
	end

	local function renderFavorites()
		for _, row in ipairs(favoriteRows) do
			row:Destroy()
		end
		table.clear(favoriteRows)
		local query = favoritesSearchBox.Text:lower():gsub("^%s+", ""):gsub("%s+$", "")
		local filtered = {}
		for originalIndex, favorite in ipairs(favorites) do
			local searchable = (tostring(favorite.name or "") .. " " .. tostring(favorite.url or "")):lower()
			if query == "" or searchable:find(query, 1, true) then
				table.insert(filtered, { Favorite = favorite, Index = originalIndex })
			end
		end
		local count = math.min(#filtered, 8)
		local listHeight = count == 0 and 52 or count * 64
		favoritesList.Size = UDim2.new(1, -16, 0, listHeight)
		local dividerY = 51 + listHeight + 7
		saveFavoriteDivider.Position = UDim2.fromOffset(8, dividerY)
		addFavoriteBtn.Position = UDim2.fromOffset(8, dividerY + 10)
		favoritesHeader.Size = UDim2.new(1, 0, 0, dividerY + 74)
		if count == 0 then
			local empty = Instance.new("TextLabel")
			empty.BackgroundTransparency = 1
			empty.FontFace = NullUI.Theme.FontRegular
			empty.Text = query ~= "" and "No saved playlist matches your search" or "No saved playlists yet"
			empty.TextColor3 = NullUI.Theme.TextDim
			Role(empty, "TextDim")
			empty.TextSize = 11
			empty.Size = UDim2.fromScale(1, 1)
			empty.ZIndex = Z.Content + 3
			empty.Parent = favoritesList
			table.insert(favoriteRows, empty)
		else
			for visibleIndex = 1, count do
				local entry = filtered[visibleIndex]
				local favorite = entry.Favorite
				local originalIndex = entry.Index
				local row = Instance.new("Frame")
				row.BackgroundColor3 = Color3.new(1, 1, 1)
				row.BackgroundTransparency = 0.96
				row.BorderSizePixel = 0
				row.Position = UDim2.fromOffset(0, (visibleIndex - 1) * 64)
				row.Size = UDim2.new(1, 0, 0, 58)
				row.ZIndex = Z.Content + 3
				row.Parent = favoritesList
				Corner(row, 10)
				Stroke(row, Color3.new(1, 1, 1), 1, 0.94)
				local playlistIconBox = Instance.new("Frame")
				playlistIconBox.BackgroundColor3 = Color3.new(1, 1, 1)
				playlistIconBox.BackgroundTransparency = 0.91
				playlistIconBox.BorderSizePixel = 0
				playlistIconBox.Position = UDim2.fromOffset(10, 9)
				playlistIconBox.Size = UDim2.fromOffset(40, 40)
				playlistIconBox.ZIndex = Z.Content + 4
				playlistIconBox.Parent = row
				Corner(playlistIconBox, 8)
				local playlistIcon = Instance.new("ImageLabel")
				playlistIcon.BackgroundTransparency = 1
				playlistIcon.Image = ResolveIcon("list-music")
				playlistIcon.ImageColor3 = NullUI.Theme.Text
				Role(playlistIcon, "Text")
				playlistIcon.AnchorPoint = Vector2.new(0.5, 0.5)
				playlistIcon.Position = UDim2.fromScale(0.5, 0.5)
				playlistIcon.Size = UDim2.fromOffset(15, 15)
				playlistIcon.ZIndex = Z.Content + 5
				playlistIcon.Parent = playlistIconBox
				local name = Instance.new("TextLabel")
				name.BackgroundTransparency = 1
				name.FontFace = NullUI.Theme.Font
				name.Text = tostring(favorite.name or "Spotify playlist")
				name.TextColor3 = NullUI.Theme.Text
				Role(name, "Text")
				name.TextSize = 11
				name.TextXAlignment = Enum.TextXAlignment.Left
				name.TextTruncate = Enum.TextTruncate.AtEnd
				name.Position = UDim2.fromOffset(60, 8)
				name.Size = UDim2.new(1, -152, 0, 20)
				name.ZIndex = Z.Content + 4
				name.Parent = row
				local subtitle = Instance.new("TextLabel")
				subtitle.BackgroundTransparency = 1
				subtitle.FontFace = NullUI.Theme.FontRegular
				subtitle.Text = "Spotify playlist"
				subtitle.TextColor3 = NullUI.Theme.TextDim
				Role(subtitle, "TextDim")
				subtitle.TextSize = 9
				subtitle.TextXAlignment = Enum.TextXAlignment.Left
				subtitle.Position = UDim2.fromOffset(60, 30)
				subtitle.Size = UDim2.new(1, -152, 0, 16)
				subtitle.ZIndex = Z.Content + 4
				subtitle.Parent = row
				local loadFavorite = Instance.new("TextButton")
				loadFavorite.Text = ""
				loadFavorite.AutoButtonColor = false
				loadFavorite.BackgroundColor3 = Color3.new(1, 1, 1)
				loadFavorite.BackgroundTransparency = 0.91
				loadFavorite.BorderSizePixel = 0
				loadFavorite.Position = UDim2.new(1, -76, 0, 13)
				loadFavorite.Size = UDim2.fromOffset(32, 32)
				loadFavorite.ZIndex = Z.Content + 5
				loadFavorite.Parent = row
				Corner(loadFavorite, 8)
				local loadFavoriteIcon = Instance.new("ImageLabel")
				loadFavoriteIcon.BackgroundTransparency = 1
				loadFavoriteIcon.Image = ResolveIcon("play")
				loadFavoriteIcon.ImageColor3 = NullUI.Theme.Text
				Role(loadFavoriteIcon, "Text")
				loadFavoriteIcon.AnchorPoint = Vector2.new(0.5, 0.5)
				loadFavoriteIcon.Position = UDim2.fromScale(0.5, 0.5)
				loadFavoriteIcon.Size = UDim2.fromOffset(13, 13)
				loadFavoriteIcon.ZIndex = Z.Content + 6
				loadFavoriteIcon.Parent = loadFavorite
				local removeFavorite = Instance.new("TextButton")
				removeFavorite.Text = ""
				removeFavorite.BackgroundColor3 = Color3.new(1, 1, 1)
				removeFavorite.BackgroundTransparency = 0.94
				removeFavorite.Position = UDim2.new(1, -38, 0, 13)
				removeFavorite.Size = UDim2.fromOffset(30, 32)
				removeFavorite.ZIndex = Z.Content + 5
				removeFavorite.Parent = row
				Corner(removeFavorite, 8)
				local removeFavoriteIcon = Instance.new("ImageLabel")
				removeFavoriteIcon.BackgroundTransparency = 1
				removeFavoriteIcon.Image = ResolveIcon("trash-2")
				removeFavoriteIcon.ImageColor3 = Color3.fromRGB(220, 125, 125)
				removeFavoriteIcon.AnchorPoint = Vector2.new(0.5, 0.5)
				removeFavoriteIcon.Position = UDim2.fromScale(0.5, 0.5)
				removeFavoriteIcon.Size = UDim2.fromOffset(13, 13)
				removeFavoriteIcon.ZIndex = Z.Content + 6
				removeFavoriteIcon.Parent = removeFavorite
				jan:Add(loadFavorite.MouseButton1Click:Connect(function()
					playlistBox.Text = tostring(favorite.url or "")
					setView("Spotify Player")
					if send("load_playlist", { url = playlistBox.Text }) then
						setStatus("Loading favorite playlist...", Color3.fromRGB(30, 215, 96))
						spotifyNotify(
							"favorite_load",
							"Open Spotify Bridge",
							"Open the browser site, wait for the playlist and press Play once. Then return to Roblox to control it here.",
							"warning",
							"external-link",
							8
						)
					end
				end))
				jan:Add(removeFavorite.MouseButton1Click:Connect(function()
					local removedName = tostring(favorite.name or "Spotify playlist")
					table.remove(favorites, originalIndex)
					saveFavorites()
					renderFavorites()
					spotifyNotify("favorite_removed", "Favorite removed", removedName, "success", "trash-2", 3)
				end))
				table.insert(favoriteRows, row)
			end
		end
	end
	jan:Add(favoritesSearchBox:GetPropertyChangedSignal("Text"):Connect(renderFavorites))

	jan:Add(addFavoriteBtn.MouseButton1Click:Connect(function()
		local url = playlistBox.Text:gsub("^%s+", ""):gsub("%s+$", "")
		if url == "" then
			spotifyNotify(
				"favorite_missing",
				"Nothing to save",
				"Paste or load a Spotify playlist first.",
				"warning",
				"heart",
				4
			)
			return
		end
		for _, favorite in ipairs(favorites) do
			if favorite.url == url then
				spotifyNotify(
					"favorite_duplicate",
					"Already saved",
					"This playlist is already in your favorites.",
					"warning",
					"heart",
					4
				)
				return
			end
		end
		table.insert(favorites, 1, { name = currentPlaylistName, url = url })
		saveFavorites()
		renderFavorites()
		spotifyNotify(
			"favorite_saved",
			"Playlist saved",
			currentPlaylistName .. " was added to Favorites.",
			"success",
			"heart",
			4
		)
	end))
	renderFavorites()

	local function paintModes()
		controlRefs.PlayPause.Icon.Image = ResolveIcon(isPlaying and "pause" or "play")
		controlRefs.Shuffle.Icon.ImageColor3 = shuffle and Color3.fromRGB(30, 215, 96) or NullUI.Theme.TextDim
		controlRefs.Repeat.Icon.ImageColor3 = repeatMode ~= "off" and Color3.fromRGB(30, 215, 96)
			or NullUI.Theme.TextDim
	end

	local function applyState(data)
		local track = data.track or data.item or {}
		local artists = track.artist or track.artists or data.artist
		if type(artists) == "table" then
			local names = {}
			for _, artist in ipairs(artists) do
				table.insert(names, type(artist) == "table" and tostring(artist.name or "") or tostring(artist))
			end
			artists = table.concat(names, ", ")
		end
		trackLabel.Text = tostring(track.name or data.trackName or "Nothing playing")
		artistLabel.Text = tostring(artists or "Spotify")
		showCover(track.image or track.imageUrl or track.albumArt or data.image or data.imageUrl)
		isPlaying = data.isPlaying == true or data.playing == true
		shuffle = data.shuffle == true or data.shuffleState == true
		repeatMode = tostring(data.repeatMode or data.repeat_state or "off")
		durationMs = tonumber(track.durationMs or track.duration_ms or data.durationMs or data.duration_ms) or 0
		progressMs = tonumber(data.progressMs or data.progress_ms or data.positionMs or data.position_ms) or 0
		lastStateClock = os.clock()
		paintModes()
		renderProgress()
		if trackLabel.Text ~= "Playlist ready" and trackLabel.Text ~= "Nothing playing" then
			setStatus(
				isPlaying
						and "Playing ÃƒÆ’Ã†â€™Ãƒâ€ Ã¢â‚¬â„¢ÃƒÆ’Ã¢â‚¬Â ÃƒÂ¢Ã¢â€šÂ¬Ã¢â€žÂ¢ÃƒÆ’Ã†â€™ÃƒÂ¢Ã¢â€šÂ¬Ã‚Â ÃƒÆ’Ã‚Â¢ÃƒÂ¢Ã¢â‚¬Å¡Ã‚Â¬ÃƒÂ¢Ã¢â‚¬Å¾Ã‚Â¢ÃƒÆ’Ã†â€™Ãƒâ€ Ã¢â‚¬â„¢ÃƒÆ’Ã‚Â¢ÃƒÂ¢Ã¢â‚¬Å¡Ã‚Â¬Ãƒâ€¦Ã‚Â¡ÃƒÆ’Ã†â€™ÃƒÂ¢Ã¢â€šÂ¬Ã…Â¡ÃƒÆ’Ã¢â‚¬Å¡Ãƒâ€šÃ‚Â¢ÃƒÆ’Ã†â€™Ãƒâ€ Ã¢â‚¬â„¢ÃƒÆ’Ã¢â‚¬Â ÃƒÂ¢Ã¢â€šÂ¬Ã¢â€žÂ¢ÃƒÆ’Ã†â€™ÃƒÂ¢Ã¢â€šÂ¬Ã…Â¡ÃƒÆ’Ã¢â‚¬Å¡Ãƒâ€šÃ‚Â¢ÃƒÆ’Ã†â€™Ãƒâ€ Ã¢â‚¬â„¢ÃƒÆ’Ã¢â‚¬Å¡Ãƒâ€šÃ‚Â¢ÃƒÆ’Ã†â€™Ãƒâ€šÃ‚Â¢ÃƒÆ’Ã‚Â¢ÃƒÂ¢Ã¢â‚¬Å¡Ã‚Â¬Ãƒâ€¦Ã‚Â¡ÃƒÆ’Ã¢â‚¬Å¡Ãƒâ€šÃ‚Â¬ÃƒÆ’Ã†â€™ÃƒÂ¢Ã¢â€šÂ¬Ã‚Â¦ÃƒÆ’Ã¢â‚¬Å¡Ãƒâ€šÃ‚Â¡ÃƒÆ’Ã†â€™Ãƒâ€ Ã¢â‚¬â„¢ÃƒÆ’Ã‚Â¢ÃƒÂ¢Ã¢â‚¬Å¡Ã‚Â¬Ãƒâ€¦Ã‚Â¡ÃƒÆ’Ã†â€™ÃƒÂ¢Ã¢â€šÂ¬Ã…Â¡ÃƒÆ’Ã¢â‚¬Å¡Ãƒâ€šÃ‚Â¬ÃƒÆ’Ã†â€™Ãƒâ€ Ã¢â‚¬â„¢ÃƒÆ’Ã¢â‚¬Â ÃƒÂ¢Ã¢â€šÂ¬Ã¢â€žÂ¢ÃƒÆ’Ã†â€™ÃƒÂ¢Ã¢â€šÂ¬Ã…Â¡ÃƒÆ’Ã¢â‚¬Å¡Ãƒâ€šÃ‚Â¢ÃƒÆ’Ã†â€™Ãƒâ€ Ã¢â‚¬â„¢ÃƒÆ’Ã¢â‚¬Å¡Ãƒâ€šÃ‚Â¢ÃƒÆ’Ã†â€™Ãƒâ€šÃ‚Â¢ÃƒÆ’Ã‚Â¢ÃƒÂ¢Ã¢â€šÂ¬Ã…Â¡Ãƒâ€šÃ‚Â¬ÃƒÆ’Ã¢â‚¬Â¦Ãƒâ€šÃ‚Â¡ÃƒÆ’Ã†â€™ÃƒÂ¢Ã¢â€šÂ¬Ã…Â¡ÃƒÆ’Ã¢â‚¬Å¡Ãƒâ€šÃ‚Â¬ÃƒÆ’Ã†â€™Ãƒâ€ Ã¢â‚¬â„¢ÃƒÆ’Ã‚Â¢ÃƒÂ¢Ã¢â‚¬Å¡Ã‚Â¬Ãƒâ€¦Ã‚Â¡ÃƒÆ’Ã†â€™ÃƒÂ¢Ã¢â€šÂ¬Ã…Â¡ÃƒÆ’Ã¢â‚¬Å¡Ãƒâ€šÃ‚Â controls synced"
					or "Paused ÃƒÆ’Ã†â€™Ãƒâ€ Ã¢â‚¬â„¢ÃƒÆ’Ã¢â‚¬Â ÃƒÂ¢Ã¢â€šÂ¬Ã¢â€žÂ¢ÃƒÆ’Ã†â€™ÃƒÂ¢Ã¢â€šÂ¬Ã‚Â ÃƒÆ’Ã‚Â¢ÃƒÂ¢Ã¢â‚¬Å¡Ã‚Â¬ÃƒÂ¢Ã¢â‚¬Å¾Ã‚Â¢ÃƒÆ’Ã†â€™Ãƒâ€ Ã¢â‚¬â„¢ÃƒÆ’Ã‚Â¢ÃƒÂ¢Ã¢â‚¬Å¡Ã‚Â¬Ãƒâ€¦Ã‚Â¡ÃƒÆ’Ã†â€™ÃƒÂ¢Ã¢â€šÂ¬Ã…Â¡ÃƒÆ’Ã¢â‚¬Å¡Ãƒâ€šÃ‚Â¢ÃƒÆ’Ã†â€™Ãƒâ€ Ã¢â‚¬â„¢ÃƒÆ’Ã¢â‚¬Â ÃƒÂ¢Ã¢â€šÂ¬Ã¢â€žÂ¢ÃƒÆ’Ã†â€™ÃƒÂ¢Ã¢â€šÂ¬Ã…Â¡ÃƒÆ’Ã¢â‚¬Å¡Ãƒâ€šÃ‚Â¢ÃƒÆ’Ã†â€™Ãƒâ€ Ã¢â‚¬â„¢ÃƒÆ’Ã¢â‚¬Å¡Ãƒâ€šÃ‚Â¢ÃƒÆ’Ã†â€™Ãƒâ€šÃ‚Â¢ÃƒÆ’Ã‚Â¢ÃƒÂ¢Ã¢â‚¬Å¡Ã‚Â¬Ãƒâ€¦Ã‚Â¡ÃƒÆ’Ã¢â‚¬Å¡Ãƒâ€šÃ‚Â¬ÃƒÆ’Ã†â€™ÃƒÂ¢Ã¢â€šÂ¬Ã‚Â¦ÃƒÆ’Ã¢â‚¬Å¡Ãƒâ€šÃ‚Â¡ÃƒÆ’Ã†â€™Ãƒâ€ Ã¢â‚¬â„¢ÃƒÆ’Ã‚Â¢ÃƒÂ¢Ã¢â‚¬Å¡Ã‚Â¬Ãƒâ€¦Ã‚Â¡ÃƒÆ’Ã†â€™ÃƒÂ¢Ã¢â€šÂ¬Ã…Â¡ÃƒÆ’Ã¢â‚¬Å¡Ãƒâ€šÃ‚Â¬ÃƒÆ’Ã†â€™Ãƒâ€ Ã¢â‚¬â„¢ÃƒÆ’Ã¢â‚¬Â ÃƒÂ¢Ã¢â€šÂ¬Ã¢â€žÂ¢ÃƒÆ’Ã†â€™ÃƒÂ¢Ã¢â€šÂ¬Ã…Â¡ÃƒÆ’Ã¢â‚¬Å¡Ãƒâ€šÃ‚Â¢ÃƒÆ’Ã†â€™Ãƒâ€ Ã¢â‚¬â„¢ÃƒÆ’Ã¢â‚¬Å¡Ãƒâ€šÃ‚Â¢ÃƒÆ’Ã†â€™Ãƒâ€šÃ‚Â¢ÃƒÆ’Ã‚Â¢ÃƒÂ¢Ã¢â€šÂ¬Ã…Â¡Ãƒâ€šÃ‚Â¬ÃƒÆ’Ã¢â‚¬Â¦Ãƒâ€šÃ‚Â¡ÃƒÆ’Ã†â€™ÃƒÂ¢Ã¢â€šÂ¬Ã…Â¡ÃƒÆ’Ã¢â‚¬Å¡Ãƒâ€šÃ‚Â¬ÃƒÆ’Ã†â€™Ãƒâ€ Ã¢â‚¬â„¢ÃƒÆ’Ã‚Â¢ÃƒÂ¢Ã¢â‚¬Å¡Ã‚Â¬Ãƒâ€¦Ã‚Â¡ÃƒÆ’Ã†â€™ÃƒÂ¢Ã¢â€šÂ¬Ã…Â¡ÃƒÆ’Ã¢â‚¬Å¡Ãƒâ€šÃ‚Â controls synced",
				Color3.fromRGB(30, 215, 96)
			)
		end
	end

	local function clearSocketConnections()
		for _, connection in ipairs(socketConnections) do
			pcall(function()
				connection:Disconnect()
			end)
		end
		table.clear(socketConnections)
	end

	local function disconnectBridge(silent)
		clearSocketConnections()
		local oldSocket = socket
		socket = nil
		isConnected = false
		if connectBtnIcon then
			connectBtnIcon.Image = ResolveIcon("link-2")
		end
		if oldSocket then
			pcall(function()
				oldSocket:Close()
			end)
		end
		if not silent then
			setStatus("Bridge disconnected", Color3.fromRGB(125, 130, 128))
		end
	end

	local function bindSocketEvent(event, callback)
		if event and type(event.Connect) == "function" then
			local ok, connection = pcall(function()
				return event:Connect(callback)
			end)
			if ok and connection then
				table.insert(socketConnections, connection)
			end
		end
	end

	connectBridge = function()
		if isConnected then
			local pageUrl = tostring(opts.ConnectUrl or "")
			local pairUrl = pageUrl .. (pageUrl:find("?", 1, true) and "&" or "?") .. "code=" .. pairBox.Text
			local copy = hasFn("setclipboard")
			if copy then
				pcall(copy, pairUrl)
				setStatus(
					"Player link copied ÃƒÆ’Ã†â€™Ãƒâ€ Ã¢â‚¬â„¢ÃƒÆ’Ã¢â‚¬Â ÃƒÂ¢Ã¢â€šÂ¬Ã¢â€žÂ¢ÃƒÆ’Ã†â€™ÃƒÂ¢Ã¢â€šÂ¬Ã‚Â ÃƒÆ’Ã‚Â¢ÃƒÂ¢Ã¢â‚¬Å¡Ã‚Â¬ÃƒÂ¢Ã¢â‚¬Å¾Ã‚Â¢ÃƒÆ’Ã†â€™Ãƒâ€ Ã¢â‚¬â„¢ÃƒÆ’Ã‚Â¢ÃƒÂ¢Ã¢â‚¬Å¡Ã‚Â¬Ãƒâ€¦Ã‚Â¡ÃƒÆ’Ã†â€™ÃƒÂ¢Ã¢â€šÂ¬Ã…Â¡ÃƒÆ’Ã¢â‚¬Å¡Ãƒâ€šÃ‚Â¢ÃƒÆ’Ã†â€™Ãƒâ€ Ã¢â‚¬â„¢ÃƒÆ’Ã¢â‚¬Â ÃƒÂ¢Ã¢â€šÂ¬Ã¢â€žÂ¢ÃƒÆ’Ã†â€™ÃƒÂ¢Ã¢â€šÂ¬Ã…Â¡ÃƒÆ’Ã¢â‚¬Å¡Ãƒâ€šÃ‚Â¢ÃƒÆ’Ã†â€™Ãƒâ€ Ã¢â‚¬â„¢ÃƒÆ’Ã¢â‚¬Å¡Ãƒâ€šÃ‚Â¢ÃƒÆ’Ã†â€™Ãƒâ€šÃ‚Â¢ÃƒÆ’Ã‚Â¢ÃƒÂ¢Ã¢â‚¬Å¡Ã‚Â¬Ãƒâ€¦Ã‚Â¡ÃƒÆ’Ã¢â‚¬Å¡Ãƒâ€šÃ‚Â¬ÃƒÆ’Ã†â€™ÃƒÂ¢Ã¢â€šÂ¬Ã‚Â¦ÃƒÆ’Ã¢â‚¬Å¡Ãƒâ€šÃ‚Â¡ÃƒÆ’Ã†â€™Ãƒâ€ Ã¢â‚¬â„¢ÃƒÆ’Ã‚Â¢ÃƒÂ¢Ã¢â‚¬Å¡Ã‚Â¬Ãƒâ€¦Ã‚Â¡ÃƒÆ’Ã†â€™ÃƒÂ¢Ã¢â€šÂ¬Ã…Â¡ÃƒÆ’Ã¢â‚¬Å¡Ãƒâ€šÃ‚Â¬ÃƒÆ’Ã†â€™Ãƒâ€ Ã¢â‚¬â„¢ÃƒÆ’Ã¢â‚¬Â ÃƒÂ¢Ã¢â€šÂ¬Ã¢â€žÂ¢ÃƒÆ’Ã†â€™ÃƒÂ¢Ã¢â€šÂ¬Ã…Â¡ÃƒÆ’Ã¢â‚¬Å¡Ãƒâ€šÃ‚Â¢ÃƒÆ’Ã†â€™Ãƒâ€ Ã¢â‚¬â„¢ÃƒÆ’Ã¢â‚¬Å¡Ãƒâ€šÃ‚Â¢ÃƒÆ’Ã†â€™Ãƒâ€šÃ‚Â¢ÃƒÆ’Ã‚Â¢ÃƒÂ¢Ã¢â€šÂ¬Ã…Â¡Ãƒâ€šÃ‚Â¬ÃƒÆ’Ã¢â‚¬Â¦Ãƒâ€šÃ‚Â¡ÃƒÆ’Ã†â€™ÃƒÂ¢Ã¢â€šÂ¬Ã…Â¡ÃƒÆ’Ã¢â‚¬Å¡Ãƒâ€šÃ‚Â¬ÃƒÆ’Ã†â€™Ãƒâ€ Ã¢â‚¬â„¢ÃƒÆ’Ã‚Â¢ÃƒÂ¢Ã¢â‚¬Å¡Ã‚Â¬Ãƒâ€¦Ã‚Â¡ÃƒÆ’Ã†â€™ÃƒÂ¢Ã¢â€šÂ¬Ã…Â¡ÃƒÆ’Ã¢â‚¬Å¡Ãƒâ€šÃ‚Â open it in your browser",
					Color3.fromRGB(30, 215, 96)
				)
				spotifyNotify(
					"link_copied",
					"Player link copied",
					"Open the link in your browser and keep that tab running.",
					"success",
					"external-link",
					6,
					{
						{
							Text = "Copy again",
							Callback = function()
								pcall(copy, pairUrl)
							end,
						},
					}
				)
			else
				setStatus("Open the player page and enter code " .. pairBox.Text, Color3.fromRGB(255, 190, 90))
				spotifyNotify(
					"manual_code",
					"Open Spotify Bridge",
					"Clipboard is unavailable. Open the player page and enter code " .. pairBox.Text .. ".",
					"warning",
					"monitor-up",
					7
				)
			end
			return
		end
		local bridgeUrl = tostring(opts.BridgeUrl or ""):gsub("^%s+", ""):gsub("%s+$", "")
		if not bridgeUrl:match("^wss?://") then
			setStatus("Spotify bridge is not configured by the script owner", Color3.fromRGB(255, 105, 105))
			return
		end
		local url = bridgeUrl
			.. (bridgeUrl:find("?", 1, true) and "&" or "?")
			.. "code="
			.. pairBox.Text
			.. "&role=game"
		local connect = websocketConnect()
		if not connect then
			setStatus("This executor has no WebSocket support", Color3.fromRGB(255, 105, 105))
			return
		end
		setStatus("Connecting...", Color3.fromRGB(255, 190, 90))
		if connectBtnIcon then
			connectBtnIcon.Image = ResolveIcon("loader-circle")
		end
		SafeSpawn(function()
			local ok, result = pcall(connect, url)
			if not ok or not result then
				if connectBtnIcon then
					connectBtnIcon.Image = ResolveIcon("link-2")
				end
				setStatus("Connection failed: " .. tostring(result), Color3.fromRGB(255, 105, 105))
				return
			end
			socket = result
			isConnected = true
			if connectBtnIcon then
				connectBtnIcon.Image = ResolveIcon("copy")
			end
			local pageUrl = tostring(opts.ConnectUrl or "")
			local pairUrl = pageUrl .. (pageUrl:find("?", 1, true) and "&" or "?") .. "code=" .. pairBox.Text
			local copy = hasFn("setclipboard")
			if copy then
				pcall(copy, pairUrl)
			end
			setStatus(
				copy
						and "Player link copied ÃƒÆ’Ã†â€™Ãƒâ€ Ã¢â‚¬â„¢ÃƒÆ’Ã¢â‚¬Â ÃƒÂ¢Ã¢â€šÂ¬Ã¢â€žÂ¢ÃƒÆ’Ã†â€™ÃƒÂ¢Ã¢â€šÂ¬Ã‚Â ÃƒÆ’Ã‚Â¢ÃƒÂ¢Ã¢â‚¬Å¡Ã‚Â¬ÃƒÂ¢Ã¢â‚¬Å¾Ã‚Â¢ÃƒÆ’Ã†â€™Ãƒâ€ Ã¢â‚¬â„¢ÃƒÆ’Ã‚Â¢ÃƒÂ¢Ã¢â‚¬Å¡Ã‚Â¬Ãƒâ€¦Ã‚Â¡ÃƒÆ’Ã†â€™ÃƒÂ¢Ã¢â€šÂ¬Ã…Â¡ÃƒÆ’Ã¢â‚¬Å¡Ãƒâ€šÃ‚Â¢ÃƒÆ’Ã†â€™Ãƒâ€ Ã¢â‚¬â„¢ÃƒÆ’Ã¢â‚¬Â ÃƒÂ¢Ã¢â€šÂ¬Ã¢â€žÂ¢ÃƒÆ’Ã†â€™ÃƒÂ¢Ã¢â€šÂ¬Ã…Â¡ÃƒÆ’Ã¢â‚¬Å¡Ãƒâ€šÃ‚Â¢ÃƒÆ’Ã†â€™Ãƒâ€ Ã¢â‚¬â„¢ÃƒÆ’Ã¢â‚¬Å¡Ãƒâ€šÃ‚Â¢ÃƒÆ’Ã†â€™Ãƒâ€šÃ‚Â¢ÃƒÆ’Ã‚Â¢ÃƒÂ¢Ã¢â‚¬Å¡Ã‚Â¬Ãƒâ€¦Ã‚Â¡ÃƒÆ’Ã¢â‚¬Å¡Ãƒâ€šÃ‚Â¬ÃƒÆ’Ã†â€™ÃƒÂ¢Ã¢â€šÂ¬Ã‚Â¦ÃƒÆ’Ã¢â‚¬Å¡Ãƒâ€šÃ‚Â¡ÃƒÆ’Ã†â€™Ãƒâ€ Ã¢â‚¬â„¢ÃƒÆ’Ã‚Â¢ÃƒÂ¢Ã¢â‚¬Å¡Ã‚Â¬Ãƒâ€¦Ã‚Â¡ÃƒÆ’Ã†â€™ÃƒÂ¢Ã¢â€šÂ¬Ã…Â¡ÃƒÆ’Ã¢â‚¬Å¡Ãƒâ€šÃ‚Â¬ÃƒÆ’Ã†â€™Ãƒâ€ Ã¢â‚¬â„¢ÃƒÆ’Ã¢â‚¬Â ÃƒÂ¢Ã¢â€šÂ¬Ã¢â€žÂ¢ÃƒÆ’Ã†â€™ÃƒÂ¢Ã¢â€šÂ¬Ã…Â¡ÃƒÆ’Ã¢â‚¬Å¡Ãƒâ€šÃ‚Â¢ÃƒÆ’Ã†â€™Ãƒâ€ Ã¢â‚¬â„¢ÃƒÆ’Ã¢â‚¬Å¡Ãƒâ€šÃ‚Â¢ÃƒÆ’Ã†â€™Ãƒâ€šÃ‚Â¢ÃƒÆ’Ã‚Â¢ÃƒÂ¢Ã¢â€šÂ¬Ã…Â¡Ãƒâ€šÃ‚Â¬ÃƒÆ’Ã¢â‚¬Â¦Ãƒâ€šÃ‚Â¡ÃƒÆ’Ã†â€™ÃƒÂ¢Ã¢â€šÂ¬Ã…Â¡ÃƒÆ’Ã¢â‚¬Å¡Ãƒâ€šÃ‚Â¬ÃƒÆ’Ã†â€™Ãƒâ€ Ã¢â‚¬â„¢ÃƒÆ’Ã‚Â¢ÃƒÂ¢Ã¢â‚¬Å¡Ã‚Â¬Ãƒâ€¦Ã‚Â¡ÃƒÆ’Ã†â€™ÃƒÂ¢Ã¢â€šÂ¬Ã…Â¡ÃƒÆ’Ã¢â‚¬Å¡Ãƒâ€šÃ‚Â open it in your browser"
					or ("Open player page; code " .. pairBox.Text),
				Color3.fromRGB(30, 215, 96)
			)
			if copy then
				spotifyNotify(
					"initial_link",
					"Spotify Connect ready",
					"The player link was copied. Open it now and keep the browser tab running.",
					"success",
					"copy-check",
					7,
					{
						{
							Text = "Copy again",
							Callback = function()
								pcall(copy, pairUrl)
							end,
						},
					}
				)
			else
				spotifyNotify(
					"manual_code",
					"Open Spotify Bridge",
					"Enter pairing code " .. pairBox.Text .. " on the player page.",
					"warning",
					"monitor-up",
					7
				)
			end

			bindSocketEvent(socket.OnMessage, function(raw)
				local decoded
				local decodedOk = pcall(function()
					decoded = HttpService:JSONDecode(tostring(raw))
				end)
				if not decodedOk or type(decoded) ~= "table" then
					return
				end
				if decoded.type == "state" or decoded.event == "state" then
					applyState(decoded)
				elseif decoded.type == "queue" then
					local playlist = decoded.playlist or {}
					currentPlaylistName = tostring(playlist.name or "Spotify playlist")
					local trackCount = tonumber(decoded.count) or 0
					setStatus(
						string.format(
							"%s ÃƒÆ’Ã†â€™Ãƒâ€ Ã¢â‚¬â„¢ÃƒÆ’Ã¢â‚¬Â ÃƒÂ¢Ã¢â€šÂ¬Ã¢â€žÂ¢ÃƒÆ’Ã†â€™ÃƒÂ¢Ã¢â€šÂ¬Ã‚Â ÃƒÆ’Ã‚Â¢ÃƒÂ¢Ã¢â‚¬Å¡Ã‚Â¬ÃƒÂ¢Ã¢â‚¬Å¾Ã‚Â¢ÃƒÆ’Ã†â€™Ãƒâ€ Ã¢â‚¬â„¢ÃƒÆ’Ã‚Â¢ÃƒÂ¢Ã¢â‚¬Å¡Ã‚Â¬Ãƒâ€¦Ã‚Â¡ÃƒÆ’Ã†â€™ÃƒÂ¢Ã¢â€šÂ¬Ã…Â¡ÃƒÆ’Ã¢â‚¬Å¡Ãƒâ€šÃ‚Â¢ÃƒÆ’Ã†â€™Ãƒâ€ Ã¢â‚¬â„¢ÃƒÆ’Ã¢â‚¬Â ÃƒÂ¢Ã¢â€šÂ¬Ã¢â€žÂ¢ÃƒÆ’Ã†â€™ÃƒÂ¢Ã¢â€šÂ¬Ã…Â¡ÃƒÆ’Ã¢â‚¬Å¡Ãƒâ€šÃ‚Â¢ÃƒÆ’Ã†â€™Ãƒâ€ Ã¢â‚¬â„¢ÃƒÆ’Ã¢â‚¬Å¡Ãƒâ€šÃ‚Â¢ÃƒÆ’Ã†â€™Ãƒâ€šÃ‚Â¢ÃƒÆ’Ã‚Â¢ÃƒÂ¢Ã¢â‚¬Å¡Ã‚Â¬Ãƒâ€¦Ã‚Â¡ÃƒÆ’Ã¢â‚¬Å¡Ãƒâ€šÃ‚Â¬ÃƒÆ’Ã†â€™ÃƒÂ¢Ã¢â€šÂ¬Ã‚Â¦ÃƒÆ’Ã¢â‚¬Å¡Ãƒâ€šÃ‚Â¡ÃƒÆ’Ã†â€™Ãƒâ€ Ã¢â‚¬â„¢ÃƒÆ’Ã‚Â¢ÃƒÂ¢Ã¢â‚¬Å¡Ã‚Â¬Ãƒâ€¦Ã‚Â¡ÃƒÆ’Ã†â€™ÃƒÂ¢Ã¢â€šÂ¬Ã…Â¡ÃƒÆ’Ã¢â‚¬Å¡Ãƒâ€šÃ‚Â¬ÃƒÆ’Ã†â€™Ãƒâ€ Ã¢â‚¬â„¢ÃƒÆ’Ã¢â‚¬Â ÃƒÂ¢Ã¢â€šÂ¬Ã¢â€žÂ¢ÃƒÆ’Ã†â€™ÃƒÂ¢Ã¢â€šÂ¬Ã…Â¡ÃƒÆ’Ã¢â‚¬Å¡Ãƒâ€šÃ‚Â¢ÃƒÆ’Ã†â€™Ãƒâ€ Ã¢â‚¬â„¢ÃƒÆ’Ã¢â‚¬Å¡Ãƒâ€šÃ‚Â¢ÃƒÆ’Ã†â€™Ãƒâ€šÃ‚Â¢ÃƒÆ’Ã‚Â¢ÃƒÂ¢Ã¢â€šÂ¬Ã…Â¡Ãƒâ€šÃ‚Â¬ÃƒÆ’Ã¢â‚¬Â¦Ãƒâ€šÃ‚Â¡ÃƒÆ’Ã†â€™ÃƒÂ¢Ã¢â€šÂ¬Ã…Â¡ÃƒÆ’Ã¢â‚¬Å¡Ãƒâ€šÃ‚Â¬ÃƒÆ’Ã†â€™Ãƒâ€ Ã¢â‚¬â„¢ÃƒÆ’Ã‚Â¢ÃƒÂ¢Ã¢â‚¬Å¡Ã‚Â¬Ãƒâ€¦Ã‚Â¡ÃƒÆ’Ã†â€™ÃƒÂ¢Ã¢â€šÂ¬Ã…Â¡ÃƒÆ’Ã¢â‚¬Å¡Ãƒâ€šÃ‚Â %d tracks ready",
							currentPlaylistName,
							trackCount
						),
						Color3.fromRGB(30, 215, 96)
					)
					spotifyNotify(
						"queue_ready_" .. currentPlaylistName,
						"Playlist ready",
						string.format("%s loaded with %d tracks.", currentPlaylistName, trackCount),
						"success",
						"list-music",
						4
					)
				elseif decoded.type == "ready" or decoded.event == "ready" then
					local message = tostring(decoded.message or "Spotify ready")
					setStatus(message, Color3.fromRGB(30, 215, 96))
					local lower = message:lower()
					if lower:find("press", 1, true) or lower:find("open", 1, true) or lower:find("tap", 1, true) then
						spotifyNotify(
							"browser_action",
							"Browser action needed",
							"Open Spotify Bridge and press Play once to unlock remote controls.",
							"warning",
							"monitor-play",
							7
						)
					end
				elseif decoded.type == "needs_browser" then
					local message = tostring(decoded.message or "Open the Spotify player tab once to continue playback")
					setStatus(message, Color3.fromRGB(255, 190, 90))
					spotifyNotify(
						"browser_attention",
						"Spotify needs attention",
						message,
						"warning",
						"external-link",
						7
					)
				elseif decoded.type == "error" or decoded.event == "error" then
					local message = tostring(decoded.message or decoded.error or "Spotify bridge error")
					setStatus(message, Color3.fromRGB(255, 105, 105))
					spotifyNotify("spotify_error_" .. message, "Spotify error", message, "error", "circle-x", 6)
				end
			end)
			bindSocketEvent(socket.OnClose, function()
				disconnectBridge(false)
			end)
			send("hello", { client = "NullUI", protocol = 1 })
		end)
	end

	jan:Add(connectBtn.MouseButton1Click:Connect(connectBridge))
	jan:Add(loadBtn.MouseButton1Click:Connect(function()
		local url = playlistBox.Text:gsub("^%s+", ""):gsub("%s+$", "")
		if url == "" then
			setStatus("Paste a Spotify playlist link", Color3.fromRGB(255, 190, 90))
			return
		end
		if send("load_playlist", { url = url }) then
			setStatus("Playlist sent to Spotify", Color3.fromRGB(30, 215, 96))
			spotifyNotify(
				"playlist_sent",
				"Open Spotify Bridge",
				"Open the browser site, wait for the playlist and press Play once. Then return to Roblox to control it here.",
				"warning",
				"external-link",
				8
			)
		end
	end))
	local function searchPlaylist()
		local query = searchBox.Text:gsub("^%s+", ""):gsub("%s+$", "")
		if query == "" then
			setStatus("Type a song or artist to search", Color3.fromRGB(255, 190, 90))
			return
		end
		if send("search", { query = query }) then
			setStatus("Searching this playlist...", Color3.fromRGB(30, 215, 96))
		end
	end
	jan:Add(searchBtn.MouseButton1Click:Connect(searchPlaylist))
	jan:Add(searchBox.FocusLost:Connect(function(enterPressed)
		if enterPressed then
			searchPlaylist()
		end
	end))
	jan:Add(shuffleBtn.MouseButton1Click:Connect(function()
		send("toggle_shuffle")
	end))
	jan:Add(previousBtn.MouseButton1Click:Connect(function()
		send("previous")
	end))
	jan:Add(playBtn.MouseButton1Click:Connect(function()
		send("play_pause")
	end))
	jan:Add(nextBtn.MouseButton1Click:Connect(function()
		send("next")
	end))
	jan:Add(repeatBtn.MouseButton1Click:Connect(function()
		send("cycle_repeat")
	end))
	local seekInput
	local function updateSeekPreview(screenX)
		LPH_ATTRIBUTES(VM(NONE))
		if durationMs <= 0 or progressTrack.AbsoluteSize.X <= 0 then
			return
		end
		local alpha = math.clamp((screenX - progressTrack.AbsolutePosition.X) / progressTrack.AbsoluteSize.X, 0, 1)
		seekPreviewMs = math.floor(durationMs * alpha)
		progressFill.Size = UDim2.new(alpha, 0, 1, 0)
		progressKnob.Position = UDim2.new(alpha, 0, 0.5, 0)
		seekBubble.Position = UDim2.new(math.clamp(alpha, 0.04, 0.96), 0, 0, -8)
		seekBubbleLabel.Text = formatTime(seekPreviewMs)
		timeLabel.Text = formatTime(seekPreviewMs)
	end
	jan:Add(progressHitbox.InputBegan:Connect(function(input)
		if
			input.UserInputType ~= Enum.UserInputType.MouseButton1
			and input.UserInputType ~= Enum.UserInputType.Touch
		then
			return
		end
		if durationMs <= 0 then
			return
		end
		seekDragging = true
		seekInput = input
		seekBubble.Visible = true
		updateSeekPreview(input.Position.X)
	end))
	jan:Add(UserInputService.InputChanged:Connect(function(input)
		LPH_ATTRIBUTES(VM(NONE))
		if not seekDragging then
			return
		end
		if input == seekInput or input.UserInputType == Enum.UserInputType.MouseMovement then
			updateSeekPreview(input.Position.X)
		end
	end))
	jan:Add(UserInputService.InputEnded:Connect(function(input)
		if not seekDragging then
			return
		end
		if input ~= seekInput and input.UserInputType ~= Enum.UserInputType.MouseButton1 then
			return
		end
		updateSeekPreview(input.Position.X)
		seekDragging = false
		seekInput = nil
		seekBubble.Visible = false
		if send("seek", { positionMs = seekPreviewMs }) then
			progressMs = seekPreviewMs
			lastStateClock = os.clock()
		end
		renderProgress()
	end))

	jan:Add(function()
		disconnectBridge(true)
	end)
	dockBtn = self:AddDockButton({
		Icon = opts.Icon or "Lucide:music-2",
		Callback = function()
			panel.Toggle()
		end,
	})

	panel.Connect = connectBridge
	panel.Disconnect = disconnectBridge
	panel.Send = send
	panel.SetState = applyState
	if opts.BridgeUrl == nil or opts.BridgeUrl == "" then
		setStatus("Spotify bridge is not configured by the script owner", Color3.fromRGB(255, 190, 90))
	else
		setStatus("Tap Connect, then open the copied browser link", Color3.fromRGB(125, 130, 128))
	end
	return panel
end

function Window:_BuildDefaultChatTools()
	local windowSelf = self

	return {
		{
			Name = "list_ui_elements",
			Description = "Lists every UI element that has a Flag, with its kind and current value.",
			Parameters = { type = "object", properties = {}, required = {} },
			Handler = function()
				return NullUI:ListUIElements()
			end,
		},
		{
			Name = "set_ui_element_value",
			Description = "Sets a UI element's value by its flag name. Use list_ui_elements first to find valid flags.",
			Parameters = {
				type = "object",
				properties = {
					flag = { type = "string", description = "The Flag of the UI element to change." },
					value = {
						description = "The new value: true/false for a Toggle, a number for a Slider, a string for a Textbox/Dropdown.",
					},
				},
				required = { "flag", "value" },
			},
			Handler = function(args)
				local ok, err = NullUI:SetUIElementValue(args.flag, args.value)
				if not ok then
					error(err, 0)
				end
				return true
			end,
		},
		{
			Name = "select_tab",
			Description = "Switches the panel to one of its top-level sidebar tabs.",
			Parameters = {
				type = "object",
				properties = {
					tab = { type = "string", description = "The tab's name." },
				},
				required = { "tab" },
			},
			Handler = function(args)
				local tabObj = windowSelf:SelectTab(args.tab)
				if not tabObj then
					error("No tab named '" .. tostring(args.tab) .. "'", 0)
				end
				return "Switched to " .. tabObj.Name
			end,
		},
		{
			Name = "select_subtab",
			Description = "Switches to a sub-tab nested under one of the top-level tabs. Selects the "
				.. "parent tab first automatically -- no need to call select_tab beforehand.",
			Parameters = {
				type = "object",
				properties = {
					tab = { type = "string", description = "The top-level tab that contains the sub-tab." },
					subtab = { type = "string", description = "The sub-tab's name." },
				},
				required = { "tab", "subtab" },
			},
			Handler = function(args)
				local tabObj = windowSelf:SelectTab(args.tab)
				if not tabObj then
					error("No tab named '" .. tostring(args.tab) .. "'", 0)
				end
				local sub = tabObj:SelectSubTabByName(args.subtab)
				if not sub then
					error("No sub-tab named '" .. tostring(args.subtab) .. "' under " .. tabObj.Name, 0)
				end
				return "Switched to " .. tabObj.Name .. " > " .. sub.Name
			end,
		},
		{
			Name = "find_and_highlight_element",
			Description = "Finds a UI element (button, toggle, card, slider, etc.) by its visible label, "
				.. "jumps to whichever tab or sub-tab it lives on, scrolls to it, and flashes a highlight "
				.. "on it -- the same thing Ctrl+K search does when you click a result.",
			Parameters = {
				type = "object",
				properties = {
					query = { type = "string", description = "The element's visible text. Partial matches are fine." },
				},
				required = { "query" },
			},
			Handler = function(args)
				local ok, titleOrErr = windowSelf:JumpToElement(args.query)
				if not ok then
					error(titleOrErr, 0)
				end
				return "Highlighted: " .. titleOrErr
			end,
		},
	}
end

function Window:_BuildDefaultSystemPrompt()
	local names = {}
	for _, t in ipairs(self._tabs) do
		if not t.Hidden then
			table.insert(names, t.Name)
		end
	end

	return "You are a helpful assistant embedded in a Roblox UI panel built with NullUI. Your tools "
		.. "only affect THIS PANEL -- they inspect/adjust the panel's own toggles/sliders/etc, switch "
		.. "between its top-level tabs ("
		.. table.concat(names, ", ")
		.. "), switch to a specific "
		.. "sub-tab within one of those, and jump to/highlight a specific UI element on the panel by "
		.. "its visible label. Only use select_tab, select_subtab, or find_and_highlight_element when "
		.. "the user is asking to be taken somewhere IN THIS PANEL, or to interact with a control "
		.. "that's actually on it. If the user asks you to write a script, explain something, or "
		.. "anything else that isn't about navigating this panel, just answer directly in chat -- do "
		.. "not call a tool just because the message happens to mention a word that sounds like a "
		.. "setting. When you write a Luau script for the user, put it in a normal ```lua fenced block "
		.. "-- the panel automatically adds a Run button to it that the user can click themselves, so "
		.. "you don't need to explain how to run it or tell them you can't execute code; you're just "
		.. "not the one who decides to run it -- they click Run after reading it. Keep answers short "
		.. "and to the point. None of your tools execute anything outside this panel, and you have no "
		.. "way to trigger the Run button yourself."
end

function Window:AddChatPanel(opts)
	opts = opts or {}
	opts.Tools = opts.Tools or self:_BuildDefaultChatTools()
	local jan = self._janitor

	local tabObj = self:AddTab({
		Name = opts.Name or "Assistant",
		Icon = opts.Icon or "bot",
		Hidden = true,
	})
	tabObj._page.Visible = false

	local staleEmptyState = tabObj._group:FindFirstChild("EmptyState")
	if staleEmptyState then
		staleEmptyState.Visible = false
	end

	local toolByName = {}
	for _, tool in ipairs(opts.Tools or {}) do
		if tool.Name then
			toolByName[tool.Name] = tool
		end
	end

	local INPUT_H = 38
	local HEADER_H = 38

	local panel = Instance.new("Frame")
	panel.Name = "ChatPanel"
	panel.BackgroundTransparency = 1
	panel.ClipsDescendants = true
	panel.Size = UDim2.fromScale(1, 1)
	panel.ZIndex = Z.Content
	panel.Parent = tabObj._group

	local BASE_Z = panel.ZIndex + 1

	local content = Instance.new("Frame")
	content.Name = "Content"
	content.BackgroundTransparency = 1
	content.Size = UDim2.fromScale(1, 1)
	content.ZIndex = panel.ZIndex
	content.Parent = panel

	local header = Instance.new("Frame")
	header.BackgroundTransparency = 1
	header.Active = true
	header.Size = UDim2.new(1, 0, 0, HEADER_H)
	header.ZIndex = BASE_Z
	header.Parent = content

	local headerPad = Instance.new("UIPadding")
	headerPad.PaddingLeft = UDim.new(0, 14)
	headerPad.PaddingRight = UDim.new(0, 8)
	headerPad.Parent = header

	local titleRow = Instance.new("Frame")
	titleRow.BackgroundTransparency = 1
	titleRow.Size = UDim2.new(1, -84, 1, 0)
	titleRow.ZIndex = BASE_Z + 1
	titleRow.Parent = header

	local titleLayout = Instance.new("UIListLayout")
	titleLayout.FillDirection = Enum.FillDirection.Horizontal
	titleLayout.VerticalAlignment = Enum.VerticalAlignment.Center
	titleLayout.Padding = UDim.new(0, 7)
	titleLayout.Parent = titleRow

	local titleIcon = Instance.new("ImageLabel")
	titleIcon.BackgroundTransparency = 1
	titleIcon.Image = ResolveIcon(opts.Icon or "bot")
	titleIcon.ImageColor3 = NullUI.Theme.Text
	Role(titleIcon, "Text")
	titleIcon.Size = UDim2.fromOffset(14, 14)
	titleIcon.LayoutOrder = 1
	titleIcon.ZIndex = BASE_Z + 2
	titleIcon.Parent = titleRow

	local titleLabel = Instance.new("TextLabel")
	titleLabel.BackgroundTransparency = 1
	titleLabel.FontFace = NullUI.Theme.Font
	titleLabel.Text = opts.Title or "Assistant"
	titleLabel.TextColor3 = NullUI.Theme.Text
	Role(titleLabel, "Text")
	titleLabel.TextSize = 14
	titleLabel.TextXAlignment = Enum.TextXAlignment.Left
	titleLabel.AutomaticSize = Enum.AutomaticSize.X
	titleLabel.Size = UDim2.fromOffset(0, 16)
	titleLabel.LayoutOrder = 2
	titleLabel.ZIndex = BASE_Z + 2
	titleLabel.Parent = titleRow

	local controls = Instance.new("Frame")
	controls.BackgroundTransparency = 1
	controls.AnchorPoint = Vector2.new(1, 0.5)
	controls.Position = UDim2.new(1, 0, 0.5, 0)
	controls.Size = UDim2.fromOffset(100, 22)
	controls.ZIndex = BASE_Z + 1
	controls.Parent = header

	local controlsLayout = Instance.new("UIListLayout")
	controlsLayout.FillDirection = Enum.FillDirection.Horizontal
	controlsLayout.HorizontalAlignment = Enum.HorizontalAlignment.Right
	controlsLayout.VerticalAlignment = Enum.VerticalAlignment.Center
	controlsLayout.Padding = UDim.new(0, 4)
	controlsLayout.Parent = controls

	local function headerIconButton(icon, layoutOrder)
		local btn = Instance.new("TextButton")
		btn.Text = ""
		btn.AutoButtonColor = false
		btn.BackgroundColor3 = Color3.new(1, 1, 1)
		btn.BackgroundTransparency = 1
		btn.BorderSizePixel = 0
		btn.Size = UDim2.fromOffset(22, 22)
		btn.LayoutOrder = layoutOrder
		btn.ZIndex = BASE_Z + 1
		btn.Parent = controls
		Corner(btn, 6)

		local ic = Instance.new("ImageLabel")
		ic.BackgroundTransparency = 1
		ic.Image = ResolveIcon(icon)
		ic.ImageColor3 = NullUI.Theme.TextDim
		Role(ic, "TextDim")
		ic.Size = UDim2.fromOffset(13, 13)
		ic.AnchorPoint = Vector2.new(0.5, 0.5)
		ic.Position = UDim2.fromScale(0.5, 0.5)
		ic.ZIndex = BASE_Z + 2
		ic.Parent = btn

		jan:Add(btn.MouseEnter:Connect(function()
			Tween(btn, { BackgroundTransparency = 0.9 }, 0.12)
			Tween(ic, { ImageColor3 = NullUI.Theme.Text }, 0.12)
		end))
		jan:Add(btn.MouseLeave:Connect(function()
			Tween(btn, { BackgroundTransparency = 1 }, 0.12)
			Tween(ic, { ImageColor3 = NullUI.Theme.TextDim }, 0.12)
		end))

		return btn, ic
	end

	local copyBtn, copyIcon = headerIconButton("copy", 1)
	local regenBtn, regenIcon = headerIconButton("refresh-cw", 2)
	local clearBtn = headerIconButton("trash-2", 3)
	local closeBtn = headerIconButton("x", 4)

	local headerDivider = Instance.new("Frame")
	headerDivider.BackgroundColor3 = Color3.new(1, 1, 1)
	headerDivider.BackgroundTransparency = 0.94
	headerDivider.BorderSizePixel = 0
	headerDivider.Position = UDim2.fromOffset(0, HEADER_H)
	headerDivider.Size = UDim2.new(1, 0, 0, 1)
	headerDivider.ZIndex = BASE_Z
	headerDivider.Parent = content

	local contentPad = Instance.new("UIPadding")
	contentPad.PaddingLeft = UDim.new(0, 14)
	contentPad.PaddingRight = UDim.new(0, 14)
	contentPad.PaddingBottom = UDim.new(0, 12)
	contentPad.Parent = content

	local inputRow = Instance.new("Frame")
	inputRow.BackgroundTransparency = 1
	inputRow.Active = true
	inputRow.AnchorPoint = Vector2.new(0, 1)
	inputRow.Position = UDim2.new(0, 0, 1, 0)
	inputRow.Size = UDim2.new(1, 0, 0, INPUT_H)
	inputRow.ZIndex = BASE_Z
	inputRow.Parent = content

	local pill = Instance.new("Frame")
	pill.BackgroundColor3 = Color3.new(1, 1, 1)
	pill.BackgroundTransparency = 0.95
	pill.BorderSizePixel = 0
	pill.Size = UDim2.new(1, -(INPUT_H + 6), 1, 0)
	pill.ZIndex = BASE_Z + 1
	pill.Parent = inputRow
	Corner(pill, 9)
	local pillStroke = Stroke(pill, Color3.new(1, 1, 1), 1, 0.9)

	local pillPad = Instance.new("UIPadding")
	pillPad.PaddingLeft = UDim.new(0, 10)
	pillPad.PaddingRight = UDim.new(0, 10)
	pillPad.Parent = pill

	local inputBox = Instance.new("TextBox")
	inputBox.BackgroundTransparency = 1
	inputBox.ClearTextOnFocus = false
	inputBox.FontFace = NullUI.Theme.FontRegular
	inputBox.PlaceholderText = opts.Placeholder or "Ask me anything..."
	inputBox.PlaceholderColor3 = Color3.fromRGB(120, 120, 122)
	inputBox.Text = ""
	inputBox.TextColor3 = NullUI.Theme.Text
	Role(inputBox, "Text")
	inputBox.TextSize = 13
	inputBox.TextXAlignment = Enum.TextXAlignment.Left
	inputBox.TextYAlignment = Enum.TextYAlignment.Center
	inputBox.ClipsDescendants = true
	inputBox.Size = UDim2.fromScale(1, 1)
	inputBox.ZIndex = BASE_Z + 2
	inputBox.Parent = pill

	jan:Add(inputBox.Focused:Connect(function()
		Tween(pillStroke, { Color = NullUI.Theme.Accent, Transparency = 0.3 }, 0.18)
	end))
	jan:Add(inputBox.FocusLost:Connect(function()
		Tween(pillStroke, { Color = Color3.new(1, 1, 1), Transparency = 0.9 }, 0.18)
	end))

	local sendBtn = Instance.new("TextButton")
	sendBtn.Name = "Send"
	sendBtn.Text = ""
	sendBtn.AutoButtonColor = false
	sendBtn.BackgroundColor3 = Color3.new(1, 1, 1)
	sendBtn.BackgroundTransparency = 0.9
	sendBtn.BorderSizePixel = 0
	sendBtn.AnchorPoint = Vector2.new(1, 0)
	sendBtn.Position = UDim2.new(1, 0, 0, 0)
	sendBtn.Size = UDim2.fromOffset(INPUT_H, INPUT_H)
	sendBtn.ZIndex = BASE_Z + 1
	sendBtn.Parent = inputRow
	Corner(sendBtn, 9)

	local sendIcon = Instance.new("ImageLabel")
	sendIcon.BackgroundTransparency = 1
	sendIcon.Image = ResolveIcon("send")
	sendIcon.ImageColor3 = NullUI.Theme.Text
	Role(sendIcon, "Text")
	sendIcon.Size = UDim2.fromOffset(14, 14)
	sendIcon.AnchorPoint = Vector2.new(0.5, 0.5)
	sendIcon.Position = UDim2.fromScale(0.5, 0.5)
	sendIcon.ZIndex = BASE_Z + 2
	sendIcon.Parent = sendBtn

	jan:Add(sendBtn.MouseEnter:Connect(function()
		Tween(sendBtn, { BackgroundTransparency = 0.8 }, 0.12)
	end))
	jan:Add(sendBtn.MouseLeave:Connect(function()
		Tween(sendBtn, { BackgroundTransparency = 0.9 }, 0.12)
	end))

	local msgScroll = Instance.new("ScrollingFrame")
	msgScroll.BackgroundTransparency = 1
	msgScroll.BorderSizePixel = 0
	msgScroll.Position = UDim2.fromOffset(0, HEADER_H + 9)
	msgScroll.Size = UDim2.new(1, 0, 1, -(HEADER_H + 9 + INPUT_H + 10))
	msgScroll.ScrollingDirection = Enum.ScrollingDirection.Y
	msgScroll.ScrollBarThickness = 0
	msgScroll.AutomaticCanvasSize = Enum.AutomaticSize.Y
	msgScroll.CanvasSize = UDim2.new(0, 0, 0, 0)
	msgScroll.ZIndex = BASE_Z
	msgScroll.Parent = content

	local msgPad = Instance.new("UIPadding")
	msgPad.PaddingRight = UDim.new(0, 18)
	msgPad.Parent = msgScroll

	local msgLayout = Instance.new("UIListLayout")
	msgLayout.Padding = UDim.new(0, 8)
	msgLayout.SortOrder = Enum.SortOrder.LayoutOrder
	msgLayout.Parent = msgScroll

	AddScrollbar(msgScroll)
	AddContentScrollThumb(msgScroll, msgLayout, panel, jan)

	local order = 0
	local transcript = {}

	local pinnedToBottom = true
	jan:Add(msgScroll:GetPropertyChangedSignal("AbsoluteCanvasSize"):Connect(function()
		if pinnedToBottom then
			msgScroll.CanvasPosition = Vector2.new(0, msgScroll.AbsoluteCanvasSize.Y)
		end
	end))
	jan:Add(msgScroll:GetPropertyChangedSignal("CanvasPosition"):Connect(function()
		LPH_ATTRIBUTES(VM(NONE))
		local atBottom = msgScroll.CanvasPosition.Y
			>= msgScroll.AbsoluteCanvasSize.Y - msgScroll.AbsoluteWindowSize.Y - 20
		pinnedToBottom = atBottom
	end))

	local function scrollToBottom()
		pinnedToBottom = true
		SafeDefer(function()
			if msgScroll and msgScroll.Parent then
				msgScroll.CanvasPosition = Vector2.new(0, msgScroll.AbsoluteCanvasSize.Y)
			end
		end)
	end

	local AVATAR = 26

	local function addBubble(text, role)
		local isUser = role == "user"
		order = order + 1

		text = text:gsub("^%s+", ""):gsub("%s+$", ""):gsub("\n\n\n+", "\n\n")

		local row = Instance.new("Frame")
		row.Name = "MessageRow"
		row.BackgroundTransparency = 1
		row.AutomaticSize = Enum.AutomaticSize.Y
		row.Size = UDim2.new(1, 0, 0, 0)
		row.LayoutOrder = order
		row.ZIndex = BASE_Z + 1
		row.Parent = msgScroll

		local rowScale = Instance.new("UIScale")
		rowScale.Scale = 0.92
		rowScale.Parent = row

		local rowLayout = Instance.new("UIListLayout")
		rowLayout.FillDirection = Enum.FillDirection.Horizontal
		rowLayout.HorizontalAlignment = isUser and Enum.HorizontalAlignment.Right or Enum.HorizontalAlignment.Left
		rowLayout.VerticalAlignment = Enum.VerticalAlignment.Top
		rowLayout.Padding = UDim.new(0, 8)
		rowLayout.Parent = row

		local avatarFinalTransparency = isUser and 0.85 or 0.82
		local avatar = Instance.new("Frame")
		avatar.Name = "Avatar"
		avatar.BackgroundColor3 = isUser and Color3.new(1, 1, 1) or NullUI.Theme.Accent
		avatar.BackgroundTransparency = 1
		avatar.BorderSizePixel = 0
		avatar.Size = UDim2.fromOffset(AVATAR, AVATAR)
		avatar.LayoutOrder = isUser and 2 or 1
		avatar.ZIndex = BASE_Z + 2
		avatar.Parent = row
		Corner(avatar, AVATAR / 2)

		local avatarIcon
		if isUser then
			local img = Instance.new("ImageLabel")
			img.BackgroundTransparency = 1
			img.ImageTransparency = 1
			img.ScaleType = Enum.ScaleType.Crop
			img.Size = UDim2.fromScale(1, 1)
			img.ZIndex = BASE_Z + 3
			img.Parent = avatar
			Corner(img, AVATAR / 2)
			avatarIcon = img
			SafeSpawn(function()
				local ok, content = pcall(
					Players.GetUserThumbnailAsync,
					Players,
					LocalPlayer.UserId,
					Enum.ThumbnailType.HeadShot,
					Enum.ThumbnailSize.Size100x100
				)
				if ok and content and img.Parent then
					img.Image = content
				end
			end)
		else
			local botIcon = Instance.new("ImageLabel")
			botIcon.BackgroundTransparency = 1
			botIcon.ImageTransparency = 1
			botIcon.Image = ResolveIcon("bot")
			botIcon.ImageColor3 = NullUI.Theme.Accent
			botIcon.Size = UDim2.fromOffset(14, 14)
			botIcon.AnchorPoint = Vector2.new(0.5, 0.5)
			botIcon.Position = UDim2.fromScale(0.5, 0.5)
			botIcon.ZIndex = BASE_Z + 3
			botIcon.Parent = avatar
			avatarIcon = botIcon
		end

		local segments = SplitMessageSegments(text)
		local hasCode = false
		for _, seg in ipairs(segments) do
			if seg.kind == "code" then
				hasCode = true
			end
		end

		local H_PAD, V_PAD = 10, 8
		local BUBBLE_MAX_WIDTH = hasCode and 380 or 260
		local bubbleWidth
		if hasCode then
			bubbleWidth = BUBBLE_MAX_WIDTH
		else
			local naturalW = MeasureText(segments[1].content, 13, 10000)
			bubbleWidth = math.min(naturalW, BUBBLE_MAX_WIDTH - H_PAD * 2) + H_PAD * 2
		end
		if msgScroll.AbsoluteSize.X > 0 then
			bubbleWidth = math.min(bubbleWidth, math.max(200, msgScroll.AbsoluteSize.X - 20))
		end

		local bubbleFinalTransparency = isUser and 0.72 or 0.9
		local bubble = Instance.new("Frame")
		bubble.Name = "Bubble"
		bubble.BackgroundColor3 = isUser and NullUI.Theme.Accent or Color3.new(1, 1, 1)
		bubble.BackgroundTransparency = 1
		bubble.BorderSizePixel = 0
		bubble.AutomaticSize = Enum.AutomaticSize.Y
		bubble.Size = UDim2.fromOffset(bubbleWidth, 0)
		bubble.LayoutOrder = isUser and 1 or 2
		bubble.ZIndex = BASE_Z + 2
		bubble.Parent = row
		Corner(bubble, 12)
		local strokeFinalTransparency = isUser and 0.8 or 0.9
		local bubbleStroke = Stroke(bubble, Color3.new(1, 1, 1), 1, 1)

		local bubblePad = Instance.new("UIPadding")
		bubblePad.PaddingTop = UDim.new(0, V_PAD)
		bubblePad.PaddingBottom = UDim.new(0, V_PAD)
		bubblePad.PaddingLeft = UDim.new(0, H_PAD)
		bubblePad.PaddingRight = UDim.new(0, H_PAD)
		bubblePad.Parent = bubble

		local bubbleLayout = Instance.new("UIListLayout")
		bubbleLayout.FillDirection = Enum.FillDirection.Vertical
		bubbleLayout.Padding = UDim.new(0, 8)
		bubbleLayout.SortOrder = Enum.SortOrder.LayoutOrder
		bubbleLayout.Parent = bubble

		Tween(avatar, { BackgroundTransparency = avatarFinalTransparency }, 0.18)
		Tween(avatarIcon, { ImageTransparency = 0 }, 0.18)
		Tween(bubble, { BackgroundTransparency = bubbleFinalTransparency }, 0.18)
		Tween(bubbleStroke, { Transparency = strokeFinalTransparency }, 0.18)
		Tween(rowScale, { Scale = 1 }, 0.26, Enum.EasingStyle.Back, Enum.EasingDirection.Out)

		local TYPE_START_DELAY = 0.08
		local maxTypeDuration = 0

		for i, seg in ipairs(segments) do
			if seg.kind == "code" then
				local card = Instance.new("Frame")
				card.Name = "CodeBlock"
				card.BackgroundColor3 = NullUI.Theme.Background
				card.BackgroundTransparency = 0.1
				card.BorderSizePixel = 0
				card.ClipsDescendants = true
				card.AutomaticSize = Enum.AutomaticSize.Y
				card.Size = UDim2.new(1, 0, 0, 0)
				card.LayoutOrder = i
				card.ZIndex = BASE_Z + 3
				card.Parent = bubble
				Corner(card, 8)
				Stroke(card, Color3.new(1, 1, 1), 1, 0.92)

				local cardLayout = Instance.new("UIListLayout")
				cardLayout.FillDirection = Enum.FillDirection.Vertical
				cardLayout.SortOrder = Enum.SortOrder.LayoutOrder
				cardLayout.Parent = card

				local header = Instance.new("Frame")
				header.BackgroundTransparency = 1
				header.Size = UDim2.new(1, 0, 0, 24)
				header.LayoutOrder = 1
				header.ZIndex = BASE_Z + 4
				header.Parent = card

				local langLabel = Instance.new("TextLabel")
				langLabel.BackgroundTransparency = 1
				langLabel.FontFace = NullUI.Theme.FontRegular
				langLabel.Text = seg.lang
				langLabel.TextColor3 = NullUI.Theme.TextDim
				Role(langLabel, "TextDim")
				langLabel.TextSize = 11
				langLabel.TextXAlignment = Enum.TextXAlignment.Left
				langLabel.Position = UDim2.fromOffset(10, 0)
				langLabel.Size = UDim2.new(1, -70, 1, 0)
				langLabel.ZIndex = BASE_Z + 5
				langLabel.Parent = header

				local function codeHeaderButton(icon, rightOffset)
					local btn = Instance.new("TextButton")
					btn.Text = ""
					btn.AutoButtonColor = false
					btn.BackgroundColor3 = Color3.new(1, 1, 1)
					btn.BackgroundTransparency = 1
					btn.BorderSizePixel = 0
					btn.AnchorPoint = Vector2.new(1, 0.5)
					btn.Position = UDim2.new(1, -rightOffset, 0.5, 0)
					btn.Size = UDim2.fromOffset(20, 20)
					btn.ZIndex = BASE_Z + 5
					btn.Parent = header
					Corner(btn, 5)

					local ic = Instance.new("ImageLabel")
					ic.BackgroundTransparency = 1
					ic.Image = ResolveIcon(icon)
					ic.ImageColor3 = NullUI.Theme.TextDim
					Role(ic, "TextDim")
					ic.Size = UDim2.fromOffset(12, 12)
					ic.AnchorPoint = Vector2.new(0.5, 0.5)
					ic.Position = UDim2.fromScale(0.5, 0.5)
					ic.ZIndex = BASE_Z + 6
					ic.Parent = btn

					jan:Add(btn.MouseEnter:Connect(function()
						Tween(btn, { BackgroundTransparency = 0.85 }, 0.12)
						Tween(ic, { ImageColor3 = NullUI.Theme.Text }, 0.12)
					end))
					jan:Add(btn.MouseLeave:Connect(function()
						Tween(btn, { BackgroundTransparency = 1 }, 0.12)
						Tween(ic, { ImageColor3 = NullUI.Theme.TextDim }, 0.12)
					end))

					return btn, ic
				end

				local copyBtn, copyIcon = codeHeaderButton("copy", 8)
				jan:Add(copyBtn.MouseButton1Click:Connect(function()
					local setclipboard = hasFn("setclipboard")
					if not setclipboard then
						return
					end
					pcall(setclipboard, seg.content)
					Tween(copyIcon, { ImageColor3 = Color3.fromRGB(120, 220, 140) }, 0.12)
					SafeDelay(0.4, function()
						if copyIcon.Parent then
							Tween(copyIcon, { ImageColor3 = NullUI.Theme.TextDim }, 0.18)
						end
					end)
				end))

				if opts.OnRunCode then
					local runBtn, runIcon = codeHeaderButton("play", 32)
					jan:Add(runBtn.MouseButton1Click:Connect(function()
						NullUI:Confirm({
							Title = "Run this code?",
							Text = "This runs exactly what's shown above, right now, in this game.",
							ConfirmText = "Run",
							CancelText = "Cancel",
							Danger = true,
							Window = self,
							Callback = function(confirmed)
								if not confirmed then
									return
								end
								local ok, err = pcall(opts.OnRunCode, seg.content, seg.lang)
								NullUI:Notify({
									Title = ok and "Ran" or "Run failed",
									Text = ok and "Code executed." or tostring(err),
									Type = ok and "success" or "error",
									Duration = 3,
								})
							end,
						})
					end))
				end

				local headerDivider = Instance.new("Frame")
				headerDivider.BackgroundColor3 = Color3.new(1, 1, 1)
				headerDivider.BackgroundTransparency = 0.92
				headerDivider.BorderSizePixel = 0
				headerDivider.Size = UDim2.new(1, 0, 0, 1)
				headerDivider.LayoutOrder = 2
				headerDivider.ZIndex = BASE_Z + 4
				headerDivider.Parent = card

				local codeContainer = Instance.new("Frame")
				codeContainer.BackgroundTransparency = 1
				codeContainer.AutomaticSize = Enum.AutomaticSize.Y
				codeContainer.Size = UDim2.new(1, 0, 0, 0)
				codeContainer.LayoutOrder = 3
				codeContainer.ZIndex = BASE_Z + 4
				codeContainer.Parent = card

				local codePad = Instance.new("UIPadding")
				codePad.PaddingTop = UDim.new(0, 8)
				codePad.PaddingBottom = UDim.new(0, 8)
				codePad.PaddingLeft = UDim.new(0, 10)
				codePad.PaddingRight = UDim.new(0, 10)
				codePad.Parent = codeContainer

				local codeLabel = Instance.new("TextLabel")
				codeLabel.BackgroundTransparency = 1
				codeLabel.FontFace = Font.new(CHAT_CODE_FONT, Enum.FontWeight.Regular, Enum.FontStyle.Normal)
				codeLabel.RichText = true
				codeLabel.Text = HighlightLua(EscapeRichText(seg.content))
				codeLabel.TextColor3 = NullUI.Theme.Text
				Role(codeLabel, "Text")
				codeLabel.TextSize = 12
				codeLabel.TextWrapped = true
				codeLabel.TextXAlignment = Enum.TextXAlignment.Left
				codeLabel.TextYAlignment = Enum.TextYAlignment.Top
				codeLabel.LineHeight = 1.3
				codeLabel.AutomaticSize = Enum.AutomaticSize.Y
				codeLabel.Size = UDim2.new(1, 0, 0, 16)
				codeLabel.ZIndex = BASE_Z + 5
				codeLabel.Parent = codeContainer
			else
				local label = Instance.new("TextLabel")
				label.Name = "Prose"
				label.BackgroundTransparency = 1
				label.FontFace = NullUI.Theme.FontRegular
				label.RichText = true
				label.Text = MarkdownToRichText(seg.content)
				label.TextColor3 = NullUI.Theme.Text
				Role(label, "Text")
				label.TextTransparency = 1
				label.TextSize = 13
				label.TextWrapped = true
				label.TextXAlignment = Enum.TextXAlignment.Left
				label.TextYAlignment = Enum.TextYAlignment.Top
				label.LineHeight = 1.3
				label.AutomaticSize = Enum.AutomaticSize.Y
				label.Size = UDim2.new(1, 0, 0, 16)
				label.LayoutOrder = i
				label.ZIndex = BASE_Z + 3

				label.MaxVisibleGraphemes = 0
				label.Parent = bubble

				Tween(label, { TextTransparency = 0 }, 0.18)

				local graphemeCount = utf8.len(seg.content) or #seg.content
				local typeDuration = math.clamp(graphemeCount * 0.014, 0.12, 1.6)
				maxTypeDuration = math.max(maxTypeDuration, typeDuration)
				SafeDelay(TYPE_START_DELAY, function()
					if label and label.Parent then
						TweenService:Create(
							label,
							TweenInfo.new(typeDuration, Enum.EasingStyle.Linear),
							{ MaxVisibleGraphemes = graphemeCount }
						):Play()
					end
				end)
			end
		end

		scrollToBottom()
		table.insert(transcript, (isUser and "You" or "Assistant") .. ": " .. text)

		return TYPE_START_DELAY + maxTypeDuration
	end

	local bumpTypingToBottom

	local function addToolLine(name)
		order = order + 1
		local row = Instance.new("Frame")
		row.Name = "ToolCall"
		row.BackgroundTransparency = 1
		row.AutomaticSize = Enum.AutomaticSize.Y
		row.Size = UDim2.new(1, 0, 0, 18)
		row.LayoutOrder = order
		row.ZIndex = BASE_Z + 1
		row.Parent = msgScroll

		local rowLayout = Instance.new("UIListLayout")
		rowLayout.FillDirection = Enum.FillDirection.Horizontal
		rowLayout.VerticalAlignment = Enum.VerticalAlignment.Center
		rowLayout.Padding = UDim.new(0, 6)
		rowLayout.Parent = row

		local toolIcon = Instance.new("ImageLabel")
		toolIcon.BackgroundTransparency = 1
		toolIcon.Image = ResolveIcon("wrench")
		toolIcon.ImageColor3 = NullUI.Theme.Accent
		toolIcon.Size = UDim2.fromOffset(11, 11)
		toolIcon.LayoutOrder = 1
		toolIcon.ZIndex = BASE_Z + 2
		toolIcon.Parent = row

		local label = Instance.new("TextLabel")
		label.BackgroundTransparency = 1
		label.FontFace = NullUI.Theme.FontRegular
		label.Text = "Called tool: " .. tostring(name)
		label.TextColor3 = NullUI.Theme.TextDim
		Role(label, "TextDim")
		label.TextSize = 11
		label.AutomaticSize = Enum.AutomaticSize.XY
		label.Size = UDim2.fromOffset(0, 14)
		label.LayoutOrder = 2
		label.ZIndex = BASE_Z + 2
		label.Parent = row

		scrollToBottom()
		table.insert(transcript, "[Called tool: " .. tostring(name) .. "]")
		if bumpTypingToBottom then
			bumpTypingToBottom()
		end
	end

	local typingRow, typingTweens, typingActive = nil, nil, false

	local function destroyTypingRow()
		if not typingRow then
			return
		end
		for _, tw in ipairs(typingTweens) do
			tw:Cancel()
		end
		local row = typingRow
		typingRow, typingTweens = nil, nil
		row:Destroy()
	end

	local function buildTypingRow()
		order = order + 1

		local row = Instance.new("Frame")
		row.Name = "TypingRow"
		row.BackgroundTransparency = 1
		row.AutomaticSize = Enum.AutomaticSize.Y
		row.Size = UDim2.new(1, 0, 0, 0)
		row.LayoutOrder = order
		row.ZIndex = BASE_Z + 1
		row.Parent = msgScroll

		local rowLayout = Instance.new("UIListLayout")
		rowLayout.FillDirection = Enum.FillDirection.Horizontal
		rowLayout.VerticalAlignment = Enum.VerticalAlignment.Top
		rowLayout.Padding = UDim.new(0, 8)
		rowLayout.Parent = row

		local avatar = Instance.new("Frame")
		avatar.BackgroundColor3 = NullUI.Theme.Accent
		avatar.BackgroundTransparency = 1
		avatar.BorderSizePixel = 0
		avatar.Size = UDim2.fromOffset(AVATAR, AVATAR)
		avatar.LayoutOrder = 1
		avatar.ZIndex = BASE_Z + 2
		avatar.Parent = row
		Corner(avatar, AVATAR / 2)

		local botIcon = Instance.new("ImageLabel")
		botIcon.BackgroundTransparency = 1
		botIcon.ImageTransparency = 1
		botIcon.Image = ResolveIcon("bot")
		botIcon.ImageColor3 = NullUI.Theme.Accent
		botIcon.Size = UDim2.fromOffset(14, 14)
		botIcon.AnchorPoint = Vector2.new(0.5, 0.5)
		botIcon.Position = UDim2.fromScale(0.5, 0.5)
		botIcon.ZIndex = BASE_Z + 3
		botIcon.Parent = avatar

		local bubble = Instance.new("Frame")
		bubble.BackgroundColor3 = Color3.new(1, 1, 1)
		bubble.BackgroundTransparency = 1
		bubble.BorderSizePixel = 0
		bubble.Size = UDim2.fromOffset(38, AVATAR)
		bubble.LayoutOrder = 2
		bubble.ZIndex = BASE_Z + 2
		bubble.Parent = row
		Corner(bubble, 12)
		local bubbleStroke = Stroke(bubble, Color3.new(1, 1, 1), 1, 1)

		local tweens = {}
		for i = 1, 3 do
			local baseX = 10 + (i - 1) * 9
			local dot = Instance.new("Frame")
			dot.BackgroundColor3 = NullUI.Theme.TextDim
			dot.BackgroundTransparency = 1
			dot.BorderSizePixel = 0
			dot.AnchorPoint = Vector2.new(0.5, 0.5)
			dot.Position = UDim2.new(0, baseX, 0.5, 0)
			dot.Size = UDim2.fromOffset(4, 4)
			dot.ZIndex = BASE_Z + 3
			dot.Parent = bubble
			Corner(dot, 2)
			Tween(dot, { BackgroundTransparency = 0 }, 0.18)

			tweens[i] = TweenService:Create(
				dot,
				TweenInfo.new(0.45, Enum.EasingStyle.Sine, Enum.EasingDirection.InOut, -1, true, (i - 1) * 0.15),
				{ Position = UDim2.new(0, baseX, 0.5, -3) }
			)
			tweens[i]:Play()
		end

		Tween(avatar, { BackgroundTransparency = 0.82 }, 0.18)
		Tween(botIcon, { ImageTransparency = 0 }, 0.18)
		Tween(bubble, { BackgroundTransparency = 0.9 }, 0.18)
		Tween(bubbleStroke, { Transparency = 0.9 }, 0.18)

		typingRow, typingTweens = row, tweens
		scrollToBottom()
	end

	local function showTyping()
		if typingRow then
			return
		end
		typingActive = true
		buildTypingRow()
	end

	function bumpTypingToBottom()
		if not typingRow then
			return
		end
		destroyTypingRow()
		buildTypingRow()
	end

	local function hideTyping()
		if not typingActive then
			return
		end
		typingActive = false
		destroyTypingRow()
	end

	local function addMessage(role, text)
		text = tostring(text or "")
		if text == "" then
			return
		end
		hideTyping()
		if role == "tool" then
			addToolLine(text)
			return nil
		end
		return addBubble(text, role)
	end

	local function handleToolCall(name, args)
		local tool = toolByName[name]
		addToolLine(name)
		if not tool or not tool.Handler then
			addMessage("assistant", "Unknown tool: " .. tostring(name))
			return nil
		end
		local ok, result = pcall(tool.Handler, args)
		if not ok then
			addMessage("assistant", "Tool error: " .. tostring(result))
			return nil
		end
		return result
	end

	local api

	local sending = false
	local lastUserText = nil

	local function setSending(value)
		sending = value
		sendIcon.Image = ResolveIcon(value and "square" or "send")
	end

	local function trySend(overrideText)
		local text = overrideText or inputBox.Text
		if sending or text == "" then
			return
		end
		setSending(true)
		if not overrideText then
			inputBox.Text = ""
		end
		lastUserText = text
		local revealTime = addMessage("user", text)
		if opts.OnSend then
			local finished = false

			SafeSpawn(function()
				if revealTime and revealTime > 0 then
					task.wait(revealTime)
				end
				local ok, err = pcall(opts.OnSend, api, text)
				if not ok then
					addMessage("assistant", "Error: " .. tostring(err))
				end
				finished = true
				setSending(false)
			end)

			SafeDelay(opts.SendTimeout or 30, function()
				if not finished and sending then
					setSending(false)
					hideTyping()
					addMessage("assistant", "(Taking too long -- you can try sending again.)")
				end
			end)
		else
			setSending(false)
		end
	end

	local function tryRegenerate()
		if sending or not lastUserText then
			return
		end
		if opts.OnRegenerate then
			SafeSpawn(opts.OnRegenerate, api, lastUserText)
		else
			trySend(lastUserText)
		end
	end

	local lastRealTab = nil

	local function openChat()
		if self._currentTab == tabObj then
			return
		end
		if self._currentTab and not self._currentTab.Hidden then
			lastRealTab = self._currentTab
		end
		tabObj._select()
	end

	local function closeChat()
		if self._currentTab ~= tabObj then
			return
		end
		if lastRealTab and not lastRealTab.Hidden then
			lastRealTab._select()
		elseif self._tabs[1] and self._tabs[1] ~= tabObj then
			self._tabs[1]._select()
		end
	end

	table.insert(self._tabChangeListeners, function(selected)
		if opts.OnToggle then
			SafeSpawn(opts.OnToggle, selected == tabObj)
		end
	end)

	local function clearChat()
		hideTyping()
		for _, child in ipairs(msgScroll:GetChildren()) do
			if child.Name == "MessageRow" or child.Name == "ToolCall" then
				child:Destroy()
			end
		end
		table.clear(transcript)
		if opts.OnClear then
			SafeSpawn(opts.OnClear)
		end
	end

	jan:Add(sendBtn.MouseButton1Click:Connect(function()
		if sending then
			if opts.OnStop then
				SafeSpawn(opts.OnStop, api)
			end
		else
			trySend()
		end
	end))
	jan:Add(inputBox.FocusLost:Connect(function(enterPressed)
		if enterPressed then
			trySend()
		end
	end))
	jan:Add(closeBtn.MouseButton1Click:Connect(closeChat))

	jan:Add(copyBtn.MouseButton1Click:Connect(function()
		local setclipboard = hasFn("setclipboard")
		if not setclipboard or #transcript == 0 then
			return
		end
		pcall(setclipboard, table.concat(transcript, "\n\n"))
		Tween(copyIcon, { ImageColor3 = Color3.fromRGB(120, 220, 140) }, 0.12)
		SafeDelay(0.4, function()
			if copyIcon.Parent then
				Tween(copyIcon, { ImageColor3 = NullUI.Theme.TextDim }, 0.18)
			end
		end)
	end))
	jan:Add(regenBtn.MouseButton1Click:Connect(function()
		if sending or not lastUserText then
			return
		end
		Tween(regenIcon, { Rotation = regenIcon.Rotation + 180 }, 0.26)
		tryRegenerate()
	end))
	jan:Add(clearBtn.MouseButton1Click:Connect(function()
		clearChat()
		lastUserText = nil
	end))

	api = {
		Instance = panel,
		Tab = tabObj,
		Open = openChat,
		Close = closeChat,
		Toggle = function()
			if self._currentTab == tabObj then
				closeChat()
			else
				openChat()
			end
		end,
		IsOpen = function()
			return self._currentTab == tabObj
		end,
		AddMessage = function(_, role, text)
			addMessage(role, text)
		end,
		LogToolCall = function(_, name)
			addToolLine(name)
		end,
		HandleToolCall = function(_, name, args)
			return handleToolCall(name, args)
		end,
		ShowTyping = function()
			showTyping()
		end,
		HideTyping = function()
			hideTyping()
		end,
		IsSending = function()
			return sending
		end,
		Clear = function()
			clearChat()
		end,
		Destroy = function()
			panel:Destroy()
		end,
	}

	return api
end

function Window:AddCloudPanel(opts)
	opts = opts or {}
	local service = opts.Service

	local tabObj = self:AddTab({
		Name = opts.Name or "Cloud",
		Icon = opts.Icon or "cloud",
		Hidden = opts.Hidden ~= false,
	})

	table.insert(self._tabChangeListeners, function(selected)
		if opts.OnToggle then
			SafeSpawn(opts.OnToggle, selected == tabObj)
		end
	end)

	local mineGrid, publicGrid, localGrid
	-- The last Apply/Load keeps its snapshot until the next one, so players can
	-- still undo after the toast is gone.
	local lastApplied = nil
	local function rememberApplied(snapshot, name)
		lastApplied = { Snapshot = snapshot, Name = tostring(name) }
	end
	local function undoApplied(snapshot)
		if lastApplied and lastApplied.Snapshot == snapshot then
			lastApplied = nil
		end
		NullUI:RestoreSnapshot(snapshot, false)
		NullUI:Notify({
			Title = "Reverted",
			Text = "Your previous settings are back.",
			Type = "info",
			Duration = 3,
		})
	end
	local function relativeTime(timestamp)
		local seconds = math.max(0, os.time() - tonumber(timestamp or os.time()))
		-- Hosts can localize the age text (e.g. a hub with its own language setting).
		if opts.FormatRelativeTime then
			return opts.FormatRelativeTime(seconds)
		end
		if seconds < 60 then
			return "updated just now"
		end
		if seconds < 3600 then
			return "updated " .. math.floor(seconds / 60) .. "m ago"
		end
		if seconds < 86400 then
			return "updated " .. math.floor(seconds / 3600) .. "h ago"
		end
		return "updated " .. math.floor(seconds / 86400) .. "d ago"
	end

	-- Public library first: it is what most players open the tab for.
	local CloudTabs = {}
	CloudTabs.Explore = tabObj:AddSubTab({ Name = "Public Configs", Icon = "Lucide:cloud" })
	CloudTabs.Local = tabObj:AddSubTab({ Name = "Local Configs", Icon = "Lucide:hard-drive" })
	CloudTabs.Mine = tabObj:AddSubTab({ Name = "Publish Public Config", Icon = "Lucide:cloud-cog" })

	CloudTabs.Local:AddParagraph({
		Title = "Local Library",
		Icon = "Lucide:hard-drive",
		Text = "Private presets saved only on this device. Load, create and manage them without uploading anything.",
	})

	CloudTabs.Local:AddSection("Quick Actions", "Lucide:zap")
	CloudTabs.Local:AddButton({
		Text = "Save Current Settings Locally",
		Description = "Stays on this device only",
		Icon = "Lucide:save",
		Callback = function()
			NullUI:Modal({
				Title = "Save Config Locally",
				Text = "Stays only on this device -- never sent anywhere.",
				ConfirmText = "Save",
				CancelText = "Cancel",
				Window = self,
				Fields = {
					{ Key = "Name", Label = "Name", Placeholder = "Enter a name...", MaxLength = 60 },
					{
						Key = "Description",
						Label = "Description (optional)",
						Type = "textarea",
						Placeholder = "What's different about this one?",
						MaxLength = 280,
					},
				},
				Callback = function(confirmed, values)
					if not confirmed then
						return
					end
					if not values.Name or values.Name:gsub("%s+", "") == "" then
						NullUI:Notify({
							Title = "Local Save",
							Text = "Name can't be empty.",
							Type = "warning",
							Duration = 3,
						})
						return
					end
					local function saveNow()
						local ok, err = NullUI:SaveConfig(values.Name, { Description = values.Description })
						NullUI:Notify({
							Title = ok and "Saved" or "Could not save",
							Text = ok and "Saved locally." or tostring(err),
							Type = ok and "success" or "error",
							Duration = 3,
						})
						if ok and localGrid then
							localGrid.Refresh()
						end
					end
					if NullUI:GetConfigMeta(values.Name) then
						NullUI:Confirm({
							Title = 'Overwrite "' .. tostring(values.Name) .. '"?',
							Text = "A local config already uses this name.",
							ConfirmText = "Overwrite",
							CancelText = "Cancel",
							Danger = true,
							Window = self,
							Callback = function(overwrite)
								if overwrite then
									saveNow()
								end
							end,
						})
					else
						saveNow()
					end
				end,
			})
		end,
	})

	localGrid = CloudTabs.Local:AddCardGrid({
		Title = "Local Configs",
		Height = 224,
		FixedHeight = true,
		Search = true,
		SearchPlaceholder = "Search local configs...",
		CardHeight = 68,
		AutoCardHeight = false,
		CardMinWidth = 180,
		Columns = 2,
		MaxColumns = 2,
		OuterPadding = 12,
		CardPadding = 8,
		ShowScrollbar = true,
		EmptyText = "No local configs saved yet.",
		ErrorText = "Your executor doesn't support local file access.",
		Fetch = function(state)
			local items, err = NullUI:ListConfigs()
			if err and #items == 0 then
				return nil, err
			end
			local query = string.lower(tostring(state and state.Query or ""))
			local out = {}
			for _, cfg in ipairs(items) do
				local searchable = string.lower(table.concat({
					tostring(cfg.Name or ""),
					tostring(cfg.Description or ""),
					table.concat(cfg.Tags or {}, " "),
				}, " "))
				if query ~= "" and not string.find(searchable, query, 1, true) then
					continue
				end

				local function loadLocalConfig()
					NullUI:Confirm({
						Title = 'Load "' .. tostring(cfg.Name) .. '"?',
						Text = "This overwrites your current settings. A snapshot is kept for instant undo.",
						ConfirmText = "Load",
						CancelText = "Cancel",
						Window = self,
						Callback = function(confirmedLoad)
							if not confirmedLoad then
								return
							end
							local snapshot = NullUI:CreateSnapshot()
							local ok, loadErr = NullUI:LoadConfig(cfg.Name, false)
							if not ok then
								NullUI:Notify({
									Title = "Could not load",
									Text = tostring(loadErr),
									Type = "error",
									Duration = 4,
								})
								return
							end
							rememberApplied(snapshot, cfg.Name)
							NullUI:Notify({
								Title = "Loaded",
								Text = '"' .. tostring(cfg.Name) .. '" is now active.',
								Type = "success",
								Duration = 6,
								Actions = {
									{
										Text = "Undo",
										Callback = function()
											undoApplied(snapshot)
										end,
									},
								},
							})
						end,
					})
				end

				local function renameLocalConfig()
					NullUI:Modal({
						Title = "Rename Config",
						Text = 'Choose a new name for "' .. tostring(cfg.Name) .. '".',
						ConfirmText = "Rename",
						CancelText = "Cancel",
						Window = self,
						Fields = { { Key = "Name", Label = "New name", Default = cfg.Name, MaxLength = 60 } },
						Callback = function(confirmed, values)
							if not confirmed then
								return
							end
							local newName = tostring(values.Name or ""):match("^%s*(.-)%s*$")
							if newName == "" then
								return
							end
							local existing = NullUI:GetConfigMeta(newName)
							if existing and newName ~= cfg.Name then
								NullUI:Notify({
									Title = "Name already used",
									Text = "Choose another config name.",
									Type = "warning",
									Duration = 3,
								})
								return
							end
							local ok, renameErr = NullUI:RenameConfig(cfg.Name, newName)
							NullUI:Notify({
								Title = ok and "Renamed" or "Could not rename",
								Text = ok and "Config name updated." or tostring(renameErr),
								Type = ok and "success" or "error",
								Duration = 3,
							})
							if ok and localGrid then
								localGrid.Refresh()
							end
						end,
					})
				end

				local function publishLocalConfig()
					if not service then
						NullUI:Notify({
							Title = "Cloud",
							Text = "No cloud service configured.",
							Type = "warning",
							Duration = 3,
						})
						return
					end
					local saved, savedErr = NullUI:GetSavedConfig(cfg.Name)
					if not saved then
						NullUI:Notify({
							Title = "Could not read config",
							Text = tostring(savedErr),
							Type = "error",
							Duration = 3,
						})
						return
					end
					local result, publishErr =
						service:Publish({ Name = cfg.Name, Description = cfg.Description, Tags = cfg.Tags }, saved.Data)
					NullUI:Notify({
						Title = result and "Published" or "Could not publish",
						Text = result and "Config published successfully." or tostring(publishErr),
						Type = result and "success" or "error",
						Duration = 4,
					})
					if result then
						if mineGrid then
							mineGrid.Refresh()
						end
						if publicGrid then
							publicGrid.Refresh()
						end
					end
				end

				local function deleteLocalConfig()
					NullUI:Confirm({
						Title = 'Delete "' .. tostring(cfg.Name) .. '"?',
						Text = "This local config will be permanently removed.",
						ConfirmText = "Delete",
						CancelText = "Cancel",
						Danger = true,
						Window = self,
						Callback = function(confirmed)
							if not confirmed then
								return
							end
							local ok, deleteErr = NullUI:DeleteConfig(cfg.Name)
							NullUI:Notify({
								Title = ok and "Deleted" or "Could not delete",
								Text = ok and "Config removed." or tostring(deleteErr),
								Type = ok and "success" or "error",
								Duration = 3,
							})
							if ok and localGrid then
								localGrid.Refresh()
							end
						end,
					})
				end

				table.insert(out, {
					UserContent = true,
					Title = cfg.Name,
					Description = cfg.Description,
					Byline = relativeTime(cfg.CreatedAt)
						.. (
							(cfg.Tags and #cfg.Tags > 0)
								and (" • " .. table.concat(
									cfg.Tags,
									", "
								))
							or ""
						),
					Icon = "Lucide:file-text",
					ActionIcon = "download",
					Callback = loadLocalConfig,
					SecondaryIcon = "trash-2",
					SecondaryCallback = deleteLocalConfig,
					SecondaryDanger = true,
				})
			end
			return out
		end,
	})

	local function publishFlow()
		if not service then
			NullUI:Notify({ Title = "Cloud", Text = "No cloud service configured.", Type = "warning", Duration = 3 })
			return
		end
		NullUI:Modal({
			Title = "New Config",
			ConfirmText = "Publish",
			CancelText = "Cancel",
			Window = self,
			Fields = {
				{ Key = "Name", Label = "Name", Placeholder = "Enter profile name...", MaxLength = 60 },
				{
					Key = "Description",
					Label = "Description",
					Type = "textarea",
					Placeholder = "Enter profile's description...",
					MaxLength = 280,
				},
				{
					Key = "Tags",
					Label = "Tags (optional)",
					Type = "tags",
					Placeholder = opts.TagsPlaceholder or "Enter tags separated by commas...",
				},
			},
			Callback = function(confirmed, values)
				if not confirmed then
					return
				end
				local result, err = service:Publish({
					Name = values.Name,
					Description = values.Description,
					Tags = values.Tags,
				})
				NullUI:Notify({
					Title = result and "Published" or "Could not publish",
					Text = result and "Your config is now public." or tostring(err),
					Type = result and "success" or "error",
					Duration = 4,
				})
				if result then
					if mineGrid then
						mineGrid.Refresh()
					end
					if publicGrid then
						publicGrid.Refresh()
					end
				end
			end,
		})
	end

	CloudTabs.Mine:AddParagraph({
		Title = "My Cloud Library",
		Icon = "Lucide:cloud",
		Text = "Publish your current setup, review what you shared and remove old uploads from one place.",
	})

	CloudTabs.Mine:AddSection("Publishing", "Lucide:upload-cloud")
	CloudTabs.Mine:AddButton({
		Text = "Publish Current Settings",
		Description = "Share your current config publicly",
		Icon = "Lucide:upload-cloud",
		Callback = publishFlow,
	})

	mineGrid = CloudTabs.Mine:AddCardGrid({
		Title = "Your Configs",
		Height = 210,
		FixedHeight = true,
		Search = false,
		CardHeight = 104,
		AutoCardHeight = false,
		DescriptionHeight = 24,
		CardMinWidth = 180,
		Columns = 2,
		MaxColumns = 2,
		OuterPadding = 12,
		CardPadding = 8,
		ShowScrollbar = true,
		EmptyText = service and "You haven't published anything yet." or "No cloud service configured.",
		ErrorText = "Couldn't load your configs.",
		Fetch = function()
			if not service then
				return {}, nil
			end
			local items, err = service:ListMine()
			if not items then
				return nil, err
			end
			local out = {}
			for _, cfg in ipairs(items) do
				local function deletePublishedConfig()
					NullUI:Confirm({
						Title = 'Delete "' .. tostring(cfg.Name) .. '"?',
						Text = "This removes it from the public library. This cannot be undone.",
						ConfirmText = "Delete",
						CancelText = "Cancel",
						Danger = true,
						Window = self,
						Callback = function(confirmedDelete)
							if not confirmedDelete then
								return
							end
							local ok, delErr = service:Delete(cfg.Id)
							NullUI:Notify({
								Title = ok and "Deleted" or "Could not delete",
								Text = ok and "Config removed." or tostring(delErr),
								Type = ok and "success" or "error",
								Duration = 3,
							})
							if ok then
								if mineGrid then
									mineGrid.Refresh()
								end
								if publicGrid then
									publicGrid.Refresh()
								end
							end
						end,
					})
				end
				table.insert(out, {
					UserContent = true,
					Title = cfg.Name,
					Description = cfg.Description,
					Byline = cfg.CreatedAtText or "",
					Icon = "Lucide:cloud",
					Stats = {
						{ Icon = "thumbs-up", Text = tostring(cfg.Likes or 0) },
						{ Icon = "download", Text = tostring(cfg.Downloads or 0) },
					},
					Menu = {
						{
							Text = "Delete publication",
							Icon = "trash-2",
							Danger = true,
							Callback = deletePublishedConfig,
						},
					},
				})
			end
			return out
		end,
	})

	CloudTabs.Explore:AddParagraph({
		Title = "Community Library",
		Icon = "Lucide:compass",
		Text = "Discover public configs, compare popularity and apply a setup with an instant undo snapshot.",
	})

	CloudTabs.Explore:AddButton({
		Text = "Undo Last Applied Config",
		Description = "Restore the settings you had before your last Apply",
		Icon = "Lucide:undo-2",
		Callback = function()
			if not lastApplied then
				NullUI:Notify({
					Title = "Nothing to undo",
					Text = "No config has been applied yet.",
					Type = "info",
					Duration = 3,
				})
				return
			end
			undoApplied(lastApplied.Snapshot)
		end,
	})

	CloudTabs.Explore:AddSection("Browse Configs", "Lucide:layout-grid")

	local SORT_MAP = { ["Top Rated"] = "top", ["Most Downloaded"] = "downloads", ["Newest"] = "new" }

	publicGrid = CloudTabs.Explore:AddCardGrid({
		Title = "Public Configs",
		Height = 230,
		FixedHeight = true,
		Sorts = { "Top Rated", "Most Downloaded", "Newest" },
		SearchPlaceholder = "Search config by name / tags...",
		CardHeight = 112,
		AutoCardHeight = false,
		DescriptionHeight = 24,
		CardMinWidth = 180,
		Columns = 2,
		MaxColumns = 2,
		OuterPadding = 12,
		CardPadding = 8,
		ShowScrollbar = true,
		EmptyText = "No public configs match your search.",
		ErrorText = "Couldn't reach the cloud service.",
		Fetch = function(state)
			if not service then
				return nil, "No cloud service configured."
			end
			local items, err = service:List({
				Query = state.Query,
				Sort = SORT_MAP[state.Sort] or "top",
				PageSize = state.PageSize,
			})
			if not items then
				return nil, err
			end
			local out = {}
			for _, cfg in ipairs(items) do
				local byline = cfg.OwnerName or "anonymous"
				if cfg.CreatedAtText then
					byline = byline .. " \226\128\162 " .. cfg.CreatedAtText
				end
				table.insert(out, {
					UserContent = true,
					Title = cfg.Name,
					Description = cfg.Description,
					Byline = byline,
					Icon = "Lucide:cloud-download",
					ActionIcon = "download",
					Stats = {
						{
							Icon = "thumbs-up",
							Text = tostring(cfg.Likes or 0),
							Callback = function()
								local liked, likeErr = service:Like(cfg.Id)
								if not liked then
									NullUI:Notify({
										Title = "Could not like",
										Text = tostring(likeErr),
										Type = "error",
										Duration = 3,
									})
									return
								end
								if publicGrid then
									publicGrid.Refresh()
								end
							end,
						},
						{ Icon = "download", Text = tostring(cfg.Downloads or 0) },
					},
					Callback = function()
						NullUI:Confirm({
							Title = 'Apply "' .. tostring(cfg.Name) .. '"?',
							Text = "This overwrites your current settings. A snapshot of what you have now "
								.. "is kept so you can undo it right after.",
							ConfirmText = "Apply",
							CancelText = "Cancel",
							Window = self,
							Callback = function(confirmedApply)
								if not confirmedApply then
									return
								end
								local result, dlErr = service:Download(cfg.Id)
								if not result or not result.Data then
									NullUI:Notify({
										Title = "Could not apply",
										Text = tostring(dlErr),
										Type = "error",
										Duration = 4,
									})
									return
								end

								local snapshot = NullUI:CreateSnapshot()

								NullUI:SetConfig(result.Data, false)
								rememberApplied(snapshot, cfg.Name)
								NullUI:Notify({
									Title = "Applied",
									Text = '"' .. tostring(cfg.Name) .. '" is now active.',
									Type = "success",
									Duration = 6,
									Actions = {
										{
											Text = "Undo",
											Callback = function()
												undoApplied(snapshot)
											end,
										},
									},
								})

								if publicGrid then
									publicGrid.Refresh()
								end
								if opts.OnApplied then
									SafeSpawn(opts.OnApplied, cfg)
								end
							end,
						})
					end,
				})
			end
			return out
		end,
	})

	local lastRealTab = nil
	local function openPanel()
		if self._currentTab == tabObj then
			return
		end
		if self._currentTab and not self._currentTab.Hidden then
			lastRealTab = self._currentTab
		end
		tabObj._select()
	end
	local function closePanel()
		if self._currentTab ~= tabObj then
			return
		end
		if lastRealTab and not lastRealTab.Hidden then
			lastRealTab._select()
		elseif self._tabs[1] and self._tabs[1] ~= tabObj then
			self._tabs[1]._select()
		end
	end

	return {
		Instance = tabObj._group,
		Tab = tabObj,
		Open = openPanel,
		Close = closePanel,
		Toggle = function()
			if self._currentTab == tabObj then
				closePanel()
			else
				openPanel()
			end
		end,
		IsOpen = function()
			return self._currentTab == tabObj
		end,
		RefreshMine = function()
			if mineGrid then
				mineGrid.Refresh()
			end
		end,
		RefreshPublic = function()
			if publicGrid then
				publicGrid.Refresh()
			end
		end,
	}
end

-- Mirrors the relay's rule so the sender sees the same warning everyone else
-- does, even when the chat service doesn't return the stored text.
local ALLOWED_SCRIPT_URLS = {
	["https://gist.githubusercontent.com/angeryy-tvy/6a9ce750ddf5860230196ac468868fdb/raw/Steal-An-Egg-Vxeze"] = true,
}
local FOREIGN_SCRIPT_WARNING = "nghiêm cấm gửi script khác vào kênh, nếu tái phạm sẽ ban chat vĩnh viễn"

local function censorForeignLoadstrings(text)
	local lower = string.lower(text)
	local parts, pos, searchFrom = {}, 1, 1
	while true do
		local _, e = string.find(lower, "httpget", searchFrom, true)
		if not e then
			break
		end
		searchFrom = e + 1
		local i = e + 1
		if string.sub(lower, i, i + 4) == "async" then
			i += 5
		end
		local _, pe = string.find(lower, "^%s*%(%s*", i)
		if pe then
			i = pe + 1
			local _, ge = string.find(lower, "^game%s*,%s*", i)
			if ge then
				i = ge + 1
			end
			-- A closed literal, or (to stop dodging the filter) an unclosed quote or
			-- long bracket up to the end of the line, or unquoted text up to ")".
			local lineEnd = (string.find(text, "\n", i, true) or (#text + 1)) - 1
			local q = string.sub(text, i, i)
			local litEnd, url
			if q == '"' or q == "'" then
				local close = string.find(text, q, i + 1, true)
				if close and close <= lineEnd then
					litEnd, url = close, string.sub(text, i + 1, close - 1)
				else
					litEnd = lineEnd
				end
			elseif q == "[" then
				local _, oe, eq = string.find(text, "^%[(=*)%[", i)
				if oe then
					local cs, ce = string.find(text, "]" .. eq .. "]", oe + 1, true)
					if cs and ce <= lineEnd then
						litEnd, url = ce, string.sub(text, oe + 1, cs - 1)
					else
						litEnd = lineEnd
					end
				end
			elseif q ~= "" and q ~= ")" and not string.find(q, "%s") then
				local close = string.find(text, ")", i, true)
				litEnd = (close and close - 1 <= lineEnd) and close - 1 or lineEnd
			end
			if litEnd then
				-- Only a properly closed literal can be the approved loader.
				local trimmed = url and url:gsub("^%s+", ""):gsub("%s+$", "")
				if not (trimmed and ALLOWED_SCRIPT_URLS[trimmed]) then
					table.insert(parts, string.sub(text, pos, i - 1))
					table.insert(parts, '"' .. FOREIGN_SCRIPT_WARNING .. '"')
					pos = litEnd + 1
				end
				searchFrom = litEnd + 1
			end
		end
	end
	table.insert(parts, string.sub(text, pos))
	return table.concat(parts)
end

function Window:AddGlobalChatPanel(opts)
	opts = opts or {}
	local service = opts.Service
	local jan = self._janitor

	local tabObj = self:AddTab({
		Name = opts.Name or "Chat",
		Icon = opts.Icon or "messages-square",
		Hidden = opts.Hidden ~= false,
	})
	tabObj._page.Visible = false
	local staleEmptyState = tabObj._group:FindFirstChild("EmptyState")
	if staleEmptyState then
		staleEmptyState.Visible = false
	end

	table.insert(self._tabChangeListeners, function(selected)
		if opts.OnToggle then
			SafeSpawn(opts.OnToggle, selected == tabObj)
		end
	end)

	-- Phones get a denser layout so 3-4 messages fit next to the pinned notice.
	local C = {
		Mobile = IsMobileDevice,
		TopGap = IsMobileDevice and 4 or 9,
		PadR = IsMobileDevice and 10 or 18,
		RowGap = IsMobileDevice and 5 or 8,
		Text = IsMobileDevice and 12 or 13,
		PinText = IsMobileDevice and 11 or 13,
		HPad = IsMobileDevice and 8 or 10,
		VPad = IsMobileDevice and 5 or 8,
		Avatar = IsMobileDevice and 22 or 26,
	}
	local INPUT_H, HEADER_H = IsMobileDevice and 34 or 38, IsMobileDevice and 30 or 38

	local panel = Instance.new("Frame")
	panel.Name = "GlobalChatPanel"
	panel.BackgroundTransparency = 1
	panel.ClipsDescendants = true
	panel.Size = UDim2.fromScale(1, 1)
	panel.ZIndex = Z.Content
	panel.Parent = tabObj._group

	local BASE_Z = panel.ZIndex + 1

	local content = Instance.new("Frame")
	content.Name = "Content"
	content.BackgroundTransparency = 1
	content.Size = UDim2.fromScale(1, 1)
	content.ZIndex = panel.ZIndex
	content.Parent = panel

	local header = Instance.new("Frame")
	header.BackgroundTransparency = 1
	header.Active = true
	header.Size = UDim2.new(1, 0, 0, HEADER_H)
	header.ZIndex = BASE_Z
	header.Parent = content

	local headerPad = Instance.new("UIPadding")
	headerPad.PaddingLeft = UDim.new(0, 14)
	headerPad.PaddingRight = UDim.new(0, 8)
	headerPad.Parent = header

	local titleRow = Instance.new("Frame")
	titleRow.BackgroundTransparency = 1
	titleRow.Size = UDim2.new(1, -162, 1, 0)
	titleRow.ZIndex = BASE_Z + 1
	titleRow.Parent = header

	local titleLayout = Instance.new("UIListLayout")
	titleLayout.FillDirection = Enum.FillDirection.Horizontal
	titleLayout.VerticalAlignment = Enum.VerticalAlignment.Center
	titleLayout.Padding = UDim.new(0, 7)
	titleLayout.Parent = titleRow

	local titleIcon = Instance.new("ImageLabel")
	titleIcon.BackgroundTransparency = 1
	titleIcon.Image = ResolveIcon(opts.Icon or "messages-square")
	titleIcon.ImageColor3 = NullUI.Theme.Text
	Role(titleIcon, "Text")
	titleIcon.Size = UDim2.fromOffset(14, 14)
	titleIcon.LayoutOrder = 1
	titleIcon.ZIndex = BASE_Z + 2
	titleIcon.Parent = titleRow

	local titleLabel = Instance.new("TextLabel")
	titleLabel.BackgroundTransparency = 1
	titleLabel.FontFace = NullUI.Theme.Font
	titleLabel.Text = opts.Title or "Chat"
	titleLabel.TextColor3 = NullUI.Theme.Text
	Role(titleLabel, "Text")
	titleLabel.TextSize = 14
	titleLabel.TextXAlignment = Enum.TextXAlignment.Left
	titleLabel.AutomaticSize = Enum.AutomaticSize.X
	titleLabel.Size = UDim2.fromOffset(0, 16)
	titleLabel.LayoutOrder = 2
	titleLabel.ZIndex = BASE_Z + 2
	titleLabel.Parent = titleRow

	local controls = Instance.new("Frame")
	controls.BackgroundTransparency = 1
	controls.AnchorPoint = Vector2.new(1, 0.5)
	controls.Position = UDim2.new(1, 0, 0.5, 0)
	controls.Size = UDim2.fromOffset(152, 22)
	controls.ZIndex = BASE_Z + 1
	controls.Parent = header

	local controlsLayout = Instance.new("UIListLayout")
	controlsLayout.FillDirection = Enum.FillDirection.Horizontal
	controlsLayout.HorizontalAlignment = Enum.HorizontalAlignment.Right
	controlsLayout.VerticalAlignment = Enum.VerticalAlignment.Center
	controlsLayout.Padding = UDim.new(0, 4)
	controlsLayout.Parent = controls

	local function headerIconButton(icon, layoutOrder)
		local btn = Instance.new("TextButton")
		btn.Text = ""
		btn.AutoButtonColor = false
		btn.BackgroundColor3 = Color3.new(1, 1, 1)
		btn.BackgroundTransparency = 1
		btn.BorderSizePixel = 0
		btn.Size = UDim2.fromOffset(22, 22)
		btn.LayoutOrder = layoutOrder
		btn.ZIndex = BASE_Z + 1
		btn.Parent = controls
		Corner(btn, 6)

		local ic = Instance.new("ImageLabel")
		ic.BackgroundTransparency = 1
		ic.Image = ResolveIcon(icon)
		ic.ImageColor3 = NullUI.Theme.TextDim
		Role(ic, "TextDim")
		ic.Size = UDim2.fromOffset(13, 13)
		ic.AnchorPoint = Vector2.new(0.5, 0.5)
		ic.Position = UDim2.fromScale(0.5, 0.5)
		ic.ZIndex = BASE_Z + 2
		ic.Parent = btn

		jan:Add(btn.MouseEnter:Connect(function()
			Tween(btn, { BackgroundTransparency = 0.9 }, 0.12)
			Tween(ic, { ImageColor3 = NullUI.Theme.Text }, 0.12)
		end))
		jan:Add(btn.MouseLeave:Connect(function()
			Tween(btn, { BackgroundTransparency = 1 }, 0.12)
			Tween(ic, { ImageColor3 = NullUI.Theme.TextDim }, 0.12)
		end))

		return btn, ic
	end

	local anonymousMode = opts.AnonymousByDefault ~= false
	local showTimestamps = true
	local notifySound = false
	local pollInterval = opts.PollInterval or 2.5

	local copyBtn, copyIcon = headerIconButton("copy", 1)
	local anonBtn, anonIcon = headerIconButton(anonymousMode and "eye-off" or "eye", 2)
	local clearBtn, clearIcon = headerIconButton("trash-2", 3)
	local settingsBtn, settingsIcon = headerIconButton("settings", 4)
	local closeBtn, closeIcon = headerIconButton("x", 5)

	-- Admin mailbox entry points: header button with a red dot, plus a short
	-- notice next to the title while something is unread.
	local hasMailbox = service ~= nil and type(service.GetMailbox) == "function"
	local mailboxBtn = headerIconButton("mail", 0)
	mailboxBtn.Visible = hasMailbox
	local mailboxDot = Instance.new("Frame")
	mailboxDot.Name = "MailboxDot"
	mailboxDot.AnchorPoint = Vector2.new(0.5, 0.5)
	mailboxDot.Position = UDim2.new(1, -4, 0, 4)
	mailboxDot.Size = UDim2.fromOffset(7, 7)
	mailboxDot.BackgroundColor3 = Color3.fromRGB(239, 68, 68)
	mailboxDot.BorderSizePixel = 0
	mailboxDot.Visible = false
	mailboxDot.ZIndex = BASE_Z + 3
	mailboxDot.Parent = mailboxBtn
	Corner(mailboxDot, 4)

	local mailboxNotice = Instance.new("TextButton")
	mailboxNotice.Name = "MailboxNotice"
	mailboxNotice.AutoButtonColor = false
	mailboxNotice.BackgroundTransparency = 1
	mailboxNotice.FontFace = NullUI.Theme.FontRegular
	mailboxNotice.Text = ""
	mailboxNotice.TextColor3 = Color3.fromRGB(239, 68, 68)
	mailboxNotice.TextSize = 11
	mailboxNotice.TextXAlignment = Enum.TextXAlignment.Left
	mailboxNotice.AutomaticSize = Enum.AutomaticSize.X
	mailboxNotice.Size = UDim2.fromOffset(0, 16)
	mailboxNotice.LayoutOrder = 3
	mailboxNotice.Visible = false
	mailboxNotice.ZIndex = BASE_Z + 2
	mailboxNotice.Parent = titleRow

	local headerDivider = Instance.new("Frame")
	headerDivider.BackgroundColor3 = Color3.new(1, 1, 1)
	headerDivider.BackgroundTransparency = 0.94
	headerDivider.BorderSizePixel = 0
	headerDivider.Position = UDim2.fromOffset(0, HEADER_H)
	headerDivider.Size = UDim2.new(1, 0, 0, 1)
	headerDivider.ZIndex = BASE_Z
	headerDivider.Parent = content

	local contentPad = Instance.new("UIPadding")
	contentPad.PaddingLeft = UDim.new(0, 14)
	contentPad.PaddingRight = UDim.new(0, 14)
	contentPad.PaddingBottom = UDim.new(0, 12)
	contentPad.Parent = content

	local inputRow = Instance.new("Frame")
	inputRow.BackgroundTransparency = 1
	inputRow.Active = true
	inputRow.AnchorPoint = Vector2.new(0, 1)
	inputRow.Position = UDim2.new(0, 0, 1, 0)
	inputRow.Size = UDim2.new(1, 0, 0, INPUT_H)
	inputRow.ZIndex = BASE_Z
	inputRow.Parent = content

	local pill = Instance.new("Frame")
	pill.BackgroundColor3 = Color3.new(1, 1, 1)
	pill.BackgroundTransparency = 0.95
	pill.BorderSizePixel = 0
	pill.Size = UDim2.new(1, -(INPUT_H + 6), 1, 0)
	pill.ZIndex = BASE_Z + 1
	pill.Parent = inputRow
	Corner(pill, 9)
	local pillStroke = Stroke(pill, Color3.new(1, 1, 1), 1, 0.9)

	local pillPad = Instance.new("UIPadding")
	pillPad.PaddingLeft = UDim.new(0, 10)
	pillPad.PaddingRight = UDim.new(0, 10)
	pillPad.Parent = pill

	local inputBox = Instance.new("TextBox")
	inputBox.BackgroundTransparency = 1
	inputBox.ClearTextOnFocus = false
	inputBox.FontFace = NullUI.Theme.FontRegular
	inputBox.PlaceholderText = opts.Placeholder or "Message everyone using this script..."
	inputBox.PlaceholderColor3 = Color3.fromRGB(120, 120, 122)
	inputBox.Text = ""
	inputBox.TextColor3 = NullUI.Theme.Text
	Role(inputBox, "Text")
	inputBox.TextSize = 13
	inputBox.TextXAlignment = Enum.TextXAlignment.Left
	inputBox.TextYAlignment = Enum.TextYAlignment.Center
	inputBox.ClipsDescendants = true
	inputBox.Size = UDim2.fromScale(1, 1)
	inputBox.ZIndex = BASE_Z + 2
	inputBox.Parent = pill

	jan:Add(inputBox.Focused:Connect(function()
		Tween(pillStroke, { Color = NullUI.Theme.Accent, Transparency = 0.3 }, 0.18)
	end))
	jan:Add(inputBox.FocusLost:Connect(function()
		Tween(pillStroke, { Color = Color3.new(1, 1, 1), Transparency = 0.9 }, 0.18)
	end))

	local sendBtn = Instance.new("TextButton")
	sendBtn.Text = ""
	sendBtn.AutoButtonColor = false
	sendBtn.BackgroundColor3 = Color3.new(1, 1, 1)
	sendBtn.BackgroundTransparency = 0.9
	sendBtn.BorderSizePixel = 0
	sendBtn.AnchorPoint = Vector2.new(1, 0)
	sendBtn.Position = UDim2.new(1, 0, 0, 0)
	sendBtn.Size = UDim2.fromOffset(INPUT_H, INPUT_H)
	sendBtn.ZIndex = BASE_Z + 1
	sendBtn.Parent = inputRow
	Corner(sendBtn, 9)

	local sendIcon = Instance.new("ImageLabel")
	sendIcon.BackgroundTransparency = 1
	sendIcon.Image = ResolveIcon("send")
	sendIcon.ImageColor3 = NullUI.Theme.Text
	Role(sendIcon, "Text")
	sendIcon.Size = UDim2.fromOffset(14, 14)
	sendIcon.AnchorPoint = Vector2.new(0.5, 0.5)
	sendIcon.Position = UDim2.fromScale(0.5, 0.5)
	sendIcon.ZIndex = BASE_Z + 2
	sendIcon.Parent = sendBtn

	jan:Add(sendBtn.MouseEnter:Connect(function()
		Tween(sendBtn, { BackgroundTransparency = 0.8 }, 0.12)
	end))
	jan:Add(sendBtn.MouseLeave:Connect(function()
		Tween(sendBtn, { BackgroundTransparency = 0.9 }, 0.12)
	end))

	local msgScroll = Instance.new("ScrollingFrame")
	msgScroll.BackgroundTransparency = 1
	msgScroll.BorderSizePixel = 0
	msgScroll.Position = UDim2.fromOffset(0, HEADER_H + C.TopGap)
	msgScroll.Size = UDim2.new(1, 0, 1, -(HEADER_H + C.TopGap + INPUT_H + 10))
	msgScroll.ScrollingDirection = Enum.ScrollingDirection.Y
	msgScroll.ScrollBarThickness = 0
	msgScroll.AutomaticCanvasSize = Enum.AutomaticSize.Y
	msgScroll.CanvasSize = UDim2.new(0, 0, 0, 0)
	msgScroll.ZIndex = BASE_Z
	msgScroll.Parent = content

	local msgPad = Instance.new("UIPadding")
	msgPad.PaddingRight = UDim.new(0, C.PadR)
	msgPad.Parent = msgScroll

	local msgLayout = Instance.new("UIListLayout")
	msgLayout.Padding = UDim.new(0, C.Mobile and 4 or 8)
	msgLayout.SortOrder = Enum.SortOrder.LayoutOrder
	msgLayout.Parent = msgScroll

	AddScrollbar(msgScroll)
	AddContentScrollThumb(msgScroll, msgLayout, panel, jan)

	local chatEmpty = Instance.new("TextLabel")
	chatEmpty.Name = "ChatEmptyState"
	chatEmpty.BackgroundTransparency = 1
	chatEmpty.FontFace = NullUI.Theme.Font
	chatEmpty.Text = service and "No messages yet. Say hello!" or "Global chat is not configured by the script owner."
	chatEmpty.TextColor3 = NullUI.Theme.TextDim
	Role(chatEmpty, "TextDim")
	chatEmpty.TextSize = 13
	chatEmpty.TextWrapped = true
	chatEmpty.TextXAlignment = Enum.TextXAlignment.Center
	chatEmpty.AnchorPoint = Vector2.new(0.5, 0.5)
	chatEmpty.Position = UDim2.new(0.5, 0, 0.5, 0)
	chatEmpty.Size = UDim2.new(1, -60, 0, 40)
	chatEmpty.ZIndex = BASE_Z + 1
	chatEmpty.Parent = content

	if not service then
		inputBox.PlaceholderText = "Chat unavailable"
		inputBox.TextEditable = false
	end

	local order = 0
	local transcript = {}
	local timestampLabels = {}
	local pinnedToBottom = true
	jan:Add(msgScroll:GetPropertyChangedSignal("AbsoluteCanvasSize"):Connect(function()
		if pinnedToBottom then
			msgScroll.CanvasPosition = Vector2.new(0, msgScroll.AbsoluteCanvasSize.Y)
		end
	end))
	jan:Add(msgScroll:GetPropertyChangedSignal("CanvasPosition"):Connect(function()
		LPH_ATTRIBUTES(VM(NONE))
		local atBottom = msgScroll.CanvasPosition.Y
			>= msgScroll.AbsoluteCanvasSize.Y - msgScroll.AbsoluteWindowSize.Y - 20
		pinnedToBottom = atBottom
	end))

	local function scrollToBottom()
		pinnedToBottom = true
		SafeDefer(function()
			if msgScroll and msgScroll.Parent then
				msgScroll.CanvasPosition = Vector2.new(0, msgScroll.AbsoluteCanvasSize.Y)
			end
		end)
	end

	local AVATAR = C.Avatar

	-- Display-only role badges; the relay's SenderTag is the trusted source when present.
	local ChatRoleTags = opts.RoleTags or {}
	local function escapeRich(s)
		return (tostring(s):gsub("&", "&amp;"):gsub("<", "&lt;"):gsub(">", "&gt;"))
	end
	local function maskedName(name)
		name = tostring(name or "Guest")
		local ok, off = pcall(utf8.offset, name, 4)
		local prefix = ok and (off and name:sub(1, off - 1) or name) or name:sub(1, 3)
		return prefix .. "*****"
	end
	local gameName = opts.GameName
	if type(gameName) ~= "string" or gameName == "" then
		local okInfo, info = pcall(function()
			return game:GetService("MarketplaceService"):GetProductInfo(game.PlaceId)
		end)
		gameName = okInfo and info and info.Name or "Unknown game"
	end

	-- Layout: pinned notice and reply bar shrink the message list.
	local PINNED_COLLAPSED_H, REPLY_H = (C.Mobile and 24 or 30), 24
	local pinnedActive, replyingTo = false, nil
	-- full = the whole notice, collapsed = header only (tap the header to switch).
	local pin = { Mode = "full" }
	local GOLD = Color3.fromRGB(245, 184, 68)

	-- Use the measured content height, not AutomaticSize inside a clipped viewport.
	local function pinnedHeight()
		if not pinnedActive then
			return 0
		end
		if pin.Mode == "collapsed" then
			return PINNED_COLLAPSED_H
		end
		local s = GetUIScale()
		local textH = pin.TextHeight or (C.PinText + 4)
		local natural = PINNED_COLLAPSED_H - 2 + textH + 8
		-- Never taller than half the panel (the body scrolls past that).
		local panelH = content.AbsoluteSize.Y / s
		return math.min(natural, math.max(90, panelH * 0.5))
	end
	local function applyLayout()
		local ph = pinnedHeight()
		local top = HEADER_H + C.TopGap + (pinnedActive and (ph + 6) or 0)
		local bottom = INPUT_H + 10 + (replyingTo and (REPLY_H + 4) or 0)
		if pinnedActive then
			pin.Frame.Size = UDim2.new(1, 0, 0, ph)
		end
		msgScroll.Position = UDim2.fromOffset(0, top)
		msgScroll.Size = UDim2.new(1, 0, 1, -(top + bottom))
	end

	pin.Frame = Instance.new("Frame")
	pin.Frame.Name = "PinnedNotice"
	pin.Frame.BackgroundColor3 = GOLD
	pin.Frame.BackgroundTransparency = 0.78
	pin.Frame.BorderSizePixel = 0
	pin.Frame.ClipsDescendants = true
	pin.Frame.Visible = false
	pin.Frame.Position = UDim2.fromOffset(0, HEADER_H + C.TopGap)
	pin.Frame.Size = UDim2.new(1, 0, 0, PINNED_COLLAPSED_H)
	pin.Frame.ZIndex = BASE_Z + 1
	pin.Frame.Parent = content
	Corner(pin.Frame, 9)
	Stroke(pin.Frame, GOLD, 1.5, 0.3)

	local pinnedBar = Instance.new("Frame")
	pinnedBar.BackgroundColor3 = GOLD
	pinnedBar.BorderSizePixel = 0
	pinnedBar.Size = UDim2.new(0, 4, 1, 0)
	pinnedBar.ZIndex = BASE_Z + 2
	pinnedBar.Parent = pin.Frame

	pin.Meta = Instance.new("TextLabel")
	pin.Meta.BackgroundTransparency = 1
	pin.Meta.FontFace = NullUI.Theme.Font
	pin.Meta.Text = "📌  PINNED"
	pin.Meta.TextColor3 = Color3.fromRGB(255, 214, 120)
	pin.Meta.TextSize = 12
	pin.Meta.TextTruncate = Enum.TextTruncate.AtEnd
	pin.Meta.TextXAlignment = Enum.TextXAlignment.Left
	pin.Meta.Position = UDim2.fromOffset(14, 0)
	pin.Meta.Size = UDim2.new(1, -42, 0, PINNED_COLLAPSED_H)
	pin.Meta.ZIndex = BASE_Z + 3
	pin.Meta.Parent = pin.Frame

	pin.Chevron = Instance.new("ImageLabel")
	pin.Chevron.BackgroundTransparency = 1
	pin.Chevron.Image = ResolveIcon("chevron-up")
	pin.Chevron.ImageColor3 = Color3.fromRGB(255, 214, 120)
	pin.Chevron.AnchorPoint = Vector2.new(1, 0)
	pin.Chevron.Position = UDim2.new(1, -10, 0, (PINNED_COLLAPSED_H - 14) / 2)
	pin.Chevron.Size = UDim2.fromOffset(14, 14)
	pin.Chevron.ZIndex = BASE_Z + 3
	pin.Chevron.Parent = pin.Frame

	pin.Header = Instance.new("TextButton")
	pin.Header.Text = ""
	pin.Header.AutoButtonColor = false
	pin.Header.BackgroundTransparency = 1
	pin.Header.Size = UDim2.new(1, 0, 0, PINNED_COLLAPSED_H)
	pin.Header.ZIndex = BASE_Z + 4
	pin.Header.Parent = pin.Frame

	pin.Body = Instance.new("ScrollingFrame")
	pin.Body.BackgroundTransparency = 1
	pin.Body.BorderSizePixel = 0
	pin.Body.Active = true
	pin.Body.ClipsDescendants = true
	pin.Body.ScrollingDirection = Enum.ScrollingDirection.Y
	pin.Body.ScrollBarThickness = 3
	pin.Body.ScrollBarImageColor3 = GOLD
	pin.Body.AutomaticCanvasSize = Enum.AutomaticSize.None
	pin.Body.CanvasSize = UDim2.new(0, 0, 0, 0)
	pin.Body.Position = UDim2.fromOffset(14, PINNED_COLLAPSED_H - 2)
	pin.Body.Size = UDim2.new(1, -22, 1, -(PINNED_COLLAPSED_H + 4))
	pin.Body.ZIndex = BASE_Z + 2
	pin.Body.Parent = pin.Frame

	pin.Text = Instance.new("TextLabel")
	pin.Text.BackgroundTransparency = 1
	pin.Text.FontFace = NullUI.Theme.FontRegular
	pin.Text.Text = ""
	pin.Text.TextColor3 = NullUI.Theme.Text
	Role(pin.Text, "Text")
	pin.Text.TextSize = C.PinText
	pin.Text.TextWrapped = true
	pin.Text.TextXAlignment = Enum.TextXAlignment.Left
	pin.Text.TextYAlignment = Enum.TextYAlignment.Top
	pin.Text.AutomaticSize = Enum.AutomaticSize.None
	pin.Text.Size = UDim2.new(1, -6, 0, 0)
	pin.Text.ZIndex = BASE_Z + 3
	pin.Text.Parent = pin.Body

	-- Measuring the full string preserves explicit newlines and word wrapping even
	-- when the notice is hidden/collapsed or its scrolling viewport is much shorter.
	local pinMeasureQueued = false
	local function queuePinMeasure()
		if pinMeasureQueued then
			return
		end
		pinMeasureQueued = true
		SafeDefer(function()
			pinMeasureQueued = false
			if not pin.Text.Parent then
				return
			end
			local width = math.floor(pin.Text.AbsoluteSize.X / GetUIScale())
			if width <= 0 then
				return
			end
			local text, font, size = pin.Text.Text, pin.Text.FontFace, pin.Text.TextSize
			if pin.MeasuredText == text and pin.MeasuredWidth == width
				and pin.MeasuredFont == font and pin.MeasuredSize == size then
				return
			end
			pin.MeasuredText, pin.MeasuredWidth = text, width
			pin.MeasuredFont, pin.MeasuredSize = font, size
			pin.MeasureId = (pin.MeasureId or 0) + 1
			local measureId = pin.MeasureId
			local params = Instance.new("GetTextBoundsParams")
			params.Text, params.Font, params.Size, params.Width = text, font, size, width
			local ok, bounds = pcall(function()
				return TextService:GetTextBoundsAsync(params)
			end)
			params:Destroy()
			if not pin.Text.Parent or pin.MeasureId ~= measureId or pin.Text.Text ~= text then
				return
			end
			local textH
			if ok then
				textH = bounds.Y
			else
				-- Keep a wrapped fallback if the custom font cannot be loaded.
				local _, fallbackH = MeasureText(text, size, width)
				textH = fallbackH
			end
			pin.TextHeight = math.ceil(textH) + 4
			pin.Text.Size = UDim2.new(1, -6, 0, pin.TextHeight)
			pin.Body.CanvasSize = UDim2.fromOffset(0, pin.TextHeight + 2)
			applyLayout()
		end)
	end

	function pin.SetMode(mode)
		pin.Mode = mode
		pin.Body.Visible = mode ~= "collapsed"
		pin.Chevron.Image = ResolveIcon(mode == "collapsed" and "chevron-down" or "chevron-up")
		applyLayout()
	end
	jan:Add(pin.Header.MouseButton1Click:Connect(function()
		pin.SetMode(pin.Mode == "collapsed" and "full" or "collapsed")
	end))
	jan:Add(content:GetPropertyChangedSignal("AbsoluteSize"):Connect(applyLayout))
	jan:Add(pin.Text:GetPropertyChangedSignal("AbsoluteSize"):Connect(queuePinMeasure))
	jan:Add(pin.Text:GetPropertyChangedSignal("Text"):Connect(queuePinMeasure))
	jan:Add(pin.Text:GetPropertyChangedSignal("FontFace"):Connect(queuePinMeasure))
	jan:Add(pin.Text:GetPropertyChangedSignal("TextSize"):Connect(queuePinMeasure))
	queuePinMeasure()

	-- Reply bar above the composer.
	local replyBar = Instance.new("Frame")
	replyBar.BackgroundColor3 = Color3.new(1, 1, 1)
	replyBar.BackgroundTransparency = 0.93
	replyBar.BorderSizePixel = 0
	replyBar.Visible = false
	replyBar.AnchorPoint = Vector2.new(0, 1)
	replyBar.Position = UDim2.new(0, 0, 1, -(INPUT_H + 4))
	replyBar.Size = UDim2.new(1, 0, 0, REPLY_H)
	replyBar.ZIndex = BASE_Z + 1
	replyBar.Parent = content
	Corner(replyBar, 6)

	local replyLabel = Instance.new("TextLabel")
	replyLabel.BackgroundTransparency = 1
	replyLabel.FontFace = NullUI.Theme.FontRegular
	replyLabel.TextColor3 = NullUI.Theme.TextDim
	Role(replyLabel, "TextDim")
	replyLabel.TextSize = 11
	replyLabel.TextTruncate = Enum.TextTruncate.AtEnd
	replyLabel.TextXAlignment = Enum.TextXAlignment.Left
	replyLabel.Position = UDim2.fromOffset(8, 0)
	replyLabel.Size = UDim2.new(1, -34, 1, 0)
	replyLabel.ZIndex = BASE_Z + 2
	replyLabel.Parent = replyBar

	local replyCancel = Instance.new("TextButton")
	replyCancel.Text = "×"
	replyCancel.AutoButtonColor = false
	replyCancel.BackgroundTransparency = 1
	replyCancel.FontFace = NullUI.Theme.Font
	replyCancel.TextSize = 16
	replyCancel.TextColor3 = NullUI.Theme.TextDim
	Role(replyCancel, "TextDim")
	replyCancel.AnchorPoint = Vector2.new(1, 0)
	replyCancel.Position = UDim2.new(1, 0, 0, 0)
	replyCancel.Size = UDim2.fromOffset(26, REPLY_H)
	replyCancel.ZIndex = BASE_Z + 3
	replyCancel.Parent = replyBar

	local function clearReply()
		replyingTo = nil
		replyBar.Visible = false
		applyLayout()
	end
	local function setReply(msg)
		if not msg.Id then
			return
		end
		replyingTo = msg
		replyLabel.Text = "Replying to " .. maskedName(msg.PlayerName or "Guest") .. ": " .. tostring(msg.Text or "")
		replyBar.Visible = true
		applyLayout()
		pcall(function()
			inputBox:CaptureFocus()
		end)
	end
	jan:Add(replyCancel.MouseButton1Click:Connect(clearReply))

	-- Online count + pinned notice come from the last poll.
	local baseTitle = opts.Title or "Chat"
	local function applyMeta()
		local meta = service and service.ChatMeta
		if not meta then
			return
		end
		local pinned = type(meta.Pinned) == "table" and tostring(meta.Pinned.Content or "") ~= "" and meta.Pinned or nil
		pinnedActive = pinned ~= nil
		pin.Frame.Visible = pinnedActive
		if pinned then
			local pinnedContent = tostring(pinned.Content)
			pin.Meta.Text = "📌  PINNED • " .. tostring(pinned.UpdatedByName or "OWNER")
			if pin.Content ~= pinnedContent then
				-- New pinned text: show it in full again so it gets noticed.
				pin.Content = pinnedContent
				pin.Text.Text = pinnedContent
				pin.Body.CanvasPosition = Vector2.zero
				pin.SetMode("full")
			end
		end
		applyLayout()
		local online = tonumber(meta.OnlineCount)
		titleLabel.Text = online and (baseTitle .. "  •  " .. online .. " online") or baseTitle
	end

	-- Report with a reason.
	local reportOverlay = Instance.new("TextButton")
	reportOverlay.Name = "ReportOverlay"
	reportOverlay.Text = ""
	reportOverlay.AutoButtonColor = false
	reportOverlay.BackgroundColor3 = Color3.new(0, 0, 0)
	reportOverlay.BackgroundTransparency = 0.4
	reportOverlay.BorderSizePixel = 0
	reportOverlay.Visible = false
	reportOverlay.Size = UDim2.fromScale(1, 1)
	reportOverlay.ZIndex = BASE_Z + 20
	reportOverlay.Parent = panel

	local reportCard = Instance.new("Frame")
	reportCard.BackgroundColor3 = NullUI.Theme.Surface
	reportCard.BorderSizePixel = 0
	reportCard.AnchorPoint = Vector2.new(0.5, 0.5)
	reportCard.Position = UDim2.fromScale(0.5, 0.5)
	reportCard.Size = UDim2.new(1, -40, 0, 168)
	reportCard.ZIndex = BASE_Z + 21
	reportCard.Parent = reportOverlay
	Corner(reportCard, 10)
	Stroke(reportCard, Color3.new(1, 1, 1), 1, 0.88)

	local function reportText(text, size, y, h, font, color)
		local l = Instance.new("TextLabel")
		l.BackgroundTransparency = 1
		l.FontFace = font
		l.Text = text
		l.TextColor3 = color
		l.TextSize = size
		l.TextTruncate = Enum.TextTruncate.AtEnd
		l.TextXAlignment = Enum.TextXAlignment.Left
		l.Position = UDim2.fromOffset(12, y)
		l.Size = UDim2.new(1, -24, 0, h)
		l.ZIndex = BASE_Z + 22
		l.Parent = reportCard
		return l
	end
	reportText("Report chat / user", 13, 9, 18, NullUI.Theme.Font, NullUI.Theme.Text)
	local reportTarget = reportText("", 11, 28, 14, NullUI.Theme.FontRegular, NullUI.Theme.TextDim)

	local reportInput = Instance.new("TextBox")
	reportInput.BackgroundColor3 = Color3.new(1, 1, 1)
	reportInput.BackgroundTransparency = 0.94
	reportInput.BorderSizePixel = 0
	reportInput.ClearTextOnFocus = false
	reportInput.MultiLine = true
	reportInput.TextWrapped = true
	reportInput.FontFace = NullUI.Theme.FontRegular
	reportInput.PlaceholderText = "Enter report reason..."
	reportInput.PlaceholderColor3 = Color3.fromRGB(120, 120, 122)
	reportInput.Text = ""
	reportInput.TextColor3 = NullUI.Theme.Text
	Role(reportInput, "Text")
	reportInput.TextSize = 12
	reportInput.TextXAlignment = Enum.TextXAlignment.Left
	reportInput.TextYAlignment = Enum.TextYAlignment.Top
	reportInput.Position = UDim2.fromOffset(12, 48)
	reportInput.Size = UDim2.new(1, -24, 0, 70)
	reportInput.ZIndex = BASE_Z + 22
	reportInput.Parent = reportCard
	Corner(reportInput, 6)
	local reportPad = Instance.new("UIPadding")
	reportPad.PaddingTop = UDim.new(0, 6)
	reportPad.PaddingBottom = UDim.new(0, 6)
	reportPad.PaddingLeft = UDim.new(0, 8)
	reportPad.PaddingRight = UDim.new(0, 8)
	reportPad.Parent = reportInput

	local function reportButton(text, xOffset, transparency)
		local b = Instance.new("TextButton")
		b.Text = text
		b.AutoButtonColor = false
		b.FontFace = NullUI.Theme.Font
		b.TextSize = 11
		b.TextColor3 = NullUI.Theme.Text
		b.BackgroundColor3 = Color3.new(1, 1, 1)
		b.BackgroundTransparency = transparency
		b.BorderSizePixel = 0
		b.Position = UDim2.new(0.5, xOffset, 1, -38)
		b.Size = UDim2.fromOffset(88, 28)
		b.ZIndex = BASE_Z + 22
		b.Parent = reportCard
		Corner(b, 6)
		return b
	end
	local reportCancel = reportButton("Cancel", -94, 0.9)
	local reportSubmit = reportButton("Send report", 6, 0.75)

	local reportingMsg, reportBusy = nil, false
	local function closeReport()
		if reportBusy then
			return
		end
		reportingMsg = nil
		reportInput.Text = ""
		reportOverlay.Visible = false
	end
	local function openReport(msg)
		reportingMsg = msg
		reportTarget.Text = "Reporting " .. maskedName(msg.PlayerName or "Guest")
		reportInput.Text = ""
		reportOverlay.Visible = true
		pcall(function()
			reportInput:CaptureFocus()
		end)
	end
	jan:Add(reportCancel.MouseButton1Click:Connect(closeReport))
	jan:Add(reportSubmit.MouseButton1Click:Connect(function()
		if reportBusy or not reportingMsg then
			return
		end
		local reason = reportInput.Text:gsub("^%s+", ""):gsub("%s+$", "")
		if reason == "" then
			NullUI:Notify({ Title = "Report", Text = "Enter a report reason.", Type = "warning", Duration = 3 })
			return
		end
		reportBusy = true
		reportSubmit.Text = "Sending..."
		SafeSpawn(function()
			local ok, err = service:ReportChatMessage(reportingMsg.Id, reason)
			reportBusy = false
			reportSubmit.Text = "Send report"
			if ok then
				closeReport()
			end
			NullUI:Notify({
				Title = ok and "Reported" or "Could not report",
				Text = ok and "Report sent to the admins." or tostring(err),
				Type = ok and "success" or "error",
				Duration = 3,
			})
		end)
	end))

	-- Join-server sharing.
	local allowJoin = false
	local function publishPresence()
		if not service or not service.PublishChatPresence then
			return false, "Presence is not supported by the relay."
		end
		return service:PublishChatPresence(LocalPlayer.UserId, allowJoin, game.PlaceId, game.JobId)
	end
	local function confirmJoin(msg)
		NullUI:Confirm({
			Title = "Join server?",
			Text = "Join " .. maskedName(msg.PlayerName or "this player") .. " in " .. tostring(msg.GameName or "their game")
				.. "? You will leave your current server.",
			ConfirmText = "Join",
			CancelText = "Cancel",
			Window = self,
			Callback = function(confirmed)
				if not confirmed then
					return
				end
				SafeSpawn(function()
					local target = type(msg.JoinServer) == "table" and msg.JoinServer or nil
					if service.GetChatJoinTarget and msg.UserId and msg.UserId ~= 0 then
						-- Ask the relay for the fresh target; the one on the message may be stale.
						target = service:GetChatJoinTarget(msg.UserId)
					end
					local placeId = type(target) == "table" and tonumber(target.PlaceId) or nil
					local jobId = type(target) == "table" and target.JobId or nil
					if not placeId or type(jobId) ~= "string" or jobId == "" then
						NullUI:Notify({
							Title = "Chat",
							Text = "This player is no longer sharing a server.",
							Type = "warning",
							Duration = 3,
						})
						return
					end
					if placeId == game.PlaceId and jobId == game.JobId then
						NullUI:Notify({ Title = "Chat", Text = "You are already in this server.", Type = "info", Duration = 3 })
						return
					end
					local ok, err = pcall(function()
						game:GetService("TeleportService"):TeleportToPlaceInstance(placeId, jobId, LocalPlayer)
					end)
					if not ok then
						NullUI:Notify({ Title = "Chat", Text = "Join failed: " .. tostring(err), Type = "error", Duration = 3 })
					end
				end)
			end,
		})
	end

	-- Rendered rows by message id, so messages deleted by an admin can be removed.
	local rowsById = {}

	local function addBubble(msg, isOwn)
		order = order + 1
		local text = tostring(msg.Text or ""):gsub("^%s+", ""):gsub("%s+$", "")
		if text == "" then
			return
		end
		if chatEmpty.Parent then
			chatEmpty.Visible = false
		end

		local row = Instance.new("Frame")
		row.Name = "ChatRow"
		row.BackgroundTransparency = 1
		row.AutomaticSize = Enum.AutomaticSize.Y
		row.Size = UDim2.new(1, 0, 0, 0)
		row.LayoutOrder = order
		row.ZIndex = BASE_Z + 1
		row.Parent = msgScroll
		if msg.Id then
			rowsById[msg.Id] = row
		end

		local rowScale = Instance.new("UIScale")
		rowScale.Scale = 0.92
		rowScale.Parent = row

		local rowLayout = Instance.new("UIListLayout")
		rowLayout.FillDirection = Enum.FillDirection.Horizontal
		rowLayout.HorizontalAlignment = isOwn and Enum.HorizontalAlignment.Right or Enum.HorizontalAlignment.Left
		rowLayout.VerticalAlignment = Enum.VerticalAlignment.Top
		rowLayout.Padding = UDim.new(0, C.RowGap)
		-- Default sort is by Name, which put the action icons before the avatar.
		rowLayout.SortOrder = Enum.SortOrder.LayoutOrder
		rowLayout.Parent = row

		local isAnon = not msg.UserId or msg.UserId == 0

		local avatar = Instance.new("Frame")
		avatar.Name = "Avatar"

		avatar.BackgroundColor3 = isAnon and Color3.fromRGB(196, 143, 105) or NullUI.Theme.Accent
		avatar.BackgroundTransparency = 1
		avatar.BorderSizePixel = 0
		avatar.Size = UDim2.fromOffset(AVATAR, AVATAR)
		avatar.LayoutOrder = isOwn and 2 or 1
		avatar.ZIndex = BASE_Z + 2
		avatar.Parent = row
		Corner(avatar, AVATAR / 2)

		if isAnon then
			local anonIconImg = Instance.new("ImageLabel")
			anonIconImg.BackgroundTransparency = 1
			anonIconImg.ImageTransparency = 1
			anonIconImg.Image = ResolveIcon("user-round")
			anonIconImg.ImageColor3 = Color3.fromRGB(90, 61, 40)
			anonIconImg.Size = UDim2.fromOffset(15, 15)
			anonIconImg.AnchorPoint = Vector2.new(0.5, 0.5)
			anonIconImg.Position = UDim2.fromScale(0.5, 0.5)
			anonIconImg.ZIndex = BASE_Z + 3
			anonIconImg.Parent = avatar
			Tween(anonIconImg, { ImageTransparency = 0 }, 0.18)
		else
			local avatarImg = Instance.new("ImageLabel")
			avatarImg.BackgroundTransparency = 1
			avatarImg.ImageTransparency = 1
			avatarImg.ScaleType = Enum.ScaleType.Crop
			avatarImg.Size = UDim2.fromScale(1, 1)
			avatarImg.ZIndex = BASE_Z + 3
			avatarImg.Parent = avatar
			Corner(avatarImg, AVATAR / 2)
			Tween(avatarImg, { ImageTransparency = 0 }, 0.18)
			SafeSpawn(function()
				local ok, content = pcall(
					Players.GetUserThumbnailAsync,
					Players,
					msg.UserId,
					Enum.ThumbnailType.HeadShot,
					Enum.ThumbnailSize.Size100x100
				)
				if ok and content and avatarImg.Parent then
					avatarImg.Image = content
				end
			end)
		end

		local H_PAD, V_PAD = C.HPad, C.VPad
		local BUBBLE_MAX_WIDTH = 240

		local MIN_BUBBLE_WIDTH = 64
		local actionCount = (msg.Id and service) and (isOwn and 2 or 3) or 0
		local actionsW = actionCount > 0 and (actionCount * 20 + (actionCount - 1) * 2 + C.RowGap) or 0
		local naturalW = MeasureText(text, C.Text, 10000)
		local bubbleWidth = math.min(naturalW, BUBBLE_MAX_WIDTH - H_PAD * 2) + H_PAD * 2
		bubbleWidth = math.max(bubbleWidth, MIN_BUBBLE_WIDTH)
		if msgScroll.AbsoluteSize.X > 0 then
			local avail = msgScroll.AbsoluteSize.X / GetUIScale() - C.PadR - AVATAR - C.RowGap - actionsW - 4
			bubbleWidth = math.min(bubbleWidth, math.max(130, avail))
		end

		local bubble = Instance.new("Frame")
		bubble.Name = "Bubble"
		bubble.BackgroundColor3 = isOwn and NullUI.Theme.Accent or Color3.new(1, 1, 1)
		bubble.BackgroundTransparency = 1
		bubble.BorderSizePixel = 0
		bubble.ClipsDescendants = true
		bubble.AutomaticSize = Enum.AutomaticSize.Y
		bubble.Size = UDim2.fromOffset(bubbleWidth, 0)
		bubble.LayoutOrder = isOwn and 1 or 2
		bubble.ZIndex = BASE_Z + 2
		bubble.Parent = row
		Corner(bubble, 12)
		local bubbleStroke = Stroke(bubble, Color3.new(1, 1, 1), 1, 1)

		local bubblePad = Instance.new("UIPadding")
		bubblePad.PaddingTop = UDim.new(0, V_PAD)
		bubblePad.PaddingBottom = UDim.new(0, V_PAD)
		bubblePad.PaddingLeft = UDim.new(0, H_PAD)
		bubblePad.PaddingRight = UDim.new(0, H_PAD)
		bubblePad.Parent = bubble

		local bubbleLayout = Instance.new("UIListLayout")
		bubbleLayout.SortOrder = Enum.SortOrder.LayoutOrder
		bubbleLayout.Parent = bubble

		local senderTag = tostring(msg.SenderTag or "")
		local roleTag = senderTag == "OWNER" and { Label = "OWNER", Color = "#EF4444" }
			or senderTag == "ADMIN" and { Label = "ADMIN", Color = "#EF4444" }
			or senderTag == "SUPPORT" and { Label = "SUPPORT", Color = "#3B82F6" }
			or (not isAnon and ChatRoleTags[tostring(msg.UserId)])
		local metaName = msg.PlayerName and (senderTag == "OWNER" and msg.PlayerName or maskedName(msg.PlayerName))
		if metaName or roleTag or msg.GameName then
			local parts = {}
			if metaName then
				table.insert(parts, escapeRich(metaName))
			end
			if roleTag then
				table.insert(parts, string.format('<font color="%s">[%s]</font>', roleTag.Color, roleTag.Label))
			end
			local metaText = table.concat(parts, " ")
			if msg.GameName and tostring(msg.GameName) ~= "" then
				metaText = metaText .. (metaText ~= "" and "  •  " or "") .. escapeRich(tostring(msg.GameName))
			end
			local metaLbl = Instance.new("TextLabel")
			metaLbl.Name = "Meta"
			metaLbl.BackgroundTransparency = 1
			metaLbl.FontFace = NullUI.Theme.Font
			metaLbl.RichText = true
			metaLbl.Text = metaText
			metaLbl.TextColor3 = isOwn and Color3.new(1, 1, 1) or NullUI.Theme.TextDim
			metaLbl.TextTransparency = 0.25
			metaLbl.TextSize = 10
			metaLbl.TextTruncate = Enum.TextTruncate.AtEnd
			metaLbl.TextXAlignment = Enum.TextXAlignment.Left
			metaLbl.Size = UDim2.new(1, 0, 0, 13)
			metaLbl.LayoutOrder = -2
			metaLbl.ZIndex = BASE_Z + 3
			metaLbl.Parent = bubble
		end

		local replyData = type(msg.Reply) == "table" and tostring(msg.Reply.Content or "") ~= "" and msg.Reply or nil
		if replyData then
			local quote = Instance.new("TextLabel")
			quote.Name = "ReplyQuote"
			quote.BackgroundTransparency = 1
			quote.FontFace = NullUI.Theme.FontRegular
			quote.Text = "↪ " .. maskedName(tostring(replyData.PlayerName or "Guest")) .. ": " .. tostring(replyData.Content)
			quote.TextColor3 = isOwn and Color3.new(1, 1, 1) or NullUI.Theme.TextDim
			quote.TextTransparency = 0.35
			quote.TextSize = 10
			quote.TextTruncate = Enum.TextTruncate.AtEnd
			quote.TextXAlignment = Enum.TextXAlignment.Left
			quote.Size = UDim2.new(1, 0, 0, 13)
			quote.LayoutOrder = -1
			quote.ZIndex = BASE_Z + 3
			quote.Parent = bubble
		end

		local label = Instance.new("TextLabel")
		label.BackgroundTransparency = 1
		label.FontFace = NullUI.Theme.FontRegular
		label.Text = text
		label.TextColor3 = NullUI.Theme.Text
		Role(label, "Text")
		label.TextTransparency = 1
		label.TextSize = C.Text
		label.TextWrapped = true
		label.TextXAlignment = Enum.TextXAlignment.Left
		label.TextYAlignment = Enum.TextYAlignment.Top
		label.LineHeight = C.Mobile and 1.15 or 1.3
		label.AutomaticSize = Enum.AutomaticSize.Y
		label.Size = UDim2.new(1, 0, 0, 16)
		label.LayoutOrder = 1
		label.ZIndex = BASE_Z + 3
		label.Parent = bubble

		if msg.CreatedAt then
			local timeLbl = Instance.new("TextLabel")
			timeLbl.BackgroundTransparency = 1
			timeLbl.FontFace = NullUI.Theme.FontRegular
			timeLbl.Text = os.date("%H:%M", math.floor(msg.CreatedAt / 1000))
			timeLbl.TextColor3 = isOwn and Color3.new(1, 1, 1) or NullUI.Theme.TextDim
			timeLbl.TextTransparency = isOwn and 0.5 or 0.4
			timeLbl.TextSize = C.Mobile and 9 or 10
			timeLbl.TextXAlignment = Enum.TextXAlignment.Left
			timeLbl.AutomaticSize = Enum.AutomaticSize.Y
			timeLbl.Size = UDim2.new(1, 0, 0, C.Mobile and 10 or 12)
			timeLbl.LayoutOrder = 2
			timeLbl.ZIndex = BASE_Z + 3

			timeLbl.Visible = showTimestamps
			timeLbl.Parent = bubble
			table.insert(timestampLabels, timeLbl)
		end

		if msg.Id and service then
			local actions = Instance.new("Frame")
			actions.Name = "Actions"
			actions.BackgroundTransparency = 1
			actions.AutomaticSize = Enum.AutomaticSize.XY
			actions.Size = UDim2.fromOffset(0, 0)
			actions.LayoutOrder = isOwn and 0 or 3
			actions.ZIndex = BASE_Z + 2
			actions.Parent = row

			local actionsLayout = Instance.new("UIListLayout")
			actionsLayout.FillDirection = Enum.FillDirection.Horizontal
			actionsLayout.VerticalAlignment = Enum.VerticalAlignment.Top
			actionsLayout.SortOrder = Enum.SortOrder.LayoutOrder
			actionsLayout.Padding = UDim.new(0, 2)
			actionsLayout.Parent = actions

			-- Icons stay visible (no hover needed, so they work on touch).
			local function addAction(order, iconName, hoverColor, onClick)
				local btn = Instance.new("TextButton")
				btn.Text = ""
				btn.AutoButtonColor = false
				btn.BackgroundColor3 = Color3.new(1, 1, 1)
				btn.BackgroundTransparency = 0.94
				btn.BorderSizePixel = 0
				btn.Size = UDim2.fromOffset(20, 20)
				btn.LayoutOrder = order
				btn.ZIndex = BASE_Z + 2
				btn.Parent = actions
				Corner(btn, 6)

				local icon = Instance.new("ImageLabel")
				icon.BackgroundTransparency = 1
				icon.Image = ResolveIcon(iconName)
				icon.ImageColor3 = NullUI.Theme.TextDim
				Role(icon, "TextDim")
				icon.ImageTransparency = 0.2
				icon.Size = UDim2.fromOffset(12, 12)
				icon.AnchorPoint = Vector2.new(0.5, 0.5)
				icon.Position = UDim2.fromScale(0.5, 0.5)
				icon.ZIndex = BASE_Z + 3
				icon.Parent = btn

				jan:Add(btn.MouseEnter:Connect(function()
					Tween(btn, { BackgroundTransparency = 0.85 }, 0.12)
					Tween(icon, { ImageColor3 = hoverColor, ImageTransparency = 0 }, 0.12)
				end))
				jan:Add(btn.MouseLeave:Connect(function()
					Tween(btn, { BackgroundTransparency = 0.94 }, 0.12)
					Tween(icon, { ImageColor3 = NullUI.Theme.TextDim, ImageTransparency = 0.2 }, 0.12)
				end))
				jan:Add(btn.MouseButton1Click:Connect(function()
					onClick(icon)
				end))
			end

			addAction(1, "copy", Color3.fromRGB(120, 220, 140), function(icon)
				local setclipboard = hasFn("setclipboard")
				if not setclipboard then
					NullUI:Notify({ Title = "Chat", Text = "Clipboard is not available.", Type = "warning", Duration = 3 })
					return
				end
				pcall(setclipboard, text)
				icon.ImageColor3 = Color3.fromRGB(120, 220, 140)
				SafeDelay(0.6, function()
					if icon.Parent then
						Tween(icon, { ImageColor3 = NullUI.Theme.TextDim }, 0.18)
					end
				end)
			end)
			addAction(2, "reply", NullUI.Theme.Text, function()
				setReply(msg)
			end)
			if not isOwn then
				addAction(3, "flag", NullUI.Theme.Danger, function()
					openReport(msg)
				end)
			end
		end

		local joinData = type(msg.JoinServer) == "table" and msg.JoinServer or nil
		if joinData and not isOwn and service and tonumber(joinData.PlaceId) and tostring(joinData.JobId or "") ~= "" then
			local joinBtn = Instance.new("TextButton")
			joinBtn.Name = "JoinServer"
			joinBtn.Text = "Join Server"
			joinBtn.AutoButtonColor = false
			joinBtn.FontFace = NullUI.Theme.Font
			joinBtn.TextSize = 10
			joinBtn.TextColor3 = Color3.fromRGB(105, 182, 255)
			joinBtn.BackgroundColor3 = Color3.new(1, 1, 1)
			joinBtn.BackgroundTransparency = 0.9
			joinBtn.BorderSizePixel = 0
			joinBtn.Size = UDim2.new(1, 0, 0, 20)
			joinBtn.LayoutOrder = 3
			joinBtn.ZIndex = BASE_Z + 3
			joinBtn.Parent = bubble
			Corner(joinBtn, 6)
			jan:Add(joinBtn.MouseButton1Click:Connect(function()
				confirmJoin(msg)
			end))
		end

		local avatarFinalTransparency = isOwn and 0.85 or 0.82
		local bubbleFinalTransparency = isOwn and 0.72 or 0.9
		local strokeFinalTransparency = isOwn and 0.8 or 0.9
		Tween(avatar, { BackgroundTransparency = avatarFinalTransparency }, 0.18)
		Tween(bubble, { BackgroundTransparency = bubbleFinalTransparency }, 0.18)
		Tween(bubbleStroke, { Transparency = strokeFinalTransparency }, 0.18)
		Tween(label, { TextTransparency = 0 }, 0.18)
		Tween(rowScale, { Scale = 1 }, 0.26, Enum.EasingStyle.Back, Enum.EasingDirection.Out)

		scrollToBottom()
		table.insert(transcript, (isOwn and "You" or "Someone") .. ": " .. text)
	end

	jan:Add(copyBtn.MouseButton1Click:Connect(function()
		local setclipboard = hasFn("setclipboard")
		if not setclipboard or #transcript == 0 then
			return
		end
		pcall(setclipboard, table.concat(transcript, "\n"))
		Tween(copyIcon, { ImageColor3 = Color3.fromRGB(120, 220, 140) }, 0.12)
		SafeDelay(0.4, function()
			if copyIcon.Parent then
				Tween(copyIcon, { ImageColor3 = NullUI.Theme.TextDim }, 0.18)
			end
		end)
	end))

	local seenIds = { [0] = true }
	local lastSeenId = 0
	-- Relay announcements are shown once per id; an early removal by the admin
	-- (announcement gone from the feed) dismisses the toast.
	local lastAnnouncementId, announcementHandle = nil, nil
	local function syncAnnouncement()
		local a = service and service.ChatMeta and service.ChatMeta.Announcement
		if type(a) ~= "table" or not a.Id then
			if announcementHandle then
				announcementHandle.Dismiss()
				announcementHandle = nil
			end
			return
		end
		if a.Id == lastAnnouncementId then
			return
		end
		lastAnnouncementId = a.Id
		local remaining = (tonumber(a.RemainingMs) or 0) / 1000
		if remaining > 0.5 then
			announcementHandle = NullUI:Announce({
				Title = a.Title,
				Text = a.Content,
				Duration = math.max(remaining, 3),
			})
		end
	end
	-- The relay rejects a second message within 1.5s; Enter + the send button can
	-- both fire for one message, so keep a single send in flight.
	local SEND_COOLDOWN = 1.5
	local sending, lastSendAt = false, 0

	local function trySend()
		local text = inputBox.Text:gsub("^%s+", ""):gsub("%s+$", "")
		if text == "" or sending then
			return
		end
		local wait = SEND_COOLDOWN - (os.clock() - lastSendAt)
		if wait > 0 then
			NullUI:Notify({
				Title = "Chat",
				Text = string.format("Slow down -- wait %.1fs.", wait),
				Type = "warning",
				Duration = 2,
			})
			return
		end
		if not service then
			NullUI:Notify({
				Title = opts.Title or "Chat",
				Text = "Global chat is not configured by the script owner.",
				Type = "warning",
				Duration = 3,
			})
			return
		end
		inputBox.Text = ""
		local sendUserId = anonymousMode and 0 or LocalPlayer.UserId
		local playerName = anonymousMode and nil or maskedName(LocalPlayer.DisplayName or LocalPlayer.Name)
		local replying = replyingTo
		clearReply()
		sending = true
		SafeSpawn(function()
			local ok, result, err = pcall(service.SendChatMessage, service, sendUserId, text, {
				PlayerName = playerName,
				GameName = gameName,
				ReplyToId = replying and replying.Id or nil,
			})
			sending = false
			lastSendAt = os.clock()
			if not ok then
				result, err = nil, result
			end
			if not result then
				-- Give the text back so a failed send doesn't lose the message.
				if inputBox.Parent and inputBox.Text == "" then
					inputBox.Text = text
				end
				NullUI:Notify({ Title = "Chat", Text = tostring(err), Type = "error", Duration = 3 })
				return
			end
			seenIds[result.Id] = true
			if result.Id > lastSeenId then
				lastSeenId = result.Id
			end
			addBubble({
				Id = result.Id,
				UserId = sendUserId,
				PlayerName = playerName,
				GameName = gameName,
				-- Prefer the server's stored text: the relay may rewrite blocked content.
				-- Without it, apply the same rule locally so the sender sees the warning.
				Text = type(result.Text) == "string" and result.Text or censorForeignLoadstrings(text),
				CreatedAt = os.time() * 1000,
				Reply = replying and { PlayerName = replying.PlayerName, Content = replying.Text } or nil,
			}, true)
		end)
	end

	jan:Add(sendBtn.MouseButton1Click:Connect(trySend))
	jan:Add(inputBox.FocusLost:Connect(function(enterPressed)
		if enterPressed then
			trySend()
		end
	end))
	jan:Add(anonBtn.MouseButton1Click:Connect(function()
		anonymousMode = not anonymousMode
		anonIcon.Image = ResolveIcon(anonymousMode and "eye-off" or "eye")
		NullUI:Notify({
			Title = "Chat",
			Text = anonymousMode and "Anonymous mode on -- new messages won't reveal your avatar."
				or "Anonymous mode off -- new messages show your avatar.",
			Type = "info",
			Duration = 3,
		})
	end))
	jan:Add(clearBtn.MouseButton1Click:Connect(function()
		for _, child in ipairs(msgScroll:GetChildren()) do
			if child.Name == "ChatRow" then
				child:Destroy()
			end
		end
		table.clear(transcript)
		table.clear(timestampLabels)
		table.clear(rowsById)
	end))
	jan:Add(closeBtn.MouseButton1Click:Connect(function()
		if self._currentTab == tabObj then
			if self._tabs[1] and self._tabs[1] ~= tabObj then
				self._tabs[1]._select()
			end
		end
	end))

	local settingsPopup
	local function closeSettingsPopup()
		if settingsPopup then
			settingsPopup:Destroy()
			settingsPopup = nil
		end
	end

	local function openSettingsPopup()
		if settingsPopup then
			closeSettingsPopup()
			return
		end

		local popup = Instance.new("Frame")
		popup.Name = "ChatSettingsPopup"
		popup.BackgroundColor3 = NullUI.Theme.Surface
		popup.BackgroundTransparency = 0.05
		popup.BorderSizePixel = 0
		popup.AnchorPoint = Vector2.new(1, 0)
		popup.Position = UDim2.new(1, 0, 0, HEADER_H + 4)
		popup.Size = UDim2.new(0, 190, 0, 0)
		popup.AutomaticSize = Enum.AutomaticSize.Y
		popup.ClipsDescendants = true
		popup.ZIndex = BASE_Z + 10
		popup.Parent = panel
		Corner(popup, 10)
		local popupStroke = Stroke(popup, Color3.new(1, 1, 1), 1, 0.88)

		local popupPad = Instance.new("UIPadding")
		popupPad.PaddingTop = UDim.new(0, 10)
		popupPad.PaddingBottom = UDim.new(0, 10)
		popupPad.PaddingLeft = UDim.new(0, 12)
		popupPad.PaddingRight = UDim.new(0, 12)
		popupPad.Parent = popup

		local popupLayout = Instance.new("UIListLayout")
		popupLayout.Padding = UDim.new(0, 8)
		popupLayout.SortOrder = Enum.SortOrder.LayoutOrder
		popupLayout.Parent = popup

		local function toggleRow(order, label, getValue, onToggle)
			local row = Instance.new("Frame")
			row.BackgroundTransparency = 1
			row.Size = UDim2.new(1, 0, 0, 20)
			row.LayoutOrder = order
			row.ZIndex = BASE_Z + 11
			row.Parent = popup

			local lbl = Instance.new("TextLabel")
			lbl.BackgroundTransparency = 1
			lbl.FontFace = NullUI.Theme.FontRegular
			lbl.Text = label
			lbl.TextColor3 = NullUI.Theme.Text
			Role(lbl, "Text")
			lbl.TextSize = 12
			lbl.TextXAlignment = Enum.TextXAlignment.Left
			lbl.Size = UDim2.new(1, -30, 1, 0)
			lbl.ZIndex = BASE_Z + 12
			lbl.Parent = row

			local check = Instance.new("TextButton")
			check.Text = ""
			check.AutoButtonColor = false
			check.BackgroundColor3 = Color3.new(1, 1, 1)
			check.BackgroundTransparency = getValue() and 0.7 or 0.92
			check.BorderSizePixel = 0
			check.AnchorPoint = Vector2.new(1, 0.5)
			check.Position = UDim2.new(1, 0, 0.5, 0)
			check.Size = UDim2.fromOffset(20, 20)
			check.ZIndex = BASE_Z + 12
			check.Parent = row
			Corner(check, 6)

			local checkIcon = Instance.new("ImageLabel")
			checkIcon.BackgroundTransparency = 1
			checkIcon.Image = ResolveIcon("check")
			checkIcon.ImageColor3 = NullUI.Theme.Accent
			checkIcon.ImageTransparency = getValue() and 0 or 1
			checkIcon.Size = UDim2.fromOffset(11, 11)
			checkIcon.AnchorPoint = Vector2.new(0.5, 0.5)
			checkIcon.Position = UDim2.fromScale(0.5, 0.5)
			checkIcon.ZIndex = BASE_Z + 13
			checkIcon.Parent = check

			jan:Add(check.MouseButton1Click:Connect(function()
				local newValue = onToggle()
				Tween(check, { BackgroundTransparency = newValue and 0.7 or 0.92 }, 0.12)
				Tween(checkIcon, { ImageTransparency = newValue and 0 or 1 }, 0.12)
			end))
		end

		toggleRow(1, "Show timestamps", function()
			return showTimestamps
		end, function()
			showTimestamps = not showTimestamps
			for _, lbl in ipairs(timestampLabels) do
				if lbl.Parent then
					lbl.Visible = showTimestamps
				end
			end
			return showTimestamps
		end)
		toggleRow(2, "Sound on new message", function()
			return notifySound
		end, function()
			notifySound = not notifySound
			return notifySound
		end)
		toggleRow(3, "Fast updates (1s)", function()
			return pollInterval <= 1
		end, function()
			pollInterval = (pollInterval <= 1) and (opts.PollInterval or 2.5) or 1
			return pollInterval <= 1
		end)
		if service and service.PublishChatPresence then
			toggleRow(4, "Allow others to join me", function()
				return allowJoin
			end, function()
				if not allowJoin and (game.JobId == "" or game.PrivateServerId ~= "" or game.PlaceId <= 0) then
					NullUI:Notify({
						Title = "Chat",
						Text = "Join sharing needs a public game server.",
						Type = "warning",
						Duration = 3,
					})
					return false
				end
				allowJoin = not allowJoin
				SafeSpawn(function()
					local ok, err = publishPresence()
					if not ok then
						allowJoin = not allowJoin
						NullUI:Notify({ Title = "Chat", Text = tostring(err), Type = "error", Duration = 3 })
					end
				end)
				return allowJoin
			end)
		end

		settingsPopup = popup
	end

	jan:Add(settingsBtn.MouseButton1Click:Connect(function()
		if settingsPopup then
			closeSettingsPopup()
		else
			openSettingsPopup()
		end
	end))

	-- Admin mailbox: notices that stay until an admin deletes them. The feed only
	-- carries {LatestId, Count}; the list is fetched when the popup opens. The
	-- last opened id is stored on this device and drives the red dots.
	local MAILBOX_SEEN_FILE = "NullUI/global_chat_mailbox_seen.txt"
	local mailboxDefaults = {
		Title = "Mailbox",
		Notice = "New message from admin",
		Empty = "The mailbox is empty.",
		Loading = "Loading...",
		Error = "Couldn't load the mailbox.",
		Edited = "edited",
		Open = "Open",
	}
	-- Hosts may pass strings or functions (e.g. to follow their own language).
	local function mailboxText(key)
		local value = opts.MailboxText and opts.MailboxText[key]
		if type(value) == "function" then
			value = value()
		end
		return value or mailboxDefaults[key]
	end
	local function mailboxAge(createdAtMs)
		local seconds = math.max(0, os.time() - math.floor((tonumber(createdAtMs) or 0) / 1000))
		local format = opts.MailboxText and opts.MailboxText.FormatAge
		if format then
			return format(seconds)
		end
		if seconds < 60 then
			return "just now"
		elseif seconds < 3600 then
			return math.floor(seconds / 60) .. "m ago"
		elseif seconds < 86400 then
			return math.floor(seconds / 3600) .. "h ago"
		end
		return math.floor(seconds / 86400) .. "d ago"
	end

	local mailboxSeenId = 0
	pcall(function()
		if fn_isfile and fn_readfile and fn_isfile(MAILBOX_SEEN_FILE) then
			mailboxSeenId = tonumber(fn_readfile(MAILBOX_SEEN_FILE)) or 0
		end
	end)
	local mailboxLatestId, mailboxCount, mailboxNotifiedId = 0, 0, 0
	local mailboxPopup, mailboxList = nil, nil

	local tabDot = nil
	if hasMailbox and tabObj._icon then
		tabDot = Instance.new("Frame")
		tabDot.Name = "MailboxDot"
		tabDot.AnchorPoint = Vector2.new(0.5, 0.5)
		tabDot.Position = UDim2.new(1, 0, 0, 1)
		tabDot.Size = UDim2.fromOffset(7, 7)
		tabDot.BackgroundColor3 = Color3.fromRGB(239, 68, 68)
		tabDot.BorderSizePixel = 0
		tabDot.Visible = false
		tabDot.ZIndex = tabObj._icon.ZIndex + 1
		tabDot.Parent = tabObj._icon
		Corner(tabDot, 4)
	end

	local function setMailboxUnread(unread)
		mailboxDot.Visible = unread
		mailboxNotice.Text = mailboxText("Notice")
		mailboxNotice.Visible = unread
		if tabDot then
			tabDot.Visible = unread
		end
	end

	local function markMailboxSeen()
		if mailboxLatestId > mailboxSeenId then
			mailboxSeenId = mailboxLatestId
			pcall(function()
				if fn_isfolder and fn_makefolder and not fn_isfolder("NullUI") then
					fn_makefolder("NullUI")
				end
				if fn_writefile then
					fn_writefile(MAILBOX_SEEN_FILE, tostring(mailboxSeenId))
				end
			end)
		end
		setMailboxUnread(false)
	end

	local function mailboxLabel(parent, text, font, size, color, order)
		local lbl = Instance.new("TextLabel")
		lbl.BackgroundTransparency = 1
		lbl.FontFace = font
		lbl.Text = text
		lbl.RichText = false
		lbl.TextColor3 = color
		lbl.TextSize = size
		lbl.TextWrapped = true
		lbl.TextXAlignment = Enum.TextXAlignment.Left
		lbl.AutomaticSize = Enum.AutomaticSize.Y
		lbl.Size = UDim2.new(1, 0, 0, 0)
		lbl.LayoutOrder = order
		lbl.ZIndex = BASE_Z + 13
		lbl.Parent = parent
		return lbl
	end

	local function renderMailbox(items, failed)
		if not mailboxList then
			return
		end
		for _, child in ipairs(mailboxList:GetChildren()) do
			if child:IsA("GuiObject") then
				child:Destroy()
			end
		end
		if not items or #items == 0 then
			local key = failed and "Error" or (items and "Empty" or "Loading")
			local note = mailboxLabel(mailboxList, mailboxText(key), NullUI.Theme.FontRegular, 12, NullUI.Theme.TextDim, 1)
			note.TextXAlignment = Enum.TextXAlignment.Center
			return
		end
		for index, item in ipairs(items) do
			local card = Instance.new("Frame")
			card.Name = "MailboxEntry"
			card.BackgroundColor3 = Color3.new(1, 1, 1)
			card.BackgroundTransparency = 0.95
			card.BorderSizePixel = 0
			card.AutomaticSize = Enum.AutomaticSize.Y
			card.Size = UDim2.new(1, -6, 0, 0)
			card.LayoutOrder = index
			card.ZIndex = BASE_Z + 12
			card.Parent = mailboxList
			Corner(card, 8)
			local cardPad = Instance.new("UIPadding")
			cardPad.PaddingTop = UDim.new(0, 8)
			cardPad.PaddingBottom = UDim.new(0, 8)
			cardPad.PaddingLeft = UDim.new(0, 10)
			cardPad.PaddingRight = UDim.new(0, 10)
			cardPad.Parent = card
			local cardLayout = Instance.new("UIListLayout")
			cardLayout.Padding = UDim.new(0, 3)
			cardLayout.SortOrder = Enum.SortOrder.LayoutOrder
			cardLayout.Parent = card

			if item.Title and item.Title ~= "" then
				mailboxLabel(card, item.Title, NullUI.Theme.Font, C.Text + 1, NullUI.Theme.Text, 1)
			end
			mailboxLabel(card, tostring(item.Content or ""), NullUI.Theme.FontRegular, C.Text, NullUI.Theme.Text, 2)
			local meta = { tostring(item.Author or "Admin"), mailboxAge(item.CreatedAt) }
			if item.Edited then
				table.insert(meta, mailboxText("Edited"))
			end
			mailboxLabel(card, table.concat(meta, " \u{2022} "), NullUI.Theme.FontRegular, 10, NullUI.Theme.TextDim, 3)
		end
	end

	local function loadMailbox()
		local popup = mailboxPopup
		SafeSpawn(function()
			local ok, items = pcall(service.GetMailbox, service)
			if mailboxPopup ~= popup then
				return
			end
			if ok and type(items) == "table" then
				renderMailbox(items, false)
			else
				renderMailbox(nil, true)
			end
		end)
	end

	local function closeMailboxPopup()
		if mailboxPopup then
			mailboxPopup:Destroy()
			mailboxPopup, mailboxList = nil, nil
		end
	end

	local function openMailboxPopup()
		if not hasMailbox then
			return
		end
		if mailboxPopup then
			closeMailboxPopup()
			return
		end
		closeSettingsPopup()

		local popup = Instance.new("Frame")
		popup.Name = "ChatMailboxPopup"
		popup.BackgroundColor3 = NullUI.Theme.Surface
		popup.BackgroundTransparency = 0.03
		popup.BorderSizePixel = 0
		popup.AnchorPoint = Vector2.new(1, 0)
		popup.Position = UDim2.new(1, 0, 0, HEADER_H + 4)
		popup.Size = UDim2.new(1, 0, 1, -(HEADER_H + 8))
		popup.ZIndex = BASE_Z + 10
		popup.Parent = panel
		Corner(popup, 10)
		Stroke(popup, Color3.new(1, 1, 1), 1, 0.88)
		local popupPad = Instance.new("UIPadding")
		popupPad.PaddingTop = UDim.new(0, 10)
		popupPad.PaddingBottom = UDim.new(0, 10)
		popupPad.PaddingLeft = UDim.new(0, 12)
		popupPad.PaddingRight = UDim.new(0, 8)
		popupPad.Parent = popup

		local title = Instance.new("TextLabel")
		title.BackgroundTransparency = 1
		title.FontFace = NullUI.Theme.Font
		title.Text = mailboxText("Title")
		title.TextColor3 = NullUI.Theme.Text
		title.TextSize = 13
		title.TextXAlignment = Enum.TextXAlignment.Left
		title.Size = UDim2.new(1, -28, 0, 22)
		title.ZIndex = BASE_Z + 11
		title.Parent = popup

		local close = Instance.new("TextButton")
		close.Text = ""
		close.AutoButtonColor = false
		close.BackgroundTransparency = 1
		close.AnchorPoint = Vector2.new(1, 0)
		close.Position = UDim2.new(1, 0, 0, 0)
		close.Size = UDim2.fromOffset(22, 22)
		close.ZIndex = BASE_Z + 11
		close.Parent = popup
		local closeIc = Instance.new("ImageLabel")
		closeIc.BackgroundTransparency = 1
		closeIc.Image = ResolveIcon("x")
		closeIc.ImageColor3 = NullUI.Theme.TextDim
		closeIc.Size = UDim2.fromOffset(13, 13)
		closeIc.AnchorPoint = Vector2.new(0.5, 0.5)
		closeIc.Position = UDim2.fromScale(0.5, 0.5)
		closeIc.ZIndex = BASE_Z + 12
		closeIc.Parent = close
		close.MouseButton1Click:Connect(closeMailboxPopup)

		local list = Instance.new("ScrollingFrame")
		list.Name = "Entries"
		list.BackgroundTransparency = 1
		list.BorderSizePixel = 0
		list.Position = UDim2.fromOffset(0, 30)
		list.Size = UDim2.new(1, 0, 1, -30)
		list.CanvasSize = UDim2.new()
		list.AutomaticCanvasSize = Enum.AutomaticSize.Y
		list.ScrollBarThickness = 3
		list.ScrollBarImageTransparency = 0.6
		list.ZIndex = BASE_Z + 11
		list.Parent = popup
		local listLayout = Instance.new("UIListLayout")
		listLayout.Padding = UDim.new(0, 6)
		listLayout.SortOrder = Enum.SortOrder.LayoutOrder
		listLayout.Parent = list

		mailboxPopup, mailboxList = popup, list
		markMailboxSeen()
		renderMailbox(nil, false)
		loadMailbox()
	end

	if hasMailbox then
		jan:Add(mailboxBtn.MouseButton1Click:Connect(openMailboxPopup))
		jan:Add(mailboxNotice.MouseButton1Click:Connect(openMailboxPopup))
	end

	local function syncMailbox()
		local meta = hasMailbox and service.ChatMeta and service.ChatMeta.Mailbox
		if type(meta) ~= "table" then
			return
		end
		local latest, count = tonumber(meta.LatestId) or 0, tonumber(meta.Count) or 0
		local changed = latest ~= mailboxLatestId or count ~= mailboxCount
		mailboxLatestId, mailboxCount = latest, count
		if mailboxPopup then
			markMailboxSeen()
			if changed then
				loadMailbox()
			end
			return
		end
		local unread = latest > mailboxSeenId
		setMailboxUnread(unread)
		if unread and latest > mailboxNotifiedId then
			mailboxNotifiedId = latest
			NullUI:Notify({
				Title = mailboxText("Title"),
				Text = mailboxText("Notice"),
				Type = "info",
				Icon = "mail",
				Duration = 6,
				Actions = {
					{
						Text = mailboxText("Open"),
						Callback = function()
							if tabObj._select then
								tabObj._select()
							end
							if not mailboxPopup then
								openMailboxPopup()
							end
						end,
					},
				},
			})
		end
	end

	local notifySoundInstance = Instance.new("Sound")
	notifySoundInstance.SoundId = "rbxasset://sounds/electronicpingshort.wav"
	notifySoundInstance.Volume = 0.5
	notifySoundInstance.Parent = panel

	if service then
		SafeSpawn(function()
			local backlog = service:PollChatMessages(0)
			if backlog then
				local historyLimit = opts.HistoryLimit or 3
				local startIdx = math.max(1, #backlog - historyLimit + 1)
				for i = startIdx, #backlog do
					local m = backlog[i]
					if not seenIds[m.Id] then
						seenIds[m.Id] = true
						addBubble(m, m.UserId == LocalPlayer.UserId)
					end
					if m.Id > lastSeenId then
						lastSeenId = m.Id
					end
				end
			end
			applyMeta()
			syncAnnouncement()
			syncMailbox()
			local failures = 0
			while panel and panel.Parent do
				-- Poll at full speed only while the chat is on screen, and back off
				-- while the relay is failing instead of hammering it.
				local delay = (self._currentTab == tabObj) and pollInterval or math.max(pollInterval * 3, 8)
				if failures > 0 then
					delay = math.min(delay * 2 ^ math.min(failures, 3), 30)
				end
				local waited = 0
				while waited < delay and panel and panel.Parent do
					waited += task.wait(0.25)
					-- Opening the chat cuts a slow background wait short.
					if failures == 0 and waited >= pollInterval and self._currentTab == tabObj then
						break
					end
				end
				if not (panel and panel.Parent) then
					break
				end
				local ok, newMsgs = pcall(service.PollChatMessages, service, lastSeenId)
				newMsgs = ok and newMsgs or nil
				failures = newMsgs and 0 or failures + 1
				if newMsgs then
					applyMeta()
					syncAnnouncement()
					syncMailbox()
					local deletedIds = service.ChatMeta and service.ChatMeta.DeletedIds
					if type(deletedIds) == "table" then
						for _, id in ipairs(deletedIds) do
							local row = rowsById[id]
							if row then
								rowsById[id] = nil
								row:Destroy()
							end
						end
					end
					for _, m in ipairs(newMsgs) do
						if not seenIds[m.Id] then
							seenIds[m.Id] = true
							local isOwn = m.UserId == LocalPlayer.UserId
							addBubble(m, isOwn)

							if notifySound and not isOwn and notifySoundInstance.Parent then
								notifySoundInstance:Play()
							end
						end
						if m.Id > lastSeenId then
							lastSeenId = m.Id
						end
					end
				end
			end
		end)
	end

	if service and service.PublishChatPresence then
		SafeSpawn(function()
			-- Clear any stale sharing left by an earlier script instance.
			publishPresence()
			while panel and panel.Parent do
				task.wait(20)
				if allowJoin and panel and panel.Parent then
					publishPresence()
				end
			end
		end)
	end

	local lastRealTab = nil
	local function openPanel()
		if self._currentTab == tabObj then
			return
		end
		if self._currentTab and not self._currentTab.Hidden then
			lastRealTab = self._currentTab
		end
		tabObj._select()
	end
	local function closePanel()
		if self._currentTab ~= tabObj then
			return
		end
		if lastRealTab and not lastRealTab.Hidden then
			lastRealTab._select()
		elseif self._tabs[1] and self._tabs[1] ~= tabObj then
			self._tabs[1]._select()
		end
	end

	return {
		Instance = panel,
		Tab = tabObj,
		Open = openPanel,
		Close = closePanel,
		Toggle = function()
			if self._currentTab == tabObj then
				closePanel()
			else
				openPanel()
			end
		end,
		IsOpen = function()
			return self._currentTab == tabObj
		end,
		Destroy = function()
			if allowJoin then
				allowJoin = false
				SafeSpawn(publishPresence)
			end
			panel:Destroy()
		end,
	}
end

local TRANSITION_EXIT = 0.18
local TRANSITION_GAP = 0.08
local TRANSITION_ENTER = 0.32

function Window:AddTab(nameOrOpts)
	local opts = type(nameOrOpts) == "table" and nameOrOpts or { Name = nameOrOpts }
	local name = opts.Name or opts.Title or "Tab"
	local iconAsset = opts.Icon and ResolveIcon(opts.Icon) or nil
	local hasIcon = iconAsset ~= nil and iconAsset ~= ""
	local jan = self._janitor

	local hidden = opts.Hidden == true

	local tabButton = Instance.new("TextButton")
	tabButton.Name = name
	tabButton.Text = ""
	tabButton.AutoButtonColor = false
	tabButton.BackgroundColor3 = Color3.new(1, 1, 1)
	tabButton.BackgroundTransparency = 1
	tabButton.BorderSizePixel = 0
	tabButton.Size = UDim2.new(1, 0, 0, 34)
	tabButton.ZIndex = Z.Content
	if not hidden then
		tabButton.Parent = self._tabBar
	end
	Corner(tabButton, 10)

	local row = Instance.new("Frame")
	row.Name = "Row"
	row.BackgroundTransparency = 1
	row.Size = UDim2.fromScale(1, 1)
	row.ZIndex = Z.Content
	row.Parent = tabButton

	local rowPad = Instance.new("UIPadding")
	rowPad.PaddingLeft = UDim.new(0, 12)
	rowPad.PaddingRight = UDim.new(0, 12)
	rowPad.Parent = row

	local rowLayout = Instance.new("UIListLayout")
	rowLayout.FillDirection = Enum.FillDirection.Horizontal
	rowLayout.VerticalAlignment = Enum.VerticalAlignment.Center
	rowLayout.Padding = UDim.new(0, 10)
	rowLayout.SortOrder = Enum.SortOrder.LayoutOrder
	rowLayout.Parent = row

	local iconLabel
	if hasIcon then
		iconLabel = Instance.new("ImageLabel")
		iconLabel.Name = "Icon"
		iconLabel.BackgroundTransparency = 1
		iconLabel.Image = iconAsset
		iconLabel.ImageColor3 = NullUI.Theme.TextDim
		Role(iconLabel, "TextDim")
		iconLabel.Size = UDim2.fromOffset(16, 16)
		iconLabel.LayoutOrder = 1
		iconLabel.ZIndex = Z.Content + 1
		iconLabel.Parent = row
	end

	local textLabel = Instance.new("TextLabel")
	textLabel.Name = "Label"
	textLabel.BackgroundTransparency = 1
	textLabel.FontFace = NullUI.Theme.Font
	textLabel.Text = name
	textLabel.TextColor3 = NullUI.Theme.TextDim
	Role(textLabel, "TextDim")
	textLabel.TextSize = 14
	textLabel.TextXAlignment = Enum.TextXAlignment.Left
	textLabel.TextTruncate = Enum.TextTruncate.AtEnd
	textLabel.Size = UDim2.new(1, hasIcon and -26 or 0, 1, 0)
	textLabel.LayoutOrder = 2
	textLabel.ZIndex = Z.Content + 1
	textLabel.Parent = row

	local pageGroup = Instance.new("CanvasGroup")
	pageGroup.Name = name .. "Group"
	pageGroup.BackgroundTransparency = 1
	pageGroup.Size = UDim2.fromScale(1, 1)
	pageGroup.GroupTransparency = 0
	pageGroup.Visible = false
	pageGroup.ZIndex = Z.Content
	pageGroup.Parent = self._content

	local page = Instance.new("ScrollingFrame")
	page.Name = name .. "Page"
	page.BackgroundTransparency = 1
	page.BorderSizePixel = 0
	page.Size = UDim2.fromScale(1, 1)
	page.ScrollingDirection = Enum.ScrollingDirection.Y
	page.ScrollBarThickness = 0
	page.AutomaticCanvasSize = Enum.AutomaticSize.Y
	page.CanvasSize = UDim2.new(0, 0, 0, 0)
	page.ZIndex = Z.Content
	page.Parent = pageGroup

	local pagePad = Instance.new("UIPadding")
	pagePad.Name = "PagePadding"
	pagePad.PaddingRight = UDim.new(0, 12)
	pagePad.PaddingBottom = UDim.new(0, 6)
	pagePad.Parent = page

	local pageLayout = Instance.new("UIListLayout")
	pageLayout.Name = "PageLayout"
	pageLayout.Padding = UDim.new(0, 5)
	pageLayout.SortOrder = Enum.SortOrder.LayoutOrder
	pageLayout.Parent = page

	AddScrollbar(page)
	AddContentScrollThumb(page, pageLayout, pageGroup, jan)
	AddEmptyState(page, pageGroup, jan)

	local tabObj = setmetatable({
		Name = name,
		_page = page,
		_group = pageGroup,
		_button = tabButton,
		_icon = iconLabel,
		_label = textLabel,
		_window = self,
		_janitor = jan,
	}, Tab)

	local myIndex = #self._tabs + 1

	local function indicatorY()
		return (tabButton.AbsolutePosition.Y - self._tabBar.AbsolutePosition.Y) / GetUIScale()
	end

	local function selectTab()
		if self._currentTab == tabObj then
			return
		end

		self._tabSwitchToken = (self._tabSwitchToken or 0) + 1
		local myToken = self._tabSwitchToken

		local direction = 0
		if self._currentIndex then
			direction = (myIndex > self._currentIndex) and 1 or -1
		end
		self._currentIndex = myIndex

		local previousTab = self._currentTab
		self._currentTab = tabObj
		for _, fn in ipairs(self._tabChangeListeners) do
			SafeSpawn(fn, tabObj)
		end

		for _, t in pairs(self._tabs) do
			local isSelected = (t == tabObj)
			Tween(t._label, { TextColor3 = isSelected and NullUI.Theme.Text or NullUI.Theme.TextDim }, 0.26)
			if t._icon then
				Tween(t._icon, { ImageColor3 = isSelected and NullUI.Theme.Text or NullUI.Theme.TextDim }, 0.26)
			end
			if not isSelected then
				Tween(t._button, { BackgroundTransparency = 1 }, 0.18)
			end
		end

		if hidden then
			Tween(self._tabIndicator, { BackgroundTransparency = 1 }, 0.18)
		else
			Tween(self._tabIndicator, {
				Position = UDim2.new(0, 0, 0, indicatorY()),
				BackgroundTransparency = 0.88,
			}, 0.32, Enum.EasingStyle.Quint, Enum.EasingDirection.Out)
		end

		for _, t in pairs(self._tabs) do
			if t ~= tabObj and t ~= previousTab and t._group.Visible then
				t._group.Visible = false
			end
		end

		local function playEnter()
			if self._tabSwitchToken ~= myToken then
				return
			end
			pageGroup.Visible = true
			pageGroup.GroupTransparency = 1
			pageGroup.Position = UDim2.fromOffset(direction * 20, 0)
			Tween(pageGroup, {
				GroupTransparency = 0,
				Position = UDim2.fromOffset(0, 0),
			}, TRANSITION_ENTER, Enum.EasingStyle.Quint, Enum.EasingDirection.Out)
		end

		if previousTab and previousTab._group.Visible then
			local g = previousTab._group
			Tween(g, {
				GroupTransparency = 1,
				Position = UDim2.fromOffset(-direction * 20, 0),
			}, TRANSITION_EXIT, Enum.EasingStyle.Quint, Enum.EasingDirection.In)
			SafeDelay(TRANSITION_EXIT, function()
				if g then
					g.Visible = false
				end
				SafeDelay(TRANSITION_GAP, playEnter)
			end)
		else
			playEnter()
		end
	end

	tabObj._select = selectTab
	tabObj.Hidden = hidden

	if not hidden then
		jan:Add(tabButton:GetPropertyChangedSignal("AbsolutePosition"):Connect(function()
			LPH_ATTRIBUTES(VM(NONE))
			if self._currentTab == tabObj then
				self._tabIndicator.Position = UDim2.new(0, 0, 0, indicatorY())
			end
		end))

		jan:Add(tabButton.MouseButton1Click:Connect(selectTab))

		jan:Add(tabButton.MouseEnter:Connect(function()
			if self._currentTab ~= tabObj then
				Tween(tabButton, { BackgroundTransparency = 0.95 }, 0.18)
			end
		end))
		jan:Add(tabButton.MouseLeave:Connect(function()
			if self._currentTab ~= tabObj then
				Tween(tabButton, { BackgroundTransparency = 1 }, 0.18)
			end
		end))
	end

	table.insert(self._tabs, tabObj)
	if not hidden then
		self._visibleTabCount = (self._visibleTabCount or 0) + 1
		if self._visibleTabCount == 1 then
			selectTab()
		end
		if self._defaultTabName and name == self._defaultTabName then
			selectTab()
		end
	end

	return tabObj
end

function Window:SelectTab(nameOrIndex)
	CloseAnyOpenPopup()
	if type(nameOrIndex) == "number" then
		local t = self._tabs[nameOrIndex]
		if t then
			t._select()
		end
		return t
	end
	for _, t in ipairs(self._tabs) do
		if t.Name == nameOrIndex then
			t._select()
			return t
		end
	end
	return nil
end

function Window:_RegisterSearchable(tabObj, title, instance)
	if not title or title == "" or not instance then
		return
	end
	table.insert(self._searchIndex, { title = title, instance = instance, tabObj = tabObj })
end

-- Labels may be translated after they are registered (e.g. a hub's own
-- Vietnamese mode), so search the text shown on screen as well as the original,
-- ignoring accents so "trung" finds "trứng".
local SearchFoldMap = nil
local function FoldSearchText(text)
	if not SearchFoldMap then
		SearchFoldMap = {}
		local groups = {
			a = "àáảãạăằắẳẵặâầấẩẫậÀÁẢÃẠĂẰẮẲẴẶÂẦẤẨẪẬ",
			e = "èéẻẽẹêềếểễệÈÉẺẼẸÊỀẾỂỄỆ",
			i = "ìíỉĩịÌÍỈĨỊ",
			o = "òóỏõọôồốổỗộơờớởỡợÒÓỎÕỌÔỒỐỔỖỘƠỜỚỞỠỢ",
			u = "ùúủũụưừứửữựÙÚỦŨỤƯỪỨỬỮỰ",
			y = "ỳýỷỹỵỲÝỶỸỴ",
			d = "đĐ",
		}
		for base, chars in pairs(groups) do
			for _, code in utf8.codes(chars) do
				SearchFoldMap[code] = base
			end
		end
	end
	text = tostring(text or "")
	local out = {}
	local ok = pcall(function()
		for _, code in utf8.codes(text) do
			out[#out + 1] = SearchFoldMap[code] or utf8.char(code)
		end
	end)
	return string.lower(ok and table.concat(out) or text)
end

local function SearchShownTitle(entry)
	local shown = entry.instance and entry.instance:FindFirstChild("Title", true)
	if shown and shown:IsA("TextLabel") and shown.Text ~= "" then
		return shown.Text
	end
	return entry.title
end

local function SearchEntryMatches(entry, foldedQuery)
	if foldedQuery == "" or FoldSearchText(entry.title):find(foldedQuery, 1, true) then
		return true
	end
	local shown = SearchShownTitle(entry)
	return shown ~= entry.title and FoldSearchText(shown):find(foldedQuery, 1, true) ~= nil
end

local function SearchEntryPath(tabObj)
	if not tabObj then
		return ""
	end
	if tabObj._parentTabName then
		return tabObj._parentTabName .. " \226\128\186 " .. tabObj.Name
	end
	return tabObj.Name or ""
end

function Window:_JumpToSearchable(entry)
	local tabObj = entry.tabObj
	local inst = entry.instance
	if not tabObj or not inst or not inst.Parent then
		return
	end

	if tabObj._parentTab then
		tabObj._parentTab._select()
		tabObj._parentTab:SelectSubTab(tabObj._subTabIdx)
	elseif tabObj._select then
		tabObj._select()
	end

	SafeDelay(0.6, function()
		if not inst.Parent then
			return
		end
		local page = tabObj._page
		if not page then
			return
		end
		local targetY = math.max(0, (inst.AbsolutePosition.Y - page.AbsolutePosition.Y) + page.CanvasPosition.Y - 40)
		page.CanvasPosition = Vector2.new(page.CanvasPosition.X, targetY)

		local baseColor = inst.BackgroundColor3
		local baseBg = inst.BackgroundTransparency

		inst.BackgroundColor3 = NullUI.Theme.Accent
		Tween(inst, { BackgroundTransparency = 0.85 }, 0.32, Enum.EasingStyle.Quint, Enum.EasingDirection.Out)

		SafeDelay(0.5, function()
			if not inst.Parent then
				return
			end
			Tween(inst, { BackgroundTransparency = baseBg }, 0.7, Enum.EasingStyle.Quint, Enum.EasingDirection.InOut)
			SafeDelay(0.7, function()
				if inst.Parent then
					inst.BackgroundColor3 = baseColor
				end
			end)
		end)
	end)
end

function Window:JumpToElement(query)
	query = tostring(query or "")
	if query == "" then
		return false, "No element name given"
	end

	local q = FoldSearchText(query)
	local best, bestScore = nil, 0
	for _, entry in ipairs(self._searchIndex) do
		local title = FoldSearchText(entry.title)
		local shown = FoldSearchText(SearchShownTitle(entry))
		if title == q or shown == q then
			best, bestScore = entry, math.huge
			break
		elseif title:find(q, 1, true) or shown:find(q, 1, true) then
			local score = 1000 - math.abs(#title - #q)
			if score > bestScore then
				best, bestScore = entry, score
			end
		end
	end

	if not best then
		return false, "No element found matching '" .. query .. "'"
	end

	self:_JumpToSearchable(best)
	return true, best.title
end

function Window:_OpenSearch()
	local self_ = self
	local root = NullUI._Root
	local panelW = math.min(440, ViewportSize().X / GetUIScale() - 40)
	local HEADER_H = 50
	local MAX_RESULTS_H = 280
	local ROW_H = 40

	local open = true
	local backdrop, panel, scale
	local heartbeatConn, textConn, focusConn
	local lastMatches = {}

	local restY

	local function closeSearch()
		if not open then
			return
		end
		open = false
		RegisterPopupClose(closeSearch)
		if heartbeatConn then
			heartbeatConn:Disconnect()
			heartbeatConn = nil
		end
		if textConn then
			textConn:Disconnect()
			textConn = nil
		end
		if focusConn then
			focusConn:Disconnect()
			focusConn = nil
		end

		local b, p = backdrop, panel
		backdrop, panel = nil, nil
		if p then
			Tween(
				p,
				{ Size = UDim2.new(p.Size.X.Scale, p.Size.X.Offset, 0, 0) },
				0.32,
				Enum.EasingStyle.Quint,
				Enum.EasingDirection.In
			)
			Tween(p, { GroupTransparency = 1 }, 0.26, Enum.EasingStyle.Quint, Enum.EasingDirection.In)
		end
		if b then
			Tween(b, { BackgroundTransparency = 1 }, 0.32, Enum.EasingStyle.Quint, Enum.EasingDirection.In)
		end
		SafeDelay(0.32, function()
			if b then
				b:Destroy()
			end
			if p then
				p:Destroy()
			end
		end)
	end

	RegisterPopupOpen(closeSearch)
	backdrop = MakePopupBackdrop(closeSearch)
	backdrop.BackgroundColor3 = Color3.new(0, 0, 0)
	Tween(backdrop, { BackgroundTransparency = 0.4 }, 0.32, Enum.EasingStyle.Quint, Enum.EasingDirection.Out)

	panel = Instance.new("CanvasGroup")
	panel.Name = "SearchPalette"
	panel.AnchorPoint = Vector2.new(0.5, 0.5)
	do
		local cx, cy = ComputeDialogCenter(self_._gui)
		local s = GetUIScale()
		local px, py = math.round(cx / s), math.round(cy / s)
		restY = py
		panel.Position = UDim2.fromOffset(px, py - 18)
	end
	panel.Size = UDim2.new(0, panelW, 0, HEADER_H)
	panel.BackgroundColor3 = NullUI.Theme.Background
	panel.BackgroundTransparency = 0.05
	panel.GroupTransparency = 1
	panel.BorderSizePixel = 0
	panel.ClipsDescendants = true
	panel.ZIndex = Z.Modal
	panel.Parent = root
	Corner(panel, 14)
	Stroke(panel, Color3.new(1, 1, 1), 1, 0.8)
	GlassLayer(panel, 14, 0.985)

	scale = Instance.new("UIScale")
	scale.Scale = 0.94
	scale.Parent = panel

	local searchIcon = Instance.new("ImageLabel")
	searchIcon.BackgroundTransparency = 1
	searchIcon.Image = ResolveIcon("search")
	searchIcon.ImageColor3 = NullUI.Theme.TextDim
	Role(searchIcon, "TextDim")
	searchIcon.Size = UDim2.fromOffset(16, 16)
	searchIcon.AnchorPoint = Vector2.new(0, 0.5)
	searchIcon.Position = UDim2.new(0, 16, 0, HEADER_H / 2)
	searchIcon.ZIndex = Z.Modal + 2
	searchIcon.Parent = panel

	local closeBtn = Instance.new("TextButton")
	closeBtn.Name = "CloseButton"
	closeBtn.Text = ""
	closeBtn.AutoButtonColor = false
	closeBtn.BackgroundColor3 = Color3.new(1, 1, 1)
	closeBtn.BackgroundTransparency = 1
	closeBtn.BorderSizePixel = 0
	closeBtn.AnchorPoint = Vector2.new(1, 0.5)
	closeBtn.Size = UDim2.fromOffset(24, 24)
	closeBtn.Position = UDim2.new(1, -10, 0, HEADER_H / 2)
	closeBtn.ZIndex = Z.Modal + 2
	closeBtn.Parent = panel
	Corner(closeBtn, 7)

	local closeIcon = Instance.new("ImageLabel")
	closeIcon.BackgroundTransparency = 1
	closeIcon.Image = ResolveIcon("x")
	closeIcon.ImageColor3 = NullUI.Theme.TextDim
	Role(closeIcon, "TextDim")
	closeIcon.Size = UDim2.fromOffset(12, 12)
	closeIcon.AnchorPoint = Vector2.new(0.5, 0.5)
	closeIcon.Position = UDim2.fromScale(0.5, 0.5)
	closeIcon.ZIndex = Z.Modal + 3
	closeIcon.Parent = closeBtn

	closeBtn.MouseEnter:Connect(function()
		Tween(closeBtn, { BackgroundTransparency = 0.9 }, 0.12)
		Tween(closeIcon, { ImageColor3 = NullUI.Theme.Text }, 0.12)
	end)
	closeBtn.MouseLeave:Connect(function()
		Tween(closeBtn, { BackgroundTransparency = 1 }, 0.12)
		Tween(closeIcon, { ImageColor3 = NullUI.Theme.TextDim }, 0.12)
	end)
	closeBtn.MouseButton1Click:Connect(closeSearch)

	local box = Instance.new("TextBox")
	box.Name = "SearchBox"
	box.BackgroundTransparency = 1
	box.FontFace = NullUI.Theme.FontRegular
	box.PlaceholderText = "Search everything..."
	box.Text = ""
	box.TextColor3 = NullUI.Theme.Text
	Role(box, "Text")
	box.PlaceholderColor3 = NullUI.Theme.TextDim
	box.TextSize = 15
	box.ClearTextOnFocus = false
	box.TextXAlignment = Enum.TextXAlignment.Left
	box.Position = UDim2.new(0, 40, 0, 0)
	box.Size = UDim2.new(1, -78, 0, HEADER_H)
	box.ZIndex = Z.Modal + 2
	box.Parent = panel

	local divider = Instance.new("Frame")
	divider.Name = "Divider"
	divider.BackgroundColor3 = Color3.new(1, 1, 1)
	divider.BackgroundTransparency = 0.92
	divider.BorderSizePixel = 0
	divider.Position = UDim2.new(0, 0, 0, HEADER_H)
	divider.Size = UDim2.new(1, 0, 0, 1)
	divider.Visible = false
	divider.ZIndex = Z.Modal + 1
	divider.Parent = panel

	local resultsHolder = Instance.new("ScrollingFrame")
	resultsHolder.Name = "Results"
	resultsHolder.BackgroundTransparency = 1
	resultsHolder.BorderSizePixel = 0
	resultsHolder.Position = UDim2.new(0, 0, 0, HEADER_H + 1)
	resultsHolder.Size = UDim2.new(1, 0, 0, 0)
	resultsHolder.Visible = false
	resultsHolder.ScrollingDirection = Enum.ScrollingDirection.Y
	resultsHolder.ScrollBarThickness = 0
	resultsHolder.AutomaticCanvasSize = Enum.AutomaticSize.Y
	resultsHolder.CanvasSize = UDim2.new(0, 0, 0, 0)
	resultsHolder.ZIndex = Z.Modal + 1
	resultsHolder.Parent = panel

	local resultsPad = Instance.new("UIPadding")
	resultsPad.PaddingTop = UDim.new(0, 6)
	resultsPad.PaddingBottom = UDim.new(0, 6)
	resultsPad.PaddingLeft = UDim.new(0, 6)
	resultsPad.PaddingRight = UDim.new(0, 16)
	resultsPad.Parent = resultsHolder

	local resultsLayout = Instance.new("UIListLayout")
	resultsLayout.Padding = UDim.new(0, 2)
	resultsLayout.SortOrder = Enum.SortOrder.LayoutOrder
	resultsLayout.Parent = resultsHolder

	AddScrollbar(resultsHolder)
	AddContentScrollThumb(resultsHolder, resultsLayout, panel, {
		Add = function(_, conn)
			heartbeatConn = conn
		end,
	})

	local emptyLabel = Instance.new("TextLabel")
	emptyLabel.BackgroundTransparency = 1
	emptyLabel.FontFace = NullUI.Theme.FontRegular
	emptyLabel.Text = "No results"
	emptyLabel.TextColor3 = NullUI.Theme.TextDim
	Role(emptyLabel, "TextDim")
	emptyLabel.TextSize = 13
	emptyLabel.Visible = false
	emptyLabel.Position = UDim2.new(0, 0, 0, HEADER_H + 9)
	emptyLabel.Size = UDim2.new(1, 0, 0, 26)
	emptyLabel.ZIndex = Z.Modal + 1
	emptyLabel.Parent = panel

	local function activate(entry)
		closeSearch()
		self_:_JumpToSearchable(entry)
	end

	local function rebuild(query)
		for _, child in ipairs(resultsHolder:GetChildren()) do
			if child:IsA("TextButton") then
				child:Destroy()
			end
		end

		local q = FoldSearchText(query:match("^%s*(.-)%s*$"))
		local matches = {}
		for _, entry in ipairs(self_._searchIndex) do
			if entry.instance and entry.instance.Parent then
				if SearchEntryMatches(entry, q) then
					table.insert(matches, entry)
					if #matches >= 15 then
						break
					end
				end
			end
		end
		lastMatches = matches

		local showEmpty = (#matches == 0 and q ~= "")
		emptyLabel.Visible = showEmpty
		resultsHolder.Visible = (#matches > 0)
		divider.Visible = (#matches > 0) or showEmpty

		for i, entry in ipairs(matches) do
			local row = Instance.new("TextButton")
			row.Text = ""
			row.AutoButtonColor = false
			row.BackgroundColor3 = Color3.new(1, 1, 1)
			row.BackgroundTransparency = 1
			row.BorderSizePixel = 0
			row.Size = UDim2.new(1, 0, 0, ROW_H)
			row.LayoutOrder = i
			row.ZIndex = Z.Modal + 2
			row.Parent = resultsHolder
			Corner(row, 8)

			local titleLbl = Instance.new("TextLabel")
			titleLbl.BackgroundTransparency = 1
			titleLbl.FontFace = NullUI.Theme.Font
			titleLbl.Text = SearchShownTitle(entry)
			titleLbl.TextColor3 = NullUI.Theme.Text
			Role(titleLbl, "Text")
			titleLbl.TextSize = 13
			titleLbl.TextXAlignment = Enum.TextXAlignment.Left
			titleLbl.TextTruncate = Enum.TextTruncate.AtEnd
			titleLbl.Position = UDim2.fromOffset(12, 5)
			titleLbl.Size = UDim2.new(1, -24, 0, 16)
			titleLbl.ZIndex = Z.Modal + 3
			titleLbl.Parent = row

			local pathLbl = Instance.new("TextLabel")
			pathLbl.BackgroundTransparency = 1
			pathLbl.FontFace = NullUI.Theme.FontRegular
			pathLbl.Text = SearchEntryPath(entry.tabObj)
			pathLbl.TextColor3 = NullUI.Theme.TextDim
			Role(pathLbl, "TextDim")
			pathLbl.TextSize = 11
			pathLbl.TextXAlignment = Enum.TextXAlignment.Left
			pathLbl.TextTruncate = Enum.TextTruncate.AtEnd
			pathLbl.Position = UDim2.fromOffset(12, 21)
			pathLbl.Size = UDim2.new(1, -24, 0, 12)
			pathLbl.ZIndex = Z.Modal + 3
			pathLbl.Parent = row

			row.MouseEnter:Connect(function()
				Tween(row, { BackgroundTransparency = 0.92 }, 0.12)
			end)
			row.MouseLeave:Connect(function()
				Tween(row, { BackgroundTransparency = 1 }, 0.12)
			end)
			row.MouseButton1Click:Connect(function()
				activate(entry)
			end)
		end

		local resultsH = math.min(#matches * (ROW_H + 2), MAX_RESULTS_H)

		local extraH = 0
		if resultsH > 0 then
			extraH = resultsH + 1
		elseif showEmpty then
			extraH = 36
		end

		Tween(
			resultsHolder,
			{ Size = UDim2.new(1, 0, 0, resultsH) },
			0.32,
			Enum.EasingStyle.Quint,
			Enum.EasingDirection.InOut
		)
		Tween(
			panel,
			{ Size = UDim2.new(0, panelW, 0, HEADER_H + extraH) },
			0.32,
			Enum.EasingStyle.Quint,
			Enum.EasingDirection.InOut
		)
	end

	local rebuildToken = 0
	textConn = box:GetPropertyChangedSignal("Text"):Connect(function()
		rebuildToken = rebuildToken + 1
		local myToken = rebuildToken
		local text = box.Text
		SafeDelay(0.12, function()
			if rebuildToken == myToken and box.Parent then
				rebuild(text)
			end
		end)
	end)

	focusConn = box.FocusLost:Connect(function(enterPressed)
		if enterPressed and lastMatches[1] then
			activate(lastMatches[1])
		end
	end)

	rebuild("")

	scale.Scale = 0.94
	Tween(panel, {
		GroupTransparency = 0,
		Position = UDim2.fromOffset(panel.Position.X.Offset, restY),
	}, 0.32, Enum.EasingStyle.Quint, Enum.EasingDirection.Out)
	Tween(scale, { Scale = 1 }, 0.32, Enum.EasingStyle.Quint, Enum.EasingDirection.Out)

	SafeDefer(function()
		if box.Parent then
			box:CaptureFocus()
		end
	end)
end

local SUBTAB_EXIT = 0.18
local SUBTAB_GAP = 0.08
local SUBTAB_ENTER = 0.30

function Tab:AddSubTab(nameOrOpts)
	local opts = type(nameOrOpts) == "table" and nameOrOpts or { Name = nameOrOpts }
	local title = opts.Name or "SubTab"
	local iconAsset = opts.Icon and ResolveIcon(opts.Icon) or nil
	local jan = self._janitor

	self._subTabCount = (self._subTabCount or 0) + 1
	local idx = self._subTabCount

	if not self._subTabHolder then
		local page = self._page
		page.ScrollingEnabled = false
		page.AutomaticCanvasSize = Enum.AutomaticSize.None
		page.CanvasSize = UDim2.new(0, 0, 0, 0)

		local pl = page:FindFirstChildOfClass("UIListLayout")
		if pl then
			pl:Destroy()
		end
		local pp = page:FindFirstChildOfClass("UIPadding")
		if pp then
			pp:Destroy()
		end
		local oldTrack = page:FindFirstChild("ScrollTrack")
		if oldTrack then
			oldTrack:Destroy()
		end

		self._subTabHolder = Instance.new("ScrollingFrame")
		self._subTabHolder.Name = "SubTabBar"
		self._subTabHolder.Size = UDim2.new(1, -12, 0, 40)
		self._subTabHolder.Position = UDim2.fromOffset(2, 6)
		self._subTabHolder.BackgroundTransparency = 1
		self._subTabHolder.BorderSizePixel = 0
		self._subTabHolder.ScrollingDirection = Enum.ScrollingDirection.X
		self._subTabHolder.ScrollBarThickness = 0
		self._subTabHolder.AutomaticCanvasSize = Enum.AutomaticSize.X
		self._subTabHolder.CanvasSize = UDim2.new(0, 0, 0, 40)
		self._subTabHolder.ZIndex = Z.Content
		self._subTabHolder.Parent = page
		AddScrollbar(self._subTabHolder)

		self._subTabIndicatorLayer = Instance.new("Frame")
		self._subTabIndicatorLayer.Name = "SubTabIndicatorLayer"
		self._subTabIndicatorLayer.BackgroundTransparency = 1
		self._subTabIndicatorLayer.ClipsDescendants = true
		self._subTabIndicatorLayer.ZIndex = Z.Window
		self._subTabIndicatorLayer.Position = self._subTabHolder.Position
		self._subTabIndicatorLayer.Size = self._subTabHolder.Size
		self._subTabIndicatorLayer.Parent = page

		self._subTabIndicator = Instance.new("Frame")
		self._subTabIndicator.Name = "Indicator"
		self._subTabIndicator.BackgroundColor3 = Color3.new(1, 1, 1)
		self._subTabIndicator.BackgroundTransparency = 1
		self._subTabIndicator.BorderSizePixel = 0
		self._subTabIndicator.ZIndex = Z.Window
		self._subTabIndicator.Size = UDim2.fromOffset(0, 32)
		self._subTabIndicator.Position = UDim2.fromOffset(0, 4)
		self._subTabIndicator.Parent = self._subTabIndicatorLayer
		Corner(self._subTabIndicator, 8)

		local sl = Instance.new("UIListLayout")
		sl.FillDirection = Enum.FillDirection.Horizontal
		sl.VerticalAlignment = Enum.VerticalAlignment.Center
		sl.Padding = UDim.new(0, 6)
		sl.SortOrder = Enum.SortOrder.LayoutOrder
		sl.Parent = self._subTabHolder

		self._subTabBody = Instance.new("Frame")
		self._subTabBody.Name = "SubTabBody"
		self._subTabBody.Size = UDim2.new(1, -4, 1, -62)
		self._subTabBody.Position = UDim2.fromOffset(2, 56)
		self._subTabBody.BackgroundTransparency = 1
		self._subTabBody.BorderSizePixel = 0
		self._subTabBody.ClipsDescendants = true
		self._subTabBody.ZIndex = Z.Content
		self._subTabBody.Parent = page

		self._subTabScrollTrack = Instance.new("Frame")
		self._subTabScrollTrack.Name = "SubTabScrollTrack"
		self._subTabScrollTrack.BackgroundColor3 = NullUI.Theme.TextDim
		self._subTabScrollTrack.BackgroundTransparency = 1
		self._subTabScrollTrack.BorderSizePixel = 0
		self._subTabScrollTrack.Position = UDim2.new(0, 2, 0, 48)
		self._subTabScrollTrack.Size = UDim2.new(1, -12, 0, 3)
		self._subTabScrollTrack.Visible = false
		self._subTabScrollTrack.ZIndex = Z.Content
		self._subTabScrollTrack.Parent = page
		Corner(self._subTabScrollTrack, 2)

		self._subTabScrollThumb = Instance.new("Frame")
		self._subTabScrollThumb.Name = "Thumb"
		self._subTabScrollThumb.BackgroundColor3 = NullUI.Theme.TextDim
		self._subTabScrollThumb.BackgroundTransparency = 1
		self._subTabScrollThumb.BorderSizePixel = 0
		self._subTabScrollThumb.Size = UDim2.new(0, 40, 1, 0)
		self._subTabScrollThumb.ZIndex = Z.Content + 1
		self._subTabScrollThumb.Parent = self._subTabScrollTrack
		Corner(self._subTabScrollThumb, 2)

		function self._updateSubTabScrollbar()
			LPH_ATTRIBUTES(VM(NONE))
			local holder = self._subTabHolder
			local track = self._subTabScrollTrack
			if not holder or not track then
				return
			end
			if not self._group or not self._group.Visible then
				track.Visible = false
				return
			end
			local windowW = holder.AbsoluteWindowSize.X
			local canvasW = holder.AbsoluteCanvasSize.X
			local overflow = canvasW - windowW
			if overflow <= 1 or windowW <= 0 then
				track.Visible = false
				return
			end
			track.Visible = false
			local trackW = track.AbsoluteSize.X
			if trackW <= 0 then
				return
			end
			local thumbW = math.min(trackW, math.max(30, trackW * (windowW / canvasW)))
			local maxThumbX = trackW - thumbW
			local ratio = math.clamp(holder.CanvasPosition.X / overflow, 0, 1)
			self._subTabScrollThumb.Size = UDim2.new(thumbW / trackW, 0, 1, 0)
			self._subTabScrollThumb.Position = UDim2.new((maxThumbX / trackW) * ratio, 0, 0, 0)
		end

		do
			local holder = self._subTabHolder
			local queued = false
			local function queueSubTabScrollbar()
				if queued then
					return
				end
				queued = true
				SafeDefer(function()
					queued = false
					if self._updateSubTabScrollbar then
						self._updateSubTabScrollbar()
					end
				end)
			end
			jan:Add(holder:GetPropertyChangedSignal("CanvasPosition"):Connect(queueSubTabScrollbar))
			jan:Add(holder:GetPropertyChangedSignal("AbsoluteCanvasSize"):Connect(queueSubTabScrollbar))
			jan:Add(holder:GetPropertyChangedSignal("AbsoluteWindowSize"):Connect(queueSubTabScrollbar))
			jan:Add(self._subTabScrollTrack:GetPropertyChangedSignal("AbsoluteSize"):Connect(queueSubTabScrollbar))
			if self._group then
				jan:Add(self._group:GetPropertyChangedSignal("Visible"):Connect(queueSubTabScrollbar))
			end
			queueSubTabScrollbar()
		end

		self._subTabs = {}

		function self._syncSubIndicator(animated)
			local sel = self._subTabs and self._subTabs[self.SelectedSubTab]
			if not sel or not sel.Button.Parent then
				return
			end
			local holder = self._subTabHolder
			local s = GetUIScale()
			local relX = (sel.Button.AbsolutePosition.X - holder.AbsolutePosition.X) / s
			local w = sel.Button.AbsoluteSize.X / s
			if w <= 0 then
				return
			end
			local goal = {
				Position = UDim2.fromOffset(math.round(relX), 4),
				Size = UDim2.fromOffset(math.round(w), 32),
				BackgroundTransparency = 0.86,
			}
			if animated then
				Tween(self._subTabIndicator, goal, 0.32, Enum.EasingStyle.Quint, Enum.EasingDirection.Out)
			else
				self._subTabIndicator.Position = goal.Position
				self._subTabIndicator.Size = goal.Size
				self._subTabIndicator.BackgroundTransparency = goal.BackgroundTransparency
			end
		end

		jan:Add(self._subTabHolder:GetPropertyChangedSignal("CanvasPosition"):Connect(function()
			LPH_ATTRIBUTES(VM(NONE))
			self._syncSubIndicator(false)
			self._updateSubTabScrollbar()
		end))
	end

	local btn = Instance.new("TextButton")
	btn.Name = "SubTab_" .. title:gsub("%s", "")
	btn.Text = ""
	btn.AutoButtonColor = false
	btn.BackgroundColor3 = Color3.new(1, 1, 1)
	btn.BackgroundTransparency = 1
	btn.BorderSizePixel = 0
	btn.AutomaticSize = Enum.AutomaticSize.X
	btn.Size = UDim2.fromOffset(0, 32)
	btn.LayoutOrder = idx
	btn.ZIndex = Z.Content
	btn.Parent = self._subTabHolder
	Corner(btn, 8)

	local bl = Instance.new("UIListLayout")
	bl.FillDirection = Enum.FillDirection.Horizontal
	bl.VerticalAlignment = Enum.VerticalAlignment.Center
	bl.SortOrder = Enum.SortOrder.LayoutOrder
	bl.Padding = UDim.new(0, 6)
	bl.Parent = btn

	local bpad = Instance.new("UIPadding")
	bpad.PaddingLeft = UDim.new(0, 12)
	bpad.PaddingRight = UDim.new(0, 12)
	bpad.Parent = btn

	local ic = nil
	if iconAsset and iconAsset ~= "" then
		ic = Instance.new("ImageLabel")
		ic.BackgroundTransparency = 1
		ic.Image = iconAsset
		ic.ImageColor3 = NullUI.Theme.TextDim
		Role(ic, "TextDim")
		ic.Size = UDim2.fromOffset(16, 16)
		ic.LayoutOrder = 1
		ic.ZIndex = Z.Content + 1
		ic.Parent = btn
	end

	local lbl = Instance.new("TextLabel")
	lbl.BackgroundTransparency = 1
	lbl.FontFace = NullUI.Theme.Font
	lbl.Text = title
	lbl.TextColor3 = NullUI.Theme.TextDim
	Role(lbl, "TextDim")
	lbl.TextSize = 13
	lbl.TextXAlignment = Enum.TextXAlignment.Center
	lbl.TextYAlignment = Enum.TextYAlignment.Center
	lbl.Size = UDim2.new(0, 0, 0, 32)
	lbl.AutomaticSize = Enum.AutomaticSize.X
	lbl.LayoutOrder = 2
	lbl.ZIndex = Z.Content + 1
	lbl.Parent = btn

	local group = Instance.new("Frame")
	group.Name = title .. "Group"
	group.Size = UDim2.fromScale(1, 1)
	group.BackgroundTransparency = 1
	group.Visible = false
	group.ZIndex = Z.Content
	group.Parent = self._subTabBody

	local container = Instance.new("ScrollingFrame")
	container.Name = title .. "Page"
	container.Size = UDim2.fromScale(1, 1)
	container.BackgroundTransparency = 1
	container.BorderSizePixel = 0
	container.ScrollingDirection = Enum.ScrollingDirection.Y
	container.ScrollBarThickness = 0
	container.AutomaticCanvasSize = Enum.AutomaticSize.Y
	container.CanvasSize = UDim2.new(0, 0, 0, 0)
	container.ZIndex = Z.Content
	container.Parent = group

	local cpad = Instance.new("UIPadding")
	cpad.Name = "PagePadding"
	cpad.PaddingRight = UDim.new(0, 12)
	cpad.PaddingBottom = UDim.new(0, 6)
	cpad.Parent = container

	local clayout = Instance.new("UIListLayout")
	clayout.Name = "PageLayout"
	clayout.Padding = UDim.new(0, 8)
	clayout.SortOrder = Enum.SortOrder.LayoutOrder
	clayout.Parent = container

	AddScrollbar(container)
	AddContentScrollThumb(container, clayout, group, jan)
	AddEmptyState(container, group, jan)

	local sub = setmetatable({
		Name = title,
		_page = container,
		_window = self._window,
		_janitor = jan,
		_parentTab = self,
		_parentTabName = self.Name,
		_subTabIdx = idx,
		Button = btn,
		Label = lbl,
		Icon = ic,
		Container = container,
		Group = group,
		Selected = false,
	}, Tab)

	self._subTabs[idx] = sub

	jan:Add(btn:GetPropertyChangedSignal("AbsolutePosition"):Connect(function()
		LPH_ATTRIBUTES(VM(NONE))
		if self.SelectedSubTab == idx then
			self._syncSubIndicator(false)
		end
	end))
	jan:Add(btn:GetPropertyChangedSignal("AbsoluteSize"):Connect(function()
		LPH_ATTRIBUTES(VM(NONE))
		if self.SelectedSubTab == idx then
			self._syncSubIndicator(false)
		end
	end))

	jan:Add(btn.MouseEnter:Connect(function()
		if idx ~= self.SelectedSubTab then
			Tween(btn, { BackgroundTransparency = 0.94 }, 0.18)
		end
	end))
	jan:Add(btn.MouseLeave:Connect(function()
		if idx ~= self.SelectedSubTab then
			Tween(btn, { BackgroundTransparency = 1 }, 0.18)
		end
	end))

	local downPos = nil
	jan:Add(btn.InputBegan:Connect(function(input)
		if
			input.UserInputType == Enum.UserInputType.MouseButton1
			or input.UserInputType == Enum.UserInputType.Touch
		then
			downPos = input.Position
		end
	end))
	jan:Add(btn.InputEnded:Connect(function(input)
		if
			(input.UserInputType == Enum.UserInputType.MouseButton1 or input.UserInputType == Enum.UserInputType.Touch)
			and downPos
		then
			if (input.Position - downPos).Magnitude < DRAG_THRESHOLD then
				self:SelectSubTab(idx)
			end
			downPos = nil
		end
	end))

	if not self.SelectedSubTab then
		self:SelectSubTab(idx)
	end

	return sub
end

function Tab:SelectSubTab(idx)
	if not self._subTabs then
		return
	end
	local previous = self.SelectedSubTab
	if previous == idx then
		return
	end

	self._subTabSwitchToken = (self._subTabSwitchToken or 0) + 1
	local myToken = self._subTabSwitchToken

	local direction = 0
	if previous then
		direction = (idx > previous) and 1 or -1
	end

	self.SelectedSubTab = idx
	local target = self._subTabs[idx]
	local previousSub = previous and self._subTabs[previous]
	if not target then
		return
	end

	self._syncSubIndicator(previous ~= nil)

	for i, st in pairs(self._subTabs) do
		local sel = (i == idx)
		st.Selected = sel
		if not sel then
			Tween(st.Button, { BackgroundTransparency = 1 }, 0.18)
		end
		Tween(st.Label, { TextColor3 = sel and NullUI.Theme.Text or NullUI.Theme.TextDim }, 0.26)
		if st.Icon then
			Tween(st.Icon, { ImageColor3 = sel and NullUI.Theme.Text or NullUI.Theme.TextDim }, 0.26)
		end
	end

	for _, st in pairs(self._subTabs) do
		if st ~= target and st ~= previousSub and st.Group.Visible then
			st.Group.Visible = false
		end
	end

	local function playEnter()
		if self._subTabSwitchToken ~= myToken then
			return
		end
		target.Group.Visible = true
		target.Group.Position = UDim2.fromOffset(direction * 20, 0)
		Tween(target.Group, {
			Position = UDim2.fromOffset(0, 0),
		}, SUBTAB_ENTER, Enum.EasingStyle.Quint, Enum.EasingDirection.Out)
	end

	if previousSub and previousSub.Group.Visible then
		local g = previousSub.Group
		Tween(g, {
			Position = UDim2.fromOffset(-direction * 20, 0),
		}, SUBTAB_EXIT, Enum.EasingStyle.Quint, Enum.EasingDirection.In)
		SafeDelay(SUBTAB_EXIT, function()
			if g then
				g.Visible = false
			end
			SafeDelay(SUBTAB_GAP, playEnter)
		end)
	else
		playEnter()
	end
end

function Tab:SelectSubTabByName(name)
	if not self._subTabs then
		return nil
	end
	for idx, st in pairs(self._subTabs) do
		if st.Name == name then
			self:SelectSubTab(idx)
			return st
		end
	end
	return nil
end

local function AttachLockApi(api, opts)
	local card = api.Instance
	if not card or not card:IsA("GuiObject") then
		return api
	end

	local state = {
		locked = false,
		reason = nil,
		overlay = nil,
		badge = nil,
		lock = nil,
		conn = nil,
	}
	api._lockState = state

	local function buildOverlay()
		if state.overlay then
			return
		end

		local blocker = Instance.new("TextButton")
		blocker.Name = "LockOverlay"
		blocker.Text = ""
		blocker.AutoButtonColor = false
		blocker.BackgroundColor3 = NullUI.Theme.Background
		blocker.BackgroundTransparency = 0.45
		blocker.BorderSizePixel = 0
		blocker.Size = UDim2.fromScale(1, 1)
		blocker.ZIndex = (card.ZIndex or 0) + 20
		blocker.Parent = card
		Corner(blocker, NullUI.Theme.CornerRadiusSm)

		local badge = Instance.new("ImageLabel")
		badge.Name = "LockBadge"
		badge.BackgroundTransparency = 1
		badge.Image = ResolveIcon("lock")
		badge.ImageColor3 = NullUI.Theme.TextDim
		Role(badge, "TextDim")
		badge.AnchorPoint = Vector2.new(0.5, 0.5)
		badge.Position = UDim2.new(0.5, 0, 0.5, 0)
		badge.Size = UDim2.fromOffset(17, 17)
		badge.ZIndex = blocker.ZIndex + 1
		badge.Parent = blocker

		blocker.MouseButton1Click:Connect(function()
			NullUI:Notify({
				Title = api.Label or "Locked",
				Text = state.reason or "This feature is locked.",
				Type = "warning",
				Icon = "lock",
				Duration = 3,
			})
			local baseX = card.Position.X.Offset
			for index, dx in ipairs({ 4, -3, 2, 0 }) do
				SafeDelay(index * 0.05, function()
					if blocker.Parent then
						Tween(card, {
							Position = UDim2.new(
								card.Position.X.Scale,
								baseX + dx,
								card.Position.Y.Scale,
								card.Position.Y.Offset
							),
						}, 0.08)
					end
				end)
			end
		end)

		blocker.MouseEnter:Connect(function()
			Tween(badge, { ImageColor3 = NullUI.Theme.Text }, 0.12)
		end)
		blocker.MouseLeave:Connect(function()
			Tween(badge, { ImageColor3 = NullUI.Theme.TextDim }, 0.12)
		end)

		state.overlay = blocker
		state.badge = badge
	end

	function api:SetLocked(locked, reason)
		locked = locked and true or false
		state.reason = reason or state.reason
		if state.locked == locked then
			if state.overlay and locked then
				state.overlay.Visible = true
			end
			return self
		end
		state.locked = locked
		if locked then
			buildOverlay()
			state.overlay.Visible = true
			state.overlay.BackgroundTransparency = 1
			Tween(state.overlay, { BackgroundTransparency = 0.45 }, 0.18)
		elseif state.overlay then
			local overlay = state.overlay
			Tween(overlay, { BackgroundTransparency = 1 }, 0.18)
			SafeDelay(0.18, function()
				if overlay.Parent and not state.locked then
					overlay.Visible = false
				end
			end)
		end
		return self
	end

	function api:Lock(reason)
		return self:SetLocked(true, reason)
	end

	function api:Unlock()
		return self:SetLocked(false)
	end

	function api:IsLocked()
		return state.locked
	end

	function api:BindLock(lock)
		if type(lock) ~= "table" or type(lock.Subscribe) ~= "function" then
			return self
		end
		if state.conn then
			pcall(function()
				state.conn:Disconnect()
			end)
		end
		state.lock = lock
		state.conn = lock:Subscribe(function(unlocked, reason)
			api:SetLocked(not unlocked, reason)
		end)
		api:SetLocked(not lock:IsUnlocked(), lock:GetReason())
		return self
	end

	if opts then
		if opts.Lock then
			api:BindLock(opts.Lock)
		elseif opts.Locked then
			api:Lock(opts.LockReason)
		end
	end

	return api
end

local function RegisterFlag(opts, api, kind)
	if opts.Flag then
		NullUI.Flags[opts.Flag] = api
		api.Flag = opts.Flag
		api.Kind = kind
		api.Label = opts.Text or opts.Label or opts.Flag
	end
	AttachLockApi(api, opts)
	return api
end

function Tab:AddLabel(text)
	local label = Instance.new("TextLabel")
	label.BackgroundTransparency = 1
	label.FontFace = NullUI.Theme.FontRegular
	label.Text = text
	label.TextColor3 = NullUI.Theme.TextDim
	Role(label, "TextDim")
	label.TextSize = 13
	label.TextWrapped = true
	label.TextXAlignment = Enum.TextXAlignment.Left
	label.AutomaticSize = Enum.AutomaticSize.Y
	label.Size = UDim2.new(1, 0, 0, 16)
	label.ZIndex = Z.Content
	label.Parent = self._page

	return {
		Instance = label,
		Set = function(_, v)
			label.Text = v
		end,
		Get = function()
			return label.Text
		end,
		Destroy = function()
			label:Destroy()
		end,
	}
end

function Tab:AddSection(textOrOpts, maybeIcon)
	local opts = type(textOrOpts) == "table" and textOrOpts or { Text = textOrOpts, Icon = maybeIcon }
	local text = tostring(opts.Text or "Section")
	local iconAsset = opts.Icon and ResolveIcon(opts.Icon) or ""

	local holder = Instance.new("Frame")
	holder.Name = "Section"
	holder.BackgroundTransparency = 1
	holder.Size = UDim2.new(1, 0, 0, 34)
	holder.ZIndex = Z.Content
	holder.Parent = self._page

	local row = Instance.new("Frame")
	row.Name = "Row"
	row.BackgroundTransparency = 1
	row.AnchorPoint = Vector2.new(0.5, 0.5)
	row.Position = UDim2.fromScale(0.5, 0.5)
	row.AutomaticSize = Enum.AutomaticSize.X
	row.Size = UDim2.fromOffset(0, 22)
	row.ZIndex = Z.Content
	row.Parent = holder

	local rowLayout = Instance.new("UIListLayout")
	rowLayout.FillDirection = Enum.FillDirection.Horizontal
	rowLayout.HorizontalAlignment = Enum.HorizontalAlignment.Center
	rowLayout.VerticalAlignment = Enum.VerticalAlignment.Center
	rowLayout.SortOrder = Enum.SortOrder.LayoutOrder
	rowLayout.Padding = UDim.new(0, 8)
	rowLayout.Parent = row

	local function makeLine(name, order, flip)
		local line = Instance.new("Frame")
		line.Name = name
		line.LayoutOrder = order
		line.BackgroundColor3 = NullUI.Theme.Accent
		line.BackgroundTransparency = 0
		line.BorderSizePixel = 0
		line.Size = UDim2.fromOffset(28, 2)
		line.ZIndex = Z.Content
		line.Parent = row
		Role(line, "Accent")
		Corner(line, 1)
		local fade = Instance.new("UIGradient")
		fade.Transparency = NumberSequence.new(flip and {
			NumberSequenceKeypoint.new(0, 0.85),
			NumberSequenceKeypoint.new(1, 0.15),
		} or {
			NumberSequenceKeypoint.new(0, 0.15),
			NumberSequenceKeypoint.new(1, 0.85),
		})
		fade.Parent = line
		return line
	end

	makeLine("LineLeft", 1, true)

	if iconAsset ~= "" then
		local img = Instance.new("ImageLabel")
		img.Name = "Icon"
		img.LayoutOrder = 2
		img.BackgroundTransparency = 1
		img.Image = iconAsset
		img.ImageColor3 = NullUI.Theme.Accent
		Role(img, "Accent")
		img.Size = UDim2.fromOffset(16, 16)
		img.ZIndex = Z.Content + 1
		img.Parent = row
	end

	local label = Instance.new("TextLabel")
	label.Name = "Label"
	label.LayoutOrder = 3
	label.BackgroundTransparency = 1
	local okSectionFont, sectionFont = pcall(Font.fromName, "Nunito", Enum.FontWeight.Bold, Enum.FontStyle.Normal)
	label.FontFace = okSectionFont and sectionFont or NullUI.Theme.Font
	label.Text = text
	label.TextColor3 = NullUI.Theme.Text
	Role(label, "Text")
	label.TextSize = 15
	label.AutomaticSize = Enum.AutomaticSize.X
	label.Size = UDim2.fromOffset(0, 20)
	label.ZIndex = Z.Content + 1
	label.Parent = row

	makeLine("LineRight", 4, false)

	return {
		Instance = holder,
		Set = function(_, v)
			label.Text = tostring(v)
		end,
		Destroy = function()
			holder:Destroy()
		end,
	}
end
function Tab:AddDivider()
	local holder = Instance.new("Frame")
	holder.Name = "Divider"
	holder.BackgroundTransparency = 1
	holder.Size = UDim2.new(1, 0, 0, 13)
	holder.ZIndex = Z.Content
	holder.Parent = self._page

	local line = Instance.new("Frame")
	line.AnchorPoint = Vector2.new(0, 0.5)
	line.Position = UDim2.new(0, 0, 0.5, 0)
	line.Size = UDim2.new(1, 0, 0, 1)
	line.BackgroundColor3 = Color3.new(1, 1, 1)
	line.BackgroundTransparency = 0.92
	line.BorderSizePixel = 0
	line.ZIndex = Z.Content
	line.Parent = holder

	return {
		Instance = holder,
		Destroy = function()
			holder:Destroy()
		end,
	}
end

Tab.AddLine = Tab.AddDivider

function Tab:AddLineText(text)
	text = tostring(text or "")

	local holder = Instance.new("Frame")
	holder.Name = "LineText"
	holder.BackgroundTransparency = 1
	holder.Size = UDim2.new(1, 0, 0, 20)
	holder.ZIndex = Z.Content
	holder.Parent = self._page

	local left = Instance.new("Frame")
	left.Name = "Left"
	left.AnchorPoint = Vector2.new(0, 0.5)
	left.Position = UDim2.fromScale(0, 0.5)
	left.Size = UDim2.new(0.5, -10, 0, 1)
	left.BackgroundColor3 = Color3.new(1, 1, 1)
	left.BackgroundTransparency = 0.92
	left.BorderSizePixel = 0
	left.ZIndex = Z.Content
	left.Parent = holder

	local right = Instance.new("Frame")
	right.Name = "Right"
	right.AnchorPoint = Vector2.new(1, 0.5)
	right.Position = UDim2.fromScale(1, 0.5)
	right.Size = UDim2.new(0.5, -10, 0, 1)
	right.BackgroundColor3 = Color3.new(1, 1, 1)
	right.BackgroundTransparency = 0.92
	right.BorderSizePixel = 0
	right.ZIndex = Z.Content
	right.Parent = holder

	local label = Instance.new("TextLabel")
	label.Name = "Label"
	label.BackgroundTransparency = 1
	label.FontFace = NullUI.Theme.FontRegular
	label.Text = text
	label.TextColor3 = NullUI.Theme.TextDim
	Role(label, "TextDim")
	label.TextSize = 12
	label.AnchorPoint = Vector2.new(0.5, 0.5)
	label.Position = UDim2.fromScale(0.5, 0.5)
	label.AutomaticSize = Enum.AutomaticSize.XY
	label.Size = UDim2.fromOffset(0, 16)
	label.ZIndex = Z.Content + 1
	label.Parent = holder

	local gap = 10
	local minSide = 6
	local lastW = -1

	local function relayout()
		local w = holder.AbsoluteSize.X / GetUIScale()
		if w <= 0 or math.abs(w - lastW) < 1 then
			return
		end
		lastW = w

		local textW = MeasureText(text, 12, w)
		local sideW = math.max((w - textW) / 2 - gap, minSide)
		left.Size = UDim2.new(0, sideW, 0, 1)
		right.Size = UDim2.new(0, sideW, 0, 1)
	end

	holder:GetPropertyChangedSignal("AbsoluteSize"):Connect(relayout)
	SafeDefer(relayout)

	return {
		Instance = holder,
		Set = function(_, v)
			text = tostring(v or "")
			label.Text = text
			lastW = -1
			relayout()
		end,
		Destroy = function()
			holder:Destroy()
		end,
	}
end

function Tab:AddParagraph(opts)
	opts = opts or {}

	local card = BaseCard(self._page, 10)
	card.AutomaticSize = Enum.AutomaticSize.Y

	local pad = Instance.new("UIPadding")
	pad.PaddingTop = UDim.new(0, 12)
	pad.PaddingBottom = UDim.new(0, 12)
	pad.PaddingLeft = UDim.new(0, 14)
	pad.PaddingRight = UDim.new(0, 14)
	pad.Parent = card

	local layout = Instance.new("UIListLayout")
	layout.Padding = UDim.new(0, 4)
	layout.SortOrder = Enum.SortOrder.LayoutOrder
	layout.Parent = card

	local titleLabel
	if opts.Title then
		local titleRow = Instance.new("Frame")
		titleRow.BackgroundTransparency = 1
		titleRow.Size = UDim2.new(1, 0, 0, 18)
		titleRow.AutomaticSize = Enum.AutomaticSize.Y
		titleRow.LayoutOrder = 1
		titleRow.ZIndex = Z.Content + 1
		titleRow.Parent = card

		local rowLayout = Instance.new("UIListLayout")
		rowLayout.FillDirection = Enum.FillDirection.Horizontal
		rowLayout.VerticalAlignment = Enum.VerticalAlignment.Center
		rowLayout.SortOrder = Enum.SortOrder.LayoutOrder
		rowLayout.Padding = UDim.new(0, 7)
		rowLayout.Parent = titleRow

		local iconAsset = opts.Icon and ResolveIcon(opts.Icon) or ""
		if iconAsset ~= "" then
			local img = Instance.new("ImageLabel")
			img.BackgroundTransparency = 1
			img.Image = iconAsset
			img.ImageColor3 = NullUI.Theme.Text
			Role(img, "Text")
			img.Size = UDim2.fromOffset(15, 15)
			img.LayoutOrder = 1
			img.ZIndex = Z.Content + 2
			img.Parent = titleRow
		end

		titleLabel = Instance.new("TextLabel")
		titleLabel.BackgroundTransparency = 1
		titleLabel.FontFace = NullUI.Theme.Font
		titleLabel.Text = opts.Title
		titleLabel.TextColor3 = NullUI.Theme.Text
		Role(titleLabel, "Text")
		titleLabel.TextSize = 14
		titleLabel.TextXAlignment = Enum.TextXAlignment.Left
		titleLabel.TextYAlignment = Enum.TextYAlignment.Center
		titleLabel.AutomaticSize = Enum.AutomaticSize.X
		titleLabel.Size = UDim2.fromOffset(0, 18)
		titleLabel.LayoutOrder = 2
		titleLabel.ZIndex = Z.Content + 2
		titleLabel.Parent = titleRow

		local titlePadding = Instance.new("UIPadding")
		titlePadding.PaddingTop = UDim.new(0, 2)
		titlePadding.Parent = titleLabel
	end

	local textLabel = Instance.new("TextLabel")
	textLabel.BackgroundTransparency = 1
	textLabel.FontFace = NullUI.Theme.FontRegular
	textLabel.Text = opts.Text or ""
	textLabel.TextColor3 = NullUI.Theme.TextDim
	Role(textLabel, "TextDim")
	textLabel.TextSize = 13
	textLabel.TextWrapped = true
	textLabel.TextXAlignment = Enum.TextXAlignment.Left
	textLabel.AutomaticSize = Enum.AutomaticSize.Y
	textLabel.Size = UDim2.new(1, 0, 0, 16)
	textLabel.LayoutOrder = 2
	textLabel.ZIndex = Z.Content + 1
	textLabel.Parent = card

	return {
		Instance = card,
		Set = function(_, v)
			textLabel.Text = v
		end,
		Get = function()
			return textLabel.Text
		end,
		SetTitle = function(_, v)
			if titleLabel then
				titleLabel.Text = v
			end
		end,
		Destroy = function()
			card:Destroy()
		end,
	}
end

local function BuildStarRow(parent, layoutOrder, maxStars, starColor, starSize, default)
	local starOutline = ResolveIcon("Phosphor:star")
	local starFilled = ResolveIcon("Material:star")

	local row = Instance.new("Frame")
	row.Name = "Stars"
	row.BackgroundTransparency = 1
	row.Size = UDim2.new(1, 0, 0, starSize)
	row.LayoutOrder = layoutOrder
	row.ZIndex = Z.Content + 1
	row.Parent = parent

	local rowLayout = Instance.new("UIListLayout")
	rowLayout.FillDirection = Enum.FillDirection.Horizontal
	rowLayout.HorizontalAlignment = Enum.HorizontalAlignment.Center
	rowLayout.VerticalAlignment = Enum.VerticalAlignment.Center
	rowLayout.Padding = UDim.new(0, 8)
	rowLayout.SortOrder = Enum.SortOrder.LayoutOrder
	rowLayout.Parent = row

	local stars = {}
	local selected = math.clamp(default or 0, 0, maxStars)

	local function paint(previewCount)
		local count = previewCount or selected
		for i, button in ipairs(stars) do
			local on = i <= count
			button.Image = on and starFilled or starOutline
			Tween(button, { ImageColor3 = on and starColor or NullUI.Theme.TextDim }, 0.12)
		end
	end

	for i = 1, maxStars do
		local button = Instance.new("ImageButton")
		button.Name = "Star" .. i
		button.BackgroundTransparency = 1
		button.AutoButtonColor = false
		button.Image = starOutline
		button.ImageColor3 = NullUI.Theme.TextDim
		Role(button, "TextDim")
		button.Size = UDim2.fromOffset(starSize, starSize)
		button.LayoutOrder = i
		button.ZIndex = Z.Content + 2
		button.Parent = row

		button.MouseEnter:Connect(function()
			paint(i)
		end)
		button.MouseLeave:Connect(function()
			paint()
		end)
		button.MouseButton1Click:Connect(function()
			selected = i
			paint()
		end)

		stars[i] = button
	end
	paint()

	return {
		Row = row,
		Get = function()
			return selected
		end,
		Set = function(v)
			selected = math.clamp(v or 0, 0, maxStars)
			paint()
		end,
		Nudge = function()
			for _, button in ipairs(stars) do
				Tween(button, { Rotation = 8 }, 0.08)
			end
			SafeDelay(0.06, function()
				for _, button in ipairs(stars) do
					Tween(button, { Rotation = 0 }, 0.12)
				end
			end)
		end,
	}
end

local function NormalizeFeedbackText(text)
	local invisibleChars = {
		["\226\128\139"] = "",
		["\226\128\142"] = "",
		["\226\128\143"] = "",
		["\239\187\191"] = "",
		["\194\173"] = "",
	}
	for char, replacement in pairs(invisibleChars) do
		text = text:gsub(char, replacement)
	end
	text = text:gsub("%s+", " ")
	text = text:gsub("^%s+", "")
	text = text:gsub("%s+$", "")
	return text
end

local FeedbackEvasionPatterns = {
	{ pattern = "d%s*i%s*s%s*c%s*o%s*r%s*d", name = "discord" },
	{ pattern = "t%s*e%s*l%s*e%s*g%s*r%s*a%s*m", name = "telegram" },
	{ pattern = "w%s*h%s*a%s*t%s*s%s*a%s*p%s*p", name = "whatsapp" },
	{ pattern = "h%s*t%s*t%s*p", name = "http" },
	{ pattern = "h%s*t%s*t%s*p%s*s", name = "https" },
	{ pattern = "w%s*w%s*w", name = "www" },
	{ pattern = "c%s*o%s*m", name = "com" },
	{ pattern = "o%s*r%s*g", name = "org" },
	{ pattern = "n%s*e%s*t", name = "net" },
	{ pattern = ".%s*g%s*g", name = ".gg" },
	{ pattern = ".%s*c%s*o%s*m", name = ".com" },
	{ pattern = "/%s*i%s*n%s*v%s*i%s*t%s*e", name = "/invite" },
	{ pattern = "d%s*o%s*t%s*%s*c%s*o%s*m", name = "dot com" },
	{ pattern = "a%s*t%s*%s*%s*h%s*e%s*r%s*e", name = "@here" },
	{ pattern = "a%s*t%s*%s*%s*e%s*v%s*e%s*r%s*y%s*o%s*n%s*e", name = "@everyone" },
}

local function DetectFeedbackEvasion(text)
	for _, evasion in ipairs(FeedbackEvasionPatterns) do
		if text:match(evasion.pattern) then
			return true, evasion.name
		end
	end
	local dotCount, slashCount = 0, 0
	for i = 1, #text do
		local char = text:sub(i, i)
		if char == "." then
			dotCount = dotCount + 1
		end
		if char == "/" then
			slashCount = slashCount + 1
		end
	end
	if dotCount >= 3 or slashCount >= 3 then
		return true, "suspicious link/invite"
	end
	return false, nil
end

local FeedbackAsciiMap = {
	["ÃƒÆ’Ã†â€™Ãƒâ€ Ã¢â‚¬â„¢ÃƒÆ’Ã¢â‚¬Â ÃƒÂ¢Ã¢â€šÂ¬Ã¢â€žÂ¢ÃƒÆ’Ã†â€™ÃƒÂ¢Ã¢â€šÂ¬Ã‚Â ÃƒÆ’Ã‚Â¢ÃƒÂ¢Ã¢â‚¬Å¡Ã‚Â¬ÃƒÂ¢Ã¢â‚¬Å¾Ã‚Â¢ÃƒÆ’Ã†â€™Ãƒâ€ Ã¢â‚¬â„¢ÃƒÆ’Ã‚Â¢ÃƒÂ¢Ã¢â‚¬Å¡Ã‚Â¬Ãƒâ€šÃ‚Â ÃƒÆ’Ã†â€™Ãƒâ€šÃ‚Â¢ÃƒÆ’Ã‚Â¢ÃƒÂ¢Ã¢â€šÂ¬Ã…Â¡Ãƒâ€šÃ‚Â¬ÃƒÆ’Ã‚Â¢ÃƒÂ¢Ã¢â€šÂ¬Ã…Â¾Ãƒâ€šÃ‚Â¢ÃƒÆ’Ã†â€™Ãƒâ€ Ã¢â‚¬â„¢ÃƒÆ’Ã¢â‚¬Â ÃƒÂ¢Ã¢â€šÂ¬Ã¢â€žÂ¢ÃƒÆ’Ã†â€™Ãƒâ€šÃ‚Â¢ÃƒÆ’Ã‚Â¢ÃƒÂ¢Ã¢â€šÂ¬Ã…Â¡Ãƒâ€šÃ‚Â¬ÃƒÆ’Ã¢â‚¬Â¦Ãƒâ€šÃ‚Â¡ÃƒÆ’Ã†â€™Ãƒâ€ Ã¢â‚¬â„¢ÃƒÆ’Ã‚Â¢ÃƒÂ¢Ã¢â‚¬Å¡Ã‚Â¬Ãƒâ€¦Ã‚Â¡ÃƒÆ’Ã†â€™ÃƒÂ¢Ã¢â€šÂ¬Ã…Â¡ÃƒÆ’Ã¢â‚¬Å¡Ãƒâ€šÃ‚Â¡"] = "a",
	["ÃƒÆ’Ã†â€™Ãƒâ€ Ã¢â‚¬â„¢ÃƒÆ’Ã¢â‚¬Â ÃƒÂ¢Ã¢â€šÂ¬Ã¢â€žÂ¢ÃƒÆ’Ã†â€™ÃƒÂ¢Ã¢â€šÂ¬Ã‚Â ÃƒÆ’Ã‚Â¢ÃƒÂ¢Ã¢â‚¬Å¡Ã‚Â¬ÃƒÂ¢Ã¢â‚¬Å¾Ã‚Â¢ÃƒÆ’Ã†â€™Ãƒâ€ Ã¢â‚¬â„¢ÃƒÆ’Ã‚Â¢ÃƒÂ¢Ã¢â‚¬Å¡Ã‚Â¬Ãƒâ€šÃ‚Â ÃƒÆ’Ã†â€™Ãƒâ€šÃ‚Â¢ÃƒÆ’Ã‚Â¢ÃƒÂ¢Ã¢â€šÂ¬Ã…Â¡Ãƒâ€šÃ‚Â¬ÃƒÆ’Ã‚Â¢ÃƒÂ¢Ã¢â€šÂ¬Ã…Â¾Ãƒâ€šÃ‚Â¢ÃƒÆ’Ã†â€™Ãƒâ€ Ã¢â‚¬â„¢ÃƒÆ’Ã¢â‚¬Â ÃƒÂ¢Ã¢â€šÂ¬Ã¢â€žÂ¢ÃƒÆ’Ã†â€™Ãƒâ€šÃ‚Â¢ÃƒÆ’Ã‚Â¢ÃƒÂ¢Ã¢â€šÂ¬Ã…Â¡Ãƒâ€šÃ‚Â¬ÃƒÆ’Ã¢â‚¬Â¦Ãƒâ€šÃ‚Â¡ÃƒÆ’Ã†â€™Ãƒâ€ Ã¢â‚¬â„¢ÃƒÆ’Ã‚Â¢ÃƒÂ¢Ã¢â‚¬Å¡Ã‚Â¬Ãƒâ€¦Ã‚Â¡ÃƒÆ’Ã†â€™ÃƒÂ¢Ã¢â€šÂ¬Ã…Â¡ÃƒÆ’Ã¢â‚¬Å¡Ãƒâ€šÃ‚Â "] = "a",
	["ÃƒÆ’Ã†â€™Ãƒâ€ Ã¢â‚¬â„¢ÃƒÆ’Ã¢â‚¬Â ÃƒÂ¢Ã¢â€šÂ¬Ã¢â€žÂ¢ÃƒÆ’Ã†â€™ÃƒÂ¢Ã¢â€šÂ¬Ã‚Â ÃƒÆ’Ã‚Â¢ÃƒÂ¢Ã¢â‚¬Å¡Ã‚Â¬ÃƒÂ¢Ã¢â‚¬Å¾Ã‚Â¢ÃƒÆ’Ã†â€™Ãƒâ€ Ã¢â‚¬â„¢ÃƒÆ’Ã‚Â¢ÃƒÂ¢Ã¢â‚¬Å¡Ã‚Â¬Ãƒâ€šÃ‚Â ÃƒÆ’Ã†â€™Ãƒâ€šÃ‚Â¢ÃƒÆ’Ã‚Â¢ÃƒÂ¢Ã¢â€šÂ¬Ã…Â¡Ãƒâ€šÃ‚Â¬ÃƒÆ’Ã‚Â¢ÃƒÂ¢Ã¢â€šÂ¬Ã…Â¾Ãƒâ€šÃ‚Â¢ÃƒÆ’Ã†â€™Ãƒâ€ Ã¢â‚¬â„¢ÃƒÆ’Ã¢â‚¬Â ÃƒÂ¢Ã¢â€šÂ¬Ã¢â€žÂ¢ÃƒÆ’Ã†â€™Ãƒâ€šÃ‚Â¢ÃƒÆ’Ã‚Â¢ÃƒÂ¢Ã¢â€šÂ¬Ã…Â¡Ãƒâ€šÃ‚Â¬ÃƒÆ’Ã¢â‚¬Â¦Ãƒâ€šÃ‚Â¡ÃƒÆ’Ã†â€™Ãƒâ€ Ã¢â‚¬â„¢ÃƒÆ’Ã‚Â¢ÃƒÂ¢Ã¢â‚¬Å¡Ã‚Â¬Ãƒâ€¦Ã‚Â¡ÃƒÆ’Ã†â€™ÃƒÂ¢Ã¢â€šÂ¬Ã…Â¡ÃƒÆ’Ã¢â‚¬Å¡Ãƒâ€šÃ‚Â£"] = "a",
	["ÃƒÆ’Ã†â€™Ãƒâ€ Ã¢â‚¬â„¢ÃƒÆ’Ã¢â‚¬Â ÃƒÂ¢Ã¢â€šÂ¬Ã¢â€žÂ¢ÃƒÆ’Ã†â€™ÃƒÂ¢Ã¢â€šÂ¬Ã‚Â ÃƒÆ’Ã‚Â¢ÃƒÂ¢Ã¢â‚¬Å¡Ã‚Â¬ÃƒÂ¢Ã¢â‚¬Å¾Ã‚Â¢ÃƒÆ’Ã†â€™Ãƒâ€ Ã¢â‚¬â„¢ÃƒÆ’Ã‚Â¢ÃƒÂ¢Ã¢â‚¬Å¡Ã‚Â¬Ãƒâ€šÃ‚Â ÃƒÆ’Ã†â€™Ãƒâ€šÃ‚Â¢ÃƒÆ’Ã‚Â¢ÃƒÂ¢Ã¢â€šÂ¬Ã…Â¡Ãƒâ€šÃ‚Â¬ÃƒÆ’Ã‚Â¢ÃƒÂ¢Ã¢â€šÂ¬Ã…Â¾Ãƒâ€šÃ‚Â¢ÃƒÆ’Ã†â€™Ãƒâ€ Ã¢â‚¬â„¢ÃƒÆ’Ã¢â‚¬Â ÃƒÂ¢Ã¢â€šÂ¬Ã¢â€žÂ¢ÃƒÆ’Ã†â€™Ãƒâ€šÃ‚Â¢ÃƒÆ’Ã‚Â¢ÃƒÂ¢Ã¢â€šÂ¬Ã…Â¡Ãƒâ€šÃ‚Â¬ÃƒÆ’Ã¢â‚¬Â¦Ãƒâ€šÃ‚Â¡ÃƒÆ’Ã†â€™Ãƒâ€ Ã¢â‚¬â„¢ÃƒÆ’Ã‚Â¢ÃƒÂ¢Ã¢â‚¬Å¡Ã‚Â¬Ãƒâ€¦Ã‚Â¡ÃƒÆ’Ã†â€™ÃƒÂ¢Ã¢â€šÂ¬Ã…Â¡ÃƒÆ’Ã¢â‚¬Å¡Ãƒâ€šÃ‚Â¢"] = "a",
	["ÃƒÆ’Ã†â€™Ãƒâ€ Ã¢â‚¬â„¢ÃƒÆ’Ã¢â‚¬Â ÃƒÂ¢Ã¢â€šÂ¬Ã¢â€žÂ¢ÃƒÆ’Ã†â€™ÃƒÂ¢Ã¢â€šÂ¬Ã‚Â ÃƒÆ’Ã‚Â¢ÃƒÂ¢Ã¢â‚¬Å¡Ã‚Â¬ÃƒÂ¢Ã¢â‚¬Å¾Ã‚Â¢ÃƒÆ’Ã†â€™Ãƒâ€ Ã¢â‚¬â„¢ÃƒÆ’Ã‚Â¢ÃƒÂ¢Ã¢â‚¬Å¡Ã‚Â¬Ãƒâ€šÃ‚Â ÃƒÆ’Ã†â€™Ãƒâ€šÃ‚Â¢ÃƒÆ’Ã‚Â¢ÃƒÂ¢Ã¢â€šÂ¬Ã…Â¡Ãƒâ€šÃ‚Â¬ÃƒÆ’Ã‚Â¢ÃƒÂ¢Ã¢â€šÂ¬Ã…Â¾Ãƒâ€šÃ‚Â¢ÃƒÆ’Ã†â€™Ãƒâ€ Ã¢â‚¬â„¢ÃƒÆ’Ã¢â‚¬Â ÃƒÂ¢Ã¢â€šÂ¬Ã¢â€žÂ¢ÃƒÆ’Ã†â€™Ãƒâ€šÃ‚Â¢ÃƒÆ’Ã‚Â¢ÃƒÂ¢Ã¢â€šÂ¬Ã…Â¡Ãƒâ€šÃ‚Â¬ÃƒÆ’Ã¢â‚¬Â¦Ãƒâ€šÃ‚Â¡ÃƒÆ’Ã†â€™Ãƒâ€ Ã¢â‚¬â„¢ÃƒÆ’Ã‚Â¢ÃƒÂ¢Ã¢â‚¬Å¡Ã‚Â¬Ãƒâ€¦Ã‚Â¡ÃƒÆ’Ã†â€™ÃƒÂ¢Ã¢â€šÂ¬Ã…Â¡ÃƒÆ’Ã¢â‚¬Å¡Ãƒâ€šÃ‚Â¤"] = "a",
	["ÃƒÆ’Ã†â€™Ãƒâ€ Ã¢â‚¬â„¢ÃƒÆ’Ã¢â‚¬Â ÃƒÂ¢Ã¢â€šÂ¬Ã¢â€žÂ¢ÃƒÆ’Ã†â€™ÃƒÂ¢Ã¢â€šÂ¬Ã‚Â ÃƒÆ’Ã‚Â¢ÃƒÂ¢Ã¢â‚¬Å¡Ã‚Â¬ÃƒÂ¢Ã¢â‚¬Å¾Ã‚Â¢ÃƒÆ’Ã†â€™Ãƒâ€ Ã¢â‚¬â„¢ÃƒÆ’Ã‚Â¢ÃƒÂ¢Ã¢â‚¬Å¡Ã‚Â¬Ãƒâ€šÃ‚Â ÃƒÆ’Ã†â€™Ãƒâ€šÃ‚Â¢ÃƒÆ’Ã‚Â¢ÃƒÂ¢Ã¢â€šÂ¬Ã…Â¡Ãƒâ€šÃ‚Â¬ÃƒÆ’Ã‚Â¢ÃƒÂ¢Ã¢â€šÂ¬Ã…Â¾Ãƒâ€šÃ‚Â¢ÃƒÆ’Ã†â€™Ãƒâ€ Ã¢â‚¬â„¢ÃƒÆ’Ã¢â‚¬Â ÃƒÂ¢Ã¢â€šÂ¬Ã¢â€žÂ¢ÃƒÆ’Ã†â€™Ãƒâ€šÃ‚Â¢ÃƒÆ’Ã‚Â¢ÃƒÂ¢Ã¢â€šÂ¬Ã…Â¡Ãƒâ€šÃ‚Â¬ÃƒÆ’Ã¢â‚¬Â¦Ãƒâ€šÃ‚Â¡ÃƒÆ’Ã†â€™Ãƒâ€ Ã¢â‚¬â„¢ÃƒÆ’Ã‚Â¢ÃƒÂ¢Ã¢â‚¬Å¡Ã‚Â¬Ãƒâ€¦Ã‚Â¡ÃƒÆ’Ã†â€™ÃƒÂ¢Ã¢â€šÂ¬Ã…Â¡ÃƒÆ’Ã¢â‚¬Å¡Ãƒâ€šÃ‚Â"] = "A",
	["ÃƒÆ’Ã†â€™Ãƒâ€ Ã¢â‚¬â„¢ÃƒÆ’Ã¢â‚¬Â ÃƒÂ¢Ã¢â€šÂ¬Ã¢â€žÂ¢ÃƒÆ’Ã†â€™ÃƒÂ¢Ã¢â€šÂ¬Ã‚Â ÃƒÆ’Ã‚Â¢ÃƒÂ¢Ã¢â‚¬Å¡Ã‚Â¬ÃƒÂ¢Ã¢â‚¬Å¾Ã‚Â¢ÃƒÆ’Ã†â€™Ãƒâ€ Ã¢â‚¬â„¢ÃƒÆ’Ã‚Â¢ÃƒÂ¢Ã¢â‚¬Å¡Ã‚Â¬Ãƒâ€šÃ‚Â ÃƒÆ’Ã†â€™Ãƒâ€šÃ‚Â¢ÃƒÆ’Ã‚Â¢ÃƒÂ¢Ã¢â€šÂ¬Ã…Â¡Ãƒâ€šÃ‚Â¬ÃƒÆ’Ã‚Â¢ÃƒÂ¢Ã¢â€šÂ¬Ã…Â¾Ãƒâ€šÃ‚Â¢ÃƒÆ’Ã†â€™Ãƒâ€ Ã¢â‚¬â„¢ÃƒÆ’Ã¢â‚¬Â ÃƒÂ¢Ã¢â€šÂ¬Ã¢â€žÂ¢ÃƒÆ’Ã†â€™ÃƒÂ¢Ã¢â€šÂ¬Ã…Â¡ÃƒÆ’Ã¢â‚¬Å¡Ãƒâ€šÃ‚Â¢ÃƒÆ’Ã†â€™Ãƒâ€ Ã¢â‚¬â„¢ÃƒÆ’Ã¢â‚¬Å¡Ãƒâ€šÃ‚Â¢ÃƒÆ’Ã†â€™Ãƒâ€šÃ‚Â¢ÃƒÆ’Ã‚Â¢ÃƒÂ¢Ã¢â‚¬Å¡Ã‚Â¬Ãƒâ€¦Ã‚Â¡ÃƒÆ’Ã¢â‚¬Å¡Ãƒâ€šÃ‚Â¬ÃƒÆ’Ã†â€™ÃƒÂ¢Ã¢â€šÂ¬Ã‚Â¦ÃƒÆ’Ã¢â‚¬Å¡Ãƒâ€šÃ‚Â¡ÃƒÆ’Ã†â€™Ãƒâ€ Ã¢â‚¬â„¢ÃƒÆ’Ã‚Â¢ÃƒÂ¢Ã¢â‚¬Å¡Ã‚Â¬Ãƒâ€¦Ã‚Â¡ÃƒÆ’Ã†â€™ÃƒÂ¢Ã¢â€šÂ¬Ã…Â¡ÃƒÆ’Ã¢â‚¬Å¡Ãƒâ€šÃ‚Â¬"] = "A",
	["ÃƒÆ’Ã†â€™Ãƒâ€ Ã¢â‚¬â„¢ÃƒÆ’Ã¢â‚¬Â ÃƒÂ¢Ã¢â€šÂ¬Ã¢â€žÂ¢ÃƒÆ’Ã†â€™ÃƒÂ¢Ã¢â€šÂ¬Ã‚Â ÃƒÆ’Ã‚Â¢ÃƒÂ¢Ã¢â‚¬Å¡Ã‚Â¬ÃƒÂ¢Ã¢â‚¬Å¾Ã‚Â¢ÃƒÆ’Ã†â€™Ãƒâ€ Ã¢â‚¬â„¢ÃƒÆ’Ã‚Â¢ÃƒÂ¢Ã¢â‚¬Å¡Ã‚Â¬Ãƒâ€šÃ‚Â ÃƒÆ’Ã†â€™Ãƒâ€šÃ‚Â¢ÃƒÆ’Ã‚Â¢ÃƒÂ¢Ã¢â€šÂ¬Ã…Â¡Ãƒâ€šÃ‚Â¬ÃƒÆ’Ã‚Â¢ÃƒÂ¢Ã¢â€šÂ¬Ã…Â¾Ãƒâ€šÃ‚Â¢ÃƒÆ’Ã†â€™Ãƒâ€ Ã¢â‚¬â„¢ÃƒÆ’Ã¢â‚¬Â ÃƒÂ¢Ã¢â€šÂ¬Ã¢â€žÂ¢ÃƒÆ’Ã†â€™Ãƒâ€šÃ‚Â¢ÃƒÆ’Ã‚Â¢ÃƒÂ¢Ã¢â€šÂ¬Ã…Â¡Ãƒâ€šÃ‚Â¬ÃƒÆ’Ã¢â‚¬Å¡Ãƒâ€šÃ‚Â ÃƒÆ’Ã†â€™Ãƒâ€ Ã¢â‚¬â„¢ÃƒÆ’Ã¢â‚¬Å¡Ãƒâ€šÃ‚Â¢ÃƒÆ’Ã†â€™Ãƒâ€šÃ‚Â¢ÃƒÆ’Ã‚Â¢ÃƒÂ¢Ã¢â‚¬Å¡Ã‚Â¬Ãƒâ€¦Ã‚Â¡ÃƒÆ’Ã¢â‚¬Å¡Ãƒâ€šÃ‚Â¬ÃƒÆ’Ã†â€™Ãƒâ€šÃ‚Â¢ÃƒÆ’Ã‚Â¢ÃƒÂ¢Ã¢â‚¬Å¡Ã‚Â¬Ãƒâ€¦Ã‚Â¾ÃƒÆ’Ã¢â‚¬Å¡Ãƒâ€šÃ‚Â¢"] = "A",
	["ÃƒÆ’Ã†â€™Ãƒâ€ Ã¢â‚¬â„¢ÃƒÆ’Ã¢â‚¬Â ÃƒÂ¢Ã¢â€šÂ¬Ã¢â€žÂ¢ÃƒÆ’Ã†â€™ÃƒÂ¢Ã¢â€šÂ¬Ã‚Â ÃƒÆ’Ã‚Â¢ÃƒÂ¢Ã¢â‚¬Å¡Ã‚Â¬ÃƒÂ¢Ã¢â‚¬Å¾Ã‚Â¢ÃƒÆ’Ã†â€™Ãƒâ€ Ã¢â‚¬â„¢ÃƒÆ’Ã‚Â¢ÃƒÂ¢Ã¢â‚¬Å¡Ã‚Â¬Ãƒâ€šÃ‚Â ÃƒÆ’Ã†â€™Ãƒâ€šÃ‚Â¢ÃƒÆ’Ã‚Â¢ÃƒÂ¢Ã¢â€šÂ¬Ã…Â¡Ãƒâ€šÃ‚Â¬ÃƒÆ’Ã‚Â¢ÃƒÂ¢Ã¢â€šÂ¬Ã…Â¾Ãƒâ€šÃ‚Â¢ÃƒÆ’Ã†â€™Ãƒâ€ Ã¢â‚¬â„¢ÃƒÆ’Ã¢â‚¬Â ÃƒÂ¢Ã¢â€šÂ¬Ã¢â€žÂ¢ÃƒÆ’Ã†â€™ÃƒÂ¢Ã¢â€šÂ¬Ã…Â¡ÃƒÆ’Ã¢â‚¬Å¡Ãƒâ€šÃ‚Â¢ÃƒÆ’Ã†â€™Ãƒâ€ Ã¢â‚¬â„¢ÃƒÆ’Ã¢â‚¬Å¡Ãƒâ€šÃ‚Â¢ÃƒÆ’Ã†â€™Ãƒâ€šÃ‚Â¢ÃƒÆ’Ã‚Â¢ÃƒÂ¢Ã¢â€šÂ¬Ã…Â¡Ãƒâ€šÃ‚Â¬ÃƒÆ’Ã¢â‚¬Â¦Ãƒâ€šÃ‚Â¡ÃƒÆ’Ã†â€™ÃƒÂ¢Ã¢â€šÂ¬Ã…Â¡ÃƒÆ’Ã¢â‚¬Å¡Ãƒâ€šÃ‚Â¬ÃƒÆ’Ã†â€™Ãƒâ€ Ã¢â‚¬â„¢ÃƒÆ’Ã‚Â¢ÃƒÂ¢Ã¢â‚¬Å¡Ã‚Â¬Ãƒâ€šÃ‚Â¦ÃƒÆ’Ã†â€™ÃƒÂ¢Ã¢â€šÂ¬Ã…Â¡ÃƒÆ’Ã¢â‚¬Å¡Ãƒâ€šÃ‚Â¡"] = "A",
	["ÃƒÆ’Ã†â€™Ãƒâ€ Ã¢â‚¬â„¢ÃƒÆ’Ã¢â‚¬Â ÃƒÂ¢Ã¢â€šÂ¬Ã¢â€žÂ¢ÃƒÆ’Ã†â€™ÃƒÂ¢Ã¢â€šÂ¬Ã‚Â ÃƒÆ’Ã‚Â¢ÃƒÂ¢Ã¢â‚¬Å¡Ã‚Â¬ÃƒÂ¢Ã¢â‚¬Å¾Ã‚Â¢ÃƒÆ’Ã†â€™Ãƒâ€ Ã¢â‚¬â„¢ÃƒÆ’Ã‚Â¢ÃƒÂ¢Ã¢â‚¬Å¡Ã‚Â¬Ãƒâ€šÃ‚Â ÃƒÆ’Ã†â€™Ãƒâ€šÃ‚Â¢ÃƒÆ’Ã‚Â¢ÃƒÂ¢Ã¢â€šÂ¬Ã…Â¡Ãƒâ€šÃ‚Â¬ÃƒÆ’Ã‚Â¢ÃƒÂ¢Ã¢â€šÂ¬Ã…Â¾Ãƒâ€šÃ‚Â¢ÃƒÆ’Ã†â€™Ãƒâ€ Ã¢â‚¬â„¢ÃƒÆ’Ã¢â‚¬Â ÃƒÂ¢Ã¢â€šÂ¬Ã¢â€žÂ¢ÃƒÆ’Ã†â€™ÃƒÂ¢Ã¢â€šÂ¬Ã…Â¡ÃƒÆ’Ã¢â‚¬Å¡Ãƒâ€šÃ‚Â¢ÃƒÆ’Ã†â€™Ãƒâ€ Ã¢â‚¬â„¢ÃƒÆ’Ã¢â‚¬Å¡Ãƒâ€šÃ‚Â¢ÃƒÆ’Ã†â€™Ãƒâ€šÃ‚Â¢ÃƒÆ’Ã‚Â¢ÃƒÂ¢Ã¢â€šÂ¬Ã…Â¡Ãƒâ€šÃ‚Â¬ÃƒÆ’Ã¢â‚¬Â¦Ãƒâ€šÃ‚Â¡ÃƒÆ’Ã†â€™ÃƒÂ¢Ã¢â€šÂ¬Ã…Â¡ÃƒÆ’Ã¢â‚¬Å¡Ãƒâ€šÃ‚Â¬ÃƒÆ’Ã†â€™Ãƒâ€ Ã¢â‚¬â„¢ÃƒÆ’Ã‚Â¢ÃƒÂ¢Ã¢â‚¬Å¡Ã‚Â¬Ãƒâ€šÃ‚Â¦ÃƒÆ’Ã†â€™ÃƒÂ¢Ã¢â€šÂ¬Ã…Â¡ÃƒÆ’Ã¢â‚¬Å¡Ãƒâ€šÃ‚Â¾"] = "A",
	["ÃƒÆ’Ã†â€™Ãƒâ€ Ã¢â‚¬â„¢ÃƒÆ’Ã¢â‚¬Â ÃƒÂ¢Ã¢â€šÂ¬Ã¢â€žÂ¢ÃƒÆ’Ã†â€™ÃƒÂ¢Ã¢â€šÂ¬Ã‚Â ÃƒÆ’Ã‚Â¢ÃƒÂ¢Ã¢â‚¬Å¡Ã‚Â¬ÃƒÂ¢Ã¢â‚¬Å¾Ã‚Â¢ÃƒÆ’Ã†â€™Ãƒâ€ Ã¢â‚¬â„¢ÃƒÆ’Ã‚Â¢ÃƒÂ¢Ã¢â‚¬Å¡Ã‚Â¬Ãƒâ€šÃ‚Â ÃƒÆ’Ã†â€™Ãƒâ€šÃ‚Â¢ÃƒÆ’Ã‚Â¢ÃƒÂ¢Ã¢â€šÂ¬Ã…Â¡Ãƒâ€šÃ‚Â¬ÃƒÆ’Ã‚Â¢ÃƒÂ¢Ã¢â€šÂ¬Ã…Â¾Ãƒâ€šÃ‚Â¢ÃƒÆ’Ã†â€™Ãƒâ€ Ã¢â‚¬â„¢ÃƒÆ’Ã¢â‚¬Â ÃƒÂ¢Ã¢â€šÂ¬Ã¢â€žÂ¢ÃƒÆ’Ã†â€™Ãƒâ€šÃ‚Â¢ÃƒÆ’Ã‚Â¢ÃƒÂ¢Ã¢â€šÂ¬Ã…Â¡Ãƒâ€šÃ‚Â¬ÃƒÆ’Ã¢â‚¬Â¦Ãƒâ€šÃ‚Â¡ÃƒÆ’Ã†â€™Ãƒâ€ Ã¢â‚¬â„¢ÃƒÆ’Ã‚Â¢ÃƒÂ¢Ã¢â‚¬Å¡Ã‚Â¬Ãƒâ€¦Ã‚Â¡ÃƒÆ’Ã†â€™ÃƒÂ¢Ã¢â€šÂ¬Ã…Â¡ÃƒÆ’Ã¢â‚¬Å¡Ãƒâ€šÃ‚Â©"] = "e",
	["ÃƒÆ’Ã†â€™Ãƒâ€ Ã¢â‚¬â„¢ÃƒÆ’Ã¢â‚¬Â ÃƒÂ¢Ã¢â€šÂ¬Ã¢â€žÂ¢ÃƒÆ’Ã†â€™ÃƒÂ¢Ã¢â€šÂ¬Ã‚Â ÃƒÆ’Ã‚Â¢ÃƒÂ¢Ã¢â‚¬Å¡Ã‚Â¬ÃƒÂ¢Ã¢â‚¬Å¾Ã‚Â¢ÃƒÆ’Ã†â€™Ãƒâ€ Ã¢â‚¬â„¢ÃƒÆ’Ã‚Â¢ÃƒÂ¢Ã¢â‚¬Å¡Ã‚Â¬Ãƒâ€šÃ‚Â ÃƒÆ’Ã†â€™Ãƒâ€šÃ‚Â¢ÃƒÆ’Ã‚Â¢ÃƒÂ¢Ã¢â€šÂ¬Ã…Â¡Ãƒâ€šÃ‚Â¬ÃƒÆ’Ã‚Â¢ÃƒÂ¢Ã¢â€šÂ¬Ã…Â¾Ãƒâ€šÃ‚Â¢ÃƒÆ’Ã†â€™Ãƒâ€ Ã¢â‚¬â„¢ÃƒÆ’Ã¢â‚¬Â ÃƒÂ¢Ã¢â€šÂ¬Ã¢â€žÂ¢ÃƒÆ’Ã†â€™Ãƒâ€šÃ‚Â¢ÃƒÆ’Ã‚Â¢ÃƒÂ¢Ã¢â€šÂ¬Ã…Â¡Ãƒâ€šÃ‚Â¬ÃƒÆ’Ã¢â‚¬Â¦Ãƒâ€šÃ‚Â¡ÃƒÆ’Ã†â€™Ãƒâ€ Ã¢â‚¬â„¢ÃƒÆ’Ã‚Â¢ÃƒÂ¢Ã¢â‚¬Å¡Ã‚Â¬Ãƒâ€¦Ã‚Â¡ÃƒÆ’Ã†â€™ÃƒÂ¢Ã¢â€šÂ¬Ã…Â¡ÃƒÆ’Ã¢â‚¬Å¡Ãƒâ€šÃ‚Â¨"] = "e",
	["ÃƒÆ’Ã†â€™Ãƒâ€ Ã¢â‚¬â„¢ÃƒÆ’Ã¢â‚¬Â ÃƒÂ¢Ã¢â€šÂ¬Ã¢â€žÂ¢ÃƒÆ’Ã†â€™ÃƒÂ¢Ã¢â€šÂ¬Ã‚Â ÃƒÆ’Ã‚Â¢ÃƒÂ¢Ã¢â‚¬Å¡Ã‚Â¬ÃƒÂ¢Ã¢â‚¬Å¾Ã‚Â¢ÃƒÆ’Ã†â€™Ãƒâ€ Ã¢â‚¬â„¢ÃƒÆ’Ã‚Â¢ÃƒÂ¢Ã¢â‚¬Å¡Ã‚Â¬Ãƒâ€šÃ‚Â ÃƒÆ’Ã†â€™Ãƒâ€šÃ‚Â¢ÃƒÆ’Ã‚Â¢ÃƒÂ¢Ã¢â€šÂ¬Ã…Â¡Ãƒâ€šÃ‚Â¬ÃƒÆ’Ã‚Â¢ÃƒÂ¢Ã¢â€šÂ¬Ã…Â¾Ãƒâ€šÃ‚Â¢ÃƒÆ’Ã†â€™Ãƒâ€ Ã¢â‚¬â„¢ÃƒÆ’Ã¢â‚¬Â ÃƒÂ¢Ã¢â€šÂ¬Ã¢â€žÂ¢ÃƒÆ’Ã†â€™Ãƒâ€šÃ‚Â¢ÃƒÆ’Ã‚Â¢ÃƒÂ¢Ã¢â€šÂ¬Ã…Â¡Ãƒâ€šÃ‚Â¬ÃƒÆ’Ã¢â‚¬Â¦Ãƒâ€šÃ‚Â¡ÃƒÆ’Ã†â€™Ãƒâ€ Ã¢â‚¬â„¢ÃƒÆ’Ã‚Â¢ÃƒÂ¢Ã¢â‚¬Å¡Ã‚Â¬Ãƒâ€¦Ã‚Â¡ÃƒÆ’Ã†â€™ÃƒÂ¢Ã¢â€šÂ¬Ã…Â¡ÃƒÆ’Ã¢â‚¬Å¡Ãƒâ€šÃ‚Âª"] = "e",
	["ÃƒÆ’Ã†â€™Ãƒâ€ Ã¢â‚¬â„¢ÃƒÆ’Ã¢â‚¬Â ÃƒÂ¢Ã¢â€šÂ¬Ã¢â€žÂ¢ÃƒÆ’Ã†â€™ÃƒÂ¢Ã¢â€šÂ¬Ã‚Â ÃƒÆ’Ã‚Â¢ÃƒÂ¢Ã¢â‚¬Å¡Ã‚Â¬ÃƒÂ¢Ã¢â‚¬Å¾Ã‚Â¢ÃƒÆ’Ã†â€™Ãƒâ€ Ã¢â‚¬â„¢ÃƒÆ’Ã‚Â¢ÃƒÂ¢Ã¢â‚¬Å¡Ã‚Â¬Ãƒâ€šÃ‚Â ÃƒÆ’Ã†â€™Ãƒâ€šÃ‚Â¢ÃƒÆ’Ã‚Â¢ÃƒÂ¢Ã¢â€šÂ¬Ã…Â¡Ãƒâ€šÃ‚Â¬ÃƒÆ’Ã‚Â¢ÃƒÂ¢Ã¢â€šÂ¬Ã…Â¾Ãƒâ€šÃ‚Â¢ÃƒÆ’Ã†â€™Ãƒâ€ Ã¢â‚¬â„¢ÃƒÆ’Ã¢â‚¬Â ÃƒÂ¢Ã¢â€šÂ¬Ã¢â€žÂ¢ÃƒÆ’Ã†â€™Ãƒâ€šÃ‚Â¢ÃƒÆ’Ã‚Â¢ÃƒÂ¢Ã¢â€šÂ¬Ã…Â¡Ãƒâ€šÃ‚Â¬ÃƒÆ’Ã¢â‚¬Â¦Ãƒâ€šÃ‚Â¡ÃƒÆ’Ã†â€™Ãƒâ€ Ã¢â‚¬â„¢ÃƒÆ’Ã‚Â¢ÃƒÂ¢Ã¢â‚¬Å¡Ã‚Â¬Ãƒâ€¦Ã‚Â¡ÃƒÆ’Ã†â€™ÃƒÂ¢Ã¢â€šÂ¬Ã…Â¡ÃƒÆ’Ã¢â‚¬Å¡Ãƒâ€šÃ‚Â«"] = "e",
	["ÃƒÆ’Ã†â€™Ãƒâ€ Ã¢â‚¬â„¢ÃƒÆ’Ã¢â‚¬Â ÃƒÂ¢Ã¢â€šÂ¬Ã¢â€žÂ¢ÃƒÆ’Ã†â€™ÃƒÂ¢Ã¢â€šÂ¬Ã‚Â ÃƒÆ’Ã‚Â¢ÃƒÂ¢Ã¢â‚¬Å¡Ã‚Â¬ÃƒÂ¢Ã¢â‚¬Å¾Ã‚Â¢ÃƒÆ’Ã†â€™Ãƒâ€ Ã¢â‚¬â„¢ÃƒÆ’Ã‚Â¢ÃƒÂ¢Ã¢â‚¬Å¡Ã‚Â¬Ãƒâ€šÃ‚Â ÃƒÆ’Ã†â€™Ãƒâ€šÃ‚Â¢ÃƒÆ’Ã‚Â¢ÃƒÂ¢Ã¢â€šÂ¬Ã…Â¡Ãƒâ€šÃ‚Â¬ÃƒÆ’Ã‚Â¢ÃƒÂ¢Ã¢â€šÂ¬Ã…Â¾Ãƒâ€šÃ‚Â¢ÃƒÆ’Ã†â€™Ãƒâ€ Ã¢â‚¬â„¢ÃƒÆ’Ã¢â‚¬Â ÃƒÂ¢Ã¢â€šÂ¬Ã¢â€žÂ¢ÃƒÆ’Ã†â€™ÃƒÂ¢Ã¢â€šÂ¬Ã…Â¡ÃƒÆ’Ã¢â‚¬Å¡Ãƒâ€šÃ‚Â¢ÃƒÆ’Ã†â€™Ãƒâ€ Ã¢â‚¬â„¢ÃƒÆ’Ã¢â‚¬Å¡Ãƒâ€šÃ‚Â¢ÃƒÆ’Ã†â€™Ãƒâ€šÃ‚Â¢ÃƒÆ’Ã‚Â¢ÃƒÂ¢Ã¢â€šÂ¬Ã…Â¡Ãƒâ€šÃ‚Â¬ÃƒÆ’Ã¢â‚¬Â¦Ãƒâ€šÃ‚Â¡ÃƒÆ’Ã†â€™ÃƒÂ¢Ã¢â€šÂ¬Ã…Â¡ÃƒÆ’Ã¢â‚¬Å¡Ãƒâ€šÃ‚Â¬ÃƒÆ’Ã†â€™Ãƒâ€ Ã¢â‚¬â„¢ÃƒÆ’Ã‚Â¢ÃƒÂ¢Ã¢â‚¬Å¡Ã‚Â¬Ãƒâ€¦Ã‚Â¡ÃƒÆ’Ã†â€™ÃƒÂ¢Ã¢â€šÂ¬Ã…Â¡ÃƒÆ’Ã¢â‚¬Å¡Ãƒâ€šÃ‚Â°"] = "E",
	["ÃƒÆ’Ã†â€™Ãƒâ€ Ã¢â‚¬â„¢ÃƒÆ’Ã¢â‚¬Â ÃƒÂ¢Ã¢â€šÂ¬Ã¢â€žÂ¢ÃƒÆ’Ã†â€™ÃƒÂ¢Ã¢â€šÂ¬Ã‚Â ÃƒÆ’Ã‚Â¢ÃƒÂ¢Ã¢â‚¬Å¡Ã‚Â¬ÃƒÂ¢Ã¢â‚¬Å¾Ã‚Â¢ÃƒÆ’Ã†â€™Ãƒâ€ Ã¢â‚¬â„¢ÃƒÆ’Ã‚Â¢ÃƒÂ¢Ã¢â‚¬Å¡Ã‚Â¬Ãƒâ€šÃ‚Â ÃƒÆ’Ã†â€™Ãƒâ€šÃ‚Â¢ÃƒÆ’Ã‚Â¢ÃƒÂ¢Ã¢â€šÂ¬Ã…Â¡Ãƒâ€šÃ‚Â¬ÃƒÆ’Ã‚Â¢ÃƒÂ¢Ã¢â€šÂ¬Ã…Â¾Ãƒâ€šÃ‚Â¢ÃƒÆ’Ã†â€™Ãƒâ€ Ã¢â‚¬â„¢ÃƒÆ’Ã¢â‚¬Â ÃƒÂ¢Ã¢â€šÂ¬Ã¢â€žÂ¢ÃƒÆ’Ã†â€™Ãƒâ€šÃ‚Â¢ÃƒÆ’Ã‚Â¢ÃƒÂ¢Ã¢â€šÂ¬Ã…Â¡Ãƒâ€šÃ‚Â¬ÃƒÆ’Ã¢â‚¬Å¡Ãƒâ€šÃ‚Â¹ÃƒÆ’Ã†â€™Ãƒâ€ Ã¢â‚¬â„¢ÃƒÆ’Ã¢â‚¬Å¡Ãƒâ€šÃ‚Â¢ÃƒÆ’Ã†â€™Ãƒâ€šÃ‚Â¢ÃƒÆ’Ã‚Â¢ÃƒÂ¢Ã¢â‚¬Å¡Ã‚Â¬Ãƒâ€¦Ã‚Â¡ÃƒÆ’Ã¢â‚¬Å¡Ãƒâ€šÃ‚Â¬ÃƒÆ’Ã†â€™ÃƒÂ¢Ã¢â€šÂ¬Ã…Â¡ÃƒÆ’Ã¢â‚¬Å¡Ãƒâ€šÃ‚Â "] = "E",
	["ÃƒÆ’Ã†â€™Ãƒâ€ Ã¢â‚¬â„¢ÃƒÆ’Ã¢â‚¬Â ÃƒÂ¢Ã¢â€šÂ¬Ã¢â€žÂ¢ÃƒÆ’Ã†â€™ÃƒÂ¢Ã¢â€šÂ¬Ã‚Â ÃƒÆ’Ã‚Â¢ÃƒÂ¢Ã¢â‚¬Å¡Ã‚Â¬ÃƒÂ¢Ã¢â‚¬Å¾Ã‚Â¢ÃƒÆ’Ã†â€™Ãƒâ€ Ã¢â‚¬â„¢ÃƒÆ’Ã‚Â¢ÃƒÂ¢Ã¢â‚¬Å¡Ã‚Â¬Ãƒâ€šÃ‚Â ÃƒÆ’Ã†â€™Ãƒâ€šÃ‚Â¢ÃƒÆ’Ã‚Â¢ÃƒÂ¢Ã¢â€šÂ¬Ã…Â¡Ãƒâ€šÃ‚Â¬ÃƒÆ’Ã‚Â¢ÃƒÂ¢Ã¢â€šÂ¬Ã…Â¾Ãƒâ€šÃ‚Â¢ÃƒÆ’Ã†â€™Ãƒâ€ Ã¢â‚¬â„¢ÃƒÆ’Ã¢â‚¬Â ÃƒÂ¢Ã¢â€šÂ¬Ã¢â€žÂ¢ÃƒÆ’Ã†â€™Ãƒâ€šÃ‚Â¢ÃƒÆ’Ã‚Â¢ÃƒÂ¢Ã¢â€šÂ¬Ã…Â¡Ãƒâ€šÃ‚Â¬ÃƒÆ’Ã¢â‚¬Å¡Ãƒâ€šÃ‚Â¦ÃƒÆ’Ã†â€™Ãƒâ€ Ã¢â‚¬â„¢ÃƒÆ’Ã‚Â¢ÃƒÂ¢Ã¢â‚¬Å¡Ã‚Â¬Ãƒâ€¦Ã‚Â¡ÃƒÆ’Ã†â€™ÃƒÂ¢Ã¢â€šÂ¬Ã…Â¡ÃƒÆ’Ã¢â‚¬Å¡Ãƒâ€šÃ‚Â "] = "E",
	["ÃƒÆ’Ã†â€™Ãƒâ€ Ã¢â‚¬â„¢ÃƒÆ’Ã¢â‚¬Â ÃƒÂ¢Ã¢â€šÂ¬Ã¢â€žÂ¢ÃƒÆ’Ã†â€™ÃƒÂ¢Ã¢â€šÂ¬Ã‚Â ÃƒÆ’Ã‚Â¢ÃƒÂ¢Ã¢â‚¬Å¡Ã‚Â¬ÃƒÂ¢Ã¢â‚¬Å¾Ã‚Â¢ÃƒÆ’Ã†â€™Ãƒâ€ Ã¢â‚¬â„¢ÃƒÆ’Ã‚Â¢ÃƒÂ¢Ã¢â‚¬Å¡Ã‚Â¬Ãƒâ€šÃ‚Â ÃƒÆ’Ã†â€™Ãƒâ€šÃ‚Â¢ÃƒÆ’Ã‚Â¢ÃƒÂ¢Ã¢â€šÂ¬Ã…Â¡Ãƒâ€šÃ‚Â¬ÃƒÆ’Ã‚Â¢ÃƒÂ¢Ã¢â€šÂ¬Ã…Â¾Ãƒâ€šÃ‚Â¢ÃƒÆ’Ã†â€™Ãƒâ€ Ã¢â‚¬â„¢ÃƒÆ’Ã¢â‚¬Â ÃƒÂ¢Ã¢â€šÂ¬Ã¢â€žÂ¢ÃƒÆ’Ã†â€™ÃƒÂ¢Ã¢â€šÂ¬Ã…Â¡ÃƒÆ’Ã¢â‚¬Å¡Ãƒâ€šÃ‚Â¢ÃƒÆ’Ã†â€™Ãƒâ€ Ã¢â‚¬â„¢ÃƒÆ’Ã¢â‚¬Å¡Ãƒâ€šÃ‚Â¢ÃƒÆ’Ã†â€™Ãƒâ€šÃ‚Â¢ÃƒÆ’Ã‚Â¢ÃƒÂ¢Ã¢â€šÂ¬Ã…Â¡Ãƒâ€šÃ‚Â¬ÃƒÆ’Ã¢â‚¬Â¦Ãƒâ€šÃ‚Â¡ÃƒÆ’Ã†â€™ÃƒÂ¢Ã¢â€šÂ¬Ã…Â¡ÃƒÆ’Ã¢â‚¬Å¡Ãƒâ€šÃ‚Â¬ÃƒÆ’Ã†â€™Ãƒâ€ Ã¢â‚¬â„¢ÃƒÆ’Ã‚Â¢ÃƒÂ¢Ã¢â‚¬Å¡Ã‚Â¬Ãƒâ€¦Ã‚Â¡ÃƒÆ’Ã†â€™ÃƒÂ¢Ã¢â€šÂ¬Ã…Â¡ÃƒÆ’Ã¢â‚¬Å¡Ãƒâ€šÃ‚Â¹"] = "E",
	["ÃƒÆ’Ã†â€™Ãƒâ€ Ã¢â‚¬â„¢ÃƒÆ’Ã¢â‚¬Â ÃƒÂ¢Ã¢â€šÂ¬Ã¢â€žÂ¢ÃƒÆ’Ã†â€™ÃƒÂ¢Ã¢â€šÂ¬Ã‚Â ÃƒÆ’Ã‚Â¢ÃƒÂ¢Ã¢â‚¬Å¡Ã‚Â¬ÃƒÂ¢Ã¢â‚¬Å¾Ã‚Â¢ÃƒÆ’Ã†â€™Ãƒâ€ Ã¢â‚¬â„¢ÃƒÆ’Ã‚Â¢ÃƒÂ¢Ã¢â‚¬Å¡Ã‚Â¬Ãƒâ€šÃ‚Â ÃƒÆ’Ã†â€™Ãƒâ€šÃ‚Â¢ÃƒÆ’Ã‚Â¢ÃƒÂ¢Ã¢â€šÂ¬Ã…Â¡Ãƒâ€šÃ‚Â¬ÃƒÆ’Ã‚Â¢ÃƒÂ¢Ã¢â€šÂ¬Ã…Â¾Ãƒâ€šÃ‚Â¢ÃƒÆ’Ã†â€™Ãƒâ€ Ã¢â‚¬â„¢ÃƒÆ’Ã¢â‚¬Â ÃƒÂ¢Ã¢â€šÂ¬Ã¢â€žÂ¢ÃƒÆ’Ã†â€™Ãƒâ€šÃ‚Â¢ÃƒÆ’Ã‚Â¢ÃƒÂ¢Ã¢â€šÂ¬Ã…Â¡Ãƒâ€šÃ‚Â¬ÃƒÆ’Ã¢â‚¬Â¦Ãƒâ€šÃ‚Â¡ÃƒÆ’Ã†â€™Ãƒâ€ Ã¢â‚¬â„¢ÃƒÆ’Ã‚Â¢ÃƒÂ¢Ã¢â‚¬Å¡Ã‚Â¬Ãƒâ€¦Ã‚Â¡ÃƒÆ’Ã†â€™ÃƒÂ¢Ã¢â€šÂ¬Ã…Â¡ÃƒÆ’Ã¢â‚¬Å¡Ãƒâ€šÃ‚Â­"] = "i",
	["ÃƒÆ’Ã†â€™Ãƒâ€ Ã¢â‚¬â„¢ÃƒÆ’Ã¢â‚¬Â ÃƒÂ¢Ã¢â€šÂ¬Ã¢â€žÂ¢ÃƒÆ’Ã†â€™ÃƒÂ¢Ã¢â€šÂ¬Ã‚Â ÃƒÆ’Ã‚Â¢ÃƒÂ¢Ã¢â‚¬Å¡Ã‚Â¬ÃƒÂ¢Ã¢â‚¬Å¾Ã‚Â¢ÃƒÆ’Ã†â€™Ãƒâ€ Ã¢â‚¬â„¢ÃƒÆ’Ã‚Â¢ÃƒÂ¢Ã¢â‚¬Å¡Ã‚Â¬Ãƒâ€šÃ‚Â ÃƒÆ’Ã†â€™Ãƒâ€šÃ‚Â¢ÃƒÆ’Ã‚Â¢ÃƒÂ¢Ã¢â€šÂ¬Ã…Â¡Ãƒâ€šÃ‚Â¬ÃƒÆ’Ã‚Â¢ÃƒÂ¢Ã¢â€šÂ¬Ã…Â¾Ãƒâ€šÃ‚Â¢ÃƒÆ’Ã†â€™Ãƒâ€ Ã¢â‚¬â„¢ÃƒÆ’Ã¢â‚¬Â ÃƒÂ¢Ã¢â€šÂ¬Ã¢â€žÂ¢ÃƒÆ’Ã†â€™Ãƒâ€šÃ‚Â¢ÃƒÆ’Ã‚Â¢ÃƒÂ¢Ã¢â€šÂ¬Ã…Â¡Ãƒâ€šÃ‚Â¬ÃƒÆ’Ã¢â‚¬Â¦Ãƒâ€šÃ‚Â¡ÃƒÆ’Ã†â€™Ãƒâ€ Ã¢â‚¬â„¢ÃƒÆ’Ã‚Â¢ÃƒÂ¢Ã¢â‚¬Å¡Ã‚Â¬Ãƒâ€¦Ã‚Â¡ÃƒÆ’Ã†â€™ÃƒÂ¢Ã¢â€šÂ¬Ã…Â¡ÃƒÆ’Ã¢â‚¬Å¡Ãƒâ€šÃ‚Â¬"] = "i",
	["ÃƒÆ’Ã†â€™Ãƒâ€ Ã¢â‚¬â„¢ÃƒÆ’Ã¢â‚¬Â ÃƒÂ¢Ã¢â€šÂ¬Ã¢â€žÂ¢ÃƒÆ’Ã†â€™ÃƒÂ¢Ã¢â€šÂ¬Ã‚Â ÃƒÆ’Ã‚Â¢ÃƒÂ¢Ã¢â‚¬Å¡Ã‚Â¬ÃƒÂ¢Ã¢â‚¬Å¾Ã‚Â¢ÃƒÆ’Ã†â€™Ãƒâ€ Ã¢â‚¬â„¢ÃƒÆ’Ã‚Â¢ÃƒÂ¢Ã¢â‚¬Å¡Ã‚Â¬Ãƒâ€šÃ‚Â ÃƒÆ’Ã†â€™Ãƒâ€šÃ‚Â¢ÃƒÆ’Ã‚Â¢ÃƒÂ¢Ã¢â€šÂ¬Ã…Â¡Ãƒâ€šÃ‚Â¬ÃƒÆ’Ã‚Â¢ÃƒÂ¢Ã¢â€šÂ¬Ã…Â¾Ãƒâ€šÃ‚Â¢ÃƒÆ’Ã†â€™Ãƒâ€ Ã¢â‚¬â„¢ÃƒÆ’Ã¢â‚¬Â ÃƒÂ¢Ã¢â€šÂ¬Ã¢â€žÂ¢ÃƒÆ’Ã†â€™Ãƒâ€šÃ‚Â¢ÃƒÆ’Ã‚Â¢ÃƒÂ¢Ã¢â€šÂ¬Ã…Â¡Ãƒâ€šÃ‚Â¬ÃƒÆ’Ã¢â‚¬Â¦Ãƒâ€šÃ‚Â¡ÃƒÆ’Ã†â€™Ãƒâ€ Ã¢â‚¬â„¢ÃƒÆ’Ã‚Â¢ÃƒÂ¢Ã¢â‚¬Å¡Ã‚Â¬Ãƒâ€¦Ã‚Â¡ÃƒÆ’Ã†â€™ÃƒÂ¢Ã¢â€šÂ¬Ã…Â¡ÃƒÆ’Ã¢â‚¬Å¡Ãƒâ€šÃ‚Â®"] = "i",
	["ÃƒÆ’Ã†â€™Ãƒâ€ Ã¢â‚¬â„¢ÃƒÆ’Ã¢â‚¬Â ÃƒÂ¢Ã¢â€šÂ¬Ã¢â€žÂ¢ÃƒÆ’Ã†â€™ÃƒÂ¢Ã¢â€šÂ¬Ã‚Â ÃƒÆ’Ã‚Â¢ÃƒÂ¢Ã¢â‚¬Å¡Ã‚Â¬ÃƒÂ¢Ã¢â‚¬Å¾Ã‚Â¢ÃƒÆ’Ã†â€™Ãƒâ€ Ã¢â‚¬â„¢ÃƒÆ’Ã‚Â¢ÃƒÂ¢Ã¢â‚¬Å¡Ã‚Â¬Ãƒâ€šÃ‚Â ÃƒÆ’Ã†â€™Ãƒâ€šÃ‚Â¢ÃƒÆ’Ã‚Â¢ÃƒÂ¢Ã¢â€šÂ¬Ã…Â¡Ãƒâ€šÃ‚Â¬ÃƒÆ’Ã‚Â¢ÃƒÂ¢Ã¢â€šÂ¬Ã…Â¾Ãƒâ€šÃ‚Â¢ÃƒÆ’Ã†â€™Ãƒâ€ Ã¢â‚¬â„¢ÃƒÆ’Ã¢â‚¬Â ÃƒÂ¢Ã¢â€šÂ¬Ã¢â€žÂ¢ÃƒÆ’Ã†â€™Ãƒâ€šÃ‚Â¢ÃƒÆ’Ã‚Â¢ÃƒÂ¢Ã¢â€šÂ¬Ã…Â¡Ãƒâ€šÃ‚Â¬ÃƒÆ’Ã¢â‚¬Â¦Ãƒâ€šÃ‚Â¡ÃƒÆ’Ã†â€™Ãƒâ€ Ã¢â‚¬â„¢ÃƒÆ’Ã‚Â¢ÃƒÂ¢Ã¢â‚¬Å¡Ã‚Â¬Ãƒâ€¦Ã‚Â¡ÃƒÆ’Ã†â€™ÃƒÂ¢Ã¢â€šÂ¬Ã…Â¡ÃƒÆ’Ã¢â‚¬Å¡Ãƒâ€šÃ‚Â¯"] = "i",
	["ÃƒÆ’Ã†â€™Ãƒâ€ Ã¢â‚¬â„¢ÃƒÆ’Ã¢â‚¬Â ÃƒÂ¢Ã¢â€šÂ¬Ã¢â€žÂ¢ÃƒÆ’Ã†â€™ÃƒÂ¢Ã¢â€šÂ¬Ã‚Â ÃƒÆ’Ã‚Â¢ÃƒÂ¢Ã¢â‚¬Å¡Ã‚Â¬ÃƒÂ¢Ã¢â‚¬Å¾Ã‚Â¢ÃƒÆ’Ã†â€™Ãƒâ€ Ã¢â‚¬â„¢ÃƒÆ’Ã‚Â¢ÃƒÂ¢Ã¢â‚¬Å¡Ã‚Â¬Ãƒâ€šÃ‚Â ÃƒÆ’Ã†â€™Ãƒâ€šÃ‚Â¢ÃƒÆ’Ã‚Â¢ÃƒÂ¢Ã¢â€šÂ¬Ã…Â¡Ãƒâ€šÃ‚Â¬ÃƒÆ’Ã‚Â¢ÃƒÂ¢Ã¢â€šÂ¬Ã…Â¾Ãƒâ€šÃ‚Â¢ÃƒÆ’Ã†â€™Ãƒâ€ Ã¢â‚¬â„¢ÃƒÆ’Ã¢â‚¬Â ÃƒÂ¢Ã¢â€šÂ¬Ã¢â€žÂ¢ÃƒÆ’Ã†â€™Ãƒâ€šÃ‚Â¢ÃƒÆ’Ã‚Â¢ÃƒÂ¢Ã¢â€šÂ¬Ã…Â¡Ãƒâ€šÃ‚Â¬ÃƒÆ’Ã¢â‚¬Â¦Ãƒâ€šÃ‚Â¡ÃƒÆ’Ã†â€™Ãƒâ€ Ã¢â‚¬â„¢ÃƒÆ’Ã‚Â¢ÃƒÂ¢Ã¢â‚¬Å¡Ã‚Â¬Ãƒâ€¦Ã‚Â¡ÃƒÆ’Ã†â€™ÃƒÂ¢Ã¢â€šÂ¬Ã…Â¡ÃƒÆ’Ã¢â‚¬Å¡Ãƒâ€šÃ‚Â"] = "I",
	["ÃƒÆ’Ã†â€™Ãƒâ€ Ã¢â‚¬â„¢ÃƒÆ’Ã¢â‚¬Â ÃƒÂ¢Ã¢â€šÂ¬Ã¢â€žÂ¢ÃƒÆ’Ã†â€™ÃƒÂ¢Ã¢â€šÂ¬Ã‚Â ÃƒÆ’Ã‚Â¢ÃƒÂ¢Ã¢â‚¬Å¡Ã‚Â¬ÃƒÂ¢Ã¢â‚¬Å¾Ã‚Â¢ÃƒÆ’Ã†â€™Ãƒâ€ Ã¢â‚¬â„¢ÃƒÆ’Ã‚Â¢ÃƒÂ¢Ã¢â‚¬Å¡Ã‚Â¬Ãƒâ€šÃ‚Â ÃƒÆ’Ã†â€™Ãƒâ€šÃ‚Â¢ÃƒÆ’Ã‚Â¢ÃƒÂ¢Ã¢â€šÂ¬Ã…Â¡Ãƒâ€šÃ‚Â¬ÃƒÆ’Ã‚Â¢ÃƒÂ¢Ã¢â€šÂ¬Ã…Â¾Ãƒâ€šÃ‚Â¢ÃƒÆ’Ã†â€™Ãƒâ€ Ã¢â‚¬â„¢ÃƒÆ’Ã¢â‚¬Â ÃƒÂ¢Ã¢â€šÂ¬Ã¢â€žÂ¢ÃƒÆ’Ã†â€™Ãƒâ€šÃ‚Â¢ÃƒÆ’Ã‚Â¢ÃƒÂ¢Ã¢â€šÂ¬Ã…Â¡Ãƒâ€šÃ‚Â¬ÃƒÆ’Ã¢â‚¬Å¡Ãƒâ€šÃ‚Â¦ÃƒÆ’Ã†â€™Ãƒâ€ Ã¢â‚¬â„¢ÃƒÆ’Ã¢â‚¬Å¡Ãƒâ€šÃ‚Â¢ÃƒÆ’Ã†â€™Ãƒâ€šÃ‚Â¢ÃƒÆ’Ã‚Â¢ÃƒÂ¢Ã¢â‚¬Å¡Ã‚Â¬Ãƒâ€¦Ã‚Â¡ÃƒÆ’Ã¢â‚¬Å¡Ãƒâ€šÃ‚Â¬ÃƒÆ’Ã†â€™Ãƒâ€šÃ‚Â¢ÃƒÆ’Ã‚Â¢ÃƒÂ¢Ã¢â‚¬Å¡Ã‚Â¬Ãƒâ€¦Ã‚Â¾ÃƒÆ’Ã¢â‚¬Å¡Ãƒâ€šÃ‚Â¢"] = "I",
	["ÃƒÆ’Ã†â€™Ãƒâ€ Ã¢â‚¬â„¢ÃƒÆ’Ã¢â‚¬Â ÃƒÂ¢Ã¢â€šÂ¬Ã¢â€žÂ¢ÃƒÆ’Ã†â€™ÃƒÂ¢Ã¢â€šÂ¬Ã‚Â ÃƒÆ’Ã‚Â¢ÃƒÂ¢Ã¢â‚¬Å¡Ã‚Â¬ÃƒÂ¢Ã¢â‚¬Å¾Ã‚Â¢ÃƒÆ’Ã†â€™Ãƒâ€ Ã¢â‚¬â„¢ÃƒÆ’Ã‚Â¢ÃƒÂ¢Ã¢â‚¬Å¡Ã‚Â¬Ãƒâ€šÃ‚Â ÃƒÆ’Ã†â€™Ãƒâ€šÃ‚Â¢ÃƒÆ’Ã‚Â¢ÃƒÂ¢Ã¢â€šÂ¬Ã…Â¡Ãƒâ€šÃ‚Â¬ÃƒÆ’Ã‚Â¢ÃƒÂ¢Ã¢â€šÂ¬Ã…Â¾Ãƒâ€šÃ‚Â¢ÃƒÆ’Ã†â€™Ãƒâ€ Ã¢â‚¬â„¢ÃƒÆ’Ã¢â‚¬Â ÃƒÂ¢Ã¢â€šÂ¬Ã¢â€žÂ¢ÃƒÆ’Ã†â€™Ãƒâ€šÃ‚Â¢ÃƒÆ’Ã‚Â¢ÃƒÂ¢Ã¢â€šÂ¬Ã…Â¡Ãƒâ€šÃ‚Â¬ÃƒÆ’Ã¢â‚¬Å¡Ãƒâ€šÃ‚Â¦ÃƒÆ’Ã†â€™Ãƒâ€ Ã¢â‚¬â„¢ÃƒÆ’Ã‚Â¢ÃƒÂ¢Ã¢â‚¬Å¡Ã‚Â¬Ãƒâ€¦Ã‚Â¡ÃƒÆ’Ã†â€™ÃƒÂ¢Ã¢â€šÂ¬Ã…Â¡ÃƒÆ’Ã¢â‚¬Å¡Ãƒâ€šÃ‚Â½"] = "I",
	["ÃƒÆ’Ã†â€™Ãƒâ€ Ã¢â‚¬â„¢ÃƒÆ’Ã¢â‚¬Â ÃƒÂ¢Ã¢â€šÂ¬Ã¢â€žÂ¢ÃƒÆ’Ã†â€™ÃƒÂ¢Ã¢â€šÂ¬Ã‚Â ÃƒÆ’Ã‚Â¢ÃƒÂ¢Ã¢â‚¬Å¡Ã‚Â¬ÃƒÂ¢Ã¢â‚¬Å¾Ã‚Â¢ÃƒÆ’Ã†â€™Ãƒâ€ Ã¢â‚¬â„¢ÃƒÆ’Ã‚Â¢ÃƒÂ¢Ã¢â‚¬Å¡Ã‚Â¬Ãƒâ€šÃ‚Â ÃƒÆ’Ã†â€™Ãƒâ€šÃ‚Â¢ÃƒÆ’Ã‚Â¢ÃƒÂ¢Ã¢â€šÂ¬Ã…Â¡Ãƒâ€šÃ‚Â¬ÃƒÆ’Ã‚Â¢ÃƒÂ¢Ã¢â€šÂ¬Ã…Â¾Ãƒâ€šÃ‚Â¢ÃƒÆ’Ã†â€™Ãƒâ€ Ã¢â‚¬â„¢ÃƒÆ’Ã¢â‚¬Â ÃƒÂ¢Ã¢â€šÂ¬Ã¢â€žÂ¢ÃƒÆ’Ã†â€™Ãƒâ€šÃ‚Â¢ÃƒÆ’Ã‚Â¢ÃƒÂ¢Ã¢â€šÂ¬Ã…Â¡Ãƒâ€šÃ‚Â¬ÃƒÆ’Ã¢â‚¬Â¦Ãƒâ€šÃ‚Â¡ÃƒÆ’Ã†â€™Ãƒâ€ Ã¢â‚¬â„¢ÃƒÆ’Ã‚Â¢ÃƒÂ¢Ã¢â‚¬Å¡Ã‚Â¬Ãƒâ€¦Ã‚Â¡ÃƒÆ’Ã†â€™ÃƒÂ¢Ã¢â€šÂ¬Ã…Â¡ÃƒÆ’Ã¢â‚¬Å¡Ãƒâ€šÃ‚Â"] = "I",
	["ÃƒÆ’Ã†â€™Ãƒâ€ Ã¢â‚¬â„¢ÃƒÆ’Ã¢â‚¬Â ÃƒÂ¢Ã¢â€šÂ¬Ã¢â€žÂ¢ÃƒÆ’Ã†â€™ÃƒÂ¢Ã¢â€šÂ¬Ã‚Â ÃƒÆ’Ã‚Â¢ÃƒÂ¢Ã¢â‚¬Å¡Ã‚Â¬ÃƒÂ¢Ã¢â‚¬Å¾Ã‚Â¢ÃƒÆ’Ã†â€™Ãƒâ€ Ã¢â‚¬â„¢ÃƒÆ’Ã‚Â¢ÃƒÂ¢Ã¢â‚¬Å¡Ã‚Â¬Ãƒâ€šÃ‚Â ÃƒÆ’Ã†â€™Ãƒâ€šÃ‚Â¢ÃƒÆ’Ã‚Â¢ÃƒÂ¢Ã¢â€šÂ¬Ã…Â¡Ãƒâ€šÃ‚Â¬ÃƒÆ’Ã‚Â¢ÃƒÂ¢Ã¢â€šÂ¬Ã…Â¾Ãƒâ€šÃ‚Â¢ÃƒÆ’Ã†â€™Ãƒâ€ Ã¢â‚¬â„¢ÃƒÆ’Ã¢â‚¬Â ÃƒÂ¢Ã¢â€šÂ¬Ã¢â€žÂ¢ÃƒÆ’Ã†â€™Ãƒâ€šÃ‚Â¢ÃƒÆ’Ã‚Â¢ÃƒÂ¢Ã¢â€šÂ¬Ã…Â¡Ãƒâ€šÃ‚Â¬ÃƒÆ’Ã¢â‚¬Â¦Ãƒâ€šÃ‚Â¡ÃƒÆ’Ã†â€™Ãƒâ€ Ã¢â‚¬â„¢ÃƒÆ’Ã‚Â¢ÃƒÂ¢Ã¢â‚¬Å¡Ã‚Â¬Ãƒâ€¦Ã‚Â¡ÃƒÆ’Ã†â€™ÃƒÂ¢Ã¢â€šÂ¬Ã…Â¡ÃƒÆ’Ã¢â‚¬Å¡Ãƒâ€šÃ‚Â³"] = "o",
	["ÃƒÆ’Ã†â€™Ãƒâ€ Ã¢â‚¬â„¢ÃƒÆ’Ã¢â‚¬Â ÃƒÂ¢Ã¢â€šÂ¬Ã¢â€žÂ¢ÃƒÆ’Ã†â€™ÃƒÂ¢Ã¢â€šÂ¬Ã‚Â ÃƒÆ’Ã‚Â¢ÃƒÂ¢Ã¢â‚¬Å¡Ã‚Â¬ÃƒÂ¢Ã¢â‚¬Å¾Ã‚Â¢ÃƒÆ’Ã†â€™Ãƒâ€ Ã¢â‚¬â„¢ÃƒÆ’Ã‚Â¢ÃƒÂ¢Ã¢â‚¬Å¡Ã‚Â¬Ãƒâ€šÃ‚Â ÃƒÆ’Ã†â€™Ãƒâ€šÃ‚Â¢ÃƒÆ’Ã‚Â¢ÃƒÂ¢Ã¢â€šÂ¬Ã…Â¡Ãƒâ€šÃ‚Â¬ÃƒÆ’Ã‚Â¢ÃƒÂ¢Ã¢â€šÂ¬Ã…Â¾Ãƒâ€šÃ‚Â¢ÃƒÆ’Ã†â€™Ãƒâ€ Ã¢â‚¬â„¢ÃƒÆ’Ã¢â‚¬Â ÃƒÂ¢Ã¢â€šÂ¬Ã¢â€žÂ¢ÃƒÆ’Ã†â€™Ãƒâ€šÃ‚Â¢ÃƒÆ’Ã‚Â¢ÃƒÂ¢Ã¢â€šÂ¬Ã…Â¡Ãƒâ€šÃ‚Â¬ÃƒÆ’Ã¢â‚¬Â¦Ãƒâ€šÃ‚Â¡ÃƒÆ’Ã†â€™Ãƒâ€ Ã¢â‚¬â„¢ÃƒÆ’Ã‚Â¢ÃƒÂ¢Ã¢â‚¬Å¡Ã‚Â¬Ãƒâ€¦Ã‚Â¡ÃƒÆ’Ã†â€™ÃƒÂ¢Ã¢â€šÂ¬Ã…Â¡ÃƒÆ’Ã¢â‚¬Å¡Ãƒâ€šÃ‚Â²"] = "o",
	["ÃƒÆ’Ã†â€™Ãƒâ€ Ã¢â‚¬â„¢ÃƒÆ’Ã¢â‚¬Â ÃƒÂ¢Ã¢â€šÂ¬Ã¢â€žÂ¢ÃƒÆ’Ã†â€™ÃƒÂ¢Ã¢â€šÂ¬Ã‚Â ÃƒÆ’Ã‚Â¢ÃƒÂ¢Ã¢â‚¬Å¡Ã‚Â¬ÃƒÂ¢Ã¢â‚¬Å¾Ã‚Â¢ÃƒÆ’Ã†â€™Ãƒâ€ Ã¢â‚¬â„¢ÃƒÆ’Ã‚Â¢ÃƒÂ¢Ã¢â‚¬Å¡Ã‚Â¬Ãƒâ€šÃ‚Â ÃƒÆ’Ã†â€™Ãƒâ€šÃ‚Â¢ÃƒÆ’Ã‚Â¢ÃƒÂ¢Ã¢â€šÂ¬Ã…Â¡Ãƒâ€šÃ‚Â¬ÃƒÆ’Ã‚Â¢ÃƒÂ¢Ã¢â€šÂ¬Ã…Â¾Ãƒâ€šÃ‚Â¢ÃƒÆ’Ã†â€™Ãƒâ€ Ã¢â‚¬â„¢ÃƒÆ’Ã¢â‚¬Â ÃƒÂ¢Ã¢â€šÂ¬Ã¢â€žÂ¢ÃƒÆ’Ã†â€™Ãƒâ€šÃ‚Â¢ÃƒÆ’Ã‚Â¢ÃƒÂ¢Ã¢â€šÂ¬Ã…Â¡Ãƒâ€šÃ‚Â¬ÃƒÆ’Ã¢â‚¬Â¦Ãƒâ€šÃ‚Â¡ÃƒÆ’Ã†â€™Ãƒâ€ Ã¢â‚¬â„¢ÃƒÆ’Ã‚Â¢ÃƒÂ¢Ã¢â‚¬Å¡Ã‚Â¬Ãƒâ€¦Ã‚Â¡ÃƒÆ’Ã†â€™ÃƒÂ¢Ã¢â€šÂ¬Ã…Â¡ÃƒÆ’Ã¢â‚¬Å¡Ãƒâ€šÃ‚Âµ"] = "o",
	["ÃƒÆ’Ã†â€™Ãƒâ€ Ã¢â‚¬â„¢ÃƒÆ’Ã¢â‚¬Â ÃƒÂ¢Ã¢â€šÂ¬Ã¢â€žÂ¢ÃƒÆ’Ã†â€™ÃƒÂ¢Ã¢â€šÂ¬Ã‚Â ÃƒÆ’Ã‚Â¢ÃƒÂ¢Ã¢â‚¬Å¡Ã‚Â¬ÃƒÂ¢Ã¢â‚¬Å¾Ã‚Â¢ÃƒÆ’Ã†â€™Ãƒâ€ Ã¢â‚¬â„¢ÃƒÆ’Ã‚Â¢ÃƒÂ¢Ã¢â‚¬Å¡Ã‚Â¬Ãƒâ€šÃ‚Â ÃƒÆ’Ã†â€™Ãƒâ€šÃ‚Â¢ÃƒÆ’Ã‚Â¢ÃƒÂ¢Ã¢â€šÂ¬Ã…Â¡Ãƒâ€šÃ‚Â¬ÃƒÆ’Ã‚Â¢ÃƒÂ¢Ã¢â€šÂ¬Ã…Â¾Ãƒâ€šÃ‚Â¢ÃƒÆ’Ã†â€™Ãƒâ€ Ã¢â‚¬â„¢ÃƒÆ’Ã¢â‚¬Â ÃƒÂ¢Ã¢â€šÂ¬Ã¢â€žÂ¢ÃƒÆ’Ã†â€™Ãƒâ€šÃ‚Â¢ÃƒÆ’Ã‚Â¢ÃƒÂ¢Ã¢â€šÂ¬Ã…Â¡Ãƒâ€šÃ‚Â¬ÃƒÆ’Ã¢â‚¬Â¦Ãƒâ€šÃ‚Â¡ÃƒÆ’Ã†â€™Ãƒâ€ Ã¢â‚¬â„¢ÃƒÆ’Ã‚Â¢ÃƒÂ¢Ã¢â‚¬Å¡Ã‚Â¬Ãƒâ€¦Ã‚Â¡ÃƒÆ’Ã†â€™ÃƒÂ¢Ã¢â€šÂ¬Ã…Â¡ÃƒÆ’Ã¢â‚¬Å¡Ãƒâ€šÃ‚Â´"] = "o",
	["ÃƒÆ’Ã†â€™Ãƒâ€ Ã¢â‚¬â„¢ÃƒÆ’Ã¢â‚¬Â ÃƒÂ¢Ã¢â€šÂ¬Ã¢â€žÂ¢ÃƒÆ’Ã†â€™ÃƒÂ¢Ã¢â€šÂ¬Ã‚Â ÃƒÆ’Ã‚Â¢ÃƒÂ¢Ã¢â‚¬Å¡Ã‚Â¬ÃƒÂ¢Ã¢â‚¬Å¾Ã‚Â¢ÃƒÆ’Ã†â€™Ãƒâ€ Ã¢â‚¬â„¢ÃƒÆ’Ã‚Â¢ÃƒÂ¢Ã¢â‚¬Å¡Ã‚Â¬Ãƒâ€šÃ‚Â ÃƒÆ’Ã†â€™Ãƒâ€šÃ‚Â¢ÃƒÆ’Ã‚Â¢ÃƒÂ¢Ã¢â€šÂ¬Ã…Â¡Ãƒâ€šÃ‚Â¬ÃƒÆ’Ã‚Â¢ÃƒÂ¢Ã¢â€šÂ¬Ã…Â¾Ãƒâ€šÃ‚Â¢ÃƒÆ’Ã†â€™Ãƒâ€ Ã¢â‚¬â„¢ÃƒÆ’Ã¢â‚¬Â ÃƒÂ¢Ã¢â€šÂ¬Ã¢â€žÂ¢ÃƒÆ’Ã†â€™Ãƒâ€šÃ‚Â¢ÃƒÆ’Ã‚Â¢ÃƒÂ¢Ã¢â€šÂ¬Ã…Â¡Ãƒâ€šÃ‚Â¬ÃƒÆ’Ã¢â‚¬Â¦Ãƒâ€šÃ‚Â¡ÃƒÆ’Ã†â€™Ãƒâ€ Ã¢â‚¬â„¢ÃƒÆ’Ã‚Â¢ÃƒÂ¢Ã¢â‚¬Å¡Ã‚Â¬Ãƒâ€¦Ã‚Â¡ÃƒÆ’Ã†â€™ÃƒÂ¢Ã¢â€šÂ¬Ã…Â¡ÃƒÆ’Ã¢â‚¬Å¡Ãƒâ€šÃ‚Â¶"] = "o",
	["ÃƒÆ’Ã†â€™Ãƒâ€ Ã¢â‚¬â„¢ÃƒÆ’Ã¢â‚¬Â ÃƒÂ¢Ã¢â€šÂ¬Ã¢â€žÂ¢ÃƒÆ’Ã†â€™ÃƒÂ¢Ã¢â€šÂ¬Ã‚Â ÃƒÆ’Ã‚Â¢ÃƒÂ¢Ã¢â‚¬Å¡Ã‚Â¬ÃƒÂ¢Ã¢â‚¬Å¾Ã‚Â¢ÃƒÆ’Ã†â€™Ãƒâ€ Ã¢â‚¬â„¢ÃƒÆ’Ã‚Â¢ÃƒÂ¢Ã¢â‚¬Å¡Ã‚Â¬Ãƒâ€šÃ‚Â ÃƒÆ’Ã†â€™Ãƒâ€šÃ‚Â¢ÃƒÆ’Ã‚Â¢ÃƒÂ¢Ã¢â€šÂ¬Ã…Â¡Ãƒâ€šÃ‚Â¬ÃƒÆ’Ã‚Â¢ÃƒÂ¢Ã¢â€šÂ¬Ã…Â¾Ãƒâ€šÃ‚Â¢ÃƒÆ’Ã†â€™Ãƒâ€ Ã¢â‚¬â„¢ÃƒÆ’Ã¢â‚¬Â ÃƒÂ¢Ã¢â€šÂ¬Ã¢â€žÂ¢ÃƒÆ’Ã†â€™ÃƒÂ¢Ã¢â€šÂ¬Ã…Â¡ÃƒÆ’Ã¢â‚¬Å¡Ãƒâ€šÃ‚Â¢ÃƒÆ’Ã†â€™Ãƒâ€ Ã¢â‚¬â„¢ÃƒÆ’Ã¢â‚¬Å¡Ãƒâ€šÃ‚Â¢ÃƒÆ’Ã†â€™Ãƒâ€šÃ‚Â¢ÃƒÆ’Ã‚Â¢ÃƒÂ¢Ã¢â€šÂ¬Ã…Â¡Ãƒâ€šÃ‚Â¬ÃƒÆ’Ã¢â‚¬Â¦Ãƒâ€šÃ‚Â¡ÃƒÆ’Ã†â€™ÃƒÂ¢Ã¢â€šÂ¬Ã…Â¡ÃƒÆ’Ã¢â‚¬Å¡Ãƒâ€šÃ‚Â¬ÃƒÆ’Ã†â€™Ãƒâ€ Ã¢â‚¬â„¢ÃƒÆ’Ã‚Â¢ÃƒÂ¢Ã¢â‚¬Å¡Ã‚Â¬Ãƒâ€šÃ‚Â¦ÃƒÆ’Ã†â€™Ãƒâ€šÃ‚Â¢ÃƒÆ’Ã‚Â¢ÃƒÂ¢Ã¢â€šÂ¬Ã…Â¡Ãƒâ€šÃ‚Â¬ÃƒÆ’Ã¢â‚¬Â¦ÃƒÂ¢Ã¢â€šÂ¬Ã…â€œ"] = "O",
	["ÃƒÆ’Ã†â€™Ãƒâ€ Ã¢â‚¬â„¢ÃƒÆ’Ã¢â‚¬Â ÃƒÂ¢Ã¢â€šÂ¬Ã¢â€žÂ¢ÃƒÆ’Ã†â€™ÃƒÂ¢Ã¢â€šÂ¬Ã‚Â ÃƒÆ’Ã‚Â¢ÃƒÂ¢Ã¢â‚¬Å¡Ã‚Â¬ÃƒÂ¢Ã¢â‚¬Å¾Ã‚Â¢ÃƒÆ’Ã†â€™Ãƒâ€ Ã¢â‚¬â„¢ÃƒÆ’Ã‚Â¢ÃƒÂ¢Ã¢â‚¬Å¡Ã‚Â¬Ãƒâ€šÃ‚Â ÃƒÆ’Ã†â€™Ãƒâ€šÃ‚Â¢ÃƒÆ’Ã‚Â¢ÃƒÂ¢Ã¢â€šÂ¬Ã…Â¡Ãƒâ€šÃ‚Â¬ÃƒÆ’Ã‚Â¢ÃƒÂ¢Ã¢â€šÂ¬Ã…Â¾Ãƒâ€šÃ‚Â¢ÃƒÆ’Ã†â€™Ãƒâ€ Ã¢â‚¬â„¢ÃƒÆ’Ã¢â‚¬Â ÃƒÂ¢Ã¢â€šÂ¬Ã¢â€žÂ¢ÃƒÆ’Ã†â€™ÃƒÂ¢Ã¢â€šÂ¬Ã…Â¡ÃƒÆ’Ã¢â‚¬Å¡Ãƒâ€šÃ‚Â¢ÃƒÆ’Ã†â€™Ãƒâ€ Ã¢â‚¬â„¢ÃƒÆ’Ã¢â‚¬Å¡Ãƒâ€šÃ‚Â¢ÃƒÆ’Ã†â€™Ãƒâ€šÃ‚Â¢ÃƒÆ’Ã‚Â¢ÃƒÂ¢Ã¢â€šÂ¬Ã…Â¡Ãƒâ€šÃ‚Â¬ÃƒÆ’Ã¢â‚¬Â¦Ãƒâ€šÃ‚Â¡ÃƒÆ’Ã†â€™ÃƒÂ¢Ã¢â€šÂ¬Ã…Â¡ÃƒÆ’Ã¢â‚¬Å¡Ãƒâ€šÃ‚Â¬ÃƒÆ’Ã†â€™Ãƒâ€ Ã¢â‚¬â„¢ÃƒÆ’Ã¢â‚¬Å¡Ãƒâ€šÃ‚Â¢ÃƒÆ’Ã†â€™Ãƒâ€šÃ‚Â¢ÃƒÆ’Ã‚Â¢ÃƒÂ¢Ã¢â€šÂ¬Ã…Â¡Ãƒâ€šÃ‚Â¬ÃƒÆ’Ã¢â‚¬Â¦Ãƒâ€šÃ‚Â¾ÃƒÆ’Ã†â€™ÃƒÂ¢Ã¢â€šÂ¬Ã…Â¡ÃƒÆ’Ã¢â‚¬Å¡Ãƒâ€šÃ‚Â¢"] = "O",
	["ÃƒÆ’Ã†â€™Ãƒâ€ Ã¢â‚¬â„¢ÃƒÆ’Ã¢â‚¬Â ÃƒÂ¢Ã¢â€šÂ¬Ã¢â€žÂ¢ÃƒÆ’Ã†â€™ÃƒÂ¢Ã¢â€šÂ¬Ã‚Â ÃƒÆ’Ã‚Â¢ÃƒÂ¢Ã¢â‚¬Å¡Ã‚Â¬ÃƒÂ¢Ã¢â‚¬Å¾Ã‚Â¢ÃƒÆ’Ã†â€™Ãƒâ€ Ã¢â‚¬â„¢ÃƒÆ’Ã‚Â¢ÃƒÂ¢Ã¢â‚¬Å¡Ã‚Â¬Ãƒâ€šÃ‚Â ÃƒÆ’Ã†â€™Ãƒâ€šÃ‚Â¢ÃƒÆ’Ã‚Â¢ÃƒÂ¢Ã¢â€šÂ¬Ã…Â¡Ãƒâ€šÃ‚Â¬ÃƒÆ’Ã‚Â¢ÃƒÂ¢Ã¢â€šÂ¬Ã…Â¾Ãƒâ€šÃ‚Â¢ÃƒÆ’Ã†â€™Ãƒâ€ Ã¢â‚¬â„¢ÃƒÆ’Ã¢â‚¬Â ÃƒÂ¢Ã¢â€šÂ¬Ã¢â€žÂ¢ÃƒÆ’Ã†â€™ÃƒÂ¢Ã¢â€šÂ¬Ã…Â¡ÃƒÆ’Ã¢â‚¬Å¡Ãƒâ€šÃ‚Â¢ÃƒÆ’Ã†â€™Ãƒâ€ Ã¢â‚¬â„¢ÃƒÆ’Ã¢â‚¬Å¡Ãƒâ€šÃ‚Â¢ÃƒÆ’Ã†â€™Ãƒâ€šÃ‚Â¢ÃƒÆ’Ã‚Â¢ÃƒÂ¢Ã¢â€šÂ¬Ã…Â¡Ãƒâ€šÃ‚Â¬ÃƒÆ’Ã¢â‚¬Â¦Ãƒâ€šÃ‚Â¡ÃƒÆ’Ã†â€™ÃƒÂ¢Ã¢â€šÂ¬Ã…Â¡ÃƒÆ’Ã¢â‚¬Å¡Ãƒâ€šÃ‚Â¬ÃƒÆ’Ã†â€™Ãƒâ€ Ã¢â‚¬â„¢ÃƒÆ’Ã‚Â¢ÃƒÂ¢Ã¢â‚¬Å¡Ã‚Â¬Ãƒâ€¦Ã‚Â¡ÃƒÆ’Ã†â€™ÃƒÂ¢Ã¢â€šÂ¬Ã…Â¡ÃƒÆ’Ã¢â‚¬Å¡Ãƒâ€šÃ‚Â¢"] = "O",
	["ÃƒÆ’Ã†â€™Ãƒâ€ Ã¢â‚¬â„¢ÃƒÆ’Ã¢â‚¬Â ÃƒÂ¢Ã¢â€šÂ¬Ã¢â€žÂ¢ÃƒÆ’Ã†â€™ÃƒÂ¢Ã¢â€šÂ¬Ã‚Â ÃƒÆ’Ã‚Â¢ÃƒÂ¢Ã¢â‚¬Å¡Ã‚Â¬ÃƒÂ¢Ã¢â‚¬Å¾Ã‚Â¢ÃƒÆ’Ã†â€™Ãƒâ€ Ã¢â‚¬â„¢ÃƒÆ’Ã‚Â¢ÃƒÂ¢Ã¢â‚¬Å¡Ã‚Â¬Ãƒâ€šÃ‚Â ÃƒÆ’Ã†â€™Ãƒâ€šÃ‚Â¢ÃƒÆ’Ã‚Â¢ÃƒÂ¢Ã¢â€šÂ¬Ã…Â¡Ãƒâ€šÃ‚Â¬ÃƒÆ’Ã‚Â¢ÃƒÂ¢Ã¢â€šÂ¬Ã…Â¾Ãƒâ€šÃ‚Â¢ÃƒÆ’Ã†â€™Ãƒâ€ Ã¢â‚¬â„¢ÃƒÆ’Ã¢â‚¬Â ÃƒÂ¢Ã¢â€šÂ¬Ã¢â€žÂ¢ÃƒÆ’Ã†â€™ÃƒÂ¢Ã¢â€šÂ¬Ã…Â¡ÃƒÆ’Ã¢â‚¬Å¡Ãƒâ€šÃ‚Â¢ÃƒÆ’Ã†â€™Ãƒâ€ Ã¢â‚¬â„¢ÃƒÆ’Ã¢â‚¬Å¡Ãƒâ€šÃ‚Â¢ÃƒÆ’Ã†â€™Ãƒâ€šÃ‚Â¢ÃƒÆ’Ã‚Â¢ÃƒÂ¢Ã¢â€šÂ¬Ã…Â¡Ãƒâ€šÃ‚Â¬ÃƒÆ’Ã¢â‚¬Â¦Ãƒâ€šÃ‚Â¡ÃƒÆ’Ã†â€™ÃƒÂ¢Ã¢â€šÂ¬Ã…Â¡ÃƒÆ’Ã¢â‚¬Å¡Ãƒâ€šÃ‚Â¬ÃƒÆ’Ã†â€™Ãƒâ€ Ã¢â‚¬â„¢ÃƒÆ’Ã‚Â¢ÃƒÂ¢Ã¢â‚¬Å¡Ã‚Â¬Ãƒâ€¦Ã‚Â¡ÃƒÆ’Ã†â€™ÃƒÂ¢Ã¢â€šÂ¬Ã…Â¡ÃƒÆ’Ã¢â‚¬Å¡Ãƒâ€šÃ‚Â"] = "O",
	["ÃƒÆ’Ã†â€™Ãƒâ€ Ã¢â‚¬â„¢ÃƒÆ’Ã¢â‚¬Â ÃƒÂ¢Ã¢â€šÂ¬Ã¢â€žÂ¢ÃƒÆ’Ã†â€™ÃƒÂ¢Ã¢â€šÂ¬Ã‚Â ÃƒÆ’Ã‚Â¢ÃƒÂ¢Ã¢â‚¬Å¡Ã‚Â¬ÃƒÂ¢Ã¢â‚¬Å¾Ã‚Â¢ÃƒÆ’Ã†â€™Ãƒâ€ Ã¢â‚¬â„¢ÃƒÆ’Ã‚Â¢ÃƒÂ¢Ã¢â‚¬Å¡Ã‚Â¬Ãƒâ€šÃ‚Â ÃƒÆ’Ã†â€™Ãƒâ€šÃ‚Â¢ÃƒÆ’Ã‚Â¢ÃƒÂ¢Ã¢â€šÂ¬Ã…Â¡Ãƒâ€šÃ‚Â¬ÃƒÆ’Ã‚Â¢ÃƒÂ¢Ã¢â€šÂ¬Ã…Â¾Ãƒâ€šÃ‚Â¢ÃƒÆ’Ã†â€™Ãƒâ€ Ã¢â‚¬â„¢ÃƒÆ’Ã¢â‚¬Â ÃƒÂ¢Ã¢â€šÂ¬Ã¢â€žÂ¢ÃƒÆ’Ã†â€™ÃƒÂ¢Ã¢â€šÂ¬Ã…Â¡ÃƒÆ’Ã¢â‚¬Å¡Ãƒâ€šÃ‚Â¢ÃƒÆ’Ã†â€™Ãƒâ€ Ã¢â‚¬â„¢ÃƒÆ’Ã¢â‚¬Å¡Ãƒâ€šÃ‚Â¢ÃƒÆ’Ã†â€™Ãƒâ€šÃ‚Â¢ÃƒÆ’Ã‚Â¢ÃƒÂ¢Ã¢â€šÂ¬Ã…Â¡Ãƒâ€šÃ‚Â¬ÃƒÆ’Ã¢â‚¬Â¦Ãƒâ€šÃ‚Â¡ÃƒÆ’Ã†â€™ÃƒÂ¢Ã¢â€šÂ¬Ã…Â¡ÃƒÆ’Ã¢â‚¬Å¡Ãƒâ€šÃ‚Â¬ÃƒÆ’Ã†â€™Ãƒâ€ Ã¢â‚¬â„¢ÃƒÆ’Ã¢â‚¬Å¡Ãƒâ€šÃ‚Â¢ÃƒÆ’Ã†â€™Ãƒâ€šÃ‚Â¢ÃƒÆ’Ã‚Â¢ÃƒÂ¢Ã¢â‚¬Å¡Ã‚Â¬Ãƒâ€¦Ã‚Â¡ÃƒÆ’Ã¢â‚¬Å¡Ãƒâ€šÃ‚Â¬ÃƒÆ’Ã†â€™ÃƒÂ¢Ã¢â€šÂ¬Ã‚Â¦ÃƒÆ’Ã‚Â¢ÃƒÂ¢Ã¢â‚¬Å¡Ã‚Â¬Ãƒâ€¦Ã¢â‚¬Å“"] = "O",
	["ÃƒÆ’Ã†â€™Ãƒâ€ Ã¢â‚¬â„¢ÃƒÆ’Ã¢â‚¬Â ÃƒÂ¢Ã¢â€šÂ¬Ã¢â€žÂ¢ÃƒÆ’Ã†â€™ÃƒÂ¢Ã¢â€šÂ¬Ã‚Â ÃƒÆ’Ã‚Â¢ÃƒÂ¢Ã¢â‚¬Å¡Ã‚Â¬ÃƒÂ¢Ã¢â‚¬Å¾Ã‚Â¢ÃƒÆ’Ã†â€™Ãƒâ€ Ã¢â‚¬â„¢ÃƒÆ’Ã‚Â¢ÃƒÂ¢Ã¢â‚¬Å¡Ã‚Â¬Ãƒâ€šÃ‚Â ÃƒÆ’Ã†â€™Ãƒâ€šÃ‚Â¢ÃƒÆ’Ã‚Â¢ÃƒÂ¢Ã¢â€šÂ¬Ã…Â¡Ãƒâ€šÃ‚Â¬ÃƒÆ’Ã‚Â¢ÃƒÂ¢Ã¢â€šÂ¬Ã…Â¾Ãƒâ€šÃ‚Â¢ÃƒÆ’Ã†â€™Ãƒâ€ Ã¢â‚¬â„¢ÃƒÆ’Ã¢â‚¬Â ÃƒÂ¢Ã¢â€šÂ¬Ã¢â€žÂ¢ÃƒÆ’Ã†â€™Ãƒâ€šÃ‚Â¢ÃƒÆ’Ã‚Â¢ÃƒÂ¢Ã¢â€šÂ¬Ã…Â¡Ãƒâ€šÃ‚Â¬ÃƒÆ’Ã¢â‚¬Â¦Ãƒâ€šÃ‚Â¡ÃƒÆ’Ã†â€™Ãƒâ€ Ã¢â‚¬â„¢ÃƒÆ’Ã‚Â¢ÃƒÂ¢Ã¢â‚¬Å¡Ã‚Â¬Ãƒâ€¦Ã‚Â¡ÃƒÆ’Ã†â€™ÃƒÂ¢Ã¢â€šÂ¬Ã…Â¡ÃƒÆ’Ã¢â‚¬Å¡Ãƒâ€šÃ‚Âº"] = "u",
	["ÃƒÆ’Ã†â€™Ãƒâ€ Ã¢â‚¬â„¢ÃƒÆ’Ã¢â‚¬Â ÃƒÂ¢Ã¢â€šÂ¬Ã¢â€žÂ¢ÃƒÆ’Ã†â€™ÃƒÂ¢Ã¢â€šÂ¬Ã‚Â ÃƒÆ’Ã‚Â¢ÃƒÂ¢Ã¢â‚¬Å¡Ã‚Â¬ÃƒÂ¢Ã¢â‚¬Å¾Ã‚Â¢ÃƒÆ’Ã†â€™Ãƒâ€ Ã¢â‚¬â„¢ÃƒÆ’Ã‚Â¢ÃƒÂ¢Ã¢â‚¬Å¡Ã‚Â¬Ãƒâ€šÃ‚Â ÃƒÆ’Ã†â€™Ãƒâ€šÃ‚Â¢ÃƒÆ’Ã‚Â¢ÃƒÂ¢Ã¢â€šÂ¬Ã…Â¡Ãƒâ€šÃ‚Â¬ÃƒÆ’Ã‚Â¢ÃƒÂ¢Ã¢â€šÂ¬Ã…Â¾Ãƒâ€šÃ‚Â¢ÃƒÆ’Ã†â€™Ãƒâ€ Ã¢â‚¬â„¢ÃƒÆ’Ã¢â‚¬Â ÃƒÂ¢Ã¢â€šÂ¬Ã¢â€žÂ¢ÃƒÆ’Ã†â€™Ãƒâ€šÃ‚Â¢ÃƒÆ’Ã‚Â¢ÃƒÂ¢Ã¢â€šÂ¬Ã…Â¡Ãƒâ€šÃ‚Â¬ÃƒÆ’Ã¢â‚¬Â¦Ãƒâ€šÃ‚Â¡ÃƒÆ’Ã†â€™Ãƒâ€ Ã¢â‚¬â„¢ÃƒÆ’Ã‚Â¢ÃƒÂ¢Ã¢â‚¬Å¡Ã‚Â¬Ãƒâ€¦Ã‚Â¡ÃƒÆ’Ã†â€™ÃƒÂ¢Ã¢â€šÂ¬Ã…Â¡ÃƒÆ’Ã¢â‚¬Å¡Ãƒâ€šÃ‚Â¹"] = "u",
	["ÃƒÆ’Ã†â€™Ãƒâ€ Ã¢â‚¬â„¢ÃƒÆ’Ã¢â‚¬Â ÃƒÂ¢Ã¢â€šÂ¬Ã¢â€žÂ¢ÃƒÆ’Ã†â€™ÃƒÂ¢Ã¢â€šÂ¬Ã‚Â ÃƒÆ’Ã‚Â¢ÃƒÂ¢Ã¢â‚¬Å¡Ã‚Â¬ÃƒÂ¢Ã¢â‚¬Å¾Ã‚Â¢ÃƒÆ’Ã†â€™Ãƒâ€ Ã¢â‚¬â„¢ÃƒÆ’Ã‚Â¢ÃƒÂ¢Ã¢â‚¬Å¡Ã‚Â¬Ãƒâ€šÃ‚Â ÃƒÆ’Ã†â€™Ãƒâ€šÃ‚Â¢ÃƒÆ’Ã‚Â¢ÃƒÂ¢Ã¢â€šÂ¬Ã…Â¡Ãƒâ€šÃ‚Â¬ÃƒÆ’Ã‚Â¢ÃƒÂ¢Ã¢â€šÂ¬Ã…Â¾Ãƒâ€šÃ‚Â¢ÃƒÆ’Ã†â€™Ãƒâ€ Ã¢â‚¬â„¢ÃƒÆ’Ã¢â‚¬Â ÃƒÂ¢Ã¢â€šÂ¬Ã¢â€žÂ¢ÃƒÆ’Ã†â€™Ãƒâ€šÃ‚Â¢ÃƒÆ’Ã‚Â¢ÃƒÂ¢Ã¢â€šÂ¬Ã…Â¡Ãƒâ€šÃ‚Â¬ÃƒÆ’Ã¢â‚¬Â¦Ãƒâ€šÃ‚Â¡ÃƒÆ’Ã†â€™Ãƒâ€ Ã¢â‚¬â„¢ÃƒÆ’Ã‚Â¢ÃƒÂ¢Ã¢â‚¬Å¡Ã‚Â¬Ãƒâ€¦Ã‚Â¡ÃƒÆ’Ã†â€™ÃƒÂ¢Ã¢â€šÂ¬Ã…Â¡ÃƒÆ’Ã¢â‚¬Å¡Ãƒâ€šÃ‚Â»"] = "u",
	["ÃƒÆ’Ã†â€™Ãƒâ€ Ã¢â‚¬â„¢ÃƒÆ’Ã¢â‚¬Â ÃƒÂ¢Ã¢â€šÂ¬Ã¢â€žÂ¢ÃƒÆ’Ã†â€™ÃƒÂ¢Ã¢â€šÂ¬Ã‚Â ÃƒÆ’Ã‚Â¢ÃƒÂ¢Ã¢â‚¬Å¡Ã‚Â¬ÃƒÂ¢Ã¢â‚¬Å¾Ã‚Â¢ÃƒÆ’Ã†â€™Ãƒâ€ Ã¢â‚¬â„¢ÃƒÆ’Ã‚Â¢ÃƒÂ¢Ã¢â‚¬Å¡Ã‚Â¬Ãƒâ€šÃ‚Â ÃƒÆ’Ã†â€™Ãƒâ€šÃ‚Â¢ÃƒÆ’Ã‚Â¢ÃƒÂ¢Ã¢â€šÂ¬Ã…Â¡Ãƒâ€šÃ‚Â¬ÃƒÆ’Ã‚Â¢ÃƒÂ¢Ã¢â€šÂ¬Ã…Â¾Ãƒâ€šÃ‚Â¢ÃƒÆ’Ã†â€™Ãƒâ€ Ã¢â‚¬â„¢ÃƒÆ’Ã¢â‚¬Â ÃƒÂ¢Ã¢â€šÂ¬Ã¢â€žÂ¢ÃƒÆ’Ã†â€™Ãƒâ€šÃ‚Â¢ÃƒÆ’Ã‚Â¢ÃƒÂ¢Ã¢â€šÂ¬Ã…Â¡Ãƒâ€šÃ‚Â¬ÃƒÆ’Ã¢â‚¬Â¦Ãƒâ€šÃ‚Â¡ÃƒÆ’Ã†â€™Ãƒâ€ Ã¢â‚¬â„¢ÃƒÆ’Ã‚Â¢ÃƒÂ¢Ã¢â‚¬Å¡Ã‚Â¬Ãƒâ€¦Ã‚Â¡ÃƒÆ’Ã†â€™ÃƒÂ¢Ã¢â€šÂ¬Ã…Â¡ÃƒÆ’Ã¢â‚¬Å¡Ãƒâ€šÃ‚Â¼"] = "u",
	["ÃƒÆ’Ã†â€™Ãƒâ€ Ã¢â‚¬â„¢ÃƒÆ’Ã¢â‚¬Â ÃƒÂ¢Ã¢â€šÂ¬Ã¢â€žÂ¢ÃƒÆ’Ã†â€™ÃƒÂ¢Ã¢â€šÂ¬Ã‚Â ÃƒÆ’Ã‚Â¢ÃƒÂ¢Ã¢â‚¬Å¡Ã‚Â¬ÃƒÂ¢Ã¢â‚¬Å¾Ã‚Â¢ÃƒÆ’Ã†â€™Ãƒâ€ Ã¢â‚¬â„¢ÃƒÆ’Ã‚Â¢ÃƒÂ¢Ã¢â‚¬Å¡Ã‚Â¬Ãƒâ€šÃ‚Â ÃƒÆ’Ã†â€™Ãƒâ€šÃ‚Â¢ÃƒÆ’Ã‚Â¢ÃƒÂ¢Ã¢â€šÂ¬Ã…Â¡Ãƒâ€šÃ‚Â¬ÃƒÆ’Ã‚Â¢ÃƒÂ¢Ã¢â€šÂ¬Ã…Â¾Ãƒâ€šÃ‚Â¢ÃƒÆ’Ã†â€™Ãƒâ€ Ã¢â‚¬â„¢ÃƒÆ’Ã¢â‚¬Â ÃƒÂ¢Ã¢â€šÂ¬Ã¢â€žÂ¢ÃƒÆ’Ã†â€™Ãƒâ€šÃ‚Â¢ÃƒÆ’Ã‚Â¢ÃƒÂ¢Ã¢â€šÂ¬Ã…Â¡Ãƒâ€šÃ‚Â¬ÃƒÆ’Ã¢â‚¬Å¡Ãƒâ€šÃ‚Â¦ÃƒÆ’Ã†â€™Ãƒâ€ Ã¢â‚¬â„¢ÃƒÆ’Ã‚Â¢ÃƒÂ¢Ã¢â‚¬Å¡Ã‚Â¬Ãƒâ€¦Ã‚Â¡ÃƒÆ’Ã†â€™ÃƒÂ¢Ã¢â€šÂ¬Ã…Â¡ÃƒÆ’Ã¢â‚¬Å¡Ãƒâ€šÃ‚Â¡"] = "U",
	["ÃƒÆ’Ã†â€™Ãƒâ€ Ã¢â‚¬â„¢ÃƒÆ’Ã¢â‚¬Â ÃƒÂ¢Ã¢â€šÂ¬Ã¢â€žÂ¢ÃƒÆ’Ã†â€™ÃƒÂ¢Ã¢â€šÂ¬Ã‚Â ÃƒÆ’Ã‚Â¢ÃƒÂ¢Ã¢â‚¬Å¡Ã‚Â¬ÃƒÂ¢Ã¢â‚¬Å¾Ã‚Â¢ÃƒÆ’Ã†â€™Ãƒâ€ Ã¢â‚¬â„¢ÃƒÆ’Ã‚Â¢ÃƒÂ¢Ã¢â‚¬Å¡Ã‚Â¬Ãƒâ€šÃ‚Â ÃƒÆ’Ã†â€™Ãƒâ€šÃ‚Â¢ÃƒÆ’Ã‚Â¢ÃƒÂ¢Ã¢â€šÂ¬Ã…Â¡Ãƒâ€šÃ‚Â¬ÃƒÆ’Ã‚Â¢ÃƒÂ¢Ã¢â€šÂ¬Ã…Â¾Ãƒâ€šÃ‚Â¢ÃƒÆ’Ã†â€™Ãƒâ€ Ã¢â‚¬â„¢ÃƒÆ’Ã¢â‚¬Â ÃƒÂ¢Ã¢â€šÂ¬Ã¢â€žÂ¢ÃƒÆ’Ã†â€™ÃƒÂ¢Ã¢â€šÂ¬Ã…Â¡ÃƒÆ’Ã¢â‚¬Å¡Ãƒâ€šÃ‚Â¢ÃƒÆ’Ã†â€™Ãƒâ€ Ã¢â‚¬â„¢ÃƒÆ’Ã¢â‚¬Å¡Ãƒâ€šÃ‚Â¢ÃƒÆ’Ã†â€™Ãƒâ€šÃ‚Â¢ÃƒÆ’Ã‚Â¢ÃƒÂ¢Ã¢â‚¬Å¡Ã‚Â¬Ãƒâ€¦Ã‚Â¡ÃƒÆ’Ã¢â‚¬Å¡Ãƒâ€šÃ‚Â¬ÃƒÆ’Ã†â€™ÃƒÂ¢Ã¢â€šÂ¬Ã‚Â¦ÃƒÆ’Ã¢â‚¬Å¡Ãƒâ€šÃ‚Â¾ÃƒÆ’Ã†â€™Ãƒâ€ Ã¢â‚¬â„¢ÃƒÆ’Ã‚Â¢ÃƒÂ¢Ã¢â‚¬Å¡Ã‚Â¬Ãƒâ€¦Ã‚Â¡ÃƒÆ’Ã†â€™ÃƒÂ¢Ã¢â€šÂ¬Ã…Â¡ÃƒÆ’Ã¢â‚¬Å¡Ãƒâ€šÃ‚Â¢"] = "U",
	["ÃƒÆ’Ã†â€™Ãƒâ€ Ã¢â‚¬â„¢ÃƒÆ’Ã¢â‚¬Â ÃƒÂ¢Ã¢â€šÂ¬Ã¢â€žÂ¢ÃƒÆ’Ã†â€™ÃƒÂ¢Ã¢â€šÂ¬Ã‚Â ÃƒÆ’Ã‚Â¢ÃƒÂ¢Ã¢â‚¬Å¡Ã‚Â¬ÃƒÂ¢Ã¢â‚¬Å¾Ã‚Â¢ÃƒÆ’Ã†â€™Ãƒâ€ Ã¢â‚¬â„¢ÃƒÆ’Ã‚Â¢ÃƒÂ¢Ã¢â‚¬Å¡Ã‚Â¬Ãƒâ€šÃ‚Â ÃƒÆ’Ã†â€™Ãƒâ€šÃ‚Â¢ÃƒÆ’Ã‚Â¢ÃƒÂ¢Ã¢â€šÂ¬Ã…Â¡Ãƒâ€šÃ‚Â¬ÃƒÆ’Ã‚Â¢ÃƒÂ¢Ã¢â€šÂ¬Ã…Â¾Ãƒâ€šÃ‚Â¢ÃƒÆ’Ã†â€™Ãƒâ€ Ã¢â‚¬â„¢ÃƒÆ’Ã¢â‚¬Â ÃƒÂ¢Ã¢â€šÂ¬Ã¢â€žÂ¢ÃƒÆ’Ã†â€™ÃƒÂ¢Ã¢â€šÂ¬Ã…Â¡ÃƒÆ’Ã¢â‚¬Å¡Ãƒâ€šÃ‚Â¢ÃƒÆ’Ã†â€™Ãƒâ€ Ã¢â‚¬â„¢ÃƒÆ’Ã¢â‚¬Å¡Ãƒâ€šÃ‚Â¢ÃƒÆ’Ã†â€™Ãƒâ€šÃ‚Â¢ÃƒÆ’Ã‚Â¢ÃƒÂ¢Ã¢â€šÂ¬Ã…Â¡Ãƒâ€šÃ‚Â¬ÃƒÆ’Ã¢â‚¬Â¦Ãƒâ€šÃ‚Â¡ÃƒÆ’Ã†â€™ÃƒÂ¢Ã¢â€šÂ¬Ã…Â¡ÃƒÆ’Ã¢â‚¬Å¡Ãƒâ€šÃ‚Â¬ÃƒÆ’Ã†â€™Ãƒâ€ Ã¢â‚¬â„¢ÃƒÆ’Ã‚Â¢ÃƒÂ¢Ã¢â‚¬Å¡Ã‚Â¬Ãƒâ€¦Ã‚Â¡ÃƒÆ’Ã†â€™ÃƒÂ¢Ã¢â€šÂ¬Ã…Â¡ÃƒÆ’Ã¢â‚¬Å¡Ãƒâ€šÃ‚Âº"] = "U",
	["ÃƒÆ’Ã†â€™Ãƒâ€ Ã¢â‚¬â„¢ÃƒÆ’Ã¢â‚¬Â ÃƒÂ¢Ã¢â€šÂ¬Ã¢â€žÂ¢ÃƒÆ’Ã†â€™ÃƒÂ¢Ã¢â€šÂ¬Ã‚Â ÃƒÆ’Ã‚Â¢ÃƒÂ¢Ã¢â‚¬Å¡Ã‚Â¬ÃƒÂ¢Ã¢â‚¬Å¾Ã‚Â¢ÃƒÆ’Ã†â€™Ãƒâ€ Ã¢â‚¬â„¢ÃƒÆ’Ã‚Â¢ÃƒÂ¢Ã¢â‚¬Å¡Ã‚Â¬Ãƒâ€šÃ‚Â ÃƒÆ’Ã†â€™Ãƒâ€šÃ‚Â¢ÃƒÆ’Ã‚Â¢ÃƒÂ¢Ã¢â€šÂ¬Ã…Â¡Ãƒâ€šÃ‚Â¬ÃƒÆ’Ã‚Â¢ÃƒÂ¢Ã¢â€šÂ¬Ã…Â¾Ãƒâ€šÃ‚Â¢ÃƒÆ’Ã†â€™Ãƒâ€ Ã¢â‚¬â„¢ÃƒÆ’Ã¢â‚¬Â ÃƒÂ¢Ã¢â€šÂ¬Ã¢â€žÂ¢ÃƒÆ’Ã†â€™Ãƒâ€šÃ‚Â¢ÃƒÆ’Ã‚Â¢ÃƒÂ¢Ã¢â€šÂ¬Ã…Â¡Ãƒâ€šÃ‚Â¬ÃƒÆ’Ã¢â‚¬Å¡Ãƒâ€šÃ‚Â¦ÃƒÆ’Ã†â€™Ãƒâ€ Ã¢â‚¬â„¢ÃƒÆ’Ã¢â‚¬Å¡Ãƒâ€šÃ‚Â¢ÃƒÆ’Ã†â€™Ãƒâ€šÃ‚Â¢ÃƒÆ’Ã‚Â¢ÃƒÂ¢Ã¢â‚¬Å¡Ã‚Â¬Ãƒâ€¦Ã‚Â¡ÃƒÆ’Ã¢â‚¬Å¡Ãƒâ€šÃ‚Â¬ÃƒÆ’Ã†â€™ÃƒÂ¢Ã¢â€šÂ¬Ã‚Â¦ÃƒÆ’Ã‚Â¢ÃƒÂ¢Ã¢â‚¬Å¡Ã‚Â¬Ãƒâ€¦Ã¢â‚¬Å“"] = "U",
	["ÃƒÆ’Ã†â€™Ãƒâ€ Ã¢â‚¬â„¢ÃƒÆ’Ã¢â‚¬Â ÃƒÂ¢Ã¢â€šÂ¬Ã¢â€žÂ¢ÃƒÆ’Ã†â€™ÃƒÂ¢Ã¢â€šÂ¬Ã‚Â ÃƒÆ’Ã‚Â¢ÃƒÂ¢Ã¢â‚¬Å¡Ã‚Â¬ÃƒÂ¢Ã¢â‚¬Å¾Ã‚Â¢ÃƒÆ’Ã†â€™Ãƒâ€ Ã¢â‚¬â„¢ÃƒÆ’Ã‚Â¢ÃƒÂ¢Ã¢â‚¬Å¡Ã‚Â¬Ãƒâ€šÃ‚Â ÃƒÆ’Ã†â€™Ãƒâ€šÃ‚Â¢ÃƒÆ’Ã‚Â¢ÃƒÂ¢Ã¢â€šÂ¬Ã…Â¡Ãƒâ€šÃ‚Â¬ÃƒÆ’Ã‚Â¢ÃƒÂ¢Ã¢â€šÂ¬Ã…Â¾Ãƒâ€šÃ‚Â¢ÃƒÆ’Ã†â€™Ãƒâ€ Ã¢â‚¬â„¢ÃƒÆ’Ã¢â‚¬Â ÃƒÂ¢Ã¢â€šÂ¬Ã¢â€žÂ¢ÃƒÆ’Ã†â€™Ãƒâ€šÃ‚Â¢ÃƒÆ’Ã‚Â¢ÃƒÂ¢Ã¢â€šÂ¬Ã…Â¡Ãƒâ€šÃ‚Â¬ÃƒÆ’Ã¢â‚¬Â¦Ãƒâ€šÃ‚Â¡ÃƒÆ’Ã†â€™Ãƒâ€ Ã¢â‚¬â„¢ÃƒÆ’Ã‚Â¢ÃƒÂ¢Ã¢â‚¬Å¡Ã‚Â¬Ãƒâ€¦Ã‚Â¡ÃƒÆ’Ã†â€™ÃƒÂ¢Ã¢â€šÂ¬Ã…Â¡ÃƒÆ’Ã¢â‚¬Å¡Ãƒâ€šÃ‚Â§"] = "c",
	["ÃƒÆ’Ã†â€™Ãƒâ€ Ã¢â‚¬â„¢ÃƒÆ’Ã¢â‚¬Â ÃƒÂ¢Ã¢â€šÂ¬Ã¢â€žÂ¢ÃƒÆ’Ã†â€™ÃƒÂ¢Ã¢â€šÂ¬Ã‚Â ÃƒÆ’Ã‚Â¢ÃƒÂ¢Ã¢â‚¬Å¡Ã‚Â¬ÃƒÂ¢Ã¢â‚¬Å¾Ã‚Â¢ÃƒÆ’Ã†â€™Ãƒâ€ Ã¢â‚¬â„¢ÃƒÆ’Ã‚Â¢ÃƒÂ¢Ã¢â‚¬Å¡Ã‚Â¬Ãƒâ€šÃ‚Â ÃƒÆ’Ã†â€™Ãƒâ€šÃ‚Â¢ÃƒÆ’Ã‚Â¢ÃƒÂ¢Ã¢â€šÂ¬Ã…Â¡Ãƒâ€šÃ‚Â¬ÃƒÆ’Ã‚Â¢ÃƒÂ¢Ã¢â€šÂ¬Ã…Â¾Ãƒâ€šÃ‚Â¢ÃƒÆ’Ã†â€™Ãƒâ€ Ã¢â‚¬â„¢ÃƒÆ’Ã¢â‚¬Â ÃƒÂ¢Ã¢â€šÂ¬Ã¢â€žÂ¢ÃƒÆ’Ã†â€™ÃƒÂ¢Ã¢â€šÂ¬Ã…Â¡ÃƒÆ’Ã¢â‚¬Å¡Ãƒâ€šÃ‚Â¢ÃƒÆ’Ã†â€™Ãƒâ€ Ã¢â‚¬â„¢ÃƒÆ’Ã¢â‚¬Å¡Ãƒâ€šÃ‚Â¢ÃƒÆ’Ã†â€™Ãƒâ€šÃ‚Â¢ÃƒÆ’Ã‚Â¢ÃƒÂ¢Ã¢â€šÂ¬Ã…Â¡Ãƒâ€šÃ‚Â¬ÃƒÆ’Ã¢â‚¬Â¦Ãƒâ€šÃ‚Â¡ÃƒÆ’Ã†â€™ÃƒÂ¢Ã¢â€šÂ¬Ã…Â¡ÃƒÆ’Ã¢â‚¬Å¡Ãƒâ€šÃ‚Â¬ÃƒÆ’Ã†â€™Ãƒâ€ Ã¢â‚¬â„¢ÃƒÆ’Ã‚Â¢ÃƒÂ¢Ã¢â‚¬Å¡Ã‚Â¬Ãƒâ€¦Ã‚Â¡ÃƒÆ’Ã†â€™ÃƒÂ¢Ã¢â€šÂ¬Ã…Â¡ÃƒÆ’Ã¢â‚¬Å¡Ãƒâ€šÃ‚Â¡"] = "C",
	["ÃƒÆ’Ã†â€™Ãƒâ€ Ã¢â‚¬â„¢ÃƒÆ’Ã¢â‚¬Â ÃƒÂ¢Ã¢â€šÂ¬Ã¢â€žÂ¢ÃƒÆ’Ã†â€™ÃƒÂ¢Ã¢â€šÂ¬Ã‚Â ÃƒÆ’Ã‚Â¢ÃƒÂ¢Ã¢â‚¬Å¡Ã‚Â¬ÃƒÂ¢Ã¢â‚¬Å¾Ã‚Â¢ÃƒÆ’Ã†â€™Ãƒâ€ Ã¢â‚¬â„¢ÃƒÆ’Ã‚Â¢ÃƒÂ¢Ã¢â‚¬Å¡Ã‚Â¬Ãƒâ€šÃ‚Â ÃƒÆ’Ã†â€™Ãƒâ€šÃ‚Â¢ÃƒÆ’Ã‚Â¢ÃƒÂ¢Ã¢â€šÂ¬Ã…Â¡Ãƒâ€šÃ‚Â¬ÃƒÆ’Ã‚Â¢ÃƒÂ¢Ã¢â€šÂ¬Ã…Â¾Ãƒâ€šÃ‚Â¢ÃƒÆ’Ã†â€™Ãƒâ€ Ã¢â‚¬â„¢ÃƒÆ’Ã¢â‚¬Â ÃƒÂ¢Ã¢â€šÂ¬Ã¢â€žÂ¢ÃƒÆ’Ã†â€™Ãƒâ€šÃ‚Â¢ÃƒÆ’Ã‚Â¢ÃƒÂ¢Ã¢â€šÂ¬Ã…Â¡Ãƒâ€šÃ‚Â¬ÃƒÆ’Ã¢â‚¬Â¦Ãƒâ€šÃ‚Â¡ÃƒÆ’Ã†â€™Ãƒâ€ Ã¢â‚¬â„¢ÃƒÆ’Ã‚Â¢ÃƒÂ¢Ã¢â‚¬Å¡Ã‚Â¬Ãƒâ€¦Ã‚Â¡ÃƒÆ’Ã†â€™ÃƒÂ¢Ã¢â€šÂ¬Ã…Â¡ÃƒÆ’Ã¢â‚¬Å¡Ãƒâ€šÃ‚Â±"] = "n",
	["ÃƒÆ’Ã†â€™Ãƒâ€ Ã¢â‚¬â„¢ÃƒÆ’Ã¢â‚¬Â ÃƒÂ¢Ã¢â€šÂ¬Ã¢â€žÂ¢ÃƒÆ’Ã†â€™ÃƒÂ¢Ã¢â€šÂ¬Ã‚Â ÃƒÆ’Ã‚Â¢ÃƒÂ¢Ã¢â‚¬Å¡Ã‚Â¬ÃƒÂ¢Ã¢â‚¬Å¾Ã‚Â¢ÃƒÆ’Ã†â€™Ãƒâ€ Ã¢â‚¬â„¢ÃƒÆ’Ã‚Â¢ÃƒÂ¢Ã¢â‚¬Å¡Ã‚Â¬Ãƒâ€šÃ‚Â ÃƒÆ’Ã†â€™Ãƒâ€šÃ‚Â¢ÃƒÆ’Ã‚Â¢ÃƒÂ¢Ã¢â€šÂ¬Ã…Â¡Ãƒâ€šÃ‚Â¬ÃƒÆ’Ã‚Â¢ÃƒÂ¢Ã¢â€šÂ¬Ã…Â¾Ãƒâ€šÃ‚Â¢ÃƒÆ’Ã†â€™Ãƒâ€ Ã¢â‚¬â„¢ÃƒÆ’Ã¢â‚¬Â ÃƒÂ¢Ã¢â€šÂ¬Ã¢â€žÂ¢ÃƒÆ’Ã†â€™ÃƒÂ¢Ã¢â€šÂ¬Ã…Â¡ÃƒÆ’Ã¢â‚¬Å¡Ãƒâ€šÃ‚Â¢ÃƒÆ’Ã†â€™Ãƒâ€ Ã¢â‚¬â„¢ÃƒÆ’Ã¢â‚¬Å¡Ãƒâ€šÃ‚Â¢ÃƒÆ’Ã†â€™Ãƒâ€šÃ‚Â¢ÃƒÆ’Ã‚Â¢ÃƒÂ¢Ã¢â€šÂ¬Ã…Â¡Ãƒâ€šÃ‚Â¬ÃƒÆ’Ã¢â‚¬Â¦Ãƒâ€šÃ‚Â¡ÃƒÆ’Ã†â€™ÃƒÂ¢Ã¢â€šÂ¬Ã…Â¡ÃƒÆ’Ã¢â‚¬Å¡Ãƒâ€šÃ‚Â¬ÃƒÆ’Ã†â€™Ãƒâ€ Ã¢â‚¬â„¢ÃƒÆ’Ã‚Â¢ÃƒÂ¢Ã¢â‚¬Å¡Ã‚Â¬Ãƒâ€šÃ‚Â¹ÃƒÆ’Ã†â€™ÃƒÂ¢Ã¢â€šÂ¬Ã‚Â¦ÃƒÆ’Ã‚Â¢ÃƒÂ¢Ã¢â‚¬Å¡Ã‚Â¬Ãƒâ€¦Ã¢â‚¬Å“"] = "N",
	["ÃƒÆ’Ã†â€™Ãƒâ€ Ã¢â‚¬â„¢ÃƒÆ’Ã¢â‚¬Â ÃƒÂ¢Ã¢â€šÂ¬Ã¢â€žÂ¢ÃƒÆ’Ã†â€™ÃƒÂ¢Ã¢â€šÂ¬Ã‚Â ÃƒÆ’Ã‚Â¢ÃƒÂ¢Ã¢â‚¬Å¡Ã‚Â¬ÃƒÂ¢Ã¢â‚¬Å¾Ã‚Â¢ÃƒÆ’Ã†â€™Ãƒâ€ Ã¢â‚¬â„¢ÃƒÆ’Ã¢â‚¬Å¡Ãƒâ€šÃ‚Â¢ÃƒÆ’Ã†â€™Ãƒâ€šÃ‚Â¢ÃƒÆ’Ã‚Â¢ÃƒÂ¢Ã¢â‚¬Å¡Ã‚Â¬Ãƒâ€¦Ã‚Â¡ÃƒÆ’Ã¢â‚¬Å¡Ãƒâ€šÃ‚Â¬ÃƒÆ’Ã†â€™ÃƒÂ¢Ã¢â€šÂ¬Ã‚Â¦ÃƒÆ’Ã¢â‚¬Å¡Ãƒâ€šÃ‚Â¡ÃƒÆ’Ã†â€™Ãƒâ€ Ã¢â‚¬â„¢ÃƒÆ’Ã¢â‚¬Â ÃƒÂ¢Ã¢â€šÂ¬Ã¢â€žÂ¢ÃƒÆ’Ã†â€™Ãƒâ€šÃ‚Â¢ÃƒÆ’Ã‚Â¢ÃƒÂ¢Ã¢â€šÂ¬Ã…Â¡Ãƒâ€šÃ‚Â¬ÃƒÆ’Ã¢â‚¬Â¦Ãƒâ€šÃ‚Â¡ÃƒÆ’Ã†â€™Ãƒâ€ Ã¢â‚¬â„¢ÃƒÆ’Ã‚Â¢ÃƒÂ¢Ã¢â‚¬Å¡Ã‚Â¬Ãƒâ€¦Ã‚Â¡ÃƒÆ’Ã†â€™ÃƒÂ¢Ã¢â€šÂ¬Ã…Â¡ÃƒÆ’Ã¢â‚¬Å¡Ãƒâ€šÃ‚Â°"] = " ",
	["ÃƒÆ’Ã†â€™Ãƒâ€ Ã¢â‚¬â„¢ÃƒÆ’Ã¢â‚¬Â ÃƒÂ¢Ã¢â€šÂ¬Ã¢â€žÂ¢ÃƒÆ’Ã†â€™ÃƒÂ¢Ã¢â€šÂ¬Ã‚Â ÃƒÆ’Ã‚Â¢ÃƒÂ¢Ã¢â‚¬Å¡Ã‚Â¬ÃƒÂ¢Ã¢â‚¬Å¾Ã‚Â¢ÃƒÆ’Ã†â€™Ãƒâ€ Ã¢â‚¬â„¢ÃƒÆ’Ã¢â‚¬Å¡Ãƒâ€šÃ‚Â¢ÃƒÆ’Ã†â€™Ãƒâ€šÃ‚Â¢ÃƒÆ’Ã‚Â¢ÃƒÂ¢Ã¢â‚¬Å¡Ã‚Â¬Ãƒâ€¦Ã‚Â¡ÃƒÆ’Ã¢â‚¬Å¡Ãƒâ€šÃ‚Â¬ÃƒÆ’Ã†â€™ÃƒÂ¢Ã¢â€šÂ¬Ã‚Â¦ÃƒÆ’Ã¢â‚¬Å¡Ãƒâ€šÃ‚Â¡ÃƒÆ’Ã†â€™Ãƒâ€ Ã¢â‚¬â„¢ÃƒÆ’Ã¢â‚¬Â ÃƒÂ¢Ã¢â€šÂ¬Ã¢â€žÂ¢ÃƒÆ’Ã†â€™Ãƒâ€šÃ‚Â¢ÃƒÆ’Ã‚Â¢ÃƒÂ¢Ã¢â€šÂ¬Ã…Â¡Ãƒâ€šÃ‚Â¬ÃƒÆ’Ã¢â‚¬Â¦Ãƒâ€šÃ‚Â¡ÃƒÆ’Ã†â€™Ãƒâ€ Ã¢â‚¬â„¢ÃƒÆ’Ã‚Â¢ÃƒÂ¢Ã¢â‚¬Å¡Ã‚Â¬Ãƒâ€¦Ã‚Â¡ÃƒÆ’Ã†â€™ÃƒÂ¢Ã¢â€šÂ¬Ã…Â¡ÃƒÆ’Ã¢â‚¬Å¡Ãƒâ€šÃ‚Âº"] = " ",
	["ÃƒÆ’Ã†â€™Ãƒâ€ Ã¢â‚¬â„¢ÃƒÆ’Ã¢â‚¬Â ÃƒÂ¢Ã¢â€šÂ¬Ã¢â€žÂ¢ÃƒÆ’Ã†â€™ÃƒÂ¢Ã¢â€šÂ¬Ã‚Â ÃƒÆ’Ã‚Â¢ÃƒÂ¢Ã¢â‚¬Å¡Ã‚Â¬ÃƒÂ¢Ã¢â‚¬Å¾Ã‚Â¢ÃƒÆ’Ã†â€™Ãƒâ€ Ã¢â‚¬â„¢ÃƒÆ’Ã¢â‚¬Å¡Ãƒâ€šÃ‚Â¢ÃƒÆ’Ã†â€™Ãƒâ€šÃ‚Â¢ÃƒÆ’Ã‚Â¢ÃƒÂ¢Ã¢â‚¬Å¡Ã‚Â¬Ãƒâ€¦Ã‚Â¡ÃƒÆ’Ã¢â‚¬Å¡Ãƒâ€šÃ‚Â¬ÃƒÆ’Ã†â€™ÃƒÂ¢Ã¢â€šÂ¬Ã‚Â¦ÃƒÆ’Ã¢â‚¬Å¡Ãƒâ€šÃ‚Â¡ÃƒÆ’Ã†â€™Ãƒâ€ Ã¢â‚¬â„¢ÃƒÆ’Ã¢â‚¬Â ÃƒÂ¢Ã¢â€šÂ¬Ã¢â€žÂ¢ÃƒÆ’Ã†â€™Ãƒâ€šÃ‚Â¢ÃƒÆ’Ã‚Â¢ÃƒÂ¢Ã¢â€šÂ¬Ã…Â¡Ãƒâ€šÃ‚Â¬ÃƒÆ’Ã¢â‚¬Â¦Ãƒâ€šÃ‚Â¡ÃƒÆ’Ã†â€™Ãƒâ€ Ã¢â‚¬â„¢ÃƒÆ’Ã‚Â¢ÃƒÂ¢Ã¢â‚¬Å¡Ã‚Â¬Ãƒâ€¦Ã‚Â¡ÃƒÆ’Ã†â€™ÃƒÂ¢Ã¢â€šÂ¬Ã…Â¡ÃƒÆ’Ã¢â‚¬Å¡Ãƒâ€šÃ‚Âª"] = " ",
}

local FeedbackAllowedChars = "abcdefghijklmnopqrstuvwxyzABCDEFGHIJKLMNOPQRSTUVWXYZ0123456789 .,!?;:()[]{}@#%&*+-=/_\"'"

local function SanitizeFeedbackText(text)
	if not text or text == "" then
		return "_No message_"
	end

	text = NormalizeFeedbackText(text)

	local hasEvasion, evasionType = DetectFeedbackEvasion(text)
	if hasEvasion then
		return "[Message blocked - " .. evasionType .. "]"
	end

	text = text:gsub("@everyone", "@\226\128\139everyone")
	text = text:gsub("@here", "@\226\128\139here")
	text = text:gsub("<@!?(%d+)>", "[user]")
	text = text:gsub("<@&(%d+)>", "[role]")

	text = text:gsub("d[iI][sS][cC][oO][rR][dD]%.?[gG][gG]%s*/?%s*[%w%-_]+", "[invite removed]")
	text = text:gsub(
		"d[iI][sS][cC][oO][rR][dD]%.?[cC][oO][mM]%s*/?%s*[iI][nN][vV][iI][tT][eE]%s*/?%s*[%w%-_]+",
		"[invite removed]"
	)
	text = text:gsub("https?%s*:%s*//%s*[%w%-%.]+%s*%.%s*[%w]+[%w%-%./?=&%%]*", "[link removed]")
	text = text:gsub("www%s*%.%s*[%w%-]+%s*%.%s*[%w]+", "[link removed]")
	text = text:gsub("t[eE][lL][eE][gG][rR][aA][mM]%.?%s*[mM][eE]%s*/%s*[%w%-_]+", "[invite removed]")

	for old, new in pairs(FeedbackAsciiMap) do
		text = text:gsub(old, new)
	end

	local cleaned = ""
	for i = 1, #text do
		local char = text:sub(i, i)
		if FeedbackAllowedChars:find(char, 1, true) then
			cleaned = cleaned .. char
		else
			cleaned = cleaned .. " "
		end
	end
	text = cleaned

	text = text:gsub("%s+", " ")
	text = text:gsub("^%s+", "")
	text = text:gsub("%s+$", "")

	local hasEvasionAfter = DetectFeedbackEvasion(text)
	if hasEvasionAfter then
		return "[Message blocked - suspicious content]"
	end

	if #text > 500 then
		text = text:sub(1, 500) .. "..."
	end

	return text
end

function NullUI:SanitizeText(text, opts)
	opts = opts or {}
	local maxLength = opts.MaxLength or 500

	if not text or text == "" then
		return "", false, nil
	end

	local normalized = NormalizeFeedbackText(tostring(text))
	local hasEvasion, evasionType = DetectFeedbackEvasion(normalized)
	if hasEvasion then
		return "", true, evasionType
	end

	local cleaned = SanitizeFeedbackText(text)
	if cleaned == "_No message_" then
		return "", false, nil
	end
	if cleaned:find("^%[Message blocked") then
		return "", true, "blocked content"
	end

	if #cleaned > maxLength then
		cleaned = cleaned:sub(1, maxLength)
	end

	return cleaned, false, nil
end

local FEEDBACK_WEBHOOK_COOLDOWN = 30
local LastFeedbackWebhookAt = 0

function NullUI:SendFeedbackWebhook(webhookUrl, stars, message, opts)
	opts = opts or {}
	stars = math.clamp(math.floor((stars or 0) + 0.5), 0, 5)

	local now = os.clock()
	if now - LastFeedbackWebhookAt < FEEDBACK_WEBHOOK_COOLDOWN then
		self:Notify({
			Title = "Feedback",
			Text = string.format(
				"Please wait %ds before sending more feedback.",
				math.ceil(FEEDBACK_WEBHOOK_COOLDOWN - (now - LastFeedbackWebhookAt))
			),
			Type = "warning",
			Duration = 3,
		})
		return false
	end

	if not webhookUrl or webhookUrl == "" then
		self:Notify({
			Title = "Feedback",
			Text = "No webhook configured.",
			Type = "warning",
			Duration = 4,
		})
		return false
	end

	local httpRequest = (syn and syn.request) or http_request or request
	if not httpRequest then
		self:Notify({
			Title = "Feedback",
			Text = "Your executor doesn't support HTTP requests.",
			Type = "error",
			Duration = 4,
		})
		return false
	end

	local normalizedMessage = NormalizeFeedbackText(message or "")
	local hasEvasion = DetectFeedbackEvasion(normalizedMessage)
	local cleanMessage = SanitizeFeedbackText(message)

	if hasEvasion or cleanMessage:find("blocked") then
		LastFeedbackWebhookAt = now
		self:Notify({
			Title = "Blocked",
			Text = "Unallowed content detected.",
			Type = "error",
			Duration = 4,
		})
		return false
	end

	LastFeedbackWebhookAt = now

	local starDisplay = string.rep("\226\152\133", stars) .. string.rep("\226\152\134", 5 - stars)
	local embedColor = opts.Color or 0xFFC440
	local hasInvite = cleanMessage:find("%[invite removed%]") or cleanMessage:find("%[link removed%]")

	local body = HttpService:JSONEncode({
		allowed_mentions = { parse = {} },
		embeds = {
			{
				title = opts.Title or "New UI Feedback",
				description = starDisplay .. "  (" .. stars .. "/5)",
				color = embedColor,
				fields = {
					{ name = "Message", value = cleanMessage, inline = false },
				},
				footer = { text = hasInvite and "Invites removed" or "Submitted anonymously" },
				timestamp = DateTime.now():ToIsoDate(),
			},
		},
	})

	SafeSpawn(function()
		local ok, err = pcall(httpRequest, {
			Url = webhookUrl,
			Method = "POST",
			Headers = { ["Content-Type"] = "application/json" },
			Body = body,
		})
		self:Notify({
			Title = ok and "Feedback Sent" or "Failed to Send",
			Text = ok and "Thanks for rating the UI!" or tostring(err),
			Type = ok and "success" or "error",
			Duration = 3,
		})
	end)

	return true
end

local function BuildFeedbackRow(parent, layoutOrder, rowH, placeholder, buttonIcon)
	local row = Instance.new("Frame")
	row.Name = "Feedback"
	row.BackgroundTransparency = 1
	row.Size = UDim2.new(1, 0, 0, rowH)
	row.LayoutOrder = layoutOrder
	row.ZIndex = Z.Content + 1
	row.Parent = parent

	local pill = Instance.new("Frame")
	pill.Name = "Pill"
	pill.BackgroundColor3 = Color3.new(1, 1, 1)
	pill.BackgroundTransparency = 0.95
	pill.BorderSizePixel = 0
	pill.Size = UDim2.new(1, -(rowH + 6), 1, 0)
	pill.ZIndex = Z.Content + 1
	pill.Parent = row
	Corner(pill, 9)
	local pillStroke = Stroke(pill, Color3.new(1, 1, 1), 1, 0.9)

	local pillPad = Instance.new("UIPadding")
	pillPad.PaddingLeft = UDim.new(0, 10)
	pillPad.PaddingRight = UDim.new(0, 10)
	pillPad.Parent = pill

	local box = Instance.new("TextBox")
	box.BackgroundTransparency = 1
	box.ClearTextOnFocus = false
	box.FontFace = NullUI.Theme.FontRegular
	box.PlaceholderText = placeholder or "Give us some feedback!"
	box.PlaceholderColor3 = Color3.fromRGB(120, 120, 122)
	box.Text = ""
	box.TextColor3 = NullUI.Theme.Text
	Role(box, "Text")
	box.TextSize = 13
	box.TextXAlignment = Enum.TextXAlignment.Left
	box.TextYAlignment = Enum.TextYAlignment.Center
	box.TextTruncate = Enum.TextTruncate.AtEnd
	box.ClipsDescendants = true
	box.Size = UDim2.fromScale(1, 1)
	box.ZIndex = Z.Content + 2
	box.Parent = pill

	box.Focused:Connect(function()
		Tween(pillStroke, { Color = NullUI.Theme.Accent, Transparency = 0.3 }, 0.18)
	end)
	box.FocusLost:Connect(function()
		Tween(pillStroke, { Color = Color3.new(1, 1, 1), Transparency = 0.9 }, 0.18)
	end)

	local sendBtn = Instance.new("TextButton")
	sendBtn.Name = "Send"
	sendBtn.Text = ""
	sendBtn.AutoButtonColor = false
	sendBtn.BackgroundColor3 = Color3.new(1, 1, 1)
	sendBtn.BackgroundTransparency = 0.9
	sendBtn.BorderSizePixel = 0
	sendBtn.AnchorPoint = Vector2.new(1, 0)
	sendBtn.Position = UDim2.new(1, 0, 0, 0)
	sendBtn.Size = UDim2.fromOffset(rowH, rowH)
	sendBtn.ZIndex = Z.Content + 1
	sendBtn.Parent = row
	Corner(sendBtn, 9)

	local sendIcon = Instance.new("ImageLabel")
	sendIcon.BackgroundTransparency = 1
	sendIcon.Image = ResolveIcon(buttonIcon or "send")
	sendIcon.ImageColor3 = NullUI.Theme.Text
	Role(sendIcon, "Text")
	sendIcon.Size = UDim2.fromOffset(12, 12)
	sendIcon.AnchorPoint = Vector2.new(0.5, 0.5)
	sendIcon.Position = UDim2.fromScale(0.5, 0.5)
	sendIcon.ZIndex = Z.Content + 2
	sendIcon.Parent = sendBtn

	sendBtn.MouseEnter:Connect(function()
		Tween(sendBtn, { BackgroundTransparency = 0.8 }, 0.12)
	end)
	sendBtn.MouseLeave:Connect(function()
		Tween(sendBtn, { BackgroundTransparency = 0.9 }, 0.12)
	end)

	return { Row = row, Box = box, SendBtn = sendBtn }
end

function Tab:AddRating(opts)
	opts = opts or {}
	local maxStars = math.max(1, opts.MaxStars or 5)
	local starColor = opts.StarColor or Color3.fromRGB(255, 196, 64)
	local hasTitle = opts.Title and opts.Title ~= ""

	local card = BaseCard(self._page, 10)
	card.AutomaticSize = Enum.AutomaticSize.Y

	local pad = Instance.new("UIPadding")
	pad.PaddingTop = UDim.new(0, 10)
	pad.PaddingBottom = UDim.new(0, 10)
	pad.PaddingLeft = UDim.new(0, 14)
	pad.PaddingRight = UDim.new(0, 14)
	pad.Parent = card

	local layout = Instance.new("UIListLayout")
	layout.Padding = UDim.new(0, 8)
	layout.SortOrder = Enum.SortOrder.LayoutOrder
	layout.Parent = card

	if hasTitle then
		local titleLabel = Instance.new("TextLabel")
		titleLabel.BackgroundTransparency = 1
		titleLabel.FontFace = NullUI.Theme.Font
		titleLabel.Text = opts.Title
		titleLabel.TextColor3 = NullUI.Theme.Text
		Role(titleLabel, "Text")
		titleLabel.TextSize = 14
		titleLabel.TextXAlignment = Enum.TextXAlignment.Left
		titleLabel.Size = UDim2.new(1, 0, 0, 16)
		titleLabel.LayoutOrder = 1
		titleLabel.ZIndex = Z.Content + 1
		titleLabel.Parent = card

		self._window:_RegisterSearchable(self, opts.Title, card)
	end

	local starBar = BuildStarRow(card, 2, maxStars, starColor, 20, opts.Default)
	local feedback = BuildFeedbackRow(card, 3, 26, opts.Placeholder, opts.ButtonIcon)

	local clearOnSubmit = opts.ClearOnSubmit ~= false
	feedback.SendBtn.MouseButton1Click:Connect(function()
		local selected = starBar.Get()
		if selected <= 0 then
			starBar.Nudge()
			return
		end
		if opts.Callback then
			SafeSpawn(opts.Callback, selected, feedback.Box.Text)
		end
		if opts.WebhookUrl then
			SafeSpawn(function()
				NullUI:SendFeedbackWebhook(opts.WebhookUrl, selected, feedback.Box.Text, opts.WebhookOptions)
			end)
		end
		if clearOnSubmit then
			feedback.Box.Text = ""
			starBar.Set(opts.Default or 0)
		end
	end)

	return {
		Instance = card,
		Get = function()
			return starBar.Get(), feedback.Box.Text
		end,
		Set = function(_, newStars, newText)
			starBar.Set(newStars)
			if newText ~= nil then
				feedback.Box.Text = newText
			end
		end,
		Destroy = function()
			card:Destroy()
		end,
	}
end

function Tab:AddButton(opts)
	opts = opts or {}
	local hasDesc = opts.Description and opts.Description ~= ""
	local height = hasDesc and 54 or 40
	local card = BaseCard(self._page, height)

	local textX = AddLeadingIcon(card, opts.Icon, height)
	AddTitleDesc(card, textX, 44, opts.Text or "Button", opts.Description, height)
	self._window:_RegisterSearchable(self, opts.Text or "Button", card)

	local chev = Instance.new("ImageLabel")
	chev.BackgroundTransparency = 1
	chev.Image = ResolveIcon("chevron-right")
	chev.ImageColor3 = NullUI.Theme.TextDim
	Role(chev, "TextDim")
	chev.Size = UDim2.fromOffset(14, 14)
	chev.AnchorPoint = Vector2.new(1, 0.5)
	chev.Position = UDim2.new(1, -16, 0.5, 0)
	chev.ZIndex = Z.Content + 1
	chev.Parent = card

	local click = Instance.new("TextButton")
	click.Text = ""
	click.AutoButtonColor = false
	click.BackgroundTransparency = 1
	click.Size = UDim2.fromScale(1, 1)
	click.ZIndex = Z.Content + 3
	click.Parent = card

	click.MouseEnter:Connect(function()
		Tween(card, { BackgroundTransparency = 0.9 }, 0.18)
		Tween(chev, { ImageColor3 = NullUI.Theme.Text, Position = UDim2.new(1, -12, 0.5, 0) }, 0.18)
	end)
	click.MouseLeave:Connect(function()
		Tween(card, { BackgroundTransparency = 0.96 }, 0.18)
		Tween(chev, { ImageColor3 = NullUI.Theme.TextDim, Position = UDim2.new(1, -16, 0.5, 0) }, 0.18)
	end)
	click.MouseButton1Click:Connect(function()
		Tween(card, { BackgroundTransparency = 0.8 }, 0.08)
		Tween(chev, { ImageColor3 = NullUI.Theme.Accent }, 0.08)
		SafeDelay(0.08, function()
			if not card.Parent then
				return
			end
			Tween(card, { BackgroundTransparency = 0.9 }, 0.18)
			Tween(chev, { ImageColor3 = NullUI.Theme.Text }, 0.18)
		end)
		if opts.Callback then
			SafeSpawn(opts.Callback)
		end
	end)

	return {
		Instance = card,
		Destroy = function()
			card:Destroy()
		end,
	}
end

function Tab:AddCard(opts)
	opts = opts or {}
	local hasDesc = opts.Description and opts.Description ~= ""
	local hasImage = (opts.Image and opts.Image ~= "") or opts.UserId ~= nil
	local hasButton = opts.ButtonText ~= nil and opts.ButtonText ~= ""
	local BUTTON_H, BUTTON_GAP, BUTTON_MARGIN = 32, 6, 4
	local buttonReserve = hasButton and (BUTTON_GAP + BUTTON_H + BUTTON_MARGIN) or 0

	local hasRating = type(opts.Rating) == "table"
	local RATING_LABEL_H, RATING_STAR_H, RATING_INPUT_H = 14, 20, 26
	local RATING_ROW_GAP, RATING_TOP_GAP, RATING_BOTTOM_MARGIN = 6, 10, 8
	local ratingHasTitle = hasRating and opts.Rating.Title and opts.Rating.Title ~= ""
	local ratingBlockH = 0
	if hasRating then
		local bodyH = (ratingHasTitle and (RATING_LABEL_H + RATING_ROW_GAP) or 0)
			+ RATING_STAR_H
			+ RATING_ROW_GAP
			+ RATING_INPUT_H
		ratingBlockH = RATING_TOP_GAP + bodyH + RATING_BOTTOM_MARGIN
	end

	local extraBottom = buttonReserve + ratingBlockH
	local topHeight = hasDesc and 54 or 40
	local height = topHeight + extraBottom
	local imgSize, imgPad = 34, 10

	local card = BaseCard(self._page, height)
	local textX = 14

	if hasImage then
		local imgHolder = Instance.new("Frame")
		imgHolder.Name = "Image"
		imgHolder.AnchorPoint = Vector2.new(0, 0.5)
		imgHolder.Position = UDim2.fromOffset(10, topHeight / 2)
		imgHolder.Size = UDim2.fromOffset(imgSize, imgSize)
		imgHolder.BackgroundTransparency = 1
		imgHolder.BorderSizePixel = 0
		imgHolder.ClipsDescendants = true
		imgHolder.ZIndex = Z.Content + 1
		imgHolder.Parent = card
		Corner(imgHolder, NullUI.Theme.CornerRadiusSm)
		Stroke(imgHolder, Color3.new(1, 1, 1), 1, 0.85)

		local img = Instance.new("ImageLabel")
		img.BackgroundTransparency = 1
		img.ScaleType = Enum.ScaleType.Crop
		img.Size = UDim2.fromScale(1, 1)
		img.ZIndex = Z.Content + 2
		img.Parent = imgHolder
		Corner(img, NullUI.Theme.CornerRadiusSm)

		if opts.UserId then
			SafeSpawn(function()
				local ok, content = pcall(
					Players.GetUserThumbnailAsync,
					Players,
					opts.UserId,
					opts.ThumbnailType or Enum.ThumbnailType.HeadShot,
					opts.ThumbnailSize or Enum.ThumbnailSize.Size100x100
				)
				if ok and content and img.Parent then
					img.Image = content
				end
			end)
		else
			img.Image = ResolveIcon(opts.Image)
		end

		textX = 10 + imgSize + imgPad
	end

	local rightReserve = opts.Callback and 44 or 14
	AddTitleDesc(card, textX, rightReserve, opts.Title or "Card", opts.Description, topHeight, extraBottom)
	self._window:_RegisterSearchable(self, opts.Title or "Card", card)

	if opts.Callback then
		local chev = Instance.new("ImageLabel")
		chev.BackgroundTransparency = 1
		chev.Image = ResolveIcon("chevron-right")
		chev.ImageColor3 = NullUI.Theme.TextDim
		Role(chev, "TextDim")
		chev.Size = UDim2.fromOffset(14, 14)
		chev.AnchorPoint = Vector2.new(1, 0.5)
		chev.Position = UDim2.new(1, -16, 0.5, 0)
		chev.ZIndex = Z.Content + 1
		chev.Parent = card

		local click = Instance.new("TextButton")
		click.Text = ""
		click.AutoButtonColor = false
		click.BackgroundTransparency = 1
		click.Size = UDim2.fromScale(1, 1)
		click.ZIndex = Z.Content + 3
		click.Parent = card

		click.MouseEnter:Connect(function()
			Tween(card, { BackgroundTransparency = 0.9 }, 0.18)
			Tween(chev, { ImageColor3 = NullUI.Theme.Text, Position = UDim2.new(1, -12, 0.5, 0) }, 0.18)
		end)
		click.MouseLeave:Connect(function()
			Tween(card, { BackgroundTransparency = 0.96 }, 0.18)
			Tween(chev, { ImageColor3 = NullUI.Theme.TextDim, Position = UDim2.new(1, -16, 0.5, 0) }, 0.18)
		end)
		click.MouseButton1Click:Connect(function()
			Tween(card, { BackgroundTransparency = 0.8 }, 0.08)
			SafeDelay(0.08, function()
				if card.Parent then
					Tween(card, { BackgroundTransparency = 0.9 }, 0.18)
				end
			end)
			SafeSpawn(opts.Callback)
		end)
	end

	if hasButton then
		local footerBtn = Instance.new("TextButton")
		footerBtn.Name = "FooterButton"
		footerBtn.Text = ""
		footerBtn.AutoButtonColor = false
		footerBtn.BackgroundColor3 = Color3.new(1, 1, 1)
		footerBtn.BackgroundTransparency = 0.85
		footerBtn.BorderSizePixel = 0
		footerBtn.Position = UDim2.new(0, 10, 1, -(BUTTON_H + BUTTON_MARGIN))
		footerBtn.Size = UDim2.new(1, -20, 0, BUTTON_H)
		footerBtn.ZIndex = Z.Content + 1
		footerBtn.Parent = card
		Corner(footerBtn, 8)
		local footerStroke = Stroke(footerBtn, Color3.new(1, 1, 1), 1, 0.85)

		local footerLabel = Instance.new("TextLabel")
		footerLabel.BackgroundTransparency = 1
		footerLabel.FontFace = NullUI.Theme.Font
		footerLabel.Text = opts.ButtonText
		footerLabel.TextColor3 = NullUI.Theme.Text
		Role(footerLabel, "Text")
		footerLabel.TextSize = 13
		footerLabel.Size = UDim2.fromScale(1, 1)
		footerLabel.ZIndex = Z.Content + 2
		footerLabel.Parent = footerBtn

		footerBtn.MouseEnter:Connect(function()
			Tween(footerBtn, { BackgroundTransparency = 0.7 }, 0.12)
			Tween(footerStroke, { Transparency = 0.7 }, 0.12)
		end)
		footerBtn.MouseLeave:Connect(function()
			Tween(footerBtn, { BackgroundTransparency = 0.85 }, 0.12)
			Tween(footerStroke, { Transparency = 0.85 }, 0.12)
		end)
		footerBtn.MouseButton1Click:Connect(function()
			Tween(footerBtn, { BackgroundTransparency = 0.55 }, 0.08)
			SafeDelay(0.08, function()
				if footerBtn.Parent then
					Tween(footerBtn, { BackgroundTransparency = 0.7 }, 0.18)
				end
			end)
			if opts.ButtonCallback then
				SafeSpawn(opts.ButtonCallback)
			end
		end)
	end

	local ratingBar
	if hasRating then
		local ratingOpts = opts.Rating

		local ratingHolder = Instance.new("Frame")
		ratingHolder.Name = "Rating"
		ratingHolder.BackgroundTransparency = 1
		ratingHolder.Position = UDim2.new(0, 10, 1, -(ratingBlockH + buttonReserve))
		ratingHolder.Size = UDim2.new(1, -20, 0, ratingBlockH - RATING_BOTTOM_MARGIN)
		ratingHolder.ZIndex = Z.Content + 1
		ratingHolder.Parent = card

		local divider = Instance.new("Frame")
		divider.Name = "Divider"
		divider.BackgroundColor3 = Color3.new(1, 1, 1)
		divider.BackgroundTransparency = 0.94
		divider.BorderSizePixel = 0
		divider.Size = UDim2.new(1, 0, 0, 1)
		divider.ZIndex = Z.Content + 1
		divider.Parent = ratingHolder

		local ratingBody = Instance.new("Frame")
		ratingBody.BackgroundTransparency = 1
		ratingBody.Position = UDim2.new(0, 0, 0, RATING_TOP_GAP)
		ratingBody.Size = UDim2.new(1, 0, 1, -RATING_TOP_GAP)
		ratingBody.ZIndex = Z.Content + 1
		ratingBody.Parent = ratingHolder

		local ratingLayout = Instance.new("UIListLayout")
		ratingLayout.Padding = UDim.new(0, RATING_ROW_GAP)
		ratingLayout.SortOrder = Enum.SortOrder.LayoutOrder
		ratingLayout.Parent = ratingBody

		if ratingHasTitle then
			local ratingLabel = Instance.new("TextLabel")
			ratingLabel.BackgroundTransparency = 1
			ratingLabel.FontFace = NullUI.Theme.Font
			ratingLabel.Text = ratingOpts.Title
			ratingLabel.TextColor3 = NullUI.Theme.Text
			Role(ratingLabel, "Text")
			ratingLabel.TextSize = 13
			ratingLabel.TextXAlignment = Enum.TextXAlignment.Left
			ratingLabel.Size = UDim2.new(1, 0, 0, RATING_LABEL_H)
			ratingLabel.LayoutOrder = 1
			ratingLabel.ZIndex = Z.Content + 1
			ratingLabel.Parent = ratingBody
		end

		local starBar = BuildStarRow(
			ratingBody,
			2,
			math.max(1, ratingOpts.MaxStars or 5),
			ratingOpts.StarColor or Color3.fromRGB(255, 196, 64),
			RATING_STAR_H,
			ratingOpts.Default
		)
		local feedback = BuildFeedbackRow(ratingBody, 3, RATING_INPUT_H, ratingOpts.Placeholder, ratingOpts.ButtonIcon)

		local clearOnSubmit = ratingOpts.ClearOnSubmit ~= false
		feedback.SendBtn.MouseButton1Click:Connect(function()
			local sel = starBar.Get()
			if sel <= 0 then
				starBar.Nudge()
				return
			end
			if ratingOpts.Callback then
				SafeSpawn(ratingOpts.Callback, sel, feedback.Box.Text)
			end
			if ratingOpts.WebhookUrl then
				SafeSpawn(function()
					NullUI:SendFeedbackWebhook(ratingOpts.WebhookUrl, sel, feedback.Box.Text, ratingOpts.WebhookOptions)
				end)
			end
			if clearOnSubmit then
				feedback.Box.Text = ""
				starBar.Set(ratingOpts.Default or 0)
			end
		end)

		ratingBar = {
			Get = function()
				return starBar.Get(), feedback.Box.Text
			end,
			Set = function(newStars, newText)
				starBar.Set(newStars)
				if newText ~= nil then
					feedback.Box.Text = newText
				end
			end,
		}
	end

	return {
		Instance = card,
		Rating = ratingBar,
		Destroy = function()
			card:Destroy()
		end,
	}
end

local CHANGELOG_TYPES = {
	Added = { Color = Color3.fromRGB(120, 210, 140), Icon = "plus" },
	Fixed = { Color = Color3.fromRGB(120, 170, 255), Icon = "wrench" },
	Changed = { Color = Color3.fromRGB(255, 190, 90), Icon = "refresh-cw" },
	Removed = { Color = Color3.fromRGB(230, 120, 120), Icon = "minus" },
}

function Tab:AddChangelogEntry(opts)
	opts = opts or {}
	local version = opts.Version or "Update"
	local date = opts.Date
	local changes = opts.Changes or {}

	local PAD = 12
	local HEADER_H = 18
	local ROW_H = 22
	local ROW_GAP = 2
	local height = PAD * 2 + HEADER_H + (#changes > 0 and 8 or 0)

	local card = BaseCard(self._page, height)
	card.AutomaticSize = Enum.AutomaticSize.Y
	self._window:_RegisterSearchable(self, version, card)

	local pad = Instance.new("UIPadding")
	pad.PaddingTop = UDim.new(0, PAD)
	pad.PaddingBottom = UDim.new(0, PAD)
	pad.PaddingLeft = UDim.new(0, PAD)
	pad.PaddingRight = UDim.new(0, PAD)
	pad.Parent = card

	local versionLabel = Instance.new("TextLabel")
	versionLabel.BackgroundTransparency = 1
	versionLabel.FontFace = NullUI.Theme.Font
	versionLabel.Text = version
	versionLabel.TextColor3 = NullUI.Theme.Text
	Role(versionLabel, "Text")
	versionLabel.TextSize = 14
	versionLabel.TextXAlignment = Enum.TextXAlignment.Left
	versionLabel.TextTruncate = Enum.TextTruncate.AtEnd
	versionLabel.Size = UDim2.new(1, date and -90 or 0, 0, HEADER_H)
	versionLabel.ZIndex = Z.Content + 1
	versionLabel.Parent = card

	if date then
		local dateLabel = Instance.new("TextLabel")
		dateLabel.BackgroundTransparency = 1
		dateLabel.FontFace = NullUI.Theme.FontRegular
		dateLabel.Text = date
		dateLabel.TextColor3 = NullUI.Theme.TextDim
		Role(dateLabel, "TextDim")
		dateLabel.TextSize = 12
		dateLabel.TextXAlignment = Enum.TextXAlignment.Right
		dateLabel.AnchorPoint = Vector2.new(1, 0)
		dateLabel.Position = UDim2.new(1, 0, 0, 2)
		dateLabel.Size = UDim2.fromOffset(90, HEADER_H)
		dateLabel.ZIndex = Z.Content + 1
		dateLabel.Parent = card
	end

	local rowsHolder = Instance.new("Frame")
	rowsHolder.Name = "Rows"
	rowsHolder.BackgroundTransparency = 1
	rowsHolder.Position = UDim2.fromOffset(0, HEADER_H + 8)
	rowsHolder.Size = UDim2.new(1, 0, 0, 0)
	rowsHolder.AutomaticSize = Enum.AutomaticSize.Y
	rowsHolder.ZIndex = Z.Content + 1
	rowsHolder.Parent = card

	local rowsLayout = Instance.new("UIListLayout")
	rowsLayout.FillDirection = Enum.FillDirection.Vertical
	rowsLayout.SortOrder = Enum.SortOrder.LayoutOrder
	rowsLayout.Padding = UDim.new(0, ROW_GAP)
	rowsLayout.Parent = rowsHolder

	for i, change in ipairs(changes) do
		local kind = CHANGELOG_TYPES[change.Type] and change.Type or "Changed"
		local meta = CHANGELOG_TYPES[kind]

		local row = Instance.new("Frame")
		row.Name = "Row" .. i
		row.BackgroundTransparency = 1
		row.Size = UDim2.new(1, 0, 0, ROW_H)
		row.AutomaticSize = Enum.AutomaticSize.Y
		row.LayoutOrder = i * 2 - 1
		row.ZIndex = Z.Content + 1
		row.Parent = rowsHolder

		local pill = Instance.new("Frame")
		pill.BackgroundColor3 = meta.Color
		pill.BackgroundTransparency = 0.85
		pill.BorderSizePixel = 0
		pill.AnchorPoint = Vector2.zero
		pill.Position = UDim2.fromOffset(0, 1)
		pill.Size = UDim2.fromOffset(66, 18)
		pill.ZIndex = Z.Content + 2
		pill.Parent = row
		Corner(pill, 5)

		local pillLayout = Instance.new("UIListLayout")
		pillLayout.FillDirection = Enum.FillDirection.Horizontal
		pillLayout.VerticalAlignment = Enum.VerticalAlignment.Center
		pillLayout.HorizontalAlignment = Enum.HorizontalAlignment.Center
		pillLayout.Padding = UDim.new(0, 3)
		pillLayout.Parent = pill

		local pillIcon = Instance.new("ImageLabel")
		pillIcon.BackgroundTransparency = 1
		pillIcon.Image = ResolveIcon(meta.Icon)
		pillIcon.ImageColor3 = meta.Color
		pillIcon.Size = UDim2.fromOffset(9, 9)
		pillIcon.LayoutOrder = 1
		pillIcon.ZIndex = Z.Content + 3
		pillIcon.Parent = pill

		local pillLabel = Instance.new("TextLabel")
		pillLabel.BackgroundTransparency = 1
		pillLabel.FontFace = NullUI.Theme.Font
		pillLabel.Text = string.upper(kind)
		pillLabel.TextColor3 = meta.Color
		pillLabel.TextSize = 9
		pillLabel.AutomaticSize = Enum.AutomaticSize.X
		pillLabel.Size = UDim2.fromOffset(0, 12)
		pillLabel.LayoutOrder = 2
		pillLabel.ZIndex = Z.Content + 3
		pillLabel.Parent = pill

		local changeLabel = Instance.new("TextLabel")
		changeLabel.BackgroundTransparency = 1
		changeLabel.FontFace = NullUI.Theme.FontRegular
		changeLabel.Text = tostring(change.Text or "")
		changeLabel.TextColor3 = NullUI.Theme.TextDim
		Role(changeLabel, "TextDim")
		changeLabel.TextSize = 12
		changeLabel.TextXAlignment = Enum.TextXAlignment.Left
		changeLabel.TextYAlignment = Enum.TextYAlignment.Top
		changeLabel.TextWrapped = true
		changeLabel.TextTruncate = Enum.TextTruncate.None
		changeLabel.AutomaticSize = Enum.AutomaticSize.Y
		changeLabel.Position = UDim2.fromOffset(76, 0)
		changeLabel.Size = UDim2.new(1, -76, 0, ROW_H)
		changeLabel.ZIndex = Z.Content + 2
		changeLabel.Parent = row

		local function alignChangelogRow()
			local isMultiline = changeLabel.TextBounds.Y > 18
			if isMultiline then
				pill.AnchorPoint = Vector2.zero
				pill.Position = UDim2.fromOffset(0, 1)
				changeLabel.TextYAlignment = Enum.TextYAlignment.Top
			else
				pill.AnchorPoint = Vector2.new(0, 0.5)
				pill.Position = UDim2.new(0, 0, 0.5, 0)
				changeLabel.TextYAlignment = Enum.TextYAlignment.Center
			end
		end
		changeLabel:GetPropertyChangedSignal("TextBounds"):Connect(alignChangelogRow)
		SafeDefer(alignChangelogRow)

		if i < #changes then
			local separator = Instance.new("Frame")
			separator.Name = "Separator" .. i
			separator.BackgroundColor3 = Color3.new(1, 1, 1)
			separator.BackgroundTransparency = 0.93
			separator.BorderSizePixel = 0
			separator.Size = UDim2.new(1, 0, 0, 1)
			separator.LayoutOrder = i * 2
			separator.ZIndex = Z.Content + 1
			separator.Parent = rowsHolder
		end
	end

	return {
		Instance = card,
		Destroy = function()
			card:Destroy()
		end,
	}
end

function Tab:AddLoadoutGroup(opts)
	opts = opts or {}
	local title = opts.Title or "Loadout"
	local color = opts.Color or NullUI.Theme.Accent
	local icons = opts.Icons or {}
	local buttonText = opts.ButtonText or "Equip"

	local PAD = 12
	local HEADER_H = 16
	local ICON_SIZE = 44
	local ROW_GAP = 8
	local BUTTON_H = 30
	local GAP1, GAP2 = 8, 10
	local height = PAD * 2 + HEADER_H + GAP1 + ICON_SIZE + GAP2 + BUTTON_H

	local card = BaseCard(self._page, height)
	self._window:_RegisterSearchable(self, title, card)

	local pad = Instance.new("UIPadding")
	pad.PaddingTop = UDim.new(0, PAD)
	pad.PaddingBottom = UDim.new(0, PAD)
	pad.PaddingLeft = UDim.new(0, PAD)
	pad.PaddingRight = UDim.new(0, PAD)
	pad.Parent = card

	local header = Instance.new("Frame")
	header.BackgroundTransparency = 1
	header.Position = UDim2.fromOffset(0, 0)
	header.Size = UDim2.new(1, 0, 0, HEADER_H)
	header.ZIndex = Z.Content + 1
	header.Parent = card

	local dot = Instance.new("Frame")
	dot.AnchorPoint = Vector2.new(0, 0.5)
	dot.Position = UDim2.new(0, 1, 0.5, 0)
	dot.Size = UDim2.fromOffset(6, 6)
	dot.BackgroundColor3 = color
	dot.BorderSizePixel = 0
	dot.ZIndex = Z.Content + 2
	dot.Parent = header
	Corner(dot, 3)

	local titleLabel = Instance.new("TextLabel")
	titleLabel.BackgroundTransparency = 1
	titleLabel.FontFace = NullUI.Theme.Font
	titleLabel.Text = string.upper(title)
	titleLabel.TextColor3 = NullUI.Theme.TextDim
	Role(titleLabel, "TextDim")
	titleLabel.TextSize = 12
	titleLabel.TextXAlignment = Enum.TextXAlignment.Left
	titleLabel.Position = UDim2.fromOffset(15, 0)
	titleLabel.Size = UDim2.new(1, -15, 1, 0)
	titleLabel.ZIndex = Z.Content + 2
	titleLabel.Parent = header

	local iconsRow = Instance.new("Frame")
	iconsRow.Name = "Icons"
	iconsRow.BackgroundTransparency = 1
	iconsRow.Position = UDim2.fromOffset(0, HEADER_H + GAP1)
	iconsRow.Size = UDim2.new(1, 0, 0, ICON_SIZE)
	iconsRow.ZIndex = Z.Content + 1
	iconsRow.Parent = card

	local rowLayout = Instance.new("UIListLayout")
	rowLayout.FillDirection = Enum.FillDirection.Horizontal
	rowLayout.Padding = UDim.new(0, ROW_GAP)
	rowLayout.SortOrder = Enum.SortOrder.LayoutOrder
	rowLayout.Parent = iconsRow

	for i, iconAsset in ipairs(icons) do
		local slot = Instance.new("Frame")
		slot.Name = "Slot" .. i
		slot.BackgroundColor3 = Color3.new(1, 1, 1)
		slot.BackgroundTransparency = 0.95
		slot.BorderSizePixel = 0
		slot.ClipsDescendants = true
		slot.Size = UDim2.new(1 / 3, -ROW_GAP * 2 / 3, 1, 0)
		slot.LayoutOrder = i
		slot.ZIndex = Z.Content + 2
		slot.Parent = iconsRow
		Corner(slot, NullUI.Theme.CornerRadiusSm)
		Stroke(slot, Color3.new(1, 1, 1), 1, 0.94)

		local img = Instance.new("ImageLabel")
		img.BackgroundTransparency = 1
		img.Image = ResolveIcon(iconAsset)
		img.ImageColor3 = color
		img.ScaleType = Enum.ScaleType.Fit
		img.Position = UDim2.fromOffset(8, 8)
		img.Size = UDim2.new(1, -16, 1, -16)
		img.ZIndex = Z.Content + 3
		img.Parent = slot
	end

	local btn = Instance.new("TextButton")
	btn.Name = "EquipButton"
	btn.Text = ""
	btn.AutoButtonColor = false
	btn.BackgroundColor3 = Color3.new(1, 1, 1)
	btn.BackgroundTransparency = 0.92
	btn.BorderSizePixel = 0
	btn.Position = UDim2.fromOffset(0, HEADER_H + GAP1 + ICON_SIZE + GAP2)
	btn.Size = UDim2.new(1, 0, 0, BUTTON_H)
	btn.ZIndex = Z.Content + 1
	btn.Parent = card
	Corner(btn, 8)

	local btnLabel = Instance.new("TextLabel")
	btnLabel.BackgroundTransparency = 1
	btnLabel.FontFace = NullUI.Theme.Font
	btnLabel.Text = buttonText
	btnLabel.TextColor3 = NullUI.Theme.Text
	Role(btnLabel, "Text")
	btnLabel.TextSize = 12
	btnLabel.Size = UDim2.fromScale(1, 1)
	btnLabel.ZIndex = Z.Content + 2
	btnLabel.Parent = btn

	btn.MouseEnter:Connect(function()
		Tween(btn, { BackgroundTransparency = 0.85 }, 0.12)
	end)
	btn.MouseLeave:Connect(function()
		Tween(btn, { BackgroundTransparency = 0.92 }, 0.12)
	end)
	btn.MouseButton1Click:Connect(function()
		Tween(btn, { BackgroundTransparency = 0.7 }, 0.08)
		SafeDelay(0.08, function()
			if btn.Parent then
				Tween(btn, { BackgroundTransparency = 0.85 }, 0.18)
			end
		end)
		if opts.Callback then
			SafeSpawn(opts.Callback)
		end
	end)

	return {
		Instance = card,
		Destroy = function()
			card:Destroy()
		end,
	}
end

function Tab:AddInfoGrid(opts)
	opts = opts or {}
	local title = opts.Title or "Info"
	local hasDesc = opts.Description and opts.Description ~= ""
	local items = opts.Items or {}
	local color = opts.Color
	local columns = opts.Columns or 2

	local PAD = 12
	local HEADER_H = hasDesc and 32 or 16
	local CHIP_H = 38
	local GRID_GAP = 8
	local rows = math.ceil(#items / columns)
	local gridH = rows > 0 and (rows * CHIP_H + (rows - 1) * GRID_GAP) or 0
	local height = PAD * 2 + HEADER_H + (rows > 0 and (10 + gridH) or 0)

	local card = BaseCard(self._page, height)
	self._window:_RegisterSearchable(self, title, card)

	local leftInset = 0
	if color then
		local accent = Instance.new("Frame")
		accent.Name = "Accent"
		accent.BackgroundColor3 = color
		accent.BorderSizePixel = 0
		accent.Size = UDim2.new(0, 3, 1, -12)
		accent.Position = UDim2.fromOffset(0, 6)
		accent.ZIndex = Z.Content + 1
		accent.Parent = card
		Corner(accent, 1.5)
		leftInset = 6
	end

	local pad = Instance.new("UIPadding")
	pad.PaddingTop = UDim.new(0, PAD)
	pad.PaddingBottom = UDim.new(0, PAD)
	pad.PaddingLeft = UDim.new(0, PAD + leftInset)
	pad.PaddingRight = UDim.new(0, PAD)
	pad.Parent = card

	local titleLabel = Instance.new("TextLabel")
	titleLabel.BackgroundTransparency = 1
	titleLabel.FontFace = NullUI.Theme.Font
	titleLabel.Text = title
	titleLabel.TextColor3 = NullUI.Theme.Text
	Role(titleLabel, "Text")
	titleLabel.TextSize = 14
	titleLabel.TextXAlignment = Enum.TextXAlignment.Left
	titleLabel.TextTruncate = Enum.TextTruncate.AtEnd
	titleLabel.Position = UDim2.fromOffset(0, 0)
	titleLabel.Size = UDim2.new(1, 0, 0, 16)
	titleLabel.ZIndex = Z.Content + 1
	titleLabel.Parent = card

	if hasDesc then
		local descLabel = Instance.new("TextLabel")
		descLabel.BackgroundTransparency = 1
		descLabel.FontFace = NullUI.Theme.FontRegular
		descLabel.Text = opts.Description
		descLabel.TextColor3 = NullUI.Theme.TextDim
		Role(descLabel, "TextDim")
		descLabel.TextSize = 12
		descLabel.TextWrapped = true
		descLabel.TextXAlignment = Enum.TextXAlignment.Left
		descLabel.TextYAlignment = Enum.TextYAlignment.Top
		descLabel.Position = UDim2.fromOffset(0, 18)
		descLabel.Size = UDim2.new(1, 0, 0, 14)
		descLabel.ZIndex = Z.Content + 1
		descLabel.Parent = card
	end

	local chipValues = {}

	if rows > 0 then
		local grid = Instance.new("Frame")
		grid.Name = "Grid"
		grid.BackgroundTransparency = 1
		grid.Position = UDim2.fromOffset(0, HEADER_H + 10)
		grid.Size = UDim2.new(1, 0, 0, gridH)
		grid.ZIndex = Z.Content + 1
		grid.Parent = card

		local gridLayout = Instance.new("UIGridLayout")
		gridLayout.CellPadding = UDim2.fromOffset(GRID_GAP, GRID_GAP)
		gridLayout.FillDirectionMaxCells = columns
		gridLayout.SortOrder = Enum.SortOrder.LayoutOrder
		gridLayout.Parent = grid

		local function relayout()
			local w = grid.AbsoluteSize.X / GetUIScale()
			if w <= 0 then
				return
			end
			local cellW = (w - GRID_GAP * (columns - 1)) / columns
			gridLayout.CellSize = UDim2.fromOffset(cellW, CHIP_H)
		end
		grid:GetPropertyChangedSignal("AbsoluteSize"):Connect(relayout)
		SafeDefer(relayout)

		for i, item in ipairs(items) do
			local chip = Instance.new("Frame")
			chip.Name = "Chip" .. i
			chip.BackgroundColor3 = Color3.new(1, 1, 1)
			chip.BackgroundTransparency = 0.95
			chip.BorderSizePixel = 0
			chip.LayoutOrder = i
			chip.ZIndex = Z.Content + 2
			chip.Parent = grid
			Corner(chip, 6)

			local chipPad = Instance.new("UIPadding")
			chipPad.PaddingTop = UDim.new(0, 6)
			chipPad.PaddingLeft = UDim.new(0, 8)
			chipPad.PaddingRight = UDim.new(0, 8)
			chipPad.Parent = chip

			local labelLabel = Instance.new("TextLabel")
			labelLabel.BackgroundTransparency = 1
			labelLabel.FontFace = NullUI.Theme.Font
			labelLabel.Text = tostring(item.Label or "")
			labelLabel.TextColor3 = NullUI.Theme.Text
			Role(labelLabel, "Text")
			labelLabel.TextSize = 12
			labelLabel.TextXAlignment = Enum.TextXAlignment.Left
			labelLabel.TextTruncate = Enum.TextTruncate.AtEnd
			labelLabel.Size = UDim2.new(1, 0, 0, 15)
			labelLabel.ZIndex = Z.Content + 3
			labelLabel.Parent = chip

			local valueLabel = Instance.new("TextLabel")
			valueLabel.Name = "Value"
			valueLabel.BackgroundTransparency = 1
			valueLabel.FontFace = NullUI.Theme.FontRegular
			valueLabel.Text = tostring(item.Value or "")
			valueLabel.TextColor3 = NullUI.Theme.TextDim
			Role(valueLabel, "TextDim")
			valueLabel.TextSize = 11
			valueLabel.TextXAlignment = Enum.TextXAlignment.Left
			valueLabel.TextTruncate = Enum.TextTruncate.AtEnd
			valueLabel.Position = UDim2.fromOffset(0, 15)
			valueLabel.Size = UDim2.new(1, 0, 0, 12)
			valueLabel.ZIndex = Z.Content + 3
			valueLabel.Parent = chip

			if item.Label then
				chipValues[item.Label] = valueLabel
			end
		end
	end

	return {
		Instance = card,
		SetValue = function(_, label, value)
			local lbl = chipValues[label]
			if lbl then
				lbl.Text = tostring(value)
			end
		end,
		Destroy = function()
			card:Destroy()
		end,
	}
end

function Tab:AddSystemInfoGrid(opts)
	opts = opts or {}
	local Stats = game:GetService("Stats")
	local LocalPlayer = Players.LocalPlayer

	local runCount = BumpRunCount()

	local grid = self:AddInfoGrid({
		Title = opts.Title or "System Info",
		Description = opts.Description,
		Color = opts.Color,
		Columns = opts.Columns or 2,
		Items = {
			{ Label = "FPS", Value = "--" },
			{ Label = "Ping", Value = "-- ms" },
			{ Label = "Executor", Value = GetExecutorName() },
			{ Label = "Executions", Value = tostring(runCount) },
			{ Label = "Server Region", Value = "Unknown" },
			{ Label = "Time of Day", Value = "--:--" },
		},
	})

	local frames = 0
	local lastFpsUpdate = os.clock()
	self._janitor:Add(RunService.Heartbeat:Connect(function()
		LPH_ATTRIBUTES(VM(NONE))
		frames = frames + 1
		local now = os.clock()
		local elapsed = now - lastFpsUpdate
		if elapsed >= 1 then
			grid:SetValue("FPS", math.floor(frames / elapsed + 0.5))
			frames = 0
			lastFpsUpdate = now
		end
	end))

	local alive = true
	self._janitor:Add(function()
		alive = false
	end)

	SafeSpawn(function()
		while alive and grid.Instance.Parent do
			pcall(function()
				local ping = 0
				pcall(function()
					ping = math.clamp(Stats.Network.ServerStatsItem["Data Ping"]:GetValue(), 0, 9999)
				end)
				grid:SetValue("Ping", math.floor(ping) .. " ms")

				local h = tonumber(os.date("%H"))
				local m = tonumber(os.date("%M"))
				grid:SetValue("Time of Day", FormatClock(h * 60 + m))
			end)
			task.wait(1)
		end
	end)

	SafeSpawn(function()
		local ok, region = pcall(function()
			return game:GetService("LocalizationService"):GetCountryRegionForPlayerAsync(LocalPlayer)
		end)
		if ok and region and alive then
			grid:SetValue("Server Region", region)
		end
	end)

	return grid
end

function Tab:AddActiveUsersGrid(opts)
	opts = opts or {}
	local service = opts.Service
	local interval = opts.Interval or 30

	local grid = self:AddInfoGrid({
		Title = opts.Title or "Active Users",
		Description = opts.Description,
		Color = opts.Color,
		Columns = 1,
		Items = { { Label = "Active Now", Value = "--" } },
	})

	if not service then
		grid:SetValue("Active Now", "No Service configured")
		return grid
	end

	local alive = true
	self._janitor:Add(function()
		alive = false
	end)

	SafeSpawn(function()
		while alive and grid.Instance.Parent do
			service:Heartbeat()
			local count, err = service:GetActiveCount()
			if alive and grid.Instance.Parent then
				grid:SetValue("Active Now", count and tostring(count) or ("Error: " .. tostring(err)))
			end
			task.wait(interval)
		end
	end)

	return grid
end

function Tab:AddLeaderboard(opts)
	opts = opts or {}
	local jan = self._janitor
	local service = opts.Service
	local interval = opts.Interval or 30
	local limit = math.clamp(opts.Limit or 5, 1, 50)
	local title = opts.Title or "Leaderboard"
	local hasDesc = opts.Description and opts.Description ~= ""

	local PAD = 12
	local HEADER_H = hasDesc and 32 or 16
	local ROW_H, ROW_GAP = 44, 6
	local listY = PAD + HEADER_H + 12
	local listH = limit * ROW_H + (limit - 1) * ROW_GAP
	local totalHeight = listY + listH + PAD

	local container = Instance.new("Frame")
	container.Name = "Leaderboard"
	container.BackgroundColor3 = NullUI.Theme.Surface
	container.BackgroundTransparency = 0.35
	container.BorderSizePixel = 0
	container.ClipsDescendants = true
	container.Size = UDim2.new(1, 0, 0, totalHeight)
	container.ZIndex = Z.Content
	container.Parent = self._page
	Corner(container, NullUI.Theme.CornerRadiusSm)
	Stroke(container, Color3.new(1, 1, 1), 1, 0.92)
	self._window:_RegisterSearchable(self, title, container)

	local titleLabel = Instance.new("TextLabel")
	titleLabel.BackgroundTransparency = 1
	titleLabel.FontFace = NullUI.Theme.Font
	titleLabel.Text = title
	titleLabel.TextColor3 = NullUI.Theme.Text
	Role(titleLabel, "Text")
	titleLabel.TextSize = 14
	titleLabel.TextXAlignment = Enum.TextXAlignment.Left
	titleLabel.TextTruncate = Enum.TextTruncate.AtEnd
	titleLabel.Position = UDim2.fromOffset(PAD, PAD)
	titleLabel.Size = UDim2.new(1, -PAD * 2 - 32, 0, 16)
	titleLabel.ZIndex = Z.Content + 1
	titleLabel.Parent = container

	if hasDesc then
		local descLabel = Instance.new("TextLabel")
		descLabel.BackgroundTransparency = 1
		descLabel.FontFace = NullUI.Theme.FontRegular
		descLabel.Text = opts.Description
		descLabel.TextColor3 = NullUI.Theme.TextDim
		Role(descLabel, "TextDim")
		descLabel.TextSize = 12
		descLabel.TextWrapped = true
		descLabel.TextXAlignment = Enum.TextXAlignment.Left
		descLabel.TextYAlignment = Enum.TextYAlignment.Top
		descLabel.Position = UDim2.fromOffset(PAD, PAD + 18)
		descLabel.Size = UDim2.new(1, -PAD * 2 - 32, 0, 14)
		descLabel.ZIndex = Z.Content + 1
		descLabel.Parent = container
	end

	local revealMe = opts.RevealByDefault == true

	local revealBtn = Instance.new("TextButton")
	revealBtn.Name = "RevealToggle"
	revealBtn.Text = ""
	revealBtn.AutoButtonColor = false
	revealBtn.BackgroundColor3 = Color3.new(1, 1, 1)
	revealBtn.BackgroundTransparency = 1
	revealBtn.BorderSizePixel = 0
	revealBtn.AnchorPoint = Vector2.new(1, 0)
	revealBtn.Position = UDim2.new(1, -PAD, 0, PAD - 4)
	revealBtn.Size = UDim2.fromOffset(24, 24)
	revealBtn.ZIndex = Z.Content + 2
	revealBtn.Parent = container
	Corner(revealBtn, 7)

	local revealIcon = Instance.new("ImageLabel")
	revealIcon.BackgroundTransparency = 1
	revealIcon.Image = ResolveIcon(revealMe and "eye" or "eye-off")
	revealIcon.ImageColor3 = NullUI.Theme.TextDim
	Role(revealIcon, "TextDim")
	revealIcon.Size = UDim2.fromOffset(14, 14)
	revealIcon.AnchorPoint = Vector2.new(0.5, 0.5)
	revealIcon.Position = UDim2.fromScale(0.5, 0.5)
	revealIcon.ZIndex = Z.Content + 3
	revealIcon.Parent = revealBtn

	jan:Add(revealBtn.MouseEnter:Connect(function()
		Tween(revealBtn, { BackgroundTransparency = 0.9 }, 0.12)
		Tween(revealIcon, { ImageColor3 = NullUI.Theme.Text }, 0.12)
	end))
	jan:Add(revealBtn.MouseLeave:Connect(function()
		Tween(revealBtn, { BackgroundTransparency = 1 }, 0.12)
		Tween(revealIcon, { ImageColor3 = NullUI.Theme.TextDim }, 0.12)
	end))

	local divider = Instance.new("Frame")
	divider.BackgroundColor3 = Color3.new(1, 1, 1)
	divider.BackgroundTransparency = 0.92
	divider.BorderSizePixel = 0
	divider.Position = UDim2.fromOffset(0, PAD + HEADER_H + 8)
	divider.Size = UDim2.new(1, 0, 0, 1)
	divider.ZIndex = Z.Content + 1
	divider.Parent = container

	local list = Instance.new("Frame")
	list.Name = "Rows"
	list.BackgroundTransparency = 1
	list.Position = UDim2.fromOffset(PAD, listY)
	list.Size = UDim2.new(1, -PAD * 2, 0, listH)
	list.ZIndex = Z.Content + 1
	list.Parent = container

	local listLayout = Instance.new("UIListLayout")
	listLayout.Padding = UDim.new(0, ROW_GAP)
	listLayout.SortOrder = Enum.SortOrder.LayoutOrder
	listLayout.Parent = list

	local emptyLabel = Instance.new("TextLabel")
	emptyLabel.BackgroundTransparency = 1
	emptyLabel.FontFace = NullUI.Theme.FontRegular
	emptyLabel.Text = "No one's run this yet"
	emptyLabel.TextColor3 = NullUI.Theme.TextDim
	Role(emptyLabel, "TextDim")
	emptyLabel.TextSize = 12
	emptyLabel.Position = UDim2.fromOffset(PAD, listY + 10)
	emptyLabel.Size = UDim2.new(1, -PAD * 2, 0, 16)
	emptyLabel.Visible = false
	emptyLabel.ZIndex = Z.Content + 1
	emptyLabel.Parent = container

	local RANK_COLORS = {
		[1] = Color3.fromRGB(255, 196, 64),
		[2] = Color3.fromRGB(203, 209, 217),
		[3] = Color3.fromRGB(205, 141, 92),
	}
	local RANK_ICONS = { [1] = "crown", [2] = "medal", [3] = "medal" }

	local function formatSeconds(total)
		total = math.floor(total or 0)
		local h = math.floor(total / 3600)
		local m = math.floor((total % 3600) / 60)
		if h > 0 then
			return string.format("%dh %dm", h, m)
		end
		if m > 0 then
			return string.format("%dm", m)
		end
		return string.format("%ds", total)
	end

	local function fallbackLabel(identity)
		local tag = (identity or ""):gsub("-", ""):sub(1, 4):upper()
		return "Player-" .. (tag ~= "" and tag or "????")
	end

	local rowFrames = {}
	local function clearRows()
		for _, f in ipairs(rowFrames) do
			f:Destroy()
		end
		table.clear(rowFrames)
	end

	local function buildRow(index, item)
		local rankColor = RANK_COLORS[index]

		local row = Instance.new("Frame")
		row.Name = "Row" .. index
		row.Active = true
		row.BackgroundColor3 = Color3.new(1, 1, 1)
		row.BackgroundTransparency = item.IsYou and 0.9 or 0.96
		row.BorderSizePixel = 0
		row.LayoutOrder = index
		row.Size = UDim2.new(1, 0, 0, ROW_H)
		row.ZIndex = Z.Content + 2
		row.Parent = list
		Corner(row, NullUI.Theme.CornerRadiusSm)
		Stroke(row, Color3.new(1, 1, 1), 1, item.IsYou and 0.88 or 0.94)

		local baseTransparency = row.BackgroundTransparency
		row.MouseEnter:Connect(function()
			Tween(row, { BackgroundTransparency = baseTransparency - 0.05 }, 0.12)
		end)
		row.MouseLeave:Connect(function()
			Tween(row, { BackgroundTransparency = baseTransparency }, 0.12)
		end)

		local rowPad = Instance.new("UIPadding")
		rowPad.PaddingLeft = UDim.new(0, 10)
		rowPad.PaddingRight = UDim.new(0, 10)
		rowPad.Parent = row

		local badge = Instance.new("Frame")
		badge.AnchorPoint = Vector2.new(0, 0.5)
		badge.Position = UDim2.new(0, 0, 0.5, 0)
		badge.Size = UDim2.fromOffset(28, 28)
		badge.BackgroundColor3 = Color3.new(1, 1, 1)
		badge.BackgroundTransparency = 0.94
		badge.BorderSizePixel = 0
		badge.ZIndex = Z.Content + 3
		badge.Parent = row
		Corner(badge, 14)
		Stroke(badge, Color3.new(1, 1, 1), 1, 0.9)

		if rankColor then
			local badgeIcon = Instance.new("ImageLabel")
			badgeIcon.BackgroundTransparency = 1
			badgeIcon.Image = ResolveIcon(RANK_ICONS[index])
			badgeIcon.ImageColor3 = rankColor
			badgeIcon.Size = UDim2.fromOffset(15, 15)
			badgeIcon.AnchorPoint = Vector2.new(0.5, 0.5)
			badgeIcon.Position = UDim2.fromScale(0.5, 0.5)
			badgeIcon.ZIndex = Z.Content + 4
			badgeIcon.Parent = badge
		else
			local badgeLabel = Instance.new("TextLabel")
			badgeLabel.BackgroundTransparency = 1
			badgeLabel.FontFace = NullUI.Theme.Font
			badgeLabel.Text = "#" .. tostring(index)
			badgeLabel.TextColor3 = NullUI.Theme.TextDim
			Role(badgeLabel, "TextDim")
			badgeLabel.TextSize = 11
			badgeLabel.Size = UDim2.fromScale(1, 1)
			badgeLabel.ZIndex = Z.Content + 4
			badgeLabel.Parent = badge
		end

		local avatarHolder = Instance.new("Frame")
		avatarHolder.AnchorPoint = Vector2.new(0, 0.5)
		avatarHolder.Position = UDim2.new(0, 34, 0.5, 0)
		avatarHolder.Size = UDim2.fromOffset(28, 28)
		avatarHolder.BackgroundColor3 = Color3.new(1, 1, 1)
		avatarHolder.BackgroundTransparency = 0.94
		avatarHolder.BorderSizePixel = 0
		avatarHolder.ClipsDescendants = true
		avatarHolder.ZIndex = Z.Content + 3
		avatarHolder.Parent = row
		Corner(avatarHolder, 14)
		Stroke(avatarHolder, Color3.new(1, 1, 1), 1, 0.85)

		if item.UserId and item.UserId ~= 0 then
			local avatarImg = Instance.new("ImageLabel")
			avatarImg.BackgroundTransparency = 1
			avatarImg.ScaleType = Enum.ScaleType.Crop
			avatarImg.Size = UDim2.fromScale(1, 1)
			avatarImg.ZIndex = Z.Content + 4
			avatarImg.Parent = avatarHolder
			SafeSpawn(function()
				local ok, content = pcall(
					Players.GetUserThumbnailAsync,
					Players,
					item.UserId,
					Enum.ThumbnailType.HeadShot,
					Enum.ThumbnailSize.Size48x48
				)
				if ok and content and avatarImg.Parent then
					avatarImg.Image = content
				end
			end)
		else
			local placeholder = Instance.new("ImageLabel")
			placeholder.BackgroundTransparency = 1
			placeholder.Image = ResolveIcon("user")
			placeholder.ImageColor3 = NullUI.Theme.TextDim
			Role(placeholder, "TextDim")
			placeholder.Size = UDim2.fromOffset(14, 14)
			placeholder.AnchorPoint = Vector2.new(0.5, 0.5)
			placeholder.Position = UDim2.fromScale(0.5, 0.5)
			placeholder.ZIndex = Z.Content + 4
			placeholder.Parent = avatarHolder
		end

		local nameLabel = Instance.new("TextLabel")
		nameLabel.BackgroundTransparency = 1
		nameLabel.FontFace = NullUI.Theme.Font
		nameLabel.Text = (
			item.NamePreview and item.NamePreview ~= "" and item.NamePreview or fallbackLabel(item.Identity)
		) .. (item.IsYou and "  (You)" or "")
		nameLabel.TextColor3 = NullUI.Theme.Text
		Role(nameLabel, "Text")
		nameLabel.TextSize = 13
		nameLabel.TextXAlignment = Enum.TextXAlignment.Left
		nameLabel.TextTruncate = Enum.TextTruncate.AtEnd
		nameLabel.Position = UDim2.fromOffset(70, 0)
		nameLabel.Size = UDim2.new(1, -70 - 68, 1, 0)
		nameLabel.ZIndex = Z.Content + 3
		nameLabel.Parent = row

		local timeLabel = Instance.new("TextLabel")
		timeLabel.BackgroundTransparency = 1
		timeLabel.FontFace = NullUI.Theme.FontRegular
		timeLabel.Text = formatSeconds(item.Seconds)
		timeLabel.TextColor3 = NullUI.Theme.TextDim
		Role(timeLabel, "TextDim")
		timeLabel.TextSize = 12
		timeLabel.TextXAlignment = Enum.TextXAlignment.Right
		timeLabel.AnchorPoint = Vector2.new(1, 0)
		timeLabel.Position = UDim2.new(1, 0, 0, 0)
		timeLabel.Size = UDim2.fromOffset(60, ROW_H)
		timeLabel.ZIndex = Z.Content + 3
		timeLabel.Parent = row

		return row
	end

	local function renderRows(items)
		clearRows()
		emptyLabel.Visible = #items == 0

		for i, item in ipairs(items) do
			if i > limit then
				break
			end
			table.insert(rowFrames, buildRow(i, item))
		end
	end

	renderRows({})

	if not service then
		return { Instance = container }
	end

	local function maskName(letters, stars)
		local name = LocalPlayer.Name or ""
		return name:sub(1, letters) .. stars
	end

	jan:Add(revealBtn.MouseButton1Click:Connect(function()
		revealMe = not revealMe
		revealIcon.Image = ResolveIcon(revealMe and "eye" or "eye-off")
		NullUI:Notify({
			Title = "Leaderboard",
			Text = revealMe and "Your avatar and more of your name will show on the leaderboard."
				or "Back to anonymous -- only 2 letters of your name will show.",
			Type = "info",
			Duration = 3,
		})
	end))

	local alive = true
	jan:Add(function()
		alive = false
	end)

	SafeSpawn(function()
		while alive and container.Parent do
			local payload = revealMe and { UserId = LocalPlayer.UserId, NamePreview = maskName(4, "*******") }
				or { UserId = 0, NamePreview = maskName(2, "********") }
			service:Heartbeat(payload)

			local items, err = service:GetLeaderboard(limit)
			if alive and container.Parent and items then
				for _, item in ipairs(items) do
					item.IsYou = item.Identity == service.Identity
				end
				renderRows(items)
			end
			task.wait(interval)
		end
	end)

	return { Instance = container }
end

function Tab:AddGradientCard(opts)
	opts = opts or {}
	local title = opts.Title or "Card"
	local hasDesc = opts.Description and opts.Description ~= ""
	local colorA = opts.ColorA or Color3.fromRGB(88, 101, 242)
	local colorB = opts.ColorB or Color3.fromRGB(52, 58, 138)
	local height = hasDesc and 54 or 40

	local card = Instance.new("Frame")
	card.Name = title .. "GradientCard"
	card.BackgroundColor3 = colorA
	card.BorderSizePixel = 0
	card.Size = UDim2.new(1, 0, 0, height)
	card.ZIndex = Z.Content
	card.Parent = self._page
	Corner(card, NullUI.Theme.CornerRadiusSm)

	local gradient = Instance.new("UIGradient")
	gradient.Color = ColorSequence.new(colorA, colorB)
	gradient.Rotation = 100
	gradient.Parent = card

	self._window:_RegisterSearchable(self, title, card)

	local PAD = 14
	local rightReserve = opts.Callback and 32 or PAD

	local titleLabel = Instance.new("TextLabel")
	titleLabel.BackgroundTransparency = 1
	titleLabel.FontFace = NullUI.Theme.Font
	titleLabel.Text = title
	titleLabel.TextColor3 = Color3.new(1, 1, 1)
	titleLabel.TextSize = 14
	titleLabel.TextXAlignment = Enum.TextXAlignment.Left
	titleLabel.TextTruncate = Enum.TextTruncate.AtEnd
	titleLabel.Position = UDim2.fromOffset(PAD, hasDesc and 9 or 0)
	titleLabel.Size = UDim2.new(1, -(PAD + rightReserve), 0, 18)
	titleLabel.ZIndex = Z.Content + 1
	titleLabel.Parent = card

	if hasDesc then
		local descLabel = Instance.new("TextLabel")
		descLabel.BackgroundTransparency = 1
		descLabel.FontFace = NullUI.Theme.FontRegular
		descLabel.Text = opts.Description
		descLabel.TextColor3 = Color3.new(1, 1, 1)
		descLabel.TextTransparency = 0.3
		descLabel.TextSize = 12
		descLabel.TextXAlignment = Enum.TextXAlignment.Left
		descLabel.TextTruncate = Enum.TextTruncate.AtEnd
		descLabel.Position = UDim2.fromOffset(PAD, 29)
		descLabel.Size = UDim2.new(1, -(PAD + rightReserve), 0, 14)
		descLabel.ZIndex = Z.Content + 1
		descLabel.Parent = card
	end

	if opts.Callback then
		local chev = Instance.new("ImageLabel")
		chev.BackgroundTransparency = 1
		chev.Image = ResolveIcon("chevron-right")
		chev.ImageColor3 = Color3.new(1, 1, 1)
		chev.ImageTransparency = 0.2
		chev.Size = UDim2.fromOffset(14, 14)
		chev.AnchorPoint = Vector2.new(1, 0.5)
		chev.Position = UDim2.new(1, -14, 0.5, 0)
		chev.ZIndex = Z.Content + 1
		chev.Parent = card

		local veil = Instance.new("Frame")
		veil.Name = "HoverVeil"
		veil.BackgroundColor3 = Color3.new(1, 1, 1)
		veil.BackgroundTransparency = 1
		veil.BorderSizePixel = 0
		veil.Size = UDim2.fromScale(1, 1)
		veil.ZIndex = Z.Content + 2
		veil.Parent = card
		Corner(veil, NullUI.Theme.CornerRadiusSm)

		local click = Instance.new("TextButton")
		click.Text = ""
		click.AutoButtonColor = false
		click.BackgroundTransparency = 1
		click.Size = UDim2.fromScale(1, 1)
		click.ZIndex = Z.Content + 3
		click.Parent = card

		click.MouseEnter:Connect(function()
			Tween(veil, { BackgroundTransparency = 0.9 }, 0.18)
			Tween(chev, { Position = UDim2.new(1, -10, 0.5, 0) }, 0.18)
		end)
		click.MouseLeave:Connect(function()
			Tween(veil, { BackgroundTransparency = 1 }, 0.18)
			Tween(chev, { Position = UDim2.new(1, -14, 0.5, 0) }, 0.18)
		end)
		click.MouseButton1Click:Connect(function()
			Tween(veil, { BackgroundTransparency = 0.8 }, 0.08)
			SafeDelay(0.08, function()
				if veil.Parent then
					Tween(veil, { BackgroundTransparency = 0.9 }, 0.18)
				end
			end)
			SafeSpawn(opts.Callback)
		end)
	end

	return {
		Instance = card,
		Destroy = function()
			card:Destroy()
		end,
	}
end

function Tab:AddToggle(opts)
	opts = opts or {}
	local state = opts.Default == true
	local hasDesc = opts.Description and opts.Description ~= ""
	local height = hasDesc and 54 or 40
	local card = BaseCard(self._page, height)

	local textX = AddLeadingIcon(card, opts.Icon, height)
	AddTitleDesc(card, textX, 66, opts.Text or "Toggle", opts.Description, height)
	self._window:_RegisterSearchable(self, opts.Text or "Toggle", card)

	local switchBg = Instance.new("Frame")
	switchBg.AnchorPoint = Vector2.new(1, 0.5)
	switchBg.Position = UDim2.new(1, -14, 0.5, 0)
	switchBg.Size = UDim2.fromOffset(36, 18)
	switchBg.BackgroundColor3 = state and NullUI.Theme.Accent or Color3.fromRGB(46, 50, 49)
	switchBg.BackgroundTransparency = state and 0 or 0.32
	switchBg.BorderSizePixel = 0
	switchBg.ZIndex = Z.Content + 1
	switchBg.Parent = card
	switchBg:SetAttribute("NullUIAccent", true)
	Corner(switchBg, 11)

	-- The disabled state stays translucent so the window background remains visible
	-- through the control instead of turning into a flat gray pill.
	local switchStroke =
		Stroke(switchBg, state and NullUI.Theme.Accent or Color3.fromRGB(205, 212, 209), 1, state and 0.88 or 0.72)

	local switchGradient = Instance.new("UIGradient")
	switchGradient.Rotation = 90
	switchGradient.Color = ColorSequence.new({
		ColorSequenceKeypoint.new(0, Color3.fromRGB(255, 255, 255)),
		ColorSequenceKeypoint.new(1, Color3.fromRGB(190, 198, 194)),
	})
	switchGradient.Transparency = NumberSequence.new({
		NumberSequenceKeypoint.new(0, state and 0 or 0.76),
		NumberSequenceKeypoint.new(1, state and 0 or 0.94),
	})
	switchGradient.Parent = switchBg

	local switchScale = Instance.new("UIScale")
	switchScale.Scale = 1
	switchScale.Parent = switchBg

	local knob = Instance.new("Frame")
	knob.Size = UDim2.fromOffset(14, 14)
	knob.Position = state and UDim2.new(1, -16, 0.5, 0) or UDim2.new(0, 2, 0.5, 0)
	knob.AnchorPoint = Vector2.new(0, 0.5)
	knob.BackgroundColor3 = state and Color3.fromRGB(18, 18, 18) or Color3.fromRGB(226, 230, 228)
	knob.BackgroundTransparency = state and 0 or 0.06
	knob.BorderSizePixel = 0
	knob.ZIndex = Z.Content + 2
	knob.Parent = switchBg
	Corner(knob, 8)

	local click = Instance.new("TextButton")
	click.Text = ""
	click.AutoButtonColor = false
	click.BackgroundTransparency = 1
	click.Size = UDim2.fromScale(1, 1)
	click.ZIndex = Z.Content + 3
	click.Parent = card

	local function render()
		local anim = 0.28
		local style, dir = Enum.EasingStyle.Quint, Enum.EasingDirection.InOut
		-- The colour role follows the switch state: a theme change repaints an
		-- "on" switch straight from the palette and leaves an "off" one neutral.
		local switchRole = state and "Accent" or nil
		switchBg:SetAttribute(ROLE_ATTR, switchRole)
		switchStroke:SetAttribute(ROLE_ATTR, switchRole)
		RoleRegistry[switchBg] = switchRole
		RoleRegistry[switchStroke] = switchRole
		Tween(switchBg, {
			BackgroundColor3 = state and NullUI.Theme.Accent or Color3.fromRGB(46, 50, 49),
			BackgroundTransparency = state and 0 or 0.32,
		}, anim, style, dir)
		Tween(switchStroke, {
			Color = state and NullUI.Theme.Accent or Color3.fromRGB(205, 212, 209),
			Transparency = state and 0.88 or 0.72,
		}, anim, style, dir)
		switchGradient.Transparency = NumberSequence.new({
			NumberSequenceKeypoint.new(0, state and 0 or 0.76),
			NumberSequenceKeypoint.new(1, state and 0 or 0.94),
		})
		Tween(knob, {
			BackgroundColor3 = state and Color3.fromRGB(18, 18, 18) or Color3.fromRGB(226, 230, 228),
			BackgroundTransparency = state and 0 or 0.06,
			Position = state and UDim2.new(1, -16, 0.5, 0) or UDim2.new(0, 2, 0.5, 0),
		}, anim, style, dir)
	end

	local signal = MakeSignal()
	local function fireChanged(newState)
		if opts.Callback then
			SafeSpawn(opts.Callback, newState)
		end
		signal.Fire(newState)
	end

	local locked = opts.Locked == true
	click.MouseButton1Click:Connect(function()
		if locked then
			return
		end
		Tween(switchScale, { Scale = 0.91 }, 0.08, Enum.EasingStyle.Quad, Enum.EasingDirection.Out)
		SafeDelay(0.08, function()
			if switchScale.Parent then
				Tween(switchScale, { Scale = 1 }, 0.18, Enum.EasingStyle.Back, Enum.EasingDirection.Out)
			end
		end)
		state = not state
		render()
		fireChanged(state)
	end)

	card.MouseEnter:Connect(function()
		if not locked then
			Tween(card, { BackgroundTransparency = 0.93 }, 0.18)
			if not state then
				Tween(switchStroke, { Transparency = 0.55 }, 0.18)
				Tween(switchBg, { BackgroundTransparency = 0.24 }, 0.18)
			end
		end
	end)
	card.MouseLeave:Connect(function()
		Tween(card, { BackgroundTransparency = 0.96 }, 0.18)
		if not state then
			Tween(switchStroke, { Transparency = 0.72 }, 0.18)
			Tween(switchBg, { BackgroundTransparency = 0.32 }, 0.18)
		end
	end)

	return RegisterFlag(opts, {
		Instance = card,
		Set = function(_, value, silent)
			state = value == true
			render()
			if not silent then
				fireChanged(state)
			end
		end,
		Get = function()
			return state
		end,
		SetLocked = function(_, v)
			locked = v == true
			card.BackgroundTransparency = locked and 0.98 or 0.96
		end,
		OnChanged = function(_, fn)
			return signal.Connect(fn)
		end,
		Destroy = function()
			signal.Clear()
			card:Destroy()
		end,
	}, "Toggle")
end

local ActiveSliderOwner = nil

function Tab:AddSlider(opts)
	opts = opts or {}
	local min = tonumber(opts.Min) or 0
	local max = tonumber(opts.Max) or 100
	if max < min then
		min, max = max, min
	end
	local increment = tonumber(opts.Increment) or 1
	local value = math.clamp(tonumber(opts.Default) or min, min, max)

	local hasDesc = opts.Description and opts.Description ~= ""
	local jan = self._janitor

	local card = BaseCard(self._page, hasDesc and 72 or 52)
	local textX = AddLeadingIcon(card, opts.Icon, 24)
	local leadingIcon = card:FindFirstChild("LeadingIcon")
	if leadingIcon then
		leadingIcon.AnchorPoint = Vector2.new(0, 0)
		leadingIcon.Position = UDim2.fromOffset(14, 9)
	end

	local label = Instance.new("TextLabel")
	label.BackgroundTransparency = 1
	label.FontFace = NullUI.Theme.Font
	label.Text = opts.Text or "Slider"
	label.TextColor3 = NullUI.Theme.Text
	Role(label, "Text")
	label.TextSize = 14
	label.TextXAlignment = Enum.TextXAlignment.Left
	label.TextTruncate = Enum.TextTruncate.AtEnd
	label.Position = UDim2.fromOffset(textX, 8)
	label.Size = UDim2.new(1, -(textX + 76), 0, 18)
	label.ZIndex = Z.Content + 1
	label.Parent = card
	self._window:_RegisterSearchable(self, opts.Text or "Slider", card)

	local descLabel
	if hasDesc then
		descLabel = Instance.new("TextLabel")
		descLabel.BackgroundTransparency = 1
		descLabel.FontFace = NullUI.Theme.FontRegular
		descLabel.Text = opts.Description
		descLabel.TextColor3 = NullUI.Theme.TextDim
		Role(descLabel, "TextDim")
		descLabel.TextSize = 12
		descLabel.TextWrapped = true
		descLabel.TextXAlignment = Enum.TextXAlignment.Left
		descLabel.TextYAlignment = Enum.TextYAlignment.Top
		descLabel.AutomaticSize = Enum.AutomaticSize.Y
		descLabel.Position = UDim2.fromOffset(textX, 26)
		descLabel.Size = UDim2.new(1, -(textX + 14), 0, 14)
		descLabel.ZIndex = Z.Content + 1
		descLabel.Parent = card
	end

	local valueLabel = Instance.new("TextLabel")
	valueLabel.BackgroundTransparency = 1
	valueLabel.FontFace = NullUI.Theme.FontRegular
	valueLabel.Text = FormatNumber(value) .. (opts.Suffix or "")
	valueLabel.TextColor3 = NullUI.Theme.TextDim
	Role(valueLabel, "TextDim")
	valueLabel.TextSize = 13
	valueLabel.TextXAlignment = Enum.TextXAlignment.Right
	valueLabel.AnchorPoint = Vector2.new(1, 0)
	valueLabel.Position = UDim2.new(1, -14, 0, 8)
	valueLabel.Size = UDim2.fromOffset(62, 18)
	valueLabel.ZIndex = Z.Content + 1
	valueLabel.Parent = card

	local track = Instance.new("Frame")
	track.Position = UDim2.new(0, 14, 1, -20)
	track.Size = UDim2.new(1, -28, 0, 6)
	-- Nearly transparent white overlay: no gray tint, so the window background
	-- remains visible through the unfilled portion of the slider.
	track.BackgroundColor3 = Color3.new(1, 1, 1)
	track.BackgroundTransparency = 0.91
	track.BorderSizePixel = 0
	track.ZIndex = Z.Content + 1
	track.Parent = card
	Corner(track, 3)

	local fill = Instance.new("Frame")
	fill.BackgroundColor3 = NullUI.Theme.Accent
	fill.BackgroundTransparency = 0
	fill.BorderSizePixel = 0
	fill.Size = UDim2.new(SafeAlpha(value, min, max), 0, 1, 0)
	fill.ZIndex = Z.Content + 2
	fill.Parent = track
	fill:SetAttribute("NullUIAccent", true)
	Role(fill, "Accent")
	Corner(fill, 3)

	local knob = Instance.new("Frame")
	knob.AnchorPoint = Vector2.new(0.5, 0.5)
	knob.Position = UDim2.new(SafeAlpha(value, min, max), 0, 0.5, 0)
	knob.Size = UDim2.fromOffset(12, 12)
	knob.BackgroundColor3 = NullUI.Theme.Accent
	knob.BackgroundTransparency = 0
	knob.BorderSizePixel = 0
	knob.ZIndex = Z.Content + 3
	knob.Parent = track
	knob:SetAttribute("NullUIAccent", true)
	Role(knob, "Accent")
	Corner(knob, 6)
	Stroke(knob, Color3.fromRGB(16, 16, 16), 2, 0)

	if hasDesc then
		local lastW = -1
		local function relayout()
			local w = card.AbsoluteSize.X / GetUIScale()
			if w <= 0 or math.abs(w - lastW) < 1 then
				return
			end
			lastW = w
			local _, h = MeasureText(opts.Description, 12, math.max(w - textX - 14, 40))
			card.Size = UDim2.new(1, 0, 0, math.max(76, 26 + h + 8 + 20))
		end
		card:GetPropertyChangedSignal("AbsoluteSize"):Connect(relayout)
		SafeDefer(relayout)
	end

	local function setVisual(alpha, animated, duration)
		if animated then
			Tween(fill, { Size = UDim2.new(alpha, 0, 1, 0) }, duration or 0.16)
			Tween(knob, { Position = UDim2.new(alpha, 0, 0.5, 0) }, duration or 0.16)
		else
			fill.Size = UDim2.new(alpha, 0, 1, 0)
			knob.Position = UDim2.new(alpha, 0, 0.5, 0)
		end
	end

	local targetAlpha = SafeAlpha(value, min, max)
	local visualAlpha = targetAlpha

	local signal = MakeSignal()
	local function fireChanged(v)
		if opts.Callback then
			SafeSpawn(opts.Callback, v)
		end
		signal.Fire(v)
	end

	local function setValueLabel()
		valueLabel.Text = FormatNumber(value) .. (opts.Suffix or "")
	end

	local moveTo
	-- Typing a value is a desktop affordance: on touch it would fight the drag
	-- gesture and pop the on-screen keyboard over the slider.
	local canTypeValue = not IsMobileDevice and opts.ValueInput ~= false

	if canTypeValue then
		local boxWidth = 54

		local valueBox = Instance.new("TextBox")
		valueBox.Name = "ValueInput"
		valueBox.BackgroundColor3 = NullUI.Theme.Glass
		valueBox.BackgroundTransparency = 0.92
		valueBox.BorderSizePixel = 0
		valueBox.ClearTextOnFocus = false
		valueBox.FontFace = NullUI.Theme.FontRegular
		valueBox.Text = ""
		valueBox.PlaceholderText = ""
		valueBox.TextColor3 = NullUI.Theme.Text
		Role(valueBox, "Text")
		valueBox.TextSize = 13
		valueBox.TextXAlignment = Enum.TextXAlignment.Center
		valueBox.AnchorPoint = Vector2.new(1, 0)
		valueBox.Position = UDim2.new(1, -12, 0, 6)
		valueBox.Size = UDim2.fromOffset(boxWidth, 22)
		valueBox.Visible = false
		valueBox.ZIndex = valueLabel.ZIndex + 2
		valueBox.Parent = card
		Corner(valueBox, 6)
		local valueBoxStroke = Stroke(valueBox, NullUI.Theme.Accent, 1, 0.4)

		local valueClick = Instance.new("TextButton")
		valueClick.Name = "ValueClick"
		valueClick.Text = ""
		valueClick.AutoButtonColor = false
		valueClick.BackgroundColor3 = NullUI.Theme.Glass
		valueClick.BackgroundTransparency = 1
		valueClick.BorderSizePixel = 0
		valueClick.AnchorPoint = valueBox.AnchorPoint
		valueClick.Position = valueBox.Position
		valueClick.Size = valueBox.Size
		valueClick.ZIndex = valueLabel.ZIndex + 1
		valueClick.Parent = card
		Corner(valueClick, 6)

		valueLabel.AnchorPoint = Vector2.new(0.5, 0.5)
		valueLabel.Position = UDim2.new(1, -12 - boxWidth / 2, 0, 17)
		valueLabel.Size = UDim2.fromOffset(boxWidth, 22)
		valueLabel.TextXAlignment = Enum.TextXAlignment.Center

		local function closeValueBox(apply)
			if not valueBox.Visible then
				return
			end
			local typed = tonumber((valueBox.Text:gsub("[^%-%d%.]", "")))
			valueBox.Visible = false
			valueClick.Visible = true
			valueLabel.Visible = true
			if apply and typed then
				moveTo(typed, true)
				fireChanged(value)
			end
		end

		local function openValueBox()
			if valueBox.Visible or opts.ReadOnly then
				return
			end
			valueLabel.Visible = false
			valueClick.Visible = false
			valueBox.Visible = true
			valueBox.Text = FormatNumber(value)
			valueBoxStroke.Color = NullUI.Theme.Accent
			valueBox:CaptureFocus()
			valueBox.CursorPosition = #valueBox.Text + 1
			valueBox.SelectionStart = 1
		end

		jan:Add(valueClick.MouseButton1Click:Connect(openValueBox))
		jan:Add(valueClick.MouseEnter:Connect(function()
			Tween(valueClick, { BackgroundTransparency = 0.93 }, MOTION.Fast)
			Tween(valueLabel, { TextColor3 = NullUI.Theme.Text }, MOTION.Fast)
		end))
		jan:Add(valueClick.MouseLeave:Connect(function()
			Tween(valueClick, { BackgroundTransparency = 1 }, MOTION.Fast)
			Tween(valueLabel, { TextColor3 = NullUI.Theme.TextDim }, MOTION.Fast)
		end))
		jan:Add(valueBox.FocusLost:Connect(function(enterPressed)
			closeValueBox(enterPressed ~= false)
		end))
	end

	moveTo = function(newValue, animated)
		value = math.clamp(newValue, min, max)
		if increment and increment > 0 then
			value = math.clamp(min + math.floor((value - min) / increment + 0.5) * increment, min, max)
		end
		local alpha = SafeAlpha(value, min, max)
		targetAlpha = alpha
		visualAlpha = alpha
		setValueLabel()
		setVisual(alpha, animated ~= false, 0.18)
	end

	local dragging = false
	local sliderInput = nil
	local sliderOwner = {}
	local followConn = nil

	local function updateFromX(xPos)
		LPH_ATTRIBUTES(VM(NONE))
		if track.AbsoluteSize.X <= 0 then
			return
		end
		targetAlpha = math.clamp((xPos - track.AbsolutePosition.X) / track.AbsoluteSize.X, 0, 1)
		local raw = min + targetAlpha * (max - min)
		local newValue = SnapToIncrement(raw, min, max, increment)
		if newValue ~= value then
			value = newValue
			setValueLabel()
			fireChanged(value)
		end
	end

	local SLIDER_SMOOTH = 22

	local function stopFollow()
		if followConn then
			followConn:Disconnect()
			followConn = nil
		end
	end

	local function releaseSlider()
		if ActiveSliderOwner == sliderOwner then
			ActiveSliderOwner = nil
		end
		dragging = false
		sliderInput = nil
		stopFollow()
	end
	jan:Add(releaseSlider)
	jan:Add(card.Destroying:Connect(releaseSlider))
	jan:Add(UserInputService.WindowFocusReleased:Connect(releaseSlider))

	local hitBox = Instance.new("TextButton")
	hitBox.Name = "SliderHitBox"
	hitBox.Text = ""
	hitBox.AutoButtonColor = false
	hitBox.BackgroundTransparency = 1
	hitBox.AnchorPoint = Vector2.new(0.5, 0.5)
	hitBox.Position = UDim2.fromScale(0.5, 0.5)
	hitBox.Size = UDim2.new(1, 8, 0, 26)
	hitBox.ZIndex = Z.Content + 4
	hitBox.Parent = track

	jan:Add(hitBox.InputBegan:Connect(function(input)
		if
			input.UserInputType ~= Enum.UserInputType.MouseButton1
			and input.UserInputType ~= Enum.UserInputType.Touch
		then
			return
		end
		if dragging or ActiveSliderOwner ~= nil then
			return
		end
		ActiveSliderOwner = sliderOwner
		dragging = true
		sliderInput = input
		updateFromX(input.Position.X)

		stopFollow()
		followConn = RunService.RenderStepped:Connect(function(dt)
			LPH_ATTRIBUTES(VM(NONE))
			if not track.Parent then
				stopFollow()
				return
			end
			local a = 1 - math.exp(-SLIDER_SMOOTH * dt)
			visualAlpha = visualAlpha + (targetAlpha - visualAlpha) * a
			if math.abs(targetAlpha - visualAlpha) < 0.001 then
				visualAlpha = targetAlpha
			end
			setVisual(visualAlpha, false)
		end)
		jan:Add(followConn)
	end))

	jan:Add(UserInputService.InputChanged:Connect(function(input)
		LPH_ATTRIBUTES(VM(NONE))
		if not dragging or ActiveSliderOwner ~= sliderOwner then
			return
		end
		if
			input == sliderInput
			or (
				sliderInput
				and sliderInput.UserInputType == Enum.UserInputType.MouseButton1
				and input.UserInputType == Enum.UserInputType.MouseMovement
			)
		then
			updateFromX(input.Position.X)
		end
	end))

	jan:Add(UserInputService.InputEnded:Connect(function(input)
		if not dragging or ActiveSliderOwner ~= sliderOwner then
			return
		end
		if
			input ~= sliderInput
			and not (
				sliderInput
				and sliderInput.UserInputType == Enum.UserInputType.MouseButton1
				and input.UserInputType == Enum.UserInputType.MouseButton1
			)
		then
			return
		end
		releaseSlider()
		targetAlpha = SafeAlpha(value, min, max)
		visualAlpha = targetAlpha
		setVisual(targetAlpha, true, 0.12)
	end))

	return RegisterFlag(opts, {
		Instance = card,
		Set = function(_, v, silent)
			moveTo(SnapToIncrement(tonumber(v) or min, min, max, increment), true)
			if not silent then
				fireChanged(value)
			end
		end,
		Get = function()
			return value
		end,
		SetRange = function(_, newMin, newMax)
			min, max = newMin, newMax
			moveTo(math.clamp(value, min, max), true)
		end,
		OnChanged = function(_, fn)
			return signal.Connect(fn)
		end,
		Destroy = function()
			stopFollow()
			signal.Clear()
			card:Destroy()
		end,
	}, "Slider")
end

local function ComputePopupPosition(window, card, w, h, bounds)
	local s = GetUIScale()
	local realW, realH = w * s, h * s

	local view = ViewportSize()
	-- Prefer the content region so a flyout never covers the tab strip or topbar.
	local winPos = (bounds and bounds.AbsolutePosition) or window.AbsolutePosition
	local winSize = (bounds and bounds.AbsoluteSize) or window.AbsoluteSize
	local cardPos = card.AbsolutePosition

	local cardSize = card.AbsoluteSize
	local pad = 8 * s

	-- Flyout behaviour: hang off the control's chevron and float over the content
	-- instead of pushing it around, so scrolling never clips it away.
	local minX = winPos.X + pad
	local maxX = winPos.X + winSize.X - realW - pad
	local px
	if maxX < minX then
		px = winPos.X + (winSize.X - realW) / 2
	else
		px = SafeClamp(cardPos.X + cardSize.X - realW + 2 * s, minX, maxX)
	end

	local topLimit = winPos.Y + pad
	local bottomLimit = winPos.Y + winSize.Y - pad
	-- Anchor on the chevron row itself: the list overlays the control, centred on
	-- it when there is room on both sides, then flips to whichever side fits.
	local anchorY = cardPos.Y + cardSize.Y / 2
	local py = anchorY - realH / 2

	if py < topLimit then
		py = topLimit
	end
	if py + realH > bottomLimit then
		py = bottomLimit - realH
	end
	if py < topLimit then
		py = topLimit
	end

	px = SafeClamp(px, 8, math.max(8, view.X - realW - 8))
	py = SafeClamp(py, 8, math.max(8, view.Y - realH - 8))

	return math.round(px / s), math.round(py / s)
end

function Tab:AddDropdown(opts)
	opts = opts or {}
	local ownerTab = self
	local options = opts.Options or {}
	local isMulti = opts.MultiSelect == true
	local hasDesc = opts.Description and opts.Description ~= ""
	local height = hasDesc and 54 or 40
	local jan = self._janitor

	local selected
	if isMulti then
		selected = {}
		if type(opts.Default) == "table" then
			for _, v in ipairs(opts.Default) do
				selected[v] = true
			end
		end
	else
		selected = opts.Default or options[1]
	end

	local signal = MakeSignal()
	local function fireChanged(newValue)
		if opts.Callback then
			SafeSpawn(opts.Callback, newValue)
		end
		signal.Fire(newValue)
	end

	local function getSelectedList()
		local list = {}
		for _, name in ipairs(options) do
			if isMulti and selected[name] then
				table.insert(list, name)
			end
		end
		return list
	end

	local function isOptionSelected(name)
		if isMulti then
			return selected[name] == true
		end
		return name == selected
	end

	local function formatValue()
		if isMulti then
			local list = getSelectedList()
			if #list == 0 then
				return "None"
			end
			if #list == 1 then
				return list[1]
			end
			return #list .. " selected"
		end
		return tostring(selected or "None")
	end

	local card = BaseCard(self._page, height)
	local textX = AddLeadingIcon(card, opts.Icon, height)

	AddTitleDesc(card, textX, 166, opts.Text or "Dropdown", opts.Description, height)
	self._window:_RegisterSearchable(self, opts.Text or "Dropdown", card)

	local valueLabel = Instance.new("TextLabel")
	valueLabel.BackgroundTransparency = 1
	valueLabel.FontFace = NullUI.Theme.FontRegular
	valueLabel.Text = formatValue()
	valueLabel.TextColor3 = NullUI.Theme.TextDim
	Role(valueLabel, "TextDim")
	valueLabel.TextSize = 13
	valueLabel.TextTruncate = Enum.TextTruncate.AtEnd
	valueLabel.TextXAlignment = Enum.TextXAlignment.Right
	valueLabel.AnchorPoint = Vector2.new(1, 0.5)
	valueLabel.Position = UDim2.new(1, -34, 0.5, 0)
	valueLabel.Size = UDim2.fromOffset(120, height)
	valueLabel.ZIndex = Z.Content + 1
	valueLabel.Parent = card

	local chevron = Instance.new("ImageLabel")
	chevron.BackgroundTransparency = 1
	chevron.Image = ResolveIcon("chevron-down")
	chevron.ImageColor3 = NullUI.Theme.TextDim
	Role(chevron, "TextDim")
	chevron.Size = UDim2.fromOffset(14, 14)
	chevron.AnchorPoint = Vector2.new(1, 0.5)
	chevron.Position = UDim2.new(1, -14, 0.5, 0)
	chevron.ZIndex = Z.Content + 1
	chevron.Parent = card

	local click = Instance.new("TextButton")
	click.Text = ""
	click.AutoButtonColor = false
	click.BackgroundTransparency = 1
	click.Size = UDim2.fromScale(1, 1)
	click.ZIndex = Z.Content + 3
	click.Parent = card

	local popupOpen = false
	local popupFrame, popupBackdrop, followConn, scrollConn
	local optionButtons = {}

	local function closePopup()
		if not popupOpen then
			return
		end
		popupOpen = false
		RegisterPopupClose(closePopup)
		Tween(chevron, { Rotation = 0 }, 0.18)

		if followConn then
			followConn:Disconnect()
			followConn = nil
		end
		if scrollConn then
			scrollConn:Disconnect()
			scrollConn = nil
		end
		table.clear(optionButtons)

		if popupBackdrop then
			popupBackdrop:Destroy()
			popupBackdrop = nil
		end

		if popupFrame then
			local pf = popupFrame
			popupFrame = nil
			Tween(
				pf,
				{ Size = UDim2.new(0, pf.Size.X.Offset, 0, 0) },
				0.32,
				Enum.EasingStyle.Quint,
				Enum.EasingDirection.In
			)
			Tween(pf, { BackgroundTransparency = 1 }, 0.32, Enum.EasingStyle.Quint, Enum.EasingDirection.In)
			SafeDelay(0.4, function()
				if pf then
					pf:Destroy()
				end
			end)
		end
	end

	local function refreshOptionVisual(name)
		local entry = optionButtons[name]
		if not entry then
			return
		end
		local sel = isOptionSelected(name)
		Tween(entry.button, { BackgroundTransparency = sel and 0.9 or 1 }, 0.12)
		Tween(entry.label, { TextColor3 = sel and NullUI.Theme.Text or NullUI.Theme.TextDim }, 0.12)
		if entry.check then
			entry.check:SetAttribute(ROLE_ATTR, sel and "Accent" or nil)
			RoleRegistry[entry.check] = sel and "Accent" or nil
			Tween(entry.check, {
				BackgroundColor3 = sel and NullUI.Theme.Accent or Color3.new(1, 1, 1),
				BackgroundTransparency = sel and 0 or 0.9,
			}, 0.12)
		end
		if entry.checkIcon then
			Tween(entry.checkIcon, { ImageTransparency = sel and 0 or 1 }, 0.12)
		end
	end

	local function openPopup()
		if popupOpen then
			return
		end
		popupOpen = true
		RegisterPopupOpen(closePopup)
		Tween(chevron, { Rotation = 180 }, 0.18)

		local root = NullUI._Root
		local mainWindow = self._window and self._window._gui or root

		local area = self._window and self._window._content
		local areaH = (area and area.AbsoluteSize.Y or mainWindow.AbsoluteSize.Y) / GetUIScale()
		local areaW = (area and area.AbsoluteSize.X or mainWindow.AbsoluteSize.X) / GetUIScale()

		-- Touch needs taller rows but far fewer of them on screen at once, so the
		-- flyout is capped against the visible content area rather than the screen.
		local rowH, padV = IsMobileDevice and 34 or 30, 12
		local contentH = #options * rowH + math.max(#options - 1, 0) * 2 + padV
		local maxByArea = math.max(rowH * 3 + padV, areaH * (IsMobileDevice and 0.58 or 0.78))
		local targetHeight = math.min(
			contentH,
			IsMobileDevice and 190 or 220,
			math.max(1, (ViewportSize().Y - 16) / GetUIScale()),
			maxByArea
		)

		-- Width follows the longest option plus exactly the trailing column the
		-- list actually draws, so short options do not leave a dead gap.
		local trailing = isMulti and 44 or 34
		local popupW = IsMobileDevice and 150 or 132
		for _, name in ipairs(options) do
			local w = MeasureText(tostring(name), 13, 1000)
			popupW = math.max(popupW, w + trailing + 22)
		end
		-- Never wider than the area it has to sit inside.
		popupW = math.min(popupW, ViewportSize().X / GetUIScale() - 24, math.max(132, areaW - 8))

		popupBackdrop = MakePopupBackdrop(closePopup)

		popupFrame = Instance.new("CanvasGroup")
		popupFrame.Name = "DropdownPopup"
		popupFrame.Active = true
		popupFrame.BackgroundColor3 = NullUI.Theme.Surface
		popupFrame.BackgroundTransparency = 1
		popupFrame.BorderSizePixel = 0
		popupFrame.ZIndex = Z.Popup
		popupFrame.Size = UDim2.new(0, popupW, 0, 0)
		popupFrame.Parent = root
		Corner(popupFrame, 10)
		local popupStroke = Stroke(popupFrame, NullUI.Theme.Glass, 1, 0.86)
		GlassLayer(popupFrame, 10, 0.96)

		local px, py =
			ComputePopupPosition(mainWindow, card, popupW, targetHeight, self._window and self._window._content)
		popupFrame.Position = UDim2.fromOffset(px, py)

		local optionsHolder = Instance.new("ScrollingFrame")
		optionsHolder.Name = "Options"
		optionsHolder.BackgroundTransparency = 1
		optionsHolder.BorderSizePixel = 0
		optionsHolder.Size = UDim2.fromScale(1, 1)
		optionsHolder.ScrollingDirection = Enum.ScrollingDirection.Y
		optionsHolder.ScrollBarThickness = 0
		optionsHolder.AutomaticCanvasSize = Enum.AutomaticSize.Y
		optionsHolder.CanvasSize = UDim2.new(0, 0, 0, 0)
		optionsHolder.ZIndex = Z.Popup + 1
		optionsHolder.Parent = popupFrame

		local optPad = Instance.new("UIPadding")
		optPad.PaddingTop = UDim.new(0, 6)
		optPad.PaddingBottom = UDim.new(0, 6)
		optPad.PaddingLeft = UDim.new(0, 6)
		optPad.PaddingRight = UDim.new(0, 16)
		optPad.Parent = optionsHolder

		local optLayout = Instance.new("UIListLayout")
		optLayout.Padding = UDim.new(0, 2)
		optLayout.SortOrder = Enum.SortOrder.LayoutOrder
		optLayout.Parent = optionsHolder

		AddScrollbar(optionsHolder)
		AddContentScrollThumb(optionsHolder, optLayout, popupFrame, {
			Add = function(_, conn)
				scrollConn = conn
			end,
		})

		for i, optionName in ipairs(options) do
			local optBtn = Instance.new("TextButton")
			optBtn.Text = ""
			optBtn.AutoButtonColor = false
			optBtn.BackgroundColor3 = Color3.new(1, 1, 1)
			optBtn.BackgroundTransparency = isOptionSelected(optionName) and 0.9 or 1
			optBtn.BorderSizePixel = 0
			optBtn.Size = UDim2.new(1, 0, 0, rowH)
			optBtn.LayoutOrder = i
			optBtn.ZIndex = Z.Popup + 2
			optBtn.Parent = optionsHolder
			Corner(optBtn, 8)

			local optLabel = Instance.new("TextLabel")
			optLabel.BackgroundTransparency = 1
			optLabel.FontFace = NullUI.Theme.FontRegular
			optLabel.Text = tostring(optionName)
			optLabel.TextColor3 = isOptionSelected(optionName) and NullUI.Theme.Text or NullUI.Theme.TextDim
			optLabel.TextSize = 13
			optLabel.TextXAlignment = Enum.TextXAlignment.Left
			optLabel.TextTruncate = Enum.TextTruncate.AtEnd
			optLabel.Position = UDim2.fromOffset(10, 0)
			optLabel.Size = UDim2.new(1, -(isMulti and 44 or 34), 1, 0)
			optLabel.ZIndex = Z.Popup + 3
			optLabel.Parent = optBtn

			local entry = { button = optBtn, label = optLabel }

			if isMulti then
				local check = Instance.new("Frame")
				check.Name = "Check"
				check.AnchorPoint = Vector2.new(1, 0.5)
				check.Position = UDim2.new(1, -10, 0.5, 0)
				check.Size = UDim2.fromOffset(14, 14)
				check.BackgroundColor3 = isOptionSelected(optionName) and NullUI.Theme.Accent or Color3.new(1, 1, 1)
				check.BackgroundTransparency = isOptionSelected(optionName) and 0 or 0.9
				check:SetAttribute("NullUIAccent", true)
				check.BorderSizePixel = 0
				check.ZIndex = Z.Popup + 3
				check.Parent = optBtn
				Corner(check, 4)
				Stroke(check, Color3.new(1, 1, 1), 1, 0.75)

				local checkIcon = Instance.new("ImageLabel")
				checkIcon.Name = "Icon"
				checkIcon.BackgroundTransparency = 1
				checkIcon.Image = ResolveIcon("check")
				checkIcon.ImageColor3 = NullUI.Theme.Background
				Role(checkIcon, "Background")
				checkIcon.ImageTransparency = isOptionSelected(optionName) and 0 or 1
				checkIcon.Size = UDim2.fromOffset(10, 10)
				checkIcon.AnchorPoint = Vector2.new(0.5, 0.5)
				checkIcon.Position = UDim2.fromScale(0.5, 0.5)
				checkIcon.ZIndex = Z.Popup + 4
				checkIcon.Parent = check

				entry.check = check
				entry.checkIcon = checkIcon
			elseif isOptionSelected(optionName) then
				local check = Instance.new("ImageLabel")
				check.Name = "SingleCheck"
				check.BackgroundTransparency = 1
				check.Image = ResolveIcon("check")
				check.ImageColor3 = NullUI.Theme.Text
				Role(check, "Text")
				check.Size = UDim2.fromOffset(14, 14)
				check.AnchorPoint = Vector2.new(1, 0.5)
				check.Position = UDim2.new(1, -10, 0.5, 0)
				check.ZIndex = Z.Popup + 3
				check.Parent = optBtn
			end

			optionButtons[optionName] = entry

			optBtn.MouseEnter:Connect(function()
				if not isOptionSelected(optionName) then
					Tween(optBtn, { BackgroundTransparency = 0.85 }, 0.12)
				end
			end)
			optBtn.MouseLeave:Connect(function()
				if not isOptionSelected(optionName) then
					Tween(optBtn, { BackgroundTransparency = 1 }, 0.12)
				end
			end)

			optBtn.MouseButton1Click:Connect(function()
				if isMulti then
					selected[optionName] = (not selected[optionName]) or nil
					refreshOptionVisual(optionName)
					valueLabel.Text = formatValue()
					fireChanged(getSelectedList())
				else
					selected = optionName
					valueLabel.Text = formatValue()
					fireChanged(optionName)
					closePopup()
				end
			end)
		end

		Tween(popupFrame, {
			Size = UDim2.new(0, popupW, 0, targetHeight),
			BackgroundTransparency = 0.06,
		}, MOTION.Slow, MOTION.Style, MOTION.Direction)
		Tween(popupStroke, { Transparency = 0.7 }, MOTION.Normal, MOTION.Style, MOTION.Direction)

		followConn = RunService.RenderStepped:Connect(function()
			LPH_ATTRIBUTES(VM(NONE))
			if not popupFrame or not card.Parent then
				return
			end
			-- Close instead of floating over unrelated rows once the control has
			-- been scrolled out of the visible area or its page was hidden.
			local cardPos, cardSize = card.AbsolutePosition, card.AbsoluteSize
			local winPos, winSize = mainWindow.AbsolutePosition, mainWindow.AbsoluteSize
			local outOfView = not card.Visible
				or cardSize.Y <= 0
				or (ownerTab and ownerTab._group and not ownerTab._group.Visible)
				or cardPos.Y + cardSize.Y < winPos.Y + 40
				or cardPos.Y > winPos.Y + winSize.Y - 10
			if outOfView then
				closePopup()
				return
			end
			local nx, ny = ComputePopupPosition(
				mainWindow,
				card,
				popupW,
				targetHeight,
				ownerTab and ownerTab._window and ownerTab._window._content
			)
			popupFrame.Position = UDim2.fromOffset(nx, ny)
		end)
		jan:Add(followConn)
	end

	click.MouseButton1Click:Connect(function()
		if popupOpen then
			closePopup()
		else
			openPopup()
		end
	end)

	card.MouseEnter:Connect(function()
		Tween(card, { BackgroundTransparency = 0.93 }, 0.18)
	end)
	card.MouseLeave:Connect(function()
		Tween(card, { BackgroundTransparency = 0.96 }, 0.18)
	end)

	return RegisterFlag(opts, {
		Instance = card,
		Set = function(_, v, silent)
			if isMulti then
				selected = {}
				if type(v) == "table" then
					for _, name in ipairs(v) do
						selected[name] = true
					end
				end
			else
				selected = v
			end
			valueLabel.Text = formatValue()
			for name in pairs(optionButtons) do
				refreshOptionVisual(name)
			end
			if not silent then
				fireChanged(isMulti and getSelectedList() or selected)
			end
		end,
		Get = function()
			if isMulti then
				return getSelectedList()
			end
			return selected
		end,
		SetOptions = function(_, newOptions)
			options = newOptions or {}
			closePopup()
			valueLabel.Text = formatValue()
		end,
		Refresh = function(_, newOptions)
			options = newOptions or options
			closePopup()
			valueLabel.Text = formatValue()
		end,
		OnChanged = function(_, fn)
			return signal.Connect(fn)
		end,
		Destroy = function()
			closePopup()
			signal.Clear()
			card:Destroy()
		end,
	}, "Dropdown")
end

function Tab:AddTextbox(opts)
	opts = opts or {}
	local hasDesc = opts.Description and opts.Description ~= ""
	local height = hasDesc and 54 or 40
	local card = BaseCard(self._page, height)

	local textX = AddLeadingIcon(card, opts.Icon, height)

	local iconGap, rightPad, pillMinW = 29, 12, 90
	local titleReserve = pillMinW + 26

	local _, _, refreshTextLayout = AddTitleDesc(card, textX, function()
		return titleReserve
	end, opts.Text or "Textbox", opts.Description, height)
	self._window:_RegisterSearchable(self, opts.Text or "Textbox", card)

	local pill = Instance.new("Frame")
	pill.AnchorPoint = Vector2.new(1, 0.5)
	pill.Position = UDim2.new(1, -14, 0.5, 0)
	pill.Size = UDim2.fromOffset(pillMinW, 26)
	pill.BackgroundColor3 = Color3.new(1, 1, 1)
	pill.BackgroundTransparency = 0.9
	pill.BorderSizePixel = 0
	pill.ZIndex = Z.Content + 2
	pill.Parent = card
	Corner(pill, 8)
	local pillStroke = Stroke(pill, Color3.new(1, 1, 1), 1, 0.88)

	local penIcon = Instance.new("ImageLabel")
	penIcon.BackgroundTransparency = 1
	penIcon.Image = ResolveIcon("pencil")
	penIcon.ImageColor3 = NullUI.Theme.TextDim
	Role(penIcon, "TextDim")
	penIcon.Size = UDim2.fromOffset(13, 13)
	penIcon.AnchorPoint = Vector2.new(0, 0.5)
	penIcon.Position = UDim2.new(0, 10, 0.5, 0)
	penIcon.ZIndex = Z.Content + 3
	penIcon.Parent = pill

	local box = Instance.new("TextBox")
	box.ClearTextOnFocus = false
	box.FontFace = NullUI.Theme.FontRegular
	box.PlaceholderText = opts.Placeholder or ""
	box.PlaceholderColor3 = Color3.fromRGB(120, 120, 122)
	box.Text = opts.Default or ""
	box.TextColor3 = NullUI.Theme.Text
	Role(box, "Text")
	box.TextSize = 13
	box.TextXAlignment = Enum.TextXAlignment.Left
	box.TextYAlignment = Enum.TextYAlignment.Center
	box.TextTruncate = Enum.TextTruncate.AtEnd
	box.ClipsDescendants = true
	box.BackgroundTransparency = 1
	box.Position = UDim2.fromOffset(iconGap, 0)
	box.Size = UDim2.new(1, -(iconGap + 10), 1, 0)
	box.ZIndex = Z.Content + 3
	box.Parent = pill

	local currentPillW = pillMinW

	local function resizePill(animated)
		local sample = box.Text ~= "" and box.Text or box.PlaceholderText
		local textW = MeasureText(sample, 13, 2000)
		local desiredW = iconGap + textW + rightPad

		local realCardW = card.AbsoluteSize.X > 0 and card.AbsoluteSize.X or 400
		local cardW = realCardW / GetUIScale()
		local maxW = math.max(pillMinW, math.floor(cardW * 0.5))
		local targetW = math.clamp(desiredW, pillMinW, maxW)

		if math.abs(targetW - currentPillW) < 1 then
			return
		end
		currentPillW = targetW
		titleReserve = targetW + 26
		refreshTextLayout()

		if animated == false then
			pill.Size = UDim2.fromOffset(targetW, 26)
		else
			Tween(
				pill,
				{ Size = UDim2.fromOffset(targetW, 26) },
				0.18,
				Enum.EasingStyle.Quint,
				Enum.EasingDirection.Out
			)
		end
	end

	box:GetPropertyChangedSignal("Text"):Connect(function()
		resizePill(true)
	end)
	card:GetPropertyChangedSignal("AbsoluteSize"):Connect(function()
		resizePill(false)
	end)
	SafeDefer(function()
		resizePill(false)
	end)

	local cardClick = Instance.new("TextButton")
	cardClick.Name = "CardFocus"
	cardClick.Text = ""
	cardClick.AutoButtonColor = false
	cardClick.BackgroundTransparency = 1
	cardClick.Size = UDim2.fromScale(1, 1)
	cardClick.ZIndex = Z.Content + 1
	cardClick.Parent = card
	self._janitor:Add(cardClick.MouseButton1Click:Connect(function()
		if box.Parent then
			box:CaptureFocus()
		end
	end))

	self._janitor:Add(box.Focused:Connect(function()
		Tween(pillStroke, { Color = NullUI.Theme.Accent, Transparency = 0.3 }, 0.18)
		Tween(pill, { BackgroundTransparency = 0.82 }, 0.18)
	end))

	local signal = MakeSignal()
	local function fireChanged(text, enterPressed)
		if opts.Callback then
			SafeSpawn(opts.Callback, text, enterPressed)
		end
		signal.Fire(text, enterPressed)
	end

	self._janitor:Add(box.FocusLost:Connect(function(enterPressed)
		Tween(pillStroke, { Color = Color3.new(1, 1, 1), Transparency = 0.88 }, 0.18)
		Tween(pill, { BackgroundTransparency = 0.9 }, 0.18)
		fireChanged(box.Text, enterPressed)
	end))

	return RegisterFlag(opts, {
		Instance = card,
		Set = function(_, v, silent)
			box.Text = tostring(v or "")
			resizePill()
			if not silent then
				fireChanged(box.Text, false)
			end
		end,
		Get = function()
			return box.Text
		end,
		OnChanged = function(_, fn)
			return signal.Connect(fn)
		end,
		Destroy = function()
			signal.Clear()
			card:Destroy()
		end,
	}, "Textbox")
end

local function MiniField(parent, label, width, zBase)
	zBase = zBase or Z.Popup

	local holder = Instance.new("Frame")
	holder.BackgroundTransparency = 1
	holder.Size = UDim2.fromOffset(width, 36)
	holder.ZIndex = zBase + 1
	holder.Parent = parent

	local lbl = Instance.new("TextLabel")
	lbl.BackgroundTransparency = 1
	lbl.FontFace = NullUI.Theme.FontRegular
	lbl.Text = label
	lbl.TextColor3 = NullUI.Theme.TextDim
	Role(lbl, "TextDim")
	lbl.TextSize = 11
	lbl.TextXAlignment = Enum.TextXAlignment.Left
	lbl.Size = UDim2.new(1, 0, 0, 12)
	lbl.ZIndex = zBase + 2
	lbl.Parent = holder

	local field = Instance.new("Frame")
	field.Position = UDim2.fromOffset(0, 12)
	field.Size = UDim2.new(1, 0, 0, 24)
	field.BackgroundColor3 = Color3.new(1, 1, 1)
	field.BackgroundTransparency = 0.92
	field.BorderSizePixel = 0
	field.ZIndex = zBase + 2
	field.Parent = holder
	Corner(field, 7)
	local fieldStroke = Stroke(field, Color3.new(1, 1, 1), 1, 0.88)

	local box = Instance.new("TextBox")
	box.ClearTextOnFocus = false
	box.FontFace = NullUI.Theme.FontRegular
	box.Text = ""
	box.TextColor3 = NullUI.Theme.Text
	Role(box, "Text")
	box.TextSize = 13
	box.TextXAlignment = Enum.TextXAlignment.Center
	box.TextYAlignment = Enum.TextYAlignment.Center
	box.BackgroundTransparency = 1
	box.Size = UDim2.fromScale(1, 1)
	box.ZIndex = zBase + 3
	box.Parent = field

	box.Focused:Connect(function()
		Tween(fieldStroke, { Color = NullUI.Theme.Accent, Transparency = 0.3 }, 0.18)
		Tween(field, { BackgroundTransparency = 0.84 }, 0.18)
	end)
	box.FocusLost:Connect(function()
		Tween(fieldStroke, { Color = Color3.new(1, 1, 1), Transparency = 0.88 }, 0.18)
		Tween(field, { BackgroundTransparency = 0.92 }, 0.18)
	end)

	return holder, box
end

function Tab:AddColorPicker(opts)
	opts = opts or {}
	local hasDesc = opts.Description and opts.Description ~= ""
	local height = hasDesc and 54 or 40
	local jan = self._janitor

	local card = BaseCard(self._page, height)
	local textX = AddLeadingIcon(card, opts.Icon, height)
	AddTitleDesc(card, textX, 52, opts.Text or "Color", opts.Description, height)
	self._window:_RegisterSearchable(self, opts.Text or "Color", card)

	local color = opts.Default or Color3.fromRGB(255, 255, 255)
	local hue, sat, val = Color3.toHSV(color)

	local swatchHolder = Instance.new("Frame")
	swatchHolder.AnchorPoint = Vector2.new(1, 0.5)
	swatchHolder.Position = UDim2.new(1, -14, 0.5, 0)
	swatchHolder.Size = UDim2.fromOffset(24, 24)
	swatchHolder.BackgroundColor3 = Color3.new(1, 1, 1)
	swatchHolder.BackgroundTransparency = 0.9
	swatchHolder.BorderSizePixel = 0
	swatchHolder.ZIndex = Z.Content + 1
	swatchHolder.Parent = card
	Corner(swatchHolder, 6)
	local swatchStroke = Stroke(swatchHolder, Color3.new(1, 1, 1), 1, 0.85)

	local swatch = Instance.new("Frame")
	swatch.AnchorPoint = Vector2.new(0.5, 0.5)
	swatch.Position = UDim2.fromScale(0.5, 0.5)
	swatch.Size = UDim2.fromOffset(16, 16)
	swatch.BackgroundColor3 = color
	swatch.BorderSizePixel = 0
	swatch.ZIndex = Z.Content + 2
	swatch.Parent = swatchHolder
	Corner(swatch, 4)

	local click = Instance.new("TextButton")
	click.Text = ""
	click.AutoButtonColor = false
	click.BackgroundTransparency = 1
	click.Size = UDim2.fromScale(1, 1)
	click.ZIndex = Z.Content + 3
	click.Parent = card

	local popupOpen = false
	local popupFrame, popupBackdrop, followConn
	local svCursor, hueCursor, svBox, hueBar, satGradient
	local hexBox, rBox, gBox, bBox
	local originalHue, originalSat, originalVal
	local draggingSV, draggingHue = false, false
	local colorInput = nil
	local dragEndedAt = 0

	local function currentColor()
		return Color3.fromHSV(hue, sat, val)
	end

	local function syncFields()
		if svCursor then
			svCursor.Position = UDim2.new(sat, 0, 1 - val, 0)
		end
		if hueCursor then
			hueCursor.Position = UDim2.new(hue, 0, 0.5, 0)
		end
		if svBox then
			svBox.BackgroundColor3 = Color3.new(1, 1, 1)
		end
		if satGradient then
			satGradient.Color = ColorSequence.new(Color3.new(1, 1, 1), Color3.fromHSV(hue, 1, 1))
		end

		local c = currentColor()
		local r = math.floor(c.R * 255 + 0.5)
		local g = math.floor(c.G * 255 + 0.5)
		local b = math.floor(c.B * 255 + 0.5)
		if hexBox and not hexBox:IsFocused() then
			hexBox.Text = "#" .. c:ToHex():upper()
		end
		if rBox and not rBox:IsFocused() then
			rBox.Text = tostring(r)
		end
		if gBox and not gBox:IsFocused() then
			gBox.Text = tostring(g)
		end
		if bBox and not bBox:IsFocused() then
			bBox.Text = tostring(b)
		end
	end

	local signal = MakeSignal()
	local lastFired = nil

	local function ColorsClose(a, b)
		if a == nil or b == nil then
			return false
		end
		return math.abs(a.R - b.R) < 0.001 and math.abs(a.G - b.G) < 0.001 and math.abs(a.B - b.B) < 0.001
	end

	local function applyColor(fireCallback)
		local c = currentColor()
		swatch.BackgroundColor3 = c
		syncFields()
		if fireCallback then
			if not ColorsClose(c, lastFired) then
				lastFired = c
				if opts.Callback then
					SafeSpawn(opts.Callback, c)
				end
				signal.Fire(c)
			end
		end
	end

	local function closePopup()
		if not popupOpen then
			return
		end
		popupOpen = false
		draggingSV, draggingHue = false, false
		colorInput = nil
		RegisterPopupClose(closePopup)
		Tween(swatchStroke, { Color = Color3.new(1, 1, 1), Transparency = 0.85 }, 0.18)

		if followConn then
			followConn:Disconnect()
			followConn = nil
		end
		if popupBackdrop then
			popupBackdrop:Destroy()
			popupBackdrop = nil
		end

		if popupFrame then
			local pf = popupFrame
			popupFrame = nil
			svCursor, hueCursor, svBox, hueBar, satGradient = nil, nil, nil, nil, nil
			hexBox, rBox, gBox, bBox = nil, nil, nil, nil
			Tween(
				pf,
				{ Size = UDim2.new(0, pf.Size.X.Offset, 0, 0) },
				0.32,
				Enum.EasingStyle.Quint,
				Enum.EasingDirection.In
			)
			Tween(pf, { BackgroundTransparency = 1 }, 0.32, Enum.EasingStyle.Quint, Enum.EasingDirection.In)
			SafeDelay(0.4, function()
				if pf then
					pf:Destroy()
				end
			end)
		end
	end

	local function updateSV(inputPos)
		LPH_ATTRIBUTES(VM(NONE))
		if not svBox or svBox.AbsoluteSize.X <= 0 then
			return
		end
		local rel, sz = svBox.AbsolutePosition, svBox.AbsoluteSize
		sat = math.clamp((inputPos.X - rel.X) / sz.X, 0, 1)
		val = 1 - math.clamp((inputPos.Y - rel.Y) / sz.Y, 0, 1)
		applyColor(true)
	end

	local function updateHue(inputPos)
		LPH_ATTRIBUTES(VM(NONE))
		if not hueBar or hueBar.AbsoluteSize.X <= 0 then
			return
		end
		local rel, sz = hueBar.AbsolutePosition, hueBar.AbsoluteSize
		hue = math.clamp((inputPos.X - rel.X) / sz.X, 0, 1)
		applyColor(true)
	end

	jan:Add(UserInputService.InputChanged:Connect(function(input)
		LPH_ATTRIBUTES(VM(NONE))
		if not popupFrame then
			return
		end
		if
			input ~= colorInput
			and not (
				colorInput
				and colorInput.UserInputType == Enum.UserInputType.MouseButton1
				and input.UserInputType == Enum.UserInputType.MouseMovement
			)
		then
			return
		end
		if draggingSV then
			updateSV(input.Position)
		end
		if draggingHue then
			updateHue(input.Position)
		end
	end))

	jan:Add(UserInputService.InputEnded:Connect(function(input)
		if
			input == colorInput
			or (
				colorInput
				and colorInput.UserInputType == Enum.UserInputType.MouseButton1
				and input.UserInputType == Enum.UserInputType.MouseButton1
			)
		then
			if draggingSV or draggingHue then
				dragEndedAt = os.clock()
			end
			draggingSV, draggingHue = false, false
			colorInput = nil
		end
	end))

	local function requestCloseFromBackdrop()
		if draggingSV or draggingHue then
			return
		end
		if os.clock() - dragEndedAt < 0.2 then
			return
		end
		closePopup()
	end

	local function openPopup()
		if popupOpen then
			return
		end
		popupOpen = true
		originalHue, originalSat, originalVal = hue, sat, val
		lastFired = currentColor()
		RegisterPopupOpen(closePopup)
		Tween(swatchStroke, { Color = NullUI.Theme.Accent, Transparency = 0.3 }, 0.18)

		local root = NullUI._Root
		local mainWindow = self._window and self._window._gui or root
		local popupW, popupH = 208, math.min(290, math.max(1, (ViewportSize().Y - 16) / GetUIScale()))

		popupBackdrop = MakePopupBackdrop(requestCloseFromBackdrop)

		popupFrame = Instance.new("ScrollingFrame")
		popupFrame.CanvasSize = UDim2.fromOffset(0, 290)
		popupFrame.ScrollingDirection = Enum.ScrollingDirection.Y
		popupFrame.ScrollBarThickness = 0
		popupFrame.ScrollBarImageColor3 = NullUI.Theme.TextDim
		popupFrame.ScrollBarImageTransparency = 1
		popupFrame.BorderSizePixel = 0
		popupFrame.Name = "ColorPickerPopup"
		popupFrame.Active = true
		popupFrame.BackgroundColor3 = NullUI.Theme.Background
		popupFrame.BackgroundTransparency = 1
		popupFrame.BorderSizePixel = 0
		popupFrame.ClipsDescendants = true
		popupFrame.ZIndex = Z.Popup
		popupFrame.Size = UDim2.new(0, popupW, 0, 0)
		popupFrame.Parent = root
		Corner(popupFrame, 10)
		local popupStroke = Stroke(popupFrame, Color3.new(1, 1, 1), 1, 0.92)
		GlassLayer(popupFrame, 10, 0.985)

		local px, py = ComputePopupPosition(mainWindow, card, popupW, popupH, self._window and self._window._content)
		popupFrame.Position = UDim2.fromOffset(px, py)

		local pad = Instance.new("UIPadding")
		pad.PaddingTop = UDim.new(0, 14)
		pad.PaddingBottom = UDim.new(0, 14)
		pad.PaddingLeft = UDim.new(0, 14)
		pad.PaddingRight = UDim.new(0, 14)
		pad.Parent = popupFrame

		local innerW = popupW - 28

		svBox = Instance.new("Frame")
		svBox.Active = true
		svBox.Position = UDim2.fromOffset(0, 0)
		svBox.Size = UDim2.fromOffset(innerW, 104)
		svBox.BackgroundColor3 = Color3.new(1, 1, 1)
		svBox.BorderSizePixel = 0
		svBox.ClipsDescendants = true
		svBox.ZIndex = Z.Popup + 1
		svBox.Parent = popupFrame
		Corner(svBox, 8)

		satGradient = Instance.new("UIGradient")
		satGradient.Color = ColorSequence.new(Color3.new(1, 1, 1), Color3.fromHSV(hue, 1, 1))
		satGradient.Parent = svBox

		local valOverlay = Instance.new("Frame")
		valOverlay.BackgroundColor3 = Color3.new(0, 0, 0)
		valOverlay.BorderSizePixel = 0
		valOverlay.Size = UDim2.fromScale(1, 1)
		valOverlay.ZIndex = Z.Popup + 1
		valOverlay.Parent = svBox
		local valGradient = Instance.new("UIGradient")
		valGradient.Rotation = 90
		valGradient.Transparency = NumberSequence.new({
			NumberSequenceKeypoint.new(0, 1),
			NumberSequenceKeypoint.new(1, 0),
		})
		valGradient.Parent = valOverlay

		local svCursorLayer = Instance.new("Frame")
		svCursorLayer.BackgroundTransparency = 1
		svCursorLayer.BorderSizePixel = 0
		svCursorLayer.ClipsDescendants = false
		svCursorLayer.Position = svBox.Position
		svCursorLayer.Size = svBox.Size
		svCursorLayer.ZIndex = Z.Popup + 2
		svCursorLayer.Parent = popupFrame

		svCursor = Instance.new("Frame")
		svCursor.AnchorPoint = Vector2.new(0.5, 0.5)
		svCursor.Position = UDim2.new(sat, 0, 1 - val, 0)
		svCursor.Size = UDim2.fromOffset(16, 16)
		svCursor.BackgroundTransparency = 1
		svCursor.ZIndex = Z.Popup + 3
		svCursor.Parent = svCursorLayer
		Corner(svCursor, 8)
		Stroke(svCursor, Color3.new(0, 0, 0), 2, 0.15)

		local svCursorInner = Instance.new("Frame")
		svCursorInner.AnchorPoint = Vector2.new(0.5, 0.5)
		svCursorInner.Position = UDim2.fromScale(0.5, 0.5)
		svCursorInner.Size = UDim2.fromOffset(11, 11)
		svCursorInner.BackgroundTransparency = 1
		svCursorInner.ZIndex = Z.Popup + 4
		svCursorInner.Parent = svCursor
		Corner(svCursorInner, 6)
		Stroke(svCursorInner, Color3.new(1, 1, 1), 2, 0)

		hueBar = Instance.new("Frame")
		hueBar.Active = true
		hueBar.Position = UDim2.fromOffset(0, 114)
		hueBar.Size = UDim2.fromOffset(innerW, 10)
		hueBar.BackgroundColor3 = Color3.new(1, 1, 1)
		hueBar.BorderSizePixel = 0
		hueBar.ClipsDescendants = true
		hueBar.ZIndex = Z.Popup + 1
		hueBar.Parent = popupFrame
		Corner(hueBar, 5)

		local hueGradient = Instance.new("UIGradient")
		hueGradient.Color = ColorSequence.new({
			ColorSequenceKeypoint.new(0.000, Color3.fromHSV(0.000, 1, 1)),
			ColorSequenceKeypoint.new(0.166, Color3.fromHSV(0.166, 1, 1)),
			ColorSequenceKeypoint.new(0.333, Color3.fromHSV(0.333, 1, 1)),
			ColorSequenceKeypoint.new(0.500, Color3.fromHSV(0.500, 1, 1)),
			ColorSequenceKeypoint.new(0.666, Color3.fromHSV(0.666, 1, 1)),
			ColorSequenceKeypoint.new(0.833, Color3.fromHSV(0.833, 1, 1)),
			ColorSequenceKeypoint.new(1.000, Color3.fromHSV(1.000, 1, 1)),
		})
		hueGradient.Parent = hueBar

		local hueCursorLayer = Instance.new("Frame")
		hueCursorLayer.BackgroundTransparency = 1
		hueCursorLayer.BorderSizePixel = 0
		hueCursorLayer.ClipsDescendants = false
		hueCursorLayer.Position = hueBar.Position
		hueCursorLayer.Size = hueBar.Size
		hueCursorLayer.ZIndex = Z.Popup + 2
		hueCursorLayer.Parent = popupFrame

		hueCursor = Instance.new("Frame")
		hueCursor.AnchorPoint = Vector2.new(0.5, 0.5)
		hueCursor.Position = UDim2.new(hue, 0, 0.5, 0)
		hueCursor.Size = UDim2.fromOffset(6, 10)
		hueCursor.BackgroundColor3 = Color3.new(1, 1, 1)
		hueCursor.BorderSizePixel = 0
		hueCursor.ZIndex = Z.Popup + 3
		hueCursor.Parent = hueCursorLayer
		Corner(hueCursor, 3)
		Stroke(hueCursor, Color3.new(0, 0, 0), 1, 0.4)

		local hexHolder, hexRef = MiniField(popupFrame, "HEX", innerW, Z.Popup)
		hexHolder.Position = UDim2.fromOffset(0, 136)
		hexBox = hexRef

		local rgbRow = Instance.new("Frame")
		rgbRow.BackgroundTransparency = 1
		rgbRow.Position = UDim2.fromOffset(0, 182)
		rgbRow.Size = UDim2.fromOffset(innerW, 36)
		rgbRow.ZIndex = Z.Popup + 1
		rgbRow.Parent = popupFrame

		local rHolder, rRef = MiniField(rgbRow, "R", 54, Z.Popup)
		rHolder.Position = UDim2.fromOffset(0, 0)
		rBox = rRef

		local gHolder, gRef = MiniField(rgbRow, "G", 54, Z.Popup)
		gHolder.Position = UDim2.fromOffset(62, 0)
		gBox = gRef

		local bHolder, bRef = MiniField(rgbRow, "B", 56, Z.Popup)
		bHolder.Position = UDim2.fromOffset(124, 0)
		bBox = bRef

		local btnRow = Instance.new("Frame")
		btnRow.BackgroundTransparency = 1
		btnRow.Position = UDim2.fromOffset(0, 232)
		btnRow.Size = UDim2.fromOffset(innerW, 30)
		btnRow.ZIndex = Z.Popup + 1
		btnRow.Parent = popupFrame

		local function MakeButton(text, x, w, filled)
			local btn = Instance.new("TextButton")
			btn.Position = UDim2.fromOffset(x, 0)
			btn.Size = UDim2.fromOffset(w, 30)
			btn.FontFace = NullUI.Theme.Font
			btn.Text = text
			btn.TextSize = 13
			btn.AutoButtonColor = false
			btn.BorderSizePixel = 0
			btn.ZIndex = Z.Popup + 2
			if filled then
				btn.BackgroundColor3 = NullUI.Theme.Accent
				btn.BackgroundTransparency = 0
				btn.TextColor3 = NullUI.Theme.Background
			else
				btn.BackgroundColor3 = Color3.new(1, 1, 1)
				btn.BackgroundTransparency = 0.92
				btn.TextColor3 = NullUI.Theme.Text
				Role(btn, "Text")
			end
			btn.Parent = btnRow
			Corner(btn, 8)
			if not filled then
				Stroke(btn, Color3.new(1, 1, 1), 1, 0.88)
			end
			return btn
		end

		local halfW = (innerW - 10) / 2
		local cancelBtn = MakeButton("Cancel", 0, halfW, false)
		local doneBtn = MakeButton("Done", halfW + 10, halfW, true)

		cancelBtn.Activated:Connect(function()
			hue, sat, val = originalHue, originalSat, originalVal
			applyColor(true)
			closePopup()
		end)
		doneBtn.Activated:Connect(closePopup)

		svBox.InputBegan:Connect(function(input)
			if
				input.UserInputType == Enum.UserInputType.MouseButton1
				or input.UserInputType == Enum.UserInputType.Touch
			then
				if draggingSV or draggingHue then
					return
				end
				draggingSV = true
				colorInput = input
				updateSV(input.Position)
			end
		end)

		hueBar.InputBegan:Connect(function(input)
			if
				input.UserInputType == Enum.UserInputType.MouseButton1
				or input.UserInputType == Enum.UserInputType.Touch
			then
				if draggingSV or draggingHue then
					return
				end
				draggingHue = true
				colorInput = input
				updateHue(input.Position)
			end
		end)

		hexBox:GetPropertyChangedSignal("Text"):Connect(function()
			local filtered = hexBox.Text:gsub("[^%x]", "")
			filtered = filtered:sub(1, 6)
			if filtered ~= hexBox.Text then
				hexBox.Text = filtered
			end
		end)

		hexBox.FocusLost:Connect(function()
			local clean = hexBox.Text:gsub("#", "")
			if #clean == 3 then
				clean = clean:sub(1, 1):rep(2) .. clean:sub(2, 2):rep(2) .. clean:sub(3, 3):rep(2)
			end
			if #clean == 6 then
				local ok, c = pcall(Color3.fromHex, clean)
				if ok and c then
					hue, sat, val = Color3.toHSV(c)
					applyColor(true)
					return
				end
			end
			syncFields()
		end)

		local function filterDigits(b)
			b:GetPropertyChangedSignal("Text"):Connect(function()
				local filtered = b.Text:gsub("%D", ""):sub(1, 3)
				if filtered ~= b.Text then
					b.Text = filtered
				end
			end)
		end
		filterDigits(rBox)
		filterDigits(gBox)
		filterDigits(bBox)

		local function onRGBCommit()
			local r = math.clamp(tonumber(rBox.Text) or 0, 0, 255)
			local g = math.clamp(tonumber(gBox.Text) or 0, 0, 255)
			local b = math.clamp(tonumber(bBox.Text) or 0, 0, 255)
			hue, sat, val = Color3.toHSV(Color3.fromRGB(r, g, b))
			applyColor(true)
		end
		rBox.FocusLost:Connect(onRGBCommit)
		gBox.FocusLost:Connect(onRGBCommit)
		bBox.FocusLost:Connect(onRGBCommit)

		syncFields()

		Tween(popupFrame, {
			Size = UDim2.new(0, popupW, 0, popupH),
			BackgroundTransparency = 0.06,
		}, MOTION.Slow, MOTION.Style, MOTION.Direction)
		Tween(popupStroke, { Transparency = 0.7 }, MOTION.Normal, MOTION.Style, MOTION.Direction)

		followConn = RunService.RenderStepped:Connect(function()
			LPH_ATTRIBUTES(VM(NONE))
			if not popupFrame or not card.Parent then
				return
			end
			local nx, ny =
				ComputePopupPosition(mainWindow, card, popupW, popupH, self._window and self._window._content)
			popupFrame.Position = UDim2.fromOffset(nx, ny)
		end)
		jan:Add(followConn)
	end

	click.MouseButton1Click:Connect(function()
		if popupOpen then
			closePopup()
		else
			openPopup()
		end
	end)

	card.MouseEnter:Connect(function()
		Tween(card, { BackgroundTransparency = 0.93 }, 0.18)
	end)
	card.MouseLeave:Connect(function()
		Tween(card, { BackgroundTransparency = 0.96 }, 0.18)
	end)

	return RegisterFlag(opts, {
		Instance = card,
		Set = function(_, c, silent)
			hue, sat, val = Color3.toHSV(c)
			applyColor(not silent)
			if silent then
				lastFired = currentColor()
			end
		end,
		Get = function()
			return currentColor()
		end,
		OnChanged = function(_, fn)
			return signal.Connect(fn)
		end,
		Destroy = function()
			closePopup()
			signal.Clear()
			card:Destroy()
		end,
	}, "ColorPicker")
end

function Tab:AddKeybind(opts)
	opts = opts or {}
	local hasDesc = opts.Description and opts.Description ~= ""
	local height = hasDesc and 54 or 40
	local jan = self._janitor

	local card = BaseCard(self._page, height)
	local textX = AddLeadingIcon(card, opts.Icon, height)
	AddTitleDesc(card, textX, 128, opts.Text or "Keybind", opts.Description, height)
	self._window:_RegisterSearchable(self, opts.Text or "Keybind", card)

	local currentKey = opts.Default

	local pill = Instance.new("Frame")
	pill.AnchorPoint = Vector2.new(1, 0.5)
	pill.Position = UDim2.new(1, -14, 0.5, 0)
	pill.Size = UDim2.fromOffset(104, 26)
	pill.BackgroundColor3 = Color3.new(1, 1, 1)
	pill.BackgroundTransparency = 0.9
	pill.BorderSizePixel = 0
	pill.ZIndex = Z.Content + 2
	pill.Parent = card
	Corner(pill, 8)
	local pillStroke = Stroke(pill, Color3.new(1, 1, 1), 1, 0.88)

	local keyIcon = Instance.new("ImageLabel")
	keyIcon.BackgroundTransparency = 1
	keyIcon.Image = ResolveIcon("keyboard")
	keyIcon.ImageColor3 = NullUI.Theme.TextDim
	Role(keyIcon, "TextDim")
	keyIcon.Size = UDim2.fromOffset(13, 13)
	keyIcon.AnchorPoint = Vector2.new(0, 0.5)
	keyIcon.Position = UDim2.new(0, 10, 0.5, 0)
	keyIcon.ZIndex = Z.Content + 3
	keyIcon.Parent = pill

	local keyLabel = Instance.new("TextLabel")
	keyLabel.BackgroundTransparency = 1
	keyLabel.FontFace = NullUI.Theme.FontRegular
	keyLabel.Text = currentKey and currentKey.Name or "None"
	keyLabel.TextColor3 = NullUI.Theme.Text
	Role(keyLabel, "Text")
	keyLabel.TextSize = 13
	keyLabel.TextTruncate = Enum.TextTruncate.AtEnd
	keyLabel.TextXAlignment = Enum.TextXAlignment.Left
	keyLabel.Position = UDim2.fromOffset(29, 0)
	keyLabel.Size = UDim2.new(1, -37, 1, 0)
	keyLabel.ZIndex = Z.Content + 3
	keyLabel.Parent = pill

	local click = Instance.new("TextButton")
	click.Text = ""
	click.AutoButtonColor = false
	click.BackgroundTransparency = 1
	click.Size = UDim2.fromScale(1, 1)
	click.ZIndex = Z.Content + 4
	click.Parent = pill

	local listening = false
	local listenConn = nil
	local signal = MakeSignal()

	local function fireChanged(key)
		signal.Fire(key)
	end

	local function stopListening()
		listening = false
		KeybindCapturing = false
		if listenConn then
			listenConn:Disconnect()
			listenConn = nil
		end
		Tween(pillStroke, { Color = Color3.new(1, 1, 1), Transparency = 0.88 }, 0.18)
		Tween(pill, { BackgroundTransparency = 0.9 }, 0.18)
		keyLabel.Text = currentKey and currentKey.Name or "None"
	end

	local function startListening()
		if listening then
			return
		end
		listening = true
		KeybindCapturing = true
		keyLabel.Text = "..."
		Tween(pillStroke, { Color = NullUI.Theme.Accent, Transparency = 0.3 }, 0.18)
		Tween(pill, { BackgroundTransparency = 0.82 }, 0.18)

		listenConn = UserInputService.InputBegan:Connect(function(input)
			if input.UserInputType ~= Enum.UserInputType.Keyboard then
				return
			end

			if input.KeyCode == Enum.KeyCode.Escape then
				stopListening()
				return
			end
			if input.KeyCode == Enum.KeyCode.Backspace or input.KeyCode == Enum.KeyCode.Delete then
				currentKey = nil
				stopListening()
				fireChanged(nil)
				return
			end

			currentKey = input.KeyCode
			stopListening()
			if opts.Callback then
				SafeSpawn(opts.Callback, currentKey, "bind")
			end
			fireChanged(currentKey)
		end)
		jan:Add(listenConn)
	end

	click.MouseButton1Click:Connect(startListening)

	jan:Add(UserInputService.InputBegan:Connect(function(input, gameProcessed)
		if listening or KeybindCapturing or gameProcessed then
			return
		end
		if UserInputService:GetFocusedTextBox() then
			return
		end
		if currentKey and input.UserInputType == Enum.UserInputType.Keyboard and input.KeyCode == currentKey then
			if opts.Callback then
				SafeSpawn(opts.Callback, currentKey, "press")
			end
		end
	end))

	card.MouseEnter:Connect(function()
		Tween(card, { BackgroundTransparency = 0.93 }, 0.18)
	end)
	card.MouseLeave:Connect(function()
		Tween(card, { BackgroundTransparency = 0.96 }, 0.18)
	end)

	return RegisterFlag(opts, {
		Instance = card,
		Set = function(_, key, silent)
			currentKey = key
			keyLabel.Text = key and key.Name or "None"
			if not silent then
				fireChanged(key)
			end
		end,
		Get = function()
			return currentKey
		end,
		OnChanged = function(_, fn)
			return signal.Connect(fn)
		end,
		Destroy = function()
			stopListening()
			signal.Clear()
			card:Destroy()
		end,
	}, "Keybind")
end

local ConsoleColors = {
	[Enum.MessageType.MessageInfo] = Color3.fromRGB(120, 170, 255),
	[Enum.MessageType.MessageWarning] = Color3.fromRGB(255, 190, 90),
	[Enum.MessageType.MessageError] = Color3.fromRGB(255, 105, 105),
	[Enum.MessageType.MessageOutput] = nil,
}

function Tab:AddConsole(opts)
	opts = opts or {}
	local height = opts.Height or 200
	local maxLogs = opts.MaxLogs or 300
	local jan = self._janitor

	local container = Instance.new("Frame")
	container.Name = "Console"
	container.BackgroundColor3 = NullUI.Theme.Surface
	container.BackgroundTransparency = 0.35
	container.BorderSizePixel = 0
	container.ClipsDescendants = true
	container.Size = UDim2.new(1, 0, 0, height)
	container.ZIndex = Z.Content
	container.Parent = self._page
	Corner(container, NullUI.Theme.CornerRadiusSm)
	Stroke(container, Color3.new(1, 1, 1), 1, 0.92)

	local header = Instance.new("Frame")
	header.Name = "Header"
	header.BackgroundTransparency = 1
	header.Size = UDim2.new(1, 0, 0, 34)
	header.ZIndex = Z.Content + 1
	header.Parent = container

	local headerPad = Instance.new("UIPadding")
	headerPad.PaddingLeft = UDim.new(0, 12)
	headerPad.PaddingRight = UDim.new(0, 8)
	headerPad.Parent = header

	local titleRow = Instance.new("Frame")
	titleRow.BackgroundTransparency = 1
	titleRow.Size = UDim2.new(1, -70, 1, 0)
	titleRow.ZIndex = Z.Content + 2
	titleRow.Parent = header

	local titleLayout = Instance.new("UIListLayout")
	titleLayout.FillDirection = Enum.FillDirection.Horizontal
	titleLayout.VerticalAlignment = Enum.VerticalAlignment.Center
	titleLayout.Padding = UDim.new(0, 7)
	titleLayout.Parent = titleRow

	local titleIcon = Instance.new("ImageLabel")
	titleIcon.BackgroundTransparency = 1
	titleIcon.Image = ResolveIcon("terminal")
	titleIcon.ImageColor3 = NullUI.Theme.TextDim
	Role(titleIcon, "TextDim")
	titleIcon.Size = UDim2.fromOffset(14, 14)
	titleIcon.LayoutOrder = 1
	titleIcon.ZIndex = Z.Content + 3
	titleIcon.Parent = titleRow

	local titleLabel = Instance.new("TextLabel")
	titleLabel.BackgroundTransparency = 1
	titleLabel.FontFace = NullUI.Theme.Font
	titleLabel.Text = opts.Title or "Debug Console"
	titleLabel.TextColor3 = NullUI.Theme.Text
	Role(titleLabel, "Text")
	titleLabel.TextSize = 13
	titleLabel.TextXAlignment = Enum.TextXAlignment.Left
	titleLabel.TextTruncate = Enum.TextTruncate.AtEnd
	titleLabel.AutomaticSize = Enum.AutomaticSize.X
	titleLabel.Size = UDim2.fromOffset(0, 14)
	titleLabel.LayoutOrder = 2
	titleLabel.ZIndex = Z.Content + 3
	titleLabel.Parent = titleRow

	local controls = Instance.new("Frame")
	controls.BackgroundTransparency = 1
	controls.AnchorPoint = Vector2.new(1, 0.5)
	controls.Position = UDim2.new(1, 0, 0.5, 0)
	controls.Size = UDim2.fromOffset(58, 24)
	controls.ZIndex = Z.Content + 2
	controls.Parent = header

	local controlsLayout = Instance.new("UIListLayout")
	controlsLayout.FillDirection = Enum.FillDirection.Horizontal
	controlsLayout.HorizontalAlignment = Enum.HorizontalAlignment.Right
	controlsLayout.VerticalAlignment = Enum.VerticalAlignment.Center
	controlsLayout.Padding = UDim.new(0, 4)
	controlsLayout.Parent = controls

	local function iconButton(icon, order)
		local btn = Instance.new("TextButton")
		btn.Text = ""
		btn.AutoButtonColor = false
		btn.BackgroundColor3 = Color3.new(1, 1, 1)
		btn.BackgroundTransparency = 1
		btn.BorderSizePixel = 0
		btn.Size = UDim2.fromOffset(24, 24)
		btn.LayoutOrder = order
		btn.ZIndex = Z.Content + 3
		btn.Parent = controls
		Corner(btn, 7)

		local ic = Instance.new("ImageLabel")
		ic.BackgroundTransparency = 1
		ic.Image = ResolveIcon(icon)
		ic.ImageColor3 = NullUI.Theme.TextDim
		Role(ic, "TextDim")
		ic.Size = UDim2.fromOffset(13, 13)
		ic.AnchorPoint = Vector2.new(0.5, 0.5)
		ic.Position = UDim2.fromScale(0.5, 0.5)
		ic.ZIndex = Z.Content + 4
		ic.Parent = btn

		jan:Add(btn.MouseEnter:Connect(function()
			Tween(btn, { BackgroundTransparency = 0.9 }, 0.12)
			Tween(ic, { ImageColor3 = NullUI.Theme.Text }, 0.12)
		end))
		jan:Add(btn.MouseLeave:Connect(function()
			Tween(btn, { BackgroundTransparency = 1 }, 0.12)
			Tween(ic, { ImageColor3 = NullUI.Theme.TextDim }, 0.12)
		end))

		return btn, ic
	end

	local copyBtn, copyIcon = iconButton("copy", 1)
	local clearBtn = iconButton("trash-2", 2)

	local divider = Instance.new("Frame")
	divider.BackgroundColor3 = Color3.new(1, 1, 1)
	divider.BackgroundTransparency = 0.92
	divider.BorderSizePixel = 0
	divider.Size = UDim2.new(1, 0, 0, 1)
	divider.Position = UDim2.fromOffset(0, 34)
	divider.ZIndex = Z.Content + 1
	divider.Parent = container

	local logsScroll = Instance.new("ScrollingFrame")
	logsScroll.Name = "Logs"
	logsScroll.BackgroundTransparency = 1
	logsScroll.BorderSizePixel = 0
	logsScroll.Position = UDim2.fromOffset(0, 35)
	logsScroll.Size = UDim2.new(1, 0, 1, -35)
	logsScroll.ScrollingDirection = Enum.ScrollingDirection.Y
	logsScroll.ScrollBarThickness = 0
	logsScroll.AutomaticCanvasSize = Enum.AutomaticSize.Y
	logsScroll.CanvasSize = UDim2.new(0, 0, 0, 0)
	logsScroll.ZIndex = Z.Content + 1
	logsScroll.Parent = container

	local logsPad = Instance.new("UIPadding")
	logsPad.PaddingTop = UDim.new(0, 8)
	logsPad.PaddingBottom = UDim.new(0, 8)
	logsPad.PaddingLeft = UDim.new(0, 10)
	logsPad.PaddingRight = UDim.new(0, 10)
	logsPad.Parent = logsScroll

	local logsLayout = Instance.new("UIListLayout")
	logsLayout.Padding = UDim.new(0, 4)
	logsLayout.SortOrder = Enum.SortOrder.LayoutOrder
	logsLayout.Parent = logsScroll

	AddScrollbar(logsScroll)
	AddContentScrollThumb(logsScroll, logsLayout, container, jan)

	local emptyState = Instance.new("Frame")
	emptyState.Name = "EmptyState"
	emptyState.BackgroundTransparency = 1
	emptyState.Position = UDim2.fromOffset(0, 35)
	emptyState.Size = UDim2.new(1, 0, 1, -35)
	emptyState.ZIndex = Z.Content + 2
	emptyState.Parent = container

	local emptyLayout = Instance.new("UIListLayout")
	emptyLayout.FillDirection = Enum.FillDirection.Vertical
	emptyLayout.HorizontalAlignment = Enum.HorizontalAlignment.Center
	emptyLayout.VerticalAlignment = Enum.VerticalAlignment.Center
	emptyLayout.Padding = UDim.new(0, 6)
	emptyLayout.Parent = emptyState

	local emptyIcon = Instance.new("ImageLabel")
	emptyIcon.BackgroundTransparency = 1
	emptyIcon.Image = ResolveIcon("frown")
	emptyIcon.ImageColor3 = NullUI.Theme.TextDim
	Role(emptyIcon, "TextDim")
	emptyIcon.Size = UDim2.fromOffset(22, 22)
	emptyIcon.LayoutOrder = 1
	emptyIcon.ZIndex = Z.Content + 3
	emptyIcon.Parent = emptyState

	local emptyLabel = Instance.new("TextLabel")
	emptyLabel.BackgroundTransparency = 1
	emptyLabel.FontFace = NullUI.Theme.FontRegular
	emptyLabel.Text = "No logs at the moment"
	emptyLabel.TextColor3 = NullUI.Theme.TextDim
	Role(emptyLabel, "TextDim")
	emptyLabel.TextSize = 12
	emptyLabel.AutomaticSize = Enum.AutomaticSize.XY
	emptyLabel.Size = UDim2.fromOffset(0, 14)
	emptyLabel.LayoutOrder = 2
	emptyLabel.ZIndex = Z.Content + 3
	emptyLabel.Parent = emptyState

	local logs = {}
	local logCount = 0
	local counter = 0
	local autoScroll = true

	local function trimLogs()
		while logCount > maxLogs do
			local oldest = table.remove(logs, 1)
			if oldest then
				oldest:Destroy()
				logCount = logCount - 1
			else
				break
			end
		end
	end

	local function escapeRich(text)
		return (text:gsub("&", "&amp;"):gsub("<", "&lt;"):gsub(">", "&gt;"))
	end

	local function addLog(message, messageType)
		message = tostring(message or "")
		if message == "" then
			return
		end
		trimLogs()

		counter = counter + 1
		local color = ConsoleColors[messageType] or NullUI.Theme.Text

		local entry = Instance.new("TextLabel")
		entry.Name = "Entry"
		entry.BackgroundTransparency = 1
		entry.RichText = true
		entry.FontFace = NullUI.Theme.FontRegular
		entry.TextSize = 12
		entry.TextWrapped = true
		entry.TextXAlignment = Enum.TextXAlignment.Left
		entry.TextYAlignment = Enum.TextYAlignment.Top
		entry.LineHeight = 1.25
		entry.AutomaticSize = Enum.AutomaticSize.Y
		entry.Size = UDim2.new(1, 0, 0, 14)
		entry.LayoutOrder = counter
		entry.ZIndex = Z.Content + 2
		entry.Text = string.format(
			'<font color="#%s" transparency="0.45">[%s]</font> <font color="#%s">%s</font>',
			NullUI.Theme.TextDim:ToHex(),
			os.date("%H:%M:%S"),
			color:ToHex(),
			escapeRich(message)
		)
		entry.Parent = logsScroll

		table.insert(logs, entry)
		logCount = logCount + 1
		emptyState.Visible = false

		if autoScroll then
			SafeDefer(function()
				logsScroll.CanvasPosition = Vector2.new(0, logsScroll.AbsoluteCanvasSize.Y)
			end)
		end
	end

	jan:Add(logsScroll:GetPropertyChangedSignal("CanvasPosition"):Connect(function()
		LPH_ATTRIBUTES(VM(NONE))
		local atBottom = logsScroll.CanvasPosition.Y
			>= logsScroll.AbsoluteCanvasSize.Y - logsScroll.AbsoluteWindowSize.Y - 20
		autoScroll = atBottom
	end))

	copyBtn.MouseButton1Click:Connect(function()
		local setclipboard = hasFn("setclipboard")
		if not setclipboard then
			return
		end

		local lines = {}
		for _, entry in ipairs(logs) do
			local clean = entry.Text
				:gsub("<font[^>]*>", "")
				:gsub("</font>", "")
				:gsub("&lt;", "<")
				:gsub("&gt;", ">")
				:gsub("&amp;", "&")
			table.insert(lines, clean)
		end
		setclipboard(table.concat(lines, "\n"))

		Tween(copyIcon, { ImageColor3 = Color3.fromRGB(120, 220, 140) }, 0.12)
		SafeDelay(0.4, function()
			if copyIcon.Parent then
				Tween(copyIcon, { ImageColor3 = NullUI.Theme.TextDim }, 0.18)
			end
		end)
	end)

	local function clearLogs()
		for _, entry in ipairs(logs) do
			entry:Destroy()
		end
		table.clear(logs)
		logCount = 0
		emptyState.Visible = true
	end

	clearBtn.MouseButton1Click:Connect(clearLogs)

	if opts.AutoCapture ~= false then
		local LogService = game:GetService("LogService")
		jan:Add(LogService.MessageOut:Connect(addLog))
	end

	return {
		Instance = container,
		Log = function(_, message, messageType)
			addLog(message, messageType)
		end,
		Clear = function()
			clearLogs()
		end,
		Destroy = function()
			container:Destroy()
		end,
	}
end

function Tab:AddTable(opts)
	opts = opts or {}
	local jan = self._janitor
	local title = opts.Title or "Table"
	local hasDesc = opts.Description and opts.Description ~= ""
	local columns = opts.Columns or {}
	local rowHeight = opts.RowHeight or 30
	local bodyHeight = opts.Height or 200
	local sortable = opts.Sortable ~= false
	local striped = opts.Striped ~= false

	local totalWeight = 0
	for _, col in ipairs(columns) do
		col.Weight = col.Weight or 1
		totalWeight = totalWeight + col.Weight
	end
	if totalWeight <= 0 then
		totalWeight = 1
	end

	local function colAlign(col)
		if col.Align == "Right" then
			return Enum.TextXAlignment.Right
		end
		if col.Align == "Center" then
			return Enum.TextXAlignment.Center
		end
		return Enum.TextXAlignment.Left
	end

	local function colX(index)
		local w = 0
		for i = 1, index - 1 do
			w = w + columns[i].Weight
		end
		return w / totalWeight
	end

	local PAD = 12
	local HEADER_H = hasDesc and 32 or 16
	local COLHEAD_H = 26
	local GAP1, GAP2 = 10, 6
	local colHeadY = PAD + HEADER_H + GAP1
	local scrollY = colHeadY + COLHEAD_H + GAP2
	local totalHeight = scrollY + bodyHeight + PAD

	local container = Instance.new("Frame")
	container.Name = "Table"
	container.BackgroundColor3 = NullUI.Theme.Surface
	container.BackgroundTransparency = 0.35
	container.BorderSizePixel = 0
	container.ClipsDescendants = true
	container.Size = UDim2.new(1, 0, 0, totalHeight)
	container.ZIndex = Z.Content
	container.Parent = self._page
	Corner(container, NullUI.Theme.CornerRadiusSm)
	Stroke(container, Color3.new(1, 1, 1), 1, 0.92)
	self._window:_RegisterSearchable(self, title, container)

	local titleLabel = Instance.new("TextLabel")
	titleLabel.BackgroundTransparency = 1
	titleLabel.FontFace = NullUI.Theme.Font
	titleLabel.Text = title
	titleLabel.TextColor3 = NullUI.Theme.Text
	Role(titleLabel, "Text")
	titleLabel.TextSize = 14
	titleLabel.TextXAlignment = Enum.TextXAlignment.Left
	titleLabel.TextTruncate = Enum.TextTruncate.AtEnd
	titleLabel.Position = UDim2.fromOffset(PAD, PAD)
	titleLabel.Size = UDim2.new(1, -PAD * 2, 0, 16)
	titleLabel.ZIndex = Z.Content + 1
	titleLabel.Parent = container

	if hasDesc then
		local descLabel = Instance.new("TextLabel")
		descLabel.BackgroundTransparency = 1
		descLabel.FontFace = NullUI.Theme.FontRegular
		descLabel.Text = opts.Description
		descLabel.TextColor3 = NullUI.Theme.TextDim
		Role(descLabel, "TextDim")
		descLabel.TextSize = 12
		descLabel.TextWrapped = true
		descLabel.TextXAlignment = Enum.TextXAlignment.Left
		descLabel.TextYAlignment = Enum.TextYAlignment.Top
		descLabel.Position = UDim2.fromOffset(PAD, PAD + 18)
		descLabel.Size = UDim2.new(1, -PAD * 2, 0, 14)
		descLabel.ZIndex = Z.Content + 1
		descLabel.Parent = container
	end

	local colHead = Instance.new("Frame")
	colHead.Name = "ColumnHeader"
	colHead.BackgroundTransparency = 1
	colHead.Position = UDim2.fromOffset(PAD, colHeadY)
	colHead.Size = UDim2.new(1, -PAD * 2, 0, COLHEAD_H)
	colHead.ZIndex = Z.Content + 1
	colHead.Parent = container

	local sortState = { Key = nil, Asc = true }
	local headerLabels = {}

	for ci, col in ipairs(columns) do
		local x0 = colX(ci)
		local wFrac = col.Weight / totalWeight

		local cellBtn = Instance.new("TextButton")
		cellBtn.Name = "Col" .. ci
		cellBtn.Text = ""
		cellBtn.AutoButtonColor = false
		cellBtn.BackgroundTransparency = 1
		cellBtn.Position = UDim2.new(x0, ci > 1 and 4 or 0, 0, 0)
		cellBtn.Size = UDim2.new(wFrac, ci > 1 and -4 or 0, 1, 0)
		cellBtn.ZIndex = Z.Content + 2
		cellBtn.Parent = colHead

		local lbl = Instance.new("TextLabel")
		lbl.BackgroundTransparency = 1
		lbl.FontFace = NullUI.Theme.Font
		lbl.Text = tostring(col.Label or col.Key or "")
		lbl.TextColor3 = NullUI.Theme.TextDim
		Role(lbl, "TextDim")
		lbl.TextSize = 12
		lbl.TextXAlignment = colAlign(col)
		lbl.TextTruncate = Enum.TextTruncate.AtEnd
		lbl.Size = UDim2.new(1, 0, 1, 0)
		lbl.ZIndex = Z.Content + 3
		lbl.Parent = cellBtn

		headerLabels[col.Key] = { Lbl = lbl, Text = tostring(col.Label or col.Key or "") }

		if sortable then
			cellBtn.MouseEnter:Connect(function()
				if sortState.Key ~= col.Key then
					Tween(lbl, { TextColor3 = NullUI.Theme.Text }, 0.12)
				end
			end)
			cellBtn.MouseLeave:Connect(function()
				if sortState.Key ~= col.Key then
					Tween(lbl, { TextColor3 = NullUI.Theme.TextDim }, 0.12)
				end
			end)
		end
	end

	local divider = Instance.new("Frame")
	divider.BackgroundColor3 = Color3.new(1, 1, 1)
	divider.BackgroundTransparency = 0.92
	divider.BorderSizePixel = 0
	divider.Position = UDim2.fromOffset(0, colHeadY + COLHEAD_H)
	divider.Size = UDim2.new(1, 0, 0, 1)
	divider.ZIndex = Z.Content + 1
	divider.Parent = container

	local scroll = Instance.new("ScrollingFrame")
	scroll.Name = "Rows"
	scroll.BackgroundTransparency = 1
	scroll.BorderSizePixel = 0
	scroll.Position = UDim2.fromOffset(0, scrollY)
	scroll.Size = UDim2.new(1, 0, 0, bodyHeight)
	scroll.ScrollingDirection = Enum.ScrollingDirection.Y
	scroll.ScrollBarThickness = 0
	scroll.AutomaticCanvasSize = Enum.AutomaticSize.Y
	scroll.CanvasSize = UDim2.new(0, 0, 0, 0)
	scroll.ZIndex = Z.Content + 1
	scroll.Parent = container

	local scrollPad = Instance.new("UIPadding")
	scrollPad.PaddingLeft = UDim.new(0, PAD)
	scrollPad.PaddingRight = UDim.new(0, PAD)
	scrollPad.Parent = scroll

	local rowsLayout = Instance.new("UIListLayout")
	rowsLayout.SortOrder = Enum.SortOrder.LayoutOrder
	rowsLayout.Parent = scroll

	AddScrollbar(scroll)
	AddContentScrollThumb(scroll, rowsLayout, container, jan)

	local emptyLabel = Instance.new("TextLabel")
	emptyLabel.BackgroundTransparency = 1
	emptyLabel.FontFace = NullUI.Theme.FontRegular
	emptyLabel.Text = "No rows"
	emptyLabel.TextColor3 = NullUI.Theme.TextDim
	Role(emptyLabel, "TextDim")
	emptyLabel.TextSize = 12
	emptyLabel.Position = UDim2.fromOffset(PAD, scrollY + 10)
	emptyLabel.Size = UDim2.new(1, -PAD * 2, 0, 16)
	emptyLabel.Visible = false
	emptyLabel.ZIndex = Z.Content + 1
	emptyLabel.Parent = container

	local currentRows = {}
	local rowFrames = {}

	local function clearRowFrames()
		for _, f in ipairs(rowFrames) do
			f:Destroy()
		end
		table.clear(rowFrames)
	end

	local function renderRows()
		clearRowFrames()
		emptyLabel.Visible = #currentRows == 0
		for ri, row in ipairs(currentRows) do
			local rowFrame = Instance.new("Frame")
			rowFrame.Name = "Row" .. ri
			rowFrame.BackgroundColor3 = Color3.new(1, 1, 1)
			rowFrame.BackgroundTransparency = (striped and ri % 2 == 0) and 0.97 or 1
			rowFrame.BorderSizePixel = 0
			rowFrame.LayoutOrder = ri
			rowFrame.Size = UDim2.new(1, 0, 0, rowHeight)
			rowFrame.ZIndex = Z.Content + 2
			rowFrame.Parent = scroll

			for ci, col in ipairs(columns) do
				local x0 = colX(ci)
				local wFrac = col.Weight / totalWeight

				local cell = Instance.new("TextLabel")
				cell.Name = "Cell" .. ci
				cell.BackgroundTransparency = 1
				cell.FontFace = NullUI.Theme.FontRegular
				cell.Text = tostring(row[col.Key] == nil and "" or row[col.Key])
				cell.TextColor3 = NullUI.Theme.Text
				Role(cell, "Text")
				cell.TextSize = 12
				cell.TextXAlignment = colAlign(col)
				cell.TextTruncate = Enum.TextTruncate.AtEnd
				cell.Position = UDim2.new(x0, ci > 1 and 4 or 0, 0, 0)
				cell.Size = UDim2.new(wFrac, ci > 1 and -4 or 0, 1, 0)
				cell.ZIndex = Z.Content + 3
				cell.Parent = rowFrame
			end

			table.insert(rowFrames, rowFrame)
		end
	end

	local function compareValues(av, bv)
		local an, bn = tonumber(av), tonumber(bv)
		if an and bn then
			if an == bn then
				return 0
			end
			return an < bn and -1 or 1
		end
		local as, bs = tostring(av or ""), tostring(bv or "")
		if as == bs then
			return 0
		end
		return as < bs and -1 or 1
	end

	local function applySort()
		if not sortState.Key then
			return
		end
		table.sort(currentRows, function(a, b)
			local c = compareValues(a[sortState.Key], b[sortState.Key])
			if sortState.Asc then
				return c < 0
			else
				return c > 0
			end
		end)
		renderRows()
	end

	if sortable then
		for ci, col in ipairs(columns) do
			local cellBtn = colHead:FindFirstChild("Col" .. ci)
			if cellBtn then
				cellBtn.MouseButton1Click:Connect(function()
					if sortState.Key == col.Key then
						sortState.Asc = not sortState.Asc
					else
						sortState.Key = col.Key
						sortState.Asc = true
					end
					for key, info in pairs(headerLabels) do
						local arrow = ""
						if key == sortState.Key then
							arrow = sortState.Asc and "  \226\150\178" or "  \226\150\188"
						end
						info.Lbl.Text = info.Text .. arrow
						info.Lbl.TextColor3 = (key == sortState.Key) and NullUI.Theme.Text or NullUI.Theme.TextDim
					end
					applySort()
				end)
			end
		end
	end

	local api = {
		Instance = container,
		SetRows = function(_, rows)
			currentRows = rows or {}
			if sortState.Key then
				applySort()
			else
				renderRows()
			end
		end,
		GetRows = function()
			return currentRows
		end,
		Destroy = function()
			container:Destroy()
		end,
	}

	api:SetRows(opts.Rows or {})

	return api
end

local function Serialize(value)
	local t = typeof(value)
	if t == "Color3" then
		return { __t = "Color3", r = value.R, g = value.G, b = value.B }
	elseif t == "EnumItem" then
		return { __t = "Enum", v = tostring(value) }
	elseif t == "table" then
		local out = {}
		for i, v in ipairs(value) do
			out[i] = Serialize(v)
		end
		return out
	end
	return value
end

local function Deserialize(value)
	if type(value) ~= "table" then
		return value
	end
	if value.__t == "Color3" then
		return Color3.new(value.r, value.g, value.b)
	elseif value.__t == "Enum" then
		local parts = string.split(value.v, ".")
		local ok, result = pcall(function()
			return Enum[parts[2]][parts[3]]
		end)
		return ok and result or nil
	end
	local out = {}
	for i, v in ipairs(value) do
		out[i] = Deserialize(v)
	end
	return out
end

function Tab:AddCardGrid(opts)
	opts = opts or {}
	local height = opts.Height or 380
	local sorts = opts.Sorts or {}
	local pageSize = opts.PageSize or 20
	local showSearch = opts.Search ~= false
	local descriptionHeight = opts.DescriptionHeight or 28
	local showNativeScrollbar = opts.ShowScrollbar == true
	local cardPadding = opts.CardPadding or 10

	local outer = Instance.new("Frame")
	outer.Name = "CardGrid"
	outer.BackgroundColor3 = Color3.new(1, 1, 1)
	outer.BackgroundTransparency = 0.97
	outer.BorderSizePixel = 0
	outer.Size = UDim2.new(1, 0, 0, height)
	outer.ZIndex = Z.Content
	outer.Parent = self._page
	Corner(outer, NullUI.Theme.CornerRadiusSm)
	Stroke(outer, Color3.new(1, 1, 1), 1, 0.95)
	self._window:_RegisterSearchable(self, opts.Title or "Cards", outer)

	local content = Instance.new("Frame")
	content.Name = "Content"
	content.BackgroundTransparency = 1
	content.Size = UDim2.fromScale(1, 1)
	content.ZIndex = Z.Content + 1
	content.Parent = outer

	local OUTER_V_PAD = opts.OuterPadding or 18
	local pad = Instance.new("UIPadding")
	pad.PaddingTop = UDim.new(0, OUTER_V_PAD)
	pad.PaddingBottom = UDim.new(0, OUTER_V_PAD)
	pad.PaddingLeft = UDim.new(0, 12)
	pad.PaddingRight = UDim.new(0, 12)
	pad.Parent = content

	local TOP_H, TABS_H = 32, 28
	local headerH = 0
	if showSearch then
		headerH = headerH + TOP_H
	end
	if #sorts > 1 then
		if headerH > 0 then
			headerH = headerH + 8
		end
		headerH = headerH + TABS_H
	end
	if headerH > 0 then
		headerH = headerH + 10
	end

	local searchBox
	if showSearch then
		local searchPill = Instance.new("Frame")
		searchPill.BackgroundColor3 = Color3.new(1, 1, 1)
		searchPill.BackgroundTransparency = 0.92
		searchPill.BorderSizePixel = 0
		searchPill.Size = UDim2.new(1, 0, 0, TOP_H)
		searchPill.ZIndex = Z.Content + 1
		searchPill.Parent = content
		Corner(searchPill, 9)
		local searchStroke = Stroke(searchPill, Color3.new(1, 1, 1), 1, 0.88)

		local searchIcon = Instance.new("ImageLabel")
		searchIcon.BackgroundTransparency = 1
		searchIcon.Image = ResolveIcon("search")
		searchIcon.ImageColor3 = NullUI.Theme.TextDim
		Role(searchIcon, "TextDim")
		searchIcon.Size = UDim2.fromOffset(13, 13)
		searchIcon.AnchorPoint = Vector2.new(0, 0.5)
		searchIcon.Position = UDim2.new(0, 10, 0.5, 0)
		searchIcon.ZIndex = Z.Content + 2
		searchIcon.Parent = searchPill

		searchBox = Instance.new("TextBox")
		searchBox.ClearTextOnFocus = false
		searchBox.FontFace = NullUI.Theme.FontRegular
		searchBox.PlaceholderText = opts.SearchPlaceholder or "Search by name / tags..."
		searchBox.PlaceholderColor3 = Color3.fromRGB(120, 120, 122)
		searchBox.Text = ""
		searchBox.TextColor3 = NullUI.Theme.Text
		Role(searchBox, "Text")
		searchBox.TextSize = 13
		searchBox.TextXAlignment = Enum.TextXAlignment.Left
		searchBox.TextYAlignment = Enum.TextYAlignment.Center
		searchBox.BackgroundTransparency = 1
		searchBox.ClipsDescendants = true
		searchBox.Position = UDim2.fromOffset(30, 0)
		searchBox.Size = UDim2.new(1, -40, 1, 0)
		searchBox.ZIndex = Z.Content + 2
		searchBox.Parent = searchPill

		searchBox.Focused:Connect(function()
			Tween(searchStroke, { Color = NullUI.Theme.Accent, Transparency = 0.3 }, 0.18)
		end)
		searchBox.FocusLost:Connect(function()
			Tween(searchStroke, { Color = Color3.new(1, 1, 1), Transparency = 0.88 }, 0.18)
		end)
	end

	local currentSort = opts.DefaultSort or sorts[1]
	local sortButtons = {}
	if #sorts > 1 then
		local tabsRow = Instance.new("Frame")
		tabsRow.BackgroundTransparency = 1
		tabsRow.Position = UDim2.fromOffset(0, showSearch and (TOP_H + 8) or 0)
		tabsRow.Size = UDim2.new(1, 0, 0, TABS_H)
		tabsRow.ZIndex = Z.Content + 1
		tabsRow.Parent = content

		local tabsLayout = Instance.new("UIListLayout")
		tabsLayout.FillDirection = Enum.FillDirection.Horizontal
		tabsLayout.Padding = UDim.new(0, 6)
		tabsLayout.SortOrder = Enum.SortOrder.LayoutOrder
		tabsLayout.Parent = tabsRow

		for i, sortName in ipairs(sorts) do
			local btn = Instance.new("TextButton")
			btn.AutoButtonColor = false
			btn.Text = ""
			btn.BackgroundColor3 = Color3.new(1, 1, 1)
			btn.BackgroundTransparency = (sortName == currentSort) and 0.85 or 1
			btn.BorderSizePixel = 0
			btn.AutomaticSize = Enum.AutomaticSize.X
			btn.Size = UDim2.fromOffset(0, TABS_H)
			btn.LayoutOrder = i
			btn.ZIndex = Z.Content + 1
			btn.Parent = tabsRow
			Corner(btn, 7)

			local btnPad = Instance.new("UIPadding")
			btnPad.PaddingLeft = UDim.new(0, 10)
			btnPad.PaddingRight = UDim.new(0, 10)
			btnPad.Parent = btn

			local lbl = Instance.new("TextLabel")
			lbl.BackgroundTransparency = 1
			lbl.FontFace = NullUI.Theme.Font
			lbl.Text = string.upper(sortName)
			lbl.TextColor3 = (sortName == currentSort) and NullUI.Theme.Text or NullUI.Theme.TextDim
			lbl.TextSize = 11
			lbl.AutomaticSize = Enum.AutomaticSize.X
			lbl.Size = UDim2.fromOffset(0, TABS_H)
			lbl.ZIndex = Z.Content + 2
			lbl.Parent = btn

			sortButtons[sortName] = { Button = btn, Label = lbl }
		end
	end

	local gridScroll = Instance.new("ScrollingFrame")
	gridScroll.BackgroundTransparency = 1
	gridScroll.BorderSizePixel = 0
	gridScroll.Position = UDim2.fromOffset(0, headerH)
	gridScroll.Size = UDim2.new(1, 0, 1, -headerH)
	gridScroll.ScrollingDirection = Enum.ScrollingDirection.Y
	gridScroll.ScrollingEnabled = true
	gridScroll.Active = true
	gridScroll.ElasticBehavior = Enum.ElasticBehavior.Never
	gridScroll.VerticalScrollBarInset = Enum.ScrollBarInset.ScrollBar
	gridScroll.ScrollBarThickness = showNativeScrollbar and (opts.ScrollBarThickness or 4) or 0
	gridScroll.ScrollBarImageColor3 = NullUI.Theme.TextDim
	gridScroll.ScrollBarImageTransparency = 1
	gridScroll.AutomaticCanvasSize = Enum.AutomaticSize.None
	gridScroll.CanvasSize = UDim2.new(0, 0, 0, 0)
	gridScroll.ZIndex = Z.Content + 1
	gridScroll.Parent = content

	-- Reserve room for the visible scrollbar so cards never sit underneath it.
	local GRID_RIGHT_PAD = gridScroll.ScrollBarThickness > 0 and (gridScroll.ScrollBarThickness + 6) or 16
	local GRID_TOP_PAD = 8
	local GRID_BOTTOM_PAD = 8
	local gridPad = Instance.new("UIPadding")
	gridPad.PaddingTop = UDim.new(0, GRID_TOP_PAD)
	gridPad.PaddingRight = UDim.new(0, GRID_RIGHT_PAD)
	gridPad.Parent = gridScroll

	local MIN_CELL_W = opts.CardMinWidth or opts.CardWidth or 190
	local FIXED_COLUMNS = opts.Columns
	local MAX_COLUMNS = opts.MaxColumns
	local CELL_H = opts.CardHeight or 88
	local CELL_GAP = 8

	local gridLayout = Instance.new("UIGridLayout")
	gridLayout.CellPadding = UDim2.fromOffset(CELL_GAP, CELL_GAP)
	gridLayout.CellSize = UDim2.fromOffset(MIN_CELL_W, CELL_H)
	gridLayout.SortOrder = Enum.SortOrder.LayoutOrder
	gridLayout.Parent = gridScroll

	local function updateGridCanvas()
		gridScroll.CanvasSize = UDim2.new(
			0,
			0,
			0,
			math.max(0, (gridLayout.AbsoluteContentSize.Y / GetUIScale()) + GRID_TOP_PAD + GRID_BOTTOM_PAD)
		)
	end
	gridLayout:GetPropertyChangedSignal("AbsoluteContentSize"):Connect(updateGridCanvas)
	SafeDefer(updateGridCanvas)

	local SAFETY_MARGIN = 4
	local currentColumns = 1
	local function relayoutGridColumns()
		local availableW = (gridScroll.AbsoluteSize.X / GetUIScale()) - GRID_RIGHT_PAD - SAFETY_MARGIN
		if availableW <= 0 then
			return
		end
		local columns = FIXED_COLUMNS and math.max(1, FIXED_COLUMNS)
			or math.max(1, math.floor((availableW + CELL_GAP) / (MIN_CELL_W + CELL_GAP)))
		if not FIXED_COLUMNS and MAX_COLUMNS then
			columns = math.min(columns, math.max(1, MAX_COLUMNS))
		end
		local cellW = math.floor((availableW - (columns - 1) * CELL_GAP) / columns)
		currentColumns = columns
		gridLayout.CellSize = UDim2.fromOffset(math.max(1, cellW), CELL_H)
	end
	gridScroll:GetPropertyChangedSignal("AbsoluteSize"):Connect(relayoutGridColumns)
	SafeDefer(relayoutGridColumns)

	if not showNativeScrollbar then
		AddScrollbar(gridScroll)
		AddContentScrollThumb(gridScroll, gridLayout, outer, self._janitor)
	end

	local MAX_OUTER_H = opts.Height or 300
	local showingCards = false

	local function applyOuterHeight(target)
		Tween(outer, { Size = UDim2.new(1, 0, 0, target) }, 0.26, Enum.EasingStyle.Quint, Enum.EasingDirection.Out)
	end

	local EMPTY_STATE_H = 220
	local function resizeOuterEmpty()
		showingCards = false
		if opts.FixedHeight then
			applyOuterHeight(MAX_OUTER_H)
			return
		end
		applyOuterHeight(math.min(headerH + OUTER_V_PAD + EMPTY_STATE_H + OUTER_V_PAD, MAX_OUTER_H))
	end

	local function resizeOuterToGridContent()
		if not showingCards then
			return
		end
		if opts.FixedHeight then
			applyOuterHeight(MAX_OUTER_H)
			return
		end
		local contentH = gridLayout.AbsoluteContentSize.Y
		if contentH <= 0 then
			return
		end
		local target = math.min(headerH + OUTER_V_PAD + contentH + OUTER_V_PAD, MAX_OUTER_H)
		applyOuterHeight(target)
	end
	gridLayout:GetPropertyChangedSignal("AbsoluteContentSize"):Connect(resizeOuterToGridContent)

	local statusHolder = Instance.new("Frame")
	statusHolder.BackgroundTransparency = 1
	statusHolder.Position = UDim2.fromOffset(0, headerH)
	statusHolder.Size = UDim2.new(1, 0, 1, -headerH)
	statusHolder.Visible = false
	statusHolder.ZIndex = Z.Content + 2
	statusHolder.Parent = content

	local statusLayout = Instance.new("UIListLayout")
	statusLayout.FillDirection = Enum.FillDirection.Vertical
	statusLayout.HorizontalAlignment = Enum.HorizontalAlignment.Center
	statusLayout.VerticalAlignment = Enum.VerticalAlignment.Center
	statusLayout.Padding = UDim.new(0, 6)
	statusLayout.Parent = statusHolder

	local statusIcon = Instance.new("ImageLabel")
	statusIcon.BackgroundTransparency = 1
	statusIcon.ImageColor3 = NullUI.Theme.TextDim
	Role(statusIcon, "TextDim")
	statusIcon.Size = UDim2.fromOffset(24, 24)
	statusIcon.LayoutOrder = 1
	statusIcon.Visible = false
	statusIcon.ZIndex = Z.Content + 3
	statusIcon.Parent = statusHolder

	local statusLabel = Instance.new("TextLabel")
	statusLabel.BackgroundTransparency = 1
	statusLabel.FontFace = NullUI.Theme.FontRegular
	statusLabel.TextColor3 = NullUI.Theme.TextDim
	Role(statusLabel, "TextDim")
	statusLabel.TextSize = 12
	statusLabel.TextWrapped = true
	statusLabel.TextXAlignment = Enum.TextXAlignment.Center
	statusLabel.AutomaticSize = Enum.AutomaticSize.Y
	statusLabel.Size = UDim2.new(1, -20, 0, 16)
	statusLabel.LayoutOrder = 2
	statusLabel.ZIndex = Z.Content + 3
	statusLabel.Parent = statusHolder

	local STATUS_ICONS = { loading = "loader-circle", empty = "frown", error = "triangle-alert" }

	local function openCardMenu(anchor, actions)
		if type(actions) ~= "table" or #actions == 0 then
			return
		end

		local popup, backdrop
		local function closeMenu()
			RegisterPopupClose(closeMenu)
			if backdrop then
				backdrop:Destroy()
				backdrop = nil
			end
			if popup then
				popup:Destroy()
				popup = nil
			end
		end

		RegisterPopupOpen(closeMenu)
		backdrop = MakePopupBackdrop(closeMenu)

		local rowH, gap, pad = 32, 2, 8
		local popupW = 190
		local popupH = pad * 2 + #actions * rowH + math.max(0, #actions - 1) * gap
		local scale = GetUIScale()
		local view = ViewportSize()
		local anchorPos, anchorSize = anchor.AbsolutePosition, anchor.AbsoluteSize
		local px = (anchorPos.X + anchorSize.X) / scale - popupW
		local py = (anchorPos.Y + anchorSize.Y) / scale + 5
		px = SafeClamp(px, 8, view.X / scale - popupW - 8)
		py = SafeClamp(py, 8, view.Y / scale - popupH - 8)

		popup = Instance.new("CanvasGroup")
		popup.Name = "CardActionsPopup"
		popup.Active = true
		popup.BackgroundColor3 = NullUI.Theme.Background
		popup.BackgroundTransparency = 0.04
		popup.BorderSizePixel = 0
		popup.Position = UDim2.fromOffset(math.round(px), math.round(py))
		popup.Size = UDim2.fromOffset(popupW, popupH)
		popup.ZIndex = Z.Popup
		popup.Parent = NullUI._Root
		Corner(popup, 10)
		Stroke(popup, Color3.new(1, 1, 1), 1, 0.9)
		GlassLayer(popup, 10, 0.985)

		local actionsHolder = Instance.new("Frame")
		actionsHolder.Name = "Actions"
		actionsHolder.BackgroundTransparency = 1
		actionsHolder.Size = UDim2.fromScale(1, 1)
		actionsHolder.ZIndex = Z.Popup + 1
		actionsHolder.Parent = popup

		local popupPad = Instance.new("UIPadding")
		popupPad.PaddingTop = UDim.new(0, pad)
		popupPad.PaddingBottom = UDim.new(0, pad)
		popupPad.PaddingLeft = UDim.new(0, pad)
		popupPad.PaddingRight = UDim.new(0, pad)
		popupPad.Parent = actionsHolder

		local popupLayout = Instance.new("UIListLayout")
		popupLayout.Padding = UDim.new(0, gap)
		popupLayout.SortOrder = Enum.SortOrder.LayoutOrder
		popupLayout.Parent = actionsHolder

		for i, action in ipairs(actions) do
			local button = Instance.new("TextButton")
			button.Name = "Action" .. i
			button.Text = ""
			button.AutoButtonColor = false
			button.BackgroundColor3 = Color3.new(1, 1, 1)
			button.BackgroundTransparency = 1
			button.BorderSizePixel = 0
			button.Size = UDim2.new(1, 0, 0, rowH)
			button.LayoutOrder = i
			button.ZIndex = Z.Popup + 1
			button.Parent = actionsHolder
			Corner(button, 7)

			local icon = Instance.new("ImageLabel")
			icon.BackgroundTransparency = 1
			icon.Image = ResolveIcon(action.Icon or "circle")
			icon.ImageColor3 = action.Danger and NullUI.Theme.Danger or NullUI.Theme.TextDim
			icon.Size = UDim2.fromOffset(14, 14)
			icon.AnchorPoint = Vector2.new(0, 0.5)
			icon.Position = UDim2.new(0, 9, 0.5, 0)
			icon.ZIndex = Z.Popup + 2
			icon.Parent = button

			local label = Instance.new("TextLabel")
			label.BackgroundTransparency = 1
			label.FontFace = NullUI.Theme.FontRegular
			label.Text = tostring(action.Text or "Action")
			label.TextColor3 = action.Danger and NullUI.Theme.Danger or NullUI.Theme.Text
			label.TextSize = 12
			label.TextXAlignment = Enum.TextXAlignment.Left
			label.Position = UDim2.fromOffset(31, 0)
			label.Size = UDim2.new(1, -39, 1, 0)
			label.ZIndex = Z.Popup + 2
			label.Parent = button

			button.MouseEnter:Connect(function()
				Tween(button, { BackgroundTransparency = 0.9 }, 0.12)
			end)
			button.MouseLeave:Connect(function()
				Tween(button, { BackgroundTransparency = 1 }, 0.12)
			end)
			button.MouseButton1Click:Connect(function()
				closeMenu()
				if action.Callback then
					SafeSpawn(action.Callback)
				end
			end)
		end
	end

	local function buildCard(item, animDelay)
		local cell = Instance.new("Frame")
		cell.Name = "GridCard"
		-- Hosts that translate UI labels should leave player-written card text alone.
		if item.UserContent then
			cell:SetAttribute("UserContent", true)
		end
		cell.BackgroundColor3 = Color3.new(1, 1, 1)
		cell.BackgroundTransparency = 1
		cell.BorderSizePixel = 0
		cell.ClipsDescendants = true
		cell.ZIndex = Z.Content + 2
		cell.Parent = gridScroll
		Corner(cell, NullUI.Theme.CornerRadiusSm)
		local cellStroke = Stroke(cell, Color3.new(1, 1, 1), 1, 1)

		local cellScale = Instance.new("UIScale")
		cellScale.Scale = 0.9
		cellScale.Parent = cell

		SafeDelay(animDelay or 0, function()
			if not cell.Parent then
				return
			end
			Tween(cell, { BackgroundTransparency = 0.94 }, 0.26, Enum.EasingStyle.Quint, Enum.EasingDirection.Out)
			Tween(cellStroke, { Transparency = 0.9 }, 0.26, Enum.EasingStyle.Quint, Enum.EasingDirection.Out)
			Tween(cellScale, { Scale = 1 }, 0.26, Enum.EasingStyle.Back, Enum.EasingDirection.Out)
		end)

		local cellPad = Instance.new("UIPadding")
		cellPad.PaddingTop = UDim.new(0, cardPadding)
		cellPad.PaddingBottom = UDim.new(0, cardPadding)
		cellPad.PaddingLeft = UDim.new(0, cardPadding)
		cellPad.PaddingRight = UDim.new(0, cardPadding)
		cellPad.Parent = cell

		local textX = 0
		if item.Icon then
			local ICON_BOX = 24
			local iconHolder = Instance.new("Frame")
			iconHolder.BackgroundColor3 = Color3.new(1, 1, 1)
			iconHolder.BackgroundTransparency = 0.9
			iconHolder.BorderSizePixel = 0
			iconHolder.Size = UDim2.fromOffset(ICON_BOX, ICON_BOX)
			iconHolder.ZIndex = Z.Content + 3
			iconHolder.Parent = cell
			Corner(iconHolder, 7)

			local iconImg = Instance.new("ImageLabel")
			iconImg.BackgroundTransparency = 1
			iconImg.Image = ResolveIcon(item.Icon)
			iconImg.ImageColor3 = NullUI.Theme.Accent
			iconImg.Size = UDim2.fromOffset(13, 13)
			iconImg.AnchorPoint = Vector2.new(0.5, 0.5)
			iconImg.Position = UDim2.fromScale(0.5, 0.5)
			iconImg.ZIndex = Z.Content + 4
			iconImg.Parent = iconHolder

			textX = ICON_BOX + 8
		end

		local hasPrimaryAction = item.Callback ~= nil
		local hasSecondaryAction = item.SecondaryCallback ~= nil
		local hasMenuAction = item.Menu and #item.Menu > 0
		local trailingReserve = (hasPrimaryAction and 26 or 0)
			+ (hasSecondaryAction and 30 or 0)
			+ (hasMenuAction and 30 or 0)
		if hasPrimaryAction then
			local actionBadge = Instance.new("Frame")
			actionBadge.Name = "LoadBadge"
			actionBadge.BackgroundColor3 = NullUI.Theme.Accent
			actionBadge.BackgroundTransparency = 0.8
			actionBadge.BorderSizePixel = 0
			actionBadge.AnchorPoint = Vector2.new(1, 0)
			actionBadge.Position = UDim2.new(1, 0, 0, 0)
			actionBadge.Size = UDim2.fromOffset(22, 22)
			actionBadge.ZIndex = Z.Content + 6
			actionBadge.Parent = cell
			Corner(actionBadge, 7)

			local actionIcon = Instance.new("ImageLabel")
			actionIcon.BackgroundTransparency = 1
			actionIcon.Image = ResolveIcon(item.ActionIcon or "download")
			actionIcon.ImageColor3 = NullUI.Theme.Accent
			actionIcon.Size = UDim2.fromOffset(12, 12)
			actionIcon.AnchorPoint = Vector2.new(0.5, 0.5)
			actionIcon.Position = UDim2.fromScale(0.5, 0.5)
			actionIcon.ZIndex = Z.Content + 7
			actionIcon.Parent = actionBadge

			local actionClick = Instance.new("TextButton")
			actionClick.Text = ""
			actionClick.AutoButtonColor = false
			actionClick.BackgroundTransparency = 1
			actionClick.Size = UDim2.fromScale(1, 1)
			actionClick.ZIndex = Z.Content + 8
			actionClick.Parent = actionBadge
			actionClick.MouseButton1Click:Connect(function()
				item.Callback()
			end)
		end

		if hasSecondaryAction then
			local secondaryBadge = Instance.new("Frame")
			secondaryBadge.Name = "SecondaryActionBadge"
			secondaryBadge.BackgroundColor3 = item.SecondaryDanger and Color3.fromRGB(225, 76, 88)
				or NullUI.Theme.Accent
			secondaryBadge.BackgroundTransparency = item.SecondaryDanger and 0.82 or 0.8
			secondaryBadge.BorderSizePixel = 0
			secondaryBadge.AnchorPoint = Vector2.new(1, 0)
			secondaryBadge.Position = UDim2.new(1, hasPrimaryAction and -30 or 0, 0, 0)
			secondaryBadge.Size = UDim2.fromOffset(22, 22)
			secondaryBadge.ZIndex = Z.Content + 6
			secondaryBadge.Parent = cell
			Corner(secondaryBadge, 7)

			local secondaryIcon = Instance.new("ImageLabel")
			secondaryIcon.BackgroundTransparency = 1
			secondaryIcon.Image = ResolveIcon(item.SecondaryIcon or "trash-2")
			secondaryIcon.ImageColor3 = item.SecondaryDanger and Color3.fromRGB(255, 125, 135) or NullUI.Theme.Accent
			secondaryIcon.Size = UDim2.fromOffset(12, 12)
			secondaryIcon.AnchorPoint = Vector2.new(0.5, 0.5)
			secondaryIcon.Position = UDim2.fromScale(0.5, 0.5)
			secondaryIcon.ZIndex = Z.Content + 7
			secondaryIcon.Parent = secondaryBadge

			local secondaryClick = Instance.new("TextButton")
			secondaryClick.Text = ""
			secondaryClick.AutoButtonColor = false
			secondaryClick.BackgroundTransparency = 1
			secondaryClick.Size = UDim2.fromScale(1, 1)
			secondaryClick.ZIndex = Z.Content + 8
			secondaryClick.Parent = secondaryBadge
			secondaryClick.MouseButton1Click:Connect(function()
				item.SecondaryCallback()
			end)
		end

		if hasMenuAction then
			local menuBadge = Instance.new("Frame")
			menuBadge.Name = "MenuBadge"
			menuBadge.BackgroundColor3 = NullUI.Theme.Accent
			menuBadge.BackgroundTransparency = 0.8
			menuBadge.BorderSizePixel = 0
			menuBadge.AnchorPoint = Vector2.new(1, 0)
			menuBadge.Position =
				UDim2.new(1, -((hasPrimaryAction and 30 or 0) + (hasSecondaryAction and 30 or 0)), 0, 0)
			menuBadge.Size = UDim2.fromOffset(22, 22)
			menuBadge.ZIndex = Z.Content + 6
			menuBadge.Parent = cell
			Corner(menuBadge, 7)

			local menuIcon = Instance.new("ImageLabel")
			menuIcon.BackgroundTransparency = 1
			menuIcon.Image = ResolveIcon("Lucide:settings")
			menuIcon.ImageColor3 = NullUI.Theme.Accent
			menuIcon.Size = UDim2.fromOffset(12, 12)
			menuIcon.AnchorPoint = Vector2.new(0.5, 0.5)
			menuIcon.Position = UDim2.fromScale(0.5, 0.5)
			menuIcon.ZIndex = Z.Content + 7
			menuIcon.Parent = menuBadge

			local menuClick = Instance.new("TextButton")
			menuClick.Text = ""
			menuClick.AutoButtonColor = false
			menuClick.BackgroundTransparency = 1
			menuClick.Size = UDim2.fromScale(1, 1)
			menuClick.ZIndex = Z.Content + 8
			menuClick.Parent = menuBadge
			menuClick.MouseButton1Click:Connect(function()
				openCardMenu(menuBadge, item.Menu)
			end)
		end

		local cursorY = 0

		local titleLbl = Instance.new("TextLabel")
		titleLbl.Name = "Title"
		titleLbl.BackgroundTransparency = 1
		titleLbl.FontFace = NullUI.Theme.Font
		titleLbl.Text = item.Title or "Untitled"
		titleLbl.TextColor3 = NullUI.Theme.Text
		Role(titleLbl, "Text")
		titleLbl.TextSize = 13
		titleLbl.TextXAlignment = Enum.TextXAlignment.Left
		titleLbl.TextYAlignment = Enum.TextYAlignment.Center
		titleLbl.TextTruncate = Enum.TextTruncate.AtEnd
		titleLbl.Position = UDim2.fromOffset(textX, item.Icon and 4 or cursorY)
		titleLbl.Size = UDim2.new(1, -(textX + trailingReserve), 0, item.Icon and 24 or 16)
		titleLbl.ZIndex = Z.Content + 3
		titleLbl.Parent = cell
		cursorY = math.max(item.Icon and (24 + 6) or 0, cursorY + 16 + 3)

		if item.Description and item.Description ~= "" then
			local descLbl = Instance.new("TextLabel")
			descLbl.Name = "Description"
			descLbl.BackgroundTransparency = 1
			descLbl.FontFace = NullUI.Theme.FontRegular
			descLbl.Text = item.Description
			descLbl.TextColor3 = NullUI.Theme.TextDim
			Role(descLbl, "TextDim")
			descLbl.TextSize = 11
			descLbl.TextWrapped = true
			descLbl.TextTruncate = Enum.TextTruncate.None
			descLbl.TextXAlignment = Enum.TextXAlignment.Left
			descLbl.TextYAlignment = Enum.TextYAlignment.Top
			descLbl.Position = UDim2.fromOffset(0, cursorY)
			descLbl.Size = UDim2.new(1, -trailingReserve, 0, descriptionHeight)
			descLbl.ZIndex = Z.Content + 3
			descLbl.Parent = cell
			cursorY = cursorY + descriptionHeight + 3
		end

		if item.Byline and item.Byline ~= "" then
			local bylineLbl = Instance.new("TextLabel")
			bylineLbl.Name = "Byline"
			bylineLbl.BackgroundTransparency = 1
			bylineLbl.FontFace = NullUI.Theme.FontRegular
			bylineLbl.Text = item.Byline
			bylineLbl.TextColor3 = NullUI.Theme.TextDim
			Role(bylineLbl, "TextDim")
			bylineLbl.TextTransparency = 0.25
			bylineLbl.TextSize = 10
			bylineLbl.TextXAlignment = Enum.TextXAlignment.Left
			bylineLbl.TextTruncate = Enum.TextTruncate.AtEnd
			bylineLbl.Position = UDim2.fromOffset(0, cursorY)
			bylineLbl.Size = UDim2.new(1, -trailingReserve, 0, 12)
			bylineLbl.ZIndex = Z.Content + 3
			bylineLbl.Parent = cell
		end

		if item.Stats and #item.Stats > 0 then
			local statsRow = Instance.new("Frame")
			statsRow.BackgroundTransparency = 1
			statsRow.AnchorPoint = Vector2.new(0, 1)
			statsRow.Position = UDim2.new(0, 0, 1, 0)
			statsRow.Size = UDim2.new(1, 0, 0, 16)
			statsRow.ZIndex = Z.Content + 3
			statsRow.Parent = cell

			local statsLayout = Instance.new("UIListLayout")
			statsLayout.FillDirection = Enum.FillDirection.Horizontal
			statsLayout.Padding = UDim.new(0, 10)
			statsLayout.SortOrder = Enum.SortOrder.LayoutOrder
			statsLayout.Parent = statsRow

			for i, stat in ipairs(item.Stats) do
				local statFrame = Instance.new(stat.Callback and "TextButton" or "Frame")
				statFrame.BackgroundTransparency = 1
				statFrame.AutomaticSize = Enum.AutomaticSize.X
				statFrame.Size = UDim2.fromOffset(0, 14)
				statFrame.LayoutOrder = i
				statFrame.ZIndex = Z.Content + 3
				statFrame.Parent = statsRow
				if stat.Callback then
					statFrame.Text = ""
					statFrame.AutoButtonColor = false
				end

				local statLayout = Instance.new("UIListLayout")
				statLayout.FillDirection = Enum.FillDirection.Horizontal
				statLayout.VerticalAlignment = Enum.VerticalAlignment.Center
				statLayout.Padding = UDim.new(0, 3)
				statLayout.Parent = statFrame

				local statIcon = Instance.new("ImageLabel")
				statIcon.BackgroundTransparency = 1
				statIcon.Image = ResolveIcon(stat.Icon or "circle")
				statIcon.ImageColor3 = NullUI.Theme.TextDim
				Role(statIcon, "TextDim")
				statIcon.Size = UDim2.fromOffset(11, 11)
				statIcon.LayoutOrder = 1
				statIcon.ZIndex = Z.Content + 4
				statIcon.Parent = statFrame

				local statLbl = Instance.new("TextLabel")
				statLbl.BackgroundTransparency = 1
				statLbl.FontFace = NullUI.Theme.FontRegular
				statLbl.Text = tostring(stat.Text or "")
				statLbl.TextColor3 = NullUI.Theme.TextDim
				Role(statLbl, "TextDim")
				statLbl.TextSize = 10
				statLbl.AutomaticSize = Enum.AutomaticSize.X
				statLbl.Size = UDim2.fromOffset(0, 12)
				statLbl.LayoutOrder = 2
				statLbl.ZIndex = Z.Content + 4
				statLbl.Parent = statFrame

				if stat.Callback then
					statFrame.MouseEnter:Connect(function()
						Tween(statIcon, { ImageColor3 = NullUI.Theme.Accent }, 0.12)
						Tween(statLbl, { TextColor3 = NullUI.Theme.Accent }, 0.12)
					end)
					statFrame.MouseLeave:Connect(function()
						Tween(statIcon, { ImageColor3 = NullUI.Theme.TextDim }, 0.12)
						Tween(statLbl, { TextColor3 = NullUI.Theme.TextDim }, 0.12)
					end)
					statFrame.MouseButton1Click:Connect(function()
						SafeSpawn(stat.Callback)
					end)
				end
			end
		end

		if item.Callback then
			local hasInteractiveStat = false
			if item.Stats then
				for _, stat in ipairs(item.Stats) do
					if stat.Callback then
						hasInteractiveStat = true
					end
				end
			end

			local click = Instance.new("TextButton")
			click.Text = ""
			click.AutoButtonColor = false
			click.BackgroundTransparency = 1
			click.Size = hasInteractiveStat and UDim2.new(1, 0, 1, -20) or UDim2.fromScale(1, 1)
			click.ZIndex = Z.Content + 5
			click.Parent = cell

			click.MouseEnter:Connect(function()
				Tween(cell, { BackgroundTransparency = 0.88 }, 0.12)
				Tween(cellStroke, { Transparency = 0.8 }, 0.12)
			end)
			click.MouseLeave:Connect(function()
				Tween(cell, { BackgroundTransparency = 0.94 }, 0.12)
				Tween(cellStroke, { Transparency = 0.9 }, 0.12)
			end)
			click.MouseButton1Click:Connect(function()
				SafeSpawn(item.Callback)
			end)
		end

		return cell
	end

	local currentQuery = ""
	local loadToken = 0

	local function clearGrid()
		for _, child in ipairs(gridScroll:GetChildren()) do
			if child.Name == "GridCard" then
				child:Destroy()
			end
		end
	end

	local function setStatus(msg, kind)
		local visible = msg ~= nil and msg ~= ""
		statusLabel.Text = msg or ""
		statusHolder.Visible = visible
		local iconName = visible and STATUS_ICONS[kind]
		statusIcon.Visible = iconName ~= nil
		if iconName then
			statusIcon.Image = ResolveIcon(iconName)
		end
	end

	local function computeCellHeight(items)
		local hasIcon, hasDesc, hasByline, hasStats = false, false, false, false
		for _, item in ipairs(items) do
			if item.Icon then
				hasIcon = true
			end
			if item.Description and item.Description ~= "" then
				hasDesc = true
			end
			if item.Byline and item.Byline ~= "" then
				hasByline = true
			end
			if item.Stats and #item.Stats > 0 then
				hasStats = true
			end
		end
		local h = 20
		h = h + (hasIcon and 24 or 16) + 3
		if hasDesc then
			h = h + descriptionHeight + 3
		end
		if hasByline then
			h = h + 12
		end
		if hasStats then
			h = h + 16 + 4
		end
		return h
	end

	local function refresh()
		if not opts.Fetch then
			return
		end
		loadToken = loadToken + 1
		local myToken = loadToken
		clearGrid()
		setStatus(opts.LoadingText or "Loading...", "loading")
		resizeOuterEmpty()
		SafeSpawn(function()
			local ok, items, fetchErr = pcall(opts.Fetch, {
				Query = currentQuery,
				Sort = currentSort,
				PageSize = pageSize,
			})
			if myToken ~= loadToken then
				return
			end
			if not ok then
				setStatus(opts.ErrorText or tostring(items), "error")
				resizeOuterEmpty()
				return
			end
			if fetchErr then
				setStatus(opts.ErrorText or tostring(fetchErr), "error")
				resizeOuterEmpty()
				return
			end
			items = items or {}
			if #items == 0 then
				setStatus(opts.EmptyText or "Nothing here yet.", "empty")
				resizeOuterEmpty()
				return
			end
			setStatus(nil)
			if opts.AutoCardHeight ~= false then
				CELL_H = math.max(computeCellHeight(items), opts.MinCardHeight or 0)
				gridLayout.CellSize = UDim2.new(gridLayout.CellSize.X.Scale, gridLayout.CellSize.X.Offset, 0, CELL_H)
			end
			showingCards = true
			for i, item in ipairs(items) do
				buildCard(item, math.min(i - 1, 8) * 0.035)
			end

			SafeSpawn(function()
				RunService.Heartbeat:Wait()
				RunService.Heartbeat:Wait()
				if myToken == loadToken then
					resizeOuterToGridContent()
				end
			end)
		end)
	end

	if searchBox then
		local debounceToken = 0
		searchBox:GetPropertyChangedSignal("Text"):Connect(function()
			currentQuery = searchBox.Text
			debounceToken = debounceToken + 1
			local myDebounce = debounceToken
			SafeDelay(0.35, function()
				if myDebounce == debounceToken then
					refresh()
				end
			end)
		end)
	end

	for sortName, entry in pairs(sortButtons) do
		entry.Button.MouseButton1Click:Connect(function()
			if currentSort == sortName then
				return
			end
			currentSort = sortName
			for otherName, otherEntry in pairs(sortButtons) do
				local active = otherName == currentSort
				Tween(otherEntry.Button, { BackgroundTransparency = active and 0.85 or 1 }, 0.12)
				Tween(otherEntry.Label, { TextColor3 = active and NullUI.Theme.Text or NullUI.Theme.TextDim }, 0.12)
			end
			refresh()
		end)
	end

	if opts.AutoLoad ~= false and opts.Fetch then
		SafeDefer(refresh)
	end

	return {
		Instance = outer,
		Refresh = refresh,
		SetQuery = function(_, q)
			currentQuery = q or ""
			if searchBox then
				searchBox.Text = currentQuery
			end
			refresh()
		end,
		SetSort = function(_, s)
			currentSort = s
			refresh()
		end,
		Destroy = function()
			outer:Destroy()
		end,
	}
end

function NullUI:GetConfig()
	local data = {}
	for flag, api in pairs(NullUI.Flags) do
		if api.Get then
			local ok, value = pcall(api.Get)
			if ok then
				data[flag] = Serialize(value)
			end
		end
	end
	return data
end

function NullUI:SetConfig(data, silent)
	if type(data) ~= "table" then
		return false
	end
	for flag, raw in pairs(data) do
		local api = NullUI.Flags[flag]
		if api and api.Set then
			pcall(api.Set, api, Deserialize(raw), silent ~= false)
		end
	end
	return true
end

function NullUI:ListUIElements()
	local out = {}
	for flag, api in pairs(NullUI.Flags) do
		local ok, value = pcall(api.Get)
		table.insert(out, {
			Flag = flag,
			Kind = api.Kind,
			Label = api.Label,
			Value = ok and value or nil,
		})
	end
	table.sort(out, function(a, b)
		return a.Flag < b.Flag
	end)
	return out
end

function NullUI:SetUIElementValue(flag, value, silent)
	local api = NullUI.Flags[flag]
	if not api or not api.Set then
		return false, "Unknown UI element: " .. tostring(flag)
	end
	local ok, err = pcall(api.Set, api, value, silent ~= false)
	if not ok then
		return false, tostring(err)
	end
	return true
end

local CONFIGS_FOLDER = "NullUI/Configs"

local function EnsureConfigsFolder()
	if not (fn_isfolder and fn_makefolder) then
		return false
	end
	local ok = pcall(function()
		if not fn_isfolder("NullUI") then
			fn_makefolder("NullUI")
		end
		if not fn_isfolder(CONFIGS_FOLDER) then
			fn_makefolder(CONFIGS_FOLDER)
		end
	end)
	return ok
end

local function SafeConfigName(name)
	name = tostring(name or "config"):gsub("[^%w_%- ]", "_"):gsub("^%s+", ""):gsub("%s+$", "")
	if name == "" then
		name = "config"
	end
	return name
end

local function ConfigPath(name)
	return CONFIGS_FOLDER .. "/" .. SafeConfigName(name) .. ".json"
end

local function LegacyConfigPath(name)
	return "NullUI/" .. SafeConfigName(name) .. ".json"
end

local function BuildConfigEnvelope(name, data, meta)
	meta = meta or {}
	return {
		Schema = 1,
		Name = name,
		Description = meta.Description or "",
		Tags = meta.Tags or {},
		CreatedAt = meta.CreatedAt or os.time(),
		Data = data,
	}
end

local function ReadConfigFile(path)
	if not (fn_isfile and fn_readfile) then
		return nil, "readfile unavailable"
	end
	local existsOk, exists = pcall(fn_isfile, path)
	if not existsOk or not exists then
		return nil, "config does not exist"
	end
	local ok, raw = pcall(fn_readfile, path)
	if not ok then
		return nil, raw
	end
	local decodeOk, decoded = pcall(function()
		return HttpService:JSONDecode(raw)
	end)
	if not decodeOk then
		return nil, "failed to decode config"
	end
	if type(decoded) ~= "table" then
		return nil, "malformed config"
	end

	if decoded.Data == nil then
		return BuildConfigEnvelope(nil, decoded, {}), nil
	end
	return decoded, nil
end

function NullUI:SaveConfig(name, opts)
	if not fn_writefile then
		return false, "writefile unavailable"
	end
	opts = opts or {}
	EnsureConfigsFolder()
	name = name or "config"
	local envelope = BuildConfigEnvelope(name, NullUI:GetConfig(), opts)
	local ok, err = pcall(function()
		fn_writefile(ConfigPath(name), HttpService:JSONEncode(envelope))
	end)
	return ok, err
end

function NullUI:LoadConfig(name, silent)
	name = name or "config"
	local envelope, err = ReadConfigFile(ConfigPath(name))
	if not envelope then
		envelope, err = ReadConfigFile(LegacyConfigPath(name))
	end
	if not envelope then
		return false, err
	end
	return NullUI:SetConfig(envelope.Data, silent)
end

function NullUI:GetConfigMeta(name)
	local envelope, err = ReadConfigFile(ConfigPath(name))
	if not envelope then
		return nil, err
	end
	return {
		Name = envelope.Name or name,
		Description = envelope.Description or "",
		Tags = envelope.Tags or {},
		CreatedAt = envelope.CreatedAt,
	}
end

function NullUI:GetSavedConfig(name)
	local envelope, err = ReadConfigFile(ConfigPath(name))
	if not envelope then
		return nil, err
	end
	return envelope, nil
end

function NullUI:ListConfigs()
	if not fn_listfiles then
		return {}, "listfiles unavailable"
	end
	EnsureConfigsFolder()
	local ok, files = pcall(fn_listfiles, CONFIGS_FOLDER)
	if not ok or type(files) ~= "table" then
		return {}, "failed to list configs"
	end

	local out = {}
	for _, path in ipairs(files) do
		if tostring(path):match("%.json$") then
			local envelope = ReadConfigFile(path)
			if envelope then
				local fileName = tostring(path):match("([^/\\]+)%.json$") or envelope.Name
				table.insert(out, {
					Name = envelope.Name or fileName,
					FileName = fileName,
					Description = envelope.Description or "",
					Tags = envelope.Tags or {},
					CreatedAt = envelope.CreatedAt or 0,
				})
			end
		end
	end

	table.sort(out, function(a, b)
		return (a.CreatedAt or 0) > (b.CreatedAt or 0)
	end)
	return out, nil
end

function NullUI:DeleteConfig(name)
	if not (fn_isfile and fn_delfile) then
		return false, "delfile unavailable"
	end
	local path = ConfigPath(name)
	local ok, exists = pcall(fn_isfile, path)
	if not ok or not exists then
		return false, "config does not exist"
	end
	local delOk, err = pcall(fn_delfile, path)
	return delOk, err
end

function NullUI:RenameConfig(oldName, newName)
	local envelope, err = ReadConfigFile(ConfigPath(oldName))
	if not envelope then
		return false, err
	end
	envelope.Name = newName
	local ok, writeErr = pcall(function()
		EnsureConfigsFolder()
		fn_writefile(ConfigPath(newName), HttpService:JSONEncode(envelope))
	end)
	if not ok then
		return false, writeErr
	end
	if ConfigPath(oldName) ~= ConfigPath(newName) then
		pcall(fn_delfile, ConfigPath(oldName))
	end
	return true
end

function NullUI:CreateSnapshot()
	return { Data = NullUI:GetConfig(), CreatedAt = os.time() }
end

function NullUI:RestoreSnapshot(snapshot, silent)
	if type(snapshot) ~= "table" or type(snapshot.Data) ~= "table" then
		return false, "invalid snapshot"
	end
	return NullUI:SetConfig(snapshot.Data, silent)
end

local CLOUD_IDENTITY_PATH = "NullUI/cloud_identity.json"

local function LoadCloudIdentity()
	if fn_isfile and fn_readfile then
		local existsOk, exists = pcall(fn_isfile, CLOUD_IDENTITY_PATH)
		if existsOk and exists then
			local ok, raw = pcall(fn_readfile, CLOUD_IDENTITY_PATH)
			if ok then
				local decodeOk, decoded = pcall(function()
					return HttpService:JSONDecode(raw)
				end)
				if decodeOk and type(decoded) == "table" and decoded.Id then
					decoded.Tokens = decoded.Tokens or {}
					return decoded
				end
			end
		end
	end
	return nil
end

local function SaveCloudIdentity(identity)
	if not fn_writefile then
		return
	end
	EnsureAssetsFolder()
	pcall(fn_writefile, CLOUD_IDENTITY_PATH, HttpService:JSONEncode(identity))
end

local function GetOrCreateCloudIdentity()
	local identity = LoadCloudIdentity()
	if identity then
		return identity
	end
	identity = { Id = HttpService:GenerateGUID(false), Tokens = {} }
	SaveCloudIdentity(identity)
	return identity
end

local CLOUD_PUBLISH_COOLDOWN = 15
local LastCloudPublishAt = 0

function NullUI:CloudService(opts)
	opts = opts or {}
	local baseUrl = opts.BaseUrl
	if type(baseUrl) ~= "string" or baseUrl:gsub("%s", "") == "" then
		return nil, "No cloud BaseUrl configured -- point CloudService's BaseUrl at your own backend."
	end
	if not baseUrl:match("^https?://") then
		return nil, "Cloud BaseUrl must start with http:// or https://"
	end
	baseUrl = baseUrl:gsub("/+$", "")
	local scriptId = opts.Script or "default"
	local identity = GetOrCreateCloudIdentity()
	local httpRequest = (syn and syn.request) or http_request or request

	local function apiRequest(method, path, body, extraHeaders)
		if not httpRequest then
			return nil, "Your executor doesn't support HTTP requests."
		end
		if not baseUrl or baseUrl == "" then
			return nil, "No cloud BaseUrl configured -- point CloudService's BaseUrl at your own backend."
		end

		local headers = {
			["Content-Type"] = "application/json",
			["X-NullUI-Identity"] = identity.Id,
			["X-NullUI-Script"] = scriptId,
		}
		if extraHeaders then
			for k, v in pairs(extraHeaders) do
				headers[k] = v
			end
		end

		local ok, res = pcall(httpRequest, {
			Url = baseUrl .. path,
			Method = method,
			Headers = headers,
			Body = body and HttpService:JSONEncode(body) or nil,
		})
		if not ok then
			return nil, tostring(res)
		end

		if res.StatusCode and (res.StatusCode < 200 or res.StatusCode >= 300) then
			local message = res.Body
			local decodeOk, decoded = pcall(function()
				return HttpService:JSONDecode(res.Body)
			end)
			if decodeOk and type(decoded) == "table" and decoded.error then
				message = tostring(decoded.error)
			end
			return nil, "HTTP " .. tostring(res.StatusCode) .. ": " .. tostring(message)
		end

		if res.Body == nil or res.Body == "" then
			return {}, nil
		end
		local decodeOk, decoded = pcall(function()
			return HttpService:JSONDecode(res.Body)
		end)
		if not decodeOk then
			return nil, "Failed to decode response."
		end
		return decoded, nil
	end

	local api = { Identity = identity.Id }

	function api:List(state)
		state = state or {}
		local query = "?sort=" .. HttpService:UrlEncode(state.Sort or "top")
		if state.Query and state.Query ~= "" then
			query = query .. "&q=" .. HttpService:UrlEncode(state.Query)
		end
		if state.Cursor then
			query = query .. "&cursor=" .. HttpService:UrlEncode(tostring(state.Cursor))
		end
		query = query .. "&limit=" .. tostring(state.PageSize or 20)

		local decoded, err = apiRequest("GET", "/configs" .. query)
		if not decoded then
			return nil, err
		end
		return decoded.Items or {}, decoded.NextCursor
	end

	function api:ListMine()
		local decoded, err = apiRequest("GET", "/configs/mine")
		if not decoded then
			return nil, err
		end
		return decoded.Items or {}
	end

	function api:GetByShareCode(shareCode)
		return apiRequest("GET", "/configs/code/" .. HttpService:UrlEncode(tostring(shareCode)))
	end

	function api:Publish(meta, data)
		meta = meta or {}
		local now = os.clock()
		if now - LastCloudPublishAt < CLOUD_PUBLISH_COOLDOWN then
			return nil,
				string.format(
					"Please wait %ds before publishing again.",
					math.ceil(CLOUD_PUBLISH_COOLDOWN - (now - LastCloudPublishAt))
				)
		end

		local cleanName, nameBlocked = NullUI:SanitizeText(meta.Name, { MaxLength = 60 })
		if nameBlocked or cleanName == "" then
			return nil, "Name was empty or blocked by the content filter."
		end
		local cleanDesc, descBlocked = NullUI:SanitizeText(meta.Description or "", { MaxLength = 280 })
		if descBlocked then
			return nil, "Description was blocked by the content filter."
		end

		local cleanTags = {}
		for _, tag in ipairs(meta.Tags or {}) do
			local cleanTag = NullUI:SanitizeText(tag, { MaxLength = 24 })
			if cleanTag ~= "" then
				table.insert(cleanTags, cleanTag)
			end
			if #cleanTags >= 8 then
				break
			end
		end

		LastCloudPublishAt = now

		local decoded, err = apiRequest("POST", "/configs", {
			Name = cleanName,
			Description = cleanDesc,
			Tags = cleanTags,
			Data = data or NullUI:GetConfig(),
		})
		if not decoded then
			return nil, err
		end

		if decoded.Id and decoded.OwnerToken then
			identity.Tokens[decoded.Id] = decoded.OwnerToken
			SaveCloudIdentity(identity)
		end
		return decoded
	end

	function api:Delete(id)
		local token = identity.Tokens[id]
		if not token then
			return false, "You don't have publish rights for this config on this device."
		end
		local decoded, err = apiRequest("DELETE", "/configs/" .. id, nil, {
			["X-NullUI-Owner-Token"] = token,
		})
		if not decoded then
			return false, err
		end
		identity.Tokens[id] = nil
		SaveCloudIdentity(identity)
		return true
	end

	function api:Like(id)
		local decoded, err = apiRequest("POST", "/configs/" .. id .. "/like")
		if not decoded then
			return false, err
		end
		return true
	end

	function api:Download(id)
		return apiRequest("POST", "/configs/" .. id .. "/download")
	end

	-- `extra` may carry PlayerName, GameName and ReplyToId; the relay ignores fields it doesn't know.
	function api:SendChatMessage(userId, text, extra)
		local body = { UserId = userId, Text = text }
		for k, v in pairs(extra or {}) do
			body[k] = v
		end
		return apiRequest("POST", "/chat/send", body)
	end

	-- Side data from the last poll (pinned notice, online count) lives in api.ChatMeta.
	function api:PollChatMessages(sinceId)
		local decoded, err = apiRequest("GET", "/chat?since=" .. tostring(sinceId or 0))
		if not decoded then
			return nil, err
		end
		self.ChatMeta = { Pinned = decoded.PinnedMessage, OnlineCount = decoded.OnlineCount }
		return decoded.Messages or {}
	end

	function api:ReportChatMessage(messageId, reason)
		local decoded, err = apiRequest("POST", "/chat/" .. tostring(messageId) .. "/report", { Reason = reason })
		if not decoded then
			return false, err
		end
		return true
	end

	function api:PublishChatPresence(userId, allowJoin, placeId, jobId)
		local decoded, err = apiRequest("POST", "/chat/presence", {
			UserId = userId,
			AllowJoin = allowJoin,
			PlaceId = allowJoin and placeId or nil,
			JobId = allowJoin and jobId or nil,
		})
		if not decoded then
			return false, err
		end
		return true
	end

	function api:GetChatJoinTarget(userId)
		local decoded, err = apiRequest("GET", "/chat/presence/" .. tostring(userId))
		if not decoded then
			return nil, err
		end
		return decoded.JoinServer
	end

	function api:Heartbeat(payload)
		local decoded, err = apiRequest("POST", "/presence/heartbeat", payload)
		if not decoded then
			return false, err
		end
		return true
	end

	function api:GetActiveCount()
		local decoded, err = apiRequest("GET", "/presence/count")
		if not decoded then
			return nil, err
		end
		return decoded.Count or 0
	end

	function api:GetLeaderboard(limit)
		local decoded, err = apiRequest("GET", "/presence/leaderboard?limit=" .. tostring(limit or 10))
		if not decoded then
			return nil, err
		end
		return decoded.Items or {}
	end

	return api
end

function NullUI:CreateAIAssistant(opts)
	opts = opts or {}
	local providers = opts.Providers or {}
	local tools = opts.Tools or (opts.Window and opts.Window:_BuildDefaultChatTools()) or {}
	local systemPrompt = opts.SystemPrompt
		or (opts.Window and opts.Window:_BuildDefaultSystemPrompt())
		or "You are a helpful assistant."
	local maxRounds = opts.MaxRounds or 6
	local maxTokens = opts.MaxTokens or 2048
	local httpRequest = (syn and syn.request) or http_request or request

	local function toOpenAITools()
		local out = {}
		for _, tool in ipairs(tools) do
			table.insert(out, {
				type = "function",
				["function"] = {
					name = tool.Name,
					description = tool.Description,
					parameters = tool.Parameters,
				},
			})
		end
		return out
	end

	local persistPath = nil
	if opts.Persist then
		persistPath = ASSETS_FOLDER .. "/" .. SafeConfigName(tostring(opts.Persist)) .. ".chat.json"
	end

	local function loadHistory()
		if not (persistPath and fn_isfile and fn_readfile) then
			return nil
		end
		local existsOk, exists = pcall(fn_isfile, persistPath)
		if not existsOk or not exists then
			return nil
		end
		local ok, raw = pcall(fn_readfile, persistPath)
		if not ok then
			return nil
		end
		local decodeOk, decoded = pcall(function()
			return HttpService:JSONDecode(raw)
		end)
		if decodeOk and type(decoded) == "table" then
			return decoded
		end
		return nil
	end

	local conversation = loadHistory() or { { role = "system", content = systemPrompt } }

	local function saveHistory()
		if not (persistPath and fn_writefile) then
			return
		end
		EnsureAssetsFolder()
		pcall(fn_writefile, persistPath, HttpService:JSONEncode(conversation))
	end

	local function callProvider(provider, messages)
		local body = HttpService:JSONEncode({
			model = provider.Model,
			messages = messages,
			tools = toOpenAITools(),
			max_tokens = maxTokens,
		})

		local ok, res = pcall(httpRequest, {
			Url = provider.Endpoint,
			Method = "POST",
			Headers = {
				["Authorization"] = "Bearer " .. tostring(provider.ApiKey),
				["Content-Type"] = "application/json",
			},
			Body = body,
		})
		if not ok then
			return nil, tostring(res), false
		end

		if res.StatusCode and res.StatusCode ~= 200 then
			local message = res.Body
			local parseOk, parsed = pcall(function()
				return HttpService:JSONDecode(res.Body)
			end)
			if parseOk and type(parsed) == "table" then
				local errField = parsed.error
				if type(errField) == "table" and errField.message then
					message = tostring(errField.message)
				elseif type(errField) == "string" then
					message = errField
				end
			end
			local rateLimited = res.StatusCode == 429
			if rateLimited then
				message = message .. " (daily free-tier limit)"
			end
			return nil, provider.Name .. " API error " .. tostring(res.StatusCode) .. ": " .. message, rateLimited
		end

		local decodeOk, decoded = pcall(function()
			return HttpService:JSONDecode(res.Body)
		end)
		if not decodeOk then
			return nil, provider.Name .. ": failed to decode API response.", false
		end
		return decoded, nil, false
	end

	local function callAI(messages)
		if not httpRequest then
			return nil, "Your executor doesn't support HTTP requests."
		end
		local lastErr = "No AI provider configured -- add at least one entry with an ApiKey to Providers."
		for _, provider in ipairs(providers) do
			if provider.ApiKey and provider.ApiKey ~= "" then
				local decoded, err, rateLimited = callProvider(provider, messages)
				if decoded then
					return decoded
				end
				lastErr = err
				if not rateLimited then
					return nil, lastErr
				end
			end
		end
		return nil, lastErr
	end

	local assistant = {}
	local stopRequested = false
	local busy = false

	function assistant:Stop()
		stopRequested = true
	end

	function assistant:IsBusy()
		return busy
	end

	function assistant:GetHistory()
		return conversation
	end

	function assistant:Reset()
		table.clear(conversation)
		table.insert(conversation, { role = "system", content = systemPrompt })
		saveHistory()
	end

	function assistant:Ask(panel, userText)
		table.insert(conversation, { role = "user", content = userText })
		panel:ShowTyping()
		stopRequested = false
		busy = true

		for _ = 1, maxRounds do
			if stopRequested then
				busy = false
				panel:HideTyping()
				panel:AddMessage("assistant", "(stopped)")
				saveHistory()
				return
			end

			local response, err = callAI(conversation)
			if not response then
				busy = false
				panel:HideTyping()
				panel:AddMessage("assistant", "Error: " .. tostring(err))
				saveHistory()
				return
			end

			local choice = response.choices and response.choices[1]
			local message = choice and choice.message
			if not message then
				busy = false
				panel:HideTyping()
				panel:AddMessage("assistant", "Error: empty response from API.")
				saveHistory()
				return
			end

			table.insert(conversation, message)

			local calls = message.tool_calls
			local hasCalls = calls and #calls > 0
			local content = message.content or ""

			local _, fenceCount = content:gsub("```", "")
			local truncated = choice.finish_reason == "length" or fenceCount % 2 == 1

			if message.content and message.content ~= "" then
				if not hasCalls and not truncated then
					panel:HideTyping()
				end
				panel:AddMessage("assistant", message.content)
			end

			if hasCalls then
				for _, call in ipairs(calls) do
					local argsOk, args = pcall(function()
						return HttpService:JSONDecode(call["function"].arguments)
					end)
					local result = panel:HandleToolCall(call["function"].name, argsOk and args or {})
					table.insert(conversation, {
						role = "tool",
						tool_call_id = call.id,
						content = HttpService:JSONEncode(result == nil and {} or result),
					})
				end
			elseif truncated then
				table.insert(conversation, {
					role = "user",
					content = "You got cut off. Continue exactly where you left off -- don't repeat "
						.. "anything, don't restart the explanation.",
				})
			else
				busy = false
				panel:HideTyping()
				saveHistory()
				return
			end
		end

		busy = false
		panel:HideTyping()
		panel:AddMessage(
			"assistant",
			"(stopped after several rounds of tool calls/continuations -- ask me to continue if you need to)"
		)
		saveHistory()
	end

	return assistant
end

local function DestroyAllWindowJanitors()
	for _, win in ipairs(NullUI._Windows) do
		win._destroyed = true
		if win._janitor then
			win._janitor:Destroy()
		end
	end
	table.clear(NullUI._Windows)
end

NullUI._Root.Destroying:Connect(function()
	AcrylicShuttingDown = true
	DestroyAllWindowJanitors()
	DestroyAllAcrylicControllers()
	LibJanitor:Destroy()
end)

function NullUI:Unload()
	if NullUI._Unloaded then
		return
	end
	NullUI._Unloaded = true
	-- Scripts hang their own GUIs off this, a launcher button being the usual
	-- one, so nothing is left on screen whichever path tore the library down.
	pcall(function()
		NullUI.Unloaded.Fire()
	end)
	pcall(CloseAnyOpenPopup)
	AcrylicShuttingDown = true
	pcall(DestroyAllWindowJanitors)
	pcall(DestroyAllAcrylicControllers)
	pcall(function()
		LibJanitor:Destroy()
	end)
	if NullUI._Root then
		pcall(function()
			NullUI._Root:Destroy()
		end)
		NullUI._Root = nil
	end
	NullUI._Windows = {}
	NullUI.Flags = {}
	local globalTable = GetGlobalTable()
	if globalTable.__NullUI_Unload then
		globalTable.__NullUI_Unload = nil
	end
end

local Translator = {
	enabled = true,
	lang = nil,
	cache = {},
	queue = {},
	queued = {},
	waiting = {},
	source = setmetatable({}, { __mode = "k" }),
	applied = setmetatable({}, { __mode = "k" }),
	running = false,
	dirty = false,
	terms = {
		{ en = "Race", clear = "Bloodline", vi = "Tộc" },
		{ en = "Reroll", clear = "re-roll", vi = "Roll lại" },
	},
}

local function TranslatorLanguage()
	local locale
	pcall(function()
		locale = game:GetService("LocalizationService").RobloxLocaleId
	end)
	if type(locale) ~= "string" or locale == "" then
		pcall(function()
			locale = LocalPlayer.LocaleId
		end)
	end
	locale = type(locale) == "string" and locale:lower() or "en-us"
	local code = locale:match("^(%a+)") or "en"
	if code == "zh" then
		if locale:find("tw") or locale:find("hk") then
			return "zh-TW"
		end
		return "zh-CN"
	end
	return code
end

local function TranslatorWanted(text)
	LPH_ATTRIBUTES(VM(NONE))
	if type(text) ~= "string" or #text < 2 or #text > 300 then
		return false
	end
	if text:find("<") or not text:find("%a%a") then
		return false
	end
	if text:find(" : ") or text:find("|") or text:find("%d%d") or text:find("%d%s*/%s*%d") or text:find("%%") then
		return false
	end
	if text:find("[\128-\255]") then
		return false
	end
	return true
end

local function TranslatorCacheFile()
	return "NullUI/translate_" .. Translator.lang .. ".json"
end

local function TranslatorLoadCache()
	if type(readfile) ~= "function" or type(isfile) ~= "function" then
		return
	end
	pcall(function()
		if isfile(TranslatorCacheFile()) then
			local data = game:GetService("HttpService"):JSONDecode(readfile(TranslatorCacheFile()))
			if type(data) == "table" then
				Translator.cache = data
			end
		end
	end)
end

local function TranslatorSaveCache()
	if not Translator.dirty or type(writefile) ~= "function" then
		return
	end
	Translator.dirty = false
	pcall(function()
		if type(isfolder) == "function" and type(makefolder) == "function" and not isfolder("NullUI") then
			makefolder("NullUI")
		end
		writefile(TranslatorCacheFile(), game:GetService("HttpService"):JSONEncode(Translator.cache))
	end)
end

local function TranslatorSet(label, translated)
	LPH_ATTRIBUTES(VM(NONE))
	if not label.Parent or not Translator.enabled then
		return
	end
	Translator.applied[label] = translated
	label.Text = translated
end

local function TranslatorRequest(joined)
	local http = game:GetService("HttpService")
	local query = http:UrlEncode(joined)
	local ok, body = pcall(
		game.HttpGetAsync,
		game,
		"https://clients5.google.com/translate_a/t?client=dict-chrome-ex&sl=en&tl=" .. Translator.lang .. "&q=" .. query
	)
	if ok and type(body) == "string" then
		local decodedOk, decoded = pcall(http.JSONDecode, http, body)
		if decodedOk and type(decoded) == "table" then
			local first = decoded[1]
			if type(first) == "table" then
				first = first[1]
			end
			if type(first) == "string" then
				return first
			end
		end
	end
	ok, body = pcall(
		game.HttpGetAsync,
		game,
		"https://api.mymemory.translated.net/get?langpair=en|" .. Translator.lang .. "&q=" .. query
	)
	if ok and type(body) == "string" then
		local decodedOk, decoded = pcall(http.JSONDecode, http, body)
		if decodedOk and type(decoded) == "table" and type(decoded.responseData) == "table" then
			local text = decoded.responseData.translatedText
			if type(text) == "string" then
				return text
			end
		end
	end
	return nil
end

local function TranslatorFetch(batch)
	local terms, lang = Translator.terms, Translator.lang
	local protectedLines, restores = {}, {}
	for index, line in ipairs(batch) do
		local restore
		if terms then
			for ti, term in ipairs(terms) do
				local override = term[lang]
				if override then
					local token = "QZX" .. string.char(64 + ti)
					local newText, count = line:gsub("%f[%a]" .. term.en .. "%f[%A]", token)
					if count > 0 then
						line = newText
						restore = restore or {}
						restore[token] = override
					end
				end
			end
		end
		protectedLines[index] = line
		restores[index] = restore
	end
	local translated = TranslatorRequest(table.concat(protectedLines, "\n"))
	if not translated then
		return nil
	end
	local lines = {}
	for line in (translated .. "\n"):gmatch("(.-)\n") do
		table.insert(lines, line)
	end
	if #lines ~= #batch then
		return nil
	end
	for index = 1, #lines do
		local restore = restores[index]
		if restore then
			for token, target in pairs(restore) do
				lines[index] = lines[index]:gsub(token, target)
			end
		end
	end
	return lines
end

local function TranslatorWorker()
	if Translator.running then
		return
	end
	Translator.running = true
	SafeSpawn(function()
		while #Translator.queue > 0 and Translator.enabled do
			local batch, size = {}, 0
			while #Translator.queue > 0 and #batch < 25 and size < 1500 do
				local text = table.remove(Translator.queue, 1)
				table.insert(batch, text)
				size += #text
			end
			local results = TranslatorFetch(batch)
			if not results and #batch > 1 then
				results = {}
				for _, text in ipairs(batch) do
					local single = TranslatorFetch({ text })
					table.insert(results, single and single[1] or text)
					task.wait(0.4)
				end
			end
			for index, text in ipairs(batch) do
				local translated = results and results[index]
				if type(translated) ~= "string" or translated == "" then
					translated = text
				end
				Translator.cache[text] = translated
				Translator.queued[text] = nil
				Translator.dirty = true
				local labels = Translator.waiting[text]
				Translator.waiting[text] = nil
				for _, label in ipairs(labels or {}) do
					if Translator.source[label] == text then
						TranslatorSet(label, translated)
					end
				end
			end
			TranslatorSaveCache()
			task.wait(1.2)
		end
		Translator.running = false
	end)
end

local function TranslatorTrack(label)
	LPH_ATTRIBUTES(VM(NONE))
	if not Translator.enabled then
		return
	end
	local text = label.Text
	if Translator.applied[label] == text then
		return
	end
	Translator.applied[label] = nil
	Translator.source[label] = text
	if not TranslatorWanted(text) then
		return
	end
	local cached = Translator.cache[text]
	if cached then
		if cached ~= text then
			TranslatorSet(label, cached)
		end
		return
	end
	Translator.waiting[text] = Translator.waiting[text] or {}
	table.insert(Translator.waiting[text], label)
	if not Translator.queued[text] then
		Translator.queued[text] = true
		table.insert(Translator.queue, text)
		TranslatorWorker()
	end
end

local function TranslatorWatch(object)
	LPH_ATTRIBUTES(VM(NONE))
	if not (object:IsA("TextLabel") or object:IsA("TextButton")) or Translator.source[object] ~= nil then
		return
	end
	Translator.source[object] = false
	object:GetPropertyChangedSignal("Text"):Connect(function()
		TranslatorTrack(object)
	end)
	TranslatorTrack(object)
end

function NullUI:GetLanguage()
	return Translator.lang
end

-- Turn auto-translation on/off at runtime. Turning it off restores the original text.
function NullUI:SetAutoTranslate(enabled)
	Translator.enabled = enabled == true
	if not Translator.enabled then
		for label, original in pairs(Translator.source) do
			if original and label.Parent and Translator.applied[label] then
				label.Text = original
			end
		end
	end
end

do
	Translator.lang = TranslatorLanguage()
	-- Set `getgenv().NullUI_NoTranslate = true` before loading to skip the translator entirely.
	local disabled = false
	pcall(function()
		disabled = getgenv().NullUI_NoTranslate == true
	end)
	if disabled then
		Translator.enabled = false
	end
	if not disabled and Translator.lang ~= "en" and NullUI._Root then
		TranslatorLoadCache()
		Translator.pending = setmetatable({}, { __mode = "k" })
		NullUI._Root.DescendantAdded:Connect(function(object)
			if Translator.enabled and (object:IsA("TextLabel") or object:IsA("TextButton")) then
				Translator.pending[object] = true
			end
		end)
		SafeSpawn(function()
			if Translator.terms then
				for _, term in ipairs(Translator.terms) do
					if term[Translator.lang] == nil and term.clear then
						term[Translator.lang] = TranslatorRequest(term.clear) or term.clear
					end
				end
			end
			local scanned = 0
			for _, object in ipairs(NullUI._Root:GetDescendants()) do
				if object:IsA("TextLabel") or object:IsA("TextButton") then
					Translator.pending[object] = true
					scanned += 1
					if scanned % 40 == 0 then
						task.wait()
					end
				end
			end
			while true do
				local processed = 0
				for object in pairs(Translator.pending) do
					Translator.pending[object] = nil
					if Translator.enabled then
						pcall(TranslatorWatch, object)
					end
					processed += 1
					if processed % 25 == 0 then
						task.wait()
					end
				end
				task.wait(0.6)
			end
		end)
	end
end

do
	local globalTable = GetGlobalTable()
	globalTable.__NullUI_Unload = function()
		pcall(function()
			NullUI:Unload()
		end)
	end
end

return NullUI
