--!strict
-- Let an already approaching avatar's next physics packet arrive before the
-- first domain dispatch. This changes response timing, never valid footprints.
local env: any=getfenv()
local Geometry: any
if env.script then Geometry=(require :: any)(env.game:GetService('ReplicatedStorage').Shared.PadGeometry)
else Geometry=require('../../shared/PadGeometry') end
local EntryWait={}
function EntryWait.resolve(config: any,action: string,args: any,initial: any,
    read: () -> any,pause: (number) -> (),clock: () -> number): any
    local quantity=if type(args)=='table' and type(args[2])=='string' then args[2] else nil
    local function approaching(context: any): boolean
        return context.alive and context.position~=nil and context.padVelocity~=nil
            and Geometry.canAwaitEntry(config,action,context.position,context.padVelocity,quantity)
    end
    if action=='Buy' and (not quantity or config.BuyPads[quantity]==nil) then return initial end
    if not approaching(initial) then return initial end
    local deadline=clock()+.25
    local current=initial
    while clock()<deadline do
        pause(math.min(.025,deadline-clock()))
        current=read()
        if not current.alive or not current.position
            or Geometry.contains(config,action,current.position,quantity)
            or not approaching(current) then break end
    end
    return current
end
return table.freeze(EntryWait)
