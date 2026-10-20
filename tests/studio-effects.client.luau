-- Run in Studio Client during Play. Isolated fixture; never mutates player state.
local player=game.Players.LocalPlayer
local controllers=player.PlayerScripts.Controllers
local Cash=require(controllers.CashEffects)
local Deposit=require(controllers.DepositEffects)
local Tier=require(controllers.TierEffects)
local Conveyor=require(controllers.Conveyor)
local tiers=Tier.new()
local fixtures=Instance.new('Folder');fixtures.Name='TierEffectsQA';fixtures.Parent=workspace
local gui=Instance.new('ScreenGui');gui.Name='EffectsQA';gui.Parent=player.PlayerGui
local character=Instance.new('Model');character.Name='EffectsQACharacter';character.Parent=workspace
local root=Instance.new('Part');root.Name='HumanoidRootPart';root.Anchored=true;root.CFrame=CFrame.new(0,30,0);root.Parent=character
local function cashParts()
    local count=0
    for _,folder in workspace:GetChildren() do
        if folder.Name=='CashCollectionBurst' then
            for _,item in folder:GetDescendants() do if item:IsA('BasePart') then count+=1 end end
        end
    end
    return count
end
local ok,err=pcall(function()
    Cash.play(gui,character,'10')
    local full=cashParts();assert(full>0,'First claim needs visible cash feedback')
    task.wait(.14)
    Cash.play(gui,character,'20')
    assert(cashParts()-full>0 and cashParts()-full<full,'A rapid repeat must use smaller visible feedback')
    for index=1,20 do
        Cash.play(gui,character,tostring(index))
        assert(cashParts()<=150,'Repeated claims exceeded the global 150-part cash budget: '..cashParts())
        task.wait(.13)
    end
    task.wait(2.1)
    assert(cashParts()==0,'Cash burst parts leaked past their two-second lifetime')
    assert(not gui:FindFirstChild('CashCollectionFeedback',true),'Cash text leaked')
    local bag=table.create(50,'tier_04')
    for _=1,10 do Deposit.play(gui,character,bag) end
    local layers,minis=0,0
    for _,item in gui:GetDescendants() do
        if item.Name=='DepositCelebration' then layers+=1 end
        if item:IsA('ViewportFrame') and item.Name=='FlyingMini' then minis+=1 end
    end
    assert(layers==1 and minis>0 and minis<=6,'Repeated deposit exceeded one layer / six Minis')
    task.wait(2.1)
    assert(not gui:FindFirstChild('DepositCelebration'),'Deposit layer leaked after cleanup')
    local producers={}
    local original={}
    for index=1,50 do
        local model=Instance.new('Model');model.Name='Producer'..index
        local part=Instance.new('Part');part.Anchored=true;part.Size=Vector3.new(2,4,2);part.CFrame=CFrame.new((index%10)*4,100,math.floor(index/10)*4);part.Parent=model;model.PrimaryPart=part;model.Parent=fixtures
        model:SetAttribute('Tier',if index<=3 then index else 4+(index%3))
        model:SetAttribute('RestingPivot',model:GetPivot());model:SetAttribute('ProducedAt',10)
        producers[model]={active=false};original[model]={pivot=model:GetPivot(),count=#model:GetDescendants()}
    end
    tiers:update(producers,10,Vector3.new(0,100,0))
    local accents=0
    for model,effect in tiers.effects do
        assert(model:GetAttribute('Tier')>=4,'Low tiers must not receive ambient effects')
        for _,part in effect.folder:GetChildren() do
            if part:IsA('BasePart') then
                accents+=1
                assert(not part.CanCollide and not part.CanTouch and not part.CanQuery,'Accents must not affect interactions')
                assert(part.Position.Y+part.Size.Y/2<102,'Accents entered the nameplate clearance above the producer')
            end
        end
    end
    assert(accents>0 and accents<=32,'50 producers must respect the global 32-part tier budget')
    local conveyor={models={},producers=producers}
    for _,elapsed in {0,.1,.25,.4,.55,1} do
        Conveyor.update(conveyor,10+elapsed)
        for model,prior in original do
            local box,size=model:GetBoundingBox()
            assert(math.abs(box.Y-size.Y/2-98)<.001,'Effects or production animation lifted feet')
            assert(#model:GetDescendants()==prior.count,'Tier geometry changed producer bounds')
        end
    end
    tiers:update(producers,12,Vector3.new(1000,100,0))
    assert(next(tiers.effects)==nil,'Distant producers retained effects')
    tiers:update(producers,13,Vector3.new(0,100,0))
    fixtures:Destroy();tiers:update(producers,14,Vector3.new(0,100,0))
    assert(next(tiers.effects)==nil,'Destroyed producers retained effects')
end)
tiers:destroy();fixtures:Destroy();gui:Destroy();character:Destroy()
assert(ok,err)
return 'PASS cash/deposit repeat budgets, tier budget and culling, feet grounding, and cleanup'
