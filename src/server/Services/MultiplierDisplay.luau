--!strict
-- The server owns the displayed multiplier and countdown. Call update once a
-- second with nextAt/now from the same clock used by the Mini event scheduler.
local Display = {}
Display.__index = Display

local ink = Color3.fromRGB(54, 32, 19)
local peach = Color3.fromRGB(255, 215, 166)

local function corner(parent: Instance, radius: number)
    local rounding = Instance.new('UICorner')
    rounding.CornerRadius = UDim.new(0, radius)
    rounding.Parent = parent
end

local function stroke(parent: Instance, width: number)
    local outline = Instance.new('UIStroke')
    outline.Color = ink
    outline.Thickness = width
    outline.Parent = parent
end

local function label(parent: Instance, name: string, position: UDim2, size: UDim2, text: string, fontSize: number): TextLabel
    local textLabel = Instance.new('TextLabel')
    textLabel.Name = name
    textLabel.BackgroundTransparency = 1
    textLabel.Position = position
    textLabel.Size = size
    textLabel.Font = Enum.Font.FredokaOne
    textLabel.TextSize = fontSize
    textLabel.TextColor3 = peach
    textLabel.TextStrokeColor3 = ink
    textLabel.TextStrokeTransparency = 0
    textLabel.Text = text
    textLabel.Parent = parent
    return textLabel
end

function Display.new(parent: Instance)
    local anchor = Instance.new('Part')
    anchor.Name = 'MiniMultiplierBillboardAnchor'
    anchor.Size = Vector3.new(1, 1, 1)
    anchor.CFrame = CFrame.new(0, 40, 0)
    anchor.Anchored = true
    anchor.CanCollide = false
    anchor.CanTouch = false
    anchor.CanQuery = false
    anchor.Transparency = 1
    anchor.Parent = parent

    local gui = Instance.new('BillboardGui')
    gui.Name = 'MiniMultiplierBillboard'
    gui.Adornee = anchor
    gui.Size = UDim2.fromOffset(460, 125)
    gui.MaxDistance = 500
    gui.AlwaysOnTop = true
    gui.LightInfluence = 0
    gui.Parent = anchor

    local title = label(gui, 'MultiplierTitle', UDim2.fromOffset(0, 0), UDim2.fromOffset(460, 47), 'Mini Multiplier: 1.00x', 35)
    local bar = Instance.new('Frame')
    bar.Name = 'MultiplierRange'
    bar.Position = UDim2.fromOffset(44, 54)
    bar.Size = UDim2.fromOffset(372, 22)
    bar.BackgroundColor3 = Color3.new(1, 1, 1)
    bar.BorderSizePixel = 0
    bar.Parent = gui
    corner(bar, 11)
    stroke(bar, 3)
    local gradient = Instance.new('UIGradient')
    gradient.Color = ColorSequence.new({
        ColorSequenceKeypoint.new(0, Color3.fromRGB(236, 75, 59)),
        ColorSequenceKeypoint.new(.5, Color3.fromRGB(255, 207, 66)),
        ColorSequenceKeypoint.new(1, Color3.fromRGB(94, 202, 69)),
    })
    gradient.Parent = bar

    local marker = Instance.new('Frame')
    marker.Name = 'CurrentMultiplierMarker'
    marker.AnchorPoint = Vector2.new(.5, .5)
    marker.Position = UDim2.fromScale(.5, .5)
    marker.Size = UDim2.fromOffset(13, 34)
    marker.BackgroundColor3 = Color3.fromRGB(255, 250, 229)
    marker.BorderSizePixel = 0
    marker.ZIndex = 2
    marker.Parent = bar
    corner(marker, 5)
    stroke(marker, 3)

    label(gui, 'Minimum', UDim2.fromOffset(22, 79), UDim2.fromOffset(88, 24), '0.50x', 18)
    label(gui, 'Maximum', UDim2.fromOffset(350, 79), UDim2.fromOffset(88, 24), '1.50x', 18)
    local countdown = label(gui, 'NextUpdateCountdown', UDim2.fromOffset(102, 90), UDim2.fromOffset(256, 30), 'Updating in 90s', 23)

    return setmetatable({anchor = anchor, gui = gui, title = title, marker = marker, countdown = countdown}, Display)
end

function Display.update(self: any, valueHundredths: number, nextAt: number, now: number)
    self.title.Text = string.format('Mini Multiplier: %.2fx', valueHundredths / 100)
    self.marker.Position = UDim2.fromScale(math.clamp((valueHundredths - 50) / 100, 0, 1), .5)
    self.countdown.Text = string.format('Updating in %ds', math.max(0, math.ceil(nextAt - now)))
end

function Display.destroy(self: any)
    self.anchor:Destroy()
end

return Display
