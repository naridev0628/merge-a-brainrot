local Tutorial=require('../src/shared/Tutorial')
local Config=require('../src/shared/Config')
local Catalog=require('../src/shared/CreatureCatalog')
local state={tutorialStep=2,starterClaimed=true,producers={},purchased=0,coinUnits=0,soldUnits=0,saleQueue={},bag={}}
for id,species in Catalog do
 state.producers={{speciesId=id},{speciesId=id},{speciesId=id}}
 assert((Tutorial.goal(state).kind=='Merge')==(species.nextId~=nil),'Tutorial merge eligibility must follow catalog nextId for '..id)
end
state.tutorialStep=7
assert(string.find(Tutorial.goal(state).detail,tostring(Config.MaxTier),1,true),'Completed tutorial must advertise every available Brainrot')
print('PASS tutorial merge guidance across '..Config.MaxTier..' species and dynamic discovery count')
