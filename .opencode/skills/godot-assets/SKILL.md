---
name: Godot Assets
description: Create, redraw, animate, import, or visually verify Potion Shop sprites, character sheets, environment art, and fantasy skin palettes while preserving the established cozy style.
---

# Asset workflow

1. Read root `AGENTS.md` and `docs/game/art-direction.md`. Inspect the actual
   reference images and relevant scene, not just their filenames. In this project
   `elf.png` is Aaron's original witch portrait, not the former Elf Adventurer.
2. Identify the requested visual result. A request for a building or furniture
   requires recognizable artwork, not labeled rectangles. Preserve established
   character identity when redrawing it; do not substitute unrelated stock art.
3. Reuse the existing palette and generators where appropriate. Keep original
   references, editable source, individually inspectable frames and runtime atlas.
   Check for manual source edits before regeneration; generators overwrite output.
4. Draw meaningful animation poses: expression, hands, feet, hair and clothing
   should change deliberately. Whole-image bob/squash is cutout animation, not a
   newly drawn walk cycle. Describe accurately what was produced. Never imply
   front-facing art provides back/side views that were not drawn.
5. Integrate the asset completely: menu preview, local player, remote player,
   frame dimensions, animation timing, anchors and filtering. When changing an
   atlas, update both its texture reference and `hframes`/`vframes` together.
6. Inspect an enlarged nearest-neighbor contact sheet for clipping, seams,
   inconsistent feet, unreadable faces, palette drift and duplicate-looking poses.
7. Run relevant project checks, then launch a separate rendered Godot instance
   and inspect an actual capture at gameplay scale. Inspect more than one pose
   for animation work. Headless loading and a source preview cannot prove that
   the imported art renders correctly. Label staged visual fixtures as fixtures.
8. Update the art notes and per-asset source/credit records. Restart this project's
   standalone game after finishing, as required by `AGENTS.md`, and give a short
   handoff with a preview when useful.

## Lessons from this project

- **SVG import limitations:** the oak floor's SVG pattern rendered blank/dark in
  Godot despite looking correct in another renderer. Bake pattern/mask-heavy SVGs
  to transparent PNG using ImageMagick, keep the SVG source, and inspect the result
  in Godot again. Do not assume every SVG feature is supported.
- **Palette changes:** change semantic skin colors (base, shade, highlight,
  blush) at drawing time. Do not tint the whole sprite and unintentionally change
  hair/clothing. Preserve shading and facial contrast for each palette.
- **Stable appearances:** derive customer outfit, skin and animation phase from
  customer ID, not queue position or a fresh random call per snapshot. Appearance
  must persist through reorder/rejoin and match on co-op clients.
- **Timing:** hold idle poses and make blinks brief; do not give every frame equal
  duration blindly. Drive steps from actual distance, returning to idle when
  blocked. Art transforms must not alter collision or authority movement.
- **Visual matching:** every ingredient and potion is its own reusable animated
  asset. Use the exact same silhouette/color on shelves, in recipes and beside
  customers. Furniture artwork must be empty; actual item sprites sit on board
  anchors, with stock controlling visibility. Do not bake inventory into shelves
  or rely on item-name labels to compensate for indistinct silhouettes.
- **Scale:** judge at game resolution, not only an enlarged contact sheet. Compare
  visible body height as well as canvas height; transparent padding affects scale.
  Nearest filtering preserves pixel edges, but non-integer scaling can produce
  uneven pixel widths. Match the established scale and inspect it rather than
  claiming every scale is pixel-perfect.
- **Tools:** authored SVG/PNG generators are useful for reproducible cohesive
  pixel art; they are not a substitute for visual judgment. No image-generation
  model is configured by this skill. Do not claim to have used one.
- **External art:** verify the original publisher's license, record provenance
  and modifications, and distinguish third-party art from original project work.
  Free-to-download alone does not establish reuse rights.

## Asset locations

Use `docs/game/art-direction.md` for current identities, generator commands and
atlas layouts. It is the canonical project art guide; do not maintain conflicting
copies in agent prompts or session memory.
