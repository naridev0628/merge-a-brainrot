--!strict
-- Creator Store sources and live loading evidence: docs/verification/AUDIO_PASS.md.
local assets: {[string]: string}={
    Coin='rbxassetid://135483737426662', -- Coin Collect, G00byBBQSauce (existing cue).
    Purchase='rbxassetid://17208380755', -- Roblox GUI - Purchase, Roblox.
    Select='rbxassetid://17208396156', -- Roblox GUI - Select, Roblox.
    Bubble='rbxassetid://17208204604', -- Roblox GUI - Bubble, Roblox.
    Notification='rbxassetid://17208361335', -- Roblox GUI - Notification High, Roblox.
    Aura='rbxassetid://17208327798', -- Roblox GUI - Aura, Roblox.
}
type Pattern={asset: string,cooldown: number,volume: number,notes: {number}}
local patterns: {[string]: Pattern}={
    Pickup={asset='Coin',cooldown=.10,volume=.17,notes={1.16}},
    Buy={asset='Purchase',cooldown=.35,volume=.18,notes={1.00}},
    Upgrade={asset='Select',cooldown=.40,volume=.19,notes={1.02,1.30}},
    Deposit={asset='Bubble',cooldown=.60,volume=.19,notes={.88,1.08}},
    Claim={asset='Coin',cooldown=.35,volume=.21,notes={1.03,1.27}},
    Merge={asset='Aura',cooldown=.65,volume=.14,notes={1.12}},
    AutoMerge={asset='Aura',cooldown=.65,volume=.14,notes={1.12}},
    PickupLucky={asset='Notification',cooldown=.35,volume=.15,notes={1.18}},
    OpenLucky={asset='Notification',cooldown=.80,volume=.18,notes={.94,1.24}},
    Rebirth={asset='Aura',cooldown=1.50,volume=.18,notes={.95,1.25}},
}
for _,pattern in patterns do table.freeze(pattern.notes);table.freeze(pattern) end
return table.freeze({
    Assets=table.freeze(assets),
    Patterns=table.freeze(patterns),
    VoiceCount=3,
    Music=table.freeze({
        Id='rbxassetid://9047837288', -- Playful Promenade, APMOfficial.
        Volume=.18, -- Multiplied by the independent music preference (default .35).
        FadeSeconds=1.5,
    }),
})
