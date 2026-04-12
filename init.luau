local Types = require(script.Parent["Library.d"])

return {
    Library = (require(script.Parent.Library) :: any) :: Types.Library,
    Types = Types,
    SaveManager = require(script.Parent.addons.SaveManager),
    ThemeManager = require(script.Parent.addons.ThemeManager),
}
