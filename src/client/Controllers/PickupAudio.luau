--!strict
-- Free Creator Store audio: Coin Collect by G00byBBQSauce (135483737426662).
local Audio={}
local sound=Instance.new('Sound'); sound.Name='MiniPickup'; sound.SoundId='rbxassetid://135483737426662'
sound.Volume=.25; sound.Parent=game:GetService('SoundService')
task.spawn(function() pcall(function() game:GetService('ContentProvider'):PreloadAsync({sound}) end) end)
local last=-10
function Audio.play()
    local now=os.clock()
    if now-last<.10 then return end -- A tray full of Minis produces a gentle chime, not dozens of overlapping sounds.
    last=now; sound.PlaybackSpeed=1+(math.random()-.5)*.12; sound.TimePosition=0; sound:Play()
end
return Audio
