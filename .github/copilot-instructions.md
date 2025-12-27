# GitHub Copilot Instructions

## Project Snapshot
- **Game:** Potion Shop — a cozy 2D fantasy management title about running a magical storefront staffed by a witchy couple.
- **Engine:** Godot 4.4 using the Forward+ renderer (see `project.godot`).
- **Style:** Pixel art assets built around a 48×48 grid, gentle pacing, and exploration-driven puzzles.

## Voice and Tone
- Favor warm, inviting language that reflects a cozy fantasy shop.
- When using emojis, prefer a single potion bottle (🧪) and omit others unless explicitly requested.
- Emphasize routine, discovery, and low-pressure challenge when summarizing features or writing copy.

## Gameplay & Design Pillars
- Highlight the five-step loop from the README whenever describing gameplay: receive order → consult recipe book → locate ingredients → mix potion → manage time/flow.
- Reinforce the four pillars: cozy atmosphere, light puzzle solving, time management, and character-driven experience.
- Mention that mastery comes from familiarity with the space rather than combat or high-stress mechanics.

## Technical & Repository Guidance
- Assume contributors run the project via Godot 4.4+ (`project.godot`).
- Reference the repo structure documented in `README.md` when pointing to files:
  - `assets/` for sprites, tilesets, UI, audio
  - `docs/` for design references (including the brand palette)
  - `scenes/` for Godot scenes
  - `scripts/` for gameplay GDScript
- Link to `docs/brand/color-palette.md` whenever color usage or branding arises.

## Color and Branding Requirements
- The canonical palette is Lospec’s **Environmental Station Alpha**; use the hex values listed in `docs/brand/color-palette.md`.
- Keep visual descriptions or UI concepts consistent with that palette unless explicitly told otherwise.

## Writing & Documentation Preferences
- Provide concise, goal-oriented explanations (1–3 sentences) unless deeper detail is requested.
- For setup instructions, reuse the “Run Locally” flow from the README (clone → open in Godot → F5).
- Call out the project’s early-development status when relevant.

## Limitations & Reminders
- Do not invent new mechanics, platforms, or rendering tech outside what’s documented.
- Prefer clarifying questions if requirements are ambiguous or conflict with the established pillars.
- Keep instructions aligned with the repository’s existing docs; update references if file paths change.
