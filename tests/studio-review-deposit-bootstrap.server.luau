-- Disposable Play fixture only: start with both Main scripts disabled.
-- Seeded quantities and a fixed event are test inputs, never saved progression.
local Server=game.ServerScriptService
local Replicated=game.ReplicatedStorage
local Core=require(Server.Domain.FarmCore)
local Config=require(Replicated.Shared.Config)
assert(Server.Main.Disabled and not Replicated:FindFirstChild('FarmNetwork'))
local originalNew,originalEvent=Core.newSession,Core.setEvent
local session,engine
local folder=Instance.new('Folder');folder.Name='DepositReviewFixture';folder.Parent=Replicated
Core.newSession=function(self,...)
    Core.newSession=originalNew
    local created=originalNew(self,...)
    local state=self:snapshot(created)
    state.starterClaimed=true;state.tutorialStep=7
    state.bag={{speciesId='tier_01',baseCoinValue=1,count=5280}}
    state.eventHundredths=106
    local tiers={1,7,3,25,20,18,24,2,6,17,19,21,22,23}
    for index,tier in tiers do
        local id=string.format('tier_%02d',tier)
        table.insert(state.producers,{id='review-'..index,speciesId=id,slot=index,due=os.clock()+100000})
        state.discoveries[id]=true
    end
    assert(self:commit(created,state));session=created;engine=self
    return created
end
Core.setEvent=function(self,target,...)
    if target==session then return originalEvent(self,target,106) end
    return originalEvent(self,target,...)
end
local function restore()
    Core.newSession=originalNew;Core.setEvent=originalEvent
end
task.delay(45,restore)
Server.Main.Disabled=false
task.spawn(function()
    local net=Replicated:WaitForChild('FarmNetwork',20)
    assert(net,'Network missing')
    net.Command.OnServerEvent:Connect(function(_,action)
        if action~='Deposit' or not session then return end
        task.defer(function()
            local deadline=os.clock()+.5
            while #session.state.bag~=0 and os.clock()<deadline do task.wait(.025) end
            if #session.state.bag~=0 then return end
            assert(engine:validate(session.state,session.owner))
            folder:SetAttribute('Carry',session.state.depositCarry)
            folder:SetAttribute('BagEmpty',true)
            folder:SetAttribute('Sorted',true)
            local ranked=table.clone(session.state.producers)
            table.sort(ranked,function(a,b)return a.slot<b.slot end)
            for i=2,#ranked do
                assert(tonumber(ranked[i-1].speciesId:sub(6))>=tonumber(ranked[i].speciesId:sub(6)))
            end
            restore()
        end)
    end)
end)
