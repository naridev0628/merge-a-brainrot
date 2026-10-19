--!strict
-- Pure domain logic: no Instances, network calls, task waits, or DataStores.
export type Position = {x: number, y: number, z: number}
export type Producer = {id: string, speciesId: string, slot: number, due: number}
export type Good = {speciesId: string, baseCoinValue: number}
export type Token = {id: string, owner: number, origin: string, speciesId: string, baseCoinValue: number, x: number, y: number, z: number}
export type State = {
    coinUnits: number, rebirths: number, revision: number, tutorialStep: number,
    producers: {Producer}, bag: {Good}, tokens: {Token}, discoveries: {[string]: boolean},
}
export type Result = {code: string, revision: number?, creditUnits: number?, replayed: boolean?}
export type Context = {now: number, alive: boolean, position: Position?}
export type Session = {owner: number, key: string, phase: string, sequence: number, state: State, cache: {[string]: any}, cacheCount: number}
local Core = {}
Core.__index = Core
local function finite(n: any): boolean
    return type(n) == "number" and n == n and math.abs(n) < math.huge
end
local function integer(n: any, low: number, high: number): boolean
    return finite(n) and n % 1 == 0 and n >= low and n <= high
end
local function copy<T>(value: T): T
    if type(value) ~= "table" then return value :: any end
    local result: any = {}
    for k, v in value :: any do result[k] = copy(v) end
    return result
end
local function validString(v: any): boolean
    return type(v) == "string" and #v > 0 and #v <= 128
end
local function validPosition(p: any): boolean
    return type(p) == "table" and finite(p.x) and finite(p.y) and finite(p.z)
end
local function distance(a: Position, b: Position): number
    return math.sqrt((a.x-b.x)^2 + (a.y-b.y)^2 + (a.z-b.z)^2)
end
function Core.new(config: any, catalog: any)
    assert(config.BuyUnits > 0 and config.Interval > 0 and config.MaxTier == 3)
    return setmetatable({config=config, catalog=catalog}, Core)
end
function Core.id(self: any, s: Session): string
    s.sequence += 1
    return s.key .. "-" .. tostring(s.sequence)
end
function Core.slotPosition(self: any, slot: number): Position
    return {x=self.config.OriginX + ((slot-1)%3-1)*14, y=1.6, z=self.config.OriginZ - 4 + math.floor((slot-1)/3)*8}
end
function Core.newSession(self: any, owner: number, now: number, key: string): Session
    local s: Session = {
        owner=owner,key=key,phase="Ready",sequence=0,cache={},cacheCount=0,
        state={coinUnits=0,rebirths=0,revision=0,tutorialStep=1,producers={},bag={},tokens={},discoveries={tier_01=true}},
    }
    table.insert(s.state.producers,{id=self:id(s),speciesId="tier_01",slot=1,due=now+self.config.Interval})
    return s
end
function Core.validate(self: any, st: State, owner: number): boolean
    local c=self.config
    if not integer(st.coinUnits,0,c.CoinCap) or not integer(st.rebirths,0,20)
        or not integer(st.revision,0,2^52) or #st.producers<1 or #st.producers>c.Slots
        or #st.bag>c.BagCap or #st.tokens>c.GroundCap then return false end
    local ids: {[string]: boolean} = {}
    local slots: {[number]: boolean} = {}
    local counts: {[string]: number} = {}
    for _,p in st.producers do
        if not validString(p.id) or ids[p.id] or not self.catalog[p.speciesId]
            or not integer(p.slot,1,c.Slots) or slots[p.slot] or not finite(p.due) then return false end
        ids[p.id]=true; slots[p.slot]=true
    end
    for _,t in st.tokens do
        if not validString(t.id) or ids[t.id] or not validString(t.origin) or t.owner~=owner
            or not self.catalog[t.speciesId] or not integer(t.baseCoinValue,1,170) or not validPosition(t) then return false end
        ids[t.id]=true
        counts[t.origin]=(counts[t.origin] or 0)+1
        if counts[t.origin]>c.GroundPerProducer then return false end
    end
    for _,g in st.bag do
        if not self.catalog[g.speciesId] or not integer(g.baseCoinValue,1,170) then return false end
    end
    return true
end
function Core.snapshot(self: any, s: Session): State
    return copy(s.state)
end
function Core.commit(self: any, s: Session, candidate: State): boolean
    candidate.revision=s.state.revision+1
    if not self:validate(candidate,s.owner) then return false end
    s.state=candidate
    return true
end
function Core.step(self: any, s: Session, now: number): boolean
    if s.phase~="Ready" or not finite(now) then return false end
    local due=false
    for _,p in s.state.producers do if p.due<=now then due=true; break end end
    if not due then return false end
    local st=copy(s.state); local c=self.config
    local counts: {[string]: number}={}
    for _,t in st.tokens do counts[t.origin]=(counts[t.origin] or 0)+1 end
    for _,p in st.producers do
        if p.due>now then continue end
        local cycles=math.min(c.CatchupCap,math.floor((now-p.due)/c.Interval)+1)
        for _=1,cycles do
            if #st.tokens>=c.GroundCap or (counts[p.id] or 0)>=c.GroundPerProducer then break end
            local pos=self:slotPosition(p.slot)
            local tokenId=self:id(s)
            local angle=(s.sequence%8)*math.pi/4
            table.insert(st.tokens,{
                id=tokenId,owner=s.owner,origin=p.id,speciesId=p.speciesId,
                baseCoinValue=self.catalog[p.speciesId].value,
                x=pos.x+math.cos(angle)*3,z=pos.z+math.sin(angle)*3,y=1.6,
            })
            counts[p.id]=(counts[p.id] or 0)+1
        end
        -- Capped or late producers never queue hidden work.
        p.due=now+c.Interval
    end
    return self:commit(s,st)
end
function Core.dispatch(self: any, s: Session, action: any, args: any, ctx: Context): Result
    local function reject(code: string): Result return {code=code,revision=s.state.revision} end
    if s.phase~="Ready" then return reject("Unavailable") end
    local sizes: {[string]: number}={Collect=1,Sell=1,Buy=1,Merge=3}
    local size=if type(action)=="string" then sizes[action] else nil
    if not size or type(args)~="table" then return reject("BadRequest") end
    local n=0
    for k,v in args do
        n+=1
        if n>size or not integer(k,1,size) or not validString(v) then return reject("BadRequest") end
    end
    if n~=size then return reject("BadRequest") end
    local requestId=args[1]
    if action~="Collect" then
        local old=s.cache[requestId]
        if old then
            if old.action~=action or #old.args~=#args then return reject("RequestConflict") end
            for i,v in args do if old.args[i]~=v then return reject("RequestConflict") end end
            local result=copy(old.result); result.replayed=true
            return result
        end
        if s.cacheCount>=self.config.RequestCap then return reject("RequestLimit") end
    end
    if not ctx.alive or not validPosition(ctx.position) or not finite(ctx.now) then return reject("NotAlive") end
    local c=self.config; local st=copy(s.state); local result: Result={code="OK"}
    if action=="Collect" then
        local index: number?=nil
        for i,t in st.tokens do if t.id==requestId and t.owner==s.owner then index=i; break end end
        if not index then return reject("MissingToken") end
        local t=st.tokens[index]
        if distance(ctx.position :: Position,t)>c.CollectDistance then return reject("TooFar") end
        if #st.bag>=c.BagCap then return reject("BagFull") end
        table.remove(st.tokens,index)
        table.insert(st.bag,{speciesId=t.speciesId,baseCoinValue=t.baseCoinValue})
        st.tutorialStep=math.max(st.tutorialStep,2)
    elseif action=="Sell" or action=="Buy" then
        local anchor={x=c.OriginX+(if action=="Sell" then -18 else 18),y=0.15,z=c.OriginZ-18}
        if distance(ctx.position :: Position,anchor)>c.PadDistance then return reject("TooFar") end
        if action=="Sell" then
            if #st.bag==0 then return reject("BagEmpty") end
            local value=0
            for _,g in st.bag do value+=g.baseCoinValue end
            local units=value*(4+st.rebirths)
            if st.coinUnits+units>c.CoinCap then return reject("WalletFull") end
            st.coinUnits+=units; st.bag={}; result.creditUnits=units
            st.tutorialStep=math.max(st.tutorialStep,3)
        else
            if #st.producers>=c.Slots then return reject("PlotFull") end
            if st.coinUnits<c.BuyUnits then return reject("InsufficientFunds") end
            local used: {[number]: boolean}={}
            for _,p in st.producers do used[p.slot]=true end
            local slot=1
            while used[slot] do slot+=1 end
            st.coinUnits-=c.BuyUnits
            table.insert(st.producers,{id=self:id(s),speciesId="tier_01",slot=slot,due=ctx.now+c.Interval})
            st.tutorialStep=math.max(st.tutorialStep,4)
        end
    else
        if args[2]==args[3] then return reject("SameProducer") end
        local a: number?=nil; local b: number?=nil
        for i,p in st.producers do
            if p.id==args[2] then a=i end
            if p.id==args[3] then b=i end
        end
        if not a or not b then return reject("MissingProducer") end
        local ai,bi=a :: number,b :: number
        local first,second=st.producers[ai],st.producers[bi]
        if first.speciesId~=second.speciesId then return reject("Mismatch") end
        local nextId=self.catalog[first.speciesId].nextId
        if not nextId then return reject("MaxTier") end
        local output={id=self:id(s),speciesId=nextId,slot=math.min(first.slot,second.slot),due=ctx.now+c.Interval}
        table.remove(st.producers,math.max(ai,bi)); table.remove(st.producers,math.min(ai,bi))
        table.insert(st.producers,output)
        st.discoveries[nextId]=true
        st.tutorialStep=math.max(st.tutorialStep,5)
    end
    if not self:commit(s,st) then return reject("InvalidState") end
    result.revision=st.revision
    if action~="Collect" then
        s.cache[requestId]={action=action,args=copy(args),result=copy(result)}
        s.cacheCount+=1
    end
    return result
end
return Core
