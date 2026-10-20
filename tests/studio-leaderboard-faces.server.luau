-- Private unparented boards only; no live-world edits, player progress or remotes.
local Display = require(game.ServerScriptService.Services.LeaderboardDisplay)
local sandbox = Instance.new('Folder')
local player = assert(game.Players:GetPlayers()[1], 'Run during a normal Studio play session')
local parts, rearPlanes = 0, 0
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
        assert(boardParts == 257, 'Preserve 255 existing Parts and add only two rear display planes')
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
    assert(parts == 771 and rearPlanes == 6, 'Three leaderboards may add exactly six noninteractive planes')
end, debug.traceback)
sandbox:Destroy()
assert(ok, err)
return 'PASS three two-sided native boards, upright reversed surfaces, matching live rows/clear, current-server scope and six inert added Parts (765 -> 771)'
