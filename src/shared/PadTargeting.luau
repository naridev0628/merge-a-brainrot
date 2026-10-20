--!strict
-- Pure client targeting: full pad footprints own actions; nearby labels supply context.
local env: any=getfenv()
local PadGeometry: any
if env.script then PadGeometry=(require :: any)(env.script.Parent.PadGeometry) else PadGeometry=require('./PadGeometry') end
local Targeting={}
type Position={x: number,y: number,z: number}
export type Target={key: string?,action: string?,values: {string}?,kind: string?,value: string}

function Targeting.resolve(config: any,catalog: any,map: any,state: any,position: Position): Target
    local target: Target={key=nil,action=nil,values=nil,kind=nil,value='1'}
    local function onPad(action: string,quantity: string?): boolean
        return PadGeometry.contains(config,action,position,quantity)
    end
    if onPad('Deposit') then
        target.key='Deposit'
        if #state.bag>0 then target.action='Deposit' end
    elseif onPad('Claim') then
        target.key='Claim'
        if state.soldUnits>0 then target.action='Claim' end
    elseif onPad('AutoMerge') then
        target.key='AutoMerge'
        local seen: {[string]: boolean}={}
        for _,producer in state.producers do
            if catalog[producer.speciesId].nextId then
                if seen[producer.speciesId] then target.action='AutoMerge'; break end
                seen[producer.speciesId]=true
            end
        end
    elseif onPad('Upgrade') then target.key='Upgrade'; target.action='Upgrade'
    else
        for quantity in config.BuyPads do
            if onPad('Buy',quantity) then
                target.key='Buy'..quantity; target.action='Buy'; target.values={quantity}; break
            end
        end
    end

    local nearest=config.PadDistance
    local function consider(kind: string,x: number,y: number,z: number,value: string?)
        local distance=math.sqrt((position.x-x)^2+(position.y-y)^2+(position.z-z)^2)
        if distance<nearest then nearest=distance; target.kind=kind; target.value=value or '1' end
    end
    for _,entry in {{'Deposit',map.Sell},{'Claim',map.Claim},{'Merge',map.Merge},{'Upgrade',map.Upgrade},{'FinishNow',map.FinishNow}} do
        local point=entry[2]
        consider(entry[1],point.X,point.Y,point.Z)
    end
    for quantity,x in config.BuyPads do consider('Buy',x,.15,config.BuyZ,quantity) end
    for key,point in map.PassPads do consider('Pass',point.X,point.Y,point.Z,key) end

    -- Corners can be farther from their label than a nearby offer: the surface still wins.
    if target.key then
        target.kind=if target.key=='AutoMerge' then 'Merge' elseif target.action=='Buy' then 'Buy' else target.key
        target.value=if target.values then target.values[1] else '1'
    end
    return target
end

return table.freeze(Targeting)
