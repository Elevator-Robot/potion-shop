# Stock Godot architecture

Validated engine baseline: Godot 4.7.2. Main scene: `client/menu.tscn`.

## Session lifecycle

`Session` is an autoload at the same RPC path on every peer. Solo uses an
`OfflineMultiplayerPeer` and the same authority rules as hosting. Hosting uses
`ENetMultiplayerPeer` with one remote client, UDP port 24567 by default. The host
is also player 1; no separate dedicated-server process or cloud account is needed.

Joining waits for an authoritative snapshot before opening the shop. A failed
connection times out or reports an error in the menu. Esc closes the session and
returns to the menu. A disconnected remote player releases their seat and held
item. A rejoin receives a fresh seat and the ongoing shop snapshot. Host loss ends
play; the client displays an explanation and can return to the menu.

The menu stores a local character choice. Joining sends that choice to the host,
which bounds it to the two available portraits and includes it in the player pose.
Appearance is independent of seat; both players may choose the same portrait.

## State ownership

- `authority/main.gd` is a RefCounted host-side rules object. It maps authenticated
  peer IDs to seats and accepted poses, checks motion bounds/speed, validates
  station distance, and deduplicates ordered command IDs.
- `authority/shop.gd` owns inventory, browsing customers, recipes, coins, reputation,
  brewing, the entrance door and the day clock. `network/game.gd` holds shared
  rules, furniture positions, collision footprints and browse destinations.
- `network/session.gd` transports typed RPC arguments and dictionary snapshots.
  Only authority RPCs can install state or correct a player's pose. Only the host
  applies commands. No client chooses a seat or writes the shop snapshot.
- `client/main.gd` creates local/remote player scenes from the roster and renders
  the shop snapshot. Own movement is responsive locally; the host can correct it.
- `client/player_observer.gd` interpolates remote poses on the arrival timeline.
- `network/shop_navigation.gd` builds a cached AStar2D graph on a 16-pixel grid
  from shared convex furniture and clutter footprints. Nodes and full connecting
  segments must clear customer radius, including exact start/end connectors.
  The host advances customers at 10 Hz: enter, browse,
  wait/look around, leave. `client/customer_view.gd` maintains visuals by customer
  ID and interpolates authoritative positions/facing. Roaming is not client-random.
- `client/shop_prop.gd` uses those same footprints for collision and configures
  pixel artwork in the editor and at runtime. `shop_clutter.gd` does the same for
  baskets, books and loose-bottle groups. Props, players and customers live
  under `World` with Y-sorting. Shallow feet-level collision allows tall shelves
  to occlude people walking behind them.
- Accepted actions append numbered visual events to a bounded snapshot history.
  Each client plays unseen item-transfer, shelf, chest and service effects once.
  Retries do not mutate inventory or emit a second effect. The door also has an
  authoritative open-until time so late joiners see its correct state.

Reliable, ordered RPCs are used for this small two-player game. Movement is sent
up to 20 times/second when changed; shop snapshots also have a 0.25-second heartbeat.
An interaction flushes movement before its command on the same channel.

## Known limits

Movement validation checks room bounds, a speed budget and the complete travel
segment sampled every two pixels against shared convex footprints. Half a pixel
of sweep tolerance accommodates local collision rounding. Clients use a feet-level
circle and matching Godot convex collision shapes. Interactions also require a
clear line to their oriented approach point or customer. This is not a full
server-side replay of Godot physics or a competitive anti-cheat system.

Shelf stock is local to each cabinet (`shelf_stock[station][item]`); the `shelves`
dictionary is an aggregate for diagnostics. Item sprites are separate nodes on
explicit board slots, never painted into furniture. Shelf commands validate the
selected item's membership and stock at that specific cabinet. Both chests
access the same storage inventory. Customer navigation avoids furniture and floor
clutter, but
customers do not physically push players or each other. The entry door is the
customer transition to the outside; players remain inside the shop scene.

Timers use monotonic wall-clock milliseconds. Headless tests use controlled
fixtures for brew completion rather than assuming fixed FPS controls wall time.
No saves, relay/NAT traversal, matchmaking, reconnect identity, or host migration
are implemented. Direct internet connections require appropriate UDP reachability.

## Checks

`python3 tools/check.py` imports resources, exercises the authority's shop rules,
loads scenes, and drives solo movement input. `--network` additionally runs a host
and client to test admission, motion, interaction, state convergence, disconnect,
and rejoin. Tests use no external services. Human playtesting covers visuals,
sound, responsiveness, and whether the game is enjoyable.

`client/item_icon.gd` is the canonical renderer for all 18 item sheets, with
`item_tile.gd` adapting it to UI containers. Visual recipes are built directly
from `Game.RECIPES`; world order bubbles, held items and shelf stacks use the
same textures. Six two-ingredient recipes cover all twelve ingredients. The
technical IDs remain in code/state, but play does not depend on name labels.
