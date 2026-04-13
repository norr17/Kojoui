# Kojo Core

`Library.lua` now mounts a built-in Kojo core on every window unless disabled.

## Default Behavior

```lua
local Window = Library:CreateWindow({
    Title = "Kojo Hub",
    Footer = "runtime ready",
    Icon = 129289898938555,
})
```

That automatically creates:

- `Dashboard`
- `Hub Settings`

## Window Options

You can customize the built-in core with these `CreateWindow` options:

- `EnableKojoCore = true`
- `KojoDashboardTabName = "Dashboard"`
- `KojoSettingsTabName = "Hub Settings"`
- `KojoAutoFooter = true`
- `KojoSafeMode = nil`

Example:

```lua
local Window = Library:CreateWindow({
    Title = "My Script",
    Footer = "v1",
    Icon = 129289898938555,
    EnableKojoCore = true,
    KojoDashboardTabName = "Home",
    KojoSettingsTabName = "Settings",
})
```

## Controller API

After creating a window, the controller is available at `Window.KojoCore`.

- `Window.KojoCore.DashboardTab`
- `Window.KojoCore.SettingsTab`
- `Window.KojoCore.Preview`
- `Window.KojoCore:Refresh()`
- `Window.KojoCore:RefreshProfile()`
- `Window.KojoCore:SetPreviewObject(instance, cloneObject)`
- `Window.KojoCore:UpdateHeadNametag()`

## Runtime Variables

The built-in dashboard reads these globals when available:

- `KOJO_ProfileName`
- `KOJO_ProfileAvatar`
- `KOJO_ProfileVisible`
- `KOJO_ProfileId`
- `KOJO_UserTier`
- `KOJO_LicenseKey`
- `KOJO_ExecutionCount`
- `KOJO_DiscordTag`
- `KOJO_ExpireAt`
- `KOJO_SecondsLeft`
- `KOJO_PlaceName`

## Safe Mode

Safe mode is script-controlled:

```lua
getgenv().KOJO_SafeMode = true
```

When enabled, the built-in preview stays available but the head nametag is forced off.
