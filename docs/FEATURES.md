# Feature Overview

## Core Library Layer

These changes live in the main library and affect scripts that already use the Obsidian API surface:

- redesigned shell
- redesigned sidebar and compact/expand motion
- updated top bar and footer badge styling
- custom icon support
- custom background support
- viewport support
- improved tab/button motion

If another script already creates windows, tabs, groupboxes, toggles, and config using Obsidian-style calls, replacing the repo base is enough to get the updated visual design.

## Kojo Example Layer

These features are part of the Kojo product example, not the minimal compatibility layer:

- dashboard runtime surface
- embedded preview panel
- nametag theme system
- optional head nametag
- workspace shell for social and AI
- runtime/license dashboard integration

These require `KojoExample.lua` or equivalent integration code.

## Safe Mode

Safe mode is not exposed as a visible setting by default. It is intended to be controlled by script:

```lua
getgenv().KOJO_SafeMode = true
```

In the current example layer, safe mode is used to keep riskier advanced UI behavior disabled by default.

## Loader / Runtime Integration

The dashboard can show runtime values such as:

- user
- Discord
- tier
- license key
- expires in
- expires at
- countdown
- executions
- game name

Those values are exact only when the script is launched through the real loader/runtime bridge.

## Notes

- Core compatibility stays in `Library.lua` and `addons/`
- Product-specific behavior stays in `KojoExample.lua`
- Advanced features are opt-in at the example/product layer
