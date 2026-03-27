-- =========================================================
-- 🛑 LÕI HỆ THỐNG (BẢN VÁ LỖI NOCLIP & TỐI ƯU COMBO SKILL)
-- 🛑 LÕI HỆ THỐNG (BẢN VÁ LỖI NOCLIP, BAY XA & GLOBAL COOLDOWN)
-- =========================================================
print(">> Giai doan 1: Khoi tao...")
task.wait(5) 
task.wait(5) -- Giữ nguyên thời gian của ông
local TS, HS = game:GetService("TeleportService"), game:GetService("HttpService")
local TweenService, RS = game:GetService("TweenService"), game:GetService("ReplicatedStorage")
local RunService = game:GetService("RunService")
@@ -34,7 +34,7 @@ local function TatNoclip()
end

print(">> Giai doan 2: Nap Radar...")
task.wait(0.5)
task.wait(0.5) -- Giữ nguyên thời gian của ông
local function QuetRadarBoss()
local folder = workspace:FindFirstChild("NPCs") or workspace
for _, ten in pairs(Cfg.DanhSachBoss) do
@@ -44,7 +44,7 @@ local function QuetRadarBoss()
end

print(">> Giai doan 3: Nap Teleport...")
task.wait(0.5)
task.wait(0.5) -- Giữ nguyên thời gian của ông
local function DoiServerSieuToc()
while true do 
local url = "https://games.roblox.com/v1/games/"..PId.."/servers/Public?sortOrder=Desc&limit=100"
@@ -83,16 +83,25 @@ local function DoiServerSieuToc()
end
end

-- [CẬP NHẬT] ÉP LOAD MAP KHI Ở QUÁ XA
local function BayToi(DichDen)
local char = Player.Character
if not char or not char:FindFirstChild("HumanoidRootPart") then return end
local HRP = char.HumanoidRootPart
    local ThoiGian = (HRP.Position - DichDen.Position).Magnitude / 350 -- Tốc độ 350 stud/s
    local KhoangCach = (HRP.Position - DichDen.Position).Magnitude
    
    if KhoangCach > 1500 then
        HRP.CFrame = DichDen * CFrame.new(0, 300, 0)
        task.wait(0.5) 
        return
    end

    local ThoiGian = KhoangCach / 350 
TweenService:Create(HRP, TweenInfo.new(ThoiGian, Enum.EasingStyle.Linear), {CFrame = DichDen}):Play()
end

print(">> Giai doan 4: Kich hoat Farm!")
task.wait(0.5)
task.wait(0.5) -- Giữ nguyên thời gian của ông
task.spawn(function()
local Combat = RS:FindFirstChild("CombatSystem") and RS.CombatSystem.Remotes.RequestHit
local Ability = RS:FindFirstChild("AbilitySystem") and RS.AbilitySystem.Remotes.RequestAbility
@@ -102,7 +111,7 @@ task.spawn(function()

if target then
print(">> Muc tieu: " .. target.Name)
            BatNoclip() -- Bật xuyên tường ngay khi thấy Boss
            BatNoclip() 

repeat 
local char = Player.Character
@@ -114,27 +123,26 @@ task.spawn(function()
BayToi(viTriAnToan)
end

                -- [VÁ LỖI 2] COMBO TUẦN TỰ (Ưu tiên Chiêu thức -> Đánh thường)
                -- [CẬP NHẬT] COMBO LÁCH LUẬT GCD
if khoangCachToiBoss < 30 then
pcall(function()
                        -- 1. Xả toàn bộ chiêu trong Config
if Ability and type(Cfg.CacChieuSuDung) == "table" then
for _, idChieu in pairs(Cfg.CacChieuSuDung) do
Ability:FireServer(idChieu)
                                task.wait(0.05) -- Nghỉ 0.05s giữa các chiêu để chống kẹt phím
                                -- Gọi biến Delay từ Config. Nếu Config cũ chưa có thì mặc định lấy 0.6s để chống lỗi
                                task.wait(Cfg.DelayGiuaCacChieu or 0.6) 
end
end
                        -- 2. Chêm 1 phát đánh thường vào lúc chờ hồi chiêu
if Combat then Combat:FireServer() end
end)
end

                task.wait(Cfg.TocDoSpamChieu) -- Nghỉ theo nhịp độ cài đặt rồi combo tiếp
                task.wait(Cfg.TocDoSpamChieu) 

until not target or not target.Parent or not target:FindFirstChild("Humanoid") or target.Humanoid.Health <= 0

print(">> Boss chet, tat Noclip, tim tiep...")
            TatNoclip() -- Chốt hạ lỗi Line 101 ở đây
            TatNoclip() 
else
print(">> Map sach. Doi " .. Cfg.ThoiGianChoHop .. "s roi Hop...")
task.wait(Cfg.ThoiGianChoHop)
