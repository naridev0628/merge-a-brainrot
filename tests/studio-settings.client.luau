-- Run in Studio Client after Preferences and FarmUI have been synced.
-- Restores the session's prior volumes and removes its temporary HUD.
local controllers=game.Players.LocalPlayer.PlayerScripts.Controllers
local UI=require(controllers.FarmUI)
local Preferences=require(controllers.Preferences)
local prior=Preferences.snapshot()
local ui=UI.new(game.Players.LocalPlayer.PlayerGui)
ui.gui.Name='SettingsRegression'
local function inside(object,root)
    local p,s=object.AbsolutePosition,object.AbsoluteSize
    local rp,rs=root.AbsolutePosition,root.AbsoluteSize
    assert(p.X>=rp.X-1 and p.Y>=rp.Y-1 and p.X+s.X<=rp.X+rs.X+1 and p.Y+s.Y<=rp.Y+rs.Y+1,object.Name..' clips outside '..root.Name)
end
local function separate(a,b)
    local ap,as=a.AbsolutePosition,a.AbsoluteSize;local bp,bs=b.AbsolutePosition,b.AbsoluteSize
    assert(ap.X+as.X<=bp.X+.1 or bp.X+bs.X<=ap.X+.1 or ap.Y+as.Y<=bp.Y+.1 or bp.Y+bs.Y<=ap.Y+.1,a.Name..' overlaps '..b.Name)
end
local ok,err=pcall(function()
    for _,size in {Vector2.new(600,280),Vector2.new(640,280),Vector2.new(320,480),Vector2.new(390,440),Vector2.new(360,568),Vector2.new(390,600),Vector2.new(640,500),Vector2.new(1440,900)} do
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
    ui.state={coinUnits=0,rebirths=0,purchased=0,bag={},saleQueue={},soldUnits=0,processorLevel=0,starterClaimed=true,cashMultiplier=1,miniMultiplier=1,autoCollect=false,autoSell=false,discoveries={},serverNow=0,tutorialStep=7,producers={},lucky={id='settings-test',held=true,baseTier=1}}
    -- Closing Settings must restore a held Lucky card without dropping it.
    local dropped=false;ui.onDropLucky=function() dropped=true end
    ui:open('Settings');ui:close()
    assert(ui:isLuckyOpen() and not dropped,'Settings close must retain the held Lucky Block')
end)
ui.gui:Destroy()
for key,value in prior do Preferences.set(key,value) end
assert(ok,err)
print('PASS nonmodal Settings, compact HUD bounds, scroll access, current values, independent SoundGroups, reset, hook disconnect and held-Lucky restoration')
