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
- Customers are original cozy elf, knight, wizard and dwarf drawings matching
  the purple shopkeeper's big-headed proportions, warm outlines and rosy cheeks.
  Each has four idle/breathing/blink frames. Appearance stays tied to customer ID;
  orders, patience bars and an angry indicator remain visible alongside the artwork.
- The fantasy population mixes moss/jade green, blue, lavender, rose, ochre,
  deep brown and peach skin. Any customer outfit can have any palette; appearance
  is independent of gameplay, and persists for that customer's whole visit.
- One carried item per player; cooperative use of shared stations and supplies.
- Days last 120 seconds; customer pressure grows and shelves restock each day.
- Movement: WASD/arrows. Interact: E/Space; hold for chopping. Esc leaves the shop.
- Player names: **Aaron** is the blue-clad witch (character 0); **Renna** is the
  purple-haired shopkeeper (character 1).
- Default player: Renna, redrawn as a big-headed elf with purple
  curls, rosy cheeks, a flower clip, sage sleeves, blue apron and a potion pocket.
  Four individually drawn idle frames include an inhale, brief blink and exhale;
  four walking frames have alternating feet, opposing arm swings and hair bounce.
  Aaron replaces Elf Adventurer: an original cozy redraw of `elf.png` with
  brown hair, a wide floppy purple hat, gold hatband, blue coat and brown boots,
  also with four individually drawn idle frames and four walking frames.
  Both stay upright, flip horizontally and return to idle when blocked.

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
