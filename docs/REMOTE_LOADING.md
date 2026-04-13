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

The Kojo dashboard/settings/preview/nametag core now mounts automatically from `Library.lua`.

## Lightweight Example

If you want the recommended lightweight script template:

```lua
loadstring(game:HttpGet("https://raw.githubusercontent.com/<owner>/<repo>/main/Example.lua"))()
```

## Full Kojo Product Example

If you want the full Kojo product UI:

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

## Runtime Data

Exact runtime fields such as:

- license key
- tier
- executions
- Discord tag
- expiry
- countdown
- place name

only become real when the UI is launched through the real loader/runtime bridge. Direct standalone GitHub example execution is only for UI and local behavior testing.
