local audio=require(game.Players.LocalPlayer.PlayerScripts.Controllers.FeedbackAudio)
assert(not audio.play('InsufficientFunds'),'Rejected purchases must stay silent')
assert(audio.play('Rebirth'),'A first successful event must play')
assert(not audio.play('Rebirth'),'Immediate repeats must be throttled')
for _=1,50 do audio.play('Pickup');audio.play('Buy');audio.play('Claim') end
local count=0
for _,sound in game.SoundService:GetChildren() do
    if sound:IsA('Sound') and string.match(sound.Name,'^FarmFeedback%d$') then
        count+=1;assert(not sound.Looped and sound.Volume<=.25,'Feedback must be short and quiet')
        assert(sound.SoundId=='rbxassetid://135483737426662','Use the cleared project cue')
    end
end
assert(count==3,'Bursts must reuse exactly three voices')
print('PASS successful cue routing, rejection silence, cooldown and three-voice sound budget')
