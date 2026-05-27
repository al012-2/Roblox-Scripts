local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Players = game:GetService("Players")
local localPlayer = Players.LocalPlayer
local playerGui = localPlayer:WaitForChild("PlayerGui")

-- السمات الأسطورية النادرة المطلوبة (التوقف عندها تلقائياً لحمايتها)
local TARGET_TRAITS = { 
    ["Ragnarök"] = true, 
    ["Fortuna's Crown"] = true, 
    ["Empyrean Guard"] = true 
}

-- [تفعيل خفي]: تشغيل زر تخطي الأنميشن لتسريع اللف لأقصى درجة
local function enableSkipAnim()
    local traitsGui = playerGui:FindFirstChild("Traits")
    if traitsGui then
        for _, obj in pairs(traitsGui:GetDescendants()) do
            if obj:IsA("TextButton") or obj:IsA("ImageButton") then
                if string.find(string.lower(obj.Name), "skip") or (obj:IsA("TextButton") and string.find(string.lower(obj.Text), "skip")) then
                    pcall(function() obj:Activate() end)
                    for _, connection in pairs(getconnections(obj.Activated or obj.MouseButton1Click)) do
                        connection:Fire()
                    end
                end
            end
        end
    end
end

-- دالة التحكم في تشغيل وإيقاف الـ Auto Roll بالضغط على الزر الفعلي للعبة
local function toggleAutoRoll()
    local traitsGui = playerGui:FindFirstChild("Traits")
    if not traitsGui then return end
    
    -- إجبار واجهة اللعبة على البقاء مفتوحة في الخلفية ليقرأ منها الماكرو
    traitsGui.Enabled = true
    
    -- البحث عن الزر الحقيقي وضغطه برمجياً بمحاكاة النقرة الأصلية
    for _, obj in pairs(traitsGui:GetDescendants()) do
        if obj:IsA("TextButton") or obj:IsA("ImageButton") then
            local nameLower = string.lower(obj.Name)
            local textLower = obj:IsA("TextButton") and string.lower(obj.Text) or ""
            if string.find(nameLower, "auto") or string.find(textLower, "auto") then
                pcall(function() obj:Activate() end)
                for _, connection in pairs(getconnections(obj.Activated or obj.MouseButton1Click)) do
                    connection:Fire()
                end
                break
            end
        end
    end
end

-- بدء تفعيل الإعدادات وتشغيل اللف فوراً عند تشغيل السكربت
enableSkipAnim()
task.wait(0.1)
toggleAutoRoll()

-- حلقة المراقبة الصامتة والحماية فائقة السرعة (كل 50 مللي ثانية)
task.spawn(function()
    while task.wait(0.05) do
        local traitsGui = playerGui:FindFirstChild("Traits")
        if traitsGui then
            traitsGui.Enabled = true
            
            -- قراءة اسم السمة المحدثة على واجهة اللعبة
            for _, obj in pairs(traitsGui:GetDescendants()) do
                if obj:IsA("TextLabel") and obj.Text ~= "" and obj.Text ~= "Trait" and not string.find(obj.Text, "Multiplier") then
                    local trait = string.gsub(obj.Text, "^%s*(.-)%s*$", "%1")
                    
                    if #trait > 2 and not string.find(trait, " ") and not string.find(trait, "%%") then
                        -- عند العثور على سمة أسطورية، يتم إرسال ضغطة إيقاف فورية لحمايتها من الضياع
                        if TARGET_TRAITS[trait] then
                            toggleAutoRoll() -- ضغطة الإلغاء الفورية لحفظ السمة
                            print("🎉 [Success] تم اصطياد السمة وإيقاف الماكرو بنجاح: " .. trait)
                            return
                        end
                    end
                end
            end
        end
    end
end)
