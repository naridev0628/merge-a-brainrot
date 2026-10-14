# Checkpoint 0 verification — 2026-10-14

## Executed

| Check | Result |
| --- | --- |
| Extracted files compared against ZIP entry SHA-256 hashes | All 30 files match |
| Git inventory | Git 2.56.0; initially unborn master; no remote; no existing source |
| Tool inventory | Studio installed; Rojo absent from PATH and checked tool-manager directories |
| Studio connector | Two instances listed; unnamed instance reports no place open |
| Official Rojo archive SHA-256 | Matches `d4dfa3493a1613a43fc87312d6dac660d7c8bf38e6a99aa5dcd0d26154ba0b82` |
| Local `rojo --version` | Rojo 7.7.1 |
| `rojo build default.project.json` | Exit 0; source mapping place generated |
| `rojo build setup.project.json` | Exit 0; setup place generated |
| Generated setup XML | Parsed; service containers, Shared folder, floor and spawn present |
| `rojo sourcemap default.project.json` | Exit 0; null map expected for source folders with no Luau files yet |
| Open generated setup in Studio | Own window; Edit inspection confirms PlaceId 0, Shared folder, SetupSpawn and SetupBaseplate |
| Rojo plugin compatibility and connection | Installed plugin 7.7.1 connects to CLI 7.7.1 on localhost:34873 |
| Live source synchronization | Temporary SetupSyncProbe ModuleScript creation and subsequent source edit observed through Studio inspection |
| Probe removal | Confirmed absent in Server runtime after local file deletion |
| Play smoke check | Client/Server DataModels active; one player, Health 100, position approximately (0, 4.645, 0), Plastic floor; avatar visually confirmed |
| Stop playtest | Tool confirmed Game Stopped |
| GitHub owner | Connector and credential-backed API both identify `naridev0628` (ID 341235326) |
| Repository creation | GitHub returned `naridev0628/merge-a-brainrot`, private=true, default branch main |

## Console observations

Studio reported `cloud_9643911698.Superpower.LocalScript:5: Expected ')' (to close '(' at line 4), got 'end'`, including repeated instances during Play. This path belongs to an installed cloud plugin, not project source. On initial opening, AssetExport also reported failure to connect its animation-export ferry. These plugin errors remain unresolved; no clean-console claim is made. Project folders contain no gameplay scripts.

## Not run

macOS execution, multiplayer, game economy, UI, save/rejoin, performance, and runtime security tests. No gameplay source exists at this checkpoint. The Play smoke check verifies only the setup floor and spawn.

The reports inside `Merge_a_Brainrot_Pack/verification/` are historical document checks from the supplied handoff and are not implementation test results.
