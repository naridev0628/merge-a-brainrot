local Presentation=require('../src/shared/MultiplierCuePresentation')
local function snapshot(revision,value,serverNow,session)
    return {status='Ready',sessionKey=session or 'one',revision=revision,eventHundredths=value,serverNow=serverNow or revision}
end
local cue=Presentation.new(50,150)
assert(cue:receive(snapshot(1,100),500),'Accept the first world event baseline')
assert(cue:read(500)==nil,'Initial join must be quiet')
assert(cue:receive(snapshot(2,110),501))
local rise=assert(cue:read(501))
assert(rise.direction=='rise' and rise.hundredths==110 and rise.text=='Mini Multiplier rose to 1.1×!')
assert(rise.expiresAt==504,'Use client elapsed time, not the server clock epoch')
assert(not cue:receive(snapshot(2,110,20),502),'A replay must not renew the cue')
assert(cue:read(503).expiresAt==504)
assert(cue:receive(snapshot(3,110,21),503),'A newer same-value snapshot is valid')
assert(cue:read(503).expiresAt==504,'Unrelated farm updates must not renew the cue')
assert(cue:receive(snapshot(4,75,22),503.5))
local fall=assert(cue:read(503.5))
assert(fall.direction=='fall' and fall.text=='Mini Multiplier dropped to 0.75×!')
assert(fall~=rise and fall.expiresAt==506.5,'Rapid updates replace the single transient')
assert(not cue:receive(snapshot(3,150,23),504),'Old revisions must not reverse the cue')
assert(not cue:receive(snapshot(5,150,21),504),'Old server times must not reverse the cue')
assert(cue:read(506.49)==fall and cue:read(506.5)==nil,'The replacement expires at its own deadline')
assert(cue:receive(snapshot(5,100,24),507))
assert(cue:read(507).text=='Mini Multiplier rose to 1×!','Format whole multipliers without fake hundredths')
cue:clear()
assert(cue:read(507)==nil and not cue:receive(snapshot(5,100,24),508),'Clearing must retain replay protection')
assert(cue:receive(snapshot(6,120,25),508) and cue:read(508)==nil,'Resuming after unavailable must establish a quiet baseline')
assert(cue:receive(snapshot(1,50,0,'two'),509) and cue:read(509)==nil,'A new session starts quietly')
assert(cue:receive(snapshot(2,150,1,'two'),510) and cue:read(510).hundredths==150)
for _,bad in {49,151,100.5,0/0,math.huge,'110'} do
    assert(not cue:receive(snapshot(3,bad,2,'two'),511),'Reject invalid event multipliers')
end
assert(not cue:receive(snapshot(3,100,2,'two'),0/0))
assert(not cue:receive(snapshot(3,100,2,'two'),509),'Late local receipt times must not rewind the transient')
cue:destroy();cue:destroy()
assert(not cue:receive(snapshot(3,100,2,'two'),511) and cue:read(511)==nil,'Destroy is terminal and idempotent')

local function checkLayout(width,height,bag,obstacles,pickups)
    local rect=Presentation.layout(width,height,bag,obstacles,pickups)
    if not rect then return nil end
    assert(rect.x>=8 and rect.y>=8 and rect.x+rect.width<=width-8 and rect.y+rect.height<=height-8,'Cue must stay within the safe area')
    assert(not (rect.x<bag.x+bag.width and rect.x+rect.width>bag.x and rect.y<bag.y+bag.height and rect.y+rect.height>bag.y),'Do not cover the basket')
    for _,other in obstacles do
        assert(not (rect.x<other.x+other.width and rect.x+rect.width>other.x and rect.y<other.y+other.height and rect.y+rect.height>other.y),'Do not cover an existing UI region')
    end
    return rect
end
for _,size in {{320,480},{390,440},{360,568},{390,844},{640,280},{640,450},{1440,900}} do
    local w,h=size[1],size[2]
    local phone=w<600
    local bw=if phone then math.clamp(w-214,96,116) elseif h<500 then 116 else 172
    local bh=bw*.77
    local bag={x=if phone then w-12-bw else w*(if h<500 then .51 else .5)-bw/2,y=h-(if phone then 30 else 20)-bh,width=bw,height=bh}
    local plain=assert(checkLayout(w,h,bag,{},false),'A plain layout must have room for the cue')
    assert(math.abs(plain.y+plain.height-(bag.y-8))<.001,'Prefer the reference placement immediately above the basket')
    local withPickup=checkLayout(w,h,bag,{},true)
    if h==280 then
        assert(withPickup==nil,'Very short screens defer the larger cue while pickups occupy the available height')
        continue
    end
    assert(withPickup,'Pickup feedback must leave another placement '..w..'x'..h)
    local envelope={x=bag.x+bag.width/2-112,y=bag.y-160,width=224,height=168}
    assert(not (withPickup.x<envelope.x+envelope.width and withPickup.x+withPickup.width>envelope.x
        and withPickup.y<envelope.y+envelope.height and withPickup.y+withPickup.height>envelope.y),'Keep clear of the full pickup animation')
    checkLayout(w,h,bag,{{x=0,y=bag.y-100,width=w,height=80},{x=w-220,y=60,width=208,height=math.max(40,h-260)}},true)
end
assert(Presentation.layout(320,480,{x=202,y=355,width=106,height=89},{{x=0,y=0,width=320,height=480}},false)==nil,
    'A completely occupied HUD hides the cue instead of covering controls')
local overflow={}
for _=1,19 do table.insert(overflow,{x=0,y=0,width=1,height=1}) end
assert(Presentation.layout(320,480,{x=202,y=355,width=106,height=89},overflow,false)==nil,'Too many obstacle rectangles must fail closed')
print('PASS multiplier cue baseline/replay/replacement/expiry/destroy and bounded phone/short/desktop layouts')
