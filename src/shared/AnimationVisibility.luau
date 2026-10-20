--!strict
-- Pure, conservative whole-farm animation scheduling. These are client visual
-- budgets only; no token positions, pickup rules or production clocks change.
local Visibility={}
Visibility.Interval=1/15
Visibility.NearDistance=50
Visibility.VisibleDistance=180
Visibility.AngularPadding=10
local function finite(value: any): boolean
    return type(value)=='number' and value==value and math.abs(value)<math.huge
end
function Visibility.bounds(config: any): any
    local halfWidth=((config.Columns-1)*config.ColumnSpacing/2)+10
    local top=config.DisplayPlatformHeight+(math.ceil(config.Slots/config.Columns)-1)*config.RowHeight+14
    local back=math.max(config.DisplayZ+10,config.BeltZ+10)
    local front=config.TrayZ-10
    local halfDepth=(back-front)/2
    local scale=config.PlotScale
    return {x=config.OriginX*scale,y=top/2*scale,z=(back+front)/2*scale,
        radius=math.sqrt(halfWidth^2+(top/2)^2+halfDepth^2)*scale}
end
-- Camera-space sphere: depth points forward. Tangent includes angular padding
-- and aspect is viewport width/height. Missing/invalid camera data fails open.
function Visibility.fullRate(view: any): boolean
    if type(view)~='table' then return true end
    for _,key in {'x','y','depth','radius','tangent','aspect'} do
        if not finite(view[key]) then return true end
    end
    if view.radius<0 or view.tangent<=0 or view.aspect<=0 then return true end
    local distanceSquared=view.x^2+view.y^2+view.depth^2
    if distanceSquared<=(view.radius+Visibility.NearDistance)^2 then return true end
    if distanceSquared>(view.radius+Visibility.VisibleDistance)^2 then return false end
    if view.depth< -view.radius then return false end
    local horizontal=view.tangent*view.aspect
    return math.abs(view.x)<=view.depth*horizontal+view.radius*math.sqrt(1+horizontal^2)+1e-6
        and math.abs(view.y)<=view.depth*view.tangent+view.radius*math.sqrt(1+view.tangent^2)+1e-6
end
function Visibility.new(slot: number): any
    return {offset=(slot%4+1)/4}
end
function Visibility.shouldUpdate(state: any,now: number,fullRate: boolean): boolean
    if not finite(now) then state.nextUpdate=nil;state.lastNow=nil;return true end
    local backwards=state.lastNow~=nil and now<state.lastNow
    state.lastNow=now
    if fullRate or backwards then state.nextUpdate=nil;return true end
    if state.nextUpdate==nil then
        -- Update immediately on entry, then stagger the next four render frames.
        state.nextUpdate=now+Visibility.Interval*state.offset
        return true
    end
    if now+1e-7<state.nextUpdate then return false end
    -- Preserve cadence without replaying missed frames after a pause/hitch.
    local elapsed=math.max(0,now-state.nextUpdate)
    state.nextUpdate+=Visibility.Interval*(math.floor(elapsed/Visibility.Interval+1e-7)+1)
    return true
end
return table.freeze(Visibility)
