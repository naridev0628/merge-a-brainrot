# Chicken Farm map reference board

Open `index.html` locally in Codex. It is a static board with 100 annotated source frames, category and visibility filters, search, an image lightbox, video timestamp links, and local Studio before/after captures. No external JavaScript library or server is required.

Source: [SSundee — Roblox Chicken Farm is INSANE](https://www.youtube.com/watch?v=HJcoc02bumg), 20:53. Capture times are approximate within about ±2.5 seconds.

## Regenerate

From the repository root:

```sh
node docs/reference/chicken-farm-map-study/build-board.mjs
```

The generator reads `captures.json` and `annotations.json`, checks for exactly one entry per index from 1 through 100, validates source-image existence and annotation fields, and writes `index.html`. Edit board layout and implementation status in the generator rather than only in the generated HTML.

## Verification record

The map integration pass reported passing Studio fixtures for FarmLandmarks, ConveyorFacade, the existing environment, mirrored plots, bridge grounding, all six hub routes, and Mini neighbor animation. The board's “Studio verified” labels refer to those game checks.

Static board checks cover 100 unique valid 1920×1080 source images, 100 individually written observation/application pairs, 36 key references, seven categories, local image/file/anchor links, all 100 source-video timestamp links, and JavaScript syntax. Before/after captures are separate local Studio images rather than part of the 100-frame source set.

The board opened in Codex. Browser interaction and rendered-page preview have **not** been verified: local-file URL security blocked the browser preview. No server or alternate-browser workaround was used. Static JavaScript syntax checking does not establish that the filters or lightbox were exercised in a browser.
