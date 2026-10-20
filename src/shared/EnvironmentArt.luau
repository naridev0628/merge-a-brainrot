--!strict
-- Original, asset-free brick scenery. Tree/lighthouse pivots sit on the ground;
-- the octagon pivot is the center of its walkable top face.
local Environment = {}
local BrickStudOcclusion = require(script.Parent.BrickStudOcclusion)

local wood = Color3.fromRGB(112, 80, 54)
local bark = Color3.fromRGB(128, 93, 62)
local leafBottom = Color3.fromRGB(65, 113, 50)
local leafTop = Color3.fromRGB(139, 184, 95)
local cream = Color3.fromRGB(255, 239, 190)
local red = Color3.fromRGB(211, 43, 36)
local white = Color3.fromRGB(255, 249, 224)
local created = 0

local function block(parent: Instance, name: string, size: Vector3, cf: CFrame, color: Color3, solid: boolean): Part
    local part = Instance.new('Part')
    part.Name = name
    part.Size = size
    part.CFrame = cf
    part.Color = color
    part.Material = Enum.Material.Plastic
    part.Anchored = true
    part.CanCollide = solid
    part.CanTouch = false
    part.CanQuery = solid
    part.TopSurface = Enum.SurfaceType.Smooth
    part.BottomSurface = Enum.SurfaceType.Smooth
    part.Parent = parent
    created += 1
    if created % 240 == 0 then task.wait() end
    return part
end

type StudBudget = { remaining: number }

-- Raised square studs remain legible in modern lighting, unlike legacy surface
-- textures. Every ornament is noncolliding, including ornaments on solid wood.
local function stud(parent: Instance, cf: CFrame, color: Color3, budget: StudBudget, size: number?)
    if budget.remaining <= 0 then return end
    budget.remaining -= 1
    local width = size or .48
    block(parent, 'SquareStud', Vector3.new(width, .14, width), cf, color:Lerp(white, .075), false)
end

local function coveredTopStud(cf: CFrame, cover: Part): boolean
    if cover.Transparency~=0 or cover.Shape~=Enum.PartType.Block then return false end
    local relative=cover.CFrame:ToObjectSpace(cf)
    local right,up,back=relative.RightVector,relative.UpVector,relative.LookVector
    local hx=math.abs(right.X)*.24+math.abs(up.X)*.07+math.abs(back.X)*.24
    local hy=math.abs(right.Y)*.24+math.abs(up.Y)*.07+math.abs(back.Y)*.24
    local hz=math.abs(right.Z)*.24+math.abs(up.Z)*.07+math.abs(back.Z)*.24
    local p,size=relative.Position,cover.Size
    return BrickStudOcclusion.isFullyInside(p.X,p.Y,p.Z,hx,hy,hz,size.X,size.Y,size.Z)
end

local function brickStuds(body: Part, budget: StudBudget, sides: boolean?, topCover: Part?, originalColor: Color3?)
    local parent=body.Parent :: Instance
    -- Tree palettes contain fractional channels; preserve them until the stud
    -- blend rather than blending a second time from BasePart's 8-bit readback.
    local size,cf,color=body.Size,body.CFrame,originalColor or body.Color
    local columns = math.max(1, math.floor(size.X / 1.55))
    local rows = math.max(1, math.floor(size.Z / 1.55))
    for x = 1, columns do
        for z = 1, rows do
            local studCF=cf * CFrame.new((x - (columns + 1) / 2) * 1.55, size.Y / 2 + .07, (z - (rows + 1) / 2) * 1.55)
            if topCover and coveredTopStud(studCF,topCover) then
                -- Preserve the old allocation, including any later side/roof
                -- cutoff. Hidden ornaments must not spend their budget elsewhere.
                budget.remaining=math.max(0,budget.remaining-1)
            else
                stud(parent, studCF, color, budget)
            end
        end
    end
    if sides then
        local levels = math.max(1, math.floor(size.Y / 1.55))
        for level = 1, levels do
            local y = (level - (levels + 1) / 2) * 1.55
            for _, sign in {-1, 1} do
                for x = 1, columns do
                    stud(parent, cf * CFrame.new((x - (columns + 1) / 2) * 1.55, y, sign * (size.Z / 2 + .07)) * CFrame.Angles(math.pi / 2, 0, 0), color, budget)
                end
                for z = 1, rows do
                    stud(parent, cf * CFrame.new(sign * (size.X / 2 + .07), y, (z - (rows + 1) / 2) * 1.55) * CFrame.Angles(0, 0, math.pi / 2), color, budget)
                end
            end
        end
    end
end

local function studdedBrick(parent: Instance, name: string, size: Vector3, cf: CFrame, color: Color3, solid: boolean, budget: StudBudget, sides: boolean?): Part
    local body = block(parent, name, size, cf, color, solid)
    brickStuds(body,budget,sides,nil,color)
    return body
end

local function finish(model: Model, parent: Instance, cf: CFrame, scale: number): Model
    model.WorldPivot = CFrame.identity
    model:ScaleTo(scale)
    model:PivotTo(cf)
    model.Parent = parent
    return model
end

local function timber(parent: Instance, name: string, from: Vector3, to: Vector3, width: number)
    local direction = to - from
    -- The long axis is Z, so the branch ends connect exactly at the given points.
    local frame = CFrame.lookAt((from + to) / 2, to)
    block(parent, name, Vector3.new(width, width, direction.Magnitude + .18), frame, wood, true)
end

function Environment.tree(parent: Instance, cf: CFrame, scale: number, variant: number): Model
    assert(scale > 0, 'Tree scale must be positive')
    local model = Instance.new('Model')
    local choice = ((math.floor(variant) - 1) % 3) + 1
    model.Name = ({'SteppedPine', 'BranchingTree', 'WideCrownTree'})[choice]
    model:SetAttribute('TreeVariant', choice)
    model:SetAttribute('NativeBrickArt', true)
    local budget: StudBudget = {remaining = 310}

    -- Four low stepped roots connect to the trunk and block the player.
    for index = 0, 3 do
        local turn = CFrame.Angles(0, index * math.pi / 2, 0)
        studdedBrick(model, 'SolidRoot', Vector3.new(3.3, .65, 1.15), turn * CFrame.new(1.65, .325, 0), wood, true, budget)
        block(model, 'RootShoulder', Vector3.new(1.75, 1.25, 1.3), turn * CFrame.new(.95, .625, 0), bark, true)
    end
    local trunkHeight = if choice == 1 then 11.6 elseif choice == 2 then 11.2 else 9.5
    studdedBrick(model, 'SolidTrunk', Vector3.new(1.85, trunkHeight, 1.85), CFrame.new(0, trunkHeight / 2, 0), wood, true, budget)
    block(model, 'BarkStep', Vector3.new(2.05, 1.15, 2.05), CFrame.new(0, 3.1, 0), bark, true)

    local function leaves(name: string, position: Vector3, size: Vector3)
        local green = leafBottom:Lerp(leafTop, math.clamp((position.Y - 5.5) / 10.5, 0, 1))
        studdedBrick(model, name, size, CFrame.new(position), green, false, budget, true)
    end
    if choice == 1 then
        -- Clean triangular silhouette with visibly separated stair-step boughs.
        for index, layer in {
            {7.0, 10.8, 8.3}, {9.2, 8.8, 7.2}, {11.4, 6.7, 5.6},
            {13.5, 4.8, 4.2}, {15.3, 2.8, 2.8},
        } do
            local y, width, depth = layer[1], layer[2], layer[3]
            timber(model, 'SolidBranch', Vector3.new(0, y - 1.4, 0), Vector3.new(width * .32, y - .5, 0), .8)
            timber(model, 'SolidBranch', Vector3.new(0, y - 1.4, 0), Vector3.new(-width * .32, y - .5, 0), .8)
            leaves('PineTier' .. index, Vector3.new(0, y, 0), Vector3.new(width, 1.7, depth))
        end
    elseif choice == 2 then
        -- Asymmetric, readable branch arms and distinct block clusters.
        timber(model, 'SolidBranch', Vector3.new(0, 5.4, 0), Vector3.new(3.6, 7.2, .6), 1.05)
        timber(model, 'SolidBranch', Vector3.new(0, 7.6, 0), Vector3.new(-3.3, 10.1, -.4), 1.1)
        timber(model, 'SolidBranch', Vector3.new(.1, 9.2, 0), Vector3.new(2.8, 12.5, .8), .95)
        leaves('LowBough', Vector3.new(3.7, 7.5, .6), Vector3.new(4.1, 2.5, 3.7))
        leaves('LeftCanopy', Vector3.new(-3.0, 10.8, -.4), Vector3.new(5.1, 3.6, 4.9))
        leaves('RightCanopy', Vector3.new(2.5, 12.5, .6), Vector3.new(5.2, 3.7, 4.7))
        leaves('CenterCanopy', Vector3.new(-.4, 13.1, -.3), Vector3.new(5.6, 4.1, 5.7))
        leaves('LeftCrownStep', Vector3.new(-2.8, 13.0, -.5), Vector3.new(3.3, 1.0, 3.1))
        leaves('RightCrownStep', Vector3.new(2.4, 14.8, .5), Vector3.new(3.3, .9, 3.1))
        leaves('LightCrown', Vector3.new(-.5, 15.6, -.2), Vector3.new(3.5, 1.0, 3.4))
    else
        -- Broad low crown, multiple exposed branches, offset upper plates.
        for _, tip in {Vector3.new(-4.0, 8.1, 0), Vector3.new(3.9, 8.6, .7), Vector3.new(0, 8.6, -3)} do
            timber(model, 'SolidBranch', Vector3.new(0, 5.2, 0), tip, 1.1)
        end
        leaves('WideLowerCrown', Vector3.new(0, 9.2, 0), Vector3.new(12.4, 2.5, 8.7))
        leaves('LeftCrownStep', Vector3.new(-3.0, 11.2, -.4), Vector3.new(6.0, 1.5, 6.6))
        leaves('RightCrownStep', Vector3.new(3.0, 11.5, .5), Vector3.new(5.5, 1.8, 6.4))
        leaves('UpperCrown', Vector3.new(-.5, 12.9, -.3), Vector3.new(6.6, 1.2, 5.3))
        leaves('LightCrown', Vector3.new(-1, 14.0, -.4), Vector3.new(3.7, 1.0, 3.5))
    end
    return finish(model, parent, cf, scale)
end

function Environment.lighthouse(parent: Instance, cf: CFrame, scale: number): Model
    assert(scale > 0, 'Lighthouse scale must be positive')
    local model = Instance.new('Model')
    model.Name = 'RedWhiteLighthouse'
    model:SetAttribute('NativeBrickArt', true)
    local budget: StudBudget = {remaining = 660}
    local tower: {Part}={}
    local function towerBrick(name: string,size: Vector3,cf: CFrame,color: Color3)
        table.insert(tower,block(model,name,size,cf,color,true))
    end
    towerBrick('CreamFoundation', Vector3.new(10.6, 1, 10.6), CFrame.new(0, .5, 0), cream)
    for index = 0, 5 do
        local y = 1 + index * 4
        towerBrick('RedTowerBand', Vector3.new(8.2, 3, 8.2), CFrame.new(0, y + 1.5, 0), red)
        towerBrick('WhiteTowerBand', Vector3.new(8.7, 1, 8.7), CFrame.new(0, y + 3.5, 0), white)
    end
    -- A front door and small deep blue windows on all four faces.
    local dark = Color3.fromRGB(37, 51, 58)
    block(model, 'DoorFrame', Vector3.new(2.6, 4.1, .35), CFrame.new(0, 3.05, -4.23), cream, false)
    block(model, 'Door', Vector3.new(1.8, 3.35, .42), CFrame.new(0, 2.7, -4.42), dark, false)
    block(model, 'DoorKnob', Vector3.new(.25, .25, .25), CFrame.new(.55, 2.6, -4.71), cream, false)
    for side = 0, 3 do
        local turn = CFrame.Angles(0, side * math.pi / 2, 0)
        for _, y in {10.5, 18.5} do
            block(model, 'WindowFrame', Vector3.new(1.7, 2.1, .27), turn * CFrame.new(0, y, -4.22), cream, false)
            block(model, 'BlueWindow', Vector3.new(1.1, 1.5, .3), turn * CFrame.new(0, y, -4.4), Color3.fromRGB(65, 125, 152), false)
        end
    end
    towerBrick('LanternBalcony', Vector3.new(10, .8, 10), CFrame.new(0, 25.4, 0), cream)
    -- Actual opaque Parts provide the covers. Delay ornament creation until the
    -- next brick exists, while the unfinished model is still outside Workspace.
    for index,body in tower do
        brickStuds(body,budget,index>1 and index<#tower,tower[index+1])
    end
    for _, x in {-3.65, 3.65} do
        for _, z in {-3.65, 3.65} do
            block(model, 'LanternPillar', Vector3.new(.65, 4.3, .65), CFrame.new(x, 27.9, z), white, true)
        end
    end
    for side = 0, 3 do
        local turn = CFrame.Angles(0, side * math.pi / 2, 0)
        local pane = block(model, 'LanternGlass', Vector3.new(6.6, 3.7, .12), turn * CFrame.new(0, 27.9, -3.65), Color3.fromRGB(170, 224, 232), false)
        pane.Material = Enum.Material.Glass
        pane.Transparency = .6
        block(model, 'LanternRail', Vector3.new(7.7, .3, .35), turn * CFrame.new(0, 27, -3.8), white, false)
    end
    local beacon = block(model, 'Beacon', Vector3.new(1.5, 2.7, 1.5), CFrame.new(0, 27.9, 0), Color3.fromRGB(255, 221, 90), false)
    beacon.Material = Enum.Material.Neon
    local light = Instance.new('PointLight')
    light.Name = 'BeaconGlow'
    light.Color = beacon.Color
    light.Brightness = 1.5
    light.Range = 26
    light.Parent = beacon
    -- Replenish a small roof allocation so its uppermost plates always get studs.
    budget.remaining = 110
    local roof: {Part}={}
    for index, width in {10.3, 8.5, 6.5, 4.3} do
        table.insert(roof,block(model, 'SteppedCreamRoof', Vector3.new(width, .7, width), CFrame.new(0, 30.25 + (index - 1) * .7, 0), cream, true))
    end
    for index,body in roof do
        brickStuds(body,budget,false,roof[index+1])
    end
    block(model, 'RoofFinial', Vector3.new(.75, 1.3, .75), CFrame.new(0, 33.35, 0), red, false)
    return finish(model, parent, cf, scale)
end

function Environment.octagon(parent: Instance, center: CFrame, radius: number, thickness: number, color: Color3,
    skipStud: ((number,number,number,number,number) -> boolean)?, nativeStuds: boolean?): Model
    assert(radius > 0 and thickness > 0, 'Octagon radius and thickness must be positive')
    local model = Instance.new('Model')
    model.Name = 'StuddedOctagonalPlatform'
    model:SetAttribute('NativeBrickArt', true)
    model:SetAttribute('Radius', radius)
    local a = radius * (math.sqrt(2) - 1)
    local leg = radius - a
    local middle=block(model, 'CenterSlab', Vector3.new(2 * a, thickness, 2 * a), CFrame.new(0, -thickness / 2, 0), color, true)
    if nativeStuds then middle.TopSurface=Enum.SurfaceType.Studs end
    for side = 0, 3 do
        local turn = CFrame.Angles(0, side * math.pi / 2, 0)
        local edge=block(model, 'StraightEdgeSlab', Vector3.new(leg, thickness, 2 * a), turn * CFrame.new(a + leg / 2, -thickness / 2, 0), color, true)
        if nativeStuds then edge.TopSurface=Enum.SurfaceType.Studs end
        -- A horizontal right triangular prism closes each corner exactly:
        -- (a,a), (radius,a), (a,radius). The top remains completely flat.
        local wedge = Instance.new('WedgePart')
        wedge.Name = 'DiagonalCornerSlab'
        wedge.Size = Vector3.new(thickness, leg, leg)
        wedge.CFrame = turn * CFrame.fromMatrix(Vector3.new(a + leg / 2, -thickness / 2, a + leg / 2), Vector3.yAxis, Vector3.xAxis, -Vector3.zAxis)
        wedge.Color = color
        wedge.Material = Enum.Material.Plastic
        wedge.Anchored = true
        wedge.CanCollide = true
        wedge.CanTouch = false
        wedge.TopSurface = Enum.SurfaceType.Smooth
        wedge.BottomSurface = Enum.SurfaceType.Smooth
        -- This horizontal wedge's local +X (RightSurface) is world up.
        if nativeStuds then wedge.RightSurface=Enum.SurfaceType.Studs end
        wedge.Parent = model
    end
    -- The hub uses a uniform native grid. Omitted/false retains the raised
    -- ornament grid and optional containment callback for other callers.
    if nativeStuds then return finish(model,parent,center,1) end
    local pitch = math.max(2.0, radius / 25)
    local width = math.min(.55, pitch * .28)
    local budget: StudBudget = {remaining = 2500}
    local limit = math.floor((radius - width) / pitch)
    for x = -limit, limit do
        for z = -limit, limit do
            local px, pz = x * pitch, z * pitch
            if math.abs(px) + math.abs(pz) + width <= radius + a then
                -- Callback uses the octagon's local coordinates and full height.
                if not skipStud or not skipStud(px,pz,width,0,.14) then
                    stud(model, CFrame.new(px, .07, pz), color, budget, width)
                end
            end
        end
    end
    return finish(model, parent, center, 1)
end

return Environment
