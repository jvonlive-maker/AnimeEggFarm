--[[ 
    ANIME EGG FARM PRO - REHAULED VERSION
    Features: Rarity Filtering, Modern UI, Optimized Auto-Farm
]]

local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Workspace = game:GetService("Workspace")
local UserInputService = game:GetService("UserInputService")
local player = Players.LocalPlayer

-- // Configuration Store
local Settings = {
    AutoBuy = false,
    AutoFarm = false,
    FastSkip = true,
    SkipDelay = 0.01,
    Rarities = {
        ["Secret"] = true,
        ["Legendary"] = false,
        ["Mythic"] = false,
        ["Exclusive"] = true,
        ["Limited"] = true
    },
    Varieties = {"diamond", "glitch", "galaxy"}
}

-- // Remote Handling
local Remotes = {}
do
    local path = ReplicatedStorage:FindFirstChild("Instances", true)
    if path then
        Remotes.Purchase = path:FindFirstChild("_purchaseEgg")
        Remotes.Request = path:FindFirstChild("_requestEgg")
        Remotes.Collect = path:FindFirstChild("_collectEarnings")
        Remotes.Sell = path:FindFirstChild("_sellStack")
    end
end

-- // UI CONSTRUCTION
local ScreenGui = Instance.new("ScreenGui", player:WaitForChild("PlayerGui"))
ScreenGui.Name = "AnimeEggFarmV2"

local MainFrame = Instance.new("Frame", ScreenGui)
MainFrame.Size = UDim2.new(0, 300, 0, 400)
MainFrame.Position = UDim2.new(0.5, -150, 0.5, -200)
MainFrame.BackgroundColor3 = Color3.fromRGB(25, 25, 25)
MainFrame.BorderSizePixel = 0

local Corner = Instance.new("UICorner", MainFrame)
Corner.CornerRadius = UDim.new(0, 10)

-- Header
local Header = Instance.new("Frame", MainFrame)
Header.Size = UDim2.new(1, 0, 0, 40)
Header.BackgroundColor3 = Color3.fromRGB(35, 35, 35)
Instance.new("UICorner", Header)

local Title = Instance.new("TextLabel", Header)
Title.Size = UDim2.new(1, -10, 1, 0)
Title.Position = UDim2.new(0, 10, 0, 0)
Title.Text = "ANIME EGG FARM PRO"
Title.TextColor3 = Color3.fromRGB(255, 255, 255)
Title.Font = Enum.Font.GothamBold
Title.TextXAlignment = Enum.TextXAlignment.Left
Title.BackgroundTransparency = 1

-- Container for Toggles
local Scroll = Instance.new("ScrollingFrame", MainFrame)
Scroll.Size = UDim2.new(1, -20, 1, -50)
Scroll.Position = UDim2.new(0, 10, 0, 45)
Scroll.BackgroundTransparency = 1
Scroll.ScrollBarThickness = 2
Scroll.CanvasSize = UDim2.new(0, 0, 2, 0)

local List = Instance.new("UIListLayout", Scroll)
List.Padding = UDim.new(0, 5)

-- // HELPER: Create Modern Toggle
local function CreateToggle(name, parent, default, callback)
    local Btn = Instance.new("TextButton", parent)
    Btn.Size = UDim2.new(1, 0, 0, 35)
    Btn.BackgroundColor3 = default and Color3.fromRGB(40, 150, 40) or Color3.fromRGB(50, 50, 50)
    Btn.Text = name .. (default and ": ON" or ": OFF")
    Btn.TextColor3 = Color3.white
    Btn.Font = Enum.Font.Gotham
    Instance.new("UICorner", Btn)
    
    Btn.MouseButton1Click:Connect(function()
        local newState = not Btn:GetAttribute("Active")
        Btn:SetAttribute("Active", newState)
        Btn.BackgroundColor3 = newState and Color3.fromRGB(40, 150, 40) or Color3.fromRGB(50, 50, 50)
        Btn.Text = name .. (newState and ": ON" or ": OFF")
        callback(newState)
    end)
    Btn:SetAttribute("Active", default)
end

-- // LOGIC: Rarity Detection
local function ShouldBuy(label)
    local container = label.Parent
    local rarityLabel = container:FindFirstChild("Rarity")
    if not rarityLabel then return false end
    
    local rarityText = rarityLabel.Text:gsub("%s", "")
    -- Stop based on user choices instead of money
    if Settings.Rarities[rarityText] then
        return true
    end
    return false
end

-- // CORE LOOPS
task.spawn(function()
    while task.wait(Settings.SkipDelay) do
        if Settings.AutoBuy then
            -- Logic to check current egg tag in workspace
            for _, tag in ipairs(workspace:GetDescendants()) do
                if tag.Name == "Eggtag" then
                    local priceLabel = tag:FindFirstChild("Price", true)
                    if priceLabel and ShouldBuy(priceLabel) then
                        -- Found target rarity! Stop skipping and buy.
                        Settings.AutoBuy = false 
                        Remotes.Purchase:FireServer({["__raw"] = true, ["data"] = {id = "entity_"..tag.Parent.Name.."_egg"}})
                        task.wait(1)
                        Settings.AutoBuy = true
                    else
                        -- Not target, keep skipping
                        Remotes.Request:FireServer({["__raw"] = true, ["data"] = {["confirmedSkip"] = true}})
                    end
                end
            end
        end
    end
end)

-- // UI Initialization
CreateToggle("Master Auto-Buy", Scroll, false, function(v) Settings.AutoBuy = v end)
CreateToggle("Stop on Secrets", Scroll, true, function(v) Settings.Rarities["Secret"] = v end)
CreateToggle("Stop on Legendaries", Scroll, false, function(v) Settings.Rarities["Legendary"] = v end)
CreateToggle("Stop on Mythics", Scroll, false, function(v) Settings.Rarities["Mythic"] = v end)
CreateToggle("Auto-Farm (Sell/Collect)", Scroll, false, function(v) Settings.AutoFarm = v end)

-- Dragging Functionality
local dragging, dragInput, dragStart, startPos
Header.InputBegan:Connect(function(input)
    if input.UserInputType == Enum.UserInputType.MouseButton1 then
        dragging = true; dragStart = input.Position; startPos = MainFrame.Position
    end
end)

UserInputService.InputChanged:Connect(function(input)
    if dragging and input.UserInputType == Enum.UserInputType.MouseMovement then
        local delta = input.Position - dragStart
        MainFrame.Position = UDim2.new(startPos.X.Scale, startPos.X.Offset + delta.X, startPos.Y.Scale, startPos.Y.Offset + delta.Y)
    end
end)

UserInputService.InputEnded:Connect(function(input)
    if input.UserInputType == Enum.UserInputType.MouseButton1 then dragging = false end
end)
