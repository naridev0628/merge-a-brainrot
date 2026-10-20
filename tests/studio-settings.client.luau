-- Run in Studio Client after Preferences and FarmUI have been synced.
-- Checks native hit geometry; panel transitions are invoked directly rather than
-- synthesizing input. Restores prior volumes and removes its temporary HUD.
local controllers=game.Players.LocalPlayer.PlayerScripts.Controllers
local UI=require(controllers.FarmUI)
local Preferences=require(controllers.Preferences)
local prior=Preferences.snapshot()
local playerGui=game.Players.LocalPlayer.PlayerGui
local ui=UI.new(playerGui)
ui.gui.Name='SettingsRegression';ui.gui.DisplayOrder=1000
local sizes={Vector2.new(600,280),Vector2.new(640,280),Vector2.new(320,480),Vector2.new(320,568),Vector2.new(390,440),Vector2.new(360,568),Vector2.new(390,600),Vector2.new(640,450),Vector2.new(640,500),Vector2.new(700,500),Vector2.new(780,500),Vector2.new(800,500),Vector2.new(800,573),Vector2.new(900,600),Vector2.new(1440,900)}
local function inside(object,root)
    local p,s=object.AbsolutePosition,object.AbsoluteSize
    local rp,rs=root.AbsolutePosition,root.AbsoluteSize
    assert(p.X>=rp.X-1 and p.Y>=rp.Y-1 and p.X+s.X<=rp.X+rs.X+1 and p.Y+s.Y<=rp.Y+rs.Y+1,object.Name..' clips outside '..root.Name)
end
local function separate(a,b)
    local ap,as=a.AbsolutePosition,a.AbsoluteSize;local bp,bs=b.AbsolutePosition,b.AbsoluteSize
    assert(ap.X+as.X<=bp.X+.1 or bp.X+bs.X<=ap.X+.1 or ap.Y+as.Y<=bp.Y+.1 or bp.Y+bs.Y<=ap.Y+.1,a.Name..' overlaps '..b.Name)
end
local function reachable(button)
    local ancestor=button
    while ancestor and ancestor~=playerGui do
        if ancestor:IsA('GuiObject') then assert(ancestor.Visible,'Hidden Settings ancestor: '..ancestor.Name) end
        ancestor=ancestor.Parent
    end
    assert(ancestor==playerGui and button.Active,'Settings must remain attached and active')
    local center=button.AbsolutePosition+button.AbsoluteSize/2
    local found=false
    for _,hit in playerGui:GetGuiObjectsAtPosition(center.X,center.Y) do
        if hit==button then found=true end
        if hit:IsDescendantOf(ui.gui) and hit~=button and not hit:IsDescendantOf(button) then
            assert(not hit.Active,'Settings is covered by an active HUD control: '..hit.Name)
        end
    end
    assert(found,'Settings must appear in its rendered center hit test')
end
local ok,err=pcall(function()
    for _,size in sizes do
        ui.root.Size=UDim2.fromOffset(size.X,size.Y)
        ui:open('Settings')
        task.wait()
        assert(ui:isSettingsOpen() and not ui:isOpen() and not ui.overlay.Active,'Settings must leave gameplay active')
        assert(ui.overlay.BackgroundTransparency==1,'Settings must leave the world bright')
        inside(ui.panel,ui.root);inside(ui.closeButton,ui.panel)
        separate(ui.panel,ui.bag);separate(ui.panel,ui.homeButton);separate(ui.panel,ui.contextPanel)
        local viewport=ui.panel.SettingsViewport
        local content=viewport.SettingsContent
        inside(viewport,ui.panel)
        assert(viewport.AbsoluteSize.Y>0,'Settings needs a positive scrolling viewport')
        for _,row in {content.sfxVolume,content.musicVolume} do
            inside(row.Label,row);inside(row.Decrease,row);inside(row.Amount,row);inside(row.Increase,row)
            separate(row.Label,row.Decrease);separate(row.Decrease,row.Amount);separate(row.Amount,row.Increase)
            assert(row.Label.TextBounds.Y<=row.Label.AbsoluteSize.Y,'Settings label must fit its row')
        end
        assert(content.SessionNotice.Text=='Session only. Resets on rejoin.','Do not claim persistent settings')
        if viewport.ScrollingEnabled then
            viewport.CanvasPosition=Vector2.new(0,viewport.AbsoluteCanvasSize.Y-viewport.AbsoluteSize.Y)
            task.wait()
            inside(content.SessionNotice,viewport)
        else
            inside(content,viewport)
        end
        Preferences.set('sfxVolume',0);Preferences.set('musicVolume',.6)
        assert(content.sfxVolume.Amount.Text=='0%' and content.musicVolume.Amount.Text=='60%','Settings must show actual preference values')
        assert(Preferences.getSoundGroup('sfx').Volume==0 and math.abs(Preferences.getSoundGroup('music').Volume-.6)<.001,'Volumes must apply immediately to independent sound groups')
        Preferences.reset()
        assert(content.sfxVolume.Amount.Text=='100%' and content.musicVolume.Amount.Text=='35%','Reset must update the displayed values')
        ui:close();task.wait()
        assert(not ui:isSettingsOpen() and not ui:isOpen(),'Closing Settings must restore gameplay HUD')
        inside(ui.settingsButton,ui.root)
        separate(ui.settingsButton,ui.contextPanel)
    end
    local callbacks=0
    local disconnect=Preferences.subscribe('sfxVolume',function() callbacks+=1 end)
    Preferences.set('sfxVolume',.2)
    disconnect()
    Preferences.set('sfxVolume',.3)
    assert(callbacks==2,'Preference hooks must support initial application and disconnect')
    ui.state={coinUnits=1000,rebirths=0,purchased=0,bag={},saleQueue={},soldUnits=0,processorLevel=0,starterClaimed=true,cashMultiplier=1,miniMultiplier=1,autoCollect=false,autoSell=false,discoveries={},serverNow=0,tutorialStep=7,producers={},lucky={id='settings-test',held=true,baseTier=1}}
    local held=ui.state.lucky
    local dropped=false;ui.onDropLucky=function() dropped=true end
    for _,size in sizes do
        ui.root.Size=UDim2.fromOffset(size.X,size.Y);ui:open('Lucky');task.wait()
        reachable(ui.settingsButton);inside(ui.settingsButton,ui.root)
        assert(ui.settingsButton.AbsoluteSize.X>=40 and ui.settingsButton.AbsoluteSize.Y>=40,'Settings needs a usable touch target')
        assert(ui.settingsButton.AbsolutePosition.X>=ui.homeButton.AbsolutePosition.X+ui.homeButton.AbsoluteSize.X+11.9,'Held Settings must stay right of Home')
        if size.X==800 then assert(ui.panel.AbsoluteSize.Y==math.min(452,size.Y-120),'Gear clearance must retain the full Lucky card height') end
        for _,other in {ui.homeButton,ui.panel,ui.bag,ui.contextPanel,ui.boostButton,ui.boostPrice,ui.autoButton,ui.cashPlus} do separate(ui.settingsButton,other) end
        separate(ui.panel,ui.homeButton);separate(ui.panel,ui.bag);separate(ui.panel,ui.contextPanel)
        local viewport=ui.panel.LuckyViewport
        local content=viewport.LuckyPresentation
        local rewards=content.GoldCard.Rewards
        assert(rewards.Reward1.Probability.Text=='75%' and rewards.Reward2.Probability.Text=='20%' and rewards.Reward3.Probability.Text=='5%','Settings access must retain the real Lucky odds')
        for _,item in {rewards.Reward1,rewards.Reward2,rewards.Reward3,content.Unlock,content.Discard} do
            local top=item.AbsolutePosition.Y-viewport.AbsolutePosition.Y+viewport.CanvasPosition.Y
            viewport.CanvasPosition=Vector2.new(0,math.clamp(top,0,math.max(0,viewport.AbsoluteCanvasSize.Y-viewport.AbsoluteSize.Y)))
            task.wait();inside(item,viewport)
        end
        assert(content.Unlock.Active and content.Discard.Active,'An affordable held block must retain both actions')
        viewport.CanvasPosition=Vector2.zero;task.wait()
        ui:setPending(true);reachable(ui.settingsButton);ui:setPending(false)
        ui:open('Settings')
        assert(not ui:isOpen() and not ui.overlay.Active,'Held Settings must leave gameplay active')
        Preferences.set('musicVolume',.4)
        ui:close();task.wait()
        assert(ui:isLuckyOpen() and ui.state.lucky==held and held.held and not dropped,'Settings close must retain the same held Lucky Block')
        reachable(ui.settingsButton)
        ui:open('Shop');task.wait()
        assert(ui.settingsButton.Parent==ui.actions and ui.settingsButton.Text=='Settings','Other modes must restore the original rail')
        ui:close()
    end
    ui:unavailable('Waiting for a plot.');task.wait()
    assert(ui.settingsButton.Parent==ui.actions and ui.settingsButton.Text=='Settings','Unavailable must restore the rail')
    -- Destroy while the reused gear is parented directly under SafeArea.
    ui:open('Lucky')
    assert(ui.settingsButton.Parent==ui.root)
end)
ui.gui:Destroy()
for key,value in prior do Preferences.set(key,value) end
assert(ok,err)
assert(ui.settingsButton.Parent==nil,'HUD destruction must also destroy the reparented Settings button')
print('PASS nonmodal Settings, compact HUD bounds, scroll access, current values, SoundGroups/reset/hooks, held-Lucky reachability/retention, rail restoration and destruction')
