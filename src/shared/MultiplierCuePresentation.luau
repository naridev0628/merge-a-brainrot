--!strict
local Presentation={}
Presentation.__index=Presentation
Presentation.Duration=3
export type Rect={x: number,y: number,width: number,height: number}
local function finite(value: any): boolean
    return type(value)=='number' and value==value and value>=0 and value<=1e12
end
function Presentation.new(minimum: number,maximum: number): any
    return setmetatable({minimum=minimum,maximum=maximum,initialized=false,destroyed=false},Presentation)
end
function Presentation.receive(self: any,snapshot: any,receivedAt: number): boolean
    if self.destroyed or type(snapshot)~='table' or snapshot.status~='Ready'
        or type(snapshot.sessionKey)~='string' or not finite(snapshot.revision) or snapshot.revision%1~=0
        or not finite(snapshot.serverNow) or not finite(receivedAt) then return false end
    local value=snapshot.eventHundredths
    if not finite(value) or value%1~=0 or value<self.minimum or value>self.maximum then return false end
    if self.receivedAt and receivedAt<self.receivedAt then return false end
    local sameSession=snapshot.sessionKey==self.sessionKey
    if sameSession and (snapshot.revision<=self.revision or snapshot.serverNow<self.serverNow) then return false end
    if not sameSession or not self.initialized then
        self.cue=nil
    elseif value~=self.value then
        local direction=if value>self.value then 'rise' else 'fall'
        local verb=if direction=='rise' then 'rose' else 'dropped'
        local formatted=string.format('%.2f',value/100):gsub('0+$',''):gsub('%.$','')
        self.cue={direction=direction,hundredths=value,expiresAt=receivedAt+Presentation.Duration,
            text='Mini Multiplier '..verb..' to '..formatted..'×!',
            compactText='Mini Multiplier\n'..verb..' to '..formatted..'×!'}
    end
    self.value=value;self.sessionKey=snapshot.sessionKey;self.revision=snapshot.revision
    self.serverNow=snapshot.serverNow;self.receivedAt=receivedAt;self.initialized=true
    return true
end
function Presentation.read(self: any,localNow: number): any
    if self.destroyed or not finite(localNow) then return nil end
    if self.cue and localNow>=self.cue.expiresAt then self.cue=nil end
    return self.cue
end
function Presentation.clear(self: any)
    self.cue=nil;self.initialized=false
end
function Presentation.destroy(self: any)
    self:clear();self.destroyed=true
end
local function overlaps(a: Rect,b: Rect): boolean
    local gap=4
    return a.x<b.x+b.width+gap and a.x+a.width>b.x-gap
        and a.y<b.y+b.height+gap and a.y+a.height>b.y-gap
end
-- A small fixed set of HUD rectangles, never a descendant/viewport scan.
-- Layout runs only when the cue or geometry/visibility changes.
function Presentation.layout(width: number,height: number,bag: Rect,obstacles: {Rect},pickups: boolean): any
    if width<40 or height<60 or #obstacles>18 then return nil end
    local compact=width<600 or height<500
    local w,h=math.min(if compact then 260 else 720,width-16),if compact then 52 else 56
    local desiredX=math.clamp(bag.x+bag.width/2-w/2,8,width-8-w)
    local desiredY=bag.y-h-8
    local regions={bag}
    for _,rect in obstacles do table.insert(regions,rect) end
    if pickups then
        -- The six pooled pickup lanes rise 160 pixels above the basket.
        table.insert(regions,{x=bag.x+bag.width/2-112,y=bag.y-160,width=224,height=168})
    end
    local xs={desiredX,8,width-8-w}
    local ys={desiredY,8,height-8-h}
    for _,rect in regions do
        table.insert(xs,rect.x-w-8);table.insert(xs,rect.x+rect.width+8)
        table.insert(ys,rect.y-h-8);table.insert(ys,rect.y+rect.height+8)
    end
    local best,bestScore=nil,math.huge
    for _,x in xs do for _,y in ys do
        if x<8 or y<8 or x+w>width-8 or y+h>height-8 then continue end
        local candidate={x=x,y=y,width=w,height=h}
        local free=true
        for _,rect in regions do if overlaps(candidate,rect) then free=false;break end end
        if free then
            local score=(x-desiredX)^2+(y-desiredY)^2
            if score<bestScore then best=candidate;bestScore=score end
        end
    end end
    if best then best.compact=compact;best.fontSize=if compact then 23 else 42 end
    return best
end
return table.freeze(Presentation)
