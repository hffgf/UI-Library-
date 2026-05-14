-- Memuat WindUI Library
local WindUI = loadstring(game:HttpGet("https://github.com/Footagesus/WindUI/releases/latest/download/main.lua"))()

-- Membuat Window Utama
local Window = WindUI:CreateWindow({
    Title = "Military Base Script",
    Icon = "rbxassetid://10000000000",
    Author = "Zareus",
    Size = UDim2.fromOffset(580, 460),
    Transparent = true
})

-- Layanan (Services)
local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local LocalPlayer = Players.LocalPlayer

-- Mendefinisikan Lokasi Remotes dan Folder Data
local sharedResources = ReplicatedStorage:WaitForChild("Shared"):WaitForChild("Resources")
local plotRemotes = sharedResources:WaitForChild("PlotResources"):WaitForChild("Remotes")
local rebirthRemotes = sharedResources:WaitForChild("RebirthResources"):WaitForChild("Remotes")
local vendorRemotes = sharedResources:WaitForChild("VendorResources"):WaitForChild("Remotes")
local structuresFolder = sharedResources:WaitForChild("PlotResources"):WaitForChild("Structures")

-- Menggunakan getgenv() agar loop toggle dapat dimatikan dengan aman
local env = getgenv or function() return _G end
env().autoCollect = false
env().autoRebirth = false

--------------------------------------------------
-- TAB 1: UTAMA (MAIN)
--------------------------------------------------
local MainTab = Window:CreateTab({
    Title = "Main Features",
    Icon = "home"
})

MainTab:CreateToggle({
    Name = "Auto Collect Cash",
    Desc = "Otomatis mengumpulkan uang dari plot milikmu.",
    Callback = function(state)
        env().autoCollect = state
        while env().autoCollect do
            task.wait(1)
            local plotName = LocalPlayer.Name .. "'s plot"
            local plot = workspace.Plots:FindFirstChild(plotName)
            if plot then
                plotRemotes.Collect:FireServer(plot)
            end
        end
    end
})

MainTab:CreateToggle({
    Name = "Auto Rebirth",
    Desc = "Otomatis memicu remote Rebirth jika uang cukup.",
    Callback = function(state)
        env().autoRebirth = state
        while env().autoRebirth do
            task.wait(3)
            rebirthRemotes.Rebirth:FireServer()
        end
    end
})

--------------------------------------------------
-- TAB 2: SHOP & AUTO BUY
--------------------------------------------------
local ShopTab = Window:CreateTab({
    Title = "Shop & Auto Buy",
    Icon = "shopping-cart"
})

-- Mengumpulkan data kategori dan item dari folder Structures game
local categories = {"All"}
local itemsByCategory = {["All"] = {}}
local selectedCategory = "All"
local selectedItem = ""
local buyAmount = 1

for _, struct in ipairs(structuresFolder:GetChildren()) do
    table.insert(itemsByCategory["All"], struct.Name)
    
    -- Mencoba membaca ModuleScript Config untuk mendapatkan kategori (jika bisa diakses client)
    pcall(function()
        local configModule = struct:FindFirstChild("Config")
        if configModule then
            local config = require(configModule)
            if config and config.BuildingCategory then
                local cat = config.BuildingCategory
                if not itemsByCategory[cat] then
                    itemsByCategory[cat] = {}
                    table.insert(categories, cat)
                end
                table.insert(itemsByCategory[cat], struct.Name)
            end
        end
    end)
end

-- UI Komponen Shop
local ItemDropdown -- Dideklarasikan lebih awal agar bisa di-refresh oleh CategoryDropdown

ShopTab:CreateDropdown({
    Name = "Pilih Kategori",
    Desc = "Filter barang berdasarkan kategori bangunan.",
    Options = categories,
    CurrentOption = "All",
    Callback = function(Option)
        selectedCategory = Option
        if ItemDropdown then
            ItemDropdown:Refresh(itemsByCategory[selectedCategory], true)
        end
    end
})

ItemDropdown = ShopTab:CreateDropdown({
    Name = "Pilih Bangunan / Resource",
    Desc = "Barang yang ingin dibeli.",
    Options = itemsByCategory["All"],
    CurrentOption = itemsByCategory["All"][1] or "",
    Callback = function(Option)
        selectedItem = Option
    end
})

ShopTab:CreateSlider({
    Name = "Jumlah Beli",
    Desc = "Seberapa banyak barang yang akan dibeli (1-50)",
    Min = 1,
    Max = 50,
    Default = 1,
    Callback = function(Value)
        buyAmount = Value
    end
})

ShopTab:CreateButton({
    Name = "Beli Sekarang",
    Desc = "Mengeksekusi pembelian barang sesuai jumlah slider.",
    Callback = function()
        if not selectedItem or selectedItem == "" then
            WindUI:Notify({Title = "Gagal", Content = "Pilih barang terlebih dahulu!", Duration = 3})
            return
        end

        WindUI:Notify({
            Title = "Memproses Pembelian...",
            Content = "Membeli " .. buyAmount .. "x " .. selectedItem,
            Duration = 2
        })

        -- Mengeksekusi remote pembelian dalam thread terpisah agar UI tidak freeze
        task.spawn(function()
            for i = 1, buyAmount do
                vendorRemotes.PurchaseStructure:FireServer(selectedItem)
                task.wait(0.15) -- Jeda aman agar tidak terkena limit / kick dari server
            end
            WindUI:Notify({
                Title = "Selesai",
                Content = "Selesai membeli " .. selectedItem,
                Duration = 3
            })
        end)
    end
})

--------------------------------------------------
-- TAB 3: MANAJEMEN PLOT
--------------------------------------------------
local PlotTab = Window:CreateTab({
    Title = "Plot Management",
    Icon = "box"
})

PlotTab:CreateButton({
    Name = "Clear Plot (Return to Inventory)",
    Desc = "Membongkar semua bangunan di plot.",
    Callback = function()
        local plotName = LocalPlayer.Name .. "'s plot"
        local plot = workspace.Plots:FindFirstChild(plotName)
        
        if plot and plot:FindFirstChild("baseplate") and plot.baseplate:FindFirstChild("Structures") then
            for _, structure in pairs(plot.baseplate.Structures:GetChildren()) do
                plotRemotes.DestroyStructure:FireServer(structure)
            end
            WindUI:Notify({Title = "Plot Cleared", Content = "Semua struktur telah dikembalikan ke inventory.", Duration = 3})
        end
    end
})

PlotTab:CreateButton({
    Name = "Save Plot (Slot 1)",
    Callback = function()
        plotRemotes.SavePlot:FireServer("1")
        WindUI:Notify({Title = "Saved", Content = "Plot berhasil disimpan ke Slot 1.", Duration = 3})
    end
})

PlotTab:CreateButton({
    Name = "Load Plot (Slot 1)",
    Callback = function()
        plotRemotes.LoadPlot:FireServer("1")
        WindUI:Notify({Title = "Loaded", Content = "Plot dari Slot 1 sedang dimuat.", Duration = 3})
    end
})

-- Memilih tab pertama saat dijalankan
Window:SelectTab(MainTab)
