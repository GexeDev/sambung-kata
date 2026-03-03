-- =========================================================
-- ENTER BOT - DETEKSI AKHIRAN 1/2 HURUF + RESIZE GEDE
-- =========================================================

if not game:IsLoaded() then game.Loaded:Wait() end

local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Players = game:GetService("Players")
local LocalPlayer = Players.LocalPlayer
local HttpService = game:GetService("HttpService")
local UserInputService = game:GetService("UserInputService")

-- =========================
-- REMOTE EVENTS
-- =========================
local remotes = ReplicatedStorage:FindFirstChild("Remotes")
if not remotes then
    remotes = Instance.new("Folder")
    remotes.Name = "Remotes"
    remotes.Parent = ReplicatedStorage
end

local MatchUI = remotes:FindFirstChild("MatchUI")
local SubmitWord = remotes:FindFirstChild("SubmitWord")
local UsedWordWarn = remotes:FindFirstChild("UsedWordWarn")

if not SubmitWord then
    for _, v in ipairs(ReplicatedStorage:GetDescendants()) do
        if v.Name == "SubmitWord" and v:IsA("RemoteEvent") then
            SubmitWord = v
            break
        end
    end
end

-- =========================
-- LOAD WORDLIST (100K KATA)
-- =========================
local kataModule = {}
local usedWords = {}

local function downloadWordlist()
    local success, response = pcall(function()
        return game:HttpGet("https://raw.githubusercontent.com/danzzy1we/roblox-script-dump/refs/heads/main/WordListDump/withallcombination2.lua")
    end)
    if success and response then
        for word in response:gmatch('"([^"]+)"') do
            table.insert(kataModule, word:lower())
        end
        print("✅ Wordlist loaded: " .. #kataModule .. " kata")
    end
end
downloadWordlist()

-- =========================
-- STATE
-- =========================
local matchActive = false
local isMyTurn = false
local serverLetter = ""
local kataTerpilih = ""
local modeAkhiran = 1  -- 1 = 1 huruf, 2 = 2 huruf
local lastTyped = ""   -- menyimpan ketikan terakhir buat deteksi akhiran

-- =========================
-- FUNGSI CARI KATA BERDASARKAN AWALAN (DARI HURUF AWAL GAME)
-- =========================
local function getKataByAwal(prefix)
    if prefix == "" then return "" end
    local lowerPrefix = string.lower(prefix)
    local candidates = {}
    
    for _, word in ipairs(kataModule) do
        if #word >= 4 and string.sub(word, 1, #lowerPrefix) == lowerPrefix and not usedWords[word] then
            table.insert(candidates, word)
        end
    end
    
    if #candidates > 0 then
        table.sort(candidates, function(a, b) return #a < #b end)
        return candidates[1]
    end
    return ""
end

-- =========================
-- FUNGSI CARI KATA BERDASARKAN AKHIRAN (DARI KETIKAN USER)
-- =========================
local function getKataByAkhiran(suffix)
    if suffix == "" then return "" end
    local lowerSuffix = string.lower(suffix)
    local candidates = {}
    
    for _, word in ipairs(kataModule) do
        if #word >= 4 and string.sub(word, -#lowerSuffix) == lowerSuffix and not usedWords[word] then
            table.insert(candidates, word)
        end
    end
    
    if #candidates > 0 then
        table.sort(candidates, function(a, b) return #a < #b end)
        return candidates[1]
    end
    return ""
end

-- =========================
-- DETEKSI MATCH VIA REMOTE
-- =========================
if MatchUI then
    MatchUI.OnClientEvent:Connect(function(cmd, value)
        print("MatchUI:", cmd, value)
        
        if cmd == "ShowMatchUI" then
            matchActive = true
            isMyTurn = false
            usedWords = {}
            lastTyped = ""
            print("✅ Match active!")
            
        elseif cmd == "HideMatchUI" then
            matchActive = false
            isMyTurn = false
            serverLetter = ""
            lastTyped = ""
            print("⏸️ Match ended")
            
        elseif cmd == "UpdateServerLetter" then
            serverLetter = value:lower()
            kataTerpilih = getKataByAwal(serverLetter)
            print("🎯 Huruf awal:", serverLetter, "→ Kata:", kataTerpilih)
            
        elseif cmd == "StartTurn" then
            isMyTurn = true
            print("🔵 Giliran anda!")
            
        elseif cmd == "EndTurn" then
            isMyTurn = false
            lastTyped = ""
            print("🟡 Giliran opponent")
        end
    end)
else
    -- Fallback ke attribute
    spawn(function()
        while true do
            local letter = LocalPlayer:GetAttribute("CurrentLetter")
            if letter and letter ~= serverLetter then
                serverLetter = letter:lower()
                kataTerpilih = getKataByAwal(serverLetter)
            end
            
            local turn = LocalPlayer:GetAttribute("MyTurn")
            if turn ~= nil then isMyTurn = turn end
            
            local active = LocalPlayer:GetAttribute("MatchActive")
            if active ~= nil then matchActive = active end
            
            task.wait(0.3)
        end
    end)
end

-- =========================
-- HANDLE USED WORD WARNING
-- =========================
if UsedWordWarn then
    UsedWordWarn.OnClientEvent:Connect(function(word)
        print("⚠️ Kata sudah dipakai:", word)
        usedWords[word:lower()] = true
        
        -- Update kata berdasarkan mode yang aktif
        if isMyTurn and matchActive then
            if serverLetter ~= "" then
                kataTerpilih = getKataByAwal(serverLetter)
            end
        end
    end)
end

-- =========================
-- DETEKSI KEYBOARD UNTUK AMBIL AKHIRAN
-- =========================
UserInputService.InputBegan:Connect(function(input, gameProcessed)
    if gameProcessed then return end
    if not matchActive or not isMyTurn then return end
    
    -- Deteksi huruf
    if input.KeyCode >= Enum.KeyCode.A and input.KeyCode <= Enum.KeyCode.Z then
        local key = string.char(input.KeyCode.Value):lower()
        lastTyped = lastTyped .. key
        if #lastTyped > 10 then lastTyped = string.sub(lastTyped, -10) end
        
        -- Update kata berdasarkan mode akhiran
        if #lastTyped >= modeAkhiran then
            local suffix = string.sub(lastTyped, -modeAkhiran)
            local kataByAkhiran = getKataByAkhiran(suffix)
            if kataByAkhiran ~= "" then
                kataTerpilih = kataByAkhiran
                print("🔍 Deteksi akhiran:", suffix, "→ Kata:", kataByAkhiran)
            end
        end
    end
    
    -- Deteksi backspace
    if input.KeyCode == Enum.KeyCode.Backspace then
        lastTyped = string.sub(lastTyped, 1, -2)
    end
    
    -- Deteksi spasi (reset)
    if input.KeyCode == Enum.KeyCode.Space then
        lastTyped = ""
    end
end)

-- =========================
-- BUAT GUI
-- =========================
local gui = Instance.new("ScreenGui")
gui.Name = "EnterBot"
gui.ResetOnSpawn = false
gui.Parent = LocalPlayer:WaitForChild("PlayerGui")
gui.IgnoreGuiInset = true
gui.DisplayOrder = 9999

-- =========================
-- PREVIEW KATA (ATAS TENGAH)
-- =========================
local previewFrame = Instance.new("Frame")
previewFrame.Name = "PreviewKata"
previewFrame.Size = UDim2.new(0, 200, 0, 50)
previewFrame.Position = UDim2.new(0.5, -100, 0.02, 0)
previewFrame.BackgroundColor3 = Color3.fromRGB(25, 25, 25)
previewFrame.BackgroundTransparency = 0.1
previewFrame.BorderSizePixel = 0
previewFrame.Parent = gui

local previewCorner = Instance.new("UICorner")
previewCorner.CornerRadius = UDim.new(0.5, 0)
previewCorner.Parent = previewFrame

local previewStroke = Instance.new("UIStroke")
previewStroke.Color = Color3.fromRGB(0, 150, 255)
previewStroke.Thickness = 1.5
previewStroke.Transparency = 0.3
previewStroke.Parent = previewFrame

local hurufLabel = Instance.new("TextLabel")
hurufLabel.Size = UDim2.new(0.3, 0, 1, 0)
hurufLabel.BackgroundTransparency = 1
hurufLabel.Text = "?"
hurufLabel.TextColor3 = Color3.fromRGB(0, 150, 255)
hurufLabel.TextSize = 30
hurufLabel.Font = Enum.Font.SourceSansBold
hurufLabel.Parent = previewFrame

local kataPreview = Instance.new("TextLabel")
kataPreview.Size = UDim2.new(0.7, 0, 1, 0)
kataPreview.Position = UDim2.new(0.3, 0, 0, 0)
kataPreview.BackgroundTransparency = 1
kataPreview.Text = "LOADING..."
kataPreview.TextColor3 = Color3.fromRGB(255, 255, 255)
kataPreview.TextSize = 14
kataPreview.Font = Enum.Font.SourceSansBold
kataPreview.TextWrapped = true
kataPreview.Parent = previewFrame

local statusPreview = Instance.new("TextLabel")
statusPreview.Size = UDim2.new(1, -10, 0, 16)
statusPreview.Position = UDim2.new(0, 5, 1, 2)
statusPreview.BackgroundTransparency = 1
statusPreview.Text = "Menunggu..."
statusPreview.TextColor3 = Color3.fromRGB(150, 150, 150)
statusPreview.TextSize = 10
statusPreview.Font = Enum.Font.SourceSans
statusPreview.TextXAlignment = Enum.TextXAlignment.Left
statusPreview.Parent = previewFrame

-- =========================
-- PANEL KONTROL (DI BAWAH PREVIEW)
-- =========================
local controlPanel = Instance.new("Frame")
controlPanel.Name = "ControlPanel"
controlPanel.Size = UDim2.new(0, 400, 0, 40)  -- lebih panjang buat 9 tombol
controlPanel.Position = UDim2.new(0.5, -200, 0.1, 0)
controlPanel.BackgroundColor3 = Color3.fromRGB(25, 25, 25)
controlPanel.BackgroundTransparency = 0.2
controlPanel.BorderSizePixel = 0
controlPanel.Parent = gui

local controlCorner = Instance.new("UICorner")
controlCorner.CornerRadius = UDim.new(0.5, 0)
controlCorner.Parent = controlPanel

-- Fungsi bikin tombol bulat
local function makeButton(pos, text, color, parent)
    local btn = Instance.new("TextButton")
    btn.Size = UDim2.new(0, 30, 0, 30)
    btn.Position = UDim2.new(0, pos, 0.5, -15)
    btn.BackgroundColor3 = Color3.fromRGB(45, 45, 45)
    btn.Text = text
    btn.TextColor3 = color
    btn.TextSize = 16
    btn.Font = Enum.Font.SourceSansBold
    btn.BorderSizePixel = 0
    btn.Parent = parent
    
    local corner = Instance.new("UICorner")
    corner.CornerRadius = UDim.new(0.5, 0)
    corner.Parent = btn
    
    return btn
end

-- 9 TOMBOL KONTROL
local lockBtn = makeButton(5, "🔓", Color3.fromRGB(255, 255, 255), controlPanel)
local mode1Btn = makeButton(40, "1H", Color3.fromRGB(0, 255, 0), controlPanel)  -- mode 1 huruf
local mode2Btn = makeButton(75, "2H", Color3.fromRGB(255, 255, 255), controlPanel)  -- mode 2 huruf
local upBtn = makeButton(110, "⬆️", Color3.fromRGB(0, 255, 0), controlPanel)
local downBtn = makeButton(145, "⬇️", Color3.fromRGB(255, 0, 0), controlPanel)
local rightBtn = makeButton(180, "➡️", Color3.fromRGB(0, 255, 0), controlPanel)
local leftBtn = makeButton(215, "⬅️", Color3.fromRGB(255, 0, 0), controlPanel)
local saveBtn = makeButton(250, "💾", Color3.fromRGB(0, 150, 255), controlPanel)
local resetBtn = makeButton(285, "↺", Color3.fromRGB(255, 255, 255), controlPanel)
local closeBtn = makeButton(320, "X", Color3.fromRGB(255, 100, 100), controlPanel)
local colorBtn = makeButton(355, "👁️", Color3.fromRGB(255, 255, 255), controlPanel)  -- ganti warna

-- =========================
-- TOMBOL ENTER (BISA DRAG, RESIZE GEDE)
-- =========================
local enterFrame = Instance.new("Frame")
enterFrame.Name = "FakeEnter"
enterFrame.Size = UDim2.new(0, 200, 0, 90)  -- lebih gede default
enterFrame.Position = UDim2.new(1, -220, 0.02, 0)
enterFrame.BackgroundColor3 = Color3.fromRGB(35, 35, 35)
enterFrame.BackgroundTransparency = 0.1
enterFrame.BorderSizePixel = 0
enterFrame.Active = true
enterFrame.Parent = gui

local enterCorner = Instance.new("UICorner")
enterCorner.CornerRadius = UDim.new(0.5, 0)
enterCorner.Parent = enterFrame

local enterStroke = Instance.new("UIStroke")
enterStroke.Color = Color3.fromRGB(0, 150, 255)
enterStroke.Thickness = 1  -- lebih tipis biar gak keliatan pas transparant
enterStroke.Transparency = 0.5
enterStroke.Parent = enterFrame

local shadow = Instance.new("ImageLabel")
shadow.Size = UDim2.new(1, 10, 1, 10)
shadow.Position = UDim2.new(0, -5, 0, -5)
shadow.BackgroundTransparency = 1
shadow.Image = "rbxassetid://1316045217"
shadow.ImageColor3 = Color3.fromRGB(0, 0, 0)
shadow.ImageTransparency = 0.6
shadow.ZIndex = -1
shadow.Parent = enterFrame

local enterText = Instance.new("TextLabel")
enterText.Size = UDim2.new(1, 0, 0.5, 0)
enterText.Position = UDim2.new(0, 0, 0, 8)
enterText.BackgroundTransparency = 1
enterText.Text = "ENTER"
enterText.TextColor3 = Color3.fromRGB(220, 220, 220)
enterText.TextSize = 28
enterText.Font = Enum.Font.SourceSansBold
enterText.Parent = enterFrame

local miniPreview = Instance.new("TextLabel")
miniPreview.Size = UDim2.new(1, 0, 0.3, 0)
miniPreview.Position = UDim2.new(0, 0, 0.55, 0)
miniPreview.BackgroundTransparency = 1
miniPreview.Text = ""
miniPreview.TextColor3 = Color3.fromRGB(0, 150, 255)
miniPreview.TextSize = 14
miniPreview.Font = Enum.Font.SourceSans
miniPreview.Parent = enterFrame

-- =========================
-- VARIABEL DRAG & STATE
-- =========================
local dragging = false
local dragInput, dragStart, startPos
local locked = false
local colorMode = false  -- false = abu-abu, true = transparant total
local defaultPos = UDim2.new(1, -220, 0.02, 0)
local defaultSize = UDim2.new(0, 200, 0, 90)

-- =========================
-- FUNGSI DRAG
-- =========================
local function updateDrag(input)
    if locked then return end
    local delta = input.Position - dragStart
    local newPos = UDim2.new(
        startPos.X.Scale, 
        startPos.X.Offset + delta.X,
        startPos.Y.Scale,
        startPos.Y.Offset + delta.Y
    )
    enterFrame.Position = newPos
end

enterFrame.InputBegan:Connect(function(input)
    if input.UserInputType == Enum.UserInputType.MouseButton1 or input.UserInputType == Enum.UserInputType.Touch then
        if not locked then
            dragging = true
            dragStart = input.Position
            startPos = enterFrame.Position
        end
        
        -- Efek klik (tetap keliatan walau transparant)
        if colorMode then
            enterFrame.BackgroundTransparency = 0.3
        else
            enterFrame.BackgroundColor3 = Color3.fromRGB(60, 60, 60)
        end
        enterText.TextColor3 = Color3.fromRGB(255, 255, 255)
    end
end)

enterFrame.InputChanged:Connect(function(input)
    if input.UserInputType == Enum.UserInputType.MouseMovement or input.UserInputType == Enum.UserInputType.Touch then
        dragInput = input
    end
end)

UserInputService.InputChanged:Connect(function(input)
    if input == dragInput and dragging then
        updateDrag(input)
    end
end)

enterFrame.InputEnded:Connect(function(input)
    if input.UserInputType == Enum.UserInputType.MouseButton1 or input.UserInputType == Enum.UserInputType.Touch then
        dragging = false
        dragInput = nil
        
        -- Kembalikan transparansi
        if colorMode then
            enterFrame.BackgroundTransparency = 0.95
            enterStroke.Transparency = 0.9
        else
            enterFrame.BackgroundColor3 = Color3.fromRGB(35, 35, 35)
            enterFrame.BackgroundTransparency = 0.1
        end
        
        -- KIRIM KATA!
        if SubmitWord and matchActive and isMyTurn and kataTerpilih ~= "" then
            SubmitWord:FireServer(kataTerpilih)
            print("✅ MENGIRIM KATA:", kataTerpilih)
            usedWords[kataTerpilih] = true
            
            -- Update kata berdasarkan mode
            if serverLetter ~= "" then
                kataTerpilih = getKataByAwal(serverLetter)
            end
            
            -- Efek sukses
            if colorMode then
                enterStroke.Color = Color3.fromRGB(0, 255, 0)
                enterStroke.Transparency = 0.5
                task.wait(0.2)
                enterStroke.Color = Color3.fromRGB(0, 150, 255)
            else
                enterFrame.BackgroundColor3 = Color3.fromRGB(0, 150, 255)
                task.wait(0.1)
                enterFrame.BackgroundColor3 = Color3.fromRGB(35, 35, 35)
            end
        end
    end
end)

-- =========================
-- FUNGSI TOMBOL KONTROL
-- =========================

-- GEMBOK
lockBtn.MouseButton1Click:Connect(function()
    locked = not locked
    lockBtn.Text = locked and "🔒" or "🔓"
    lockBtn.BackgroundColor3 = locked and Color3.fromRGB(0, 150, 255) or Color3.fromRGB(45, 45, 45)
end)

-- MODE 1 HURUF
mode1Btn.MouseButton1Click:Connect(function()
    modeAkhiran = 1
    mode1Btn.BackgroundColor3 = Color3.fromRGB(0, 150, 255)
    mode2Btn.BackgroundColor3 = Color3.fromRGB(45, 45, 45)
    print("🔤 Mode deteksi: 1 huruf terakhir")
end)

-- MODE 2 HURUF
mode2Btn.MouseButton1Click:Connect(function()
    modeAkhiran = 2
    mode2Btn.BackgroundColor3 = Color3.fromRGB(0, 150, 255)
    mode1Btn.BackgroundColor3 = Color3.fromRGB(45, 45, 45)
    print("🔤 Mode deteksi: 2 huruf terakhir")
end)

-- WARNA (TRANSPARANT / ABU-ABU)
colorBtn.MouseButton1Click:Connect(function()
    colorMode = not colorMode
    if colorMode then
        -- Mode transparant total (hampir gak keliatan)
        enterFrame.BackgroundTransparency = 0.95
        enterStroke.Transparency = 0.9
        enterStroke.Thickness = 0.5
        shadow.ImageTransparency = 0.95
        enterText.TextTransparency = 0.3
        miniPreview.TextTransparency = 0.3
        colorBtn.BackgroundColor3 = Color3.fromRGB(0, 150, 255)
        colorBtn.Text = "👁️"
    else
        -- Mode abu-abu normal
        enterFrame.BackgroundTransparency = 0.1
        enterStroke.Transparency = 0.5
        enterStroke.Thickness = 2
        shadow.ImageTransparency = 0.6
        enterText.TextTransparency = 0
        miniPreview.TextTransparency = 0
        colorBtn.BackgroundColor3 = Color3.fromRGB(45, 45, 45)
        colorBtn.Text = "👁️"
    end
end)

-- RESIZE UP (TAMBAH TINGGI) - BATAS MAKSIMAL GEDE
upBtn.MouseButton1Click:Connect(function()
    local currentSize = enterFrame.Size
    local newHeight = math.min(currentSize.Y.Offset + 20, 400)  -- maks 400
    enterFrame.Size = UDim2.new(0, currentSize.X.Offset, 0, newHeight)
    enterText.TextSize = math.floor(newHeight * 0.34)
    miniPreview.TextSize = math.floor(newHeight * 0.17)
    print("📏 Tinggi:", newHeight)
end)

-- RESIZE DOWN (KURANG TINGGI)
downBtn.MouseButton1Click:Connect(function()
    local currentSize = enterFrame.Size
    local newHeight = math.max(currentSize.Y.Offset - 20, 40)
    enterFrame.Size = UDim2.new(0, currentSize.X.Offset, 0, newHeight)
    enterText.TextSize = math.floor(newHeight * 0.34)
    miniPreview.TextSize = math.floor(newHeight * 0.17)
    print("📏 Tinggi:", newHeight)
end)

-- RESIZE RIGHT (TAMBAH LEBAR) - BATAS MAKSIMAL GEDE
rightBtn.MouseButton1Click:Connect(function()
    local currentSize = enterFrame.Size
    local newWidth = math.min(currentSize.X.Offset + 40, 800)  -- maks 800
    enterFrame.Size = UDim2.new(0, newWidth, 0, currentSize.Y.Offset)
    print("📏 Lebar:", newWidth)
end)

-- RESIZE LEFT (KURANG LEBAR)
leftBtn.MouseButton1Click:Connect(function()
    local currentSize = enterFrame.Size
    local newWidth = math.max(currentSize.X.Offset - 40, 80)
    enterFrame.Size = UDim2.new(0, newWidth, 0, currentSize.Y.Offset)
    print("📏 Lebar:", newWidth)
end)

-- SAVE POSISI & UKURAN
saveBtn.MouseButton1Click:Connect(function()
    local saveData = {
        Position = {
            X = enterFrame.Position.X.Offset,
            Y = enterFrame.Position.Y.Offset
        },
        Size = {
            Width = enterFrame.Size.X.Offset,
            Height = enterFrame.Size.Y.Offset
        }
    }
    
    if not _G.EnterBotSettings then _G.EnterBotSettings = {} end
    _G.EnterBotSettings.SavedPos = saveData.Position
    _G.EnterBotSettings.SavedSize = saveData.Size
    
    print("💾 Posisi & ukuran tersimpan!")
    
    saveBtn.BackgroundColor3 = Color3.fromRGB(0, 255, 0)
    task.wait(0.2)
    saveBtn.BackgroundColor3 = Color3.fromRGB(45, 45, 45)
end)

-- RESET
resetBtn.MouseButton1Click:Connect(function()
    enterFrame.Position = defaultPos
    enterFrame.Size = defaultSize
    enterText.TextSize = 28
    miniPreview.TextSize = 14
end)

-- CLOSE
closeBtn.MouseButton1Click:Connect(function()
    gui:Destroy()
end)

-- =========================
-- LOAD SAVED SETTINGS
-- =========================
if _G.EnterBotSettings and _G.EnterBotSettings.SavedPos then
    enterFrame.Position = UDim2.new(0, _G.EnterBotSettings.SavedPos.X, 0, _G.EnterBotSettings.SavedPos.Y)
end
if _G.EnterBotSettings and _G.EnterBotSettings.SavedSize then
    enterFrame.Size = UDim2.new(0, _G.EnterBotSettings.SavedSize.Width, 0, _G.EnterBotSettings.SavedSize.Height)
    enterText.TextSize = math.floor(_G.EnterBotSettings.SavedSize.Height * 0.34)
    miniPreview.TextSize = math.floor(_G.EnterBotSettings.SavedSize.Height * 0.17)
end

-- =========================
-- FUNGSI UPDATE GUI
-- =========================
local function updateGUI()
    if matchActive then
        if isMyTurn then
            statusPreview.Text = "🔵 GILIRAN ANDA | Mode: " .. modeAkhiran .. "H"
            statusPreview.TextColor3 = Color3.fromRGB(0, 255, 0)
        else
            statusPreview.Text = "🟡 Giliran opponent"
            statusPreview.TextColor3 = Color3.fromRGB(255, 255, 0)
        end
    else
        statusPreview.Text = "⚫ Menunggu match..."
        statusPreview.TextColor3 = Color3.fromRGB(150, 150, 150)
    end
    
    hurufLabel.Text = serverLetter ~= "" and serverLetter:upper() or "?"
    
    if kataTerpilih ~= "" then
        kataPreview.Text = kataTerpilih:upper()
        miniPreview.Text = kataTerpilih:upper()
        kataPreview.TextColor3 = Color3.fromRGB(255, 255, 255)
    else
        if serverLetter ~= "" then
            kataPreview.Text = "TIDAK ADA"
            kataPreview.TextColor3 = Color3.fromRGB(255, 0, 0)
        else
            kataPreview.Text = "MENUNGGU"
            kataPreview.TextColor3 = Color3.fromRGB(255, 255, 255)
        end
        miniPreview.Text = ""
    end
    
    -- Update warna tombol berdasarkan status (hanya kalau mode abu-abu)
    if not colorMode then
        if matchActive and isMyTurn and kataTerpilih ~= "" then
            enterFrame.BackgroundColor3 = Color3.fromRGB(45, 45, 45)
            enterText.TextColor3 = Color3.fromRGB(0, 255, 0)
        else
            enterFrame.BackgroundColor3 = Color3.fromRGB(35, 35, 35)
            enterText.TextColor3 = Color3.fromRGB(150, 150, 150)
        end
    end
end

spawn(function()
    while true do
        updateGUI()
        task.wait(0.1)
    end
end)

-- =========================
-- INIT
-- =========================
print("🚀 ENTER BOT - DETEKSI AKHIRAN!")
print("📌 Mode 1H: deteksi 1 huruf terakhir (contoh: ahmesx → annex)")
print("📌 Mode 2H: deteksi 2 huruf terakhir (contoh: ahmantap → asap)")
print("📌 ⬆️⬇️ : atur TINGGI (maks 400)")
print("📌 ➡️⬅️ : atur LEBAR (maks 800)")
print("📌 👁️ : ganti mode transparant/abu-abu")