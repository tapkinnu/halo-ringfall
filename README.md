# Halo: Ringfall

A sci-fi first-person shooter inspired by Halo, built on the Kenney FPS Starter Kit for Godot 4.

## Features

- **Recharging Energy Shield** — Halo's signature mechanic. Shield absorbs damage first, then health. Shield recharges after 3 seconds without taking damage.
- **3 Weapons** (switch with 1/2/3 or E):
  - **MA5 Assault Rifle** — Full-auto, 32-round mag, moderate damage, fast fire rate
  - **M6 Magnum** — Semi-auto pistol, 8-round mag, high damage, headshot potential
  - **Type-25 Plasma Rifle** — Full-auto energy weapon, 50-round mag, high spread, low damage
- **3 Enemy Types** with distinct AI:
  - **Grunt** — Weak, slow, flees when low health (10 pts)
  - **Elite** — Has energy shield, aggressive pursuit, rage mode when shield breaks (25 pts)
  - **Hunter** — Massive health pool, slow charge attack, devastating damage (50 pts)
- **Wave-based survival** — Enemies spawn in escalating waves; each wave adds more enemies and tougher types
- **Sci-fi arena** — Floating platforms, glowing energy pillars, light strips, fog atmosphere
- **Full HUD** — Shield/health bars, ammo counter, weapon name, score, wave indicator, enemy count

## Controls

| Key | Action |
|-----|--------|
| W A S D | Movement |
| Mouse | Look |
| Left Click | Shoot |
| Space | Jump (double jump) |
| E | Cycle weapons |
| 1 2 3 | Select weapon directly |
| R | Reload |
| Esc | Release mouse |

## Tech

- **Engine:** Godot 4.4+ (Forward+ / Vulkan)
- **Base:** Kenney Starter Kit FPS (MIT + CC0)
- **Language:** GDScript

## License

- Code: MIT (Kenney + modifications)
- Assets: CC0 (Kenney)