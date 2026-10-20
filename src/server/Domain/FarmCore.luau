--!strict
-- Pure domain logic: no Instances, network calls, task waits, or DataStores.
export type Position = {x: number, y: number, z: number}
export type Producer = {id: string, speciesId: string, slot: number, due: number, productionCredit: number?}
export type Good = {speciesId: string, baseCoinValue: number, count: number?}
export type Token = {id: string, owner: number, origin: string, speciesId: string, baseCoinValue: number, count: number?, x: number, y: number, z: number, startX: number, startY: number, startZ: number, spawnedAt: number, readyAt: number}
export type State = {
    coinUnits: number, rebirths: number, revision: number, tutorialStep: number, purchased: number, eventHundredths: number,
    obbyBonusHundredths: number?,depositCarry: number?,
    producers: {Producer}, bag: {Good}, tokens: {Token}, discoveries: {[string]: boolean},
    starterClaimed: boolean, saleQueue: {{units: number,due: number,count: number?,interval: number?}}, soldUnits: number,
    cashMultiplier: number, autoCollect: boolean, autoSell: boolean, miniMultiplier: number, processorLevel: number,
    lucky: {id: string,baseTier: number,held: boolean?}?,
}
export type Result = {code: string, revision: number?, creditUnits: number?, replayed: boolean?, speciesId: string?, count: number?, mergedCount: number?,counts: {[string]: number}?,inputCount: number?,depositedCount: number?,multiplierHundredths: number?}
export type Context = {now: number, alive: boolean, position: Position?, pickupPosition: Position?}
export type Session = {owner: number, key: string, phase: string, sequence: number, state: State, cache: {[string]: any}, cacheCount: number, productionCursor: number, pickupCache: {[string]: any}, pickupOrder: {string}}
local env: any=getfenv()
local Economy: any
if env.script then Economy=(require :: any)(env.game:GetService('ReplicatedStorage').Shared.Economy) else Economy=(require :: (string) -> unknown)('../../shared/Economy') end
local PickupGeometry: any
if env.script then PickupGeometry=(require :: any)(env.game:GetService('ReplicatedStorage').Shared.PickupGeometry) else PickupGeometry=(require :: (string) -> unknown)('../../shared/PickupGeometry') end
local MiniMotion: any
if env.script then MiniMotion=(require :: any)(env.game:GetService('ReplicatedStorage').Shared.MiniMotion) else MiniMotion=(require :: (string) -> unknown)('../../shared/MiniMotion') end
local PadGeometry: any
if env.script then PadGeometry=(require :: any)(env.game:GetService('ReplicatedStorage').Shared.PadGeometry) else PadGeometry=(require :: (string) -> unknown)('../../shared/PadGeometry') end
local LuckyRewards: any
if env.script then LuckyRewards=(require :: any)(env.game:GetService('ReplicatedStorage').Shared.LuckyRewards) else LuckyRewards=(require :: (string) -> unknown)('../../shared/LuckyRewards') end
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
        y=(c.DisplayPlatformHeight or .5)+math.floor((slot-1)/c.Columns)*c.RowHeight,z=c.DisplayZ}
end
function Core.newSession(self: any, owner: number, now: number, key: string): Session
    local s: Session = {
        owner=owner,key=key,phase="Ready",sequence=0,cache={},cacheCount=0,productionCursor=1,pickupCache={},pickupOrder={},
        state={coinUnits=self.config.StartingUnits,purchased=0,eventHundredths=100,obbyBonusHundredths=0,depositCarry=0,rebirths=0,revision=0,tutorialStep=1,producers={},bag={},tokens={},discoveries={},
            starterClaimed=false,saleQueue={},soldUnits=0,cashMultiplier=1,autoCollect=false,autoSell=false,miniMultiplier=1,processorLevel=0},
    }
    return s
end
function Core.validate(self: any, st: State, owner: number): boolean
    local c=self.config
    if not integer(st.coinUnits,0,c.CoinCap) or not integer(st.rebirths,0,20) or not integer(st.eventHundredths,50,150)
        or (st.obbyBonusHundredths~=nil and not integer(st.obbyBonusHundredths,0,100))
        or (st.depositCarry~=nil and not integer(st.depositCarry,0,99))
        or not integer(st.revision,0,2^52) or #st.producers>c.Slots
        or not integer(st.purchased,0,2^31-1) or Economy.count(st.bag)>c.BagCap or #st.tokens>c.GroundCap or Economy.count(st.saleQueue)>c.SaleCapacity
        or not integer(st.soldUnits,0,c.CoinCap) then return false end
    if (st.starterClaimed and #st.producers==0) or (not st.starterClaimed and #st.producers>0) then return false end
    if st.cashMultiplier~=1 and st.cashMultiplier~=2 and st.cashMultiplier~=4 and st.cashMultiplier~=8 then return false end
    if not integer(st.processorLevel,0,#c.ProcessorCosts) or not integer(st.miniMultiplier,1,2) then return false end
    if st.lucky and (not validString(st.lucky.id) or not integer(st.lucky.baseTier,2,c.MaxTier)
        or (st.lucky.held~=nil and type(st.lucky.held)~='boolean')) then return false end
    local reserved=st.coinUnits+st.soldUnits
    local lastDue=-math.huge
    for _,sale in st.saleQueue do
        if not integer(sale.units,1,c.CoinCap) or not finite(sale.due) or sale.due<lastDue-1e-7 or not integer(sale.count or 1,1,c.SaleCapacity) or not finite(sale.interval or c.SaleSeconds) or (sale.interval or c.SaleSeconds)<0 then return false end
        reserved+=sale.units*(sale.count or 1); lastDue=sale.due+(sale.count or 1)*(sale.interval or c.SaleSeconds)-(sale.interval or c.SaleSeconds)
    end
    if reserved>c.CoinCap then return false end
    local ids: {[string]: boolean} = {}
    local slots: {[number]: boolean} = {}
    local counts: {[string]: number} = {}
    for _,p in st.producers do
        if not validString(p.id) or ids[p.id] or not self.catalog[p.speciesId]
            or not integer(p.slot,1,c.Slots) or slots[p.slot] or not finite(p.due) or not integer(p.productionCredit or 0,0,99) then return false end
        ids[p.id]=true; slots[p.slot]=true
    end
    for _,t in st.tokens do
        if not validString(t.id) or ids[t.id] or not validString(t.origin) or t.owner~=owner
            or not self.catalog[t.speciesId] or not integer(t.baseCoinValue,1,c.CoinCap) or not integer(t.count or 1,1,c.CoinCap) or not validPosition(t)
            or not finite(t.spawnedAt) or not finite(t.readyAt) or t.readyAt<t.spawnedAt
            or not finite(t.startX) or not finite(t.startY) or not finite(t.startZ) then return false end
        ids[t.id]=true
        counts[t.origin]=(counts[t.origin] or 0)+1
        if counts[t.origin]>c.GroundPerProducer then return false end
    end
    for _,g in st.bag do
        if not self.catalog[g.speciesId] or not integer(g.baseCoinValue,1,c.CoinCap) or not integer(g.count or 1,1,c.BagCap) then return false end
    end
    return true
end
function Core.snapshot(self: any, s: Session): State
    return copy(s.state)
end
function Core.setEvent(self: any,s: Session,hundredths: number)
    if hundredths==s.state.eventHundredths then return end
    local st=copy(s.state);st.eventHundredths=hundredths;self:commit(s,st)
end
-- Server-owned reward/expiry input. The run service owns the deadline; rebirth
-- preserves this rate along with passes. Return true only when state changes.
function Core.setObbyBonus(self: any,s: Session,hundredths: number): boolean
    if s.phase~="Ready" or not integer(hundredths,0,100) or hundredths==(s.state.obbyBonusHundredths or 0) then return false end
    local st=copy(s.state);st.obbyBonusHundredths=hundredths
    return self:commit(s,st)
end
function Core.commit(self: any, s: Session, candidate: State): boolean
    candidate.revision=s.state.revision+1
    if not self:validate(candidate,s.owner) then return false end
    -- Slot 1 is the viewer's left. Rank the authoritative display slots after
    -- every valid transition, retaining previous slot order among equal tiers.
    -- Sort references only: storage order drives the round-robin scheduler.
    local displayOrder=table.clone(candidate.producers)
    table.sort(displayOrder,function(a: Producer,b: Producer): boolean
        local aTier,bTier=self.catalog[a.speciesId].tier,self.catalog[b.speciesId].tier
        return if aTier==bTier then a.slot<b.slot else aTier>bTier
    end)
    for slot,producer in displayOrder do producer.slot=slot end
    -- Pack all surviving minis after every state change. The server stores the
    -- same resting centers that clients animate towards, including after pickup.
    local tray=self.config.Tray
    local cells=tray.Columns*tray.Rows
    for index,token in candidate.tokens do
        local slot=((index-1)*7)%cells
        local layer=math.floor((index-1)/cells)
        local row=math.floor(slot/tray.Columns)
        local column=(slot%tray.Columns+row*2+layer*3)%tray.Columns
        local seed=0
        for character=1,#token.id do seed=(seed*31+string.byte(token.id,character))%65521 end
        seed=bit32.bxor(seed,bit32.lshift(seed,13))
        seed=bit32.bxor(seed,bit32.rshift(seed,17))
        seed=bit32.bxor(seed,bit32.lshift(seed,5))
        local jitterX=(seed%101/100-.5)*.62
        local jitterZ=(math.floor(seed/101)%101/100-.5)*.62
        token.x=(column-(tray.Columns-1)/2)*tray.SpacingX+(row%2-.5)*.35+(layer%2-.5)*.4+jitterX
        token.y=tray.BaseY+layer*tray.LayerHeight
        token.z=self.config.TrayZ+(row-(tray.Rows-1)/2)*tray.SpacingZ+(layer%2-.5)*.4+jitterZ
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
local function drainSales(st: State,now: number,c: any): boolean
    local changed=false
    while #st.saleQueue>0 and st.saleQueue[1].due<=now do
        local sale=st.saleQueue[1]
        local interval=sale.interval or c.SaleSeconds
        local processed=if interval==0 then sale.count or 1 else math.min(sale.count or 1,math.floor((now-sale.due)/interval+1e-7)+1)
        st.soldUnits+=sale.units*processed; changed=true
        sale.count=(sale.count or 1)-processed
        if sale.count==0 then table.remove(st.saleQueue,1) else sale.due+=processed*interval end
    end
    return changed
end
local function deposit(c: any,st: State,now: number): (string,any?)
    local quote=Economy.depositQuote(c,st)
    if quote.code~='OK' then return quote.code,nil end
    local interval=if c.ProcessorRates then 1/c.ProcessorRates[st.processorLevel+1] else c.SaleSeconds
    for _,g in quote.goods do
        local units=g.baseCoinValue*(4+st.rebirths)*st.cashMultiplier
        local tail=st.saleQueue[#st.saleQueue]
        if tail and tail.units==units then
            tail.count=(tail.count or 1)+(g.count or 1)
        else
            local previousEnd=if tail then tail.due+((tail.count or 1)-1)*(tail.interval or interval) else now
            table.insert(st.saleQueue,{units=units,count=g.count or 1,due=math.max(now,previousEnd)+interval,interval=interval})
        end
    end
    st.depositCarry=quote.nextCarry
    st.bag={}; st.tutorialStep=math.max(st.tutorialStep,3)
    return 'OK',quote
end
local function hasStepWork(st: State,now: number): boolean
    if st.saleQueue[1] and st.saleQueue[1].due<=now then return true end
    -- Capped producers still advance deadlines/credits and roll Lucky.
    for _,producer in st.producers do if producer.due<=now then return true end end
    if st.autoSell and st.soldUnits>0 then return true end
    if st.autoCollect then
        if #st.bag>0 then return true end
        for _,token in st.tokens do if token.readyAt<=now then return true end end
    end
    return false
end
function Core.step(self: any, s: Session, now: number): boolean
    if s.phase~="Ready" or not finite(now) then return false end
    -- Read-only and conservative: blocked work may still take the normal path,
    -- but a quiet cadence tick need not recursively copy every producer/Mini.
    if not hasStepWork(s.state,now) then return false end
    local changed=false
    local st=copy(s.state); local c=self.config
    if drainSales(st,now,c) then changed=true end
    local counts: {[string]: number}={}
    for _,t in st.tokens do counts[t.origin]=(counts[t.origin] or 0)+1 end
    local nextCursor=s.productionCursor
    for offset=0,#st.producers-1 do
        local index=(s.productionCursor-1+offset)%#st.producers+1
        local p=st.producers[index]
        if p.due>now then continue end
        changed=true
        local cycles=math.min(c.CatchupCap,math.floor((now-p.due)/c.Interval)+1)
        local drops=cycles*st.miniMultiplier
        p.productionCredit=0
        for _=1,drops do
            -- Lucky rolls belong to production ticks, even when the physical tray is full.
            if not st.lucky and self.random()<c.LuckyChance then
                local best=1
                for _,producer in st.producers do best=math.max(best,self.catalog[producer.speciesId].tier) end
                st.lucky={id=self:id(s),baseTier=math.min(c.MaxTier-2,best+1)}
            end
            if #st.tokens>=c.GroundCap or (counts[p.id] or 0)>=c.GroundPerProducer then continue end
            local tokenId=self:id(s)
            local source=self:slotPosition(p.slot)
            table.insert(st.tokens,{
                id=tokenId,owner=s.owner,origin=p.id,speciesId=p.speciesId,
                baseCoinValue=self.catalog[p.speciesId].value,count=self.catalog[p.speciesId].production or 1,
                x=0,z=c.TrayZ,y=c.Tray.BaseY,
                startX=source.x,startY=source.y+1,startZ=source.z-2,
                spawnedAt=now,readyAt=now+(c.TransitSeconds or 0),
            })
            counts[p.id]=(counts[p.id] or 0)+1
            nextCursor=index%#st.producers+1
        end
        -- Capped or late producers never queue hidden work.
        p.due=now+c.Interval
    end
    if st.autoCollect then
        for index=#st.tokens,1,-1 do
            local t=st.tokens[index]
            if t.readyAt<=now and Economy.count(st.bag)+(t.count or 1)<=c.BagCap then
                table.remove(st.tokens,index); Economy.add(st.bag,t.speciesId,t.baseCoinValue,t.count); changed=true
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
    local sizes: {[string]: number}={Collect=1,CollectNearby=1,AutoMerge=1,Deposit=1,Claim=1,Buy=2,Merge=(self.config.MergeCount or 3)+1,Rebirth=1,Upgrade=1,OpenLucky=3,PickupLucky=2,DropLucky=2,DiscardLucky=2}
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
        local old=(if action=='CollectNearby' then s.pickupCache else s.cache)[requestId]
        if old then
            if old.action~=action or #old.args~=#args then return reject("RequestConflict") end
            for i,v in args do if old.args[i]~=v then return reject("RequestConflict") end end
            local result=copy(old.result); result.replayed=true
            return result
        end
        if action~='CollectNearby' and s.cacheCount>=self.config.RequestCap then return reject("RequestLimit") end
    end
    if not ctx.alive or not validPosition(ctx.position) or not finite(ctx.now) then return reject("NotAlive") end
    local c=self.config; local st=copy(s.state); local result: Result={code="OK"}
    drainSales(st,ctx.now,c)
    if action=='CollectNearby' then
        if ctx.pickupPosition~=nil and not validPosition(ctx.pickupPosition) then return reject('NotAlive') end
        local room=c.BagCap-Economy.count(st.bag)
        if room<=0 then return reject('BagFull') end
        local counts: {[string]: number}={}; local picked=0
        -- Runtime supplies the actual root center; retain the legacy domain context for callers without an avatar.
        local center=ctx.pickupPosition or {x=(ctx.position :: Position).x,y=(ctx.position :: Position).y+3,z=(ctx.position :: Position).z}
        for index=#st.tokens,1,-1 do
            local t=st.tokens[index]
            local current=MiniMotion.position(c,t,ctx.now)
            local miniCount=t.count or 1
            if picked+miniCount<=room and t.owner==s.owner and current and PickupGeometry.contains(center,current,c.PickupRadius) then
                table.remove(st.tokens,index); Economy.add(st.bag,t.speciesId,t.baseCoinValue,miniCount)
                counts[t.speciesId]=(counts[t.speciesId] or 0)+miniCount; picked+=miniCount
            end
        end
        if picked==0 then return reject('NothingNearby') end
        result.count=picked; result.counts=counts; st.tutorialStep=math.max(st.tutorialStep,2)
    elseif action=='AutoMerge' then
        if not PadGeometry.contains(c,action,ctx.position :: Position) then return reject('TooFar') end
        local merged=0
        while true do
            local seen: {[string]: {number}}={}
            local group: {number}?=nil
            for index,p in st.producers do
                if self.catalog[p.speciesId].nextId then
                    local matches=seen[p.speciesId] or {}
                    seen[p.speciesId]=matches;table.insert(matches,index)
                    if #matches==(c.MergeCount or 3) then group=matches;break end
                end
            end
            if not group then break end
            local first=st.producers[group[1]]
            local nextId=self.catalog[first.speciesId].nextId
            local slot=first.slot
            for index=#group,1,-1 do
                slot=math.min(slot,st.producers[group[index]].slot)
                table.remove(st.producers,group[index])
            end
            table.insert(st.producers,{id=self:id(s),speciesId=nextId,slot=slot,due=ctx.now+c.Interval})
            st.discoveries[nextId]=true;merged+=1
        end
        if merged==0 then return reject('NoPairs') end
        table.sort(st.producers,function(a: Producer,b: Producer) return a.slot<b.slot end)
        for packedSlot,p in st.producers do p.slot=packedSlot end
        st.tutorialStep=7; result.count=merged
    elseif action=="Collect" then
        local index: number?=nil
        for i,t in st.tokens do if t.id==requestId and t.owner==s.owner then index=i; break end end
        if not index then return reject("MissingToken") end
        local t=st.tokens[index]
        local current=MiniMotion.position(c,t,ctx.now)
        if not current then return reject('InTransit') end
        if distance(ctx.position :: Position,current)>c.CollectDistance then return reject("TooFar") end
        if Economy.count(st.bag)+(t.count or 1)>c.BagCap then return reject("BagFull") end
        table.remove(st.tokens,index)
        Economy.add(st.bag,t.speciesId,t.baseCoinValue,t.count)
        result.speciesId=t.speciesId; result.count=t.count or 1
        st.tutorialStep=math.max(st.tutorialStep,2)
    elseif action=="Deposit" or action=="Claim" or action=="Buy" then
        if not PadGeometry.contains(c,action,ctx.position :: Position,quantity) then return reject("TooFar") end
        if action=="Deposit" then
            local code,quote=deposit(c,st,ctx.now)
            if code~='OK' then return reject(code) end
            result.inputCount=quote.inputCount;result.depositedCount=quote.depositedCount;result.multiplierHundredths=quote.multiplierHundredths
        elseif action=="Claim" then
            if st.soldUnits==0 then return reject('NothingReady') end
            result.creditUnits=st.soldUnits; st.coinUnits+=st.soldUnits; st.soldUnits=0
            st.tutorialStep=math.max(st.tutorialStep,4)
        else
            local quote=Economy.purchaseQuote(c,st,quantity)
            if quote.code~='OK' then return reject(quote.code) end
            local amount,tier,cost=quote.amount,quote.tier,quote.cost
            local speciesId=string.format('tier_%02d',tier)
            st.coinUnits-=cost; st.purchased+=amount*(c.MergeCount or 3)^(tier-1); result.count=amount; result.speciesId=speciesId; st.starterClaimed=true; st.discoveries[speciesId]=true
            if quote.mergePlan then
                local previous: {[string]: Producer}={}
                for _,producer in st.producers do previous[producer.id]=producer end
                local final: {Producer}={}
                for slot,item in quote.mergePlan do
                    local source=if item.sourceId then previous[item.sourceId] else nil
                    local unchanged=source and source.speciesId==item.speciesId
                    table.insert(final,{id=if source then source.id else self:id(s),speciesId=item.speciesId,slot=slot,
                        due=if source and unchanged then source.due else ctx.now+c.Interval,
                        productionCredit=if source and unchanged then source.productionCredit else 0})
                end
                st.producers=final
                for _,discovered in quote.discoveries do st.discoveries[discovered]=true end
                result.mergedCount=quote.mergedCount
            else
                local used: {[number]: boolean}={}
                for _,p in st.producers do used[p.slot]=true end
                local slot=1
                for _=1,amount do
                    while used[slot] do slot+=1 end
                    table.insert(st.producers,{id=self:id(s),speciesId=speciesId,slot=slot,due=ctx.now+c.Interval})
                    used[slot]=true
                end
            end
            st.tutorialStep=if #st.producers>=2 then math.max(st.tutorialStep,6) else st.tutorialStep
        end
    elseif action=='PickupLucky' or action=='DropLucky' or action=='DiscardLucky' then
        local lucky=st.lucky
        if not lucky or lucky.id~=args[2] then return reject('MissingLucky') end
        if action=='PickupLucky' then
            if not lucky.held and distance(ctx.position :: Position,{x=c.LuckyX,y=1.6,z=c.LuckyZ})>c.LuckyPickupRadius then return reject('TooFar') end
            lucky.held=true
        else
            if not lucky.held then return reject('NotHoldingLucky') end
            if action=='DropLucky' then lucky.held=false else st.lucky=nil end
        end
    elseif action=='OpenLucky' then
        local lucky=st.lucky
        if not lucky or lucky.id~=args[2] then return reject('MissingLucky') end
        if not lucky.held then return reject('NotHoldingLucky') end
        local cost=LuckyRewards.cost(c,st)
        if args[3]~=tostring(cost) then return reject('PriceChanged') end
        if #st.producers>=c.Slots then return reject('PlotFull') end
        if st.coinUnits<cost then return reject('InsufficientFunds') end
        local roll=self.random()
        local speciesId=LuckyRewards.choose(c,lucky.baseTier,roll).speciesId
        st.coinUnits-=cost; st.lucky=nil
        table.insert(st.producers,{id=self:id(s),speciesId=speciesId,slot=#st.producers+1,due=ctx.now+c.Interval})
        st.discoveries[speciesId]=true; result.speciesId=speciesId
    elseif action=='Upgrade' then
        local cost=c.ProcessorCosts[st.processorLevel+1]
        if not cost then return reject('MaxProcessor') end
        if not PadGeometry.contains(c,action,ctx.position :: Position) then return reject('TooFar') end
        if st.coinUnits<cost then return reject('InsufficientFunds') end
        local ratio=if c.ProcessorRates then c.ProcessorRates[st.processorLevel+1]/c.ProcessorRates[st.processorLevel+2] else (1+st.processorLevel)/(2+st.processorLevel)
        st.coinUnits-=cost; st.processorLevel+=1
        for _,sale in st.saleQueue do sale.due=ctx.now+math.max(0,sale.due-ctx.now)*ratio; sale.interval=(sale.interval or c.SaleSeconds)*ratio end
    elseif action=="Rebirth" then
        if st.rebirths>=c.MaxRebirths then return reject("MaxRebirths") end
        local ownsTop=false
        for _,p in st.producers do if self.catalog[p.speciesId].tier>=(c.RebirthTier or c.MaxTier) then ownsTop=true; break end end
        if not ownsTop then return reject("NeedTier6") end
        if st.coinUnits<c.RebirthBase+st.rebirths*c.RebirthStep then return reject("InsufficientFunds") end
        st.rebirths+=1; st.purchased=0; st.coinUnits=0; st.bag={}; st.tokens={}; st.saleQueue={}; st.soldUnits=0; st.processorLevel=0; st.lucky=nil;st.depositCarry=0
        st.producers={{id=self:id(s),speciesId="tier_01",slot=1,due=ctx.now+c.Interval}}
    else
        local selected: {[string]: boolean}={}
        for index=2,size do
            if selected[args[index]] then return reject("SameProducer") end
            selected[args[index]]=true
        end
        local indexes: {number}={}
        for index,p in st.producers do
            if selected[p.id] then table.insert(indexes,index) end
        end
        if #indexes~=(c.MergeCount or 3) then return reject("MissingProducer") end
        local first=st.producers[indexes[1]]
        local slot=first.slot
        for _,index in indexes do
            if st.producers[index].speciesId~=first.speciesId then return reject("Mismatch") end
            slot=math.min(slot,st.producers[index].slot)
        end
        local nextId=self.catalog[first.speciesId].nextId
        if not nextId then return reject("MaxTier") end
        local output: Producer={id=self:id(s),speciesId=nextId :: string,slot=slot,due=ctx.now+c.Interval}
        for index=#indexes,1,-1 do table.remove(st.producers,indexes[index]) end
        table.insert(st.producers,output)
        result.count=1
        table.sort(st.producers,function(a: Producer,b: Producer) return a.slot<b.slot end)
        for packedSlot,p in st.producers do p.slot=packedSlot end
        st.discoveries[nextId]=true
        st.tutorialStep=7
    end
    if not self:commit(s,st) then return reject("InvalidState") end
    result.revision=st.revision
    if action=='CollectNearby' then
        s.pickupCache[requestId]={action=action,args=copy(args),result=copy(result)}
        table.insert(s.pickupOrder,requestId)
        if #s.pickupOrder>128 then local oldest=table.remove(s.pickupOrder,1);if oldest then s.pickupCache[oldest]=nil end end
    elseif action~="Collect" then
        s.cache[requestId]={action=action,args=copy(args),result=copy(result)}
        s.cacheCount+=1
    end
    return result
end
return Core
