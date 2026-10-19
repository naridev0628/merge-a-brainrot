local Core=require('../src/server/Domain/FarmCore')
local Config=require('../src/shared/Config')
local Catalog=require('../src/shared/CreatureCatalog')
local Tutorial=require('../src/shared/Tutorial')
local core=Core.new(Config,Catalog,function() return 1 end)
local s=core:newSession(1,0,'fair')
core:dispatch(s,'Buy',{'free'},{now=0,alive=true,position={x=Config.BuyPads['1'],y=3,z=34}})
s.state.rebirths=3; s.state.coinUnits=10000
core:dispatch(s,'Buy',{'bulk','100'},{now=0,alive=true,position={x=Config.BuyPads['100'],y=3,z=34}})
core:setPasses(s,{mini2=true})
local finalId=s.state.producers[100].id
local produced={}
for cycle=1,3 do
    core:step(s,cycle*6)
    for _,t in s.state.tokens do produced[t.origin]=true end
    s.state.tokens={}
end
assert(produced[finalId],'last producer starved across three collected cycles')
for _,p in s.state.producers do assert(produced[p.id],'a producer never got a turn') end
local two=core:newSession(2,0,'tutorial')
two.state.starterClaimed=true
two.state.coinUnits=0
two.state.producers={{id='a',speciesId='tier_01',slot=1,due=6},{id='b',speciesId='tier_03',slot=2,due=6}}
assert(Tutorial.goal(two.state).kind=='Collect','tutorial requests an impossible merge')
print('PASS fair capped production and tutorial recovery after unmatched Lucky rewards')
