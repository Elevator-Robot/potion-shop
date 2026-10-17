# Potion Shop

Potion Shop is a shop-management game where you create and sell potions, serve customers, and keep your magical business running through busy days.

Run the shop solo or team up in two-player co-op. Gather ingredients, brew potions,
and coordinate orders to keep up with customer demand. Choose your Elf Adventurer or
Purple Shopkeeper sprite in the menu, then walk around the shop with WASD/arrows.
The Purple Shopkeeper is selected by default and has eight custom-drawn cozy
pixel-art poses for idle, blinking, and walking.

## Run in Godot

Open `project.godot` with **stock Godot 4.7** (validated with 4.7.2), then press **F5**.
Choose **Play Solo**, **Host Co-op**, or **Join Co-op**. No Summer installation or
account is needed. F6 on `client/main.tscn` starts a solo shop directly.

- **Move:** WASD or arrow keys.
- **Interact:** E or Space; hold to chop ingredients.
- **Leave shop:** Esc.

For co-op on one machine, run two instances: host in one, join `127.0.0.1` in the
other. On a LAN, join the host's LAN IP. Both use UDP port **24567** by default;
the menu lets you choose another port. The host plays too and owns the shared shop.
Leaving as host ends the session. Rejoining starts with empty hands in the current shop.

Optional terminal shortcuts:

```sh
godot --path . -- --solo
godot --path . -- --host
godot --path . -- --join=127.0.0.1
```

Append `--port=24568` after `--` to use a different port on both instances.

## Develop with OpenCode

Use OpenCode's normal **Build** agent in this directory. Project instructions in
`AGENTS.md` and the `godot-development` skill describe the workflow:

1. Describe a feature, bug, or change in OpenCode.
2. OpenCode edits the scripts/scenes and runs relevant checks.
3. Play in Godot and share feedback, screenshots, or the full error and line number.
4. OpenCode iterates.

Example: “Make the brewing progress easier to read. Keep the recipes unchanged.”

The [game brief](docs/game/brief.md) preserves design intent; the
[architecture notes](docs/game/architecture.md) explain ownership and networking.

## Validate

Requires Python 3 and Godot on PATH (or set `GODOT_BIN` to its executable):

```sh
python3 tools/check.py
python3 tools/check.py --network
```

These are headless functional checks. Visual quality and game feel are verified
by playing in Godot. Platform exports and saved progression are not configured.
