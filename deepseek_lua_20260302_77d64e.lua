-- =========================================================
-- MANUAL AUTO KATA - KETIK NGASAL + ENTER KIRIM KATA BENER
-- (DENGAN ANTI DOUBLE + WORDLIST EKSTERNAL + GUI KECIL)
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
-- LOAD WORDLIST DARI GITHUB LU (withallcombination2.lua)
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
    warn("❌ Gagal load wordlist! Pakai database minimal...")
    kataModule = {"error", "loading", "wordlist"} -- Fallback kecil
end

-- =========================
-- REMOTE EVENTS (DARI JEMPUT.LUA)
-- =========================
local remotes = ReplicatedStorage:FindFirstChild("Remotes")
if not remotes then
    remotes = Instance.new("Folder")
    remotes.Name = "Remotes"
    remotes.Parent = ReplicatedStorage
end

-- Cari remote yang dibutuhkan
local MatchUI = remotes:FindFirstChild("MatchUI") 
local SubmitWord = remotes:FindFirstChild("SubmitWord")
local BillboardUpdate = remotes:FindFirstChild("BillboardUpdate")
local BillboardEnd = remotes:FindFirstChild("BillboardEnd")
local TypeSound = remotes:FindFirstChild("TypeSound")
local UsedWordWarn = remotes:FindFirstChild("UsedWordWarn")

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
local usedWords = {}      -- Set untuk kata yang sudah dipakai
local usedWordsList = {}  -- List untuk ditampilkan
local kataTerpilih = ""   -- Kata yang akan dikirim saat ENTER
local autoEnabled = true  -- Auto aktif default

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
-- FUNGSI UPDATE KATA TERPILIH
-- =========================
local function updateKataTerpilih()
    if serverLetter == "" then
        kataTerpilih = ""
        return
    end

    local words = getValidWords(serverLetter)
    if #words > 0 then
        kataTerpilih = words[1]  -- Ambil kata terpanjang
    else
        kataTerpilih = ""
    end
end

-- =========================
-- MEMBUAT GUI MINIMALIS
-- =========================
local screenGui = Instance.new("ScreenGui")
screenGui.Name = "ManualKataBot"
screenGui.ResetOnSpawn = false
screenGui.Parent = LocalPlayer:WaitForChild("PlayerGui")

local mainFrame = Instance.new("Frame")
mainFrame.Size = UDim2.new(0, 260, 0, 180)
mainFrame.Position = UDim2.new(0.5, -130, 0.1, 0)
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
title.Text = "⌨️ MANUAL KATA BOT (ENTER KIRIM)"
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
hurufLabel.Size = UDim2.new(0, 50, 0, 35)
hurufLabel.Position = UDim2.new(0, 5, 0, 50)
hurufLabel.BackgroundColor3 = Color3.fromRGB(15, 15, 15)
hurufLabel.TextColor3 = Color3.fromRGB(0, 150, 255)
hurufLabel.Text = "?"
hurufLabel.TextSize = 20
hurufLabel.Font = Enum.Font.SourceSansBold
hurufLabel.BorderColor3 = Color3.fromRGB(0, 150, 255)
hurufLabel.BorderSizePixel = 1
hurufLabel.Parent = mainFrame

-- Kata yang akan dikirim
local kataLabel = Instance.new("TextLabel")
kataLabel.Name = "Kata"
kataLabel.Size = UDim2.new(0, 190, 0, 35)
kataLabel.Position = UDim2.new(0, 60, 0, 50)
kataLabel.BackgroundColor3 = Color3.fromRGB(15, 15, 15)
kataLabel.TextColor3 = Color3.fromRGB(255, 255, 255)
kataLabel.Text = "Menunggu huruf..."
kataLabel.TextSize = 14
kataLabel.Font = Enum.Font.SourceSansBold
kataLabel.BorderColor3 = Color3.fromRGB(0, 150, 255)
kataLabel.BorderSizePixel = 1
kataLabel.Parent = mainFrame

-- Informasi
local infoLabel = Instance.new("TextLabel")
infoLabel.Size = UDim2.new(1, -10, 0, 18)
infoLabel.Position = UDim2.new(0, 5, 0, 90)
infoLabel.BackgroundColor3 = Color3.fromRGB(0, 0, 0)
infoLabel.TextColor3 = Color3.fromRGB(150, 150, 150)
infoLabel.Text = "💡 Ketik NGASAL, tekan ENTER → kirim kata di atas"
infoLabel.TextSize = 10
infoLabel.TextXAlignment = Enum.TextXAlignment.Left
infoLabel.Parent = mainFrame

-- Toggle Auto
local toggleButton = Instance.new("TextButton")
toggleButton.Size = UDim2.new(0, 80, 0, 25)
toggleButton.Position = UDim2.new(0, 5, 0, 115)
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
    else
        toggleButton.Text = "❌ AUTO OFF"
        toggleButton.BackgroundColor3 = Color3.fromRGB(150, 0, 0)
    end
end)

-- Kata terpakai counter
local usedCounter = Instance.new("TextLabel")
usedCounter.Name = "UsedCounter"
usedCounter.Size = UDim2.new(0, 80, 0, 25)
usedCounter.Position = UDim2.new(0, 95, 0, 115)
usedCounter.BackgroundColor3 = Color3.fromRGB(15, 15, 15)
usedCounter.TextColor3 = Color3.fromRGB(255, 255, 0)
usedCounter.Text = "📋 0"
usedCounter.TextSize = 11
usedCounter.Font = Enum.Font.SourceSansBold
usedCounter.BorderColor3 = Color3.fromRGB(0, 150, 255)
usedCounter.BorderSizePixel = 1
usedCounter.Parent = mainFrame

-- Wordlist info
local wordlistInfo = Instance.new("TextLabel")
wordlistInfo.Size = UDim2.new(0, 160, 0, 18)
wordlistInfo.Position = UDim2.new(0, 5, 0, 150)
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
    if matchActive then
        if isMyTurn then
            statusLabel.Text = "Status: 🔵 GILIRAN ANDA"
            statusLabel.TextColor3 = Color3.fromRGB(0, 255, 0)
        else
            statusLabel.Text = "Status: 🟡 Giliran opponent"
            statusLabel.TextColor3 = Color3.fromRGB(255, 255, 0)
        end
    else
        statusLabel.Text = "Status: ⚫ Menunggu match..."
        statusLabel.TextColor3 = Color3.fromRGB(200, 200, 200)
    end

    hurufLabel.Text = serverLetter ~= "" and serverLetter:upper() or "?"
    
    -- Update kata yang akan dikirim
    updateKataTerpilih()
    if kataTerpilih ~= "" then
        kataLabel.Text = kataTerpilih:upper()
        kataLabel.TextColor3 = Color3.fromRGB(255, 255, 255)
    else
        if serverLetter ~= "" then
            kataLabel.Text = "TIDAK ADA KATA"
            kataLabel.TextColor3 = Color3.fromRGB(255, 0, 0)
        else
            kataLabel.Text = "MENUNGGU HURUF..."
            kataLabel.TextColor3 = Color3.fromRGB(255, 255, 255)
        end
    end
    
    -- Update counter kata terpakai
    usedCounter.Text = "📋 " .. #usedWordsList
end

-- =========================
-- DETEKSI REMOTE EVENTS (DARI JEMPUT.LUA)
-- =========================

-- MatchUI event
if MatchUI then
    MatchUI.OnClientEvent:Connect(function(cmd, value)
        print("MatchUI:", cmd, value)

        if cmd == "ShowMatchUI" then
            matchActive = true
            isMyTurn = false
            resetUsedWords()
            updateGUI()

        elseif cmd == "HideMatchUI" then
            matchActive = false
            isMyTurn = false
            serverLetter = ""
            updateGUI()

        elseif cmd == "UpdateServerLetter" then
            serverLetter = value
            updateGUI()

        elseif cmd == "StartTurn" then
            isMyTurn = true
            updateGUI()

        elseif cmd == "EndTurn" then
            isMyTurn = false
            updateGUI()
        end
    end)
end

-- Fallback: cek atribut player kalau remote gak ada
if not MatchUI then
    spawn(function()
        while true do
            local attr = LocalPlayer:GetAttribute("CurrentLetter")
            if attr and attr ~= serverLetter then
                serverLetter = attr:lower()
                matchActive = true
                updateGUI()
            end
            
            local turnAttr = LocalPlayer:GetAttribute("MyTurn")
            if turnAttr ~= nil then
                isMyTurn = turnAttr
                updateGUI()
            end
            task.wait(0.5)
        end
    end)
end

-- =========================
-- HANDLE USED WORD WARNING
-- =========================
if UsedWordWarn then
    UsedWordWarn.OnClientEvent:Connect(function(word)
        print("⚠️ Kata sudah dipakai:", word)
        addUsedWord(word)
        
        -- Update kata terpilih dengan kata baru
        updateKataTerpilih()
        updateGUI()
        
        -- Efek merah di GUI
        kataLabel.TextColor3 = Color3.fromRGB(255, 0, 0)
        task.wait(0.3)
        kataLabel.TextColor3 = Color3.fromRGB(255, 255, 255)
    end)
end

-- =========================
-- DETEKSI KEYBOARD ENTER - FITUR UTAMA!
-- =========================
UserInputService.InputBegan:Connect(function(input, gameProcessed)
    if gameProcessed then return end
    
    -- Deteksi tombol Enter
    if input.KeyCode == Enum.KeyCode.Return then
        -- Cek apakah bisa kirim
        if not matchActive then
            print("⛔ Belum ada match")
            return
        end
        
        if not isMyTurn then
            print("⛔ Bukan giliran anda")
            return
        end
        
        if serverLetter == "" then
            print("⛔ Belum ada huruf awal")
            return
        end
        
        if kataTerpilih == "" then
            print("⛔ Tidak ada kata tersedia untuk huruf:", serverLetter)
            return
        end
        
        if not autoEnabled then
            print("⛔ Auto disabled, nyalakan dulu")
            return
        end
        
        if not SubmitWord then
            warn("❌ Remote SubmitWord tidak ditemukan!")
            return
        end
        
        -- KIRIM KATA!
        SubmitWord:FireServer(kataTerpilih)
        print("✅ Mengirim kata:", kataTerpilih)
        
        -- Tambahkan ke daftar kata terpakai
        addUsedWord(kataTerpilih)
        
        -- Efek visual di GUI
        kataLabel.TextColor3 = Color3.fromRGB(0, 255, 0)
        task.wait(0.2)
        kataLabel.TextColor3 = Color3.fromRGB(255, 255, 255)
        
        -- Update GUI untuk kata berikutnya
        updateGUI()
        
        -- Optional: kirim billboard end kalau ada
        if BillboardEnd then
            pcall(function()
                BillboardEnd:FireServer()
            end)
        end
    end
end)

-- =========================
-- INITIAL UPDATE
-- =========================
updateGUI()
print("🚀 MANUAL KATA BOT siap!")
print("📌 Cara pakai: Ketik NGASAL di keyboard, tekan ENTER, bot kirim kata bener!")
print("📌 Total kata:", #kataModule)