-- Modernized Anime Egg Farm Pro
local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Workspace = game:GetService("Workspace")
local UIS = game:GetService("UserInputService")
local player = Players.LocalPlayer

-- // Configuration [cite: 2, 3]
local Settings = {
    AutoBuy = false,
    AutoFarm = false,
    CurrentTab = "Main",
    Rarities = {
        ["secret"] = true,
        ["legendary"] = false,
        ["mythic"] = false,
        ["exclusive"] = true,
        ["limited"] = true,
        ["developer"] = true,
        ["admin"] = true
    },
    FastSkipDelay = 0.01 -- [cite: 3]
}

-- // Remote Fetching [cite: 4, 5]
local Remotes = {}
pcall(function()
    local conduit = ReplicatedStorage.Modules.Internals.Skeleton.Conduit.Instances
    Remotes.Purchase = conduit._purchaseEgg
    Remotes.Request = conduit._requestEgg
    Remotes.Collect = conduit._collectEarnings
    Remotes.Sell = conduit._sellStack
end)

-- // UI Creation [cite: 5, 6, 7]
local Gui = Instance.new("ScreenGui", player.PlayerGui)
Gui.Name = "AuraFarm_V3"

local Main = Instance.new("Frame", Gui)
Main.Size = UDim2.new(0, 350, 0, 280)
Main.Position = UDim2.new(0.5, -175, 0.5, -140)
Main.BackgroundColor3 = Color3.fromRGB(15, 15, 17)
Main.BorderSizePixel = 0
Instance.new("UICorner", Main).CornerRadius = UDim.new(0, 10)

-- Sidebar Tabs
local Sidebar = Instance.new("Frame", Main)
Sidebar.Size = UDim2.new(0, 80, 1, 0)
Sidebar.BackgroundColor3 = Color3.fromRGB(20, 20, 22)
Instance.new("UICorner", Sidebar).CornerRadius = UDim.new(0, 10)

local Container = Instance.new("Frame", Main)
Container.Size = UDim2.new(1, -90, 1, -10)
Container.Position = UDim2.new(0, 85, 0, 5)
Container.BackgroundTransparency = 1

-- // Logic: Egg Detection [cite: 42, 48, 49]
local function checkEgg(label)
    if not label or not label.Parent then return false end
    local rarity = tostring(label.Parent:FindFirstChild("Rarity").Text):lower()
    
    if Settings.Rarities[rarity] then
        return true
    end
    return false
end

-- // Core Skip Loop [cite: 58, 62, 65]
task.spawn(function()
    while task.wait(Settings.FastSkipDelay) do
        if Settings.AutoBuy then
            local foundTarget = false
            for _, tag in ipairs(Workspace:GetDescendants()) do
                if tag.Name == "Eggtag" then
                    local priceLabel = tag:FindFirstChild("Price", true)
                    if priceLabel and checkEgg(priceLabel) then
                        foundTarget = true
                        -- Fire Purchase [cite: 38, 39]
                        Remotes.Purchase:FireServer({
                            ["__raw"] = true,
                            ["data"] = {
                                id = "entity_" .. tag.Parent.Name .. "_egg",
                                rarity = tag.Container.Rarity.Text,
                                variety = tag.Container.Variety.Text
                            }
                        })
                        task.wait(1) -- Stop to ensure purchase [cite: 3]
                    end
                end
            end
            
            if not foundTarget then
                Remotes.Request:FireServer({["__raw"] = true, ["data"] = {["confirmedSkip"] = true}})
            end
        end
    end
end)

-- // AutoFarm Loop [cite: 66, 69, 71]
task.spawn(function()
    while task.wait(1) do
        if Settings.AutoFarm then
            Remotes.Collect:FireServer({["__raw"] = true, ["data"] = {}})
            -- Check for Box Stack [cite: 67, 68]
            local char = player.Character
            if char and char:FindFirstChildOfClass("Tool") and char:FindFirstChildOfClass("Tool").Name:find("Box Stack") then
                Remotes.Sell:FireServer({["__raw"] = true, ["data"] = {}})
            end
        end
    end
end)

-- // UI Helper (Modern Buttons)
local function createToggle(name, parent, settingKey, isRarity)
    local b = Instance.new("TextButton", parent)
    b.Size = UDim2.new(1, 0, 0, 35)
    b.BackgroundColor3 = Color3.fromRGB(30, 30, 35)
    b.Text = name
    b.TextColor3 = Color3.white
    b.Font = Enum.Font.GothamSemibold
    Instance.new("UICorner", b)
    
    local function update()
        local active = isRarity and Settings.Rarities[settingKey] or Settings[settingKey]
        b.BackgroundColor3 = active and Color3.fromRGB(80, 200, 120) or Color3.fromRGB(30, 30, 35)
    end
    
    b.MouseButton1Click:Connect(function()
        if isRarity then
            Settings.Rarities[settingKey] = not Settings.Rarities[settingKey]
        else
            Settings[settingKey] = not Settings[settingKey]
        end
        update()
    end)
    update()
end

-- Populate Tabs
local list = Instance.new("UIListLayout", Container)
list.Padding = UDim.new(0, 5)

-- Add Toggles [cite: 17, 49]
createToggle("Master Auto-Buy", Container, "AutoBuy", false)
createToggle("Auto Farm", Container, "AutoFarm", false)
createToggle("Stop Mythic", Container, "mythic", true)
createToggle("Stop Legendary", Container, "legendary", true)
createToggle("Stop Secret", Container, "secret", true)
createToggle("Stop Exclusive/Limited", Container, "exclusive", true)

-- Simple Dragging [cite: 29, 30]
local dragStart, startPos, dragging
Main.InputBegan:Connect(function(input)
    if input.UserInputType == Enum.UserInputType.MouseButton1 then
        dragging = true; dragStart = input.Position; startPos = Main.Position
    end
end)
UIS.InputChanged:Connect(function(input)
    if dragging and input.UserInputType == Enum.UserInputType.MouseMovement then
        local delta = input.Position - dragStart
        Main.Position = UDim2.new(startPos.X.Scale, startPos.X.Offset + delta.X, startPos.Y.Scale, startPos.Y.Offset + delta.Y)
    end
end)
UIS.InputEnded:Connect(function(input) if input.UserInputType == Enum.UserInputType.MouseButton1 then dragging = false end end)
