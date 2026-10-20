--!strict
-- Presentation-only interpolation. The server quantity is never changed.
local Counter={}
Counter.__index=Counter
Counter.Duration=.8
function Counter.new(): any
    return setmetatable({value=0,target=0,from=0,started=0,initialized=false},Counter)
end
function Counter.read(self: any,now: number): number
    local progress=math.clamp((now-self.started)/Counter.Duration,0,1)
    self.value=if progress>=1 then self.target else self.from+(self.target-self.from)*(1-(1-progress)^2)
    return math.floor(self.value)
end
function Counter.set(self: any,value: number,now: number)
    if self.initialized and value==self.target then return end
    if not self.initialized or value<self.target then
        self.value=value;self.from=value;self.target=value;self.started=now-Counter.Duration;self.initialized=true
        return
    end
    self:read(now)
    self.from=self.value;self.target=value;self.started=now
end
return table.freeze(Counter)
