local TS = game:GetService("TeleportService")
local HS = game:GetService("HttpService")
local Player = game.Players.LocalPlayer
local PId, JId = game.PlaceId, game.JobId

-- =========================================================
-- 1. CẤU HÌNH CỐT LÕI
-- =========================================================
local DanhSachBoss = {"StrongestShinobiBoss", "AizenBoss"}
local delayHop = 3 
local ServerDaThu = {}

-- =========================================================
-- 2. MODULE RADAR
-- =========================================================
local function QuetRadarBoss()
    local thuMucQuai = workspace:FindFirstChild("NPCs") or workspace
    for _, ten in pairs(DanhSachBoss) do
        local boss = thuMucQuai:FindFirstChild(ten)
        if boss and boss:FindFirstChild("Humanoid") and boss.Humanoid.Health > 0 then
            return boss 
        end
    end
    return nil
end

-- =========================================================
-- 3. MODULE NHẢY SERVER SIÊU TỐC
-- =========================================================
local function DoiServerSieuToc()
    local url = "https://games.roblox.com/v1/games/"..PId.."/servers/Public?sortOrder=Desc&limit=100"
    
    local success, res = pcall(function() return game:HttpGet(url) end)
    if not success then return end 

    local data = HS:JSONDecode(res)
    if data and data.data then
        local danhSachServerNgon = {} 
        
        for _, srv in pairs(data.data) do
            if type(srv) == "table" and srv.id ~= JId and not ServerDaThu[srv.id] and srv.playing < (srv.maxPlayers - 1) then
                table.insert(danhSachServerNgon, srv)
            end
        end
        
        if #danhSachServerNgon > 0 then
            local serverChot = danhSachServerNgon[math.random(1, #danhSachServerNgon)]
            
            print(">> [Bơm Ga] Chốt ngẫu nhiên server " .. serverChot.playing .. "/" .. serverChot.maxPlayers .. ". Teleport ngay!")
            ServerDaThu[serverChot.id] = true
            TS:TeleportToPlaceInstance(PId, serverChot.id, Player)
            task.wait(3) 
        else
            print(">> 100 Server đầu đều nát. Đợi nhịp sau lấy danh sách mới...")
            ServerDaThu = {} 
        end
    end
end

-- =========================================================
-- 4. VÒNG LẶP THỰC THI (TRÁI TIM)
-- =========================================================
task.spawn(function()
    print(">> KÍCH HOẠT HỆ THỐNG AUTO BOSS HOP...")
    
    while true do
        task.wait(1) 
        local bossMucTieu = QuetRadarBoss()
        
        if bossMucTieu then
            print(">> [BÁO ĐỘNG] Bắt được: " .. bossMucTieu.Name .. " - KHÓA MỤC TIÊU!")
            
            repeat
                task.wait(0.5) 
                -- Đợi chèn hàm Bay và hàm Đánh vào đây
                
            until not bossMucTieu or not bossMucTieu.Parent or not bossMucTieu:FindFirstChild("Humanoid") or bossMucTieu.Humanoid.Health <= 0
            
            print(">> Boss đã bị tiêu diệt hoặc biến mất. Khởi động lại Radar...")
        else
            print(">> Trắng tay. Đợi " .. delayHop .. "s rồi té sang Server khác...")
            task.wait(delayHop)
            DoiServerSieuToc() -- GỌI ĐÚNG HÀM MỚI Ở ĐÂY
        end
    end
end)
