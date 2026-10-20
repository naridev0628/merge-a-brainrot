--!strict
-- Presentation adaptation: starter drops use baseTier 2. Reward tiers, prices
-- and probabilities remain authoritative in FarmCore and LuckyPanel.
local function rgb(r: number,g: number,b: number): {number}
    return table.freeze({r,g,b})
end
local basic=table.freeze({
    key='basic',title='Basic',body=rgb(255,193,0),cardTop=rgb(255,255,90),cardBottom=rgb(255,158,20),
    titleColor=rgb(255,231,116),rewards=rgb(102,57,3),costStripe=rgb(75,90,13),mark=rgb(255,255,255),
})
local upgraded=table.freeze({
    key='upgraded',title='Upgraded',body=rgb(38,155,255),cardTop=rgb(166,244,255),cardBottom=rgb(38,109,245),
    titleColor=rgb(220,250,255),rewards=rgb(12,52,104),costStripe=rgb(18,67,99),mark=rgb(255,255,255),
})
local Appearance={}
function Appearance.forTier(baseTier: number?)
    if baseTier and baseTier%1==0 and baseTier>=3 and baseTier<math.huge then return upgraded end
    return basic
end
return table.freeze(Appearance)
