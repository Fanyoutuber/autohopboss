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
-- 4. MODULE NHẢY SERVER (ÉP XUNG)
-- =========================================================
local function DoiServer()
    local url = "https://games.roblox.com/v1/games/"..PId.."/servers/Public?sortOrder=Asc&limit=100"
    
    while true do 
        local apiUrl = url
        if trangHienTai ~= "" then apiUrl = apiUrl.."&cursor="..trangHienTai end
        
        local success, res = pcall(function() return game:HttpGet(apiUrl) end)
        if not success then return end 

        local data = HS:JSONDecode(res)
        if data and data.data then
            for _, srv in pairs(data.data) do
                if type(srv) == "table" and srv.id ~= JId and not ServerDaThu[srv.id] and srv.playing >= 3 and srv.playing < 8 then
                    print(">> Chốt server: " .. srv.playing .. " người. Đang Teleport...")
                    ServerDaThu[srv.id] = true
                    TS:TeleportToPlaceInstance(PId, srv.id, Player)
                    task.wait(10)
                    return
                end
            end
            
            trangHienTai = data.nextPageCursor or ""
            if trangHienTai == "" then 
                ServerDaThu = {} 
                print(">> Quét cạn API. Đợi reset...")
                break 
            end
            
            print(">> Trang này rác, lật trang tiếp theo...")
            task.wait(0.2) 
        else
            break
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
