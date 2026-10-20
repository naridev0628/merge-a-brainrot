local Index=require('../src/shared/MiniNeighborIndex')

local index=Index.new(2)
index:insert('center',0,0,0)
index:insert('inside-negative',-.1,-.1,-.1)
index:insert('edge',2,0,0)
index:insert('outside',2.01,0,0)
index:insert('distant-farm',200,0,0)
local found,checks=index:query(0,0,0,2)
local seen={}
for _,value in found do seen[value]=true end
assert(seen.center and seen['inside-negative'],'Query lost neighbors across a negative cell boundary')
assert(not seen.edge and not seen.outside,'Jostle radius must retain its strict boundary')
assert(not seen['distant-farm'] and checks<5,'Other farms must not be scanned')
-- A radius larger than the cell size must still search every intersecting cell.
found=index:query(0,0,0,3)
assert(#found==4,'A wide search omitted a neighboring cell')

-- Explicit co-located values must not overwrite one another.
index:insert('same-position',0,0,0)
found=index:query(0,0,0,.01)
assert(#found==2,'Distinct Minis at the same position must each remain in the index')

-- Compare actual neighborhood membership against an independent brute-force
-- distance check over six separated farms and several pile layers.
for _,perFarm in {50,100,200} do
    local grid=Index.new(2)
    local points={}
    for farm=1,6 do
        for slot=1,perFarm do
            local within=(slot-1)%24
            local p={id=(farm-1)*perFarm+slot,
                x=farm*200+(within%6)*1.625,
                y=math.floor((slot-1)/24)*1.3,
                z=math.floor(within/6)*1.625}
            points[p.id]=p
            grid:insert(p.id,p.x,p.y,p.z)
        end
    end
    local comparisons=0
    for _,p in points do
        local neighbors,visited=grid:query(p.x,p.y,p.z,1.95)
        comparisons+=visited
        local actual={}
        for _,id in neighbors do
            assert(not actual[id],'A neighbor appeared twice')
            actual[id]=true
        end
        for _,candidate in points do
            local dx,dy,dz=p.x-candidate.x,p.y-candidate.y,p.z-candidate.z
            local expected=math.sqrt(dx*dx+dy*dy+dz*dz)<1.95
            assert(actual[candidate.id]==(if expected then true else nil),'Spatial bucket changed jostle membership')
        end
    end
    local brute=#points*#points
    assert(comparisons<brute*.25,'Neighbor optimization must eliminate at least 75% of cross-farm candidate checks')
    print(string.format('PASS %d Minis: %d spatial checks versus %d full-scan checks (%.1f%% fewer)',
        #points,comparisons,brute,100*(1-comparisons/brute)))
end
print('PASS exact neighbor membership, negative cells, strict radius, large queries and co-located Minis')
