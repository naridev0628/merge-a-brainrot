--!strict
local Shared=game:GetService('ReplicatedStorage'):WaitForChild('Shared')
local Config=require(Shared:WaitForChild('Config'))
local Catalog=require(Shared:WaitForChild('CreatureCatalog'))
local Panel={}
Panel.Width=340
Panel.Height=622
local ink=Color3.fromRGB(12,10,5)
local function outline(label: any,thickness: number)
    label.TextStrokeTransparency=1
    local stroke=Instance.new('UIStroke'); stroke.Name='LetterOutline'; stroke.Color=ink; stroke.Thickness=thickness; stroke.Parent=label
end
local function border(object: any,thickness: number)
    local stroke=object:FindFirstChildOfClass('UIStroke')
    if stroke then stroke.Color=ink; stroke.Thickness=thickness end
end
function Panel.new(view: any,button: any,text: any,frame: any,Art: any,C: any)
    local content=Instance.new('Frame'); content.Name='LuckyPresentation'; content.Size=UDim2.fromOffset(Panel.Width,Panel.Height); content.BackgroundTransparency=1; content.Active=false; content.Parent=view.panel
    local scale=Instance.new('UIScale'); scale.Parent=content
    local card=frame(content,'GoldCard',Color3.fromRGB(255,225,14)); card.Size=UDim2.fromOffset(340,442); border(card,5); Art.brick(card,card.BackgroundColor3)
    local gradient=Instance.new('UIGradient'); gradient.Rotation=90; gradient.Color=ColorSequence.new(Color3.fromRGB(255,255,45),Color3.fromRGB(255,145,0)); gradient.Parent=card
    local title=text(card,'Title',43,Color3.fromRGB(255,185,0)); title.Position=UDim2.fromOffset(40,12); title.Size=UDim2.fromOffset(260,49); title.Text='Basic'; title.ZIndex=3; outline(title,4)
    local subtitle=text(card,'Subtitle',29,Color3.new(1,1,1)); subtitle.Position=UDim2.fromOffset(22,59); subtitle.Size=UDim2.fromOffset(296,36); subtitle.Text='Lucky Block'; subtitle.ZIndex=3; outline(subtitle,3)
    local portrait=Art.luckyPortrait(card,UDim2.fromOffset(82,95),UDim2.fromOffset(176,129)); portrait.ZIndex=3
    local rewards=frame(card,'Rewards',Color3.fromRGB(102,57,3)); rewards.BackgroundTransparency=.28; rewards.Position=UDim2.fromOffset(14,228); rewards.Size=UDim2.fromOffset(312,198); rewards.ZIndex=3; border(rewards,3)
    local rows={}
    for index=1,3 do
        local row=Instance.new('Frame'); row.Name='Reward'..index; row.BackgroundTransparency=1; row.Position=UDim2.fromOffset(8,6+(index-1)*62); row.Size=UDim2.fromOffset(296,62); row.Parent=rewards
        local name=text(row,'Name',25,C.cream); name.Size=UDim2.fromOffset(209,39); name.TextXAlignment=Enum.TextXAlignment.Left; outline(name,2.5)
        name.TextScaled=true; local nameSize=Instance.new('UITextSizeConstraint'); nameSize.MinTextSize=16; nameSize.MaxTextSize=25; nameSize.Parent=name
        local tier=text(row,'Tier',18,Color3.new(1,1,1)); tier.Position=UDim2.fromOffset(0,39); tier.Size=UDim2.fromOffset(195,22); tier.TextXAlignment=Enum.TextXAlignment.Left; outline(tier,2)
        local odds=text(row,'Probability',34,Color3.new(1,1,1)); odds.Position=UDim2.fromOffset(212,10); odds.Size=UDim2.fromOffset(84,42); outline(odds,3.5)
        rows[index]={root=row,name=name,tier=tier,odds=odds}
    end
    local costStripe=frame(content,'CostStripe',Color3.fromRGB(75,90,13)); costStripe.BackgroundTransparency=.30; costStripe.Position=UDim2.fromOffset(0,452); costStripe.Size=UDim2.fromOffset(340,46); border(costStripe,3)
    local costText=text(costStripe,'Cost',30,C.green); costText.Size=UDim2.fromScale(1,1); outline(costText,3)
    local function action(name: string,label: string,color: Color3,y: number)
        local control=button(content,name,label,color); control.Position=UDim2.fromOffset(12,y); control.Size=UDim2.fromOffset(316,50); control.TextSize=32; control.TextColor3=Color3.new(1,1,1); control.TextStrokeTransparency=1; border(control,3); Art.brick(control,color)
        outline(control.BrickCaption,3)
        return control
    end
    local unlock=action('Unlock','Unlock!',C.green,510)
    local discard=action('Discard','Discard',Color3.fromRGB(255,62,68),572)
    unlock.Activated:Connect(function()
        if not view.pending and view.eligible then view.onLucky() end
    end)
    discard.Activated:Connect(function()
        if not view.pending and view.state and view.state.lucky and view.state.lucky.held then view.onDiscardLucky() end
    end)
    return {
        setVisible=function(active: boolean)
            content.Visible=active
            if active then view.panel.BackgroundTransparency=1; view.heading.Visible=false end
        end,
        resize=function()
            scale.Scale=math.max(.05,math.min(view.panel.Size.X.Offset/Panel.Width,view.panel.Size.Y.Offset/Panel.Height))
        end,
        render=function(state: any)
            for _,row in rows do row.root.Visible=false end
            local held=state.lucky and state.lucky.held
            discard.Active=held and not view.pending or false; discard.AutoButtonColor=discard.Active
            if not held then costText.Text='Pick up a Lucky Block'; unlock.Text='Unlock!'; unlock.Active=false; unlock.AutoButtonColor=false; view.eligible=false; return end
            local odds={}
            for index,chance in {75,20,5} do
                local tier=math.min(Config.MaxTier,state.lucky.baseTier+index-1); odds[tier]=(odds[tier] or 0)+chance
            end
            local index=0
            for tier=1,Config.MaxTier do
                if odds[tier] then
                    index+=1; local row=rows[index]; local species=Catalog[string.format('tier_%02d',tier)]
                    row.root.Visible=true; row.name.Text=species.name; row.name.TextColor3=Color3.fromRGB(table.unpack(species.color)); row.tier.Text='Tier '..tier; row.odds.Text=odds[tier]..'%'
                end
            end
            local cost=Config.LuckyBaseUnits+#state.producers*Config.LuckyPerProducerUnits
            costText.Text='Cost: $'..view.coins(cost)
            view.eligible=state.coinUnits>=cost and #state.producers<Config.Slots
            unlock.Text=if view.pending then 'Please wait...' elseif #state.producers>=Config.Slots then 'Stack Full' elseif state.coinUnits<cost then 'Need $'..view.coins(cost-state.coinUnits) else 'Unlock!'
            unlock.Active=view.eligible and not view.pending; unlock.AutoButtonColor=unlock.Active; unlock.BackgroundTransparency=if view.eligible then 0 else .3
            discard.BackgroundTransparency=if view.pending then .3 else 0
        end,
    }
end
return Panel
