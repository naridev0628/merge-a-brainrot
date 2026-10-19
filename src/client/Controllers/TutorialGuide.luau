--!strict
local Guide={}
Guide.__index=Guide
function Guide.new()
    local self: any=setmetatable({parts={}},Guide)
    local folder=Instance.new('Folder'); folder.Name='LocalTutorialArrows'; folder.Parent=workspace; self.folder=folder
    local marker=Instance.new('Part'); marker.Name='FirstBrainrotArrow'; marker.Anchored=true; marker.Transparency=1; marker.CanCollide=false; marker.CanTouch=false; marker.CanQuery=false; marker.Parent=folder; self.marker=marker
    local gui=Instance.new('BillboardGui'); gui.Name='StarterPrompt'; gui.Size=UDim2.fromOffset(250,115); gui.AlwaysOnTop=true; gui.Enabled=false; gui.Parent=marker; self.markerGui=gui
    local label=Instance.new('TextLabel'); label.Size=UDim2.new(1,0,0,50); label.Text='Buy your first Brainrot!'; label.TextWrapped=true; label.Font=Enum.Font.FredokaOne; label.TextSize=23; label.TextColor3=Color3.fromRGB(142,255,58); label.TextStrokeTransparency=0; label.BackgroundTransparency=1; label.Parent=gui
    for _,spec in {{0,70,12,36,0},{-10,92,30,12,45},{10,92,30,12,-45}} do
        local piece=Instance.new('Frame'); piece.AnchorPoint=Vector2.new(.5,.5); piece.Position=UDim2.new(.5,spec[1],0,spec[2]); piece.Size=UDim2.fromOffset(spec[3],spec[4]); piece.Rotation=spec[5]; piece.BackgroundColor3=Color3.fromRGB(255,228,40); piece.BorderSizePixel=0; piece.Parent=gui
    end
    for i=1,24 do
        local p=Instance.new('Part'); p.Name='Chevron'; p.Size=Vector3.new(.35,.12,1.45)
        p.Anchored=true; p.CanCollide=false; p.CanTouch=false; p.CanQuery=false
        p.Material=Enum.Material.Neon; p.Color=Color3.fromRGB(255,248,170); p.Transparency=1; p.Parent=folder
        self.parts[i]=p
    end
    return self
end
function Guide.showStarter(self: any,target: Vector3?)
    self.markerGui.Enabled=target~=nil
    if target then self.marker.Position=target+Vector3.new(0,7+math.sin(os.clock()*3)*.35,0) end
end
function Guide.update(self: any,origin: Vector3?,target: Vector3?)
    if not origin or not target or (target-origin).Magnitude<3 then
        for _,p in self.parts do p.Transparency=1 end
        return
    end
    local start=Vector3.new(origin.X,.42,origin.Z)
    local goal=Vector3.new(target.X,.42,target.Z)
    local delta=goal-start
    if delta.Magnitude<1 then return end
    local direction=delta.Unit
    local phase=(os.clock()*3)%2.6
    for index=1,12 do
        local offset=2+index*2.6+phase
        local visible=offset<delta.Magnitude
        local center=start+direction*offset
        local facing=CFrame.lookAt(center,center+direction)
        for sideIndex,side in {-1,1} do
            local p=self.parts[(index-1)*2+sideIndex]
            p.Transparency=if visible then .08 else 1
            p.CFrame=facing*CFrame.new(side*.42,0,.35)*CFrame.Angles(0,side*math.pi/4,0)
        end
    end
end
return Guide
