-- Run in the Studio Client command bar during Play. This creates and removes a separate test HUD.
local UI=require(game.Players.LocalPlayer.PlayerScripts.Controllers.FarmUI)
local ui=UI.new(game.Players.LocalPlayer.PlayerGui)
ui.gui.Name="LayoutRegression"
ui.root.Size=UDim2.fromOffset(640,280)
task.wait()
ui:update({coinUnits=0,rebirths=0,bag={},saleQueue={},soldUnits=0,processorLevel=0,starterClaimed=true,cashMultiplier=1,miniMultiplier=1,autoCollect=false,autoSell=false,discoveries={tier_01=true},serverNow=0,tutorialStep=4,producers={
    {id="a",speciesId="tier_01",slot=1},
    {id="b",speciesId="tier_01",slot=2},
}})
ui:toggleMerge()
ui:notice("Respawn before merging again.")
task.wait()
local feedbackVisible=ui.toast.Visible and ui.toast.ZIndex>ui.overlay.ZIndex
local listHeight=ui.list.AbsoluteSize.Y
local cardHeight=ui.list.Producer_1.AbsoluteSize.Y
require(game.Players.LocalPlayer.PlayerScripts.Controllers.CashEffects).play(ui.gui,game.Players.LocalPlayer.Character,"534")
task.wait(.3)
local cash=ui.root.CashCollectionFeedback
assert(cash.TextScaled,"Collection feedback must retain automatic text sizing")
assert(cash.TextBounds.Y>=24,"Collection feedback is too small to read")
ui.gui:Destroy()
assert(feedbackVisible,"Merge feedback is hidden behind the modal")
assert(listHeight>=48,"Short screen cannot show a full touch target")
assert(cardHeight>=48,"Producer cards must be at least 48 pixels tall")
print("PASS modal feedback and short-screen touch targets")
