--!strict
return table.freeze({
    Interval = 6, Cadence = 0.25, BuyUnits = 20, StartingUnits = 20, CoinCap = 4000000000000,
    Slots = 100, Columns = 10, ColumnSpacing = 6.5, RowHeight = 7,
    GroundPerProducer = 8, GroundCap = 96, BagCap = 96,
    CatchupCap = 2, CollectDistance = 8, PadDistance = 10,
    MaxTier = 6, RequestCap = 10000, PlotCount = 6,
    BuyPads = table.freeze({["1"]=36,["5"]=12,["10"]=-12,["100"]=-36}),
    BuyUnlocks = table.freeze({["1"]=0,["5"]=1,["10"]=2,["100"]=3}),
    BuyZ = 34, SellX = 27, SellZ = 12, ClaimX = -24, ClaimZ = 13, DisplayZ = 66,
    TransitSeconds = 4, BeltZ = 55, TrayZ = 45,
    SaleSeconds = 0.5, SaleCapacity = 96,
    ProcessorRates = table.freeze({2,5,10,18,31,52}),
    ProcessorCosts = table.freeze({400,1000,2000,4000,10000}), UpgradeX = -42, UpgradeZ = 15,
    LuckyChance = .001, LuckyBaseUnits = 160, LuckyPerProducerUnits = 40,
    RebirthBase = 4000000, RebirthStep = 2000000, MaxRebirths = 20,
    OriginX = 0, OriginZ = 52, MemoryOnly = true,
})
