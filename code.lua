--[ MODERNIZED AUTO-UTILITY ]--
local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local TweenService = game:GetService("TweenService")
local UserInputService = game:GetService("UserInputService")

local Player = Players.LocalPlayer
local PlayerGui = Player:WaitForChild("PlayerGui")

--// Configuration Module
local Config = {
    Colors = {
        Main = Color3.fromRGB(20, 20, 25),
        Accent = Color3.fromRGB(0, 170, 255),
        Success = Color3.fromRGB(0, 255, 120),
        Text = Color3.fromRGB(240, 240, 240)
    },
    Defaults = {
        MinPrice = 1000000000, -- [cite: 2]
        MaxPrice = 100000000000, -- [cite: 2]
        Varieties = "diamond,glitch,galaxy" -- [cite: 3]
    }
}

--// State Controller
local State = {
    AutoBuy = false,
    AutoFarm = false,
    SpecialRarities = true, -- [cite: 4]
    FastSkip = 0.01 -- [cite: 2]
}

--// Remote Handler (Best Effort)
local Remotes = {}
do
    local path = ReplicatedStorage:FindFirstChild("Instances", true)
    if path then
        Remotes.Purchase = path:FindFirstChild("_purchaseEgg") -- 
        Remotes.Request = path:FindFirstChild("_requestEgg") -- 
        Remotes.Collect = path:FindFirstChild("_collectEarnings") -- 
        Remotes.Sell = path:FindFirstChild("_sellStack") -- 
    end
end

--// Modern UI Constructor
local function CreateModernUI()
    local Screen = Instance.new("ScreenGui", PlayerGui)
    Screen.Name = "ModernAuto"
    Screen.ResetOnSpawn = false -- 

    -- Main Panel
    local Main = Instance.new("Frame", Screen)
    Main.Size = UDim2.new(0, 450, 0, 300)
    Main.Position = UDim2.new(0.5, -225, 0.5, -150)
    Main.BackgroundColor3 = Config.Colors.Main
    Main.BorderSizePixel = 0
    
    local Corner = Instance.new("UICorner", Main)
    Corner.CornerRadius = UDim.new(0, 10) -- [cite: 6]

    -- Title Bar
    local Header = Instance.new("Frame", Main)
    Header.Size = UDim2.new(1, 0, 0, 40)
    Header.BackgroundTransparency = 1 -- [cite: 6]

    local Title = Instance.new("TextLabel", Header)
    Title.Text = "  PRO SIMULATOR UTILITY"
    Title.Size = UDim2.new(1, 0, 1, 0)
    Title.TextColor3 = Config.Colors.Text
    Title.Font = Enum.Font.GothamBold
    Title.TextSize = 16
    Title.TextXAlignment = Enum.TextXAlignment.Left -- [cite: 6]

    return Main, Screen
end

local MainPanel, RootGui = CreateModernUI()

--// Core Systems: AutoFarm [cite: 70, 71]
task.spawn(function()
    while task.wait(1) do
        if State.AutoFarm then
            -- Equip Tool Logic
            local backpack = Player:FindFirstChild("Backpack")
            if backpack then
                for _, tool in ipairs(backpack:GetChildren()) do
                    if tool:IsA("Tool") and tool.Name:match("^Box Stack %[") then -- [cite: 66]
                        Player.Character.Humanoid:EquipTool(tool) -- [cite: 67]
                        break
                    end
                end
            end
            
            -- Network Signals
            if Remotes.Collect then Remotes.Collect:FireServer({["__raw"] = true, ["data"] = {}}) end -- [cite: 68]
            if Remotes.Sell then Remotes.Sell:FireServer({["__raw"] = true, ["data"] = {}}) end -- [cite: 69]
        end
    end
end)

--// Core Systems: AutoBuy/Skip Loop [cite: 59, 60]
task.spawn(function()
    while true do
        if State.AutoBuy then
            local args = { [1] = { ["__raw"] = true, ["data"] = {} } } -- [cite: 64]
            if Remotes.Request then
                Remotes.Request:FireServer(unpack(args)) -- [cite: 63]
            end
            task.wait(State.FastSkip) -- [cite: 65]
        else
            task.wait(0.5)
        end
    end
end)

print("Modernized Script Loaded Successfully.")
