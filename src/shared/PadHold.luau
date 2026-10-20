--!strict
local PadHold={}
type State={key: string?,enteredAt: number,lastSent: number?,retryAt: number?,stopped: boolean}
function PadHold.new(): State return {key=nil,enteredAt=0,lastSent=nil,retryAt=nil,stopped=false} end
function PadHold.update(state: State,key: string?,now: number)
    if state.key~=key then state.key=key;state.enteredAt=now;state.lastSent=nil;state.retryAt=nil;state.stopped=false end
end
function PadHold.ready(state: State,now: number): boolean
    if not state.key or state.stopped then return false end
    if state.retryAt then return now>=state.retryAt end
    -- Entry is immediate. Holding repeats at a deliberate pace after two seconds.
    return state.lastSent==nil or (now-state.enteredAt>=2 and now-state.lastSent>=.5)
end
function PadHold.sent(state: State,now: number) state.lastSent=now;state.retryAt=nil end
function PadHold.retry(state: State,now: number)
    -- Position replication can lag entry. Respect the slowest pad request budget.
    state.retryAt=now+.5
end
function PadHold.stop(state: State) state.stopped=true;state.retryAt=nil end
return table.freeze(PadHold)
