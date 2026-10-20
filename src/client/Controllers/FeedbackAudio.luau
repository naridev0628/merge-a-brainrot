--!strict
-- Three reusable voices, short fades and action priority over pickup chatter.
local Config=require(script.Parent.AudioConfig)
local Preloader=require(script.Parent.AudioPreloader)
local Preferences=require(script.Parent.Preferences)
local Audio={}
type Voice={sound: Sound,priority: number,untilAt: number,version: number,jobs: {thread}}
local voices: {Voice}={}
local soundService=game:GetService('SoundService')
local lastByKind: {[string]: number}={}
local delayed: {[string]: {thread}}={}
local lastNote=-math.huge
local lastPriority=0
local lastAction=-math.huge
local running=false
local generation=0
local function cancel(jobs: {thread})
    for _,job in jobs do pcall(task.cancel,job) end
    table.clear(jobs)
end
function Audio.start()
    if running then return end
    running=true;generation+=1
    for index=1,Config.VoiceCount do
        local name='FarmFeedback'..index
        local existing=soundService:FindFirstChild(name)
        local sound: Sound
        if existing and existing:IsA('Sound') then sound=existing
        else sound=Instance.new('Sound');sound.Name=name end
        sound:Stop();sound.SoundId=Config.Assets.Coin
        sound.SoundGroup=Preferences.getSoundGroup('sfx')
        sound.Looped=false;sound.Volume=0;sound.Parent=soundService
        table.insert(voices,{sound=sound,priority=0,untilAt=0,version=0,jobs={}})
    end
    for _,id in Config.Assets do Preloader.request(id) end
end
local function note(assetId: string,tone: any,volume: number,priority: number,token: number)
    if not running or token~=generation then return end
    if Preloader.status(assetId)~='ready' then
        assetId=Config.Assets.Coin
        if Preloader.status(assetId)~='ready' then return end
    end
    local now=os.clock()
    if (now-lastNote<.045 and priority<=lastPriority) or (priority==1 and now-lastAction<.10) then return end
    local chosen: Voice?=nil
    for _,voice in voices do
        if voice.untilAt<=now then chosen=voice;break end
        if voice.priority<=priority and (not chosen or voice.priority<chosen.priority
            or (voice.priority==chosen.priority and voice.untilAt<chosen.untilAt)) then chosen=voice end
    end
    if not chosen then return end
    local voice=chosen :: Voice
    cancel(voice.jobs);voice.version+=1
    local version=voice.version
    lastNote=now;lastPriority=priority;if priority>1 then lastAction=now end
    voice.priority=priority;voice.untilAt=now+tone.length
    local sound=voice.sound
    sound:Stop();sound.SoundId=assetId;sound.PlaybackSpeed=tone.pitch
    local gain=volume*(tone.gain or 1)
    sound.Volume=gain;sound.TimePosition=0;sound:Play()
    -- A tiny tail fade avoids hard truncation without a frame loop or new voice.
    for step=1,3 do
        local job=task.delay(tone.length-.06+step*.02,function()
            if not running or token~=generation or version~=voice.version then return end
            sound.Volume=gain*(1-step/3)
            if step==3 then sound:Stop() end
        end)
        table.insert(voice.jobs,job)
    end
end
function Audio.play(kind: string): boolean
    local pattern=Config.Patterns[kind]
    if not pattern then return false end
    Audio.start()
    local now=os.clock();local key=pattern.group or kind
    if now-(lastByKind[key] or -math.huge)<pattern.cooldown then return false end
    lastByKind[key]=now
    local jobs=delayed[key]
    if not jobs then jobs={};delayed[key]=jobs else cancel(jobs) end
    local token=generation
    for _,tone in pattern.notes do
        local assetId=Config.Assets[tone.asset or pattern.asset]
        if tone.at==0 then note(assetId,tone,pattern.volume,pattern.priority,token)
        else
            table.insert(jobs,task.delay(tone.at,function()
                note(assetId,tone,pattern.volume,pattern.priority,token)
            end))
        end
    end
    return true
end
function Audio.destroy()
    running=false;generation+=1
    for _,jobs in delayed do cancel(jobs) end
    for _,voice in voices do cancel(voice.jobs);voice.sound:Stop();voice.sound:Destroy() end
    table.clear(voices);table.clear(lastByKind);table.clear(delayed)
    lastNote=-math.huge;lastAction=-math.huge;lastPriority=0
end
Audio.start()
return Audio
