--!strict
-- A short-lived index of landed Mini centers. Rebuilt only on an arrival frame,
-- so repacking and removed models cannot leave stale spatial entries behind.
local Index={}
Index.__index=Index
type Entry={value: any,x: number,y: number,z: number}
type Buckets={[number]: {[number]: {[number]: {Entry}}}}
function Index.new(cellSize: number)
    assert(cellSize>0 and cellSize<math.huge,'Cell size must be positive and finite')
    return setmetatable({cellSize=cellSize,buckets={} :: Buckets},Index)
end
function Index.insert(self: any,value: any,x: number,y: number,z: number)
    local size=self.cellSize
    local ix,iy,iz=math.floor(x/size),math.floor(y/size),math.floor(z/size)
    local column=self.buckets[ix]
    if not column then column={};self.buckets[ix]=column end
    local row=column[iy]
    if not row then row={};column[iy]=row end
    local bucket=row[iz]
    if not bucket then bucket={};row[iz]=bucket end
    table.insert(bucket,{value=value,x=x,y=y,z=z})
end
function Index.query(self: any,x: number,y: number,z: number,radius: number): ({any},number)
    assert(radius>=0 and radius<math.huge,'Radius must be nonnegative and finite')
    local size=self.cellSize
    local squaredRadius=radius*radius
    local result={}
    local checked=0
    for ix=math.floor((x-radius)/size),math.floor((x+radius)/size) do
        local column=self.buckets[ix]
        if not column then continue end
        for iy=math.floor((y-radius)/size),math.floor((y+radius)/size) do
            local row=column[iy]
            if not row then continue end
            for iz=math.floor((z-radius)/size),math.floor((z+radius)/size) do
                local bucket=row[iz]
                if not bucket then continue end
                for _,entry in bucket do
                    checked+=1
                    local dx,dy,dz=entry.x-x,entry.y-y,entry.z-z
                    if dx*dx+dy*dy+dz*dz<squaredRadius then table.insert(result,entry.value) end
                end
            end
        end
    end
    return result,checked
end
return table.freeze(Index)
