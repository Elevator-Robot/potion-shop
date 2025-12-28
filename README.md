# Potion Shop 🧪

## Overview
Potion Shop is a cozy 2D fantasy management game about running a magical storefront built on routine, discovery, and gentle challenge. Players control a charming couple who wear witch hats and cloaks while helping a rotating cast of whimsical customers with specific potion requests.

## Core Gameplay Loop
1. **Receive an order** – Customers request love tonics, restorative brews, and other bespoke concoctions.
2. **Consult the recipe book** – Each potion lists the ingredients and steps needed for success.
3. **Locate ingredients** – Items are scattered throughout the shop, turning every order into a light spatial puzzle.
4. **Mix the potion** – Combine ingredients with the correct timing and sequence to fulfill the order.
5. **Manage time and flow** – Rising demand challenges players to balance speed, accuracy, and efficient navigation.

The loop emphasizes spatial awareness, memory, and efficiency rather than combat.

## Game Pillars
- **Cozy fantasy atmosphere** – Warm, magical, and inviting spaces that feel alive and comforting.
- **Light puzzle solving** – Exploration-driven challenges that reward observation without harsh penalties.
- **Time management** – Increasing customer volume introduces meaningful pacing decisions.
- **Character-focused experience** – Routine and repetition make the shop feel personal and lived in.

## Technical Overview
- **Genre:** 2D fantasy, cozy management
- **Perspective:** Top-down
- **Engine:** Godot 4.4 (Forward+ renderer)
- **Art style:** Pixel art built around 48×48 assets
- **Platform target:** Desktop, with Steam distribution as the primary goal

## Getting Started
### Requirements
- Godot 4.4 or later

### Run Locally
1. Clone the repository: `git clone https://github.com/Elevator-Robot/potion-shop.git`
2. Open the project via `project.godot` in the Godot editor.
3. Press <kbd>F5</kbd> (or click **Run Project**) to launch the current scene.

## Repository Structure
```
.
├── assets/      Sprite sheets, tilesets, UI, and audio source files
├── docs/        Design references, including brand guidelines like docs/brand/color-palette.md
├── scenes/      Godot scene files for rooms, characters, and UI
├── scripts/     Gameplay logic implemented in GDScript
├── icon.svg     Application icon referenced by Godot
└── project.godot  Godot project configuration
```

## Documentation & References
- Brand color palette: [docs/brand/color-palette.md](docs/brand/color-palette.md)
- Sprite animation studies: [docs/art/sprite-animations.md](docs/art/sprite-animations.md)

## Project Status
The project is in early development; core systems, assets, and mechanics are actively being designed, prototyped, and iterated.

## Vision
Potion Shop focuses on mastery through familiarity. Players learn the space, internalize recipes, and keep a magical business running through care, observation, and thoughtful play rather than direct confrontation.
