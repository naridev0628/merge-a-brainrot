--!strict
local Economy={}
local env: any=getfenv()
local Catalog: any
if env.script then Catalog=(require :: any)(env.script.Parent.CreatureCatalog) else Catalog=require('./CreatureCatalog') end
-- Quarter-dollar units. First two purchases cost $5; then +$1 per purchase.
function Economy.buyCost(purchased: number, amount: number, tier: number?,mergeCount: number?): number
    local count=amount*(mergeCount or 3)^((tier or 1)-1)
    -- Closed form keeps high-tier bulk quotes constant-time (millions of
    -- equivalent starter purchases), including the first two $5 purchases.
    local increasing=math.max(0,count-math.max(0,2-purchased))
    local last=math.max(0,purchased+count-2)
    return count*20+2*increasing*(2*last-increasing+1)
end
export type PlannedProducer={speciesId: string,sourceId: string?}
export type PurchaseQuote = {amount: number, tier: number, cost: number, code: string,
    mergePlan: {PlannedProducer}?,mergedCount: number?,discoveries: {string}?}
-- Count arithmetic never materializes the incoming hundred producers. Resolve
-- the same final survivor plan for price labels and the authoritative command.
local function bulkPlan(config: any,state: any,amount: number,tier: number): ({PlannedProducer},number,{string})
    local counts: {[number]: number}={}
    for _,producer in state.producers do
        local level=Catalog[producer.speciesId].tier
        counts[level]=(counts[level] or 0)+1
    end
    counts[tier]=(counts[tier] or 0)+amount
    local discoveries={string.format('tier_%02d',tier)}
    for level=1,config.MaxTier-1 do
        local count=counts[level] or 0
        local carry=math.floor(count/(config.MergeCount or 3))
        counts[level]=count%(config.MergeCount or 3)
        if carry>0 then
            counts[level+1]=(counts[level+1] or 0)+carry
            table.insert(discoveries,string.format('tier_%02d',level+1))
        end
    end
    local plan: {PlannedProducer}={}
    for level=config.MaxTier,1,-1 do
        for _=1,counts[level] or 0 do table.insert(plan,{speciesId=string.format('tier_%02d',level)}) end
    end
    local previous=table.clone(state.producers)
    table.sort(previous,function(a: any,b: any) return a.slot<b.slot end)
    local used: {[string]: boolean}={}
    -- Keep existing exact-tier producers first, including their schedule.
    for _,item in plan do
        for _,producer in previous do
            if not used[producer.id] and producer.speciesId==item.speciesId then
                item.sourceId=producer.id;used[producer.id]=true;break
            end
        end
    end
    -- A promotion can retain one constituent ID; all old token origins remain
    -- valid even when the corresponding producer is retired by this transaction.
    for _,item in plan do
        if item.sourceId then continue end
        for _,producer in previous do
            if not used[producer.id] and Catalog[producer.speciesId].tier<Catalog[item.speciesId].tier then
                item.sourceId=producer.id;used[producer.id]=true;break
            end
        end
    end
    return plan,(#state.producers+amount-#plan)/((config.MergeCount or 3)-1),discoveries
end
-- One price and eligibility decision for server purchases, pad signage, and HUD.
-- Buy100 checks capacity after automatic merging; other batches require room.
function Economy.purchaseQuote(config: any, state: any, quantity: string): PurchaseQuote
    if config.BuyPads[quantity]==nil or config.BuyUnlocks[quantity]==nil then
        return {amount=0,tier=1,cost=0,code='BadRequest'}
    end
    local amount=tonumber(quantity) :: number
    local tier=if quantity=='100' then math.clamp(state.rebirths,1,math.min(config.MaxTier,config.BuyMaxTier or config.MaxTier)) else 1
    local cost=Economy.buyCost(state.purchased or 0,amount,tier,config.MergeCount)
    local plan,mergedCount,discoveries=nil,nil,nil
    if quantity=='100' then plan,mergedCount,discoveries=bulkPlan(config,state,amount,tier) end
    local finalCount=if plan then #plan else #state.producers+amount
    local code=if not state.starterClaimed and quantity~='1' then 'ClaimStarter'
        elseif state.rebirths<config.BuyUnlocks[quantity] then 'Locked'
        elseif amount<1 or finalCount>config.Slots then 'PlotFull'
        elseif state.coinUnits<cost then 'InsufficientFunds' else 'OK'
    return {amount=amount,tier=tier,cost=cost,code=code,mergePlan=plan,mergedCount=mergedCount,discoveries=discoveries}
end
function Economy.count(items: {any}): number
    local total=0
    for _,item in items do total+=item.count or 1 end
    return total
end
function Economy.add(bag: {any},speciesId: string,value: number,count: number?)
    for _,item in bag do
        if item.speciesId==speciesId and item.baseCoinValue==value then item.count=(item.count or 1)+(count or 1); return end
    end
    table.insert(bag,{speciesId=speciesId,baseCoinValue=value,count=count or 1})
end
export type DepositGood={speciesId: string,baseCoinValue: number,count: number}
export type DepositQuote={code: string,inputCount: number,depositedCount: number,multiplierHundredths: number,nextCarry: number,goods: {DepositGood},creditUnits: number}
-- World events and earned obby bonuses apply when a bag enters the processor.
-- Carry fractional Minis across deposits; never round each bag down permanently.
function Economy.depositQuote(config: any,state: any): DepositQuote
    local multiplier=(state.eventHundredths or 100)+(state.obbyBonusHundredths or 0)
    local carry=state.depositCarry or 0
    local goods: {DepositGood}={}
    local inputCount,depositedCount,creditUnits=0,0,0
    for _,good in state.bag do
        local count=good.count or 1
        inputCount+=count
        local scaled=count*multiplier+carry
        local output=math.floor(scaled/100)
        carry=scaled%100
        if output>0 then
            table.insert(goods,{speciesId=good.speciesId,baseCoinValue=good.baseCoinValue,count=output})
            depositedCount+=output
            creditUnits+=output*good.baseCoinValue*(4+(state.rebirths or 0))*(state.cashMultiplier or 1)
        end
    end
    local reserved=(state.coinUnits or 0)+(state.soldUnits or 0)+creditUnits
    for _,sale in state.saleQueue do reserved+=sale.units*(sale.count or 1) end
    local code=if inputCount==0 then 'BagEmpty'
        elseif depositedCount+Economy.count(state.saleQueue)>config.SaleCapacity then 'QueueFull'
        elseif reserved>config.CoinCap then 'WalletFull' else 'OK'
    return {code=code,inputCount=inputCount,depositedCount=depositedCount,multiplierHundredths=multiplier,nextCarry=carry,goods=goods,creditUnits=creditUnits}
end
return Economy
