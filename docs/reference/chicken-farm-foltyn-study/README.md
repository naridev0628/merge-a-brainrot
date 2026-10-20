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

The [board’s applied comparison section](index.html#comparison-layout) includes every paired front/oblique scene. Direct evidence:

| Scene | Front pair | Oblique pair |
| --- | --- | --- |
| 24 Minis | [Before](../../verification/layout-before-24-front.jpg) / [After](../../verification/layout-after-24-front.jpg) | [Before](../../verification/layout-before-24-oblique.jpg) / [After](../../verification/layout-after-24-oblique.jpg) |
| 50 Minis | [Before](../../verification/layout-before-50-front.jpg) / [After](../../verification/layout-after-50-front.jpg) | [Before](../../verification/layout-before-50-oblique.jpg) / [After](../../verification/layout-after-50-oblique.jpg) |
| 96 Minis | [Before](../../verification/layout-before-96-front.jpg) / [After](../../verification/layout-after-96-front.jpg) | [Before](../../verification/layout-before-96-oblique.jpg) / [After](../../verification/layout-after-96-oblique.jpg) |
| Six producer names | [Before](../../verification/producer-palette-before-front.jpg) / [After](../../verification/producer-palette-after-front.jpg) | [Before](../../verification/producer-palette-before-oblique.jpg) / [After](../../verification/producer-palette-after-oblique.jpg) |

Lawn: [raised overlay before](../../verification/lawn-overlay-before.jpg) / [native studs after](../../verification/lawn-native-after.jpg).

These are isolated comparison scenes. Their cloned pad labels are not managed as the normal owned plot by `PadLabels`; visible label overlaps are not acceptance of the normal controller’s layout. Dense Crocodilo meshes still overlap at high counts. The images and Part counts make **no FPS, memory, device or multiplayer claim**. Historical benchmark provenance is unchanged.

The farmer’s visible shirt and sleeves at [01:36](0096-01-36.jpg) and [03:22](0202-03-22.jpg) support the already implemented waist-height blue counter. Thick island foundations, square silo, two-rail fences, basket, shrubs, plank bridges and tutorial ground guidance are also already present. They are comparison points, not missing-feature claims. Existing tree variants should be assessed before adding scenery.

**Nests are excluded by the user’s direction.** They remain visible in reference images and are described only as source evidence. This study does not propose adding them or copying character assets.

## Evidence files

- `captures.json`: exact saved UTC times, screenshot dimensions, filenames and capture notes.
- `annotations.json`: observation, intended application, subject visibility and category for every saved image.
- `study.json`: source and method metadata, omitted samples and limitations.
- `build-board.mjs`: validates the capture/annotation relationship and generates `index.html`. Run `node docs/reference/chicken-farm-foltyn-study/build-board.mjs` from the repository root.

The original 100 captures, 36 key references and frame anchors remain intact; that board gains only a link to this separate study. The older 12-frame study is untouched. Native acceptance reported by the root agent is summarized above; commit/sync provenance stays in the engineering checkpoint. This research folder itself changes no game source.
