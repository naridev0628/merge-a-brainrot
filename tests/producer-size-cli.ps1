$ErrorActionPreference='Stop'
$repo=Split-Path -Parent $PSScriptRoot
# Imported dimensions, not hand-picked ideal cubes. Review imports replace the
# older Raccooni and Lirili templates under their existing catalog keys.
$templates=@{}
Get-ChildItem (Join-Path $repo 'assets/characters/roblox') -Filter '*.model.json' | ForEach-Object {
    $item=Get-Content -LiteralPath $_.FullName -Raw | ConvertFrom-Json
    $key=$_.Name.Replace('.model.json','')
    $templates[$key]=@{size=$item.properties.Size;mesh=$item.properties.MeshId}
}
foreach($path in @('assets/characters/expansion_import/asset-manifest.json','assets/characters/review_pack/import-manifest.json')){
    foreach($item in (Get-Content -LiteralPath (Join-Path $repo $path) -Raw | ConvertFrom-Json)){
        $key=if($item.key){$item.key}else{$item.name}
        $templates[$key]=@{size=$item.size;mesh=$item.mesh}
    }
}
$inputRows=foreach($key in ($templates.Keys | Sort-Object)){
    if($key -notmatch '^[A-Za-z0-9_]+$'){throw "Unexpected imported key $key"}
    $item=$templates[$key]
    $dimensions=($item.size | ForEach-Object {([double]$_).ToString('R',[System.Globalization.CultureInfo]::InvariantCulture)}) -join ','
    "['$key']={size=Vector3.new($dimensions),mesh='$($item.mesh)'},"
}
$runtime=@'
local Config=require('../src/shared/Config')
local Catalog=require('../src/shared/CreatureCatalog')
local Map={PlotScale=Config.PlotScale}
local vectorMeta={}
local function vector(x,y,z) return setmetatable({X=x or 0,Y=y or 0,Z=z or 0},vectorMeta) end
function vectorMeta.__add(a,b) return vector(a.X+b.X,a.Y+b.Y,a.Z+b.Z) end
function vectorMeta.__sub(a,b) return vector(a.X-b.X,a.Y-b.Y,a.Z-b.Z) end
function vectorMeta.__mul(a,b)
    if type(a)=='number' then a,b=b,a end
    return vector(a.X*b,a.Y*b,a.Z*b)
end
local Vector3={new=vector}
local frameMeta={}
local CFrame={}
function CFrame.new(x,y,z)
    return setmetatable({Position=if type(x)=='table' then x else vector(x,y,z)},frameMeta)
end
CFrame.identity=CFrame.new()
function frameMeta.__index(_,key) if key=='Rotation' then return CFrame.identity end end
function frameMeta.__mul(a,b) return CFrame.new(a.Position+b.Position) end
local methods={}
local Instance={}
function Instance.new(class)
    local item={_props={ClassName=class},_children={},_attributes={},_scale=1}
    return setmetatable(item,{
        __index=function(self,key) return methods[key] or self._props[key] end,
        __newindex=function(self,key,value)
            self._props[key]=value
            if key=='Parent' and value then table.insert(value._children,self) end
        end,
    })
end
function methods:IsA(class) return self.ClassName==class or (class=='BasePart' and self.ClassName=='MeshPart') end
function methods:FindFirstChild(name)
    for _,child in self._children do if child.Name==name then return child end end
end
function methods:WaitForChild(name) return assert(self:FindFirstChild(name),name) end
function methods:SetAttribute(name,value) self._attributes[name]=value end
function methods:GetAttribute(name) return self._attributes[name] end
function methods:Clone()
    local copy=Instance.new(self.ClassName)
    for key,value in self._props do if key~='Parent' then copy[key]=value end end
    return copy
end
function methods:GetPivot() return self.PrimaryPart.CFrame end
function methods:GetScale() return self._scale end
function methods:ScaleTo(scale)
    assert(self.PrimaryPart and self.PrimaryPart:IsA('MeshPart'),'All imported catalog producers must take the MeshPart path')
    self.PrimaryPart.Size*=scale/self._scale;self._scale=scale
end
function methods:PivotTo(frame) self.PrimaryPart.CFrame=frame end
function methods:GetBoundingBox() return self.PrimaryPart.CFrame,self.PrimaryPart.Size end
local storage=Instance.new('Folder')
local base=Instance.new('Folder');base.Name='CharacterModels';base.Parent=storage
local expansion=Instance.new('Folder');expansion.Name='ExpansionModels';expansion.Parent=storage
local style={apply=function() end}
local environment=setmetatable({
    Instance=Instance,Vector3=Vector3,CFrame=CFrame,Map=Map,
    Color3={fromRGB=vector,new=vector},
    UDim2={fromScale=vector},
    Enum={TextYAlignment={Bottom='Bottom',Top='Top'}},
    game={GetService=function(_,name) assert(name=='ReplicatedStorage');return storage end},
    script={Parent={Config='Config',TextStyle='TextStyle'}},
    require=function(module) if module=='Config' then return Config end;assert(module=='TextStyle');return style end,
},{__index=getfenv()})
local function compile(source)
    local chunk=assert(loadstring(source));setfenv(chunk,environment);return chunk()
end
'@
$factory=Get-Content -LiteralPath (Join-Path $repo 'src/shared/ModelFactory.luau') -Raw
$world=Get-Content -LiteralPath (Join-Path $repo 'src/server/Services/WorldBuilder.luau') -Raw
$placement=[regex]::Match($world,'local function placeScaled\(model: Model,transform: CFrame\)[\s\S]*?\r?\nend').Value
if(-not $placement){throw 'Missing real WorldBuilder placement function'}
$scriptText=$runtime+"`nlocal inputs={`n"+($inputRows -join "`n")+"`n}`n"
$scriptText+="local Factory=compile([====[`n"+$factory+"`n]====])`n"
$scriptText+="local placeScaled=compile([====[`n"+$placement+"`nreturn placeScaled`n]====])`n"
$scriptText+=@'
for key,input in inputs do
    local template=Instance.new('MeshPart')
    template.Name=key;template.Size=input.size;template.MeshId=input.mesh;template.CFrame=CFrame.new(800,-50,700)
    template.Parent=if key:match('^tier_') then base else expansion
end
local holder=Instance.new('Folder')
local minHeight,maxHeight,maxWidth=math.huge,0,0
for tier=1,Config.MaxTier do
    local id=string.format('tier_%02d',tier)
    local species=assert(Catalog[id])
    local key=species.modelKey or id
    local input=assert(inputs[key],'Catalog entry has no imported producer: '..key)
    local original=input.size
    local position=vector(45,Config.DisplayPlatformHeight+Config.RowHeight*2,Config.DisplayZ)
    local model=Factory.producer(holder,id,species,position)
    assert(model.PrimaryPart.MeshId==input.mesh,'Factory must select the exact imported character')
    local nameplate=assert(model.PrimaryPart:FindFirstChild('CharacterLabel'))
    local labelTop=model.PrimaryPart.Size.Y/2+nameplate.StudsOffset.Y+nameplate.Size.Y/2
    local labelClearance=(Config.RowHeight-Config.DisplayPlatformHeight-labelTop)*Config.PlotScale
    assert(labelClearance>=.5,'Producer nameplate reaches the next shelf underside: '..key)
    placeScaled(model,CFrame.new(120,0,-60))
    local frame,size=model:GetBoundingBox()
    assert(math.abs(size.Y-3.15)<1e-6,'Producer must read approximately half a standard avatar tall: '..key)
    assert(size.X<=Config.ColumnSpacing*.88*Config.PlotScale+1e-6,'Wide producer exceeds bay clearance: '..key)
    assert(math.abs(frame.Position.Y-size.Y/2-position.Y*Config.PlotScale)<1e-7,'Feet must remain on the scaled shelf floor')
    assert(math.abs(model:GetScale()-Config.PlotScale)<1e-8,'Plot scale must apply exactly once')
    local template=(if species.modelKey then expansion else base):FindFirstChild(key)
    assert(template.Size==original and template.CFrame.Position.Y==-50,'Rendering must never resize or move imported templates')
    local miniKey=key..'_Mini'
    local miniInput=assert(inputs[miniKey],'Missing imported Mini '..miniKey)
    local mini=Factory.producer(holder,'mini-'..id,species,position,true)
    local miniScale=if species.modelKey then 1 else .42
    assert(math.abs(mini.PrimaryPart.Size.Y-miniInput.size.Y*miniScale)<1e-8,'Producer size must not alter Mini size: '..miniKey)
    minHeight=math.min(minHeight,size.Y);maxHeight=math.max(maxHeight,size.Y);maxWidth=math.max(maxWidth,size.X)
end
print(string.format('PASS all %d imported tiers through actual ModelFactory and WorldBuilder placement: %.3f-%.3f world studs high, max width %.3f; exact mesh mapping, feet and template preservation',Config.MaxTier,minHeight,maxHeight,maxWidth))
'@
$target=Join-Path $repo '.tools/producer-size-cli.luau'
[System.IO.File]::WriteAllText($target,$scriptText)
& (Join-Path $repo '.tools/luau/luau.exe') $target
exit $LASTEXITCODE
