local Shared=game.ReplicatedStorage.Shared
local Config=require(Shared.Config)
local UI=require(game.Players.LocalPlayer.PlayerScripts.Controllers.FarmUI)
local ui=UI.new(game.Players.LocalPlayer.PlayerGui)
ui.gui.Name='CapacityHintsQA'
local state={coinUnits=100000,rebirths=1,purchased=1,bag={},tokens={},saleQueue={},soldUnits=0,processorLevel=0,
    starterClaimed=true,cashMultiplier=1,miniMultiplier=1,autoCollect=false,autoSell=false,
    discoveries={tier_01=true},serverNow=100,tutorialStep=7,eventHundredths=127,
    producers={{id='producer1',speciesId='tier_01',slot=1}}}
local ok,err=pcall(function()
    for _,size in {Vector2.new(320,480),Vector2.new(640,280),Vector2.new(1440,900)} do
        ui.root.Size=UDim2.fromOffset(size.X,size.Y)
        ui:update(state);ui:setContext('Buy','1')
        assert(ui.contextText.Text==(Config.Slots-1)..' spaces left')
        state.tokens=table.create(Config.GroundCap,{id='visual-only'})
        ui:update(state)
        assert(ui.contextText.Text=='Tray full • Collect Minis','Full tray must explain why drops stop')
        task.wait()
        assert(ui.contextText.TextBounds.Y<=ui.contextText.AbsoluteSize.Y,'Capacity hint must fit on a small display')
        state.tokens={};ui:update(state)
        assert(ui.contextText.Text==(Config.Slots-1)..' spaces left','The tray hint must clear after collection')
        ui:open('Index')
        task.wait()
        local note=ui.panel.IndexProduction
        assert(string.find(note.Text,'1.27 Minis/s',1,true),'Index must include the active world event')
        assert(note.TextBounds.Y<=note.AbsoluteSize.Y,'Production explanation must fit its allocated text area')
        state.eventHundredths=50;ui:update(state)
        assert(string.find(note.Text,'0.5 Minis/s',1,true),'Event-only snapshots must refresh the Index')
        state.obbyBonusHundredths=25;ui:update(state)
        assert(string.find(note.Text,'0.75 Minis/s',1,true),'Obby-only snapshots must refresh the Index')
        ui:close()
        state.eventHundredths=127;state.obbyBonusHundredths=0
    end
end)
ui.gui:Destroy()
assert(ok,err)
return 'PASS live capacity hints, collection recovery, small-screen fit and event/obby-only Index refresh'
