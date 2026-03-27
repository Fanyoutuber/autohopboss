print(">> Giai doan 1: Khoi tao...")
task.wait(5) 
local TS, HS = game:GetService("TeleportService"), game:GetService("HttpService")
local RS = game:GetService("ReplicatedStorage")
local RunService = game:GetService("RunService")
local Player, PId, JId = game.Players.LocalPlayer, game.PlaceId, game.JobId
local Cfg = getgenv().Tai_Config
local cursor, tenFile = "", "SoDen_Tai.json"

local ServerDaThu = {}
pcall(function() if isfile(tenFile) then ServerDaThu = HS:JSONDecode(readfile(tenFile)) end end)
ServerDaThu[JId] = true 

-- HỆ THỐNG NOCLIP ĐỘC LẬP
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
task.wait(0.5)
local function QuetRadarBoss()
    local folder = workspace:FindFirstChild("NPCs") or workspace
    for _, ten in pairs(Cfg.DanhSachBoss) do
        local b = folder:FindFirstChild(ten)
        if b and b:FindFirstChild("Humanoid") and b.Humanoid.Health > 0 then return b end
    end
end

print(">> Giai doan 3: Nap Teleport...")
task.wait(0.5)
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
                task.wait(5)
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

-- MODULE BAY BẰNG LERP CFRAME (KHÔNG XÀI TWEEN)
local function BayToi(DichDen)
    local char = Player.Character
    if not char or not char:FindFirstChild("HumanoidRootPart") then return end
    local HRP = char.HumanoidRootPart
    local KhoangCach = (HRP.Position - DichDen.Position).Magnitude
    
    -- Xử lý khác đảo: Bay tức thời lên không trung 500 stud để ép load map
    if KhoangCach > 2000 then
        HRP.CFrame = DichDen * CFrame.new(0, 500, 0)
        -- Hãm phanh triệt để, chống rớt tự do vỡ đầu cắn dame
        HRP.Velocity = Vector3.new(0, 0, 0) 
        task.wait(0.5) 
        return
    end

    -- Lướt mượt bằng Lerp dựa trên tốc độ vòng lặp (Ép tốc 350 stud/s)
    local BuocNhay = 350 / KhoangCach * Cfg.TocDoSpamChieu
    if BuocNhay > 1 then BuocNhay = 1 end -- Chống văng xuyên vũ trụ nếu đứng quá gần
    
    HRP.CFrame = HRP.CFrame:Lerp(DichDen, BuocNhay)
    HRP.Velocity = Vector3.new(0, 0, 0) -- Giữ nhân vật lơ lửng không bị rớt
end

print(">> Giai doan 4: Kich hoat Farm!")
task.wait(0.5)
task.spawn(function()
    local Combat = RS:FindFirstChild("CombatSystem") and RS.CombatSystem.Remotes.RequestHit
    local Ability = RS:FindFirstChild("AbilitySystem") and RS.AbilitySystem.Remotes.RequestAbility

    while task.wait(1) do
        local target = QuetRadarBoss()
        
        if target then
            print(">> Muc tieu: " .. target.Name)
            BatNoclip() 
            
            repeat 
                local char = Player.Character
                local khoangCachToiBoss = 9999
                
                if char and target:FindFirstChild("HumanoidRootPart") then
                    -- Lấy tọa độ dưới gầm đất boss
                    local viTriAnToan = target.HumanoidRootPart.CFrame * CFrame.new(0, Cfg.KhoangCachBay, 0)
                    khoangCachToiBoss = (char.HumanoidRootPart.Position - viTriAnToan.Position).Magnitude
                    BayToi(viTriAnToan)
                end
                
                -- CHỈ BẮN CHIÊU KHI ĐÃ ÁP SÁT (< 30 STUD)
                if khoangCachToiBoss < 30 then
                    pcall(function()
                        if Ability and type(Cfg.CacChieuSuDung) == "table" then
                            for _, idChieu in pairs(Cfg.CacChieuSuDung) do
                                Ability:FireServer(idChieu)
                                task.wait(Cfg.DelayGiuaCacChieu or 0.6) 
                            end
                        end
                        if Combat then Combat:FireServer() end
                    end)
                end
                
                -- Thời gian lặp chính (quyết định độ mượt của màn lướt)
                task.wait(Cfg.TocDoSpamChieu) 
                
            until not target or not target.Parent or not target:FindFirstChild("Humanoid") or target.Humanoid.Health <= 0
            
            print(">> Boss chet, tat Noclip, tim tiep...")
            TatNoclip() 
        else
            print(">> Map sach. Doi " .. Cfg.ThoiGianChoHop .. "s roi Hop...")
            task.wait(Cfg.ThoiGianChoHop)
            DoiServerSieuToc()
        end
    end
end)
