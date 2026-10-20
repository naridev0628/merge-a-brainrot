--!strict
local Shared=game:GetService('ReplicatedStorage'):WaitForChild('Shared')
local Catalog=require(Shared:WaitForChild('CreatureCatalog'))
local Config=require(Shared:WaitForChild('Config'))
local Style=require(Shared:WaitForChild('TextStyle'))
local Panel={}
function Panel.new(view: any,text: any,frame: any,Art: any,C: any)
    local header=frame(view.panel,'IndexHeader',Color3.fromRGB(177,52,216)); header.Size=UDim2.new(1,0,0,60); header.ZIndex=0
    Art.brick(header,header.BackgroundColor3); Art.icon(header,'book',UDim2.fromOffset(6,0),UDim2.fromOffset(66,58))
    local note=text(view.panel,'IndexProduction',14,C.cream); note.Position=UDim2.fromOffset(12,65); note.Size=UDim2.new(1,-24,0,30); note.TextStrokeTransparency=1
    local grid=Instance.new('ScrollingFrame'); grid.Name='IndexGrid'; grid.Position=UDim2.fromOffset(12,102); grid.Size=UDim2.new(1,-24,1,-114); grid.BackgroundTransparency=1; grid.BorderSizePixel=0; grid.ScrollBarThickness=4; grid.CanvasSize=UDim2.new(); grid.Parent=view.panel
    local layout=Instance.new('UIGridLayout'); layout.CellPadding=UDim2.fromOffset(8,8); layout.SortOrder=Enum.SortOrder.LayoutOrder; layout.Parent=grid
    layout:GetPropertyChangedSignal('AbsoluteContentSize'):Connect(function() grid.CanvasSize=UDim2.fromOffset(0,layout.AbsoluteContentSize.Y+4) end)
    local entries={}
    for tier=1,Config.MaxTier do
        local id=string.format('tier_%02d',tier)
        local card=frame(grid,id,Color3.fromRGB(15,33,49)); card.BackgroundTransparency=.35; card.LayoutOrder=tier
        local value=text(card,'MiniValue',21,Color3.fromRGB(255,196,100)); value.Position=UDim2.fromOffset(5,3); value.Size=UDim2.new(1,-12,0,25); value.TextXAlignment=Enum.TextXAlignment.Right; value.TextStrokeTransparency=1; value.ZIndex=3
        local name=text(card,'Name',18,C.cream); name.Position=UDim2.new(0,5,1,-54); name.Size=UDim2.new(1,-10,0,32); name.TextStrokeTransparency=1; name.ZIndex=3
        name.TextScaled=true; local nameSize=Instance.new('UITextSizeConstraint'); nameSize.MinTextSize=12; nameSize.MaxTextSize=18; nameSize.Parent=name
        local level=text(card,'Level',12,Color3.fromRGB(210,215,225)); level.Position=UDim2.new(0,3,1,-21); level.Size=UDim2.new(1,-6,0,18); level.TextStrokeTransparency=1; level.Text='Level '..tier; level.ZIndex=3
        entries[tier]={id=id,card=card,value=value,name=name,found=nil,portrait=nil}
    end
    return {
        setVisible=function(active: boolean)
            header.Visible=active; grid.Visible=active; note.Visible=active
            Style.apply(view.heading,if active then 32 else 25,Style.Cream)
            if active then
                view.heading.Position=UDim2.fromOffset(80,4); view.heading.Size=UDim2.new(1,-150,0,48); view.heading.TextXAlignment=Enum.TextXAlignment.Left
                view.panel.BackgroundTransparency=.28
            end
        end,
        resize=function(phone: boolean)
            local columns=if phone then 2 else 4
            local available=view.panel.Size.X.Offset-28
            local width=math.max(80,math.floor((available-8*(columns-1))/columns))
            layout.CellSize=UDim2.fromOffset(width,if phone then 174 else 190)
            layout.FillDirectionMaxCells=columns
        end,
        render=function(state: any)
            note.Text=(if state.miniMultiplier==2 then '2 Minis' else '1 Mini')..' every '..Config.Interval..'s per Brainrot · $ value per Mini'
            for tier,entry in entries do
                local species=Catalog[entry.id]; local found=state.discoveries[entry.id]==true
                entry.name.Text=if found then species.name else '???'
                entry.name.TextColor3=if found then Color3.fromRGB(table.unpack(species.color)) else Style.Cream
                entry.value.Text=if found then '$'..view.coins(species.value*(4+state.rebirths)*state.cashMultiplier) else '???'
                if entry.found~=found then
                    if entry.portrait then entry.portrait:Destroy() end
                    entry.portrait=Art.portrait(entry.card,entry.id,UDim2.fromScale(.08,.12),UDim2.fromScale(.84,.67),false,not found)
                    entry.found=found
                end
            end
        end,
    }
end
return Panel
