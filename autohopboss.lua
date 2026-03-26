-- =========================================================
-- GIAI ĐOẠN 1: KHỞI TẠO BIẾN (Đợi 3s để ổn định session)
-- =========================================================
print(">> Giai doan 1: Dang khoi tao he thong... doi 3s")
task.wait(3)

local TS = game:GetService("TeleportService")
local HS = game:GetService("HttpService")
local Player = game.Players.LocalPlayer
local PId, JId = game.PlaceId, game.JobId

-- CONFIG
local DanhSachBoss = {"StrongestShinobiBoss", "AizenBoss"}
local delayHop = 2 -- Tang len 15s de chac chan session cu da dong
local ServerDaThu = {}

-- =========================================================
-- GIAI ĐOẠN 2: THIẾT LẬP RADAR (Đợi thêm 2s)
-- =========================================================
task.wait(2)
print(">> Giai doan 2: Dang nap Module Radar...")

local function QuetRadarBoss()
    local folder = workspace:FindFirstChild("NPCs") or workspace
    for _, ten in pairs(DanhSachBoss) do
        local b = folder:FindFirstChild(ten)
        if b and b:FindFirstChild("Humanoid") and b.Humanoid.Health > 0 then return b end
    end
    return nil
end

-- =========================================================
-- GIAI ĐOẠN 3: THIẾT LẬP SERVER HOP (Đợi thêm 2s)
-- =========================================================
task.wait(2)
print(">> Giai doan 3: Dang nap Module Teleport...")

local function DoiServerSieuToc()
    local url = "https://games.roblox.com/v1/games/"..PId.."/servers/Public?sortOrder=Desc&limit=100"
    local success, res = pcall(function() return game:HttpGet(url) end)
    if not success then return end 

    local data = HS:JSONDecode(res)
    if data and data.data then
        local danhSachNgon = {} 
        for _, srv in pairs(data.data) do
            if type(srv) == "table" and srv.id ~= JId and not ServerDaThu[srv.id] and srv.playing < (srv.maxPlayers - 3) then
                table.insert(danhSachNgon, srv)
            end
        end
        
        if #danhSachNgon > 0 then
            local chot = danhSachNgon[math.random(1, #danhSachNgon)]
            print(">> [Bơm Ga] Chốt phong: " .. chot.playing .. "/" .. chot.maxPlayers)
            ServerDaThu[chot.id] = true
            TS:TeleportToPlaceInstance(PId, chot.id, Player)
            task.wait(5) -- Doi lenh teleport on dinh
        else
            ServerDaThu = {} 
        end
    end
end

-- =========================================================
-- GIAI ĐOẠN 4: KÍCH HOẠT VÒNG LẶP (Chốt hạ)
-- =========================================================
task.wait(2)
print(">> Giai doan cuoi: Kich hoat vong lap farm!")

task.spawn(function()
    while true do
        task.wait(1) 
        local target = QuetRadarBoss()
        if target then
            print(">> Muc tieu: " .. target.Name)
            repeat task.wait(0.5) until not target or not target.Parent or not target:FindFirstChild("Humanoid") or target.Humanoid.Health <= 0
            print(">> Boss chet. Dang tim muc tieu tiep theo...")
        else
            print(">> Map sach. Doi " .. delayHop .. "s roi Hop...")
            task.wait(delayHop)
            DoiServerSieuToc()
        end
    end
end)
