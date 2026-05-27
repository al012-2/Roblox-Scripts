local Players = game:GetService("Players")
local CoreGui = game:GetService("CoreGui")
local playerGui = Players.LocalPlayer:WaitForChild("PlayerGui")

local TARGET_TRAITS = { ["Ragnarök"] = true, ["Fortuna's Crown"] = true, ["Empyrean Guard"] = true }
local isMacroRunning = false

-- === 1. تصميم الواجهة الاحترافية (GUI) ===
local ScreenGui = Instance.new("ScreenGui", CoreGui)
ScreenGui.Name = "AutoRollPro"
ScreenGui.ResetOnSpawn = false

local MainFrame = Instance.new("Frame", ScreenGui)
MainFrame.Size = UDim2.new(0, 280, 0, 160)
MainFrame.Position = UDim2.new(0.5, -140, 0.4, -80)
MainFrame.BackgroundColor3 = Color3.fromRGB(15, 15, 20)
MainFrame.BorderSizePixel = 0
MainFrame.Active = true
MainFrame.Draggable = true

Instance.new("UICorner", MainFrame).CornerRadius = UDim.new(0, 12)
Instance.new("UIGradient", MainFrame).Color = ColorSequence.new(Color3.fromRGB(30, 30, 40), Color3.fromRGB(15, 15, 20))

local Title = Instance.new("TextLabel", MainFrame)
Title.Size = UDim2.new(1, 0, 0, 40)
Title.Text = "AUTO-ROLL PRO ⚡"
Title.TextColor3 = Color3.fromRGB(255, 255, 255)
Title.Font = Enum.Font.GothamBold
Title.TextSize = 16
Title.BackgroundTransparency = 1

local StatusLabel = Instance.new("TextLabel", MainFrame)
StatusLabel.Size = UDim2.new(0, 240, 0, 30)
StatusLabel.Position = UDim2.new(0, 20, 0, 50)
StatusLabel.Text = "Status: Ready"
StatusLabel.TextColor3 = Color3.fromRGB(200, 200, 200)
StatusLabel.BackgroundColor3 = Color3.fromRGB(25, 25, 35)
StatusLabel.Font = Enum.Font.Gotham
StatusLabel.TextSize = 12
Instance.new("UICorner", StatusLabel).CornerRadius = UDim.new(0, 6)

local ToggleBtn = Instance.new("TextButton", MainFrame)
ToggleBtn.Size = UDim2.new(0, 240, 0, 40)
ToggleBtn.Position = UDim2.new(0, 20, 0, 100)
ToggleBtn.Text = "START ROLLING 🟢"
ToggleBtn.BackgroundColor3 = Color3.fromRGB(40, 180, 100)
ToggleBtn.TextColor3 = Color3.fromRGB(255, 255, 255)
ToggleBtn.Font = Enum.Font.GothamBold
Instance.new("UICorner", ToggleBtn).CornerRadius = UDim.new(0, 8)

-- === 2. وظائف الماكرو ===
local function forceOpenAutoRollUI()
    local traitsGui = playerGui:FindFirstChild("Traits")
    if traitsGui then
        traitsGui.Enabled = true
        for _, obj in pairs(traitsGui:GetDescendants()) do
            if (obj:IsA("Frame") or obj:IsA("ScrollingFrame")) and (string.find(string.lower(obj.Name), "main") or string.find(string.lower(obj.Name), "auto")) then
                obj.Visible = true
            end
        end
    end
end

local function clickAutoRollButton()
    local traitsGui = playerGui:FindFirstChild("Traits")
    if traitsGui then
        for _, obj in pairs(traitsGui:GetDescendants()) do
            if (obj:IsA("TextButton") or obj:IsA("ImageButton")) and (string.find(string.lower(obj.Name), "auto") or string.find(string.lower(obj.Text or ""), "auto")) then
                pcall(function() obj:Activate() end)
                for _, conn in pairs(getconnections(obj.Activated or obj.MouseButton1Click)) do conn:Fire() end
                return true
            end
        end
    end
    return false
end

-- === 3. منطق التشغيل ===
ToggleBtn.Activated:Connect(function()
    isMacroRunning = not isMacroRunning
    if isMacroRunning then
        ToggleBtn.Text = "STOP ROLLING 🛑"
        ToggleBtn.BackgroundColor3 = Color3.fromRGB(180, 40, 40)
        StatusLabel.Text = "Status: Running..."
        
        task.spawn(function()
            while isMacroRunning do
                forceOpenAutoRollUI()
                local trait = nil
                -- قراءة السمة من الشاشة
                for _, obj in pairs(playerGui:FindFirstChild("Traits"):GetDescendants()) do
                    if obj:IsA("TextLabel") and obj.Text ~= "" and obj.Text ~= "Trait" and not string.find(obj.Text, "Multiplier") then
                        local text = string.gsub(obj.Text, "^%s*(.-)%s*$", "%1")
                        if #text > 2 and not string.find(text, " ") and not string.find(text, "%%") then trait = text break end
                    end
                end
                
                if trait and TARGET_TRAITS[trait] then
                    clickAutoRollButton()
                    StatusLabel.Text = "FOUND: " .. trait
                    isMacroRunning = false
                    ToggleBtn.Text = "START ROLLING 🟢"
                    ToggleBtn.BackgroundColor3 = Color3.fromRGB(40, 180, 100)
                end
                task.wait(0.1)
            end
        end)
    else
        ToggleBtn.Text = "START ROLLING 🟢"
        ToggleBtn.BackgroundColor3 = Color3.fromRGB(40, 180, 100)
        StatusLabel.Text = "Status: Stopped"
    end
end)
