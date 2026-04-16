local cloneref = (cloneref or clonereference or function(instance: any)
    return instance
end)
local CoreGui: CoreGui = cloneref(game:GetService("CoreGui"))
local Players: Players = cloneref(game:GetService("Players"))
local RunService: RunService = cloneref(game:GetService("RunService"))
local SoundService: SoundService = cloneref(game:GetService("SoundService"))
local UserInputService: UserInputService = cloneref(game:GetService("UserInputService"))
local TextService: TextService = cloneref(game:GetService("TextService"))
local MarketplaceService: MarketplaceService = cloneref(game:GetService("MarketplaceService"))
local Teams: Teams = cloneref(game:GetService("Teams"))
local TweenService: TweenService = cloneref(game:GetService("TweenService"))

local getgenv = getgenv or function()
    return shared
end
local setclipboard = setclipboard or nil
local protectgui = protectgui or (syn and syn.protect_gui) or function() end
local gethui = gethui or function()
    return CoreGui
end

local LocalPlayer = Players.LocalPlayer or Players.PlayerAdded:Wait()
local Mouse = cloneref(LocalPlayer:GetMouse())

local Labels = {}
local Buttons = {}
local Toggles = {}
local Options = {}
local Tooltips = {}
local AttachKojoCoreToWindow

local BaseURL = "https://raw.githubusercontent.com/deividcomsono/Obsidian/refs/heads/main/"
local CustomImageManager = {}
local CustomImageManagerAssets = {
    TransparencyTexture = {
        RobloxId = 139785960036434,
        Path = "Obsidian/assets/TransparencyTexture.png",
        URL = BaseURL .. "assets/TransparencyTexture.png",

        Id = nil,
    },

    SaturationMap = {
        RobloxId = 4155801252,
        Path = "Obsidian/assets/SaturationMap.png",
        URL = BaseURL .. "assets/SaturationMap.png",

        Id = nil,
    },
}
do
    local function RecursiveCreatePath(Path: string, IsFile: boolean?)
        if not isfolder or not makefolder then
            return
        end

        local Segments = Path:split("/")
        local TraversedPath = ""

        if IsFile then
            table.remove(Segments, #Segments)
        end

        for _, Segment in ipairs(Segments) do
            if not isfolder(TraversedPath .. Segment) then
                makefolder(TraversedPath .. Segment)
            end

            TraversedPath = TraversedPath .. Segment .. "/"
        end

        return TraversedPath
    end

    function CustomImageManager.AddAsset(
        AssetName: string,
        RobloxAssetId: number,
        URL: string,
        ForceRedownload: boolean?
    )
        if CustomImageManagerAssets[AssetName] ~= nil then
            error(string.format("Asset %q already exists", AssetName))
        end

        assert(typeof(RobloxAssetId) == "number", "RobloxAssetId must be a number")

        CustomImageManagerAssets[AssetName] = {
            RobloxId = RobloxAssetId,
            Path = string.format("Obsidian/custom_assets/%s", AssetName),
            URL = URL,

            Id = nil,
        }

        CustomImageManager.DownloadAsset(AssetName, ForceRedownload)
    end

    function CustomImageManager.GetAsset(AssetName: string)
        if not CustomImageManagerAssets[AssetName] then
            return nil
        end

        local AssetData = CustomImageManagerAssets[AssetName]
        if AssetData.Id then
            return AssetData.Id
        end

        local AssetID = string.format("rbxassetid://%s", AssetData.RobloxId)

        if getcustomasset then
            local Success, NewID = pcall(getcustomasset, AssetData.Path)

            if Success and NewID then
                AssetID = NewID
            end
        end

        AssetData.Id = AssetID
        return AssetID
    end

    function CustomImageManager.DownloadAsset(AssetName: string, ForceRedownload: boolean?)
        if not getcustomasset or not writefile or not isfile then
            return false, "missing functions"
        end

        local AssetData = CustomImageManagerAssets[AssetName]

        RecursiveCreatePath(AssetData.Path, true)

        if ForceRedownload ~= true and isfile(AssetData.Path) then
            return true, nil
        end

        local success, errorMessage = pcall(function()
            writefile(AssetData.Path, game:HttpGet(AssetData.URL))
        end)

        return success, errorMessage
    end

    for AssetName, _ in CustomImageManagerAssets do
        CustomImageManager.DownloadAsset(AssetName)
    end
end

local LEGACY_TEXT_FONT = Enum.Font.Gotham
local LEGACY_TEXT_FONT_BOLD = Enum.Font.GothamBold
local SAFE_FONT_FAMILY = Font.fromEnum(LEGACY_TEXT_FONT).Family
local DEFAULT_LIBRARY_FONT = Font.fromEnum(LEGACY_TEXT_FONT)

local function GetLegacyFontEnumFromFont(FontValue, WeightOverride: Enum.FontWeight?)
    if typeof(FontValue) == "EnumItem" then
        return FontValue
    end

    local Weight = WeightOverride
    if typeof(FontValue) == "Font" then
        Weight = Weight or FontValue.Weight
    end

    local WeightValue = (Weight or Enum.FontWeight.Medium).Value
    if WeightValue >= Enum.FontWeight.Bold.Value then
        return LEGACY_TEXT_FONT_BOLD
    end

    return LEGACY_TEXT_FONT
end

local function NormalizeFontValue(FontValue, Weight: Enum.FontWeight?)
    if typeof(FontValue) == "EnumItem" then
        FontValue = Font.fromEnum(FontValue)
    end

    if typeof(FontValue) ~= "Font" then
        return Font.fromEnum(GetLegacyFontEnumFromFont(FontValue, Weight))
    end

    return Font.fromEnum(GetLegacyFontEnumFromFont(FontValue, Weight or FontValue.Weight))
end

local Library = {
    LocalPlayer = LocalPlayer,
    DevicePlatform = nil,
    IsMobile = false,
    IsRobloxFocused = true,

    ScreenGui = nil,

    SearchText = "",
    Searching = false,
    GlobalSearch = false,
    LastSearchTab = nil,

    ActiveTab = nil,
    Tabs = {},
    TabButtons = {},
    DependencyBoxes = {},

    KeybindFrame = nil,
    KeybindContainer = nil,
    KeybindToggles = {},

    Notifications = {},
    Dialogues = {},
    ActiveDialog = nil,

    ToggleKeybind = Enum.KeyCode.RightControl,
    TweenInfo = TweenInfo.new(0.12, Enum.EasingStyle.Quart, Enum.EasingDirection.Out),
    NotifyTweenInfo = TweenInfo.new(0.25, Enum.EasingStyle.Quad, Enum.EasingDirection.Out),

    Toggled = false,
    Unloaded = false,

    Labels = Labels,
    Buttons = Buttons,
    Toggles = Toggles,
    Options = Options,

    NotifySide = "Right",
    ShowCustomCursor = true,
    ForceCheckbox = false,
    ShowToggleFrameInKeybinds = true,
    UseLegacyTextRendering = false,
    NotifyOnError = false,

    CantDragForced = false,

    Signals = {},
    UnloadSignals = {},

    OriginalMinSize = Vector2.new(480, 360),
    MinSize = Vector2.new(480, 360),
    DPIScale = 1,
    CornerRadius = 12,

    IsLightTheme = false,
    Scheme = {
        BackgroundColor = Color3.fromRGB(11, 12, 16),
        MainColor = Color3.fromRGB(15, 16, 22),
        AccentColor = Color3.fromRGB(235, 185, 210),
        OutlineColor = Color3.fromRGB(34, 37, 46),
        FontColor = Color3.fromRGB(244, 245, 248),
        Font = DEFAULT_LIBRARY_FONT,

        RedColor = Color3.fromRGB(255, 50, 50),
        DarkColor = Color3.new(0, 0, 0),
        WhiteColor = Color3.new(1, 1, 1),
    },

    Registry = {},
    Scales = {},

    ImageManager = CustomImageManager,
}

if RunService:IsStudio() then
    if UserInputService.TouchEnabled and not UserInputService.MouseEnabled then
        Library.IsMobile = true
        Library.OriginalMinSize = Vector2.new(480, 240)
    else
        Library.IsMobile = false
        Library.OriginalMinSize = Vector2.new(480, 360)
    end
else
    pcall(function()
        Library.DevicePlatform = UserInputService:GetPlatform()
    end)
    Library.IsMobile = (Library.DevicePlatform == Enum.Platform.Android or Library.DevicePlatform == Enum.Platform.IOS)
    Library.OriginalMinSize = Library.IsMobile and Vector2.new(480, 240) or Vector2.new(480, 360)
end

local Templates = {
    --// UI \\-
    Frame = {
        BorderSizePixel = 0,
    },
    ImageLabel = {
        BackgroundTransparency = 1,
        BorderSizePixel = 0,
    },
    ImageButton = {
        AutoButtonColor = false,
        BorderSizePixel = 0,
    },
    ScrollingFrame = {
        BorderSizePixel = 0,
    },
    TextLabel = {
        BorderSizePixel = 0,
        FontFace = "Font",
        RichText = true,
        LineHeight = 1,
        TextColor3 = "FontColor",
        TextYAlignment = Enum.TextYAlignment.Center,
    },
    TextButton = {
        AutoButtonColor = false,
        BorderSizePixel = 0,
        FontFace = "Font",
        RichText = true,
        LineHeight = 1,
        TextColor3 = "FontColor",
        TextYAlignment = Enum.TextYAlignment.Center,
    },
    TextBox = {
        BorderSizePixel = 0,
        FontFace = "Font",
        LineHeight = 1,
        PlaceholderColor3 = function()
            local H, S, V = Library.Scheme.FontColor:ToHSV()
            return Color3.fromHSV(H, S, V / 2)
        end,
        Text = "",
        TextColor3 = "FontColor",
        TextYAlignment = Enum.TextYAlignment.Center,
    },
    UIListLayout = {
        SortOrder = Enum.SortOrder.LayoutOrder,
    },
    UIStroke = {
        ApplyStrokeMode = Enum.ApplyStrokeMode.Border,
    },

    --// Library \\--
    Window = {
        Title = "No Title",
        Footer = "No Footer",
        Icon = "kojo-logo",
        Position = UDim2.fromOffset(6, 6),
        Size = UDim2.fromOffset(760, 560),
        IconSize = UDim2.fromOffset(30, 30),
        AutoShow = true,
        Center = true,
        Resizable = true,
        SearchbarSize = UDim2.fromScale(1, 1),
        GlobalSearch = false,
        CornerRadius = 14,
        NotifySide = "Right",
        ShowCustomCursor = false,
        DisableSearch = true,
        Font = DEFAULT_LIBRARY_FONT,
        ToggleKeybind = Enum.KeyCode.RightControl,
        AutoSelectFirstTab = false,
        MobileButtonsSide = "Left",
        UnlockMouseWhileOpen = true,
        DPIScale = 100,
        MobileAutoScale = true,
        BackgroundImage = "",
        BackgroundImageTransparency = 0.24,
        UITransparency = 0,
        FooterAvatar = "",
        FooterBackgroundImage = "",
        FooterBackgroundTransparency = 0.28,
        EnableKojoCore = false,
        KojoDashboardTabName = "Home",
        KojoSettingsTabName = "Settings",
        KojoAutoFooter = true,
        KojoSafeMode = nil,

        EnableSidebarResize = false,
        EnableCompacting = true,
        DisableCompactingSnap = false,
        SidebarCompacted = false,
        MinContainerWidth = 256,

        --// Snapping \\--
        MinSidebarWidth = 128,
        SidebarCompactWidth = 48,
        SidebarCollapseThreshold = 0.5,

        --// Dragging \\--
        CompactWidthActivation = 128,
    },
    Dialog = {
        Title = "Dialog",
        Description = "Description",
        AutoDismiss = true,
        OutsideClickDismiss = true,
        FooterButtons = {}
    },
    Toggle = {
        Text = "Toggle",
        Default = false,

        Callback = function() end,
        Changed = function() end,

        Risky = false,
        Disabled = false,
        Visible = true,
    },
    Input = {
        Text = "Input",
        Default = "",
        Finished = false,
        Numeric = false,
        MultiLine = false,
        Height = nil,
        ClearTextOnFocus = true,
        Placeholder = "",
        AllowEmpty = true,
        EmptyReset = "---",
        Compact = false,
        ControlWidth = nil,

        Callback = function() end,
        Changed = function() end,

        Disabled = false,
        Visible = true,
    },
    Slider = {
        Text = "Slider",
        Default = 0,
        Min = 0,
        Max = 100,
        Rounding = 0,

        Prefix = "",
        Suffix = "",

        Callback = function() end,
        Changed = function() end,

        Disabled = false,
        Visible = true,
    },
    Dropdown = {
        Values = {},
        DisabledValues = {},
        Multi = false,
        Compact = false,
        ControlWidth = nil,
        MaxVisibleDropdownItems = 8,

        Callback = function() end,
        Changed = function() end,

        Disabled = false,
        Visible = true,
    },
    Viewport = {
        Object = nil,
        Camera = nil,
        Clone = true,
        AutoFocus = true,
        Interactive = false,
        AutoRotate = false,
        RotateSpeed = 18,
        FocusYOffset = 0.28,
        CameraDistanceMultiplier = 2.15,
        BackgroundColor = Color3.fromRGB(17, 18, 24),
        BackgroundTransparency = 0,
        BackgroundImage = "",
        BackgroundImageColor = Color3.new(1, 1, 1),
        BackgroundImageTransparency = 1,
        BackgroundGradient = false,
        BackgroundGradientRotation = 0,
        Height = 200,
        Visible = true,
    },
    Image = {
        Image = "",
        Transparency = 0,
        BackgroundTransparency = 0,
        Color = Color3.new(1, 1, 1),
        RectOffset = Vector2.zero,
        RectSize = Vector2.zero,
        ScaleType = Enum.ScaleType.Fit,
        Height = 200,
        Visible = true,
    },
    Video = {
        Video = "",
        Looped = false,
        Playing = false,
        Volume = 1,
        Height = 200,
        Visible = true,
    },
    UIPassthrough = {
        Instance = nil,
        Height = 24,
        Visible = true,
    },

    --// Addons \\-
    KeyPicker = {
        Text = "KeyPicker",
        Default = "None",
        DefaultModifiers = {},
        Mode = "Toggle",
        Modes = { "Always", "Toggle", "Hold" },
        SyncToggleState = false,

        Callback = function() end,
        ChangedCallback = function() end,
        Changed = function() end,
        Clicked = function() end,
    },
    ColorPicker = {
        Default = Color3.new(1, 1, 1),

        Callback = function() end,
        Changed = function() end,
    },
}

local Places = {
    Bottom = { 0, 1 },
    Right = { 1, 0 },
}
local Sizes = {
    Left = { 0.5, 1 },
    Right = { 0.5, 1 },
}

--// Scheme Functions \\--
local SchemeReplaceAlias = {
    RedColor = "Red",
    WhiteColor = "White",
    DarkColor = "Dark"
}

local SchemeAlias = {
    Red = "RedColor",
    White = "WhiteColor",
    Dark = "DarkColor"
}

local function GetSchemeValue(Index)
    if not Index then
        return nil
    end

    local ReplaceAliasIndex = SchemeReplaceAlias[Index]
    if ReplaceAliasIndex and Library.Scheme[ReplaceAliasIndex] ~= nil then
        Library.Scheme[Index] = Library.Scheme[ReplaceAliasIndex]
        Library.Scheme[ReplaceAliasIndex] = nil

        return Library.Scheme[Index]
    end

    local AliasIndex = SchemeAlias[Index]
    if AliasIndex and Library.Scheme[AliasIndex] ~= nil then
        warn(string.format("Scheme Value %q is deprecated, please use %q instead.", Index, AliasIndex))
        return Library.Scheme[AliasIndex]
    end

    return Library.Scheme[Index]
end

--// Basic Functions \\--
local function WaitForEvent(Event, Timeout, Condition)
    local Bindable = Instance.new("BindableEvent")
    local Connection = Event:Once(function(...)
        if not Condition or typeof(Condition) == "function" and Condition(...) then
            Bindable:Fire(true)
        else
            Bindable:Fire(false)
        end
    end)
    task.delay(Timeout, function()
        Connection:Disconnect()
        Bindable:Fire(false)
    end)

    local Result = Bindable.Event:Wait()
    Bindable:Destroy()

    return Result
end

local function IsMouseInput(Input: InputObject, IncludeM2: boolean?)
    return Input.UserInputType == Enum.UserInputType.MouseButton1
        or (IncludeM2 == true and Input.UserInputType == Enum.UserInputType.MouseButton2)
        or Input.UserInputType == Enum.UserInputType.Touch
end
local function IsClickInput(Input: InputObject, IncludeM2: boolean?)
    return IsMouseInput(Input, IncludeM2)
        and Input.UserInputState == Enum.UserInputState.Begin
        and Library.IsRobloxFocused
end
local function IsHoverInput(Input: InputObject)
    return (Input.UserInputType == Enum.UserInputType.MouseMovement or Input.UserInputType == Enum.UserInputType.Touch)
        and Input.UserInputState == Enum.UserInputState.Change
end
local function IsDragInput(Input: InputObject, IncludeM2: boolean?)
    return IsMouseInput(Input, IncludeM2)
        and (Input.UserInputState == Enum.UserInputState.Begin or Input.UserInputState == Enum.UserInputState.Change)
        and Library.IsRobloxFocused
end

local function GetTableSize(Table: { [any]: any })
    local Size = 0

    for _, _ in Table do
        Size += 1
    end

    return Size
end
local function StopTween(Tween: TweenBase)
    if not (Tween and Tween.PlaybackState == Enum.PlaybackState.Playing) then
        return
    end

    Tween:Cancel()
end
local function Trim(Text: string)
    return Text:match("^%s*(.-)%s*$")
end
local function Round(Value, Rounding)
    assert(Rounding >= 0, "Invalid rounding number.")

    if Rounding == 0 then
        return math.floor(Value)
    end

    return tonumber(string.format("%." .. Rounding .. "f", Value))
end

local function GetPlayers(ExcludeLocalPlayer: boolean?)
    local PlayerList = Players:GetPlayers()

    if ExcludeLocalPlayer then
        local Idx = table.find(PlayerList, LocalPlayer)
        if Idx then
            table.remove(PlayerList, Idx)
        end
    end

    table.sort(PlayerList, function(Player1, Player2)
        return Player1.Name:lower() < Player2.Name:lower()
    end)

    return PlayerList
end
local function GetTeams()
    local TeamList = Teams:GetTeams()

    table.sort(TeamList, function(Team1, Team2)
        return Team1.Name:lower() < Team2.Name:lower()
    end)

    return TeamList
end

function Library:UpdateDependencyBoxes()
    for _, Depbox in Library.DependencyBoxes do
        Depbox:Update(true)
    end

    if Library.Searching then
        Library:UpdateSearch(Library.SearchText)
    end
end

local function CheckDepbox(Box, Search)
    local VisibleElements = 0

    for _, ElementInfo in Box.Elements do
        if ElementInfo.Type == "Divider" then
            ElementInfo.Holder.Visible = false
            continue
        elseif ElementInfo.SubButton then
            --// Check if any of the Buttons Name matches with Search
            local Visible = false

            --// Check if Search matches Element's Name and if Element is Visible
            if ElementInfo.Text:lower():match(Search) and ElementInfo.Visible then
                Visible = true
            else
                ElementInfo.Base.Visible = false
            end
            if ElementInfo.SubButton.Text:lower():match(Search) and ElementInfo.SubButton.Visible then
                Visible = true
            else
                ElementInfo.SubButton.Base.Visible = false
            end
            ElementInfo.Holder.Visible = Visible
            if Visible then
                VisibleElements += 1
            end

            continue
        end

        --// Check if Search matches Element's Name and if Element is Visible
        if ElementInfo.Text and ElementInfo.Text:lower():match(Search) and ElementInfo.Visible then
            ElementInfo.Holder.Visible = true
            VisibleElements += 1
        else
            ElementInfo.Holder.Visible = false
        end
    end

    for _, Depbox in Box.DependencyBoxes do
        if not Depbox.Visible then
            continue
        end

        VisibleElements += CheckDepbox(Depbox, Search)
    end

    Box.Holder.Visible = VisibleElements > 0
    return VisibleElements
end
local function RestoreDepbox(Box)
    for _, ElementInfo in Box.Elements do
        ElementInfo.Holder.Visible = typeof(ElementInfo.Visible) == "boolean" and ElementInfo.Visible or true

        if ElementInfo.SubButton then
            ElementInfo.Base.Visible = ElementInfo.Visible
            ElementInfo.SubButton.Base.Visible = ElementInfo.SubButton.Visible
        end
    end

    Box:Resize()
    Box.Holder.Visible = true

    for _, Depbox in Box.DependencyBoxes do
        if not Depbox.Visible then
            continue
        end

        RestoreDepbox(Depbox)
    end
end

local function ApplySearchToTab(Tab, Search)
    if not Tab then
        return
    end

    local HasVisible = false

    --// Loop through Groupboxes to get Elements Info
    for _, Groupbox in Tab.Groupboxes do
        local VisibleElements = 0

        for _, ElementInfo in Groupbox.Elements do
            if ElementInfo.Type == "Divider" then
                ElementInfo.Holder.Visible = false
                continue
            elseif ElementInfo.SubButton then
                --// Check if any of the Buttons Name matches with Search
                local Visible = false

                --// Check if Search matches Element's Name and if Element is Visible
                if ElementInfo.Text:lower():match(Search) and ElementInfo.Visible then
                    Visible = true
                else
                    ElementInfo.Base.Visible = false
                end
                if ElementInfo.SubButton.Text:lower():match(Search) and ElementInfo.SubButton.Visible then
                    Visible = true
                else
                    ElementInfo.SubButton.Base.Visible = false
                end
                ElementInfo.Holder.Visible = Visible
                if Visible then
                    VisibleElements += 1
                end

                continue
            end

            --// Check if Search matches Element's Name and if Element is Visible
            if ElementInfo.Text and ElementInfo.Text:lower():match(Search) and ElementInfo.Visible then
                ElementInfo.Holder.Visible = true
                VisibleElements += 1
            else
                ElementInfo.Holder.Visible = false
            end
        end

        for _, Depbox in Groupbox.DependencyBoxes do
            if not Depbox.Visible then
                continue
            end

            VisibleElements += CheckDepbox(Depbox, Search)
        end

        --// Update Groupbox Size and Visibility if found any element
        if VisibleElements > 0 then
            Groupbox:Resize()
            HasVisible = true
        end
        Groupbox.BoxHolder.Visible = VisibleElements > 0
    end

    for _, Tabbox in Tab.Tabboxes do
        local VisibleTabs = 0
        local VisibleElements = {}

        for _, SubTab in Tabbox.Tabs do
            VisibleElements[SubTab] = 0

            for _, ElementInfo in SubTab.Elements do
                if ElementInfo.Type == "Divider" then
                    ElementInfo.Holder.Visible = false
                    continue
                elseif ElementInfo.SubButton then
                    --// Check if any of the Buttons Name matches with Search
                    local Visible = false

                    --// Check if Search matches Element's Name and if Element is Visible
                    if ElementInfo.Text:lower():match(Search) and ElementInfo.Visible then
                        Visible = true
                    else
                        ElementInfo.Base.Visible = false
                    end
                    if ElementInfo.SubButton.Text:lower():match(Search) and ElementInfo.SubButton.Visible then
                        Visible = true
                    else
                        ElementInfo.SubButton.Base.Visible = false
                    end
                    ElementInfo.Holder.Visible = Visible
                    if Visible then
                        VisibleElements[SubTab] += 1
                    end

                    continue
                end

                --// Check if Search matches Element's Name and if Element is Visible
                if ElementInfo.Text and ElementInfo.Text:lower():match(Search) and ElementInfo.Visible then
                    ElementInfo.Holder.Visible = true
                    VisibleElements[SubTab] += 1
                else
                    ElementInfo.Holder.Visible = false
                end
            end

            for _, Depbox in SubTab.DependencyBoxes do
                if not Depbox.Visible then
                    continue
                end

                VisibleElements[SubTab] += CheckDepbox(Depbox, Search)
            end
        end

        for SubTab, Visible in VisibleElements do
            SubTab.ButtonHolder.Visible = Visible > 0
            if Visible > 0 then
                VisibleTabs += 1
                HasVisible = true

                if Tabbox.ActiveTab == SubTab then
                    SubTab:Resize()
                elseif Tabbox.ActiveTab and VisibleElements[Tabbox.ActiveTab] == 0 then
                    SubTab:Show()
                end
            end
        end

        --// Update Tabbox Visibility if any visible
        Tabbox.BoxHolder.Visible = VisibleTabs > 0
    end

    return HasVisible
end
local function ResetTab(Tab)
    if not Tab then
        return
    end

    for _, Groupbox in Tab.Groupboxes do
        for _, ElementInfo in Groupbox.Elements do
            ElementInfo.Holder.Visible = typeof(ElementInfo.Visible) == "boolean" and ElementInfo.Visible or true

            if ElementInfo.SubButton then
                ElementInfo.Base.Visible = ElementInfo.Visible
                ElementInfo.SubButton.Base.Visible = ElementInfo.SubButton.Visible
            end
        end

        for _, Depbox in Groupbox.DependencyBoxes do
            if not Depbox.Visible then
                continue
            end

            RestoreDepbox(Depbox)
        end

        Groupbox:Resize()
        Groupbox.BoxHolder.Visible = true
    end

    for _, Tabbox in Tab.Tabboxes do
        for _, SubTab in Tabbox.Tabs do
            for _, ElementInfo in SubTab.Elements do
                ElementInfo.Holder.Visible = typeof(ElementInfo.Visible) == "boolean" and ElementInfo.Visible or true

                if ElementInfo.SubButton then
                    ElementInfo.Base.Visible = ElementInfo.Visible
                    ElementInfo.SubButton.Base.Visible = ElementInfo.SubButton.Visible
                end
            end

            for _, Depbox in SubTab.DependencyBoxes do
                if not Depbox.Visible then
                    continue
                end

                RestoreDepbox(Depbox)
            end

            SubTab.ButtonHolder.Visible = true
        end

        if Tabbox.ActiveTab then
            Tabbox.ActiveTab:Resize()
        end
        Tabbox.BoxHolder.Visible = true
    end
end

function Library:UpdateSearch(SearchText)
    Library.SearchText = SearchText

    local TabsToReset = {}

    if Library.GlobalSearch then
        for _, Tab in Library.Tabs do
            if typeof(Tab) == "table" and not Tab.IsKeyTab then
                table.insert(TabsToReset, Tab)
            end
        end
    elseif Library.LastSearchTab and typeof(Library.LastSearchTab) == "table" then
        table.insert(TabsToReset, Library.LastSearchTab)
    end

    for _, Tab in ipairs(TabsToReset) do
        ResetTab(Tab)
    end

    local Search = SearchText:lower()
    if Trim(Search) == "" then
        Library.Searching = false
        Library.LastSearchTab = nil
        return
    end
    if not Library.GlobalSearch and Library.ActiveTab and Library.ActiveTab.IsKeyTab then
        Library.Searching = false
        Library.LastSearchTab = nil
        return
    end

    Library.Searching = true

    local TabsToSearch = {}

    if Library.GlobalSearch then
        TabsToSearch = TabsToReset
        if #TabsToSearch == 0 then
            for _, Tab in Library.Tabs do
                if typeof(Tab) == "table" and not Tab.IsKeyTab then
                    table.insert(TabsToSearch, Tab)
                end
            end
        end
    elseif Library.ActiveTab then
        table.insert(TabsToSearch, Library.ActiveTab)
    end

    local FirstVisibleTab = nil
    local ActiveHasVisible = false

    for _, Tab in ipairs(TabsToSearch) do
        local HasVisible = ApplySearchToTab(Tab, Search)
        if HasVisible then
            if not FirstVisibleTab then
                FirstVisibleTab = Tab
            end
            if Tab == Library.ActiveTab then
                ActiveHasVisible = true
            end
        end
    end

    if Library.GlobalSearch then
        if ActiveHasVisible and Library.ActiveTab then
            Library.ActiveTab:RefreshSides()
        elseif FirstVisibleTab then
            local SearchMarker = SearchText
            task.defer(function()
                if Library.SearchText ~= SearchMarker then
                    return
                end

                if Library.ActiveTab ~= FirstVisibleTab then
                    FirstVisibleTab:Show()
                end
            end)
        end
        Library.LastSearchTab = nil
    else
        Library.LastSearchTab = Library.ActiveTab
    end
end

function Library:AddToRegistry(Instance, Properties)
    Library.Registry[Instance] = Properties
end

function Library:RemoveFromRegistry(Instance)
    Library.Registry[Instance] = nil
end

function Library:UpdateColorsUsingRegistry()
    for Instance, Properties in Library.Registry do
        for Property, Index in Properties do
            local SchemeValue = GetSchemeValue(Index)

            if SchemeValue or typeof(Index) == "function" then
                Instance[Property] = SchemeValue or Index()
            end
        end
    end
end

function Library:SetDPIScale(DPIScale: number)
    Library.DPIScale = DPIScale / 100
    Library.MinSize = Library.OriginalMinSize * Library.DPIScale

    for _, UIScale in Library.Scales do
        UIScale.Scale = Library.DPIScale
    end

    for _, Option in Options do
        if Option.Type == "Dropdown" then
            Option:RecalculateListSize()
        end
    end

    for _, Notification in Library.Notifications do
        Notification:Resize()
    end
end

function Library:SetInteractionSpeed(Speed: number)
    Speed = math.clamp(tonumber(Speed) or 100, 50, 200)
    local Factor = 100 / Speed

    Library.TweenInfo = TweenInfo.new(0.12 * Factor, Enum.EasingStyle.Quart, Enum.EasingDirection.Out)
    Library.NotifyTweenInfo = TweenInfo.new(0.25 * Factor, Enum.EasingStyle.Quad, Enum.EasingDirection.Out)
end

function Library:GiveSignal(Connection: RBXScriptConnection | RBXScriptSignal)
    local ConnectionType = typeof(Connection)
    if Connection and (ConnectionType == "RBXScriptConnection" or ConnectionType == "RBXScriptSignal") then
        table.insert(Library.Signals, Connection)
    end

    return Connection
end

function IsValidCustomIcon(Icon: string)
    return typeof(Icon) == "string"
        and (
            Icon:match("^%d+$")
            or Icon:match("rbxasset")
            or Icon:match("roblox%.com/asset/%?id=")
            or Icon:match("create%.roblox%.com/store/asset/")
            or Icon:match("rbxthumb://type=")
            or Icon:match("%.[Pp][Nn][Gg]$")
            or Icon:match("%.[Jj][Pp][Ee]?[Gg]$")
            or Icon:match("%.[Ww][Ee][Bb][Pp]$")
        )
end

local function ResolveImageSource(Source: string)
    if typeof(Source) ~= "string" or Source == "" then
        return Source
    end

    local AssetId = nil
    if Source:match("^%d+$") then
        AssetId = Source
    else
        AssetId = Source:match("^rbxassetid://(%d+)$")
            or Source:match("create%.roblox%.com/store/asset/(%d+)")
            or Source:match("roblox%.com/asset/%?id=(%d+)")
    end

    if AssetId then
        return string.format("rbxassetid://%s", AssetId)
    end

    if Source:match("^rbxthumb://type=") then
        return Source
    end

    if Source:match("%.[Pp][Nn][Gg]$") or Source:match("%.[Jj][Pp][Ee]?[Gg]$") or Source:match("%.[Ww][Ee][Bb][Pp]$") then
        if getcustomasset then
            local Success, Asset = pcall(getcustomasset, Source)
            if Success and Asset then
                return Asset
            end
        end
    end

    return Source
end

local function GetAssetIdFromSource(Source: string)
    if typeof(Source) ~= "string" then
        return nil
    end

    return Source:match("^rbxassetid://(%d+)$")
        or Source:match("create%.roblox%.com/store/asset/(%d+)")
        or Source:match("roblox%.com/asset/%?id=(%d+)")
        or (Source:match("^%d+$") and Source)
end

local function AttachImageLoadFallback(ImageObject: Instance, Source: string)
    if not ImageObject or not ImageObject:IsA("ImageLabel") then
        return
    end

    local AssetId = GetAssetIdFromSource(Source)
    if not AssetId then
        return
    end

    task.delay(1.2, function()
        if not ImageObject.Parent then
            return
        end

        local CurrentImage = ImageObject.Image
        if CurrentImage ~= Source and CurrentImage ~= string.format("rbxassetid://%s", AssetId) then
            return
        end

        local Loaded = false
        pcall(function()
            Loaded = ImageObject.IsLoaded
        end)

        if not Loaded then
            ImageObject.Image = string.format("rbxthumb://type=Asset&id=%s&w=150&h=150", AssetId)
            ImageObject.ImageRectOffset = Vector2.zero
            ImageObject.ImageRectSize = Vector2.zero
        end
    end)
end

type Icon = {
    Url: string,
    Id: number,
    IconName: string,
    ImageRectOffset: Vector2,
    ImageRectSize: Vector2,
}

type IconModule = {
    Icons: { string },
    GetAsset: (Name: string) -> Icon?,
}

Library.KojoIcons = Library.KojoIcons or {
    ["kojo-logo"] = "rbxassetid://129289898938555",
    ["kojo-home"] = "rbxassetid://76183500264293",
    ["kojo-combat"] = "rbxassetid://10734975692",
    ["kojo-visuals"] = "rbxassetid://73885361599183",
    ["kojo-player"] = "rbxassetid://119811692586075",
    ["kojo-advanced"] = "rbxassetid://10734963400",
    ["kojo-settings"] = "rbxassetid://14007344336",

    ["kojo-discord"] = "rbxassetid://75871011309830",
    ["kojo-buy-key"] = "rbxassetid://10723396000",
    ["kojo-copy"] = "rbxassetid://76996819137437",
    ["kojo-game"] = "rbxassetid://10723395215",

    ["kojo-tier-premium"] = "rbxassetid://10709818626",
    ["kojo-tier-vip"] = "rbxassetid://10709818626",
    ["kojo-tier-lifetime"] = "rbxassetid://10709818626",
    ["kojo-tier-freemium"] = "rbxassetid://10734976528",
    ["kojo-tier-standard"] = "rbxassetid://10723396000",
}

local FetchIcons, Icons = pcall(function()
    return (loadstring(
        game:HttpGet("https://raw.githubusercontent.com/deividcomsono/lucide-roblox-direct/refs/heads/main/source.lua")
    ) :: () -> IconModule)()
end)

function Library:GetIcon(IconName: string)
    if not FetchIcons or typeof(IconName) ~= "string" or IconName == "" then
        return
    end

    if type(Icons) ~= "table" or type(Icons.GetAsset) ~= "function" then
        return
    end

    local function NormalizeIcon(Icon)
        if type(Icon) ~= "table" or typeof(Icon.Url) ~= "string" or Icon.Url == "" then
            return nil
        end

        return {
            Url = ResolveImageSource(Icon.Url),
            Id = Icon.Id,
            IconName = Icon.IconName,
            ImageRectOffset = typeof(Icon.ImageRectOffset) == "Vector2" and Icon.ImageRectOffset or Vector2.zero,
            ImageRectSize = typeof(Icon.ImageRectSize) == "Vector2" and Icon.ImageRectSize or Vector2.zero,
        }
    end

    local Success, Icon = pcall(function()
        return Icons:GetAsset(IconName)
    end)
    local Normalized = Success and NormalizeIcon(Icon) or nil
    if Normalized then
        return Normalized
    end

    Success, Icon = pcall(Icons.GetAsset, IconName)
    if not Success then
        return
    end

    return NormalizeIcon(Icon)
end

function Library:GetKojoIcon(IconName: string)
    if typeof(IconName) ~= "string" then
        return
    end

    local IconUrl = Library.KojoIcons[IconName]
    if not IconUrl then
        return
    end

    return {
        Url = ResolveImageSource(IconUrl),
        ImageRectOffset = Vector2.zero,
        ImageRectSize = Vector2.zero,
        Custom = true,
    }
end

function Library:GetCustomIcon(IconName: string)
    local KojoIcon = Library:GetKojoIcon(IconName)
    if KojoIcon then
        return KojoIcon
    end

    if not IsValidCustomIcon(IconName) then
        return Library:GetIcon(IconName)
    else
        IconName = ResolveImageSource(IconName)
        return {
            Url = IconName,
            ImageRectOffset = Vector2.zero,
            ImageRectSize = Vector2.zero,
            Custom = true,
        }
    end
end

function Library:Validate(Table: { [string]: any }, Template: { [string]: any }): { [string]: any }
    if typeof(Table) ~= "table" then
        return Template
    end

    for k, v in Template do
        if typeof(k) == "number" then
            continue
        end

        if typeof(v) == "table" then
            Table[k] = Library:Validate(Table[k], v)
        elseif Table[k] == nil then
            Table[k] = v
        end
    end

    return Table
end

--// Creator Functions \\--
local function FillInstance(Table: { [string]: any }, Instance: GuiObject)
    local ThemeProperties = Library.Registry[Instance] or {}

    for key, value in Table do
        local PropertyKey = key
        if key ~= "Text" then
            local SchemeValue = GetSchemeValue(value)

            if key == "FontFace" and Library.UseLegacyTextRendering then
                PropertyKey = "Font"

                if typeof(value) == "function" then
                    ThemeProperties[PropertyKey] = function()
                        return GetLegacyFontEnumFromFont(value())
                    end
                    value = GetLegacyFontEnumFromFont(value())
                elseif SchemeValue ~= nil then
                    ThemeProperties[PropertyKey] = function()
                        return GetLegacyFontEnumFromFont(GetSchemeValue("Font"))
                    end
                    value = GetLegacyFontEnumFromFont(SchemeValue)
                else
                    ThemeProperties[PropertyKey] = nil
                    value = GetLegacyFontEnumFromFont(value)
                end

                ThemeProperties[key] = nil
            elseif SchemeValue or typeof(value) == "function" then
                ThemeProperties[key] = value
                value = SchemeValue or value()
            else
                ThemeProperties[key] = nil
            end

        else
            ThemeProperties[key] = nil
        end

        Instance[PropertyKey] = value
    end

    if GetTableSize(ThemeProperties) > 0 then
        Library.Registry[Instance] = ThemeProperties
    end
end

local function New(ClassName: string, Properties: { [string]: any }): any
    local Instance = Instance.new(ClassName)

    if Templates[ClassName] then
        FillInstance(Templates[ClassName], Instance)
    end
    FillInstance(Properties, Instance)

    if Properties["Parent"] and not Properties["ZIndex"] then
        pcall(function()
            Instance.ZIndex = Properties.Parent.ZIndex
        end)
    end

    return Instance
end

--// Main Instances \\-
local function SafeParentUI(Instance: Instance, Parent: Instance | () -> Instance)
    local success, _error = pcall(function()
        if not Parent then
            Parent = CoreGui
        end

        local DestinationParent
        if typeof(Parent) == "function" then
            DestinationParent = Parent()
        else
            DestinationParent = Parent
        end

        Instance.Parent = DestinationParent
    end)

    if not (success and Instance.Parent) then
        Instance.Parent = Library.LocalPlayer:WaitForChild("PlayerGui", math.huge)
    end
end

local function ParentUI(UI: Instance, SkipHiddenUI: boolean?)
    if SkipHiddenUI then
        SafeParentUI(UI, CoreGui)
        return
    end

    pcall(protectgui, UI)
    SafeParentUI(UI, gethui)
end

local ScreenGui = New("ScreenGui", {
    Name = "Obsidian",
    DisplayOrder = 999,
    ResetOnSpawn = false,
})
ParentUI(ScreenGui)
Library.ScreenGui = ScreenGui
ScreenGui.DescendantRemoving:Connect(function(Instance)
    Library:RemoveFromRegistry(Instance)
end)

local ModalElement = New("TextButton", {
    BackgroundTransparency = 1,
    Modal = false,
    Size = UDim2.fromScale(0, 0),
    AnchorPoint = Vector2.zero,
    Text = "",
    ZIndex = -999,
    Parent = ScreenGui,
})

--// Cursor
local Cursor, CursorCustomImage
do
    Cursor = New("Frame", {
        AnchorPoint = Vector2.new(0.5, 0.5),
        BackgroundColor3 = "WhiteColor",
        Size = UDim2.fromOffset(9, 1),
        Visible = false,
        ZIndex = 11000,
        Parent = ScreenGui,
    })
    New("Frame", {
        AnchorPoint = Vector2.new(0.5, 0.5),
        BackgroundColor3 = "DarkColor",
        Position = UDim2.fromScale(0.5, 0.5),
        Size = UDim2.new(1, 2, 1, 2),
        ZIndex = 10999,
        Parent = Cursor,
    })

    local CursorV = New("Frame", {
        AnchorPoint = Vector2.new(0.5, 0.5),
        BackgroundColor3 = "WhiteColor",
        Position = UDim2.fromScale(0.5, 0.5),
        Size = UDim2.fromOffset(1, 9),
        ZIndex = 11000,
        Parent = Cursor,
    })
    New("Frame", {
        AnchorPoint = Vector2.new(0.5, 0.5),
        BackgroundColor3 = "DarkColor",
        Position = UDim2.fromScale(0.5, 0.5),
        Size = UDim2.new(1, 2, 1, 2),
        ZIndex = 10999,
        Parent = CursorV,
    })

    CursorCustomImage = New("ImageLabel", {
        AnchorPoint = Vector2.new(0.5, 0.5),
        BackgroundTransparency = 1,
        Position = UDim2.fromScale(0.5, 0.5),
        Size = UDim2.fromOffset(20, 20),
        ZIndex = 11000,
        Visible = false,
        Parent = Cursor
    })
end

--// Notification
local NotificationArea
local NotificationList
do
    NotificationArea = New("Frame", {
        AnchorPoint = Vector2.new(1, 0),
        BackgroundTransparency = 1,
        Position = UDim2.new(1, -6, 0, 6),
        Size = UDim2.new(0, 300, 1, -6),
        Parent = ScreenGui,
    })
    table.insert(
        Library.Scales,
        New("UIScale", {
            Parent = NotificationArea,
        })
    )

    NotificationList = New("UIListLayout", {
        HorizontalAlignment = Enum.HorizontalAlignment.Right,
        Padding = UDim.new(0, 8),
        Parent = NotificationArea,
    })
end

--// Lib Functions \\--
function Library:ResetCursorIcon()
    CursorCustomImage.Visible = false
    CursorCustomImage.Size = UDim2.fromOffset(20, 20)
end

function Library:ChangeCursorIcon(ImageId: string)
    if not ImageId or ImageId == "" then
        Library:ResetCursorIcon()
        return
    end

    local Icon = Library:GetCustomIcon(ImageId)
    assert(Icon, "Image must be a valid Roblox asset or a valid URL or a valid lucide icon.")

    CursorCustomImage.Visible = true
    CursorCustomImage.Image = Icon.Url
    CursorCustomImage.ImageRectOffset = Icon.ImageRectOffset
    CursorCustomImage.ImageRectSize = Icon.ImageRectSize
end

function Library:ChangeCursorIconSize(Size: UDim2)
    assert(typeof(Size) == "UDim2", "UDim2 expected.")
    CursorCustomImage.Size = Size
end

function Library:GetBetterColor(Color: Color3, Add: number): Color3
    Add = Add * (Library.IsLightTheme and -4 or 2)
    return Color3.fromRGB(
        math.clamp(Color.R * 255 + Add, 0, 255),
        math.clamp(Color.G * 255 + Add, 0, 255),
        math.clamp(Color.B * 255 + Add, 0, 255)
    )
end

function Library:GetLighterColor(Color: Color3): Color3
    local H, S, V = Color:ToHSV()
    return Color3.fromHSV(H, math.max(0, S - 0.1), math.min(1, V + 0.1))
end

function Library:GetDarkerColor(Color: Color3): Color3
    local H, S, V = Color:ToHSV()
    return Color3.fromHSV(H, S, V / 2)
end

function Library:LerpColor(ColorA: Color3, ColorB: Color3, Alpha: number): Color3
    return ColorA:Lerp(ColorB, math.clamp(Alpha, 0, 1))
end

function Library:GetWeightedFont(Weight: Enum.FontWeight?): Font
    local NormalizedFont = NormalizeFontValue(Library.Scheme.Font, Weight)
    if Library.UseLegacyTextRendering then
        return Font.fromEnum(GetLegacyFontEnumFromFont(NormalizedFont, Weight))
    end
    return NormalizedFont
end

function Library:GetUiColor(Token: string): Color3
    local Scheme = Library.Scheme
    local Accent = Scheme.AccentColor
    local Background = Scheme.BackgroundColor
    local Main = Scheme.MainColor
    local Outline = Scheme.OutlineColor
    local FontColor = Scheme.FontColor

    if Token == "Shell" then
        return Background
    elseif Token == "Rail" then
        return Library:LerpColor(Background, Main, 0.16)
    elseif Token == "Topbar" then
        return Library:LerpColor(Background, Main, 0.1)
    elseif Token == "Panel" then
        return Library:LerpColor(Background, Main, 0.26)
    elseif Token == "Card" then
        return Library:LerpColor(Background, Main, 0.38)
    elseif Token == "Control" then
        return Library:LerpColor(Main, Background, 0.14)
    elseif Token == "Divider" then
        return Library:LerpColor(Outline, Background, 0.38)
    elseif Token == "SoftOutline" then
        return Library:LerpColor(Outline, Background, 0.2)
    elseif Token == "MutedText" then
        return Library:LerpColor(FontColor, Background, 0.24)
    elseif Token == "SubtleText" then
        return Library:LerpColor(FontColor, Background, 0.56)
    elseif Token == "ActiveText" then
        return FontColor
    elseif Token == "AccentFill" then
        return Library:LerpColor(Accent, Color3.new(1, 1, 1), 0.08)
    elseif Token == "AccentGlow" then
        return Library:LerpColor(Accent, Color3.new(1, 1, 1), 0.32)
    elseif Token == "AccentSoft" then
        return Library:LerpColor(Accent, Background, 0.26)
    end

    return FontColor
end

function Library:GetKeyString(KeyCode: Enum.KeyCode)
    if KeyCode.EnumType == Enum.KeyCode and KeyCode.Value > 33 and KeyCode.Value < 127 then
        return string.char(KeyCode.Value)
    end

    return KeyCode.Name
end

function Library:GetTextBounds(Text: string, Font: Font, Size: number, Width: number?): (number, number)
    local Params = Instance.new("GetTextBoundsParams")
    Params.Text = Text
    Params.RichText = true
    if Library.UseLegacyTextRendering then
        Params.Font = Font.fromEnum(GetLegacyFontEnumFromFont(Font))
    else
        Params.Font = NormalizeFontValue(Font)
    end
    Params.Size = Size
    Params.Width = Width or workspace.CurrentCamera.ViewportSize.X - 32

    local Bounds = TextService:GetTextBoundsAsync(Params)
    return math.ceil(Bounds.X), math.ceil(Bounds.Y)
end

function Library:MouseIsOverFrame(Frame: GuiObject, Mouse: Vector2): boolean
    local AbsPos, AbsSize = Frame.AbsolutePosition, Frame.AbsoluteSize
    return Mouse.X >= AbsPos.X
        and Mouse.X <= AbsPos.X + AbsSize.X
        and Mouse.Y >= AbsPos.Y
        and Mouse.Y <= AbsPos.Y + AbsSize.Y
end

function Library:SafeCallback(Func: (...any) -> ...any, ...: any)
    if not (Func and typeof(Func) == "function") then
        return
    end

    local Result = table.pack(xpcall(Func, function(Error)
        task.defer(error, debug.traceback(Error, 2))
        if Library.NotifyOnError then
            Library:Notify(Error)
        end

        return Error
    end, ...))

    if not Result[1] then
        return nil
    end

    return table.unpack(Result, 2, Result.n)
end

function Library:MakeDraggable(UI: GuiObject, DragFrame: GuiObject, IgnoreToggled: boolean?, IsMainWindow: boolean?)
    local StartPos
    local FramePos
    local Dragging = false
    local Changed
    DragFrame.InputBegan:Connect(function(Input: InputObject)
        if not IsClickInput(Input) or IsMainWindow and Library.CantDragForced then
            return
        end

        StartPos = Input.Position
        FramePos = UI.Position
        Dragging = true

        Changed = Input.Changed:Connect(function()
            if Input.UserInputState ~= Enum.UserInputState.End then
                return
            end

            Dragging = false
            if Changed and Changed.Connected then
                Changed:Disconnect()
                Changed = nil
            end
        end)
    end)
    Library:GiveSignal(UserInputService.InputChanged:Connect(function(Input: InputObject)
        if
            (not IgnoreToggled and not Library.Toggled)
            or (IsMainWindow and Library.CantDragForced)
            or not (ScreenGui and ScreenGui.Parent)
        then
            Dragging = false
            if Changed and Changed.Connected then
                Changed:Disconnect()
                Changed = nil
            end

            return
        end

        if Dragging and IsHoverInput(Input) then
            local Delta = Input.Position - StartPos
            UI.Position =
                UDim2.new(FramePos.X.Scale, FramePos.X.Offset + Delta.X, FramePos.Y.Scale, FramePos.Y.Offset + Delta.Y)
        end
    end))
end

function Library:MakeResizable(UI: GuiObject, DragFrame: GuiObject, Callback: () -> ()?)
    local StartPos
    local FrameSize
    local Dragging = false
    local Changed

    DragFrame.InputBegan:Connect(function(Input: InputObject)
        if not IsClickInput(Input) then
            return
        end

        StartPos = Input.Position
        FrameSize = UI.Size
        Dragging = true

        Changed = Input.Changed:Connect(function()
            if Input.UserInputState ~= Enum.UserInputState.End then
                return
            end

            Dragging = false
            if Changed and Changed.Connected then
                Changed:Disconnect()
                Changed = nil
            end
        end)
    end)

    Library:GiveSignal(UserInputService.InputChanged:Connect(function(Input: InputObject)
        if not UI.Visible or not (ScreenGui and ScreenGui.Parent) then
            Dragging = false
            if Changed and Changed.Connected then
                Changed:Disconnect()
                Changed = nil
            end

            return
        end

        if Dragging and IsHoverInput(Input) then
            local Delta = Input.Position - StartPos
            UI.Size = UDim2.new(
                FrameSize.X.Scale,
                math.clamp(FrameSize.X.Offset + Delta.X, Library.MinSize.X, math.huge),
                FrameSize.Y.Scale,
                math.clamp(FrameSize.Y.Offset + Delta.Y, Library.MinSize.Y, math.huge)
            )
            if Callback then
                Library:SafeCallback(Callback)
            end
        end
    end))
end

function Library:MakeCover(Holder: GuiObject, Place: string)
    local Pos = Places[Place] or { 0, 0 }
    local Size = Sizes[Place] or { 1, 0.5 }

    local Cover = New("Frame", {
        AnchorPoint = Vector2.new(Pos[1], Pos[2]),
        BackgroundColor3 = Holder.BackgroundColor3,
        Position = UDim2.fromScale(Pos[1], Pos[2]),
        Size = UDim2.fromScale(Size[1], Size[2]),
        Parent = Holder,
    })

    return Cover
end

function Library:MakeLine(Frame: GuiObject, Info)
    local Line = New("Frame", {
        AnchorPoint = Info.AnchorPoint or Vector2.zero,
        BackgroundColor3 = function()
            return Library:GetUiColor("Divider")
        end,
        Position = Info.Position,
        Size = Info.Size,
        ZIndex = Info.ZIndex or Frame.ZIndex,
        Parent = Frame,
    })

    return Line
end

function Library:AddOutline(Frame: GuiObject)
    local OutlineStroke = New("UIStroke", {
        Color = function()
            return Library:GetUiColor("SoftOutline")
        end,
        Thickness = 1,
        Transparency = 0,
        ZIndex = 2,
        Parent = Frame,
    })
    local ShadowStroke = New("UIStroke", {
        Color = function()
            return Library:GetUiColor("SoftOutline")
        end,
        Thickness = 1,
        Transparency = 1,
        ZIndex = 1,
        Parent = Frame,
    })
    return OutlineStroke, ShadowStroke
end

function Library:AddBlank(Frame: GuiObject, Size: UDim2)
    return New("Frame", {
        BackgroundTransparency = 1,
        Size = Size or UDim2.fromScale(0, 0),
        Parent = Frame,
    })
end

--// Deprecated \\--
function Library:MakeOutline(Frame: GuiObject, Corner: number?, ZIndex: number?)
    warn("Obsidian:MakeOutline is deprecated, please use Obsidian:AddOutline instead.")
    local Holder = New("Frame", {
        BackgroundColor3 = "DarkColor",
        Position = UDim2.fromOffset(-2, -2),
        Size = UDim2.new(1, 4, 1, 4),
        ZIndex = ZIndex,
        Parent = Frame,
    })

    local Outline = New("Frame", {
        BackgroundColor3 = "OutlineColor",
        Position = UDim2.fromOffset(1, 1),
        Size = UDim2.new(1, -2, 1, -2),
        ZIndex = ZIndex,
        Parent = Holder,
    })

    if Corner and Corner > 0 then
        New("UICorner", {
            CornerRadius = UDim.new(0, Corner + 1),
            Parent = Holder,
        })
        New("UICorner", {
            CornerRadius = UDim.new(0, Corner),
            Parent = Outline,
        })
    end

    return Holder, Outline
end

function Library:AddDraggableLabel(Text: string)
    local Table = {}

    local Label = New("TextLabel", {
        AutomaticSize = Enum.AutomaticSize.XY,
        BackgroundColor3 = "BackgroundColor",
        Size = UDim2.fromOffset(0, 0),
        Position = UDim2.fromOffset(6, 6),
        Text = Text,
        TextSize = 15,
        ZIndex = 10,
        Parent = ScreenGui,
    })
    New("UICorner", {
        CornerRadius = UDim.new(0, Library.CornerRadius),
        Parent = Label,
    })
    New("UIPadding", {
        PaddingBottom = UDim.new(0, 6),
        PaddingLeft = UDim.new(0, 12),
        PaddingRight = UDim.new(0, 12),
        PaddingTop = UDim.new(0, 6),
        Parent = Label,
    })
    table.insert(
        Library.Scales,
        New("UIScale", {
            Parent = Label,
        })
    )
    Library:AddOutline(Label)

    Library:MakeDraggable(Label, Label, true)

    Table.Label = Label

    function Table:SetText(Text: string)
        Label.Text = Text
    end

    function Table:SetVisible(Visible: boolean)
        Label.Visible = Visible
    end

    return Table
end

function Library:AddDraggableButton(Text: string, Func, ExcludeScaling: boolean?)
    local Table = {}

    local Button = New("TextButton", {
        BackgroundColor3 = "BackgroundColor",
        Position = UDim2.fromOffset(6, 6),
        TextSize = 16,
        ZIndex = 10,
        Parent = ScreenGui,
    })
    New("UICorner", {
        CornerRadius = UDim.new(0, Library.CornerRadius),
        Parent = Button,
    })
    if not ExcludeScaling then
        table.insert(
            Library.Scales,
            New("UIScale", {
                Parent = Button,
            })
        )
    end
    Library:AddOutline(Button)

    Button.MouseButton1Click:Connect(function()
        Library:SafeCallback(Func, Table)
    end)
    Library:MakeDraggable(Button, Button, true)

    Table.Button = Button

    function Table:SetText(Text: string)
        local X, Y = Library:GetTextBounds(Text, Library.Scheme.Font, 16)

        Button.Text = Text
        Button.Size = UDim2.fromOffset(X * 2, Y * 2)
    end
    Table:SetText(Text)

    return Table
end

function Library:AddDraggableMenu(Name: string)
    local IsKeybindMenu = Name == "Keybinds"
    local MinWidth = IsKeybindMenu and 228 or 180
    local HeaderHeight = IsKeybindMenu and 30 or 34

    local Holder = New("Frame", {
        AutomaticSize = IsKeybindMenu and Enum.AutomaticSize.Y or Enum.AutomaticSize.XY,
        BackgroundColor3 = function()
            return IsKeybindMenu and Library:GetUiColor("Card") or Library.Scheme.BackgroundColor
        end,
        Position = UDim2.fromOffset(6, 6),
        Size = IsKeybindMenu and UDim2.fromOffset(MinWidth, 0) or UDim2.fromOffset(0, 0),
        ZIndex = 10,
        Parent = ScreenGui,
    })
    New("UICorner", {
        CornerRadius = UDim.new(0, Library.CornerRadius),
        Parent = Holder,
    })
    table.insert(
        Library.Scales,
        New("UIScale", {
            Parent = Holder,
        })
    )
    if not IsKeybindMenu then
        New("Frame", {
            BackgroundTransparency = 1,
            Size = UDim2.fromOffset(MinWidth, 0),
            Parent = Holder,
        })
    end
    Library:AddOutline(Holder)

    Library:MakeLine(Holder, {
        Position = UDim2.fromOffset(0, HeaderHeight),
        Size = UDim2.new(1, 0, 0, 1),
    })

    local Label = New("TextLabel", {
        BackgroundTransparency = 1,
        FontFace = function()
            return Library:GetWeightedFont(IsKeybindMenu and Enum.FontWeight.Bold or Enum.FontWeight.Medium)
        end,
        Size = UDim2.new(1, 0, 0, HeaderHeight),
        Text = Name,
        TextColor3 = function()
            return IsKeybindMenu and Library:GetUiColor("ActiveText") or Library.Scheme.FontColor
        end,
        TextSize = IsKeybindMenu and 14 or 15,
        TextXAlignment = Enum.TextXAlignment.Left,
        Parent = Holder,
    })
    New("UIPadding", {
        PaddingLeft = UDim.new(0, 12),
        PaddingRight = UDim.new(0, 12),
        Parent = Label,
    })

    local Container = New("Frame", {
        AutomaticSize = Enum.AutomaticSize.Y,
        BackgroundTransparency = 1,
        Position = UDim2.fromOffset(0, HeaderHeight + 1),
        Size = UDim2.new(1, 0, 0, 0),
        Parent = Holder,
    })
    New("UIListLayout", {
        Padding = UDim.new(0, IsKeybindMenu and 6 or 7),
        Parent = Container,
    })
    New("UIPadding", {
        PaddingBottom = UDim.new(0, IsKeybindMenu and 9 or 7),
        PaddingLeft = UDim.new(0, IsKeybindMenu and 9 or 7),
        PaddingRight = UDim.new(0, IsKeybindMenu and 9 or 7),
        PaddingTop = UDim.new(0, IsKeybindMenu and 8 or 7),
        Parent = Container,
    })

    Library:MakeDraggable(Holder, Label, true)
    return Holder, Container
end

--// Watermark - Deprecated \\--
do
    local WatermarkLabel = Library:AddDraggableLabel("")
    WatermarkLabel:SetVisible(false)

    function Library:SetWatermark(Text: string)
        warn("Watermark is deprecated, please use Library:AddDraggableLabel instead.")
        WatermarkLabel:SetText(Text)
    end

    function Library:SetWatermarkVisibility(Visible: boolean)
        warn("Watermark is deprecated, please use Library:AddDraggableLabel instead.")
        WatermarkLabel:SetVisible(Visible)
    end
end

--// Context Menu \\--
local CurrentMenu
function Library:AddContextMenu(
    Holder: GuiObject,
    Size: UDim2 | () -> (),
    Offset: { [number]: number } | () -> {},
    List: number?,
    ActiveCallback: (Active: boolean) -> ()?
)
    local Menu
    if List then
        Menu = New("ScrollingFrame", {
            AutomaticCanvasSize = List == 2 and Enum.AutomaticSize.Y or Enum.AutomaticSize.None,
            AutomaticSize = List == 1 and Enum.AutomaticSize.Y or Enum.AutomaticSize.None,
            BackgroundColor3 = function()
                return Library:GetUiColor("Card")
            end,
            BorderSizePixel = 0,
            BottomImage = "rbxasset://textures/ui/Scroll/scroll-middle.png",
            CanvasSize = UDim2.fromOffset(0, 0),
            ScrollBarImageTransparency = 1,
            ScrollBarThickness = 0,
            Size = typeof(Size) == "function" and Size() or Size,
            TopImage = "rbxasset://textures/ui/Scroll/scroll-middle.png",
            Visible = false,
            ZIndex = 10,
            Parent = ScreenGui,
        })
    else
        Menu = New("Frame", {
            BackgroundColor3 = function()
                return Library:GetUiColor("Card")
            end,
            BorderSizePixel = 0,
            Size = typeof(Size) == "function" and Size() or Size,
            Visible = false,
            ZIndex = 10,
            Parent = ScreenGui,
        })
    end
    New("UICorner", {
        CornerRadius = UDim.new(0, 8),
        Parent = Menu,
    })
    local MenuStroke = New("UIStroke", {
        Color = function()
            return Library:GetUiColor("SoftOutline")
        end,
        Parent = Menu,
    })
    local MenuScale = New("UIScale", {
        Parent = Menu,
    })
    table.insert(Library.Scales, MenuScale)

    local Table = {
        Active = false,
        Holder = Holder,
        Menu = Menu,
        List = nil,
        Signal = nil,

        Size = Size,
        Tween = nil,
        CloseVersion = 0,
    }

    if List then
        Table.List = New("UIListLayout", {
            Parent = Menu,
        })
    end

    function Table:Open()
        if CurrentMenu == Table then
            return
        elseif CurrentMenu then
            CurrentMenu:Close()
        end

        CurrentMenu = Table
        Table.Active = true

        if typeof(Offset) == "function" then
            Menu.Position = UDim2.fromOffset(
                math.floor(Holder.AbsolutePosition.X + Offset()[1]),
                math.floor(Holder.AbsolutePosition.Y + Offset()[2])
            )
        else
            Menu.Position = UDim2.fromOffset(
                math.floor(Holder.AbsolutePosition.X + Offset[1]),
                math.floor(Holder.AbsolutePosition.Y + Offset[2])
            )
        end
        Menu.Size = typeof(Table.Size) == "function" and Table.Size() or Table.Size
        if typeof(ActiveCallback) == "function" then
            Library:SafeCallback(ActiveCallback, true)
        end

        Menu.Visible = true
        Table.CloseVersion += 1
        StopTween(Table.Tween)
        MenuScale.Scale = 0.96
        Menu.BackgroundTransparency = 0.08
        MenuStroke.Transparency = 0.12
        Table.Tween = TweenService:Create(MenuScale, TweenInfo.new(0.14, Enum.EasingStyle.Quart, Enum.EasingDirection.Out), {
            Scale = 1,
        })
        Table.Tween:Play()
        TweenService:Create(Menu, TweenInfo.new(0.14, Enum.EasingStyle.Quart, Enum.EasingDirection.Out), {
            BackgroundTransparency = 0,
        }):Play()
        TweenService:Create(MenuStroke, TweenInfo.new(0.14, Enum.EasingStyle.Quart, Enum.EasingDirection.Out), {
            Transparency = 0,
        }):Play()

        Table.Signal = Holder:GetPropertyChangedSignal("AbsolutePosition"):Connect(function()
            if typeof(Offset) == "function" then
                Menu.Position = UDim2.fromOffset(
                    math.floor(Holder.AbsolutePosition.X + Offset()[1]),
                    math.floor(Holder.AbsolutePosition.Y + Offset()[2])
                )
            else
                Menu.Position = UDim2.fromOffset(
                    math.floor(Holder.AbsolutePosition.X + Offset[1]),
                    math.floor(Holder.AbsolutePosition.Y + Offset[2])
                )
            end
        end)
    end

    function Table:Close()
        if CurrentMenu ~= Table then
            return
        end

        if Table.Signal then
            Table.Signal:Disconnect()
            Table.Signal = nil
        end
        Table.Active = false
        CurrentMenu = nil
        if typeof(ActiveCallback) == "function" then
            Library:SafeCallback(ActiveCallback, false)
        end

        Table.CloseVersion += 1
        local CloseVersion = Table.CloseVersion
        StopTween(Table.Tween)
        Table.Tween = TweenService:Create(MenuScale, TweenInfo.new(0.1, Enum.EasingStyle.Quad, Enum.EasingDirection.Out), {
            Scale = 0.97,
        })
        Table.Tween:Play()
        TweenService:Create(Menu, TweenInfo.new(0.1, Enum.EasingStyle.Quad, Enum.EasingDirection.Out), {
            BackgroundTransparency = 0.08,
        }):Play()
        TweenService:Create(MenuStroke, TweenInfo.new(0.1, Enum.EasingStyle.Quad, Enum.EasingDirection.Out), {
            Transparency = 0.18,
        }):Play()
        task.delay(0.1, function()
            if Library.Unloaded or Table.Active or Table.CloseVersion ~= CloseVersion then
                return
            end

            Menu.Visible = false
        end)
    end

    function Table:Toggle()
        if Table.Active then
            Table:Close()
        else
            Table:Open()
        end
    end

    function Table:SetSize(Size)
        Table.Size = Size
        Menu.Size = typeof(Size) == "function" and Size() or Size
    end

    return Table
end

Library:GiveSignal(UserInputService.InputBegan:Connect(function(Input: InputObject)
    if Library.Unloaded then
        return
    end

    if IsClickInput(Input, true) then
        local Location = Input.Position

        if
            CurrentMenu
            and not (
                Library:MouseIsOverFrame(CurrentMenu.Menu, Location)
                or Library:MouseIsOverFrame(CurrentMenu.Holder, Location)
            )
        then
            CurrentMenu:Close()
        end
    end
end))

--// Tooltip \\--
local TooltipLabel = New("TextLabel", {
    AutomaticSize = Enum.AutomaticSize.Y,
    BackgroundColor3 = "BackgroundColor",
    BorderColor3 = "OutlineColor",
    BorderSizePixel = 1,
    TextSize = 14,
    TextWrapped = true,
    Visible = false,
    ZIndex = 20,
    Parent = ScreenGui,
})
New("UIPadding", {
    PaddingBottom = UDim.new(0, 2),
    PaddingLeft = UDim.new(0, 4),
    PaddingRight = UDim.new(0, 4),
    PaddingTop = UDim.new(0, 2),
    Parent = TooltipLabel,
})
table.insert(
    Library.Scales,
    New("UIScale", {
        Parent = TooltipLabel,
    })
)
TooltipLabel:GetPropertyChangedSignal("AbsolutePosition"):Connect(function()
    if Library.Unloaded then
        return
    end

    local X, _ = Library:GetTextBounds(
        TooltipLabel.Text,
        TooltipLabel.FontFace,
        TooltipLabel.TextSize,
        (workspace.CurrentCamera.ViewportSize.X - TooltipLabel.AbsolutePosition.X - 8) / Library.DPIScale
    )

    TooltipLabel.Size = UDim2.fromOffset(X + 8)
end)

local CurrentHoverInstance
function Library:AddTooltip(InfoStr: string, DisabledInfoStr: string, HoverInstance: GuiObject)
    local TooltipTable = {
        Disabled = false,
        Hovering = false,
        Signals = {},
    }

    local function DoHover()
        if
            CurrentHoverInstance == HoverInstance
            or Library.ActiveDialog
            or (CurrentMenu and Library:MouseIsOverFrame(CurrentMenu.Menu, Mouse))
            or (TooltipTable.Disabled and typeof(DisabledInfoStr) ~= "string")
            or (not TooltipTable.Disabled and typeof(InfoStr) ~= "string")
        then
            return
        end
        CurrentHoverInstance = HoverInstance

        TooltipLabel.Text = TooltipTable.Disabled and DisabledInfoStr or InfoStr
        TooltipLabel.Visible = true

        while
            Library.Toggled
            and not Library.ActiveDialog
            and Library:MouseIsOverFrame(HoverInstance, Mouse)
            and not (CurrentMenu and Library:MouseIsOverFrame(CurrentMenu.Menu, Mouse))
        do
            TooltipLabel.Position = UDim2.fromOffset(
                Mouse.X + (Library.ShowCustomCursor and 8 or 14),
                Mouse.Y + (Library.ShowCustomCursor and 8 or 12)
            )

            RunService.RenderStepped:Wait()
        end

        TooltipLabel.Visible = false
        CurrentHoverInstance = nil
    end

    local function GiveSignal(Connection: RBXScriptConnection | RBXScriptSignal)
        local ConnectionType = typeof(Connection)
        if Connection and (ConnectionType == "RBXScriptConnection" or ConnectionType == "RBXScriptSignal") then
            table.insert(TooltipTable.Signals, Connection)
        end

        return Connection
    end

    GiveSignal(HoverInstance.MouseEnter:Connect(DoHover))
    GiveSignal(HoverInstance.MouseMoved:Connect(DoHover))
    GiveSignal(HoverInstance.MouseLeave:Connect(function()
        if CurrentHoverInstance ~= HoverInstance then
            return
        end

        TooltipLabel.Visible = false
        CurrentHoverInstance = nil
    end))

    function TooltipTable:Destroy()
        for Index = #TooltipTable.Signals, 1, -1 do
            local Connection = table.remove(TooltipTable.Signals, Index)
            if Connection and Connection.Connected then
                Connection:Disconnect()
            end
        end

        if CurrentHoverInstance == HoverInstance then
            if TooltipLabel then
                TooltipLabel.Visible = false
            end

            CurrentHoverInstance = nil
        end
    end

    table.insert(Tooltips, TooltipLabel)
    return TooltipTable
end

function Library:OnUnload(Callback)
    table.insert(Library.UnloadSignals, Callback)
end

function Library:Unload()
    for Index = #Library.Signals, 1, -1 do
        local Connection = table.remove(Library.Signals, Index)
        if Connection and Connection.Connected then
            Connection:Disconnect()
        end
    end

    for _, Callback in Library.UnloadSignals do
        Library:SafeCallback(Callback)
    end

    for _, Tooltip in Tooltips do
        Library:SafeCallback(Tooltip.Destroy, Tooltip)
    end

    Library.Unloaded = true
    ScreenGui:Destroy()

    getgenv().Library = nil
end

local CheckIcon = Library:GetIcon("check")
local ArrowIcon = Library:GetIcon("chevron-up")
local ResizeIcon = Library:GetIcon("move-diagonal-2")
local KeyIcon = Library:GetIcon("key")
local MoveIcon = Library:GetIcon("move")

function Library:SetIconModule(module: IconModule)
    FetchIcons = true
    Icons = module

    -- Top ten fixes 🚀
    CheckIcon = Library:GetIcon("check")
    ArrowIcon = Library:GetIcon("chevron-up")
    ResizeIcon = Library:GetIcon("move-diagonal-2")
    KeyIcon = Library:GetIcon("key")
    MoveIcon = Library:GetIcon("move")
end

local BaseAddons = {}
do
    local Funcs = {}

    function Funcs:AddKeyPicker(Idx, Info)
        Info = Library:Validate(Info, Templates.KeyPicker)

        local ParentObj = self
        local ToggleLabel = ParentObj.TextLabel
        local SyncTarget = nil

        local KeyPicker = {
            Text = Info.Text,
            Value = Info.Default, -- Key
            Modifiers = Info.DefaultModifiers, -- Modifiers
            DisplayValue = Info.Default, -- Picker Text

            Toggled = false,
            Mode = Info.Mode,
            SyncToggleState = Info.SyncToggleState,

            Callback = Info.Callback,
            ChangedCallback = Info.ChangedCallback,
            Changed = Info.Changed,
            Clicked = Info.Clicked,

            Type = "KeyPicker",
        }

        local function ResolveSyncTarget(Target)
            if Target == true then
                return ParentObj
            end

            if typeof(Target) == "table" then
                return Target
            end

            if typeof(Target) == "string" then
                return Library.Toggles[Target]
            end

            return nil
        end

        if KeyPicker.Mode == "Press" then
            assert(ParentObj.Type == "Label", "KeyPicker with the mode 'Press' can be only applied on Labels.")

            KeyPicker.SyncToggleState = false
            Info.Modes = { "Press" }
            Info.Mode = "Press"
        end

        if KeyPicker.SyncToggleState then
            SyncTarget = ResolveSyncTarget(Info.SyncToggleState)
            if typeof(SyncTarget) ~= "table" or SyncTarget.Type ~= "Toggle" then
                KeyPicker.SyncToggleState = false
                SyncTarget = nil
            else
                Info.Modes = { "Always", "Toggle", "Hold" }

                if not table.find(Info.Modes, Info.Mode) then
                    Info.Mode = "Toggle"
                end

                KeyPicker.Toggled = SyncTarget.Value
            end
        end

        KeyPicker.Mode = Info.Mode

        local Picking = false

        -- Special Keys
        local SpecialKeys = {
            ["MB1"] = Enum.UserInputType.MouseButton1,
            ["MB2"] = Enum.UserInputType.MouseButton2,
            ["MB3"] = Enum.UserInputType.MouseButton3,
        }

        local SpecialKeysInput = {
            [Enum.UserInputType.MouseButton1] = "MB1",
            [Enum.UserInputType.MouseButton2] = "MB2",
            [Enum.UserInputType.MouseButton3] = "MB3",
        }

        -- Modifiers
        local Modifiers = {
            ["LAlt"] = Enum.KeyCode.LeftAlt,
            ["RAlt"] = Enum.KeyCode.RightAlt,

            ["LCtrl"] = Enum.KeyCode.LeftControl,
            ["RCtrl"] = Enum.KeyCode.RightControl,

            ["LShift"] = Enum.KeyCode.LeftShift,
            ["RShift"] = Enum.KeyCode.RightShift,

            ["Tab"] = Enum.KeyCode.Tab,
            ["CapsLock"] = Enum.KeyCode.CapsLock,
        }

        local ModifiersInput = {
            [Enum.KeyCode.LeftAlt] = "LAlt",
            [Enum.KeyCode.RightAlt] = "RAlt",

            [Enum.KeyCode.LeftControl] = "LCtrl",
            [Enum.KeyCode.RightControl] = "RCtrl",

            [Enum.KeyCode.LeftShift] = "LShift",
            [Enum.KeyCode.RightShift] = "RShift",

            [Enum.KeyCode.Tab] = "Tab",
            [Enum.KeyCode.CapsLock] = "CapsLock",
        }

        local IsModifierInput = function(Input)
            return Input.UserInputType == Enum.UserInputType.Keyboard and ModifiersInput[Input.KeyCode] ~= nil
        end

        local GetActiveModifiers = function()
            local ActiveModifiers = {}

            for Name, Input in Modifiers do
                if table.find(ActiveModifiers, Name) then
                    continue
                end
                if not UserInputService:IsKeyDown(Input) then
                    continue
                end

                table.insert(ActiveModifiers, Name)
            end

            return ActiveModifiers
        end

        local AreModifiersHeld = function(Required)
            if not (typeof(Required) == "table" and GetTableSize(Required) > 0) then
                return true
            end

            local ActiveModifiers = GetActiveModifiers()
            local Holding = true

            for _, Name in Required do
                if table.find(ActiveModifiers, Name) then
                    continue
                end

                Holding = false
                break
            end

            return Holding
        end

        local IsInputDown = function(Input)
            if not Input then
                return false
            end

            if SpecialKeysInput[Input.UserInputType] ~= nil then
                return UserInputService:IsMouseButtonPressed(Input.UserInputType)
                    and not UserInputService:GetFocusedTextBox()
            elseif Input.UserInputType == Enum.UserInputType.Keyboard then
                return UserInputService:IsKeyDown(Input.KeyCode) and not UserInputService:GetFocusedTextBox()
            else
                return false
            end
        end

        local ConvertToInputModifiers = function(CurrentModifiers)
            local InputModifiers = {}

            for _, name in CurrentModifiers do
                table.insert(InputModifiers, Modifiers[name])
            end

            return InputModifiers
        end

        local VerifyModifiers = function(CurrentModifiers)
            if typeof(CurrentModifiers) ~= "table" then
                return {}
            end

            local ValidModifiers = {}

            for _, name in CurrentModifiers do
                if not Modifiers[name] then
                    continue
                end

                table.insert(ValidModifiers, name)
            end

            return ValidModifiers
        end

        KeyPicker.Modifiers = VerifyModifiers(KeyPicker.Modifiers) -- Verify default modifiers

        local Picker = New("TextButton", {
            BackgroundColor3 = function()
                return Library:GetUiColor("Control")
            end,
            BorderSizePixel = 0,
            FontFace = function()
                return Library:GetWeightedFont(Enum.FontWeight.Medium)
            end,
            Size = UDim2.fromOffset(42, 20),
            Text = KeyPicker.Value,
            TextColor3 = function()
                return Library:GetUiColor("ActiveText")
            end,
            TextSize = 13,
            Parent = ToggleLabel,
        })
        if ParentObj.Window and ParentObj.Window.RegisterTransparencyTarget then
            ParentObj.Window:RegisterTransparencyTarget(Picker, 0.04, 0.62)
        end
        New("UICorner", {
            CornerRadius = UDim.new(0, 7),
            Parent = Picker,
        })
        New("UIStroke", {
            Color = function()
                return Library:GetUiColor("SoftOutline")
            end,
            Parent = Picker,
        })
        local PickerHoverTween
        Picker.MouseEnter:Connect(function()
            StopTween(PickerHoverTween)
            PickerHoverTween = TweenService:Create(Picker, TweenInfo.new(0.12, Enum.EasingStyle.Quart, Enum.EasingDirection.Out), {
                BackgroundTransparency = 0.04,
            })
            PickerHoverTween:Play()
        end)
        Picker.MouseLeave:Connect(function()
            StopTween(PickerHoverTween)
            PickerHoverTween = TweenService:Create(Picker, TweenInfo.new(0.12, Enum.EasingStyle.Quart, Enum.EasingDirection.Out), {
                BackgroundTransparency = 0,
            })
            PickerHoverTween:Play()
        end)
        Picker.MouseButton1Down:Connect(function()
            StopTween(PickerHoverTween)
            PickerHoverTween = TweenService:Create(Picker, TweenInfo.new(0.08, Enum.EasingStyle.Quad, Enum.EasingDirection.Out), {
                BackgroundTransparency = 0.1,
            })
            PickerHoverTween:Play()
        end)
        Picker.MouseButton1Up:Connect(function()
            StopTween(PickerHoverTween)
            PickerHoverTween = TweenService:Create(Picker, TweenInfo.new(0.1, Enum.EasingStyle.Quad, Enum.EasingDirection.Out), {
                BackgroundTransparency = 0.03,
            })
            PickerHoverTween:Play()
        end)

        local KeybindsToggle = { Normal = KeyPicker.Mode ~= "Toggle" }
        do
            local Holder = New("TextButton", {
                BackgroundColor3 = function()
                    return Library:GetUiColor("Control")
                end,
                BackgroundTransparency = 0.06,
                Size = UDim2.new(1, 0, 0, 24),
                Text = "",
                Visible = not Info.NoUI,
                Parent = Library.KeybindContainer,
            })
            if ParentObj.Window and ParentObj.Window.RegisterTransparencyTarget then
                ParentObj.Window:RegisterTransparencyTarget(Holder, 0.04, 0.58)
            end
            New("UICorner", {
                CornerRadius = UDim.new(0, 8),
                Parent = Holder,
            })
            New("UIStroke", {
                Color = function()
                    return Library:GetUiColor("SoftOutline")
                end,
                Transparency = 0.1,
                Parent = Holder,
            })

            local Label = New("TextLabel", {
                FontFace = function()
                    return Library:GetWeightedFont(Enum.FontWeight.Medium)
                end,
                Position = UDim2.fromOffset(10, 0),
                Size = UDim2.new(1, -16, 1, 0),
                BackgroundTransparency = 1,
                Text = "",
                TextColor3 = function()
                    return Library:GetUiColor("ActiveText")
                end,
                TextTruncate = Enum.TextTruncate.AtEnd,
                TextSize = 13,
                TextTransparency = 0.35,
                TextXAlignment = Enum.TextXAlignment.Left,
                Parent = Holder,
            })

            local Checkbox = New("Frame", {
                AnchorPoint = Vector2.new(0, 0.5),
                BackgroundColor3 = function()
                    return Library:GetUiColor("AccentFill")
                end,
                BackgroundTransparency = 0.08,
                Position = UDim2.fromOffset(8, 12),
                Size = UDim2.fromOffset(14, 14),
                SizeConstraint = Enum.SizeConstraint.RelativeYY,
                Parent = Holder,
            })
            New("UICorner", {
                CornerRadius = UDim.new(0, Library.CornerRadius / 2),
                Parent = Checkbox,
            })
            New("UIStroke", {
                Color = function()
                    return Library:GetUiColor("AccentSoft")
                end,
                Parent = Checkbox,
            })

            local CheckImage = New("ImageLabel", {
                Image = CheckIcon and CheckIcon.Url or "",
                ImageColor3 = "FontColor",
                ImageRectOffset = CheckIcon and CheckIcon.ImageRectOffset or Vector2.zero,
                ImageRectSize = CheckIcon and CheckIcon.ImageRectSize or Vector2.zero,
                ImageTransparency = 1,
                Position = UDim2.fromOffset(2, 2),
                Size = UDim2.new(1, -4, 1, -4),
                Parent = Checkbox,
            })

            function KeybindsToggle:Display(State)
                Label.TextTransparency = State and 0 or 0.5
                CheckImage.ImageTransparency = State and 0 or 1
            end

            function KeybindsToggle:SetText(Text)
                Label.Text = Text
            end

            function KeybindsToggle:SetVisibility(Visibility)
                Holder.Visible = Visibility
            end

            function KeybindsToggle:SetNormal(Normal)
                KeybindsToggle.Normal = Normal

                Holder.Active = not Normal
                Label.Position = Normal and UDim2.fromOffset(10, 0) or UDim2.fromOffset(30, 0)
                Label.Size = Normal and UDim2.new(1, -16, 1, 0) or UDim2.new(1, -36, 1, 0)
                Checkbox.Visible = not Normal
            end

            KeyPicker.DoClick = function(...) end --// make luau lsp shut up
            Holder.MouseButton1Click:Connect(function()
                if KeybindsToggle.Normal then
                    return
                end

                KeyPicker.Toggled = not KeyPicker.Toggled
                KeyPicker:DoClick()
            end)

            KeybindsToggle.Holder = Holder
            KeybindsToggle.Label = Label
            KeybindsToggle.Checkbox = Checkbox
            KeybindsToggle.Loaded = true
            table.insert(Library.KeybindToggles, KeybindsToggle)
        end

        local MenuTable = Library:AddContextMenu(Picker, UDim2.fromOffset(62, 0), function()
            return { Picker.AbsoluteSize.X + 1.5, 0.5 }
        end, 1)
        KeyPicker.Menu = MenuTable

        local function IsBoundInput(Input)
            local Key = KeyPicker.Value
            if not Key then
                return false
            end

            return (
                SpecialKeysInput[Input.UserInputType] == Key
                or (Input.UserInputType == Enum.UserInputType.Keyboard and Input.KeyCode.Name == Key)
            )
        end

        local function IsModifierInputForPicker(Input)
            if Input.UserInputType ~= Enum.UserInputType.Keyboard then
                return false
            end

            local ModifierName = ModifiersInput[Input.KeyCode]
            if not ModifierName then
                return false
            end

            return table.find(KeyPicker.Modifiers, ModifierName) ~= nil
        end

        local function ApplySyncState(State, Force)
            if not (KeyPicker.SyncToggleState and SyncTarget) then
                return
            end

            State = if State == nil then KeyPicker:GetState() else State
            if Force or SyncTarget.Value ~= State then
                SyncTarget:SetValue(State)
            end
        end

        local ModeButtons = {}
        for _, Mode in Info.Modes do
            local ModeButton = {}

            local Button = New("TextButton", {
                BackgroundColor3 = function()
                    return Library:GetUiColor("Control")
                end,
                BackgroundTransparency = 1,
                Size = UDim2.new(1, 0, 0, 20),
                Text = Mode,
                TextColor3 = function()
                    return Library:GetUiColor("ActiveText")
                end,
                TextSize = 13,
                TextTransparency = 0.5,
                Parent = MenuTable.Menu,
            })
            New("UICorner", {
                CornerRadius = UDim.new(0, 6),
                Parent = Button,
            })

            function ModeButton:Select()
                for _, Button in ModeButtons do
                    Button:Deselect()
                end

                KeyPicker.Mode = Mode

                Button.BackgroundTransparency = 0
                Button.TextTransparency = 0

                if KeyPicker.SyncToggleState and SyncTarget then
                    if Mode == "Always" then
                        ApplySyncState(true, true)
                    elseif Mode == "Toggle" then
                        KeyPicker.Toggled = SyncTarget.Value
                    end
                end

                MenuTable:Close()
                if KeyPicker.Update then
                    KeyPicker:Update()
                end
            end

            function ModeButton:Deselect()
                KeyPicker.Mode = nil

                Button.BackgroundTransparency = 1
                Button.TextTransparency = 0.5
            end

            Button.MouseButton1Click:Connect(function()
                ModeButton:Select()
            end)

            if KeyPicker.Mode == Mode then
                ModeButton:Select()
            end

            ModeButtons[Mode] = ModeButton
        end

        function KeyPicker:Display(PickerText)
            if Library.Unloaded then
                return
            end

            local X, Y = Library:GetTextBounds(
                PickerText or KeyPicker.DisplayValue,
                Picker.FontFace,
                Picker.TextSize,
                ToggleLabel.AbsoluteSize.X
            )
            Picker.Text = PickerText or KeyPicker.DisplayValue
            Picker.Size = UDim2.fromOffset(math.max(42, X + 14), 20)
        end

        function KeyPicker:Update()
            KeyPicker:Display()

            local State = KeyPicker:GetState()

            if Info.NoUI then
                return
            end

            if KeyPicker.Mode == "Toggle" and SyncTarget and SyncTarget.Disabled then
                KeybindsToggle:SetVisibility(false)
                return
            end

            local ShowToggle = Library.ShowToggleFrameInKeybinds and KeyPicker.Mode == "Toggle"

            if KeybindsToggle.Loaded then
                if ShowToggle then
                    KeybindsToggle:SetNormal(false)
                else
                    KeybindsToggle:SetNormal(true)
                end

                KeybindsToggle:SetText(("[%s] %s (%s)"):format(KeyPicker.DisplayValue, KeyPicker.Text, KeyPicker.Mode))
                KeybindsToggle:SetVisibility(true)
                KeybindsToggle:Display(State)
            end
        end

        function KeyPicker:GetState()
            if KeyPicker.Mode == "Always" then
                return true
            elseif KeyPicker.Mode == "Hold" then
                local Key = KeyPicker.Value
                if Key == "None" then
                    return false
                end

                if not AreModifiersHeld(KeyPicker.Modifiers) then
                    return false
                end

                if SpecialKeys[Key] ~= nil then
                    return UserInputService:IsMouseButtonPressed(SpecialKeys[Key])
                        and not UserInputService:GetFocusedTextBox()
                else
                    return UserInputService:IsKeyDown(Enum.KeyCode[Key]) and not UserInputService:GetFocusedTextBox()
                end
            else
                return KeyPicker.Toggled
            end
        end

        function KeyPicker:OnChanged(Func)
            KeyPicker.Changed = Func
        end

        function KeyPicker:OnClick(Func)
            KeyPicker.Clicked = Func
        end

        function KeyPicker:DoClick()
            if KeyPicker.Mode == "Press" then
                if KeyPicker.Toggled and Info.WaitForCallback == true then
                    return
                end

                KeyPicker.Toggled = true
            end

            Library:SafeCallback(KeyPicker.Callback, KeyPicker.Toggled)
            Library:SafeCallback(KeyPicker.Clicked, KeyPicker.Toggled)

            if KeyPicker.Mode == "Press" then
                KeyPicker.Toggled = false
            end
        end

        function KeyPicker:SetValue(Data)
            local Key, Mode, Modifiers = Data[1], Data[2], Data[3]

            local IsKeyValid, UserInputType = pcall(function()
                if Key == "None" then
                    Key = nil
                    return nil
                end

                if SpecialKeys[Key] == nil then
                    return Enum.KeyCode[Key]
                end

                return SpecialKeys[Key]
            end)

            if Key == nil then
                KeyPicker.Value = "None"
            elseif IsKeyValid then
                KeyPicker.Value = Key
            else
                KeyPicker.Value = "Unknown"
            end

            KeyPicker.Modifiers =
                VerifyModifiers(if typeof(Modifiers) == "table" then Modifiers else KeyPicker.Modifiers)
            KeyPicker.DisplayValue = if GetTableSize(KeyPicker.Modifiers) > 0
                then (table.concat(KeyPicker.Modifiers, " + ") .. " + " .. KeyPicker.Value)
                else KeyPicker.Value

            if ModeButtons[Mode] then
                ModeButtons[Mode]:Select()
            end

            local NewModifiers = ConvertToInputModifiers(KeyPicker.Modifiers)
            Library:SafeCallback(KeyPicker.ChangedCallback, UserInputType, NewModifiers)
            Library:SafeCallback(KeyPicker.Changed, UserInputType, NewModifiers)

            KeyPicker:Update()
        end

        function KeyPicker:SetText(Text)
            KeybindsToggle:SetText(Text)
            KeyPicker:Update()
        end

        function KeyPicker:SetMode(Mode)
            if not ModeButtons[Mode] then
                return
            end

            ModeButtons[Mode]:Select()
        end

        Picker.MouseButton1Click:Connect(function()
            if Picking then
                return
            end

            Picking = true

            Picker.Text = "..."
            Picker.Size = UDim2.fromOffset(29, 18)

            -- Wait for an non modifier key --
            local Input
            local ActiveModifiers = {}

            local GetInput = function()
                Input = UserInputService.InputBegan:Wait()
                return UserInputService:GetFocusedTextBox() ~= nil
            end

            repeat
                task.wait()

                -- Wait for any input --
                Picker.Text = "..."
                Picker.Size = UDim2.fromOffset(29, 18)

                if GetInput() then
                    Picking = false
                    KeyPicker:Update()
                    return
                end

                -- Escape --
                if Input.KeyCode == Enum.KeyCode.Escape then
                    break
                end

                -- Handle modifier keys --
                if IsModifierInput(Input) then
                    local StopLoop = false

                    repeat
                        task.wait()
                        if UserInputService:IsKeyDown(Input.KeyCode) then
                            task.wait(0.075)

                            if UserInputService:IsKeyDown(Input.KeyCode) then
                                -- Add modifier to the key list --
                                if not table.find(ActiveModifiers, ModifiersInput[Input.KeyCode]) then
                                    ActiveModifiers[#ActiveModifiers + 1] = ModifiersInput[Input.KeyCode]
                                    KeyPicker:Display(table.concat(ActiveModifiers, " + ") .. " + ...")
                                end

                                -- Wait for another input --
                                if GetInput() then
                                    StopLoop = true
                                    break -- Invalid Input
                                end

                                -- Escape --
                                if Input.KeyCode == Enum.KeyCode.Escape then
                                    break
                                end

                                -- Stop loop if its a normal key --
                                if not IsModifierInput(Input) then
                                    break
                                end
                            else
                                if not table.find(ActiveModifiers, ModifiersInput[Input.KeyCode]) then
                                    break -- Modifier is meant to be used as a normal key --
                                end
                            end
                        end
                    until false

                    if StopLoop then
                        Picking = false
                        KeyPicker:Update()
                        return
                    end
                end

                break -- Input found, end loop
            until false

            local Key = "Unknown"
            if SpecialKeysInput[Input.UserInputType] ~= nil then
                Key = SpecialKeysInput[Input.UserInputType]
            elseif Input.UserInputType == Enum.UserInputType.Keyboard then
                Key = Input.KeyCode == Enum.KeyCode.Escape and "None" or Input.KeyCode.Name
            end

            ActiveModifiers = if Input.KeyCode == Enum.KeyCode.Escape or Key == "Unknown" then {} else ActiveModifiers

            KeyPicker.Toggled = false
            KeyPicker:SetValue({ Key, KeyPicker.Mode, ActiveModifiers })

            -- RunService.RenderStepped:Wait()
            repeat
                task.wait()
            until not IsInputDown(Input) or UserInputService:GetFocusedTextBox()
            Picking = false
        end)
        Picker.MouseButton2Click:Connect(MenuTable.Toggle)

        Library:GiveSignal(UserInputService.InputBegan:Connect(function(Input: InputObject)
            if Library.Unloaded then
                return
            end

            if
                KeyPicker.Mode == "Always"
                or KeyPicker.Value == "Unknown"
                or KeyPicker.Value == "None"
                or Picking
                or UserInputService:GetFocusedTextBox()
            then
                return
            end

            local Key = KeyPicker.Value
            local HoldingModifiers = AreModifiersHeld(KeyPicker.Modifiers)
            local HoldingKey = false

            if
                Key
                and HoldingModifiers == true
                and IsBoundInput(Input)
            then
                HoldingKey = true
            end

            if KeyPicker.Mode == "Toggle" then
                if HoldingKey then
                    KeyPicker.Toggled = not KeyPicker.Toggled
                    KeyPicker:DoClick()
                    ApplySyncState(KeyPicker.Toggled, true)
                end
            elseif KeyPicker.Mode == "Hold" then
                if HoldingKey then
                    ApplySyncState(true, true)
                end
            elseif KeyPicker.Mode == "Press" then
                if HoldingKey then
                    KeyPicker:DoClick()
                end
            end

            KeyPicker:Update()
        end))

        Library:GiveSignal(UserInputService.InputEnded:Connect(function(Input: InputObject)
            if Library.Unloaded then
                return
            end

            if
                KeyPicker.Value == "Unknown"
                or KeyPicker.Value == "None"
                or Picking
                or UserInputService:GetFocusedTextBox()
            then
                return
            end

            if KeyPicker.Mode == "Hold" and (IsBoundInput(Input) or IsModifierInputForPicker(Input)) then
                ApplySyncState(KeyPicker:GetState(), true)
            end

            KeyPicker:Update()
        end))

        KeyPicker:Update()

        if ParentObj.Addons then
            table.insert(ParentObj.Addons, KeyPicker)
        end

        KeyPicker.Default = KeyPicker.Value
        KeyPicker.DefaultModifiers = table.clone(KeyPicker.Modifiers or {})

        Options[Idx] = KeyPicker

        return self
    end

    local HueSequenceTable = {}
    for Hue = 0, 1, 0.1 do
        table.insert(HueSequenceTable, ColorSequenceKeypoint.new(Hue, Color3.fromHSV(Hue, 1, 1)))
    end
    function Funcs:AddColorPicker(Idx, Info)
        Info = Library:Validate(Info, Templates.ColorPicker)

        local ParentObj = self
        local ToggleLabel = ParentObj.TextLabel

        local ColorPicker = {
            Value = Info.Default,

            Transparency = Info.Transparency or 0,
            Title = Info.Title,

            Callback = Info.Callback,
            Changed = Info.Changed,

            Type = "ColorPicker",
        }
        ColorPicker.Hue, ColorPicker.Sat, ColorPicker.Vib = ColorPicker.Value:ToHSV()

        local Holder = New("TextButton", {
            BackgroundColor3 = ColorPicker.Value,
            BorderColor3 = Library:GetDarkerColor(ColorPicker.Value),
            BorderSizePixel = 1,
            Size = UDim2.fromOffset(18, 18),
            Text = "",
            Parent = ToggleLabel,
        })

        local HolderTransparency = New("ImageLabel", {
            Image = CustomImageManager.GetAsset("TransparencyTexture"),
            ImageTransparency = (1 - ColorPicker.Transparency),
            ScaleType = Enum.ScaleType.Tile,
            Size = UDim2.fromScale(1, 1),
            TileSize = UDim2.fromOffset(9, 9),
            Parent = Holder,
        })

        --// Color Menu \\--
        local ColorMenu = Library:AddContextMenu(
            Holder,
            UDim2.fromOffset(Info.Transparency and 256 or 234, 0),
            function()
                return { 0.5, Holder.AbsoluteSize.Y + 1.5 }
            end,
            1
        )
        ColorMenu.List.Padding = UDim.new(0, 8)
        ColorPicker.ColorMenu = ColorMenu

        New("UIPadding", {
            PaddingBottom = UDim.new(0, 6),
            PaddingLeft = UDim.new(0, 6),
            PaddingRight = UDim.new(0, 6),
            PaddingTop = UDim.new(0, 6),
            Parent = ColorMenu.Menu,
        })

        if typeof(ColorPicker.Title) == "string" then
            New("TextLabel", {
                BackgroundTransparency = 1,
                Size = UDim2.new(1, 0, 0, 8),
                Text = ColorPicker.Title,
                TextSize = 14,
                TextXAlignment = Enum.TextXAlignment.Left,
                Parent = ColorMenu.Menu,
            })
        end

        local ColorHolder = New("Frame", {
            BackgroundTransparency = 1,
            Size = UDim2.new(1, 0, 0, 200),
            Parent = ColorMenu.Menu,
        })
        New("UIListLayout", {
            FillDirection = Enum.FillDirection.Horizontal,
            Padding = UDim.new(0, 6),
            Parent = ColorHolder,
        })

        --// Sat Map
        local SatVipMap = New("ImageButton", {
            BackgroundColor3 = ColorPicker.Value,
            Image = CustomImageManager.GetAsset("SaturationMap"),
            Size = UDim2.fromOffset(200, 200),
            Parent = ColorHolder,
        })

        local SatVibCursor = New("Frame", {
            AnchorPoint = Vector2.new(0.5, 0.5),
            BackgroundColor3 = "WhiteColor",
            Size = UDim2.fromOffset(6, 6),
            Parent = SatVipMap,
        })
        New("UICorner", {
            CornerRadius = UDim.new(1, 0),
            Parent = SatVibCursor,
        })
        New("UIStroke", {
            Color = "DarkColor",
            Parent = SatVibCursor,
        })

        --// Hue
        local HueSelector = New("TextButton", {
            Size = UDim2.fromOffset(16, 200),
            Text = "",
            Parent = ColorHolder,
        })
        New("UIGradient", {
            Color = ColorSequence.new(HueSequenceTable),
            Rotation = 90,
            Parent = HueSelector,
        })

        local HueCursor = New("Frame", {
            AnchorPoint = Vector2.new(0.5, 0.5),
            BackgroundColor3 = "WhiteColor",
            BorderColor3 = "DarkColor",
            BorderSizePixel = 1,
            Position = UDim2.fromScale(0.5, ColorPicker.Hue),
            Size = UDim2.new(1, 2, 0, 1),
            Parent = HueSelector,
        })

        --// Alpha
        local TransparencySelector, TransparencyColor, TransparencyCursor
        if Info.Transparency then
            TransparencySelector = New("ImageButton", {
                Image = CustomImageManager.GetAsset("TransparencyTexture"),
                ScaleType = Enum.ScaleType.Tile,
                Size = UDim2.fromOffset(16, 200),
                TileSize = UDim2.fromOffset(8, 8),
                Parent = ColorHolder,
            })

            TransparencyColor = New("Frame", {
                BackgroundColor3 = ColorPicker.Value,
                Size = UDim2.fromScale(1, 1),
                Parent = TransparencySelector,
            })
            New("UIGradient", {
                Rotation = 90,
                Transparency = NumberSequence.new({
                    NumberSequenceKeypoint.new(0, 0),
                    NumberSequenceKeypoint.new(1, 1),
                }),
                Parent = TransparencyColor,
            })

            TransparencyCursor = New("Frame", {
                AnchorPoint = Vector2.new(0.5, 0.5),
                BackgroundColor3 = "WhiteColor",
                BorderColor3 = "DarkColor",
                BorderSizePixel = 1,
                Position = UDim2.fromScale(0.5, ColorPicker.Transparency),
                Size = UDim2.new(1, 2, 0, 1),
                Parent = TransparencySelector,
            })
        end

        local InfoHolder = New("Frame", {
            BackgroundTransparency = 1,
            Size = UDim2.new(1, 0, 0, 20),
            Parent = ColorMenu.Menu,
        })
        New("UIListLayout", {
            FillDirection = Enum.FillDirection.Horizontal,
            HorizontalFlex = Enum.UIFlexAlignment.Fill,
            Padding = UDim.new(0, 8),
            Parent = InfoHolder,
        })

        local HueBox = New("TextBox", {
            BackgroundColor3 = "MainColor",
            BorderColor3 = "OutlineColor",
            BorderSizePixel = 1,
            ClearTextOnFocus = false,
            Size = UDim2.fromScale(1, 1),
            Text = "#??????",
            TextSize = 14,
            Parent = InfoHolder,
        })

        local RgbBox = New("TextBox", {
            BackgroundColor3 = "MainColor",
            BorderColor3 = "OutlineColor",
            BorderSizePixel = 1,
            ClearTextOnFocus = false,
            Size = UDim2.fromScale(1, 1),
            Text = "?, ?, ?",
            TextSize = 14,
            Parent = InfoHolder,
        })

        --// Context Menu \\--
        local ContextMenu = Library:AddContextMenu(Holder, UDim2.fromOffset(93, 0), function()
            return { Holder.AbsoluteSize.X + 1.5, 0.5 }
        end, 1)
        ColorPicker.ContextMenu = ContextMenu
        do
            local function CreateButton(Text, Func)
                local Button = New("TextButton", {
                    BackgroundTransparency = 1,
                    Size = UDim2.new(1, 0, 0, 21),
                    Text = Text,
                    TextSize = 14,
                    Parent = ContextMenu.Menu,
                })

                Button.MouseButton1Click:Connect(function()
                    Library:SafeCallback(Func)
                    ContextMenu:Close()
                end)
            end

            CreateButton("Copy color", function()
                Library.CopiedColor = { ColorPicker.Value, ColorPicker.Transparency }
            end)

            ColorPicker.SetValueRGB = function(...) end --// make luau lsp shut up
            CreateButton("Paste color", function()
                ColorPicker:SetValueRGB(Library.CopiedColor[1], Library.CopiedColor[2])
            end)

            if setclipboard then
                CreateButton("Copy Hex", function()
                    setclipboard(tostring(ColorPicker.Value:ToHex()))
                end)
                CreateButton("Copy RGB", function()
                    setclipboard(table.concat({
                        math.floor(ColorPicker.Value.R * 255),
                        math.floor(ColorPicker.Value.G * 255),
                        math.floor(ColorPicker.Value.B * 255),
                    }, ", "))
                end)
            end
        end

        --// End \\--

        function ColorPicker:SetHSVFromRGB(Color)
            ColorPicker.Hue, ColorPicker.Sat, ColorPicker.Vib = Color:ToHSV()
        end

        function ColorPicker:Display()
            if Library.Unloaded then
                return
            end

            ColorPicker.Value = Color3.fromHSV(ColorPicker.Hue, ColorPicker.Sat, ColorPicker.Vib)

            Holder.BackgroundColor3 = ColorPicker.Value
            Holder.BorderColor3 = Library:GetDarkerColor(ColorPicker.Value)
            HolderTransparency.ImageTransparency = (1 - ColorPicker.Transparency)

            SatVipMap.BackgroundColor3 = Color3.fromHSV(ColorPicker.Hue, 1, 1)
            if TransparencyColor then
                TransparencyColor.BackgroundColor3 = ColorPicker.Value
            end

            SatVibCursor.Position = UDim2.fromScale(ColorPicker.Sat, 1 - ColorPicker.Vib)
            HueCursor.Position = UDim2.fromScale(0.5, ColorPicker.Hue)
            if TransparencyCursor then
                TransparencyCursor.Position = UDim2.fromScale(0.5, ColorPicker.Transparency)
            end

            HueBox.Text = "#" .. ColorPicker.Value:ToHex()
            RgbBox.Text = table.concat({
                math.floor(ColorPicker.Value.R * 255),
                math.floor(ColorPicker.Value.G * 255),
                math.floor(ColorPicker.Value.B * 255),
            }, ", ")
        end

        function ColorPicker:Update()
            ColorPicker:Display()

            Library:SafeCallback(ColorPicker.Callback, ColorPicker.Value)
            Library:SafeCallback(ColorPicker.Changed, ColorPicker.Value)
        end

        function ColorPicker:OnChanged(Func)
            ColorPicker.Changed = Func
        end

        function ColorPicker:SetValue(HSV, Transparency)
            if typeof(HSV) == "Color3" then
                ColorPicker:SetValueRGB(HSV, Transparency)
                return
            end

            local Color = Color3.fromHSV(HSV[1], HSV[2], HSV[3])
            ColorPicker.Transparency = Info.Transparency and Transparency or 0
            ColorPicker:SetHSVFromRGB(Color)
            ColorPicker:Update()
        end

        function ColorPicker:SetValueRGB(Color, Transparency)
            ColorPicker.Transparency = Info.Transparency and Transparency or 0
            ColorPicker:SetHSVFromRGB(Color)
            ColorPicker:Update()
        end

        Holder.MouseButton1Click:Connect(ColorMenu.Toggle)
        Holder.MouseButton2Click:Connect(ContextMenu.Toggle)

        SatVipMap.InputBegan:Connect(function(Input: InputObject)
            while IsDragInput(Input) do
                local MinX = SatVipMap.AbsolutePosition.X
                local MaxX = MinX + SatVipMap.AbsoluteSize.X
                local LocationX = math.clamp(Mouse.X, MinX, MaxX)

                local MinY = SatVipMap.AbsolutePosition.Y
                local MaxY = MinY + SatVipMap.AbsoluteSize.Y
                local LocationY = math.clamp(Mouse.Y, MinY, MaxY)

                local OldSat = ColorPicker.Sat
                local OldVib = ColorPicker.Vib
                ColorPicker.Sat = (LocationX - MinX) / (MaxX - MinX)
                ColorPicker.Vib = 1 - ((LocationY - MinY) / (MaxY - MinY))

                if ColorPicker.Sat ~= OldSat or ColorPicker.Vib ~= OldVib then
                    ColorPicker:Update()
                end

                RunService.RenderStepped:Wait()
            end
        end)
        HueSelector.InputBegan:Connect(function(Input: InputObject)
            while IsDragInput(Input) do
                local Min = HueSelector.AbsolutePosition.Y
                local Max = Min + HueSelector.AbsoluteSize.Y
                local Location = math.clamp(Mouse.Y, Min, Max)

                local OldHue = ColorPicker.Hue
                ColorPicker.Hue = (Location - Min) / (Max - Min)

                if ColorPicker.Hue ~= OldHue then
                    ColorPicker:Update()
                end

                RunService.RenderStepped:Wait()
            end
        end)
        if TransparencySelector then
            TransparencySelector.InputBegan:Connect(function(Input: InputObject)
                while IsDragInput(Input) do
                    local Min = TransparencySelector.AbsolutePosition.Y
                    local Max = TransparencySelector.AbsolutePosition.Y + TransparencySelector.AbsoluteSize.Y
                    local Location = math.clamp(Mouse.Y, Min, Max)

                    local OldTransparency = ColorPicker.Transparency
                    ColorPicker.Transparency = (Location - Min) / (Max - Min)

                    if ColorPicker.Transparency ~= OldTransparency then
                        ColorPicker:Update()
                    end

                    RunService.RenderStepped:Wait()
                end
            end)
        end

        HueBox.FocusLost:Connect(function(Enter)
            if not Enter then
                return
            end

            local Success, Color = pcall(Color3.fromHex, HueBox.Text)
            if Success and typeof(Color) == "Color3" then
                ColorPicker.Hue, ColorPicker.Sat, ColorPicker.Vib = Color:ToHSV()
            end

            ColorPicker:Update()
        end)
        RgbBox.FocusLost:Connect(function(Enter)
            if not Enter then
                return
            end

            local R, G, B = RgbBox.Text:match("(%d+),%s*(%d+),%s*(%d+)")
            if R and G and B then
                ColorPicker:SetHSVFromRGB(Color3.fromRGB(R, G, B))
            end

            ColorPicker:Update()
        end)

        ColorPicker:Display()

        if ParentObj.Addons then
            table.insert(ParentObj.Addons, ColorPicker)
        end

        ColorPicker.Default = ColorPicker.Value

        Options[Idx] = ColorPicker

        return self
    end

    BaseAddons.__index = Funcs
    BaseAddons.__namecall = function(_, Key, ...)
        return Funcs[Key](...)
    end
end

local BaseGroupbox = {}
do
    local Funcs = {}

    function Funcs:AddDivider(...)
        local Params = select(1, ...)
        local Text
        local MarginTop = 0
        local MarginBottom = 0

        if typeof(Params) == "table" then
            Text = Params.Text
            MarginTop = Params.MarginTop or Params.Margin or 0
            MarginBottom = Params.MarginBottom or Params.Margin or 0
        elseif typeof(Params) == "string" then
            Text = Params
        end

        local Groupbox = self
        local Container = Groupbox.Container

        local Holder = New("Frame", {
            BackgroundTransparency = 1,
            Size = UDim2.new(1, 0, 0, 6 + MarginTop + MarginBottom),
            Parent = Container,
        })

        local InnerHolder = New("Frame", {
            BackgroundTransparency = 1,
            Size = UDim2.new(1, 0, 1, 0),
            Parent = Holder,
        })

        New("UIPadding", {
            PaddingTop = UDim.new(0, MarginTop),
            PaddingBottom = UDim.new(0, MarginBottom),
            Parent = Holder,
        })

        if Text then
            local TextLabel = New("TextLabel", {
                AutomaticSize = Enum.AutomaticSize.X,
                BackgroundTransparency = 1,
                FontFace = function()
                    return Library:GetWeightedFont(Enum.FontWeight.Medium)
                end,
                Size = UDim2.fromScale(1, 0),
                Text = Text,
                TextColor3 = function()
                    return Library:GetUiColor("SubtleText")
                end,
                TextSize = 13,
                TextXAlignment = Enum.TextXAlignment.Center,
                Parent = InnerHolder,
            })

            local X, _ = Library:GetTextBounds(Text, TextLabel.FontFace, TextLabel.TextSize, TextLabel.AbsoluteSize.X)
            local SizeX = X // 2 + 10

            New("Frame", {
                AnchorPoint = Vector2.new(0, 0.5),
                BackgroundColor3 = function()
                    return Library:GetUiColor("Divider")
                end,
                Position = UDim2.fromScale(0, 0.5),
                Size = UDim2.new(0.5, -SizeX, 0, 2),
                Parent = InnerHolder,
            })
            New("Frame", {
                AnchorPoint = Vector2.new(1, 0.5),
                BackgroundColor3 = function()
                    return Library:GetUiColor("Divider")
                end,
                Position = UDim2.fromScale(1, 0.5),
                Size = UDim2.new(0.5, -SizeX, 0, 2),
                Parent = InnerHolder,
            })
        else
            New("Frame", {
                AnchorPoint = Vector2.new(0, 0.5),
                BackgroundColor3 = function()
                    return Library:GetUiColor("Divider")
                end,
                Position = UDim2.fromScale(0, 0.5),
                Size = UDim2.new(1, 0, 0, 2),
                Parent = InnerHolder,
            })
        end

        Groupbox:Resize()

        table.insert(Groupbox.Elements, {
            Holder = Holder,
            Type = "Divider",
        })
    end

    function Funcs:AddLabel(...)
        local Data = {}
        local Addons = {}

        local First = select(1, ...)
        local Second = select(2, ...)

        if typeof(First) == "table" or typeof(Second) == "table" then
            local Params = typeof(First) == "table" and First or Second

            Data.Text = Params.Text or ""
            Data.DoesWrap = Params.DoesWrap or false
            Data.Size = Params.Size or 14
            Data.Visible = Params.Visible or true
            Data.Idx = typeof(Second) == "table" and First or nil
        else
            Data.Text = First or ""
            Data.DoesWrap = Second or false
            Data.Size = 14
            Data.Visible = true
            Data.Idx = select(3, ...) or nil
        end

        local Groupbox = self
        local Container = Groupbox.Container

        local Label = {
            Text = Data.Text,
            DoesWrap = Data.DoesWrap,

            Addons = Addons,

            Visible = Data.Visible,
            Type = "Label",
        }

        local TextLabel = New("TextLabel", {
            BackgroundTransparency = 1,
            ClipsDescendants = false,
            FontFace = function()
                return Library:GetWeightedFont(Enum.FontWeight.Medium)
            end,
            Size = UDim2.new(1, 0, 0, 20),
            Text = Label.Text,
            TextColor3 = function()
                return Library:GetUiColor("MutedText")
            end,
            TextSize = math.max(Data.Size, 15),
            TextTruncate = Label.DoesWrap and Enum.TextTruncate.None or Enum.TextTruncate.AtEnd,
            TextWrapped = Label.DoesWrap,
            TextXAlignment = Groupbox.IsKeyTab and Enum.TextXAlignment.Center or Enum.TextXAlignment.Left,
            TextYAlignment = Label.DoesWrap and Enum.TextYAlignment.Top or Enum.TextYAlignment.Center,
            Parent = Container,
        })

        function Label:SetVisible(Visible: boolean)
            Label.Visible = Visible

            TextLabel.Visible = Label.Visible
            Groupbox:Resize()
        end

        function Label:SetText(Text: string)
            Label.Text = Text
            TextLabel.Text = Text

            if Label.DoesWrap then
                local AvailableWidth = math.max(1, TextLabel.AbsoluteSize.X)
                local _, Y = Library:GetTextBounds(Label.Text, TextLabel.FontFace, TextLabel.TextSize, AvailableWidth)
                TextLabel.Size = UDim2.new(1, 0, 0, Y + 4)
            end

            Groupbox:Resize()
        end

        if Label.DoesWrap then
            local AvailableWidth = math.max(1, TextLabel.AbsoluteSize.X)
            local _, Y = Library:GetTextBounds(Label.Text, TextLabel.FontFace, TextLabel.TextSize, AvailableWidth)
            TextLabel.Size = UDim2.new(1, 0, 0, Y + 4)

            local Last = TextLabel.AbsoluteSize
            TextLabel:GetPropertyChangedSignal("AbsoluteSize"):Connect(function()
                if TextLabel.AbsoluteSize == Last then
                    return
                end

                local AvailableWidth = math.max(1, TextLabel.AbsoluteSize.X)
                local _, Y = Library:GetTextBounds(Label.Text, TextLabel.FontFace, TextLabel.TextSize, AvailableWidth)
                TextLabel.Size = UDim2.new(1, 0, 0, Y + 4)

                Last = TextLabel.AbsoluteSize
                Groupbox:Resize()
            end)
        else
            New("UIListLayout", {
                FillDirection = Enum.FillDirection.Horizontal,
                HorizontalAlignment = Enum.HorizontalAlignment.Right,
                Padding = UDim.new(0, 6),
                Parent = TextLabel,
            })
        end

        Groupbox:Resize()

        Label.TextLabel = TextLabel
        Label.Container = Container
        Label.Window = Groupbox.Window
        if not Data.DoesWrap then
            setmetatable(Label, BaseAddons)
        end

        Label.Holder = TextLabel
        table.insert(Groupbox.Elements, Label)

        if Data.Idx then
            Labels[Data.Idx] = Label
        else
            table.insert(Labels, Label)
        end

        return Label
    end

    function Funcs:AddButton(...)
        local function GetInfo(...)
            local Info = {}

            local First = select(1, ...)
            local Second = select(2, ...)

            if typeof(First) == "table" or typeof(Second) == "table" then
                local Params = typeof(First) == "table" and First or Second

                Info.Text = Params.Text or ""
                Info.Func = Params.Func or Params.Callback or function() end
                Info.DoubleClick = Params.DoubleClick

                Info.Tooltip = Params.Tooltip
                Info.DisabledTooltip = Params.DisabledTooltip

                Info.Risky = Params.Risky or false
                Info.Disabled = Params.Disabled or false
                Info.Visible = Params.Visible or true
                Info.Idx = typeof(Second) == "table" and First or nil
            else
                Info.Text = First or ""
                Info.Func = Second or function() end
                Info.DoubleClick = false

                Info.Tooltip = nil
                Info.DisabledTooltip = nil

                Info.Risky = false
                Info.Disabled = false
                Info.Visible = true
                Info.Idx = select(3, ...) or nil
            end

            return Info
        end
        local Info = GetInfo(...)

        local Groupbox = self
        local Container = Groupbox.Container

        local Button = {
            Text = Info.Text,
            Func = Info.Func,
            DoubleClick = Info.DoubleClick,

            Tooltip = Info.Tooltip,
            DisabledTooltip = Info.DisabledTooltip,
            TooltipTable = nil,

            Risky = Info.Risky,
            Disabled = Info.Disabled,
            Visible = Info.Visible,

            Tween = nil,
            Type = "Button",
        }

        local Holder = New("Frame", {
            BackgroundTransparency = 1,
            Size = UDim2.new(1, 0, 0, 20),
            Parent = Container,
        })

        New("UIListLayout", {
            FillDirection = Enum.FillDirection.Horizontal,
            HorizontalFlex = Enum.UIFlexAlignment.Fill,
            Padding = UDim.new(0, 4),
            Parent = Holder,
        })

        local function CreateButton(Button)
            local Base = New("TextButton", {
                Active = not Button.Disabled,
                BackgroundColor3 = function()
                    if Button.Risky then
                        return Library:LerpColor(Library.Scheme.RedColor, Library:GetUiColor("Control"), 0.82)
                    end

                    return Library:GetUiColor("Control")
                end,
                FontFace = function()
                    return Library:GetWeightedFont(Enum.FontWeight.Medium)
                end,
                Size = UDim2.fromScale(1, 1),
                Text = Button.Text,
                TextColor3 = function()
                    return Button.Risky and Library.Scheme.RedColor or Library:GetUiColor("ActiveText")
                end,
                TextSize = 13,
                TextTransparency = Button.Disabled and 0.55 or 0,
                Visible = Button.Visible,
                Parent = Holder,
            })
            New("UICorner", {
                CornerRadius = UDim.new(0, 6),
                Parent = Base,
            })

            local Stroke = New("UIStroke", {
                Color = function()
                    return Button.Risky and Library:LerpColor(Library.Scheme.RedColor, Library:GetUiColor("SoftOutline"), 0.45)
                        or Library:GetUiColor("SoftOutline")
                end,
                Transparency = Button.Disabled and 0.45 or 0,
                Parent = Base,
            })

            return Base, Stroke
        end

        local function InitEvents(Button)
            Button.Base.MouseEnter:Connect(function()
                if Button.Disabled then
                    return
                end

                Button.Tween = TweenService:Create(Button.Base, Library.TweenInfo, {
                    BackgroundTransparency = 0.06,
                })
                Button.Tween:Play()
            end)
            Button.Base.MouseLeave:Connect(function()
                if Button.Disabled then
                    return
                end

                Button.Tween = TweenService:Create(Button.Base, Library.TweenInfo, {
                    BackgroundTransparency = 0,
                })
                Button.Tween:Play()
            end)
            Button.Base.MouseButton1Down:Connect(function()
                if Button.Disabled then
                    return
                end
                StopTween(Button.Tween)
                Button.Tween = TweenService:Create(Button.Base, TweenInfo.new(0.08, Enum.EasingStyle.Quad, Enum.EasingDirection.Out), {
                    BackgroundTransparency = 0.12,
                })
                Button.Tween:Play()
            end)
            Button.Base.MouseButton1Up:Connect(function()
                if Button.Disabled then
                    return
                end
                StopTween(Button.Tween)
                Button.Tween = TweenService:Create(Button.Base, TweenInfo.new(0.12, Enum.EasingStyle.Quad, Enum.EasingDirection.Out), {
                    BackgroundTransparency = 0.03,
                })
                Button.Tween:Play()
            end)

            Button.Base.MouseButton1Click:Connect(function()
                if Button.Disabled or Button.Locked then
                    return
                end

                if Button.DoubleClick then
                    Button.Locked = true

                    Button.Base.Text = "Are you sure?"
                    Button.Base.TextColor3 = Library.Scheme.AccentColor
                    Library.Registry[Button.Base].TextColor3 = "AccentColor"

                    local Clicked = WaitForEvent(Button.Base.MouseButton1Click, 0.5)

                    Button.Base.Text = Button.Text
                    Button.Base.TextColor3 = Button.Risky and Library.Scheme.RedColor or Library.Scheme.FontColor
                    Library.Registry[Button.Base].TextColor3 = Button.Risky and "RedColor" or "FontColor"

                    if Clicked then
                        Library:SafeCallback(Button.Func)
                    end

                    RunService.RenderStepped:Wait() --// Mouse Button fires without waiting (i hate roblox)
                    Button.Locked = false
                    return
                end

                Library:SafeCallback(Button.Func)
            end)
        end

        Button.Base, Button.Stroke = CreateButton(Button)
        if Groupbox.Window and Groupbox.Window.RegisterTransparencyTarget then
            Groupbox.Window:RegisterTransparencyTarget(Button.Base, 0.04, 0.62)
        end
        InitEvents(Button)

        function Button:AddButton(...)
            local Info = GetInfo(...)

            local SubButton = {
                Text = Info.Text,
                Func = Info.Func,
                DoubleClick = Info.DoubleClick,

                Tooltip = Info.Tooltip,
                DisabledTooltip = Info.DisabledTooltip,
                TooltipTable = nil,

                Risky = Info.Risky,
                Disabled = Info.Disabled,
                Visible = Info.Visible,

                Tween = nil,
                Type = "SubButton",
            }

            Button.SubButton = SubButton
            SubButton.Base, SubButton.Stroke = CreateButton(SubButton)
            if Groupbox.Window and Groupbox.Window.RegisterTransparencyTarget then
                Groupbox.Window:RegisterTransparencyTarget(SubButton.Base, 0.04, 0.62)
            end
            InitEvents(SubButton)

            function SubButton:UpdateColors()
                if Library.Unloaded then
                    return
                end

                StopTween(SubButton.Tween)

                SubButton.Base.BackgroundTransparency = SubButton.Disabled and 0.35 or 0
                SubButton.Base.TextTransparency = SubButton.Disabled and 0.55 or 0
                SubButton.Stroke.Transparency = SubButton.Disabled and 0.45 or 0
            end

            function SubButton:SetDisabled(Disabled: boolean)
                SubButton.Disabled = Disabled

                if SubButton.TooltipTable then
                    SubButton.TooltipTable.Disabled = SubButton.Disabled
                end

                SubButton.Base.Active = not SubButton.Disabled
                SubButton:UpdateColors()
            end

            function SubButton:SetVisible(Visible: boolean)
                SubButton.Visible = Visible

                SubButton.Base.Visible = SubButton.Visible
                Groupbox:Resize()
            end

            function SubButton:SetText(Text: string)
                SubButton.Text = Text
                SubButton.Base.Text = Text
            end

            if typeof(SubButton.Tooltip) == "string" or typeof(SubButton.DisabledTooltip) == "string" then
                SubButton.TooltipTable =
                    Library:AddTooltip(SubButton.Tooltip, SubButton.DisabledTooltip, SubButton.Base)
                SubButton.TooltipTable.Disabled = SubButton.Disabled
            end

            if SubButton.Risky then
                SubButton.Base.TextColor3 = Library.Scheme.RedColor
                Library.Registry[SubButton.Base].TextColor3 = "RedColor"
            end

            SubButton:UpdateColors()

            if Info.Idx then
                Buttons[Info.Idx] = SubButton
            else
                table.insert(Buttons, SubButton)
            end

            return SubButton
        end

        function Button:UpdateColors()
            if Library.Unloaded then
                return
            end

            StopTween(Button.Tween)

            Button.Base.BackgroundTransparency = Button.Disabled and 0.35 or 0
            Button.Base.TextTransparency = Button.Disabled and 0.55 or 0
            Button.Stroke.Transparency = Button.Disabled and 0.45 or 0
        end

        function Button:SetDisabled(Disabled: boolean)
            Button.Disabled = Disabled

            if Button.TooltipTable then
                Button.TooltipTable.Disabled = Button.Disabled
            end

            Button.Base.Active = not Button.Disabled
            Button:UpdateColors()
        end

        function Button:SetVisible(Visible: boolean)
            Button.Visible = Visible

            Holder.Visible = Button.Visible
            Groupbox:Resize()
        end

        function Button:SetText(Text: string)
            Button.Text = Text
            Button.Base.Text = Text
        end

        if typeof(Button.Tooltip) == "string" or typeof(Button.DisabledTooltip) == "string" then
            Button.TooltipTable = Library:AddTooltip(Button.Tooltip, Button.DisabledTooltip, Button.Base)
            Button.TooltipTable.Disabled = Button.Disabled
        end

        if Button.Risky then
            Button.Base.TextColor3 = Library.Scheme.RedColor
            Library.Registry[Button.Base].TextColor3 = "RedColor"
        end

        Button:UpdateColors()
        Groupbox:Resize()

        Button.Holder = Holder
        table.insert(Groupbox.Elements, Button)

        if Info.Idx then
            Buttons[Info.Idx] = Button
        else
            table.insert(Buttons, Button)
        end

        return Button
    end

    function Funcs:AddCheckbox(Idx, Info)
        Info = Library:Validate(Info, Templates.Toggle)

        local Groupbox = self
        local Container = Groupbox.Container

        local Toggle = {
            Text = Info.Text,
            Value = Info.Default,

            Tooltip = Info.Tooltip,
            DisabledTooltip = Info.DisabledTooltip,
            TooltipTable = nil,

            Callback = Info.Callback,
            Changed = Info.Changed,

            Risky = Info.Risky,
            Disabled = Info.Disabled,
            Visible = Info.Visible,
            Addons = {},

            Type = "Toggle",
        }

        local Button = New("TextButton", {
            Active = not Toggle.Disabled,
            BackgroundTransparency = 1,
            Size = UDim2.new(1, 0, 0, 22),
            Text = "",
            Visible = Toggle.Visible,
            Parent = Container,
        })

        local Label = New("TextLabel", {
            BackgroundTransparency = 1,
            FontFace = function()
                return Library:GetWeightedFont(Enum.FontWeight.Medium)
            end,
            Position = UDim2.fromOffset(26, 0),
            Size = UDim2.new(1, -26, 1, 0),
            Text = Toggle.Text,
            TextColor3 = function()
                return Library:GetUiColor("MutedText")
            end,
            TextSize = 14,
            TextXAlignment = Enum.TextXAlignment.Left,
            Parent = Button,
        })

        New("UIListLayout", {
            FillDirection = Enum.FillDirection.Horizontal,
            HorizontalAlignment = Enum.HorizontalAlignment.Right,
            Padding = UDim.new(0, 6),
            Parent = Label,
        })

        local Checkbox = New("Frame", {
            BackgroundColor3 = function()
                return Library:GetUiColor("Control")
            end,
            Size = UDim2.fromOffset(18, 18),
            SizeConstraint = Enum.SizeConstraint.RelativeYY,
            Parent = Button,
        })
        New("UICorner", {
            CornerRadius = UDim.new(0, 6),
            Parent = Checkbox,
        })

        local CheckboxStroke = New("UIStroke", {
            Color = function()
                return Library:GetUiColor("SoftOutline")
            end,
            Parent = Checkbox,
        })

        local CheckImage = New("ImageLabel", {
            Image = CheckIcon and CheckIcon.Url or "",
            ImageColor3 = "FontColor",
            ImageRectOffset = CheckIcon and CheckIcon.ImageRectOffset or Vector2.zero,
            ImageRectSize = CheckIcon and CheckIcon.ImageRectSize or Vector2.zero,
            ImageTransparency = 1,
            Position = UDim2.fromOffset(2, 2),
            Size = UDim2.new(1, -4, 1, -4),
            Parent = Checkbox,
        })

        function Toggle:UpdateColors()
            Toggle:Display()
        end

        function Toggle:Display()
            if Library.Unloaded then
                return
            end

            CheckboxStroke.Transparency = Toggle.Disabled and 0.45 or 0

            if Toggle.Disabled then
                Label.FontFace = Library:GetWeightedFont(Enum.FontWeight.Medium)
                Label.TextTransparency = 0.55
                CheckImage.ImageTransparency = Toggle.Value and 0.55 or 1

                Checkbox.BackgroundColor3 = Library:GetUiColor("Control")
                Library.Registry[Checkbox].BackgroundColor3 = function()
                    return Library:GetUiColor("Control")
                end

                return
            end

            Label.FontFace = Library:GetWeightedFont(Toggle.Value and Enum.FontWeight.Bold or Enum.FontWeight.Medium)
            Label.TextColor3 = Toggle.Value and Library:GetUiColor("ActiveText") or Library:GetUiColor("MutedText")
            Label.TextTransparency = 0
            TweenService:Create(CheckImage, Library.TweenInfo, {
                ImageTransparency = Toggle.Value and 0 or 1,
            }):Play()

            Checkbox.BackgroundColor3 = Toggle.Value and Library:GetUiColor("AccentFill") or Library:GetUiColor("Control")
            Library.Registry[Checkbox].BackgroundColor3 = function()
                return Toggle.Value and Library:GetUiColor("AccentFill") or Library:GetUiColor("Control")
            end
        end

        function Toggle:OnChanged(Func)
            Toggle.Changed = Func
        end

        function Toggle:SetValue(Value)
            if Toggle.Disabled then
                return
            end

            Toggle.Value = Value
            Toggle:Display()

            for _, Addon in Toggle.Addons do
                if Addon.Type == "KeyPicker" and Addon.SyncToggleState then
                    Addon.Toggled = Toggle.Value
                    Addon:Update()
                end
            end

            Library:UpdateDependencyBoxes()
            Library:SafeCallback(Toggle.Callback, Toggle.Value)
            Library:SafeCallback(Toggle.Changed, Toggle.Value)
        end

        function Toggle:SetDisabled(Disabled: boolean)
            Toggle.Disabled = Disabled

            if Toggle.TooltipTable then
                Toggle.TooltipTable.Disabled = Toggle.Disabled
            end

            for _, Addon in Toggle.Addons do
                if Addon.Type == "KeyPicker" and Addon.SyncToggleState then
                    Addon:Update()
                end
            end

            Button.Active = not Toggle.Disabled
            Toggle:Display()
        end

        function Toggle:SetVisible(Visible: boolean)
            Toggle.Visible = Visible

            Button.Visible = Toggle.Visible
            Groupbox:Resize()
        end

        function Toggle:SetText(Text: string)
            Toggle.Text = Text
            Label.Text = Text
        end

        Button.MouseButton1Click:Connect(function()
            if Toggle.Disabled then
                return
            end

            Toggle:SetValue(not Toggle.Value)
        end)

        if typeof(Toggle.Tooltip) == "string" or typeof(Toggle.DisabledTooltip) == "string" then
            Toggle.TooltipTable = Library:AddTooltip(Toggle.Tooltip, Toggle.DisabledTooltip, Button)
            Toggle.TooltipTable.Disabled = Toggle.Disabled
        end

        if Toggle.Risky then
            Label.TextColor3 = Library.Scheme.RedColor
            Library.Registry[Label].TextColor3 = "RedColor"
        end

        Toggle:Display()
        Groupbox:Resize()

        Toggle.TextLabel = Label
        Toggle.Container = Container
        Toggle.Window = Groupbox.Window
        setmetatable(Toggle, BaseAddons)

        Toggle.Holder = Button
        table.insert(Groupbox.Elements, Toggle)

        Toggle.Default = Toggle.Value

        Toggles[Idx] = Toggle

        return Toggle
    end

    function Funcs:AddToggle(Idx, Info)
        if Library.ForceCheckbox then
            return Funcs.AddCheckbox(self, Idx, Info)
        end

        Info = Library:Validate(Info, Templates.Toggle)

        local Groupbox = self
        local Container = Groupbox.Container

        local Toggle = {
            Text = Info.Text,
            Value = Info.Default,

            Tooltip = Info.Tooltip,
            DisabledTooltip = Info.DisabledTooltip,
            TooltipTable = nil,

            Callback = Info.Callback,
            Changed = Info.Changed,

            Risky = Info.Risky,
            Disabled = Info.Disabled,
            Visible = Info.Visible,
            Addons = {},

            Type = "Toggle",
        }

        local Button = New("TextButton", {
            Active = not Toggle.Disabled,
            BackgroundTransparency = 1,
            Size = UDim2.new(1, 0, 0, 24),
            Text = "",
            Visible = Toggle.Visible,
            Parent = Container,
        })

        local Label = New("TextLabel", {
            BackgroundTransparency = 1,
            FontFace = function()
                return Library:GetWeightedFont(Enum.FontWeight.Medium)
            end,
            Size = UDim2.new(1, -42, 1, 0),
            Text = Toggle.Text,
            TextColor3 = function()
                return Library:GetUiColor("MutedText")
            end,
            TextSize = 14,
            TextXAlignment = Enum.TextXAlignment.Left,
            Parent = Button,
        })

        New("UIListLayout", {
            FillDirection = Enum.FillDirection.Horizontal,
            HorizontalAlignment = Enum.HorizontalAlignment.Right,
            Padding = UDim.new(0, 4),
            Parent = Label,
        })

        local Switch = New("Frame", {
            AnchorPoint = Vector2.new(1, 0),
            BackgroundColor3 = function()
                return Library:GetUiColor("Control")
            end,
            Position = UDim2.fromScale(1, 0),
            Size = UDim2.fromOffset(32, 18),
            Parent = Button,
        })
        if Groupbox.Window and Groupbox.Window.RegisterTransparencyTarget then
            Groupbox.Window:RegisterTransparencyTarget(Switch, 0.04, 0.58)
        end
        New("UICorner", {
            CornerRadius = UDim.new(1, 0),
            Parent = Switch,
        })
        New("UIPadding", {
            PaddingBottom = UDim.new(0, 2),
            PaddingLeft = UDim.new(0, 2),
            PaddingRight = UDim.new(0, 2),
            PaddingTop = UDim.new(0, 2),
            Parent = Switch,
        })
        local SwitchStroke = New("UIStroke", {
            Color = function()
                return Library:GetUiColor("SoftOutline")
            end,
            Parent = Switch,
        })

        local Ball = New("Frame", {
            BackgroundColor3 = function()
                return Library:GetUiColor("ActiveText")
            end,
            Size = UDim2.fromScale(1, 1),
            SizeConstraint = Enum.SizeConstraint.RelativeYY,
            Parent = Switch,
        })
        New("UICorner", {
            CornerRadius = UDim.new(1, 0),
            Parent = Ball,
        })

        function Toggle:UpdateColors()
            Toggle:Display()
        end

        function Toggle:Display()
            if Library.Unloaded then
                return
            end

            local Offset = Toggle.Value and 1 or 0
            local SwitchColor = Toggle.Value and Library:GetUiColor("AccentFill") or Library:GetUiColor("Control")
            local StrokeColor = Toggle.Value and Library:GetUiColor("AccentSoft") or Library:GetUiColor("SoftOutline")

            Switch.BackgroundTransparency = Toggle.Disabled and 0.45 or 0
            SwitchStroke.Transparency = Toggle.Disabled and 0.45 or 0

            Library.Registry[Switch].BackgroundColor3 = function()
                return Toggle.Value and Library:GetUiColor("AccentFill") or Library:GetUiColor("Control")
            end
            Library.Registry[SwitchStroke].Color = function()
                return Toggle.Value and Library:GetUiColor("AccentSoft") or Library:GetUiColor("SoftOutline")
            end

            if Toggle.Disabled then
                Label.FontFace = Library:GetWeightedFont(Enum.FontWeight.Medium)
                Label.TextTransparency = 0.55
                Switch.BackgroundColor3 = SwitchColor
                SwitchStroke.Color = StrokeColor
                Ball.AnchorPoint = Vector2.new(Offset, 0)
                Ball.Position = UDim2.fromScale(Offset, 0)

                Ball.BackgroundColor3 = Library:GetUiColor("SubtleText")
                Library.Registry[Ball].BackgroundColor3 = function()
                    return Library:GetUiColor("SubtleText")
                end

                return
            end

            Label.FontFace = Library:GetWeightedFont(Toggle.Value and Enum.FontWeight.Bold or Enum.FontWeight.Medium)
            Label.TextColor3 = Toggle.Value and Library:GetUiColor("ActiveText") or Library:GetUiColor("MutedText")
            Label.TextTransparency = 0

            StopTween(Toggle.SwitchTween)
            StopTween(Toggle.SwitchStrokeTween)
            StopTween(Toggle.BallTween)
            Toggle.SwitchTween = TweenService:Create(Switch, Library.TweenInfo, {
                BackgroundColor3 = SwitchColor,
                BackgroundTransparency = 0,
            })
            Toggle.SwitchStrokeTween = TweenService:Create(SwitchStroke, Library.TweenInfo, {
                Color = StrokeColor,
                Transparency = 0,
            })
            Toggle.BallTween = TweenService:Create(Ball, TweenInfo.new(0.12, Enum.EasingStyle.Quart, Enum.EasingDirection.Out), {
                AnchorPoint = Vector2.new(Offset, 0),
                Position = UDim2.fromScale(Offset, 0),
            })
            Toggle.SwitchTween:Play()
            Toggle.SwitchStrokeTween:Play()
            Toggle.BallTween:Play()

            Ball.BackgroundColor3 = Library:GetUiColor("ActiveText")
            Library.Registry[Ball].BackgroundColor3 = function()
                return Library:GetUiColor("ActiveText")
            end
        end

        function Toggle:OnChanged(Func)
            Toggle.Changed = Func
        end

        function Toggle:SetValue(Value)
            if Toggle.Disabled then
                return
            end

            Toggle.Value = Value
            Toggle:Display()

            for _, Addon in Toggle.Addons do
                if Addon.Type == "KeyPicker" and Addon.SyncToggleState then
                    Addon.Toggled = Toggle.Value
                    Addon:Update()
                end
            end

            Library:UpdateDependencyBoxes()
            Library:SafeCallback(Toggle.Callback, Toggle.Value)
            Library:SafeCallback(Toggle.Changed, Toggle.Value)
        end

        function Toggle:SetDisabled(Disabled: boolean)
            Toggle.Disabled = Disabled

            if Toggle.TooltipTable then
                Toggle.TooltipTable.Disabled = Toggle.Disabled
            end

            for _, Addon in Toggle.Addons do
                if Addon.Type == "KeyPicker" and Addon.SyncToggleState then
                    Addon:Update()
                end
            end

            Button.Active = not Toggle.Disabled
            Toggle:Display()
        end

        function Toggle:SetVisible(Visible: boolean)
            Toggle.Visible = Visible

            Button.Visible = Toggle.Visible
            Groupbox:Resize()
        end

        function Toggle:SetText(Text: string)
            Toggle.Text = Text
            Label.Text = Text
        end

        Button.MouseButton1Click:Connect(function()
            if Toggle.Disabled then
                return
            end

            Toggle:SetValue(not Toggle.Value)
        end)

        if typeof(Toggle.Tooltip) == "string" or typeof(Toggle.DisabledTooltip) == "string" then
            Toggle.TooltipTable = Library:AddTooltip(Toggle.Tooltip, Toggle.DisabledTooltip, Button)
            Toggle.TooltipTable.Disabled = Toggle.Disabled
        end

        if Toggle.Risky then
            Label.TextColor3 = Library.Scheme.RedColor
            Library.Registry[Label].TextColor3 = "RedColor"
        end

        Toggle:Display()
        Groupbox:Resize()

        Toggle.TextLabel = Label
        Toggle.Container = Container
        setmetatable(Toggle, BaseAddons)

        Toggle.Holder = Button
        table.insert(Groupbox.Elements, Toggle)

        Toggle.Default = Toggle.Value

        Toggles[Idx] = Toggle

        return Toggle
    end

    function Funcs:AddInput(Idx, Info)
        Info = Library:Validate(Info, Templates.Input)

        local Groupbox = self
        local Container = Groupbox.Container

        local Input = {
            Text = Info.Text,
            Value = Info.Default,

            Finished = Info.Finished,
            Numeric = Info.Numeric,
            MultiLine = Info.MultiLine,
            Height = Info.Height,
            ClearTextOnFocus = Info.ClearTextOnFocus,
            Placeholder = Info.Placeholder,
            AllowEmpty = Info.AllowEmpty,
            EmptyReset = Info.EmptyReset,
            Compact = Info.Compact,
            ControlWidth = Info.ControlWidth,

            Tooltip = Info.Tooltip,
            DisabledTooltip = Info.DisabledTooltip,
            TooltipTable = nil,

            Callback = Info.Callback,
            Changed = Info.Changed,

            Disabled = Info.Disabled,
            Visible = Info.Visible,

            Type = "Input",
        }

        local ControlWidth = Input.ControlWidth or 108
        local BoxHeight = Input.Compact and 22 or (Input.Height or (Input.MultiLine and 72 or 22))
        local HolderHeight = Input.Compact and 28 or (14 + 4 + BoxHeight)

        local Holder = New("Frame", {
            BackgroundTransparency = 1,
            Size = UDim2.new(1, 0, 0, HolderHeight),
            Visible = Input.Visible,
            Parent = Container,
        })

        local Label = New("TextLabel", {
            BackgroundTransparency = 1,
            FontFace = function()
                return Library:GetWeightedFont(Enum.FontWeight.Medium)
            end,
            Size = Input.Compact and UDim2.new(1, -(ControlWidth + 10), 1, 0) or UDim2.new(1, 0, 0, 14),
            Text = Input.Text,
            TextColor3 = function()
                return Library:GetUiColor("MutedText")
            end,
            TextSize = 14,
            TextXAlignment = Enum.TextXAlignment.Left,
            Parent = Holder,
        })

        local Box = New("TextBox", {
            AnchorPoint = Input.Compact and Vector2.new(1, 0.5) or Vector2.new(0, 1),
            BackgroundColor3 = function()
                return Library:GetUiColor("Control")
            end,
            BorderSizePixel = 0,
            ClearTextOnFocus = not Input.Disabled and Input.ClearTextOnFocus,
            ClipsDescendants = true,
            FontFace = function()
                return Library:GetWeightedFont(Enum.FontWeight.Medium)
            end,
            PlaceholderColor3 = function()
                return Library:GetUiColor("SubtleText")
            end,
            PlaceholderText = Input.Placeholder,
            Position = Input.Compact and UDim2.new(1, 0, 0.5, 0) or UDim2.fromScale(0, 1),
            Size = Input.Compact and UDim2.fromOffset(ControlWidth, 22) or UDim2.new(1, 0, 0, BoxHeight),
            Text = Input.Value,
            TextEditable = not Input.Disabled,
            TextSize = Input.Compact and 13 or 14,
            TextTruncate = Input.MultiLine and Enum.TextTruncate.None or Enum.TextTruncate.AtEnd,
            TextWrapped = Input.MultiLine,
            TextXAlignment = Enum.TextXAlignment.Left,
            TextYAlignment = Input.MultiLine and Enum.TextYAlignment.Top or Enum.TextYAlignment.Center,
            MultiLine = Input.MultiLine,
            Parent = Holder,
        })
        if Groupbox.Window and Groupbox.Window.RegisterTransparencyTarget then
            Groupbox.Window:RegisterTransparencyTarget(Box, 0.04, 0.62)
        end
        New("UICorner", {
            CornerRadius = UDim.new(0, 7),
            Parent = Box,
        })
        New("UIStroke", {
            Color = function()
                return Library:GetUiColor("SoftOutline")
            end,
            Parent = Box,
        })

        New("UIPadding", {
            PaddingLeft = UDim.new(0, Input.Compact and 8 or 10),
            PaddingRight = UDim.new(0, Input.Compact and 8 or 10),
            PaddingTop = UDim.new(0, Input.MultiLine and 8 or 0),
            PaddingBottom = UDim.new(0, Input.MultiLine and 8 or 0),
            Parent = Box,
        })

        function Input:UpdateColors()
            if Library.Unloaded then
                return
            end

            Label.TextTransparency = Input.Disabled and 0.55 or 0
            Box.TextTransparency = Input.Disabled and 0.55 or 0
            Box.BackgroundTransparency = Input.Disabled and 0.35 or 0
        end

        function Input:OnChanged(Func)
            Input.Changed = Func
        end

        function Input:SetValue(Text)
            if not Input.AllowEmpty and Trim(Text) == "" then
                Text = Input.EmptyReset
            end

            if Info.MaxLength and #Text > Info.MaxLength then
                Text = Text:sub(1, Info.MaxLength)
            end

            if Input.Numeric then
                if #tostring(Text) > 0 and not tonumber(Text) then
                    Text = Input.Value
                end
            end

            Input.Value = Text
            Box.Text = Text

            if not Input.Disabled then
                Library:SafeCallback(Input.Callback, Input.Value)
                Library:SafeCallback(Input.Changed, Input.Value)
            end
        end

        function Input:SetDisabled(Disabled: boolean)
            Input.Disabled = Disabled

            if Input.TooltipTable then
                Input.TooltipTable.Disabled = Input.Disabled
            end

            Box.ClearTextOnFocus = not Input.Disabled and Input.ClearTextOnFocus
            Box.TextEditable = not Input.Disabled
            Input:UpdateColors()
        end

        function Input:SetVisible(Visible: boolean)
            Input.Visible = Visible

            Holder.Visible = Input.Visible
            Groupbox:Resize()
        end

        function Input:SetText(Text: string)
            Input.Text = Text
            Label.Text = Text
        end

        if Input.Finished then
            Box.FocusLost:Connect(function(Enter)
                if not Enter then
                    return
                end

                Input:SetValue(Box.Text)
            end)
        else
            Box:GetPropertyChangedSignal("Text"):Connect(function()
                if Box.Text == Input.Value then return end
                
                Input:SetValue(Box.Text)
            end)
        end

        if typeof(Input.Tooltip) == "string" or typeof(Input.DisabledTooltip) == "string" then
            Input.TooltipTable = Library:AddTooltip(Input.Tooltip, Input.DisabledTooltip, Box)
            Input.TooltipTable.Disabled = Input.Disabled
        end

        Groupbox:Resize()

        Input.Holder = Holder
        table.insert(Groupbox.Elements, Input)

        Input.Default = Input.Value

        Options[Idx] = Input

        return Input
    end

    function Funcs:AddSlider(Idx, Info)
        Info = Library:Validate(Info, Templates.Slider)

        local Groupbox = self
        local Container = Groupbox.Container

        local Slider = {
            Text = Info.Text,
            Value = Info.Default,

            Min = Info.Min,
            Max = Info.Max,

            Prefix = Info.Prefix,
            Suffix = Info.Suffix,
            Compact = Info.Compact,
            Rounding = Info.Rounding,

            Tooltip = Info.Tooltip,
            DisabledTooltip = Info.DisabledTooltip,
            TooltipTable = nil,

            Callback = Info.Callback,
            Changed = Info.Changed,

            Disabled = Info.Disabled,
            Visible = Info.Visible,

            Type = "Slider",
        }

        local SliderHolderHeight = Info.Compact and 18 or 48

        local Holder = New("Frame", {
            BackgroundTransparency = 1,
            Size = UDim2.new(1, 0, 0, SliderHolderHeight),
            Visible = Slider.Visible,
            Parent = Container,
        })
        local EditingValue = false

        local SliderLabel
        if not Info.Compact then
            SliderLabel = New("TextLabel", {
                BackgroundTransparency = 1,
                FontFace = function()
                    return Library:GetWeightedFont(Enum.FontWeight.Medium)
                end,
                Size = UDim2.new(1, -58, 0, 14),
                Text = Slider.Text,
                TextColor3 = function()
                    return Library:GetUiColor("MutedText")
                end,
                TextSize = 14,
                TextXAlignment = Enum.TextXAlignment.Left,
                Parent = Holder,
            })
        end

        local ValueLabel
        local ValueInput
        if not Info.Compact then
            ValueLabel = New("TextButton", {
                AutoButtonColor = false,
                AnchorPoint = Vector2.new(1, 0),
                BackgroundTransparency = 1,
                FontFace = function()
                    return Library:GetWeightedFont(Enum.FontWeight.Medium)
                end,
                Position = UDim2.new(1, 0, 0, 0),
                Size = UDim2.fromOffset(56, 14),
                Text = "",
                TextColor3 = function()
                    return Library:GetUiColor("SubtleText")
                end,
                TextSize = 12,
                TextXAlignment = Enum.TextXAlignment.Right,
                Parent = Holder,
            })

            ValueInput = New("TextBox", {
                AnchorPoint = Vector2.new(1, 0),
                BackgroundColor3 = function()
                    return Library:GetUiColor("Control")
                end,
                BorderSizePixel = 0,
                ClearTextOnFocus = false,
                FontFace = function()
                    return Library:GetWeightedFont(Enum.FontWeight.Medium)
                end,
                Position = UDim2.new(1, 4, 0, -3),
                Size = UDim2.fromOffset(64, 20),
                Text = "",
                TextColor3 = function()
                    return Library:GetUiColor("ActiveText")
                end,
                TextEditable = true,
                TextSize = 12,
                TextXAlignment = Enum.TextXAlignment.Right,
                Visible = false,
                Parent = Holder,
            })
            if Groupbox.Window and Groupbox.Window.RegisterTransparencyTarget then
                Groupbox.Window:RegisterTransparencyTarget(ValueInput, 0.04, 0.6)
            end
            New("UICorner", {
                CornerRadius = UDim.new(0, 6),
                Parent = ValueInput,
            })
            New("UIStroke", {
                Color = function()
                    return Library:GetUiColor("SoftOutline")
                end,
                Parent = ValueInput,
            })
            New("UIPadding", {
                PaddingLeft = UDim.new(0, 6),
                PaddingRight = UDim.new(0, 6),
                Parent = ValueInput,
            })
        end

        local Bar = New("TextButton", {
            Active = not Slider.Disabled,
            AnchorPoint = Vector2.new(0, 1),
            BackgroundColor3 = function()
                return Library:GetUiColor("Divider")
            end,
            BorderSizePixel = 0,
            Position = Info.Compact and UDim2.fromScale(0, 1) or UDim2.new(0, 0, 1, -10),
            Size = UDim2.new(1, 0, 0, 4),
            Text = "",
            Parent = Holder,
        })
        if Groupbox.Window and Groupbox.Window.RegisterTransparencyTarget then
            Groupbox.Window:RegisterTransparencyTarget(Bar, 0.18, 0.4)
        end
        New("UICorner", {
            CornerRadius = UDim.new(1, 0),
            Parent = Bar,
        })

        local DisplayLabel = New("TextLabel", {
            BackgroundTransparency = 1,
            Size = UDim2.fromScale(1, 1),
            Text = "",
            TextSize = 12,
            ZIndex = 2,
            Parent = Bar,
        })
        DisplayLabel.Visible = Info.Compact

        local Fill = New("Frame", {
            BackgroundColor3 = function()
                return Library:GetUiColor("AccentFill")
            end,
            Size = UDim2.fromScale(0.5, 1),
            Parent = Bar,
        })
        New("UICorner", {
            CornerRadius = UDim.new(1, 0),
            Parent = Fill,
        })
        New("UIGradient", {
            Color = ColorSequence.new({
                ColorSequenceKeypoint.new(0, Color3.fromRGB(255, 248, 252)),
                ColorSequenceKeypoint.new(1, Library:GetUiColor("AccentFill")),
            }),
            Parent = Fill,
        })
        local Knob = New("Frame", {
            AnchorPoint = Vector2.new(0.5, 0.5),
            BackgroundColor3 = function()
                return Library:GetUiColor("ActiveText")
            end,
            Position = UDim2.fromScale(0.5, 0.5),
            Size = UDim2.fromOffset(12, 12),
            Parent = Bar,
        })
        New("UICorner", {
            CornerRadius = UDim.new(1, 0),
            Parent = Knob,
        })

        local function GetValueLabelText()
            if Info.HideMax then
                return string.format("%s%s%s", Slider.Prefix, Slider.Value, Slider.Suffix)
            end

            return string.format("%s%s", Slider.Value, Slider.Suffix)
        end

        local function FinishValueEdit(Commit)
            if not ValueInput or not EditingValue then
                return
            end

            EditingValue = false

            if Commit then
                Slider:SetValue(ValueInput.Text)
            else
                Slider:Display()
            end

            ValueInput.Visible = false
            ValueLabel.Visible = true
        end
        New("UIStroke", {
            Color = function()
                return Library:GetUiColor("AccentSoft")
            end,
            Parent = Knob,
        })

        function Slider:UpdateColors()
            if Library.Unloaded then
                return
            end

            if SliderLabel then
                SliderLabel.TextTransparency = Slider.Disabled and 0.55 or 0
            end
            DisplayLabel.TextTransparency = Slider.Disabled and 0.55 or 0
            if ValueLabel then
                ValueLabel.TextTransparency = Slider.Disabled and 0.55 or 0
            end
            if ValueInput then
                ValueInput.TextTransparency = Slider.Disabled and 0.55 or 0
                ValueInput.BackgroundTransparency = Slider.Disabled and 0.35 or 0
                ValueInput.TextEditable = not Slider.Disabled
            end
            Fill.BackgroundTransparency = Slider.Disabled and 0.35 or 0
            Knob.BackgroundTransparency = Slider.Disabled and 0.25 or 0
        end

        function Slider:Display()
            if Library.Unloaded then
                return
            end

            local CustomDisplayText = nil
            if Info.FormatDisplayValue then
                CustomDisplayText = Info.FormatDisplayValue(Slider, Slider.Value)
            end

            if CustomDisplayText then
                DisplayLabel.Text = tostring(CustomDisplayText)
            else
                if Info.Compact then
                    DisplayLabel.Text =
                        string.format("%s: %s%s%s", Slider.Text, Slider.Prefix, Slider.Value, Slider.Suffix)
                elseif Info.HideMax then
                    DisplayLabel.Text = string.format("%s%s%s", Slider.Prefix, Slider.Value, Slider.Suffix)
                else
                    DisplayLabel.Text = string.format(
                        "%s%s%s/%s%s%s",
                        Slider.Prefix,
                        Slider.Value,
                        Slider.Suffix,
                        Slider.Prefix,
                        Slider.Max,
                        Slider.Suffix
                    )
                end
            end

            local X = (Slider.Value - Slider.Min) / (Slider.Max - Slider.Min)
            if Slider.FillTween then
                Slider.FillTween:Cancel()
            end
            if Slider.KnobTween then
                Slider.KnobTween:Cancel()
            end
            Slider.FillTween = TweenService:Create(Fill, TweenInfo.new(0.12, Enum.EasingStyle.Quart, Enum.EasingDirection.Out), {
                Size = UDim2.fromScale(X, 1),
            })
            Slider.KnobTween = TweenService:Create(Knob, TweenInfo.new(0.12, Enum.EasingStyle.Quart, Enum.EasingDirection.Out), {
                Position = UDim2.fromScale(X, 0.5),
            })
            Slider.FillTween:Play()
            Slider.KnobTween:Play()

            if ValueLabel and not Info.Compact then
                local ValueText = GetValueLabelText()
                ValueLabel.Text = ValueText
                if ValueInput and not EditingValue then
                    ValueInput.Text = ValueText
                end
            end
        end

        function Slider:OnChanged(Func)
            Slider.Changed = Func
        end

        function Slider:SetMax(Value)
            assert(Value > Slider.Min, "Max value cannot be less than the current min value.")

            Slider:SetValue(math.clamp(Slider.Value, Slider.Min, Value)) --this will make  so it updates. and im calling this so i dont need to add an if :P
            Slider.Max = Value
            Slider:Display()
        end

        function Slider:SetMin(Value)
            assert(Value < Slider.Max, "Min value cannot be greater than the current max value.")

            Slider:SetValue(math.clamp(Slider.Value, Value, Slider.Max)) --same here. adding these comments for the funny
            Slider.Min = Value
            Slider:Display()
        end

        function Slider:SetValue(Str)
            if Slider.Disabled then
                return
            end

            local Num = tonumber(Str)
            if not Num then
                return
            end

            Num = Round(math.clamp(Num, Slider.Min, Slider.Max), Slider.Rounding)
            if Num == Slider.Value then
                return
            end

            Slider.Value = Num
            Slider:Display()

            Library:SafeCallback(Slider.Callback, Slider.Value)
            Library:SafeCallback(Slider.Changed, Slider.Value)
        end

        function Slider:SetDisabled(Disabled: boolean)
            Slider.Disabled = Disabled

            if EditingValue then
                FinishValueEdit(false)
            end

            if Slider.TooltipTable then
                Slider.TooltipTable.Disabled = Slider.Disabled
            end

            Bar.Active = not Slider.Disabled
            Slider:UpdateColors()
        end

        function Slider:SetVisible(Visible: boolean)
            Slider.Visible = Visible

            Holder.Visible = Slider.Visible
            Groupbox:Resize()
        end

        function Slider:SetText(Text: string)
            Slider.Text = Text
            if SliderLabel then
                SliderLabel.Text = Text
                return
            end
            Slider:Display()
        end

        function Slider:SetPrefix(Prefix: string)
            Slider.Prefix = Prefix
            Slider:Display()
        end

        function Slider:SetSuffix(Suffix: string)
            Slider.Suffix = Suffix
            Slider:Display()
        end

        Bar.InputBegan:Connect(function(Input: InputObject)
            if not IsClickInput(Input) or Slider.Disabled or EditingValue then
                return
            end

            for _, Side in Library.ActiveTab.Sides do
                Side.ScrollingEnabled = false
            end

            while IsDragInput(Input) do
                local Location = Mouse.X
                local Scale = math.clamp((Location - Bar.AbsolutePosition.X) / Bar.AbsoluteSize.X, 0, 1)

                local OldValue = Slider.Value
                Slider.Value = Round(Slider.Min + ((Slider.Max - Slider.Min) * Scale), Slider.Rounding)

                Slider:Display()
                if Slider.Value ~= OldValue then
                    Library:SafeCallback(Slider.Callback, Slider.Value)
                    Library:SafeCallback(Slider.Changed, Slider.Value)
                end

                RunService.RenderStepped:Wait()
            end

            for _, Side in Library.ActiveTab.Sides do
                Side.ScrollingEnabled = true
            end
        end)

        if ValueLabel and ValueInput then
            ValueLabel.MouseButton1Click:Connect(function()
                if Slider.Disabled then
                    return
                end

                EditingValue = true
                ValueInput.Text = tostring(Slider.Value)
                ValueLabel.Visible = false
                ValueInput.Visible = true
                ValueInput:CaptureFocus()
                ValueInput.CursorPosition = #ValueInput.Text + 1
            end)

            ValueInput.FocusLost:Connect(function()
                FinishValueEdit(true)
            end)
        end

        if typeof(Slider.Tooltip) == "string" or typeof(Slider.DisabledTooltip) == "string" then
            Slider.TooltipTable = Library:AddTooltip(Slider.Tooltip, Slider.DisabledTooltip, Bar)
            Slider.TooltipTable.Disabled = Slider.Disabled
        end

        Slider:UpdateColors()
        Slider:Display()
        Groupbox:Resize()

        Slider.Holder = Holder
        table.insert(Groupbox.Elements, Slider)

        Slider.Default = Slider.Value

        Options[Idx] = Slider

        return Slider
    end

    function Funcs:AddDropdown(Idx, Info)
        Info = Library:Validate(Info, Templates.Dropdown)

        local Groupbox = self
        local Container = Groupbox.Container

        if Info.SpecialType == "Player" then
            Info.Values = GetPlayers(Info.ExcludeLocalPlayer)
            Info.AllowNull = true
        elseif Info.SpecialType == "Team" then
            Info.Values = GetTeams()
            Info.AllowNull = true
        end

        local Dropdown = {
            Text = typeof(Info.Text) == "string" and Info.Text or nil,
            Value = Info.Multi and {} or nil,
            Values = Info.Values,
            DisabledValues = Info.DisabledValues,
            Multi = Info.Multi,
            Compact = Info.Compact,
            ControlWidth = Info.ControlWidth,

            SpecialType = Info.SpecialType,
            ExcludeLocalPlayer = Info.ExcludeLocalPlayer,

            Tooltip = Info.Tooltip,
            DisabledTooltip = Info.DisabledTooltip,
            TooltipTable = nil,

            Callback = Info.Callback,
            Changed = Info.Changed,

            Disabled = Info.Disabled,
            Visible = Info.Visible,

            Type = "Dropdown",
        }

        local ControlWidth = Dropdown.ControlWidth or 102

        local Holder = New("Frame", {
            BackgroundTransparency = 1,
            Size = UDim2.new(1, 0, 0, Dropdown.Text and (Dropdown.Compact and 26 or 40) or 22),
            Visible = Dropdown.Visible,
            Parent = Container,
        })

        local Label = New("TextLabel", {
            BackgroundTransparency = 1,
            FontFace = function()
                return Library:GetWeightedFont(Enum.FontWeight.Medium)
            end,
            Size = Dropdown.Compact and UDim2.new(1, -(ControlWidth + 8), 1, 0) or UDim2.new(1, 0, 0, 14),
            Text = Dropdown.Text,
            TextColor3 = function()
                return Library:GetUiColor("MutedText")
            end,
            TextSize = 14,
            TextXAlignment = Enum.TextXAlignment.Left,
            Visible = not not Info.Text,
            Parent = Holder,
        })
        local MenuTable

        local Display = New("TextButton", {
            Active = not Dropdown.Disabled,
            AnchorPoint = Dropdown.Compact and Vector2.new(1, 0.5) or Vector2.new(0, 1),
            BackgroundColor3 = function()
                return Library:GetUiColor("Control")
            end,
            BorderSizePixel = 0,
            FontFace = function()
                return Library:GetWeightedFont(Enum.FontWeight.Medium)
            end,
            Position = Dropdown.Compact and UDim2.new(1, 0, 0.5, 0) or UDim2.fromScale(0, 1),
            Size = Dropdown.Compact and UDim2.fromOffset(ControlWidth, 20) or UDim2.new(1, 0, 0, 22),
            Text = "---",
            TextColor3 = function()
                return Library:GetUiColor("ActiveText")
            end,
            TextSize = Dropdown.Compact and 13 or 14,
            TextXAlignment = Enum.TextXAlignment.Left,
            Parent = Holder,
        })
        if Groupbox.Window and Groupbox.Window.RegisterTransparencyTarget then
            Groupbox.Window:RegisterTransparencyTarget(Display, 0.04, 0.62)
        end
        New("UICorner", {
            CornerRadius = UDim.new(0, Dropdown.Compact and 6 or 7),
            Parent = Display,
        })
        New("UIStroke", {
            Color = function()
                return Library:GetUiColor("SoftOutline")
            end,
            Parent = Display,
        })

        New("UIPadding", {
            PaddingLeft = UDim.new(0, Dropdown.Compact and 8 or 10),
            PaddingRight = UDim.new(0, 6),
            Parent = Display,
        })

        local ArrowImage = New("ImageLabel", {
            AnchorPoint = Vector2.new(1, 0.5),
            Image = ArrowIcon and ArrowIcon.Url or "",
            ImageColor3 = function()
                return Library:GetUiColor("SubtleText")
            end,
            ImageRectOffset = ArrowIcon and ArrowIcon.ImageRectOffset or Vector2.zero,
            ImageRectSize = ArrowIcon and ArrowIcon.ImageRectSize or Vector2.zero,
            ImageTransparency = 0.5,
            Position = UDim2.fromScale(1, 0.5),
            Size = UDim2.fromOffset(Dropdown.Compact and 12 or 14, Dropdown.Compact and 12 or 14),
            Parent = Display,
        })
        local DisplayTween
        local ArrowTween
        Display.MouseEnter:Connect(function()
            if Dropdown.Disabled then
                return
            end

            StopTween(DisplayTween)
            DisplayTween = TweenService:Create(Display, TweenInfo.new(0.12, Enum.EasingStyle.Quart, Enum.EasingDirection.Out), {
                BackgroundTransparency = 0.04,
            })
            DisplayTween:Play()
        end)
        Display.MouseLeave:Connect(function()
            if Dropdown.Disabled or MenuTable.Active then
                return
            end

            StopTween(DisplayTween)
            DisplayTween = TweenService:Create(Display, TweenInfo.new(0.12, Enum.EasingStyle.Quart, Enum.EasingDirection.Out), {
                BackgroundTransparency = 0,
            })
            DisplayTween:Play()
        end)
        Display.MouseButton1Down:Connect(function()
            if Dropdown.Disabled then
                return
            end

            StopTween(DisplayTween)
            DisplayTween = TweenService:Create(Display, TweenInfo.new(0.08, Enum.EasingStyle.Quad, Enum.EasingDirection.Out), {
                BackgroundTransparency = 0.1,
            })
            DisplayTween:Play()
        end)
        Display.MouseButton1Up:Connect(function()
            if Dropdown.Disabled then
                return
            end

            StopTween(DisplayTween)
            DisplayTween = TweenService:Create(Display, TweenInfo.new(0.1, Enum.EasingStyle.Quad, Enum.EasingDirection.Out), {
                BackgroundTransparency = MenuTable and MenuTable.Active and 0.06 or 0.03,
            })
            DisplayTween:Play()
        end)

        local SearchBox
        if Info.Searchable then
            SearchBox = New("TextBox", {
                BackgroundTransparency = 1,
                PlaceholderText = "Search...",
                Position = UDim2.fromOffset(-8, 0),
                Size = UDim2.new(1, -12, 1, 0),
                TextSize = 14,
                TextXAlignment = Enum.TextXAlignment.Left,
                Visible = false,
                Parent = Display,
            })
            New("UIPadding", {
                PaddingLeft = UDim.new(0, 8),
                Parent = SearchBox,
            })
        end

        MenuTable = Library:AddContextMenu(
            Display,
            function()
                return UDim2.fromOffset(Display.AbsoluteSize.X / Library.DPIScale, 0)
            end,
            function()
                return { 0.5, Display.AbsoluteSize.Y + 1.5 }
            end,
            2,
            function(Active: boolean)
                Display.TextTransparency = (Active and SearchBox) and 1 or 0
                StopTween(DisplayTween)
                DisplayTween = TweenService:Create(Display, TweenInfo.new(0.14, Enum.EasingStyle.Quart, Enum.EasingDirection.Out), {
                    BackgroundTransparency = Active and 0.06 or 0,
                })
                DisplayTween:Play()
                StopTween(ArrowTween)
                ArrowTween = TweenService:Create(ArrowImage, TweenInfo.new(0.14, Enum.EasingStyle.Quart, Enum.EasingDirection.Out), {
                    ImageTransparency = Active and 0 or 0.5,
                    Rotation = Active and 180 or 0,
                })
                ArrowTween:Play()
                if SearchBox then
                    SearchBox.Text = ""
                    SearchBox.Visible = Active
                end
            end
        )
        Dropdown.Menu = MenuTable
        if Groupbox.Window and Groupbox.Window.RegisterTransparencyTarget then
            Groupbox.Window:RegisterTransparencyTarget(MenuTable.Menu, 0.04, 0.54)
        end

        function Dropdown:RecalculateListSize(Count)
            local Y = math.clamp((Count or GetTableSize(Dropdown.Values)) * 22, 0, Info.MaxVisibleDropdownItems * 22)

            MenuTable:SetSize(function()
                return UDim2.fromOffset(Display.AbsoluteSize.X / Library.DPIScale, Y)
            end)
        end

        function Dropdown:UpdateColors()
            if Library.Unloaded then
                return
            end

            Label.TextTransparency = Dropdown.Disabled and 0.55 or 0
            Display.TextTransparency = Dropdown.Disabled and 0.55 or 0
            Display.BackgroundTransparency = Dropdown.Disabled and 0.35 or 0
            ArrowImage.ImageTransparency = Dropdown.Disabled and 0.55 or MenuTable.Active and 0 or 0.3
        end

        function Dropdown:Display()
            if Library.Unloaded then
                return
            end

            local Str = ""

            if Info.Multi then
                for _, Value in Dropdown.Values do
                    if Dropdown.Value[Value] then
                        Str = Str
                            .. (Info.FormatDisplayValue and tostring(Info.FormatDisplayValue(Value)) or tostring(Value))
                            .. ", "
                    end
                end

                Str = Str:sub(1, #Str - 2)
            else
                Str = Dropdown.Value and tostring(Dropdown.Value) or ""
                if Str ~= "" and Info.FormatDisplayValue then
                    Str = tostring(Info.FormatDisplayValue(Str))
                end
            end

            if #Str > 25 then
                Str = Str:sub(1, 22) .. "..."
            end

            Display.Text = (Str == "" and "---" or Str)
        end

        function Dropdown:OnChanged(Func)
            Dropdown.Changed = Func
        end

        function Dropdown:GetActiveValues()
            if Info.Multi then
                local Table = {}

                for Value, _ in Dropdown.Value do
                    table.insert(Table, Value)
                end

                return Table
            end

            return Dropdown.Value and 1 or 0
        end

        local Buttons = {}
        function Dropdown:BuildDropdownList()
            local Values = Dropdown.Values
            local DisabledValues = Dropdown.DisabledValues

            for Button, _ in Buttons do
                Button:Destroy()
            end
            table.clear(Buttons)

            local Count = 0
            for _, Value in Values do
                if SearchBox and not tostring(Value):lower():match(SearchBox.Text:lower()) then
                    continue
                end

                Count += 1
                local IsDisabled = table.find(DisabledValues, Value)
                local Table = {}

                local Button = New("TextButton", {
                    BackgroundColor3 = function()
                        return Library:GetUiColor("Control")
                    end,
                    BackgroundTransparency = 1,
                    LayoutOrder = IsDisabled and 1 or 0,
                    FontFace = function()
                        return Library:GetWeightedFont(Enum.FontWeight.Medium)
                    end,
                    Size = UDim2.new(1, 0, 0, 22),
                    Text = tostring(Value),
                    TextColor3 = function()
                        return Library:GetUiColor("ActiveText")
                    end,
                    TextSize = 13,
                    TextTransparency = 0.3,
                    TextXAlignment = Enum.TextXAlignment.Left,
                    Parent = MenuTable.Menu,
                })
                New("UICorner", {
                    CornerRadius = UDim.new(0, 6),
                    Parent = Button,
                })
                New("UIPadding", {
                    PaddingLeft = UDim.new(0, 7),
                    PaddingRight = UDim.new(0, 7),
                    Parent = Button,
                })

                local Selected
                if Info.Multi then
                    Selected = Dropdown.Value[Value]
                else
                    Selected = Dropdown.Value == Value
                end

                function Table:UpdateButton()
                    if Info.Multi then
                        Selected = Dropdown.Value[Value]
                    else
                        Selected = Dropdown.Value == Value
                    end

                    Button.BackgroundTransparency = Selected and 0 or 1
                    Button.TextTransparency = IsDisabled and 0.55 or Selected and 0 or 0.3
                end

                if not IsDisabled then
                    Button.MouseButton1Click:Connect(function()
                        local Try = not Selected

                        if not (Dropdown:GetActiveValues() == 1 and not Try and not Info.AllowNull) then
                            Selected = Try
                            if Info.Multi then
                                Dropdown.Value[Value] = Selected and true or nil
                            else
                                Dropdown.Value = Selected and Value or nil
                            end

                            for _, OtherButton in Buttons do
                                OtherButton:UpdateButton()
                            end
                        end

                        Table:UpdateButton()
                        Dropdown:Display()

                        Library:UpdateDependencyBoxes()
                        Library:SafeCallback(Dropdown.Callback, Dropdown.Value)
                        Library:SafeCallback(Dropdown.Changed, Dropdown.Value)
                    end)
                end

                Table:UpdateButton()
                Dropdown:Display()

                Buttons[Button] = Table
            end

            Dropdown:RecalculateListSize(Count)
        end

        function Dropdown:SetValue(Value)
            if Info.Multi then
                local Table = {}

                for Val, Active in Value or {} do
                    if typeof(Active) ~= "boolean" then
                        Table[Active] = true
                    elseif Active and table.find(Dropdown.Values, Val) then
                        Table[Val] = true
                    end
                end

                Dropdown.Value = Table
            else
                if table.find(Dropdown.Values, Value) then
                    Dropdown.Value = Value
                elseif not Value then
                    Dropdown.Value = nil
                end
            end

            Dropdown:Display()
            for _, Button in Buttons do
                Button:UpdateButton()
            end

            if not Dropdown.Disabled then
                Library:UpdateDependencyBoxes()
                Library:SafeCallback(Dropdown.Callback, Dropdown.Value)
                Library:SafeCallback(Dropdown.Changed, Dropdown.Value)
            end
        end

        function Dropdown:SetValues(Values)
            Dropdown.Values = Values
            Dropdown:BuildDropdownList()
        end

        function Dropdown:AddValues(Values)
            if typeof(Values) == "table" then
                for _, val in Values do
                    table.insert(Dropdown.Values, val)
                end
            elseif typeof(Values) == "string" then
                table.insert(Dropdown.Values, Values)
            else
                return
            end

            Dropdown:BuildDropdownList()
        end

        function Dropdown:SetDisabledValues(DisabledValues)
            Dropdown.DisabledValues = DisabledValues
            Dropdown:BuildDropdownList()
        end

        function Dropdown:AddDisabledValues(DisabledValues)
            if typeof(DisabledValues) == "table" then
                for _, val in DisabledValues do
                    table.insert(Dropdown.DisabledValues, val)
                end
            elseif typeof(DisabledValues) == "string" then
                table.insert(Dropdown.DisabledValues, DisabledValues)
            else
                return
            end

            Dropdown:BuildDropdownList()
        end

        function Dropdown:SetDisabled(Disabled: boolean)
            Dropdown.Disabled = Disabled

            if Dropdown.TooltipTable then
                Dropdown.TooltipTable.Disabled = Dropdown.Disabled
            end

            MenuTable:Close()
            Display.Active = not Dropdown.Disabled
            Dropdown:UpdateColors()
        end

        function Dropdown:SetVisible(Visible: boolean)
            Dropdown.Visible = Visible

            Holder.Visible = Dropdown.Visible
            Groupbox:Resize()
        end

        function Dropdown:SetText(Text: string)
            Dropdown.Text = Text
            Holder.Size = UDim2.new(1, 0, 0, Text and 40 or 22)

            Label.Text = Text and Text or ""
            Label.Visible = not not Text
        end

        Display.MouseButton1Click:Connect(function()
            if Dropdown.Disabled then
                return
            end

            MenuTable:Toggle()
        end)

        if SearchBox then
            SearchBox:GetPropertyChangedSignal("Text"):Connect(Dropdown.BuildDropdownList)
        end

        local Defaults = {}
        if typeof(Info.Default) == "string" then
            local Index = table.find(Dropdown.Values, Info.Default)
            if Index then
                table.insert(Defaults, Index)
            end
        elseif typeof(Info.Default) == "table" then
            for _, Value in next, Info.Default do
                local Index = table.find(Dropdown.Values, Value)
                if Index then
                    table.insert(Defaults, Index)
                end
            end
        elseif Dropdown.Values[Info.Default] ~= nil then
            table.insert(Defaults, Info.Default)
        end

        if next(Defaults) then
            for i = 1, #Defaults do
                local Index = Defaults[i]
                if Info.Multi then
                    Dropdown.Value[Dropdown.Values[Index]] = true
                else
                    Dropdown.Value = Dropdown.Values[Index]
                end

                if not Info.Multi then
                    break
                end
            end
        end

        if typeof(Dropdown.Tooltip) == "string" or typeof(Dropdown.DisabledTooltip) == "string" then
            Dropdown.TooltipTable = Library:AddTooltip(Dropdown.Tooltip, Dropdown.DisabledTooltip, Display)
            Dropdown.TooltipTable.Disabled = Dropdown.Disabled
        end

        Dropdown:UpdateColors()
        Dropdown:Display()
        Dropdown:BuildDropdownList()
        Groupbox:Resize()

        Dropdown.Holder = Holder
        table.insert(Groupbox.Elements, Dropdown)

        Dropdown.Default = Defaults
        Dropdown.DefaultValues = Dropdown.Values

        Options[Idx] = Dropdown

        return Dropdown
    end

    function Funcs:AddViewport(Idx, Info)
        Info = Library:Validate(Info, Templates.Viewport)

        local Groupbox = self
        local Container = Groupbox.Container

        local Dragging, Pinching = false, false
        local LastMousePos, LastPinchDist = nil, 0

        local ViewportObject = Info.Object
        if Info.Clone and typeof(Info.Object) == "Instance" then
            if Info.Object.Archivable then
                ViewportObject = ViewportObject:Clone()
            else
                Info.Object.Archivable = true
                ViewportObject = ViewportObject:Clone()
                Info.Object.Archivable = false
            end
        end

        local Viewport = {
            Object = ViewportObject,
            Camera = if not Info.Camera then Instance.new("Camera") else Info.Camera,
            Interactive = Info.Interactive,
            AutoFocus = Info.AutoFocus,
            AutoRotate = Info.AutoRotate,
            RotateSpeed = Info.RotateSpeed,
            FocusYOffset = Info.FocusYOffset,
            CameraDistanceMultiplier = Info.CameraDistanceMultiplier,
            BackgroundColor = Info.BackgroundColor,
            BackgroundTransparency = Info.BackgroundTransparency,
            BackgroundImage = Info.BackgroundImage,
            BackgroundImageTransparency = Info.BackgroundImageTransparency,
            BackgroundGradient = Info.BackgroundGradient,
            BackgroundGradientRotation = Info.BackgroundGradientRotation,
            Visible = Info.Visible,
            Type = "Viewport",
        }

        assert(
            typeof(Viewport.Object) == "Instance" and (Viewport.Object:IsA("BasePart") or Viewport.Object:IsA("Model")),
            "Instance must be a BasePart or Model."
        )

        assert(
            typeof(Viewport.Camera) == "Instance" and Viewport.Camera:IsA("Camera"),
            "Camera must be a valid Camera instance."
        )

        local function GetModelMetrics(model)
            if model:IsA("BasePart") then
                return model.Size, model.Position
            end

            local boundingBox, boundingSize = model:GetBoundingBox()
            return boundingSize, boundingBox.Position
        end

        local OrbitYaw = math.rad(24)
        local OrbitPitch = math.rad(-8)
        local OrbitDistance = nil
        local OrbitMinDistance = 2
        local OrbitMaxDistance = 24
        local OrbitFocus = Vector3.zero
        local OrbitExtent = 4

        local function ApplyOrbitCamera()
            if not Viewport.Object then
                return
            end

            local CosPitch = math.cos(OrbitPitch)
            local Direction = Vector3.new(
                math.sin(OrbitYaw) * CosPitch,
                math.sin(OrbitPitch),
                math.cos(OrbitYaw) * CosPitch
            )

            Viewport.Camera.CFrame = CFrame.new(OrbitFocus + Direction * OrbitDistance, OrbitFocus)
        end

        local function FocusCamera(PreserveDistance)
            local ModelSize, ModelPosition = GetModelMetrics(Viewport.Object)
            local MaxExtent = math.max(ModelSize.X, ModelSize.Y, ModelSize.Z)

            OrbitExtent = MaxExtent
            OrbitFocus = ModelPosition + Vector3.new(0, MaxExtent * Viewport.FocusYOffset, 0)
            OrbitMinDistance = math.max(1.75, MaxExtent * 0.8)
            OrbitMaxDistance = math.max(24, MaxExtent * 8)

            if not PreserveDistance or not OrbitDistance then
                OrbitDistance = math.max(4.5, MaxExtent * Viewport.CameraDistanceMultiplier)
            else
                OrbitDistance = math.clamp(OrbitDistance, OrbitMinDistance, OrbitMaxDistance)
            end

            ApplyOrbitCamera()
        end

        local Holder = New("Frame", {
            BackgroundTransparency = 1,
            Size = UDim2.new(1, 0, 0, Info.Height),
            Visible = Viewport.Visible,
            Parent = Container,
        })

        local Box = New("Frame", {
            AnchorPoint = Vector2.new(0, 1),
            BackgroundColor3 = "MainColor",
            BorderColor3 = "OutlineColor",
            BorderSizePixel = 1,
            ClipsDescendants = true,
            Position = UDim2.fromScale(0, 1),
            Size = UDim2.fromScale(1, 1),
            Parent = Holder,
        })
        if Groupbox.Window and Groupbox.Window.RegisterTransparencyTarget then
            Groupbox.Window:RegisterTransparencyTarget(Box, 0.04, 0.56)
        end

        New("UIPadding", {
            PaddingBottom = UDim.new(0, 3),
            PaddingLeft = UDim.new(0, 8),
            PaddingRight = UDim.new(0, 8),
            PaddingTop = UDim.new(0, 4),
            Parent = Box,
        })

        local BackgroundFrame = New("Frame", {
            BackgroundColor3 = Viewport.BackgroundColor,
            BackgroundTransparency = Viewport.BackgroundTransparency,
            Size = UDim2.fromScale(1, 1),
            Parent = Box,
        })
        local BackgroundCorner = New("UICorner", {
            CornerRadius = UDim.new(0, 8),
            Parent = BackgroundFrame,
        })
        local BackgroundImage = New("ImageLabel", {
            BackgroundTransparency = 1,
            Image = Viewport.BackgroundImage,
            ImageColor3 = Viewport.BackgroundImageColor,
            ImageTransparency = Viewport.BackgroundImage == "" and 1 or Viewport.BackgroundImageTransparency,
            ScaleType = Enum.ScaleType.Crop,
            Size = UDim2.fromScale(1, 1),
            Parent = BackgroundFrame,
        })
        New("UICorner", {
            CornerRadius = UDim.new(0, 8),
            Parent = BackgroundImage,
        })
        local BackgroundGradient = New("UIGradient", {
            Color = typeof(Viewport.BackgroundGradient) == "ColorSequence" and Viewport.BackgroundGradient
                or ColorSequence.new(Viewport.BackgroundColor),
            Enabled = typeof(Viewport.BackgroundGradient) == "ColorSequence",
            Rotation = Viewport.BackgroundGradientRotation or 0,
            Parent = BackgroundFrame,
        })

        local ViewportFrame = New("ViewportFrame", {
            BackgroundTransparency = 1,
            Size = UDim2.fromScale(1, 1),
            Parent = Box,
            CurrentCamera = Viewport.Camera,
            Active = Viewport.Interactive,
        })
        New("UICorner", {
            CornerRadius = UDim.new(0, 8),
            Parent = ViewportFrame,
        })

        ViewportFrame.MouseEnter:Connect(function()
            if not Viewport.Interactive then
                return
            end

            for _, Side in Groupbox.Tab.Sides do
                Side.ScrollingEnabled = false
            end
        end)

        ViewportFrame.MouseLeave:Connect(function()
            if not Viewport.Interactive then
                return
            end

            for _, Side in Groupbox.Tab.Sides do
                Side.ScrollingEnabled = true
            end
        end)

        ViewportFrame.InputBegan:Connect(function(input)
            if not Viewport.Interactive then
                return
            end

            if input.UserInputType == Enum.UserInputType.MouseButton1 or input.UserInputType == Enum.UserInputType.MouseButton2 then
                Dragging = true
                LastMousePos = input.Position
            elseif input.UserInputType == Enum.UserInputType.Touch and not Pinching then
                Dragging = true
                LastMousePos = input.Position
            end
        end)

        Library:GiveSignal(UserInputService.InputEnded:Connect(function(input)
            if Library.Unloaded then
                return
            end

            if not Viewport.Interactive then
                return
            end

            if input.UserInputType == Enum.UserInputType.MouseButton1 or input.UserInputType == Enum.UserInputType.MouseButton2 then
                Dragging = false
            elseif input.UserInputType == Enum.UserInputType.Touch then
                Dragging = false
            end
        end))

        Library:GiveSignal(UserInputService.InputChanged:Connect(function(input)
            if Library.Unloaded then
                return
            end

            if not Viewport.Interactive or not Dragging or Pinching then
                return
            end

            if
                input.UserInputType == Enum.UserInputType.MouseMovement
                or input.UserInputType == Enum.UserInputType.Touch
            then
                local MouseDelta = input.Position - LastMousePos
                LastMousePos = input.Position

                OrbitYaw -= MouseDelta.X * 0.01
                OrbitPitch = math.clamp(OrbitPitch - MouseDelta.Y * 0.008, math.rad(-70), math.rad(70))
                ApplyOrbitCamera()
            end
        end))

        ViewportFrame.InputChanged:Connect(function(input)
            if not Viewport.Interactive then
                return
            end

            if input.UserInputType == Enum.UserInputType.MouseWheel then
                local ZoomAmount = input.Position.Z * math.max(0.8, OrbitExtent * 0.08)
                OrbitDistance = math.clamp((OrbitDistance or 8) - ZoomAmount, OrbitMinDistance, OrbitMaxDistance)
                ApplyOrbitCamera()
            end
        end)

        Library:GiveSignal(UserInputService.TouchPinch:Connect(function(touchPositions, scale, velocity, state)
            if Library.Unloaded then
                return
            end

            if not Viewport.Interactive or not Library:MouseIsOverFrame(ViewportFrame, touchPositions[1]) then
                return
            end

            if state == Enum.UserInputState.Begin then
                Pinching = true
                Dragging = false
                LastPinchDist = (touchPositions[1] - touchPositions[2]).Magnitude
            elseif state == Enum.UserInputState.Change then
                local currentDist = (touchPositions[1] - touchPositions[2]).Magnitude
                local delta = (currentDist - LastPinchDist) * 0.1
                LastPinchDist = currentDist
                OrbitDistance = math.clamp((OrbitDistance or 8) - delta, OrbitMinDistance, OrbitMaxDistance)
                ApplyOrbitCamera()
            elseif state == Enum.UserInputState.End or state == Enum.UserInputState.Cancel then
                Pinching = false
            end
        end))

        Library:GiveSignal(RunService.RenderStepped:Connect(function(DeltaTime)
            if Library.Unloaded or not Viewport.AutoRotate or not Viewport.Visible or Dragging or Pinching then
                return
            end

            OrbitYaw += math.rad(Viewport.RotateSpeed) * DeltaTime
            ApplyOrbitCamera()
        end))

        Viewport.Object.Parent = ViewportFrame
        if Viewport.AutoFocus then
            FocusCamera()
        end

        function Viewport:SetObject(Object: Instance, Clone: boolean?)
            assert(Object, "Object cannot be nil.")

            if Clone then
                Object = Object:Clone()
            end

            if Viewport.Object then
                Viewport.Object:Destroy()
            end

            Viewport.Object = Object
            Viewport.Object.Parent = ViewportFrame
            FocusCamera(false)

            Groupbox:Resize()
        end

        function Viewport:SetHeight(Height: number)
            assert(Height > 0, "Height must be greater than 0.")

            Holder.Size = UDim2.new(1, 0, 0, Height)
            Groupbox:Resize()
        end

        function Viewport:Focus()
            if not Viewport.Object then
                return
            end

            FocusCamera(false)
        end

        function Viewport:SetCamera(Camera: Instance)
            assert(
                Camera and typeof(Camera) == "Instance" and Camera:IsA("Camera"),
                "Camera must be a valid Camera instance."
            )

            Viewport.Camera = Camera
            ViewportFrame.CurrentCamera = Camera
        end

        function Viewport:SetInteractive(Interactive: boolean)
            Viewport.Interactive = Interactive
            ViewportFrame.Active = Interactive
        end

        function Viewport:SetAutoRotate(AutoRotate: boolean)
            Viewport.AutoRotate = AutoRotate
        end

        function Viewport:SetRotateSpeed(RotateSpeed: number)
            Viewport.RotateSpeed = RotateSpeed
        end

        function Viewport:SetVisible(Visible: boolean)
            Viewport.Visible = Visible

            Holder.Visible = Viewport.Visible
            Groupbox:Resize()
        end

        function Viewport:SetBackgroundColor(Color: Color3)
            Viewport.BackgroundColor = Color
            BackgroundFrame.BackgroundColor3 = Color
        end

        function Viewport:SetBackgroundTransparency(Transparency: number)
            Viewport.BackgroundTransparency = math.clamp(Transparency, 0, 1)
            BackgroundFrame.BackgroundTransparency = Viewport.BackgroundTransparency
        end

        function Viewport:SetBackgroundImage(Image: string)
            Viewport.BackgroundImage = Image
            local ResolvedImage = ResolveImageSource(Image)
            BackgroundImage.Image = ResolvedImage
            BackgroundImage.ImageTransparency = ResolvedImage == "" and 1 or Viewport.BackgroundImageTransparency
        end

        function Viewport:SetBackgroundImageColor(Color: Color3)
            Viewport.BackgroundImageColor = Color
            BackgroundImage.ImageColor3 = Color
        end

        function Viewport:SetBackgroundImageTransparency(Transparency: number)
            Viewport.BackgroundImageTransparency = math.clamp(Transparency, 0, 1)
            BackgroundImage.ImageTransparency = Viewport.BackgroundImage == "" and 1 or Viewport.BackgroundImageTransparency
        end

        function Viewport:SetBackgroundGradient(Gradient, Rotation)
            Viewport.BackgroundGradient = Gradient
            if Rotation ~= nil then
                Viewport.BackgroundGradientRotation = Rotation
            end

            if typeof(Gradient) == "ColorSequence" then
                BackgroundGradient.Enabled = true
                BackgroundGradient.Color = Gradient
                BackgroundGradient.Rotation = Viewport.BackgroundGradientRotation or 0
            else
                BackgroundGradient.Enabled = false
            end
        end

        Groupbox:Resize()

        Viewport.Holder = Holder
        Viewport.Box = Box
        Viewport.BackgroundFrame = BackgroundFrame
        Viewport.BackgroundImageLabel = BackgroundImage
        Viewport.BackgroundGradientObject = BackgroundGradient
        table.insert(Groupbox.Elements, Viewport)

        Options[Idx] = Viewport

        return Viewport
    end

    function Funcs:AddImage(Idx, Info)
        Info = Library:Validate(Info, Templates.Image)

        local Groupbox = self
        local Container = Groupbox.Container

        local Image = {
            Image = Info.Image,
            Color = Info.Color,
            RectOffset = Info.RectOffset,
            RectSize = Info.RectSize,
            Height = Info.Height,
            ScaleType = Info.ScaleType,
            Transparency = Info.Transparency,
            BackgroundTransparency = Info.BackgroundTransparency,

            Visible = Info.Visible,
            Type = "Image",
        }

        local Holder = New("Frame", {
            BackgroundTransparency = 1,
            Size = UDim2.new(1, 0, 0, Info.Height),
            Visible = Image.Visible,
            Parent = Container,
        })

        local Box = New("Frame", {
            AnchorPoint = Vector2.new(0, 1),
            BackgroundColor3 = "MainColor",
            BorderColor3 = "OutlineColor",
            BorderSizePixel = 1,
            BackgroundTransparency = Image.BackgroundTransparency,
            Position = UDim2.fromScale(0, 1),
            Size = UDim2.fromScale(1, 1),
            Parent = Holder,
        })

        New("UIPadding", {
            PaddingBottom = UDim.new(0, 3),
            PaddingLeft = UDim.new(0, 8),
            PaddingRight = UDim.new(0, 8),
            PaddingTop = UDim.new(0, 4),
            Parent = Box,
        })

        local ImageProperties = {
            BackgroundTransparency = 1,
            Size = UDim2.fromScale(1, 1),
            Image = Image.Image,
            ImageTransparency = Image.Transparency,
            ImageColor3 = Image.Color,
            ImageRectOffset = Image.RectOffset,
            ImageRectSize = Image.RectSize,
            ScaleType = Image.ScaleType,
            Parent = Box,
        }

        local Icon = Library:GetCustomIcon(ImageProperties.Image)
        assert(Icon, "Image must be a valid Roblox asset or a valid URL or a valid lucide icon.")

        ImageProperties.Image = Icon.Url
        ImageProperties.ImageRectOffset = Icon.ImageRectOffset
        ImageProperties.ImageRectSize = Icon.ImageRectSize

        local ImageLabel = New("ImageLabel", ImageProperties)

        function Image:SetHeight(Height: number)
            assert(Height > 0, "Height must be greater than 0.")

            Image.Height = Height
            Holder.Size = UDim2.new(1, 0, 0, Height)
            Groupbox:Resize()
        end

        function Image:SetImage(NewImage: string)
            assert(typeof(NewImage) == "string", "Image must be a string.")

            local Icon = Library:GetCustomIcon(NewImage)
            assert(Icon, "Image must be a valid Roblox asset or a valid URL or a valid lucide icon.")

            NewImage = Icon.Url
            Image.RectOffset = Icon.ImageRectOffset
            Image.RectSize = Icon.ImageRectSize

            ImageLabel.Image = NewImage
            Image.Image = NewImage
        end

        function Image:SetColor(Color: Color3)
            assert(typeof(Color) == "Color3", "Color must be a Color3 value.")

            ImageLabel.ImageColor3 = Color
            Image.Color = Color
        end

        function Image:SetRectOffset(RectOffset: Vector2)
            assert(typeof(RectOffset) == "Vector2", "RectOffset must be a Vector2 value.")

            ImageLabel.ImageRectOffset = RectOffset
            Image.RectOffset = RectOffset
        end

        function Image:SetRectSize(RectSize: Vector2)
            assert(typeof(RectSize) == "Vector2", "RectSize must be a Vector2 value.")

            ImageLabel.ImageRectSize = RectSize
            Image.RectSize = RectSize
        end

        function Image:SetScaleType(ScaleType: Enum.ScaleType)
            assert(
                typeof(ScaleType) == "EnumItem" and ScaleType:IsA("ScaleType"),
                "ScaleType must be a valid Enum.ScaleType."
            )

            ImageLabel.ScaleType = ScaleType
            Image.ScaleType = ScaleType
        end

        function Image:SetTransparency(Transparency: number)
            assert(typeof(Transparency) == "number", "Transparency must be a number between 0 and 1.")
            assert(Transparency >= 0 and Transparency <= 1, "Transparency must be between 0 and 1.")

            ImageLabel.ImageTransparency = Transparency
            Image.Transparency = Transparency
        end

        function Image:SetVisible(Visible: boolean)
            Image.Visible = Visible

            Holder.Visible = Image.Visible
            Groupbox:Resize()
        end

        Groupbox:Resize()

        Image.Holder = Holder
        table.insert(Groupbox.Elements, Image)

        Options[Idx] = Image

        return Image
    end

    function Funcs:AddVideo(Idx, Info)
        Info = Library:Validate(Info, Templates.Video)

        local Groupbox = self
        local Container = Groupbox.Container

        local Video = {
            Video = Info.Video,
            Looped = Info.Looped,
            Playing = Info.Playing,
            Volume = Info.Volume,
            Height = Info.Height,
            Visible = Info.Visible,

            Type = "Video",
        }

        local Holder = New("Frame", {
            BackgroundTransparency = 1,
            Size = UDim2.new(1, 0, 0, Info.Height),
            Visible = Video.Visible,
            Parent = Container,
        })

        local Box = New("Frame", {
            AnchorPoint = Vector2.new(0, 1),
            BackgroundColor3 = "MainColor",
            BorderColor3 = "OutlineColor",
            BorderSizePixel = 1,
            Position = UDim2.fromScale(0, 1),
            Size = UDim2.fromScale(1, 1),
            Parent = Holder,
        })

        New("UIPadding", {
            PaddingBottom = UDim.new(0, 3),
            PaddingLeft = UDim.new(0, 8),
            PaddingRight = UDim.new(0, 8),
            PaddingTop = UDim.new(0, 4),
            Parent = Box,
        })

        local VideoFrameInstance = New("VideoFrame", {
            BackgroundTransparency = 1,
            Size = UDim2.fromScale(1, 1),
            Video = Video.Video,
            Looped = Video.Looped,
            Volume = Video.Volume,
            Parent = Box,
        })

        VideoFrameInstance.Playing = Video.Playing

        function Video:SetHeight(Height: number)
            assert(Height > 0, "Height must be greater than 0.")

            Video.Height = Height
            Holder.Size = UDim2.new(1, 0, 0, Height)
            Groupbox:Resize()
        end

        function Video:SetVideo(NewVideo: string)
            assert(typeof(NewVideo) == "string", "Video must be a string.")

            VideoFrameInstance.Video = NewVideo
            Video.Video = NewVideo
        end

        function Video:SetLooped(Looped: boolean)
            assert(typeof(Looped) == "boolean", "Looped must be a boolean.")

            VideoFrameInstance.Looped = Looped
            Video.Looped = Looped
        end

        function Video:SetVolume(Volume: number)
            assert(typeof(Volume) == "number", "Volume must be a number between 0 and 10.")

            VideoFrameInstance.Volume = Volume
            Video.Volume = Volume
        end

        function Video:SetPlaying(Playing: boolean)
            assert(typeof(Playing) == "boolean", "Playing must be a boolean.")

            VideoFrameInstance.Playing = Playing
            Video.Playing = Playing
        end

        function Video:Play()
            VideoFrameInstance.Playing = true
            Video.Playing = true
        end

        function Video:Pause()
            VideoFrameInstance.Playing = false
            Video.Playing = false
        end

        function Video:SetVisible(Visible: boolean)
            Video.Visible = Visible

            Holder.Visible = Video.Visible
            Groupbox:Resize()
        end

        Groupbox:Resize()

        Video.Holder = Holder
        Video.VideoFrame = VideoFrameInstance
        table.insert(Groupbox.Elements, Video)

        Options[Idx] = Video

        return Video
    end

    function Funcs:AddUIPassthrough(Idx, Info)
        Info = Library:Validate(Info, Templates.UIPassthrough)

        local Groupbox = self
        local Container = Groupbox.Container

        assert(Info.Instance, "Instance must be provided.")
        assert(
            typeof(Info.Instance) == "Instance" and Info.Instance:IsA("GuiBase2d"),
            "Instance must inherit from GuiBase2d."
        )
        assert(typeof(Info.Height) == "number" and Info.Height > 0, "Height must be a number greater than 0.")

        local Passthrough = {
            Instance = Info.Instance,
            Height = Info.Height,
            Visible = Info.Visible,

            Type = "UIPassthrough",
        }

        local Holder = New("Frame", {
            BackgroundTransparency = 1,
            Size = UDim2.new(1, 0, 0, Info.Height),
            Visible = Passthrough.Visible,
            Parent = Container,
        })

        Passthrough.Instance.Parent = Holder

        Groupbox:Resize()

        function Passthrough:SetHeight(Height: number)
            assert(typeof(Height) == "number" and Height > 0, "Height must be a number greater than 0.")

            Passthrough.Height = Height
            Holder.Size = UDim2.new(1, 0, 0, Height)
            Groupbox:Resize()
        end

        function Passthrough:SetInstance(Instance: Instance)
            assert(Instance, "Instance must be provided.")
            assert(
                typeof(Instance) == "Instance" and Instance:IsA("GuiBase2d"),
                "Instance must inherit from GuiBase2d."
            )

            if Passthrough.Instance then
                Passthrough.Instance.Parent = nil
            end

            Passthrough.Instance = Instance
            Passthrough.Instance.Parent = Holder
        end

        function Passthrough:SetVisible(Visible: boolean)
            Passthrough.Visible = Visible

            Holder.Visible = Passthrough.Visible
            Groupbox:Resize()
        end

        Passthrough.Holder = Holder
        table.insert(Groupbox.Elements, Passthrough)

        Options[Idx] = Passthrough

        return Passthrough
    end

    function Funcs:AddDependencyBox()
        local Groupbox = self
        local Container = Groupbox.Container

        local DepboxContainer
        local DepboxList

        do
            DepboxContainer = New("Frame", {
                BackgroundTransparency = 1,
                Size = UDim2.fromScale(1, 1),
                Visible = false,
                Parent = Container,
            })

            DepboxList = New("UIListLayout", {
                Padding = UDim.new(0, 8),
                Parent = DepboxContainer,
            })
        end

        local Depbox = {
            Visible = false,
            Dependencies = {},

            Holder = DepboxContainer,
            Container = DepboxContainer,

            Elements = {},
            DependencyBoxes = {},
        }

        function Depbox:Resize()
            DepboxContainer.Size = UDim2.new(1, 0, 0, DepboxList.AbsoluteContentSize.Y / Library.DPIScale)
            Groupbox:Resize()
        end

        function Depbox:Update(CancelSearch)
            for _, Dependency in Depbox.Dependencies do
                local Element = Dependency[1]
                local Value = Dependency[2]

                if Element.Type == "Toggle" and Element.Value ~= Value then
                    DepboxContainer.Visible = false
                    Depbox.Visible = false
                    return
                elseif Element.Type == "Dropdown" then
                    if typeof(Element.Value) == "table" then
                        if not Element.Value[Value] then
                            DepboxContainer.Visible = false
                            Depbox.Visible = false
                            return
                        end
                    else
                        if Element.Value ~= Value then
                            DepboxContainer.Visible = false
                            Depbox.Visible = false
                            return
                        end
                    end
                end
            end

            Depbox.Visible = true
            DepboxContainer.Visible = true
            if not Library.Searching then
                task.defer(function()
                    Depbox:Resize()
                end)
            elseif not CancelSearch then
                Library:UpdateSearch(Library.SearchText)
            end
        end

        DepboxList:GetPropertyChangedSignal("AbsoluteContentSize"):Connect(function()
            if not Depbox.Visible then
                return
            end

            Depbox:Resize()
        end)

        function Depbox:SetupDependencies(Dependencies)
            for _, Dependency in Dependencies do
                assert(typeof(Dependency) == "table", "Dependency should be a table.")
                assert(Dependency[1] ~= nil, "Dependency is missing element.")
                assert(Dependency[2] ~= nil, "Dependency is missing expected value.")
            end

            Depbox.Dependencies = Dependencies
            Depbox:Update()
        end

        DepboxContainer:GetPropertyChangedSignal("Visible"):Connect(function()
            Depbox:Resize()
        end)

        setmetatable(Depbox, BaseGroupbox)

        table.insert(Groupbox.DependencyBoxes, Depbox)
        table.insert(Library.DependencyBoxes, Depbox)

        return Depbox
    end

    function Funcs:AddDependencyGroupbox()
        local Groupbox = self
        local Tab = Groupbox.Tab
        local BoxHolder = Groupbox.BoxHolder

        local DepGroupboxContainer
        local DepGroupboxList

        do
            DepGroupboxContainer = New("Frame", {
                BackgroundColor3 = "BackgroundColor",
                Size = UDim2.fromScale(1, 0),
                Visible = false,
                Parent = BoxHolder,
            })
            New("UICorner", {
                CornerRadius = UDim.new(0, Library.CornerRadius),
                Parent = DepGroupboxContainer,
            })
            Library:AddOutline(DepGroupboxContainer)

            DepGroupboxList = New("UIListLayout", {
                Padding = UDim.new(0, 8),
                Parent = DepGroupboxContainer,
            })
            New("UIPadding", {
                PaddingBottom = UDim.new(0, 7),
                PaddingLeft = UDim.new(0, 7),
                PaddingRight = UDim.new(0, 7),
                PaddingTop = UDim.new(0, 7),
                Parent = DepGroupboxContainer,
            })
        end

        local DepGroupbox = {
            Visible = false,
            Dependencies = {},

            BoxHolder = BoxHolder,
            Holder = DepGroupboxContainer,
            Container = DepGroupboxContainer,

            Tab = Tab,
            Elements = {},
            DependencyBoxes = {},
        }

        function DepGroupbox:Resize()
            DepGroupboxContainer.Size = UDim2.new(1, 0, 0, (DepGroupboxList.AbsoluteContentSize.Y / Library.DPIScale) + 18)
        end

        function DepGroupbox:Update(CancelSearch)
            for _, Dependency in DepGroupbox.Dependencies do
                local Element = Dependency[1]
                local Value = Dependency[2]

                if Element.Type == "Toggle" and Element.Value ~= Value then
                    DepGroupboxContainer.Visible = false
                    DepGroupbox.Visible = false
                    return
                elseif Element.Type == "Dropdown" then
                    if typeof(Element.Value) == "table" then
                        if not Element.Value[Value] then
                            DepGroupboxContainer.Visible = false
                            DepGroupbox.Visible = false
                            return
                        end
                    else
                        if Element.Value ~= Value then
                            DepGroupboxContainer.Visible = false
                            DepGroupbox.Visible = false
                            return
                        end
                    end
                end
            end

            DepGroupbox.Visible = true
            if not Library.Searching then
                DepGroupboxContainer.Visible = true
                DepGroupbox:Resize()
            elseif not CancelSearch then
                Library:UpdateSearch(Library.SearchText)
            end
        end

        function DepGroupbox:SetupDependencies(Dependencies)
            for _, Dependency in Dependencies do
                assert(typeof(Dependency) == "table", "Dependency should be a table.")
                assert(Dependency[1] ~= nil, "Dependency is missing element.")
                assert(Dependency[2] ~= nil, "Dependency is missing expected value.")
            end

            DepGroupbox.Dependencies = Dependencies
            DepGroupbox:Update()
        end

        setmetatable(DepGroupbox, BaseGroupbox)

        table.insert(Tab.DependencyGroupboxes, DepGroupbox)
        table.insert(Library.DependencyBoxes, DepGroupbox)

        return DepGroupbox
    end

    BaseGroupbox.__index = Funcs
    BaseGroupbox.__namecall = function(_, Key, ...)
        return Funcs[Key](...)
    end
end

function Library:SetFont(FontFace)
    Library.Scheme.Font = NormalizeFontValue(FontFace)
    Library:UpdateColorsUsingRegistry()
end

function Library:SetNotifySide(Side: string)
    Library.NotifySide = Side

    if Side:lower() == "left" then
        NotificationArea.AnchorPoint = Vector2.new(0, 0)
        NotificationArea.Position = UDim2.fromOffset(6, 6)
        NotificationList.HorizontalAlignment = Enum.HorizontalAlignment.Left
    else
        NotificationArea.AnchorPoint = Vector2.new(1, 0)
        NotificationArea.Position = UDim2.new(1, -6, 0, 6)
        NotificationList.HorizontalAlignment = Enum.HorizontalAlignment.Right
    end
end

function Library:Notify(...)
    local Data = {}
    local Info = select(1, ...)

    if typeof(Info) == "table" then
        Data.Title = tostring(Info.Title)
        Data.Description = tostring(Info.Description)
        Data.Time = Info.Time or 5
        Data.SoundId = Info.SoundId
        Data.Steps = Info.Steps
        Data.Persist = Info.Persist
        Data.Icon = Info.Icon
        Data.BigIcon = Info.BigIcon
        Data.IconColor = Info.IconColor
    else
        Data.Description = tostring(Info)
        Data.Time = select(2, ...) or 5
        Data.SoundId = select(3, ...)
    end
    Data.Destroyed = false

    local DeletedInstance = false
    local DeleteConnection = nil
    if typeof(Data.Time) == "Instance" then
        DeleteConnection = Data.Time.Destroying:Connect(function()
            DeletedInstance = true

            DeleteConnection:Disconnect()
            DeleteConnection = nil
        end)
    end

    local FakeBackground = New("Frame", {
        AutomaticSize = Enum.AutomaticSize.Y,
        BackgroundTransparency = 1,
        Size = UDim2.fromScale(1, 0),
        Visible = false,
        Parent = NotificationArea,
    })

    local Holder = New("Frame", {
        AutomaticSize = Enum.AutomaticSize.Y,
        BackgroundColor3 = "MainColor",
        Position = Library.NotifySide:lower() == "left" and UDim2.new(-1, -8, 0, -2) or UDim2.new(1, 8, 0, -2),
        Size = UDim2.fromScale(1, 1),
        ZIndex = 5,
        Parent = FakeBackground,
    })
    New("UICorner", {
        CornerRadius = UDim.new(0, Library.CornerRadius),
        Parent = Holder,
    })
    New("UIListLayout", {
        Padding = UDim.new(0, 4),
        Parent = Holder,
    })
    New("UIPadding", {
        PaddingBottom = UDim.new(0, 8),
        PaddingLeft = UDim.new(0, 8),
        PaddingRight = UDim.new(0, 8),
        PaddingTop = UDim.new(0, 8),
        Parent = Holder,
    })
    Library:AddOutline(Holder)

    local ContentContainer = New("Frame", {
        BackgroundTransparency = 1,
        AutomaticSize = Enum.AutomaticSize.XY,
        Size = UDim2.fromScale(1, 0),
        Parent = Holder,
    })
    New("UIListLayout", {
        Padding = UDim.new(0, 10),
        FillDirection = Enum.FillDirection.Horizontal,
        VerticalAlignment = Enum.VerticalAlignment.Center,
        Parent = ContentContainer,
    })

    local BigIconLabel
    local VisualHolder = New("Frame", {
        BackgroundColor3 = function()
            return Library:GetUiColor("Control")
        end,
        Size = UDim2.fromOffset(28, 28),
        Parent = ContentContainer,
    })
    New("UICorner", {
        CornerRadius = UDim.new(0, 8),
        Parent = VisualHolder,
    })
    New("UIStroke", {
        Color = function()
            return Library:GetUiColor("SoftOutline")
        end,
        Transparency = 0.15,
        Parent = VisualHolder,
    })

    local ParsedBigIcon = Data.BigIcon and Library:GetCustomIcon(Data.BigIcon) or nil
    BigIconLabel = New("ImageLabel", {
        BackgroundTransparency = 1,
        AnchorPoint = Vector2.new(0.5, 0.5),
        Position = UDim2.fromScale(0.5, 0.5),
        Size = UDim2.fromOffset(18, 18),
        Image = ParsedBigIcon and ParsedBigIcon.Url or "rbxassetid://129289898938555",
        ImageColor3 = Data.IconColor or "AccentColor",
        ImageRectOffset = ParsedBigIcon and ParsedBigIcon.ImageRectOffset or Vector2.zero,
        ImageRectSize = ParsedBigIcon and ParsedBigIcon.ImageRectSize or Vector2.zero,
        Parent = VisualHolder,
    })

    local TextContainer = New("Frame", {
        BackgroundTransparency = 1,
        AutomaticSize = Enum.AutomaticSize.XY,
        Size = UDim2.fromScale(0, 0),
        Parent = ContentContainer,
    })
    New("UIListLayout", {
        Padding = UDim.new(0, 4),
        Parent = TextContainer,
    })
    
    local TitleContainer
    if Data.Title then
        TitleContainer = New("Frame", {
            BackgroundTransparency = 1,
            Size = UDim2.fromScale(0, 0),
            Parent = TextContainer,
        })
    end

    local IconLabel
    if Data.Icon and TitleContainer then
        local ParsedIcon = Library:GetCustomIcon(Data.Icon)
        if ParsedIcon then
            IconLabel = New("ImageLabel", {
                BackgroundTransparency = 1,
                AnchorPoint = Vector2.new(0, 0.5),
                Position = UDim2.new(0, 0, 0.5, 1),
                Size = UDim2.fromOffset(15, 15),
                Image = ParsedIcon.Url,
                ImageColor3 = Data.IconColor or "FontColor",
                ImageRectOffset = ParsedIcon.ImageRectOffset,
                ImageRectSize = ParsedIcon.ImageRectSize,
                Parent = TitleContainer,
            })
        end
    end

    local Title
    local Desc
    local TitleX = 0
    local DescX = 0

    local TimerFill

    if Data.Title then
        Title = New("TextLabel", {
            AutomaticSize = Enum.AutomaticSize.None,
            BackgroundTransparency = 1,
            AnchorPoint = Vector2.new(0, 0.5),
            Position = UDim2.new(0, (Data.Icon and 21 or 0), 0.5, 0),
            Size = UDim2.fromScale(0, 0),
            Text = Data.Title,
            TextSize = 15,
            TextXAlignment = Enum.TextXAlignment.Left,
            TextYAlignment = Enum.TextYAlignment.Center,
            TextWrapped = true,
            Parent = TitleContainer,
        })
    end

    if Data.Description then
        Desc = New("TextLabel", {
            AutomaticSize = Enum.AutomaticSize.None,
            BackgroundTransparency = 1,
            Size = UDim2.fromScale(0, 0),
            Text = Data.Description,
            TextSize = 14,
            TextXAlignment = Enum.TextXAlignment.Left,
            TextWrapped = true,
            Parent = TextContainer,
        })
    end

    function Data:Resize()
        local ExtraWidth = BigIconLabel and 32 or 0
        local IconWidth = IconLabel and 21 or 0

        if Title then
            local X, Y =
                Library:GetTextBounds(Title.Text, Title.FontFace, Title.TextSize, (NotificationArea.AbsoluteSize.X / Library.DPIScale) - 24 - ExtraWidth - IconWidth)
            Title.Size = UDim2.fromOffset(X, Y)
            TitleX = X + IconWidth
            TitleContainer.Size = UDim2.fromOffset(TitleX, math.max(Y, IconLabel and 16 or 0))
        end

        if Desc then
            local X, Y =
                Library:GetTextBounds(Desc.Text, Desc.FontFace, Desc.TextSize, (NotificationArea.AbsoluteSize.X / Library.DPIScale) - 24 - ExtraWidth)
            Desc.Size = UDim2.fromOffset(X, Y)
            DescX = X
        end

        FakeBackground.Size = UDim2.fromOffset(math.max(TitleX, DescX) + 24 + ExtraWidth, 0)
    end

    function Data:ChangeTitle(Text)
        if Title then
            Data.Title = tostring(Text)
            Title.Text = Data.Title
            Data:Resize()
        end
    end

    function Data:ChangeDescription(Text)
        if Desc then
            Data.Description = tostring(Text)
            Desc.Text = Data.Description
            Data:Resize()
        end
    end

    function Data:ChangeStep(NewStep)
        if TimerFill and Data.Steps then
            NewStep = math.clamp(NewStep or 0, 0, Data.Steps)
            TimerFill.Size = UDim2.fromScale(NewStep / Data.Steps, 1)
        end
    end

    function Data:Destroy()
        Data.Destroyed = true

        if typeof(Data.Time) == "Instance" then
            pcall(Data.Time.Destroy, Data.Time)
        end

        if DeleteConnection then
            DeleteConnection:Disconnect()
        end

        TweenService
            :Create(Holder, Library.NotifyTweenInfo, {
                Position = Library.NotifySide:lower() == "left" and UDim2.new(-1, -8, 0, -2) or UDim2.new(1, 8, 0, -2),
            })
            :Play()

        task.delay(Library.NotifyTweenInfo.Time, function()
            Library.Notifications[FakeBackground] = nil
            FakeBackground:Destroy()
        end)
    end

    Data:Resize()

    local TimerHolder = New("Frame", {
        BackgroundTransparency = 1,
        Size = UDim2.new(1, 0, 0, 7),
        Visible = (Data.Persist ~= true and typeof(Data.Time) ~= "Instance") or typeof(Data.Steps) == "number",
        Parent = Holder,
    })
    local TimerBar = New("Frame", {
        BackgroundColor3 = "BackgroundColor",
        BorderColor3 = "OutlineColor",
        BorderSizePixel = 1,
        Position = UDim2.fromOffset(0, 3),
        Size = UDim2.new(1, 0, 0, 2),
        Parent = TimerHolder,
    })
    TimerFill = New("Frame", {
        BackgroundColor3 = "AccentColor",
        Size = UDim2.fromScale(1, 1),
        Parent = TimerBar,
    })

    if typeof(Data.Time) == "Instance" then
        TimerFill.Size = UDim2.fromScale(0, 1)
    end
    if Data.SoundId then
        local SoundId = Data.SoundId
        if typeof(SoundId) == "number" then
            SoundId = string.format("rbxassetid://%d", SoundId)
        end

        New("Sound", {
            SoundId = SoundId,
            Volume = 3,
            PlayOnRemove = true,
            Parent = SoundService,
        }):Destroy()
    end

    Library.Notifications[FakeBackground] = Data

    FakeBackground.Visible = true
    TweenService:Create(Holder, Library.NotifyTweenInfo, {
        Position = UDim2.fromOffset(0, 0),
    }):Play()

    task.delay(Library.NotifyTweenInfo.Time, function()
        if Data.Persist then
            return
        elseif typeof(Data.Time) == "Instance" then
            repeat
                task.wait()
            until DeletedInstance or Data.Destroyed
        else
            TweenService
                :Create(TimerFill, TweenInfo.new(Data.Time, Enum.EasingStyle.Linear, Enum.EasingDirection.InOut), {
                    Size = UDim2.fromScale(0, 1),
                })
                :Play()
            task.wait(Data.Time)
        end

        if not Data.Destroyed then
            Data:Destroy()
        end
    end)

    return Data
end

function Library:CreateWindow(WindowInfo)
    WindowInfo = Library:Validate(WindowInfo, Templates.Window)
    local function GetStableViewportSize()
        local Camera = workspace.CurrentCamera
        local Viewport = Camera and Camera.ViewportSize or Vector2.zero
        local LastViewport = Viewport
        local StableFrames = 0
        local StartedAt = os.clock()

        while os.clock() - StartedAt < 3 do
            if Viewport.X >= 320 and Viewport.Y >= 200 then
                if math.abs(Viewport.X - LastViewport.X) < 1 and math.abs(Viewport.Y - LastViewport.Y) < 1 then
                    StableFrames += 1
                else
                    StableFrames = 0
                end

                if StableFrames >= 2 then
                    break
                end
            else
                StableFrames = 0
            end

            RunService.RenderStepped:Wait()
            Camera = workspace.CurrentCamera
            LastViewport = Viewport
            Viewport = Camera and Camera.ViewportSize or Vector2.zero
        end

        return Viewport
    end

    local ViewportSize: Vector2 = GetStableViewportSize()

    local MaxX = ViewportSize.X - 64
    local MaxY = ViewportSize.Y - 64

    Library.OriginalMinSize =
        Vector2.new(math.min(Library.OriginalMinSize.X, MaxX), math.min(Library.OriginalMinSize.Y, MaxY))
    Library.MinSize = Library.OriginalMinSize

    WindowInfo.Size = UDim2.fromOffset(
        math.clamp(WindowInfo.Size.X.Offset, Library.MinSize.X, MaxX),
        math.clamp(WindowInfo.Size.Y.Offset, Library.MinSize.Y, MaxY)
    )

    if WindowInfo.MobileAutoScale and Library.IsMobile and WindowInfo.DPIScale == 100 then
        local ShortestSide = math.min(ViewportSize.X, ViewportSize.Y)
        if ShortestSide <= 640 then
            WindowInfo.DPIScale = 82
        elseif ShortestSide <= 760 then
            WindowInfo.DPIScale = 88
        elseif ShortestSide <= 920 then
            WindowInfo.DPIScale = 94
        end
    end

    WindowInfo.Font = NormalizeFontValue(WindowInfo.Font)
    WindowInfo.CornerRadius = math.min(WindowInfo.CornerRadius, 20)

    --// Old Naming \\--
    if WindowInfo.Compact ~= nil then
        WindowInfo.SidebarCompacted = WindowInfo.Compact
    end
    if WindowInfo.SidebarMinWidth ~= nil then
        WindowInfo.MinSidebarWidth = WindowInfo.SidebarMinWidth
    end
    WindowInfo.MinSidebarWidth = math.max(64, WindowInfo.MinSidebarWidth)
    WindowInfo.SidebarCompactWidth = math.max(48, WindowInfo.SidebarCompactWidth)
    WindowInfo.SidebarCollapseThreshold = math.clamp(WindowInfo.SidebarCollapseThreshold, 0.1, 0.9)
    WindowInfo.CompactWidthActivation = math.max(48, WindowInfo.CompactWidthActivation)

    Library.CornerRadius = WindowInfo.CornerRadius
    Library:SetNotifySide(WindowInfo.NotifySide)
    Library.ShowCustomCursor = WindowInfo.ShowCustomCursor
    Library.Scheme.Font = NormalizeFontValue(WindowInfo.Font)
    Library.ToggleKeybind = WindowInfo.ToggleKeybind
    Library.GlobalSearch = WindowInfo.GlobalSearch

    local IsDefaultSearchbarSize = WindowInfo.SearchbarSize == UDim2.fromScale(1, 1)
    local MainFrame
    local DividerLine
    local TitleDividerLine
    local RailBottomLine
    local TopBarBottomLine
    local TopTabsBottomLine
    local TitleHolder
    local WindowTitle
    local WindowIcon
    local TopBar
    local RightWrapper
    local SearchBox
    local CurrentTabInfo
    local CurrentTabLabel
    local CurrentTabDescription
    local CurrentTabSeparatorA
    local CurrentTabSeparatorB
    local TopTabs
    local ShellDividerLine
    local TopTabsBackground
    local ResizeButton
    local Tabs
    local Container
    local BackgroundImage
    local BackgroundImageFallback
    local ContainerBackgroundImage
    local ContainerBackgroundImageFallback
    local MainScale
    local WindowIconGlow
    local FooterBadge
    local FooterBadgeBackgroundImage
    local FooterBadgeGradient
    local FooterBadgeStroke
    local FooterBadgeIcon
    local FooterBadgeGlow
    local FooterBadgeAvatar
    local FooterBadgeLabel
    local ShellTransparencyTargets = {}
    local function RegisterTransparencyTarget(Instance, Base, Scale)
        if not Instance then
            return
        end

        local Entry = {
            Instance = Instance,
            Base = Base or 0,
            Scale = Scale or 1,
        }

        table.insert(ShellTransparencyTargets, Entry)

        if WindowInfo.UITransparency then
            Instance.BackgroundTransparency = math.clamp(
                (Entry.Base or 0) + (WindowInfo.UITransparency * (Entry.Scale or 1)),
                0,
                1
            )
        end

        return Entry
    end

    local InitialLeftWidth = math.ceil(WindowInfo.Size.X.Offset * 0.3)
    local IsCompact = WindowInfo.SidebarCompacted
    local LastExpandedWidth = InitialLeftWidth

    local Window = {}
    local SidebarBrandLabel
    local SidebarToggleTopButton
    local SidebarToggleChevron
    local LeftRail
    local LeftRailFill

    do
        local ShellRadius = math.max(WindowInfo.CornerRadius, 14)
        local RailWidth = 54
        local TopBarHeight = 42
        local TabBarHeight = 36
        local ContentInset = 3

        Library.KeybindFrame, Library.KeybindContainer = Library:AddDraggableMenu("Keybinds")
        Library.KeybindFrame.AnchorPoint = Vector2.new(0, 0.5)
        Library.KeybindFrame.Position = UDim2.new(0, 6, 0.5, 0)
        Library.KeybindFrame.Visible = false

        MainFrame = New("TextButton", {
            BackgroundColor3 = function()
                return Library:GetUiColor("Shell")
            end,
            Name = "Main",
            Text = "",
            Position = WindowInfo.Position,
            Size = WindowInfo.Size,
            Visible = false,
            Parent = ScreenGui,
        })
        New("UICorner", {
            CornerRadius = UDim.new(0, ShellRadius),
            Parent = MainFrame,
        })
        MainScale = New("UIScale", {
            Parent = MainFrame,
        })
        table.insert(Library.Scales, MainScale)
        Library:AddOutline(MainFrame)

        BackgroundImageFallback = New("ImageLabel", {
            Image = "",
            Position = UDim2.fromScale(0, 0),
            Size = UDim2.fromScale(1, 1),
            ScaleType = Enum.ScaleType.Crop,
            ZIndex = 0,
            BackgroundTransparency = 1,
            ImageTransparency = 1,
            Visible = false,
            Parent = MainFrame,
        })
        New("UICorner", {
            CornerRadius = UDim.new(0, ShellRadius),
            Parent = BackgroundImageFallback,
        })

        BackgroundImage = New("ImageLabel", {
            Image = WindowInfo.BackgroundImage or "",
            Position = UDim2.fromScale(0, 0),
            Size = UDim2.fromScale(1, 1),
            ScaleType = Enum.ScaleType.Crop,
            ZIndex = 0,
            BackgroundTransparency = 1,
            ImageTransparency = (WindowInfo.BackgroundImage ~= nil and WindowInfo.BackgroundImage ~= "")
                    and WindowInfo.BackgroundImageTransparency
                or 1,
            Visible = WindowInfo.BackgroundImage ~= nil and WindowInfo.BackgroundImage ~= "",
            Parent = MainFrame,
        })
        New("UICorner", {
            CornerRadius = UDim.new(0, ShellRadius),
            Parent = BackgroundImage,
        })

        if WindowInfo.Center then
            MainFrame.Position = UDim2.new(0.5, -MainFrame.Size.X.Offset / 2, 0.5, -MainFrame.Size.Y.Offset / 2)
        end

        Window.MainFrame = MainFrame

        local ShellInset = New("Frame", {
            BackgroundTransparency = 1,
            Position = UDim2.fromOffset(2, 2),
            Size = UDim2.new(1, -4, 1, -4),
            Parent = MainFrame,
        })

        LeftRail = New("Frame", {
            BackgroundColor3 = function()
                return Library:GetUiColor("Rail")
            end,
            Size = UDim2.new(0, RailWidth, 1, 0),
            Parent = ShellInset,
        })
        RegisterTransparencyTarget(LeftRail, 0, 1.05)
        New("UICorner", {
            CornerRadius = UDim.new(0, ShellRadius - 2),
            Parent = LeftRail,
        })
        LeftRailFill = New("Frame", {
            BackgroundColor3 = function()
                return Library:GetUiColor("Rail")
            end,
            Position = UDim2.fromOffset(math.floor(RailWidth / 2), 0),
            Size = UDim2.new(0, math.ceil(RailWidth / 2), 1, 0),
            Parent = LeftRail,
        })
        RegisterTransparencyTarget(LeftRailFill, 0, 1.05)

        DividerLine = New("Frame", {
            BackgroundColor3 = function()
                return Library:GetUiColor("Divider")
            end,
            Position = UDim2.fromOffset(RailWidth, 0),
            Size = UDim2.new(0, 1, 1, 0),
            ZIndex = 7,
            Parent = ShellInset,
        })

        TopBar = New("Frame", {
            BackgroundColor3 = function()
                return Library:GetUiColor("Topbar")
            end,
            Position = UDim2.fromOffset(RailWidth, 0),
            Size = UDim2.new(1, -RailWidth, 0, TopBarHeight),
            Parent = ShellInset,
        })
        RegisterTransparencyTarget(TopBar, 0, 0.98)
        New("Frame", {
            BackgroundColor3 = function()
                return Library:GetUiColor("Divider")
            end,
            Position = UDim2.fromOffset(0, 0),
            Size = UDim2.new(0, 1, 0, TopBarHeight),
            Parent = TopBar,
        })
        New("UICorner", {
            CornerRadius = UDim.new(0, ShellRadius - 2),
            Parent = TopBar,
        })
        local TopBarFill = New("Frame", {
            BackgroundColor3 = function()
                return Library:GetUiColor("Topbar")
            end,
            Position = UDim2.fromOffset(0, ShellRadius),
            Size = UDim2.new(1, 0, 1, -ShellRadius),
            Parent = TopBar,
        })
        local TopBarCornerFill = New("Frame", {
            BackgroundColor3 = function()
                return Library:GetUiColor("Topbar")
            end,
            Position = UDim2.fromOffset(0, 0),
            Size = UDim2.new(0, ShellRadius, 0, ShellRadius),
            Parent = TopBar,
        })
        RegisterTransparencyTarget(TopBarFill, 0, 0.98)
        RegisterTransparencyTarget(TopBarCornerFill, 0, 0.98)
        Library:MakeDraggable(MainFrame, TopBar, false, true)

        TitleHolder = New("Frame", {
            BackgroundTransparency = 1,
            ClipsDescendants = false,
            Size = UDim2.new(0, RailWidth, 0, TopBarHeight),
            Parent = ShellInset,
        })
        TitleDividerLine = New("Frame", {
            BackgroundColor3 = function()
                return Library:GetUiColor("Divider")
            end,
            Position = UDim2.fromOffset(RailWidth, 0),
            Size = UDim2.new(0, 1, 0, TopBarHeight),
            ZIndex = 7,
            Parent = ShellInset,
        })
        New("Frame", {
            BackgroundColor3 = function()
                return Library:GetUiColor("Divider")
            end,
            Position = UDim2.new(1, 0, 0, 0),
            Size = UDim2.new(0, 1, 0, TopBarHeight),
            ZIndex = 7,
            Parent = TitleHolder,
        })

        local ParsedWindowIcon = nil
        if WindowInfo.Icon ~= nil and WindowInfo.Icon ~= "" then
            ParsedWindowIcon = Library:GetCustomIcon(tostring(WindowInfo.Icon))
        end
        ParsedWindowIcon = ParsedWindowIcon or Library:GetKojoIcon("kojo-logo")
        if ParsedWindowIcon then

            WindowIconGlow = New("ImageLabel", {
                Image = ParsedWindowIcon.Url,
                ImageRectOffset = ParsedWindowIcon.ImageRectOffset,
                ImageRectSize = ParsedWindowIcon.ImageRectSize,
                AnchorPoint = Vector2.new(0.5, 0.5),
                BackgroundTransparency = 1,
                ImageColor3 = function()
                    return Library:GetUiColor("AccentGlow")
                end,
                ImageTransparency = 0.56,
                Position = UDim2.fromScale(0.5, 0.5),
                Size = UDim2.fromOffset(34, 34),
                Parent = TitleHolder,
            })
            WindowIcon = New("ImageLabel", {
                Image = ParsedWindowIcon.Url,
                ImageRectOffset = ParsedWindowIcon.ImageRectOffset,
                ImageRectSize = ParsedWindowIcon.ImageRectSize,
                AnchorPoint = Vector2.new(0.5, 0.5),
                BackgroundTransparency = 1,
                ImageTransparency = 0.04,
                Position = UDim2.fromScale(0.5, 0.5),
                Size = UDim2.fromOffset(20, 20),
                Parent = TitleHolder,
            })
            AttachImageLoadFallback(WindowIconGlow, ParsedWindowIcon.Url)
            AttachImageLoadFallback(WindowIcon, ParsedWindowIcon.Url)
        else
            WindowIconGlow = New("TextLabel", {
                AnchorPoint = Vector2.new(0.5, 0.5),
                BackgroundTransparency = 1,
                FontFace = function()
                    return Library:GetWeightedFont(Enum.FontWeight.Bold)
                end,
                Position = UDim2.fromScale(0.5, 0.5),
                Size = UDim2.fromOffset(24, 24),
                Text = WindowInfo.Title:sub(1, 1),
                TextColor3 = function()
                    return Library:GetUiColor("AccentFill")
                end,
                TextSize = 22,
                TextTransparency = 0.7,
                Parent = TitleHolder,
            })
            WindowIcon = New("TextLabel", {
                AnchorPoint = Vector2.new(0.5, 0.5),
                BackgroundTransparency = 1,
                FontFace = function()
                    return Library:GetWeightedFont(Enum.FontWeight.Bold)
                end,
                Position = UDim2.fromScale(0.5, 0.5),
                Size = UDim2.fromOffset(22, 22),
                Text = WindowInfo.Title:sub(1, 1),
                TextColor3 = function()
                    return Library:GetUiColor("AccentFill")
                end,
                TextSize = 18,
                Parent = TitleHolder,
            })
        end

        SidebarBrandLabel = New("TextLabel", {
            AnchorPoint = Vector2.new(0, 0.5),
            BackgroundTransparency = 1,
            FontFace = function()
                return Library:GetWeightedFont(Enum.FontWeight.Bold)
            end,
            RichText = false,
            Position = UDim2.new(0, 34, 0.5, 0),
            Size = UDim2.new(1, -40, 0, 20),
            Text = WindowInfo.Title,
            TextColor3 = function()
                return Library:GetUiColor("ActiveText")
            end,
            TextSize = 14,
            TextTransparency = 1,
            TextStrokeTransparency = 1,
            TextTruncate = Enum.TextTruncate.AtEnd,
            TextYAlignment = Enum.TextYAlignment.Center,
            TextXAlignment = Enum.TextXAlignment.Left,
            Visible = true,
            Parent = TitleHolder,
        })

        do
            local SidebarToggleButton = New("TextButton", {
                AutoButtonColor = false,
                BackgroundTransparency = 1,
                Size = UDim2.fromScale(1, 1),
                Text = "",
                ZIndex = 3,
                Parent = TitleHolder,
            })
            SidebarToggleButton.MouseButton1Click:Connect(function()
                Window:ToggleCompact()
            end)
        end

        CurrentTabInfo = New("Frame", {
            BackgroundTransparency = 1,
            ClipsDescendants = false,
            Position = UDim2.fromOffset(12, 0),
            Size = UDim2.new(1, -(WindowInfo.DisableSearch and 24 or 230), 1, 0),
            Parent = TopBar,
        })
        New("UIListLayout", {
            FillDirection = Enum.FillDirection.Horizontal,
            HorizontalAlignment = Enum.HorizontalAlignment.Left,
            VerticalAlignment = Enum.VerticalAlignment.Center,
            Padding = UDim.new(0, 10),
            Parent = CurrentTabInfo,
        })

        WindowTitle = New("TextLabel", {
            AutomaticSize = Enum.AutomaticSize.X,
            BackgroundTransparency = 1,
            FontFace = function()
                return Library:GetWeightedFont(Enum.FontWeight.SemiBold)
            end,
            RichText = false,
            Size = UDim2.fromOffset(0, 20),
            Text = WindowInfo.Title,
            TextColor3 = function()
                return Library:GetUiColor("ActiveText")
            end,
            TextSize = 15,
            TextStrokeTransparency = 1,
            TextTruncate = Enum.TextTruncate.AtEnd,
            TextYAlignment = Enum.TextYAlignment.Center,
            Parent = CurrentTabInfo,
        })

        CurrentTabSeparatorA = New("TextLabel", {
            AutomaticSize = Enum.AutomaticSize.X,
            BackgroundTransparency = 1,
            FontFace = function()
                return Library:GetWeightedFont(Enum.FontWeight.SemiBold)
            end,
            RichText = false,
            Size = UDim2.fromOffset(0, 20),
            Text = "/",
            TextColor3 = function()
                return Library:GetUiColor("MutedText")
            end,
            TextSize = 14,
            TextStrokeTransparency = 1,
            TextYAlignment = Enum.TextYAlignment.Center,
            Visible = false,
            Parent = CurrentTabInfo,
        })

        CurrentTabLabel = New("TextLabel", {
            AutomaticSize = Enum.AutomaticSize.X,
            BackgroundTransparency = 1,
            FontFace = function()
                return Library:GetWeightedFont(Enum.FontWeight.Heavy)
            end,
            RichText = false,
            Size = UDim2.fromOffset(0, 20),
            Text = "",
            TextColor3 = function()
                return Library:GetUiColor("ActiveText")
            end,
            TextSize = 15,
            TextStrokeTransparency = 1,
            TextTruncate = Enum.TextTruncate.AtEnd,
            TextYAlignment = Enum.TextYAlignment.Center,
            Parent = CurrentTabInfo,
        })

        CurrentTabSeparatorB = New("TextLabel", {
            AutomaticSize = Enum.AutomaticSize.X,
            BackgroundTransparency = 1,
            FontFace = function()
                return Library:GetWeightedFont(Enum.FontWeight.SemiBold)
            end,
            RichText = false,
            Size = UDim2.fromOffset(0, 20),
            Text = "/",
            TextColor3 = function()
                return Library:GetUiColor("MutedText")
            end,
            TextSize = 14,
            TextStrokeTransparency = 1,
            TextYAlignment = Enum.TextYAlignment.Center,
            Visible = false,
            Parent = CurrentTabInfo,
        })

        CurrentTabDescription = New("TextLabel", {
            AutomaticSize = Enum.AutomaticSize.X,
            BackgroundTransparency = 1,
            FontFace = function()
                return Library:GetWeightedFont(Enum.FontWeight.SemiBold)
            end,
            RichText = false,
            Size = UDim2.fromOffset(0, 20),
            Text = "",
            TextColor3 = function()
                return Library:GetUiColor("ActiveText")
            end,
            TextSize = 15,
            TextStrokeTransparency = 1,
            TextTruncate = Enum.TextTruncate.AtEnd,
            TextYAlignment = Enum.TextYAlignment.Center,
            Parent = CurrentTabInfo,
        })

        RightWrapper = New("Frame", {
            AnchorPoint = Vector2.new(1, 0.5),
            BackgroundTransparency = 1,
            Position = UDim2.new(1, -14, 0.5, 0),
            Size = UDim2.fromOffset(WindowInfo.DisableSearch and 214 or 356, 28),
            Parent = TopBar,
        })
        New("UIListLayout", {
            FillDirection = Enum.FillDirection.Horizontal,
            HorizontalAlignment = Enum.HorizontalAlignment.Right,
            VerticalAlignment = Enum.VerticalAlignment.Center,
            Padding = UDim.new(0, 8),
            Parent = RightWrapper,
        })

        if not (WindowInfo.DisableSearch or false) then
            SearchBox = New("TextBox", {
                BackgroundColor3 = function()
                    return Library:GetUiColor("Control")
                end,
                ClearTextOnFocus = false,
                FontFace = function()
                    return Library:GetWeightedFont(Enum.FontWeight.Medium)
                end,
                PlaceholderText = "Search",
                PlaceholderColor3 = function()
                    return Library:GetUiColor("SubtleText")
                end,
                Size = UDim2.fromOffset(138, 28),
                TextSize = 14,
                TextXAlignment = Enum.TextXAlignment.Left,
                Visible = true,
                Parent = RightWrapper,
            })
            RegisterTransparencyTarget(SearchBox, 0.02, 0.92)
            New("UICorner", {
                CornerRadius = UDim.new(0, 8),
                Parent = SearchBox,
            })
            New("UIPadding", {
                PaddingLeft = UDim.new(0, 10),
                PaddingRight = UDim.new(0, 10),
                Parent = SearchBox,
            })
            New("UIStroke", {
                Color = function()
                    return Library:GetUiColor("SoftOutline")
                end,
                Parent = SearchBox,
            })
        end

        FooterBadge = New("Frame", {
            BackgroundColor3 = function()
                return Library:GetUiColor("Control")
            end,
            ClipsDescendants = true,
            Size = UDim2.fromOffset(144, 28),
            Parent = RightWrapper,
        })
        RegisterTransparencyTarget(FooterBadge, 0.02, 0.92)
        New("UICorner", {
            CornerRadius = UDim.new(0, 8),
            Parent = FooterBadge,
        })
        FooterBadgeBackgroundImage = New("ImageLabel", {
            BackgroundTransparency = 1,
            Image = WindowInfo.FooterBackgroundImage or "",
            ImageTransparency = WindowInfo.FooterBackgroundImage == "" and 1 or (WindowInfo.FooterBackgroundTransparency or 0.28),
            Position = UDim2.fromScale(0, 0),
            ScaleType = Enum.ScaleType.Crop,
            Size = UDim2.fromScale(1, 1),
            Parent = FooterBadge,
        })
        New("UICorner", {
            CornerRadius = UDim.new(0, 8),
            Parent = FooterBadgeBackgroundImage,
        })
        FooterBadgeGlow = New("Frame", {
            AnchorPoint = Vector2.new(0, 0.5),
            BackgroundColor3 = function()
                return Library:GetUiColor("AccentSoft")
            end,
            BackgroundTransparency = 0.8,
            Position = UDim2.new(0, 5, 0.5, 0),
            Size = UDim2.fromOffset(20, 20),
            Parent = FooterBadge,
        })
        New("UICorner", {
            CornerRadius = UDim.new(1, 0),
            Parent = FooterBadgeGlow,
        })
        FooterBadgeAvatar = New("ImageLabel", {
            BackgroundTransparency = 1,
            Image = WindowInfo.FooterAvatar or "",
            ImageTransparency = WindowInfo.FooterAvatar == "" and 1 or 0,
            Position = UDim2.fromOffset(5, 4),
            ScaleType = Enum.ScaleType.Crop,
            Size = UDim2.fromOffset(20, 20),
            Parent = FooterBadge,
        })
        New("UICorner", {
            CornerRadius = UDim.new(1, 0),
            Parent = FooterBadgeAvatar,
        })
        FooterBadgeGradient = New("UIGradient", {
            Color = ColorSequence.new({
                ColorSequenceKeypoint.new(0, Library:GetUiColor("Control")),
                ColorSequenceKeypoint.new(1, Library:GetUiColor("Control")),
            }),
            Rotation = 0,
            Parent = FooterBadge,
        })
        FooterBadgeStroke = New("UIStroke", {
            Color = function()
                return Library:GetUiColor("SoftOutline")
            end,
            Parent = FooterBadge,
        })
        FooterBadgeIcon = New("ImageLabel", {
            BackgroundTransparency = 1,
            ImageTransparency = 0.2,
            Position = UDim2.new(1, -22, 0, 6),
            Size = UDim2.fromOffset(14, 14),
            Parent = FooterBadge,
        })
        FooterBadgeLabel = New("TextLabel", {
            BackgroundTransparency = 1,
            FontFace = function()
                return Library:GetWeightedFont(Enum.FontWeight.Bold)
            end,
            Position = UDim2.fromOffset(30, 0),
            Size = UDim2.new(1, -52, 1, 0),
            Text = WindowInfo.Footer,
            TextSize = 14,
            TextXAlignment = Enum.TextXAlignment.Left,
            Parent = FooterBadge,
        })

        RailBottomLine = Library:MakeLine(ShellInset, {
            Position = UDim2.fromOffset(0, TopBarHeight),
            Size = UDim2.new(0, RailWidth, 0, 1),
        })

        TopBarBottomLine = Library:MakeLine(ShellInset, {
            Position = UDim2.fromOffset(RailWidth, TopBarHeight),
            Size = UDim2.new(1, -RailWidth, 0, 1),
        })

        TopTabsBackground = New("Frame", {
            BackgroundColor3 = function()
                return Library:GetUiColor("Topbar")
            end,
            Position = UDim2.fromOffset(RailWidth, TopBarHeight + 1),
            Size = UDim2.new(1, -RailWidth, 0, TabBarHeight - 1),
            Parent = ShellInset,
        })
        RegisterTransparencyTarget(TopTabsBackground, 0, 1.02)

        TopTabs = New("Frame", {
            BackgroundTransparency = 1,
            Position = UDim2.fromOffset(RailWidth + 4, TopBarHeight),
            Size = UDim2.new(1, -(RailWidth + 8), 0, TabBarHeight),
            Parent = ShellInset,
        })
        New("UIListLayout", {
            FillDirection = Enum.FillDirection.Horizontal,
            HorizontalAlignment = Enum.HorizontalAlignment.Left,
            VerticalAlignment = Enum.VerticalAlignment.Center,
            Padding = UDim.new(0, 8),
            Parent = TopTabs,
        })

        TopTabsBottomLine = Library:MakeLine(ShellInset, {
            Position = UDim2.fromOffset(RailWidth, TopBarHeight + TabBarHeight),
            Size = UDim2.new(1, -RailWidth, 0, 1),
        })

        Tabs = New("ScrollingFrame", {
            AutomaticCanvasSize = Enum.AutomaticSize.Y,
            BackgroundTransparency = 1,
            CanvasSize = UDim2.fromScale(0, 0),
            Position = UDim2.fromOffset(0, TopBarHeight + 4),
            ScrollBarThickness = 0,
            Size = UDim2.new(0, RailWidth, 1, -(TopBarHeight + 4)),
            Parent = ShellInset,
        })
        New("UIListLayout", {
            HorizontalAlignment = Enum.HorizontalAlignment.Center,
            Padding = UDim.new(0, 6),
            Parent = Tabs,
        })
        New("UIPadding", {
            PaddingTop = UDim.new(0, 8),
            Parent = Tabs,
        })

        Container = New("Frame", {
            BackgroundColor3 = function()
                return Library:GetUiColor("Panel")
            end,
            ClipsDescendants = true,
            Name = "Container",
            Position = UDim2.fromOffset(RailWidth + ContentInset, TopBarHeight + TabBarHeight + 3),
            Size = UDim2.new(1, -(RailWidth + ContentInset * 2 + 1), 1, -(TopBarHeight + TabBarHeight + 7)),
            Parent = ShellInset,
        })
        RegisterTransparencyTarget(Container, 0.02, 0.96)
        New("UICorner", {
            CornerRadius = UDim.new(0, ShellRadius - 2),
            Parent = Container,
        })
        Library:AddOutline(Container)
        ContainerBackgroundImageFallback = New("ImageLabel", {
            Image = "",
            BackgroundTransparency = 1,
            ImageTransparency = 1,
            Position = UDim2.fromScale(0, 0),
            ScaleType = Enum.ScaleType.Crop,
            Size = UDim2.fromScale(1, 1),
            Visible = false,
            ZIndex = 0,
            Parent = Container,
        })
        New("UICorner", {
            CornerRadius = UDim.new(0, ShellRadius - 2),
            Parent = ContainerBackgroundImageFallback,
        })

        ContainerBackgroundImage = New("ImageLabel", {
            Image = WindowInfo.BackgroundImage or "",
            BackgroundTransparency = 1,
            ImageTransparency = (WindowInfo.BackgroundImage ~= nil and WindowInfo.BackgroundImage ~= "")
                    and math.min(0.96, WindowInfo.BackgroundImageTransparency + 0.08)
                or 1,
            Position = UDim2.fromScale(0, 0),
            ScaleType = Enum.ScaleType.Crop,
            Size = UDim2.fromScale(1, 1),
            Visible = WindowInfo.BackgroundImage ~= nil and WindowInfo.BackgroundImage ~= "",
            ZIndex = 0,
            Parent = Container,
        })
        New("UICorner", {
            CornerRadius = UDim.new(0, ShellRadius - 2),
            Parent = ContainerBackgroundImage,
        })
        New("UIPadding", {
            PaddingLeft = UDim.new(0, 4),
            PaddingRight = UDim.new(0, 4),
            Parent = Container,
        })

        ShellDividerLine = New("Frame", {
            BackgroundColor3 = function()
                return Library:GetUiColor("Divider")
            end,
            Position = UDim2.fromOffset(RailWidth, 0),
            Size = UDim2.new(0, 1, 1, 0),
            Visible = false,
            ZIndex = 8,
            Parent = ShellInset,
        })

        if WindowInfo.Resizable then
            ResizeButton = New("TextButton", {
                AnchorPoint = Vector2.new(1, 1),
                BackgroundTransparency = 1,
                Position = UDim2.new(1, -4, 1, -4),
                Size = UDim2.fromOffset(18, 18),
                Text = "",
                Parent = MainFrame,
            })

            Library:MakeResizable(MainFrame, ResizeButton, function()
                for _, Tab in Library.Tabs do
                    if typeof(Tab) == "table" and Tab.Resize then
                        Tab:Resize(true)
                    end
                end
            end)
        end

        local function RepositionSidePanels()
            if Library.KeybindFrame and Library.KeybindFrame.Parent and MainFrame then
                Library.KeybindFrame.AnchorPoint = Vector2.new(1, 0.5)
                Library.KeybindFrame.Position = UDim2.fromOffset(
                    MainFrame.AbsolutePosition.X - 10,
                    MainFrame.AbsolutePosition.Y + math.floor(MainFrame.AbsoluteSize.Y * 0.5)
                )
            end
        end

        RepositionSidePanels()
        Library:GiveSignal(MainFrame:GetPropertyChangedSignal("AbsolutePosition"):Connect(RepositionSidePanels))
        Library:GiveSignal(MainFrame:GetPropertyChangedSignal("AbsoluteSize"):Connect(RepositionSidePanels))
        Library:GiveSignal(Library.KeybindFrame:GetPropertyChangedSignal("AbsoluteSize"):Connect(RepositionSidePanels))
    end

    local WindowToggleToken = 0
    local WindowPositionTween
    local WindowScaleTween
    local WindowGlowTween

    local function SetWindowGlowTransparency(Value)
        if not WindowIconGlow then
            return
        end

        if WindowIconGlow:IsA("ImageLabel") then
            WindowIconGlow.ImageTransparency = Value
        else
            WindowIconGlow.TextTransparency = Value
        end
    end

    local function TweenWindowGlow(Size, Transparency, TweenData)
        if not WindowIconGlow then
            return
        end

        local Properties = {
            Size = Size,
        }

        if WindowIconGlow:IsA("ImageLabel") then
            Properties.ImageTransparency = Transparency
        else
            Properties.TextTransparency = Transparency
        end

        StopTween(WindowGlowTween)
        WindowGlowTween = TweenService:Create(WindowIconGlow, TweenData, Properties)
        WindowGlowTween:Play()
    end

    --// Window Table \\--

    local function ApplyBackgroundVisuals()
        local RequestedTransparency = math.clamp(WindowInfo.BackgroundImageTransparency or 1, 0, 1)
        local MainImageTransparency = RequestedTransparency
        local ContentImageTransparency = RequestedTransparency

        if BackgroundImageFallback then
            BackgroundImageFallback.ImageTransparency = BackgroundImageFallback.Visible and MainImageTransparency or 1
        end
        BackgroundImage.ImageTransparency = BackgroundImage.Visible and MainImageTransparency or 1
        if ContainerBackgroundImageFallback then
            ContainerBackgroundImageFallback.ImageTransparency = ContainerBackgroundImageFallback.Visible and ContentImageTransparency
                or 1
        end
        if ContainerBackgroundImage then
            ContainerBackgroundImage.ImageTransparency = ContainerBackgroundImage.Visible and ContentImageTransparency
                or 1
        end
    end

    function Window:RegisterTransparencyTarget(Instance, Base, Scale)
        return RegisterTransparencyTarget(Instance, Base, Scale)
    end

    function Window:ChangeTitle(title)
        assert(typeof(title) == "string", "Expected string for title got: " .. typeof(title))

        WindowTitle.Text = title
        WindowInfo.Title = title
    end

    function Window:SetBackgroundImage(Image)
        assert(typeof(Image) == "string", "Expected string for Image got: " .. typeof(Image))

        local AssetId = Image ~= "" and Image:match("(%d+)") or nil
        local ThumbnailImage = AssetId and string.format("rbxthumb://type=Asset&id=%s&w=768&h=432", AssetId) or ""
        local RawImage = AssetId and string.format("rbxassetid://%s", AssetId) or ResolveImageSource(Image)

        if BackgroundImageFallback then
            BackgroundImageFallback.Image = ThumbnailImage
            BackgroundImageFallback.Visible = ThumbnailImage ~= ""
        end
        BackgroundImage.Image = RawImage
        BackgroundImage.Visible = RawImage ~= ""
        if ContainerBackgroundImageFallback then
            ContainerBackgroundImageFallback.Image = ThumbnailImage
            ContainerBackgroundImageFallback.Visible = ThumbnailImage ~= ""
        end
        if ContainerBackgroundImage then
            ContainerBackgroundImage.Image = RawImage
            ContainerBackgroundImage.Visible = RawImage ~= ""
        end
        WindowInfo.BackgroundImage = RawImage
        ApplyBackgroundVisuals()
    end

    function Window:SetBackgroundTransparency(Transparency)
        assert(typeof(Transparency) == "number", "Expected number for transparency got: " .. typeof(Transparency))
        assert(Transparency >= 0 and Transparency <= 1, "Transparency must be between 0 and 1")

        WindowInfo.BackgroundImageTransparency = Transparency
        ApplyBackgroundVisuals()
    end

    function Window:ClearBackgroundImage()
        Window:SetBackgroundImage("")
    end

    function Window:SetUiTransparency(Transparency)
        assert(typeof(Transparency) == "number", "Expected number for transparency got: " .. typeof(Transparency))
        assert(Transparency >= 0 and Transparency <= 2, "Transparency must be between 0 and 2")

        WindowInfo.UITransparency = Transparency
        MainFrame.BackgroundTransparency = math.clamp(Transparency * 0.44, 0, 0.92)

        for _, Entry in ShellTransparencyTargets do
            Entry.Instance.BackgroundTransparency = math.clamp((Entry.Base or 0) + (Transparency * (Entry.Scale or 1)), 0, 1)
        end

        ApplyBackgroundVisuals()
    end

    local function RefreshFooterBadgeWidth()
        if not FooterBadge or not FooterBadgeLabel then
            return
        end

        local textWidth = select(1, Library:GetTextBounds(WindowInfo.Footer or "", Library:GetWeightedFont(Enum.FontWeight.Bold), 14))
        local badgeWidth = math.clamp(textWidth + 72, 150, 210)
        FooterBadge.Size = UDim2.fromOffset(badgeWidth, 28)
    end

    function Window:SetFooter(footer)
        assert(typeof(footer) == "string", "Expected string for footer got: " .. typeof(footer))

        WindowInfo.Footer = footer
        if FooterBadgeLabel then
            FooterBadgeLabel.Text = footer
        end
        RefreshFooterBadgeWidth()
    end

    function Window:SetFooterAvatar(image)
        assert(typeof(image) == "string", "Expected string for image got: " .. typeof(image))

        local Resolved = ResolveImageSource(image)
        WindowInfo.FooterAvatar = Resolved

        if FooterBadgeAvatar then
            FooterBadgeAvatar.Image = Resolved
            FooterBadgeAvatar.ImageTransparency = Resolved == "" and 1 or 0
            AttachImageLoadFallback(FooterBadgeAvatar, Resolved)
        end
    end

    function Window:SetFooterBackgroundImage(image)
        assert(typeof(image) == "string", "Expected string for image got: " .. typeof(image))

        local Resolved = ResolveImageSource(image)
        WindowInfo.FooterBackgroundImage = Resolved

        if FooterBadgeBackgroundImage then
            FooterBadgeBackgroundImage.Image = Resolved
            FooterBadgeBackgroundImage.ImageTransparency = Resolved == ""
                    and 1
                or math.clamp(WindowInfo.FooterBackgroundTransparency or 0.28, 0, 1)
            AttachImageLoadFallback(FooterBadgeBackgroundImage, Resolved)
        end
    end

    function Window:SetFooterBackgroundTransparency(transparency)
        assert(typeof(transparency) == "number", "Expected number for transparency got: " .. typeof(transparency))
        assert(transparency >= 0 and transparency <= 1, "Transparency must be between 0 and 1")

        WindowInfo.FooterBackgroundTransparency = transparency
        if FooterBadgeBackgroundImage then
            FooterBadgeBackgroundImage.ImageTransparency = (WindowInfo.FooterBackgroundImage == "" or WindowInfo.FooterBackgroundImage == nil)
                    and 1
                or transparency
        end
    end

    function Window:SetFooterPalette(Status)
        if not FooterBadge or not FooterBadgeStroke or not FooterBadgeLabel then
            return
        end

        local Tone = tostring(Status or ""):lower()
        local BackgroundColor = Library:GetUiColor("Control")
        local StrokeColor = Library:GetUiColor("SoftOutline")
        local TextColor = Library:GetUiColor("ActiveText")
        local GlowColor = Library:GetUiColor("AccentSoft")
        local GradientA = BackgroundColor
        local GradientB = BackgroundColor
        local IconName = "kojo-tier-standard"

        if Tone == "premium" or Tone == "vip" or Tone == "lifetime" then
            BackgroundColor = Color3.fromRGB(24, 31, 25)
            StrokeColor = Color3.fromRGB(84, 176, 129)
            TextColor = Color3.fromRGB(224, 252, 231)
            GlowColor = Color3.fromRGB(118, 215, 157)
            GradientA = Color3.fromRGB(38, 49, 39)
            GradientB = Color3.fromRGB(26, 35, 28)
            IconName = Tone == "premium" and "kojo-tier-premium" or (Tone == "vip" and "kojo-tier-vip" or "kojo-tier-lifetime")
        elseif Tone == "freemium" then
            BackgroundColor = Color3.fromRGB(24, 26, 34)
            StrokeColor = Color3.fromRGB(76, 86, 114)
            TextColor = Color3.fromRGB(218, 223, 236)
            GlowColor = Color3.fromRGB(174, 185, 214)
            GradientA = Color3.fromRGB(37, 41, 55)
            GradientB = Color3.fromRGB(24, 26, 34)
            IconName = "kojo-tier-freemium"
        elseif Tone == "standard" then
            BackgroundColor = Color3.fromRGB(25, 28, 33)
            StrokeColor = Color3.fromRGB(96, 109, 138)
            TextColor = Color3.fromRGB(228, 231, 238)
            GlowColor = Color3.fromRGB(148, 162, 194)
            GradientA = Color3.fromRGB(42, 46, 56)
            GradientB = Color3.fromRGB(25, 28, 33)
            IconName = "kojo-tier-standard"
        end

        FooterBadge.BackgroundColor3 = BackgroundColor
        FooterBadgeStroke.Color = StrokeColor
        FooterBadgeLabel.TextColor3 = TextColor
        if FooterBadgeGlow then
            FooterBadgeGlow.BackgroundColor3 = GlowColor
        end
        if FooterBadgeGradient then
            FooterBadgeGradient.Color = ColorSequence.new({
                ColorSequenceKeypoint.new(0, GradientA),
                ColorSequenceKeypoint.new(1, GradientB),
            })
        end
        if FooterBadgeIcon then
            local ParsedIcon = Library:GetCustomIcon(IconName)
            if ParsedIcon then
                FooterBadgeIcon.Image = ParsedIcon.Url
                FooterBadgeIcon.ImageRectOffset = ParsedIcon.ImageRectOffset
                FooterBadgeIcon.ImageRectSize = ParsedIcon.ImageRectSize
                FooterBadgeIcon.ImageColor3 = TextColor
                FooterBadgeIcon.ImageTransparency = 0.1
                AttachImageLoadFallback(FooterBadgeIcon, ParsedIcon.Url)
            end
        end
        RefreshFooterBadgeWidth()
    end

    Window.SubInterfaces = {}

    function Window:AddSubInterface(Info)
        Info = Library:Validate(Info or {}, {
            Title = "Panel",
            Subtitle = "",
            Width = 760,
            Height = 520,
            HideMainWindow = true,
            ShowBackButton = true,
            CloseOnOverlay = false,
            BackButtonText = "Main UI",
            AccentColor = Library:GetUiColor("Accent"),
            RailWidth = 176,
        })

        local ShellRadius = math.max((WindowInfo and WindowInfo.CornerRadius) or 16, 14)
        local TopBarHeight = 42

        local SubInterface = {
            Title = Info.Title,
            Subtitle = Info.Subtitle,
            Width = Info.Width,
            Height = Info.Height,
            HideMainWindow = Info.HideMainWindow,
            CloseOnOverlay = Info.CloseOnOverlay,
            Visible = false,
            Type = "SubInterface",
        }

        local Overlay = New("TextButton", {
            AutoButtonColor = false,
            BackgroundColor3 = "DarkColor",
            BackgroundTransparency = 1,
            Modal = true,
            Size = UDim2.fromScale(1, 1),
            Text = "",
            Visible = false,
            ZIndex = 40,
            Parent = ScreenGui,
        })

        local Panel = New("Frame", {
            Active = true,
            BackgroundColor3 = function()
                return Library:GetUiColor("Shell")
            end,
            BorderSizePixel = 0,
            Position = UDim2.new(0.5, -math.floor(Info.Width / 2), 0.5, -math.floor(Info.Height / 2)),
            Size = UDim2.fromOffset(Info.Width, Info.Height),
            Visible = false,
            ZIndex = 41,
            Parent = ScreenGui,
        })
        New("UICorner", {
            CornerRadius = UDim.new(0, ShellRadius),
            Parent = Panel,
        })
        local PanelStroke = New("UIStroke", {
            Color = function()
                return Library:GetUiColor("SoftOutline")
            end,
            Transparency = 0.18,
            Parent = Panel,
        })
        Window:RegisterTransparencyTarget(Panel, 0.02, 0.92)

        local PanelScale = New("UIScale", {
            Scale = 0.975,
            Parent = Panel,
        })

        local ShellOverlay = New("Frame", {
            Active = true,
            BackgroundTransparency = 1,
            Position = UDim2.fromOffset(2, 2),
            Size = UDim2.new(1, -4, 1, -4),
            ZIndex = 41,
            Parent = Panel,
        })

        local Rail = New("Frame", {
            Active = true,
            BackgroundColor3 = function()
                return Library:GetUiColor("Rail")
            end,
            BorderSizePixel = 0,
            Position = UDim2.fromOffset(0, 0),
            Size = UDim2.new(0, Info.RailWidth, 1, 0),
            ZIndex = 41,
            Parent = ShellOverlay,
        })
        Window:RegisterTransparencyTarget(Rail, 0, 1.05)
        New("UICorner", {
            CornerRadius = UDim.new(0, ShellRadius - 2),
            Parent = Rail,
        })

        local Header = New("Frame", {
            Active = true,
            BackgroundColor3 = function()
                return Library:GetUiColor("TopBar")
            end,
            BorderSizePixel = 0,
            Position = UDim2.fromOffset(Info.RailWidth, 0),
            Size = UDim2.new(1, -Info.RailWidth, 0, TopBarHeight + 8),
            ZIndex = 41,
            Parent = ShellOverlay,
        })
        Window:RegisterTransparencyTarget(Header, 0, 0.98)

        local Divider = New("Frame", {
            BackgroundColor3 = function()
                return Library:GetUiColor("Divider")
            end,
            BorderSizePixel = 0,
            Position = UDim2.fromOffset(Info.RailWidth, 0),
            Size = UDim2.new(0, 1, 1, 0),
            ZIndex = 42,
            Parent = ShellOverlay,
        })

        local TopDivider = New("Frame", {
            BackgroundColor3 = function()
                return Library:GetUiColor("Divider")
            end,
            BorderSizePixel = 0,
            Position = UDim2.fromOffset(0, TopBarHeight + 8),
            Size = UDim2.new(1, 0, 0, 1),
            ZIndex = 42,
            Parent = ShellOverlay,
        })

        local BackButton = New("TextButton", {
            AutoButtonColor = false,
            BackgroundColor3 = function()
                return Library:GetUiColor("Control")
            end,
            BorderSizePixel = 0,
            Position = UDim2.fromOffset(14, 14),
            Size = UDim2.fromOffset(128, 34),
            Text = "",
            Visible = Info.ShowBackButton,
            ZIndex = 43,
            Parent = Rail,
        })
        Window:RegisterTransparencyTarget(BackButton, 0.02, 0.88)
        New("UICorner", {
            CornerRadius = UDim.new(0, 10),
            Parent = BackButton,
        })
        local BackStroke = New("UIStroke", {
            Color = function()
                return Library:GetUiColor("SoftOutline")
            end,
            Transparency = 0.18,
            Parent = BackButton,
        })
        local BackLabel = New("TextLabel", {
            BackgroundTransparency = 1,
            FontFace = function()
                return Library:GetWeightedFont(Enum.FontWeight.Bold)
            end,
            Position = UDim2.fromOffset(12, 0),
            Size = UDim2.new(1, -24, 1, 0),
            Text = Info.BackButtonText,
            TextColor3 = function()
                return Library:GetUiColor("ActiveText")
            end,
            TextSize = 13,
            TextXAlignment = Enum.TextXAlignment.Center,
            ZIndex = 44,
            Parent = BackButton,
        })

        local RailContent = New("Frame", {
            BackgroundTransparency = 1,
            Position = UDim2.fromOffset(12, 58),
            Size = UDim2.new(1, -24, 1, -70),
            ZIndex = 42,
            Parent = Rail,
        })
        local RailLayout = New("UIListLayout", {
            Padding = UDim.new(0, 10),
            SortOrder = Enum.SortOrder.LayoutOrder,
            Parent = RailContent,
        })

        local TitleLabel = New("TextLabel", {
            BackgroundTransparency = 1,
            FontFace = function()
                return Library:GetWeightedFont(Enum.FontWeight.Bold)
            end,
            Position = UDim2.fromOffset(18, 10),
            Size = UDim2.new(1, -110, 0, 26),
            Text = Info.Title,
            TextColor3 = function()
                return Library:GetUiColor("ActiveText")
            end,
            TextSize = 22,
            TextXAlignment = Enum.TextXAlignment.Left,
            ZIndex = 43,
            Parent = Header,
        })
        local SubtitleLabel = New("TextLabel", {
            BackgroundTransparency = 1,
            FontFace = function()
                return Library:GetWeightedFont(Enum.FontWeight.Medium)
            end,
            Position = UDim2.fromOffset(18, 34),
            Size = UDim2.new(1, -110, 0, 20),
            Text = Info.Subtitle,
            TextColor3 = function()
                return Library:GetUiColor("MutedText")
            end,
            TextSize = 13,
            TextXAlignment = Enum.TextXAlignment.Left,
            ZIndex = 43,
            Parent = Header,
        })

        local AccentBar = New("Frame", {
            BackgroundColor3 = Info.AccentColor,
            BorderSizePixel = 0,
            Position = UDim2.fromOffset(18, TopBarHeight + 7),
            Size = UDim2.fromOffset(78, 2),
            ZIndex = 43,
            Parent = Header,
        })
        New("UICorner", {
            CornerRadius = UDim.new(1, 0),
            Parent = AccentBar,
        })

        local Content = New("Frame", {
            Active = true,
            BackgroundTransparency = 1,
            Position = UDim2.fromOffset(Info.RailWidth + 16, TopBarHeight + 24),
            Size = UDim2.new(1, -(Info.RailWidth + 32), 1, -(TopBarHeight + 36)),
            ZIndex = 42,
            Parent = ShellOverlay,
        })

        local OverlayTween
        local ScaleTween

        function SubInterface:SetTitle(Text)
            SubInterface.Title = tostring(Text or "")
            TitleLabel.Text = SubInterface.Title
        end

        function SubInterface:SetSubtitle(Text)
            SubInterface.Subtitle = tostring(Text or "")
            SubtitleLabel.Text = SubInterface.Subtitle
        end

        function SubInterface:Show()
            for _, Other in Window.SubInterfaces do
                if Other ~= SubInterface and Other.Visible then
                    Other:Hide(false)
                end
            end

            if SubInterface.HideMainWindow and MainFrame then
                MainFrame.Visible = false
            end
            if Library.KeybindFrame then
                Library.KeybindFrame.Visible = false
            end

            StopTween(OverlayTween)
            StopTween(ScaleTween)

            Overlay.Visible = true
            Panel.Visible = true
            Overlay.BackgroundTransparency = 1
            PanelScale.Scale = 0.972
            Panel.Position = UDim2.new(0.5, -math.floor(Info.Width / 2), 0.5, -math.floor(Info.Height / 2) + 10)

            OverlayTween = TweenService:Create(Overlay, TweenInfo.new(0.2, Enum.EasingStyle.Quad, Enum.EasingDirection.Out), {
                BackgroundTransparency = 0.42,
            })
            ScaleTween = TweenService:Create(PanelScale, TweenInfo.new(0.26, Enum.EasingStyle.Quint, Enum.EasingDirection.Out), {
                Scale = 1,
            })
            OverlayTween:Play()
            ScaleTween:Play()
            TweenService:Create(Panel, TweenInfo.new(0.22, Enum.EasingStyle.Quint, Enum.EasingDirection.Out), {
                Position = UDim2.new(0.5, -math.floor(Info.Width / 2), 0.5, -math.floor(Info.Height / 2)),
            }):Play()

            SubInterface.Visible = true
        end

        function SubInterface:Hide(ShowMain)
            if ShowMain == nil then
                ShowMain = true
            end

            StopTween(OverlayTween)
            StopTween(ScaleTween)

            OverlayTween = TweenService:Create(Overlay, TweenInfo.new(0.16, Enum.EasingStyle.Quad, Enum.EasingDirection.Out), {
                BackgroundTransparency = 1,
            })
            ScaleTween = TweenService:Create(PanelScale, TweenInfo.new(0.16, Enum.EasingStyle.Quad, Enum.EasingDirection.Out), {
                Scale = 0.978,
            })
            OverlayTween:Play()
            ScaleTween:Play()
            TweenService:Create(Panel, TweenInfo.new(0.16, Enum.EasingStyle.Quad, Enum.EasingDirection.Out), {
                Position = UDim2.new(0.5, -math.floor(Info.Width / 2), 0.5, -math.floor(Info.Height / 2) + 8),
            }):Play()

            task.delay(0.17, function()
                if not SubInterface.Visible then
                    Overlay.Visible = false
                    Panel.Visible = false
                end
            end)

            SubInterface.Visible = false

            if ShowMain and SubInterface.HideMainWindow and MainFrame and Library.Toggled then
                MainFrame.Visible = true
            end
        end

        function SubInterface:Toggle()
            if SubInterface.Visible then
                SubInterface:Hide()
            else
                SubInterface:Show()
            end
        end

        function SubInterface:Destroy()
            Overlay:Destroy()
            Panel:Destroy()
        end

        BackButton.MouseButton1Click:Connect(function()
            SubInterface:Hide(true)
        end)
        if SubInterface.CloseOnOverlay then
            Overlay.MouseButton1Click:Connect(function()
                SubInterface:Hide(true)
            end)
        end
        Library:MakeDraggable(Panel, Header, false, true)

        SubInterface.Overlay = Overlay
        SubInterface.Panel = Panel
        SubInterface.Rail = Rail
        SubInterface.RailContent = RailContent
        SubInterface.RailLayout = RailLayout
        SubInterface.Header = Header
        SubInterface.Content = Content
        SubInterface.BackButton = BackButton
        SubInterface.TitleLabel = TitleLabel
        SubInterface.SubtitleLabel = SubtitleLabel
        SubInterface.AccentBar = AccentBar
        SubInterface.Stroke = PanelStroke
        table.insert(Window.SubInterfaces, SubInterface)

        return SubInterface
    end

    function Window:AddPreviewPanel(Info)
        Info = Library:Validate(Info or {}, {
            Title = "Preview",
            Width = 250,
            Height = 272,
            Side = "Left",
            Offset = 14,
            Visible = false,
            Interactive = true,
            AutoFocus = true,
            AutoRotate = false,
            RotateSpeed = 18,
            FocusYOffset = 0.28,
            CameraDistanceMultiplier = 2.15,
            Clone = true,
            Object = nil,
        })

        local Preview = {
            Title = Info.Title,
            Width = Info.Width,
            Height = Info.Height,
            Side = Info.Side,
            Offset = Info.Offset,
            Visible = Info.Visible,
            Interactive = Info.Interactive,
            AutoFocus = Info.AutoFocus,
            AutoRotate = Info.AutoRotate,
            RotateSpeed = Info.RotateSpeed,
            FocusYOffset = Info.FocusYOffset,
            CameraDistanceMultiplier = Info.CameraDistanceMultiplier,
            Clone = Info.Clone,
            Object = nil,
            OwnsObject = false,
            Type = "PreviewPanel",
        }

        local Holder = New("Frame", {
            BackgroundColor3 = function()
                return Library:GetUiColor("Card")
            end,
            Position = UDim2.fromOffset(24, 24),
            Size = UDim2.fromOffset(Preview.Width, Preview.Height),
            Visible = Preview.Visible,
            ZIndex = 12,
            Parent = ScreenGui,
        })
        New("UICorner", {
            CornerRadius = UDim.new(0, 12),
            Parent = Holder,
        })
        local HolderStroke = New("UIStroke", {
            Color = function()
                return Library:GetUiColor("SoftOutline")
            end,
            Parent = Holder,
        })
        Holder.BackgroundTransparency = 0.02

        local Header = New("TextButton", {
            AutoButtonColor = false,
            BackgroundTransparency = 1,
            Size = UDim2.new(1, 0, 0, 30),
            Text = "",
            Parent = Holder,
        })
        local HeaderLabel = New("TextLabel", {
            BackgroundTransparency = 1,
            FontFace = function()
                return Library:GetWeightedFont(Enum.FontWeight.Heavy)
            end,
            Position = UDim2.fromOffset(12, 0),
            Size = UDim2.new(1, -24, 1, 0),
            Text = Preview.Title,
            TextColor3 = function()
                return Library:GetUiColor("ActiveText")
            end,
            TextSize = 15,
            TextXAlignment = Enum.TextXAlignment.Left,
            Parent = Header,
        })

        local Divider = New("Frame", {
            BackgroundColor3 = function()
                return Library:GetUiColor("Divider")
            end,
            Position = UDim2.fromOffset(0, 30),
            Size = UDim2.new(1, 0, 0, 1),
            Parent = Holder,
        })

        local Body = New("Frame", {
            BackgroundTransparency = 1,
            Position = UDim2.fromOffset(12, 42),
            Size = UDim2.new(1, -24, 1, -54),
            Parent = Holder,
        })

        local ViewportFrame = New("ViewportFrame", {
            BackgroundTransparency = 1,
            Size = UDim2.fromScale(1, 1),
            Parent = Body,
        })
        local WorldModel = Instance.new("WorldModel")
        WorldModel.Parent = ViewportFrame
        local Camera = Instance.new("Camera")
        Camera.Parent = ViewportFrame
        ViewportFrame.CurrentCamera = Camera

        local DraggingViewport = false
        local LastViewportPosition

        local OrbitYaw = math.rad(24)
        local OrbitPitch = math.rad(-8)
        local OrbitDistance = nil
        local OrbitMinDistance = 2
        local OrbitMaxDistance = 24
        local OrbitFocus = Vector3.zero
        local OrbitExtent = 4

        local function ApplyOrbitCamera()
            if not Preview.Object then
                return
            end

            local CosPitch = math.cos(OrbitPitch)
            local Direction = Vector3.new(
                math.sin(OrbitYaw) * CosPitch,
                math.sin(OrbitPitch),
                math.cos(OrbitYaw) * CosPitch
            )

            Camera.CFrame = CFrame.new(OrbitFocus + Direction * OrbitDistance, OrbitFocus)
        end

        local function FocusCamera(PreserveDistance)
            if not Preview.Object then
                return
            end

            local ModelSize
            local ModelPosition
            if Preview.Object:IsA("BasePart") then
                ModelSize = Preview.Object.Size
                ModelPosition = Preview.Object.Position
            else
                local BoundingBox
                BoundingBox, ModelSize = Preview.Object:GetBoundingBox()
                ModelPosition = BoundingBox.Position
            end
            local MaxExtent = math.max(ModelSize.X, ModelSize.Y, ModelSize.Z)

            OrbitExtent = MaxExtent
            OrbitFocus = ModelPosition + Vector3.new(0, MaxExtent * Preview.FocusYOffset, 0)
            OrbitMinDistance = math.max(1.75, MaxExtent * 0.8)
            OrbitMaxDistance = math.max(24, MaxExtent * 8)

            if not PreserveDistance or not OrbitDistance then
                OrbitDistance = math.max(4.5, MaxExtent * Preview.CameraDistanceMultiplier)
            else
                OrbitDistance = math.clamp(OrbitDistance, OrbitMinDistance, OrbitMaxDistance)
            end

            ApplyOrbitCamera()
        end

        local function SnapPosition()
            if not Window.MainFrame then
                return
            end

            local WindowPosition = Window.MainFrame.AbsolutePosition
            local WindowSize = Window.MainFrame.AbsoluteSize
            local Side = tostring(Preview.Side or "Left"):lower()

            if Side == "right" then
                Holder.AnchorPoint = Vector2.new(0, 0.5)
                Holder.Position = UDim2.fromOffset(
                    WindowPosition.X + WindowSize.X + Preview.Offset,
                    WindowPosition.Y + math.floor(WindowSize.Y * 0.5)
                )
            else
                Holder.AnchorPoint = Vector2.new(1, 0.5)
                Holder.Position = UDim2.fromOffset(
                    WindowPosition.X - Preview.Offset,
                    WindowPosition.Y + math.floor(WindowSize.Y * 0.5)
                )
            end
        end

        local function NormalizeObject(Object, CloneObject)
            assert(
                typeof(Object) == "Instance" and (Object:IsA("BasePart") or Object:IsA("Model")),
                "Preview object must be a BasePart or Model."
            )

            if CloneObject == false then
                return Object, false
            end

            local OriginalArchivable = Object.Archivable
            if not OriginalArchivable then
                Object.Archivable = true
            end

            local ClonedObject = Object:Clone()
            Object.Archivable = OriginalArchivable

            return ClonedObject, true
        end

        function Preview:SetObject(Object, CloneObject)
            if Preview.Object and Preview.OwnsObject then
                Preview.Object:Destroy()
            end

            local FinalObject, OwnsObject = NormalizeObject(Object, CloneObject == nil and Preview.Clone or CloneObject)
            Preview.Object = FinalObject
            Preview.OwnsObject = OwnsObject
            Preview.Object.Parent = WorldModel

            if Preview.AutoFocus then
                FocusCamera(false)
            end
        end

        function Preview:Focus()
            FocusCamera(false)
        end

        function Preview:SetVisible(Visible)
            Preview.Visible = Visible
            Holder.Visible = Visible
            if Visible then
                SnapPosition()
            end
        end

        function Preview:Toggle()
            Preview:SetVisible(not Preview.Visible)
        end

        function Preview:SetTitle(Text)
            Preview.Title = Text
            HeaderLabel.Text = Text
        end

        function Preview:SetSide(Side)
            Preview.Side = Side
            SnapPosition()
        end

        function Preview:SetOffset(Offset)
            Preview.Offset = Offset
            SnapPosition()
        end

        function Preview:SetAutoRotate(AutoRotate)
            Preview.AutoRotate = AutoRotate
        end

        function Preview:SetRotateSpeed(RotateSpeed)
            Preview.RotateSpeed = RotateSpeed
        end

        function Preview:Destroy()
            if Preview.Object and Preview.OwnsObject then
                Preview.Object:Destroy()
            end

            WorldModel:Destroy()
            Camera:Destroy()
            Holder:Destroy()
        end

        ViewportFrame.InputBegan:Connect(function(Input)
            if not Preview.Interactive then
                return
            end

            if Input.UserInputType == Enum.UserInputType.MouseButton1 or Input.UserInputType == Enum.UserInputType.MouseButton2 then
                DraggingViewport = true
                LastViewportPosition = Input.Position
            end
        end)

        ViewportFrame.InputEnded:Connect(function(Input)
            if Input.UserInputType == Enum.UserInputType.MouseButton1 or Input.UserInputType == Enum.UserInputType.MouseButton2 then
                DraggingViewport = false
            end
        end)

        ViewportFrame.InputChanged:Connect(function(Input)
            if not Preview.Interactive then
                return
            end

            if Input.UserInputType == Enum.UserInputType.MouseWheel then
                local ZoomAmount = Input.Position.Z * math.max(0.8, OrbitExtent * 0.08)
                OrbitDistance = math.clamp((OrbitDistance or 8) - ZoomAmount, OrbitMinDistance, OrbitMaxDistance)
                ApplyOrbitCamera()
            end
        end)

        Library:GiveSignal(UserInputService.InputChanged:Connect(function(Input)
            if Library.Unloaded or not Preview.Interactive or not DraggingViewport or not Preview.Object then
                return
            end

            if Input.UserInputType ~= Enum.UserInputType.MouseMovement then
                return
            end

            local Delta = Input.Position - LastViewportPosition
            LastViewportPosition = Input.Position

            OrbitYaw -= Delta.X * 0.01
            OrbitPitch = math.clamp(OrbitPitch - Delta.Y * 0.008, math.rad(-70), math.rad(70))
            ApplyOrbitCamera()
        end))

        Library:GiveSignal(RunService.RenderStepped:Connect(function(DeltaTime)
            if Library.Unloaded or not Preview.AutoRotate or not Preview.Visible or DraggingViewport then
                return
            end

            OrbitYaw += math.rad(Preview.RotateSpeed) * DeltaTime
            ApplyOrbitCamera()
        end))

        Library:MakeDraggable(Holder, Header, true)
        SnapPosition()

        if Info.Object then
            Preview:SetObject(Info.Object, Info.Clone)
        end

        Preview.Holder = Holder
        Preview.Viewport = ViewportFrame
        Preview.WorldModel = WorldModel
        Preview.Body = Body
        Preview.Camera = Camera
        Preview.Header = Header
        Preview.Stroke = HolderStroke

        return Preview
    end

    local SidebarChromeTween
    local SidebarBrandTween
    local SidebarChevronTween
    local SidebarWidthTween
    local SidebarWidthValue
    local SidebarWidthConnection
    local WindowIconTween
    local WindowIconGlowTween

    local function UpdateSidebarChrome(Animate)
        local Compact = IsCompact
        local IconTarget = Compact and UDim2.fromScale(0.5, 0.5) or UDim2.new(0, 20, 0.5, 0)
        local GlowTarget = Compact and UDim2.fromScale(0.5, 0.5) or UDim2.new(0, 20, 0.5, 0)
        local BrandTransparency = Compact and 1 or 0.08
        local ChevronRotation = Compact and 0 or 180

        if not Animate then
            if WindowIcon then
                WindowIcon.Position = IconTarget
            end
            if WindowIconGlow then
                WindowIconGlow.Position = GlowTarget
            end
            if SidebarBrandLabel then
                SidebarBrandLabel.TextTransparency = BrandTransparency
            end
            if SidebarToggleChevron then
                SidebarToggleChevron.Rotation = ChevronRotation
            end
            return
        end

        if WindowIcon then
            StopTween(WindowIconTween)
            WindowIconTween = TweenService:Create(
                WindowIcon,
                TweenInfo.new(0.2, Enum.EasingStyle.Quart, Enum.EasingDirection.Out),
                { Position = IconTarget }
            )
            WindowIconTween:Play()
        end
        if WindowIconGlow then
            StopTween(WindowIconGlowTween)
            WindowIconGlowTween = TweenService:Create(
                WindowIconGlow,
                TweenInfo.new(0.22, Enum.EasingStyle.Quart, Enum.EasingDirection.Out),
                { Position = GlowTarget }
            )
            WindowIconGlowTween:Play()
        end
        if SidebarBrandLabel then
            StopTween(SidebarBrandTween)
            SidebarBrandTween = TweenService:Create(
                SidebarBrandLabel,
                TweenInfo.new(0.18, Enum.EasingStyle.Quad, Enum.EasingDirection.Out),
                { TextTransparency = BrandTransparency }
            )
            SidebarBrandTween:Play()
        end
        if SidebarToggleChevron then
            StopTween(SidebarChevronTween)
            SidebarChevronTween = TweenService:Create(
                SidebarToggleChevron,
                TweenInfo.new(0.2, Enum.EasingStyle.Quart, Enum.EasingDirection.Out),
                { Rotation = ChevronRotation }
            )
            SidebarChevronTween:Play()
        end
    end

    local function ApplyCompact(AnimationMode)
        IsCompact = Window:GetSidebarWidth() <= WindowInfo.CompactWidthActivation

        UpdateSidebarChrome(AnimationMode ~= "instant")

        local Index = 0
        for _, Button in Library.TabButtons do
            if Button.RefreshSidebar then
                Index += 1
                if AnimationMode == "stagger" then
                    task.delay(0.02 * (Index - 1), function()
                        if Button.Button and Button.Button.Parent then
                            Button.RefreshSidebar(true)
                        end
                    end)
                else
                    Button.RefreshSidebar(AnimationMode ~= "instant")
                end
            end
        end
    end

    function Window:IsSidebarCompacted()
        return IsCompact
    end

    function Window:ToggleCompact()
        Window:SetCompact(not IsCompact)
    end

    function Window:SetCompact(State)
        local TargetWidth = State and WindowInfo.SidebarCompactWidth or LastExpandedWidth

        StopTween(SidebarWidthTween)
        if SidebarWidthConnection then
            SidebarWidthConnection:Disconnect()
            SidebarWidthConnection = nil
        end
        if SidebarWidthValue then
            SidebarWidthValue:Destroy()
            SidebarWidthValue = nil
        end

        SidebarWidthValue = Instance.new("NumberValue")
        SidebarWidthValue.Value = Window:GetSidebarWidth()
        SidebarWidthConnection = SidebarWidthValue:GetPropertyChangedSignal("Value"):Connect(function()
            Window:SetSidebarWidth(math.floor(SidebarWidthValue.Value + 0.5), "instant")
        end)
        SidebarWidthTween = TweenService:Create(
            SidebarWidthValue,
            TweenInfo.new(0.22, Enum.EasingStyle.Quart, Enum.EasingDirection.Out),
            { Value = TargetWidth }
        )
        local CurrentSidebarWidthTween = SidebarWidthTween
        SidebarWidthTween.Completed:Connect(function()
            if SidebarWidthTween ~= CurrentSidebarWidthTween then
                return
            end
            if SidebarWidthConnection then
                SidebarWidthConnection:Disconnect()
                SidebarWidthConnection = nil
            end
            if SidebarWidthValue then
                SidebarWidthValue:Destroy()
                SidebarWidthValue = nil
            end

            SidebarWidthTween = nil
            Window:SetSidebarWidth(TargetWidth, "stagger")
        end)
        SidebarWidthTween:Play()
    end

    function Window:GetSidebarWidth()
        return Tabs.Size.X.Offset
    end

    function Window:SetSidebarWidth(Width, CompactAnimationMode)
        local ContentInset = 3
        local TopBarHeight = 42
        local TabBarHeight = 36

        Width = math.clamp(Width, 48, math.max(48, MainFrame.Size.X.Offset - WindowInfo.MinContainerWidth - 16))
        Width = math.floor(Width + 0.5)

        if LeftRail then
            LeftRail.Size = UDim2.new(0, Width, 1, 0)
        end
        if LeftRailFill then
            LeftRailFill.Position = UDim2.fromOffset(math.floor(Width / 2), 0)
            LeftRailFill.Size = UDim2.new(0, math.ceil(Width / 2), 1, 0)
        end
        DividerLine.Position = UDim2.fromOffset(Width, 0)
        DividerLine.Size = UDim2.new(0, 1, 1, 0)
        if ShellDividerLine then
            ShellDividerLine.Position = UDim2.fromOffset(Width, 0)
            ShellDividerLine.Size = UDim2.new(0, 1, 1, 0)
        end
        if TitleDividerLine then
            TitleDividerLine.Position = UDim2.fromOffset(Width, 0)
            TitleDividerLine.Size = UDim2.new(0, 1, 0, TopBarHeight)
        end
        if RailBottomLine then
            RailBottomLine.Size = UDim2.new(0, Width, 0, 1)
        end
        if TopBarBottomLine then
            TopBarBottomLine.Position = UDim2.fromOffset(Width, TopBarHeight)
            TopBarBottomLine.Size = UDim2.new(1, -Width, 0, 1)
        end
        if TopTabsBottomLine then
            TopTabsBottomLine.Position = UDim2.fromOffset(Width, TopBarHeight + TabBarHeight)
            TopTabsBottomLine.Size = UDim2.new(1, -Width, 0, 1)
        end

        TitleHolder.Size = UDim2.new(0, Width, 0, TopBarHeight)
        if TopBar then
            TopBar.Position = UDim2.fromOffset(Width, 0)
            TopBar.Size = UDim2.new(1, -Width, 0, TopBarHeight)
        end
        Tabs.Position = UDim2.fromOffset(0, TopBarHeight + 4)
        Tabs.Size = UDim2.new(0, Width, 1, -(TopBarHeight + 4))
        if TopTabsBackground then
            TopTabsBackground.Position = UDim2.fromOffset(Width, TopBarHeight + 1)
            TopTabsBackground.Size = UDim2.new(1, -Width, 0, TabBarHeight - 1)
        end
        TopTabs.Position = UDim2.fromOffset(Width + 4, TopBarHeight)
        TopTabs.Size = UDim2.new(1, -(Width + 8), 0, TabBarHeight)
        Container.Position = UDim2.fromOffset(Width + ContentInset, TopBarHeight + TabBarHeight + 3)
        Container.Size = UDim2.new(1, -(Width + ContentInset * 2 + 1), 1, -(TopBarHeight + TabBarHeight + 7))

        if WindowInfo.EnableCompacting then
            ApplyCompact(CompactAnimationMode or "instant")
        end
        if not IsCompact then
            LastExpandedWidth = Width
        end
    end

    function Window:ShowTabInfo(Name, Description)
        CurrentTabLabel.Text = Name
        local HasDescription = Description and Description ~= "" and Description ~= Name
        CurrentTabDescription.Text = HasDescription and Description or ""
        if CurrentTabSeparatorA then
            CurrentTabSeparatorA.Visible = true
        end
        if CurrentTabSeparatorB then
            CurrentTabSeparatorB.Visible = HasDescription and true or false
        end
    end
    function Window:HideTabInfo()
        CurrentTabLabel.Text = ""
        CurrentTabDescription.Text = ""
        if CurrentTabSeparatorA then
            CurrentTabSeparatorA.Visible = false
        end
        if CurrentTabSeparatorB then
            CurrentTabSeparatorB.Visible = false
        end
    end

    function Window:AddTab(...)
        local Name = nil
        local Icon = nil
        local Description = nil

        if select("#", ...) == 1 and typeof(...) == "table" then
            local Info = select(1, ...)
            Name = Info.Name or "Tab"
            Icon = Info.Icon
            Description = Info.Description
        else
            Name = select(1, ...)
            Icon = select(2, ...)
            Description = select(3, ...)
        end

        local function normalizeTabName(value)
            return tostring(value or ""):gsub("%s+", ""):lower()
        end

        local normalizedName = normalizeTabName(Name)
        local builtInDashboard = normalizeTabName(WindowInfo.KojoDashboardTabName or "Home")
        local builtInSettings = normalizeTabName(WindowInfo.KojoSettingsTabName or "Settings")
        local isBuiltInDashboard = normalizedName == builtInDashboard or normalizedName == "dashboard" or normalizedName == "home"
        local isBuiltInSettings = normalizedName == builtInSettings or normalizedName == "uisettings" or normalizedName == "settings"

        if Window.KojoCore then
            if isBuiltInDashboard and Window.KojoCore.DashboardTab then
                Window.Tabs[Name] = Window.KojoCore.DashboardTab
                return Window.KojoCore.DashboardTab
            end

            if isBuiltInSettings and Window.KojoCore.SettingsTab then
                Window.Tabs[Name] = Window.KojoCore.SettingsTab
                return Window.KojoCore.SettingsTab
            end
        end

        local TabButton: TextButton
        local TabButtonScale
        local TabButtonPlate
        local TabButtonStroke
        local TabButtonGlow
        local TabButtonMarker
        local TabLabel
        local SidebarLabel
        local SidebarButtonRegistration
        local TabIcon
        local TabIconGlow
        local TopTabButton
        local TopTabGlow
        local TopTabUnderline

        local TabContainer
        local PageScroll
        local PageContent
        local TabLeft
        local TabRight
        local TabLeftList
        local TabRightList
        local TabOrder = #Library.Tabs + 1
        local EffectiveOrder = isBuiltInDashboard and 0 or (isBuiltInSettings and 100000 or TabOrder)

        Icon = Library:GetCustomIcon(Icon)
        local IsCustomSidebarIcon = Icon and Icon.Custom == true
        do
            TabButton = New("TextButton", {
                BackgroundColor3 = function()
                    return Library:GetUiColor("DarkColor")
                end,
                BackgroundTransparency = 1,
                ClipsDescendants = true,
                LayoutOrder = EffectiveOrder,
                Size = UDim2.fromOffset(34, 34),
                Text = "",
                Parent = Tabs,
            })
            New("UICorner", {
                CornerRadius = UDim.new(0, 12),
                Parent = TabButton,
            })
            TabButtonScale = New("UIScale", {
                Scale = 1,
                Parent = TabButton,
            })
            TabButtonPlate = New("Frame", {
                AnchorPoint = Vector2.new(0.5, 0.5),
                BackgroundColor3 = function()
                    return Library:GetUiColor("AccentFill")
                end,
                BackgroundTransparency = 1,
                Position = UDim2.fromScale(0.5, 0.5),
                Size = UDim2.fromOffset(0, 0),
                Parent = TabButton,
            })
            New("UICorner", {
                CornerRadius = UDim.new(0, 12),
                Parent = TabButtonPlate,
            })
            New("UIGradient", {
                Rotation = 25,
                Color = function()
                    local Accent = Library:GetUiColor("AccentFill")
                    return ColorSequence.new({
                        ColorSequenceKeypoint.new(0, Library:LerpColor(Accent, Color3.new(1, 1, 1), 0.18)),
                        ColorSequenceKeypoint.new(1, Library:LerpColor(Accent, Color3.new(0, 0, 0), 0.08)),
                    })
                end,
                Parent = TabButtonPlate,
            })
            TabButtonGlow = New("Frame", {
                AnchorPoint = Vector2.new(0.5, 0.5),
                BackgroundColor3 = function()
                    return Library:GetUiColor("AccentFill")
                end,
                BackgroundTransparency = 1,
                Position = UDim2.fromScale(0.5, 0.5),
                Size = UDim2.fromOffset(0, 0),
                Parent = TabButton,
            })
            New("UICorner", {
                CornerRadius = UDim.new(0, 13),
                Parent = TabButtonGlow,
            })
            TabButtonMarker = New("Frame", {
                AnchorPoint = Vector2.new(0, 0.5),
                BackgroundColor3 = function()
                    return Library:GetUiColor("AccentFill")
                end,
                BackgroundTransparency = 1,
                Position = UDim2.new(0, 2, 0.5, 0),
                Size = UDim2.fromOffset(2, 0),
                Parent = TabButton,
            })
            New("UICorner", {
                CornerRadius = UDim.new(1, 0),
                Parent = TabButtonMarker,
            })
            TabButtonStroke = New("UIStroke", {
                Color = function()
                    return Library:GetUiColor("SoftOutline")
                end,
                Transparency = 1,
                Parent = TabButton,
            })

            if Icon then
                TabIconGlow = New("ImageLabel", {
                    Image = Icon.Url,
                    ImageColor3 = function()
                        return Library:GetUiColor("ActiveText")
                    end,
                    ImageRectOffset = Icon.ImageRectOffset,
                    ImageRectSize = Icon.ImageRectSize,
                    ImageTransparency = 1,
                    AnchorPoint = Vector2.new(0.5, 0.5),
                    Position = UDim2.fromScale(0.5, 0.5),
                    Size = UDim2.fromOffset(24, 24),
                    Parent = TabButton,
                })
                TabIcon = New("ImageLabel", {
                    Image = Icon.Url,
                    ImageColor3 = function()
                        return IsCustomSidebarIcon and Color3.new(1, 1, 1) or Library:GetUiColor("SubtleText")
                    end,
                    ImageRectOffset = Icon.ImageRectOffset,
                    ImageRectSize = Icon.ImageRectSize,
                    ImageTransparency = 1,
                    AnchorPoint = Vector2.new(0.5, 0.5),
                    Position = UDim2.fromScale(0.5, 0.5),
                    Size = UDim2.fromOffset(18, 18),
                    Parent = TabButton,
                })
                AttachImageLoadFallback(TabIcon, Icon.Url)
                AttachImageLoadFallback(TabIconGlow, Icon.Url)
            else
                TabIcon = New("TextLabel", {
                    AnchorPoint = Vector2.new(0.5, 0.5),
                    BackgroundTransparency = 1,
                    FontFace = function()
                        return Library:GetWeightedFont(Enum.FontWeight.Bold)
                    end,
                    Position = UDim2.fromScale(0.5, 0.5),
                    Size = UDim2.fromOffset(14, 14),
                    Text = Name:sub(1, 1):upper(),
                    TextColor3 = function()
                        return Library:GetUiColor("MutedText")
                    end,
                    TextSize = 14,
                    Parent = TabButton,
                })
                TabIconGlow = New("TextLabel", {
                    AnchorPoint = Vector2.new(0.5, 0.5),
                    BackgroundTransparency = 1,
                    FontFace = function()
                        return Library:GetWeightedFont(Enum.FontWeight.Bold)
                    end,
                    Position = UDim2.fromScale(0.5, 0.5),
                    Size = UDim2.fromOffset(18, 18),
                    Text = Name:sub(1, 1):upper(),
                    TextColor3 = function()
                        return Library:GetUiColor("AccentGlow")
                    end,
                    TextSize = 16,
                    TextTransparency = 1,
                    Parent = TabButton,
                })
            end

            SidebarLabel = New("TextLabel", {
                AnchorPoint = Vector2.new(0, 0.5),
                BackgroundTransparency = 1,
                FontFace = function()
                    return Library:GetWeightedFont(Enum.FontWeight.SemiBold)
                end,
                RichText = false,
                Position = UDim2.new(0, 36, 0.5, 0),
                Size = UDim2.new(1, -46, 0, 18),
                Text = Name,
                TextColor3 = function()
                    return Library:GetUiColor("MutedText")
                end,
                TextSize = 14,
                TextTransparency = 1,
                TextStrokeTransparency = 1,
                TextXAlignment = Enum.TextXAlignment.Left,
                Visible = true,
                Parent = TabButton,
            })

            local TextWidth = select(1, Library:GetTextBounds(Name, Library:GetWeightedFont(Enum.FontWeight.SemiBold), 14))
            local LeftPad = 6
            local TopWidth = TextWidth + (LeftPad * 2)
            TopTabButton = New("TextButton", {
                AutomaticSize = Enum.AutomaticSize.None,
                BackgroundTransparency = 1,
                ClipsDescendants = true,
                LayoutOrder = EffectiveOrder,
                Size = UDim2.fromOffset(TopWidth, 36),
                Text = "",
                Parent = TopTabs,
            })

            TabLabel = New("TextLabel", {
                AnchorPoint = Vector2.new(0, 0.5),
                BackgroundTransparency = 1,
                FontFace = function()
                    return Library:GetWeightedFont(Enum.FontWeight.SemiBold)
                end,
                RichText = false,
                Position = UDim2.new(0, 0, 0.5, 0),
                Size = UDim2.new(1, 0, 0, 18),
                Text = Name,
                TextColor3 = function()
                    return Library:GetUiColor("MutedText")
                end,
                TextSize = 14,
                TextStrokeTransparency = 1,
                TextXAlignment = Enum.TextXAlignment.Left,
                Parent = TopTabButton,
            })
            New("UIPadding", {
                PaddingLeft = UDim.new(0, LeftPad),
                PaddingRight = UDim.new(0, LeftPad),
                Parent = TabLabel,
            })
            TopTabGlow = New("Frame", {
                AnchorPoint = Vector2.new(0, 1),
                BackgroundColor3 = function()
                    return Library:GetUiColor("AccentSoft")
                end,
                BackgroundTransparency = 1,
                Position = UDim2.new(0, 0, 1, -2),
                Size = UDim2.fromOffset(TopWidth, 5),
                Visible = true,
                Parent = TopTabButton,
            })
            TopTabUnderline = New("Frame", {
                AnchorPoint = Vector2.new(0, 1),
                BackgroundColor3 = function()
                    return Library:GetUiColor("AccentFill")
                end,
                BackgroundTransparency = 1,
                Position = UDim2.new(0, 0, 1, -1),
                Size = UDim2.fromOffset(TopWidth, 2),
                Visible = true,
                Parent = TopTabButton,
            })

            SidebarButtonRegistration = {
                Button = TabButton,
                Label = TabLabel,
                SidebarLabel = SidebarLabel,
                TopLabel = TabLabel,
                Icon = TabIcon,
                Glow = TabButtonGlow,
                Scale = TabButtonScale,
            }
            table.insert(Library.TabButtons, SidebarButtonRegistration)

            --// Tab Container \\--
            TabContainer = New("Frame", {
                BackgroundTransparency = 1,
                Position = UDim2.fromOffset(0, 0),
                Size = UDim2.fromScale(1, 1),
                Visible = false,
                Parent = Container,
            })

            PageScroll = New("ScrollingFrame", {
                BackgroundTransparency = 1,
                CanvasSize = UDim2.fromOffset(0, 0),
                ScrollBarImageTransparency = 1,
                ScrollBarThickness = 0,
                Size = UDim2.fromScale(1, 1),
                Parent = TabContainer,
            })
            PageContent = New("Frame", {
                AutomaticSize = Enum.AutomaticSize.Y,
                BackgroundTransparency = 1,
                Size = UDim2.new(1, 0, 0, 0),
                Parent = PageScroll,
            })

            TabLeft = New("Frame", {
                AutomaticSize = Enum.AutomaticSize.Y,
                BackgroundTransparency = 1,
                Size = UDim2.new(0.5, -3, 0, 0),
                Parent = PageContent,
            })
            TabLeftList = New("UIListLayout", {
                Padding = UDim.new(0, 8),
                Parent = TabLeft,
            })
            New("UIPadding", {
                PaddingBottom = UDim.new(0, 4),
                PaddingLeft = UDim.new(0, 4),
                PaddingRight = UDim.new(0, 3),
                PaddingTop = UDim.new(0, 4),
                Parent = TabLeft,
            })
            do
                New("Frame", {
                    BackgroundTransparency = 1,
                    LayoutOrder = -1,
                    Parent = TabLeft,
                })
                New("Frame", {
                    BackgroundTransparency = 1,
                    LayoutOrder = 1,
                    Parent = TabLeft,
                })
            end

            TabRight = New("Frame", {
                AnchorPoint = Vector2.new(1, 0),
                BackgroundTransparency = 1,
                Position = UDim2.fromScale(1, 0),
                Size = UDim2.new(0.5, -3, 0, 0),
                AutomaticSize = Enum.AutomaticSize.Y,
                Parent = PageContent,
            })
            TabRightList = New("UIListLayout", {
                Padding = UDim.new(0, 8),
                Parent = TabRight,
            })
            New("UIPadding", {
                PaddingBottom = UDim.new(0, 4),
                PaddingLeft = UDim.new(0, 3),
                PaddingRight = UDim.new(0, 4),
                PaddingTop = UDim.new(0, 4),
                Parent = TabRight,
            })
            do
                New("Frame", {
                    BackgroundTransparency = 1,
                    LayoutOrder = -1,
                    Parent = TabRight,
                })
                New("Frame", {
                    BackgroundTransparency = 1,
                    LayoutOrder = 1,
                    Parent = TabRight,
                })
            end
        end

        --// Warning Box \\--
        local WarningBoxHolder = New("Frame", {
            AutomaticSize = Enum.AutomaticSize.Y,
            BackgroundTransparency = 1,
            Position = UDim2.fromOffset(0, 7),
            Size = UDim2.fromScale(1, 0),
            Visible = false,
            Parent = TabContainer,
        })

        local WarningBox
        local WarningBoxOutline
        local WarningBoxShadowOutline
        local WarningBoxScrollingFrame
        local WarningTitle
        local WarningStroke
        local WarningText
        do
            WarningBox = New("Frame", {
                BackgroundColor3 = "BackgroundColor",
                Position = UDim2.fromOffset(2, 0),
                Size = UDim2.new(1, -5, 0, 0),
                Parent = WarningBoxHolder,
            })
            New("UICorner", {
                CornerRadius = UDim.new(0, WindowInfo.CornerRadius),
                Parent = WarningBox,
            })
            WarningBoxOutline, WarningBoxShadowOutline = Library:AddOutline(WarningBox)

            WarningBoxScrollingFrame = New("ScrollingFrame", {
                BackgroundTransparency = 1,
                BorderSizePixel = 0,
                Size = UDim2.fromScale(1, 1),
                CanvasSize = UDim2.new(0, 0, 0, 0),
                ScrollBarThickness = 3,
                ScrollingDirection = Enum.ScrollingDirection.Y,
                Parent = WarningBox,
            })
            New("UIPadding", {
                PaddingBottom = UDim.new(0, 4),
                PaddingLeft = UDim.new(0, 6),
                PaddingRight = UDim.new(0, 6),
                PaddingTop = UDim.new(0, 4),
                Parent = WarningBoxScrollingFrame,
            })

            WarningTitle = New("TextLabel", {
                BackgroundTransparency = 1,
                Size = UDim2.new(1, -4, 0, 14),
                Text = "",
                TextColor3 = Color3.fromRGB(255, 50, 50),
                TextSize = 14,
                TextXAlignment = Enum.TextXAlignment.Left,
                Parent = WarningBoxScrollingFrame,
            })

            WarningStroke = New("UIStroke", {
                ApplyStrokeMode = Enum.ApplyStrokeMode.Contextual,
                Color = Color3.fromRGB(169, 0, 0),
                LineJoinMode = Enum.LineJoinMode.Miter,
                Parent = WarningTitle,
            })

            WarningText = New("TextLabel", {
                BackgroundTransparency = 1,
                Position = UDim2.fromOffset(0, 16),
                Size = UDim2.new(1, -4, 0, 0),
                Text = "",
                TextSize = 14,
                TextWrapped = true,
                Parent = WarningBoxScrollingFrame,
                TextXAlignment = Enum.TextXAlignment.Left,
                TextYAlignment = Enum.TextYAlignment.Top,
            })

            New("UIStroke", {
                ApplyStrokeMode = Enum.ApplyStrokeMode.Contextual,
                Color = "DarkColor",
                LineJoinMode = Enum.LineJoinMode.Miter,
                Parent = WarningText,
            })
        end

        --// Tab Table \\--
        local Tab = {
            Order = TabOrder,
            LayoutOrder = EffectiveOrder,
            Window = Window,
            Groupboxes = {},
            Tabboxes = {},
            DependencyGroupboxes = {},
            Sides = {
                PageScroll,
            },
            PageScroll = PageScroll,
            PageContent = PageContent,
            LeftColumn = TabLeft,
            RightColumn = TabRight,
            WarningBox = {
                IsNormal = false,
                LockSize = false,
                Visible = false,
                Title = "WARNING",
                Text = "",
            },
        }

        function Tab:UpdateWarningBox(Info)
            if typeof(Info.IsNormal) == "boolean" then
                Tab.WarningBox.IsNormal = Info.IsNormal
            end
            if typeof(Info.LockSize) == "boolean" then
                Tab.WarningBox.LockSize = Info.LockSize
            end
            if typeof(Info.Visible) == "boolean" then
                Tab.WarningBox.Visible = Info.Visible
            end
            if typeof(Info.Title) == "string" then
                Tab.WarningBox.Title = Info.Title
            end
            if typeof(Info.Text) == "string" then
                Tab.WarningBox.Text = Info.Text
            end

            WarningBoxHolder.Visible = Tab.WarningBox.Visible
            WarningTitle.Text = Tab.WarningBox.Title
            WarningText.Text = Tab.WarningBox.Text
            Tab:Resize(true)

            WarningBox.BackgroundColor3 = Tab.WarningBox.IsNormal == true and Library.Scheme.BackgroundColor
                or Color3.fromRGB(127, 0, 0)

            WarningBoxShadowOutline.Color = Tab.WarningBox.IsNormal == true and Library.Scheme.DarkColor
                or Color3.fromRGB(85, 0, 0)
            WarningBoxOutline.Color = Tab.WarningBox.IsNormal == true and Library.Scheme.OutlineColor
                or Color3.fromRGB(255, 50, 50)

            WarningTitle.TextColor3 = Tab.WarningBox.IsNormal == true and Library.Scheme.FontColor
                or Color3.fromRGB(255, 50, 50)
            WarningStroke.Color = Tab.WarningBox.IsNormal == true and Library.Scheme.OutlineColor
                or Color3.fromRGB(169, 0, 0)

            if not Library.Registry[WarningBox] then
                Library:AddToRegistry(WarningBox, {})
            end
            if not Library.Registry[WarningBoxShadowOutline] then
                Library:AddToRegistry(WarningBoxShadowOutline, {})
            end
            if not Library.Registry[WarningBoxOutline] then
                Library:AddToRegistry(WarningBoxOutline, {})
            end
            if not Library.Registry[WarningTitle] then
                Library:AddToRegistry(WarningTitle, {})
            end
            if not Library.Registry[WarningStroke] then
                Library:AddToRegistry(WarningStroke, {})
            end

            Library.Registry[WarningBox].BackgroundColor3 = function()
                return Tab.WarningBox.IsNormal == true and Library.Scheme.BackgroundColor or Color3.fromRGB(127, 0, 0)
            end

            Library.Registry[WarningBoxShadowOutline].Color = function()
                return Tab.WarningBox.IsNormal == true and Library.Scheme.DarkColor or Color3.fromRGB(85, 0, 0)
            end

            Library.Registry[WarningBoxOutline].Color = function()
                return Tab.WarningBox.IsNormal == true and Library.Scheme.OutlineColor or Color3.fromRGB(255, 50, 50)
            end

            Library.Registry[WarningTitle].TextColor3 = function()
                return Tab.WarningBox.IsNormal == true and Library.Scheme.FontColor or Color3.fromRGB(255, 50, 50)
            end

            Library.Registry[WarningStroke].Color = function()
                return Tab.WarningBox.IsNormal == true and Library.Scheme.OutlineColor or Color3.fromRGB(169, 0, 0)
            end
        end

        function Tab:RefreshSides()
            local Offset = WarningBoxHolder.Visible and WarningBox.Size.Y.Offset + 8 or 0
            if PageScroll then
                PageScroll.Position = UDim2.new(0, 0, 0, Offset)
                PageScroll.Size = UDim2.new(1, 0, 1, -Offset)
            end

            if PageContent and TabLeftList and TabRightList then
                local Height = math.max(TabLeftList.AbsoluteContentSize.Y, TabRightList.AbsoluteContentSize.Y)
                PageContent.Size = UDim2.new(1, 0, 0, Height + 6)
                if PageScroll then
                    PageScroll.CanvasSize = UDim2.fromOffset(0, Height + 6)
                end
            end
        end

        function Tab:Resize(ResizeWarningBox: boolean?)
            if ResizeWarningBox then
                local MaximumSize = math.floor(TabContainer.AbsoluteSize.Y / 3.25)
                local _, YText = Library:GetTextBounds(
                    WarningText.Text,
                    Library.Scheme.Font,
                    WarningText.TextSize,
                    WarningText.AbsoluteSize.X
                )

                local YBox = 24 + YText
                if Tab.WarningBox.LockSize == true and YBox >= MaximumSize then
                    WarningBoxScrollingFrame.CanvasSize = UDim2.fromOffset(0, YBox)
                    YBox = MaximumSize
                else
                    WarningBoxScrollingFrame.CanvasSize = UDim2.fromOffset(0, 0)
                end

                WarningText.Size = UDim2.new(1, -4, 0, YText)
                WarningBox.Size = UDim2.new(1, -5, 0, YBox + 4)
            end

            Tab:RefreshSides()
        end

        function Tab:AddGroupbox(Info)
            local BoxHolder = New("Frame", {
                AutomaticSize = Enum.AutomaticSize.Y,
                BackgroundTransparency = 1,
                Size = UDim2.fromScale(1, 0),
                Parent = Info.Side == 1 and TabLeft or TabRight,
            })
            New("UIListLayout", {
                Padding = UDim.new(0, 3),
                Parent = BoxHolder,
            })
            New("UIPadding", {
                PaddingBottom = UDim.new(0, 2),
                PaddingTop = UDim.new(0, 2),
                Parent = BoxHolder,
            })

            local GroupboxHolder
            local GroupboxLabel

            local GroupboxContainer
            local GroupboxList

            do
                GroupboxHolder = New("Frame", {
                    BackgroundColor3 = function()
                        return Library:GetUiColor("Card")
                    end,
                    Size = UDim2.fromScale(1, 0),
                    Parent = BoxHolder,
                })
                New("UICorner", {
                    CornerRadius = UDim.new(0, math.max(WindowInfo.CornerRadius, 14)),
                    Parent = GroupboxHolder,
                })
                Library:AddOutline(GroupboxHolder)
                if Tab.Window and Tab.Window.RegisterTransparencyTarget then
                    Tab.Window:RegisterTransparencyTarget(GroupboxHolder, 0.04, 0.6)
                end

                Library:MakeLine(GroupboxHolder, {
                    Position = UDim2.fromOffset(0, 34),
                    Size = UDim2.new(1, 0, 0, 1),
                })

                local BoxIcon = Library:GetCustomIcon(Info.IconName)
                if BoxIcon then
                    New("ImageLabel", {
                        Image = BoxIcon.Url,
                        ImageColor3 = BoxIcon.Custom and "WhiteColor" or function()
                            return Library:GetUiColor("AccentGlow")
                        end,
                        ImageRectOffset = BoxIcon.ImageRectOffset,
                        ImageRectSize = BoxIcon.ImageRectSize,
                        Position = UDim2.fromOffset(12, 9),
                        Size = UDim2.fromOffset(14, 14),
                        Parent = GroupboxHolder,
                    })
                end

                GroupboxLabel = New("TextLabel", {
                    BackgroundTransparency = 1,
                    FontFace = function()
                        return Library:GetWeightedFont(Enum.FontWeight.Bold)
                    end,
                    Position = UDim2.fromOffset(BoxIcon and 24 or 0, 0),
                    Size = UDim2.new(1, 0, 0, 34),
                    Text = Info.Name,
                    TextColor3 = function()
                        return Library:GetUiColor("ActiveText")
                    end,
                    TextSize = 15,
                    TextXAlignment = Enum.TextXAlignment.Left,
                    Parent = GroupboxHolder,
                })
                New("UIPadding", {
                    PaddingLeft = UDim.new(0, 18),
                    PaddingRight = UDim.new(0, 18),
                    Parent = GroupboxLabel,
                })

                GroupboxContainer = New("Frame", {
                    BackgroundTransparency = 1,
                    Position = UDim2.fromOffset(0, 35),
                    Size = UDim2.new(1, 0, 1, -35),
                    Parent = GroupboxHolder,
                })

                GroupboxList = New("UIListLayout", {
                    Padding = UDim.new(0, 3),
                    Parent = GroupboxContainer,
                })
                New("UIPadding", {
                    PaddingBottom = UDim.new(0, 8),
                    PaddingLeft = UDim.new(0, 12),
                    PaddingRight = UDim.new(0, 12),
                    PaddingTop = UDim.new(0, 2),
                    Parent = GroupboxContainer,
                })
            end

            local Groupbox = {
                BoxHolder = BoxHolder,
                Holder = GroupboxHolder,
                Container = GroupboxContainer,

                Tab = Tab,
                Window = Tab.Window,
                DependencyBoxes = {},
                Elements = {},
            }

            function Groupbox:Resize()
                GroupboxHolder.Size = UDim2.new(1, 0, 0, (GroupboxList.AbsoluteContentSize.Y / Library.DPIScale) + 45)
                if Groupbox.Tab and Groupbox.Tab.RefreshSides then
                    Groupbox.Tab:RefreshSides()
                end
            end

            setmetatable(Groupbox, BaseGroupbox)

            Groupbox:Resize()
            Tab.Groupboxes[Info.Name] = Groupbox

            return Groupbox
        end

        function Tab:AddLeftGroupbox(Name, IconName)
            return Tab:AddGroupbox({ Side = 1, Name = Name, IconName = IconName })
        end

        function Tab:AddRightGroupbox(Name, IconName)
            return Tab:AddGroupbox({ Side = 2, Name = Name, IconName = IconName })
        end

        function Tab:AddTabbox(Info)
            local BoxHolder = New("Frame", {
                AutomaticSize = Enum.AutomaticSize.Y,
                BackgroundTransparency = 1,
                Size = UDim2.fromScale(1, 0),
                Parent = Info.Side == 1 and TabLeft or TabRight,
            })
            New("UIListLayout", {
                Padding = UDim.new(0, 6),
                Parent = BoxHolder,
            })
            New("UIPadding", {
                PaddingBottom = UDim.new(0, 4),
                PaddingTop = UDim.new(0, 4),
                Parent = BoxHolder,
            })

            local TabboxHolder
            local TabboxButtons

            do
                TabboxHolder = New("Frame", {
                    BackgroundColor3 = "BackgroundColor",
                    ClipsDescendants = true,
                    Size = UDim2.fromScale(1, 0),
                    Parent = BoxHolder,
                })
                New("UICorner", {
                    CornerRadius = UDim.new(0, WindowInfo.CornerRadius),
                    Parent = TabboxHolder,
                })
                Library:AddOutline(TabboxHolder)
                if Tab.Window and Tab.Window.RegisterTransparencyTarget then
                    Tab.Window:RegisterTransparencyTarget(TabboxHolder, 0.04, 0.58)
                end

                TabboxButtons = New("Frame", {
                    BackgroundTransparency = 1,
                    Size = UDim2.new(1, 0, 0, 34),
                    Parent = TabboxHolder,
                })
                New("UIListLayout", {
                    FillDirection = Enum.FillDirection.Horizontal,
                    HorizontalFlex = Enum.UIFlexAlignment.Fill,
                    Parent = TabboxButtons,
                })
            end

            local Tabbox = {
                ActiveTab = nil,

                BoxHolder = BoxHolder,
                Holder = TabboxHolder,
                Tabs = {},
            }

            function Tabbox:AddTab(Name, IconName)
                local BoxIcon = Library:GetCustomIcon(IconName)

                local Button = New("TextButton", {
                    BackgroundColor3 = "MainColor",
                    BackgroundTransparency = 0,
                    ClipsDescendants = true,
                    Size = UDim2.fromOffset(0, 34),
                    Text = "",
                    Parent = TabboxButtons,
                })
                New("UICorner", {
                    CornerRadius = UDim.new(0, math.max(8, WindowInfo.CornerRadius - 2)),
                    Parent = Button,
                })

                local ButtonContent = New("Frame", {
                    AnchorPoint = Vector2.new(0.5, 0.5),
                    AutomaticSize = Enum.AutomaticSize.X,
                    BackgroundTransparency = 1,
                    Position = UDim2.fromScale(0.5, 0.5),
                    Size = UDim2.fromOffset(0, 16),
                    Parent = Button,
                })
                New("UIListLayout", {
                    FillDirection = Enum.FillDirection.Horizontal,
                    HorizontalAlignment = Enum.HorizontalAlignment.Center,
                    VerticalAlignment = Enum.VerticalAlignment.Center,
                    Padding = UDim.new(0, 8),
                    Parent = ButtonContent,
                })

                local ButtonIcon
                if BoxIcon then
                    ButtonIcon = New("ImageLabel", {
                        Image = BoxIcon.Url,
                        ImageColor3 = BoxIcon.Custom and "WhiteColor" or "AccentColor",
                        ImageRectOffset = BoxIcon.ImageRectOffset,
                        ImageRectSize = BoxIcon.ImageRectSize,
                        ImageTransparency = 0.5,
                        Size = UDim2.fromOffset(16, 16),
                        Parent = ButtonContent,
                    })
                end

                local ButtonLabel = New("TextLabel", {
                    AutomaticSize = Enum.AutomaticSize.X,
                    BackgroundTransparency = 1,
                    Size = UDim2.fromOffset(0, 16),
                    Text = Name,
                    TextSize = 15,
                    TextTransparency = 0.5,
                    Parent = ButtonContent,
                })

                local Line = Library:MakeLine(Button, {
                    AnchorPoint = Vector2.new(0, 1),
                    Position = UDim2.new(0, 0, 1, 1),
                    Size = UDim2.new(1, 0, 0, 1),
                })

                local Container = New("Frame", {
                    BackgroundTransparency = 1,
                    Position = UDim2.fromOffset(0, 35),
                    Size = UDim2.new(1, 0, 1, -35),
                    Visible = false,
                    Parent = TabboxHolder,
                })
                local List = New("UIListLayout", {
                    Padding = UDim.new(0, 8),
                    Parent = Container,
                })
                New("UIPadding", {
                    PaddingBottom = UDim.new(0, 7),
                    PaddingLeft = UDim.new(0, 7),
                    PaddingRight = UDim.new(0, 7),
                    PaddingTop = UDim.new(0, 7),
                    Parent = Container,
                })

                local Tab = {
                    ButtonHolder = Button,
                    Container = Container,

                    Tab = Tab,
                    Elements = {},
                    DependencyBoxes = {},
                }

                function Tab:Show()
                    if Tabbox.ActiveTab then
                        Tabbox.ActiveTab:Hide()
                    end

                    Button.BackgroundTransparency = 1
                    ButtonLabel.TextTransparency = 0
                    if ButtonIcon then
                        ButtonIcon.ImageTransparency = 0
                    end
                    Line.Visible = false

                    Container.Visible = true

                    Tabbox.ActiveTab = Tab
                    Tab:Resize()
                end

                function Tab:Hide()
                    Button.BackgroundTransparency = 0
                    ButtonLabel.TextTransparency = 0.5
                    if ButtonIcon then
                        ButtonIcon.ImageTransparency = 0.5
                    end
                    Line.Visible = true
                    Container.Visible = false

                    Tabbox.ActiveTab = nil
                end

                function Tab:Resize()
                    if Tabbox.ActiveTab ~= Tab then
                        return
                    end

                    TabboxHolder.Size = UDim2.new(1, 0, 0, (List.AbsoluteContentSize.Y / Library.DPIScale) + 49)
                    if Tab.Tab and Tab.Tab.RefreshSides then
                        Tab.Tab:RefreshSides()
                    end
                end

                --// Execution \\--
                if not Tabbox.ActiveTab then
                    Tab:Show()
                end

                Button.MouseButton1Click:Connect(Tab.Show)

                setmetatable(Tab, BaseGroupbox)

                Tabbox.Tabs[Name] = Tab

                return Tab
            end

            if Info.Name then
                Tab.Tabboxes[Info.Name] = Tabbox
            else
                table.insert(Tab.Tabboxes, Tabbox)
            end

            return Tabbox
        end

        function Tab:AddLeftTabbox(Name)
            return Tab:AddTabbox({ Side = 1, Name = Name })
        end

        function Tab:AddRightTabbox(Name)
            return Tab:AddTabbox({ Side = 2, Name = Name })
        end

        local function PlaySidebarTween(Key, Instance, Info, Goal)
            if not Instance then
                return
            end

            local TweenKey = Key .. "Tween"
            StopTween(Tab[TweenKey])
            Tab[TweenKey] = TweenService:Create(Instance, Info, Goal)
            Tab[TweenKey]:Play()
        end

        local function ApplySidebarState(State, Instant)
            Tab.SidebarState = State
            local AccentFill = Library:GetUiColor("AccentFill")
            local AccentSoft = Library:GetUiColor("AccentSoft")
            local ActiveText = Library:GetUiColor("ActiveText")
            local SubtleText = Library:GetUiColor("SubtleText")
            local SoftOutline = Library:GetUiColor("SoftOutline")
            local Compact = Window:IsSidebarCompacted()
            local ButtonWidth = Compact and 34 or math.max(112, Window:GetSidebarWidth() - 18)

            local Scale = 1
            local ButtonSize = UDim2.fromOffset(ButtonWidth, 34)
            local PlateSize = UDim2.fromOffset(0, 0)
            local PlateTransparency = 1
            local GlowSize = UDim2.fromOffset(0, 0)
            local GlowTransparency = 1
            local MarkerSize = UDim2.fromOffset(0, 0)
            local MarkerTransparency = 1
            local StrokeTransparency = 1
            local StrokeColor = SoftOutline
            local IconPosition = Compact and UDim2.fromScale(0.5, 0.5) or UDim2.new(0, 18, 0.5, 0)
            local IconColor = IsCustomSidebarIcon and Color3.fromRGB(255, 255, 255) or SubtleText
            local IconTransparency = IsCustomSidebarIcon and 0.18 or 0.04
            local IconGlowTransparency = 1
            local SidebarLabelTransparency = Compact and 1 or 0.34
            local SidebarLabelColor = SubtleText
            local SidebarLabelPosition = Compact and UDim2.fromOffset(42, 0) or UDim2.fromOffset(36, 0)

            if Compact then
                if State == "hover" then
                    PlateSize = UDim2.fromOffset(28, 28)
                    PlateTransparency = 0.74
                    IconColor = IsCustomSidebarIcon and Color3.fromRGB(255, 255, 255) or ActiveText
                    IconTransparency = 0
                elseif State == "active" then
                    PlateSize = UDim2.fromOffset(30, 30)
                    PlateTransparency = 0.06
                    IconColor = IsCustomSidebarIcon and Color3.fromRGB(255, 255, 255) or ActiveText
                    IconTransparency = 0
                end
            else
                PlateSize = UDim2.fromOffset(ButtonWidth - (State == "active" and 6 or 10), 30)
                PlateTransparency = State == "active" and 0.08 or (State == "hover" and 0.78 or 1)
                IconColor = IsCustomSidebarIcon and Color3.fromRGB(255, 255, 255) or (State == "idle" and SubtleText or ActiveText)
                IconTransparency = State == "idle" and (IsCustomSidebarIcon and 0.18 or 0.04) or 0
                SidebarLabelTransparency = State == "active" and 0 or (State == "hover" and 0.14 or 0.32)
                SidebarLabelColor = State == "idle" and SubtleText or ActiveText
                SidebarLabelPosition = State == "active" and UDim2.fromOffset(34, 0)
                    or (State == "hover" and UDim2.fromOffset(35, 0) or UDim2.fromOffset(38, 0))
            end

            if Instant then
                TabButton.Size = ButtonSize
                if TabButtonScale then
                    TabButtonScale.Scale = Scale
                end
                if TabButtonPlate then
                    TabButtonPlate.Size = PlateSize
                    TabButtonPlate.BackgroundTransparency = PlateTransparency
                end
                if TabButtonGlow then
                    TabButtonGlow.Size = GlowSize
                    TabButtonGlow.BackgroundTransparency = GlowTransparency
                end
                if TabButtonMarker then
                    TabButtonMarker.Size = MarkerSize
                    TabButtonMarker.BackgroundTransparency = MarkerTransparency
                end
                if TabButtonStroke then
                    TabButtonStroke.Color = StrokeColor
                    TabButtonStroke.Transparency = StrokeTransparency
                end
                if TabIcon then
                    pcall(function()
                        TabIcon.ImageColor3 = IconColor
                        TabIcon.ImageTransparency = IconTransparency
                    end)
                    pcall(function()
                        TabIcon.TextColor3 = IconColor
                        TabIcon.TextTransparency = IconTransparency
                    end)
                    pcall(function()
                        TabIcon.Position = IconPosition
                    end)
                end
                if TabIconGlow then
                    pcall(function()
                        TabIconGlow.ImageTransparency = IconGlowTransparency
                    end)
                    pcall(function()
                        TabIconGlow.TextTransparency = IconGlowTransparency
                    end)
                    pcall(function()
                        TabIconGlow.Position = IconPosition
                    end)
                end
                if SidebarLabel then
                    SidebarLabel.TextColor3 = SidebarLabelColor
                    SidebarLabel.TextTransparency = SidebarLabelTransparency
                    SidebarLabel.Position = SidebarLabelPosition
                    SidebarLabel.FontFace = Library:GetWeightedFont(
                        State == "active" and Enum.FontWeight.Bold or Enum.FontWeight.Medium
                    )
                end
                return
            end

            PlaySidebarTween("ButtonSize", TabButton, TweenInfo.new(0.22, Enum.EasingStyle.Quart, Enum.EasingDirection.Out), {
                Size = ButtonSize,
            })
            PlaySidebarTween("Scale", TabButtonScale, TweenInfo.new(0.18, Enum.EasingStyle.Quart, Enum.EasingDirection.Out), {
                Scale = Scale,
            })
            PlaySidebarTween("Plate", TabButtonPlate, TweenInfo.new(0.18, Enum.EasingStyle.Quart, Enum.EasingDirection.Out), {
                Size = PlateSize,
                BackgroundTransparency = PlateTransparency,
            })
            PlaySidebarTween("Glow", TabButtonGlow, TweenInfo.new(0.2, Enum.EasingStyle.Quad, Enum.EasingDirection.Out), {
                Size = GlowSize,
                BackgroundTransparency = GlowTransparency,
            })
            PlaySidebarTween("Marker", TabButtonMarker, TweenInfo.new(0.18, Enum.EasingStyle.Quart, Enum.EasingDirection.Out), {
                Size = MarkerSize,
                BackgroundTransparency = MarkerTransparency,
            })
            if TabButtonStroke then
                TabButtonStroke.Color = StrokeColor
                PlaySidebarTween("Stroke", TabButtonStroke, TweenInfo.new(0.16, Enum.EasingStyle.Quad, Enum.EasingDirection.Out), {
                    Transparency = StrokeTransparency,
                })
            end
            if TabIcon then
                pcall(function()
                    TabIcon.ImageColor3 = IconColor
                end)
                pcall(function()
                    TabIcon.TextColor3 = IconColor
                end)
                pcall(function()
                    PlaySidebarTween("IconImage", TabIcon, TweenInfo.new(0.16, Enum.EasingStyle.Quad, Enum.EasingDirection.Out), {
                        ImageTransparency = IconTransparency,
                    })
                end)
                pcall(function()
                    PlaySidebarTween("IconImagePosition", TabIcon, TweenInfo.new(0.18, Enum.EasingStyle.Quart, Enum.EasingDirection.Out), {
                        Position = IconPosition,
                    })
                end)
                pcall(function()
                    PlaySidebarTween("IconText", TabIcon, TweenInfo.new(0.16, Enum.EasingStyle.Quad, Enum.EasingDirection.Out), {
                        TextTransparency = IconTransparency,
                    })
                end)
                pcall(function()
                    PlaySidebarTween("IconTextPosition", TabIcon, TweenInfo.new(0.18, Enum.EasingStyle.Quart, Enum.EasingDirection.Out), {
                        Position = IconPosition,
                    })
                end)
            end
            if TabIconGlow then
                pcall(function()
                    PlaySidebarTween("IconGlowImage", TabIconGlow, TweenInfo.new(0.16, Enum.EasingStyle.Quad, Enum.EasingDirection.Out), {
                        ImageTransparency = IconGlowTransparency,
                    })
                end)
                pcall(function()
                    PlaySidebarTween("IconGlowImagePosition", TabIconGlow, TweenInfo.new(0.18, Enum.EasingStyle.Quart, Enum.EasingDirection.Out), {
                        Position = IconPosition,
                    })
                end)
                pcall(function()
                    PlaySidebarTween("IconGlowText", TabIconGlow, TweenInfo.new(0.16, Enum.EasingStyle.Quad, Enum.EasingDirection.Out), {
                        TextTransparency = IconGlowTransparency,
                    })
                end)
                pcall(function()
                    PlaySidebarTween("IconGlowTextPosition", TabIconGlow, TweenInfo.new(0.18, Enum.EasingStyle.Quart, Enum.EasingDirection.Out), {
                        Position = IconPosition,
                    })
                end)
            end
            if SidebarLabel then
                SidebarLabel.TextColor3 = SidebarLabelColor
                SidebarLabel.FontFace = Library:GetWeightedFont(
                    State == "active" and Enum.FontWeight.Bold or Enum.FontWeight.SemiBold
                )
                PlaySidebarTween("SidebarLabelPosition", SidebarLabel, TweenInfo.new(0.18, Enum.EasingStyle.Quart, Enum.EasingDirection.Out), {
                    Position = SidebarLabelPosition,
                })
                PlaySidebarTween("SidebarLabel", SidebarLabel, TweenInfo.new(0.16, Enum.EasingStyle.Quad, Enum.EasingDirection.Out), {
                    TextTransparency = SidebarLabelTransparency,
                })
            end
        end

        function Tab:RefreshSidebar(Animate)
            local State = "idle"
            if Library.ActiveTab == Tab then
                State = "active"
            elseif Tab.IsHovered then
                State = "hover"
            end
            ApplySidebarState(State, not Animate)
        end
        if SidebarButtonRegistration then
            SidebarButtonRegistration.RefreshSidebar = function(Animate)
                Tab:RefreshSidebar(Animate)
            end
        end

        function Tab:Hover(Hovering)
            if Library.ActiveTab == Tab then
                return
            end

            Tab.IsHovered = Hovering
            TabLabel.TextColor3 = Hovering and Library:GetUiColor("ActiveText") or Library:GetUiColor("MutedText")
            ApplySidebarState(Hovering and "hover" or "idle", false)
        end

        function Tab:Show()
            local PreviousTab = Library.ActiveTab

            if Library.ActiveTab then
                Library.ActiveTab:Hide()
            end

            StopTween(Tab.ButtonTween)
            StopTween(Tab.UnderlineTween)
            StopTween(Tab.GlowTween)
            TabButton.BackgroundTransparency = 1
            ApplySidebarState("active", false)
            TabLabel.FontFace = Library:GetWeightedFont(Enum.FontWeight.Bold)
            TabLabel.TextColor3 = Library:GetUiColor("ActiveText")
            if TopTabGlow then
                Tab.GlowTween = TweenService:Create(TopTabGlow, Library.TweenInfo, {
                    BackgroundTransparency = 0.72,
                })
                Tab.GlowTween:Play()
            end
            Tab.UnderlineTween = TweenService:Create(TopTabUnderline, Library.TweenInfo, {
                BackgroundTransparency = 0,
            })
            Tab.UnderlineTween:Play()

            if Description then
                Window:ShowTabInfo(Name, Description)
            else
                Window:ShowTabInfo(Name, Name)
            end

            local StartOffsetX = 0
            if PreviousTab and PreviousTab.Order then
                StartOffsetX = Tab.Order > PreviousTab.Order and 10 or -10
            end

            TabContainer.Position = UDim2.fromOffset(StartOffsetX, 6)
            TabContainer.Visible = true
            StopTween(Tab.ContainerTween)
            Tab.ContainerTween = TweenService:Create(TabContainer, TweenInfo.new(0.18, Enum.EasingStyle.Quart, Enum.EasingDirection.Out), {
                Position = UDim2.fromOffset(0, 0),
            })
            Tab.ContainerTween:Play()
            Tab:RefreshSides()

            Library.ActiveTab = Tab

            if Library.Searching then
                Library:UpdateSearch(Library.SearchText)
            end
        end

        function Tab:Hide()
            StopTween(Tab.ButtonTween)
            StopTween(Tab.UnderlineTween)
            StopTween(Tab.GlowTween)
            StopTween(Tab.ContainerTween)
            TabButton.BackgroundTransparency = 1
            ApplySidebarState("idle", false)
            TabLabel.FontFace = Library:GetWeightedFont(Enum.FontWeight.SemiBold)
            TabLabel.TextColor3 = Library:GetUiColor("MutedText")
            if TopTabGlow then
                Tab.GlowTween = TweenService:Create(TopTabGlow, Library.TweenInfo, {
                    BackgroundTransparency = 1,
                })
                Tab.GlowTween:Play()
            end
            Tab.UnderlineTween = TweenService:Create(TopTabUnderline, Library.TweenInfo, {
                BackgroundTransparency = 1,
            })
            Tab.UnderlineTween:Play()
            TabContainer.Position = UDim2.fromOffset(0, 0)
            TabContainer.Visible = false

            Window:HideTabInfo()

            Library.ActiveTab = nil
        end

        --// Execution \\--
        ApplySidebarState("idle", true)
        if not Library.ActiveTab and WindowInfo.AutoSelectFirstTab then
            Tab:Show()
        end

        task.delay(0.04 * math.max(TabOrder - 1, 0), function()
            if not (TabButton and TabButton.Parent) then
                return
            end

            if Library.ActiveTab == Tab then
                ApplySidebarState("active", false)
            else
                ApplySidebarState("idle", false)
            end
        end)

        TabButton.MouseEnter:Connect(function()
            Tab:Hover(true)
        end)
        TabButton.MouseLeave:Connect(function()
            Tab:Hover(false)
        end)
        TabButton.MouseButton1Click:Connect(Tab.Show)
        TopTabButton.MouseEnter:Connect(function()
            Tab:Hover(true)
        end)
        TopTabButton.MouseLeave:Connect(function()
            Tab:Hover(false)
        end)
        TopTabButton.MouseButton1Click:Connect(Tab.Show)

        Library.Tabs[Name] = Tab

        return Tab
    end

    function Window:AddKeyTab(...)
        local Name = nil
        local Icon = nil
        local Description = nil

        if select("#", ...) == 1 and typeof(...) == "table" then
            local Info = select(1, ...)
            Name = Info.Name or "Tab"
            Icon = Info.Icon
            Description = Info.Description
        else
            Name = select(1, ...) or "Tab"
            Icon = select(2, ...)
            Description = select(3, ...)
        end

        Icon = Icon or "key"

        local TabButton: TextButton
        local TabButtonScale
        local TabButtonPlate
        local TabButtonStroke
        local TabButtonGlow
        local TabButtonMarker
        local TabLabel
        local TabIcon
        local TabIconGlow
        local TopTabButton
        local TopTabUnderline

        local TabContainer

        Icon = if Icon == "key" then KeyIcon else Library:GetCustomIcon(Icon)
        local IsCustomSidebarIcon = Icon and Icon.Custom == true
        do
            TabButton = New("TextButton", {
                BackgroundColor3 = function()
                    return Library:GetUiColor("DarkColor")
                end,
                BackgroundTransparency = 1,
                ClipsDescendants = true,
                Size = UDim2.fromOffset(34, 34),
                Text = "",
                Parent = Tabs,
            })
            New("UICorner", {
                CornerRadius = UDim.new(0, 12),
                Parent = TabButton,
            })
            TabButtonScale = New("UIScale", {
                Scale = 0.78,
                Parent = TabButton,
            })
            TabButtonPlate = New("Frame", {
                AnchorPoint = Vector2.new(0.5, 0.5),
                BackgroundColor3 = function()
                    return Library:GetUiColor("AccentFill")
                end,
                BackgroundTransparency = 1,
                Position = UDim2.fromScale(0.5, 0.5),
                Size = UDim2.fromOffset(0, 0),
                Parent = TabButton,
            })
            New("UICorner", {
                CornerRadius = UDim.new(0, 12),
                Parent = TabButtonPlate,
            })
            New("UIGradient", {
                Rotation = 25,
                Color = function()
                    local Accent = Library:GetUiColor("AccentFill")
                    return ColorSequence.new({
                        ColorSequenceKeypoint.new(0, Library:LerpColor(Accent, Color3.new(1, 1, 1), 0.2)),
                        ColorSequenceKeypoint.new(1, Library:LerpColor(Accent, Color3.new(0, 0, 0), 0.1)),
                    })
                end,
                Parent = TabButtonPlate,
            })
            TabButtonGlow = New("Frame", {
                AnchorPoint = Vector2.new(0.5, 0.5),
                BackgroundColor3 = function()
                    return Library:GetUiColor("AccentFill")
                end,
                BackgroundTransparency = 1,
                Position = UDim2.fromScale(0.5, 0.5),
                Size = UDim2.fromOffset(0, 0),
                Parent = TabButton,
            })
            New("UICorner", {
                CornerRadius = UDim.new(0, 13),
                Parent = TabButtonGlow,
            })
            TabButtonMarker = New("Frame", {
                AnchorPoint = Vector2.new(0, 0.5),
                BackgroundColor3 = function()
                    return Library:GetUiColor("AccentFill")
                end,
                BackgroundTransparency = 1,
                Position = UDim2.new(0, 2, 0.5, 0),
                Size = UDim2.fromOffset(2, 0),
                Parent = TabButton,
            })
            New("UICorner", {
                CornerRadius = UDim.new(1, 0),
                Parent = TabButtonMarker,
            })
            TabButtonStroke = New("UIStroke", {
                Color = function()
                    return Library:GetUiColor("SoftOutline")
                end,
                Transparency = 1,
                Parent = TabButton,
            })

            if Icon then
                TabIconGlow = New("ImageLabel", {
                    Image = Icon.Url,
                    ImageColor3 = function()
                        return Library:GetUiColor("ActiveText")
                    end,
                    ImageRectOffset = Icon.ImageRectOffset,
                    ImageRectSize = Icon.ImageRectSize,
                    AnchorPoint = Vector2.new(0.5, 0.5),
                    ImageTransparency = 1,
                    Position = UDim2.fromScale(0.5, 0.5),
                    Size = UDim2.fromOffset(24, 24),
                    Parent = TabButton,
                })
                TabIcon = New("ImageLabel", {
                    Image = Icon.Url,
                    ImageColor3 = function()
                        return IsCustomSidebarIcon and Color3.new(1, 1, 1) or Library:GetUiColor("SubtleText")
                    end,
                    ImageRectOffset = Icon.ImageRectOffset,
                    ImageRectSize = Icon.ImageRectSize,
                    AnchorPoint = Vector2.new(0.5, 0.5),
                    ImageTransparency = 1,
                    Position = UDim2.fromScale(0.5, 0.5),
                    Size = UDim2.fromOffset(18, 18),
                    Parent = TabButton,
                })
                AttachImageLoadFallback(TabIcon, Icon.Url)
                AttachImageLoadFallback(TabIconGlow, Icon.Url)
            end

            local TextWidth = select(1, Library:GetTextBounds(Name, Library:GetWeightedFont(Enum.FontWeight.Medium), 16))
            local LeftPad = 6
            local TopWidth = TextWidth + (LeftPad * 2)
            TopTabButton = New("TextButton", {
                BackgroundTransparency = 1,
                Size = UDim2.fromOffset(TopWidth, 34),
                Text = "",
                Parent = TopTabs,
            })
            TabLabel = New("TextLabel", {
                BackgroundTransparency = 1,
                FontFace = function()
                    return Library:GetWeightedFont(Enum.FontWeight.Medium)
                end,
                Size = UDim2.new(1, 0, 1, 0),
                Text = Name,
                TextColor3 = function()
                    return Library:GetUiColor("SubtleText")
                end,
                TextSize = 15,
                TextXAlignment = Enum.TextXAlignment.Left,
                Parent = TopTabButton,
            })
            New("UIPadding", {
                PaddingLeft = UDim.new(0, LeftPad),
                PaddingRight = UDim.new(0, LeftPad),
                Parent = TabLabel,
            })
            TopTabUnderline = New("Frame", {
                AnchorPoint = Vector2.new(0, 1),
                BackgroundColor3 = function()
                    return Library:GetUiColor("AccentFill")
                end,
                Position = UDim2.new(0, 0, 1, 1),
                Size = UDim2.fromOffset(TopWidth, 3),
                Visible = false,
                Parent = TopTabButton,
            })

            table.insert(Library.TabButtons, {
                Button = TabButton,
                Label = TabLabel,
                TopLabel = TabLabel,
                Icon = TabIcon,
                Glow = TabButtonGlow,
                Scale = TabButtonScale,
            })

            --// Tab Container \\--
            TabContainer = New("ScrollingFrame", {
                AutomaticCanvasSize = Enum.AutomaticSize.Y,
                BackgroundTransparency = 1,
                CanvasSize = UDim2.fromScale(0, 0),
                ScrollBarThickness = 0,
                Size = UDim2.fromScale(1, 1),
                Visible = false,
                Parent = Container,
            })
            New("UIListLayout", {
                HorizontalAlignment = Enum.HorizontalAlignment.Center,
                Padding = UDim.new(0, 8),
                VerticalAlignment = Enum.VerticalAlignment.Center,
                Parent = TabContainer,
            })
            New("UIPadding", {
                PaddingLeft = UDim.new(0, 1),
                PaddingRight = UDim.new(0, 1),
                Parent = TabContainer,
            })
        end

        --// Tab Table \\--
        local Tab = {
            Elements = {},
            IsKeyTab = true,
        }

        function Tab:AddKeyBox(Callback)
            assert(typeof(Callback) == "function", "Callback must be a function")

            local Holder = New("Frame", {
                BackgroundTransparency = 1,
                Size = UDim2.new(0.75, 0, 0, 21),
                Parent = TabContainer,
            })

            local Box = New("TextBox", {
                BackgroundColor3 = "MainColor",
                BorderColor3 = "OutlineColor",
                BorderSizePixel = 1,
                PlaceholderText = "Key",
                Size = UDim2.new(1, -71, 1, 0),
                TextSize = 14,
                TextXAlignment = Enum.TextXAlignment.Left,
                Parent = Holder,
            })
            New("UIPadding", {
                PaddingLeft = UDim.new(0, 8),
                PaddingRight = UDim.new(0, 8),
                Parent = Box,
            })

            local Button = New("TextButton", {
                AnchorPoint = Vector2.new(1, 0),
                BackgroundColor3 = "MainColor",
                BorderColor3 = "OutlineColor",
                BorderSizePixel = 1,
                Position = UDim2.fromScale(1, 0),
                Size = UDim2.new(0, 63, 1, 0),
                Text = "Execute",
                TextSize = 14,
                Parent = Holder,
            })

            Button.InputBegan:Connect(function(Input)
                if not IsClickInput(Input) then
                    return
                end

                if not Library:MouseIsOverFrame(Button, Input.Position) then
                    return
                end

                Callback(Box.Text)
            end)
        end

        function Tab:RefreshSides() end
        function Tab:Resize() end

        function Tab:Hover(Hovering)
            if Library.ActiveTab == Tab then
                return
            end

            TabLabel.TextColor3 = Hovering and Library:GetUiColor("MutedText") or Library:GetUiColor("SubtleText")
            if TabIcon then
                pcall(function()
                    TabIcon.ImageColor3 = IsCustomSidebarIcon and Color3.fromRGB(255, 255, 255) or (Hovering and Library:GetUiColor("ActiveText") or Library:GetUiColor("SubtleText"))
                    TabIcon.ImageTransparency = IsCustomSidebarIcon and (Hovering and 1 or 0.38) or 0
                end)
                pcall(function()
                    TabIcon.TextColor3 = Hovering and Library:GetUiColor("AccentGlow") or Library:GetUiColor("SubtleText")
                end)
            end
            if TabIconGlow then
                pcall(function()
                    TabIconGlow.ImageTransparency = IsCustomSidebarIcon and (Hovering and 0.58 or 1) or (Hovering and 0.78 or 1)
                end)
            end
            if TabButtonStroke then
                TabButtonStroke.Color = Hovering and Library:GetUiColor("AccentSoft") or Library:GetUiColor("SoftOutline")
                TabButtonStroke.Transparency = 1
            end
            if TabButtonGlow then
                StopTween(Tab.GlowBubbleTween)
                Tab.GlowBubbleTween = TweenService:Create(
                    TabButtonGlow,
                    TweenInfo.new(0.12, Enum.EasingStyle.Quad, Enum.EasingDirection.Out),
                    {
                        BackgroundTransparency = 1,
                        Size = UDim2.fromOffset(0, 0),
                    }
                )
                Tab.GlowBubbleTween:Play()
            end
        end

        function Tab:Show()
            if Library.ActiveTab then
                Library.ActiveTab:Hide()
            end

            StopTween(Tab.GlowBubbleTween)
            TabButton.BackgroundTransparency = 1
            if TabButtonStroke then
                TabButtonStroke.Color = Library:GetUiColor("AccentSoft")
                TabButtonStroke.Transparency = 1
            end
            if TabButtonGlow then
                Tab.GlowBubbleTween = TweenService:Create(TabButtonGlow, Library.TweenInfo, {
                    BackgroundTransparency = 1,
                    Size = UDim2.fromOffset(0, 0),
                })
                Tab.GlowBubbleTween:Play()
            end
            TabLabel.FontFace = Library:GetWeightedFont(Enum.FontWeight.Bold)
            TabLabel.TextColor3 = Library:GetUiColor("ActiveText")
            TopTabUnderline.Visible = true
            if TabIcon then
                pcall(function()
                    TabIcon.ImageColor3 = IsCustomSidebarIcon and Color3.fromRGB(255, 255, 255) or Library:GetUiColor("ActiveText")
                    TabIcon.ImageTransparency = IsCustomSidebarIcon and 1 or 0
                end)
                pcall(function()
                    TabIcon.TextColor3 = Library:GetUiColor("AccentFill")
                end)
            end
            if TabIconGlow then
                pcall(function()
                    TabIconGlow.ImageTransparency = IsCustomSidebarIcon and 0.1 or 0.42
                end)
            end
            TabContainer.Visible = true

            if Description then
                Window:ShowTabInfo(Name, Description)
            else
                Window:ShowTabInfo(Name, Name)
            end

            Tab:RefreshSides()

            Library.ActiveTab = Tab

            if Library.Searching then
                Library:UpdateSearch(Library.SearchText)
            end
        end

        function Tab:Hide()
            StopTween(Tab.GlowBubbleTween)
            TabButton.BackgroundTransparency = 1
            if TabButtonStroke then
                TabButtonStroke.Color = Library:GetUiColor("SoftOutline")
                TabButtonStroke.Transparency = 1
            end
            if TabButtonGlow then
                Tab.GlowBubbleTween = TweenService:Create(TabButtonGlow, Library.TweenInfo, {
                    BackgroundTransparency = 1,
                    Size = UDim2.fromOffset(0, 0),
                })
                Tab.GlowBubbleTween:Play()
            end
            TabLabel.FontFace = Library:GetWeightedFont(Enum.FontWeight.SemiBold)
            TabLabel.TextColor3 = Library:GetUiColor("MutedText")
            TopTabUnderline.Visible = false
            if TabIcon then
                pcall(function()
                    TabIcon.ImageColor3 = IsCustomSidebarIcon and Color3.fromRGB(255, 255, 255) or Library:GetUiColor("SubtleText")
                    TabIcon.ImageTransparency = IsCustomSidebarIcon and 0.38 or 0
                end)
                pcall(function()
                    TabIcon.TextColor3 = Library:GetUiColor("SubtleText")
                end)
            end
            if TabIconGlow then
                pcall(function()
                    TabIconGlow.ImageTransparency = 1
                end)
            end
            TabContainer.Visible = false

            Window:HideTabInfo()

            Library.ActiveTab = nil
        end

        --// Execution \\--
        if not Library.ActiveTab and WindowInfo.AutoSelectFirstTab then
            Tab:Show()
        end

        TabButton.MouseEnter:Connect(function()
            Tab:Hover(true)
        end)
        TabButton.MouseLeave:Connect(function()
            Tab:Hover(false)
        end)
        TabButton.MouseButton1Click:Connect(Tab.Show)
        TopTabButton.MouseEnter:Connect(function()
            Tab:Hover(true)
        end)
        TopTabButton.MouseLeave:Connect(function()
            Tab:Hover(false)
        end)
        TopTabButton.MouseButton1Click:Connect(Tab.Show)

        Tab.Container = TabContainer
        setmetatable(Tab, BaseGroupbox)

        Library.Tabs[Name] = Tab

        return Tab
    end

    function Window:AddDialog(Idx, Info)
        Info = Library:Validate(Info, Templates.Dialog)

        local DialogFrame
        local DialogOverlay
        local DialogContainer
        local ButtonsHolder
        local FooterButtonsList = {}

        DialogOverlay = New("TextButton", {
            AutoButtonColor = false,
            BackgroundColor3 = "DarkColor",
            BackgroundTransparency = 1,
            Size = UDim2.fromScale(1, 1),
            Text = "",
            Active = false,
            ZIndex = 9000,
            Visible = true,
            Parent = MainFrame,
        })
        TweenService:Create(DialogOverlay, Library.TweenInfo, {
            BackgroundTransparency = 0.5,
        }):Play()

        DialogFrame = New("TextButton", {
            AnchorPoint = Vector2.new(0.5, 0.5),
            BackgroundColor3 = "BackgroundColor",
            Position = UDim2.fromScale(0.5, 0.5),
            Size = UDim2.fromOffset(300, 0),
            AutomaticSize = Enum.AutomaticSize.Y,
            Text = "",
            AutoButtonColor = false,
            ZIndex = 9001,
            Parent = DialogOverlay,
        })
        New("UICorner", {
            CornerRadius = UDim.new(0, WindowInfo.CornerRadius),
            Parent = DialogFrame,
        })
        Library:AddOutline(DialogFrame)

        local InnerContainer = New("Frame", {
            BackgroundTransparency = 1,
            Size = UDim2.fromScale(1, 0),
            AutomaticSize = Enum.AutomaticSize.Y,
            ZIndex = 9002,
            Parent = DialogFrame,
        })
        local DialogScale = New("UIScale", {
            Scale = 0.95,
            Parent = DialogFrame,
        })
        TweenService:Create(DialogScale, Library.TweenInfo, {
            Scale = 1
        }):Play()
        local _InnerPadding = New("UIPadding", {
            PaddingBottom = UDim.new(0, 15),
            PaddingLeft = UDim.new(0, 15),
            PaddingRight = UDim.new(0, 15),
            PaddingTop = UDim.new(0, 15),
            Parent = InnerContainer,
        })
        local _InnerLayout = New("UIListLayout", {
            Padding = UDim.new(0, 10),
            SortOrder = Enum.SortOrder.LayoutOrder,
            Parent = InnerContainer,
        })

        local HeaderContainer = New("Frame", {
            BackgroundTransparency = 1,
            Size = UDim2.fromScale(1, 0),
            AutomaticSize = Enum.AutomaticSize.Y,
            LayoutOrder = 1,
            ZIndex = 9002,
            Parent = InnerContainer,
        })
        New("UIListLayout", {
            Padding = UDim.new(0, 6),
            SortOrder = Enum.SortOrder.LayoutOrder,
            Parent = HeaderContainer,
        })
        New("UIPadding", {
            PaddingBottom = UDim.new(0, 5),
            Parent = HeaderContainer,
        })

        local TitleRow = New("Frame", {
            BackgroundTransparency = 1,
            Size = UDim2.new(1, 0, 0, 20),
            AutomaticSize = Enum.AutomaticSize.Y,
            LayoutOrder = 1,
            ZIndex = 9002,
            Parent = HeaderContainer,
        })
        New("UIListLayout", {
            Padding = UDim.new(0, 6),
            FillDirection = Enum.FillDirection.Horizontal,
            VerticalAlignment = Enum.VerticalAlignment.Center,
            SortOrder = Enum.SortOrder.LayoutOrder,
            Parent = TitleRow,
        })

        if Info.Icon then
            local ParsedIcon = Library:GetCustomIcon(Info.Icon)
            if ParsedIcon then
                local IconImg = New("ImageLabel", {
                    BackgroundTransparency = 1,
                    Size = UDim2.fromOffset(16, 16),
                    Image = ParsedIcon.Url,
                    ImageColor3 = "FontColor",
                    ImageRectOffset = ParsedIcon.ImageRectOffset,
                    ImageRectSize = ParsedIcon.ImageRectSize,
                    LayoutOrder = 1,
                    ZIndex = 9002,
                    Parent = TitleRow,
                })
                if Info.TitleColor then
                    IconImg.ImageColor3 = Info.TitleColor
                end
            end
        end

        local TitleLabel = New("TextLabel", {
            BackgroundTransparency = 1,
            Size = UDim2.new(1, 0, 0, 18),
            AutomaticSize = Enum.AutomaticSize.Y,
            Text = Info.Title,
            TextSize = 18,
            TextXAlignment = Enum.TextXAlignment.Left,
            LayoutOrder = 2,
            ZIndex = 9002,
            Parent = TitleRow,
        })
        if Info.TitleColor then
            TitleLabel.TextColor3 = Info.TitleColor
        end

        local DescriptionLabel = New("TextLabel", {
            BackgroundTransparency = 1,
            Size = UDim2.new(1, 0, 0, 14),
            AutomaticSize = Enum.AutomaticSize.Y,
            Text = Info.Description,
            TextSize = 14,
            TextTransparency = Info.DescriptionColor and 0 or 0.2,
            TextXAlignment = Enum.TextXAlignment.Left,
            TextWrapped = true,
            LayoutOrder = 2,
            ZIndex = 9002,
            Parent = HeaderContainer,
        })
        if Info.DescriptionColor then
            DescriptionLabel.TextColor3 = Info.DescriptionColor
        end

        DialogContainer = New("Frame", {
            BackgroundTransparency = 1,
            Size = UDim2.fromScale(1, 0),
            AutomaticSize = Enum.AutomaticSize.Y,
            LayoutOrder = 4,
            ZIndex = 9002,
            Parent = InnerContainer,
        })
        local _DialogContainerLayout = New("UIListLayout", {
            Padding = UDim.new(0, 8),
            SortOrder = Enum.SortOrder.LayoutOrder,
            Parent = DialogContainer,
        })
        New("UIPadding", {
            PaddingBottom = UDim.new(0, 5),
            Parent = DialogContainer,
        })
        
        local _Sep2 = New("Frame", {
            BackgroundColor3 = "OutlineColor",
            BackgroundTransparency = 0,
            BorderSizePixel = 0,
            Size = UDim2.new(1, 0, 0, 1),
            LayoutOrder = 5,
            ZIndex = 9002,
            Parent = InnerContainer,
        })

        ButtonsHolder = New("Frame", {
            BackgroundTransparency = 1,
            Size = UDim2.new(1, 0, 0, 0),
            AutomaticSize = Enum.AutomaticSize.Y,
            LayoutOrder = 6,
            ZIndex = 9002,
            Parent = InnerContainer,
        })
        New("UIListLayout", {
            Padding = UDim.new(0, 8),
            FillDirection = Enum.FillDirection.Horizontal,
            HorizontalAlignment = Enum.HorizontalAlignment.Right,
            Wraps = true,
            SortOrder = Enum.SortOrder.LayoutOrder,
            Parent = ButtonsHolder,
        })
        New("UIPadding", {
            PaddingTop = UDim.new(0, 5),
            Parent = ButtonsHolder,
        })

        local Dialog = {
            Elements = {},
            Container = DialogContainer,
        }

        function Dialog:Resize()
            local MaxWidth = MainFrame.AbsoluteSize.X * 0.75
            local MinWidth = 400

            local TotalButtonWidth = 0
            local ButtonCount = 0
            local HasButtons = false

            for _, BtnWrap in FooterButtonsList do
                HasButtons = true
                ButtonCount = ButtonCount + 1
                TotalButtonWidth = TotalButtonWidth + BtnWrap.Container.Size.X.Offset
            end

            local TargetWidth = MinWidth
            if HasButtons then
                local RequiredWidth = TotalButtonWidth + ((ButtonCount - 1) * 8) + 30
                TargetWidth = math.max(MinWidth, math.min(RequiredWidth, MaxWidth))
            end

            DialogFrame.Size = UDim2.fromOffset(TargetWidth, 0)

            local _DescX, DescY = Library:GetTextBounds(DescriptionLabel.Text, Library.Scheme.Font, 14, TargetWidth - 30)
            DescriptionLabel.Size = UDim2.new(1, 0, 0, DescY)

            local HasElements = false
            for _, v in DialogContainer:GetChildren() do
                if not v:IsA("UIListLayout") and not v:IsA("UIPadding") then
                    HasElements = true
                    break
                end
            end
            DialogContainer.Visible = HasElements

            ButtonsHolder.Visible = HasButtons
            _Sep2.Visible = HasButtons
        end

        function Dialog:SetTitle(Title)
            TitleLabel.Text = Title
            Dialog:Resize()
        end

        function Dialog:SetDescription(Description)
            DescriptionLabel.Text = Description
            Dialog:Resize()
        end

        function Dialog:Dismiss()
            Library.ActiveDialog = nil
            local CloseTween = TweenService:Create(DialogScale, Library.TweenInfo, { Scale = 0.95 })
            TweenService:Create(DialogOverlay, Library.TweenInfo, { BackgroundTransparency = 1 }):Play()
            CloseTween:Play()
            
            task.delay(Library.TweenInfo.Time, function()
                DialogOverlay:Destroy()
            end)
            Library.Dialogues[Idx] = nil
        end

        DialogOverlay.MouseButton1Click:Connect(function()
            if Info.OutsideClickDismiss then
                Dialog:Dismiss()
            end
        end)

        function Dialog:RemoveFooterButton(ButtonIdx)
            if FooterButtonsList[ButtonIdx] then
                FooterButtonsList[ButtonIdx].Container:Destroy()
                FooterButtonsList[ButtonIdx] = nil
            end
        end

        function Dialog:SetButtonDisabled(ButtonIdx, Disabled)
            if FooterButtonsList[ButtonIdx] and type(FooterButtonsList[ButtonIdx].SetDisabled) == "function" then
                FooterButtonsList[ButtonIdx]:SetDisabled(Disabled)
            end
        end

        function Dialog:SetButtonOrder(ButtonIdx, Order)
            if FooterButtonsList[ButtonIdx] and FooterButtonsList[ButtonIdx].Container then
                FooterButtonsList[ButtonIdx].Container.LayoutOrder = Order
            end
        end

        function Dialog:AddFooterButton(ButtonIdx, ButtonInfo)
            Dialog:RemoveFooterButton(ButtonIdx)

            local WaitTime = ButtonInfo.WaitTime or 0

            local ButtonContainer = New("Frame", {
                BackgroundTransparency = 1,
                Size = UDim2.fromOffset(0, 26),
                LayoutOrder = ButtonInfo.Order or 0,
                ZIndex = 9002,
                Parent = ButtonsHolder,
            })
            
            local BtnColor = "MainColor"
            local BtnOutline = "OutlineColor"
            local Variant = ButtonInfo.Variant or "Primary"
            
            if Variant == "Primary" then
                BtnColor = "FontColor"
                BtnOutline = "FontColor"
            elseif Variant == "Secondary" then
                BtnColor = "MainColor"
                BtnOutline = "OutlineColor"
            elseif Variant == "Destructive" then
                BtnColor = Color3.fromRGB(220, 38, 38)
                BtnOutline = Color3.fromRGB(220, 38, 38)
            elseif Variant == "Ghost" then
                BtnColor = "BackgroundColor"
                BtnOutline = "BackgroundColor"
            end

            local TextBtn = New("TextButton", {
                BackgroundColor3 = BtnColor,
                BorderColor3 = BtnOutline,
                BackgroundTransparency = WaitTime > 0 and 0.5 or 0,
                Size = UDim2.fromOffset(0, 26),
                Text = "",
                AutoButtonColor = false,
                ZIndex = 9002,
                Parent = ButtonContainer,
            })
            Library:AddOutline(TextBtn)
            New("UICorner", { CornerRadius = UDim.new(0, Library.CornerRadius), Parent = TextBtn })

            local _BtnPadding = New("UIPadding", {
                PaddingLeft = UDim.new(0, 15),
                PaddingRight = UDim.new(0, 15),
                Parent = TextBtn,
            })

            local TextColor = Library.Scheme.FontColor
            if Variant == "Primary" then
                TextColor = Library.Scheme.BackgroundColor
            elseif Variant == "Destructive" then
                TextColor = Color3.new(1, 1, 1)
            end
            
            local BtnLabel = New("TextLabel", {
                BackgroundTransparency = 1,
                Size = UDim2.fromScale(1, 1),
                Text = ButtonInfo.Title or ButtonIdx,
                TextColor3 = TextColor,
                TextTransparency = WaitTime > 0 and 0.5 or 0,
                TextSize = 14,
                ZIndex = 9002,
                Parent = TextBtn,
            })
            
            local LabelX, _ = Library:GetTextBounds(BtnLabel.Text, Library.Scheme.Font, 14, 250)
            ButtonContainer.Size = UDim2.fromOffset(LabelX + 30, 26)
            TextBtn.Size = UDim2.fromOffset(LabelX + 30, 26)

            local ProgressBar
            if WaitTime > 0 then
                ProgressBar = New("Frame", {
                    BackgroundColor3 = "AccentColor",
                    BorderSizePixel = 0,
                    Position = UDim2.new(0, 0, 1, -2),
                    Size = UDim2.new(0, 0, 0, 2),
                    ZIndex = 2,
                    Parent = TextBtn,
                })
                New("UICorner", { CornerRadius = UDim.new(0, Library.CornerRadius), Parent = ProgressBar })
            end

            local IsActive = WaitTime <= 0

            local ButtonWrap = {
                Container = ButtonContainer,
                SetDisabled = function(self, Disabled)
                    IsActive = not Disabled
                    if Disabled then
                        TweenService:Create(TextBtn, Library.TweenInfo, { BackgroundTransparency = 0.5 }):Play()
                        TweenService:Create(BtnLabel, Library.TweenInfo, { TextTransparency = 0.5 }):Play()
                    else
                        TweenService:Create(TextBtn, Library.TweenInfo, { BackgroundTransparency = 0 }):Play()
                        TweenService:Create(BtnLabel, Library.TweenInfo, { TextTransparency = 0 }):Play()
                    end
                end
            }

            local ActiveColor = typeof(BtnColor) == "Color3" and BtnColor or Library.Scheme[BtnColor]
            local HoverColor = Variant == "Ghost" and Library.Scheme.MainColor or Library:GetBetterColor(ActiveColor, 10)

            TextBtn.MouseEnter:Connect(function()
                if not IsActive then return end
                TweenService:Create(TextBtn, Library.TweenInfo, {
                    BackgroundColor3 = HoverColor
                }):Play()
            end)
            TextBtn.MouseLeave:Connect(function()
                if not IsActive then return end
                TweenService:Create(TextBtn, Library.TweenInfo, {
                    BackgroundColor3 = ActiveColor
                }):Play()
            end)

            TextBtn.MouseButton1Click:Connect(function()
                if not IsActive then return end
                if ButtonInfo.Callback then
                    ButtonInfo.Callback(Dialog)
                end
                if Info.AutoDismiss then
                    Dialog:Dismiss()
                end
            end)

            if WaitTime > 0 then
                TweenService:Create(ProgressBar, TweenInfo.new(WaitTime, Enum.EasingStyle.Linear), {
                    Size = UDim2.new(1, 0, 0, 2)
                }):Play()
                
                task.delay(WaitTime, function()
                    ButtonWrap:SetDisabled(false)
                    if ProgressBar then
                        TweenService:Create(ProgressBar, Library.TweenInfo, {
                            BackgroundTransparency = 1
                        }):Play()
                    end
                end)
            end

            FooterButtonsList[ButtonIdx] = ButtonWrap
        end

        for BIdx, BInfo in Info.FooterButtons do
            if type(BIdx) == "number" and BInfo.Id then BIdx = BInfo.Id end
            Dialog:AddFooterButton(BIdx, BInfo)
        end

        setmetatable(Dialog, BaseGroupbox)
        Library.Dialogues[Idx] = Dialog

        Dialog:Resize()
        
        Library.ActiveDialog = Dialog
        return Dialog
    end

    function Library:Toggle(Value: boolean?)
        if typeof(Value) == "boolean" then
            Library.Toggled = Value
        else
            Library.Toggled = not Library.Toggled
        end

        WindowToggleToken += 1
        local ToggleToken = WindowToggleToken
        local TargetPosition = MainFrame.Position
        local TargetScale = Library.DPIScale
        local HiddenPosition = TargetPosition + UDim2.fromOffset(0, 10)
        local ClosedScale = math.max(TargetScale * 0.975, 0.7)
        local OpenTweenInfo = TweenInfo.new(0.24, Enum.EasingStyle.Quint, Enum.EasingDirection.Out)
        local CloseTweenInfo = TweenInfo.new(0.18, Enum.EasingStyle.Quart, Enum.EasingDirection.Out)

        if WindowInfo.UnlockMouseWhileOpen then
            ModalElement.Modal = Library.Toggled
        end

        StopTween(WindowPositionTween)
        StopTween(WindowScaleTween)

        if Library.Toggled then
            MainFrame.Visible = true
            MainFrame.Position = HiddenPosition
            MainScale.Scale = ClosedScale
            SetWindowGlowTransparency(0.24)
            if WindowIconGlow then
                WindowIconGlow.Size = UDim2.fromOffset(40, 40)
            end

            WindowPositionTween = TweenService:Create(MainFrame, OpenTweenInfo, {
                Position = TargetPosition,
            })
            WindowScaleTween = TweenService:Create(MainScale, OpenTweenInfo, {
                Scale = TargetScale,
            })
            WindowPositionTween:Play()
            WindowScaleTween:Play()
            TweenWindowGlow(UDim2.fromOffset(32, 32), 0.68, TweenInfo.new(0.3, Enum.EasingStyle.Quart, Enum.EasingDirection.Out))
        else
            WindowPositionTween = TweenService:Create(MainFrame, CloseTweenInfo, {
                Position = HiddenPosition,
            })
            WindowScaleTween = TweenService:Create(MainScale, CloseTweenInfo, {
                Scale = ClosedScale,
            })
            WindowPositionTween:Play()
            WindowScaleTween:Play()
            TweenWindowGlow(UDim2.fromOffset(24, 24), 0.86, TweenInfo.new(0.18, Enum.EasingStyle.Quad, Enum.EasingDirection.Out))
            task.delay(CloseTweenInfo.Time, function()
                if Library.Unloaded or ToggleToken ~= WindowToggleToken or Library.Toggled then
                    return
                end

                MainFrame.Visible = false
                MainFrame.Position = TargetPosition
                MainScale.Scale = TargetScale
                if WindowIconGlow then
                    WindowIconGlow.Size = UDim2.fromOffset(32, 32)
                end
                SetWindowGlowTransparency(0.68)
            end)
        end

        if Library.Toggled and not Library.IsMobile then
            local OldMouseIconEnabled = UserInputService.MouseIconEnabled
            pcall(function()
                RunService:UnbindFromRenderStep("ShowCursor")
            end)
            RunService:BindToRenderStep("ShowCursor", Enum.RenderPriority.Last.Value, function()
                UserInputService.MouseIconEnabled = not Library.ShowCustomCursor

                Cursor.Position = UDim2.fromOffset(Mouse.X, Mouse.Y)
                Cursor.Visible = Library.ShowCustomCursor

                if not (Library.Toggled and ScreenGui and ScreenGui.Parent) then
                    UserInputService.MouseIconEnabled = OldMouseIconEnabled
                    Cursor.Visible = false
                    RunService:UnbindFromRenderStep("ShowCursor")
                end
            end)
        elseif not Library.Toggled then
            TooltipLabel.Visible = false

            for _, Option in Library.Options do
                if Option.Type == "ColorPicker" then
                    Option.ColorMenu:Close()
                    Option.ContextMenu:Close()
                elseif Option.Type == "Dropdown" or Option.Type == "KeyPicker" then
                    Option.Menu:Close()
                end
            end
        end
    end

    if WindowInfo.EnableSidebarResize then
        local Threshold = (WindowInfo.MinSidebarWidth + WindowInfo.SidebarCompactWidth) * WindowInfo.SidebarCollapseThreshold
        local StartPos, StartWidth
        local Dragging = false
        local Changed

        local SidebarGrabber = New("TextButton", {
            AnchorPoint = Vector2.new(0.5, 0),
            BackgroundTransparency = 1,
            Position = UDim2.fromScale(0.5, 0),
            Size = UDim2.new(0, 8, 1, 0),
            Text = "",
            Parent = DividerLine,
        })
        SidebarGrabber.MouseEnter:Connect(function()
            TweenService:Create(DividerLine, Library.TweenInfo, {
                BackgroundColor3 = Library:GetLighterColor(Library.Scheme.OutlineColor),
            }):Play()
        end)
        SidebarGrabber.MouseLeave:Connect(function()
            if Dragging then
                return
            end
            TweenService:Create(DividerLine, Library.TweenInfo, {
                BackgroundColor3 = Library.Scheme.OutlineColor,
            }):Play()
        end)

        SidebarGrabber.InputBegan:Connect(function(Input: InputObject)
            if not IsClickInput(Input) then
                return
            end

            Library.CantDragForced = true

            StartPos = Input.Position
            StartWidth = Window:GetSidebarWidth()
            Dragging = true

            Changed = Input.Changed:Connect(function()
                if Input.UserInputState ~= Enum.UserInputState.End then
                    return
                end

                Library.CantDragForced = false
                TweenService:Create(DividerLine, Library.TweenInfo, {
                    BackgroundColor3 = Library.Scheme.OutlineColor,
                }):Play()

                Dragging = false
                if Changed and Changed.Connected then
                    Changed:Disconnect()
                    Changed = nil
                end
            end)
        end)

        Library:GiveSignal(UserInputService.InputChanged:Connect(function(Input: InputObject)
            if not Library.Toggled or not (ScreenGui and ScreenGui.Parent) then
                Dragging = false
                if Changed and Changed.Connected then
                    Changed:Disconnect()
                    Changed = nil
                end

                return
            end

            if Dragging and IsHoverInput(Input) then
                local Delta = Input.Position - StartPos
                local Width = StartWidth + Delta.X

                if WindowInfo.DisableCompactingSnap then
                    Window:SetSidebarWidth(Width)
                    return
                end

                if Width > Threshold then
                    Window:SetSidebarWidth(math.max(Width, WindowInfo.MinSidebarWidth))
                else
                    Window:SetSidebarWidth(WindowInfo.SidebarCompactWidth)
                end
            end
        end))
    end
    if WindowInfo.EnableCompacting then
        if WindowInfo.SidebarCompacted then
            Window:SetSidebarWidth(WindowInfo.SidebarCompactWidth, "instant")
        else
            ApplyCompact("instant")
        end
    end
    if typeof(WindowInfo.DPIScale) == "number" then
        Library:SetDPIScale(WindowInfo.DPIScale)
    end
    if typeof(WindowInfo.UITransparency) == "number" then
        Window:SetUiTransparency(WindowInfo.UITransparency)
    end
    if typeof(WindowInfo.FooterAvatar) == "string" and WindowInfo.FooterAvatar ~= "" then
        Window:SetFooterAvatar(WindowInfo.FooterAvatar)
    end
    if typeof(WindowInfo.FooterBackgroundImage) == "string" and WindowInfo.FooterBackgroundImage ~= "" then
        Window:SetFooterBackgroundImage(WindowInfo.FooterBackgroundImage)
    end
    if typeof(WindowInfo.FooterBackgroundTransparency) == "number" then
        Window:SetFooterBackgroundTransparency(WindowInfo.FooterBackgroundTransparency)
    end
    if WindowInfo.AutoShow then
        task.spawn(Library.Toggle)
    end

    if Library.IsMobile then
        local ToggleButton = Library:AddDraggableButton("Toggle", function()
            Library:Toggle()
        end, true)

        local LockButton = Library:AddDraggableButton("Lock", function(self)
            Library.CantDragForced = not Library.CantDragForced
            self:SetText(Library.CantDragForced and "Unlock" or "Lock")
        end, true)

        if WindowInfo.MobileButtonsSide == "Right" then
            ToggleButton.Button.Position = UDim2.new(1, -6, 0, 6)
            ToggleButton.Button.AnchorPoint = Vector2.new(1, 0)

            LockButton.Button.Position = UDim2.new(1, -6, 0, 46)
            LockButton.Button.AnchorPoint = Vector2.new(1, 0)
        else
            LockButton.Button.Position = UDim2.fromOffset(6, 46)
        end
    end

    --// Execution \\--
    if SearchBox then
        SearchBox:GetPropertyChangedSignal("Text"):Connect(function()
            Library:UpdateSearch(SearchBox.Text)
        end)
    end

    Library:GiveSignal(UserInputService.InputBegan:Connect(function(Input: InputObject)
        if Library.Unloaded then
            return
        end

        if UserInputService:GetFocusedTextBox() then
            return
        end

        if
            (
                typeof(Library.ToggleKeybind) == "table"
                and Library.ToggleKeybind.Type == "KeyPicker"
                and Input.KeyCode.Name == Library.ToggleKeybind.Value
            ) or Input.KeyCode == Library.ToggleKeybind
        then
            Library.Toggle()
        end
    end))

    Library:GiveSignal(UserInputService.WindowFocused:Connect(function()
        Library.IsRobloxFocused = true
    end))
    Library:GiveSignal(UserInputService.WindowFocusReleased:Connect(function()
        Library.IsRobloxFocused = false
    end))

    if WindowInfo.EnableKojoCore ~= false and AttachKojoCoreToWindow then
        local ok, err = pcall(AttachKojoCoreToWindow, Window, WindowInfo)
        if not ok then
            warn("[Kojo] Failed to mount built-in dashboard/settings: " .. tostring(err))
        end
    end

    return Window
end

local function OnPlayerChange()
    if Library.Unloaded then
        return
    end

    local PlayerList, ExcludedPlayerList = GetPlayers(), GetPlayers(true)
    for _, Dropdown in Options do
        if Dropdown.Type == "Dropdown" and Dropdown.SpecialType == "Player" then
            Dropdown:SetValues(Dropdown.ExcludeLocalPlayer and ExcludedPlayerList or PlayerList)
        end
    end
end

local function OnTeamChange()
    if Library.Unloaded then
        return
    end

    local TeamList = GetTeams()
    for _, Dropdown in Options do
        if Dropdown.Type == "Dropdown" and Dropdown.SpecialType == "Team" then
            Dropdown:SetValues(TeamList)
        end
    end
end

function Library:CreateAdvancedNametag(Info)
    Info = Info or {}

    local Parent = Info.Parent
    if not Parent then
        Parent = LocalPlayer and LocalPlayer:FindFirstChildOfClass("PlayerGui")
    end
    if not Parent then
        Parent = Library.ScreenGui or gethui()
    end

    local Adornee = Info.Adornee
    local Size = Info.Size or UDim2.fromOffset(238, 56)
    local Accent = Info.AccentColor or Library:GetUiColor("AccentFill")
    local Secondary = Info.SecondaryTextColor or Color3.fromRGB(121, 129, 145)
    local BackgroundColor = Info.BackgroundColor or Color3.fromRGB(238, 243, 252)
    local StrokeColor = Info.StrokeColor or Accent:Lerp(Color3.new(1, 1, 1), 0.3)
    local BackgroundImage = ResolveImageSource(tostring(Info.BackgroundImage or ""))
    local AvatarImage = ResolveImageSource(tostring(Info.Avatar or ""))
    local LogoSource = ResolveImageSource(tostring(Info.Logo or Library.KojoIcons["kojo-logo"]))
    local BaseWidth = Size.X.Offset > 0 and Size.X.Offset or 238
    local BaseHeight = Size.Y.Offset > 0 and Size.Y.Offset or 56
    local DynamicScale = Info.DynamicScale ~= false
    local MinScale = tonumber(Info.MinScale) or 0.72
    local MaxScale = tonumber(Info.MaxScale) or 0.88
    local ReferenceDistance = tonumber(Info.ReferenceDistance) or 36
    local CurrentScale = 1

    local Gui = New("BillboardGui", {
        Name = Info.Name or "KojoAdvancedNametag",
        Size = Size,
        StudsOffset = Info.StudsOffset or Vector3.new(0, 3.2, 0),
        AlwaysOnTop = Info.AlwaysOnTop ~= false,
        MaxDistance = Info.MaxDistance or 120,
        LightInfluence = 0,
        Adornee = Adornee,
        Parent = Parent,
    })

    local Card = New("Frame", {
        BackgroundColor3 = BackgroundColor,
        BorderSizePixel = 0,
        ClipsDescendants = true,
        Size = UDim2.fromScale(1, 1),
        Parent = Gui,
    })
    New("UICorner", {
        CornerRadius = UDim.new(0, 18),
        Parent = Card,
    })
    local CardStroke = New("UIStroke", {
        Color = StrokeColor,
        Transparency = 0.1,
        Thickness = 1.4,
        Parent = Card,
    })

    local Background = New("ImageLabel", {
        Name = "Background",
        BackgroundTransparency = 1,
        Image = BackgroundImage,
        ImageTransparency = BackgroundImage == "" and 1 or math.clamp(tonumber(Info.BackgroundTransparency) or 0.16, 0, 1),
        ScaleType = Enum.ScaleType.Crop,
        Size = UDim2.fromScale(1, 1),
        Parent = Card,
    })
    New("UICorner", {
        CornerRadius = UDim.new(0, 18),
        Parent = Background,
    })
    AttachImageLoadFallback(Background, BackgroundImage)

    local Glow = New("Frame", {
        BackgroundColor3 = Accent,
        BackgroundTransparency = 0.9,
        BorderSizePixel = 0,
        Position = UDim2.new(0, -6, 0.5, -15),
        Size = UDim2.fromOffset(54, 30),
        Parent = Card,
    })
    New("UICorner", {
        CornerRadius = UDim.new(1, 0),
        Parent = Glow,
    })

    local AvatarPlate = New("Frame", {
        BackgroundColor3 = Color3.fromRGB(255, 255, 255),
        BackgroundTransparency = 0.02,
        Position = UDim2.new(0, 11, 0.5, -18),
        Size = UDim2.fromOffset(36, 36),
        Parent = Card,
    })
    New("UICorner", {
        CornerRadius = UDim.new(1, 0),
        Parent = AvatarPlate,
    })
    local AvatarPlateStroke = New("UIStroke", {
        Color = Color3.fromRGB(255, 255, 255),
        Transparency = 0.08,
        Thickness = 1,
        Parent = AvatarPlate,
    })
    local AvatarClip = New("Frame", {
        BackgroundTransparency = 1,
        ClipsDescendants = true,
        Position = UDim2.fromOffset(2, 2),
        Size = UDim2.new(1, -4, 1, -4),
        Parent = AvatarPlate,
    })
    New("UICorner", {
        CornerRadius = UDim.new(1, 0),
        Parent = AvatarClip,
    })
    local Avatar = New("ImageLabel", {
        BackgroundTransparency = 1,
        Image = AvatarImage,
        Position = UDim2.fromOffset(0, 0),
        ScaleType = Enum.ScaleType.Crop,
        Size = UDim2.new(1, 0, 1, 0),
        Parent = AvatarClip,
    })
    AttachImageLoadFallback(Avatar, AvatarImage)

    local NameLabel = New("TextLabel", {
        BackgroundTransparency = 1,
        FontFace = Library:GetWeightedFont(Enum.FontWeight.SemiBold),
        Position = UDim2.new(0, 58, 0, 7),
        Size = UDim2.new(1, -66, 0, 18),
        Text = tostring(Info.Title or "Kojo"),
        TextColor3 = Info.TextColor or Color3.fromRGB(57, 64, 79),
        TextSize = 16,
        TextTruncate = Enum.TextTruncate.AtEnd,
        TextXAlignment = Enum.TextXAlignment.Left,
        TextYAlignment = Enum.TextYAlignment.Center,
        Parent = Card,
    })

    local BrandIcon = New("ImageLabel", {
        BackgroundTransparency = 1,
        Image = LogoSource,
        Position = UDim2.new(0, 58, 1, -19),
        Size = UDim2.fromOffset(11, 11),
        ImageColor3 = Accent,
        Parent = Card,
    })
    AttachImageLoadFallback(BrandIcon, LogoSource)

    local BrandLabel = New("TextLabel", {
        BackgroundTransparency = 1,
        FontFace = Library:GetWeightedFont(Enum.FontWeight.Bold),
        Position = UDim2.new(0, 74, 1, -21),
        Size = UDim2.fromOffset(40, 14),
        Text = tostring(Info.BrandText or "KOJO"),
        TextColor3 = Accent,
        TextSize = 9,
        TextXAlignment = Enum.TextXAlignment.Left,
        TextYAlignment = Enum.TextYAlignment.Center,
        Parent = Card,
    })

    local SubtitleLabel = New("TextLabel", {
        BackgroundTransparency = 1,
        FontFace = Library:GetWeightedFont(Enum.FontWeight.SemiBold),
        Position = UDim2.new(0, 122, 1, -21),
        Size = UDim2.new(1, -130, 0, 14),
        Text = tostring(Info.Subtitle or "Freemium"),
        TextColor3 = Secondary:Lerp(Color3.fromRGB(86, 92, 108), 0.35),
        TextSize = 10,
        TextTruncate = Enum.TextTruncate.AtEnd,
        TextXAlignment = Enum.TextXAlignment.Left,
        TextYAlignment = Enum.TextYAlignment.Center,
        Parent = Card,
    })

    local Controller = {
        Gui = Gui,
        Card = Card,
        Background = Background,
        AvatarPlate = AvatarPlate,
        AvatarPlateStroke = AvatarPlateStroke,
        AvatarClip = AvatarClip,
        Avatar = Avatar,
        NameLabel = NameLabel,
        BrandIcon = BrandIcon,
        BrandLabel = BrandLabel,
        SubtitleLabel = SubtitleLabel,
        CardStroke = CardStroke,
        Glow = Glow,
    }

    local function GetAdorneePosition(CurrentAdornee)
        if typeof(CurrentAdornee) ~= "Instance" then
            return nil
        end

        if CurrentAdornee:IsA("Attachment") then
            return CurrentAdornee.WorldPosition
        end

        if CurrentAdornee:IsA("BasePart") then
            return CurrentAdornee.Position
        end

        return nil
    end

    local function UpdateScale()
        if not DynamicScale then
            Gui.Size = UDim2.fromOffset(BaseWidth, BaseHeight)
            return
        end

        local Camera = workspace.CurrentCamera
        local AdorneePosition = GetAdorneePosition(Gui.Adornee)
        if not Camera or not AdorneePosition then
            Gui.Size = UDim2.fromOffset(BaseWidth, BaseHeight)
            return
        end

        local Distance = (Camera.CFrame.Position - AdorneePosition).Magnitude
        local Scale = math.clamp((ReferenceDistance / math.max(Distance, 1)) ^ 0.72, MinScale, MaxScale)
        if math.abs(Scale - CurrentScale) < 0.01 then
            return
        end

        CurrentScale = Scale
        Gui.Size = UDim2.fromOffset(math.floor(BaseWidth * Scale), math.floor(BaseHeight * Scale))
    end

    local ScaleConnection = RunService.RenderStepped:Connect(UpdateScale)
    UpdateScale()

    function Controller:SetVisible(Visible)
        Gui.Enabled = Visible == true
    end

    function Controller:SetAdornee(NewAdornee)
        Gui.Adornee = NewAdornee
        UpdateScale()
    end

    function Controller:SetTitle(Text)
        NameLabel.Text = tostring(Text or "")
    end

    function Controller:SetSubtitle(Text)
        SubtitleLabel.Text = tostring(Text or "")
    end

    function Controller:SetBrandText(Text)
        BrandLabel.Text = tostring(Text or "")
    end

    function Controller:SetAvatar(Image)
        local Resolved = ResolveImageSource(tostring(Image or ""))
        Avatar.Image = Resolved
        Avatar.ImageTransparency = Resolved == "" and 1 or 0
        AttachImageLoadFallback(Avatar, Resolved)
    end

    function Controller:SetBackgroundImage(Image)
        local Resolved = ResolveImageSource(tostring(Image or ""))
        Background.Image = Resolved
        Background.ImageTransparency = Resolved == "" and 1 or math.clamp(tonumber(Info.BackgroundTransparency) or 0.16, 0, 1)
        AttachImageLoadFallback(Background, Resolved)
    end

    function Controller:SetBackgroundTransparency(Transparency)
        Info.BackgroundTransparency = Transparency
        Background.ImageTransparency = Background.Image == "" and 1 or math.clamp(tonumber(Transparency) or 0.16, 0, 1)
    end

    function Controller:SetAccent(Color)
        Accent = Color or Accent
        CardStroke.Color = Accent:Lerp(Color3.new(1, 1, 1), 0.3)
        Glow.BackgroundColor3 = Accent
        BrandIcon.ImageColor3 = Accent
        BrandLabel.TextColor3 = Accent
    end

    function Controller:Destroy()
        if ScaleConnection then
            ScaleConnection:Disconnect()
            ScaleConnection = nil
        end
        Gui:Destroy()
    end

    return Controller
end

AttachKojoCoreToWindow = function(Window, WindowInfo)
    if not Window or Window._KojoCoreMounted then
        return Window and Window.KojoCore or nil
    end

    Library._KojoMountCounter = (Library._KojoMountCounter or 0) + 1
    local Prefix = "KojoCore_" .. tostring(Library._KojoMountCounter)
    local Env = getgenv and getgenv() or _G
    local ApplyingProfile = false
    local HeadNametag = nil
    local CountdownStartedAt = os.clock()
    local CountdownBase = nil
    local Preview = nil
    local updateHeadNametag = nil

    local function getBridge()
        local Bridge = rawget(Env, "KOJO_SOCIAL")
        if type(Bridge) ~= "table" then
            Bridge = rawget(_G, "KOJO_SOCIAL")
        end
        return type(Bridge) == "table" and Bridge or nil
    end

    local function getEnvValue(Key, Fallback)
        local Value = rawget(Env, Key)
        if Value == nil then
            Value = rawget(_G, Key)
        end
        if Value == nil then
            return Fallback
        end
        return Value
    end

    local function setEnvValue(Key, Value)
        pcall(function()
            rawset(_G, Key, Value)
        end)
        pcall(function()
            if getgenv then
                rawset(getgenv(), Key, Value)
            end
        end)
    end

    local function notify(Title, Description)
        Library:Notify({
            Title = Title,
            Description = Description,
            Time = 3,
        })
    end

    local function getScalePercent()
        local RawScale = tonumber(Library.DPIScale) or 1
        return math.clamp(math.floor((RawScale * 100) + 0.5), 75, 125)
    end

    local function styleDashboardButton(Button, Style)
        local BackgroundColor = (Style and Style.BackgroundColor) or Color3.fromRGB(24, 27, 34)
        local StrokeColor = (Style and Style.StrokeColor) or BackgroundColor:Lerp(Color3.fromRGB(255, 255, 255), 0.18)
        local TextColor = (Style and Style.TextColor) or Color3.fromRGB(255, 255, 255)
        local HasIcon = Style and Style.Icon

        Button.Base.AutoButtonColor = false
        Button.Base.BackgroundTransparency = 0
        Button.Base.BackgroundColor3 = BackgroundColor
        Button.Base.TextColor3 = TextColor
        Button.Base.Text = ""
        Button.Base.TextTransparency = 1
        Button.Base.FontFace = Font.fromEnum(LEGACY_TEXT_FONT_BOLD)
        Button.Base.TextSize = 13
        Button.Stroke.Color = StrokeColor
        Button.Stroke.Transparency = 0.05

        for _, Child in ipairs(Button.Base:GetChildren()) do
            if
                Child.Name == "KojoButtonPadding"
                or Child.Name == "KojoButtonIcon"
                or Child.Name == "KojoButtonGlow"
                or Child.Name == "KojoButtonGradient"
                or Child.Name == "KojoButtonLabel"
            then
                Child:Destroy()
            end
        end

        local Label = Instance.new("TextLabel")
        Label.Name = "KojoButtonLabel"
        Label.BackgroundTransparency = 1
        Label.AnchorPoint = Vector2.new(0, 0.5)
        Label.Position = HasIcon and UDim2.new(0, 28, 0.5, 0) or UDim2.new(0, 0, 0.5, 0)
        Label.Size = HasIcon and UDim2.new(1, -36, 1, 0) or UDim2.new(1, -12, 1, 0)
        Label.FontFace = Font.fromEnum(LEGACY_TEXT_FONT_BOLD)
        Label.Text = Button.Text or ""
        Label.TextColor3 = TextColor
        Label.TextSize = 13
        Label.TextXAlignment = HasIcon and Enum.TextXAlignment.Left or Enum.TextXAlignment.Center
        Label.TextYAlignment = Enum.TextYAlignment.Center
        Label.ZIndex = Button.Base.ZIndex + 1
        Label.Parent = Button.Base

        local Gradient = Instance.new("UIGradient")
        Gradient.Name = "KojoButtonGradient"
        Gradient.Color = (Style and Style.Gradient) or ColorSequence.new({
            ColorSequenceKeypoint.new(0, BackgroundColor),
            ColorSequenceKeypoint.new(1, BackgroundColor:Lerp(Color3.fromRGB(255, 255, 255), 0.08)),
        })
        Gradient.Rotation = (Style and Style.Rotation) or 0
        Gradient.Parent = Button.Base

        if Style and Style.Icon then
            local ParsedIcon = Library:GetCustomIcon(Style.Icon)
            if ParsedIcon then
                local Glow = Instance.new("Frame")
                Glow.Name = "KojoButtonGlow"
                Glow.AnchorPoint = Vector2.new(0, 0.5)
                Glow.BackgroundColor3 = Style.IconGlowColor or StrokeColor
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

    local function applyCleanDashboardLabel(Label, Weight, Color)
        if not Label or not Label.TextLabel then
            return
        end

        local TextLabel = Label.TextLabel
        TextLabel.FontFace = Library:GetWeightedFont(Weight or Enum.FontWeight.Medium)
        TextLabel.TextSize = 14
        TextLabel.TextColor3 = Color or Color3.fromRGB(214, 219, 230)
        TextLabel.TextWrapped = false
        TextLabel.TextStrokeTransparency = 1
    end

    local function trim(Value)
        return tostring(Value or ""):match("^%s*(.-)%s*$")
    end

    local function normalizeAsset(Value)
        local Text = trim(Value)
        if Text == "" then
            return ""
        end

        local Digits = Text:match("(%d+)")
        if Digits then
            return "rbxassetid://" .. Digits
        end

        if Text:find("rbxassetid://", 1, true) == 1 or Text:find("rbxthumb://", 1, true) == 1 then
            return Text
        end

        return Text
    end

    local function resolveBackgroundDisplayAsset(Value)
        local Normalized = normalizeAsset(Value)
        local AssetId = Normalized:match("(%d+)")
        if AssetId then
            return string.format("rbxthumb://type=Asset&id=%s&w=768&h=432", AssetId)
        end
        return Normalized
    end

    local function maskKey(Value)
        local Text = tostring(Value or "Unavailable")
        if #Text <= 8 then
            return Text
        end
        return Text:sub(1, 4) .. string.rep("*", math.max(0, #Text - 8)) .. Text:sub(-4)
    end

    local function formatDuration(Seconds)
        if Seconds == nil then
            return "Lifetime"
        end

        Seconds = math.max(0, math.floor(tonumber(Seconds) or 0))
        if Seconds >= 315360000 then
            return "Lifetime"
        end

        local Days = math.floor(Seconds / 86400)
        local Hours = math.floor((Seconds % 86400) / 3600)
        local Minutes = math.floor((Seconds % 3600) / 60)
        local RemainingSeconds = Seconds % 60

        if Days > 0 then
            return string.format("%dd %02dh %02dm", Days, Hours, Minutes)
        end
        if Hours > 0 then
            return string.format("%dh %02dm %02ds", Hours, Minutes, RemainingSeconds)
        end
        if Minutes > 0 then
            return string.format("%dm %02ds", Minutes, RemainingSeconds)
        end

        return string.format("%ds", RemainingSeconds)
    end

    local function getGameDisplayName()
        local PlaceName = trim(getEnvValue("KOJO_PlaceName", ""))
        if PlaceName ~= "" then
            return PlaceName
        end

        local Success, Info = pcall(function()
            return MarketplaceService:GetProductInfo(game.PlaceId)
        end)
        if Success and type(Info) == "table" and Info.Name then
            return tostring(Info.Name)
        end

        return tostring(game.GameId)
    end

    local function makeFallbackPreviewModel()
        local Model = Instance.new("Model")
        Model.Name = Prefix .. "_PreviewFallback"

        local Part = Instance.new("Part")
        Part.Name = "Root"
        Part.Anchored = true
        Part.CanCollide = false
        Part.Size = Vector3.new(2, 3, 1)
        Part.Color = Color3.fromRGB(129, 140, 248)
        Part.Parent = Model

        local Humanoid = Instance.new("Humanoid")
        Humanoid.Parent = Model
        Model.PrimaryPart = Part

        return Model
    end

    local function makeAvatarPreviewModel()
        local Character = LocalPlayer and LocalPlayer.Character
        if not Character then
            return makeFallbackPreviewModel()
        end

        local PreviousArchivable = Character.Archivable
        Character.Archivable = true
        local Success, Clone = pcall(function()
            return Character:Clone()
        end)
        Character.Archivable = PreviousArchivable

        if not Success or not Clone then
            return makeFallbackPreviewModel()
        end

        for _, Descendant in ipairs(Clone:GetDescendants()) do
            if Descendant:IsA("Script") or Descendant:IsA("LocalScript") or Descendant:IsA("ModuleScript") then
                Descendant:Destroy()
            elseif Descendant:IsA("BasePart") then
                Descendant.Anchored = true
                Descendant.CanCollide = false
            end
        end

        Clone.Name = Prefix .. "_PreviewAvatar"
        return Clone
    end

    local function getTierValue()
        local Tier = trim(getEnvValue("KOJO_UserTier", "Freemium"))
        if Tier == "" then
            Tier = "Freemium"
        end
        return Tier
    end

    local function getTierPalette()
        local Tier = string.lower(getTierValue())
        if Tier == "premium" then
            return "premium"
        end
        if Tier == "lifetime" then
            return "lifetime"
        end
        if Tier == "vip" then
            return "vip"
        end
        return "freemium"
    end

    local function isGeneratedKojoDisplayName(Text)
        Text = trim(tostring(Text or ""))
        if Text == "" then
            return false
        end

        if Text == "Kojo User" then
            return true
        end

        return Text:match("^Kojo%-%w%w%w%w$") ~= nil
    end

    local function getRobloxDisplayName()
        if not LocalPlayer then
            return ""
        end

        local DisplayName = trim(LocalPlayer.DisplayName or "")
        if DisplayName ~= "" then
            return DisplayName
        end

        return trim(LocalPlayer.Name or "")
    end

    local function getDisplayName()
        local Text = trim(getEnvValue("KOJO_ProfileName", ""))
        if Text ~= "" and not isGeneratedKojoDisplayName(Text) then
            return Text
        end

        local Bridge = getBridge()
        if Bridge and type(Bridge.profile) == "table" then
            Text = trim(Bridge.profile.display_name or "")
            if Text ~= "" and not isGeneratedKojoDisplayName(Text) then
                return Text
            end
        end

        local RobloxDisplayName = getRobloxDisplayName()
        if RobloxDisplayName ~= "" then
            return RobloxDisplayName
        end

        if Text ~= "" then
            return Text
        end

        return "Kojo User"
    end

    local function getAvatarImage()
        local Image = normalizeAsset(getEnvValue("KOJO_ProfileAvatar", ""))
        if Image ~= "" then
            return Image
        end

        local Bridge = getBridge()
        if Bridge and type(Bridge.profile) == "table" then
            Image = normalizeAsset(Bridge.profile.script_avatar_url or Bridge.profile.avatar_url or "")
            if Image ~= "" then
                return Image
            end
        end

        if LocalPlayer then
            return string.format("rbxthumb://type=AvatarHeadShot&id=%s&w=150&h=150", tostring(LocalPlayer.UserId))
        end

        return ""
    end

    local DEFAULT_KOJO_BACKDROP_ASSET = "rbxassetid://137576635451854"

    local function getNametagBackground()
        local Value = normalizeAsset(getEnvValue("KOJO_NametagBackgroundAsset", ""))
        if Value ~= "" then
            return Value
        end

        local Bridge = getBridge()
        if Bridge and type(Bridge.profile) == "table" then
            Value = normalizeAsset(Bridge.profile.nametag_asset or "")
            if Value ~= "" then
                return Value
            end
        end

        return DEFAULT_KOJO_BACKDROP_ASSET
    end

    local function getNametagTransparency()
        local Value = tonumber(getEnvValue("KOJO_NametagTransparency", nil))
        if Value == nil then
            local Bridge = getBridge()
            if Bridge and type(Bridge.profile) == "table" then
                Value = tonumber(Bridge.profile.nametag_transparency)
            end
        end
        if Value == nil then
            return 0.28
        end
        if Value > 1 then
            Value = Value / 100
        end
        return math.clamp(Value, 0, 1)
    end

    local function getPreviewBackdrop()
        local Value = normalizeAsset(getEnvValue("KOJO_PreviewBackdropAsset", ""))
        if Value ~= "" then
            return Value
        end
        return DEFAULT_KOJO_BACKDROP_ASSET
    end

    local function getPreviewBackdropTransparency()
        local Value = tonumber(getEnvValue("KOJO_PreviewBackdropTransparency", 0))
        if Value > 1 then
            Value = Value / 100
        end
        return math.clamp(Value, 0, 1)
    end

    local function getWindowBackground()
        return normalizeAsset(getEnvValue("KOJO_WindowBackgroundAsset", ""))
    end

    local function getWindowBackgroundTransparency()
        local Value = tonumber(getEnvValue("KOJO_WindowBackgroundTransparency", WindowInfo.BackgroundImageTransparency or 0.24))
        if Value > 1 then
            Value = Value / 100
        end
        return math.clamp(Value, 0, 1)
    end

    local function isSafeModeEnabled()
        local SafeMode = WindowInfo.KojoSafeMode
        if SafeMode == nil then
            SafeMode = getEnvValue("KOJO_SafeMode", false)
        end
        return SafeMode == true
    end

    local function normalizeKojoRootPath(Root)
        if typeof(Root) ~= "string" or Root == "" then
            return nil
        end

        Root = Root:gsub("\\", "/")
        if Root:sub(-1) ~= "/" then
            Root ..= "/"
        end

        return Root
    end

    local function ensureKojoAssetFolder(FilePath)
        if not makefolder or not isfolder then
            return
        end

        local Directory = tostring(FilePath or ""):gsub("\\", "/"):match("^(.*)/[^/]+$")
        if not Directory or Directory == "" then
            return
        end

        local Traversed = ""
        for _, Segment in ipairs(Directory:split("/")) do
            if Segment ~= "" then
                Traversed = Traversed == "" and Segment or (Traversed .. "/" .. Segment)
                if not isfolder(Traversed) then
                    makefolder(Traversed)
                end
            end
        end
    end

    local function resolveKojoAsset(RelativePath)
        RelativePath = tostring(RelativePath or ""):gsub("^[/\\]+", ""):gsub("\\", "/")
        if RelativePath == "" then
            return ""
        end

        local CandidateRoots = {
            rawget(Env, "KojoObsidianRoot"),
            rawget(_G, "KojoObsidianRoot"),
            "obsidian_kojo",
            "./obsidian_kojo",
            "Kojoui",
            "./Kojoui",
        }

        for _, Root in ipairs(CandidateRoots) do
            local NormalizedRoot = normalizeKojoRootPath(Root)
            if NormalizedRoot then
                local LocalPath = NormalizedRoot .. "assets/" .. RelativePath
                if isfile and isfile(LocalPath) then
                    return ResolveImageSource(LocalPath)
                end
            end
        end

        local AssetBaseUrl = trim(getEnvValue("KOJO_ASSET_BASE_URL", "https://raw.githubusercontent.com/norr17/Kojoui/main/assets/"))
        if AssetBaseUrl ~= "" and getcustomasset and writefile and game and game.HttpGet then
            local CachePath = "Obsidian/kojo_assets/" .. RelativePath
            if not (isfile and isfile(CachePath)) then
                ensureKojoAssetFolder(CachePath)
                pcall(function()
                    writefile(CachePath, game:HttpGet(AssetBaseUrl .. RelativePath))
                end)
            end
            if isfile and isfile(CachePath) then
                return ResolveImageSource(CachePath)
            end
        end

        return ""
    end

    local BackgroundPresets = {
        None = "",
        ["Glass Sky"] = resolveKojoAsset("backdrops/sky.png"),
        ["Mint Bloom"] = resolveKojoAsset("backdrops/mint_garden.png"),
        ["Aurora Wash"] = resolveKojoAsset("backdrops/aurora.png"),
        ["Night City"] = resolveKojoAsset("backdrops/night_city.png"),
        ["Dawn Glow"] = resolveKojoAsset("backdrops/dawn_glow.png"),
    }
    local NametagBackgroundPresets = {
        None = "",
        ["Midnight Glow"] = DEFAULT_KOJO_BACKDROP_ASSET,
        ["Glass Sky"] = resolveKojoAsset("backdrops/sky.png"),
        ["Mint Bloom"] = resolveKojoAsset("backdrops/mint_garden.png"),
        ["Aurora Wash"] = resolveKojoAsset("backdrops/aurora.png"),
        ["Night City"] = resolveKojoAsset("backdrops/night_city.png"),
        ["Dawn Glow"] = resolveKojoAsset("backdrops/dawn_glow.png"),
    }
    local PreviewBackdropPresets = {
        ["Hide Backdrop"] = {
            Color = Color3.fromRGB(23, 26, 34),
            Transparency = 0,
            Image = "",
            ImageTransparency = 1,
            Gradient = false,
            Rotation = 0,
        },
        ["Midnight Glow"] = {
            Color = Color3.fromRGB(12, 20, 36),
            Transparency = 0,
            Image = DEFAULT_KOJO_BACKDROP_ASSET,
            ImageTransparency = 0,
            Gradient = false,
            Rotation = 0,
        },
        ["Studio Slate"] = {
            Color = Color3.fromRGB(59, 66, 86),
            Transparency = 0,
            Image = resolveKojoAsset("backdrops/studio_slate.png"),
            ImageTransparency = 0.04,
            Gradient = false,
            Rotation = 0,
        },
        ["Dawn Glow"] = {
            Color = Color3.fromRGB(154, 105, 119),
            Transparency = 0,
            Image = resolveKojoAsset("backdrops/dawn_glow.png"),
            ImageTransparency = 0,
            Gradient = false,
            Rotation = 0,
        },
        ["Mint Bloom"] = {
            Color = Color3.fromRGB(98, 141, 126),
            Transparency = 0,
            Image = resolveKojoAsset("backdrops/mint_garden.png"),
            ImageTransparency = 0.02,
            Gradient = false,
            Rotation = 0,
        },
        ["Blueprint"] = {
            Color = Color3.fromRGB(130, 184, 240),
            Transparency = 0,
            Image = resolveKojoAsset("backdrops/blueprint.png"),
            ImageTransparency = 0.02,
            Gradient = false,
            Rotation = 0,
        },
        ["Night City"] = {
            Color = Color3.fromRGB(52, 58, 106),
            Transparency = 0,
            Image = resolveKojoAsset("backdrops/night_city.png"),
            ImageTransparency = 0.04,
            Gradient = false,
            Rotation = 0,
        },
    }
    local BuiltInPreviewBackdropNames = {}
    local CurrentPreviewBackdropName = "Midnight Glow"

    for Name in pairs(PreviewBackdropPresets) do
        BuiltInPreviewBackdropNames[Name] = true
    end

    local function getPresetNames(Map, includeNoneFirst)
        local Names = {}
        for Name in pairs(Map) do
            if includeNoneFirst == true or Name ~= "None" then
                table.insert(Names, Name)
            end
        end
        table.sort(Names, function(a, b)
            if a == "None" then
                return true
            elseif b == "None" then
                return false
            end
            return a < b
        end)
        return Names
    end

    local function registerFlatAssetPreset(Map, Asset, BaseName, OptionIndex)
        Asset = normalizeAsset(Asset)
        if Asset == "" then
            return "None"
        end

        for ExistingName, ExistingAsset in pairs(Map) do
            if ExistingAsset == Asset then
                return ExistingName
            end
        end

        local AssetId = Asset:match("(%d+)")
        local CandidateBase = AssetId and string.format("%s %s", BaseName, AssetId) or ("Custom " .. BaseName)
        local Candidate = CandidateBase
        local Counter = 2

        while Map[Candidate] ~= nil do
            Candidate = string.format("%s %d", CandidateBase, Counter)
            Counter += 1
        end

        Map[Candidate] = Asset
        if OptionIndex and Options[OptionIndex] then
            Options[OptionIndex]:SetValues(getPresetNames(Map, true))
        end
        return Candidate
    end

    local function getPreviewBackdropPresetNames()
        return getPresetNames(PreviewBackdropPresets, false)
    end

    local function registerPreviewBackdropPreset(Asset)
        Asset = normalizeAsset(Asset)
        if Asset == "" then
            return nil
        end

        local DisplayImage = resolveBackgroundDisplayAsset(Asset)
        for ExistingName, Preset in pairs(PreviewBackdropPresets) do
            if type(Preset) == "table" and Preset.Image == DisplayImage then
                return ExistingName
            end
        end

        local AssetId = Asset:match("(%d+)")
        local CandidateBase = AssetId and ("Backdrop " .. AssetId) or "Custom Backdrop"
        local Candidate = CandidateBase
        local Counter = 2

        while PreviewBackdropPresets[Candidate] ~= nil do
            Candidate = string.format("%s %d", CandidateBase, Counter)
            Counter += 1
        end

        PreviewBackdropPresets[Candidate] = {
            Color = Color3.fromRGB(28, 31, 40),
            Transparency = 0,
            Image = DisplayImage,
            ImageTransparency = 0,
            Gradient = false,
            Rotation = 0,
            SourceAsset = Asset,
        }

        if Options[Prefix .. "_PreviewBackdropPreset"] then
            Options[Prefix .. "_PreviewBackdropPreset"]:SetValues(getPreviewBackdropPresetNames())
        end

        return Candidate
    end

    local function renamePreviewBackdropPreset(CurrentName, NewName)
        CurrentName = tostring(CurrentName or "")
        NewName = trim(NewName)

        if CurrentName == "" or NewName == "" then
            return nil
        end
        if BuiltInPreviewBackdropNames[CurrentName] then
            notify("Kojo", "Built-in backdrops cannot be renamed")
            return nil
        end
        if PreviewBackdropPresets[CurrentName] == nil then
            return nil
        end
        if PreviewBackdropPresets[NewName] ~= nil and NewName ~= CurrentName then
            notify("Kojo", "Backdrop name already exists")
            return nil
        end
        if NewName == CurrentName then
            return CurrentName
        end

        PreviewBackdropPresets[NewName] = PreviewBackdropPresets[CurrentName]
        PreviewBackdropPresets[CurrentName] = nil

        if Options[Prefix .. "_PreviewBackdropPreset"] then
            Options[Prefix .. "_PreviewBackdropPreset"]:SetValues(getPreviewBackdropPresetNames())
            Options[Prefix .. "_PreviewBackdropPreset"]:SetValue(NewName)
        end

        return NewName
    end

    local function deleteSavedKey()
        local Removed = false
        pcall(function()
            setEnvValue("KojoKey", nil)
        end)
        pcall(function()
            if isfile and isfile("kojohub/key.txt") then
                delfile("kojohub/key.txt")
                Removed = true
            end
        end)
        return Removed
    end

    local function applyFooter()
        if WindowInfo.KojoAutoFooter == false then
            return
        end

        Window:SetFooter(getDisplayName())
        Window:SetFooterAvatar(getAvatarImage())
        Window:SetFooterBackgroundImage(getNametagBackground())
        Window:SetFooterBackgroundTransparency(getNametagTransparency())
        if Window.SetFooterPalette then
            Window:SetFooterPalette(getTierPalette())
        end
    end

    local function applyWindowBackground()
        local Background = getWindowBackground()
        if Background == "" then
            Window:ClearBackgroundImage()
        else
            Window:SetBackgroundImage(resolveBackgroundDisplayAsset(Background))
        end
        Window:SetBackgroundTransparency(getWindowBackgroundTransparency())
    end

    local function applyWindowBackgroundPreset(Name)
        local Preset = BackgroundPresets[Name]
        if Preset == nil then
            return
        end

        setEnvValue("KOJO_WindowBackgroundAsset", Preset)
        applyWindowBackground()
    end

    local function applyNametagBackgroundPreset(Name)
        local Preset = NametagBackgroundPresets[Name]
        if Preset == nil then
            return
        end

        setEnvValue("KOJO_NametagBackgroundAsset", Preset)
        applyFooter()
        updateHeadNametag()
    end

    local function applyPreviewBackdropPreset(Name)
        local Preset = PreviewBackdropPresets[Name]
        if not Preview or not Preset then
            return
        end

        CurrentPreviewBackdropName = Name
        setEnvValue("KOJO_PreviewBackdropAsset", Preset.SourceAsset or "")
        Preview:SetBackgroundColor(Preset.Color or Color3.fromRGB(23, 26, 34))
        Preview:SetBackgroundTransparency(Preset.Transparency or 0)
        Preview:SetBackgroundImage(Preset.Image or "")
        Preview:SetBackgroundImageTransparency(Preset.Image and (Preset.ImageTransparency or 0) or 1)
        if Preview.SetBackgroundGradient then
            Preview:SetBackgroundGradient(Preset.Gradient or false, Preset.Rotation or 0)
        end
    end

    local DashboardTab = Window:AddTab(WindowInfo.KojoDashboardTabName or "Home", "kojo-home")
    local SettingsTab = Window:AddTab(WindowInfo.KojoSettingsTabName or "Settings", "kojo-settings")

    local DashboardGroup = DashboardTab:AddLeftGroupbox("Home")
    local UserLabel = DashboardGroup:AddLabel("User: -", true)
    local DiscordLabel = DashboardGroup:AddLabel("Discord: -", true)
    local TierLabel = DashboardGroup:AddLabel("Tier: -", true)
    local LicenseLabel = DashboardGroup:AddLabel("License Key: -", true)
    local ExpiresLabel = DashboardGroup:AddLabel("Expires In: -", true)
    local ExpiresAtLabel = DashboardGroup:AddLabel("Expires At: -", true)
    local CountdownLabel = DashboardGroup:AddLabel("Countdown: -", true)
    local ExecutionsLabel = DashboardGroup:AddLabel("Executions: -", true)
    local GameLabel = DashboardGroup:AddLabel("Game: -", true)
    applyCleanDashboardLabel(UserLabel, Enum.FontWeight.SemiBold, Color3.fromRGB(232, 236, 244))
    applyCleanDashboardLabel(DiscordLabel)
    applyCleanDashboardLabel(TierLabel)
    applyCleanDashboardLabel(LicenseLabel)
    applyCleanDashboardLabel(ExpiresLabel)
    applyCleanDashboardLabel(ExpiresAtLabel)
    applyCleanDashboardLabel(CountdownLabel, Enum.FontWeight.SemiBold, Color3.fromRGB(208, 236, 220))
    applyCleanDashboardLabel(ExecutionsLabel)
    applyCleanDashboardLabel(GameLabel)

    local AccessGroup = DashboardTab:AddLeftGroupbox("Access")
    local DiscordButton = AccessGroup:AddButton("Discord", function()
        local Url = trim(getEnvValue("KOJO_DiscordInvite", "https://discord.gg/5VrGVd7YTc"))
        if setclipboard then
            setclipboard(Url)
            notify("Kojo", "Discord link copied")
        else
            notify("Kojo", Url)
        end
    end)
    local BuyKeyButton = DiscordButton:AddButton("Buy Key", function()
        local Url = trim(getEnvValue("KOJO_Website", "https://kojohub.pro/checkpoint"))
        if setclipboard then
            setclipboard(Url)
            notify("Kojo", "Purchase link copied")
        else
            notify("Kojo", Url)
        end
    end)
    local CopyLicenseButton = AccessGroup:AddButton("Copy License", function()
        local Value = tostring(getEnvValue("KOJO_LicenseKey", "Unavailable"))
        if setclipboard then
            setclipboard(Value)
            notify("Kojo", "License copied")
        else
            notify("Kojo", Value)
        end
    end)
    local CopyGameButton = CopyLicenseButton:AddButton("Copy Game ID", function()
        if setclipboard then
            setclipboard(tostring(game.GameId))
            notify("Kojo", "Game id copied")
        else
            notify("Kojo", tostring(game.GameId))
        end
    end)
    styleDashboardButton(DiscordButton, {
        BackgroundColor = Color3.fromRGB(66, 76, 198),
        StrokeColor = Color3.fromRGB(150, 160, 240),
        TextColor = Color3.fromRGB(248, 250, 255),
        Icon = "kojo-discord",
        IconGlowColor = Color3.fromRGB(170, 184, 255),
        Gradient = ColorSequence.new({
            ColorSequenceKeypoint.new(0, Color3.fromRGB(61, 70, 186)),
            ColorSequenceKeypoint.new(0.5, Color3.fromRGB(88, 100, 224)),
            ColorSequenceKeypoint.new(1, Color3.fromRGB(53, 60, 164)),
        }),
    })
    styleDashboardButton(BuyKeyButton, {
        BackgroundColor = Color3.fromRGB(26, 58, 48),
        StrokeColor = Color3.fromRGB(126, 214, 170),
        TextColor = Color3.fromRGB(242, 255, 247),
        Icon = "kojo-buy-key",
        IconGlowColor = Color3.fromRGB(148, 232, 188),
        Gradient = ColorSequence.new({
            ColorSequenceKeypoint.new(0, Color3.fromRGB(22, 50, 41)),
            ColorSequenceKeypoint.new(0.5, Color3.fromRGB(39, 79, 66)),
            ColorSequenceKeypoint.new(1, Color3.fromRGB(18, 42, 35)),
        }),
    })
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

    local PreviewGroup = DashboardTab:AddRightGroupbox("Preview")
    Preview = PreviewGroup:AddViewport(Prefix .. "_Preview", {
        Object = makeAvatarPreviewModel(),
        Height = 500,
        BackgroundColor = Color3.fromRGB(12, 20, 36),
        BackgroundTransparency = 0,
        BackgroundImage = getPreviewBackdrop() == "" and "" or resolveBackgroundDisplayAsset(getPreviewBackdrop()),
        BackgroundImageTransparency = getPreviewBackdrop() == "" and 1 or getPreviewBackdropTransparency(),
        Interactive = not isSafeModeEnabled(),
        AutoFocus = true,
        AutoRotate = false,
        RotateSpeed = 8,
        FocusYOffset = -0.16,
        CameraDistanceMultiplier = 1.38,
    })
    local PreviewButtons = PreviewGroup:AddButton("Refocus", function()
        Preview:Focus()
    end)
    PreviewButtons:AddButton("Refresh Avatar", function()
        Preview:SetObject(makeAvatarPreviewModel(), false)
        Preview:Focus()
        if Preview.SetAutoRotate then
            Preview:SetAutoRotate(true)
        end
    end)

    local MenuGroup = SettingsTab:AddLeftGroupbox("Menu")
    local DisplayGroup = SettingsTab:AddLeftGroupbox("Display")
    local ThemeGroup = SettingsTab:AddLeftGroupbox("Theme")
    local ProfileGroup = SettingsTab:AddRightGroupbox("Profile")
    local ConfigGroup = SettingsTab:AddRightGroupbox("Configuration")
    local ThemesGroup = SettingsTab:AddRightGroupbox("Themes")
    ProfileGroup:AddLabel(getBridge() and "Connected" or "Local only", true)

    local function applyProfilePayload(Profile)
        if type(Profile) ~= "table" then
            return
        end

        ApplyingProfile = true
        if Profile.display_name and Profile.display_name ~= "" then
            setEnvValue("KOJO_ProfileName", tostring(Profile.display_name))
        end
        if Profile.script_avatar_url ~= nil then
            setEnvValue("KOJO_ProfileAvatar", normalizeAsset(Profile.script_avatar_url))
        end
        if Profile.discord_username ~= nil then
            setEnvValue("KOJO_DiscordTag", tostring(Profile.discord_username))
        end
        if Profile.visible ~= nil then
            setEnvValue("KOJO_ProfileVisible", Profile.visible == true)
        end
        if Profile.profile_id ~= nil then
            setEnvValue("KOJO_ProfileId", tostring(Profile.profile_id))
        end
        if Profile.nametag_asset ~= nil then
            local Image = normalizeAsset(Profile.nametag_asset)
            setEnvValue("KOJO_NametagBackgroundAsset", Image)
            local PresetName = registerFlatAssetPreset(NametagBackgroundPresets, Image, "Nametag", Prefix .. "_NametagBackgroundPreset")
            if Options[Prefix .. "_NametagBackgroundPreset"] then
                Options[Prefix .. "_NametagBackgroundPreset"]:SetValue(PresetName)
            end
        end
        if Profile.nametag_transparency ~= nil then
            setEnvValue("KOJO_NametagTransparency", tonumber(Profile.nametag_transparency) or 0.28)
            if Options[Prefix .. "_NametagFade"] then
                Options[Prefix .. "_NametagFade"]:SetValue(math.floor(getNametagTransparency() * 100 + 0.5))
            end
        end
        ApplyingProfile = false
        applyFooter()
        updateHeadNametag()
    end

    local function pushProfile(Changes)
        if ApplyingProfile then
            return
        end

        local Bridge = getBridge()
        if Bridge and type(Bridge.updateProfile) == "function" then
            local Ok, Response = pcall(Bridge.updateProfile, Changes)
            if Ok and type(Response) == "table" then
                applyProfilePayload(Response)
            end
        end
    end

    local function refreshRemoteProfile()
        local Bridge = getBridge()
        if Bridge and type(Bridge.refreshProfile) == "function" then
            local Ok, Response = pcall(Bridge.refreshProfile)
            if Ok and type(Response) == "table" then
                applyProfilePayload(Response)
            end
        end
    end

    updateHeadNametag = function()
        if isSafeModeEnabled() or not (Toggles[Prefix .. "_ShowHeadNametag"] and Toggles[Prefix .. "_ShowHeadNametag"].Value) then
            if HeadNametag then
                HeadNametag:Destroy()
                HeadNametag = nil
            end
            return
        end

        local Character = LocalPlayer and LocalPlayer.Character
        local Head = Character and Character:FindFirstChild("Head")
        if not Head then
            return
        end

        if not HeadNametag then
            HeadNametag = Library:CreateAdvancedNametag({
                Name = Prefix .. "_HeadNametag",
                Adornee = Head,
                Title = getDisplayName(),
                Subtitle = getTierValue(),
                Avatar = getAvatarImage(),
                BackgroundImage = getNametagBackground(),
                BackgroundTransparency = getNametagTransparency(),
                DynamicScale = false,
                MinScale = 0.78,
                MaxScale = 0.88,
                ReferenceDistance = 38,
            })
        else
            HeadNametag:SetAdornee(Head)
            HeadNametag:SetTitle(getDisplayName())
            HeadNametag:SetSubtitle(getTierValue())
            HeadNametag:SetAvatar(getAvatarImage())
            HeadNametag:SetBackgroundImage(getNametagBackground())
            HeadNametag:SetBackgroundTransparency(getNametagTransparency())
        end

        HeadNametag:SetAccent(Library:GetUiColor("AccentFill"))
        HeadNametag:SetVisible(true)
    end

    local DisplayNameInput = ProfileGroup:AddInput(Prefix .. "_DisplayName", {
        Text = "Display Name",
        Default = getDisplayName(),
        Placeholder = "Kojo display name",
        ClearTextOnFocus = false,
        Finished = true,
        Callback = function(Value)
            local Text = trim(Value)
            if Text == "" then
                return
            end
            setEnvValue("KOJO_ProfileName", Text)
            applyFooter()
            updateHeadNametag()
            pushProfile({
                display_name = Text,
            })
        end,
    })
    local AvatarInput = ProfileGroup:AddInput(Prefix .. "_ScriptAvatar", {
        Text = "Script Avatar",
        Default = getAvatarImage(),
        Placeholder = "123456789 or rbxassetid://...",
        ClearTextOnFocus = false,
        Finished = true,
        Callback = function(Value)
            local Image = normalizeAsset(Value)
            setEnvValue("KOJO_ProfileAvatar", Image)
            applyFooter()
            updateHeadNametag()
            pushProfile({
                script_avatar_url = Image,
            })
        end,
    })
    ProfileGroup:AddToggle(Prefix .. "_ShowHeadNametag", {
        Text = "Show Head Nametag",
        Default = false,
        Callback = function(Value)
            if isSafeModeEnabled() and Value then
                notify("Kojo", "Safe mode is enabled in script, head nametag stays off")
                Toggles[Prefix .. "_ShowHeadNametag"]:SetValue(false)
                return
            end
            updateHeadNametag()
        end,
    })
    ProfileGroup:AddToggle(Prefix .. "_Visible", {
        Text = "Visible in Presence",
        Default = getEnvValue("KOJO_ProfileVisible", true) ~= false,
        Callback = function(Value)
            setEnvValue("KOJO_ProfileVisible", Value)
            pushProfile({
                visible = Value,
            })
        end,
    })
    local ProfileButtons = ProfileGroup:AddButton("Refresh Profile", function()
        refreshRemoteProfile()
        if Options[Prefix .. "_DisplayName"] then
            Options[Prefix .. "_DisplayName"]:SetValue(getDisplayName())
        end
        if Options[Prefix .. "_ScriptAvatar"] then
            Options[Prefix .. "_ScriptAvatar"]:SetValue(getAvatarImage())
        end
        applyFooter()
        updateHeadNametag()
        notify("Kojo", "Profile refreshed")
    end)
    ProfileButtons:AddButton("Copy Profile ID", function()
        local Value = tostring(getEnvValue("KOJO_ProfileId", "Unavailable"))
        if setclipboard then
            setclipboard(Value)
            notify("Kojo", "Profile id copied")
        else
            notify("Kojo", Value)
        end
    end)
    MenuGroup:AddToggle(Prefix .. "_ShowKeybindFrame", {
        Text = "Show Keybind Frame",
        Default = Library.KeybindFrame and Library.KeybindFrame.Visible or false,
        Callback = function(Value)
            if Library.KeybindFrame then
                Library.KeybindFrame.Visible = Value
            end
        end,
    })
    MenuGroup:AddToggle(Prefix .. "_ShowCustomCursor", {
        Text = "Custom Cursor",
        Default = Library.ShowCustomCursor,
        Callback = function(Value)
            Library.ShowCustomCursor = Value
        end,
    })
    MenuGroup:AddDropdown(Prefix .. "_NotifySide", {
        Text = "Notification Side",
        Values = { "Left", "Right" },
        Default = Library.NotifySide or "Right",
        Callback = function(Value)
            Library:SetNotifySide(Value)
        end,
    })
    MenuGroup:AddLabel("Toggle Key")
        :AddKeyPicker(Prefix .. "_MenuKeybind", {
            Default = typeof(WindowInfo.ToggleKeybind) == "EnumItem" and WindowInfo.ToggleKeybind.Name or tostring(WindowInfo.ToggleKeybind),
            NoUI = true,
            Text = "Menu keybind",
            Callback = function()
            end,
        })
    if Options[Prefix .. "_MenuKeybind"] then
        Library.ToggleKeybind = Options[Prefix .. "_MenuKeybind"]
    end
    MenuGroup:AddButton("Enable All", function()
        for _, Toggle in pairs(Library.Toggles) do
            if typeof(Toggle) == "table" and Toggle.SetValue and Toggle.Type == "Toggle" then
                Toggle:SetValue(true)
            end
        end
        notify("Kojo", "All toggles enabled")
    end)
    MenuGroup:AddButton("Disable All", function()
        for _, Toggle in pairs(Library.Toggles) do
            if typeof(Toggle) == "table" and Toggle.SetValue and Toggle.Type == "Toggle" then
                Toggle:SetValue(false)
            end
        end
        notify("Kojo", "All toggles disabled")
    end)
    MenuGroup:AddButton("Delete Saved Key", function()
        local Removed = deleteSavedKey()
        notify("Kojo", Removed and "Saved key deleted" or "No saved key file found")
    end)
    MenuGroup:AddButton("Unload Library", function()
        Library:Unload()
    end)

    ThemeGroup:AddDropdown(Prefix .. "_WindowBackgroundPreset", {
        Text = "Window Background",
        Values = getPresetNames(BackgroundPresets, true),
        Default = "None",
        Callback = function(Value)
            applyWindowBackgroundPreset(Value)
        end,
    })
    ThemeGroup:AddDropdown(Prefix .. "_NametagBackgroundPreset", {
        Text = "Nametag Background",
        Values = getPresetNames(NametagBackgroundPresets, true),
        Default = "Midnight Glow",
        Callback = function(Value)
            applyNametagBackgroundPreset(Value)
            if not ApplyingProfile then
                pushProfile({
                    nametag_asset = NametagBackgroundPresets[Value] or "",
                })
            end
        end,
    })
    ThemeGroup:AddDropdown(Prefix .. "_PreviewBackdropPreset", {
        Text = "Avatar Backdrop",
        Values = getPreviewBackdropPresetNames(),
        Default = "Midnight Glow",
        Callback = function(Value)
            applyPreviewBackdropPreset(Value)
        end,
    })
    ThemeGroup:AddInput(Prefix .. "_WindowBackground", {
        Text = "Background Asset",
        Default = getWindowBackground(),
        Placeholder = "rbxassetid://...",
        ClearTextOnFocus = false,
        Finished = true,
        Callback = function(Value)
            local Image = normalizeAsset(Value)
            local PresetName = registerFlatAssetPreset(BackgroundPresets, Image, "Asset", Prefix .. "_WindowBackgroundPreset")
            if Options[Prefix .. "_WindowBackgroundPreset"] then
                Options[Prefix .. "_WindowBackgroundPreset"]:SetValue(PresetName)
            else
                applyWindowBackgroundPreset(PresetName)
            end
        end,
    })
    ThemeGroup:AddSlider(Prefix .. "_WindowFade", {
        Text = "Background Fade",
        Default = math.floor(getWindowBackgroundTransparency() * 100 + 0.5),
        Min = 0,
        Max = 100,
        Rounding = 0,
        Suffix = "%",
        Callback = function(Value)
            setEnvValue("KOJO_WindowBackgroundTransparency", Value)
            applyWindowBackground()
        end,
    })
    ThemeGroup:AddInput(Prefix .. "_NametagBackground", {
        Text = "Nametag Asset",
        Default = getNametagBackground(),
        Placeholder = "rbxassetid://...",
        ClearTextOnFocus = false,
        Finished = true,
        Callback = function(Value)
            local Image = normalizeAsset(Value)
            local PresetName = registerFlatAssetPreset(NametagBackgroundPresets, Image, "Nametag", Prefix .. "_NametagBackgroundPreset")
            if Options[Prefix .. "_NametagBackgroundPreset"] then
                Options[Prefix .. "_NametagBackgroundPreset"]:SetValue(PresetName)
            else
                applyNametagBackgroundPreset(PresetName)
            end
            if not ApplyingProfile then
                pushProfile({
                    nametag_asset = Image,
                })
            end
        end,
    })
    ThemeGroup:AddSlider(Prefix .. "_NametagFade", {
        Text = "Nametag Transparency",
        Default = math.floor(getNametagTransparency() * 100 + 0.5),
        Min = 0,
        Max = 100,
        Rounding = 0,
        Suffix = "%",
        Callback = function(Value)
            setEnvValue("KOJO_NametagTransparency", Value)
            applyFooter()
            updateHeadNametag()
            pushProfile({
                nametag_transparency = Value,
            })
        end,
    })
    ThemeGroup:AddInput(Prefix .. "_PreviewBackdrop", {
        Text = "Backdrop Asset",
        Default = getPreviewBackdrop(),
        Placeholder = "rbxassetid://...",
        ClearTextOnFocus = false,
        Finished = true,
        Callback = function(Value)
            local Image = normalizeAsset(Value)
            local PresetName = registerPreviewBackdropPreset(Image)
            if PresetName and Options[Prefix .. "_PreviewBackdropPreset"] then
                Options[Prefix .. "_PreviewBackdropPreset"]:SetValue(PresetName)
            end
        end,
    })
    ThemeGroup:AddInput(Prefix .. "_PreviewBackdropLabel", {
        Text = "Backdrop Rename",
        Default = "",
        Placeholder = "My favorite backdrop",
        ClearTextOnFocus = false,
        Finished = true,
        Callback = function(Value)
            local Renamed = renamePreviewBackdropPreset(CurrentPreviewBackdropName, Value)
            if Renamed then
                CurrentPreviewBackdropName = Renamed
                notify("Kojo", string.format("Backdrop renamed to %s", Renamed))
            end
        end,
    })
    ThemeGroup:AddSlider(Prefix .. "_PreviewFade", {
        Text = "Backdrop Transparency",
        Default = math.floor(getPreviewBackdropTransparency() * 100 + 0.5),
        Min = 0,
        Max = 100,
        Rounding = 0,
        Suffix = "%",
        Callback = function(Value)
            setEnvValue("KOJO_PreviewBackdropTransparency", Value)
            Preview:SetBackgroundImageTransparency(Value / 100)
        end,
    })
    DisplayGroup:AddSlider(Prefix .. "_UITransparency", {
        Text = "UI Transparency",
        Default = math.floor((WindowInfo.UITransparency or 0) * 100 + 0.5),
        Min = 0,
        Max = 200,
        Rounding = 0,
        Suffix = "%",
        Callback = function(Value)
            Window:SetUiTransparency(Value / 100)
        end,
    })
    DisplayGroup:AddSlider(Prefix .. "_WindowScale", {
        Text = "Window Scale",
        Default = getScalePercent(),
        Min = 75,
        Max = 125,
        Rounding = 0,
        Suffix = "%",
        Callback = function(Value)
            local NumericValue = math.clamp(tonumber(Value) or getScalePercent(), 75, 125)
            WindowInfo.DPIScale = NumericValue
            Library:SetDPIScale(NumericValue)
            if Options[Prefix .. "_WindowScale"] then
                Options[Prefix .. "_WindowScale"]:SetValue(NumericValue)
            end
        end,
    })
    DisplayGroup:AddDropdown(Prefix .. "_InteractionSpeed", {
        Text = "Animation Speed",
        Values = { "80%", "100%", "120%", "140%", "160%" },
        Default = "100%",
        Callback = function(Value)
            local SpeedText = tostring(Value):gsub("%%", "")
            local Speed = tonumber(SpeedText) or 100
            Library:SetInteractionSpeed(Speed)
        end,
    })

    do
        local OriginalAddLeftGroupbox = SettingsTab.AddLeftGroupbox
        local OriginalAddRightGroupbox = SettingsTab.AddRightGroupbox

        function SettingsTab:AddLeftGroupbox(Name, ...)
            local Normalized = tostring(Name or ""):gsub("%s+", ""):lower()
            if Normalized == "menu" then
                return MenuGroup
            end
            if Normalized == "theme" then
                return ThemeGroup
            end
            if Normalized == "display" or Normalized == "appearance" then
                return DisplayGroup
            end
            if Normalized == "profile" then
                return ProfileGroup
            end
            if Normalized == "themes" then
                return ThemesGroup
            end
            if Normalized == "configuration" or Normalized == "config" then
                return ConfigGroup
            end
            return OriginalAddLeftGroupbox(self, Name, ...)
        end

        function SettingsTab:AddRightGroupbox(Name, ...)
            local Normalized = tostring(Name or ""):gsub("%s+", ""):lower()
            if Normalized == "menu" then
                return MenuGroup
            end
            if Normalized == "theme" then
                return ThemeGroup
            end
            if Normalized == "display" or Normalized == "appearance" then
                return DisplayGroup
            end
            if Normalized == "profile" then
                return ProfileGroup
            end
            if Normalized == "themes" then
                return ThemesGroup
            end
            if Normalized == "configuration" or Normalized == "config" then
                return ConfigGroup
            end
            return OriginalAddRightGroupbox(self, Name, ...)
        end
    end

    local function refreshDashboard()
        local CountdownText = "Lifetime"
        local SecondsLeft = tonumber(getEnvValue("KOJO_SecondsLeft", nil))
        if SecondsLeft and SecondsLeft < 315360000 then
            if CountdownBase == nil then
                CountdownBase = SecondsLeft
                CountdownStartedAt = os.clock()
            end
            local Remaining = math.max(0, math.floor(CountdownBase - (os.clock() - CountdownStartedAt)))
            CountdownText = formatDuration(Remaining)
            ExpiresLabel:SetText("Expires In: " .. CountdownText)
            CountdownLabel:SetText("Countdown: " .. CountdownText)
        else
            CountdownBase = nil
            ExpiresLabel:SetText("Expires In: Lifetime")
            CountdownLabel:SetText("Countdown: Lifetime")
        end

        local RawKey = tostring(getEnvValue("KOJO_LicenseKey", "Unavailable"))
        local Discord = trim(getEnvValue("KOJO_DiscordTag", "Not linked"))
        if Discord == "" then
            Discord = "Not linked"
        end
        UserLabel:SetText("User: " .. getDisplayName())
        DiscordLabel:SetText("Discord: " .. Discord)
        TierLabel:SetText("Tier: " .. getTierValue())
        LicenseLabel:SetText("License Key: " .. RawKey)
        ExpiresAtLabel:SetText("Expires At: " .. tostring(getEnvValue("KOJO_ExpireAt", "Lifetime")))
        ExecutionsLabel:SetText("Executions: " .. tostring(getEnvValue("KOJO_ExecutionCount", 1)))
        GameLabel:SetText("Game: " .. getGameDisplayName())

    end

    if LocalPlayer then
        Library:GiveSignal(LocalPlayer.CharacterAdded:Connect(function()
            task.delay(0.35, function()
                Preview:SetObject(makeAvatarPreviewModel(), false)
                Preview:Focus()
                updateHeadNametag()
            end)
        end))
    end

    do
        local WindowBackgroundAsset = getWindowBackground()
        local WindowBackgroundPreset = registerFlatAssetPreset(BackgroundPresets, WindowBackgroundAsset, "Asset", Prefix .. "_WindowBackgroundPreset")
        if Options[Prefix .. "_WindowBackgroundPreset"] then
            Options[Prefix .. "_WindowBackgroundPreset"]:SetValue(WindowBackgroundPreset)
        end

        local NametagAsset = getNametagBackground()
        local NametagPreset = registerFlatAssetPreset(NametagBackgroundPresets, NametagAsset, "Nametag", Prefix .. "_NametagBackgroundPreset")
        if Options[Prefix .. "_NametagBackgroundPreset"] then
            Options[Prefix .. "_NametagBackgroundPreset"]:SetValue(NametagPreset)
        end

        local PreviewBackdropAsset = getPreviewBackdrop()
        if PreviewBackdropAsset ~= "" then
            local Registered = registerPreviewBackdropPreset(PreviewBackdropAsset)
            if Registered then
                CurrentPreviewBackdropName = Registered
            end
        end
        if Options[Prefix .. "_PreviewBackdropPreset"] then
            Options[Prefix .. "_PreviewBackdropPreset"]:SetValue(CurrentPreviewBackdropName)
        else
            applyPreviewBackdropPreset(CurrentPreviewBackdropName)
        end

    if Options[Prefix .. "_InteractionSpeed"] then
        Options[Prefix .. "_InteractionSpeed"]:SetValue("100%")
    end
    if Options[Prefix .. "_WindowScale"] then
        Options[Prefix .. "_WindowScale"]:SetValue(getScalePercent())
    end
    end

    applyWindowBackground()
    applyFooter()
    Window:SetUiTransparency(WindowInfo.UITransparency or 0)
    Preview:SetInteractive(not isSafeModeEnabled())
    refreshRemoteProfile()
    refreshDashboard()

    task.spawn(function()
        while not Library.Unloaded do
            task.wait(1)
            if Library.Unloaded then
                break
            end
            refreshDashboard()
        end
    end)

    local Controller = {
        DashboardTab = DashboardTab,
        SettingsTab = SettingsTab,
        Preview = Preview,
        Refresh = refreshDashboard,
        RefreshProfile = refreshRemoteProfile,
        SetPreviewObject = function(_, Object, CloneObject)
            Preview:SetObject(Object, CloneObject)
            Preview:Focus()
        end,
        UpdateHeadNametag = updateHeadNametag,
    }

    Window.KojoCore = Controller
    Window._KojoCoreMounted = true
    Library.LastKojoCoreWindow = Window

    return Controller
end

Library:GiveSignal(Players.PlayerAdded:Connect(OnPlayerChange))
Library:GiveSignal(Players.PlayerRemoving:Connect(OnPlayerChange))

Library:GiveSignal(Teams.ChildAdded:Connect(OnTeamChange))
Library:GiveSignal(Teams.ChildRemoved:Connect(OnTeamChange))

getgenv().Library = Library
return Library
