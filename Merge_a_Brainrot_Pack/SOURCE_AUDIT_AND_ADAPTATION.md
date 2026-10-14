# Source audit and adaptation

Inspection date: 2026-10-14. Local inputs were found in the user's Downloads folder. No original file was modified. No archive program was executed and no proprietary model was extracted or imported.

## What was inspected

| Input | Actual contents | Review performed |
|---|---|---|
| `STEAL_AN_EGG_ONE_SHOT_PROMPT.md` | 193,194 bytes; 1,768 lines; mission, 26 numbered sections and extensive data appendices | Complete heading index and targeted mission, architecture, map, core-loop, fusion, UI, data/security, art, reference-index, conflict and checklist sections |
| `research.zip` | 1,776 files + 26 directories; 85,818,966 uncompressed bytes | Complete member inventory, every member read for hash/CRC, six main reports and selected generated/raw text/data reviewed |
| `reference.zip` | 255 files + 10 directories; 85,412,912 uncompressed bytes | Complete member inventory, every member read for hash/CRC, eight representative raster images visually reviewed; four videos inventoried but not played |

The reference archive has 127 PNG, 62 WebP, 61 JPG, four MP4 and one AVIF. It contains no embedded license/source text manifest, Studio model, place, mesh-source file or game scripts. Both archives have no `.rbxm`, `.rbxmx`, `.rbxl`, `.rbxlx`, `.fbx`, `.obj` or `.glb` members. This is a statement about these filenames and formats, not a license determination.

All member reads passed ZIP CRC validation. Input and per-member SHA-256 hashes, sizes, counts, duplicate-content counts and unsafe-path checks are recorded in the inventories and `verification/SOURCE_INSPECTION.json`. Every row is inventoried; only the selected content above was semantically reviewed. Path-based category/disposition labels are explicitly marked as inference. Empty origin/license fields mean evidence has not been linked, not that a file is free to use.

The reference inventory additionally matches 217 media files to identical research members by SHA-256. All 109 wiki images have origin URLs recovered from `research/raw/fandom_images/_manifest.tsv`, with an identical-content match. These links are reported by supplied metadata and were not all revalidated online. Metadata uploader names are recorded as contributors, not rightsholders; metadata upload timestamps are not asserted as capture dates. Production rights remain unapproved.

## Original research organization

| Original group | Files | Adaptation |
|---|---:|---|
| Six numbered reports | 6 | Preserve the coverage/review method; rewrite findings around the new game |
| `research/generated/` | 4 | Do not run/import old Python/Lua/config; provide a small original catalog |
| `raw/community/` | 94 | Historical anecdotes/metadata; no popularity or asset-rights claims carried forward |
| `raw/fandom/` | 456 | Historical wiki data; conflicting and client-derived values excluded |
| `raw/fandom_images/` | 110 | Legacy reference media/manifest only |
| `raw/guides/` | 559 | Legacy third-party snapshots, not current Chicken Farm evidence |
| `raw/guide_images/` | 63 | Reference-only observations |
| `raw/roblox_api/` | 61 | Dated metadata, not authoritative gameplay formulas |
| `raw/youtube/` | 410 | Caption/video organization useful; ASR/storyboard precision limited |
| Other raw index/data files | 13 | Preserve source paths in the inventory |

The six main documents are `01_fandom_wiki.md`, `02_guide_sites.md`, `03_youtube_findings.md`, `04_official_and_community.md`, `05_prompt_review.md` and `06_fixes_applied.md`. Together they contain 479,363 bytes. They cover Steal An Egg, not verified Chicken Farm research.

Notable exclusions: `generated/build_data.py`, `generated/config_extras.json`, `generated/PetVisuals.lua`, `generated/ZonePets.lua` and `raw/fandom_petindex_utility_main_v0.1.13.js`. The config extras contain 88 competitor-named records with fields such as zone, egg/model weight, index Speed, hatch and pool. The new six-species catalog replaces that entire data model.

Original prompt tags `[VERIFIED]`, `[SOURCE]` and `[DESIGN]` are the earlier author's labels. They are not inherited as verification for this adaptation. The old review identifies 74 findings; the old fix log claims all addressed. Those historical claims do not certify this package or an implemented Roblox game.

## Original reference organization

| Folder | Files | Treatment |
|---|---:|---|
| `reference/guides/` | 63 | Observe broad usability; replace game-specific art and features |
| `reference/ingame/` | 20 | Selected HUD/index/pen screenshots reviewed |
| `reference/ingame_clips/` | 4 | Inventory only; no playback claim |
| `reference/official/` | 14 | Competitor icon/thumbnail/badge/pass art; excluded from production |
| `reference/wiki/` | 109 | Competitor renders/screenshots; reference-only |
| `reference/youtube_storyboards/` | 29 | Contact-sheet indexing method useful; no precise timing inferred |
| `reference/youtube_thumbs/` | 16 | Legacy video provenance strings |

The inspected `reference/guides/fuse_machine_screen_ign.webp` visibly requires three same pets and mentions Luck. The new merge rule deliberately replaces it with two identical species producing one guaranteed successor. The pen screenshots show passive income labels; they cannot establish the requested collect-and-sell gameplay or Chicken Farm timings.

## Core adaptation mapping

| Original prompt | Merge a Brainrot replacement |
|---|---|
| §0 faithful recreation in one pass | Original v1 specification; incremental guidance by default, full mode available |
| §0.4–0.5 mandatory concept/image pipeline | Optional original art after playable mechanics; written map spec and actual captures for QA |
| §1 and §5–7 steal/carry/guardian/day-night loop | Bounded producer → Mini → bag → sell loop |
| §2–3 seven-plot hub and twelve biome lanes | Six compact plots around an original open plaza |
| §4 weight/scale/speed/growth math | Fixed six-tier values and integer quarter-Coin ledger |
| §8 pens, hatching and automatic income | Twelve producer slots, fresh session timers, no offline production |
| §9–10 treadmill, trails, bat and traps | Removed from v1 |
| §11 index rewards | Persistent discovery display with no extra rewards |
| §12 sell pets/eggs | Sell bag Minis only; producers cannot be deleted/sold |
| §13 paid three-pet probabilistic egg fusion | Free deterministic two-species merge, immediate producer output |
| §14–15 premium shop/live events | Removed from v1; starter purchase uses Coins |
| §16–17 tutorial and copied UI geometry | Server-confirmed onboarding and original responsive design brief |
| §19 data/remotes | Smaller schema, stronger lease lifecycle and serialized mutations |
| §20–21 competitor art/catalogs | Six proposed original primitive characters with stable IDs |
| §22 reference list | Complete archive inventory + observed notes + future capture plan |
| §23 no rebirth | Explicit rebirth thresholds, reset/preserve list and permanent bonus |
| §24–25 unknowns/done checklist | Evidence ledger, meaningful tests and truthful status reporting |

Legacy media remains local evidence and is not redistributed in the replacement pack. The revised research/reference archives contain newly authored notes, inventories and templates. No ownership or reuse license is inferred from the source files.
