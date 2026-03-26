local TS = game:GetService("TeleportService")
local HS = game:GetService("HttpService")
local Player = game.Players.LocalPlayer
local PId, JId = game.PlaceId, game.JobId

-- =========================================================
-- 1. CẤU HÌNH CỐT LÕI
-- =========================================================
local DanhSachBoss = {"StrongestShinobiBoss", "AizenBoss"}
local delayHop = 5 -- Bắt buộc để 5s trở lên

-- =========================================================
-- 2. BIẾN HỆ THỐNG HOP
-- =========================================================
local ServerDaThu = {}
local trangHienTai = ""

-- =========================================================
-- 3. MODULE RADAR
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
-- 4. MODULE NHẢY SERVER (Bản Mô Phỏng Banana Hub)
-- =========================================================
local function DoiServerSieuToc()
    -- Luôn lấy 100 server đông nhất (Desc) để đảm bảo không dính server rác/lỗi
    local url = "https://games.roblox.com/v1/games/"..PId.."/servers/Public?sortOrder=Desc&limit=100"
    
    local success, res = pcall(function() return game:HttpGet(url) end)
    if not success then return end 

    local data = HS:JSONDecode(res)
    if data and data.data then
        local danhSachServerNgon = {} -- Cái rổ chứa server xài được
        
        -- Bước 1: Quét 1 lượt 100 server, con nào trống từ 2 chỗ trở lên thì ném hết vào rổ
        for _, srv in pairs(data.data) do
            if type(srv) == "table" and srv.id ~= JId and not ServerDaThu[srv.id] and srv.playing < (srv.maxPlayers - 1) then
                table.insert(danhSachServerNgon, srv)
            end
        end
        
        -- Bước 2: Nếu rổ có đồ, bốc NGẪU NHIÊN 1 cái để né đụng xe với tụi player khác
        if #danhSachServerNgon > 0 then
            local serverChot = danhSachServerNgon[math.random(1, #danhSachServerNgon)]
            
            print(">> [Bơm Ga] Chốt ngẫu nhiên server " .. serverChot.playing .. "/" .. serverChot.maxPlayers .. ". Teleport ngay!")
            ServerDaThu[serverChot.id] = true
            
            TS:TeleportToPlaceInstance(PId, serverChot.id, Player)
            
            -- Ép xung: Chỉ đợi 3s để mồi lệnh. Nếu xịt, vòng lặp chính sẽ tự gọi lại hàm này cực nhanh
            task.wait(3) 
        else
            print(">> 100 Server đầu đều nát. Đợi nhịp sau lấy danh sách mới...")
            -- Hết server ngon thì xóa sổ đen để làm lại vòng mới, không cần lật trang rườm rà
            ServerDaThu = {} 
        end
    end
end

-- =========================================================
-- 5. VÒNG LẶP THỰC THI (TRÁI TIM)
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
            DoiServer()
        end
    end
end)
