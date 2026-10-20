--!strict
local Config=require(script.Parent.AudioConfig)
local Preloader=require(script.Parent.AudioPreloader)
local Preferences=require(script.Parent.Preferences)
local soundService=game:GetService('SoundService')
local tweenService=game:GetService('TweenService')
local Music={}
local sound: Sound?=nil
local fade: Tween?=nil
local generation=0
local running=false

function Music.start()
    if running then return end
    running=true;generation+=1
    local token=generation
    if not sound then
        local existing=soundService:FindFirstChild('FarmSoundtrack')
        if existing and existing:IsA('Sound') then sound=existing
        else sound=Instance.new('Sound');sound.Name='FarmSoundtrack' end
    end
    local voice=sound :: Sound
    voice:Stop();voice.Volume=0
    voice.SoundId=Config.Music.Id
    voice.SoundGroup=Preferences.getSoundGroup('music')
    voice.Looped=true;voice.PlaybackSpeed=1;voice.Parent=soundService
    Preloader.request(Config.Music.Id,function(success)
        if not success or not running or token~=generation or sound~=voice then return end
        voice.TimePosition=0;voice:Play()
        fade=tweenService:Create(voice,TweenInfo.new(Config.Music.FadeSeconds),{Volume=Config.Music.Volume})
        fade:Play()
    end)
end

function Music.stop()
    running=false;generation+=1
    if fade then fade:Cancel();fade:Destroy();fade=nil end
    if sound then sound:Stop();sound.Volume=0 end
end

function Music.destroy()
    Music.stop()
    if sound then sound:Destroy();sound=nil end
end
return Music
