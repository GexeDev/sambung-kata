-- =========================================================
-- FILTER KATA - VERSI SEDERHANA (PASTI MUNCUL)
-- =========================================================

if not game:IsLoaded() then game.Loaded:Wait() end

local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Players = game:GetService("Players")
local LocalPlayer = Players.LocalPlayer
local HttpService = game:GetService("HttpService")
local UserInputService = game:GetService("UserInputService")
local VirtualInputManager = game:GetService("VirtualInputManager")

-- =========================
-- LOAD WORDLIST
-- =========================
local kataModule = {}

local function downloadWordlist()
    local success, response = pcall(function()
        return game:HttpGet("https://raw.githubusercontent.com/danzzy1we/roblox-script-dump/refs/heads/main/WordListDump/withallcombination2.lua")
    end)
    
    if success and response then
        for word in response:gmatch('"([^"]+)"') do
            if #word >= 2 then
                table.insert(kataModule, word:lower())
            end
        end
        print("✅ Wordlist loaded: " .. #kataModule .. " kata")
    else
        print("❌ Gagal download")
        kataModule = {"annex", "axis", "xenon", "abesif", "xantat"} -- fallback
    end
end

downloadWordlist()

-- =========================
-- STATE
-- =========================
local serverLetter = "a"  -- SET MANUAL DULU BUAT TEST
local akhiranInput = ""
local hasilFilter = {}

-- =========================
-- FUNGSI FILTER (SEDERHANA)
-- =========================
local function filterKata()
    hasilFilter = {}
    
    -- PAKAI HURUF MANUAL DULU BUAT TEST
    local hurufAwal = "a"  -- GANTI INI SESUAI HURUF GAME NANTI
    
    for _, kata in ipairs(kataModule) do
        -- Filter berdasarkan huruf awal
        if string.sub(kata, 1, 1) == hurufAwal then
            -- Kalau ada akhiran, filter juga
            if akhiranInput == "" then
                table.insert(hasilFilter, kata)
            else
                if string.sub(kata, -#akhiranInput) == akhiranInput then
                    table.insert(hasilFilter, kata)
                end
            end
        end
    end
    
    print("🔍 Ditemukan:", #hasilFilter, "kata untuk huruf", hurufAwal, "akhiran", akhiranInput)
end

-- =========================
-- GUI SEDERHANA
-- =========================
local gui = Instance.new("ScreenGui")
gui.Name = "TestFilter"
gui.Parent = LocalPlayer:WaitForChild("PlayerGui")

local frame = Instance.new("Frame")
frame.Size = UDim2.new(0, 250, 0, 300)
frame.Position = UDim2.new(0.5, -125, 0.5, -150)
frame.BackgroundColor3 = Color3.fromRGB(20, 20, 20)
frame.BorderColor3 = Color3.fromRGB(0, 150, 255)
frame.BorderSizePixel = 2
frame.Active = true
frame.Draggable = true
frame.Parent = gui

local corner = Instance.new("UICorner")
corner.CornerRadius = UDim.new(0, 8)
corner.Parent = frame

-- Search Bar
local searchBox = Instance.new("TextBox")
searchBox.Size = UDim2.new(1, -20, 0, 35)
searchBox.Position = UDim2.new(0, 10, 0, 10)
searchBox.BackgroundColor3 = Color3.fromRGB(10, 10, 10)
searchBox.TextColor3 = Color3.fromRGB(255, 255, 255)
searchBox.PlaceholderText = "Cari akhiran..."
searchBox.Text = ""
searchBox.Font = Enum.Font.SourceSans
searchBox.TextSize = 14
searchBox.BorderColor3 = Color3.fromRGB(0, 150, 255)
searchBox.BorderSizePixel = 2
searchBox.Parent = frame

local searchCorner = Instance.new("UICorner")
searchCorner.CornerRadius = UDim.new(0, 6)
searchCorner.Parent = searchBox

-- List
local listFrame = Instance.new("ScrollingFrame")
listFrame.Size = UDim2.new(1, -20, 0, 200)
listFrame.Position = UDim2.new(0, 10, 0, 55)
listFrame.BackgroundColor3 = Color3.fromRGB(10, 10, 10)
listFrame.BorderColor3 = Color3.fromRGB(0, 150, 255)
listFrame.BorderSizePixel = 2
listFrame.ScrollBarThickness = 6
listFrame.Parent = frame

local listCorner = Instance.new("UICorner")
listCorner.CornerRadius = UDim.new(0, 6)
listCorner.Parent = listFrame

local listLayout = Instance.new("UIListLayout")
listLayout.Padding = UDim.new(0, 2)
listLayout.HorizontalAlignment = Enum.HorizontalAlignment.Center
listLayout.Parent = listFrame

-- =========================
-- UPDATE LIST
-- =========================
local function updateList()
    -- Hapus semua
    for _, child in ipairs(listFrame:GetChildren()) do
        if child:IsA("TextButton") then
            child:Destroy()
        end
    end
    
    -- Tampilkan maksimal 50 kata biar gak lag
    local maxShow = math.min(50, #hasilFilter)
    for i = 1, maxShow do
        local kata = hasilFilter[i]
        local btn = Instance.new("TextButton")
        btn.Size = UDim2.new(1, -8, 0, 25)
        btn.BackgroundColor3 = Color3.fromRGB(30, 30, 30)
        btn.TextColor3 = Color3.fromRGB(255, 255, 255)
        btn.Text = kata:upper()
        btn.Font = Enum.Font.SourceSans
        btn.TextSize = 13
        btn.BorderColor3 = Color3.fromRGB(0, 150, 255)
        btn.BorderSizePixel = 1
        btn.Parent = listFrame
        
        local btnCorner = Instance.new("UICorner")
        btnCorner.CornerRadius = UDim.new(0, 4)
        btnCorner.Parent = btn
        
        btn.MouseButton1Click:Connect(function()
            print("🔘 Klik:", kata)
        end)
    end
    
    print("📋 Menampilkan", maxShow, "dari", #hasilFilter, "kata")
end

-- Event search
searchBox.Changed:Connect(function(prop)
    if prop == "Text" then
        akhiranInput = searchBox.Text:lower()
        filterKata()
        updateList()
    end
end)

-- Filter awal
filterKata()
updateList()

print("🚀 TEST FILTER READY")
