--!strict
local Marketplace=game:GetService('MarketplaceService')
local Players=game:GetService('Players')
local Config=require(game.ReplicatedStorage.Shared.PassConfig) :: {[string]: {id: number,name: string,suggestedRobux: number?}}
local Passes={}
function Passes.start(onUpdate: (Player,{[string]: boolean})->())
    local records: {[Player]: {[string]: boolean}}={}
    local running: {[Player]: boolean}={}
    local function refresh(player: Player)
        if running[player] then return end
        running[player]=true
        local owned: {[string]: boolean}=records[player] or {}
        for key,pass in Config do
            if pass.id>0 then
                local ok,value=pcall(Marketplace.UserOwnsGamePassAsync,Marketplace,player.UserId,pass.id)
                if ok then owned[key]=value==true end
            end
        end
        running[player]=nil
        if player.Parent==Players then records[player]=owned; onUpdate(player,table.clone(owned)) end
    end
    Marketplace.PromptGamePassPurchaseFinished:Connect(function(player,passId,purchased)
        if not purchased then return end
        for _,pass in Config do
            if pass.id>0 and pass.id==passId then
                -- A purchase may finish during the join ownership query. Schedule another refresh.
                task.spawn(function()
                    while running[player] and player.Parent==Players do task.wait(.2) end
                    if player.Parent==Players then refresh(player) end
                end)
                break
            end
        end
    end)
    Players.PlayerRemoving:Connect(function(player) records[player]=nil; running[player]=nil end)
    return function(player: Player) task.spawn(refresh,player) end
end
return Passes
