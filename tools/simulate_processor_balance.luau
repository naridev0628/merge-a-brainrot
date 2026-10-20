-- Analytical full-utilization benchmark: $1/Mini, no boosts, unlimited backlog.
-- These are earning/payback lower bounds, not measured travel or player times.
local Config=require('../src/shared/Config')
local previousCosts={40,120,360,1000,3000,8000,20000,48000,100000,220000,480000,1000000,2200000,4800000,10000000,22000000,48000000,100000000,220000000,480000000,1000000000,1600000000,2600000000,4200000000,6800000000,11000000000,18000000000,29000000000,47000000000,76000000000,123000000000}
local samples={[1]=true,[2]=true,[3]=true,[5]=true,[6]=true,[11]=true,[17]=true,[21]=true,[27]=true,[31]=true}
local totalOld,totalNew=0,0
local earnOld,earnNew=0,0
local maxOld,maxNew,maxPayback=0,0,0
print('Rate -> next | old $ -> new $ | earnings seconds old -> new | incremental payback seconds old -> new')
for index,cost in Config.ProcessorCosts do
    local rate,nextRate=Config.ProcessorRates[index],Config.ProcessorRates[index+1]
    if not previousCosts[index] then
        print(string.format('Extended %d -> %d | $%.0f | %.2fs earning | %.2fs incremental payback',rate,nextRate,cost/4,cost/4/rate,cost/4/(nextRate-rate)))
        continue
    end
    local old,new=previousCosts[index]/4,cost/4
    local oldWait,newWait=old/rate,new/rate
    local oldPayback,newPayback=old/(nextRate-rate),new/(nextRate-rate)
    totalOld+=old;totalNew+=new;earnOld+=oldWait;earnNew+=newWait
    maxOld=math.max(maxOld,oldWait);maxNew=math.max(maxNew,newWait)
    maxPayback=math.max(maxPayback,newPayback)
    if samples[index] then
        print(string.format('%d -> %d | $%.0f -> $%.0f | %.2fs -> %.2fs | %.2fs -> %.2fs',rate,nextRate,old,new,oldWait,newWait,oldPayback,newPayback))
    end
end
print(string.format('Original 31 upgrades total spend: $%.0f -> $%.0f; ideal sequential earning time %.2fs -> %.2fs',totalOld,totalNew,earnOld,earnNew))
print(string.format('Worst earning time: %.2fs -> %.2fs; new worst incremental payback %.2fs',maxOld,maxNew,maxPayback))
