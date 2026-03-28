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

-- 4. HÀM BAY TỚI BOSS (Xử lý mượt StreamingEnabled)
local function BayToi(target)
    local character = Player.Character or Player.CharacterAdded:Wait()
    local rootPart = character:WaitForChild("HumanoidRootPart", 5)
    
    if not rootPart or not target then return false end

    -- Bước 1: Bay tới tọa độ ảo (Pivot) của model để ép game nạp dữ liệu
    local toaDoAo = target:GetPivot() * CFrame.new(0, 0, Cfg.KhoangCachBay)
    local distance = (rootPart.Position - toaDoAo.Position).Magnitude
    
    if distance > 10 then
        local tweenInfo = TweenInfo.new(distance / Cfg.TocDoBay, Enum.EasingStyle.Linear) 
        local tween = TweenService:Create(rootPart, tweenInfo, {CFrame = toaDoAo})
        tween:Play()
        tween.Completed:Wait() -- Chờ bay tới vùng biển chứa Boss
    else
        rootPart.CFrame = toaDoAo
    end

    -- Bước 2: Tới nơi rồi, đứng đợi game load cái lõi vật lý ra
    local thoiGianCho = 0
    local bossRoot = target:FindFirstChild("HumanoidRootPart") or target:FindFirstChild("Torso")
    
    while not bossRoot and thoiGianCho < 5 do -- Chờ tối đa 5 giây cho chắc cú
        task.wait(0.5)
        thoiGianCho = thoiGianCho + 0.5
        bossRoot = target:FindFirstChild("HumanoidRootPart") or target:FindFirstChild("Torso")
    end

    -- Đợi 5 giây mà mạng lag vẫn chưa load được xác thì báo lỗi, chuyển con khác
    if not bossRoot then 
        print(">> [LỖI] Đã tới nơi nhưng game lag không load được thể xác Boss!")
        return false 
    end
    
    return true
end
-- 5. HÀM BÁM LƯNG VÀ TẤN CÔNG (Lối đánh Cối Xay Gió)
local function DanhBoss(target)
    local Combat = RS:FindFirstChild("CombatSystem") and RS.CombatSystem.Remotes.RequestHit
    local Ability = RS:FindFirstChild("AbilitySystem") and RS.AbilitySystem.Remotes.RequestAbility
    
    while target and target.Parent and target:FindFirstChild("Humanoid") and target.Humanoid.Health > 0 do
        local character = Player.Character
        local bossRoot = target:FindFirstChild("HumanoidRootPart") or target:FindFirstChild("Torso")
        
        -- Đang đánh mà bay màu thì văng ra hồi sinh
        if not character or not character:FindFirstChild("HumanoidRootPart") or character:FindFirstChild("Humanoid").Health <= 0 then
            break 
        end
        if not bossRoot then break end
        
        -- Nếu có danh sách chiêu thì chơi kiểu xoay vòng
        if Ability and type(Cfg.CacChieuSuDung) == "table" and #Cfg.CacChieuSuDung > 0 then
            for _, idChieu in ipairs(Cfg.CacChieuSuDung) do
                -- Phải kiểm tra lại xác Boss và xác mình trước mỗi nhịp vung tay (lỡ chết giữa combo)
                if not target:FindFirstChild("Humanoid") or target.Humanoid.Health <= 0 then break end
                if not Player.Character or Player.Character:FindFirstChild("Humanoid").Health <= 0 then break end
                
                -- Khóa tọa độ liên tục theo thời gian thực lỡ Boss lướt đi
                bossRoot = target:FindFirstChild("HumanoidRootPart") or target:FindFirstChild("Torso")
                if bossRoot then
                    Player.Character.HumanoidRootPart.CFrame = bossRoot.CFrame * CFrame.new(0, 0, Cfg.KhoangCachBay)
                end
                
                -- Bơm Combo: Xả chiêu xong nhồi ngay 1 cú chém thường
                pcall(function()
                    Ability:FireServer(idChieu)
                    if Combat then Combat:FireServer() end
                end)
                
                -- Khựng lại 1 nhịp (0.5s) để game load đồ họa sát thương
                task.wait(Cfg.NhipDanh) 
            end
        else
            -- Nếu ông xóa hết chiêu trong bảng Config, nó sẽ tự lùi về chế độ chỉ chém thường
            character.HumanoidRootPart.CFrame = bossRoot.CFrame * CFrame.new(0, 0, Cfg.KhoangCachBay)
            pcall(function() if Combat then Combat:FireServer() end end)
            task.wait(Cfg.TocDoDanh)
        end
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
