-- Run in Studio Client during Play. Temporary test UI is removed afterward.
local player=game.Players.LocalPlayer
local UI=require(player.PlayerScripts.Controllers.FarmUI)
local Config=require(game.ReplicatedStorage.Shared.Config)
local Economy=require(game.ReplicatedStorage.Shared.Economy)
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
    assert(ap.X+as.X<=bp.X or bp.X+bs.X<=ap.X or ap.Y+as.Y<=bp.Y or bp.Y+bs.Y<=ap.Y,
        a.Name..' overlaps '..b.Name..' at '..tostring(ui.root.AbsoluteSize)..' ('..ui.mode..')')
end
if game:GetService('UserInputService').TouchEnabled then
    -- Keep the real simulator viewport/control size. The desktop section below
    -- uses virtual root sizes, which cannot resize Roblox's native controls.
    local touchOK,touchError=xpcall(function()
        local touch=player.PlayerGui:FindFirstChild('TouchGui')
        local jump=touch and touch:FindFirstChild('JumpButton',true)
        local thumb=touch and touch:FindFirstChild('ThumbstickStart',true)
        assert(jump and thumb,'Wait for the native touch controls before this fixture')
        local function visible(item)
            while item and item~=ui.gui do
                if item:IsA('GuiObject') and not item.Visible then return false end
                item=item.Parent
            end
            return true
        end
        local function reveal(viewport,item)
            viewport.CanvasPosition=Vector2.new(0,math.clamp(
                item.AbsolutePosition.Y-viewport.AbsolutePosition.Y+viewport.CanvasPosition.Y,
                0,math.max(0,viewport.AbsoluteCanvasSize.Y-viewport.AbsoluteSize.Y)))
            task.wait();inside(item,viewport)
        end
        local drops=0;ui.onDropLucky=function() drops+=1 end
        for _,step in {1,7} do
            state.tutorialStep=step;state.lucky=nil;ui:close();ui:update(state);ui:setContext('Buy','1')
            for _,mode in {'Normal','Lucky','Settings'} do
                if mode~='Normal' then
                    state.lucky={id='touch-layout',held=true,baseTier=1};ui:update(state);ui:open(mode)
                end
                task.wait()
                for _,item in {ui.hud,ui.bag,ui.total,ui.homeButton,ui.actions,ui.contextPanel,
                    ui.cashPlus,ui.settingsButton,ui.boostButton,ui.autoButton,ui.panel} do
                    if visible(item) and (item~=ui.panel or mode~='Normal') then
                        inside(item,ui.root);separate(item,jump);separate(item,thumb)
                    end
                end
                assert(ui.total.Visible and ui.bag.Visible and ui.hud.Visible,'Touch must retain farm counts')
                assert(ui.bagText.Text=='1000000','Touch must retain the complete Mini count')
                assert(ui.cashPlus.AbsoluteSize.X>=40 and ui.cashPlus.AbsoluteSize.Y>=40,'Touch Shop target is too small')
                for _,label in {ui.stats,ui.rebirthCount,ui.multiplier,ui.total,ui.bagText} do
                    assert(label.TextBounds.X<=label.AbsoluteSize.X+1 and label.TextBounds.Y<=label.AbsoluteSize.Y+1,
                        label.Name..' text does not fit the touch layout')
                end
                if mode~='Normal' then
                    for _,item in {ui.homeButton,ui.hud,ui.bag,ui.total,ui.contextPanel} do separate(ui.panel,item) end
                    assert(not ui:isOpen() and not ui.overlay.Active,'Touch side panels must remain nonmodal')
                    if mode=='Lucky' then
                        separate(ui.panel,ui.settingsButton)
                        local viewport=ui.panel.LuckyViewport
                        local content=viewport.LuckyPresentation
                        for index=1,3 do reveal(viewport,content.GoldCard.Rewards['Reward'..index]) end
                        reveal(viewport,content.Unlock);reveal(viewport,content.Discard)
                    else
                        local viewport=ui.panel.SettingsViewport
                        for _,row in viewport.SettingsContent:GetChildren() do
                            if row:IsA('GuiObject') and row:FindFirstChild('Increase') then
                                reveal(viewport,row.Increase);reveal(viewport,row.Decrease)
                            end
                        end
                        ui:close()
                        assert(ui:isLuckyOpen() and state.lucky.id=='touch-layout' and state.lucky.held and drops==0,
                            'Settings must restore the same held block without dropping it')
                    end
                end
            end
        end
    end,debug.traceback)
    ui.gui:Destroy()
    if not touchOK then error(touchError) end
    return 'PASS native touch HUD: actual Jump/Thumbstick separation, counts/text fit, Shop target and reachable Lucky/Settings scroll actions'
end
local Tutorial=require(game.ReplicatedStorage.Shared.Tutorial)
local onboarding=table.clone(state)
onboarding.status='Ready';onboarding.bag={};onboarding.producers={};onboarding.starterClaimed=false
local homeOK,homeError=xpcall(function()
    for _,size in {Vector2.new(320,480),Vector2.new(390,440),Vector2.new(360,568),Vector2.new(390,844),
        Vector2.new(600,280),Vector2.new(640,280),Vector2.new(640,450),Vector2.new(640,500),Vector2.new(700,500),
        Vector2.new(780,500),Vector2.new(900,600),Vector2.new(1440,900)} do
        ui.root.Size=UDim2.fromOffset(size.X,size.Y)
        ui:unavailable('Waiting for a plot.');task.wait()
        assert(not ui.homeButton.Visible,'Home must wait for a Ready farm')
        for _,step in {1,2,4,6,7} do
            onboarding.tutorialStep=step;onboarding.starterClaimed=step>1
            onboarding.soldUnits=if step==4 then 8 else 0
            onboarding.producers=if step>=6 then state.producers elseif step>1 then {state.producers[1]} else {}
            ui:update(onboarding);ui:setContext('Buy','1');task.wait()
            assert(ui.homeButton.Visible,'Ready farms must have Home during onboarding')
            inside(ui.homeButton,ui.root);inside(ui.cashPlus,ui.root)
            assert(ui.cashPlus.Visible and ui.cashPlus.Active,'Short onboarding must retain the Shop button')
            local goal=Tutorial.goal(onboarding)
            assert(ui.objective.Text==goal.title and ui.hint.Text==goal.detail,'Onboarding guidance must remain unchanged')
            if step<7 then
                assert(ui.objective.Visible and ui.hint.Visible,'Onboarding objective and detail must remain visible')
                separate(ui.homeButton,ui.objective);separate(ui.homeButton,ui.hint);separate(ui.objective,ui.hint)
                for _,label in {ui.objective,ui.hint} do
                    inside(label,ui.root);separate(label,ui.actions);separate(label,ui.contextPanel)
                    assert(label.TextBounds.X<=label.AbsoluteSize.X+1 and label.TextBounds.Y<=label.AbsoluteSize.Y+1,
                        label.Name..' must fit its rendered onboarding text')
                end
                for _,control in {ui.homeButton,ui.actions,ui.contextPanel} do separate(ui.cashPlus,control) end
                if size.X<600 and size.Y<500 then
                    assert(not ui.boostButton.Visible and not ui.boostPrice.Visible and not ui.autoButton.Visible,
                        'Short phone onboarding must reserve the compact header and action row')
                    for _,control in {ui.mergeButton,ui.indexButton,ui.rebirthButton,ui.settingsButton} do inside(control,ui.root) end
                end
            else
                assert(ui.homeButton.Position.X.Scale==.5 and ui.homeButton.Position.Y.Offset==6,'Mature Home position must remain unchanged')
                assert(ui.boostButton.Visible and ui.boostPrice.Visible and ui.autoButton.Visible,'Promos must return after onboarding')
            end
            ui:open('Shop');task.wait()
            assert(ui.mode=='Shop' and ui:isOpen(),'The retained Shop entry must still open its panel')
            ui:close()
        end
        onboarding.tutorialStep=1
        for _,mode in {'Lucky','Settings'} do
            ui:update(onboarding);ui:open(mode);task.wait()
            assert(ui.homeButton.Visible and ui.homeButton.Position.X.Scale==.5,'Side panels retain centered Home during onboarding')
            inside(ui.panel,ui.root);separate(ui.panel,ui.homeButton);separate(ui.panel,ui.bag);separate(ui.panel,ui.contextPanel)
            assert(not ui.objective.Visible and not ui.hint.Visible,'Side-panel guidance visibility must remain unchanged')
            assert(ui.boostButton.Visible and ui.autoButton.Visible,'Side-panel promotional controls must be restored')
            ui:close()
        end
    end
end,debug.traceback)
if not homeOK then ui.gui:Destroy();error(homeError) end
for _,size in {Vector2.new(640,280),Vector2.new(320,480),Vector2.new(390,440),Vector2.new(360,568),Vector2.new(390,600),Vector2.new(390,690),Vector2.new(390,700),Vector2.new(640,450),Vector2.new(390,844),Vector2.new(1440,900)} do
    ui.root.Size=UDim2.fromOffset(size.X,size.Y)
    ui:update(state)
    ui:setContext('Buy','5')
    task.wait()
    assert(not ui.contextPanel.Visible and not ui.contextButton.Active,'Automatic walk pads must not show a proximity overlay')
    assert(ui.bagText.Text=='1000000' and ui.bagText.TextScaled,'Large counts must remain readable')
    assert(not ui.bagValue.Visible,'The bag cash value must stay hidden')
    ui:setContext('Buy','100')
    assert(not ui.contextPanel.Visible and not ui.contextButton.Active,'Locked Buy100 must not restore the removed overlay')
    assert(Economy.purchaseQuote(Config,state,'100').code=='Locked','Buy100 must retain its rebirth unlock')
    state.rebirths=2;state.coinUnits=136;state.purchased=3
    local originalProducers=state.producers
    state.producers={}
    for slot=1,48 do table.insert(state.producers,{id='p'..slot,speciesId='tier_01',slot=slot}) end
    ui:update(state);ui:setContext('Buy','100')
    local bulk=Economy.purchaseQuote(Config,state,'100')
    assert(bulk.amount==100 and bulk.tier==2 and bulk.cost==Economy.buyCost(state.purchased,100,2,Config.MergeCount)
        and bulk.mergePlan and #bulk.mergePlan<=Config.Slots,'Buy100 must quote all hundred and check capacity after automatic merging')
    assert(not ui.contextPanel.Visible,'Buy100 quotes must remain on world signage, not a proximity panel')
    ui:setContext('Buy','5')
    assert(Economy.purchaseQuote(Config,state,'5').code=='PlotFull','Fixed batches must still require room')
    for slot=49,50 do table.insert(state.producers,{id='p'..slot,speciesId='tier_01',slot=slot}) end
    ui:update(state);ui:setContext('Buy','100')
    local fullBulk=Economy.purchaseQuote(Config,state,'100')
    assert(fullBulk.cost>0 and fullBulk.amount==100 and fullBulk.mergePlan and #fullBulk.mergePlan<=Config.Slots,
        'A full plot of matching producers must retain a paid Buy100 auto-merge quote')
    assert(not ui.contextPanel.Visible and not ui.contextButton.Active,'Full plots must not restore the removed context panel')
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
    assert(string.find(rewardArea.BulkReward.Unlock.Text,'Tier 1',1,true),'First rebirth must unlock Buy100 tier 1')
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
print('PASS onboarding Home/guidance/Shop layout, adaptive Lucky bounds/odds/cost, rebirth rewards, pooled pickup budget/expiry, million-Mini count, walk pads and cash cleanup')
