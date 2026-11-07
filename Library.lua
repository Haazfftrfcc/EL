local cloneref = (cloneref or clonereference or function(instance: any) return instance end)
local InputService: UserInputService = cloneref(game:GetService("UserInputService"))
local TextService: TextService = cloneref(game:GetService("TextService"))
local CoreGui: CoreGui = cloneref(game:GetService("CoreGui"))
local Players: Players = cloneref(game:GetService("Players"))
local RunService: RunService = cloneref(game:GetService("RunService"))
local TweenService: TweenService = cloneref(game:GetService("TweenService"))

local LocalPlayer = Players.LocalPlayer or Players.PlayerAdded:Wait()
local Mouse = cloneref(LocalPlayer:GetMouse())

local ProtectGui = protectgui or (syn and syn.protect_gui) or function() end
local GetHUI = gethui or function() return CoreGui end

local function SafeParentUI(Instance: Instance, Parent: Instance | () -> Instance)
    local success, _ = pcall(function()
        local DestinationParent = typeof(Parent) == "function" and Parent() or (Parent or CoreGui)
        Instance.Parent = DestinationParent
    end)
    if not (success and Instance.Parent) then
        Instance.Parent = LocalPlayer:WaitForChild("PlayerGui", math.huge)
    end
end

local function ParentUI(UI: Instance)
    pcall(ProtectGui, UI)
    SafeParentUI(UI, GetHUI)
end

local ScreenGui = Instance.new("ScreenGui")
ScreenGui.ZIndexBehavior = Enum.ZIndexBehavior.Global
ScreenGui.DisplayOrder = 999
ScreenGui.ResetOnSpawn = false
ParentUI(ScreenGui)

local Toggles = {}
local Options = {}
local Labels = {}
local Buttons = {}

local DPIScale = 1;
local Library = {
    Registry = {};
    RegistryMap = {};
    
    -- Colors (Linoria Red Theme) --
    FontColor = Color3.fromRGB(255, 255, 255);
    MainColor = Color3.fromRGB(24, 24, 24);
    BackgroundColor = Color3.fromRGB(15, 15, 15);

    AccentColor = Color3.fromRGB(248, 51, 51); -- 리노리아 특유의 Red Accent
    AccentColorDark = Color3.fromRGB(174, 3, 3);
    DisabledAccentColor = Color3.fromRGB(120, 50, 50);

    OutlineColor = Color3.fromRGB(45, 45, 45);
    DisabledOutlineColor = Color3.fromRGB(55, 55, 55);
    DisabledTextColor = Color3.fromRGB(120, 120, 120);

    Black = Color3.new(0, 0, 0);
    Font = Enum.Font.Code;

    OpenedFrames = {};
    Signals = {};
    
    ActiveTab = nil;
    TotalTabs = 0;
    ScreenGui = ScreenGui;
    Window = nil;

    Toggled = false;
    IsMobile = true;
    CanDrag = true;
    CantDragForced = false;
    Unloaded = false;

    SaveManager = nil;
    ThemeManager = nil;

    Toggles = Toggles;
    Options = Options;
    Labels = Labels;
    Buttons = Buttons;
}

function Library:Create(Class, Properties)
    local Inst = typeof(Class) == "string" and Instance.new(Class) or Class
    for Prop, Val in next, Properties do
        Inst[Prop] = Val
    end
    return Inst
end

function Library:AddToRegistry(Instance, Properties)
    local Data = { Instance = Instance, Properties = Properties }
    table.insert(Library.Registry, Data)
    Library.RegistryMap[Instance] = Data
end

function Library:UpdateColorsUsingRegistry()
    for _, Object in next, Library.Registry do
        for Property, ColorIdx in next, Object.Properties do
            if typeof(ColorIdx) == "string" then
                Object.Instance[Property] = Library[ColorIdx]
            end
        end
    end
end

function Library:MakeDraggable(Instance, Cutoff)
    Instance.Active = true
    local Dragging, DraggingInput, DraggingStart, StartPosition

    InputService.TouchStarted:Connect(function(Input)
        if Library.CantDragForced then return end
        if not Dragging and (Input.Position.Y - Instance.AbsolutePosition.Y) <= (Cutoff or 40) then
            Dragging = true
            DraggingInput = Input
            DraggingStart = Input.Position
            StartPosition = Instance.Position
        end
    end)
    InputService.TouchMoved:Connect(function(Input)
        if Input == DraggingInput and Dragging and Library.CanDrag then
            local Offset = Input.Position - DraggingStart
            Instance.Position = UDim2.new(StartPosition.X.Scale, StartPosition.X.Offset + Offset.X, StartPosition.Y.Scale, StartPosition.Y.Offset + Offset.Y)
        end
    end)
    InputService.TouchEnded:Connect(function(Input)
        if Input == DraggingInput then Dragging = false end
    end)
end

function Library:CreateWindow(Config)
    Config = Config or {}
    local TitleText = Config.Title or "Linoria Mobile"
    local Size = Config.Size or UDim2.fromOffset(520, 340)

    local Outer = Library:Create("Frame", {
        AnchorPoint = Vector2.new(0.5, 0.5),
        Position = UDim2.fromScale(0.5, 0.5),
        Size = Size,
        BackgroundColor3 = Library.Black,
        BorderSizePixel = 0,
        Parent = ScreenGui,
        Name = "MainWindow"
    })
    
    Library:MakeDraggable(Outer, 30)

    local Inner = Library:Create("Frame", {
        Position = UDim2.fromOffset(1, 1),
        Size = UDim2.new(1, -2, 1, -2),
        BackgroundColor3 = Library.MainColor,
        BorderColor3 = Library.AccentColor,
        BorderMode = Enum.BorderMode.Inset,
        Parent = Outer
    })
    Library:AddToRegistry(Inner, { BackgroundColor3 = "MainColor", BorderColor3 = "AccentColor" })

    -- Header Title Bar
    local TitleLabel = Library:Create("TextLabel", {
        Position = UDim2.fromOffset(8, 0),
        Size = UDim2.new(1, -16, 0, 26),
        BackgroundTransparency = 1,
        Font = Library.Font,
        Text = TitleText,
        TextColor3 = Library.FontColor,
        TextSize = 14,
        TextXAlignment = Enum.TextXAlignment.Left,
        Parent = Inner
    })

    -- Central Container
    local MainContainer = Library:Create("Frame", {
        Position = UDim2.fromOffset(6, 26),
        Size = UDim2.new(1, -12, 1, -32),
        BackgroundColor3 = Library.BackgroundColor,
        BorderColor3 = Library.OutlineColor,
        Parent = Inner
    })
    Library:AddToRegistry(MainContainer, { BackgroundColor3 = "BackgroundColor", BorderColor3 = "OutlineColor" })

    -- 🌟 좌측 세로 탭 바 (Vertical Sidebar Layout)
    local Sidebar = Library:Create("ScrollingFrame", {
        Position = UDim2.fromOffset(4, 4),
        Size = UDim2.new(0, 120, 1, -8),
        BackgroundColor3 = Library.MainColor,
        BorderColor3 = Library.OutlineColor,
        ScrollBarThickness = 2,
        ScrollBarImageColor3 = Library.AccentColor,
        Parent = MainContainer
    })
    Library:AddToRegistry(Sidebar, { BackgroundColor3 = "MainColor", BorderColor3 = "OutlineColor", ScrollBarImageColor3 = "AccentColor" })

    Library:Create("UIListLayout", {
        Padding = UDim.new(0, 3),
        SortOrder = Enum.SortOrder.LayoutOrder,
        Parent = Sidebar
    })

    -- 우측 컨텐츠 영역
    local ContentArea = Library:Create("Frame", {
        Position = UDim2.fromOffset(128, 4),
        Size = UDim2.new(1, -132, 1, -8),
        BackgroundTransparency = 1,
        Parent = MainContainer
    })

    local Window = { Tabs = {}, ActiveTab = nil }

    function Window:AddTab(Name)
        local Tab = { Groupboxes = {} }

        -- 세로 탭 버튼
        local TabButton = Library:Create("TextButton", {
            Size = UDim2.new(1, -4, 0, 28),
            Position = UDim2.fromOffset(2, 0),
            BackgroundColor3 = Library.BackgroundColor,
            BorderColor3 = Library.Black,
            Font = Library.Font,
            Text = Name,
            TextColor3 = Library.DisabledTextColor,
            TextSize = 13,
            Parent = Sidebar
        })

        local TabFrame = Library:Create("Frame", {
            Size = UDim2.fromScale(1, 1),
            BackgroundTransparency = 1,
            Visible = false,
            Parent = ContentArea
        })

        local LeftSide = Library:Create("ScrollingFrame", {
            Position = UDim2.fromScale(0, 0),
            Size = UDim2.new(0.5, -3, 1, 0),
            BackgroundTransparency = 1,
            ScrollBarThickness = 0,
            Parent = TabFrame
        })
        Library:Create("UIListLayout", { Padding = UDim.new(0, 6), Parent = LeftSide })

        local RightSide = Library:Create("ScrollingFrame", {
            Position = UDim2.new(0.5, 3, 0, 0),
            Size = UDim2.new(0.5, -3, 1, 0),
            BackgroundTransparency = 1,
            ScrollBarThickness = 0,
            Parent = TabFrame
        })
        Library:Create("UIListLayout", { Padding = UDim.new(0, 6), Parent = RightSide })

        function Tab:Show()
            for _, t in next, Window.Tabs do t:Hide() end
            TabFrame.Visible = true
            TabButton.BackgroundColor3 = Library.MainColor
            TabButton.TextColor3 = Library.AccentColor
        end

        function Tab:Hide()
            TabFrame.Visible = false
            TabButton.BackgroundColor3 = Library.BackgroundColor
            TabButton.TextColor3 = Library.DisabledTextColor
        end

        TabButton.MouseButton1Click:Connect(function() Tab:Show() end)

        function Tab:AddGroupbox(Info)
            local Side = (Info.Side == 2 or Info.Side == "Right") and RightSide or LeftSide
            
            local GroupOuter = Library:Create("Frame", {
                Size = UDim2.new(1, 0, 0, 30),
                BackgroundColor3 = Library.BackgroundColor,
                BorderColor3 = Library.OutlineColor,
                Parent = Side
            })

            local GroupHeader = Library:Create("TextLabel", {
                Position = UDim2.fromOffset(6, 2),
                Size = UDim2.new(1, -12, 0, 16),
                BackgroundTransparency = 1,
                Font = Library.Font,
                Text = Info.Name or "Group",
                TextColor3 = Library.FontColor,
                TextSize = 13,
                TextXAlignment = Enum.TextXAlignment.Left,
                Parent = GroupOuter
            })

            local Container = Library:Create("Frame", {
                Position = UDim2.fromOffset(4, 20),
                Size = UDim2.new(1, -8, 1, -24),
                BackgroundTransparency = 1,
                Parent = GroupOuter
            })
            local Layout = Library:Create("UIListLayout", { Padding = UDim.new(0, 4), Parent = Container })

            local Groupbox = {}

            local function Resize()
                GroupOuter.Size = UDim2.new(1, 0, 0, Layout.AbsoluteContentSize.Y + 26)
            end
            Layout:GetPropertyChangedSignal("AbsoluteContentSize"):Connect(Resize)

            -- 🌟 리노리아 특유의 Toggle (체크박스 □ -> 활성화 시 Red 적용)
            function Groupbox:AddToggle(Idx, Config)
                local Toggle = { Value = Config.Default or false, Callback = Config.Callback or function() end }

                local ToggleContainer = Library:Create("Frame", {
                    Size = UDim2.new(1, 0, 0, 18),
                    BackgroundTransparency = 1,
                    Parent = Container
                })

                local BoxOuter = Library:Create("Frame", {
                    Size = UDim2.fromOffset(14, 14),
                    Position = UDim2.fromOffset(0, 2),
                    BackgroundColor3 = Library.Black,
                    BorderSizePixel = 0,
                    Parent = ToggleContainer
                })

                local BoxInner = Library:Create("Frame", {
                    Position = UDim2.fromOffset(1, 1),
                    Size = UDim2.fromOffset(12, 12),
                    BackgroundColor3 = Toggle.Value and Library.AccentColor or Library.MainColor,
                    BorderColor3 = Toggle.Value and Library.AccentColorDark or Library.OutlineColor,
                    BorderMode = Enum.BorderMode.Inset,
                    Parent = BoxOuter
                })

                local Label = Library:Create("TextLabel", {
                    Position = UDim2.fromOffset(20, 0),
                    Size = UDim2.new(1, -20, 1, 0),
                    BackgroundTransparency = 1,
                    Font = Library.Font,
                    Text = Config.Text,
                    TextColor3 = Library.FontColor,
                    TextSize = 13,
                    TextXAlignment = Enum.TextXAlignment.Left,
                    Parent = ToggleContainer
                })

                function Toggle:SetValue(Bool)
                    Toggle.Value = not not Bool
                    BoxInner.BackgroundColor3 = Toggle.Value and Library.AccentColor or Library.MainColor
                    BoxInner.BorderColor3 = Toggle.Value and Library.AccentColorDark or Library.OutlineColor
                    Toggle.Callback(Toggle.Value)
                end

                ToggleContainer.InputBegan:Connect(function(Input)
                    if Input.UserInputType == Enum.UserInputType.Touch or Input.UserInputType == Enum.UserInputType.MouseButton1 then
                        Toggle:SetValue(not Toggle.Value)
                    end
                end)

                Toggles[Idx] = Toggle
                Resize()
                return Toggle
            end

            return Groupbox
        end

        table.insert(Window.Tabs, Tab)
        if #Window.Tabs == 1 then Tab:Show() end
        return Tab
    end

    -- Mobile Toggle Button
    local MobileBtn = Library:Create("TextButton", {
        Position = UDim2.new(0.01, 0, 0.1, 0),
        Size = UDim2.fromOffset(75, 26),
        BackgroundColor3 = Library.MainColor,
        BorderColor3 = Library.AccentColor,
        Font = Library.Font,
        Text = "UI Toggle",
        TextColor3 = Library.FontColor,
        TextSize = 12,
        Parent = ScreenGui
    })
    MobileBtn.MouseButton1Click:Connect(function()
        Outer.Visible = not Outer.Visible
    end)
    Library:MakeDraggable(MobileBtn)

    Library.Window = Outer
    return Window
end

getgenv().Linoria = Library
return Library
