# Kojo Obsidian

Kojo Obsidian keeps the Obsidian-compatible file surface:

- `Library.lua`
- `addons/ThemeManager.lua`
- `addons/SaveManager.lua`

If an existing script already loads Obsidian from a GitHub raw base, replacing only the repo base is enough to get:

- the Kojo shell and sidebar
- a built-in `Dashboard` tab
- a built-in `Hub Settings` tab
- built-in profile, preview, nametag, and runtime/license surfaces

## Repository Layout

```text
obsidian_kojo/
|-- Library.lua
|-- Library.d.luau
|-- init.luau
|-- Example.lua
|-- LegacyExample.lua
|-- KojoLiteExample.lua
|-- KojoExample.lua
|-- KojoExampleRemote.lua
|-- KojoExampleRemoteSafe.lua
|-- LocalExample.lua
|-- LocalExampleSafe.lua
|-- addons/
|   |-- SaveManager.lua
|   `-- ThemeManager.lua
|-- assets/
|-- docs/
|   |-- FEATURES.md
|   |-- KOJO_CORE.md
|   |-- REMOTE_LOADING.md
|   |-- STRUCTURE.md
|   `-- AI_QUICKSTART.md
|-- README.md
|-- CHANGELOG.md
`-- LICENSE
```

## Drop-In Compatibility

```lua
local repo = "https://raw.githubusercontent.com/<owner>/<repo>/main/"
local Library = loadstring(game:HttpGet(repo .. "Library.lua"))()
local ThemeManager = loadstring(game:HttpGet(repo .. "addons/ThemeManager.lua"))()
local SaveManager = loadstring(game:HttpGet(repo .. "addons/SaveManager.lua"))()
```

Existing scripts keep their own tabs and controls. The library now also auto-mounts Kojo core tabs unless you disable them with `EnableKojoCore = false` in `CreateWindow`.

## Built-In Kojo Core

When `EnableKojoCore` is on, every window gets:

- `Dashboard`
  - runtime identity
  - Discord/tier/license data
  - countdown and game name
  - preview viewport
  - access actions
- `Hub Settings`
  - profile editing
  - head nametag toggle
  - presence toggle
  - window background settings
  - nametag settings
  - preview backdrop settings
  - key deletion / unload / keybind frame / window scale

These features live in `Library.lua`, not only in `KojoExample.lua`.

## Examples

- `Example.lua`
  - lightweight recommended example for AI and new scripts
- `KojoLiteExample.lua`
  - same lightweight example with Kojo naming
- `LegacyExample.lua`
  - older large Obsidian-style example
- `KojoExample.lua`
  - full Kojo product example

## Documentation

- [Remote loading](docs/REMOTE_LOADING.md)
- [Structure](docs/STRUCTURE.md)
- [Features](docs/FEATURES.md)
- [Kojo core](docs/KOJO_CORE.md)
- [AI quickstart](docs/AI_QUICKSTART.md)
