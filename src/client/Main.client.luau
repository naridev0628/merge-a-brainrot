--!strict
local Players=game:GetService('Players')
local ReplicatedStorage=game:GetService('ReplicatedStorage')
local HttpService=game:GetService('HttpService')
local UserInputService=game:GetService('UserInputService')
local RunService=game:GetService('RunService')
local Marketplace=game:GetService('MarketplaceService')
local Shared=ReplicatedStorage:WaitForChild('Shared')
local Config=require(Shared:WaitForChild('Config'))
local PickupGeometry=require(Shared:WaitForChild('PickupGeometry'))
local MiniMotion=require(Shared:WaitForChild('MiniMotion'))
local PadTargeting=require(Shared:WaitForChild('PadTargeting'))
local PadHold=require(Shared:WaitForChild('PadHold'))
local Economy=require(Shared:WaitForChild('Economy'))
local LuckyRewards=require(Shared:WaitForChild('LuckyRewards'))
local Map=require(Shared:WaitForChild('MapSpec'))
local Tutorial=require(Shared:WaitForChild('Tutorial'))
local PassConfig=require(Shared:WaitForChild('PassConfig'))
local Controllers=script.Parent:WaitForChild('Controllers')
local PurchaseEffects=require(Controllers:WaitForChild('PurchaseEffects'))
local LeaderboardFooter=require(Controllers:WaitForChild('LeaderboardFooter'))
local UI=require(Controllers:WaitForChild('FarmUI'))
local Guide=require(Controllers:WaitForChild('TutorialGuide'))
local Effects=require(Controllers:WaitForChild('DepositEffects'))
local Discovery=require(Controllers:WaitForChild('DiscoveryEffects'))
local LuckyEffects=require(Controllers:WaitForChild('LuckyEffects'))
local CashEffects=require(Controllers:WaitForChild('CashEffects'))
local UpgradeEffects=require(Controllers:WaitForChild('UpgradeEffects'))
require(Controllers:WaitForChild('LuckyCarryPose')).start()
local Conveyor=require(Controllers:WaitForChild('Conveyor'))
local PickupAudio=require(Controllers:WaitForChild('PickupAudio'))
local FeedbackAudio=require(Controllers:WaitForChild('FeedbackAudio'))
local MusicController=require(Controllers:WaitForChild('MusicController'))
local ObbyHUD=require(Controllers:WaitForChild('ObbyHUD'))
local MultiplierCue=require(Controllers:WaitForChild('MultiplierCue'))
local PadLabels=require(Controllers:WaitForChild('PadLabels'))
local PadFeedback=require(Controllers:WaitForChild('PadFeedback'))
local CashPadCounter=require(Controllers:WaitForChild('CashPadCounter'))
local Locale=require(Controllers:WaitForChild('Locale'))
Locale.bind(workspace)
local Catalog=require(Shared:WaitForChild('CreatureCatalog'))
local player=Players.LocalPlayer
local view=UI.new(player:WaitForChild('PlayerGui'))
local multiplierCue=MultiplierCue.new(view)
local padLabels=PadLabels.new()
local padFeedback=PadFeedback.new()
local cashPadCounter=CashPadCounter.new()
local obbyHUD=ObbyHUD.new()
view.gui.Destroying:Connect(function() obbyHUD:destroy(); padLabels:destroy(); padFeedback:destroy(); cashPadCounter:destroy() end)
MusicController.start()
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
local shopInfo: {[string]: any}={}
local prompting=false
local pickupCounts: {[string]: number}={}
local pickupScheduled=false
local heldPad=PadHold.new()
local lastAuraAt=-10

local lastLuckyAt=-10
local droppedLucky: string?=nil
local revealingLuckySpecies: string?=nil
local messages={BadRequest='That action could not be read.',Unavailable='Your farm is unavailable.',MissingToken='Already collected.',BagFull='Bag full - deposit your Minis.',TooFar='Move closer to your own pad or Mini.',BagEmpty='Your bag is empty.',WalletFull='Wallet limit reached. Your Minis are still safe.',PlotFull='Maximum amount of Brainrots reached. Merge your Brainrots.',InsufficientFunds='Not enough Coins. Deposit Minis, wait, then collect cash.',Locked='Rebirth to unlock this purchase amount.',ClaimStarter='Buy your first Tung Tung at BUY 1.',SameProducer='Choose three different Brainrots.',MissingProducer='That group changed. Choose again.',Mismatch='Choose three matching Brainrots.',MaxTier='Highest tier reached!',NotAlive='Wait until your character respawns.',RequestLimit='Session action limit reached. Restart this preview.',RequestConflict='Request already used. Try again.',InvalidState='Your farm could not update.',NeedTier6='You need to own a Level 6 Brainrot to rebirth.',MaxRebirths='Maximum rebirths reached.',QueueFull='Processor full. Wait for space before depositing.',NothingReady='Your Minis are still selling. Check the timer.',MaxProcessor='Processor fully upgraded.'}
local function send(action: string,values: {string}?)
    if not state or pending or state.status~='Ready' then return end
    local args={HttpService:GenerateGUID(false)}
    if values then for _,v in values do table.insert(args,v) end end
    local miniSpecies={}; if action=='Deposit' then for _,mini in state.bag do for _=1,math.min(3,mini.count or 1) do table.insert(miniSpecies,mini.speciesId) end end end
    pending={action=action,args=args,sent=os.clock(),count=Economy.count(state.bag),miniSpecies=miniSpecies,discoveries=table.clone(state.discoveries),
        luckyBaseTier=if action=='OpenLucky' and state.lucky then state.lucky.baseTier else nil}
    -- Dispatch before refreshing panels; UI work must not delay the request.
    command:FireServer(action,args); pending.dispatchedAt=os.clock(); view:setPending(true)
end
view.onBuy=function(quantity) send('Buy',{quantity}) end
view.onDeposit=function() send('Deposit') end
view.onClaim=function() send('Claim') end
view.onMerge=function() view:notice('Walk onto the MERGE pad to combine matching Brainrots.') end
view.onRebirth=function() send('Rebirth') end
view.onUpgrade=function() send('Upgrade') end
view.onLucky=function()
    if state and state.lucky then send('OpenLucky',{state.lucky.id,tostring(LuckyRewards.cost(Config,state))}) end
end
view.onDropLucky=function()
    if state and state.lucky and not pending then droppedLucky=state.lucky.id;send('DropLucky',{state.lucky.id}) end
end
view.onDiscardLucky=function()
    if state and state.lucky then send('DiscardLucky',{state.lucky.id}) end
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
            local info=shopInfo[key]
            part.Label.Text.Text=PassConfig[key].name
            local price=part.Label:FindFirstChild('Price')
            if price then price.Text=if info and info.forSale then info.price..' Robux' else 'Coming soon' end
        end
    end
end)
snapshot.OnClientEvent:Connect(function(incoming)
    if incoming.status~='Ready' then state=nil; pending=nil; obbyHUD:clear(); multiplierCue:clear(); padLabels:clear(); view:setPending(false); view:unavailable(incoming.reason or 'Waiting for a plot.'); return end
    if incoming.sessionKey~=sessionKey then sessionKey=incoming.sessionKey; revision=-1; pending=nil; heldPad=PadHold.new(); view:setPending(false) end
    if incoming.revision<revision then return end
    local oldMultiplier=state and state.cashMultiplier
    local oldHeldId=state and state.lucky and state.lucky.held and state.lucky.id
    if state and not (pending and pending.action=='OpenLucky') then for id in incoming.discoveries do if not state.discoveries[id] and id~=revealingLuckySpecies then showDiscovery(id) end end end
    revision=incoming.revision; state=incoming; receivedAt=os.clock()
    view:update(state)
    multiplierCue:receive(state,receivedAt)
    padLabels:setPlot(state.plotId)
    padFeedback:setPlot(state.plotId)
    cashPadCounter:setState(state)
    if state.lucky and state.lucky.held and state.lucky.id~=oldHeldId then view:open('Lucky')
    elseif view:isLuckyOpen() and (not state.lucky or not state.lucky.held) then view:close() end
    LeaderboardFooter.update(state)
    if oldMultiplier and state.cashMultiplier>oldMultiplier then view:offerUpgrade(state.cashMultiplier) end
    if obbyHUD:receive(state,receivedAt) then
        FeedbackAudio.play('Upgrade')
        view:notice('Obby complete! +0.25x Minis for 5 minutes.')
    end
end)
result.OnClientEvent:Connect(function(response)
    if response.action=='Collect' or response.action=='CollectNearby' then
        if response.code=='OK' then
            PickupAudio.play()
            for species,count in response.counts or {[response.speciesId or 'tier_01']=response.count or 1} do pickupCounts[species]=(pickupCounts[species] or 0)+count end
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
    if RunService:IsStudio() and completed.padDetectedAt then
        view.gui:SetAttribute('LastPadServerConfirmationMs',(os.clock()-completed.padDetectedAt)*1000)
    end
    pending=nil; view:setPending(false)
    if completed.holdKey and completed.holdKey==heldPad.key and response.code~='OK' then
        -- A moving boundary or newly earned cash must not require stepping off.
        if response.code=='TooFar' or (response.code=='InsufficientFunds' and completed.action=='Buy') then
            PadHold.retry(heldPad,os.clock()); return
        end
        PadHold.stop(heldPad)
    end
    if response.code~='OK' then
        if response.code~='InsufficientFunds' and response.action~='PickupLucky' then view:notice(messages[response.code] or 'Try again.') end
        return
    end
    FeedbackAudio.play(response.action)
    if response.action=='Claim' then
        if state then
            local remaining=if state.revision>=(response.revision or 0) then state.soldUnits
                else math.max(0,(state.soldUnits or 0)-(response.creditUnits or 0))
            cashPadCounter:claim(state.plotId,response.creditUnits or 0,remaining,os.clock(),response.revision)
        end
        CashEffects.play(view.gui,player.Character,UI.coins(response.creditUnits or 0))
    elseif response.action=='Deposit' then
        Effects.play(view.gui,player.Character,completed.miniSpecies)
        local function grouped(value: number): string
            local result=tostring(value)
            while true do
                local nextText,changed=result:gsub('^(%d+)(%d%d%d)','%1,%2')
                result=nextText
                if changed==0 then return result end
            end
        end
        local inputCount=response.inputCount or completed.count
        local depositedCount=response.depositedCount or inputCount
        local multiplier=(response.multiplierHundredths or 100)/100
        view:notice('Deposited '..grouped(inputCount)..' Minis ('..string.format('%.2f',multiplier)..'× → '..grouped(depositedCount)..')')
    elseif response.action=='Buy' then PurchaseEffects.play(view.gui,response.count or 1,response.speciesId or 'tier_01')
    elseif response.action=='Upgrade' then if state then UpgradeEffects.play(state.plotCFrame) end
    elseif response.action=='PickupLucky' then
        view:open('Lucky')
    elseif response.action=='DropLucky' or response.action=='DiscardLucky' then view:close()
    elseif response.action=='OpenLucky' then
        view:close(); revealingLuckySpecies=response.speciesId
        LuckyEffects.play(view.gui,function()
            revealingLuckySpecies=nil
            showDiscovery(response.speciesId,not completed.discoveries[response.speciesId])
        end,completed.luckyBaseTier)
    elseif response.action=='Rebirth' then view:close(); view:clearSelection(); view:notice('Rebirth complete! Your earnings and bulk-buy unlocks increased.')
    else view:clearSelection(); if not view:isLuckyOpen() and not view:isSettingsOpen() then view:close() end; view:notice('Merged '..(response.count or 1)..' groups of three!') end
end)
UserInputService.InputBegan:Connect(function(input,processed)
    if input.KeyCode==Enum.KeyCode.Escape and view:isSettingsOpen() then view:close(); return end
    if processed then return end
    if input.KeyCode==Enum.KeyCode.Escape then if view:isLuckyOpen() then view.onDropLucky() else view:close() end
    end
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
    local char=player.Character; local root=char and char:FindFirstChild('HumanoidRootPart') :: BasePart?
    local humanoid=char and char:FindFirstChildOfClass('Humanoid')
    if state and root and humanoid and humanoid.Health>0 then
        local foot=root.Position-Vector3.new(0,humanoid.HipHeight+root.Size.Y/2+(if humanoid.RigType==Enum.HumanoidRigType.R6 then 2 else 0),0)
        local pos=state.plotCFrame:PointToObjectSpace(foot)/Map.PlotScale
        local target=PadTargeting.resolve(Config,Catalog,Map,state,{x=pos.X,y=pos.Y,z=pos.Z})
        PadHold.update(heldPad,target.key,os.clock())
        if not pending and not view:isOpen() and PadHold.ready(heldPad,os.clock()) and target.action=='Buy' and Economy.purchaseQuote(Config,state,target.values[1]).code=='InsufficientFunds' then
            -- Keep the physical hold alive while waiting for replicated income.
            target.action=nil
        end
        if not view:isOpen() and not pending and target.action and PadHold.ready(heldPad,os.clock()) then
            local detectedAt=os.clock()
            -- Acknowledge locally on the entry frame; rewards still await server OK.
            padFeedback:trigger(state.plotId,target.key,detectedAt)
            local feedbackAt=os.clock()
            view:setContext(target.kind,target.value)
            send(target.action,target.values)
            if pending then
                pending.holdKey=heldPad.key;pending.padDetectedAt=detectedAt; PadHold.sent(heldPad,os.clock())
                if RunService:IsStudio() then
                    view.gui:SetAttribute('LastPadKey',heldPad.key)
                    view.gui:SetAttribute('LastPadDispatchMs',(pending.dispatchedAt-detectedAt)*1000)
                    view.gui:SetAttribute('LastPadFeedbackMs',(feedbackAt-detectedAt)*1000)
                end
            end
        end
    else PadHold.update(heldPad,nil,os.clock()) end
    padFeedback:update(os.clock())
    cashPadCounter:update(os.clock())
    view:animateCounters(os.clock())
    if state then conveyor:update(state.serverNow+os.clock()-receivedAt) end
    guide:update(root and root.Position,if root then targetForGoal(root.Position) else nil)
    guide:showStarter(if state and not state.starterClaimed and not view:isOpen() then state.plotCFrame:PointToWorldSpace(Vector3.new(Config.BuyPads['1'],0,Config.BuyZ)*Map.PlotScale) else nil)
end)
task.spawn(function()
    while true do
        task.wait(.05)
        obbyHUD:update(os.clock())
        multiplierCue:update(os.clock())
        padLabels:update(os.clock())
        if not state then command:FireServer('State',{}); task.wait(1); continue end
        LeaderboardFooter.update(state)
        if pending and os.clock()-pending.sent>=3 then pending.sent=os.clock(); command:FireServer(pending.action,pending.args) end
        local char=player.Character; local root=char and char:FindFirstChild('HumanoidRootPart') :: BasePart?
        local humanoid=char and char:FindFirstChildOfClass('Humanoid')
        if not root or not humanoid or humanoid.Health<=0 then PadHold.update(heldPad,nil,os.clock()); view:setContext(nil); continue end
        local foot=root.Position-Vector3.new(0,humanoid.HipHeight+root.Size.Y/2+(if humanoid.RigType==Enum.HumanoidRigType.R6 then 2 else 0),0)
        local pos=state.plotCFrame:PointToObjectSpace(foot)/Map.PlotScale
        local footPosition={x=pos.X,y=pos.Y,z=pos.Z}
        local target=PadTargeting.resolve(Config,Catalog,Map,state,footPosition)
        if state.lucky and not state.lucky.held then
            local distance=(pos-Vector3.new(Config.LuckyX,1.6,Config.LuckyZ)).Magnitude
            if distance>Config.LuckyPickupRadius+2 then droppedLucky=nil end
            if distance<=Config.LuckyPickupRadius and state.lucky.id~=droppedLucky and not pending and os.clock()-lastLuckyAt>=.6 then
                lastLuckyAt=os.clock();send('PickupLucky',{state.lucky.id})
            end
        end
        view.estimatedServerNow=state.serverNow+os.clock()-receivedAt
        view:setContext(target.kind,target.value)
        if view:isOpen() or Economy.count(state.bag)>=Config.BagCap or state.autoCollect then continue end
        -- Aura keeps its own four-per-second cadence while pad holds scan more often.
        if os.clock()-lastAuraAt<.25 then continue end
        local pickupPos=state.plotCFrame:PointToObjectSpace(root.Position)/Map.PlotScale
        local pickupCenter={x=pickupPos.X,y=pickupPos.Y,z=pickupPos.Z}
        for _,t in state.tokens do
            local current=MiniMotion.position(Config,t,view.estimatedServerNow)
            if current and PickupGeometry.contains(pickupCenter,current,Config.PickupRadius) then
                lastAuraAt=os.clock()
                command:FireServer('CollectNearby',{HttpService:GenerateGUID(false)}); break
            end
        end
    end
end)
command:FireServer('State',{})
