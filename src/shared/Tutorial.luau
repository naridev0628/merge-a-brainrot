--!strict
local env: any=getfenv()
local Economy: any
if env.script then Economy=(require :: any)(env.script.Parent.Economy) else Economy=require('./Economy') end
local Tutorial={}
function Tutorial.goal(s: any)
    if s.tutorialStep>=7 then return {kind='Done',title='Your farm, your rules!',detail='Grow your stack. Discover all six Brainrots.'} end
    if not s.starterClaimed then return {kind='Buy',title='Buy your first Brainrot!',detail='Walk onto BUY 1. Your starting $5 buys Tung Tung!'} end
    local seen={}
    for _,p in s.producers do
        if p.speciesId~='tier_06' and seen[p.speciesId] then return {kind='Merge',title='Merge two matching Brainrots!',detail='Walk onto MERGE. Matching pairs combine automatically!'} end
        seen[p.speciesId]=true
    end
    local price=Economy.buyCost(s.purchased or 0,1)
    if s.coinUnits>=price then return {kind='Buy',title='Buy another Tung Tung!',detail='$'..price/4 ..' - step onto BUY 1, then MERGE.'} end
    if s.soldUnits>0 then return {kind='Claim',title='Collect your cash!',detail='Your Minis sold. Pick up the coins at the green pad.'} end
    if #s.saleQueue>0 then return {kind='Wait',title='Your Minis are selling!',detail='Watch the processor. Collect cash when sales finish.'} end
    if Economy.count(s.bag)>=3 then return {kind='Deposit',title='Deposit your Minis!',detail='Take them to the deposit pad to start selling.'} end
    return {kind='Collect',title='Collect 3 mini Tung Tungs!',detail=tostring(Economy.count(s.bag))..'/3 Minis - walk over their tiny copies.'}
end
return Tutorial
