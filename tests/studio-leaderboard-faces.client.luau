-- Read-only inspection after normal Main.client footer updates have run.
local player = assert(game.Players.LocalPlayer)
local root = assert(workspace:FindFirstChild('MergeABrainrotGenerated'))
local boards = 0
for _, board in root:GetDescendants() do
    if not board:IsA('Model') or not board:GetAttribute('LeaderboardKey') then continue end
    boards += 1
    local front = assert(board:FindFirstChild('LeaderboardBodyPlane')).LeaderboardBody
    local rear = assert(board:FindFirstChild('LeaderboardBodyRearPlane')).LeaderboardBodyRear
    assert(front.ServerScope.Text == 'CURRENT SERVER' and rear.ServerScope.Text == front.ServerScope.Text)
    local rank = nil
    for _, row in front.LeaderboardRows:GetChildren() do
        local other = assert(rear.LeaderboardRows:FindFirstChild(row.Name))
        assert(row.Visible == other.Visible and row:GetAttribute('UserId') == other:GetAttribute('UserId'), 'Replicated rank identities must match on both sides')
        assert(row.Username.Text == other.Username.Text and row.Metric.Text == other.Metric.Text, 'Replicated player lists must match')
        if row.Visible and row:GetAttribute('UserId') == player.UserId then rank = row:GetAttribute('Rank') end
    end
    local first, second = front.PersonalLeaderboardFooter, rear.PersonalLeaderboardFooter
    assert(first.RichText and second.RichText and first.Text == second.Text, 'Both faces must show the same local-player footer')
    local expected = if rank then 'You are #' .. rank .. ' on the leaderboard!' else 'You are not on the leaderboard!'
    assert(first.Text:sub(1, #expected) == expected, 'Personal rank must belong to this client session')
    assert(first.Text:find('<font color=', 1, true), 'Wait for normal client footer initialization before running this fixture')
end
assert(boards == 3, 'All three live leaderboard pairs must be present')
return 'PASS six live leaderboard faces, replicated lists/current-server scope and local-session personal footer ranks'
