-- Read-only current acceptance. The requested map review removes the lighthouse;
-- historical stud containment arithmetic remains in brick-stud-occlusion.luau.
local root=assert(workspace:FindFirstChild('MergeABrainrotGenerated'))
assert(not root:FindFirstChild('RedWhiteLighthouse',true),'Removed lighthouse must not return')
local scenery=assert(root:FindFirstChild('HubScenery'))
for index=1,2 do
    local stall=assert(scenery:FindFirstChild('BrainrotMarket'..index),'The reviewed hub must retain its new markets')
    local merchant=assert(stall:FindFirstChild(if index==1 then 'BrainrotLogKeeper' else 'BrainrotCoffeeKeeper'))
    assert(merchant:GetAttribute('BlenderAuthored')==true,'Market characters must use authored geometry')
end
return 'PASS removed lighthouse stays absent and both authored hub merchants remain present'
