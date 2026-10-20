--!strict
-- Presentation only. Physical tokens include in-flight Minis, matching the
-- domain's reserved tray capacity; bag and processor quantities are separate.
export type Status={
    producerCount: number,tokenCount: number,spacesLeft: number,
    producersFull: boolean,trayFull: boolean,
}
local Capacity={}
function Capacity.inspect(config: any,state: any): Status
    local producers=#state.producers
    local tokens=#state.tokens
    return {
        producerCount=producers,tokenCount=tokens,
        spacesLeft=math.max(0,config.Slots-producers),
        producersFull=producers>=config.Slots,
        trayFull=tokens>=config.GroundCap,
    }
end
function Capacity.hint(config: any,state: any): string
    local status=Capacity.inspect(config,state)
    -- The buy action still explains a blocked purchase when both limits fill.
    if status.trayFull then return 'Tray full • Collect Minis' end
    if status.producersFull then return 'Merge to make room' end
    return tostring(status.spacesLeft)..(if status.spacesLeft==1 then ' space left' else ' spaces left')
end
return table.freeze(Capacity)
