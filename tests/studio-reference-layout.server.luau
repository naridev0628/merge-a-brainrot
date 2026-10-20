-- Disposable visual comparison, not a gameplay or performance benchmark.
-- Execute on Server during normal single-player Play. In later Server calls:
-- _G.ReferenceLayoutPreview.setCount(24), setCount(50), setCount(96), destroy().
-- Uses fixed IDs for paired before/after poses and actual imported Mini meshes.
assert(game:GetService("RunService"):IsStudio(), "Studio only")
assert(not _G.ReferenceLayoutPreview, "Destroy the earlier preview first")
local Shared=game.ReplicatedStorage.Shared
local Config=require(Shared.Config)
local Catalog=require(Shared.CreatureCatalog)
local Core=require(game.ServerScriptService.Domain.FarmCore)
local World=require(game.ServerScriptService.Services.WorldBuilder)
local player=assert(game.Players:GetPlayers()[1], "Start normal Play first")
local generated=assert(workspace:FindFirstChild("MergeABrainrotGenerated"))
local clone=assert(generated:FindFirstChild("Plot1")):Clone()
clone.Name="ReferenceLayoutPreview"
clone.Producers:ClearAllChildren()
clone.Minis:ClearAllChildren()
clone.StackRows:ClearAllChildren()
for _,item in clone:GetDescendants() do
    if item:IsA("SpawnLocation") or item:IsA("LuaSourceContainer") then item:Destroy() end
end
local lucky=clone:FindFirstChild("LuckyBlock")
if lucky then lucky:Destroy() end
clone:PivotTo(CFrame.new(0,2000,0))
local world={
    root=clone,frame=clone:GetPivot(),producers=clone.Producers,tokens=clone.Minis,
    rows=clone.StackRows,badgePart=clone.OwnerBadgeAnchor,pads={},
    saleLabel={},processorLabel={},processorRate={},
    upgradeLabel=clone.UpgradePad.Label.Text,upgradePrice=clone.UpgradePad.Label.Price,
}
local config=table.clone(Config)
config.GroundCap=96
config.LuckyChance=0
local core=Core.new(config,Catalog,function() return 1 end)
local active=true
local api={}
function api.setCount(count,mode)
    assert(active and (count==24 or count==50 or count==96), "Use 24, 50 or 96")
    mode=mode or "tier_06"
    assert(mode=="mixed" or mode=="tier_06", "Unknown preview species")
    world.producers:ClearAllChildren()
    world.tokens:ClearAllChildren()
    local session=core:newSession(player.UserId,0,"reference-layout-v1")
    local state=core:snapshot(session)
    state.starterClaimed=true
    for slot=1,50 do
        local species=if mode=="mixed" then string.format("tier_%02d",(slot-1)%6+1) else mode
        state.producers[slot]={id=core:id(session),speciesId=species,slot=slot,due=1}
        state.discoveries[species]=true
    end
    assert(core:commit(session,state))
    core:step(session,1);core:step(session,2)
    state=core:snapshot(session)
    while #state.tokens>count do table.remove(state.tokens) end
    for _,token in state.tokens do
        token.spawnedAt=os.clock()-10
        token.readyAt=os.clock()-6
    end
    for _,producer in state.producers do producer.due=os.clock()+10000 end
    assert(core:commit(session,state))
    World.render(world,session.state)
    assert(#world.tokens:GetChildren()==count)
    return {count=count,mode=mode,producers=#state.producers,frame=world.frame}
end
function api.destroy()
    if not active then return end
    active=false
    clone:Destroy()
    if _G.ReferenceLayoutPreview==api then _G.ReferenceLayoutPreview=nil end
end
local ok,result=xpcall(function()
    local initial=api.setCount(96)
    clone.Parent=workspace
    return initial
end,debug.traceback)
if not ok then api.destroy();error(result) end
_G.ReferenceLayoutPreview=api
task.delay(180,api.destroy)
return result
