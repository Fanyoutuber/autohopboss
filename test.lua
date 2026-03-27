print(">> Giai doan 1: Khoi tao...")
task.wait(10) 
local TS, HS = game:GetService("TeleportService"), game:GetService("HttpService")
local TweenService, RS = game:GetService("TweenService"), game:GetService("ReplicatedStorage")
local Player, PId, JId = game.Players.LocalPlayer, game.PlaceId, game.JobId
local Cfg = getgenv().Tai_Config
local cursor, tenFile = "", "SoDen_Tai.json"

-- Event Manager
getgenv().ActiveConnections = getgenv().ActiveConnections or {}
local function RegisterEvent(signal, name, callback, noPcall)
    if ActiveConnections[name] then ActiveConnections[name]:Disconnect(); ActiveConnections[name] = nil end
    if noPcall then
        ActiveConnections[name] = signal:Connect(callback)
    else
        ActiveConnections[name] = signal:Connect(function(...)
            local success, err = pcall(callback, ...)
            if not success then warn("[Event Error] " .. name .. ": " .. tostring(err)) end
        end)
    end
end

-- Trí nhớ Sổ đen
local ServerDaThu = {}
pcall(function() if isfile(tenFile) then ServerDaThu = HS:JSONDecode(readfile(tenFile)) end end)
ServerDaThu[JId] = true 

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

-- MODULE BAY TỚI MỤC TIÊU & NOCLIP
local RunService = game:GetService("RunService")

local function BayToi(DichDen)
    local char = Player.Character
    if not char or not char:FindFirstChild("HumanoidRootPart") then return end
    local HRP = char.HumanoidRootPart
    
    -- [VÁ LỖI KẸT ĐẢO] Bật Noclip liên tục bằng Event Manager để đi xuyên núi
    RegisterEvent(RunService.Stepped, "Noclip_Tai", function()
        for _, v in pairs(char:GetDescendants()) do
            if v:IsA("BasePart") and v.CanCollide then 
                v.CanCollide = false 
            end
        end
    end)

    -- Tăng tốc độ bay lên 350 để lướt nhanh hơn
    local ThoiGian = (HRP.Position - DichDen.Position).Magnitude / 350
    TweenService:Create(HRP, TweenInfo.new(ThoiGian, Enum.EasingStyle.Linear), {CFrame = DichDen}):Play()
end

local function TatNoclip()
    UnregisterEvent("Noclip_Tai")
end

print(">> Giai doan 4: Kich hoat Farm! (Ban Da Luong Xa Skill)")
task.wait(0.5)
task.spawn(function()
    local Combat = RS:FindFirstChild("CombatSystem") and RS.CombatSystem.Remotes.RequestHit
    local Ability = RS:FindFirstChild("AbilitySystem") and RS.AbilitySystem.Remotes.RequestAbility

    while task.wait(1) do
        local target = QuetRadarBoss()
        
        if target then
            print(">> Muc tieu: " .. target.Name)
            local danhNgung = false -- Cờ hiệu để quản lý luồng đánh thường
            
            -- [LUỒNG 1] CHUYÊN TRÁCH ĐÁNH THƯỜNG (M1 SUPER FAST)
            task.spawn(function()
                while not danhNgung and target and target.Parent and target:FindFirstChild("Humanoid") and target.Humanoid.Health > 0 do
                    pcall(function()
                        if Combat then Combat:FireServer() end
                    end)
                    task.wait(0.05) -- Tốc độ đánh thường vắt kiệt công suất (20 hit/giây)
                end
            end)
            
            -- [LUỒNG 2] CHUYÊN TRÁCH DI CHUYỂN VÀ XẢ CHIÊU
            repeat 
                task.wait(Cfg.TocDoSpamChieu) 
                local char = Player.Character
                local khoangCachToiBoss = 9999
                
                if char and target:FindFirstChild("HumanoidRootPart") then
                    local viTriAnToan = target.HumanoidRootPart.CFrame * CFrame.new(0, Cfg.KhoangCachBay, 0)
                    khoangCachToiBoss = (char.HumanoidRootPart.Position - viTriAnToan.Position).Magnitude
                    BayToi(viTriAnToan)
                end
                
                if khoangCachToiBoss < 30 then
                    pcall(function()
                        if Ability and type(Cfg.CacChieuSuDung) == "table" then
                            for _, idChieu in pairs(Cfg.CacChieuSuDung) do
                                Ability:FireServer(idChieu)
                            end
                        end
                    end)
                end
                
            until not target or not target.Parent or not target:FindFirstChild("Humanoid") or target.Humanoid.Health <= 0
            
            danhNgung = true -- Boss chết, kéo cờ đỏ để dập tắt Luồng 1
            print(">> Boss chet, tat Noclip, tim tiep...")
            if TatNoclip then TatNoclip() end 
        else
            print(">> Map sach. Doi " .. Cfg.ThoiGianChoHop .. "s roi Hop...")
            task.wait(Cfg.ThoiGianChoHop)
            DoiServerSieuToc()
        end
    end
end)
