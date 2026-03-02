-- =========================================================
-- ENTER BOT V5 - KATA TERPENDEK (AMAN)
-- =========================================================

if not game:IsLoaded() then game.Loaded:Wait() end

local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Players = game:GetService("Players")
local LocalPlayer = Players.LocalPlayer
local HttpService = game:GetService("HttpService")

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

-- =========================
-- FUNGSI CARI KATA (TERPENDEK - DIUBAH!)
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
        -- UBAH: dari terpanjang → terpendek
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
            print("✅ Match active!")
            
        elseif cmd == "HideMatchUI" then
            matchActive = false
            isMyTurn = false
            serverLetter = ""
            print("⏸️ Match ended")
            
        elseif cmd == "UpdateServerLetter" then
            serverLetter = value:lower()
            kataTerpilih = getKata(serverLetter)
            print("🎯 Huruf awal:", serverLetter, "→ Kata (terpendek):", kataTerpilih)
            
        elseif cmd == "StartTurn" then
            isMyTurn = true
            print("🔵 Giliran anda!")
            
        elseif cmd == "EndTurn" then
            isMyTurn = false
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
                kataTerpilih = getKata(serverLetter)
            end
            
            local turn = LocalPlayer:GetAttribute("MyTurn")
            if turn ~= nil then
                isMyTurn = turn
            end
            
            local active = LocalPlayer:GetAttribute("MatchActive")
            if active ~= nil then
                matchActive = active
            end
            
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
        if serverLetter ~= "" then
            kataTerpilih = getKata(serverLetter)
        end
    end)
end

-- =========================
-- BUAT GUI (FIXED POSITION)
-- =========================
local gui = Instance.new("ScreenGui")
gui.Name = "EnterBot"
gui.ResetOnSpawn = false
gui.Parent = LocalPlayer:WaitForChild("PlayerGui")
gui.IgnoreGuiInset = true
gui.DisplayOrder = 9999

-- =========================
-- 1. PREVIEW KATA (ATAS TENGAH)
-- =========================
local previewFrame = Instance.new("Frame")
previewFrame.Name = "PreviewKata"
previewFrame.Size = UDim2.new(0, 200, 0, 50)
previewFrame.Position = UDim2.new(0.5, -100, 0.02, 0)
previewFrame.BackgroundColor3 = Color3.fromRGB(25, 25, 25)
previewFrame.BackgroundTransparency = 0.1
previewFrame.BorderSizePixel = 0
previewFrame.Parent = gui

-- Bikin lonjong
local previewCorner = Instance.new("UICorner")
previewCorner.CornerRadius = UDim.new(0.5, 0)
previewCorner.Parent = previewFrame

-- Stroke biru
local previewStroke = Instance.new("UIStroke")
previewStroke.Color = Color3.fromRGB(0, 150, 255)
previewStroke.Thickness = 1.5
previewStroke.Transparency = 0.3
previewStroke.Parent = previewFrame

-- Huruf awal (di kiri)
local hurufLabel = Instance.new("TextLabel")
hurufLabel.Size = UDim2.new(0.3, 0, 1, 0)
hurufLabel.BackgroundTransparency = 1
hurufLabel.Text = "?"
hurufLabel.TextColor3 = Color3.fromRGB(0, 150, 255)
hurufLabel.TextSize = 30
hurufLabel.Font = Enum.Font.SourceSansBold
hurufLabel.Parent = previewFrame

-- Kata preview (di kanan)
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

-- Status kecil
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
-- 2. TOMBOL ENTER (ATAS KANAN - FIXED)
-- =========================
local enterFrame = Instance.new("Frame")
enterFrame.Name = "FakeEnter"
enterFrame.Size = UDim2.new(0, 150, 0, 70)
enterFrame.Position = UDim2.new(1, -170, 0.02, 0)
enterFrame.BackgroundColor3 = Color3.fromRGB(35, 35, 35)
enterFrame.BackgroundTransparency = 0.1
enterFrame.BorderSizePixel = 0
enterFrame.Parent = gui

-- Bikin lonjong
local enterCorner = Instance.new("UICorner")
enterCorner.CornerRadius = UDim.new(0.5, 0)
enterCorner.Parent = enterFrame

-- Stroke biru
local enterStroke = Instance.new("UIStroke")
enterStroke.Color = Color3.fromRGB(0, 150, 255)
enterStroke.Thickness = 2
enterStroke.Transparency = 0.5
enterStroke.Parent = enterFrame

-- Shadow
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
enterText.Size = UDim2.new(1, 0, 0.5, 0)
enterText.Position = UDim2.new(0, 0, 0, 8)
enterText.BackgroundTransparency = 1
enterText.Text = "ENTER"
enterText.TextColor3 = Color3.fromRGB(220, 220, 220)
enterText.TextSize = 24
enterText.Font = Enum.Font.SourceSansBold
enterText.Parent = enterFrame

-- Preview kata kecil di tombol
local miniPreview = Instance.new("TextLabel")
miniPreview.Size = UDim2.new(1, 0, 0.3, 0)
miniPreview.Position = UDim2.new(0, 0, 0.55, 0)
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
    -- Update status match
    if matchActive then
        if isMyTurn then
            statusPreview.Text = "🔵 GILIRAN ANDA"
            statusPreview.TextColor3 = Color3.fromRGB(0, 255, 0)
        else
            statusPreview.Text = "🟡 Giliran opponent"
            statusPreview.TextColor3 = Color3.fromRGB(255, 255, 0)
        end
    else
        statusPreview.Text = "⚫ Menunggu match..."
        statusPreview.TextColor3 = Color3.fromRGB(150, 150, 150)
    end
    
    -- Update huruf awal
    hurufLabel.Text = serverLetter ~= "" and serverLetter:upper() or "?"
    
    -- Update kata preview
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
    
    -- Update warna tombol
    if matchActive and isMyTurn and kataTerpilih ~= "" then
        enterFrame.BackgroundColor3 = Color3.fromRGB(45, 45, 45)
        enterText.TextColor3 = Color3.fromRGB(0, 255, 0)
    else
        enterFrame.BackgroundColor3 = Color3.fromRGB(35, 35, 35)
        enterText.TextColor3 = Color3.fromRGB(150, 150, 150)
    end
end

-- Update tiap 0.1 detik
spawn(function()
    while true do
        updateGUI()
        task.wait(0.1)
    end
end)

-- =========================
-- EVENT KLIK TOMBOL ENTER
-- =========================
enterFrame.InputBegan:Connect(function(input)
    if input.UserInputType == Enum.UserInputType.MouseButton1 or input.UserInputType == Enum.UserInputType.Touch then
        enterFrame.BackgroundColor3 = Color3.fromRGB(60, 60, 60)
        enterText.TextColor3 = Color3.fromRGB(255, 255, 255)
    end
end)

enterFrame.InputEnded:Connect(function(input)
    if input.UserInputType == Enum.UserInputType.MouseButton1 or input.UserInputType == Enum.UserInputType.Touch then
        updateGUI()
        
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
        print("✅ MENGIRIM KATA (terpendek):", kataTerpilih)
        
        usedWords[kataTerpilih] = true
        kataTerpilih = getKata(serverLetter)
        
        -- Efek sukses
        enterFrame.BackgroundColor3 = Color3.fromRGB(0, 150, 255)
        task.wait(0.1)
        updateGUI()
    end
end)

-- =========================
-- INIT
-- =========================
print("🚀 ENTER BOT V5 - KATA TERPENDEK (AMAN)!")
print("📌 Preview kata: ATAS TENGAH (200x50)")
print("📌 Tombol Enter: ATAS KANAN (150x70) - FIXED")
print("📌 GAK PAKE KATA PANJANG - TERPENDEK BIAR AMAN!")
