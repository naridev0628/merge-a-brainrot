local Occlusion=require('../src/shared/BrickStudOcclusion')

assert(Occlusion.isFullyInside(0,0,0,.24,.07,.24,1,1,1),'An enclosed stud should be omitted')
assert(Occlusion.isFullyInside(.26,.43,.26,.24,.07,.24,1,1,1),'Exactly contained faces remain hidden')
assert(not Occlusion.isFullyInside(.2601,0,0,.24,.07,.24,1,1,1),'Keep a partly exposed side')
assert(not Occlusion.isFullyInside(0,.4301,0,.24,.07,.24,1,1,1),'Keep a protruding top')
assert(not Occlusion.isFullyInside(0,-.4301,0,.24,.07,.24,1,1,1),'Keep a protruding bottom')
assert(not Occlusion.isFullyInside(0,0,.2601,.24,.07,.24,1,1,1),'Keep a partly exposed depth edge')
assert(Occlusion.isFullyInside(0,-.2800006866455,0,.24,.07,.24,8.5,.699999988079,8.5),
    'Roblox float storage of adjoining roof faces must not defeat containment')

-- Independent corner enumeration catches center-only and incomplete-height checks.
local function oracle(x,y,z,hx,hy,hz,sx,sy,sz)
    for _,dx in {-hx,hx} do for _,dy in {-hy,hy} do for _,dz in {-hz,hz} do
        if x+dx < -sx/2-1e-5 or x+dx > sx/2+1e-5
            or y+dy < -sy/2-1e-5 or y+dy > sy/2+1e-5
            or z+dz < -sz/2-1e-5 or z+dz > sz/2+1e-5 then return false end
    end end end
    return true
end
for x=-7,7 do for y=-7,7 do for z=-7,7 do
    local px,py,pz=x*.1+.013,y*.1-.017,z*.1+.019
    assert(Occlusion.isFullyInside(px,py,pz,.24,.07,.24,1,1,1)
        ==oracle(px,py,pz,.24,.07,.24,1,1,1))
end end end

-- Each covering brick starts at the supporting brick's top. The literal counts
-- include thin exposed foundation edges and all exposed stepped roof borders.
local function hiddenTopStuds(width,coverWidth,coverHeight)
    local count=0
    local columns=math.max(1,math.floor(width/1.55))
    for ix=1,columns do for iz=1,columns do
        local x,z=(ix-(columns+1)/2)*1.55,(iz-(columns+1)/2)*1.55
        local y=.07-coverHeight/2
        local hidden=Occlusion.isFullyInside(x,y,z,.24,.07,.24,coverWidth,coverHeight,coverWidth)
        assert(hidden==oracle(x,y,z,.24,.07,.24,coverWidth,coverHeight,coverWidth))
        if hidden then count+=1 end
    end end
    return count
end
assert(hiddenTopStuds(10.6,8.2,3)==16,'Foundation outer studs project .015 studs beyond the red tower')
assert(hiddenTopStuds(8.2,8.7,1)==25)
assert(hiddenTopStuds(8.7,8.2,3)==25)
assert(hiddenTopStuds(8.7,10,.8)==25)
assert(hiddenTopStuds(10.3,8.5,.7)==36)
assert(hiddenTopStuds(8.5,6.5,.7)==9,'Keep the second roof step border')
assert(hiddenTopStuds(6.5,4.3,.7)==4,'Keep the third roof step border')
assert(hiddenTopStuds(4.3,.75,1.3)==0,'The top roof studs remain exposed around the finial')
local hidden=16+6*25+5*25+25+36+9+4
assert(hidden==365)
print('PASS full stud volume containment; thin foundation edges and roof borders preserved; 365 hidden lighthouse top studs')
