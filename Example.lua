--[[
    InfernixLib Executor Example
    Demonstrates the new Windows 11 style executor
]]

-- Load the library
local InfernixLib = loadstring(game:HttpGet("https://raw.githubusercontent.com/aauuzyy/InfernixLib/main/InfernixLib.lua?v=" .. os.time()))()

-- Create executor window
local Executor = InfernixLib:CreateExecutor({
    Name = "Infernix Executor"
})

-- Create default tabs
local ScriptTab = Executor:CreateTab("Script 1")
local Script2Tab = Executor:CreateTab("Script 2")
local Script3Tab = Executor:CreateTab("Settings")

-- Add some example code to the first tab
ScriptTab:SetCode([[
-- Welcome to Infernix Executor!
-- Write your Lua code here and click Execute

print("Hello from Infernix!")

-- Example: Get local player
local Players = game:GetService("Players")
local LocalPlayer = Players.LocalPlayer
print("Your name is:", LocalPlayer.Name)
]])

-- Show the executor
Executor:Show()

-- Notification
InfernixLib:Notify({
    Title = "Infernix Executor",
    Content = "Executor loaded! Press RightControl to toggle.",
    Duration = 5
})

print("Infernix Executor loaded successfully!")
