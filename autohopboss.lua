local TeleportService = game:GetService("TeleportService")
local HttpService = game:GetService("HttpService")

-- =========================================================
-- 1. CẤU HÌNH CỐT LÕI (Chỗ duy nhất ông cần sửa tay)
-- =========================================================
-- Nhét tất cả tên Boss ông muốn săn vào đây. Ưu tiên con nào thì để lên đầu.
local DanhSachBoss = {"StrongestShinobiBoss", "AizenBoss", "JinwooBoss", "JinwooBoss"}
local delayHop = 5 -- Mức an toàn chống bị Roblox ban IP

-- =========================================================
-- 2. MODULE RADAR ĐA MỤC TIÊU
-- =========================================================
local function QuetRadarBoss()
    -- LỖ HỔNG CHỖ NÀY: Phải thay chữ "Enemies" bằng đúng tên thư mục ông soi được trong Dex
    local thuMucQuai = workspace:FindFirstChild("Enemies") or workspace
    
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
-- 3. MODULE NHẢY SERVER
-- =========================================================
local function DoiServer()
    local placeId = game.PlaceId
    local jobId = game.JobId
    local url = "https://games.roblox.com/v1/games/" .. tostring(placeId) .. "/servers/Public?sortOrder=Desc&limit=100"
    
    -- pcall: Bọc lại để nếu mạng rớt, script không kéo sập luôn phần mềm Delta
    local success, response = pcall(function() return game:HttpGet(url) end)
    if not success then return end
    
    local data = HttpService:JSONDecode(response)
    if data and data.data then
        for _, server in pairs(data.data) do
            -- Lọc server: Phải khác phòng hiện tại và còn chỗ trống
            if type(server) == "table" and server.id ~= jobId and server.playing < server.maxPlayers then
                print(">> Radar chốt được Server mới. Đang chuẩn bị Teleport...")
                TeleportService:TeleportToPlaceInstance(placeId, server.id, game.Players.LocalPlayer)
                task.wait(10) -- Khóa mõm script, chờ game đẩy sang phòng kia
                break
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