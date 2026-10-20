-- Isolated client UI; no input automation or progression changes.
local player=game.Players.LocalPlayer
local Controllers=player.PlayerScripts.Controllers
local UI=require(Controllers.FarmUI)
local Lucky=require(Controllers.LuckyEffects)
local Appearance=require(game.ReplicatedStorage.Shared.LuckyAppearance)
local ui=UI.new(player.PlayerGui);ui.gui.Name='LuckyAppearanceQA'
local reveal=Instance.new('ScreenGui');reveal.Name='LuckyAppearanceRevealQA';reveal.Parent=player.PlayerGui
local state={coinUnits=10000,rebirths=0,purchased=0,bag={},tokens={},saleQueue={},soldUnits=0,processorLevel=0,
    starterClaimed=true,cashMultiplier=1,miniMultiplier=1,autoCollect=false,autoSell=false,discoveries={tier_01=true},
    serverNow=0,tutorialStep=4,producers={{id='a',speciesId='tier_01',slot=1},{id='b',speciesId='tier_01',slot=2}}}
local ok,err=xpcall(function()
    local portrait
    for _,size in {Vector2.new(390,440),Vector2.new(1440,900)} do
        ui.root.Size=UDim2.fromOffset(size.X,size.Y)
        for _,tier in {2,3,6,2} do
            state.lucky={id='private-'..tier,held=true,baseTier=tier}
            ui:update(state);ui:open('Lucky');task.wait()
            local content=ui.panel.LuckyViewport.LuckyPresentation
            local card=content.GoldCard
            local palette=Appearance.forTier(tier)
            assert(card:GetAttribute('LuckyAppearance')==palette.key and card.Title.Text==palette.title,'Card must follow authoritative baseTier')
            assert(card.Title.TextBounds.X<=card.Title.AbsoluteSize.X+1 and card.Title.TextBounds.Y<=card.Title.AbsoluteSize.Y+1,'Basic/Upgraded title must fit the compact header')
            assert(card.Rewards.BackgroundColor3==Color3.fromRGB(table.unpack(palette.rewards)))
            assert(content.CostStripe.Cost.Text=='Cost: $60','Changing appearance must preserve the existing two-producer price')
            assert(ui:isLuckyOpen() and not ui:isOpen() and not ui.overlay.Active and ui.overlay.BackgroundTransparency==1,'The Lucky card must remain nonmodal')
            local current=card.LuckyBlockPortrait
            if portrait then assert(current==portrait,'Palette updates must reuse the existing portrait') end
            portrait=current
            local block=current.WorldModel.LuckyBlock.PrimaryPart
            assert(block:GetAttribute('LuckyAppearance')==palette.key,'Portrait must match the card')
            if tier>=3 then assert(block.TextureID=='' and #block.LuckyQuestionMarks:GetChildren()==36,'Upgraded portraits need 28 glyph runs and eight white corner accents') end
            if tier==6 then
                assert(card.Rewards.Reward1.Probability.Text=='100%' and not card.Rewards.Reward2.Visible,'Clamped top-tier odds must remain aggregated')
            else
                assert(card.Rewards.Reward1.Probability.Text=='75%' and card.Rewards.Reward2.Probability.Text=='20%' and card.Rewards.Reward3.Probability.Text=='5%','Appearance must preserve actual reward odds')
            end
            local stud=card.BrickTexture:FindFirstChild('Stud')
            assert(stud and stud.BackgroundColor3==Color3.fromRGB(table.unpack(palette.body)):Lerp(Color3.new(1,1,1),.14),'Existing card studs must recolor with the card')
        end
    end
    local finished=0
    Lucky.play(reveal,function() finished+=1 end,3)
    local opening=assert(reveal:FindFirstChild('LuckyOpening'))
    assert(opening.LuckyBlockPortrait.WorldModel.LuckyBlock.PrimaryPart:GetAttribute('LuckyAppearance')=='upgraded','Reveal must retain the opened block tier after the server removes it')
    reveal:Destroy()
    task.wait(.1)
    assert(finished==1,'Decorated reveal cancellation must complete exactly once')
end,debug.traceback)
ui.gui:Destroy();reveal:Destroy()
assert(ok,err)
return 'PASS Basic/Upgraded compact card and retained portrait, native title fit, cost/odds/nonmodal preservation, recolored studs and blue reveal cancellation'
