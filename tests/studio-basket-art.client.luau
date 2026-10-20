-- Private unparented basket; validates compact portraits without altering live HUD.
local art=require(game.Players.LocalPlayer.PlayerScripts.Controllers.BrickArt)
local parent=Instance.new('Frame')
art.basket(parent)
local count=0
for _,piece in parent:GetChildren() do
    if piece:IsA('ViewportFrame') then
        count+=1
        local p,s=piece.Position,piece.Size
        assert(p.X.Scale>=0 and p.Y.Scale>=0 and p.X.Scale+s.X.Scale<=1,
            'Basket portraits must stay within its horizontal and upper bounds')
        assert(p.Y.Scale+s.Y.Scale<=.53,'Brainrot faces must remain in the upper half of the basket')
        local model=assert(piece:FindFirstChildOfClass('WorldModel')):FindFirstChild('Portrait')
        local bounds,extent=model:GetBoundingBox()
        local camera=assert(piece.CurrentCamera)
        local focus=bounds.Position+Vector3.new(0,extent.Y*.23,0)
        assert((camera.CFrame.LookVector-(focus-camera.CFrame.Position).Unit).Magnitude<.001,
            'Basket camera must frame upper faces instead of entire tall bodies')
    end
end
assert(count==3,'Preserve the three actual Brainrot portraits')
assert(parent.WovenBody:FindFirstChildOfClass('UICorner').CornerRadius.Scale>=.35)
assert(parent:FindFirstChild('RimDepth') and parent.BasketRim:FindFirstChild('RimHighlight'))
assert(parent:FindFirstChild('CountInsetDepth'))
assert(parent.CountInset.Position==UDim2.fromScale(.16,.64)
    and parent.CountInset.Size==UDim2.fromScale(.68,.30),'Preserve the count label inset contract')
parent:Destroy()
return 'PASS compact three-face basket, rounded woven body, deep rim and unchanged count inset'
