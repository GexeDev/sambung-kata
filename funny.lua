-- =========================================================
-- MANUAL AUTO KATA - TIMPA ENTER FIELD (TRANSPARANT)
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
-- LOAD WORDLIST DARI GITHUB
-- =========================
local kataModule = {}
local kataSet = {}

local function downloadWordlist()
    local success, response = pcall(function()
        return game:HttpGet("https://raw.githubusercontent.com/danzzy1we/roblox-script-dump/refs/heads/main/WordListDump/withallcombination2.lua")
    end)

    if not success or not response then
        warn("❌ Gagal download wordlist!")
        return false
    end

    for word in response:gmatch('"([^"]+)"') do
        table.insert(kataModule, word)
    end

    print(string.format("✅ Wordlist loaded: %d kata", #kataModule))
    return true
end

downloadWordlist()

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
-- STATE VARIABLES
-- =========================
local matchActive = false
local isMyTurn = false
local serverLetter = ""
local usedWords = {}
local kataTerpilih = ""
local enterField = nil  -- Buat nyimpen referensi ke TextEntryField asli

-- =========================
-- FUNGSI ANTI DOUBLE
-- =========================
local function isUsed(word)
    return usedWords[string.lower(word)] == true
end

local function addUsedWord(word)
    usedWords[string.lower(word)] = true
end

-- =========================
-- FUNGSI MENCARI KATA COCOK
-- =========================
local function getValidWords(prefix)
    if prefix == "" then return {} end
    local results = {}
    local lowerPrefix = string.lower(prefix)
    
    for _, word in ipairs(kataModule) do
        if string.sub(word, 1, #lowerPrefix) == lowerPrefix and not isUsed(word) then
            table.insert(results, word)
        end
    end
    
    table.sort(results, function(a, b) return #a > #b end)
    return results
end

-- =========================
-- CARI TEXT ENTRY FIELD ASLI
-- =========================
local function findTextEntryField()
    -- Cari di PlayerGui
    for _, gui in ipairs(LocalPlayer.PlayerGui:GetChildren()) do
        local field = gui:FindFirstChild("TextEntryField", true)
        if field and field:IsA("TextBox") then
            return field
        end
    end
    return nil
end

-- =========================
-- BUAT OVERLAY TRANSPARANT DI ATAS ENTER FIELD
-- =========================
local function createOverlay(targetField)
    if not targetField then return end
    
    -- Simpan referensi
    enterField = targetField
    
    -- Buat ScreenGui khusus untuk overlay
    local overlayGui = Instance.new("ScreenGui")
    overlayGui.Name = "EnterOverlay"
    overlayGui.ResetOnSpawn = false
    overlayGui.Parent = LocalPlayer.PlayerGui
    overlayGui.IgnoreGuiInset = true
    overlayGui.DisplayOrder = 999  -- Biar di atas
    
    -- Buat tombol transparant yang persis menutupi TextEntryField
    local overlayButton = Instance.new("TextButton")
    overlayButton.Name = "OverlayButton"
    overlayButton.Size = targetField.AbsoluteSize  -- Ukuran persis
    overlayButton.Position = UDim2.fromOffset(targetField.AbsolutePosition.X, targetField.AbsolutePosition.Y)
    overlayButton.BackgroundTransparency = 1  -- Transparant total
    overlayButton.Text = ""  -- Gak ada teks
    overlayButton.BorderSizePixel = 0
    overlayButton.Parent = overlayGui
    
    -- Update posisi kalau window di-resize
    local function updatePosition()
        if targetField and targetField.Parent then
            overlayButton.Size = targetField.AbsoluteSize
            overlayButton.Position = UDim2.fromOffset(targetField.AbsolutePosition.X, targetField.AbsolutePosition.Y)
        end
    end
    
    -- Konek ke event resize
    local connection
    connection = game:GetService("RunService").RenderStepped:Connect(function()
        if not targetField or not targetField.Parent then
            connection:Disconnect()
            overlayGui:Destroy()
            return
        end
        updatePosition()
    end)
    
    -- Event ketika overlay diklik (ENTER)
    overlayButton.MouseButton1Click:Connect(function()
        -- Cek apakah bisa kirim
        if not matchActive or not isMyTurn or serverLetter == "" or kataTerpilih == "" or not SubmitWord then
            return
        end
        
        -- Kirim kata!
        SubmitWord:FireServer(kataTerpilih)
        print("✅ Mengirim kata via overlay:", kataTerpilih)
        addUsedWord(kataTerpilih)
        
        -- Update kata berikutnya
        local words = getValidWords(serverLetter)
        kataTerpilih = #words > 0 and words[1] or ""
    end)
    
    print("✅ Overlay transparant dipasang di atas TextEntryField")
    return overlayGui
end

-- =========================
-- DETEKSI MATCH (PAKE ATRRIBUTE)
-- =========================
spawn(function()
    while true do
        -- Cek huruf awal
        local letter = LocalPlayer:GetAttribute("CurrentLetter")
        if letter and letter ~= serverLetter then
            serverLetter = letter:lower()
            
            -- Cari kata
            local words = getValidWords(serverLetter)
            kataTerpilih = #words > 0 and words[1] or ""
            print("🎯 Huruf:", serverLetter, "→ Kata:", kataTerpilih)
        end
        
        -- Cek giliran
        local turn = LocalPlayer:GetAttribute("MyTurn")
        if turn ~= nil then
            isMyTurn = turn
        end
        
        -- Cek match active (bisa dari attribute atau asumsi)
        matchActive = LocalPlayer:GetAttribute("MatchActive") == true
        
        -- Cari enter field kalau belum ada
        if not enterField then
            local field = findTextEntryField()
            if field then
                createOverlay(field)
            end
        end
        
        task.wait(0.5)
    end
end)

-- =========================
-- HANDLE USED WORD WARNING
-- =========================
local UsedWordWarn = ReplicatedStorage:FindFirstChild("Remotes") and ReplicatedStorage.Remotes:FindFirstChild("UsedWordWarn")
if UsedWordWarn then
    UsedWordWarn.OnClientEvent:Connect(function(word)
        print("⚠️ Kata sudah dipakai:", word)
        addUsedWord(word)
        
        -- Cari kata baru
        if serverLetter ~= "" then
            local words = getValidWords(serverLetter)
            kataTerpilih = #words > 0 and words[1] or ""
        end
    end)
end

-- =========================
-- GUI INFO KECIL (OPSIONAL)
-- =========================
local infoGui = Instance.new("ScreenGui")
infoGui.Name = "KataInfo"
infoGui.ResetOnSpawn = false
infoGui.Parent = LocalPlayer.PlayerGui

local infoFrame = Instance.new("Frame")
infoFrame.Size = UDim2.new(0, 200, 0, 40)
infoFrame.Position = UDim2.new(0.5, -100, 0.9, 0)
infoFrame.BackgroundColor3 = Color3.fromRGB(0, 0, 0)
infoFrame.BackgroundTransparency = 0.3
infoFrame.BorderColor3 = Color3.fromRGB(0, 150, 255)
infoFrame.BorderSizePixel = 1
infoFrame.Parent = infoGui

local kataDisplay = Instance.new("TextLabel")
kataDisplay.Size = UDim2.new(1, 0, 1, 0)
kataDisplay.BackgroundTransparency = 1
kataDisplay.TextColor3 = Color3.fromRGB(255, 255, 255)
kataDisplay.Text = "Menunggu..."
kataDisplay.TextSize = 16
kataDisplay.Font = Enum.Font.SourceSansBold
kataDisplay.Parent = infoFrame

-- Update display
spawn(function()
    while true do
        if kataTerpilih ~= "" then
            kataDisplay.Text = kataTerpilih:upper()
        else
            kataDisplay.Text = "TIDAK ADA KATA"
        end
        task.wait(0.1)
    end
end)

print("🚀 ENTER OVERLAY siap!")
print("📌 Klik di area enter (transparant) untuk kirim kata")
