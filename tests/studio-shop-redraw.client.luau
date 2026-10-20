-- Actual isolated FarmUI regression; no normal UI, preferences, input or economy changes.
-- Run unchanged before/after the signature optimization. Counts exclude deferred startup.
local Players=game:GetService('Players')
local RunService=game:GetService('RunService')
local HttpService=game:GetService('HttpService')
assert(RunService:IsStudio() and RunService:IsClient(),'Client Studio fixture only')
local UI=require(Players.LocalPlayer.PlayerScripts.Controllers.FarmUI)
local ui=UI.new(Players.LocalPlayer.PlayerGui)
ui.gui.Name='ShopRedrawRegression';ui.gui.Enabled=false
local keys={'cash2','cash4','cash8','autoCollect','autoSell','mini2'}
local metrics={irrelevantUpdates=0,offerCreations=0,addedDescendants=0,identitiesRetained=0}
local connection
local function quiet()
    -- Art.brick coalesces AbsoluteSize layout through task.defer.
    for _=1,3 do RunService.Heartbeat:Wait() end
end
local function offers()
    local result={}
    for _,key in keys do result[key]=assert(ui.list:FindFirstChild(key),'Missing offer '..key) end
    return result
end
local function changed(previous,message)
    local current=offers()
    for _,key in keys do
        assert(current[key]~=previous[key] and previous[key].Parent==nil,message..': '..key)
    end
    return current
end
local state={coinUnits=10000,rebirths=0,purchased=0,bag={},tokens={},saleQueue={},soldUnits=0,
    processorLevel=0,starterClaimed=true,cashMultiplier=1,miniMultiplier=1,
    autoCollect=false,autoSell=false,discoveries={tier_01=true},serverNow=100,tutorialStep=7,
    eventHundredths=100,obbyBonusHundredths=0,
    producers={{id='shop-1',speciesId='tier_01',slot=1},{id='shop-2',speciesId='tier_01',slot=2}}}
local ok,err=xpcall(function()
    ui:update(state);ui:setShopInfo({cash2={price=123,forSale=true}});ui:open('Shop')
    quiet()
    local original=offers()
    metrics.startingDescendants=#ui.list:GetDescendants()
    connection=ui.list.DescendantAdded:Connect(function(item)
        metrics.addedDescendants+=1
        if item:IsA('TextButton') and table.find(keys,item.Name) then metrics.offerCreations+=1 end
    end)
    local patches={
        {coinUnits=20000},
        {eventHundredths=150},
        {obbyBonusHundredths=25},
        {producers={{id='shop-1',speciesId='tier_01',slot=1},{id='shop-new',speciesId='tier_02',slot=2}}},
        {lucky={id='shop-lucky',held=false,baseTier=2}},
        {rebirths=1},
    }
    for _,patch in patches do
        state=table.clone(state)
        for key,value in patch do state[key]=value end
        ui:update(state);metrics.irrelevantUpdates+=1
    end
    quiet()
    connection:Disconnect();connection=nil
    metrics.endingDescendants=#ui.list:GetDescendants()
    for _,key in keys do if ui.list:FindFirstChild(key)==original[key] then metrics.identitiesRetained+=1 end end
    assert(ui.stats.Text=='$5000' and ui.state==state,'Unrelated gameplay HUD/state must still update')
    assert(metrics.identitiesRetained==6 and metrics.offerCreations==0 and metrics.addedDescendants==0,
        ('Unrelated snapshots rebuilt %d offers / %d descendants; retained %d of 6 identities'):format(
            metrics.offerCreations,metrics.addedDescendants,metrics.identitiesRetained))
    assert(metrics.endingDescendants==metrics.startingDescendants,'Unrelated snapshots must preserve Shop descendants')

    local current=original
    for _,change in {
        {field='cashMultiplier',value=2,offer='cash2'},
        {field='miniMultiplier',value=2,offer='mini2'},
        {field='autoCollect',value=true,offer='autoCollect'},
        {field='autoSell',value=true,offer='autoSell'},
    } do
        state=table.clone(state);state[change.field]=change.value;ui:update(state)
        current=changed(current,'Ownership must refresh offers')
        assert(current[change.offer].BrickCaption.Text:find('OWNED',1,true),'Owned pass must update its caption')
    end
    ui:setShopInfo({cash4={price=234,forSale=true},cash8={price=456,forSale=true}})
    current=changed(current,'Fresh shop metadata must invalidate offers')
    ui:setPending(true);current=changed(current,'Pending start must refresh')
    assert(ui.confirm.Text=='Waiting for server...','Visible pending status must update')
    ui:setPending(false);current=changed(current,'Pending completion must refresh')
    assert(ui.confirm.Text=='Close','Shop pending completion must restore Close')
    ui.upgradeKey='cash4';ui:open('Upgrade');current=changed(current,'Mode transition must refresh')
    assert(ui.confirm.Text=='Upgrade - 234 Robux','Upgrade must use selected metadata')
    ui.upgradeKey='cash8';ui:update(state);current=changed(current,'Upgrade key change must refresh')
    assert(ui.confirm.Text=='Upgrade - 456 Robux','Upgrade must refresh its selected offer')
    ui:open('Shop');current=changed(current,'Returning to Shop must refresh')
    assert(ui.heading.Text=='Permanent boosts' and ui.confirm.Text=='Close','Mode transition must restore Shop presentation')
    quiet()
end,debug.traceback)
if connection then connection:Disconnect() end
ui.gui:Destroy()
print('ShopRedrawRegression '..HttpService:JSONEncode(metrics))
assert(ok,err)
return {result='PASS Shop identity/zero construction for irrelevant snapshots; ownership, metadata, pending, mode and upgrade-key refresh',counts=metrics}
