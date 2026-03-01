-- Membuat ScreenGui
local screenGui = Instance.new("ScreenGui")
screenGui.Name = "WordSearchGUI"
screenGui.Parent = game.Players.LocalPlayer:WaitForChild("PlayerGui")

-- Frame utama (warna hitam dengan border biru)
local mainFrame = Instance.new("Frame")
mainFrame.Size = UDim2.new(0, 300, 0, 400)
mainFrame.Position = UDim2.new(0.5, -150, 0.5, -200)
mainFrame.BackgroundColor3 = Color3.fromRGB(0, 0, 0) -- Hitam
mainFrame.BorderColor3 = Color3.fromRGB(0, 150, 255) -- Biru elegan
mainFrame.BorderSizePixel = 3
mainFrame.Active = true
mainFrame.Draggable = true
mainFrame.Parent = screenGui

-- Frame dalam untuk konten
local contentFrame = Instance.new("Frame")
contentFrame.Size = UDim2.new(1, -20, 1, -20)
contentFrame.Position = UDim2.new(0, 10, 0, 10)
contentFrame.BackgroundColor3 = Color3.fromRGB(0, 0, 0)
contentFrame.BorderSizePixel = 0
contentFrame.Parent = mainFrame

-- Label Search 1 (Awalan)
local label1 = Instance.new("TextLabel")
label1.Size = UDim2.new(1, 0, 0, 20)
label1.Position = UDim2.new(0, 0, 0, 0)
label1.BackgroundColor3 = Color3.fromRGB(0, 0, 0)
label1.TextColor3 = Color3.fromRGB(255, 255, 255)
label1.Text = "CARI BERDASARKAN AWALAN"
label1.TextSize = 12
label1.Font = Enum.Font.SourceSansBold
label1.TextXAlignment = Enum.TextXAlignment.Left
label1.BorderColor3 = Color3.fromRGB(0, 150, 255)
label1.BorderSizePixel = 1
label1.Parent = contentFrame

-- Search bar 1 (Awalan)
local searchBox1 = Instance.new("TextBox")
searchBox1.Size = UDim2.new(1, 0, 0, 30)
searchBox1.Position = UDim2.new(0, 0, 0, 22)
searchBox1.BackgroundColor3 = Color3.fromRGB(15, 15, 15)
searchBox1.TextColor3 = Color3.fromRGB(255, 255, 255)
searchBox1.PlaceholderColor3 = Color3.fromRGB(100, 100, 100)
searchBox1.PlaceholderText = "Contoh: xa, xi, xe, ax, ex, ox..."
searchBox1.Text = ""
searchBox1.Font = Enum.Font.SourceSans
searchBox1.TextSize = 14
searchBox1.BorderColor3 = Color3.fromRGB(0, 150, 255)
searchBox1.BorderSizePixel = 2
searchBox1.ClearTextOnFocus = false
searchBox1.Parent = contentFrame

-- Label Search 2 (Akhiran)
local label2 = Instance.new("TextLabel")
label2.Size = UDim2.new(1, 0, 0, 20)
label2.Position = UDim2.new(0, 0, 0, 60)
label2.BackgroundColor3 = Color3.fromRGB(0, 0, 0)
label2.TextColor3 = Color3.fromRGB(255, 255, 255)
label2.Text = "CARI BERDASARKAN AKHIRAN"
label2.TextSize = 12
label2.Font = Enum.Font.SourceSansBold
label2.TextXAlignment = Enum.TextXAlignment.Left
label2.BorderColor3 = Color3.fromRGB(0, 150, 255)
label2.BorderSizePixel = 1
label2.Parent = contentFrame

-- Search bar 2 (Akhiran)
local searchBox2 = Instance.new("TextBox")
searchBox2.Size = UDim2.new(1, 0, 0, 30)
searchBox2.Position = UDim2.new(0, 0, 0, 82)
searchBox2.BackgroundColor3 = Color3.fromRGB(15, 15, 15)
searchBox2.TextColor3 = Color3.fromRGB(255, 255, 255)
searchBox2.PlaceholderColor3 = Color3.fromRGB(100, 100, 100)
searchBox2.PlaceholderText = "Contoh: if, tif, ks, x, ex, ix..."
searchBox2.Text = ""
searchBox2.Font = Enum.Font.SourceSans
searchBox2.TextSize = 14
searchBox2.BorderColor3 = Color3.fromRGB(0, 150, 255)
searchBox2.BorderSizePixel = 2
searchBox2.ClearTextOnFocus = false
searchBox2.Parent = contentFrame

-- Listbox untuk hasil pencarian
local listFrame = Instance.new("ScrollingFrame")
listFrame.Size = UDim2.new(1, 0, 0, 200)
listFrame.Position = UDim2.new(0, 0, 0, 120)
listFrame.BackgroundColor3 = Color3.fromRGB(5, 5, 5)
listFrame.BorderColor3 = Color3.fromRGB(0, 150, 255)
listFrame.BorderSizePixel = 2
listFrame.ScrollBarThickness = 8
listFrame.ScrollBarImageColor3 = Color3.fromRGB(0, 150, 255)
listFrame.CanvasSize = UDim2.new(0, 0, 0, 0)
listFrame.AutomaticCanvasSize = Enum.AutomaticSize.Y
listFrame.Parent = contentFrame

-- UIListLayout untuk mengatur tombol secara otomatis
local listLayout = Instance.new("UIListLayout")
listLayout.Padding = UDim.new(0, 2)
listLayout.HorizontalAlignment = Enum.HorizontalAlignment.Center
listLayout.SortOrder = Enum.SortOrder.LayoutOrder
listLayout.Parent = listFrame

-- ========== SATU TABEL BESAR BERISI SEMUA KATA ==========
local semuaKata = {
    -- ===== KATA DARI COUNTER X =====
    -- xa
    "xantelesma", "xantat", "xantofil", "xantokromia", "xantoma", "xantin", "xantina",
    -- xi
    "xiaomi", "xilan", "xilarium", "xilem", "xilitol", "xilofit", "xilografi", "xister", 
    "xilofag", "xirofobia", "xilofon", "xilologi", "xilol", "xilonit", "xilulosa", 
    "xiloidina", "xilena", "xifoid", "xilograf", "xilotomi",
    -- xe
    "xerostomia", "xeroterm", "xenomania", "xenon", "xenia", "xenoglosia", "xerografi", 
    "xeroser", "xerosis", "xenofilia", "xeroftalmia", "xerofili", "xerofit", "xerokasi", 
    "xenofili", "xenogenetik", "xenobiotik", "xerik", "xenograf", "xenoglosofobia", 
    "xenolit", "xerofobia", "xeromorf", "xenokrasi", "xenoblas", "xenogenesis",
    -- ax
    "axis", "axioo", "axolotl", "axecelsum", "axelrodi", "axillaris",
    -- ex
    "expor", "extralarge", "excavata", "excellency", "exodus", "excoecaria", 
    "eximia", "exocarpus", "expat",
    -- ox
    "oxalidaceae", "oxleyanum", "oxypetalum", "oxyphylla", "oxyris",
    
    -- ===== KATA BARU YANG ANDA BERIKAN =====
    "bordeaux", "lex", "sphinx", "unisex", "bodrex", "komix", "gallierex", 
    "addax", "aframax", "apterix", "bombyx", "caloperdrix", "caranx", "caronx", 
    "chalcococyx", "chx", "cimex", "circumfix", "coix", "confix", "cyathocalyx", 
    "donax", "echinosorex", "forex", "helix", "hystrix", "ilex", "index", "lux", 
    "marx", "max", "melanoperdix", "meritrix", "microhierax", "molitrix", "murex", 
    "mystax", "naiasptatrix", "natrix", "nephotettix", "nephottotix", "ninox", 
    "nontax", "nothopanax", "nycticorax", "offax", "olfax", "ex", "prix", "annex", 
    "croix", "deux", "complex", "ix", "hapax", "rex", "klux", "mantoux", "box", "vox",
    
    -- ===== KATA DARI COUNTER CHEATER (AKHIRAN if) =====
    "abesif", "abrasif", "abusif", "adhesif", "adrif", "agresif", "akuif", "alif", 
    "anaglif", "antihipertensif", "antikorosif", "antipasif", "antitusif", "arif", 
    "bermuradif", "bertakrif", "bertarif", "brigif", "daif", "defensif", "delusif", 
    "depresif", "dif", "diskursif", "drif", "egresif", "eksesif", "eksklusif", 
    "ekskursif", "ekslusif", "ekspansif", "eksplosif", "ekspresif", "ekstensif", 
    "ekstraserbasif", "ekstrusif", "elusif", "esif", "foraminif", "forklif", "glif", 
    "hanif", "hieroglif", "ilusif", "implosif", "impresif", "impulsif", 
    "imunosupresif", "inesif", "infleksif", "ingresif", "inklusif", "intensif", 
    "invasif", "kalsif", "kif", "klif", "klusif", "koersif", "kohesif", "kolusif", 
    "komisif", "komprehensif", "kompulsif", "kondusif", "konif", "konklusif", 
    "konsesif", "konvulsif", "korosif", "kursif", "laif", "lamalif", "lif", 
    "lusif", "manif", "masif", "maukif", "mengagresif", "mengintensif", "mualif", 
    "mukhalif", "muradif", "mutahalif", "mutasawif", "mutawif", "naif", "nif", 
    "nonantipasif", "nontarif", "obsesif", "ofensif", "oklusif", "ostensif", "pasif", 
    "pelaif", "permansif", "permisif", "persuasif", "petroglif", "plosif", "posesif", 
    "progresif", "radif", "refleksif", "regresif", "represif", "resesif", "residif", 
    "responsif", "retrogresif", "rif", "roglif", "saif", "seagresif", "searif", 
    "seeksklusif", "seekstensif", "seintensif", "semasif", "sepasif", "sherif", 
    "sif", "sponsif", "subversif", "sudorif", "suksesif", "superintensif", 
    "supresif", "syarif", "tafoglif", "takarif", "taklif", "takrif", "tarif", 
    "tasrif", "teragresif", "terpasif", "trif", "usif", "wakif", "wif", "yonif",
    
    -- ===== KATA DARI COUNTER CHEATER (AKHIRAN tif) =====
    "ablatif", "abortif", "absorptif", "adaptif", "adiktif", "aditif", "adjektif", 
    "adjudikatif", "administratif", "adoptif", "adsorptif", "adventif", "afektif", 
    "aferitif", "afirmatif", "agentif", "agitatif", "aglutinatif", "agregatif", 
    "ajektif", "akomodatif", "akseleratif", "aktif", "akumulatif", "akusatif", 
    "alatif", "alteratif", "alternatif", "amelioratif", "antidegeneratif", 
    "antisipatif", "aperitif", "aplikatif", "apositif", "apresiatif", 
    "argumentatif", "artikulatif", "asertif", "asimilatif", "askriptif", 
    "asosiatif", "aspiratif", "asumptif", "asumtif", "atif", "atraktif", 
    "atributif", "auditif", "augmentatif", "automotif", "benefaktif", 
    "berinisiatif", "bermotif", "berobjektif", "bervariatif", "bioaditif", 
    "bioaktif", "datif", "dedikatif", "deduktif", "defektif", "definitif", 
    "deformatif", "degeneratif", "degradatif", "deklaratif", "dekoratif", 
    "demonstratif", "denotatif", "derivatif", "desideratif", "deskriptif", 
    "destruktif", "detektif", "determinatif", "diapositif", "digestif", 
    "dikatif", "diminutif", "direktif", "disinsentif", "disintegratif", 
    "disjungtif", "diskriminatif", "disosiatif", "disruptif", "distingtif", 
    "distributif", "ditransitif", "dukatif", "duktif", "duplikatif", "duratif", 
    "dwitransitif", "edukatif", "efektif", "ejektif", "eksekutif", "eksplikatif", 
    "eksploitatif", "eksploitif", "eksploratif", "ekstraktif", "ekstrapunitif", 
    "ekuatif", "elaboratif", "elatif", "elektif", "elektromotif", "elektronegatif", 
    "elektropositif", "emansipatif", "emotif", "enumeratif", "ergatif", 
    "eskalatif", "evaluatif", "evokatif", "evolutif", "faktif", "faktitif", 
    "fakultatif", "fermentatif", "figuratif", "fiktif", "finitif", "fktif", 
    "flektif", "fluktuatif", "formatif", "fotokonduktif", "frekuentatif", 
    "frikatif", "gatif", "generatif", "genetif", "genitif", "gislatif", 
    "gulatif", "habilitatif", "habituatif", "hatif", "heterofermentatif", 
    "heteronormatif", "hiperaktif", "hipersensitif", "homofermentatif", 
    "ilatif", "ilustratif", "imajinatif", "imitatif", "imperatif", 
    "imperfektif", "imunoreaktif", "indikatif", "indoktrinatif", "induktif", 
    "infektif", "infinitif", "inflektif", "informatif", "inisiatif", "inkoatif", 
    "inkompletif", "inkorporatif", "inovatif", "insentif", "inseptif", 
    "insinuatif", "inspektif", "inspiratif", "instingtif", "instruktif", 
    "instrumentatif", "integratif", "interaktif", "interogatif", "interpretatif", 
    "interpretif", "intransitif", "intropunitif", "intuitif", "inventif", 
    "investigatif", "iritatif", "isolatif", "iteratif", "judikatif", 
    "kalkulatif", "kapasitif", "karitatif", "karminatif", "kausatif", 
    "klaratif", "kognatif", "kognitif", "kolaboratif", "kolektif", 
    "koligatif", "komitatif", "komparatif", "kompetitif", "kompletif", 
    "komplikatif", "komulatif", "komunikatif", "komutatif", "konatif", 
    "konektif", "konfektif", "konfrontatif", "konjungtif", "konotatif", 
    "konsekutif", "konservatif", "konspiratif", "konstatatif", "konstitutif", 
    "konstriktif", "konstruktif", "konsultatif", "konsumtif", "kontemplatif", 
    "kontinuatif", "kontradiktif", "kontraktif", "kontrapositif", 
    "kontraproduktif", "kontraseptif", "kontributif", "konvektif", "kooperatif", 
    "kooptatif", "koordinatif", "koperatif", "kopulatif", "koratif", "korektif", 
    "korelatif", "korporatif", "koruptif", "kreatif", "kualitatif", 
    "kuantitatif", "kuasilegislatif", "kuatif", "kulatif", "kumulatif", 
    "kuratif", "kwantitatif", "laksatif", "latif", "legislatif", 
    "legitimatif", "limitatif", "lioratif", "lokatif", "lokomotif", 
    "lukratif", "maladministratif", "manipulatif", "meditatif", "modifikatif", 
    "monstratif", "motif", "multiperspektif", "multipliktif", "naratif", 
    "nefaktif", "negatif", "neratif", "nitif", "nominatif", "nonaktif", 
    "nondiskriminatif", "nondistingtif", "nonkooperatif", "nonnominatif", 
    "nonpredikatif", "nonproduktif", "nonretroaktif", "normatif", "notatif", 
    "nutritif", "objektif", "obligatif", "obstruktif", "obviatif", "obyektif", 
    "oksidatif", "operatif", "optatif", "otomotif", "otoritatif", "overaktif", 
    "paliatif", "partisipatif", "partitif", "pengaktif", "perfektif", 
    "performatif", "perseptif", "perspektif", "peyoratif", "polutif", "positif", 
    "predikatif", "prerogatif", "preskriptif", "preventif", "primitif", 
    "privatif", "proaktif", "produktif", "prolatif", "promotif", "prospektif", 
    "protektif", "provokatif", "proyektif", "psikoaktif", "ptif", "punitif", 
    "purgatif", "radiatif", "radioaktif", "ratif", "reaktif", "reduktif", 
    "reflektif", "reformatif", "regulatif", "rehabilitatif", "rekonsiliatif", 
    "rekonstruktif", "rekreatif", "relatif", "repetitif", "representatif", 
    "reproduktif", "reseptif", "resistif", "resitatif", "restoratif", 
    "restriktif", "retroaktif", "retrospektif", "rivatif", "rogatif", 
    "seaktif", "sedatif", "seefektif", "segregatif", "sekomunikatif", 
    "selektif", "sensitif", "seobjektif", "seobyektif", "sesatif", "siatif", 
    "signifikatif", "simplikatif", "simulfaktif", "skriptif", "solutif", 
    "spekulatif", "sportif", "statif", "stif", "stigatif", "stimulatif", 
    "struktif", "subjektif", "subordinatif", "substantif", "substitutif", 
    "subyektif", "sugestif", "sumatif", "superkonduktif", "superlatif", 
    "supersensitif", "suportif", "takaditif", "takaktif", "takefektif", 
    "takobjektif", "taktransitif", "tatif", "tentatif", "teraktif", "tif", 
    "transaktif", "transformatif", "transitif", "translatif", "troaktif", 
    "ultrakonservatif", "valuatif", "variatif", "vegetatif", "vokatif", 
    "yudikatif",
    
    -- ===== KATA DARI COUNTER CHEATER (AKHIRAN ks) =====
    "adaks", "afiks", "afluks", "agrokompleks", "aks", "aloleks", "ambaks", 
    "ambifiks", "anoks", "antefiks", "anteliks", "antiklimaks", "antraks", 
    "apendiks", "berafiks", "berklimaks", "berkonfiks", "berkonteks", 
    "berkuteks", "berparadoks", "berprefiks", "bersufiks", "bikonveks", 
    "biloks", "birofaks", "biseks", "bkkks", "boks", "bomseks", "boraks", 
    "botoks", "brafaks", "cuaks", "deks", "detoks", "difaks", "diindeks", 
    "diks", "disklimaks", "doks", "dominatriks", "dupleks", "eks", 
    "ekuinoks", "faks", "falotoraks", "fiks", "fiolaks", "flaks", 
    "fleks", "fluks", "foniks", "goks", "heks", "heliks", "heterodoks", 
    "hidroponiks", "hijinks", "hiperteks", "hoaks", "homoseks", "indeks", 
    "infiks", "interfiks", "ireks", "isoleks", "karapaks", "kemorefleks", 
    "klimaks", "koaks", "kodeks", "kompleks", "konfiks", "konteks", 
    "konveks", "korteks", "koteks", "kuadrupleks", "kuinoks", "kuteks", 
    "laks", "larnaks", "lateks", "leks", "liks", "loks", "lppks", 
    "luks", "lureks", "maks", "matriks", "meaks", "mengindeks", 
    "mengklimaks", "mesotoraks", "mks", "multikompleks", "multipleks", 
    "naks", "noks", "obeks", "oniks", "ortodoks", "paks", "paradoks", 
    "paralaks", "pengindeks", "pertamaks", "petromaks", "piks", "piroks", 
    "plaks", "pleks", "pmks", "poliklimaks", "prefiks", "protoraks", 
    "radiks", "raks", "redoks", "refleks", "refluks", "relaks", 
    "retrofleks", "riks", "rileks", "rouks", "sefalotoraks", "seks", 
    "serviks", "sfinks", "simpleks", "simulfiks", "sinemapleks", 
    "sinepleks", "sintaks", "sirkumfiks", "sirkumfleks", "sks", 
    "sotoraks", "spandeks", "subteks", "sufiks", "suks", "superheliks", 
    "suprafiks", "taks", "teks", "teleks", "teleteks", "terodoks", 
    "toks", "toraks", "traks", "tripleks", "tromaks", "tubifeks", 
    "tuks", "uks", "ultramikroskopiks", "ultraortodoks", "uniseks", 
    "veks", "verniks", "verteks", "videoteks", "vorteks", "yolks"
}

-- Fungsi untuk mencari kata berdasarkan awalan
local function cariBerdasarkanAwalan(awalan)
    if awalan == "" then return {} end
    local hasil = {}
    awalan = awalan:lower()
    for _, kata in ipairs(semuaKata) do
        if kata:sub(1, #awalan):lower() == awalan then
            table.insert(hasil, kata)
        end
    end
    return hasil
end

-- Fungsi untuk mencari kata berdasarkan akhiran
local function cariBerdasarkanAkhiran(akhiran)
    if akhiran == "" then return {} end
    local hasil = {}
    akhiran = akhiran:lower()
    for _, kata in ipairs(semuaKata) do
        if kata:sub(-#akhiran):lower() == akhiran then
            table.insert(hasil, kata)
        end
    end
    return hasil
end

-- Fungsi untuk menampilkan hasil pencarian
local function tampilkanHasil(hasilKata)
    -- Hapus semua tombol yang ada di listFrame
    for _, child in ipairs(listFrame:GetChildren()) do
        if child:IsA("TextButton") then
            child:Destroy()
        end
    end
    
    -- Tampilkan hasil pencarian
    for _, kata in ipairs(hasilKata) do
        local wordButton = Instance.new("TextButton")
        wordButton.Size = UDim2.new(1, -10, 0, 30)
        wordButton.BackgroundColor3 = Color3.fromRGB(20, 20, 20)
        wordButton.TextColor3 = Color3.fromRGB(255, 255, 255)
        wordButton.Text = kata
        wordButton.Font = Enum.Font.SourceSans
        wordButton.TextSize = 14
        wordButton.BorderColor3 = Color3.fromRGB(0, 150, 255)
        wordButton.BorderSizePixel = 1
        wordButton.AutoButtonColor = false
        
        -- Fungsi saat kata diklik
        wordButton.MouseButton1Click:Connect(function()
            local args = {
                [1] = kata
            }
            game.ReplicatedStorage.Remotes.SubmitWord:FireServer(unpack(args))
            print("Mengirim kata: " .. kata)
        end)
        
        wordButton.MouseEnter:Connect(function()
            wordButton.BackgroundColor3 = Color3.fromRGB(40, 40, 40)
        end)
        
        wordButton.MouseLeave:Connect(function()
            wordButton.BackgroundColor3 = Color3.fromRGB(20, 20, 20)
        end)
        
        wordButton.Parent = listFrame
    end
end

-- Event saat search bar berubah
searchBox1.Changed:Connect(function(prop)
    if prop == "Text" then
        local hasil = cariBerdasarkanAwalan(searchBox1.Text)
        tampilkanHasil(hasil)
    end
end)

searchBox2.Changed:Connect(function(prop)
    if prop == "Text" then
        local hasil = cariBerdasarkanAkhiran(searchBox2.Text)
        tampilkanHasil(hasil)
    end
end)

-- Tombol close
local closeButton = Instance.new("TextButton")
closeButton.Size = UDim2.new(0, 20, 0, 20)
closeButton.Position = UDim2.new(1, -25, 0, 5)
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

-- Tampilkan semua kata saat pertama kali buka
tampilkanHasil(semuaKata)
