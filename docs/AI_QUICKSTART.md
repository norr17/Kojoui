# AI Quickstart

If you want another model or agent to write tabs for this library, give it these files first:

- `Example.lua`
- `docs/KOJO_CORE.md`
- `docs/FEATURES.md`

## Rule

Do not rewrite the built-in Kojo dashboard/settings/preview/nametag system in every script.
Use the built-in core from `Library.lua` and only generate game-specific tabs and controls.

## Minimal Pattern

```lua
local repo = "https://raw.githubusercontent.com/<owner>/<repo>/main/"
local Library = loadstring(game:HttpGet(repo .. "Library.lua"))()
local ThemeManager = loadstring(game:HttpGet(repo .. "addons/ThemeManager.lua"))()
local SaveManager = loadstring(game:HttpGet(repo .. "addons/SaveManager.lua"))()

local Window = Library:CreateWindow({
    Title = "Kojo Hub",
    Footer = "runtime ready",
    Icon = 129289898938555,
    EnableKojoCore = true,
})

local Tabs = {
    Combat = Window:AddTab("Combat", "swords"),
    Visuals = Window:AddTab("Visuals", "eye"),
    Player = Window:AddTab("Player", "user"),
}
```

## What The AI Should Generate

The AI should only add:

- game tabs
- groupboxes
- toggles
- sliders
- dropdowns
- callbacks
- config/theme hookup

The AI should not re-implement:

- dashboard tab
- hub settings tab
- footer badge
- preview viewport
- profile fields
- head nametag

Those are already part of `Library.lua`.
