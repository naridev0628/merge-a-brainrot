-- Verifies generated shelf rows plus isolated rows without parenting test geometry.
local Shared=game.ReplicatedStorage.Shared
local Config=require(Shared.Config)
local Catalog=require(Shared.CreatureCatalog)
local Map=require(Shared.MapSpec)
local Core=require(game.ServerScriptService.Domain.FarmCore)
local Shelves=require(Shared.DisplayShelves)
local layout=Core.new(Config,Catalog)
local forbidden={BackStud=true,DividerStud=true,PlatformStud=true,PlatformFrontStud=true}
local expectedBudget=1+22*Config.Columns
local function near(a,b,message)
    assert((a-b).Magnitude<.001,message)
end
local function audit(shelf,row,frame,scale)
    local byName={}
    local count=0
    for _,part in shelf:GetChildren() do
        assert(part:IsA('BasePart'),'Rows should contain only their bounded native geometry')
        count+=1
        assert(part.Anchored and not part.CanCollide and not part.CanTouch,'Shelf physics flags changed')
        assert(not forbidden[part.Name],'Small repeated studs should use native surfaces: '..part.Name)
        byName[part.Name]=byName[part.Name] or {}
        table.insert(byName[part.Name],part)
    end
    assert(count==expectedBudget and count<=300,'Each shelf row must retain its geometry within 300 parts')
    assert(#byName.DisplayBrickStud==15*Config.Columns,'Keep the large physical plinth studs')
    local function at(name,x,size,position,color)
        local found=nil
        for _,part in byName[name] or {} do
            local logical=frame:PointToObjectSpace(part.Position)/scale
            if math.abs(logical.X-x)<.001 then
                assert(not found,'Duplicate structural part '..name)
                found=part
            end
        end
        assert(found,'Missing '..name)
        near(found.Size/scale,size,name..' size changed')
        near(frame:PointToObjectSpace(found.Position)/scale,position,name..' moved')
        if color then near(Vector3.new(found.Color.R,found.Color.G,found.Color.B),
            Vector3.new(color.R,color.G,color.B),name..' palette changed') end
        return found
    end
    local rowY=(row-1)*Config.RowHeight
    local height=Config.DisplayPlatformHeight
    local lift=height-.5
    local width=Config.ColumnSpacing-.1
    local base=at('ShelfBase',0,Vector3.new(Config.Columns*Config.ColumnSpacing+1,.45,7),
        Vector3.new(0,.225+rowY,Config.DisplayZ),Color3.fromRGB(255,174,22))
    assert(base.TopSurface==Enum.SurfaceType.Studs)
    for column=1,Config.Columns do
        local slot=(row-1)*Config.Columns+column
        local position=layout:slotPosition(slot)
        local x=position.x
        local plinth=at('DisplayPlatform',x,Vector3.new(Config.ColumnSpacing*.88,height,5.7),
            Vector3.new(x,height/2+rowY,Config.DisplayZ),Color3.fromRGB(255,223,122))
        local support=frame:PointToObjectSpace(plinth.CFrame:PointToWorldSpace(Vector3.new(0,plinth.Size.Y/2,0)))/scale
        assert(math.abs(support.Y-position.y)<.001,'Producer foot/support plane changed')
        assert(plinth.TopSurface==Enum.SurfaceType.Studs)
        local back=at('DisplayBack',x,Vector3.new(width,5.8,.25),
            Vector3.new(x,3.1+lift+rowY,Config.DisplayZ+3.45),Color3.fromRGB(178,128,52))
        assert(back.FrontSurface==Enum.SurfaceType.Studs,'Back wall needs visible native front studs')
        local divider=at('DisplayDivider',x-width/2,Vector3.new(.22,4.5,6.8),
            Vector3.new(x-width/2,2.45+lift+rowY,Config.DisplayZ),Color3.fromRGB(217,164,66))
        assert(divider.LeftSurface==Enum.SurfaceType.Studs and divider.RightSurface==Enum.SurfaceType.Studs)
        local glow=at('Slot'..slot,x,Vector3.new(Config.ColumnSpacing*.9,.12,5.9),
            Vector3.new(x,height-.12+rowY,Config.DisplayZ),nil)
        assert(glow.Material==Enum.Material.Neon,'World.render needs a recolorable neon slot')
        at('DividerTopTrim',x-width/2,Vector3.new(.38,.22,7),
            Vector3.new(x-width/2,rowY+lift+4.8,Config.DisplayZ),Color3.fromRGB(255,215,103))
        at('BayTopTrim',x,Vector3.new(width,.25,.42),
            Vector3.new(x,rowY+lift+6,Config.DisplayZ+3.45),Color3.fromRGB(255,215,103))
        local front=at('PlatformFrontTrim',x,Vector3.new(width,height,.4),
            Vector3.new(x,rowY+height/2,Config.DisplayZ-3.4),Color3.fromRGB(255,195,42))
        assert(front.FrontSurface==Enum.SurfaceType.Studs,'Front gold fascia needs native studs')
    end
    return count
end
local generated=assert(workspace:FindFirstChild('MergeABrainrotGenerated'))
local liveRows=0
for _,plot in generated:GetChildren() do
    if not plot.Name:match('^Plot%d+$') then continue end
    for _,model in plot:GetDescendants() do
        if model:IsA('Model') and model:FindFirstChild('ShelfBase') then
            audit(model,assert(tonumber(model.Name)),plot:GetPivot(),Map.PlotScale)
            liveRows+=1
        end
    end
end
assert(liveRows>0,'Exercise at least one World.render-generated row')

for row=1,math.ceil(Config.Slots/Config.Columns) do
    local shelf=Shelves.buildRow(row,layout)
    local ok,err=pcall(function()
        assert(shelf.Parent==nil and shelf.Name==tostring(row),'Build off-world with the row lookup name')
        assert(shelf:GetPivot()==CFrame.identity,'World scaling depends on an identity row pivot')
        audit(shelf,row,CFrame.identity,1)
        local frame=CFrame.new(120,0,-80)*CFrame.Angles(0,math.pi/3,0)
        shelf:ScaleTo(Map.PlotScale);shelf:PivotTo(frame)
        audit(shelf,row,frame,Map.PlotScale)
        local glow=shelf:FindFirstChild('Slot'..((row-1)*Config.Columns+1))
        glow.Color=Color3.fromRGB(12,34,56)
        assert(glow.Color==Color3.fromRGB(12,34,56),'Slot lookup/recolor must stay compatible with World.render')
    end)
    shelf:Destroy()
    assert(ok,err)
end
return string.format('PASS %d live rows; five-row dimensions, support plane, slot lookup, native surfaces, physics and %d parts/row after scaling',liveRows,expectedBudget)
