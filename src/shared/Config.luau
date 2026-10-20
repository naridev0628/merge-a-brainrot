--!strict
return table.freeze({
    Interval = 1, Cadence = 0.25, BuyUnits = 20, StartingUnits = 20, CoinCap = 8000000000000000,
    Slots = 50, Columns = 10, ColumnSpacing = 10, RowHeight = 11, DisplayPlatformHeight = 1.8,
    GroundPerProducer = 8, GroundCap = 96, BagCap = 15000000000000,
    CatchupCap = 2, CollectDistance = 16, PickupRadius = 12/.65, PadDistance = 10,
    MaxTier = 25, MergeCount = 3, RebirthTier = 6, BuyMaxTier = 6, RequestCap = 10000, PlotCount = 6, PlotScale = .65,
    BuyPads = table.freeze({["1"]=44,["5"]=22,["10"]=-22,["100"]=-44}),
    BuyUnlocks = table.freeze({["1"]=0,["5"]=0,["10"]=0,["100"]=1}),
    BuyZ = 67.5, SellX = -17, SellZ = -28, ClaimX = -43, ClaimZ = -28, DisplayZ = 88,
    TransitSeconds = 4, BeltZ = 77, TrayZ = 67,
    Tray = table.freeze({Width=24,Depth=16,Columns=8,Rows=4,SpacingX=2.75,SpacingZ=3.25,BaseY=1.3,LayerHeight=2}),
    AutoCollectZ = 52,
    PlotRearStartZ = 44, PlotBackZ = 96,
    SaleSeconds = 0.5, SaleCapacity = 37500000000000,
    ProcessorRates = table.freeze({2,5,10,18,31,52,90,150,250,420,700,1200,2000,3400,5700,9600,16000,27000,45000,76000,128000,216000,360000,600000,1000000,1700000,2900000,4900000,8300000,14000000,24000000,42000000,70000000,120000000,200000000,340000000,570000000,960000000,1600000000,2700000000,4500000000,7600000000,13000000000,22000000000,37000000000,63000000000,110000000000,190000000000,320000000000,540000000000,920000000000,1600000000000,2700000000000,4500000000000,7600000000000,13000000000000,22000000000000,37000000000000}),
    -- Prices use quarter-dollar units: 5–12 seconds of the current rate at $1/Mini.
    -- Cap at 12 seconds so late upgrades do not grow into multi-minute stalls.
    ProcessorCosts = table.freeze({40,120,280,576,1116,2080,3960,7200,12000,20160,33600,57600,96000,163200,273600,460800,768000,1296000,2160000,3648000,6144000,10368000,17280000,28800000,48000000,81600000,139200000,235200000,398400000,672000000,1152000000,2016000000,3360000000,5760000000,9600000000,16320000000,27360000000,46080000000,76800000000,129600000000,216000000000,364800000000,624000000000,1056000000000,1776000000000,3024000000000,5280000000000,9120000000000,15360000000000,25920000000000,44160000000000,76800000000000,129600000000000,216000000000000,364800000000000,624000000000000,1056000000000000}), UpgradeX = -37, UpgradeZ = 11, MergeX = 0, MergeZ = 52,
    LuckyChance = .01, LuckyBaseUnits = 160, LuckyPerProducerUnits = 40, LuckyX = 0, LuckyZ = 65, LuckyPickupRadius = 6/.65,
    RebirthBase = 100000, RebirthStep = 100000, MaxRebirths = 20,
    OriginX = 0, OriginZ = 52, MemoryOnly = true,
})
