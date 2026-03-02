-- =========================================================
-- TIMPA TOMBOL ENTER (VERSI FIX - PASTI KELUAR)
-- =========================================================

if not game:IsLoaded() then game.Loaded:Wait() end

local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Players = game:GetService("Players")
local LocalPlayer = Players.LocalPlayer
local HttpService = game:GetService("HttpService")

-- =========================
-- REMOTE SUBMIT WORD
-- =========================
local SubmitWord = ReplicatedStorage:FindFirstChild("Remotes") and ReplicatedStorage.Remotes:FindFirstChild("SubmitWord")
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
            table.insert(kataModule, word)
        end
        print("✅ Wordlist loaded: " .. #kataModule .. " kata siap!")
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

-- =========================
-- FUNGSI CARI KATA (TERPANJANG + ANTI DOUBLE)
-- =========================
local function getKata(prefix)
    if prefix == "" then return "" end
    local lowerPrefix = string.lower(prefix)
    local candidates = {}
    
    for _, word in ipairs(kataModule) do
        if string.sub(word, 1, #lowerPrefix) == lowerPrefix and not usedWords[word] then
            table.insert(candidates, word)
        end
    end
    
    if #candidates > 0 then
        -- Urutkan dari terpanjang
        table.sort(candidates, function(a, b) return #a > #b end)
        return candidates[1]
    end
    return ""
end

-- =========================
-- DETEKSI GILIRAN (PAKE ATTRIBUTE)
-- =========================
spawn(function()
    while true do
        local letter = LocalPlayer:GetAttribute("CurrentLetter")
        if letter and letter ~= serverLetter then
            serverLetter = letter:lower()
            kataTerpilih = getKata(serverLetter)
            print("🎯 Huruf:", serverLetter, "→ Kata:", kataTerpilih)
        end
        
        isMyTurn = LocalPlayer:GetAttribute("MyTurn") == true
        matchActive = LocalPlayer:GetAttribute("MatchActive") == true
        
        task.wait(0.3)
    end
end)

-- =========================
-- HANDLE USED WORD WARNING
-- =========================
local UsedWordWarn = ReplicatedStorage:FindFirstChild("Remotes") and ReplicatedStorage.Remotes:FindFirstChild("UsedWordWarn")
if UsedWordWarn then
    UsedWordWarn.OnClientEvent:Connect(function(word)
        print("⚠️ Kata sudah dipakai:", word)
        usedWords[word] = true
        if serverLetter ~= "" then
            kataTerpilih = getKata(serverLetter)
        end
    end)
end

-- =========================
-- BUAT GUI UTAMA (PASTI MUNCUL)
-- =========================
local gui = Instance.new("ScreenGui")
gui.Name = "EnterButtonFix"
gui.ResetOnSpawn = false
gui.Parent = LocalPlayer:WaitForChild("PlayerGui")
gui.IgnoreGuiInset = true
gui.DisplayOrder = 9999  -- PALING ATAS

-- =========================
-- 1. PREVIEW KATA (DI ATAS, BENTUK LONJONG)
-- =========================
local previewFrame = Instance.new("Frame")
previewFrame.Name = "PreviewKata"
previewFrame.Size = UDim2.new(0, 280, 0, 80)
previewFrame.Position = UDim2.new(0.5, -140, 0.03, 0)  -- di atas tengah
previewFrame.BackgroundColor3 = Color3.fromRGB(25, 25, 25)  -- abu-abu gelap
previewFrame.BackgroundTransparency = 0.1
previewFrame.BorderSizePixel = 0
previewFrame.Parent = gui

-- Bikin LONJONG (tidak ada siku)
local previewCorner = Instance.new("UICorner")
previewCorner.CornerRadius = UDim.new(0.5, 0)  -- oval sempurna
previewCorner.Parent = previewFrame

-- Stroke biru tipis biar elegan
local previewStroke = Instance.new("UIStroke")
previewStroke.Color = Color3.fromRGB(0, 150, 255)
previewStroke.Thickness = 1.5
previewStroke.Transparency = 0.3
previewStroke.Parent = previewFrame

-- Huruf awal (besar di kiri)
local hurufLabel = Instance.new("TextLabel")
hurufLabel.Name = "HurufAwal"
hurufLabel.Size = UDim2.new(0.25, 0, 1, 0)
hurufLabel.BackgroundTransparency = 1
hurufLabel.Text = "?"
hurufLabel.TextColor3 = Color3.fromRGB(0, 150, 255)
hurufLabel.TextSize = 48
hurufLabel.Font = Enum.Font.SourceSansBold
hurufLabel.Parent = previewFrame

-- Kata yang akan dikirim (di kanan)
local kataPreview = Instance.new("TextLabel")
kataPreview.Name = "KataTerpilih"
kataPreview.Size = UDim2.new(0.75, 0, 1, 0)
kataPreview.Position = UDim2.new(0.25, 0, 0, 0)
kataPreview.BackgroundTransparency = 1
kataPreview.Text = "LOADING..."
kataPreview.TextColor3 = Color3.fromRGB(255, 255, 255)
kataPreview.TextSize = 20
kataPreview.Font = Enum.Font.SourceSansBold
kataPreview.TextWrapped = true
kataPreview.Parent = previewFrame

-- Status kecil di bawah preview
local statusPreview = Instance.new("TextLabel")
statusPreview.Name = "Status"
statusPreview.Size = UDim2.new(1, -20, 0, 20)
statusPreview.Position = UDim2.new(0, 10, 1, 5)
statusPreview.BackgroundTransparency = 1
statusPreview.Text = "Menunggu giliran..."
statusPreview.TextColor3 = Color3.fromRGB(150, 150, 150)
statusPreview.TextSize = 12
statusPreview.Font = Enum.Font.SourceSans
statusPreview.TextXAlignment = Enum.TextXAlignment.Left
statusPreview.Parent = previewFrame

-- =========================
-- 2. TOMBOL ENTER TIRUAN (PASTI MUNCUL DI KANAN BAWAH)
-- =========================
local enterFrame = Instance.new("Frame")
enterFrame.Name = "FakeEnter"
enterFrame.Size = UDim2.new(0, 120, 0, 60)  -- ukuran standar tombol Enter
enterFrame.Position = UDim2.new(1, -140, 1, -80)  -- kanan bawah
enterFrame.BackgroundColor3 = Color3.fromRGB(35, 35, 35)  -- abu-abu gelap
enterFrame.BackgroundTransparency = 0.1
enterFrame.BorderSizePixel = 0
enterFrame.Parent = gui

-- Bikin LONJONG (sesuai screenshot)
local enterCorner = Instance.new("UICorner")
enterCorner.CornerRadius = UDim.new(0.5, 0)  -- oval
enterCorner.Parent = enterFrame

-- Stroke tipis
local enterStroke = Instance.new("UIStroke")
enterStroke.Color = Color3.fromRGB(0, 150, 255)
enterStroke.Thickness = 1.5
enterStroke.Transparency = 0.5
enterStroke.Parent = enterFrame

-- Efek shadow (biar keliatan timbul)
local shadow = Instance.new("ImageLabel")
shadow.Size = UDim2.new(1, 10, 1, 10)
shadow.Position = UDim2.new(0, -5, 0, -5)
shadow.BackgroundTransparency = 1
shadow.Image = "rbxassetid://1316045217"
shadow.ImageColor3 = Color3.fromRGB(0, 0, 0)
shadow.ImageTransparency = 0.6
shadow.ZIndex = -1
shadow.Parent = enterFrame

-- Teks ENTER
local enterText = Instance.new("TextLabel")
enterText.Size = UDim2.new(1, 0, 0.6, 0)
enterText.Position = UDim2.new(0, 0, 0, 5)
enterText.BackgroundTransparency = 1
enterText.Text = "ENTER"
enterText.TextColor3 = Color3.fromRGB(220, 220, 220)
enterText.TextSize = 22
enterText.Font = Enum.Font.SourceSansBold
enterText.Parent = enterFrame

-- Preview kata kecil di tombol (opsional)
local miniPreview = Instance.new("TextLabel")
miniPreview.Name = "MiniKata"
miniPreview.Size = UDim2.new(1, 0, 0.3, 0)
miniPreview.Position = UDim2.new(0, 0, 0.6, 0)
miniPreview.BackgroundTransparency = 1
miniPreview.Text = ""
miniPreview.TextColor3 = Color3.fromRGB(0, 150, 255)
miniPreview.TextSize = 12
miniPreview.Font = Enum.Font.SourceSans
miniPreview.Parent = enterFrame

-- =========================
-- FUNGSI UPDATE GUI
-- =========================
local function updateGUI()
    -- Update huruf awal
    hurufLabel.Text = serverLetter ~= "" and serverLetter:upper() or "?"
    
    -- Update kata preview
    if kataTerpilih ~= "" then
        kataPreview.Text = kataTerpilih:upper()
        miniPreview.Text = kataTerpilih:upper()
    else
        if serverLetter ~= "" then
            kataPreview.Text = "TIDAK ADA KATA"
            kataPreview.TextColor3 = Color3.fromRGB(255, 0, 0)
        else
            kataPreview.Text = "MENUNGGU HURUF..."
            kataPreview.TextColor3 = Color3.fromRGB(255, 255, 255)
        end
        miniPreview.Text = ""
    end
    
    -- Update status
    if not matchActive then
        statusPreview.Text = "⏳ Menunggu match..."
    elseif not isMyTurn then
        statusPreview.Text = "🟡 Giliran opponent"
    else
        statusPreview.Text = "🔵 GILIRAN ANDA - Tekan ENTER"
    end
    
    -- Update warna tombol berdasarkan status
    if matchActive and isMyTurn and kataTerpilih ~= "" then
        enterFrame.BackgroundColor3 = Color3.fromRGB(45, 45, 45)  -- lebih terang
        enterText.TextColor3 = Color3.fromRGB(0, 255, 0)  -- hijau
    else
        enterFrame.BackgroundColor3 = Color3.fromRGB(35, 35, 35)  -- normal
        enterText.TextColor3 = Color3.fromRGB(150, 150, 150)  -- abu-abu
    end
end

-- Update setiap 0.2 detik
spawn(function()
    while true do
        updateGUI()
        task.wait(0.2)
    end
end)

-- =========================
-- EVENT KLIK TOMBOL ENTER
-- =========================
enterFrame.InputBegan:Connect(function(input)
    if input.UserInputType == Enum.UserInputType.MouseButton1 or input.UserInputType == Enum.UserInputType.Touch then
        -- Efek tekan
        enterFrame.BackgroundColor3 = Color3.fromRGB(60, 60, 60)
        enterText.TextColor3 = Color3.fromRGB(255, 255, 255)
    end
end)

enterFrame.InputEnded:Connect(function(input)
    if input.UserInputType == Enum.UserInputType.MouseButton1 or input.UserInputType == Enum.UserInputType.Touch then
        -- Kembalikan warna
        updateGUI()  -- biar balik ke warna sesuai status
        
        -- CEK DAN KIRIM!
        if not SubmitWord then
            warn("❌ SubmitWord tidak ditemukan!")
            return
        end
        
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
            print("⛔ Tidak ada kata tersedia")
            return
        end
        
        -- KIRIM!
        SubmitWord:FireServer(kataTerpilih)
        print("✅ MENGIRIM KATA:", kataTerpilih)
        
        -- Tandai sebagai sudah dipakai
        usedWords[kataTerpilih] = true
        
        -- Cari kata baru untuk berikutnya
        kataTerpilih = getKata(serverLetter)
        
        -- Efek kedip sukses
        enterFrame.BackgroundColor3 = Color3.fromRGB(0, 150, 255)
        task.wait(0.1)
        updateGUI()
    end
end)

-- =========================
-- ADAPTASI POSISI (KALO KETEMU TOMBOL ASLI)
-- =========================
spawn(function()
    task.wait(2)  -- tunggu 2 detik
    
    -- Coba cari tombol Enter asli
    local found = false
    for _, gui in ipairs(LocalPlayer.PlayerGui:GetChildren()) do
        local enterBtn = gui:FindFirstChild("Enter", true) or gui:FindFirstChild("enter", true)
        if enterBtn and enterBtn:IsA("TextButton") then
            -- Ketemu! Update posisi tombol tiruan
            local absPos = enterBtn.AbsolutePosition
            local absSize = enterBtn.AbsoluteSize
            
            enterFrame.Size = UDim2.fromOffset(absSize.X, absSize.Y)
            enterFrame.Position = UDim2.fromOffset(absPos.X, absPos.Y)
            
            print("✅ Tombol Enter asli ditemukan, posisi disesuaikan")
            found = true
            break
        end
    end
    
    if not found then
        print("ℹ️ Tombol Enter asli tidak ditemukan, pakai posisi default (kanan bawah)")
    end
end)

-- =========================
-- INIT
-- =========================
print("🚀 ENTER BOT SIAP!")
print("📌 Preview kata di ATAS, tombol ENTER abu-abu di kanan bawah")
print("📌 Tinggal klik tombol ENTER tiruan, otomatis kirim kata bener!")
