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
print('PASS walk-on starter purchase intent, bounds and one-time claim')
