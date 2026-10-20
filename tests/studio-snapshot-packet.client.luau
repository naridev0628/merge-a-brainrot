assert(game:GetService('RunService'):IsStudio())
local folder=assert(game.ReplicatedStorage:FindFirstChild('SnapshotPacketProbe'))
local remote=folder.Packet
local previous
local function same(a,b)
    if type(a)~=type(b) then return false end
    if type(a)~='table' then return a==b end
    for key,value in a do if not same(value,b[key]) then return false end end
    for key in b do if a[key]==nil then return false end end
    return true
end
local connection
connection=remote.OnClientEvent:Connect(function(phase,packet,expected)
    if phase=='first' then
        assert(#packet.producers==50 and #packet.tokens==96)
        for key,value in expected do assert(same(packet[key],value),'Wire field differs: '..key) end
        assert(packet.status=='Ready' and packet.memoryOnly and packet.serverNow==102)
        assert(packet.plotId==1 and typeof(packet.plotCFrame)=='CFrame')
        assert(packet.sessionKey=='isolated-wire-probe' and packet.timePlayed==0)
        assert(packet.obby.phase=='Available')
        assert(packet.tokens~=expected.tokens,'RemoteEvent must copy separate table arguments')
        previous=packet
        packet.tokens[1].x=1000000
        packet.obby.phase='Client edit'
        remote:FireServer('mutated')
    elseif phase=='second' then
        assert(packet.eventHundredths==125 and packet.serverNow==103)
        assert(packet.tokens[1].x~=1000000 and packet.obby.phase=='Available')
        assert(previous.tokens[1].x==1000000 and previous.eventHundredths~=125)
        connection:Disconnect()
        remote:FireServer('passed')
    else
        error('Unexpected packet phase')
    end
end)
remote:FireServer('ready')
return 'Snapshot packet client probe connected'
