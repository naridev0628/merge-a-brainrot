--!strict
local ReplicatedStorage=game:GetService("ReplicatedStorage")
local Players=game:GetService("Players")
local UserInputService=game:GetService("UserInputService")
local HttpService=game:GetService("HttpService")
local Shared=ReplicatedStorage:WaitForChild("Shared")
local Config=require(Shared:WaitForChild("Config"))
local Map=require(Shared:WaitForChild("MapSpec"))
local UI=require(script.Parent:WaitForChild("Controllers"):WaitForChild("FarmUI"))
local player=Players.LocalPlayer
local view=UI.new(player:WaitForChild("PlayerGui"))
local net=ReplicatedStorage:WaitForChild("FarmNetwork",15)
if not net then view:notice("Farm unavailable. Rejoin to try again."); return end
local command=net:WaitForChild("Command") :: RemoteEvent
local stateEvent=net:WaitForChild("StateSnapshot") :: RemoteEvent
local resultEvent=net:WaitForChild("CommandResult") :: RemoteEvent
local state: any=nil
local appliedRevision=-1
local pending: any=nil
local collectRetry: {[string]: number}={}
local wasOnSell=false
local messages={
    BadRequest="That action could not be read. Try again.",Unavailable="Your farm is unavailable.",
    MissingToken="Already collected.",BagFull="Bag full — sell your Minis.",TooFar="Move closer to your own pad or Mini.",
    BagEmpty="Bag empty — collect Minis.",WalletFull="Wallet limit reached. Your Minis are still in your bag.",
    PlotFull="No free slots — merge a matching pair.",InsufficientFunds="Sell Minis to earn 20 Coins.",
    SameProducer="Choose two different matching producers.",MissingProducer="That selection changed — choose again.",
    Mismatch="Choose two of the same species.",MaxTier="Top tier for this prototype — keep collecting!",
    NotAlive="Wait until your character respawns.",RequestLimit="Session action limit reached. Restart this Studio test.",
    RequestConflict="That request was already used. Try again.",InvalidState="Your farm could not update.",
}
local function send(action: string, ids: {string}?)
    if not state or state.status~="Ready" or pending then return end
    local args={HttpService:GenerateGUID(false)}
    local selectedIds: {string}=ids or {}
    for _,id in selectedIds do table.insert(args,id) end
    pending={action=action,args=args,sent=os.clock()}
    view:setPending(true)
    command:FireServer(action,args)
end
view.onBuy=function() send("Buy") end
view.onSell=function() send("Sell") end
view.onMerge=function(ids) send("Merge",ids) end
view.onHome=function()
    if state and state.status=="Ready" then command:FireServer("Home",{}) end
end
stateEvent.OnClientEvent:Connect(function(incoming)
    if incoming.status~="Ready" then view:unavailable(incoming.reason or "Your farm is unavailable."); state=nil; return end
    if incoming.revision<appliedRevision then return end
    appliedRevision=incoming.revision; state=incoming
    local active={}
    for _,token in state.tokens do active[token.id]=true end
    for id in collectRetry do if not active[id] then collectRetry[id]=nil end end
    view:update(state)
end)
resultEvent.OnClientEvent:Connect(function(response)
    if response.action=="Collect" then
        if response.code=="BagFull" then view:notice(messages.BagFull) end
        return
    end
    if not pending or response.requestId~=pending.args[1] then return end
    pending=nil; view:setPending(false)
    if response.code=="OK" then
        if response.action=="Sell" then view:notice("Sold Minis · +"..UI.coins(response.creditUnits or 0).." Coins")
        elseif response.action=="Buy" then view:notice("Spoon Sprout added. Open Merge to choose a pair.")
        else view:clearSelection(); view:notice("Merged! Your new producer makes more valuable Minis.") end
    else
        if response.code=="MissingProducer" then view:clearSelection() end
        view:notice(messages[response.code] or "Please try again.")
    end
    -- Only StateSnapshot advances appliedRevision; a result never substitutes for state.
end)
UserInputService.InputBegan:Connect(function(input,processed)
    if processed then return end
    if input.KeyCode==Enum.KeyCode.Escape then view:close()
    elseif input.KeyCode==Enum.KeyCode.M then view:toggleMerge()
    elseif input.KeyCode==Enum.KeyCode.E and not view:isOpen() then
        if view.context=="Buy" then send("Buy") elseif view.context=="Sell" then send("Sell") end
    end
end)
task.spawn(function()
    while true do
        task.wait(0.25)
        if not state then command:FireServer("State",{}); task.wait(1); continue end
        local character=player.Character
        local root=character and character:FindFirstChild("HumanoidRootPart") :: BasePart?
        local humanoid=character and character:FindFirstChildOfClass("Humanoid")
        if pending and os.clock()-pending.sent>=3 then
            pending.sent=os.clock(); command:FireServer(pending.action,pending.args)
            view:notice("Waiting for the server… retrying the same request.")
        end
        if not root or not humanoid or humanoid.Health<=0 then view:setContext(nil); wasOnSell=false; continue end
        local pos=root.Position
        local nearSell=(pos-Map.Sell).Magnitude<=Config.PadDistance
        local nearBuy=(pos-Map.Buy).Magnitude<=Config.PadDistance
        view:setContext(if nearSell then "Sell" elseif nearBuy then "Buy" else nil)
        local onSell=math.abs(pos.X-Map.Sell.X)<=5 and math.abs(pos.Z-Map.Sell.Z)<=5 and math.abs(pos.Y-Map.Sell.Y)<=8
        if onSell and not wasOnSell and not view:isOpen() and #state.bag>0 then send("Sell") end
        wasOnSell=onSell
        if view:isOpen() or #state.bag>=Config.BagCap then continue end
        local sent=0
        for _,token in state.tokens do
            local distance=(pos-Vector3.new(token.x,token.y,token.z)).Magnitude
            if distance<=Config.CollectDistance and os.clock()-(collectRetry[token.id] or -10)>1 then
                collectRetry[token.id]=os.clock()
                command:FireServer("Collect",{token.id})
                sent+=1; if sent>=3 then break end
            end
        end
    end
end)
command:FireServer("State",{})
