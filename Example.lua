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

-- The executor comes with a default "Console" tab
-- You can add more tabs by clicking the file icon button

-- Show the executor
Executor:Show()

-- Notification
InfernixLib:Notify({
    Title = "Infernix Executor",
    Content = "Executor loaded! Press LeftControl to toggle.",
    Duration = 5
})

print("Infernix Executor loaded successfully!")
