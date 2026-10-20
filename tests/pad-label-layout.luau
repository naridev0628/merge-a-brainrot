local Layout=require('../src/shared/PadLabelLayout')
local function candidate(key,x,y,distance,priority,near)
    return {key=key,x=x,y=y,width=180,height=102,distance=distance,priority=priority or 1,near=near or false}
end
local function separate(a,b,gap)
    return a.x+a.width+gap<=b.x or b.x+b.width+gap<=a.x
        or a.y+a.height+gap<=b.y or b.y+b.height+gap<=a.y
end
local function verify(items,result)
    local visible={}
    for _,item in items do
        local value=result[item.key]
        assert(value,'Every candidate must receive an explicit result')
        if value.visible then
            assert(value.scale>=.58 and value.scale<=1,'Text must stay within readable bounded scale')
            if item.near then assert(value.scale==1,'A nearby action must keep full size') end
            assert(math.abs(value.rect.x+value.rect.width/2-item.x)<1e-6,'Do not move a price away from its physical pad')
            for _,other in visible do assert(separate(value.rect,other,3.999),'Visible labels must not collide') end
            table.insert(visible,value.rect)
        end
    end
end
local near={candidate('Buy1',300,200,12,1,true)}
local output=Layout.solve(near,{})
verify(near,output)
assert(output.Buy1.scale==1)
local farther={candidate('Buy1',300,200,50)}
local far=Layout.solve(farther,{})
assert(far.Buy1.scale<output.Buy1.scale,'Distant fixed-pixel labels must shrink')
-- Hand-measured spawn screenshot: adjacent Buy5/Auto Collect/Buy10 centers
-- are about 120 pixels apart; all three can fit above the .58 readable floor.
local row={candidate('Buy5',760,220,36),candidate('Pass_autoCollect',880,220,36,3),candidate('Buy10',1000,220,36)}
output=Layout.solve(row,{})
verify(row,output)
for _,item in row do assert(output[item.key].visible,'Shrink before hiding a price that can fit') end
-- A perspective-compressed offer cannot steal the nearest action's space.
local packed={candidate('Buy1',300,200,18,1,true),candidate('Pass_autoCollect',340,200,45,3)}
output=Layout.solve(packed,{})
verify(packed,output)
assert(output.Buy1.visible and not output.Pass_autoCollect.visible)
-- Input order must not alter the stable key/priority policy.
local reverse={packed[2],packed[1]}
local reordered=Layout.solve(reverse,{})
assert(reordered.Buy1.visible and not reordered.Pass_autoCollect.visible)
local same={candidate('Buy5',300,200,40),candidate('Buy10',300,200,40)}
output=Layout.solve(same,{})
local again=Layout.solve({same[2],same[1]},{})
assert(output.Buy5.visible==again.Buy5.visible and output.Buy10.visible==again.Buy10.visible)
-- Once crowded out, a label requires extra clearance before reappearing.
local edge={candidate('Buy1',300,200,50),candidate('Pass_autoCollect',410,200,50,3)}
local stable=Layout.solve(edge,{Pass_autoCollect=false})
assert(not stable.Pass_autoCollect.visible,'Do not flash at the 4-pixel collision boundary')
edge[2].x=420
stable=Layout.solve(edge,{Pass_autoCollect=false})
assert(stable.Pass_autoCollect.visible,'Restore after the wider reappearance margin clears')
verify(edge,stable)
-- Vertical separation is valid; oblique/short views must remain bounded.
for _,spacing in {0,60,108,120,200} do
    local items={}
    for i=1,15 do table.insert(items,candidate('pad'..i,100+(i%5)*spacing,100+math.floor(i/5)*80,20+i*3,i%3+1,i==1)) end
    verify(items,Layout.solve(items,{}))
end
print('PASS pad label near readability, distance scaling, shrink-before-hide, anchored prices, deterministic priority and visibility hysteresis')
