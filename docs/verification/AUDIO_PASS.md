# Farm audio pass — 2026-10-20

The client uses one quiet looping soundtrack and three reusable effect voices. Music and effects route through the independent `Preferences` SoundGroups. `MusicController.start()` is idempotent; `stop()` retains its one voice and `destroy()` releases it. `FeedbackAudio` preserves the existing require-to-initialize and `play(action)` interface, and now also exposes `start()` and `destroy()`.

## Sources

These exact assets were returned by Studio's Creator Store audio search as free. The creator names below are the returned metadata, not inferred from an asset title. The store tool did not return a separate license document. No audio was extracted from the Chicken Farm reference video, downloaded, uploaded or republished.

| Use | Asset and Creator Store page | Returned creator | Loaded duration |
|---|---|---|---:|
| Soundtrack | [Playful Promenade — 9047837288](https://create.roblox.com/store/asset/9047837288) | APMOfficial | 144.222 s |
| Pickup, cash claim and fallback | [Coin Collect — 135483737426662](https://create.roblox.com/store/asset/135483737426662) | G00byBBQSauce, existing project attribution | 0.874 s |
| Purchase | [Roblox GUI - Purchase — 17208380755](https://create.roblox.com/store/asset/17208380755) | Roblox | 0.874 s |
| Upgrade | [Roblox GUI - Select — 17208396156](https://create.roblox.com/store/asset/17208396156) | Roblox | 0.527 s |
| Deposit | [Roblox GUI - Bubble — 17208204604](https://create.roblox.com/store/asset/17208204604) | Roblox | 0.549 s |
| Lucky pickup/open | [Roblox GUI - Notification High — 17208361335](https://create.roblox.com/store/asset/17208361335) | Roblox | 1.518 s |
| Merge, automatic merge and rebirth | [Roblox GUI - Aura — 17208327798](https://create.roblox.com/store/asset/17208327798) | Roblox | 2.172 s |

The soundtrack's store description identifies a carefree, cheerful orchestral piece with bassoon and acoustic guitar, from the Kaptain library's *Cartoons & Comedy Tunes*, courtesy of APM Music. The complete track repeats with Roblox's `Looped` playback. A seamless edited loop or subjective listening comparison is not claimed. Base volume is 0.18, multiplied by the music preference (default 0.35, effective 0.063), with a 1.5-second entrance fade.

## Loading and resource limits

- Every configured asset gets at most one preload attempt in a client session. Concurrent requests share the same result.
- Failed or stalled loads become terminal failures after at most 12 seconds. No retry loop or application warning spam is used. Unavailable effect variants fall back to the existing Coin Collect cue if it loaded; unavailable music stays silent.
- Preload uses a silent, unparented Sound holder to provide the audio content type. A Studio probe found that bare-ID string preloads could return `Failure` for an audio asset whose Sound preload returned `Success`. Each holder is destroyed on completion or after 12 seconds and is never played.
- Effect playback has per-action cooldowns and a global 65 ms note interval. Delayed notes are invalidated on destruction, so they cannot play on replacement voices.
- Music has no frame loop or playlist allocations. Stop/destroy cancels its fade and prevents a pending preload completion from restarting it.

## Verification

In Studio client `ef89b65f-2f6a-4fe7-8272-bae9e8007fd1`, all seven selected assets returned `AssetFetchStatus.Success`; parented load probes reported `IsLoaded=true` and the durations above. All temporary probes were removed.

`tests/audio-load-cache.luau` failed first against an empty implementation, then passed checks for duplicate consumers, cached success and failure, 100 denied-asset requests without retries, stalled loads, ignored late success, and provider exceptions.

`tests/studio-audio-lifecycle.client.luau` passed using the production module sources in an isolated temporary SoundService folder with muted test groups. It checked actual asset loading and playback advancement, five distinct action palettes, cooldowns, a burst of 300 action calls with only three effect voices, one looping music voice, independent group assignment, quiet fade target, stop/start reuse, destruction and delayed-note invalidation. The temporary folder, groups and voices were removed without changing the live game voices, HUD or camera.

All five new/changed audio modules and both Studio audio fixtures compiled with the local Luau CLI. After synchronization and a fresh Play session, both audio fixtures passed again against the live controllers and real Preferences SoundGroups. Playback was validated programmatically; human listening and published-place permissions remain separate checks.

## Integration

After Controllers are available in `Main.client.luau`:

```luau
local MusicController=require(Controllers:WaitForChild('MusicController'))
MusicController.start()
```

Keep the existing `FeedbackAudio.play(response.action)` call. The settings agent owns `Preferences`; both controllers use its `getSoundGroup('sfx'|'music')` API. Run `tests/studio-audio.client.luau` and `tests/studio-audio-lifecycle.client.luau` after synchronization to check the integrated client.

No plugin was changed or removed. The older console asset `203785492` is absent from the source and was not made part of this palette.
