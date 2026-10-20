# Setup

## Current stacked farm preview

Use `default.project.json` for gameplay. Create `build/`, then run `rojo build default.project.json -o build/MergeABrainrot-StackedFarm.rbxlx`. Open that file in Studio and press Play. For continuous editing, run `rojo serve default.project.json` and connect the Rojo plugin to that server. The world appears at runtime.

Use Luau 0.743 to run all non-Studio `tests/*.luau` scripts. Run `tools/simulate_progression.luau` for the economy benchmark. The optional Studio-only layout regression is `tests/studio-layout.client.luau`; run its contents in the Client command bar during Play. The game is memory-only and refuses progression outside Studio.

The setup-place commands below document Checkpoint 0. They are retained for history; use the default project for the first playable.

## Windows (this machine)

Git 2.56.0 and Roblox Studio are installed. Rojo 7.7.1 was downloaded from the official release into `.tools/rojo-7.7.1/`, with its archive SHA-256 checked against the release metadata. This is project-local; system PATH was not changed. The installed Studio plugin is also 7.7.1; connection and source creation/edit/removal sync were verified on 2026-10-14.

Run from the repository root in PowerShell:

```powershell
.\.tools\rojo-7.7.1\rojo.exe build setup.project.json -o build\MergeABrainrot-Setup.rbxlx
.\.tools\rojo-7.7.1\rojo.exe serve setup.project.json --port 34873
```

On a fresh Windows clone, `.tools/` and `build/` are intentionally absent. Download the Windows archive matching your processor from the pinned release below, extract `rojo.exe` into `.tools/rojo-7.7.1/`, and create `build/` before running these commands. Alternatively, install Rojo 7.7.1 on PATH and use `rojo` in place of the local executable path.

Open `build/MergeABrainrot-Setup.rbxlx` in a separate Roblox Studio window. Use the Rojo plugin to connect to the address printed by `serve`. Confirm the project name before connecting. Verify Explorer contains `ReplicatedStorage.Shared`, `ServerScriptService`, and `StarterPlayer.StarterPlayerScripts`. Press Play to check the floor/spawn, then Stop. This is a setup place, with no farm or economic state.

The setup place is connected to localhost:34873 in the current session; its server was left running. On a later session, start `serve` again and connect the plugin to port 34873. If the plugin needs installation/update, the official CLI supports `rojo plugin install`. Restart Studio afterward if necessary.

## macOS (instructions only; not executed)

Use Git and Roblox Studio on the Mac. Download Rojo **7.7.1** from the official release: `macos-aarch64` for Apple Silicon or `macos-x86_64` for Intel. Extract it and make the executable available as `rojo`. Use the same version on both machines.

From the repository root:

```sh
rojo --version
mkdir -p build
rojo build setup.project.json -o build/MergeABrainrot-Setup.rbxlx
rojo serve setup.project.json
```

Open the generated setup place in Studio and connect the Rojo plugin. Mac execution and sync must be verified on the collaborator's machine.

## Shared repository

The owner clarified that no shared repository existed and requested a new one. The private repository is [naridev0628/merge-a-brainrot](https://github.com/naridev0628/merge-a-brainrot). The initial setup is on `main`; future work uses `codex/` feature branches.

The owner will invite the collaborator through [repository access settings](https://github.com/naridev0628/merge-a-brainrot/settings/access). After accepting the invitation, the collaborator can clone:

```sh
git clone https://github.com/naridev0628/merge-a-brainrot.git
cd merge-a-brainrot
```

Use your own local Studio development place and commit portable source/configuration changes. Generated builds and downloaded tools are excluded from Git. The supplied archive remains intact under `Merge_a_Brainrot_Pack/`; current project status is in `docs/BUILD_STATUS.md`.

## References

- [Rojo installation](https://rojo.space/docs/v7/getting-started/installation/)
- [Build and sync workflow](https://rojo.space/docs/v7/getting-started/new-game/)
- [Pinned Rojo 7.7.1 release](https://github.com/rojo-rbx/rojo/releases/tag/v7.7.1)

No experience has been published, no API access enabled, and no production data accessed.
