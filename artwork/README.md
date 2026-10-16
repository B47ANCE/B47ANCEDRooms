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
