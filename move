-- Random Movement  |  walks around a home point like a real player (anti-AFK / looks human)
-- Obsidian UI, mobile friendly. Re-run to reload.

if getgenv().RandomMoveUnload then pcall(getgenv().RandomMoveUnload) end

local Players = game:GetService("Players")
local RunService = game:GetService("RunService")
local LocalPlayer = Players.LocalPlayer

local repo = "https://raw.githubusercontent.com/deividcomsono/Obsidian/main/"
local Library = loadstring(game:HttpGet(repo .. "Library.lua"))()
local SaveManager = loadstring(game:HttpGet(repo .. "addons/SaveManager.lua"))()
local Options = Library.Options

local S = {
    on = false,
    token = 0,
    radius = 12,        -- studs around the home point
    minWait = 2,        -- seconds between moves
    maxWait = 6,
    jumpChance = 15,    -- % chance to jump on a move
    turnChance = 30,    -- % chance to just turn the camera-less body instead of walking
    home = nil,         -- Vector3
    moves = 0,
}

local function parts()
    local char = LocalPlayer.Character
    local hum = char and char:FindFirstChildOfClass("Humanoid")
    local root = char and char:FindFirstChild("HumanoidRootPart")
    if hum and root and hum.Health > 0 then return char, hum, root end
end

local function setHome()
    local _, _, root = parts()
    if root then S.home = root.Position end
    return S.home
end

-- random point on the ground inside the radius (raycast down so we don't walk off edges)
local rayParams = RaycastParams.new()
rayParams.FilterType = Enum.RaycastFilterType.Exclude
local function randomPoint(char)
    rayParams.FilterDescendantsInstances = { char }
    for _ = 1, 8 do
        local a = math.random() * math.pi * 2
        local r = math.sqrt(math.random()) * S.radius
        local p = S.home + Vector3.new(math.cos(a) * r, 0, math.sin(a) * r)
        local hit = workspace:Raycast(p + Vector3.new(0, 6, 0), Vector3.new(0, -20, 0), rayParams)
        if hit and math.abs(hit.Position.Y - S.home.Y) < 6 then
            return hit.Position
        end
    end
    return nil
end

local function walkTo(hum, root, target, alive)
    hum:MoveTo(target)
    local t0 = os.clock()
    while alive() and os.clock() - t0 < 4 do
        if (Vector3.new(root.Position.X, 0, root.Position.Z) - Vector3.new(target.X, 0, target.Z)).Magnitude < 2 then break end
        task.wait(0.1)
    end
    if alive() then hum:Move(Vector3.zero) end
end

local Status
local function setStatus(t) if Status then Status:SetText(t) end end

local function start()
    S.token += 1
    local my = S.token
    local function alive() return S.on and S.token == my end
    if not S.home then setHome() end
    task.spawn(function()
        while alive() do
            local char, hum, root = parts()
            if char and S.home then
                -- went too far (teleport / new map)? make the current spot the new home
                if (root.Position - S.home).Magnitude > S.radius * 4 then S.home = root.Position end
                if math.random(100) <= S.turnChance then
                    -- small turn in place
                    root.CFrame = root.CFrame * CFrame.Angles(0, math.rad(math.random(-90, 90)), 0)
                else
                    local target = randomPoint(char)
                    if target then
                        if math.random(100) <= S.jumpChance then hum.Jump = true end
                        walkTo(hum, root, target, alive)
                        S.moves += 1
                    end
                end
                setStatus("Moves: " .. S.moves)
            end
            local lo, hi = math.min(S.minWait, S.maxWait), math.max(S.minWait, S.maxWait)
            task.wait(lo + math.random() * (hi - lo))
        end
    end)
end

-- respawn: keep the same home, continue automatically
local charConn = LocalPlayer.CharacterAdded:Connect(function()
    if S.on then task.wait(2) start() end
end)

-- ===== UI =====
local cam = workspace.CurrentCamera
local vp = cam and cam.ViewportSize or Vector2.new(1280, 720)
local Window = Library:CreateWindow({
    Title = "Random Movement",
    Footer = "walks around like a real player",
    Center = true,
    AutoShow = true,
    Resizable = true,
    ShowCustomCursor = false,
    Size = UDim2.fromOffset(math.min(520, vp.X - 24), math.min(330, vp.Y - 24)),
    Font = Enum.Font.Gotham,
    CornerRadius = 10,
    ShowMobileButtons = true,
    SidebarCompacted = true,
})

local Main = Window:AddTab({ Name = "Move", Icon = "footprints", Description = "Random walking around a home point" })
local Settings = Window:AddTab({ Name = "Settings", Icon = "settings", Description = "Config and menu" })

local L = Main:AddLeftGroupbox("Control", "play")
L:AddToggle("RandomMove", {
    Text = "Random Movement",
    Default = false,
    Callback = function(v)
        S.on = v
        if v then
            start()
            -- اخفاء الواجهة اذا اشتغل (ترجعها بالزر الجانبي للجوال او RightShift)
            task.defer(function() pcall(function() Library:Toggle(false) end) end)
        else
            S.token += 1
        end
    end,
})
L:AddButton({
    Text = "Set home here",
    Func = function()
        if setHome() then Library:Notify({ Title = "Random Movement", Description = "Home set to your position", Time = 3 }) end
    end,
})
Status = L:AddLabel("Moves: 0")

local R = Main:AddRightGroupbox("Settings", "sliders-horizontal")
R:AddSlider("RM_Radius", { Text = "Radius (studs)", Default = 12, Min = 3, Max = 50, Rounding = 0, Callback = function(v) S.radius = v end })
R:AddSlider("RM_Min", { Text = "Min wait (s)", Default = 2, Min = 0.5, Max = 30, Rounding = 1, Callback = function(v) S.minWait = v end })
R:AddSlider("RM_Max", { Text = "Max wait (s)", Default = 6, Min = 1, Max = 60, Rounding = 1, Callback = function(v) S.maxWait = v end })
R:AddSlider("RM_Jump", { Text = "Jump chance", Default = 15, Min = 0, Max = 100, Rounding = 0, Suffix = "%", Callback = function(v) S.jumpChance = v end })
R:AddSlider("RM_Turn", { Text = "Turn-only chance", Default = 30, Min = 0, Max = 100, Rounding = 0, Suffix = "%", Callback = function(v) S.turnChance = v end })

local Menu = Settings:AddLeftGroupbox("Menu", "menu")
Menu:AddLabel("Menu bind"):AddKeyPicker("MenuKeybind", { Default = "RightShift", NoUI = true, Text = "Menu keybind" })
Library.ToggleKeybind = Options.MenuKeybind
Menu:AddButton({ Text = "Unload", Func = function() Library:Unload() end })

SaveManager:SetLibrary(Library)
SaveManager:SetIgnoreIndexes({ "MenuKeybind" })
SaveManager:SetFolder("RandomMovement")
SaveManager:BuildConfigSection(Settings)
pcall(function() SaveManager:LoadAutoloadConfig() end)

Library:OnUnload(function()
    S.on = false
    S.token += 1
    pcall(function() charConn:Disconnect() end)
    local _, hum = parts()
    if hum then pcall(function() hum:Move(Vector3.zero) end) end
    getgenv().RandomMoveUnload = nil
end)
getgenv().RandomMoveUnload = function() pcall(function() Library:Unload() end) end

Library:Notify({ Title = "Random Movement", Description = "Loaded", Time = 3 })
