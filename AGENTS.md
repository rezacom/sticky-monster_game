# Sticky Monster Agent Notes

## Architecture

The project is a Godot 4 GDScript-only offline Android game. Main scene: `res://scenes/app/AppRoot.tscn`.

Autoloads:

- `GameData`: loads JSON level/world/skin/balance data and shared calculations.
- `SaveManager`: versioned local save, progression, coins, XP, skins, settings.
- `LocalizationManager`: English/Farsi strings.
- `AudioManager`: central placeholder-safe SFX/music API.
- `SceneManager`: screen transitions, history, Android back behavior.
- `AppManager`: current level flow and result handoff.

Gameplay:

- `scenes/gameplay/Gameplay.tscn`
- `scripts/gameplay/gameplay.gd`
- `scripts/gameplay/level_builder.gd`
- `components/sticky_character/sticky_character.gd`
- `components/obstacles/level_block.gd`
- `components/collectibles/coin.gd`
- `components/areas/effect_area.gd`

Levels are data-driven through `data/levels/levels.json`; the current build has 200 stages split across 10 worlds. Keep UI logic out of level simulation.

## Coding Rules

- Use GDScript only.
- Do not add paid assets or online dependencies.
- Keep data in `data/` and gameplay behavior in `components/` or `scripts/gameplay/`.
- Avoid large monolithic scripts.
- Avoid `:=` when the right side is JSON or Dictionary `Variant` data; warnings are treated as errors in this project.
- Missing audio or art must not crash the game.
- Preserve Android portrait, base resolution `1080x1920`, and Compatibility renderer.

## Test Commands

```powershell
& 'F:\Program Files\Godot_v4.7.1-stable_win64.exe\Godot_v4.7.1-stable_win64.exe' --headless --path . --quit-after 160
& 'F:\Program Files\Godot_v4.7.1-stable_win64.exe\Godot_v4.7.1-stable_win64.exe' --headless --path . --scene res://scenes/gameplay/Gameplay.tscn --quit-after 120
& 'F:\Program Files\Godot_v4.7.1-stable_win64.exe\Godot_v4.7.1-stable_win64.exe' --headless --path . --scene res://tests/LogicTests.tscn
```

Use `--log-file res://tests/<name>.log` when stdout is silent.

## Completion Standard

A change is complete only when the relevant scene runs without parser/runtime errors, `res://` references exist, save data still loads, and progression rules still pass `tests/LogicTests.tscn`.
