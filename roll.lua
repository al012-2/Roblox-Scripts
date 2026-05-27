local Players = game:GetService("Players")
local CoreGui = game:GetService("CoreGui")
local localPlayer = Players.LocalPlayer
local playerGui = localPlayer:WaitForChild("PlayerGui")

-- السمات النادرة جداً للتوقف التلقائي
local TARGET_TRAITS = {
    ["Ragnarök"] = true,
    ["Fortuna's Crown"] = true,
    ["Empyrean Guard"] = true,
}

local isMacroRunning = false

-- [جديد]: دالة تفتح واجهة الـ Traits والـ Auto Roll برمجياً من بعيد
local function forceOpenAutoRollUI()
    local traitsGui = playerGui:FindFirstChild("Traits")
    if traitsGui then
        -- جعل القائمة الرئيسية مرئية
        traitsGui.Enabled = true
        for _, obj in pairs(traitsGui:GetDescendants()) do
            if obj:IsA("Frame") or obj:IsA("ScrollingFrame") then
                -- إذا كانت الواجهة مخفية أو تحتاج تفعيل
                if string.find(string.lower(obj.Name), "main") or string.find(string.lower(obj.Name), "auto") then
                    obj.Visible = true
                end
            end
        end
    end
end

-- دالة الضغط التلقائي المستقر
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

-- دالة مراقبة السمة الحالية من الـ UI
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

-- === بناء الواجهة (GUI) ===
local ScreenGui = Instance.new("ScreenGui")
ScreenGui.Name = "InfiniteRemoteAutoRoll"
ScreenGui.ResetOnSpawn = false
pcall(function() ScreenGui.Parent = CoreGui end)

local MainFrame = Instance.new("Frame")
MainFrame.Size = UDim2.new(0, 320, 0, 180)
MainFrame.Position = UDim2.new(0.5, -160, 0.4, -90)
MainFrame.BackgroundColor3 = Color3.fromRGB(25, 25, 35)
MainFrame.Active = true
MainFrame.Draggable = true
MainFrame.Parent = ScreenGui

local UICorner = Instance.new("UICorner")
UICorner.CornerRadius = UDim.new(0, 12)
UICorner.Parent = MainFrame

local Title = Instance.new("TextLabel")
Title.Size = UDim2.new(1, 0, 0, 45)
Title.Text = "REMOTE AUTO-ROLL UNLOCKED ⚡"
Title.TextColor3 = Color3.fromRGB(255, 255, 255)
Title.Font = Enum.Font.GothamBold
Title.TextSize = 14
Title.BackgroundColor3 = Color3.fromRGB(35, 35, 48)
Title.Parent = MainFrame

local StatusLabel = Instance.new("TextLabel")
StatusLabel.Size = UDim2.new(0, 280, 0, 35)
StatusLabel.Position = UDim2.new(0, 20, 0, 65)
StatusLabel.Text = "الحالة: جاهز للفتح والتشغيل"
StatusLabel.TextColor3 = Color3.fromRGB(200, 200, 200)
StatusLabel.BackgroundColor3 = Color3.fromRGB(30, 30, 40)
StatusLabel.Font = Enum.Font.Gotham
StatusLabel.TextSize = 13
StatusLabel.Parent = MainFrame

local ToggleBtn = Instance.new("TextButton")
ToggleBtn.Size = UDim2.new(0, 280, 0, 45)
ToggleBtn.Position = UDim2.new(0, 20, 0, 115)
ToggleBtn.Text = "تشغيل الأوتو رول عن بُعد 🟢"
ToggleBtn.TextColor3 = Color3.fromRGB(255, 255, 255)
ToggleBtn.BackgroundColor3 = Color3.fromRGB(0, 150, 80)
ToggleBtn.Font = Enum.Font.GothamBold
ToggleBtn.TextSize = 14
ToggleBtn.Parent = MainFrame

local function startMacro()
    if isMacroRunning then return end
    
    -- خطوة أولى: إجبار اللعبة على فتح واجهة الأوتو رول خفياً
    forceOpenAutoRollUI()
    task.wait(0.2)
    
    -- خطوة ثانية: الضغط على الزر
    local clicked = clickAutoRollButton()
    if not clicked then
        StatusLabel.Text = "❌ تعذر العثور على زر الأوتو رول"
        return
    end

    isMacroRunning = true
    ToggleBtn.Text = "إيقاف الماكرو 🛑"
    ToggleBtn.BackgroundColor3 = Color3.fromRGB(170, 30, 30)
    
    task.spawn(function()
        while isMacroRunning do
            -- التأكد المستمر من بقاء الواجهة مفتوحة في الخلفية ليقرأ منها السكربت
            forceOpenAutoRollUI()
            
            local currentTrait = getCurrentTraitFromUI()
            if currentTrait then
                StatusLabel.Text = "السمة الحالية المراقبة: " .. tostring(currentTrait)
                
                if TARGET_TRAITS[currentTrait] then
                    StatusLabel.Text = "🎉 تم اصطياد السمة بنجاح: " .. tostring(currentTrait)
                    isMacroRunning = false
                    clickAutoRollButton() -- ضغطة الإيقاف للحماية
                    ToggleBtn.Text = "تشغيل الأوتو رول عن بُعد 🟢"
                    ToggleBtn.BackgroundColor3 = Color3.fromRGB(0, 150, 80)
                    break
                end
            end
            task.wait(0.1)
        end
    end)
end

ToggleBtn.Activated:Connect(function()
    if isMacroRunning then
        isMacroRunning = false
        clickAutoRollButton()
        ToggleBtn.Text = "تشغيل الأوتو رول عن بُعد 🟢"
        ToggleBtn.BackgroundColor3 = Color3.fromRGB(0, 150, 80)
        StatusLabel.Text = "الحالة: تم الإيقاف"
    else
        startMacro()
    end
end)
