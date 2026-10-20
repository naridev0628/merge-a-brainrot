local Motion=require('../src/shared/MiniMotion')
local Config=require('../src/shared/Config')
local Core=require('../src/server/Domain/FarmCore')
local Catalog=require('../src/shared/CreatureCatalog')
assert(type(Motion.beltHeight)=='function' and type(Motion.slideYOffset)=='function',
    'The domain, server attributes and client must share the curved belt trajectory')
local precise=table.clone(Config);precise.PickupRadius=.0001
local core=Core.new(precise,Catalog,function() return 1 end)
for _,startX in {-45,-25,-5,5,25,45} do
    for sample=0,20 do
        local alpha=sample/20
        local x=startX*(1-alpha)
        local dropY,centerY=Motion.beltHeight(startX),Motion.beltHeight(0)
        local clientY=dropY+(centerY-dropY)*alpha+Motion.slideYOffset(math.abs(startX),alpha)
        local token={id='curve',owner=1,origin='producer',speciesId='tier_01',baseCoinValue=1,count=1,
            startX=startX,startY=30,startZ=Config.DisplayZ,x=0,y=1.3,z=Config.TrayZ,spawnedAt=10,readyAt=14}
        local now=10+(.22+.55*alpha)*4
        local position=Motion.position(Config,token,now)
        assert(math.abs(position.x-x)<1e-8 and math.abs(position.y-clientY)<1e-8,
            'Authoritative pickup and rendered motion must use exactly the same curve')
        -- Physical belt facets join samples of .95 + .0004*x^2, with a .175 half-thickness.
        local distance=math.abs(x)
        local top=1.15
        if distance>7 then
            local inner=7+math.min(3,math.floor((distance-7)/11))*11
            local outer=inner+11
            top=.95+.0004*(inner*inner+(outer*outer-inner*inner)*(distance-inner)/11)+.175
        end
        assert(clientY-top>.3,'Moving Mini centers must stay above the actual red belt facets')
        local session=core:newSession(1,0,'curve')
        session.state.tokens={token}
        assert(core:dispatch(session,'CollectNearby',{'pick'},{now=now,alive=true,
            position=position,pickupPosition={x=x,y=clientY,z=Config.BeltZ}}).code=='OK',
            'A precision pickup at the visible curved slide position must succeed')
    end
end
assert(Motion.slideYOffset(45,0)==0 and Motion.slideYOffset(45,1)==0,'Curve joins cannot jump')
print('PASS curved belt clearance, phase joins and precise server/client pickup alignment across both lanes')
