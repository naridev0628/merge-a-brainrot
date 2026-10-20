--!strict
-- A small visual backlog, coalesced by species while queued or showing.
local Queue={}
Queue.__index=Queue
function Queue.new(limit: number)
    assert(limit>=1 and limit%1==0)
    return setmetatable({limit=limit,items={},present={}},Queue)
end
function Queue.push(self: any,key: string): boolean
    if self.present[key] or #self.items>=self.limit then return false end
    self.present[key]=true;table.insert(self.items,key)
    return true
end
function Queue.take(self: any): string?
    return table.remove(self.items,1)
end
function Queue.complete(self: any,key: string)
    self.present[key]=nil
end
function Queue.clear(self: any)
    table.clear(self.items);table.clear(self.present)
end
return table.freeze(Queue)
