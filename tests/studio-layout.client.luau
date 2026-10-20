-- Run in Studio Client during Play. Temporary test UI is removed afterward.
local player=game.Players.LocalPlayer
local UI=require(player.PlayerScripts.Controllers.FarmUI)
local ui=UI.new(player.PlayerGui)
ui.gui.Name='LayoutRegression'
local state={coinUnits=0,rebirths=0,purchased=0,bag={{speciesId='tier_01',baseCoinValue=2,count=1000000}},saleQueue={},soldUnits=0,processorLevel=0,starterClaimed=true,cashMultiplier=1,miniMultiplier=1,autoCollect=false,autoSell=false,discoveries={tier_01=true},serverNow=0,tutorialStep=4,producers={{id='a',speciesId='tier_01',slot=1},{id='b',speciesId='tier_01',slot=2}}}
for _,size in {Vector2.new(640,280),Vector2.new(390,844)} do
    ui.root.Size=UDim2.fromOffset(size.X,size.Y)
    ui:update(state)
    ui:setContext('Buy','5')
    task.wait()
    assert(not ui.contextButton.Active,'Walk pads must not use clickable purchase controls')
    assert(not string.find(ui.contextButton.Text,'LOCKED'),'Buy 5 must be available before rebirth')
    assert(ui.bagText.Text=='1000000' and ui.bagText.TextScaled,'Large counts must remain readable')
    assert(not ui.bagValue.Visible,'The bag cash value must stay hidden')
    ui:setContext('Buy','100')
    assert(string.find(ui.contextButton.Text,'LOCKED'),'Buy 100 must require rebirth')
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
assert(notes==8,'Cash claim must scatter eight small cash bundles')
ui.gui:Destroy()
task.wait(2)
assert(burst.Parent==nil,'Cash bundles and sparks must clear after two seconds')
print('PASS short landscape/portrait UI, million-Mini count, walk-pad controls, buy unlock labels and cash burst cleanup')
