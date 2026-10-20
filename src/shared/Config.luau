--!strict
return table.freeze({
    Interval = 1, Cadence = 0.25, BuyUnits = 20, StartingUnits = 20, CoinCap = 4000000000000,
    Slots = 50, Columns = 10, ColumnSpacing = 6.5, RowHeight = 11, DisplayPlatformHeight = 1.8,
    GroundPerProducer = 8, GroundCap = 50, BagCap = 2147483647,
    CatchupCap = 2, CollectDistance = 16, PickupRadius = 12/.65, PadDistance = 10,
    MaxTier = 6, RequestCap = 10000, PlotCount = 6, PlotScale = .65,
    BuyPads = table.freeze({["1"]=44,["5"]=18,["10"]=-18,["50"]=-44}),
    BuyUnlocks = table.freeze({["1"]=0,["5"]=0,["10"]=0,["50"]=1}),
    BuyZ = 56, SellX = -27, SellZ = -28, ClaimX = -35, ClaimZ = -12, DisplayZ = 88,
    TransitSeconds = 4, BeltZ = 77, TrayZ = 67,
    PlotRearStartZ = 44, PlotBackZ = 96,
    SaleSeconds = 0.5, SaleCapacity = 2147483647,
    ProcessorRates = table.freeze({2,5,10,18,31,52}),
    ProcessorCosts = table.freeze({40,120,360,1000,3000}), UpgradeX = -37, UpgradeZ = 11, MergeX = 0, MergeZ = 40,
    LuckyChance = .01, LuckyBaseUnits = 160, LuckyPerProducerUnits = 40, LuckyX = 0, LuckyZ = 67, LuckyPickupRadius = 6/.65,
    RebirthBase = 100000, RebirthStep = 100000, MaxRebirths = 20,
    OriginX = 0, OriginZ = 52, MemoryOnly = true,
})
