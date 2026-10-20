--!strict
local Factory=require(game:GetService('ReplicatedStorage').Shared.ModelFactory)
local Visuals=require(game:GetService('ReplicatedStorage').Shared.LuckyBlockVisuals)
local Carry={}
function Carry.update(character: Model?,lucky: any)
    if not character then return end
    local old=character:FindFirstChild('HeldLuckyBlock')
    if not lucky or not lucky.held then if old then old:Destroy() end;return end
    if old and old:IsA('BasePart') and old:GetAttribute('LuckyId')==lucky.id and old:GetAttribute('GripVersion')==2 then Visuals.apply(old,lucky.baseTier);return end
    if old then old:Destroy() end
    local hand=character:FindFirstChild('RightHand') or character:FindFirstChild('Right Arm')
    if not hand or not hand:IsA('BasePart') then return end
    local block=Factory.prop(character,'LuckyBlock',CFrame.identity,1)
    if not block then return end
    block.Name='HeldLuckyBlock';block:SetAttribute('LuckyId',lucky.id);block:SetAttribute('GripVersion',2)
    block.Size*=3.2/math.max(block.Size.X,block.Size.Y,block.Size.Z)
    -- The palm touches the near face. This remains a real hand-held prop as
    -- shoulder/elbow animation, avatar scale and R6/R15 proportions change.
    local grip=hand:FindFirstChild('RightGripAttachment')
    -- Grip attachments orient Tools sideways; their rotation is unsuitable for
    -- a box carried along the fingers. Keep only the palm location.
    local palm=if grip and grip:IsA('Attachment') then grip.Position else Vector3.new(0,-hand.Size.Y/2,0)
    block.CFrame=hand.CFrame*CFrame.new(palm+Vector3.new(0,-block.Size.Y/2+.12,0))*CFrame.Angles(-math.pi/2,0,0)
    Visuals.apply(block,lucky.baseTier)
    block.Anchored=false;block.Massless=true;block.CanCollide=false;block.CanTouch=false;block.CanQuery=false
    local weld=Instance.new('WeldConstraint');weld.Name='HandGrip';weld.Part0=hand;weld.Part1=block;weld.Parent=block
end
return Carry
