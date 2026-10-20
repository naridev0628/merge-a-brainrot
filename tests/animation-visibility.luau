local Visibility=require('../src/shared/AnimationVisibility')
local Config=require('../src/shared/Config')
local bounds=Visibility.bounds(Config)
local function view(x,y,depth,radius,aspect)
    return {x=x,y=y,depth=depth,radius=radius or 0,tangent=math.tan(math.rad(35+Visibility.AngularPadding)),aspect=aspect or 16/9}
end
assert(Visibility.fullRate(nil) and Visibility.fullRate({}),'Camera-free/invalid fixtures must remain full rate')
assert(Visibility.fullRate(view(0,0,-49)),'Nearby farms must remain full rate even behind the camera')
assert(not Visibility.fullRate(view(0,0,-120)),'Distant farms behind the camera may throttle')
assert(Visibility.fullRate(view(0,0,179)) and not Visibility.fullRate(view(0,0,181)),'Visible distance must be bounded')
assert(Visibility.fullRate(view(0,0,180+bounds.radius,bounds.radius)),'Use nearest sphere distance, not just plot center')
assert(Visibility.fullRate(view(0,0,120,bounds.radius,.5)),'Portrait view must preserve a centered farm')
assert(not Visibility.fullRate(view(160,0,100,0,.5)),'Portrait horizontal frustum must be narrower')
local edge=view(100+10*math.sqrt(2),0,100,10,1)
assert(Visibility.fullRate(edge),'Sphere touching a padded frustum plane must stay full rate')
edge.x+=.01
assert(not Visibility.fullRate(edge),'A fully excluded distant sphere may throttle')
local invalid=view(0,0,0);invalid.depth=0/0
assert(Visibility.fullRate(invalid),'Invalid camera samples must fail open')
-- The bound covers both outside producers and the complete tray arc; all
-- quantities are world-space so the padding survives the plot transform.
for _,x in {-45,45} do for _,y in {0,Config.DisplayPlatformHeight+4*Config.RowHeight+10} do
    for _,z in {Config.TrayZ-8,Config.DisplayZ+8} do
        local dx,dy,dz=x*Config.PlotScale-bounds.x,y*Config.PlotScale-bounds.y,z*Config.PlotScale-bounds.z
        assert(dx*dx+dy*dy+dz*dz<bounds.radius^2,'Farm bound omitted an animation extreme')
    end
end end

local groups={}
local counts={0,0,0,0,0,0}
for index=1,6 do groups[index]=Visibility.new(index) end
local steadyPeak=0
for frame=0,600 do
    local active=0
    for index,state in groups do
        if Visibility.shouldUpdate(state,frame/60,index==1) then counts[index]+=1;active+=1 end
    end
    if frame>4 then steadyPeak=math.max(steadyPeak,active) end
end
assert(counts[1]==601,'A visible near farm must keep every frame')
local total=0
for index,count in counts do
    total+=count
    if index>1 then assert(count>=150 and count<=152,'Offscreen farms must run at bounded 15 Hz') end
end
assert(total<601*6*.4 and steadyPeak<=3,'Staggering should cut model updates and avoid six-farm bursts')
local reentry=Visibility.new(1)
assert(Visibility.shouldUpdate(reentry,10,false))
assert(not Visibility.shouldUpdate(reentry,10.001,false))
assert(Visibility.shouldUpdate(reentry,10.002,true),'Reentry must update immediately before the far deadline')
assert(Visibility.shouldUpdate(reentry,10.003,true),'Visible updates must remain unthrottled')
assert(Visibility.shouldUpdate(reentry,10.004,false))
assert(Visibility.shouldUpdate(reentry,100,false),'A long pause produces one catch-up sample')
assert(not Visibility.shouldUpdate(reentry,100.001,false),'Missed far frames must not queue hidden work')
assert(Visibility.shouldUpdate(reentry,1,false),'A reset clock must not strand a group behind a future deadline')
print(string.format('PASS padded farm visibility, portrait/frustum edges, near/far bounds, reentry and 15 Hz staggering: %d/%d group updates, steady peak %d/6',total,601*6,steadyPeak))
