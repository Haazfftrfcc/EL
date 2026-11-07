local SaveManager = {}
SaveManager.Folder = "LinoriaMobileConfigs"
SaveManager.Ignore = {}

local HttpService = game:GetService("HttpService")

function SaveManager:SetFolder(Folder)
    SaveManager.Folder = Folder
    if not isfolder(Folder) then
        makefolder(Folder)
    end
end

function SaveManager:Save(Name)
    if not Name or Name:sub(%s*) == "" then return end
    local Data = {}

    for Idx, Toggle in next, getgenv().Linoria.Toggles do
        if not table.find(SaveManager.Ignore, Idx) then
            Data[Idx] = Toggle.Value
        end
    end

    writefile(SaveManager.Folder .. "/" .. Name .. ".json", HttpService:JSONEncode(Data))
end

function SaveManager:Load(Name)
    local Path = SaveManager.Folder .. "/" .. Name .. ".json"
    if not isfile(Path) then return end

    local Success, Decoded = pcall(function()
        return HttpService:JSONDecode(readfile(Path))
    end)

    if Success and type(Decoded) == "table" then
        for Idx, Value in next, Decoded do
            if getgenv().Linoria.Toggles[Idx] then
                getgenv().Linoria.Toggles[Idx]:SetValue(Value)
            end
        end
    end
end

function SaveManager:BuildConfigSection(Tab)
    local Group = Tab:AddGroupbox({ Name = "Config Manager", Side = 2 })
    
    Group:AddToggle("AutoSave", {
        Text = "Auto Save Config",
        Default = false,
        Callback = function(Value)
            print("AutoSave:", Value)
        end
    })
end

return SaveManager
