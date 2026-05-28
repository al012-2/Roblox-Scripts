local Players = game:GetService("Players")
local CoreGui = game:GetService("CoreGui")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local localPlayer = Players.LocalPlayer
local playerGui = localPlayer:WaitForChild("PlayerGui")

local TARGET_TRAITS = {
    ["Ragnarök"] = true,
    ["Fortuna's Crown"] = true,
    ["Empyrean Guard"] = true,
}

local isMacroRunning = false
local isJumpEnabled = true
local jumpDelay = 0.6
local rollCount = 0
local traitSkipValue = 3 -- القيمة الافتراضية

-- ===== دالة SetTraitSkip =====
local function setTraitSkip(val)
    pcall(function()
        ReplicatedStorage:WaitForChild("Packages")
            :WaitForChild("_Index")
            :WaitForChild("sleitnick_knit@1.7.0")
            :WaitForChild("knit")
            :WaitForChild("Services")
            :WaitForChild("SettingsService")
            :WaitForChild("RF")
            :WaitForChild("SetTraitSkip")
            :InvokeServer(val)
    end)
end

-- ===== دالة القفز =====
local function doJump()
    local character = localPlayer.Character
    if not character then return end
    local humanoid = character:FindFirstChildOfClass("Humanoid")
    if humanoid and humanoid:GetState() ~= Enum.HumanoidStateType.Jumping then
        humanoid.Jump = true
    end
end

local function forceOpenAutoRollUI()
    local traitsGui = playerGui:FindFirstChild("Traits")
    if traitsGui then
        traitsGui.Enabled = true
        for _, obj in pairs(traitsGui:GetDescendants()) do
            if obj:IsA("Frame") or obj:IsA("ScrollingFrame") then
                if string.find(string.lower(obj.Name), "main") or string.find(string.lower(obj.Name), "auto") then
                    obj.Visible = true
                end
            end
        end
    end
end

local function clickAutoRollButton()
    local traitsGui = playerGui:FindFirstChild("Traits")
    if traitsGui then
        for _, obj in pairs(traitsGui:GetDescendants()) do
            if obj:IsA("TextButton") or obj:IsA("ImageButton") then
                if string.find(string.lower(obj.Name), "auto") or (obj:IsA("TextButton") and string.find(string.lower(obj.Text), "auto")) then
                    if guiinteract then
                        guiinteract(obj)
                    else
                        pcall(function() obj:Activate() end)
                        pcall(function()
                            for _, connection in pairs(getconnections(obj.Activated or obj.MouseButton1Click)) do
                                connection:Fire()
                            end
                        end)
                    end
                    return true
                end
            end
        end
    end
    return false
end

local function getCurrentTraitFromUI()
    local traitsGui = playerGui:FindFirstChild("Traits")
    if traitsGui then
        for _, obj in pairs(traitsGui:GetDescendants()) do
            if obj:IsA("TextLabel") and obj.Text ~= "" and obj.Text ~= "Trait" and not string.find(obj.Text, "Multiplier") then
                local text = string.gsub(obj.Text, "^%s*(.-)%s*$", "%1")
                if #text > 2 and not string.find(text, " ") and not string.find(text, "%%") then
                    return text
                end
            end
        end
    end
    return nil
end

-- ===== بناء الواجهة =====
local ScreenGui = Instance.new("ScreenGui")
ScreenGui.Name = "AutoRollPro"
ScreenGui.ResetOnSpawn = false
pcall(function() ScreenGui.Parent = CoreGui end)

local MainFrame = Instance.new("Frame")
MainFrame.Size = UDim2.new(0, 340, 0, 290)
MainFrame.Position = UDim2.new(0.5, -170, 0.4, -145)
MainFrame.BackgroundColor3 = Color3.fromRGB(10, 10, 20)
MainFrame.Active = true
MainFrame.Draggable = true
MainFrame.Parent = ScreenGui
Instance.new("UICorner", MainFrame).CornerRadius = UDim.new(0, 14)

-- العنوان
local Title = Instance.new("TextLabel")
Title.Size = UDim2.new(1, 0, 0, 42)
Title.Text = "⚡ REMOTE AUTO-ROLL v2"
Title.TextColor3 = Color3.fromRGB(255, 255, 255)
Title.Font = Enum.Font.GothamBold
Title.TextSize = 13
Title.BackgroundColor3 = Color3.fromRGB(20, 20, 40)
Title.Parent = MainFrame
Instance.new("UICorner", Title).CornerRadius = UDim.new(0, 14)

-- الحالة
local StatusLabel = Instance.new("TextLabel")
StatusLabel.Size = UDim2.new(0, 300, 0, 32)
StatusLabel.Position = UDim2.new(0, 20, 0, 52)
StatusLabel.Text = "الحالة: جاهز"
StatusLabel.TextColor3 = Color3.fromRGB(200, 200, 220)
StatusLabel.BackgroundColor3 = Color3.fromRGB(16, 16, 30)
StatusLabel.Font = Enum.Font.Gotham
StatusLabel.TextSize = 12
StatusLabel.Parent = MainFrame
Instance.new("UICorner", StatusLabel).CornerRadius = UDim.new(0, 8)

-- عداد اللفات
local RollLabel = Instance.new("TextLabel")
RollLabel.Size = UDim2.new(0, 300, 0, 28)
RollLabel.Position = UDim2.new(0, 20, 0, 90)
RollLabel.Text = "اللفات: 0"
RollLabel.TextColor3 = Color3.fromRGB(100, 220, 255)
RollLabel.BackgroundColor3 = Color3.fromRGB(10, 25, 40)
RollLabel.Font = Enum.Font.GothamBold
RollLabel.TextSize = 12
RollLabel.Parent = MainFrame
Instance.new("UICorner", RollLabel).CornerRadius = UDim.new(0, 8)

-- === قسم TraitSkip ===
local SkipLabel = Instance.new("TextLabel")
SkipLabel.Size = UDim2.new(0, 300, 0, 24)
SkipLabel.Position = UDim2.new(0, 20, 0, 126)
SkipLabel.Text = "TraitSkip: " .. tostring(traitSkipValue)
SkipLabel.TextColor3 = Color3.fromRGB(255, 200, 80)
SkipLabel.BackgroundTransparency = 1
SkipLabel.Font = Enum.Font.GothamBold
SkipLabel.TextSize = 12
SkipLabel.TextXAlignment = Enum.TextXAlignment.Right
SkipLabel.Parent = MainFrame

local SkipFrame = Instance.new("Frame")
SkipFrame.Size = UDim2.new(0, 300, 0, 32)
SkipFrame.Position = UDim2.new(0, 20, 0, 152)
SkipFrame.BackgroundTransparency = 1
SkipFrame.Parent = MainFrame

local skipOptions = {1, 2, 3, 4, 5}
local skipBtns = {}
for i, val in ipairs(skipOptions) do
    local btn = Instance.new("TextButton")
    btn.Size = UDim2.new(0, 52, 0, 30)
    btn.Position = UDim2.new(0, (i-1) * 58, 0, 0)
    btn.Text = tostring(val)
    btn.Font = Enum.Font.GothamBold
    btn.TextSize = 13
    btn.TextColor3 = Color3.fromRGB(255, 255, 255)
    btn.BackgroundColor3 = (val == traitSkipValue) and Color3.fromRGB(180, 120, 0) or Color3.fromRGB(30, 30, 50)
    btn.Parent = SkipFrame
    Instance.new("UICorner", btn).CornerRadius = UDim.new(0, 7)
    table.insert(skipBtns, btn)

    btn.Activated:Connect(function()
        traitSkipValue = val
        SkipLabel.Text = "TraitSkip: " .. tostring(val)
        setTraitSkip(val)
        for _, b in ipairs(skipBtns) do
            b.BackgroundColor3 = Color3.fromRGB(30, 30, 50)
        end
        btn.BackgroundColor3 = Color3.fromRGB(180, 120, 0)
    end)
end

-- زر القفز التلقائي
local JumpBtn = Instance.new("TextButton")
JumpBtn.Size = UDim2.new(0, 300, 0, 34)
JumpBtn.Position = UDim2.new(0, 20, 0, 194)
JumpBtn.Text = "القفز التلقائي: مفعّل ✅"
JumpBtn.TextColor3 = Color3.fromRGB(255, 255, 255)
JumpBtn.BackgroundColor3 = Color3.fromRGB(6, 120, 140)
JumpBtn.Font = Enum.Font.GothamBold
JumpBtn.TextSize = 13
JumpBtn.Parent = MainFrame
Instance.new("UICorner", JumpBtn).CornerRadius = UDim.new(0, 9)

-- زر التشغيل
local ToggleBtn = Instance.new("TextButton")
ToggleBtn.Size = UDim2.new(0, 300, 0, 42)
ToggleBtn.Position = UDim2.new(0, 20, 0, 238)
ToggleBtn.Text = "▶ تشغيل الأوتو رول"
ToggleBtn.TextColor3 = Color3.fromRGB(255, 255, 255)
ToggleBtn.BackgroundColor3 = Color3.fromRGB(0, 140, 75)
ToggleBtn.Font = Enum.Font.GothamBold
ToggleBtn.TextSize = 14
ToggleBtn.Parent = MainFrame
Instance.new("UICorner", ToggleBtn).CornerRadius = UDim.new(0, 10)

-- ===== الأحداث =====
JumpBtn.Activated:Connect(function()
    isJumpEnabled = not isJumpEnabled
    if isJumpEnabled then
        JumpBtn.Text = "القفز التلقائي: مفعّل ✅"
        JumpBtn.BackgroundColor3 = Color3.fromRGB(6, 120, 140)
    else
        JumpBtn.Text = "القفز التلقائي: معطّل ❌"
        JumpBtn.BackgroundColor3 = Color3.fromRGB(80, 80, 100)
    end
end)

local function startMacro()
    if isMacroRunning then return end

    -- تطبيق TraitSkip قبل البدء
    setTraitSkip(traitSkipValue)
    task.wait(0.2)

    forceOpenAutoRollUI()
    task.wait(0.2)

    local clicked = clickAutoRollButton()
    if not clicked then
        StatusLabel.Text = "❌ تعذر إيجاد زر الأوتو رول"
        return
    end

    isMacroRunning = true
    rollCount = 0
    ToggleBtn.Text = "■ إيقاف الماكرو"
    ToggleBtn.BackgroundColor3 = Color3.fromRGB(160, 30, 30)

    task.spawn(function()
        while isMacroRunning do
            forceOpenAutoRollUI()

            if isJumpEnabled then
                doJump()
            end

            local currentTrait = getCurrentTraitFromUI()
            if currentTrait then
                rollCount = rollCount + 1
                RollLabel.Text = "اللفات: " .. tostring(rollCount)
                StatusLabel.Text = "السمة: " .. tostring(currentTrait)

                if TARGET_TRAITS[currentTrait] then
                    StatusLabel.Text = "🎉 اصطياد: " .. tostring(currentTrait)
                    isMacroRunning = false
                    clickAutoRollButton()
                    ToggleBtn.Text = "▶ تشغيل الأوتو رول"
                    ToggleBtn.BackgroundColor3 = Color3.fromRGB(0, 140, 75)
                    break
                end
            end

            task.wait(jumpDelay)
        end
    end)
end

ToggleBtn.Activated:Connect(function()
    if isMacroRunning then
        isMacroRunning = false
        clickAutoRollButton()
        ToggleBtn.Text = "▶ تشغيل الأوتو رول"
        ToggleBtn.BackgroundColor3 = Color3.fromRGB(0, 140, 75)
        StatusLabel.Text = "تم الإيقاف — اللفات: " .. tostring(rollCount)
    else
        startMacro()
    end
end)
