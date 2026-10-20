-- Run from the repository: ./.tools/luau/luau.exe tools/simulate_progression.luau
-- Observational active-player simulation: exercises real Core commands, with
-- real queues, production caps, conveyor readiness, balances and request IDs.
local Core=require('../src/server/Domain/FarmCore')
local Config=require('../src/shared/Config')
local Catalog=require('../src/shared/CreatureCatalog')
local Economy=require('../src/shared/Economy')

local function clock(seconds)
    return string.format('%02d:%02d:%05.2f',math.floor(seconds/3600),math.floor(seconds/60)%60,seconds%60)
end
local function simulate(label,continueGrowing,useUpgrades)
    local core=Core.new(Config,Catalog,function() return 1 end) -- No Lucky windfalls.
    local session=core:newSession(101,0,'pace-'..label)
    local now=0; local serial=0; local collected=0; local purchased=0; local merges=0
    local grossUnits=0; local depositWait=0; local groundFullTicks=0
    local upgradeUnits=0; local upgradeCount=0
    local milestones={}; local failure=nil
    local function record()
        for _,producer in session.state.producers do
            local tier=Catalog[producer.speciesId].tier
            if not milestones[tier] then
                milestones[tier]=now
                print(label..' tier '..tier..' at '..clock(now)..' wallet $'..session.state.coinUnits/4 ..' producers '..#session.state.producers)
            end
        end
    end
    local function advance(seconds)
        local untilTime=now+seconds
        while now<untilTime do
            now=math.min(untilTime,now+Config.Cadence)
            core:step(session,now)
            if #session.state.tokens==Config.GroundCap then groundFullTicks+=1 end
        end
    end
    local function command(action,args,x,z)
        serial+=1
        local arguments={label..'-request-'..serial}
        for _,arg in args or {} do table.insert(arguments,arg) end
        if action=='Collect' then arguments={args[1]} end
        local result=core:dispatch(session,action,arguments,{now=now,alive=true,position={x=x,y=3,z=z}})
        if result.code=='RequestLimit' then failure='RequestLimit' end
        if result.code=='OK' then
            if action=='Buy' then purchased+=1 end
            if action=='AutoMerge' then merges+=result.count or 0 end
            if action=='Claim' then grossUnits+=result.creditUnits end
            record()
        end
        return result.code
    end
    assert(command('Buy',{'1'},Config.BuyPads['1'],Config.BuyZ)=='OK')
    advance(2) -- Buy pad to tray.
    local firstHarvest=true
    while now<48*3600 and not failure do
        -- One aura request collects the currently settled pile at walking distance.
        local count=0
        repeat
            local before=Economy.count(session.state.bag)
            command('CollectNearby',{},0,Config.TrayZ)
            local picked=Economy.count(session.state.bag)-before
            count+=picked; collected+=picked
            advance(Config.Cadence)
        until (firstHarvest and count>=3) or (not firstHarvest and count>0)
        firstHarvest=false
        advance(2) -- Tray to processor intake.
        local blockedThisTrip=Economy.count(session.state.saleQueue)>Config.ProcessorRates[session.state.processorLevel+1]*8
        while Economy.count(session.state.bag)+Economy.count(session.state.saleQueue)>Config.SaleCapacity do
            advance(Config.Cadence); depositWait+=Config.Cadence; blockedThisTrip=true
        end
        assert(command('Deposit',{},Config.SellX,Config.SellZ)=='OK' or failure)
        advance(2) -- Intake to payout. Claim only money actually processed.
        if session.state.soldUnits>0 then
            assert(command('Claim',{},Config.ClaimX,Config.ClaimZ)=='OK' or failure)
        end
        if failure then break end
        if milestones[6] and session.state.coinUnits>=Config.RebirthBase then
            local tiers={0,0,0,0,0,0}
            for _,producer in session.state.producers do tiers[Catalog[producer.speciesId].tier]+=1 end
            print(label..' pre-rebirth wallet $'..session.state.coinUnits/4 ..' | producers '..#session.state.producers..' | tiers1-6 '..table.concat(tiers,','))
            advance(2) -- Move to rebirth/interaction station.
            assert(command('Rebirth',{},0,36)=='OK')
            print(label..' FIRST REBIRTH '..clock(now)..' | bought '..purchased..' | merges '..merges..' | collected '..collected..' | gross $'..grossUnits/4 ..' | deposit-wait '..clock(depositWait)..' | ground-cap seconds '..groundFullTicks*Config.Cadence..' | upgrades '..upgradeCount..' costing $'..upgradeUnits/4 ..' | cached requests '..session.cacheCount)
            return {label=label,seconds=now,milestones=milestones,purchased=purchased,merges=merges,collected=collected,grossUnits=grossUnits,depositWait=depositWait}
        end
        -- The player saw a full intake this trip. Spend earned cash on the next
        -- affordable processor upgrade before buying more producers. One upgrade
        -- per affected trip lets the next circuit expose whether it was enough.
        local upgradeCost=Config.ProcessorCosts[session.state.processorLevel+1]
        if useUpgrades and (blockedThisTrip or (milestones[2] and session.state.processorLevel==0)) and upgradeCost and session.state.coinUnits>=upgradeCost then
            advance(2) -- Additional payout-to-upgrade station visit.
            assert(command('Upgrade',{},Config.UpgradeX,Config.UpgradeZ)=='OK' or failure)
            if not failure then
                upgradeUnits+=upgradeCost; upgradeCount+=1
                print(label..' processor '..Config.ProcessorRates[session.state.processorLevel+1]..'/s at '..clock(now)..' paid $'..upgradeCost/4 ..' wallet $'..session.state.coinUnits/4)
            end
            advance(Config.Cadence)
        end
        advance(2) -- Payout to the single-buy pad.
        if continueGrowing or not milestones[6] then
            while session.state.coinUnits>=Economy.buyCost(session.state.purchased,1) and #session.state.producers<Config.Slots do
                assert(command('Buy',{'1'},Config.BuyPads['1'],Config.BuyZ)=='OK' or failure)
                if failure then break end
                advance(.8) -- Step off and return to the buy pad.
            end
        end
        advance(2) -- Buy pad to merge area.
        if continueGrowing or not milestones[6] then
            command('AutoMerge',{},Config.MergeX,Config.MergeZ)
            advance(.6)
        end
        advance(2) -- Merge area back to tray.
    end
    error(label..' did not reach rebirth: '..tostring(failure or '48-hour horizon')..' at '..clock(now)..', wallet $'..session.state.coinUnits/4 ..', requests '..session.cacheCount)
end

print('Live config: buy $'..Config.BuyUnits/4 ..', interval '..Config.Interval..'s, transit '..Config.TransitSeconds..'s, processor '..Config.ProcessorRates[1]..'/s, rebirth $'..Config.RebirthBase/4)
-- Saving without expansion is intentionally omitted from the active growth benchmark.
-- Growth-only results are retained in the audit; this run tests saving for rebirth.
simulate('save-for-rebirth-with-upgrades',false,true)
