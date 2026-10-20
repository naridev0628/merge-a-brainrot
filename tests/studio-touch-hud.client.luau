-- Run in Studio Client with a touch device selected and normal Main/HUD active.
-- Read-only: no UI creation, property writes, input, camera changes or connections.
-- Repeat after each native device/orientation/state change; this samples the current layout only.
local Players=game:GetService('Players')
local Input=game:GetService('UserInputService')
local RunService=game:GetService('RunService')
local report={
    passed=false,failures={},hud={},controls={},movementHitRegions={},hitRegionOverlaps={},
    scope='Live native HUD/control rectangles; movement hit frames are diagnostic, not fullscreen exclusion zones. No touch activation or physical-device claim.',
}
local function check(condition,message)
    if not condition then table.insert(report.failures,message) end
end
local function visible(object)
    local current=object
    while current do
        if current:IsA('GuiObject') and not current.Visible then return false end
        if current:IsA('ScreenGui') and not current.Enabled then return false end
        current=current.Parent
    end
    return true
end
local function rectangle(object)
    local p,s=object.AbsolutePosition,object.AbsoluteSize
    return {x=p.X,y=p.Y,width=s.X,height=s.Y}
end
local function overlap(a,b)
    local width=math.min(a.x+a.width,b.x+b.width)-math.max(a.x,b.x)
    local height=math.min(a.y+a.height,b.y+b.height)-math.max(a.y,b.y)
    return width>0 and height>0,width,height
end
local function inside(a,b)
    return a.width>0 and a.height>0 and a.x>=b.x-1 and a.y>=b.y-1
        and a.x+a.width<=b.x+b.width+1 and a.y+a.height<=b.y+b.height+1
end
local function record(object)
    return {path=object:GetFullName(),className=object.ClassName,rect=rectangle(object),
        visible=object.Visible,effectiveVisible=visible(object),active=object.Active,
        anchor={object.AnchorPoint.X,object.AnchorPoint.Y},
        position={object.Position.X.Scale,object.Position.X.Offset,object.Position.Y.Scale,object.Position.Y.Offset},
        size={object.Size.X.Scale,object.Size.X.Offset,object.Size.Y.Scale,object.Size.Y.Offset}}
end
local ok,problem=xpcall(function()
    if not RunService:IsStudio() or not RunService:IsClient() then
        check(false,'Run this fixture in Studio Client');return
    end
    report.touchEnabled=Input.TouchEnabled
    if not Input.TouchEnabled then check(false,'Select a touch device before measuring');return end
    local player=Players.LocalPlayer
    if not player then check(false,'LocalPlayer is unavailable');return end
    local deadline=os.clock()+10
    local playerGui,hud,touch
    repeat
        playerGui=player:FindFirstChildOfClass('PlayerGui')
        hud=playerGui and playerGui:FindFirstChild('BrainrotHUD')
        touch=playerGui and playerGui:FindFirstChild('TouchGui')
        if hud and touch and hud:FindFirstChild('SafeArea') and touch:FindFirstChild('JumpButton',true)
            and touch:FindFirstChild('ThumbstickStart',true) then break end
        RunService.Heartbeat:Wait()
    until os.clock()>=deadline
    if not hud or not hud:IsA('ScreenGui') or not touch or not touch:IsA('ScreenGui') then
        check(false,'Normal BrainrotHUD and Roblox TouchGui must both exist within ten seconds');return
    end
    local safe=hud:FindFirstChild('SafeArea')
    if not safe or not safe:IsA('GuiObject') then check(false,'HUD SafeArea is missing');return end
    RunService.RenderStepped:Wait();RunService.RenderStepped:Wait()
    local camera=workspace.CurrentCamera
    if not camera then check(false,'CurrentCamera is unavailable');return end
    local viewport=camera.ViewportSize
    local screen={x=0,y=0,width=viewport.X,height=viewport.Y}
    report.viewport={viewport.X,viewport.Y};report.safeArea=rectangle(safe)
    report.hudEnabled=hud.Enabled;report.touchGuiEnabled=touch.Enabled
    check(hud.Enabled and visible(safe),'Normal HUD must be enabled and visible')
    check(touch.Enabled,'Roblox TouchGui must stay enabled')
    check(inside(report.safeArea,screen),'HUD SafeArea must be inside the current viewport')

    local controls={}
    for _,name in {'JumpButton','ThumbstickStart'} do
        local object=touch:FindFirstChild(name,true)
        if not object or not object:IsA('GuiObject') then
            check(false,'Missing Roblox touch control: '..name)
        else
            local entry=record(object);entry.name=name;table.insert(report.controls,entry)
            check(entry.effectiveVisible,'Roblox '..name..' must remain visible')
            check(inside(entry.rect,screen),'Roblox '..name..' must be onscreen with positive size')
            table.insert(controls,{object=object,parent=object.Parent,visible=object.Visible,active=object.Active,
                size=object.Size,position=object.Position,anchor=object.AnchorPoint,entry=entry})
        end
    end
    -- The native movement frame may intentionally cover much of the screen.
    -- Report it separately, including transparency and actual HUD intersections,
    -- rather than treating a transparent input parent as a visible joystick.
    for _,object in touch:GetDescendants() do
        if object:IsA('GuiObject') and (object.Name=='DynamicThumbstickFrame' or object.Name=='ThumbstickFrame'
            or object.Name=='TouchControlFrame') then
            local entry=record(object);entry.backgroundTransparency=object.BackgroundTransparency
            entry.fullViewport=entry.rect.width>=screen.width-1 and entry.rect.height>=screen.height-1
            table.insert(report.movementHitRegions,entry)
        end
    end

    local stats=safe:FindFirstChild('FarmStats')
    local cash=stats and stats:FindFirstChild('CashBar')
    local actions=safe:FindFirstChild('Actions')
    local overlay=safe:FindFirstChild('PanelOverlay')
    local panel=overlay and overlay:FindFirstChild('MergePanel')
    local lucky=panel and panel:FindFirstChild('LuckyViewport')
    local settings=panel and panel:FindFirstChild('SettingsViewport')
    if overlay and overlay:IsA('GuiObject') then
        report.panelOverlay=record(overlay)
        report.panelOverlay.backgroundTransparency=overlay.BackgroundTransparency
        report.panelOverlay.visibleContent=if lucky and visible(lucky) then 'LuckyViewport'
            elseif settings and visible(settings) then 'SettingsViewport' else 'OtherOrClosed'
        -- Identify Lucky from its actual visible viewport, not a localized title.
        -- Other menus may intentionally use a modal/dimmed overlay; record those.
        if lucky and visible(lucky) then
            check(not overlay.Active and overlay.BackgroundTransparency==1,
                'Visible Lucky card must keep its fullscreen overlay transparent and nonmodal')
        end
    else
        check(false,'Missing HUD PanelOverlay')
    end
    local items={
        {'CashBar',cash},{'CashAmount',cash and cash:FindFirstChild('Stats')},
        {'CashPlus',cash and cash:FindFirstChild('CashPlus')},
        {'CashMultiplier',cash and cash:FindFirstChild('CashMultiplier')},
        {'RebirthCount',stats and stats:FindFirstChild('RebirthCount')},
        {'MiniBag',safe:FindFirstChild('MiniBag')},{'TotalBrainrots',safe:FindFirstChild('TotalBrainrots')},
        {'Sprint',safe:FindFirstChild('Sprint')},{'Home',safe:FindFirstChild('Home')},
        {'Actions',actions},{'PadAction',safe:FindFirstChild('PadAction')},
        -- Measure the card and its visible controls, never the fullscreen overlay.
        {'PanelCard',panel},{'PanelClose',panel and panel:FindFirstChild('Close')},
        {'ProducersViewport',panel and panel:FindFirstChild('Producers')},
        {'LuckyViewport',lucky},{'SettingsViewport',settings},
    }
    for _,name in {'Merge','Index','Rebirth','Settings'} do
        table.insert(items,{name,safe:FindFirstChild(name) or (actions and actions:FindFirstChild(name))})
    end
    for _,item in items do
        local name,object=item[1],item[2]
        if not object or not object:IsA('GuiObject') then
            check(false,'Missing HUD element: '..name)
        else
            local entry=record(object);entry.name=name;table.insert(report.hud,entry)
            if object:IsA('ScrollingFrame') then
                entry.canvasPosition={object.CanvasPosition.X,object.CanvasPosition.Y}
                entry.absoluteCanvasSize={object.AbsoluteCanvasSize.X,object.AbsoluteCanvasSize.Y}
                entry.scrollingEnabled=object.ScrollingEnabled
            end
            if name=='Sprint' then check(entry.effectiveVisible,'Touch Sprint must remain visible') end
            if entry.effectiveVisible then
                check(inside(entry.rect,screen),name..' is outside the current viewport')
                check(inside(entry.rect,report.safeArea),name..' is outside the HUD safe area')
                for _,control in controls do
                    if control.entry.effectiveVisible then
                        local intersects,width,height=overlap(entry.rect,control.entry.rect)
                        check(not intersects,string.format('%s overlaps %s by %.2f x %.2f pixels',
                            name,control.entry.name,math.max(0,width),math.max(0,height)))
                    end
                end
                for _,region in report.movementHitRegions do
                    local intersects,width,height=overlap(entry.rect,region.rect)
                    if region.effectiveVisible and intersects then
                        table.insert(report.hitRegionOverlaps,{hud=name,region=region.path,
                            width=width,height=height,diagnosticOnly=true})
                    end
                end
            end
        end
    end
    RunService.RenderStepped:Wait()
    check(workspace.CurrentCamera==camera and camera.ViewportSize==viewport,
        'Viewport changed during measurement; rerun after orientation settles')
    check(touch.Parent==playerGui and touch.Enabled,'Roblox TouchGui changed or was disabled during measurement')
    local preserved=#controls==2 and touch.Parent==playerGui and touch.Enabled
    for _,control in controls do
        local object=control.object
        local unchanged=object.Parent==control.parent and object.Visible==control.visible and object.Active==control.active
            and object.Size==control.size and object.Position==control.position and object.AnchorPoint==control.anchor
        preserved=preserved and unchanged
        check(unchanged,
            control.entry.name..' changed during read-only measurement; rerun while controls are idle')
    end
    report.controlsPreserved=preserved
end,debug.traceback)
if not ok then table.insert(report.failures,'Fixture error: '..tostring(problem)) end
report.passed=#report.failures==0
return report
