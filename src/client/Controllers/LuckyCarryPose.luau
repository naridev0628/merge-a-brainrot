--!strict
local Players=game:GetService('Players')
local RunService=game:GetService('RunService')
local Pose={}
type SavedPose={frame: CFrame,attachment: Attachment?}
local baselines: {[Instance]: SavedPose}={}
local function isJoint(joint: Instance): boolean
    return joint:IsA('Motor6D') or joint:IsA('AnimationConstraint')
end
local function save(joint: any): SavedPose?
    if baselines[joint] then return baselines[joint] end
    local attachment=if joint:IsA('AnimationConstraint') then joint.Attachment0 else nil
    if joint:IsA('AnimationConstraint') and not attachment then return nil end
    local saved: SavedPose={frame=if attachment then attachment.CFrame else joint.C0,attachment=attachment}
    baselines[joint]=saved
    return saved
end
local function setFrame(joint: any,saved: SavedPose,frame: CFrame)
    -- AnimationConstraint.C0 is a read-only view of Attachment0.CFrame.
    if saved.attachment then saved.attachment.CFrame=frame else joint.C0=frame end
end
local function restore(joint: any)
    local saved=baselines[joint]
    if saved and joint.Parent then setFrame(joint,saved,saved.frame);joint.Transform=CFrame.identity end
    baselines[joint]=nil
end
function Pose.release(character: Model)
    for _,joint in character:GetDescendants() do
        if isJoint(joint) then restore(joint) end
    end
end
function Pose.apply(character: Model): {[Instance]: boolean}
    local active: {[Instance]: boolean}={}
    if not character:FindFirstChild('HeldLuckyBlock') then return active end
    for _,instance in character:GetDescendants() do
        if isJoint(instance) then
            local joint: any=instance
            local name=joint.Name:gsub(' ','')
            if name~='RightShoulder' and name~='LeftShoulder' and name~='RightElbow' and name~='LeftElbow' and name~='RightWrist' and name~='LeftWrist' then continue end
            local saved=save(joint)
            if not saved then continue end
            local baseline=saved.frame
            if name=='RightShoulder' or name=='LeftShoulder' then
                local desired=CFrame.Angles(math.rad(78),0,math.rad(if name=='RightShoulder' then -18 else 18))
                -- Animator owns Transform. Keep the lift in C0 so animation
                -- cannot replace it; rotate before the saved R6/R15 joint basis.
                setFrame(joint,saved,CFrame.new(baseline.Position)*desired*baseline.Rotation)
                joint.Transform=CFrame.identity
                active[joint]=true
            elseif name=='RightElbow' or name=='LeftElbow' then
                setFrame(joint,saved,baseline*CFrame.Angles(math.rad(12),0,0))
                joint.Transform=CFrame.identity;active[joint]=true
            elseif name=='RightWrist' or name=='LeftWrist' then
                joint.Transform=CFrame.identity;active[joint]=true
            end
        end
    end
    return active
end
function Pose.start()
    return RunService.PreSimulation:Connect(function()
        local active: {[Instance]: boolean}={}
        for _,player in Players:GetPlayers() do
            local character=player.Character
            if character then for joint in Pose.apply(character) do active[joint]=true end end
        end
        for joint in baselines do if not active[joint] then restore(joint) end end
    end)
end
return Pose
