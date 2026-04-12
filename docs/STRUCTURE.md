# Structure

This repository is prepared to stay close to the expected Obsidian layout.

## Files To Keep Stable

If you want existing remote scripts to remain compatible, keep these paths unchanged:

- `Library.lua`
- `addons/ThemeManager.lua`
- `addons/SaveManager.lua`

Those three paths are the compatibility surface for scripts that already load Obsidian remotely.

## Files In This Fork

- `Library.lua`
  - core UI library
- `Library.d.luau`
  - type definitions
- `init.luau`
  - package entrypoint for structured require usage
- `Example.lua`
  - generic example template
- `KojoExample.lua`
  - Kojo product example
- `KojoExampleRemote.lua`
  - remote GitHub template for the Kojo example
- `KojoExampleRemoteSafe.lua`
  - remote GitHub template for the Kojo example with safe mode
- `LocalExample.lua`
  - local workspace launcher
- `LocalExampleSafe.lua`
  - local workspace launcher with safe mode

## Addons

The `addons/` folder intentionally stays separate, matching the common Obsidian loading pattern:

- `addons/ThemeManager.lua`
- `addons/SaveManager.lua`

## Assets

The `assets/` folder contains local assets used by the Kojo example layer:

- `assets/backdrops/`
- `assets/kojo_icons/`
- color/transparency helper images

These assets are not required by older plain Obsidian scripts unless they use the Kojo product example or custom local-asset features.

## Compatibility Rule

If your goal is "replace only the repo link", do not rename:

- `Library.lua`
- `addons/ThemeManager.lua`
- `addons/SaveManager.lua`

You can add new files freely as long as those existing paths remain valid.
