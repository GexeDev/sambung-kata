-- =========================================================
-- ULTRA SMART AUTO KATA (DENGAN ANTI DOUBLE + WORDLIST EKSTERNAL)
-- =========================================================

if not game:IsLoaded() then game.Loaded:Wait() end

-- =========================
-- SERVICES
-- =========================
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Players = game:GetService("Players")
local UserInputService = game:GetService("UserInputService")
local LocalPlayer = Players.LocalPlayer
local HttpService = game:GetService("HttpService")

-- =========================
-- LOAD WORDLIST DARI GITHUB (withallcombination2.lua)
-- =========================
local kataModule = {}
local kataSet = {} -- Untuk cek duplikat cepat

local function downloadWordlist()
    local success, response = pcall(function()
        return game:HttpGet("https://raw.githubusercontent.com/danzzy1we/roblox-script-dump/refs/heads/main/WordListDump/withallcombination2.lua")
    end)
    
    if not success or not response then
        warn("❌ Gagal download wordlist!")
        return false
    end

    -- Parse format return ["a","aa","aabi",...]
    local words = {}
    for word in response:gmatch('"([^"]+)"') do
        table.insert(words, word)
    end
    
    if #words == 0 then
        warn("❌ Wordlist kosong!")
        return false
    end
    
    -- Filter kata unik dan panjang > 1
    local duplicateCount = 0
    for _, word in ipairs(words) do
        local w = string.lower(word)
        if #w > 1 then
            if not kataSet[w] then
                kataSet[w] = true
                table.insert(kataModule, w)
            else
                duplicateCount = duplicateCount + 1
            end
        end
    end
    
    print(string.format("✅ Wordlist loaded: %d unique words (%d duplicates removed)", #kataModule, duplicateCount))
    return true
end

local wordlistOk = downloadWordlist()
if not wordlistOk or #kataModule == 0 then
    warn("❌ Gagal load wordlist! Menggunakan database internal...")
    -- Fallback ke database minimal
    kataModule = {"xantelesma", "xantat", "xantofil", "xerostomia", "xenon", "axis", "exodus"}
end

-- =========================
-- REMOTE EVENTS (DARI SCRIPT DANZZY)
-- =========================
local remotes = ReplicatedStorage:FindFirstChild("Remotes")
if not remotes then
    remotes = Instance.new("Folder")
    remotes.Name = "Remotes"
    remotes.Parent = ReplicatedStorage
end

-- Cari remote yang dibutuhkan
local MatchUI = remotes:FindFirstChild("MatchUI") or remotes:FindFirstChild("MatchUI")
local SubmitWord = remotes:FindFirstChild("SubmitWord") or remotes:FindFirstChild("SubmitWord")
local BillboardUpdate = remotes:FindFirstChild("BillboardUpdate") or remotes:FindFirstChild("BillboardUpdate")
local BillboardEnd = remotes:FindFirstChild("BillboardEnd") or remotes:FindFirstChild("BillboardEnd")
local TypeSound = remotes:FindFirstChild("TypeSound") or remotes:FindFirstChild("TypeSound")
local UsedWordWarn = remotes:FindFirstChild("UsedWordWarn") or remotes:FindFirstChild("UsedWordWarn")

if not SubmitWord then
    -- Fallback: cari di seluruh ReplicatedStorage
    for _, v in ipairs(ReplicatedStorage:GetDescendants()) do
        if v.Name == "SubmitWord" and v:IsA("RemoteEvent") then
            SubmitWord = v
            break
        end
    end
end

-- =========================
-- STATE VARIABLES
-- =========================
local matchActive = false
local isMyTurn = false
local serverLetter = ""
local usedWords = {}      -- Set untuk kata yang sudah dipakai di match ini
local usedWordsList = {}  -- List untuk ditampilkan
local opponentStreamWord = ""
local autoEnabled = true  -- Auto aktif default
local autoRunning = false

-- =========================
-- FUNGSI ANTI DOUBLE
-- =========================
local function isUsed(word)
    return usedWords[string.lower(word)] == true
end

local function addUsedWord(word)
    local w = string.lower(word)
    if not usedWords[w] then
        usedWords[w] = true
        table.insert(usedWordsList, word)
        print("📝 Kata dipakai:", word)
    end
end

local function resetUsedWords()
    usedWords = {}
    usedWordsList = {}
    print("🔄 Reset daftar kata untuk match baru")
end

-- =========================
-- FUNGSI MENCARI KATA COCOK (DENGAN ANTI DOUBLE)
-- =========================
local function getValidWords(prefix)
    if prefix == "" then return {} end
    
    local results = {}
    local lowerPrefix = string.lower(prefix)
    
    for _, word in ipairs(kataModule) do
        -- Cek apakah berawalan dengan prefix
        if string.sub(word, 1, #lowerPrefix) == lowerPrefix then
            -- Cek apakah sudah dipakai
            if not isUsed(word) then
                table.insert(results, word)
            end
        end
    end
    
    -- Urutkan berdasarkan panjang (yang terpanjang dulu) biar lebih gacor
    table.sort(results, function(a, b)
        return #a > #b
    end)
    
    return results
end

-- =========================
-- FUNGSI AUTO KIRIM KATA
-- =========================
local function kirimKataOtomatis()
    if autoRunning then return end
    if not autoEnabled then return end
    if not matchActive then return end
    if not isMyTurn then return end
    if serverLetter == "" then return end
    
    autoRunning = true
    
    -- Cari kata yang valid
    local words = getValidWords(serverLetter)
    
    if #words == 0 then
        print("⚠️ Tidak ada kata tersedia untuk huruf:", serverLetter)
        autoRunning = false
        return
    end
    
    -- Pilih kata pertama (terpanjang)
    local selectedWord = words[1]
    
    -- Efek mengetik (simulasi)
    local currentWord = serverLetter
    local remaining = string.sub(selectedWord, #serverLetter + 1)
    
    for i = 1, #remaining do
        if not matchActive or not isMyTurn then
            autoRunning = false
            return
        end
        
        currentWord = currentWord .. string.sub(remaining, i, i)
        
        -- Fire remote update
        if BillboardUpdate then
            pcall(function()
                BillboardUpdate:FireServer(currentWord)
            end)
        end
        if TypeSound then
            pcall(function()
                TypeSound:FireServer()
            end)
        end
        
        task.wait(0.05) -- Delay kecil biar keliatan natural
    end
    
    task.wait(0.1)
    
    -- Kirim kata
    if SubmitWord then
        pcall(function()
            SubmitWord:FireServer(selectedWord)
            print("✅ Mengirim kata:", selectedWord)
        end)
        
        -- Tambahkan ke daftar kata terpakai
        addUsedWord(selectedWord)
    end
    
    -- End billboard
    if BillboardEnd then
        pcall(function()
            BillboardEnd:FireServer()
        end)
    end
    
    autoRunning = false
end

-- =========================
-- MEMBUAT GUI MINIMALIS
-- =========================
local screenGui = Instance.new("ScreenGui")
screenGui.Name = "AutoKataBot"
screenGui.ResetOnSpawn = false
screenGui.Parent = LocalPlayer:WaitForChild("PlayerGui")

local mainFrame = Instance.new("Frame")
mainFrame.Size = UDim2.new(0, 250, 0, 160)
mainFrame.Position = UDim2.new(0.5, -125, 0.1, 0)
mainFrame.BackgroundColor3 = Color3.fromRGB(0, 0, 0)
mainFrame.BorderColor3 = Color3.fromRGB(0, 150, 255)
mainFrame.BorderSizePixel = 2
mainFrame.Active = true
mainFrame.Draggable = true
mainFrame.Parent = screenGui

-- Title
local title = Instance.new("TextLabel")
title.Size = UDim2.new(1, 0, 0, 25)
title.BackgroundColor3 = Color3.fromRGB(0, 0, 0)
title.TextColor3 = Color3.fromRGB(0, 150, 255)
title.Text = "🤖 AUTO KATA BOT (ANTI DOUBLE)"
title.TextSize = 12
title.Font = Enum.Font.SourceSansBold
title.Parent = mainFrame

-- Status
local statusLabel = Instance.new("TextLabel")
statusLabel.Name = "Status"
statusLabel.Size = UDim2.new(1, -10, 0, 20)
statusLabel.Position = UDim2.new(0, 5, 0, 25)
statusLabel.BackgroundColor3 = Color3.fromRGB(15, 15, 15)
statusLabel.TextColor3 = Color3.fromRGB(200, 200, 200)
statusLabel.Text = "Status: Menunggu match..."
statusLabel.TextSize = 11
statusLabel.TextXAlignment = Enum.TextXAlignment.Left
statusLabel.BorderColor3 = Color3.fromRGB(0, 150, 255)
statusLabel.BorderSizePixel = 1
statusLabel.Parent = mainFrame

-- Huruf Awal
local hurufLabel = Instance.new("TextLabel")
hurufLabel.Name = "Huruf"
hurufLabel.Size = UDim2.new(0, 50, 0, 30)
hurufLabel.Position = UDim2.new(0, 5, 0, 50)
hurufLabel.BackgroundColor3 = Color3.fromRGB(15, 15, 15)
hurufLabel.TextColor3 = Color3.fromRGB(0, 150, 255)
hurufLabel.Text = "?"
hurufLabel.TextSize = 18
hurufLabel.Font = Enum.Font.SourceSansBold
hurufLabel.BorderColor3 = Color3.fromRGB(0, 150, 255)
hurufLabel.BorderSizePixel = 1
hurufLabel.Parent = mainFrame

-- Kata yang akan dikirim
local kataLabel = Instance.new("TextLabel")
kataLabel.Name = "Kata"
kataLabel.Size = UDim2.new(0, 180, 0, 30)
kataLabel.Position = UDim2.new(0, 60, 0, 50)
kataLabel.BackgroundColor3 = Color3.fromRGB(15, 15, 15)
kataLabel.TextColor3 = Color3.fromRGB(255, 255, 255)
kataLabel.Text = "Menunggu..."
kataLabel.TextSize = 14
kataLabel.Font = Enum.Font.SourceSansBold
kataLabel.BorderColor3 = Color3.fromRGB(0, 150, 255)
kataLabel.BorderSizePixel = 1
kataLabel.Parent = mainFrame

-- Toggle Auto
local toggleButton = Instance.new("TextButton")
toggleButton.Size = UDim2.new(0, 80, 0, 25)
toggleButton.Position = UDim2.new(0, 5, 0, 90)
toggleButton.BackgroundColor3 = Color3.fromRGB(0, 150, 255)
toggleButton.TextColor3 = Color3.fromRGB(255, 255, 255)
toggleButton.Text = "✅ AUTO ON"
toggleButton.TextSize = 11
toggleButton.Font = Enum.Font.SourceSansBold
toggleButton.BorderSizePixel = 0
toggleButton.Parent = mainFrame
toggleButton.MouseButton1Click:Connect(function()
    autoEnabled = not autoEnabled
    if autoEnabled then
        toggleButton.Text = "✅ AUTO ON"
        toggleButton.BackgroundColor3 = Color3.fromRGB(0, 150, 255)
        kirimKataOtomatis()
    else
        toggleButton.Text = "❌ AUTO OFF"
        toggleButton.BackgroundColor3 = Color3.fromRGB(150, 0, 0)
    end
end)

-- Info Wordlist
local wordlistInfo = Instance.new("TextLabel")
wordlistInfo.Size = UDim2.new(1, -10, 0, 18)
wordlistInfo.Position = UDim2.new(0, 5, 0, 125)
wordlistInfo.BackgroundColor3 = Color3.fromRGB(0, 0, 0)
wordlistInfo.TextColor3 = Color3.fromRGB(100, 100, 100)
wordlistInfo.Text = "📚 " .. #kataModule .. " kata siap"
wordlistInfo.TextSize = 9
wordlistInfo.TextXAlignment = Enum.TextXAlignment.Left
wordlistInfo.Parent = mainFrame

-- Close button
local closeButton = Instance.new("TextButton")
closeButton.Size = UDim2.new(0, 20, 0, 20)
closeButton.Position = UDim2.new(1, -22, 0, 3)
closeButton.BackgroundColor3 = Color3.fromRGB(50, 50, 50)
closeButton.TextColor3 = Color3.fromRGB(255, 255, 255)
closeButton.Text = "X"
closeButton.TextSize = 12
closeButton.Font = Enum.Font.SourceSansBold
closeButton.BorderColor3 = Color3.fromRGB(0, 150, 255)
closeButton.BorderSizePixel = 1
closeButton.Parent = mainFrame
closeButton.MouseButton1Click:Connect(function()
    screenGui:Destroy()
end)

-- =========================
-- FUNGSI UPDATE GUI
-- =========================
local function updateGUI()
    local statusText = ""
    if matchActive then
        if isMyTurn then
            statusText = "Status: 🔵 GILIRAN ANDA"
        else
            if opponentStreamWord ~= "" then
                statusText = "Status: 🟡 Opponent ngetik: " .. opponentStreamWord
            else
                statusText = "Status: 🟢 Giliran opponent"
            end
        end
    else
        statusText = "Status: ⚫ Menunggu match..."
    end
    
    statusLabel.Text = statusText
    hurufLabel.Text = serverLetter ~= "" and serverLetter:upper() or "?"
    
    -- Cari kata yang akan dikirim
    if serverLetter ~= "" and isMyTurn then
        local words = getValidWords(serverLetter)
        if #words > 0 then
            kataLabel.Text = words[1]:upper()
        else
            kataLabel.Text = "TIDAK ADA KATA"
            kataLabel.TextColor3 = Color3.fromRGB(255, 0, 0)
        end
    else
        kataLabel.Text = "MENUNGGU..."
        kataLabel.TextColor3 = Color3.fromRGB(255, 255, 255)
    end
end

-- =========================
-- DETEKSI REMOTE EVENTS (DARI SCRIPT DANZZY)
-- =========================

-- MatchUI event
if MatchUI then
    MatchUI.OnClientEvent:Connect(function(cmd, value)
        print("MatchUI:", cmd, value)
        
        if cmd == "ShowMatchUI" then
            matchActive = true
            isMyTurn = false
            resetUsedWords()
            
        elseif cmd == "HideMatchUI" then
            matchActive = false
            isMyTurn = false
            serverLetter = ""
            resetUsedWords()
            
        elseif cmd == "StartTurn" then
            isMyTurn = true
            updateGUI()
            if autoEnabled then
                task.wait(0.3)
                kirimKataOtomatis()
            end
            
        elseif cmd == "EndTurn" then
            isMyTurn = false
            
        elseif cmd == "UpdateServerLetter" then
            serverLetter = value or ""
            updateGUI()
        end
        
        updateGUI()
    end)
else
    warn("⚠️ MatchUI tidak ditemukan!")
end

-- BillboardUpdate (untuk lihat opponent ngetik)
if BillboardUpdate then
    BillboardUpdate.OnClientEvent:Connect(function(word)
        if matchActive and not isMyTurn then
            opponentStreamWord = word or ""
            updateGUI()
        end
    end)
end

-- UsedWordWarn (kata sudah dipakai)
if UsedWordWarn then
    UsedWordWarn.OnClientEvent:Connect(function(word)
        if word then
            addUsedWord(word)
            updateGUI()
            
            -- Kalau auto aktif dan ini giliran kita, cari kata lain
            if autoEnabled and matchActive and isMyTurn then
                task.wait(0.1)
                kirimKataOtomatis()
            end
        end
    end)
end

-- =========================
-- DETEKSI TOMBOL ENTER MANUAL (OPSIONAL)
-- =========================
UserInputService.InputBegan:Connect(function(input, gameProcessed)
    if gameProcessed then return end
    
    if input.KeyCode == Enum.KeyCode.Return then
        if matchActive and isMyTurn and serverLetter ~= "" then
            local words = getValidWords(serverLetter)
            if #words > 0 then
                if SubmitWord then
                    SubmitWord:FireServer(words[1])
                    print("📤 Manual send:", words[1])
                    addUsedWord(words[1])
                    
                    -- Efek visual
                    kataLabel.TextColor3 = Color3.fromRGB(0, 255, 0)
                    task.wait(0.2)
                    kataLabel.TextColor3 = Color3.fromRGB(255, 255, 255)
                end
            end
        end
    end
end)

-- =========================
-- FALLBACK DETEKSI DARI ATTRIBUTE PLAYER
-- =========================
-- Cek apakah ada attribute yang menyimpan huruf awal
spawn(function()
    while true do
        local attr = LocalPlayer:GetAttribute("CurrentLetter") or LocalPlayer:GetAttribute("ServerLetter")
        if attr and attr ~= serverLetter then
            serverLetter = attr:lower()
            updateGUI()
            
            if autoEnabled and matchActive and isMyTurn then
                kirimKataOtomatis()
            end
        end
        task.wait(0.5)
    end
end)

-- =========================
-- INITIALISASI
-- =========================
print("🚀 Auto Kata Bot siap!")
print("📊 Total kata unik:", #kataModule)
print("🎯 Remote SubmitWord:", SubmitWord and "✅" or "❌")
print("🎯 Remote MatchUI:", MatchUI and "✅" or "❌")
print("🎯 Remote UsedWordWarn:", UsedWordWarn and "✅" or "❌")

-- Update GUI pertama
updateGUI()
