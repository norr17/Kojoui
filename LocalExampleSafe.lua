local function normalizeRoot(root)
    if root == "" then
        return ""
    end

    if root:sub(-1) ~= "\\" and root:sub(-1) ~= "/" then
        return root .. "\\"
    end

    return root
end

local function findRoot()
    local envRoot = rawget(getgenv(), "KojoObsidianRoot")
    local candidates = {
        envRoot,
        "obsidian_kojo",
        ".\\obsidian_kojo",
        "Obsidian",
        ".\\Obsidian",
        "",
    }

    for _, candidate in ipairs(candidates) do
        if type(candidate) == "string" and candidate ~= "" then
            local root = normalizeRoot(candidate)
            if isfile(root .. "Library.lua") and isfile(root .. "Example.lua") then
                return root
            end
        end
    end

    if isfile("Library.lua") and isfile("Example.lua") then
        return ""
    end

    error("Could not locate local Obsidian files. Put the folder in your executor workspace or set getgenv().KojoObsidianRoot first.")
end

local root = findRoot()

local function loadLuaFile(path)
    local source = readfile(root .. path)
    assert(type(source) == "string", "readfile failed for " .. root .. path)

    local chunk, err = loadstring(source)
    assert(chunk, err or ("loadstring failed for " .. root .. path))

    return chunk()
end

local Library = loadLuaFile("Library.lua")
local ThemeManager = loadLuaFile("addons\\ThemeManager.lua")
local SaveManager = loadLuaFile("addons\\SaveManager.lua")

getgenv().KOJO_SafeMode = true

getgenv().KojoObsidianLocal = {
    Library = Library,
    ThemeManager = ThemeManager,
    SaveManager = SaveManager,
}

local useLegacyExample = rawget(getgenv and getgenv() or _G, "KojoUseLegacyExample") == true
local examplePath = "Example.lua"

if useLegacyExample and isfile(root .. "KojoExample.lua") then
    examplePath = "KojoExample.lua"
end
local source = readfile(root .. examplePath)
assert(type(source) == "string", "readfile failed for " .. root .. examplePath)
source = source:gsub('local repo = \".-\"\n', "")
source = source:gsub('local Library = loadstring%(.-%)[^\n]*\n', 'local Library = KojoObsidianLocal.Library\n')
source = source:gsub('local ThemeManager = loadstring%(.-%)[^\n]*\n', 'local ThemeManager = KojoObsidianLocal.ThemeManager\n')
source = source:gsub('local SaveManager = loadstring%(.-%)[^\n]*\n', 'local SaveManager = KojoObsidianLocal.SaveManager\n')
loadstring(source)()
