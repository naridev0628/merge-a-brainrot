-- Read-only, ten-second client sample. Run after the desired farm population
-- has settled; repeat the same camera route at each capacity for comparison.
local RunService=game:GetService('RunService')
local Stats=game:GetService('Stats')
local Collection=game:GetService('CollectionService')
local root=assert(workspace:FindFirstChild('MergeABrainrotGenerated'))
local function inventory()
    local counts={instances=0,parts=0,meshes=0,shelfParts=0,producerParts=0,miniParts=0}
    for _,item in root:GetDescendants() do
        counts.instances+=1
        if item:IsA('BasePart') then
            counts.parts+=1
            if item:IsA('MeshPart') then counts.meshes+=1 end
            if item:FindFirstAncestor('StackRows') then counts.shelfParts+=1
            elseif item:FindFirstAncestor('Producers') then counts.producerParts+=1
            elseif item:FindFirstAncestor('Minis') then counts.miniParts+=1 end
        end
    end
    counts.producerModels=#Collection:GetTagged('BrainrotProducer')
    counts.miniModels=#Collection:GetTagged('ConveyorMini')
    return counts
end
local before=inventory()
local memoryBefore=Stats:GetTotalMemoryUsageMb()
local samples={}
local total=0
local started=os.clock()
while os.clock()-started<10 do
    local delta=RunService.RenderStepped:Wait()
    table.insert(samples,delta*1000)
    total+=delta
end
table.sort(samples)
local function percentile(fraction)
    return samples[math.max(1,math.ceil(#samples*fraction))]
end
return {
    sampleSeconds=os.clock()-started,frames=#samples,
    meanFrameMs=total*1000/#samples,p50FrameMs=percentile(.50),
    p95FrameMs=percentile(.95),p99FrameMs=percentile(.99),
    maxFrameMs=samples[#samples],
    memoryBeforeMb=memoryBefore,memoryAfterMb=Stats:GetTotalMemoryUsageMb(),
    before=before,after=inventory(),
    note='Client observation only; no population, camera, state, or graphics settings were changed. Ten seconds is not a device or memory-soak certification.',
}
