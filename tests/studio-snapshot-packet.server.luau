-- Run in disposable Studio Play, then run the paired client fixture.
-- Uses an isolated Core session and RemoteEvent, never the player's economy.
assert(game:GetService('RunService'):IsStudio())
local Shared=game.ReplicatedStorage.Shared
local Config=require(Shared.Config)
local Catalog=require(Shared.CreatureCatalog)
local Core=require(game.ServerScriptService.Domain.FarmCore)
local Packet=require(game.ServerScriptService.Domain.SnapshotPacket)
assert(not game.ReplicatedStorage:FindFirstChild('SnapshotPacketProbe'),'Remove the previous probe first')
local core=Core.new(Config,Catalog,function() return 1 end)
local session=core:newSession(991,100,'isolated-wire-probe')
local seeded=core:snapshot(session)
seeded.starterClaimed=true
for slot=1,Config.Slots do
    local species=string.format('tier_%02d',(slot-1)%6+1)
    seeded.producers[slot]={id=core:id(session),speciesId=species,slot=slot,due=101}
    seeded.discoveries[species]=true
end
assert(core:commit(session,seeded),'The isolated producer seed must be valid')
core:step(session,101);core:step(session,102)
assert(#session.state.producers==50 and #session.state.tokens==96)
local folder=Instance.new('Folder');folder.Name='SnapshotPacketProbe'
local remote=Instance.new('RemoteEvent');remote.Name='Packet';remote.Parent=folder
folder:SetAttribute('Status','Armed');folder.Parent=game.ReplicatedStorage
local world={id=1,frame=workspace.MergeABrainrotGenerated.Plot1:GetPivot()}
local obby={phase='Available',checkpoint=0,bonusHundredths=0}
local firstX=session.state.tokens[1].x
local connection
connection=remote.OnServerEvent:Connect(function(player,phase)
    local ok,err=pcall(function()
        if phase=='ready' then
            local packet=Packet.build(session,world,102,obby)
            remote:FireClient(player,'first',packet,core:snapshot(session))
        elseif phase=='mutated' then
            assert(session.state.tokens[1].x==firstX,'Client packet mutation reached authority')
            assert(session.state.status==nil and session.state.serverNow==nil,'Packet metadata leaked into authority')
            local previous=Packet.build(session,world,102,obby)
            core:setEvent(session,125)
            assert(previous.eventHundredths~=125,'A later commit mutated the old packet')
            remote:FireClient(player,'second',Packet.build(session,world,103,obby))
        elseif phase=='passed' then
            folder:SetAttribute('Status','PASS 50/96 packet values, CFrame, client isolation, later commit and metadata')
            connection:Disconnect()
        else
            error('Unexpected probe phase')
        end
    end)
    if not ok then folder:SetAttribute('Status','FAIL '..tostring(err));connection:Disconnect() end
end)
return 'Snapshot packet probe armed; run paired client fixture'
