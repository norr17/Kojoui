-- Replace <owner> and <repo> with your GitHub repository before using this file remotely.
local repo = "https://raw.githubusercontent.com/<owner>/<repo>/main/"

local Library = loadstring(game:HttpGet(repo .. "Library.lua"))()
local ThemeManager = loadstring(game:HttpGet(repo .. "addons/ThemeManager.lua"))()
local SaveManager = loadstring(game:HttpGet(repo .. "addons/SaveManager.lua"))()

getgenv().KOJO_SafeMode = false
getgenv().KojoObsidianLocal = {
    Library = Library,
    ThemeManager = ThemeManager,
    SaveManager = SaveManager,
}

loadstring(game:HttpGet(repo .. "KojoExample.lua"))()
