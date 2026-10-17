# Potion Shop

A top-down 2D potion-shop management game for solo play or two-player co-op.
Gather ingredients, brew potions directly in a cauldron, and serve customers
before their patience runs out. Earn coins and maintain the shop's reputation.

## Current design

- Environment: an irregular rustic cottage in shadowy woods, with alcoves,
  beveled corners, timber/plaster/stone walls, moss, lanterns and stained glass.
  Nine eccentric shelf forms include tall bowed cases, stacked cubbies, living
  branches, a leaning tower and low hutches. Twelve wall assets form the kit.
  The back wall is full-height; sides/front are cut away. Woods are scenic only.
- Chests, prep table, bottling station, service counter and queue box are absent.
  The violet/jade cauldron remains a separate animated asset.
- Shelf contents are hidden until searched. Shortly after a request, required
  ingredients pop over stocked shelves alongside a distracting ingredient.
  Hints fade after a few seconds; talking repeats them. Locations/stock are
  truthful, but not every hint is relevant. Search always exposes real contents.
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
  patience bars and an angry indicator accompany the artwork; orders appear only
  in occasional thoughts or conversation.
- Customers and players block one another at their feet. Customers sidestep
  encounters; both show a tiny squash, hat wobble and questioning emote when
  they bump. Reactions have a cooldown and do not change patience or inventory.
- The fantasy population mixes moss/jade green, blue, lavender, rose, ochre,
  deep brown and peach skin. Any customer outfit can have any palette; appearance
  is independent of gameplay, and persists for that customer's whole visit.
- Each player has an eight-item bag and one selected item. Collect multiple
  ingredients, select them to add to the cauldron, and collect/select bottles
  before serving. Any recipe can be brewed from owned ingredients; demand does
  not gate crafting. Shelves accept their assigned items back. Deselect the
  active item to empty an unfinished mix.
- Days last 120 seconds; customer pressure grows and shelves restock each day.
- Movement: WASD/arrows. Interact/search: E/Space or click. Click discoveries to
  collect; click bag icons or press 1–8 to select. R opens recipes. Esc closes
  panels first, then leaves. Hearts, thoughts and discovery emotes animate feedback.
- The first customer arrives after eight seconds. Day one allows one visitor;
  each later day adds one up to the customer cap. Arrival intervals gently shrink
  from 34 to 20 seconds. Patience starts at 150 seconds, never below 110.
- Talking reveals a short, sometimes silly request with the potion sprite inline.
  Idle potion thoughts appear briefly every so often; there is no persistent HUD
  order list. Nearby customers chat with one another. Either kind of conversation
  pauses patience for five seconds plus two seconds afterward.
- The compact 624×436 cottage reduces travel. Decorated potion display shelves
  flank the entrance: select a crafted bottle and interact to stock it for later;
  search the rack to retrieve it. Stock is shared in co-op and persists across days.
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
