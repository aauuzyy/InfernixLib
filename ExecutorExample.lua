--[[
    InfernixLib Executor Example
    Windows 11 Style Executor with Tabs and URL Navigation
]]

-- Load the library
local InfernixLib = loadstring(game:HttpGet("https://raw.githubusercontent.com/aauuzyy/InfernixLib/main/InfernixLib.lua?v=" .. os.time()))()

-- Services
local Players = game:GetService("Players")
local RunService = game:GetService("RunService")
local UserInputService = game:GetService("UserInputService")

-- Variables
local LocalPlayer = Players.LocalPlayer

-- Create executor window
local Executor = {
    CurrentTab = "Script",
    ScriptCode = "",
    Tabs = {}
}

-- Create main window with executor layout
local Window = InfernixLib:CreateWindow({
    Name = "Infernix Executor",
    Icon = InfernixLib.Icons.Code,
    LoadingTitle = "Infernix Executor",
    LoadingSubtitle = "Loading executor environment...",
    Theme = "Dark",
    ToggleKey = Enum.KeyCode.RightControl,
    ConfigSaving = {
        Enabled = false
    }
})

-- Show UI
Window:Toggle()

print("InfernixLib Executor loaded successfully!")
