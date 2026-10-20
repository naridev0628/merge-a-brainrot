--!strict
-- Coordinates and radius are in the same unscaled plot space on both peers.
local PickupGeometry={}
type Position={x: number,y: number,z: number}
function PickupGeometry.contains(center: Position,target: Position,radius: number): boolean
    local dx,dy,dz=target.x-center.x,target.y-center.y,target.z-center.z
    return dx*dx+dy*dy+dz*dz<=radius*radius
end
return table.freeze(PickupGeometry)
