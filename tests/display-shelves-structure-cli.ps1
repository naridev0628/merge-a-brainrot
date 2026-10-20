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
local Instance={}
function Instance.new(kind)
    if kind=='Model' then return {parts={}} end
    assert(kind=='Part','Unexpected generated instance '..kind)
    return setmetatable({CanQuery=true,FrontSurface='Smooth',LeftSurface='Smooth',RightSurface='Smooth'},{
        __newindex=function(self,key,value)
            rawset(self,key,value)
            if key=='Parent' then table.insert(value.parts,self) end
        end,
    })
end
local modules={Config=Config,TextStyle={}}
local environment=setmetatable({
    Instance=Instance,Vector3={new=vector},CFrame={new=vector,identity={}},
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
local additions={RearRowJoin=true,RearRowSupport=true}
local first=Shelves.buildRow(1,layout)
assert(#first.parts==221,'The ground row must retain its existing 221 parts')
for _,part in first.parts do assert(not additions[part.Name],'Ground row has no preceding gap to fill') end
local extra=0
for row=2,5 do
    local shelf=Shelves.buildRow(row,layout)
    local panels,supports,retained={},{},{}
    for _,part in shelf.parts do
        if part.Name=='RearRowJoin' then table.insert(panels,part)
        elseif part.Name=='RearRowSupport' then table.insert(supports,part)
        else table.insert(retained,part) end
    end
    assert(#panels==1,'Upper row '..row..' must close its rear air gap with one panel')
    assert(#supports==2,'Upper rows need exactly two rear edge supports')
    assert(#shelf.parts==224 and #retained==221,'Upper rows may add only three parts')
    extra+=#panels+#supports
    -- All original visible geometry must remain a pure vertical translation.
    for index,part in retained do
        local base=first.parts[index]
        local name=if base.Name:match('^Slot%d+$') then 'Slot'..(tonumber(base.Name:sub(5))+(row-1)*10) else base.Name
        assert(part.Name==name,'Slot lookup or original part order changed')
        for _,key in {'Size','Color','Material','TopSurface','BottomSurface','FrontSurface','LeftSurface','RightSurface','Anchored','CanCollide','CanTouch','CanQuery'} do
            assert(equal(part[key],base[key]),'Existing '..part.Name..' '..key..' changed')
        end
        close(part.CFrame.X,base.CFrame.X,'Existing x moved')
        close(part.CFrame.Z,base.CFrame.Z,'Existing z moved')
        close(part.CFrame.Y,base.CFrame.Y+(row-1)*11,'Existing support height moved')
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
    print('PASS row '..row..': continuous rear join, two inert supports, all 221 original parts preserved')
end
assert(extra==12,'Full 50-producer plot must add exactly twelve parts')
print('PASS one/two/five-row structural contract; full plot 1105 -> 1117 Parts')
'@
$target = Join-Path $repo '.tools/display-shelves-structure-cli.luau'
[System.IO.File]::WriteAllText($target, $scriptText)
& (Join-Path $repo '.tools/luau/luau.exe') $target
exit $LASTEXITCODE
