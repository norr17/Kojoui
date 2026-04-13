# Feature Overview

## Core Library Layer

These features now live directly in `Library.lua` and apply to normal Obsidian-style scripts after a repo-link swap:

- redesigned shell
- redesigned sidebar and compact/expand motion
- updated top bar and footer badge styling
- built-in `Dashboard` tab
- built-in `Hub Settings` tab
- runtime/license dashboard surface
- embedded preview viewport
- nametag footer + head nametag support
- profile and presence controls
- custom icon support
- custom background support

If another script already creates windows, tabs, groupboxes, toggles, and config using Obsidian-style calls, replacing the repo base is enough to get the updated shell plus the Kojo core tabs.

## Kojo Product Layer

These larger product-specific surfaces are still part of the full Kojo example, not the lightweight compatibility layer:

- social workspace shell
- AI workspace shell
- cross-user nametag consumption
- server/global/direct-message flows

These require `KojoExample.lua` or equivalent product integration.

## Safe Mode

Safe mode stays script-controlled:

```lua
getgenv().KOJO_SafeMode = true
```

The built-in Kojo core reads it and keeps the head nametag disabled while still allowing the preview panel.

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

Those values are exact when the script is launched through the real loader/runtime bridge.
