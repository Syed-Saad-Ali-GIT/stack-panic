# Stack Panic — Project Context (Godot)

This document explains the repository’s *runtime* structure so other agents/AI can quickly understand where things live and how the game boots and plays.

## High-level overview

`StackPanic` is a Godot 4 project (mobile-focused) built around a simple “tap-to-stack” mechanic:

1. Launch into a lightweight main menu scene (`res://scenes/Main.tscn`).
2. On tap/click, switch to gameplay (`res://scenes/Game.tscn`).
3. Gameplay spawns a moving “block” (`res://scenes/Block.tscn`).
4. When the player taps, the current block locks in place, the game trims it based on overhang, updates score/UI, and spawns the next block.
5. On game over, the death overlay (`res://scenes/DeathScreen.tscn`) is shown with retry/revive buttons.

Communication between systems is primarily done via a signal bus autoload (`autoloads/Events.gd`).

## Repo layout

At a glance:

- `project.godot`: Godot configuration, including the main scene and autoload singletons.
- `autoloads/`: global singleton scripts (autoloads) used across scenes.
- `scenes/`: the Godot scene files that make up the UI and gameplay entities.
- `scripts/`: non-scene scripts used by gameplay (theme/stage logic).
- `assets/`: art/audio placeholders (not critical for understanding the game loop).
- `stack-panic-prp.md`: product requirements plan (game rules + intended monetization/feature roadmap).

## Godot entry + autoloads

### `project.godot`

Key settings:

- `run/main_scene="uid://main001"` (the entry scene corresponds to `res://scenes/Main.tscn`)
- Autoload singletons registered under `[autoload]`:
  - `AudioManager` -> `autoloads/AudioManager.gd`
  - `Events` -> `autoloads/Events.gd`
  - `SaveManager` -> `autoloads/SaveManager.gd`
  - `ThemeManagerSP` -> `autoloads/ThemeManagerSP.gd`

## Runtime flow (startup → gameplay)

### 1) Main menu: `scenes/Main.tscn`

Scene purpose:

- Shows title/tap prompt.
- Displays best score (from `SaveManager.high_score`).
- On input (screen touch or left mouse), transitions to gameplay.

Script behavior (inline in `Main.tscn`):

- `_ready()` sets `BestLabel` using `SaveManager.high_score`.
- `_unhandled_input()` listens for `InputEventScreenTouch` and left mouse button.
- `_go_to_game()` calls:
  - `get_tree().change_scene_to_file('res://scenes/Game.tscn')`

### 2) Gameplay world: `scenes/Game.tscn`

Scene purpose:

- Owns the gameplay loop: stack state, spawning blocks, handling tap lock, scoring, game over, and revive/retry overlay interaction.
- Contains:
  - `Background` (`ColorRect`)
  - `Camera2D`
  - `HUD` (instanced from `scenes/HUD.tscn`)
  - `DeathScreen` (instanced from `scenes/DeathScreen.tscn`)

Important constants (from the inline script in `Game.tscn`):

- `PERFECT_THRESHOLD = 4.0` (overhang <= 4px counts as perfect)
- `BASE_SPEED = 180.0` and `MAX_SPEED = 520.0`
- `BLOCK_HEIGHT = 40.0`
- Initial stack Y: `vp_size.y * STACK_START_Y_RATIO` where `STACK_START_Y_RATIO = 0.7`
- Initial block width: `vp_size.x * 0.85`
- Game over trimming cutoff: `<= 8.0` (see `_on_block_locked`)

Gameplay loop:

- `_ready()`:
  - Connects `death_screen.retry_pressed` to `_start_game`
  - Connects `death_screen.revive_pressed` to `_on_revive`
  - Centers the camera
  - Calls `_start_game()`

- `_start_game()` (resets state):
  - Frees existing stack blocks/current block
  - Resets score, streak/combo, counters
  - Sets stack top position and initial width
  - Sets `game_active = true`
  - Emits:
    - `Events.game_started`
    - `Events.score_changed(0)`
  - Updates background color via `ThemeManagerSP.get_stage(...)`
  - Spawns the first moving block via `_spawn_next_block()`

- Input:
  - `_unhandled_input()` accepts tap/click only when `game_active == true`
  - `_tap()` calls `current_block.lock()` (which stops motion and emits `block_locked`)

- Scoring + trimming:
  - `_on_block_locked(block_x, block_width)`:
    - Overhang = `absf(block_x - stack_top_x)`
    - If `overhang >= block_width`: immediate game over
    - Else perfect if `overhang <= PERFECT_THRESHOLD`:
      - Perfect placement trims to full width (sets `final_width = block_width`)
      - Otherwise trims by overlap math and can trigger game over if `final_width <= 8.0`
    - Combo logic:
      - `perfect_streak` increments on perfect placements
      - At 3 perfects, sets `combo_active = true` for 5 subsequent blocks
      - During combo, points double and the HUD combo badge is shown/hidden
    - Points update:
      - Perfect: `2` points, non-perfect: `1` point (doubled again during combo)
    - Emits to the signal bus:
      - `Events.score_changed(score)`
      - `Events.block_placed(score, is_perfect)`
    - Places the block into the stack and spawns the next one

- Spawning:
  - `_spawn_next_block()`:
    - Instantiates `BLOCK_SCENE` (`res://scenes/Block.tscn`)
    - Speed: `minf(BASE_SPEED + score * 0.08, MAX_SPEED)`
    - Block color: `ThemeManagerSP.get_block_color(SaveManager.active_theme, score)`
    - Calls `block.setup(current_width, move_right, spd, stack_top_y - BLOCK_HEIGHT, col)`
    - Connects `block.block_locked` to `_on_block_locked`

- Game over:
  - `_trigger_game_over()`:
    - Sets `game_active = false`
    - `death_count += 1`
    - Updates/persists best via `SaveManager.check_and_save_high_score(score)`
    - Emits `Events.new_high_score` (when applicable) and `Events.game_over(score)`
    - Calls `death_screen.show_death(score, is_new_best)`

- Revive:
  - `_on_revive()` currently just:
    - Sets `game_active = true`
    - Hides death overlay
    - Spawns the next block
  - There is no rewarded-ad or revive-cost logic in the current code paths; revive is purely UI-driven.

### 3) Moving block entity: `scenes/Block.tscn`

Scene purpose:

- A moving colored rectangle that:
  - travels horizontally across the screen,
  - stops when locked,
  - emits its position/width for trimming/overhang logic in `Game.tscn`.

Key behaviors (inline script in `Block.tscn`):

- `setup(p_width, p_move_right, p_speed, p_y, p_color)`:
  - Stores screen width for boundary wrapping
  - Sets starting X off-screen based on direction:
    - moving right: `position.x = -p_width`
    - moving left: `position.x = screen_width + p_width`
  - Sets `ColorRect` size and position to match width
  - Sets `active = true`

- `_process(delta)`:
  - Moves `position.x` by `dir * speed * delta`
  - Wraps around when it passes the opposite edge

- `lock()`:
  - Sets `active = false`
  - Emits `block_locked(position.x, block_width)`

- `trim(new_width, new_x)`:
  - Updates internal `block_width`
  - Sets `position.x = new_x`
  - Updates the `ColorRect` to visually reflect the trimmed width

### 4) HUD overlay: `scenes/HUD.tscn`

Scene purpose:

- Displays score, best score, and visual feedback for perfect taps and combos.

Key behaviors (inline script in `HUD.tscn`):

- `_ready()` connects to signal bus:
  - `Events.score_changed -> _on_score_changed`
  - `Events.block_placed -> _on_block_placed`
  - `Events.game_started -> _on_game_started`
- Perfect feedback:
  - `show_perfect()` reveals `PerfectLabel` and animates it upward/fade-out.
  - `trigger_flash()` briefly shows a white `FlashOverlay`.
- Combo feedback:
  - `show_combo(multiplier)` shows `ComboBadge` and sets `ComboLabel` text to `x{multiplier}`
  - `hide_combo()` hides the badge
- Best score is set in `_ready()` using `SaveManager.high_score`

### 5) Death overlay: `scenes/DeathScreen.tscn`

Scene purpose:

- Shows game over UI.
- Provides buttons for retry and revive.
- Emits button presses back to `Game.tscn`.

Key behaviors (inline script in `DeathScreen.tscn`):

- Signals:
  - `retry_pressed`
  - `revive_pressed`
- `_ready()`:
  - `retry_button.pressed` emits `retry_pressed`
  - `revive_button.pressed` emits `revive_pressed`
  - `visible = false` initially
- `show_death(score, is_new_high)`:
  - Fills labels using provided `score` and `SaveManager.high_score`
  - Shows/hides “NEW BEST!”
  - Tweens the overlay panel alpha to fade in
- `hide_death()` sets `visible = false`

## Global managers (autoload)

### `autoloads/Events.gd` (signal bus)

Defines signals only (no logic):

- `game_started`
- `game_over(score: int)`
- `block_placed(score: int, is_perfect: bool)`
- `score_changed(new_score: int)`
- `new_high_score(score: int)`
- `theme_changed(theme_name: String)`
- `ad_requested(ad_type: String)`

### `autoloads/SaveManager.gd` (persistence + settings)

Purpose:

- Stores and loads player data/settings from `user://save.cfg` using `ConfigFile`.

Data fields used in current code:

- `high_score` (read by UI and updated on game over)
- `tokens`, `unlocked_themes`, `active_theme` (used for theme selection)
- settings toggles:
  - `sfx_enabled`
  - `music_enabled`
  - `ghost_enabled`

Key functions:

- `_ready()` calls `load_data()`
- `save_data()` writes to `SAVE_PATH` (`user://save.cfg`)
- `load_data()` reads existing save or keeps defaults
- `check_and_save_high_score(score: int) -> bool`:
  - updates `high_score` and persists when `score > high_score`
  - returns `true` when a new best is recorded

### `autoloads/AudioManager.gd` (sound/music gate)

Purpose:

- Creates and manages two `AudioStreamPlayer` nodes:
  - one for SFX (`play_sfx`)
  - one for music (`play_music`)
- Respects player settings stored in `SaveManager`:
  - if `SaveManager.sfx_enabled` is false, SFX won’t play
  - if `SaveManager.music_enabled` is false, music won’t play

### `autoloads/ThemeManagerSP.gd` (theme + stage color logic)

Purpose:

- Provides:
  - stage/background colors based on `(theme_name, score)`
  - block color based on `(theme_name, score)`

Key behaviors:

- `get_stage(theme_name, score)`:
  - chooses the best matching stage where `score >= score_min`
  - returns a dictionary containing `bg_top`, `bg_bot`, and `block` colors
- `get_block_color(theme_name, score)`:
  - for `Classic` at `score >= 100`, cycles the block color using time and HSV
  - otherwise uses the stage’s configured `block` color

## Intended features vs implemented code (important for future agents)

`stack-panic-prp.md` describes a broader mobile game plan (ads, daily challenge, shop, ghost runs, etc.).

In the current code paths, the core loop and theme/save/audio are implemented.
The revive button exists in the UI flow, but the revive logic is currently immediate (no rewarded-ad integration is visible in the gameplay code).

If you’re adding features (ads/daily challenge/shop), the PRP is the authoritative spec, while the autoload + signal patterns above are the current integration style.

