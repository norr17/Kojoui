-- Kojo lightweight example.
-- Built-in Dashboard and Hub Settings are mounted by Library.lua automatically.
-- Keep this file small and put only game-specific controls here.

local repo = "https://raw.githubusercontent.com/<owner>/<repo>/main/"
local Library = loadstring(game:HttpGet(repo .. "Library.lua"))()
local ThemeManager = loadstring(game:HttpGet(repo .. "addons/ThemeManager.lua"))()
local SaveManager = loadstring(game:HttpGet(repo .. "addons/SaveManager.lua"))()

local Options = Library.Options
local Toggles = Library.Toggles

Library.ShowToggleFrameInKeybinds = true

local Window = Library:CreateWindow({
    Title = "Kojo Hub",
    Footer = "runtime ready",
    Icon = 129289898938555,
    NotifySide = "Right",
    ShowCustomCursor = true,
    EnableKojoCore = true,
    KojoDashboardTabName = "Dashboard",
    KojoSettingsTabName = "Hub Settings",
})

local Core = Window.KojoCore
local Tabs = {
    Combat = Window:AddTab("Combat", "swords"),
    Visuals = Window:AddTab("Visuals", "eye"),
    Player = Window:AddTab("Player", "user"),
}

local CombatMain = Tabs.Combat:AddLeftGroupbox("Combat")
CombatMain:AddToggle("AutoSwing", {
    Text = "Auto Swing",
    Default = false,
})
CombatMain:AddToggle("AutoPitch", {
    Text = "Auto Pitch",
    Default = false,
})
CombatMain:AddSlider("HitChance", {
    Text = "Hit Chance",
    Default = 80,
    Min = 0,
    Max = 100,
    Rounding = 0,
    Suffix = "%",
})
CombatMain:AddDropdown("TargetMode", {
    Text = "Target Mode",
    Values = { "Closest", "Cursor", "Lowest HP" },
    Default = "Closest",
})

local VisualMain = Tabs.Visuals:AddLeftGroupbox("Visuals")
VisualMain:AddToggle("ESPEnabled", {
    Text = "ESP",
    Default = false,
})
    :AddColorPicker("ESPColor", {
        Default = Color3.fromRGB(255, 164, 222),
        Title = "ESP Color",
    })
VisualMain:AddToggle("ShowNames", {
    Text = "Show Names",
    Default = true,
})
VisualMain:AddToggle("ShowDistance", {
    Text = "Show Distance",
    Default = true,
})

local PlayerMain = Tabs.Player:AddLeftGroupbox("Player")
PlayerMain:AddToggle("SpeedEnabled", {
    Text = "Override WalkSpeed",
    Default = false,
})
PlayerMain:AddSlider("WalkSpeed", {
    Text = "WalkSpeed",
    Default = 16,
    Min = 16,
    Max = 100,
    Rounding = 0,
})
PlayerMain:AddToggle("JumpEnabled", {
    Text = "Override JumpPower",
    Default = false,
})
PlayerMain:AddSlider("JumpPower", {
    Text = "JumpPower",
    Default = 50,
    Min = 50,
    Max = 150,
    Rounding = 0,
})

local InfoGroup = Tabs.Player:AddRightGroupbox("Runtime")
InfoGroup:AddLabel("Built-in tabs:", true)
InfoGroup:AddLabel("- Dashboard", true)
InfoGroup:AddLabel("- Hub Settings", true)
InfoGroup:AddLabel("Use Window.KojoCore for preview and nametag access.", true)
InfoGroup:AddButton("Refresh Dashboard", function()
    if Core and Core.Refresh then
        Core:Refresh()
    end
end)
InfoGroup:AddButton("Refresh Profile", function()
    if Core and Core.RefreshProfile then
        Core:RefreshProfile()
    end
end)

Toggles.AutoSwing:OnChanged(function()
    print("[Kojo] Auto Swing:", Toggles.AutoSwing.Value)
end)

Toggles.ESPEnabled:OnChanged(function()
    print("[Kojo] ESP:", Toggles.ESPEnabled.Value, Options.ESPColor.Value)
end)

Toggles.SpeedEnabled:OnChanged(function()
    print("[Kojo] Speed enabled:", Toggles.SpeedEnabled.Value, Options.WalkSpeed.Value)
end)

ThemeManager:SetLibrary(Library)
SaveManager:SetLibrary(Library)
SaveManager:IgnoreThemeSettings()
SaveManager:SetIgnoreIndexes({})
ThemeManager:SetFolder("KojoHub")
SaveManager:SetFolder("KojoHub/game")

if Core and Core.SettingsTab then
    SaveManager:BuildConfigSection(Core.SettingsTab)
    ThemeManager:ApplyToTab(Core.SettingsTab)
end

SaveManager:LoadAutoloadConfig()
