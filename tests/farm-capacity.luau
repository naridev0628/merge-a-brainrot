local Capacity=require('../src/shared/FarmCapacity')
local function state(producers,tokens)
    local snapshot={producers={},tokens={},bag={{count=100000}},saleQueue={{count=100000}}}
    for index=1,producers do table.insert(snapshot.producers,{id='p'..index}) end
    for index=1,tokens do table.insert(snapshot.tokens,{id='t'..index,readyAt=1000}) end
    return snapshot
end
local config={Slots=50,GroundCap=50}
local empty=state(0,0)
local info=Capacity.inspect(config,empty)
assert(info.spacesLeft==50 and not info.producersFull and not info.trayFull)
assert(Capacity.hint(config,empty)=='50 spaces left','Bag/processor quantities must not consume producer slots')
assert(Capacity.hint(config,state(49,49))=='1 space left','Partial capacity must stay actionable and singular')
assert(Capacity.hint(config,state(50,0))=='Merge to make room','Owned Brainrots stay present when producer slots fill')
assert(Capacity.hint(config,state(7,50))=='Tray full • Collect Minis','Physical tokens include in-flight drops reserved by the domain')
assert(Capacity.hint(config,state(50,50))=='Tray full • Collect Minis','Tray hint wins when the buy action already explains the merge requirement')
local recovering=state(10,50)
table.remove(recovering.tokens)
assert(Capacity.hint(config,recovering)=='40 spaces left','Collection must clear the full-tray message on the next snapshot')
local larger={Slots=96,GroundCap=96}
assert(Capacity.hint(larger,state(50,50))=='46 spaces left','Neither limit may be hardcoded to the current 50')
assert(Capacity.hint(larger,state(96,95))=='Merge to make room')
assert(Capacity.hint(larger,state(95,96))=='Tray full • Collect Minis')
local separate={Slots=96,GroundCap=128}
assert(Capacity.hint(separate,state(95,96))=='1 space left','Producer and tray limits remain independent')
assert(Capacity.hint(separate,state(95,128))=='Tray full • Collect Minis')
local full=state(50,50)
table.freeze(full.producers);table.freeze(full.tokens);table.freeze(full)
info=Capacity.inspect(config,full)
assert(info.producerCount==50 and info.tokenCount==50 and info.spacesLeft==0)
assert(info.producersFull and info.trayFull)
info.spacesLeft=99
assert(Capacity.inspect(config,full).spacesLeft==0,'Presentation results must not become shared mutable state')
print('PASS capacity hints: empty/partial/full, collection recovery, in-flight tokens, independent limits and dynamic 96-slot config')
