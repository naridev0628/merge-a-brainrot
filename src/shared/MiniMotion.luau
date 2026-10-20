--!strict
-- Logical trajectory shared by authoritative pickup and the visible conveyor.
local Motion={}
export type Position={x: number,y: number,z: number}
function Motion.progress(now: number,spawnedAt: number,readyAt: number): number?
    if now<spawnedAt then return nil end
    if now>=readyAt then return 1 end
    return math.clamp((now-spawnedAt)/math.max(.01,readyAt-spawnedAt),0,1)
end
function Motion.phase(t: number): (number,number,number)
    if t<.22 then return 1,(t/.22)^2,0 end
    if t<.77 then return 2,(t-.22)/.55,0 end
    if t<1 then
        local arc=(t-.77)/.23
        return 3,arc,math.sin(arc*math.pi)*3
    end
    return 4,1,0
end
function Motion.position(config: any,token: any,now: number): Position?
    local t=Motion.progress(now,token.spawnedAt,token.readyAt)
    if not t then return nil end
    local phase,alpha,lift=Motion.phase(t)
    if phase==4 then return {x=token.x,y=token.y,z=token.z} end
    local drop={x=token.startX,y=1.4+math.abs(token.startX)*.032,z=config.BeltZ}
    local center={x=0,y=.75,z=config.BeltZ}
    local from: Position
    local target: Position
    if phase==1 then
        from={x=token.startX,y=token.startY,z=token.startZ};target=drop
    elseif phase==2 then
        from=drop;target=center
    else
        from=center;target={x=token.x,y=token.y,z=token.z}
    end
    return {x=from.x+(target.x-from.x)*alpha,y=from.y+(target.y-from.y)*alpha+lift,z=from.z+(target.z-from.z)*alpha}
end
return Motion
