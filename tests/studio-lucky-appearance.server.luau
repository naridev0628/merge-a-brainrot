-- Private unparented models only. No player progress, live-world edits or remotes.
local Shared=game.ReplicatedStorage.Shared
local Visuals=require(Shared.LuckyBlockVisuals)
local Appearance=require(Shared.LuckyAppearance)
local Factory=require(Shared.ModelFactory)
local Carry=require(game.ServerScriptService.Services.LuckyCarry)
local sandbox=Instance.new('Folder')
local function close(a,b,message) assert((a-b).Magnitude<.0002,message) end
local function checkMarks(block)
    local folder=assert(block:FindFirstChild('LuckyQuestionMarks'))
    local upgraded=block:GetAttribute('LuckyAppearance')=='upgraded'
    assert(#folder:GetChildren()==(if upgraded then 36 else 28),'28 glyph runs plus eight corner caps only on upgraded blocks')
    local caps=0
    for _,mark in folder:GetChildren() do
        assert(mark:IsA('Part') and mark.Color==Color3.new(1,1,1),'Marks must be white native Parts')
        assert(not mark.Anchored and mark.Massless and not mark.CastShadow,'Marks must follow their block without mass or shadows')
        assert(not mark.CanCollide and not mark.CanTouch and not mark.CanQuery,'Marks must not affect movement or targeting')
        assert(mark.QuestionWeld.Part0==block and mark.QuestionWeld.Part1==mark,'Every mark must be welded to its block')
        local p=block.CFrame:PointToObjectSpace(mark.Position)
        assert(math.abs(p.Y)<block.Size.Y/2 and math.abs(p.X)<=block.Size.X*.51 and math.abs(p.Z)<=block.Size.Z*.51,'Glyph must hug the four side faces')
        if string.sub(mark.Name,1,6)=='Corner' then
            caps+=1
            if block:IsA('MeshPart') then
                local authored=p/(block.Size/Vector3.new(4.01,4.0845,4.01))
                assert(math.abs(math.abs(authored.X)-1.80)<.0002 and math.abs(math.abs(authored.Z)-1.80)<.0002,'Caps must use authored horizontal corner centers')
                assert(math.min(math.abs(authored.Y+1.83775),math.abs(authored.Y-1.77225))<.0002,'Caps must use authored upper/lower centers')
                local outside=Vector3.new(math.abs(p.X),math.abs(p.Y),math.abs(p.Z))+mark.Size/2-block.Size/2
                assert(outside.X<=0 and outside.Y<=0 and outside.Z<=0,'Corner skins must preserve the authored overall bounds')
            end
        end
    end
    assert(caps==(if upgraded then 8 else 0),'Only upgraded blocks get native corner accents')
    return folder
end
local template=game.ReplicatedStorage.MapModels.LuckyBlock
local templateTexture,templateColor=template.TextureID,template.Color
local ok,err=xpcall(function()
    local model=Instance.new('Model');model.Parent=sandbox
    local block=assert(Factory.prop(model,'LuckyBlock',CFrame.new(9,2,-7)*CFrame.Angles(0,.7,0),1.25))
    model.PrimaryPart=block
    local original={CFrame=block.CFrame,Size=block.Size,CanCollide=block.CanCollide,CanQuery=block.CanQuery,CanTouch=block.CanTouch,Anchored=block.Anchored}
    Visuals.apply(block,2)
    assert(block.TextureID==templateTexture and block.Color==templateColor and not block:FindFirstChild('LuckyQuestionMarks'),'Basic must retain the authored gold mesh')
    Visuals.apply(block,3)
    assert(block.TextureID=='' and block.Color==Color3.fromRGB(table.unpack(Appearance.forTier(3).body)),'Blue must not multiply through a gold texture')
    local marks=checkMarks(block)
    for _=1,20 do Visuals.apply(block,6) end
    assert(block.LuckyQuestionMarks==marks and #marks:GetChildren()==36,'Repeated updates must reuse the bounded decoration')
    for key,value in original do assert(block[key]==value,'Appearance changed interaction geometry/property '..key) end
    local relative={}
    for _,mark in marks:GetChildren() do relative[mark]={position=block.CFrame:PointToObjectSpace(mark.Position),size=mark.Size} end
    model:ScaleTo(2)
    for mark,before in relative do
        close(mark.Size,before.size*2,'ScaleTo must scale each white glyph run')
        close(block.CFrame:PointToObjectSpace(mark.Position),before.position*2,'ScaleTo must preserve glyph alignment')
    end
    Visuals.apply(block,3);checkMarks(block)
    Visuals.apply(block,2)
    assert(block.TextureID==templateTexture and block.Color==templateColor and not block:FindFirstChild('LuckyQuestionMarks'),'Blue-to-gold transfer must restore the original texture')
    Visuals.apply(block,3);checkMarks(block)
    local fallback=Factory.part(sandbox,'Fallback',Vector3.new(3,3,3),CFrame.new(),Color3.new(1,1,1))
    Visuals.apply(fallback,2);checkMarks(fallback)
    Visuals.apply(fallback,3);checkMarks(fallback)
    assert(fallback.Color==block.Color,'Fallback and authored upgraded blocks use the same shell palette')
    local character=Instance.new('Model');character.Parent=sandbox
    local root=Factory.part(character,'HumanoidRootPart',Vector3.new(2,2,1),CFrame.new(5,10,20)*CFrame.Angles(0,1,0),Color3.new())
    character.PrimaryPart=root
    local lucky={id='private',held=true,baseTier=3}
    Carry.update(character,lucky)
    local held=assert(character:FindFirstChild('HeldLuckyBlock'));checkMarks(held)
    close(held.Position,(root.CFrame*CFrame.new(0,.25,-2.3)).Position,'Held block must retain the carry offset')
    assert(not held.Anchored and held.Massless and not held.CanQuery and not held.CanTouch and not held.CanCollide)
    local before=held.CFrame:PointToObjectSpace(held.LuckyQuestionMarks.Question1_1.Position)
    character:PivotTo(CFrame.new(-12,3,9)*CFrame.Angles(.2,-1,.1))
    close(held.CFrame:PointToObjectSpace(held.LuckyQuestionMarks.Question1_1.Position),before,'Held pivot must move the glyph with the block')
    Carry.update(character,lucky);assert(character.HeldLuckyBlock==held,'Same-id updates must reuse the held block')
    lucky.baseTier=2;Carry.update(character,lucky)
    assert(held.TextureID==templateTexture and not held:FindFirstChild('LuckyQuestionMarks'),'Held tier transfer must restore Basic gold')
    lucky.held=false;Carry.update(character,lucky)
    assert(not character:FindFirstChild('HeldLuckyBlock'),'Dropping must release the decorated held block')
    assert(template.TextureID==templateTexture and template.Color==templateColor and not template:FindFirstChild('LuckyQuestionMarks'),'Never recolor the shared template')
end,debug.traceback)
sandbox:Destroy()
assert(ok,err)
return 'PASS Lucky gold/blue geometry, 36-part cap, eight authored corner positions/bounds, flags, idempotence, ScaleTo/pivot, texture transfer, held cleanup and unchanged interaction/template properties'
