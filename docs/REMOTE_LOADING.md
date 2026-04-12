# Remote Loading

## Drop-In Obsidian Replacement

If your script already loads Obsidian with a raw GitHub base URL, keep the same file paths and replace only the repo base:

```lua
local repo = "https://raw.githubusercontent.com/<owner>/<repo>/main/"

local Library = loadstring(game:HttpGet(repo .. "Library.lua"))()
local ThemeManager = loadstring(game:HttpGet(repo .. "addons/ThemeManager.lua"))()
local SaveManager = loadstring(game:HttpGet(repo .. "addons/SaveManager.lua"))()
```

This keeps compatibility with scripts that already expect:

- `Library.lua`
- `addons/ThemeManager.lua`
- `addons/SaveManager.lua`

## Kojo Product Example

If you want the Kojo example UI itself:

```lua
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
```

## Kojo Product Example With Safe Mode

```lua
local repo = "https://raw.githubusercontent.com/<owner>/<repo>/main/"

local Library = loadstring(game:HttpGet(repo .. "Library.lua"))()
local ThemeManager = loadstring(game:HttpGet(repo .. "addons/ThemeManager.lua"))()
local SaveManager = loadstring(game:HttpGet(repo .. "addons/SaveManager.lua"))()

getgenv().KOJO_SafeMode = true
getgenv().KojoObsidianLocal = {
    Library = Library,
    ThemeManager = ThemeManager,
    SaveManager = SaveManager,
}

loadstring(game:HttpGet(repo .. "KojoExample.lua"))()
```

## Runtime Data

Exact runtime fields such as:

- license key
- tier
- executions
- Discord tag
- expiry
- countdown
- place name

only become real when the UI is launched through your real loader/runtime bridge. Direct standalone example execution is only for UI and local behavior testing.
