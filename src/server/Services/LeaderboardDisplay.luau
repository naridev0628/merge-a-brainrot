--!strict
-- Original native wood boards. Rankings describe this server's current players.
local Players = game:GetService('Players')
local Display = {}
local wood = Color3.fromRGB(146, 98, 76)
local trim = Color3.fromRGB(76, 47, 31)
local ink = Color3.fromRGB(23, 18, 14)
local rankColors = {
    Color3.fromRGB(255, 226, 61),
    Color3.fromRGB(231, 237, 245),
    Color3.fromRGB(255, 175, 73),
}
local thumbnails: {[number]: string} = {}
local requests: {[number]: {(string) -> ()}} = {}

local function thumbnail(userId: number, receive: (string) -> ())
    local cached = thumbnails[userId]
    if cached then receive(cached); return end
    if requests[userId] then table.insert(requests[userId], receive); return end
    requests[userId] = {receive}
    task.spawn(function()
        local ok, content, ready = pcall(function()
            return Players:GetUserThumbnailAsync(userId, Enum.ThumbnailType.HeadShot, Enum.ThumbnailSize.Size100x100)
        end)
        local image = if ok and ready and type(content) == 'string' then content else ''
        if image ~= '' then thumbnails[userId] = image end
        local waiting = requests[userId]
        requests[userId] = nil
        for _, callback in waiting or {} do callback(image) end
    end)
end

local function part(parent: Instance, name: string, size: Vector3, cf: CFrame, color: Color3, collide: boolean?): Part
    local block = Instance.new('Part')
    block.Name = name
    block.Size = size
    block.CFrame = cf
    block.Color = color
    block.Material = Enum.Material.Plastic
    block.Anchored = true
    block.CanCollide = collide == true
    block.CanTouch = false
    block.CanQuery = collide == true
    block.TopSurface = Enum.SurfaceType.Smooth
    block.BottomSurface = Enum.SurfaceType.Smooth
    block.Parent = parent
    return block
end

local function rounded(parent: Instance, radius: UDim)
    local corner = Instance.new('UICorner')
    corner.CornerRadius = radius
    corner.Parent = parent
end

local function text(parent: Instance, name: string, value: string, pos: UDim2, size: UDim2, fontSize: number, color: Color3): TextLabel
    local label = Instance.new('TextLabel')
    label.Name = name
    label.BackgroundTransparency = 1
    label.Position = pos
    label.Size = size
    label.Font = Enum.Font.FredokaOne
    label.TextSize = fontSize
    label.TextColor3 = color
    label.TextStrokeColor3 = ink
    label.TextStrokeTransparency = 0
    label.Text = value
    label.Parent = parent
    return label
end

function Display.compact(value: number): string
    local amount, suffix = value, ''
    if math.abs(value) >= 1e9 then amount, suffix = value / 1e9, 'B'
    elseif math.abs(value) >= 1e6 then amount, suffix = value / 1e6, 'M'
    elseif math.abs(value) >= 1e3 then amount, suffix = value / 1e3, 'K' end
    local number = string.format('%.2f', amount):gsub('%.?0+$', '')
    return number .. suffix
end

function Display.time(seconds: number): string
    local minutes = math.max(0, math.floor(seconds / 60))
    local days = math.floor(minutes / 1440)
    local hours = math.floor(minutes / 60) % 24
    local remainder = minutes % 60
    if days > 0 then return string.format('%dd %dh %dm', days, hours, remainder) end
    if hours > 0 then return string.format('%dh %dm', hours, remainder) end
    return string.format('%dm', remainder)
end

function Display.new(parent: Instance, key: string, title: string, color: Color3, cf: CFrame)
    assert(key == 'coins' or key == 'time' or key == 'count', 'Unknown leaderboard key')
    local model = Instance.new('Model')
    model.Name = 'Leaderboard_' .. key
    model:SetAttribute('LeaderboardKey', key)
    model:SetAttribute('LeaderboardColor', color)
    model:SetAttribute('LeaderboardScope', 'CurrentServer')

    -- The panel is 23 by 24 studs. Feet extend two studs below the panel;
    -- passing a CFrame at Y=14 places the feet on the ground.
    part(model, 'BoardBack', Vector3.new(22.4, 19.6, 1), CFrame.new(0, -2, 0), wood, true)
    part(model, 'HeaderBack', Vector3.new(22.4, 4, 1), CFrame.new(0, 10, 0), wood, true)
    for _, x in {-10.6, 10.6} do
        part(model, 'WoodPost', Vector3.new(1, 25.4, 1.4), CFrame.new(x, -1.3, .05), trim, true)
        part(model, 'PostFoot', Vector3.new(1.8, .65, 3), CFrame.new(x, -13.675, .1), trim, true)
    end
    for _, y in {-11.6, 7.9, 11.6} do
        part(model, 'WoodRail', Vector3.new(23, .8, 1.6), CFrame.new(0, y, -.1), trim, true)
        part(model, 'RailHighlight', Vector3.new(23, .12, 1.65), CFrame.new(0, y + .34, -.1), Color3.fromRGB(116, 75, 43))
        for x = -10.5, 10.5, 1.5 do
            part(model, 'RailPeg', Vector3.new(.48, .28, .16), CFrame.new(x, y, -.98), Color3.fromRGB(168, 113, 61))
        end
    end
    for y = -10.7, 11.3, 1.5 do
        for x = -9.9, 9.9, 1.5 do
            if y < 7.1 or y > 8.7 then
                part(model, 'SquareWoodStud', Vector3.new(.64, .64, .22), CFrame.new(x, y, -.61), Color3.fromRGB(166, 115, 89))
            end
        end
    end

    local function surface(name: string, size: Vector3, position: Vector3, canvas: Vector2): SurfaceGui
        -- Keep text physically in front of every stud and peg. AlwaysOnTop is
        -- false so the board still occludes normally within the world.
        local plane = part(model, name .. 'Plane', size, CFrame.new(position), wood)
        plane.Transparency = 1
        local gui = Instance.new('SurfaceGui')
        gui.Name = name
        gui.Face = Enum.NormalId.Front
        gui.SizingMode = Enum.SurfaceGuiSizingMode.FixedSize
        gui.CanvasSize = canvas
        gui.AlwaysOnTop = false
        gui.LightInfluence = 0
        gui.MaxDistance = 350
        gui.Parent = plane
        return gui
    end
    local header = surface('LeaderboardHeader', Vector3.new(21.5, 3.2, .02), Vector3.new(0, 10, -1.15), Vector2.new(690, 120))
    local heading = text(header, 'Title', title, UDim2.fromOffset(10, 0), UDim2.fromOffset(670, 120), 58, color)
    heading.TextScaled = true
    local headingSize = Instance.new('UITextSizeConstraint')
    headingSize.MaxTextSize = 58
    headingSize.MinTextSize = 34
    headingSize.Parent = heading

    local body = surface('LeaderboardBody', Vector3.new(21.5, 18.7, .02), Vector3.new(0, -2, -1.15), Vector2.new(690, 600))
    text(body, 'ServerScope', 'CURRENT SERVER', UDim2.fromOffset(0, 0), UDim2.fromOffset(690, 30), 18, Color3.fromRGB(255, 236, 203))
    local rowHolder = Instance.new('Frame')
    rowHolder.Name = 'LeaderboardRows'
    rowHolder.BackgroundTransparency = 1
    rowHolder.Position = UDim2.fromOffset(0, 35)
    rowHolder.Size = UDim2.fromOffset(690, 495)
    rowHolder.Parent = body
    local rows = {}
    for rank = 1, 9 do
        local frame = Instance.new('Frame')
        frame.Name = 'Row' .. rank
        frame.Position = UDim2.fromOffset(8, (rank - 1) * 55)
        frame.Size = UDim2.fromOffset(674, 54)
        frame.BackgroundTransparency = 1
        frame.Visible = false
        frame:SetAttribute('Rank', rank)
        frame.Parent = rowHolder
        local rankColor = rankColors[rank] or (if rank % 2 == 0 then Color3.fromRGB(201, 251, 255) else Color3.fromRGB(255, 255, 245))
        text(frame, 'Rank', '#' .. rank, UDim2.fromOffset(0, 0), UDim2.fromOffset(58, 54), 31, rankColor)
        local avatar = Instance.new('ImageLabel')
        avatar.Name = 'Avatar'
        avatar.Position = UDim2.fromOffset(62, 2)
        avatar.Size = UDim2.fromOffset(50, 50)
        avatar.BackgroundColor3 = Color3.fromRGB(55, 45, 39)
        avatar.BorderSizePixel = 0
        avatar.Image = ''
        avatar.Parent = frame
        rounded(avatar, UDim.new(.5, 0))
        local border = Instance.new('UIStroke')
        border.Color = ink
        border.Thickness = 2
        border.Parent = avatar
        local username = text(frame, 'Username', '', UDim2.fromOffset(122, 0), UDim2.fromOffset(335, 54), 29, rankColor)
        username.TextXAlignment = Enum.TextXAlignment.Left
        username.TextScaled = true
        local usernameSize = Instance.new('UITextSizeConstraint')
        usernameSize.MaxTextSize = 29
        usernameSize.MinTextSize = 17
        usernameSize.Parent = username
        local metric = text(frame, 'Metric', '', UDim2.fromOffset(461, 0), UDim2.fromOffset(207, 54), 30, rankColor)
        metric.TextXAlignment = Enum.TextXAlignment.Right
        metric.TextScaled = true
        local metricSize = Instance.new('UITextSizeConstraint')
        metricSize.MaxTextSize = 30
        metricSize.MinTextSize = 18
        metricSize.Parent = metric
        table.insert(rows, {frame = frame, avatar = avatar, username = username, metric = metric})
    end
    local footer = text(body, 'PersonalLeaderboardFooter', 'You are not on the leaderboard! [0]', UDim2.fromOffset(4, 546), UDim2.fromOffset(682, 45), 23, Color3.new(1, 1, 1))
    footer.RichText = true
    footer.TextScaled = true
    local footerSize = Instance.new('UITextSizeConstraint')
    footerSize.MaxTextSize = 23
    footerSize.MinTextSize = 15
    footerSize.Parent = footer

    -- Bridge approaches see the rear of these inward-facing boards. Reuse the
    -- exact UI layout on two inert rear planes, with a real outward-facing
    -- orientation so names and rankings remain readable rather than mirrored.
    local function rearSurface(front: SurfaceGui): SurfaceGui
        local frontPlane = front.Parent :: BasePart
        local plane = frontPlane:Clone()
        plane.Name = front.Name .. 'RearPlane'
        plane.CFrame = frontPlane.CFrame * CFrame.new(0, 0, 2.3) * CFrame.Angles(0, math.pi, 0)
        plane.CastShadow = false
        local gui = plane:FindFirstChild(front.Name) :: SurfaceGui
        gui.Name = front.Name .. 'Rear'
        plane.Parent = model
        return gui
    end
    rearSurface(header)
    local rearBody = rearSurface(body)
    local rearHolder = rearBody:FindFirstChild('LeaderboardRows') :: Frame
    local rearRows = {}
    for _, row in rows do
        local frame = rearHolder:FindFirstChild(row.frame.Name) :: Frame
        table.insert(rearRows, {
            frame = frame,
            avatar = frame:FindFirstChild('Avatar') :: ImageLabel,
            username = frame:FindFirstChild('Username') :: TextLabel,
            metric = frame:FindFirstChild('Metric') :: TextLabel,
        })
    end
    local faces = {
        {rows = rows, footer = footer},
        {rows = rearRows, footer = rearBody:FindFirstChild('PersonalLeaderboardFooter') :: TextLabel},
    }
    model.WorldPivot = CFrame.identity
    model:PivotTo(cf)
    model.Parent = parent
    return {key = key, rootModel = model, rows = rows, footer = footer, faces = faces}
end

function Display.update(board: any, entries: {any})
    local ordered = table.clone(entries)
    table.sort(ordered, function(a, b)
        if a[board.key] == b[board.key] then return a.userId < b.userId end
        return a[board.key] > b[board.key]
    end)
    for rank = 1, #board.rows do
        local entry = ordered[rank]
        local imageRows = {}
        for _, face in board.faces do
            local row = face.rows[rank]
            row.frame.Visible = entry ~= nil
            if entry then
                local oldUserId = row.frame:GetAttribute('UserId')
                row.frame:SetAttribute('UserId', entry.userId)
                row.username.Text = '@' .. entry.name
                row.metric.Text = if board.key == 'time' then Display.time(entry.time) else (if board.key == 'coins' then '$' else '') .. Display.compact(entry[board.key])
                if oldUserId ~= entry.userId or row.avatar.Image == '' then
                    row.avatar.Image = ''
                    table.insert(imageRows, row)
                end
            else
                row.frame:SetAttribute('UserId', nil)
                row.username.Text = ''
                row.metric.Text = ''
                row.avatar.Image = ''
            end
        end
        if entry and #imageRows > 0 then
            local userId = entry.userId
            thumbnail(userId, function(image)
                for _, row in imageRows do
                    if row.frame.Parent and row.frame:GetAttribute('UserId') == userId then row.avatar.Image = image end
                end
            end)
        end
    end
end

return Display
