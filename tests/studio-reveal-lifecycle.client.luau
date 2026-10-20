-- Isolated Studio Client regression. No real player progress or network calls.
-- The normal Lucky reveal completes within the 3s load budget + ~2s animation.
local player=game.Players.LocalPlayer
local controllers=player.PlayerScripts.Controllers
local Lucky=require(controllers.LuckyEffects)
local Discovery=require(controllers.DiscoveryEffects)
local Runtime=require(controllers.VisualRuntime)
local Art=require(controllers.BrickArt)
local Catalog=require(game.ReplicatedStorage.Shared.CreatureCatalog)
local fixtures={}
local function gui()
    local item=Instance.new('ScreenGui');item.Name='RevealLifecycleQA';item.Parent=player.PlayerGui
    table.insert(fixtures,item)
    return item
end
local function waitUntil(test,seconds)
    local deadline=os.clock()+seconds
    while not test() and os.clock()<deadline do task.wait(.05) end
    assert(test(),'Reveal lifecycle exceeded its deadline')
end
local ok,err=pcall(function()
    local removed=gui()
    local finished=0
    Lucky.play(removed,function() finished+=1 end)
    assert(removed:FindFirstChild('LuckyOpening'))
    removed:Destroy()
    waitUntil(function() return finished==1 end,.5)
    task.wait(.1)
    assert(finished==1,'UI destruction must release exactly one Lucky completion')
    Lucky.play(removed,function() finished+=1 end)
    assert(finished==2,'An already destroyed UI must release completion promptly')

    local loading=gui()
    local cancelled,shown,completed=0,0,0
    local late=nil
    local scope=Runtime.new(loading,function() completed+=1 end)
    scope:load(function(done)
        late=done
        return function() cancelled+=1 end
    end,3,function() shown+=1 end)
    loading:Destroy()
    waitUntil(function() return completed==1 end,.5)
    late(true)
    assert(cancelled==1 and shown==0 and next(scope.resources)==nil,'Cancelled loads must release handles and ignore late callbacks')

    local portraitGui=gui()
    local portrait=Art.luckyPortrait(portraitGui,UDim2.new(),UDim2.fromOffset(100,100),true)
    task.wait(.1)
    assert(not portrait.Visible,'Delegated Lucky portraits must not start their own reveal/preload path')
    portraitGui:Destroy()

    local discoveries=gui()
    local show=Discovery.new(discoveries)
    for _=1,100 do show('tier_01') end
    show('tier_02')
    local first=assert(discoveries:FindFirstChild('NewDiscovery'))
    local count=0
    for _,item in discoveries:GetChildren() do if item.Name=='NewDiscovery' then count+=1 end end
    assert(count==1,'Discovery bursts must retain one active card')
    first:Destroy()
    waitUntil(function()
        local nextCard=discoveries:FindFirstChild('NewDiscovery')
        return nextCard and nextCard.CreatureName.Text==Catalog.tier_02.name
    end,.5)
    discoveries:Destroy()
    show('tier_03')
    assert(#discoveries:GetChildren()==0,'Destroyed discovery UI must not restart its queue')

    local normal=gui()
    local revealed=0
    Lucky.play(normal,function() revealed+=1 end)
    waitUntil(function() return revealed>0 end,6.5)
    assert(revealed==1 and not normal:FindFirstChild('LuckyOpening'),'Normal or timeout fallback must finish once and remove the opening')
    task.wait(.1)
    assert(revealed==1,'A late preload must not repeat a completed reveal')
end)
for _,item in fixtures do item:Destroy() end
assert(ok,err)
return 'PASS reveal destruction, late completion, delegated portrait, coalesced discovery backlog, cancellation cleanup and bounded Lucky completion'
