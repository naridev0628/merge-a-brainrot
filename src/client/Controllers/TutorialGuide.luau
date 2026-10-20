--!strict
local Guide={}
Guide.__index=Guide
local count,spacing,speed=12,2.8,6
local function arrow(folder: Instance,name: string): {BasePart}
    local pieces={}
    -- Two triangular prisms form a full arrowhead. Their extrusion is the
    -- visible Y thickness, unlike the previous pair of flat diagonal strips.
    for index,class in {'Part','WedgePart','WedgePart'} do
        local p=Instance.new(class) :: BasePart
        p.Name=name..(if index==1 then 'Shaft' else 'Head')
        p.Size=if index==1 then Vector3.new(.32,.20,1.02) else Vector3.new(.20,.72,.88)
        p.Anchored=true;p.CanCollide=false;p.CanTouch=false;p.CanQuery=false
        p.Material=Enum.Material.SmoothPlastic;p.Color=Color3.fromRGB(255,255,255);p.Transparency=1
        p.TopSurface=Enum.SurfaceType.Smooth;p.BottomSurface=Enum.SurfaceType.Smooth;p.CastShadow=true
        p.Parent=folder;table.insert(pieces,p)
    end
    return pieces
end
local function pose(pieces: {BasePart},frame: CFrame,transparency: number)
    pieces[1].CFrame=frame*CFrame.new(0,0,.38)
    pieces[2].CFrame=frame*CFrame.new(-.36,0,-.4)*CFrame.Angles(0,0,math.pi/2)
    pieces[3].CFrame=frame*CFrame.new(.36,0,-.4)*CFrame.Angles(0,0,-math.pi/2)
    for _,p in pieces do p.Transparency=transparency end
end
function Guide.new()
    local self: any=setmetatable({parts={},arrows={},lights={}},Guide)
    local folder=Instance.new('Folder'); folder.Name='LocalTutorialArrows'; folder.Parent=workspace; self.folder=folder
    local marker=Instance.new('Part'); marker.Name='FirstBrainrotArrow'; marker.Anchored=true; marker.Transparency=1; marker.CanCollide=false; marker.CanTouch=false; marker.CanQuery=false; marker.Parent=folder; self.marker=marker
    local gui=Instance.new('BillboardGui'); gui.Name='StarterPrompt'; gui.Size=UDim2.fromOffset(250,50); gui.AlwaysOnTop=false; gui.Enabled=false; gui.Parent=marker; self.markerGui=gui
    local label=Instance.new('TextLabel'); label.Size=UDim2.new(1,0,0,50); label.Text='Buy your first Brainrot!'; label.TextWrapped=true; label.Font=Enum.Font.FredokaOne; label.TextSize=23; label.TextColor3=Color3.fromRGB(142,255,58); label.TextStrokeTransparency=0; label.BackgroundTransparency=1; label.Parent=gui
    self.starterParts=arrow(folder,'StarterArrow')
    for i=1,count do
        local pieces=arrow(folder,'BodyStreamArrow')
        self.arrows[i]=pieces
        for _,p in pieces do table.insert(self.parts,p) end
        if i<=3 then
            local glow=Instance.new('PointLight')
            glow.Color=Color3.fromRGB(255,255,255);glow.Brightness=.12;glow.Range=2
            glow.Shadows=false;glow.Enabled=false;glow.Parent=pieces[1];self.lights[i]=glow
        end
    end
    return self
end
function Guide.showStarter(self: any,target: Vector3?)
    self.markerGui.Enabled=target~=nil
    if target then
        self.marker.Position=target+Vector3.new(0,7+math.sin(os.clock()*3)*.2,0)
        local center=self.marker.Position-Vector3.new(0,2,0)
        pose(self.starterParts,CFrame.lookAt(center,center-Vector3.yAxis,Vector3.zAxis),.08)
    else
        for _,p in self.starterParts do p.Transparency=1 end
    end
end
function Guide.update(self: any,origin: Vector3?,target: Vector3?)
    if not origin or not target or (target-origin).Magnitude<3 then
        for _,p in self.parts do p.Transparency=1 end
        for _,light in self.lights do light.Enabled=false end
        return
    end
    local ground=target.Y+.32
    local start=Vector3.new(origin.X,ground,origin.Z)
    local goal=Vector3.new(target.X,ground,target.Z)
    local delta=goal-start
    if delta.Magnitude<1 then
        for _,p in self.parts do p.Transparency=1 end
        for _,light in self.lights do light.Enabled=false end
        return
    end
    local direction=delta.Unit
    local phase=(os.clock()*speed)%spacing
    local height=math.max(0,origin.Y-.15-ground)
    local bend=math.min(6.5,delta.Magnitude)
    for index=1,count do
        local offset=(index-1)*spacing+phase+.35
        local visible=offset<delta.Magnitude-.35
        local center=start+direction*offset
        -- Begin inside the waist silhouette and move outward horizontally,
        -- then smoothly bend down to the ground. The tangent is horizontal
        -- at both ends, avoiding a kink when the stream reaches the lawn.
        local t=math.clamp(offset/bend,0,1)
        local lift=height*(1-3*t*t+2*t*t*t)
        center+=Vector3.new(0,lift,0)
        local slope=height*(-6*t+6*t*t)/bend
        local facing=CFrame.lookAt(center,center+direction+Vector3.new(0,slope,0))
        local fadeIn=math.clamp(offset/.9,0,1)
        local fadeOut=math.clamp((delta.Magnitude-offset)/1.1,0,1)
        pose(self.arrows[index],facing,if visible then 1-.94*math.min(fadeIn,fadeOut) else 1)
        if self.lights[index] then self.lights[index].Enabled=visible end
    end
end
function Guide.destroy(self: any)
    self.folder:Destroy()
    table.clear(self.parts);table.clear(self.arrows);table.clear(self.lights)
end
return Guide
