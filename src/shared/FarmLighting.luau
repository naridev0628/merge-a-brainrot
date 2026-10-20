--!strict
local Lighting=game:GetService('Lighting')
local FarmLighting={}
function FarmLighting.apply()
    Lighting.ClockTime=14.4
    Lighting.GeographicLatitude=25
    Lighting.Brightness=2
    Lighting.GlobalShadows=true
    Lighting.ShadowSoftness=.5
    Lighting.Ambient=Color3.fromRGB(100,108,120)
    Lighting.OutdoorAmbient=Color3.fromRGB(132,140,149)
    Lighting.ColorShift_Top=Color3.fromRGB(0,0,0)
    Lighting.ColorShift_Bottom=Color3.fromRGB(0,0,0)
    Lighting.EnvironmentDiffuseScale=.55
    Lighting.EnvironmentSpecularScale=.2
    Lighting.ExposureCompensation=0
    local correction=Lighting:FindFirstChild('FarmColorGrade') :: ColorCorrectionEffect?
    if not correction then correction=Instance.new('ColorCorrectionEffect');correction.Name='FarmColorGrade';correction.Parent=Lighting end
    correction.Brightness=0;correction.Contrast=.025;correction.Saturation=0
    correction.TintColor=Color3.fromRGB(255,255,255);correction.Enabled=true
    local models=game:GetService('ReplicatedStorage'):FindFirstChild('MapModels')
    local legacyDome=workspace:FindFirstChild('FarmSkyDome')
    if legacyDome then legacyDome:Destroy() end
    local template=models and models:FindFirstChild('ReferenceSky')
    if template and template:IsA('Sky') then
        for _,existing in Lighting:GetChildren() do
            if existing:IsA('Sky') then existing:Destroy() end
        end
        local sky=template:Clone();sky.Name='FarmReferenceSky';sky.Parent=Lighting
    end
end
return table.freeze(FarmLighting)
