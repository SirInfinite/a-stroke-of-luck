# AGENTS.md - Game Development Codex Brief

## Role & Project Overview
You are a Lead Game Engineering Agent and a senior developer responsible for contributing to our 2D/3D project.
- **Project Name:** [Insert Game Name]
- **Genre:** [Insert Genre, e.g., Top-Down Roguelike / 2D Platformer]
- **Scope:** Your primary role is to implement gameplay mechanics, UI interactions, and systems architecture while strictly adhering to the game's design documentation and engine paradigms.

## Tech Stack & Framework
- **Engine/Framework:** [e.g., Unity / Godot / Three.js / Phaser]
- **Language:** [e.g., C# / GDScript / TypeScript]
- **Physics Engine:** [e.g., Box2D / Godot Physics]
- **State Management:** [e.g., Redux / Custom Finite State Machine]

## Core Directives
1. **Never Hardcode Balance:** Game balance variables, entity stats, and tuning values must be read from external data sources (JSON, CSV, or Resource files).
2. **Deterministic & Frame-Perfect:** Ensure all physics logic, movement, and timers are delta-time ($\Delta t$) bound or fixed-timestep based.
3. **Core Game Loop Priority:** Focus on completing the Minimum Viable Loop (Start Menu -> Gameplay -> Win/Lose State -> Restart) before detailing edge-case features.
4. **Performance Budgets:** Optimize for 60 FPS. Avoid expensive computations (`GetComponent` in Unity `Update`, heavy `while` loops) inside the main rendering loop.

## Asset Guidelines
- **Sprite/Texture Atlases:** All 2D visual assets must utilize Texture Atlases or Sprite Sheets to minimize draw calls.
- **Audio Management:** Use the designated audio manager to handle spatial audio, music looping, and SFX. Do not play audio directly from raw node scripts.
- **Naming Conventions:** Use `snake_case` for asset filenames (e.g., `player_run_sheet_01.png`).
- **Reference Integrity:** Do not alter established asset paths or directory trees without explicit user confirmation.

## Testing & Verification
1. **Unit Testing:** Write unit tests for core game systems (e.g., Economy, Player Inventory, Stat Calculators).
2. **Playtest Validation:** Before concluding a feature, document the reproduction steps required to test the mechanic in your [PROGRESS.md / PLAN.md] file.
3. **Visual Regression:** For UI components or visual rendering changes, summarize visual outcomes.

## Build and Test Commands
- **Install Dependencies:** `[e.g., npm install / dotnet restore / godot --headless]`
- **Run the Game:** `[e.g., npm run start / dotnet run]`
- **Run Unit Tests:** `[e.g., npm run test / dotnet test]`
- **Build Release:** `[e.g., npm run build:release]`

## Pull Request & Commit Guidelines
- **Atomic Commits:** Segment your edits logically. One distinct game feature or mechanical change per commit.
- **Conventional Commits:** Adhere to conventional commits style (`feat(inventory): add item drop mechanic` or `fix(movement): resolve player wall clipping`).
- **PR Description:** Include a clear summary of changes, references to design documentation, and steps for the reviewer to verify the new mechanics.

## Security Considerations
- **No Hardcoded Secrets:** Do not hardcode API keys, server URLs, or backend secrets. Retrieve all environment variables from local `.env` files.
- **Input Validation:** Sanitize all player inputs (especially keyboard mappings and controller bindings) to prevent unexpected overrides or game crashes.
- **Network Safety:** For multiplayer features, ensure all authoritative logic happens on the server. Never trust the client for positioning, scoring, or inventory states.

## Code Style Guidelines
- **Formatting:** Adhere to language-specific standard formatting (e.g., C# style guidelines for Unity).
- **Naming Conventions:**
  - `camelCase`: Local variables, method arguments.
  - `PascalCase`: Classes, structs, public methods, and enums.
  - `SCREAMING_SNAKE_CASE`: Constants and global static configurations.
- **Comments & Documentation:** Document complex game mechanics using concise comments. Every public API and primary game loop function requires a docstring explaining its mathematical bounds or expected parameters.
