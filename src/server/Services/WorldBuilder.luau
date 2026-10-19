--!strict
local Shared=game:GetService("ReplicatedStorage"):WaitForChild("Shared")
local Factory=require(Shared.ModelFactory)
local Map=require(Shared.MapSpec)
local Catalog=require(Shared.CreatureCatalog)
local World={}
function World.build()
    local old=workspace:FindFirstChild("MergeABrainrotGenerated")
    if old then old:Destroy() end
    local root=Instance.new("Folder"); root.Name="MergeABrainrotGenerated"
    local mint=Color3.fromRGB(182,223,202); local cream=Color3.fromRGB(255,244,220)
    Factory.part(root,"Meadow",Map.GroundSize,CFrame.new(0,-0.5,0),Color3.fromRGB(137,187,143),nil,true)
    Factory.part(root,"Plot",Map.PlotSize,CFrame.new(Map.Origin+Vector3.new(0,0.1,0)),mint,nil,true)
    Factory.part(root,"Walkway",Vector3.new(14,0.15,55),CFrame.new(0,0.08,0),cream)
    for _,x in {-26,26} do Factory.part(root,"SideFence",Vector3.new(0.6,2,52),CFrame.new(x,1,52),cream,nil,true) end
    Factory.part(root,"BackFence",Vector3.new(52,2,0.6),CFrame.new(0,1,78),cream,nil,true)
    for _,x in {-18,18} do Factory.part(root,"FrontFence",Vector3.new(16,2,0.6),CFrame.new(x,1,26),cream,nil,true) end
    for slot=1,12 do
        local x=((slot-1)%3-1)*14; local z=48+math.floor((slot-1)/3)*8
        local pad=Factory.part(root,"Slot"..slot,Vector3.new(5.5,0.25,5.5),CFrame.new(x,0.3,z),cream)
        pad:SetAttribute("Slot",slot)
    end
    local sell=Factory.part(root,"SellPad",Vector3.new(10,0.3,10),CFrame.new(Map.Sell),Color3.fromRGB(245,188,72))
    local buy=Factory.part(root,"BuyPad",Vector3.new(10,0.3,10),CFrame.new(Map.Buy),Color3.fromRGB(119,185,245))
    Factory.label(sell,"SELL MINIS\nWalk onto pad",150,52)
    Factory.label(buy,"BUY TIER 1\n20 Coins",150,52)
    local sign=Factory.part(root,"OwnerSign",Vector3.new(8,3.5,0.5),CFrame.new(-25,4,42)*CFrame.Angles(0,math.pi/2,0),cream)
    local ownerLabel=Factory.label(sign,"MINI MEADOW\nYour little beginning",210,56)
    for _,data in {{-36,20},{36,20},{-36,77},{36,77},{-55,-15},{55,-15}} do
        Factory.part(root,"TreeTrunk",Vector3.new(2,6,2),CFrame.new(data[1],3,data[2]),Color3.fromRGB(161,121,87),nil,true)
        Factory.part(root,"TreeCrown",Vector3.new(9,10,9),CFrame.new(data[1],9,data[2]),Color3.fromRGB(95,158,113),Enum.PartType.Ball)
    end
    local spawn=Instance.new("SpawnLocation")
    spawn.Name="FarmSpawn"; spawn.Anchored=true; spawn.CanCollide=false; spawn.CanTouch=false
    spawn.Transparency=1; spawn.Size=Vector3.new(6,1,6); spawn.CFrame=Map.Spawn; spawn.Neutral=true; spawn.Parent=root
    local producers=Instance.new("Folder"); producers.Name="Producers"; producers.Parent=root
    local tokens=Instance.new("Folder"); tokens.Name="Minis"; tokens.Parent=root
    root.Parent=workspace
    local lighting=game:GetService("Lighting")
    lighting.ClockTime=14; lighting.Brightness=2; lighting.Ambient=Color3.fromRGB(150,160,170)
    return {root=root,producers=producers,tokens=tokens,ownerLabel=ownerLabel,sell=sell,buy=buy}
end
function World.render(world: any, state: any)
    local present={}
    for _,p in state.producers do
        present[p.id]=true
        if not world.producers:FindFirstChild(p.id) then
            local pos=Vector3.new(((p.slot-1)%3-1)*14,0.5,48+math.floor((p.slot-1)/3)*8)
            Factory.producer(world.producers,p.id,Catalog[p.speciesId],pos)
        end
    end
    for _,child in world.producers:GetChildren() do if not present[child.Name] then child:Destroy() end end
    present={}
    for _,t in state.tokens do
        present[t.id]=true
        if not world.tokens:FindFirstChild(t.id) then Factory.mini(world.tokens,t,Catalog[t.speciesId]) end
    end
    for _,child in world.tokens:GetChildren() do if not present[child.Name] then child:Destroy() end end
end
function World.clear(world: any)
    world.producers:ClearAllChildren(); world.tokens:ClearAllChildren()
    world.ownerLabel.Text="MINI MEADOW\nReady for a farmer"
end
return World
