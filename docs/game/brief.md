# Potion Shop

A top-down 2D potion-shop management game for solo play or two-player co-op.
Gather ingredients, brew potions directly in a cauldron, and serve customers
before their patience runs out. Earn coins and maintain the shop's reputation.

## Current design

- Environment: warm oak floorboards, cool stone walls, and three arched stained-glass
  windows with potion motifs and colored light across the floor. The back wall is
  shown at full height; side/front walls are cut away for a clear view of gameplay.
- Interactivity is a core pillar: nine varied ingredient cabinets/racks/bins, two storage
  chests, an animated entrance door and a single directly usable cauldron, with
  books, baskets, bottles and parcels around the room. There is no prep table,
  separate bottling station, service counter or marked customer queue.
- Furniture is empty, grounded woodwork arranged in loose library rows, with
  restrained worn finishes. Actual inventory items are separate animated sprites
  placed on the boards; stock is tracked per cabinet. Potion racks start empty
  and can display/store crafted bottles. The violet/jade cauldron has its own
  idle, brewing and ready frames, liquid layer, and visual input/output sprites.
- Visual matching is the central loop: six bottles have unique shapes/colors
  (crimson vial, blue globe, amber square, violet crescent, green triangle and
  pearly heart). Twelve animated dark-fantasy ingredients combine in six simple
  two-ingredient recipes. Orders, recipes, held items and shelf stock all reuse
  the same sprites; item-name labels are not used in play.
- Customers are original cozy elf, knight, wizard and dwarf drawings matching
  the purple shopkeeper's big-headed proportions, warm outlines and rosy cheeks.
  Each has front/rear/profile idle and walking frames. Customers enter through the
  door, browse around furniture, pause and look around, then leave through the door
  after service or when patience expires. Appearance stays tied to customer ID;
  orders, patience bars and an angry indicator remain visible alongside the artwork.
- The fantasy population mixes moss/jade green, blue, lavender, rose, ochre,
  deep brown and peach skin. Any customer outfit can have any palette; appearance
  is independent of gameplay, and persists for that customer's whole visit.
- One carried item per player; cooperative use of shelves, chests and the cauldron.
  Add raw ingredients directly; matching recipes brew automatically. Collect the
  finished potion at the same cauldron and serve any nearby matching customer.
  Shelves accept their assigned items back; chests share a 12-item inventory.
  Empty an unfinished mix with empty hands if you want to start another recipe.
- Days last 120 seconds; customer pressure grows and shelves restock each day.
- Movement: WASD/arrows. Interact: E/Space or left click. Point at a shelf sprite
  to select it, or use Tab to cycle. R opens the visual recipe book. Esc leaves.
- The first customer arrives after about three seconds. Initial patience is
  90 seconds to allow for browsing and brewing; later days increase pressure.
- Player names: **Aaron** is the blue-clad witch (character 0); **Renna** is the
  purple-haired shopkeeper (character 1).
- Default player: Renna, redrawn as a big-headed elf with purple
  curls, rosy cheeks, a flower clip, sage sleeves, blue apron and a potion pocket.
  Four individually drawn idle frames include an inhale, brief blink and exhale;
  four walking frames have alternating feet, opposing arm swings and hair bounce.
  Aaron replaces Elf Adventurer: an original cozy redraw of `elf.png` with
  brown hair, a wide floppy purple hat, gold hatband, blue coat and brown boots,
  also with four individually drawn idle frames and four walking frames.
  Both have separately drawn rear idle and walking frames: upward movement,
  including diagonals, shows their backs and retains that facing when stopped.
  Horizontal movement uses independently drawn profile frames (mirrored for left)
  with side faces, clothing and near/far limbs, retaining profile idle on release.
  They stay upright, flip horizontally and return to idle when blocked.

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
