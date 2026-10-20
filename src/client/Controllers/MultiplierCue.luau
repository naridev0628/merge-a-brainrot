--!strict
local Shared=game:GetService('ReplicatedStorage'):WaitForChild('Shared')
local Presentation=require(Shared:WaitForChild('MultiplierCuePresentation'))
local MiniEvent=require(Shared:WaitForChild('MiniEvent'))
local Style=require(Shared:WaitForChild('TextStyle'))
local Cue={}
Cue.__index=Cue
local owners: {[ScreenGui]: any}={}
local colors={rise=Style.Price,fall=Color3.fromRGB(255,151,132)}

local function visible(object: GuiObject,root: GuiObject): boolean
    local current: Instance?=object
    while current and current~=root do
        if current:IsA('GuiObject') and not current.Visible then return false end
        current=current.Parent
    end
    return current==root and root.Visible
end
local function rectangle(object: GuiObject,origin: Vector2): any
    local p,s=object.AbsolutePosition-origin,object.AbsoluteSize
    return {x=p.X,y=p.Y,width=s.X,height=s.Y}
end
function Cue.new(view: any)
    if owners[view.gui] then owners[view.gui]:destroy() end
    local self: any=setmetatable({view=view,presentation=Presentation.new(MiniEvent.Minimum,MiniEvent.Maximum),
        connections={},pickups={},obstacles={},dirty=true,destroyed=false},Cue)
    owners[view.gui]=self
    local old=view.root:FindFirstChild('MiniMultiplierChange')
    if old then old:Destroy() end
    local label=Instance.new('TextLabel');label.Name='MiniMultiplierChange'
    label.BackgroundTransparency=1;label.Text='';label.Visible=false
    label.Active=false;label.Selectable=false;label.RichText=false;label.TextWrapped=true;label.TextScaled=true
    label.ZIndex=8;Style.apply(label,30,Style.Price,3)
    local size=Instance.new('UITextSizeConstraint');size.MinTextSize=17;size.MaxTextSize=30;size.Parent=label
    label.Parent=view.root;self.label=label;self.textSize=size
    local function connect(signal: RBXScriptSignal,callback: (...any)->())
        local connection=signal:Connect(callback)
        self.connections[connection]=true
        return connection
    end
    local function disconnect(connection: RBXScriptConnection)
        connection:Disconnect();self.connections[connection]=nil
    end
    local function dirty() self.dirty=true end
    for _,object in {view.root,view.bag} do
        for _,property in {'AbsoluteSize','AbsolutePosition','Visible'} do connect(object:GetPropertyChangedSignal(property),dirty) end
    end
    -- These are the existing HUD regions; their geometry/visibility signals
    -- coalesce into one layout pass on the caller's next regular update.
    for _,name in {'panel','contextPanel','actions','hud','total','homeButton','boostButton',
        'boostPrice','autoButton','title','objective','hint','toast'} do
        local object=view[name]
        if object then
            table.insert(self.obstacles,object)
            for _,property in {'AbsoluteSize','AbsolutePosition','Visible'} do connect(object:GetPropertyChangedSignal(property),dirty) end
        end
    end
    if view.overlay then connect(view.overlay:GetPropertyChangedSignal('Visible'),dirty) end
    local function pickup(child: Instance)
        if child.Name~='PickupGain' or not child:IsA('GuiObject') or self.pickups[child] then return end
        local record: any={}
        self.pickups[child]=record;self.dirty=true
        record.visibility=connect(child:GetPropertyChangedSignal('Visible'),dirty)
        record.destroying=connect(child.Destroying,function()
            disconnect(record.visibility);disconnect(record.destroying)
            self.pickups[child]=nil;self.dirty=true
        end)
    end
    for _,child in view.bag:GetChildren() do pickup(child) end
    connect(view.bag.ChildAdded,pickup)
    connect(view.gui.Destroying,function() self:destroy() end)
    connect(view.gui.AncestryChanged,function(_,parent) if not parent then self:destroy() end end)
    connect(view.root.Destroying,function() self:destroy() end)
    connect(view.bag.Destroying,function() self:destroy() end)
    connect(label.Destroying,function() self:destroy() end)
    return self
end
function Cue.update(self: any,now: number)
    if self.destroyed then return end
    local display=self.presentation:read(now)
    if not display then self.label.Visible=false;self.display=nil;return end
    if display==self.display and not self.dirty then return end
    self.display=display
    if self.dirty then
        self.dirty=false
        local view=self.view
        local origin=view.root.AbsolutePosition
        local obstacles={}
        for _,object in self.obstacles do
            if object.Parent and visible(object,view.root) then table.insert(obstacles,rectangle(object,origin)) end
        end
        local pickups=false
        for object in self.pickups do
            if object.Parent==view.bag and object.Visible then pickups=true;break end
        end
        local size=view.root.AbsoluteSize
        self.layout=if visible(view.bag,view.root) then Presentation.layout(size.X,size.Y,rectangle(view.bag,origin),obstacles,pickups) else nil
    end
    local layout=self.layout
    self.label.Text=if layout and layout.compact then display.compactText else display.text
    self.label.TextColor3=colors[display.direction]
    self.label.Visible=layout~=nil
    if not layout then return end
    self.label.Position=UDim2.fromOffset(layout.x,layout.y)
    self.label.Size=UDim2.fromOffset(layout.width,layout.height)
    self.textSize.MaxTextSize=layout.fontSize
    self.label.TextOutline.Thickness=if layout.compact then 2 else 3
end
function Cue.receive(self: any,snapshot: any,receivedAt: number): boolean
    if self.destroyed then return false end
    local previous=self.presentation.cue
    local accepted=self.presentation:receive(snapshot,receivedAt)
    if accepted then
        if self.presentation.cue~=previous then self.dirty=true end
        self:update(receivedAt)
    end
    return accepted
end
function Cue.clear(self: any)
    if self.destroyed then return end
    self.presentation:clear();self.label.Visible=false
end
function Cue.destroy(self: any)
    if self.destroyed then return end
    self.destroyed=true;self.presentation:destroy()
    if owners[self.view.gui]==self then owners[self.view.gui]=nil end
    for connection in self.connections do connection:Disconnect() end
    table.clear(self.connections);table.clear(self.pickups);table.clear(self.obstacles)
    self.label:Destroy()
end
return table.freeze(Cue)
