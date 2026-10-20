local Packet=require('../src/server/Domain/SnapshotPacket')
local Core=require('../src/server/Domain/FarmCore')
local Config=require('../src/shared/Config')
local Catalog=require('../src/shared/CreatureCatalog')
local Scenario=require('./CapacityHarnessScenario')

local function same(a,b)
    if type(a)~=type(b) then return false end
    if type(a)~='table' then return a==b end
    for key,value in a do if not same(value,b[key]) then return false end end
    for key in b do if a[key]==nil then return false end end
    return true
end
local world={id=4,frame='opaque plot CFrame'}
local obby={phase='Cooldown',checkpoint=0,bonusHundredths=25,boostExpiresAt=400,cooldownEndsAt=700}
local function legacy(core,session,now)
    local packet=core:snapshot(session)
    packet.status=session.phase;packet.memoryOnly=true;packet.serverNow=now
    packet.plotId=world.id;packet.plotCFrame=world.frame;packet.sessionKey=session.key
    packet.timePlayed=math.floor(now-(session.joinedAt or now));packet.obby=obby
    return packet
end
local run=Scenario.new(Core,Config,Catalog,96,100)
local core,session=run.core,run.sessions[1]
session.joinedAt=90.25
local packet=Packet.build(session,world,100.75,obby)
local thread=coroutine.create(Packet.build)
local resumed,immediate=coroutine.resume(thread,session,world,100.75,obby)
assert(resumed and coroutine.status(thread)=='dead' and same(immediate,packet),
    'Packet construction must finish without yielding before FireClient')
assert(same(packet,legacy(core,session,100.75)),'Every state field and wire metadata must match the deep-copy packet')
assert(packet.status=='Ready' and packet.memoryOnly and packet.serverNow==100.75)
assert(packet.plotId==4 and packet.plotCFrame==world.frame and packet.sessionKey==session.key)
assert(packet.timePlayed==10 and packet.obby==obby,'Use the supplied clock and obby snapshot unchanged')
assert(packet~=session.state,'Packet metadata requires its own root')
assert(session.state.serverNow==nil and session.state.obby==nil and session.state.plotId==nil,
    'Building a packet must not add wire metadata to authoritative state')
packet.coinUnits=123;packet.status='local envelope'
assert(session.state.coinUnits==0 and session.phase=='Ready','Root edits must not change the session')

-- Borrow committed nested tables rather than copying 50 producers/96 tokens.
-- Observing actual recursive iteration catches a deep-copy regression without
-- replacing Core.snapshot or the packet implementation.
local traversed=0
local function observe(value)
    for _,child in value do if type(child)=='table' then observe(child) end end
    setmetatable(value,{__iter=function(t) traversed+=1;return next,t end})
end
for _,child in session.state do if type(child)=='table' then observe(child) end end
packet=Packet.build(session,world,101,obby)
assert(traversed==0,'Packet creation must not traverse/copy committed nested state')
for _,key in {'producers','tokens','bag','saleQueue','discoveries'} do
    assert(packet[key]==session.state[key],'Committed nested table should be borrowed: '..key)
end
local transaction=core:snapshot(session)
assert(traversed==151,'Core.snapshot must still deeply copy all 151 nested tables in this full farm')
transaction.producers[1].due+=50
transaction.tokens[1].x+=50
transaction.discoveries.tier_01=false
assert(transaction.producers[1].due~=session.state.producers[1].due
    and transaction.tokens[1].x~=session.state.tokens[1].x and session.state.discoveries.tier_01,
    'Transaction snapshots must remain independently mutable')

-- Every transition must replace committed state, leaving previously built
-- outbound packets stable even after repacking, merging or rebirth.
local function transition(name,change)
    local previous=Packet.build(session,world,110,obby)
    local expected=legacy(core,session,110)
    local before=session.state
    change()
    assert(same(previous,expected),name..' mutated a previously built packet')
    assert(session.state~=before,name..' must actually exercise a committed change')
    assert(same(Packet.build(session,world,110,obby),legacy(core,session,110)),name..' changed wire contents')
end
transition('event',function() core:setEvent(session,125) end)
transition('bonus',function() assert(core:setObbyBonus(session,25)) end)
transition('passes',function() core:setPasses(session,{cash2=true}) end)
transition('due production',function() assert(core:step(session,101)) end)
transition('pickup/repack',function()
    local token=session.state.tokens[1]
    assert(core:dispatch(session,'Collect',{token.id},
        {now=101,alive=true,position={x=token.x,y=token.y,z=token.z}}).code=='OK')
end)
transition('deposit',function()
    assert(core:dispatch(session,'Deposit',{'packet-deposit'},
        {now=101,alive=true,position={x=Config.SellX,y=0,z=Config.SellZ}}).code=='OK')
end)
transition('sales',function() assert(core:step(session,101.5)) end)
transition('claim',function()
    assert(core:dispatch(session,'Claim',{'packet-claim'},
        {now=101.5,alive=true,position={x=Config.ClaimX,y=0,z=Config.ClaimZ}}).code=='OK')
end)
transition('merge',function()
    assert(core:dispatch(session,'AutoMerge',{'packet-merge'},
        {now=101.5,alive=true,position={x=Config.MergeX,y=0,z=Config.MergeZ}}).code=='OK')
end)
local seeded=core:snapshot(session)
seeded.lucky={id='packet-lucky',baseTier=3,held=false}
seeded.coinUnits=Config.RebirthBase
assert(core:commit(session,seeded))
transition('Lucky hold',function()
    assert(core:dispatch(session,'PickupLucky',{'packet-hold','packet-lucky'},
        {now=101.5,alive=true,position={x=Config.LuckyX,y=0,z=Config.LuckyZ}}).code=='OK')
end)
transition('rebirth',function()
    assert(core:dispatch(session,'Rebirth',{'packet-rebirth'},
        {now=101.5,alive=true,position={x=0,y=0,z=Config.MergeZ}}).code=='OK')
end)

local fresh=core:newSession(7,500,'fresh-session')
local freshPacket=Packet.build(fresh,world,500.75,nil)
assert(freshPacket.timePlayed==0 and freshPacket.obby==nil and freshPacket.sessionKey=='fresh-session')
assert(#freshPacket.producers==0 and #freshPacket.tokens==0,'No prior packet/session data may be cached')
fresh.phase='Closing'
assert(Packet.build(fresh,world,501,nil).status=='Closing','Status must reflect the current session')
print('PASS snapshot packet parity, metadata isolation, zero nested copies, deep transactions and eleven real Core transitions')
