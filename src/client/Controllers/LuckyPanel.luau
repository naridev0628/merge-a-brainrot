--!strict
local Shared=game:GetService('ReplicatedStorage'):WaitForChild('Shared')
local Config=require(Shared:WaitForChild('Config'))
local Catalog=require(Shared:WaitForChild('CreatureCatalog'))
local Panel={}
function Panel.new(view: any,button: any,text: any,frame: any,Art: any,C: any)
    local content=Instance.new('Frame'); content.Name='LuckyPresentation'; content.Size=UDim2.fromOffset(340,560); content.BackgroundTransparency=1; content.Parent=view.panel
    local scale=Instance.new('UIScale'); scale.Parent=content
    local card=frame(content,'GoldCard',Color3.fromRGB(255,213,13)); card.Size=UDim2.fromOffset(340,450); Art.brick(card,card.BackgroundColor3)
    local gradient=Instance.new('UIGradient'); gradient.Rotation=90; gradient.Color=ColorSequence.new(Color3.fromRGB(255,255,45),Color3.fromRGB(255,145,0)); gradient.Parent=card
    local title=text(card,'Title',32,Color3.fromRGB(255,200,0)); title.Position=UDim2.fromOffset(12,12); title.Size=UDim2.fromOffset(264,38); title.Text='Basic'; title.TextStrokeTransparency=0; title.ZIndex=3
    local subtitle=text(card,'Subtitle',25,C.cream); subtitle.Position=UDim2.fromOffset(12,47); subtitle.Size=UDim2.fromOffset(264,32); subtitle.Text='Lucky Block'; subtitle.TextStrokeTransparency=0; subtitle.ZIndex=3
    Art.luckyPortrait(card,UDim2.fromOffset(84,80),UDim2.fromOffset(172,140))
    local rewards=frame(card,'Rewards',Color3.fromRGB(80,45,10)); rewards.BackgroundTransparency=.35; rewards.Position=UDim2.fromOffset(14,228); rewards.Size=UDim2.fromOffset(312,206)
    local rows={}
    for index=1,3 do
        local row=Instance.new('Frame'); row.Name='Reward'..index; row.BackgroundTransparency=1; row.Position=UDim2.fromOffset(8,8+(index-1)*64); row.Size=UDim2.fromOffset(296,62); row.Parent=rewards
        local name=text(row,'Name',22,C.cream); name.Size=UDim2.fromOffset(215,38); name.TextXAlignment=Enum.TextXAlignment.Left; name.TextStrokeTransparency=0
        name.TextScaled=true; local nameSize=Instance.new('UITextSizeConstraint'); nameSize.MinTextSize=14; nameSize.MaxTextSize=22; nameSize.Parent=name
        local level=text(row,'Level',15,C.cream); level.Position=UDim2.fromOffset(0,38); level.Size=UDim2.fromOffset(195,22); level.TextXAlignment=Enum.TextXAlignment.Left; level.TextStrokeTransparency=0
        local odds=text(row,'Probability',29,Color3.new(1,1,1)); odds.Position=UDim2.fromOffset(218,10); odds.Size=UDim2.fromOffset(78,42); odds.TextStrokeTransparency=0
        rows[index]={root=row,name=name,level=level,odds=odds}
    end
    local costStripe=frame(content,'CostStripe',Color3.fromRGB(38,29,17)); costStripe.BackgroundTransparency=.28; costStripe.Position=UDim2.fromOffset(0,460); costStripe.Size=UDim2.fromOffset(340,42)
    local costText=text(costStripe,'Cost',27,C.green); costText.Size=UDim2.fromScale(1,1); costText.TextStrokeTransparency=0
    local unlock=button(content,'Unlock','Unlock!',C.green); unlock.Position=UDim2.fromOffset(12,512); unlock.Size=UDim2.fromOffset(316,48); unlock.TextSize=29; unlock.TextColor3=C.cream; unlock.TextStrokeTransparency=0; Art.brick(unlock,C.green)
    unlock.Activated:Connect(function()
        if view.pending then return end
        if view.eligible then view.onLucky() elseif not view.state or not view.state.lucky then view:close() end
    end)
    return {
        setVisible=function(active: boolean)
            content.Visible=active
            if active then view.panel.BackgroundTransparency=1; view.heading.Visible=false end
        end,
        resize=function()
            scale.Scale=math.max(.05,math.min(view.panel.Size.X.Offset/340,view.panel.Size.Y.Offset/560))
        end,
        render=function(state: any)
            for _,row in rows do row.root.Visible=false end
            if not state.lucky then costText.Text='Already opened'; unlock.Text='Close'; view.eligible=false; return end
            local odds={}
            for index,chance in {75,20,5} do
                local tier=math.min(Config.MaxTier,state.lucky.baseTier+index-1); odds[tier]=(odds[tier] or 0)+chance
            end
            local index=0
            for tier=1,Config.MaxTier do
                if odds[tier] then
                    index+=1; local row=rows[index]; local species=Catalog[string.format('tier_%02d',tier)]
                    row.root.Visible=true; row.name.Text=species.name; row.name.TextColor3=Color3.fromRGB(table.unpack(species.color)); row.level.Text='Level '..tier; row.odds.Text=odds[tier]..'%'
                end
            end
            local cost=Config.LuckyBaseUnits+#state.producers*Config.LuckyPerProducerUnits
            costText.Text='Cost: $'..view.coins(cost)
            view.eligible=state.coinUnits>=cost and #state.producers<Config.Slots
            unlock.Text=if view.pending then 'Please wait...' elseif #state.producers>=Config.Slots then 'Stack full' elseif state.coinUnits<cost then 'Need $'..view.coins(cost-state.coinUnits) else 'Unlock!'
            unlock.AutoButtonColor=view.eligible and not view.pending; unlock.BackgroundTransparency=if view.eligible then 0 else .3
        end,
    }
end
return Panel
