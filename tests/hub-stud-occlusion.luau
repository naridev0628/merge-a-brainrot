local Occlusion=require('../src/shared/HubStudOcclusion')

local circle={kind='circle',x=0,z=0,radius=5,bottom=0,top=.3}
local box={kind='box',x=10,z=20,halfX=2,halfZ=4,rightX=1,rightZ=0,bottom=-.02,top=.18}
assert(Occlusion.isFullyCovered(0,0,1,0,.14,{circle}))
assert(not Occlusion.isFullyCovered(4.6,0,1,0,.14,{circle}),'Keep a stud whose center is inside but corner crosses the circle')
assert(not Occlusion.isFullyCovered(0,0,1,-.001,.14,{circle}),'The whole stud must be above the cover bottom')
assert(not Occlusion.isFullyCovered(0,0,1,0,.301,{circle}),'The whole stud must be below the cover top')
assert(Occlusion.isFullyCovered(11.5,23.5,1,0,.14,{box}),'An exactly contained boundary is covered')
assert(not Occlusion.isFullyCovered(11.50001,23.5,1,0,.14,{box}),'Keep a partial rectangular-edge stud')
assert(not Occlusion.isFullyCovered(10,20,1,0,.181,{box}))
assert(not Occlusion.isFullyCovered(0,0,1,0,.14,{}))
local rotated={kind='box',x=0,z=0,halfX=1,halfZ=5,rightX=math.sqrt(.5),rightZ=math.sqrt(.5),bottom=0,top=1}
assert(Occlusion.isFullyCovered(0,0,1,0,.14,{rotated}))
assert(not Occlusion.isFullyCovered(.3,.3,1,0,.14,{rotated}),'Rotated edge checks must include the square footprint')
assert(not Occlusion.isFullyCovered(0,0,1,0,.14,{
    {kind='box',x=-.25,z=0,halfX=.25,halfZ=1,rightX=1,rightZ=0,bottom=0,top=1},
    {kind='box',x=.25,z=0,halfX=.25,halfZ=1,rightX=1,rightZ=0,bottom=0,top=1},
}),'Conservatively keep studs spanning multiple covers')

-- Independent eight-corner oracle; no support-radius shortcut from the helper.
local function oracle(x,z,width,bottom,top,covers)
    for _,cover in covers do
        local inside=true
        for _,dx in {-width/2,width/2} do for _,dz in {-width/2,width/2} do for _,y in {bottom,top} do
            local px,pz=x+dx-cover.x,z+dz-cover.z
            if y<cover.bottom or y>cover.top then inside=false end
            if cover.kind=='circle' then
                if px*px+pz*pz>cover.radius*cover.radius then inside=false end
            else
                local u=px*cover.rightX+pz*cover.rightZ
                local v=-px*cover.rightZ+pz*cover.rightX
                if math.abs(u)>cover.halfX or math.abs(v)>cover.halfZ then inside=false end
            end
        end end end
        if inside then return true end
    end
    return false
end
local covers={{kind='circle',x=0,z=0,radius=34,bottom=0,top=.3}}
for sector=0,5 do
    local angle=sector*math.pi/3
    table.insert(covers,{kind='box',x=math.sin(angle)*65,z=math.cos(angle)*65,
        halfX=7,halfZ=31,rightX=math.cos(angle),rightZ=-math.sin(angle),bottom=-.02,top=.18})
end
local radius=96
local a=radius*(math.sqrt(2)-1)
local pitch,width=radius/25,.55
local limit=math.floor((radius-width)/pitch)
local before,culled,kept=0,0,0
for ix=-limit,limit do for iz=-limit,limit do
    local x,z=ix*pitch,iz*pitch
    if math.abs(x)+math.abs(z)+width<=radius+a then
        before+=1
        local covered=Occlusion.isFullyCovered(x,z,width,0,.14,covers)
        assert(covered==oracle(x,z,width,0,.14,covers),'Occlusion differs from the independent eight-corner oracle')
        if covered then culled+=1 else kept+=1 end
    end
end end
assert(before==2037 and culled==557 and kept==1480,'Current hub count changed unexpectedly')
-- Exercise partial edges for different widths and shifted positions as well.
for ix=-16,16 do for iz=-16,16 do for _,width2 in {.1,.55,1.7} do
    local x,z=ix*.4+.07,iz*.4-.13
    assert(Occlusion.isFullyCovered(x,z,width2,0,.14,{circle,rotated})
        ==oracle(x,z,width2,0,.14,{circle,rotated}))
end end end
print('PASS hub stud containment: independent corner oracle; 2037 -> 1480, 557 fully hidden studs culled; partial/rotated/vertical boundaries retained')
