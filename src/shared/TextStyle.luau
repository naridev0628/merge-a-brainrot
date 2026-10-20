--!strict
-- Shared rounded lettering for the HUD and physical farm signs.
local Style={}
Style.Font=Enum.Font.FredokaOne
Style.Ink=Color3.fromRGB(20,17,14)
Style.Cream=Color3.fromRGB(255,242,195)
Style.Price=Color3.fromRGB(115,255,36)
Style.Gold=Color3.fromRGB(255,211,46)
function Style.apply(label: any,size: number?,color: Color3?,thickness: number?)
    label.Font=Style.Font
    if size then label.TextSize=size end
    if color then label.TextColor3=color end
    label.TextStrokeTransparency=1
    local outline=label:FindFirstChild('TextOutline')
    if not outline then outline=Instance.new('UIStroke'); outline.Name='TextOutline'; outline.Parent=label end
    outline.ApplyStrokeMode=Enum.ApplyStrokeMode.Contextual
    outline.LineJoinMode=Enum.LineJoinMode.Round
    outline.Color=Style.Ink
    outline.Thickness=thickness or math.clamp(label.TextSize*.085,1.5,3.5)
    return label
end
return table.freeze(Style)
