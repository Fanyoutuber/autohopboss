print(">> Giai doan 1: Khoi tao...")
task.wait(3)
local TS, HS = game:GetService("TeleportService"), game:GetService("HttpService")
local Player, PId, JId = game.Players.LocalPlayer, game.PlaceId, game.JobId
local DanhSachBoss, delayHop, ServerDaThu = {"StrongestShinobiBoss", "AizenBoss"}, 3, {}

print(">> Giai doan 2: Nap Radar...")
task.wait(1)
local function QuetRadarBoss()
    local folder = workspace:FindFirstChild("NPCs") or workspace
    for _, ten in pairs(DanhSachBoss) do
        local b = folder:FindFirstChild(ten)
        if b and b:FindFirstChild("Humanoid") and b.Humanoid.Health > 0 then return b end
    end
end

print(">> Giai doan 3: Nap Teleport...")
task.wait(1)
local function DoiServerSieuToc()
    local url = "https://games.roblox.com/v1/games/"..PId.."/servers/Public?sortOrder=Asc&limit=100"
    local success, res = pcall(function() return game:HttpGet(url) end)
    if not success then return print(">> [LỖI API] Bi chan, doi nhip sau...") end
    
    local data = HS:JSONDecode(res)
    if data and data.data then
        local danhSachNgon = {} 
        for _, srv in pairs(data.data) do
            if type(srv) == "table" and srv.id ~= JId and not ServerDaThu[srv.id] and srv.playing >= 3 and srv.playing < (srv.maxPlayers - 2) then
                table.insert(danhSachNgon, srv)
            end
        end
        
        if #danhSachNgon > 0 then
            local chot = danhSachNgon[math.random(1, #danhSachNgon)]
            print(">> Chot phong: " .. chot.playing .. "/" .. chot.maxPlayers)
            ServerDaThu[chot.id] = true
            TS:TeleportToPlaceInstance(PId, chot.id, Player)
            task.wait(5)
        else
            print(">> [CANH BAO] Quet xit. Reset danh sach...")
            ServerDaThu = {} 
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
            repeat task.wait(0.5) until not target or not target.Parent or not target:FindFirstChild("Humanoid") or target.Humanoid.Health <= 0
            print(">> Boss chet, tim tiep...")
        else
            print(">> Map sach. Doi " .. delayHop .. "s roi Hop...")
            task.wait(delayHop)
            DoiServerSieuToc()
        end
    end
end)
