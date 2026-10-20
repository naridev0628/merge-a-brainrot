--!strict
local Factory=require(game:GetService('ReplicatedStorage').Shared.ModelFactory)
local Visuals=require(game:GetService('ReplicatedStorage').Shared.LuckyBlockVisuals)
local Carry={}
function Carry.update(character: Model?,lucky: any)
    if not character then return end
    local old=character:FindFirstChild('HeldLuckyBlock')
    if not lucky or not lucky.held then if old then old:Destroy() end;return end
    if old and old:IsA('BasePart') and old:GetAttribute('LuckyId')==lucky.id then Visuals.apply(old,lucky.baseTier);return end
    if old then old:Destroy() end
    local root=character:FindFirstChild('HumanoidRootPart')
    if not root or not root:IsA('BasePart') then return end
    local block=Factory.prop(character,'LuckyBlock',CFrame.identity,1)
    if not block then return end
    block.Name='HeldLuckyBlock';block:SetAttribute('LuckyId',lucky.id)
    block.Size*=3.2/math.max(block.Size.X,block.Size.Y,block.Size.Z)
    block.CFrame=root.CFrame*CFrame.new(0,.25,-2.3)
    Visuals.apply(block,lucky.baseTier)
    block.Anchored=false;block.Massless=true;block.CanCollide=false;block.CanTouch=false;block.CanQuery=false
    local weld=Instance.new('WeldConstraint');weld.Part0=root;weld.Part1=block;weld.Parent=block
end
return Carry
