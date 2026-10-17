---
name: Godot Development
description: Implement and debug Potion Shop GDScript, scenes, resources, UI, and stock Godot multiplayer; validate changes before handing off for user playtesting.
---

# Godot development loop

1. Read root `AGENTS.md`, `docs/game/brief.md`, and relevant architecture notes.
2. Turn the request into a small player-visible outcome. Ask only when a design
   choice would materially change the requested behavior.
3. Inspect affected scripts, scenes, resources, and existing changes. Verify APIs
   against the installed Godot version and official Godot documentation when uncertain.
4. Edit the smallest complete feature. Keep shared rules in `network/game.gd`,
   authority validation in `authority/`, and presentation/input in `client/`.
5. Run `python3 tools/check.py`; add `--network` for RPC or session changes.
   Diagnose the first underlying error rather than chasing cascading failures.
6. Add regression coverage when changing meaningful rules or networking behavior;
   do not create implementation-mirroring tests for cosmetic edits.
7. Give a concise handoff: what changed, checks actually run, and what to try in
   Godot. The user runs F5, or F6 on the shop scene for a solo shortcut.
8. On feedback, use the exact error/stack trace or screenshot. Reproduce what can
   be reproduced, fix the cause, and rerun affected checks.

For artwork or animation changes, load `godot-assets` and follow the canonical
`docs/game/art-direction.md`. Restart the standalone game after completing game
changes, following the process-scoping instructions in root `AGENTS.md`.

## Scene discipline

- Use `.tscn`/`.tres` text edits for this workflow. Preserve resource references
  and node names used by `$Path`, `%UniqueName`, and signal connections.
- Check layout at relevant aspect ratios through user playtesting; successful
  headless loading does not prove UI visibility or readability.
- Do not introduce Summer APIs or services. This project runs in stock Godot.
- For fresh external assets, confirm intended art direction and use rights first;
  record dimensions, scale, and import choices when they matter.

## Debugging information to request when needed

Test input through actual key/mouse events and the InputMap/GUI path, not only
`Input.action_press()` or emitting a button's signal. Use the installed Godot
version's device constants; Godot 4.7 uses `InputEvent.DEVICE_ID_KEYBOARD` (16)
and `InputEvent.DEVICE_ID_MOUSE` (32). Device 16 is not a Summer-specific bug.
Headless GUI tests need viewport-local coordinates (for example,
`Viewport.push_input(event, true)`), respecting stretch transforms.

If clicks select nodes in the editor, inspect Game panel input/selection mode.
Also test a standalone game window before concluding the menu code is broken.
If advice fails, reproduce and verify rather than repeating the same instruction.

Ask for the shortest reproduction, expected versus actual behavior, and the full
Godot error including script and line. For co-op, identify host/client, addresses,
and whether both processes use the same revision. For appearance, ask for a
screenshot and window size. Avoid requesting all of these for every small change.
