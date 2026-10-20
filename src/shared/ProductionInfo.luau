--!strict
-- Keep expected production and the value of each Mini separate in player UI.
local Info={}
function Info.rate(config: any,state: any): number
    return (state.miniMultiplier or 1)*((state.eventHundredths or 100)+(state.obbyBonusHundredths or 0))/100/config.Interval
end
function Info.saleUnits(baseValue: number,state: any): number
    return baseValue*(4+(state.rebirths or 0))*(state.cashMultiplier or 1)
end
return table.freeze(Info)
