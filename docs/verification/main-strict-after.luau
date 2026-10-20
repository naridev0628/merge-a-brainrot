--!strict
local Core=require('../../src/server/Domain/FarmCore')
local Config=require('../../src/shared/Config')
local Catalog=require('../../src/shared/CreatureCatalog')
local core=Core.new(Config,Catalog)
local session=core:newSession(1,0,'strict-probe')
local function render(_state: Core.State) end
local stateToRender=session.state
local ok,err=pcall(function()
    render(stateToRender)
    return nil
end)
if not ok then print(tostring(err)) end
if session.state.lucky and session.state.lucky.held then
    local state=core:snapshot(session);local lucky=state.lucky;if lucky then lucky.held=false;core:commit(session,state) end
end
if session.state.lucky and session.state.lucky.held then
    local dropped=core:snapshot(session);local lucky=dropped.lucky;if lucky then lucky.held=false;core:commit(session,dropped) end
end
local domainResult: Core.Result={code='OK'}
local response=table.clone(domainResult) :: Core.Result & {requestId: string?,action: string?}
response.requestId='probe'
response.action='Buy'
print(response.code)