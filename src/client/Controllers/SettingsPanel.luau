--!strict
local Preferences=require(script.Parent:WaitForChild('Preferences'))
local Panel={Height=270}

function Panel.new(view: any,button: any,text: any,frame: any,Art: any,C: any)
    local header=Instance.new('Frame');header.Name='SettingsHeader';header.BackgroundTransparency=1;header.Size=UDim2.fromOffset(40,40);header.Position=UDim2.fromOffset(10,5);header.Parent=view.panel
    Art.icon(header,'gear',UDim2.fromScale(0,0),UDim2.fromScale(1,1))
    local viewport=Instance.new('ScrollingFrame');viewport.Name='SettingsViewport';viewport.BackgroundTransparency=1;viewport.BorderSizePixel=0;viewport.ScrollBarThickness=4;viewport.ScrollingDirection=Enum.ScrollingDirection.Y;viewport.CanvasSize=UDim2.fromOffset(0,208);viewport.Parent=view.panel
    local content=Instance.new('Frame');content.Name='SettingsContent';content.Size=UDim2.new(1,-6,0,208);content.BackgroundTransparency=1;content.Parent=viewport
    local disconnects={}
    local rows={}
    for index,spec in {{key='sfxVolume',label='Sound effects'},{key='musicVolume',label='Music'}} do
        local row=frame(content,spec.key,C.navy);row.BackgroundTransparency=.35;row.Position=UDim2.fromOffset(4,(index-1)*58);row.Size=UDim2.new(1,-8,0,52)
        local label=text(row,'Label',18,C.cream);label.Text=spec.label;label.TextXAlignment=Enum.TextXAlignment.Left;label.Position=UDim2.fromOffset(8,0);label.Size=UDim2.new(1,-138,1,0)
        local amount=text(row,'Amount',19,C.cream);amount.Position=UDim2.new(1,-84,0,0);amount.Size=UDim2.fromOffset(44,52)
        local decrease=button(row,'Decrease','−',C.blue);decrease.Position=UDim2.new(1,-126,0,4);decrease.Size=UDim2.fromOffset(40,44);decrease.TextSize=25
        local increase=button(row,'Increase','+',C.blue);increase.Position=UDim2.new(1,-40,0,4);increase.Size=UDim2.fromOffset(36,44);increase.TextSize=25
        table.insert(rows,{root=row,label=label,amount=amount,decrease=decrease,increase=increase})
        local function adjust(direction: number)
            local value=assert(Preferences.get(spec.key))
            Preferences.set(spec.key,math.round(value*100+direction*10)/100)
        end
        decrease.Activated:Connect(function() adjust(-1) end)
        increase.Activated:Connect(function() adjust(1) end)
        table.insert(disconnects,Preferences.subscribe(spec.key,function(value)
            amount.Text=tostring(math.round(value*100))..'%'
            decrease.Active=value>0;decrease.AutoButtonColor=decrease.Active;decrease.BackgroundTransparency=if decrease.Active then 0 else .55
            increase.Active=value<1;increase.AutoButtonColor=increase.Active;increase.BackgroundTransparency=if increase.Active then 0 else .55
        end))
    end
    local reset=button(content,'ResetDefaults','Reset audio',C.amber);reset.Position=UDim2.fromOffset(4,118);reset.Size=UDim2.new(1,-8,0,40);reset.TextSize=19
    reset.Activated:Connect(function() Preferences.reset() end)
    local status=text(content,'SessionNotice',14,C.cream);status.Text='Session only. Resets on rejoin.';status.Position=UDim2.fromOffset(6,164);status.Size=UDim2.new(1,-12,0,40)
    view.gui.Destroying:Connect(function() for _,disconnect in disconnects do disconnect() end end)
    header.Visible=false;viewport.Visible=false
    return {
        setVisible=function(active: boolean) header.Visible=active;viewport.Visible=active end,
        resize=function()
            local compact=view.panel.Size.X.Offset<250
            local contentHeight=if compact then 250 else 208
            content.Size=UDim2.new(1,-6,0,contentHeight)
            viewport.CanvasSize=UDim2.fromOffset(0,contentHeight)
            viewport.Position=UDim2.fromOffset(8,54)
            viewport.Size=UDim2.new(1,-16,1,-62)
            viewport.ScrollingEnabled=view.panel.Size.Y.Offset-62<contentHeight
            if not viewport.ScrollingEnabled then viewport.CanvasPosition=Vector2.zero end
            for index,row in rows do
                row.root.Position=UDim2.fromOffset(4,(index-1)*(if compact then 80 else 58))
                row.root.Size=UDim2.new(1,-8,0,if compact then 74 else 52)
                row.label.Position=UDim2.fromOffset(8,0);row.label.Size=if compact then UDim2.new(1,-16,0,24) else UDim2.new(1,-138,1,0);row.label.TextSize=if compact then 16 else 18
                row.decrease.Position=if compact then UDim2.fromOffset(8,26) else UDim2.new(1,-126,0,4)
                row.amount.Position=if compact then UDim2.new(.5,-22,0,26) else UDim2.new(1,-84,0,0);row.amount.Size=UDim2.fromOffset(44,if compact then 44 else 52)
                row.increase.Position=UDim2.new(1,if compact then -44 else -40,0,if compact then 26 else 4)
            end
            reset.Position=UDim2.fromOffset(4,if compact then 160 else 118)
            status.Position=UDim2.fromOffset(6,if compact then 206 else 164)
        end,
    }
end

return table.freeze(Panel)
