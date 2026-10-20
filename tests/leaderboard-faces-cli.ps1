$ErrorActionPreference = 'Stop'
$repo = Split-Path -Parent $PSScriptRoot
# Execute the actual modules with a small Instance substitute and a controlled
# thumbnail queue. Native surface orientation is also covered by the Studio fixture.
$runtime = @'
local function signal()
    local listeners = {}
    return {
        Connect = function(_, callback)
            local connection = {Connected = true}
            function connection:Disconnect() self.Connected = false end
            table.insert(listeners, {connection, callback})
            return connection
        end,
        Fire = function(_, value)
            for _, item in listeners do if item[1].Connected then item[2](value) end end
        end,
    }
end
local methods = {}
local Instance = {}
function Instance.new(class)
    return setmetatable({_props = {ClassName = class, Name = class, DescendantAdded = signal()}, _children = {}, _attributes = {}}, {
        __index = function(self, key) return methods[key] or self._props[key] end,
        __newindex = function(self, key, value)
            if key == 'Parent' then
                local old = self._props.Parent
                if old then table.remove(old._children, assert(table.find(old._children, self))) end
                self._props.Parent = value
                if value then
                    table.insert(value._children, self)
                    local added = self:GetDescendants()
                    table.insert(added, 1, self)
                    while value do
                        for _, descendant in added do value.DescendantAdded:Fire(descendant) end
                        value = value.Parent
                    end
                end
            else self._props[key] = value end
        end,
    })
end
function methods:IsA(class) return self.ClassName == class or (class == 'BasePart' and self.ClassName == 'Part') end
function methods:GetChildren() return table.clone(self._children) end
function methods:GetDescendants()
    local result = {}
    for _, child in self._children do
        table.insert(result, child)
        for _, descendant in child:GetDescendants() do table.insert(result, descendant) end
    end
    return result
end
function methods:FindFirstChild(name, recursive)
    for _, child in self._children do if child.Name == name then return child end end
    if recursive then
        for _, child in self._children do
            local found = child:FindFirstChild(name, true)
            if found then return found end
        end
    end
    return nil
end
function methods:WaitForChild(name) return assert(self:FindFirstChild(name), name) end
function methods:IsDescendantOf(root)
    local parent = self.Parent
    while parent do if parent == root then return true end; parent = parent.Parent end
    return false
end
function methods:SetAttribute(key, value) self._attributes[key] = value end
function methods:GetAttribute(key) return self._attributes[key] end
function methods:PivotTo(cf) self.WorldPivot = cf end
function methods:Clone()
    local copy = Instance.new(self.ClassName)
    for key, value in self._props do
        if key ~= 'Parent' and key ~= 'DescendantAdded' then copy[key] = value end
    end
    copy._attributes = table.clone(self._attributes)
    for _, child in self._children do child:Clone().Parent = copy end
    return copy
end
function methods:Destroy()
    for _, child in self:GetChildren() do child:Destroy() end
    self.Parent = nil
end
local function vector(x, y, z) return {X = x, Y = y, Z = z} end
local frameMeta = {}
frameMeta.__mul = function(a, b)
    local p, q = a.Position or vector(0, 0, 0), b.Position or vector(0, 0, 0)
    return setmetatable({Position = vector(p.X + q.X, p.Y + q.Y, p.Z + q.Z), Yaw = (a.Yaw or 0) + (b.Yaw or 0)}, frameMeta)
end
local CFrame = {
    new = function(x, y, z) return setmetatable({Position = if type(x) == 'table' then x else vector(x or 0, y or 0, z or 0), Yaw = 0}, frameMeta) end,
    Angles = function(_, y) return setmetatable({Yaw = y}, frameMeta) end,
}
CFrame.identity = CFrame.new()
local function color(r, g, b) return {R = r, G = g, B = b, _type = 'Color3'} end
local Color3 = {new = color, fromRGB = function(r, g, b) return color(r / 255, g / 255, b / 255) end}
local Enum = setmetatable({}, {__index = function(_, key) return setmetatable({}, {__index = function(_, item) return key .. '.' .. item end}) end})
local pending, thumbnailCalls = {}, {}
local Players = {LocalPlayer = {UserId = 11}}
function Players:GetUserThumbnailAsync(id)
    thumbnailCalls[id] = (thumbnailCalls[id] or 0) + 1
    return 'thumb:' .. id, true
end
local storage, shared = Instance.new('Folder'), Instance.new('Folder')
shared.Name = 'Shared'; shared.Parent = storage
local catalogModule = Instance.new('ModuleScript'); catalogModule.Name = 'CreatureCatalog'; catalogModule.Parent = shared
local configModule = Instance.new('ModuleScript'); configModule.Name = 'Config'; configModule.Parent = shared
local groundModule = Instance.new('ModuleScript'); groundModule.Name = 'GroundSurface'; groundModule.Parent = shared
local panelCalls={}
local GroundSurface
local workspace = Instance.new('Folder')
local environment = setmetatable({
    Instance = Instance, CFrame = CFrame, Color3 = Color3, Enum = Enum,
    Vector3 = {new = vector}, Vector2 = {new = vector},
    UDim = {new = vector}, UDim2 = {fromOffset = vector},
    game = {GetService = function(_, name) return if name == 'Players' then Players else storage end},
    task = {spawn = function(callback) table.insert(pending, callback) end},
    workspace = workspace,
    require = function(module)
        if module==groundModule then return GroundSurface end
        if module==configModule then return {MergeCount=3} end
        assert(module == catalogModule); return {small = {tier = 1}, large = {tier = 4}}
    end,
    typeof = function(value) return if type(value) == 'table' and value._type then value._type else type(value) end,
}, {__index = getfenv()})
local function compile(source)
    local chunk = assert(loadstring(source))
    setfenv(chunk, environment)
    return chunk()
end
'@
$display = Get-Content -LiteralPath (Join-Path $repo 'src/server/Services/LeaderboardDisplay.luau') -Raw
$footer = Get-Content -LiteralPath (Join-Path $repo 'src/client/Controllers/LeaderboardFooter.luau') -Raw
$ground = Get-Content -LiteralPath (Join-Path $repo 'src/shared/GroundSurface.luau') -Raw
$scriptText = $runtime + "`nlocal ActualGround = compile([====[`n" + $ground + "`n]====])`n"
$scriptText += @'
GroundSurface={panel=function(parent,frame,width,height,tone)
    assert(tone=='Brown' and frame.Position.Z==-.52 and width==19.8 and (height==18.8 or height==3))
    table.insert(panelCalls,{width=width,height=height})
    local result=ActualGround.panel(parent,frame,width,height,tone)
    assert(result:GetAttribute('TileCount')==(if height==18.8 then 4 else 2),'Actual tiling must stay bounded')
    for _,tile in result:GetChildren() do
        assert(tile.Anchored and not tile.CanCollide and not tile.CanTouch and not tile.CanQuery)
    end
    return result
end}
'@
$scriptText += "`nlocal Display = compile([====[`n" + $display + "`n]====])`nlocal Footer = compile([====[`n" + $footer + "`n]====])`n"
$scriptText += @'
local root = Instance.new('Folder'); root.Name = 'MergeABrainrotGenerated'; root.Parent = workspace
assert(Display.compact(0)=='0' and Display.compact(1250)=='1.25K')
assert(Display.compact(7249674957000)=='7.25T' and Display.compact(2e15)=='2Qa',
    'Largest current economy values must remain short and readable')
local boards = {}
local parts, rearPlanes = 0, 0
for _, key in {'coins', 'time', 'count'} do
    local board = Display.new(root, key, key, Color3.fromRGB(255, 200, 100), CFrame.identity)
    assert(board.faces and #board.faces == 2, 'Each leaderboard needs two live faces')
    assert(board.rows == board.faces[1].rows and board.footer == board.faces[1].footer, 'Keep canonical front handles')
    assert(board.rootModel:GetAttribute('LeaderboardScope')=='CurrentServer','Never label local preview standings as global')
    assert(board.rows[1].avatar:FindFirstChild('UIStroke').Thickness==3 and board.rows[4].avatar:FindFirstChild('UIStroke').Thickness==2,
        'Top three avatar frames must carry the medal emphasis')
    for _, instance in board.rootModel:GetDescendants() do
        if instance:IsA('BasePart') then
            parts += 1
            if instance.Name:match('RearPlane$') then
                rearPlanes += 1
                assert(instance.Anchored and not instance.CanCollide and not instance.CanTouch and not instance.CanQuery)
            end
        end
    end
    table.insert(boards, board)
end
assert(parts<771 and rearPlanes==6 and #panelCalls==6,'Use two reusable brown panels per board and preserve six inert rear planes')
local entries = {
    {userId = 22, name = 'Second', coins = 2200, time = 7200, count = 20},
    {userId = 11, name = 'First', coins = 1100, time = 3600, count = 10},
}
for _, board in boards do Display.update(board, entries) end
assert(#pending == 2, 'All six faces must share one pending thumbnail request per player')
assert(entries[1].userId == 22, 'Rendering must not mutate caller order')
local oldFirstRows = {}
for _, board in boards do
    for _, face in board.faces do table.insert(oldFirstRows, face.rows[1]) end
end
entries[2].coins = 3300; entries[2].time = 10800; entries[2].count = 30
for _, board in boards do Display.update(board, entries) end
assert(#pending == 2, 'Rank changes must coalesce existing thumbnail requests')
pending[1]()
for _, row in oldFirstRows do assert(row.avatar.Image == '', 'Late old-user thumbnail must not overwrite the replacement row') end
pending[2]()
local function equalFaces(board)
    for rank, front in board.faces[1].rows do
        local rear = board.faces[2].rows[rank]
        assert(front.frame.Visible == rear.frame.Visible)
        assert(front.frame:GetAttribute('UserId') == rear.frame:GetAttribute('UserId'))
        assert(front.username.Text == rear.username.Text and front.metric.Text == rear.metric.Text)
        assert(front.avatar.Image == rear.avatar.Image)
    end
end
for _, board in boards do
    equalFaces(board)
    assert(board.rows[1].avatar.Image == 'thumb:11' and board.rows[2].avatar.Image == 'thumb:22')
end
assert(thumbnailCalls[11] == 1 and thumbnailCalls[22] == 1, 'No duplicate avatar fetches across faces or boards')
local state = {coinUnits = 13200, timePlayed = 10800, producers = {{speciesId = 'small'}, {speciesId = 'large'}}}
Footer.update(state)
local expected = {coins = '$3.3K', time = '3h 0m', count = '28'}
for _, board in boards do
    for _, face in board.faces do
        assert(face.footer.Text:find('You are #1 on the leaderboard!', 1, true), 'Both personal footers need the local rank')
        assert(face.footer.Text:find('[' .. expected[board.key] .. ']', 1, true), 'Both personal footers need the local value')
    end
end
Footer.update({coinUnits=8e15})
for _,face in boards[1].faces do assert(face.footer.Text:find('[$2Qa]',1,true),'Personal value must use the same large-value units') end
-- Equal scores use stable user ID order; removed rows must clear on both faces.
entries[1].coins = 3300; entries[1].time = 10800; entries[1].count = 30
for _, board in boards do
    Display.update(board, entries)
    assert(board.rows[1].frame:GetAttribute('UserId') == 11)
    Display.update(board, {entries[1]})
    equalFaces(board)
    assert(not board.rows[2].frame.Visible and board.rows[2].avatar.Image == '')
end
Footer.update(state)
for _, board in boards do
    for _, face in board.faces do assert(face.footer.Text:find('You are not on the leaderboard!', 1, true)) end
end
-- Replacing the generated world must stop writes to old boards and discover new ones.
local oldText = boards[1].footer.Text
root.Parent = nil
local replacement = Instance.new('Folder'); replacement.Name = 'MergeABrainrotGenerated'; replacement.Parent = workspace
local models=Instance.new('Folder');models.Name='MapModels';models.Parent=storage
local brown=Instance.new('MeshPart');brown.Name='GroundBrownTile';brown.Parent=models
local nextBoard = Display.new(replacement, 'coins', 'Net Worth', Color3.new(1, 1, 1), CFrame.identity)
local meshTiles=0
for _,item in nextBoard.rootModel:GetDescendants() do
    if item:IsA('MeshPart') then meshTiles+=1 end
    if item.Name=='AuthoredBrownPanel' then assert(not item:GetAttribute('MissingTemplate')) end
end
assert(meshTiles==6,'Imported brown Blender template must be reused on both insets')
Display.update(nextBoard, {entries[2]})
Footer.update({coinUnits = 80})
assert(boards[1].footer.Text == oldText, 'Detached worlds must stop receiving personal footer updates')
for _, face in nextBoard.faces do assert(face.footer.Text:find('[$20]', 1, true)) end
-- Newly built boards are discovered without a root replacement.
local added = Display.new(replacement, 'time', 'Time', Color3.new(1, 1, 1), CFrame.identity)
Display.update(added, {entries[2]})
Footer.update({timePlayed = 65})
for _, face in added.faces do assert(face.footer.Text:find('[1m]', 1, true)) end
assert(#pending == 2, 'Cached avatars must be reused for replacement boards')
-- Destroying a board before an outstanding avatar completes must be harmless.
Display.update(added, {{userId = 33, name = 'Leaving', time = 5}})
added.rootModel:Destroy()
pending[3]()
print('PASS two-sided rows, sorting/ties/removal, one avatar fetch per user, delayed callbacks, personal values and world replacement')
print('PASS brown Blender panel integration, larger medal rows, exact three-to-one counts, T/Qa formatting and six noninteractive rear planes')
'@
$target = Join-Path $repo '.tools/leaderboard-faces-cli.luau'
[System.IO.File]::WriteAllText($target, $scriptText)
& (Join-Path $repo '.tools/luau/luau.exe') $target
exit $LASTEXITCODE
