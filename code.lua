--[[ 
    MODERNIZED AUTO-FARM & EGG UTILITY
    Based on provided logic.
    Refactored for performance and UI/UX.
]]

local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Workspace = game:GetService("Workspace")
local UserInputService = game:GetService("UserInputService")
local RunService = game:GetService("RunService")
local TweenService = game:GetService("TweenService")
local CoreGui = game:GetService("CoreGui")

local Player = Players.LocalPlayer
local PlayerGui = Player:WaitForChild("PlayerGui")

--------------------------------------------------------------------------------
-- 1. CONFIGURATION & STATE
--------------------------------------------------------------------------------
local Config = {
    [cite_start]MinPrice = 1000000000,           -- Default 1B [cite: 2]
    [cite_start]MaxPrice = 100000000000,         -- Default 100B [cite: 2]
    [cite_start]Varieties = "diamond,glitch,galaxy", -- [cite: 3]
    [cite_start]FastSkipDelay = 0.01,            -- [cite: 3]
    AutoBuy = false,
    AutoFarm = false,
    [cite_start]AutoSpecial = true,              -- Admin/Dev/Limited [cite: 4]
    [cite_start]EventAutoBuy = true,             -- [cite: 4]
    SelectedEgg = "",                -- Name matching
}

local Remotes = {
    Purchase = nil,
    Request = nil,
    Collect = nil,
    Sell = nil
}

[cite_start]-- Safe Remote Lookup [cite: 4, 5]
local function FindRemotes()
    local modules = ReplicatedStorage:FindFirstChild("Modules")
    local internals = modules and modules:FindFirstChild("Internals")
    local skeleton = internals and internals:FindFirstChild("Skeleton")
    local conduit = skeleton and skeleton:FindFirstChild("Conduit")
    local instances = conduit and conduit:FindFirstChild("Instances")
    
    if instances then
        Remotes.Purchase = instances:FindFirstChild("_purchaseEgg")
        Remotes.Request = instances:FindFirstChild("_requestEgg")
        Remotes.Collect = instances:FindFirstChild("_collectEarnings")
        Remotes.Sell = instances:FindFirstChild("_sellStack")
    end
end
FindRemotes()

--------------------------------------------------------------------------------
-- 2. HELPER FUNCTIONS (LOGIC)
--------------------------------------------------------------------------------

[cite_start]-- Parse "1.5B", "100k" into numbers [cite: 34]
local function ParsePrice(str)
    if not str or str == "" then return 0 end
    local s = str:lower():gsub("%$", ""):gsub(",", ""):gsub("%s+", "")
    local mult = 1
    if s:match("k$") then mult = 1000; s = s:gsub("k$", "") end
    if s:match("m$") then mult = 1000000; s = s:gsub("m$", "") end
    if s:match("b$") then mult = 1000000000; s = s:gsub("b$", "") end
    local n = tonumber(s)
    return n and (n * mult) or 0
end

[cite_start]-- Check if variety matches input string [cite: 23]
local function MatchesVariety(labelVariety)
    if not labelVariety then return false end
    local cleanLabel = labelVariety:lower():gsub("%s+", "")
    for part in string.gmatch(Config.Varieties:lower(), "[^,]+") do
        local target = part:gsub("^%s+", ""):gsub("%s+$", "")
        if cleanLabel == target then return true end
    end
    return false
end

[cite_start]-- Equip the "Box Stack" tool [cite: 66]
local function EquipBoxStack()
    local bp = Player:FindFirstChild("Backpack")
    local char = Player.Character
    if not bp or not char then return end
    
    local human = char:FindFirstChildOfClass("Humanoid")
    if not human then return end

    -- Check if already equipped
    local equipped = char:FindFirstChildOfClass("Tool")
    if equipped and equipped.Name:match("^Box Stack %[") then return true end

    -- Find in backpack
    for _, item in ipairs(bp:GetChildren()) do
        if item:IsA("Tool") and item.Name:match("^Box Stack %[") then
            human:EquipTool(item)
            return true
        end
    end
    return false
end

--------------------------------------------------------------------------------
-- 3. MODERN UI LIBRARY
--------------------------------------------------------------------------------
local UI = {}
local MainFrame = nil

function UI.Create()
    -- Destroy old instances
    if CoreGui:FindFirstChild("ModernAutoHub") then
        CoreGui.ModernAutoHub:Destroy()
    end

    local Screen = Instance.new("ScreenGui")
    Screen.Name = "ModernAutoHub"
    Screen.Parent = CoreGui
    Screen.ZIndexBehavior = Enum.ZIndexBehavior.Sibling

    local Frame = Instance.new("Frame")
    Frame.Name = "MainFrame"
    Frame.Size = UDim2.new(0, 500, 0, 350)
    Frame.Position = UDim2.new(0.5, -250, 0.5, -175)
    Frame.BackgroundColor3 = Color3.fromRGB(25, 25, 30)
    Frame.BorderSizePixel = 0
    Frame.ClipsDescendants = true
    Frame.Parent = Screen
    
    local Corner = Instance.new("UICorner", Frame)
    Corner.CornerRadius = UDim.new(0, 8)

    -- Draggable Logic
    local Dragging, DragInput, DragStart, StartPos
    Frame.InputBegan:Connect(function(input)
        if input.UserInputType == Enum.UserInputType.MouseButton1 then
            Dragging = true; DragStart = input.Position; StartPos = Frame.Position
        end
    end)
    Frame.InputChanged:Connect(function(input)
        if input.UserInputType == Enum.UserInputType.MouseMovement then DragInput = input end
    end)
    UserInputService.InputChanged:Connect(function(input)
        if input == DragInput and Dragging then
            local Delta = input.Position - DragStart
            Frame.Position = UDim2.new(StartPos.X.Scale, StartPos.X.Offset + Delta.X, StartPos.Y.Scale, StartPos.Y.Offset + Delta.Y)
        end
    end)
    UserInputService.InputEnded:Connect(function(input)
        if input.UserInputType == Enum.UserInputType.MouseButton1 then Dragging = false end
    end)

    -- Header
    local Header = Instance.new("Frame", Frame)
    Header.Size = UDim2.new(1, 0, 0, 40)
    Header.BackgroundColor3 = Color3.fromRGB(35, 35, 40)
    local Title = Instance.new("TextLabel", Header)
    Title.Text = "  AUTO UTILITY V2"
    Title.Size = UDim2.new(1, -40, 1, 0)
    Title.BackgroundTransparency = 1
    Title.TextColor3 = Color3.fromRGB(255, 255, 255)
    Title.Font = Enum.Font.GothamBold
    Title.TextSize = 16
    Title.TextXAlignment = Enum.TextXAlignment.Left

    -- Minimizing
    local MinBtn = Instance.new("TextButton", Header)
    MinBtn.Size = UDim2.new(0, 40, 1, 0)
    MinBtn.Position = UDim2.new(1, -40, 0, 0)
    MinBtn.Text = "-"
    MinBtn.BackgroundColor3 = Color3.fromRGB(200, 50, 50)
    MinBtn.TextColor3 = Color3.new(1,1,1)
    MinBtn.MouseButton1Click:Connect(function()
        Frame.Visible = not Frame.Visible
        -- Note: Re-opening logic would require a separate small button, 
        -- keeping simple toggle for now (RightControl to toggle visibility)
    end)
    UserInputService.InputBegan:Connect(function(io, gp)
        if not gp and io.KeyCode == Enum.KeyCode.RightControl then
            Frame.Visible = not Frame.Visible
        end
    end)

    -- Tabs Container
    local TabHolder = Instance.new("Frame", Frame)
    TabHolder.Size = UDim2.new(0, 120, 1, -40)
    TabHolder.Position = UDim2.new(0, 0, 0, 40)
    TabHolder.BackgroundColor3 = Color3.fromRGB(30, 30, 35)
    
    local ContentHolder = Instance.new("Frame", Frame)
    ContentHolder.Size = UDim2.new(1, -120, 1, -40)
    ContentHolder.Position = UDim2.new(0, 120, 0, 40)
    ContentHolder.BackgroundTransparency = 1

    MainFrame = {Tabs = TabHolder, Content = ContentHolder}
    return MainFrame
end

local function CreateTab(name)
    local TabBtn = Instance.new("TextButton", MainFrame.Tabs)
    TabBtn.Size = UDim2.new(1, 0, 0, 35)
    TabBtn.Position = UDim2.new(0, 0, 0, (#MainFrame.Tabs:GetChildren()-1) * 35)
    TabBtn.Text = name
    TabBtn.BackgroundColor3 = Color3.fromRGB(30, 30, 35)
    TabBtn.TextColor3 = Color3.fromRGB(150, 150, 150)
    TabBtn.Font = Enum.Font.GothamMedium
    TabBtn.TextSize = 14

    local Scroll = Instance.new("ScrollingFrame", MainFrame.Content)
    Scroll.Size = UDim2.new(1, -10, 1, -10)
    Scroll.Position = UDim2.new(0, 5, 0, 5)
    Scroll.BackgroundTransparency = 1
    Scroll.ScrollBarThickness = 4
    Scroll.Visible = false
    
    local List = Instance.new("UIListLayout", Scroll)
    List.Padding = UDim.new(0, 5)
    List.SortOrder = Enum.SortOrder.LayoutOrder

    TabBtn.MouseButton1Click:Connect(function()
        for _, v in pairs(MainFrame.Content:GetChildren()) do v.Visible = false end
        for _, v in pairs(MainFrame.Tabs:GetChildren()) do 
            v.TextColor3 = Color3.fromRGB(150, 150, 150)
            v.BackgroundColor3 = Color3.fromRGB(30, 30, 35)
        end
        Scroll.Visible = true
        TabBtn.TextColor3 = Color3.fromRGB(255, 255, 255)
        TabBtn.BackgroundColor3 = Color3.fromRGB(45, 45, 50)
    end)

    return Scroll
end

local function AddToggle(parent, text, configKey)
    local Container = Instance.new("Frame", parent)
    Container.Size = UDim2.new(1, 0, 0, 40)
    Container.BackgroundColor3 = Color3.fromRGB(40, 40, 45)
    Instance.new("UICorner", Container).CornerRadius = UDim.new(0, 6)

    local Label = Instance.new("TextLabel", Container)
    Label.Size = UDim2.new(0.7, 0, 1, 0)
    Label.Position = UDim2.new(0, 10, 0, 0)
    Label.BackgroundTransparency = 1
    Label.Text = text
    Label.TextColor3 = Color3.fromRGB(220, 220, 220)
    Label.Font = Enum.Font.Gotham
    Label.TextSize = 14
    Label.TextXAlignment = Enum.TextXAlignment.Left

    local Btn = Instance.new("TextButton", Container)
    Btn.Size = UDim2.new(0, 24, 0, 24)
    Btn.Position = UDim2.new(1, -34, 0.5, -12)
    Btn.BackgroundColor3 = Config[configKey] and Color3.fromRGB(0, 200, 100) or Color3.fromRGB(60, 60, 60)
    Btn.Text = ""
    Instance.new("UICorner", Btn).CornerRadius = UDim.new(0, 4)

    Btn.MouseButton1Click:Connect(function()
        Config[configKey] = not Config[configKey]
        TweenService:Create(Btn, TweenInfo.new(0.2), {
            BackgroundColor3 = Config[configKey] and Color3.fromRGB(0, 200, 100) or Color3.fromRGB(60, 60, 60)
        }):Play()
    end)
end

local function AddInput(parent, text, configKey, isNumber)
    local Container = Instance.new("Frame", parent)
    Container.Size = UDim2.new(1, 0, 0, 50)
    Container.BackgroundColor3 = Color3.fromRGB(40, 40, 45)
    Instance.new("UICorner", Container).CornerRadius = UDim.new(0, 6)

    local Label = Instance.new("TextLabel", Container)
    Label.Size = UDim2.new(1, -20, 0, 20)
    Label.Position = UDim2.new(0, 10, 0, 5)
    Label.BackgroundTransparency = 1
    Label.Text = text
    Label.TextColor3 = Color3.fromRGB(180, 180, 180)
    Label.Font = Enum.Font.Gotham
    Label.TextSize = 12
    Label.TextXAlignment = Enum.TextXAlignment.Left

    local Box = Instance.new("TextBox", Container)
    Box.Size = UDim2.new(1, -20, 0, 20)
    Box.Position = UDim2.new(0, 10, 0, 25)
    Box.BackgroundTransparency = 1
    Box.Text = tostring(Config[configKey])
    Box.TextColor3 = Color3.fromRGB(255, 255, 255)
    Box.Font = Enum.Font.GothamBold
    Box.TextSize = 14
    Box.TextXAlignment = Enum.TextXAlignment.Left
    
    Box.FocusLost:Connect(function()
        if isNumber then
            local num = tonumber(Box.Text)
            if num then Config[configKey] = num end
        else
            Config[configKey] = Box.Text
        end
        Box.Text = tostring(Config[configKey])
    end)
end

-- Build the UI
local UIStruct = UI.Create()
local BuyTab = CreateTab("Auto Buy")
local FarmTab = CreateTab("Auto Farm")
local SettingsTab = CreateTab("Settings")

-- Populate Auto Buy Tab
AddToggle(BuyTab, "Enable Auto Buy", "AutoBuy")
AddToggle(BuyTab, "Auto Buy Special (Dev/Admin)", "AutoSpecial")
AddToggle(BuyTab, "Auto Buy During Events", "EventAutoBuy")
AddInput(BuyTab, "Target Varieties (e.g. diamond,glitch)", "Varieties", false)
AddInput(BuyTab, "Specific Egg Name (Optional)", "SelectedEgg", false)

-- Populate Auto Farm Tab
AddToggle(FarmTab, "Enable Auto Farm", "AutoFarm")

-- Populate Settings Tab
AddInput(SettingsTab, "Min Price", "MinPrice", true)
AddInput(SettingsTab, "Max Price", "MaxPrice", true)
AddInput(SettingsTab, "Skip Delay", "FastSkipDelay", true)


--------------------------------------------------------------------------------
-- 4. MAIN LOGIC LOOPS
--------------------------------------------------------------------------------

[cite_start]-- LOGIC: Auto Farm (Equip -> Collect -> Sell) [cite: 70]
task.spawn(function()
    while true do
        if Config.AutoFarm then
            local hasTool = EquipBoxStack()
            
            if Remotes.Collect then
                Remotes.Collect:FireServer({["__raw"] = true, ["data"] = {}})
            end

            if hasTool and Remotes.Sell then
                Remotes.Sell:FireServer({["__raw"] = true, ["data"] = {}})
            end
            task.wait(1)
        else
            task.wait(0.5)
        end
    end
end)

[cite_start]-- LOGIC: Skip Spam (Requests new eggs) [cite: 58]
task.spawn(function()
    while true do
        if Config.AutoBuy then
            -- Default Fast Skip
            if Remotes.Request then
                Remotes.Request:FireServer({["__raw"] = true, ["data"] = {}})
            end
            task.wait(Config.FastSkipDelay)
        else
            task.wait(0.5)
        end
    end
end)

-- LOGIC: Purchase Handler
-- Scans the Workspace for 'Eggtag' UI elements and buys based on config
local function CheckAndBuy(label)
    if not Config.AutoBuy then return end
    if not label or not label.Parent then return end

    local container = label.Parent
    local rarityLabel = container:FindFirstChild("Rarity")
    local varietyLabel = container:FindFirstChild("Variety")
    
    local rarityText = rarityLabel and rarityLabel.Text:lower() or ""
    local varietyText = varietyLabel and varietyLabel.Text:lower() or ""
    local priceVal = ParsePrice(label.Text)

    local shouldBuy = false

    [cite_start]-- 1. Selected Egg Override [cite: 40]
    if Config.SelectedEgg ~= "" and container.Parent.Name:lower():match(Config.SelectedEgg:lower()) then
        shouldBuy = true
    [cite_start]-- 2. Special Rarity Override [cite: 48]
    elseif Config.AutoSpecial and (rarityText == "admin" or rarityText == "developer" or rarityText == "exclusive" or rarityText == "limited" or rarityText == "secret") then
        shouldBuy = true
    [cite_start]-- 3. Standard Price & Variety Check [cite: 50]
    elseif priceVal >= Config.MinPrice and priceVal <= Config.MaxPrice then
        if MatchesVariety(varietyText) then
            shouldBuy = true
        end
    end

    if shouldBuy then
        local model = label:FindFirstAncestorWhichIsA("Model")
        if model and Remotes.Purchase then
            local eggId = "entity_" .. model.Name .. "_egg"
            [cite_start]-- Fire Purchase [cite: 38]
            Remotes.Purchase:FireServer({
                ["__raw"] = true,
                ["data"] = {
                    ["id"] = eggId,
                    ["rarity"] = rarityLabel.Text,
                    ["variety"] = varietyLabel.Text
                }
            })
            
            [cite_start]-- If we bought something, fire a confirmed skip to clear it [cite: 61]
            if Remotes.Request then
                task.wait(0.1)
                Remotes.Request:FireServer({["__raw"] = true, ["data"] = {["confirmedSkip"] = true}})
            end
        end
    end
end

[cite_start]-- Monitor Workspace for new Price tags [cite: 52]
Workspace.DescendantAdded:Connect(function(descendant)
    if descendant:IsA("TextLabel") and descendant.Name == "Price" then
        descendant:GetPropertyChangedSignal("Text"):Connect(function()
            CheckAndBuy(descendant)
        end)
        -- Initial check
        task.wait() 
        CheckAndBuy(descendant)
    end
end)

-- Initial Scan of existing tags
for _, v in pairs(Workspace:GetDescendants()) do
    if v:IsA("TextLabel") and v.Name == "Price" then
        v:GetPropertyChangedSignal("Text"):Connect(function() CheckAndBuy(v) end)
    end
end

[cite_start]-- LOGIC: Event Monitor [cite: 53, 54]
-- Checks if "EventBoard" says active, forces AutoBuy on if so.
task.spawn(function()
    while true do
        task.wait(2)
        if Config.EventAutoBuy then
            local map = Workspace:FindFirstChild("Map")
            local essentials = map and map:FindFirstChild("Essentials")
            local board = essentials and essentials:FindFirstChild("EventBoard")
            
            if board then
                local gui = board:FindFirstChild("SurfaceGui")
                local glitch = gui and gui:FindFirstChild("Glitch")
                local galaxy = gui and gui:FindFirstChild("Galaxy")
                
                local active = false
                if glitch and glitch:IsA("TextLabel") and glitch.Text:lower():find("event is active") then active = true end
                if galaxy and galaxy:IsA("TextLabel") and galaxy.Text:lower():find("event is active") then active = true end
                
                if active then
                    Config.AutoBuy = true
                    -- Optional: Update visual toggle if needed, but state is what matters
                end
            end
        end
    end
end)

print("Modern Auto Utility Loaded.")
