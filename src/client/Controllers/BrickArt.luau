--!strict
-- Native UI artwork and model portraits: no placeholder image IDs or external fonts.
local Shared=game:GetService('ReplicatedStorage'):WaitForChild('Shared')
local Style=require(Shared:WaitForChild('TextStyle'))
local Factory=require(Shared:WaitForChild('ModelFactory'))
local Catalog=require(Shared:WaitForChild('CreatureCatalog'))
local LuckyVisuals=require(Shared:WaitForChild('LuckyBlockVisuals'))
local ContentProvider=game:GetService('ContentProvider')
local Icon3D=require(script.Parent.Icon3D)
local Art={}
local ink=Color3.fromRGB(31,27,23)
local function rect(parent: Instance,pos: UDim2,size: UDim2,color: Color3,rotation: number?,border: number?): Frame
    local f=Instance.new('Frame'); f.Size=size; f.Position=pos; f.BackgroundColor3=color; f.BorderSizePixel=0; f.Rotation=rotation or 0; f.Parent=parent
    if border then local s=Instance.new('UIStroke'); s.Thickness=border; s.Color=ink; s.Parent=f end
    return f
end
local function glyph(parent: Instance,value: string,pos: UDim2,size: UDim2,color: Color3)
    local l=Instance.new('TextLabel'); l.Text=value; l.Position=pos; l.Size=size; l.BackgroundTransparency=1; l.Font=Enum.Font.FredokaOne; l.TextColor3=color; l.TextScaled=true; l.TextStrokeTransparency=0; l.TextStrokeColor3=ink; l.Parent=parent
    Style.apply(l,nil,color)
    return l
end
function Art.brick(parent: GuiObject,color: Color3)
    local art=Instance.new('Frame'); art.Name='BrickTexture'; art.Size=UDim2.fromScale(1,1); art.BackgroundTransparency=1; art.ClipsDescendants=true; art.Parent=parent
    local studs: {Frame}={}; local queued=false
    local function layoutStuds()
        queued=false
        if not art.Parent then return end
        local width,height=art.AbsoluteSize.X,art.AbsoluteSize.Y
        if width<8 or height<8 then for _,stud in studs do stud.Visible=false end; return end
        -- Work in rendered pixels, then convert each square back to scale units.
        -- This also handles a UIScale on the Lucky card or a hovering button.
        local pitch=22
        local columns=math.max(1,math.floor((width-12)/pitch)); local rows=math.max(1,math.floor((height-12)/pitch))
        while columns*rows>240 do
            pitch+=1; columns=math.max(1,math.floor((width-12)/pitch)); rows=math.max(1,math.floor((height-12)/pitch))
        end
        local side=math.min(11,width-6,height-6)
        local left=(width-(columns-1)*pitch-side)/2; local top=(height-(rows-1)*pitch-side)/2
        local count=columns*rows
        for index=1,count do
            local stud=studs[index]
            if not stud then
                stud=rect(art,UDim2.new(),UDim2.new(),color:Lerp(Color3.new(1,1,1),.14)); stud.Name='Stud'
                local corner=Instance.new('UICorner'); corner.CornerRadius=UDim.new(0,1); corner.Parent=stud
                local border=Instance.new('UIStroke'); border.Color=color:Lerp(ink,.28); border.Thickness=1; border.Transparency=.45; border.Parent=stud
                local shading=Instance.new('UIGradient'); shading.Color=ColorSequence.new(Color3.new(1,1,1),Color3.fromRGB(185,185,185)); shading.Rotation=90; shading.Parent=stud
                local highlight=rect(stud,UDim2.fromScale(.09,.06),UDim2.fromScale(.82,.16),color:Lerp(Color3.new(1,1,1),.5)); highlight.Name='Highlight'; highlight.BackgroundTransparency=.2
                local shadow=rect(stud,UDim2.fromScale(.12,.84),UDim2.fromScale(.82,.16),color:Lerp(ink,.42)); shadow.Name='Shadow'; shadow.BackgroundTransparency=.15
                studs[index]=stud
            end
            local column=(index-1)%columns; local row=math.floor((index-1)/columns)
            stud.Visible=true; stud.Size=UDim2.fromScale(side/width,side/height); stud.Position=UDim2.fromScale((left+column*pitch)/width,(top+row*pitch)/height)
        end
        for index=count+1,#studs do studs[index].Visible=false end
    end
    art:GetPropertyChangedSignal('AbsoluteSize'):Connect(function()
        if queued then return end; queued=true; task.defer(layoutStuds)
    end)
    task.defer(layoutStuds)
    if parent:IsA('TextButton') then
        local label=Instance.new('TextLabel'); label.Name='BrickCaption'; label.BackgroundTransparency=1; label.Size=UDim2.fromScale(1,1); label.ZIndex=3; label.Parent=parent
        local function sync()
            label.Text=parent.Text; label.Font=parent.Font; label.TextSize=parent.TextSize; label.TextColor3=parent.TextColor3
            label.TextWrapped=parent.TextWrapped; label.TextXAlignment=parent.TextXAlignment; label.TextYAlignment=parent.TextYAlignment
            Style.apply(label,parent.TextSize,parent.TextColor3)
            local parentOutline=parent:FindFirstChild('TextOutline'); if parentOutline then parentOutline.Enabled=false end
        end
        for _,property in {'Text','Font','TextSize','TextColor3','TextWrapped','TextXAlignment','TextYAlignment','TextStrokeColor3','TextStrokeTransparency'} do parent:GetPropertyChangedSignal(property):Connect(sync) end
        parent.TextTransparency=1; sync()
    end
    local function recolor(nextColor: Color3)
        color=nextColor
        for _,stud in studs do
            stud.BackgroundColor3=color:Lerp(Color3.new(1,1,1),.14)
            local border=stud:FindFirstChildOfClass('UIStroke')
            if border then border.Color=color:Lerp(ink,.28) end
            local highlight=stud:FindFirstChild('Highlight')
            local shadow=stud:FindFirstChild('Shadow')
            if highlight and highlight:IsA('Frame') then highlight.BackgroundColor3=color:Lerp(Color3.new(1,1,1),.5) end
            if shadow and shadow:IsA('Frame') then shadow.BackgroundColor3=color:Lerp(ink,.42) end
        end
    end
    return art,recolor
end
local function preparePortrait(v: ViewportFrame,model: Model,delegatedPreload: boolean?)
    -- Mesh content is not guaranteed to have loaded when a template is cloned.
    -- Keep the WorldModel and reveal only after the preload attempt completes.
    v.Visible=false
    if not delegatedPreload then
        task.spawn(function()
            pcall(function() ContentProvider:PreloadAsync(model:GetDescendants()) end)
            if v.Parent then v.Visible=true end
        end)
    end
    local cf,extent=model:GetBoundingBox(); local camera=Instance.new('Camera'); camera.FieldOfView=35
    camera.CFrame=CFrame.lookAt(cf.Position+Vector3.new(extent.X*.22,extent.Y*.09,-math.max(extent.Y,extent.X,extent.Z)*1.85),cf.Position)
    camera.Parent=v; v.CurrentCamera=camera
end
function Art.portrait(parent: Instance,speciesId: string,pos: UDim2,size: UDim2,mini: boolean?,silhouette: boolean?)
    local v=Instance.new('ViewportFrame'); v.Name='CharacterPortrait'; v.Position=pos; v.Size=size; v.BackgroundTransparency=1; v.Ambient=Color3.fromRGB(220,220,220); v.LightColor=Color3.new(1,1,1); v.LightDirection=Vector3.new(-1,-1,-2); v.Parent=parent
    local world=Instance.new('WorldModel'); world.Parent=v
    local model=Factory.producer(world,'Portrait',Catalog[speciesId],Vector3.zero,mini~=false)
    for _,item in model:GetDescendants() do if item:IsA('BillboardGui') then item:Destroy() end end
    if silhouette then v.ImageColor3=Color3.new(0,0,0) end
    preparePortrait(v,model); return v
end
function Art.luckyPortrait(parent: Instance,pos: UDim2,size: UDim2,delegatedPreload: boolean?,baseTier: number?)
    local v=Instance.new('ViewportFrame'); v.Name='LuckyBlockPortrait'; v.Position=pos; v.Size=size; v.BackgroundTransparency=1; v.Ambient=Color3.fromRGB(235,235,235); v.LightColor=Color3.new(1,1,1); v.LightDirection=Vector3.new(-1,-1,-2); v.Parent=parent
    local world=Instance.new('WorldModel'); world.Parent=v
    local model=Instance.new('Model'); model.Name='LuckyBlock'; model.Parent=world
    local mesh: BasePart?=Factory.prop(model,'LuckyBlock',CFrame.new())
    if not mesh then
        mesh=Factory.part(model,'GoldenBlock',Vector3.new(3,3,3),CFrame.new(),Color3.fromRGB(255,193,0))
    end
    model.PrimaryPart=mesh
    LuckyVisuals.apply(mesh,baseTier)
    preparePortrait(v,model,delegatedPreload)
    local cf,extent=model:GetBoundingBox(); local distance=math.max(extent.X,extent.Y,extent.Z)*2.45
    local camera=v.CurrentCamera
    if camera then camera.CFrame=CFrame.lookAt(cf.Position+Vector3.new(1,.72,-1).Unit*distance,cf.Position) end
    return v
end
function Art.setLuckyTier(viewport: ViewportFrame,baseTier: number?)
    local world=viewport:FindFirstChildOfClass('WorldModel')
    local model=world and world:FindFirstChild('LuckyBlock')
    if model and model:IsA('Model') and model.PrimaryPart then LuckyVisuals.apply(model.PrimaryPart,baseTier) end
end
function Art.cardPortrait(entry: TextButton,speciesId: string)
    local caption=entry.Text; entry.Text=''
    Art.portrait(entry,speciesId,UDim2.fromOffset(0,0),UDim2.new(0,60,1,0))
    local label=Instance.new('TextLabel'); label.Name='Caption'; label.BackgroundTransparency=1
    label.Position=UDim2.fromOffset(64,0); label.Size=UDim2.new(1,-68,1,0); label.Text=caption
    label.TextColor3=entry.TextColor3; label.Font=entry.Font; label.TextSize=16; label.TextWrapped=true; label.Parent=entry; Style.apply(label,16)
end
function Art.icon(parent: Instance,kind: string,pos: UDim2,size: UDim2)
    local sculpture=Icon3D.create(parent,kind,pos,size)
    if sculpture then return sculpture end
    local f=Instance.new('Frame'); f.Name='Icon'; f.Position=pos; f.Size=size; f.BackgroundTransparency=1; f.Parent=parent
    if kind=='book' then
        local book=rect(f,UDim2.fromScale(.18,.22),UDim2.fromScale(.64,.61),Color3.fromRGB(255,202,87),-27,4)
        rect(book,UDim2.fromScale(.07,.30),UDim2.fromScale(.9,.55),Color3.fromRGB(255,230,150),0,2)
        local cover=rect(book,UDim2.fromScale(-.04,-.09),UDim2.fromScale(1.04,.78),Color3.fromRGB(189,45,52),0,4)
        rect(cover,UDim2.fromScale(.14,.16),UDim2.fromScale(.72,.62),Color3.fromRGB(236,94,78),0,2)
        rect(cover,UDim2.fromScale(.22,.24),UDim2.fromScale(.56,.18),Color3.fromRGB(153,39,46))
        rect(cover,UDim2.fromScale(.22,.48),UDim2.fromScale(.56,.12),Color3.fromRGB(183,48,48))
        local ribbon=rect(book,UDim2.fromScale(.13,.63),UDim2.fromScale(.15,.43),Color3.fromRGB(244,88,79),10,2); ribbon.ZIndex=2
    elseif kind=='rebirth' then
        local aspect=Instance.new('UIAspectRatioConstraint'); aspect.AspectRatio=1; aspect.Parent=f
        -- Two long circular arcs with native scanline triangle heads. Avoid a
        -- font triangle here: fallback glyph sizing can hide the curved shafts.
        for layer=1,2 do for half=0,1 do
            local color=if layer==1 then ink elseif half==0 then Color3.fromRGB(255,94,175) else Color3.fromRGB(126,223,255)
            for segment=0,32 do
                local angle=math.rad(-168+half*180+segment*4.875)
                local thickness=if layer==1 then .19 else .115
                local piece=rect(f,UDim2.fromScale(.5+math.cos(angle)*.30,.5+math.sin(angle)*.30),UDim2.fromScale(thickness,thickness),color)
                piece.AnchorPoint=Vector2.new(.5,.5)
                local rounded=Instance.new('UICorner'); rounded.CornerRadius=UDim.new(1,0); rounded.Parent=piece
            end
        end end
        for half=0,1 do
            local angle=math.rad(-12+half*180)
            local center=Vector2.new(.5+math.cos(angle)*.30,.5+math.sin(angle)*.30)+Vector2.new(-math.sin(angle),math.cos(angle))*.045
            local head=Instance.new('Frame'); head.Name='ArrowHead'; head.BackgroundTransparency=1; head.AnchorPoint=Vector2.new(.5,.5); head.Position=UDim2.fromScale(center.X,center.Y); head.Size=UDim2.fromScale(.31,.29); head.Rotation=math.deg(angle); head.Parent=f
            for layer=1,2 do
                local color=if layer==1 then ink elseif half==0 then Color3.fromRGB(255,94,175) else Color3.fromRGB(126,223,255)
                local margin=if layer==1 then 0 else .15
                for row=0,23 do
                    local t=row/24; local width=(1-t)*(1-margin*2)
                    rect(head,UDim2.fromScale((1-width)/2,margin+t*(1-margin*2)),UDim2.fromScale(width,(1-margin*2)/24+.006),color)
                end
            end
        end
    elseif kind=='money' then
        local bill=rect(f,UDim2.fromScale(.1,.2),UDim2.fromScale(.8,.58),Color3.fromRGB(131,255,48),-8,3)
        rect(bill,UDim2.fromScale(.08,.13),UDim2.fromScale(.84,.74),Color3.fromRGB(85,190,20),0,2)
        glyph(bill,'$',UDim2.fromScale(.3,.05),UDim2.fromScale(.4,.9),Color3.fromRGB(209,255,141))
    elseif kind=='home' then
        rect(f,UDim2.fromScale(.20,.39),UDim2.fromScale(.6,.48),Color3.fromRGB(255,237,178),0,2)
        rect(f,UDim2.fromScale(.27,.15),UDim2.fromScale(.48,.48),Color3.fromRGB(232,74,68),45,2)
        rect(f,UDim2.fromScale(.23,.45),UDim2.fromScale(.54,.38),Color3.fromRGB(255,237,178))
        rect(f,UDim2.fromScale(.42,.6),UDim2.fromScale(.18,.27),Color3.fromRGB(120,72,38))
    elseif kind=='merge' then
        Art.portrait(f,'tier_01',UDim2.fromScale(0,0),UDim2.fromScale(.6,.85))
        Art.portrait(f,'tier_02',UDim2.fromScale(.4,.12),UDim2.fromScale(.6,.85))
        glyph(f,'+',UDim2.fromScale(.35,.53),UDim2.fromScale(.3,.38),Color3.fromRGB(255,230,71))
    else
        glyph(f,'⚙',UDim2.fromScale(0,0),UDim2.fromScale(1,1),Color3.fromRGB(255,233,137))
    end
    return f
end
function Art.basket(parent: GuiObject)
    local function rounded(object: GuiObject,radius: number)
        local corner=Instance.new('UICorner');corner.CornerRadius=UDim.new(radius,0);corner.Parent=object
    end
    -- Crop the actual character models to their upper faces. Every viewport stays
    -- inside the bag: no tall full-body portrait extends up over the avatar.
    for _,spec in {{'tier_01',.07,.09,.34,.43},{'tier_01',.59,.09,.34,.43},{'tier_02',.31,.015,.38,.50}} do
        local face=Art.portrait(parent,spec[1],UDim2.fromScale(spec[2],spec[3]),UDim2.fromScale(spec[4],spec[5]))
        face.Name='BasketFace';face.ZIndex=1
        local world=face:FindFirstChildOfClass('WorldModel')
        local character=world and world:FindFirstChild('Portrait')
        if character and character:IsA('Model') and face.CurrentCamera then
            local cf,extent=character:GetBoundingBox()
            local focus=cf.Position+Vector3.new(0,extent.Y*.23,0)
            face.CurrentCamera.CFrame=CFrame.lookAt(focus+Vector3.new(extent.X*.07,extent.Y*.02,-extent.Y*.93),focus)
        end
    end
    local body=rect(parent,UDim2.fromScale(.075,.46),UDim2.fromScale(.85,.525),Color3.fromRGB(242,161,51),0,4)
    body.Name='WovenBody';body.ClipsDescendants=true;body.ZIndex=2;rounded(body,.38)
    local shade=Instance.new('UIGradient')
    shade.Color=ColorSequence.new({
        ColorSequenceKeypoint.new(0,Color3.fromRGB(255,218,126)),
        ColorSequenceKeypoint.new(.42,Color3.fromRGB(255,198,81)),
        ColorSequenceKeypoint.new(1,Color3.fromRGB(183,91,22)),
    })
    shade.Rotation=90;shade.Parent=body
    -- Short interlaced strips stay safely within the rounded silhouette.
    -- Large diagonal stripes previously escaped the corners and read as a box.
    for row=1,3 do
        for column=1,6 do
            local x=.075+(column-1)*.17
            local y=.18+(row-1)*.29
            if row==3 and (column==1 or column==6) then continue end
            for _,direction in {-1,1} do
                local strip=rect(body,UDim2.fromScale(x,y),UDim2.fromScale(.15,.045),
                    if direction==1 then Color3.fromRGB(255,219,127) else Color3.fromRGB(175,86,22),direction*35)
                strip.Name='CrossWeave';strip.AnchorPoint=Vector2.new(.5,.5);strip.ZIndex=2
                strip.BackgroundTransparency=.12;rounded(strip,.5)
            end
        end
    end
    local underRim=rect(parent,UDim2.fromScale(.055,.52),UDim2.fromScale(.89,.115),Color3.fromRGB(146,67,16))
    underRim.Name='RimDepth';underRim.ZIndex=3;rounded(underRim,.8)
    local rim=rect(parent,UDim2.fromScale(.015,.44),UDim2.fromScale(.97,.16),Color3.fromRGB(255,185,64),0,3)
    rim.Name='BasketRim';rim.ZIndex=3;rounded(rim,.8)
    local rimShade=Instance.new('UIGradient');rimShade.Rotation=90
    rimShade.Color=ColorSequence.new(Color3.fromRGB(255,229,144),Color3.fromRGB(224,128,30));rimShade.Parent=rim
    local highlight=rect(rim,UDim2.fromScale(.045,.10),UDim2.fromScale(.91,.19),Color3.fromRGB(255,240,180))
    highlight.Name='RimHighlight';highlight.ZIndex=3;rounded(highlight,1)
    local plateShadow=rect(parent,UDim2.fromScale(.155,.652),UDim2.fromScale(.69,.305),Color3.fromRGB(153,75,20))
    plateShadow.Name='CountInsetDepth';plateShadow.ZIndex=3;rounded(plateShadow,.42)
    local plate=rect(parent,UDim2.fromScale(.16,.64),UDim2.fromScale(.68,.30),Color3.fromRGB(255,236,181),0,2)
    plate.Name='CountInset';plate.ZIndex=3;rounded(plate,.42)
    local plateShade=Instance.new('UIGradient');plateShade.Rotation=90
    plateShade.Color=ColorSequence.new(Color3.fromRGB(255,248,210),Color3.fromRGB(255,221,137));plateShade.Parent=plate
end
return Art
