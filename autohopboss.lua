-- Hứng config từ bên ngoài, nếu không có thì gán mặc định để chống lỗi
local Cfg = getgenv().Tai_Config or {
    DanhSachBoss = {"StrongestShinobiBoss"},
    ThoiGianChoHop = 3
}

print(">> Giai doan 1: Khoi tao...")
task.wait(12)
local TS, HS = game:GetService("TeleportService"), game:GetService("HttpService")
local Player, PId, JId = game.Players.LocalPlayer, game.PlaceId, game.JobId
local ServerDaThu = {}
local cursor = "" 

print(">> Giai doan 2: Nap Radar...")
task.wait(1)
local function QuetRadarBoss()
    local folder = workspace:FindFirstChild("NPCs") or workspace
    for _, ten in pairs(Cfg.DanhSachBoss) do -- Đã đổi sang đọc từ Cfg
        local b = folder:FindFirstChild(ten)
        if b and b:FindFirstChild("Humanoid") and b.Humanoid.Health > 0 then return b end
    end
end

print(">> Giai doan 3: Nap Teleport (Ban Ep Xung Lat Trang)...")
task.wait(1)
local function DoiServerSieuToc()
    while true do 
        local url = "https://games.roblox.com/v1/games/"..PId.."/servers/Public?sortOrder=Asc&limit=100"
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
                TS:TeleportToPlaceInstance(PId, chot.id, Player)
                task.wait(5)
                return 
            else
                cursor = data.nextPageCursor or ""
                if cursor == "" then
                    print(">> Quet can game khong thay phong, reset...")
                    ServerDaThu = {} 
                    break 
                end
                print(">> Trang nay Full het, dang lat trang...")
                task.wait(0.5) 
            end
        end
    end
end

print(">> Giai doan 4: Kich hoat Farm!")
task.wait(1)
task.spawn(function()
    while task.wait(1) do
        local target = QuetRadarBoss()
        if target then
            print(">> Muc tieu: " .. target.Name)
            repeat task.wait(1) until not target or not target.Parent or not target:FindFirstChild("Humanoid") or target.Humanoid.Health <= 0
            print(">> Boss chet, tim tiep...")
        else
            -- Đã đổi delayHop thành Cfg.ThoiGianChoHop
            print(">> Map sach. Doi " .. Cfg.ThoiGianChoHop .. "s roi Hop...")
            task.wait(Cfg.ThoiGianChoHop)
            DoiServerSieuToc()
        end
    end
end)
