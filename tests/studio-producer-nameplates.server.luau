-- Disposable floating-label A/B/C preview; the earlier lower-trim plate trial was rejected.
-- No production Source, normal farm, player or camera edits.
-- _G.ProducerNameplatePreview: setRows(1|2|5), setMode('baseline'|'aot'|'aot-narrow'),
-- setStressName('catalog'|'wide20'|'wide23'), inspect(), destroy().
local RunService=game:GetService('RunService')
assert(RunService:IsStudio() and RunService:IsServer(),'Studio Server required')
assert(not _G.ProducerNameplatePreview,'Destroy the earlier preview first')
local Shared=game.ReplicatedStorage.Shared
local Config=require(Shared.Config)
local Catalog=require(Shared.CreatureCatalog)
local Map=require(Shared.MapSpec)
local Core=require(game.ServerScriptService.Domain.FarmCore)
local World=require(game.ServerScriptService.Services.WorldBuilder)
local clone=workspace.MergeABrainrotGenerated.Plot2:Clone()
clone.Name='ProducerNameplatePreview'
clone.Producers:ClearAllChildren();clone.Minis:ClearAllChildren();clone.StackRows:ClearAllChildren()
for _,item in clone:GetDescendants() do
    if item:IsA('SpawnLocation') or item:IsA('LuaSourceContainer') then item:Destroy() end
end
local lucky=clone:FindFirstChild('LuckyBlock')
if lucky then lucky:Destroy() end
clone:PivotTo(CFrame.new(0,2000,0))
local world={root=clone,frame=clone:GetPivot(),producers=clone.Producers,tokens=clone.Minis,
    rows=clone.StackRows,badgePart=clone.OwnerBadgeAnchor,ownerLabel=clone.OwnerSign.Label.Text,pads={},
    saleLabel={},processorLabel={},processorRate={},upgradeLabel=clone.UpgradePad.Label.Text,
    upgradePrice=clone.UpgradePad.Label.Price}
local core=Core.new(Config,Catalog,function() return 1 end)
local state=core:newSession(900010,0,'nameplate-preview').state
state.starterClaimed=true
local active=true
local rowCount=5
local mode='baseline'
local stress='catalog'
local revision=0
local records={}
local geometry={}
local baselineParts,baselineColliders,baselineInstances=0,0,0
local api={}
local function near(a,b)
    return math.abs(a-b)<.0001
end
local function rememberLabel(label)
    local constraint=assert(label:FindFirstChildWhichIsA('UITextSizeConstraint'))
    local outline=assert(label:FindFirstChild('TextOutline'))
    return {properties={Position=label.Position,Size=label.Size,FontFace=label.FontFace,
        TextSize=label.TextSize,TextScaled=label.TextScaled,TextWrapped=label.TextWrapped,
        TextColor3=label.TextColor3,TextYAlignment=label.TextYAlignment,
        TextStrokeTransparency=label.TextStrokeTransparency},
        text=label.Text,parent=label.Parent,constraint=constraint,min=constraint.MinTextSize,max=constraint.MaxTextSize,
        outline=outline,color=outline.Color,thickness=outline.Thickness}
end
local function restoreRecord(record)
    -- These are the only properties the A/B/C trial changes. In particular it
    -- never writes TextWrapped, whose native setter can also disable TextScaled.
    record.gui.AlwaysOnTop=record.before.AlwaysOnTop
    record.gui.Size=record.before.Size
    record.name.Text=record.nameBefore.text
end
local function applyMode()
    for slot,record in records do
        restoreRecord(record)
        if mode~='baseline' then record.gui.AlwaysOnTop=true end
        if mode=='aot-narrow' then
            local size=record.before.Size
            record.gui.Size=UDim2.new(size.X.Scale*(7.2/8.8),size.X.Offset,size.Y.Scale,size.Y.Offset)
        end
        if slot==1 and stress~='catalog' then
            record.name.Text=string.rep('W',if stress=='wide20' then 20 else 23)
        end
    end
    revision+=1
    clone:SetAttribute('PreviewMode',mode);clone:SetAttribute('StressName',stress)
    clone:SetAttribute('PreviewRevision',revision)
end
local function assertLabel(label,before,expectedText)
    assert(label.Parent==before.parent,'Do not move label children')
    assert(label.Text==expectedText,'Unexpected label text')
    for key,value in before.properties do assert(label[key]==value,'Label style changed: '..label.Name..'.'..key) end
    assert(label.TextScaled,'Native TextScaled must remain enabled')
    assert(before.constraint.Parent==label and before.constraint.MinTextSize==before.min
        and before.constraint.MaxTextSize==before.max,'Preserve the original font-size constraints')
    assert(before.outline.Parent==label and before.outline.Color==before.color
        and before.outline.Thickness==before.thickness,'Preserve the original outline')
end
function api.inspect()
    assert(active,'Preview has been destroyed')
    local parts,colliders,instances=0,0,0
    for _,item in clone:GetDescendants() do
        instances+=1
        if item:IsA('BasePart') then
            parts+=1;if item.CanCollide then colliders+=1 end
            local before=assert(geometry[item],'Unexpected added Part')
            for key,value in before do assert(item[key]==value,'Preview changed Part '..item.Name..'.'..key) end
        end
    end
    assert(parts==baselineParts and colliders==baselineColliders,'Variants must add zero Parts/colliders')
    assert(instances==baselineInstances,'Variants must add zero Instances')
    for slot,record in records do
        local gui,before=record.gui,record.before
        assert(gui.Parent==record.character and gui.Adornee==record.adornee,'Preserve the original label attachment')
        assert(gui.AlwaysOnTop==(if mode=='baseline' then before.AlwaysOnTop else true),'Wrong A/B/C overlay state')
        for key,value in before do
            if key~='Size' and key~='AlwaysOnTop' then assert(gui[key]==value,'Unexpected Billboard change: '..key) end
        end
        local width=if mode=='aot-narrow' then 7.2 else 8.8
        assert(near(gui.Size.X.Scale,width*Map.PlotScale) and near(gui.Size.Y.Scale,3.6*Map.PlotScale)
            and gui.Size.X.Offset==before.Size.X.Offset and gui.Size.Y.Offset==before.Size.Y.Offset,
            'Keep scaled logical dimensions and original pixel offsets')
        assert(near(gui.MaxDistance,65*Map.PlotScale),'Preserve the scaled world-distance cutoff')
        local text=if slot==1 and stress~='catalog' then string.rep('W',if stress=='wide20' then 20 else 23)
            else record.nameBefore.text
        assertLabel(record.name,record.nameBefore,text)
        assertLabel(record.level,record.levelBefore,record.levelBefore.text)
    end
    return {rows=rowCount,producers=#state.producers,mode=mode,stressName=stress,revision=revision,
        addedParts=parts-baselineParts,addedColliders=colliders-baselineColliders,addedInstances=instances-baselineInstances,
        canvasLogical={if mode=='aot-narrow' then 7.2 else 8.8,3.6},
        canvasWorld={records[1].gui.Size.X.Scale,records[1].gui.Size.Y.Scale},
        maxDistance=records[1].gui.MaxDistance,
        scope='Disposable overlay comparison; front/oblique/rear readability and through-wall clutter require native visual judgment'}
end
function api.destroy()
    if not active then return end
    active=false;clone:Destroy();table.clear(records);table.clear(geometry)
    if _G.ProducerNameplatePreview==api then _G.ProducerNameplatePreview=nil end
end
local function checked(callback)
    local ok,result=xpcall(callback,debug.traceback)
    if not ok then api.destroy();error(result) end
    return result
end
function api.setMode(value)
    assert(active and (value=='baseline' or value=='aot' or value=='aot-narrow'),'Use baseline, aot or aot-narrow')
    return checked(function()
        mode=value;applyMode();return api.inspect()
    end)
end
function api.setStressName(value)
    assert(active and (value=='catalog' or value=='wide20' or value=='wide23'),'Unknown stress case')
    return checked(function()
        stress=value;applyMode();return api.inspect()
    end)
end
function api.setRows(value)
    assert(active and (value==1 or value==2 or value==5),'Use one, two or five rows')
    return checked(function()
        clone:SetAttribute('Ready',false)
        for _,record in records do restoreRecord(record) end
        table.clear(records)
        rowCount=value;state.producers={}
        for slot=1,rowCount*Config.Columns do
            local species=string.format('tier_%02d',(slot-1)%6+1)
            table.insert(state.producers,{id='nameplate-'..slot..'-'..species,speciesId=species,slot=slot,due=10000})
        end
        World.render(world,state)
        table.clear(geometry);baselineParts=0;baselineColliders=0;baselineInstances=0
        for _,item in clone:GetDescendants() do
            baselineInstances+=1
            if item:IsA('BasePart') then
                baselineParts+=1;if item.CanCollide then baselineColliders+=1 end
                local before={CFrame=item.CFrame,Size=item.Size,Color=item.Color,CanCollide=item.CanCollide,
                    CanQuery=item.CanQuery,CanTouch=item.CanTouch,Transparency=item.Transparency,Anchored=item.Anchored}
                if item:IsA('MeshPart') then before.MeshId=item.MeshId;before.TextureID=item.TextureID end
                geometry[item]=before
            end
        end
        for _,producer in state.producers do
            local model=assert(world.producers:FindFirstChild(producer.id))
            local character=assert(model.PrimaryPart)
            local template=Shared.Parent.CharacterModels[producer.speciesId]
            assert(character:IsA('MeshPart') and character.MeshId==template.MeshId,'Use the actual imported species mesh')
            local gui=assert(character:FindFirstChild('CharacterLabel'))
            assert(not gui.AlwaysOnTop,'Begin from the original depth-tested label')
            local record={gui=gui,name=assert(gui:FindFirstChild('Name')),level=assert(gui:FindFirstChild('Level')),
                character=character,adornee=gui.Adornee,before={Size=gui.Size,AlwaysOnTop=gui.AlwaysOnTop,
                    Enabled=gui.Enabled,MaxDistance=gui.MaxDistance,StudsOffset=gui.StudsOffset,
                    StudsOffsetWorldSpace=gui.StudsOffsetWorldSpace,LightInfluence=gui.LightInfluence}}
            record.nameBefore=rememberLabel(record.name);record.levelBefore=rememberLabel(record.level)
            records[producer.slot]=record
        end
        applyMode()
        clone:SetAttribute('PreviewRows',rowCount);clone:SetAttribute('Ready',true)
        return api.inspect()
    end)
end
local result=checked(function()
    api.setRows(5)
    -- Verify round-trip restoration before exposing the clone for screenshots.
    api.setMode('aot');api.setMode('aot-narrow')
    local initial=api.setMode('baseline')
    clone.Parent=workspace
    return initial
end)
_G.ProducerNameplatePreview=api
task.delay(300,api.destroy)
return result
