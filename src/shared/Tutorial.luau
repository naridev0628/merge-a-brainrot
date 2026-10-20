--!strict
local env: any=getfenv()
local Economy: any
local Config: any
local Catalog: any
if env.script then
    Economy=(require :: any)(env.script.Parent.Economy)
    Config=(require :: any)(env.script.Parent.Config)
    Catalog=(require :: any)(env.script.Parent.CreatureCatalog)
else
    Economy=require('./Economy');Config=require('./Config');Catalog=require('./CreatureCatalog')
end
local Tutorial={}
function Tutorial.goal(s: any)
    if s.tutorialStep>=7 then return {kind='Done',title='Your farm, your rules!',detail='Grow your stack. Discover all '..Config.MaxTier..' Brainrots.'} end
    if not s.starterClaimed then return {kind='Buy',title='Buy your first Brainrot!',detail='Walk onto BUY 1. Your starting $5 buys Tung Tung!'} end
    local seen: {[string]: number}={}
    for _,p in s.producers do
        if Catalog[p.speciesId] and Catalog[p.speciesId].nextId then
            seen[p.speciesId]=(seen[p.speciesId] or 0)+1
            if seen[p.speciesId]>=Config.MergeCount then
                return {kind='Merge',title='Merge three matching Brainrots!',detail='Walk onto MERGE. Three matching Brainrots become one!'}
            end
        end
    end
    local price=Economy.buyCost(s.purchased or 0,1)
    if s.coinUnits>=price then return {kind='Buy',title='Buy another Tung Tung!',detail='$'..price/4 ..' - buy until you have three matching Brainrots.'} end
    if s.soldUnits>0 then return {kind='Claim',title='Collect your cash!',detail='Your Minis sold. Pick up the coins at the green pad.'} end
    if #s.saleQueue>0 then return {kind='Wait',title='Your Minis are selling!',detail='Watch the processor. Collect cash when sales finish.'} end
    if Economy.count(s.bag)>=3 then return {kind='Deposit',title='Deposit your Minis!',detail='Take them to the deposit pad to start selling.'} end
    return {kind='Collect',title='Collect 3 mini Tung Tungs!',detail=tostring(Economy.count(s.bag))..'/3 Minis - walk nearby to collect them, even as they fall.'}
end
return Tutorial
