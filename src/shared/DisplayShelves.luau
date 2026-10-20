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
    local base=Factory.part(shelf,'ShelfBase',
        Vector3.new(Config.Columns*Config.ColumnSpacing+1,.45,7),
        CFrame.new(0,.225+rowY,Config.DisplayZ),orange)
    base.TopSurface=Enum.SurfaceType.Studs

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
        local divider=Factory.part(shelf,'DisplayDivider',Vector3.new(.22,4.5,6.8),
            CFrame.new(x-width/2,2.45+lift+rowY,Config.DisplayZ),Color3.fromRGB(217,164,66))
        divider.LeftSurface=Enum.SurfaceType.Studs
        divider.RightSurface=Enum.SurfaceType.Studs
        local glow=Factory.part(shelf,'Slot'..slot,Vector3.new(Config.ColumnSpacing*.9,.12,5.9),
            CFrame.new(x,height-.12+rowY,Config.DisplayZ),orange)
        glow.Material=Enum.Material.Neon
        local h=rowY+lift
        Factory.part(shelf,'DividerTopTrim',Vector3.new(.38,.22,7),
            CFrame.new(x-width/2,h+4.8,Config.DisplayZ),gold)
        Factory.part(shelf,'BayTopTrim',Vector3.new(width,.25,.42),
            CFrame.new(x,h+6,Config.DisplayZ+3.45),gold)
        local front=Factory.part(shelf,'PlatformFrontTrim',Vector3.new(width,height,.4),
            CFrame.new(x,rowY+height/2,Config.DisplayZ-3.4),Color3.fromRGB(255,195,42))
        front.FrontSurface=Enum.SurfaceType.Studs
    end
    return shelf
end
return table.freeze(Shelves)
