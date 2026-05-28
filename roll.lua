local Rayfield = loadstring(game:HttpGet('https://sirius.menu/rayfield'))()

local Window = Rayfield:CreateWindow({
   Name = "⚡ Auto Roll Hub",
   LoadingTitle = "⚡ Auto Roll Hub",
   LoadingSubtitle = "by 1_F0",
   ConfigurationSaving = {
      Enabled = false,
      FolderName = nil,
      FileName = "AutoRollHub"
   },
   Discord = {
      Enabled = false,
      Invite = "noinvitelink",
      RememberJoins = true
   },
   KeySystem = false,
})

-- ===== الإعدادات =====
local Players = game:GetService("Players")
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
local isAutoBuyEnabled = false
local isAutoItemsEnabled = false
local isAutoCrateEnabled = false
local jumpDelay = 0.6
local rollCount = 0
local traitSkipValue = 3

local ITEMS_TO_USE = {
    "RerollTrait", "UltraClover", "FortunesDiamond",
    "MythicLostCrate", "EpicLootCrate", "RadiantShard",
    "DamagePotion", "MultiRollPotion", "DropRatePotion",
    "ReviveSpeedPotion", "RollSpeedPotion", "CoinPotion",
    "LuckPotion", "MovementSpeedPotion",
}

-- ===== دوال مساعدة =====
local RF_BASE = {"Packages","_Index","sleitnick_knit@1.7.0","knit","Services"}

local function invokeRF(path, ...)
    local obj = ReplicatedStorage
    for _, p in ipairs(path) do obj = obj:WaitForChild(p) end
    return obj:InvokeServer(...)
end

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

local function useItem(itemId, amount)
    pcall(invokeRF, {table.unpack(RF_BASE),"ItemService","RF","UseItem"}, itemId, amount or 1)
end

local function useAllItems()
    for _, itemId in ipairs(ITEMS_TO_USE) do
        useItem(itemId, 1)
        task.wait(0.3)
    end
end

local function autoBuyAll()
    pcall(function()
        local Knit = require(ReplicatedStorage.Packages.Knit)
        local ShopService = Knit.GetService("ShopService")
        local ShopConfig = require(ReplicatedStorage.GameInfo.ShopConfig)
        for _, slotDef in ShopConfig.Slots do
            pcall(function()
                ShopService:Purchase(slotDef.ItemId, slotDef.MaxPerPlayer or 1)
            end)
            task.wait(0.3)
        end
    end)
end

local function getQuestService()
    local Knit = require(ReplicatedStorage.Packages.Knit)
    return Knit.GetService("QuestService")
end

local function crazyHeartExchange(exchangeType)
    pcall(function()
        local QuestService = getQuestService()
        QuestService:TurnIn(exchangeType)
    end)
    task.wait(0.5)
    if exchangeType == "CrazyHeartCrateExchange" then
        for i = 1, 10 do
            pcall(invokeRF, {table.unpack(RF_BASE),"ItemService","RF","UseItem"}, "CrazyDiamondCrate", 1)
            task.wait(0.3)
        end
    end
end

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

-- ===== تاب الأوتو رول =====
local RollTab = Window:CreateTab("🎲 Auto Roll", nil)
RollTab:CreateSection("إعدادات الرول")

RollTab:CreateSlider({
    Name = "Trait Skip",
    Range = {1, 5},
    Increment = 1,
    Suffix = "",
    CurrentValue = traitSkipValue,
    Flag = "traitskip",
    Callback = function(Value)
        traitSkipValue = Value
        setTraitSkip(Value)
    end,
})

RollTab:CreateToggle({
    Name = "القفز التلقائي",
    CurrentValue = true,
    Flag = "jumpToggle",
    Callback = function(Value)
        isJumpEnabled = Value
    end,
})

RollTab:CreateButton({
    Name = "▶ تشغيل / إيقاف الأوتو رول",
    Callback = function()
        if isMacroRunning then
            isMacroRunning = false
            clickAutoRollButton()
            Rayfield:Notify({
                Title = "⏹ تم الإيقاف",
                Content = "اللفات: " .. tostring(rollCount),
                Duration = 4,
                Image = 4483362458
            })
        else
            setTraitSkip(traitSkipValue)
            task.wait(0.2)
            forceOpenAutoRollUI()
            task.wait(0.2)

            if not clickAutoRollButton() then
                Rayfield:Notify({
                    Title = "❌ خطأ",
                    Content = "تعذر إيجاد زر الأوتو رول",
                    Duration = 4,
                    Image = 4483362458
                })
                return
            end

            isMacroRunning = true
            rollCount = 0
            Rayfield:Notify({
                Title = "✅ تم التشغيل",
                Content = "الأوتو رول شغال!",
                Duration = 3,
                Image = 4483362458
            })

            task.spawn(function()
                local buyTimer, itemTimer, crateTimer = 0, 0, 0
                while isMacroRunning do
                    forceOpenAutoRollUI()
                    if isJumpEnabled then doJump() end

                    buyTimer   = buyTimer   + jumpDelay
                    itemTimer  = itemTimer  + jumpDelay
                    crateTimer = crateTimer + jumpDelay

                    if isAutoBuyEnabled and buyTimer >= 60 then
                        buyTimer = 0
                        task.spawn(autoBuyAll)
                    end
                    if isAutoItemsEnabled and itemTimer >= 30 then
                        itemTimer = 0
                        task.spawn(useAllItems)
                    end
                    if isAutoCrateEnabled and crateTimer >= 60 then
                        crateTimer = 0
                        task.spawn(function() crazyHeartExchange("CrazyHeartCrateExchange") end)
                    end

                    local currentTrait = getCurrentTraitFromUI()
                    if currentTrait then
                        rollCount = rollCount + 1
                        if TARGET_TRAITS[currentTrait] then
                            isMacroRunning = false
                            clickAutoRollButton()
                            Rayfield:Notify({
                                Title = "🎉 اصطياد!",
                                Content = "حصلت على: " .. tostring(currentTrait) .. "\nاللفات: " .. tostring(rollCount),
                                Duration = 10,
                                Image = 4483362458
                            })
                            break
                        end
                    end
                    task.wait(jumpDelay)
                end
            end)
        end
    end,
})

-- ===== تاب المتجر =====
local ShopTab = Window:CreateTab("🛒 المتجر", nil)
ShopTab:CreateSection("المتجر")

ShopTab:CreateToggle({
    Name = "الشراء التلقائي (كل 60 ثانية)",
    CurrentValue = false,
    Flag = "autobuy",
    Callback = function(Value)
        isAutoBuyEnabled = Value
    end,
})

ShopTab:CreateButton({
    Name = "🛒 شراء المتجر الآن",
    Callback = function()
        Rayfield:Notify({Title="🛒 المتجر", Content="جاري الشراء...", Duration=3, Image=4483362458})
        task.spawn(autoBuyAll)
    end,
})

ShopTab:CreateSection("الأيتمز")

ShopTab:CreateToggle({
    Name = "الأيتمز التلقائية (كل 30 ثانية)",
    CurrentValue = false,
    Flag = "autoitems",
    Callback = function(Value)
        isAutoItemsEnabled = Value
    end,
})

ShopTab:CreateButton({
    Name = "🎒 استخدام كل الأيتمز الآن",
    Callback = function()
        Rayfield:Notify({Title="🎒 الأيتمز", Content="جاري الاستخدام...", Duration=3, Image=4483362458})
        task.spawn(useAllItems)
    end,
})

-- ===== تاب Trade =====
local CrateTab = Window:CreateTab("💎 Trade", nil)
CrateTab:CreateSection("Crazy Heart NPC")

CrateTab:CreateToggle({
    Name = "الكريتس التلقائية (كل 60 ثانية)",
    CurrentValue = false,
    Flag = "autocrate",
    Callback = function(Value)
        isAutoCrateEnabled = Value
    end,
})

CrateTab:CreateButton({
    Name = "💎 بادل 125 → 10 Crates",
    Callback = function()
        Rayfield:Notify({Title="💎 Trade", Content="جاري المبادلة...", Duration=3, Image=4483362458})
        task.spawn(function() crazyHeartExchange("CrazyHeartCrateExchange") end)
    end,
})

CrateTab:CreateButton({
    Name = "👑 بادل 1000 → Crazy Heart Title",
    Callback = function()
        Rayfield:Notify({Title="👑 Title", Content="جاري الحصول على التايتل...", Duration=3, Image=4483362458})
        task.spawn(function() crazyHeartExchange("CrazyHeartTitleExchange") end)
    end,
})

-- ===== تاب Misc =====
local MiscTab = Window:CreateTab("🎲 Misc", nil)
MiscTab:CreateSection("الحركة")

MiscTab:CreateSlider({
    Name = "WalkSpeed",
    Range = {1, 350},
    Increment = 1,
    Suffix = "Speed",
    CurrentValue = 16,
    Flag = "sliderws",
    Callback = function(Value)
        localPlayer.Character.Humanoid.WalkSpeed = Value
    end,
})

MiscTab:CreateSlider({
    Name = "JumpPower",
    Range = {1, 350},
    Increment = 1,
    Suffix = "Power",
    CurrentValue = 16,
    Flag = "sliderjp",
    Callback = function(Value)
        localPlayer.Character.Humanoid.JumpPower = Value
    end,
})

MiscTab:CreateToggle({
    Name = "Infinite Jump",
    CurrentValue = false,
    Flag = "infjump",
    Callback = function(Value)
        _G.infinjump = Value
        if not _G.infinJumpStarted then
            _G.infinJumpStarted = true
            local m = localPlayer:GetMouse()
            m.KeyDown:Connect(function(k)
                if _G.infinjump and k:byte() == 32 then
                    local humanoid = localPlayer.Character:FindFirstChildOfClass("Humanoid")
                    if humanoid then
                        humanoid:ChangeState("Jumping")
                        task.wait()
                        humanoid:ChangeState("Seated")
                    end
                end
            end)
        end
    end,
})

-- ===== إشعار البداية =====
Rayfield:Notify({
    Title = "issacnicc7",
    Content = "تم تحميل السكريبت!",
    Duration = 5,
    Image = 4483362458,
})
