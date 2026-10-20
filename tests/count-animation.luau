local Counter=require('../src/shared/CountAnimation')
local c=Counter.new()
c:set(100,0);assert(c:read(0)==100,'Initial snapshot must not count from zero')
c:set(200,1);assert(c:read(1)==100)
local last=100
for i=1,8 do
    local value=c:read(1+i*.1)
    assert(value>=last and value<=200,'Count must progress monotonically without overshoot')
    last=value
end
assert(last==200,'The target must be reached within one second')
c:set(300,2);local midway=c:read(2.3)
c:set(400,2.3);assert(c:read(2.3)==midway,'Further pickups must not jump')
c:set(400,2.6);assert(c:read(3.11)==400,'Identical snapshots must not restart animation')
c:set(500,4);c:read(4.2);c:set(0,4.2)
assert(c:read(4.2)==0 and c:read(5)==0,'Deposit must cancel any animated increase immediately')
c:set(4294967295,6);assert(c:read(6.9)==4294967295,'Large counts must end exactly')
print('PASS basket count animation, retargeting, snapshot stability, deposit reset and large counts')
