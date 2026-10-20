-- Run in disposable Play after the matching bootstrap is installed.
local player=game.Players.LocalPlayer
local Config=require(game.ReplicatedStorage.Shared.Config)
local result=Instance.new('StringValue');result.Name='DepositReviewResult';result.Value='running';result.Parent=player.PlayerGui
task.spawn(function()
    local controls=require(player.PlayerScripts:WaitForChild('PlayerModule')):GetControls()
    local ok,err=xpcall(function()
        local net=game.ReplicatedStorage:WaitForChild('FarmNetwork',20)
        local response
        local listener=net.CommandResult.OnClientEvent:Connect(function(value)
            if value.action=='Deposit' and value.code=='OK' then response=value end
        end)
        player.PlayerScripts.Main.Disabled=false
        local plot=workspace:WaitForChild('MergeABrainrotGenerated'):WaitForChild('Plot1')
        local character=player.Character or player.CharacterAdded:Wait()
        local humanoid=character:WaitForChild('Humanoid')
        local root=character:WaitForChild('HumanoidRootPart')
        task.wait(2)
        controls:Disable()
        local frame=plot:GetPivot()
        local height=humanoid.HipHeight+root.Size.Y/2+(if humanoid.RigType==Enum.HumanoidRigType.R6 then 2 else 0)
        local staging=frame:PointToWorldSpace(Vector3.new(Config.SellX,0,Config.SellZ+16)*Config.PlotScale)+Vector3.new(0,height+.2,0)
        character:PivotTo(CFrame.new(staging))
        task.wait(.5)
        humanoid:MoveTo(frame:PointToWorldSpace(Vector3.new(Config.SellX,0,Config.SellZ)*Config.PlotScale))
        local deadline=os.clock()+12
        repeat task.wait(.05) until response or os.clock()>deadline
        listener:Disconnect()
        assert(response,'Walking onto Deposit produced no success')
        assert(response.inputCount==5280 and response.depositedCount==5596 and response.multiplierHundredths==106,'Wrong authoritative deposit arithmetic')
        task.wait(.1)
        local found=false
        for _,item in player.PlayerGui:GetDescendants() do
            if item:IsA('TextLabel') and item.Text=='Deposited 5,280 Minis (1.06× → 5,596)' then found=true end
        end
        assert(found,'Exact multiplier/result toast missing')
        local fixture=game.ReplicatedStorage.DepositReviewFixture
        assert(fixture:GetAttribute('BagEmpty') and fixture:GetAttribute('Carry')==80 and fixture:GetAttribute('Sorted'),'Server deposit or sorting state mismatch')
        result.Value=game.HttpService:JSONEncode({pass=true,input=5280,output=5596,multiplier=1.06,carry=80,sorted=true})
    end,debug.traceback)
    controls:Enable()
    if not ok then result.Value=game.HttpService:JSONEncode({pass=false,error=tostring(err)}) end
end)
return 'Deposit walking check started'
