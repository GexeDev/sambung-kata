-- =========================================================
-- SEARCH BAR AKHIRAN - MINIMALIS (LAST LETTER STYLE)
-- =========================================================

if not game:IsLoaded() then game.Loaded:Wait() end

local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Players = game:GetService("Players")
local LocalPlayer = Players.LocalPlayer
local HttpService = game:GetService("HttpService")
local UserInputService = game:GetService("UserInputService")

-- =========================
-- REMOTE EVENT UNTUK DETEKSI AWALAN
-- =========================
local remotes = ReplicatedStorage:FindFirstChild("Remotes")
if not remotes then
    remotes = Instance.new("Folder")
    remotes.Name = "Remotes"
    remotes.Parent = ReplicatedStorage
end

local MatchUI = remotes:FindFirstChild("MatchUI")
local SubmitWord = remotes:FindFirstChild("SubmitWord")

if not SubmitWord then
    for _, v in ipairs(ReplicatedStorage:GetDescendants()) do
        if v.Name == "SubmitWord" and v:IsA("RemoteEvent") then
            SubmitWord = v
            break
        end
    end
end

-- =========================
-- LOAD WORDLIST DARI GITHUB (100K+ KATA)
-- =========================
local kataModule = {}

local function downloadWordlist()
    local success, response = pcall(function()
        return game:HttpGet("https://raw.githubusercontent.com/danzzy1we/roblox-script-dump/refs/heads/main/WordListDump/withallcombination2.lua")
    end)
    
    if success and response then
        for word in response:gmatch('"([^"]+)"') do
            if #word > 1 then
                table.insert(kataModule, word:lower())
            end
        end
        print("✅ Wordlist loaded: " .. #kataModule .. " kata")
    else
        kataModule = {"gagal", "load", "wordlist"}
        print("❌ Gagal download wordlist")
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
local hasilFilter = {}

-- =========================
-- DETEKSI AWALAN DARI GAME
-- =========================
if MatchUI then
    MatchUI.OnClientEvent:Connect(function(cmd, value)
        if cmd == "ShowMatchUI" then
            matchActive = true
            isMyTurn = false
        elseif cmd == "HideMatchUI" then
            matchActive = false
            isMyTurn = false
            serverLetter = ""
        elseif cmd == "UpdateServerLetter" then
            serverLetter = value:lower()
        elseif cmd == "StartTurn" then
            isMyTurn = true
        elseif cmd == "EndTurn" then
            isMyTurn = false
        end
    end)
else
    -- Fallback ke attribute
    spawn(function()
        while true do
            local letter = LocalPlayer:GetAttribute("CurrentLetter")
            if letter and letter ~= serverLetter then
                serverLetter = letter:lower()
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
-- FUNGSI FILTER KATA BERDASARKAN AKHIRAN
-- =========================
local function filterKata(akhiran)
    hasilFilter = {}
    if akhiran == "" then return end
    
    local lowerAkhiran = akhiran:lower()
    
    for _, kata in ipairs(kataModule) do
        if #kata >= 4 and string.sub(kata, -#lowerAkhiran) == lowerAkhiran then
            table.insert(hasilFilter, kata)
        end
    end
    
    -- Urutkan dari terpendek
    table.sort(hasilFilter, function(a, b) return #a < #b end)
end

-- =========================
-- BUAT GUI MINIMALIS (LAST LETTER STYLE)
-- =========================
local gui = Instance.new("ScreenGui")
gui.Name = "AkhiranSearch"
gui.ResetOnSpawn = false
gui.Parent = LocalPlayer:WaitForChild("PlayerGui")
gui.IgnoreGuiInset = true
gui.DisplayOrder = 9999

-- Frame utama (ukuran kecil)
local mainFrame = Instance.new("Frame")
mainFrame.Size = UDim2.new(0, 220, 0, 280)
mainFrame.Position = UDim2.new(0.5, -110, 0.5, -140)  -- tengah layar
mainFrame.BackgroundColor3 = Color3.fromRGB(20, 20, 20)  -- abu-abu gelap
mainFrame.BorderColor3 = Color3.fromRGB(200, 200, 200)  -- outline putih tipis
mainFrame.BorderSizePixel = 1
mainFrame.Active = true
mainFrame.Draggable = true  -- bisa digeser
mainFrame.Parent = gui

-- Sudut sedikit melengkung
local mainCorner = Instance.new("UICorner")
mainCorner.CornerRadius = UDim.new(0, 6)
mainCorner.Parent = mainFrame

-- =========================
-- HEADER
-- =========================
local headerFrame = Instance.new("Frame")
headerFrame.Size = UDim2.new(1, -20, 0, 30)
headerFrame.Position = UDim2.new(0, 10, 0, 5)
headerFrame.BackgroundColor3 = Color3.fromRGB(30, 30, 30)
headerFrame.BorderSizePixel = 0
headerFrame.Parent = mainFrame

local headerCorner = Instance.new("UICorner")
headerCorner.CornerRadius = UDim.new(0, 4)
headerCorner.Parent = headerFrame

-- Huruf awal (dari game)
local hurufLabel = Instance.new("TextLabel")
hurufLabel.Size = UDim2.new(0, 40, 1, 0)
hurufLabel.BackgroundTransparency = 1
hurufLabel.Text = "A"
hurufLabel.TextColor3 = Color3.fromRGB(255, 255, 255)
hurufLabel.TextSize = 20
hurufLabel.Font = Enum.Font.SourceSansBold
hurufLabel.Parent = headerFrame

-- Status giliran
local statusLabel = Instance.new("TextLabel")
statusLabel.Size = UDim2.new(1, -50, 1, 0)
statusLabel.Position = UDim2.new(0, 45, 0, 0)
statusLabel.BackgroundTransparency = 1
statusLabel.Text = "Menunggu..."
statusLabel.TextColor3 = Color3.fromRGB(150, 150, 150)
statusLabel.TextSize = 12
statusLabel.Font = Enum.Font.SourceSans
statusLabel.TextXAlignment = Enum.TextXAlignment.Left
statusLabel.Parent = headerFrame

-- =========================
-- SEARCH BAR
-- =========================
local searchBox = Instance.new("TextBox")
searchBox.Size = UDim2.new(1, -20, 0, 35)
searchBox.Position = UDim2.new(0, 10, 0, 40)
searchBox.BackgroundColor3 = Color3.fromRGB(10, 10, 10)
searchBox.TextColor3 = Color3.fromRGB(255, 255, 255)
searchBox.PlaceholderColor3 = Color3.fromRGB(100, 100, 100)
searchBox.PlaceholderText = "Cari akhiran... (contoh: x)"
searchBox.Text = ""
searchBox.Font = Enum.Font.SourceSans
searchBox.TextSize = 14
searchBox.BorderColor3 = Color3.fromRGB(200, 200, 200)
searchBox.BorderSizePixel = 1
searchBox.ClearTextOnFocus = false
searchBox.Parent = mainFrame

local searchCorner = Instance.new("UICorner")
searchCorner.CornerRadius = UDim.new(0, 4)
searchCorner.Parent = searchBox

-- =========================
-- LIST HASIL PENCARIAN
-- =========================
local listFrame = Instance.new("ScrollingFrame")
listFrame.Size = UDim2.new(1, -20, 0, 160)
listFrame.Position = UDim2.new(0, 10, 0, 80)
listFrame.BackgroundColor3 = Color3.fromRGB(10, 10, 10)
listFrame.BorderColor3 = Color3.fromRGB(200, 200, 200)
listFrame.BorderSizePixel = 1
listFrame.ScrollBarThickness = 4
listFrame.ScrollBarImageColor3 = Color3.fromRGB(150, 150, 150)
listFrame.CanvasSize = UDim2.new(0, 0, 0, 0)
listFrame.AutomaticCanvasSize = Enum.AutomaticSize.Y
listFrame.Parent = mainFrame

local listCorner = Instance.new("UICorner")
listCorner.CornerRadius = UDim.new(0, 4)
listCorner.Parent = listFrame

-- UIListLayout untuk mengatur tombol
local listLayout = Instance.new("UIListLayout")
listLayout.Padding = UDim.new(0, 2)
listLayout.HorizontalAlignment = Enum.HorizontalAlignment.Center
listLayout.SortOrder = Enum.SortOrder.LayoutOrder
listLayout.Parent = listFrame

-- =========================
-- FOOTER (INFORMASI)
-- =========================
local footerFrame = Instance.new("Frame")
footerFrame.Size = UDim2.new(1, -20, 0, 25)
footerFrame.Position = UDim2.new(0, 10, 0, 245)
footerFrame.BackgroundColor3 = Color3.fromRGB(30, 30, 30)
footerFrame.BorderSizePixel = 0
footerFrame.Parent = mainFrame

local footerCorner = Instance.new("UICorner")
footerCorner.CornerRadius = UDim.new(0, 4)
footerCorner.Parent = footerFrame

-- Jumlah kata ditemukan
local countLabel = Instance.new("TextLabel")
countLabel.Size = UDim2.new(0.5, 0, 1, 0)
countLabel.Position = UDim2.new(0, 5, 0, 0)
countLabel.BackgroundTransparency = 1
countLabel.Text = "0 kata"
countLabel.TextColor3 = Color3.fromRGB(150, 150, 150)
countLabel.TextSize = 11
countLabel.Font = Enum.Font.SourceSans
countLabel.TextXAlignment = Enum.TextXAlignment.Left
countLabel.Parent = footerFrame

-- Status match
local matchStatus = Instance.new("TextLabel")
matchStatus.Size = UDim2.new(0.5, -5, 1, 0)
matchStatus.Position = UDim2.new(0.5, 0, 0, 0)
matchStatus.BackgroundTransparency = 1
matchStatus.Text = "⚫"
matchStatus.TextColor3 = Color3.fromRGB(150, 150, 150)
matchStatus.TextSize = 11
matchStatus.Font = Enum.Font.SourceSans
matchStatus.TextXAlignment = Enum.TextXAlignment.Right
matchStatus.Parent = footerFrame

-- =========================
-- FUNGSI UPDATE TAMPILAN
-- =========================
local function updateHasil()
    -- Hapus semua tombol di listFrame
    for _, child in ipairs(listFrame:GetChildren()) do
        if child:IsA("TextButton") then
            child:Destroy()
        end
    end
    
    -- Tampilkan hasil filter
    for _, kata in ipairs(hasilFilter) do
        local wordButton = Instance.new("TextButton")
        wordButton.Size = UDim2.new(1, -8, 0, 24)
        wordButton.BackgroundColor3 = Color3.fromRGB(30, 30, 30)
        wordButton.TextColor3 = Color3.fromRGB(220, 220, 220)
        wordButton.Text = kata:upper()
        wordButton.Font = Enum.Font.SourceSans
        wordButton.TextSize = 12
        wordButton.BorderColor3 = Color3.fromRGB(200, 200, 200)
        wordButton.BorderSizePixel = 1
        wordButton.AutoButtonColor = false
        wordButton.Parent = listFrame
        
        local btnCorner = Instance.new("UICorner")
        btnCorner.CornerRadius = UDim.new(0, 3)
        btnCorner.Parent = wordButton
        
        -- Hover effect
        wordButton.MouseEnter:Connect(function()
            wordButton.BackgroundColor3 = Color3.fromRGB(50, 50, 50)
        end)
        wordButton.MouseLeave:Connect(function()
            wordButton.BackgroundColor3 = Color3.fromRGB(30, 30, 30)
        end)
        
        -- Klik untuk submit (kalau ada SubmitWord)
        wordButton.MouseButton1Click:Connect(function()
            if SubmitWord and matchActive and isMyTurn and serverLetter ~= "" then
                if string.sub(kata, 1, 1) == serverLetter then
                    SubmitWord:FireServer(kata)
                    print("✅ Mengirim kata:", kata)
                    
                    -- Efek kedip
                    wordButton.BackgroundColor3 = Color3.fromRGB(0, 255, 0)
                    task.wait(0.1)
                    wordButton.BackgroundColor3 = Color3.fromRGB(30, 30, 30)
                else
                    -- Kata tidak sesuai huruf awal
                    wordButton.BackgroundColor3 = Color3.fromRGB(255, 0, 0)
                    task.wait(0.1)
                    wordButton.BackgroundColor3 = Color3.fromRGB(30, 30, 30)
                end
            end
        end)
    end
    
    -- Update counter
    countLabel.Text = #hasilFilter .. " kata ditemukan"
end

-- Event saat ngetik di search bar
searchBox.Changed:Connect(function(prop)
    if prop == "Text" then
        filterKata(searchBox.Text)
        updateHasil()
    end
end)

-- =========================
-- UPDATE STATUS GAME
-- =========================
spawn(function()
    while true do
        -- Update huruf awal
        hurufLabel.Text = serverLetter ~= "" and serverLetter:upper() or "?"
        
        -- Update status giliran
        if matchActive then
            if isMyTurn then
                statusLabel.Text = "GILIRAN ANDA"
                statusLabel.TextColor3 = Color3.fromRGB(0, 255, 0)
                matchStatus.Text = "🔵"
            else
                statusLabel.Text = "Giliran opponent"
                statusLabel.TextColor3 = Color3.fromRGB(255, 255, 0)
                matchStatus.Text = "🟡"
            end
        else
            statusLabel.Text = "Menunggu match..."
            statusLabel.TextColor3 = Color3.fromRGB(150, 150, 150)
            matchStatus.Text = "⚫"
        end
        
        -- Filter ulang kalau search bar gak kosong (untuk validasi huruf awal)
        if searchBox.Text ~= "" then
            -- Update warna tombol berdasarkan huruf awal
            for _, btn in ipairs(listFrame:GetChildren()) do
                if btn:IsA("TextButton") then
                    local kata = btn.Text:lower()
                    if serverLetter ~= "" and string.sub(kata, 1, 1) == serverLetter then
                        btn.TextColor3 = Color3.fromRGB(0, 255, 0)  -- hijau kalau bisa
                    else
                        btn.TextColor3 = Color3.fromRGB(220, 220, 220)  -- putih normal
                    end
                end
            end
        end
        
        task.wait(0.2)
    end
end)

-- =========================
-- TOMBOL CLOSE (X)
-- =========================
local closeButton = Instance.new("TextButton")
closeButton.Size = UDim2.new(0, 16, 0, 16)
closeButton.Position = UDim2.new(1, -20, 0, 5)
closeButton.BackgroundColor3 = Color3.fromRGB(40, 40, 40)
closeButton.TextColor3 = Color3.fromRGB(200, 200, 200)
closeButton.Text = "X"
closeButton.TextSize = 12
closeButton.Font = Enum.Font.SourceSansBold
closeButton.BorderColor3 = Color3.fromRGB(200, 200, 200)
closeButton.BorderSizePixel = 1
closeButton.Parent = mainFrame

local closeCorner = Instance.new("UICorner")
closeCorner.CornerRadius = UDim.new(0, 3)
closeCorner.Parent = closeButton

closeButton.MouseButton1Click:Connect(function()
    gui:Destroy()
end)

-- =========================
-- INIT
-- =========================
print("🚀 SEARCH BAR AKHIRAN READY!")
print("📌 Cari akhiran, langsung klik kata untuk kirim!")