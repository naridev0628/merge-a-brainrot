--!strict
local Shared=game:GetService('ReplicatedStorage'):WaitForChild('Shared')
local Config=require(Shared:WaitForChild('Config'))
local Catalog=require(Shared:WaitForChild('CreatureCatalog'))
local Style=require(Shared:WaitForChild('TextStyle'))
local Panel={Width=248,Height=452,MinContentHeight=252}
function Panel.new(view: any,button: any,text: any,frame: any,Art: any,C: any)
    local viewport=Instance.new('ScrollingFrame'); viewport.Name='LuckyViewport'; viewport.Size=UDim2.fromScale(1,1); viewport.BackgroundTransparency=1; viewport.BorderSizePixel=0; viewport.ScrollBarThickness=3; viewport.ScrollingDirection=Enum.ScrollingDirection.Y; viewport.CanvasSize=UDim2.new(); viewport.Parent=view.panel
    local content=Instance.new('Frame'); content.Name='LuckyPresentation'; content.BackgroundTransparency=1; content.Active=false; content.Parent=viewport
    local card=frame(content,'GoldCard',Color3.fromRGB(255,210,14)); Art.brick(card,card.BackgroundColor3)
    local gradient=Instance.new('UIGradient'); gradient.Rotation=90; gradient.Color=ColorSequence.new(Color3.fromRGB(255,255,90),Color3.fromRGB(255,158,20)); gradient.Parent=card
    local title=text(card,'Title',32,Style.Gold); title.Text='Basic'; title.ZIndex=3
    local subtitle=text(card,'Subtitle',22,Style.Cream); subtitle.Text='Lucky Block'; subtitle.ZIndex=3
    local portrait=Art.luckyPortrait(card,UDim2.new(),UDim2.new()); portrait.ZIndex=3
    local rewards=frame(card,'Rewards',Color3.fromRGB(102,57,3)); rewards.BackgroundTransparency=.22; rewards.ZIndex=3
    local rows={}
    for index=1,3 do
        local row=Instance.new('Frame'); row.Name='Reward'..index; row.BackgroundTransparency=1; row.Parent=rewards
        local name=text(row,'Name',19,Style.Cream); name.TextXAlignment=Enum.TextXAlignment.Left; name.TextScaled=true
        local limit=Instance.new('UITextSizeConstraint'); limit.MinTextSize=14; limit.MaxTextSize=19; limit.Parent=name
        local tier=text(row,'Tier',14,Style.Cream); tier.TextXAlignment=Enum.TextXAlignment.Left
        local odds=text(row,'Probability',27,Style.Cream)
        rows[index]={root=row,name=name,tier=tier,odds=odds}
    end
    local costStripe=frame(content,'CostStripe',Color3.fromRGB(75,90,13)); costStripe.BackgroundTransparency=.18
    local costText=text(costStripe,'Cost',24,Style.Price); costText.Size=UDim2.fromScale(1,1)
    local unlock=button(content,'Unlock','Unlock!',C.green); Art.brick(unlock,C.green)
    local discard=button(content,'Discard','Discard',Color3.fromRGB(255,62,68)); Art.brick(discard,discard.BackgroundColor3)
    unlock.Activated:Connect(function() if not view.pending and view.eligible then view.onLucky() end end)
    discard.Activated:Connect(function() if not view.pending and view.state and view.state.lucky and view.state.lucky.held then view.onDiscardLucky() end end)
    return {
        setVisible=function(active: boolean)
            viewport.Visible=active
            if active then view.panel.BackgroundTransparency=1; view.heading.Visible=false end
        end,
        resize=function()
            local width=view.panel.Size.X.Offset
            -- The viewport fits the free HUD space; the content keeps its
            -- two-line name budget and scrolls when that space is shorter.
            local height=math.max(Panel.MinContentHeight,view.panel.Size.Y.Offset)
            content.Size=UDim2.fromOffset(width,height)
            viewport.CanvasSize=UDim2.fromOffset(0,height)
            viewport.ScrollingEnabled=height>view.panel.Size.Y.Offset
            if not viewport.ScrollingEnabled then viewport.CanvasPosition=Vector2.zero end
            local short=height<330
            local actionHeight=if short then 30 else 42
            local costHeight=if short then 27 else 35
            local cardHeight=height-actionHeight*2-costHeight-18
            -- Only use the large portrait header when all three reward names
            -- still have two readable lines plus their tier subline.
            local compactHeader=cardHeight<291
            local headerHeight=if compactHeader then 54 else 145
            card.Size=UDim2.fromOffset(width,cardHeight)
            title.Position=UDim2.fromOffset(if compactHeader then 55 else 8,4); title.Size=UDim2.new(1,if compactHeader then -88 else -38,0,if compactHeader then 25 else 38); title.TextSize=if compactHeader then 24 else 32
            subtitle.Position=UDim2.fromOffset(if compactHeader then 55 else 8,if compactHeader then 28 else 40); subtitle.Size=UDim2.new(1,if compactHeader then -62 else -16,0,25); subtitle.TextSize=if compactHeader then 18 else 22
            portrait.Position=if compactHeader then UDim2.fromOffset(2,2) else UDim2.new(.5,-48,0,65); portrait.Size=UDim2.fromOffset(if compactHeader then 50 else 96,if compactHeader then 50 else 76)
            rewards.Position=UDim2.fromOffset(7,headerHeight); rewards.Size=UDim2.new(1,-14,0,cardHeight-headerHeight-7)
            local rowHeight=(cardHeight-headerHeight-11)/3
            local showTier=rowHeight>=45
            for index,row in rows do
                row.root.Position=UDim2.fromOffset(5,2+(index-1)*rowHeight); row.root.Size=UDim2.new(1,-10,0,rowHeight)
                row.name.Position=UDim2.new(); row.name.Size=UDim2.new(1,-54,0,if showTier then rowHeight-15 else rowHeight)
                row.tier.Visible=showTier
                row.tier.Position=UDim2.new(0,0,1,-15); row.tier.Size=UDim2.new(1,-54,0,15)
                row.odds.Position=UDim2.new(1,-54,0,0); row.odds.Size=UDim2.new(0,54,1,0); row.odds.TextSize=if short then 24 else 27
            end
            costStripe.Position=UDim2.fromOffset(0,cardHeight+6); costStripe.Size=UDim2.fromOffset(width,costHeight); costText.TextSize=if short then 19 else 24
            unlock.Position=UDim2.fromOffset(4,cardHeight+costHeight+12); unlock.Size=UDim2.fromOffset(width-8,actionHeight)
            discard.Position=UDim2.fromOffset(4,height-actionHeight); discard.Size=UDim2.fromOffset(width-8,actionHeight)
            unlock.TextSize=if short then 20 else 25; discard.TextSize=if short then 20 else 25
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
