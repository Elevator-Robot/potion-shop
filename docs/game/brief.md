# Potion Shop

A top-down 2D potion-shop management game for solo play or two-player co-op.
Gather ingredients, prepare them, brew and bottle potions, and serve customers
before their patience runs out. Earn coins and maintain the shop's reputation.

## Current design

- Environment: warm oak floorboards, cool stone walls, and three arched stained-glass
  windows with potion motifs and colored light across the floor. The back wall is
  shown at full height; side/front walls are cut away for a clear view of gameplay.
- One shared shop with shelves, storage, prep table, cauldron, bottling station,
  and serving counter.
- Three recipes: Healing Potion, Mana Potion, and Ember Tonic.
- One carried item per player; cooperative use of shared stations and supplies.
- Days last 120 seconds; customer pressure grows and shelves restock each day.
- Movement: WASD/arrows. Interact: E/Space; hold for chopping. Esc leaves the shop.
- Choose Blue Witch (`elf.png`) or Purple Shopkeeper (`potionmaker.png`) in the
  menu, for solo or co-op. Both use the existing static artwork at 48 world pixels
  tall, stay upright, and flip toward horizontal movement. There are no walk-cycle sheets.

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
