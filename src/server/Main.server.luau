--!strict
local Players=game:GetService('Players')
local ReplicatedStorage=game:GetService('ReplicatedStorage')
local RunService=game:GetService('RunService')
local HttpService=game:GetService('HttpService')
local Shared=ReplicatedStorage:WaitForChild('Shared')
local Config=require(Shared.Config)
local Catalog=require(Shared.CreatureCatalog)
local Map=require(Shared.MapSpec)
local MiniEvent=require(Shared.MiniEvent)
local MultiplierDisplay=require(script.Parent.Services.MultiplierDisplay)
local Core=require(script.Parent.Domain.FarmCore)
local ObbyRun=require(script.Parent.Domain.ObbyRun)
local ObbyService=require(script.Parent.Services.ObbyService)
local ObbyConfig=require(Shared.ObbyConfig)
local Limiter=require(script.Parent.Domain.RateLimiter)
local World=require(script.Parent.Services.WorldBuilder)
local LuckyCarry=require(script.Parent.Services.LuckyCarry)
local Passes=require(script.Parent.Services.PassService)
local net=Instance.new('Folder'); net.Name='FarmNetwork'
local command=Instance.new('RemoteEvent'); command.Name='Command'; command.Parent=net
local snapshot=Instance.new('RemoteEvent'); snapshot.Name='StateSnapshot'; snapshot.Parent=net
local result=Instance.new('RemoteEvent'); result.Name='CommandResult'; result.Parent=net
net.Parent=ReplicatedStorage
if not RunService:IsStudio() then
    command.OnServerEvent:Connect(function(player) snapshot:FireClient(player,{status='Unavailable',reason='This preview requires Studio. Saving is not implemented.'}) end)
    warn('[MergeABrainrot] Studio-only memory mode; live progression disabled.'); return
end
local core=Core.new(Config,Catalog)
local obby=ObbyService.new(core,ObbyRun,ObbyConfig)
local hub=World.build()
local eventDisplay=MultiplierDisplay.new(hub.root)
local eventValue=MiniEvent.Initial
local eventNextAt=os.clock()+MiniEvent.IntervalSeconds
local sessions: {[Player]: any}={}
local worlds: {[Player]: any}={}
local owners: {[number]: Player}={}
local buckets: {[Player]: any}={}
local connections: {[Player]: RBXScriptConnection}={}
local rates={CollectNearby={4,6},AutoMerge={2,3},Collect={12,24},State={1,2},Deposit={3,6},Claim={3,6},Buy={4,6},Merge={3,6},Rebirth={1,2},Upgrade={4,6},OpenLucky={2,3},PickupLucky={2,3},DropLucky={2,3},DiscardLucky={2,3},Home={1/3,1},Sprint={4,8}}
local function send(player: Player)
    local session=sessions[player]
    if not session then snapshot:FireClient(player,{status='Unavailable',reason='All six plots are occupied. Waiting for a free plot.'}); return end
    local state: any=core:snapshot(session); state.status=session.phase; state.memoryOnly=true; state.serverNow=os.clock()
    state.plotId=worlds[player].id; state.plotCFrame=worlds[player].frame; state.sessionKey=session.key
    state.timePlayed=math.floor(os.clock()-(session.joinedAt or os.clock()))
    state.obby=obby:snapshot(player)
    snapshot:FireClient(player,state)
end
local function render(player: Player)
    if not sessions[player] then return end
    local ok,err=pcall(World.render,worlds[player],sessions[player].state)
    if not ok then warn('[MergeABrainrot] Visual update failed: '..tostring(err)) end
    LuckyCarry.update(player.Character,sessions[player].state.lucky)
end
local refreshPasses=Passes.start(function(player,owned)
    if sessions[player] then core:setPasses(sessions[player],owned); render(player); send(player) end
end)
local function context(player: Player)
    local character=player.Character
    local humanoid=character and character:FindFirstChildOfClass('Humanoid')
    local root=character and character:FindFirstChild('HumanoidRootPart') :: BasePart?
    local world=worlds[player]
    local foot=if root and humanoid then root.Position-Vector3.new(0,humanoid.HipHeight+root.Size.Y/2+(if humanoid.RigType==Enum.HumanoidRigType.R6 then 2 else 0),0) else nil
    local pos=if foot and world then world.frame:PointToObjectSpace(foot)/Map.PlotScale else nil
    local pickupPos=if root and world then world.frame:PointToObjectSpace(root.Position)/Map.PlotScale else nil
    return {now=os.clock(),alive=humanoid~=nil and humanoid.Health>0 and root~=nil,position=pos and {x=pos.X,y=pos.Y,z=pos.Z},
        pickupPosition=pickupPos and {x=pickupPos.X,y=pickupPos.Y,z=pickupPos.Z},
        worldPosition=foot and {x=foot.X,y=foot.Y,z=foot.Z}}
end
local function moveHome(player: Player,character: Model)
    local root=character:WaitForChild('HumanoidRootPart',10)
    if root and player.Parent==Players and sessions[player] and player.Character==character then
        local changed=obby:reset(player,'Home',os.clock())
        character:PivotTo(worlds[player].frame*CFrame.new(Map.Spawn.Position*Map.PlotScale+Vector3.new(0,2,0))*Map.Spawn.Rotation)
        if changed then send(player) end
    end
end
local function attach(player: Player)
    if sessions[player] then return end
    local chosen=nil
    for _,world in hub.plots do if not owners[world.id] then chosen=world; break end end
    if not chosen then send(player); return end
    owners[chosen.id]=player; worlds[player]=chosen
    player.RespawnLocation=chosen.spawn
    sessions[player]=core:newSession(player.UserId,os.clock(),HttpService:GenerateGUID(false))
    obby:attach(player,sessions[player])
    core:setEvent(sessions[player],eventValue)
    sessions[player].joinedAt=os.clock()
    World.setOwner(chosen,player); refreshPasses(player)
    connections[player]=player.CharacterAdded:Connect(function(c)
        local changed=obby:reset(player,'Respawn',os.clock())
        if changed then send(player) end
        local session=sessions[player]
        if session and session.state.lucky and session.state.lucky.held then
            local state=core:snapshot(session);state.lucky.held=false;core:commit(session,state);render(player);send(player)
        end
        moveHome(player,c)
    end)
    if player.Character then task.spawn(moveHome,player,player.Character) end
    render(player); send(player)
    print('[MergeABrainrot] Ready on plot '..chosen.id..': $5 starter purchase and timed sales.')
end
command.OnServerEvent:Connect(function(player: Player,action: any,args: any,...: any)
    local now=os.clock(); local b=buckets[player]
    if not b then b={}; buckets[player]=b end
    if not Limiter.allow(b,'All',now,20,36) then return end
    if select('#',...)~=0 or type(action)~='string' or #action>16 or not rates[action] then return end
    local rate=rates[action]; if not Limiter.allow(b,action,now,rate[1],rate[2]) then return end
    if action=='State' then if type(args)=='table' and next(args)==nil then send(player) end; return end
    local session=sessions[player]; if not session then send(player); return end
    if action=='Sprint' then
        if type(args)=='table' and #args==1 and type(args[1])=='boolean' then
            local humanoid=player.Character and player.Character:FindFirstChildOfClass('Humanoid')
            if humanoid and humanoid.Health>0 then humanoid.WalkSpeed=if args[1] then 24 else 16 end
        end
        return
    end
    if action=='Home' then
        if type(args)=='table' and next(args)==nil and context(player).alive and player.Character then moveHome(player,player.Character) end
        return
    end
    local response=core:dispatch(session,action,args,context(player))
    response.requestId=type(args)=='table' and type(args[1])=='string' and #args[1]<=128 and args[1] or nil
    response.action=action; result:FireClient(player,response)
    if response.code=='OK' and not response.replayed then render(player) end
    send(player)
end)
Players.PlayerAdded:Connect(attach)
Players.PlayerRemoving:Connect(function(player)
    local session=sessions[player]; if session then session.phase='Closing'; sessions[player]=nil end
    obby:detach(player)
    buckets[player]=nil
    if connections[player] then connections[player]:Disconnect(); connections[player]=nil end
    local world=worlds[player]
    if world then owners[world.id]=nil; worlds[player]=nil; World.clear(world) end
    for _,waiting in Players:GetPlayers() do if waiting~=player and not sessions[waiting] then attach(waiting) end end
end)
for _,player in Players:GetPlayers() do attach(player) end
task.spawn(function()
    while true do
        task.wait(.1)
        for player in sessions do
            local sample=context(player)
            local changed,bonusChanged=obby:update(player,{now=sample.now,alive=sample.alive,position=sample.worldPosition})
            if changed then
                if bonusChanged then render(player) end
                send(player)
            end
        end
    end
end)
task.spawn(function()
    local nextBoards=0
    while true do
        task.wait(Config.Cadence)
        local now=os.clock()
        if now>=eventNextAt then
            eventValue=MiniEvent.next(eventValue,math.random);eventNextAt=now+MiniEvent.IntervalSeconds
            for player,session in sessions do core:setEvent(session,eventValue);send(player) end
        end
        eventDisplay:update(eventValue,eventNextAt,now)
        for player,session in sessions do
            if session.state.lucky and session.state.lucky.held and not context(player).alive then
                local dropped=core:snapshot(session);dropped.lucky.held=false;core:commit(session,dropped);render(player);send(player)
            end
            local sample=context(player)
            local changed,farmChanged=obby:step(player,{now=sample.now,alive=sample.alive,position=sample.worldPosition})
            if farmChanged then render(player) end
            if changed then send(player) end
        end
        if os.clock()>=nextBoards then
            nextBoards=os.clock()+3; local entries={}
            for player,session in sessions do
                local total=0;for _,p in session.state.producers do total+=2^(Catalog[p.speciesId].tier-1) end
                table.insert(entries,{userId=player.UserId,name=player.Name,coins=session.state.coinUnits/4,count=total,time=math.floor(os.clock()-session.joinedAt)})
                send(player)
            end
            World.updateBoards(hub,entries)
        end
    end
end)
game:BindToClose(function() for _,session in sessions do session.phase='Closing' end end)
