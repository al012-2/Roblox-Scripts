-- تنظيف أي نسخة سابقة أولاً
if getgenv().TitanLoaded then
    pcall(getgenv().TitanLoaded)
end

local Rayfield = loadstring(game:HttpGet('https://sirius.menu/rayfield'))()

local Window = Rayfield:CreateWindow({
   Name = "Titan RNG - Hub V30 (Auto Boss Replicator)",
   LoadingTitle = "جاري تحميل محاكي الجيم باس ونظام الفارم...",
   ConfigurationSaving = { Enabled = true, FolderName = "TitanRNG_Smart", FileName = "Config" }
})

local Players = game:GetService("Players")
local Rep = game:GetService("ReplicatedStorage")
local player = Players.LocalPlayer

-- ==================== الحالة العامة ====================
local activeConnections = {}
local ActiveMode = nil
local ActiveWorldKey = nil
local FarmToken = 0
local customBossToken = 0
local fastBattleToken = 0
local autoQuestToken = 0
local autoClaimToken = 0
local DisableBattleAnimation = false
local WaitForBattle = false
local LadderMode = true
local SelectedDifficulty = "Normal"
local MaxDifficulty = "Nightmare"
local DiffList = {"Normal", "Hard", "Extreme", "Nightmare"}
local ModeToggles = {}
local isSwitchingMode = false
local WorldOrder = {"1", "2", "3", "4", "5", "raid"}
local SelectedCustomBosses = {}

getgenv().TitanLoaded = function()
    ActiveMode = nil
    ActiveWorldKey = nil
    FarmToken += 1
    customBossToken += 1
    fastBattleToken += 1
    autoQuestToken += 1
    autoClaimToken += 1
    DisableBattleAnimation = false
    for _, conn in ipairs(activeConnections) do
        pcall(function() conn:Disconnect() end)
    end
    pcall(function() Rayfield:Destroy() end)
    getgenv().TitanLoaded = nil
end

-- ==================== فحص وجلب الريموتات ====================
local function safeWaitForChild(parent, name, timeout)
    local obj = parent:FindFirstChild(name) or parent:WaitForChild(name, timeout or 5)
    if not obj then
        warn("[Titan Hub] تعذر العثور على الريموت: " .. tostring(name))
    end
    return obj
end

local challengeRemote = safeWaitForChild(Rep, "challengeBoss", 5)
local teleportAreaRemote = safeWaitForChild(Rep, "teleportToArea", 5)
local battleEvent = safeWaitForChild(Rep, "battleEvent", 5)
local bossResultRemote = safeWaitForChild(Rep, "bossResult", 5)
local autoRollRemote = safeWaitForChild(Rep, "toggleAutoRoll", 5)
local quickRollRemote = safeWaitForChild(Rep, "toggleQuickRoll", 5)
local equipBestRemote = safeWaitForChild(Rep, "equipBest", 5)
local claimDailyRemote = safeWaitForChild(Rep, "claimDaily", 5)
local claimQuestRemote = safeWaitForChild(Rep, "claimQuest", 5)
local runInfTowerRemote = safeWaitForChild(Rep, "runInfTower", 5)
local sendUIRemote = safeWaitForChild(Rep, "sendUI", 5)

-- ==================== بيانات البوسات والعوالم ====================
local BossHierarchy = {
   ["1"] = {"cart_titan", "armored_titan", "beast_titan", "warhammer_titan", "colossal_titan"},
   ["2"] = {"mist_executioner", "sand_warden", "surgeon", "serpent_sage", "crimson_crow"},
   ["3"] = {"dreamer", "insect_eater", "thread_demon", "moon_reaper", "worthy_fighter", "thriller_king"},
   ["4"] = {"leopard_assassin", "mochi_man", "sand_warlord", "string_emperor", "red_dog", "dragon_emperor"},
   ["5"] = {"blood_brother", "blooming_wrath", "volcano_head", "deadbeat_dad", "kindness_spreader", "curse_tyrant"},
   ["raid"] = {"cleanup_kaiju", "kaiju_no_8", "mina_ashiro", "kikoru_shinomiya", "gen_narumi", "soshiro_hoshina"}
}

local AllAvailableBosses = {
    "cart_titan", "armored_titan", "beast_titan", "warhammer_titan", "colossal_titan",
    "mist_executioner", "sand_warden", "surgeon", "serpent_sage", "crimson_crow",
    "dreamer", "insect_eater", "thread_demon", "moon_reaper", "worthy_fighter", "thriller_king",
    "leopard_assassin", "mochi_man", "sand_warlord", "string_emperor", "red_dog", "dragon_emperor",
    "blood_brother", "blooming_wrath", "volcano_head", "deadbeat_dad", "kindness_spreader", "curse_tyrant",
    "cleanup_kaiju", "kaiju_no_8", "mina_ashiro", "kikoru_shinomiya", "gen_narumi", "soshiro_hoshina"
}

local WorldAreaNames = {
    ["1"] = "Shiganshina",
    ["2"] = "Leaf Village",
    ["3"] = "Infinity Castle",
    ["4"] = "Marineford",
    ["5"] = "Shibuya Station",
    ["raid"] = "Kaiju Raid"
}

local NpcButtons = {
    { label = "Prestige (Scary Guy)", name = "Scary Guy" },
    { label = "Skill Tree (Tree Guy)", name = "Tree Guy" },
    { label = "Blacksmith", name = "Blacksmith" },
    { label = "Sensei", name = "Sensei" },
}

local UnnamedFallback = { cart_titan = true }
local BossWorldOf = {}
for world, list in pairs(BossHierarchy) do
    for _, b in ipairs(list) do BossWorldOf[b] = world end
end

-- ==================== دوال المساعدة ====================
local function humanDelay(minSec, maxSec)
    task.wait(minSec + math.random() * (maxSec - minSec))
end

local function getCharWithTimeout(timeout)
    local char = player.Character
    if char then return char end
    local t = os.clock()
    repeat
        task.wait(0.2)
        char = player.Character
    until char or os.clock() - t > (timeout or 10)
    return char
end

local function isCharAlive()
    local char = player.Character
    local hum = char and char:FindFirstChildOfClass("Humanoid")
    local root = char and char:FindFirstChild("HumanoidRootPart")
    return hum ~= nil and root ~= nil and hum.Health > 0
end

local function norm(s)
    return (s:lower():gsub("[%s_%-]", ""))
end

local function isAlreadyInBattle()
    local pgui = player:FindFirstChild("PlayerGui")
    if not pgui then return false end
    local battleUI = pgui:FindFirstChild("BattleUI")
    if battleUI then
        local label = battleUI:FindFirstChild("battleNotifierLabel", true)
        if label and label.Visible then
            return true
        end
    end
    return false
end

-- ==================== النقل بين العوالم ====================
local function forceTeleportToWorld(worldKey)
    if worldKey == "raid" then return end

    local char = getCharWithTimeout(10)
    if not char then return end
    local root = char:WaitForChild("HumanoidRootPart", 5)
    if not root then return end

    local areaName = WorldAreaNames[tostring(worldKey)]
    if teleportAreaRemote then
        pcall(function() teleportAreaRemote:FireServer(areaName) end)
        pcall(function() teleportAreaRemote:FireServer(tostring(worldKey)) end)
    end

    local lobby = workspace:FindFirstChild("Lobby")
    local portals = lobby and lobby:FindFirstChild("portals")
    local portalFolder = portals and portals:FindFirstChild(tostring(worldKey))

    if portalFolder then
        local pModel = portalFolder:FindFirstChild("portalModel")
        local triggerPart = nil
        if pModel then
            triggerPart = pModel:FindFirstChild("Part") or pModel:FindFirstChildWhichIsA("BasePart", true)
        end
        triggerPart = triggerPart or portalFolder:FindFirstChildWhichIsA("BasePart", true)

        if triggerPart and root.Parent then
            root.AssemblyLinearVelocity = Vector3.zero
            root.CFrame = triggerPart.CFrame
            task.wait(0.15)
            if firetouchinterest then
                firetouchinterest(root, triggerPart, 0)
                task.wait(0.1)
                firetouchinterest(root, triggerPart, 1)
            end
            humanDelay(1.0, 1.5)
        end
    end
end

local function recoverIfDead(worldKey, alive)
    if isCharAlive() then return true end
    local t = os.clock()
    repeat
        task.wait(0.5)
    until isCharAlive() or not alive() or os.clock() - t > 30
    if not alive() or not isCharAlive() then return false end
    humanDelay(1.5, 2.0)
    forceTeleportToWorld(worldKey)
    return true
end

-- ==================== البحث عن البوسات والـ Cooldown ====================
local BossCache, MissUntil = {}, {}

local function findBossModel(bossName)
    local key = bossName:lower()
    local cached = BossCache[key]
    if cached and cached.Parent and cached:IsDescendantOf(workspace) then
        return cached
    end
    BossCache[key] = nil

    if MissUntil[key] and os.clock() < MissUntil[key] then return nil end

    local want = norm(bossName)
    local found

    local searchRoots = { workspace:FindFirstChild("bossNpcs"), workspace:FindFirstChild("KaijuRaid") }
    for _, root in ipairs(searchRoots) do
        if root then
            local unnamed
            for _, folder in ipairs(root:GetChildren()) do
                for _, m in ipairs(folder:GetChildren()) do
                    if m:IsA("Model") then
                        local n = norm(m.Name)
                        if m:GetAttribute("bossId") == bossName
                            or n == want
                            or (n ~= "" and want ~= "" and n:find(want, 1, true)) then
                            found = m
                            break
                        elseif n == "" and UnnamedFallback[bossName] then
                            unnamed = unnamed or m
                        end
                    end
                end
                if found then break end
            end
            if found then break end
            found = found or unnamed
        end
    end

    if not found then
        local npcsFolder = workspace:FindFirstChild("npcs")
        for _, obj in ipairs(workspace:GetDescendants()) do
            if obj:IsA("Model")
                and not (npcsFolder and obj:IsDescendantOf(npcsFolder))
                and norm(obj.Name) == want then
                found = obj
                break
            end
        end
    end

    if found then BossCache[key] = found else MissUntil[key] = os.clock() + 5 end
    return found
end

local function isBossOnCooldown(bossName, difficulty)
    local bossModel = findBossModel(bossName)
    if not bossModel then return false end

    local pgui = player:FindFirstChild("PlayerGui")
    if not pgui then return false end

    for _, gui in ipairs(pgui:GetChildren()) do
        if gui.Name == "bossCooldownBillboard" and gui:IsA("BillboardGui") then
            local adornee = gui.Adornee
            if adornee and adornee:IsDescendantOf(bossModel) then
                local label = gui:FindFirstChild("cooldownLabel", true)
                if label and label:IsA("TextLabel") and label.Text:find(difficulty, 1, true) then
                    return true
                end
            end
        end
    end
    return false
end

-- ==================== نظام القتال والانتقال ====================
local function teleportNear(targetPosition, attempt)
    local AttemptDistances = { {3, 4}, {2, 3}, {1, 2} }
    local range = AttemptDistances[attempt or 1] or AttemptDistances[1]
    local angle = math.random() * math.pi * 2
    local dist = range[1] + math.random() * (range[2] - range[1])
    local char = player.Character
    local root = char and char:FindFirstChild("HumanoidRootPart")
    if not root then return false end
    root.AssemblyLinearVelocity = Vector3.zero
    root.CFrame = CFrame.new(targetPosition + Vector3.new(math.cos(angle) * dist, 2.5, math.sin(angle) * dist))
    return true
end

local ResultCounter = 0
local LastBossCooldown = 300
if bossResultRemote then
    table.insert(activeConnections, bossResultRemote.OnClientEvent:Connect(function(won, boss, diff, cd)
        ResultCounter += 1
        if type(cd) == "number" then LastBossCooldown = cd end
    end))
end

local BattleStarts, BattleEnds = 0, 0
if battleEvent then
    table.insert(activeConnections, battleEvent.OnClientEvent:Connect(function(action)
        if action == "battle_start" then
            BattleStarts += 1
        elseif action == "battle_ended" then
            BattleEnds += 1
        end
    end))
end

local function hitAndRunBoss(bossName, difficulty, shouldContinue, forceWait)
    shouldContinue = shouldContinue or function() return true end
    if isAlreadyInBattle() then return false end
    if isBossOnCooldown(bossName, difficulty) then return false end

    local targetModel = findBossModel(bossName)
    if not targetModel then return false end

    local targetPart = targetModel:FindFirstChild("HumanoidRootPart")
        or targetModel:FindFirstChild("Head")
        or targetModel:FindFirstChildWhichIsA("BasePart", true)
    if not targetPart then return false end

    local accepted = false
    local startsBefore, endsBefore, resultsBefore = BattleStarts, BattleEnds, ResultCounter

    for attempt = 1, 3 do
        if not shouldContinue() or isAlreadyInBattle() then return false end

        local pos = targetPart.Parent and targetPart.Position or targetModel:GetPivot().Position
        if not teleportNear(pos, attempt) then return false end

        task.wait(0.45 + attempt * 0.15)
        if not shouldContinue() then return false end

        startsBefore, endsBefore, resultsBefore = BattleStarts, BattleEnds, ResultCounter
        if challengeRemote then
            pcall(function() challengeRemote:FireServer(tostring(bossName), tostring(difficulty)) end)
        end

        local t = os.clock()
        while os.clock() - t < 2 do
            if BattleStarts ~= startsBefore or ResultCounter ~= resultsBefore
                or isBossOnCooldown(bossName, difficulty) then
                accepted = true
                break
            end
            task.wait(0.05)
        end
        if accepted then break end
    end

    if not accepted then return false end

    if WaitForBattle or forceWait then
        local t = os.clock()
        while isAlreadyInBattle() and os.clock() - t < 180 do
            if not shouldContinue() then break end
            task.wait(0.5)
        end
    else
        humanDelay(0.3, 0.5)
    end
    return true
end

local SkipUntil = {}

local function attemptBoss(boss, diff, alive, worldKey)
    local k = boss .. "|" .. diff
    if SkipUntil[k] and os.clock() < SkipUntil[k] then return false end
    if not recoverIfDead(worldKey, alive) then return false end
    if isBossOnCooldown(boss, diff) then return false end

    local function stillGoing() return alive() and isCharAlive() end

    local fired = hitAndRunBoss(boss, diff, stillGoing, true)
    if not alive() then return false end

    if not fired then
        if not isCharAlive() then return false end
        SkipUntil[k] = os.clock() + 15
        return false
    end
    if not isCharAlive() then return false end

    task.wait(0.8)
    if isBossOnCooldown(boss, diff) then
        SkipUntil[k] = os.clock() + math.max(LastBossCooldown - 5, 20)
        return true
    end

    SkipUntil[k] = os.clock() + 45
    return false
end

local function stopAllFarming()
    ActiveMode = nil
    ActiveWorldKey = nil
    FarmToken += 1
    customBossToken += 1
    for _, tog in pairs(ModeToggles) do
        if tog then pcall(function() tog:Set(false) end) end
    end
end

-- ==================== تبويب Auto Boss ومحاكاة الجيم باس ====================
local FarmTab = Window:CreateTab("Auto Boss (Replicator)", 4483362458)

-- 1. اختيار البوسات يدوياً (Pick Bosses مثل الإعدادات الأصلية)
FarmTab:CreateDropdown({
   Name = "Pick Bosses (اختر البوسات المطلوبة)",
   Options = AllAvailableBosses,
   CurrentOption = {},
   MultipleOptions = true,
   Flag = "CustomPickedBosses",
   Callback = function(Options)
      SelectedCustomBosses = Options
   end,
})

-- 2. تشغيل الـ Auto Boss على البوسات المحددة (يحاكي الجيم باس تماماً ومجاناً)
FarmTab:CreateToggle({
   Name = "Custom Auto Boss (محاكي الجيم باس)",
   CurrentValue = false,
   Flag = "CustomAutoBossToggle",
   Callback = function(Value)
      customBossToken += 1
      local myToken = customBossToken

      if Value then
          task.spawn(function()
              while customBossToken == myToken do
                  if #SelectedCustomBosses == 0 then
                      task.wait(2)
                  else
                      for _, boss in ipairs(SelectedCustomBosses) do
                          if customBossToken ~= myToken then break end

                          local world = BossWorldOf[boss] or "1"
                          if world ~= "raid" and ActiveWorldKey ~= world then
                              forceTeleportToWorld(world)
                              ActiveWorldKey = world
                          end

                          if not isAlreadyInBattle() and not isBossOnCooldown(boss, SelectedDifficulty) then
                              attemptBoss(boss, SelectedDifficulty, function() return customBossToken == myToken end, world)
                          end
                          task.wait(0.6)
                      end
                  end
                  task.wait(1.5)
              end
          end)
      end
   end,
})

FarmTab:CreateDropdown({
   Name = "Default Difficulty",
   Options = DiffList,
   CurrentOption = {"Normal"},
   Flag = "Difficulty",
   Callback = function(Option)
      SelectedDifficulty = type(Option) == "table" and Option[1] or Option
   end,
})

FarmTab:CreateToggle({
   Name = "Fast Battle / Hide Battle UI",
   CurrentValue = false,
   Flag = "FastBattle",
   Callback = function(Value)
      DisableBattleAnimation = Value
      fastBattleToken += 1
      local myToken = fastBattleToken
      local playerGui = player:WaitForChild("PlayerGui")

      if Value then
          task.spawn(function()
              while DisableBattleAnimation and fastBattleToken == myToken do
                  local battleUI = playerGui:FindFirstChild("BattleUI")
                  if battleUI and battleUI:IsA("ScreenGui") then battleUI.Enabled = false end
                  local cutsceneUI = playerGui:FindFirstChild("PullCutsceneUI")
                  if cutsceneUI and cutsceneUI:IsA("ScreenGui") then cutsceneUI.Enabled = false end
                  if battleEvent then pcall(function() battleEvent:FireServer("Skip") end) end
                  humanDelay(0.4, 0.7)
              end
              local battleUI = playerGui:FindFirstChild("BattleUI")
              if battleUI and battleUI:IsA("ScreenGui") then battleUI.Enabled = true end
          end)
      end
   end,
})

FarmTab:CreateToggle({
   Name = "Wait for battle end",
   CurrentValue = false,
   Flag = "WaitBattle",
   Callback = function(Value) WaitForBattle = Value end,
})

-- ==================== تبويب الرول والتاور (Multi-Battle) ====================
local RollTab = Window:CreateTab("Roll & Tower", 4483362458)
RollTab:CreateButton({ Name = "Toggle Auto Roll", Callback = function() if autoRollRemote then autoRollRemote:FireServer() end end })
RollTab:CreateButton({ Name = "Toggle Quick Roll", Callback = function() if quickRollRemote then quickRollRemote:FireServer() end end })
RollTab:CreateButton({ Name = "Equip Best Cards", Callback = function() if equipBestRemote then equipBestRemote:FireServer() end end })
RollTab:CreateButton({ Name = "Claim Daily Reward", Callback = function() if claimDailyRemote then claimDailyRemote:FireServer() end end })

RollTab:CreateToggle({
   Name = "Auto Run Infinite Tower (Multi-Battle)",
   CurrentValue = false,
   Flag = "AutoInfTowerMulti",
   Callback = function(Value)
      local towerToken = FarmToken
      if not Value then return end
      task.spawn(function()
          while FarmToken == towerToken do
              if runInfTowerRemote and not isAlreadyInBattle() then
                  pcall(function() runInfTowerRemote:FireServer() end)
              end
              task.wait(15)
          end
      end)
   end,
})

-- ==================== تبويب الـ NPCs ====================
local NpcTab = Window:CreateTab("NPCs", 4483362458)

local function findNpc(npcName)
    local folder = workspace:FindFirstChild("npcs")
    if not folder then return nil end
    local want = norm(npcName)
    for _, d in ipairs(folder:GetDescendants()) do
        if d:IsA("Model") and norm(d.Name) == want then return d end
    end
    return nil
end

local function teleportToNpc(npcName)
    local npc = findNpc(npcName)
    if not npc then
        Rayfield:Notify({ Title = "NPC", Content = "تعذر العثور على: " .. npcName, Duration = 4 })
        return
    end
    if not isCharAlive() then return end
    local part = npc:FindFirstChild("HumanoidRootPart") or npc:FindFirstChildWhichIsA("BasePart", true)
    local root = player.Character and player.Character:FindFirstChild("HumanoidRootPart")
    if part and root then
        root.AssemblyLinearVelocity = Vector3.zero
        root.CFrame = part.CFrame * CFrame.new(0, 0, 4) + Vector3.new(0, 2, 0)
    end
end

for _, info in ipairs(NpcButtons) do
    NpcTab:CreateButton({
        Name = "الانتقال إلى: " .. info.label,
        Callback = function() teleportToNpc(info.name) end,
    })
end

-- ==================== تبويب الكوستات الذكي ====================
local QuestTab = Window:CreateTab("Quests", 4483362458)

local function claimAll()
    if claimQuestRemote then pcall(function() claimQuestRemote:FireServer("all") end) end
end

QuestTab:CreateButton({ Name = "Claim All Rewards Now", Callback = claimAll })

QuestTab:CreateToggle({
    Name = "Auto Claim Quests (كل 20 ثانية)",
    CurrentValue = false,
    Flag = "AutoClaimQuests",
    Callback = function(Value)
        autoClaimToken += 1
        local myToken = autoClaimToken
        if not Value then return end
        task.spawn(function()
            while autoClaimToken == myToken do
                claimAll()
                humanDelay(15, 25)
            end
        end)
    end,
})

Rayfield:LoadConfiguration()

Rayfield:Notify({ Title = "Titan Hub V30", Content = "تم دمج محاكي Auto Boss وقائمة Pick Bosses بنجاح!", Duration = 5 })
