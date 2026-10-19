--!strict
local Core = require("../src/server/Domain/FarmCore")
local Config = require("../src/shared/Config")
local Catalog = require("../src/shared/CreatureCatalog")
local count = 0
local function eq(actual, expected, message)
    assert(actual == expected, (message or "value") .. ": expected " .. tostring(expected) .. ", got " .. tostring(actual))
end
local function test(name, fn)
    fn()
    count += 1
    print("PASS " .. name)
end
local function fixture(overrides)
    local config = table.clone(Config)
    config.SaleSeconds=0 -- Legacy economy tests isolate value math; sales.luau tests real waiting.
    config.ProcessorRates=nil; config.TransitSeconds=0 -- Timing is covered by sales/conveyor suites.
    for k, v in overrides or {} do config[k] = v end
    local core = Core.new(config, Catalog)
    local session=core:newSession(42,0,"session")
    core:dispatch(session,"Buy",{"starter"},{now=0,alive=true,position={x=Config.BuyPads['1'],y=3,z=Config.BuyZ}})
    session.cache={}; session.cacheCount=0
    return core,session,config
end
local function context(now, x, z)
    return {now = now or 0, alive = true, position = {x = x or 0, y = 3, z = z or 36}}
end
local function collect(core, s, token, now)
    return core:dispatch(s, "Collect", {token.id}, context(now, token.x, token.z))
end
local function command(core, s, action, id, args, now)
    if action=='Sell' then
        local deposited=core:dispatch(s,'Deposit',{id..'/deposit'},context(now,Config.SellX,Config.SellZ))
        if deposited.code~='OK' then return deposited end
        core:step(s,now or 0)
        return core:dispatch(s,'Claim',{id},context(now,Config.ClaimX,Config.ClaimZ))
    end
    local x = if action == "Buy" then Config.BuyPads["1"] elseif action == "Sell" then Config.SellX else 0
    local z = if action == "Sell" then Config.SellZ else Config.BuyZ
    return core:dispatch(s, action, {id, table.unpack(args or {})}, context(now, x, z))
end
local function fingerprint(s)
    -- Economic invariants, deliberately excluding rate limiter and attempted-ID sequence.
    local st = s.state
    local pieces = {tostring(st.coinUnits), tostring(st.revision), tostring(#st.bag), tostring(#st.tokens)}
    for _, p in st.producers do table.insert(pieces, p.id .. p.speciesId .. tostring(p.slot)) end
    return table.concat(pieces, "|")
end
test("starting $5 buys Tong Tong and three Minis fund the first merge", function()
    local core, s = fixture()
    eq(#s.state.producers, 1, "starter producer")
    eq(s.state.coinUnits, 0)
    core:step(s, 5.99); eq(#s.state.tokens, 0)
    for i = 1, 3 do
        core:step(s, i * 6)
        eq(#s.state.tokens, 1)
        eq(collect(core, s, s.state.tokens[1], i * 6).code, "OK")
    end
    eq(#s.state.bag, 3)
    eq(command(core, s, "Sell", "sell1", nil, 18).creditUnits, 24)
    eq(command(core, s, "Buy", "buy1", nil, 18).code, "OK")
    eq(s.state.coinUnits, 4)
    local a, b = s.state.producers[1], s.state.producers[2]
    eq(command(core, s, "Merge", "merge1", {a.id, b.id}, 18).code, "OK")
    eq(#s.state.producers, 1)
    eq(s.state.producers[1].speciesId, "tier_02")
    eq(s.state.producers[1].slot, 1)
    eq(s.state.producers[1].due, 24)
    eq(s.state.discoveries.tier_02, true)
    core:step(s, 24); eq(s.state.tokens[1].baseCoinValue, 5)
end)
test("duplicate collection and successful sale replay cannot grant extras", function()
    local core, s = fixture()
    core:step(s, 6); local token = s.state.tokens[1]
    eq(collect(core, s, token, 6).code, "OK")
    local before = fingerprint(s)
    eq(collect(core, s, token, 6).code, "MissingToken"); eq(fingerprint(s), before)
    command(core, s, "Sell", "sale", nil, 6)
    local sold = fingerprint(s)
    eq(command(core, s, "Sell", "sale", nil, 6).replayed, true)
    eq(fingerprint(s), sold)
    eq(command(core, s, "Buy", "sale", nil, 6).code, "RequestConflict")
    eq(fingerprint(s), sold)
end)
test("buy and merge retries preserve wallet and output identity", function()
    local core, s = fixture(); s.state.coinUnits = 160
    command(core, s, "Buy", "buy")
    local before = fingerprint(s)
    eq(command(core, s, "Buy", "buy").replayed, true); eq(fingerprint(s), before)
    local a, b = s.state.producers[1].id, s.state.producers[2].id
    command(core, s, "Merge", "merge", {a,b})
    local merged = fingerprint(s)
    eq(command(core, s, "Merge", "merge", {a,b}).replayed, true)
    eq(fingerprint(s), merged)
    eq(command(core, s, "Merge", "newmerge", {a,b}).code, "MissingProducer")
    eq(fingerprint(s), merged)
end)
test("same-ID foreign and mismatched merges leave full state unchanged", function()
    local core, s = fixture(); s.state.coinUnits = 160
    command(core, s, "Buy", "b1"); command(core, s, "Buy", "b2")
    local a, b = s.state.producers[1].id, s.state.producers[2].id
    for _, pair in {{a,a},{a,"foreign"}} do
        local before = fingerprint(s)
        assert(command(core,s,"Merge","bad"..pair[2],pair).code ~= "OK")
        eq(fingerprint(s),before)
    end
    command(core,s,"Merge","good",{a,b})
    local before = fingerprint(s)
    eq(command(core,s,"Merge","mismatch",{s.state.producers[1].id,s.state.producers[2].id}).code,"Mismatch")
    eq(fingerprint(s),before)
end)
test("dead distant malformed and nonfinite requests are rejected", function()
    local core,s=fixture(); s.state.coinUnits=80; core:step(s,6)
    local before=fingerprint(s)
    eq(core:dispatch(s,"Buy",{"far"},context(6,1000,1000)).code,"TooFar")
    local dead=context(6,18,34); dead.alive=false
    eq(core:dispatch(s,"Buy",{"dead"},dead).code,"NotAlive")
    local nan=context(6,0/0,34)
    eq(core:dispatch(s,"Buy",{"nan"},nan).code,"NotAlive")
    for _, args in {{{}}, {string.rep("x",129)}, {"ok",99}, {}} do
        eq(core:dispatch(s,"Buy",args,context()).code,"BadRequest")
    end
    eq(core:dispatch(s,"Collect",{"foreign"},context()).code,"MissingToken")
    eq(fingerprint(s),before)
end)
test("full bag leaves token; coin overflow leaves entire bag",function()
    local core,s=fixture()
    for i=1,96 do table.insert(s.state.bag,{speciesId="tier_01",baseCoinValue=2}) end
    core:step(s,6); local token=s.state.tokens[1]; local before=fingerprint(s)
    eq(collect(core,s,token,6).code,"BagFull"); eq(fingerprint(s),before)
    s.state.coinUnits=Config.CoinCap
    before=fingerprint(s)
    eq(command(core,s,"Sell","overflow").code,"WalletFull"); eq(fingerprint(s),before)
end)
test("full plot rejects purchase without charge and merge frees a slot",function()
    local core,s=fixture({Slots=12}); s.state.coinUnits=2000
    for i=1,11 do eq(command(core,s,"Buy","b"..i).code,"OK") end
    local before=fingerprint(s)
    eq(command(core,s,"Buy","full").code,"PlotFull"); eq(fingerprint(s),before)
    command(core,s,"Merge","m",{s.state.producers[1].id,s.state.producers[2].id})
    eq(command(core,s,"Buy","full").code,"OK") -- failed requests are not remembered
    eq(s.state.producers[#s.state.producers].slot,12)
end)
test("stall catchup and capped production discard backlog",function()
    local core,s=fixture()
    core:step(s,600); eq(#s.state.tokens,2); eq(s.state.producers[1].due,606)
    for t=606,624,6 do core:step(s,t) end
    eq(#s.state.tokens,6)
    core:step(s,1000); eq(#s.state.tokens,8)
    core:step(s,2000); eq(#s.state.tokens,8)
    collect(core,s,s.state.tokens[1],2000)
    core:step(s,2000.25); eq(#s.state.tokens,7)
    core:step(s,2006); eq(#s.state.tokens,8)
end)
test("retired producer goods remain collectible with captured value",function()
    local core,s=fixture(); s.state.coinUnits=80
    command(core,s,"Buy","buy"); core:step(s,6)
    local token=s.state.tokens[1]
    command(core,s,"Merge","merge",{s.state.producers[1].id,s.state.producers[2].id},6)
    eq(#s.state.tokens,2); eq(collect(core,s,token,6).code,"OK")
    eq(command(core,s,"Sell","sell",nil,6).creditUnits,8)
end)
test("max tier merge request cache cap and closing lifecycle reject safely",function()
    local core,s=fixture({RequestCap=1}); s.state.coinUnits=160
    command(core,s,"Buy","first")
    local before=fingerprint(s)
    eq(command(core,s,"Buy","second").code,"RequestLimit"); eq(fingerprint(s),before)
    s.phase="Closing"
    eq(command(core,s,"Buy","first").code,"Unavailable")
    core:step(s,100); eq(fingerprint(s),before)
    local c,t=fixture(); t.state.coinUnits=80; command(c,t,"Buy","b")
    t.state.producers[1].speciesId="tier_06"; t.state.producers[2].speciesId="tier_06"
    before=fingerprint(t)
    eq(command(c,t,"Merge","m",{t.state.producers[1].id,t.state.producers[2].id}).code,"MaxTier")
    eq(fingerprint(t),before)
end)
test("independent sessions cannot consume each other's producers or tokens",function()
    local core,a=fixture(); local b=core:newSession(43,0,"other")
    command(core,b,'Buy','starter')
    core:step(a,6); core:step(b,6)
    local before=fingerprint(b)
    eq(collect(core,b,a.state.tokens[1],6).code,"MissingToken")
    eq(command(core,b,"Merge","foreign",{a.state.producers[1].id,b.state.producers[1].id}).code,"MissingProducer")
    eq(fingerprint(b),before)
end)
test("token bucket limits bursts and replenishes at the configured rate",function()
    local Limiter=require("../src/server/Domain/RateLimiter")
    local buckets={}
    eq(Limiter.allow(buckets,"Buy",0,3,2),true)
    eq(Limiter.allow(buckets,"Buy",0,3,2),true)
    eq(Limiter.allow(buckets,"Buy",0,3,2),false)
    eq(Limiter.allow(buckets,"Buy",0.2,3,2),false)
    eq(Limiter.allow(buckets,"Buy",0.4,3,2),true)
    eq(Limiter.allow(buckets,"Sell",0.4,3,2),true)
    eq(Limiter.allow(buckets,"Buy",100,3,2),true)
    eq(Limiter.allow(buckets,"Buy",100,3,2),true)
    eq(Limiter.allow(buckets,"Buy",100,3,2),false)
end)

test("earned income reaches tier three without grants",function()
    local core,s=fixture()
    local now=0
    local sequence=0
    local function earnPurchase()
        while s.state.coinUnits<80 do
            now+=6; core:step(s,now)
            for _,token in table.clone(s.state.tokens) do
                for _,live in s.state.tokens do
                    if live.id==token.id then eq(collect(core,s,live,now).code,"OK"); break end
                end
            end
            sequence+=1
            eq(command(core,s,"Sell","sale"..sequence,nil,now).code,"OK")
        end
        sequence+=1
        eq(command(core,s,"Buy","purchase"..sequence,nil,now).code,"OK")
    end
    earnPurchase()
    eq(command(core,s,"Merge","merge1",{s.state.producers[1].id,s.state.producers[2].id},now).code,"OK")
    earnPurchase(); earnPurchase()
    local inputs={}
    for _,p in s.state.producers do if p.speciesId=="tier_01" then table.insert(inputs,p.id) end end
    eq(command(core,s,"Merge","merge2",inputs,now).code,"OK")
    eq(command(core,s,"Merge","merge3",{s.state.producers[1].id,s.state.producers[2].id},now).code,"OK")
    eq(#s.state.producers,1); eq(s.state.producers[1].speciesId,"tier_03")
    eq(s.state.discoveries.tier_03,true)
end)
print("ALL " .. count .. " TESTS PASSED")
