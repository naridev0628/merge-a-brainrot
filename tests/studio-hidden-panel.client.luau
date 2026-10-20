-- Isolated actual FarmUI regression; no normal session, camera, input or preferences change.
-- Run before/after the guard to count hidden card/portrait construction, not native FPS.
local Players=game:GetService('Players')
local RunService=game:GetService('RunService')
local HttpService=game:GetService('HttpService')
assert(RunService:IsStudio() and RunService:IsClient(),'Client Studio fixture only')
local UI=require(Players.LocalPlayer.PlayerScripts.Controllers.FarmUI)
local ui=UI.new(Players.LocalPlayer.PlayerGui)
ui.gui.Name='HiddenPanelRegression';ui.gui.Enabled=false
local metrics={hidden={instances=0,portraits=0,cards=0},visible={instances=0,portraits=0,cards=0}}
local phase='hidden'
local seen=setmetatable({},{__mode='k'})
local connection=ui.gui.DescendantAdded:Connect(function(item)
    if seen[item] then return end
    seen[item]=true
    local count=metrics[phase]
    count.instances+=1
    if item:IsA('ViewportFrame') and item.Name=='CharacterPortrait' then count.portraits+=1 end
    if item:IsA('TextButton') and item.Name:match('^Producer_') then count.cards+=1 end
end)
local state={coinUnits=10000,rebirths=0,purchased=0,bag={},tokens={},saleQueue={},soldUnits=0,
    processorLevel=0,starterClaimed=true,cashMultiplier=1,miniMultiplier=1,
    autoCollect=false,autoSell=false,discoveries={tier_01=true},serverNow=100,tutorialStep=7,
    eventHundredths=100,obbyBonusHundredths=0,producers={}}
for slot=1,50 do state.producers[slot]={id='hidden-'..slot,speciesId='tier_01',slot=slot} end
local function cards()
    local count=0
    for _,item in ui.list:GetChildren() do
        if item:IsA('TextButton') and item.Name:match('^Producer_') then count+=1 end
    end
    return count
end
local function quiet()
    -- Drain deferred engine signals without waiting on asset downloads.
    RunService.Heartbeat:Wait()
end
local ok,err=xpcall(function()
    ui:update(state)
    ui:setPending(true);ui:setPending(false)
    ui:setShopInfo({cash2={price=123,forSale=true}})
    local latest=table.clone(state);latest.coinUnits=20000;latest.producers=table.clone(state.producers)
    latest.producers[50]=nil
    latest.producers[49]={id='newest-49',speciesId='tier_02',slot=49}
    ui:update(latest);quiet()
    assert(not ui.overlay.Visible and ui.state==latest,'Hidden updates must retain current state')
    assert(ui.stats.Text=='$5000','Closed panel must not suppress the gameplay HUD')
    assert(metrics.hidden.cards==0 and metrics.hidden.portraits==0,
        ('Closed panel built %d cards / %d portraits / %d descendants'):format(metrics.hidden.cards,metrics.hidden.portraits,metrics.hidden.instances))
    assert(cards()==0,'Never-opened Merge list must stay empty')

    phase='visible'
    ui:open('Merge');quiet()
    assert(ui:isOpen() and ui.overlay.Active and cards()==49,'Opening Merge must build the latest producer list')
    assert(ui.list.Producer_49.Caption.Text:find('Level 2',1,true),'Opening must use the latest producer species')
    ui:setPending(true);assert(ui.confirm.Text=='Waiting for server...','Visible pending state must refresh')
    ui:setPending(false);assert(ui.confirm.Text=='Confirm merge','Visible pending completion must refresh')
    latest=table.clone(latest);latest.producers={latest.producers[1],latest.producers[2]}
    ui:update(latest);assert(cards()==2,'Visible producer removals must refresh')

    ui:close();quiet();phase='hidden'
    local hiddenBefore=metrics.hidden.cards+metrics.hidden.portraits
    latest=table.clone(latest);latest.producers={latest.producers[1]};latest.coinUnits=22000
    ui:update(latest);ui:setPending(true);ui:clearSelection();ui:setPending(false)
    ui:setShopInfo({cash2={price=321,forSale=true}});quiet()
    assert(metrics.hidden.cards+metrics.hidden.portraits==hiddenBefore,'Closed previously-built panels must not rebuild')
    phase='visible'
    ui:open('Merge');assert(cards()==1,'Reopening must discard removed producer cards')

    -- Existing panels remain live; the guard must use overlay visibility, not isOpen().
    ui:open('Shop')
    assert(ui.list:FindFirstChild('cash2') and #ui.list:GetChildren()>=6,'Visible Shop must build its offers')
    ui:setShopInfo({cash2={price=654,forSale=true}})
    assert(ui.shopInfo.cash2.price==654 and ui.list:FindFirstChild('cash2'),'Visible Shop metadata must refresh')
    ui:open('Rebirth')
    assert(ui.panel.RebirthRewards.CashReward.CashBoost.Text=='x1.25 Cash','Rebirth presentation must remain live')
    latest=table.clone(latest);latest.rebirths=1;ui:update(latest)
    assert(ui.panel.RebirthRewards.CashReward.CashBoost.Text=='x1.5 Cash','Visible Rebirth updates must remain live')
    ui:open('Index')
    latest=table.clone(latest);latest.eventHundredths=50;ui:update(latest)
    assert(ui.panel.IndexGrid.tier_01.MiniValue.Text=='0.5 / sec','Visible Index cards must react to production changes')

    latest=table.clone(latest);latest.lucky={id='hidden-fixture-lucky',held=true,baseTier=1}
    ui:update(latest);ui:open('Lucky')
    assert(ui:isLuckyOpen() and not ui:isOpen() and not ui.overlay.Active,'Lucky must remain live and nonmodal')
    local lucky=ui.panel.LuckyViewport.LuckyPresentation
    assert(lucky.CostStripe.Cost.Text=='Cost: $50','Lucky must use the current one-producer price')
    latest=table.clone(latest);latest.producers={state.producers[1],state.producers[2]}
    ui:update(latest)
    assert(lucky.CostStripe.Cost.Text=='Cost: $60','Visible Lucky must react to producer changes')
    ui:open('Settings');ui:setPending(true);ui:setPending(false)
    assert(ui:isSettingsOpen() and not ui:isOpen() and not ui.overlay.Active,'Settings must remain live and nonmodal')
    ui:close()
    assert(ui:isLuckyOpen(),'Closing Settings must restore a held Lucky card')
    quiet()
end,debug.traceback)
connection:Disconnect()
ui.gui:Destroy()
table.clear(seen)
print('HiddenPanelRegression '..HttpService:JSONEncode(metrics))
assert(ok,err)
return {result='PASS hidden state/pending/shop deferral, fresh reopening, visible panels and nonmodal Lucky/Settings',counts=metrics}
