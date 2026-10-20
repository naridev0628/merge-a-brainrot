--!strict
local Core=require('../../src/server/Domain/FarmCore')
local Config=require('../../src/shared/Config')
local Catalog=require('../../src/shared/CreatureCatalog')
local core=Core.new(Config,Catalog)
local session=core:newSession(1,0,'strict-probe')
local function render(_state: Core.State) end
local ok,err=pcall(render,session.state)
if not ok then print(tostring(err)) end
if session.state.lucky and session.state.lucky.held then
    local state=core:snapshot(session);state.lucky.held=false;core:commit(session,state)
end
if session.state.lucky and session.state.lucky.held then
    local dropped=core:snapshot(session);dropped.lucky.held=false;core:commit(session,dropped)
end
local response: Core.Result={code='OK'}
response.requestId='probe'
response.action='Buy'
print(response.code)