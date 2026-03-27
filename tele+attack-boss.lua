local Players = game:GetService("Players")
local TweenService = game:GetService("TweenService")
local RunService = game:GetService("RunService")

local player = Players.LocalPlayer

-- =========================================
-- KHU VỰC CÀI ĐẶT
-- =========================================
local TARGET_NAME = "YamatoBoss" 
local FLY_SPEED = 150 
local DISTANCE = 4 

local autoFarmToggle = true
local noclipConnection

-- 1. HÀM NOCLIP (Đã tối ưu CPU)
local function BatNoclip()
    if noclipConnection then noclipConnection:Disconnect() end
    noclipConnection = RunService.Stepped:Connect(function()
        if autoFarmToggle and player.Character then
            -- Chỉ quét các bộ phận gốc bằng GetChildren() thay vì GetDescendants()
            for _, part in pairs(player.Character:GetChildren()) do
                if part:IsA("BasePart") and part.CanCollide then
                    part.CanCollide = false
                end
            end
        end
    end)
end

-- 2. HÀM TÌM QUÁI (Đã vá lỗi treo game)
local function LayMucTieu()
    -- Đợi tối đa 5 giây, không có thì bỏ qua để không bị kẹt script
    local folderNPC = workspace:WaitForChild("NPCs", 5)
    if not folderNPC then return nil end 
    
    for _, obj in pairs(folderNPC:GetChildren()) do 
        if obj.Name == TARGET_NAME and obj:FindFirstChild("Humanoid") and obj:FindFirstChild("HumanoidRootPart") then
            if obj.Humanoid.Health > 0 then
                return obj 
            end
        end
    end
    return nil 
end

-- 3. HÀM TẤN CÔNG (Có bảo vệ chống lỗi)
local function AttackBoss()
    pcall(function()
        game:GetService("ReplicatedStorage").CombatSystem.Remotes.RequestHit:FireServer()
    end)
end

-- 4. VÒNG LẶP AUTO FARM CHÍNH (Đã xử lý kẹt khi nhân vật chết)
local function BatDauFarm()
    BatNoclip()
    
    task.spawn(function()
        while autoFarmToggle do
            -- [SỬA LỖI CHÍ MẠNG]: Cập nhật lại nhân vật liên tục mỗi chu kỳ
            local character = player.Character or player.CharacterAdded:Wait()
            local rootPart = character:WaitForChild("HumanoidRootPart", 5)
            
            -- Nếu chưa có xác hoặc đang chết thì đợi rồi lặp lại
            if not rootPart or not character:FindFirstChild("Humanoid") or character.Humanoid.Health <= 0 then
                task.wait(1)
                continue 
            end

            local quaiHienTai = LayMucTieu()
            
            if quaiHienTai then
                local targetCFrame = quaiHienTai.HumanoidRootPart.CFrame * CFrame.new(0, 0, DISTANCE)
                local distance = (rootPart.Position - targetCFrame.Position).Magnitude
                
                -- Khắc phục lỗi giật ngược nếu đứng quá gần
                if distance > 10 then 
                    local tweenInfo = TweenInfo.new(distance / FLY_SPEED, Enum.EasingStyle.Linear)
                    local tween = TweenService:Create(rootPart, tweenInfo, {CFrame = targetCFrame})
                    tween:Play()
                    tween.Completed:Wait() 
                else
                    rootPart.CFrame = targetCFrame
                end
                
                -- Vòng lặp bám lưng đánh quái
                while autoFarmToggle and quaiHienTai and quaiHienTai.Parent and quaiHienTai:FindFirstChild("Humanoid") and quaiHienTai.Humanoid.Health > 0 do
                    -- [SỬA LỖI CHÍ MẠNG]: Kiểm tra lại xác ngay trong lúc đánh lỡ bị Boss đấm chết
                    if not player.Character or not player.Character:FindFirstChild("HumanoidRootPart") or player.Character.Humanoid.Health <= 0 then
                        break -- Thoát vòng lặp đánh để hồi sinh
                    end
                    
                    player.Character.HumanoidRootPart.CFrame = quaiHienTai.HumanoidRootPart.CFrame * CFrame.new(0, 0, DISTANCE)
                    AttackBoss()
                    task.wait(0.1) 
                end
            else
                task.wait(1) 
            end
        end
    end)
end

-- Chạy Script
BatDauFarm()
