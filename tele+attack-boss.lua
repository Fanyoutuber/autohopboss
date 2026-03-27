local Players = game:GetService("Players")
local TweenService = game:GetService("TweenService")
local RunService = game:GetService("RunService")

local player = Players.LocalPlayer
local character = player.Character or player.CharacterAdded:Wait()
local rootPart = character:WaitForChild("HumanoidRootPart")

-- =========================================
-- KHU VỰC CÀI ĐẶT (Tùy chỉnh linh hoạt ở đây)
-- =========================================
local TARGET_NAME = "YamatoBoss" -- Đổi tên quái muốn farm
local FLY_SPEED = 150 
local DISTANCE = 4 -- Đứng cách lưng boss 4 stud

local autoFarmToggle = true

-- 1. HÀM NOCLIP (Giữ nguyên)
local function Noclip()
    RunService.Stepped:Connect(function()
        if autoFarmToggle and character then
            for _, part in pairs(character:GetDescendants()) do
                if part:IsA("BasePart") and part.CanCollide then
                    part.CanCollide = false
                end
            end
        end
    end)
end

-- 2. HÀM TÌM QUÁI TRÊN BẢN ĐỒ
local function LấyMụcTiêu()
    -- LỖ HỔNG Ở ĐÂY: Hiện tại đang quét toàn bộ workspace. 
    -- Nếu biết thư mục chứa quái, hãy đổi thành: workspace.ThuMucQuai:GetChildren()
    for _, obj in pairs(workspace:WaitForChild("NPCs"):FindFirstChild()) do 
        if obj.Name == TARGET_NAME and obj:FindFirstChild("Humanoid") and obj:FindFirstChild("HumanoidRootPart") then
            if obj.Humanoid.Health > 0 then
                return obj -- Trả về con quái còn sống đầu tiên tìm thấy
            end
        end
    end
    return nil -- Không thấy con nào thì báo rỗng
end

-- 3. HÀM TẤN CÔNG (Spam gói tin)
local function AttackBoss()
    game:GetService("ReplicatedStorage").CombatSystem.Remotes.RequestHit:FireServer()
end

-- 4. VÒNG LẶP AUTO FARM CHÍNH
local function BatDauFarm()
    Noclip()
    
    -- Dùng task.spawn để vòng lặp chạy ngầm, không làm treo game
    task.spawn(function()
        while autoFarmToggle do
            local quaiHienTai = LấyMụcTiêu()
            
            if quaiHienTai then
                -- Bước 1: Bay tới quái
                local targetCFrame = quaiHienTai.HumanoidRootPart.CFrame * CFrame.new(0, 0, DISTANCE)
                local distance = (rootPart.Position - targetCFrame.Position).Magnitude
                
                local tweenInfo = TweenInfo.new(distance / FLY_SPEED, Enum.EasingStyle.Linear)
                local tween = TweenService:Create(rootPart, tweenInfo, {CFrame = targetCFrame})
                tween:Play()
                
                -- Đợi bay tới nơi
                tween.Completed:Wait() 
                
                -- Bước 2: Bám đít và xả skill cho đến khi nó chết
                while quaiHienTai and quaiHienTai.Parent and quaiHienTai:FindFirstChild("Humanoid") and quaiHienTai.Humanoid.Health > 0 and autoFarmToggle do
                    rootPart.CFrame = quaiHienTai.HumanoidRootPart.CFrame * CFrame.new(0, 0, DISTANCE)
                    AttackBoss()
                    task.wait(0.1) -- Tốc độ vung kiếm
                end
                
                -- Boss chết thì vòng lặp tự văng ra ngoài, lặp lại từ đầu đi tìm con mới
            else
                -- Không tìm thấy con nào thì đứng đợi 1 giây rồi quét lại (Đỡ lag máy)
                task.wait(1) 
            end
        end
    end)
end

-- Chạy Script
BatDauFarm()
