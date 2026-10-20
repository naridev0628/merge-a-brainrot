-- Client-only private UI fixture; no remotes, gameplay changes, or camera moves.
local controllers=game.Players.LocalPlayer.PlayerScripts.Controllers
local UI=require(controllers.FarmUI)
local Cue=require(controllers.MultiplierCue)
local ui=UI.new(game.Players.LocalPlayer.PlayerGui)
ui.gui.Name='MultiplierCueFixture'
local controller=Cue.new(ui)
local state={status='Ready',sessionKey='cue-fixture',revision=1,eventHundredths=100,serverNow=1,
    coinUnits=0,rebirths=0,purchased=0,bag={},saleQueue={},soldUnits=0,processorLevel=0,
    starterClaimed=true,cashMultiplier=1,miniMultiplier=1,autoCollect=false,autoSell=false,
    discoveries={tier_01=true},tutorialStep=7,tokens={},producers={{id='a',speciesId='tier_01',slot=1}}}
local now=100
local function receive(value)
    state.revision+=1;state.serverNow+=1;state.eventHundredths=value
    now+=.01;controller:receive(state,now)
end
local function visible(object)
    local parent=object
    while parent and parent~=ui.root do
        if parent:IsA('GuiObject') and not parent.Visible then return false end
        parent=parent.Parent
    end
    return parent==ui.root
end
local function separate(a,b)
    local ap,as,bp,bs=a.AbsolutePosition,a.AbsoluteSize,b.AbsolutePosition,b.AbsoluteSize
    return ap.X+as.X<=bp.X or bp.X+bs.X<=ap.X or ap.Y+as.Y<=bp.Y or bp.Y+bs.Y<=ap.Y
end
local function verify()
    local label=controller.label
    assert(not label.Active and not label.Selectable and label.BackgroundTransparency==1,'The cue must not intercept gameplay input')
    assert(label.Font==Enum.Font.FredokaOne and label:FindFirstChild('TextOutline'),'Use the outlined reference lettering')
    local count=0
    for _,child in ui.root:GetChildren() do if child.Name=='MiniMultiplierChange' then count+=1 end end
    assert(count==1,'Rapid updates must reuse one label')
    if not label.Visible then return false end -- Fully occupied short layouts may hide the cue.
    local p,s,rp,rs=label.AbsolutePosition,label.AbsoluteSize,ui.root.AbsolutePosition,ui.root.AbsoluteSize
    assert(p.X>=rp.X and p.Y>=rp.Y and p.X+s.X<=rp.X+rs.X and p.Y+s.Y<=rp.Y+rs.Y,'Cue clips outside the safe area')
    assert(label.TextBounds.X<=s.X+1 and label.TextBounds.Y<=s.Y+1,'Multiplier text does not fit')
    assert(separate(label,ui.bag),'Cue overlaps basket')
    for _,name in {'panel','contextPanel','actions','hud','total','homeButton','boostButton','boostPrice','autoButton','title','objective','hint','toast'} do
        local object=ui[name]
        if visible(object) then assert(separate(label,object),'Cue overlaps '..name) end
    end
    for _,child in ui.bag:GetChildren() do
        if child.Name=='PickupGain' and child.Visible then assert(separate(label,child),'Cue overlaps pickup feedback') end
    end
    return true
end
local ok,err=xpcall(function()
    ui:update(state)
    controller:receive(state,now)
    assert(not controller.label.Visible,'Initial event baseline must be quiet')
    local shown=0
    for _,size in {Vector2.new(320,480),Vector2.new(390,440),Vector2.new(360,568),
        Vector2.new(390,844),Vector2.new(640,280),Vector2.new(640,450),Vector2.new(1440,900)} do
        ui.root.Size=UDim2.fromOffset(size.X,size.Y)
        ui:setContext('Buy','1');ui:update(state);task.wait()
        receive(110);controller:update(now);task.wait()
        assert(controller.label.TextColor3==Color3.fromRGB(115,255,36),'Rise should be green')
        if verify() then shown+=1 end
        local label=controller.label
        receive(75);task.wait();verify()
        assert(controller.label==label and string.find(label.Text,'0.75x',1,true),'Replacement must use the actual event value')
        assert(label.TextColor3==Color3.fromRGB(255,151,132),'Fall should be salmon')
        for tier=1,6 do ui:pickup(1,string.format('tier_%02d',tier)) end
        task.wait();controller:update(now);task.wait();verify()
        state.lucky={id='cue-lucky',held=true,baseTier=1}
        ui:update(state);ui:open('Lucky');task.wait();controller:update(now);task.wait();verify()
        assert(not ui:isOpen() and not ui.overlay.Active,'Cue must not make Lucky modal')
        ui:close();state.lucky=nil;ui:update(state)
        ui:open('Settings');task.wait();controller:update(now);task.wait();verify()
        assert(not ui:isOpen() and not ui.overlay.Active,'Cue must not make Settings modal')
        ui:close();task.wait();controller:update(now)
        controller:update(now+3)
        assert(not label.Visible,'The transient must expire without a new snapshot')
    end
    assert(shown>0,'The cue should be visible in usable layouts')
    receive(110)
    local original=controller
    controller=Cue.new(ui)
    assert(original.destroyed and next(original.connections)==nil,'Replacing a controller must release the previous lifetime')
    controller:receive(state,now);assert(not controller.label.Visible,'Recreated HUD must establish a quiet baseline')
    receive(75)
    ui.gui:Destroy()
    assert(controller.destroyed and next(controller.connections)==nil and next(controller.pickups)==nil,'GUI destruction must release every subscription')
    controller:destroy();controller:update(now+100);controller:receive(state,now+100)
end,debug.traceback)
controller:destroy()
if ui.gui.Parent then ui.gui:Destroy() end
assert(ok,err)
return 'PASS one bounded multiplier cue, actual values/colors, replay/expiry, phone/short layouts, pickup/Lucky/Settings separation and GUI teardown'
