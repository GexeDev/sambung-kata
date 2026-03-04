-- =========================================================
-- FILTER KATA - AUTO KETIK (BUKAN REMOTE)
-- =========================================================

if not game:IsLoaded() then game.Loaded:Wait() end

local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Players = game:GetService("Players")
local LocalPlayer = Players.LocalPlayer
local HttpService = game:GetService("HttpService")
local UserInputService = game:GetService("UserInputService")
local VirtualInputManager = game:GetService("VirtualInputManager")

-- =========================
-- REMOTE EVENT (CUMA BUAT DETEKSI AWALAN)
-- =========================
local remotes = ReplicatedStorage:FindFirstChild("Remotes")
if not remotes then
    remotes = Instance.new("Folder")
    remotes.Name = "Remotes"
    remotes.Parent = ReplicatedStorage
end

local MatchUI = remotes:FindFirstChild("MatchUI")

-- =========================
-- LOAD WORDLIST DARI GITHUB
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
    end
end

downloadWordlist()

-- =========================
-- STATE
-- =========================
local matchActive = false
local isMyTurn = false
local serverLetter = ""
local akhiranInput = ""
local hasilFilter = {}
local isTyping = false

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
            filterKata()
        elseif cmd == "StartTurn" then
            isMyTurn = true
        elseif cmd == "EndTurn" then
            isMyTurn = false
        end
    end)
else
    spawn(function()
        while true do
            local letter = LocalPlayer:GetAttribute("CurrentLetter")
            if letter and letter ~= serverLetter then
                serverLetter = letter:lower()
                filterKata()
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
-- FUNGSI FILTER KATA
-- =========================
local function filterKata()
    hasilFilter = {}
    
    if serverLetter == "" then return end
    
    local lowerAkhiran = akhiranInput:lower()
    
    for _, kata in ipairs(kataModule) do
        if string.sub(kata, 1, 1) == serverLetter then
            if akhiranInput == "" then
                table.insert(hasilFilter, kata)
            else
                if string.sub(kata, -#lowerAkhiran) == lowerAkhiran then
                    table.insert(hasilFilter, kata)
                end
            end
        end
    end
    
    table.sort(hasilFilter, function(a, b) return #a < #b end)
end

-- =========================
-- FUNGSI AUTO KETIK (VIRTUAL INPUT)
-- =========================
local function autoType(kata)
    if isTyping then 
        print("⏳ Lagi ngetik...")
        return 
    end
    isTyping = true
    
    -- Delay biar fokus ke text box
    task.wait(0.1)
    
    -- Ketik huruf per huruf
    for i = 1, #kata do
        local huruf = string.sub(kata, i, i)
        local keyCode = Enum.KeyCode[huruf:upper()]
        
        if keyCode then
            VirtualInputManager:SendKeyEvent(true, keyCode, false, game)
            task.wait(0.05)
            VirtualInputManager:SendKeyEvent(false, keyCode, false, game)
            task.wait(0.03)
        end
    end
    
    task.wait(0.1)
    
    -- Enter
    VirtualInputManager:SendKeyEvent(true, Enum.KeyCode.Return, false, game)
    task.wait(0.05)
    VirtualInputManager:SendKeyEvent(false, Enum.KeyCode.Return, false, game)
    
    isTyping = false
    print("✅ Auto ketik:", kata)
end

-- =========================
-- BUAT GUI (VERSI OK)
-- =========================
local gui = Instance.new("ScreenGui")
gui.Name = "FilterKata"
gui.ResetOnSpawn = false
gui.Parent = LocalPlayer:WaitForChild("PlayerGui")
gui.IgnoreGuiInset = true
gui.DisplayOrder = 9999

-- Frame utama
local mainFrame = Instance.new("Frame")
mainFrame.Size = UDim2.new(0, 200, 0, 250)
mainFrame.Position = UDim2.new(0.5, -100, 0.5, -125)
mainFrame.BackgroundColor3 = Color3.fromRGB(20, 20, 20)
mainFrame.BorderColor3 = Color3.fromRGB(0, 150, 255)
mainFrame.BorderSizePixel = 2
mainFrame.Active = true
mainFrame.Draggable = true
mainFrame.Parent = gui

local mainCorner = Instance.new("UICorner")
mainCorner.CornerRadius = UDim.new(0, 8)
mainCorner.Parent = mainFrame

-- HEADER
local headerFrame = Instance.new("Frame")
headerFrame.Size = UDim2.new(1, -10, 0, 40)
headerFrame.Position = UDim2.new(0, 5, 0, 5)
headerFrame.BackgroundColor3 = Color3.fromRGB(30, 30, 30)
headerFrame.BorderSizePixel = 0
headerFrame.Parent = mainFrame

local headerCorner = Instance.new("UICorner")
headerCorner.CornerRadius = UDim.new(0, 6)
headerCorner.Parent = headerFrame

local hurufLabel = Instance.new("TextLabel")
hurufLabel.Size = UDim2.new(0, 40, 1, 0)
hurufLabel.BackgroundTransparency = 1
hurufLabel.Text = "A"
hurufLabel.TextColor3 = Color3.fromRGB(0, 150, 255)
hurufLabel.TextSize = 24
hurufLabel.Font = Enum.Font.SourceSansBold
hurufLabel.Parent = headerFrame

local statusLabel = Instance.new("TextLabel")
statusLabel.Size = UDim2.new(1, -45, 1, 0)
statusLabel.Position = UDim2.new(0, 45, 0, 0)
statusLabel.BackgroundTransparency = 1
statusLabel.Text = "Menunggu"
statusLabel.TextColor3 = Color3.fromRGB(200, 200, 200)
statusLabel.TextSize = 12
statusLabel.Font = Enum.Font.SourceSans
statusLabel.TextXAlignment = Enum.TextXAlignment.Left
statusLabel.Parent = headerFrame

-- SEARCH BAR
local searchBox = Instance.new("TextBox")
searchBox.Size = UDim2.new(1, -10, 0, 35)
searchBox.Position = UDim2.new(0, 5, 0, 50)
searchBox.BackgroundColor3 = Color3.fromRGB(10, 10, 10)
searchBox.TextColor3 = Color3.fromRGB(255, 255, 255)
searchBox.PlaceholderColor3 = Color3.fromRGB(100, 100, 100)
searchBox.PlaceholderText = "Cari akhiran..."
searchBox.Text = ""
searchBox.Font = Enum.Font.SourceSans
searchBox.TextSize = 14
searchBox.BorderColor3 = Color3.fromRGB(0, 150, 255)
searchBox.BorderSizePixel = 2
searchBox.ClearTextOnFocus = false
searchBox.Parent = mainFrame

local searchCorner = Instance.new("UICorner")
searchCorner.CornerRadius = UDim.new(0, 6)
searchCorner.Parent = searchBox

-- LIST HASIL
local listFrame = Instance.new("ScrollingFrame")
listFrame.Size = UDim2.new(1, -10, 0, 120)
listFrame.Position = UDim2.new(0, 5, 0, 90)
listFrame.BackgroundColor3 = Color3.fromRGB(10, 10, 10)
listFrame.BorderColor3 = Color3.fromRGB(0, 150, 255)
listFrame.BorderSizePixel = 2
listFrame.ScrollBarThickness = 6
listFrame.ScrollBarImageColor3 = Color3.fromRGB(0, 150, 255)
listFrame.CanvasSize = UDim2.new(0, 0, 0, 0)
listFrame.AutomaticCanvasSize = Enum.AutomaticSize.Y
listFrame.Parent = mainFrame

local listCorner = Instance.new("UICorner")
listCorner.CornerRadius = UDim.new(0, 6)
listCorner.Parent = listFrame

local listLayout = Instance.new("UIListLayout")
listLayout.Padding = UDim.new(0, 2)
listLayout.HorizontalAlignment = Enum.HorizontalAlignment.Center
listLayout.SortOrder = Enum.SortOrder.LayoutOrder
listLayout.Parent = listFrame

-- FOOTER
local footerFrame = Instance.new("Frame")
footerFrame.Size = UDim2.new(1, -10, 0, 30)
footerFrame.Position = UDim2.new(0, 5, 0, 215)
footerFrame.BackgroundColor3 = Color3.fromRGB(30, 30, 30)
footerFrame.BorderSizePixel = 0
footerFrame.Parent = mainFrame

local footerCorner = Instance.new("UICorner")
footerCorner.CornerRadius = UDim.new(0, 6)
footerCorner.Parent = footerFrame

local totalLabel = Instance.new("TextLabel")
totalLabel.Size = UDim2.new(0.7, -5, 1, 0)
totalLabel.Position = UDim2.new(0, 5, 0, 0)
totalLabel.BackgroundTransparency = 1
totalLabel.Text = "0 kata"
totalLabel.TextColor3 = Color3.fromRGB(150, 150, 150)
totalLabel.TextSize = 11
totalLabel.Font = Enum.Font.SourceSans
totalLabel.TextXAlignment = Enum.TextXAlignment.Left
totalLabel.Parent = footerFrame

local matchStatus = Instance.new("TextLabel")
matchStatus.Size = UDim2.new(0.3, -5, 1, 0)
matchStatus.Position = UDim2.new(0.7, 0, 0, 0)
matchStatus.BackgroundTransparency = 1
matchStatus.Text = "⚫"
matchStatus.TextColor3 = Color3.fromRGB(150, 150, 150)
matchStatus.TextSize = 14
matchStatus.Font = Enum.Font.SourceSansBold
matchStatus.Parent = footerFrame

-- CLOSE BUTTON
local closeButton = Instance.new("TextButton")
closeButton.Size = UDim2.new(0, 20, 0, 20)
closeButton.Position = UDim2.new(1, -25, 0, 5)
closeButton.BackgroundColor3 = Color3.fromRGB(40, 40, 40)
closeButton.TextColor3 = Color3.fromRGB(200, 200, 200)
closeButton.Text = "X"
closeButton.TextSize = 12
closeButton.Font = Enum.Font.SourceSansBold
closeButton.BorderColor3 = Color3.fromRGB(0, 150, 255)
closeButton.BorderSizePixel = 1
closeButton.Parent = mainFrame

local closeCorner = Instance.new("UICorner")
closeCorner.CornerRadius = UDim.new(0, 4)
closeCorner.Parent = closeButton

closeButton.MouseButton1Click:Connect(function()
    gui:Destroy()
end)

-- =========================
-- UPDATE LIST
-- =========================
local function updateList()
    -- Hapus semua button lama
    for _, child in ipairs(listFrame:GetChildren()) do
        if child:IsA("TextButton") then
            child:Destroy()
        end
    end
    
    -- Tampilkan hasil
    for _, kata in ipairs(hasilFilter) do
        local btn = Instance.new("TextButton")
        btn.Size = UDim2.new(1, -8, 0, 28)
        btn.BackgroundColor3 = Color3.fromRGB(30, 30, 30)
        btn.TextColor3 = Color3.fromRGB(220, 220, 220)
        btn.Text = kata:upper()
        btn.Font = Enum.Font.SourceSans
        btn.TextSize = 13
        btn.BorderColor3 = Color3.fromRGB(0, 150, 255)
        btn.BorderSizePixel = 1
        btn.AutoButtonColor = false
        btn.Parent = listFrame
        
        local btnCorner = Instance.new("UICorner")
        btnCorner.CornerRadius = UDim.new(0, 4)
        btnCorner.Parent = btn
        
        -- Hover
        btn.MouseEnter:Connect(function()
            btn.BackgroundColor3 = Color3.fromRGB(50, 50, 50)
        end)
        btn.MouseLeave:Connect(function()
            btn.BackgroundColor3 = Color3.fromRGB(30, 30, 30)
        end)
        
        -- KLIK → AUTO KETIK (BUKAN REMOTE)
        btn.MouseButton1Click:Connect(function()
            if isTyping then
                print("⏳ Lagi ngetik, tunggu...")
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
            
            if string.sub(kata, 1, 1) ~= serverLetter then
                print("⛔ Kata tidak sesuai huruf awal")
                return
            end
            
            -- Auto ketik!
            print("✍️ Auto ketik:", kata)
            autoType(kata)
            
            -- Efek visual
            btn.BackgroundColor3 = Color3.fromRGB(0, 255, 0)
            task.wait(0.1)
            btn.BackgroundColor3 = Color3.fromRGB(30, 30, 30)
        end)
    end
    
    totalLabel.Text = #hasilFilter .. " kata"
end

-- Event search bar
searchBox.Changed:Connect(function(prop)
    if prop == "Text" then
        akhiranInput = searchBox.Text
        filterKata()
        updateList()
    end
end)

-- Update status
spawn(function()
    while true do
        hurufLabel.Text = serverLetter ~= "" and serverLetter:upper() or "?"
        
        if matchActive then
            if isMyTurn then
                if isTyping then
                    statusLabel.Text = "SEDANG NGETIK..."
                    statusLabel.TextColor3 = Color3.fromRGB(255, 165, 0)
                else
                    statusLabel.Text = "GILIRAN ANDA"
                    statusLabel.TextColor3 = Color3.fromRGB(0, 255, 0)
                end
                matchStatus.Text = "🔵"
            else
                statusLabel.Text = "Giliran opponent"
                statusLabel.TextColor3 = Color3.fromRGB(255, 255, 0)
                matchStatus.Text = "🟡"
            end
        else
            statusLabel.Text = "Menunggu match"
            statusLabel.TextColor3 = Color3.fromRGB(150, 150, 150)
            matchStatus.Text = "⚫"
        end
        
        task.wait(0.2)
    end
end)

-- Filter awal
filterKata()
updateList()

print("🚀 AUTO KETIK READY!")
print("📌 Awalan dari game, search bar untuk akhiran")
print("📌 Klik kata → auto ketik + enter (BUKAN REMOTE)")