--!strict
-- Fixed voice budget, session-cached assets and independent SFX preferences.
local Config=require(script.Parent.AudioConfig)
local Preloader=require(script.Parent.AudioPreloader)
local Preferences=require(script.Parent.Preferences)
local Audio={}
local voices: {Sound}={}
local soundService=game:GetService('SoundService')
local lastByKind: {[string]: number}={}
local lastNote=-math.huge
local voiceIndex=0
local running=false
local generation=0

function Audio.start()
    if running then return end
    running=true
    generation+=1
    for index=1,Config.VoiceCount do
        local name='FarmFeedback'..index
        local existing=soundService:FindFirstChild(name)
        local sound: Sound
        if existing and existing:IsA('Sound') then sound=existing
        else sound=Instance.new('Sound');sound.Name=name end
        sound:Stop()
        sound.SoundId=Config.Assets.Coin
        sound.SoundGroup=Preferences.getSoundGroup('sfx')
        sound.Looped=false;sound.Volume=0;sound.Parent=soundService
        table.insert(voices,sound)
    end
    for _,id in Config.Assets do Preloader.request(id) end
end

local function note(assetId: string,pitch: number,volume: number,token: number)
    if not running or token~=generation then return end
    if Preloader.status(assetId)~='ready' then
        assetId=Config.Assets.Coin
        if Preloader.status(assetId)~='ready' then return end
    end
    local now=os.clock()
    if now-lastNote<.065 then return end
    lastNote=now;voiceIndex=voiceIndex%#voices+1
    local voice=voices[voiceIndex]
    voice:Stop();voice.SoundId=assetId;voice.PlaybackSpeed=pitch
    voice.Volume=volume;voice.TimePosition=0;voice:Play()
end
function Audio.play(kind: string): boolean
    local pattern=Config.Patterns[kind]
    if not pattern then return false end
    Audio.start()
    local now=os.clock()
    if now-(lastByKind[kind] or -math.huge)<pattern.cooldown then return false end
    lastByKind[kind]=now
    local token=generation
    local assetId=Config.Assets[pattern.asset]
    for index,pitch in pattern.notes do
        if index==1 then note(assetId,pitch,pattern.volume,token)
        else task.delay((index-1)*.12,function() note(assetId,pitch,pattern.volume,token) end) end
    end
    return true
end
function Audio.destroy()
    running=false;generation+=1
    for _,sound in voices do sound:Stop();sound:Destroy() end
    table.clear(voices);table.clear(lastByKind)
    voiceIndex=0;lastNote=-math.huge
end
-- Preserve the existing require-to-initialize contract.
Audio.start()
return Audio
