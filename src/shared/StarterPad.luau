--!strict
local Starter={}
function Starter.shouldClaim(state: any,position: {x: number,y: number,z: number},config: any): boolean
    return not state.starterClaimed and math.abs(position.x-config.BuyPads['1'])<=5
        and math.abs(position.z-config.BuyZ)<=3.5 and position.y>=-.1 and position.y<=7
end
return Starter
