local ThemeManager = {}
ThemeManager.Folder = "LinoriaMobileThemes"
ThemeManager.Library = nil

function ThemeManager:SetLibrary(Lib)
    ThemeManager.Library = Lib
end

function ThemeManager:ApplyTheme(ThemeData)
    if not ThemeManager.Library then return end
    for Key, Color in next, ThemeData do
        if ThemeManager.Library[Key] then
            ThemeManager.Library[Key] = Color
        end
    end
    ThemeManager.Library:UpdateColorsUsingRegistry()
end

-- 기본 리노리아 Red 테마 정의
ThemeManager.BuiltInThemes = {
    ["Linoria Red"] = {
        FontColor = Color3.fromRGB(255, 255, 255),
        MainColor = Color3.fromRGB(24, 24, 24),
        BackgroundColor = Color3.fromRGB(15, 15, 15),
        AccentColor = Color3.fromRGB(248, 51, 51),
        AccentColorDark = Color3.fromRGB(174, 3, 3),
        OutlineColor = Color3.fromRGB(45, 45, 45)
    }
}

function ThemeManager:BuildThemeSection(Tab)
    local Group = Tab:AddGroupbox({ Name = "Theme Settings", Side = 2 })
    
    Group:AddToggle("RedThemeToggle", {
        Text = "Enforce Red Theme",
        Default = true,
        Callback = function(State)
            if State then
                ThemeManager:ApplyTheme(ThemeManager.BuiltInThemes["Linoria Red"])
            end
        end
    })
end

return ThemeManager
