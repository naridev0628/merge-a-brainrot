local Targeting=require('../src/shared/PadTargeting')
local Config=require('../src/shared/Config')
local Catalog=require('../src/shared/CreatureCatalog')
-- Plain point records keep targeting executable without Roblox's Vector3 runtime.
local map={
    Sell={X=-27,Y=.15,Z=-28},Claim={X=-35,Y=.15,Z=-12},
    Merge={X=0,Y=.15,Z=40},Upgrade={X=-37,Y=.15,Z=11},
    FinishNow={X=-37,Y=.15,Z=23},PassPads={mini2={X=-13,Y=.15,Z=-28}},
}
local state={bag={},soldUnits=0,producers={}}
local function resolve(x,y,z,layout)
    return Targeting.resolve(Config,Catalog,layout or map,state,{x=x,y=y,z=z})
end
local function pad(x,z,key,action,kind,value)
    local target=resolve(x,0,z)
    assert(target.key==key,'Wrong footprint: '..tostring(target.key))
    assert(target.action==action,'Wrong action: '..tostring(target.action))
    assert(target.kind==kind and target.value==(value or '1'),'Wrong context')
    return target
end

-- Empty pads must retain ownership/context without sending a futile action.
pad(-27,-28,'Deposit',nil,'Deposit')
pad(-35,-12,'Claim',nil,'Claim')
state.bag={{speciesId='tier_01',count=1}}
state.soldUnits=1
pad(-27,-28,'Deposit','Deposit','Deposit')
pad(-35,-12,'Claim','Claim','Claim')
pad(-37,11,'Upgrade','Upgrade','Upgrade')
for quantity,x in Config.BuyPads do
    local target=pad(x,56,'Buy'..quantity,'Buy','Buy',quantity)
    assert(#target.values==1 and target.values[1]==quantity,'Buy keeps its exact request quantity')
end

-- Merge only activates for an actual upgradable pair, not different or max-tier producers.
state.producers={{speciesId='tier_01'},{speciesId='tier_02'}}
pad(0,40,'AutoMerge',nil,'Merge')
state.producers={{speciesId='tier_06'},{speciesId='tier_06'}}
pad(0,40,'AutoMerge',nil,'Merge')
state.producers={{speciesId='tier_01'},{speciesId='tier_02'},{speciesId='tier_01'}}
pad(0,40,'AutoMerge','AutoMerge','Merge')

-- Full rendered corners own context even beyond the nearby-label radius.
pad(-36.35,-33.35,'Deposit','Deposit','Deposit')
local overlap=table.clone(map)
overlap.PassPads={nearby={X=-36.35,Y=0,Z=-33.35}}
local corner=resolve(-36.35,0,-33.35,overlap)
assert(corner.kind=='Deposit','A closer pass label must not steal a pad footprint')
assert(resolve(44,7.01,56).key==nil,'Standing above a pad must not trigger it')
assert(resolve(44,-.11,56).action==nil,'Standing below a pad must not trigger it')
assert(resolve(49.36,0,56).key==nil,'Outside the Buy surface must not trigger it')

-- Nearby labels remain available outside the action footprint, with strict range/tie rules.
local nearBuy=resolve(44,0,61)
assert(nearBuy.key==nil and nearBuy.action==nil and nearBuy.kind=='Buy' and nearBuy.value=='1')
local finish=resolve(-37,.15,23)
assert(finish.key==nil and finish.kind=='FinishNow')
local pass=resolve(-13,.15,-28)
assert(pass.key==nil and pass.kind=='Pass' and pass.value=='mini2')
local ties={Sell={X=0,Y=0,Z=0},Claim={X=0,Y=0,Z=0},Merge=map.Merge,Upgrade=map.Upgrade,
    FinishNow=map.FinishNow,PassPads={tie={X=0,Y=0,Z=0}}}
assert(resolve(0,0,0,ties).kind=='Deposit','Equal distances retain first label priority')
assert(resolve(0,0,-10,ties).kind==nil,'Labels exactly at the range limit are hidden')
local outside=resolve(200,0,200)
assert(outside.key==nil and outside.action==nil and outside.kind==nil and outside.value=='1')
print('PASS pad action eligibility, exact Buy requests, merge pairs, corner ownership and nearby context')
