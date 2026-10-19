local Core=require('../src/server/Domain/FarmCore')
local Config=require('../src/shared/Config')
local Catalog=require('../src/shared/CreatureCatalog')
local function eq(a,b) assert(a==b,tostring(a)..' ~= '..tostring(b)) end
local function fixture()
    local c=Core.new(Config,Catalog)
    local s=c:newSession(7,0,'stack')
    c:dispatch(s,'Buy',{'starter'},{now=0,alive=true,position={x=Config.BuyPads['1'],y=3,z=34}})
    return c,s
end
local function buy(c,s,id,quantity)
    local x=Config.BuyPads[quantity] or 0
    return c:dispatch(s,'Buy',{id,quantity},{now=0,alive=true,position={x=x,y=3,z=34}})
end
local c,s=fixture(); s.state.coinUnits=80000
eq(buy(c,s,'locked','5').code,'Locked')
eq(s.state.coinUnits,80000); eq(#s.state.producers,1)
s.state.rebirths=3
eq(buy(c,s,'hundred','100').code,'OK')
eq(#s.state.producers,100); eq(s.state.coinUnits,80000-99*Config.BuyUnits)
eq(buy(c,s,'hundred','100').replayed,true)
eq(#s.state.producers,100)
eq(buy(c,s,'hundred','10').code,'RequestConflict')
eq(buy(c,s,'capacity','100').code,'PlotFull'); eq(s.state.coinUnits,80000-99*Config.BuyUnits)
eq(buy(c,s,'forged','99').code,'BadRequest')
local one=c:slotPosition(1); local ten=c:slotPosition(10); local eleven=c:slotPosition(11)
assert(ten.x<one.x); eq(eleven.x,one.x); assert(eleven.y>one.y); eq(eleven.z,one.z)
local due=s.state.producers[3].due; local survivor=s.state.producers[3].id
eq(c:dispatch(s,'Merge',{'merge',s.state.producers[1].id,s.state.producers[2].id},{now=2,alive=true,position={x=0,y=3,z=36}}).code,'OK')
local seen={}
for _,p in s.state.producers do seen[p.slot]=true; if p.id==survivor then eq(p.due,due) end end
for i=1,99 do assert(seen[i]) end
c:step(s,6)
for _,t in s.state.tokens do assert(t.y>0 and t.y<8); assert(t.z<one.z) end
local r,rs=fixture()
local ctx={now=12,alive=true,position={x=0,y=3,z=36}}
eq(r:dispatch(rs,'Rebirth',{'rb'},ctx).code,'NeedTier6')
rs.state.producers[1].speciesId='tier_06'; rs.state.discoveries.tier_06=true
eq(r:dispatch(rs,'Rebirth',{'rb'},ctx).code,'InsufficientFunds')
eq(Config.RebirthBase,4000000)
rs.state.coinUnits=Config.RebirthBase-1
eq(r:dispatch(rs,'Rebirth',{'under-price'},ctx).code,'InsufficientFunds')
rs.state.coinUnits=Config.RebirthBase; r:step(rs,6)
eq(r:dispatch(rs,'Rebirth',{'rb'},ctx).code,'OK')
eq(rs.state.rebirths,1); eq(rs.state.coinUnits,0); eq(#rs.state.tokens,0); eq(#rs.state.bag,0)
eq(rs.state.producers[1].speciesId,'tier_01'); eq(rs.state.producers[1].due,18)
eq(rs.state.discoveries.tier_06,true)
eq(r:dispatch(rs,'Rebirth',{'rb'},ctx).replayed,true); eq(rs.state.rebirths,1)
rs.state.coinUnits=5*Config.BuyUnits-1
eq(buy(r,rs,'poor','5').code,'InsufficientFunds'); eq(rs.state.coinUnits,5*Config.BuyUnits-1); eq(#rs.state.producers,1)
rs.state.rebirths=20
eq(r:dispatch(rs,'Rebirth',{'limit'},ctx).code,'MaxRebirths')
print('PASS bulk purchase, unlock, replay, packing, ground tokens and rebirth regressions')
