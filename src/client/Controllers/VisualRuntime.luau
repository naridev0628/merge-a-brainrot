--!strict
local Lifecycle=require(script.Parent:WaitForChild('VisualLifecycle'))
local ContentProvider=game:GetService('ContentProvider')
local TweenService=game:GetService('TweenService')
local Runtime={LoadTimeout=3}
local function cancel(thread: thread)
    if coroutine.running()~=thread and coroutine.status(thread)~='dead' then pcall(task.cancel,thread) end
end
local function schedule(seconds: number,callback: ()->()): ()->()
    local pending=task.delay(seconds,callback)
    return function() cancel(pending) end
end
function Runtime.watch(scope: any,instance: Instance)
    local destroyed=instance.Destroying:Connect(function() scope:finish('cancelled') end)
    local removed=instance.AncestryChanged:Connect(function()
        if not instance.Parent then scope:finish('cancelled') end
    end)
    scope:own(function() destroyed:Disconnect();removed:Disconnect() end)
    if not instance.Parent then scope:finish('cancelled') end
end
function Runtime.new(gui: ScreenGui,onFinish: (string)->()): any
    local scope=Lifecycle.new(schedule,onFinish,function(err) warn('Reveal visual: '..tostring(err)) end)
    Runtime.watch(scope,gui)
    return scope
end
function Runtime.load(scope: any,assets: {Instance},callback: (boolean)->(),timeout: number?)
    scope:load(function(done)
        local worker=task.defer(function()
            local failed=false
            local ok=pcall(function()
                ContentProvider:PreloadAsync(assets,function(_,status)
                    if status~=Enum.AssetFetchStatus.Success then failed=true end
                end)
            end)
            done(ok and not failed)
        end)
        -- Engine fetching may finish later, but no suspended visual coroutine
        -- or late callback may keep its UI/animation lock alive.
        return function() cancel(worker) end
    end,timeout or Runtime.LoadTimeout,function(success) callback(success) end)
end
function Runtime.tween(scope: any,instance: Instance,info: TweenInfo,properties: any)
    if not scope:alive() then return end
    local tween=TweenService:Create(instance,info,properties)
    scope:own(function() tween:Cancel() end)
    tween:Play()
end
return table.freeze(Runtime)
