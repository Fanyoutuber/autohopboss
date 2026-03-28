local Cfg = getgenv().Tai_Config

-- =========================================
print(">> Giai doan 1: Khoi tao...")
task.wait(1) 

local TS = game:GetService("TeleportService")
local HS = game:GetService("HttpService")
local TweenService = game:GetService("TweenService")
local RS = game:GetService("ReplicatedStorage")
local RunService = game:GetService("RunService")

local Player = game.Players.LocalPlayer
local PId, JId = game.PlaceId, game.JobId

local ServerDaThu = {}
local cursor = ""

-- =========================================
-- KHU VỰC CÁC HÀM PHỤ TRỢ
-- =========================================

-- 1. HÀM NOCLIP
local noclipConnection
local function BatNoclip()
    if noclipConnection then noclipConnection:Disconnect() end
    noclipConnection = RunService.Stepped:Connect(function()
        local char = Player.Character
        if char then
            for _, part in pairs(char:GetChildren()) do
                if part:IsA("BasePart") and part.CanCollide then
                    part.CanCollide = false
                end
            end
        end
    end)
end

-- 2. HÀM TÌM BOSS (Gọi list từ Config)
local function QuetRadarBoss()
    local folder = workspace:WaitForChild("NPCs", 5) or workspace
    for _, ten in pairs(Cfg.DanhSachBoss) do
        local b = folder:FindFirstChild(ten)
        if b and b:FindFirstChild("Humanoid") and b.Humanoid.Health > 0 then 
            return b 
        end
    end
    return nil
end

-- 3. HÀM HOP SERVER 
local function DoiServerSieuToc()
    while true do 
        local url = "https://games.roblox.com/v1/games/"..PId.."/servers/Public?sortOrder=Asc&limit=100"
        if cursor ~= "" then url = url .. "&cursor=" .. cursor end
        
        local success, res = pcall(function() return game:HttpGet(url) end)
        if not success then return print(">> [LỖI API] Doi nhip sau...") end
        
        local data = HS:JSONDecode(res)
        if data and data.data then
            local danhSachNgon = {} 
            for _, srv in pairs(data.data) do
                if type(srv) == "table" and srv.id ~= JId and not ServerDaThu[srv.id] and srv.playing < (srv.maxPlayers - 2) then
                    table.insert(danhSachNgon, srv)
                end
            end
            
            if #danhSachNgon > 0 then
                local chot = danhSachNgon[math.random(1, #danhSachNgon)]
                print(">> Chot phong: " .. chot.playing .. "/" .. chot.maxPlayers)
                ServerDaThu[chot.id] = true
                TS:TeleportToPlaceInstance(PId, chot.id, Player)
                task.wait(5)
                return 
            else
                cursor = data.nextPageCursor or ""
                if cursor == "" then
                    print(">> Quet can game khong thay phong, reset...")
                    ServerDaThu = {} 
                    break 
                end
                task.wait(0.5) 
            end
        end
    end
end

-- 4. HÀM BAY TỚI BOSS (Gọi Khoảng cách & Tốc độ từ Config)
-- 4. HÀM BAY TỚI BOSS (Đã vá lỗi nhận diện Boss)
local function BayToi(target)
    local character = Player.Character or Player.CharacterAdded:Wait()
    local rootPart = character:WaitForChild("HumanoidRootPart", 5)
    
    if not rootPart or not target then return false end

    -- Bổ sung bộ dò tìm dự phòng: Lấy 1 trong 3 cục làm mốc
    -- Ưu tiên bốc thẳng cái Torso ra trước, không có mới mò tới HumanoidRootPart
    local bossRoot = target:FindFirstChild("Torso") or target:FindFirstChild("HumanoidRootPart")
    
    if not bossRoot then 
        print(">> [LỖI]: Boss " .. target.Name .. " bị thiếu lõi vật lý (Torso/HRP)!")
        return false 
    end

    local targetCFrame = bossRoot.CFrame * CFrame.new(0, 0, Cfg.KhoangCachBay) 
    local distance = (rootPart.Position - targetCFrame.Position).Magnitude
    
    if distance > 10 then
        local tweenInfo = TweenInfo.new(distance / Cfg.TocDoBay, Enum.EasingStyle.Linear) 
        local tween = TweenService:Create(rootPart, tweenInfo, {CFrame = targetCFrame})
        tween:Play()
        tween.Completed:Wait() 
    else
        rootPart.CFrame = targetCFrame
    end
    return true
end

-- 5. HÀM BÁM LƯNG VÀ TẤN CÔNG (Đã đồng bộ với hàm Bay)
local function DanhBoss(target)
    local Combat = RS:FindFirstChild("CombatSystem") and RS.CombatSystem.Remotes.RequestHit
    local Ability = RS:FindFirstChild("AbilitySystem") and RS.AbilitySystem.Remotes.RequestAbility
    
    while target and target.Parent and target:FindFirstChild("Humanoid") and target.Humanoid.Health > 0 do
        local character = Player.Character
        local bossRoot = target:FindFirstChild("HumanoidRootPart") or target:FindFirstChild("Torso") or target:FindFirstChild("UpperTorso")
        
        if not character or not character:FindFirstChild("HumanoidRootPart") or character:FindFirstChild("Humanoid").Health <= 0 then
            break 
        end
        
        -- Nếu boss mất xác đột ngột thì văng ra để tìm con mới
        if not bossRoot then break end 
        
        character.HumanoidRootPart.CFrame = bossRoot.CFrame * CFrame.new(0, 0, Cfg.KhoangCachBay)
        
        pcall(function()
            if Ability and type(Cfg.CacChieuSuDung) == "table" then
                for _, idChieu in pairs(Cfg.CacChieuSuDung) do
                    Ability:FireServer(idChieu)
                    task.wait(Cfg.DelayGiuaCacChieu) 
                end
            end
            if Combat then Combat:FireServer() end
        end)
        
        task.wait(Cfg.TocDoDanh) 
    end
end
-- =========================================
-- VÒNG LẶP AUTO FARM CHÍNH
-- =========================================
print(">> Giai doan 4: Kich hoat Farm!")
task.wait(1)

BatNoclip() 

task.spawn(function()
    while task.wait(1) do
        local target = QuetRadarBoss()
        
        if target then
            print(">> Phat hien Boss: " .. target.Name .. ". Dang bay toi...")
            
            local bayThanhCong = BayToi(target)
            
            if bayThanhCong then
                print(">> Da tiep can! Dang xa skill...")
                DanhBoss(target)
            end
            
            print(">> Boss da chet hoac nhan vat bay mau, quet lai...")
        else
            print(">> Map sach. Doi " .. Cfg.ThoiGianChoHop .. "s roi Hop...")
            task.wait(Cfg.ThoiGianChoHop)
            DoiServerSieuToc()
        end
    end
end)
