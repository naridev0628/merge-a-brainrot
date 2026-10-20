--!strict
-- One pool serves both the authoritative roll and the card's reward rows.
-- Near the catalog ceiling shift the entire window down, preserving three
-- distinct rewards and their advertised 75/20/5 probabilities.
local env: any=getfenv()
local Catalog: any
if env.script then Catalog=(require :: any)(env.script.Parent.CreatureCatalog)
else Catalog=(require :: (string) -> unknown)('./CreatureCatalog') end
local Rewards={}
export type Reward = {tier: number, speciesId: string, chance: number}
function Rewards.pool(config: any,baseTier: number): {Reward}
    local first=math.clamp(baseTier,math.min(2,config.MaxTier-2),config.MaxTier-2)
    local pool={}
    for offset,chance in {75,20,5} do
        local tier=first+offset-1
        table.insert(pool,{tier=tier,speciesId=string.format('tier_%02d',tier),chance=chance})
    end
    return pool
end
function Rewards.choose(config: any,baseTier: number,roll: number): Reward
    return Rewards.pool(config,baseTier)[if roll<.75 then 1 elseif roll<.95 then 2 else 3]
end
function Rewards.cost(config: any,state: any): number
    local first=Rewards.pool(config,if state.lucky then state.lucky.baseTier else 2)[1]
    -- Follow actual quantity rather than an obsolete exponential tier curve.
    -- One producer pays ten base seconds of the lowest reward's output.
    -- Price the clamped pool so ceiling blocks never overcharge identical odds.
    local ratio=Catalog[first.speciesId].production/Catalog.tier_02.production
    return (config.LuckyBaseUnits+#state.producers*config.LuckyPerProducerUnits)*ratio
end
return table.freeze(Rewards)
