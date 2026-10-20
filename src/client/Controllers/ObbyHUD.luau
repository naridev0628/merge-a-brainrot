--!strict
local Shared=game:GetService('ReplicatedStorage'):WaitForChild('Shared')
local Presentation=require(Shared:WaitForChild('ObbyPresentation'))
local TextStyle=require(Shared:WaitForChild('TextStyle'))
local HUD={}
HUD.__index=HUD
local owners: {[BillboardGui]: any}={}
local colors={bonus=TextStyle.Gold,running=TextStyle.Cream,cooldown=Color3.fromRGB(211,227,239),idle=TextStyle.Price}

function HUD.new(root: Instance?)
    return setmetatable({root=root or workspace,presentation=Presentation.new(),dirty=true,nextUpdate=0,destroyed=false},HUD)
end
function HUD.detach(self: any)
    local gui=self.gui
    if gui and owners[gui]==self then
        owners[gui]=nil
        if self.label then self.label:Destroy() end
        if gui.Parent and gui.Size==self.expandedSize then gui.Size=self.originalSize end
    end
    self.gui=nil;self.label=nil;self.originalSize=nil;self.expandedSize=nil
end
local function attach(self: any): boolean
    local world=self.root:FindFirstChild('MergeABrainrotGenerated')
    local anchor=world and world:FindFirstChild('MiniMultiplierBillboardAnchor')
    local candidate=anchor and anchor:FindFirstChild('MiniMultiplierBillboard')
    local gui=if candidate and candidate:IsA('BillboardGui') then candidate else nil
    if gui==self.gui and self.label and self.label.Parent==gui then return true end
    self:detach()
    if not gui then return false end
    if owners[gui] then owners[gui]:destroy() end
    local previous=gui:FindFirstChild('ObbyStatus')
    if previous then previous:Destroy() end
    self.originalSize=gui.Size
    self.expandedSize=UDim2.new(gui.Size.X.Scale,gui.Size.X.Offset,gui.Size.Y.Scale,math.max(160,gui.Size.Y.Offset))
    gui.Size=self.expandedSize
    local label=Instance.new('TextLabel');label.Name='ObbyStatus'
    label.BackgroundTransparency=1;label.Position=UDim2.fromOffset(0,125);label.Size=UDim2.new(1,0,0,30)
    label.Text='';label.TextWrapped=false;label.RichText=false;label.Active=false
    TextStyle.apply(label,23,TextStyle.Cream,2)
    label.Parent=gui
    self.gui=gui;self.label=label;owners[gui]=self
    return true
end
function HUD.update(self: any,localNow: number)
    if self.destroyed then return end
    if not self.dirty and localNow<self.nextUpdate then return end
    self.nextUpdate=localNow+1;self.dirty=false
    local display=self.presentation:read(localNow)
    if not display then self:detach();return end
    if not attach(self) then return end
    if self.label.Text~=display.text then self.label.Text=display.text end
    self.label.TextColor3=colors[display.kind]
end
function HUD.receive(self: any,snapshot: any,receivedAt: number): boolean
    if self.destroyed then return false end
    local accepted,finish,changed=self.presentation:receive(snapshot,receivedAt)
    if accepted then
        self.dirty=self.dirty or changed
        self:update(receivedAt)
    end
    return finish
end
function HUD.clear(self: any)
    self.presentation:clear();self:detach();self.dirty=true
end
function HUD.destroy(self: any)
    if self.destroyed then return end
    self.destroyed=true;self:detach();self.presentation:clear()
end
return table.freeze(HUD)
