--!strict
-- Pure domain logic: no Instances, network calls, task waits, or DataStores.
export type Position = {x: number, y: number, z: number}
export type Producer = {id: string, speciesId: string, slot: number, due: number}
export type Good = {speciesId: string, baseCoinValue: number}
export type Token = {id: string, owner: number, origin: string, speciesId: string, baseCoinValue: number, x: number, y: number, z: number, startX: number, startY: number, startZ: number, spawnedAt: number, readyAt: number}
export type State = {
    coinUnits: number, rebirths: number, revision: number, tutorialStep: number,
    producers: {Producer}, bag: {Good}, tokens: {Token}, discoveries: {[string]: boolean},
    starterClaimed: boolean, saleQueue: {{units: number,due: number}}, soldUnits: number,
    cashMultiplier: number, autoCollect: boolean, autoSell: boolean, miniMultiplier: number, processorLevel: number,
    lucky: {id: string,baseTier: number}?,
}
export type Result = {code: string, revision: number?, creditUnits: number?, replayed: boolean?, speciesId: string?}
export type Context = {now: number, alive: boolean, position: Position?}
export type Session = {owner: number, key: string, phase: string, sequence: number, state: State, cache: {[string]: any}, cacheCount: number, productionCursor: number}
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
function Core.new(config: any, catalog: any, random: (() -> number)?)
    assert(config.BuyUnits > 0 and config.Interval > 0 and config.MaxTier >= 3)
    return setmetatable({config=config, catalog=catalog,random=random or math.random}, Core)
end
function Core.id(self: any, s: Session): string
    s.sequence += 1
    return s.key .. "-" .. tostring(s.sequence)
end
function Core.slotPosition(self: any, slot: number): Position
    local c=self.config
    return {x=c.OriginX+((c.Columns-1)/2-(slot-1)%c.Columns)*c.ColumnSpacing,
        y=0.5+math.floor((slot-1)/c.Columns)*c.RowHeight,z=c.DisplayZ}
end
function Core.newSession(self: any, owner: number, now: number, key: string): Session
    local s: Session = {
        owner=owner,key=key,phase="Ready",sequence=0,cache={},cacheCount=0,productionCursor=1,
        state={coinUnits=self.config.StartingUnits,rebirths=0,revision=0,tutorialStep=1,producers={},bag={},tokens={},discoveries={},
            starterClaimed=false,saleQueue={},soldUnits=0,cashMultiplier=1,autoCollect=false,autoSell=false,miniMultiplier=1,processorLevel=0},
    }
    return s
end
function Core.validate(self: any, st: State, owner: number): boolean
    local c=self.config
    if not integer(st.coinUnits,0,c.CoinCap) or not integer(st.rebirths,0,20)
        or not integer(st.revision,0,2^52) or #st.producers>c.Slots
        or #st.bag>c.BagCap or #st.tokens>c.GroundCap or #st.saleQueue>c.SaleCapacity
        or not integer(st.soldUnits,0,c.CoinCap) then return false end
    if (st.starterClaimed and #st.producers==0) or (not st.starterClaimed and #st.producers>0) then return false end
    if st.cashMultiplier~=1 and st.cashMultiplier~=2 and st.cashMultiplier~=4 and st.cashMultiplier~=8 then return false end
    if not integer(st.processorLevel,0,#c.ProcessorCosts) or not integer(st.miniMultiplier,1,2) then return false end
    if st.lucky and (not validString(st.lucky.id) or not integer(st.lucky.baseTier,2,6)) then return false end
    local reserved=st.coinUnits+st.soldUnits
    local lastDue=-math.huge
    for _,sale in st.saleQueue do
        if not integer(sale.units,1,c.CoinCap) or not finite(sale.due) or sale.due<lastDue then return false end
        reserved+=sale.units; lastDue=sale.due
    end
    if reserved>c.CoinCap then return false end
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
            or not self.catalog[t.speciesId] or not integer(t.baseCoinValue,1,170) or not validPosition(t)
            or not finite(t.spawnedAt) or not finite(t.readyAt) or t.readyAt<t.spawnedAt
            or not finite(t.startX) or not finite(t.startY) or not finite(t.startZ) then return false end
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
    -- Pack all surviving minis after every state change. The server stores the
    -- same resting centers that clients animate towards, including after pickup.
    for index,token in candidate.tokens do
        local slot=((index-1)*7)%24
        local layer=math.floor((index-1)/24)
        local row=math.floor(slot/6)
        local column=(slot%6+row*2+layer*3)%6
        local seed=0
        for character=1,#token.id do seed=(seed*31+string.byte(token.id,character))%65521 end
        seed=bit32.bxor(seed,bit32.lshift(seed,13))
        seed=bit32.bxor(seed,bit32.rshift(seed,17))
        seed=bit32.bxor(seed,bit32.lshift(seed,5))
        local jitterX=(seed%101/100-.5)*.62
        local jitterZ=(math.floor(seed/101)%101/100-.5)*.62
        token.x=(column-2.5)*2.5+(row%2-.5)*.35+(layer%2-.5)*.4+jitterX
        token.y=1.3+layer*2
        token.z=self.config.TrayZ+(row-1.5)*2.5+(layer%2-.5)*.4+jitterZ
    end
    s.state=candidate
    return true
end
function Core.setPasses(self: any,s: Session,owned: {[string]: boolean})
    local st=copy(s.state)
    st.cashMultiplier=if owned.cash8 then 8 elseif owned.cash4 then 4 elseif owned.cash2 then 2 else 1
    st.autoCollect=owned.autoCollect==true; st.autoSell=owned.autoSell==true
    st.miniMultiplier=if owned.mini2 then 2 else 1
    if st.cashMultiplier==s.state.cashMultiplier and st.autoCollect==s.state.autoCollect and st.autoSell==s.state.autoSell and st.miniMultiplier==s.state.miniMultiplier then return end
    self:commit(s,st)
end
local function deposit(c: any,st: State,now: number): string
    if #st.bag==0 then return 'BagEmpty' end
    if #st.bag+#st.saleQueue>c.SaleCapacity then return 'QueueFull' end
    local total=st.coinUnits+st.soldUnits
    for _,sale in st.saleQueue do total+=sale.units end
    for _,g in st.bag do total+=g.baseCoinValue*(4+st.rebirths)*st.cashMultiplier end
    if total>c.CoinCap then return 'WalletFull' end
    local due=math.max(now,if #st.saleQueue>0 then st.saleQueue[#st.saleQueue].due else now)
    for _,g in st.bag do
        due+=if c.ProcessorRates then 1/c.ProcessorRates[st.processorLevel+1] else c.SaleSeconds/(1+st.processorLevel)
        table.insert(st.saleQueue,{units=g.baseCoinValue*(4+st.rebirths)*st.cashMultiplier,due=due})
    end
    st.bag={}; st.tutorialStep=math.max(st.tutorialStep,3)
    return 'OK'
end
function Core.step(self: any, s: Session, now: number): boolean
    if s.phase~="Ready" or not finite(now) then return false end
    local changed=false
    local st=copy(s.state); local c=self.config
    while #st.saleQueue>0 and st.saleQueue[1].due<=now do
        local sale=table.remove(st.saleQueue,1)
        if sale then st.soldUnits+=sale.units; changed=true end
    end
    local counts: {[string]: number}={}
    for _,t in st.tokens do counts[t.origin]=(counts[t.origin] or 0)+1 end
    local nextCursor=s.productionCursor
    for offset=0,#st.producers-1 do
        local index=(s.productionCursor-1+offset)%#st.producers+1
        local p=st.producers[index]
        if p.due>now then continue end
        changed=true
        local cycles=math.min(c.CatchupCap,math.floor((now-p.due)/c.Interval)+1)
        for _=1,cycles*st.miniMultiplier do
            if #st.tokens>=c.GroundCap or (counts[p.id] or 0)>=c.GroundPerProducer then break end
            local tokenId=self:id(s)
            local source=self:slotPosition(p.slot)
            table.insert(st.tokens,{
                id=tokenId,owner=s.owner,origin=p.id,speciesId=p.speciesId,
                baseCoinValue=self.catalog[p.speciesId].value,
                x=0,z=c.TrayZ,y=1.3,
                startX=source.x,startY=source.y+1,startZ=source.z-2,
                spawnedAt=now,readyAt=now+(c.TransitSeconds or 0),
            })
            counts[p.id]=(counts[p.id] or 0)+1
            nextCursor=index%#st.producers+1
            if not st.lucky and self.random()<c.LuckyChance then
                local best=1
                for _,producer in st.producers do best=math.max(best,self.catalog[producer.speciesId].tier) end
                st.lucky={id=self:id(s),baseTier=math.min(6,best+1)}
            end
        end
        -- Capped or late producers never queue hidden work.
        p.due=now+c.Interval
    end
    if st.autoCollect then
        for index=#st.tokens,1,-1 do
            local t=st.tokens[index]
            if t.readyAt<=now and #st.bag<c.BagCap then
                table.remove(st.tokens,index); table.insert(st.bag,{speciesId=t.speciesId,baseCoinValue=t.baseCoinValue}); changed=true
            end
        end
        if deposit(c,st,now)=='OK' then changed=true end
    end
    if st.autoSell and st.soldUnits>0 then st.coinUnits+=st.soldUnits; st.soldUnits=0; changed=true end
    if changed and self:commit(s,st) then s.productionCursor=nextCursor; return true end
    return false
end
function Core.dispatch(self: any, s: Session, requestedAction: any, args: any, ctx: Context): Result
    local function reject(code: string): Result return {code=code,revision=s.state.revision} end
    if s.phase~="Ready" then return reject("Unavailable") end
    local sizes: {[string]: number}={Collect=1,Deposit=1,Claim=1,Buy=2,Merge=3,Rebirth=1,Upgrade=1,OpenLucky=3}
    if type(requestedAction)~='string' then return reject('BadRequest') end
    local action: string=tostring(requestedAction)
    local size=sizes[action]
    if not size or type(args)~="table" then return reject("BadRequest") end
    local n=0
    for k,v in args do
        n+=1
        if n>size or not integer(k,1,size) or not validString(v) then return reject("BadRequest") end
    end
    local legacyBuy=action=="Buy" and n==1 and validString(args[1])
    if n~=size and not legacyBuy then return reject("BadRequest") end
    local quantity: string=if action=="Buy" then args[2] or "1" else "1"
    if action=="Buy" and self.config.BuyPads[quantity]==nil then return reject("BadRequest") end
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
        if ctx.now<t.readyAt then return reject('InTransit') end
        if distance(ctx.position :: Position,t)>c.CollectDistance then return reject("TooFar") end
        if #st.bag>=c.BagCap then return reject("BagFull") end
        table.remove(st.tokens,index)
        table.insert(st.bag,{speciesId=t.speciesId,baseCoinValue=t.baseCoinValue})
        result.speciesId=t.speciesId
        st.tutorialStep=math.max(st.tutorialStep,2)
    elseif action=="Deposit" or action=="Claim" or action=="Buy" then
        local anchor={x=c.OriginX+(if action=="Deposit" then c.SellX elseif action=="Claim" then c.ClaimX else c.BuyPads[quantity]),y=0.15,z=if action=="Deposit" then c.SellZ elseif action=="Claim" then c.ClaimZ else c.BuyZ}
        if distance(ctx.position :: Position,anchor)>c.PadDistance then return reject("TooFar") end
        if action=="Deposit" then
            local code=deposit(c,st,ctx.now)
            if code~='OK' then return reject(code) end
        elseif action=="Claim" then
            if st.soldUnits==0 then return reject('NothingReady') end
            result.creditUnits=st.soldUnits; st.coinUnits+=st.soldUnits; st.soldUnits=0
            st.tutorialStep=math.max(st.tutorialStep,4)
        else
            if not st.starterClaimed and quantity~='1' then return reject('ClaimStarter') end
            if st.rebirths<c.BuyUnlocks[quantity] then return reject("Locked") end
            local amount=if quantity=='100' then math.min(100,c.Slots-#st.producers) else tonumber(quantity) :: number
            if amount<1 then return reject('PlotFull') end
            if #st.producers+amount>c.Slots then return reject("PlotFull") end
            local cost=c.BuyUnits*amount
            if st.coinUnits<cost then return reject("InsufficientFunds") end
            local used: {[number]: boolean}={}
            for _,p in st.producers do used[p.slot]=true end
            local slot=1
            st.coinUnits-=cost; st.starterClaimed=true; st.discoveries.tier_01=true
            for _=1,amount do
                while used[slot] do slot+=1 end
                table.insert(st.producers,{id=self:id(s),speciesId="tier_01",slot=slot,due=ctx.now+c.Interval})
                used[slot]=true
            end
            st.tutorialStep=if #st.producers>=2 then math.max(st.tutorialStep,6) else st.tutorialStep
        end
    elseif action=='OpenLucky' then
        local lucky=st.lucky
        if not lucky or lucky.id~=args[2] then return reject('MissingLucky') end
        if distance(ctx.position :: Position,{x=0,y=1.6,z=24})>c.CollectDistance then return reject('TooFar') end
        local cost=c.LuckyBaseUnits+#st.producers*c.LuckyPerProducerUnits
        if args[3]~=tostring(cost) then return reject('PriceChanged') end
        if #st.producers>=c.Slots then return reject('PlotFull') end
        if st.coinUnits<cost then return reject('InsufficientFunds') end
        local roll=self.random()
        local tier=math.min(6,lucky.baseTier+(if roll<.75 then 0 elseif roll<.95 then 1 else 2))
        local speciesId=string.format('tier_%02d',tier)
        st.coinUnits-=cost; st.lucky=nil
        table.insert(st.producers,{id=self:id(s),speciesId=speciesId,slot=#st.producers+1,due=ctx.now+c.Interval})
        st.discoveries[speciesId]=true; result.speciesId=speciesId
    elseif action=='Upgrade' then
        local cost=c.ProcessorCosts[st.processorLevel+1]
        if not cost then return reject('MaxProcessor') end
        if distance(ctx.position :: Position,{x=c.UpgradeX,y=.15,z=c.UpgradeZ})>c.PadDistance then return reject('TooFar') end
        if st.coinUnits<cost then return reject('InsufficientFunds') end
        local ratio=if c.ProcessorRates then c.ProcessorRates[st.processorLevel+1]/c.ProcessorRates[st.processorLevel+2] else (1+st.processorLevel)/(2+st.processorLevel)
        st.coinUnits-=cost; st.processorLevel+=1
        for _,sale in st.saleQueue do sale.due=ctx.now+math.max(0,sale.due-ctx.now)*ratio end
    elseif action=="Rebirth" then
        if st.rebirths>=c.MaxRebirths then return reject("MaxRebirths") end
        local ownsTop=false
        for _,p in st.producers do if self.catalog[p.speciesId].tier==c.MaxTier then ownsTop=true; break end end
        if not ownsTop then return reject("NeedTier6") end
        if st.coinUnits<c.RebirthBase+st.rebirths*c.RebirthStep then return reject("InsufficientFunds") end
        st.rebirths+=1; st.coinUnits=0; st.bag={}; st.tokens={}; st.saleQueue={}; st.soldUnits=0; st.processorLevel=0; st.lucky=nil
        st.producers={{id=self:id(s),speciesId="tier_01",slot=1,due=ctx.now+c.Interval}}
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
        table.sort(st.producers,function(a: Producer,b: Producer) return a.slot<b.slot end)
        for slot,p in st.producers do p.slot=slot end
        st.discoveries[nextId]=true
        st.tutorialStep=7
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
