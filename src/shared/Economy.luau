--!strict
local Economy={}
-- Quarter-dollar units. First two purchases cost $5; then +$1 per purchase.
function Economy.buyCost(purchased: number, amount: number, tier: number?): number
    local total=0
    for offset=0,amount*2^((tier or 1)-1)-1 do total+=20+4*math.max(0,purchased+offset-1) end
    return total
end
export type PurchaseQuote = {amount: number, tier: number, cost: number, code: string}
-- One price and eligibility decision for server purchases, pad signage, and HUD.
-- Fixed batches require full room; Buy50 fills only the remaining spaces.
function Economy.purchaseQuote(config: any, state: any, quantity: string): PurchaseQuote
    if config.BuyPads[quantity]==nil or config.BuyUnlocks[quantity]==nil then
        return {amount=0,tier=1,cost=0,code='BadRequest'}
    end
    local amount=if quantity=='50' then math.max(0,math.min(50,config.Slots-#state.producers)) else tonumber(quantity) :: number
    local tier=if quantity=='50' then math.clamp(state.rebirths,1,config.MaxTier) else 1
    local cost=Economy.buyCost(state.purchased or 0,amount,tier)
    local code=if not state.starterClaimed and quantity~='1' then 'ClaimStarter'
        elseif state.rebirths<config.BuyUnlocks[quantity] then 'Locked'
        elseif amount<1 or #state.producers+amount>config.Slots then 'PlotFull'
        elseif state.coinUnits<cost then 'InsufficientFunds' else 'OK'
    return {amount=amount,tier=tier,cost=cost,code=code}
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
return Economy
