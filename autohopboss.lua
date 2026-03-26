local TS = game:GetService("TeleportService")
local HS = game:GetService("HttpService")
local PId, JId = game.PlaceId, game.JobId
local Player = game.Players.LocalPlayer

-- CONFIG
local BossList = {"StrongestShinobiBoss", "AizenBoss"}
local delayHop = 5 -- Mức an toàn chống ban

-- VARIABLES
local ServerDaThu = {}
local trangHienTai = ""

-- RADAR
local function GetBoss()
    local folder = workspace:FindFirstChild("NPCs") or workspace
    for _, name in pairs(BossList) do
        local b = folder:FindFirstChild(name)
        if b and b:FindFirstChild("Humanoid") and b.Humanoid.Health > 0 then
            return b
        end
    end
end

-- SERVER HOP
local function DoiServer()
    local url = "https://games.roblox.com/v1/games/"..PId.."/servers/Public?sortOrder=Asc&limit=100"
    if trangHienTai ~= "" then url = url.."&cursor="..trangHienTai end
    
    local success, res = pcall(function() return game:HttpGet(url) end)
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
        -- Hết trang hoặc cạn list
        trangHienTai = data.nextPageCursor or ""
        if trangHienTai == "" then ServerDaThu = {} end 
    end
end

-- MAIN LOOP
task.spawn(function()
    print(">> KÍCH HOẠT HỆ THỐNG AUTO BOSS HOP...")
    while task.wait(1) do
        local boss = GetBoss()
        
        if boss then
            print(">> [BÁO ĐỘNG] Bắt được: " .. boss.Name .. " - KHÓA MỤC TIÊU!")
            repeat 
                task.wait(0.5) 
                -- Chỗ nhét hàm Bay và hàm Đánh (RemoteEvent)
            until not boss or not boss.Parent or not boss:FindFirstChild("Humanoid") or boss.Humanoid.Health <= 0
            
            print(">> Boss bay màu. Khởi động lại Radar...")
        else
            print(">> Trắng tay. Đợi " .. delayHop .. "s rồi té...")
            task.wait(delayHop)
            DoiServer()
        end
    end
end)
