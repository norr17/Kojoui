# Structure

This repository stays close to the expected Obsidian layout.

## Files To Keep Stable

If you want existing remote scripts to remain compatible, keep these paths unchanged:

- `Library.lua`
- `addons/ThemeManager.lua`
- `addons/SaveManager.lua`

Those three paths are the compatibility surface for scripts that already load Obsidian remotely.

## Files In This Fork

- `Library.lua`
  - core UI library plus built-in Kojo dashboard/settings/preview/nametag tabs
- `Library.d.luau`
  - type definitions
- `init.luau`
  - package entrypoint for structured require usage
- `Example.lua`
  - lightweight recommended example
- `KojoLiteExample.lua`
  - lightweight example duplicate for Kojo-specific usage
- `LegacyExample.lua`
  - old large Obsidian-style example
- `KojoExample.lua`
  - full Kojo product example
- `KojoExampleRemote.lua`
  - remote GitHub template for the full Kojo example
- `KojoExampleRemoteSafe.lua`
  - remote GitHub template for the full Kojo example with safe mode
- `LocalExample.lua`
  - local workspace launcher
- `LocalExampleSafe.lua`
  - local workspace launcher with safe mode

## Addons

The `addons/` folder intentionally stays separate, matching the common Obsidian loading pattern:

- `addons/ThemeManager.lua`
- `addons/SaveManager.lua`

## Compatibility Rule

If your goal is "replace only the repo link", do not rename:

- `Library.lua`
- `addons/ThemeManager.lua`
- `addons/SaveManager.lua`

You can add new files freely as long as those existing paths remain valid.
