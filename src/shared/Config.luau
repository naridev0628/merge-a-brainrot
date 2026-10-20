--!strict
return table.freeze({
    Interval = 1, Cadence = 0.25, BuyUnits = 20, StartingUnits = 20, CoinCap = 4000000000000,
    Slots = 100, Columns = 10, ColumnSpacing = 6.5, RowHeight = 11,
    GroundPerProducer = 8, GroundCap = 96, BagCap = 2147483647,
    CatchupCap = 2, CollectDistance = 16, PickupRadius = 24, PadDistance = 10,
    MaxTier = 6, RequestCap = 10000, PlotCount = 6,
    BuyPads = table.freeze({["1"]=39,["5"]=16,["10"]=-16,["100"]=-39}),
    BuyUnlocks = table.freeze({["1"]=0,["5"]=0,["10"]=0,["100"]=1}),
    BuyZ = 38, SellX = 27, SellZ = -28, ClaimX = 35, ClaimZ = -12, DisplayZ = 66,
    TransitSeconds = 4, BeltZ = 55, TrayZ = 45,
    SaleSeconds = 0.5, SaleCapacity = 2147483647,
    ProcessorRates = table.freeze({2,5,10,18,31,52}),
    ProcessorCosts = table.freeze({40,120,360,1000,3000}), UpgradeX = 37, UpgradeZ = 11, MergeX = 0, MergeZ = 27,
    LuckyChance = .01, LuckyBaseUnits = 160, LuckyPerProducerUnits = 40,
    RebirthBase = 100000, RebirthStep = 100000, MaxRebirths = 20,
    OriginX = 0, OriginZ = 52, MemoryOnly = true,
})
