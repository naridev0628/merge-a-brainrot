--!strict
-- Pure containment for axis-aligned square studs beneath opaque, level covers.
-- A stud must fit inside one complete cover; partial overlaps remain visible.
export type Cover = {
    kind: 'circle',x: number,z: number,radius: number,bottom: number,top: number,
} | {
    kind: 'box',x: number,z: number,halfX: number,halfZ: number,
    rightX: number,rightZ: number,bottom: number,top: number,
}
local Occlusion={}

function Occlusion.isFullyCovered(x: number,z: number,width: number,bottom: number,top: number,covers: {Cover}): boolean
    local half=width/2
    for _,cover in covers do
        if bottom<cover.bottom or top>cover.top then continue end
        local dx,dz=x-cover.x,z-cover.z
        if cover.kind=='circle' then
            -- The furthest square corner must fit in the circular footprint.
            local farX,farZ=math.abs(dx)+half,math.abs(dz)+half
            if farX*farX+farZ*farZ<=cover.radius*cover.radius then return true end
        else
            local localX=dx*cover.rightX+dz*cover.rightZ
            local localZ=-dx*cover.rightZ+dz*cover.rightX
            local extent=half*(math.abs(cover.rightX)+math.abs(cover.rightZ))
            if math.abs(localX)+extent<=cover.halfX and math.abs(localZ)+extent<=cover.halfZ then return true end
        end
    end
    return false
end

return table.freeze(Occlusion)
