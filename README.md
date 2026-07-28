# Sticky Monster

Sticky Monster is an offline, portrait 2D Godot game prototype expanded into a complete playable mobile structure: splash, main menu, world and level selection, 200 data-driven stages, save progression, skins, settings, results, and Android export presets.

## Godot Version

Use Godot `4.7.1 stable` or newer Godot 4 stable. The project uses GDScript only and the Compatibility renderer.

## Run The Game

1. Open Godot.
2. Import this folder as a project.
3. Open `project.godot`.
4. Press Run. The main scene is `res://scenes/app/AppRoot.tscn`.

Command-line validation:

```powershell
& 'F:\Program Files\Godot_v4.7.1-stable_win64.exe\Godot_v4.7.1-stable_win64.exe' --headless --path . --quit-after 160
& 'F:\Program Files\Godot_v4.7.1-stable_win64.exe\Godot_v4.7.1-stable_win64.exe' --headless --path . --scene res://scenes/gameplay/Gameplay.tscn --quit-after 120
& 'F:\Program Files\Godot_v4.7.1-stable_win64.exe\Godot_v4.7.1-stable_win64.exe' --headless --path . --scene res://tests/LogicTests.tscn
```

## Folder Structure

- `autoload/`: global managers for data, save, scene flow, audio, localization, and app state.
- `components/`: reusable gameplay pieces such as the sticky character, blocks, coins, and effect areas.
- `data/`: JSON data for 200 levels, worlds, skins, balance, and localization.
- `scenes/`: app screens and gameplay scene.
- `scripts/`: gameplay builders and UI screen scripts.
- `tests/`: logic test scene and logs.
- `themes/`: base UI theme.

## Creating A Level

Edit `data/levels/levels.json`. Each level has `id`, `world`, `index`, `start`, `exit`, `ideal_launches`, `max_launches`, `coins`, `blocks`, `hazards`, `areas`, `physics`, `xp_reward`, and `coin_reward`.

Use an existing stage as a template. Blocks support types such as `sticky`, `solid`, `ice`, `moving`, `bounce`, `hot`, `blade`, and `vanishing`. Areas support `wind`, `sand`, `magnet_pull`, `magnet_push`, `portal`, `gravity`, `jet`, `slow_time`, and hazard area types.

## Adding Obstacles

Add data to a level first. If a new behavior is needed, extend:

- `components/obstacles/level_block.gd` for colliding surfaces.
- `components/areas/effect_area.gd` for force fields, portals, hazards, and trigger zones.
- `scripts/gameplay/level_builder.gd` if a new object category is needed.

## Adding Skins

Edit `data/skins/skins.json`. Add an `id`, localized names, a hex `color`, and an unlock rule: `default`, `coins`, `level`, `stars`, or `world`.

## Adding Audio

`autoload/audio_manager.gd` already exposes named SFX calls. The current build intentionally uses silent placeholders so missing files never crash the game. Add `AudioStreamPlayer` streams there when final audio assets are available.

## Physics Balance

Change `data/balance/gameplay.json` for drag distance, launch multiplier, gravity, speed, star thresholds, XP, and rewards.

## Save File

Save data is local only at:

```text
user://sticky_monster_save.json
```

It is versioned, sanitized on load, and recreated if missing or invalid.

## Android Export

`export_presets.cfg` contains APK and AAB presets using package name `com.example.stickymonster`, portrait orientation, Compatibility renderer, and no internet permission. Install Android export templates and SDK support in Godot, then use:

- Project > Export > Android APK
- Project > Export > Android AAB

## Remaining Manual QA

Headless validation passes, but touch feel, Android back behavior, vibration strength, real APK/AAB signing, and performance on low-end phones still need manual device testing. Audio is currently placeholder-only.
