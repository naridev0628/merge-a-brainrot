--!strict
-- This label is personal: client writes never overwrite another player's footer.
local Players = game:GetService('Players')
local Catalog = require(game:GetService('ReplicatedStorage'):WaitForChild('Shared'):WaitForChild('CreatureCatalog'))
local Footer = {}
local currentRoot: Instance? = nil
local addedConnection: RBXScriptConnection? = nil
local boards: {[Instance]: boolean} = {}

local function compact(value: number): string
    local amount, suffix = value, ''
    if math.abs(value) >= 1e9 then amount, suffix = value / 1e9, 'B'
    elseif math.abs(value) >= 1e6 then amount, suffix = value / 1e6, 'M'
    elseif math.abs(value) >= 1e3 then amount, suffix = value / 1e3, 'K' end
    return string.format('%.2f', amount):gsub('%.?0+$', '') .. suffix
end

local function duration(seconds: number): string
    local minutes = math.max(0, math.floor(seconds / 60))
    local days = math.floor(minutes / 1440)
    local hours = math.floor(minutes / 60) % 24
    local remainder = minutes % 60
    if days > 0 then return string.format('%dd %dh %dm', days, hours, remainder) end
    if hours > 0 then return string.format('%dh %dm', hours, remainder) end
    return string.format('%dm', remainder)
end

local function discover(instance: Instance)
    if instance:IsA('Model') and instance:GetAttribute('LeaderboardKey') then boards[instance] = true end
end

local function syncRoot(): Instance?
    local root = workspace:FindFirstChild('MergeABrainrotGenerated')
    if root ~= currentRoot then
        if addedConnection then addedConnection:Disconnect(); addedConnection = nil end
        table.clear(boards)
        currentRoot = root
        if root then
            for _, instance in root:GetDescendants() do discover(instance) end
            addedConnection = root.DescendantAdded:Connect(discover)
        end
    end
    return root
end

function Footer.update(state: any)
    local root = syncRoot()
    local player = Players.LocalPlayer
    if not root or not player then return end
    local total = 0
    for _, producer in state.producers or {} do
        local species = Catalog[producer.speciesId]
        if species then total += 2 ^ (species.tier - 1) end
    end
    local values = {
        coins = '$' .. compact((state.coinUnits or 0) / 4),
        count = compact(total),
        time = duration(state.timePlayed or 0),
    }
    for board in boards do
        if not board:IsDescendantOf(root) then boards[board] = nil; continue end
        local key = board:GetAttribute('LeaderboardKey')
        local footer = board:FindFirstChild('PersonalLeaderboardFooter', true)
        local rows = board:FindFirstChild('LeaderboardRows', true)
        if not footer or not footer:IsA('TextLabel') or not rows or type(key) ~= 'string' then continue end
        local rank: number? = nil
        for _, row in rows:GetChildren() do
            if row:IsA('Frame') and row.Visible and row:GetAttribute('UserId') == player.UserId then
                rank = row:GetAttribute('Rank') :: number
                break
            end
        end
        local color = board:GetAttribute('LeaderboardColor')
        if typeof(color) ~= 'Color3' then color = Color3.new(1, 1, 1) end
        local c = color :: Color3
        local hex = string.format('#%02X%02X%02X', math.floor(c.R * 255 + .5), math.floor(c.G * 255 + .5), math.floor(c.B * 255 + .5))
        local message = if rank then 'You are #' .. rank .. ' on the leaderboard!' else 'You are not on the leaderboard!'
        footer.RichText = true
        footer.Text = message .. ' <font color="' .. hex .. '">[' .. (values[key] or '0') .. ']</font>'
    end
end

return Footer
