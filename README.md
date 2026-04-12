# Kojo Obsidian

Kojo Obsidian keeps the same drop-in file layout used by Obsidian-style remote loaders:

- `Library.lua`
- `addons/ThemeManager.lua`
- `addons/SaveManager.lua`

If an existing script already loads Obsidian with a GitHub raw base URL, you only need to replace the base URL. The rest of the load path can stay the same.

## Repository Layout

```text
obsidian_kojo/
├─ Library.lua
├─ Library.d.luau
├─ init.luau
├─ Example.lua
├─ KojoExample.lua
├─ KojoExampleRemote.lua
├─ KojoExampleRemoteSafe.lua
├─ LocalExample.lua
├─ LocalExampleSafe.lua
├─ addons/
│  ├─ SaveManager.lua
│  └─ ThemeManager.lua
├─ assets/
│  ├─ backdrops/
│  ├─ kojo_icons/
│  ├─ SaturationMap.png
│  └─ TransparencyTexture.png
└─ docs/
   ├─ REMOTE_LOADING.md
   ├─ STRUCTURE.md
   └─ FEATURES.md
```

## Drop-In Compatibility

This repository is prepared so existing Obsidian-style scripts can switch to the new design by replacing only the repo base:

```lua
local repo = "https://raw.githubusercontent.com/<owner>/<repo>/main/"
local Library = loadstring(game:HttpGet(repo .. "Library.lua"))()
local ThemeManager = loadstring(game:HttpGet(repo .. "addons/ThemeManager.lua"))()
local SaveManager = loadstring(game:HttpGet(repo .. "addons/SaveManager.lua"))()
```

If a script already uses that pattern, it will load the updated Kojo-styled library chrome automatically.

## Included Examples

- `Example.lua`
  - generic Obsidian-compatible example template
- `KojoExample.lua`
  - Kojo product UI example
- `KojoExampleRemote.lua`
  - remote GitHub template for the Kojo example
- `KojoExampleRemoteSafe.lua`
  - remote GitHub template for the Kojo example with safe mode enabled
- `LocalExample.lua`
  - local workspace launcher
- `LocalExampleSafe.lua`
  - local workspace launcher with safe mode enabled

## New Feature Areas

- redesigned shell and sidebar motion
- dashboard runtime/license surface
- optional preview panel and viewport support
- optional head nametag and nametag theme system
- optional workspace shell for social/AI surfaces
- custom icon and backdrop assets

Advanced product features stay in the Kojo example layer. Core compatibility stays in `Library.lua` and `addons/`.

## Documentation

- [Remote loading](docs/REMOTE_LOADING.md)
- [Structure and compatibility](docs/STRUCTURE.md)
- [Feature overview](docs/FEATURES.md)
