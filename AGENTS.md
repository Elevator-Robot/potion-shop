# Potion Shop — OpenCode + Godot

## Working agreement

Use the normal Build agent. The user describes changes here, you edit the project
and run relevant checks, then the user plays it in Godot and brings back feedback.
Load the project `godot-development` skill for gameplay, scene, resource, or engine
work. No Summer installation, account, MCP server, or custom agent is required.
For asset creation, redraws, animation or visual polish, also load `godot-assets`
and read `docs/game/art-direction.md`. Deliver recognizable artwork and inspect
it in rendered Godot; placeholder geometry and headless tests are not visual proof.
Do not delegate unless the user explicitly requests it.

Read `docs/game/brief.md` before changing design and `docs/game/architecture.md`
before changing networking. Keep these documents current when decisions change.
The report in `docs/research/` describes the pre-migration project, not current setup.

## Project map

Primary atmosphere reference: `/home/aphexlog/Google Drive/Game Dev/Potion Shop/potion-shop/concept`
(including `exterior/`). Inspect these images before visual redesigns. Aim for
violet window light, amber candles, layered gnarled woodland, patterned rugs and
busy witchy furniture. Preserve the reference originals; record derived assets.

- `project.godot`: stock Godot 4.7 project; Compatibility renderer.
- `client/menu.tscn`: F5 entry point, solo and host/join controls.
- `client/main.tscn`: shop scene; F6 starts solo if no session exists.
- `client/`: input, presentation, HUD, and owner/observer player scenes.
- `network/session.gd`: `Session` autoload; ENet lifecycle, RPCs, state delivery.
- `network/game.gd`: shared constants, recipes, station geometry, helpers.
- `network/shop_navigation.gd`: host-side customer paths around shared furniture.
- `network/cottage_layout.gd`: irregular floor outline shared by art and physics.
- `client/customer_view.gd`: interpolated roaming customers, not queue slots.
- `client/shop_prop.gd`: pixel furniture, foot collisions and interaction frames.
- `client/item_icon.gd`: one canonical animated sprite per ingredient/potion,
  reused in hints, search, inventory, hands, recipes and customer bubbles; no item-name UI.
- `authority/main.gd`: host-owned seat, movement and command validation.
- `authority/shop.gd`: shop rules and authoritative state.
- `assets/characters/`: existing character art; reuse it.
- `docs/game/art-direction.md`: player identities, visual style and atlas contracts.
- `tools/draw_*`: reproducible original asset generators; retain editable sources.

## Rules

- Preserve the server-authoritative shop. Derive sender identity from Godot RPC
  metadata, never a client-provided seat. Clients render snapshots, not invented state.
- Use tabs in GDScript and existing naming conventions. Prefer explicit types
  when dictionary values would otherwise infer Variant.
- Inspect scenes/resources before editing; preserve node paths, signals, and UIDs.
- Do not edit `.godot/`, manually regenerate import caches, or replace assets casually.
- Avoid simultaneous disk writes and unsaved editor changes to the same scene.
  When the user reports unsaved editor work, resolve that before overwriting it.
- Keep changes scoped. Do not redesign mechanics just to fix an integration issue.

## Validation and handoff

Run `python3 tools/check.py` for script/resource changes. It imports the project,
loads scenes, checks shop behavior, and runs a solo input smoke test headlessly.
For networking changes also run `python3 tools/check.py --network` (two ENet peers).
Set `GODOT_BIN` if the executable is not named `godot`.

Headless checks do not prove appearance, sound, or game feel. Report exactly what
passed and give the user a short F5/F6 playtest checklist for the changed behavior.
Do not claim to have visually inspected the game without actually viewing it.

After completing game changes and relevant checks, always restart this project's
standalone game so the user can immediately play the latest version. Stop only
the game process belonging to this project, leaving the Godot editor and other
projects alone. Launch `godot --path . --windowed --resolution 1152x864` from the
project root (or use `GODOT_BIN`). If it is not running, start it. Run it in the
background and mention the restart in the handoff.

Conventional commits: `type(scope): lowercase imperative description`.
