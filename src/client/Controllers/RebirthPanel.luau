--!strict
local Config=require(game:GetService('ReplicatedStorage').Shared.Config)
local Catalog=require(game:GetService('ReplicatedStorage').Shared.CreatureCatalog)
local Style=require(game:GetService('ReplicatedStorage').Shared.TextStyle)
local Panel={}
function Panel.new(view: any,button: any,text: any,frame: any,Art: any,C: any)
    local header=frame(view.panel,'RebirthHeader',Color3.fromRGB(239,58,64)); header.Size=UDim2.new(1,0,0,56); header.ZIndex=0; Art.brick(header,header.BackgroundColor3)
    Art.icon(header,'rebirth',UDim2.fromOffset(5,0),UDim2.fromOffset(54,54))
    local content=Instance.new('ScrollingFrame'); content.Name='RebirthRewards'; content.BackgroundTransparency=1; content.BorderSizePixel=0; content.ScrollBarThickness=4; content.Position=UDim2.fromOffset(12,66); content.Size=UDim2.new(1,-24,1,-78); content.CanvasSize=UDim2.fromOffset(0,370); content.Parent=view.panel
    local function label(name: string,value: string,y: number,h: number,size: number,color: Color3)
        local l=text(content,name,size,color); l.Text=value; l.Position=UDim2.fromOffset(0,y); l.Size=UDim2.new(1,0,0,h); l.TextStrokeTransparency=1; return l
    end
    label('Receive','Next rebirth rewards',0,31,25,Style.Price)
    local boost=frame(content,'CashReward',C.green); boost.Position=UDim2.new(.5,6,0,38); boost.Size=UDim2.new(.5,-14,0,108); Art.brick(boost,C.green); Art.icon(boost,'money',UDim2.fromScale(.23,.29),UDim2.fromScale(.54,.67))
    local boostText=text(boost,'CashBoost',20,C.cream); boostText.Size=UDim2.new(1,0,0,35); boostText.TextStrokeTransparency=1; boostText.ZIndex=3
    local bulk=frame(content,'BulkReward',C.blue); bulk.Position=UDim2.fromOffset(8,38); bulk.Size=UDim2.new(.5,-14,0,108); Art.brick(bulk,C.blue)
    local bulkPortrait=nil; local shownTier=nil
    local bulkText=text(bulk,'Unlock',19,C.cream); bulkText.Size=UDim2.new(1,0,0,38); bulkText.TextStrokeTransparency=1; bulkText.ZIndex=3
    label('Requirement','Requirement',151,28,24,C.cream)
    local progress=frame(content,'CashProgress',Color3.fromRGB(31,55,18)); progress.Position=UDim2.fromOffset(8,183); progress.Size=UDim2.new(1,-16,0,46); progress.ClipsDescendants=true
    local fill=Instance.new('Frame'); fill.Name='Fill'; fill.BorderSizePixel=0; fill.BackgroundColor3=C.green; fill.Parent=progress
    local amount=text(progress,'Amount',24,C.cream); amount.Size=UDim2.fromScale(1,1); amount.TextScaled=true; amount.TextStrokeTransparency=1; amount.ZIndex=2
    local level=label('LevelRequirement','',235,24,17,C.cream)
    local normal=button(content,'RebirthNow','REBIRTH',Color3.fromRGB(249,80,85)); normal.Position=UDim2.new(0,8,0,267); normal.Size=UDim2.new(.5,-16,0,48); normal.TextColor3=C.cream; normal.TextStrokeTransparency=1; Art.brick(normal,normal.BackgroundColor3)
    local skip=button(content,'NoReset','NO RESET',Color3.fromRGB(151,151,151)); skip.Position=UDim2.new(.5,8,0,267); skip.Size=UDim2.new(.5,-16,0,48); skip.TextColor3=C.cream; skip.TextStrokeTransparency=1; Art.brick(skip,skip.BackgroundColor3)
    local skipNote=text(skip,'Availability',12,C.cream); skipNote.Position=UDim2.new(0,0,1,2); skipNote.Size=UDim2.new(1,0,0,20); skipNote.Text='Robux · Coming soon'; skipNote.TextStrokeTransparency=1
    label('ResetWarning','Resets cash, Brainrots, Minis and processor.\nKeeps your index and permanent passes.',338,32,14,C.pink)
    normal.Activated:Connect(function() if view.eligible and not view.pending then view.onRebirth() else view:notice('Meet the cash and Level 6 requirements first.') end end)
    skip.Activated:Connect(function() view:notice('No Reset rebirth will keep your characters. Robux purchase is coming soon.') end)
    return {
        setVisible=function(active: boolean)
            header.Visible=active; content.Visible=active
            view.heading.Position=UDim2.fromOffset(if active then 65 else 12,4)
            view.heading.TextXAlignment=if active then Enum.TextXAlignment.Left else Enum.TextXAlignment.Center
            view.panel.BackgroundTransparency=if active then .25 else 0
        end,
        render=function(state: any)
            local cost=Config.RebirthBase+state.rebirths*Config.RebirthStep
            boostText.Text='x'..(1+math.min(state.rebirths+1,Config.MaxRebirths)*.25)..' Cash'
            local buyTier=math.clamp(state.rebirths+1,1,Config.MaxTier)
            bulkText.Text='Buy 50 - Tier '..buyTier
            if shownTier~=buyTier then
                if bulkPortrait then bulkPortrait:Destroy() end
                bulkPortrait=Art.portrait(bulk,string.format('tier_%02d',buyTier),UDim2.fromScale(.2,.32),UDim2.fromScale(.6,.66)); shownTier=buyTier
            end
            fill.Size=UDim2.fromScale(math.clamp(state.coinUnits/cost,0,1),1)
            amount.Text='$'..view.coins(state.coinUnits)..' / '..(if cost>=4000000 then string.format('%gM',cost/4000000) else view.coins(cost))
            local top=false; for _,producer in state.producers do if Catalog[producer.speciesId].tier==6 then top=true end end
            level.Text=(if top then '✓ ' else '')..'Own a Level 6 Brainrot'
            view.eligible=top and state.coinUnits>=cost and state.rebirths<Config.MaxRebirths
            normal.BackgroundTransparency=if view.eligible then 0 else .35
            normal.Text=if view.pending then 'Please wait...' elseif state.rebirths>=Config.MaxRebirths then 'MAX REBIRTHS' else 'REBIRTH'
        end,
    }
end
return Panel
