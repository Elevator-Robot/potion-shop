# Potion Shop

Potion Shop is a shop-management game where you create and sell potions, serve customers, and keep your magical business running through busy days.

Run the shop solo or team up in two-player co-op. Gather ingredients, brew potions,
and coordinate orders to keep up with customer demand. Choose Aaron (the blue-clad
witch) or Renna (the purple-haired shopkeeper), then walk around with WASD/arrows.
Renna is selected by default. Both players have 24 custom-drawn cozy pixel-art
poses for front/rear/profile idle and walking; moving upward shows their backs,
and moving sideways shows their profiles.

## Run in Godot

Open `project.godot` with **stock Godot 4.7** (validated with 4.7.2), then press **F5**.
Choose **Play Solo**, **Host Co-op**, or **Join Co-op**. No Summer installation or
account is needed. F6 on `client/main.tscn` starts a solo shop directly.

- **Move:** WASD or arrow keys.
- **Interact:** E, Space or left click at the nearby object/customer.
- **Search shelves:** E/click opens contents; click a discovery to collect it.
- **Inventory:** eight-item bag; click a bag icon or press 1–8 to select.
- **Recipes:** R opens/closes the recipe book.
- **Close a panel / leave shop:** Esc.

The shop is an irregular woodland cottage with tall crooked shelves and rustic
walls. Customer requests show the bottle they want. Shortly afterward, ingredients
briefly pop over stocked shelves—including a distraction ingredient. Search to
inspect the real contents, collect what you want, and match pairs in the visual
recipe book. Any recipe can be brewed from your bag, even without a matching
customer request. Talking to a customer pauses them and repeats their hints.

The current concept-led pass tightens the room, adds angled decorated shelves,
violet windows, rugs, animated trees and mushrooms. Customer orders appear in
occasional thoughts; talk to hear a short request with the potion sprite inline.
Both player conversations and customer chats pause patience for five seconds
plus a two-second grace period. Day one starts with one customer at a time.
The two entrance racks display crafted potions stored for future orders.

Select ingredients in your bag to add them to the cauldron. Collect/select the
finished bottle before serving. Clicking the selected bag icon puts it away.
Assigned items can be returned through a shelf's search panel. Every shelf's
stock is independent. Chests are removed. Requests, hints, discoveries and
service have animated bubbles, sparkles and cute emotes.

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
