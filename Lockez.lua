local Players = game:GetService("Players")
local RunService = game:GetService("RunService")
local LocalPlayer = Players.LocalPlayer
local Camera = workspace.CurrentCamera

-- ========== CẤU HÌNH HỆ THỐNG ==========
local Settings = {
    Enabled = true,
    AimPart = "Head",
    AimFOV = 120,    -- CỐ ĐỊNH FOV AIM LÀ 120 THEO YÊU CẦU
    NeedItem = true,
    Smoothness = 0.2,
    WallCheck = true,
    CameraFOV = 70   -- Lưu cấu hình FOV Camera để khóa liên tục
}

-- ========== TỰ ĐỘNG BẤM NÚT CHẠY TRÊN MOBILE ==========
local function AutoClickSprintButton()
    pcall(function()
        -- Chờ PlayerGui và bộ giao diện gốc của game tải xong
        local playerGui = LocalPlayer:WaitForChild("PlayerGui", 5)
        if not playerGui then return end
        
        -- Quét tìm nút chạy dựa trên hình ảnh biểu tượng người chạy (Mobile Sprint)
        for _, gui in pairs(playerGui:GetDescendants()) do
            if gui:IsA("ImageButton") or gui:IsA("TextButton") then
                -- Kiểm tra nếu ID hình ảnh hoặc tên nút trùng với nút Sprint của game
                if gui.Image == "rbxassetid://12177341398" or string.lower(gui.Name):match("sprint") or string.lower(gui.Name):match("run") then
                    -- Giả lập hành vi chạm/click vào nút chạy
                    local virtualUser = game:GetService("VirtualUser")
                    gui.Size = gui.Size -- Kích hoạt cập nhật trạng thái nếu cần
                    
                    -- Cách 1: Giả lập nhấn trực tiếp bằng hệ thống GUI
                    firesignal(gui.MouseButton1Click)
                    firesignal(gui.TouchTap)
                    break
                end
            end
        end
    end)
end

-- Tự động bấm nút chạy khi nhân vật hồi sinh (Chết xong hồi sinh tự bấm lại)
LocalPlayer.CharacterAdded:Connect(function(char)
    task.wait(1.5) -- Đợi giao diện game tải lại sau khi hồi sinh
    AutoClickSprintButton()
end)

-- ========== LOGIC NGẮM BẮN & TƯỜNG CẢN ==========
local function CheckHoldingItem()
    if not Settings.NeedItem then return true end
    local char = LocalPlayer.Character
    if char and char:FindFirstChildOfClass("Tool") then
        return true
    end
    return false
end

local function IsVisible(targetPart, targetCharacter)
    if not Settings.WallCheck then return true end
    local char = LocalPlayer.Character
    local ignoreList = {char, targetCharacter}
    local obscuringParts = Camera:GetPartsObscuringTarget({targetPart.Position}, ignoreList)
    return #obscuringParts == 0
end

local function GetTarget()
    if not Settings.Enabled or not CheckHoldingItem() then return nil end
    local target = nil
    local maxDist = Settings.AimFOV
    local center = Vector2.new(Camera.ViewportSize.X / 2, Camera.ViewportSize.Y / 2)
    
    for _, player in pairs(Players:GetPlayers()) do
        if player ~= LocalPlayer and player.Character then
            local humanoid = player.Character:FindFirstChildOfClass("Humanoid")
            local part = player.Character:FindFirstChild(Settings.AimPart)
            
            -- Kiểm tra kỹ máu, trạng thái Dead, và part mục tiêu phải hợp lệ
            if humanoid and part and humanoid.Health > 0 and humanoid:GetState() ~= Enum.HumanoidStateType.Dead and part:IsDescendantOf(player.Character) then
                local pos, onScreen = Camera:WorldToViewportPoint(part.Position)
                if onScreen and IsVisible(part, player.Character) then
                    local dist = (Vector2.new(pos.X, pos.Y) - center).Magnitude
                    if dist < maxDist then
                        maxDist = dist
                        target = part
                    end
                end
            end
        end
    end
    return target
end

-- ========== TÍNH NĂNG ĐỒ HỌA MINECRAFT ==========
local function ApplyMinecraftGraphics()
    for _, obj in pairs(workspace:GetDescendants()) do
        if obj:IsA("BasePart") and not obj:IsA("MeshPart") then
            obj.Material = Enum.Material.SmoothPlastic
        elseif obj:IsA("Texture") or obj:IsA("Decal") then
            obj:Destroy()
        end
    end
    local lighting = game:GetService("Lighting")
    lighting.GlobalShadows = false
    lighting.FogEnd = 9e9
    for _, effect in pairs(lighting:GetChildren()) do
        if effect:IsA("BloomEffect") or effect:IsA("BlurEffect") or effect:IsA("DepthOfFieldEffect") or effect:IsA("SunRaysEffect") then
            effect.Enabled = false
        end
    end
end

-- Kích hoạt đồ họa mượt và tự động bấm nút chạy lần đầu khi thực thi script
ApplyMinecraftGraphics()
task.defer(AutoClickSprintButton)

-- ========== TỰ TẠO MENU GUI (QLxAIM) ==========
if game:GetService("CoreGui"):FindFirstChild("RoStreetsGui") then
    game:GetService("CoreGui").RoStreetsGui:Destroy()
end

local ScreenGui = Instance.new("ScreenGui")
ScreenGui.Name = "RoStreetsGui"
ScreenGui.Parent = game:GetService("CoreGui")
ScreenGui.ZIndexBehavior = Enum.ZIndexBehavior.Sibling

-- Nút mở nhanh Menu
local OpenBtn = Instance.new("TextButton")
OpenBtn.Name = "OpenBtn"
OpenBtn.Parent = ScreenGui
OpenBtn.Position = UDim2.new(0.05, 0, 0.15, 0)
OpenBtn.Size = UDim2.new(0, 45, 0, 45)
OpenBtn.BackgroundColor3 = Color3.fromRGB(30, 30, 30)
OpenBtn.TextColor3 = Color3.fromRGB(255, 255, 255)
OpenBtn.Text = "Menu"
OpenBtn.TextSize = 14
OpenBtn.Font = Enum.Font.SourceSansBold

local OpenCorner = Instance.new("UICorner")
OpenCorner.CornerRadius = UDim.new(0, 50)
OpenCorner.Parent = OpenBtn

-- Khung Menu chính
local MainFrame = Instance.new("Frame")
MainFrame.Name = "MainFrame"
MainFrame.Parent = ScreenGui
MainFrame.Position = UDim2.new(0.3, 0, 0.25, 0)
MainFrame.Size = UDim2.new(0, 300, 0, 215) 
MainFrame.BackgroundColor3 = Color3.fromRGB(20, 20, 20)
MainFrame.Visible = false

local MainCorner = Instance.new("UICorner")
MainCorner.CornerRadius = UDim.new(0, 8)
MainCorner.Parent = MainFrame

-- Tiêu đề Menu QLxAIM màu cầu vồng
local Title = Instance.new("TextLabel")
Title.Parent = MainFrame
Title.Size = UDim2.new(1, 0, 0, 35)
Title.BackgroundColor3 = Color3.fromRGB(30, 30, 30)
Title.Text = "   QLxAIM"
Title.TextXAlignment = Enum.TextXAlignment.Left
Title.Font = Enum.Font.SourceSansBold
Title.TextSize = 18

local TitleCorner = Instance.new("UICorner")
TitleCorner.CornerRadius = UDim.new(0, 8)
TitleCorner.Parent = Title

-- Hàm tạo nút Toggle trong Menu
local function CreateToggle(name, text, default, yPos, callback)
    local btn = Instance.new("TextButton")
    btn.Parent = MainFrame
    btn.Position = UDim2.new(0.05, 0, 0, yPos)
    btn.Size = UDim2.new(0, 270, 0, 30)
    btn.BackgroundColor3 = default and Color3.fromRGB(0, 150, 0) or Color3.fromRGB(50, 50, 50)
    btn.Text = text .. (default and ": BẬT" or ": TẮT")
    btn.TextColor3 = Color3.fromRGB(255, 255, 255)
    btn.Font = Enum.Font.SourceSans
    btn.TextSize = 14
    
    local corner = Instance.new("UICorner")
    corner.CornerRadius = UDim.new(0, 4)
    corner.Parent = btn

    local enabled = default
    btn.MouseButton1Click:Connect(function()
        enabled = not enabled
        btn.BackgroundColor3 = enabled and Color3.fromRGB(0, 150, 0) or Color3.fromRGB(50, 50, 50)
        btn.Text = text .. (enabled and ": BẬT" or ": TẮT")
        callback(enabled)
    end)
end

-- Tạo các nút bấm trong menu
CreateToggle("AimToggle", "Chức năng Aim", true, 50, function(v) Settings.Enabled = v end)
CreateToggle("WallToggle", "Đợi địch ra khỏi tường (Wall Check)", true, 90, function(v) Settings.WallCheck = v end)

-- NÚT CHỈNH CAMERA FOV
local CamFovBtn = Instance.new("TextButton")
CamFovBtn.Parent = MainFrame
CamFovBtn.Position = UDim2.new(0.05, 0, 0, 135)
CamFovBtn.Size = UDim2.new(0, 270, 0, 30)
CamFovBtn.BackgroundColor3 = Color3.fromRGB(40, 40, 40)
CamFovBtn.Text = "Chỉnh FOV Camera (Hiện tại: " .. math.floor(Settings.CameraFOV) .. ")"
CamFovBtn.TextColor3 = Color3.fromRGB(255, 255, 255)
CamFovBtn.Font = Enum.Font.SourceSans

local CamFovCorner = Instance.new("UICorner")
CamFovCorner.CornerRadius = UDim.new(0, 4)
CamFovCorner.Parent = CamFovBtn

local camFovModes = {70, 90, 110, 120}
local camIdx = 1
CamFovBtn.MouseButton1Click:Connect(function()
    camIdx = camIdx + 1
    if camIdx > #camFovModes then camIdx = 1 end
    Settings.CameraFOV = camFovModes[camIdx]
    CamFovBtn.Text = "Chỉnh FOV Camera (Hiện tại: " .. camFovModes[camIdx] .. ")"
end)

-- Nút đổi Đồ họa Minecraft
local McBtn = Instance.new("TextButton")
McBtn.Parent = MainFrame
McBtn.Position = UDim2.new(0.05, 0, 0, 175)
McBtn.Size = UDim2.new(0, 270, 0, 30)
McBtn.BackgroundColor3 = Color3.fromRGB(90, 60, 40)
McBtn.Text = "Kích hoạt Đồ họa Minecraft (Mượt FPS)"
McBtn.TextColor3 = Color3.fromRGB(255, 255, 255)
McBtn.Font = Enum.Font.SourceSansBold
McBtn.TextSize = 14

local McCorner = Instance.new("UICorner")
McCorner.CornerRadius = UDim.new(0, 4)
McCorner.Parent = McBtn
McBtn.MouseButton1Click:Connect(ApplyMinecraftGraphics)

-- Sự kiện ẩn/hiện Menu
OpenBtn.MouseButton1Click:Connect(function()
    MainFrame.Visible = not MainFrame.Visible
end)

-- ========== ĐỒ HỌA VÒNG TRÒN FOV AIM CỐ ĐỊNH ==========
local Circle = Drawing.new("Circle")
Circle.Thickness = 1.5
Circle.NumSides = 36
Circle.Filled = false
Circle.Radius = Settings.AimFOV
Circle.Visible = true

workspace.DescendantAdded:Connect(function(obj)
    if obj:IsA("BasePart") and not obj:IsA("MeshPart") then
        RunService.Heartbeat:Wait()
        obj.Material = Enum.Material.SmoothPlastic
    end
end)

-- ========== VÒNG LẶP HOẠT ĐỘNG CHÍNH ==========
RunService.RenderStepped:Connect(function()
    -- KHÓA CỨNG CAMERA FOV LIÊN TỤC
    if Camera.FieldOfView ~= Settings.CameraFOV then
        Camera.FieldOfView = Settings.CameraFOV
    end

    local targetPart = GetTarget()
    
    -- Tạo màu Rainbow cầu vồng cho chữ tiêu đề QLxAIM
    local hue = tick() % 5 / 5
    Title.TextColor3 = Color3.fromHSV(hue, 1, 1)
    
    -- Xử lý dí tâm súng
    if targetPart then
        local targetCFrame = CFrame.lookAt(Camera.CFrame.Position, targetPart.Position)
        Camera.CFrame = Camera.CFrame:Lerp(targetCFrame, Settings.Smoothness)
    end

    -- Xử lý hiển thị vòng tròn FOV cố định (120px)
    if Settings.Enabled then
        Circle.Position = Vector2.new(Camera.ViewportSize.X / 2, Camera.ViewportSize.Y / 2)
        Circle.Radius = Settings.AimFOV
        Circle.Visible = true
        Circle.Color = targetPart and Color3.fromRGB(0, 255, 0) or Color3.fromRGB(255, 0, 0)
    else
        Circle.Visible = false
    end
end)
