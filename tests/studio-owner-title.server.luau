-- Run in normal Studio Play after all plots are built. The clone is never
-- parented, so this checks actual renderer geometry/lifecycle without changing
-- a player's farm, camera, UI, or network state. Rendered font fit is separate.
assert(game:GetService('RunService'):IsStudio(),'Studio only')
local Shared=game.ReplicatedStorage.Shared
local Config=require(Shared.Config)
local Catalog=require(Shared.CreatureCatalog)
local Map=require(Shared.MapSpec)
local Core=require(game.ServerScriptService.Domain.FarmCore)
local World=require(game.ServerScriptService.Services.WorldBuilder)
local source=assert(workspace.MergeABrainrotGenerated:FindFirstChild('Plot2'))
local fixture=source:Clone()
fixture.Producers:ClearAllChildren()
fixture.Minis:ClearAllChildren()
fixture.StackRows:ClearAllChildren()
local world={
    root=fixture,frame=fixture:GetPivot(),producers=fixture.Producers,
    tokens=fixture.Minis,rows=fixture.StackRows,badgePart=fixture.OwnerBadgeAnchor,
    ownerLabel=fixture.OwnerSign.Label.Text,
    ownerName=fixture.OwnerBadgeAnchor.OwnerBadge.Username,
    portrait=fixture.OwnerBadgeAnchor.OwnerBadge.Portrait,pads={},
    saleLabel={},processorLabel={},processorRate={},
    upgradeLabel=fixture.UpgradePad.Label.Text,upgradePrice=fixture.UpgradePad.Label.Price,
}
local sign=fixture.OwnerSign
local title=world.ownerLabel
local gui=title.Parent
local badge=world.badgePart.OwnerBadge
local originalSign={Size=sign.Size,CFrame=sign.CFrame,CanCollide=sign.CanCollide,
    CanTouch=sign.CanTouch,CanQuery=sign.CanQuery,Color=sign.Color}
local originalBadge={Size=badge.Size,MaxDistance=badge.MaxDistance,AlwaysOnTop=badge.AlwaysOnTop}
local originalPortrait={Size=world.portrait.Size,Position=world.portrait.Position}
local originalFont,originalColor=title.FontFace,title.TextColor3
local originalStroke=assert(title:FindFirstChildOfClass('UIStroke'))
local originalThickness,originalOutline=originalStroke.Thickness,originalStroke.Color
local function close(a,b,message)
    assert(math.abs(a-b)<.001,message)
end
local function audit(count)
    local rows=math.max(1,math.ceil(count/Config.Columns))
    local rowRise=(rows-1)*Config.RowHeight*Map.PlotScale
    assert(gui.StudsOffset==Vector3.zero,'Title must not swing into the shelf when the camera tilts')
    assert(gui.Size.X.Offset==0 and gui.Size.Y.Offset==0,'Header should scale with the display and distance')
    assert(gui.Size.X.Scale>0 and gui.Size.Y.Scale>0,'Header canvas must have positive world dimensions')
    local center=world.frame:PointToObjectSpace(sign.Position+gui.StudsOffsetWorldSpace)
    local bottom=center.Y-gui.Size.Y.Scale/2
    assert(bottom>rowRise+Config.DisplayPlatformHeight*Map.PlotScale,'Header must be above the top occupied row')
    for _,producer in world.producers:GetChildren() do
        local character=assert(producer.PrimaryPart)
        local label=assert(character:FindFirstChild('CharacterLabel'))
        local position=world.frame:PointToObjectSpace(character.Position)
        -- A camera-relative offset cannot contribute more world Y than its
        -- magnitude. This covers tilted camera up/back axes, not just level views.
        local upper=position.Y+label.StudsOffset.Magnitude+
            label.StudsOffsetWorldSpace.Y+label.Size.Y.Scale/2
        assert(bottom>upper+.3,'Header overlaps a producer-name envelope at '..producer.Name)
    end
    for _,row in world.rows:GetChildren() do
        for _,part in row:GetChildren() do
            if part.Name=='BayTopTrim' then
                local top=world.frame:PointToObjectSpace(part.Position).Y+part.Size.Y/2
                assert(bottom>top,'Header is still buried behind the display back wall')
            end
        end
    end
    close(world.frame:PointToObjectSpace(world.badgePart.Position).Y,
        44*Map.PlotScale+rowRise,'Portrait anchor must still follow the occupied row')
    close(gui.MaxDistance,100*Map.PlotScale,'Preserve the authored cutoff through plot scaling')
    assert(not gui.AlwaysOnTop,'Preserve ordinary title occlusion')
    assert(title.TextScaled and title.TextWrapped,'Long display names need bounded wrapped text')
    local fit=assert(title:FindFirstChildOfClass('UITextSizeConstraint'),'Title needs a maximum font size')
    assert(fit.MaxTextSize==22 and fit.MinTextSize>=1 and fit.MinTextSize<fit.MaxTextSize)
    assert(title.FontFace==originalFont and title.TextColor3==originalColor,'Title font/palette changed')
    assert(originalStroke.Parent==title and originalStroke.Thickness==originalThickness
        and originalStroke.Color==originalOutline,'Title outline changed')
    for key,value in originalSign do assert(sign[key]==value,'Physical OwnerSign changed: '..key) end
    for key,value in originalBadge do assert(badge[key]==value,'Portrait badge changed: '..key) end
    for key,value in originalPortrait do assert(world.portrait[key]==value,'Portrait geometry changed: '..key) end
    assert(fixture.Parent==nil,'Fixture must remain off-world')
    return center.Y
end
local core=Core.new(Config,Catalog,function() return 1 end)
local state=core:newSession(900001,0,'owner-title-fixture').state
state.starterClaimed=true
local longTitle=string.rep('W',20).."'s BRAINROT FARM"
local ok,err=xpcall(function()
    title.Text=longTitle
    world.ownerName.Text="OwnerTitleFixture's Plot"
    world.portrait.Visible=true
    world.ownerName.Position=UDim2.fromOffset(0,78)
    local heights={}
    for _,count in {1,11,50,11,1,0,50} do
        state.producers={}
        for slot=1,count do
            -- Include the tallest authored mesh at every top row, plus each
            -- catalog variant in the larger displays.
            local species=if slot==count then 'tier_05' else string.format('tier_%02d',(slot-1)%6+1)
            -- Species is immutable for a real producer ID; merges create new
            -- IDs. Do not accidentally retain a different mesh across counts.
            table.insert(state.producers,{id='owner-title-'..slot..'-'..species,speciesId=species,slot=slot,due=10000})
        end
        World.render(world,state)
        for _,producer in state.producers do
            local model=assert(world.producers:FindFirstChild(producer.id))
            assert(model:GetAttribute('SpeciesId')==producer.speciesId,'Fixture rendered a stale species model')
        end
        assert(#world.rows:GetChildren()==math.max(1,math.ceil(count/Config.Columns)))
        assert(title.Text==longTitle,'Rendering must not truncate or rewrite the display name')
        local height=audit(count)
        if heights[count] then close(height,heights[count],'Shrinking rows must restore the earlier title height') end
        heights[count]=height
        assert(world.portrait.Visible and world.ownerName.Position==UDim2.fromOffset(0,78),
            'Row layout must not replace the owned portrait/name state')
    end
    World.clear(world)
    assert(title.Text=='BRAINROT FARM' and world.ownerName.Text=='Available plot')
    assert(not world.portrait.Visible and world.portrait.Image=='' and world.ownerName.Position==UDim2.fromOffset(0,40))
    assert(#world.rows:GetChildren()==0 and #world.producers:GetChildren()==0)
    close(audit(0),heights[0],'Clearing ownership must restore the first-row header')
end,debug.traceback)
fixture:Destroy()
assert(ok,err)
return 'PASS owner header: actual render 1/2/5 rows, shrink/empty/clear, long-name preservation, producer-label and wall clearance, unchanged sign/portrait and occlusion'
