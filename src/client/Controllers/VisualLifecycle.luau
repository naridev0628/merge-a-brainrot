--!strict
-- Engine-independent ownership for one short visual. Loaders and timers return
-- cancellation functions; completion releases every resource exactly once.
local Lifecycle={}
Lifecycle.__index=Lifecycle
type Cancel=()->()
type Schedule=(number,()->())->Cancel
function Lifecycle.new(schedule: Schedule,onFinish: (string)->(),onError: ((any)->())?)
    return setmetatable({active=true,schedule=schedule,onFinish=onFinish,onError=onError,resources={},nextResource=0},Lifecycle)
end
function Lifecycle.alive(self: any): boolean
    return self.active==true
end
function Lifecycle.own(self: any,cleanup: Cancel): Cancel
    local retained=true
    self.nextResource+=1
    local id=self.nextResource
    local function release()
        if not retained then return end
        retained=false
        self.resources[id]=nil
        pcall(cleanup)
    end
    if self.active then self.resources[id]=release else release() end
    return release
end
function Lifecycle.finish(self: any,reason: string)
    if not self.active then return end
    self.active=false
    local resources=self.resources;self.resources={}
    for _,release in resources do release() end
    local onFinish=self.onFinish
    self.onFinish=nil
    if onFinish then
        local ok,err=pcall(onFinish,reason)
        if not ok and self.onError then pcall(self.onError,err) end
    end
end
function Lifecycle.run(self: any,callback: ()->())
    if not self.active then return end
    local ok,err=pcall(callback)
    if not ok then
        self:finish('error')
        if self.onError then pcall(self.onError,err) end
    end
end
function Lifecycle.after(self: any,seconds: number,callback: ()->())
    if not self.active then return end
    local release: Cancel?=nil
    local fired=false
    local pending=self.schedule(seconds,function()
        fired=true
        local stop=release
        if stop then stop() end
        self:run(callback)
    end)
    release=Lifecycle.own(self,pending)
    if fired then release() end
end
function Lifecycle.load(self: any,begin: ((boolean)->())->Cancel,seconds: number,callback: (boolean,string)->())
    if not self.active then return end
    local resolved=false
    local stopLoad: Cancel?=nil
    local stopTimeout: Cancel?=nil
    local function stop()
        local loader,timer=stopLoad,stopTimeout
        if loader then loader() end
        if timer then timer() end
    end
    local function settle(success: boolean,reason: string)
        if resolved or not self.active then return end
        resolved=true;stop()
        self:run(function() callback(success,reason) end)
    end
    self:own(function() resolved=true;stop() end)
    stopTimeout=Lifecycle.own(self,self.schedule(seconds,function() settle(false,'timeout') end))
    if resolved or not self.active then return end
    local ok,cancel=pcall(begin,function(success: boolean) settle(success,if success then 'loaded' else 'failed') end)
    if ok and type(cancel)=='function' then
        stopLoad=Lifecycle.own(self,cancel)
        if resolved then stopLoad() end
    elseif not ok then settle(false,'failed') end
end
return table.freeze(Lifecycle)
