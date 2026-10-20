-- Requires Source access. Private unparented boards and a temporary module clone;
-- no live-world edits, production Source changes, player progress or remotes.
local original = game.ServerScriptService.Services.LeaderboardDisplay
local Display = require(original)
local sandbox = Instance.new('Folder')
local player = assert(game.Players:GetPlayers()[1], 'Run during a normal Studio play session')
local parts, rearPlanes = 0, 0
local asyncModule, asyncState
local function waitUntil(predicate)
    local deadline = os.clock() + 3
    while not predicate() and os.clock() < deadline do task.wait() end
    assert(predicate(), 'Timed out waiting for native thumbnail workers')
end
local ok, err = xpcall(function()
    for index, key in {'coins', 'time', 'count'} do
        local cf = CFrame.new(index * 30, 14, -20) * CFrame.Angles(0, index * 1.2, 0)
        local board = Display.new(sandbox, key, 'Private board', Color3.fromRGB(255, 220, 80), cf)
        assert(#board.faces == 2 and board.rows == board.faces[1].rows and board.footer == board.faces[1].footer)
        assert(board.rootModel:GetAttribute('LeaderboardScope') == 'CurrentServer', 'Both faces must keep honest server scope')
        local boardParts = 0
        for _, instance in board.rootModel:GetDescendants() do
            if instance:IsA('BasePart') then boardParts += 1 end
        end
        assert(boardParts>=61 and boardParts<257, 'Blender tile panels must replace the dense individual-stud grid')
        parts += boardParts
        for _, name in {'LeaderboardHeader', 'LeaderboardBody'} do
            local front = assert(board.rootModel:FindFirstChild(name .. 'Plane'))
            local rear = assert(board.rootModel:FindFirstChild(name .. 'RearPlane'))
            local frontGui = assert(front:FindFirstChild(name))
            local rearGui = assert(rear:FindFirstChild(name .. 'Rear'))
            assert(rear.Anchored and not rear.CanCollide and not rear.CanTouch and not rear.CanQuery, 'Rear faces must not affect movement or targeting')
            assert(rear.Transparency == 1 and not rear.CastShadow, 'Only rear text should render')
            assert(rear.Size == front.Size and rearGui.CanvasSize == frontGui.CanvasSize, 'Both faces must keep the original layout dimensions')
            assert(frontGui.Face == Enum.NormalId.Front and rearGui.Face == Enum.NormalId.Front, 'Rotate the real surface; do not mirror text')
            assert(not rearGui.AlwaysOnTop and rearGui.MaxDistance == frontGui.MaxDistance, 'Rear text must obey the same world occlusion and distance')
            assert(front.CFrame.LookVector:Dot(rear.CFrame.LookVector) < -.99999, 'Rear face must point outwards')
            assert(front.CFrame.UpVector:Dot(rear.CFrame.UpVector) > .99999, 'Rear text must remain upright')
            local relative = front.CFrame:PointToObjectSpace(rear.Position)
            assert((relative - Vector3.new(0, 0, 2.3)).Magnitude < .0001, 'Rear face must sit beyond the wood without moving the front')
            rearPlanes += 1
        end
        local entries = {{userId = player.UserId, name = player.Name, coins = 1250, time = 3660, count = 8}}
        Display.update(board, entries)
        for _, face in board.faces do
            assert(face.rows[1].frame.Visible and face.rows[1].frame:GetAttribute('UserId') == player.UserId)
            assert(face.rows[1].username.Text == '@' .. player.Name)
            local expected = if key == 'coins' then '$1.25K' elseif key == 'time' then '1h 1m' else '8'
            assert(face.rows[1].metric.Text == expected, 'Native row text must match on both faces')
            assert(not face.rows[2].frame.Visible, 'Unused ranks must remain hidden')
        end
        Display.update(board, {})
        for _, face in board.faces do
            assert(not face.rows[1].frame.Visible and face.rows[1].frame:GetAttribute('UserId') == nil)
            assert(face.rows[1].username.Text == '' and face.rows[1].metric.Text == '' and face.rows[1].avatar.Image == '')
        end
    end
    assert(parts<771 and rearPlanes == 6, 'Reuse brown panels and preserve exactly six noninteractive rear planes')

    -- Keep the actual task.spawn scheduling and UI Instances; control only the
    -- thumbnail provider so delayed responses and fetch counts are deterministic.
    local injection = [[
local fixture = {calls={},released={},workers={},errors={},completed=0}
local nativeTask=task
local task={spawn=function(callback)
    return nativeTask.spawn(function()
        local worker=coroutine.running();fixture.workers[worker]=true
        local success,problem=xpcall(callback,debug.traceback)
        if not success then table.insert(fixture.errors,problem) end
        fixture.workers[worker]=nil;fixture.completed+=1
    end)
end}
local Players={}
function Players:GetUserThumbnailAsync(id)
    fixture.calls[id]=(fixture.calls[id] or 0)+1
    while not fixture.released[id] do nativeTask.wait() end
    return 'rbxthumb://type=AvatarHeadShot&id='..id..'&w=100&h=100',true
end
]]
    local source, providers = original.Source:gsub("local Players = game:GetService%('Players'%)", function() return injection end)
    assert(providers == 1, 'Expected exactly one thumbnail provider')
    local exports
    source, exports = source:gsub('return Display%s*$', 'Display.__thumbnailFixture=fixture\nreturn Display')
    assert(exports == 1, 'Expected one Display export')
    asyncModule = original:Clone(); asyncModule.Name = 'LeaderboardThumbnailFixture'
    asyncModule.Source = source; asyncModule.Parent = original.Parent
    local isolated = require(asyncModule)
    asyncState = isolated.__thumbnailFixture
    local boards = {}
    for _, key in {'coins', 'time'} do
        table.insert(boards, isolated.new(sandbox, key, 'Async fixture', Color3.new(1, 1, 1), CFrame.identity))
    end
    local entries = {
        {userId=11,name='First',coins=100,time=100,count=1},
        {userId=22,name='Second',coins=200,time=200,count=2},
    }
    for _, board in boards do isolated.update(board, entries) end
    waitUntil(function() return asyncState.calls[11] and asyncState.calls[22] end)
    entries[1].coins=300; entries[1].time=300
    for _, board in boards do isolated.update(board, entries) end
    assert(asyncState.calls[11] == 1 and asyncState.calls[22] == 1, 'Pending avatar requests must coalesce across faces/boards')
    asyncState.released[22]=true
    waitUntil(function() return asyncState.completed == 1 end)
    for _, board in boards do for _, face in board.faces do
        assert(face.rows[1].frame:GetAttribute('UserId') == 11 and face.rows[1].avatar.Image == '',
            'An old-user response must not overwrite the replacement row')
        assert(face.rows[2].avatar.Image:find('id=22&', 1, true), 'Current rows must receive the delayed response')
    end end
    asyncState.released[11]=true
    waitUntil(function() return asyncState.completed == 2 end)
    for _, board in boards do
        isolated.update(board, {})
        isolated.update(board, entries)
        for _, face in board.faces do assert(face.rows[1].avatar.Image:find('id=11&', 1, true), 'Cached avatar must restore immediately') end
    end
    assert(asyncState.calls[11] == 1 and asyncState.calls[22] == 1, 'Cached avatars must not refetch')
    isolated.update(boards[1], {{userId=33,name='Leaving',coins=1,time=1,count=1}})
    waitUntil(function() return asyncState.calls[33] == 1 end)
    boards[1].rootModel:Destroy(); asyncState.released[33]=true
    waitUntil(function() return asyncState.completed == 3 end)
    assert(#asyncState.errors == 0, table.concat(asyncState.errors, '\n'))
end, debug.traceback)
if asyncState then for worker in asyncState.workers do task.cancel(worker) end end
if asyncModule then asyncModule:Destroy() end
sandbox:Destroy()
assert(ok, err)
return 'PASS three two-sided native boards, matching rows/clear, brown tile panels and six inert rear planes; native async thumbnail coalescing, stale-row rejection, cache reuse and destroyed-row cleanup'
