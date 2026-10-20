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
| Processor hierarchy | [03:22](0202-03-22.jpg): small heading, large standalone 79, rate below | Applied “Processing Minis”, a larger numeric queue with comma separators, and the existing rate. The same three text cells and board geometry remain; no Instances or Parts added. Clear also resets the queue, rate and upgrade quote/affordability. |

The [board’s applied comparison section](index.html#comparison-layout) includes every paired front/oblique scene. Direct evidence:

| Scene | Front pair | Oblique pair |
| --- | --- | --- |
| 24 Minis | [Before](../../verification/layout-before-24-front.jpg) / [After](../../verification/layout-after-24-front.jpg) | [Before](../../verification/layout-before-24-oblique.jpg) / [After](../../verification/layout-after-24-oblique.jpg) |
| 50 Minis | [Before](../../verification/layout-before-50-front.jpg) / [After](../../verification/layout-after-50-front.jpg) | [Before](../../verification/layout-before-50-oblique.jpg) / [After](../../verification/layout-after-50-oblique.jpg) |
| 96 Minis | [Before](../../verification/layout-before-96-front.jpg) / [After](../../verification/layout-after-96-front.jpg) | [Before](../../verification/layout-before-96-oblique.jpg) / [After](../../verification/layout-after-96-oblique.jpg) |
| Six producer names | [Before](../../verification/producer-palette-before-front.jpg) / [After](../../verification/producer-palette-after-front.jpg) | [Before](../../verification/producer-palette-before-oblique.jpg) / [After](../../verification/producer-palette-after-oblique.jpg) |

Lawn: [raised overlay before](../../verification/lawn-overlay-before.jpg) / [native studs after](../../verification/lawn-native-after.jpg).

These are isolated comparison scenes. Their cloned pad labels are not managed as the normal owned plot by `PadLabels`; visible label overlaps are not acceptance of the normal controller’s layout. Dense Crocodilo meshes still overlap at high counts. The images and Part counts make **no FPS, memory, device or multiplayer claim**. Historical benchmark provenance is unchanged.

### Hub lawn: dense native studs on the existing foundation

The [hub lawn comparison](index.html#comparison-hub-lawn) applies the dense open-lawn texture visible at [08:00](0480-08-00.jpg) to our hub. Five implementation images supplement the unchanged 14 source frames:

| View | Before | After |
| --- | --- | --- |
| Ground level | [Sparse raised ornaments](../../verification/hub-lawn-before-ground.jpg) | [Dense native studs](../../verification/hub-lawn-after-ground.jpg) |
| Oblique overview | [Earlier hub surface](../../verification/hub-lawn-before-oblique.jpg) | [Same island and routes](../../verification/hub-lawn-after-oblique.jpg) |
| Path and plaza junction | — | [Native surface detail](../../verification/hub-lawn-after-seam.jpg) |

Baseline is `6756b31`; this hub pass was **native-verified and committed in8909891**. It removes the remaining **1480 inert `SquareStud` Parts**, retaining all nine collision slabs, six paths, central plaza and its physical studs. The earlier 557 fully hidden ornaments were already culled from the original 2037 and are not counted again. Five rectangular top faces and four horizontal wedge faces now use native studs; their patterns follow the slabs’ orientations, rather than a seamless texture atlas.

Actual-generator checks and native **864 foundation raycasts, six routes with 8664 prop-clearance checks, bridge grounding and environment checks passed**. The foundation sizes, transforms, colors, materials and collision flags remain unchanged. Live water and rendering differ between the paired captures; the images document surface appearance and preserved composition. The Part reduction is **not an FPS, memory-recovery, device or multiplayer measurement**. Raw evidence: [hub-native-studs.json](../../verification/hub-native-studs.json).

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

### Processor board: count first, with reliable empty-state reset

The [processor comparison section](index.html#comparison-processor) uses the matched **96-count pair** as its main comparison. The reference at 03:22 informs the heading/count/rate hierarchy; “Processing Minis”, numeric formatting and dimensions are our adaptation. The font, economy, physical board and existing three text cells remain unchanged. Baseline source is `977b29e`; this processor change was native-verified and committed in `eb7bc2b`.

| View | Before | After |
| --- | --- | --- |
| 96 queued, close | [Original queue text](../../verification/processor-before-96.jpg) | [Larger standalone count](../../verification/processor-after-96.jpg) |
| Empty queue | [Original empty state](../../verification/processor-before-zero.jpg) | [Numeric zero](../../verification/processor-after-zero.jpg) |
| 96 queued, approach | [Original approach](../../verification/processor-before-96-approach.jpg) | [Clearer count; cloned labels still overlap](../../verification/processor-after-96-approach.jpg) |
| Maximum queue | — | [2,147,483,647 fits](../../verification/processor-after-max.jpg) |

Native checks reduced **15 expected baseline failures to zero across nine recorded samples**, including clear and fresh-state rendering on the same Core session. Clear resets queue, rate and related upgrade quote/affordability consistently. Native text measurements passed for 0, 1, 96 and the maximum count: the title measured **269×40 inside 660×48 pixels**, the maximum count **491×92 inside 660×110**, and the rate **248×48 inside 660×58**. No Instances or Parts were added.

Matched close views were visually accepted. The approach count is clearer, but unmanaged cloned pad labels still overlap the board: this is **not normal owned-pad layout acceptance**. The empty after-view includes a chat-loading artifact and a slightly different background; the 96-count pair is the closest visual match. These images and text bounds establish no FPS, memory, device or multiplayer improvement.

The farmer’s visible shirt and sleeves at [01:36](0096-01-36.jpg) and [03:22](0202-03-22.jpg) support the already implemented waist-height blue counter. Thick island foundations, square silo, two-rail fences, basket, shrubs, plank bridges and tutorial ground guidance are also already present. They are comparison points, not missing-feature claims. Existing tree variants should be assessed before adding scenery.

**Nests are excluded by the user’s direction.** They remain visible in reference images and are described only as source evidence. This study does not propose adding them or copying character assets.

## Touch HUD: space for movement, Jump and the held card

The [touch HUD comparison](index.html#comparison-touch) adds five before/after layout pairs and four held-card/settings views. These are **14 implementation images**, separate from the unchanged **14 source-video frames**. They document our responsive adaptation, not a mobile layout established by the reference video.

| Emulator layout | Before | After |
| --- | --- | --- |
| Phone landscape, safe area 750×323 | [Overlapping bottom HUD](../../verification/touch-phone-landscape-before.jpg) | [Central count strip](../../verification/touch-phone-landscape-after.jpg) |
| Phone portrait, safe area 401×720 | [Basket over Jump](../../verification/touch-phone-portrait-before.jpg) | [Counts above controls](../../verification/touch-phone-portrait-after.jpg) |
| Short landscape, safe area 705×280 | [Cash and total overlap controls](../../verification/touch-galaxy-landscape-before.jpg) | [Compact HUD and clear controls](../../verification/touch-galaxy-landscape-after.jpg) |
| Tablet landscape, safe area 1375×974 | [Cash and Sprint meet larger controls](../../verification/touch-tablet-landscape-before.jpg) | [Large-control clearance](../../verification/touch-tablet-landscape-after.jpg) |
| Narrow tablet, safe area 579×759 | [Large Jump overlaps basket](../../verification/touch-medium-portrait-before.jpg) | [Clearance follows actual control size](../../verification/touch-medium-portrait-after.jpg) |

[Held Lucky in portrait](../../verification/touch-actual-held-portrait.jpg) and [Settings while carrying](../../verification/touch-actual-settings-portrait.jpg) show the block, farm counts and native controls together. The short landscape card keeps its existing scrolling: [upper content](../../verification/touch-actual-lucky-short-top.jpg) / [cost, Unlock and Discard](../../verification/touch-actual-lucky-short-bottom.jpg). The two short-card screenshots use different camera positions; they demonstrate scroll states, not a matched before/after scene.

Five settled emulator layouts passed native bounds, count/text-fit and reachable Lucky/Settings scroll-action checks. The actual-module CLI also covered 2,163 desktop layouts and 72 touch layout/state combinations. A native-size observer follows Jump resizing and replacement; the measured Galaxy→iPad and reverse transition each retained one sampled mismatching render frame before correction, versus approximately 1.8 seconds and 0.2 seconds before the observer. This is event-response evidence, not an FPS improvement.

Validation used the **Studio device emulator, mouse-driven interaction and native UI checks**. No physical touchscreen, device performance or multiplayer certification is claimed. The recorded comparisons preserve Home, counts, the Shop route and the nonmodal held card; compact promotional controls yield space. Source observations, source frame counts and existing comparison evidence remain unchanged. Raw evidence: [touch-hud-native.json](../../verification/touch-hud-native.json).

## Evidence files

- `captures.json`: exact saved UTC times, screenshot dimensions, filenames and capture notes.
- `annotations.json`: observation, intended application, subject visibility and category for every saved image.
- `study.json`: source and method metadata, omitted samples and limitations.
- `build-board.mjs`: validates the capture/annotation relationship and generates `index.html`. Run `node docs/reference/chicken-farm-foltyn-study/build-board.mjs` from the repository root.

The original 100 captures, 36 key references and frame anchors remain intact; that board gains only a link to this separate study. The older 12-frame study is untouched. Native acceptance reported by the root agent is summarized above; commit/sync provenance stays in the engineering checkpoint. This research folder itself changes no game source.

The generated HTML and local links are checked statically. Browser interaction preview remains unverified because local-file browser access is blocked; no alternate browser or server was used.
