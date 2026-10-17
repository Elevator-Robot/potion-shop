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
- `authority/shop.gd` owns inventory, customer queue, recipes, coins, reputation,
  brewing, and the day clock. `network/game.gd` holds shared rules and geometry.
- `network/session.gd` transports typed RPC arguments and dictionary snapshots.
  Only authority RPCs can install state or correct a player's pose. Only the host
  applies commands. No client chooses a seat or writes the shop snapshot.
- `client/main.gd` creates local/remote player scenes from the roster and renders
  the shop snapshot. Own movement is responsive locally; the host can correct it.
- `client/player_observer.gd` interpolates remote poses on the arrival timeline.

Reliable, ordered RPCs are used for this small two-player game. Movement is sent
up to 20 times/second when changed; shop snapshots also have a 0.25-second heartbeat.
An interaction flushes movement before its command on the same channel.

## Known limits

Movement validation checks room bounds and a speed budget, not full server-side
station collision simulation. Normal clients use Godot collision bodies. Prep
hold duration is enforced by the normal client's input code, not the authority.
These limitations predate the migration; this is not competitive anti-cheat.

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
