local TeleportService = game:GetService("TeleportService")
local HttpService = game:GetService("HttpService")

-- CONFIG
local BossList = {"StrongestShinobiBoss", "AizenBoss"}
local hopDelay = 2 -- Đã nâng lên 5s để né lỗi spam API của Roblox
local blacklistedServers = {}
local pageCursor = ""

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

-- SERVER HOPPER
local function Hop()
    local url = "https://games.roblox.com/v1/games/"..game.PlaceId.."/servers/Public?sortOrder=Asc&limit=100"
    if pageCursor ~= "" then url ..= "&cursor="..pageCursor end
    
    local s, res = pcall(function() return game:HttpGet(url) end)
    if not s then return end
    
    local data = HttpService:JSONDecode(res)
    if data and data.data then
        for _, srv in pairs(data.data) do
            if srv.id ~= game.JobId and not blacklistedServers[srv.id] and srv.playing >= 3 and srv.playing < 8 then
                print(">> Sang Server: "..srv.playing.." người")
                blacklistedServers[srv.id] = true
                TeleportService:TeleportToPlaceInstance(game.PlaceId, srv.id, game.Players.LocalPlayer)
                task.wait(10)
                return
            end
        end
        pageCursor = data.nextPageCursor or ""
    end
end

-- MAIN LOOP
task.spawn(function()
    print(">> HE THONG BAT DAU...")
    while task.wait(1) do
        local target = GetBoss()
        if target then
            print(">> Muc tieu: "..target.Name)
            repeat task.wait(0.5) until not target or not target.Parent or not target:FindFirstChild("Humanoid") or target.Humanoid.Health <= 0
            print(">> Boss chet, dang quet lai...")
        else
            print(">> Khong co boss, dang hop sau "..hopDelay.."s")
            task.wait(hopDelay)
            Hop()
        end
    end
end)
