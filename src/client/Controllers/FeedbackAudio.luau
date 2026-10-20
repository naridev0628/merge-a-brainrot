--!strict
-- Reuse the project's cleared Creator Store cue, not extracted reference audio.
local Audio={}
local patterns={
    Pickup={cooldown=.10,volume=.17,notes={1.16}},
    Buy={cooldown=.35,volume=.21,notes={.96}},
    Upgrade={cooldown=.40,volume=.23,notes={1.02,1.30}},
    Deposit={cooldown=.60,volume=.23,notes={.88,1.08}},
    Claim={cooldown=.35,volume=.25,notes={1.03,1.27}},
    Merge={cooldown=.65,volume=.22,notes={.94,1.18,1.40}},
    AutoMerge={cooldown=.65,volume=.22,notes={.94,1.18,1.40}},
    PickupLucky={cooldown=.35,volume=.18,notes={1.08}},
    OpenLucky={cooldown=.80,volume=.24,notes={.90,1.17,1.46}},
    Rebirth={cooldown=1.50,volume=.25,notes={1.00,1.25,1.50}},
}
local voices: {Sound}={}
local soundService=game:GetService('SoundService')
for index=1,3 do
    local name='FarmFeedback'..index
    local existing=soundService:FindFirstChild(name)
    local sound: Sound
    if existing and existing:IsA('Sound') then
        sound=existing
    else
        sound=Instance.new('Sound'); sound.Name=name
        sound.SoundId='rbxassetid://135483737426662' -- Coin Collect, G00byBBQSauce
        sound.Looped=false; sound.Volume=0; sound.Parent=soundService
    end
    table.insert(voices,sound)
end
task.spawn(function() pcall(function()game:GetService('ContentProvider'):PreloadAsync(voices)end) end)
local lastByKind: {[string]: number}={}
local lastNote=-math.huge
local voiceIndex=0
local function note(pitch: number,volume: number)
    local now=os.clock()
    if now-lastNote<.065 then return end
    lastNote=now;voiceIndex=voiceIndex%#voices+1
    local voice=voices[voiceIndex]
    voice:Stop();voice.PlaybackSpeed=pitch;voice.Volume=volume;voice.TimePosition=0;voice:Play()
end
function Audio.play(kind: string): boolean
    local pattern=patterns[kind]
    if not pattern then return false end
    local now=os.clock()
    if now-(lastByKind[kind] or -math.huge)<pattern.cooldown then return false end
    lastByKind[kind]=now
    for index,pitch in pattern.notes do
        if index==1 then note(pitch,pattern.volume)
        else task.delay((index-1)*.12,function() note(pitch,pattern.volume) end) end
    end
    return true
end
return Audio
