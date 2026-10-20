$ErrorActionPreference = 'Stop'
$repo = Split-Path -Parent $PSScriptRoot
$runtime = @'
-- Execute the real generator and Factory.part using numeric recording instances.
-- Native scaling, pivots and rendering remain covered by the Studio fixture.
local Config=require('../src/shared/Config')
local Core=require('../src/server/Domain/FarmCore')
local Catalog=require('../src/shared/CreatureCatalog')
local layout=Core.new(Config,Catalog)
local function vector(x,y,z) return {X=x,Y=y,Z=z} end
-- Only the generator's X-axis cap rotation is needed in this numeric runtime.
local frameMethods={}
local frameMeta={__index=frameMethods}
local function frame(x,y,z,rx)
    return setmetatable({X=x,Y=y,Z=z,rx=rx or 0},frameMeta)
end
function frameMethods:PointToWorldSpace(p)
    local c,s=math.cos(self.rx),math.sin(self.rx)
    return vector(self.X+p.X,self.Y+c*p.Y-s*p.Z,self.Z+s*p.Y+c*p.Z)
end
function frameMeta.__mul(a,b)
    local p=a:PointToWorldSpace(b)
    return frame(p.X,p.Y,p.Z,a.rx+b.rx)
end
local Instance={}
function Instance.new(kind)
    if kind=='Model' then return {parts={}} end
    assert(kind=='Part' or kind=='WedgePart','Unexpected generated instance '..kind)
    return setmetatable({ClassName=kind,CanQuery=true,FrontSurface='Smooth',LeftSurface='Smooth',RightSurface='Smooth'},{
        __newindex=function(self,key,value)
            rawset(self,key,value)
            if key=='Parent' then table.insert(value.parts,self) end
        end,
    })
end
local modules={Config=Config,TextStyle={}}
local environment=setmetatable({
    Instance=Instance,Vector3={new=vector},CFrame={new=frame,identity=frame(0,0,0),Angles=function(x,y,z)
        assert(y==0 and z==0,'The shelf numeric fixture supports only X rotation')
        return frame(0,0,0,x)
    end},
    Color3={fromRGB=vector},
    Enum={SurfaceType={Studs='Studs',Smooth='Smooth'},Material={Plastic='Plastic',Neon='Neon'},PartType={Block='Block'}},
    script={Parent={Config='Config',ModelFactory='ModelFactory',TextStyle='TextStyle'}},
    require=function(name) return assert(modules[name],'Missing dependency '..name) end,
},{__index=getfenv()})
local function compile(source)
    local chunk=assert(loadstring(source));setfenv(chunk,environment);return chunk()
end
'@
$factory = Get-Content -LiteralPath (Join-Path $repo 'src/shared/ModelFactory.luau') -Raw
$shelves = Get-Content -LiteralPath (Join-Path $repo 'src/shared/DisplayShelves.luau') -Raw
$scriptText = $runtime + "`nmodules.ModelFactory=compile([====[`n" + $factory + "`n]====])`n"
$scriptText += "local Shelves=compile([====[`n" + $shelves + "`n]====])`n"
$scriptText += @'
local function close(a,b,message) assert(math.abs(a-b)<1e-8,message) end
local function equal(a,b)
    if type(a)~='table' then return a==b end
    return a.X==b.X and a.Y==b.Y and a.Z==b.Z
end
local function auditDividers(shelf,row)
    local function at(name,x)
        local result=nil
        for _,part in shelf.parts do
            if part.Name==name and math.abs(part.CFrame.X-x)<1e-8 then
                assert(not result,'Duplicate bay part '..name)
                result=part
            end
        end
        return assert(result,'Missing bay part '..name)
    end
    for column=1,Config.Columns do
        local position=layout:slotPosition((row-1)*Config.Columns+column)
        local x=position.x
        local divider=at('DisplayDivider',x-4.95)
        assert(divider.ClassName=='WedgePart','Divider must open at the front with a triangular side profile')
        close(divider.CFrame.rx,0,'Wedge must rise toward the rear (+Z), not toward the belt')
        local plinth,back=at('DisplayPlatform',x),at('DisplayBack',x)
        local bottom=divider.CFrame.Y-divider.Size.Y/2
        local rearTop=divider.CFrame.Y+divider.Size.Y/2
        close(bottom,position.y,'Low divider front must meet the existing producer support plane')
        close(bottom,plinth.CFrame.Y+plinth.Size.Y/2,'Divider must meet the plinth')
        close(rearTop,back.CFrame.Y+back.Size.Y/2,'Tall divider rear must meet the existing back wall')
        local cap=at('DividerTopTrim',x-4.95)
        assert(cap.TopSurface=='Studs','Diagonal cap must retain the Lego surface')
        for _,side in {-1,1} do
            local endpoint=cap.CFrame:PointToWorldSpace(vector(0,0,side*cap.Size.Z/2))
            close(endpoint.X,divider.CFrame.X,'Cap left the divider')
            close(endpoint.Y,if side<0 then bottom else rearTop,'Cap must follow the full wedge slope without a gap')
            close(endpoint.Z,divider.CFrame.Z+side*divider.Size.Z/2,'Cap must meet both wedge ends')
        end
        local rearCap=at('BayTopTrim',x)
        for _,sx in {-1,1} do for _,sy in {-1,1} do for _,sz in {-1,1} do
            local corner=cap.CFrame:PointToWorldSpace(vector(sx*cap.Size.X/2,sy*cap.Size.Y/2,sz*cap.Size.Z/2))
            assert(corner.Z>=84.5 and corner.Z<=91.5,'Sloped cap escaped the old divider depth envelope')
            assert(corner.Y<=rearCap.CFrame.Y+rearCap.Size.Y/2+1e-8,'Sloped cap grew above the existing back trim')
            assert(math.abs(corner.X-x)>=4.76-1e-8,'Cap narrowed the producer/Mini center corridor')
        end end end
        for _,part in {divider,cap} do
            assert(part.Anchored and not part.CanTouch,'Shelf geometry must stay anchored without touch events')
            assert(part.CanCollide==(part==divider),'Stand dividers must block players; trim remains cosmetic')
        end
        assert(plinth.CanCollide and back.CanCollide,'Producer stands need solid top and rear supports')
    end
end
local additions={RearRowJoin=true,RearRowSupport=true,FrontRowSupport=true}
local first=Shelves.buildRow(1,layout)
assert(#first.parts==221,'The ground row must retain its existing 221 parts')
for _,part in first.parts do assert(not additions[part.Name],'Ground row has no preceding gap to fill') end
auditDividers(first,1)
local extra=0
for row=2,5 do
    local shelf=Shelves.buildRow(row,layout)
    local panels,supports,fronts,retained={},{},{},{}
    for _,part in shelf.parts do
        if part.Name=='RearRowJoin' then table.insert(panels,part)
        elseif part.Name=='RearRowSupport' then table.insert(supports,part)
        elseif part.Name=='FrontRowSupport' then table.insert(fronts,part)
        else table.insert(retained,part) end
    end
    assert(#panels==1,'Upper row '..row..' must close its rear air gap with one panel')
    assert(#supports==2,'Upper rows need exactly two rear edge supports')
    assert(#fronts==11,'Every upper row needs both outside posts and all nine internal bay divisions')
    assert(#shelf.parts==235 and #retained==221,'Upper rows add three rear pieces and eleven front pillars')
    auditDividers(shelf,row)
    extra+=#panels+#supports+#fronts
    -- All original visible geometry must remain a pure vertical translation.
    for index,part in retained do
        local base=first.parts[index]
        local name=if base.Name:match('^Slot%d+$') then 'Slot'..(tonumber(base.Name:sub(5))+(row-1)*10) else base.Name
        assert(part.Name==name,'Slot lookup or original part order changed')
        for _,key in {'ClassName','Size','Color','Material','TopSurface','BottomSurface','FrontSurface','LeftSurface','RightSurface','Anchored','CanCollide','CanTouch','CanQuery'} do
            assert(equal(part[key],base[key]),'Existing '..part.Name..' '..key..' changed')
        end
        close(part.CFrame.X,base.CFrame.X,'Existing x moved')
        close(part.CFrame.Z,base.CFrame.Z,'Existing z moved')
        close(part.CFrame.Y,base.CFrame.Y+(row-1)*11,'Existing support height moved')
        close(part.CFrame.rx,base.CFrame.rx,'Upper row orientation changed')
    end
    local rowY=(row-1)*11
    local panel=panels[1]
    close(panel.CFrame.Y-panel.Size.Y/2,rowY-3.7,'Join must meet preceding back wall')
    close(panel.CFrame.Y+panel.Size.Y/2,rowY+.1,'Join must reach inside the current base')
    close(panel.Size.X,99.9,'Join must span the existing bay backs')
    assert(panel.FrontSurface=='Studs','Join must retain the native brick face')
    for _,part in {panel,supports[1],supports[2]} do
        assert(part.Anchored and not part.CanCollide and not part.CanQuery and not part.CanTouch,'Added rear geometry must be inert')
        assert(part.CFrame.Z-part.Size.Z/2>=91.24-1e-8 and part.CFrame.Z+part.Size.Z/2<=91.66+1e-8,'Added geometry must stay inside the existing rear trim depth')
        assert(math.abs(part.CFrame.X)+part.Size.X/2<=49.95+1e-8,'Added geometry must stay inside the existing backs width')
    end
    assert(supports[1].CFrame.X*supports[2].CFrame.X<0,'Rear supports must occupy opposite edges')
    for _,part in supports do
        close(math.abs(part.CFrame.X),49.65,'Support must hug the rear edge')
        close(part.Size.X,.6,'Support must stay narrow')
        close(part.CFrame.Y-part.Size.Y/2,rowY-11,'Support must meet the previous shelf base')
        close(part.CFrame.Y+part.Size.Y/2,rowY+.45,'Support must meet the current shelf base')
    end
    for index,part in fronts do
        close(part.CFrame.X,50-(index-1)*10,'Front pillar must align with a bay boundary')
        close(part.Size.X,.34,'Front pillar must remain narrow enough to reveal faces')
        close(part.Size.Z,.38,'Front pillar depth must stay inside the front trim')
        close(part.CFrame.Z,Config.DisplayZ-3.35,'Front pillars must remain ahead of the producer center')
        close(part.CFrame.Y-part.Size.Y/2,rowY-11+Config.DisplayPlatformHeight,'Pillar must meet the lower platform floor')
        close(part.CFrame.Y+part.Size.Y/2,rowY,'Pillar must meet the upper shelf underside')
        assert(part.Anchored and part.CanCollide and part.CanQuery and not part.CanTouch and part.FrontSurface=='Studs',
            'Visible structural pillars need solid physics and native studs')
        for column=1,Config.Columns do
            local center=layout:slotPosition((row-2)*Config.Columns+column)
            assert(math.abs(part.CFrame.X-center.x)-part.Size.X/2>=4.8,
                'Pillars must leave the producer and falling Mini center corridors open')
        end
    end
    print('PASS row '..row..': continuous rear join, two rear supports, eleven front pillars, all 221 original parts preserved')
end
assert(extra==56,'Full plot must retain twelve rear pieces and add exactly forty-four front pillars')
print('PASS one/two/five-row support and open Mini corridors; 221/235 Parts per ground/upper row, 1161 per full plot')
'@
$target = Join-Path $repo '.tools/display-shelves-structure-cli.luau'
[System.IO.File]::WriteAllText($target, $scriptText)
& (Join-Path $repo '.tools/luau/luau.exe') $target
exit $LASTEXITCODE
