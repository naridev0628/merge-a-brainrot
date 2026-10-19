--!strict
local Players=game:GetService("Players")
local ReplicatedStorage=game:GetService("ReplicatedStorage")
local RunService=game:GetService("RunService")
local HttpService=game:GetService("HttpService")
local Shared=ReplicatedStorage:WaitForChild("Shared")
local Config=require(Shared.Config)
local Map=require(Shared.MapSpec)
local Core=require(script.Parent.Domain.FarmCore)
local Limiter=require(script.Parent.Domain.RateLimiter)
local World=require(script.Parent.Services.WorldBuilder)
local net=Instance.new("Folder"); net.Name="FarmNetwork"
local command=Instance.new("RemoteEvent"); command.Name="Command"; command.Parent=net
local snapshot=Instance.new("RemoteEvent"); snapshot.Name="StateSnapshot"; snapshot.Parent=net
local result=Instance.new("RemoteEvent"); result.Name="CommandResult"; result.Parent=net
net.Parent=ReplicatedStorage
-- This checkpoint must never silently run an unsaved economy in a published server.
if not RunService:IsStudio() then
    command.OnServerEvent:Connect(function(player)
        snapshot:FireClient(player,{status="Unavailable",reason="This prototype requires Roblox Studio. Saving is not implemented."})
    end)
    warn("[MergeABrainrot] Studio-only memory mode; live progression disabled.")
    return
end
local core=Core.new(Config,require(Shared.CreatureCatalog))
local world=World.build()
local sessions: {[Player]: any}={}
local buckets: {[Player]: any}={}
local owner: Player?=nil
local characterConnections: {[Player]: RBXScriptConnection}={}
local rates={Collect={12,24},State={1,2},Sell={3,6},Buy={3,6},Merge={3,6},Home={1/3,1}}
local function send(player: Player)
    local session=sessions[player]
    if session then
        local state=core:snapshot(session)
        state.status=session.phase; state.memoryOnly=true
        snapshot:FireClient(player,state)
    else snapshot:FireClient(player,{status="Unavailable",reason="All plots are occupied. This checkpoint has one plot."}) end
end
local function render()
    if owner and sessions[owner] then
        local ok,err=pcall(World.render,world,sessions[owner].state)
        if not ok then warn("[MergeABrainrot] Visual update failed: "..tostring(err)) end
    end
end
local function context(player: Player)
    local character=player.Character
    local humanoid=character and character:FindFirstChildOfClass("Humanoid")
    local root=character and character:FindFirstChild("HumanoidRootPart") :: BasePart?
    local pos=root and root.Position
    return {now=os.clock(),alive=humanoid~=nil and humanoid.Health>0 and root~=nil,
        position=pos and {x=pos.X,y=pos.Y,z=pos.Z}}
end
local function moveHome(player: Player, character: Model)
    local root=character:WaitForChild("HumanoidRootPart",10)
    if root and player.Parent==Players and sessions[player] and player.Character==character then character:PivotTo(Map.Spawn) end
end
local function attach(player: Player)
    if sessions[player] or owner then return end
    owner=player
    sessions[player]=core:newSession(player.UserId,os.clock(),HttpService:GenerateGUID(false))
    world.ownerLabel.Text=player.DisplayName.."'s FARM\nMINI MEADOW"
    characterConnections[player]=player.CharacterAdded:Connect(function(c) moveHome(player,c) end)
    if player.Character then task.spawn(moveHome,player,player.Character) end
    render(); send(player)
    print("[MergeABrainrot] Ready: one starter; Studio memory mode.")
end
command.OnServerEvent:Connect(function(player: Player, action: any, args: any, ...: any)
    local now=os.clock()
    local b=buckets[player]
    if not b then b={}; buckets[player]=b end
    if not Limiter.allow(b,"All",now,20,36) then return end
    if select("#",...)~=0 or type(action)~="string" or #action>16 or not rates[action] then return end
    local rate=rates[action]
    if not Limiter.allow(b,action,now,rate[1],rate[2]) then return end
    if action=="State" then if type(args)=="table" and next(args)==nil then send(player) end; return end
    local session=sessions[player]
    if not session then send(player); return end
    if action=="Home" then
        if type(args)~="table" or next(args)~=nil then return end
        if context(player).alive and player.Character then player.Character:PivotTo(Map.Spawn) end
        return
    end
    local response=core:dispatch(session,action,args,context(player))
    -- Never echo malformed large inputs back to a client.
    local requestId=type(args)=="table" and type(args[1])=="string" and #args[1]<=128 and args[1] or nil
    response.requestId=requestId; response.action=action
    result:FireClient(player,response)
    if response.code=="OK" and not response.replayed then render() end
    send(player)
end)
Players.PlayerAdded:Connect(attach)
Players.PlayerRemoving:Connect(function(player)
    local session=sessions[player]
    if session then session.phase="Closing"; sessions[player]=nil end
    buckets[player]=nil
    if characterConnections[player] then characterConnections[player]:Disconnect(); characterConnections[player]=nil end
    if owner==player then
        owner=nil; World.clear(world)
        for _,waiting in Players:GetPlayers() do if waiting~=player then attach(waiting); break end end
    end
end)
for _,player in Players:GetPlayers() do attach(player) end
task.spawn(function()
    while true do
        task.wait(Config.Cadence)
        if owner then
            local session=sessions[owner]
            if session and core:step(session,os.clock()) then render(); send(owner) end
        end
    end
end)
game:BindToClose(function()
    for _,session in sessions do session.phase="Closing" end
end)
