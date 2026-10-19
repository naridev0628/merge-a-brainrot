--!strict
local Input=game:GetService('UserInputService')
local Players=game:GetService('Players')
local Sprint={}
function Sprint.start(command: RemoteEvent,gui: ScreenGui)
    local active=false
    local held: {[Enum.KeyCode]: boolean}={}
    local button=Instance.new('TextButton');button.Name='Sprint';button.Text='Sprint';button.Size=UDim2.fromOffset(82,44);button.AnchorPoint=Vector2.new(1,1);button.Position=UDim2.new(1,-110,1,-168);button.BackgroundColor3=Color3.fromRGB(75,178,238);button.TextColor3=Color3.new(1,1,1);button.Font=Enum.Font.FredokaOne;button.TextSize=18;button.TextStrokeTransparency=0;button.Visible=Input.TouchEnabled;button.Parent=gui
    local corner=Instance.new('UICorner');corner.CornerRadius=UDim.new(0,8);corner.Parent=button
    local border=Instance.new('UIStroke');border.Thickness=3;border.Color=Color3.fromRGB(23,34,44);border.Parent=button
    local safe=gui:WaitForChild('SafeArea') :: Frame
    button.Parent=safe
    local function resize()
        local portrait=safe.AbsoluteSize.X<600
        button.AnchorPoint=if portrait then Vector2.new(0,1) else Vector2.new(1,1)
        button.Position=if portrait then UDim2.new(0,12,1,-250) else UDim2.new(1,-140,1,-66)
    end
    safe:GetPropertyChangedSignal('AbsoluteSize'):Connect(resize);resize()
    Input:GetPropertyChangedSignal('TouchEnabled'):Connect(function()button.Visible=Input.TouchEnabled end)
    local function set(value: boolean)
        if active==value then return end
        active=value;button.Text=if value then 'Sprint ON' else 'Sprint';button.BackgroundColor3=if value then Color3.fromRGB(95,222,53) else Color3.fromRGB(75,178,238)
        command:FireServer('Sprint',{value})
    end
    button.Activated:Connect(function()set(not active)end)
    Input.InputBegan:Connect(function(key,processed)if not processed and (key.KeyCode==Enum.KeyCode.LeftShift or key.KeyCode==Enum.KeyCode.RightShift) then held[key.KeyCode]=true;set(true)end end)
    Input.InputEnded:Connect(function(key)if key.KeyCode==Enum.KeyCode.LeftShift or key.KeyCode==Enum.KeyCode.RightShift then held[key.KeyCode]=nil;set(next(held)~=nil)end end)
    Input.WindowFocusReleased:Connect(function()table.clear(held);set(false)end)
    Players.LocalPlayer.CharacterAdded:Connect(function()table.clear(held);active=false;button.Text='Sprint';button.BackgroundColor3=Color3.fromRGB(75,178,238)end)
end
return Sprint
