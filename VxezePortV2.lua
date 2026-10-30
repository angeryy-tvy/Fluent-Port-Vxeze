-- VxezePortV2: Vxeze Hub UI library (split out of Sae-VxezeV2.lua) with global chat.
-- local Library = loadstring(game:HttpGet(".../VxezePortV2.lua"))()
-- Window:GlobalChat({ Endpoint = ..., ApiKey = ... }) adds a Chat tab.
local Library = (function()
	local function fn(arg)
		return game:GetService(arg)
	end

	local UserInputService = fn("UserInputService")
	local TweenService = fn("TweenService")
	local HttpService = fn("HttpService")
	local RunService = fn("RunService")
	local localPlayer = fn("Players").LocalPlayer
	local color = Color3.fromRGB
	local udim2 = UDim2.new
	local udim = UDim.new
	local vector2 = Vector2.new
	local font = Font.new("rbxasset://fonts/families/Montserrat.json", Enum.FontWeight.SemiBold)
	local font2 = Font.new("rbxasset://fonts/families/Montserrat.json", Enum.FontWeight.Bold)
	local font3 = Font.new("rbxasset://fonts/families/Montserrat.json", Enum.FontWeight.ExtraBold)
	local font4 = Font.new("rbxasset://fonts/families/RobotoMono.json", Enum.FontWeight.SemiBold)
	local font5 = Font.new("rbxassetid://12187365977", Enum.FontWeight.Bold)
	local colorSequence = ColorSequence.new(color(26, 255, 0), color(0, 255, 0))
	local font6 = Font.new(font5.Family, font5.Weight, Enum.FontStyle.Italic)

	local tbl = {
		bg = color(16, 18, 40),
		tx = color(242, 244, 255),
		a1 = color(122, 162, 255),
		a2 = color(185, 139, 255),
		g1 = color(255, 229, 138),
		g2 = color(255, 155, 88),
		dk = color(42, 18, 0),
		mint = color(110, 255, 182),
		red = color(255, 110, 110),
		sky = color(143, 180, 255),
		pink = color(255, 158, 207),
		vio = color(199, 166, 255),
		gold = color(255, 210, 122),
		wh = color(255, 255, 255),
		val = color(217, 222, 255),
		dc = color(88, 101, 242),
		pn = color(24, 26, 54),
		w1 = color(36, 40, 86),
		w2 = color(14, 15, 34),
		gv = color(184, 255, 156),
		on = color(255, 255, 254),
	}

	local tbl2 = {
		{"Twilight", color(36, 40, 86), color(14, 15, 34), color(122, 162, 255), color(185, 139, 255)},
		{"Aurora", color(10, 84, 82), color(4, 26, 38), color(63, 224, 176), color(127, 255, 216)},
		{"Ocean", color(8, 70, 128), color(3, 20, 52), color(47, 185, 221), color(127, 220, 255)},
		{"Midnight", color(52, 24, 112), color(10, 4, 36), color(118, 100, 226), color(160, 132, 240)},
		{"Sakura", color(118, 44, 96), color(36, 12, 40), color(255, 140, 200), color(255, 196, 228)},
		{"Onyx", color(58, 46, 22), color(8, 6, 2), color(255, 206, 110), color(255, 150, 80)},
		{
			"Black",
			color(50, 50, 56),
			color(16, 16, 19),
			color(250, 251, 255),
			color(176, 182, 198),
			color(14, 14, 18),
		},
		{
			"Mono",
			color(92, 94, 104),
			color(30, 31, 36),
			color(250, 251, 255),
			color(196, 200, 214),
			color(20, 21, 26),
		},
	}

	local tbl3 = {tbl.gold, tbl.mint, tbl.sky, tbl.pink, tbl.vio}

	local tbl4 = {
		LeftShift = "LShift",
		RightShift = "RShift",
		LeftControl = "LCtrl",
		RightControl = "RCtrl",
		LeftAlt = "LAlt",
		RightAlt = "RAlt",
	}

	local v = udim2(1, 0, 1, 0)
	local v2 = udim2(0.5, 0, 0.5, 0)
	local v3 = vector2(0.5, 0.5)
	local v4 = vector2(1, 0.5)
	local center = Enum.TextXAlignment.Center
	local center2 = Enum.HorizontalAlignment.Center
	local horizontal = Enum.FillDirection.Horizontal
	local y = Enum.AutomaticSize.Y
	local x = Enum.AutomaticSize.X
	local atEnd = Enum.TextTruncate.AtEnd
	local center3 = Enum.VerticalAlignment.Center
	local v5 = udim2(1, 0, 0, 0)
	local v6 = udim2(1, 0, 0.5, 0)
	local v7 = vector2(1, 0)
	local quint = Enum.EasingStyle.Quint
	local back = Enum.EasingStyle.Back
	local n = 46
	local n2 = 54

	local function fn2(arg, arg2)
		return udim2(0, arg, 0, arg2)
	end

	local tbl5 = {}

	for i, v8 in ipairs({
		"home",
		"zap",
		"egg",
		"farm",
		"leaf",
		"eye",
		"user",
		"settings",
		"search",
		"minus",
		"x",
		"shield",
		"target",
		"crosshair",
		"key",
		"palette",
		"folder",
		"star",
		"check",
		"down",
		"gauge",
		"wind",
		"ghost",
		"clock",
		"coins",
		"pin",
		"info",
		"warn",
		"ok",
		"sliders",
		"grid",
		"server",
		"flame",
		"swords",
		"trash",
		"save",
		"copy",
		"plus",
		"refresh",
		"crown",
		"gem",
		"hand",
		"wand",
		"sparkles",
		"discord",
	}) do
		tbl5[v8] = i - 1
	end

	local str = "tienkhanh1/venyx-assets@main/venyx-icons3.png"
	local png

	local function fn3(arg, arg2)
		local v8 = getcustomasset
		local v9, ok, result

		if v8 then
			v9 = v8

			if writefile then
				ok, result = pcall(function()
					if not (isfile and isfile(arg)) then
						pcall(makefolder, "VxezeHub")

						for _, v10 in ipairs(arg2) do
							local ok2, result2 = pcall(function()
								if v10:sub(1, 5) ~= "data:" then
									return game:HttpGet(v10)
								end
								local base64decode

								if crypt then
									base64decode = crypt.base64decode

									if not base64decode then
										if crypt.base64 then
											base64decode = crypt.base64.decode or base64_decode
										else
											base64decode = base64_decode
											return base64decode(v10:sub(6))
										end
									end
								else
									base64decode = base64_decode
									return base64decode(v10:sub(6))
								end

								return base64decode(v10:sub(6))
							end)

							if ok2 and result2:sub(2, 4) == "PNG" then
								writefile(arg, result2)
								break
							end
						end
					end

					return v9(arg)
				end)

				if ok and result then
					return result
				end
				return nil
			end
		else
			v9 = getsynasset

			if v9 then
				if writefile then
					ok, result = pcall(function()
						if not (isfile and isfile(arg)) then
							pcall(makefolder, "VxezeHub")

							for _, v10 in ipairs(arg2) do
								local ok2, result2 = pcall(function()
									if v10:sub(1, 5) ~= "data:" then
										return game:HttpGet(v10)
									end
									local base64decode

									if crypt then
										base64decode = crypt.base64decode

										if not base64decode then
											if crypt.base64 then
												base64decode = crypt.base64.decode or base64_decode
											else
												base64decode = base64_decode
												return base64decode(v10:sub(6))
											end
										end
									else
										base64decode = base64_decode
										return base64decode(v10:sub(6))
									end

									return base64decode(v10:sub(6))
								end)

								if ok2 and result2:sub(2, 4) == "PNG" then
									writefile(arg, result2)
									break
								end
							end
						end

						return v9(arg)
					end)

					if ok and result then
						return result
					end
					return nil
				end
			end
		end

		return nil
	end

	local function fn4()
		if png == nil then
			png = fn3("VxezeHub/icons3.png", {
				"https://raw.githubusercontent.com/" .. str:gsub("@", "/"),
				"https://cdn.jsdelivr.net/gh/tienkhanh1/venyx-assets@main/venyx-icons3.png",
			}) or false
		end

		return png
	end

	local tbl6 = {Opt = {}, Keys = {}, Alias = {}, th = tbl2[1][1]}
	local state = {AutoLoad = true, AutoSave = true, Active = "Default", Theme = "Ocean", Cfg = 2, Lang = ""}
	tbl6.State = state
	local tbl7 = {}

	local function fn5(arg, arg2)
		tbl7[#tbl7 + 1] = arg:Connect(arg2)
	end

	local function fn6()
		local tbl8 = {}

		for i = 1, 10 do
			tbl8[i] = string.char(math.random(97, 122))
		end

		return table.concat(tbl8)
	end

	local function fn7(arg, arg2)
		local instance = Instance.new(arg)
		instance.Name = fn6()
		local parent = arg2.Parent
		arg2.Parent = nil

		for k, v8 in next, arg2 do
			if type(k) == "number" then
				v8.Parent = instance
			else
				instance[k] = v8
			end
		end

		instance.Parent = parent
		return instance
	end

	local tbl8 = {BackgroundTransparency = 1, BorderSizePixel = 0, BackgroundColor3 = tbl.wh}

	local function fn8(arg, arg2, arg3)
		local function fn9(arg4)
			for _, v8 in ipairs({arg2, tbl8}) do
				for k, v9 in next, v8 do
					if arg4[k] == nil then
						arg4[k] = v9
					end
				end
			end

			if arg3 and arg4.TextSize then
				arg4.TextSize = math.floor(arg4.TextSize * 1.18 + 0.5)
			end

			local textSize = arg4.TextTruncate == atEnd and not arg4.AutomaticSize and arg4.TextSize

			if textSize then
				arg4.TextTruncate = nil
			end

			local v8 = fn7(arg, arg4)

			if textSize then
				local function fn10()
					if v8.AbsoluteSize.X < 2 then
						return
					elseif v8:GetAttribute("nofit") then
						return
					elseif v8.TextSize == textSize and v8.TextBounds.X <= v8.AbsoluteSize.X then
						return
					end

					v8.TextSize = textSize
					local attribute = v8:GetAttribute("alt")
					if attribute and v8.Text ~= attribute and v8.TextBounds.X > v8.AbsoluteSize.X then
						v8.Text = attribute
						return
					end

					while true do
						if not (v8.TextBounds.X > v8.AbsoluteSize.X and v8.TextSize > 8) then
							break
						end
						v8.TextSize = v8.TextSize - 1
					end
				end

				v8:GetPropertyChangedSignal("Text"):Connect(fn10)
				v8:GetPropertyChangedSignal("AbsoluteSize"):Connect(fn10)
			end

			return v8
		end

		return fn9
	end

	local tbl9 = {FontFace = font, TextColor3 = tbl.tx, TextSize = 13, TextXAlignment = Enum.TextXAlignment.Left}
	local Frame = fn8("Frame", {})
	local Frame2 = fn8("Frame", {BackgroundTransparency = 0})
	local TextButton = fn8("TextButton", {Text = "", AutoButtonColor = false}, true)
	local TextLabel = fn8("TextLabel", tbl9, true)

	local TextBox = fn8("TextBox", {
		Text = "",
		PlaceholderColor3 = color(178, 180, 188),
		ClearTextOnFocus = false,
		FontFace = font,
		TextColor3 = tbl.tx,
		TextSize = 13,
		TextXAlignment = tbl9.TextXAlignment,
	}, true)

	local ScrollingFrame = fn8("ScrollingFrame", {
		ScrollBarThickness = 2,
		ScrollBarImageTransparency = 0.6,
		CanvasSize = udim2(),
		AutomaticCanvasSize = y,
		ScrollingDirection = Enum.ScrollingDirection.Y,
	})

	local ImageLabel = fn8("ImageLabel", {})

	local function fn9(arg)
		local v8 = tbl5[arg.Image]

		if v8 then
			local v9 = fn4()
			arg.Image = v9 or ""

			if v9 then
				arg.ImageRectOffset = vector2(v8 % 8 * 64, v8 // 8 * 64)
				arg.ImageRectSize = vector2(64, 64)
			end
		end

		return ImageLabel(arg)
	end

	local function fn10(image, arg, imageColor3, imageTransparency)
		return fn9({
			AnchorPoint = v3,
			Position = v2,
			Size = fn2(arg, arg),
			Image = image,
			ImageColor3 = imageColor3,
			ImageTransparency = imageTransparency,
		})
	end

	local function fn11(arg)
		return "rbxthumb://type=AvatarHeadShot&id=" .. localPlayer.UserId .. "&w=" .. arg .. "&h=" .. arg
	end

	local function fn12(arg)
		return fn7("UICorner", {CornerRadius = arg and udim(0, arg) or udim(1, 0)})
	end

	local function fn13(transparency, color2)
		return fn7("UIStroke", {Transparency = transparency, Color = color2 or tbl.wh, ApplyStrokeMode = Enum.ApplyStrokeMode.Border})
	end

	local function fn14(arg, arg2, rotation)
		return fn7("UIGradient", {Color = ColorSequence.new(arg, arg2), Rotation = rotation or 0})
	end

	local function fn15(rotation, ...)
		local tbl10 = {}

		for i, v8 in ipairs({...}) do
			tbl10[i] = NumberSequenceKeypoint.new(v8[1], v8[2])
		end

		return fn7("UIGradient", {Rotation = rotation, Transparency = NumberSequence.new(tbl10)})
	end

	local function fn16(arg, arg2, arg3, arg4)
		return fn7("UIPadding", {
			PaddingTop = udim(0, arg),
			PaddingRight = udim(0, arg2 or arg),
			PaddingBottom = udim(0, arg3 or arg),
			PaddingLeft = udim(0, arg4 or arg2 or arg),
		})
	end

	local function fn17(arg, horizontalAlignment, verticalAlignment, fillDirection)
		return fn7("UIListLayout", {
			Padding = udim(0, arg or 0),
			HorizontalAlignment = horizontalAlignment,
			VerticalAlignment = verticalAlignment,
			FillDirection = fillDirection,
			SortOrder = Enum.SortOrder.LayoutOrder,
		})
	end

	local function fn18(parent, position, size)
		return Frame({Parent = parent, Position = position, Size = size, BackgroundTransparency = 0.9})
	end

	local function fn19(arg, arg2, arg3, arg4, arg5, arg6)
		local n3 = arg3 or 0.25
		local v8 = arg4 or quint
		local out = arg5 or Enum.EasingDirection.Out
		local tween = TweenService:Create(arg, TweenInfo.new(n3, v8, out, 0, false, arg6 or 0), arg2)
		tween:Play()
		return tween
	end

	local function fn20(arg, backgroundTransparency, backgroundTransparency2)
		fn5(arg.MouseEnter, function()
			fn19(arg, {BackgroundTransparency = backgroundTransparency}, 0.15)
		end)

		fn5(arg.MouseLeave, function()
			fn19(arg, {BackgroundTransparency = backgroundTransparency2 or 1}, 0.25)
		end)
	end

	local function fn21(arg, arg2, arg3)
		local function fn22()
			if not arg3() then
				arg2.Visible = false
			end
		end

		arg.Completed:Connect(fn22)
	end

	local function fn22(arg, ...)
		if arg then
			pcall(arg, ...)
		end
	end

	local function fn23(arg)
		return arg.UserInputType == Enum.UserInputType.MouseButton1 or arg.UserInputType == Enum.UserInputType.Touch
	end

	local tbl10 = {p = Vector3.zero, t = 0, m = 0}

	fn5(UserInputService.InputBegan, function(arg)
		if fn23(arg) then
			tbl10.p, tbl10.t = arg.Position, os.clock()
			tbl10.m = 0
			tbl10.s = false
		end
	end)

	fn5(UserInputService.InputChanged, function(arg)
		if arg.UserInputType == Enum.UserInputType.Touch or arg.UserInputType == Enum.UserInputType.MouseMovement then
			tbl10.m = math.max(tbl10.m, (arg.Position - tbl10.p).Magnitude)
		end
	end)

	local function fn24()
		return tbl10.m < 14 and os.clock() - tbl10.t < 0.45 and not tbl10.s
	end

	local function fn25(arg, arg2)
		fn5(arg.Activated, function(...)
			if fn24() then
				arg2(...)
			end
		end)
	end

	local function fn26(arg)
		local str2 = tostring(arg)
		local match, v8 = str2:match("^(%-?%d+)(.*)$")
		if not match then
			return str2
		end
		return match:reverse():gsub("(%d%d%d)", "%1,"):reverse():gsub("^(%-?),", "%1") .. v8
	end

	local function fn27(parent, scale, arg, arg2)
		local anchorPoint = parent.AnchorPoint
		local position = parent.Position
		local size = parent.Size

		if not parent.Parent:FindFirstChildWhichIsA("UIGridStyleLayout") then
			parent.AnchorPoint = v3
			parent.Position = position + udim2((0.5 - anchorPoint.X) * size.X.Scale, (0.5 - anchorPoint.X) * size.X.Offset, (0.5 - anchorPoint.Y) * size.Y.Scale, (0.5 - anchorPoint.Y) * size.Y.Offset)
		end

		local UIScale = fn7("UIScale", {Parent = parent})
		arg = arg or parent

		fn5(arg.InputBegan, function(arg3)
			if not fn23(arg3) then
				return
			end
			fn19(UIScale, {Scale = scale or 0.96}, 0.12)

			if arg2 then
				arg2(true)
			end
		end)

		fn5(arg.InputEnded, function(arg3)
			if not fn23(arg3) then
				return
			end
			fn19(UIScale, {Scale = 1}, 0.4, back)

			if arg2 then
				arg2(false)
			end
		end)
	end

	local function fn28(p, a)
		return {p = p, v = vector2(), t = p, a = a}
	end

	local function fn29(arg, arg2)
		if (arg.t - arg.p).Magnitude < 0.03 and arg.v.Magnitude < 0.03 then
			return
		end
		arg2 = math.min(arg2, 0.05)
		local v8 = math.ceil(arg2 * 240)
		local n3 = arg2 / v8

		for i = 1, v8 do
			arg.v = arg.v + ((arg.t - arg.p) * 230 - arg.v * 29) * n3
			arg.p = arg.p + arg.v * n3
		end

		arg.a(arg.p)
	end

	local function fn30(arg, arg2, arg3)
		local v8, v9, v10, flag

		local function fn31()
			return v8.UserInputType == Enum.UserInputType.Touch
		end

		fn5(arg.InputBegan, function(arg4)
			if not v8 and fn23(arg4) then
				local v11 = vector2(arg4.Position.X, arg4.Position.Y)
				local t = arg2.t
				v8 = arg4
				v9 = v11
				v10 = t
				flag = false
			end
		end)

		fn5(UserInputService.InputChanged, function(arg4)
			if not v8 then
				return
			end

			if fn31() and arg4 ~= v8 then
				return
			elseif not fn31() and arg4.UserInputType ~= Enum.UserInputType.MouseMovement then
				return
			end

			local n3 = vector2(arg4.Position.X, arg4.Position.Y) - v9
			flag = flag or n3.Magnitude > 5

			if flag then
				arg2.t = arg3(v10 + n3)
			end
		end)

		fn5(UserInputService.InputEnded, function(arg4)
			if v8 then
				if arg4 == v8 then
					v8 = nil
				elseif not fn31() and arg4.UserInputType == Enum.UserInputType.MouseButton1 then
					v8 = nil
				end
			end
		end)

		local function fn32()
			return flag
		end

		return fn32
	end

	local function fn32(parent, arg5)
		arg5.Parent = parent
		arg5.Image = "rbxassetid://114478477603814"
		fn9(arg5)
	end

	local function fn33(parent, arg, arg2)
		local v8 = Frame({
			Parent = parent,
			AnchorPoint = v4,
			Position = v6,
			Size = fn2(arg, arg2),
			BackgroundTransparency = 0.84,
			fn12(),
		})

		local v9 = Frame({Parent = v8, Size = v, fn12(), fn14(tbl.a1, tbl.a2)})

		local v10 = Frame2({
			Parent = v8,
			AnchorPoint = vector2(0, 0.5),
			Position = udim2(0, 3, 0.5, 0),
			Size = fn2(arg2 - 6, arg2 - 6),
			ZIndex = 2,
			fn12(),
			(fn13(0.6, color(0, 0, 0))),
		})

		local function fn34(arg3, arg4)
			local backgroundTransparency = arg3 and 0 or 1
			local v11 = udim2(0, arg3 and arg - arg2 + 3 or 3, 0.5, 0)

			if arg4 then
				v9.BackgroundTransparency = backgroundTransparency
				v10.Position = v11
				return
			end

			fn19(v9, {BackgroundTransparency = backgroundTransparency}, 0.26)
			fn19(v10, {Position = v11}, 0.26)
		end

		return fn34
	end

	local function fn34(arg, arg2, transparency, transparency2, arg3)
		fn5(arg.Focused, function()
			fn19(arg2, {Transparency = transparency, Color = tbl.a1}, 0.2)
		end)

		fn5(arg.FocusLost, function()
			fn19(arg2, {Transparency = transparency2, Color = tbl.wh}, 0.25)

			if arg3 then
				arg3()
			end
		end)
	end

	local function fn35(arg, placeholderText)
		local v8 = fn13(0.86)
		arg.BackgroundTransparency = arg.BackgroundTransparency or 0.92
		arg[1] = fn12(9)
		arg[2] = v8
		arg[3] = fn9({Position = udim2(0, 10, 0.5, -9), Size = fn2(18, 18), Image = "search", ImageTransparency = 0.3})
		arg.ClipsDescendants = true

		local v9 = TextBox({
			Parent = Frame(arg),
			Position = fn2(35, 0),
			Size = udim2(1, -43, 1, 0),
			PlaceholderText = placeholderText,
			TextSize = 14,
			ClipsDescendants = true,
		})

		fn34(v9, v8, 0.55, 0.86)
		return v9
	end

	local tbl12 = {ok = tbl.mint, warn = tbl.gold, err = tbl.red}
	local tbl13 = {ok = "ok", err = "x", warn = "warn"}

	local function fn36(arg)
		return tbl12[arg] or tbl.sky, tbl13[arg] or "info"
	end

	local function fn37(arg)
		for _, child in ipairs(arg:GetChildren()) do
			if child:IsA("GuiObject") then
				child:Destroy()
			end
		end
	end

	local function fn38(arg)
		return {
			Set = function(arg2, arg3, text)
				local v8 = arg[arg3]

				if v8 and v8.Text ~= text then
					v8.Text = text
				end
			end,
			Icon = function(arg2, arg3, image)
				local imageLabel = arg[arg3] and arg[arg3].Parent:FindFirstChildOfClass("ImageLabel")

				if imageLabel and imageLabel.Image ~= image then
					imageLabel.Image, imageLabel.ImageColor3 = image, tbl5[image] and tbl.a1 or color(255, 255, 255)
				end
			end,
		}
	end

	local function fn39(parent, text, arg, arg2, arg3)
		local v8

		local tbl14 = {
			Parent = parent,
			Position = udim2(arg / arg2, arg * 8 / arg2, 0, 0),
			Size = udim2(1 / arg2, 8 / arg2 - 8, 1, 0),
			BackgroundTransparency = arg3 and 0 or 0.92,
		}

		parent, v8 = fn12(13), arg3 and fn14(tbl.a1, tbl.a2, 90)
		arg, arg2 = v8 or fn13(0.84), arg3 and fn13(0.55, tbl.a1:Lerp(tbl.wh, 0.5))

		tbl14[1], tbl14[2], tbl14[3], tbl14[4] = parent, arg, arg2 or nil, TextLabel({
			Size = v,
			Text = text,
			FontFace = font2,
			TextSize = 16,
			TextColor3 = arg3 and tbl.on or tbl.wh,
			TextXAlignment = center,
		})

		local v9 = TextButton(tbl14)
		fn27(v9)
		return v9
	end

	local index = {}
	index.__index = index

	local function fn40(arg)
		if arg.bq then
			return
		elseif arg.done == #arg.list then
			return
		end

		arg.bq = true

		task.defer(function()
			arg.bq = false
			local tbl14 = {0, 0}
			local v8 = table.clone(arg.list)
			local tbl15 = {}

			table.sort(v8, function(arg2, arg3)
				return arg2.card.AbsoluteSize.Y > arg3.card.AbsoluteSize.Y
			end)

			local flag = true
			local flag2 = true

			for _, v9 in ipairs(v8) do
				local side = v9.side or (tbl14[1] <= tbl14[2] and 1 or 2)

				if flag then
					flag = not v9.side or v9.side == 3
				end

				tbl15[v9] = side

				if side < 3 then
					tbl14[side] = tbl14[side] + (v9.card.AbsoluteSize.Y + 16)
				end

				flag2 = flag2 and v9.card.AbsoluteSize.Y > 40
			end

			flag = flag and tbl15[arg.list[1]] == 2

			for k, v9 in next, tbl15 do
				v9 = flag and v9 < 3 and 3 - v9 or v9

				if k.card.Parent ~= arg.cols[v9] then
					k.card.Parent = arg.cols[v9]
				end
			end

			if flag2 then
				arg.done = #arg.list
			end
		end)
	end

	local function fn41(arg)
		if not pcall(function()
			arg.Parent = gethui()
		end) then
			arg.Parent = fn("CoreGui")
		end
	end

	local function fn42(vxezeUI, id)
		local genv = getgenv and getgenv() or {}
		local vxezeWindows = genv.VxezeWindows or {}
		genv.VxezeWindows = vxezeWindows
		local vxezeUI2 = vxezeWindows[id]

		if vxezeUI2 then
			pcall(vxezeUI2.Destroy, vxezeUI2)
		else
			vxezeUI2 = genv.VxezeUI
			vxezeUI2 = vxezeUI2 and not genv.VxezeUI.Id and genv.VxezeUI

			if vxezeUI2 then
				pcall(vxezeUI2.Destroy, vxezeUI2)
			end
		end

		local v8 = tbl6
		local v9 = tbl6
		vxezeWindows[id] = vxezeUI
		genv.VxezeUI = vxezeUI
		v8.W = vxezeUI
		v9.Id = id
		vxezeUI.Id = id
		local tbl14 = {}

		for k, v10 in next, vxezeWindows, nil do
			if k ~= id then
				tbl14[v10.slot or 0] = true
			end
		end

		vxezeUI.slot = 0

		while tbl14[vxezeUI.slot] do
			vxezeUI.slot = vxezeUI.slot + 1
		end

		local ScreenGui = fn7("ScreenGui", {
			IgnoreGuiInset = true,
			ResetOnSpawn = false,
			ZIndexBehavior = Enum.ZIndexBehavior.Sibling,
			DisplayOrder = 100,
		})

		ScreenGui:SetAttribute("VxezeId", id)
		fn41(ScreenGui)

		if not (genv.VxezeNT and genv.VxezeNT.Parent and genv.VxezeNT.Parent.Parent) then
			local ScreenGui2 = fn7("ScreenGui", { IgnoreGuiInset = true, ResetOnSpawn = false, DisplayOrder = 101 })
			fn41(ScreenGui2)

			genv.VxezeNT = Frame({
				Parent = ScreenGui2,
				AnchorPoint = v7,
				Position = udim2(1, -16, 0, 16),
				Size = udim2(0, 320, 1, -32),
				fn17(8, Enum.HorizontalAlignment.Right),
			})
		end

		vxezeUI.nt = genv.VxezeNT
		return ScreenGui
	end

	-- Display language. Text is translated where it is shown (labels, buttons, placeholders);
	-- the English strings stay the keys for configs, search and callbacks.
	-- Rules are {luaPattern, replacement}: %1 keeps a capture as is, @1 translates it too.
	local lang = {
		code = "en",
		dicts = {},
		upper = {},
		rules = {},
		cache = {},
		names = {en = "English"},
		order = {"en"},
		orig = setmetatable({}, {__mode = "k"}),
		shown = setmetatable({}, {__mode = "k"}),
		ph = setmetatable({}, {__mode = "k"}),
		guis = {},
		viUp = {},
	}

	do
		local pairs_ = "àÀáÁảẢãÃạẠăĂằẰắẮẳẲẵẴặẶâÂầẦấẤẩẨẫẪậẬèÈéÉẻẺẽẼẹẸêÊềỀếẾểỂễỄệỆìÌíÍỉỈĩĨịỊòÒóÓỏỎõÕọỌôÔồỒốỐổỔỗỖộỘơƠờỜớỚởỞỡỠợỢùÙúÚủỦũŨụỤưƯừỪứỨửỬữỮựỰỳỲýÝỷỶỹỸỵỴđĐ"
		local prev

		for _, cp in utf8.codes(pairs_) do
			local ch = utf8.char(cp)

			if prev then
				lang.viUp[prev] = ch
				prev = nil
			else
				prev = ch
			end
		end
	end

	-- string.upper only knows ASCII; section headers are shown in capitals.
	local function langUpper(s)
		return (s:upper():gsub(utf8.charpattern, function(ch)
			return lang.viUp[ch] or ch
		end))
	end

	local function tr(text)
		local code = lang.code

		if code == "en" or type(text) ~= "string" or text == "" or not text:find("%a") then
			return text
		end

		local cache = lang.cache[code]

		if not cache then
			cache = {n = 0}
			lang.cache[code] = cache
		end

		local hit = cache[text]

		if hit then
			return hit
		end

		local dict = lang.dicts[code] or {}
		local out = dict[text]

		if not out then
			local lead, core, trail = text:match("^(%s*)(.-)(%s*)$")
			local found = dict[core] or (lang.upper[code] or {})[core]

			if found then
				out = lead .. found .. trail
			else
				for _, rule in ipairs(lang.rules[code] or {}) do
					local caps = {core:match(rule[1])}

					if caps[1] ~= nil then
						out = lead .. (rule[2]:gsub("([%%@])(%d)", function(mark, i)
							local cap = tostring(caps[tonumber(i)] or "")
							return mark == "@" and tr(cap) or cap
						end)) .. trail
						break
					end
				end
			end
		end

		out = out or text

		if cache.n > 4000 then
			cache = {n = 0}
			lang.cache[code] = cache
		end

		cache[text] = out
		cache.n = cache.n + 1
		return out
	end

	-- Player content (chat bubbles, pinned notice, mailbox) is never translated.
	local langSkip = {ChatRow = true, PinnedNotice = true, MailboxEntry = true}

	local function langSkipped(inst)
		if inst:GetAttribute("NoTr") then
			return true
		end

		local p = inst.Parent

		while p do
			if langSkip[p.Name] or p:GetAttribute("NoTr") then
				return true
			end
			p = p.Parent
		end

		return false
	end

	local function langApply(inst)
		local en = lang.orig[inst]

		if en then
			local out = tr(en)

			if inst.Text ~= out then
				lang.shown[inst] = out
				inst.Text = out
			end
		end

		local ph = lang.ph[inst]

		if ph then
			local out = tr(ph)

			if inst.PlaceholderText ~= out then
				inst.PlaceholderText = out
			end
		end
	end

	local function langAttach(inst)
		if inst:IsA("GuiBase2d") then
			pcall(function()
				-- Roblox's own auto-translation would translate the hub a second time.
				inst.AutoLocalize = false
			end)
		end

		local isBox = inst:IsA("TextBox")

		if not (isBox or inst:IsA("TextLabel") or inst:IsA("TextButton")) or langSkipped(inst) then
			return
		end

		if isBox then
			lang.ph[inst] = inst.PlaceholderText

			inst:GetPropertyChangedSignal("PlaceholderText"):Connect(function()
				if inst.PlaceholderText ~= tr(lang.ph[inst]) then
					lang.ph[inst] = inst.PlaceholderText
					langApply(inst)
				end
			end)
		else
			lang.orig[inst] = inst.Text

			inst:GetPropertyChangedSignal("Text"):Connect(function()
				if inst.Text == lang.shown[inst] then
					return
				end
				lang.orig[inst] = inst.Text
				langApply(inst)
			end)
		end

		langApply(inst)
	end

	local function langWatch(gui)
		if not gui or lang.guis[gui] then
			return
		end

		lang.guis[gui] = true
		langAttach(gui)

		for _, inst in ipairs(gui:GetDescendants()) do
			langAttach(inst)
		end

		gui.DescendantAdded:Connect(langAttach)
	end

	-- The Roblox language setting picks the default ("vi-vn" -> "vi").
	local function langFromGame()
		local LocalizationService = fn("LocalizationService")
		local id = ""

		pcall(function()
			id = LocalizationService.RobloxLocaleId

			if id == "" then
				id = LocalizationService.SystemLocaleId
			end
		end)

		local code = tostring(id):lower():match("^(%a%a)")
		return (code and lang.dicts[code]) and code or "en"
	end

	tbl6.T = function(arg, text)
		return tr(text)
	end

	tbl6.AddTranslations = function(arg, code, dict, rules, name)
		local d = lang.dicts[code]

		if not d then
			d = {}
			lang.dicts[code] = d
			lang.upper[code] = {}
			lang.rules[code] = {}
			lang.order[#lang.order + 1] = code
		end

		lang.names[code] = name or lang.names[code] or code

		for k, v in next, dict or {} do
			d[k] = v
			lang.upper[code][k:upper()] = langUpper(v)
		end

		for _, rule in ipairs(rules or {}) do
			table.insert(lang.rules[code], rule)
		end

		lang.cache[code] = nil

		if lang.code == code then
			for inst in next, lang.orig do
				langApply(inst)
			end
		end
	end

	tbl6.Languages = function()
		local out = {}

		for i, code in ipairs(lang.order) do
			out[i] = {code, lang.names[code]}
		end

		return out
	end

	tbl6.Language = function()
		return lang.code
	end

	-- code = nil or "" follows the game language. The choice is kept in _state.json.
	tbl6.SetLanguage = function(arg, code, save)
		local choice = code or ""
		code = choice ~= "" and lang.dicts[choice] and choice or (choice == "en" and "en") or langFromGame()

		if save ~= false then
			tbl6.State.Lang = choice
			tbl6:Persist()
		end

		if code == lang.code then
			return
		end

		lang.code = code

		for inst in next, lang.orig do
			langApply(inst)
		end

		for inst in next, lang.ph do
			langApply(inst)
		end

		if tbl6.W and tbl6.W.langCard then
			tbl6.W.langCard()
		end
	end

	tbl6.WatchLanguage = function(arg, gui)
		langWatch(gui)
	end

	tbl6.Window = function(arg, arg2)
		arg2 = arg2 or {}
		local w = {Tabs = {}, Key = arg2.Key or Enum.KeyCode.RightControl, us = 1, open = true}
		local v8 = fn42(w, tostring(arg2.Id or "Vxeze Hub"))
		w.Gui = v8
		local n3 = 832
		local n4 = 510
		w.dim = Frame({Parent = v8, Size = v, BackgroundColor3 = color(0, 0, 0)})

		pcall(function()
			w.dim.Interactable = false
		end)

		w.dz = 0.6

		local v9 = Frame({
			Parent = v8,
			Active = true,
			ZIndex = 3,
			AnchorPoint = v3,
			Position = v2,
			Size = fn2(n3, n4),
		})

		w.Main = v9
		local UIScale = fn7("UIScale", {Parent = v9})

		local CanvasGroup = fn7("CanvasGroup", {
			Parent = v9,
			Position = fn2(-3, -3),
			Size = udim2(1, 6, 1, 6),
			BackgroundTransparency = 1,
			Visible = false,
		})

		local v10 = Frame({Parent = v9, Size = v})

		w.bg = Frame({
			Parent = v10,
			Size = v,
			BackgroundTransparency = 0.05,
			fn12(16),
			fn14(tbl.w1, tbl.w2, 90),
		})

		w.tone = Frame({Parent = v10, Size = v, BackgroundColor3 = color(0, 0, 0), fn12(16)})

		w.Tint = function(arg3)
			local flag = state.Theme == "Black" and color(0, 0, 0)
			w.bg:FindFirstChildOfClass("UIGradient").Color = ColorSequence.new(flag or tbl.w1, flag or tbl.w2)
		end

		w.Tone = function(arg3, arg4)
			w.tone.BackgroundColor3 = arg4 < 0 and tbl.wh or color(0, 0, 0)
			w.tone.BackgroundTransparency = 1 - math.abs(arg4) / 100 * (arg4 < 0 and 0.22 or 0.65)
		end

		w:Tone(70)
		Frame2({Parent = v10, Size = udim2(1, 0, 0.55, 0), fn12(16), (fn15(90, {0, 0.86}, {1, 1}))})

		Frame2({
			Parent = v10,
			Position = fn2(20, 1),
			Size = udim2(1, -40, 0, 1),
			(fn15(0, {0, 1}, {0.5, 0.3}, {1, 1})),
		})

		local v11 = fn13(0.7)
		Frame({Parent = v10, Size = v, ZIndex = 5, fn12(16), v11})

		local function fn43()
			local viewportSize = workspace.CurrentCamera.ViewportSize
			local n5 = UserInputService.TouchEnabled and not UserInputService.KeyboardEnabled and 0.88 or 1
			return math.clamp(math.min((viewportSize.X - 60) / n3, (viewportSize.Y - 20) / n4), 0.55, 1.3) * w.us * n5
		end

		local function fn44()
			if w.open then
				fn19(UIScale, {Scale = fn43()}, 0.3)
			end
		end

		fn5(workspace.CurrentCamera:GetPropertyChangedSignal("ViewportSize"), fn44)

		w.SetScale = function(arg3, us)
			w.us = us
			fn44()
		end

		local v12 = TextButton({
			Parent = v8,
			AnchorPoint = v3,
			Position = udim2(0, 44, 0, 100 + w.slot * 60),
			Size = fn2(50, 50),
			BackgroundTransparency = 0.12,
			BackgroundColor3 = tbl.bg,
			Visible = false,
			fn12(18),
			(fn13(0.75)),
		})

		local UIScale2 = fn7("UIScale", {Parent = v12, Scale = 0})

		fn32(v12, {
			AnchorPoint = v3,
			Position = v2,
			Size = fn2(60, 60),
			ScaleType = Enum.ScaleType.Fit,
		})

		local v13 = fn28(vector2(), function(arg3)
			v9.Position = udim2(0.5, arg3.X, 0.5, arg3.Y)
		end)

		local v14 = fn28(vector2(44, 100 + w.slot * 60), function(arg3)
			v12.Position = udim2(0, arg3.X, 0, arg3.Y)
		end)

		local v15 = fn6()

		RunService:BindToRenderStep(v15, Enum.RenderPriority.Camera.Value + 1, function(arg3)
			fn29(v13, arg3)

			if v12.Visible then
				fn29(v14, arg3)
			end
		end)

		local v16 = TextButton({
			Parent = v10,
			Size = udim2(1, 0, 0, n),
			ClipsDescendants = true,
			(Frame({Size = udim2(1, 0, 1, 16), BackgroundTransparency = 0.95, (fn12(16))})),
		})

		fn18(v10, fn2(0, n), udim2(1, 0, 0, 1))

		fn32(v16, {
			AnchorPoint = v3,
			Position = udim2(0, n2 / 2, 0.5, 0),
			Size = fn2(46, 46),
			ScaleType = Enum.ScaleType.Fit,
		})

		local v17 = Frame({
			Parent = v16,
			Position = fn2(n2 + 6, 0),
			Size = udim2(1, -n2 - 345, 1, 0),
			ClipsDescendants = true,
			(fn17(10, nil, center3, horizontal)),
		})

		local tbl14 = {
			Parent = v17,
			Size = udim2(0, 0, 1, 0),
			AutomaticSize = x,
			Text = (arg2.Title or "Vxeze Hub"):upper(),
		}

		local v18
		v18, tbl14.FontFace = Enum, Font.new("rbxasset://fonts/families/Montserrat.json", Enum.FontWeight.Heavy)
		tbl14.TextSize = 22
		TextLabel(tbl14)

		TextLabel({
			Parent = v17,
			LayoutOrder = 1,
			Size = udim2(0, 0, 1, 0),
			AutomaticSize = x,
			Text = "/",
			TextSize = 13,
			TextTransparency = 0.6,
		})

		local v19 = TextLabel({
			Parent = v17,
			LayoutOrder = 2,
			Size = udim2(0, 0, 1, 0),
			AutomaticSize = x,
			Text = arg2.Game or "",
			TextSize = 13,
			TextTransparency = 0.3,
			TextTruncate = atEnd,
			(fn7("UISizeConstraint", {MaxSize = vector2(170, 99)})),
		})

		if arg2.Version then
			TextLabel({
				Parent = v17,
				LayoutOrder = 3,
				Size = fn2(0, 20),
				AutomaticSize = x,
				Text = arg2.Version,
				FontFace = font2,
				TextSize = 11,
				TextTransparency = 0.25,
				TextXAlignment = center,
				BackgroundTransparency = 0.9,
				fn12(),
				fn16(0, 8),
			})
		end

		local v20 = Frame2({Size = fn2(7, 7), BackgroundColor3 = tbl.sky, fn12()})

		local v21 = TextLabel({
			Size = fn2(0, 22),
			AutomaticSize = x,
			TextSize = 11,
			FontFace = font2,
			TextColor3 = tbl.val,
			LayoutOrder = 1,
			TextTruncate = atEnd,
			(fn7("UISizeConstraint", {MaxSize = vector2(200, 99)})),
		})

		local v22 = Frame({
			Parent = v17,
			LayoutOrder = 4,
			Size = fn2(0, 22),
			AutomaticSize = x,
			Visible = false,
			BackgroundTransparency = 0.9,
			BackgroundColor3 = tbl.sky,
			fn12(),
			fn16(0, 10),
			fn17(6, nil, center3, horizontal),
			v20,
			v21,
		})

		w.Status = function(arg3, text, arg4)
			local v23 = fn36(arg4)
			v22.Visible = text ~= nil and text ~= ""
			if v21.Text == text and v20.BackgroundColor3 == v23 then
				return
			end
			v21.Text = text or ""
			v20.BackgroundColor3 = v23
			v22.BackgroundColor3 = v23
		end

		if not arg2.Game then
			task.spawn(function()
				local ok, result = pcall(fn("MarketplaceService").GetProductInfo, fn("MarketplaceService"), game.PlaceId)
				v19.Text = ok and result and result.Name or ""
			end)
		end

		local v23 = TextButton({
			Parent = v16,
			AnchorPoint = v4,
			Position = udim2(1, -10, 0.5, 0),
			Size = fn2(26, 26),
			BackgroundTransparency = 0.92,
			fn12(9),
			fn13(0.86),
			(fn10("minus", 18)),
		})

		fn27(v23)
		local search = fn35({Parent = v16, AnchorPoint = v4, Position = udim2(1, -44, 0.5, 0), Size = fn2(128, 26)}, "Search")

		-- "Language: Name" card left of the search box; a tap opens the language list.
		local langLabel = TextLabel({
			Size = udim2(0, 0, 1, 0),
			AutomaticSize = x,
			FontFace = font2,
			TextSize = 11,
			TextTransparency = 0.1,
		})

		langLabel:SetAttribute("NoTr", true)

		local langBtn = TextButton({
			Parent = v16,
			AnchorPoint = v4,
			Position = udim2(1, -180, 0.5, 0),
			Size = fn2(0, 26),
			AutomaticSize = x,
			BackgroundTransparency = 0.92,
			fn12(9),
			fn13(0.86),
			fn16(0, 10),
			langLabel,
		})

		fn20(langBtn, 0.86, 0.92)

		local langList = Frame({
			Parent = v10,
			AnchorPoint = v7,
			Position = udim2(1, -180, 0, n - 2),
			Size = fn2(190, 0),
			AutomaticSize = y,
			Visible = false,
			ZIndex = 16,
			BackgroundTransparency = 0.02,
			BackgroundColor3 = tbl.pn,
			fn12(12),
			fn13(0.82),
			fn16(6),
			(fn17(2)),
		})

		local function langRows()
			fn37(langList)
			local choice = state.Lang or ""
			local rows = {{"", tr("Auto (game language)")}}

			for _, v40 in ipairs(tbl6:Languages()) do
				rows[#rows + 1] = v40
			end

			for i, row in ipairs(rows) do
				local on = row[1] == choice

				local v40 = TextButton({
					Parent = langList,
					LayoutOrder = i,
					Size = udim2(1, 0, 0, 32),
					ZIndex = 17,
					BackgroundTransparency = on and 0.86 or 1,
					BackgroundColor3 = on and tbl.a1 or tbl.wh,
					fn12(9),
					(TextLabel({
						Position = fn2(10, 0),
						Size = udim2(1, -36, 1, 0),
						ZIndex = 17,
						Text = row[2],
						FontFace = on and font2 or font,
						TextTransparency = on and 0 or 0.2,
					})),
				})

				v40:SetAttribute("NoTr", true)

				if on then
					fn10("check", 14, tbl.a1).Parent = v40
					v40:FindFirstChildOfClass("ImageLabel").Position = udim2(1, -16, 0.5, 0)
					v40:FindFirstChildOfClass("ImageLabel").ZIndex = 17
				else
					fn20(v40, 0.94)
				end

				fn25(v40, function()
					langList.Visible = false
					tbl6:SetLanguage(row[1])
				end)
			end
		end

		w.langCard = function()
			langLabel.Text = tr("Language") .. ": " .. (lang.names[lang.code] or lang.code)

			if langList.Visible then
				langRows()
			end
		end

		fn25(langBtn, function()
			langList.Visible = not langList.Visible

			if langList.Visible then
				langRows()
			end
		end)

		w.langCard()
		local v24 = Frame

		local tbl15 = {
			Parent = v10,
			Position = fn2(0, n + 1),
			Size = udim2(0, n2, 1, -n - 1),
			ClipsDescendants = true,
		}

		local tbl16
		tbl15[1] = Frame({Position = fn2(0, -16), Size = udim2(1, 16, 1, 16), BackgroundTransparency = 0.95, (fn12(16))})
		local v25 = v24(tbl15)
		fn18(v25, udim2(1, -1, 0, 0), udim2(0, 1, 1, 0))

		local v26 = Frame({
			Parent = v25,
			AnchorPoint = v3,
			Position = udim2(0.5, 0, 0, 29),
			Size = fn2(38, 38),
			BackgroundTransparency = 0.82,
			fn12(12),
			(fn13(0.68)),
		})

		local UIScale3 = fn7("UIScale", {Parent = v26})

		local v27 = ScrollingFrame({
			Parent = v25,
			ZIndex = 2,
			Position = fn2(0, 8),
			Size = udim2(1, 0, 1, -60),
			ScrollBarThickness = 0,
			fn16(2, 0),
			(fn17(4, center2)),
		})

		fn9({
			Parent = v25,
			AnchorPoint = vector2(0.5, 1),
			Position = udim2(0.5, 0, 1, -10),
			Size = fn2(32, 32),
			Image = fn11(48),
			BackgroundTransparency = 0,
			BackgroundColor3 = tbl.a2,
			(fn12()),
		})

		local v28 = TextLabel({
			Parent = v10,
			Position = fn2(n2 + 18, n + 9),
			Size = udim2(1, -n2 - 36, 0, 26),
			FontFace = font2,
			TextSize = 20,
		})

		local v29

		local v30 = Frame({
			Parent = v10,
			Position = fn2(n2, n + 41),
			Size = udim2(1, -n2, 1, -n - 49),
			ClipsDescendants = true,
		})

		fn30(v16, v13, function(arg3)
			local viewportSize = workspace.CurrentCamera.ViewportSize
			local absoluteSize = v9.AbsoluteSize
			local n5 = viewportSize.X / 2 + absoluteSize.X / 2 - 90
			local n6 = viewportSize.Y / 2 + absoluteSize.Y / 2 - 60
			return vector2(math.clamp(arg3.X, -n5, n5), math.clamp(arg3.Y, -n6, n6))
		end)

		local v31 = fn30(v12, v14, function(arg3)
			local viewportSize = workspace.CurrentCamera.ViewportSize
			return vector2(math.clamp(arg3.X, 30, viewportSize.X - 30), math.clamp(arg3.Y, 30, viewportSize.Y - 30))
		end)

		local v32 = TextButton({
			Parent = v10,
			AnchorPoint = vector2(1, 1),
			Position = udim2(1, -3, 1, -3),
			Size = fn2(22, 22),
			ZIndex = 6,
		})

		for _, v33 in ipairs({{14, 11}, {7, 16}}) do
			Frame2({
				Parent = v32,
				AnchorPoint = v3,
				Position = fn2(v33[2], v33[2]),
				Size = fn2(v33[1], 2),
				Rotation = -45,
				BackgroundTransparency = 0.4,
				ZIndex = 6,
				fn12(),
			})
		end

		fn5(v32.InputBegan, function(arg3)
			if not fn23(arg3) then
				return
			end
			local position = arg3.Position
			local v33 = vector2(v9.Size.X.Offset, v9.Size.Y.Offset)
			local scale = UIScale.Scale
			local connection
			local n5 = v13.p - v33 * scale / 2
			local v34
			v34, v9.AnchorPoint, v9.Position = udim2, vector2(), udim2(0.5, n5.X, 0.5, n5.Y)

			local function fn45(input)
				if input ~= arg3 and input.UserInputType ~= Enum.UserInputType.MouseMovement then
					return
				end
				local n6 = (input.Position - position) / scale
				local n7 = workspace.CurrentCamera.ViewportSize / scale
				v9.Size = fn2(math.clamp(v33.X + n6.X, n3, math.max(n3, n7.X - 40)), math.clamp(v33.Y + n6.Y, n4, math.max(n4, n7.Y - 20)))
			end

			local connection2 = UserInputService.InputChanged:Connect(fn45)

			local function fn46(input)
				if input == arg3 or input.UserInputType == Enum.UserInputType.MouseButton1 then
					connection2:Disconnect()
					connection:Disconnect()
					local t = n5 + vector2(v9.Size.X.Offset, v9.Size.Y.Offset) * scale / 2
					v9.AnchorPoint = v3
					v13.t = t
					v13.p = t
					v13.a(t)
				end
			end

			connection = UserInputService.InputEnded:Connect(fn46)
		end)

		local n5 = 0

		w.Show = function(arg3, open)
			w.open = open
			n5 += 1
			local v33 = n5
			local v34 = fn43()

			if v10.Parent ~= CanvasGroup then
				local v35
				v35, v10.Position, v10.Size = udim2, fn2(3, 3), udim2(1, -6, 1, -6)
				v10.Parent = CanvasGroup
				CanvasGroup.GroupTransparency = open and 1 or 0
			end

			UIScale.Scale = v34
			CanvasGroup.Visible = true
			v9.Visible = true
			fn19(w.dim, {BackgroundTransparency = open and 1 - w.dz or 1}, 0.3)
			fn19(CanvasGroup, {GroupTransparency = open and 0 or 1}, open and 0.28 or 0.18, Enum.EasingStyle.Sine, Enum.EasingDirection.Out)

			task.delay(open and 0.3 or 0.2, function()
				if n5 ~= v33 then
					return
				end
				CanvasGroup.Visible = false
				v10.Position = udim2()
				v10.Size = v
				v10.Parent = v9

				if not open then
					v9.Visible = false
				end
			end)

			if v12.Visible then
				UIScale2.Scale = 0.85
				fn19(UIScale2, {Scale = 1}, 0.3, back)
			else
				v12.Visible = true
				UIScale2.Scale = 0
				fn19(UIScale2, {Scale = 1}, 0.4, back)
			end
		end

		fn25(v23, function()
			w:Show(false)
		end)

		fn25(v12, function()
			if not v31() then
				w:Show(not w.open)
			end
		end)

		fn5(UserInputService.InputBegan, function(arg3, arg4)
			if not arg4 and arg3.KeyCode == w.Key then
				w:Show(not w.open)
			end
		end)

		local v33 = TextButton({
			Parent = v10,
			Size = v,
			BackgroundColor3 = color(5, 6, 16),
			ZIndex = 20,
			Visible = false,
			ClipsDescendants = true,
			fn12(16),
		})

		local v34 = TextButton({
			Parent = v33,
			AnchorPoint = v7,
			Position = udim2(1, 420, 0, 6),
			Size = udim2(0, 390, 1, -12),
			BackgroundTransparency = 0.02,
			BackgroundColor3 = tbl.pn,
			fn12(14),
			(fn13(0.84)),
		})

		local tbl17

		local v35 = TextLabel({
			Parent = v34,
			Position = fn2(18, 14),
			Size = udim2(1, -80, 0, 20),
			FontFace = font2,
			TextSize = 15,
		})

		local v36 = TextLabel({
			Parent = v34,
			Position = fn2(18, 34),
			Size = udim2(1, -80, 0, 14),
			TextSize = 11,
			TextTransparency = 0.32,
		})

		local selectAll

		v24, tbl17, v29 = TextButton({
			Parent = v34,
			AnchorPoint = v7,
			Position = udim2(1, -12, 0, 10),
			Size = fn2(40, 40),
			BackgroundTransparency = 0.92,
			fn12(12),
			(fn10("x", 22)),
		}), {Parent = v34, Position = fn2(14, 60)}, udim2

		tbl17.Size = v29(1, -28, 0, 40)
		tbl17.BackgroundTransparency = 0.93
		local filter = fn35(tbl17, "Filter")
		tbl17, v25, v32, tbl16, selectAll = {Parent = v34, Position = fn2(12, 108)}, fn16(3), fn7, {}, udim2
		tbl16.CellSize = selectAll(0.5, -5, 0, 44)
		tbl16.CellPadding = fn2(8, 8)
		tbl16.SortOrder = Enum.SortOrder.LayoutOrder
		tbl17[1], tbl17[2] = v25, v32("UIGridLayout", tbl16)
		local v37 = ScrollingFrame(tbl17)
		local clear

		local v38 = Frame({
			Parent = v34,
			AnchorPoint = vector2(0, 1),
			Position = udim2(0, 14, 1, -14),
			Size = udim2(1, -28, 0, 44),
		})

		tbl16, clear, selectAll = fn39(v38, "Default", 0, 3), fn39(v38, "Clear", 1, 3), fn39(v38, "Select all", 2, 3, true)

		w.Dialog = function(arg3, arg4)
			local tbl18 = arg4 or {}

			if w.dlg then
				w.dlg.Close()
			end

			if not w.open then
				w:Show(true)
			end

			local v39, v40 = fn36(tbl18.Kind)
			local UIScale4 = fn7("UIScale", {Scale = 0.9})
			local v41 = TextButton({Parent = v10, Size = v, BackgroundColor3 = color(5, 6, 16), ZIndex = 30, fn12(16)})

			local tbl19 = {
				Parent = v41,
				AnchorPoint = v3,
				Position = v2,
				Size = fn2(400, 0),
				AutomaticSize = y,
				BackgroundTransparency = 0.02,
				BackgroundColor3 = tbl.pn,
			}

			local v42 = fn12(18)
			local v43 = fn13(0.8)
			local v44 = fn16(22)
			local v45 = fn17(16)
			local tbl20 = {Size = udim2(1, 0, 0, 46)}

			local v46 = Frame({
				Size = fn2(46, 46),
				BackgroundTransparency = 0.8,
				BackgroundColor3 = v39,
				fn12(14),
				fn10(tbl18.Icon or v40, 24, v39),
			})

			local n6

			tbl20[1], tbl20[2] = v46, TextLabel({
				Position = fn2(60, 0),
				Size = udim2(1, -60, 1, 0),
				Text = tbl18.Title or "",
				FontFace = font2,
				TextSize = 17,
				TextWrapped = true,
			})

			tbl19[1], tbl19[2], tbl19[3], tbl19[4], tbl19[5], tbl19[6] = v42, v43, v44, v45, UIScale4, Frame(tbl20)
			local v47 = TextButton(tbl19)

			if tbl18.Text then
				TextLabel({
					Parent = v47,
					LayoutOrder = 1,
					Size = v5,
					AutomaticSize = y,
					Text = tbl18.Text,
					TextSize = 13,
					TextTransparency = 0.25,
					TextWrapped = true,
				})
			end

			local n7
			local v48 = Frame({Parent = v47, LayoutOrder = 2, Size = udim2(1, 0, 0, 42)})
			local dlg = {}

			dlg.Close = function(arg5)
				if w.dlg == dlg then
					w.dlg = nil
				end

				fn19(UIScale4, {Scale = 0.92}, 0.18)
				local v49 = fn19(v41, {BackgroundTransparency = 1}, 0.2)

				local function fn45()
					v41:Destroy()
				end

				v49.Completed:Connect(fn45)
				v47.Visible = false
				fn22(arg5)
			end

			local buttons = tbl18.Buttons or {{"OK"}}

			for i, button in ipairs(buttons) do
				tbl19, n6, n7 = button[1], i - 1, #buttons

				fn39(v48, tbl19, n6, n7, button[3]).Activated:Connect(function()
					if fn24() then
						dlg.Close(button[2])
					end
				end)
			end

			local function fn45()
				if tbl18.Cancel ~= false then
					dlg.Close(tbl18.Cancel)
				end
			end

			v41.Activated:Connect(fn45)
			w.dlg = dlg
			fn19(v41, {BackgroundTransparency = 0.45}, 0.2)
			fn19(UIScale4, {Scale = 1}, 0.35, back)
			return dlg
		end

		local function fn45(title, text, kind, arg3, arg4, arg5)
			w:Dialog({Title = title, Text = text, Kind = kind, Buttons = {{arg5 or "Cancel"}, {arg3, arg4, true}}})
		end

		local function fn46()
			tbl6:Save()
			tbl6:Notify("Config saved", state.Active, "ok")
		end

		local function fn47(arg3, arg4)
			tbl6:Notify(arg4, arg3 or "", pcall(setclipboard, arg3) and "ok" or "err")
		end

		fn27(v24)
		local tbl18 = {bt = {}, sel = {}}

		local function fn48()
			tbl18.open = false
			fn19(v33, {BackgroundTransparency = 1}, 0.22)

			fn21(fn19(v34, {Position = udim2(1, 540, 0, 6)}, 0.28, quint, Enum.EasingDirection.In), v33, function()
				return tbl18.open
			end)
		end

		local function fn49()
			for k, v39 in next, tbl18.bt do
				local flag = tbl18.sel[k] ~= nil
				fn19(v39[1], {BackgroundTransparency = flag and 0.72 or 0.93, BackgroundColor3 = flag and tbl.a1 or tbl.wh}, 0.18)
				fn19(v39[2], {Transparency = flag and 0.2 or 0.82, Color = flag and tbl.a1:Lerp(tbl.wh, 0.35) or tbl.wh}, 0.18)
				fn19(v39[3], {ImageTransparency = flag and 0 or 1}, 0.18)
			end
		end

		local function fn50()
			fn49()
			local tbl19 = {}

			for _, v39 in ipairs(tbl18.o) do
				if tbl18.sel[v39] then
					tbl19[#tbl19 + 1] = v39
				end
			end

			fn22(tbl18.d, tbl19)
		end

		w.Sync = function(arg3, arg4)
			if tbl18.open then
				if not (tbl18.ob == arg4) then
					return
				end
			else
				return
			end

			tbl18.sel = {}

			for _, v39 in ipairs(arg4.Multi and arg4.Value or {arg4.Value}) do
				tbl18.sel[v39] = true
			end

			fn49()
		end

		w.Pick = function(arg3, text, arg4, arg5, arg6, d, arg7, ob)
			tbl18.ob = ob
			v35.Text = text
			v36.Text = arg6 and "Pick any" or "Pick one"
			filter.Text = ""
			fn37(v37)
			local def = arg7 or {}
			tbl18.bt = {}
			tbl18.sel = {}
			tbl18.d = d
			tbl18.o = {}
			tbl18.def = def

			for _, v39 in ipairs(arg6 and arg5 or {arg5}) do
				tbl18.sel[v39] = true
			end

			local flag = type(arg4[1]) == "table"
			local v39
			v39, v37:FindFirstChildOfClass("UIGridLayout").CellSize = udim2, udim2(0.5, -5, 0, flag and 54 or 44)
			v34.Size = udim2(0, flag and 500 or 390, 1, -12)

			for i, v40 in ipairs(arg4) do
				local v41 = flag and v40.v or v40
				tbl18.o[i] = v41
				local v42 = fn13(0.82)
				local v43 = Frame({Parent = v37, LayoutOrder = i})

				local v44 = TextButton({
					Parent = v43,
					AnchorPoint = v3,
					Position = v2,
					Size = v,
					BackgroundTransparency = 0.93,
					fn12(13),
					v42,
				})

				if flag then
					Frame({
						Parent = v44,
						Position = fn2(5, 5),
						Size = fn2(44, 44),
						BackgroundTransparency = 0.72,
						BackgroundColor3 = v40.col or tbl.a1,
						fn12(12),
						fn13(0.6, v40.col),
						(ImageLabel({
							AnchorPoint = v3,
							Position = v2,
							Size = udim2(1, 2, 1, 2),
							Image = v40.img or "",
							ScaleType = Enum.ScaleType.Fit,
						})),
					})

					TextLabel({
						Parent = v44,
						Position = fn2(56, 3),
						Size = udim2(1, -60, 0, 28),
						Text = v40.t or tostring(v41),
						FontFace = font3,
						TextSize = 17,
						TextTruncate = atEnd,
					})

					local v45 = Frame({
						Parent = v44,
						Position = fn2(57, 32),
						Size = udim2(1, -90, 0, 17),
						ClipsDescendants = true,
						(fn17(6, nil, center3, horizontal)),
					})

					local v46 = TextLabel({
						Parent = v45,
						Size = udim2(0, 0, 1, 0),
						AutomaticSize = x,
						Text = (v40.sub or ""):upper(),
						FontFace = font5,
						TextSize = 12.5,
						TextColor3 = v40.grad and tbl.wh or v40.col or tbl.val,
						(fn7("UIStroke", {Thickness = 1.2, Color = color(0, 0, 0)})),
					})

					if v40.grad then
						v40.grad:Clone().Parent = v46
					end

					if v40.note then
						local v47 = TextLabel({
							Parent = v45,
							LayoutOrder = 1,
							Size = udim2(1, -6, 1, 0),
							Text = v40.note,
							FontFace = font2,
							TextSize = 12.5,
							RichText = true,
							TextTruncate = atEnd,
							(fn7("UIStroke", {Thickness = 1.2, Color = color(0, 0, 0)})),
						})

						local function fn51()
							v47.Size = udim2(1, -v46.AbsoluteSize.X - 6, 1, 0)
						end

						v46:GetPropertyChangedSignal("AbsoluteSize"):Connect(fn51)
						fn51()
					end
				else
					TextLabel({
						Parent = v44,
						Position = fn2(14, 0),
						Size = udim2(1, -40, 1, 0),
						Text = tostring(v41),
						FontFace = font2,
						TextSize = 12,
						TextWrapped = true,
						LineHeight = 0.95,
					})
				end

				tbl18.bt[v41] = {
					v44,
					v42,
					fn9({
						Parent = v44,
						AnchorPoint = flag and vector2(1, 1) or v4,
						Position = flag and udim2(1, -9, 1, -8) or udim2(1, -12, 0.5, 0),
						Size = fn2(18, 18),
						Image = "check",
						ImageTransparency = 1,
					}),
					v43,
					((tostring(v41) .. " " .. (flag and (v40.t or "") .. " " .. (v40.sub or "") .. " " .. (v40.note or "") or "")):lower()),
				}

				fn27(v44, 0.95)

				fn25(v44, function()
					if arg6 then
						tbl18.sel[v41] = not tbl18.sel[v41] or nil
						fn50()
					else
						tbl18.sel = {[v41] = true}
						fn49()
						fn48()
						fn22(d, v41)
					end
				end)
			end

			v38.Visible = arg6 == true
			v37.Size = udim2(1, -24, 1, arg6 and -176 or -120)
			fn49()
			tbl18.open = true
			v33.Visible = true
			fn19(v33, {BackgroundTransparency = 0.45}, 0.25)
			fn19(v34, {Position = udim2(1, -6, 0, 6)}, 0.45)
		end

		fn5(filter:GetPropertyChangedSignal("Text"), function()
			local str2 = filter.Text:lower()

			for _, v39 in next, tbl18.bt do
				v39[4].Visible = v39[5]:find(str2, 1, true) ~= nil
			end
		end)

		fn25(v24, fn48)
		fn25(v33, fn48)

		local function fn51(arg3)
			tbl18.sel = {}

			for _, v39 in ipairs(arg3) do
				tbl18.sel[v39] = true
			end

			fn50()
		end

		fn25(tbl16, function()
			fn51(tbl18.def)
		end)

		fn25(clear, function()
			fn51({})
		end)

		fn25(selectAll, function()
			fn51(tbl18.o)
		end)

		local function fn52(arg3)
			return 29 + (arg3.i - 1) * 42 - v27.CanvasPosition.Y
		end

		fn5(v27:GetPropertyChangedSignal("CanvasPosition"), function()
			if w.Cur then
				v26.Position = udim2(0.5, 0, 0, fn52(w.Cur))
			end
		end)

		local function fn53(arg3, parent, layoutOrder)
			layoutOrder = Frame({Parent = parent, LayoutOrder = layoutOrder, Size = v5, AutomaticSize = y, (fn17(16))})
			local v39 = Frame({Parent = layoutOrder, LayoutOrder = 1, Size = v5, AutomaticSize = y, (fn17(16, nil, nil, horizontal))})
			arg3.cols = {}
			arg3.list = {}
			arg3.crow = layoutOrder

			for i = 1, 2 do
				arg3.cols[i] = Frame({
					Parent = v39,
					LayoutOrder = i,
					Size = udim2(0.5, -8, 0, 0),
					AutomaticSize = y,
					(fn17(16)),
				})
			end

			arg3.cols[3] = Frame({
				Parent = layoutOrder,
				LayoutOrder = 2,
				Size = udim2(0.5, -8, 0, 0),
				AutomaticSize = y,
				Visible = false,
				(fn17(16)),
			})

			arg3.cols[4] = Frame({Parent = layoutOrder, LayoutOrder = 0, Size = v5, AutomaticSize = y, Visible = false, (fn17(16))})
		end

		local function fn54(arg3, arg4)
			local chip = arg3.on and arg3.on.chip

			if chip then
				if chip.AbsoluteSize.X == 0 then
					return
				end
			else
				return
			end

			local tbl19 = {
				Position = fn2((chip.AbsolutePosition.X - arg3.row.AbsolutePosition.X) / UIScale.Scale, 0),
				Size = fn2(chip.AbsoluteSize.X / UIScale.Scale, 24),
			}

			if arg4 then
				arg3.hl.Position, arg3.hl.Size = tbl19.Position, tbl19.Size
			else
				fn19(arg3.hl, tbl19, 0.38)
			end
		end

		local function fn55(arg3, on)
			if arg3.on == on then
				return
			end
			arg3.on = on

			for _, sub in ipairs(arg3.subs) do
				fn19(sub.chip, {TextTransparency = sub == on and 0 or 0.5}, 0.2)
			end

			fn54(arg3)
		end

		local function fn56(arg3)
			if os.clock() < (arg3.lock or 0) then
				return
			end
			local scale = UIScale.Scale
			local y2 = arg3.sc.AbsolutePosition.Y
			local n6 = arg3.sc.AbsoluteCanvasSize.Y - arg3.sc.AbsoluteWindowSize.Y
			local v39 = arg3.subs[1]

			for _, sub in ipairs(arg3.subs) do
				v39 = if sub.g.AbsolutePosition.Y - y2 <= 40 * scale then sub else v39
			end

			fn55(arg3, if n6 > 0 then if arg3.sc.CanvasPosition.Y >= n6 - 2 then arg3.subs[#arg3.subs] else v39 else v39)
		end

		local function fn57(arg3, arg4, arg5)
			local n6 = arg3.CanvasPosition.Y + arg4.AbsolutePosition.Y - arg3.AbsolutePosition.Y - arg5 * UIScale.Scale

			fn19(arg3, {
				CanvasPosition = vector2(0, math.clamp(n6, 0, math.max(0, arg3.AbsoluteCanvasSize.Y - arg3.AbsoluteWindowSize.Y))),
			}, 0.45)
		end

		local function fn58(arg3, arg4)
			arg3.lock = os.clock() + 0.5
			fn57(arg3.sc, arg4.g, 4)
			fn55(arg3, arg4)
		end

		w.Select = function(arg3, cur)
			local cur2 = w.Cur
			if cur2 == cur then
				return
			end
			search.Text = ""
			w.Cur = cur

			for _, v39 in ipairs(cur.subs or {}) do
				fn40(v39)
			end

			if cur.list then
				fn40(cur)
			end

			for _, tab in ipairs(w.Tabs) do
				if tab.bar then
					tab.bar.Visible = tab == cur
					task.defer(fn54, tab, true)
				end

				fn19(tab.im, {ImageTransparency = tab == cur and 0 or 0.45}, 0.3)
			end

			fn19(v26, {Position = udim2(0.5, 0, 0, fn52(cur))}, 0.42)
			UIScale3.Scale = 0.86
			fn19(UIScale3, {Scale = 1}, 0.5, back)
			local n6 = cur2 and (cur2.i > cur.i and -1 or 1) or 0

			if cur2 then
				cur2.k = cur2.k + 1
				local k = cur2.k

				fn21(fn19(cur2.fr, {Position = udim2(-n6, 0, 0, 0)}, 0.5), cur2.fr, function()
					return cur2.k ~= k or w.Cur == cur2
				end)
			end

			cur.k = cur.k + 1

			if not cur.fr.Visible then
				local v39
				v39, cur.fr.Position = udim2, udim2(n6, 0, 0, 0)
			end

			cur.fr.Visible = true
			fn19(cur.fr, {Position = udim2()}, 0.5)
			v28.Text = cur.Title or cur.Name
			v28.Position = fn2(n2 + 18 + n6 * 24, n + 9)
			v28.TextTransparency = 0.7
			fn19(v28, {Position = fn2(n2 + 18, n + 9), TextTransparency = 0}, 0.45)
		end

		w.nest = {}

		w.Grip = function(arg3, gf, parent)
			local function fn59()
				return gf.AbsoluteCanvasSize.Y / math.max(gf.AbsoluteWindowSize.Y, 1)
			end

			fn30(TextButton({
				Parent = parent,
				AnchorPoint = v7,
				Position = udim2(1, 0, 0, 0),
				Size = udim2(0, 14, 1, 0),
				ZIndex = 8,
				Visible = not UserInputService.TouchEnabled,
			}), setmetatable({}, {
				__index = function()
					return vector2(0, gf.CanvasPosition.Y / fn59())
				end,
				__newindex = function(arg4, arg5, arg6)
					w.goal = math.clamp(arg6.Y * fn59(), 0, math.max(0, gf.AbsoluteCanvasSize.Y - gf.AbsoluteWindowSize.Y))
					w.gf = gf
					gf.CanvasPosition = vector2(0, w.goal)
				end,
			}), function(arg4)
				return arg4
			end)
		end

		w.Tab = function(arg3, name, image, arg4)
			local top = {Name = name, W = w, Secs = {}, i = #w.Tabs + 1, k = 0}
			top.top = top
			top.fr = Frame({Parent = v30, Size = v, Visible = false})

			if arg4 then
				top.sc = Frame({Parent = top.fr, Size = v, fn16(6, 16, 6)})
			else
				top.sc = ScrollingFrame({
					Parent = top.fr,
					Size = v,
					ScrollingEnabled = UserInputService.TouchEnabled,
					ScrollBarThickness = 3,
					ScrollBarImageColor3 = tbl.wh,
					ScrollBarImageTransparency = 0.7,
					ElasticBehavior = Enum.ElasticBehavior.Always,
					fn16(4, 0, 12),
					(fn17(12, center2)),
				})

				top.g = Frame({Parent = top.sc, Size = udim2(1, -36, 0, 0), AutomaticSize = y})

				fn5(top.sc.InputChanged, function(arg5)
					if arg5.UserInputType == Enum.UserInputType.MouseWheel then
						w:Wheel(arg5.Position.Z)
					end
				end)

				w:Grip(top.sc, top.fr)

				fn5(top.sc.MouseWheelForward, function()
					w:Wheel(1)
				end)

				fn5(top.sc.MouseWheelBackward, function()
					w:Wheel(-1)
				end)

				fn53(top, top.g, 0)
				top.subs = {}
			end

			local v39 = TextButton({Parent = v27, Size = fn2(38, 38), LayoutOrder = top.i})

			top.im = fn9({
				Parent = v39,
				AnchorPoint = v3,
				Position = v2,
				Size = fn2(24, 24),
				Image = image or "grid",
				ImageTransparency = 0.45,
			})

			fn27(top.im, 0.8, v39, function(arg5)
				if w.Cur == top then
					fn19(UIScale3, {Scale = arg5 and 0.9 or 1}, arg5 and 0.12 or 0.45, arg5 and quint or back)
				end
			end)

			fn25(v39, function()
				w:Select(top)
			end)

			w.Tabs[top.i] = top

			top.Section = function(arg5, arg6, arg7, arg8)
				return index.new(top, arg6, arg7, arg8)
			end

			top.Arrange = function(arg5, arg6)
				for i, v40 in ipairs(arg6) do
					for i2, v41 in ipairs(v40) do
						for _, sec in ipairs(arg5.Secs) do
							if sec.name == v41 then
								sec.side, sec.card.LayoutOrder = i, i2
							end
						end
					end
				end

				arg5.done = -1
				fn40(arg5)
			end

			top.Sub = function(arg5, text)
				local tbl19 = {
					Name = name .. " / " .. text,
					W = w,
					Secs = top.Secs,
					i = #top.subs + 1,
					sc = top.sc,
					top = top,
				}

				if #top.subs == 0 then
					top.g.Visible = #top.Secs > 0

					top.bar = Frame({
						Parent = v10,
						AnchorPoint = v7,
						Position = udim2(1, -18, 0, n + 7),
						Size = fn2(0, 30),
						AutomaticSize = x,
						Visible = w.Cur == top,
						BackgroundTransparency = 0.95,
						fn12(),
						fn13(0.88),
						(fn16(3)),
					})

					top.hl = Frame({Parent = top.bar, Size = fn2(0, 24), BackgroundTransparency = 0.84, fn12()})

					top.row = Frame({
						Parent = top.bar,
						Size = fn2(0, 24),
						AutomaticSize = x,
						ZIndex = 2,
						(fn17(4, nil, center3, horizontal)),
					})

					fn5(top.row:GetPropertyChangedSignal("AbsoluteSize"), function()
						fn54(top, true)
					end)

					fn5(top.sc:GetPropertyChangedSignal("CanvasPosition"), function()
						fn56(top)
					end)
				end

				local v40 = TextButton({
					Size = udim2(1, 0, 0, 18),
					(TextLabel({
						Size = udim2(1, -30, 1, 0),
						Text = text:upper(),
						FontFace = font3,
						TextSize = 12,
						TextTransparency = 0.35,
					})),
				})

				local v41 = fn9({
					Parent = v40,
					AnchorPoint = v3,
					Position = udim2(1, -9, 0.5, 0),
					Size = fn2(13, 13),
					Image = "down",
					ImageTransparency = 0.55,
				})

				tbl19.g = Frame({
					Parent = top.sc,
					LayoutOrder = tbl19.i,
					Size = udim2(1, -36, 0, 0),
					AutomaticSize = y,
					fn17(12),
					v40,
				})

				fn53(tbl19, tbl19.g, 1)

				fn25(v40, function()
					tbl19.crow.Visible = not tbl19.crow.Visible
					fn19(v41, {Rotation = tbl19.crow.Visible and 0 or -90}, 0.25)
				end)

				tbl19.chip = TextButton({
					Parent = top.row,
					LayoutOrder = tbl19.i,
					Size = fn2(0, 24),
					AutomaticSize = x,
					Text = text,
					FontFace = font2,
					TextSize = 12,
					TextColor3 = tbl.wh,
					TextTransparency = 0.5,
					BackgroundTransparency = 1,
					fn12(),
					fn16(0, 12),
				})

				fn25(tbl19.chip, function()
					fn58(top, tbl19)
				end)

				tbl19.Go = function(arg6)
					if not w.open then
						w:Show(true)
					end

					w:Select(top)
					task.delay(0.15, fn58, top, tbl19)
				end

				top.subs[tbl19.i] = tbl19

				tbl19.Section = function(arg6, arg7, arg8, arg9)
					return index.new(tbl19, arg7, arg8, arg9)
				end

				tbl19.Arrange = top.Arrange

				if tbl19.i == 1 then
					fn55(top, tbl19)
				end

				return tbl19
			end

			if not w.Cur then
				w:Select(top)
			end

			return top
		end

		w.All = {}

		local v39 = Frame({
			Parent = v10,
			AnchorPoint = v7,
			Position = udim2(1, -44, 0, n - 4),
			Size = fn2(300, 0),
			AutomaticSize = y,
			Visible = false,
			ZIndex = 15,
			BackgroundTransparency = 0.02,
			BackgroundColor3 = tbl.pn,
			fn12(12),
			fn13(0.82),
			fn16(6),
			(fn17(2)),
		})

		local function fn59(arg3)
			search.Text = ""
			w:Select(arg3.tab)

			task.delay(0.55, function()
				fn57(arg3.tab.sc, arg3.r, 40)
				arg3.r.BackgroundTransparency = 0.8
				fn19(arg3.r, {BackgroundTransparency = 1}, 1.4)
			end)
		end

		fn5(search:GetPropertyChangedSignal("Text"), function()
			local str2 = search.Text:lower()
			fn37(v39)
			v39.Visible = str2 ~= ""
			if str2 == "" then
				return
			end
			local all = w.All
			local n6 = 0

			for _, v40 in ipairs(all) do
				if n6 < 8 and (v40.n:find(str2, 1, true) or tr(v40.title):lower():find(str2, 1, true)) then
					local layoutOrder = n6 + 1

					local v41 = TextButton({
						Parent = v39,
						LayoutOrder = layoutOrder,
						Size = udim2(1, 0, 0, 42),
						fn12(9),
						TextLabel({
							Position = fn2(10, 4),
							Size = udim2(1, -20, 0, 18),
							Text = v40.title,
							FontFace = font2,
							TextTruncate = atEnd,
						}),
						(TextLabel({
							Position = fn2(10, 22),
							Size = udim2(1, -20, 0, 15),
							Text = v40.path,
							TextSize = 11,
							TextTransparency = 0.45,
							TextTruncate = atEnd,
						})),
					})

					fn20(v41, 0.92)

					local function fn60()
						if fn24() then
							fn59(v40)
						end
					end

					v41.Activated:Connect(fn60)
					n6 = layoutOrder
				end
			end

			if n6 == 0 then
				TextLabel({
					Parent = v39,
					Size = udim2(1, 0, 0, 32),
					Text = "No results",
					TextTransparency = 0.45,
					TextXAlignment = center,
				})
			end
		end)

		w.Home = function(arg3, arg4)
			local tbl19 = arg4 or {}
			local v40 = w:Tab(tbl19.Name or "Home", tbl19.Icon or "home", true)
			v40.Title = tbl19.Title or "Dashboard"
			local v41 = Frame({Parent = v40.sc, Position = fn2(-6, -6), Size = udim2(1, 12, 1, 12)})

			local function fn60(arg5, arg6, arg7, arg8, backgroundTransparency, backgroundColor3, arg9)
				return Frame({
					Parent = v41,
					Position = udim2(arg5, 6, arg6, 6),
					Size = udim2(arg7, -12, arg8, -12),
					BackgroundTransparency = backgroundTransparency or 0.93,
					BackgroundColor3 = backgroundColor3 or tbl.wh,
					fn12(18),
					(fn13(arg9 or 0.86, backgroundColor3 and backgroundColor3:Lerp(tbl.wh, 0.5))),
				})
			end

			local function fn61(parent, arg5, image, imageColor3)
				fn9({Parent = parent, Position = fn2(14, 13), Size = fn2(14, 14), Image = image, ImageColor3 = imageColor3})

				return TextLabel({
					Parent = parent,
					Position = fn2(34, 12),
					Size = udim2(1, -48, 0, 16),
					Text = arg5:upper(),
					FontFace = font3,
					TextSize = 11.5,
					TextTransparency = 0.15,
				})
			end

			local v42 = fn60(0, 0, 0.6666666666666666, 0.3, 0.55)
			fn14(color(255, 196, 120), color(150, 110, 255)).Parent = v42

			fn9({
				Parent = v42,
				Position = udim2(0, 16, 0.5, -28),
				Size = fn2(56, 56),
				Image = fn11(150),
				BackgroundTransparency = 0,
				BackgroundColor3 = tbl.a2,
				fn12(),
				(fn13(0.4)),
			})

			TextLabel({
				Parent = v42,
				Position = udim2(0, 86, 0.5, -34),
				Size = udim2(1, -100, 0, 14),
				Text = "Welcome back",
				TextSize = 11,
				TextTransparency = 0.25,
			})

			TextLabel({
				Parent = v42,
				Position = udim2(0, 86, 0.5, -19),
				Size = udim2(1, -100, 0, 24),
				Text = localPlayer.DisplayName,
				FontFace = font2,
				TextSize = 21,
				TextTruncate = atEnd,
			})

			local v43 = Frame({
				Parent = v42,
				Position = udim2(0, 86, 0.5, 10),
				Size = udim2(1, -100, 0, 20),
				(fn17(6, nil, nil, horizontal)),
			})

			local executor = tbl19.Executor or identifyexecutor and select(2, pcall(identifyexecutor))

			for i, v44 in ipairs({{tbl19.Game}, {type(executor) == "string" and executor}, {tbl19.Key, tbl.mint}}) do
				if v44[1] then
					TextLabel({
						Parent = v43,
						LayoutOrder = i,
						Size = udim2(0, 0, 1, 0),
						AutomaticSize = x,
						Text = tostring(v44[1]),
						TextSize = 11,
						TextColor3 = v44[2] and v44[2]:Lerp(tbl.wh, 0.6),
						BackgroundTransparency = v44[2] and 0.8 or 0.75,
						BackgroundColor3 = v44[2] or color(0, 0, 0),
						TextXAlignment = center,
						fn12(),
						(fn16(0, 10)),
					})
				end
			end

			local notice = tbl19.Notice
			local v44 = fn60(0.6666666666666666, 0, 0.3333333333333333, 0.3, 0.78, notice and tbl.a1 or tbl.dc, 0.55)

			Frame2({
				Parent = v44,
				Position = fn2(14, 14),
				Size = fn2(36, 36),
				BackgroundColor3 = notice and tbl.a1 or tbl.dc,
				fn12(11),
				fn10(notice and "sparkles" or "discord", 22),
			})

			TextLabel({
				Parent = v44,
				Position = fn2(60, 15),
				Size = udim2(1, -72, 0, 17),
				Text = notice and notice[1] or tbl19.Community or "Community",
				FontFace = font2,
				TextSize = 14,
				TextTruncate = atEnd,
			})

			if notice then
				TextLabel({
					Parent = v44,
					Position = fn2(14, 58),
					Size = udim2(1, -28, 1, -70),
					Text = notice[2],
					TextSize = 11,
					TextTransparency = 0.22,
					TextWrapped = true,
					TextYAlignment = Enum.TextYAlignment.Top,
				})
			else
				TextLabel({
					Parent = v44,
					Position = fn2(60, 33),
					Size = udim2(1, -72, 0, 14),
					Text = "Updates, keys, support",
					TextSize = 11,
					TextTransparency = 0.22,
				})

				local v45 = TextButton({
					Parent = v44,
					AnchorPoint = vector2(0, 1),
					Position = udim2(0, 14, 1, -12),
					Size = udim2(1, -28, 0, 32),
					BackgroundTransparency = 0,
					BackgroundColor3 = tbl.dc,
					Text = "Copy invite",
					FontFace = font2,
					TextSize = 12,
					TextColor3 = tbl.wh,
					(fn12(10)),
				})

				fn27(v45)

				fn25(v45, function()
					fn47(tbl19.Discord, "Invite copied")
				end)
			end

			local TeleportService = fn("TeleportService")

			local actions = tbl19.Actions or {
				{
					"Rejoin",
					"refresh",
					function()
						fn45("Rejoin this server?", "You leave and join this same server again.", "warn", "Rejoin", function()
							TeleportService:TeleportToPlaceInstance(game.PlaceId, game.JobId, localPlayer)
						end)
					end,
				},
				{
					"Server hop",
					"server",
					function()
						fn45("Hop to another server?", "You leave this server and join a different one.", "warn", "Hop", function()
							if tbl19.Hop then
								tbl19.Hop()
							else
								TeleportService:Teleport(game.PlaceId, localPlayer)
							end
						end)
					end,
				},
				{
					"Copy Job ID",
					"copy",
					function()
						fn47(game.JobId, "Job ID copied")
					end,
				},
				tbl19.Unload and {"Unload hub", "trash", tbl19.Unload} or {"Save config", "save", fn46},
				tbl19.Switch or tbl19.Discord and {
					"Discord",
					"discord",
					function()
						fn47(tbl19.Discord, "Discord invite copied")
					end,
				} or {
					"Hide UI",
					"eye",
					function()
						w:Show(false)
					end,
				},
			}

			local v45 = Frame({
				Parent = v41,
				Position = udim2(0, 6, 0.3, 6),
				Size = udim2(1, -12, 0.16, -12),
				(fn17(12, nil, nil, horizontal)),
			})

			for i, action in ipairs(actions) do
				local v46 = tbl3[(i - 1) % 5 + 1]

				local v47 = TextButton({
					Parent = Frame({Parent = v45, LayoutOrder = i, Size = udim2(1 / #actions, 12 / #actions - 12, 1, 0)}),
					AnchorPoint = v3,
					Position = v2,
					Size = v,
					BackgroundTransparency = 0.94,
					fn12(14),
					fn13(0.88),
					Frame({
						Position = udim2(0, 10, 0.5, -15),
						Size = fn2(30, 30),
						BackgroundTransparency = 0.82,
						BackgroundColor3 = v46,
						fn12(9),
						(fn10(action[2], 16, v46)),
					}),
					(TextLabel({
						Position = fn2(48, 0),
						Size = udim2(1, -54, 1, 0),
						Text = action[1],
						TextSize = 12,
						TextWrapped = true,
					})),
				})

				fn27(v47, 0.95)

				fn25(v47, function()
					fn22(action[3])
				end)
			end

			local v46 = fn60(0, 0.46, 0.6666666666666666, 0.54)
			local session = fn61(v46, "Session", "clock", tbl.gold)
			local v47 = fn60(0.6666666666666666, 0.46, 0.3333333333333333, 0.54)
			fn61(v47, "What's new", "sparkles", tbl.pink)

			local v48 = ScrollingFrame({
				Parent = v47,
				Position = fn2(14, 40),
				Size = udim2(1, -24, 1, -50),
				fn16(1, 4, 4, 1),
				(fn17(10)),
			})

			local tbl20 = {}

			local function fn62(arg5)
				local n6 = math.max(os.time() - arg5, 0)

				for _, v49 in ipairs({{86400, "day"}, {3600, "hour"}, {60, "minute"}}) do
					local n7 = n6 // v49[1]
					if n7 >= 1 then
						return ("%d %s%s ago"):format(n7, v49[2], n7 > 1 and "s" or "")
					end
				end

				return "just now"
			end

			tbl20.News = function(arg5, list)
				tbl20.list = list
				fn37(v48)

				for i, v49 in ipairs(list) do
					local v50 = Frame({
						Position = fn2(44, 0),
						Size = udim2(1, -44, 0, 0),
						AutomaticSize = y,
						fn17(2),
						(TextLabel({Size = v5, AutomaticSize = y, Text = v49[2], TextSize = 12, TextWrapped = true})),
					})

					if v49[3] or v49[4] then
						local v51 = Frame({Parent = v50, LayoutOrder = 1, Size = udim2(1, 0, 0, 14), (fn17(5, nil, center3, horizontal))})

						if v49[3] then
							TextLabel({
								Parent = v51,
								Size = udim2(0, 0, 1, 0),
								AutomaticSize = x,
								Text = v49[3],
								FontFace = font4,
								TextSize = 10,
								TextTransparency = 0.4,
							})
						end

						if v49[4] then
							local v52 = Frame({
								Parent = v51,
								LayoutOrder = 1,
								Size = udim2(0, 0, 1, 0),
								AutomaticSize = x,
								BackgroundTransparency = 0.9,
								fn12(),
								fn16(0, 6),
								(fn17(3, nil, center3, horizontal)),
							})

							fn9({Parent = v52, Size = fn2(10, 10), Image = "clock", ImageTransparency = 0.3})

							TextLabel({
								Parent = v52,
								LayoutOrder = 1,
								Size = udim2(0, 0, 1, 0),
								AutomaticSize = x,
								Text = fn62(v49[4]),
								FontFace = font4,
								TextSize = 10,
								TextTransparency = 0.3,
							})
						end
					end

					Frame({
						Parent = v48,
						LayoutOrder = i,
						Size = v5,
						AutomaticSize = y,
						v50,
						TextLabel({
							Size = fn2(0, 18),
							AutomaticSize = x,
							Text = v49[1],
							FontFace = font4,
							TextSize = 9,
							TextColor3 = color(16, 20, 42),
							BackgroundTransparency = 0,
							BackgroundColor3 = ({NEW = tbl.mint, FIX = tbl.sky, IMP = tbl.gold, UPD = tbl.red})[v49[1]] or tbl.vio,
							TextXAlignment = center,
							fn12(5),
							fn16(0, 6),
						}),
					})
				end
			end

			tbl20.Stats = function(arg5, arg6, arg7)
				session.Text = arg6:upper()

				local v49 = Frame({
					Parent = v46,
					Position = fn2(12, 38),
					Size = udim2(1, -24, 1, -48),
					(fn7("UIGridLayout", {
						CellSize = udim2(0.3333333333333333, -7, 0.333, -6),
						CellPadding = fn2(10, 8),
						SortOrder = Enum.SortOrder.LayoutOrder,
					})),
				})

				local tbl21 = {}

				for i, v50 in ipairs(arg7) do
					local v51 = Frame({Parent = v49, LayoutOrder = i, BackgroundTransparency = 0.94, fn12(12)})

					if v50[2] then
						fn9({
							Parent = v51,
							AnchorPoint = vector2(0, 0.5),
							Position = udim2(0, 8, 0.5, 0),
							Size = fn2(30, 30),
							Image = v50[2],
							ScaleType = Enum.ScaleType.Fit,
							ImageColor3 = tbl5[v50[2]] and tbl.a1 or nil,
						})
					end

					local n6 = v50[2] and 44 or 10

					TextLabel({
						Parent = v51,
						Position = udim2(0, n6, 0.5, -17),
						Size = udim2(1, -n6 - 6, 0, 13),
						Text = v50[1]:upper(),
						FontFace = font3,
						TextSize = 9.5,
						TextTransparency = 0.38,
					})

					tbl21[v50[1]] = TextLabel({
						Parent = v51,
						Position = udim2(0, n6, 0.5, -2),
						Size = udim2(1, -n6 - 6, 0, 18),
						Text = "--",
						FontFace = font4,
						TextSize = 13.5,
						TextTruncate = atEnd,
					})

					if v50[3] then
						local v52 = TextButton({
							Parent = v51,
							AnchorPoint = vector2(1, 0),
							Position = udim2(1, -8, 0, 8),
							Size = fn2(40, 16),
							Text = "OPEN",
							FontFace = font3,
							TextSize = 9,
							TextColor3 = tbl.wh,
							BackgroundTransparency = 0.82,
							BackgroundColor3 = tbl.wh,
							fn12(),
							(fn13(0.7)),
						})

						fn27(v52, 0.92)

						fn25(v52, function()
							fn22(v50[3])
						end)
					end
				end

				return fn38(tbl21)
			end

			if tbl19.News then
				tbl20:News(tbl19.News)
			end

			return tbl20
		end

		local function fn60(arg3, arg4, arg5)
			return type(arg3) == "table" and arg3 or w:Tab(arg3 or arg4, arg5)
		end

		w.Settings = function(arg3, arg4)
			local settings_ = fn60(arg4, "Settings", "settings")
			local Interface = settings_:Section("Interface", "sliders")

			Interface:Slider("UI scale", 60, 140, 100, function(arg5)
				w:SetScale(arg5 / 100)
			end, "%", 5)

			local function fn61(key)
				w.Key = key
			end

			Interface:Key("Show / hide UI", w.Key, nil, fn61)

			Interface:Slider("Opacity", 50, 100, 95, function(arg5)
				w.bg.BackgroundTransparency = 1 - arg5 / 100
			end, "%")

			Interface:Slider("Tone", -100, 100, 70, function(arg5)
				w:Tone(arg5)
			end, "", 5)

			Interface:Slider("Dim the game", 0, 80, 60, function(arg5)
				w.dz = arg5 / 100

				if w.open then
					w.dim.BackgroundTransparency = 1 - w.dz
				end
			end, "%", 5)

			local Theme = settings_:Section("Theme", "palette")
			local tbl19 = {Parent = Theme.f, LayoutOrder = 2, Name = "VxezeThemes", Size = v5, AutomaticSize = y}
			local v40 = fn16(2, 14, 14)
			local v41

			tbl19[1], tbl19[2] = v40, fn7("UIGridLayout", {
				CellSize = udim2(0.25, -8, 0, 62),
				CellPadding = fn2(10, 10),
				SortOrder = Enum.SortOrder.LayoutOrder,
			})

			local v42 = Frame(tbl19)
			Theme.n = Theme.n + 1
			local marks = {}

			for i, v43 in ipairs(tbl2) do
				local v44 = fn13(0.86)
				local tbl20 = {Parent = v42, LayoutOrder = i, BackgroundTransparency = 0.95}
				local v45 = fn12(12)
				local tbl21 = {Position = fn2(6, 6)}
				local v46
				tbl21.Size = udim2(1, -12, 0, 30)
				tbl21.BackgroundTransparency = 0
				v46, Theme, tbl19, i, v41 = fn12(8), fn14(v43[2], v43[4], 20), Frame, {AnchorPoint = vector2(0, 1)}, udim2
				i.Position = v41(0, 6, 1, -5)
				i.Size = udim2(0.45, 0, 0, 6)
				i.BackgroundTransparency = 0
				i.BackgroundColor3 = v43[5]
				i[1] = fn12()
				tbl21[1], tbl21[2], tbl21[3] = v46, Theme, tbl19(i)

				tbl20[1], tbl20[2], tbl20[3], tbl20[4] = v45, v44, Frame(tbl21), TextLabel({
					Position = fn2(8, 40),
					Size = udim2(1, -26, 0, 16),
					Text = v43[1],
					FontFace = font2,
					TextSize = 11,
					TextTruncate = atEnd,
				})

				v46, v45, i = TextButton(tbl20), v43[1], {}

				i[1], i[2] = v44, fn9({
					Parent = v46,
					AnchorPoint = v4,
					Position = udim2(1, -8, 0, 48),
					Size = fn2(12, 12),
					Image = "check",
					ImageColor3 = v43[5],
					ImageTransparency = 1,
				})

				marks[v45] = i
				fn27(v46, 0.95)

				fn25(v46, function()
					tbl6:Theme(v43[1])
				end)
			end

			w.marks = marks
			local Defaults = settings_:Section("Defaults", "refresh")

			Defaults:Button("Reset to defaults", "Reset", function()
				fn45("Reset every option?", "All options go back to their built-in values and your active config is saved that way.", "warn", "Reset", function()
					tbl6:Reset()
					tbl6:Notify("Reset", "Every option is back to its default", "ok")
				end)
			end, "danger")

			Defaults:Button("Turn off all toggles", "Turn off", function()
				tbl6:Notify("Toggles off", tbl6:Off() .. " switched off", "ok")
			end)

			return settings_
		end

		w.Config = function(arg3, arg4)
			local config = fn60(arg4, "Config", "save")
			local Config = config:Section("Config", "folder")
			local v40 = Config:Stats({"Active", "Saved configs"})
			local config2

			local function fn61()
				v40:Set("Active", state.Active)
				v40:Set("Saved configs", tostring(#tbl6:Configs()))

				if config2 then
					config2:Set(state.Active, true)
				end
			end

			local function fn62(arg5, arg6, arg7, arg8)
				local v41 = arg5:Dropdown(arg6, function()
					return tbl6:Configs()
				end, nil, function(arg9)
					if arg9 and arg7 then
						arg7(arg9)
					end
				end, arg8)

				v41.Skip = true
				return v41
			end

			config2 = fn62(Config, "Config", function(arg5)
				if arg5 ~= state.Active then
					tbl6:Notify("Config picked", arg5 .. " - press Set active to load it", "info")
				end
			end)

			Config:Button("Set as active config", "Set active", function()
				local value = config2.Value
				if not value then
					return tbl6:Notify("Nothing picked", "Choose a config first", "warn")
				end

				if tbl6:Load(value) then
					fn61()
					tbl6:Notify("Active config", value, "ok")
				end
			end, "gold")

			Config:Button("Save changes", "Save", fn46)

			Config:Toggle("Auto load", state.AutoLoad, function(autoLoad)
				if state.AutoLoad ~= autoLoad then
					tbl6:Notify("Auto load " .. (autoLoad and "on" or "off"), autoLoad and state.Active .. " loads every time Vxeze Hub starts" or "Vxeze Hub starts with its default options", "info")
				end

				state.AutoLoad = autoLoad
				tbl6:Persist()
			end).Skip = true

			Config:Toggle("Auto save", state.AutoSave, function(autoSave)
				if state.AutoSave == autoSave then
					return
				end
				state.AutoSave = autoSave
				tbl6:Persist()

				if autoSave then
					tbl6:Save()
				end

				tbl6:Notify("Auto save " .. (autoSave and "on" or "off"), autoSave and "Every change is saved to " .. state.Active or "Press Save changes to keep your options", "info")
			end).Skip = true

			local Profiles = config:Section("Profiles", "copy")
			local v41 = Profiles:Input("New config name", "Auto if empty")
			v41.Skip = true

			Profiles:Button("Create config", "Create", function()
				local v42, v43 = tbl6:Name(v41.Value)
				if not v42 then
					return tbl6:Notify("Config not created", v43, "err")
				end
				tbl6:Save(v42)
				state.Active = v42
				tbl6:Persist()
				v41:Set("", true)
				fn61()
				tbl6:Notify("Config created", v42 .. " is now the active config", "ok")
			end, "gold")

			local pickToDelete = fn62(Profiles, "Pick to delete", nil, true)

			Profiles:Button("Delete picked", "Delete", function()
				local tbl19 = {}
				local flag = false

				for _, v42 in ipairs(pickToDelete.Value) do
					if v42:lower() == "default" then
						flag = true
					else
						tbl19[#tbl19 + 1] = v42
					end
				end

				if #tbl19 == 0 then
					return tbl6:Notify("Nothing to delete", "Pick configs other than Default", "warn")
				end

				fn45("Delete " .. #tbl19 .. " config(s)?", table.concat(tbl19, ", ") .. (flag and "\nDefault is kept." or ""), "err", "Delete", function()
					for _, v42 in ipairs(tbl19) do
						tbl6:Delete(v42)
					end

					pickToDelete:Set({}, true)
					fn61()
					tbl6:Notify(#tbl19 .. " config(s) deleted", table.concat(tbl19, ", "), "ok")
				end)
			end, "danger")

			local v42

			v42 = Profiles:Dropdown("Restore deleted", function()
				return tbl6:Trash()
			end, nil, function(arg5)
				if not arg5 then
					return
				end
				local v43 = tbl6:Restore(arg5)
				v42:Set(nil, true)
				fn61()
				tbl6:Notify(v43 and "Config restored" or "Restore failed", v43 or arg5, v43 and "ok" or "err")
			end)

			v42.Skip = true

			fn62(Profiles, "Export config", function(arg5)
				local ok = pcall(setclipboard, tbl6:Export(arg5))
				tbl6:Notify(ok and "Config copied" or "Copy failed", ok and arg5 .. " is on your clipboard" or "This executor cannot copy text", ok and "ok" or "err")

				w:Dialog({
					Title = ok and "Config copied" or "Copy failed",
					Kind = ok and "ok" or "err",
					Text = ok and arg5 .. " is on your clipboard. Paste it to share it, then load it with Import config." or "This executor cannot copy text.",
				})
			end)

			local v43 = Profiles:Input("Import text", "Paste config text")
			v43.Skip = true

			Profiles:Button("Import config", "Import", function()
				local v44, v45 = tbl6:Import(v43.Value)
				if not v44 then
					return tbl6:Notify("Import failed", v45, "err")
				end
				v43:Set("", true)

				fn45("Config imported", v44 .. " was added to your configs. Apply it now?", "ok", "Apply now", function()
					tbl6:Load(v44)
					fn61()
					tbl6:Notify("Config loaded", v44, "ok")
				end, "Later")

				tbl6:Notify("Config imported", v44 .. " was added to your configs", "ok")
			end, "gold")

			fn61()
			return config
		end

		w.Quick = function(arg3, arg4, arg5)
			local tbl19 = {pins = {}, keys = {}, at = {}, fold = {}}
			local tbl20 = {show = false, keys = true, size = 1}
			local tbl21 = {Value = ""}
			local tbl22 = {}
			local tbl23 = {}
			local tbl24 = {}
			local tbl25, fn61
			local n6 = 0
			local tbl26

			local function fn62(arg6)
				local tr = tbl26.tr
				tbl26.o:Set(tbl26.o.From(math.clamp((arg6.Position.X - tr.AbsolutePosition.X) / tr.AbsoluteSize.X, 0, 1)), false, true)
			end

			local function fn63(arg6)
				return tbl6.Keys[arg6].Name
			end

			local function fn64(arg6)
				local tbl27 = {}
				local n7 = -#fn63(arg6) - 2
				local str2 = ""

				for match in arg6:sub(1, n7):gmatch("[^/]+") do
					match = match:match("^%s*(.-)%s*$")

					if match:lower() ~= str2 then
						str2, tbl27[#tbl27 + 1] = match:lower(), match
					end
				end

				return table.concat(tbl27, "  /  ")
			end

			local function fn65(arg6)
				local v40 = tbl19.keys[arg6]
				return v40 and (tbl4[v40] or v40)
			end

			local function fn66(parent, scale, arg6)
				local UIScale4 = scale and fn7("UIScale", {Parent = parent})
				local backgroundTransparency = parent.BackgroundTransparency

				local function fn67(input)
					if fn23(input) then
						fn19(UIScale4 or parent, UIScale4 and {Scale = scale} or {BackgroundTransparency = backgroundTransparency - 0.06}, 0.12)
					end
				end

				parent.InputBegan:Connect(fn67)

				local function fn68(input)
					if fn23(input) then
						fn19(UIScale4 or parent, UIScale4 and {Scale = 1} or {BackgroundTransparency = backgroundTransparency}, 0.35)
					end
				end

				parent.InputEnded:Connect(fn68)

				local function fn69()
					if fn24() then
						arg6()
					end
				end

				parent.Activated:Connect(fn69)
			end

			local function fn67(arg6, arg7, arg8)
				local descendants = arg6:GetDescendants()
				descendants[#descendants + 1] = arg6

				for _, descendant in ipairs(descendants) do
					local tbl27 = {}

					if descendant:IsA("GuiObject") then
						tbl27.BackgroundTransparency = descendant.BackgroundTransparency
					end

					if descendant:IsA("TextLabel") then
						tbl27.TextTransparency = descendant.TextTransparency
					elseif descendant:IsA("TextButton") then
						tbl27.TextTransparency = descendant.TextTransparency
					elseif descendant:IsA("TextBox") then
						tbl27.TextTransparency = descendant.TextTransparency
					end

					if descendant:IsA("ImageLabel") then
						tbl27.ImageTransparency = descendant.ImageTransparency
					end

					if descendant:IsA("UIStroke") then
						tbl27.Transparency = descendant.Transparency
					end

					local tbl28 = {}

					for k in next, tbl27 do
						tbl28[k] = 1
					end

					if arg7 then
						for k in next, tbl27 do
							descendant[k] = 1
						end

						fn19(descendant, tbl27, 0.3, nil, nil, arg8)
					else
						fn19(descendant, tbl28, 0.26, quint, Enum.EasingDirection.In, arg8)
					end
				end

				if not arg7 then
					arg6.Active = false
					fn19(arg6, {Position = arg6.Position + fn2(0, 26)}, 0.3, quint, Enum.EasingDirection.In, arg8)
					task.delay(0.32 + arg8, arg6.Destroy, arg6)
				end
			end

			local function fn68()
				for i, v40 in ipairs(w.All) do
					local str2 = v40.k:sub(1, -#v40.title - 2)
					tbl24[str2], tbl24[v40.k] = tbl24[str2] or i, tbl24[v40.k] or i
				end

				local tbl27 = {}

				for k, v40 in next, tbl6.Keys do
					if v40.Kind then
						tbl27[#tbl27 + 1] = k
					end
				end

				table.sort(tbl27, function(arg6, arg7)
					local n7 = (tbl24[arg6:sub(1, -#fn63(arg6) - 2)] or 1000000000) * 10000 + (tbl24[arg6] or 0)
					local n8 = (tbl24[arg7:sub(1, -#fn63(arg7) - 2)] or 1000000000) * 10000 + (tbl24[arg7] or 0)
					if n7 == n8 then
						return arg6 < arg7
					end
					return n7 < n8
				end)

				return tbl27
			end

			local function fn69()
				tbl21:Set(HttpService:JSONEncode(tbl19), true)
			end

			local function fn70()
				tbl19 = {pins = {}, keys = {}, at = {}, fold = {}}
				local v40 = table.pack(fn68())

				for _, v41 in ipairs(table.unpack(v40, 1, v40.n)) do
					for _, v42 in ipairs(arg5 or {}) do
						if v41:sub(-#v42) == v42 then
							tbl19.pins[v41] = 1
						end
					end
				end
			end

			local function fn71()
				for _, v40 in ipairs(tbl23) do
					local v41 = table.find(v40[1].ls, v40[2])

					if v41 then
						table.remove(v40[1].ls, v41)
					end
				end

				table.clear(tbl23)

				for i, v40 in ipairs(tbl22) do
					fn67(v40.f, false, (i - 1) * 0.05)
				end

				table.clear(tbl22)

				if fn61 then
					fn61()
				end

				if not tbl20.show then
					return
				end
				local viewportSize = workspace.CurrentCamera.ViewportSize
				local v40 = fn68()
				local n7 = 220
				local scale = math.clamp(viewportSize.Y / 720, 0.75, 1.2) * tbl20.size
				local n8 = 0

				for i = 1, 5 do
					local tbl27 = {}
					local id = tostring(i)

					for _, v41 in ipairs(v40) do
						if tbl19.pins[v41] == i then
							tbl27[#tbl27 + 1] = v41
						end
					end

					if #tbl27 > 0 then
						n8 += 1
						local tbl28
						local UIScale4 = fn7("UIScale", {Scale = scale})
						local v41 = fn17(5)
						local v42

						local v43 = Frame({
							LayoutOrder = 1,
							Size = v5,
							AutomaticSize = y,
							ClipsDescendants = true,
							fn16(0, 7, 7),
							v41,
						})

						local v44 = udim2
						local v45

						local v46 = fn9({
							AnchorPoint = v3,
							Position = v44(1, -17, 0.5, 0),
							Size = fn2(12, 12),
							Image = "down",
							ImageTransparency = 0.4,
							Rotation = tbl19.fold[id] and -90 or 0,
						})

						local tbl29
						local tbl30 = {Size = udim2(1, 0, 0, 34)}
						v42, tbl29, v44 = fn9({Position = fn2(12, 10), Size = fn2(14, 14), Image = "zap", ImageColor3 = tbl3[i]}), {Position = fn2(33, 0)}, udim2
						tbl29.Size = v44(1, -90, 1, 0)
						tbl29.Text = "QUICK BAR " .. i
						tbl29.FontFace = font3
						tbl29.TextSize = 11
						local v47 = TextLabel(tbl29)
						local v48

						tbl30[1], tbl30[2], tbl30[3], tbl30[4] = v46, v42, v47, TextLabel({
							AnchorPoint = v4,
							Position = udim2(1, -32, 0.5, 0),
							Size = fn2(0, 16),
							AutomaticSize = x,
							Text = #tbl27,
							FontFace = font2,
							TextSize = 9.5,
							TextXAlignment = center,
							BackgroundTransparency = 0.88,
							fn12(),
							(fn16(0, 6)),
						})

						tbl29, v48, tbl28, v45 = TextButton(tbl30), Frame, {
							Parent = w.Gui,
							AnchorPoint = vector2(0.5, 0),
							Size = fn2(n7, 0),
							AutomaticSize = y,
							BackgroundTransparency = 0.06,
							Active = true,
							ZIndex = 2,
						}, fn17

						tbl28[1], tbl28[2], tbl28[3], tbl28[4], tbl28[5], tbl28[6], tbl28[7] = fn12(16), fn14(tbl.w1, tbl.w2, 90), fn13(0.74), UIScale4, v45(), tbl29, v43
						local v49 = v48(tbl28)
						local v50 = n8
						local b = {f = v49, u = UIScale4, id = id}

						b.place = function(arg6, scale2)
							local v51 = tbl19.at[id]
							v51 = v51 and vector2(v51[1], v51[2]) or vector2(arg6.X - 18 - n7 * scale2 / 2 - (v50 - 1) * (n7 * scale2 + 12), math.max(arg6.Y * 0.023, 8))
							b.sp.t = vector2(math.clamp(v51.X, 40, arg6.X - 40), math.clamp(v51.Y, 0, arg6.Y - 40))
							UIScale4.Scale = scale2
						end

						b.sp = fn28(vector2(), function(arg6)
							v49.Position = udim2(0, arg6.X, 0, arg6.Y)
						end)

						b.place(viewportSize, scale)
						b.sp.p = b.sp.t + vector2(0, 14)
						tbl22[#tbl22 + 1] = b

						if tbl19.fold[id] then
							v43.AutomaticSize = Enum.AutomaticSize.None
							v43.Size = v5
						end

						tbl29.InputBegan:Connect(function(input)
							if fn23(input) then
								tbl25 = tbl25 or {b = b, i = input, s = vector2(input.Position.X, input.Position.Y), p = b.sp.t}
							end
						end)

						fn66(tbl29, nil, function()
							tbl19.fold[id] = not tbl19.fold[id] or nil
							local v51 = tbl19.fold[id]
							local n9 = v41.AbsoluteContentSize.Y / math.max(v49.AbsoluteSize.X / n7, 0.01) + 7
							local v52
							v52, v43.AutomaticSize, v43.Size = udim2, Enum.AutomaticSize.None, udim2(1, 0, 0, v51 and n9 or 0)
							fn19(v46, {Rotation = v51 and -90 or 0}, 0.3)

							fn19(v43, {Size = udim2(1, 0, 0, v51 and 0 or n9)}, 0.32).Completed:Connect(function()
								if not tbl19.fold[id] then
									v43.AutomaticSize = y
								end
							end)

							fn69()
						end)

						for i2, v51 in ipairs(tbl27) do
							local v52 = tbl6.Keys[v51]
							local v53 = fn65(v51)
							local fn72
							local kind = v52.Kind

							local v54 = TextButton({
								Parent = v43,
								LayoutOrder = i2,
								Size = udim2(1, 0, 0, kind == "slider" and 46 or 34),
								BackgroundTransparency = 0.93,
								(fn12(11)),
							})

							local v55 = Frame({Parent = v54, Size = v, fn12(11), fn14(tbl.a1, tbl.a2)})
							local v56

							local tbl31 = {
								Parent = v54,
								AnchorPoint = v7,
								Position = udim2(1, -9, 0, 6),
								Size = fn2(160, 22),
								ZIndex = 2,
							}

							local v57 = fn17
							local tbl32
							tbl31[1] = v57(6, Enum.HorizontalAlignment.Right, center3, horizontal)
							v56, tbl32, v57 = Frame(tbl31), {Parent = v54, Position = fn2(11, 6)}, udim2
							tbl32.Size = v57(1, -(kind == "button" and 96 or kind == "input" and 132 or 60) - (v53 and 44 or 0), 0, 22)
							tbl32.Text = fn63(v51)
							tbl32.FontFace = font2
							tbl32.TextSize = 12.5
							tbl32.TextTruncate = atEnd
							tbl32.ZIndex = 2
							TextLabel(tbl32)

							if v53 then
								TextLabel({
									Parent = v56,
									Size = fn2(0, 18),
									AutomaticSize = x,
									Text = v53,
									FontFace = font4,
									TextSize = 10,
									TextXAlignment = center,
									BackgroundTransparency = 0.86,
									fn12(6),
									fn16(0, 6),
								})
							end

							if kind == "toggle" then
								local v58 = fn33(Frame({Parent = v56, LayoutOrder = 1, Size = fn2(38, 20)}), 38, 20)

								fn72 = function(arg6, arg7)
									v58(arg6, arg7)

									if arg7 then
										v55.BackgroundTransparency = arg6 and 0.78 or 1
									else
										fn19(v55, {BackgroundTransparency = arg6 and 0.78 or 1}, 0.25)
									end
								end

								fn66(v54, nil, function()
									tbl6.qb = true
									v52:Set(not v52.Value)
									tbl6.qb = nil
								end)
							elseif kind == "button" then
								local v58 = TextLabel({
									Parent = v56,
									LayoutOrder = 1,
									Size = fn2(0, 22),
									AutomaticSize = x,
									Text = v52.Text,
									FontFace = font2,
									TextSize = 11,
									TextColor3 = v52.Col:Lerp(tbl.wh, 0.55),
									BackgroundTransparency = 0.85,
									BackgroundColor3 = v52.Col,
									fn12(8),
									fn16(0, 10),
									fn13(0.5, v52.Col),
								})

								fn66(v54, nil, function()
									v52.Fire()
									v58.BackgroundTransparency = 0.5
									fn19(v58, {BackgroundTransparency = 0.85}, 0.5)
								end)
							elseif kind == "input" then
								local v58 = TextBox({
									Parent = v56,
									LayoutOrder = 1,
									Size = fn2(116, 24),
									BackgroundTransparency = 0.7,
									BackgroundColor3 = color(0, 0, 0),
									PlaceholderText = "Type here",
									TextSize = 11.5,
									TextTruncate = atEnd,
									ClipsDescendants = true,
									fn12(7),
									fn16(0, 7),
									fn13(0.8),
								})

								local function fn73()
									v52:Set(v58.Text)
								end

								v58.FocusLost:Connect(fn73)

								fn72 = function(arg6)
									if not v58:IsFocused() then
										v58.Text = tostring(arg6 or "")
									end
								end
							else
								local v58 = TextLabel({
									Parent = v56,
									LayoutOrder = 1,
									Size = fn2(0, 22),
									AutomaticSize = x,
									FontFace = font4,
									TextSize = 11,
									TextColor3 = tbl.val,
								})

								local v59 = Frame({
									Parent = v54,
									Position = udim2(0, 11, 1, -13),
									Size = udim2(1, -22, 0, 5),
									BackgroundTransparency = 0.86,
									ZIndex = 2,
									(fn12()),
								})

								local v60 = Frame2({Parent = v59, Size = udim2(0, 0, 1, 0), fn12(), (fn14(tbl.a1, tbl.a2))})

								local v61 = Frame2({
									Parent = v59,
									AnchorPoint = v3,
									Position = udim2(0, 0, 0.5, 0),
									Size = fn2(13, 13),
									ZIndex = 3,
									fn12(),
									(fn13(0.65, color(0, 0, 0))),
								})

								fn72 = function(arg6, arg7)
									local n9 = math.clamp(v52.Frac(arg6), 0, 1)
									fn19(v60, {Size = udim2(n9, 0, 1, 0)}, arg7 and 0 or 0.1)
									fn19(v61, {Position = udim2(n9, 0, 0.5, 0)}, arg7 and 0 or 0.1)
									v58.Text = v52.Txt(arg6)
								end

								v54.InputBegan:Connect(function(input)
									if fn23(input) then
										tbl26 = {o = v52, tr = v59, i = input}
										tbl10.s = true
										fn62(input)
									end
								end)
							end

							if fn72 then
								fn72(v52.Value, true)
								v52.ls[#v52.ls + 1] = fn72
								tbl23[#tbl23 + 1] = {v52, fn72}
							end
						end

						b.sp.a(b.sp.p)
						fn67(v49, true, (n8 - 1) * 0.06)
					end
				end
			end

			local function fn72()
				n6 += 1
				local v40 = n6

				task.delay(0.15, function()
					if v40 == n6 then
						fn71()
					end
				end)
			end

			fn5(RunService.Heartbeat, function(arg6)
				for _, v40 in ipairs(tbl22) do
					fn29(v40.sp, arg6)
				end
			end)

			fn5(workspace.CurrentCamera:GetPropertyChangedSignal("ViewportSize"), function()
				local viewportSize = workspace.CurrentCamera.ViewportSize

				if viewportSize.X < 300 then
					return
				elseif viewportSize.Y < 200 then
					return
				end

				for _, v40 in ipairs(tbl22) do
					v40.place(viewportSize, math.clamp(viewportSize.Y / 720, 0.75, 1.2) * tbl20.size)
				end
			end)

			fn5(UserInputService.InputChanged, function(arg6)
				if tbl26 then
					if arg6 == tbl26.i then
						fn62(arg6)
					elseif tbl26.i.UserInputType == Enum.UserInputType.MouseButton1 and arg6.UserInputType == Enum.UserInputType.MouseMovement then
						fn62(arg6)
					end
				end

				if tbl25 then
					if arg6 ~= tbl25.i and arg6.UserInputType ~= Enum.UserInputType.MouseMovement then
						return
					end
				else
					return
				end

				local n7 = vector2(arg6.Position.X, arg6.Position.Y) - tbl25.s
				local viewportSize = tbl25
				viewportSize.mv = viewportSize.mv or n7.Magnitude > 6

				if tbl25.mv then
					viewportSize, arg6 = workspace.CurrentCamera.ViewportSize, tbl25.p + n7
					tbl25.b.sp.t = vector2(math.clamp(arg6.X, 40, viewportSize.X - 40), math.clamp(arg6.Y, 0, viewportSize.Y - 40))
				end
			end)

			fn5(UserInputService.InputEnded, function(arg6)
				if tbl26 then
					if arg6 == tbl26.i then
						tbl26 = nil
					elseif arg6.UserInputType == Enum.UserInputType.MouseButton1 then
						tbl26 = nil
					end
				end

				if tbl25 then
					if arg6 ~= tbl25.i and arg6.UserInputType ~= Enum.UserInputType.MouseButton1 then
						return
					end
				else
					return
				end

				local v40 = tbl25
				tbl25 = nil

				if v40.mv then
					tbl19.at[v40.b.id] = {v40.b.sp.t.X, v40.b.sp.t.Y}
					fn69()
				end
			end)

			local function fn73(arg6, arg7)
				if arg7 and w.Key and arg7 == w.Key.Name then
					return tbl6:Notify("Key not set", (tbl4[arg7] or arg7) .. " already shows and hides the menu", "warn")
				end

				for k, v40 in next, tbl19.keys do
					if arg7 and v40 == arg7 and k ~= arg6 then
						tbl19.keys[k] = nil
						tbl6:Notify("Key moved", (tbl4[arg7] or arg7) .. " now toggles " .. fn63(arg6) .. " instead of " .. fn63(k), "info")
					end
				end

				tbl19.keys[arg6] = arg7
				fn69()
				fn71()
			end

			function w.Pin(arg6, arg7)
				local UIScale4 = fn7("UIScale", {Scale = 0.9})
				local flag = false
				local v40, v41, v42
				local v43 = TextButton({Parent = v10, Size = v, BackgroundColor3 = color(5, 6, 16), ZIndex = 30, fn12(16)})

				local tbl27 = {
					Parent = v43,
					AnchorPoint = v3,
					Position = v2,
					Size = fn2(390, 0),
					AutomaticSize = y,
					BackgroundTransparency = 0.02,
					BackgroundColor3 = tbl.pn,
				}

				local v44 = fn12(18)
				local v45 = fn13(0.8)
				local v46 = fn16(20)
				local v47
				local v48 = fn17(10)
				local tbl28
				local tbl29 = {Size = udim2(1, 0, 0, 46)}

				local v49 = Frame({
					Size = fn2(46, 46),
					BackgroundTransparency = 0.8,
					BackgroundColor3 = tbl.a1,
					fn12(14),
					fn10("pin", 22, tbl.a1),
				})

				local tbl30 = {Position = fn2(60, 3)}
				local v50
				tbl30.Size = udim2(1, -60, 0, 22)
				tbl30.Text = fn63(arg7)
				tbl30.FontFace = font2
				tbl30.TextSize = 17
				tbl30.TextTruncate = atEnd
				v50, tbl28, v47 = TextLabel(tbl30), {Position = fn2(60, 26)}, udim2
				tbl28.Size = v47(1, -60, 0, 16)
				tbl28.Text = fn64(arg7)
				tbl28.TextSize = 11.5
				tbl28.TextTransparency = 0.42
				tbl28.TextTruncate = atEnd
				tbl29[1], tbl29[2], tbl29[3] = v49, v50, TextLabel(tbl28)
				tbl27[1], tbl27[2], tbl27[3], tbl27[4], tbl27[5], tbl27[6] = v44, v45, v46, v48, UIScale4, Frame(tbl29)
				local v51 = TextButton(tbl27)

				local function fn74(layoutOrder, text)
					TextLabel({
						Parent = v51,
						LayoutOrder = layoutOrder,
						Size = udim2(1, 0, 0, 22),
						Text = text,
						FontFace = font3,
						TextSize = 10,
						TextTransparency = 0.45,
						TextYAlignment = Enum.TextYAlignment.Bottom,
					})
				end

				fn74(1, "SHOW ON QUICK BAR")

				local v52 = Frame({
					Parent = v51,
					LayoutOrder = 2,
					Size = udim2(1, 0, 0, 40),
					(fn7("UIGridLayout", {
						CellSize = udim2(0.16666666666666666, -7, 1, 0),
						CellPadding = fn2(8, 0),
						SortOrder = Enum.SortOrder.LayoutOrder,
					})),
				})

				local tbl31 = {}

				local function fn75(arg8)
					for k, v53 in next, tbl31 do
						local flag2 = (tbl19.pins[arg7] or 0) == k
						fn19(v53[1], {BackgroundTransparency = flag2 and 0 or 1}, arg8 and 0 or 0.2)
						fn19(v53[2], {Transparency = flag2 and 0.45 or 0.84, Color = flag2 and tbl.a1 or tbl.wh}, arg8 and 0 or 0.2)
						v53[3].TextColor3 = flag2 and tbl.on or tbl.wh
					end
				end

				for i = 0, 5 do
					tbl28, tbl30 = fn13(0.84), TextLabel({
						Size = v,
						Text = i == 0 and "Off" or i,
						FontFace = font3,
						TextSize = 13,
						TextXAlignment = center,
						ZIndex = 2,
					})

					local v53 = TextButton({Parent = v52, LayoutOrder = i, BackgroundTransparency = 0.93, fn12(12), tbl28, tbl30})
					tbl31[i] = {Frame({Parent = v53, Size = v, fn12(12), fn14(tbl.a1, tbl.a2, 90)}), tbl28, tbl30}

					fn66(v53, 0.9, function()
						tbl19.pins[arg7] = i > 0 and i or nil
						fn75()
						fn69()
						fn71()

						if i > 0 and not tbl20.show then
							tbl6:Notify("Quick bars are hidden", "Turn on Show quick bars to see Quick bar " .. i, "info")
						end
					end)
				end

				fn75(true)

				local function fn76()
					v41.Text = flag and "Press any key  -  Esc cancels" or fn65(arg7) or "Not set"
					v41.TextTransparency = (flag or tbl19.keys[arg7]) and 0 or 0.45
					fn19(v42, {Transparency = flag and 0.3 or 0.82, Color = flag and tbl.a1 or tbl.wh}, 0.2)
				end

				local flag2 = UserInputService.KeyboardEnabled and (tbl6.Keys[arg7].Kind == "toggle" or tbl6.Keys[arg7].Kind == "button")
				local v53

				if flag2 then
					fn74(3, "KEYBIND")
					v42 = fn13(0.82)
					local v54 = Frame({Parent = v51, LayoutOrder = 4, Size = udim2(1, 0, 0, 40)})
					local v55 = TextButton({Parent = v54, Size = udim2(1, -98, 1, 0), BackgroundTransparency = 0.92, fn12(12), v42})
					v41 = TextLabel({Parent = v55, Size = v, FontFace = font4, TextSize = 14, TextXAlignment = center})

					fn66(v55, 0.96, function()
						flag = true
						tbl6.kw = true
						fn76()
					end)

					fn66(TextButton({
						Parent = v54,
						AnchorPoint = v7,
						Position = udim2(1, 0, 0, 0),
						Size = udim2(0, 88, 1, 0),
						BackgroundTransparency = 0.92,
						fn12(12),
						fn13(0.84),
						(TextLabel({Size = v, Text = "Clear", FontFace = font2, TextSize = 13, TextXAlignment = center})),
					}), 0.92, function()
						flag = false
						tbl6.kw = nil
						fn73(arg7)
						fn76()
					end)

					local connection = UserInputService.InputBegan:Connect(function(input)
						if flag then
							if input.UserInputType ~= Enum.UserInputType.Keyboard then
								return
							end
						else
							return
						end

						flag = false

						task.defer(function()
							tbl6.kw = nil
						end)

						if input.KeyCode ~= Enum.KeyCode.Escape then
							fn73(arg7, input.KeyCode.Name)
						end

						fn76()
					end)

					fn76()
					v53 = connection
				else
					v53 = v40
				end

				local function fn77()
					if v53 then
						v53:Disconnect()
					end

					if flag then
						tbl6.kw = nil
					end

					fn19(UIScale4, {Scale = 0.92}, 0.18)
					local v54 = fn19(v43, {BackgroundTransparency = 1}, 0.2)

					local function fn78()
						v43:Destroy()
					end

					v54.Completed:Connect(fn78)
					v51.Visible = false
				end

				fn39(Frame({Parent = v51, LayoutOrder = 5, Size = udim2(1, 0, 0, 52), (fn16(10, 0, 0))}), "Done", 0, 1, true).Activated:Connect(function()
					if fn24() then
						fn77()
					end
				end)

				v43.Activated:Connect(fn77)
				fn19(v43, {BackgroundTransparency = 0.45}, 0.2)
				fn19(UIScale4, {Scale = 1}, 0.35, back)
			end

			local v40 = arg4:Section("Quick bars", "zap")

			v40:Toggle("Show quick bars", true, function(show)
				tbl20.show = show
				fn72()
			end)

			v40:Toggle("Keybinds", true, function(keys)
				tbl20.keys = keys
			end)

			v40:Slider("Bar size", 60, 160, 100, function(arg6)
				tbl20.size = arg6 / 100

				for _, v41 in ipairs(tbl22) do
					v41.u.Scale = math.clamp(workspace.CurrentCamera.ViewportSize.Y / 720, 0.75, 1.2) * tbl20.size
				end
			end, "%", 5)

			tbl21.Set = function(arg6, arg7, arg8)
				arg6.Value = tostring(arg7 or "")
				local ok, result = pcall(HttpService.JSONDecode, HttpService, arg6.Value)

				if ok and type(result) == "table" and type(result.pins) == "table" then
					for _, v41 in ipairs({"keys", "at", "fold"}) do
						result[v41] = type(result[v41]) == "table" and result[v41] or {}
					end

					tbl19 = result
				else
					fn70()
				end

				if not arg8 then
					fn72()
				end
			end

			v40:Reg("Quick bar layout", tbl21)
			local v41 = arg4:Section("Pins and keybinds", "pin")
			v41:Text("Tip: you can also hold any feature, or right-click it on PC, to pin it or set a key.")

			local v42 = Frame({
				Parent = v41.f,
				LayoutOrder = v41.n + 1,
				Size = v5,
				AutomaticSize = y,
				fn16(4, 14, 12),
				(fn17(8)),
			})

			v41:Add(v42, "")
			local v43 = Frame({Parent = v42, Size = udim2(1, 0, 0, 34)})
			local findAnOption = fn35({Parent = v43, Size = udim2(1, -150, 1, 0)}, "Find an option")
			local str2 = "All"

			local v44 = Frame({
				Parent = v43,
				AnchorPoint = v7,
				Position = udim2(1, 0, 0, 0),
				Size = udim2(0, 142, 1, 0),
				BackgroundTransparency = 0.93,
				fn12(10),
				fn13(0.86),
				(fn16(3)),
			})

			local v45 = Frame2({Parent = v44, Size = udim2(0.5, 0, 1, 0), fn12(8), (fn14(tbl.a1, tbl.a2, 90))})
			local v46 = ScrollingFrame({Parent = v42, LayoutOrder = 1, Size = udim2(1, 0, 0, 300), (fn17(4))})
			w.nest[v46] = arg4.top or arg4

			local v47 = TextLabel({
				Parent = v46,
				Size = udim2(1, 0, 0, 60),
				TextSize = 12,
				TextTransparency = 0.45,
				TextXAlignment = center,
			})

			fn61 = function()
				for _, child in ipairs(v46:GetChildren()) do
					if child:IsA("GuiObject") and child ~= v47 then
						child:Destroy()
					end
				end

				local str3 = findAnOption.Text:lower()
				local v48 = table.pack(fn68())
				local v49
				local n7 = 0

				for _, v50 in ipairs(table.unpack(v48, 1, v48.n)) do
					if (str2 == "All" or tbl19.pins[v50] or tbl19.keys[v50]) and v50:lower():find(str3, 1, true) then
						local v51 = tbl19.pins[v50]
						local v52 = fn65(v50)
						local layoutOrder

						if fn64(v50) ~= v49 then
							local v53 = fn64(v50)
							layoutOrder = n7 + 1

							TextLabel({
								Parent = v46,
								LayoutOrder = layoutOrder,
								Size = udim2(1, -6, 0, 24),
								Text = v53:upper(),
								FontFace = font3,
								TextSize = 9.5,
								TextTransparency = 0.5,
								TextYAlignment = Enum.TextYAlignment.Bottom,
								(fn16(0, 0, 3, 6)),
							})

							v49 = v53
						else
							layoutOrder = n7
						end

						local tbl27 = Frame
						local tbl28 = {AnchorPoint = v4, Position = udim2(1, -10, 0.5, 0), Size = fn2(170, 22)}
						local v53 = fn17
						local v54
						local v55 = v53(6, Enum.HorizontalAlignment.Right, center3, horizontal)

						local tbl29 = {
							LayoutOrder = 1,
							Size = fn2(0, 22),
							AutomaticSize = x,
							BackgroundTransparency = v51 and 0 or 0.9,
						}

						local v56 = fn12()
						local v57

						tbl29[1], tbl29[2], tbl29[3], tbl29[4] = v56, fn16(0, 9), v51 and fn14(tbl.a1, tbl.a2, 90) or nil, TextLabel({
							Size = udim2(0, 0, 1, 0),
							AutomaticSize = x,
							Text = v51 and "QUICK BAR " .. v51 or "+ PIN",
							FontFace = font3,
							TextSize = 9.5,
							TextTransparency = v51 and 0 or 0.4,
							TextColor3 = v51 and tbl.on or tbl.wh,
						})

						tbl28[1], tbl28[2] = v55, Frame2(tbl29)
						local v58 = tbl27(tbl28)

						if v52 then
							TextLabel({
								Parent = v58,
								Size = fn2(0, 22),
								AutomaticSize = x,
								Text = v52,
								FontFace = font4,
								TextSize = 10.5,
								TextXAlignment = center,
								BackgroundTransparency = 0.88,
								fn12(7),
								fn16(0, 7),
							})
						end

						layoutOrder += 1
						local tbl30 = {Parent = v46, LayoutOrder = layoutOrder, Size = udim2(1, -6, 0, 38), BackgroundTransparency = 0.955}
						v53, v54, tbl27, v57 = fn12(12), fn13(0.9), {Position = fn2(12, 0)}, udim2
						tbl27.Size = v57(1, -190, 1, 0)
						tbl27.RichText = true
						tbl27.Text = fn63(v50) .. (tbl6.Keys[v50].Kind ~= "toggle" and "  <font transparency=\"0.6\">" .. tbl6.Keys[v50].Kind .. "</font>" or "")
						tbl27.FontFace = font2
						tbl27.TextSize = 13
						tbl27.TextTruncate = atEnd
						tbl30[1], tbl30[2], tbl30[3], tbl30[4] = v53, v54, v58, TextLabel(tbl27)

						fn66(TextButton(tbl30), 0.97, function()
							w:Pin(v50)
						end)

						n7 = layoutOrder
					end
				end

				v47.Visible, v47.Text = n7 == 0, str2 == "All" and "No option matches" or "Nothing pinned or bound yet"
			end

			local tbl27 = {}

			for i, v48 in ipairs({"All", "Pinned"}) do
				tbl27[i] = TextLabel({
					Size = v,
					Text = v48,
					FontFace = font2,
					TextSize = 12,
					TextXAlignment = center,
					TextColor3 = i == 1 and tbl.on or tbl.wh,
				})

				fn66(TextButton({
					Parent = v44,
					Position = udim2((i - 1) / 2, 0, 0, 0),
					Size = udim2(0.5, 0, 1, 0),
					ZIndex = 2,
					tbl27[i],
				}), 0.95, function()
					str2 = v48

					for i2, v49 in ipairs(tbl27) do
						fn19(v49, {TextColor3 = i2 == i and tbl.on or tbl.wh}, 0.2)
					end

					fn19(v45, {Position = udim2((i - 1) / 2, 0, 0, 0)}, 0.3, back)
					fn61()
				end)
			end

			local n7 = 0

			fn5(findAnOption:GetPropertyChangedSignal("Text"), function()
				n7 += 1
				local v48 = n7

				task.delay(0.2, function()
					if v48 == n7 then
						fn61()
					end
				end)
			end)

			v41:Button("Clear all quick bars", "Clear", function()
				fn45("Clear every quick bar?", "Features keep their state, they just leave the bars.", "warn", "Clear", function()
					tbl19.pins = {}
					fn69()
					fn71()
				end)
			end, "danger")

			v41:Button("Clear all keybinds", "Clear", function()
				fn45("Clear every keybind?", "Keys stop toggling options until you set them again.", "warn", "Clear", function()
					tbl19.keys = {}
					fn69()
					fn71()
				end)
			end, "danger")

			fn5(UserInputService.InputBegan, function(arg6, arg7)
				if arg7 then
					return
				elseif tbl6.kw then
					return
				elseif tbl20.keys then
					if arg6.UserInputType ~= Enum.UserInputType.Keyboard then
						return
					end
				else
					return
				end

				for k, v48 in next, tbl19.keys do
					local v49 = tbl6.Keys[k]

					if v49 and v48 == arg6.KeyCode.Name then
						if v49.Kind == "button" then
							v49.Fire()
							tbl6:Notify(fn63(k), "Pressed", "ok", 2)
						else
							tbl6.qb = true
							v49:Set(not v49.Value)
							tbl6.qb = nil
							tbl6:Notify(fn63(k), v49.Value and "Turned on" or "Turned off", v49.Value and "ok" or "info", 2)
						end
					end
				end
			end)

			fn70()
			fn72()
			return v40
		end

		w.Wheel = function(arg3, arg4)
			local sc = w.Cur and w.Cur.sc

			if UserInputService.TouchEnabled then
				return
			elseif w.open then
				if tbl18.open then
					return
				elseif w.dlg then
					return
				elseif os.clock() - (w.wt or 0) < 0.015 then
					return
				elseif sc then
					if not sc:IsA("ScrollingFrame") then
						return
					end
				else
					return
				end
			else
				return
			end

			w.wt = os.clock()
			local n6 = UserInputService:GetMouseLocation() - (w.Gui.IgnoreGuiInset and vector2() or vector2(0, 58))

			for k, v40 in next, w.nest do
				local absolutePosition = k.AbsolutePosition
				local absoluteSize = k.AbsoluteSize
				local y2 = k.CanvasPosition.Y
				sc = if k.Parent then if (w.Cur.top or w.Cur) == v40 then if n6.X >= absolutePosition.X then if n6.Y >= absolutePosition.Y then if n6.X <= absolutePosition.X + absoluteSize.X then if n6.Y <= absolutePosition.Y + absoluteSize.Y then if arg4 > 0 and y2 > 1 then k elseif arg4 < 0 then if y2 < k.AbsoluteCanvasSize.Y - absoluteSize.Y - 1 then k else sc else sc else sc else sc else sc else sc else sc else sc
			end

			local n7 = math.max(0, sc.AbsoluteCanvasSize.Y - sc.AbsoluteWindowSize.Y)
			local goal = w.goal
			local y2 = sc.CanvasPosition.Y
			goal = if goal then if w.gf ~= sc then y2 elseif math.abs(goal - y2) > 300 then y2 else goal else y2
			w.goal = math.clamp(goal - arg4 * 120, 0, n7)
			w.gf = sc
			fn19(sc, {CanvasPosition = vector2(0, w.goal)}, 0.4)
		end

		fn5(UserInputService.InputChanged, function(arg3)
			local sc = w.Cur and w.Cur.sc

			if arg3.UserInputType ~= Enum.UserInputType.MouseWheel then
				return
			elseif not sc then
				return
			end

			local n6 = UserInputService:GetMouseLocation() - (w.Gui.IgnoreGuiInset and vector2() or vector2(0, 58))
			local absolutePosition = sc.AbsolutePosition
			local absoluteSize = sc.AbsoluteSize

			if n6.X < absolutePosition.X then
				return
			elseif n6.Y < absolutePosition.Y then
				return
			elseif n6.X > absolutePosition.X + absoluteSize.X then
				return
			elseif n6.Y > absolutePosition.Y + absoluteSize.Y then
				return
			end

			w:Wheel(arg3.Position.Z)
		end)

		w.Destroy = function(arg3)
			for _, v40 in ipairs(tbl7) do
				v40:Disconnect()
			end

			tbl7 = {}
			pcall(RunService.UnbindFromRenderStep, RunService, v15)
			v8:Destroy()
			local vxezeWindows = getgenv and getgenv().VxezeWindows

			if vxezeWindows and vxezeWindows[w.Id] == w then
				vxezeWindows[w.Id] = nil
			end
		end

		w.Notify = function(arg3, ...)
			return tbl6:Notify(...)
		end

		w.GlobalChat = function(arg3, opts)
			return tbl6:GlobalChat(w, opts)
		end

		tbl6:Boot()
		langWatch(v8)
		langWatch(w.nt and w.nt.Parent)
		tbl6:SetLanguage(state.Lang, false)
		w.langCard()
		w:Show(true)
		return w
	end

	index.new = function(t, name, image, side)
		local obj = setmetatable({t = t, W = t.W, n = 0, name = name, side = side}, index)

		obj.hd = TextButton({
			Size = udim2(1, 0, 0, 42),
			fn9({
				Position = fn2(14, 14),
				Size = fn2(15, 15),
				Image = image or "grid",
				ImageColor3 = tbl3[#t.Secs % 5 + 1],
			}),
			(TextLabel({
				Position = fn2(37, 12),
				Size = udim2(1, -76, 0, 18),
				Text = name:upper(),
				FontFace = font3,
				TextSize = 12,
				TextTransparency = 0.06,
				TextTruncate = atEnd,
			})),
		})

		obj.ch = fn9({
			Parent = obj.hd,
			AnchorPoint = v3,
			Position = udim2(1, -22, 0, 21),
			Size = fn2(14, 14),
			Image = "down",
			ImageTransparency = 0.5,
		})

		obj.f = Frame({LayoutOrder = 1, Size = v5, AutomaticSize = y, ClipsDescendants = true, (fn17())})

		if side and side > 2 then
			t.cols[side].Visible = true
		end

		obj.card = Frame({
			Parent = t.cols[side or 1],
			Size = v5,
			AutomaticSize = y,
			BackgroundTransparency = 0.95,
			LayoutOrder = #t.Secs + 1,
			fn12(16),
			fn13(0.88),
			fn17(),
			obj.hd,
			obj.f,
		})

		fn25(obj.hd, function()
			obj:Collapse(obj.open ~= false)
		end)

		t.Secs[#t.Secs + 1] = obj
		t.list[#t.list + 1] = obj

		fn5(obj.card:GetPropertyChangedSignal("AbsoluteSize"), function()
			fn40(t)
		end)

		fn40(t)
		return obj
	end

	index.Collapse = function(arg, arg2)
		arg.open = not arg2
		local f = arg.f
		local n3 = math.max(arg.hd.AbsoluteSize.Y / 42, 0.1)
		local n4 = f:FindFirstChildOfClass("UIListLayout").AbsoluteContentSize.Y / n3
		f.Size = udim2(1, 0, 0, f.AbsoluteSize.Y / n3)
		f.AutomaticSize = Enum.AutomaticSize.None

		fn19(f, {Size = udim2(1, 0, 0, arg2 and 0 or n4)}, 0.35).Completed:Connect(function()
			if arg.open then
				f.AutomaticSize = y
			end
		end)

		fn19(arg.ch, {Rotation = arg2 and -90 or 0}, 0.3)
	end

	index.Add = function(arg, r, title, arg2)
		if arg.n > 0 then
			fn18(r, fn2(14, 0), udim2(1, -28, 0, 1))
		end

		arg.n = arg.n + 1

		if arg2 then
			local all = arg.W.All

			all[#all + 1] = {
				r = r,
				n = title:lower(),
				title = title,
				tab = arg.t.top,
				path = arg.t.Name .. " / " .. arg.name,
				k = arg.t.Name .. "/" .. arg.name .. "/" .. title,
			}
		end
	end

	index.Row = function(arg, text, text2, arg2)
		local n3 = text2 and 48 or 42
		local v8 = TextButton({Parent = arg.f, Size = udim2(1, 0, 0, n3), LayoutOrder = arg.n + 1, (fn12(14))})
		arg:Add(v8, text, true)
		fn20(v8, 0.97)

		fn5(v8.InputBegan, function(arg3)
			if fn23(arg3) then
				fn19(v8, {BackgroundTransparency = 0.94}, 0.08)
			end
		end)

		fn5(v8.InputEnded, function(arg3)
			if fn23(arg3) then
				fn19(v8, {BackgroundTransparency = 1}, 0.35)
			end
		end)

		local v9 = Frame({
			Parent = v8,
			AnchorPoint = vector2(0, 0.5),
			Position = udim2(0, 14, 0.5, 0),
			Size = udim2(1, -arg2 - 42, 0, text2 and 42 or 21),
			fn17(0, nil, center3),
			(TextLabel({Size = udim2(1, 0, 0, 21), Text = text, TextSize = 14.5, TextTruncate = atEnd})),
		})

		if text2 then
			TextLabel({
				Parent = v9,
				LayoutOrder = 1,
				Size = v5,
				AutomaticSize = y,
				Text = text2,
				TextSize = 12,
				TextTransparency = 0.3,
				TextWrapped = true,
			})
		end

		return v8, Frame({Parent = v8, AnchorPoint = v4, Position = udim2(1, -14, 0.5, 0), Size = fn2(arg2, 36)}), v9
	end

	index.Reg = function(arg, name, arg2)
		local value = arg2.Value
		arg2.Key, arg2.Name, arg2.Def = arg.t.Name .. "/" .. arg.name .. "/" .. name, name, type(value) == "table" and table.clone(value) or value
		local v8
		v8, tbl6.Opt[name], tbl6.Keys[arg2.Key] = tbl6, arg2, arg2
		local set = arg2.Set

		arg2.Set = function(arg3, ...)
			set(arg3, ...)

			if state.AutoSave and not tbl6.busy and not arg2.Skip then
				tbl6:Dirty()
			end
		end

		return arg2
	end

	index.Hold = function(arg, arg2, arg3)
		local n3 = 0

		fn5(arg2.InputEnded, function(arg4)
			if fn23(arg4) then
				n3 += 1
			end
		end)

		fn5(arg2.InputBegan, function(arg4)
			local w = arg.W
			if not w.Pin then
				return
			end

			if arg4.UserInputType == Enum.UserInputType.MouseButton2 then
				return w:Pin(arg3.Key)
			end

			if not fn23(arg4) then
				return
			end
			n3 += 1
			local v8 = n3
			local flag = arg4.UserInputType == Enum.UserInputType.MouseButton1

			task.delay(0.6, function()
				local flag2 = n3 == v8 and tbl10.m < 14 and not tbl10.s
				local flag3

				if flag2 then
					local v9 = flag and UserInputService:IsMouseButtonPressed(arg4.UserInputType)

					if v9 then
						flag3 = v9
					elseif flag then
						flag3 = not flag
					else
						flag3 = arg4.UserInputState ~= Enum.UserInputState.End
					end
				else
					flag3 = flag2
				end

				if flag3 then
					tbl10.s = true
					w:Pin(arg3.Key)
				end
			end)
		end)
	end

	index.Toggle = function(arg, arg2, arg3, arg4, arg5)
		local v8, v9 = arg:Row(arg2, arg5, 48)
		local v10 = fn33(v9, 46, 24)
		local tbl14 = {Value = not not arg3, ls = {}, Tab = arg.t.Name, Kind = "toggle"}

		tbl14.Set = function(arg6, value, arg7)
			value = not not value
			tbl14.Value = value
			v10(value)

			for _, v11 in ipairs(tbl14.ls) do
				v11(value)
			end

			if not arg7 then
				fn22(arg4, value)
			end
		end

		fn25(v8, function()
			tbl14:Set(not tbl14.Value)
		end)

		arg:Hold(v8, tbl14)
		v10(tbl14.Value, true)

		if arg3 then
			fn22(arg4, true)
		end

		return arg:Reg(arg2, tbl14)
	end

	local tbl14 = {K = 1000, M = 1000000, B = 1000000000, T = 1000000000000}

	index.Slider = function(arg, arg2, arg3, arg4, arg5, arg6, arg7, arg8, arg9)
		local flag = arg7 == "log"
		local n3, n4

		if flag then
			n3 = 0
			n4 = 1000
		else
			n3 = arg3
			n4 = arg4
		end

		local n5 = arg8 or 1
		local v8, v9, v10 = arg:Row(arg2, arg9, 200)
		local textLabel = v10:FindFirstChildOfClass("TextLabel")
		textLabel:SetAttribute("nofit", true)
		textLabel.TextSize = 17
		local tbl15 = {w = 0}

		local function fn43()
			v10.Size = udim2(0, tbl15.w, v10.Size.Y.Scale, v10.Size.Y.Offset)
			v9.Size = udim2(1, -tbl15.w - 46, 0, 36)
		end

		tbl15[#tbl15 + 1] = fn43

		local function fn44()
			local n6 = textLabel.AbsoluteSize.Y / 21

			if n6 <= 0 then
				return
			elseif textLabel.TextBounds.X <= 0 then
				return
			end

			local w = math.max(math.ceil(textLabel.TextBounds.X / n6) + 6, arg9 and math.min(150, #arg9 * 6.3 + 6) or 0)
			if w <= tbl15.w then
				return fn43()
			end
			tbl15.w = w

			for _, v11 in ipairs(tbl15) do
				v11()
			end
		end

		fn5(textLabel:GetPropertyChangedSignal("TextBounds"), fn44)
		task.defer(fn44)

		local v11 = Frame({
			Parent = v9,
			Position = udim2(0, 8, 0.5, -3),
			Size = udim2(1, -70, 0, 6),
			BackgroundTransparency = 0.88,
			(fn12()),
		})

		local v12 = Frame2({Parent = v11, Size = udim2(0, 0, 1, 0), fn12(), (fn14(tbl.a1, tbl.a2))})

		local v13 = Frame2({
			Parent = v11,
			AnchorPoint = v3,
			Position = udim2(0, 0, 0.5, 0),
			Size = fn2(20, 20),
			ZIndex = 2,
			fn12(),
			(fn13(0.65, color(0, 0, 0))),
		})

		local UIScale = fn7("UIScale", {Parent = v13})
		local v14 = fn13(0.8)

		local v15 = TextBox({
			Parent = v9,
			AnchorPoint = v4,
			Position = v6,
			Size = fn2(54, 28),
			FontFace = font3,
			TextSize = 13,
			TextTruncate = atEnd,
			TextColor3 = tbl.val,
			TextXAlignment = center,
			BackgroundTransparency = 0.72,
			BackgroundColor3 = color(0, 0, 0),
			fn12(8),
			fn16(4, 4),
			v14,
		})

		local function fn45(arg10)
			if arg10 <= 0 then
				return 0
			end
			local n6 = 10 ^ (3 + 9 * arg10 / 1000)
			local n7 = 10 ^ (math.floor(math.log10(n6)) - 2)
			return math.floor(n6 / n7 + 0.5) * n7
		end

		local function fn46(arg10)
			return flag and (arg10 <= 0 and 0 or math.clamp((math.log10(arg10) - 3) / 9 * 1000, 0, 1000)) or arg10
		end

		local function fn47(arg10, arg11)
			local str2 = string.format(arg10 >= 100 and "%.0f" or arg10 >= 10 and "%.1f" or "%.2f", arg10)
			return (str2:find("%.") and str2:gsub("0+$", ""):gsub("%.$", "") or str2) .. arg11
		end

		local function txt(arg10, arg11)
			if not flag then
				return type(arg7) == "function" and arg7(arg10) or fn26(arg10) .. (arg7 or "")
			end

			if arg10 <= 0 then
				return arg11 and "0" or "Off"
			end
			local n6 = arg10 < 1000000 and 1000 or arg10 < 1000000000 and 1000000 or 1000000000
			return fn47(arg10 / n6, (n6 == 1000 and "K" or n6 == 1000000 and "M" or "B") .. (arg11 and "" or "/s"))
		end

		local v16 = TextButton({Parent = v9, Position = fn2(-4, -2), Size = udim2(1, -60, 1, 4), ZIndex = 3})
		local drag = {ls = {}, Kind = "slider"}

		drag.Set = function(arg10, value, arg11, arg12)
			if type(value) ~= "number" then
				local match, v17 = tostring(value):upper():match("^([%d%.]+)(%a?)")
				value = (tonumber(match) or 0) * (tbl14[v17] or (flag and 1000000 or 1))
			end

			value = flag and fn45(fn46(value)) or math.clamp(math.floor((value - n3) / n5 + 0.5) * n5 + n3, n3, n4)
			local flag2 = value ~= drag.Value
			drag.Value = value
			local n6 = (fn46(value) - n3) / (n4 - n3)
			fn19(v12, {Size = udim2(n6, 0, 1, 0)}, arg12 and 0.08 or 0.3)
			fn19(v13, {Position = udim2(n6, 0, 0.5, 0)}, arg12 and 0.08 or 0.3)

			if not v15:IsFocused() then
				v15.Text = txt(value)
			end

			for _, v17 in ipairs(drag.ls) do
				v17(value)
			end

			if arg11 then
			elseif flag2 then
				fn22(arg6, value)
			end
		end

		local v17

		local function fn48(arg10)
			local n6 = n3 + (n4 - n3) * math.clamp((arg10 - v11.AbsolutePosition.X) / v11.AbsoluteSize.X, 0, 1)
			drag:Set(flag and fn45(n6) or n6, false, true)
		end

		local function fn49(arg10)
			v17 = arg10

			if arg.t.cols and UserInputService.TouchEnabled then
				arg.t.sc.ScrollingEnabled = not arg10
			end

			fn19(UIScale, {Scale = arg10 and 1.25 or 1}, 0.22, back)
		end

		fn5(v16.InputBegan, function(d)
			local drag2 = tbl6.drag

			if fn23(d) then
				if drag2 and drag2 ~= drag and drag2.d and drag2.d.UserInputState ~= Enum.UserInputState.End then
					return
				end
			else
				return
			end

			tbl6.drag = drag
			drag.d = d
			tbl10.s = true
			fn49(d)
			fn48(d.Position.X)
		end)

		local function fn50()
			return v17.UserInputType == Enum.UserInputType.MouseButton1
		end

		fn5(UserInputService.InputChanged, function(arg10)
			if v17 and (arg10 == v17 or fn50() and arg10.UserInputType == Enum.UserInputType.MouseMovement) then
				fn48(arg10.Position.X)
			end
		end)

		fn5(UserInputService.InputEnded, function(arg10)
			if v17 and (arg10 == v17 or fn50() and arg10.UserInputType == Enum.UserInputType.MouseButton1) then
				tbl6.drag = nil
				fn49(nil)
			end
		end)

		fn5(v15.Focused, function()
			v15.Text = flag and txt(drag.Value, true) or tostring(drag.Value)
			fn19(v15, {BackgroundTransparency = 0.75}, 0.15)
		end)

		fn34(v15, v14, 0.5, 0.8, function()
			fn19(v15, {BackgroundTransparency = 0.9}, 0.2)
			local str2 = v15.Text:gsub("[%s,/]", ""):gsub("[sS]$", "")
			str2 = if flag then if str2:lower() == "off" then "0" else str2 else str2

			if str2:match("^%-?[%d%.]+%a?$") then
				drag:Set(flag and str2 or tonumber(str2))
			end

			v15.Text = txt(drag.Value)
		end)

		drag.Frac = function(arg10)
			return (fn46(arg10) - n3) / (n4 - n3)
		end

		drag.Txt = txt

		drag.From = function(arg10)
			arg10 = n3 + (n4 - n3) * arg10
			return flag and fn45(arg10) or arg10
		end

		arg:Hold(v8, drag)
		drag:Set(arg5, true)
		return arg:Reg(arg2, drag)
	end

	index.Dropdown = function(arg, arg2, options, arg3, arg4, multi, arg5)
		local v8, v9 = arg:Row(arg2, arg5, 176)

		local v10 = Frame({
			Parent = v9,
			AnchorPoint = vector2(0, 0.5),
			Position = udim2(0, 0, 0.5, 0),
			Size = udim2(1, 0, 0, 32),
			BackgroundTransparency = 0.93,
			fn12(10),
			fn13(0.87),
			(fn9({AnchorPoint = v4, Position = udim2(1, -8, 0.5, 0), Size = fn2(13, 13), Image = "down"})),
		})

		local v11 = TextLabel({
			Parent = v10,
			Position = fn2(9, 0),
			Size = udim2(1, -34, 1, 0),
			FontFace = font2,
			TextSize = 14,
			TextTruncate = atEnd,
		})

		local v12 = TextLabel({
			Parent = v10,
			AnchorPoint = v4,
			Position = udim2(1, -26, 0.5, 0),
			Size = fn2(0, 18),
			AutomaticSize = x,
			FontFace = font2,
			TextSize = 11,
			TextColor3 = color(226, 229, 255),
			BackgroundTransparency = 0.72,
			BackgroundColor3 = tbl.a1,
			TextXAlignment = center,
			fn12(),
			(fn16(0, 6)),
		})

		local w = arg.W
		local tbl15 = {Options = options, Multi = multi}

		tbl15.Set = function(arg6, arg7, arg8)
			tbl15.Value = multi and (type(arg7) == "table" and arg7 or {arg7}) or arg7
			local options2 = multi and type(tbl15.Options) == "table" and tbl15.Options

			if options2 then
				local tbl16 = {}

				for i, v13 in ipairs(options2) do
					tbl16[type(v13) == "table" and v13.v or v13] = i
				end

				tbl15.Value = table.clone(tbl15.Value)

				table.sort(tbl15.Value, function(arg9, arg10)
					return (tbl16[arg9] or 1000000000) < (tbl16[arg10] or 1000000000)
				end)
			end

			local n3 = multi and #tbl15.Value or 0
			v11:SetAttribute("alt", n3 > 1 and tbl15.Value[1] .. "..." or nil)
			v11.Text = multi and (n3 == 0 and "None" or tostring(tbl15.Value[1])) or tostring(tbl15.Value or "None")
			v12.Text = "+" .. n3 - 1
			v12.Visible = n3 > 1
			v11.Size = udim2(1, n3 > 1 and -70 or -34, 1, 0)
			v11.TextTransparency = 0.6
			fn19(v11, {TextTransparency = 0}, 0.3)
			w:Sync(tbl15)

			if not arg8 then
				fn22(arg4, tbl15.Value)
			end
		end

		tbl15.Refresh = function(arg6, options2)
			tbl15.Options = options2
		end

		fn25(v8, function()
			local options2 = type(tbl15.Options) == "function" and tbl15.Options() or tbl15.Options

			arg.W:Pick(arg2, options2, tbl15.Value, multi, function(arg6)
				tbl15:Set(arg6)
			end, tbl15.Default, tbl15)
		end)

		tbl15.Default = multi and table.clone(arg3 or {}) or nil
		tbl15:Set(multi and (arg3 or {}) or arg3, true)
		return arg:Reg(arg2, tbl15)
	end

	index.Input = function(arg, arg2, placeholderText, arg3, arg4)
		local v8, v9 = arg:Row(arg2, arg4, 176)
		local v10 = fn13(0.87)

		local v11 = TextBox({
			Parent = v9,
			AnchorPoint = vector2(0, 0.5),
			Position = udim2(0, 0, 0.5, 0),
			Size = udim2(1, 0, 0, 26),
			BackgroundTransparency = 0.8,
			BackgroundColor3 = color(0, 0, 0),
			PlaceholderText = placeholderText or "",
			TextSize = 13,
			TextTruncate = atEnd,
			TextXAlignment = Enum.TextXAlignment.Left,
			ClipsDescendants = true,
			fn12(10),
			fn16(0, 10),
			v10,
		})

		local tbl15 = {Value = "", ls = {}, Kind = "input"}

		tbl15.Set = function(arg5, arg6, arg7)
			tbl15.Value = tostring(arg6 or "")
			v11.Text = tbl15.Value

			for _, v12 in ipairs(tbl15.ls) do
				v12(tbl15.Value)
			end

			if not arg7 then
				fn22(arg3, tbl15.Value)
			end
		end

		arg:Hold(v8, tbl15)

		fn34(v11, v10, 0.5, 0.87, function()
			tbl15:Set(v11.Text)
		end)

		fn25(v8, function()
			v11:CaptureFocus()
		end)

		return arg:Reg(arg2, tbl15)
	end

	index.Key = function(arg, arg2, arg3, arg4, arg5, arg6)
		local v8, v9 = arg:Row(arg2, arg6, 60)
		local v10 = fn13(0.82)

		local v11 = TextLabel({
			Parent = v9,
			AnchorPoint = v4,
			Position = v6,
			Size = fn2(0, 26),
			AutomaticSize = x,
			FontFace = font4,
			TextXAlignment = center,
			BackgroundTransparency = 0.92,
			fn12(9),
			fn16(0, 12),
			v10,
			(fn7("UISizeConstraint", {MinSize = vector2(36, 26)})),
		})

		local flag
		local tbl15 = {}

		tbl15.Set = function(arg7, value, arg8)
			tbl15.Value = value
			local name = value and value.Name or "None"
			v11.Text = tbl4[name] or name
			fn19(v10, {Transparency = 0.82, Color = tbl.wh}, 0.2)

			if not arg8 then
				fn22(arg5, value)
			end
		end

		fn25(v8, function()
			flag = true
			tbl6.kw = true
			v11.Text = "..."
			fn19(v10, {Transparency = 0.4, Color = tbl.a1}, 0.2)
		end)

		fn5(UserInputService.InputBegan, function(arg7, arg8)
			if flag and arg7.UserInputType == Enum.UserInputType.Keyboard then
				flag = false

				task.defer(function()
					tbl6.kw = nil
				end)

				tbl15:Set(arg7.KeyCode ~= Enum.KeyCode.Escape and arg7.KeyCode or nil)
			elseif arg8 then
			elseif tbl15.Value and arg7.KeyCode == tbl15.Value then
				fn22(arg4)
			end
		end)

		tbl15:Set(arg3, true)
		return arg:Reg(arg2, tbl15)
	end

	index.Button = function(arg, name, text, arg2, arg3, arg4)
		local sky = ({danger = tbl.red, gold = tbl.gold, mint = tbl.mint, pink = tbl.pink})[arg3] or tbl.sky
		local v8, v9 = arg:Row(name, arg4, 110)

		local v10 = TextLabel({
			Parent = v9,
			AnchorPoint = v4,
			Position = v6,
			Size = fn2(0, 26),
			AutomaticSize = x,
			Text = text or "Run",
			FontFace = font2,
			TextSize = 13,
			TextTransparency = 1,
			fn16(0, 14),
		})

		local v11 = TextLabel({
			Parent = v10,
			AnchorPoint = v3,
			Position = v2,
			Size = udim2(1, 28, 1, 0),
			Text = v10.Text,
			FontFace = font2,
			TextSize = 13,
			TextColor3 = sky:Lerp(tbl.wh, 0.55),
			TextXAlignment = center,
			BackgroundTransparency = 0.85,
			BackgroundColor3 = sky,
			fn12(10),
			(fn13(0.5, sky)),
		})

		fn27(v11, 0.93, v8, function(arg5)
			fn19(v11, {BackgroundTransparency = arg5 and 0.7 or 0.85}, 0.2)
		end)

		fn25(v8, function()
			fn22(arg2)
		end)

		local tbl15 = {
			Kind = "button",
			Skip = true,
			Text = v10.Text,
			Col = sky,
			Name = name,
			Key = arg.t.Name .. "/" .. arg.name .. "/" .. name,
			Fire = function()
				fn22(arg2)
			end,
			Set = function(arg5, text2)
				v10.Text = text2
				v11.Text = text2
				arg5.Text = text2
			end,
		}

		tbl6.Keys[tbl15.Key] = tbl15
		arg:Hold(v8, tbl15)
		return tbl15
	end

	index.Stats = function(arg, arg2, arg3)
		local v8 = Frame({Parent = arg.f, Size = v5, AutomaticSize = y, LayoutOrder = arg.n + 1})

		local v9 = Frame({
			Parent = v8,
			Size = v5,
			AutomaticSize = y,
			fn16(8, 14, 10),
			(fn7("UIGridLayout", {
				CellSize = arg3 == 1 and udim2(1, 0, 0, 40) or udim2(0.5, -6, 0, 40),
				CellPadding = fn2(12, 6),
				SortOrder = Enum.SortOrder.LayoutOrder,
			})),
		})

		arg:Add(v8, "")
		local tbl15 = {}

		for i, v10 in ipairs(arg2) do
			local image = type(v10) == "table" and v10[2]
			v10 = type(v10) == "table" and v10[1] or v10
			local n3 = image and 40 or 10
			local v11 = Frame({Parent = v9, LayoutOrder = i, BackgroundTransparency = 0.95, fn12(10)})

			if image then
				fn9({
					Parent = v11,
					Position = fn2(8, 7),
					Size = fn2(26, 26),
					Image = image,
					ScaleType = Enum.ScaleType.Fit,
					ImageColor3 = tbl5[image] and tbl.a1 or nil,
				})
			end

			TextLabel({
				Parent = v11,
				Position = fn2(n3, 4),
				Size = udim2(1, -n3 - 8, 0, 14),
				Text = v10:upper(),
				FontFace = font3,
				TextSize = 9.5,
				TextTransparency = 0.38,
			})

			tbl15[v10] = TextLabel({
				Parent = v11,
				Position = fn2(n3, 19),
				Size = udim2(1, -n3 - 8, 0, 17),
				Text = "--",
				FontFace = font4,
				TextSize = 13,
				TextTruncate = atEnd,
			})
		end

		return fn38(tbl15)
	end

	index.List = function(arg, arg2, text, arg3)
		local n3 = arg3 and 48 or 64
		local v8 = Frame({Parent = arg.f, LayoutOrder = arg.n + 1, Size = udim2(1, 0, 0, arg2 * n3 + 12)})
		arg:Add(v8, "")
		local v9 = ScrollingFrame({Parent = v8, Position = fn2(10, 6), Size = udim2(1, -20, 1, -12), (fn17(6))})
		arg.W.nest[v9] = arg.t.top or arg.t

		local v10 = TextLabel({
			Parent = v8,
			Size = v,
			Text = text or "Nothing here",
			TextSize = 12,
			TextTransparency = 0.45,
			TextXAlignment = center,
		})

		local tbl15 = {}
		local tbl16 = {}
		local id

		local function fn43(arg4)
			local flag = arg4.it and arg4.it.id == id
			arg4.s.Color = flag and tbl.a1 or tbl.wh
			arg4.s.Transparency = flag and 0.3 or 0.9
			arg4.r.BackgroundTransparency = flag and 0.9 or 0.955
		end

		local function fn44()
			local tbl17 = {s = fn13(0.9)}

			tbl17.r = TextButton({
				Parent = v9,
				Size = udim2(1, -6, 0, n3 - 6),
				BackgroundTransparency = 0.955,
				fn12(15),
				tbl17.s,
			})

			local n4 = arg3 and 30 or 42

			tbl17.box = Frame({
				Parent = tbl17.r,
				Position = fn2(8, arg3 and 6 or 8),
				Size = fn2(n4, n4),
				BackgroundTransparency = 0.8,
				fn12(arg3 and 10 or 13),
			})

			tbl17.im = ImageLabel({
				Parent = tbl17.box,
				AnchorPoint = v3,
				Position = v2,
				Size = fn2(n4 - 4, n4 - 4),
				ScaleType = Enum.ScaleType.Fit,
			})

			local v11 = Frame({
				Parent = tbl17.r,
				Position = fn2(n4 + 18, arg3 and 4 or 5),
				Size = udim2(1, -152, 0, 18),
				(fn17(8, nil, center3, horizontal)),
			})

			tbl17.a = TextLabel({Parent = v11, Size = fn2(0, 18), AutomaticSize = x, FontFace = font2, TextSize = 13.5})

			tbl17.pr = TextLabel({
				Parent = v11,
				LayoutOrder = 1,
				Size = fn2(0, 18),
				AutomaticSize = x,
				FontFace = font4,
				TextSize = 12.5,
				TextColor3 = tbl.gv,
			})

			local v12 = Frame({
				Parent = tbl17.r,
				Position = fn2(n4 + 18, arg3 and 23 or 24),
				Size = udim2(1, -152, 0, 13),
				(fn17(8, nil, center3, horizontal)),
			})

			tbl17.rar = TextLabel({Parent = v12, Size = fn2(0, 13), AutomaticSize = x, FontFace = font3, TextSize = 9.5})
			tbl17.l1 = v11
			tbl17.l2 = v12

			tbl17.bd = TextLabel({
				Parent = tbl17.r,
				AnchorPoint = vector2(1, 0),
				Position = udim2(1, -10, 0, 5),
				Size = fn2(0, 12),
				AutomaticSize = x,
				FontFace = font3,
				TextSize = 9,
				TextColor3 = tbl.a1,
				Text = "",
			})

			tbl17.tg = TextLabel({
				Parent = v12,
				LayoutOrder = 1,
				Size = fn2(0, 13),
				AutomaticSize = x,
				FontFace = font2,
				TextSize = 9.5,
				TextColor3 = color(201, 194, 255),
			})

			local v13 = Frame({
				Parent = tbl17.r,
				Position = fn2(60, 39),
				Size = udim2(1, -152, 0, 15),
				Visible = not arg3,
				(fn17(8, nil, center3, horizontal)),
			})

			tbl17.v = TextLabel({
				Parent = v13,
				Size = fn2(0, 15),
				AutomaticSize = x,
				FontFace = font4,
				TextSize = 12,
				TextColor3 = tbl.gv,
			})

			tbl17.b = TextLabel({
				Parent = v13,
				LayoutOrder = 1,
				Size = fn2(0, 15),
				AutomaticSize = x,
				TextSize = 11,
				TextTransparency = 0.3,
			})

			tbl17.k = TextButton({
				Parent = tbl17.r,
				AnchorPoint = v4,
				Position = udim2(1, -10, 0.5, 0),
				Size = fn2(78, 32),
				BackgroundTransparency = 0,
				fn12(11),
				fn14(tbl.g1, tbl.g2),
				(TextLabel({Size = v, FontFace = font2, TextSize = 12, TextColor3 = tbl.dk, TextXAlignment = center})),
			})

			tbl17.kl = tbl17.k:FindFirstChildOfClass("TextLabel")
			fn27(tbl17.k)

			fn25(tbl17.k, function()
				if tbl17.it and tbl17.it.act then
					fn22(tbl17.it.act, tbl17.it)
				end
			end)

			fn25(tbl17.r, function()
				if not tbl17.it then
					return
				end
				id = tbl17.it.id

				for _, v14 in next, tbl15 do
					fn43(v14)
				end

				fn22(tbl17.it.pick, tbl17.it)
			end)

			return tbl17
		end

		tbl16.Set = function(arg4, arg5, text2)
			v10.Visible = #arg5 == 0

			if text2 then
				v10.Text = text2
			end

			v8.Size = udim2(1, 0, 0, #arg5 == 0 and 34 or math.min(#arg5, arg2) * n3 + 12)
			local tbl17 = {}

			for i, v11 in ipairs(arg5) do
				local v12 = tbl15[v11.id] or fn44()
				tbl15[v11.id], tbl17[v11.id] = v12, true
				v12.it = v11
				v12.r.LayoutOrder = i

				local tbl18 = {
					a = v11.title,
					pr = v11.price or v11.count,
					rar = v11.rarity,
					tg = v11.tags,
					v = v11.value,
					b = v11.sub,
					kl = v11.button,
				}

				for _, v13 in ipairs({"a", "pr", "rar", "tg", "v", "b", "kl"}) do
					local text3 = tbl18[v13] or ""

					if v12[v13].Text ~= text3 then
						v12[v13].Text = text3
					end
				end

				v12.k.Visible = v11.button ~= nil
				v12.rar.Parent, v12.rar.LayoutOrder, v12.pr.Parent, v12.pr.LayoutOrder = v11.top and v12.l1 or v12.l2, v11.top and 2 or 0, v11.top and v12.l2 or v12.l1, v11.top and 0 or 1

				if v12.bd.Text ~= (v11.badge or "") then
					v12.bd.Text = v11.badge or ""
				end

				if not v11.top then
					v12.pr.TextColor3, v12.pr.TextSize = v11.count and color(201, 194, 255) or tbl.gv, v11.count and 13.5 or 12.5
				end

				if v11.top and not v12.fx then
					v12.fx = true
					local v13
					v13, v12.pr.FontFace, v12.pr.TextSize, v12.pr.TextColor3, v12.pr.Size, v12.l2.Size = udim2, font6, 15, tbl.wh, fn2(0, 17), udim2(1, -152, 0, 17)
					v12.rar.FontFace, v12.rar.TextSize = font5, 13.5
					fn7("UIGradient", {Parent = v12.pr, Color = colorSequence, Rotation = 90})

					for _, v14 in ipairs({v12.pr, v12.rar}) do
						fn7("UIStroke", {Parent = v14, Thickness = 1.6, Color = color(0, 0, 0), Transparency = 0.05})
					end
				end

				if v12.g ~= v11.grad then
					local uiGradient = v12.rar:FindFirstChildOfClass("UIGradient")

					if uiGradient then
						uiGradient:Destroy()
					end

					v12.g = v11.grad

					if v11.grad then
						v11.grad:Clone().Parent = v12.rar
					end
				end

				v12.rar.TextColor3 = v11.grad and tbl.wh or v11.color or tbl.val
				v12.box.BackgroundColor3 = v11.color or tbl.a1

				if v12.im.Image ~= (v11.image or "") then
					v12.im.Image = v11.image or ""
				end

				fn43(v12)
			end

			for k, v11 in next, tbl15 do
				if not tbl17[k] then
					v11.r:Destroy()
					tbl15[k] = nil
				end
			end
		end

		tbl16.Select = function(arg4, arg5)
			id = arg5

			for _, v11 in next, tbl15 do
				fn43(v11)
			end
		end

		return tbl16
	end

	local function fn43(parent, arg)
		local uiGradient = parent:FindFirstChildOfClass("UIGradient")

		if uiGradient then
			uiGradient:Destroy()
		end

		if arg then
			arg:Clone().Parent = parent
		end
	end

	local function fn44(arg)
		arg.FontFace, arg.TextColor3 = font5, arg.TextColor3 or tbl.wh
		arg.TextTruncate = atEnd
		local v8 = TextLabel(arg)

		fn7("UIStroke", {
			Parent = v8,
			Thickness = math.max(1.2, arg.TextSize / 8),
			Color = color(0, 0, 0),
			Transparency = 0.05,
		})

		return v8
	end

	local new = ColorSequenceKeypoint.new

	local tbl15 = {
		COMMON = {color(30, 34, 42), color(104, 114, 132), color(214, 222, 236)},
		UNCOMMON = {color(6, 44, 22), color(36, 168, 84), color(160, 255, 170)},
		RARE = {color(6, 24, 78), color(36, 112, 255), color(140, 205, 255)},
		EPIC = {color(34, 8, 74), color(146, 56, 255), color(220, 170, 255)},
		LEGENDARY = {color(74, 30, 0), color(255, 146, 18), color(255, 228, 130)},
		MYTHIC = {color(72, 0, 22), color(255, 38, 88), color(255, 168, 190)},
		COSMIC = {color(22, 0, 40), color(128, 0, 154), color(236, 150, 255), color(92, 0, 190)},
		SECRET = {color(0, 0, 0), color(52, 52, 64), color(255, 255, 255), stars = true},
		ETERNAL = {color(4, 20, 56), color(30, 196, 220), color(255, 160, 255), color(196, 80, 255), shine = true},
		DIVINE = {
			color(84, 54, 0),
			color(255, 196, 50),
			color(255, 252, 220),
			color(255, 236, 150),
			shine = true,
			star = color(255, 255, 255),
			rays = true,
		},
	}

	local function fn45(arg)
		local color2 = arg.color or tbl.a1
		return tbl15[arg.rarity] or {color2:Lerp(color(0, 0, 0), 0.75), color2, (color2:Lerp(tbl.wh, 0.6))}
	end

	local function fn46(parent, arg, arg2, arg3)
		arg.Parent = parent
		arg.ClipsDescendants = true
		local v8 = Frame2(arg)

		local tbl16 = {
			f = v8,
			g = fn14(tbl.wh, tbl.wh, 120),
			h = {},
			st = {},
			ss = {},
			sh = fn15(30, {0, 1}, {0.4, 1}, {0.5, 0.55}, {0.6, 1}, {1, 1}),
		}

		fn12(arg2).Parent, tbl16.g.Parent = v8, v8

		for i, v9 in ipairs(arg3) do
			tbl16.h[i] = Frame2({
				Parent = v8,
				AnchorPoint = v3,
				Position = v2,
				Size = fn2(v9, v9),
				BackgroundTransparency = 0.96 - i * 0.1,
				(fn12()),
			})
		end

		for i, v9 in ipairs({{0.13, 0.28, 13}, {0.87, 0.2, 10}, {0.84, 0.72, 12}}) do
			local v10 = fn2(v9[3] * arg3[1] / 95, v9[3] * arg3[1] / 95)

			tbl16.ss[i] = fn9({
				Parent = v8,
				AnchorPoint = v3,
				Position = udim2(v9[1], 1.5, v9[2], 1.5),
				Size = v10,
				Image = "sparkles",
				ImageColor3 = color(90, 50, 0),
				ZIndex = 2,
			})

			tbl16.st[i] = fn9({
				Parent = v8,
				AnchorPoint = v3,
				Position = udim2(v9[1], 0, v9[2], 0),
				Size = v10,
				Image = "sparkles",
				ZIndex = 2,
			})
		end

		tbl16.sf = Frame({
			Parent = v8,
			Size = v,
			BackgroundColor3 = tbl.wh,
			BackgroundTransparency = 0,
			ZIndex = 4,
			tbl16.sh,
		})

		return tbl16
	end

	local function fn47(arg, arg2)
		arg.g.Color = ColorSequence.new({new(0, arg2[2]), new(0.5, arg2[4] or arg2[1]:Lerp(arg2[2], 0.4)), new(1, arg2[1])})

		for _, v8 in ipairs(arg.h) do
			v8.BackgroundColor3 = arg2[3]
		end

		if arg2.rays and not arg.ry then
			arg.ry = ImageLabel({
				Parent = arg.f,
				AnchorPoint = v3,
				Position = v2,
				Size = udim2(1.5, 0, 1.5, 0),
				SizeConstraint = Enum.SizeConstraint.RelativeXX,
				Image = "rbxassetid://109516122757226",
				ImageColor3 = color(255, 250, 215),
				ImageTransparency = 0.3,
				ScaleType = Enum.ScaleType.Fit,
			})
		end

		if arg.ry then
			arg.ry.Visible = arg2.rays == true
		end

		arg.sf.Visible = arg.live and arg2.shine == true

		for i, v8 in ipairs(arg.st) do
			v8.Visible, v8.ImageColor3 = arg2.shine or arg2.stars or false, arg2.star or arg2[3]
			v8.ImageTransparency = 0.15
			arg.ss[i].Visible, arg.ss[i].ImageTransparency = v8.Visible and arg2.star ~= nil, 0.55
		end

		for _, v8 in ipairs(arg.tw or {}) do
			v8:Cancel()
		end

		arg.tw = {}

		if arg.live then
			if not arg2.shine and not arg2.rays then
				return
			end
		else
			return
		end

		local function fn48(arg3, arg4, arg5, arg6, arg7)
			local sine = arg6 and Enum.EasingStyle.Sine
			local tween = TweenService:Create(arg3, TweenInfo.new(arg4, sine or Enum.EasingStyle.Linear, Enum.EasingDirection.InOut, -1, arg6 == true, arg7 or 0), arg5)
			tween:Play()
			arg.tw[#arg.tw + 1] = tween
		end

		arg.h[#arg.h].BackgroundTransparency = 0.82
		fn48(arg.h[#arg.h], 1.3, {BackgroundTransparency = 0.62}, true)

		if arg2.rays then
			arg.ry.Rotation = 0
			fn48(arg.ry, 30, {Rotation = 360})
		end

		if arg2.shine then
			arg.sh.Offset = vector2(-1, 0)
			fn48(arg.sh, 1.2, {Offset = vector2(1, 0)}, false, 2.2)

			for i, v8 in ipairs(arg.st) do
				v8.ImageTransparency, arg.ss[i].ImageTransparency = 0.4, 0.95
				fn48(v8, 0.9 + i * 0.25, {ImageTransparency = 0}, true)
				fn48(arg.ss[i], 0.9 + i * 0.25, {ImageTransparency = 0.55}, true)
			end
		end
	end

	local function fn48(parent)
		parent.FontFace = font6
		fn7("UIGradient", {Parent = parent, Color = colorSequence, Rotation = 90})
		return parent
	end

	local function fn49(arg, arg2, arg3)
		return ColorSequence.new({new(0, arg), new(0.5, arg2), new(1, arg3)})
	end

	local tbl16 = {
		GOLDEN = fn49(color(255, 250, 190), color(255, 204, 40), color(255, 140, 0)),
		SILVER = fn49(color(255, 255, 255), color(196, 214, 246), color(120, 146, 196)),
		RAINBOW = ColorSequence.new({
			new(0, color(255, 70, 70)),
			new(0.25, color(255, 220, 60)),
			new(0.5, color(80, 255, 110)),
			new(0.75, color(80, 170, 255)),
			new(1, color(220, 90, 255)),
		}),
		NITRO = fn49(color(255, 244, 130), color(255, 150, 30), color(255, 60, 20)),
		SCRAMBLED = fn49(color(240, 205, 255), color(186, 110, 255), color(130, 50, 240)),
		FRACTURED = fn49(color(255, 196, 186), color(255, 84, 84), color(200, 20, 40)),
		ENCHANTED = fn49(color(210, 255, 255), color(80, 225, 255), color(30, 150, 255)),
		BLOOM = fn49(color(255, 228, 244), color(255, 140, 210), color(240, 70, 160)),
		["SPIRIT BLOOM"] = fn49(color(230, 255, 210), color(130, 245, 130), color(40, 190, 90)),
		PARASITE = fn49(color(236, 255, 180), color(150, 240, 70), color(70, 180, 30)),
	}

	local function fn50(arg)
		local c = arg.c or tbl.a1

		return fn7("UIGradient", {
			Color = tbl16[arg.n:gsub("^%+", "")] or fn49(c:Lerp(tbl.wh, 0.6), c, c:Lerp(color(0, 0, 0), 0.25)),
			Rotation = arg.n == "RAINBOW" and 0 or 90,
		})
	end

	local function fn51(parent, arg, arg2, textSize)
		for _, child in ipairs(parent:GetChildren()) do
			if child:IsA("GuiObject") then
				child:Destroy()
			end
		end

		for i, v8 in ipairs(arg or {}) do
			local v9 = fn44({
				Parent = parent,
				LayoutOrder = i,
				Size = fn2(0, arg2),
				AutomaticSize = x,
				TextSize = textSize,
				Text = v8.n,
			})

			v9:FindFirstChildOfClass("UIStroke").Thickness = textSize / 5
			fn50(v8).Parent = v9
		end
	end

	local function fn52(arg, arg2)
		local v8 = tbl5[arg2]
		arg.ImageRectOffset = vector2(v8 % 8 * 64, v8 // 8 * 64)
	end

	local function fn53(parent, arg, arg2, arg3, layoutOrder)
		return Frame({
			Parent = parent,
			LayoutOrder = layoutOrder,
			Size = udim2(1, 0, 0, arg2),
			(fn7("UIGridLayout", {
				CellSize = udim2(1 / arg, -arg3 * (arg - 1) / arg - 1, 0, arg2),
				CellPadding = fn2(arg3, arg3),
				SortOrder = Enum.SortOrder.LayoutOrder,
			})),
		})
	end

	local function fn54(parent, textSize)
		local v8 = Frame({
			Parent = parent,
			Size = fn2(0, textSize + 8),
			AutomaticSize = x,
			BackgroundTransparency = 0.05,
			fn12(),
			fn13(0.2),
			fn16(0, 9),
		})

		return v8, fn44({
			Parent = v8,
			Size = fn2(0, textSize + 8),
			AutomaticSize = x,
			TextSize = textSize,
			TextXAlignment = center,
		})
	end

	local function fn55(arg, arg2, arg3, arg4)
		arg.BackgroundColor3 = arg3[1]
		arg:FindFirstChildOfClass("UIStroke").Color = arg3[2]
		arg2.Text = arg4.rarity or ""
		fn43(arg2, arg4.grad)
		arg2.TextColor3 = arg4.grad and tbl.wh or arg4.color or tbl.tx
	end

	local function fn56(arg, arg2)
		local keypoints = arg.Keypoints

		for i = 2, #keypoints do
			if arg2 <= keypoints[i].Time then
				return keypoints[i - 1].Value:Lerp(keypoints[i].Value, (arg2 - keypoints[i - 1].Time) / math.max(keypoints[i].Time - keypoints[i - 1].Time, 0.0001))
			end
		end

		return keypoints[#keypoints].Value
	end

	local tbl17 = {}

	local function fn57(arg, arg2)
		local grad = (arg2.rarity == "ETERNAL" or arg2.rarity == "DIVINE") and arg2.grad

		if grad and math.abs(grad.Rotation) == 90 then
			if not tbl17[grad] then
				local n3 = grad.Rotation < 0 and 0.53 or 0
				local n4 = grad.Rotation < 0 and 1 or 0.5
				local tbl18 = {}

				for i = 0, 8 do
					tbl18[#tbl18 + 1] = new(i / 8, fn56(grad.Color, n3 + (n4 - n3) * i / 8))
				end

				tbl17[grad] = fn7("UIGradient", {Color = ColorSequence.new(tbl18), Rotation = grad.Rotation})
			end

			grad = tbl17[grad]
		end

		fn43(arg, grad or nil)
	end

	index.Showcase = function(arg, arg2, arg3, arg4, arg5)
		local top = arg.t.top or arg.t
		local w = arg.W
		local n3 = 364
		local v8 = fn13(0.5)
		local v9 = Frame({Parent = arg.f, LayoutOrder = arg.n + 1, Size = v5, AutomaticSize = y})
		arg:Add(v9, "")
		local v10 = Frame({Parent = v9, Size = v5, AutomaticSize = y, fn16(2, 14, 6), (fn17(8))})
		local v11 = Frame({Parent = v10, Size = udim2(1, 0, 0, 30)})
		local v12 = Frame({Parent = v10, LayoutOrder = 1, Size = v5, AutomaticSize = y, (fn17(14, nil, nil, horizontal))})

		local v13 = Frame({
			Parent = Frame({Parent = v12, Size = fn2(250, 370), fn16(3, 0)}),
			Size = v,
			BackgroundTransparency = 0.45,
			fn12(20),
			v8,
			fn16(9),
			(fn17(6, center2)),
		})

		local tbl18 = {a = fn46(v13, {Size = udim2(1, 0, 0, 145)}, 14, {170, 126, 84})}
		tbl18.a.live = true

		tbl18.im = ImageLabel({
			Parent = tbl18.a.f,
			AnchorPoint = v3,
			Position = udim2(0.5, 0, 0.5, 2),
			Size = fn2(138, 138),
			ScaleType = Enum.ScaleType.Fit,
			ZIndex = 3,
		})

		local v14

		tbl18.mu = Frame({
			Parent = tbl18.a.f,
			AnchorPoint = v7,
			Position = udim2(1, -8, 0, 7),
			Size = fn2(0, 0),
			AutomaticSize = Enum.AutomaticSize.XY,
			ZIndex = 5,
			(fn17(2, Enum.HorizontalAlignment.Right)),
		})

		tbl18.ti = fn44({
			Parent = v13,
			LayoutOrder = 1,
			Size = udim2(1, 0, 0, 24),
			Text = "Pick an egg",
			TextSize = 21,
			TextXAlignment = center,
		})

		tbl18.rb, tbl18.ra = fn54(v13, 13)
		tbl18.rb.LayoutOrder = 2
		local wh
		tbl18.va = fn48(fn44({Parent = v13, LayoutOrder = 3, Size = udim2(1, 0, 0, 30), TextSize = 26, TextXAlignment = center}))
		local v15 = fn53(v13, 2, 34, 6, 4)
		local tbl19 = {}

		for i, v16 in ipairs({{"gauge", "Size"}, {"gem", "Weight"}}) do
			local v17 = Frame({
				Parent = v15,
				LayoutOrder = i,
				BackgroundTransparency = 0.55,
				BackgroundColor3 = color(0, 0, 0),
				fn12(10),
			})

			fn9({
				Parent = v17,
				AnchorPoint = vector2(0, 0.5),
				Position = udim2(0, 8, 0.5, 0),
				Size = fn2(15, 15),
				Image = v16[1],
			})

			tbl19[i] = fn44({Parent = v17, Position = fn2(29, 3), Size = udim2(1, -34, 0, 16), TextSize = 13})

			TextLabel({
				Parent = v17,
				Position = fn2(29, 19),
				Size = udim2(1, -34, 0, 11),
				Text = v16[2]:upper(),
				FontFace = font3,
				TextSize = 8,
				TextTransparency = 0.45,
			})
		end

		local v16

		local v17 = Frame({
			Parent = v13,
			LayoutOrder = 5,
			Size = udim2(1, 0, 0, 22),
			BackgroundTransparency = 0.55,
			BackgroundColor3 = color(0, 0, 0),
			ClipsDescendants = true,
			(fn12(8)),
		})

		tbl18.si = fn9({
			Parent = v17,
			AnchorPoint = vector2(0, 0.5),
			Position = udim2(0, 8, 0.5, 0),
			Size = fn2(14, 14),
			Image = "clock",
		})

		tbl19[3] = fn44({Parent = v17, Position = fn2(28, 0), Size = udim2(1, -36, 1, 0), TextSize = 11})
		tbl18.bf = Frame2({Parent = v17, AnchorPoint = vector2(0, 1), Position = udim2(0, 0, 1, 0), Size = udim2(0, 0, 0, 3)})
		local a1

		local tbl20 = {
			Parent = Frame({Parent = v13, LayoutOrder = 6, Size = udim2(1, 0, 0, 34)}),
			Size = v,
			BackgroundTransparency = 0,
		}

		v16, v14, a1, wh, v15 = fn12(12), fn14(tbl.a1, tbl.a2, 90), tbl.a1, tbl.wh, fn17
		tbl20[1], tbl20[2], tbl20[3], tbl20[4] = v16, v14, fn13(0.55, a1:Lerp(wh, 0.5)), v15(7, center2, center3, horizontal)
		local v18 = TextButton(tbl20)
		local v19 = fn9({Parent = v18, Size = fn2(17, 17), Image = "hand", ImageColor3 = tbl.on})

		local v20 = TextLabel({
			Parent = v18,
			LayoutOrder = 1,
			Size = fn2(0, 34),
			AutomaticSize = x,
			FontFace = font2,
			TextSize = 15,
			TextColor3 = tbl.on,
		})

		fn27(v18)
		local v21

		fn25(v18, function()
			if v21 then
				fn22(arg5, v21)
			end
		end)

		local v22 = Frame({
			Parent = v11,
			Size = udim2(1, -128, 1, 0),
			BackgroundTransparency = 0.93,
			fn12(),
			fn13(0.9),
			(fn16(3)),
		})

		local v23 = fn48(fn44({
			Parent = Frame({
				Parent = v11,
				AnchorPoint = v7,
				Position = udim2(1, 0, 0, 0),
				Size = fn2(120, 30),
				BackgroundTransparency = 0.8,
				BackgroundColor3 = color(60, 210, 80),
				fn12(),
				fn13(0.5, color(96, 238, 92)),
				(fn17(0, center2, center3, horizontal)),
			}),
			Size = fn2(0, 30),
			AutomaticSize = x,
			Text = "--",
			TextSize = 14,
		}))

		local v24 = Frame2({Parent = v22, Size = udim2(1 / #arg3, 0, 1, 0), fn12(), (fn14(tbl.a1, tbl.a2))})
		local tbl21 = {}
		local n4 = 1
		local v25 = fn53(v22, #arg3, 24, 0)
		local tbl22 = {}

		for i, v26 in ipairs(arg3) do
			local v27 = TextButton({Parent = v25, LayoutOrder = i, (fn17(5, center2, center3, horizontal))})

			tbl22[i] = fn9({
				Parent = v27,
				Size = fn2(14, 14),
				Image = v26[2],
				ImageColor3 = i == 1 and tbl.dk or tbl.tx,
			})

			tbl21[i] = TextLabel({
				Parent = v27,
				LayoutOrder = 1,
				Size = fn2(0, 24),
				AutomaticSize = x,
				Text = v26[1]:upper(),
				FontFace = font3,
				TextSize = 10,
				TextColor3 = i == 1 and tbl.dk or tbl.tx,
			})

			fn25(v27, function()
				tbl21[n4].TextColor3, tbl22[n4].ImageColor3 = tbl.tx, tbl.tx
				n4 = i
				tbl21[i].TextColor3, tbl22[i].ImageColor3, tbl22[i].Size = tbl.dk, tbl.dk, fn2(20, 20)
				fn19(tbl22[i], {Size = fn2(14, 14)}, 0.45, back)
				fn19(v24, {Position = udim2((i - 1) / #arg3, 0, 0, 0)}, 0.3)
				fn22(arg4, v26[1])
			end)
		end

		local v26 = Frame({Parent = v12, LayoutOrder = 1, Size = udim2(1, -264, 0, 370)})

		local v27 = ScrollingFrame({
			Parent = v26,
			Size = v,
			ScrollingEnabled = UserInputService.TouchEnabled,
			ScrollBarThickness = 3,
			ScrollBarImageColor3 = tbl.wh,
			ScrollBarImageTransparency = 0.6,
		})

		w.nest[v27] = top
		w:Grip(v27, v26)
		local v28 = fn53(v27, arg2, 178, 8)
		local v29
		v29, v28.Position, v28.Size = udim2, fn2(3, 3), udim2(1, -16, 0, 0)
		v28.AutomaticSize = y
		fn16(0, 0, 3, 0).Parent = v28

		local v30 = TextLabel({
			Parent = v27,
			Size = udim2(1, 0, 0, 40),
			Text = "No eggs yet",
			TextSize = 12,
			TextTransparency = 0.45,
			TextXAlignment = center,
		})

		local tbl23 = {}
		local tbl24 = {}
		local tbl25 = {}

		local function fn58(arg6)
			local flag = v21 ~= arg6 and (not v21 or not arg6 or v21.id ~= arg6.id or v21.muts ~= arg6.muts)
			v21 = arg6
			arg6 = arg6 or {}
			local v31 = fn45(arg6)

			if flag ~= false then
				fn47(tbl18.a, v31)
				fn55(tbl18.rb, tbl18.ra, v31, arg6)
				fn57(tbl18.ti, arg6)
				v13.BackgroundColor3, v8.Color = v31[1], v31[2]
			end

			if tbl18.m ~= arg6.muts then
				tbl18.m = arg6.muts
				fn51(tbl18.mu, arg6.muts, 20, 13)
			end

			tbl18.im.Image, tbl18.ti.Text, tbl18.va.Text = arg6.image or "", arg6.title or "Pick an egg", arg6.value or "--"

			for i, v32 in ipairs({arg6.size, arg6.weight, arg6.status}) do
				tbl19[i].Text = v32 or "--"
			end

			local tbl26 = arg6.kind == "Ready" and {"sparkles", tbl.mint} or arg6.kind == "Growing" and {"clock", tbl.wh} or {"egg", v31[3]}
			fn52(tbl18.si, tbl26[1])
			tbl18.si.ImageColor3, tbl19[3].TextColor3 = tbl26[2], tbl26[2]
			local v32
			v32, tbl18.bf.Size, tbl18.bf.BackgroundColor3 = udim2, udim2(arg6.kind == "Growing" and arg6.pct or 0, 0, 0, 3), v31[3]
			v18.Parent.Visible, v20.Text = arg6.label ~= nil, arg6.label or ""
			fn52(v19, ({["Hatch now"] = "sparkles", ["Go to egg"] = "pin"})[arg6.label] or "hand")
		end

		local function fn59()
			local y2 = v27.AbsolutePosition.Y
			local y3 = v27.AbsoluteSize.Y

			for _, v31 in next, tbl23 do
				local n5 = v31.c.AbsolutePosition.Y - y2
				local visible = n5 > -v31.c.AbsoluteSize.Y - 60 and n5 < y3 + 60

				if v31.box.Visible ~= visible then
					v31.box.Visible = visible
				end
			end
		end

		fn5(v27:GetPropertyChangedSignal("CanvasPosition"), fn59)
		fn5(v27:GetPropertyChangedSignal("AbsoluteSize"), fn59)

		local function fn60()
			local v31 = table.remove(tbl24)
			if v31 then
				v31.c.Visible = true
				return v31
			end
			local tbl26 = {s = fn13(0.1)}
			tbl26.c = TextButton({Parent = v28, BackgroundTransparency = 0.3, fn12(18), tbl26.s})
			tbl26.box = Frame({Parent = tbl26.c, Size = v})
			tbl26.a = fn46(tbl26.box, {Position = fn2(5, 5), Size = udim2(1, -10, 0, 108)}, 14, {118, 86, 56})

			tbl26.im = ImageLabel({
				Parent = tbl26.a.f,
				AnchorPoint = v3,
				Position = v2,
				Size = fn2(96, 96),
				ScaleType = Enum.ScaleType.Fit,
				ZIndex = 3,
			})

			tbl26.rk = fn44({Parent = tbl26.a.f, Position = fn2(7, 5), Size = fn2(30, 15), TextSize = 12, ZIndex = 5})

			tbl26.tm = fn44({
				Parent = tbl26.a.f,
				AnchorPoint = vector2(0, 1),
				Position = udim2(0, 7, 1, -6),
				Size = fn2(64, 15),
				TextSize = 12,
				ZIndex = 5,
			})

			tbl26.sz = fn44({
				Parent = tbl26.a.f,
				AnchorPoint = vector2(1, 1),
				Position = udim2(1, -7, 1, -6),
				Size = fn2(48, 15),
				TextSize = 11,
				TextXAlignment = Enum.TextXAlignment.Right,
				ZIndex = 5,
			})

			tbl26.mt = Frame({
				Parent = tbl26.a.f,
				AnchorPoint = v7,
				Position = udim2(1, -5, 0, 4),
				Size = fn2(0, 0),
				AutomaticSize = Enum.AutomaticSize.XY,
				ZIndex = 5,
				(fn17(1, Enum.HorizontalAlignment.Right)),
			})

			tbl26.ti = fn44({
				Parent = tbl26.box,
				Position = fn2(8, 117),
				Size = udim2(1, -16, 0, 18),
				TextSize = 14,
				TextXAlignment = center,
			})

			tbl26.rb, tbl26.ra = fn54(Frame({Parent = tbl26.box, Position = fn2(8, 137), Size = udim2(1, -16, 0, 17), (fn17(0, center2))}), 10)
			tbl26.rb.BackgroundTransparency, tbl26.rb:FindFirstChildOfClass("UIStroke").Enabled = 1, false
			tbl26.rb:FindFirstChildOfClass("UIPadding"):Destroy()

			tbl26.va = fn48(fn44({
				Parent = tbl26.box,
				Position = fn2(8, 156),
				Size = udim2(1, -16, 0, 17),
				TextSize = 14,
				TextXAlignment = center,
			}))

			tbl26.bf = Frame2({
				Parent = tbl26.a.f,
				AnchorPoint = vector2(0, 1),
				Position = udim2(0, 0, 1, 0),
				Size = udim2(0, 0, 0, 3),
				ZIndex = 5,
			})

			fn25(tbl26.c, function()
				if not tbl26.it then
					return
				end
				tbl25.sel = tbl26.it.id

				for _, v32 in next, tbl23 do
					v32.s.Thickness = v32.it.id == tbl25.sel and 2.5 or 1.2
				end

				fn58(tbl26.it)
			end)

			return tbl26
		end

		tbl25.Set = function(arg6, arg7, arg8, text)
			v30.Visible, v23.Text = #arg7 == 0, text or "--"

			for i, v31 in ipairs(arg3) do
				tbl21[i].Text = v31[1]:upper() .. (arg8 and arg8[v31[1]] and "  " .. arg8[v31[1]] or "")
			end

			local tbl26 = {}
			local v31 = nil

			for i, v32 in ipairs(arg7) do
				local v33 = tbl23[v32.id] or fn60()
				tbl23[v32.id], tbl26[v32.id] = v33, true
				v33.it = v32
				v33.c.LayoutOrder = i
				local v34 = fn45(v32)

				if v33.p ~= v34 then
					v33.p = v34
					fn47(v33.a, v34)
					fn55(v33.rb, v33.ra, v34, v32)
					fn57(v33.ti, v32)
					v33.c.BackgroundColor3, v33.s.Color = v34[1], v34[2]
				end

				v33.s.Thickness = v32.id == tbl25.sel and 2.5 or 1.2

				if v33.im.Image ~= v32.image then
					v33.im.Image = v32.image or ""
				end

				v33.rk.Text, v33.ti.Text, v33.va.Text, v33.tm.Text, v33.sz.Text = "#" .. (v32.rank or i), v32.title, v32.value, v32.time or "", v32.size or ""
				local mk = ""

				for _, v35 in ipairs(v32.muts or {}) do
					mk ..= v35.n .. ","
				end

				if v33.mk ~= mk then
					v33.mk = mk
					fn51(v33.mt, v32.muts, 14, 9)
				end

				local v35
				v35, v33.bf.Size, v33.bf.BackgroundColor3 = udim2, udim2(v32.pct or 0, 0, 0, 3), v32.ready and tbl.mint or v34[3]
				v31 = if v32.id == tbl25.sel then v32 else v31
			end

			for k, v32 in next, tbl23 do
				if not tbl26[k] then
					v32.c.Visible = false
					v32.it = nil
					v32.p = nil
					v32.mk = nil
					tbl23[k], tbl24[#tbl24 + 1] = nil, v32
				end
			end

			task.defer(fn59)
			v31 = v31 or arg7[1]
			tbl25.sel = v31 and v31.id
			fn58(v31)
		end

		tbl25.Card = function(arg6, visible)
			v13.Parent.Visible = visible
			v26.Size = udim2(1, visible and -264 or 0, 0, n3 + 6)
		end

		fn58(nil)
		return tbl25
	end

	index.Order = function(arg, arg2, arg3, arg4)
		local tbl18 = {Value = table.clone(arg3)}
		local v8 = Frame({Parent = arg.f, LayoutOrder = arg.n + 1, Size = udim2(1, 0, 0, #arg3 * 34 + 12)})
		arg:Add(v8, arg2, true)
		local tbl19 = {}

		for i = 1, #arg3 do
			local v9 = Frame({
				Parent = v8,
				Position = fn2(14, 6 + (i - 1) * 34),
				Size = udim2(1, -28, 0, 30),
				BackgroundTransparency = 0.95,
				(fn12(9)),
			})

			TextLabel({
				Parent = v9,
				Position = fn2(10, 0),
				Size = fn2(20, 30),
				Text = tostring(i),
				FontFace = font4,
				TextSize = 12,
				TextTransparency = 0.45,
			})

			tbl19[i] = TextLabel({
				Parent = v9,
				Position = fn2(34, 0),
				Size = udim2(1, -110, 1, 0),
				FontFace = font2,
				TextSize = 13,
			})

			for i2, v10 in ipairs({-1, 1}) do
				local v11 = udim2

				v11 = TextButton({
					Parent = v9,
					AnchorPoint = v4,
					Position = v11(1, i2 == 1 and -38 or -6, 0.5, 0),
					Size = fn2(28, 24),
					BackgroundTransparency = 0.9,
					fn12(7),
					(fn10("down", 14)),
				})

				v11:FindFirstChildWhichIsA("ImageLabel").Rotation = v10 < 0 and 180 or 0
				fn27(v11)

				fn25(v11, function()
					local value = tbl18.Value
					local n3 = i + v10

					if n3 < 1 then
						return
					elseif n3 > #value then
						return
					end

					value[i], value[n3] = value[n3], value[i]
					tbl18:Set(value)
				end)
			end
		end

		tbl18.Set = function(arg5, arg6, arg7)
			local tbl20 = {}
			local value = {}

			for _, v9 in ipairs(type(arg6) == "table" and arg6 or {}) do
				if table.find(arg3, v9) and not tbl20[v9] then
					tbl20[v9] = true
					value[#value + 1] = v9
				end
			end

			for i, v9 in ipairs(arg3) do
				if not tbl20[v9] then
					local n3 = #value + 1

					for i2 = i + 1, #arg3 do
						local v10 = table.find(value, arg3[i2])
						if v10 then
							n3 = v10
							break
						end
					end

					table.insert(value, n3, v9)
				end
			end

			tbl18.Value = value

			for i, v9 in ipairs(tbl19) do
				v9.Text = value[i]
			end

			if not arg7 then
				fn22(arg4, value)
			end
		end

		tbl18:Set(arg3, true)
		return arg:Reg(arg2, tbl18)
	end

	index.Text = function(arg, text)
		local v8 = TextLabel({
			Size = v5,
			AutomaticSize = y,
			Text = text,
			TextSize = 12,
			TextTransparency = 0.22,
			TextWrapped = true,
		})

		arg.tn = (arg.tn or 0) + 1

		local v9 = Frame({
			Parent = arg.f,
			Size = v5,
			AutomaticSize = y,
			LayoutOrder = -1000 + arg.tn,
			Visible = text ~= "",
			(Frame({Size = v5, AutomaticSize = y, fn16(12, 14), v8})),
		})

		if arg.n >= arg.tn then
			fn18(v9, udim2(0, 14, 1, -1), udim2(1, -28, 0, 1))
		end

		arg.n = arg.n + 1

		return {
			Set = function(arg2, text2)
				v8.Text, v9.Visible = text2, text2 ~= ""
			end,
		}
	end

	tbl6.Notify = function(arg, text, text2, arg2, arg3)
		local w = tbl6.W
		if not w then
			return
		end
		arg3 = arg3 or 4
		local v8, v9 = fn36(arg2)
		local v10 = Frame({Parent = w.nt, Size = v5, AutomaticSize = y})
		local v11 = Frame
		local tbl18 = {Position = fn2(42, 0), Size = udim2(1, -42, 0, 0), AutomaticSize = y}
		local v12 = fn17(2)
		local tbl19
		tbl18[1], tbl18[2] = v12, TextLabel({Size = udim2(1, 0, 0, 17), Text = text or "", FontFace = font2})
		local v13 = v11(tbl18)

		if text2 and text2 ~= "" then
			TextLabel({
				Parent = v13,
				LayoutOrder = 1,
				Size = v5,
				AutomaticSize = y,
				Text = text2,
				TextSize = 12,
				TextTransparency = 0.3,
				TextWrapped = true,
			})
		end

		v11, arg2, tbl19, tbl18 = Frame({
			AnchorPoint = vector2(0, 1),
			Position = udim2(0, 0, 1, 10),
			Size = udim2(1, 0, 0, 3),
			BackgroundTransparency = 0.2,
			BackgroundColor3 = v8,
			(fn12()),
		}), Frame, {
			Parent = v10,
			Position = fn2(360, 0),
			Size = v5,
			AutomaticSize = y,
			BackgroundTransparency = 0.06,
			BackgroundColor3 = color(20, 22, 46),
		}, Frame

		tbl19[1], tbl19[2], tbl19[3], tbl19[4], tbl19[5], tbl19[6] = fn12(16), fn13(0.86), fn16(14, 14, 18), v13, v11, tbl18({
			Size = fn2(30, 30),
			BackgroundTransparency = 0.8,
			BackgroundColor3 = v8,
			fn12(10),
			fn10(v9, 16, v8),
		})

		local v14 = arg2(tbl19)
		fn19(v14, {Position = udim2()}, 0.5)
		fn19(v11, {Size = fn2(0, 3)}, arg3, Enum.EasingStyle.Linear)

		task.delay(arg3, function()
			fn19(v14, {Position = fn2(360, 0)}, 0.35, quint, Enum.EasingDirection.In)
			task.delay(0.4, v10.Destroy, v10)
		end)
	end

	-- Roblox UserId whose avatar shows on admin announcements (OlwenThNek).
	tbl6.AnnounceAvatarUserId = 11464210153

	-- Centered banner at the top of the screen (from NullUI:Announce). Tap to dismiss.
	tbl6.Announce = function(arg, opts)
		opts = opts or {}
		local w = tbl6.W
		local text = tostring(opts.Text or "")

		if text == "" or not (w and w.nt and w.nt.Parent) then
			return {Dismiss = function() end}
		end

		local title = opts.Title or "Announcement"
		local duration = math.max(tonumber(opts.Duration) or 6, 1)
		local accent = opts.Color or tbl.a1
		local mobile = UserInputService.TouchEnabled and not UserInputService.MouseEnabled

		if tbl6.activeAnnounce then
			tbl6.activeAnnounce.Dismiss()
		end

		local function metrics()
			local view = workspace.CurrentCamera.ViewportSize
			local width = math.min(mobile and 320 or 400, math.max(view.X - 32, 160))
			return width, math.clamp(view.Y * 0.05, 14, 44)
		end

		local width, top = metrics()

		local card = fn7("Frame", {
			AnchorPoint = vector2(0.5, 0),
			Position = udim2(0.5, 0, 0, top - 12),
			Size = fn2(width, 0),
			AutomaticSize = y,
			BackgroundColor3 = tbl.pn,
			BackgroundTransparency = 1,
			BorderSizePixel = 0,
			ZIndex = 50,
			Active = true,
			fn12(mobile and 12 or 14),
			fn16(mobile and 8 or 10, mobile and 10 or 12),
			(fn17(mobile and 4 or 5)),
		})

		local stroke = fn13(1, accent)
		stroke.Parent = card

		local header = Frame({
			Parent = card,
			LayoutOrder = 1,
			AutomaticSize = Enum.AutomaticSize.XY,
			ZIndex = 51,
			(fn17(6, nil, center3, horizontal)),
		})

		local avatarUserId = opts.Avatar

		if avatarUserId == nil then
			avatarUserId = tbl6.AnnounceAvatarUserId
		end

		local avatar

		if avatarUserId then
			local size = mobile and 20 or 24

			avatar = fn7("ImageLabel", {
				Parent = header,
				BackgroundTransparency = 1,
				ImageTransparency = 1,
				Image = "rbxthumb://type=AvatarHeadShot&id=" .. tostring(avatarUserId) .. "&w=150&h=150",
				ScaleType = Enum.ScaleType.Crop,
				Size = fn2(size, size),
				ZIndex = 51,
				fn12(),
				(fn13(0.4, accent)),
			})
		end

		local icon = fn7("ImageLabel", {
			Parent = header,
			LayoutOrder = 1,
			BackgroundTransparency = 1,
			Image = "rbxassetid://104747300280187",
			ImageColor3 = accent,
			ImageTransparency = 1,
			Size = fn2(mobile and 13 or 15, mobile and 13 or 15),
			ZIndex = 51,
		})

		local titleLabel = fn7("TextLabel", {
			Parent = header,
			LayoutOrder = 2,
			BackgroundTransparency = 1,
			FontFace = font2,
			Text = title,
			TextColor3 = accent,
			TextTransparency = 1,
			TextSize = mobile and 12 or 13,
			AutomaticSize = Enum.AutomaticSize.XY,
			Size = fn2(0, mobile and 12 or 13),
			ZIndex = 51,
		})

		local body = fn7("TextLabel", {
			Parent = card,
			LayoutOrder = 2,
			BackgroundTransparency = 1,
			FontFace = font,
			Text = text,
			TextColor3 = tbl.tx,
			TextTransparency = 1,
			TextSize = mobile and 12 or 14,
			TextWrapped = true,
			TextXAlignment = Enum.TextXAlignment.Left,
			AutomaticSize = y,
			Size = v5,
			ZIndex = 51,
		})

		-- Admin text is shown as written.
		body:SetAttribute("NoTr", true)

		local barHolder = Frame2({
			Parent = card,
			LayoutOrder = 3,
			BackgroundColor3 = accent,
			BackgroundTransparency = 1,
			Size = udim2(1, 0, 0, 2),
			ZIndex = 51,
			(fn12(1)),
		})

		local bar = Frame2({
			Parent = barHolder,
			BackgroundColor3 = accent,
			BackgroundTransparency = 1,
			Size = v,
			ZIndex = 52,
			(fn12(1)),
		})

		card.Parent = w.nt.Parent

		local viewportConn = workspace.CurrentCamera:GetPropertyChangedSignal("ViewportSize"):Connect(function()
			local width2, top2 = metrics()
			card.Size = fn2(width2, 0)
			card.Position = udim2(0.5, 0, 0, top2)
		end)

		local dismissed = false
		local handle = {Instance = card}

		handle.Dismiss = function()
			if dismissed then
				return
			end

			dismissed = true

			if tbl6.activeAnnounce == handle then
				tbl6.activeAnnounce = nil
			end

			viewportConn:Disconnect()

			if not card.Parent then
				return
			end

			local _, top2 = metrics()
			fn19(card, {BackgroundTransparency = 1, Position = udim2(0.5, 0, 0, top2 - 12)}, 0.22)
			fn19(stroke, {Transparency = 1}, 0.22)
			fn19(icon, {ImageTransparency = 1}, 0.22)

			if avatar then
				fn19(avatar, {ImageTransparency = 1}, 0.22)
			end

			fn19(titleLabel, {TextTransparency = 1}, 0.22)
			fn19(body, {TextTransparency = 1}, 0.22)
			fn19(barHolder, {BackgroundTransparency = 1}, 0.22)
			fn19(bar, {BackgroundTransparency = 1}, 0.22)
			task.delay(0.25, card.Destroy, card)
		end

		tbl6.activeAnnounce = handle

		card.InputBegan:Connect(function(input)
			if fn23(input) then
				handle.Dismiss()
			end
		end)

		fn19(card, {BackgroundTransparency = 0.06, Position = udim2(0.5, 0, 0, top)}, 0.3)
		fn19(stroke, {Transparency = 0.55}, 0.3)
		fn19(icon, {ImageTransparency = 0}, 0.3)

		if avatar then
			fn19(avatar, {ImageTransparency = 0}, 0.3)
		end

		fn19(titleLabel, {TextTransparency = 0}, 0.3)
		fn19(body, {TextTransparency = 0}, 0.3)
		fn19(barHolder, {BackgroundTransparency = 0.85}, 0.3)
		fn19(bar, {BackgroundTransparency = 0}, 0.3)

		task.delay(0.05, function()
			if bar.Parent and not dismissed then
				fn19(bar, {Size = udim2(0, 0, 1, 0)}, duration, Enum.EasingStyle.Linear)
			end
		end)

		task.delay(duration, handle.Dismiss)
		return handle
	end

	local function fn58()
		return "VxezeHub/" .. (game.GameId ~= 0 and game.GameId or game.PlaceId) .. (tbl6.Id ~= "Vxeze Hub" and "/" .. tbl6.Id or "")
	end

	local function dir()
		return fn58() .. "/" .. localPlayer.UserId
	end

	local function fn59(arg)
		return dir() .. "/" .. arg .. ".json"
	end

	local function rd(arg)
		local ok, result = pcall(function()
			return HttpService:JSONDecode(readfile(arg))
		end)

		if ok then
			if type(result) == "table" then
				if result then
					return result
				end
			end
		end

		return nil
	end

	local function wr(arg, arg2)
		local str2 = ""

		for match in arg:gsub("/[^/]*$", ""):gmatch("[^/]+") do
			local str3 = str2 .. match
			pcall(makefolder, str3)
			str2 = str3 .. "/"
		end

		return pcall(writefile, arg, HttpService:JSONEncode(arg2))
	end

	local function fn60(arg)
		if arg == nil then
			return {z = 1}
		end
		return typeof(arg) == "Color3" and {c = arg:ToHex()} or typeof(arg) == "EnumItem" and {k = arg.Name} or arg
	end

	local function fn61(arg)
		if type(arg) ~= "table" then
			return arg
		end

		if arg.z then
			return nil
		end
		return arg.c and Color3.fromHex(arg.c) or arg.k and Enum.KeyCode[arg.k] or arg
	end

	local function fn62(arg, arg2)
		return HttpService:JSONEncode(fn60(arg)) == HttpService:JSONEncode(fn60(arg2))
	end

	local function fn63(arg)
		tbl6.busy = true

		for k, v8 in next, arg do
			local v9 = tbl6.Keys[k] or tbl6.Opt[k] or tbl6.Alias[k]
			v8 = fn61(v8)

			if v9 and not v9.Skip and not fn62(v8, v9.Value) then
				pcall(v9.Set, v9, v8)
			end
		end

		tbl6.busy = false
	end

	tbl6.Persist = function(arg)
		wr(dir() .. "/_state.json", state)
	end

	tbl6.Dir = dir
	tbl6.Rd = rd
	tbl6.Wr = wr

	tbl6.Save = function(arg, arg2, arg3)
		if arg2 then
			if not arg3 then
				arg3 = {}

				for k, v8 in next, tbl6.Keys, nil do
					if not v8.Skip then
						arg3[k] = fn60(v8.Value)
					end
				end
			end
		else
			arg2 = state.Active

			if not arg3 then
				arg3 = {}

				for k, v8 in next, tbl6.Keys, nil do
					if not v8.Skip then
						arg3[k] = fn60(v8.Value)
					end
				end
			end
		end

		local v8 = fn59(arg2)

		if isfile and isfile(v8) then
			pcall(writefile, v8 .. ".bak", readfile(v8))
		end

		return wr(v8, arg3)
	end

	tbl6.Load = function(arg, active)
		local v8 = rd(fn59(active))

		if v8 then
			if v8 then
				fn63(v8)
				state.Active = active
				tbl6:Persist()
				return true
			end
		else
			v8 = rd(fn59(active) .. ".bak")

			if v8 then
				fn63(v8)
				state.Active = active
				tbl6:Persist()
				return true
			end
		end

		return false
	end

	tbl6.Configs = function()
		local tbl18 = {}

		pcall(function()
			for _, v8 in ipairs(listfiles(dir())) do
				local match = v8:match("([^/\\]+)%.json$")

				if match then
					if match:sub(1, 1) ~= "_" then
						tbl18[#tbl18 + 1] = match
					end
				end
			end
		end)

		table.sort(tbl18)
		return tbl18
	end

	tbl6.Delete = function(arg, arg2)
		local v8 = rd(fn59(arg2))

		if v8 then
			wr(dir() .. "/_trash/" .. arg2 .. ".json", v8)
		else
			v8 = rd(fn59(arg2) .. ".bak")

			if v8 then
				wr(dir() .. "/_trash/" .. arg2 .. ".json", v8)
			end
		end

		pcall(delfile, fn59(arg2))
		pcall(delfile, fn59(arg2) .. ".bak")

		if state.Active == arg2 then
			tbl6:Load("Default")
		end

		tbl6:Persist()
	end

	tbl6.Trash = function(arg)
		local tbl18 = {}

		pcall(function()
			for _, v8 in ipairs(listfiles(dir() .. "/_trash")) do
				tbl18[#tbl18 + 1] = v8:match("([^/\\]+)%.json$")
			end
		end)

		table.sort(tbl18)
		return tbl18
	end

	tbl6.Restore = function(arg, arg2)
		local str2 = dir() .. "/_trash/" .. arg2 .. ".json"
		local v8 = rd(str2)
		local v9 = tbl6:Name(arg2)

		if v8 then
			if v9 then
				tbl6:Save(v9, v8)
				pcall(delfile, str2)
				return v9
			end

			return
		end
	end

	tbl6.Name = function(arg, arg2)
		arg2 = tostring(arg2 or ""):match("^%s*(.-)%s*$")
		if arg2 ~= "" and not arg2:match("^[%w _%-]+$") then
			return nil, "Use letters, numbers, spaces, - or _"
		end

		if #arg2 > 32 then
			return nil, "32 characters at most"
		end
		local str2 = arg2 ~= "" and arg2 or "Config"
		arg2 = if arg2 == "" then "Config 1" else arg2
		local n3 = 2

		while true do
			if not (isfile and isfile(fn59(arg2))) then
				break
			end
			arg2, n3 = str2 .. " " .. n3, n3 + 1
		end

		return arg2
	end

	tbl6.Export = function(arg, name)
		return HttpService:JSONEncode({ vxeze = 1, name = name, data = rd(fn59(name)) or {} })
	end

	tbl6.Import = function(arg, arg2)
		local ok, data = pcall(HttpService.JSONDecode, HttpService, tostring(arg2 or ""))

		if ok then
			local v8, name, str2, v9, jsonEncode, data2

			if type(data) ~= "table" or data.vxeze ~= nil then
				if ok then
					if type(data) ~= "table" then
						return nil, "Not a Vxeze Hub config text"
					end

					if data.vxeze ~= 1 then
						return nil, "Not a Vxeze Hub config text"
					end

					if type(data.data) ~= "table" then
						return nil, "Not a Vxeze Hub config text"
					end
					v8 = tbl6
					name = tbl6.Name
					local v10 = tostring
					local name2 = data.name or "Imported"
					str2 = v10(name2):gsub("[^%w _%-]", "")
					v9 = name(v8, str2)

					if v9 then
						tbl6:Save(v9, data.data)
						jsonEncode = HttpService.JSONEncode
						data2 = data.data
						pcall(writefile, fn59(v9) .. ".bak", jsonEncode(HttpService, data2))
						return v9
					end

					return nil, "Bad config name"
				end
			else
				for k in next, data, nil do
					if type(k) == "string" and k:find(" / ", 1, true) then
						data = { vxeze = 1, data = data }
						break
					end
				end

				if ok then
					if type(data) ~= "table" then
						return nil, "Not a Vxeze Hub config text"
					end

					if data.vxeze ~= 1 then
						return nil, "Not a Vxeze Hub config text"
					end

					if type(data.data) ~= "table" then
						return nil, "Not a Vxeze Hub config text"
					end
					v8 = tbl6
					name = tbl6.Name
					str2 = tostring(data.name or "Imported"):gsub("[^%w _%-]", "")
					v9 = name(v8, str2)

					if v9 then
						tbl6:Save(v9, data.data)
						jsonEncode = HttpService.JSONEncode
						data2 = data.data
						pcall(writefile, fn59(v9) .. ".bak", jsonEncode(HttpService, data2))
						return v9
					end

					return nil, "Bad config name"
				end
			end
		end

		return nil, "Not a Vxeze Hub config text"
	end

	tbl6.Dirty = function(arg)
		tbl6.tok = (tbl6.tok or 0) + 1
		local tok = tbl6.tok

		task.delay(1, function()
			if tbl6.tok == tok then
				tbl6:Save()
			end
		end)
	end

	tbl6.Reset = function(arg)
		tbl6.busy = true

		for _, v8 in next, tbl6.Keys do
			if not v8.Skip and not fn62(v8.Def, v8.Value) then
				pcall(v8.Set, v8, type(v8.Def) == "table" and table.clone(v8.Def) or v8.Def)
			end
		end

		tbl6.busy = false
		tbl6:Save()
	end

	tbl6.Off = function(arg)
		local n3 = 0

		for _, v8 in next, tbl6.Keys do
			if v8.Kind == "toggle" and v8.Value and not v8.Skip then
				v8:Set(false)
				n3 += 1
			end
		end

		return n3
	end

	tbl6.Theme = function(arg, th)
		local v8 = nil

		for _, v9 in ipairs(tbl2) do
			v8 = if v9[1] == th then v9 else v8
		end

		if not v8 then
			return
		end
		local w = tbl6.W

		if tbl6.th ~= th then
			tbl6.th = th

			local tbl18 = {
				w1 = v8[2],
				w2 = v8[3],
				a1 = v8[4],
				a2 = v8[5],
				sky = v8[4]:Lerp(tbl.wh, 0.2),
				g1 = v8[5]:Lerp(tbl.wh, 0.35),
				g2 = v8[4],
				val = v8[5]:Lerp(tbl.wh, 0.7),
				pn = v8[2]:Lerp(v8[3], 0.55),
				bg = v8[2]:Lerp(v8[3], 0.75),
				on = v8[6] or color(255, 255, 254),
			}

			local tbl19 = {}

			for _, v9 in ipairs({0.35, 0.4, 0.5}) do
				tbl19[tbl.a1:Lerp(tbl.wh, v9):ToHex()] = tbl18.a1:Lerp(tbl.wh, v9)
			end

			tbl19[tbl.sky:Lerp(tbl.wh, 0.55):ToHex()] = tbl18.sky:Lerp(tbl.wh, 0.55)

			for k, v9 in next, tbl18 do
				tbl19[tbl[k]:ToHex()] = v9
				tbl[k] = v9
			end

			tbl19[tbl.wh:ToHex()], tbl19[tbl.tx:ToHex()] = nil, nil

			local function fn64(arg2)
				return tbl19[arg2:ToHex()]
			end

			for _, v9 in ipairs({w and w.Gui, w and w.nt and w.nt.Parent}) do
				for _, v10 in ipairs(v9 and v9:GetDescendants() or {}) do
					if not (v10:FindFirstAncestor("VxezeThemes") or v10.Parent == w.bg) then
						if v10:IsA("GuiObject") then
							v10.BackgroundColor3 = fn64(v10.BackgroundColor3) or v10.BackgroundColor3

							if v10:IsA("TextLabel") or v10:IsA("TextButton") or v10:IsA("TextBox") then
								v10.TextColor3 = fn64(v10.TextColor3) or v10.TextColor3
							end

							if v10:IsA("ImageLabel") or v10:IsA("ImageButton") then
								v10.ImageColor3 = fn64(v10.ImageColor3) or v10.ImageColor3
							end
						elseif v10:IsA("UIStroke") then
							v10.Color = fn64(v10.Color) or v10.Color
						elseif v10:IsA("UIGradient") then
							local tbl20 = {}

							for i, keypoint in ipairs(v10.Color.Keypoints) do
								tbl20[i] = ColorSequenceKeypoint.new(keypoint.Time, fn64(keypoint.Value) or keypoint.Value)
							end

							v10.Color = ColorSequence.new(tbl20)
						end
					end
				end
			end
		end

		state.Theme = th

		if w then
			w:Tint()
		end

		for k, v9 in next, w and w.marks or {} do
			fn19(v9[1], {Transparency = k == th and 0.3 or 0.86, Color = k == th and v8[4] or tbl.wh}, 0.2)
			fn19(v9[2], {ImageTransparency = k == th and 0 or 1}, 0.2)
		end

		tbl6:Persist()
	end

	tbl6.Boot = function()
		if not rd(dir() .. "/_state.json") then
			pcall(function()
				for _, v8 in ipairs(listfiles(fn58())) do
					local match = v8:match("([^/\\]+%.json)$")
					local v9

					if match then
						v9 = rd(fn58() .. "/" .. match)
						if not v9 then
							continue
						end
					else
						v9 = match
						if not v9 then
							continue
						end
					end

					wr(dir() .. "/" .. match, v9)
				end
			end)
		end

		local v8 = rd(dir() .. "/_state.json")

		if v8 then
			for k in next, state, nil do
				if v8[k] ~= nil then
					state[k] = v8[k]
				end
			end

			if v8 then
				if v8.Cfg ~= 2 then
					local v9 = state
					local v10 = state
					state.AutoLoad = true
					v9.AutoSave = true
					v10.Cfg = 2
				end
			end
		end

		task.defer(function()
			RunService.Heartbeat:Wait()
			RunService.Heartbeat:Wait()

			if isfile then
				if not isfile(fn59("Default")) then
					tbl6:Save("Default")
				end
			else
				tbl6:Save("Default")
			end

			if state.AutoLoad then
				tbl6:Load(state.Active)
			end

			tbl6:Theme(state.Theme)
		end)
	end

	-- Global chat (ported from NullUI's AddGlobalChatPanel). Lucide asset ids for the icons
	-- the panel uses; the hub's own sprite sheet doesn't have them.
	local chatIcons = {
		["messages-square"] = 109110355978624,
		copy = 87942399647942,
		["eye-off"] = 112375739491233,
		eye = 139722329189430,
		["trash-2"] = 79564839810840,
		settings = 101463883805422,
		x = 73070135088117,
		mail = 107247149114562,
		send = 120131238507529,
		["chevron-up"] = 124630674114245,
		["chevron-down"] = 95086910949405,
		["user-round"] = 122472562648438,
		reply = 138678897436694,
		flag = 80165228709790,
		check = 83827110621355,
	}

	-- Talks to the Fluent global chat relay (camelCase JSON, string ids, ISO timestamps,
	-- X-Global-Chat-Key header) and hands the panel NullUI-shaped messages.
	tbl6.ChatService = function(arg, config)
		local MarketplaceService = fn("MarketplaceService")
		local endpoint = config.Endpoint:gsub("/+$", "")
		local httpRequest = request
			or http_request
			or (syn and syn.request)
			or function(req)
				return HttpService:RequestAsync(req)
			end
		local playerId = tostring(localPlayer.UserId)
		local playerName = localPlayer.DisplayName or localPlayer.Name
		do
			local ok, off = pcall(utf8.offset, playerName, 4)
			playerName = (ok and (off and playerName:sub(1, off - 1) or playerName) or playerName:sub(1, 3)) .. "*****"
		end
		local gameName = config.GameName
		if not gameName then
			local ok, info = pcall(MarketplaceService.GetProductInfo, MarketplaceService, game.PlaceId)
			gameName = ok and info.Name or "Unknown game"
		end
		local avatarUrl = "https://www.roblox.com/headshot-thumbnail/image?userId=" .. playerId .. "&width=150&height=150&format=png"

		local function idFor(id)
			return tonumber(id) or 0
		end

		local service = {ChatMeta = {OnlineCount = 0}}

		local function call(method, path, body, query)
			local ok, res = pcall(httpRequest, {
				Url = endpoint .. (path or "") .. (query or ""),
				Method = method,
				Headers = {["Content-Type"] = "application/json", ["X-Global-Chat-Key"] = config.ApiKey},
				Body = body and HttpService:JSONEncode(body) or nil,
			})
			if not ok or type(res) ~= "table" then
				return nil, tostring(res)
			end
			local decoded, data = pcall(HttpService.JSONDecode, HttpService, res.Body or "")
			if not res.Success then
				local msg = decoded and type(data) == "table" and data.error
				return nil, msg or res.StatusMessage or "Request failed"
			end
			if not decoded or type(data) ~= "table" then
				return nil, "Invalid chat response"
			end
			return data
		end

		local function toMs(iso)
			local ok, dt = pcall(DateTime.fromIsoDate, iso)
			return ok and dt and dt.UnixTimestampMillis or os.time() * 1000
		end

		local function convert(m)
			local join = type(m.joinServer) == "table" and m.joinServer or nil
			local reply = type(m.reply) == "table" and m.reply or nil
			return {
				Id = idFor(m.id),
				UserId = tonumber(m.playerId) or 0,
				PlayerName = m.playerName,
				GameName = m.gameName,
				SenderTag = m.senderTag,
				Text = m.content,
				CreatedAt = toMs(m.createdAt),
				Reply = reply and {PlayerName = reply.playerName, Content = reply.content} or nil,
				JoinServer = join and {PlaceId = join.placeId, JobId = join.jobId} or nil,
			}
		end

		-- With `after` the relay only returns newer messages, so a quiet chat stays cheap.
		local function fetch(sinceId)
			local query = "?limit=" .. tostring(config.MaxMessages or 50)
			if sinceId and sinceId > 0 then
				query = query .. "&after=" .. tostring(sinceId)
			end
			local data, err = call("GET", nil, nil, query)
			if not data then
				return nil, err
			end
			local pinned = type(data.pinnedMessage) == "table" and data.pinnedMessage or nil
			local deletedIds = {}
			for _, id in ipairs(type(data.deletedIds) == "table" and data.deletedIds or {}) do
				table.insert(deletedIds, idFor(id))
			end
			service.ChatMeta = {
				Pinned = pinned and {Content = pinned.content, UpdatedByName = pinned.updatedByName} or nil,
				OnlineCount = tonumber(data.onlineCount) or 0,
				DeletedIds = deletedIds,
				Announcement = type(data.announcement) == "table" and {
					Id = tostring(data.announcement.id),
					Title = "Announcement",
					Content = data.announcement.content,
					RemainingMs = tonumber(data.announcement.remainingMs) or 0,
				} or nil,
				Mailbox = type(data.mailbox) == "table" and {
					LatestId = tonumber(data.mailbox.latestId) or 0,
					Count = tonumber(data.mailbox.count) or 0,
				} or nil,
			}
			return type(data.messages) == "table" and data.messages or {}
		end

		function service:PollChatMessages(sinceId)
			local raw, err = fetch(sinceId)
			if not raw then
				return nil, err
			end
			local out = {}
			for _, m in ipairs(raw) do
				local converted = convert(m)
				if converted.Id > (sinceId or 0) then
					table.insert(out, converted)
				end
			end
			return out
		end

		function service:SendChatMessage(_, text, extra)
			extra = extra or {}
			local data, err = call("POST", nil, {
				playerId = playerId,
				playerName = extra.PlayerName or playerName,
				gameName = extra.GameName or gameName,
				avatarUrl = avatarUrl,
				content = text,
				replyToId = extra.ReplyToId and tostring(extra.ReplyToId) or nil,
			})
			if not data then
				return nil, err
			end
			-- The relay answers with the stored message (it may rewrite blocked links).
			local posted = type(data.message) == "table" and data.message or data
			return {Id = idFor(posted.id), Text = type(posted.content) == "string" and posted.content or nil}
		end

		function service:GetMailbox()
			local data, err = call("GET", "/mailbox")
			if not data then
				return nil, err
			end
			local out = {}
			for _, entry in ipairs(type(data.items) == "table" and data.items or {}) do
				table.insert(out, {
					Id = tonumber(entry.id) or 0,
					Title = entry.title,
					Content = entry.content,
					Author = entry.createdByName,
					CreatedAt = toMs(entry.createdAt),
					Edited = type(entry.updatedAt) == "string",
				})
			end
			return out
		end

		function service:ReportChatMessage(messageId, reason)
			if not messageId or messageId <= 0 then
				return false, "Unknown message"
			end
			local data, err = call("POST", "/report", {
				reporterPlayerId = playerId,
				reporterPlayerName = playerName,
				messageId = tostring(messageId),
				reason = reason,
			})
			return data ~= nil, err
		end

		function service:PublishChatPresence(_, allowJoin, placeId, jobId)
			local data, err = call("POST", "/presence", {
				playerId = playerId,
				allowJoin = allowJoin,
				placeId = allowJoin and placeId or nil,
				jobId = allowJoin and jobId or nil,
			})
			return data ~= nil, err
		end

		function service:GetChatJoinTarget(userId)
			local data, err = call("GET", "/presence/" .. tostring(userId))
			if not data then
				return nil, err
			end
			local join = data.joinServer
			return type(join) == "table" and {PlaceId = join.placeId, JobId = join.jobId} or nil
		end

		return service
	end

	-- w:GlobalChat(opts) builds a "Chat" tab. opts.Service (NullUI-shaped) or
	-- opts.Endpoint + opts.ApiKey for the Fluent relay.
	tbl6.GlobalChat = function(arg, w, opts)
		opts = opts or {}
		local Players = fn("Players")
		local TextService = fn("TextService")
		local LocalPlayer = localPlayer
		local IsMobileDevice = UserInputService.TouchEnabled and not UserInputService.MouseEnabled

		local service = opts.Service
		if not service and opts.Endpoint then
			service = tbl6:ChatService({
				Endpoint = opts.Endpoint,
				ApiKey = opts.ApiKey,
				GameName = opts.GameName,
				MaxMessages = opts.MaxMessages,
			})
		end

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

		local function hasFn(name)
			local ok, v = pcall(function()
				return getgenv and getgenv()[name] or getfenv(0)[name]
			end)
			return ok and type(v) == "function" and v or nil
		end

		local fn_isfolder, fn_makefolder = hasFn("isfolder"), hasFn("makefolder")
		local fn_isfile, fn_readfile, fn_writefile = hasFn("isfile"), hasFn("readfile"), hasFn("writefile")

		-- Colors follow the hub theme (read on use, so theme switches apply to new rows).
		local Theme = setmetatable({Font = font2, FontRegular = font}, {
			__index = function(_, k)
				if k == "Text" then
					return tbl.tx
				elseif k == "TextDim" then
					return color(168, 174, 204)
				elseif k == "Accent" then
					return tbl.a1
				elseif k == "Surface" then
					return tbl.pn
				elseif k == "Danger" then
					return tbl.red
				end
			end,
		})

		local Tween = fn19

		local function Corner(parent, radius)
			local c = Instance.new("UICorner")
			c.CornerRadius = udim(0, radius)
			c.Parent = parent
			return c
		end

		local function Stroke(parent, color2, thickness, transparency)
			local s = Instance.new("UIStroke")
			s.Color = color2 or tbl.wh
			s.Thickness = thickness or 1
			s.Transparency = transparency or 0.9
			s.ApplyStrokeMode = Enum.ApplyStrokeMode.Border
			s.Parent = parent
			return s
		end

		local function ResolveIcon(icon)
			if type(icon) ~= "string" or icon == "" then
				return ""
			elseif icon:match("^%a[%w%+%-%.]*://") then
				return icon
			elseif icon:match("^%d+$") then
				return "rbxassetid://" .. icon
			end
			return chatIcons[icon] and "rbxassetid://" .. chatIcons[icon] or ""
		end

		local measureCache = {}

		local function MeasureText(text, size, maxWidth)
			text = tostring(text or "")
			maxWidth = maxWidth or 10000
			local key = text .. "\1" .. size .. "\1" .. math.floor(maxWidth)
			local cached = measureCache[key]
			if cached then
				return cached.X, cached.Y
			end
			local ok, bounds = pcall(function()
				return TextService:GetTextSize(text, size, Enum.Font.MontserratBold, vector2(maxWidth, 100000))
			end)
			local w2, h
			if ok and bounds then
				w2, h = math.ceil(bounds.X * 1.06), math.ceil(bounds.Y)
			else
				w2, h = math.ceil(#text * size * 0.55), size + 2
			end
			measureCache[key] = vector2(w2, h)
			return w2, h
		end

		-- AbsoluteSize includes the window's UIScale; layout math works in unscaled px.
		local function GetUIScale()
			return math.max(w.Main.AbsoluteSize.X / 832, 0.1)
		end

		local notifyKinds = {success = "ok", error = "err", warning = "warn"}

		local function notify(t)
			tbl6:Notify(t.Title, t.Text, notifyKinds[t.Type], t.Duration)
		end

		local function announce(t)
			return tbl6:Announce(t)
		end

		local function confirm(t)
			w:Dialog({
				Title = t.Title,
				Text = t.Text,
				Kind = "warn",
				Buttons = {
					{t.CancelText or "Cancel"},
					{
						t.ConfirmText or "OK",
						function()
							t.Callback(true)
						end,
						true,
					},
				},
			})
		end

		-- Every connection the panel makes, dropped when the panel goes away.
		local conns = {}
		local jan = {
			Add = function(_, c)
				conns[#conns + 1] = c
				return c
			end,
		}

		-- Tab-change hook: the hub's Select has no listeners, so wrap it once per window.
		if not w.tabListeners then
			w.tabListeners = {}
			local baseSelect = w.Select
			w.Select = function(arg3, cur)
				local before = w.Cur
				baseSelect(arg3, cur)
				if w.Cur ~= before then
					for _, f in ipairs(w.tabListeners) do
						task.spawn(f, w.Cur)
					end
				end
			end
		end
		local tabListeners = w.tabListeners

		local tabObj = w:Tab(opts.Name or "Chat", ResolveIcon(opts.Icon or "messages-square"), true)
		tabObj.Title = opts.Title or opts.Name or "Chat"

		local function isShown()
			return w.Cur == tabObj and w.open
		end

		table.insert(tabListeners, function(selected)
			if opts.OnToggle then
				task.spawn(opts.OnToggle, selected == tabObj)
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
		panel.ZIndex = 2
		panel.Parent = tabObj.sc

		panel.Destroying:Connect(function()
			for _, c in ipairs(conns) do
				c:Disconnect()
			end
			table.clear(conns)
		end)

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
		titleIcon.ImageColor3 = Theme.Text
		titleIcon.Size = UDim2.fromOffset(14, 14)
		titleIcon.LayoutOrder = 1
		titleIcon.ZIndex = BASE_Z + 2
		titleIcon.Parent = titleRow

		local titleLabel = Instance.new("TextLabel")
		titleLabel.BackgroundTransparency = 1
		titleLabel.FontFace = Theme.Font
		titleLabel.Text = opts.Title or "Chat"
		titleLabel.TextColor3 = Theme.Text
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
			ic.ImageColor3 = Theme.TextDim
			ic.Size = UDim2.fromOffset(13, 13)
			ic.AnchorPoint = Vector2.new(0.5, 0.5)
			ic.Position = UDim2.fromScale(0.5, 0.5)
			ic.ZIndex = BASE_Z + 2
			ic.Parent = btn

			jan:Add(btn.MouseEnter:Connect(function()
				Tween(btn, { BackgroundTransparency = 0.9 }, 0.12)
				Tween(ic, { ImageColor3 = Theme.Text }, 0.12)
			end))
			jan:Add(btn.MouseLeave:Connect(function()
				Tween(btn, { BackgroundTransparency = 1 }, 0.12)
				Tween(ic, { ImageColor3 = Theme.TextDim }, 0.12)
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
		mailboxNotice.FontFace = Theme.FontRegular
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
		inputBox.FontFace = Theme.FontRegular
		inputBox.PlaceholderText = opts.Placeholder or "Message everyone using this script..."
		inputBox.PlaceholderColor3 = Color3.fromRGB(120, 120, 122)
		inputBox.Text = ""
		inputBox.TextColor3 = Theme.Text
		inputBox.TextSize = 13
		inputBox.TextXAlignment = Enum.TextXAlignment.Left
		inputBox.TextYAlignment = Enum.TextYAlignment.Center
		inputBox.ClipsDescendants = true
		inputBox.Size = UDim2.fromScale(1, 1)
		inputBox.ZIndex = BASE_Z + 2
		inputBox.Parent = pill

		jan:Add(inputBox.Focused:Connect(function()
			Tween(pillStroke, { Color = Theme.Accent, Transparency = 0.3 }, 0.18)
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
		sendIcon.ImageColor3 = Theme.Text
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

		msgScroll.ScrollBarThickness = 3
		msgScroll.ScrollBarImageTransparency = 0.7

		local chatEmpty = Instance.new("TextLabel")
		chatEmpty.Name = "ChatEmptyState"
		chatEmpty.BackgroundTransparency = 1
		chatEmpty.FontFace = Theme.Font
		chatEmpty.Text = service and "No messages yet. Say hello!" or "Global chat is not configured by the script owner."
		chatEmpty.TextColor3 = Theme.TextDim
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
			local atBottom = msgScroll.CanvasPosition.Y
				>= msgScroll.AbsoluteCanvasSize.Y - msgScroll.AbsoluteWindowSize.Y - 20
			pinnedToBottom = atBottom
		end))

		local function scrollToBottom()
			pinnedToBottom = true
			task.defer(function()
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
		pin.Meta.FontFace = Theme.Font
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
		pin.Text.FontFace = Theme.FontRegular
		pin.Text.Text = ""
		pin.Text.TextColor3 = Theme.Text
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
			task.defer(function()
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
		replyLabel.FontFace = Theme.FontRegular
		replyLabel.TextColor3 = Theme.TextDim
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
		replyCancel.FontFace = Theme.Font
		replyCancel.TextSize = 16
		replyCancel.TextColor3 = Theme.TextDim
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
		reportCard.BackgroundColor3 = Theme.Surface
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
		reportText("Report chat / user", 13, 9, 18, Theme.Font, Theme.Text)
		local reportTarget = reportText("", 11, 28, 14, Theme.FontRegular, Theme.TextDim)

		local reportInput = Instance.new("TextBox")
		reportInput.BackgroundColor3 = Color3.new(1, 1, 1)
		reportInput.BackgroundTransparency = 0.94
		reportInput.BorderSizePixel = 0
		reportInput.ClearTextOnFocus = false
		reportInput.MultiLine = true
		reportInput.TextWrapped = true
		reportInput.FontFace = Theme.FontRegular
		reportInput.PlaceholderText = "Enter report reason..."
		reportInput.PlaceholderColor3 = Color3.fromRGB(120, 120, 122)
		reportInput.Text = ""
		reportInput.TextColor3 = Theme.Text
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
			b.FontFace = Theme.Font
			b.TextSize = 11
			b.TextColor3 = Theme.Text
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
				notify({ Title = "Report", Text = "Enter a report reason.", Type = "warning", Duration = 3 })
				return
			end
			reportBusy = true
			reportSubmit.Text = "Sending..."
			task.spawn(function()
				local ok, err = service:ReportChatMessage(reportingMsg.Id, reason)
				reportBusy = false
				reportSubmit.Text = "Send report"
				if ok then
					closeReport()
				end
				notify({
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
			confirm({
				Title = "Join server?",
				Text = "Join " .. maskedName(msg.PlayerName or "this player") .. " in " .. tostring(msg.GameName or "their game")
					.. "? You will leave your current server.",
				ConfirmText = "Join",
				CancelText = "Cancel",
				Callback = function(confirmed)
					if not confirmed then
						return
					end
					task.spawn(function()
						local target = type(msg.JoinServer) == "table" and msg.JoinServer or nil
						if service.GetChatJoinTarget and msg.UserId and msg.UserId ~= 0 then
							-- Ask the relay for the fresh target; the one on the message may be stale.
							target = service:GetChatJoinTarget(msg.UserId)
						end
						local placeId = type(target) == "table" and tonumber(target.PlaceId) or nil
						local jobId = type(target) == "table" and target.JobId or nil
						if not placeId or type(jobId) ~= "string" or jobId == "" then
							notify({
								Title = "Chat",
								Text = "This player is no longer sharing a server.",
								Type = "warning",
								Duration = 3,
							})
							return
						end
						if placeId == game.PlaceId and jobId == game.JobId then
							notify({ Title = "Chat", Text = "You are already in this server.", Type = "info", Duration = 3 })
							return
						end
						local ok, err = pcall(function()
							game:GetService("TeleportService"):TeleportToPlaceInstance(placeId, jobId, LocalPlayer)
						end)
						if not ok then
							notify({ Title = "Chat", Text = "Join failed: " .. tostring(err), Type = "error", Duration = 3 })
						end
					end)
				end,
			})
		end

		-- Rendered rows by message id, so messages deleted by an admin can be removed.
		local rowsById = {}

		local avatarCache = {}

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

			avatar.BackgroundColor3 = isAnon and Color3.fromRGB(196, 143, 105) or Theme.Accent
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
				-- One thumbnail request per user: busy chats repeat the same senders constantly.
				local cachedAvatar = avatarCache[msg.UserId]
				if cachedAvatar then
					avatarImg.Image = cachedAvatar
				else
					task.spawn(function()
						local ok, content = pcall(
							Players.GetUserThumbnailAsync,
							Players,
							msg.UserId,
							Enum.ThumbnailType.HeadShot,
							Enum.ThumbnailSize.Size100x100
						)
						if ok and content then
							avatarCache[msg.UserId] = content
							if avatarImg.Parent then
								avatarImg.Image = content
							end
						end
					end)
				end
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
			bubble.BackgroundColor3 = isOwn and Theme.Accent or Color3.new(1, 1, 1)
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
				metaLbl.FontFace = Theme.Font
				metaLbl.RichText = true
				metaLbl.Text = metaText
				metaLbl.TextColor3 = isOwn and Color3.new(1, 1, 1) or Theme.TextDim
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
				quote.FontFace = Theme.FontRegular
				quote.Text = "↪ " .. maskedName(tostring(replyData.PlayerName or "Guest")) .. ": " .. tostring(replyData.Content)
				quote.TextColor3 = isOwn and Color3.new(1, 1, 1) or Theme.TextDim
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
			label.FontFace = Theme.FontRegular
			label.Text = text
			label.TextColor3 = Theme.Text
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
				timeLbl.FontFace = Theme.FontRegular
				timeLbl.Text = os.date("%H:%M", math.floor(msg.CreatedAt / 1000))
				timeLbl.TextColor3 = isOwn and Color3.new(1, 1, 1) or Theme.TextDim
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
					icon.ImageColor3 = Theme.TextDim
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
						Tween(icon, { ImageColor3 = Theme.TextDim, ImageTransparency = 0.2 }, 0.12)
					end))
					jan:Add(btn.MouseButton1Click:Connect(function()
						onClick(icon)
					end))
				end

				addAction(1, "copy", Color3.fromRGB(120, 220, 140), function(icon)
					local setclipboard = hasFn("setclipboard")
					if not setclipboard then
						notify({ Title = "Chat", Text = "Clipboard is not available.", Type = "warning", Duration = 3 })
						return
					end
					pcall(setclipboard, text)
					icon.ImageColor3 = Color3.fromRGB(120, 220, 140)
					task.delay(0.6, function()
						if icon.Parent then
							Tween(icon, { ImageColor3 = Theme.TextDim }, 0.18)
						end
					end)
				end)
				addAction(2, "reply", Theme.Text, function()
					setReply(msg)
				end)
				if not isOwn then
					addAction(3, "flag", Theme.Danger, function()
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
				joinBtn.FontFace = Theme.Font
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
			task.delay(0.4, function()
				if copyIcon.Parent then
					Tween(copyIcon, { ImageColor3 = Theme.TextDim }, 0.18)
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
				announcementHandle = announce({
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
				notify({
					Title = "Chat",
					Text = string.format("Slow down -- wait %.1fs.", wait),
					Type = "warning",
					Duration = 2,
				})
				return
			end
			if not service then
				notify({
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
			task.spawn(function()
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
					notify({ Title = "Chat", Text = tostring(err), Type = "error", Duration = 3 })
					return
				end
				-- Only remember the id so the poll doesn't draw this message twice. Moving
				-- lastSeenId up to it would skip messages other people sent between the last
				-- poll and this send (their ids are lower), and those would never appear.
				seenIds[result.Id] = true
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
			notify({
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
			if isShown() then
				if w.Tabs[1] and w.Tabs[1] ~= tabObj then
					w:Select(w.Tabs[1])
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
			popup.BackgroundColor3 = Theme.Surface
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
				lbl.FontFace = Theme.FontRegular
				lbl.Text = label
				lbl.TextColor3 = Theme.Text
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
				checkIcon.ImageColor3 = Theme.Accent
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
						notify({
							Title = "Chat",
							Text = "Join sharing needs a public game server.",
							Type = "warning",
							Duration = 3,
						})
						return false
					end
					allowJoin = not allowJoin
					task.spawn(function()
						local ok, err = publishPresence()
						if not ok then
							allowJoin = not allowJoin
							notify({ Title = "Chat", Text = tostring(err), Type = "error", Duration = 3 })
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
		local MAILBOX_SEEN_FILE = "VxezeHub/global_chat_mailbox_seen.txt"
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
		if hasMailbox and tabObj.im then
			tabDot = Instance.new("Frame")
			tabDot.Name = "MailboxDot"
			tabDot.AnchorPoint = Vector2.new(0.5, 0.5)
			tabDot.Position = UDim2.new(1, 0, 0, 1)
			tabDot.Size = UDim2.fromOffset(7, 7)
			tabDot.BackgroundColor3 = Color3.fromRGB(239, 68, 68)
			tabDot.BorderSizePixel = 0
			tabDot.Visible = false
			tabDot.ZIndex = tabObj.im.ZIndex + 1
			tabDot.Parent = tabObj.im
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
					if fn_isfolder and fn_makefolder and not fn_isfolder("VxezeHub") then
						fn_makefolder("VxezeHub")
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
				local note = mailboxLabel(mailboxList, mailboxText(key), Theme.FontRegular, 12, Theme.TextDim, 1)
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
					mailboxLabel(card, item.Title, Theme.Font, C.Text + 1, Theme.Text, 1)
				end
				mailboxLabel(card, tostring(item.Content or ""), Theme.FontRegular, C.Text, Theme.Text, 2)
				local meta = { tostring(item.Author or "Admin"), mailboxAge(item.CreatedAt) }
				if item.Edited then
					table.insert(meta, mailboxText("Edited"))
				end
				mailboxLabel(card, table.concat(meta, " \u{2022} "), Theme.FontRegular, 10, Theme.TextDim, 3)
			end
		end

		local function loadMailbox()
			local popup = mailboxPopup
			task.spawn(function()
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
			popup.BackgroundColor3 = Theme.Surface
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
			title.FontFace = Theme.Font
			title.Text = mailboxText("Title")
			title.TextColor3 = Theme.Text
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
			closeIc.ImageColor3 = Theme.TextDim
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
				notify({
					Title = mailboxText("Title"),
					Text = mailboxText("Notice"),
					Type = "info",
					Duration = 6,
				})
			end
		end

		local notifySoundInstance = Instance.new("Sound")
		notifySoundInstance.SoundId = "rbxasset://sounds/electronicpingshort.wav"
		notifySoundInstance.Volume = 0.5
		notifySoundInstance.Parent = panel

		-- Building a bubble is the expensive part of chat (dozens of instances, tweens, avatar
		-- lookups), and a busy chat made the whole hub stutter. While the chat tab isn't open
		-- new messages are only queued and drawn (in small batches) when the tab opens.
		-- Nothing is ever dropped from under the reader: old rows are only trimmed while the
		-- list is at the bottom, and the cap is high.
		local MAX_ROWS, MAX_PENDING = 250, 150
		local pending = {}
		local flushing = false
		local function trimRows()
			if not pinnedToBottom then
				return
			end
			local rows = {}
			for _, child in ipairs(msgScroll:GetChildren()) do
				if child.Name == "ChatRow" then
					rows[#rows + 1] = child
				end
			end
			for i = 1, #rows - MAX_ROWS do
				rows[i]:Destroy()
			end
		end
		local function flushPending()
			if flushing or #pending == 0 then
				return
			end
			flushing = true
			local queued = pending
			pending = {}
			for i, m in ipairs(queued) do
				-- One bad message must not leave `flushing` stuck or stop the rest.
				pcall(addBubble, m, m.UserId == LocalPlayer.UserId)
				if i % 8 == 0 then
					task.wait()
				end
			end
			flushing = false
			trimRows()
		end
		table.insert(tabListeners, function(selected)
			if selected == tabObj then
				task.spawn(flushPending)
			end
		end)

		-- Executor HTTP calls have no timeout, and one that never returns used to
		-- freeze the chat until the player sent something. Give each poll a deadline;
		-- a late answer is dropped (the next poll asks again from the same id).
		local POLL_TIMEOUT, MAX_STRANDED = 12, 3
		local strandedPolls = 0
		local function pollWithDeadline(sinceId)
			if strandedPolls >= MAX_STRANDED then
				return false, "Chat relay is not responding"
			end
			local done, ok, result = false, false, nil
			task.spawn(function()
				ok, result = pcall(service.PollChatMessages, service, sinceId)
				if done == nil then
					strandedPolls -= 1
				end
				done = true
			end)
			local started = os.clock()
			while done == false and os.clock() - started < POLL_TIMEOUT do
				task.wait(0.1)
			end
			if done == false then
				done = nil
				strandedPolls += 1
				return false, "Chat poll timed out"
			end
			return ok, result
		end

		if service then
			task.spawn(function()
				local backlogOk, backlog = pollWithDeadline(0)
				backlog = backlogOk and backlog or nil
				if type(backlog) == "table" then
					-- Show the whole backlog the relay returned (it already caps it at MaxMessages).
					local historyLimit = opts.HistoryLimit or #backlog
					local startIdx = math.max(1, #backlog - historyLimit + 1)
					for i = startIdx, #backlog do
						local m = backlog[i]
						if not seenIds[m.Id] then
							seenIds[m.Id] = true
							-- One bad message must not kill the poll loop below.
							pcall(addBubble, m, m.UserId == LocalPlayer.UserId)
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
					local delay = (isShown()) and pollInterval or math.max(pollInterval * 3, 8)
					if failures > 0 then
						delay = math.min(delay * 2 ^ math.min(failures, 3), 30)
					end
					local waited = 0
					while waited < delay and panel and panel.Parent do
						waited += task.wait(0.25)
						-- Opening the chat cuts a slow background wait short.
						if failures == 0 and waited >= pollInterval and isShown() then
							break
						end
					end
					if not (panel and panel.Parent) then
						break
					end
					local ok, newMsgs = pollWithDeadline(lastSeenId)
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
						-- While the tab's own flush is still drawing, new messages queue behind it
						-- so rows can't end up out of order.
						local onScreen = isShown() and not flushing
						if onScreen then
							flushPending()
						end
						for _, m in ipairs(newMsgs) do
							if not seenIds[m.Id] then
								seenIds[m.Id] = true
								local isOwn = m.UserId == LocalPlayer.UserId
								if onScreen then
									pcall(addBubble, m, isOwn)
								else
									pending[#pending + 1] = m
									if #pending > MAX_PENDING then
										table.remove(pending, 1)
									end
								end

								if notifySound and not isOwn and notifySoundInstance.Parent then
									notifySoundInstance:Play()
								end
							end
							if m.Id > lastSeenId then
								lastSeenId = m.Id
							end
						end
						if onScreen then
							trimRows()
						end
					end
				end
			end)
		end

		if service and service.PublishChatPresence then
			task.spawn(function()
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
			if not w.open then
				w:Show(true)
			end
			if w.Cur == tabObj then
				return
			end
			lastRealTab = w.Cur
			w:Select(tabObj)
		end
		local function closePanel()
			if w.Cur ~= tabObj then
				return
			end
			local back = lastRealTab or (w.Tabs[1] ~= tabObj and w.Tabs[1]) or nil
			if back then
				w:Select(back)
			end
		end

		return {
			Instance = panel,
			Tab = tabObj,
			Service = service,
			Open = openPanel,
			Close = closePanel,
			Toggle = function()
				if isShown() then
					closePanel()
				else
					openPanel()
				end
			end,
			IsOpen = isShown,
			Destroy = function()
				if allowJoin then
					allowJoin = false
					task.spawn(publishPresence)
				end
				panel:Destroy()
			end,
		}
	end


	-- Built-in Vietnamese for the hub's own screens (dashboard, settings, configs, chat).
	tbl6:AddTranslations("vi", {
		["Language"] = "Ngôn ngữ",
		["Auto (game language)"] = "Tự động (theo ngôn ngữ game)",
		["Search"] = "Tìm kiếm",
		["Find an option"] = "Tìm một tùy chọn",
		["No results"] = "Không có kết quả",
		["No option matches"] = "Không có tùy chọn nào khớp",
		["Nothing here"] = "Chưa có gì ở đây",
		["Announcement"] = "Thông báo",

		-- Dashboard
		["Home"] = "Trang chủ",
		["Dashboard"] = "Bảng điều khiển",
		["Welcome back"] = "Chào mừng trở lại",
		["Copy invite"] = "Sao chép lời mời",
		["Invite copied"] = "Đã sao chép lời mời",
		["Discord invite copied"] = "Đã sao chép lời mời Discord",
		["Updates, keys, support"] = "Cập nhật, key, hỗ trợ",
		["Rejoin"] = "Vào lại",
		["Server hop"] = "Đổi server",
		["Copy Job ID"] = "Sao chép Job ID",
		["Job ID copied"] = "Đã sao chép Job ID",
		["Unload hub"] = "Tắt hub",
		["Session"] = "Phiên chơi",
		["What's new"] = "Có gì mới",
		["Rejoin this server?"] = "Vào lại server này?",
		["You leave and join this same server again."] = "Bạn sẽ thoát ra rồi vào lại đúng server này.",
		["Hop to another server?"] = "Chuyển sang server khác?",
		["You leave this server and join a different one."] = "Bạn sẽ rời server này và vào một server khác.",
		["Hop"] = "Đổi",
		["OPEN"] = "MỞ",
		["Open"] = "Mở",
		["NEW"] = "MỚI",
		["FIX"] = "SỬA",
		["UPD"] = "CẬP NHẬT",
		["No eggs yet"] = "Chưa có trứng",
		["Pick an egg"] = "Chọn một quả trứng",

		-- Dialogs and common buttons
		["OK"] = "OK",
		["Cancel"] = "Hủy",
		["Done"] = "Xong",
		["Later"] = "Để sau",
		["Run"] = "Chạy",
		["Save"] = "Lưu",
		["Delete"] = "Xóa",
		["Create"] = "Tạo",
		["Import"] = "Nhập",
		["Reset"] = "Đặt lại",
		["Clear"] = "Xóa hết",
		["Turn off"] = "Tắt",
		["Turned on"] = "Đã bật",
		["Turned off"] = "Đã tắt",
		["Not set"] = "Chưa đặt",
		["None"] = "Không",
		["Off"] = "Tắt",
		["All"] = "Tất cả",
		["Select all"] = "Chọn tất cả",
		["Pick one"] = "Chọn một",
		["Pick any"] = "Chọn tùy ý",
		["Nothing picked"] = "Chưa chọn gì",
		["Type here"] = "Nhập tại đây",
		["Loading..."] = "Đang tải...",
		["Unknown game"] = "Game không rõ",

		-- Settings
		["Settings"] = "Cài đặt",
		["Interface"] = "Giao diện",
		["Theme"] = "Chủ đề",
		["Defaults"] = "Mặc định",
		["Default"] = "Mặc định",
		["UI scale"] = "Tỉ lệ giao diện",
		["Dim the game"] = "Làm tối game",
		["Tone"] = "Tông màu",
		["Opacity"] = "Độ mờ",
		["Size"] = "Kích thước",
		["Weight"] = "Độ đậm",
		["Bar size"] = "Cỡ thanh",
		["Hide UI"] = "Ẩn giao diện",
		["Show / hide UI"] = "Hiện / ẩn giao diện",
		["Turn off all toggles"] = "Tắt mọi công tắc",
		["Toggles off"] = "Đã tắt các công tắc",
		["Reset to defaults"] = "Khôi phục mặc định",
		["Reset every option?"] = "Đặt lại mọi tùy chọn?",
		["All options go back to their built-in values and your active config is saved that way."] = "Mọi tùy chọn trở về giá trị gốc và config đang dùng sẽ được lưu như vậy.",
		["Every option is back to its default"] = "Mọi tùy chọn đã về mặc định",

		-- Configs
		["Config"] = "Config",
		["Profiles"] = "Hồ sơ",
		["Active config"] = "Config đang dùng",
		["Saved configs"] = "Config đã lưu",
		["Auto load"] = "Tự tải",
		["Auto save"] = "Tự lưu",
		["Save changes"] = "Lưu thay đổi",
		["Save config"] = "Lưu config",
		["Create config"] = "Tạo config",
		["New config name"] = "Tên config mới",
		["Config 1"] = "Config 1",
		["Set active"] = "Dùng config này",
		["Set as active config"] = "Đặt làm config đang dùng",
		["Delete picked"] = "Xóa mục đã chọn",
		["Pick to delete"] = "Chọn để xóa",
		["Pick configs other than Default"] = "Hãy chọn config khác Default",
		["Nothing to delete"] = "Không có gì để xóa",
		["Choose a config first"] = "Hãy chọn một config trước",
		["Export config"] = "Xuất config",
		["Import config"] = "Nhập config",
		["Import text"] = "Văn bản nhập",
		["Paste config text"] = "Dán nội dung config",
		["Apply now"] = "Áp dụng ngay",
		["Restore deleted"] = "Khôi phục mục đã xóa",
		["Config saved"] = "Đã lưu config",
		["Config loaded"] = "Đã tải config",
		["Config created"] = "Đã tạo config",
		["Config not created"] = "Chưa tạo được config",
		["Config imported"] = "Đã nhập config",
		["Config copied"] = "Đã sao chép config",
		["Config picked"] = "Đã chọn config",
		["Config restored"] = "Đã khôi phục config",
		["Imported"] = "Đã nhập",
		["Import failed"] = "Nhập thất bại",
		["Restore failed"] = "Khôi phục thất bại",
		["Copy failed"] = "Sao chép thất bại",
		["Bad config name"] = "Tên config không hợp lệ",
		["Use letters, numbers, spaces, - or _"] = "Chỉ dùng chữ, số, dấu cách, - hoặc _",
		["32 characters at most"] = "Tối đa 32 ký tự",
		["Not a Vxeze Hub config text"] = "Đây không phải config của Vxeze Hub",
		["This executor cannot copy text"] = "Executor này không sao chép được văn bản",
		["This executor cannot copy text."] = "Executor này không sao chép được văn bản.",
		["Press Save changes to keep your options"] = "Bấm Lưu thay đổi để giữ tùy chọn của bạn",
		["Vxeze Hub starts with its default options"] = "Vxeze Hub khởi động với tùy chọn mặc định",

		-- Quick bars and keybinds
		["Quick bars"] = "Thanh nhanh",
		["Quick bar layout"] = "Bố cục thanh nhanh",
		["Show quick bars"] = "Hiện thanh nhanh",
		["Quick bars are hidden"] = "Thanh nhanh đang ẩn",
		["Clear all quick bars"] = "Xóa mọi thanh nhanh",
		["Clear every quick bar?"] = "Xóa mọi thanh nhanh?",
		["Features keep their state, they just leave the bars."] = "Các tính năng vẫn giữ trạng thái, chỉ bị gỡ khỏi thanh.",
		["Pins and keybinds"] = "Ghim và phím tắt",
		["Keybinds"] = "Phím tắt",
		["KEYBIND"] = "PHÍM TẮT",
		["Clear all keybinds"] = "Xóa mọi phím tắt",
		["Clear every keybind?"] = "Xóa mọi phím tắt?",
		["Keys stop toggling options until you set them again."] = "Các phím sẽ không bật/tắt tùy chọn nữa cho đến khi bạn đặt lại.",
		["Nothing pinned or bound yet"] = "Chưa ghim hay gán phím nào",
		["Key not set"] = "Chưa đặt phím",
		["Key moved"] = "Đã chuyển phím",
		["Press any key  -  Esc cancels"] = "Bấm một phím bất kỳ  -  Esc để hủy",
		["SHOW ON QUICK BAR"] = "HIỆN TRÊN THANH NHANH",
		["+ PIN"] = "+ GHIM",
		["Pressed"] = "Đã bấm",
		["Tip: you can also hold any feature, or right-click it on PC, to pin it or set a key."] = "Mẹo: giữ một tính năng (hoặc chuột phải trên PC) để ghim hoặc gán phím cho nó.",

		-- Global chat
		["Chat"] = "Chat",
		["Global Chat"] = "Chat toàn cầu",
		["Message everyone using this script..."] = "Nhắn cho mọi người đang dùng script...",
		["No messages yet. Say hello!"] = "Chưa có tin nhắn. Hãy chào mọi người!",
		["Global chat is not configured by the script owner."] = "Chủ script chưa cấu hình chat toàn cầu.",
		["Chat unavailable"] = "Chat không khả dụng",
		["Report chat / user"] = "Báo cáo tin nhắn / người dùng",
		["Enter report reason..."] = "Nhập lý do báo cáo...",
		["Enter a report reason."] = "Hãy nhập lý do báo cáo.",
		["Send report"] = "Gửi báo cáo",
		["Sending..."] = "Đang gửi...",
		["Report"] = "Báo cáo",
		["Reported"] = "Đã báo cáo",
		["Report sent to the admins."] = "Đã gửi báo cáo tới admin.",
		["Could not report"] = "Không gửi được báo cáo",
		["Join Server"] = "Vào server",
		["Join server?"] = "Vào server này?",
		["Join"] = "Vào",
		["This player is no longer sharing a server."] = "Người chơi này không còn chia sẻ server.",
		["You are already in this server."] = "Bạn đang ở trong server này rồi.",
		["Join sharing needs a public game server."] = "Chia sẻ server chỉ dùng được ở server công khai.",
		["Show timestamps"] = "Hiện thời gian",
		["Sound on new message"] = "Phát âm thanh khi có tin mới",
		["Fast updates (1s)"] = "Cập nhật nhanh (1 giây)",
		["Allow others to join me"] = "Cho người khác vào server của tôi",
		["Anonymous mode on -- new messages won't reveal your avatar."] = "Đã bật ẩn danh: tin nhắn mới sẽ không hiện avatar của bạn.",
		["Anonymous mode off -- new messages show your avatar."] = "Đã tắt ẩn danh: tin nhắn mới sẽ hiện avatar của bạn.",
		["Clipboard is not available."] = "Không dùng được bộ nhớ tạm.",
		["Mailbox"] = "Hộp thư",
		["New message from admin"] = "Có tin nhắn mới từ admin",
		["The mailbox is empty."] = "Hộp thư trống.",
		["Couldn't load the mailbox."] = "Không tải được hộp thư.",
		["edited"] = "đã sửa",
		["just now"] = "vừa xong",
		["Chat relay is not responding"] = "Máy chủ chat không phản hồi",
		["Chat poll timed out"] = "Hết thời gian chờ tải chat",
		["Presence is not supported by the relay."] = "Máy chủ chat không hỗ trợ chia sẻ server.",
		["Request failed"] = "Yêu cầu thất bại",
		["Invalid chat response"] = "Phản hồi chat không hợp lệ",
		["Unknown message"] = "Tin nhắn không xác định",
	}, {
		{"^(%d+) days? ago$", "%1 ngày trước"},
		{"^(%d+) hours? ago$", "%1 giờ trước"},
		{"^(%d+) minutes? ago$", "%1 phút trước"},
		{"^(%d+)m ago$", "%1 phút trước"},
		{"^(%d+)h ago$", "%1 giờ trước"},
		{"^(%d+)d ago$", "%1 ngày trước"},
		{"^(.+)  •  (%d+) online$", "@1  •  %2 đang online"},
		{"^Join (.+) in (.+)%? You will leave your current server%.$", "Vào cùng %1 trong %2? Bạn sẽ rời server hiện tại."},
		{"^Replying to (.-): (.*)$", "Đang trả lời %1: %2"},
		{"^Reporting (.+)$", "Báo cáo %1"},
		{"^Join failed: (.*)$", "Vào server thất bại: %1"},
		{"^Slow down %-%- wait (.+)s%.$", "Chậm lại, chờ %1 giây."},
		{"^QUICK BAR (%d+)$", "THANH NHANH %1"},
		{"^Turn on Show quick bars to see Quick bar (%d+)$", "Bật Hiện thanh nhanh để thấy thanh nhanh %1"},
		{"^(%d+) switched off$", "Đã tắt %1 công tắc"},
		{"^(.+) %- press Set active to load it$", "%1 - bấm Dùng config này để tải"},
		{"^Auto load on$", "Đã bật tự tải"},
		{"^Auto load off$", "Đã tắt tự tải"},
		{"^Auto save on$", "Đã bật tự lưu"},
		{"^Auto save off$", "Đã tắt tự lưu"},
		{"^(.+) loads every time Vxeze Hub starts$", "%1 sẽ được tải mỗi khi Vxeze Hub khởi động"},
		{"^Every change is saved to (.+)$", "Mọi thay đổi được lưu vào %1"},
		{"^(.+) is now the active config$", "%1 giờ là config đang dùng"},
		{"^Delete (%d+) config%(s%)%?$", "Xóa %1 config?"},
		{"^(%d+) config%(s%) deleted$", "Đã xóa %1 config"},
		{"^(.+)\nDefault is kept%.$", "%1\nConfig Default được giữ lại."},
		{"^(.+) is on your clipboard%. Paste it to share it, then load it with Import config%.$", "%1 đã nằm trong bộ nhớ tạm. Dán để chia sẻ, rồi tải bằng Nhập config."},
		{"^(.+) is on your clipboard$", "%1 đã nằm trong bộ nhớ tạm"},
		{"^(.+) was added to your configs%. Apply it now%?$", "Đã thêm %1 vào danh sách config. Áp dụng luôn?"},
		{"^(.+) was added to your configs$", "Đã thêm %1 vào danh sách config"},
		{"^(.+) already shows and hides the menu$", "%1 đang dùng để hiện/ẩn menu"},
		{"^(.+) now toggles (.+) instead of (.+)$", "%1 giờ bật/tắt @2 thay vì @3"},
		-- Search result paths: "Steal / Auto Steal / Filter"
		{"^(%a[^/]-) / (.+)$", "@1 / @2"},
	}, "Tiếng Việt")

	return tbl6
end)()

return Library
