--!strict
return table.freeze({
    PlotScale = 0.5,
    Origin = Vector3.new(0,0,52),
    Spawn = CFrame.new(0,4,18)*CFrame.Angles(0,math.pi,0),
    Sell = Vector3.new(27,0.15,-28),
    Claim = Vector3.new(35,0.15,-12),
    Merge = Vector3.new(0,0.15,30),
    Upgrade = Vector3.new(37,0.15,11),
    FinishNow = Vector3.new(37,0.15,23),
    PassPads = table.freeze({
        mini2=Vector3.new(13,.15,-28),cash2=Vector3.new(20,.15,-12),
        autoCollect=Vector3.new(-16,.15,43),autoSell=Vector3.new(-15,.15,5),
        cash4=Vector3.new(-35,.15,-15),cash8=Vector3.new(-35,.15,-27),
    }),
    GroundSize = Vector3.new(240,1,200),
    PlotSize = Vector3.new(112,0.18,112),
})
