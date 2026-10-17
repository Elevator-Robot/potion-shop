# Potion Shop

A top-down 2D potion-shop management game for solo play or two-player co-op.
Gather ingredients, prepare them, brew and bottle potions, and serve customers
before their patience runs out. Earn coins and maintain the shop's reputation.

## Current design

- One shared shop with shelves, storage, prep table, cauldron, bottling station,
  and serving counter.
- Three recipes: Healing Potion, Mana Potion, and Ember Tonic.
- One carried item per player; cooperative use of shared stations and supplies.
- Days last 120 seconds; customer pressure grows and shelves restock each day.
- Movement: WASD/arrows. Interact: E/Space; hold for chopping. Esc leaves the shop.
- Existing elf and potion-maker sprites identify the two seats. They are static
  artwork, not animated sprite sheets. Character selection is a future feature.

## Development workflow

OpenCode edits and checks the game; the user runs Godot and provides playtest
feedback. Keep this loop lightweight. Use standard Godot, not Summer services.

## Scope boundaries

Current multiplayer is a two-player listen server over ENet, suitable for local
or LAN play. Host departure ends the session. Rejoining gets a free seat and
current shop state, not the previous player's inventory. There is no matchmaking,
host migration, saved progression, or platform export configuration yet.

Ask before adding new mechanics or changing the intended art style. The existing
code establishes current behavior; it does not authorize inventing a broader game.
