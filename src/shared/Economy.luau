--!strict
local Economy={}
-- Quarter-dollar units. First two purchases cost $5; then +$1 per purchase.
function Economy.buyCost(purchased: number, amount: number, tier: number?): number
    local total=0
    for offset=0,amount*2^((tier or 1)-1)-1 do total+=20+4*math.max(0,purchased+offset-1) end
    return total
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
