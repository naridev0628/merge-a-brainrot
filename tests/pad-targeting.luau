local Targeting=require('../src/shared/PadTargeting')
local Config=require('../src/shared/Config')
local Catalog=require('../src/shared/CreatureCatalog')
-- Plain point records keep targeting executable without Roblox's Vector3 runtime.
local map={
    Sell={X=Config.SellX,Y=.15,Z=Config.SellZ},Claim={X=Config.ClaimX,Y=.15,Z=Config.ClaimZ},
    Merge={X=Config.MergeX,Y=.15,Z=Config.MergeZ},Upgrade={X=Config.UpgradeX,Y=.15,Z=Config.UpgradeZ},
    FinishNow={X=-37,Y=.15,Z=23},PassPads={mini2={X=35,Y=.15,Z=-28}},
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
pad(Config.SellX,Config.SellZ,'Deposit',nil,'Deposit')
pad(Config.ClaimX,Config.ClaimZ,'Claim',nil,'Claim')
state.bag={{speciesId='tier_01',count=1}}
state.soldUnits=1
pad(Config.SellX,Config.SellZ,'Deposit','Deposit','Deposit')
pad(Config.ClaimX,Config.ClaimZ,'Claim','Claim','Claim')
pad(-37,11,'Upgrade','Upgrade','Upgrade')
for quantity,x in Config.BuyPads do
    local target=pad(x,Config.BuyZ,'Buy'..quantity,'Buy','Buy',quantity)
    assert(#target.values==1 and target.values[1]==quantity,'Buy keeps its exact request quantity')
end

-- Merge requires three of one upgradable species, never a pair or a max-tier triple.
state.producers={{speciesId='tier_01'},{speciesId='tier_02'}}
pad(Config.MergeX,Config.MergeZ,'AutoMerge',nil,'Merge')
local maxId=string.format('tier_%02d',Config.MaxTier)
state.producers={{speciesId=maxId},{speciesId=maxId},{speciesId=maxId}}
pad(Config.MergeX,Config.MergeZ,'AutoMerge',nil,'Merge')
state.producers={{speciesId='tier_01'},{speciesId='tier_02'},{speciesId='tier_01'}}
pad(Config.MergeX,Config.MergeZ,'AutoMerge',nil,'Merge')
table.insert(state.producers,{speciesId='tier_02'})
pad(Config.MergeX,Config.MergeZ,'AutoMerge',nil,'Merge')
table.insert(state.producers,{speciesId='tier_01'})
pad(Config.MergeX,Config.MergeZ,'AutoMerge','AutoMerge','Merge')

-- Full rendered corners own context even beyond the nearby-label radius.
pad(Config.SellX-9.35,Config.SellZ-5.35,'Deposit','Deposit','Deposit')
local overlap=table.clone(map)
overlap.PassPads={nearby={X=Config.SellX-9.35,Y=0,Z=Config.SellZ-5.35}}
local corner=resolve(Config.SellX-9.35,0,Config.SellZ-5.35,overlap)
assert(corner.kind=='Deposit','A closer pass label must not steal a pad footprint')
assert(resolve(Config.BuyPads['1'],7.01,Config.BuyZ).key==nil,'Standing above a pad must not trigger it')
assert(resolve(Config.BuyPads['1'],-.11,Config.BuyZ).action==nil,'Standing below a pad must not trigger it')
assert(resolve(Config.BuyPads['1']+5.36,0,Config.BuyZ).key==nil,'Outside the Buy surface must not trigger it')

-- Nearby labels remain available outside the action footprint, with strict range/tie rules.
local nearBuy=resolve(Config.BuyPads['1'],0,Config.BuyZ+5)
assert(nearBuy.key==nil and nearBuy.action==nil and nearBuy.kind=='Buy' and nearBuy.value=='1')
local finish=resolve(-37,.15,23)
assert(finish.key==nil and finish.kind==nil,'Removed Finish Now pads must not leave invisible prompts')
local pass=resolve(35,.15,-28)
assert(pass.key==nil and pass.kind==nil,'Removed pass pads must not leave invisible prompts')
local ties={Sell={X=0,Y=0,Z=0},Claim={X=0,Y=0,Z=0},Merge=map.Merge,Upgrade=map.Upgrade,
    FinishNow=map.FinishNow,PassPads={tie={X=0,Y=0,Z=0}}}
assert(resolve(0,0,0,ties).kind=='Deposit','Equal distances retain first label priority')
assert(resolve(0,0,-10,ties).kind==nil,'Labels exactly at the range limit are hidden')
local outside=resolve(200,0,200)
assert(outside.key==nil and outside.action==nil and outside.kind==nil and outside.value=='1')
print('PASS pad action eligibility, exact Buy requests, matching triples, pair/max-tier rejection, corner ownership and nearby context')
