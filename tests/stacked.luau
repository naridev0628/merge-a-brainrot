local Economy=require('../src/shared/Economy')
local Core=require('../src/server/Domain/FarmCore')
local Config=require('../src/shared/Config')
local Catalog=require('../src/shared/CreatureCatalog')
local function eq(a,b) assert(a==b,tostring(a)..' ~= '..tostring(b)) end
local function fixture()
    local c=Core.new(Config,Catalog)
    local s=c:newSession(7,0,'stack')
    c:dispatch(s,'Buy',{'starter'},{now=0,alive=true,position={x=Config.BuyPads['1'],y=3,z=Config.BuyZ}})
    return c,s
end
local function buy(c,s,id,quantity)
    local x=Config.BuyPads[quantity] or 0
    return c:dispatch(s,'Buy',{id,quantity},{now=0,alive=true,position={x=x,y=3,z=Config.BuyZ}})
end
local c,s=fixture(); s.state.coinUnits=4000000
eq(buy(c,s,'locked','100').code,'Locked')
eq(s.state.coinUnits,4000000); eq(#s.state.producers,1)
s.state.rebirths=3
local quote=Economy.purchaseQuote(Config,s.state,'100')
eq(buy(c,s,'hundred','100').code,'OK')
eq(#s.state.producers,#quote.mergePlan); eq(s.state.coinUnits,4000000-Economy.buyCost(1,100,3))
eq(buy(c,s,'hundred','100').replayed,true)
eq(buy(c,s,'hundred','10').code,'RequestConflict')
eq(buy(c,s,'forged','50').code,'BadRequest')
-- Keep fifty placed producers for the independent shelf/merge geometry checks.
c,s=fixture();s.state.coinUnits=4000000
for index=1,49 do eq(buy(c,s,'single'..index,'1').code,'OK') end
local one=c:slotPosition(1); local ten=c:slotPosition(10); local eleven=c:slotPosition(11)
assert(ten.x<one.x); eq(eleven.x,one.x); assert(eleven.y>one.y); eq(eleven.z,one.z)
assert(one.x-ten.x>=90,'Ten producer bays must span the broad rear bank')
assert(math.abs(one.x)<=46 and math.abs(ten.x)<=46,'End producers must drop onto the existing 102-stud conveyor')
for slot=2,Config.Columns do
    eq(c:slotPosition(slot-1).x-c:slotPosition(slot).x,10)
end
local due=s.state.producers[4].due; local survivor=s.state.producers[4].id
eq(c:dispatch(s,'Merge',{'merge',s.state.producers[1].id,s.state.producers[2].id,s.state.producers[3].id},{now=2,alive=true,position={x=0,y=3,z=36}}).code,'OK')
local seen={}
for _,p in s.state.producers do seen[p.slot]=true; if p.id==survivor then eq(p.due,due) end end
for i=1,48 do assert(seen[i]) end
c:step(s,6)
for _,t in s.state.tokens do assert(t.y>0 and t.y<8); assert(t.z<one.z) end
local r,rs=fixture()
local ctx={now=12,alive=true,position={x=0,y=3,z=36}}
eq(r:dispatch(rs,'Rebirth',{'rb'},ctx).code,'NeedTier6')
rs.state.producers[1].speciesId='tier_06'; rs.state.discoveries.tier_06=true
eq(r:dispatch(rs,'Rebirth',{'rb'},ctx).code,'InsufficientFunds')
eq(Config.RebirthBase,100000)
rs.state.coinUnits=Config.RebirthBase-1
eq(r:dispatch(rs,'Rebirth',{'under-price'},ctx).code,'InsufficientFunds')
rs.state.coinUnits=Config.RebirthBase; r:step(rs,6)
eq(r:dispatch(rs,'Rebirth',{'rb'},ctx).code,'OK')
eq(rs.state.rebirths,1); eq(rs.state.coinUnits,0); eq(#rs.state.tokens,0); eq(Economy.count(rs.state.bag),0)
eq(rs.state.producers[1].speciesId,'tier_01'); eq(rs.state.producers[1].due,12+Config.Interval)
eq(rs.state.discoveries.tier_06,true)
eq(r:dispatch(rs,'Rebirth',{'rb'},ctx).replayed,true); eq(rs.state.rebirths,1)
rs.state.coinUnits=5*Config.BuyUnits-1
eq(buy(r,rs,'poor','5').code,'InsufficientFunds'); eq(rs.state.coinUnits,5*Config.BuyUnits-1); eq(#rs.state.producers,1)
rs.state.rebirths=20
eq(r:dispatch(rs,'Rebirth',{'limit'},ctx).code,'MaxRebirths')
print('PASS bulk purchase, unlock, replay, packing, ground tokens and rebirth regressions')
