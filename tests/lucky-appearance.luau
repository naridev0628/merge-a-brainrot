local Appearance=require('../src/shared/LuckyAppearance')
local Core=require('../src/server/Domain/FarmCore')
local Config=require('../src/shared/Config')
local Catalog=require('../src/shared/CreatureCatalog')
local basic=Appearance.forTier(2)
local upgraded=Appearance.forTier(3)
assert(basic.key=='basic' and basic.title=='Basic')
assert(upgraded.key=='upgraded' and upgraded.title=='Upgraded')
for _,tier in {1,2} do assert(Appearance.forTier(tier)==basic) end
for tier=3,Config.MaxTier do assert(Appearance.forTier(tier)==upgraded) end
for _,tier in {0,-1,1.5,math.huge,0/0} do assert(Appearance.forTier(tier)==basic) end
assert(Appearance.forTier(nil)==basic)
assert(basic.body[1]>basic.body[3] and upgraded.body[3]>upgraded.body[1])
assert(table.isfrozen(basic) and table.isfrozen(upgraded) and table.isfrozen(upgraded.body))
assert(not pcall(function() upgraded.body[1]=255 end))
-- Exercise authoritative generation: the starter produces baseTier 2, not 1.
for producerTier=1,Config.MaxTier do
    local core=Core.new(Config,Catalog,function() return 0 end)
    local session=core:newSession(1,0,'appearance')
    local context={now=1,alive=true,position={x=Config.BuyPads['1'],y=3,z=Config.BuyZ}}
    assert(core:dispatch(session,'Buy',{'free'},context).code=='OK')
    session.state.producers[1].speciesId=string.format('tier_%02d',producerTier)
    core:step(session,12)
    local lucky=assert(session.state.lucky)
    assert(lucky.baseTier==math.min(Config.MaxTier-2,producerTier+1))
    assert(Appearance.forTier(lucky.baseTier)==(if producerTier==1 then basic else upgraded))
end
print('PASS Lucky appearance: real generated tier boundary, gold/blue palette, invalid-preview fallback and immutable descriptors')
