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
        assert(not ui.contextPanel.Visible,'Automatic pads must not show a proximity panel')
        state.tokens=table.create(Config.GroundCap,{id='visual-only'})
        ui:update(state)
        assert(not ui.contextPanel.Visible,'Full tray must not restore the removed proximity panel')
        task.wait()
        state.tokens={};ui:update(state)
        for _,kind in {'Buy','Deposit','Claim','Upgrade','Merge','Lucky','FinishNow'} do
            ui:setContext(kind,'1');ui:setPending(true)
            assert(not ui.contextPanel.Visible,'Removed proximity panel reappeared for '..kind)
            ui:setPending(false)
        end
        ui:open('Index')
        task.wait()
        local note=ui.panel.IndexProduction
        local rate=ui.panel.IndexGrid.tier_01.MiniValue
        assert(rate.Text=='1 / sec','Card must show raw production; the event applies at deposit')
        assert(note.Text=='$1.25 per Mini · Each card shows Minis / second','Index must separate rebirth cash value from tier production')
        assert(note.TextBounds.Y<=note.AbsoluteSize.Y,'Production explanation must fit its allocated text area')
        state.eventHundredths=50;ui:update(state)
        assert(rate.Text=='1 / sec','Event must not multiply displayed production twice')
        state.obbyBonusHundredths=25;ui:update(state)
        assert(rate.Text=='1 / sec','Obby multiplier belongs to deposit, not raw production')
        ui:close()
        state.eventHundredths=127;state.obbyBonusHundredths=0
    end
    local catalog=require(Shared.CreatureCatalog)
    for tier=1,8 do ui:pickup(tier*10,string.format('tier_%02d',tier)) end
    assert(#ui.pickupPool==6,'Pickup visuals must remain bounded')
    for _,entry in ui.pickupPool do
        assert(not entry.root:FindFirstChild('Species'),'Pickup subtitle must be removed')
        assert(entry.amount.Text=='+'..entry.count,'Pickup must show only its numeric gain')
        assert(entry.amount.TextColor3==Color3.fromRGB(table.unpack(catalog[entry.speciesId].color)),'Pickup must use the producer name color')
    end
end)
ui.gui:Destroy()
assert(ok,err)
return 'PASS hidden proximity panels, colored number-only bounded pickups, small-screen Index and event/obby-only refresh'
