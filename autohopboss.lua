local TeleportService = game:GetService("TeleportService")
local HttpService = game:GetService("HttpService")

-- =========================================================
-- 1. CẤU HÌNH CỐT LÕI (Chỗ duy nhất ông cần sửa tay)
-- =========================================================
-- Nhét tất cả tên Boss ông muốn săn vào đây. Ưu tiên con nào thì để lên đầu.
local DanhSachBoss = {"StrongestShinobiBoss", "AizenBoss", "YamatoBoss", "JinwooBoss"}
local delayHop = 1 -- Mức an toàn chống bị Roblox ban IP

-- =========================================================
-- 2. MODULE RADAR ĐA MỤC TIÊU
-- =========================================================
local function QuetRadarBoss()
    -- LỖ HỔNG CHỖ NÀY: Phải thay chữ "Enemies" bằng đúng tên thư mục ông soi được trong Dex
    local thuMucQuai = workspace:FindFirstChild("NPCs") or workspace
    
    for _, ten in pairs(DanhSachBoss) do
        local boss = thuMucQuai:FindFirstChild(ten)
        
        -- Logic: Tìm thấy đồ thật + Có thanh máu + Máu lớn hơn 0
        if boss and boss:FindFirstChild("Humanoid") and boss.Humanoid.Health > 0 then
            return boss -- Ném nguyên cái xác con Boss ra để dùng
        end
    end
    return nil -- Quét hết mảng không thấy ai thì báo rỗng
end

-- =========================================================
-- MODULE NHẢY SERVER (Bản vá lỗi GameFull)
-- =========================================================
local ServerDaThu = {} -- Sổ đen: Lưu ID các server đã đâm đầu vào
local trangHienTai = "" -- Dùng để lật trang nếu 100 server đầu tiên đều nát

local function DoiServer()
    local placeId, jobId = game.PlaceId, game.JobId
    
    -- Gắn thêm cursor để lật trang nếu cần
    local url = "https://games.roblox.com/v1/games/" .. placeId .. "/servers/Public?sortOrder=Asc&limit=100"
    if trangHienTai ~= "" then
        url = url .. "&cursor=" .. trangHienTai
    end
    
    local success, response = pcall(function() return game:HttpGet(url) end)
    if not success then return end

    local data = HttpService:JSONDecode(response)
    if data and data.data then
        local timThayServer = false
        
        for _, server in pairs(data.data) do
            -- LOGIC MỚI: 
            -- 1. Khác server đang đứng
            -- 2. Chưa từng nằm trong sổ đen (ServerDaThu)
            -- 3. Trừ hao an toàn: Phải trống ít nhất 2 slot (maxPlayers - 1)
            if type(server) == "table" and server.id ~= jobId and not ServerDaThu[server.id] and server.playing >= 3 and server.playing < 8 then
                
                print(">> Radar chốt server mới: " .. server.playing .. "/" .. server.maxPlayers .. " người. Đang Teleport...")
                
                -- Đưa ngay vào sổ đen để lần sau không đâm đầu lại
                ServerDaThu[server.id] = true 
                timThayServer = true
                
                TeleportService:TeleportToPlaceInstance(placeId, server.id, game.Players.LocalPlayer)
                task.wait(10)
                break
            end
        end
        
        -- Nếu quét sạch 100 server ở trang này mà không có cái nào xài được
        if not timThayServer then
            if data.nextPageCursor then
                print(">> Trang này hết server ngon. Chuẩn bị lật sang trang sau...")
                trangHienTai = data.nextPageCursor -- Lưu mã trang sau
            else
                print(">> Đã quét cạn đáy API Roblox. Reset lại từ trang đầu...")
                trangHienTai = "" 
                ServerDaThu = {} -- Xóa sổ đen làm lại từ đầu
            end
        end
    end
end

-- =========================================================
-- 4. TRÁI TIM KỊCH BẢN (Vòng lặp thực thi)
-- =========================================================
-- Dùng task.spawn để tách luồng, Delta không bị treo cứng khi chạy vòng lặp vô hạn
task.spawn(function()
    print(">> KÍCH HOẠT HỆ THỐNG AUTO BOSS HOP...")
    
    while true do
        task.wait(1) -- Trễ 1 giây mỗi vòng để CPU không bốc khói
        
        local bossMucTieu = QuetRadarBoss()
        
        if bossMucTieu then
            print(">> [BÁO ĐỘNG] Phát hiện mục tiêu: " .. bossMucTieu.Name .. " - HỦY LỆNH HOP!")
            
            -- ĐÂY LÀ ĐIỂM CHỜ:
            -- Sau này ông lôi cái hàm ModuleDiChuyen.BayToi(bossMucTieu.HumanoidRootPart) ráp vào đây
            -- Và gọi hàm AutoAttack() ở ngay dưới nó
            
            break -- Đập vỡ vòng lặp Hop, giữ nhân vật đứng lại server này để đấm Boss
        else
            print(">> Trắng tay. Đợi " .. delayHop .. "s rồi té sang Server khác...")
            task.wait(delayHop)
            DoiServer()
        end
    end
end)
