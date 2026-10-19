--!strict
local Players=game:GetService('Players')
local ReplicatedStorage=game:GetService('ReplicatedStorage')
local HttpService=game:GetService('HttpService')
local UserInputService=game:GetService('UserInputService')
local RunService=game:GetService('RunService')
local Marketplace=game:GetService('MarketplaceService')
local Shared=ReplicatedStorage:WaitForChild('Shared')
local Config=require(Shared:WaitForChild('Config'))
local Map=require(Shared:WaitForChild('MapSpec'))
local Tutorial=require(Shared:WaitForChild('Tutorial'))
local StarterPad=require(Shared:WaitForChild('StarterPad'))
local PassConfig=require(Shared:WaitForChild('PassConfig'))
local Controllers=script.Parent:WaitForChild('Controllers')
local UI=require(Controllers:WaitForChild('FarmUI'))
local Guide=require(Controllers:WaitForChild('TutorialGuide'))
local Effects=require(Controllers:WaitForChild('DepositEffects'))
local Discovery=require(Controllers:WaitForChild('DiscoveryEffects'))
local LuckyEffects=require(Controllers:WaitForChild('LuckyEffects'))
local CashEffects=require(Controllers:WaitForChild('CashEffects'))
local Conveyor=require(Controllers:WaitForChild('Conveyor'))
local PickupAudio=require(Controllers:WaitForChild('PickupAudio'))
local Locale=require(Controllers:WaitForChild('Locale'))
Locale.bind(workspace)
local Catalog=require(Shared:WaitForChild('CreatureCatalog'))
local player=Players.LocalPlayer
local view=UI.new(player:WaitForChild('PlayerGui'))
local guide=Guide.new()
local conveyor=Conveyor.new()
local showDiscovery=Discovery.new(view.gui)
local net=ReplicatedStorage:WaitForChild('FarmNetwork',15)
if not net then view:unavailable('Farm unavailable. Rejoin to try again.'); return end
local command=net:WaitForChild('Command') :: RemoteEvent
require(Controllers:WaitForChild('Sprint')).start(command,view.gui)
task.spawn(function()
    local assets=ReplicatedStorage:FindFirstChild('CharacterModels')
    if assets then pcall(function()game:GetService('ContentProvider'):PreloadAsync(assets:GetChildren())end) end
end)
local snapshot=net:WaitForChild('StateSnapshot') :: RemoteEvent
local result=net:WaitForChild('CommandResult') :: RemoteEvent
local state: any=nil
local pending: any=nil
local revision=-1
local sessionKey=nil
local receivedAt=0
local collectRetry: {[string]: number}={}
local shopInfo: {[string]: any}={}
local prompting=false
local luckyAnimating=false
local pickupCounts: {[string]: number}={}
local pickupScheduled=false
local lastClaimAt=-10
local lastClaimRevision=-1
local messages={BadRequest='That action could not be read.',Unavailable='Your farm is unavailable.',MissingToken='Already collected.',BagFull='Bag full - deposit your Minis.',TooFar='Move closer to your own pad or Mini.',BagEmpty='Your bag is empty.',WalletFull='Wallet limit reached. Your Minis are still safe.',PlotFull='Maximum amount of Brainrots reached. Merge your Brainrots.',InsufficientFunds='Not enough Coins. Deposit Minis, wait, then collect cash.',Locked='Rebirth to unlock this purchase amount.',ClaimStarter='Buy your first Tong Tong at BUY 1.',SameProducer='Choose two different Brainrots.',MissingProducer='That pair changed. Choose again.',Mismatch='Choose two matching Brainrots.',MaxTier='Highest tier reached!',NotAlive='Wait until your character respawns.',RequestLimit='Session action limit reached. Restart this preview.',RequestConflict='Request already used. Try again.',InvalidState='Your farm could not update.',NeedTier6='You need to own a Level 6 Brainrot to rebirth.',MaxRebirths='Maximum rebirths reached.',QueueFull='Processor full. Wait for space before depositing.',NothingReady='Your Minis are still selling. Check the timer.',MaxProcessor='Processor fully upgraded.'}
local function send(action: string,values: {string}?)
    if not state or pending or luckyAnimating or state.status~='Ready' then return end
    local args={HttpService:GenerateGUID(false)}
    if values then for _,v in values do table.insert(args,v) end end
    local miniSpecies={}; if action=='Deposit' then for _,mini in state.bag do table.insert(miniSpecies,mini.speciesId) end end
    pending={action=action,args=args,sent=os.clock(),count=#state.bag,miniSpecies=miniSpecies,discoveries=table.clone(state.discoveries)}
    if action=='Claim' then lastClaimAt=os.clock() end
    view:setPending(true); command:FireServer(action,args)
end
view.onBuy=function(quantity) send('Buy',{quantity}) end
view.onDeposit=function() send('Deposit') end
view.onClaim=function() send('Claim') end
view.onMerge=function(ids) send('Merge',ids) end
view.onRebirth=function() send('Rebirth') end
view.onUpgrade=function() send('Upgrade') end
view.onLucky=function()
    if state and state.lucky then send('OpenLucky',{state.lucky.id,tostring(Config.LuckyBaseUnits+#state.producers*Config.LuckyPerProducerUnits)}) end
end
view.onHome=function() if state then command:FireServer('Home',{}) end end
view.onPass=function(key)
    local pass=PassConfig[key]; local info=shopInfo[key]
    if prompting or not pass or pass.id<=0 or not info or not info.forSale then view:notice('This pass is coming soon.'); return end
    prompting=true
    local ok=pcall(Marketplace.PromptGamePassPurchase,Marketplace,player,pass.id)
    if not ok then prompting=false; view:notice('The Roblox shop is unavailable. Try again later.') end
end
Marketplace.PromptGamePassPurchaseFinished:Connect(function(who) if who==player then prompting=false end end)
task.spawn(function()
    for key,pass in PassConfig do
        if pass.id>0 then
            local ok,info=pcall(Marketplace.GetProductInfoAsync,Marketplace,pass.id,Enum.InfoType.GamePass)
            if ok then shopInfo[key]={price=info.PriceInRobux,forSale=info.IsForSale and type(info.PriceInRobux)=='number'} end
        end
    end
    view:setShopInfo(shopInfo)
    for _,part in workspace:GetDescendants() do
        local key=part:GetAttribute('PassKey')
        if key and part:IsA('BasePart') and part:FindFirstChild('Label') then
            local info=shopInfo[key]; part.Label.Text.Text=PassConfig[key].name..'\n'..(if info and info.forSale then info.price..' Robux' else 'Coming soon')
        end
    end
end)
snapshot.OnClientEvent:Connect(function(incoming)
    if incoming.status~='Ready' then state=nil; pending=nil; view:setPending(false); view:unavailable(incoming.reason or 'Waiting for a plot.'); return end
    if incoming.sessionKey~=sessionKey then sessionKey=incoming.sessionKey; revision=-1; pending=nil; collectRetry={}; lastClaimAt=-10; lastClaimRevision=-1; view:setPending(false) end
    if incoming.revision<revision then return end
    local oldMultiplier=state and state.cashMultiplier
    if state and not luckyAnimating and not (pending and pending.action=='OpenLucky') then for id in incoming.discoveries do if not state.discoveries[id] then showDiscovery(id) end end end
    revision=incoming.revision; state=incoming; receivedAt=os.clock()
    local active={}; for _,token in state.tokens do active[token.id]=true end
    for id in collectRetry do if not active[id] then collectRetry[id]=nil end end
    view:update(state)
    if oldMultiplier and state.cashMultiplier>oldMultiplier then view:offerUpgrade(state.cashMultiplier) end
end)
result.OnClientEvent:Connect(function(response)
    if response.action=='Collect' then
        if response.code=='OK' then
            PickupAudio.play()
            local species=response.speciesId or 'tier_01'
            pickupCounts[species]=(pickupCounts[species] or 0)+1
            if not pickupScheduled then
                pickupScheduled=true
                task.delay(.12,function()
                    for id,count in pickupCounts do view:pickup(count,id) end
                    pickupCounts={}; pickupScheduled=false
                end)
            end
        end
        return
    end
    if not pending or response.requestId~=pending.args[1] then return end
    local completed=pending
    pending=nil; view:setPending(false)
    if response.code~='OK' then view:notice(messages[response.code] or 'Try again.'); return end
    if response.action=='Claim' then
        lastClaimRevision=revision
        CashEffects.play(view.gui,player.Character,UI.coins(response.creditUnits or 0))
    elseif response.action=='Deposit' then
        Effects.play(view.gui,player.Character,completed.miniSpecies)
        view:notice('Deposited '..completed.count..' Minis! Watch the processor timer.')
    elseif response.action=='Buy' then view:notice('Brainrots added to your stack!')
    elseif response.action=='Upgrade' then view:notice('Processor upgraded! Your queue now sells faster.')
    elseif response.action=='OpenLucky' then
        view:close(); luckyAnimating=true
        LuckyEffects.play(view.gui,function()
            luckyAnimating=false
            showDiscovery(response.speciesId,not completed.discoveries[response.speciesId])
            view:notice('Lucky Block: '..Catalog[response.speciesId].name..'!')
        end)
    elseif response.action=='Rebirth' then view:close(); view:clearSelection(); view:notice('Rebirth complete! Your earnings and bulk-buy unlocks increased.')
    else view:clearSelection(); view:close(); view:notice('Merged! Tutorial complete - keep growing your farm!') end
end)
UserInputService.InputBegan:Connect(function(input,processed)
    if processed then return end
    if input.KeyCode==Enum.KeyCode.Escape then view:close()
    elseif input.KeyCode==Enum.KeyCode.M then view:toggleMerge()
    elseif input.KeyCode==Enum.KeyCode.E then view:act() end
end)
local function targetForGoal(pos: Vector3): Vector3?
    if not state or view:isOpen() then return nil end
    local goal=Tutorial.goal(state)
    if goal.kind=='Done' then return nil end
    local target=nil
    if goal.kind=='Buy' then target=Vector3.new(Config.BuyPads['1'],0,Config.BuyZ)
    elseif goal.kind=='Deposit' then target=Map.Sell
    elseif goal.kind=='Claim' or goal.kind=='Wait' then target=Map.Claim
    elseif goal.kind=='Merge' then target=Map.Merge
    else
        target=Vector3.new(0,0,Config.TrayZ); local closest=math.huge
        for _,t in state.tokens do local v=Vector3.new(t.x,t.y,t.z); local d=(state.plotCFrame:PointToWorldSpace(v*Map.PlotScale)-pos).Magnitude; if d<closest then closest=d; target=v end end
    end
    return state.plotCFrame:PointToWorldSpace(target*Map.PlotScale)
end
RunService.RenderStepped:Connect(function()
    if state then conveyor:update(state.serverNow+os.clock()-receivedAt) end
    local char=player.Character; local root=char and char:FindFirstChild('HumanoidRootPart') :: BasePart?
    guide:update(root and root.Position,if root then targetForGoal(root.Position) else nil)
    guide:showStarter(if state and not state.starterClaimed and not view:isOpen() then state.plotCFrame:PointToWorldSpace(Vector3.new(Config.BuyPads['1'],0,Config.BuyZ)*Map.PlotScale) else nil)
end)
task.spawn(function()
    while true do
        task.wait(.25)
        if not state then command:FireServer('State',{}); task.wait(1); continue end
        if pending and os.clock()-pending.sent>=3 then pending.sent=os.clock(); command:FireServer(pending.action,pending.args) end
        local char=player.Character; local root=char and char:FindFirstChild('HumanoidRootPart') :: BasePart?
        local humanoid=char and char:FindFirstChildOfClass('Humanoid')
        if not root or not humanoid or humanoid.Health<=0 then view:setContext(nil); continue end
        local foot=root.Position-Vector3.new(0,humanoid.HipHeight+root.Size.Y/2+(if humanoid.RigType==Enum.HumanoidRigType.R6 then 2 else 0),0)
        local pos=state.plotCFrame:PointToObjectSpace(foot)/Map.PlotScale
        if not view:isOpen() and not pending and StarterPad.shouldClaim(state,{x=pos.X,y=pos.Y,z=pos.Z},Config) then send('Buy',{'1'}) end
        -- The visible cash pad is 15 by 10 in logical plot coordinates.
        local onCashPad=math.abs(pos.X-Map.Claim.X)<=7.5 and math.abs(pos.Z-Map.Claim.Z)<=5 and pos.Y>=-.1 and pos.Y<=9 and (pos-Map.Claim).Magnitude<=Config.PadDistance
        if onCashPad and state.soldUnits>0 and not view:isOpen() and not pending and not luckyAnimating and revision>lastClaimRevision and os.clock()-lastClaimAt>=1.1 then send('Claim') end
        local kind: string?=nil; local value='1'; local nearest=Config.PadDistance
        local function consider(name: string,point: Vector3,key: string?)
            local d=(pos-point).Magnitude
            if d<nearest then nearest=d; kind=name; value=key or '1' end
        end
        consider('Deposit',Map.Sell); consider('Claim',Map.Claim); consider('Merge',Map.Merge); consider('Upgrade',Map.Upgrade); consider('FinishNow',Map.FinishNow)
        for quantity,x in Config.BuyPads do consider('Buy',Vector3.new(x,.15,Config.BuyZ),quantity) end
        for key,point in Map.PassPads do consider('Pass',point,key) end
        if state.lucky then consider('Lucky',Vector3.new(0,1.6,24)) end
        view.estimatedServerNow=state.serverNow+os.clock()-receivedAt
        view:setContext(kind,value)
        if view:isOpen() or #state.bag>=Config.BagCap or state.autoCollect then continue end
        local sent=0
        for _,t in state.tokens do
            if view.estimatedServerNow>=t.readyAt and (pos-Vector3.new(t.x,t.y,t.z)).Magnitude<=Config.CollectDistance and os.clock()-(collectRetry[t.id] or -10)>1 then
                collectRetry[t.id]=os.clock(); command:FireServer('Collect',{t.id}); sent+=1; if sent>=3 then break end
            end
        end
    end
end)
command:FireServer('State',{})
