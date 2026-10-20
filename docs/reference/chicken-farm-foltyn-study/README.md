# Foltyn Chicken Farm reference study

Source: [Foltyn — ROBLOX CHICKEN FARM..](https://www.youtube.com/watch?v=jdZNH1-EMJo), displayed duration **16:01**. Open the [annotated board](index.html), or return to the [original 100-frame study](../chicken-farm-map-study/index.html).

Fourteen selected browser screenshots cover 00:20–14:25. They were saved on 20 October 2026 between **09:49:57 and 09:57:50 UTC**, after seeking and allowing the paused picture to update. Five additional sampled positions were omitted because they showed creator close-ups or an edited interlude. This is sampled visual research, not continuous viewing or an audio audit.

The screenshots were captured through native Computer Use from the existing Chrome YouTube window. No remote video/audio was downloaded or extracted. Capture size is 1920×1080; timestamps use displayed whole seconds (approximately ±1 second). Creator overlays, editorial zooms and the recorded purchase dialog remain visible. Exact source colors, font family, dimensions, collision and economy cannot be established from these images.

## Applied changes and comparison evidence

| Priority | Evidence | Bounded application |
| --- | --- | --- |
| Display silhouette | [11:12](0672-11-12.jpg), [12:48](0768-12-48.jpg), [06:34](0394-06-34.jpg) | Applied low-front/high-rear dividers with sloped existing gold caps. Same 221/224 Parts per ground/upper row, 1117 for five rows; support, joins, producers, slots and Mini paths preserved. Exact dimensions are our adaptation. |
| Tray proportions | [04:48](0288-04-48.jpg) | Applied 24×16 logical tray with 32 positions per layer and three layers for 96 Minis. Connected rails/rims/facade changed together. Matched native scenes compare 24, 50 and 96 Minis. Dense Crocodilo overlap remains; the video establishes no cap or pickup radius. |
| Lawn surface | [08:00](0480-08-00.jpg) | Removed only the raised lawn overlay: 844 Parts per plot, 5064 across six. Native studded slabs remain; all 18 slab sizes/transforms match within 1e-5 and 77 colliders per plot are unchanged. Environment, mirror, bridge and affordability fixtures passed. |
| Producer name palette | [12:48](0768-12-48.jpg) | Applied Tung RGB(255,204,143) and Crocodilo RGB(177,236,112), with matched front/oblique native views of six actual meshes. Other names, font, outlines, size/offset/cutoff/depth occlusion and character colors are unchanged. This is a name-fill adjustment, not a font change. |
| Farm title clearance | Normal gameplay clipping, compared with the reference’s readable display hierarchy | Our adaptation moves only the title Billboard above the highest occupied row and wraps long display names. Physical sign, portrait, font, outline and ordinary depth occlusion remain unchanged. This is not an exact reference-header reproduction. |

The [board’s applied comparison section](index.html#comparison-layout) includes every paired front/oblique scene. Direct evidence:

| Scene | Front pair | Oblique pair |
| --- | --- | --- |
| 24 Minis | [Before](../../verification/layout-before-24-front.jpg) / [After](../../verification/layout-after-24-front.jpg) | [Before](../../verification/layout-before-24-oblique.jpg) / [After](../../verification/layout-after-24-oblique.jpg) |
| 50 Minis | [Before](../../verification/layout-before-50-front.jpg) / [After](../../verification/layout-after-50-front.jpg) | [Before](../../verification/layout-before-50-oblique.jpg) / [After](../../verification/layout-after-50-oblique.jpg) |
| 96 Minis | [Before](../../verification/layout-before-96-front.jpg) / [After](../../verification/layout-after-96-front.jpg) | [Before](../../verification/layout-before-96-oblique.jpg) / [After](../../verification/layout-after-96-oblique.jpg) |
| Six producer names | [Before](../../verification/producer-palette-before-front.jpg) / [After](../../verification/producer-palette-after-front.jpg) | [Before](../../verification/producer-palette-before-oblique.jpg) / [After](../../verification/producer-palette-after-oblique.jpg) |

Lawn: [raised overlay before](../../verification/lawn-overlay-before.jpg) / [native studs after](../../verification/lawn-native-after.jpg).

These are isolated comparison scenes. Their cloned pad labels are not managed as the normal owned plot by `PadLabels`; visible label overlaps are not acceptance of the normal controller’s layout. Dense Crocodilo meshes still overlap at high counts. The images and Part counts make **no FPS, memory, device or multiplayer claim**. Historical benchmark provenance is unchanged.

### Farm title: row-aware header and long-name wrapping

The [title comparison section](index.html#comparison-title) adds two illustrated pairs while preserving the 14 source references and all nine earlier comparison pairs. It also links the other two matched title views:

| View | Before | After |
| --- | --- | --- |
| One-row front | [Original title](../../verification/owner-title-before-one-front.jpg) | [Raised header](../../verification/owner-title-after-one-front.jpg) |
| Two-row oblique | [Original title](../../verification/owner-title-before-two-oblique.jpg) | [Raised header](../../verification/owner-title-after-two-oblique.jpg) |
| Five-row front | [Original title](../../verification/owner-title-before-five-front.jpg) | [Raised header](../../verification/owner-title-after-five-front.jpg) |
| Five-row long name | [Original title](../../verification/owner-title-before-long-front.jpg) | [Wrapped header](../../verification/owner-title-after-long-front.jpg) |

The title center follows logical Y `16 + (rows − 1) × 11` in world Y, with a 32×4 logical-stud canvas. The existing authored distance cutoff of 100 still becomes 65 world studs under plot scaling. The physical sign and portrait badge are unchanged. Native RED on the original camera-relative offset was followed by GREEN for one, two and five rows, shrink, empty and ownership reset; synthetic IDs preserve immutable species identity. At the close five-row camera, the 20-W display name measured **343.53×40.0618 pixels inside a 347×43 canvas**. Four paired views were visually accepted.

This fixes the farm title’s shelf clipping. Lower-row producer names can still be occluded by upper shelf edges. A fixed-pixel portrait can crowd the header at far distances on short viewports, and cloned comparison-pad labels remain unmanaged by the normal owned-plot controller. The captures do not establish universal text readability or any FPS, memory, device or multiplayer improvement.

The farmer’s visible shirt and sleeves at [01:36](0096-01-36.jpg) and [03:22](0202-03-22.jpg) support the already implemented waist-height blue counter. Thick island foundations, square silo, two-rail fences, basket, shrubs, plank bridges and tutorial ground guidance are also already present. They are comparison points, not missing-feature claims. Existing tree variants should be assessed before adding scenery.

**Nests are excluded by the user’s direction.** They remain visible in reference images and are described only as source evidence. This study does not propose adding them or copying character assets.

## Evidence files

- `captures.json`: exact saved UTC times, screenshot dimensions, filenames and capture notes.
- `annotations.json`: observation, intended application, subject visibility and category for every saved image.
- `study.json`: source and method metadata, omitted samples and limitations.
- `build-board.mjs`: validates the capture/annotation relationship and generates `index.html`. Run `node docs/reference/chicken-farm-foltyn-study/build-board.mjs` from the repository root.

The original 100 captures, 36 key references and frame anchors remain intact; that board gains only a link to this separate study. The older 12-frame study is untouched. Native acceptance reported by the root agent is summarized above; commit/sync provenance stays in the engineering checkpoint. This research folder itself changes no game source.

The generated HTML and local links are checked statically. Browser interaction preview remains unverified because local-file browser access is blocked; no alternate browser or server was used.
