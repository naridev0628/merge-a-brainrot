--!strict
-- Outbound envelope only: nested tables borrow the committed Core state.
-- Do not mutate them or use this packet as a transaction candidate; Core.snapshot
-- remains the deep-copy API. Core commits replace state instead of mutating it.
-- Build and FireClient must stay adjacent without a yield. Roblox copies remote
-- table arguments: https://create.roblox.com/docs/scripting/events/remote#table-identities
local Packet={}

function Packet.build(session: any,world: any,now: number,obbyState: any): any
    local state=table.clone(session.state)
    state.status=session.phase
    state.memoryOnly=true
    state.serverNow=now
    state.plotId=world.id
    state.plotCFrame=world.frame
    state.sessionKey=session.key
    state.timePlayed=math.floor(now-(session.joinedAt or now))
    state.obby=obbyState
    return state
end

return table.freeze(Packet)
