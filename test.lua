-- =========================================================
-- 🛑 LÕI HỆ THỐNG (BẢN VÁ LỖI NOCLIP & TỐI ƯU COMBO SKILL)
-- =========================================================
print(">> Giai doan 1: Khoi tao...")
task.wait(15) 
local TS, HS = game:GetService("TeleportService"), game:GetService("HttpService")
local TweenService, RS = game:GetService("TweenService"), game:GetService("ReplicatedStorage")
local RunService = game:GetService("RunService")
local Player, PId, JId = game.Players.LocalPlayer, game.PlaceId, game.JobId
local Cfg = getgenv().Tai_Config
local cursor, tenFile = "", "SoDen_Tai.json"

-- Trí nhớ Sổ đen
local ServerDaThu = {}
pcall(function() if isfile(tenFile) then ServerDaThu = HS:JSONDecode(readfile(tenFile)) end end)
ServerDaThu[JId] = true 

-- [VÁ LỖI 1] HỆ THỐNG NOCLIP ĐỘC LẬP (ÉP XUYÊN ĐẢO)
local NoclipConnection
local function BatNoclip()
    if NoclipConnection then NoclipConnection:Disconnect() end
    NoclipConnection = RunService.Stepped:Connect(function()
        local char = Player.Character
        if char then
            for _, v in pairs(char:GetDescendants()) do
                if v:IsA("BasePart") and v.CanCollide then v.CanCollide = false end
            end
        end
    end)
end

local function TatNoclip()
    if NoclipConnection then NoclipConnection:Disconnect(); NoclipConnection = nil end
end

print(">> Giai doan 2: Nap Radar...")
task.wait(2)
local function QuetRadarBoss()
    local folder = workspace:FindFirstChild("NPCs") or workspace
    for _, ten in pairs(Cfg.DanhSachBoss) do
        local b = folder:FindFirstChild(ten)
        if b and b:FindFirstChild("Humanoid") and b.Humanoid.Health > 0 then return b end
    end
end

print(">> Giai doan 3: Nap Teleport...")
task.wait(2)
local function DoiServerSieuToc()
    while true do 
        local url = "https://games.roblox.com/v1/games/"..PId.."/servers/Public?sortOrder=Desc&limit=100"
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
                pcall(function() writefile(tenFile, HS:JSONEncode(ServerDaThu)) end)
                TS:TeleportToPlaceInstance(PId, chot.id, Player)
                task.wait(10)
                return 
            else
                cursor = data.nextPageCursor or ""
                if cursor == "" then
                    ServerDaThu = {} 
                    pcall(function() delfile(tenFile) end) 
                    break 
                end
                task.wait(0.2) 
            end
        end
    end
end

local function BayToi(DichDen)
    local char = Player.Character
    if not char or not char:FindFirstChild("HumanoidRootPart") then return end
    local HRP = char.HumanoidRootPart
    local ThoiGian = (HRP.Position - DichDen.Position).Magnitude / 350 -- Tốc độ 350 stud/s
    TweenService:Create(HRP, TweenInfo.new(ThoiGian, Enum.EasingStyle.Linear), {CFrame = DichDen}):Play()
end

print(">> Giai doan 4: Kich hoat Farm!")
task.wait(2)
task.spawn(function()
    local Combat = RS:FindFirstChild("CombatSystem") and RS.CombatSystem.Remotes.RequestHit
    local Ability = RS:FindFirstChild("AbilitySystem") and RS.AbilitySystem.Remotes.RequestAbility

    while task.wait(1) do
        local target = QuetRadarBoss()
        
        if target then
            print(">> Muc tieu: " .. target.Name)
            BatNoclip() -- Bật xuyên tường ngay khi thấy Boss
            
            repeat 
                local char = Player.Character
                local khoangCachToiBoss = 9999
                
                if char and target:FindFirstChild("HumanoidRootPart") then
                    local viTriAnToan = target.HumanoidRootPart.CFrame * CFrame.new(0, Cfg.KhoangCachBay, 0)
                    khoangCachToiBoss = (char.HumanoidRootPart.Position - viTriAnToan.Position).Magnitude
                    BayToi(viTriAnToan)
                end
                
                -- [VÁ LỖI 2] COMBO TUẦN TỰ (Ưu tiên Chiêu thức -> Đánh thường)
                if khoangCachToiBoss < 30 then
                    pcall(function()
                        -- 1. Xả toàn bộ chiêu trong Config
                        if Ability and type(Cfg.CacChieuSuDung) == "table" then
                            for _, idChieu in pairs(Cfg.CacChieuSuDung) do
                                Ability:FireServer(idChieu)
                                task.wait(0.05) -- Nghỉ 0.05s giữa các chiêu để chống kẹt phím
                            end
                        end
                        -- 2. Chêm 1 phát đánh thường vào lúc chờ hồi chiêu
                        if Combat then Combat:FireServer() end
                    end)
                end
                
                task.wait(Cfg.TocDoSpamChieu) -- Nghỉ theo nhịp độ cài đặt rồi combo tiếp
                
            until not target or not target.Parent or not target:FindFirstChild("Humanoid") or target.Humanoid.Health <= 0
            
            print(">> Boss chet, tat Noclip, tim tiep...")
            TatNoclip() -- Chốt hạ lỗi Line 101 ở đây
        else
            print(">> Map sach. Doi " .. Cfg.ThoiGianChoHop .. "s roi Hop...")
            task.wait(Cfg.ThoiGianChoHop)
            DoiServerSieuToc()
        end
    end
end)
