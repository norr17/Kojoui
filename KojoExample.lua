local Local = rawget(getgenv(), "KojoObsidianLocal")
local Library = assert(Local and Local.Library, "KojoObsidianLocal.Library is required")
local ThemeManager = assert(Local and Local.ThemeManager, "KojoObsidianLocal.ThemeManager is required")
local SaveManager = assert(Local and Local.SaveManager, "KojoObsidianLocal.SaveManager is required")
local MarketplaceService = game:GetService("MarketplaceService")
local Players = game:GetService("Players")
local RunService = game:GetService("RunService")
local TweenService = game:GetService("TweenService")
local KojoRoot = tostring(rawget(getgenv and getgenv() or _G, "KojoObsidianRoot") or "obsidian_kojo"):gsub("\\", "/")

local function assetPath(relativePath)
    return string.format("%s/assets/%s", KojoRoot, relativePath)
end

local Options = Library.Options
local Toggles = Library.Toggles

Library.ForceCheckbox = false
Library.ShowToggleFrameInKeybinds = true
Library.ShowCustomCursor = false

local Window = Library:CreateWindow({
    Title = "Kojo Hub",
    Footer = "Kojo v3.0",
    Icon = 129289898938555,
    NotifySide = "Right",
    ShowCustomCursor = false,
    DisableSearch = true,
    Resizable = false,
    AutoSelectFirstTab = true,
    SidebarCompacted = true,
    Size = UDim2.fromOffset(760, 560),
})

local Tabs = {
    Home = Window:AddTab("Home", "kojo-home"),
    Combat = Window:AddTab("Combat", "kojo-combat"),
    Visuals = Window:AddTab("Visuals", "kojo-visuals"),
    Player = Window:AddTab("Player", "kojo-player"),
    Advanced = Window:AddTab("Advanced", "kojo-advanced"),
    Settings = Window:AddTab("Settings", "kojo-settings"),
}

local LocalPlayer = Players.LocalPlayer
local KojoEnv = getgenv and getgenv() or _G

local function getKojoSocial()
    local bridge = rawget(KojoEnv, "KOJO_SOCIAL")
    if bridge == nil then
        bridge = rawget(_G, "KOJO_SOCIAL")
    end

    if type(bridge) == "table" then
        return bridge
    end

    return nil
end

local function notify(title, description)
    Library:Notify({
        Title = title,
        Description = description,
        Time = 3,
    })
end

local function getKojoValue(key, fallback)
    local value = rawget(KojoEnv, key)
    if value == nil then
        value = rawget(_G, key)
    end

    if value == nil then
        return fallback
    end

    return value
end

local function maskKey(value)
    value = tostring(value or "Unavailable")
    if #value <= 8 then
        return value
    end

    return value:sub(1, 4) .. string.rep("*", math.max(0, #value - 8)) .. value:sub(-4)
end

local function copyText(label, value)
    local success = pcall(function()
        setclipboard(value)
    end)

    if success then
        notify("Kojo", label .. " copied to clipboard")
    else
        notify("Kojo", "Clipboard is unavailable")
    end
end

local function setKojoEnvValue(key, value)
    pcall(function()
        rawset(_G, key, value)
    end)
    pcall(function()
        if getgenv then
            rawset(getgenv(), key, value)
        end
    end)
end

local function deleteSavedKey()
    local removed = false

    pcall(function()
        setKojoEnvValue("KojoKey", nil)
    end)

    pcall(function()
        if isfile and isfile("kojohub/key.txt") then
            delfile("kojohub/key.txt")
            removed = true
        end
    end)

    return removed
end

local BackgroundPresets = {
    None = "",
}

local function getBackgroundPresetNames()
    local names = { "None" }

    for name, _ in pairs(BackgroundPresets) do
        if name ~= "None" then
            table.insert(names, name)
        end
    end

    table.sort(names, function(a, b)
        if a == "None" then
            return true
        elseif b == "None" then
            return false
        end

        return a < b
    end)

    return names
end

local function registerBackgroundPreset(asset)
    if asset == "" then
        return "None"
    end

    for existingName, existingAsset in pairs(BackgroundPresets) do
        if existingAsset == asset then
            return existingName
        end
    end

    local assetId = asset:match("(%d+)")
    local baseName = assetId and ("Asset " .. assetId) or "Custom Background"
    local candidate = baseName
    local counter = 2

    while BackgroundPresets[candidate] ~= nil do
        candidate = string.format("%s %d", baseName, counter)
        counter += 1
    end

    BackgroundPresets[candidate] = asset
    if Options.WindowBackgroundPreset then
        Options.WindowBackgroundPreset:SetValues(getBackgroundPresetNames())
    end

    return candidate
end

local function normalizeBackgroundAsset(value)
    if typeof(value) ~= "string" then
        return ""
    end

    value = value:match("^%s*(.-)%s*$")
    if value == "" then
        return ""
    end

    local createStoreId = value:match("/asset/(%d+)")
    if createStoreId then
        return "rbxassetid://" .. createStoreId
    end

    local webAssetId = value:match("[?&]id=(%d+)")
    if webAssetId then
        return "rbxassetid://" .. webAssetId
    end

    local rawAssetId = value:match("^rbxassetid://(%d+)$")
    if rawAssetId then
        return "rbxassetid://" .. rawAssetId
    end

    if value:match("^%d+$") then
        return "rbxassetid://" .. value
    end

    return value
end

local function resolveBackgroundDisplayAsset(value)
    local normalized = normalizeBackgroundAsset(value)
    local assetId = normalized:match("(%d+)")

    if assetId then
        return string.format("rbxthumb://type=Asset&id=%s&w=768&h=432", assetId)
    end

    return normalized
end

local function applyBackgroundPreset(name)
    local preset = BackgroundPresets[name]
    if preset == nil then
        return
    end

    if preset == "" then
        Window:ClearBackgroundImage()
        return
    end

    Window:SetBackgroundImage(resolveBackgroundDisplayAsset(preset))
end

local function createPreviewBladeModel()
    local model = Instance.new("Model")
    model.Name = "KojoPreviewBlade"

    local handle = Instance.new("Part")
    handle.Name = "Handle"
    handle.Shape = Enum.PartType.Cylinder
    handle.Size = Vector3.new(0.38, 1.15, 0.38)
    handle.Color = Color3.fromRGB(42, 44, 54)
    handle.Material = Enum.Material.Metal
    handle.Anchored = true
    handle.CanCollide = false
    handle.Parent = model

    local guard = Instance.new("Part")
    guard.Name = "Guard"
    guard.Size = Vector3.new(0.22, 0.18, 0.92)
    guard.Color = Color3.fromRGB(205, 210, 218)
    guard.Material = Enum.Material.Metal
    guard.Anchored = true
    guard.CanCollide = false
    guard.CFrame = handle.CFrame * CFrame.new(0, 0.58, 0)
    guard.Parent = model

    local blade = Instance.new("WedgePart")
    blade.Name = "Blade"
    blade.Size = Vector3.new(0.14, 1.7, 0.74)
    blade.Color = Color3.fromRGB(226, 229, 235)
    blade.Material = Enum.Material.Metal
    blade.Anchored = true
    blade.CanCollide = false
    blade.CFrame = handle.CFrame * CFrame.new(0, 1.26, -0.1) * CFrame.Angles(math.rad(90), 0, math.rad(180))
    blade.Parent = model

    local ring = Instance.new("Part")
    ring.Name = "Ring"
    ring.Shape = Enum.PartType.Cylinder
    ring.Size = Vector3.new(0.12, 0.54, 0.54)
    ring.Color = Color3.fromRGB(215, 220, 228)
    ring.Material = Enum.Material.Metal
    ring.Anchored = true
    ring.CanCollide = false
    ring.CFrame = handle.CFrame * CFrame.new(0, -0.62, 0) * CFrame.Angles(0, 0, math.rad(90))
    ring.Parent = model

    model.PrimaryPart = handle
    model:PivotTo(CFrame.new(0, 0, 0) * CFrame.Angles(math.rad(-8), math.rad(18), math.rad(12)))

    return model
end

local function createAvatarPreviewModel()
    local character = LocalPlayer and LocalPlayer.Character
    if not character then
        return createPreviewBladeModel()
    end

    local originalArchivable = character.Archivable
    if not originalArchivable then
        character.Archivable = true
    end
    local clone = character:Clone()
    character.Archivable = originalArchivable
    clone.Name = "KojoPreviewAvatar"

    for _, descendant in ipairs(clone:GetDescendants()) do
        if descendant:IsA("BasePart") then
            descendant.Anchored = true
            descendant.CanCollide = false
        elseif descendant:IsA("Script") or descendant:IsA("LocalScript") then
            descendant:Destroy()
        elseif descendant:IsA("Animator") then
            descendant:Destroy()
        end
    end

    clone:PivotTo(CFrame.new(0, -1.4, 0) * CFrame.Angles(0, math.rad(25), 0))
    return clone
end

local function buildPreviewObject(kind)
    if kind == "Avatar" then
        return createAvatarPreviewModel()
    end

    return createPreviewBladeModel()
end

local function styleDashboardButton(Button, Spec, StrokeColor, TextColor)
    local Style = if typeof(Spec) == "table"
        then Spec
        else {
            BackgroundColor = Spec,
            StrokeColor = StrokeColor,
            TextColor = TextColor,
        }

    local BackgroundColor = Style.BackgroundColor or Color3.fromRGB(24, 27, 34)
    local ResolvedStroke = Style.StrokeColor or BackgroundColor:Lerp(Color3.fromRGB(255, 255, 255), 0.18)
    local ResolvedText = Style.TextColor or Color3.fromRGB(255, 255, 255)

    Button.Base.BackgroundTransparency = 0
    Button.Base.BackgroundColor3 = BackgroundColor
    Button.Base.TextColor3 = ResolvedText
    Button.Base.Text = ""
    Button.Base.FontFace = Font.new("rbxasset://fonts/families/GothamSSm.json", Enum.FontWeight.Bold)
    Button.Base.TextSize = 13
    Button.Stroke.Color = ResolvedStroke
    Button.Stroke.Transparency = 0.05

    for _, child in ipairs(Button.Base:GetChildren()) do
        if child.Name == "KojoButtonPadding" or child.Name == "KojoButtonIcon" or child.Name == "KojoButtonGlow" or child.Name == "KojoButtonGradient" or child.Name == "KojoButtonShine" or child.Name == "KojoButtonLabel" then
            child:Destroy()
        end
    end

    local Label = Instance.new("TextLabel")
    Label.Name = "KojoButtonLabel"
    Label.BackgroundTransparency = 1
    Label.AnchorPoint = Vector2.new(0.5, 0.5)
    Label.Position = UDim2.fromScale(0.5, 0.5)
    Label.Size = UDim2.new(1, -12, 1, 0)
    Label.FontFace = Font.new("rbxasset://fonts/families/GothamSSm.json", Enum.FontWeight.Bold)
    Label.Text = Button.Text or ""
    Label.TextColor3 = ResolvedText
    Label.TextSize = 13
    Label.TextXAlignment = Enum.TextXAlignment.Center
    Label.TextYAlignment = Enum.TextYAlignment.Center
    Label.ZIndex = Button.Base.ZIndex + 1
    Label.Parent = Button.Base

    local Gradient = Instance.new("UIGradient")
    Gradient.Name = "KojoButtonGradient"
    Gradient.Color = Style.Gradient or ColorSequence.new({
        ColorSequenceKeypoint.new(0, BackgroundColor),
        ColorSequenceKeypoint.new(1, BackgroundColor:Lerp(Color3.fromRGB(255, 255, 255), 0.08)),
    })
    Gradient.Rotation = Style.Rotation or 0
    Gradient.Parent = Button.Base

    if Style.Icon then
        local ParsedIcon = Library:GetCustomIcon(Style.Icon)
        if ParsedIcon then
            local Glow = Instance.new("Frame")
            Glow.Name = "KojoButtonGlow"
            Glow.AnchorPoint = Vector2.new(0, 0.5)
            Glow.BackgroundColor3 = Style.IconGlowColor or ResolvedStroke
            Glow.BackgroundTransparency = 0.78
            Glow.BorderSizePixel = 0
            Glow.Position = UDim2.new(0, 10, 0.5, 0)
            Glow.Size = UDim2.fromOffset(11, 11)
            Glow.Parent = Button.Base
            Instance.new("UICorner", Glow).CornerRadius = UDim.new(1, 0)

            local Icon = Instance.new("ImageLabel")
            Icon.Name = "KojoButtonIcon"
            Icon.BackgroundTransparency = 1
            Icon.AnchorPoint = Vector2.new(0, 0.5)
            Icon.Position = UDim2.new(0, 10, 0.5, 0)
            Icon.Size = UDim2.fromOffset(11, 11)
            Icon.Image = ParsedIcon.Url
            Icon.ImageRectOffset = ParsedIcon.ImageRectOffset
            Icon.ImageRectSize = ParsedIcon.ImageRectSize
            Icon.ImageColor3 = Style.IconColor or Color3.fromRGB(255, 255, 255)
            Icon.ZIndex = Button.Base.ZIndex + 1
            Icon.Parent = Button.Base
        end
    end
end

local function applyCleanDashboardLabel(Label, weight, color)
    if not Label or not Label.TextLabel then
        return
    end

    local TextLabel = Label.TextLabel
    TextLabel.FontFace = Library:GetWeightedFont(weight or Enum.FontWeight.Medium)
    TextLabel.TextSize = 14
    TextLabel.TextColor3 = color or Color3.fromRGB(214, 219, 230)
    TextLabel.TextWrapped = false
    TextLabel.TextStrokeTransparency = 1
end

local function uiColor(name, fallback)
    local ok, value = pcall(function()
        return Library:GetUiColor(name)
    end)
    if ok and value ~= nil then
        return value
    end
    return fallback
end

local function createUi(className, properties)
    local object = Instance.new(className)
    for key, value in pairs(properties or {}) do
        object[key] = value
    end
    return object
end

local function addCorner(object, radius)
    local corner = Instance.new("UICorner")
    corner.CornerRadius = UDim.new(0, radius)
    corner.Parent = object
    return corner
end

local function addStroke(object, color, transparency, thickness)
    local stroke = Instance.new("UIStroke")
    stroke.Color = color
    stroke.Transparency = transparency or 0
    stroke.Thickness = thickness or 1
    stroke.Parent = object
    return stroke
end

local function clearChildren(parent, predicate)
    for _, child in ipairs(parent:GetChildren()) do
        if not predicate or predicate(child) then
            child:Destroy()
        end
    end
end

local function getKojoUserName()
    local social = getKojoSocial()
    if social and type(social.profile) == "table" then
        local displayName = tostring(social.profile.display_name or "")
        if displayName ~= "" then
            return displayName
        end
    end

    local profileName = tostring(getKojoValue("KOJO_ProfileName", ""))
    if profileName ~= "" then
        return profileName
    end

    return tostring(getKojoValue("KOJO_UserName", LocalPlayer and (LocalPlayer.DisplayName or LocalPlayer.Name) or "Unknown"))
end

local function getKojoDiscordTag()
    local social = getKojoSocial()
    if social and type(social.profile) == "table" then
        local discordName = tostring(social.profile.discord_username or "")
        if discordName ~= "" then
            return discordName
        end
    end

    return tostring(getKojoValue("KOJO_DiscordTag", "Not linked"))
end

local function normalizeImageAsset(value)
    if typeof(value) ~= "string" then
        return ""
    end

    value = value:match("^%s*(.-)%s*$")
    if value == "" then
        return ""
    end

    local createStoreId = value:match("/asset/(%d+)")
    if createStoreId then
        return "rbxassetid://" .. createStoreId
    end

    local webAssetId = value:match("[?&]id=(%d+)")
    if webAssetId then
        return "rbxassetid://" .. webAssetId
    end

    local rawAssetId = value:match("^rbxassetid://(%d+)$")
    if rawAssetId then
        return "rbxassetid://" .. rawAssetId
    end

    if value:match("^%d+$") then
        return "rbxassetid://" .. value
    end

    return value
end

local function getKojoFooterAvatar()
    local social = getKojoSocial()
    if social and type(social.profile) == "table" then
        local profileAvatar = normalizeImageAsset(tostring(social.profile.script_avatar_url or social.profile.avatar_url or ""))
        if profileAvatar ~= "" then
            return profileAvatar
        end
    end

    local runtimeAvatar = normalizeImageAsset(tostring(getKojoValue("KOJO_ProfileAvatar", "")))
    if runtimeAvatar ~= "" then
        return runtimeAvatar
    end

    local explicitAvatar = normalizeImageAsset(tostring(getKojoValue("KOJO_AvatarImage", "")))
    if explicitAvatar ~= "" then
        return explicitAvatar
    end

    if not LocalPlayer then
        return ""
    end

    local success, content = pcall(function()
        local image, _ = Players:GetUserThumbnailAsync(
            LocalPlayer.UserId,
            Enum.ThumbnailType.HeadShot,
            Enum.ThumbnailSize.Size60x60
        )
        return image
    end)

    if success and type(content) == "string" then
        return content
    end

    return ""
end

local function getCurrentProfileDisplayName(profile)
    local optionValue = Options.ProfileDisplayName and tostring(Options.ProfileDisplayName.Value or "") or ""
    optionValue = optionValue:match("^%s*(.-)%s*$")
    if optionValue ~= "" then
        return optionValue
    end

    if profile and type(profile) == "table" then
        local displayName = tostring(profile.display_name or ""):match("^%s*(.-)%s*$")
        if displayName ~= "" then
            return displayName
        end
    end

    return getKojoUserName()
end

local function getCurrentProfileAvatar(profile)
    local optionValue = Options.ProfileScriptAvatar and normalizeImageAsset(tostring(Options.ProfileScriptAvatar.Value or "")) or ""
    if optionValue ~= "" then
        return optionValue
    end

    if profile and type(profile) == "table" then
        local avatarValue = normalizeImageAsset(tostring(profile.script_avatar_url or profile.avatar_url or ""))
        if avatarValue ~= "" then
            return avatarValue
        end
    end

    return getKojoFooterAvatar()
end

local function getRemainingSeconds()
    local secondsLeft = tonumber(getKojoValue("KOJO_SecondsLeft", nil))
    if secondsLeft then
        return math.max(0, math.floor(secondsLeft))
    end

    local expireAt = tonumber(getKojoValue("KOJO_ExpireAt", nil))
    if expireAt then
        return math.max(0, math.floor(expireAt - os.time()))
    end

    return nil
end

local ApplyingRemoteProfile = false
local HomeUserLabel
local HomeDiscordLabel
local HomeTierLabel
local HomeLicenseLabel
local HomeExpiresAtLabel
local HomeCountdownLabel
local HomeExecutionsLabel
local ProfileStatusLabel
local SafeModeStatusLabel
local LicenseTierLabel
local LicenseKeyLabel
local LicenseExpiryAtLabel
local LicenseCountdownLabel
local LicenseExecutionsLabel
local NametagBackgroundPresets
local registerNametagBackgroundPreset
local GameDisplayName

local function setLabelText(label, value)
    if label and label.SetText then
        label:SetText(value)
    end
end

local function updateFooterIdentity(profile)
    local profileName = getCurrentProfileDisplayName(profile)
    local profileAvatar = getCurrentProfileAvatar(profile)

    Window:SetFooter(profileName)
    if Window.SetFooterAvatar then
        Window:SetFooterAvatar(profileAvatar)
    end
end

local HeadNametagGui
local HeadNametagController
local HeadNametagSignature

local function getHeadNametagAdornee()
    local character = LocalPlayer and LocalPlayer.Character
    if not character then
        return nil
    end

    return character:FindFirstChild("Head") or character:FindFirstChild("HumanoidRootPart")
end

local function destroyHeadNametag()
    if HeadNametagController then
        HeadNametagController:Destroy()
        HeadNametagController = nil
    end
    if HeadNametagGui then
        HeadNametagGui:Destroy()
        HeadNametagGui = nil
    end
    HeadNametagSignature = nil
end

local function ensureHeadNametag()
    local adornee = getHeadNametagAdornee()
    if not adornee then
        destroyHeadNametag()
        return nil
    end

    if HeadNametagController and HeadNametagGui and HeadNametagGui.Parent then
        HeadNametagController:SetAdornee(adornee)
        return HeadNametagGui
    end

    destroyHeadNametag()

    HeadNametagController = Library:CreateAdvancedNametag({
        Name = "KojoHeadNametag",
        Parent = LocalPlayer and LocalPlayer:FindFirstChildOfClass("PlayerGui"),
        Adornee = adornee,
        Size = UDim2.fromOffset(244, 56),
        StudsOffset = Vector3.new(0, 2.95, 0),
        AlwaysOnTop = true,
        MaxDistance = 95,
        DynamicScale = true,
        MinScale = 0.62,
        MaxScale = 0.76,
        ReferenceDistance = 52,
        Title = getKojoUserName(),
        Subtitle = tostring(getKojoValue("KOJO_UserTier", "Freemium")),
        BrandText = "KOJO",
        Avatar = getKojoFooterAvatar(),
        BackgroundImage = "",
        BackgroundTransparency = 0.16,
    })

    HeadNametagGui = HeadNametagController.Gui
    return HeadNametagGui
end

local function updateHeadNametag(profile)
    local isVisible = true
    if Toggles.ShowHeadNametag then
        isVisible = Toggles.ShowHeadNametag.Value == true
    end

    if not isVisible then
        destroyHeadNametag()
        return
    end

    local gui = ensureHeadNametag()
    if not gui then
        return
    end

    if not HeadNametagController then
        return
    end

    local backgroundImage = ""
    local avatarImage = getCurrentProfileAvatar(profile)
    local titleText = getCurrentProfileDisplayName(profile)
    local tierText = tostring(getKojoValue("KOJO_UserTier", "Freemium"))

    if Options.NametagBackground and NametagBackgroundPresets[Options.NametagBackground.Value] then
        backgroundImage = NametagBackgroundPresets[Options.NametagBackground.Value]
    end

    local transparencyValue = Options.NametagTransparency and (Options.NametagTransparency.Value / 100) or 0.1
    local signature = table.concat({
        tostring(titleText),
        tostring(avatarImage),
        tostring(backgroundImage),
        tostring(transparencyValue),
        tierText,
    }, "|")

    if HeadNametagController and HeadNametagSignature ~= signature then
        destroyHeadNametag()
        gui = ensureHeadNametag()
        if not gui or not HeadNametagController then
            return
        end
    end

    HeadNametagController:SetAdornee(getHeadNametagAdornee())
    HeadNametagController:SetAvatar(avatarImage)
    HeadNametagController:SetTitle(titleText)
    HeadNametagController:SetSubtitle(tierText)
    HeadNametagController:SetBrandText("KOJO")
    HeadNametagController:SetBackgroundImage(backgroundImage)
    HeadNametagController:SetBackgroundTransparency(transparencyValue)
    HeadNametagSignature = signature
end

local function applySocialProfile(profile, opts)
    opts = opts or {}
    profile = type(profile) == "table" and profile or {}
    local social = getKojoSocial()
    if social and type(social) == "table" then
        social.profile = {}
        for key, value in pairs(profile) do
            social.profile[key] = value
        end
    end

    local displayName = getCurrentProfileDisplayName(profile)
    local discordName = tostring(profile.discord_username or getKojoDiscordTag())
    local visible = profile.visible
    if visible == nil then
        visible = getKojoValue("KOJO_ProfileVisible", true) ~= false
    end

    updateFooterIdentity(profile)
    setLabelText(HomeUserLabel, ("User: %s"):format(displayName))
    setLabelText(HomeDiscordLabel, ("Discord: %s"):format(discordName))
    setLabelText(HomeTierLabel, ("Tier: %s"):format(tostring(getKojoValue("KOJO_UserTier", "Freemium"))))
    setLabelText(HomeLicenseLabel, ("License Key: %s"):format(tostring(getKojoValue("KOJO_LicenseKey", "Unavailable"))))
    setLabelText(HomeExecutionsLabel, ("Executions: %s"):format(tostring(getKojoValue("KOJO_ExecutionCount", 1))))

    if ProfileStatusLabel then
        local status = profile.profile_id and ("Connected: " .. tostring(profile.profile_id)) or "Connected"
        if not getKojoSocial() then
            status = "Local only"
        end
        ProfileStatusLabel:SetText(status)
    end

    ApplyingRemoteProfile = true
    pcall(function()
        if Options.ProfileDisplayName then
            Options.ProfileDisplayName:SetValue(displayName)
        end
        if Options.ProfileScriptAvatar then
            Options.ProfileScriptAvatar:SetValue(normalizeImageAsset(tostring(profile.script_avatar_url or profile.avatar_url or "")))
        end
        if Toggles.ProfileVisible then
            Toggles.ProfileVisible:SetValue(visible == true)
        end

        local nametagAsset = tostring(profile.nametag_asset or "")
        if Options.NametagAsset then
            Options.NametagAsset:SetValue(nametagAsset)
        end
        if nametagAsset ~= "" then
            local presetName = registerNametagBackgroundPreset(nametagAsset)
            if Options.NametagBackground then
                Options.NametagBackground:SetValue(presetName)
            end
        elseif Options.NametagBackground and type(profile.nametag_background) == "string" and profile.nametag_background ~= "" then
            Options.NametagBackground:SetValue(profile.nametag_background)
        end
        if Options.NametagTransparency and profile.nametag_transparency ~= nil then
            Options.NametagTransparency:SetValue(tonumber(profile.nametag_transparency) or 0)
        end
    end)
    ApplyingRemoteProfile = false
    updateHeadNametag(profile)

    if opts.notify then
        notify("Kojo", opts.notify)
    end
end

local function refreshSocialProfile(silent)
    local social = getKojoSocial()
    if not social or type(social.refreshProfile) ~= "function" then
        if not silent then
            notify("Kojo", "Social bridge is unavailable in this session")
        end
        return nil, "missing_social_bridge"
    end

    local profile, err = social.refreshProfile()
    if profile then
        applySocialProfile(profile, {
            notify = silent and nil or "Profile refreshed",
        })
        return profile
    end

    if not silent then
        notify("Kojo", err or "Profile refresh failed")
    end
    return nil, err
end

local function pushSocialProfile(changes, successMessage)
    local social = getKojoSocial()
    if not social or type(social.updateProfile) ~= "function" then
        local localProfile = {
            profile_id = tostring(getKojoValue("KOJO_ProfileId", "")),
            discord_id = "",
            discord_username = getKojoDiscordTag(),
            display_name = getKojoUserName(),
            avatar_url = "",
            script_avatar_url = tostring(getKojoValue("KOJO_ProfileAvatar", "")),
            nametag_background = Options.NametagBackground and Options.NametagBackground.Value or "None",
            nametag_asset = Options.NametagAsset and Options.NametagAsset.Value or "",
            nametag_transparency = Options.NametagTransparency and Options.NametagTransparency.Value or 0,
            visible = getKojoValue("KOJO_ProfileVisible", true) ~= false,
            preferences = {},
        }
        for key, value in pairs(changes or {}) do
            localProfile[key] = value
        end

        if localProfile.display_name then
            setKojoEnvValue("KOJO_ProfileName", localProfile.display_name)
        end
        if localProfile.script_avatar_url or localProfile.avatar_url then
            setKojoEnvValue("KOJO_ProfileAvatar", localProfile.script_avatar_url ~= "" and localProfile.script_avatar_url or localProfile.avatar_url)
        end
        if localProfile.visible ~= nil then
            setKojoEnvValue("KOJO_ProfileVisible", localProfile.visible == true)
        end

        applySocialProfile(localProfile, {
            notify = successMessage or "Applied locally",
        })
        return localProfile, "local_only"
    end

    local profile, err = social.updateProfile(changes)
    if profile then
        if profile.display_name then
            setKojoEnvValue("KOJO_ProfileName", profile.display_name)
        end
        if profile.script_avatar_url or profile.avatar_url then
            setKojoEnvValue("KOJO_ProfileAvatar", tostring(profile.script_avatar_url or profile.avatar_url or ""))
        end
        setKojoEnvValue("KOJO_ProfileVisible", profile.visible ~= false)
        applySocialProfile(profile, {
            notify = successMessage,
        })
        return profile
    end

    notify("Kojo", err or "Profile update failed")
    return nil, err
end

local function formatRemainingTime(secondsLeft)
    if secondsLeft == nil then
        return "Lifetime"
    end

    if secondsLeft <= 0 then
        return "Expired"
    end

    local days = math.floor(secondsLeft / 86400)
    local hours = math.floor((secondsLeft % 86400) / 3600)
    local minutes = math.floor((secondsLeft % 3600) / 60)
    local seconds = secondsLeft % 60

    if days > 0 then
        return string.format("%dd %02dh %02dm", days, hours, minutes)
    elseif hours > 0 then
        return string.format("%02dh %02dm %02ds", hours, minutes, seconds)
    elseif minutes > 0 then
        return string.format("%02dm %02ds", minutes, seconds)
    end

    return string.format("%02ds", seconds)
end

local function formatExpiryAbsolute()
    local expireAt = tonumber(getKojoValue("KOJO_ExpireAt", nil))
    if not expireAt then
        return "Lifetime"
    end

    local success, formatted = pcall(function()
        local dt = DateTime.fromUnixTimestamp(expireAt):ToLocalTime()
        return string.format("%04d-%02d-%02d %02d:%02d", dt.Year, dt.Month, dt.Day, dt.Hour, dt.Minute)
    end)
    if success and type(formatted) == "string" then
        return formatted
    end

    return tostring(expireAt)
end

local function refreshLicenseLabels()
    local discordTag = getKojoDiscordTag()
    local userName = getKojoUserName()
    local fullLicenseKey = tostring(getKojoValue("KOJO_LicenseKey", "Unavailable"))

    setLabelText(HomeUserLabel, ("User: %s"):format(userName))
    setLabelText(HomeDiscordLabel, ("Discord: %s"):format(discordTag))
    setLabelText(HomeTierLabel, ("Tier: %s"):format(tostring(getKojoValue("KOJO_UserTier", "Freemium"))))
    setLabelText(HomeLicenseLabel, ("License Key: %s"):format(fullLicenseKey))
    setLabelText(HomeExpiresAtLabel, ("Expires At: %s"):format(formatExpiryAbsolute()))
    setLabelText(HomeCountdownLabel, ("Countdown: %s"):format(formatRemainingTime(getRemainingSeconds())))
    setLabelText(HomeExecutionsLabel, ("Executions: %s"):format(tostring(getKojoValue("KOJO_ExecutionCount", 1))))
    if Options.HomeGameName and Options.HomeGameName.SetText then
        Options.HomeGameName:SetText(("Game: %s"):format(GameDisplayName))
    end

    setLabelText(LicenseTierLabel, ("Tier: %s"):format(tostring(getKojoValue("KOJO_UserTier", "Freemium"))))
    setLabelText(LicenseKeyLabel, ("License Key: %s"):format(maskKey(getKojoValue("KOJO_LicenseKey", "Unavailable"))))
    setLabelText(LicenseExpiryAtLabel, ("Expires At: %s"):format(formatExpiryAbsolute()))
    setLabelText(LicenseCountdownLabel, ("Countdown: %s"):format(formatRemainingTime(getRemainingSeconds())))
    setLabelText(LicenseExecutionsLabel, ("Executions: %s"):format(tostring(getKojoValue("KOJO_ExecutionCount", 1))))
end

local SafeModeEnabled = getKojoValue("KOJO_SafeMode", true) ~= false

local function refreshSafeModeLabel()
    if SafeModeStatusLabel and SafeModeStatusLabel.SetText then
        if SafeModeEnabled then
            SafeModeStatusLabel:SetText("Safe Mode is on: head nametag stays off and preview interaction is restricted.")
        else
            SafeModeStatusLabel:SetText("Safe Mode is off: advanced in-world UI and interactive preview are allowed.")
        end
    end
end

local function applySafeModeState(enabled, opts)
    opts = opts or {}
    SafeModeEnabled = enabled == true
    setKojoEnvValue("KOJO_SafeMode", SafeModeEnabled)

    local viewport = Options.HomeAvatarViewport
    if viewport and viewport.SetInteractive then
        viewport:SetInteractive(not SafeModeEnabled)
    end
    if viewport and viewport.SetAutoRotate then
        viewport:SetAutoRotate(true)
    end

    if SafeModeEnabled and Toggles.ShowHeadNametag and Toggles.ShowHeadNametag.Value and opts.force ~= false then
        Toggles.ShowHeadNametag:SetValue(false)
    else
        updateHeadNametag(getKojoSocial() and getKojoSocial().profile or nil)
    end

    refreshSafeModeLabel()
end

GameDisplayName = tostring(getKojoValue("KOJO_PlaceName", game.PlaceId))
task.spawn(function()
    local success, info = pcall(function()
        return MarketplaceService:GetProductInfo(game.PlaceId)
    end)

    if success and type(info) == "table" and type(info.Name) == "string" and info.Name ~= "" then
        GameDisplayName = info.Name
        if Options.HomeGameName and Options.HomeGameName.SetText then
            Options.HomeGameName:SetText(("Game: %s"):format(GameDisplayName))
        end
    end
end)

NametagBackgroundPresets = {
    None = "",
    ["Glass Sky"] = assetPath("backdrops/sky.png"),
    ["Mint Bloom"] = assetPath("backdrops/mint_garden.png"),
    ["Aurora Wash"] = assetPath("backdrops/aurora.png"),
    ["Soft Petals"] = assetPath("backdrops/petals.png"),
    ["Night City"] = assetPath("backdrops/night_city.png"),
    ["Dawn Glow"] = assetPath("backdrops/dawn_glow.png"),
}

local function getNametagBackgroundPresetNames()
    local names = { "None" }
    for name in pairs(NametagBackgroundPresets) do
        if name ~= "None" then
            table.insert(names, name)
        end
    end
    table.sort(names, function(a, b)
        if a == "None" then
            return true
        elseif b == "None" then
            return false
        end

        return a < b
    end)
    return names
end

function registerNametagBackgroundPreset(asset)
    asset = normalizeBackgroundAsset(asset)
    if asset == "" then
        return "None"
    end

    for existingName, existingAsset in pairs(NametagBackgroundPresets) do
        if existingAsset == asset then
            return existingName
        end
    end

    local assetId = asset:match("(%d+)")
    local baseName = assetId and ("Nametag " .. assetId) or "Custom Nametag"
    local candidate = baseName
    local counter = 2

    while NametagBackgroundPresets[candidate] ~= nil do
        candidate = string.format("%s %d", baseName, counter)
        counter += 1
    end

    NametagBackgroundPresets[candidate] = asset
    if Options.NametagBackground then
        Options.NametagBackground:SetValues(getNametagBackgroundPresetNames())
    end

    return candidate
end

local function applyNametagBackground(name)
    local preset = NametagBackgroundPresets[name]
    if preset == nil or not Window.SetFooterBackgroundImage then
        return
    end

    if preset == "" then
        Window:SetFooterBackgroundImage("")
        updateHeadNametag(getKojoSocial() and getKojoSocial().profile or nil)
        return
    end

    Window:SetFooterBackgroundImage(preset)
    updateHeadNametag(getKojoSocial() and getKojoSocial().profile or nil)
    local workspaceShell = rawget(KojoEnv, "__KOJO_WORKSPACE_SHELL")
    if workspaceShell and workspaceShell.RefreshHeaderTag then
        workspaceShell:RefreshHeaderTag()
    end
end

local AvatarBackdropPresets = {
    ["Hide Backdrop"] = {
        Color = Color3.fromRGB(0, 0, 0),
        Transparency = 1,
        Image = "",
        ImageColor = Color3.new(1, 1, 1),
        ImageTransparency = 1,
    },
    ["Studio Slate"] = {
        Color = Color3.fromRGB(18, 20, 28),
        Transparency = 0,
        Image = assetPath("backdrops/studio_slate.png"),
        ImageColor = Color3.new(1, 1, 1),
        ImageTransparency = 0.08,
    },
    ["Galaxy"] = {
        Color = Color3.fromRGB(68, 54, 130),
        Transparency = 0,
        Image = assetPath("backdrops/galaxy.png"),
        ImageColor = Color3.new(1, 1, 1),
        ImageTransparency = 0.02,
    },
    ["Nebula"] = {
        Color = Color3.fromRGB(108, 52, 86),
        Transparency = 0,
        Image = assetPath("backdrops/nebula.png"),
        ImageColor = Color3.new(1, 1, 1),
        ImageTransparency = 0.04,
    },
    ["Sky"] = {
        Color = Color3.fromRGB(89, 148, 230),
        Transparency = 0,
        Image = assetPath("backdrops/sky.png"),
        ImageColor = Color3.new(1, 1, 1),
        ImageTransparency = 0,
    },
    ["Rain"] = {
        Color = Color3.fromRGB(72, 88, 120),
        Transparency = 0,
        Image = assetPath("backdrops/rain.png"),
        ImageColor = Color3.new(1, 1, 1),
        ImageTransparency = 0.03,
    },
    ["Carbon"] = {
        Color = Color3.fromRGB(14, 15, 19),
        Transparency = 0,
        Image = assetPath("backdrops/studio_slate.png"),
        ImageColor = Color3.fromRGB(104, 108, 120),
        ImageTransparency = 0.4,
    },
    ["Aurora"] = {
        Color = Color3.fromRGB(42, 96, 102),
        Transparency = 0,
        Image = assetPath("backdrops/aurora.png"),
        ImageColor = Color3.new(1, 1, 1),
        ImageTransparency = 0.03,
    },
    ["Dawn Glow"] = {
        Color = Color3.fromRGB(255, 196, 183),
        Transparency = 0,
        Image = assetPath("backdrops/dawn_glow.png"),
        ImageColor = Color3.new(1, 1, 1),
        ImageTransparency = 0,
    },
    ["Mint Garden"] = {
        Color = Color3.fromRGB(193, 239, 218),
        Transparency = 0,
        Image = assetPath("backdrops/mint_garden.png"),
        ImageColor = Color3.new(1, 1, 1),
        ImageTransparency = 0.02,
    },
    ["Blueprint"] = {
        Color = Color3.fromRGB(130, 184, 240),
        Transparency = 0,
        Image = assetPath("backdrops/blueprint.png"),
        ImageColor = Color3.new(1, 1, 1),
        ImageTransparency = 0.02,
    },
    ["Night City"] = {
        Color = Color3.fromRGB(58, 56, 110),
        Transparency = 0,
        Image = assetPath("backdrops/night_city.png"),
        ImageColor = Color3.new(1, 1, 1),
        ImageTransparency = 0.04,
    },
    ["Petals"] = {
        Color = Color3.fromRGB(247, 201, 222),
        Transparency = 0,
        Image = assetPath("backdrops/petals.png"),
        ImageColor = Color3.new(1, 1, 1),
        ImageTransparency = 0.03,
    },
    ["Sunset"] = {
        Color = Color3.fromRGB(120, 76, 104),
        Transparency = 0,
        Image = assetPath("backdrops/sunset.png"),
        ImageColor = Color3.new(1, 1, 1),
        ImageTransparency = 0.02,
    },
    ["Starlight"] = {
        Color = Color3.fromRGB(18, 26, 52),
        Transparency = 0,
        Image = assetPath("backdrops/starlight.png"),
        ImageColor = Color3.new(1, 1, 1),
        ImageTransparency = 0.03,
    },
    ["Sakura"] = {
        Color = Color3.fromRGB(156, 110, 144),
        Transparency = 0,
        Image = assetPath("backdrops/sakura.png"),
        ImageColor = Color3.new(1, 1, 1),
        ImageTransparency = 0.05,
    },
}

local BuiltInAvatarBackdropNames = {}
for presetName in pairs(AvatarBackdropPresets) do
    BuiltInAvatarBackdropNames[presetName] = true
end

local function getAvatarBackdropPresetNames()
    local names = {}
    for name in pairs(AvatarBackdropPresets) do
        table.insert(names, name)
    end
    table.sort(names)
    return names
end

local function registerAvatarBackdropPreset(asset)
    asset = normalizeBackgroundAsset(asset)
    if asset == "" then
        return nil
    end

    for existingName, preset in pairs(AvatarBackdropPresets) do
        if type(preset) == "table" and preset.Image == resolveBackgroundDisplayAsset(asset) then
            return existingName
        end
    end

    local assetId = asset:match("(%d+)")
    local baseName = assetId and ("Backdrop " .. assetId) or "Custom Backdrop"
    local candidate = baseName
    local counter = 2

    while AvatarBackdropPresets[candidate] ~= nil do
        candidate = string.format("%s %d", baseName, counter)
        counter += 1
    end

    AvatarBackdropPresets[candidate] = {
        Color = Color3.fromRGB(28, 31, 40),
        Transparency = 0,
        Image = resolveBackgroundDisplayAsset(asset),
        ImageColor = Color3.new(1, 1, 1),
        ImageTransparency = 0,
    }

    if Options.HomeAvatarBackdrop then
        Options.HomeAvatarBackdrop:SetValues(getAvatarBackdropPresetNames())
    end

    return candidate
end

local function renameAvatarBackdropPreset(currentName, newName)
    currentName = tostring(currentName or "")
    newName = tostring(newName or ""):match("^%s*(.-)%s*$")

    if currentName == "" or newName == "" then
        return nil
    end

    if BuiltInAvatarBackdropNames[currentName] then
        notify("Kojo", "Built-in backdrops cannot be renamed")
        return nil
    end

    if AvatarBackdropPresets[currentName] == nil then
        return nil
    end

    if AvatarBackdropPresets[newName] ~= nil and newName ~= currentName then
        notify("Kojo", "Backdrop name already exists")
        return nil
    end

    if newName == currentName then
        return currentName
    end

    AvatarBackdropPresets[newName] = AvatarBackdropPresets[currentName]
    AvatarBackdropPresets[currentName] = nil

    if Options.HomeAvatarBackdrop then
        Options.HomeAvatarBackdrop:SetValues(getAvatarBackdropPresetNames())
        Options.HomeAvatarBackdrop:SetValue(newName)
    end

    return newName
end

local function applyAvatarBackdrop(name)
    local Viewport = Options.HomeAvatarViewport
    local Preset = AvatarBackdropPresets[name]
    if not Viewport or not Preset then
        return
    end

    Viewport:SetBackgroundColor(Preset.Color)
    Viewport:SetBackgroundTransparency(Preset.Transparency or 0)
    Viewport:SetBackgroundImage(Preset.Image or "")
    if Viewport.SetBackgroundImageColor then
        Viewport:SetBackgroundImageColor(Preset.ImageColor or Color3.new(1, 1, 1))
    end
    local imageTransparency = Preset.Image and (Preset.ImageTransparency or 0.16) or 1
    if Options.AvatarBackdropFade and typeof(Options.AvatarBackdropFade.Value) == "number" then
        imageTransparency = math.clamp(Options.AvatarBackdropFade.Value / 100, 0, 1)
    end
    Viewport:SetBackgroundImageTransparency(imageTransparency)
    if Viewport.SetBackgroundGradient then
        Viewport:SetBackgroundGradient(Preset.Gradient or false, Preset.Rotation or 0)
    end
end

local function refreshHomeAvatar()
    local Viewport = Options.HomeAvatarViewport
    if not Viewport then
        return
    end

    Viewport:SetObject(createAvatarPreviewModel(), false)
    Viewport:Focus()
    if Viewport.SetAutoRotate then
        Viewport:SetAutoRotate(true)
    end
end

-- Home
local HomeAccount = Tabs.Home:AddLeftGroupbox("Dashboard")
local HomeTier = tostring(getKojoValue("KOJO_UserTier", "Freemium"))
HomeUserLabel = HomeAccount:AddLabel({
    Text = ("User: %s"):format(getKojoUserName()),
})
HomeDiscordLabel = HomeAccount:AddLabel({
    Text = ("Discord: %s"):format(getKojoDiscordTag()),
})
HomeTierLabel = HomeAccount:AddLabel({
    Text = ("Tier: %s"):format(HomeTier),
})
HomeLicenseLabel = HomeAccount:AddLabel({
    Text = ("License Key: %s"):format(tostring(getKojoValue("KOJO_LicenseKey", "Unavailable"))),
    DoesWrap = true,
})
local ExpiryLabel = HomeAccount:AddLabel({
    Text = ("Expires In: %s"):format(formatRemainingTime(getRemainingSeconds())),
})
HomeExpiresAtLabel = HomeAccount:AddLabel({
    Text = ("Expires At: %s"):format(formatExpiryAbsolute()),
})
HomeCountdownLabel = HomeAccount:AddLabel({
    Text = ("Countdown: %s"):format(formatRemainingTime(getRemainingSeconds())),
})
HomeExecutionsLabel = HomeAccount:AddLabel({
    Text = ("Executions: %s"):format(tostring(getKojoValue("KOJO_ExecutionCount", 1))),
})
local HomeGameLabel = HomeAccount:AddLabel("HomeGameName", {
    Text = ("Game: %s"):format(GameDisplayName),
})

applyCleanDashboardLabel(HomeUserLabel, Enum.FontWeight.SemiBold, Color3.fromRGB(232, 236, 244))
applyCleanDashboardLabel(HomeDiscordLabel)
applyCleanDashboardLabel(HomeTierLabel)
applyCleanDashboardLabel(HomeLicenseLabel)
applyCleanDashboardLabel(ExpiryLabel)
applyCleanDashboardLabel(HomeExpiresAtLabel)
applyCleanDashboardLabel(HomeCountdownLabel, Enum.FontWeight.SemiBold, Color3.fromRGB(208, 236, 220))
applyCleanDashboardLabel(HomeExecutionsLabel)
applyCleanDashboardLabel(HomeGameLabel)

LicenseTierLabel = HomeTierLabel
LicenseKeyLabel = HomeLicenseLabel
LicenseExpiryAtLabel = HomeExpiresAtLabel
LicenseCountdownLabel = HomeCountdownLabel
LicenseExecutionsLabel = HomeExecutionsLabel

task.spawn(function()
    while true do
        task.wait(1)
        if ExpiryLabel and ExpiryLabel.SetText then
            ExpiryLabel:SetText(("Expires In: %s"):format(formatRemainingTime(getRemainingSeconds())))
        end
        refreshLicenseLabels()
    end
end)

local HomeLinks = Tabs.Home:AddLeftGroupbox("Access")
local DiscordButton = HomeLinks:AddButton("Discord", function()
    copyText("Discord link", "https://discord.gg/5VrGVd7YTc")
end)
local WebsiteButton = DiscordButton:AddButton("Buy Key", function()
    copyText("Website link", "https://kojohub.pro")
end)
styleDashboardButton(DiscordButton, {
    BackgroundColor = Color3.fromRGB(92, 110, 255),
    StrokeColor = Color3.fromRGB(176, 188, 255),
    TextColor = Color3.fromRGB(248, 250, 255),
    Icon = "kojo-discord",
    IconGlowColor = Color3.fromRGB(194, 208, 255),
    Gradient = ColorSequence.new({
        ColorSequenceKeypoint.new(0, Color3.fromRGB(86, 104, 246)),
        ColorSequenceKeypoint.new(0.5, Color3.fromRGB(121, 138, 255)),
        ColorSequenceKeypoint.new(1, Color3.fromRGB(78, 92, 228)),
    }),
})
styleDashboardButton(WebsiteButton, {
    BackgroundColor = Color3.fromRGB(40, 76, 68),
    StrokeColor = Color3.fromRGB(150, 238, 194),
    TextColor = Color3.fromRGB(242, 255, 247),
    Icon = "kojo-buy-key",
    IconGlowColor = Color3.fromRGB(180, 255, 210),
    Gradient = ColorSequence.new({
        ColorSequenceKeypoint.new(0, Color3.fromRGB(34, 69, 62)),
        ColorSequenceKeypoint.new(0.5, Color3.fromRGB(58, 104, 92)),
        ColorSequenceKeypoint.new(1, Color3.fromRGB(28, 58, 52)),
    }),
})

local CopyLicenseButton = HomeLinks:AddButton("Copy License", function()
    copyText("License key", tostring(getKojoValue("KOJO_LicenseKey", "Unavailable")))
end)
local CopyGameButton = CopyLicenseButton:AddButton("Copy Game ID", function()
    copyText("Game id", tostring(game.PlaceId))
end)
styleDashboardButton(CopyLicenseButton, {
    BackgroundColor = Color3.fromRGB(24, 27, 34),
    StrokeColor = Color3.fromRGB(78, 88, 116),
    TextColor = Color3.fromRGB(222, 227, 236),
    Icon = "kojo-copy",
    IconGlowColor = Color3.fromRGB(112, 124, 168),
})
styleDashboardButton(CopyGameButton, {
    BackgroundColor = Color3.fromRGB(24, 27, 34),
    StrokeColor = Color3.fromRGB(78, 88, 116),
    TextColor = Color3.fromRGB(222, 227, 236),
    Icon = "kojo-game",
    IconGlowColor = Color3.fromRGB(112, 124, 168),
})

local HomeAvatar = Tabs.Home:AddRightGroupbox("Preview")
HomeAvatar:AddViewport("HomeAvatarViewport", {
    Object = createAvatarPreviewModel(),
    Clone = false,
    Height = 422,
    Interactive = true,
    AutoFocus = true,
    AutoRotate = true,
    RotateSpeed = 8,
    FocusYOffset = 0.02,
    CameraDistanceMultiplier = 1.2,
    BackgroundColor = AvatarBackdropPresets["Studio Slate"].Color,
    BackgroundTransparency = 0,
    BackgroundGradient = AvatarBackdropPresets["Studio Slate"].Gradient or false,
    BackgroundGradientRotation = AvatarBackdropPresets["Studio Slate"].Rotation or 0,
})
local AvatarTools = HomeAvatar:AddButton("Refocus", function()
    if Options.HomeAvatarViewport then
        Options.HomeAvatarViewport:Focus()
    end
end)
AvatarTools:AddButton("Refresh Avatar", function()
    refreshHomeAvatar()
end)

if LocalPlayer then
    LocalPlayer.CharacterAdded:Connect(function()
        task.delay(1, function()
            refreshHomeAvatar()
            updateHeadNametag(getKojoSocial() and getKojoSocial().profile or nil)
        end)
    end)
end

-- Combat
local CombatAimbot = Tabs.Combat:AddLeftGroupbox("Aimbot")
local AimbotEnabled = CombatAimbot:AddToggle("AimbotEnabled", {
    Text = "Enabled",
    Default = false,
})
CombatAimbot:AddToggle("AimbotShowFov", {
    Text = "Show FOV Circle",
    Default = false,
})
CombatAimbot:AddToggle("AimbotPrediction", {
    Text = "Prediction",
    Default = false,
})
CombatAimbot:AddSlider("AimbotFov", {
    Text = "FOV Radius",
    Default = 120,
    Min = 10,
    Max = 500,
    Rounding = 0,
})
CombatAimbot:AddDropdown("AimbotTarget", {
    Text = "Target Part",
    Values = { "Head", "Torso", "LeftArm", "RightArm", "Closest" },
    Default = "Head",
    Compact = true,
    ControlWidth = 104,
})
CombatAimbot:AddLabel("Keybind"):AddKeyPicker("AimbotKeybind", {
    Default = "E",
    SyncToggleState = AimbotEnabled,
    Mode = "Hold",
    Text = "Aimbot",
    NoUI = false,
})

local CombatTrigger = Tabs.Combat:AddRightGroupbox("Triggerbot")
local TriggerEnabled = CombatTrigger:AddToggle("TriggerEnabled", {
    Text = "Enabled",
    Default = false,
})
CombatTrigger:AddSlider("TriggerDelay", {
    Text = "Delay (ms)",
    Default = 50,
    Min = 0,
    Max = 500,
    Rounding = 0,
    Suffix = "ms",
})
CombatTrigger:AddToggle("TriggerIgnoreFriendly", {
    Text = "Ignore Friendly",
    Default = true,
})
CombatTrigger:AddLabel("Keybind"):AddKeyPicker("TriggerKeybind", {
    Default = "Q",
    SyncToggleState = TriggerEnabled,
    Mode = "Hold",
    Text = "Triggerbot",
    NoUI = false,
})
CombatTrigger:AddDropdown("TriggerMode", {
    Text = "Mode",
    Values = { "Toggle", "Hold", "Always" },
    Default = "Hold",
    Compact = true,
    ControlWidth = 96,
    Callback = function(value)
        if Options.TriggerKeybind and Options.TriggerKeybind.SetMode then
            Options.TriggerKeybind:SetMode(value)
        end
    end,
})

-- Visuals
local VisualsEsp = Tabs.Visuals:AddLeftGroupbox("ESP")
VisualsEsp:AddToggle("EspEnabled", {
    Text = "Enabled",
    Default = false,
}):AddColorPicker("EspAccent", {
    Default = Color3.fromRGB(233, 194, 215),
    Title = "ESP Accent",
})
VisualsEsp:AddToggle("EspNames", {
    Text = "Show Names",
    Default = true,
})
VisualsEsp:AddToggle("EspHealth", {
    Text = "Health Bar",
    Default = false,
})
VisualsEsp:AddToggle("EspBoxes", {
    Text = "Bounding Box",
    Default = false,
})
VisualsEsp:AddSlider("EspDistance", {
    Text = "Render Distance",
    Default = 500,
    Min = 100,
    Max = 2000,
    Rounding = 0,
})

local VisualsChams = Tabs.Visuals:AddRightGroupbox("Chams")
VisualsChams:AddToggle("ChamsEnabled", {
    Text = "Enabled",
    Default = false,
})
VisualsChams:AddDropdown("ChamsMode", {
    Text = "Mode",
    Values = { "Highlight", "Outline", "Box" },
    Default = "Highlight",
    Compact = true,
    ControlWidth = 112,
})
VisualsChams:AddSlider("ChamsTransparency", {
    Text = "Transparency",
    Default = 50,
    Min = 0,
    Max = 100,
    Rounding = 0,
    Suffix = "%",
})
VisualsChams:AddToggle("ChamsVisibleOnly", {
    Text = "Visible Only",
    Default = false,
})
VisualsChams:AddLabel("Chams Color"):AddColorPicker("ChamsColor", {
    Default = Color3.fromRGB(245, 224, 235),
    Title = "Chams Color",
})

-- Player
local PlayerMovement = Tabs.Player:AddLeftGroupbox("Movement")
PlayerMovement:AddToggle("SpeedEnabled", {
    Text = "Speed Hack",
    Default = false,
})
PlayerMovement:AddSlider("WalkSpeed", {
    Text = "Walk Speed",
    Default = 16,
    Min = 16,
    Max = 200,
    Rounding = 0,
})
local FlyEnabled = PlayerMovement:AddToggle("FlyEnabled", {
    Text = "Fly",
    Default = false,
})
PlayerMovement:AddLabel("Fly Key"):AddKeyPicker("FlyKeybind", {
    Default = "F",
    SyncToggleState = FlyEnabled,
    Mode = "Toggle",
    Text = "Fly",
    NoUI = false,
})
PlayerMovement:AddSlider("FlySpeed", {
    Text = "Fly Speed",
    Default = 50,
    Min = 10,
    Max = 300,
    Rounding = 0,
})

local PlayerCharacter = Tabs.Player:AddRightGroupbox("Character")
PlayerCharacter:AddToggle("NoClipEnabled", {
    Text = "No Clip",
    Default = false,
})
PlayerCharacter:AddToggle("InfJumpEnabled", {
    Text = "Infinite Jump",
    Default = false,
})
PlayerCharacter:AddSlider("JumpPower", {
    Text = "Jump Power",
    Default = 50,
    Min = 50,
    Max = 300,
    Rounding = 0,
})
PlayerCharacter:AddToggle("AntiVoidEnabled", {
    Text = "Anti Void",
    Default = false,
})

-- Advanced
local AdvancedControls = Tabs.Advanced:AddLeftGroupbox("Controls")
AdvancedControls:AddInput("CustomNote", {
    Text = "Custom Note",
    Default = "",
    Placeholder = "Type here...",
    ClearTextOnFocus = false,
    Compact = true,
    ControlWidth = 138,
})
AdvancedControls:AddDropdown("SearchableProfile", {
    Text = "Profile",
    Values = { "Legit", "Balanced", "Rage", "Silent", "Mobile", "Experimental" },
    Default = "Balanced",
    Searchable = true,
})
AdvancedControls:AddDropdown("EnabledModules", {
    Text = "Enabled Modules",
    Values = { "Aimbot", "ESP", "Trigger", "Speed", "Fly" },
    Multi = true,
})
AdvancedControls:AddLabel("Accent Preview"):AddColorPicker("AdvancedAccent", {
    Default = Color3.fromRGB(233, 194, 215),
    Title = "Accent Preview",
})
AdvancedControls:AddButton("Test Notification", function()
    notify("Kojo", "Notification working")
end)

local AdvancedBox = Tabs.Advanced:AddRightTabbox()
local AdvancedProfiles = AdvancedBox:AddTab("Profiles")
AdvancedProfiles:AddToggle("ProfileAutoLoad", { Text = "Auto Load Profile", Default = true })
AdvancedProfiles:AddDropdown("ProfileSlot", {
    Text = "Slot",
    Values = { "Default", "PvP", "Legit", "Mobile" },
    Default = "Default",
})

local AdvancedDebug = AdvancedBox:AddTab("Debug")
AdvancedDebug:AddToggle("ShowMetrics", { Text = "Show Metrics", Default = false })
AdvancedDebug:AddSlider("UIScale", {
    Text = "Window Scale",
    Default = 100,
    Min = 75,
    Max = 125,
    Rounding = 0,
    Suffix = "%",
    Callback = function(value)
        Library:SetDPIScale(value)
    end,
})

local AdvancedWorkspace = Tabs.Advanced:AddLeftGroupbox("Workspace")
local OpenWorkspaceButton = AdvancedWorkspace:AddButton("Open Workspace", function()
end)
styleDashboardButton(OpenWorkspaceButton, {
    BackgroundColor = Color3.fromRGB(34, 40, 58),
    StrokeColor = Color3.fromRGB(126, 149, 255),
    TextColor = Color3.fromRGB(244, 247, 255),
    Icon = "rbxassetid://116182575062729",
    IconGlowColor = Color3.fromRGB(126, 149, 255),
    Gradient = ColorSequence.new({
        ColorSequenceKeypoint.new(0, Color3.fromRGB(40, 54, 94)),
        ColorSequenceKeypoint.new(0.55, Color3.fromRGB(78, 95, 168)),
        ColorSequenceKeypoint.new(1, Color3.fromRGB(44, 58, 102)),
    }),
})
AdvancedWorkspace:AddLabel({
    Text = "Workspace opens a focused shell for Social and AI while hiding the main UI.",
    DoesWrap = true,
})

local function workspaceFont(weight)
    return Library:GetWeightedFont(weight or Enum.FontWeight.Medium)
end

local function tweenWorkspace(instance, duration, properties, style, direction)
    local tween = TweenService:Create(instance, TweenInfo.new(duration or 0.22, style or Enum.EasingStyle.Quint, direction or Enum.EasingDirection.Out), properties)
    tween:Play()
    return tween
end

local function createWorkspaceCard(parent, title, subtitle, position, size, accent)
    local card = createUi("Frame", {
        BackgroundColor3 = Color3.fromRGB(13, 16, 23),
        BorderSizePixel = 0,
        Position = position,
        Size = size,
        Parent = parent,
    })
    addCorner(card, 18)
    addStroke(card, Color3.fromRGB(52, 60, 79), 0.18, 1)

    local wash = createUi("Frame", {
        BackgroundColor3 = accent or Color3.fromRGB(91, 109, 255),
        BackgroundTransparency = 0.88,
        BorderSizePixel = 0,
        Position = UDim2.fromOffset(0, 0),
        Size = UDim2.new(1, 0, 0, 88),
        Parent = card,
    })
    addCorner(wash, 18)
    createUi("UIGradient", {
        Rotation = 24,
        Color = ColorSequence.new({
            ColorSequenceKeypoint.new(0, (accent or Color3.fromRGB(91, 109, 255)):Lerp(Color3.fromRGB(255, 255, 255), 0.14)),
            ColorSequenceKeypoint.new(1, Color3.fromRGB(13, 16, 23)),
        }),
        Transparency = NumberSequence.new({
            NumberSequenceKeypoint.new(0, 0.18),
            NumberSequenceKeypoint.new(1, 1),
        }),
        Parent = wash,
    })

    local titleLabel = createUi("TextLabel", {
        BackgroundTransparency = 1,
        FontFace = workspaceFont(Enum.FontWeight.Bold),
        Position = UDim2.fromOffset(16, 14),
        Size = UDim2.new(1, -32, 0, 18),
        Text = title,
        TextColor3 = Color3.fromRGB(243, 246, 255),
        TextSize = 15,
        TextXAlignment = Enum.TextXAlignment.Left,
        Parent = card,
    })
    local subtitleLabel = createUi("TextLabel", {
        BackgroundTransparency = 1,
        FontFace = workspaceFont(Enum.FontWeight.Medium),
        Position = UDim2.fromOffset(16, 34),
        Size = UDim2.new(1, -32, 0, 14),
        Text = subtitle or "",
        TextColor3 = Color3.fromRGB(137, 146, 165),
        TextSize = 11,
        TextXAlignment = Enum.TextXAlignment.Left,
        Parent = card,
    })
    createUi("Frame", {
        BackgroundColor3 = Color3.fromRGB(40, 46, 62),
        BackgroundTransparency = 0.15,
        BorderSizePixel = 0,
        Position = UDim2.new(0, 0, 0, 56),
        Size = UDim2.new(1, 0, 0, 1),
        Parent = card,
    })
    local body = createUi("Frame", {
        BackgroundTransparency = 1,
        Position = UDim2.fromOffset(16, 68),
        Size = UDim2.new(1, -32, 1, -84),
        Parent = card,
    })
    return {Card = card, Body = body, Title = titleLabel, Subtitle = subtitleLabel}
end

local function createWorkspaceActionButton(parent, text, position, size, style)
    local base = createUi("TextButton", {
        AutoButtonColor = false,
        BackgroundColor3 = Color3.fromRGB(24, 28, 40),
        BorderSizePixel = 0,
        Position = position,
        Size = size,
        Text = "",
        Parent = parent,
    })
    addCorner(base, 14)

    local stroke = addStroke(base, Color3.fromRGB(76, 86, 116), 0.08, 1)
    local button = {
        Base = base,
        Stroke = stroke,
        Text = text,
    }
    styleDashboardButton(button, style or {})
    return button
end

local function createWorkspacePill(parent, text, position, size, active, accent)
    local base = createUi("TextButton", {
        AutoButtonColor = false,
        BackgroundColor3 = active and accent or Color3.fromRGB(21, 25, 34),
        BorderSizePixel = 0,
        Position = position,
        Size = size,
        Text = "",
        Parent = parent,
    })
    addCorner(base, 12)
    local stroke = addStroke(base, active and accent:Lerp(Color3.fromRGB(255, 255, 255), 0.28) or Color3.fromRGB(60, 69, 89), active and 0.02 or 0.1, 1)
    local gradient = createUi("UIGradient", {
        Rotation = 0,
        Color = active and ColorSequence.new({
            ColorSequenceKeypoint.new(0, accent:Lerp(Color3.fromRGB(255, 255, 255), 0.15)),
            ColorSequenceKeypoint.new(1, accent),
        }) or ColorSequence.new({
            ColorSequenceKeypoint.new(0, Color3.fromRGB(22, 26, 36)),
            ColorSequenceKeypoint.new(1, Color3.fromRGB(28, 34, 48)),
        }),
        Parent = base,
    })
    local label = createUi("TextLabel", {
        BackgroundTransparency = 1,
        FontFace = workspaceFont(active and Enum.FontWeight.Bold or Enum.FontWeight.Medium),
        Position = UDim2.new(0, 18, 0, 0),
        Size = UDim2.new(1, -36, 1, 0),
        Text = text,
        TextColor3 = active and Color3.fromRGB(249, 251, 255) or Color3.fromRGB(198, 205, 221),
        TextSize = 13,
        Parent = base,
    })
    local icon = createUi("ImageLabel", {
        BackgroundTransparency = 1,
        Image = "",
        ImageColor3 = active and Color3.fromRGB(249, 251, 255) or Color3.fromRGB(175, 184, 205),
        ImageTransparency = 1,
        Position = UDim2.fromOffset(14, 10),
        Size = UDim2.fromOffset(16, 16),
        Parent = base,
    })
    return {Base = base, Label = label, Stroke = stroke, Gradient = gradient, Icon = icon}
end

local function createWorkspaceTextBox(parent, placeholder, position, size, multiline)
    local box = createUi("TextBox", {
        BackgroundColor3 = Color3.fromRGB(17, 20, 29),
        BorderSizePixel = 0,
        ClearTextOnFocus = false,
        FontFace = workspaceFont(Enum.FontWeight.Medium),
        PlaceholderColor3 = Color3.fromRGB(112, 120, 138),
        PlaceholderText = placeholder,
        Position = position,
        Size = size,
        Text = "",
        TextColor3 = Color3.fromRGB(236, 240, 250),
        TextSize = 13,
        TextWrapped = multiline and true or false,
        TextXAlignment = Enum.TextXAlignment.Left,
        TextYAlignment = multiline and Enum.TextYAlignment.Top or Enum.TextYAlignment.Center,
        MultiLine = multiline and true or false,
        Parent = parent,
    })
    addCorner(box, 14)
    addStroke(box, Color3.fromRGB(54, 61, 80), 0.12, 1)
    createUi("UIPadding", {
        PaddingLeft = UDim.new(0, 12),
        PaddingRight = UDim.new(0, 12),
        PaddingTop = UDim.new(0, multiline and 10 or 0),
        PaddingBottom = UDim.new(0, multiline and 10 or 0),
        Parent = box,
    })
    return box
end

local function createWorkspaceRosterEntry(parent, name, subtitle, accent, icon)
    local row = createUi("Frame", {
        BackgroundColor3 = Color3.fromRGB(18, 21, 30),
        BorderSizePixel = 0,
        Size = UDim2.new(1, 0, 0, 54),
        Parent = parent,
    })
    addCorner(row, 14)
    addStroke(row, Color3.fromRGB(54, 61, 80), 0.12, 1)

    local avatar = createUi("Frame", {
        BackgroundColor3 = accent,
        BorderSizePixel = 0,
        Position = UDim2.fromOffset(10, 9),
        Size = UDim2.fromOffset(36, 36),
        Parent = row,
    })
    addCorner(avatar, 18)
    createUi("UIGradient", {
        Rotation = 35,
        Color = ColorSequence.new({
            ColorSequenceKeypoint.new(0, accent:Lerp(Color3.fromRGB(255, 255, 255), 0.18)),
            ColorSequenceKeypoint.new(1, accent:Lerp(Color3.fromRGB(0, 0, 0), 0.18)),
        }),
        Parent = avatar,
    })
    if icon and icon ~= "" then
        createUi("ImageLabel", {
            BackgroundTransparency = 1,
            Image = icon,
            Position = UDim2.fromOffset(9, 9),
            Size = UDim2.fromOffset(18, 18),
            ImageColor3 = Color3.fromRGB(255, 255, 255),
            Parent = avatar,
        })
    end
    createUi("TextLabel", {
        BackgroundTransparency = 1,
        FontFace = workspaceFont(Enum.FontWeight.Bold),
        Position = UDim2.fromOffset(58, 10),
        Size = UDim2.new(1, -70, 0, 16),
        Text = name,
        TextColor3 = Color3.fromRGB(241, 245, 255),
        TextSize = 13,
        TextXAlignment = Enum.TextXAlignment.Left,
        Parent = row,
    })
    createUi("TextLabel", {
        BackgroundTransparency = 1,
        FontFace = workspaceFont(Enum.FontWeight.Medium),
        Position = UDim2.fromOffset(58, 27),
        Size = UDim2.new(1, -70, 0, 14),
        Text = subtitle,
        TextColor3 = Color3.fromRGB(149, 159, 181),
        TextSize = 11,
        TextXAlignment = Enum.TextXAlignment.Left,
        Parent = row,
    })
    return row
end

local function createWorkspaceBubble(parent, text, side, accent)
    local row = createUi("Frame", {
        BackgroundTransparency = 1,
        AutomaticSize = Enum.AutomaticSize.Y,
        Size = UDim2.new(1, 0, 0, 0),
        Parent = parent,
    })
    local bubble = createUi("Frame", {
        AnchorPoint = side == "Right" and Vector2.new(1, 0) or Vector2.new(0, 0),
        BackgroundColor3 = side == "Right" and (accent or Color3.fromRGB(92, 108, 255)) or Color3.fromRGB(19, 23, 32),
        BorderSizePixel = 0,
        AutomaticSize = Enum.AutomaticSize.Y,
        Position = side == "Right" and UDim2.new(1, 0, 0, 0) or UDim2.new(0, 0, 0, 0),
        Size = UDim2.new(0.72, 0, 0, 0),
        Parent = row,
    })
    addCorner(bubble, 16)
    addStroke(bubble, side == "Right" and Color3.fromRGB(160, 174, 255) or Color3.fromRGB(55, 63, 82), side == "Right" and 0.08 or 0.16, 1)
    createUi("UIPadding", {
        PaddingLeft = UDim.new(0, 14),
        PaddingRight = UDim.new(0, 14),
        PaddingTop = UDim.new(0, 11),
        PaddingBottom = UDim.new(0, 11),
        Parent = bubble,
    })
    createUi("TextLabel", {
        BackgroundTransparency = 1,
        AutomaticSize = Enum.AutomaticSize.Y,
        FontFace = workspaceFont(Enum.FontWeight.Medium),
        Size = UDim2.new(1, 0, 0, 0),
        Text = text,
        TextWrapped = true,
        TextColor3 = side == "Right" and Color3.fromRGB(252, 252, 255) or Color3.fromRGB(222, 228, 240),
        TextSize = 12,
        TextXAlignment = Enum.TextXAlignment.Left,
        TextYAlignment = Enum.TextYAlignment.Top,
        Parent = bubble,
    })
    return row
end

local function applyWorkspaceZ(object, z)
    if object:IsA("GuiObject") then
        object.ZIndex = z
    end

    for _, child in ipairs(object:GetChildren()) do
        local nextZ = z
        if child:IsA("TextLabel") or child:IsA("TextButton") or child:IsA("ImageLabel") or child:IsA("ImageButton") or child:IsA("TextBox") then
            nextZ = z + 1
        elseif child:IsA("ScrollingFrame") then
            nextZ = z
        end
        applyWorkspaceZ(child, nextZ)
    end
end

local WorkspaceShell = nil
local function ensureWorkspaceShell()
    if WorkspaceShell then
        return WorkspaceShell
    end

    WorkspaceShell = Window:AddSubInterface({
        Title = "Workspace",
        Subtitle = "Focused social and AI tools",
        Width = 944,
        Height = 556,
        AccentColor = Color3.fromRGB(126, 149, 255),
        BackButtonText = "Main UI",
        RailWidth = 182,
        CloseOnOverlay = false,
    })

    WorkspaceShell.Panel.BackgroundColor3 = Color3.fromRGB(7, 9, 14)
    WorkspaceShell.Stroke.Color = Color3.fromRGB(42, 49, 66)
    WorkspaceShell.Stroke.Transparency = 0.08
    WorkspaceShell.Rail.BackgroundColor3 = Color3.fromRGB(10, 12, 18)
    WorkspaceShell.Header.BackgroundColor3 = Color3.fromRGB(8, 10, 16)
    WorkspaceShell.BackButton.BackgroundColor3 = Color3.fromRGB(16, 20, 30)
    WorkspaceShell.BackButton.Size = UDim2.fromOffset(128, 38)
    WorkspaceShell.BackButton.Position = UDim2.fromOffset(16, 14)
    WorkspaceShell.Content.ClipsDescendants = true
    WorkspaceShell.TitleLabel.Visible = false
    WorkspaceShell.SubtitleLabel.Visible = false
    WorkspaceShell.AccentBar.Visible = false
    WorkspaceShell.Content.Position = UDim2.fromOffset(200, 78)
    WorkspaceShell.Content.Size = UDim2.new(1, -(182 + 36), 1, -94)

    local DragZone = createUi("TextButton", {
        Active = true,
        AutoButtonColor = false,
        BackgroundTransparency = 1,
        BorderSizePixel = 0,
        Position = UDim2.fromOffset(0, 0),
        Size = UDim2.new(1, -360, 1, 0),
        Text = "",
        Parent = WorkspaceShell.Header,
    })
    DragZone.ZIndex = 39
    pcall(function()
        Library:MakeDraggable(WorkspaceShell.Panel, DragZone, false, true)
    end)

    local HeaderPills = createUi("Frame", {
        BackgroundColor3 = Color3.fromRGB(13, 16, 24),
        BorderSizePixel = 0,
        AnchorPoint = Vector2.new(1, 0),
        Position = UDim2.new(1, -24, 0, 14),
        Size = UDim2.fromOffset(220, 40),
        Parent = WorkspaceShell.Header,
    })
    addCorner(HeaderPills, 16)
    addStroke(HeaderPills, Color3.fromRGB(57, 65, 86), 0.08, 1)
    local SocialPill = createWorkspacePill(HeaderPills, "Social", UDim2.fromOffset(4, 4), UDim2.fromOffset(104, 32), true, Color3.fromRGB(88, 106, 255))
    local AIPill = createWorkspacePill(HeaderPills, "AI", UDim2.fromOffset(112, 4), UDim2.fromOffset(104, 32), false, Color3.fromRGB(126, 102, 245))
    SocialPill.Icon.Image = normalizeImageAsset("rbxassetid://116182575062729")
    SocialPill.Icon.ImageTransparency = 0
    AIPill.Icon.Image = normalizeImageAsset("rbxassetid://10723382230")
    AIPill.Icon.ImageTransparency = 0

    local HeaderTag = createUi("Frame", {
        BackgroundColor3 = Color3.fromRGB(18, 22, 31),
        BorderSizePixel = 0,
        Position = UDim2.fromOffset(162, 10),
        Size = UDim2.fromOffset(326, 52),
        Parent = WorkspaceShell.Header,
    })
    addCorner(HeaderTag, 18)
    addStroke(HeaderTag, Color3.fromRGB(84, 96, 124), 0.04, 1)
    local HeaderTagGlow = createUi("Frame", {
        BackgroundColor3 = Color3.fromRGB(122, 94, 255),
        BackgroundTransparency = 0.9,
        BorderSizePixel = 0,
        Position = UDim2.fromOffset(12, 10),
        Size = UDim2.new(1, -24, 1, -20),
        Parent = HeaderTag,
    })
    addCorner(HeaderTagGlow, 16)
    local HeaderTagBackground = createUi("ImageLabel", {
        BackgroundTransparency = 1,
        Image = "",
        ImageTransparency = 0.18,
        ScaleType = Enum.ScaleType.Crop,
        Size = UDim2.fromScale(1, 1),
        Parent = HeaderTag,
    })
    addCorner(HeaderTagBackground, 18)
    createUi("UIGradient", {
        Rotation = 0,
        Color = ColorSequence.new({
            ColorSequenceKeypoint.new(0, Color3.fromRGB(244, 247, 255)),
            ColorSequenceKeypoint.new(1, Color3.fromRGB(218, 227, 248)),
        }),
        Transparency = NumberSequence.new({
            NumberSequenceKeypoint.new(0, 0.72),
            NumberSequenceKeypoint.new(1, 0.9),
        }),
        Parent = HeaderTagBackground,
    })
    local HeaderTagAvatarRing = createUi("Frame", {
        BackgroundColor3 = Color3.fromRGB(244, 247, 255),
        BorderSizePixel = 0,
        Position = UDim2.fromOffset(11, 7),
        Size = UDim2.fromOffset(38, 38),
        Parent = HeaderTag,
    })
    addCorner(HeaderTagAvatarRing, 19)
    local HeaderTagAvatar = createUi("ImageLabel", {
        BackgroundTransparency = 1,
        Image = "",
        Position = UDim2.fromOffset(3, 3),
        Size = UDim2.fromOffset(32, 32),
        Parent = HeaderTagAvatarRing,
    })
    addCorner(HeaderTagAvatar, 16)
    local HeaderTagName = createUi("TextLabel", {
        BackgroundTransparency = 1,
        FontFace = workspaceFont(Enum.FontWeight.SemiBold),
        Position = UDim2.fromOffset(62, 8),
        Size = UDim2.new(1, -74, 0, 18),
        Text = getKojoUserName(),
        TextColor3 = Color3.fromRGB(241, 245, 255),
        TextSize = 16,
        TextTruncate = Enum.TextTruncate.AtEnd,
        TextXAlignment = Enum.TextXAlignment.Left,
        Parent = HeaderTag,
    })
    local HeaderTagBrand = createUi("TextLabel", {
        BackgroundTransparency = 1,
        FontFace = workspaceFont(Enum.FontWeight.Bold),
        Position = UDim2.fromOffset(62, 31),
        Size = UDim2.new(0, 56, 0, 12),
        Text = "KOJO",
        TextColor3 = Color3.fromRGB(236, 186, 215),
        TextSize = 10,
        TextXAlignment = Enum.TextXAlignment.Left,
        Parent = HeaderTag,
    })
    local HeaderTagTier = createUi("TextLabel", {
        BackgroundTransparency = 1,
        FontFace = workspaceFont(Enum.FontWeight.SemiBold),
        Position = UDim2.fromOffset(122, 31),
        Size = UDim2.new(1, -132, 0, 12),
        Text = tostring(getKojoValue("KOJO_UserTier", "Freemium")),
        TextColor3 = Color3.fromRGB(132, 141, 164),
        TextSize = 10,
        TextTruncate = Enum.TextTruncate.AtEnd,
        TextXAlignment = Enum.TextXAlignment.Left,
        Parent = HeaderTag,
    })

    local RailHero = createUi("Frame", {
        BackgroundColor3 = Color3.fromRGB(16, 20, 28),
        BorderSizePixel = 0,
        LayoutOrder = 1,
        Size = UDim2.new(1, 0, 0, 118),
        Parent = WorkspaceShell.RailContent,
    })
    addCorner(RailHero, 16)
    addStroke(RailHero, Color3.fromRGB(54, 63, 86), 0.1, 1)
    createUi("UIGradient", {
        Rotation = 30,
        Color = ColorSequence.new({
            ColorSequenceKeypoint.new(0, Color3.fromRGB(30, 42, 78)),
            ColorSequenceKeypoint.new(0.55, Color3.fromRGB(55, 72, 120)),
            ColorSequenceKeypoint.new(1, Color3.fromRGB(16, 20, 28)),
        }),
        Parent = RailHero,
    })
    createUi("TextLabel", {
        BackgroundTransparency = 1,
        FontFace = workspaceFont(Enum.FontWeight.Bold),
        Position = UDim2.fromOffset(14, 14),
        Size = UDim2.new(1, -28, 0, 18),
        Text = "Workspace",
        TextColor3 = Color3.fromRGB(246, 248, 255),
        TextSize = 15,
        TextXAlignment = Enum.TextXAlignment.Left,
        Parent = RailHero,
    })
    createUi("TextLabel", {
        BackgroundTransparency = 1,
        FontFace = workspaceFont(Enum.FontWeight.Medium),
        Position = UDim2.fromOffset(14, 36),
        Size = UDim2.new(1, -28, 0, 40),
        Text = "Private shell for social rooms and assistant flows.",
        TextWrapped = true,
        TextColor3 = Color3.fromRGB(203, 211, 228),
        TextSize = 11,
        TextXAlignment = Enum.TextXAlignment.Left,
        TextYAlignment = Enum.TextYAlignment.Top,
        Parent = RailHero,
    })

    local ModuleSync = createWorkspaceRosterEntry(WorkspaceShell.RailContent, "Kojo Sync", "Rooms and presence", Color3.fromRGB(88, 106, 255), "rbxassetid://116182575062729")
    ModuleSync.LayoutOrder = 2
    local ModuleAI = createWorkspaceRosterEntry(WorkspaceShell.RailContent, "Kojo AI", "Assistant workspace", Color3.fromRGB(126, 102, 245), "rbxassetid://10723382230")
    ModuleAI.LayoutOrder = 3

    local SocialRoot = createUi("Frame", {BackgroundTransparency = 1, Position = UDim2.fromScale(0, 0), Size = UDim2.fromScale(1, 1), Parent = WorkspaceShell.Content})
    local AIRoot = createUi("Frame", {BackgroundTransparency = 1, Position = UDim2.fromScale(0.08, 0), Size = UDim2.fromScale(1, 1), Visible = false, Parent = WorkspaceShell.Content})

    local function clearWorkspaceList(container)
        for _, child in ipairs(container:GetChildren()) do
            if not child:IsA("UIListLayout") and not child:IsA("UIPadding") then
                child:Destroy()
            end
        end
    end

    local function scrollToBottom(frame)
        task.defer(function()
            local maxY = math.max(0, frame.AbsoluteCanvasSize.Y - frame.AbsoluteWindowSize.Y)
            frame.CanvasPosition = Vector2.new(0, maxY)
        end)
    end

    local function addChannel(parent, name, subtitle, accent, active)
        local item = createUi("TextButton", {
            AutoButtonColor = false,
            BackgroundColor3 = active and Color3.fromRGB(29, 36, 54) or Color3.fromRGB(17, 20, 29),
            BorderSizePixel = 0,
            Size = UDim2.new(1, 0, 0, 46),
            Text = "",
            Parent = parent,
        })
        addCorner(item, 12)
        addStroke(item, active and accent or Color3.fromRGB(53, 61, 80), active and 0.08 or 0.16, 1)
        local marker = createUi("Frame", {
            BackgroundColor3 = accent,
            BorderSizePixel = 0,
            Position = UDim2.fromOffset(12, 18),
            Size = UDim2.fromOffset(9, 9),
            Parent = item,
        })
        createUi("UICorner", {CornerRadius = UDim.new(1, 0), Parent = marker})
        createUi("TextLabel", {
            BackgroundTransparency = 1,
            FontFace = workspaceFont(active and Enum.FontWeight.Bold or Enum.FontWeight.Medium),
            Position = UDim2.fromOffset(30, 8),
            Size = UDim2.new(1, -42, 0, 14),
            Text = name,
            TextColor3 = active and Color3.fromRGB(246, 248, 255) or Color3.fromRGB(201, 208, 223),
            TextSize = 12,
            TextXAlignment = Enum.TextXAlignment.Left,
            Parent = item,
        })
        createUi("TextLabel", {
            BackgroundTransparency = 1,
            FontFace = workspaceFont(Enum.FontWeight.Medium),
            Position = UDim2.fromOffset(30, 22),
            Size = UDim2.new(1, -42, 0, 12),
            Text = subtitle,
            TextColor3 = Color3.fromRGB(144, 153, 174),
            TextSize = 10,
            TextXAlignment = Enum.TextXAlignment.Left,
            Parent = item,
        })
        return item
    end

    local function createModeCard(parent, title, body, accent)
        local card = createUi("Frame", {
            BackgroundColor3 = Color3.fromRGB(18, 21, 30),
            BorderSizePixel = 0,
            Size = UDim2.new(1, 0, 0, 86),
            Parent = parent,
        })
        addCorner(card, 16)
        addStroke(card, Color3.fromRGB(54, 61, 80), 0.12, 1)
        local iconGlow = createUi("Frame", {
            BackgroundColor3 = accent,
            BackgroundTransparency = 0.08,
            BorderSizePixel = 0,
            Position = UDim2.fromOffset(14, 16),
            Size = UDim2.fromOffset(42, 42),
            Parent = card,
        })
        addCorner(iconGlow, 21)
        createUi("UIGradient", {
            Rotation = 35,
            Color = ColorSequence.new({
                ColorSequenceKeypoint.new(0, accent:Lerp(Color3.fromRGB(255, 255, 255), 0.18)),
                ColorSequenceKeypoint.new(1, accent:Lerp(Color3.fromRGB(0, 0, 0), 0.12)),
            }),
            Parent = iconGlow,
        })
        createUi("TextLabel", {
            BackgroundTransparency = 1,
            FontFace = workspaceFont(Enum.FontWeight.Bold),
            Position = UDim2.fromOffset(68, 18),
            Size = UDim2.new(1, -82, 0, 16),
            Text = title,
            TextColor3 = Color3.fromRGB(246, 248, 255),
            TextSize = 14,
            TextXAlignment = Enum.TextXAlignment.Left,
            Parent = card,
        })
        createUi("TextLabel", {
            BackgroundTransparency = 1,
            FontFace = workspaceFont(Enum.FontWeight.Medium),
            Position = UDim2.fromOffset(68, 36),
            Size = UDim2.new(1, -82, 0, 28),
            Text = body,
            TextWrapped = true,
            TextColor3 = Color3.fromRGB(149, 159, 181),
            TextSize = 11,
            TextXAlignment = Enum.TextXAlignment.Left,
            TextYAlignment = Enum.TextYAlignment.Top,
            Parent = card,
        })
        return card
    end

    local function resolveWorkspaceTagBackground()
        local backgroundImage = ""
        if Options.NametagBackground and NametagBackgroundPresets[Options.NametagBackground.Value] then
            backgroundImage = tostring(NametagBackgroundPresets[Options.NametagBackground.Value] or "")
        end
        return backgroundImage
    end

    local function refreshWorkspaceHeaderTag(profile)
        profile = type(profile) == "table" and profile or (getKojoSocial() and getKojoSocial().profile or nil) or {}
        HeaderTagName.Text = getCurrentProfileDisplayName(profile)
        HeaderTagTier.Text = tostring(getKojoValue("KOJO_UserTier", "Freemium"))
        HeaderTagAvatar.Image = getCurrentProfileAvatar(profile)
        HeaderTagBackground.Image = resolveWorkspaceTagBackground()
        HeaderTagBackground.ImageTransparency = (Options.NametagTransparency and Options.NametagTransparency.Value or 28) / 100
    end

    local SocialRail = createWorkspaceCard(SocialRoot, "Community", "Rooms, direct links, and presence", UDim2.new(0, 0, 0, 0), UDim2.new(0, 268, 1, 0), Color3.fromRGB(88, 106, 255))
    local SocialFeed = createWorkspaceCard(SocialRoot, "Global", "Shared shell for Kojo users", UDim2.new(0, 284, 0, 0), UDim2.new(1, -284, 1, 0), Color3.fromRGB(111, 128, 255))

    createUi("TextLabel", {
        BackgroundTransparency = 1,
        FontFace = workspaceFont(Enum.FontWeight.Bold),
        Position = UDim2.fromOffset(0, 0),
        Size = UDim2.new(1, 0, 0, 16),
        Text = "Rooms",
        TextColor3 = Color3.fromRGB(243, 246, 255),
        TextSize = 13,
        TextXAlignment = Enum.TextXAlignment.Left,
        Parent = SocialRail.Body,
    })
    local ChannelList = createUi("ScrollingFrame", {
        Active = true,
        AutomaticCanvasSize = Enum.AutomaticSize.Y,
        BackgroundTransparency = 1,
        BorderSizePixel = 0,
        CanvasSize = UDim2.new(),
        Position = UDim2.fromOffset(0, 24),
        ScrollBarImageColor3 = Color3.fromRGB(74, 84, 108),
        ScrollBarThickness = 2,
        Size = UDim2.new(1, 0, 0, 180),
        Parent = SocialRail.Body,
    })
    createUi("UIListLayout", {
        Padding = UDim.new(0, 8),
        SortOrder = Enum.SortOrder.LayoutOrder,
        Parent = ChannelList,
    })

    local CurrentRoomLabel = nil
    local CurrentRoomSub = nil
    local CurrentRoomKey = "global"
    local loadRoomHistory
    local ActiveChannel = nil
    local function setActiveChannel(button, accent)
        if ActiveChannel and ActiveChannel ~= button then
            ActiveChannel.BackgroundColor3 = Color3.fromRGB(17, 20, 29)
            local stroke = ActiveChannel:FindFirstChildOfClass("UIStroke")
            if stroke then
                stroke.Color = Color3.fromRGB(53, 61, 80)
                stroke.Transparency = 0.16
            end
        end
        ActiveChannel = button
        button.BackgroundColor3 = Color3.fromRGB(29, 36, 54)
        local stroke = button:FindFirstChildOfClass("UIStroke")
        if stroke then
            stroke.Color = accent
            stroke.Transparency = 0.08
        end
        if CurrentRoomLabel then
            CurrentRoomLabel.Text = button:GetAttribute("RoomTitle") or "# global"
        end
        if CurrentRoomSub then
            CurrentRoomSub.Text = button:GetAttribute("RoomSub") or "Shared shell for Kojo users."
        end
        CurrentRoomKey = tostring(button:GetAttribute("RoomKey") or "global")
    end

    local function addWorkspaceChannel(roomKey, name, subtitle, accent, active)
        local item = addChannel(ChannelList, name, subtitle, accent, active)
        item:SetAttribute("RoomKey", roomKey)
        item:SetAttribute("RoomTitle", name)
        item:SetAttribute("RoomSub", subtitle)
        item.MouseButton1Click:Connect(function()
            setActiveChannel(item, accent)
            if loadRoomHistory then
                loadRoomHistory(roomKey)
            end
        end)
        if active then
            ActiveChannel = item
        end
        return item
    end

    addWorkspaceChannel("global", "# global", "Public Kojo channel", Color3.fromRGB(96, 114, 255), true)
    addWorkspaceChannel("support", "# support", "Help and moderation", Color3.fromRGB(113, 218, 178), false)
    addWorkspaceChannel("updates", "# updates", "Release notes", Color3.fromRGB(255, 162, 91), false)
    addWorkspaceChannel("direct", "Direct", "Private rooms", Color3.fromRGB(206, 120, 255), false)

    createUi("TextLabel", {
        BackgroundTransparency = 1,
        FontFace = workspaceFont(Enum.FontWeight.Bold),
        Position = UDim2.fromOffset(0, 218),
        Size = UDim2.new(1, 0, 0, 16),
        Text = "Online now",
        TextColor3 = Color3.fromRGB(243, 246, 255),
        TextSize = 13,
        TextXAlignment = Enum.TextXAlignment.Left,
        Parent = SocialRail.Body,
    })
    local PresenceList = createUi("ScrollingFrame", {
        Active = true,
        AutomaticCanvasSize = Enum.AutomaticSize.Y,
        BackgroundTransparency = 1,
        BorderSizePixel = 0,
        CanvasSize = UDim2.new(),
        Position = UDim2.fromOffset(0, 242),
        ScrollBarImageColor3 = Color3.fromRGB(74, 84, 108),
        ScrollBarThickness = 2,
        Size = UDim2.new(1, 0, 1, -242),
        Parent = SocialRail.Body,
    })
    createUi("UIListLayout", {
        Padding = UDim.new(0, 8),
        SortOrder = Enum.SortOrder.LayoutOrder,
        Parent = PresenceList,
    })

    local function populatePresence()
        clearWorkspaceList(PresenceList)
        local roster = nil
        local social = getKojoSocial()
        if social and type(social.list_presence) == "function" then
            local ok, result = pcall(social.list_presence)
            if ok and type(result) == "table" and #result > 0 then
                roster = result
            end
        end

        if not roster then
            roster = {
                {name = tostring(ProfileName), subtitle = tostring(GameName), accent = Color3.fromRGB(88, 106, 255), icon = "rbxassetid://10747373176"},
                {name = "Yuna", subtitle = "Support room", accent = Color3.fromRGB(254, 140, 192), icon = "rbxassetid://10723406885"},
                {name = "Chuna", subtitle = "Bridge online", accent = Color3.fromRGB(115, 218, 177), icon = "rbxassetid://10723382230"},
            }
        end

        for _, entry in ipairs(roster) do
            local accent = entry.accent
            if typeof(accent) ~= "Color3" then
                accent = Color3.fromRGB(88, 106, 255)
            end
            createWorkspaceRosterEntry(
                PresenceList,
                tostring(entry.display_name or entry.name or "Unknown"),
                tostring(entry.game_name or entry.subtitle or "Online"),
                accent,
                tostring(entry.icon or entry.avatar or "rbxassetid://10747373176")
            )
        end
    end

    local FeedHeader = createUi("Frame", {
        BackgroundColor3 = Color3.fromRGB(16, 20, 28),
        BorderSizePixel = 0,
        Position = UDim2.fromOffset(0, 0),
        Size = UDim2.new(1, 0, 0, 56),
        Parent = SocialFeed.Body,
    })
    addCorner(FeedHeader, 14)
    addStroke(FeedHeader, Color3.fromRGB(52, 60, 79), 0.12, 1)
    CurrentRoomLabel = createUi("TextLabel", {
        BackgroundTransparency = 1,
        FontFace = workspaceFont(Enum.FontWeight.Bold),
        Position = UDim2.fromOffset(16, 10),
        Size = UDim2.new(1, -140, 0, 16),
        Text = "# global",
        TextColor3 = Color3.fromRGB(246, 248, 255),
        TextSize = 13,
        TextXAlignment = Enum.TextXAlignment.Left,
        Parent = FeedHeader,
    })
    CurrentRoomSub = createUi("TextLabel", {
        BackgroundTransparency = 1,
        FontFace = workspaceFont(Enum.FontWeight.Medium),
        Position = UDim2.fromOffset(16, 28),
        Size = UDim2.new(1, -140, 0, 14),
        Text = "Public Kojo channel",
        TextColor3 = Color3.fromRGB(157, 166, 187),
        TextSize = 11,
        TextXAlignment = Enum.TextXAlignment.Left,
        Parent = FeedHeader,
    })
    createWorkspacePill(FeedHeader, "Bridge Live", UDim2.new(1, -114, 0, 13), UDim2.fromOffset(98, 30), true, Color3.fromRGB(88, 106, 255))

    local Messages = createUi("ScrollingFrame", {
        Active = true,
        AutomaticCanvasSize = Enum.AutomaticSize.Y,
        BackgroundTransparency = 1,
        BorderSizePixel = 0,
        CanvasSize = UDim2.new(),
        Position = UDim2.fromOffset(0, 68),
        ScrollBarImageColor3 = Color3.fromRGB(74, 84, 108),
        ScrollBarThickness = 3,
        Size = UDim2.new(1, 0, 1, -130),
        Parent = SocialFeed.Body,
    })
    createUi("UIPadding", {
        PaddingBottom = UDim.new(0, 6),
        Parent = Messages,
    })
    createUi("UIListLayout", {
        Padding = UDim.new(0, 10),
        SortOrder = Enum.SortOrder.LayoutOrder,
        Parent = Messages,
    })

    local function addSystemMessages(roomKey)
        clearWorkspaceList(Messages)
        if roomKey == "support" then
            createWorkspaceBubble(Messages, "Support channel is ready. When backend transport is online, staff responses land here.", "Left")
        elseif roomKey == "updates" then
            createWorkspaceBubble(Messages, "Release notes and patch updates will stream here.", "Left")
        elseif roomKey == "direct" then
            createWorkspaceBubble(Messages, "Direct messages are not wired yet. This shell is reserved for private threads.", "Left")
        else
            createWorkspaceBubble(Messages, "Kojo transport foundation is ready. Presence and channel routing can plug into this shell without touching the main UI.", "Left")
            createWorkspaceBubble(Messages, "This shell is where global chat and private rooms will land.", "Left")
            createWorkspaceBubble(Messages, "Good. Keep the main UI clean.", "Right", Color3.fromRGB(88, 106, 255))
        end
        scrollToBottom(Messages)
    end

    local function renderBackendMessages(history)
        clearWorkspaceList(Messages)
        if type(history) ~= "table" or #history == 0 then
            addSystemMessages(CurrentRoomKey)
            return
        end
        local selfProfileId = tostring(getKojoValue("KOJO_ProfileId", ""))
        for _, entry in ipairs(history) do
            local content = tostring(entry.content or "")
            if content ~= "" then
                local author = tostring(entry.display_name or "Kojo")
                local side = tostring(entry.profile_id or "") == selfProfileId and "Right" or "Left"
                local accent = side == "Right" and Color3.fromRGB(88, 106, 255) or nil
                createWorkspaceBubble(Messages, side == "Left" and (author .. "\n" .. content) or content, side, accent)
            end
        end
        scrollToBottom(Messages)
    end

    loadRoomHistory = function(roomKey, silent)
        roomKey = tostring(roomKey or CurrentRoomKey or "global")
        CurrentRoomKey = roomKey
        local social = getKojoSocial()
        if social and type(social.listRoomMessages) == "function" and roomKey ~= "direct" then
            local ok, history = pcall(social.listRoomMessages, roomKey, 60)
            if ok and type(history) == "table" then
                renderBackendMessages(history)
                return
            end
            if not silent then
                notify("Kojo", "Chat transport unavailable, showing local preview")
            end
        end
        addSystemMessages(roomKey)
    end

    local SocialDraft = createWorkspaceTextBox(SocialFeed.Body, "Write to the current room", UDim2.new(0, 0, 1, -48), UDim2.new(1, -118, 0, 42), false)
    local SocialSend = createWorkspaceActionButton(SocialFeed.Body, "Send", UDim2.new(1, -104, 1, -48), UDim2.fromOffset(104, 42), {
        BackgroundColor = Color3.fromRGB(89, 107, 255),
        StrokeColor = Color3.fromRGB(156, 170, 255),
        Gradient = ColorSequence.new({
            ColorSequenceKeypoint.new(0, Color3.fromRGB(89, 107, 255)),
            ColorSequenceKeypoint.new(0.5, Color3.fromRGB(120, 136, 255)),
            ColorSequenceKeypoint.new(1, Color3.fromRGB(89, 107, 255)),
        }),
    })
    SocialSend.Base.MouseButton1Click:Connect(function()
        local draft = tostring(SocialDraft.Text or ""):match("^%s*(.-)%s*$")
        if draft == "" then
            notify("Kojo", "Enter a message first")
            return
        end
        local social = getKojoSocial()
        SocialDraft.Text = ""
        if social and type(social.sendRoomMessage) == "function" and CurrentRoomKey ~= "direct" then
            local ok, message = pcall(social.sendRoomMessage, CurrentRoomKey, draft)
            if ok and type(message) == "table" then
                loadRoomHistory(CurrentRoomKey, true)
                return
            end
        end
        createWorkspaceBubble(Messages, draft, "Right", Color3.fromRGB(88, 106, 255))
        scrollToBottom(Messages)
        task.delay(0.1, function()
            createWorkspaceBubble(Messages, "Transport is not connected yet. This shell is ready for the backend bridge.", "Left")
            scrollToBottom(Messages)
        end)
    end)

    local AIControlCard = createWorkspaceCard(AIRoot, "AI Control", "Assistant tools stay in this shell only", UDim2.new(0, 0, 0, 0), UDim2.new(0, 228, 1, 0), Color3.fromRGB(126, 102, 245))
    local AssistantCard = createWorkspaceCard(AIRoot, "Kojo Assistant", "Prompt-aware help and future routing", UDim2.new(0, 244, 0, 0), UDim2.new(1, -244, 1, 0), Color3.fromRGB(126, 102, 245))

    local AIControlBody = createUi("Frame", {
        BackgroundTransparency = 1,
        Position = UDim2.new(),
        Size = UDim2.fromScale(1, 1),
        Parent = AIControlCard.Body,
    })
    createUi("UIListLayout", {
        Padding = UDim.new(0, 12),
        SortOrder = Enum.SortOrder.LayoutOrder,
        Parent = AIControlBody,
    })
    createModeCard(AIControlBody, "Kojo AI", "Gemini-backed assistant shell for profile, presence, and support flows.", Color3.fromRGB(126, 102, 245))
    local ProviderChip = createWorkspaceActionButton(AIControlBody, "Provider: Gemini", UDim2.new(), UDim2.new(1, 0, 0, 40), {
        BackgroundColor = Color3.fromRGB(20, 24, 34),
        StrokeColor = Color3.fromRGB(83, 93, 122),
        Gradient = ColorSequence.new({
            ColorSequenceKeypoint.new(0, Color3.fromRGB(24, 28, 39)),
            ColorSequenceKeypoint.new(1, Color3.fromRGB(31, 36, 50)),
        }),
    })
    local LiveTranslate = createWorkspaceActionButton(AIControlBody, "Auto Translate Chat: Off", UDim2.new(), UDim2.new(1, 0, 0, 42), {
        BackgroundColor = Color3.fromRGB(27, 32, 42),
        StrokeColor = Color3.fromRGB(87, 98, 126),
        Gradient = ColorSequence.new({
            ColorSequenceKeypoint.new(0, Color3.fromRGB(27, 32, 42)),
            ColorSequenceKeypoint.new(1, Color3.fromRGB(36, 42, 57)),
        }),
    })
    local TranslateStateLabel = createUi("TextLabel", {
        BackgroundTransparency = 1,
        FontFace = workspaceFont(Enum.FontWeight.Medium),
        LayoutOrder = 10,
        Size = UDim2.new(1, 0, 0, 42),
        Text = "Incoming social messages can be translated in place once room transport is active.",
        TextWrapped = true,
        TextColor3 = Color3.fromRGB(166, 175, 194),
        TextSize = 11,
        TextXAlignment = Enum.TextXAlignment.Left,
        TextYAlignment = Enum.TextYAlignment.Top,
        Parent = AIControlBody,
    })
    ProviderChip.Base.AutoButtonColor = false
    local TranslateEnabled = false
    LiveTranslate.Base.MouseButton1Click:Connect(function()
        TranslateEnabled = not TranslateEnabled
        local label = LiveTranslate.Base:FindFirstChild("KojoButtonLabel")
        if label then
            label.Text = TranslateEnabled and "Auto Translate Chat: On" or "Auto Translate Chat: Off"
        end
    end)

    local AssistantStream = createUi("ScrollingFrame", {
        Active = true,
        AutomaticCanvasSize = Enum.AutomaticSize.Y,
        BackgroundColor3 = Color3.fromRGB(15, 18, 27),
        BorderSizePixel = 0,
        CanvasSize = UDim2.new(),
        Position = UDim2.fromOffset(0, 0),
        ScrollBarImageColor3 = Color3.fromRGB(74, 84, 108),
        ScrollBarThickness = 3,
        Size = UDim2.new(1, 0, 1, -86),
        Parent = AssistantCard.Body,
    })
    addCorner(AssistantStream, 16)
    addStroke(AssistantStream, Color3.fromRGB(52, 60, 79), 0.12, 1)
    createUi("UIPadding", {
        PaddingLeft = UDim.new(0, 16),
        PaddingRight = UDim.new(0, 16),
        PaddingTop = UDim.new(0, 16),
        PaddingBottom = UDim.new(0, 16),
        Parent = AssistantStream,
    })
    createUi("UIListLayout", {
        Padding = UDim.new(0, 12),
        SortOrder = Enum.SortOrder.LayoutOrder,
        Parent = AssistantStream,
    })
    createWorkspaceBubble(AssistantStream, "Kojo assistant stays inside this shell. Use it for profile support, presence status, and AI translation status.", "Left")
    createWorkspaceBubble(AssistantStream, "Good. Keep it separate from the main UI.", "Right", Color3.fromRGB(126, 102, 245))

    local AssistantPrompt = createWorkspaceTextBox(AssistantCard.Body, "Message Kojo AI", UDim2.new(0, 0, 1, -42), UDim2.new(1, -118, 0, 42), false)
    local AssistantAsk = createWorkspaceActionButton(AssistantCard.Body, "Send", UDim2.new(1, -104, 1, -42), UDim2.fromOffset(104, 42), {
        BackgroundColor = Color3.fromRGB(128, 97, 255),
        StrokeColor = Color3.fromRGB(193, 174, 255),
        Gradient = ColorSequence.new({
            ColorSequenceKeypoint.new(0, Color3.fromRGB(122, 94, 255)),
            ColorSequenceKeypoint.new(0.5, Color3.fromRGB(154, 124, 255)),
            ColorSequenceKeypoint.new(1, Color3.fromRGB(122, 94, 255)),
        }),
    })
    AssistantAsk.Base.MouseButton1Click:Connect(function()
        local prompt = tostring(AssistantPrompt.Text or ""):match("^%s*(.-)%s*$")
        if prompt == "" then
            notify("Kojo", "Enter a prompt first")
            return
        end

        createWorkspaceBubble(AssistantStream, prompt, "Right", Color3.fromRGB(126, 102, 245))
        AssistantPrompt.Text = ""
        scrollToBottom(AssistantStream)

        local social = getKojoSocial()
        if not social or type(social.ask) ~= "function" then
            createWorkspaceBubble(AssistantStream, "Assistant bridge unavailable. Deploy the backend AI route and the workspace will use it here.", "Left")
            scrollToBottom(AssistantStream)
            return
        end

        local ok, response = pcall(social.ask, prompt, nil, "gemini")
        if ok and type(response) == "table" and type(response.reply) == "string" and response.reply ~= "" then
            createWorkspaceBubble(AssistantStream, response.reply, "Left")
        elseif ok and type(response) == "string" and response ~= "" then
            createWorkspaceBubble(AssistantStream, response, "Left")
        else
            createWorkspaceBubble(AssistantStream, "Assistant request sent. Response bridge is not returning text in this preview yet.", "Left")
        end
        scrollToBottom(AssistantStream)
    end)

    local function setModuleActive(card, active, accent)
        card.BackgroundColor3 = active and Color3.fromRGB(23, 29, 42) or Color3.fromRGB(18, 21, 30)
        local stroke = card:FindFirstChildOfClass("UIStroke")
        if stroke then
            stroke.Color = active and accent or Color3.fromRGB(54, 61, 80)
            stroke.Transparency = active and 0.04 or 0.12
        end
    end

    local function makeCardClickable(card, callback)
        local hit = createUi("TextButton", {
            Active = true,
            AutoButtonColor = false,
            BackgroundTransparency = 1,
            BorderSizePixel = 0,
            Position = UDim2.new(),
            Size = UDim2.fromScale(1, 1),
            Text = "",
            Parent = card,
        })
        hit.ZIndex = 46
        hit.MouseButton1Click:Connect(callback)
    end

    local function setPillState(pill, active, accent)
        pill.Base.BackgroundColor3 = active and accent or Color3.fromRGB(21, 25, 34)
        pill.Stroke.Color = active and accent:Lerp(Color3.fromRGB(255, 255, 255), 0.28) or Color3.fromRGB(60, 69, 89)
        pill.Stroke.Transparency = active and 0.02 or 0.1
        pill.Gradient.Color = active and ColorSequence.new({
            ColorSequenceKeypoint.new(0, accent:Lerp(Color3.fromRGB(255, 255, 255), 0.15)),
            ColorSequenceKeypoint.new(1, accent),
        }) or ColorSequence.new({
            ColorSequenceKeypoint.new(0, Color3.fromRGB(22, 26, 36)),
            ColorSequenceKeypoint.new(1, Color3.fromRGB(28, 34, 48)),
        })
        pill.Label.TextColor3 = active and Color3.fromRGB(249, 251, 255) or Color3.fromRGB(198, 205, 221)
        pill.Label.FontFace = workspaceFont(active and Enum.FontWeight.Bold or Enum.FontWeight.Medium)
        if pill.Icon then
            pill.Icon.ImageColor3 = active and Color3.fromRGB(249, 251, 255) or Color3.fromRGB(175, 184, 205)
            pill.Icon.ImageTransparency = 0
        end
    end

    local function playWorkspaceReveal(root)
        for _, child in ipairs(root:GetChildren()) do
            if child:IsA("Frame") or child:IsA("ScrollingFrame") then
                local original = child.Position
                child.Position = original + UDim2.fromOffset(0, 14)
                tweenWorkspace(child, 0.24, {Position = original})
            end
        end
    end

    local function switchWorkspaceMode(mode)
        local showSocial = mode == "Social"
        local entering = showSocial and SocialRoot or AIRoot
        local leaving = showSocial and AIRoot or SocialRoot

        entering.Visible = true
        entering.Position = UDim2.new(showSocial and 0.06 or -0.06, 0, 0, 0)
        tweenWorkspace(entering, 0.24, {Position = UDim2.fromScale(0, 0)})
        if leaving.Visible then
            tweenWorkspace(leaving, 0.18, {Position = UDim2.new(showSocial and -0.05 or 0.05, 0, 0, 0)}, Enum.EasingStyle.Quad)
        end
        task.delay(0.19, function()
            if leaving ~= entering then
                leaving.Visible = false
                leaving.Position = UDim2.fromScale(0, 0)
            end
        end)

        setPillState(SocialPill, showSocial, Color3.fromRGB(88, 106, 255))
        setPillState(AIPill, not showSocial, Color3.fromRGB(126, 102, 245))
        setModuleActive(ModuleSync, showSocial, Color3.fromRGB(88, 106, 255))
        setModuleActive(ModuleAI, not showSocial, Color3.fromRGB(126, 102, 245))
        playWorkspaceReveal(entering)
    end

    SocialPill.Base.MouseButton1Click:Connect(function()
        switchWorkspaceMode("Social")
    end)
    AIPill.Base.MouseButton1Click:Connect(function()
        switchWorkspaceMode("AI")
    end)
    makeCardClickable(ModuleSync, function()
        switchWorkspaceMode("Social")
    end)
    makeCardClickable(ModuleAI, function()
        switchWorkspaceMode("AI")
    end)

    applyWorkspaceZ(DragZone, 39)
    applyWorkspaceZ(HeaderPills, 44)
    applyWorkspaceZ(HeaderTag, 43)
    applyWorkspaceZ(RailHero, 43)
    applyWorkspaceZ(ModuleSync, 43)
    applyWorkspaceZ(ModuleAI, 43)
    applyWorkspaceZ(SocialRoot, 43)
    applyWorkspaceZ(AIRoot, 43)

    refreshWorkspaceHeaderTag(getKojoSocial() and getKojoSocial().profile or nil)
    populatePresence()
    switchWorkspaceMode("Social")
    loadRoomHistory("global", true)
    scrollToBottom(AssistantStream)

    task.spawn(function()
        while WorkspaceShell and WorkspaceShell.Panel and WorkspaceShell.Panel.Parent do
            task.wait(8)
            if WorkspaceShell.Panel.Visible then
                refreshWorkspaceHeaderTag(getKojoSocial() and getKojoSocial().profile or nil)
                populatePresence()
                if SocialRoot.Visible then
                    loadRoomHistory(CurrentRoomKey, true)
                end
            end
        end
    end)

    local originalShow = WorkspaceShell.Show
    function WorkspaceShell:Show()
        originalShow(self)
        refreshWorkspaceHeaderTag(getKojoSocial() and getKojoSocial().profile or nil)
        populatePresence()
        if SocialRoot.Visible then
            loadRoomHistory(CurrentRoomKey, true)
        end
        switchWorkspaceMode(SocialRoot.Visible and "Social" or "AI")
    end

    function WorkspaceShell:RefreshHeaderTag()
        refreshWorkspaceHeaderTag(getKojoSocial() and getKojoSocial().profile or nil)
    end

    setKojoEnvValue("__KOJO_WORKSPACE_SHELL", WorkspaceShell)

    return WorkspaceShell
end

OpenWorkspaceButton.Base.MouseButton1Click:Connect(function()
    task.defer(function()
        local ok, shell = pcall(ensureWorkspaceShell)
        if not ok then
            warn(shell)
            notify("Kojo", "Workspace failed to open")
            return
        end

        if shell and shell.Show then
            shell:Show()
        end
    end)
end)

-- Settings
local MenuGroup = Tabs.Settings:AddLeftGroupbox("Menu")
MenuGroup:AddLabel("Toggle Key"):AddKeyPicker("MenuKeybind", {
    Default = "RightControl",
    SyncToggleState = false,
    Mode = "Toggle",
    Text = "Menu keybind",
    NoUI = true,
})
MenuGroup:AddDropdown("NotificationSide", {
    Values = { "Left", "Right" },
    Default = "Right",
    Text = "Notification Side",
    Callback = function(value)
        Library:SetNotifySide(value)
    end,
})
MenuGroup:AddToggle("KeybindFrameOpen", {
    Default = false,
    Text = "Show Keybind Frame",
    Callback = function(value)
        if Library.KeybindFrame then
            Library.KeybindFrame.Visible = value
        end
    end,
})
MenuGroup:AddButton("Enable All", function()
    for _, toggle in pairs(Library.Toggles) do
        if typeof(toggle) == "table" and toggle.SetValue and toggle.Type == "Toggle" then
            toggle:SetValue(true)
        end
    end
    notify("Kojo", "All toggles enabled")
end)
MenuGroup:AddButton("Disable All", function()
    for _, toggle in pairs(Library.Toggles) do
        if typeof(toggle) == "table" and toggle.SetValue and toggle.Type == "Toggle" then
            toggle:SetValue(false)
        end
    end
    notify("Kojo", "All toggles disabled")
end)
MenuGroup:AddButton("Unload Library", function()
    Library:Unload()
end)
MenuGroup:AddButton("Delete Saved Key", function()
    local removed = deleteSavedKey()
    notify("Kojo", removed and "Saved key deleted" or "No saved key file found")
end)

local ThemeGroup = Tabs.Settings:AddLeftGroupbox("Theme")
ThemeGroup:AddDropdown("WindowBackgroundPreset", {
    Text = "Window Background",
    Values = getBackgroundPresetNames(),
    Default = "None",
    Callback = function(value)
        applyBackgroundPreset(value)
    end,
})
ThemeGroup:AddDropdown("NametagBackground", {
    Text = "Nametag Background",
    Values = getNametagBackgroundPresetNames(),
    Default = "None",
    Callback = function(value)
        applyNametagBackground(value)
        if not ApplyingRemoteProfile then
            pushSocialProfile({
                nametag_background = value,
                nametag_asset = NametagBackgroundPresets[value] or "",
            })
        end
    end,
})
ThemeGroup:AddDropdown("HomeAvatarBackdrop", {
    Text = "Avatar Backdrop",
    Values = getAvatarBackdropPresetNames(),
    Default = "Studio Slate",
    Callback = function(value)
        applyAvatarBackdrop(value)
    end,
})
ThemeGroup:AddInput("WindowBackgroundAsset", {
    Text = "Background Asset",
    Default = "",
    Placeholder = "rbxassetid://...",
    ClearTextOnFocus = false,
    Finished = true,
    Callback = function(value)
        local normalized = normalizeBackgroundAsset(value)
        if normalized ~= value and Options.WindowBackgroundAsset then
            Options.WindowBackgroundAsset:SetValue(normalized)
            return
        end

        if normalized == "" then
            if Options.WindowBackgroundPreset then
                Options.WindowBackgroundPreset:SetValue("None")
            end
            Window:ClearBackgroundImage()
            return
        end

        local presetName = registerBackgroundPreset(normalized)
        if Options.WindowBackgroundPreset then
            Options.WindowBackgroundPreset:SetValue(presetName)
        else
            applyBackgroundPreset(presetName)
        end
    end,
})
ThemeGroup:AddInput("NametagAsset", {
    Text = "Nametag Asset",
    Default = "",
    Placeholder = "rbxassetid://...",
    ClearTextOnFocus = false,
    Finished = true,
    Callback = function(value)
        local normalized = normalizeBackgroundAsset(value)
        if normalized ~= value and Options.NametagAsset then
            Options.NametagAsset:SetValue(normalized)
            return
        end

        if normalized == "" then
            if Options.NametagBackground then
                Options.NametagBackground:SetValue("None")
            end
            applyNametagBackground("None")
            if not ApplyingRemoteProfile then
                pushSocialProfile({
                    nametag_asset = "",
                    nametag_background = "None",
                })
            end
            return
        end

        local presetName = registerNametagBackgroundPreset(normalized)
        if Options.NametagBackground then
            Options.NametagBackground:SetValue(presetName)
        end
        if not ApplyingRemoteProfile then
            pushSocialProfile({
                nametag_asset = normalized,
                nametag_background = presetName,
            })
        end
    end,
})
ThemeGroup:AddSlider("WindowBackgroundFade", {
    Text = "Background Fade",
    Default = 24,
    Min = 0,
    Max = 100,
    Rounding = 0,
    Suffix = "%",
    Callback = function(value)
        Window:SetBackgroundTransparency(value / 100)
    end,
})
ThemeGroup:AddSlider("NametagTransparency", {
    Text = "Nametag Transparency",
    Default = 28,
    Min = 0,
    Max = 100,
    Rounding = 0,
    Suffix = "%",
    Callback = function(value)
        if Window.SetFooterBackgroundTransparency then
            Window:SetFooterBackgroundTransparency(value / 100)
        end
        if not ApplyingRemoteProfile then
            pushSocialProfile({
                nametag_transparency = value,
            })
        end
    end,
})
ThemeGroup:AddSlider("UITransparency", {
    Text = "UI Transparency",
    Default = 0,
    Min = 0,
    Max = 200,
    Rounding = 0,
    Suffix = "%",
    Callback = function(value)
        Window:SetUiTransparency(value / 100)
    end,
})
ThemeGroup:AddSlider("SettingsWindowScale", {
    Text = "Window Scale",
    Default = 100,
    Min = 75,
    Max = 125,
    Rounding = 0,
    Suffix = "%",
    Callback = function(value)
        Library:SetDPIScale(value)
    end,
})
ThemeGroup:AddInput("AvatarBackdropAsset", {
    Text = "Backdrop Asset",
    Default = "",
    Placeholder = "rbxassetid://...",
    ClearTextOnFocus = false,
    Finished = true,
    Callback = function(value)
        local normalized = normalizeBackgroundAsset(value)
        if normalized ~= value and Options.AvatarBackdropAsset then
            Options.AvatarBackdropAsset:SetValue(normalized)
            return
        end

        if normalized == "" then
            return
        end

        local presetName = registerAvatarBackdropPreset(normalized)
        if presetName and Options.HomeAvatarBackdrop then
            Options.HomeAvatarBackdrop:SetValue(presetName)
        end
    end,
})
ThemeGroup:AddInput("AvatarBackdropLabel", {
    Text = "Backdrop Rename",
    Default = "",
    Placeholder = "My favorite backdrop",
    ClearTextOnFocus = false,
    Finished = true,
    Callback = function(value)
        local currentName = Options.HomeAvatarBackdrop and Options.HomeAvatarBackdrop.Value
        if not currentName or value == "" then
            return
        end

        local renamed = renameAvatarBackdropPreset(currentName, value)
        if renamed then
            notify("Kojo", ("Backdrop renamed to %s"):format(renamed))
        end
    end,
})
ThemeGroup:AddSlider("AvatarBackdropFade", {
    Text = "Backdrop Transparency",
    Default = 0,
    Min = 0,
    Max = 100,
    Rounding = 0,
    Suffix = "%",
    Callback = function()
        if Options.HomeAvatarBackdrop then
            applyAvatarBackdrop(Options.HomeAvatarBackdrop.Value)
        end
    end,
})
ThemeGroup:AddDropdown("InteractionSpeed", {
    Text = "Animation Speed",
    Values = { "80%", "100%", "120%", "140%", "160%" },
    Default = "100%",
    Callback = function(value)
        local stripped = value:gsub("%%", "")
        local speed = tonumber(stripped) or 100
        Library:SetInteractionSpeed(speed)
    end,
})

local ProfileGroup = Tabs.Settings:AddRightGroupbox("Profile")
ProfileStatusLabel = ProfileGroup:AddLabel({
    Text = getKojoSocial() and "Connected" or "Local only",
})
ProfileGroup:AddInput("ProfileDisplayName", {
    Text = "Display Name",
    Default = getKojoUserName(),
    Placeholder = "Kojo display name",
    ClearTextOnFocus = false,
    Finished = true,
    Callback = function(value)
        if ApplyingRemoteProfile then
            return
        end

        local trimmed = tostring(value or ""):match("^%s*(.-)%s*$")
        if trimmed == "" then
            notify("Kojo", "Display name cannot be empty")
            return
        end

        setKojoEnvValue("KOJO_ProfileName", trimmed)
        updateHeadNametag({
            display_name = trimmed,
        })

        pushSocialProfile({
            display_name = trimmed,
        }, "Profile name updated")
    end,
})
ProfileGroup:AddInput("ProfileScriptAvatar", {
    Text = "Script Avatar",
    Default = tostring(getKojoValue("KOJO_ProfileAvatar", "")),
    Placeholder = "123456789 or rbxassetid://...",
    ClearTextOnFocus = false,
    Finished = true,
    Callback = function(value)
        if ApplyingRemoteProfile then
            return
        end

        local normalized = normalizeImageAsset(tostring(value or ""))
        if normalized ~= tostring(value or "") and Options.ProfileScriptAvatar then
            Options.ProfileScriptAvatar:SetValue(normalized)
        end

        setKojoEnvValue("KOJO_ProfileAvatar", normalized)
        updateHeadNametag({
            display_name = getCurrentProfileDisplayName(getKojoSocial() and getKojoSocial().profile or nil),
            script_avatar_url = normalized,
        })

        pushSocialProfile({
            script_avatar_url = normalized,
        }, "Script avatar updated")
    end,
})
ProfileGroup:AddToggle("ShowHeadNametag", {
    Text = "Show Head Nametag",
    Default = false,
    Callback = function(value)
        if SafeModeEnabled and value then
            notify("Kojo", "Turn off Safe Mode before enabling the head nametag")
            if Toggles.ShowHeadNametag then
                Toggles.ShowHeadNametag:SetValue(false)
            end
            return
        end
        updateHeadNametag(getKojoSocial() and getKojoSocial().profile or nil)
    end,
})
ProfileGroup:AddToggle("ProfileVisible", {
    Text = "Visible in Presence",
    Default = getKojoValue("KOJO_ProfileVisible", true) ~= false,
    Callback = function(value)
        if ApplyingRemoteProfile then
            return
        end

        pushSocialProfile({
            visible = value,
        }, value and "Presence visible" or "Presence hidden")
    end,
})
local ProfileButtons = ProfileGroup:AddButton("Refresh Profile", function()
    refreshSocialProfile()
end)
ProfileButtons:AddButton("Copy Profile ID", function()
    copyText("Profile id", tostring(getKojoValue("KOJO_ProfileId", "Unavailable")))
end)

ThemeManager:SetLibrary(Library)
SaveManager:SetLibrary(Library)
SaveManager:IgnoreThemeSettings()
SaveManager:SetIgnoreIndexes({ "MenuKeybind", "SaveManager_ImportPayload" })
SaveManager:SetGameFolder("KojoExample", "KojoHub")
ThemeManager:SetFolder(SaveManager.Folder)
ThemeManager:ApplyToGroupbox(ThemeGroup)
SaveManager:BuildConfigSection(Tabs.Settings)

Library.ToggleKeybind = Options.MenuKeybind
Window:SetBackgroundTransparency(0.24)
SaveManager:LoadAutoloadConfig()

updateFooterIdentity(getKojoSocial() and getKojoSocial().profile or nil)
if Window.SetFooterPalette then
    Window:SetFooterPalette(HomeTier)
end
refreshLicenseLabels()
Options.InteractionSpeed:SetValue("100%")
Options.SettingsWindowScale:SetValue(100)
local registeredAvatarBackdropName = nil
if Options.AvatarBackdropAsset and Options.AvatarBackdropAsset.Value ~= "" then
    registeredAvatarBackdropName = registerAvatarBackdropPreset(Options.AvatarBackdropAsset.Value)
end
if Options.AvatarBackdropLabel and Options.AvatarBackdropLabel.Value ~= "" then
    local currentBackdropName = Options.HomeAvatarBackdrop and Options.HomeAvatarBackdrop.Value or registeredAvatarBackdropName
    if currentBackdropName then
        local renamed = renameAvatarBackdropPreset(currentBackdropName, Options.AvatarBackdropLabel.Value)
        if renamed then
            registeredAvatarBackdropName = renamed
        end
    end
end
if Options.HomeAvatarBackdrop and Options.HomeAvatarBackdrop.Value then
    applyAvatarBackdrop(Options.HomeAvatarBackdrop.Value)
end
applySafeModeState(SafeModeEnabled, { force = false })
if Options.NametagAsset and Options.NametagAsset.Value ~= "" then
    local presetName = registerNametagBackgroundPreset(Options.NametagAsset.Value)
    if Options.NametagBackground then
        Options.NametagBackground:SetValue(presetName)
    end
elseif Options.NametagBackground and Options.NametagBackground.Value then
    applyNametagBackground(Options.NametagBackground.Value)
end
if Options.NametagTransparency and Window.SetFooterBackgroundTransparency then
    Window:SetFooterBackgroundTransparency(Options.NametagTransparency.Value / 100)
end
if Options.WindowBackgroundAsset and Options.WindowBackgroundAsset.Value ~= "" then
    local normalizedAsset = normalizeBackgroundAsset(Options.WindowBackgroundAsset.Value)
    local presetName = registerBackgroundPreset(normalizedAsset)
    Options.WindowBackgroundPreset:SetValue(presetName)
end

applySocialProfile(getKojoSocial() and getKojoSocial().profile or nil)
task.spawn(function()
    refreshSocialProfile(true)
end)
