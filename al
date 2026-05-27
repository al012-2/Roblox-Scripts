local playerGui = game:GetService("Players").LocalPlayer:WaitForChild("PlayerGui")
local TARGET_TRAITS = { ["Ragnarök"] = true, ["Fortuna's Crown"] = true, ["Empyrean Guard"] = true }

-- دالة فتح الواجهة والضغط التلقائي عن بعد
local function runAutoRoll()
    local traitsGui = playerGui:FindFirstChild("Traits")
    if not traitsGui then return end
    
    -- فتح الواجهة برمجياً ليتمكن السكربت من القراءة
    traitsGui.Enabled = true
    for _, obj in pairs(traitsGui:GetDescendants()) do
        if obj:IsA("Frame") or obj:IsA("ScrollingFrame") then
            if string.find(string.lower(obj.Name), "main") or string.find(string.lower(obj.Name), "auto") then 
                obj.Visible = true 
            end
        end
    end
    
    -- محاكاة الضغط الفعلي على زر الـ Auto Roll باللعبة
    for _, obj in pairs(traitsGui:GetDescendants()) do
        if obj:IsA("TextButton") or obj:IsA("ImageButton") then
            if string.find(string.lower(obj.Name), "auto") or (obj:IsA("TextButton") and string.find(string.lower(obj.Text), "auto")) then
                pcall(function() obj:Activate() end)
                for _, btn in pairs(getconnections(obj.Activated or obj.MouseButton1Click)) do 
                    btn:Fire() 
                end
                break
            end
        end
    end
end

-- تشغيل الـ Auto Roll فوراً عند تشغيل السكربت
runAutoRoll()

-- حلقة المراقبة والحماية السريعة في الخلفية
task.spawn(function()
    while task.wait(0.05) do -- فحص فائق السرعة (50 مللي ثانية) لحماية السمة
        local traitsGui = playerGui:FindFirstChild("Traits")
        if traitsGui then
            traitsGui.Enabled = true
            
            -- البحث عن اسم السمة الحالية وقراءتها
            for _, obj in pairs(traitsGui:GetDescendants()) do
                if obj:IsA("TextLabel") and obj.Text ~= "" and obj.Text ~= "Trait" and not string.find(obj.Text, "Multiplier") then
                    local trait = string.gsub(obj.Text, "^%s*(.-)%s*$", "%1")
                    if #trait > 2 and not string.find(trait, " ") and not string.find(trait, "%%") then
                        
                        -- إذا ظهرت إحدى السمات الأسطورية المطلوبة
                        if TARGET_TRAITS[trait] then
                            runAutoRoll() -- ضغطة الإيقاف الفورية لحمايتها من الضياع
                            print("🎉 [Macro] تم صيد السمة المطلوبة وإيقاف اللف بنجاح: " .. trait)
                            return
                        end
                    end
                end
            end
        end
    end
end)
