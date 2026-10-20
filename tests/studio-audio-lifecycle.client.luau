-- Run on a quiet client after audio modules are synced. Restores active controllers.
local Controllers=game.Players.LocalPlayer.PlayerScripts.Controllers
local Audio=require(Controllers.FeedbackAudio)
local Music=require(Controllers.MusicController)
local Config=require(Controllers.AudioConfig)
local Preloader=require(Controllers.AudioPreloader)
local Preferences=require(Controllers.Preferences)
local service=game:GetService('SoundService')
local function countFeedback()
    local count=0
    for _,child in service:GetChildren() do
        if child:IsA('Sound') and child.Name:match('^FarmFeedback%d$') then count+=1 end
    end
    return count
end
local function waitReady(id)
    local deadline=os.clock()+14
    while Preloader.status(id)=='loading' and os.clock()<deadline do task.wait(.05) end
    assert(Preloader.status(id)=='ready','Selected audio did not load: '..id)
end
Audio.start();Audio.start()
assert(countFeedback()==3,'Repeated startup must preserve exactly three effect voices')
for _,id in Config.Assets do waitReady(id) end
assert(not Audio.play('InsufficientFunds'),'Rejected actions must stay silent')
for _,kind in {'Pickup','Buy','Deposit','Merge','OpenLucky'} do
    task.wait(.25)
    assert(Audio.play(kind),'First action should be accepted: '..kind)
    assert(not Audio.play(kind),'An immediate repeat must be throttled: '..kind)
    local expected=Config.Assets[Config.Patterns[kind].asset]
    local found=false
    for _,child in service:GetChildren() do
        if child:IsA('Sound') and child.Name:match('^FarmFeedback%d$') then
            if child.SoundId==expected and child.IsPlaying then found=true end
            assert(child.SoundGroup==Preferences.getSoundGroup('sfx'))
            assert(not child.Looped and child.Volume<=.25)
        end
    end
    assert(found,'Action did not select its distinct sound: '..kind)
end
for _=1,100 do Audio.play('Pickup');Audio.play('Buy');Audio.play('Claim') end
assert(countFeedback()==3,'Action bursts must never allocate more voices')

Music.start()
local soundtrack=assert(service:FindFirstChild('FarmSoundtrack'))
for _=1,20 do Music.start() end
waitReady(Config.Music.Id)
task.wait(Config.Music.FadeSeconds+.1)
assert(service:FindFirstChild('FarmSoundtrack')==soundtrack,'Repeated music startup must reuse its voice')
assert(soundtrack.Looped and soundtrack.IsPlaying and soundtrack.TimePosition>0,'Music must load and advance')
assert(soundtrack.SoundGroup==Preferences.getSoundGroup('music'),'Music must respect the independent music preference')
assert(math.abs(soundtrack.Volume-Config.Music.Volume)<.001,'Music must fade to its quiet configured level')
Music.stop()
assert(not soundtrack.IsPlaying and soundtrack.Volume==0,'Stop must immediately silence music')
Music.start()
assert(service:FindFirstChild('FarmSoundtrack')==soundtrack,'Stop/start must reuse one music voice')
Music.destroy()
assert(not service:FindFirstChild('FarmSoundtrack'),'Destroy must remove the soundtrack voice')

task.wait(1.6)
assert(Audio.play('Rebirth'))
Audio.destroy()
assert(countFeedback()==0,'Destroy must release all effect voices')
Audio.start()
task.wait(.3)
for _,child in service:GetChildren() do
    if child:IsA('Sound') and child.Name:match('^FarmFeedback%d$') then
        assert(not child.IsPlaying and child.Volume==0,'Delayed notes from a destroyed controller must not reach new voices')
    end
end
assert(countFeedback()==3)
Music.start()
return 'PASS loaded distinct palettes, cooldowns, three SFX voices, one music voice, independent groups and lifecycle cleanup'
