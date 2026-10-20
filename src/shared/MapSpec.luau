--!strict
local Config=require(script.Parent.Config)
return table.freeze({
    PlotScale = Config.PlotScale,
    Origin = Vector3.new(0,0,52),
    Spawn = CFrame.new(0,4,18)*CFrame.Angles(0,math.pi,0),
    Sell = Vector3.new(Config.SellX,0.15,Config.SellZ),
    DepositHalfSize = Vector2.new(9,5),
    Claim = Vector3.new(Config.ClaimX,0.15,Config.ClaimZ),
    Merge = Vector3.new(Config.MergeX,0.15,Config.MergeZ),
    Upgrade = Vector3.new(Config.UpgradeX,0.15,Config.UpgradeZ),
    FinishNow = Vector3.new(-37,0.15,23),
    FarmerCenter = Vector3.new(Config.SellX,0,-43),
    FarmerAlcoveCenter = Vector3.new(Config.SellX,-.5,-45),
    FarmerAlcoveSize = Vector3.new(24,1,14),
    PassPads = table.freeze({
        mini2=Vector3.new(-13,.15,-28),cash2=Vector3.new(-20,.15,-12),
        autoCollect=Vector3.new(0,.15,Config.AutoCollectZ),autoSell=Vector3.new(15,.15,5),
        cash4=Vector3.new(35,.15,-15),cash8=Vector3.new(35,.15,-27),
    }),
    GroundSize = Vector3.new(240,1,200),
    PlotSize = Vector3.new(112,0.18,Config.PlotBackZ+38),
})
