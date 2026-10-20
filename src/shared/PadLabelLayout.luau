--!strict
local Layout={}
local function rectangle(item: any,scale: number): any
    local w,h=item.width*scale,item.height*scale
    return {x=item.x-w/2,y=item.y-h/2,width=w,height=h}
end
local function separate(a: any,b: any,gap: number): boolean
    return a.x+a.width+gap<=b.x or b.x+b.width+gap<=a.x
        or a.y+a.height+gap<=b.y or b.y+b.height+gap<=a.y
end
function Layout.solve(items: {any},previous: {[string]: boolean}): {[string]: any}
    local output,ordered={},table.clone(items)
    for _,item in items do
        output[item.key]={visible=false,scale=1}
    end
    table.sort(ordered,function(a: any,b: any)
        if a.near~=b.near then return a.near end
        if a.priority~=b.priority then return a.priority<b.priority end
        return a.key<b.key
    end)
    local admitted={}
    local function fits(rect: any,key: string,gap: number): boolean
        for _,other in admitted do
            if other.key~=key and not separate(rect,output[other.key].rect,gap) then return false end
        end
        return true
    end
    -- Reserve the readable minimum first, so an earlier large label cannot
    -- hide another label when both could fit at a smaller readable size.
    for _,item in ordered do
        local minimum=if item.near then 1 else .58
        local rect=rectangle(item,minimum)
        if fits(rect,item.key,if previous[item.key]==false then 12 else 4) then
            output[item.key]={visible=true,scale=minimum,rect=rect}
            table.insert(admitted,item)
        end
    end
    for _,item in admitted do
        local low=output[item.key].scale
        local high=if item.near then 1 else math.clamp(24/math.max(item.distance,1),.58,1)
        for _=1,8 do
            local midpoint=(low+high)/2
            if fits(rectangle(item,midpoint),item.key,4) then low=midpoint else high=midpoint end
        end
        local scale=math.max(output[item.key].scale,math.floor(low*1000)/1000)
        if fits(rectangle(item,high),item.key,4) then scale=high end
        output[item.key]={visible=true,scale=scale,rect=rectangle(item,scale)}
    end
    return output
end
return table.freeze(Layout)
