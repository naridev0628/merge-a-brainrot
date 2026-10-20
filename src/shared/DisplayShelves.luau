--!strict
-- Build an unparented row in logical plot coordinates. WorldBuilder owns
-- scaling, parenting, yielding and render-generation cancellation.
local Config=require(script.Parent.Config)
local Factory=require(script.Parent.ModelFactory)
local Shelves={}
local orange=Color3.fromRGB(255,174,22)
local gold=Color3.fromRGB(255,215,103)

function Shelves.buildRow(row: number,layout: any): Model
    local shelf=Instance.new('Model')
    shelf.Name=tostring(row)
    shelf.WorldPivot=CFrame.identity
    local rowY=(row-1)*Config.RowHeight
    local height=Config.DisplayPlatformHeight
    local lift=height-.5
    local width=Config.ColumnSpacing-.1
    local studSpread=Config.ColumnSpacing*.37
    local dividerRise=lift+6-height
    local dividerDepth=6.8
    local dividerLength=math.sqrt(dividerDepth^2+dividerRise^2)
    local dividerTilt=-math.atan2(dividerRise,dividerDepth)
    local base=Factory.part(shelf,'ShelfBase',
        Vector3.new(Config.Columns*Config.ColumnSpacing+1,.45,7),
        CFrame.new(0,.225+rowY,Config.DisplayZ),orange)
    base.TopSurface=Enum.SurfaceType.Studs

    if row>1 then
        -- Close the air band above the preceding back wall. Keep all three
        -- pieces inside the rear trim footprint, clear of producers and drops.
        local lowerTop=rowY-Config.RowHeight+lift+6
        local upperBottom=rowY+.1
        local join=Factory.part(shelf,'RearRowJoin',
            Vector3.new(Config.Columns*Config.ColumnSpacing-.1,upperBottom-lowerTop,.25),
            CFrame.new(0,(lowerTop+upperBottom)/2,Config.DisplayZ+3.45),Color3.fromRGB(178,128,52))
        join.FrontSurface=Enum.SurfaceType.Studs
        join.CanQuery=false
        local previousBottom=rowY-Config.RowHeight
        local currentTop=rowY+.45
        for _,side in {-1,1} do
            local support=Factory.part(shelf,'RearRowSupport',
                Vector3.new(.6,currentTop-previousBottom,.42),
                CFrame.new(side*(Config.Columns*Config.ColumnSpacing/2-.35),
                    (previousBottom+currentTop)/2,Config.DisplayZ+3.45),Color3.fromRGB(217,164,66))
            support.CanQuery=false
        end
    end

    for column=1,Config.Columns do
        local slot=(row-1)*Config.Columns+column
        local position=layout:slotPosition(slot)
        local x=position.x
        local plinth=Factory.part(shelf,'DisplayPlatform',
            Vector3.new(Config.ColumnSpacing*.88,height,5.7),
            CFrame.new(x,height/2+rowY,Config.DisplayZ),Color3.fromRGB(255,223,122))
        plinth.TopSurface=Enum.SurfaceType.Studs
        -- These larger top studs preserve the raised brick silhouette. The
        -- dense smaller studs on flat faces become native surface decoration.
        for dx=-studSpread,studSpread,studSpread/2 do
            for _,dz in {-1.8,0,1.8} do
                Factory.part(shelf,'DisplayBrickStud',Vector3.new(.7,.16,.7),
                    CFrame.new(x+dx,height+.08+rowY,Config.DisplayZ+dz),Color3.fromRGB(255,237,167))
            end
        end
        local back=Factory.part(shelf,'DisplayBack',Vector3.new(width,5.8,.25),
            CFrame.new(x,3.1+lift+rowY,Config.DisplayZ+3.45),Color3.fromRGB(178,128,52))
        back.FrontSurface=Enum.SurfaceType.Studs
        -- A native wedge opens the front at the platform and rises to the
        -- unchanged rear wall. The gold cap shares its diagonal centerline.
        local dividerFrame=CFrame.new(x-width/2,height+dividerRise/2+rowY,Config.DisplayZ)
        local divider=Instance.new('WedgePart')
        divider.Name='DisplayDivider'
        divider.Size=Vector3.new(.22,dividerRise,dividerDepth)
        divider.CFrame=dividerFrame
        divider.Color=Color3.fromRGB(217,164,66)
        divider.Material=Enum.Material.Plastic
        divider.Anchored=true;divider.CanCollide=false;divider.CanTouch=false
        divider.TopSurface=Enum.SurfaceType.Smooth;divider.BottomSurface=Enum.SurfaceType.Smooth
        divider.LeftSurface=Enum.SurfaceType.Studs
        divider.RightSurface=Enum.SurfaceType.Studs
        divider.Parent=shelf
        local glow=Factory.part(shelf,'Slot'..slot,Vector3.new(Config.ColumnSpacing*.9,.12,5.9),
            CFrame.new(x,height-.12+rowY,Config.DisplayZ),orange)
        glow.Material=Enum.Material.Neon
        local h=rowY+lift
        local cap=Factory.part(shelf,'DividerTopTrim',Vector3.new(.38,.22,dividerLength),
            dividerFrame*CFrame.Angles(dividerTilt,0,0),gold)
        cap.TopSurface=Enum.SurfaceType.Studs
        Factory.part(shelf,'BayTopTrim',Vector3.new(width,.25,.42),
            CFrame.new(x,h+6,Config.DisplayZ+3.45),gold)
        local front=Factory.part(shelf,'PlatformFrontTrim',Vector3.new(width,height,.4),
            CFrame.new(x,rowY+height/2,Config.DisplayZ-3.4),Color3.fromRGB(255,195,42))
        front.FrontSurface=Enum.SurfaceType.Studs
    end
    return shelf
end
return table.freeze(Shelves)
