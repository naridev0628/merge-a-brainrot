-- Isolated animation fixture; does not move the player's actual producers.
local Conveyor=require(game.Players.LocalPlayer.PlayerScripts.Controllers.Conveyor)
local fixture=Instance.new('Model');fixture.Name='ProducerGroundingQA'
local part=Instance.new('Part');part.Size=Vector3.new(2,4,2);part.Anchored=true;part.CFrame=CFrame.new(0,5,0);part.Parent=fixture;fixture.PrimaryPart=part
local rest=fixture:GetPivot();fixture:SetAttribute('RestingPivot',rest);fixture:SetAttribute('ProducedAt',10)
local controller={models={},producers={[fixture]={active=false}}}
fixture.Parent=workspace
local ok,err=pcall(function()
    for _,elapsed in {0,.1,.25,.4,.55,1} do
        Conveyor.update(controller,10+elapsed)
        local cf,size=fixture:GetBoundingBox()
        assert(math.abs(cf.Y-size.Y/2-3)<.001,'Production animation lifts feet off the stand')
    end
    assert((fixture:GetPivot().Position-rest.Position).Magnitude<.001,'Animation must return to its resting position')
    -- Procedural cylinder characters use a sideways primary-part pivot.
    rest=CFrame.new(0,5,0)*CFrame.Angles(0,0,math.pi/2)
    fixture:PivotTo(rest);fixture:SetAttribute('RestingPivot',rest)
    for _,elapsed in {.1,.25,.4,.55,1} do
        Conveyor.update(controller,10+elapsed)
        local pivot=fixture:GetPivot()
        local halfHeight=(math.abs(pivot.RightVector.Y)*part.Size.X+math.abs(pivot.UpVector.Y)*part.Size.Y+math.abs(pivot.LookVector.Y)*part.Size.Z)/2
        assert(math.abs(pivot.Y-halfHeight-4)<.001,'Sideways fallback pivots must also stay grounded')
    end
end)
fixture:Destroy();assert(ok,err)
return 'PASS producer feet remain grounded throughout production animation'
