--!strict
local PadHold={}
type State={key: string?,enteredAt: number,lastSent: number?,stopped: boolean}
function PadHold.new(): State return {key=nil,enteredAt=0,lastSent=nil,stopped=false} end
function PadHold.update(state: State,key: string?,now: number)
    if state.key~=key then state.key=key;state.enteredAt=now;state.lastSent=nil;state.stopped=false end
end
function PadHold.ready(state: State,now: number): boolean
    if not state.key or state.stopped then return false end
    return state.lastSent==nil or (now-state.enteredAt>=2-1e-7 and now-(state.lastSent :: number)>=.1-1e-7)
end
function PadHold.sent(state: State,now: number) state.lastSent=now end
function PadHold.stop(state: State) state.stopped=true end
return table.freeze(PadHold)
