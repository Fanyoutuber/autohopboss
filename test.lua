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
    local ThoiGian = (HRP.Position - DichDen.Position).Magnitude / 300
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
            repeat 
                task.wait(Cfg.TocDoSpamChieu) 
                local char = Player.Character
                if char and target:FindFirstChild("HumanoidRootPart") then
                    BayToi(target.HumanoidRootPart.CFrame * CFrame.new(0, Cfg.KhoangCachBay, 0))
                end
                
                pcall(function()
                    -- Bắn đòn đánh thường
                    if Combat then Combat:FireServer() end
                    
                    -- Quét mảng để bắn các chiêu được chỉ định
                    if Ability and type(Cfg.CacChieuSuDung) == "table" then
                        for _, idChieu in pairs(Cfg.CacChieuSuDung) do
                            Ability:FireServer(idChieu)
                        end
                    end
                end)
                
            until not target or not target.Parent or not target:FindFirstChild("Humanoid") or target.Humanoid.Health <= 0
            
            print(">> Boss chet, tim tiep...")
        else
            print(">> Map sach. Doi " .. Cfg.ThoiGianChoHop .. "s roi Hop...")
            task.wait(Cfg.ThoiGianChoHop)
            DoiServerSieuToc()
        end
    end
end)
