-- Run in Studio Client during Play. Temporary test UI is removed afterward.
local player=game.Players.LocalPlayer
local UI=require(player.PlayerScripts.Controllers.FarmUI)
local ui=UI.new(player.PlayerGui)
ui.gui.Name='LayoutRegression'
local state={coinUnits=0,rebirths=0,purchased=0,bag={{speciesId='tier_01',baseCoinValue=2,count=1000000}},saleQueue={},soldUnits=0,processorLevel=0,starterClaimed=true,cashMultiplier=1,miniMultiplier=1,autoCollect=false,autoSell=false,discoveries={tier_01=true},serverNow=0,tutorialStep=4,producers={{id='a',speciesId='tier_01',slot=1},{id='b',speciesId='tier_01',slot=2}}}
state.tokens={}
local function inside(object,root)
    local p,s=object.AbsolutePosition,object.AbsoluteSize
    local rp,rs=root.AbsolutePosition,root.AbsoluteSize
    assert(p.X>=rp.X-1 and p.Y>=rp.Y-1 and p.X+s.X<=rp.X+rs.X+1 and p.Y+s.Y<=rp.Y+rs.Y+1,object.Name..' clips outside '..root.Name)
end
local function separate(a,b)
    local ap,as=a.AbsolutePosition,a.AbsoluteSize;local bp,bs=b.AbsolutePosition,b.AbsoluteSize
    assert(ap.X+as.X<=bp.X or bp.X+bs.X<=ap.X or ap.Y+as.Y<=bp.Y or bp.Y+bs.Y<=ap.Y,a.Name..' overlaps '..b.Name)
end
for _,size in {Vector2.new(640,280),Vector2.new(320,480),Vector2.new(390,440),Vector2.new(360,568),Vector2.new(390,600),Vector2.new(390,690),Vector2.new(390,700),Vector2.new(640,450),Vector2.new(390,844),Vector2.new(1440,900)} do
    ui.root.Size=UDim2.fromOffset(size.X,size.Y)
    ui:update(state)
    ui:setContext('Buy','5')
    task.wait()
    assert(not ui.contextButton.Active,'Walk pads must not use clickable purchase controls')
    assert(not string.find(ui.contextButton.Text,'LOCKED'),'Buy 5 must be available before rebirth')
    assert(ui.bagText.Text=='1000000' and ui.bagText.TextScaled,'Large counts must remain readable')
    assert(not ui.bagValue.Visible,'The bag cash value must stay hidden')
    ui:setContext('Buy','50')
    assert(string.find(ui.contextButton.Text,'LOCKED'),'Buy 50 must require rebirth')
    state.rebirths=2;state.coinUnits=136;state.purchased=3
    local originalProducers=state.producers
    state.producers={}
    for slot=1,48 do table.insert(state.producers,{id='p'..slot,speciesId='tier_01',slot=slot}) end
    ui:update(state);ui:setContext('Buy','50')
    assert(string.find(ui.contextButton.Text,'$34',1,true),'Buy 50 must quote two remaining tier-2 producers at the shared price')
    ui:setContext('Buy','5')
    assert(string.find(ui.contextButton.Text,'Not enough space',1,true),'Fixed batches must report insufficient room')
    for slot=49,50 do table.insert(state.producers,{id='p'..slot,speciesId='tier_01',slot=slot}) end
    ui:update(state);ui:setContext('Buy','50')
    assert(string.find(ui.contextButton.Text,'Not enough space',1,true),'A full plot must not advertise a zero-cost purchase')
    state.producers=originalProducers;state.rebirths=0;state.coinUnits=0;state.purchased=0;ui:update(state)
    state.lucky={id='layout',held=true,baseTier=1};ui:update(state);ui:open('Lucky');task.wait()
    assert(ui:isLuckyOpen() and not ui:isOpen() and not ui.overlay.Active,'Lucky must leave gameplay active')
    assert(ui.overlay.BackgroundTransparency==1,'Lucky must leave the world bright')
    inside(ui.panel,ui.root);inside(ui.bag,ui.root);inside(ui.homeButton,ui.root)
    separate(ui.panel,ui.bag);separate(ui.panel,ui.homeButton);separate(ui.panel,ui.contextPanel)
    local viewport=ui.panel.LuckyViewport
    local presentation=viewport.LuckyPresentation
    inside(viewport,ui.panel)
    assert(viewport.AbsoluteSize.Y>0,'Lucky viewport must fit positive free HUD space')
    for _,item in presentation:GetDescendants() do
        if item:IsA('TextLabel') and item.Visible and item.Text~='' and not item:FindFirstAncestorWhichIsA('ViewportFrame') then
            assert(item.TextSize>=14,'Lucky copy must keep a readable native size')
            inside(item,presentation)
        end
    end
    local rewards=presentation.GoldCard.Rewards
    for index=1,3 do
        local row=rewards['Reward'..index]
        local name=row:FindFirstChild('Name')
        assert(row.AbsoluteSize.Y>0 and name.AbsoluteSize.Y>0,'Lucky reward rows must have positive height')
        assert(name.TextBounds.Y>0 and name.AbsoluteSize.Y>=name.TextBounds.Y,'Lucky reward name must fit its actual rendered text')
        assert(name.AbsoluteSize.X>=name.TextBounds.X,'Lucky reward name must fit its actual rendered width')
        inside(name,row);separate(name,row.Probability)
        if row.Tier.Visible then separate(name,row.Tier) end
        if index<3 then separate(row,rewards['Reward'..(index+1)]) end
    end
    assert(rewards.Reward1.Probability.Text=='75%' and rewards.Reward2.Probability.Text=='20%' and rewards.Reward3.Probability.Text=='5%','Actual Lucky odds must remain visible')
    assert(presentation.CostStripe.Cost.Text=='Cost: $60','Lucky price must match two producers')
    if viewport.ScrollingEnabled then
        viewport.CanvasPosition=Vector2.new(0,viewport.AbsoluteCanvasSize.Y-viewport.AbsoluteSize.Y)
        task.wait()
        inside(presentation.Unlock,viewport);inside(presentation.Discard,viewport)
        viewport.CanvasPosition=Vector2.zero
        task.wait()
    else
        inside(presentation,viewport)
    end
    for i=1,50 do ui:pickup(1,'tier_01') end
    local gains=0;local sum=0
    for _,item in ui.bag:GetChildren() do
        if item.Name=='PickupGain' and item.Visible then gains+=1;sum+=item:GetAttribute('Count') or 0 end
    end
    assert(gains>0 and gains<=6 and sum==50,'Pickup bursts must aggregate without losing counts or exceeding six popups')
    task.wait(1.2)
    for _,item in ui.bag:GetChildren() do if item.Name=='PickupGain' then assert(not item.Visible,'Pooled pickup rows must expire') end end
    ui:close();state.lucky=nil;ui:update(state);ui:open('Rebirth');task.wait()
    inside(ui.panel,ui.root)
    local rewardArea=ui.panel.RebirthRewards
    assert(rewardArea.CashReward.CashBoost.Text=='x1.25 Cash','Rebirth must show the real next cash multiplier')
    assert(string.find(rewardArea.BulkReward.Unlock.Text,'Tier 1',1,true),'First rebirth must unlock Buy50 tier 1')
    ui:close()
    local mergeCalled=false
    ui.onMerge=function()mergeCalled=true end
    ui:toggleMerge()
    assert(mergeCalled and not ui:isOpen(),'Merge button must guide to pad without opening a chooser')
end
require(player.PlayerScripts.Controllers.CashEffects).play(ui.gui,player.Character,'534')
task.wait(.3)
local cash=ui.root.CashCollectionFeedback
assert(cash.TextScaled and cash.TextBounds.Y>=24,'Cash feedback must remain readable')
local burst=workspace:FindFirstChild('CashCollectionBurst')
assert(burst,'Cash claim must create its ground celebration')
local notes=0
for _,part in burst:GetChildren() do
    if part.Name=='CashNote' then notes+=1 end
    assert(not part.CanCollide and not part.CanTouch,'Cash effects must not block movement')
end
assert(notes>0 and notes<=8,'Cash claim must keep a bounded bundle burst')
ui.gui:Destroy()
task.wait(2)
assert(burst.Parent==nil,'Cash bundles and sparks must clear after two seconds')
print('PASS adaptive Lucky bounds/odds/cost, rebirth rewards, pooled pickup budget/expiry, million-Mini count, walk pads and cash cleanup')
