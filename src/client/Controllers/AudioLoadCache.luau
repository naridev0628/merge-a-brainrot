--!strict
-- Engine-independent async cache: one attempt per asset for this client session.
local Cache={}
type Callback=(boolean)->()
type Entry={state: string,callbacks: {Callback}}
function Cache.new(load: (string,Callback)->(),schedule: (number,()->())->())
    local entries: {[string]: Entry}={}
    local function settle(entry: Entry,success: boolean)
        if entry.state~='loading' then return end
        entry.state=if success then 'ready' else 'failed'
        local callbacks=entry.callbacks
        entry.callbacks={}
        for _,callback in callbacks do pcall(callback,success) end
    end
    local function request(id: string,callback: Callback?)
        local entry=entries[id]
        if entry then
            if callback then
                if entry.state=='loading' then table.insert(entry.callbacks,callback)
                else pcall(callback,entry.state=='ready') end
            end
            return
        end
        local created: Entry={state='loading',callbacks={}}
        entries[id]=created
        if callback then table.insert(created.callbacks,callback) end
        local ok=pcall(load,id,function(success) settle(created,success) end)
        if not ok then settle(created,false) end
        if created.state=='loading' then schedule(12,function() settle(created,false) end) end
    end
    return {
        request=request,
        status=function(id: string): string? return if entries[id] then entries[id].state else nil end,
    }
end
return Cache
