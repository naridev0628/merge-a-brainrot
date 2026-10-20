--!strict
-- The stud's center and projected half extents are in the cover Part's space.
-- A whole volume must fit in one opaque brick; center-only coverage is unsafe.
local Occlusion={}
function Occlusion.isFullyInside(x: number,y: number,z: number,hx: number,hy: number,hz: number,
    width: number,height: number,depth: number): boolean
    -- CFrame/Part geometry uses floats; stacked faces can differ by a few
    -- millionths of a stud after translation. This is not an edge inset.
    local epsilon=1e-5
    return math.abs(x)+hx<=width/2+epsilon
        and math.abs(y)+hy<=height/2+epsilon
        and math.abs(z)+hz<=depth/2+epsilon
end
return table.freeze(Occlusion)
