--[[
    HƯỚNG DẪN SỬ DỤNG FLUENT RENEWED (CUSTOM BUILD)

    Vì bạn đã chỉnh sửa source code, bạn cần sử dụng phiên bản đã được build (gộp lại thành 1 file).
    Repo GitHub của bạn đã có sẵn tính năng tự động build.

    CÁCH LẤY FILE BUILD:
    1. Truy cập repo GitHub của bạn: https://github.com/angeryy-tvy/Fluent-Port-Vxeze/actions
    2. Bấm vào workflow chạy gần nhất (tên là "Bundle and Upload Fluent Renewed" hoặc "Pushed").
    3. Cuộn xuống phần "Artifacts" và tải "Fluent.luau" về.
    4. Giải nén file zip để lấy file "Fluent.luau".

    CÁCH 1: DÙNG TRỰC TIẾP FILE TRÊN MÁY (NẾU EXECUTOR HỖ TRỢ)
    Copy file Fluent.luau vào thư mục workspace của executor và dùng lệnh:
]]

local Fluent = loadfile("Fluent.luau")()

--[[
    CÁCH 2: UPLOAD LÊN GITHUB ĐỂ DÙNG LINK
    1. Upload file "Fluent.luau" bạn vừa tải về lên lại repo GitHub của bạn (vào thư mục nào cũng được, ví dụ Distribution).
    2. Lấy link "Raw" của file đó.
    3. Dùng link đó như sau:
]]

-- local Fluent = loadstring(game:HttpGet("LINK_RAW_CUA_BAN/Fluent.luau"))()

-- Code ví dụ sử dụng:
local Window = Fluent:CreateWindow({
    Title = "Fluent Renewed " .. Fluent.Version,
    SubTitle = "by angeryy-tvy",
    TabWidth = 160,
    Size = UDim2.fromOffset(580, 460),
    Acrylic = true,
    Theme = "Dark",
    MinimizeKey = Enum.KeyCode.RightControl
})

local Tabs = {
    Main = Window:CreateTab({
        Title = "Main",
        Icon = "home"
    })
}

Tabs.Main:CreateButton({
    Title = "Test Button",
    Description = "Click me",
    Callback = function()
        print("Hello World")
    end
})

Window:SelectTab(1)
Fluent:Notify({
    Title = "Thành công",
    Content = "Đã load Fluent UI custom của bạn!",
    Duration = 8
})
