-- SyntaxNext UI External Library
-- Extracted from the stable SyntaxNext Native UI baseline.
-- UI core only: no game-specific features.

-- SECTION 11: NEXUS NATIVE UI (PRESERVED PREVIOUS UI)
local function CreateWindow(options)
    options = options or {}
    local ChatLogsFrame = nil
    local ChatLogsGlass = nil
-- ================================================================
-- SyntaxNext / Suzume Native UI Edition
--
-- 本版本：
-- 1) 完全移除 WindUI，不再加载 WindUI.lua。
-- 2) 主 UI 直接采用“测试.lua”的原生 ScreenGui / MainFrame 结构。
-- 3) 资源毛玻璃统一使用测试.lua：rbxassetid://81247868201885
-- 4) 模仿 WindUI：Window / Tab / Section / Paragraph / Button /
--    Toggle / Input / Slider / Tag / EditOpenButton / Notify。
-- 5) 右上角功能列表透明显示，并按文字实际宽度自适应；名称使用 Opal RGB + Bloom，模式小字使用白色 Bloom。
-- 6) 单个功能独立进入/退出，不影响其它功能的动画。
-- 7) 顶部“灵动岛”移除磨砂玻璃，仅使用白色 Bloom，展开/收缩采用更明显的多段Q弹回弹；
--    功能切换时展开并提示，灵动岛同时作为主 UI 唯一打开/隐藏入口。
-- 本次回退修复：
-- A) 回到上一版稳定的资源毛玻璃结构，不采用最近版本的遮罩/复杂磨砂层。
-- B) 主 UI 白色玻璃层严格贴合 MainFrame 本体，资源图负责外扩毛玻璃。
-- C) 功能列表改为手动右对齐布局，避免UIScale/排序时文本行重叠。
-- D) 功能列表取消旧辉光方案，改为无描边白色高亮文字并显示模式。
-- E) 主题拖动调节项移除；字体与字体颜色改用带弹出动画、自适应滚动的样式选择器。
-- ================================================================

local Players = game:GetService("Players")
local RunService = game:GetService("RunService")
local UserInputService = game:GetService("UserInputService")
local TweenService = game:GetService("TweenService")
local TextService = game:GetService("TextService")

local LocalPlayer = Players.LocalPlayer
local PlayerGui = LocalPlayer:WaitForChild("PlayerGui")
local CoreGui = game:GetService("CoreGui")
local env = (type(getgenv) == "function" and getgenv()) or _G

-- ================================================================
-- 配置
-- ================================================================

local GLASS_ASSET = "rbxassetid://81247868201885"

local MAIN_SIZE = Vector2.new(580, 420)
local MAIN_GLASS_EXPANSION = 60
local MAIN_GLASS_ALPHA = 0.00
local MAIN_GLASS_WHITE_ALPHA = 1.0

local CONTROL_WHITE_ALPHA = 0.84
local CONTROL_STROKE_ALPHA = 0.86

local FEATURE_TEXT_SIZE = 14
local FEATURE_FONT = Enum.Font.GothamMedium
local FEATURE_ROW_HEIGHT = 30
local FEATURE_MIN_WIDTH = 58
local FEATURE_HORIZONTAL_PADDING = 24
local FEATURE_GAP = 5
local FEATURE_GLASS_EXPANSION = 5
local FEATURE_GLASS_ALPHA = 0.04
local FEATURE_WHITE_ALPHA = 0.82

local ISLAND_COLLAPSED_WIDTH = 154
local ISLAND_COLLAPSED_HEIGHT = 38
local ISLAND_EXPANDED_WIDTH = 360
local ISLAND_EXPANDED_HEIGHT = 70
local ISLAND_TOP_Y = 10
local ISLAND_EXPANDED_Y = 22
local ISLAND_CORNER_RADIUS = 24
-- 灵动岛不再使用磨砂/白色实体背景，只保留 Bloom 辉光。
local ISLAND_GLASS_EXPANSION = 0
local ISLAND_GLASS_ALPHA = 1.00
local ISLAND_WHITE_ALPHA = 1.00
local ISLAND_ICON_SIZE = 30
local ISLAND_AUTO_COLLAPSE = 1.9
local ISLAND_SPRING_SCALE = 1.12
local ISLAND_BLOOM_16 = "rbxassetid://104490578391522"
local ISLAND_BLOOM_8 = "rbxassetid://102472648910048"
local ISLAND_BLOOM_BASE_ALPHA = 0.34
local ISLAND_BLOOM_IN_ALPHA = 0.28

local NOTIFY_GLASS_VISIBILITY = 100
local NOTIFY_GLASS_PADDING = 5
local NOTIFY_CORNER_RADIUS = 12
local NOTIFY_WHITE_ALPHA = 0.82

-- ================================================================
-- 旧 UI 清理
-- ================================================================

pcall(function()
    local old = CoreGui:FindFirstChild("NexusSuzumeNativeUI")
    if old then old:Destroy() end
end)

pcall(function()
    local old = CoreGui:FindFirstChild("NexusFeatureHUD")
    if old then old:Destroy() end
end)

pcall(function()
    local old = CoreGui:FindFirstChild("NexusDynamicIsland")
    if old then old:Destroy() end
end)

-- ================================================================
-- 工具
-- ================================================================

local function safeParent(gui, parent)
    local ok = pcall(function()
        gui.Parent = parent
    end)
    return ok and gui.Parent ~= nil
end

local function addCorner(parent, radius)
    local corner = Instance.new("UICorner")
    corner.CornerRadius = UDim.new(0, radius or 10)
    corner.Parent = parent
    return corner
end

local function addStroke(parent, transparency, thickness)
    local stroke = Instance.new("UIStroke")
    stroke.Thickness = thickness or 1
    stroke.Color = Color3.fromRGB(255, 255, 255)
    stroke.Transparency = transparency == nil and 0.86 or transparency
    stroke.Parent = parent
    return stroke
end

local function clampNumber(value, minValue, maxValue)
    return math.clamp(tonumber(value) or minValue, minValue, maxValue)
end

local function adaptiveExpansion(guiObject, requested, ratio, maxRatio)
    local width = math.max(guiObject.AbsoluteSize.X, 1)
    local height = math.max(guiObject.AbsoluteSize.Y, 1)
    local shortest = math.min(width, height)
    local ratioValue = math.floor(shortest * (ratio or 0.18) + 0.5)
    local maxValue = requested
    if maxRatio then
        maxValue = math.min(maxValue, math.floor(shortest * maxRatio + 0.5))
    end
    return math.max(0, math.min(ratioValue, maxValue))
end

local function attachResourceGlass(target, config)
    config = config or {}

    if config.ClipToBounds ~= nil then
        target.ClipsDescendants = config.ClipToBounds
    else
        target.ClipsDescendants = false
    end

    local image = Instance.new("ImageLabel")
    image.Name = config.Name or "BackgroundImage"
    image.BackgroundTransparency = 1
    image.BorderSizePixel = 0
    image.AnchorPoint = Vector2.new(0, 0)
    image.Image = GLASS_ASSET
    image.ScaleType = Enum.ScaleType.Stretch
    image.ImageTransparency = config.ImageTransparency == nil and 0 or config.ImageTransparency
    image.ZIndex = config.ImageZIndex or 0
    -- 按测试.lua原始方案：资源本体不单独做圆角，避免外扩资源出现错位圆角/方形露边。
    image.ClipsDescendants = false
    image.Parent = target
    if config.ImageCornerRadius ~= false then
        -- 仅在明确要求时给资源图加圆角；默认关闭，圆角由白色表面承担。
        if config.ImageCornerRadius ~= nil then
            addCorner(image, config.ImageCornerRadius)
        end
    end

    -- 白色玻璃表面固定贴合 target 本体，避免随外扩资源产生“白色背景错位”。
    local white = Instance.new("Frame")
    white.Name = config.WhiteName or "WhiteGlass"
    white.AnchorPoint = Vector2.new(0, 0)
    white.Size = UDim2.fromScale(1, 1)
    white.Position = UDim2.fromScale(0, 0)
    white.BackgroundColor3 = Color3.fromRGB(255, 255, 255)
    white.BackgroundTransparency = config.WhiteTransparency == nil and 0.85 or config.WhiteTransparency
    white.BorderSizePixel = 0
    white.ZIndex = config.WhiteZIndex or 1
    white.Parent = target
    addCorner(white, config.CornerRadius or 10)

    local dynamicPadding = config.FixedPadding

    local function update()
        if not target.Parent then return end
        local pad = dynamicPadding
        if pad == nil then
            pad = adaptiveExpansion(
                target,
                config.MaxPadding or 24,
                config.PaddingRatio or 0.18,
                config.AdaptiveMaxRatio
            )
        end
        pad = math.max(0, tonumber(pad) or 0)
        image.Position = UDim2.fromOffset(-pad, -pad)
        image.Size = UDim2.new(1, pad * 2, 1, pad * 2)
        white.Size = UDim2.fromScale(1, 1)
        white.Position = UDim2.fromScale(0, 0)
    end

    update()
    local conn = target:GetPropertyChangedSignal("AbsoluteSize"):Connect(update)

    local api = {
        Image = image,
        White = white,
        Connection = conn,
        Update = update,
    }
    function api:SetPadding(pad)
        dynamicPadding = math.max(0, tonumber(pad) or 0)
        update()
    end
    function api:GetPadding()
        return dynamicPadding
    end
    function api:SetImageTransparency(value)
        image.ImageTransparency = math.clamp(tonumber(value) or image.ImageTransparency, 0, 1)
    end
    function api:SetWhiteTransparency(value)
        white.BackgroundTransparency = math.clamp(tonumber(value) or white.BackgroundTransparency, 0, 1)
    end
    function api:SetCornerRadius(radius)
        local r = math.max(0, tonumber(radius) or 0)
        local c1 = white:FindFirstChildOfClass("UICorner")
        if c1 then c1.CornerRadius = UDim.new(0, r) end
        local c2 = image:FindFirstChildOfClass("UICorner")
        if c2 then c2.CornerRadius = UDim.new(0, r) end
    end

    return api
end

local function destroyGlass(glass)
    if not glass then return end
    if glass.Connection then pcall(function() glass.Connection:Disconnect() end) end
    if glass.Image then pcall(function() glass.Image:Destroy() end) end
    if glass.White then pcall(function() glass.White:Destroy() end) end
end

-- ================================================================
-- 聊天日志复用主 UI 的资源玻璃
-- 不使用 BlurEffect / Acrylic / Liquid Glass，只复用 Nexus 主 UI 的
-- rbxassetid://81247868201885 资源图和同一套外扩逻辑。
-- ================================================================
if ChatLogsFrame and ChatLogsFrame.Parent and not ChatLogsGlass then
    ChatLogsGlass = attachResourceGlass(ChatLogsFrame, {
        Name = "BackgroundImage",
        WhiteName = "WhiteGlass",
        ImageTransparency = MAIN_GLASS_ALPHA,
        WhiteTransparency = MAIN_GLASS_WHITE_ALPHA,
        MaxPadding = 60,
        PaddingRatio = 1,
        AdaptiveMaxRatio = 0.18,
        CornerRadius = 12,
        ImageZIndex = 0,
        WhiteZIndex = 1,
    })
    ChatLogsGlass.White.BackgroundTransparency = MAIN_GLASS_WHITE_ALPHA
end

-- ================================================================
-- 主 ScreenGui / MainFrame
-- ================================================================

local ScreenGui = Instance.new("ScreenGui")
ScreenGui.Name = "NexusSuzumeNativeUI"
ScreenGui.ResetOnSpawn = false
ScreenGui.IgnoreGuiInset = true
ScreenGui.ZIndexBehavior = Enum.ZIndexBehavior.Sibling
ScreenGui.DisplayOrder = 99990

if not safeParent(ScreenGui, CoreGui) then
    ScreenGui.Parent = PlayerGui
end

local MainFrame = Instance.new("Frame")
MainFrame.Name = "MainFrame"
MainFrame.Size = UDim2.fromOffset(MAIN_SIZE.X, MAIN_SIZE.Y)
MainFrame.Position = UDim2.new(0.5, -MAIN_SIZE.X / 2, 0.5, -MAIN_SIZE.Y / 2)
MainFrame.BackgroundTransparency = 1
MainFrame.BorderSizePixel = 0
MainFrame.ClipsDescendants = false
MainFrame.Parent = ScreenGui

addCorner(MainFrame, 12)
addStroke(MainFrame, 1, 1)

local MainGlass = attachResourceGlass(MainFrame, {
    Name = "BackgroundImage",
    WhiteName = "WhiteGlass",
    ImageTransparency = MAIN_GLASS_ALPHA,
    WhiteTransparency = MAIN_GLASS_WHITE_ALPHA,
    MaxPadding = 60,
    PaddingRatio = 1,
    AdaptiveMaxRatio = 0.18,
    CornerRadius = 12,
    ImageZIndex = 0,
    WhiteZIndex = 1,
})

-- 白色层只做很淡的混合，真正的毛玻璃来自资源图，不使用黑色背景。
MainGlass.White.BackgroundTransparency = MAIN_GLASS_WHITE_ALPHA

-- ================================================================
-- 顶部栏
-- ================================================================

local TitleBar = Instance.new("Frame")
TitleBar.Name = "TitleBar"
TitleBar.Size = UDim2.new(1, 0, 0, 45)
TitleBar.BackgroundTransparency = 1
TitleBar.BorderSizePixel = 0
TitleBar.ZIndex = 10
TitleBar.Parent = MainFrame

local TitleLabel = Instance.new("TextLabel")
TitleLabel.Name = "TitleLabel"
TitleLabel.Size = UDim2.new(1, -215, 1, 0)
TitleLabel.Position = UDim2.fromOffset(15, 0)
TitleLabel.BackgroundTransparency = 1
TitleLabel.Text = tostring(options.Title or "SyntaxNext")
TitleLabel.TextColor3 = Color3.fromRGB(255, 255, 255)
TitleLabel.TextSize = 18
TitleLabel.Font = Enum.Font.GothamBold
TitleLabel.TextXAlignment = Enum.TextXAlignment.Left
TitleLabel.ZIndex = 12
TitleLabel.Parent = TitleBar

local TimeTag = Instance.new("TextLabel")
TimeTag.Name = "TimeTag"
TimeTag.Size = UDim2.fromOffset(70, 24)
TimeTag.Position = UDim2.new(1, -196, 0.5, -12)
TimeTag.BackgroundColor3 = Color3.fromRGB(255, 255, 255)
TimeTag.BackgroundTransparency = 0.85
TimeTag.Text = "00:00"
TimeTag.TextColor3 = Color3.fromRGB(255, 255, 255)
TimeTag.TextSize = 13
TimeTag.Font = Enum.Font.GothamMedium
TimeTag.ZIndex = 12
TimeTag.Parent = TitleBar
addCorner(TimeTag, 6)

-- 主 UI 控制：最小化 / 增大 / 删除；统一放入右侧控制组，避免白色底块错位。
local ControlGroup = Instance.new("Frame")
ControlGroup.Name = "WindowControls"
ControlGroup.Size = UDim2.fromOffset(112, 30)
ControlGroup.Position = UDim2.new(1, -116, 0.5, -15)
ControlGroup.BackgroundTransparency = 1
ControlGroup.BorderSizePixel = 0
ControlGroup.ZIndex = 12
ControlGroup.Parent = TitleBar

local function styleWindowControl(button, glyph)
    button.Size = UDim2.fromOffset(30, 30)
    button.BackgroundColor3 = Color3.fromRGB(255, 255, 255)
    button.BackgroundTransparency = 0.18
    button.BorderSizePixel = 0
    button.Text = glyph
    button.TextColor3 = Color3.fromRGB(80, 80, 86)
    button.TextSize = glyph == "□" and 14 or 17
    button.Font = Enum.Font.GothamBold
    button.AutoButtonColor = false
    button.ZIndex = 12
    button.Parent = ControlGroup
    addCorner(button, 8)
end

local MinBtn = Instance.new("TextButton")
MinBtn.Name = "MinimizeBtn"
MinBtn.Position = UDim2.fromOffset(0, 0)
styleWindowControl(MinBtn, "−")

local MaxBtn = Instance.new("TextButton")
MaxBtn.Name = "MaximizeBtn"
MaxBtn.Position = UDim2.fromOffset(39, 0)
styleWindowControl(MaxBtn, "□")

local CloseBtn = Instance.new("TextButton")
CloseBtn.Name = "CloseBtn"
CloseBtn.Position = UDim2.fromOffset(78, 0)
styleWindowControl(CloseBtn, "×")

local function windowControlHover(button, hover)
    TweenService:Create(button, TweenInfo.new(0.12, Enum.EasingStyle.Quad, Enum.EasingDirection.Out), {
        BackgroundTransparency = hover and 0.02 or 0.18,
    }):Play()
end

for _, button in ipairs({MinBtn, MaxBtn, CloseBtn}) do
    button.MouseEnter:Connect(function() windowControlHover(button, true) end)
    button.MouseLeave:Connect(function() windowControlHover(button, false) end)
end

local Divider = Instance.new("Frame")
Divider.Name = "Divider"
Divider.Size = UDim2.new(1, -30, 0, 1)
Divider.Position = UDim2.fromOffset(15, 45)
Divider.BackgroundColor3 = Color3.fromRGB(255, 255, 255)
Divider.BackgroundTransparency = 0.85
Divider.BorderSizePixel = 0
Divider.ZIndex = 11
Divider.Parent = MainFrame

-- ================================================================
-- 左侧 Tab 区 + 内容区
-- ================================================================

local Body = Instance.new("Frame")
Body.Name = "Body"
Body.Size = UDim2.new(1, -30, 1, -68)
Body.Position = UDim2.fromOffset(15, 58)
Body.BackgroundTransparency = 1
Body.BorderSizePixel = 0
Body.ZIndex = 10
Body.Parent = MainFrame

local TabBar = Instance.new("ScrollingFrame")
TabBar.Name = "TabBar"
TabBar.Size = UDim2.new(0, 126, 1, 0)
TabBar.BackgroundTransparency = 1
TabBar.BorderSizePixel = 0
TabBar.ScrollBarThickness = 2
TabBar.Active = true
TabBar.ScrollBarImageTransparency = 0.65
TabBar.ZIndex = 10
TabBar.Parent = Body

local TabLayout = Instance.new("UIListLayout")
TabLayout.Padding = UDim.new(0, 7)
TabLayout.SortOrder = Enum.SortOrder.LayoutOrder
TabLayout.Parent = TabBar

TabLayout:GetPropertyChangedSignal("AbsoluteContentSize"):Connect(function()
    TabBar.CanvasSize = UDim2.fromOffset(0, TabLayout.AbsoluteContentSize.Y + 8)
end)

-- 单一全局页面指示条：切换页面时沿左侧上下滑动、拉伸、回弹。
local GlobalTabIndicator = Instance.new("Frame")
GlobalTabIndicator.Name = "ActiveTabIndicator"
GlobalTabIndicator.Size = UDim2.fromOffset(4, 22)
GlobalTabIndicator.Position = UDim2.fromOffset(3, 18)
GlobalTabIndicator.AnchorPoint = Vector2.new(0, 0.5)
GlobalTabIndicator.BackgroundColor3 = Color3.fromRGB(255, 255, 255)
GlobalTabIndicator.BackgroundTransparency = 0.04
GlobalTabIndicator.BorderSizePixel = 0
GlobalTabIndicator.ZIndex = 30
GlobalTabIndicator.Active = false
GlobalTabIndicator.Selectable = false
GlobalTabIndicator.Visible = false
GlobalTabIndicator.Parent = Body
addCorner(GlobalTabIndicator, 999)

local ContentHost = Instance.new("Frame")
ContentHost.Name = "ContentHost"
ContentHost.Size = UDim2.new(1, -136, 1, 0)
ContentHost.Position = UDim2.fromOffset(136, 0)
ContentHost.BackgroundTransparency = 1
ContentHost.BorderSizePixel = 0
ContentHost.ZIndex = 10
ContentHost.Parent = Body

local TabPages = {}

-- ================================================================
-- Notify
-- ================================================================

local NotifyHolder = Instance.new("Frame")
NotifyHolder.Name = "NotifyHolder"
NotifyHolder.AnchorPoint = Vector2.new(1, 1)
NotifyHolder.Position = UDim2.new(1, -18, 1, -18)
NotifyHolder.Size = UDim2.fromOffset(300, 300)
NotifyHolder.BackgroundTransparency = 1
NotifyHolder.BorderSizePixel = 0
NotifyHolder.ZIndex = 100
NotifyHolder.Parent = ScreenGui

local NotifyLayout = Instance.new("UIListLayout")
NotifyLayout.VerticalAlignment = Enum.VerticalAlignment.Bottom
NotifyLayout.HorizontalAlignment = Enum.HorizontalAlignment.Right
NotifyLayout.Padding = UDim.new(0, 7)
NotifyLayout.Parent = NotifyHolder

local NotificationConfig = {
    GlassVisibility = 100,
    GlassPadding = NOTIFY_GLASS_PADDING,
    CornerRadius = NOTIFY_CORNER_RADIUS,
    WhiteAlpha = NOTIFY_WHITE_ALPHA,
}
local ActiveNotifications = {}

local function Notify(config)
    config = config or {}

    local box = Instance.new("Frame")
    box.Name = "Notification"
    box.Size = UDim2.fromOffset(280, 58)
    box.BackgroundTransparency = 1
    box.BorderSizePixel = 0
    box.ClipsDescendants = false
    box.ZIndex = 101
    box.Parent = NotifyHolder

    local glass = attachResourceGlass(box, {
        Name = "BackgroundImage",
        WhiteName = "WhiteGlass",
        ImageTransparency = 1 - (NotificationConfig.GlassVisibility / 100),
        WhiteTransparency = NotificationConfig.WhiteAlpha,
        FixedPadding = NotificationConfig.GlassPadding,
        CornerRadius = NotificationConfig.CornerRadius,
        ImageCornerRadius = NotificationConfig.CornerRadius,
        ImageZIndex = 0,
        WhiteZIndex = 1,
        ClipToBounds = true,
    })
    table.insert(ActiveNotifications, {Box = box, Glass = glass})

    local title = Instance.new("TextLabel")
    title.Size = UDim2.new(1, -24, 0, 20)
    title.Position = UDim2.fromOffset(12, 8)
    title.BackgroundTransparency = 1
    title.Text = tostring(config.Title or "SyntaxNext")
    title.TextColor3 = Color3.fromRGB(255, 255, 255)
    title.TextSize = 14
    title.Font = Enum.Font.GothamBold
    title.TextXAlignment = Enum.TextXAlignment.Left
    title.ZIndex = 3
    title.Parent = box

    local desc = Instance.new("TextLabel")
    desc.Size = UDim2.new(1, -24, 0, 22)
    desc.Position = UDim2.fromOffset(12, 29)
    desc.BackgroundTransparency = 1
    desc.Text = tostring(config.Content or "")
    desc.TextColor3 = Color3.fromRGB(245, 245, 245)
    desc.TextSize = 12
    desc.Font = Enum.Font.Gotham
    desc.TextXAlignment = Enum.TextXAlignment.Left
    desc.ZIndex = 3
    desc.Parent = box

    box.Position = UDim2.fromOffset(40, 0)
    box.BackgroundTransparency = 1
    local scale = Instance.new("UIScale")
    scale.Scale = 0.82
    scale.Parent = box

    TweenService:Create(scale, TweenInfo.new(0.22, Enum.EasingStyle.Back, Enum.EasingDirection.Out), {Scale = 1}):Play()

    task.delay(config.Duration or 2.5, function()
        if box.Parent then
            local out = TweenService:Create(scale, TweenInfo.new(0.18, Enum.EasingStyle.Quad, Enum.EasingDirection.In), {Scale = 0.8})
            out:Play()
            out.Completed:Wait()
            destroyGlass(glass)
            for i = #ActiveNotifications, 1, -1 do
                if ActiveNotifications[i].Box == box then
                    table.remove(ActiveNotifications, i)
                    break
                end
            end
            box:Destroy()
        end
    end)

    return box
end

local NotificationAPI = {}
function NotificationAPI.Show(config)
    return Notify(config or {})
end
function NotificationAPI.SetGlassVisibility(value)
    NotificationConfig.GlassVisibility = math.clamp(tonumber(value) or NotificationConfig.GlassVisibility, 0, 100)
    local visibility = NotificationConfig.GlassVisibility / 100
    for _, item in ipairs(ActiveNotifications) do
        if item.Box and item.Box.Parent and item.Glass then
            item.Glass:SetImageTransparency(1 - visibility)
            item.Glass:SetWhiteTransparency(NotificationConfig.WhiteAlpha + (1 - visibility) * 0.10)
        end
    end
end
function NotificationAPI.SetGlassPadding(value)
    NotificationConfig.GlassPadding = math.clamp(math.floor(tonumber(value) or NotificationConfig.GlassPadding), 0, 30)
    for _, item in ipairs(ActiveNotifications) do
        if item.Box and item.Box.Parent and item.Glass then
            item.Glass:SetPadding(NotificationConfig.GlassPadding)
        end
    end
end
function NotificationAPI.SetCornerRadius(value)
    NotificationConfig.CornerRadius = math.clamp(math.floor(tonumber(value) or NotificationConfig.CornerRadius), 0, 28)
    for _, item in ipairs(ActiveNotifications) do
        if item.Box and item.Box.Parent and item.Glass then
            item.Glass:SetCornerRadius(NotificationConfig.CornerRadius)
        end
    end
end
function NotificationAPI.GetConfig()
    return {
        GlassVisibility = NotificationConfig.GlassVisibility,
        GlassPadding = NotificationConfig.GlassPadding,
        CornerRadius = NotificationConfig.CornerRadius,
        WhiteAlpha = NotificationConfig.WhiteAlpha,
    }
end
_G.NexusNotifications = NotificationAPI

-- ================================================================
-- Window API
-- ================================================================

local Window = {}
Window.UIElements = {
    Main = MainFrame,
    ContentHost = ContentHost,
    TabBar = TabBar,
    ActiveTabIndicator = GlobalTabIndicator,
}

function Window:Notify(config)
    return NotificationAPI.Show(config)
end

-- ================================================================
-- 页面控制器（按 WindUI TabModule 的核心思路重写）
--
-- WindUI 的页面切换核心是：
-- 1. Tabs[] 保存所有页；Containers[] 保存所有页面容器。
-- 2. SelectedTab 只保存当前 Tab 索引。
-- 3. SelectTab(index) 时先统一取消/隐藏其它页。
-- 4. 目标页设为 Visible，再从 AnchorPoint(0, 0.05) 平滑回到 (0, 0)。
-- 5. 每次选择都重新同步 Tab 的选中状态，并触发 OnChange。
-- ================================================================

local PageController = {
    Tabs = TabPages,
    Containers = {},
    SelectedTab = nil,
    TabCount = 0,
    OnChangeFunc = function(_) end,
    TransitionSerial = 0,
}

local function cancelTabAnimation(tab)
    if not tab then return end
    for key, tween in pairs(tab._Tweens or {}) do
        pcall(function() tween:Cancel() end)
        tab._Tweens[key] = nil
    end
end

local function setTabVisual(tab, selected, instant)
    if not tab or not tab.UIElements.Main or not tab.UIElements.Main.Parent then return end

    local targetTransparency = selected and 0.76 or 0.92
    local targetColor = selected and Color3.fromRGB(255, 255, 255) or Color3.fromRGB(232, 232, 236)

    if instant then
        tab.UIElements.Main.BackgroundTransparency = targetTransparency
        tab.UIElements.Main.TextColor3 = targetColor
        if tab._ButtonScale then tab._ButtonScale.Scale = 1 end
        return
    end

    if tab._ButtonTween then
        pcall(function() tab._ButtonTween:Cancel() end)
    end

    tab._ButtonTween = TweenService:Create(
        tab.UIElements.Main,
        TweenInfo.new(0.15, Enum.EasingStyle.Quad, Enum.EasingDirection.Out),
        {BackgroundTransparency = targetTransparency}
    )
    tab._ButtonTween:Play()
    tab.UIElements.Main.TextColor3 = targetColor

    if tab._ButtonScale then
        TweenService:Create(
            tab._ButtonScale,
            TweenInfo.new(0.15, Enum.EasingStyle.Quad, Enum.EasingDirection.Out),
            {Scale = 1}
        ):Play()
    end
end

local function tabIndicatorY(tab)
    if not tab or not tab.UIElements.Main or not tab.UIElements.Main.Parent or not TabBar.Parent then
        return 0
    end
    return tab.UIElements.Main.AbsolutePosition.Y - TabBar.AbsolutePosition.Y + (tab.UIElements.Main.AbsoluteSize.Y * 0.5)
end

local function syncTabIndicator(tab, animated)
    if not GlobalTabIndicator.Parent or not tab or not tab.UIElements.Main or not tab.UIElements.Main.Parent then
        return
    end

    local targetY = tabIndicatorY(tab)
    local targetPosition = UDim2.fromOffset(2, targetY)

    if not GlobalTabIndicator.Visible then
        GlobalTabIndicator.Position = targetPosition
        GlobalTabIndicator.Size = UDim2.fromOffset(4, 24)
        GlobalTabIndicator.Visible = true
        return
    end

    PageController.IndicatorSerial = (PageController.IndicatorSerial or 0) + 1
    local serial = PageController.IndicatorSerial

    if not animated then
        GlobalTabIndicator.Position = targetPosition
        GlobalTabIndicator.Size = UDim2.fromOffset(4, 24)
        return
    end

    local jumpTween = TweenService:Create(
        GlobalTabIndicator,
        TweenInfo.new(0.10, Enum.EasingStyle.Quart, Enum.EasingDirection.Out),
        {
            Position = UDim2.fromOffset(2, targetY - 4),
            Size = UDim2.fromOffset(4, 18),
        }
    )
    jumpTween:Play()

    task.delay(0.10, function()
        if serial ~= PageController.IndicatorSerial
            or PageController.SelectedTab ~= tab.Index
            or not GlobalTabIndicator.Parent then
            return
        end

        local dropTween = TweenService:Create(
            GlobalTabIndicator,
            TweenInfo.new(0.10, Enum.EasingStyle.Quart, Enum.EasingDirection.Out),
            {
                Position = UDim2.fromOffset(2, targetY + 2),
                Size = UDim2.fromOffset(4, 27),
            }
        )
        dropTween:Play()

        task.delay(0.10, function()
            if serial ~= PageController.IndicatorSerial
                or PageController.SelectedTab ~= tab.Index
                or not GlobalTabIndicator.Parent then
                return
            end

            TweenService:Create(
                GlobalTabIndicator,
                TweenInfo.new(0.10, Enum.EasingStyle.Quad, Enum.EasingDirection.Out),
                {
                    Position = targetPosition,
                    Size = UDim2.fromOffset(4, 24),
                }
            ):Play()
        end)
    end)
end

function PageController:OnChange(callback)
    if type(callback) == "function" then
        self.OnChangeFunc = callback
    end
end

function PageController:Register(tab)
    self.TabCount += 1
    tab.Index = self.TabCount
    tab.Selected = false
    tab.Locked = tab.Locked == true
    tab._Tweens = tab._Tweens or {}
    self.Tabs[tab.Index] = tab
    self.Containers[tab.Index] = tab.Page
    return tab.Index
end

function PageController:SelectTab(tabIndex, silent)
    tabIndex = tonumber(tabIndex)
    local target = tabIndex and self.Tabs[tabIndex]

    -- 完整判断：目标不存在 / 页面不存在 / 已锁定 / 已销毁时直接拒绝。
    if target == nil then return false end
    if target.Locked then return false end
    if target.Page == nil or target.Page.Parent == nil then return false end
    if target.UIElements == nil or target.UIElements.Main == nil or target.UIElements.Main.Parent == nil then return false end
    if ScreenGui == nil or ScreenGui.Parent == nil then return false end

    self.TransitionSerial += 1
    local serial = self.TransitionSerial
    self.SelectedTab = target.Index

    -- 完全仿照 WindUI 的容器逻辑：先处理全部页，再只打开目标页。
    for _, tab in ipairs(self.Tabs) do
        if tab then
            cancelTabAnimation(tab)
            tab.Selected = false

            if tab.Page and tab.Page.Parent then
                tab.Page.Active = false
                tab.Page.Visible = false
                tab.Page.ZIndex = 11
                tab.Page.AnchorPoint = Vector2.new(0, 0.05)
            end

            setTabVisual(tab, false, true)
        end
    end

    target.Selected = true
    target.Page.Visible = true
    target.Page.Active = true
    target.Page.ZIndex = 20
    target.Page.AnchorPoint = Vector2.new(0, 0.05)

    setTabVisual(target, true, true)
    syncTabIndicator(target, true)

    -- 保持每个页面自己的滚动位置；这里只清理“错误残留”的旧位置。
    local pagePosition = target.Page.Position
    target.Page.Position = UDim2.new(pagePosition.X.Scale, pagePosition.X.Offset, 0, pagePosition.Y.Offset)

    -- WindUI 风格：AnchorPoint 从 0.05 平滑回到 0。
    local pageTween = TweenService:Create(
        target.Page,
        TweenInfo.new(0.15, Enum.EasingStyle.Quart, Enum.EasingDirection.Out),
        {AnchorPoint = Vector2.new(0, 0)}
    )
    target._Tweens.Page = pageTween
    pageTween:Play()

    -- 页面切换动画期间仍保证其它页面不可交互。
    task.delay(0.18, function()
        if serial ~= self.TransitionSerial
            or self.SelectedTab ~= target.Index
            or not target.Page.Parent then
            return
        end

        for _, tab in ipairs(self.Tabs) do
            if tab and tab ~= target and tab.Page and tab.Page.Parent then
                tab.Page.Visible = false
                tab.Page.Active = false
                tab.Page.ZIndex = 11
            end
        end
        target.Page.Visible = true
        target.Page.Active = true
        target.Page.ZIndex = 20
        target.Page.AnchorPoint = Vector2.new(0, 0)
        syncTabIndicator(target, false)
    end)

    if not silent then
        pcall(function()
            self.OnChangeFunc(target.Index, target)
        end)
    end

    return true
end

function PageController:GetSelectedTab()
    return self.SelectedTab and self.Tabs[self.SelectedTab] or nil
end

Window.SelectTab = function(_, tabOrIndex, silent)
    local index = tabOrIndex
    if type(tabOrIndex) == "table" then
        index = tabOrIndex.Index
    end
    return PageController:SelectTab(index, silent == true)
end

Window.OnTabChanged = function(_, callback)
    return PageController:OnChange(callback)
end
Window.PageController = PageController

function Window:Tab(config)
    config = config or {}
    local title = tostring(config.Title or "Tab")

    local page = Instance.new("ScrollingFrame")
    page.Name = "Tab_" .. tostring(#TabPages + 1)
    page.Size = UDim2.fromScale(1, 1)
    page.BackgroundTransparency = 1
    page.BorderSizePixel = 0
    page.ScrollBarThickness = 3
    page.ScrollBarImageTransparency = 0.55
    page.Active = false
    page.Visible = false
    page.ZIndex = 11
    page.AnchorPoint = Vector2.new(0, 0.05)
    page.AutomaticCanvasSize = Enum.AutomaticSize.Y
    page.CanvasSize = UDim2.new(0, 0, 0, 0)
    page.Parent = ContentHost

    local pageScale = Instance.new("UIScale")
    pageScale.Scale = 1
    pageScale.Parent = page

    local list = Instance.new("UIListLayout")
    list.Padding = UDim.new(0, 9)
    list.SortOrder = Enum.SortOrder.LayoutOrder
    list.Parent = page

    local padding = Instance.new("UIPadding")
    padding.PaddingBottom = UDim.new(0, 8)
    padding.Parent = page

    local function refreshCanvas()
        if not page.Parent then return end
        local h = math.max(list.AbsoluteContentSize.Y + 12, page.AbsoluteSize.Y + 1)
        page.CanvasSize = UDim2.fromOffset(0, h)
    end
    list:GetPropertyChangedSignal("AbsoluteContentSize"):Connect(refreshCanvas)

    local tabButton = Instance.new("TextButton")
    tabButton.Name = "TabButton"
    tabButton.Size = UDim2.new(1, -5, 0, 36)
    tabButton.BackgroundColor3 = Color3.fromRGB(255, 255, 255)
    tabButton.BackgroundTransparency = 0.92
    tabButton.Text = title
    tabButton.TextColor3 = Color3.fromRGB(232, 232, 236)
    tabButton.TextSize = 13
    tabButton.Font = Enum.Font.GothamMedium
    tabButton.TextXAlignment = Enum.TextXAlignment.Left
    tabButton.AutoButtonColor = false
    tabButton.Active = true
    tabButton.Selectable = true
    tabButton.ZIndex = 12
    tabButton.Parent = TabBar
    addCorner(tabButton, 8)

    local tabPad = Instance.new("UIPadding")
    tabPad.PaddingLeft = UDim.new(0, 12)
    tabPad.Parent = tabButton

    local Tab = {}
    Tab.Page = page
    Tab.UIElements = {Main = tabButton}
    Tab.Scale = pageScale
    Tab.Title = title
    Tab.Icon = config.Icon
    Tab.Locked = config.Locked == true
    Tab._Tweens = {}
    Tab._ElementOrder = 0

    local tabButtonScale = Instance.new("UIScale")
    tabButtonScale.Scale = 1
    tabButtonScale.Parent = tabButton
    Tab._ButtonScale = tabButtonScale

    local registeredIndex = PageController:Register(Tab)

    local function requestActivate()
        return PageController:SelectTab(registeredIndex, false)
    end

    tabButton.Activated:Connect(requestActivate)
    tabButton.InputBegan:Connect(function(input)
        if input.UserInputType == Enum.UserInputType.Touch
            or input.UserInputType == Enum.UserInputType.MouseButton1 then
            requestActivate()
        end
    end)

    tabButton.MouseEnter:Connect(function()
        if PageController.SelectedTab ~= Tab.Index then
            TweenService:Create(tabButton, TweenInfo.new(0.09, Enum.EasingStyle.Quad, Enum.EasingDirection.Out), {
                BackgroundTransparency = 0.84
            }):Play()
            TweenService:Create(tabButtonScale, TweenInfo.new(0.09, Enum.EasingStyle.Quad, Enum.EasingDirection.Out), {
                Scale = 1.02
            }):Play()
        end
    end)

    tabButton.MouseLeave:Connect(function()
        if PageController.SelectedTab ~= Tab.Index then
            TweenService:Create(tabButton, TweenInfo.new(0.09, Enum.EasingStyle.Quad, Enum.EasingDirection.Out), {
                BackgroundTransparency = 0.92
            }):Play()
            TweenService:Create(tabButtonScale, TweenInfo.new(0.09, Enum.EasingStyle.Quad, Enum.EasingDirection.Out), {
                Scale = 1
            }):Play()
        end
    end)

    function Tab:Activate(silent)
        return PageController:SelectTab(self.Index, silent == true)
    end

    function Tab:Select(silent)
        return PageController:SelectTab(self.Index, silent == true)
    end

    Tab.Indicator = GlobalTabIndicator

    task.defer(function()
        refreshCanvas()
        if TabLayout and TabLayout.Parent and TabBar and TabBar.Parent then
            TabBar.CanvasSize = UDim2.fromOffset(0, math.max(TabLayout.AbsoluteContentSize.Y + 8, TabBar.AbsoluteSize.Y))
        end

        -- 第一个 Tab 自动成为默认页面。
        -- 原版本虽然成功创建了 Tab 和全部组件，但 page 默认 Visible=false，
        -- 没有默认 SelectTab 时用户只能看到窗口外壳，看不到任何 Section/Toggle 等组件。
        if PageController.SelectedTab == nil and page.Parent ~= nil then
            PageController:SelectTab(registeredIndex, true)
        end
    end)

    local function nextElementOrder()
        Tab._ElementOrder += 1
        return Tab._ElementOrder
    end

    function Tab:Section(sectionConfig)
        sectionConfig = sectionConfig or {}
        local section = Instance.new("TextLabel")
        section.Name = "Section"
        section.Size = UDim2.new(1, -4, 0, 26)
        section.BackgroundTransparency = 1
        section.Text = tostring(sectionConfig.Title or "Section")
        section.TextColor3 = Color3.fromRGB(255, 255, 255)
        section.TextSize = sectionConfig.TextSize or 16
        section.Font = Enum.Font.GothamBold
        section.TextXAlignment = sectionConfig.TextXAlignment == "Center" and Enum.TextXAlignment.Center or Enum.TextXAlignment.Left
        section.LayoutOrder = nextElementOrder()
        section.ZIndex = 12
        section.Parent = page
        return section
    end

    function Tab:Paragraph(paragraphConfig)
        paragraphConfig = paragraphConfig or {}
        local frame = Instance.new("Frame")
        frame.Name = "Paragraph"
        frame.Size = UDim2.new(1, -4, 0, paragraphConfig.Height or 60)
        frame.BackgroundTransparency = 1
        frame.BorderSizePixel = 0
        frame.LayoutOrder = nextElementOrder()
        frame.ZIndex = 12
        frame.Parent = page

        local titleLabel = Instance.new("TextLabel")
        titleLabel.Size = UDim2.new(1, 0, 0, 20)
        titleLabel.BackgroundTransparency = 1
        titleLabel.Text = tostring(paragraphConfig.Title or "")
        titleLabel.TextColor3 = Color3.fromRGB(255, 255, 255)
        titleLabel.TextSize = 13
        titleLabel.Font = Enum.Font.GothamBold
        titleLabel.TextXAlignment = Enum.TextXAlignment.Left
        titleLabel.ZIndex = 13
        titleLabel.Parent = frame

        local descLabel = Instance.new("TextLabel")
        descLabel.Size = UDim2.new(1, 0, 0, (paragraphConfig.Height or 60) - 22)
        descLabel.Position = UDim2.fromOffset(0, 21)
        descLabel.BackgroundTransparency = 1
        descLabel.Text = tostring(paragraphConfig.Desc or "")
        descLabel.TextColor3 = Color3.fromRGB(240, 240, 240)
        descLabel.TextSize = 12
        descLabel.Font = Enum.Font.Gotham
        descLabel.TextWrapped = true
        descLabel.TextXAlignment = Enum.TextXAlignment.Left
        descLabel.TextYAlignment = Enum.TextYAlignment.Top
        descLabel.ZIndex = 13
        descLabel.Parent = frame
        return frame
    end

    function Tab:Button(buttonConfig)
        buttonConfig = buttonConfig or {}
        local btn = Instance.new("TextButton")
        btn.Name = "Button"
        btn.Size = UDim2.new(1, -4, 0, 38)
        btn.BackgroundColor3 = Color3.fromRGB(255, 255, 255)
        btn.BackgroundTransparency = CONTROL_WHITE_ALPHA
        btn.Text = tostring(buttonConfig.Title or "Button")
        btn.TextColor3 = Color3.fromRGB(255, 255, 255)
        btn.TextSize = 14
        btn.Font = Enum.Font.Gotham
        btn.LayoutOrder = nextElementOrder()
        btn.ZIndex = 12
        btn.Parent = page
        addCorner(btn, 8)
        addStroke(btn, CONTROL_STROKE_ALPHA, 1)

        local normal = btn.BackgroundTransparency
        btn.MouseEnter:Connect(function()
            TweenService:Create(btn, TweenInfo.new(0.12), {BackgroundTransparency = math.max(0.72, normal - 0.08)}):Play()
        end)
        btn.MouseLeave:Connect(function()
            TweenService:Create(btn, TweenInfo.new(0.12), {BackgroundTransparency = normal}):Play()
        end)
        btn.MouseButton1Click:Connect(function()
            if type(buttonConfig.Callback) == "function" then
                buttonConfig.Callback()
            end
        end)
        return btn
    end

    -- ================================================================
    -- Keybind 组件：点击按键框后按下键盘按键完成录入；之后按键可切换对应功能。
    -- 支持 Escape 取消录入，Backspace/Delete 清除绑定。
    -- ================================================================
    local NexusKeybindEntries = {}
    local NexusKeybindListening = nil
    local NexusKeybindListeningToken = 0
    local NexusKeybindLastButtonAction = 0
    local NexusKeybindConsumedCode = nil
    local NexusKeybindConsumedUntil = 0

    local function disconnectNexusKeybindConnection()
        pcall(function()
            if _G.NexusKeybindConnection then
                _G.NexusKeybindConnection:Disconnect()
                _G.NexusKeybindConnection = nil
            end
        end)
        pcall(function()
            if _G.NexusKeybindCaptureConnection then
                _G.NexusKeybindCaptureConnection:Disconnect()
                _G.NexusKeybindCaptureConnection = nil
            end
        end)
        pcall(function()
            if _G.NexusKeybindContextBound then
                game:GetService("ContextActionService"):UnbindAction("NexusKeybindCapture")
                _G.NexusKeybindContextBound = nil
            end
            if _G.NexusKeybindDispatchBound then
                game:GetService("ContextActionService"):UnbindAction("NexusKeybindDispatch")
                _G.NexusKeybindDispatchBound = nil
            end
        end)
    end

    disconnectNexusKeybindConnection()
    pcall(function()
        if _G.NexusKeybindDispatchBound then
            game:GetService("ContextActionService"):UnbindAction("NexusKeybindDispatch")
            _G.NexusKeybindDispatchBound = nil
        end
    end)
    _G.NexusKeybindEntries = NexusKeybindEntries

    local function keyCodeDisplay(keyCode)
        if typeof(keyCode) == "EnumItem" and keyCode.EnumType == Enum.KeyCode then
            return keyCode.Name
        end
        return "--"
    end

    local function stopKeybindCapture(entry, restoreText)
        if NexusKeybindListening ~= entry then
            return
        end

        NexusKeybindListening = nil
        NexusKeybindListeningToken += 1
        entry.Listening = false

        pcall(function()
            if _G.NexusKeybindCaptureConnection then
                _G.NexusKeybindCaptureConnection:Disconnect()
                _G.NexusKeybindCaptureConnection = nil
            end
        end)
        pcall(function()
            if _G.NexusKeybindContextBound then
                game:GetService("ContextActionService"):UnbindAction("NexusKeybindCapture")
                _G.NexusKeybindContextBound = nil
            end
        end)

        if restoreText and entry.Button and entry.Button.Parent then
            entry.Button.Text = keyCodeDisplay(entry.KeyCode)
        end
    end

    local function startKeybindCapture(entry)
        if not entry or not entry.Button or not entry.Button.Parent then
            return
        end

        if NexusKeybindListening and NexusKeybindListening ~= entry then
            stopKeybindCapture(NexusKeybindListening, true)
        end

        NexusKeybindListeningToken += 1
        local token = NexusKeybindListeningToken
        NexusKeybindListening = entry
        entry.Listening = true
        entry.Button.Text = "按任意键"

        local function finishCapture(keyCode)
            if NexusKeybindListening ~= entry or not entry.Listening or token ~= NexusKeybindListeningToken then
                return
            end

            if not (typeof(keyCode) == "EnumItem" and keyCode.EnumType == Enum.KeyCode) then
                return
            end

            if keyCode == Enum.KeyCode.Escape then
                stopKeybindCapture(entry, true)
                return
            end

            if keyCode == Enum.KeyCode.Backspace or keyCode == Enum.KeyCode.Delete then
                entry:Set(nil)
                stopKeybindCapture(entry, false)
                if entry.Button and entry.Button.Parent then
                    entry.Button.Text = "--"
                end
                return
            end

            NexusKeybindConsumedCode = keyCode
            NexusKeybindConsumedUntil = os.clock() + 0.20
            entry:Set(keyCode)
            -- 录入这一按不立即触发功能；等待释放后下一次按下才触发。
            entry.WasKeyDown = true
            stopKeybindCapture(entry, false)
        end

        -- 录入期同时使用 ContextActionService 与 UserInputService。
        -- CAS 抢占优先级，避免游戏自身把键盘事件标记为已处理导致录入失败。
        pcall(function()
            local ContextActionService = game:GetService("ContextActionService")
            ContextActionService:BindActionAtPriority(
                "NexusKeybindCapture",
                function(_, inputState, inputObject)
                    if inputState == Enum.UserInputState.Begin and inputObject then
                        finishCapture(inputObject.KeyCode)
                    end
                    return Enum.ContextActionResult.Sink
                end,
                false,
                Enum.ContextActionPriority.High.Value,
                Enum.UserInputType.Keyboard
            )
            _G.NexusKeybindContextBound = true
        end)

        _G.NexusKeybindCaptureConnection = UserInputService.InputBegan:Connect(function(input)
            if NexusKeybindListening ~= entry or not entry.Listening or token ~= NexusKeybindListeningToken then
                return
            end
            if input.UserInputType == Enum.UserInputType.Keyboard then
                finishCapture(input.KeyCode)
            end
        end)
    end

    local function createKeybindControl(parent, config, callback, compact)
        config = config or {}
        local entry = {
            KeyCode = nil,
            Callback = callback,
            ToggleCallback = callback,
            ToggleAPI = nil,
            Button = nil,
            Listening = false,
            Enabled = true,
            WasKeyDown = false,
        }

        local button = Instance.new("TextButton")
        button.Name = "Keybind"
        button.Size = compact and UDim2.fromOffset(58, 24) or UDim2.fromOffset(76, 30)
        button.AnchorPoint = Vector2.new(1, 0.5)
        -- 给按键框留出明确的独立区域，避免与右侧 Toggle 开关重叠。
        button.Position = compact and UDim2.new(1, -112, 0.5, 0) or UDim2.new(1, -8, 0.5, 0)
        button.BackgroundColor3 = Color3.fromRGB(255, 255, 255)
        button.BackgroundTransparency = 0.90
        button.BorderSizePixel = 0
        button.AutoButtonColor = false
        button.Text = "--"
        button.TextColor3 = Color3.fromRGB(255, 255, 255)
        button.TextSize = compact and 10 or 12
        button.Font = Enum.Font.GothamMedium
        button.ZIndex = 18
        button.Parent = parent
        addCorner(button, 7)
        addStroke(button, 0.78, 1)
        entry.Button = button

        local function setButtonText()
            if button and button.Parent and not entry.Listening then
                button.Text = keyCodeDisplay(entry.KeyCode)
            end
        end

        function entry:Set(value)
            if typeof(value) == "EnumItem" and value.EnumType == Enum.KeyCode then
                entry.KeyCode = value
            elseif value == nil or tostring(value) == "" or tostring(value) == "--" then
                entry.KeyCode = nil
            elseif type(value) == "string" then
                local ok, enumValue = pcall(function()
                    return Enum.KeyCode[value]
                end)
                entry.KeyCode = ok and enumValue or nil
            else
                entry.KeyCode = nil
            end
            entry.Listening = false
            pcall(function()
                entry.WasKeyDown = entry.KeyCode ~= nil and UserInputService:IsKeyDown(entry.KeyCode) or false
            end)
            setButtonText()
        end

        function entry:Get()
            return entry.KeyCode
        end

        function entry:Clear()
            entry:Set(nil)
        end

        local function beginListening()
            local now = os.clock()
            if now - NexusKeybindLastButtonAction < 0.06 then
                return
            end
            NexusKeybindLastButtonAction = now
            startKeybindCapture(entry)
        end

        -- Activated 用于触摸/鼠标，MouseButton1Click 作为桌面输入兜底；用时间戳避免双触发。
        button.Activated:Connect(beginListening)
        button.MouseButton1Click:Connect(beginListening)

        button.MouseEnter:Connect(function()
            TweenService:Create(button, TweenInfo.new(0.10, Enum.EasingStyle.Quad, Enum.EasingDirection.Out), {
                BackgroundTransparency = 0.78,
            }):Play()
        end)
        button.MouseLeave:Connect(function()
            TweenService:Create(button, TweenInfo.new(0.10, Enum.EasingStyle.Quad, Enum.EasingDirection.Out), {
                BackgroundTransparency = 0.90,
            }):Play()
        end)

        entry:Set(config.Default)
        table.insert(NexusKeybindEntries, entry)
        return entry
    end

    -- ================================================================
    -- 按键触发：以键盘状态轮询为主，InputBegan / CAS 为辅。
    -- 轮询不依赖 gameProcessed，因此游戏、聊天框等吞输入时仍可触发。
    -- ================================================================
    local NexusKeybindDispatchStamp = {}
    local NexusKeybindPollConnection

    -- 同一按键可以绑定多个功能。
    -- 一次实体按下只处理一次，然后把同键功能作为一个组统一切换：
    -- 全部关闭/部分关闭 -> 全部开启；全部开启 -> 全部关闭。
    local function triggerKeybindGroup(keyCode)
        if not keyCode or keyCode == Enum.KeyCode.Unknown then return end

        local keyName = tostring(keyCode)
        local now = os.clock()
        local last = NexusKeybindDispatchStamp[keyName]
        if last and now - last < 0.10 then
            return false
        end

        local matching = {}
        local allToggleEntries = true
        local hasToggleEntry = false
        local allEnabled = true

        for _, entry in ipairs(NexusKeybindEntries) do
            if entry
                and entry.Enabled
                and not entry.Listening
                and entry.KeyCode
                and tostring(entry.KeyCode) == keyName then
                matching[#matching + 1] = entry

                if entry.ToggleAPI and type(entry.ToggleAPI.Get) == "function" and type(entry.ToggleAPI.Set) == "function" then
                    hasToggleEntry = true
                    if not entry.ToggleAPI:Get() then
                        allEnabled = false
                    end
                else
                    allToggleEntries = false
                end
            end
        end

        if #matching == 0 then
            return false
        end

        NexusKeybindDispatchStamp[keyName] = now

        if hasToggleEntry and allToggleEntries then
            local targetState = not allEnabled
            for _, entry in ipairs(matching) do
                local toggleApi = entry.ToggleAPI
                task.spawn(function()
                    local ok, err = pcall(function()
                        toggleApi:Set(targetState, true)
                    end)
                    if not ok then
                        warn("[Nexus Keybind] 同键功能切换失败:", err)
                    end
                end)
            end
        else
            -- 独立 Keybind 仍保持原来的回调行为。
            -- 若与 Toggle 共用按键，Toggle 组仍会统一切换，独立回调照常执行一次。
            for _, entry in ipairs(matching) do
                if type(entry.Callback) == "function" then
                    local callback = entry.Callback
                    task.spawn(function()
                        local ok, err = pcall(callback)
                        if not ok then
                            warn("[Nexus Keybind] 快捷键触发失败:", err)
                        end
                    end)
                end
            end
        end

        return true
    end

    local function dispatchNexusKeybind(inputObject)
        if not inputObject or inputObject.UserInputType ~= Enum.UserInputType.Keyboard then
            return
        end
        if NexusKeybindListening then
            return
        end

        local keyCode = inputObject.KeyCode
        if keyCode == Enum.KeyCode.Unknown then
            return
        end
        if NexusKeybindConsumedCode == keyCode and os.clock() < NexusKeybindConsumedUntil then
            NexusKeybindConsumedCode = nil
            NexusKeybindConsumedUntil = 0
            for _, entry in ipairs(NexusKeybindEntries) do
                if entry.KeyCode and tostring(entry.KeyCode) == tostring(keyCode) then
                    entry.WasKeyDown = true
                end
            end
            return
        end

        local matched = triggerKeybindGroup(keyCode)
        if matched then
            for _, entry in ipairs(NexusKeybindEntries) do
                if entry.Enabled and entry.KeyCode and tostring(entry.KeyCode) == tostring(keyCode) then
                    entry.WasKeyDown = true
                end
            end
        end
    end

    -- 主通道：检测真正的“按下沿”，避免按住按键不断重复切换。
    NexusKeybindPollConnection = RunService.RenderStepped:Connect(function()
        if NexusKeybindListening then
            return
        end

        for _, entry in ipairs(NexusKeybindEntries) do
            if entry.Enabled and entry.KeyCode then
                local isDown = false
                pcall(function()
                    isDown = UserInputService:IsKeyDown(entry.KeyCode)
                end)

                if isDown and not entry.WasKeyDown then
                    triggerKeybindGroup(entry.KeyCode)
                end

                entry.WasKeyDown = isDown
            else
                entry.WasKeyDown = false
            end
        end
    end)

    -- 事件兜底：忽略 gameProcessed，只处理已经录入的键。
    _G.NexusKeybindConnection = UserInputService.InputBegan:Connect(function(input)
        dispatchNexusKeybind(input)
    end)

    pcall(function()
        local cas = game:GetService("ContextActionService")
        cas:BindActionAtPriority(
            "NexusKeybindDispatch",
            function(_, inputState, inputObject)
                if inputState == Enum.UserInputState.Begin and inputObject then
                    dispatchNexusKeybind(inputObject)
                end
                return Enum.ContextActionResult.Pass
            end,
            false,
            Enum.ContextActionPriority.High.Value,
            Enum.UserInputType.Keyboard
        )
        _G.NexusKeybindDispatchBound = true
    end)

    ScreenGui.Destroying:Connect(function()
        stopKeybindCapture(NexusKeybindListening, false)
        if _G.NexusKeybindEntries == NexusKeybindEntries then
            _G.NexusKeybindEntries = nil
        end
        if _G.NexusKeybindConnection then
            pcall(function() _G.NexusKeybindConnection:Disconnect() end)
            _G.NexusKeybindConnection = nil
        end
        if _G.NexusKeybindDispatchBound then
            pcall(function() game:GetService("ContextActionService"):UnbindAction("NexusKeybindDispatch") end)
            _G.NexusKeybindDispatchBound = nil
        end
        pcall(function()
            if NexusKeybindPollConnection then
                NexusKeybindPollConnection:Disconnect()
                NexusKeybindPollConnection = nil
            end
        end)
        table.clear(NexusKeybindEntries)
    end)

    function Tab:Toggle(toggleConfig)
        toggleConfig = toggleConfig or {}
        local state = toggleConfig.Default == true

        local frame = Instance.new("Frame")
        frame.Name = "Toggle"
        frame.Size = UDim2.new(1, -4, 0, 38)
        frame.BackgroundColor3 = Color3.fromRGB(255, 255, 255)
        frame.BackgroundTransparency = CONTROL_WHITE_ALPHA
        frame.BorderSizePixel = 0
        frame.LayoutOrder = nextElementOrder()
        frame.ZIndex = 12
        frame.Parent = page
        addCorner(frame, 8)
        addStroke(frame, CONTROL_STROKE_ALPHA, 1)

        local hasKeybind = type(toggleConfig.Keybind) == "table"
        local textRightPadding = hasKeybind and 126 or 70

        local text = Instance.new("TextLabel")
        text.Size = UDim2.new(1, -textRightPadding, 1, 0)
        text.Position = UDim2.fromOffset(12, 0)
        text.BackgroundTransparency = 1
        text.Text = tostring(toggleConfig.Title or "Toggle")
        text.TextColor3 = Color3.fromRGB(255, 255, 255)
        text.TextSize = 14
        text.Font = Enum.Font.Gotham
        text.TextXAlignment = Enum.TextXAlignment.Left
        text.ZIndex = 13
        text.Parent = frame

        local switch = Instance.new("Frame")
        switch.Size = UDim2.fromOffset(42, 22)
        switch.Position = UDim2.new(1, -52, 0.5, -11)
        switch.BackgroundColor3 = state and Color3.fromRGB(80, 200, 120) or Color3.fromRGB(120, 120, 120)
        switch.BackgroundTransparency = 0.10
        switch.BorderSizePixel = 0
        switch.ZIndex = 13
        switch.Parent = frame
        addCorner(switch, 999)

        local dot = Instance.new("Frame")
        dot.Size = UDim2.fromOffset(18, 18)
        dot.Position = state and UDim2.new(1, -20, 0.5, -9) or UDim2.fromOffset(2, 2)
        dot.BackgroundColor3 = Color3.fromRGB(255, 255, 255)
        dot.BorderSizePixel = 0
        dot.ZIndex = 14
        dot.Parent = switch
        addCorner(dot, 999)

        local click = Instance.new("TextButton")
        click.Size = UDim2.fromScale(1, 1)
        click.BackgroundTransparency = 1
        click.Text = ""
        click.ZIndex = 15
        click.Parent = frame

        local api = {}
        local keybindApi = nil

        local function setState(value, fireCallback)
            state = value == true
            TweenService:Create(switch, TweenInfo.new(0.18), {
                BackgroundColor3 = state and Color3.fromRGB(80, 200, 120) or Color3.fromRGB(120, 120, 120)
            }):Play()
            TweenService:Create(dot, TweenInfo.new(0.18, Enum.EasingStyle.Quad), {
                Position = state and UDim2.new(1, -20, 0.5, -9) or UDim2.fromOffset(2, 2)
            }):Play()
            if fireCallback and type(toggleConfig.Callback) == "function" then
                toggleConfig.Callback(state)
            end
        end

        function api:Set(value, fire)
            setState(value, fire == true)
        end

        function api:Get()
            return state
        end

        function api:Toggle(fire)
            setState(not state, fire ~= false)
        end

        if hasKeybind then
            keybindApi = createKeybindControl(frame, toggleConfig.Keybind, function()
                api:Toggle(true)
            end, true)
            keybindApi.ToggleAPI = api
            api.Keybind = keybindApi
        end

        click.MouseButton1Click:Connect(function()
            api:Toggle(true)
        end)

        return api
    end

    -- 独立 Keybind 组件：用于需要单独放置按键绑定的页面。
    function Tab:Keybind(keybindConfig)
        keybindConfig = keybindConfig or {}
        local frame = Instance.new("Frame")
        frame.Name = "KeybindRow"
        frame.Size = UDim2.new(1, -4, 0, 42)
        frame.BackgroundColor3 = Color3.fromRGB(255, 255, 255)
        frame.BackgroundTransparency = CONTROL_WHITE_ALPHA
        frame.BorderSizePixel = 0
        frame.LayoutOrder = nextElementOrder()
        frame.ZIndex = 12
        frame.Parent = page
        addCorner(frame, 8)
        addStroke(frame, CONTROL_STROKE_ALPHA, 1)

        local label = Instance.new("TextLabel")
        label.Size = UDim2.new(1, -104, 1, 0)
        label.Position = UDim2.fromOffset(12, 0)
        label.BackgroundTransparency = 1
        label.Text = tostring(keybindConfig.Title or "Keybind")
        label.TextColor3 = Color3.fromRGB(255, 255, 255)
        label.TextSize = 14
        label.Font = Enum.Font.Gotham
        label.TextXAlignment = Enum.TextXAlignment.Left
        label.ZIndex = 13
        label.Parent = frame

        local api = createKeybindControl(frame, keybindConfig, keybindConfig.Callback, false)
        return api
    end

    function Tab:AnimatedSelector(selectorConfig)
        selectorConfig = selectorConfig or {}
        local values = selectorConfig.Values or selectorConfig.Options or {}
        local selected = tostring(selectorConfig.Value or values[1] or "")
        local expanded = false
        local openToken = 0

        local frame = Instance.new("Frame")
        frame.Name = "AnimatedSelector"
        frame.Size = UDim2.new(1, -4, 0, 42)
        frame.BackgroundColor3 = Color3.fromRGB(255, 255, 255)
        frame.BackgroundTransparency = 0.86
        frame.BorderSizePixel = 0
        frame.LayoutOrder = nextElementOrder()
        frame.ZIndex = 30
        frame.Parent = page
        addCorner(frame, 10)

        local label = Instance.new("TextLabel")
        label.Size = UDim2.new(0.52, 0, 1, 0)
        label.Position = UDim2.fromOffset(12, 0)
        label.BackgroundTransparency = 1
        label.Text = tostring(selectorConfig.Title or "样式")
        label.TextColor3 = Color3.fromRGB(255, 255, 255)
        label.TextSize = 13
        label.Font = Enum.Font.GothamMedium
        label.TextXAlignment = Enum.TextXAlignment.Left
        label.ZIndex = 32
        label.Parent = frame

        local selector = Instance.new("TextButton")
        selector.Name = "Value"
        selector.Size = UDim2.new(0.40, -8, 0, 30)
        selector.Position = UDim2.new(0.60, -4, 0.5, -15)
        selector.BackgroundColor3 = Color3.fromRGB(255, 255, 255)
        selector.BackgroundTransparency = 0.18
        selector.BorderSizePixel = 0
        selector.Text = selected
        selector.TextColor3 = Color3.fromRGB(55, 55, 62)
        selector.TextSize = 12
        selector.Font = Enum.Font.GothamMedium
        selector.TextTruncate = Enum.TextTruncate.AtEnd
        selector.AutoButtonColor = false
        selector.ZIndex = 33
        selector.Parent = frame
        addCorner(selector, 8)

        local arrow = Instance.new("TextLabel")
        arrow.Size = UDim2.fromOffset(18, 20)
        arrow.AnchorPoint = Vector2.new(1, 0.5)
        arrow.Position = UDim2.new(1, -7, 0.5, 0)
        arrow.BackgroundTransparency = 1
        arrow.Text = "⌄"
        arrow.TextColor3 = Color3.fromRGB(95, 95, 102)
        arrow.TextSize = 14
        arrow.Font = Enum.Font.GothamBold
        arrow.ZIndex = 34
        arrow.Parent = selector

        local popup = Instance.new("ScrollingFrame")
        popup.Name = "StyleOptions"
        popup.Size = UDim2.fromOffset(math.max(180, frame.AbsoluteSize.X), math.min(190, math.max(34, #values * 34 + 8)))
        popup.BackgroundColor3 = Color3.fromRGB(255, 255, 255)
        popup.BackgroundTransparency = 0.14
        popup.BorderSizePixel = 0
        popup.ScrollBarThickness = 2
        popup.ScrollBarImageTransparency = 0.7
        popup.Active = true
        popup.Visible = false
        popup.ZIndex = 200
        popup.Parent = ContentHost
        addCorner(popup, 10)

        local popupScale = Instance.new("UIScale")
        popupScale.Scale = 0.90
        popupScale.Parent = popup

        local popupLayout = Instance.new("UIListLayout")
        popupLayout.Padding = UDim.new(0, 3)
        popupLayout.SortOrder = Enum.SortOrder.LayoutOrder
        popupLayout.Parent = popup

        local function updatePopupPosition()
            if not popup.Parent or not frame.Parent then return end
            local relative = frame.AbsolutePosition - ContentHost.AbsolutePosition
            popup.Position = UDim2.fromOffset(relative.X, relative.Y + frame.AbsoluteSize.Y + 6)
            popup.Size = UDim2.fromOffset(math.max(frame.AbsoluteSize.X, 180), math.min(190, math.max(34, #values * 34 + 8)))
        end

        local function refreshCanvasForPopup()
            local baseY = popupLayout.AbsoluteContentSize.Y
            local selectorLocalY = frame.AbsolutePosition.Y - page.AbsolutePosition.Y + page.CanvasPosition.Y
            local neededBottom = selectorLocalY + frame.AbsoluteSize.Y + 6 + math.min(190, math.max(34, #values * 34 + 8)) + 12
            local contentHeight = math.max(baseY + 10, neededBottom)
            local current = page.CanvasSize.Y.Offset
            page.CanvasSize = UDim2.fromOffset(0, math.max(current, contentHeight))
            task.defer(function()
                if not expanded or not page.Parent then return end
                local viewportBottom = page.CanvasPosition.Y + page.AbsoluteSize.Y
                local requiredBottom = selectorLocalY + frame.AbsoluteSize.Y + 6 + math.min(190, math.max(34, #values * 34 + 8))
                local targetY = page.CanvasPosition.Y
                if requiredBottom > viewportBottom - 8 then
                    targetY = math.min(math.max(0, page.CanvasSize.Y.Offset - page.AbsoluteSize.Y), requiredBottom - page.AbsoluteSize.Y + 12)
                end
                if targetY > page.CanvasPosition.Y then
                    TweenService:Create(page, TweenInfo.new(0.22, Enum.EasingStyle.Quint, Enum.EasingDirection.Out), {
                        CanvasPosition = Vector2.new(page.CanvasPosition.X, targetY),
                    }):Play()
                end
                task.defer(updatePopupPosition)
            end)
        end

        local function setSelected(value, fire)
            selected = tostring(value)
            selector.Text = selected
            if fire and type(selectorConfig.Callback) == "function" then
                selectorConfig.Callback(selected)
            end
        end

        local optionButtons = {}
        for i, value in ipairs(values) do
            local option = Instance.new("TextButton")
            option.Name = "Option_" .. tostring(i)
            option.Size = UDim2.new(1, -8, 0, 31)
            option.Position = UDim2.fromOffset(4, 0)
            option.BackgroundColor3 = Color3.fromRGB(255, 255, 255)
            option.BackgroundTransparency = 0.18
            option.BorderSizePixel = 0
            option.Text = tostring(value)
            option.TextColor3 = Color3.fromRGB(60, 60, 68)
            option.TextSize = 12
            option.Font = Enum.Font.GothamMedium
            option.AutoButtonColor = false
            option.ZIndex = 202
            option.Parent = popup
            addCorner(option, 7)
            optionButtons[i] = option

            option.Activated:Connect(function()
                setSelected(value, true)
                expanded = false
                openToken += 1
                local token = openToken
                TweenService:Create(popupScale, TweenInfo.new(0.13, Enum.EasingStyle.Quint, Enum.EasingDirection.In), {Scale = 0.90}):Play()
                TweenService:Create(popup, TweenInfo.new(0.13, Enum.EasingStyle.Quad, Enum.EasingDirection.In), {BackgroundTransparency = 1}):Play()
                task.delay(0.13, function()
                    if token == openToken then
                        popup.Visible = false
                        arrow.Text = "⌄"
                    end
                end)
            end)

            option.MouseEnter:Connect(function()
                TweenService:Create(option, TweenInfo.new(0.10, Enum.EasingStyle.Quad, Enum.EasingDirection.Out), {BackgroundTransparency = 0.02}):Play()
            end)
            option.MouseLeave:Connect(function()
                TweenService:Create(option, TweenInfo.new(0.10, Enum.EasingStyle.Quad, Enum.EasingDirection.Out), {BackgroundTransparency = 0.18}):Play()
            end)
        end

        popupLayout:GetPropertyChangedSignal("AbsoluteContentSize"):Connect(function()
            popup.CanvasSize = UDim2.fromOffset(0, popupLayout.AbsoluteContentSize.Y + 6)
            if expanded then
                refreshCanvasForPopup()
            end
        end)

        local function setExpanded(value)
            expanded = value
            openToken += 1
            local token = openToken
            if expanded then
                popup.Visible = true
                arrow.Text = "⌃"
                popupScale.Scale = 0.90
                popup.BackgroundTransparency = 1
                updatePopupPosition()
                refreshCanvasForPopup()
                TweenService:Create(popupScale, TweenInfo.new(0.22, Enum.EasingStyle.Back, Enum.EasingDirection.Out), {Scale = 1}):Play()
                TweenService:Create(popup, TweenInfo.new(0.18, Enum.EasingStyle.Quad, Enum.EasingDirection.Out), {BackgroundTransparency = 0.14}):Play()
                for i, option in ipairs(optionButtons) do
                    option.BackgroundTransparency = 1
                    task.delay((i - 1) * 0.018, function()
                        if expanded and token == openToken and option.Parent then
                            TweenService:Create(option, TweenInfo.new(0.16, Enum.EasingStyle.Quint, Enum.EasingDirection.Out), {BackgroundTransparency = 0.18}):Play()
                        end
                    end)
                end
            else
                arrow.Text = "⌄"
                TweenService:Create(popupScale, TweenInfo.new(0.14, Enum.EasingStyle.Quint, Enum.EasingDirection.In), {Scale = 0.90}):Play()
                TweenService:Create(popup, TweenInfo.new(0.12, Enum.EasingStyle.Quad, Enum.EasingDirection.In), {BackgroundTransparency = 1}):Play()
                task.delay(0.14, function()
                    if token == openToken and popup.Parent then
                        popup.Visible = false
                    end
                end)
            end
        end

        selector.Activated:Connect(function()
            setExpanded(not expanded)
        end)

        page:GetPropertyChangedSignal("CanvasPosition"):Connect(function()
            if expanded then
                task.defer(updatePopupPosition)
            end
        end)
        frame:GetPropertyChangedSignal("AbsolutePosition"):Connect(function()
            if expanded then
                task.defer(updatePopupPosition)
            end
        end)
        ContentHost:GetPropertyChangedSignal("AbsolutePosition"):Connect(function()
            if expanded then
                task.defer(updatePopupPosition)
            end
        end)

        local api = {}
        function api:Set(value, fire)
            setSelected(value, fire == true)
        end
        function api:Get()
            return selected
        end
        function api:Close()
            if expanded then setExpanded(false) end
        end
        return api
    end

    -- 所有普通 Dropdown 与 UI样式页 AnimatedSelector 统一使用同一套弹出动画。
    -- 这样其它页面的功能选择器也会拥有：缩放Q弹、淡入、错峰选项、悬停动画、收回动画。
    function Tab:Dropdown(dropdownConfig)
        dropdownConfig = dropdownConfig or {}
        return self:AnimatedSelector({
            Title = dropdownConfig.Title or "Dropdown",
            Values = dropdownConfig.Values or dropdownConfig.Options or {},
            Value = dropdownConfig.Value,
            Callback = dropdownConfig.Callback,
        })
    end

    function Tab:Input(inputConfig)
        inputConfig = inputConfig or {}
        local box = Instance.new("TextBox")
        box.Name = "Input"
        box.Size = UDim2.new(1, -4, 0, 38)
        box.BackgroundColor3 = Color3.fromRGB(255, 255, 255)
        box.BackgroundTransparency = CONTROL_WHITE_ALPHA
        box.BorderSizePixel = 0
        box.PlaceholderText = tostring(inputConfig.Placeholder or "请输入...")
        box.Text = tostring(inputConfig.Default or "")
        box.TextColor3 = Color3.fromRGB(255, 255, 255)
        box.PlaceholderColor3 = Color3.fromRGB(190, 190, 190)
        box.TextSize = 14
        box.Font = Enum.Font.Gotham
        box.LayoutOrder = nextElementOrder()
        box.ZIndex = 12
        box.Parent = page
        addCorner(box, 8)
        addStroke(box, CONTROL_STROKE_ALPHA, 1)

        box.FocusLost:Connect(function(enterPressed)
            if type(inputConfig.Callback) == "function" then
                inputConfig.Callback(box.Text, enterPressed)
            end
        end)
        return box
    end

    function Tab:Slider(sliderConfig)
        sliderConfig = sliderConfig or {}
        local minValue = tonumber(sliderConfig.Value and sliderConfig.Value.Min) or 0
        local maxValue = tonumber(sliderConfig.Value and sliderConfig.Value.Max) or 100
        local value = tonumber(sliderConfig.Value and sliderConfig.Value.Default) or minValue
        local increment = tonumber(sliderConfig.Increment) or 1

        local frame = Instance.new("Frame")
        frame.Name = "Slider"
        frame.Size = UDim2.new(1, -4, 0, 50)
        frame.BackgroundColor3 = Color3.fromRGB(255, 255, 255)
        frame.BackgroundTransparency = CONTROL_WHITE_ALPHA
        frame.BorderSizePixel = 0
        frame.LayoutOrder = nextElementOrder()
        frame.ZIndex = 12
        frame.Parent = page
        addCorner(frame, 8)
        addStroke(frame, CONTROL_STROKE_ALPHA, 1)

        local label = Instance.new("TextLabel")
        label.Size = UDim2.new(0.62, 0, 0, 20)
        label.Position = UDim2.fromOffset(12, 6)
        label.BackgroundTransparency = 1
        label.Text = tostring(sliderConfig.Title or "Slider")
        label.TextColor3 = Color3.fromRGB(255, 255, 255)
        label.TextSize = 13
        label.Font = Enum.Font.Gotham
        label.TextXAlignment = Enum.TextXAlignment.Left
        label.ZIndex = 13
        label.Parent = frame

        local valueLabel = Instance.new("TextLabel")
        valueLabel.Size = UDim2.new(0.30, 0, 0, 20)
        valueLabel.Position = UDim2.new(0.70, -12, 0, 6)
        valueLabel.BackgroundTransparency = 1
        valueLabel.TextColor3 = Color3.fromRGB(235, 235, 235)
        valueLabel.TextSize = 13
        valueLabel.Font = Enum.Font.Gotham
        valueLabel.TextXAlignment = Enum.TextXAlignment.Right
        valueLabel.ZIndex = 13
        valueLabel.Parent = frame

        local track = Instance.new("Frame")
        track.Size = UDim2.new(1, -24, 0, 6)
        track.Position = UDim2.new(0, 12, 1, -14)
        track.BackgroundColor3 = Color3.fromRGB(150, 150, 150)
        track.BackgroundTransparency = 0.18
        track.BorderSizePixel = 0
        track.ZIndex = 13
        track.Parent = frame
        addCorner(track, 999)

        local fill = Instance.new("Frame")
        fill.BackgroundColor3 = Color3.fromRGB(120, 160, 255)
        fill.BorderSizePixel = 0
        fill.ZIndex = 14
        fill.Parent = track
        addCorner(fill, 999)

        local function snap(v)
            local steps = math.floor(((v - minValue) / increment) + 0.5)
            return math.clamp(minValue + steps * increment, minValue, maxValue)
        end

        local function setValue(v, fire)
            value = snap(clampNumber(v, minValue, maxValue))
            local ratio = (value - minValue) / math.max(maxValue - minValue, 0.0001)
            fill.Size = UDim2.new(ratio, 0, 1, 0)
            valueLabel.Text = tostring(value)
            if fire and type(sliderConfig.Callback) == "function" then
                sliderConfig.Callback(value)
            end
        end

        local dragging = false
        local function updateFromInput(input)
            local width = math.max(track.AbsoluteSize.X, 1)
            local pos = math.clamp((input.Position.X - track.AbsolutePosition.X) / width, 0, 1)
            setValue(minValue + (maxValue - minValue) * pos, true)
        end

        track.InputBegan:Connect(function(input)
            if input.UserInputType == Enum.UserInputType.MouseButton1 or input.UserInputType == Enum.UserInputType.Touch then
                dragging = true
                updateFromInput(input)
            end
        end)

        UserInputService.InputChanged:Connect(function(input)
            if dragging and (input.UserInputType == Enum.UserInputType.MouseMovement or input.UserInputType == Enum.UserInputType.Touch) then
                updateFromInput(input)
            end
        end)

        UserInputService.InputEnded:Connect(function(input)
            if input.UserInputType == Enum.UserInputType.MouseButton1 or input.UserInputType == Enum.UserInputType.Touch then
                dragging = false
            end
        end)

        setValue(value, false)

        local api = {}
        function api:Set(v, fire)
            setValue(v, fire == true)
        end
        function api:Get()
            return value
        end
        return api
    end

    function Tab:Code(config)
        config = config or {}
        local box = Instance.new("TextLabel")
        box.Name = "Code"
        box.Size = UDim2.new(1, -4, 0, config.Height or 90)
        box.BackgroundColor3 = Color3.fromRGB(255, 255, 255)
        box.BackgroundTransparency = 0.90
        box.BorderSizePixel = 0
        box.Text = tostring(config.Code or "")
        box.TextColor3 = Color3.fromRGB(240, 240, 240)
        box.TextSize = 12
        box.Font = Enum.Font.Code
        box.TextWrapped = true
        box.TextXAlignment = Enum.TextXAlignment.Left
        box.TextYAlignment = Enum.TextYAlignment.Top
        box.LayoutOrder = nextElementOrder()
        box.ZIndex = 12
        box.Parent = page
        addCorner(box, 8)
        addStroke(box, 0.90, 1)
        local pad = Instance.new("UIPadding")
        pad.PaddingTop = UDim.new(0, 8)
        pad.PaddingBottom = UDim.new(0, 8)
        pad.PaddingLeft = UDim.new(0, 8)
        pad.PaddingRight = UDim.new(0, 8)
        pad.Parent = box
        return box
    end

    function Tab:Hide()
        page.Visible = false
        tabButton.Visible = false
    end

    return Tab
end

function Window:Tag(config)
    config = config or {}
    local tag = Instance.new("TextLabel")
    tag.Name = "Tag"
    tag.AutomaticSize = Enum.AutomaticSize.X
    tag.Size = UDim2.fromOffset(0, 24)
    tag.BackgroundColor3 = Color3.fromRGB(255, 255, 255)
    tag.BackgroundTransparency = 0.84
    tag.Text = "  " .. tostring(config.Title or "Tag") .. "  "
    tag.TextColor3 = config.Color or Color3.fromRGB(255, 255, 255)
    tag.TextSize = 12
    tag.Font = Enum.Font.GothamMedium
    tag.ZIndex = 20
    tag.Parent = TitleBar
    addCorner(tag, 7)
    addStroke(tag, 0.92, 1)

    local count = #TitleBar:GetChildren()
    tag.Position = UDim2.new(1, -132 - ((count - 2) * 82), 0, 0.5)
    tag.AnchorPoint = Vector2.new(1, 0.5)

    local api = {}
    function api:SetTitle(textValue)
        tag.Text = "  " .. tostring(textValue) .. "  "
    end
    function api:SetColor(color)
        if typeof(color) == "Color3" then
            tag.TextColor3 = color
        end
    end
    function api:Destroy()
        tag:Destroy()
    end
    return api
end

local OpenButton
local MenuVisible = true

function Window:EditOpenButton(config)
    -- 旧 WindUI 的悬浮打开按钮已移除。现在统一通过顶部灵动岛打开/隐藏主 UI。
    return nil
end

-- ================================================================
-- 主UI拖拽
-- ================================================================

local draggingMain = false
local mainDragStart
local mainStartPos

TitleBar.InputBegan:Connect(function(input)
    if input.UserInputType == Enum.UserInputType.MouseButton1 or input.UserInputType == Enum.UserInputType.Touch then
        draggingMain = true
        mainDragStart = input.Position
        mainStartPos = MainFrame.Position
    end
end)

UserInputService.InputChanged:Connect(function(input)
    if draggingMain and (input.UserInputType == Enum.UserInputType.MouseMovement or input.UserInputType == Enum.UserInputType.Touch) then
        local delta = input.Position - mainDragStart
        MainFrame.Position = UDim2.new(
            mainStartPos.X.Scale,
            mainStartPos.X.Offset + delta.X,
            mainStartPos.Y.Scale,
            mainStartPos.Y.Offset + delta.Y
        )
    end
end)

UserInputService.InputEnded:Connect(function(input)
    if input.UserInputType == Enum.UserInputType.MouseButton1 or input.UserInputType == Enum.UserInputType.Touch then
        draggingMain = false
    end
end)

-- 主 UI 状态由灵动岛控制；这里先注册状态，实际按钮事件在灵动岛建立后绑定。

-- ================================================================
-- 灵动岛：完全移除原本磨砂玻璃，只使用白色 Bloom + 透明主体
-- ================================================================

local IslandGui = Instance.new("ScreenGui")
IslandGui.Name = "NexusDynamicIsland"
IslandGui.ResetOnSpawn = false
IslandGui.IgnoreGuiInset = true
IslandGui.ZIndexBehavior = Enum.ZIndexBehavior.Global
IslandGui.DisplayOrder = 100001
if not safeParent(IslandGui, CoreGui) then
    IslandGui.Parent = PlayerGui
end

local Island = Instance.new("Frame")
Island.Name = "Island"
Island.AnchorPoint = Vector2.new(0.5, 0)
Island.Position = UDim2.new(0.5, 0, 0, ISLAND_TOP_Y)
Island.Size = UDim2.fromOffset(ISLAND_COLLAPSED_WIDTH, ISLAND_COLLAPSED_HEIGHT)
Island.BackgroundTransparency = 1
Island.BorderSizePixel = 0
Island.ClipsDescendants = false
Island.ZIndex = 300
Island.Parent = IslandGui

local IslandCorner = addCorner(Island, ISLAND_CORNER_RADIUS)
local IslandStroke = addStroke(Island, 0.82, 1)
IslandStroke.Color = Color3.fromRGB(255, 255, 255)

local IslandConfig = {
    CornerRadius = ISLAND_CORNER_RADIUS,
    Edge = 42,
}

local function clampIslandRadius(value)
    local maxRadius = math.max(8, math.floor(math.min(Island.AbsoluteSize.X, Island.AbsoluteSize.Y) * 0.5))
    return math.clamp(math.floor(tonumber(value) or 24), 6, maxRadius)
end

local function applyIslandAppearance()
    IslandConfig.CornerRadius = clampIslandRadius(IslandConfig.CornerRadius)
    local radius = IslandConfig.CornerRadius
    IslandCorner.CornerRadius = UDim.new(0, radius)
    IslandStroke.Transparency = math.clamp(1 - (IslandConfig.Edge / 100), 0.34, 0.88)
end

local IslandBrand = Instance.new("TextLabel")
IslandBrand.Name = "Brand"
IslandBrand.Position = UDim2.fromOffset(18, 0)
IslandBrand.Size = UDim2.new(0.55, 0, 1, 0)
IslandBrand.BackgroundTransparency = 1
IslandBrand.Text = "SyntaxNext"
IslandBrand.TextColor3 = Color3.fromRGB(255, 255, 255)
IslandBrand.TextSize = 13
IslandBrand.Font = Enum.Font.GothamBold
IslandBrand.TextXAlignment = Enum.TextXAlignment.Left
IslandBrand.ZIndex = 306
IslandBrand.Parent = Island

local IslandFPS = Instance.new("TextLabel")
IslandFPS.Name = "FPS"
IslandFPS.AnchorPoint = Vector2.new(1, 0)
IslandFPS.Position = UDim2.new(1, -16, 0, 0)
IslandFPS.Size = UDim2.new(0.36, 0, 1, 0)
IslandFPS.BackgroundTransparency = 1
IslandFPS.Text = "60 FPS"
IslandFPS.TextColor3 = Color3.fromRGB(255, 255, 255)
IslandFPS.TextSize = 12
IslandFPS.Font = Enum.Font.GothamMedium
IslandFPS.TextXAlignment = Enum.TextXAlignment.Right
IslandFPS.ZIndex = 306
IslandFPS.Parent = Island

local IslandStatus = Instance.new("TextLabel")
IslandStatus.Name = "Status"
IslandStatus.AnchorPoint = Vector2.new(0.5, 0)
IslandStatus.Position = UDim2.new(0.5, 0, 0, 8)
IslandStatus.Size = UDim2.fromOffset(220, 21)
IslandStatus.BackgroundTransparency = 1
IslandStatus.Text = "功能已开启"
IslandStatus.TextColor3 = Color3.fromRGB(255, 255, 255)
IslandStatus.TextSize = 14
IslandStatus.Font = Enum.Font.GothamBold
IslandStatus.TextXAlignment = Enum.TextXAlignment.Center
IslandStatus.TextTransparency = 1
IslandStatus.ZIndex = 307
IslandStatus.Parent = Island

local IslandSwitch = Instance.new("Frame")
IslandSwitch.Name = "SwitchIcon"
IslandSwitch.Size = UDim2.fromOffset(ISLAND_ICON_SIZE, 18)
IslandSwitch.Position = UDim2.fromOffset(16, 40)
IslandSwitch.BackgroundColor3 = Color3.fromRGB(126, 126, 134)
IslandSwitch.BackgroundTransparency = 1
IslandSwitch.BorderSizePixel = 0
IslandSwitch.ZIndex = 307
IslandSwitch.Parent = Island
addCorner(IslandSwitch, 999)

local IslandSwitchDot = Instance.new("Frame")
IslandSwitchDot.Name = "Dot"
IslandSwitchDot.Size = UDim2.fromOffset(14, 14)
IslandSwitchDot.Position = UDim2.fromOffset(2, 2)
IslandSwitchDot.BackgroundColor3 = Color3.fromRGB(255, 255, 255)
IslandSwitchDot.BackgroundTransparency = 1
IslandSwitchDot.BorderSizePixel = 0
IslandSwitchDot.ZIndex = 308
IslandSwitchDot.Parent = IslandSwitch
addCorner(IslandSwitchDot, 999)

local IslandDetail = Instance.new("TextLabel")
IslandDetail.Name = "Detail"
IslandDetail.Position = UDim2.fromOffset(54, 37)
IslandDetail.Size = UDim2.new(1, -68, 0, 25)
IslandDetail.BackgroundTransparency = 1
IslandDetail.Text = "SyntaxNext"
IslandDetail.TextColor3 = Color3.fromRGB(255, 255, 255)
IslandDetail.TextSize = 12
IslandDetail.Font = Enum.Font.GothamMedium
IslandDetail.TextXAlignment = Enum.TextXAlignment.Left
IslandDetail.TextTransparency = 1
IslandDetail.ZIndex = 307
IslandDetail.Parent = Island

-- 灵动岛文字互斥显示：
-- 收缩态只显示 Brand/FPS；状态态只显示 Status/Detail。
-- 任何切换都先硬切换显示组，再执行 Tween，避免快速开关时出现文字叠加。
local function setIslandTextMode(mode)
    if mode == "status" then
        IslandBrand.TextTransparency = 1
        IslandFPS.TextTransparency = 1
        IslandStatus.TextTransparency = 1
        IslandDetail.TextTransparency = 1
    else
        IslandStatus.TextTransparency = 1
        IslandDetail.TextTransparency = 1
        IslandBrand.TextTransparency = 0
        IslandFPS.TextTransparency = 0
    end
end

local islandExpanded = false
local islandCollapsing = false
local islandStateEnabled = true
local islandToken = 0
local islandTweens = {}
setIslandTextMode("collapsed")

local IslandMotionScale = Instance.new("UIScale")
IslandMotionScale.Name = "MotionScale"
IslandMotionScale.Scale = 1
IslandMotionScale.Parent = Island

-- 双层主体 Bloom：向外扩张覆盖灵动岛四周与圆角区域；两层采用相同高亮透明度。
local IslandBloom16 = Instance.new("ImageLabel")
IslandBloom16.Name = "WhiteBloom16"
IslandBloom16.BackgroundTransparency = 1
IslandBloom16.BorderSizePixel = 0
IslandBloom16.AnchorPoint = Vector2.new(0.5, 0.5)
IslandBloom16.Position = UDim2.fromScale(0.5, 0.5)
IslandBloom16.Size = UDim2.new(1, 180, 1, 108)
IslandBloom16.Image = ISLAND_BLOOM_16
IslandBloom16.ScaleType = Enum.ScaleType.Stretch
IslandBloom16.ImageColor3 = Color3.fromRGB(255, 255, 255)
IslandBloom16.ImageTransparency = 0.58
IslandBloom16.ZIndex = 299
IslandBloom16.Parent = Island

local IslandBloomValue = Instance.new("NumberValue")
IslandBloomValue.Name = "WhiteBloomIntensity"
IslandBloomValue.Value = ISLAND_BLOOM_IN_ALPHA
IslandBloomValue.Parent = Island

local IslandBloom8 = Instance.new("ImageLabel")
IslandBloom8.Name = "WhiteBloom8"
IslandBloom8.BackgroundTransparency = 1
IslandBloom8.BorderSizePixel = 0
IslandBloom8.AnchorPoint = Vector2.new(0.5, 0.5)
IslandBloom8.Position = UDim2.fromScale(0.5, 0.5)
IslandBloom8.Size = UDim2.new(1, 145, 1, 86)
IslandBloom8.Image = ISLAND_BLOOM_8
IslandBloom8.ScaleType = Enum.ScaleType.Stretch
IslandBloom8.ImageColor3 = Color3.fromRGB(255, 255, 255)
IslandBloom8.ImageTransparency = 0.72
IslandBloom8.ZIndex = 299
IslandBloom8.Parent = Island


local function applyIslandBloomAlpha(alpha)
    alpha = math.clamp(tonumber(alpha) or 0, 0, 1)
    -- 两层 Bloom 使用完全相同的透明度，保证灵动岛在所有动画阶段的白色辉光浓度一致。
    -- 数值整体上调亮度，避免回弹/收缩过程中辉光明显变暗。
    local base = math.clamp(ISLAND_BLOOM_BASE_ALPHA + (1 - alpha) * 0.18, 0.24, 0.62)
    IslandBloom16.ImageTransparency = base
    IslandBloom8.ImageTransparency = base
end

IslandBloomValue.Changed:Connect(applyIslandBloomAlpha)
applyIslandBloomAlpha(ISLAND_BLOOM_IN_ALPHA)

local function setIslandBloomAlpha(alpha, duration, easing, direction)
    alpha = math.clamp(tonumber(alpha) or 0, 0, 1)
    if duration and duration > 0 then
        local tw = TweenService:Create(
            IslandBloomValue,
            TweenInfo.new(duration, easing or Enum.EasingStyle.Sine, direction or Enum.EasingDirection.Out),
            {Value = alpha}
        )
        table.insert(islandTweens, tw)
        tw:Play()
        tw.Completed:Connect(function()
            for i, t in ipairs(islandTweens) do
                if t == tw then
                    table.remove(islandTweens, i)
                    break
                end
            end
        end)
        return tw
    end
    IslandBloomValue.Value = alpha
end

local function cancelIslandTweens()
    -- 反向逐个摘除引用后再 Cancel，防止 Completed 回调同步修改 islandTweens
    -- 时导致某些旧 Tween 没有被真正取消。
    for i = #islandTweens, 1, -1 do
        local tween = islandTweens[i]
        islandTweens[i] = nil
        pcall(function() tween:Cancel() end)
    end
end

local function islandTween(instance, info, props)
    local tween = TweenService:Create(instance, info, props)
    table.insert(islandTweens, tween)
    tween:Play()
    tween.Completed:Connect(function()
        for i, t in ipairs(islandTweens) do
            if t == tween then
                table.remove(islandTweens, i)
                break
            end
        end
    end)
    return tween
end

local function setSwitchIcon(enabled, instant)
    local bgColor = enabled and Color3.fromRGB(92, 200, 124) or Color3.fromRGB(126, 126, 134)
    local dotPos = enabled and UDim2.new(1, -16, 0, 2) or UDim2.fromOffset(2, 2)
    if instant then
        IslandSwitch.BackgroundColor3 = bgColor
        IslandSwitchDot.Position = dotPos
        return
    end
    islandTween(IslandSwitch, TweenInfo.new(0.22, Enum.EasingStyle.Quint, Enum.EasingDirection.Out), {
        BackgroundColor3 = bgColor,
    })
    islandTween(IslandSwitchDot, TweenInfo.new(0.24, Enum.EasingStyle.Back, Enum.EasingDirection.Out), {
        Position = dotPos,
    })
end

local function tweenIslandFrame(width, height, y, duration, easing, direction)
    local info = TweenInfo.new(
        duration or 0.42,
        easing or Enum.EasingStyle.Quint,
        direction or Enum.EasingDirection.Out
    )
    return islandTween(Island, info, {
        Position = UDim2.new(0.5, 0, 0, y),
        Size = UDim2.fromOffset(width, height),
    })
end

local function islandBounceIn(token)
    if token ~= islandToken or not Island.Parent then return end
    -- 更明显的 Q 弹：压缩 -> 大回弹 -> 过冲回落 -> 二次小回弹 -> 定型。
    IslandMotionScale.Scale = 0.76
    islandTween(IslandMotionScale, TweenInfo.new(0.22, Enum.EasingStyle.Back, Enum.EasingDirection.Out), {Scale = 1.12})
    task.delay(0.22, function()
        if token ~= islandToken or not Island.Parent then return end
        islandTween(IslandMotionScale, TweenInfo.new(0.11, Enum.EasingStyle.Quad, Enum.EasingDirection.InOut), {Scale = 0.94})
        task.delay(0.11, function()
            if token ~= islandToken or not Island.Parent then return end
            islandTween(IslandMotionScale, TweenInfo.new(0.13, Enum.EasingStyle.Back, Enum.EasingDirection.Out), {Scale = 1.05})
            task.delay(0.13, function()
                if token ~= islandToken or not Island.Parent then return end
                islandTween(IslandMotionScale, TweenInfo.new(0.10, Enum.EasingStyle.Quad, Enum.EasingDirection.InOut), {Scale = 0.985})
                task.delay(0.10, function()
                    if token ~= islandToken or not Island.Parent then return end
                    islandTween(IslandMotionScale, TweenInfo.new(0.12, Enum.EasingStyle.Back, Enum.EasingDirection.Out), {Scale = 1})
                end)
            end)
        end)
    end)
end

local function islandBounceSettle(token)
    if token ~= islandToken or not Island.Parent then return end
    islandTween(IslandMotionScale, TweenInfo.new(0.10, Enum.EasingStyle.Back, Enum.EasingDirection.Out), {Scale = 1.08})
    task.delay(0.10, function()
        if token ~= islandToken or not Island.Parent then return end
        islandTween(IslandMotionScale, TweenInfo.new(0.09, Enum.EasingStyle.Quad, Enum.EasingDirection.InOut), {Scale = 0.94})
        task.delay(0.09, function()
            if token ~= islandToken or not Island.Parent then return end
            islandTween(IslandMotionScale, TweenInfo.new(0.11, Enum.EasingStyle.Back, Enum.EasingDirection.Out), {Scale = 1.03})
            task.delay(0.11, function()
                if token == islandToken and Island.Parent then
                    islandTween(IslandMotionScale, TweenInfo.new(0.10, Enum.EasingStyle.Sine, Enum.EasingDirection.Out), {Scale = 1})
                end
            end)
        end)
    end)
end

local function collapseIsland(token)
    if token ~= islandToken then return end
    islandCollapsing = true
    cancelIslandTweens()

    -- 先强制关闭状态文字，再让静止态文字出现；两组永远不同时可见。
    setIslandTextMode("collapsed")
    islandTween(IslandSwitch, TweenInfo.new(0.12, Enum.EasingStyle.Sine, Enum.EasingDirection.In), {BackgroundTransparency = 1})
    islandTween(IslandSwitchDot, TweenInfo.new(0.12, Enum.EasingStyle.Sine, Enum.EasingDirection.In), {BackgroundTransparency = 1})
    -- 收缩全过程保持统一高亮，只改变形变，不让 Bloom 忽明忽暗。
    setIslandBloomAlpha(1, 0.08, Enum.EasingStyle.Sine, Enum.EasingDirection.Out)

    -- 收缩时做更明显的“压缩 → 超过目标回弹 → 回落 → 小幅回弹 → 定型”。
    IslandMotionScale.Scale = 1
    local frameTween = tweenIslandFrame(
        ISLAND_COLLAPSED_WIDTH,
        ISLAND_COLLAPSED_HEIGHT,
        ISLAND_TOP_Y,
        0.32,
        Enum.EasingStyle.Quint,
        Enum.EasingDirection.InOut
    )

    islandTween(IslandMotionScale, TweenInfo.new(0.09, Enum.EasingStyle.Quad, Enum.EasingDirection.In), {Scale = 0.86})
    task.delay(0.09, function()
        if token ~= islandToken or not Island.Parent then return end
        islandTween(IslandMotionScale, TweenInfo.new(0.17, Enum.EasingStyle.Back, Enum.EasingDirection.Out), {Scale = 1.12})
        task.delay(0.17, function()
            if token ~= islandToken or not Island.Parent then return end
            islandTween(IslandMotionScale, TweenInfo.new(0.10, Enum.EasingStyle.Quad, Enum.EasingDirection.InOut), {Scale = 0.925})
            task.delay(0.10, function()
                if token ~= islandToken or not Island.Parent then return end
                islandTween(IslandMotionScale, TweenInfo.new(0.12, Enum.EasingStyle.Back, Enum.EasingDirection.Out), {Scale = 1.045})
                task.delay(0.12, function()
                    if token ~= islandToken or not Island.Parent then return end
                    islandTween(IslandMotionScale, TweenInfo.new(0.09, Enum.EasingStyle.Quad, Enum.EasingDirection.InOut), {Scale = 0.985})
                    task.delay(0.09, function()
                        if token ~= islandToken or not Island.Parent then return end
                        islandTween(IslandMotionScale, TweenInfo.new(0.11, Enum.EasingStyle.Back, Enum.EasingDirection.Out), {Scale = 1})
                    end)
                end)
            end)
        end)
    end)

    -- collapseIsland 上面已经把状态文字隐藏，因此这里仅恢复静止态 Brand/FPS。
    islandTween(IslandBrand, TweenInfo.new(0.16, Enum.EasingStyle.Sine, Enum.EasingDirection.Out), {TextTransparency = 0})
    islandTween(IslandFPS, TweenInfo.new(0.16, Enum.EasingStyle.Sine, Enum.EasingDirection.Out), {TextTransparency = 0})

    frameTween.Completed:Connect(function(playbackState)
        if token == islandToken and playbackState == Enum.PlaybackState.Completed then
            islandExpanded = false
            islandCollapsing = false
            setIslandTextMode("collapsed")
            setIslandBloomAlpha(ISLAND_BLOOM_IN_ALPHA, 0.12, Enum.EasingStyle.Sine, Enum.EasingDirection.Out)
        end
    end)
end

local function getIslandFeatureWidth(text)
    local ok, measured = pcall(function()
        return TextService:GetTextSize(tostring(text), 12, Enum.Font.GothamMedium, Vector2.new(1000, 24))
    end)
    local width = (ok and measured and measured.X) or (#tostring(text) * 7)
    return math.clamp(math.ceil(width + 98), 250, 430)
end

local function showIsland(status, feature, enabled, detailOverride)
    islandToken += 1
    local token = islandToken
    islandStateEnabled = enabled ~= false
    local wasCollapsing = islandCollapsing
    islandCollapsing = false

    local detailText = tostring(detailOverride or tostring(feature or "SyntaxNext"))
    local nextStatus = tostring(status or (islandStateEnabled and "功能已开启" or "功能已关闭"))
    local targetWidth = getIslandFeatureWidth(detailText)

    cancelIslandTweens()

    if islandExpanded then
        -- 状态态：先强制隐藏静止态文字，防止 SyntaxNext / FPS 与状态文本重叠。
        setIslandTextMode("status")
        IslandStatus.Text = nextStatus
        IslandDetail.Text = detailText
        setSwitchIcon(islandStateEnabled, true)

        islandTween(IslandStatus, TweenInfo.new(0.15, Enum.EasingStyle.Sine, Enum.EasingDirection.Out), {TextTransparency = 0})
        islandTween(IslandDetail, TweenInfo.new(0.17, Enum.EasingStyle.Sine, Enum.EasingDirection.Out), {TextTransparency = 0.04})
        setIslandBloomAlpha(1, 0.10, Enum.EasingStyle.Quad, Enum.EasingDirection.Out)

        if wasCollapsing then
            -- 如果用户在收缩尚未完成时再次开启同一个功能，恢复完整展开尺寸，
            -- 不允许继续停留在半收缩状态。
            tweenIslandFrame(
                targetWidth,
                ISLAND_EXPANDED_HEIGHT,
                ISLAND_EXPANDED_Y,
                0.22,
                Enum.EasingStyle.Quint,
                Enum.EasingDirection.Out
            )
            IslandMotionScale.Scale = math.max(0.90, math.min(IslandMotionScale.Scale, 1.02))
            islandTween(IslandMotionScale, TweenInfo.new(0.13, Enum.EasingStyle.Back, Enum.EasingDirection.Out), {Scale = 1.08})
            task.delay(0.13, function()
                if token ~= islandToken or not Island.Parent then return end
                islandTween(IslandMotionScale, TweenInfo.new(0.09, Enum.EasingStyle.Quad, Enum.EasingDirection.InOut), {Scale = 0.95})
                task.delay(0.09, function()
                    if token ~= islandToken or not Island.Parent then return end
                    islandTween(IslandMotionScale, TweenInfo.new(0.11, Enum.EasingStyle.Back, Enum.EasingDirection.Out), {Scale = 1.025})
                    task.delay(0.11, function()
                        if token == islandToken and Island.Parent then
                            islandTween(IslandMotionScale, TweenInfo.new(0.09, Enum.EasingStyle.Sine, Enum.EasingDirection.Out), {Scale = 1})
                        end
                    end)
                end)
            end)
        else
            islandBounceSettle(token)
        end
    else
        -- 从收缩态展开：先把静止态文字彻底隐藏，再让状态文字淡入。
        setIslandTextMode("status")
        IslandStatus.Text = nextStatus
        IslandDetail.Text = detailText
        IslandSwitch.BackgroundTransparency = 1
        IslandSwitchDot.BackgroundTransparency = 1
        setSwitchIcon(islandStateEnabled, true)

        islandExpanded = true
        setIslandBloomAlpha(1, 0.12, Enum.EasingStyle.Quint, Enum.EasingDirection.Out)

        islandTween(IslandBrand, TweenInfo.new(0.11, Enum.EasingStyle.Sine, Enum.EasingDirection.In), {TextTransparency = 1})
        islandTween(IslandFPS, TweenInfo.new(0.11, Enum.EasingStyle.Sine, Enum.EasingDirection.In), {TextTransparency = 1})

        tweenIslandFrame(
            targetWidth,
            ISLAND_EXPANDED_HEIGHT,
            ISLAND_EXPANDED_Y,
            0.30,
            Enum.EasingStyle.Quint,
            Enum.EasingDirection.Out
        )
        islandBounceIn(token)

        islandTween(IslandStatus, TweenInfo.new(0.19, Enum.EasingStyle.Sine, Enum.EasingDirection.Out), {TextTransparency = 0})
        islandTween(IslandDetail, TweenInfo.new(0.22, Enum.EasingStyle.Sine, Enum.EasingDirection.Out), {TextTransparency = 0.04})
        islandTween(IslandSwitch, TweenInfo.new(0.18, Enum.EasingStyle.Sine, Enum.EasingDirection.Out), {BackgroundTransparency = 0.10})
        islandTween(IslandSwitchDot, TweenInfo.new(0.18, Enum.EasingStyle.Sine, Enum.EasingDirection.Out), {BackgroundTransparency = 0})
    end

    task.delay(ISLAND_AUTO_COLLAPSE, function()
        if token == islandToken then
            collapseIsland(token)
        end
    end)
end

-- 页面切换回调：采用 WindUI TabModule 的 OnChange 思路。
-- 这里不负责创建页面，只负责当前页状态变化后的同步。
PageController:OnChange(function(index, tab)
    if not tab then return end

    if PageMeta and PageMeta.Parent then
        PageMeta.TextTransparency = 0.35
        PageMeta.Text = "SyntaxNext  •  " .. tostring(tab.Title or ("页面 " .. tostring(index))) .. "  /  " .. tostring(index) .. " / " .. tostring(PageController.TabCount)
        TweenService:Create(
            PageMeta,
            TweenInfo.new(0.14, Enum.EasingStyle.Quad, Enum.EasingDirection.Out),
            {TextTransparency = 0.05}
        ):Play()
    end

    if PageStatusDot and PageStatusDot.Parent then
        TweenService:Create(
            PageStatusDot,
            TweenInfo.new(0.12, Enum.EasingStyle.Quad, Enum.EasingDirection.Out),
            {BackgroundTransparency = 0}
        ):Play()
    end

    task.spawn(function()
        pcall(function()
            if showIsland then
                showIsland(
                    "页面已切换",
                    tostring(tab.Title or ("页面 " .. tostring(index))),
                    true,
                    "Page: " .. tostring(tab.Title or index)
                )
            end
        end)
    end)
end)

local IslandHitbox = Instance.new("TextButton")
IslandHitbox.Name = "Interaction"
IslandHitbox.Size = UDim2.fromScale(1, 1)
IslandHitbox.Position = UDim2.fromScale(0, 0)
IslandHitbox.BackgroundTransparency = 1
IslandHitbox.BorderSizePixel = 0
IslandHitbox.Text = ""
IslandHitbox.AutoButtonColor = false
IslandHitbox.ZIndex = 320
IslandHitbox.Parent = Island

local IslandHoverScale = Instance.new("UIScale")
IslandHoverScale.Scale = 1
IslandHoverScale.Parent = IslandHitbox

IslandHitbox.MouseEnter:Connect(function()
    TweenService:Create(IslandHoverScale, TweenInfo.new(0.12, Enum.EasingStyle.Quad, Enum.EasingDirection.Out), {Scale = 1.025}):Play()
end)
IslandHitbox.MouseLeave:Connect(function()
    TweenService:Create(IslandHoverScale, TweenInfo.new(0.16, Enum.EasingStyle.Back, Enum.EasingDirection.Out), {Scale = 1}):Play()
end)

-- 初始为透明胶囊，仅保留白色 Bloom 辉光。
applyIslandAppearance()
islandExpanded = false
islandCollapsing = false
IslandMotionScale.Scale = 1

-- ================================================================
-- 主 UI 入口、状态、按钮
-- ================================================================

local MainUIDeleted = false
local MainUIMinimized = false
local MainUIMaximized = false
local MainNormalSize = UDim2.fromOffset(MAIN_SIZE.X, MAIN_SIZE.Y)
local MainMaxSize = UDim2.fromOffset(700, 520)
local MainOriginalPosition = MainFrame.Position

local function getMainUISize()
    return MainUIMaximized and MainMaxSize or MainNormalSize
end

local function animateMainUIVisible(visible)
    if MainUIDeleted then return end
    local scale = MainFrame:FindFirstChild("OpenScale")
    if not scale then
        scale = Instance.new("UIScale")
        scale.Name = "OpenScale"
        scale.Scale = 1
        scale.Parent = MainFrame
    end
    if visible then
        MainFrame.Visible = true
        MainFrame.Size = getMainUISize()
        -- 更明显的 Q 弹打开：更小初始缩放 + Back 回弹。
        scale.Scale = 0.82
        Body.Visible = true
        Divider.Visible = true
        TweenService:Create(
            scale,
            TweenInfo.new(0.34, Enum.EasingStyle.Back, Enum.EasingDirection.Out),
            {Scale = 1}
        ):Play()
    else
        TweenService:Create(scale, TweenInfo.new(0.16, Enum.EasingStyle.Quad, Enum.EasingDirection.In), {Scale = 0.90}):Play()
        task.delay(0.16, function()
            if not MainUIDeleted then
                MainFrame.Visible = false
                scale.Scale = 1
            end
        end)
    end
end

local function minimizeMainUI()
    if MainUIDeleted then return end
    MainUIMinimized = true
    -- 最小化：完整隐藏主 UI，不保留任何窗口残片。
    MainFrame.Visible = false
    Body.Visible = false
    Divider.Visible = false
    showIsland("主UI已最小化", "点击灵动岛恢复", true, "点击灵动岛恢复")
end

local function maximizeMainUI()
    if MainUIDeleted then return end
    MainUIMinimized = false
    MainUIMaximized = not MainUIMaximized
    MainFrame.Visible = true
    Body.Visible = true
    Divider.Visible = true
    MainFrame.Size = getMainUISize()
    local scale = MainFrame:FindFirstChild("OpenScale")
    if not scale then
        scale = Instance.new("UIScale")
        scale.Name = "OpenScale"
        scale.Parent = MainFrame
    end
    scale.Scale = 0.88
    TweenService:Create(
        scale,
        TweenInfo.new(0.28, Enum.EasingStyle.Back, Enum.EasingDirection.Out),
        {Scale = 1}
    ):Play()
    showIsland(MainUIMaximized and "主UI已增大" or "主UI已恢复", "页面可继续操作", true)
end

-- 统一隐藏入口：隐藏页面、最小化按钮、灵动岛均走这里，隐藏后保留灵动岛作为恢复入口。
_G.NexusHideMainUI = function()
    if MainUIDeleted then return end
    MainUIMinimized = true
    animateMainUIVisible(false)
    showIsland("主UI已隐藏", "点击灵动岛恢复", false, "点击灵动岛恢复")
end

_G.NexusShowMainUI = function()
    if MainUIDeleted then return end
    MainUIMinimized = false
    animateMainUIVisible(true)
    showIsland("主UI已打开", "SyntaxNext", true, "SyntaxNext")
end

local function deleteMainUI()
    if MainUIDeleted then return end
    MainUIDeleted = true
    islandToken += 1

    -- 销毁即关闭脚本：一次性销毁本脚本创建的所有 UI，不保留灵动岛、功能列表或通知。
    pcall(function()
        if ScreenGui and ScreenGui.Parent then ScreenGui:Destroy() end
    end)
    pcall(function()
        if FeatureHUD and FeatureHUD.Parent then FeatureHUD:Destroy() end
    end)
    pcall(function()
        if IslandGui and IslandGui.Parent then IslandGui:Destroy() end
    end)

    _G.NexusNotifications = nil
    _G.NexusFeatureList = nil
    _G.NexusDynamicIsland = nil
end

IslandHitbox.Activated:Connect(function()
    if MainUIDeleted then
        showIsland("主UI已销毁", "请重新执行脚本", false)
        return
    end
    if MainFrame.Visible then
        -- 点击灵动岛隐藏主 UI，再次点击恢复。
        if _G.NexusHideMainUI then
            _G.NexusHideMainUI()
        else
            animateMainUIVisible(false)
            MainUIMinimized = true
            showIsland("主UI已隐藏", "点击灵动岛恢复", false, "点击灵动岛恢复")
        end
    else
        if _G.NexusShowMainUI then
            _G.NexusShowMainUI()
        else
            MainUIMinimized = false
            animateMainUIVisible(true)
            showIsland("主UI已打开", "SyntaxNext", true, "SyntaxNext")
        end
    end
end)

MinBtn.Activated:Connect(function()
    if _G.NexusHideMainUI then
        _G.NexusHideMainUI()
    else
        minimizeMainUI()
    end
end)
MaxBtn.Activated:Connect(maximizeMainUI)
CloseBtn.Activated:Connect(deleteMainUI)

_G.NexusDynamicIsland = {
    Show = showIsland,
    SetCornerRadius = function(value)
        IslandConfig.CornerRadius = tonumber(value) or IslandConfig.CornerRadius
        applyIslandAppearance()
    end,
    -- 兼容旧接口名称：现在代表磨砂浓度，不是模糊。
    SetGlassVisibility = function(value)
        IslandConfig.FrostOpacity = math.clamp(tonumber(value) or IslandConfig.FrostOpacity, 0, 100)
        applyIslandAppearance()
    end,
    -- 兼容旧接口名称：现在代表高光强度。
    SetGlassPadding = function(value)
        IslandConfig.Highlight = math.clamp(tonumber(value) or IslandConfig.Highlight, 0, 100)
        applyIslandAppearance()
    end,
    SetFrostOpacity = function(value)
        IslandConfig.FrostOpacity = math.clamp(tonumber(value) or IslandConfig.FrostOpacity, 0, 100)
        applyIslandAppearance()
    end,
    SetHighlight = function(value)
        IslandConfig.Highlight = math.clamp(tonumber(value) or IslandConfig.Highlight, 0, 100)
        applyIslandAppearance()
    end,
    GetConfig = function()
        return {
            CornerRadius = IslandConfig.CornerRadius,
            FrostOpacity = IslandConfig.FrostOpacity,
            Highlight = IslandConfig.Highlight,
            Edge = IslandConfig.Edge,
        }
    end,
}

-- ================================================================
-- ================================================================
-- 右上角功能列表：参照 WindUI 的“单一当前状态 + 独立元素状态”思路
-- 功能名称左侧，Mode 右侧；每个功能独立进入/退出；不会因 Tween 失败而不显示
-- ================================================================

local FeatureHUD = Instance.new("ScreenGui")
FeatureHUD.Name = "NexusFeatureHUD"
FeatureHUD.ResetOnSpawn = false
FeatureHUD.IgnoreGuiInset = true
FeatureHUD.ZIndexBehavior = Enum.ZIndexBehavior.Global
FeatureHUD.DisplayOrder = 100002
if not safeParent(FeatureHUD, CoreGui) then
    FeatureHUD.Parent = PlayerGui
end

local FeaturePanel = Instance.new("Frame")
FeaturePanel.Name = "FeatureList"
FeaturePanel.AnchorPoint = Vector2.new(1, 0)
FeaturePanel.Position = UDim2.new(1, -16, 0, 64)
FeaturePanel.Size = UDim2.fromOffset(100, 28)
FeaturePanel.BackgroundTransparency = 1
FeaturePanel.BorderSizePixel = 0
FeaturePanel.ClipsDescendants = false
FeaturePanel.Visible = false
FeaturePanel.ZIndex = 400
FeaturePanel.Parent = FeatureHUD

local FeatureContent = Instance.new("Frame")
FeatureContent.Name = "FeatureContent"
FeatureContent.Size = FeaturePanel.Size
FeatureContent.Position = UDim2.fromScale(0, 0)
FeatureContent.BackgroundTransparency = 1
FeatureContent.BorderSizePixel = 0
FeatureContent.ClipsDescendants = false
FeatureContent.ZIndex = 400
FeatureContent.Parent = FeaturePanel

local FeatureEntries = {}
local FeatureOrder = {}
local FeatureList = {}

-- 前置声明：Lua/Luau 的局部变量作用域从声明点开始，
-- 这些 Bloom/RGB 函数会被前面的 Feature 生命周期函数调用。
local setModeBloomAlpha
local positionModeBloom
local destroyRGBText
local buildRGBText

local FEATURE_NAME_TEXT_SIZE = 14
local FEATURE_MODE_TEXT_SIZE = 9
local FEATURE_FONT = Enum.Font.Gotham
local FEATURE_MODE_FONT = Enum.Font.GothamMedium
local FEATURE_ROW_HEIGHT = 28
local FEATURE_GAP = 5
local FEATURE_SIDE_PADDING = 14
local FEATURE_NAME_MODE_GAP = 10
local FEATURE_MIN_WIDTH = 86
local FEATURE_MAX_WIDTH = 520
-- 功能列表方向动画：开启从右侧并入最终位置，关闭从左侧向右并出。
local FEATURE_SLIDE_IN_MIN = 90
local FEATURE_SLIDE_IN_MAX = 180
local FEATURE_SLIDE_IN_RATIO = 0.42
local FEATURE_SLIDE_OUT_EXTRA = 22
local FEATURE_WHITE_ALPHA = 0.82
local FEATURE_GLASS_ALPHA = 0.04
local FEATURE_GLASS_EXPANSION = 5

local function resolveFeatureMode(_, mode)
    if mode ~= nil and tostring(mode) ~= "" then
        return tostring(mode)
    end
    return ""
end

local function featureTextWidth(text, size, font, fallback)
    local ok, result = pcall(function()
        return TextService:GetTextSize(tostring(text or ""), size, font, Vector2.new(2000, 64))
    end)
    if ok and result then
        return result.X
    end
    return fallback or (#tostring(text or "") * size * 0.62)
end

local function measureFeature(name, mode)
    local nameText = tostring(name)
    local modeText = resolveFeatureMode(nameText, mode)
    local nameWidth = featureTextWidth(nameText, FEATURE_NAME_TEXT_SIZE, FEATURE_FONT, #nameText * 8)
    local modeWidth = modeText ~= "" and featureTextWidth(modeText, FEATURE_MODE_TEXT_SIZE, FEATURE_MODE_FONT, #modeText * 5) or 0
    local contentWidth = nameWidth + modeWidth + (modeText ~= "" and FEATURE_NAME_MODE_GAP or 0)
    local width = math.clamp(math.ceil(contentWidth + FEATURE_SIDE_PADDING * 2), FEATURE_MIN_WIDTH, FEATURE_MAX_WIDTH)
    return nameText, modeText, nameWidth, modeWidth, contentWidth, width
end

local function cancelTween(entry, key)
    if not entry or not entry.Tweens then return end
    local tween = entry.Tweens[key]
    if tween then
        pcall(function() tween:Cancel() end)
        entry.Tweens[key] = nil
    end
end

local function cancelAllTweens(entry)
    if not entry or not entry.Tweens then return end
    -- 先复制引用再逐个清理，避免 Tween:Cancel() 触发完成回调时
    -- 修改同一张表导致 pairs() 跳过其它 Tween。
    local pending = {}
    for key, tween in pairs(entry.Tweens) do
        pending[#pending + 1] = {key = key, tween = tween}
    end
    for _, item in ipairs(pending) do
        entry.Tweens[item.key] = nil
        pcall(function() item.tween:Cancel() end)
    end
end

local function removeFromOrder(name)
    for i = #FeatureOrder, 1, -1 do
        if FeatureOrder[i] == name then
            table.remove(FeatureOrder, i)
        end
    end
end

local function sortedFeatureEntries()
    local rows = {}
    for _, name in ipairs(FeatureOrder) do
        local entry = FeatureEntries[name]
        if entry and entry.Enabled and entry.Frame and entry.Frame.Parent then
            rows[#rows + 1] = entry
        end
    end
    table.sort(rows, function(a, b)
        if a.ContentWidth ~= b.ContentWidth then
            return a.ContentWidth > b.ContentWidth
        end
        return a.Name < b.Name
    end)
    return rows
end

local function layoutFeatureList(animated)
    local rows = sortedFeatureEntries()
    local maxWidth = FEATURE_MIN_WIDTH
    for _, entry in ipairs(rows) do
        maxWidth = math.max(maxWidth, entry.Width)
    end

    FeaturePanel.Size = UDim2.fromOffset(maxWidth, math.max(1, #rows * FEATURE_ROW_HEIGHT + math.max(0, #rows - 1) * FEATURE_GAP))
    FeatureContent.Size = FeaturePanel.Size
    FeatureContent.Visible = (#rows > 0)
    FeaturePanel.Visible = (#rows > 0)
    if #rows > 0 then
        FeatureHUD.Enabled = true
        FeaturePanel.Visible = true
        FeatureContent.Visible = true
    end

    for index, entry in ipairs(rows) do
        local x = math.max(0, maxWidth - entry.Width)
        local y = (index - 1) * (FEATURE_ROW_HEIGHT + FEATURE_GAP)
        local target = UDim2.fromOffset(x, y)
        entry.Frame.Size = UDim2.fromOffset(entry.Width, FEATURE_ROW_HEIGHT)

        if animated and entry.State == "active" then
            cancelTween(entry, "Layout")
            local tw = TweenService:Create(entry.Frame, TweenInfo.new(0.16, Enum.EasingStyle.Quint, Enum.EasingDirection.Out), {
                Position = target,
            })
            entry.Tweens.Layout = tw
            tw:Play()
        else
            entry.Frame.Position = target
        end
    end
end

local function ensureFeatureVisible(entry)
    if not entry or not entry.Frame or not entry.Frame.Parent then return end
    entry.Frame.Visible = true
    entry.NameLabel.Visible = true
    entry.ModeLabel.Visible = entry.Mode ~= ""
    entry.NameLabel.TextTransparency = 1
    entry.ModeLabel.TextTransparency = entry.Mode ~= "" and 0.02 or 1
    if entry.ModeBloom then
        positionModeBloom(entry)
        setModeBloomAlpha(entry, entry.Mode ~= "" and 1 or 0)
    end
    if entry.RGB and entry.RGB.AlphaValue then entry.RGB.AlphaValue.Value = 0 end
end

local function featureEnter(entry)
    if not entry or not entry.Frame or not entry.Frame.Parent then return end

    -- 开/关动画互相覆盖：如果当前正处于退出或进入动画，直接从当前视觉状态反向接管，
    -- 不跳回起点、不等待旧动画结束。
    local interrupt = entry._EnterInterrupt
    entry._EnterInterrupt = nil

    cancelAllTweens(entry)
    entry.Generation = (tonumber(entry.Generation) or 0) + 1
    local generation = entry.Generation
    entry.Enabled = true
    entry.State = "enter"

    FeatureHUD.Enabled = true
    FeaturePanel.Visible = true
    FeatureContent.Visible = true
    entry.Frame.Visible = true
    entry.Frame.Parent = FeatureContent

    -- 先确定最终布局；真正的进入起点在下面根据“正常进入/动画反向覆盖”决定。
    layoutFeatureList(false)
    local finalPos = entry.Frame.Position

    local isInterrupted = interrupt and interrupt.Visible and (interrupt.State == "enter" or interrupt.State == "exit")
    local startPos
    local startScale
    local startNameAlpha
    local startModeAlpha
    local startRGBAlpha
    local startModeBloomAlpha

    if isInterrupted and interrupt.Position then
        startPos = interrupt.Position
        startScale = math.clamp(tonumber(interrupt.Scale) or 0.92, 0.84, 1.10)
        startNameAlpha = math.clamp(tonumber(interrupt.NameAlpha) or 0, 0, 1)
        startModeAlpha = math.clamp(tonumber(interrupt.ModeAlpha) or 0.02, 0, 1)
        startRGBAlpha = math.clamp(tonumber(interrupt.RGBAlpha) or 0, 0, 1)
        startModeBloomAlpha = math.clamp(tonumber(interrupt.ModeBloomAlpha) or 1, 0, 1)
    else
        local slideIn = math.clamp(
            math.max(entry.Width + 16, entry.Width * FEATURE_SLIDE_IN_RATIO),
            FEATURE_SLIDE_IN_MIN,
            FEATURE_SLIDE_IN_MAX
        )
        startPos = UDim2.fromOffset(finalPos.X.Offset + slideIn, finalPos.Y.Offset)
        startScale = 0.90
        startNameAlpha = 1
        startModeAlpha = 1
        startRGBAlpha = 0
        startModeBloomAlpha = entry.Mode ~= "" and 1 or 0
    end

    -- 不再做明显的“冲过头”，只保留很轻微的 Q 弹。
    local overshootLeft = UDim2.fromOffset(finalPos.X.Offset - 7, finalPos.Y.Offset)
    local overshootRight = UDim2.fromOffset(finalPos.X.Offset + 2, finalPos.Y.Offset)

    entry.Frame.Position = startPos
    entry.Scale.Scale = startScale

    if entry.NameLabel then
        entry.NameLabel.Visible = true
        entry.NameLabel.TextTransparency = startNameAlpha
        entry.NameLabel.TextStrokeTransparency = 1
    end
    if entry.ModeLabel then
        entry.ModeLabel.Visible = entry.Mode ~= ""
        entry.ModeLabel.TextTransparency = entry.Mode ~= "" and startModeAlpha or 1
        entry.ModeLabel.TextStrokeTransparency = 1
    end
    if entry.RGB and entry.RGB.AlphaValue then
        entry.RGB.AlphaValue.Value = startRGBAlpha
    end
    if entry.ModeBloom then
        positionModeBloom(entry)
        setModeBloomAlpha(entry, entry.Mode ~= "" and startModeBloomAlpha or 0)
    end

    -- 开启动画更短更快：右侧并入 -> 极轻微左弹 -> 立刻回正。
    local inTween = TweenService:Create(
        entry.Frame,
        TweenInfo.new(0.17, Enum.EasingStyle.Quart, Enum.EasingDirection.Out),
        {Position = overshootLeft}
    )
    entry.Tweens.In = inTween
    inTween:Play()

    if entry.Scale then
        local scaleIn = TweenService:Create(
            entry.Scale,
            TweenInfo.new(0.13, Enum.EasingStyle.Back, Enum.EasingDirection.Out),
            {Scale = 1.045}
        )
        entry.Tweens.ScaleIn = scaleIn
        scaleIn:Play()
    end

    -- 如果是从退出动画直接反向接管，就让当前透明度一起恢复，而不是突然闪现。
    if isInterrupted then
        if entry.RGB and entry.RGB.AlphaValue then
            local rgbRestore = TweenService:Create(
                entry.RGB.AlphaValue,
                TweenInfo.new(0.13, Enum.EasingStyle.Quad, Enum.EasingDirection.Out),
                {Value = 0}
            )
            entry.Tweens.RGBRestore = rgbRestore
            rgbRestore:Play()
        end
        if entry.ModeLabel and entry.Mode ~= "" then
            local modeRestore = TweenService:Create(
                entry.ModeLabel,
                TweenInfo.new(0.13, Enum.EasingStyle.Quad, Enum.EasingDirection.Out),
                {TextTransparency = 0.02}
            )
            entry.Tweens.ModeRestore = modeRestore
            modeRestore:Play()
        end
        if entry.ModeBloom and entry.Mode ~= "" then
            local bloomRestore = TweenService:Create(
                entry.ModeBloom.AlphaValue,
                TweenInfo.new(0.13, Enum.EasingStyle.Quad, Enum.EasingDirection.Out),
                {Value = 1}
            )
            entry.Tweens.BloomRestore = bloomRestore
            bloomRestore:Play()
        end
    else
        if entry.RGB and entry.RGB.AlphaValue then
            entry.RGB.AlphaValue.Value = 0
        end
        if entry.ModeBloom then
            setModeBloomAlpha(entry, entry.Mode ~= "" and 1 or 0)
        end
    end

    task.delay(0.17, function()
        if not entry.Frame or not entry.Frame.Parent then return end
        if entry.Generation ~= generation or not entry.Enabled or entry.State ~= "enter" then return end

        cancelTween(entry, "In")
        cancelTween(entry, "ScaleIn")
        cancelTween(entry, "RGBRestore")
        cancelTween(entry, "ModeRestore")
        cancelTween(entry, "BloomRestore")

        local bounceBack = TweenService:Create(
            entry.Frame,
            TweenInfo.new(0.055, Enum.EasingStyle.Back, Enum.EasingDirection.Out),
            {Position = overshootRight}
        )
        entry.Tweens.BounceBack = bounceBack
        bounceBack:Play()

        if entry.Scale then
            local scaleBack = TweenService:Create(
                entry.Scale,
                TweenInfo.new(0.055, Enum.EasingStyle.Quad, Enum.EasingDirection.Out),
                {Scale = 0.985}
            )
            entry.Tweens.ScaleBack = scaleBack
            scaleBack:Play()
        end

        task.delay(0.055, function()
            if not entry.Frame or not entry.Frame.Parent then return end
            if entry.Generation ~= generation or not entry.Enabled or entry.State ~= "enter" then return end

            cancelTween(entry, "BounceBack")
            cancelTween(entry, "ScaleBack")

            local settle = TweenService:Create(
                entry.Frame,
                TweenInfo.new(0.065, Enum.EasingStyle.Quad, Enum.EasingDirection.Out),
                {Position = finalPos}
            )
            entry.Tweens.Settle = settle
            settle:Play()

            if entry.Scale then
                local scaleSettle = TweenService:Create(
                    entry.Scale,
                    TweenInfo.new(0.065, Enum.EasingStyle.Quad, Enum.EasingDirection.Out),
                    {Scale = 1}
                )
                entry.Tweens.ScaleSettle = scaleSettle
                scaleSettle:Play()
            end

            task.delay(0.07, function()
                if entry.Frame and entry.Frame.Parent and entry.Generation == generation and entry.Enabled and entry.State == "enter" then
                    entry.Frame.Position = finalPos
                    if entry.Scale then entry.Scale.Scale = 1 end
                    if entry.NameLabel then entry.NameLabel.TextTransparency = 1 end
                    if entry.RGB and entry.RGB.AlphaValue then entry.RGB.AlphaValue.Value = 0 end
                    if entry.ModeLabel then entry.ModeLabel.TextTransparency = entry.Mode ~= "" and 0.02 or 1 end
                    if entry.ModeBloom then setModeBloomAlpha(entry, entry.Mode ~= "" and 1 or 0) end
                    entry.State = "active"
                    cancelTween(entry, "Settle")
                    cancelTween(entry, "ScaleSettle")
                    layoutFeatureList(true)
                end
            end)
        end)
    end)
end

local function destroyFeature(name, entry)
    if entry then
        cancelAllTweens(entry)
        destroyRGBText(entry)
        if entry.Frame then pcall(function() entry.Frame:Destroy() end) end
    end
    if FeatureEntries[name] == entry then
        FeatureEntries[name] = nil
    end
    removeFromOrder(name)
end

local function featureExit(name, entry)
    if not entry or not entry.Frame or not entry.Frame.Parent then
        if FeatureEntries[name] == entry then
            FeatureEntries[name] = nil
        end
        removeFromOrder(name)
        layoutFeatureList(false)
        return
    end

    cancelAllTweens(entry)
    entry.Generation = (tonumber(entry.Generation) or 0) + 1
    local generation = entry.Generation
    entry.Enabled = false
    entry.State = "exit"

    -- 记录退出起点。关闭时整行从左向右并出，不再突然缩到原地。
    local startPos = entry.Frame.Position
    local outDistance = math.max(entry.Width + FEATURE_SLIDE_OUT_EXTRA, FEATURE_SLIDE_IN_MIN)
    local exitPos = UDim2.fromOffset(startPos.X.Offset + outDistance, startPos.Y.Offset)

    local scaleTw = TweenService:Create(entry.Scale, TweenInfo.new(0.20, Enum.EasingStyle.Back, Enum.EasingDirection.In), {Scale = 0.88})
    local posTw = TweenService:Create(entry.Frame, TweenInfo.new(0.21, Enum.EasingStyle.Quint, Enum.EasingDirection.In), {Position = exitPos})
    local rgbTw = entry.RGB and entry.RGB.AlphaValue and TweenService:Create(entry.RGB.AlphaValue, TweenInfo.new(0.18, Enum.EasingStyle.Quad, Enum.EasingDirection.In), {Value = 1}) or nil
    local nameTw = TweenService:Create(entry.NameLabel, TweenInfo.new(0.17, Enum.EasingStyle.Quad, Enum.EasingDirection.In), {TextTransparency = 1})
    local modeTw = TweenService:Create(entry.ModeLabel, TweenInfo.new(0.16, Enum.EasingStyle.Quad, Enum.EasingDirection.In), {TextTransparency = 1})
    local modeBloomTw = entry.ModeBloom and entry.ModeBloom.AlphaValue and TweenService:Create(entry.ModeBloom.AlphaValue, TweenInfo.new(0.16, Enum.EasingStyle.Quad, Enum.EasingDirection.In), {Value = 0}) or nil

    entry.Tweens.Scale = scaleTw
    entry.Tweens.Position = posTw
    entry.Tweens.RGB = rgbTw
    entry.Tweens.Name = nameTw
    entry.Tweens.Mode = modeTw
    entry.Tweens.ModeBloom = modeBloomTw

    scaleTw:Play()
    posTw:Play()
    if rgbTw then rgbTw:Play() end
    nameTw:Play()
    modeTw:Play()
    if modeBloomTw then modeBloomTw:Play() end

    -- 其它仍开启的功能立即重新排位；正在退出的这一行保持自己的左→右退出轨迹。
    layoutFeatureList(true)

    task.delay(0.22, function()
        if not entry.Frame or not entry.Frame.Parent then return end
        if entry.Generation ~= generation or entry.Enabled or entry.State ~= "exit" then return end

        cancelAllTweens(entry)
        entry.Frame.Visible = false
        entry.State = "hidden"
        entry.Scale.Scale = 1
        entry.NameLabel.TextTransparency = 1
        entry.ModeLabel.TextTransparency = 1
        if entry.RGB and entry.RGB.AlphaValue then entry.RGB.AlphaValue.Value = 1 end
        if entry.ModeBloom then setModeBloomAlpha(entry, 0) end

        -- 防止下次开启时继承上一次退出后的位置。
        entry.Frame.Position = UDim2.fromOffset(0, 0)
        layoutFeatureList(false)
    end)
end

-- ================================================================
-- ================================================================
-- Opal 风格 RGB 文字 + Bloom 辉光
-- 参考你提供的 OpalWatermark：
-- 1) 文字按“单字符”拆分，每个字符有独立 RGB 相位。
-- 2) 字符相位模拟 $animCount：1, 8, 15, 22, 29...
-- 3) 每个字符拥有独立 bloom_16x，辉光颜色与对应字符完全一致。
-- 4) 不使用 TextStroke/UIGradient，形成连续的逐字符 RGB 流动。
-- bloom_16x: 104490578391522
-- ================================================================
local OPAL_BLOOM_16 = "rbxassetid://104490578391522"
local OPAL_BLOOM_8 = "rbxassetid://102472648910048"
local OPAL_RGB_SPEED = 0.28
local OPAL_CHAR_PHASE = 7 / 84
local OPAL_SATURATION = 0.78
local OPAL_VALUE = 1.0
local OPAL_BLOOM_ALPHA = 0.58 -- 对应 JSON alpha=0.42
local OPAL_BLOOM_EXTRA_X = 6
local OPAL_BLOOM_HEIGHT = 16
local OPAL_BLOOM_SOFT_EXTRA_X = 7
local OPAL_BLOOM_SOFT_HEIGHT = 18
local OPAL_BLOOM_SOFT_ALPHA = 0.76
local OPAL_BLOOM_Z = 402
local OPAL_TEXT_Z = 406
local OPAL_MODE_BLOOM_Z = 403
local OPAL_MODE_TEXT_Z = 405
local OPAL_MODE_BLOOM_ALPHA = 0.36
local OPAL_MODE_BLOOM_EXTRA_X = 16
local OPAL_MODE_BLOOM_HEIGHT = 24

setModeBloomAlpha = function(entry, alpha)
    if not entry or not entry.ModeBloom then return end
    alpha = math.clamp(tonumber(alpha) or 1, 0, 1)
    entry.ModeBloom.Alpha = alpha
    if entry.ModeBloom.Image and entry.ModeBloom.Image.Parent then
        entry.ModeBloom.Image.ImageTransparency = math.clamp(1 - alpha + OPAL_MODE_BLOOM_ALPHA * alpha, 0, 1)
    end
end

positionModeBloom = function(entry)
    if not entry or not entry.ModeLabel or not entry.ModeBloom or not entry.ModeBloom.Image then return end
    local label = entry.ModeLabel
    local glow = entry.ModeBloom.Image
    local w = math.max(2, label.AbsoluteSize.X)
    glow.Size = UDim2.fromOffset(w + OPAL_MODE_BLOOM_EXTRA_X, OPAL_MODE_BLOOM_HEIGHT)
    glow.Position = UDim2.new(
        label.Position.X.Scale,
        label.Position.X.Offset - OPAL_MODE_BLOOM_EXTRA_X * 0.5,
        0.5,
        -OPAL_MODE_BLOOM_HEIGHT * 0.5
    )
end

local function setRGBAlpha(entry, alpha)
    if not entry or not entry.RGB then return end
    alpha = math.clamp(tonumber(alpha) or 0, 0, 1)
    entry.RGB.Alpha = alpha

    if entry.RGB.Characters then
        for i, label in ipairs(entry.RGB.Characters) do
            if label and label.Parent then
                label.TextTransparency = alpha
            end
            local charBloom = entry.RGB.CharacterBlooms and entry.RGB.CharacterBlooms[i]
            if charBloom and charBloom.Parent then
                charBloom.ImageTransparency = math.clamp(OPAL_BLOOM_ALPHA + alpha * (1 - OPAL_BLOOM_ALPHA), 0, 1)
            end
        end
    end

    local bloomTransparency = 1
    if entry.RGB.Bloom16 and entry.RGB.Bloom16.Parent then
        entry.RGB.Bloom16.ImageTransparency = bloomTransparency
    end
    if entry.RGB.BloomSoft and entry.RGB.BloomSoft.Parent then
        entry.RGB.BloomSoft.ImageTransparency = math.clamp(OPAL_BLOOM_SOFT_ALPHA + alpha * (1 - OPAL_BLOOM_SOFT_ALPHA), 0, 1)
    end
end

destroyRGBText = function(entry)
    if not entry or not entry.RGB then return end
    if entry.RGB.Holder then pcall(function() entry.RGB.Holder:Destroy() end) end
    if entry.RGB.AlphaValue then pcall(function() entry.RGB.AlphaValue:Destroy() end) end
    entry.RGB = nil
end

local function makeOpalCharacter(parent, char, x, width, font, textSize, alpha)
    -- 模仿 Opal JSON 的逐字符 RGB：每个字符独立拥有自己的柔光层，
    -- 文字与辉光使用完全相同的 hue，因此不会再出现“整串文字一个辉光颜色”。
    local charHeight = math.max(1, textSize + 6)
    local charY = math.floor((FEATURE_ROW_HEIGHT - charHeight) * 0.5 + 0.5)
    local bloomWidth = math.max(2, math.ceil(width + OPAL_BLOOM_EXTRA_X))
    local bloomHeight = math.min(OPAL_BLOOM_HEIGHT, charHeight)

    local bloom = Instance.new("ImageLabel")
    bloom.Name = "RGBCharBloom"
    bloom.BackgroundTransparency = 1
    bloom.BorderSizePixel = 0
    bloom.AnchorPoint = Vector2.new(0.5, 0.5)
    bloom.Position = UDim2.fromOffset(math.floor(x + width * 0.5 + 0.5), charY + charHeight * 0.5)
    bloom.Size = UDim2.fromOffset(bloomWidth, bloomHeight)
    bloom.Image = OPAL_BLOOM_16
    bloom.ScaleType = Enum.ScaleType.Stretch
    bloom.ImageColor3 = Color3.fromHSV(0, OPAL_SATURATION, OPAL_VALUE)
    bloom.ImageTransparency = math.clamp(OPAL_BLOOM_ALPHA + (alpha or 0) * (1 - OPAL_BLOOM_ALPHA), 0, 1)
    bloom.ZIndex = OPAL_BLOOM_Z
    bloom.Parent = parent

    local label = Instance.new("TextLabel")
    label.Name = "RGBChar"
    label.BackgroundTransparency = 1
    label.BorderSizePixel = 0
    label.Size = UDim2.fromOffset(math.max(1, math.ceil(width + 1)), charHeight)
    label.Position = UDim2.fromOffset(math.floor(x + 0.5), charY)
    label.Text = char
    label.Font = font
    label.TextSize = textSize
    label.TextColor3 = Color3.fromHSV(0, OPAL_SATURATION, OPAL_VALUE)
    label.TextTransparency = alpha or 0
    label.TextStrokeTransparency = 1
    label.TextXAlignment = Enum.TextXAlignment.Left
    label.TextYAlignment = Enum.TextYAlignment.Center
    label.ZIndex = OPAL_TEXT_Z
    label.Parent = parent
    return label, bloom
end

buildRGBText = function(entry)
    if not entry or not entry.Frame or not entry.NameLabel then return end
    destroyRGBText(entry)

    local base = entry.NameLabel
    local font = base.Font
    local textSize = base.TextSize
    local holder = Instance.new("Frame")
    holder.Name = "OpalRGBText"
    holder.BackgroundTransparency = 1
    holder.BorderSizePixel = 0
    holder.ClipsDescendants = false
    holder.Size = base.Size
    holder.Position = base.Position
    holder.AnchorPoint = base.AnchorPoint
    holder.ZIndex = OPAL_BLOOM_Z
    holder.Parent = entry.Frame

    -- Opal JSON 的核心：单独一层 bloom_16x 放在 RGB 文本下面。
    -- 主 Bloom + 柔和外层 Bloom：两层都严格按照实际字符宽度铺开，
    -- 避免 holder/NameLabel 宽度与逐字符 TextService 测量存在误差时右侧缺光。
    local bloomSoft = Instance.new("ImageLabel")
    bloomSoft.Name = "BloomSoft"
    bloomSoft.BackgroundTransparency = 1
    bloomSoft.BorderSizePixel = 0
    bloomSoft.Position = UDim2.fromOffset(-OPAL_BLOOM_SOFT_EXTRA_X / 2, -(OPAL_BLOOM_SOFT_HEIGHT - textSize) * 0.5)
    bloomSoft.Size = UDim2.fromOffset(math.max(2, OPAL_BLOOM_SOFT_EXTRA_X), OPAL_BLOOM_SOFT_HEIGHT)
    bloomSoft.Image = OPAL_BLOOM_8
    bloomSoft.ScaleType = Enum.ScaleType.Stretch
    bloomSoft.ImageColor3 = Color3.fromRGB(255, 90, 180)
    bloomSoft.ImageTransparency = 1
    bloomSoft.ZIndex = OPAL_BLOOM_Z - 1
    bloomSoft.Parent = holder

    local bloom16 = Instance.new("ImageLabel")
    bloom16.Name = "Bloom16"
    bloom16.BackgroundTransparency = 1
    bloom16.BorderSizePixel = 0
    bloom16.Position = UDim2.fromOffset(-OPAL_BLOOM_EXTRA_X / 2, -(OPAL_BLOOM_HEIGHT - textSize) * 0.5)
    bloom16.Size = UDim2.fromOffset(math.max(2, OPAL_BLOOM_EXTRA_X), OPAL_BLOOM_HEIGHT)
    bloom16.Image = OPAL_BLOOM_16
    bloom16.ScaleType = Enum.ScaleType.Stretch
    bloom16.ImageColor3 = Color3.fromRGB(255, 90, 180)
    bloom16.ImageTransparency = 1
    bloom16.ZIndex = OPAL_BLOOM_Z
    bloom16.Parent = holder

    local characters = {}
    local characterBlooms = {}
    local text = tostring(entry.Name or base.Text or "")
    local x = 0

    for _, codepoint in utf8.codes(text) do
        local char = utf8.char(codepoint)
        local charWidth = featureTextWidth(char, textSize, font, math.max(1, textSize * 0.55))
        local label, bloom = makeOpalCharacter(holder, char, x, charWidth, font, textSize, 0)
        characters[#characters + 1] = label
        characterBlooms[#characterBlooms + 1] = bloom
        x += charWidth
    end

    base.TextTransparency = 1
    base.TextStrokeTransparency = 1

    local alphaValue = Instance.new("NumberValue")
    alphaValue.Name = "OpalRGBAlpha"
    alphaValue.Value = 0
    alphaValue.Parent = entry.Frame
    alphaValue.Changed:Connect(function(value)
        setRGBAlpha(entry, value)
    end)

    entry.RGB = {
        Holder = holder,
        Bloom16 = bloom16,
        BloomSoft = bloomSoft,
        Characters = characters,
        CharacterBlooms = characterBlooms,
        Alpha = 0,
        AlphaValue = alphaValue,
        TextWidth = x,
    }

    -- 首次构建后立即用逐字符实际宽度更新两层 Bloom 的边界。
    local bloomWidth = math.max(2, x)
    bloom16.Position = UDim2.fromOffset(-OPAL_BLOOM_EXTRA_X / 2, -(OPAL_BLOOM_HEIGHT - textSize) * 0.5)
    bloom16.Size = UDim2.fromOffset(math.max(2, bloomWidth + OPAL_BLOOM_EXTRA_X), OPAL_BLOOM_HEIGHT)
    bloomSoft.Position = UDim2.fromOffset(-OPAL_BLOOM_SOFT_EXTRA_X / 2, -(OPAL_BLOOM_SOFT_HEIGHT - textSize) * 0.5)
    bloomSoft.Size = UDim2.fromOffset(math.max(2, bloomWidth + OPAL_BLOOM_SOFT_EXTRA_X), OPAL_BLOOM_SOFT_HEIGHT)
    setRGBAlpha(entry, 0)
end

local function updateRGBText(entry)
    if not entry or not entry.RGB then return end
    local base = entry.NameLabel
    local holder = entry.RGB.Holder
    if not base or not holder or not holder.Parent then return end

    holder.Size = base.Size
    holder.Position = base.Position
    holder.AnchorPoint = base.AnchorPoint

    local text = tostring(entry.Name or base.Text or "")
    for _, label in ipairs(entry.RGB.Characters or {}) do
        if label and label.Parent then label:Destroy() end
    end
    table.clear(entry.RGB.Characters)
    table.clear(entry.RGB.CharacterBlooms or {})

    local x = 0
    local font = base.Font
    local textSize = base.TextSize
    for _, codepoint in utf8.codes(text) do
        local char = utf8.char(codepoint)
        local charWidth = featureTextWidth(char, textSize, font, math.max(1, textSize * 0.55))
        local label, bloom = makeOpalCharacter(holder, char, x, charWidth, font, textSize, entry.RGB.Alpha or 0)
        entry.RGB.Characters[#entry.RGB.Characters + 1] = label
        entry.RGB.CharacterBlooms[#entry.RGB.CharacterBlooms + 1] = bloom
        x += charWidth
    end

    entry.RGB.TextWidth = x
    local bloomWidth = math.max(2, x)
    if entry.RGB.Bloom16 and entry.RGB.Bloom16.Parent then
        entry.RGB.Bloom16.Position = UDim2.fromOffset(-OPAL_BLOOM_EXTRA_X / 2, -(OPAL_BLOOM_HEIGHT - textSize) * 0.5)
        entry.RGB.Bloom16.Size = UDim2.fromOffset(math.max(2, bloomWidth + OPAL_BLOOM_EXTRA_X), OPAL_BLOOM_HEIGHT)
    end
    if entry.RGB.BloomSoft and entry.RGB.BloomSoft.Parent then
        entry.RGB.BloomSoft.Position = UDim2.fromOffset(-OPAL_BLOOM_SOFT_EXTRA_X / 2, -(OPAL_BLOOM_SOFT_HEIGHT - textSize) * 0.5)
        entry.RGB.BloomSoft.Size = UDim2.fromOffset(math.max(2, bloomWidth + OPAL_BLOOM_SOFT_EXTRA_X), OPAL_BLOOM_SOFT_HEIGHT)
    end
    base.TextTransparency = 1
    base.TextStrokeTransparency = 1
end

local FeatureRGBConnection
FeatureRGBConnection = RunService.RenderStepped:Connect(function()
    if not FeatureHUD or not FeatureHUD.Parent then
        if FeatureRGBConnection then
            FeatureRGBConnection:Disconnect()
            FeatureRGBConnection = nil
        end
        return
    end

    local t = os.clock()
    for index, name in ipairs(FeatureOrder) do
        local entry = FeatureEntries[name]
        if entry and entry.Enabled and entry.Frame and entry.Frame.Parent then
            if entry.ModeBloom then
                positionModeBloom(entry)
            end
            if not entry.RGB then
                continue
            end
            local chars = entry.RGB.Characters or {}
            local blooms = entry.RGB.CharacterBlooms or {}
            -- 模仿 JSON 的 $animCount: 1, 8, 15, 22, 29...
            -- 每个字符都拥有递进相位，因此会从左到右形成彩虹渐变，而非整串同色。
            local flowBase = (t * OPAL_RGB_SPEED + (index - 1) * 0.035) % 1
            for i, label in ipairs(chars) do
                if label and label.Parent then
                    local hue = (flowBase + (i - 1) * OPAL_CHAR_PHASE) % 1
                    local rgb = Color3.fromHSV(hue, OPAL_SATURATION, OPAL_VALUE)
                    label.TextColor3 = rgb
                    local charBloom = blooms[i]
                    if charBloom and charBloom.Parent then
                        charBloom.ImageColor3 = rgb
                    end
                end
            end

            -- 旧的整串 Bloom 仅作为极淡的环境光底，不再承担主色变化。
            if entry.RGB.Bloom16 and entry.RGB.Bloom16.Parent then
                entry.RGB.Bloom16.ImageTransparency = 1
            end
            if entry.RGB.BloomSoft and entry.RGB.BloomSoft.Parent then
                entry.RGB.BloomSoft.ImageTransparency = 1
            end
        end
    end
end)

local function createFeature(name, mode)
    local nameText, modeText, nameWidth, modeWidth, contentWidth, totalWidth = measureFeature(name, mode)

    local frame = Instance.new("Frame")
    frame.Name = "Feature_" .. tostring(name):gsub("%W", "_")
    frame.Size = UDim2.fromOffset(totalWidth, FEATURE_ROW_HEIGHT)
    frame.BackgroundTransparency = 1
    frame.BorderSizePixel = 0
    frame.ClipsDescendants = false
    frame.Visible = true
    frame.ZIndex = 400
    frame.Parent = FeatureContent
    addCorner(frame, 9)

    local scale = Instance.new("UIScale")
    scale.Scale = 1
    scale.Parent = frame

    local nameLabel = Instance.new("TextLabel")
    nameLabel.Name = "Name"
    nameLabel.Size = UDim2.new(1, -(FEATURE_SIDE_PADDING * 2 + (modeText ~= "" and modeWidth + FEATURE_NAME_MODE_GAP or 0)), 1, 0)
    nameLabel.Position = UDim2.fromOffset(FEATURE_SIDE_PADDING, 0)
    nameLabel.BackgroundTransparency = 1
    nameLabel.Text = nameText
    nameLabel.TextColor3 = Color3.fromRGB(24, 24, 28)
    nameLabel.TextTransparency = 0
    nameLabel.TextStrokeTransparency = 1
    nameLabel.TextSize = FEATURE_NAME_TEXT_SIZE
    nameLabel.Font = FEATURE_FONT
    nameLabel.TextXAlignment = Enum.TextXAlignment.Left
    nameLabel.TextYAlignment = Enum.TextYAlignment.Center
    nameLabel.TextTruncate = Enum.TextTruncate.AtEnd
    nameLabel.ZIndex = 404
    nameLabel.Parent = frame

    local modeLabel = Instance.new("TextLabel")
    modeLabel.Name = "Mode"
    modeLabel.Size = UDim2.fromOffset(math.max(1, modeWidth + 2), 16)
    modeLabel.Position = UDim2.new(1, -(FEATURE_SIDE_PADDING + modeWidth), 0.5, -8)
    modeLabel.BackgroundTransparency = 1
    modeLabel.Text = modeText
    modeLabel.TextColor3 = Color3.fromRGB(255, 255, 255)
    modeLabel.TextTransparency = modeText ~= "" and 0.02 or 1
    modeLabel.TextStrokeTransparency = 1
    modeLabel.TextSize = FEATURE_MODE_TEXT_SIZE
    modeLabel.Font = FEATURE_MODE_FONT
    modeLabel.TextXAlignment = Enum.TextXAlignment.Right
    modeLabel.TextYAlignment = Enum.TextYAlignment.Center
    modeLabel.TextTruncate = Enum.TextTruncate.AtEnd
    modeLabel.ZIndex = OPAL_MODE_TEXT_Z
    modeLabel.Parent = frame

    local modeBloom = Instance.new("ImageLabel")
    modeBloom.Name = "ModeBloom8"
    modeBloom.BackgroundTransparency = 1
    modeBloom.BorderSizePixel = 0
    modeBloom.Image = OPAL_BLOOM_8
    modeBloom.ScaleType = Enum.ScaleType.Stretch
    modeBloom.ImageColor3 = Color3.fromRGB(255, 255, 255)
    modeBloom.ImageTransparency = modeText ~= "" and 0.64 or 1
    modeBloom.ZIndex = OPAL_MODE_BLOOM_Z
    modeBloom.Parent = frame

    local modeBloomAlpha = Instance.new("NumberValue")
    modeBloomAlpha.Name = "ModeBloomAlpha"
    modeBloomAlpha.Value = modeText ~= "" and 1 or 0
    modeBloomAlpha.Parent = frame
    modeBloomAlpha.Changed:Connect(function(value)
        if modeBloom.Parent then
            modeBloom.ImageTransparency = math.clamp(1 - math.clamp(value, 0, 1) + OPAL_MODE_BLOOM_ALPHA * math.clamp(value, 0, 1), 0, 1)
        end
    end)

    local entry = {
        Name = nameText,
        Mode = modeText,
        NameWidth = nameWidth,
        ModeWidth = modeWidth,
        ContentWidth = contentWidth,
        Width = totalWidth,
        Frame = frame,
        Scale = scale,
        NameLabel = nameLabel,
        ModeLabel = modeLabel,
        ModeBloom = {Image = modeBloom, AlphaValue = modeBloomAlpha, Alpha = modeText ~= "" and 1 or 0},
        Enabled = true,
        State = "active",
        Generation = 0,
        Tweens = {},
    }
    buildRGBText(entry)
    return entry
end

function FeatureList:Set(name, enabled, mode)
    name = tostring(name)
    enabled = enabled == true
    local resolvedMode = resolveFeatureMode(name, mode)
    local entry = FeatureEntries[name]

    if enabled then
        if not entry or not entry.Frame or not entry.Frame.Parent then
            entry = createFeature(name, resolvedMode)
            FeatureEntries[name] = entry
        else
            -- 在反向覆盖前保存当前动画的真实视觉状态，避免“关的过程中重新开”时跳回右侧起点。
            local previousState = entry.State
            local wasAnimating = entry.Frame.Visible and (previousState == "enter" or previousState == "exit")
            local interruptState
            if wasAnimating then
                interruptState = {
                    Visible = true,
                    State = previousState,
                    Position = entry.Frame.Position,
                    Scale = entry.Scale and entry.Scale.Scale or 1,
                    NameAlpha = entry.NameLabel and entry.NameLabel.TextTransparency or 0,
                    ModeAlpha = entry.ModeLabel and entry.ModeLabel.TextTransparency or 0.02,
                    RGBAlpha = entry.RGB and entry.RGB.AlphaValue and entry.RGB.AlphaValue.Value or 0,
                    ModeBloomAlpha = entry.ModeBloom and entry.ModeBloom.AlphaValue and entry.ModeBloom.AlphaValue.Value or 0,
                }
            end

            cancelAllTweens(entry)
            entry.Generation = (tonumber(entry.Generation) or 0) + 1

            local infoName, infoMode, nameWidth, modeWidth, contentWidth, totalWidth = measureFeature(name, resolvedMode)
            entry.Name = infoName
            entry.Mode = infoMode
            entry.NameWidth = nameWidth
            entry.ModeWidth = modeWidth
            entry.ContentWidth = contentWidth
            entry.Width = totalWidth

            entry.NameLabel.Text = infoName
            entry.NameLabel.Size = UDim2.new(1, -(FEATURE_SIDE_PADDING * 2 + (infoMode ~= "" and modeWidth + FEATURE_NAME_MODE_GAP or 0)), 1, 0)
            entry.ModeLabel.Text = infoMode
            entry.ModeLabel.Visible = infoMode ~= ""
            entry.ModeLabel.Size = UDim2.fromOffset(math.max(1, modeWidth + 2), 16)
            entry.ModeLabel.Position = UDim2.new(1, -(FEATURE_SIDE_PADDING + modeWidth), 0.5, -8)
            updateRGBText(entry)
            if entry.ModeBloom then positionModeBloom(entry) end

            entry._EnterInterrupt = interruptState
        end

        entry.Enabled = true
        entry.State = "enter"
        entry.Frame.Visible = true
        entry.Frame.Parent = FeatureContent
        entry.Frame.Size = UDim2.fromOffset(entry.Width, FEATURE_ROW_HEIGHT)

        if not table.find(FeatureOrder, name) then
            FeatureOrder[#FeatureOrder + 1] = name
        end

        FeatureHUD.Enabled = true
        FeaturePanel.Visible = true
        FeatureContent.Visible = true
        featureEnter(entry)

        pcall(function()
            showIsland("功能已开启", entry.Name, true, entry.Name .. (entry.Mode ~= "" and ("  " .. entry.Mode) or ""))
        end)
        return
    end

    if entry then
        -- 关闭时同样直接覆盖当前开启动画：featureExit 会从当前帧的位置向右滑出，
        -- 不重置到左侧，不等待进入动画完成。
        if not entry.Enabled and entry.State ~= "active" and entry.State ~= "enter" then
            return
        end

        local displayName = entry.Name
        local displayMode = entry.Mode
        featureExit(name, entry)
        pcall(function()
            showIsland("功能已关闭", displayName, false, displayName .. (displayMode ~= "" and ("  " .. displayMode) or ""))
        end)
    end
end

function FeatureList:SetMode(name, mode)
    name = tostring(name)
    local entry = FeatureEntries[name]
    if not entry or not entry.Frame or not entry.Frame.Parent then return end

    local infoName, infoMode, nameWidth, modeWidth, contentWidth, totalWidth = measureFeature(name, mode)
    entry.Name = infoName
    entry.Mode = infoMode
    entry.NameWidth = nameWidth
    entry.ModeWidth = modeWidth
    entry.ContentWidth = contentWidth
    entry.Width = totalWidth
    entry.NameLabel.Text = infoName
    entry.NameLabel.Size = UDim2.new(1, -(FEATURE_SIDE_PADDING * 2 + (infoMode ~= "" and modeWidth + FEATURE_NAME_MODE_GAP or 0)), 1, 0)
    entry.ModeLabel.Text = infoMode
    entry.ModeLabel.Visible = infoMode ~= ""
    entry.ModeLabel.TextTransparency = infoMode ~= "" and 0.02 or 1
    entry.ModeLabel.Size = UDim2.fromOffset(math.max(1, modeWidth + 2), 16)
    entry.ModeLabel.Position = UDim2.new(1, -(FEATURE_SIDE_PADDING + modeWidth), 0.5, -8)
    if entry.ModeBloom then
        positionModeBloom(entry)
        setModeBloomAlpha(entry, infoMode ~= "" and 1 or 0)
    end
    entry.Frame.Size = UDim2.fromOffset(totalWidth, FEATURE_ROW_HEIGHT)
    updateRGBText(entry)
    layoutFeatureList(true)
    pcall(function()
        showIsland("模式已切换", entry.Name, true, entry.Name .. (entry.Mode ~= "" and ("  " .. entry.Mode) or ""))
    end)
end

function FeatureList:IsEnabled(name)
    local entry = FeatureEntries[tostring(name)]
    return entry ~= nil and entry.Enabled == true and entry.Frame ~= nil and entry.Frame.Parent ~= nil
end

function FeatureList:RefreshColors()
    for _, entry in pairs(FeatureEntries) do
        if entry.Frame and entry.Frame.Parent then
            entry.NameLabel.TextColor3 = Color3.fromRGB(24, 24, 28)
            entry.ModeLabel.TextColor3 = Color3.fromRGB(255, 255, 255)
            entry.NameLabel.TextStrokeTransparency = 1
            entry.ModeLabel.TextStrokeTransparency = 1
            if entry.RGB then updateRGBText(entry) end
        end
    end
end

function FeatureList:Toggle(name, mode)
    name = tostring(name)
    self:Set(name, not self:IsEnabled(name), mode)
end

function FeatureList:Clear()
    for name, entry in pairs(FeatureEntries) do
        destroyFeature(name, entry)
    end
    table.clear(FeatureEntries)
    table.clear(FeatureOrder)
    FeaturePanel.Visible = false
end

_G.NexusFeatureList = FeatureList

_G.NexusPageController = PageController

-- 灵动岛 FPS
-- ================================================================

task.spawn(function()
    local RunService = game:GetService("RunService")
    local frames = 0
    local last = os.clock()
    local fps = 60
    RunService.RenderStepped:Connect(function()
        frames += 1
        local now = os.clock()
        if now - last >= 0.5 then
            fps = math.floor(frames / (now - last) + 0.5)
            frames = 0
            last = now
            if IslandFPS and IslandFPS.Parent then
                IslandFPS.Text = tostring(fps) .. " FPS"
            end
        end
    end)
end)

-- ================================================================
-- 时间标签
-- ================================================================

task.spawn(function()
    local hue = 0
    while ScreenGui.Parent do
        local now = os.date("*t")
        TimeTag.Text = string.format("%02d:%02d", now.hour, now.min)
        hue = (hue + 0.008) % 1
        TimeTag.TextColor3 = Color3.fromHSV(hue, 0.78, 1)
        task.wait(0.05)
    end
end)

-- ================================================================
-- 页面双向切换：第一/第二页均可通过 Tab、按钮和触摸来回切换。
-- UI字体颜色示例：
-- FontColorSelector:Set("纯黑")
-- ================================================================

-- ================================================================

    -- ================================================================
    -- External Library API
    -- ================================================================
    Window.Title = tostring(options.Title or "SyntaxNext")
    Window.FeatureList = FeatureList
    Window.PageController = PageController

    function Window:CreateTab(config)
        local tab = self:Tab(config or {})
        -- Convenience aliases; the original names remain unchanged.
        tab.AddSection = tab.Section
        tab.AddParagraph = tab.Paragraph
        tab.AddButton = tab.Button
        tab.AddToggle = tab.Toggle
        tab.AddKeybind = tab.Keybind
        tab.AddSelector = tab.AnimatedSelector
        tab.AddDropdown = tab.Dropdown
        tab.AddInput = tab.Input
        tab.AddSlider = tab.Slider
        tab.AddCode = tab.Code
        return tab
    end

    function Window:RegisterFeature(name, config)
        config = config or {}
        name = tostring(name)
        local enabled = config.Enabled == true
        local mode = tostring(config.Mode or "")
        FeatureList:Set(name, enabled, mode)

        local api = {}
        function api:Set(value, newMode)
            enabled = value == true
            if newMode ~= nil then mode = tostring(newMode) end
            FeatureList:Set(name, enabled, mode)
        end
        function api:SetMode(newMode)
            mode = tostring(newMode or "")
            FeatureList:SetMode(name, mode)
        end
        function api:IsEnabled()
            return FeatureList:IsEnabled(name)
        end
        function api:Toggle()
            api:Set(not FeatureList:IsEnabled(name))
        end
        return api
    end

    function Window:GetFeatureList()
        return FeatureList
    end

    -- WindUI-style feature-list aliases.
    -- 原有 FeatureList:Set / SetMode / Toggle API 保持不变。
    function Window:Feature(name, config)
        config = config or {}
        return self:RegisterFeature(name, config)
    end

    function Window:AddFeature(name, config)
        config = config or {}
        return self:RegisterFeature(name, config)
    end

    function Window:RemoveFeature(name)
        FeatureList:Set(name, false)
    end

    function Window:GetPageController()
        return PageController
    end

    function Window:SetVisible(visible)
        visible = visible == true
        if visible then
            if _G.NexusShowMainUI then
                _G.NexusShowMainUI()
            else
                MainFrame.Visible = true
            end
        else
            if _G.NexusHideMainUI then
                _G.NexusHideMainUI()
            else
                MainFrame.Visible = false
            end
        end
    end

    function Window:Destroy()
        deleteMainUI()
    end

    -- 默认不创建任何功能页；由外部脚本按需使用 Window:Tab() 添加。
    return Window
end

local SyntaxNextUI = {}
SyntaxNextUI.Version = "1.0.4"

-- WindUI-style API: both dot and colon invocation are supported.
-- UI.CreateWindow(config)
-- UI:CreateWindow(config)
function SyntaxNextUI.CreateWindow(selfOrOptions, maybeOptions)
    local options

    if selfOrOptions == SyntaxNextUI then
        options = maybeOptions
    else
        options = selfOrOptions
    end

    return CreateWindow(options or {})
end

function SyntaxNextUI:Create(config)
    return CreateWindow(config or {})
end

SyntaxNextUI.New = SyntaxNextUI.CreateWindow
SyntaxNextUI.createWindow = SyntaxNextUI.CreateWindow

return SyntaxNextUI
