-- Read-only measurement after root positions the camera from Server cameraHints.
-- Change EXPECTED_COUNT/LEVEL to match _G.ProcessorBoardPreview.setCount(...).
local EXPECTED_COUNT=2147483647
local EXPECTED_LEVEL=0
local RunService=game:GetService('RunService')
assert(RunService:IsStudio() and RunService:IsClient(),'Studio Client required')
local preview=assert(workspace:WaitForChild('ProcessorBoardPreview',10),'Preview did not replicate')
local function ready()
    if not preview:GetAttribute('Ready') or preview:GetAttribute('PreviewCount')~=EXPECTED_COUNT
        or preview:GetAttribute('PreviewLevel')~=EXPECTED_LEVEL then return false end
    local board=preview:FindFirstChild('ProcessorSign')
    local processor=board and board:FindFirstChild('Processor')
    local display=processor and processor:FindFirstChild('ProcessorDisplay')
    return display and display.Adornee and display:FindFirstChild('Title') and display:FindFirstChild('Queued')
        and display:FindFirstChild('Rate') and display.Queued.Text==preview:GetAttribute('PreviewQueueText')
        and display.Rate.Text==preview:GetAttribute('PreviewRateText')
end
local deadline=os.clock()+10
repeat if ready() then break end;RunService.Heartbeat:Wait() until os.clock()>=deadline
assert(ready(),'Requested preview count/UI did not replicate within ten seconds')
RunService.RenderStepped:Wait();RunService.RenderStepped:Wait()
local display=preview.ProcessorSign.Processor.ProcessorDisplay
local face=display.Adornee
local camera=assert(workspace.CurrentCamera)
local distance=(camera.CFrame.Position-face.Position).Magnitude
local projected,onScreen=camera:WorldToViewportPoint(face.Position)
local frontFacing=(camera.CFrame.Position-face.Position):Dot(face.CFrame.LookVector)>0
assert(frontFacing and onScreen and projected.Z>0 and distance<display.MaxDistance,
    'Position the camera on the visible board front within its existing cutoff before measuring')
assert(display.CanvasSize==Vector2.new(690,300) and not display.AlwaysOnTop,'Preserve board canvas and occlusion')
local result={count=EXPECTED_COUNT,level=EXPECTED_LEVEL,revision=preview:GetAttribute('PreviewRevision'),
    distance=distance,maxDistance=display.MaxDistance,frontFacing=frontFacing,lines={},
    camera={position=tostring(camera.CFrame.Position),look=tostring(camera.CFrame.LookVector)}}
for _,key in {'Title','Queued','Rate'} do
    local label=assert(display:FindFirstChild(key))
    local bounds,size=label.TextBounds,label.AbsoluteSize
    local constraint=label:FindFirstChildWhichIsA('UITextSizeConstraint')
    local fits=bounds.X<=size.X+1 and bounds.Y<=size.Y+1
    result.lines[key]={text=label.Text,bounds={bounds.X,bounds.Y},cell={size.X,size.Y},
        textScaled=label.TextScaled,textWrapped=label.TextWrapped,font=label.Font.Name,textSize=label.TextSize,
        minimum=if constraint then constraint.MinTextSize else nil,
        maximum=if constraint then constraint.MaxTextSize else nil,fits=fits}
    assert(bounds.X>0 and bounds.Y>0,'Visible board line has no measured text: '..key)
    assert(fits,'Text exceeds board cell: '..key)
    if key=='Queued' then assert(label.TextScaled,'Count scaling must remain enabled') end
end
result.scope='Actual native cell/font measurements; matched close/approach screenshots establish visual hierarchy'
return result
