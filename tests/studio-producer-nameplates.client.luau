-- Read-only native measurement of the disposable A/B/C floating-label preview.
-- Match these literals to the Server API. This never edits the camera or normal HUD.
local EXPECTED_ROWS=5
local EXPECTED_MODE='aot-narrow'
local EXPECTED_STRESS='catalog'
local RunService=game:GetService('RunService')
assert(RunService:IsStudio() and RunService:IsClient(),'Studio Client required')
assert(EXPECTED_MODE=='baseline' or EXPECTED_MODE=='aot' or EXPECTED_MODE=='aot-narrow','Unknown preview variant')
local Map=require(game.ReplicatedStorage.Shared.MapSpec)
local Catalog=require(game.ReplicatedStorage.Shared.CreatureCatalog)
local preview=assert(workspace:WaitForChild('ProducerNameplatePreview',10),'Preview did not replicate')
local width=(if EXPECTED_MODE=='aot-narrow' then 7.2 else 8.8)*Map.PlotScale
local function ready()
    if not preview:GetAttribute('Ready') or preview:GetAttribute('PreviewRows')~=EXPECTED_ROWS
        or preview:GetAttribute('PreviewMode')~=EXPECTED_MODE or preview:GetAttribute('StressName')~=EXPECTED_STRESS then return false end
    local producers=preview:FindFirstChild('Producers')
    if not producers or #producers:GetChildren()~=EXPECTED_ROWS*10 then return false end
    for _,model in producers:GetChildren() do
        local character=model.PrimaryPart
        local gui=character and character:FindFirstChild('CharacterLabel')
        if not gui or gui.AlwaysOnTop~=(EXPECTED_MODE~='baseline') or math.abs(gui.Size.X.Scale-width)>.0001
            or not gui:FindFirstChild('Name') or not gui:FindFirstChild('Level') then return false end
        if model.Name=='nameplate-1-tier_01' then
            local expectedText=if EXPECTED_STRESS=='catalog' then Catalog.tier_01.name
                else string.rep('W',if EXPECTED_STRESS=='wide20' then 20 else 23)
            if gui:FindFirstChild('Name').Text~=expectedText then return false end
        end
    end
    return true
end
local deadline=os.clock()+10
repeat if ready() then break end;RunService.Heartbeat:Wait() until os.clock()>=deadline
assert(ready(),'Expected preview state/children did not replicate within ten seconds')
RunService.RenderStepped:Wait();RunService.RenderStepped:Wait()
local camera=assert(workspace.CurrentCamera)
local measurements={}
local candidates,overflowCandidates=0,0
for _,model in preview.Producers:GetChildren() do
    local character=model.PrimaryPart
    local gui=character.CharacterLabel
    assert(math.abs(gui.MaxDistance-65*Map.PlotScale)<.0001,'Do not expand the scaled cutoff')
    assert(math.abs(gui.Size.Y.Scale-3.6*Map.PlotScale)<.0001,'Keep original canvas height')
    -- Camera-relative offset is retained in every variant. Projection/cutoff
    -- candidates are diagnostic estimates, not a claim about engine visibility.
    local center=character.Position+camera.CFrame:VectorToWorldSpace(gui.StudsOffset)+gui.StudsOffsetWorldSpace
    local projected,onScreen=camera:WorldToViewportPoint(center)
    local distance=(camera.CFrame.Position-character.Position).Magnitude
    local candidate=gui.Enabled and onScreen and projected.Z>0 and distance<gui.MaxDistance
    local result={id=model.Name,species=model:GetAttribute('SpeciesId'),distanceToAdornee=distance,
        withinCutoff=distance<gui.MaxDistance,centerOnScreen=onScreen,visibilityCandidate=candidate,
        alwaysOnTop=gui.AlwaysOnTop,canvasWorld={gui.Size.X.Scale,gui.Size.Y.Scale},
        maxDistance=gui.MaxDistance}
    local overflow=false
    for _,key in {'Name','Level'} do
        local label=assert(gui:FindFirstChild(key))
        local constraint=assert(label:FindFirstChildWhichIsA('UITextSizeConstraint'))
        assert(label.TextScaled,'TextScaled must remain enabled for '..model.Name..' '..key)
        assert(constraint.MinTextSize==(if key=='Name' then 6 else 5)
            and constraint.MaxTextSize==(if key=='Name' then 24 else 16),'Preserve original font-size caps')
        local bounds,size=label.TextBounds,label.AbsoluteSize
        local fits=bounds.X<=size.X+1 and bounds.Y<=size.Y+1
        result[key]={text=label.Text,bounds={bounds.X,bounds.Y},cell={size.X,size.Y},
            fitsCell=fits,textScaled=label.TextScaled,textWrapped=label.TextWrapped}
        if candidate then
            assert(bounds.X>0 and bounds.Y>0,'Nearby candidate has no measured text')
            overflow=overflow or not fits
        end
    end
    if candidate then
        candidates+=1
        if overflow then overflowCandidates+=1 end
    end
    table.insert(measurements,result)
end
table.sort(measurements,function(a,b) return a.id<b.id end)
return {rows=EXPECTED_ROWS,mode=EXPECTED_MODE,stress=EXPECTED_STRESS,
    revision=preview:GetAttribute('PreviewRevision'),candidates=candidates,overflowCandidates=overflowCandidates,
    camera={position=tostring(camera.CFrame.Position),look=tostring(camera.CFrame.LookVector)},
    measurements=measurements,
    caveat='Measured text fit/projection does not prove legibility. Compare front, oblique and rear views for name overlap, face obstruction and through-wall clutter.'}
