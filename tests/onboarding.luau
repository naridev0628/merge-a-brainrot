local Economy=require('../src/shared/Economy')
local Tutorial=require('../src/shared/Tutorial')
local Input=require('../src/shared/StarterPad')
local Config=require('../src/shared/Config')
local state={starterClaimed=false,tutorialStep=0,producers={},bag={},saleQueue={},coinUnits=0,soldUnits=0}
assert(Tutorial.goal(state).title=='Buy your first Brainrot!')
assert(Input.shouldClaim(state,{x=Config.BuyPads['1'],y=3,z=Config.BuyZ},Config))
assert(Input.shouldClaim(state,{x=Config.BuyPads['1'],y=-0.00000048,z=Config.BuyZ},Config),'Grounded feet tolerate floating-point floor error')
assert(not Input.shouldClaim(state,{x=Config.BuyPads['1'],y=-2,z=Config.BuyZ},Config),'Below the plot is not on the pad')
assert(not Input.shouldClaim(state,{x=Config.BuyPads['1']+7,y=3,z=Config.BuyZ},Config),'Near the pad is not on the pad')
assert(not Input.shouldClaim(state,{x=Config.BuyPads['1'],y=20,z=Config.BuyZ},Config),'Do not claim while flying above it')
state.starterClaimed=true
assert(not Input.shouldClaim(state,{x=Config.BuyPads['1'],y=3,z=Config.BuyZ},Config),'Never auto-buy a paid producer')
state.producers={{speciesId='tier_01'},{speciesId='tier_01'}}
assert(Tutorial.goal(state).kind~='Merge','Two matching Brainrots must not trigger the three-to-one tutorial')
table.insert(state.producers,{speciesId='tier_02'})
assert(Tutorial.goal(state).kind~='Merge','Different species cannot complete a matching triple')
table.insert(state.producers,{speciesId='tier_01'})
local merge=Tutorial.goal(state)
assert(merge.kind=='Merge' and merge.title=='Merge three matching Brainrots!')
assert(merge.detail=='Walk onto MERGE. Three matching Brainrots become one!')
local maxId=string.format('tier_%02d',Config.MaxTier)
state.producers={{speciesId=maxId},{speciesId=maxId},{speciesId=maxId}}
assert(Tutorial.goal(state).kind~='Merge','Max-tier triples must not prompt an impossible merge')
state.producers={{speciesId='tier_01'},{speciesId='tier_01'}}
state.coinUnits=1000
assert(Tutorial.goal(state).kind=='Buy' and Tutorial.goal(state).detail:find('three matching Brainrots',1,true),
    'A player with only a pair must be guided to obtain a third match')
print('PASS starter bounds and one-time claim; tutorial matching triples, pair/max-tier rejection and third-match purchase guidance')
