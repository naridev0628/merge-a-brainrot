--!strict
local Players=game:GetService('Players')
local RunService=game:GetService('RunService')
local Pose={}
function Pose.start()
    local posed: {[Motor6D]: boolean}={}
    return RunService.PreSimulation:Connect(function()
        local active: {[Motor6D]: boolean}={}
        for _,player in Players:GetPlayers() do
            local character=player.Character
            if character and character:FindFirstChild('HeldLuckyBlock') then
                for _,joint in character:GetDescendants() do
                    if joint:IsA('Motor6D') then
                        local name=joint.Name:gsub(' ','')
                        if name=='RightShoulder' or name=='LeftShoulder' then
                            joint.Transform=CFrame.Angles(math.rad(82),0,math.rad(if name=='RightShoulder' then -8 else 8));active[joint]=true
                        elseif name=='RightElbow' or name=='LeftElbow' then
                            joint.Transform=CFrame.Angles(math.rad(12),0,0);active[joint]=true
                        end
                    end
                end
            end
        end
        for joint in posed do if not active[joint] and joint.Parent then joint.Transform=CFrame.identity end end
        posed=active
    end)
end
return Pose
