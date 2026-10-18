# Rooms project thumbnail

Selected by the user on October 15, 2026. The authoring checkpoint 79398b2 set the
project thumbnail without publishing, packaging or deploying. The subsequent
explicit publish request selects this export for an update to the existing item.
Runtime source, canonical mod version and runtime package are unchanged. Prior
publication evidence remains tied to its original preview; old provenance is
copied with exact hashes before the thumbnail update.

| File | Role | PNG dimensions | Bytes | SHA-256 |
|---|---|---|---:|---|
| source/rooms-thumbnail-original.png | Exact user-supplied source | 1254x1254 RGB | 1588530 | a639a0c877d9c9a3bf747c1363e0cd207e5525a4b7031734595181dad4bb9a07 |
| thumbnail.png | Selected project/Workshop export | 512x512 RGB | 278399 | 9602702443b0b1a92f9ed35e48e927fdd92d3e7d05d4789917a0edba2ed26668 |
| history/team-thumbnail-512.png | Prior fallback, exact preserved bytes | 512x512 RGBA | 607956 | f775bff1783d59af91f331652740d5279fd5603f66d431c6349f38cbd2d9915b |

The original was copied byte-for-byte. The export is a deterministic Lanczos
resize to the established square thumbnail size, PNG optimization/compression
level 9. The artwork was not regenerated, cropped or redrawn. The original and
previous fallback remain unchanged. The supplied original exceeds the existing
upload helper's 1 MiB preview cap; the export is below that cap.

scripts/prepare_workshop.py already copies artwork/thumbnail.png to the selected
stage's preview.png, verifies its SHA-256 and uses that file as the VDF preview.
No packaging code change is needed. Source/history artwork lives outside the
runtime source tree and is not included in the mod ZIP. Existing icon.png and
poster.png are unchanged. The manual selection supersedes fallback thumbnail
selection independently of those roles.

[VERIFIED files] PNG structure, dimensions, exported size and SHA-256 were checked
with Pillow/hashlib. Original equality and prior-fallback equality were checked
before/after selection. The export was visually inspected for complete text and
room composition. `python scripts/check_versions.py` passes for development;
the artwork authoring checkpoint used an Unreleased changelog entry. The explicit
publish preparation folds that note into the current runtime version as a
thumbnail-only update. Runtime tests were not repeated during authoring; publishing
reruns the applicable preflight without claiming native UI/gameplay acceptance.
Existing dedicated G7 and stable G8 runtime gates remain unchanged.

## Verified Workshop thumbnail publication

[VERIFIED live asset] The explicit publish request updated existing item
3820077442 (App ID 108600, Mod ID B47ANCEDRooms). SteamCMD used cached login,
exited 0 and reported Committing update...Success. The live preview URL changed;
its 512x512 PNG is exactly 278399 bytes and matches thumbnail.png SHA-256 in the
table above. Item title, public visibility and canonical description are unchanged.
Upload completed October 15, 2026, 5:22 PM Phoenix (2026-10-16 00:22 UTC).
The API's runtime-content update timestamp stayed unchanged for this artwork
update; that timestamp is not used as evidence of the thumbnail change.

Release preparation commit: `26c024ef43ab77d7bf9bdef339795c1114cc5221` on public
B47ANCE/B47ANCEDRooms, feature/standalone-rooms. Runtime remains 0.1.0-dev.3;
unchanged ZIP SHA-256:
`8fd3fc035f31c38996569e743584c98058a26b113ffc2d9079eac07b6f5b6087`.
Canonical inputs are artwork/thumbnail.png, docs/WORKSHOP_DESCRIPTION.md and
docs/WORKSHOP_CHANGELOG.md. Generated text is workshop/description.bbcode and
workshop/changenote.txt. Fresh stage/preview.png, VDF, manifest, local logs,
API snapshots and receipt are under ignored
dist/workshop-publish/0.1.0-dev.3-thumbnail/submission. Previous current-package
provenance was copied with a hash/size preservation ledger; nothing was deleted,
relabeled or rebuilt. Current provenance records this update separately from
prior UI publication evidence.

[TESTED offline] `python tests/run_tests.py` and
`python scripts/check_versions.py --root . --release` PASS. Preparation used
`python scripts/prepare_workshop.py --output dist/workshop-publish/0.1.0-dev.3-thumbnail/submission`.
Its ZIP CRC/path/duplicate/case/source-manifest and 84-file source/package/stage
parity checks PASS. Lua-only/localization/require-case checks, PNG dimensions,
size, preview SHA, public source/freshness and staged/tracked-file audits PASS.
No new runtime version or package was needed for a thumbnail metadata update.

After verified upload, the same verified Steam desktop installation was exited
gracefully and restarted with a hidden launch window; the client process returned.
A read-only check confirms its subscribed 84 runtime files remain identical to
the published UI build. No game/server launch, SP deployment, forced termination
or other project change occurred. Native UI/gameplay and dedicated multiplayer
remain NOT TESTED; G7 BLOCKED / NOT TESTED and stable G8 BLOCKED.

## Transparent mod icon — 0.2.0-dev.7

Selected by the user on October 18, 2026 for the mod icon. Built-in imagegen
edited source/rooms-thumbnail-original.png to isolate the room subject, remove
all lettering, background and external shadow, and retain genuine transparent
alpha. The full-size generated PNG is preserved at source/rooms-icon-transparent.png.
It is a generated interpretation of the supplied artwork, not a pixel-exact crop.
The complete room, door, window, cabinet, floor and green outline were visually
reviewed. The prompt requested the original pixel-art design and crisp edges,
the complete room centered with transparent padding, and no text, fill, glow,
shadow, added objects or clipped edges.

The production export at ../src/B47ANCEDRooms/42/icon.png is 64x64 RGBA, matching
the prior icon slot. System.Drawing HighQualityBicubic/HighQuality pixel-offset
resampling exported the generated source without compositing a background.
All four corners are transparent; the alpha range is 0–255. Prior icon bytes
are preserved in history/team-mod-icon-64.png. Source/history files are outside
the runtime package. No packaging or fallback-selection changes are required.

| File | SHA-256 |
|---|---|
| source/rooms-icon-transparent.png (1254x1254 RGBA) | 94aee1a977c64c2d74c5d4995f25d9522923a1e7e94d56370bb8dd26c831322a |
| ../src/B47ANCEDRooms/42/icon.png (64x64 RGBA) | 85c2071045b20eae12712177bf0ec69273ae363a12c13d8575e5f4a2c002edb0 |
| history/team-mod-icon-64.png (64x64 RGB) | 60e2a193a6c1e1190941e6c342ec23c673a561dbed895c80067fe2b89c7f7e83 |

The selected thumbnail SHA-256 remains 9602702443b0b1a92f9ed35e48e927fdd92d3e7d05d4789917a0edba2ed26668.
The runtime poster and original thumbnail source remain byte-identical to the
parent commit. Native in-game icon rendering remains NOT TESTED.
