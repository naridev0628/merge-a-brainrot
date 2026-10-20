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
type Tone={at: number,pitch: number,length: number,gain: number?,asset: string?}
type Pattern={asset: string,cooldown: number,volume: number,notes: {Tone},priority: number,group: string?}
local patterns: {[string]: Pattern}={
    Pickup={asset='Coin',cooldown=.12,volume=.12,priority=1,notes={{at=0,pitch=1.24,length=.18}}},
    Buy={asset='Purchase',cooldown=.35,volume=.15,priority=2,notes={{at=0,pitch=1.16,length=.28}}},
    Upgrade={asset='Select',cooldown=.45,volume=.15,priority=2,
        notes={{at=0,pitch=1.08,length=.23},{at=.15,pitch=1.36,length=.28,gain=.82}}},
    Deposit={asset='Bubble',cooldown=.60,volume=.14,priority=2,notes={{at=0,pitch=1.12,length=.29}}},
    Claim={asset='Coin',cooldown=.35,volume=.17,priority=3,
        notes={{at=0,pitch=1.12,length=.23},{at=1.05,pitch=1.42,length=.20,gain=.55,asset='Select'}}},
    Merge={asset='Aura',cooldown=.65,volume=.11,priority=2,group='Merge',
        notes={{at=0,pitch=1.30,length=.50},{at=.18,pitch=1.32,length=.23,gain=.55,asset='Select'}}},
    AutoMerge={asset='Aura',cooldown=.65,volume=.11,priority=2,group='Merge',
        notes={{at=0,pitch=1.30,length=.50},{at=.18,pitch=1.32,length=.23,gain=.55,asset='Select'}}},
    PickupLucky={asset='Notification',cooldown=.35,volume=.13,priority=2,notes={{at=0,pitch=1.22,length=.34}}},
    OpenLucky={asset='Notification',cooldown=.80,volume=.16,priority=3,
        notes={{at=0,pitch=1.05,length=.36},{at=.20,pitch=1.35,length=.32,gain=.75}}},
    Rebirth={asset='Aura',cooldown=1.50,volume=.15,priority=3,
        notes={{at=0,pitch=1.15,length=.62},{at=.28,pitch=1.40,length=.30,gain=.70,asset='Select'}}},
}
for _,pattern in patterns do
    for _,tone in pattern.notes do table.freeze(tone) end
    table.freeze(pattern.notes);table.freeze(pattern)
end
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
