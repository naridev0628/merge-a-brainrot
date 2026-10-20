--!strict
-- Logical footprints match the complete rendered pad surfaces, including corners.
local PadGeometry={}
local halfSizes: {[string]: {number}}={Deposit={9,5},Claim={7.5,5},AutoMerge={5,3.5},Upgrade={5.5,3.5},Buy={5,3.5}}
-- WorldBuilder adds .7 to each base dimension; include that visible .35 rim per side.
local baseOverhang=.35
local edgeEpsilon=1e-4 -- Preserve inclusive edges through plot CFrame roundoff.
type Position={x: number,y: number,z: number}
function PadGeometry.contains(config: any,action: string,position: Position,quantity: string?): boolean
    local half=halfSizes[action]
    if not half then return false end
    local x,z
    if action=='Deposit' then x,z=config.SellX,config.SellZ
    elseif action=='Claim' then x,z=config.ClaimX,config.ClaimZ
    elseif action=='AutoMerge' then x,z=config.MergeX,config.MergeZ
    elseif action=='Upgrade' then x,z=config.UpgradeX,config.UpgradeZ
    else x,z=config.BuyPads[quantity or '1'],config.BuyZ end
    if type(x)~='number' then return false end
    return math.abs(position.x-(x+(config.OriginX or 0)))<=half[1]+baseOverhang+edgeEpsilon
        and math.abs(position.z-z)<=half[2]+baseOverhang+edgeEpsilon and position.y>=-.1 and position.y<=7
end
return table.freeze(PadGeometry)
