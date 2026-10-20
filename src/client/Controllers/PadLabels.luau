--!strict
-- Local presentation only: direct Text/Price/Detail children remain in place
-- for server quotes and shop-info updates. No text or pad properties are edited.
local Players=game:GetService('Players')
local Layout=require(game:GetService('ReplicatedStorage'):WaitForChild('Shared'):WaitForChild('PadLabelLayout'))
local Labels={};Labels.__index=Labels
local owners: {[Instance]: any}={}
local names={
    Buy1=1,Buy5=1,Buy10=1,Buy100=1,
    DepositPad=2,CoinPad=2,UpgradePad=2,MergePad=2,FinishNowPad=3,
    Pass_autoCollect=3,Pass_autoSell=3,Pass_mini2=3,Pass_cash2=3,Pass_cash4=3,Pass_cash8=3,
}
local function scaled(value: UDim2,factor: number): UDim2
    return UDim2.new(value.X.Scale,value.X.Offset*factor,value.Y.Scale,value.Y.Offset*factor)
end
local function constraintSize(object: UITextSizeConstraint,minimum: number,maximum: number)
    if minimum>object.MaxTextSize then object.MaxTextSize=maximum end
    object.MinTextSize=minimum;object.MaxTextSize=maximum
end
local function capture(part: BasePart,gui: BillboardGui): any
    local record: any={part=part,gui=gui,size=gui.Size,enabled=gui.Enabled,children={},factor=1}
    for _,child in gui:GetChildren() do
        if child:IsA('TextLabel') then
            local entry: any={object=child,size=child.Size,position=child.Position,textSize=child.TextSize,
                textScaled=child.TextScaled,textWrapped=child.TextWrapped,decorations={}}
            for _,decoration in child:GetChildren() do
                if decoration:IsA('UITextSizeConstraint') then
                    table.insert(entry.decorations,{object=decoration,min=decoration.MinTextSize,max=decoration.MaxTextSize})
                elseif decoration:IsA('UIStroke') then
                    table.insert(entry.decorations,{object=decoration,thickness=decoration.Thickness})
                end
            end
            -- Fit localized titles inside their existing cell, without changing
            -- their text or letting glyphs escape the overlap rectangle.
            if not child.TextScaled then
                local constraint=Instance.new('UITextSizeConstraint')
                constraint.Name='PadLabelTextFit';constraint.MinTextSize=12;constraint.MaxTextSize=child.TextSize
                constraint.Parent=child
                table.insert(entry.decorations,{object=constraint,min=12,max=child.TextSize,owned=true})
                child.TextScaled=true
            end
            table.insert(record.children,entry)
        end
    end
    return record
end
local function apply(record: any,factor: number)
    if record.factor==factor then return end
    record.factor=factor
    record.gui.Size=scaled(record.size,factor)
    for _,entry in record.children do
        local child=entry.object
        child.Size=scaled(entry.size,factor);child.Position=scaled(entry.position,factor)
        child.TextSize=math.max(1,entry.textSize*factor)
        for _,decoration in entry.decorations do
            if decoration.thickness then decoration.object.Thickness=decoration.thickness*factor
            else
                constraintSize(decoration.object,math.max(1,math.floor(decoration.min*factor)),math.max(1,math.floor(decoration.max*factor)))
            end
        end
    end
end
local function restore(record: any)
    if not record.gui.Parent then return end
    record.gui.Size=record.size;record.gui.Enabled=record.enabled
    for _,entry in record.children do
        local child=entry.object
        if not child.Parent then continue end
        child.Size=entry.size;child.Position=entry.position;child.TextSize=entry.textSize;child.TextScaled=entry.textScaled
        -- Enabling TextScaled also changes TextWrapped in the native engine.
        child.TextWrapped=entry.textWrapped
        for _,decoration in entry.decorations do
            if decoration.owned then decoration.object:Destroy()
            elseif decoration.object.Parent then
                if decoration.thickness then decoration.object.Thickness=decoration.thickness
                else constraintSize(decoration.object,decoration.min,decoration.max) end
            end
        end
    end
end
function Labels.new(root: Instance?): any
    local scope=root or workspace
    if owners[scope] then owners[scope]:destroy() end
    local self=setmetatable({root=scope,records={},previous={},nextUpdate=0,nextScan=0,destroyed=false},Labels)
    owners[scope]=self
    return self
end
function Labels.clear(self: any)
    for _,record in self.records do restore(record) end
    table.clear(self.records);table.clear(self.previous)
    self.plot=nil;self.plotId=nil;self.nextUpdate=0;self.nextScan=0
end
function Labels.setPlot(self: any,id: number?)
    if self.destroyed or self.plotId==id then return end
    self:clear()
    if id and id%1==0 and id>=1 and id<=6 then self.plotId=id end
end
function Labels.update(self: any,now: number,camera: Camera?,position: Vector3?)
    if self.destroyed or not self.plotId or now<self.nextUpdate then return end
    self.nextUpdate=now+.1
    local world=self.root:FindFirstChild('MergeABrainrotGenerated')
    local plot=world and world:FindFirstChild('Plot'..self.plotId)
    if plot~=self.plot then
        for _,record in self.records do restore(record) end
        table.clear(self.records);table.clear(self.previous)
        self.plot=plot;self.nextScan=0
    end
    if not plot then return end
    if now>=self.nextScan then
        self.nextScan=now+1
        -- Fifteen named static pads; no world/descendant scan on the frame path.
        for name in names do
            local part=plot:FindFirstChild(name)
            local gui=part and part:FindFirstChild('Label')
            local record=self.records[name]
            if record and (record.part~=part or record.gui~=gui) then
                restore(record);self.records[name]=nil;self.previous[name]=nil;record=nil
            end
            if not record and part and part:IsA('BasePart') and gui and gui:IsA('BillboardGui')
                and gui.Size.X.Scale==0 and gui.Size.Y.Scale==0 then
                self.records[name]=capture(part,gui)
            end
        end
    end
    camera=camera or workspace.CurrentCamera
    if not camera then return end
    if not position then
        local player=Players.LocalPlayer
        local character=player and player.Character
        local root=character and character:FindFirstChild('HumanoidRootPart')
        if root and root:IsA('BasePart') then position=root.Position end
    end
    local candidates={}
    for name,record in self.records do
        local part,gui=record.part,record.gui
        local distance=(part.Position-camera.CFrame.Position).Magnitude
        local playerDistance=if position then (position-part.Position).Magnitude else math.huge
        record.near=distance<=(if record.near then 20 else 18) or playerDistance<=(if record.near then 9 else 8)
        local anchor=part.Position+gui.StudsOffsetWorldSpace+camera.CFrame:VectorToWorldSpace(gui.StudsOffset)
        local projected,onScreen=camera:WorldToViewportPoint(anchor)
        if record.enabled and part.Parent==plot and gui.Parent==part and onScreen and projected.Z>0
            and (gui.MaxDistance<=0 or distance<gui.MaxDistance) then
            table.insert(candidates,{key=name,x=projected.X,y=projected.Y,width=record.size.X.Offset,
                height=record.size.Y.Offset,distance=distance,priority=names[name],
                near=record.near})
        end
    end
    local result=Layout.solve(candidates,self.previous)
    for name,record in self.records do
        local display=result[name]
        local show=display~=nil and display.visible
        record.gui.Enabled=show
        -- Offscreen/cutoff transitions do not count as overlap rejection.
        if display then self.previous[name]=show end
        if show then apply(record,display.scale) end
    end
end
function Labels.destroy(self: any)
    if self.destroyed then return end
    self:clear();self.destroyed=true
    if owners[self.root]==self then owners[self.root]=nil end
end
return table.freeze(Labels)
