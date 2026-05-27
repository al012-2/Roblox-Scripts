local Players = game:GetService("Players")
local CoreGui = game:GetService("CoreGui")
local playerGui = Players.LocalPlayer:WaitForChild("PlayerGui")

local TARGET_TRAITS = { ["Ragnarök"] = true, ["Fortuna's Crown"] = true, ["Empyrean Guard"] = true }
local isMacroRunning = false

-- دالة التحكم في الواجهات (فتح القوائم خفياً)
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

-- دالة الضغط على زر الأوتو رول
local function clickAutoRollButton()
    local traitsGui = playerGui:FindFirstChild("Traits")
    if traitsGui then
        for _, obj in pairs(traitsGui:GetDescendants()) do
            if obj:IsA("TextButton") or obj:IsA("ImageButton") then
                if string.find(string.lower(obj.Name), "auto") or (obj:IsA("TextButton") and string.find(string.lower(obj.Text), "auto")) then
                    pcall(function() obj:Activate() end)
                    for _, conn in pairs(getconnections(obj.Activated or obj.MouseButton1Click)) do conn:Fire() end
                    return true
                end
            end
        end
    end
    return false
end

-- دالة قراءة السمة الحالية
local function getCurrentTraitFromUI()
    local traitsGui = playerGui:FindFirstChild("Traits")
    if traitsGui then
        for _, obj in pairs(traitsGui:GetDescendants()) do
            if obj:IsA("TextLabel") and obj.Text ~= "" and obj.Text ~= "Trait" and not string.find(obj.Text, "Multiplier") then
                local text = string.gsub(obj.Text, "^%s*(.-)%s*$", "%1")
                if #text > 2 and not string.find(text, " ") and not string.find(text, "%%") then return text end
            end
        end
    end
    return nil
end

-- تشغيل المراقبة التلقائية
forceOpenAutoRollUI()
task.wait(0.5)
if clickAutoRollButton() then
    isMacroRunning = true
    task.spawn(function()
        while isMacroRunning do
            forceOpenAutoRollUI()
            local trait = getCurrentTraitFromUI()
            if trait and TARGET_TRAITS[trait] then
                clickAutoRollButton()
                print("🎉 تم صيد السمة المطلوبة: " .. trait)
                isMacroRunning = false
            end
            task.wait(0.05)
        end
    end)
end
