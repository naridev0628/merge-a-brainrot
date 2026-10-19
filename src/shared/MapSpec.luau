--!strict
return table.freeze({
    PlotScale = 0.5,
    Origin = Vector3.new(0,0,52),
    Spawn = CFrame.new(0,4,18)*CFrame.Angles(0,math.pi,0),
    Sell = Vector3.new(27,0.15,12),
    Claim = Vector3.new(-24,0.15,13),
    Merge = Vector3.new(0,0.15,32),
    Upgrade = Vector3.new(-42,0.15,15),
    FinishNow = Vector3.new(-42,0.15,2),
    PassPads = table.freeze({
        mini2=Vector3.new(42,.15,-4),cash2=Vector3.new(-43,.15,-17),
        autoCollect=Vector3.new(-16,.15,35),autoSell=Vector3.new(-13,.15,-4),
        cash4=Vector3.new(-43,.15,-30),cash8=Vector3.new(-28,.15,-30),
    }),
    GroundSize = Vector3.new(240,1,200),
    PlotSize = Vector3.new(112,0.18,112),
})
