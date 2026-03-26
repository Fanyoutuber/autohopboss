print(">> Giai doan 1: Khoi tao...")
task.wait(3)
local TS, HS = game:GetService("TeleportService"), game:GetService("HttpService")
local Player, PId, JId = game.Players.LocalPlayer, game.PlaceId, game.JobId
local DanhSachBoss, delayHop, ServerDaThu = {"StrongestShinobiBoss", "AizenBoss"}, 3, {}
local cursor = "" -- Thêm biến lật trang

print(">> Giai doan 2: Nap Radar...")
task.wait(2)
local function QuetRadarBoss()
    local folder = workspace:FindFirstChild("NPCs") or workspace
    for _, ten in pairs(DanhSachBoss) do
        local b = folder:FindFirstChild(ten)
        if b and b:FindFirstChild("Humanoid") and b.Humanoid.Health > 0 then return b end
    end
end

print(">> Giai doan 3: Nap Teleport (Ban Ep Xung Lat Trang)...")
task.wait(2)
local function DoiServerSieuToc()
    while true do 
        -- Dùng Desc lấy server sống, lật trang liên tục nếu Full
        local url = "https://games.roblox.com/v1/games/"..PId.."/servers/Public?sortOrder=Desc&limit=100"
        if cursor ~= "" then url = url .. "&cursor=" .. cursor end
        
        local success, res = pcall(function() return game:HttpGet(url) end)
        if not success then return print(">> [LỖI API] Doi nhip sau...") end
        
        local data = HS:JSONDecode(res)
        if data and data.data then
            local danhSachNgon = {} 
            for _, srv in pairs(data.data) do
                -- Chỉ cần trống 3 chỗ là nhét vào danh sách
                if type(srv) == "table" and srv.id ~= JId and not ServerDaThu[srv.id] and srv.playing < (srv.maxPlayers - 2) then
                    table.insert(danhSachNgon, srv)
                end
            end
            
            if #danhSachNgon > 0 then
                local chot = danhSachNgon[math.random(1, #danhSachNgon)]
                print(">> Chot phong: " .. chot.playing .. "/" .. chot.maxPlayers)
                ServerDaThu[chot.id] = true
                TS:TeleportToPlaceInstance(PId, chot.id, Player)
                task.wait(5)
                return -- Nhảy thành công thì thoát vòng lặp lật trang
            else
                -- Lật trang siêu tốc (0.2s) nếu 100 phòng này đều Full
                cursor = data.nextPageCursor or ""
                if cursor == "" then
                    print(">> Quet can game khong thay phong, reset...")
                    ServerDaThu = {} 
                    break -- Văng ra ngoài đợi 10s sau quét lại từ đầu
                end
                print(">> Trang nay Full het, dang lat trang...")
                task.wait(0.2) 
            end
        end
    end
end

print(">> Giai doan 4: Kich hoat Farm!")
task.wait(2)
task.spawn(function()
    while task.wait(1) do
        local target = QuetRadarBoss()
        if target then
            print(">> Muc tieu: " .. target.Name)
            repeat task.wait(1) until not target or not target.Parent or not target:FindFirstChild("Humanoid") or target.Humanoid.Health <= 0
            print(">> Boss chet, tim tiep...")
        else
            print(">> Map sach. Doi " .. delayHop .. "s roi Hop...")
            task.wait(delayHop)
            DoiServerSieuToc()
        end
    end
end)
