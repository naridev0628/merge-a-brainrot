--!strict
-- Logical footprints match the complete rendered pad surfaces, including corners.
local PadGeometry={}
local halfSizes: {[string]: {number}}={Deposit={9,5},Claim={7.5,5},AutoMerge={5,3.5},Upgrade={5.5,3.5},Buy={5,3.5}}
-- WorldBuilder adds .7 to each base dimension; include that visible .35 rim per side.
local baseOverhang=.35
local edgeEpsilon=1e-4 -- Preserve inclusive edges through plot CFrame roundoff.
type Position={x: number,y: number,z: number}
type Bounds={x: number,z: number,hx: number,hz: number}
local function bounds(config: any,action: string,quantity: string?): Bounds?
    local half=halfSizes[action]
    if not half then return nil end
    local x,z
    if action=='Deposit' then x,z=config.SellX,config.SellZ
    elseif action=='Claim' then x,z=config.ClaimX,config.ClaimZ
    elseif action=='AutoMerge' then x,z=config.MergeX,config.MergeZ
    elseif action=='Upgrade' then x,z=config.UpgradeX,config.UpgradeZ
    else x,z=config.BuyPads[quantity or '1'],config.BuyZ end
    if type(x)~='number' then return nil end
    return {x=x+(config.OriginX or 0),z=z,hx=half[1]+baseOverhang,hz=half[2]+baseOverhang}
end
function PadGeometry.contains(config: any,action: string,position: Position,quantity: string?): boolean
    local pad=bounds(config,action,quantity)
    if not pad then return false end
    return math.abs(position.x-pad.x)<=pad.hx+edgeEpsilon
        and math.abs(position.z-pad.z)<=pad.hz+edgeEpsilon and position.y>=-.1 and position.y<=7
end
-- Eligibility for a short server-side recheck, never permission to transact.
-- Initial acceleration can replicate before the matching position packet. Keep
-- the request pending only near this exact pad and while moving toward its edge.
function PadGeometry.canAwaitEntry(config: any,action: string,position: Position,velocity: Position,quantity: string?): boolean
    local pad=bounds(config,action,quantity)
    if not pad or position.y<-.1 or position.y>7 then return false end
    local dx=math.clamp(position.x,pad.x-pad.hx,pad.x+pad.hx)-position.x
    local dz=math.clamp(position.z,pad.z-pad.hz,pad.z+pad.hz)-position.z
    local distance=math.sqrt(dx*dx+dz*dz)
    local speed=math.sqrt(velocity.x*velocity.x+velocity.z*velocity.z)
    return distance>edgeEpsilon and distance<=4/(config.PlotScale or 1) and speed>=.01
        and (dx*velocity.x+dz*velocity.z)/(distance*speed)>=.75
end
-- Called only with server-observed position and velocity. A walking avatar can
-- lag its entry RemoteEvent by ~200 ms in measured Studio walks. Bridge up to
-- 250 ms of movement, capped at four world studs, only toward the surface edge.
function PadGeometry.entryPosition(config: any,action: string,position: Position,velocity: Position,quantity: string?): Position
    local pad=bounds(config,action,quantity)
    if not pad or position.y<-.1 or position.y>7 then return position end
    local x=math.clamp(position.x,pad.x-pad.hx,pad.x+pad.hx)
    local z=math.clamp(position.z,pad.z-pad.hz,pad.z+pad.hz)
    local dx,dz=x-position.x,z-position.z
    local distance=math.sqrt(dx*dx+dz*dz)
    local speed=math.sqrt(velocity.x*velocity.x+velocity.z*velocity.z)
    local reach=math.min(speed*.25,4/(config.PlotScale or 1))
    if distance<=edgeEpsilon or distance>reach or speed<.01 then return position end
    if (dx*velocity.x+dz*velocity.z)/(distance*speed)<.75 then return position end
    return {x=x,y=position.y,z=z}
end
return table.freeze(PadGeometry)
