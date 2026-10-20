local Core=require('../src/server/Domain/FarmCore')
local Config=require('../src/shared/Config')
local Catalog=require('../src/shared/CreatureCatalog')
local core=Core.new(Config,Catalog)
local pads={
    {action='Deposit',x=Config.SellX,z=Config.SellZ,hx=9.35,hz=5.35},
    {action='Claim',x=Config.ClaimX,z=Config.ClaimZ,hx=7.85,hz=5.35},
    {action='Upgrade',x=Config.UpgradeX,z=Config.UpgradeZ,hx=5.85,hz=3.85},
    {action='AutoMerge',x=Config.MergeX,z=Config.MergeZ,hx=5.35,hz=3.85},
}
for quantity,x in Config.BuyPads do table.insert(pads,{action='Buy',quantity=quantity,x=x,z=Config.BuyZ,hx=5.35,hz=3.85}) end
local function attempt(pad,dx,y,dz)
    local s=core:newSession(1,0,'pad')
    s.state.coinUnits=1000000;s.state.soldUnits=40;s.state.rebirths=3;s.state.starterClaimed=true
    s.state.producers={{id='a',speciesId='tier_01',slot=1,due=1},{id='b',speciesId='tier_01',slot=2,due=1}}
    s.state.bag={{speciesId='tier_01',baseCoinValue=2,count=1}}
    return core:dispatch(s,pad.action,if pad.quantity then {'edge',pad.quantity} else {'edge'},
        {now=0,alive=true,position={x=pad.x+dx,y=y,z=pad.z+dz}})
end
for _,pad in pads do
    for _,xSign in {-1,1} do for _,zSign in {-1,1} do
        for _,height in {0,7} do
            local result=attempt(pad,xSign*pad.hx,height,zSign*pad.hz)
            assert(result.code=='OK',pad.action..' full corner must work: '..result.code)
        end
    end end
    for _,sign in {-1,1} do
        assert(attempt(pad,sign*(pad.hx+.01),0,0).code=='TooFar',pad.action..' outside side must reject')
        assert(attempt(pad,0,0,sign*(pad.hz+.01)).code=='TooFar',pad.action..' outside end must reject')
    end
    assert(attempt(pad,0,7.01,0).code=='TooFar' and attempt(pad,0,-.11,0).code=='TooFar')
end
print('PASS entire pad corners, inclusive edges, outside footprint and height limits')
