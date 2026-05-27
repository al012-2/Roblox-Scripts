-- كود Auto-Roll Pro المدمج
local Players = game:GetService("Players")
local CoreGui = game:GetService("CoreGui")
local playerGui = Players.LocalPlayer:WaitForChild("PlayerGui")
local TARGET_TRAITS = { ["Ragnarök"] = true, ["Fortuna's Crown"] = true, ["Empyrean Guard"] = true }
local isMacroRunning = false

-- بناء الواجهة
local ScreenGui = Instance.new("ScreenGui", CoreGui)
ScreenGui.Name = "AutoRollPro"
local MainFrame = Instance.new("Frame", ScreenGui)
MainFrame.Size = UDim2.new(0, 280, 0, 160)
MainFrame.Position = UDim2.new(0.5, -140, 0.4, -80)
MainFrame.BackgroundColor3 = Color3.fromRGB(15, 15, 20)
MainFrame.Active = true
MainFrame.Draggable = true
Instance.new("UICorner", MainFrame).CornerRadius = UDim.new(0, 12)

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
StatusLabel.Parent = MainFrame

local ToggleBtn = Instance.new("TextButton", MainFrame)
ToggleBtn.Size = UDim2.new(0, 240, 0, 40)
ToggleBtn.Position = UDim2.new(0, 20, 0, 100)
ToggleBtn.Text = "START ROLLING 🟢"
ToggleBtn.BackgroundColor3 = Color3.fromRGB(40, 180, 100)
ToggleBtn.Parent = MainFrame

-- وظائف الماكرو
ToggleBtn.Activated:Connect(function()
    isMacroRunning = not isMacroRunning
    ToggleBtn.Text = isMacroRunning and "STOP ROLLING 🛑" or "START ROLLING 🟢"
    ToggleBtn.BackgroundColor3 = isMacroRunning and Color3.fromRGB(180, 40, 40) or Color3.fromRGB(40, 180, 100)
    
    if isMacroRunning then
        task.spawn(function()
            while isMacroRunning do
                local traitsGui = playerGui:FindFirstChild("Traits")
                if traitsGui then
                    traitsGui.Enabled = true
                    for _, obj in pairs(traitsGui:GetDescendants()) do
                        if (obj:IsA("TextButton") or obj:IsA("ImageButton")) and string.find(string.lower(obj.Name), "auto") then
                            pcall(function() obj:Activate() end)
                        end
                        if obj:IsA("TextLabel") and TARGET_TRAITS[obj.Text] then
                            isMacroRunning = false
                        end
                    end
                end
                task.wait(0.1)
            end
        end)
    end
end)
