local TS = game:GetService("TeleportService")
local HS = game:GetService("HttpService")
local Player = game.Players.LocalPlayer
local PId, JId = game.PlaceId, game.JobId

-- =========================================================
-- 1. CẤU HÌNH CỐT LÕI
-- =========================================================
local DanhSachBoss = {"StrongestShinobiBoss", "AizenBoss"}
local delayHop = 10 -- Nâng lên 10s để né cái lỗi "Whitelist Error (4/3)" ông vừa gặp
local ServerDaThu = {}
local trangHienTai = ""

-- =========================================================
-- 2. MODULE RADAR
-- =========================================================
local function QuetRadarBoss()
    local folder = workspace:FindFirstChild("NPCs") or workspace
    for _, ten in pairs(DanhSachBoss) do
        local b = folder:FindFirstChild(ten)
        if b and b:FindFirstChild("Humanoid") and b.Humanoid.Health > 0 then return b end
    end
    return nil
end

-- =========================================================
-- 3. MODULE NHẢY SERVER SIÊU TỐC (Bản Né Server Full)
-- =========================================================
local function DoiServerSieuToc()
    -- Quét từ server đông nhất xuống để đảm bảo server đó "sống"
    local url = "https://games.roblox.com/v1/games/"..PId.."/servers/Public?sortOrder=Desc&limit=100"
    if trangHienTai ~= "" then url = url .. "&cursor=" .. trangHienTai end
    
    local success, res = pcall(function() return game:HttpGet(url) end)
    if not success then return end 

    local data = HS:JSONDecode(res)
    if data and data.data then
        local danhSachNgon = {} 
        
        for _, srv in pairs(data.data) do
            -- LOGIC MỚI: Chỉ nhảy vào server trống ít nhất 3 slot (maxPlayers - 3)
            -- Điều này giúp né việc 2-3 người cùng nhảy vào 1 lúc gây kẹt cửa
            if type(srv) == "table" and srv.id ~= JId and not ServerDaThu[srv.id] and srv.playing < (srv.maxPlayers - 3) then
                table.insert(danhSachNgon, srv)
            end
        end
        
        if #danhSachNgon > 0 then
            -- BỐC NGẪU NHIÊN: Tuyệt chiêu né đụng hàng với tụi script khác
            local chot = danhSachNgon[math.random(1, #danhSachNgon)]
            
            print(">> [Bơm Ga] Chốt phòng ngẫu nhiên: " .. chot.playing .. "/" .. chot.maxPlayers)
            ServerDaThu[chot.id] = true
            TS:TeleportToPlaceInstance(PId, chot.id, Player)
            task.wait(3) 
        else
            -- Nếu 100 server trang này đều quá đông, tự động lật trang tìm tiếp
            trangHienTai = data.nextPageCursor or ""
            if trangHienTai == "" then ServerDaThu = {} end
            print(">> Toàn phòng đông, đang rà soát trang tiếp theo...")
        end
    end
end

-- =========================================================
-- 4. VÒNG LẶP THỰC THI
-- =========================================================
task.spawn(function()
    print(">> HE THONG BAT DAU...")
    while task.wait(1) do
        local target = QuetRadarBoss()
        if target then
            print(">> Muc tieu: " .. target.Name)
            repeat task.wait(0.5) until not target or not target.Parent or not target:FindFirstChild("Humanoid") or target.Humanoid.Health <= 0
            print(">> Boss bay mau. Dang quet lai...")
        else
            print(">> Trắng tay. Đợi " .. delayHop .. "s rồi nhảy...")
            task.wait(delayHop)
            DoiServerSieuToc()
        end
    end
end)
